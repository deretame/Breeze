use aes::cipher::BlockDecrypt;
use aes::{Aes128, Aes192, Aes256};
use aes_gcm::{
    Aes128Gcm, Aes256Gcm, Nonce,
    aead::{Aead, KeyInit as AeadKeyInit, Payload as AeadPayload},
};
use anyhow::{Context as AnyhowContext, Result as AnyResult, anyhow};
use base64::Engine as Base64Engine;
use base64::engine::general_purpose::{STANDARD as BASE64_STANDARD, URL_SAFE as BASE64_URL_SAFE};
use cbc::cipher::{BlockDecryptMut, BlockEncryptMut, KeyIvInit, block_padding::Pkcs7};
use cbc::{Decryptor as CbcDecryptor, Encryptor as CbcEncryptor};
use flate2::Compression;
use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use serde::Deserialize;
use serde_json::Map;
use serde_json::{Value, json};
use std::collections::HashMap;
use std::fs;
use std::future::Future;
use std::io;
use std::io::Read;
use std::io::Write;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};
use std::path::{Path, PathBuf};
use std::pin::Pin;
#[cfg(target_os = "macos")]
use std::process::Command;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::mpsc::{self, TryRecvError};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use getrandom::fill as random_fill;
use hmac::{Hmac, Mac};
use pbkdf2::pbkdf2_hmac;
use reqwest::multipart::{Form as MultipartForm, Part as MultipartPart};
use reqwest::{Client, Method, Proxy};
use sha1::Sha1;
use sha2::{Digest, Sha256, Sha512};
#[cfg(windows)]
use windows_registry::CURRENT_USER;

use filetime::{FileTime, set_file_times};
use rquickjs::{Ctx, Function, function::Func};
use tokio::net::lookup_host;
use tokio::sync::Semaphore;
use tokio::task::JoinHandle;
use tokio::time::timeout;
use url::form_urlencoded;
use uuid::Uuid;

mod bridge;
mod fs_ops;
mod http;
mod native_buffer;
mod state;
mod url_headers;

pub use self::bridge::{
    BridgeRuntimeConfig, bridge_pending_count, configure_bridge_runtime,
    current_bridge_runtime_config, host_call, host_call_drop, host_call_start, host_call_try_take,
    register_bridge_route_async_handler, register_bridge_route_blocking_handler,
    register_bridge_route_sync_handler, unregister_bridge_route_handler,
};
pub use self::http::{
    HttpClientConfig, configure_http_client, current_http_client_config, http_request_drop,
    http_request_drop_evented, http_request_start, http_request_start_evented,
    http_request_try_take, set_worker_http_config,
};
pub use self::native_buffer::{
    native_buffer_free, native_buffer_put, native_buffer_put_raw, native_buffer_take,
    native_buffer_take_raw, native_exec, native_exec_chain,
};
pub use self::state::{
    body_state_is_consumed, body_state_register, body_state_try_consume, fetch_state_can_clone,
    fetch_state_register, fetch_state_take_offloaded, fetch_state_try_consume,
};
pub use self::url_headers::{headers_query, headers_rewrite, urlsp_query, urlsp_rewrite};

use self::bridge::{BridgeRouteAsyncHandler, BridgeRouteBlockingHandler, BridgeRouteSyncHandler};
use self::fs_ops::{
    fs_access, fs_chmod, fs_copy_file, fs_cp, fs_link, fs_lstat, fs_mkdir, fs_mkdtemp,
    fs_read_file, fs_readdir, fs_readlink, fs_realpath, fs_rename, fs_rm, fs_stat, fs_symlink,
    fs_task_dispatch, fs_truncate, fs_unlink, fs_utimes, fs_write_file,
};
use self::http::{
    HttpClientState, cleanup_stale_pending, cleanup_stale_pending_abort, decode_host_base64,
    http_io_sem, http_req_pool,
};
use self::native_buffer::{NATIVE_BUF_ID, native_pool, start_native_buffer_gc_loop};
use self::state::{cleanup_stale_body_state, cleanup_stale_fetch_state};

const WEB_POLYFILL_CORE: &str = concat!(
    include_str!("../js/04_runtime_base_polyfills.js"),
    "\n",
    include_str!("../js/00_bootstrap.js"),
    "\n",
    include_str!("../js/05_structured_clone.js"),
    "\n",
    include_str!("../js/06_url.js"),
    "\n",
    include_str!("../js/10_headers.js"),
    "\n",
    include_str!("../js/20_abort.js"),
    "\n",
    include_str!("../js/30_fetch.js"),
    "\n",
    include_str!("../js/60_native.js"),
    "\n",
    include_str!("../js/62_bridge.js"),
    "\n",
    include_str!("../js/63_stack_hook.js"),
    "\n",
    include_str!("../js/65_console.js"),
    "\n"
);

#[cfg(feature = "host-fs")]
const WEB_FS_POLYFILL: &str = concat!(include_str!("../js/50_fs.js"), "\n");

pub const WEB_POLYFILL: &str = concat!(
    include_str!("../js/04_runtime_base_polyfills.js"),
    "\n",
    include_str!("../js/00_bootstrap.js"),
    "\n",
    include_str!("../js/05_structured_clone.js"),
    "\n",
    include_str!("../js/06_url.js"),
    "\n",
    include_str!("../js/10_headers.js"),
    "\n",
    include_str!("../js/20_abort.js"),
    "\n",
    include_str!("../js/30_fetch.js"),
    "\n",
    include_str!("../js/60_native.js"),
    "\n",
    include_str!("../js/62_bridge.js"),
    "\n",
    include_str!("../js/63_stack_hook.js"),
    "\n",
    include_str!("../js/65_console.js"),
    "\n",
    include_str!("../js/99_exports.js"),
    "\n"
);

const WEB_REQUIRE_POLYFILL: &str = r#"(function () {
  if (typeof globalThis.require === "function") return;
  globalThis.require = function require(name) {
    if (name === "path") return globalThis.__web.path;
    if (name === "buffer") return globalThis.__web.bufferModule;
    if (name === "crypto") return globalThis.__web.cryptoModule;
    if (name === "uuidv4") return globalThis.__web.uuidv4Module;
    throw new Error(`Cannot find module '${name}'`);
  };
})();
"#;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct WebRuntimeOptions {
    pub fs: bool,
}

pub fn polyfill_script(options: WebRuntimeOptions) -> String {
    let mut script = String::from(WEB_POLYFILL_CORE);
    if !options.fs {
        script.push_str(WEB_REQUIRE_POLYFILL);
    }
    #[cfg(feature = "host-fs")]
    if options.fs {
        script.push_str(WEB_FS_POLYFILL);
    }
    script.push_str(include_str!("../js/99_exports.js"));
    script.push('\n');
    script
}

