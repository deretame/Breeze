use rquickjs::{Context, Function, Runtime, function::Func};
use serde::de::DeserializeOwned;
use serde_json::Value;
use std::collections::HashMap;
use std::future::IntoFuture;
use std::marker::PhantomData;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::mpsc;
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use tokio::sync::OwnedMutexGuard;
use tokio::sync::oneshot;

use crate::web_runtime::{
    WebRuntimeOptions, http_request_drop_evented, http_request_start_evented,
    install_host_bindings, polyfill_script, timer_drop_evented, timer_start_evented,
    wasi_run_drop_evented, wasi_run_start_evented,
};

#[cfg(feature = "host-fs")]
use crate::web_runtime::{fs_task_drop_evented, fs_task_start_evented};

const ASYNC_TASK_DISPATCHER_JS: &str = r#"(function () {
  globalThis.__host_runtime_dispatch_task = function (__runtimeId, __taskId, __source) {
    let __value;
    try {
      __value = (0, eval)(__source);
    } catch (err) {
      let __msg;
      try {
        const __message = String(err && err.message ? err.message : err || "task eval error");
        const __stack = String(err && err.stack ? err.stack : "");
        __msg = __stack ? `${__message}\n${__stack}` : __message;
      } catch (_err) {
        __msg = "task eval error";
      }
      globalThis.__host_runtime_task_complete(__runtimeId, __taskId, false, __msg);
      return;
    }

    Promise.resolve(__value).then(
      (result) => {
        let __out;
        if (typeof result === "string") {
          __out = result;
        } else if (result === undefined) {
          __out = "undefined";
        } else {
          try {
            __out = JSON.stringify(result);
            if (__out === undefined) __out = String(result);
          } catch (_err) {
            __out = String(result);
          }
        }
        globalThis.__host_runtime_task_complete(__runtimeId, __taskId, true, __out);
      },
      (err) => {
        let __msg;
        try {
          const __message = String(err && err.message ? err.message : err || "task rejected");
          const __stack = String(err && err.stack ? err.stack : "");
          __msg = __stack ? `${__message}\n${__stack}` : __message;
        } catch (_err) {
          __msg = "task rejected";
        }
        globalThis.__host_runtime_task_complete(__runtimeId, __taskId, false, __msg);
      }
    );
  };
})();"#;

const BUNDLE_DISPATCHER_JS: &str = r#"(async () => {
  try {
    if (globalThis.__host_bundle_runtime && typeof globalThis.__host_bundle_runtime.invoke === "function") {
      return JSON.stringify({ ok: true, data: null });
    }

    const REGISTRY_KEY = "__host_bundle_registry";

    const ensureRegistry = () => {
      let registry = globalThis[REGISTRY_KEY];
      if (!(registry instanceof Map)) {
        registry = new Map();
        globalThis[REGISTRY_KEY] = registry;
      }
      return registry;
    };

    const normalizeApi = (api) => {
      let out = api;
      if (out && typeof out === "object" && out.default !== undefined) {
        out = out.default;
      }
      if (!out || (typeof out !== "object" && typeof out !== "function")) {
        throw new TypeError("bundle must export object or function");
      }
      return out;
    };

    const isSafeKey = (k) => k !== "__proto__" && k !== "prototype" && k !== "constructor";

    const resolveCallable = (api, fnPath) => {
      const parts = String(fnPath).split(".").filter(Boolean);
      if (parts.length === 0) {
        throw new TypeError("function path is empty");
      }

      let owner = api;
      for (let i = 0; i < parts.length - 1; i++) {
        const key = parts[i];
        if (!isSafeKey(key)) throw new TypeError(`unsafe path segment: ${key}`);
        owner = owner?.[key];
        if (owner === undefined || owner === null) {
          throw new Error(`function path not found: ${fnPath}`);
        }
      }

      const leaf = parts[parts.length - 1];
      if (!isSafeKey(leaf)) throw new TypeError(`unsafe path segment: ${leaf}`);
      const fn = owner?.[leaf];
      if (typeof fn !== "function") {
        throw new TypeError(`target is not function: ${fnPath}`);
      }

      return { owner, fn };
    };

    globalThis.__host_bundle_runtime = {
      loadBundle(name, source) {
        const registry = ensureRegistry();
        const module = { exports: {} };
        const exports = module.exports;
        const requireFn = typeof require === "function" ? require.bind(globalThis) : undefined;
        const runner = new Function("module", "exports", "require", source);
        runner(module, exports, requireFn);
        registry.set(String(name), normalizeApi(module.exports));
      },
      async invoke(payload) {
        const registry = ensureRegistry();
        const name = String(payload?.name || "");
        const fnPath = String(payload?.fnPath || "");
        const args = Array.isArray(payload?.args) ? payload.args : [];

        const api = registry.get(name);
        if (!api) {
          throw new Error(`bundle not found: ${name}`);
        }

        const { owner, fn } = resolveCallable(api, fnPath);
        return await fn.apply(owner, args);
      },
      unloadBundle(name) {
        const registry = ensureRegistry();
        return registry.delete(String(name));
      },
      clearBundles() {
        const registry = ensureRegistry();
        const count = registry.size;
        registry.clear();
        return count;
      },
      listBundles() {
        const registry = ensureRegistry();
        return Array.from(registry.keys()).map((v) => String(v));
      },
      async callOnce(payload) {
        const source = String(payload?.source || "");
        const fnPath = String(payload?.fnPath || "");
        const args = Array.isArray(payload?.args) ? payload.args : [];

        const module = { exports: {} };
        const exports = module.exports;
        const requireFn = typeof require === "function" ? require.bind(globalThis) : undefined;
        const runner = new Function("module", "exports", "require", source);
        runner(module, exports, requireFn);

        const api = normalizeApi(module.exports);
        const { owner, fn } = resolveCallable(api, fnPath);
        return await fn.apply(owner, args);
      },
    };

    return JSON.stringify({ ok: true, data: null });
  } catch (err) {
    const base = String(err && err.message ? err.message : err || "执行失败");
    const stack = String(err && err.stack ? err.stack : "");
    const message = stack ? `${base}\n${stack}` : base;
    return JSON.stringify({ ok: false, error: message });
  }
})()"#;

