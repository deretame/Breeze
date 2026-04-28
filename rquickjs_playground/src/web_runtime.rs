use aes::{Aes128, Aes192, Aes256};
use anyhow::{Context as AnyhowContext, Result as AnyResult, anyhow};
use base64::Engine as Base64Engine;
use base64::engine::general_purpose::{STANDARD as BASE64_STANDARD, URL_SAFE as BASE64_URL_SAFE};
use ecb::cipher::{BlockDecryptMut, KeyInit, block_padding::Pkcs7};
use flate2::Compression;
use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use serde::Deserialize;
use serde_json::Map;
use serde_json::{Value, json};
use std::collections::HashMap;
#[cfg(feature = "wasi")]
use std::collections::VecDeque;
use std::fs;
use std::future::Future;
use std::io;
use std::io::Read;
use std::io::Write;
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
use reqwest::multipart::{Form as MultipartForm, Part as MultipartPart};
use reqwest::{Client, Method, Proxy};
use sha2::{Digest, Sha256};
#[cfg(windows)]
use windows_registry::CURRENT_USER;

use filetime::{FileTime, set_file_times};
use rquickjs::{Ctx, Function, Promise, function::Func};
use tokio::runtime::{Builder as TokioRuntimeBuilder, Runtime as TokioRuntime};
use tokio::sync::Semaphore;
use tokio::task::JoinHandle;
use tokio::time::timeout;
#[cfg(feature = "wasi")]
use wasmtime::{Engine, Linker, Module, Store};
#[cfg(feature = "wasi")]
use wasmtime_wasi::WasiCtxBuilder;

const WEB_POLYFILL_CORE: &str = concat!(
    include_str!("../js/00_bootstrap.js"),
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
    include_str!("../js/65_console.js"),
    "\n"
);

#[cfg(feature = "host-fs")]
const WEB_FS_POLYFILL: &str = concat!(include_str!("../js/50_fs.js"), "\n");

pub const WEB_POLYFILL: &str = concat!(
    include_str!("../js/00_bootstrap.js"),
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
    include_str!("../js/65_console.js"),
    "\n",
    include_str!("../js/99_exports.js"),
    "\n"
);

pub const WEB_WASI_POLYFILL: &str = concat!(include_str!("../js/61_wasi.js"), "\n");
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
    pub wasi: bool,
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
    if options.wasi && cfg!(feature = "wasi") {
        script.push_str(WEB_WASI_POLYFILL);
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
    if options.wasi && !cfg!(feature = "wasi") {
        return Err(rquickjs::Error::new_from_js_message(
            "rust",
            "runtime",
            "当前构建未启用 wasi Cargo 特性",
        ));
    }
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
    globals.set("__host_call_try_take", Func::from(host_call_try_take))?;
    globals.set("__host_call_drop", Func::from(host_call_drop))?;
    if options.wasi {
        globals.set("__wasi_run_start", Func::from(wasi_run_start))?;
        globals.set("__wasi_run_try_take", Func::from(wasi_run_try_take))?;
        globals.set("__wasi_run_drop", Func::from(wasi_run_drop))?;
    }
    globals.set("__log_emit", Func::from(log_emit))?;
    globals.set("__runtime_stats", Func::from(runtime_stats))?;
    globals.set("__crypto_sha256_b64", Func::from(crypto_sha256_b64))?;
    globals.set(
        "__crypto_hmac_sha256_b64",
        Func::from(crypto_hmac_sha256_b64),
    )?;
    globals.set(
        "__crypto_random_bytes_b64",
        Func::from(crypto_random_bytes_b64),
    )?;
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
    Ok(())
}

static HTTP_REQ_ID: AtomicU64 = AtomicU64::new(1);
static HTTP_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static BRIDGE_REQ_ID: AtomicU64 = AtomicU64::new(1);
static BRIDGE_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static HTTP_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
static FS_REQ_ID: AtomicU64 = AtomicU64::new(1);
static FS_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
static FS_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
static TIMER_REQ_ID: AtomicU64 = AtomicU64::new(1);
static TIMER_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_REQ_ID: AtomicU64 = AtomicU64::new(1);
#[cfg(feature = "wasi")]
static WASI_REQ_POOL: OnceLock<Mutex<HashMap<u64, PendingTask>>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_REQ_EVENT_POOL: OnceLock<Mutex<HashMap<u64, PendingAbortTask>>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_ENGINE: OnceLock<Engine> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_MODULE_CACHE: OnceLock<Mutex<HashMap<Vec<u8>, Module>>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_MODULE_CACHE_ORDER: OnceLock<Mutex<VecDeque<Vec<u8>>>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_LINKER: OnceLock<Linker<wasmtime_wasi::p1::WasiP1Ctx>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_CACHE_HITS: AtomicU64 = AtomicU64::new(0);
#[cfg(feature = "wasi")]
static WASI_CACHE_MISSES: AtomicU64 = AtomicU64::new(0);
#[cfg(feature = "wasi")]
static WASI_CACHE_EVICTIONS: AtomicU64 = AtomicU64::new(0);
static HTTP_CLIENT_STATE: OnceLock<Mutex<HttpClientState>> = OnceLock::new();
static HOST_ASYNC_RT: OnceLock<TokioRuntime> = OnceLock::new();
static HTTP_IO_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
static FS_IO_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
#[cfg(feature = "wasi")]
static WASI_IO_SEM: OnceLock<Arc<Semaphore>> = OnceLock::new();
static HTTP_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static BRIDGE_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static FS_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static TIMER_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
#[cfg(feature = "wasi")]
static WASI_STALE_DROPS: AtomicU64 = AtomicU64::new(0);
static LOG_TX: OnceLock<mpsc::Sender<LogEvent>> = OnceLock::new();
static LOG_HTTP_ENDPOINT: OnceLock<Mutex<Option<String>>> = OnceLock::new();
static LOG_HTTP_DIRECT_CLIENT: OnceLock<Client> = OnceLock::new();
static LOG_ENQUEUED: AtomicU64 = AtomicU64::new(0);
static LOG_WRITTEN: AtomicU64 = AtomicU64::new(0);
static LOG_DROPPED: AtomicU64 = AtomicU64::new(0);
static LOG_ERRORS: AtomicU64 = AtomicU64::new(0);
static LOG_PENDING: AtomicU64 = AtomicU64::new(0);
static NATIVE_BUF_GC_TTL_SECS: AtomicU64 = AtomicU64::new(DEFAULT_NATIVE_BUFFER_GC_TTL_SECS);
static NATIVE_BUF_GC_DROPS: AtomicU64 = AtomicU64::new(0);
static NATIVE_BUF_GC_LOOP_STARTED: OnceLock<()> = OnceLock::new();
type BridgeRouteFuture = Pin<Box<dyn Future<Output = AnyResult<Value>> + Send + 'static>>;
type BridgeRouteSyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;
type BridgeRouteAsyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> BridgeRouteFuture + Send + Sync + 'static>;
type BridgeRouteBlockingHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;
static BRIDGE_ROUTE_SYNC_HANDLERS: OnceLock<Mutex<HashMap<String, BridgeRouteSyncHandler>>> =
    OnceLock::new();
static BRIDGE_ROUTE_ASYNC_HANDLERS: OnceLock<Mutex<HashMap<String, BridgeRouteAsyncHandler>>> =
    OnceLock::new();
static BRIDGE_ROUTE_BLOCKING_HANDLERS: OnceLock<
    Mutex<HashMap<String, BridgeRouteBlockingHandler>>,
> = OnceLock::new();
const HTTP_SYSTEM_PROXY_REFRESH_INTERVAL: Duration = Duration::from_secs(3);

struct PendingTask {
    rx: mpsc::Receiver<String>,
    task: JoinHandle<()>,
    created_at: Instant,
}

struct PendingAbortTask {
    task: JoinHandle<()>,
    created_at: Instant,
}

struct NativeBufferEntry {
    bytes: Vec<u8>,
    created_at: Instant,
}

impl NativeBufferEntry {
    fn new(bytes: Vec<u8>) -> Self {
        Self {
            bytes,
            created_at: Instant::now(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpClientConfig {
    pub use_http_proxy: bool,
    pub use_socks5_proxy: bool,
    pub http_proxy: Option<String>,
    pub socks5_proxy: Option<String>,
    pub disable_tls_verify: bool,
}

impl Default for HttpClientConfig {
    fn default() -> Self {
        Self {
            use_http_proxy: true,
            use_socks5_proxy: true,
            http_proxy: None,
            socks5_proxy: None,
            disable_tls_verify: false,
        }
    }
}

struct HttpClientState {
    client: Option<Client>,
    config: HttpClientConfig,
    auto_system_proxy: bool,
    system_proxy_fingerprint: Option<String>,
    last_system_proxy_check_at: Option<Instant>,
}

impl Default for HttpClientState {
    fn default() -> Self {
        Self {
            client: None,
            config: HttpClientConfig::default(),
            auto_system_proxy: false,
            system_proxy_fingerprint: None,
            last_system_proxy_check_at: None,
        }
    }
}

struct LogEvent {
    level: String,
    message: String,
    ts_ms: u128,
}

fn http_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    HTTP_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn bridge_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    BRIDGE_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

fn bridge_route_sync_handler_cell() -> &'static Mutex<HashMap<String, BridgeRouteSyncHandler>> {
    BRIDGE_ROUTE_SYNC_HANDLERS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn bridge_route_async_handler_cell() -> &'static Mutex<HashMap<String, BridgeRouteAsyncHandler>> {
    BRIDGE_ROUTE_ASYNC_HANDLERS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn bridge_route_blocking_handler_cell()
-> &'static Mutex<HashMap<String, BridgeRouteBlockingHandler>> {
    BRIDGE_ROUTE_BLOCKING_HANDLERS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn normalize_bridge_route_name(name: impl Into<String>) -> AnyResult<String> {
    let name = name.into().trim().to_string();
    if name.is_empty() {
        return Err(anyhow!("bridge 路由名不能为空"));
    }
    Ok(name)
}

pub fn register_bridge_route_sync_handler<F>(name: impl Into<String>, handler: F) -> AnyResult<()>
where
    F: Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static,
{
    let name = normalize_bridge_route_name(name)?;
    let wrapped = Arc::new(handler) as BridgeRouteSyncHandler;
    {
        let mut handlers = bridge_route_sync_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_async_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 异步路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_blocking_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 阻塞路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    Ok(())
}

pub fn register_bridge_route_async_handler<F, Fut>(
    name: impl Into<String>,
    handler: F,
) -> AnyResult<()>
where
    F: Fn(String, Vec<Value>) -> Fut + Send + Sync + 'static,
    Fut: Future<Output = AnyResult<Value>> + Send + 'static,
{
    let name = normalize_bridge_route_name(name)?;
    let wrapped = Arc::new(move |runtime_name: String, args: Vec<Value>| {
        Box::pin(handler(runtime_name, args)) as BridgeRouteFuture
    }) as BridgeRouteAsyncHandler;
    {
        let mut handlers = bridge_route_async_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 异步路由表锁已损坏"))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_sync_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_blocking_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 阻塞路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    Ok(())
}

pub fn register_bridge_route_blocking_handler<F>(
    name: impl Into<String>,
    handler: F,
) -> AnyResult<()>
where
    F: Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static,
{
    let name = normalize_bridge_route_name(name)?;
    let wrapped = Arc::new(handler) as BridgeRouteBlockingHandler;
    {
        let mut handlers = bridge_route_blocking_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 阻塞路由表锁已损坏"))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_sync_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_async_handler_cell()
            .lock()
            .map_err(|_| anyhow!("bridge 异步路由表锁已损坏"))?;
        handlers.remove(&name);
    }
    Ok(())
}

pub fn unregister_bridge_route_handler(name: &str) -> AnyResult<bool> {
    let mut sync_handlers = bridge_route_sync_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?;
    let mut async_handlers = bridge_route_async_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 异步路由表锁已损坏"))?;
    let mut blocking_handlers = bridge_route_blocking_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 阻塞路由表锁已损坏"))?;
    let removed_sync = sync_handlers.remove(name).is_some();
    let removed_async = async_handlers.remove(name).is_some();
    let removed_blocking = blocking_handlers.remove(name).is_some();
    Ok(removed_sync || removed_async || removed_blocking)
}

fn call_registered_bridge_route_sync(
    runtime_name: String,
    name: String,
    args: Vec<Value>,
) -> AnyResult<Value> {
    let sync_handler = bridge_route_sync_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?
        .get(&name)
        .cloned()
        .ok_or_else(|| anyhow!("不支持的 bridge 方法: {name}"))?;
    sync_handler(runtime_name, args)
}

async fn call_registered_bridge_route(
    runtime_name: String,
    name: String,
    args: Vec<Value>,
) -> AnyResult<Value> {
    let sync_handler = bridge_route_sync_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 同步路由表锁已损坏"))?
        .get(&name)
        .cloned();
    if let Some(sync_handler) = sync_handler {
        return sync_handler(runtime_name, args);
    }

    let async_handler = bridge_route_async_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 异步路由表锁已损坏"))?
        .get(&name)
        .cloned();
    if let Some(async_handler) = async_handler {
        return async_handler(runtime_name, args).await;
    }

    let blocking_handler = bridge_route_blocking_handler_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 阻塞路由表锁已损坏"))?
        .get(&name)
        .cloned();
    if let Some(blocking_handler) = blocking_handler {
        return host_async_runtime()
            .spawn_blocking(move || blocking_handler(runtime_name, args))
            .await
            .map_err(|err| anyhow!("bridge blocking 路由任务 join 失败: {err}"))?;
    }

    Err(anyhow!("不支持的 bridge 方法: {name}"))
}

fn http_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    HTTP_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
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

#[cfg(feature = "wasi")]
fn wasi_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    WASI_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(feature = "wasi")]
fn wasi_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    WASI_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(feature = "wasi")]
fn wasi_engine() -> &'static Engine {
    WASI_ENGINE.get_or_init(Engine::default)
}

#[cfg(feature = "wasi")]
fn wasi_module_cache() -> &'static Mutex<HashMap<Vec<u8>, Module>> {
    WASI_MODULE_CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(feature = "wasi")]
fn wasi_module_cache_order() -> &'static Mutex<VecDeque<Vec<u8>>> {
    WASI_MODULE_CACHE_ORDER.get_or_init(|| Mutex::new(VecDeque::new()))
}

#[cfg(feature = "wasi")]
fn wasi_linker() -> AnyResult<&'static Linker<wasmtime_wasi::p1::WasiP1Ctx>> {
    if let Some(linker) = WASI_LINKER.get() {
        return Ok(linker);
    }