pub fn install_host_bindings(
    ctx: &Ctx<'_>,
    runtime_name: &str,
    options: WebRuntimeOptions,
) -> Result<(), rquickjs::Error> {
    if options.fs && !cfg!(feature = "host-fs") {
        return Err(rquickjs::Error::new_from_js_message(
            "rust",
            "runtime",
            "当前构建未启用 host-fs Cargo 特性",
        ));
    }
    let runtime_name = normalize_runtime_name(runtime_name);
    let globals = ctx.globals();
    globals.set("__http_request_start", Func::from(http_request_start))?;
    globals.set("__http_request_try_take", Func::from(http_request_try_take))?;
    globals.set("__http_request_drop", Func::from(http_request_drop))?;
    globals.set("__urlsp_rewrite", Func::from(urlsp_rewrite))?;
    globals.set("__urlsp_query", Func::from(urlsp_query))?;
    globals.set("__headers_rewrite", Func::from(headers_rewrite))?;
    globals.set("__headers_query", Func::from(headers_query))?;
    globals.set("__fetch_state_register", Func::from(fetch_state_register))?;
    globals.set(
        "__fetch_state_try_consume",
        Func::from(fetch_state_try_consume),
    )?;
    globals.set("__fetch_state_can_clone", Func::from(fetch_state_can_clone))?;
    globals.set(
        "__fetch_state_take_offloaded",
        Func::from(fetch_state_take_offloaded),
    )?;
    globals.set("__body_state_register", Func::from(body_state_register))?;
    globals.set(
        "__body_state_try_consume",
        Func::from(body_state_try_consume),
    )?;
    globals.set(
        "__body_state_is_consumed",
        Func::from(body_state_is_consumed),
    )?;
    globals.set("__native_buffer_put", Func::from(native_buffer_put))?;
    globals.set("__native_buffer_put_raw", Func::from(native_buffer_put_raw))?;
    globals.set("__native_buffer_take", Func::from(native_buffer_take))?;
    globals.set(
        "__native_buffer_take_raw",
        Func::from(native_buffer_take_raw),
    )?;
    globals.set("__native_buffer_free", Func::from(native_buffer_free))?;
    globals.set("__native_exec", Func::from(native_exec))?;
    globals.set("__native_exec_chain", Func::from(native_exec_chain))?;
    let runtime_name_for_host_call = runtime_name.clone();
    globals.set(
        "__host_call",
        Function::new(
            ctx.clone(),
            move |name: String, args_json: Option<String>| {
                host_call(runtime_name_for_host_call.clone(), name, args_json)
            },
        )?,
    )?;
    let runtime_name_for_host_call_start = runtime_name.clone();
    globals.set(
        "__host_call_start",
        Function::new(
            ctx.clone(),
            move |name: String, args_json: Option<String>| {
                host_call_start(runtime_name_for_host_call_start.clone(), name, args_json)
            },
        )?,
    )?;
    globals.set(
        "__host_call_route_mode",
        Function::new(ctx.clone(), move |name: String| {
            let mode =
                crate::web_runtime::bridge::bridge_route_mode(&name).map(|mode| match mode {
                    crate::web_runtime::bridge::BridgeRouteMode::Sync => "sync",
                    crate::web_runtime::bridge::BridgeRouteMode::Async => "async",
                    crate::web_runtime::bridge::BridgeRouteMode::Blocking => "blocking",
                });
            Ok::<_, rquickjs::Error>(mode.map(str::to_string))
        })?,
    )?;
    globals.set("__host_call_try_take", Func::from(host_call_try_take))?;
    globals.set("__host_call_drop", Func::from(host_call_drop))?;
    let log_emit_rt = runtime_name.to_string();
    globals.set(
        "__log_emit",
        Func::from(move |level: String, message: String| {
            log_emit(level, message, log_emit_rt.clone())
        }),
    )?;
    globals.set("__runtime_stats", Func::from(runtime_stats))?;
    globals.set("__crypto_sha1_b64", Func::from(crypto_sha1_b64))?;
    globals.set("__crypto_sha256_b64", Func::from(crypto_sha256_b64))?;
    globals.set("__crypto_sha512_b64", Func::from(crypto_sha512_b64))?;
    globals.set("__crypto_hmac_sha1_b64", Func::from(crypto_hmac_sha1_b64))?;
    globals.set(
        "__crypto_hmac_sha256_b64",
        Func::from(crypto_hmac_sha256_b64),
    )?;
    globals.set(
        "__crypto_hmac_sha512_b64",
        Func::from(crypto_hmac_sha512_b64),
    )?;
    globals.set(
        "__crypto_random_bytes_b64",
        Func::from(crypto_random_bytes_b64),
    )?;
    globals.set(
        "__crypto_aes_cbc_pkcs7_encrypt_b64",
        Func::from(crypto_aes_cbc_pkcs7_encrypt_b64),
    )?;
    globals.set(
        "__crypto_aes_cbc_pkcs7_decrypt_b64",
        Func::from(crypto_aes_cbc_pkcs7_decrypt_b64),
    )?;
    globals.set(
        "__crypto_aes_gcm_encrypt_b64",
        Func::from(crypto_aes_gcm_encrypt_b64),
    )?;
    globals.set(
        "__crypto_aes_gcm_decrypt_b64",
        Func::from(crypto_aes_gcm_decrypt_b64),
    )?;
    globals.set(
        "__crypto_pbkdf2_sha256_b64",
        Func::from(crypto_pbkdf2_sha256_b64),
    )?;
    globals.set(
        "__crypto_timing_safe_equal_b64",
        Func::from(crypto_timing_safe_equal_b64),
    )?;
    globals.set("__crypto_random_uuid_v4", Func::from(crypto_random_uuid_v4))?;
    #[cfg(feature = "host-fs")]
    if options.fs {
        globals.set("__fs_read_file", Func::from(fs_read_file))?;
        globals.set("__fs_write_file", Func::from(fs_write_file))?;
        globals.set("__fs_mkdir", Func::from(fs_mkdir))?;
        globals.set("__fs_readdir", Func::from(fs_readdir))?;
        globals.set("__fs_stat", Func::from(fs_stat))?;
        globals.set("__fs_access", Func::from(fs_access))?;
        globals.set("__fs_unlink", Func::from(fs_unlink))?;
        globals.set("__fs_rm", Func::from(fs_rm))?;
        globals.set("__fs_rename", Func::from(fs_rename))?;
        globals.set("__fs_copy_file", Func::from(fs_copy_file))?;
        globals.set("__fs_realpath", Func::from(fs_realpath))?;
        globals.set("__fs_lstat", Func::from(fs_lstat))?;
        globals.set("__fs_readlink", Func::from(fs_readlink))?;
        globals.set("__fs_symlink", Func::from(fs_symlink))?;
        globals.set("__fs_link", Func::from(fs_link))?;
        globals.set("__fs_truncate", Func::from(fs_truncate))?;
        globals.set("__fs_chmod", Func::from(fs_chmod))?;
        globals.set("__fs_utimes", Func::from(fs_utimes))?;
        globals.set("__fs_cp", Func::from(fs_cp))?;
        globals.set("__fs_mkdtemp", Func::from(fs_mkdtemp))?;
        globals.set("__fs_task_start", Func::from(fs_task_start))?;
        globals.set("__fs_task_try_take", Func::from(fs_task_try_take))?;
        globals.set("__fs_task_drop", Func::from(fs_task_drop))?;
    }
    globals.set("__sourcemap_lookup", Func::from(sourcemap_lookup))?;
    Ok(())
}

