use std::path::Path;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use anyhow::Context;
use rusqlite::{Connection, OptionalExtension, params};
use serde_json::Value;

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
pub struct UserPluginRecord {
    pub plugin_id: String,
    pub version: String,
    pub bundle_path: String,
    pub bundle_hash: String,
    pub enabled: bool,
    pub debug: bool,
    pub debug_url: Option<String>,
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

#[derive(Clone, Debug)]
pub struct PluginConfigRecord {
    pub config_json: String,
    pub revision: i64,
    pub updated_at: String,
}

#[derive(Clone, Debug)]
pub struct DownloadTaskRecord {
    pub task_id: String,
    pub status: String,
    pub progress: i64,
    pub payload_json: String,
    pub error_text: Option<String>,
    pub updated_at: String,
}

#[derive(Clone, Debug)]
pub struct AssetRecord {
    pub storage_key: String,
    pub media_type: String,
    pub byte_size: i64,
    pub content_hash: String,
}

#[derive(Clone, Debug, Default, serde::Serialize)]
pub struct MigrationImportCounts {
    pub favorites: i64,
    pub histories: i64,
    pub follows: i64,
    pub folders: i64,
    pub links: i64,
    pub plugins: i64,
    pub plugin_configs: i64,
    pub downloads: i64,
    pub download_tasks: i64,
    pub download_folders: i64,
    pub download_folder_items: i64,
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

        initialize_schema(&mut connection)?;

        Ok(Self {
            connection: Arc::new(Mutex::new(connection)),
        })
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

    pub fn plugin_config(
        &self,
        user_id: &str,
        plugin_id: &str,
    ) -> anyhow::Result<PluginConfigRecord> {
        let connection = self.lock_connection()?;
        let existing = connection
            .query_row(
                "SELECT config_json, revision, updated_at
                 FROM plugin_configs WHERE user_id = ?1 AND plugin_id = ?2",
                params![user_id, plugin_id],
                |row| {
                    Ok(PluginConfigRecord {
                        config_json: row.get(0)?,
                        revision: row.get(1)?,
                        updated_at: row.get(2)?,
                    })
                },
            )
            .optional()?;
        Ok(existing.unwrap_or(PluginConfigRecord {
            config_json: "{}".to_owned(),
            revision: 0,
            updated_at: "0".to_owned(),
        }))
    }

    pub fn update_plugin_config(
        &self,
        user_id: &str,
        plugin_id: &str,
        config_json: &str,
        expected_revision: Option<i64>,
        updated_at: &str,
    ) -> anyhow::Result<Option<PluginConfigRecord>> {
        let mut connection = self.lock_connection()?;
        let transaction = connection.transaction()?;
        let current_revision: i64 = transaction
            .query_row(
                "SELECT revision FROM plugin_configs
                 WHERE user_id = ?1 AND plugin_id = ?2",
                params![user_id, plugin_id],
                |row| row.get(0),
            )
            .optional()?
            .unwrap_or(0);
        if expected_revision.is_some_and(|expected| expected != current_revision) {
            return Ok(None);
        }
        let next_revision = current_revision + 1;
        transaction.execute(
            "INSERT INTO plugin_configs(user_id, plugin_id, config_json, revision, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT(user_id, plugin_id) DO UPDATE SET
               config_json = excluded.config_json,
               revision = excluded.revision,
               updated_at = excluded.updated_at",
            params![user_id, plugin_id, config_json, next_revision, updated_at],
        )?;
        transaction.commit()?;
        Ok(Some(PluginConfigRecord {
            config_json: config_json.to_owned(),
            revision: next_revision,
            updated_at: updated_at.to_owned(),
        }))
    }

    pub fn delete_plugin_config(&self, user_id: &str, plugin_id: &str) -> anyhow::Result<()> {
        let connection = self.lock_connection()?;
        connection.execute(
            "DELETE FROM plugin_configs WHERE user_id = ?1 AND plugin_id = ?2",
            params![user_id, plugin_id],
        )?;
        Ok(())
    }

    pub fn upsert_plugin_object(
        &self,
        content_hash: &str,
        compression: &str,
        original_size: i64,
        compressed_size: i64,
        storage_key: &str,
        created_at: &str,
    ) -> anyhow::Result<()> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO plugin_objects(
                content_hash, compression, original_size, compressed_size, storage_key, created_at
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(content_hash) DO UPDATE SET
               compression = excluded.compression,
               original_size = excluded.original_size,
               compressed_size = excluded.compressed_size,
               storage_key = excluded.storage_key",
            params![
                content_hash,
                compression,
                original_size,
                compressed_size,
                storage_key,
                created_at,
            ],
        )?;
        Ok(())
    }