pub struct HostRuntime {
    runtime: Runtime,
    context: Context,
    cache_scope_id: String,
    options: WebRuntimeOptions,
}

#[derive(Debug, Clone)]
pub struct RuntimeTaskStats {
    pub pending: usize,
    pub running: usize,
    pub done: usize,
    pub dropped: usize,
}

pub struct AsyncHostRuntime {
    runtime_id: u64,
    cache_scope_id: String,
    options: WebRuntimeOptions,
    tx: mpsc::Sender<WorkerSignal>,
    states: Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    bundle_call_once_lock: Arc<tokio::sync::Mutex<()>>,
    next_id: AtomicU64,
}

pub struct AsyncHostRuntimeBuilder {
    cache_scope_id: String,
    options: WebRuntimeOptions,
}

impl AsyncHostRuntimeBuilder {
    pub fn new(cache_scope_id: impl Into<String>) -> Self {
        Self {
            cache_scope_id: cache_scope_id.into(),
            options: WebRuntimeOptions::default(),
        }
    }

    pub fn with_options(mut self, options: WebRuntimeOptions) -> Self {
        self.options = options;
        self
    }

    pub fn filesystem(mut self, enabled: bool) -> Self {
        self.options.fs = enabled;
        self
    }

    pub fn wasi(mut self, enabled: bool) -> Self {
        self.options.wasi = enabled;
        self
    }

    pub fn build(self) -> Result<AsyncHostRuntime, String> {
        AsyncHostRuntime::build_inner(self.cache_scope_id, self.options)
    }
}

pub struct RuntimeTaskHandle {
    id: u64,
    rx: Option<oneshot::Receiver<Result<String, String>>>,
    states: Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    tx: mpsc::Sender<WorkerSignal>,
    drop_cleanup: bool,
    bundle_call_once_guard: Option<OwnedMutexGuard<()>>,
}

pub struct RuntimeJsonTaskHandle<T> {
    inner: RuntimeTaskHandle,
    _marker: PhantomData<T>,
}

enum AsyncCommand {
    Submit {
        id: u64,
        script: String,
    },
    Drop {
        id: u64,
    },
    DropMany {
        ids: Vec<u64>,
    },
    RunGc {
        tx: oneshot::Sender<Result<(), String>>,
    },
    Shutdown,
}

enum HostEvent {
    HttpCompleted {
        id: u64,
        payload: String,
    },
    #[cfg(feature = "host-fs")]
    FsCompleted {
        id: u64,
        payload: String,
    },
    WasiCompleted {
        id: u64,
        payload: String,
    },
    TimerCompleted {
        id: u64,
        payload: String,
    },
}

enum WorkerSignal {
    Command(AsyncCommand),
    HostEvent(HostEvent),
}

#[derive(Debug, Clone)]
enum TaskState {
    Pending,
    Running,
    Done(Result<String, String>),
    Dropped,
}

static ASYNC_RUNTIME_ID: AtomicU64 = AtomicU64::new(1);
static ASYNC_RUNTIME_SHARED: OnceLock<Mutex<HashMap<u64, Arc<RuntimeShared>>>> = OnceLock::new();
static JS_ERROR_INCLUDE_STACK: AtomicBool = AtomicBool::new(true);

pub fn configure_js_error_stack(include_stack: bool) {
    JS_ERROR_INCLUDE_STACK.store(include_stack, Ordering::Relaxed);
}

pub fn js_error_stack_enabled() -> bool {
    JS_ERROR_INCLUDE_STACK.load(Ordering::Relaxed)
}

struct RuntimeShared {
    states: Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
}

impl HostRuntime {
    pub fn new(cache_scope_id: String) -> Result<Self, rquickjs::Error> {
        Self::new_with_options(cache_scope_id, WebRuntimeOptions::default())
    }

    pub fn new_with_options(
        cache_scope_id: String,
        options: WebRuntimeOptions,
    ) -> Result<Self, rquickjs::Error> {
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
        let runtime = Runtime::new()?;
        let context = Context::full(&runtime)?;
        let polyfill = polyfill_script(options);

        context.with(|ctx| {
            install_host_bindings(&ctx, &cache_scope_id, options)?;
            ctx.eval::<(), _>(polyfill.as_str())?;
            Ok::<(), rquickjs::Error>(())
        })?;

        Ok(Self {
            runtime,
            context,
            cache_scope_id,
            options,
        })
    }

    pub fn submit_async_task(
        &self,
        runtime_id: u64,
        task_id: u64,
        script: &str,
    ) -> Result<(), String> {
        self.context
            .with(|ctx| {
                let globals = ctx.globals();
                let dispatch: Function = globals.get("__host_runtime_dispatch_task")?;
                dispatch.call::<_, ()>((runtime_id, task_id, script))
            })
            .map_err(|e| format!("任务提交到 JS 失败: {e}"))
    }

