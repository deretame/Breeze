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
        | "crypto.sha1_hex"
        | "crypto.sha512_hex"
        | "crypto.md5_hex"
        | "crypto.hmac_sha1_hex"
        | "crypto.hmac_sha512_hex"
        | "crypto.aes_ecb_pkcs7_decrypt_b64"
        | "crypto.aes_cbc_pkcs7_encrypt_b64"
        | "crypto.aes_cbc_pkcs7_decrypt_b64"
        | "crypto.aes_gcm_encrypt_b64"
        | "crypto.aes_gcm_decrypt_b64"
        | "compression.gzip_decompress"
        | "compression.gzip_compress" => Some(BridgeRouteMode::Sync),
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
            | "crypto.sha1_hex"
            | "crypto.sha512_hex"
            | "crypto.md5_hex"
            | "crypto.hmac_sha1_hex"
            | "crypto.hmac_sha512_hex"
            | "crypto.aes_ecb_pkcs7_decrypt_b64"
            | "crypto.aes_cbc_pkcs7_encrypt_b64"
            | "crypto.aes_cbc_pkcs7_decrypt_b64"
            | "crypto.aes_gcm_encrypt_b64"
            | "crypto.aes_gcm_decrypt_b64"
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
        return tokio::runtime::Handle::try_current()
            .unwrap()
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

