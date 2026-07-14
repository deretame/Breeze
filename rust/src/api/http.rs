use crate::frb_generated::StreamSink;
use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use reqwest::header::{HeaderMap, HeaderName, HeaderValue};
use reqwest::{Client, Method};
use rquickjs_playground::{
    BuildHttpClientOptions, build_http_client_ex, current_http_client_config,
};
use std::collections::HashMap;
use std::path::Path;
use std::time::Duration;
use tokio::io::AsyncWriteExt;

/// 客户端级默认配置。
#[frb]
#[derive(Clone, Debug, Default)]
pub struct HttpClientOptions {
    pub base_url: Option<String>,
    pub default_headers: Option<HashMap<String, String>>,
    /// 整请求超时（毫秒），默认 30000。
    pub timeout_ms: Option<u64>,
    /// 连接超时（毫秒），默认 15000。
    pub connect_timeout_ms: Option<u64>,
    /// 是否跟随重定向，默认 true。
    pub follow_redirects: Option<bool>,
    /// 强制直连、忽略代理。
    pub no_proxy: Option<bool>,
    /// 覆盖本次客户端使用的 HTTP 代理（例如 `http://127.0.0.1:7890`）。
    /// 设置后优先于全局代理配置。
    pub http_proxy: Option<String>,
    /// 覆盖全局 TLS 校验；`None` 时跟随全局配置。
    pub danger_accept_invalid_certs: Option<bool>,
    pub user_agent: Option<String>,
}

/// 单次 `fetch` 的 init（对齐 Fetch API 的 RequestInit）。
#[frb]
#[derive(Clone, Debug, Default)]
pub struct FetchInit {
    pub method: Option<String>,
    pub headers: Option<HashMap<String, String>>,
    pub query: Option<HashMap<String, String>>,
    pub body: Option<Vec<u8>>,
    pub timeout_ms: Option<u64>,
    pub follow_redirects: Option<bool>,
}

/// Fetch 响应。
#[frb]
#[derive(Clone, Debug)]
pub struct FetchResponse {
    pub status: u16,
    pub status_text: String,
    pub ok: bool,
    pub headers: HashMap<String, String>,
    pub body: Vec<u8>,
    pub url: String,
    pub redirected: bool,
}

/// 下载进度事件。
#[frb]
#[derive(Clone, Debug)]
pub struct HttpProgress {
    pub received: u64,
    pub total: Option<u64>,
}

/// 基于 reqwest 的 HTTP 客户端（opaque）。
///
/// 底层 `reqwest::Client` 由 `rquickjs_playground::build_http_client_ex` 创建，
/// 与 QuickJS 插件侧共用同一套代理 / TLS 配置。
#[frb(opaque)]
pub struct HttpClient {
    client: Client,
    base_url: String,
    default_headers: HashMap<String, String>,
    timeout_ms: u64,
}

impl HttpClient {
    #[frb(sync)]
    pub fn new() -> Result<Self> {
        Self::create(None)
    }

    #[frb(sync)]
    pub fn create(options: Option<HttpClientOptions>) -> Result<Self> {
        let options = options.unwrap_or_default();
        let timeout_ms = options.timeout_ms.unwrap_or(30_000);
        let client = create_reqwest_client(&options)?;
        Ok(Self {
            client,
            base_url: options.base_url.unwrap_or_default(),
            default_headers: options.default_headers.unwrap_or_default(),
            timeout_ms,
        })
    }

    #[frb(sync)]
    pub fn direct() -> Result<Self> {
        Self::create(Some(HttpClientOptions {
            no_proxy: Some(true),
            ..Default::default()
        }))
    }

    #[frb(sync)]
    pub fn base_url(&self) -> String {
        self.base_url.clone()
    }

    #[frb(sync)]
    pub fn default_headers(&self) -> HashMap<String, String> {
        self.default_headers.clone()
    }