    pub fn pump_jobs(&self, max_jobs: usize) -> Result<usize, String> {
        let mut executed = 0usize;
        while executed < max_jobs && self.runtime.is_job_pending() {
            match self.runtime.execute_pending_job() {
                Ok(true) => executed += 1,
                Ok(false) => break,
                Err(err) => return Err(format!("执行 JS event loop job 失败: {err}")),
            }
        }
        Ok(executed)
    }

    pub fn with_context<R>(
        &self,
        f: impl for<'js> FnOnce(rquickjs::Ctx<'js>) -> Result<R, rquickjs::Error>,
    ) -> Result<R, rquickjs::Error> {
        self.context.with(f)
    }

    pub fn cache_scope_id(&self) -> &str {
        &self.cache_scope_id
    }

    pub fn options(&self) -> WebRuntimeOptions {
        self.options
    }

    pub fn run_gc(&self) {
        self.runtime.run_gc();
    }
}

impl AsyncHostRuntime {
    pub fn builder(cache_scope_id: impl Into<String>) -> AsyncHostRuntimeBuilder {
        AsyncHostRuntimeBuilder::new(cache_scope_id)
    }

    pub fn new(cache_scope_id: impl Into<String>) -> Result<Self, String> {
        Self::builder(cache_scope_id).build()
    }

    pub fn new_with_options(
        cache_scope_id: impl Into<String>,
        options: WebRuntimeOptions,
    ) -> Result<Self, String> {
        Self::builder(cache_scope_id).with_options(options).build()
    }

    fn build_inner(cache_scope_id: String, options: WebRuntimeOptions) -> Result<Self, String> {
        if options.wasi && !cfg!(feature = "wasi") {
            return Err("当前构建未启用 wasi Cargo 特性".to_string());
        }
        if options.fs && !cfg!(feature = "host-fs") {
            return Err("当前构建未启用 host-fs Cargo 特性".to_string());
        }
        let cache_scope_id_for_worker = cache_scope_id.clone();
        let options_for_worker = options;
        let (tx, rx) = mpsc::channel::<WorkerSignal>();
        let tx_for_worker = tx.clone();
        let states = Arc::new(Mutex::new(HashMap::<u64, TaskState>::new()));
        let states_for_worker = Arc::clone(&states);
        let waiters = Arc::new(Mutex::new(HashMap::<
            u64,
            oneshot::Sender<Result<String, String>>,
        >::new()));
        let waiters_for_worker = Arc::clone(&waiters);
        let runtime_id = ASYNC_RUNTIME_ID.fetch_add(1, Ordering::SeqCst);
        register_runtime_shared(
            runtime_id,
            Arc::new(RuntimeShared {
                states: Arc::clone(&states),
                waiters: Arc::clone(&waiters),
            }),
        );
        let (init_tx, init_rx) = mpsc::channel::<Result<(), String>>();

        thread::spawn(move || {
            let host = match HostRuntime::new_with_options(
                cache_scope_id_for_worker,
                options_for_worker,
            ) {
                Ok(host) => host,
                Err(err) => {
                    let _ = init_tx.send(Err(format!("初始化 HostRuntime 失败: {err}")));
                    return;
                }
            };

            if let Err(err) = install_async_runtime_bindings(&host, tx_for_worker.clone()) {
                let _ = init_tx.send(Err(err));
                return;
            }

            let _ = init_tx.send(Ok(()));

            let mut running = true;
            while running {
                loop {
                    match rx.try_recv() {
                        Ok(signal) => {
                            running = handle_worker_signal(
                                signal,
                                &host,
                                runtime_id,
                                &states_for_worker,
                                &waiters_for_worker,
                            );
                            if !running {
                                break;
                            }
                        }
                        Err(mpsc::TryRecvError::Empty) => break,
                        Err(mpsc::TryRecvError::Disconnected) => {
                            running = false;
                            break;
                        }
                    }
                }

                if !running {
                    break;
                }

                match host.pump_jobs(2048) {
                    Ok(jobs) if jobs > 0 => continue,
                    Ok(_) => {}
                    Err(err) => {
                        fail_all_active_tasks(&states_for_worker, &waiters_for_worker, err);
                        break;
                    }
                }

                if !running {
                    break;
                }

                match rx.recv() {
                    Ok(signal) => {
                        running = handle_worker_signal(
                            signal,
                            &host,
                            runtime_id,
                            &states_for_worker,
                            &waiters_for_worker,
                        );
                    }
                    Err(_) => break,
                }
            }
        });

        match init_rx.recv() {
            Ok(Ok(())) => Ok(Self {
                runtime_id,
                cache_scope_id,
                options,
                tx,
                states,
                waiters,
                bundle_call_once_lock: Arc::new(tokio::sync::Mutex::new(())),
                next_id: AtomicU64::new(1),
            }),
            Ok(Err(err)) => {
                unregister_runtime_shared(runtime_id);
                Err(err)
            }
            Err(_) => {
                unregister_runtime_shared(runtime_id);
                Err("初始化 HostRuntime 失败: worker 提前退出".to_string())
            }
        }
    }

    pub fn spawn(&self, script: impl Into<String>) -> Result<RuntimeTaskHandle, String> {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst);
        let (result_tx, result_rx) = oneshot::channel::<Result<String, String>>();

        {
            let mut guard = self
                .states
                .lock()
                .map_err(|_| "提交任务失败: 状态锁已损坏".to_string())?;
            guard.insert(id, TaskState::Pending);
        }

