//! Bridge 路由实现。
//!
//! 注意：crypto 相关路由只接受原始二进制数据。
//! 如果需要传入 base64 或字符串，请先在 JS 层转换为 Uint8Array：
//!   - base64: 使用全局的 bytesFromBase64(base64String)
//!   - 字符串: 使用 new TextEncoder().encode(string) 或 encodeUtf8(string)

use super::*;

pub(crate) type BridgeRouteFuture =
    Pin<Box<dyn Future<Output = AnyResult<Value>> + Send + 'static>>;
pub(crate) type BridgeRouteSyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;
pub(crate) type BridgeRouteAsyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> BridgeRouteFuture + Send + Sync + 'static>;
pub(crate) type BridgeRouteBlockingHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BridgeRouteMode {
    Sync,
    Async,
    Blocking,
}

#[derive(Debug, Clone)]
pub struct BridgeRuntimeConfig {
    pub allowed_route_prefixes: Vec<String>,
    pub max_args_json_bytes: usize,
    pub max_return_binary_bytes: usize,
}

impl Default for BridgeRuntimeConfig {
    fn default() -> Self {
        Self {
            allowed_route_prefixes: Vec::new(),
            max_args_json_bytes: BRIDGE_ARGS_JSON_MAX_BYTES_DEFAULT,
            max_return_binary_bytes: BRIDGE_RETURN_BINARY_MAX_BYTES_DEFAULT,
        }
    }
}

static BRIDGE_RUNTIME_CONFIG: OnceLock<Mutex<BridgeRuntimeConfig>> = OnceLock::new();

pub(crate) fn bridge_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    BRIDGE_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

pub fn bridge_pending_count() -> usize {
    bridge_req_pool()
        .lock()
        .map(|mut guard| {
            cleanup_stale_pending(&mut guard, &BRIDGE_STALE_DROPS);
            guard.len()
        })
        .unwrap_or_default()
}

pub fn bridge_route_mode(name: &str) -> Option<BridgeRouteMode> {
    if let Ok(handlers) = bridge_route_sync_handler_cell().lock() {
        if handlers.contains_key(name) {
            return Some(BridgeRouteMode::Sync);
        }
    }

    if let Ok(handlers) = bridge_route_async_handler_cell().lock() {
        if handlers.contains_key(name) {
            return Some(BridgeRouteMode::Async);
        }
    }

    if let Ok(handlers) = bridge_route_blocking_handler_cell().lock() {
        if handlers.contains_key(name) {
            return Some(BridgeRouteMode::Blocking);
        }
    }

    match name {
        "math.add"
        | "native.put"
        | "native.take"
        | "native.exec"
        | "compression.gzip_decompress"
        | "compression.gzip_compress" => Some(BridgeRouteMode::Sync),
        _ if bridge_crypto::is_crypto_route(name) => Some(BridgeRouteMode::Sync),
        _ => None,
    }
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

fn bridge_runtime_config_cell() -> &'static Mutex<BridgeRuntimeConfig> {
    BRIDGE_RUNTIME_CONFIG.get_or_init(|| Mutex::new(BridgeRuntimeConfig::default()))
}

pub fn configure_bridge_runtime(config: BridgeRuntimeConfig) -> AnyResult<()> {
    let mut guard = bridge_runtime_config_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-runtime-config-lock-is-poisoned")))?;
    *guard = config;
    Ok(())
}

pub fn current_bridge_runtime_config() -> BridgeRuntimeConfig {
    bridge_runtime_config_cell()
        .lock()
        .map(|guard| guard.clone())
        .unwrap_or_default()
}

fn bridge_error_value(code: &str, message: impl Into<String>, details: Option<Value>) -> Value {
    let mut obj = Map::new();
    obj.insert("code".to_string(), Value::String(code.to_string()));
    obj.insert("message".to_string(), Value::String(message.into()));
    if let Some(details) = details {
        obj.insert("details".to_string(), details);
    }
    Value::Object(obj)
}

fn bridge_error_json(code: &str, message: impl Into<String>, details: Option<Value>) -> String {
    let info = bridge_error_value(code, message, details);
    let fallback = info
        .get("message")
        .and_then(Value::as_str)
        .map(|s| s.to_string())
        .unwrap_or_else(|| crate::tr!("bridge-call-failed"));
    json!({
        "ok": false,
        "error": fallback,
        "errorInfo": info
    })
    .to_string()
}

