use std::{cmp::Ordering, time::Duration};

use anyhow::{Context, Result};
use serde_json::json;
use tracing::{info, warn};

use crate::{api::plugin_store, app_state::AppState};

const PLUGIN_UPDATE_INTERVAL: Duration = Duration::from_secs(4 * 60 * 60);

/// Runs the server-owned plugin updater. The first tick is immediate, then the
/// catalog and each plugin's own update channel are checked every four hours.
pub async fn run(state: AppState) {
    let mut interval = tokio::time::interval(PLUGIN_UPDATE_INTERVAL);
    interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

    loop {
        interval.tick().await;
        if let Err(error) = update_once(&state).await {
            warn!(error = %error, "server plugin auto-update failed");
        }
    }
}

async fn update_once(state: &AppState) -> Result<()> {
    let catalog = match crate::plugin_store::fetch_catalog(&state.http_client).await {
        Ok(catalog) => catalog,
        Err(error) => {
            warn!(error = %error, "plugin catalog unavailable; trying plugin self-update channels");
            Vec::new()
        }
    };
    let installed = state
        .database
        .list_plugins()
        .context("failed to list installed plugins")?;

    for plugin in installed {
        let catalog_item = catalog
            .iter()
            .find(|item| item.manifest.uuid.trim() == plugin.plugin_id)
            .cloned();
        let item = match catalog_item {
            Some(item)
                if compare_versions(item.manifest.version.trim(), &plugin.version)
                    == Ordering::Greater =>
            {
                Some(item)
            }
            Some(_) => None,
            None => match build_self_channel_item(state, &plugin).await {
                Ok(item) => item,
                Err(error) => {
                    warn!(
                        plugin_id = %plugin.plugin_id,
                        error = %error,
                        "plugin self-update channel unavailable"
                    );
                    None
                }
            },
        };
        let Some(item) = item else {
            continue;
        };
        let remote_version = item.manifest.version.trim();

        match install_update_item(state, &item).await {
            Ok(installed) => {
                info!(
                    plugin_id = %installed.plugin_id,
                    old_version = %plugin.version,
                    new_version = %installed.version,
                    "server plugin auto-update completed"
                );
                state.websocket_hub.publish_event_to_all(
                    "plugins.updated",
                    json!({
                        "plugin_id": installed.plugin_id,
                        "version": installed.version,
                        "status": "updated",
                    }),
                );
            }
            Err(error) => {
                warn!(
                    plugin_id = %plugin.plugin_id,
                    current_version = %plugin.version,
                    target_version = remote_version,
                    error = ?error,
                    "server plugin auto-update skipped"
                );
                state.websocket_hub.publish_event_to_all(
                    "plugins.updated",
                    json!({
                        "plugin_id": plugin.plugin_id,
                        "version": remote_version,
                        "status": "failed",
                        "error": "插件自动更新失败",
                    }),
                );
            }
        }
    }
    Ok(())
}

async fn build_self_channel_item(
    state: &AppState,
    plugin: &crate::db::PluginRecord,
) -> Result<Option<crate::plugin_store::CloudPluginItem>> {
    let bundle_path = state.config.plugin_root.join(&plugin.bundle_path);
    let bundle =
        crate::plugin_store::read_plugin_bundle_file_verified(&bundle_path, &plugin.bundle_hash)
            .await
            .with_context(|| format!("failed to read current bundle for {}", plugin.plugin_id))?;
    let info = state
        .plugin_runtime
        .invoke_json(
            "plugin-update",
            &plugin.plugin_id,
            &bundle,
            "getInfo",
            &json!([]),
        )
        .await
        .map_err(|error| anyhow::anyhow!(error))?;
    let npm_name = crate::plugin_store::plugin_info_field(&info, "npmName");
    let update_url = crate::plugin_store::plugin_info_field(&info, "updateUrl");
    if npm_name.is_empty() && update_url.is_empty() {
        return Ok(None);
    }
    let version = crate::plugin_store::fetch_self_channel_latest_version(
        &state.http_client,
        &npm_name,
        &update_url,
    )
    .await?;
    if compare_versions(&version, &plugin.version) != Ordering::Greater {
        return Ok(None);
    }
    Ok(Some(crate::plugin_store::CloudPluginItem {
        repo: "self-update".to_owned(),
        manifest: crate::plugin_store::CloudPluginManifest {
            name: crate::plugin_store::plugin_info_field(&info, "name"),
            uuid: plugin.plugin_id.clone(),
            icon_url: String::new(),
            creator: Default::default(),
            describe: String::new(),
            version,
            home: String::new(),
            update_url,
            npm_name,
        },
    }))
}