        {
            let mut guard = self
                .waiters
                .lock()
                .map_err(|_| "提交任务失败: 等待器锁已损坏".to_string())?;
            guard.insert(id, result_tx);
        }

        if self
            .tx
            .send(WorkerSignal::Command(AsyncCommand::Submit {
                id,
                script: script.into(),
            }))
            .is_err()
        {
            if let Ok(mut guard) = self.states.lock() {
                guard.remove(&id);
            }
            if let Ok(mut guard) = self.waiters.lock() {
                guard.remove(&id);
            }
            return Err("提交任务失败: worker 不可用".to_string());
        }

        Ok(RuntimeTaskHandle {
            id,
            rx: Some(result_rx),
            states: Arc::clone(&self.states),
            waiters: Arc::clone(&self.waiters),
            tx: self.tx.clone(),
            drop_cleanup: true,
            bundle_call_once_guard: None,
        })
    }

    pub fn spawn_json<T>(
        &self,
        script: impl Into<String>,
    ) -> Result<RuntimeJsonTaskHandle<T>, String>
    where
        T: DeserializeOwned + Send + 'static,
    {
        let inner = self.spawn(script)?;
        Ok(RuntimeJsonTaskHandle {
            inner,
            _marker: PhantomData,
        })
    }

    pub fn cancel(&self, id: u64) -> bool {
        if self
            .tx
            .send(WorkerSignal::Command(AsyncCommand::Drop { id }))
            .is_err()
        {
            return false;
        }
        true
    }

    pub fn cancel_many(&self, ids: Vec<u64>) -> bool {
        if ids.is_empty() {
            return true;
        }

        if self
            .tx
            .send(WorkerSignal::Command(AsyncCommand::DropMany { ids }))
            .is_err()
        {
            return false;
        }
        true
    }

    pub fn stats(&self) -> RuntimeTaskStats {
        let Ok(guard) = self.states.lock() else {
            return RuntimeTaskStats {
                pending: 0,
                running: 0,
                done: 0,
                dropped: 0,
            };
        };

        let mut pending = 0usize;
        let mut running = 0usize;
        let mut done = 0usize;
        let mut dropped = 0usize;

        for state in guard.values() {
            match state {
                TaskState::Pending => pending += 1,
                TaskState::Running => running += 1,
                TaskState::Done(_) => done += 1,
                TaskState::Dropped => dropped += 1,
            }
        }

        RuntimeTaskStats {
            pending,
            running,
            done,
            dropped,
        }
    }

    pub fn cache_scope_id(&self) -> &str {
        &self.cache_scope_id
    }

    pub fn options(&self) -> WebRuntimeOptions {
        self.options
    }

    pub async fn run_gc(&self) -> Result<(), String> {
        let (tx, rx) = oneshot::channel::<Result<(), String>>();
        self.tx
            .send(WorkerSignal::Command(AsyncCommand::RunGc { tx }))
            .map_err(|_| "触发 GC 失败: worker 不可用".to_string())?;
        rx.await
            .map_err(|_| "触发 GC 失败: worker 已关闭".to_string())?
    }

    pub async fn bundle_load(&self, name: &str, source: &str) -> Result<(), String> {
        self.bundle_ensure_dispatcher().await?;
        let name_literal =
            serde_json::to_string(name).map_err(|e| format!("序列化 bundle 名称失败: {e}"))?;
        let source_literal =
            serde_json::to_string(source).map_err(|e| format!("序列化 bundle 脚本失败: {e}"))?;

        let script = format!(
            r#"
            (async () => {{
              try {{
                const host = globalThis.__host_bundle_runtime;
                if (!host || typeof host.loadBundle !== "function") {{
                  throw new Error("bundle dispatcher unavailable");
                }}
                host.loadBundle({name_literal}, {source_literal});
                return JSON.stringify({{ ok: true, data: null }});
              }} catch (err) {{
                const base = String(err && err.message ? err.message : err || "执行失败");
                const stack = String(err && err.stack ? err.stack : "");
                const message = stack ? `${{base}}\n${{stack}}` : base;
                return JSON.stringify({{ ok: false, error: message }});
              }}
            }})()
            "#
        );

        let raw = self
            .spawn(script)
            .map_err(|e| format!("加载 bundle 失败: {e}"))?
            .wait_async()
            .await
            .map_err(|e| format!("加载 bundle 失败: {e}"))?;
        let _ = parse_ok_json_payload(&raw)?;
        Ok(())
    }

    pub async fn bundle_call(
        &self,
        name: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Value, String> {
        let raw = self
            .bundle_call_start(name, fn_path, args)
            .await?
            .wait_async()
            .await
            .map_err(|e| format!("执行 bundle 函数失败: {e}"))?;
        parse_ok_json_payload(&raw)
    }

    pub async fn bundle_call_start(
        &self,
        name: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<RuntimeTaskHandle, String> {
        self.bundle_ensure_dispatcher().await?;
        if !args.is_array() {
            return Err("调用参数必须是 JSON 数组".to_string());
        }

        let script = build_bundle_call_script(name, fn_path, args)?;
        self.spawn(script)
            .map_err(|e| format!("提交 bundle 调用任务失败: {e}"))
    }

    pub async fn bundle_call_once(
        &self,
        source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Value, String> {
        let raw = self
            .bundle_call_once_start(source, fn_path, args)
            .await?
            .wait_async()
            .await
            .map_err(|e| format!("执行一次性 bundle 调用失败: {e}"))?;
        parse_ok_json_payload(&raw)
    }

    pub async fn bundle_call_once_start(
        &self,
        source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<RuntimeTaskHandle, String> {
        let once_guard = self.bundle_call_once_lock.clone().lock_owned().await;
        self.bundle_ensure_dispatcher().await?;
        if !args.is_array() {
            return Err("调用参数必须是 JSON 数组".to_string());
        }

        let script = build_bundle_call_once_script(source, fn_path, args)?;
        let mut handle = self
            .spawn(script)
            .map_err(|e| format!("执行一次性 bundle 调用失败: {e}"))?;
        handle.bundle_call_once_guard = Some(once_guard);
        Ok(handle)
    }

    pub async fn bundle_unload(&self, name: &str) -> Result<bool, String> {
        self.bundle_ensure_dispatcher().await?;
        let name_literal =
            serde_json::to_string(name).map_err(|e| format!("序列化 bundle 名称失败: {e}"))?;

        let script = format!(
            r#"
            (async () => {{
              try {{
                const host = globalThis.__host_bundle_runtime;
                if (!host || typeof host.unloadBundle !== "function") {{
                  throw new Error("bundle dispatcher unavailable");
                }}
                const removed = host.unloadBundle({name_literal});
                return JSON.stringify({{ ok: true, data: removed }});
              }} catch (err) {{
                const base = String(err && err.message ? err.message : err || "执行失败");
                const stack = String(err && err.stack ? err.stack : "");
                const message = stack ? `${{base}}\n${{stack}}` : base;
                return JSON.stringify({{ ok: false, error: message }});
              }}
            }})()
            "#
        );

        let raw = self
            .spawn(script)
            .map_err(|e| format!("卸载 bundle 失败: {e}"))?
            .wait_async()
            .await
            .map_err(|e| format!("卸载 bundle 失败: {e}"))?;
        let data = parse_ok_json_payload(&raw)?;
        Ok(data.as_bool().unwrap_or(false))
    }

    pub async fn bundle_list(&self) -> Result<Vec<String>, String> {
        self.bundle_ensure_dispatcher().await?;
        let script = r#"
            (async () => {
              try {
                const host = globalThis.__host_bundle_runtime;
                if (!host || typeof host.listBundles !== "function") {
                  throw new Error("bundle dispatcher unavailable");
                }
                const names = host.listBundles();
                return JSON.stringify({ ok: true, data: names });
              } catch (err) {
                const base = String(err && err.message ? err.message : err || "执行失败");
                const stack = String(err && err.stack ? err.stack : "");
                const message = stack ? `${base}\n${stack}` : base;
                return JSON.stringify({ ok: false, error: message });
              }
            })()
        "#;

        let raw = self
            .spawn(script)
            .map_err(|e| format!("读取 bundle 列表失败: {e}"))?
            .wait_async()
            .await
            .map_err(|e| format!("读取 bundle 列表失败: {e}"))?;
        let data = parse_ok_json_payload(&raw)?;
        let arr = data
            .as_array()
            .ok_or_else(|| "读取 bundle 列表失败: 返回值不是数组".to_string())?;
        Ok(arr
            .iter()
            .map(|v| v.as_str().unwrap_or_default().to_string())
            .collect())
    }

    async fn bundle_ensure_dispatcher(&self) -> Result<(), String> {
        let raw = self
            .spawn(BUNDLE_DISPATCHER_JS)
            .map_err(|e| format!("初始化 bundle dispatcher 失败: {e}"))?
            .wait_async()
            .await
            .map_err(|e| format!("初始化 bundle dispatcher 失败: {e}"))?;
        let _ = parse_ok_json_payload(&raw)?;
        Ok(())
    }
}

impl Drop for AsyncHostRuntime {
    fn drop(&mut self) {
        fail_all_active_tasks(
            &self.states,
            &self.waiters,
            "等待任务结果失败: runtime 已关闭".to_string(),
        );
        let _ = self.tx.send(WorkerSignal::Command(AsyncCommand::Shutdown));
        unregister_runtime_shared(self.runtime_id);
    }
}

impl RuntimeTaskHandle {
    pub fn id(&self) -> u64 {
        self.id
    }

    pub fn wait(mut self) -> Result<String, String> {
        let Some(rx) = self.rx.take() else {
            self.drop_cleanup = false;
            clear_task_state(&self.states, self.id);
            return Err("等待任务结果失败: 任务句柄已失效".to_string());
        };

        let out = match rx.blocking_recv() {
            Ok(result) => {
                clear_task_state(&self.states, self.id);
                result
            }
            Err(_) => {
                clear_task_state(&self.states, self.id);
                Err("等待任务结果失败: runtime 已关闭".to_string())
            }
        };

        self.drop_cleanup = false;
        out
    }

    pub async fn wait_async(mut self) -> Result<String, String> {
        let Some(rx) = self.rx.take() else {
            self.drop_cleanup = false;
            clear_task_state(&self.states, self.id);
            return Err("等待任务结果失败: 任务句柄已失效".to_string());
        };

        let out = match rx.await {
            Ok(result) => {
                clear_task_state(&self.states, self.id);
                result
            }
            Err(_) => {
                clear_task_state(&self.states, self.id);
                Err("等待任务结果失败: runtime 已关闭".to_string())
            }
        };

        self.drop_cleanup = false;
        out
    }
}

impl Drop for RuntimeTaskHandle {
    fn drop(&mut self) {
        if !self.drop_cleanup {
            return;
        }

        remove_waiter(&self.waiters, self.id);

        if is_task_active(&self.states, self.id) {
            if self
                .tx
                .send(WorkerSignal::Command(AsyncCommand::Drop { id: self.id }))
                .is_err()
            {
                clear_task_state(&self.states, self.id);
            }
        } else {
            clear_task_state(&self.states, self.id);
        }
    }
}

impl IntoFuture for RuntimeTaskHandle {
    type Output = Result<String, String>;
    type IntoFuture =
        std::pin::Pin<Box<dyn std::future::Future<Output = Result<String, String>> + Send>>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move { self.wait_async().await })
    }
}

impl<T> RuntimeJsonTaskHandle<T>
where
    T: DeserializeOwned + Send + 'static,
{
    pub fn id(&self) -> u64 {
        self.inner.id()
    }

    pub fn wait(self) -> Result<T, String> {
        parse_json_payload(self.inner.wait())
    }

    pub async fn wait_async(self) -> Result<T, String> {
        parse_json_payload(self.inner.wait_async().await)
    }
}

impl<T> IntoFuture for RuntimeJsonTaskHandle<T>
where
    T: DeserializeOwned + Send + 'static,
{
    type Output = Result<T, String>;
    type IntoFuture =
        std::pin::Pin<Box<dyn std::future::Future<Output = Result<T, String>> + Send>>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move { self.wait_async().await })
    }
}