    pub fn remove_unreferenced_plugin_objects(&self) -> anyhow::Result<Vec<String>> {
        let mut connection = self.lock_connection()?;
        let transaction = connection.transaction()?;
        let storage_keys = {
            let mut statement = transaction.prepare(
                "SELECT storage_key FROM plugin_objects
                 WHERE content_hash NOT IN (
                   SELECT DISTINCT bundle_hash FROM plugins
                 )",
            )?;
            statement
                .query_map([], |row| row.get::<_, String>(0))?
                .collect::<Result<Vec<_>, _>>()?
        };
        transaction.execute(
            "DELETE FROM plugin_objects
             WHERE content_hash NOT IN (
               SELECT DISTINCT bundle_hash FROM plugins
             )",
            [],
        )?;
        transaction.commit()?;
        Ok(storage_keys)
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

    pub fn upsert_user_plugin(
        &self,
        user_id: &str,
        plugin_id: &str,
        enabled: bool,
        debug: bool,
        debug_url: Option<&str>,
        updated_at: &str,
    ) -> anyhow::Result<()> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO user_plugins(user_id, plugin_id, enabled, debug, debug_url, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(user_id, plugin_id) DO UPDATE SET
               enabled = excluded.enabled,
               debug = excluded.debug,
               debug_url = excluded.debug_url,
               updated_at = excluded.updated_at",
            params![user_id, plugin_id, enabled, debug, debug_url, updated_at],
        )?;
        Ok(())
    }

    pub fn find_user_plugin(
        &self,
        user_id: &str,
        plugin_id: &str,
    ) -> anyhow::Result<Option<UserPluginRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT p.plugin_id, p.version, p.bundle_path, p.bundle_hash,
                        up.enabled, up.debug, up.debug_url, up.updated_at
                 FROM user_plugins up
                 JOIN plugins p ON p.plugin_id = up.plugin_id
                 WHERE up.user_id = ?1 AND up.plugin_id = ?2",
                params![user_id, plugin_id],
                |row| {
                    Ok(UserPluginRecord {
                        plugin_id: row.get(0)?,
                        version: row.get(1)?,
                        bundle_path: row.get(2)?,
                        bundle_hash: row.get(3)?,
                        enabled: row.get::<_, i64>(4)? != 0,
                        debug: row.get::<_, i64>(5)? != 0,
                        debug_url: row.get(6)?,
                        updated_at: row.get(7)?,
                    })
                },
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn remove_user_plugin(&self, user_id: &str, plugin_id: &str) -> anyhow::Result<bool> {
        let connection = self.lock_connection()?;
        Ok(connection.execute(
            "DELETE FROM user_plugins WHERE user_id = ?1 AND plugin_id = ?2",
            params![user_id, plugin_id],
        )? > 0)
    }

