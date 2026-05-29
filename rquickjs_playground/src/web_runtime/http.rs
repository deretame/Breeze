#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpClientConfig {
    pub use_http_proxy: bool,
    pub use_socks5_proxy: bool,
    pub http_proxy: Option<String>,
    pub socks5_proxy: Option<String>,
    pub disable_tls_verify: bool,
    pub allow_private_network: bool,
}

impl Default for HttpClientConfig {
    fn default() -> Self {
        Self {
            use_http_proxy: true,
            use_socks5_proxy: true,
            http_proxy: None,
            socks5_proxy: None,
            disable_tls_verify: false,
            allow_private_network: false,
        }
    }
}

pub(crate) struct HttpClientState {
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

pub(crate) fn http_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    HTTP_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

pub(crate) fn http_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    HTTP_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

pub(crate) fn http_io_sem() -> &'static Arc<Semaphore> {
    HTTP_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(HTTP_MAX_IN_FLIGHT)))
}

pub(crate) fn cleanup_stale_pending(
    pool: &mut HashMap<u64, PendingTask>,
    dropped_counter: &AtomicU64,
) {
    let now = Instant::now();
    let stale_items: Vec<(u64, PendingTaskMeta, u64)> = pool
        .iter()
        .filter_map(|(id, pending)| {
            if now.duration_since(pending.created_at) > PENDING_TASK_TTL {
                Some((
                    *id,
                    pending.meta.clone(),
                    now.duration_since(pending.created_at).as_millis() as u64,
                ))
            } else {
                None
            }
        })
        .collect();

    for (id, meta, elapsed_ms) in stale_items {
        if let Some(pending) = pool.remove(&id) {
            pending.task.abort();
            dropped_counter.fetch_add(1, Ordering::Relaxed);
            tracing::warn!(
                "cleanup stale pending task: kind={}, id={}, elapsed_ms={}, label={}",
                meta.kind,
                id,
                elapsed_ms,
                meta.label
            );
        }
    }
}

