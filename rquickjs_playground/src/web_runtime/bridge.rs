use super::*;
use tracing::{debug, warn};

pub(crate) type BridgeRouteFuture = Pin<Box<dyn Future<Output = AnyResult<Value>> + Send + 'static>>;
pub(crate) type BridgeRouteSyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;
pub(crate) type BridgeRouteAsyncHandler =
    Arc<dyn Fn(String, Vec<Value>) -> BridgeRouteFuture + Send + Sync + 'static>;
pub(crate) type BridgeRouteBlockingHandler =
    Arc<dyn Fn(String, Vec<Value>) -> AnyResult<Value> + Send + Sync + 'static>;

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

static BRIDGE_TRY_TAKE_COUNT: OnceLock<Mutex<HashMap<u64, u64>>> = OnceLock::new();

fn bridge_try_take_count_cell() -> &'static Mutex<HashMap<u64, u64>> {
    BRIDGE_TRY_TAKE_COUNT.get_or_init(|| Mutex::new(HashMap::new()))
}

fn bridge_runtime_config_cell() -> &'static Mutex<BridgeRuntimeConfig> {
    BRIDGE_RUNTIME_CONFIG.get_or_init(|| Mutex::new(BridgeRuntimeConfig::default()))
}

pub fn configure_bridge_runtime(config: BridgeRuntimeConfig) -> AnyResult<()> {
    let mut guard = bridge_runtime_config_cell()
        .lock()
        .map_err(|_| anyhow!("bridge 运行时配置锁已损坏"))?;
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
        .unwrap_or("bridge 调用失败")
        .to_string();
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
            | "crypto.md5_hex"
            | "crypto.aes_ecb_pkcs7_decrypt_b64"
            | "compression.gzip_decompress"
            | "compression.gzip_compress"
    ) {
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
    let config = current_bridge_runtime_config();
    if let Some(raw) = args_json.as_ref() {
        if raw.len() > config.max_args_json_bytes {
            BRIDGE_LIMIT_HITS.fetch_add(1, Ordering::Relaxed);
            return Err(anyhow!(
                "bridge 参数过大: {} > {}",
                raw.len(),
                config.max_args_json_bytes
            ));
        }
    }
    let Some(raw) = args_json else {
        return Ok(Vec::new());
    };
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }
    let value: Value = serde_json::from_str(&raw).context("解析 bridge args JSON 失败")?;
    let mut args = value
        .as_array()
        .cloned()
        .ok_or_else(|| anyhow!("args 必须是数组"))?;
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
                    .ok_or_else(|| anyhow!("bridge bytes 参数缺少 nativeBufferId"))?;
                let bytes = native_buffer_take_raw(id)
                    .ok_or_else(|| anyhow!("bridge bytes 参数 nativeBufferId 不存在: {id}"))?;
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
            .decrypt_padded::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-128 ECB 解密失败"))?
            .to_vec(),
        24 => ecb::Decryptor::<Aes192>::new_from_slice(&key)
            .map_err(|_| anyhow!("AES-192 密钥长度无效"))?
            .decrypt_padded::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-192 ECB 解密失败"))?
            .to_vec(),
        32 => ecb::Decryptor::<Aes256>::new_from_slice(&key)
            .map_err(|_| anyhow!("AES-256 密钥长度无效"))?
            .decrypt_padded::<Pkcs7>(&mut payload)
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
            format!(
                "bridge 返回二进制过大: {} > {}",
                bytes.len(),
                config.max_return_binary_bytes
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
    let call_name = name.clone();
    if !is_bridge_route_allowed(&name) {
        BRIDGE_DENIED.fetch_add(1, Ordering::Relaxed);
        return bridge_error_json(
            "BRIDGE_ROUTE_DENIED",
            format!("bridge 路由已被拒绝: {name}"),
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
    debug!(name, has_args = args_json.is_some(), "host_call_start: bridge call initiated");

    if !is_bridge_route_allowed(&name) {
        warn!(name, "host_call_start: route denied");
        BRIDGE_DENIED.fetch_add(1, Ordering::Relaxed);
        return bridge_error_json(
            "BRIDGE_ROUTE_DENIED",
            format!("bridge 路由已被拒绝: {name}"),
            Some(json!({ "name": name })),
        );
    }
    {
        let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
        cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
        if pool.len() >= BRIDGE_MAX_PENDING {
            warn!(name, pool_len = pool.len(), "host_call_start: pending queue full");
            return bridge_error_json(
                "BRIDGE_PENDING_FULL",
                "bridge pending 队列已满",
                Some(json!({"maxPending": BRIDGE_MAX_PENDING})),
            );
        }
    }

    let id = BRIDGE_REQ_ID.fetch_add(1, Ordering::Relaxed);
    let (tx, rx) = mpsc::channel::<String>();
    let log_name = name.clone();

    let sync_handler = bridge_route_sync_handler_cell()
        .lock()
        .ok()
        .and_then(|guard| guard.get(&name).cloned());

    if let Some(handler) = sync_handler {
        let args = match parse_bridge_args(args_json) {
            Ok(args) => args,
            Err(e) => {
                let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
                let payload = bridge_error_json(
                    "BRIDGE_CALL_FAILED",
                    format!("{e:#}"),
                    Some(json!({"name": log_name})),
                );
                let _ = tx.send(payload);
                pool.insert(id, PendingTask {
                    rx,
                    task: None,
                    created_at: Instant::now(),
                });
                return json!({ "ok": true, "data": { "id": id } }).to_string();
            }
        };

        let t0 = Instant::now();
        let payload = match handler(runtime_name, args) {
            Ok(data) => {
                debug!(id, "host_call_start: sync handler resolved in {:?}", t0.elapsed());
                json!({ "ok": true, "data": encode_bridge_return_value(data) }).to_string()
            }
            Err(error) => {
                warn!(id, error = %error, "host_call_start: sync handler failed in {:?}", t0.elapsed());
                bridge_error_json(
                    "BRIDGE_CALL_FAILED",
                    format!("{error:#}"),
                    Some(json!({"name": log_name})),
                )
            }
        };
        let _ = tx.send(payload);

        {
            let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
            pool.insert(id, PendingTask {
                rx,
                task: None,
                created_at: Instant::now(),
            });
        }

        debug!(id, name = log_name, "host_call_start: sync route — returning id={id}");
        return json!({ "ok": true, "data": { "id": id } }).to_string();
    }

    let call_name = name.clone();
    let err_name = name;
    let task = host_async_runtime().spawn(async move {
        let t0 = Instant::now();
        debug!(id, call_name, "host_call_start: tokio task started");
        let payload = match bridge_call_inner_async(runtime_name, call_name, args_json).await {
            Ok(data) => {
                debug!(id, "host_call_start: bridge resolved in {:?}", t0.elapsed());
                json!({ "ok": true, "data": encode_bridge_return_value(data) }).to_string()
            }
            Err(error) => {
                warn!(id, error = %error, "host_call_start: bridge failed in {:?}", t0.elapsed());
                bridge_error_json(
                    "BRIDGE_CALL_FAILED",
                    format!("{error:#}"),
                    Some(json!({"name": err_name})),
                )
            }
        };
        let _ = tx.send(payload);
    });

    {
        let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
        pool.insert(
            id,
            PendingTask {
                rx,
                task: Some(task),
                created_at: Instant::now(),
            },
        );
    }

    debug!(id, name = log_name, "host_call_start: returning id={id}");
    json!({ "ok": true, "data": { "id": id } }).to_string()
}

pub fn host_call_try_take(id: u64) -> String {
    let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
    cleanup_stale_pending(&mut pool, &BRIDGE_STALE_DROPS);
    let Some(pending) = pool.get_mut(&id) else {
        debug!(id, "host_call_try_take: request id not found");
        return json!({ "ok": false, "error": "request id 不存在" }).to_string();
    };

    match pending.rx.try_recv() {
        Ok(result) => {
            let elapsed = pending.created_at.elapsed();
            if let Ok(mut guard) = bridge_try_take_count_cell().lock() {
                if let Some(&count) = guard.get(&id) {
                    debug!(id, count, "host_call_try_take: result ready in {:?} after {} polls", elapsed, count);
                } else {
                    debug!(id, "host_call_try_take: result ready in {:?}", elapsed);
                }
                guard.remove(&id);
            }
            pool.remove(&id);
            json!({ "ok": true, "done": true, "result": result }).to_string()
        }
        Err(TryRecvError::Empty) => {
            let count = bridge_try_take_count_cell()
                .lock()
                .map(|mut guard| {
                    let c = guard.entry(id).or_insert(0);
                    *c += 1;
                    *c
                })
                .unwrap_or(0);
            let elapsed = pending.created_at.elapsed();
            if count == 1
                || count == 2
                || count == 3
                || (count <= 64 && count.is_power_of_two())
                || count % 1024 == 0
            {
                warn!(
                    id,
                    count,
                    "host_call_try_take: NOT READY after {} polls ({:?})",
                    count,
                    elapsed
                );
            }
            json!({ "ok": true, "done": false }).to_string()
        }
        Err(TryRecvError::Disconnected) => {
            if let Ok(mut guard) = bridge_try_take_count_cell().lock() {
                guard.remove(&id);
            }
            warn!(id, "host_call_try_take: channel disconnected — task crashed");
            pool.remove(&id);
            json!({ "ok": false, "error": "request 执行线程异常退出" }).to_string()
        }
    }
}

pub fn host_call_drop(id: u64) -> String {
    let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
    let existed = if let Some(pending) = pool.remove(&id) {
        if let Some(task) = pending.task {
            task.abort();
        }
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}
