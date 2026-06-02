use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use reqwest_dav::re_exports::reqwest as dav_reqwest;
use reqwest_dav::types::list_cmd::ListResponse;
use reqwest_dav::{Auth, Client, ClientBuilder, DecodeError, Depth, Error as DavError};
use std::collections::{HashSet, VecDeque};
use std::time::Duration;

#[frb]
pub async fn webdav_test_connection(
    host: String,
    username: String,
    password: String,
) -> Result<()> {
    let client = build_client(&host, &username, &password)?;
    let _ = client
        .list("/", Depth::Number(0))
        .await
        .map_err(|e| anyhow!("WebDAV 连接测试失败: {e}"))?;
    Ok(())
}

#[frb]
pub async fn webdav_ensure_remote_ready(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
) -> Result<()> {
    let client = build_client(&host, &username, &password)?;
    ensure_directory(&client, &format!("/{sync_root_name}/")).await
}

#[frb]
pub async fn webdav_download_text(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
    remote_path: String,
) -> Result<String> {
    let client = build_client(&host, &username, &password)?;
    let path = normalize_any_managed_path(
        &remote_path,
        &sync_root_name,
        &legacy_data_root_name,
        &legacy_settings_root_name,
    )?;
    let response = client
        .get_raw(&path)
        .await
        .map_err(|e| anyhow!("md5 下载失败: {e}"))?;
    if response.status().as_u16() == 404 {
        return Ok(String::new());
    }
    let bytes = response
        .bytes()
        .await
        .map_err(|e| anyhow!("md5 下载失败: {e}"))?;
    Ok(String::from_utf8_lossy(&bytes).trim().to_string())
}

#[frb]
pub async fn webdav_upload_text(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
    remote_path: String,
    value: String,
) -> Result<()> {
    webdav_upload_bytes(
        host,
        username,
        password,
        sync_root_name,
        legacy_data_root_name,
        legacy_settings_root_name,
        remote_path,
        value.into_bytes(),
        "text/plain; charset=utf-8".to_string(),
    )
    .await
}

#[frb]
pub async fn webdav_list_remote_data_files(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
) -> Result<Vec<String>> {
    let client = build_client(&host, &username, &password)?;
    let sync_root = format!("/{sync_root_name}");
    let legacy_data_root = format!("/{legacy_data_root_name}");
    let legacy_settings_root = format!("/{legacy_settings_root_name}");

    let mut pending_dirs = VecDeque::from([
        sync_root.clone(),
        legacy_data_root.clone(),
        legacy_settings_root.clone(),
    ]);
    let mut visited_dirs = HashSet::new();
    let mut paths = HashSet::new();

    while let Some(current_dir) = pending_dirs.pop_front() {
        let current_dir = normalize_remote_path(&current_dir)?;
        if current_dir.is_empty() || !visited_dirs.insert(current_dir.clone()) {
            continue;
        }

        let entries = match client
            .list_rsp(&directory_request_path(&current_dir), Depth::Number(1))
            .await
        {
            Ok(entries) => entries,
            Err(DavError::Decode(DecodeError::StatusMismatched(status)))
                if status.response_code == 404 || status.response_code == 409 =>
            {
                Vec::new()
            }
            Err(e) => return Err(anyhow!("WebDAV 服务请求失败: {e}")),
        };
        for entry in entries {
            let normalized = normalize_managed_href(
                &entry.href,
                &sync_root,
                &legacy_data_root,
                &legacy_settings_root,
            )?;
            if normalized == sync_root
                || normalized == legacy_data_root
                || normalized == legacy_settings_root
            {
                continue;
            }

            let is_directory = is_directory_entry(&entry, &normalized);
            paths.insert(normalized.clone());
            if is_directory {
                pending_dirs.push_back(normalized);
            }
        }
    }

    let mut result: Vec<String> = paths.into_iter().collect();
    result.sort();
    Ok(result)
}

#[frb]
pub async fn webdav_download_file(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
    remote_path: String,
) -> Result<Vec<u8>> {
    let client = build_client(&host, &username, &password)?;
    let request_path = normalize_any_managed_path(
        &remote_path,
        &sync_root_name,
        &legacy_data_root_name,
        &legacy_settings_root_name,
    )?;
    download_file_with_retry(&client, &request_path).await
}