    let mut linker: Linker<wasmtime_wasi::p1::WasiP1Ctx> = Linker::new(wasi_engine());
    wasmtime_wasi::p1::add_to_linker_sync(&mut linker, |s| s)
        .map_err(|e| anyhow!("注册 WASI linker 失败: {e}"))?;

    match WASI_LINKER.set(linker) {
        Ok(()) => Ok(WASI_LINKER.get().expect("wasi linker 初始化后必须可读取")),
        Err(_linker) => Ok(WASI_LINKER
            .get()
            .expect("wasi linker 并发初始化后必须可读取")),
    }
}

const HTTP_MAX_IN_FLIGHT: usize = 256;
const FS_MAX_IN_FLIGHT: usize = 128;
const WASI_MAX_IN_FLIGHT: usize = 32;
const HTTP_OFFLOAD_BODY_HEADER: &str = "x-rquickjs-host-offload-binary-v1";
const HTTP_WASI_TRANSFORM_HEADER: &str = "x-rquickjs-host-wasi-transform-b64-v1";
const HTTP_FORMDATA_BODY_HEADER: &str = "x-rquickjs-host-body-formdata-v1";
const HTTP_AUTO_OFFLOAD_SIZE_THRESHOLD: u64 = 1 * 1024 * 1024;
const HTTP_MAX_PENDING: usize = 4096;
const BRIDGE_MAX_PENDING: usize = 4096;
const FS_MAX_PENDING: usize = 4096;
const TIMER_MAX_PENDING: usize = 8192;
const WASI_MAX_PENDING: usize = 1024;
const PENDING_TASK_TTL: Duration = Duration::from_secs(120);
const NATIVE_BUFFER_GC_INTERVAL: Duration = Duration::from_secs(60);
const DEFAULT_NATIVE_BUFFER_GC_TTL_SECS: u64 = 15 * 60;

fn http_io_sem() -> &'static Arc<Semaphore> {
    HTTP_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(HTTP_MAX_IN_FLIGHT)))
}

fn fs_io_sem() -> &'static Arc<Semaphore> {
    FS_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(FS_MAX_IN_FLIGHT)))
}

#[cfg(feature = "wasi")]
fn wasi_io_sem() -> &'static Arc<Semaphore> {
    WASI_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(WASI_MAX_IN_FLIGHT)))
}

fn cleanup_stale_pending(pool: &mut HashMap<u64, PendingTask>, dropped_counter: &AtomicU64) {
    let now = Instant::now();
    let stale_ids: Vec<u64> = pool
        .iter()
        .filter_map(|(id, pending)| {
            if now.duration_since(pending.created_at) > PENDING_TASK_TTL {
                Some(*id)
            } else {
                None
            }
        })
        .collect();

    for id in stale_ids {
        if let Some(pending) = pool.remove(&id) {
            pending.task.abort();
            dropped_counter.fetch_add(1, Ordering::Relaxed);
        }
    }
}

fn cleanup_stale_pending_abort(
    pool: &mut HashMap<u64, PendingAbortTask>,
    dropped_counter: &AtomicU64,
) {
    let now = Instant::now();
    let stale_ids: Vec<u64> = pool
        .iter()
        .filter_map(|(id, pending)| {
            if now.duration_since(pending.created_at) > PENDING_TASK_TTL {
                Some(*id)
            } else {
                None
            }
        })
        .collect();

    for id in stale_ids {
        if let Some(pending) = pool.remove(&id) {
            pending.task.abort();
            dropped_counter.fetch_add(1, Ordering::Relaxed);
        }
    }
}

fn header_truthy(value: &str) -> bool {
    matches!(
        value.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes" | "on"
    )
}

fn is_binary_content(content_type: &str) -> bool {
    let ct = content_type.to_lowercase();

    if ct.starts_with("text/")
        || ct.contains("json")
        || ct.contains("xml")
        || ct.contains("javascript")
    {
        return false;
    }

    if ct.starts_with("image/")
        || ct.starts_with("audio/")
        || ct.starts_with("video/")
        || ct.starts_with("font/")
        || ct.starts_with("multipart/")
    {
        return true;
    }

    static BINARY_PREFIXES: &[&str] = &[
        "application/octet-stream",
        "application/pdf",
        "application/zip",
        "application/gzip",
        "application/wasm",
        "application/vnd",
        "application/x-protobuf",
        "application/x-msgpack",
    ];

    BINARY_PREFIXES.iter().any(|&prefix| ct.starts_with(prefix))
}

fn should_auto_offload_response(headers: &reqwest::header::HeaderMap) -> bool {
    if let Some(content_disposition) = headers
        .get(reqwest::header::CONTENT_DISPOSITION)
        .and_then(|v| v.to_str().ok())
    {
        let cd = content_disposition.to_ascii_lowercase();
        if cd.contains("attachment") {
            return true;
        }
    }

    if let Some(content_length) = headers
        .get(reqwest::header::CONTENT_LENGTH)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok())
    {
        if content_length >= HTTP_AUTO_OFFLOAD_SIZE_THRESHOLD {
            return true;
        }
    }

    let content_type = headers
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default()
        .to_ascii_lowercase();

    if content_type.is_empty() {
        return false;
    }

    if is_binary_content(&content_type) {
        return true;
    }

    false
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct HostFormDataPlan {
    kind: Option<String>,
    entries: Vec<HostFormDataEntry>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct HostFormDataEntry {
    name: String,
    kind: String,
    value: Option<String>,
    data_b64: Option<String>,
    filename: Option<String>,
    content_type: Option<String>,
}

fn parse_host_formdata_plan(raw_json: &str) -> AnyResult<HostFormDataPlan> {
    let plan = serde_json::from_str::<HostFormDataPlan>(raw_json)
        .context("解析 host formdata plan JSON 失败")?;
    if let Some(kind) = &plan.kind {
        if kind != "rquickjs-formdata-v1" {
            return Err(anyhow!("不支持的 formdata plan kind: {kind}"));
        }
    }
    Ok(plan)
}

fn decode_host_base64(raw_b64: &str) -> AnyResult<Vec<u8>> {
    let raw = raw_b64.trim();
    BASE64_STANDARD
        .decode(raw)
        .or_else(|_| BASE64_URL_SAFE.decode(raw))
        .context("base64 解码 formdata 字段失败")
}

type HmacSha256 = Hmac<Sha256>;

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

fn build_multipart_form(plan: HostFormDataPlan) -> AnyResult<MultipartForm> {
    let mut form = MultipartForm::new();
    for entry in plan.entries {
        if entry.kind.eq_ignore_ascii_case("text") {
            let value = entry
                .value
                .ok_or_else(|| anyhow!("formdata 文本字段缺少 value"))?;
            form = form.text(entry.name, value);
            continue;
        }

        if entry.kind.eq_ignore_ascii_case("binary") {
            let data_b64 = entry
                .data_b64
                .ok_or_else(|| anyhow!("formdata 二进制字段缺少 dataB64"))?;
            let bytes = decode_host_base64(&data_b64)?;
            let mut part = MultipartPart::bytes(bytes);
            if let Some(filename) = entry.filename {
                part = part.file_name(filename);
            }
            if let Some(content_type) = entry
                .content_type
                .as_deref()
                .map(str::trim)
                .filter(|v| !v.is_empty())
            {
                part = part
                    .mime_str(content_type)
                    .map_err(|e| anyhow!("设置 formdata part Content-Type 失败: {e}"))?;
            }
            form = form.part(entry.name, part);
            continue;
        }

        return Err(anyhow!("不支持的 formdata 字段类型: {}", entry.kind));
    }
    Ok(form)
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[cfg_attr(not(feature = "wasi"), allow(dead_code))]
struct WasiTransformPlan {
    module_id: u64,
    function: Option<String>,
    args: Option<Value>,
    js_process: Option<bool>,
    output_type: String,
}

#[cfg(feature = "wasi")]
fn parse_wasi_transform_plan(raw_b64: &str) -> AnyResult<WasiTransformPlan> {
    let raw = raw_b64.trim();
    let decoded = BASE64_URL_SAFE
        .decode(raw)
        .or_else(|_| BASE64_STANDARD.decode(raw))
        .context("base64 解码 wasi transform plan 失败")?;
    let json_text = String::from_utf8(decoded).context("wasi transform plan 不是有效 UTF-8")?;
    serde_json::from_str::<WasiTransformPlan>(&json_text)
        .context("解析 wasi transform plan JSON 失败")
}

#[cfg(not(feature = "wasi"))]
fn parse_wasi_transform_plan(_raw_b64: &str) -> AnyResult<WasiTransformPlan> {
    Err(anyhow!("当前构建未启用 wasi Cargo 特性"))
}

#[cfg(feature = "wasi")]
fn build_wasi_argv_json(plan: &WasiTransformPlan) -> AnyResult<Option<String>> {
    let mut argv: Vec<String> = Vec::new();
    if let Some(function) = &plan.function {
        argv.push("--fn".to_string());
        argv.push(function.clone());
    }
    if let Some(args) = &plan.args {
        argv.push("--args-json".to_string());
        argv.push(serde_json::to_string(args).context("序列化 wasi args 失败")?);
    }
    if argv.is_empty() {
        Ok(None)
    } else {
        Ok(Some(
            serde_json::to_string(&argv).context("序列化 wasi argv 失败")?,
        ))
    }
}

#[cfg(feature = "wasi")]
async fn run_wasi_transform_once(plan: &WasiTransformPlan, input: Vec<u8>) -> AnyResult<Vec<u8>> {
    if !plan.output_type.eq_ignore_ascii_case("binary") {
        return Err(anyhow!(
            "当前仅支持 outputType=binary，收到: {}",
            plan.output_type
        ));
    }

    let stdin_id = native_buffer_put_raw(input);
    let args_json = build_wasi_argv_json(plan)?;
    let module_id = plan.module_id;
    let raw = tokio::task::spawn_blocking(move || {
        wasi_run_inner(module_id, Some(stdin_id), args_json, false)
    })
    .await
    .context("执行 wasi transform 任务失败")?;
    let payload = parse_host_ok_payload(raw)?;

    let exit_code = payload
        .get("exitCode")
        .and_then(Value::as_i64)
        .unwrap_or_default();
    let stderr_id = payload
        .get("stderrId")
        .and_then(Value::as_u64)
        .ok_or_else(|| anyhow!("wasi 返回缺少 stderrId"))?;
    let stderr = native_buffer_take_raw(stderr_id).unwrap_or_default();
    let stderr_text = String::from_utf8_lossy(&stderr).to_string();

    if exit_code != 0 {
        return Err(anyhow!(
            "wasi 执行失败，exitCode={exit_code}, stderr={stderr_text}"
        ));
    }

    let stdout_id = payload
        .get("stdoutId")
        .and_then(Value::as_u64)
        .ok_or_else(|| anyhow!("wasi 返回缺少 stdoutId"))?;
    let out =
        native_buffer_take_raw(stdout_id).ok_or_else(|| anyhow!("wasi stdout buffer 不存在"))?;
    Ok(out)
}

#[cfg(not(feature = "wasi"))]
async fn run_wasi_transform_once(_plan: &WasiTransformPlan, _input: Vec<u8>) -> AnyResult<Vec<u8>> {
    Err(anyhow!("当前构建未启用 wasi Cargo 特性"))
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

fn forward_log_event_if_needed(event: &LogEvent) {
    let Some(url) = current_log_http_endpoint() else {
        return;
    };

    let level = event.level.clone();
    let message = event.message.clone();
    let ts_ms = event.ts_ms;

    let _ = host_async_runtime().spawn(async move {
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
                    let line = format!("[qjs:{}:{}] {}", event.ts_ms, event.level, event.message);
                    match event.level.as_str() {
                        "error" => tracing::error!("{}", line),
                        "warn" => tracing::warn!("{}", line),
                        "info" => tracing::info!("{}", line),
                        "debug" => tracing::debug!("{}", line),
                        _ => tracing::info!("{}", line),
                    }
                    forward_log_event_if_needed(&event);
                    LOG_WRITTEN.fetch_add(1, Ordering::Relaxed);
                }
            })
            .expect("创建 log worker 失败");
        tx
    })
}