    /// 将客户端迁移快照导入当前用户的服务端数据库。
    ///
    /// 该方法只做 upsert，不会清空服务端数据；所有业务表写入同一个事务，
    /// 这样客户端重试时不会产生半份迁移结果。
    pub fn import_migration_snapshot(
        &self,
        user_id: &str,
        data: &Value,
        include_downloads: bool,
    ) -> anyhow::Result<MigrationImportCounts> {
        let mut connection = self.lock_connection()?;
        let transaction = connection.transaction()?;
        let mut counts = MigrationImportCounts::default();

        if let Some(settings) = data.get("account_settings") {
            transaction.execute(
                "INSERT INTO user_settings(user_id, settings_json, revision, updated_at)
                 VALUES (?1, ?2, 1, ?3)
                 ON CONFLICT(user_id) DO UPDATE SET
                   settings_json = excluded.settings_json,
                   revision = user_settings.revision + 1,
                   updated_at = excluded.updated_at",
                params![
                    user_id,
                    serde_json::to_string(settings)?,
                    current_import_timestamp(),
                ],
            )?;
        }

        for item in array_field(data, "favorites") {
            import_library_row(&transaction, user_id, "comic_favorites", item, true)?;
            counts.favorites += 1;
        }
        for item in array_field(data, "histories") {
            import_library_row(&transaction, user_id, "comic_histories", item, true)?;
            counts.histories += 1;
        }
        for item in array_field(data, "follows") {
            let Some(unique_key) = string_value(item, "uniqueKey") else {
                continue;
            };
            let updated_at =
                string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
            let deleted_at = deleted_timestamp(item, &updated_at);
            transaction.execute(
                "INSERT INTO comic_follows(user_id, unique_key, payload_json, updated_at, deleted_at)
                 VALUES (?1, ?2, ?3, ?4, ?5)
                 ON CONFLICT(user_id, unique_key) DO UPDATE SET
                   payload_json = excluded.payload_json,
                   updated_at = excluded.updated_at,
                   deleted_at = excluded.deleted_at",
                params![
                    user_id,
                    unique_key,
                    serde_json::to_string(item)?,
                    updated_at,
                    deleted_at,
                ],
            )?;
            counts.follows += 1;
        }
        for item in array_field(data, "folders") {
            let Some(sync_id) = string_value(item, "syncId") else {
                continue;
            };
            let updated_at =
                string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
            let deleted_at = item.get("deletedAt").and_then(value_as_string);
            transaction.execute(
                "INSERT INTO comic_folders(
                   user_id, sync_id, parent_sync_id, type_data, unique_key,
                   payload_json, updated_at, deleted_at
                 ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
                 ON CONFLICT(user_id, sync_id) DO UPDATE SET
                   parent_sync_id = excluded.parent_sync_id,
                   type_data = excluded.type_data,
                   unique_key = excluded.unique_key,
                   payload_json = excluded.payload_json,
                   updated_at = excluded.updated_at,
                   deleted_at = excluded.deleted_at",
                params![
                    user_id,
                    sync_id,
                    item.get("parentSyncId").and_then(value_as_string),
                    string_value(item, "typeData").unwrap_or_default(),
                    string_value(item, "uniqueKey").unwrap_or_default(),
                    serde_json::to_string(item)?,
                    updated_at,
                    deleted_at,
                ],
            )?;
            counts.folders += 1;
        }
        for item in array_field(data, "links") {
            let Some(unique_key) = string_value(item, "uniqueKey") else {
                continue;
            };
            let updated_at =
                string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
            let deleted_at = item.get("deletedAt").and_then(value_as_string);
            transaction.execute(
                "INSERT INTO comic_links(
                   user_id, unique_key, comic_unique_key, folder_sync_id,
                   type_data, payload_json, updated_at, deleted_at
                 ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
                 ON CONFLICT(user_id, unique_key) DO UPDATE SET
                   comic_unique_key = excluded.comic_unique_key,
                   folder_sync_id = excluded.folder_sync_id,
                   type_data = excluded.type_data,
                   payload_json = excluded.payload_json,
                   updated_at = excluded.updated_at,
                   deleted_at = excluded.deleted_at",
                params![
                    user_id,
                    unique_key,
                    string_value(item, "comicUniqueKey").unwrap_or_default(),
                    item.get("folderSyncId").and_then(value_as_string),
                    string_value(item, "typeData").unwrap_or_default(),
                    serde_json::to_string(item)?,
                    updated_at,
                    deleted_at,
                ],
            )?;
            counts.links += 1;
        }
        for item in array_field(data, "plugin_configs") {
            let Some(plugin_id) = string_value(item, "name") else {
                continue;
            };
            let config_json = match item.get("config") {
                Some(Value::String(value)) => value.clone(),
                Some(value) => serde_json::to_string(value)?,
                None => "{}".to_owned(),
            };
            transaction.execute(
                "INSERT INTO plugin_configs(
                   user_id, plugin_id, config_json, revision, updated_at
                 )
                 SELECT ?1, ?2, ?3, 1, ?4
                 WHERE EXISTS (SELECT 1 FROM plugins WHERE plugin_id = ?2)
                 ON CONFLICT(user_id, plugin_id) DO UPDATE SET
                   config_json = excluded.config_json,
                   revision = plugin_configs.revision + 1,
                   updated_at = excluded.updated_at",
                params![user_id, plugin_id, config_json, current_import_timestamp(),],
            )?;
            counts.plugin_configs += 1;
        }

