use base64::Engine as _;
use rquickjs::{
    AsyncContext, AsyncRuntime, Ctx, Function, Value as JsValue, async_with, function::Func,
};
use serde::de::DeserializeOwned;
use serde_json::Value;
use std::collections::{HashMap, VecDeque};
use std::future::IntoFuture;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::marker::PhantomData;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::time::Duration;
use tokio::sync::mpsc as tokio_mpsc;
use tokio::sync::oneshot;

use crate::web_runtime::{
    WebRuntimeOptions, http_request_drop_evented, http_request_start_evented,
    install_host_bindings, native_buffer_take_raw, polyfill_script, timer_drop_evented,
    timer_start_kind_evented,
};

#[cfg(feature = "host-fs")]
use crate::web_runtime::{fs_task_drop_evented, fs_task_start_evented};

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
    const sanitizeSourceName = (name) => String(name || "bundle")
      .replace(/[^a-zA-Z0-9._-]/g, "_")
      .slice(0, 120);
    const appendSourceUrl = (source, logicalName) =>
      `${String(source || "")}\n//# sourceURL=${sanitizeSourceName(logicalName)}.cjs`;
    const withInvokeContextError = (err, ctx) => {
      const scope = `bundle:${ctx?.name || "?"} fn:${ctx?.fnPath || "?"} args:${ctx?.args || "[]"} source:${ctx?.sourceName || "?"}`;

      if (err instanceof Error) {
        err.__bundle_scope = scope;
        return err;
      }

      const base = Error.isError(err) ? err.message : String(err || "执行失败");
      const enriched = new Error(base);
      if (typeof Error.captureStackTrace === "function") {
        Error.captureStackTrace(enriched, withInvokeContextError);
      }
      enriched.__bundle_scope = scope;
      return enriched;
    };

    const safeTypeOf = (value) => {
      if (value === null) return "null";
      if (Array.isArray(value)) return "array";
      return typeof value;
    };
    const ownKeysPreview = (obj, max = 24) => {
      if (!obj || (typeof obj !== "object" && typeof obj !== "function")) return [];
      try {
        return Object.keys(obj).slice(0, max);
      } catch (_err) {
        return [];
      }
    };
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
          throw new Error(
            `function path not found: ${fnPath}; missing segment=${key}; rootType=${safeTypeOf(api)}; rootKeys=${JSON.stringify(ownKeysPreview(api))}`
          );
        }
      }

      const leaf = parts[parts.length - 1];
      if (!isSafeKey(leaf)) throw new TypeError(`unsafe path segment: ${leaf}`);
      const fn = owner?.[leaf];
      if (typeof fn !== "function") {
        throw new TypeError(
          `target is not function: ${fnPath}; targetType=${safeTypeOf(fn)}; ownerType=${safeTypeOf(owner)}; ownerKeys=${JSON.stringify(ownKeysPreview(owner))}; rootKeys=${JSON.stringify(ownKeysPreview(api))}`
        );
      }

      return { owner, fn };
    };

    globalThis.__host_bundle_runtime = {
      loadBundle(name, source) {
        const registry = ensureRegistry();
        const module = { exports: {} };
        const exports = module.exports;
        const requireFn = typeof require === "function" ? require.bind(globalThis) : undefined;
        const runner = new Function("module", "exports", "require", appendSourceUrl(source, name));
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

        try {
          const { owner, fn } = resolveCallable(api, fnPath);
          return await fn.apply(owner, args);
        } catch (err) {
          throw withInvokeContextError(err, { name, fnPath, args: JSON.stringify(args), sourceName: `${sanitizeSourceName(name)}.cjs` });
        }
      },
      async invokeOnceLoaded(payload) {
        const registry = ensureRegistry();
        const name = String(payload?.name || "");
        const fnPath = String(payload?.fnPath || "");
        const args = Array.isArray(payload?.args) ? payload.args : [];
        const debugName = String(payload?.debugName || "__once__");
        const sourceName = String(payload?.sourceName || "__bundle_once__.cjs");

        const api = registry.get(name);
        if (!api) {
          throw new Error(`bundle not found: ${name}`);
        }

        try {
          const { owner, fn } = resolveCallable(api, fnPath);
          return await fn.apply(owner, args);
        } catch (err) {
          throw withInvokeContextError(err, { name: debugName, fnPath, args: JSON.stringify(args), sourceName });
        }
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
    };

    return JSON.stringify({ ok: true, data: null });
  } catch (err) {
    const base = Error.isError(err) ? err.message : String(err || "执行失败");
    const stack = Error.isError(err) ? (err.stack || "") : "";
    const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
    return JSON.stringify({ ok: false, error: base, stack, debug_scope: debugScope });
  }
})()"#;

const MAX_BUNDLE_CALL_ONCE_CONTEXTS: usize = 10;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ContextRoute {
    Primary,
    Once(usize),
}

struct ContextSlot {
    context: AsyncContext,
    busy_task_id: Option<u64>,
    last_bundle_source_hash: Option<u64>,
    last_bundle_name: Option<String>,
}