fn is_bridge_route_allowed(name: &str) -> bool {
    if matches!(
        name,
        "math.add"
            | "native.put"
            | "native.take"
            | "native.exec"
            | "compression.gzip_decompress"
            | "compression.gzip_compress"
    ) || bridge_crypto::is_crypto_route(name)
    {
        return true;
    }

    let config = current_bridge_runtime_config();
    if config.allowed_route_prefixes.is_empty() {
        return true;
    }
    config
        .allowed_route_prefixes
        .iter()
        .any(|prefix| !prefix.is_empty() && name.starts_with(prefix))
}

fn normalize_bridge_route_name(name: impl Into<String>) -> AnyResult<String> {
    let name = name.into().trim().to_string();
    if name.is_empty() {
        return Err(anyhow!(crate::tr!("bridge-route-name-cannot-be-empty")));
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
            .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_async_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-async-route-table-lock-is-poisoned")))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_blocking_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-blocking-route-table-lock-is-poisoned")))?;
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
            .map_err(|_| anyhow!(crate::tr!("bridge-async-route-table-lock-is-poisoned")))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_sync_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_blocking_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-blocking-route-table-lock-is-poisoned")))?;
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
            .map_err(|_| anyhow!(crate::tr!("bridge-blocking-route-table-lock-is-poisoned")))?;
        handlers.insert(name.clone(), wrapped);
    }
    {
        let mut handlers = bridge_route_sync_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?;
        handlers.remove(&name);
    }
    {
        let mut handlers = bridge_route_async_handler_cell()
            .lock()
            .map_err(|_| anyhow!(crate::tr!("bridge-async-route-table-lock-is-poisoned")))?;
        handlers.remove(&name);
    }
    Ok(())
}

pub fn unregister_bridge_route_handler(name: &str) -> AnyResult<bool> {
    let mut sync_handlers = bridge_route_sync_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?;
    let mut async_handlers = bridge_route_async_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-async-route-table-lock-is-poisoned")))?;
    let mut blocking_handlers = bridge_route_blocking_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-blocking-route-table-lock-is-poisoned")))?;
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
        .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?
        .get(&name)
        .cloned()
        .ok_or_else(|| anyhow!(crate::tr!("unsupported-bridge-method", name = name)))?;
    sync_handler(runtime_name, args)
}

async fn call_registered_bridge_route(
    runtime_name: String,
    name: String,
    args: Vec<Value>,
) -> AnyResult<Value> {
    let sync_handler = bridge_route_sync_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-sync-route-table-lock-is-poisoned")))?
        .get(&name)
        .cloned();
    if let Some(sync_handler) = sync_handler {
        return sync_handler(runtime_name, args);
    }

    let async_handler = bridge_route_async_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-async-route-table-lock-is-poisoned")))?
        .get(&name)
        .cloned();
    if let Some(async_handler) = async_handler {
        return async_handler(runtime_name, args).await;
    }

    let blocking_handler = bridge_route_blocking_handler_cell()
        .lock()
        .map_err(|_| anyhow!(crate::tr!("bridge-blocking-route-table-lock-is-poisoned")))?
        .get(&name)
        .cloned();
    if let Some(blocking_handler) = blocking_handler {
        return tokio::runtime::Handle::try_current()
            .unwrap()
            .spawn_blocking(move || blocking_handler(runtime_name, args))
            .await
            .map_err(|err| {
                anyhow!(crate::tr!(
                    "bridge-blocking-route-task-join-failed",
                    err = err
                ))
            })?;
    }

    Err(anyhow!(crate::tr!(
        "unsupported-bridge-method",
        name = name
    )))
}

fn parse_host_ok_payload(raw: String) -> AnyResult<Value> {
    let payload: Value =
        serde_json::from_str(&raw).context(crate::tr!("failed-to-parse-host-return-json"))?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload)
    } else {
        Err(anyhow!(crate::tr!("call-failed")))
    }
}

fn parse_bridge_args(args_json: Option<String>) -> AnyResult<Vec<Value>> {
    let config = current_bridge_runtime_config();
    if let Some(raw) = args_json.as_ref() {
        if raw.len() > config.max_args_json_bytes {
            BRIDGE_LIMIT_HITS.fetch_add(1, Ordering::Relaxed);
            return Err(anyhow!(crate::tr!(
                "bridge-argument-too-large",
                arg0 = raw.len(),
                arg1 = config.max_args_json_bytes
            )));
        }
    }
    let Some(raw) = args_json else {
        return Ok(Vec::new());
    };
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }
    let value: Value =
        serde_json::from_str(&raw).context(crate::tr!("failed-to-parse-bridge-args-json"))?;
    let mut args = value
        .as_array()
        .cloned()
        .ok_or_else(|| anyhow!(crate::tr!("args-must-be-an-array")))?;
    for arg in &mut args {
        decode_bridge_arg_value(arg)?;
    }
    Ok(args)
}