        if include_downloads {
            for item in array_field(data, "downloads") {
                let Some(comic_key) = string_value(item, "uniqueKey") else {
                    continue;
                };
                let updated_at =
                    string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
                transaction.execute(
                    "INSERT INTO download_manifests(
                       user_id, comic_unique_key, manifest_json, updated_at
                     ) VALUES (?1, ?2, ?3, ?4)
                     ON CONFLICT(user_id, comic_unique_key) DO UPDATE SET
                       manifest_json = excluded.manifest_json,
                       updated_at = excluded.updated_at",
                    params![user_id, comic_key, serde_json::to_string(item)?, updated_at,],
                )?;
                counts.downloads += 1;
            }
            for item in array_field(data, "download_tasks") {
                let task_id = format!(
                    "local:{}:{}",
                    string_value(item, "comicId").unwrap_or_default(),
                    value_as_string(item.get("id").unwrap_or(&Value::Null))
                        .unwrap_or_else(|| uuid::Uuid::new_v4().to_string())
                );
                let status = string_value(item, "status").unwrap_or_else(|| {
                    if item
                        .get("isCompleted")
                        .and_then(Value::as_bool)
                        .unwrap_or(false)
                    {
                        "completed".to_owned()
                    } else {
                        "queued".to_owned()
                    }
                });
                let progress = if status == "completed" { 100 } else { 0 };
                transaction.execute(
                    "INSERT INTO download_tasks(
                       user_id, task_id, status, progress, payload_json, error_text, updated_at
                     ) VALUES (?1, ?2, ?3, ?4, ?5, NULL, ?6)
                     ON CONFLICT(user_id, task_id) DO UPDATE SET
                       status = excluded.status,
                       progress = excluded.progress,
                       payload_json = excluded.payload_json,
                       updated_at = excluded.updated_at",
                    params![
                        user_id,
                        task_id,
                        status,
                        progress,
                        serde_json::to_string(item)?,
                        current_import_timestamp(),
                    ],
                )?;
                counts.download_tasks += 1;
            }
            for item in array_field(data, "download_folders") {
                let Some(folder_key) = string_value(item, "folderKey") else {
                    continue;
                };
                let updated_at =
                    string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
                let deleted_at = deleted_timestamp(item, &updated_at);
                transaction.execute(
                    "INSERT INTO download_folders(
                       user_id, folder_key, payload_json, updated_at, deleted_at
                     ) VALUES (?1, ?2, ?3, ?4, ?5)
                     ON CONFLICT(user_id, folder_key) DO UPDATE SET
                       payload_json = excluded.payload_json,
                       updated_at = excluded.updated_at,
                       deleted_at = excluded.deleted_at",
                    params![
                        user_id,
                        folder_key,
                        serde_json::to_string(item)?,
                        updated_at,
                        deleted_at,
                    ],
                )?;
                counts.download_folders += 1;
            }
            for item in array_field(data, "download_folder_items") {
                let Some(unique_key) = string_value(item, "uniqueKey") else {
                    continue;
                };
                let updated_at =
                    string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
                let deleted_at = deleted_timestamp(item, &updated_at);
                transaction.execute(
                    "INSERT INTO download_folder_items(
                       user_id, unique_key, folder_key, download_unique_key,
                       payload_json, updated_at, deleted_at
                     ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
                     ON CONFLICT(user_id, unique_key) DO UPDATE SET
                       folder_key = excluded.folder_key,
                       download_unique_key = excluded.download_unique_key,
                       payload_json = excluded.payload_json,
                       updated_at = excluded.updated_at,
                       deleted_at = excluded.deleted_at",
                    params![
                        user_id,
                        unique_key,
                        string_value(item, "folderKey").unwrap_or_default(),
                        string_value(item, "downloadUniqueKey").unwrap_or_default(),
                        serde_json::to_string(item)?,
                        updated_at,
                        deleted_at,
                    ],
                )?;
                counts.download_folder_items += 1;
            }
        }

        transaction.commit()?;
        Ok(counts)
    }

    pub fn append_migration_asset_page(
        &self,
        user_id: &str,
        comic_unique_key: &str,
        relative_path: &str,
        asset_id: &str,
        updated_at: &str,
    ) -> anyhow::Result<()> {
        let mut connection = self.lock_connection()?;
        let transaction = connection.transaction()?;
        let mut manifest = transaction
            .query_row(
                "SELECT manifest_json FROM download_manifests
                 WHERE user_id = ?1 AND comic_unique_key = ?2",
                params![user_id, comic_unique_key],
                |row| row.get::<_, String>(0),
            )
            .optional()?
            .and_then(|value| serde_json::from_str::<Value>(&value).ok())
            .unwrap_or_else(|| serde_json::json!({}));
        let object = manifest
            .as_object_mut()
            .ok_or_else(|| anyhow::anyhow!("migration manifest must be a JSON object"))?;
        let pages = object
            .entry("pages")
            .or_insert_with(|| Value::Array(Vec::new()));
        let pages = pages
            .as_array_mut()
            .ok_or_else(|| anyhow::anyhow!("migration manifest pages must be an array"))?;
        pages.retain(|page| page.get("path").and_then(Value::as_str) != Some(relative_path));
        pages.push(serde_json::json!({
            "path": relative_path,
            "asset_id": asset_id,
        }));
        transaction.execute(
            "INSERT INTO download_manifests(user_id, comic_unique_key, manifest_json, updated_at)
             VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT(user_id, comic_unique_key) DO UPDATE SET
               manifest_json = excluded.manifest_json,
               updated_at = excluded.updated_at",
            params![
                user_id,
                comic_unique_key,
                serde_json::to_string(&manifest)?,
                updated_at,
            ],
        )?;
        transaction.commit()?;
        Ok(())
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

    pub fn list_user_plugins(&self, user_id: &str) -> anyhow::Result<Vec<UserPluginRecord>> {
        let connection = self.lock_connection()?;
        let mut statement = connection.prepare(
            "SELECT p.plugin_id, p.version, p.bundle_path, p.bundle_hash,
                    up.enabled, up.debug, up.debug_url, up.updated_at
             FROM user_plugins up
             JOIN plugins p ON p.plugin_id = up.plugin_id
             WHERE up.user_id = ?1
             ORDER BY p.plugin_id",
        )?;
        let records = statement
            .query_map([user_id], |row| {
                Ok(UserPluginRecord {
                    plugin_id: row.get(0)?,
                    version: row.get(1)?,
                    bundle_path: row.get(2)?,
                    bundle_hash: row.get(3)?,
                    enabled: row.get::<_, i64>(4)? != 0,
                    debug: row.get::<_, i64>(5)? != 0,
                    debug_url: row.get(6)?,
                    updated_at: row.get(7)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(records)
    }

    pub fn export_migration_data(
        &self,
        user_id: &str,
        include_downloads: bool,
    ) -> anyhow::Result<Value> {
        let connection = self.lock_connection()?;
        let account_settings = connection
            .query_row(
                "SELECT settings_json FROM user_settings WHERE user_id = ?1",
                [user_id],
                |row| row.get::<_, String>(0),
            )
            .optional()?
            .and_then(|value| serde_json::from_str::<Value>(&value).ok())
            .unwrap_or_else(|| Value::Object(serde_json::Map::new()));

        let mut data = serde_json::Map::new();
        data.insert("account_settings".to_owned(), account_settings);
        data.insert(
            "favorites".to_owned(),
            query_payloads(&connection, "comic_favorites", user_id)?,
        );
        data.insert(
            "histories".to_owned(),
            query_payloads(&connection, "comic_histories", user_id)?,
        );
        data.insert(
            "follows".to_owned(),
            query_payloads(&connection, "comic_follows", user_id)?,
        );
        data.insert(
            "folders".to_owned(),
            query_payloads(&connection, "comic_folders", user_id)?,
        );
        data.insert(
            "links".to_owned(),
            query_payloads(&connection, "comic_links", user_id)?,
        );

        let mut plugin_configs = Vec::new();
        let mut config_statement = connection.prepare(
            "SELECT plugin_id, config_json FROM plugin_configs
             WHERE user_id = ?1 ORDER BY plugin_id",
        )?;
        for row in config_statement.query_map([user_id], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
        })? {
            let (plugin_id, config_json) = row?;
            plugin_configs.push(serde_json::json!({
                "id": 0,
                "name": plugin_id,
                "config": config_json,
            }));
        }
        data.insert("plugin_configs".to_owned(), Value::Array(plugin_configs));

        if include_downloads {
            let mut downloads = Vec::new();
            let mut download_assets = Vec::new();
            let mut manifest_statement = connection.prepare(
                "SELECT comic_unique_key, manifest_json FROM download_manifests
                 WHERE user_id = ?1 ORDER BY comic_unique_key",
            )?;
            for row in manifest_statement.query_map([user_id], |row| {
                Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
            })? {
                let (comic_key, manifest_json) = row?;
                let mut manifest = serde_json::from_str::<Value>(&manifest_json)?;
                if let Some(pages) = manifest.get_mut("pages").and_then(Value::as_array_mut) {
                    for (page_index, page) in pages.iter().enumerate() {
                        let Some(asset_id) = page.get("asset_id").and_then(Value::as_str) else {
                            continue;
                        };
                        let relative_path = page
                            .get("path")
                            .and_then(Value::as_str)
                            .map(ToOwned::to_owned)
                            .unwrap_or_else(|| {
                                let chapter = page
                                    .get("chapter_id")
                                    .and_then(Value::as_str)
                                    .filter(|value| !value.is_empty())
                                    .unwrap_or("chapter");
                                let chapter = chapter.replace(['/', '\\'], "_").replace("..", "_");
                                format!("{chapter}/page-{page_index}.bin")
                            });
                        let Some((media_type, byte_size, content_hash)) = connection
                            .query_row(
                                "SELECT media_type, byte_size, content_hash FROM assets
                                 WHERE user_id = ?1 AND asset_id = ?2",
                                rusqlite::params![user_id, asset_id],
                                |asset| {
                                    Ok((
                                        asset.get::<_, String>(0)?,
                                        asset.get::<_, i64>(1)?,
                                        asset.get::<_, String>(2)?,
                                    ))
                                },
                            )
                            .optional()?
                        else {
                            continue;
                        };
                        download_assets.push(serde_json::json!({
                            "comic_key": comic_key,
                            "relative_path": relative_path,
                            "asset_id": asset_id,
                            "media_type": media_type,
                            "byte_size": byte_size,
                            "content_hash": content_hash,
                        }));
                    }
                    if let Some(object) = manifest.as_object_mut() {
                        object.remove("pages");
                    }
                }
                downloads.push(manifest);
            }
            data.insert("downloads".to_owned(), Value::Array(downloads));
            data.insert("download_assets".to_owned(), Value::Array(download_assets));
            data.insert(
                "download_tasks".to_owned(),
                query_payloads(&connection, "download_tasks", user_id)?,
            );
            data.insert(
                "download_folders".to_owned(),
                query_payloads(&connection, "download_folders", user_id)?,
            );
            data.insert(
                "download_folder_items".to_owned(),
                query_payloads(&connection, "download_folder_items", user_id)?,
            );
        }

        Ok(Value::Object(data))
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

    pub fn upsert_plugin(
        &self,
        plugin_id: &str,
        version: &str,
        bundle_path: &str,
        bundle_hash: &str,
        enabled: bool,
        updated_at: &str,
    ) -> anyhow::Result<PluginRecord> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO plugins(plugin_id, version, bundle_path, bundle_hash, enabled, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(plugin_id) DO UPDATE SET
               version = excluded.version,
               bundle_path = excluded.bundle_path,
               bundle_hash = excluded.bundle_hash,
               enabled = excluded.enabled,
               updated_at = excluded.updated_at",
            params![
                plugin_id,
                version,
                bundle_path,
                bundle_hash,
                enabled,
                updated_at
            ],
        )?;
        Ok(PluginRecord {
            plugin_id: plugin_id.to_owned(),
            version: version.to_owned(),
            bundle_path: bundle_path.to_owned(),
            bundle_hash: bundle_hash.to_owned(),
            enabled,
            updated_at: updated_at.to_owned(),
        })
    }

    pub fn create_download_task(
        &self,
        user_id: &str,
        task_id: &str,
        payload_json: &str,
        updated_at: &str,
    ) -> anyhow::Result<DownloadTaskRecord> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO download_tasks(user_id, task_id, status, progress, payload_json, error_text, updated_at)
             VALUES (?1, ?2, 'queued', 0, ?3, NULL, ?4)",
            params![user_id, task_id, payload_json, updated_at],
        )?;
        Ok(DownloadTaskRecord {
            task_id: task_id.to_owned(),
            status: "queued".to_owned(),
            progress: 0,
            payload_json: payload_json.to_owned(),
            error_text: None,
            updated_at: updated_at.to_owned(),
        })
    }

    pub fn find_download_task(
        &self,
        user_id: &str,
        task_id: &str,
    ) -> anyhow::Result<Option<DownloadTaskRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT task_id, status, progress, payload_json, error_text, updated_at
                 FROM download_tasks WHERE user_id = ?1 AND task_id = ?2",
                params![user_id, task_id],
                download_task_from_row,
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn list_download_tasks(&self, user_id: &str) -> anyhow::Result<Vec<DownloadTaskRecord>> {
        let connection = self.lock_connection()?;
        let mut statement = connection.prepare(
            "SELECT task_id, status, progress, payload_json, error_text, updated_at
             FROM download_tasks WHERE user_id = ?1 ORDER BY updated_at DESC",
        )?;
        Ok(statement
            .query_map([user_id], download_task_from_row)?
            .collect::<Result<Vec<_>, _>>()?)
    }

    pub fn update_download_task(
        &self,
        user_id: &str,
        task_id: &str,
        status: &str,
        progress: i64,
        error_text: Option<&str>,
        updated_at: &str,
    ) -> anyhow::Result<bool> {
        let connection = self.lock_connection()?;
        Ok(connection.execute(
            "UPDATE download_tasks SET status = ?1, progress = ?2, error_text = ?3, updated_at = ?4
             WHERE user_id = ?5 AND task_id = ?6",
            params![status, progress, error_text, updated_at, user_id, task_id],
        )? > 0)
    }

    pub fn save_manifest(
        &self,
        user_id: &str,
        comic_unique_key: &str,
        manifest_json: &str,
        updated_at: &str,
    ) -> anyhow::Result<()> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO download_manifests(user_id, comic_unique_key, manifest_json, updated_at)
             VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT(user_id, comic_unique_key) DO UPDATE SET
               manifest_json = excluded.manifest_json,
               updated_at = excluded.updated_at",
            params![user_id, comic_unique_key, manifest_json, updated_at],
        )?;
        Ok(())
    }

    pub fn find_manifest(
        &self,
        user_id: &str,
        comic_unique_key: &str,
    ) -> anyhow::Result<Option<String>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT manifest_json FROM download_manifests
                 WHERE user_id = ?1 AND comic_unique_key = ?2",
                params![user_id, comic_unique_key],
                |row| row.get(0),
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn create_asset(
        &self,
        user_id: &str,
        asset_id: &str,
        storage_key: &str,
        media_type: &str,
        byte_size: i64,
        content_hash: &str,
        created_at: &str,
    ) -> anyhow::Result<AssetRecord> {
        let connection = self.lock_connection()?;
        connection.execute(
            "INSERT INTO assets(user_id, asset_id, storage_key, media_type, byte_size, content_hash, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![user_id, asset_id, storage_key, media_type, byte_size, content_hash, created_at],
        )?;
        Ok(AssetRecord {
            storage_key: storage_key.to_owned(),
            media_type: media_type.to_owned(),
            byte_size,
            content_hash: content_hash.to_owned(),
        })
    }

    pub fn find_asset(&self, user_id: &str, asset_id: &str) -> anyhow::Result<Option<AssetRecord>> {
        let connection = self.lock_connection()?;
        connection
            .query_row(
                "SELECT storage_key, media_type, byte_size, content_hash
                 FROM assets WHERE user_id = ?1 AND asset_id = ?2",
                params![user_id, asset_id],
                |row| {
                    Ok(AssetRecord {
                        storage_key: row.get(0)?,
                        media_type: row.get(1)?,
                        byte_size: row.get(2)?,
                        content_hash: row.get(3)?,
                    })
                },
            )
            .optional()
            .map_err(Into::into)
    }

    pub fn delete_asset(&self, user_id: &str, asset_id: &str) -> anyhow::Result<bool> {
        let connection = self.lock_connection()?;
        Ok(connection.execute(
            "DELETE FROM assets WHERE user_id = ?1 AND asset_id = ?2",
            params![user_id, asset_id],
        )? > 0)
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

fn download_task_from_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<DownloadTaskRecord> {
    Ok(DownloadTaskRecord {
        task_id: row.get(0)?,
        status: row.get(1)?,
        progress: row.get(2)?,
        payload_json: row.get(3)?,
        error_text: row.get(4)?,
        updated_at: row.get(5)?,
    })
}

fn array_field<'a>(value: &'a Value, key: &str) -> Vec<&'a Value> {
    value
        .get(key)
        .and_then(Value::as_array)
        .map(|items| items.iter().collect())
        .unwrap_or_default()
}