#[frb]
pub async fn webdav_upload_bytes(
    host: String,
    username: String,
    password: String,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
    remote_path: String,
    data: Vec<u8>,
    content_type: String,
) -> Result<()> {
    let client = build_client(&host, &username, &password)?;
    let path = normalize_any_managed_path(
        &remote_path,
        &sync_root_name,
        &legacy_data_root_name,
        &legacy_settings_root_name,
    )?;
    upload_bytes(&client, &path, data, &content_type).await
}

#[frb]
pub async fn webdav_delete_remote_files(
    host: String,
    username: String,
    password: String,
    remote_paths: Vec<String>,
    sync_root_name: String,
    legacy_data_root_name: String,
    legacy_settings_root_name: String,
) -> Result<()> {
    let client = build_client(&host, &username, &password)?;
    let mut normalized: Vec<String> = remote_paths
        .into_iter()
        .filter_map(|path| {
            normalize_any_managed_path(
                &path,
                &sync_root_name,
                &legacy_data_root_name,
                &legacy_settings_root_name,
            )
            .ok()
        })
        .filter(|path| {
            path != &format!("/{sync_root_name}")
                && path != &format!("/{legacy_data_root_name}")
                && path != &format!("/{legacy_settings_root_name}")
        })
        .collect();

    normalized.sort_by(|a, b| {
        let a_depth = path_depth(a);
        let b_depth = path_depth(b);
        if a_depth == b_depth {
            b.cmp(a)
        } else {
            b_depth.cmp(&a_depth)
        }
    });
    normalized.dedup();

    for path in normalized {
        let response = client
            .delete_raw(&path)
            .await
            .map_err(|e| anyhow!("文件删除失败: {e}"))?;
        let code = response.status().as_u16();
        if code == 404 {
            continue;
        }
        if !(code == 200 || code == 202 || code == 204) {
            return Err(anyhow!("文件删除失败，状态码: {code}"));
        }
    }

    Ok(())
}

fn build_client(host: &str, username: &str, password: &str) -> Result<Client> {
    if host.trim().is_empty() || username.trim().is_empty() || password.is_empty() {
        return Err(anyhow!("WebDAV 配置不完整"));
    }

    ClientBuilder::new()
        .set_host(host.trim().to_string())
        .set_auth(Auth::Basic(
            username.trim().to_string(),
            password.to_string(),
        ))
        .set_agent(
            dav_reqwest::ClientBuilder::new()
                .timeout(Duration::from_secs(10))
                .build()
                .map_err(|e| anyhow!("构建 HTTP 客户端失败: {e}"))?,
        )
        .build()
        .map_err(|e| anyhow!("构建 WebDAV 客户端失败: {e}"))
}

async fn ensure_directory(client: &Client, dir_path: &str) -> Result<()> {
    match client.list_raw(dir_path, Depth::Number(0)).await {
        Ok(response) => {
            let code = response.status().as_u16();
            if matches!(code, 200 | 207 | 301 | 302 | 403 | 405) {
                return Ok(());
            }
        }
        _ => {}
    }

    match client.mkcol_raw(dir_path).await {
        Ok(response) => {
            let code = response.status().as_u16();
            if matches!(code, 201 | 204 | 405 | 301 | 302) {
                Ok(())
            } else {
                Err(anyhow!("目录创建失败，状态码: {code}"))
            }
        }
        Err(e) => Err(anyhow!("目录创建失败: {e}")),
    }
}

async fn download_file_with_retry(client: &Client, request_path: &str) -> Result<Vec<u8>> {
    const MAX_RETRIES: usize = 3;

    for _ in 0..MAX_RETRIES {
        let response = client
            .get_raw(request_path)
            .await
            .map_err(|e| anyhow!("文件下载失败: {e}"))?;
        let code = response.status().as_u16();
        if code == 200 || code == 206 {
            let bytes = response
                .bytes()
                .await
                .map_err(|e| anyhow!("文件下载失败: {e}"))?;
            return Ok(bytes.to_vec());
        }
        if code == 404 {
            return Err(anyhow!("文件不存在，状态码: {code}"));
        }
        if code == 409 || code == 423 || code == 429 || code >= 500 {
            tokio::time::sleep(Duration::from_secs(2)).await;
            continue;
        }
        return Err(anyhow!("文件下载失败，状态码: {code}"));
    }

    Err(anyhow!("文件下载失败，重试次数用尽"))
}