async fn install_update_item(
    state: &AppState,
    item: &crate::plugin_store::CloudPluginItem,
) -> Result<crate::api::admin::InstallPluginResponse> {
    let bundle = crate::plugin_store::download_catalog_bundle(&state.http_client, item).await?;
    plugin_store::install_validated_bundle(
        state,
        &item.manifest.uuid,
        &item.manifest.version,
        &bundle,
    )
    .await
    .map_err(|error| anyhow::anyhow!("{error:?}"))
}

fn compare_versions(left_raw: &str, right_raw: &str) -> Ordering {
    let left = tokenize_version(left_raw);
    let right = tokenize_version(right_raw);
    let length = left.len().max(right.len());
    for index in 0..length {
        let left_token = left.get(index).cloned().unwrap_or(VersionToken::Number(0));
        let right_token = right.get(index).cloned().unwrap_or(VersionToken::Number(0));
        let ordering = compare_tokens(&left_token, &right_token);
        if ordering != Ordering::Equal {
            return ordering;
        }
    }
    Ordering::Equal
}

#[derive(Clone, Debug, Eq, PartialEq)]
enum VersionToken {
    Number(u64),
    Text(String),
}

fn compare_tokens(left: &VersionToken, right: &VersionToken) -> Ordering {
    match (left, right) {
        (VersionToken::Number(left), VersionToken::Number(right)) => left.cmp(right),
        (VersionToken::Text(left), VersionToken::Text(right)) => left.cmp(right),
        (VersionToken::Number(_), VersionToken::Text(_)) => Ordering::Greater,
        (VersionToken::Text(_), VersionToken::Number(_)) => Ordering::Less,
    }
}

fn tokenize_version(raw: &str) -> Vec<VersionToken> {
    let mut normalized = raw.trim();
    if normalized.len() >= 2
        && matches!(normalized.as_bytes()[0], b'v' | b'V')
        && normalized.as_bytes()[1].is_ascii_alphanumeric()
    {
        normalized = &normalized[1..];
    }

    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut current_is_digit = None;
    for character in normalized.chars() {
        let is_digit = character.is_ascii_digit();
        if !character.is_ascii_alphanumeric() {
            flush_token(&mut tokens, &mut current, current_is_digit);
            current_is_digit = None;
            continue;
        }
        if current_is_digit.is_some_and(|kind| kind != is_digit) {
            flush_token(&mut tokens, &mut current, current_is_digit);
        }
        current.push(character.to_ascii_lowercase());
        current_is_digit = Some(is_digit);
    }
    flush_token(&mut tokens, &mut current, current_is_digit);
    if tokens.is_empty() {
        tokens.push(VersionToken::Text(normalized.to_ascii_lowercase()));
    }
    tokens
}

fn flush_token(
    tokens: &mut Vec<VersionToken>,
    current: &mut String,
    current_is_digit: Option<bool>,
) {
    if current.is_empty() {
        return;
    }
    if current_is_digit == Some(true) {
        tokens.push(VersionToken::Number(current.parse().unwrap_or(u64::MAX)));
    } else {
        tokens.push(VersionToken::Text(std::mem::take(current)));
    }
    current.clear();
}

#[cfg(test)]
mod tests {
    use std::cmp::Ordering;

    use super::compare_versions;

    #[test]
    fn compares_versions_like_the_client_updater() {
        assert_eq!(compare_versions("1.2.0", "1.1.9"), Ordering::Greater);
        assert_eq!(compare_versions("v2.0.0", "2.0.0"), Ordering::Equal);
        assert_eq!(compare_versions("1.0.0-beta", "1.0.0"), Ordering::Less);
        assert_eq!(compare_versions("1.0.0", "1.0.0-beta"), Ordering::Greater);
        assert_eq!(compare_versions("2026.8", "2026.10"), Ordering::Less);
    }
}