fn parse_json_payload<T>(raw: Result<String, String>) -> Result<T, String>
where
    T: DeserializeOwned,
{
    match raw {
        Ok(payload) => serde_json::from_str(&payload)
            .map_err(|e| format!("解析 JSON 任务结果失败: {e}; payload={payload}")),
        Err(err) => Err(err),
    }
}

fn build_bundle_call_once_script(
    source: &str,
    fn_path: &str,
    args: &Value,
) -> Result<String, String> {
    let source_literal =
        serde_json::to_string(source).map_err(|e| format!("序列化 bundle 脚本失败: {e}"))?;
    let fn_path_literal =
        serde_json::to_string(fn_path).map_err(|e| format!("序列化函数路径失败: {e}"))?;
    let args_literal =
        serde_json::to_string(args).map_err(|e| format!("序列化调用参数失败: {e}"))?;

    Ok(format!(
        r#"
        (async () => {{
          const clearBundles = () => {{
            const host = globalThis.__host_bundle_runtime;
            if (!host) {{
              throw new Error("bundle dispatcher unavailable");
            }}

            if (typeof host.clearBundles === "function") {{
              host.clearBundles();
              return;
            }}

            if (typeof host.listBundles === "function" && typeof host.unloadBundle === "function") {{
              const names = host.listBundles();
              for (const name of names) host.unloadBundle(name);
              return;
            }}

            throw new Error("bundle clear unavailable");
          }};

          try {{
            const host = globalThis.__host_bundle_runtime;
            if (!host || typeof host.callOnce !== "function") {{
              throw new Error("bundle dispatcher unavailable");
            }}
            clearBundles();
            const data = await host.callOnce({{ source: {source_literal}, fnPath: {fn_path_literal}, args: {args_literal} }});
            return JSON.stringify({{ ok: true, data }});
          }} catch (err) {{
            const base = String(err && err.message ? err.message : err || "执行失败");
            const stack = String(err && err.stack ? err.stack : "");
            const message = stack ? `${{base}}\n${{stack}}` : base;
            return JSON.stringify({{ ok: false, error: message }});
          }} finally {{
            try {{
              clearBundles();
            }} catch (_err) {{}}
          }}
        }})()
        "#
    ))
}