    /// 核心 API：`fetch(url, init?)`。
    pub async fn fetch(&self, url: String, init: Option<FetchInit>) -> Result<FetchResponse> {
        let init = init.unwrap_or_default();
        let method_raw = init
            .method
            .as_deref()
            .unwrap_or("GET")
            .trim()
            .to_ascii_uppercase();
        let method = Method::from_bytes(method_raw.as_bytes())
            .map_err(|e| anyhow!("invalid http method {method_raw}: {e}"))?;

        let input_url = url.clone();
        let resolved = self.resolve_url(&url);
        let mut builder = self.client.request(method, &resolved);
        builder = self.apply_default_headers(builder);
        builder = apply_headers(builder, init.headers.as_ref())?;
        if let Some(query) = init.query.as_ref() {
            builder = builder.query(query);
        }
        if let Some(body) = init.body {
            builder = builder.body(body);
        }

        let timeout_ms = init.timeout_ms.unwrap_or(self.timeout_ms);
        builder = builder.timeout(Duration::from_millis(timeout_ms));
        let _ = init.follow_redirects;

        let response = builder
            .send()
            .await
            .map_err(|e| anyhow!("fetch failed: {e}"))?;

        let status = response.status();
        let status_code = status.as_u16();
        let status_text = status.canonical_reason().unwrap_or("").to_string();
        let final_url = response.url().to_string();
        let redirected = final_url != resolved && final_url != input_url;
        let headers = flatten_headers(response.headers());
        let body = response
            .bytes()
            .await
            .map_err(|e| anyhow!("read response body failed: {e}"))?
            .to_vec();

        Ok(FetchResponse {
            status: status_code,
            status_text,
            ok: (200..300).contains(&status_code),
            headers,
            body,
            url: final_url,
            redirected,
        })
    }

    /// 下载到本地文件（流式写盘）。
    pub async fn download(
        &self,
        url: String,
        save_path: String,
        init: Option<FetchInit>,
        progress: Option<StreamSink<HttpProgress>>,
    ) -> Result<()> {
        let init = init.unwrap_or_default();
        let method_raw = init
            .method
            .as_deref()
            .unwrap_or("GET")
            .trim()
            .to_ascii_uppercase();
        let method = Method::from_bytes(method_raw.as_bytes())
            .map_err(|e| anyhow!("invalid http method {method_raw}: {e}"))?;

        let resolved = self.resolve_url(&url);
        let mut builder = self.client.request(method, &resolved);
        builder = self.apply_default_headers(builder);
        builder = apply_headers(builder, init.headers.as_ref())?;
        if let Some(query) = init.query.as_ref() {
            builder = builder.query(query);
        }
        if let Some(body) = init.body {
            builder = builder.body(body);
        }
        let timeout_ms = init.timeout_ms.unwrap_or(self.timeout_ms);
        builder = builder.timeout(Duration::from_millis(timeout_ms));

        let response = builder
            .send()
            .await
            .map_err(|e| anyhow!("download failed: {e}"))?;

        let status = response.status();
        if !status.is_success() {
            return Err(anyhow!(
                "download bad status {}: {}",
                status.as_u16(),
                resolved
            ));
        }

        let total = response.content_length();
        let path = Path::new(&save_path);
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent)
                .await
                .map_err(|e| anyhow!("create download dir failed: {e}"))?;
        }

        let tmp_path = format!("{save_path}.part");
        let mut file = tokio::fs::File::create(&tmp_path)
            .await
            .map_err(|e| anyhow!("create download file failed: {e}"))?;

        let mut received: u64 = 0;
        let mut stream = response;
        loop {
            match stream.chunk().await {
                Ok(Some(chunk)) => {
                    file.write_all(&chunk)
                        .await
                        .map_err(|e| anyhow!("write download chunk failed: {e}"))?;
                    received += chunk.len() as u64;
                    if let Some(sink) = progress.as_ref() {
                        let _ = sink.add(HttpProgress { received, total });
                    }
                }
                Ok(None) => break,
                Err(e) => {
                    let _ = tokio::fs::remove_file(&tmp_path).await;
                    return Err(anyhow!("read download stream failed: {e}"));
                }
            }
        }

        file.flush()
            .await
            .map_err(|e| anyhow!("flush download file failed: {e}"))?;
        drop(file);

        tokio::fs::rename(&tmp_path, &save_path)
            .await
            .map_err(|e| anyhow!("finalize download file failed: {e}"))?;
        Ok(())
    }

    fn resolve_url(&self, url: &str) -> String {
        let url = url.trim();
        if url.starts_with("http://") || url.starts_with("https://") {
            return url.to_string();
        }
        if self.base_url.is_empty() {
            return url.to_string();
        }
        let base = self.base_url.trim_end_matches('/');
        if url.starts_with('/') {
            format!("{base}{url}")
        } else {
            format!("{base}/{url}")
        }
    }

    fn apply_default_headers(
        &self,
        mut builder: reqwest::RequestBuilder,
    ) -> reqwest::RequestBuilder {
        for (k, v) in &self.default_headers {
            builder = builder.header(k.as_str(), v.as_str());
        }
        builder
    }
}