async fn upload_bytes(
    client: &Client,
    remote_path: &str,
    data: Vec<u8>,
    content_type: &str,
) -> Result<()> {
    let response = client
        .start_request(dav_reqwest::Method::PUT, remote_path)
        .await
        .map_err(|e| anyhow!("文件上传失败: {e}"))?
        .header(
            dav_reqwest::header::CONTENT_TYPE,
            dav_reqwest::header::HeaderValue::from_str(content_type)
                .map_err(|e| anyhow!("文件上传失败: {e}"))?,
        )
        .body(data)
        .send()
        .await
        .map_err(|e| anyhow!("文件上传失败: {e}"))?;
    let code = response.status().as_u16();
    if code == 201 || code == 204 || code == 200 {
        Ok(())
    } else {
        Err(anyhow!("文件上传失败，状态码: {code}"))
    }
}

fn normalize_remote_path(remote_path: &str) -> Result<String> {
    let trimmed = remote_path.trim();
    if trimmed.is_empty() {
        return Err(anyhow!("远端路径不能为空"));
    }

    let raw_path = if let Ok(url) = url::Url::parse(trimmed) {
        url.path().to_string()
    } else {
        trimmed.to_string()
    };
    let mut normalized = raw_path.replace('\\', "/");
    while normalized.contains("//") {
        normalized = normalized.replace("//", "/");
    }
    if !normalized.starts_with('/') {
        normalized = format!("/{normalized}");
    }
    if normalized.len() > 1 && normalized.ends_with('/') {
        normalized.pop();
    }
    Ok(normalized)
}

fn normalize_any_managed_path(
    remote_path: &str,
    sync_root_name: &str,
    legacy_data_root_name: &str,
    legacy_settings_root_name: &str,
) -> Result<String> {
    let normalized = normalize_remote_path(remote_path)?;
    if normalized == format!("/{sync_root_name}")
        || normalized.starts_with(&format!("/{sync_root_name}/"))
        || normalized == format!("/{legacy_data_root_name}")
        || normalized.starts_with(&format!("/{legacy_data_root_name}/"))
        || normalized == format!("/{legacy_settings_root_name}")
        || normalized.starts_with(&format!("/{legacy_settings_root_name}/"))
    {
        Ok(normalized)
    } else {
        Ok(format!(
            "/{sync_root_name}/{}",
            normalized.trim_start_matches('/')
        ))
    }
}

fn normalize_managed_href(
    href: &str,
    sync_root: &str,
    legacy_data_root: &str,
    legacy_settings_root: &str,
) -> Result<String> {
    let normalized = normalize_remote_path(href)?;
    if let Some(stripped) = strip_to_managed_root(&normalized, sync_root) {
        return Ok(stripped);
    }
    if let Some(stripped) = strip_to_managed_root(&normalized, legacy_data_root) {
        return Ok(stripped);
    }
    if let Some(stripped) = strip_to_managed_root(&normalized, legacy_settings_root) {
        return Ok(stripped);
    }
    Ok(normalized)
}

fn strip_to_managed_root(path: &str, root: &str) -> Option<String> {
    if root.is_empty() {
        return None;
    }

    let root = if root.starts_with('/') {
        root.to_string()
    } else {
        format!("/{root}")
    };
    let root = root.trim_end_matches('/').to_string();

    if path == root {
        return Some(root);
    }

    let needle = format!("{root}/");
    path.find(&needle)
        .map(|index| path[index..].to_string())
        .or_else(|| path.rfind(&needle).map(|index| path[index..].to_string()))
}

fn path_depth(remote_path: &str) -> usize {
    remote_path
        .split('/')
        .filter(|part| !part.is_empty())
        .count()
}

fn directory_request_path(path: &str) -> String {
    let normalized = path.trim_end_matches('/');
    if normalized.is_empty() {
        "/".to_string()
    } else {
        format!("{normalized}/")
    }
}

fn is_directory_entry(entry: &ListResponse, normalized_href: &str) -> bool {
    if normalized_href.ends_with('/') {
        return true;
    }

    entry.prop_stat.iter().any(|prop_stat| {
        prop_stat.status.starts_with("HTTP/1.1 2")
            && prop_stat.prop.resource_type.collection.is_some()
    })
}