fn parse_ok_json_payload(raw: &str) -> Result<Value, String> {
    let payload: Value =
        serde_json::from_str(raw).map_err(|e| format!("解析 JS 返回 JSON 失败: {e}"))?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        let raw_error = payload
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("执行失败");
        Err(format_js_error(raw_error))
    }
}

fn format_js_error(raw: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return "执行失败".to_string();
    }

    if js_error_stack_enabled() {
        return trimmed.to_string();
    }

    for line in trimmed.lines() {
        let text = line.trim();
        if text.is_empty() {
            continue;
        }
        if !text.starts_with("at ") {
            return text.to_string();
        }
    }

    trimmed.lines().next().unwrap_or(trimmed).trim().to_string()
}

fn build_bundle_call_script(name: &str, fn_path: &str, args: &Value) -> Result<String, String> {
    let name_literal =
        serde_json::to_string(name).map_err(|e| format!("序列化 bundle 名称失败: {e}"))?;
    let fn_path_literal =
        serde_json::to_string(fn_path).map_err(|e| format!("序列化函数路径失败: {e}"))?;
    let args_literal =
        serde_json::to_string(args).map_err(|e| format!("序列化调用参数失败: {e}"))?;

    Ok(format!(
        r#"
        (async () => {{
          try {{
            const host = globalThis.__host_bundle_runtime;
            if (!host || typeof host.invoke !== "function") {{
              throw new Error("bundle dispatcher unavailable");
            }}
            const data = await host.invoke({{ name: {name_literal}, fnPath: {fn_path_literal}, args: {args_literal} }});
            return JSON.stringify({{ ok: true, data }});
          }} catch (err) {{
            const base = String(err && err.message ? err.message : err || "执行失败");
            const stack = String(err && err.stack ? err.stack : "");
            const message = stack ? `${{base}}\n${{stack}}` : base;
            return JSON.stringify({{ ok: false, error: message }});
          }}
        }})()
        "#
    ))
}

fn async_runtime_shared() -> &'static Mutex<HashMap<u64, Arc<RuntimeShared>>> {
    ASYNC_RUNTIME_SHARED.get_or_init(|| Mutex::new(HashMap::new()))
}