fn host_async_runtime() -> &'static TokioRuntime {
    HOST_ASYNC_RT.get_or_init(|| {
        TokioRuntimeBuilder::new_multi_thread()
            .worker_threads(4)
            .enable_all()
            .thread_name("rquickjs-host-async")
            .build()
            .expect("创建 Host Tokio runtime 失败")
    })
}

fn http_client_state_cell() -> &'static Mutex<HttpClientState> {
    HTTP_CLIENT_STATE.get_or_init(|| Mutex::new(HttpClientState::default()))
}

pub fn configure_http_client(config: HttpClientConfig) -> AnyResult<()> {
    let mut state = http_client_state_cell()
        .lock()
        .map_err(|_| anyhow!("HTTP client 状态锁已损坏"))?;
    state.client = None;
    state.auto_system_proxy = false;
    state.system_proxy_fingerprint = None;
    state.last_system_proxy_check_at = None;
    state.config = config;
    Ok(())
}

pub fn current_http_client_config() -> HttpClientConfig {
    http_client_state_cell()
        .lock()
        .map(|state| state.config.clone())
        .unwrap_or_default()
}

pub fn configure_native_buffer_gc_ttl_seconds(ttl_seconds: u64) {
    NATIVE_BUF_GC_TTL_SECS.store(ttl_seconds, Ordering::Relaxed);
    start_native_buffer_gc_loop();
}

pub fn current_native_buffer_gc_ttl_seconds() -> u64 {
    NATIVE_BUF_GC_TTL_SECS.load(Ordering::Relaxed)
}

fn normalize_http_proxy_url(raw: &str) -> String {
    let value = raw.trim();
    if value.contains("://") {
        return value.to_string();
    }
    format!("http://{value}")
}

fn normalize_socks5_proxy_url(raw: &str) -> String {
    let value = raw.trim();
    if value.contains("://") {
        return value.to_string();
    }
    format!("socks5h://{value}")
}

fn supports_auto_system_proxy() -> bool {
    cfg!(any(
        target_os = "windows",
        target_os = "macos",
        target_os = "linux"
    ))
}

fn build_http_client(config: &HttpClientConfig) -> AnyResult<(Client, bool)> {
    let mut builder = Client::builder().timeout(Duration::from_secs(30));
    let mut has_explicit_proxy = false;

    if config.use_http_proxy {
        if let Some(proxy_raw) = config.http_proxy.as_deref() {
            let proxy_url = normalize_http_proxy_url(proxy_raw);
            let proxy = Proxy::all(&proxy_url)
                .with_context(|| format!("解析 HTTP 代理地址失败: {proxy_url}"))?;
            builder = builder.proxy(proxy);
            has_explicit_proxy = true;
        } else if config.use_socks5_proxy {
            if let Some(proxy_raw) = config.socks5_proxy.as_deref() {
                let proxy_url = normalize_socks5_proxy_url(proxy_raw);
                let proxy = Proxy::all(&proxy_url)
                    .with_context(|| format!("解析 socks5 代理地址失败: {proxy_url}"))?;
                builder = builder.proxy(proxy);
                has_explicit_proxy = true;
            }
        }
    } else if config.use_socks5_proxy {
        if let Some(proxy_raw) = config.socks5_proxy.as_deref() {
            let proxy_url = normalize_socks5_proxy_url(proxy_raw);
            let proxy = Proxy::all(&proxy_url)
                .with_context(|| format!("解析 socks5 代理地址失败: {proxy_url}"))?;
            builder = builder.proxy(proxy);
            has_explicit_proxy = true;
        }
    }

    if config.disable_tls_verify {
        if cfg!(debug_assertions) {
            builder = builder.danger_accept_invalid_certs(true);
        } else {
            tracing::warn!("disable_tls_verify 已设置，但 release 模式下强制保持证书校验开启");
        }
    }

    let auto_system_proxy = !has_explicit_proxy && supports_auto_system_proxy();
    if !has_explicit_proxy && !auto_system_proxy {
        builder = builder.no_proxy();
    }

    let client = builder.build().context("创建 HTTP client 失败")?;
    Ok((client, auto_system_proxy))
}

fn env_var_or_empty(name: &str) -> String {
    std::env::var(name).unwrap_or_default()
}

