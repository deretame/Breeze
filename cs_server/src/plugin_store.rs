use std::io::{Cursor, Read};

use anyhow::{Context, bail};
use reqwest::{Client, Url};
use serde::{Deserialize, Serialize};
use serde_json::Value;

pub const MAX_BUNDLE_BYTES: usize = 8 * 1024 * 1024;

const CLOUD_PLUGIN_LIST_API: &str = "https://api.windy-78.site/plugin-list";
const CLOUD_PLUGIN_LIST_VERSION: &str =
    "https://breeze-version.s3.bitiful.net/plugin-list-version.json";
const CLOUD_PLUGIN_LIST_DIRECT: &str =
    "https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json";
const CLOUD_PLUGIN_LIST_GITHUB_REPO: &str = "deretame/Breeze-plugin-list";
const CDN_MIRRORS: &[&str] = &[
    "https://jsdelivr.topthink.com/",
    "https://cdn.jsdmirror.com/",
    "https://cdn.jsdmirror.cn/",
    "https://www.webcache.cn/",
    "https://jsd.onmicrosoft.cn/",
    "https://cdn.jsdelivr.net/",
];

const GITHUB_CDN_MIRRORS: &[&str] = &[
    "https://cdn.jsdmirror.com/",
    "https://cdn.jsdmirror.cn/",
    "https://jsd.onmicrosoft.cn/",
    "https://cdn.jsdelivr.net/",
];

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CloudPluginItem {
    #[serde(default)]
    pub repo: String,
    pub manifest: CloudPluginManifest,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CloudPluginManifest {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub uuid: String,
    #[serde(rename = "iconUrl", default)]
    pub icon_url: String,
    #[serde(default)]
    pub creator: CloudPluginCreator,
    #[serde(default)]
    pub describe: String,
    #[serde(default)]
    pub version: String,
    #[serde(default)]
    pub home: String,
    #[serde(rename = "updateUrl", default)]
    pub update_url: String,
    #[serde(rename = "npmName", default)]
    pub npm_name: String,
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct CloudPluginCreator {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub describe: String,
}

pub async fn fetch_catalog(client: &Client) -> anyhow::Result<Vec<CloudPluginItem>> {
    let mut candidates = vec![CLOUD_PLUGIN_LIST_API.to_owned()];
    if let Ok(version_payload) = fetch_json(client, CLOUD_PLUGIN_LIST_VERSION).await {
        if let Some(version) = version_payload
            .get("version")
            .and_then(Value::as_str)
            .map(str::trim)
            .filter(|version| !version.is_empty())
        {
            candidates.extend(GITHUB_CDN_MIRRORS.iter().map(|mirror| {
                format!("{mirror}gh/{CLOUD_PLUGIN_LIST_GITHUB_REPO}@{version}/plugins_data.json")
            }));
        }
    }
    candidates.push(CLOUD_PLUGIN_LIST_DIRECT.to_owned());

    let mut last_error = None;
    for candidate in candidates {
        match fetch_json(client, &candidate).await {
            Ok(payload) => match parse_catalog_payload(payload) {
                Ok(items) if !items.is_empty() => return Ok(items),
                Ok(_) => last_error = Some(format!("插件目录为空: {candidate}")),
                Err(error) => last_error = Some(format!("插件目录格式错误: {candidate}: {error}")),
            },
            Err(error) => last_error = Some(format!("插件目录请求失败: {candidate}: {error}")),
        }
    }

    bail!(last_error.unwrap_or_else(|| "所有插件目录通道都不可用".to_owned()))
}

pub fn parse_catalog_payload(payload: Value) -> anyhow::Result<Vec<CloudPluginItem>> {
    let items = if let Some(items) = payload.as_array() {
        items.clone()
    } else if let Some(items) = payload.get("items").and_then(Value::as_array) {
        items.clone()
    } else {
        bail!("插件目录必须是数组或包含 items 数组的对象")
    };

    items
        .into_iter()
        .map(serde_json::from_value::<CloudPluginItem>)
        .filter_map(|result| match result {
            Ok(item) if !item.manifest.uuid.trim().is_empty() => Some(Ok(item)),
            Ok(_) => None,
            Err(error) => Some(Err(error)),
        })
        .collect::<Result<Vec<_>, _>>()
        .context("解析插件目录条目失败")
}

pub async fn download_catalog_bundle(
    client: &Client,
    item: &CloudPluginItem,
) -> anyhow::Result<String> {
    let manifest = &item.manifest;
    let mut last_error = None;

    if !manifest.npm_name.trim().is_empty() && !manifest.version.trim().is_empty() {
        for extension in [".cjs.br", ".cjs"] {
            let asset_path = format!(
                "npm/{}@{}/dist/{}.bundle{}",
                manifest.npm_name.trim(),
                manifest.version.trim(),
                manifest.npm_name.trim(),
                extension
            );
            for mirror in CDN_MIRRORS {
                let url = format!("{mirror}{asset_path}");
                match download_bundle_from_url(client, &url).await {
                    Ok(bundle) => return Ok(bundle),
                    Err(error) => last_error = Some(format!("{url}: {error}")),
                }
            }
        }
    }

    if !manifest.update_url.trim().is_empty() {
        let release = fetch_json(client, manifest.update_url.trim()).await?;
        let assets = release
            .get("assets")
            .and_then(Value::as_array)
            .cloned()
            .unwrap_or_default();
        for asset in assets {
            let name = asset
                .get("name")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_ascii_lowercase();
            if !name.ends_with(".cjs") && !name.ends_with(".cjs.br") {
                continue;
            }
            let Some(url) = asset
                .get("browser_download_url")
                .and_then(Value::as_str)
                .map(str::trim)
                .filter(|url| !url.is_empty())
            else {
                continue;
            };
            match download_bundle_from_url(client, url).await {
                Ok(bundle) => return Ok(bundle),
                Err(error) => last_error = Some(format!("{url}: {error}")),
            }
        }
    }

    bail!(last_error.unwrap_or_else(|| {
        format!(
            "插件没有可下载资源: npmName={}, updateUrl={}",
            manifest.npm_name, manifest.update_url
        )
    }))
}

pub async fn download_bundle_from_url(client: &Client, raw_url: &str) -> anyhow::Result<String> {
    let url = Url::parse(raw_url).context("插件下载地址不是合法 URL")?;
    if url.scheme() != "https" {
        bail!("插件下载地址只允许 HTTPS")
    }

    let response = client
        .get(url.clone())
        .header("accept", "*/*")
        .send()
        .await?
        .error_for_status()?;
    let bytes = response.bytes().await?;
    decode_plugin_bundle(&bytes, raw_url.ends_with(".br"))
}

pub fn decode_plugin_bundle(bytes: &[u8], brotli_encoded: bool) -> anyhow::Result<String> {
    if bytes.is_empty() || bytes.len() > MAX_BUNDLE_BYTES {
        bail!("插件 bundle 不能为空且不能超过 8 MiB")
    }

    let decoded = if brotli_encoded {
        let direct = String::from_utf8(bytes.to_vec()).ok();
        if direct
            .as_deref()
            .is_some_and(|source| source.contains("getInfo"))
        {
            direct
                .expect("direct UTF-8 source should be present")
                .into_bytes()
        } else {
            let mut decoder = brotli::Decompressor::new(Cursor::new(bytes), 4096);
            let mut output = Vec::new();
            decoder.read_to_end(&mut output)?;
            output
        }
    } else {
        bytes.to_vec()
    };

    if decoded.len() > MAX_BUNDLE_BYTES {
        bail!("解码后的插件 bundle 不能超过 8 MiB")
    }
    String::from_utf8(decoded).context("插件 bundle 不是有效 UTF-8 JavaScript")
}

pub fn plugin_info_field(info: &Value, key: &str) -> String {
    info.get(key)
        .and_then(Value::as_str)
        .or_else(|| {
            info.get("data")
                .and_then(|data| data.get(key))
                .and_then(Value::as_str)
        })
        .unwrap_or_default()
        .trim()
        .to_owned()
}

async fn fetch_json(client: &Client, url: &str) -> anyhow::Result<Value> {
    let response = client
        .get(url)
        .header("accept", "application/json, text/plain, */*")
        .send()
        .await?
        .error_for_status()?;
    Ok(response.json().await?)
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{decode_plugin_bundle, parse_catalog_payload, plugin_info_field};

    #[test]
    fn parses_the_real_catalog_shape_and_ignores_entries_without_uuid() {
        let items = parse_catalog_payload(json!([
            {
                "repo": "demo/source",
                "manifest": {
                    "uuid": "plugin-1",
                    "name": "Demo",
                    "npmName": "demo-plugin",
                    "version": "1.2.3",
                    "creator": {"name": "author"}
                }
            },
            {"repo": "invalid", "manifest": {"name": "missing uuid"}}
        ]))
        .expect("catalog should parse");

        assert_eq!(items.len(), 1);
        assert_eq!(items[0].manifest.uuid, "plugin-1");
        assert_eq!(items[0].manifest.npm_name, "demo-plugin");
        assert_eq!(items[0].manifest.creator.name, "author");
    }

    #[test]
    fn reads_plugin_info_from_root_or_data() {
        assert_eq!(plugin_info_field(&json!({"uuid": "root"}), "uuid"), "root");
        assert_eq!(
            plugin_info_field(&json!({"data": {"version": "nested"}}), "version"),
            "nested"
        );
    }

    #[test]
    fn decodes_brotli_plugin_source() {
        let source = b"module.exports = { getInfo: async () => ({ uuid: 'demo' }) };";
        let mut encoded = Vec::new();
        {
            let mut writer = brotli::CompressorWriter::new(&mut encoded, 4096, 5, 22);
            std::io::Write::write_all(&mut writer, source).expect("source should compress");
        }
        assert_eq!(
            decode_plugin_bundle(&encoded, true).expect("source should decompress"),
            String::from_utf8(source.to_vec()).expect("source should be UTF-8")
        );
    }
}