fn sourcemap_lookup(bundle_name: String, gen_line: f64, gen_col: f64) -> String {
    match crate::source_map::look_up(&bundle_name, gen_line as u32, gen_col as u32) {
        Some(r) => {
            json!({ "source": r.source, "line": r.line, "column": r.column, "name": r.name })
                .to_string()
        }
        None => String::new(),
    }
}

static HTTP_REQ_ID: AtomicU64 = AtomicU64::new(1);
static BODY_STATE_ID: AtomicU64 = AtomicU64::new(1);
static FETCH_STATE_ID: AtomicU64 = AtomicU64::new(1);
static HTTP_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static BRIDGE_REQ_ID: AtomicU64 = AtomicU64::new(1);
static BRIDGE_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static HTTP_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
static FS_REQ_ID: AtomicU64 = AtomicU64::new(1);
static FS_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static FS_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
static TIMER_REQ_ID: AtomicU64 = AtomicU64::new(1);
static TIMER_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
static HTTP_CLIENT_STATE: OnceLock<Mutex<HttpClientState>> = OnceLock::new();
static HTTP_IO_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
static FS_IO_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
static HTTP_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static HTTP_EVENT_COMPLETED: AtomicU64 = AtomicU64::new(0);
static HTTP_EVENT_CANCELED: AtomicU64 = AtomicU64::new(0);
static HTTP_EVENT_SUPPRESSED: AtomicU64 = AtomicU64::new(0);
static BRIDGE_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static FS_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static TIMER_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static LOG_TX: OnceLock<mpsc::Sender<LogEvent>> = OnceLock::new();
static LOG_HTTP_ENDPOINT: OnceLock<Mutex<Option<String>>> = OnceLock::new();
static LOG_HTTP_DIRECT_CLIENT: OnceLock<Client> = OnceLock::new();
static LOG_ENQUEUED: AtomicU64 = AtomicU64::new(0);
static LOG_WRITTEN: AtomicU64 = AtomicU64::new(0);
static LOG_DROPPED: AtomicU64 = AtomicU64::new(0);
static LOG_ERRORS: AtomicU64 = AtomicU64::new(0);
static LOG_PENDING: AtomicU64 = AtomicU64::new(0);
static BRIDGE_BYTES_IN: AtomicU64 = AtomicU64::new(0);
static BRIDGE_BYTES_OUT: AtomicU64 = AtomicU64::new(0);
static BRIDGE_DENIED: AtomicU64 = AtomicU64::new(0);
static BRIDGE_LIMIT_HITS: AtomicU64 = AtomicU64::new(0);
static NATIVE_BUF_GC_TTL_SECS: AtomicU64 = AtomicU64::new(DEFAULT_NATIVE_BUFFER_GC_TTL_SECS);
static NATIVE_BUF_GC_DROPS: AtomicU64 = AtomicU64::new(0);
static NATIVE_BUF_GC_LOOP_STARTED: OnceLock<()> = OnceLock::new();
static BODY_STATE_POOL: OnceLock<Mutex<HashMap<u64, BodyStateEntry>>> = OnceLock::new();
static BODY_CONSUME_REJECTS: AtomicU64 = AtomicU64::new(0);
static BODY_STATE_GC_DROPS: AtomicU64 = AtomicU64::new(0);
static FETCH_STATE_POOL: OnceLock<Mutex<HashMap<u64, FetchStateEntry>>> = OnceLock::new();
static FETCH_STATE_REJECTS: AtomicU64 = AtomicU64::new(0);
static FETCH_STATE_GC_DROPS: AtomicU64 = AtomicU64::new(0);
static BODY_STATE_OP_SEQ: AtomicU64 = AtomicU64::new(0);
static FETCH_STATE_OP_SEQ: AtomicU64 = AtomicU64::new(0);
static BRIDGE_ROUTE_SYNC_HANDLERS: OnceLock<Mutex<HashMap<String, BridgeRouteSyncHandler>>> =
    OnceLock::new();
static BRIDGE_ROUTE_ASYNC_HANDLERS: OnceLock<Mutex<HashMap<String, BridgeRouteAsyncHandler>>> =
    OnceLock::new();
static BRIDGE_ROUTE_BLOCKING_HANDLERS: OnceLock<
    Mutex<HashMap<String, BridgeRouteBlockingHandler>>,
> = OnceLock::new();
const HTTP_SYSTEM_PROXY_REFRESH_INTERVAL: Duration = Duration::from_secs(3);
const BRIDGE_BINARY_PROTOCOL: &str = "bridge-binary-v1";
const BRIDGE_ARGS_JSON_MAX_BYTES_DEFAULT: usize = 8 * 1024 * 1024;
const BRIDGE_RETURN_BINARY_MAX_BYTES_DEFAULT: usize = 32 * 1024 * 1024;

struct PendingTask {
    rx: mpsc::Receiver<String>,
    task: JoinHandle<()>,
    created_at: Instant,
    meta: PendingTaskMeta,
}

struct PendingAbortTask {
    task: JoinHandle<()>,
    created_at: Instant,
    meta: PendingAbortTaskMeta,
}

#[derive(Debug, Clone)]
struct PendingTaskMeta {
    kind: &'static str,
    label: String,
}

#[derive(Debug, Clone)]
struct PendingAbortTaskMeta {
    kind: &'static str,
    label: String,
}

struct NativeBufferEntry {
    bytes: Vec<u8>,
    created_at: Instant,
}

#[derive(Debug, Clone, Default)]
struct FetchObjectState {
    consumed: bool,
    offloaded: bool,
    offload_taken: bool,
    native_body: bool,
}

#[derive(Debug, Clone)]
struct BodyStateEntry {
    consumed: bool,
    created_at: Instant,
}