fn query_payloads(
    connection: &rusqlite::Connection,
    table: &str,
    user_id: &str,
) -> anyhow::Result<Value> {
    let sql = format!("SELECT payload_json FROM {table} WHERE user_id = ?1 ORDER BY updated_at");
    let mut statement = connection.prepare(&sql)?;
    let mut payloads = Vec::new();
    for row in statement.query_map([user_id], |row| row.get::<_, String>(0))? {
        let payload = row?;
        payloads.push(serde_json::from_str(&payload)?);
    }
    Ok(Value::Array(payloads))
}

fn string_value(value: &Value, key: &str) -> Option<String> {
    value.get(key).and_then(value_as_string)
}

fn value_as_string(value: &Value) -> Option<String> {
    let result = match value {
        Value::String(value) => value.clone(),
        Value::Number(value) => value.to_string(),
        Value::Bool(value) => value.to_string(),
        _ => return None,
    };
    (!result.trim().is_empty()).then_some(result)
}

fn deleted_timestamp(value: &Value, updated_at: &str) -> Option<String> {
    value
        .get("deleted")
        .and_then(Value::as_bool)
        .filter(|deleted| *deleted)
        .map(|_| updated_at.to_owned())
}

fn current_import_timestamp() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};

    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis().to_string())
        .unwrap_or_else(|_| "0".to_owned())
}

