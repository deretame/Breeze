use std::path::Path;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use anyhow::Context;
use rusqlite::Connection;

const CURRENT_SCHEMA_VERSION: i64 = 1;

#[derive(Clone)]
pub struct Database {
    connection: Arc<Mutex<Connection>>,
}

#[derive(Clone, Debug)]
pub struct PluginRecord {
    pub plugin_id: String,
    pub version: String,
    pub bundle_hash: String,
    pub enabled: bool,
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

    pub fn list_plugins(&self) -> anyhow::Result<Vec<PluginRecord>> {
        let connection = self
            .connection
            .lock()
            .map_err(|_| anyhow::anyhow!("SQLite connection lock poisoned"))?;
        let mut statement = connection.prepare(
            "SELECT plugin_id, version, bundle_hash, enabled, updated_at
             FROM plugins
             ORDER BY plugin_id",
        )?;
        let records = statement
            .query_map([], |row| {
                Ok(PluginRecord {
                    plugin_id: row.get(0)?,
                    version: row.get(1)?,
                    bundle_hash: row.get(2)?,
                    enabled: row.get::<_, i64>(3)? != 0,
                    updated_at: row.get(4)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(records)
    }
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
            1
        );
        assert!(
            database
                .list_plugins()
                .expect("plugin catalog should be readable")
                .is_empty()
        );

        drop(database);
        std::fs::remove_dir_all(data_dir).expect("test database directory should be removable");
    }
}