#[derive(Debug, Clone)]
struct FetchStateEntry {
    state: FetchObjectState,
    created_at: Instant,
}

const FETCH_STATE_TTL: Duration = Duration::from_secs(30 * 60);
const BODY_STATE_TTL: Duration = Duration::from_secs(30 * 60);
const STATE_GC_EVERY_OPS: u64 = 256;

impl NativeBufferEntry {
    fn new(bytes: Vec<u8>) -> Self {
        Self {
            bytes,
            created_at: Instant::now(),
        }
    }
}

#[derive(Debug, Clone)]
struct LogEvent {
    level: String,
    message: String,
    ts_ms: u128,
    runtime_name: String,
}

fn body_state_pool() -> &'static Mutex<HashMap<u64, BodyStateEntry>> {
    BODY_STATE_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn fetch_state_pool() -> &'static Mutex<HashMap<u64, FetchStateEntry>> {
    FETCH_STATE_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn fs_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    FS_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn fs_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    FS_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn timer_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    TIMER_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

const HTTP_MAX_IN_FLIGHT: usize = 256;
const FS_MAX_IN_FLIGHT: usize = 128;
const HTTP_OFFLOAD_BODY_HEADER: &str = "x-rquickjs-host-offload-binary-v1";
const HTTP_FORMDATA_BODY_HEADER: &str = "x-rquickjs-host-body-formdata-v1";
const HTTP_AUTO_OFFLOAD_SIZE_THRESHOLD: u64 = 1 * 1024 * 1024;
const HTTP_MAX_PENDING: usize = 4096;
const BRIDGE_MAX_PENDING: usize = 4096;
const FS_MAX_PENDING: usize = 4096;
const TIMER_MAX_PENDING: usize = 8192;
const PENDING_TASK_TTL: Duration = Duration::from_secs(120);
const NATIVE_BUFFER_GC_INTERVAL: Duration = Duration::from_secs(60);
const DEFAULT_NATIVE_BUFFER_GC_TTL_SECS: u64 = 15 * 60;

fn pending_task_debug_item(id: u64, pending: &PendingTask) -> Value {
    json!({
        "id": id,
        "kind": pending.meta.kind,
        "label": pending.meta.label,
        "elapsedMs": pending.created_at.elapsed().as_millis() as u64,
    })
}

fn pending_abort_task_debug_item(id: u64, pending: &PendingAbortTask) -> Value {
    json!({
        "id": id,
        "kind": pending.meta.kind,
        "label": pending.meta.label,
        "elapsedMs": pending.created_at.elapsed().as_millis() as u64,
    })
}

fn fs_io_sem() -> &'static Arc<Semaphore> {
    FS_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(FS_MAX_IN_FLIGHT)))
}

type HmacSha1 = Hmac<Sha1>;
type HmacSha256 = Hmac<Sha256>;
type HmacSha512 = Hmac<Sha512>;

fn bytes_to_hex(bytes: &[u8]) -> String {
    bytes
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect::<String>()
}

