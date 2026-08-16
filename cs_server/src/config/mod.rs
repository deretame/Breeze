use std::net::{IpAddr, SocketAddr};
use std::path::PathBuf;

use anyhow::{Context, bail};
use axum::http::HeaderValue;

#[derive(Clone, Debug)]
pub struct ServerConfig {
    pub host: IpAddr,
    pub port: u16,
    pub data_dir: PathBuf,
    pub web_root: PathBuf,
    pub plugin_root: PathBuf,
    pub server_download_enabled: bool,
    pub registration_enabled: bool,
    pub session_ttl_days: u64,
    pub admin_token: Option<String>,
    pub cors_origin: Option<HeaderValue>,
    pub http_proxy: Option<String>,
    pub socks5_proxy: Option<String>,
    pub disable_tls_verify: bool,
    pub allow_private_network: bool,
}

impl ServerConfig {
    pub fn from_env() -> anyhow::Result<Self> {
        let host: IpAddr = parse_env("BREEZE_SERVER_HOST", "127.0.0.1")?.parse()?;
        let port = parse_env("BREEZE_SERVER_PORT", "8787")?.parse()?;
        let data_dir = PathBuf::from(parse_env("BREEZE_DATA_DIR", "cs_server/data")?);
        let web_root = PathBuf::from(parse_env("BREEZE_WEB_ROOT", "cs_web/dist")?);
        let plugin_root = PathBuf::from(parse_env("BREEZE_PLUGIN_ROOT", "cs_server/plugins")?);
        let server_download_enabled = parse_bool_env("BREEZE_SERVER_DOWNLOAD", false)?;
        let registration_enabled = parse_bool_env("BREEZE_ALLOW_REGISTRATION", host.is_loopback())?;
        let session_ttl_days = parse_env("BREEZE_SESSION_TTL_DAYS", "30")?.parse()?;
        let admin_token = parse_optional_string("BREEZE_ADMIN_TOKEN");
        let cors_origin = parse_optional_header("BREEZE_CORS_ORIGIN")?;
        let http_proxy = parse_optional_string("BREEZE_HTTP_PROXY");
        let socks5_proxy = parse_optional_string("BREEZE_SOCKS5_PROXY");
        let disable_tls_verify = parse_bool_env("BREEZE_DISABLE_TLS_VERIFY", false)?;
        let allow_private_network = parse_bool_env("BREEZE_ALLOW_PRIVATE_NETWORK", false)?;

        if http_proxy.is_some() && socks5_proxy.is_some() {
            bail!("configure either BREEZE_HTTP_PROXY or BREEZE_SOCKS5_PROXY, not both");
        }

        Ok(Self {
            host,
            port,
            data_dir,
            web_root,
            plugin_root,
            server_download_enabled,
            registration_enabled,
            session_ttl_days,
            admin_token,
            cors_origin,
            http_proxy,
            socks5_proxy,
            disable_tls_verify,
            allow_private_network,
        })
    }

    pub fn bind_addr(&self) -> SocketAddr {
        SocketAddr::from((self.host, self.port))
    }

    pub fn web_frontend_enabled(&self) -> bool {
        self.web_root.join("index.html").is_file()
    }

    pub fn asset_root(&self) -> PathBuf {
        self.data_dir.join("assets")
    }

    pub fn http_client_config(&self) -> rquickjs_playground::HttpClientConfig {
        rquickjs_playground::HttpClientConfig {
            use_http_proxy: self.http_proxy.is_some(),
            use_socks5_proxy: self.socks5_proxy.is_some(),
            http_proxy: self.http_proxy.clone(),
            socks5_proxy: self.socks5_proxy.clone(),
            disable_tls_verify: self.disable_tls_verify,
            allow_private_network: self.allow_private_network,
        }
    }
}

fn parse_env(name: &str, default: &str) -> anyhow::Result<String> {
    Ok(std::env::var(name).unwrap_or_else(|_| default.to_owned()))
}

fn parse_optional_string(name: &str) -> Option<String> {
    std::env::var(name)
        .ok()
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

fn parse_optional_header(name: &str) -> anyhow::Result<Option<HeaderValue>> {
    let Some(value) = parse_optional_string(name) else {
        return Ok(None);
    };
    Ok(Some(
        value
            .parse()
            .with_context(|| format!("invalid {name} header value"))?,
    ))
}

fn parse_bool_env(name: &str, default: bool) -> anyhow::Result<bool> {
    let value = std::env::var(name).unwrap_or_else(|_| default.to_string());
    match value.trim().to_ascii_lowercase().as_str() {
        "1" | "true" | "yes" | "on" => Ok(true),
        "0" | "false" | "no" | "off" => Ok(false),
        _ => bail!("invalid boolean value for {name}: {value}"),
    }
}