fn register_runtime_shared(runtime_id: u64, shared: Arc<RuntimeShared>) {
    if let Ok(mut guard) = async_runtime_shared().lock() {
        guard.insert(runtime_id, shared);
    }
}

fn unregister_runtime_shared(runtime_id: u64) {
    if let Ok(mut guard) = async_runtime_shared().lock() {
        guard.remove(&runtime_id);
    }
}

fn with_runtime_shared<F>(runtime_id: u64, f: F)
where
    F: FnOnce(&Arc<RuntimeShared>),
{
    let Some(shared) = async_runtime_shared()
        .lock()
        .ok()
        .and_then(|guard| guard.get(&runtime_id).cloned())
    else {
        return;
    };

    f(&shared);
}

fn async_runtime_task_complete(runtime_id: u64, task_id: u64, ok: bool, payload: String) {
    let outcome = if ok { Ok(payload) } else { Err(payload) };
    with_runtime_shared(runtime_id, |shared| {
        finalize_task_and_notify(shared, task_id, outcome)
    });
}

fn install_async_runtime_bindings(
    host: &HostRuntime,
    signal_tx: mpsc::Sender<WorkerSignal>,
) -> Result<(), String> {
    host.with_context(|ctx| {
        let globals = ctx.globals();
        globals.set(
            "__host_runtime_task_complete",
            Func::from(async_runtime_task_complete),
        )?;
        install_evented_host_bindings_worker(&ctx, signal_tx.clone(), host.options())?;
        ctx.eval::<(), _>(ASYNC_TASK_DISPATCHER_JS)?;
        Ok::<(), rquickjs::Error>(())
    })
    .map_err(|e| format!("安装 AsyncHostRuntime 绑定失败: {e}"))
}

fn install_evented_host_bindings_worker(
    ctx: &rquickjs::Ctx<'_>,
    signal_tx: mpsc::Sender<WorkerSignal>,
    options: WebRuntimeOptions,
) -> Result<(), rquickjs::Error> {
    let globals = ctx.globals();

    let http_tx = signal_tx.clone();
    globals.set(
        "__http_request_start_evented",
        Function::new(
            ctx.clone(),
            move |method: String, url: String, headers_json: String, body: Option<String>| {
                let tx = http_tx.clone();
                http_request_start_evented(method, url, headers_json, body, move |id, payload| {
                    let _ = tx.send(WorkerSignal::HostEvent(HostEvent::HttpCompleted {
                        id,
                        payload,
                    }));
                })
            },
        )?,
    )?;
    globals.set(
        "__http_request_drop_evented",
        Func::from(http_request_drop_evented),
    )?;

    let timer_tx = signal_tx.clone();
    globals.set(
        "__timer_start_evented",
        Function::new(ctx.clone(), move |delay_ms: i64| {
            let tx = timer_tx.clone();
            timer_start_evented(delay_ms, move |id, payload| {
                let _ = tx.send(WorkerSignal::HostEvent(HostEvent::TimerCompleted {
                    id,
                    payload,
                }));
            })
        })?,
    )?;
    globals.set("__timer_drop_evented", Func::from(timer_drop_evented))?;

    #[cfg(feature = "host-fs")]
    if options.fs {
        let fs_tx = signal_tx.clone();
        globals.set(
            "__fs_task_start_evented",
            Function::new(ctx.clone(), move |op: String, args_json: String| {
                let tx = fs_tx.clone();
                fs_task_start_evented(op, args_json, move |id, payload| {
                    let _ = tx.send(WorkerSignal::HostEvent(HostEvent::FsCompleted {
                        id,
                        payload,
                    }));
                })
            })?,
        )?;
        globals.set("__fs_task_drop_evented", Func::from(fs_task_drop_evented))?;
    }

    if options.wasi {
        let wasi_tx = signal_tx;
        globals.set(
            "__wasi_run_start_evented",
            Function::new(
                ctx.clone(),
                move |module_id: u64,
                      stdin_id: Option<u64>,
                      args_json: Option<String>,
                      consume_module: bool| {
                    let tx = wasi_tx.clone();
                    wasi_run_start_evented(
                        module_id,
                        stdin_id,
                        args_json,
                        consume_module,
                        move |id, payload| {
                            let _ = tx.send(WorkerSignal::HostEvent(HostEvent::WasiCompleted {
                                id,
                                payload,
                            }));
                        },
                    )
                },
            )?,
        )?;
        globals.set("__wasi_run_drop_evented", Func::from(wasi_run_drop_evented))?;
    }

    Ok(())
}

fn handle_worker_signal(
    signal: WorkerSignal,
    host: &HostRuntime,
    runtime_id: u64,
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
) -> bool {
    match signal {
        WorkerSignal::Command(cmd) => handle_worker_command(cmd, host, runtime_id, states, waiters),
        WorkerSignal::HostEvent(event) => {
            handle_host_event(host, event);
            true
        }
    }
}

fn handle_worker_command(
    cmd: AsyncCommand,
    host: &HostRuntime,
    runtime_id: u64,
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
) -> bool {
    match cmd {
        AsyncCommand::Submit { id, script } => {
            if !mark_running_if_available(states, id) {
                return true;
            }

            if let Err(err) = host.submit_async_task(runtime_id, id, &script) {
                finalize_task_with_waiter(states, waiters, id, Err(err));
            }
            true
        }
        AsyncCommand::Drop { id } => {
            mark_dropped_and_notify(states, waiters, id);
            true
        }
        AsyncCommand::DropMany { ids } => {
            for id in ids {
                mark_dropped_and_notify(states, waiters, id);
            }
            true
        }
        AsyncCommand::RunGc { tx } => {
            host.run_gc();
            let _ = tx.send(Ok(()));
            true
        }
        AsyncCommand::Shutdown => false,
    }
}