fn import_library_row(
    transaction: &rusqlite::Transaction<'_>,
    user_id: &str,
    table: &str,
    item: &Value,
    include_source: bool,
) -> anyhow::Result<()> {
    let Some(unique_key) = string_value(item, "uniqueKey") else {
        return Ok(());
    };
    let source = if include_source {
        string_value(item, "source").unwrap_or_default()
    } else {
        String::new()
    };
    let comic_id = if include_source {
        string_value(item, "comicId").unwrap_or_default()
    } else {
        String::new()
    };
    let updated_at = string_value(item, "updatedAt").unwrap_or_else(current_import_timestamp);
    let deleted_at = deleted_timestamp(item, &updated_at);
    transaction.execute(
        &format!(
            "INSERT INTO {table}(
               user_id, unique_key, source, comic_id, payload_json, updated_at, deleted_at
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(user_id, unique_key) DO UPDATE SET
               source = excluded.source,
               comic_id = excluded.comic_id,
               payload_json = excluded.payload_json,
               updated_at = excluded.updated_at,
               deleted_at = excluded.deleted_at"
        ),
        params![
            user_id,
            unique_key,
            source,
            comic_id,
            serde_json::to_string(item)?,
            updated_at,
            deleted_at,
        ],
    )?;
    Ok(())
}

