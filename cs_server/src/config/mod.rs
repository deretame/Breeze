use std::net::{IpAddr, SocketAddr};
use std::path::{Path, PathBuf};

use anyhow::{Context, bail};
use axum::http::HeaderValue;
use serde::Deserialize;

#[derive(Clone, Debug)]
pub struct ServerConfig {
    pub host: IpAddr,
    pub port: u16,
    pub data_dir: PathBuf,
    pub web_root: PathBuf,
    pub plugin_root: PathBuf,
    pub plugin_install_enabled: bool,
    pub registration_enabled: bool,
    pub session_ttl_days: u64,
    pub admin_token: Option<String>,
    pub cors_origin: Option<HeaderValue>,
    pub http_proxy: Option<String>,
    pub socks5_proxy: Option<String>,
    pub disable_tls_verify: bool,
    pub allow_private_network: bool,
    pub log_filter: String,
}

impl ServerConfig {
    pub fn from_cli() -> anyhow::Result<Self> {
        let mut args = std::env::args().skip(1);
        let Some(argument) = args.next() else {
            return Self::from_file(Self::default_path()?);
        };

        if argument != "--config" {
            bail!("未知参数：{argument}；用法：breeze_cs_server [--config <path>]");
        }

        let path = args
            .next()
            .context("--config 后面必须提供 config.yaml 路径")?;
        if args.next().is_some() {
            bail!("--config 只能使用一次；用法：breeze_cs_server [--config <path>]");
        }
        Self::from_file(path)
    }

    pub fn default_path() -> anyhow::Result<PathBuf> {
        for candidate in [
            PathBuf::from("config.yaml"),
            PathBuf::from("cs_server/config.yaml"),
        ] {
            if candidate.is_file() {
                return Ok(candidate);
            }
        }

        bail!(
            "找不到服务端配置文件，请创建 cs_server/config.yaml，或使用 --config <path> 指定配置文件"
        )
    }

    pub fn from_file(path: impl AsRef<Path>) -> anyhow::Result<Self> {
        let path = path.as_ref();
        let contents = std::fs::read_to_string(path)
            .with_context(|| format!("读取服务端配置文件失败: {}", path.display()))?;
        let raw: RawServerConfig = serde_yaml::from_str(&contents)
            .with_context(|| format!("解析服务端 YAML 配置失败: {}", path.display()))?;
        let base_dir = path.parent().unwrap_or_else(|| Path::new("."));

        let host: IpAddr = raw
            .host
            .parse()
            .with_context(|| format!("配置 host 不是有效的 IP 地址: {}", raw.host))?;
        let data_dir = resolve_path(base_dir, raw.data_dir);
        let web_root = resolve_path(base_dir, raw.web_root);
        let plugin_root = resolve_path(base_dir, raw.plugin_root);
        let plugin_install_enabled = raw
            .allow_plugin_install
            .unwrap_or_else(|| host.is_loopback());
        let registration_enabled = raw.allow_registration.unwrap_or_else(|| host.is_loopback());
        let admin_token = trim_optional(raw.admin_token);
        let cors_origin = parse_optional_header(trim_optional(raw.cors_origin))?;
        let http_proxy = trim_optional(raw.http_proxy);
        let socks5_proxy = trim_optional(raw.socks5_proxy);

        if http_proxy.is_some() && socks5_proxy.is_some() {
            bail!("配置 http_proxy 和 socks5_proxy 时只能选择一个");
        }
        if raw.session_ttl_days == 0 {
            bail!("配置 session_ttl_days 必须大于 0");
        }

        Ok(Self {
            host,
            port: raw.port,
            data_dir,
            web_root,
            plugin_root,
            plugin_install_enabled,
            registration_enabled,
            session_ttl_days: raw.session_ttl_days,
            admin_token,
            cors_origin,
            http_proxy,
            socks5_proxy,
            disable_tls_verify: raw.disable_tls_verify,
            allow_private_network: raw.allow_private_network,
            log_filter: if raw.log_filter.trim().is_empty() {
                RawServerConfig::default().log_filter
            } else {
                raw.log_filter
            },
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

#[derive(Debug, Deserialize)]
#[serde(default)]
struct RawServerConfig {
    host: String,
    port: u16,
    data_dir: String,
    web_root: String,
    plugin_root: String,
    allow_plugin_install: Option<bool>,
    allow_registration: Option<bool>,
    session_ttl_days: u64,
    admin_token: Option<String>,
    cors_origin: Option<String>,
    http_proxy: Option<String>,
    socks5_proxy: Option<String>,
    disable_tls_verify: bool,
    allow_private_network: bool,
    log_filter: String,
}

impl Default for RawServerConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_owned(),
            port: 8787,
            data_dir: "data".to_owned(),
            web_root: "../cs_web/dist".to_owned(),
            plugin_root: "plugins".to_owned(),
            allow_plugin_install: None,
            allow_registration: None,
            session_ttl_days: 30,
            admin_token: None,
            cors_origin: None,
            http_proxy: None,
            socks5_proxy: None,
            disable_tls_verify: false,
            allow_private_network: false,
            log_filter: "breeze_cs_server=info,tower_http=info".to_owned(),
        }
    }
}

fn resolve_path(base_dir: &Path, value: String) -> PathBuf {
    let path = PathBuf::from(value);
    if path.is_absolute() {
        path
    } else {
        base_dir.join(path)
    }
}

fn trim_optional(value: Option<String>) -> Option<String> {
    value
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

fn parse_optional_header(value: Option<String>) -> anyhow::Result<Option<HeaderValue>> {
    let Some(value) = value else {
        return Ok(None);
    };
    Ok(Some(
        value
            .parse()
            .context("配置 cors_origin 不是有效的 HTTP HeaderValue")?,
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn yaml_defaults_and_optional_loopback_flags_are_preserved() {
        let raw: RawServerConfig = serde_yaml::from_str("host: 127.0.0.1\n").unwrap();

        assert_eq!(raw.port, 8787);
        assert_eq!(raw.data_dir, "data");
        assert!(raw.allow_plugin_install.is_none());
        assert!(raw.allow_registration.is_none());
    }

    #[test]
    fn relative_paths_are_resolved_from_config_directory() {
        let path = resolve_path(Path::new("cs_server"), "data".to_owned());

        assert_eq!(path, PathBuf::from("cs_server/data"));
    }
}