struct PendingOnceSubmission {
    id: u64,
    submission: OnceTaskSubmission,
}

struct OnceTaskSubmission {
    source: String,
    source_hash: u64,
    fn_path: String,
    args_json: String,
}

pub struct HostRuntime {
    runtime: AsyncRuntime,
    context: AsyncContext,
    once_contexts: Vec<ContextSlot>,
    pending_once_submissions: VecDeque<PendingOnceSubmission>,
    worker_signal_tx: Option<tokio_mpsc::UnboundedSender<WorkerSignal>>,
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
    tx: tokio_mpsc::UnboundedSender<WorkerSignal>,
    tokio_handle: tokio::runtime::Handle,
    states: Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
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

    pub fn build(self) -> Result<AsyncHostRuntime, String> {
        AsyncHostRuntime::build_inner(self.cache_scope_id, self.options)
    }
}

pub struct RuntimeTaskHandle {
    id: u64,
    rx: Option<oneshot::Receiver<Result<String, String>>>,
    states: Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    tx: tokio_mpsc::UnboundedSender<WorkerSignal>,
    drop_cleanup: bool,
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
    SubmitOnce {
        id: u64,
        submission: OnceTaskSubmission,
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
        route: ContextRoute,
        id: u64,
        payload: String,
    },
    #[cfg(feature = "host-fs")]
    FsCompleted {
        route: ContextRoute,
        id: u64,
        payload: String,
    },
    TimerCompleted {
        route: ContextRoute,
        id: u64,
        payload: String,
    },
}

enum WorkerSignal {
    Command(AsyncCommand),
    HostEvent(HostEvent),
    TaskCompleted { id: u64 },
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
    worker_signal_tx: tokio_mpsc::UnboundedSender<WorkerSignal>,
}

fn serialize_js_value<'js>(ctx: &Ctx<'js>, value: JsValue<'js>) -> Result<String, String> {
    if value.is_undefined() {
        return Ok("undefined".to_string());
    }
    if value.is_string() {
        return value
            .as_string()
            .and_then(|s| s.to_string().ok())
            .ok_or_else(|| "无法读取字符串".to_string());
    }
    match ctx.json_stringify(value) {
        Ok(Some(js_str)) => js_str.to_string().map_err(|e| format!("{e}")),
        Ok(None) => Ok("undefined".to_string()),
        Err(_) => Ok("null".to_string()),
    }
}

impl HostRuntime {
    async fn install_promise_rejection_tracker(runtime: &AsyncRuntime) {
        runtime
            .set_host_promise_rejection_tracker(Some(Box::new(
                move |ctx, _promise, reason, is_handled| {
                    if is_handled {
                        return;
                    }

                    let message = if reason.is_string() {
                        reason
                            .get::<String>()
                            .unwrap_or_else(|_| "Promise rejected".to_string())
                    } else if reason.is_undefined() {
                        "Promise rejected".to_string()
                    } else {
                        ctx.json_stringify(reason)
                            .ok()
                            .and_then(|v| v.and_then(|s| s.to_string().ok()))
                            .unwrap_or_else(|| "Promise rejected".to_string())
                    };

                    tracing::warn!("[qjs-unhandled-promise] {}", message);
                },
            )))
            .await;
    }

    async fn init_context(
        runtime: &AsyncRuntime,
        cache_scope_id: &str,
        options: WebRuntimeOptions,
    ) -> Result<AsyncContext, String> {
        let context = AsyncContext::full(runtime)
            .await
            .map_err(|e| format!("初始化 AsyncContext 失败: {e}"))?;
        let polyfill = polyfill_script(options);
        context
            .with(|ctx| {
                install_host_bindings(&ctx, cache_scope_id, options)?;
                ctx.eval::<(), _>(polyfill.as_str())?;
                Ok::<(), rquickjs::Error>(())
            })
            .await
            .map_err(|e| format!("初始化 Context 绑定失败: {e}"))?;
        Ok(context)
    }