fn handle_host_event(host: &HostRuntime, event: HostEvent) {
    let result = host.with_context(|ctx| handle_host_event_in_ctx(ctx, event));

    let _ = result;
}

fn handle_host_event_in_ctx(
    ctx: rquickjs::Ctx<'_>,
    event: HostEvent,
) -> Result<(), rquickjs::Error> {
    let globals = ctx.globals();
    match event {
        HostEvent::HttpCompleted { id, payload } => {
            let func: Function = globals.get("__host_runtime_http_complete")?;
            func.call::<_, ()>((id, payload))
        }
        #[cfg(feature = "host-fs")]
        HostEvent::FsCompleted { id, payload } => {
            let func: Function = globals.get("__host_runtime_fs_complete")?;
            func.call::<_, ()>((id, payload))
        }
        HostEvent::WasiCompleted { id, payload } => {
            let func: Function = globals.get("__host_runtime_wasi_complete")?;
            func.call::<_, ()>((id, payload))
        }
        HostEvent::TimerCompleted { id, payload } => {
            let func: Function = globals.get("__host_runtime_timer_complete")?;
            func.call::<_, ()>((id, payload))
        }
    }
}

fn fail_all_active_tasks(
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    message: String,
) {
    let Ok(mut guard) = states.lock() else {
        return;
    };

    let mut failed_ids = Vec::new();
    for (id, state) in guard.iter_mut() {
        match state {
            TaskState::Pending | TaskState::Running => {
                *state = TaskState::Done(Err(message.clone()));
                failed_ids.push(*id);
            }
            TaskState::Done(_) | TaskState::Dropped => {}
        }
    }

    drop(guard);
    for id in failed_ids {
        let notified = notify_waiter(waiters, id, Err(message.clone()));
        if !notified {
            clear_task_state(states, id);
        }
    }
}

fn mark_dropped_and_notify(
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    id: u64,
) {
    let Ok(mut guard) = states.lock() else {
        return;
    };

    let Some(state) = guard.get(&id) else {
        return;
    };

    if !matches!(state, TaskState::Pending | TaskState::Running) {
        return;
    }

    guard.insert(id, TaskState::Dropped);
    drop(guard);
    let notified = notify_waiter(waiters, id, Err("task dropped".to_string()));
    if !notified {
        clear_task_state(states, id);
    }
}

fn finalize_task_with_waiter(
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    id: u64,
    outcome: Result<String, String>,
) {
    if finalize_task(states, id, outcome) {
        let notified = notify_waiter(waiters, id, read_done_outcome(states, id));
        if !notified {
            clear_task_state(states, id);
        }
    }
}

fn finalize_task_and_notify(shared: &RuntimeShared, id: u64, outcome: Result<String, String>) {
    finalize_task_with_waiter(&shared.states, &shared.waiters, id, outcome);
}

fn notify_waiter(
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    id: u64,
    outcome: Result<String, String>,
) -> bool {
    let sender = waiters.lock().ok().and_then(|mut guard| guard.remove(&id));
    if let Some(tx) = sender {
        let _ = tx.send(outcome);
        true
    } else {
        false
    }
}

fn read_done_outcome(
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    id: u64,
) -> Result<String, String> {
    let Ok(guard) = states.lock() else {
        return Err("读取任务结果失败: 状态锁已损坏".to_string());
    };

    match guard.get(&id) {
        Some(TaskState::Done(Ok(value))) => Ok(value.clone()),
        Some(TaskState::Done(Err(err))) => Err(err.clone()),
        Some(TaskState::Dropped) => Err("task dropped".to_string()),
        Some(TaskState::Pending) | Some(TaskState::Running) => {
            Err("读取任务结果失败: 任务尚未完成".to_string())
        }
        None => Err("读取任务结果失败: 任务不存在".to_string()),
    }
}

fn clear_task_state(states: &Arc<Mutex<HashMap<u64, TaskState>>>, id: u64) {
    if let Ok(mut guard) = states.lock() {
        guard.remove(&id);
    }
}

fn remove_waiter(
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    id: u64,
) {
    if let Ok(mut guard) = waiters.lock() {
        guard.remove(&id);
    }
}

fn is_task_active(states: &Arc<Mutex<HashMap<u64, TaskState>>>, id: u64) -> bool {
    let Ok(guard) = states.lock() else {
        return false;
    };

    matches!(
        guard.get(&id),
        Some(TaskState::Pending | TaskState::Running)
    )
}

fn mark_running_if_available(states: &Arc<Mutex<HashMap<u64, TaskState>>>, id: u64) -> bool {
    let Ok(mut guard) = states.lock() else {
        return false;
    };

    match guard.get(&id) {
        Some(TaskState::Dropped) | None => false,
        _ => {
            guard.insert(id, TaskState::Running);
            true
        }
    }
}

fn finalize_task(
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    id: u64,
    outcome: Result<String, String>,
) -> bool {
    let Ok(mut guard) = states.lock() else {
        return false;
    };

    match guard.get(&id) {
        Some(TaskState::Dropped) | None => {
            let _ = guard.remove(&id);
            false
        }
        _ => {
            guard.insert(id, TaskState::Done(outcome));
            true
        }
    }
}