fn crypto_sha1_hex(input: String) -> AnyResult<Value> {
    let mut hasher = Sha1::new();
    hasher.update(input.as_bytes());
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_sha512_hex(input: String) -> AnyResult<Value> {
    let mut hasher = Sha512::new();
    hasher.update(input.as_bytes());
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_hmac_sha1_hex(key: String, input: String) -> AnyResult<Value> {
    let mut mac = <Hmac<Sha1> as Mac>::new_from_slice(key.as_bytes())
        .map_err(|_| anyhow!("HMAC-SHA1 密钥无效"))?;
    mac.update(input.as_bytes());
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_hmac_sha512_hex(key: String, input: String) -> AnyResult<Value> {
    let mut mac = <Hmac<Sha512> as Mac>::new_from_slice(key.as_bytes())
        .map_err(|_| anyhow!("HMAC-SHA512 密钥无效"))?;
    mac.update(input.as_bytes());
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64: String, key_raw: String) -> AnyResult<Value> {
    let payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let plain = super::aes_ecb_decrypt_pkcs7_b64(&payload, &key)?;

    let text = String::from_utf8(plain).context("解密结果不是有效 UTF-8")?;
    Ok(json!(text))
}

fn crypto_aes_cbc_pkcs7_encrypt_b64(
    plain_b64: String,
    key_raw: String,
    iv_raw: String,
) -> AnyResult<Value> {
    let plain = BASE64_STANDARD
        .decode(plain_b64.as_bytes())
        .context("base64 解码失败")?;
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
    Ok(json!(BASE64_STANDARD.encode(out)))
}

fn crypto_aes_cbc_pkcs7_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    iv_raw: String,
) -> AnyResult<Value> {
    let mut payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
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
    Ok(json!(BASE64_STANDARD.encode(plain)))
}

fn crypto_aes_gcm_encrypt_b64(
    plain_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> AnyResult<Value> {
    let plain = BASE64_STANDARD
        .decode(plain_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let nonce = nonce_raw.into_bytes();
    let aad = aad_b64
        .map(|raw| {
            BASE64_STANDARD
                .decode(raw.as_bytes())
                .context("base64 解码失败")
        })
        .transpose()?
        .unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &plain,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 加密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
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
    Ok(json!(BASE64_STANDARD.encode(out)))
}

fn crypto_aes_gcm_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> AnyResult<Value> {
    let payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let nonce = nonce_raw.into_bytes();
    let aad = aad_b64
        .map(|raw| {
            BASE64_STANDARD
                .decode(raw.as_bytes())
                .context("base64 解码失败")
        })
        .transpose()?
        .unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &payload,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 解密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
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
    Ok(json!(BASE64_STANDARD.encode(out)))
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
        "crypto.sha1_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_sha1_hex(input)
        }
        "crypto.sha512_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_sha512_hex(input)
        }
        "crypto.hmac_sha1_hex" => {
            let key = require_str_arg(&args, 0, "key")?;
            let input = require_str_arg(&args, 1, "input")?;
            crypto_hmac_sha1_hex(key, input)
        }
        "crypto.hmac_sha512_hex" => {
            let key = require_str_arg(&args, 0, "key")?;
            let input = require_str_arg(&args, 1, "input")?;
            crypto_hmac_sha512_hex(key, input)
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64, key_raw)
        }
        "crypto.aes_cbc_pkcs7_encrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let iv_raw = require_str_arg(&args, 2, "ivRaw")?;
            crypto_aes_cbc_pkcs7_encrypt_b64(payload_b64, key_raw, iv_raw)
        }
        "crypto.aes_cbc_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let iv_raw = require_str_arg(&args, 2, "ivRaw")?;
            crypto_aes_cbc_pkcs7_decrypt_b64(payload_b64, key_raw, iv_raw)
        }
        "crypto.aes_gcm_encrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let nonce_raw = require_str_arg(&args, 2, "nonceRaw")?;
            let aad_b64 = args
                .get(3)
                .and_then(|v| v.as_str())
                .map(ToString::to_string);
            crypto_aes_gcm_encrypt_b64(payload_b64, key_raw, nonce_raw, aad_b64)
        }
        "crypto.aes_gcm_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let nonce_raw = require_str_arg(&args, 2, "nonceRaw")?;
            let aad_b64 = args
                .get(3)
                .and_then(|v| v.as_str())
                .map(ToString::to_string);
            crypto_aes_gcm_decrypt_b64(payload_b64, key_raw, nonce_raw, aad_b64)
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
        "crypto.sha1_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_sha1_hex(input)
        }
        "crypto.sha512_hex" => {
            let input = require_str_arg(&args, 0, "input")?;
            crypto_sha512_hex(input)
        }
        "crypto.hmac_sha1_hex" => {
            let key = require_str_arg(&args, 0, "key")?;
            let input = require_str_arg(&args, 1, "input")?;
            crypto_hmac_sha1_hex(key, input)
        }
        "crypto.hmac_sha512_hex" => {
            let key = require_str_arg(&args, 0, "key")?;
            let input = require_str_arg(&args, 1, "input")?;
            crypto_hmac_sha512_hex(key, input)
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64, key_raw)
        }
        "crypto.aes_cbc_pkcs7_encrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let iv_raw = require_str_arg(&args, 2, "ivRaw")?;
            crypto_aes_cbc_pkcs7_encrypt_b64(payload_b64, key_raw, iv_raw)
        }
        "crypto.aes_cbc_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let iv_raw = require_str_arg(&args, 2, "ivRaw")?;
            crypto_aes_cbc_pkcs7_decrypt_b64(payload_b64, key_raw, iv_raw)
        }
        "crypto.aes_gcm_encrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let nonce_raw = require_str_arg(&args, 2, "nonceRaw")?;
            let aad_b64 = args
                .get(3)
                .and_then(|v| v.as_str())
                .map(ToString::to_string);
            crypto_aes_gcm_encrypt_b64(payload_b64, key_raw, nonce_raw, aad_b64)
        }
        "crypto.aes_gcm_decrypt_b64" => {
            let payload_b64 = require_str_arg(&args, 0, "payloadB64")?;
            let key_raw = require_str_arg(&args, 1, "keyRaw")?;
            let nonce_raw = require_str_arg(&args, 2, "nonceRaw")?;
            let aad_b64 = args
                .get(3)
                .and_then(|v| v.as_str())
                .map(ToString::to_string);
            crypto_aes_gcm_decrypt_b64(payload_b64, key_raw, nonce_raw, aad_b64)
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
    if !is_bridge_route_allowed(&name) {
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
            return bridge_error_json(
                "BRIDGE_PENDING_FULL",
                "bridge pending 队列已满",
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
        let mut pool = bridge_req_pool().lock().expect("bridge 请求池加锁失败");
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