pub(crate) fn cleanup_stale_pending_abort(
    pool: &mut HashMap<u64, PendingAbortTask>,
    dropped_counter: &AtomicU64,
) {
    let now = Instant::now();
    let stale_items: Vec<(u64, PendingAbortTaskMeta, u64)> = pool
        .iter()
        .filter_map(|(id, pending)| {
            if now.duration_since(pending.created_at) > PENDING_TASK_TTL {
                Some((
                    *id,
                    pending.meta.clone(),
                    now.duration_since(pending.created_at).as_millis() as u64,
                ))
            } else {
                None
            }
        })
        .collect();

    for (id, meta, elapsed_ms) in stale_items {
        if let Some(pending) = pool.remove(&id) {
            pending.task.abort();
            dropped_counter.fetch_add(1, Ordering::Relaxed);
            tracing::warn!(
                "cleanup stale pending abort task: kind={}, id={}, elapsed_ms={}, label={}",
                meta.kind,
                id,
                elapsed_ms,
                meta.label
            );
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

pub(crate) fn decode_host_base64(raw_b64: &str) -> AnyResult<Vec<u8>> {
    let raw = raw_b64.trim();
    BASE64_STANDARD
        .decode(raw)
        .or_else(|_| BASE64_URL_SAFE.decode(raw))
        .context("base64 解码 formdata 字段失败")
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
        .map(|g| g.config.clone())
        .unwrap_or_default()
}

thread_local! {
    static WORKER_HTTP_CONFIG: std::cell::RefCell<Option<HttpClientConfig>> = const { std::cell::RefCell::new(None) };
}

pub fn set_worker_http_config(config: HttpClientConfig) {
    WORKER_HTTP_CONFIG.with(|c| *c.borrow_mut() = Some(config));
}

fn worker_http_config() -> HttpClientConfig {
    WORKER_HTTP_CONFIG.with(|c| {
        c.borrow()
            .clone()
            .unwrap_or_else(current_http_client_config)
    })
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
            state.last_system_proxy_check_at = Some(Instant::now());
        } else {
            state.system_proxy_fingerprint = None;
            state.last_system_proxy_check_at = None;
        }
    }

    Ok(state
        .client
        .clone()
        .ok_or_else(|| anyhow!("HTTP client 未初始化"))?)
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
        builder = builder.danger_accept_invalid_certs(true);
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
    let request_label = format!("method={} url={}", method, url);

    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
                Ok(Ok(permit)) => permit,
                Ok(Err(_)) => {
                    let _ = tx
                        .send(json!({ "ok": false, "error": "http 并发控制器不可用" }).to_string());
                    return;
                }
                Err(_) => {
                    let _ = tx
                        .send(json!({ "ok": false, "error": "http 等待并发许可超时" }).to_string());
                    return;
                }
            };
            let payload =
                match http_request_inner_async(method, url, headers_json, body, None).await {
                    Ok(payload) => payload,
                    Err(error) => json!({ "ok": false, "error": format!("{error:#}") }).to_string(),
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
                meta: PendingTaskMeta {
                    kind: "http",
                    label: request_label,
                },
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
    body_native_buffer_id: Option<u64>,
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
    let request_label = format!("method={} url={}", method, url);

    let task = tokio::runtime::Handle::try_current()
        .unwrap()
        .spawn(async move {
            let finish = |payload: String| {
                let should_callback = http_req_event_pool()
                    .lock()
                    .map(|mut pool| pool.remove(&id).is_some())
                    .unwrap_or(false);
                if should_callback {
                    HTTP_EVENT_COMPLETED.fetch_add(1, Ordering::Relaxed);
                    on_complete(id, payload);
                } else {
                    HTTP_EVENT_SUPPRESSED.fetch_add(1, Ordering::Relaxed);
                }
            };
            let permit = match timeout(Duration::from_secs(15), sem.acquire_owned()).await {
                Ok(Ok(permit)) => permit,
                Ok(Err(_)) => {
                    finish(json!({ "ok": false, "error": "http 并发控制器不可用" }).to_string());
                    return;
                }
                Err(_) => {
                    finish(json!({ "ok": false, "error": "http 等待并发许可超时" }).to_string());
                    return;
                }
            };
            let payload = match http_request_inner_async(
                method,
                url,
                headers_json,
                body,
                body_native_buffer_id,
            )
            .await
            {
                Ok(payload) => payload,
                Err(error) => json!({ "ok": false, "error": format!("{error:#}") }).to_string(),
            };
            drop(permit);
            finish(payload);
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
                meta: PendingAbortTaskMeta {
                    kind: "http_evented",
                    label: request_label,
                },
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
        HTTP_EVENT_CANCELED.fetch_add(1, Ordering::Relaxed);
        true
    } else {
        false
    };
    json!({ "ok": true, "dropped": existed }).to_string()
}

async fn http_request_inner_async(
    method: String,
    url: String,
    headers_json: String,
    body: Option<String>,
    body_native_buffer_id: Option<u64>,
) -> AnyResult<String> {
    let method = Method::from_bytes(method.as_bytes()).context("解析 HTTP method 失败")?;
    ensure_http_target_allowed(&url).await?;
    let mut headers_map = Map::new();
    let headers_value: Value =
        serde_json::from_str(&headers_json).context("解析 HTTP headers JSON 失败")?;
    let client = http_client()?;
    let mut offload_body_to_native = false;
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

    if formdata_body {
        let raw_plan = body.ok_or_else(|| anyhow!("formdata 请求缺少 body payload"))?;
        let plan = parse_host_formdata_plan(&raw_plan)?;
        let form = build_multipart_form(plan)?;
        builder = builder.multipart(form);
    } else if let Some(native_buffer_id) = body_native_buffer_id {
        let bytes = native_buffer_take_raw(native_buffer_id)
            .ok_or_else(|| anyhow!("request body nativeBufferId 不存在: {native_buffer_id}"))?;
        builder = builder.body(bytes);
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
        let body_bytes = response
            .bytes()
            .await
            .context("读取 HTTP 响应体字节失败")?
            .to_vec();

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
            "offloadedBytes": body_len
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

async fn ensure_http_target_allowed(url: &str) -> AnyResult<()> {
    let config = worker_http_config();
    if config.allow_private_network {
        return Ok(());
    }

    let parsed = reqwest::Url::parse(url).with_context(|| format!("解析 URL 失败: {url}"))?;
    let host = parsed
        .host_str()
        .ok_or_else(|| anyhow!("URL 缺少 host: {url}"))?
        .trim();

    if host.eq_ignore_ascii_case("localhost") || host.to_ascii_lowercase().ends_with(".localhost") {
        return Err(anyhow!("已拦截内网请求: {host}"));
    }

    if let Ok(ip) = host.parse::<IpAddr>() {
        if is_private_or_local_ip(ip) {
            return Err(anyhow!("已拦截内网请求: {host}"));
        }
        return Ok(());
    }

    let port = parsed.port_or_known_default().unwrap_or(80);
    let resolved = lookup_host((host, port))
        .await
        .with_context(|| format!("解析域名失败: {host}"))?;
    for socket in resolved {
        if is_private_or_local_ip(socket.ip()) {
            return Err(anyhow!("已拦截内网请求: {host}"));
        }
    }

    Ok(())
}

fn is_private_or_local_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(ipv4) => is_private_or_local_ipv4(ipv4),
        IpAddr::V6(ipv6) => is_private_or_local_ipv6(ipv6),
    }
}

fn is_private_or_local_ipv4(ip: Ipv4Addr) -> bool {
    let [a, b, ..] = ip.octets();
    ip.is_loopback()
        || ip.is_private()
        || ip.is_link_local()
        || ip.is_unspecified()
        || (a == 100 && (64..=127).contains(&b))
}

fn is_private_or_local_ipv6(ip: Ipv6Addr) -> bool {
    ip.is_loopback() || ip.is_unspecified() || ip.is_unique_local() || ip.is_unicast_link_local()
}
use super::*;