/// 快捷入口：每次新建客户端后 `fetch`。
#[frb]
pub async fn fetch(url: String, init: Option<FetchInit>) -> Result<FetchResponse> {
    HttpClient::new()?.fetch(url, init).await
}

/// 快捷入口：每次新建直连客户端后 `fetch`。
#[frb]
pub async fn fetch_direct(url: String, init: Option<FetchInit>) -> Result<FetchResponse> {
    HttpClient::direct()?.fetch(url, init).await
}

fn create_reqwest_client(options: &HttpClientOptions) -> Result<Client> {
    let mut config = current_http_client_config();
    if let Some(disable_tls) = options.danger_accept_invalid_certs {
        config.disable_tls_verify = disable_tls;
    }
    if let Some(proxy) = options
        .http_proxy
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        config.use_http_proxy = true;
        config.http_proxy = Some(proxy.to_string());
        // 显式 HTTP 代理时不再叠 SOCKS5，避免探测语义混乱
        config.use_socks5_proxy = false;
        config.socks5_proxy = None;
    }

    build_http_client_ex(
        &config,
        BuildHttpClientOptions {
            no_proxy: options.no_proxy.unwrap_or(false),
            timeout: Some(Duration::from_millis(options.timeout_ms.unwrap_or(30_000))),
            connect_timeout: Some(Duration::from_millis(
                options.connect_timeout_ms.unwrap_or(15_000),
            )),
            follow_redirects: options.follow_redirects,
            user_agent: options.user_agent.clone(),
        },
    )
    .map_err(|e| anyhow!("failed to create http client: {e:#}"))
}

fn apply_headers(
    mut builder: reqwest::RequestBuilder,
    headers: Option<&HashMap<String, String>>,
) -> Result<reqwest::RequestBuilder> {
    if let Some(headers) = headers {
        for (k, v) in headers {
            let name = HeaderName::from_bytes(k.as_bytes())
                .map_err(|e| anyhow!("invalid header name {k}: {e}"))?;
            let value = HeaderValue::from_str(v)
                .map_err(|e| anyhow!("invalid header value for {k}: {e}"))?;
            builder = builder.header(name, value);
        }
    }
    Ok(builder)
}

fn flatten_headers(headers: &HeaderMap) -> HashMap<String, String> {
    let mut map = HashMap::new();
    for (name, value) in headers.iter() {
        let key = name.as_str().to_string();
        let val = value.to_str().unwrap_or_default().to_string();
        map.entry(key)
            .and_modify(|existing: &mut String| {
                existing.push_str(", ");
                existing.push_str(&val);
            })
            .or_insert(val);
    }
    map
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn fetch_example_com() {
        let client = HttpClient::create(Some(HttpClientOptions {
            no_proxy: Some(true),
            timeout_ms: Some(15_000),
            ..Default::default()
        }))
        .expect("create client");

        let response = client
            .fetch("https://example.com".into(), None)
            .await
            .expect("fetch example.com");

        assert!(response.ok, "unexpected status {}", response.status);
        assert!(!response.body.is_empty());
    }
}