fn initialize_schema(connection: &mut Connection) -> anyhow::Result<()> {
    let transaction = connection.transaction()?;
    transaction.execute_batch(
        r#"
        CREATE TABLE users (
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
            debug_url TEXT,
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

        CREATE TABLE sessions (
            id TEXT PRIMARY KEY NOT NULL,
            user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token_hash TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL
        );

        CREATE TABLE download_folders (
            user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            folder_key TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            PRIMARY KEY (user_id, folder_key)
        );

        CREATE TABLE download_folder_items (
            user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            unique_key TEXT NOT NULL,
            folder_key TEXT NOT NULL,
            download_unique_key TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            PRIMARY KEY (user_id, unique_key)
        );

        CREATE TABLE plugin_objects (
            content_hash TEXT PRIMARY KEY NOT NULL,
            compression TEXT NOT NULL,
            original_size INTEGER NOT NULL,
            compressed_size INTEGER NOT NULL,
            storage_key TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL
        );

        CREATE INDEX plugin_configs_plugin_idx ON plugin_configs(plugin_id);
        CREATE INDEX download_tasks_status_idx ON download_tasks(status, updated_at);
        CREATE INDEX assets_user_created_idx ON assets(user_id, created_at);
        CREATE INDEX sessions_user_id_idx ON sessions(user_id);
        CREATE INDEX sessions_expiry_idx ON sessions(expires_at);
        CREATE INDEX download_folder_items_folder_idx
            ON download_folder_items(user_id, folder_key);
        CREATE INDEX plugin_objects_storage_idx ON plugin_objects(storage_key);
        "#,
    )?;
    transaction.commit()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use serde_json::{Value, json};

    use super::{Database, LibraryKind};

    #[test]
    fn opens_current_schema() {
        let suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be after Unix epoch")
            .as_nanos();
        let data_dir = std::env::temp_dir().join(format!(
            "breeze-cs-server-test-{}-{suffix}",
            std::process::id()
        ));

        let database = Database::open(&data_dir).expect("database should open");
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

        database
            .upsert_plugin("plugin-1", "1.0.0", "plugin-1.cjs", "hash", true, "2")
            .expect("plugin should be written");
        database
            .upsert_plugin_object("hash", "brotli", 100, 40, "objects/hash.cjs.br", "3")
            .expect("plugin object should be written");
        database
            .upsert_plugin_object(
                "orphan-hash",
                "brotli",
                80,
                30,
                "objects/orphan.cjs.br",
                "3",
            )
            .expect("orphan plugin object should be written");
        assert_eq!(
            database
                .remove_unreferenced_plugin_objects()
                .expect("orphan plugin objects should be collected"),
            vec!["objects/orphan.cjs.br".to_owned()]
        );
        database
            .upsert_user_plugin(&user.id, "plugin-1", true, false, None, "2")
            .expect("user plugin should be written");
        let counts = database
            .import_migration_snapshot(
                &user.id,
                &json!({
                    "account_settings": {"global": {"themeMode": "dark"}},
                    "favorites": [{
                        "uniqueKey": "source:comic-2",
                        "source": "source",
                        "comicId": "comic-2",
                        "title": "migrated",
                        "updatedAt": "3",
                        "deleted": false
                    }],
                    "histories": [],
                    "follows": [{
                        "uniqueKey": "source:comic-3",
                        "updatedAt": "4",
                        "deleted": false
                    }],
                    "folders": [{
                        "syncId": "folder-1",
                        "uniqueKey": "folder-1",
                        "typeData": "favorite",
                        "updatedAt": "5"
                    }],
                    "links": [{
                        "uniqueKey": "link-1",
                        "comicUniqueKey": "source:comic-2",
                        "typeData": "favorite",
                        "updatedAt": "5"
                    }],
                    "plugin_configs": [{
                        "name": "plugin-1",
                        "config": "{\"token\":\"demo\"}"
                    }],
                    "downloads": [{
                        "uniqueKey": "source:comic-4",
                        "updatedAt": "6"
                    }],
                    "download_tasks": [{
                        "id": 7,
                        "comicId": "comic-4",
                        "isCompleted": true,
                        "status": "completed"
                    }],
                    "download_folders": [{"folderKey": "all"}],
                    "download_folder_items": [{"uniqueKey": "item-1"}]
                }),
                true,
            )
            .expect("migration should import");
        assert_eq!(counts.favorites, 1);
        assert_eq!(counts.follows, 1);
        assert_eq!(counts.folders, 1);
        assert_eq!(counts.links, 1);
        assert_eq!(counts.plugin_configs, 1);
        assert_eq!(counts.downloads, 1);
        assert_eq!(counts.download_tasks, 1);
        assert_eq!(counts.download_folders, 1);
        assert_eq!(counts.download_folder_items, 1);
        assert_eq!(
            database
                .list_library_records(&user.id, LibraryKind::Favorites, false)
                .expect("migrated favorite should be readable")
                .len(),
            2
        );
        database
            .create_asset(
                &user.id,
                "asset-1",
                "user-1/asset-1.bin",
                "image/jpeg",
                3,
                "hash-1",
                "7",
            )
            .expect("migration asset should be written");
        database
            .append_migration_asset_page(
                &user.id,
                "source:comic-4",
                "chapter-1/page-1.jpg",
                "asset-1",
                "7",
            )
            .expect("migration asset should be linked");
        let manifest = database
            .find_manifest(&user.id, "source:comic-4")
            .expect("manifest should be readable")
            .expect("manifest should exist");
        let manifest: Value = serde_json::from_str(&manifest).expect("manifest should be JSON");
        assert_eq!(manifest["pages"][0]["asset_id"], "asset-1");

        let exported = database
            .export_migration_data(&user.id, true)
            .expect("migration data should export");
        assert_eq!(exported["favorites"].as_array().unwrap().len(), 2);
        assert_eq!(exported["plugin_configs"][0]["name"], "plugin-1");
        assert_eq!(exported["downloads"][0]["uniqueKey"], "source:comic-4");
        assert_eq!(exported["download_assets"][0]["asset_id"], "asset-1");
        assert_eq!(exported["download_folders"][0]["folderKey"], "all");
        assert_eq!(exported["download_folder_items"][0]["uniqueKey"], "item-1");

        drop(database);
        std::fs::remove_dir_all(data_dir).expect("test database directory should be removable");
    }
}