    pub async fn new_with_options_async(
        cache_scope_id: String,
        options: WebRuntimeOptions,
    ) -> Result<Self, String> {
        if options.fs && !cfg!(feature = "host-fs") {
            return Err("当前构建未启用 host-fs Cargo 特性".to_string());
        }
        crate::web_runtime::set_worker_http_config(crate::web_runtime::current_http_client_config());
        let runtime = AsyncRuntime::new().map_err(|e| format!("初始化 AsyncRuntime 失败: {e}"))?;
        Self::install_promise_rejection_tracker(&runtime).await;
        let context = Self::init_context(&runtime, &cache_scope_id, options).await?;

        Ok(Self {
            runtime,
            context,
            once_contexts: Vec::new(),
            pending_once_submissions: VecDeque::new(),
            worker_signal_tx: None,
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
        let ctx = self.context.clone();
        let rt_id = runtime_id;
        let id = task_id;
        let script_owned = script.to_owned();
        tokio::spawn(async move {
            let result: Result<String, String> = async_with!(&ctx => |ctx| {
                let value: JsValue = ctx.eval(script_owned.as_str())
                    .map_err(|e: rquickjs::Error| format!("eval失败: {e}"))?;
                if let Some(promise) = value.as_promise() {
                    let r = promise.clone().into_future::<JsValue>().await;
                    match r {
                        Ok(v) => serialize_js_value(&ctx, v),
                        Err(e) => Err(format!("Promise rejected: {e}")),
                    }
                } else {
                    serialize_js_value(&ctx, value)
                }
            })
            .await;
            let outcome = result.unwrap_or_else(|e| {
                format!("{{\"ok\":false,\"error\":\"{}\"}}", e.replace('"', "\\\""))
            });
            with_runtime_shared(rt_id, |shared| {
                finalize_task_and_notify(shared, id, Ok(outcome));
                let _ = shared
                    .worker_signal_tx
                    .send(WorkerSignal::TaskCompleted { id });
            });
        });
        Ok(())
    }

    fn set_worker_signal_tx(&mut self, tx: tokio_mpsc::UnboundedSender<WorkerSignal>) {
        self.worker_signal_tx = Some(tx);
    }

    async fn ensure_async_runtime_bindings_on_context(
        &self,
        context: &AsyncContext,
    ) -> Result<(), String> {
        let Some(signal_tx) = self.worker_signal_tx.clone() else {
            return Err("AsyncHostRuntime worker 信号通道不可用".to_string());
        };
        context
            .with(|ctx| {
                install_evented_host_bindings_worker(
                    &ctx,
                    signal_tx.clone(),
                    self.options,
                    ContextRoute::Primary,
                )?;
                ctx.eval::<(), _>(BUNDLE_DISPATCHER_JS)?;
                Ok::<(), rquickjs::Error>(())
            })
            .await
            .map_err(|e| format!("安装 AsyncHostRuntime 上下文绑定失败: {e}"))
    }

    async fn ensure_once_context_pool_capacity(
        &mut self,
        max_contexts: usize,
    ) -> Result<(), String> {
        while self.once_contexts.len() < max_contexts {
            let context =
                Self::init_context(&self.runtime, &self.cache_scope_id, self.options).await?;
            let slot_index = self.once_contexts.len();
            context
                .with(|ctx| {
                    install_evented_host_bindings_worker(
                        &ctx,
                        self.worker_signal_tx.clone().ok_or_else(|| {
                            rquickjs::Error::new_from_js_message(
                                "rust",
                                "runtime",
                                "worker signal channel unavailable",
                            )
                        })?,
                        self.options,
                        ContextRoute::Once(slot_index),
                    )?;
                    ctx.eval::<(), _>(BUNDLE_DISPATCHER_JS)?;
                    Ok::<(), rquickjs::Error>(())
                })
                .await
                .map_err(|e| format!("安装一次性 Context 绑定失败: {e}"))?;
            self.once_contexts.push(ContextSlot {
                context,
                busy_task_id: None,
                last_bundle_source_hash: None,
                last_bundle_name: None,
            });
        }
        Ok(())
    }

    async fn acquire_once_slot_for_task(
        &mut self,
        task_id: u64,
        max_contexts: usize,
    ) -> Result<Option<usize>, String> {
        if let Some((index, slot)) = self
            .once_contexts
            .iter_mut()
            .enumerate()
            .find(|(_, slot)| slot.busy_task_id.is_none())
        {
            slot.busy_task_id = Some(task_id);
            return Ok(Some(index));
        }

        if self.once_contexts.len() < max_contexts {
            self.ensure_once_context_pool_capacity(self.once_contexts.len() + 1)
                .await?;
            let index = self.once_contexts.len() - 1;
            self.once_contexts[index].busy_task_id = Some(task_id);
            return Ok(Some(index));
        }

        Ok(None)
    }

    async fn submit_async_task_on_route(
        &mut self,
        route: ContextRoute,
        runtime_id: u64,
        task_id: u64,
        script: &str,
    ) -> Result<(), String> {
        match route {
            ContextRoute::Primary => self.submit_async_task(runtime_id, task_id, script),
            ContextRoute::Once(slot_index) => {
                let Some(slot) = self.once_contexts.get(slot_index) else {
                    return Err(format!("一次性 Context slot 不存在: {slot_index}"));
                };
                let ctx = slot.context.clone();
                let rt_id = runtime_id;
                let id = task_id;
                let script_owned = script.to_owned();
                tokio::spawn(async move {
                    let result: Result<String, String> = async_with!(&ctx => |ctx| {
                        let value: JsValue = ctx.eval(script_owned.as_str()).map_err(|e: rquickjs::Error| format!("eval失败: {e}"))?;
                        if let Some(promise) = value.as_promise() {
                            let r = promise.clone().into_future::<JsValue>().await;
                            match r {
                                Ok(v) => serialize_js_value(&ctx, v),
                                Err(e) => Err(format!("Promise rejected: {e}")),
                            }
                        } else {
                            serialize_js_value(&ctx, value)
                        }
                    }).await;
                    let outcome = result.unwrap_or_else(|e| {
                        format!("{{\"ok\":false,\"error\":\"{}\"}}", e.replace('"', "\\\""))
                    });
                    with_runtime_shared(rt_id, |shared| {
                        finalize_task_and_notify(shared, id, Ok(outcome));
                        let _ = shared
                            .worker_signal_tx
                            .send(WorkerSignal::TaskCompleted { id });
                    });
                });
                Ok(())
            }
        }
    }

    async fn submit_once_task_on_slot(
        &mut self,
        runtime_id: u64,
        task_id: u64,
        slot_index: usize,
        submission: &OnceTaskSubmission,
    ) -> Result<(), String> {
        let last_hash = self
            .once_contexts
            .get(slot_index)
            .and_then(|slot| slot.last_bundle_source_hash);
        let bundle_name = format!("__bundle_once__{:016x}", submission.source_hash);
        let script = build_bundle_call_once_script(
            if last_hash == Some(submission.source_hash) {
                None
            } else {
                Some(submission.source.as_str())
            },
            &bundle_name,
            &submission.fn_path,
            &submission.args_json,
        )?;

        self.submit_async_task_on_route(
            ContextRoute::Once(slot_index),
            runtime_id,
            task_id,
            &script,
        )
        .await?;

        if let Some(slot) = self.once_contexts.get_mut(slot_index) {
            slot.last_bundle_source_hash = Some(submission.source_hash);
            slot.last_bundle_name = Some(bundle_name);
        }
        Ok(())
    }

    async fn with_context_route<R>(
        &self,
        route: ContextRoute,
        f: impl for<'js> FnOnce(rquickjs::Ctx<'js>) -> Result<R, rquickjs::Error> + Send + 'static,
    ) -> Result<R, rquickjs::Error>
    where
        R: Send + 'static,
    {
        match route {
            ContextRoute::Primary => self.context.with(f).await,
            ContextRoute::Once(slot_index) => {
                self.once_contexts
                    .get(slot_index)
                    .ok_or_else(|| {
                        rquickjs::Error::new_from_js_message(
                            "rust",
                            "runtime",
                            &format!("once context slot not found: {slot_index}"),
                        )
                    })?
                    .context
                    .with(f)
                    .await
            }
        }
    }

    fn queue_pending_once_submission(&mut self, id: u64, submission: OnceTaskSubmission) {
        self.pending_once_submissions
            .push_back(PendingOnceSubmission { id, submission });
    }

    fn remove_pending_once_submission(&mut self, id: u64) -> bool {
        let before = self.pending_once_submissions.len();
        self.pending_once_submissions.retain(|item| item.id != id);
        before != self.pending_once_submissions.len()
    }

    fn release_once_slot(&mut self, task_id: u64) -> Result<bool, String> {
        let Some((slot_index, _)) = self
            .once_contexts
            .iter()
            .enumerate()
            .find(|(_, slot)| slot.busy_task_id == Some(task_id))
        else {
            return Ok(false);
        };

        self.once_contexts[slot_index].busy_task_id = None;
        Ok(true)
    }

    async fn try_schedule_pending_once_submissions(
        &mut self,
        runtime_id: u64,
        states: &Arc<Mutex<HashMap<u64, TaskState>>>,
        waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    ) {
        loop {
            let Some(pending) = self.pending_once_submissions.pop_front() else {
                break;
            };

            if !is_task_active(states, pending.id) {
                remove_waiter(waiters, pending.id);
                clear_task_state(states, pending.id);
                continue;
            }

            match self
                .acquire_once_slot_for_task(pending.id, MAX_BUNDLE_CALL_ONCE_CONTEXTS)
                .await
            {
                Ok(Some(slot_index)) => {
                    if let Err(err) = self
                        .submit_once_task_on_slot(
                            runtime_id,
                            pending.id,
                            slot_index,
                            &pending.submission,
                        )
                        .await
                    {
                        let _ = self.release_once_slot(pending.id);
                        finalize_task_with_waiter(states, waiters, pending.id, Err(err));
                        continue;
                    }
                }
                Ok(None) => {
                    self.pending_once_submissions.push_front(pending);
                    break;
                }
                Err(err) => {
                    finalize_task_with_waiter(states, waiters, pending.id, Err(err));
                }
            }
        }
    }

    pub async fn pump_jobs(&self, max_jobs: usize) -> Result<usize, String> {
        let mut executed = 0usize;
        while executed < max_jobs && self.runtime.is_job_pending().await {
            match self.runtime.execute_pending_job().await {
                Ok(true) => executed += 1,
                Ok(false) => break,
                Err(err) => return Err(format!("执行 JS event loop job 失败: {err}")),
            }
        }
        Ok(executed)
    }

    pub async fn with_context<R>(
        &self,
        f: impl for<'js> FnOnce(rquickjs::Ctx<'js>) -> Result<R, rquickjs::Error> + Send + 'static,
    ) -> Result<R, rquickjs::Error>
    where
        R: Send + 'static,
    {
        self.context.with(f).await
    }

