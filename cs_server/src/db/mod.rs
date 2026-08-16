use std::path::Path;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use anyhow::Context;
use rusqlite::{Connection, OptionalExtension, params};

const CURRENT_SCHEMA_VERSION: i64 = 2;

#[derive(Clone)]
pub struct Database {
    connection: Arc<Mutex<Connection>>,
}

#[derive(Clone, Debug)]
pub struct PluginRecord {
    pub plugin_id: String,
    pub version: String,
    pub bundle_path: String,
    pub bundle_hash: String,
    pub enabled: bool,
    pub updated_at: String,
}

#[derive(Clone, Debug)]
pub struct UserRecord {
    pub id: String,
    pub username: String,
    pub password_hash: Option<String>,
    pub created_at: String,
}

#[derive(Clone, Copy, Debug)]
pub enum LibraryKind {
    Favorites,
    History,
    Follows,
}

impl LibraryKind {
    pub fn parse(value: &str) -> Option<Self> {
        match value {
            "favorites" => Some(Self::Favorites),
            "history" => Some(Self::History),
            "follows" => Some(Self::Follows),
            _ => None,
        }
    }

    fn table_name(self) -> &'static str {
        match self {
            Self::Favorites => "comic_favorites",
            Self::History => "comic_histories",
            Self::Follows => "comic_follows",
        }
    }
}

#[derive(Clone, Debug)]
pub struct LibraryRecord {
    pub unique_key: String,
    pub source: String,
    pub comic_id: String,
    pub payload_json: String,
    pub updated_at: String,
    pub deleted_at: Option<String>,
}

#[derive(Clone, Debug)]
pub struct AccountSettingsRecord {
    pub settings_json: String,
    pub revision: i64,
    pub updated_at: String,
}

impl Database {
    pub fn open(data_dir: &Path) -> anyhow::Result<Self> {
        std::fs::create_dir_all(data_dir)
            .with_context(|| format!("failed to create {}", data_dir.display()))?;
        let path = data_dir.join("breeze.sqlite3");
        let mut connection = Connection::open(&path)
            .with_context(|| format!("failed to open {}", path.display()))?;

        connection
            .busy_timeout(Duration::from_secs(5))
            .context("failed to configure SQLite busy timeout")?;
        connection
            .pragma_update(None, "foreign_keys", "ON")
            .context("failed to enable SQLite foreign keys")?;
        connection
            .pragma_update(None, "journal_mode", "WAL")
            .context("failed to enable SQLite WAL mode")?;

        migrate(&mut connection)?;

        Ok(Self {
            connection: Arc::new(Mutex::new(connection)),
        })
    }

    pub fn schema_version(&self) -> anyhow::Result<i64> {
        let connection = self
            .connection
            .lock()
            .map_err(|_| anyhow::anyhow!("SQLite connection lock poisoned"))?;
        let version = connection.query_row(
            "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
            [],
            |row| row.get(0),
        )?;
        Ok(version)
    }