fn decode_bridge_arg_value(value: &mut Value) -> AnyResult<()> {
    match value {
        Value::Array(items) => {
            for item in items {
                decode_bridge_arg_value(item)?;
            }
            Ok(())
        }
        Value::Object(map) => {
            if map
                .get("__hostArgKind")
                .and_then(Value::as_str)
                .map(|kind| kind == "bytes")
                .unwrap_or(false)
            {
                let id = map
                    .get("nativeBufferId")
                    .and_then(Value::as_u64)
                    .ok_or_else(|| {
                        anyhow!(crate::tr!("bridge-bytes-argument-missing-nativebufferid"))
                    })?;
                let bytes = native_buffer_take_raw(id).ok_or_else(|| {
                    anyhow!(crate::tr!(
                        "bridge-bytes-argument-nativebufferid-does-not",
                        id = id
                    ))
                })?;
                BRIDGE_BYTES_IN.fetch_add(bytes.len() as u64, Ordering::Relaxed);
                *value = Value::Array(bytes.into_iter().map(Value::from).collect());
                return Ok(());
            }
            for item in map.values_mut() {
                decode_bridge_arg_value(item)?;
            }
            Ok(())
        }
        _ => Ok(()),
    }
}

fn require_arg<'a>(args: &'a [Value], index: usize, name: &str) -> AnyResult<&'a Value> {
    args.get(index)
        .ok_or_else(|| anyhow!(crate::tr!("missing-argument", name = name)))
}

fn require_str_arg(args: &[Value], index: usize, name: &str) -> AnyResult<String> {
    require_arg(args, index, name)?
        .as_str()
        .map(ToString::to_string)
        .ok_or_else(|| anyhow!(crate::tr!("argument-must-be-a-string", name = name)))
}

fn require_u64_arg(args: &[Value], index: usize, name: &str) -> AnyResult<u64> {
    require_arg(args, index, name)?.as_u64().ok_or_else(|| {
        anyhow!(crate::tr!(
            "argument-must-be-a-non-negative-integer",
            name = name
        ))
    })
}

fn parse_u8_json_value(value: &Value) -> AnyResult<Vec<u8>> {
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!(crate::tr!("data-must-be-a-byte-array")))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let n = item
            .as_u64()
            .ok_or_else(|| anyhow!(crate::tr!("byte-array-elements-must-be-integers")))?;
        if n > 255 {
            return Err(anyhow!(crate::tr!(
                "byte-array-elements-must-be-in-the-0-255-range"
            )));
        }
        out.push(n as u8);
    }
    Ok(out)
}

fn compression_gzip_decompress(input: Vec<u8>) -> AnyResult<Value> {
    let mut decoder = GzDecoder::new(input.as_slice());
    let mut out = Vec::new();
    decoder
        .read_to_end(&mut out)
        .context(crate::tr!("gzip-decompression-failed"))?;
    Ok(json!(out))
}

fn compression_gzip_compress(input: Vec<u8>) -> AnyResult<Value> {
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder
        .write_all(&input)
        .context(crate::tr!("gzip-compression-failed"))?;
    let out = encoder
        .finish()
        .context(crate::tr!("gzip-compression-failed"))?;
    Ok(json!(out))
}