    pub async fn run_gc(&self) {
        self.runtime.run_gc().await;
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
        if options.fs && !cfg!(feature = "host-fs") {
            return Err("当前构建未启用 host-fs Cargo 特性".to_string());
        }
        let cache_scope_id_for_worker = cache_scope_id.clone();
        let options_for_worker = options;
        let (tx, mut rx) = tokio_mpsc::unbounded_channel::<WorkerSignal>();
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
                worker_signal_tx: tx.clone(),
            }),
        );
        let (init_tx, init_rx) = std::sync::mpsc::channel::<Result<(), String>>();
        let (handle_tx, handle_rx) = std::sync::mpsc::channel::<tokio::runtime::Handle>();

        thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .thread_name(format!("qjs-{cache_scope_id_for_worker}"))
                .build()
                .expect("创建 per-instance tokio runtime 失败");

            let _ = handle_tx.send(rt.handle().clone());

            rt.block_on(async move {
                let mut host = match HostRuntime::new_with_options_async(
                    cache_scope_id_for_worker,
                    options_for_worker,
                )
                .await
                {
                    Ok(host) => host,
                    Err(err) => {
                        let _ = init_tx.send(Err(format!("初始化 HostRuntime 失败: {err}")));
                        return;
                    }
                };

                host.set_worker_signal_tx(tx_for_worker.clone());

                if let Err(err) = install_async_runtime_bindings(&host, tx_for_worker.clone()).await
                {
                    let _ = init_tx.send(Err(err));
                    return;
                }

                let _ = init_tx.send(Ok(()));

                let mut running = true;
                while running {
                    while let Ok(signal) = rx.try_recv() {
                        running = handle_worker_signal(
                            signal,
                            &mut host,
                            runtime_id,
                            &states_for_worker,
                            &waiters_for_worker,
                        )
                        .await;
                        if !running {
                            break;
                        }
                    }

                    if !running {
                        break;
                    }

                    match host.pump_jobs(2048).await {
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

                    match tokio::time::timeout(Duration::from_millis(1), rx.recv()).await {
                        Ok(Some(signal)) => {
                            running = handle_worker_signal(
                                signal,
                                &mut host,
                                runtime_id,
                                &states_for_worker,
                                &waiters_for_worker,
                            )
                            .await;
                        }
                        Ok(None) => break,
                        Err(_elapsed) => {}
                    }
                }
            });
        });

        let tokio_handle = handle_rx
            .recv()
            .map_err(|_| "获取 tokio handle 失败".to_string())?;

        match init_rx.recv() {
            Ok(Ok(())) => Ok(Self {
                runtime_id,
                cache_scope_id,
                options,
                tx,
                tokio_handle,
                states,
                waiters,
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

    pub fn tokio_handle(&self) -> &tokio::runtime::Handle {
        &self.tokio_handle
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
        let _ = crate::source_map::extract_and_register("__default__", source);
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
                const base = Error.isError(err) ? err.message : String(err || "执行失败");
                const stack = Error.isError(err) ? (err.stack || "") : "";
                const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
                return JSON.stringify({{ ok: false, error: base, stack, debug_scope: debugScope }});
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

    pub async fn bundle_call_bytes(
        &self,
        name: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Vec<u8>, String> {
        self.bundle_call_start(name, fn_path, args)
            .await?
            .wait_bytes_async()
            .await
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

    pub async fn bundle_call_once_bytes(
        &self,
        source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Vec<u8>, String> {
        self.bundle_call_once_start(source, fn_path, args)
            .await?
            .wait_bytes_async()
            .await
    }

    pub async fn bundle_call_once_start(
        &self,
        source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<RuntimeTaskHandle, String> {
        if !args.is_array() {
            return Err("调用参数必须是 JSON 数组".to_string());
        }

        let handle = self
            .spawn_once(source, fn_path, args)
            .await
            .map_err(|e| format!("执行一次性 bundle 调用失败: {e}"))?;
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
                const base = Error.isError(err) ? err.message : String(err || "执行失败");
                const stack = Error.isError(err) ? (err.stack || "") : "";
                const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
                return JSON.stringify({{ ok: false, error: base, stack, debug_scope: debugScope }});
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
                const base = Error.isError(err) ? err.message : String(err || "执行失败");
                const stack = Error.isError(err) ? (err.stack || "") : "";
                const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
                return JSON.stringify({ ok: false, error: base, stack, debug_scope: debugScope });
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

    async fn spawn_once(
        &self,
        source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<RuntimeTaskHandle, String> {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst);
        let (result_tx, result_rx) = oneshot::channel::<Result<String, String>>();
        let source_owned = source.to_string();
        let source_hash = tokio::task::spawn_blocking({
            let source_for_hash = source_owned.clone();
            move || fast_u64_hash(&source_for_hash)
        })
        .await
        .map_err(|e| format!("计算一次性 bundle 哈希失败: {e}"))?;
        let submission = OnceTaskSubmission {
            source: source_owned,
            source_hash,
            fn_path: fn_path.to_string(),
            args_json: serde_json::to_string(args)
                .map_err(|e| format!("序列化调用参数失败: {e}"))?,
        };

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
            .send(WorkerSignal::Command(AsyncCommand::SubmitOnce {
                id,
                submission,
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
        })
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

    pub fn wait_bytes(self) -> Result<Vec<u8>, String> {
        parse_bytes_payload(self.wait())
    }

    pub async fn wait_bytes_async(self) -> Result<Vec<u8>, String> {
        parse_bytes_payload(self.wait_async().await)
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

fn parse_bytes_payload(raw: Result<String, String>) -> Result<Vec<u8>, String> {
    let data = parse_ok_json_payload(&raw?)?;
    bytes_from_value(&data)
}

fn bytes_from_value(data: &Value) -> Result<Vec<u8>, String> {
    if let Some(obj) = data.as_object() {
        if let Some(id) = obj.get("nativeBufferId").and_then(Value::as_u64) {
            return native_buffer_take_raw(id)
                .ok_or_else(|| format!("native buffer 不存在或已被消费: {id}"));
        }
    }

    if let Some(arr) = data.as_array() {
        let mut out = Vec::with_capacity(arr.len());
        for (idx, item) in arr.iter().enumerate() {
            let n = item
                .as_u64()
                .ok_or_else(|| format!("字节数组第 {idx} 项不是无符号整数"))?;
            if n > 255 {
                return Err(format!("字节数组第 {idx} 项超出范围: {n}"));
            }
            out.push(n as u8);
        }
        return Ok(out);
    }

    if let Some(raw) = data.as_str() {
        let text = raw.trim();
        if text.is_empty() {
            return Ok(Vec::new());
        }
        let b64 = if let Some(idx) = text.find(',') {
            let (prefix, tail) = text.split_at(idx);
            if prefix.to_ascii_lowercase().contains(";base64") {
                tail.trim_start_matches(',').trim()
            } else {
                text
            }
        } else {
            text
        };
        return base64::engine::general_purpose::STANDARD
            .decode(b64)
            .map_err(|e| format!("无法将字符串解码为 base64 字节: {e}"));
    }

    Err("不支持的二进制返回类型：期望 nativeBufferId / number[] / base64字符串".to_string())
}

fn build_bundle_call_once_script(
    source: Option<&str>,
    bundle_name: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<String, String> {
    let name_literal =
        serde_json::to_string(bundle_name).map_err(|e| format!("序列化 bundle 名称失败: {e}"))?;
    let source_clause = if let Some(source) = source {
        let source_literal =
            serde_json::to_string(source).map_err(|e| format!("序列化 bundle 脚本失败: {e}"))?;
        format!("host.loadBundle({name_literal}, {source_literal});")
    } else {
        String::new()
    };
    let fn_path_literal =
        serde_json::to_string(fn_path).map_err(|e| format!("序列化函数路径失败: {e}"))?;

    Ok(format!(
        r#"
        (async () => {{
          const encodeHostData = (value) => {{
            if (
              (
                typeof globalThis.__native_buffer_put_raw === "function"
                || typeof globalThis.__native_buffer_put === "function"
              )
              && (
                value instanceof Uint8Array
                || value instanceof ArrayBuffer
                || ArrayBuffer.isView(value)
              )
            ) {{
              let bytes;
              if (value instanceof Uint8Array) bytes = value;
              else if (value instanceof ArrayBuffer) bytes = new Uint8Array(value);
              else bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
              let id;
              if (typeof globalThis.__native_buffer_put_raw === "function") {{
                try {{
                  id = globalThis.__native_buffer_put_raw(Array.from(bytes));
                }} catch (_err) {{}}
              }}
              if ((id === undefined || id === null) && typeof globalThis.__native_buffer_put === "function") {{
                const raw = globalThis.__native_buffer_put(JSON.stringify(Array.from(bytes)));
                const payload = JSON.parse(raw);
                if (!payload || payload.ok !== true) {{
                  throw new Error(payload && payload.error ? String(payload.error) : "native put failed");
                }}
                id = payload.id;
              }}
              if (id === undefined || id === null) {{
                throw new Error("native binary bridge unavailable");
              }}
              return {{
                __hostReturnKind: "bytes",
                nativeBufferId: id,
                tag: Object.prototype.toString.call(value),
                ctor: value && value.constructor ? String(value.constructor.name || "") : "",
                byteLength: Number(bytes.byteLength || 0),
              }};
            }}
            return value;
          }};
          try {{
            const host = globalThis.__host_bundle_runtime;
            if (!host || typeof host.loadBundle !== "function" || typeof host.invokeOnceLoaded !== "function") {{
              throw new Error("bundle dispatcher unavailable");
            }}
            {source_clause}
            const data = await host.invokeOnceLoaded({{
              name: {name_literal},
              debugName: "__once__",
              sourceName: "__bundle_once__.cjs",
              fnPath: {fn_path_literal},
              args: {args_json}
            }});
            return JSON.stringify({{ ok: true, data: encodeHostData(data) }});
          }} catch (err) {{
            const base = Error.isError(err) ? err.message : String(err || "执行失败");
            const stack = Error.isError(err) ? (err.stack || "") : "";
            const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
            return JSON.stringify({{ ok: false, error: base, stack, debug_scope: debugScope }});
          }}
        }})()
        "#
    ))
}

fn fast_u64_hash(text: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    text.hash(&mut hasher);
    hasher.finish()
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
        let raw_stack = payload.get("stack").and_then(Value::as_str).unwrap_or("");
        let debug_scope = payload
            .get("debug_scope")
            .and_then(Value::as_str)
            .unwrap_or("");
        Err(format_js_error_with_stack(
            raw_error,
            raw_stack,
            debug_scope,
        ))
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

fn format_js_error_with_stack(raw_error: &str, raw_stack: &str, debug_scope: &str) -> String {
    let message = format_js_error(raw_error);
    if !js_error_stack_enabled() {
        return message;
    }

    let scope = debug_scope.trim();
    let scoped_message = if scope.is_empty() {
        message.clone()
    } else {
        format!("[{scope}] {message}")
    };

    let stack = raw_stack.trim();
    if stack.is_empty() {
        return scoped_message;
    }
    if stack.starts_with(message.as_str()) {
        if scope.is_empty() {
            return stack.to_string();
        }
        return format!("[{scope}] {stack}");
    }
    format!("{scoped_message}\n{stack}")
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
          const encodeHostData = (value) => {{
            if (
              (
                typeof globalThis.__native_buffer_put_raw === "function"
                || typeof globalThis.__native_buffer_put === "function"
              )
              && (
                value instanceof Uint8Array
                || value instanceof ArrayBuffer
                || ArrayBuffer.isView(value)
              )
            ) {{
              let bytes;
              if (value instanceof Uint8Array) bytes = value;
              else if (value instanceof ArrayBuffer) bytes = new Uint8Array(value);
              else bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
              let id;
              if (typeof globalThis.__native_buffer_put_raw === "function") {{
                try {{
                  id = globalThis.__native_buffer_put_raw(Array.from(bytes));
                }} catch (_err) {{}}
              }}
              if ((id === undefined || id === null) && typeof globalThis.__native_buffer_put === "function") {{
                const raw = globalThis.__native_buffer_put(JSON.stringify(Array.from(bytes)));
                const payload = JSON.parse(raw);
                if (!payload || payload.ok !== true) {{
                  throw new Error(payload && payload.error ? String(payload.error) : "native put failed");
                }}
                id = payload.id;
              }}
              if (id === undefined || id === null) {{
                throw new Error("native binary bridge unavailable");
              }}
              return {{
                __hostReturnKind: "bytes",
                nativeBufferId: id,
                tag: Object.prototype.toString.call(value),
                ctor: value && value.constructor ? String(value.constructor.name || "") : "",
                byteLength: Number(bytes.byteLength || 0),
              }};
            }}
            return value;
          }};
          try {{
            const host = globalThis.__host_bundle_runtime;
            if (!host || typeof host.invoke !== "function") {{
              throw new Error("bundle dispatcher unavailable");
            }}
            const data = await host.invoke({{ name: {name_literal}, fnPath: {fn_path_literal}, args: {args_literal} }});
            return JSON.stringify({{ ok: true, data: encodeHostData(data) }});
          }} catch (err) {{
            const base = Error.isError(err) ? err.message : String(err || "执行失败");
            const stack = Error.isError(err) ? (err.stack || "") : "";
            const debugScope = Error.isError(err) ? (err.__bundle_scope || "") : "";
            return JSON.stringify({{ ok: false, error: base, stack, debug_scope: debugScope }});
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

async fn install_async_runtime_bindings(
    host: &HostRuntime,
    _signal_tx: tokio_mpsc::UnboundedSender<WorkerSignal>,
) -> Result<(), String> {
    host.ensure_async_runtime_bindings_on_context(&host.context)
        .await
        .map_err(|e| format!("安装 AsyncHostRuntime 绑定失败: {e}"))
}

fn install_evented_host_bindings_worker(
    ctx: &rquickjs::Ctx<'_>,
    signal_tx: tokio_mpsc::UnboundedSender<WorkerSignal>,
    options: WebRuntimeOptions,
    route: ContextRoute,
) -> Result<(), rquickjs::Error> {
    let globals = ctx.globals();

    let http_tx = signal_tx.clone();
    globals.set(
        "__http_request_start_evented",
        Function::new(
            ctx.clone(),
            move |method: String,
                  url: String,
                  headers_json: String,
                  body: Option<String>,
                  body_native_buffer_id: Option<u64>| {
                let tx = http_tx.clone();
                http_request_start_evented(
                    method,
                    url,
                    headers_json,
                    body,
                    body_native_buffer_id,
                    move |id, payload| {
                        let _ = tx.send(WorkerSignal::HostEvent(HostEvent::HttpCompleted {
                            route,
                            id,
                            payload,
                        }));
                    },
                )
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
        Function::new(ctx.clone(), move |delay_ms: i64, repeat: Option<bool>| {
            let tx = timer_tx.clone();
            timer_start_kind_evented(delay_ms, repeat.unwrap_or(false), move |id, payload| {
                let _ = tx.send(WorkerSignal::HostEvent(HostEvent::TimerCompleted {
                    route,
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
                        route,
                        id,
                        payload,
                    }));
                })
            })?,
        )?;
        globals.set("__fs_task_drop_evented", Func::from(fs_task_drop_evented))?;
    }

    Ok(())
}

async fn handle_worker_signal(
    signal: WorkerSignal,
    host: &mut HostRuntime,
    runtime_id: u64,
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
) -> bool {
    match signal {
        WorkerSignal::Command(cmd) => {
            handle_worker_command(cmd, host, runtime_id, states, waiters).await
        }
        WorkerSignal::HostEvent(event) => {
            handle_host_event(host, event).await;
            true
        }
        WorkerSignal::TaskCompleted { id } => {
            handle_task_completed(host, runtime_id, states, waiters, id).await;
            true
        }
    }
}

async fn handle_worker_command(
    cmd: AsyncCommand,
    host: &mut HostRuntime,
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
        AsyncCommand::SubmitOnce { id, submission } => {
            if !mark_running_if_available(states, id) {
                return true;
            }

            match host
                .acquire_once_slot_for_task(id, MAX_BUNDLE_CALL_ONCE_CONTEXTS)
                .await
            {
                Ok(Some(slot_index)) => {
                    if let Err(err) = host
                        .submit_once_task_on_slot(runtime_id, id, slot_index, &submission)
                        .await
                    {
                        let _ = host.release_once_slot(id);
                        finalize_task_with_waiter(states, waiters, id, Err(err));
                    }
                }
                Ok(None) => {
                    host.queue_pending_once_submission(id, submission);
                }
                Err(err) => {
                    finalize_task_with_waiter(states, waiters, id, Err(err));
                }
            }
            true
        }
        AsyncCommand::Drop { id } => {
            if host.remove_pending_once_submission(id) {
                clear_task_state(states, id);
                remove_waiter(waiters, id);
                return true;
            }
            mark_dropped_and_notify(states, waiters, id);
            let _ = host.release_once_slot(id);
            host.try_schedule_pending_once_submissions(runtime_id, states, waiters)
                .await;
            true
        }
        AsyncCommand::DropMany { ids } => {
            for id in ids {
                if host.remove_pending_once_submission(id) {
                    clear_task_state(states, id);
                    remove_waiter(waiters, id);
                } else {
                    mark_dropped_and_notify(states, waiters, id);
                    let _ = host.release_once_slot(id);
                }
            }
            host.try_schedule_pending_once_submissions(runtime_id, states, waiters)
                .await;
            true
        }
        AsyncCommand::RunGc { tx } => {
            let rt = host.runtime.clone();
            tokio::spawn(async move {
                rt.run_gc().await;
                let _ = tx.send(Ok(()));
            });
            true
        }
        AsyncCommand::Shutdown => false,
    }
}

async fn handle_host_event(host: &HostRuntime, event: HostEvent) {
    let route = match &event {
        HostEvent::HttpCompleted { route, .. } => *route,
        #[cfg(feature = "host-fs")]
        HostEvent::FsCompleted { route, .. } => *route,
        HostEvent::TimerCompleted { route, .. } => *route,
    };
    let result = host
        .with_context_route(route, |ctx| handle_host_event_in_ctx(ctx, event))
        .await;

    let _ = result;
}

fn handle_host_event_in_ctx(
    ctx: rquickjs::Ctx<'_>,
    event: HostEvent,
) -> Result<(), rquickjs::Error> {
    let globals = ctx.globals();
    match event {
        HostEvent::HttpCompleted { id, payload, .. } => {
            let func: Function = globals.get("__host_runtime_http_complete")?;
            func.call::<_, ()>((id, payload))
        }
        #[cfg(feature = "host-fs")]
        HostEvent::FsCompleted { id, payload, .. } => {
            let func: Function = globals.get("__host_runtime_fs_complete")?;
            func.call::<_, ()>((id, payload))
        }
        HostEvent::TimerCompleted { id, payload, .. } => {
            let func: Function = globals.get("__host_runtime_timer_complete")?;
            func.call::<_, ()>((id, payload))
        }
    }
}

async fn handle_task_completed(
    host: &mut HostRuntime,
    runtime_id: u64,
    states: &Arc<Mutex<HashMap<u64, TaskState>>>,
    waiters: &Arc<Mutex<HashMap<u64, oneshot::Sender<Result<String, String>>>>>,
    id: u64,
) {
    let _ = host.release_once_slot(id);
    host.try_schedule_pending_once_submissions(runtime_id, states, waiters)
        .await;
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