    pub fn create_user(
        &self,
        id: &str,
        username: &str,
        password_hash: &str,
        created_at: &str,
    ) -> anyhow::Result<UserRecord> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO users(id, username, password_hash, created_at)
             VALUES (?1, ?2, ?3, ?4)",
            params![id, username, password_hash, created_at],
        )?;
        Ok(UserRecord {
            id: id.to_owned(),
            username: username.to_owned(),
            password_hash: Some(password_hash.to_owned()),
            created_at: created_at.to_owned(),
        })
    }

    pub fn find_user_by_username(&self, username: &str) -> anyhow::Result<Option<UserRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT id, username, password_hash, created_at
                 FROM users WHERE username = ?1",
                [username],
                user_from_row,
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn find_user_by_id(&self, id: &str) -> anyhow::Result<Option<UserRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT id, username, password_hash, created_at
                 FROM users WHERE id = ?1",
                [id],
                user_from_row,
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn create_session(
        &self,
        id: &str,
        user_id: &str,
        token_hash: &str,
        created_at: &str,
        expires_at: &str,
    ) -> anyhow::Result<()> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO sessions(id, user_id, token_hash, created_at, expires_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![id, user_id, token_hash, created_at, expires_at],
        )?;
        Ok(())
    }

    pub fn find_user_id_by_session(
        &self,
        token_hash: &str,
        now: &str,
    ) -> anyhow::Result<Option<String>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT user_id FROM sessions
                 WHERE token_hash = ?1 AND CAST(expires_at AS INTEGER) > CAST(?2 AS INTEGER)",
                params![token_hash, now],
                |row| row.get(0),
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn delete_session(&self, token_hash: &str) -> anyhow::Result<bool> {
        let connection = self.lock_connection()?;
        Ok(connection.execute("DELETE FROM sessions WHERE token_hash = ?1", [token_hash])? > 0)
    }

    pub fn account_settings(&self, user_id: &str) -> anyhow::Result<AccountSettingsRecord> {
        let connection = self.lock_connection()?;
        let existing = connection
            .query_row(
                "SELECT settings_json, revision, updated_at
                 FROM user_settings WHERE user_id = ?1",
                [user_id],
                |row| {
                    Ok(AccountSettingsRecord {
                        settings_json: row.get(0)?,
                        revision: row.get(1)?,
                        updated_at: row.get(2)?,
                    })
                },
            )
            .optional()?;
        Ok(existing.unwrap_or(AccountSettingsRecord {
            settings_json: "{}".to_owned(),
            revision: 0,
            updated_at: "0".to_owned(),
        }))
    }

    pub fn update_account_settings(
        &self,
        user_id: &str,
        settings_json: &str,
        expected_revision: Option<i64>,
        updated_at: &str,
    ) -> anyhow::Result<Option<AccountSettingsRecord>> {
        let mut connection = self.lock_connection()?;
        let transaction = connection.transaction()?;
        let current_revision: i64 = transaction
            .query_row(
                "SELECT revision FROM user_settings WHERE user_id = ?1",
                [user_id],
                |row| row.get(0),
            )
            .optional()?
            .unwrap_or(0);
        if expected_revision.is_some_and(|expected| expected != current_revision) {
            return Ok(None);
        }
        let next_revision = current_revision + 1;
        transaction.execute(
            "INSERT INTO user_settings(user_id, settings_json, revision, updated_at)
             VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT(user_id) DO UPDATE SET
               settings_json = excluded.settings_json,
               revision = excluded.revision,
               updated_at = excluded.updated_at",
            params![user_id, settings_json, next_revision, updated_at],
        )?;
        transaction.commit()?;
        Ok(Some(AccountSettingsRecord {
            settings_json: settings_json.to_owned(),
            revision: next_revision,
            updated_at: updated_at.to_owned(),
        }))
    }

    pub fn list_library_records(
        &self,
        user_id: &str,
        kind: LibraryKind,
        include_deleted: bool,
    ) -> anyhow::Result<Vec<LibraryRecord>> {
        let connection = self.lock_connection()?;
        let table = kind.table_name();
        let deleted_filter = if include_deleted {
            ""
        } else {
            " AND deleted_at IS NULL"
        };
        let sql = match kind {
            LibraryKind::Favorites | LibraryKind::History => format!(
                "SELECT unique_key, source, comic_id, payload_json, updated_at, deleted_at
                 FROM {table} WHERE user_id = ?1{deleted_filter} ORDER BY updated_at DESC"
            ),
            LibraryKind::Follows => format!(
                "SELECT unique_key, '', '', payload_json, updated_at, deleted_at
                 FROM {table} WHERE user_id = ?1{deleted_filter} ORDER BY updated_at DESC"
            ),
        };
        let mut statement = connection.prepare(&sql)?;
        let records = statement
            .query_map([user_id], |row| {
                Ok(LibraryRecord {
                    unique_key: row.get(0)?,
                    source: row.get(1)?,
                    comic_id: row.get(2)?,
                    payload_json: row.get(3)?,
                    updated_at: row.get(4)?,
                    deleted_at: row.get(5)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(records)
    }

    pub fn upsert_library_record(
        &self,
        user_id: &str,
        kind: LibraryKind,
        unique_key: &str,
        source: &str,
        comic_id: &str,
        payload_json: &str,
        updated_at: &str,
    ) -> anyhow::Result<LibraryRecord> {
        let connection = self.lock_connection()?;
        match kind {
            LibraryKind::Favorites | LibraryKind::History => {
                let table = kind.table_name();
                connection.execute(
                    &format!(
                        "INSERT INTO {table}(user_id, unique_key, source, comic_id,
                         payload_json, updated_at, deleted_at)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, NULL)
                         ON CONFLICT(user_id, unique_key) DO UPDATE SET
                           source = excluded.source,
                           comic_id = excluded.comic_id,
                           payload_json = excluded.payload_json,
                           updated_at = excluded.updated_at,
                           deleted_at = NULL"
                    ),
                    params![
                        user_id,
                        unique_key,
                        source,
                        comic_id,
                        payload_json,
                        updated_at
                    ],
                )?;
            }
            LibraryKind::Follows => {
                connection.execute(
                    "INSERT INTO comic_follows(user_id, unique_key, payload_json, updated_at, deleted_at)
                     VALUES (?1, ?2, ?3, ?4, NULL)
                     ON CONFLICT(user_id, unique_key) DO UPDATE SET
                       payload_json = excluded.payload_json,
                       updated_at = excluded.updated_at,
                       deleted_at = NULL",
                    params![user_id, unique_key, payload_json, updated_at],
                )?;
            }
        }
        Ok(LibraryRecord {
            unique_key: unique_key.to_owned(),
            source: source.to_owned(),
            comic_id: comic_id.to_owned(),
            payload_json: payload_json.to_owned(),
            updated_at: updated_at.to_owned(),
            deleted_at: None,
        })
    }

    pub fn delete_library_record(
        &self,
        user_id: &str,
        kind: LibraryKind,
        unique_key: &str,
        deleted_at: &str,
    ) -> anyhow::Result<bool> {
        let connection = self.lock_connection()?;
        let table = kind.table_name();
        Ok(connection.execute(
            &format!(
                "UPDATE {table} SET deleted_at = ?1, updated_at = ?2
                 WHERE user_id = ?3 AND unique_key = ?4"
            ),
            params![deleted_at, deleted_at, user_id, unique_key],
        )? > 0)
    }

    fn lock_connection(&self) -> anyhow::Result<std::sync::MutexGuard<'_, Connection>> {
        self.connection
            .lock()
            .map_err(|_| anyhow::anyhow!("SQLite connection lock poisoned"))
    }

    pub fn list_plugins(&self) -> anyhow::Result<Vec<PluginRecord>> {
        let connection = self
            .connection
            .lock()
            .map_err(|_| anyhow::anyhow!("SQLite connection lock poisoned"))?;
        let mut statement = connection.prepare(
            "SELECT plugin_id, version, bundle_path, bundle_hash, enabled, updated_at
             FROM plugins
             ORDER BY plugin_id",
        )?;
        let records = statement
            .query_map([], |row| {
                Ok(PluginRecord {
                    plugin_id: row.get(0)?,
                    version: row.get(1)?,
                    bundle_path: row.get(2)?,
                    bundle_hash: row.get(3)?,
                    enabled: row.get::<_, i64>(4)? != 0,
                    updated_at: row.get(5)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(records)
    }

    pub fn find_plugin(&self, plugin_id: &str) -> anyhow::Result<Option<PluginRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT plugin_id, version, bundle_path, bundle_hash, enabled, updated_at
                 FROM plugins WHERE plugin_id = ?1",
                [plugin_id],
                |row| {
                    Ok(PluginRecord {
                        plugin_id: row.get(0)?,
                        version: row.get(1)?,
                        bundle_path: row.get(2)?,
                        bundle_hash: row.get(3)?,
                        enabled: row.get::<_, i64>(4)? != 0,
                        updated_at: row.get(5)?,
                    })
                },
            )
            .optional()
            .map_err(Into::into)
    }
}

fn user_from_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<UserRecord> {
    Ok(UserRecord {
        id: row.get(0)?,
        username: row.get(1)?,
        password_hash: row.get(2)?,
        created_at: row.get(3)?,
    })
}

fn migrate(connection: &mut Connection) -> anyhow::Result<()> {
    connection.execute_batch(
        "CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );",
    )?;

    let version: i64 = connection.query_row(
        "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
        [],
        |row| row.get(0),
    )?;

    if version < 1 {
        let transaction = connection.transaction()?;
        transaction.execute_batch(
            "CREATE TABLE users (
                id TEXT PRIMARY KEY NOT NULL,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT,
                created_at TEXT NOT NULL
            );

            CREATE TABLE user_settings (
                user_id TEXT PRIMARY KEY NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                settings_json TEXT NOT NULL DEFAULT '{}',
                revision INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE plugins (
                plugin_id TEXT PRIMARY KEY NOT NULL,
                version TEXT NOT NULL,
                bundle_path TEXT NOT NULL,
                bundle_hash TEXT NOT NULL,
                enabled INTEGER NOT NULL DEFAULT 1,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE user_plugins (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                plugin_id TEXT NOT NULL REFERENCES plugins(plugin_id) ON DELETE CASCADE,
                enabled INTEGER NOT NULL DEFAULT 1,
                debug INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, plugin_id)
            );

            CREATE TABLE plugin_configs (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                plugin_id TEXT NOT NULL REFERENCES plugins(plugin_id) ON DELETE CASCADE,
                config_json TEXT NOT NULL DEFAULT '{}',
                revision INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, plugin_id)
            );

            CREATE TABLE comic_favorites (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                unique_key TEXT NOT NULL,
                source TEXT NOT NULL,
                comic_id TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                PRIMARY KEY (user_id, unique_key)
            );

            CREATE TABLE comic_histories (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                unique_key TEXT NOT NULL,
                source TEXT NOT NULL,
                comic_id TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                PRIMARY KEY (user_id, unique_key)
            );

            CREATE TABLE comic_follows (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                unique_key TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                PRIMARY KEY (user_id, unique_key)
            );

            CREATE TABLE comic_folders (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                sync_id TEXT NOT NULL,
                parent_sync_id TEXT,
                type_data TEXT NOT NULL,
                unique_key TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                PRIMARY KEY (user_id, sync_id)
            );

            CREATE TABLE comic_links (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                unique_key TEXT NOT NULL,
                comic_unique_key TEXT NOT NULL,
                folder_sync_id TEXT,
                type_data TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                PRIMARY KEY (user_id, unique_key)
            );

            CREATE TABLE download_tasks (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                task_id TEXT NOT NULL,
                status TEXT NOT NULL,
                progress INTEGER NOT NULL DEFAULT 0,
                payload_json TEXT NOT NULL,
                error_text TEXT,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, task_id)
            );

            CREATE TABLE download_manifests (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                comic_unique_key TEXT NOT NULL,
                manifest_json TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, comic_unique_key)
            );

            CREATE TABLE assets (
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                asset_id TEXT NOT NULL,
                storage_key TEXT NOT NULL,
                media_type TEXT NOT NULL,
                byte_size INTEGER NOT NULL,
                content_hash TEXT NOT NULL,
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, asset_id)
            );

            CREATE TABLE server_meta (
                key TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
            );

            INSERT INTO schema_migrations(version) VALUES (1);",
        )?;
        transaction.commit()?;
    }

    if version < 2 {
        let transaction = connection.transaction()?;
        transaction.execute_batch(
            "CREATE TABLE sessions (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                token_hash TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL,
                expires_at TEXT NOT NULL
            );

            CREATE INDEX sessions_user_id_idx ON sessions(user_id);
            CREATE INDEX sessions_expiry_idx ON sessions(expires_at);

            INSERT INTO schema_migrations(version) VALUES (2);",
        )?;
        transaction.commit()?;
    }

    if version > CURRENT_SCHEMA_VERSION {
        anyhow::bail!(
            "database schema version {version} is newer than server version {CURRENT_SCHEMA_VERSION}"
        );
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use super::Database;

    #[test]
    fn opens_and_migrates_schema() {
        let suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be after Unix epoch")
            .as_nanos();
        let data_dir = std::env::temp_dir().join(format!(
            "breeze-cs-server-test-{}-{suffix}",
            std::process::id()
        ));

        let database = Database::open(&data_dir).expect("database should open");
        assert_eq!(
            database
                .schema_version()
                .expect("schema should be readable"),
            2
        );
        assert!(
            database
                .list_plugins()
                .expect("plugin catalog should be readable")
                .is_empty()
        );

        let user = database
            .create_user("user-1", "alice", "hash", "1")
            .expect("user should be created");
        assert_eq!(user.username, "alice");
        database
            .upsert_library_record(
                &user.id,
                super::LibraryKind::Favorites,
                "source:comic-1",
                "source",
                "comic-1",
                "{\"title\":\"demo\"}",
                "2",
            )
            .expect("favorite should be written");
        assert_eq!(
            database
                .list_library_records(&user.id, super::LibraryKind::Favorites, false)
                .expect("favorite should be readable")
                .len(),
            1
        );

        drop(database);
        std::fs::remove_dir_all(data_dir).expect("test database directory should be removable");
    }
}