fn encode_bridge_return_value(value: Value) -> Value {
    let bytes = match parse_u8_json_value(&value) {
        Ok(v) => v,
        Err(_) => return value,
    };
    let config = current_bridge_runtime_config();
    if bytes.len() > config.max_return_binary_bytes {
        BRIDGE_LIMIT_HITS.fetch_add(1, Ordering::Relaxed);
        return bridge_error_value(
            "BRIDGE_RETURN_TOO_LARGE",
            crate::tr!(
                "bridge-return-binary-too-large",
                arg0 = bytes.len(),
                arg1 = config.max_return_binary_bytes
            ),
            Some(json!({
                "size": bytes.len(),
                "max": config.max_return_binary_bytes
            })),
        );
    }

    BRIDGE_BYTES_OUT.fetch_add(bytes.len() as u64, Ordering::Relaxed);
    let id = native_buffer_put_raw(bytes);
    json!({
        "__hostProtocol": BRIDGE_BINARY_PROTOCOL,
        "__hostReturnKind": "bytes",
        "nativeBufferId": id
    })
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
                .ok_or_else(|| anyhow!(crate::tr!("argument-a-must-be-a-number")))?;
            let b = require_arg(&args, 1, "b")?
                .as_f64()
                .ok_or_else(|| anyhow!(crate::tr!("argument-b-must-be-a-number")))?;
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
                None => Err(anyhow!(crate::tr!("buffer-id-does-not-exist"))),
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
        _ if bridge_crypto::is_crypto_route(&name) => {
            bridge_crypto::dispatch_crypto_route(&name, &args)
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
                .ok_or_else(|| anyhow!(crate::tr!("argument-a-must-be-a-number")))?;
            let b = require_arg(&args, 1, "b")?
                .as_f64()
                .ok_or_else(|| anyhow!(crate::tr!("argument-b-must-be-a-number")))?;
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
                None => Err(anyhow!(crate::tr!("buffer-id-does-not-exist"))),
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
        _ if bridge_crypto::is_crypto_route(&name) => {
            bridge_crypto::dispatch_crypto_route(&name, &args)
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
    let call_name = name.clone();
    if !is_bridge_route_allowed(&name) {
        BRIDGE_DENIED.fetch_add(1, Ordering::Relaxed);
        return bridge_error_json(
            "BRIDGE_ROUTE_DENIED",
            crate::tr!("bridge-route-rejected", name = name),
            Some(json!({ "name": name })),
        );
    }
    match bridge_call_inner(runtime_name, call_name, args_json) {
        Ok(data) => json!({ "ok": true, "data": encode_bridge_return_value(data) }).to_string(),
        Err(error) => bridge_error_json(
            "BRIDGE_CALL_FAILED",
            format!("{error:#}"),
            Some(json!({"name": name})),
        ),
    }
}

pub fn host_call_start(runtime_name: String, name: String, args_json: Option<String>) -> String {
    if !is_bridge_route_allowed(&name) {
        BRIDGE_DENIED.fetch_add(1, Ordering::Relaxed);
        return bridge_error_json(
            "BRIDGE_ROUTE_DENIED",
            crate::tr!("bridge-route-rejected", name = name),
            Some(json!({ "name": name })),
        );
    }
    {
        let mut pool = bridge_req_pool()
            .lock()
            .expect(&crate::tr!("failed-to-lock-bridge-request-pool"));
        cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
        if pool.len() >= BRIDGE_MAX_PENDING {
            return bridge_error_json(
                "BRIDGE_PENDING_FULL",
                crate::tr!("bridge-pending-queue-is-full"),
                Some(json!({"maxPending": BRIDGE_MAX_PENDING})),
            );
        }
    }

    let id = BRIDGE_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let call_name = name.clone();
    let request_label = format!("route={name}");
    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            let payload = match bridge_call_inner_async(runtime_name, call_name, args_json).await {
                Ok(data) => {
                    json!({ "ok": true, "data": encode_bridge_return_value(data) }).to_string()
                }
                Err(error) => bridge_error_json(
                    "BRIDGE_CALL_FAILED",
                    format!("{error:#}"),
                    Some(json!({"name": name})),
                ),
            };
            let _ = tx.send(payload);
        });

    {
        let mut pool = bridge_req_pool()
            .lock()
            .expect(&crate::tr!("failed-to-lock-bridge-request-pool"));
        pool.insert(
            id,
            PendingTask {
                rx,
                task,
                created_at: Instant::now(),
                meta: PendingTaskMeta {
                    kind: "bridge",
                    label: request_label,
                },
            },
        );
    }

    json!({ "ok": true, "data": { "id": id } }).to_string()
}

pub fn host_call_try_take(id: u64) -> String {
    let mut pool = bridge_req_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-bridge-request-pool"));
    cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
    let Some(pending) = pool.get_mut(&id) else {
        return json!({ "ok": false, "error": crate::tr!("request-id-does-not-exist") })
            .to_string();
    };

    match pending.rx.try_recv() {
        Ok(result) => {
            pool.remove(&id);
            json!({ "ok": true, "done": true, "result": result }).to_string()
        }
        Err(TryRecvError::Empty) => json!({ "ok": true, "done": false }).to_string(),
        Err(TryRecvError::Disconnected) => {
            pool.remove(&id);
            json!({ "ok": false, "error": crate::tr!("request-execution-thread-panicked") })
                .to_string()
        }
    }
}

pub fn host_call_drop(id: u64) -> String {
    let mut pool = bridge_req_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-bridge-request-pool"));
    let existed = if let Some(pending) = pool.remove(&id) {
        pending.task.abort();
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}