#[cfg(target_os = "macos")]
fn macos_system_proxy_fingerprint() -> Option<String> {
    let out = Command::new("scutil").arg("--proxy").output().ok()?;
    if !out.status.success() {
        return None;
    }
    Some(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

#[cfg(windows)]
fn windows_internet_settings_fingerprint() -> Option<String> {
    let key = CURRENT_USER
        .open("Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings")
        .ok()?;
    let proxy_enable = key.get_u32("ProxyEnable").unwrap_or(0);
    let proxy_server = key.get_string("ProxyServer").unwrap_or_default();
    let auto_config_url = key.get_string("AutoConfigURL").unwrap_or_default();
    let auto_detect = key.get_u32("AutoDetect").unwrap_or(0);
    Some(format!(
        "proxyEnable={proxy_enable};proxyServer={proxy_server};autoConfigUrl={auto_config_url};autoDetect={auto_detect}"
    ))
}

fn current_system_proxy_fingerprint() -> Option<String> {
    let env_fingerprint = format!(
        "ALL_PROXY={};all_proxy={};HTTP_PROXY={};http_proxy={};HTTPS_PROXY={};https_proxy={};NO_PROXY={};no_proxy={}",
        env_var_or_empty("ALL_PROXY"),
        env_var_or_empty("all_proxy"),
        env_var_or_empty("HTTP_PROXY"),
        env_var_or_empty("http_proxy"),
        env_var_or_empty("HTTPS_PROXY"),
        env_var_or_empty("https_proxy"),
        env_var_or_empty("NO_PROXY"),
        env_var_or_empty("no_proxy")
    );
    #[cfg(windows)]
    {
        let win_fingerprint = windows_internet_settings_fingerprint().unwrap_or_default();
        return Some(format!("{env_fingerprint};{win_fingerprint}"));
    }
    #[cfg(target_os = "macos")]
    {
        let mac_fingerprint = macos_system_proxy_fingerprint().unwrap_or_default();
        return Some(format!("{env_fingerprint};{mac_fingerprint}"));
    }
    #[cfg(not(any(windows, target_os = "macos")))]
    {
        Some(env_fingerprint)
    }
}

fn http_client() -> AnyResult<Client> {
    let now = Instant::now();
    let mut state = http_client_state_cell()
        .lock()
        .map_err(|_| anyhow!("HTTP client 状态锁已损坏"))?;
    let config = state.config.clone();
    let mut need_rebuild = state.client.is_none();
    if state.auto_system_proxy {
        let need_check = state
            .last_system_proxy_check_at
            .map(|last| now.saturating_duration_since(last) >= HTTP_SYSTEM_PROXY_REFRESH_INTERVAL)
            .unwrap_or(true);
        if need_check {
            let fingerprint = current_system_proxy_fingerprint();
            if state.system_proxy_fingerprint != fingerprint {
                need_rebuild = true;
            }
            state.system_proxy_fingerprint = fingerprint;
            state.last_system_proxy_check_at = Some(now);
        }
    }
    if need_rebuild {
        let (client, auto_system_proxy) = build_http_client(&config)?;
        state.client = Some(client);
        state.config = config;
        state.auto_system_proxy = auto_system_proxy;
        if auto_system_proxy {
            state.system_proxy_fingerprint = current_system_proxy_fingerprint();
            state.last_system_proxy_check_at = Some(now);
        } else {
            state.system_proxy_fingerprint = None;
            state.last_system_proxy_check_at = None;
        }
    }
    match state.client.clone() {
        Some(client) => Ok(client),
        None => Err(anyhow!("HTTP client 不可用")),
    }
}

pub fn http_request_start(
    method: String,
    url: String,
    headers_json: String,
    body: Option<String>,
) -> String {
    {
        let mut pool = http_req_pool().lock().expect("http 请求池加锁失败");
        cleanup_stale_pending(&mut pool, &HTTP_STALE_DROPS);
        if pool.len() >= HTTP_MAX_PENDING {
            return json!({ "ok": false, "error": "http pending 队列已满" }).to_string();
        }
    }

    let id = HTTP_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let sem = Arc::clone(http_io_sem());

    let task = host_async_runtime().spawn(async move {
        let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
            Ok(Ok(permit)) => permit,
            Ok(Err(_)) => {
                let _ =
                    tx.send(json!({ "ok": false, "error": "http 并发控制器不可用" }).to_string());
                return;
            }
            Err(_) => {
                let _ =
                    tx.send(json!({ "ok": false, "error": "http 等待并发许可超时" }).to_string());
                return;
            }
        };
        let payload = match http_request_inner_async(method, url, headers_json, body).await {
            Ok(payload) => payload,
            Err(error) => json!({ "ok": false, "error": format!("{error}") }).to_string(),
        };
        drop(permit);
        let _ = tx.send(payload);
    });

    {
        let mut pool = http_req_pool().lock().expect("http 请求池加锁失败");
        pool.insert(
            id,
            PendingTask {
                rx,
                task,
                created_at: Instant::now(),
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

pub fn http_request_try_take(id: u64) -> String {
    let mut pool = http_req_pool().lock().expect("http 请求池加锁失败");
    cleanup_stale_pending(&mut pool, &HTTP_STALE_DROPS);
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
            json!({ "ok": false, "error": "request 执行线程异常退出" }).to_string()
        }
    }
}

pub fn http_request_drop(id: u64) -> String {
    let mut pool = http_req_pool().lock().expect("http 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

pub fn http_request_start_evented<F>(
    method: String,
    url: String,
    headers_json: String,
    body: Option<String>,
    on_complete: F,
) -> String
where
    F: FnOnce(u64, String) + Send + 'static,
{
    {
        let mut pool = http_req_event_pool()
            .lock()
            .expect("http event 请求池加锁失败");
        cleanup_stale_pending_abort(&mut pool, &HTTP_STALE_DROPS);
        if pool.len() >= HTTP_MAX_PENDING {
            return json!({ "ok": false, "error": "http pending 队列已满" }).to_string();
        }
    }

    let id = HTTP_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let sem = Arc::clone(http_io_sem());

    let task = host_async_runtime().spawn(async move {
        let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
            Ok(Ok(permit)) => permit,
            Ok(Err(_)) => {
                on_complete(
                    id,
                    json!({ "ok": false, "error": "http 并发控制器不可用" }).to_string(),
                );
                return;
            }
            Err(_) => {
                on_complete(
                    id,
                    json!({ "ok": false, "error": "http 等待并发许可超时" }).to_string(),
                );
                return;
            }
        };
        let payload = match http_request_inner_async(method, url, headers_json, body).await {
            Ok(payload) => payload,
            Err(error) => json!({ "ok": false, "error": format!("{error}") }).to_string(),
        };
        drop(permit);
        on_complete(id, payload);
        let _ = http_req_event_pool()
            .lock()
            .map(|mut pool| pool.remove(&id));
    });

    {
        let mut pool = http_req_event_pool()
            .lock()
            .expect("http event 请求池加锁失败");
        pool.insert(
            id,
            PendingAbortTask {
                task,
                created_at: Instant::now(),
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

pub fn http_request_drop_evented(id: u64) -> String {
    let mut pool = http_req_event_pool()
        .lock()
        .expect("http event 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

pub fn timer_start_evented<F>(delay_ms: i64, on_complete: F) -> String
where
    F: FnOnce(u64, String) + Send + 'static,
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

    let task = host_async_runtime().spawn(async move {
        tokio::time::sleep(Duration::from_millis(normalized_delay_ms)).await;
        on_complete(id, json!({ "ok": true }).to_string());
        let _ = timer_req_event_pool()
            .lock()
            .map(|mut pool| pool.remove(&id));
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

    let task = host_async_runtime().spawn(async move {
        let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
            Ok(Ok(permit)) => permit,
            Ok(Err(_)) => {
                let _ = tx.send(json!({ "ok": false, "error": "fs 并发控制器不可用" }).to_string());
                return;
            }
            Err(_) => {
                let _ = tx.send(json!({ "ok": false, "error": "fs 等待并发许可超时" }).to_string());
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

    let task = host_async_runtime().spawn(async move {
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

fn fs_task_dispatch(op: String, args_json: String) -> String {
    let args: Vec<Value> = match serde_json::from_str(&args_json) {
        Ok(v) => v,
        Err(e) => {
            return json!({ "ok": false, "code": "EINVAL", "error": e.to_string() }).to_string();
        }
    };

    let arg_str = |idx: usize, name: &str| -> Result<String, String> {
        args.get(idx)
            .and_then(Value::as_str)
            .map(ToString::to_string)
            .ok_or_else(|| format!("参数 {name} 必须是字符串"))
    };
    let arg_bool = |idx: usize, name: &str| -> Result<bool, String> {
        args.get(idx)
            .and_then(Value::as_bool)
            .ok_or_else(|| format!("参数 {name} 必须是布尔值"))
    };
    let arg_u64 = |idx: usize, name: &str| -> Result<u64, String> {
        args.get(idx)
            .and_then(Value::as_u64)
            .ok_or_else(|| format!("参数 {name} 必须是非负整数"))
    };
    let arg_u32 = |idx: usize, name: &str| -> Result<u32, String> {
        arg_u64(idx, name)
            .and_then(|v| u32::try_from(v).map_err(|_| format!("参数 {name} 超出 u32 范围")))
    };
    let arg_i64 = |idx: usize, name: &str| -> Result<i64, String> {
        args.get(idx)
            .and_then(Value::as_i64)
            .ok_or_else(|| format!("参数 {name} 必须是整数"))
    };
    let arg_opt_str = |idx: usize| -> Option<String> {
        args.get(idx).and_then(|v| {
            if v.is_null() {
                None
            } else {
                v.as_str().map(ToString::to_string)
            }
        })
    };

    match op.as_str() {
        "readFile" => match arg_str(0, "path") {
            Ok(path) => fs_read_file(path, arg_opt_str(1)),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "writeFile" => match (
            arg_str(0, "path"),
            arg_str(1, "dataJson"),
            arg_opt_str(2),
            arg_bool(3, "append"),
        ) {
            (Ok(path), Ok(data_json), encoding, Ok(append)) => {
                fs_write_file(path, data_json, encoding, append)
            }
            _ => {
                json!({ "ok": false, "code": "EINVAL", "error": "writeFile 参数无效" }).to_string()
            }
        },
        "mkdir" => match (arg_str(0, "path"), arg_bool(1, "recursive")) {
            (Ok(path), Ok(recursive)) => fs_mkdir(path, recursive),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "mkdir 参数无效" }).to_string(),
        },
        "readdir" => match (arg_str(0, "path"), arg_bool(1, "withFileTypes")) {
            (Ok(path), Ok(with_file_types)) => fs_readdir(path, with_file_types),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "readdir 参数无效" }).to_string(),
        },
        "stat" => match arg_str(0, "path") {
            Ok(path) => fs_stat(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "lstat" => match arg_str(0, "path") {
            Ok(path) => fs_lstat(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "access" => match arg_str(0, "path") {
            Ok(path) => fs_access(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "unlink" => match arg_str(0, "path") {
            Ok(path) => fs_unlink(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "rm" => match (
            arg_str(0, "path"),
            arg_bool(1, "recursive"),
            arg_bool(2, "force"),
        ) {
            (Ok(path), Ok(recursive), Ok(force)) => fs_rm(path, recursive, force),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "rm 参数无效" }).to_string(),
        },
        "rename" => match (arg_str(0, "oldPath"), arg_str(1, "newPath")) {
            (Ok(old_path), Ok(new_path)) => fs_rename(old_path, new_path),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "rename 参数无效" }).to_string(),
        },
        "copyFile" => match (arg_str(0, "src"), arg_str(1, "dst")) {
            (Ok(src), Ok(dst)) => fs_copy_file(src, dst),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "copyFile 参数无效" }).to_string(),
        },
        "cp" => match (
            arg_str(0, "src"),
            arg_str(1, "dst"),
            arg_bool(2, "recursive"),
            arg_bool(3, "force"),
            arg_bool(4, "errorOnExist"),
        ) {
            (Ok(src), Ok(dst), Ok(recursive), Ok(force), Ok(error_on_exist)) => {
                fs_cp(src, dst, recursive, force, error_on_exist)
            }
            _ => json!({ "ok": false, "code": "EINVAL", "error": "cp 参数无效" }).to_string(),
        },
        "realpath" => match arg_str(0, "path") {
            Ok(path) => fs_realpath(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "readlink" => match arg_str(0, "path") {
            Ok(path) => fs_readlink(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "symlink" => match (
            arg_str(0, "target"),
            arg_str(1, "path"),
            arg_bool(2, "isDir"),
        ) {
            (Ok(target), Ok(path), Ok(is_dir)) => fs_symlink(target, path, is_dir),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "symlink 参数无效" }).to_string(),
        },
        "link" => match (arg_str(0, "existingPath"), arg_str(1, "newPath")) {
            (Ok(existing_path), Ok(new_path)) => fs_link(existing_path, new_path),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "link 参数无效" }).to_string(),
        },
        "truncate" => match (arg_str(0, "path"), arg_u64(1, "len")) {
            (Ok(path), Ok(len)) => fs_truncate(path, len),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "truncate 参数无效" }).to_string(),
        },
        "chmod" => match (arg_str(0, "path"), arg_u32(1, "mode")) {
            (Ok(path), Ok(mode)) => fs_chmod(path, mode),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "chmod 参数无效" }).to_string(),
        },
        "utimes" => match (arg_str(0, "path"), arg_i64(1, "atime"), arg_i64(2, "mtime")) {
            (Ok(path), Ok(atime_millis), Ok(mtime_millis)) => {
                fs_utimes(path, atime_millis, mtime_millis)
            }
            _ => json!({ "ok": false, "code": "EINVAL", "error": "utimes 参数无效" }).to_string(),
        },
        "mkdtemp" => match arg_str(0, "prefix") {
            Ok(prefix) => fs_mkdtemp(prefix),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        _ => {
            json!({ "ok": false, "code": "EINVAL", "error": format!("不支持的 fs 异步操作: {op}") })
                .to_string()
        }
    }
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

pub fn log_emit(level: String, message: String) -> String {
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
    #[cfg(feature = "wasi")]
    let mut wasi_pending = wasi_req_pool().lock().map(|m| m.len()).unwrap_or_default();
    #[cfg(not(feature = "wasi"))]
    let wasi_pending = 0usize;

    if let Ok(mut pool) = http_req_pool().lock() {
        cleanup_stale_pending(&mut pool, &HTTP_STALE_DROPS);
        http_pending = pool.len();
    }
    if let Ok(mut pool) = fs_req_pool().lock() {
        cleanup_stale_pending(&mut pool, &FS_STALE_DROPS);
        fs_pending = pool.len();
    }
    #[cfg(feature = "wasi")]
    if let Ok(mut pool) = wasi_req_pool().lock() {
        cleanup_stale_pending(&mut pool, &WASI_STALE_DROPS);
        wasi_pending = pool.len();
    }

    #[cfg(feature = "wasi")]
    let wasi_cache_size = wasi_module_cache()
        .lock()
        .map(|m| m.len())
        .unwrap_or_default();
    #[cfg(not(feature = "wasi"))]
    let wasi_cache_size = 0usize;
    let http_available = http_io_sem().available_permits();
    let fs_available = fs_io_sem().available_permits();
    #[cfg(feature = "wasi")]
    let wasi_available = wasi_io_sem().available_permits();
    #[cfg(not(feature = "wasi"))]
    let wasi_available = 0usize;
    let native_buffer_pool_size = native_pool().lock().map(|m| m.len()).unwrap_or_default();

    #[cfg(feature = "wasi")]
    let wasi_stale_drops = WASI_STALE_DROPS.load(Ordering::Relaxed);
    #[cfg(not(feature = "wasi"))]
    let wasi_stale_drops = 0_u64;

    #[cfg(feature = "wasi")]
    let wasi_cache_capacity = WASI_MODULE_CACHE_MAX_ENTRIES;
    #[cfg(not(feature = "wasi"))]
    let wasi_cache_capacity = 0usize;

    #[cfg(feature = "wasi")]
    let wasi_cache_hits = WASI_CACHE_HITS.load(Ordering::Relaxed);
    #[cfg(not(feature = "wasi"))]
    let wasi_cache_hits = 0_u64;

    #[cfg(feature = "wasi")]
    let wasi_cache_misses = WASI_CACHE_MISSES.load(Ordering::Relaxed);
    #[cfg(not(feature = "wasi"))]
    let wasi_cache_misses = 0_u64;

    #[cfg(feature = "wasi")]
    let wasi_cache_evictions = WASI_CACHE_EVICTIONS.load(Ordering::Relaxed);
    #[cfg(not(feature = "wasi"))]
    let wasi_cache_evictions = 0_u64;

    json!({
        "ok": true,
        "limits": {
            "pending": {
                "http": HTTP_MAX_PENDING,
                "fs": FS_MAX_PENDING,
                "wasi": WASI_MAX_PENDING,
            },
            "inFlight": {
                "http": HTTP_MAX_IN_FLIGHT,
                "fs": FS_MAX_IN_FLIGHT,
                "wasi": WASI_MAX_IN_FLIGHT,
            }
        },
        "pending": {
            "http": http_pending,
            "fs": fs_pending,
            "wasi": wasi_pending,
        },
        "permits": {
            "httpAvailable": http_available,
            "fsAvailable": fs_available,
            "wasiAvailable": wasi_available,
        },
        "staleDrops": {
            "http": HTTP_STALE_DROPS.load(Ordering::Relaxed),
            "fs": FS_STALE_DROPS.load(Ordering::Relaxed),
            "wasi": wasi_stale_drops,
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
        "wasi": {
            "cacheSize": wasi_cache_size,
            "cacheCapacity": wasi_cache_capacity,
            "cacheHits": wasi_cache_hits,
            "cacheMisses": wasi_cache_misses,
            "cacheEvictions": wasi_cache_evictions,
        }
    })
    .to_string()
}

async fn http_request_inner_async(
    method: String,
    url: String,
    headers_json: String,
    body: Option<String>,
) -> AnyResult<String> {
    let method = Method::from_bytes(method.as_bytes()).context("解析 HTTP method 失败")?;
    let mut headers_map = Map::new();
    let headers_value: Value =
        serde_json::from_str(&headers_json).context("解析 HTTP headers JSON 失败")?;
    let client = http_client()?;
    let mut offload_body_to_native = false;
    let mut wasi_transform_plan: Option<WasiTransformPlan> = None;
    let mut formdata_body = false;
    let mut plain_headers: Vec<(String, String)> = Vec::new();

    let mut builder = client.request(method, &url);

    if let Value::Object(obj) = headers_value {
        for (key, value) in obj {
            if let Some(v) = value.as_str() {
                if key.eq_ignore_ascii_case(HTTP_OFFLOAD_BODY_HEADER) {
                    offload_body_to_native = header_truthy(v);
                    continue;
                }
                if key.eq_ignore_ascii_case(HTTP_WASI_TRANSFORM_HEADER) {
                    wasi_transform_plan = Some(parse_wasi_transform_plan(v)?);
                    continue;
                }
                if key.eq_ignore_ascii_case(HTTP_FORMDATA_BODY_HEADER) {
                    formdata_body = header_truthy(v);
                    continue;
                }
                plain_headers.push((key, v.to_string()));
            }
        }
    }

    for (key, value) in plain_headers {
        if formdata_body && key.eq_ignore_ascii_case("content-type") {
            continue;
        }
        builder = builder.header(&key, value);
    }

    if wasi_transform_plan.is_some() && !offload_body_to_native {
        return Err(anyhow!(
            "使用 wasi transform 时必须同时开启 {HTTP_OFFLOAD_BODY_HEADER}"
        ));
    }

    if formdata_body {
        let raw_plan = body.ok_or_else(|| anyhow!("formdata 请求缺少 body payload"))?;
        let plan = parse_host_formdata_plan(&raw_plan)?;
        let form = build_multipart_form(plan)?;
        builder = builder.multipart(form);
    } else if let Some(content) = body {
        builder = builder.body(content);
    }

    let response = builder.send().await.context("发送 HTTP 请求失败")?;
    let auto_offload_body = should_auto_offload_response(response.headers());
    let status = response.status();
    let final_url = response.url().to_string();

    for (name, value) in response.headers() {
        let value_text = value.to_str().context("解析 HTTP 响应头失败")?.to_string();
        headers_map.insert(name.to_string(), Value::String(value_text));
    }

    if offload_body_to_native || auto_offload_body {
        let mut body_bytes = response
            .bytes()
            .await
            .context("读取 HTTP 响应体字节失败")?
            .to_vec();

        let mut wasi_applied = false;
        let mut wasi_need_js_processing = false;
        let mut wasi_function: Option<String> = None;
        let mut wasi_output_type: Option<String> = None;
        if let Some(plan) = &wasi_transform_plan {
            wasi_need_js_processing = plan.js_process.unwrap_or(false);
            wasi_function = plan.function.clone();
            wasi_output_type = Some(plan.output_type.clone());
            body_bytes = run_wasi_transform_once(plan, body_bytes).await?;
            wasi_applied = true;
        }

        let native_buffer_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
        let body_len = body_bytes.len();

        {
            let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
            pool.insert(native_buffer_id, NativeBufferEntry::new(body_bytes));
        }

        headers_map.insert(
            "x-rquickjs-host-offloaded".to_string(),
            Value::String("1".to_string()),
        );
        headers_map.insert(
            "x-rquickjs-host-native-buffer-id".to_string(),
            Value::String(native_buffer_id.to_string()),
        );

        return Ok(json!({
            "ok": true,
            "status": status.as_u16(),
            "statusText": status.canonical_reason().unwrap_or(""),
            "url": final_url,
            "headers": headers_map,
            "body": "",
            "offloaded": true,
            "nativeBufferId": native_buffer_id,
            "offloadedBytes": body_len,
            "wasiApplied": wasi_applied,
            "wasiNeedJsProcessing": wasi_need_js_processing,
            "wasiFunction": wasi_function,
            "wasiOutputType": wasi_output_type
        })
        .to_string());
    }

    let body_text = response.text().await.context("读取 HTTP 响应体失败")?;

    Ok(json!({
        "ok": true,
        "status": status.as_u16(),
        "statusText": status.canonical_reason().unwrap_or(""),
        "url": final_url,
        "headers": headers_map,
        "body": body_text
    })
    .to_string())
}

static NATIVE_BUF_ID: AtomicU64 = AtomicU64::new(1);
static NATIVE_BUF_POOL: OnceLock<Mutex<HashMap<u64, NativeBufferEntry>>> = OnceLock::new();

fn native_pool() -> &'static Mutex<HashMap<u64, NativeBufferEntry>> {
    let pool = NATIVE_BUF_POOL.get_or_init(|| Mutex::new(HashMap::new()));
    start_native_buffer_gc_loop();
    pool
}

fn native_buffer_ttl() -> Option<Duration> {
    let ttl_secs = NATIVE_BUF_GC_TTL_SECS.load(Ordering::Relaxed);
    if ttl_secs == 0 {
        None
    } else {
        Some(Duration::from_secs(ttl_secs))
    }
}

fn cleanup_stale_native_buffers(pool: &mut HashMap<u64, NativeBufferEntry>) -> usize {
    let Some(ttl) = native_buffer_ttl() else {
        return 0;
    };
    let now = Instant::now();
    let stale_ids: Vec<u64> = pool
        .iter()
        .filter_map(|(id, entry)| {
            if now.duration_since(entry.created_at) > ttl {
                Some(*id)
            } else {
                None
            }
        })
        .collect();

    for id in &stale_ids {
        pool.remove(id);
    }
    stale_ids.len()
}

fn start_native_buffer_gc_loop() {
    NATIVE_BUF_GC_LOOP_STARTED.get_or_init(|| {
        thread::Builder::new()
            .name("rquickjs-native-buf-gc".to_string())
            .spawn(|| {
                loop {
                    thread::sleep(NATIVE_BUFFER_GC_INTERVAL);
                    let removed = {
                        let mut pool = match native_pool().lock() {
                            Ok(pool) => pool,
                            Err(_) => continue,
                        };
                        cleanup_stale_native_buffers(&mut pool)
                    };
                    if removed > 0 {
                        NATIVE_BUF_GC_DROPS.fetch_add(removed as u64, Ordering::Relaxed);
                    }
                }
            })
            .expect("创建 native buffer gc 线程失败");
    });
}

fn parse_u8_json_array(data_json: &str) -> AnyResult<Vec<u8>> {
    let value: Value = serde_json::from_str(data_json).context("解析字节数组 JSON 失败")?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("数据必须是字节数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let n = item
            .as_u64()
            .ok_or_else(|| anyhow!("字节数组元素必须是整数"))?;
        if n > 255 {
            return Err(anyhow!("字节数组元素必须在 0-255 范围"));
        }
        out.push(n as u8);
    }
    Ok(out)
}

pub fn native_buffer_put(data_json: String) -> String {
    let bytes = match parse_u8_json_array(&data_json) {
        Ok(bytes) => bytes,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(id, NativeBufferEntry::new(bytes));
    json!({ "ok": true, "id": id }).to_string()
}

pub fn native_buffer_put_raw(bytes: Vec<u8>) -> u64 {
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(id, NativeBufferEntry::new(bytes));
    id
}

pub fn native_buffer_take(id: u64) -> String {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    match pool.remove(&id) {
        Some(entry) => json!({ "ok": true, "data": entry.bytes }).to_string(),
        None => json!({ "ok": false, "error": "buffer id 不存在" }).to_string(),
    }
}

pub fn native_buffer_take_raw(id: u64) -> Option<Vec<u8>> {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.remove(&id).map(|entry| entry.bytes)
}

pub fn native_buffer_free(id: u64) -> String {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    let existed = pool.remove(&id).is_some();
    json!({ "ok": true, "freed": existed }).to_string()
}

fn native_apply_op(
    op: &str,
    mut bytes: Vec<u8>,
    extra: Option<Vec<u8>>,
) -> Result<Vec<u8>, String> {
    match op {
        "invert" => {
            for b in &mut bytes {
                *b = 255 - *b;
            }
            Ok(bytes)
        }
        "grayscale_rgba" => {
            for chunk in bytes.chunks_exact_mut(4) {
                let r = chunk[0] as f32;
                let g = chunk[1] as f32;
                let b = chunk[2] as f32;
                let y = (0.299 * r + 0.587 * g + 0.114 * b).round() as u8;
                chunk[0] = y;
                chunk[1] = y;
                chunk[2] = y;
            }
            Ok(bytes)
        }
        "xor" => {
            let rhs = extra.ok_or_else(|| "xor 需要第二个输入参数".to_string())?;
            if rhs.len() != bytes.len() {
                return Err("xor 两个输入长度必须一致".to_string());
            }
            for i in 0..bytes.len() {
                bytes[i] ^= rhs[i];
            }
            Ok(bytes)
        }
        "noop" => Ok(bytes),
        "gzip_decompress" => {
            let mut decoder = GzDecoder::new(bytes.as_slice());
            let mut out = Vec::new();
            decoder
                .read_to_end(&mut out)
                .map_err(|e| format!("gzip 解压失败: {e}"))?;
            Ok(out)
        }
        "gzip_compress" => {
            let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
            encoder
                .write_all(&bytes)
                .map_err(|e| format!("gzip 压缩失败: {e}"))?;
            encoder.finish().map_err(|e| format!("gzip 压缩失败: {e}"))
        }
        _ => Err(format!("不支持的 native op: {op}")),
    }
}

fn parse_chain_steps(steps_json: &str) -> AnyResult<Vec<(String, Option<u64>)>> {
    let value: Value = serde_json::from_str(steps_json).context("解析 steps JSON 失败")?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("steps 必须是数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let obj = item
            .as_object()
            .ok_or_else(|| anyhow!("steps 元素必须是对象"))?;
        let op = obj
            .get("op")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("steps 元素缺少 op 字段"))?
            .to_string();
        let extra_input_id = obj.get("extraInputId").and_then(Value::as_u64);
        out.push((op, extra_input_id));
    }
    Ok(out)
}

pub fn native_exec(
    op: String,
    input_id: u64,
    _args_json: Option<String>,
    extra_input_id: Option<u64>,
) -> String {
    let (input, extra) = {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        let input = match pool.remove(&input_id) {
            Some(entry) => entry,
            None => return json!({ "ok": false, "error": "input id 不存在" }).to_string(),
        };

        let extra = if let Some(extra_id) = extra_input_id {
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    pool.insert(input_id, input);
                    return json!({ "ok": false, "error": "extra input id 不存在" }).to_string();
                }
            }
        } else {
            None
        };

        (input.bytes, extra)
    };

    let output = match native_apply_op(&op, input, extra) {
        Ok(bytes) => bytes,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };

    let output_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(output_id, NativeBufferEntry::new(output));
    json!({ "ok": true, "id": output_id }).to_string()
}

pub fn native_exec_chain(input_id: u64, steps_json: String) -> String {
    let steps = match parse_chain_steps(&steps_json) {
        Ok(steps) => steps,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    if steps.is_empty() {
        return json!({ "ok": false, "error": "steps 不能为空" }).to_string();
    }

    let mut current = {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        match pool.remove(&input_id) {
            Some(entry) => entry.bytes,
            None => return json!({ "ok": false, "error": "input id 不存在" }).to_string(),
        }
    };

    for (op, extra_input_id) in steps {
        let extra = if let Some(extra_id) = extra_input_id {
            let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    return json!({ "ok": false, "error": "extra input id 不存在" }).to_string();
                }
            }
        } else {
            None
        };

        current = match native_apply_op(&op, current, extra) {
            Ok(bytes) => bytes,
            Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
        };
    }

    let output_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(output_id, NativeBufferEntry::new(current));
    json!({ "ok": true, "id": output_id }).to_string()
}

#[cfg(feature = "wasi")]
fn parse_argv(args_json: Option<String>) -> AnyResult<Vec<String>> {
    let Some(raw) = args_json else {
        return Ok(Vec::new());
    };
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }
    let value: Value = serde_json::from_str(&raw).context("解析 argv JSON 失败")?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("argv 必须是字符串数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        out.push(
            item.as_str()
                .ok_or_else(|| anyhow!("argv 必须是字符串数组"))?
                .to_string(),
        );
    }
    Ok(out)
}

#[cfg(feature = "wasi")]
const WASI_MODULE_CACHE_MAX_ENTRIES: usize = 64;

#[cfg(feature = "wasi")]
fn wasi_module_get_or_compile(wasm_bytes: &[u8]) -> AnyResult<Module> {
    {
        let cache = wasi_module_cache()
            .lock()
            .expect("wasi module cache 加锁失败");
        if let Some(module) = cache.get(wasm_bytes) {
            WASI_CACHE_HITS.fetch_add(1, Ordering::Relaxed);
            return Ok(module.clone());
        }
    }

    WASI_CACHE_MISSES.fetch_add(1, Ordering::Relaxed);

    let engine = wasi_engine();
    let module = Module::new(engine, wasm_bytes).map_err(|e| anyhow!("编译 WASM 模块失败: {e}"))?;

    {
        let key = wasm_bytes.to_vec();
        let mut cache = wasi_module_cache()
            .lock()
            .expect("wasi module cache 加锁失败");
        if let Some(existing) = cache.get(wasm_bytes) {
            return Ok(existing.clone());
        }
        cache.insert(key.clone(), module.clone());

        let mut order = wasi_module_cache_order()
            .lock()
            .expect("wasi module cache order 加锁失败");
        order.push_back(key);

        while cache.len() > WASI_MODULE_CACHE_MAX_ENTRIES {
            if let Some(oldest) = order.pop_front() {
                cache.remove(&oldest);
                WASI_CACHE_EVICTIONS.fetch_add(1, Ordering::Relaxed);
            } else {
                break;
            }
        }
    }

    Ok(module)
}

#[cfg(feature = "wasi")]
fn wasi_run_inner(
    module_id: u64,
    stdin_id: Option<u64>,
    args_json: Option<String>,
    consume_module: bool,
) -> String {
    let wasm_bytes = {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        if consume_module {
            match pool.remove(&module_id) {
                Some(entry) => entry.bytes,
                None => {
                    return json!({ "ok": false, "error": "module id 不存在" }).to_string();
                }
            }
        } else {
            match pool.get(&module_id) {
                Some(entry) => entry.bytes.clone(),
                None => {
                    return json!({ "ok": false, "error": "module id 不存在" }).to_string();
                }
            }
        }
    };

    let stdin_bytes = if let Some(id) = stdin_id {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        match pool.remove(&id) {
            Some(entry) => entry.bytes,
            None => return json!({ "ok": false, "error": "stdin id 不存在" }).to_string(),
        }
    } else {
        Vec::new()
    };

    let args = match parse_argv(args_json) {
        Ok(v) => v,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };

    let engine = wasi_engine();
    let module = match wasi_module_get_or_compile(&wasm_bytes) {
        Ok(module) => module,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };

    let linker = match wasi_linker() {
        Ok(linker) => linker,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };

    let stdout_pipe = wasmtime_wasi::p2::pipe::MemoryOutputPipe::new(1024 * 1024 * 64);
    let stderr_pipe = wasmtime_wasi::p2::pipe::MemoryOutputPipe::new(1024 * 1024 * 64);
    let stdin_pipe = wasmtime_wasi::p2::pipe::MemoryInputPipe::new(stdin_bytes);

    let mut builder = WasiCtxBuilder::new();
    builder.stdin(stdin_pipe);
    builder.stdout(stdout_pipe.clone());
    builder.stderr(stderr_pipe.clone());

    let mut argv = vec!["module.wasm".to_string()];
    argv.extend(args);
    builder.args(&argv);

    let wasi = builder.build_p1();
    let mut store = Store::new(engine, wasi);

    let instance = match linker.instantiate(&mut store, &module) {
        Ok(instance) => instance,
        Err(error) => return json!({ "ok": false, "error": error.to_string() }).to_string(),
    };

    let start = match instance.get_typed_func::<(), ()>(&mut store, "_start") {
        Ok(func) => func,
        Err(error) => return json!({ "ok": false, "error": error.to_string() }).to_string(),
    };

    let mut exit_code = 0_i32;
    if let Err(error) = start.call(&mut store, ()) {
        if let Some(code) = error.downcast_ref::<wasmtime_wasi::I32Exit>() {
            exit_code = code.0;
        } else {
            return json!({ "ok": false, "error": error.to_string() }).to_string();
        }
    }

    let stdout_bytes = stdout_pipe.contents().to_vec();
    let stderr_bytes = stderr_pipe.contents().to_vec();

    let stdout_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let stderr_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(stdout_id, NativeBufferEntry::new(stdout_bytes));
    pool.insert(stderr_id, NativeBufferEntry::new(stderr_bytes));

    json!({
        "ok": true,
        "exitCode": exit_code,
        "stdoutId": stdout_id,
        "stderrId": stderr_id
    })
    .to_string()
}

#[cfg(feature = "wasi")]
pub fn wasi_run_start(
    module_id: u64,
    stdin_id: Option<u64>,
    args_json: Option<String>,
    consume_module: bool,
) -> String {
    {
        let mut pool = wasi_req_pool().lock().expect("wasi 请求池加锁失败");
        cleanup_stale_pending(&mut pool, &WASI_STALE_DROPS);
        if pool.len() >= WASI_MAX_PENDING {
            return json!({ "ok": false, "error": "wasi pending 队列已满" }).to_string();
        }
    }

    let id = WASI_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let sem = Arc::clone(wasi_io_sem());

    let task = host_async_runtime().spawn(async move {
        let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
            Ok(Ok(permit)) => permit,
            Ok(Err(_)) => {
                let _ =
                    tx.send(json!({ "ok": false, "error": "wasi 并发控制器不可用" }).to_string());
                return;
            }
            Err(_) => {
                let _ =
                    tx.send(json!({ "ok": false, "error": "wasi 等待并发许可超时" }).to_string());
                return;
            }
        };
        let payload = tokio::task::spawn_blocking(move || {
            wasi_run_inner(module_id, stdin_id, args_json, consume_module)
        })
        .await
        .unwrap_or_else(|e| json!({ "ok": false, "error": e.to_string() }).to_string());
        drop(permit);
        let _ = tx.send(payload);
    });

    {
        let mut pool = wasi_req_pool().lock().expect("wasi 请求池加锁失败");
        pool.insert(
            id,
            PendingTask {
                rx,
                task,
                created_at: Instant::now(),
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

#[cfg(feature = "wasi")]
pub fn wasi_run_try_take(id: u64) -> String {
    let mut pool = wasi_req_pool().lock().expect("wasi 请求池加锁失败");
    cleanup_stale_pending(&mut pool, &WASI_STALE_DROPS);
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
            json!({ "ok": false, "error": "wasi 执行任务异常退出" }).to_string()
        }
    }
}

#[cfg(feature = "wasi")]
pub fn wasi_run_drop(id: u64) -> String {
    let mut pool = wasi_req_pool().lock().expect("wasi 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

#[cfg(feature = "wasi")]
pub fn wasi_run_start_evented<F>(
    module_id: u64,
    stdin_id: Option<u64>,
    args_json: Option<String>,
    consume_module: bool,
    on_complete: F,
) -> String
where
    F: FnOnce(u64, String) + Send + 'static,
{
    {
        let mut pool = wasi_req_event_pool()
            .lock()
            .expect("wasi event 请求池加锁失败");
        cleanup_stale_pending_abort(&mut pool, &WASI_STALE_DROPS);
        if pool.len() >= WASI_MAX_PENDING {
            return json!({ "ok": false, "error": "wasi pending 队列已满" }).to_string();
        }
    }

    let id = WASI_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let sem = Arc::clone(wasi_io_sem());

    let task = host_async_runtime().spawn(async move {
        let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
            Ok(Ok(permit)) => permit,
            Ok(Err(_)) => {
                on_complete(
                    id,
                    json!({ "ok": false, "error": "wasi 并发控制器不可用" }).to_string(),
                );
                return;
            }
            Err(_) => {
                on_complete(
                    id,
                    json!({ "ok": false, "error": "wasi 等待并发许可超时" }).to_string(),
                );
                return;
            }
        };
        let payload = tokio::task::spawn_blocking(move || {
            wasi_run_inner(module_id, stdin_id, args_json, consume_module)
        })
        .await
        .unwrap_or_else(|e| json!({ "ok": false, "error": e.to_string() }).to_string());
        drop(permit);
        on_complete(id, payload);
        let _ = wasi_req_event_pool()
            .lock()
            .map(|mut pool| pool.remove(&id));
    });

    {
        let mut pool = wasi_req_event_pool()
            .lock()
            .expect("wasi event 请求池加锁失败");
        pool.insert(
            id,
            PendingAbortTask {
                task,
                created_at: Instant::now(),
            },
        );
    }

    json!({ "ok": true, "id": id }).to_string()
}

#[cfg(feature = "wasi")]
pub fn wasi_run_drop_evented(id: u64) -> String {
    let mut pool = wasi_req_event_pool()
        .lock()
        .expect("wasi event 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

#[cfg(not(feature = "wasi"))]
pub fn wasi_run_start(
    _module_id: u64,
    _stdin_id: Option<u64>,
    _args_json: Option<String>,
    _consume_module: bool,
) -> String {
    json!({ "ok": false, "error": "当前构建未启用 wasi Cargo 特性" }).to_string()
}

#[cfg(not(feature = "wasi"))]
pub fn wasi_run_try_take(_id: u64) -> String {
    json!({ "ok": false, "error": "当前构建未启用 wasi Cargo 特性" }).to_string()
}

#[cfg(not(feature = "wasi"))]
pub fn wasi_run_drop(_id: u64) -> String {
    json!({ "ok": true, "dropped": false }).to_string()
}

#[cfg(not(feature = "wasi"))]
pub fn wasi_run_start_evented<F>(
    _module_id: u64,
    _stdin_id: Option<u64>,
    _args_json: Option<String>,
    _consume_module: bool,
    _on_complete: F,
) -> String
where
    F: FnOnce(u64, String) + Send + 'static,
{
    json!({ "ok": false, "error": "当前构建未启用 wasi Cargo 特性" }).to_string()
}

#[cfg(not(feature = "wasi"))]
pub fn wasi_run_drop_evented(_id: u64) -> String {
    json!({ "ok": true, "dropped": false }).to_string()
}

fn parse_host_ok_payload(raw: String) -> AnyResult<Value> {
    let payload: Value = serde_json::from_str(&raw).context("解析宿主返回 JSON 失败")?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload)
    } else {
        Err(anyhow!(
            "{}",
            payload
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("调用失败")
        ))
    }
}

fn parse_bridge_args(args_json: Option<String>) -> AnyResult<Vec<Value>> {
    let Some(raw) = args_json else {
        return Ok(Vec::new());
    };
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }
    let value: Value = serde_json::from_str(&raw).context("解析 bridge args JSON 失败")?;
    value
        .as_array()
        .cloned()
        .ok_or_else(|| anyhow!("args 必须是数组"))
}

pub fn call_js_global_function(
    ctx: &Ctx<'_>,
    function_name: String,
    args_json: Option<String>,
) -> AnyResult<Value> {
    let args = parse_bridge_args(args_json)?;
    let function_name_json = serde_json::to_string(&function_name).context("序列化函数名失败")?;
    let args_literal = serde_json::to_string(&args).context("序列化函数参数失败")?;

    let script = format!(
        r#"
        (async () => {{
          const fnName = {function_name_json};
          const args = {args_literal};
          const fn = globalThis[fnName];
          if (typeof fn !== "function") {{
            throw new Error(`JS 函数不存在: ${{fnName}}`);
          }}
          const data = await fn(...args);
          return JSON.stringify({{ ok: true, data }});
        }})()
        "#
    );

    let promise: Promise = ctx.eval(script).context("执行 JS 调用脚本失败")?;
    let raw: String = promise.finish().context("等待 JS Promise 失败")?;
    let payload: Value = serde_json::from_str(&raw).context("解析 JS 返回 JSON 失败")?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        Err(anyhow!(
            "{}",
            payload
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("调用失败")
        ))
    }
}

fn require_arg<'a>(args: &'a [Value], index: usize, name: &str) -> AnyResult<&'a Value> {
    args.get(index).ok_or_else(|| anyhow!("缺少参数: {name}"))
}

fn require_str_arg(args: &[Value], index: usize, name: &str) -> AnyResult<String> {
    require_arg(args, index, name)?
        .as_str()
        .map(ToString::to_string)
        .ok_or_else(|| anyhow!("参数 {name} 必须是字符串"))
}

fn require_u64_arg(args: &[Value], index: usize, name: &str) -> AnyResult<u64> {
    require_arg(args, index, name)?
        .as_u64()
        .ok_or_else(|| anyhow!("参数 {name} 必须是非负整数"))
}

fn parse_u8_json_value(value: &Value) -> AnyResult<Vec<u8>> {
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("数据必须是字节数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let n = item
            .as_u64()
            .ok_or_else(|| anyhow!("字节数组元素必须是整数"))?;
        if n > 255 {
            return Err(anyhow!("字节数组元素必须在 0-255 范围"));
        }
        out.push(n as u8);
    }
    Ok(out)
}

fn crypto_md5_hex(input: String) -> AnyResult<Value> {
    let digest = md5::compute(input.as_bytes());
    Ok(json!(format!("{:x}", digest)))
}

fn crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64: String, key_raw: String) -> AnyResult<Value> {
    let mut payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();

    let plain = match key.len() {
        16 => ecb::Decryptor::<Aes128>::new_from_slice(&key)
            .map_err(|_| anyhow!("AES-128 密钥长度无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-128 ECB 解密失败"))?
            .to_vec(),
        24 => ecb::Decryptor::<Aes192>::new_from_slice(&key)
            .map_err(|_| anyhow!("AES-192 密钥长度无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-192 ECB 解密失败"))?
            .to_vec(),
        32 => ecb::Decryptor::<Aes256>::new_from_slice(&key)
            .map_err(|_| anyhow!("AES-256 密钥长度无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-256 ECB 解密失败"))?
            .to_vec(),
        _ => {
            return Err(anyhow!(
                "AES ECB 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    };

    let text = String::from_utf8(plain).context("解密结果不是有效 UTF-8")?;
    Ok(json!(text))
}

fn compression_gzip_decompress(input: Vec<u8>) -> AnyResult<Value> {
    let mut decoder = GzDecoder::new(input.as_slice());
    let mut out = Vec::new();
    decoder.read_to_end(&mut out).context("gzip 解压失败")?;
    Ok(json!(out))
}

fn compression_gzip_compress(input: Vec<u8>) -> AnyResult<Value> {
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(&input).context("gzip 压缩失败")?;
    let out = encoder.finish().context("gzip 压缩失败")?;
    Ok(json!(out))
}

fn bridge_call_inner(
    runtime_name: String,
    name: String,
    args_json: Option<String>,
) -> AnyResult<Value> {
    let args = parse_bridge_args(args_json)?;

    match name.as_str() {
        "math.add" => {
            let a = require_arg(&args, 0, "a")?
                .as_f64()
                .ok_or_else(|| anyhow!("参数 a 必须是数字"))?;
            let b = require_arg(&args, 1, "b")?
                .as_f64()
                .ok_or_else(|| anyhow!("参数 b 必须是数字"))?;
            Ok(json!(a + b))
        }
        "native.put" => {
            let bytes = parse_u8_json_value(require_arg(&args, 0, "bytes")?)?;
            let id = native_buffer_put_raw(bytes);
            Ok(json!(id))
        }
        "native.take" => {
            let id = require_u64_arg(&args, 0, "id")?;
            match native_buffer_take_raw(id) {
                Some(bytes) => Ok(json!(bytes)),
                None => Err(anyhow!("buffer id 不存在")),
            }
        }
        "native.exec" => {
            let op = require_str_arg(&args, 0, "op")?;
            let input_id = require_u64_arg(&args, 1, "inputId")?;
            let args_json = args.get(2).and_then(|v| {
                if v.is_null() {
                    None
                } else {
                    Some(v.to_string())
                }
            });
            let extra_input_id = args.get(3).and_then(Value::as_u64);
            let payload =
                parse_host_ok_payload(native_exec(op, input_id, args_json, extra_input_id))?;
            Ok(payload.get("id").cloned().unwrap_or(Value::Null))
        }
        "crypto.md5_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_md5_hex(input)
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64, key_raw)
        }
        "compression.gzip_decompress" => {
            let input = parse_u8_json_value(require_arg(&args, 0, "input")?)?;
            compression_gzip_decompress(input)
        }
        "compression.gzip_compress" => {
            let input = parse_u8_json_value(require_arg(&args, 0, "input")?)?;
            compression_gzip_compress(input)
        }
        _ => call_registered_bridge_route_sync(runtime_name, name, args),
    }
}

async fn bridge_call_inner_async(
    runtime_name: String,
    name: String,
    args_json: Option<String>,
) -> AnyResult<Value> {
    let args = parse_bridge_args(args_json)?;

    match name.as_str() {
        "math.add" => {
            let a = require_arg(&args, 0, "a")?
                .as_f64()
                .ok_or_else(|| anyhow!("参数 a 必须是数字"))?;
            let b = require_arg(&args, 1, "b")?
                .as_f64()
                .ok_or_else(|| anyhow!("参数 b 必须是数字"))?;
            Ok(json!(a + b))
        }
        "native.put" => {
            let bytes = parse_u8_json_value(require_arg(&args, 0, "bytes")?)?;
            let id = native_buffer_put_raw(bytes);
            Ok(json!(id))
        }
        "native.take" => {
            let id = require_u64_arg(&args, 0, "id")?;
            match native_buffer_take_raw(id) {
                Some(bytes) => Ok(json!(bytes)),
                None => Err(anyhow!("buffer id 不存在")),
            }
        }
        "native.exec" => {
            let op = require_str_arg(&args, 0, "op")?;
            let input_id = require_u64_arg(&args, 1, "inputId")?;
            let args_json = args.get(2).and_then(|v| {
                if v.is_null() {
                    None
                } else {
                    Some(v.to_string())
                }
            });
            let extra_input_id = args.get(3).and_then(Value::as_u64);
            let payload =
                parse_host_ok_payload(native_exec(op, input_id, args_json, extra_input_id))?;
            Ok(payload.get("id").cloned().unwrap_or(Value::Null))
        }
        "crypto.md5_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_md5_hex(input)
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64, key_raw)
        }
        "compression.gzip_decompress" => {
            let input = parse_u8_json_value(require_arg(&args, 0, "input")?)?;
            compression_gzip_decompress(input)
        }
        "compression.gzip_compress" => {
            let input = parse_u8_json_value(require_arg(&args, 0, "input")?)?;
            compression_gzip_compress(input)
        }
        _ => call_registered_bridge_route(runtime_name, name, args).await,
    }
}

pub fn host_call(runtime_name: String, name: String, args_json: Option<String>) -> String {
    match bridge_call_inner(runtime_name, name, args_json) {
        Ok(data) => json!({ "ok": true, "data": data }).to_string(),
        Err(error) => json!({ "ok": false, "error": format!("{error:#}") }).to_string(),
    }
}

pub fn host_call_start(runtime_name: String, name: String, args_json: Option<String>) -> String {
    {
        let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
        cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
        if pool.len() >= BRIDGE_MAX_PENDING {
            return json!({ "ok": false, "error": "bridge pending 队列已满" }).to_string();
        }
    }

    let id = BRIDGE_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let task = host_async_runtime().spawn(async move {
        let payload = match bridge_call_inner_async(runtime_name, name, args_json).await {
            Ok(data) => json!({ "ok": true, "data": data }).to_string(),
            Err(error) => json!({ "ok": false, "error": format!("{error:#}") }).to_string(),
        };
        let _ = tx.send(payload);
    });

    {
        let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
        pool.insert(
            id,
            PendingTask {
                rx,
                task,
                created_at: Instant::now(),
            },
        );
    }

    json!({ "ok": true, "data": { "id": id } }).to_string()
}

pub fn host_call_try_take(id: u64) -> String {
    let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
    cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
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
            json!({ "ok": false, "error": "request 执行线程异常退出" }).to_string()
        }
    }
}

pub fn host_call_drop(id: u64) -> String {
    let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

fn io_error_code(error: &io::Error) -> &'static str {
    match error.kind() {
        io::ErrorKind::NotFound => "ENOENT",
        io::ErrorKind::PermissionDenied => "EACCES",
        io::ErrorKind::AlreadyExists => "EEXIST",
        io::ErrorKind::InvalidInput => "EINVAL",
        io::ErrorKind::InvalidData => "EINVAL",
        io::ErrorKind::TimedOut => "ETIMEDOUT",
        io::ErrorKind::Interrupted => "EINTR",
        io::ErrorKind::WouldBlock => "EWOULDBLOCK",
        _ => "EIO",
    }
}

fn fs_error_payload(error: io::Error) -> String {
    json!({
        "ok": false,
        "code": io_error_code(&error),
        "error": error.to_string()
    })
    .to_string()
}

fn system_time_to_millis(time: Result<SystemTime, io::Error>) -> Option<i64> {
    let value = time.ok()?;
    let dur = value.duration_since(UNIX_EPOCH).ok()?;
    Some(dur.as_millis() as i64)
}

fn normalize_encoding(encoding: Option<String>) -> String {
    encoding
        .unwrap_or_default()
        .trim()
        .to_ascii_lowercase()
        .replace('_', "-")
}

pub fn fs_read_file(path: String, encoding: Option<String>) -> String {
    match fs::read(&path) {
        Ok(bytes) => {
            let encoding = normalize_encoding(encoding);
            if encoding.is_empty() {
                json!({ "ok": true, "kind": "bytes", "data": bytes }).to_string()
            } else if encoding == "utf8" || encoding == "utf-8" {
                match String::from_utf8(bytes) {
                    Ok(text) => json!({ "ok": true, "kind": "text", "data": text }).to_string(),
                    Err(err) => json!({ "ok": false, "code": "EINVAL", "error": err.to_string() })
                        .to_string(),
                }
            } else {
                json!({
                    "ok": false,
                    "code": "EINVAL",
                    "error": format!("不支持的编码: {encoding}")
                })
                .to_string()
            }
        }
        Err(error) => fs_error_payload(error),
    }
}

fn parse_fs_write_payload(data_json: String, encoding: Option<String>) -> Result<Vec<u8>, String> {
    let value: Value = serde_json::from_str(&data_json).map_err(|e| e.to_string())?;
    let kind = value
        .get("kind")
        .and_then(Value::as_str)
        .ok_or("缺少 kind 字段")?;

    if kind == "bytes" {
        let list = value
            .get("data")
            .and_then(Value::as_array)
            .ok_or("bytes 数据格式错误")?;
        let mut out = Vec::with_capacity(list.len());
        for item in list {
            let num = item.as_u64().ok_or("bytes 数据必须是 0-255 的整数")?;
            if num > 255 {
                return Err("bytes 数据必须在 0-255 范围内".to_string());
            }
            out.push(num as u8);
        }
        return Ok(out);
    }

    if kind == "text" {
        let text = value
            .get("data")
            .and_then(Value::as_str)
            .ok_or("text 数据格式错误")?;
        let encoding = normalize_encoding(encoding);
        if encoding.is_empty() || encoding == "utf8" || encoding == "utf-8" {
            return Ok(text.as_bytes().to_vec());
        }
        return Err(format!("不支持的编码: {encoding}"));
    }

    Err(format!("不支持的 kind: {kind}"))
}

pub fn fs_write_file(
    path: String,
    data_json: String,
    encoding: Option<String>,
    append: bool,
) -> String {
    let bytes = match parse_fs_write_payload(data_json, encoding) {
        Ok(bytes) => bytes,
        Err(error) => {
            return json!({ "ok": false, "code": "EINVAL", "error": format!("{error}") })
                .to_string();
        }
    };

    let result = if append {
        fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)
            .and_then(|mut file| file.write_all(&bytes))
    } else {
        fs::write(&path, bytes)
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_mkdir(path: String, recursive: bool) -> String {
    let result = if recursive {
        fs::create_dir_all(&path)
    } else {
        fs::create_dir(&path)
    };
    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_readdir(path: String, with_file_types: bool) -> String {
    match fs::read_dir(&path) {
        Ok(read_dir) => {
            let mut entries = Vec::new();
            for entry in read_dir {
                match entry {
                    Ok(item) => {
                        let name = item.file_name().to_string_lossy().to_string();
                        if with_file_types {
                            match item.file_type() {
                                Ok(file_type) => entries.push(json!({
                                    "name": name,
                                    "isFile": file_type.is_file(),
                                    "isDirectory": file_type.is_dir(),
                                    "isSymbolicLink": file_type.is_symlink(),
                                })),
                                Err(error) => return fs_error_payload(error),
                            }
                        } else {
                            entries.push(Value::String(name));
                        }
                    }
                    Err(error) => return fs_error_payload(error),
                }
            }
            json!({ "ok": true, "entries": entries }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_stat(path: String) -> String {
    match fs::metadata(&path) {
        Ok(metadata) => json!({
            "ok": true,
            "isFile": metadata.is_file(),
            "isDirectory": metadata.is_dir(),
            "isSymbolicLink": metadata.file_type().is_symlink(),
            "size": metadata.len(),
            "readonly": metadata.permissions().readonly(),
            "atimeMs": system_time_to_millis(metadata.accessed()),
            "mtimeMs": system_time_to_millis(metadata.modified()),
            "ctimeMs": system_time_to_millis(metadata.created())
        })
        .to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_access(path: String) -> String {
    match fs::metadata(&path) {
        Ok(_) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_unlink(path: String) -> String {
    match fs::remove_file(&path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_rm(path: String, recursive: bool, force: bool) -> String {
    let target = Path::new(&path);
    if !target.exists() {
        if force {
            return json!({ "ok": true }).to_string();
        }
        return json!({ "ok": false, "code": "ENOENT", "error": "文件或目录不存在" }).to_string();
    }

    let result = if target.is_dir() {
        if recursive {
            fs::remove_dir_all(target)
        } else {
            fs::remove_dir(target)
        }
    } else {
        fs::remove_file(target)
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_rename(old_path: String, new_path: String) -> String {
    match fs::rename(&old_path, &new_path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_copy_file(src: String, dst: String) -> String {
    match fs::copy(&src, &dst) {
        Ok(bytes) => json!({ "ok": true, "bytesCopied": bytes }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_realpath(path: String) -> String {
    match fs::canonicalize(&path) {
        Ok(resolved) => {
            json!({ "ok": true, "path": resolved.to_string_lossy().to_string() }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_lstat(path: String) -> String {
    match fs::symlink_metadata(&path) {
        Ok(metadata) => json!({
            "ok": true,
            "isFile": metadata.is_file(),
            "isDirectory": metadata.is_dir(),
            "isSymbolicLink": metadata.file_type().is_symlink(),
            "size": metadata.len(),
            "readonly": metadata.permissions().readonly(),
            "atimeMs": system_time_to_millis(metadata.accessed()),
            "mtimeMs": system_time_to_millis(metadata.modified()),
            "ctimeMs": system_time_to_millis(metadata.created())
        })
        .to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_readlink(path: String) -> String {
    match fs::read_link(&path) {
        Ok(target) => {
            json!({ "ok": true, "path": target.to_string_lossy().to_string() }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

#[cfg(unix)]
fn create_symlink_impl(target: &str, path: &str, _is_dir: bool) -> io::Result<()> {
    std::os::unix::fs::symlink(target, path)
}

#[cfg(windows)]
fn create_symlink_impl(target: &str, path: &str, is_dir: bool) -> io::Result<()> {
    if is_dir {
        std::os::windows::fs::symlink_dir(target, path)
    } else {
        std::os::windows::fs::symlink_file(target, path)
    }
}

#[cfg(not(any(unix, windows)))]
fn create_symlink_impl(_target: &str, _path: &str, _is_dir: bool) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "当前平台不支持符号链接",
    ))
}

pub fn fs_symlink(target: String, path: String, is_dir: bool) -> String {
    match create_symlink_impl(&target, &path, is_dir) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_link(existing_path: String, new_path: String) -> String {
    match fs::hard_link(&existing_path, &new_path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_truncate(path: String, len: u64) -> String {
    let result = fs::OpenOptions::new()
        .write(true)
        .open(&path)
        .and_then(|file| file.set_len(len));
    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

#[cfg(unix)]
fn chmod_impl(path: &str, mode: u32) -> io::Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let perms = fs::Permissions::from_mode(mode);
    fs::set_permissions(path, perms)
}

#[cfg(windows)]
fn chmod_impl(path: &str, mode: u32) -> io::Result<()> {
    let mut perms = fs::metadata(path)?.permissions();
    perms.set_readonly((mode & 0o200) == 0);
    fs::set_permissions(path, perms)
}

#[cfg(not(any(unix, windows)))]
fn chmod_impl(_path: &str, _mode: u32) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "当前平台不支持 chmod",
    ))
}

pub fn fs_chmod(path: String, mode: u32) -> String {
    match chmod_impl(&path, mode) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_utimes(path: String, atime_millis: i64, mtime_millis: i64) -> String {
    let atime_secs = atime_millis.div_euclid(1000);
    let atime_nanos = (atime_millis.rem_euclid(1000) * 1_000_000) as u32;
    let mtime_secs = mtime_millis.div_euclid(1000);
    let mtime_nanos = (mtime_millis.rem_euclid(1000) * 1_000_000) as u32;
    let atime = FileTime::from_unix_time(atime_secs, atime_nanos);
    let mtime = FileTime::from_unix_time(mtime_secs, mtime_nanos);
    match set_file_times(&path, atime, mtime) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> io::Result<()> {
    if !dst.exists() {
        fs::create_dir_all(dst)?;
    }
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        let file_type = entry.file_type()?;
        if file_type.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else if file_type.is_file() {
            fs::copy(&src_path, &dst_path)?;
        } else if file_type.is_symlink() {
            let target = fs::read_link(&src_path)?;
            create_symlink_impl(
                &target.to_string_lossy(),
                &dst_path.to_string_lossy(),
                target.is_dir(),
            )?;
        }
    }
    Ok(())
}

pub fn fs_cp(
    src: String,
    dst: String,
    recursive: bool,
    force: bool,
    error_on_exist: bool,
) -> String {
    let src_path = Path::new(&src);
    let dst_path = Path::new(&dst);

    if !src_path.exists() {
        return json!({ "ok": false, "code": "ENOENT", "error": "源路径不存在" }).to_string();
    }

    if dst_path.exists() {
        if error_on_exist {
            return json!({ "ok": false, "code": "EEXIST", "error": "目标路径已存在" }).to_string();
        }
        if !force {
            return json!({ "ok": false, "code": "EEXIST", "error": "目标路径已存在，且未启用 force" }).to_string();
        }
    }

    let result = if src_path.is_dir() {
        if !recursive {
            Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "复制目录时必须启用 recursive",
            ))
        } else {
            copy_dir_recursive(src_path, dst_path)
        }
    } else {
        fs::copy(src_path, dst_path).map(|_| ())
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

static MKDTEMP_COUNTER: AtomicU64 = AtomicU64::new(0);

pub fn fs_mkdtemp(prefix: String) -> String {
    for _ in 0..32 {
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_else(|_| Duration::from_secs(0))
            .as_nanos();
        let seq: u64 = MKDTEMP_COUNTER.fetch_add(1, Ordering::Relaxed);
        let candidate = format!("{prefix}{ts:016x}{seq:04x}");
        let path = PathBuf::from(candidate);
        match fs::create_dir(&path) {
            Ok(()) => {
                return json!({ "ok": true, "path": path.to_string_lossy().to_string() })
                    .to_string();
            }
            Err(error) if error.kind() == io::ErrorKind::AlreadyExists => continue,
            Err(error) => return fs_error_payload(error),
        }
    }
    json!({ "ok": false, "code": "EEXIST", "error": "无法创建唯一临时目录" }).to_string()
}

#[cfg(test)]
pub fn run_async_script(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime")?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

#[cfg(test)]
pub fn run_async_script_without_wasi(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime-no-wasi")?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

#[cfg(test)]
pub fn run_async_script_with_fs(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-fs")
        .filesystem(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

#[cfg(test)]
pub fn run_async_script_with_wasi(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-wasi")
        .wasi(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

#[cfg(test)]
pub fn run_async_script_with_wasi_and_fs(
    script: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-wasi-fs")
        .wasi(true)
        .filesystem(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}
