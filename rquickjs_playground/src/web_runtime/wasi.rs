#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[cfg_attr(not(feature = "wasi"), allow(dead_code))]
pub(crate) struct WasiTransformPlan {
    pub(crate) module_id: u64,
    pub(crate) function: Option<String>,
    pub(crate) args: Option<Value>,
    pub(crate) js_process: Option<bool>,
    pub(crate) output_type: String,
}

#[cfg(feature = "wasi")]
pub(crate) fn wasi_req_pool() -> &'static Mutex<HashMap<u64, PendingTask>> {
    WASI_REQ_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(feature = "wasi")]
pub(crate) fn wasi_req_event_pool() -> &'static Mutex<HashMap<u64, PendingAbortTask>> {
    WASI_REQ_EVENT_POOL.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(feature = "wasi")]
fn wasi_engine() -> &'static Engine {
    WASI_ENGINE.get_or_init(Engine::default)
}

#[cfg(feature = "wasi")]
pub(crate) fn wasi_module_cache() -> &'static Mutex<HashMap<Vec<u8>, Module>> {
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

#[cfg(feature = "wasi")]
pub(crate) fn wasi_io_sem() -> &'static Arc<Semaphore> {
    WASI_IO_SEM.get_or_init(|| Arc::new(Semaphore::new(WASI_MAX_IN_FLIGHT)))
}

#[cfg(feature = "wasi")]
pub(crate) fn parse_wasi_transform_plan(raw_b64: &str) -> AnyResult<WasiTransformPlan> {
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
pub(crate) fn parse_wasi_transform_plan(_raw_b64: &str) -> AnyResult<WasiTransformPlan> {
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
pub(crate) async fn run_wasi_transform_once(
    plan: &WasiTransformPlan,
    input: Vec<u8>,
) -> AnyResult<Vec<u8>> {
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
pub(crate) async fn run_wasi_transform_once(
    _plan: &WasiTransformPlan,
    _input: Vec<u8>,
) -> AnyResult<Vec<u8>> {
    Err(anyhow!("当前构建未启用 wasi Cargo 特性"))
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
                task: Some(task),
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
        if let Some(task) = pending.task {
            task.abort();
        }
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
use super::*;