fn crypto_digest_b64<D: Digest + Default>(input_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let input = decode_host_base64(&input_b64).context("解析输入失败")?;
        let mut hasher = D::default();
        hasher.update(&input);
        let out = hasher.finalize();
        Ok(json!({
            "ok": true,
            "hex": bytes_to_hex(&out),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn aes_ecb_decrypt_pkcs7_b64(payload: &[u8], key: &[u8]) -> AnyResult<Vec<u8>> {
    if payload.len() % 16 != 0 {
        return Err(anyhow!("AES ECB 密文长度必须是 16 的倍数"));
    }
    let mut out = vec![0u8; payload.len()];
    match key.len() {
        16 => {
            let cipher =
                Aes128::new_from_slice(key).map_err(|_| anyhow!("AES-128 密钥长度无效"))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes128>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        24 => {
            let cipher =
                Aes192::new_from_slice(key).map_err(|_| anyhow!("AES-192 密钥长度无效"))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes192>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        32 => {
            let cipher =
                Aes256::new_from_slice(key).map_err(|_| anyhow!("AES-256 密钥长度无效"))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes256>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        _ => {
            return Err(anyhow!(
                "AES ECB 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    }

    let pad_len = *out.last().ok_or_else(|| anyhow!("AES ECB 解密结果为空"))? as usize;
    if pad_len == 0 || pad_len > 16 || pad_len > out.len() {
        return Err(anyhow!("AES ECB PKCS7 填充无效"));
    }
    if !out[out.len() - pad_len..]
        .iter()
        .all(|b| *b as usize == pad_len)
    {
        return Err(anyhow!("AES ECB PKCS7 填充无效"));
    }
    out.truncate(out.len() - pad_len);
    Ok(out)
}

fn crypto_sha256_b64(input_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let input = decode_host_base64(&input_b64).context("解析 sha256 输入失败")?;
        let mut hasher = Sha256::new();
        hasher.update(&input);
        let out = hasher.finalize();
        Ok(json!({
            "ok": true,
            "hex": format!("{:x}", out),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_sha1_b64(input_b64: String) -> String {
    crypto_digest_b64::<Sha1>(input_b64)
}

fn crypto_sha512_b64(input_b64: String) -> String {
    crypto_digest_b64::<Sha512>(input_b64)
}

fn crypto_hmac_sha256_b64(key_b64: String, input_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let key = decode_host_base64(&key_b64).context("解析 hmac key 失败")?;
        let input = decode_host_base64(&input_b64).context("解析 hmac 输入失败")?;
        let mut mac = <HmacSha256 as Mac>::new_from_slice(&key).context("初始化 hmac 失败")?;
        mac.update(&input);
        let out = mac.finalize().into_bytes();
        Ok(json!({
            "ok": true,
            "hex": format!("{:x}", out),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_random_bytes_b64(size: i32) -> String {
    let result: AnyResult<String> = (|| {
        if size < 0 {
            return Err(anyhow!("size 必须是非负整数"));
        }
        let n = usize::try_from(size).context("size 超出范围")?;
        let mut bytes = vec![0u8; n];
        if n > 0 {
            random_fill(&mut bytes).map_err(|e| anyhow!("生成随机字节失败: {e}"))?;
        }
        Ok(json!({
            "ok": true,
            "base64": BASE64_STANDARD.encode(bytes)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_hmac_sha1_b64(key_b64: String, input_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let key = decode_host_base64(&key_b64).context("解析 hmac key 失败")?;
        let input = decode_host_base64(&input_b64).context("解析 hmac 输入失败")?;
        let mut mac = <HmacSha1 as Mac>::new_from_slice(&key).context("初始化 hmac 失败")?;
        mac.update(&input);
        let out = mac.finalize().into_bytes();
        Ok(json!({
            "ok": true,
            "hex": format!("{:x}", out),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_hmac_sha512_b64(key_b64: String, input_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let key = decode_host_base64(&key_b64).context("解析 hmac key 失败")?;
        let input = decode_host_base64(&input_b64).context("解析 hmac 输入失败")?;
        let mut mac = <HmacSha512 as Mac>::new_from_slice(&key).context("初始化 hmac 失败")?;
        mac.update(&input);
        let out = mac.finalize().into_bytes();
        Ok(json!({
            "ok": true,
            "hex": format!("{:x}", out),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_aes_cbc_pkcs7_encrypt_b64(plain_b64: String, key_raw: String, iv_raw: String) -> String {
    let result: AnyResult<String> = (|| {
        let plain = decode_host_base64(&plain_b64).context("解析明文失败")?;
        let key = key_raw.into_bytes();
        let iv = iv_raw.into_bytes();
        let out = match key.len() {
            16 => {
                let cipher = CbcEncryptor::<Aes128>::new_from_slices(&key, &iv)
                    .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?;
                let mut buf = plain.clone();
                let msg_len = buf.len();
                buf.resize(msg_len + 16, 0);
                cipher
                    .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                    .map_err(|_| anyhow!("AES-128 CBC 加密失败"))?
                    .to_vec()
            }
            24 => {
                let cipher = CbcEncryptor::<Aes192>::new_from_slices(&key, &iv)
                    .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?;
                let mut buf = plain.clone();
                let msg_len = buf.len();
                buf.resize(msg_len + 16, 0);
                cipher
                    .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                    .map_err(|_| anyhow!("AES-192 CBC 加密失败"))?
                    .to_vec()
            }
            32 => {
                let cipher = CbcEncryptor::<Aes256>::new_from_slices(&key, &iv)
                    .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?;
                let mut buf = plain.clone();
                let msg_len = buf.len();
                buf.resize(msg_len + 16, 0);
                cipher
                    .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                    .map_err(|_| anyhow!("AES-256 CBC 加密失败"))?
                    .to_vec()
            }
            _ => {
                return Err(anyhow!(
                    "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                    key.len()
                ));
            }
        };
        Ok(json!({ "ok": true, "base64": BASE64_STANDARD.encode(out) }).to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_aes_cbc_pkcs7_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    iv_raw: String,
) -> String {
    let result: AnyResult<String> = (|| {
        let mut payload = decode_host_base64(&payload_b64).context("解析密文失败")?;
        let key = key_raw.into_bytes();
        let iv = iv_raw.into_bytes();
        let plain = match key.len() {
            16 => CbcDecryptor::<Aes128>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?
                .decrypt_padded_mut::<Pkcs7>(&mut payload)
                .map_err(|_| anyhow!("AES-128 CBC 解密失败"))?
                .to_vec(),
            24 => CbcDecryptor::<Aes192>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?
                .decrypt_padded_mut::<Pkcs7>(&mut payload)
                .map_err(|_| anyhow!("AES-192 CBC 解密失败"))?
                .to_vec(),
            32 => CbcDecryptor::<Aes256>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?
                .decrypt_padded_mut::<Pkcs7>(&mut payload)
                .map_err(|_| anyhow!("AES-256 CBC 解密失败"))?
                .to_vec(),
            _ => {
                return Err(anyhow!(
                    "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                    key.len()
                ));
            }
        };
        Ok(json!({ "ok": true, "base64": BASE64_STANDARD.encode(plain) }).to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_aes_gcm_encrypt_b64(
    plain_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> String {
    let result: AnyResult<String> = (|| {
        let plain = decode_host_base64(&plain_b64).context("解析明文失败")?;
        let key = key_raw.into_bytes();
        let nonce = nonce_raw.into_bytes();
        let cipher_text = match key.len() {
            16 => {
                let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
                let nonce = Nonce::from_slice(&nonce);
                let aad = aad_b64
                    .as_ref()
                    .map(|raw| decode_host_base64(raw))
                    .transpose()
                    .context("解析 aad 失败")?
                    .unwrap_or_default();
                cipher
                    .encrypt(
                        nonce,
                        AeadPayload {
                            msg: &plain,
                            aad: &aad,
                        },
                    )
                    .map_err(|_| anyhow!("AES-128 GCM 加密失败"))?
            }
            32 => {
                let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
                let nonce = Nonce::from_slice(&nonce);
                let aad = aad_b64
                    .as_ref()
                    .map(|raw| decode_host_base64(raw))
                    .transpose()
                    .context("解析 aad 失败")?
                    .unwrap_or_default();
                cipher
                    .encrypt(
                        nonce,
                        AeadPayload {
                            msg: &plain,
                            aad: &aad,
                        },
                    )
                    .map_err(|_| anyhow!("AES-256 GCM 加密失败"))?
            }
            _ => {
                return Err(anyhow!(
                    "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                    key.len()
                ));
            }
        };
        Ok(json!({ "ok": true, "base64": BASE64_STANDARD.encode(cipher_text) }).to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_aes_gcm_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> String {
    let result: AnyResult<String> = (|| {
        let payload = decode_host_base64(&payload_b64).context("解析密文失败")?;
        let key = key_raw.into_bytes();
        let nonce = nonce_raw.into_bytes();
        let plain = match key.len() {
            16 => {
                let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
                let nonce = Nonce::from_slice(&nonce);
                let aad = aad_b64
                    .as_ref()
                    .map(|raw| decode_host_base64(raw))
                    .transpose()
                    .context("解析 aad 失败")?
                    .unwrap_or_default();
                cipher
                    .decrypt(
                        nonce,
                        AeadPayload {
                            msg: &payload,
                            aad: &aad,
                        },
                    )
                    .map_err(|_| anyhow!("AES-128 GCM 解密失败"))?
            }
            32 => {
                let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
                let nonce = Nonce::from_slice(&nonce);
                let aad = aad_b64
                    .as_ref()
                    .map(|raw| decode_host_base64(raw))
                    .transpose()
                    .context("解析 aad 失败")?
                    .unwrap_or_default();
                cipher
                    .decrypt(
                        nonce,
                        AeadPayload {
                            msg: &payload,
                            aad: &aad,
                        },
                    )
                    .map_err(|_| anyhow!("AES-256 GCM 解密失败"))?
            }
            _ => {
                return Err(anyhow!(
                    "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                    key.len()
                ));
            }
        };
        Ok(json!({ "ok": true, "base64": BASE64_STANDARD.encode(plain) }).to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_pbkdf2_sha256_b64(
    password_b64: String,
    salt_b64: String,
    iterations: i32,
    key_len: i32,
) -> String {
    let result: AnyResult<String> = (|| {
        if iterations <= 0 {
            return Err(anyhow!("iterations 必须大于 0"));
        }
        if key_len < 0 {
            return Err(anyhow!("keyLen 必须是非负整数"));
        }

        let password = decode_host_base64(&password_b64).context("解析 pbkdf2 password 失败")?;
        let salt = decode_host_base64(&salt_b64).context("解析 pbkdf2 salt 失败")?;
        let rounds = u32::try_from(iterations).context("iterations 超出范围")?;
        let out_len = usize::try_from(key_len).context("keyLen 超出范围")?;
        let mut out = vec![0u8; out_len];
        pbkdf2_hmac::<Sha256>(&password, &salt, rounds, &mut out);

        Ok(json!({
            "ok": true,
            "hex": out.iter().map(|b| format!("{:02x}", b)).collect::<String>(),
            "base64": BASE64_STANDARD.encode(out)
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_timing_safe_equal_b64(left_b64: String, right_b64: String) -> String {
    let result: AnyResult<String> = (|| {
        let left = decode_host_base64(&left_b64).context("解析 timingSafeEqual left 失败")?;
        let right = decode_host_base64(&right_b64).context("解析 timingSafeEqual right 失败")?;
        let max_len = left.len().max(right.len());
        let mut diff = left.len() ^ right.len();
        for i in 0..max_len {
            let l = left.get(i).copied().unwrap_or(0);
            let r = right.get(i).copied().unwrap_or(0);
            diff |= usize::from(l ^ r);
        }
        Ok(json!({
            "ok": true,
            "equal": diff == 0
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

fn crypto_random_uuid_v4() -> String {
    let result: AnyResult<String> = (|| {
        let uuid = Uuid::new_v4().to_string();
        Ok(json!({
            "ok": true,
            "uuid": uuid
        })
        .to_string())
    })();

    match result {
        Ok(v) => v,
        Err(err) => json!({ "ok": false, "error": format!("{err:#}") }).to_string(),
    }
}

const LOG_MAX_PENDING: u64 = 16_384;

fn log_http_endpoint_cell() -> &'static Mutex<Option<String>> {
    LOG_HTTP_ENDPOINT.get_or_init(|| Mutex::new(None))
}

pub fn configure_log_http_endpoint(url: Option<String>) {
    if let Ok(mut guard) = log_http_endpoint_cell().lock() {
        *guard = url.map(|v| v.trim().to_string()).filter(|v| !v.is_empty());
    }
}

pub fn current_log_http_endpoint() -> Option<String> {
    log_http_endpoint_cell()
        .lock()
        .ok()
        .and_then(|guard| guard.clone())
}

fn log_http_direct_client() -> AnyResult<&'static Client> {
    if let Some(client) = LOG_HTTP_DIRECT_CLIENT.get() {
        return Ok(client);
    }

    let client = Client::builder()
        .no_proxy()
        .timeout(Duration::from_secs(10))
        .build()
        .context("创建日志直连 HTTP client 失败")?;

    match LOG_HTTP_DIRECT_CLIENT.set(client) {
        Ok(()) => Ok(LOG_HTTP_DIRECT_CLIENT
            .get()
            .expect("日志直连 HTTP client 初始化后必须可读取")),
        Err(_client) => Ok(LOG_HTTP_DIRECT_CLIENT
            .get()
            .expect("日志直连 HTTP client 并发初始化后必须可读取")),
    }
}

static LOG_FORWARD_RT: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

fn log_forward_runtime() -> &'static tokio::runtime::Runtime {
    LOG_FORWARD_RT.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(1)
            .enable_all()
            .thread_name("rquickjs-log-forward")
            .build()
            .expect("创建 log-forward tokio runtime 失败")
    })
}

fn forward_log_event_if_needed(event: &LogEvent) {
    let Some(url) = current_log_http_endpoint() else {
        return;
    };

    let level = event.level.clone();
    let message = event.message.clone();
    let ts_ms = event.ts_ms;

    let _ = log_forward_runtime().spawn(async move {
        let payload = json!({
            "level": level,
            "message": message,
            "payload": {
                "tsMs": ts_ms
            }
        });
        if let Ok(client) = log_http_direct_client() {
            if let Err(e) = client
                .post(url)
                .header(reqwest::header::CONTENT_TYPE, "application/json")
                .json(&payload)
                .send()
                .await
            {
                tracing::debug!("[qjs-log-http] 转发失败: {e}");
            }
        } else {
            tracing::debug!("[qjs-log-http] 日志直连 HTTP client 不可用，跳过日志转发");
        }
    });
}

fn log_sender() -> &'static mpsc::Sender<LogEvent> {
    LOG_TX.get_or_init(|| {
        let (tx, rx) = mpsc::channel::<LogEvent>();
        thread::Builder::new()
            .name("rquickjs-log-worker".to_string())
            .spawn(move || {
                while let Ok(event) = rx.recv() {
                    LOG_PENDING.fetch_sub(1, Ordering::Relaxed);
                    let line = format!(
                        "[qjs:{}:{}:{}] {}",
                        event.runtime_name, event.ts_ms, event.level, event.message
                    );
                    match event.level.as_str() {
                        "error" => tracing::error!("{}", line),
                        "warn" => tracing::warn!("{}", line),
                        "info" => tracing::info!("{}", line),
                        "debug" => tracing::debug!("{}", line),
                        "log" => tracing::info!("{}", line),
                        _ => tracing::info!("{}", line),
                    }
                    LOG_WRITTEN.fetch_add(1, Ordering::Relaxed);
                    forward_log_event_if_needed(&event);
                }
            })
            .expect("创建 log worker 失败");
        tx
    })
}

pub fn configure_native_buffer_gc_ttl_seconds(ttl_seconds: u64) {
    NATIVE_BUF_GC_TTL_SECS.store(ttl_seconds, Ordering::Relaxed);
    start_native_buffer_gc_loop();
}

pub fn current_native_buffer_gc_ttl_seconds() -> u64 {
    NATIVE_BUF_GC_TTL_SECS.load(Ordering::Relaxed)
}

pub fn timer_start_kind_evented<F>(delay_ms: i64, repeat: bool, on_complete: F) -> String
where
    F: Fn(u64, String) + Send + Sync + 'static,
{
    {
        let mut pool = timer_req_event_pool()
            .lock()
            .expect("timer event 请求池加锁失败");
        cleanup_stale_pending_abort(&mut pool, &TIMER_STALE_DROPS);
        if pool.len() >= TIMER_MAX_PENDING {
            return json!({ "ok": false, "error": "timer pending 队列已满" }).to_string();
        }
    }

    let id = TIMER_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let normalized_delay_ms = delay_ms.clamp(0, 24 * 60 * 60 * 1000) as u64;
    let on_complete = Arc::new(on_complete);
    let timer_label = format!("repeat={} delayMs={}", repeat, normalized_delay_ms);

    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            if repeat {
                let mut tick: u64 = 0;
                loop {
                    tokio::time::sleep(Duration::from_millis(normalized_delay_ms)).await;
                    tick = tick.saturating_add(1);
                    on_complete(
                        id,
                        json!({ "ok": true, "kind": "interval", "tick": tick }).to_string(),
                    );
                    let alive = timer_req_event_pool()
                        .lock()
                        .map(|pool| pool.contains_key(&id))
                        .unwrap_or(false);
                    if !alive {
                        break;
                    }
                }
            } else {
                tokio::time::sleep(Duration::from_millis(normalized_delay_ms)).await;
                on_complete(id, json!({ "ok": true, "kind": "timeout" }).to_string());
                let _ = timer_req_event_pool()
                    .lock()
                    .map(|mut pool| pool.remove(&id));
            }
        });

    {
        let mut pool = timer_req_event_pool()
            .lock()
            .expect("timer event 请求池加锁失败");
        pool.insert(
            id,
            PendingAbortTask {
                task,
                created_at: Instant::now(),
                meta: PendingAbortTaskMeta {
                    kind: "timer_evented",
                    label: timer_label,
                },
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

pub fn timer_drop_evented(id: u64) -> String {
    let mut pool = timer_req_event_pool()
        .lock()
        .expect("timer event 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

pub fn fs_task_start(op: String, args_json: String) -> String {
    {
        let mut pool = fs_req_pool().lock().expect("fs 请求池加锁失败");
        cleanup_stale_pending(&mut pool, &FS_STALE_DROPS);
        if pool.len() >= FS_MAX_PENDING {
            return json!({ "ok": false, "error": "fs pending 队列已满" }).to_string();
        }
    }

    let id = FS_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let sem = Arc::clone(fs_io_sem());
    let request_label = format!("op={}", op);

    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
                Ok(Ok(permit)) => permit,
                Ok(Err(_)) => {
                    let _ =
                        tx.send(json!({ "ok": false, "error": "fs 并发控制器不可用" }).to_string());
                    return;
                }
                Err(_) => {
                    let _ =
                        tx.send(json!({ "ok": false, "error": "fs 等待并发许可超时" }).to_string());
                    return;
                }
            };
            let payload = tokio::task::spawn_blocking(move || fs_task_dispatch(op, args_json))
                .await
                .unwrap_or_else(|e| json!({ "ok": false, "error": e.to_string() }).to_string());
            drop(permit);
            let _ = tx.send(payload);
        });

    {
        let mut pool = fs_req_pool().lock().expect("fs 请求池加锁失败");
        pool.insert(
            id,
            PendingTask {
                rx,
                task,
                created_at: Instant::now(),
                meta: PendingTaskMeta {
                    kind: "fs",
                    label: request_label,
                },
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

pub fn fs_task_try_take(id: u64) -> String {
    let mut pool = fs_req_pool().lock().expect("fs 请求池加锁失败");
    cleanup_stale_pending(&mut pool, &FS_STALE_DROPS);
    let Some(pending) = pool.get_mut(&id) else {
        return json!({ "ok": false, "error": "request id 不存在" }).to_string();
    };

    match pending.rx.try_recv() {
        Ok(result) => {
            pool.remove(&id);
            json!({ "ok": true, "done": true, "result": result }).to_string()
        }
        Err(TryRecvError::Empty) => json!({ "ok": true, "done": false }).to_string(),
        Err(TryRecvError::Disconnected) => {
            pool.remove(&id);
            json!({ "ok": false, "error": "fs 执行任务异常退出" }).to_string()
        }
    }
}

pub fn fs_task_drop(id: u64) -> String {
    let mut pool = fs_req_pool().lock().expect("fs 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

pub fn fs_task_start_evented<F>(op: String, args_json: String, on_complete: F) -> String
where
    F: FnOnce(u64, String) + Send + 'static,
{
    {
        let mut pool = fs_req_event_pool().lock().expect("fs event 请求池加锁失败");
        cleanup_stale_pending_abort(&mut pool, &FS_STALE_DROPS);
        if pool.len() >= FS_MAX_PENDING {
            return json!({ "ok": false, "error": "fs pending 队列已满" }).to_string();
        }
    }

    let id = FS_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let sem = Arc::clone(fs_io_sem());
    let request_label = format!("op={}", op);

    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
                Ok(Ok(permit)) => permit,
                Ok(Err(_)) => {
                    on_complete(
                        id,
                        json!({ "ok": false, "error": "fs 并发控制器不可用" }).to_string(),
                    );
                    return;
                }
                Err(_) => {
                    on_complete(
                        id,
                        json!({ "ok": false, "error": "fs 等待并发许可超时" }).to_string(),
                    );
                    return;
                }
            };
            let payload = tokio::task::spawn_blocking(move || fs_task_dispatch(op, args_json))
                .await
                .unwrap_or_else(|e| json!({ "ok": false, "error": e.to_string() }).to_string());
            drop(permit);
            on_complete(id, payload);
            let _ = fs_req_event_pool().lock().map(|mut pool| pool.remove(&id));
        });

    {
        let mut pool = fs_req_event_pool().lock().expect("fs event 请求池加锁失败");
        pool.insert(
            id,
            PendingAbortTask {
                task,
                created_at: Instant::now(),
                meta: PendingAbortTaskMeta {
                    kind: "fs_evented",
                    label: request_label,
                },
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

pub fn fs_task_drop_evented(id: u64) -> String {
    let mut pool = fs_req_event_pool().lock().expect("fs event 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

fn normalize_runtime_name(input: &str) -> String {
    let raw = input.trim();
    if raw.is_empty() {
        return "default-runtime".to_string();
    }

    let mut out = String::with_capacity(raw.len().min(96));
    for ch in raw.chars() {
        if out.len() >= 96 {
            break;
        }
        if ch.is_ascii_alphanumeric() || matches!(ch, '_' | '-' | '.' | '@') {
            out.push(ch);
        } else {
            out.push('_');
        }
    }

    if out.is_empty() {
        "default-runtime".to_string()
    } else {
        out
    }
}

pub fn log_emit(level: String, message: String, runtime_name: String) -> String {
    let level_norm = level.trim().to_ascii_lowercase();
    let level = if level_norm.is_empty() {
        "log".to_string()
    } else {
        level_norm
    };

    let current = LOG_PENDING.load(Ordering::Relaxed);
    if current >= LOG_MAX_PENDING {
        LOG_DROPPED.fetch_add(1, Ordering::Relaxed);
        return json!({ "ok": true, "dropped": true }).to_string();
    }

    LOG_PENDING.fetch_add(1, Ordering::Relaxed);

    let event = LogEvent {
        level,
        message,
        ts_ms: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis())
            .unwrap_or_default(),
        runtime_name,
    };

    if let Err(e) = log_sender().send(event) {
        LOG_PENDING.fetch_sub(1, Ordering::Relaxed);
        LOG_ERRORS.fetch_add(1, Ordering::Relaxed);
        return json!({ "ok": false, "error": format!("log worker 不可用: {e}") }).to_string();
    }

    LOG_ENQUEUED.fetch_add(1, Ordering::Relaxed);
    json!({ "ok": true, "dropped": false }).to_string()
}

pub fn runtime_stats() -> String {
    let mut http_pending = http_req_pool().lock().map(|m| m.len()).unwrap_or_default();
    let mut fs_pending = fs_req_pool().lock().map(|m| m.len()).unwrap_or_default();
    let mut http_pending_debug = Vec::new();
    let mut fs_pending_debug = Vec::new();
    let mut bridge_pending_debug = Vec::new();
    let mut timer_pending_debug = Vec::new();

    if let Ok(mut pool) = http_req_pool().lock() {
        cleanup_stale_pending(&mut pool, &HTTP_STALE_DROPS);
        http_pending = pool.len();
        http_pending_debug = pool
            .iter()
            .map(|(id, pending)| pending_task_debug_item(*id, pending))
            .collect();
    }
    if let Ok(mut pool) = fs_req_pool().lock() {
        cleanup_stale_pending(&mut pool, &FS_STALE_DROPS);
        fs_pending = pool.len();
        fs_pending_debug = pool
            .iter()
            .map(|(id, pending)| pending_task_debug_item(*id, pending))
            .collect();
    }
    if let Ok(mut pool) = BRIDGE_REQ_POOL
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
    {
        cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
        bridge_pending_debug = pool
            .iter()
            .map(|(id, pending)| pending_task_debug_item(*id, pending))
            .collect();
    }
    if let Ok(mut pool) = timer_req_event_pool().lock() {
        cleanup_stale_pending_abort(&mut pool, &TIMER_STALE_DROPS);
        timer_pending_debug = pool
            .iter()
            .map(|(id, pending)| pending_abort_task_debug_item(*id, pending))
            .collect();
    }
    if let Ok(mut pool) = body_state_pool().lock() {
        cleanup_stale_body_state(&mut pool);
    }
    if let Ok(mut pool) = fetch_state_pool().lock() {
        cleanup_stale_fetch_state(&mut pool);
    }

    let http_available = http_io_sem().available_permits();
    let fs_available = fs_io_sem().available_permits();
    let native_buffer_pool_size = native_pool().lock().map(|m| m.len()).unwrap_or_default();
    let bridge_config = current_bridge_runtime_config();

    json!({
        "ok": true,
        "limits": {
            "pending": {
                "http": HTTP_MAX_PENDING,
                "fs": FS_MAX_PENDING,
            },
            "inFlight": {
                "http": HTTP_MAX_IN_FLIGHT,
                "fs": FS_MAX_IN_FLIGHT,
            }
        },
        "pending": {
            "http": http_pending,
            "fs": fs_pending,
            "bridge": bridge_pending_count(),
        },
        "pendingDebug": {
            "http": http_pending_debug,
            "fs": fs_pending_debug,
            "bridge": bridge_pending_debug,
            "timer": timer_pending_debug,
        },
        "permits": {
            "httpAvailable": http_available,
            "fsAvailable": fs_available,
        },
        "staleDrops": {
            "http": HTTP_STALE_DROPS.load(Ordering::Relaxed),
            "fs": FS_STALE_DROPS.load(Ordering::Relaxed),
            "bridge": BRIDGE_STALE_DROPS.load(Ordering::Relaxed),
        },
        "httpEvented": {
            "completed": HTTP_EVENT_COMPLETED.load(Ordering::Relaxed),
            "canceled": HTTP_EVENT_CANCELED.load(Ordering::Relaxed),
            "suppressedCallbacks": HTTP_EVENT_SUPPRESSED.load(Ordering::Relaxed),
        },
        "logs": {
            "pending": LOG_PENDING.load(Ordering::Relaxed),
            "pendingCapacity": LOG_MAX_PENDING,
            "enqueued": LOG_ENQUEUED.load(Ordering::Relaxed),
            "written": LOG_WRITTEN.load(Ordering::Relaxed),
            "dropped": LOG_DROPPED.load(Ordering::Relaxed),
            "errors": LOG_ERRORS.load(Ordering::Relaxed),
            "httpEndpointConfigured": current_log_http_endpoint().is_some(),
        },
        "nativeBuffer": {
            "poolSize": native_buffer_pool_size,
            "gcTtlSeconds": current_native_buffer_gc_ttl_seconds(),
            "gcIntervalSeconds": NATIVE_BUFFER_GC_INTERVAL.as_secs(),
            "gcDrops": NATIVE_BUF_GC_DROPS.load(Ordering::Relaxed),
        },
        "bodyState": {
            "poolSize": body_state_pool().lock().map(|m| m.len()).unwrap_or_default(),
            "consumeRejects": BODY_CONSUME_REJECTS.load(Ordering::Relaxed),
            "ttlSeconds": BODY_STATE_TTL.as_secs(),
            "gcDrops": BODY_STATE_GC_DROPS.load(Ordering::Relaxed),
        },
        "fetchState": {
            "poolSize": fetch_state_pool().lock().map(|m| m.len()).unwrap_or_default(),
            "rejects": FETCH_STATE_REJECTS.load(Ordering::Relaxed),
            "ttlSeconds": FETCH_STATE_TTL.as_secs(),
            "gcDrops": FETCH_STATE_GC_DROPS.load(Ordering::Relaxed),
        },
        "bridge": {
            "protocol": BRIDGE_BINARY_PROTOCOL,
            "bytesIn": BRIDGE_BYTES_IN.load(Ordering::Relaxed),
            "bytesOut": BRIDGE_BYTES_OUT.load(Ordering::Relaxed),
            "denied": BRIDGE_DENIED.load(Ordering::Relaxed),
            "limitHits": BRIDGE_LIMIT_HITS.load(Ordering::Relaxed),
            "config": {
                "maxArgsJsonBytes": bridge_config.max_args_json_bytes,
                "maxReturnBinaryBytes": bridge_config.max_return_binary_bytes,
                "allowedRoutePrefixes": bridge_config.allowed_route_prefixes,
            }
        }
    })
    .to_string()
}

#[cfg(test)]
pub use crate::tests::support::{run_async_script, run_async_script_with_fs};
