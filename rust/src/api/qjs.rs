use anyhow::Result;
use flutter_rust_bridge::{DartFnFuture, frb};

pub use crate::qjs::{QjsCancelTasksByGroupResult, QjsRuntimeBuildRequest};

/// Rust 堆缓冲句柄，所有权已移交给 Dart。
///
/// `ptr` 指向 heap 上一段 `len` 字节的连续内存（Rust `Vec<u8>` 的 data 指针）。
/// Dart 侧应把它当作零拷贝的 `Uint8List` 视图使用（`Uint8List.view`），
/// 用完后调用 [`qjs_free_task_bytes`] 释放，或经 Dart 侧 finalizer 自动释放。
/// `ptr == 0 && len == 0` 表示空结果。
pub struct QjsTaskBytes {
    pub ptr: usize,
    pub len: usize,
}

/// 把 `Vec<u8>` 泄漏为堆缓冲并返回 `(data_ptr, len)`，所有权转交给 Dart。
///
/// 释放时用 `Vec::from_raw_parts(ptr, len, len)` 重建，因此必须保证
/// `capacity == len`：`shrink_to_fit` 后若 allocator 不舍得缩容，重新精确收集一次。
fn leak_vec_to_qjs_task_bytes(mut bytes: Vec<u8>) -> QjsTaskBytes {
    if bytes.is_empty() {
        return QjsTaskBytes { ptr: 0, len: 0 };
    }
    bytes.shrink_to_fit();
    if bytes.capacity() != bytes.len() {
        // 极小概率 allocator 不舍得缩容；重新精确收集，保证 capacity == len。
        bytes = bytes.into_iter().collect();
    }
    let len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    // 泄漏：所有权交给 Dart，由 qjs_free_task_bytes 归还。
    std::mem::forget(bytes);
    QjsTaskBytes { ptr: ptr as usize, len }
}

#[frb]
pub async fn qjs_replace_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    crate::qjs::qjs_replace_bundle(runtime_name, bundle_name, bundle_js).await
}

/// 统一执行入口:调用插件 bundle 里的函数,返回原始字节。
///
/// `is_once=true` 用 `bundle_js`/`bundle_url` 走一次性 debug 池(不常驻);
/// `false` 走常驻运行时里已加载的当前 bundle。
/// 返回值为 Rust 堆缓冲句柄:JS 返回 `Uint8Array`/`ArrayBuffer` 时为真实字节,
/// 否则为 JSON 序列化后的 UTF-8 字节,由调用方自行转换。
/// 缓冲所有权已移交给 Dart,用完后必须调用 `qjs_free_task_bytes` 释放。
#[frb]
pub async fn qjs_task_call(
    runtime_name: String,
    task_group_key: String,
    is_once: bool,
    bundle_js: Option<String>,
    bundle_url: Option<String>,
    fn_path: String,
    args_json: String,
) -> Result<QjsTaskBytes> {
    let bytes = crate::qjs::qjs_task_call(
        runtime_name,
        task_group_key,
        is_once,
        bundle_js,
        bundle_url,
        fn_path,
        args_json,
    )
    .await?;
    Ok(leak_vec_to_qjs_task_bytes(bytes))
}

/// 释放 [`qjs_task_call`] 返回的 Rust 堆缓冲（把所有权归还给 Rust）。
///
/// 同一 `(ptr, len)` 只能释放一次；重复释放或释放非法句柄是未定义行为。
#[frb(sync)]
pub fn qjs_free_task_bytes(ptr: usize, len: usize) {
    if ptr == 0 || len == 0 {
        return;
    }
    // SAFETY:
    // - ptr/len 由 leak_vec_to_qjs_task_bytes 配套产生，已保证 capacity == len；
    // - Dart 侧承诺同一句柄只释放一次。
    unsafe {
        drop(Vec::from_raw_parts(ptr as *mut u8, len, len));
    }
}

#[frb]
pub async fn qjs_clear_bundle(runtime_name: String) -> Result<bool> {
    crate::qjs::qjs_clear_bundle(runtime_name).await
}

#[frb]
pub async fn qjs_current_bundle(runtime_name: String) -> Result<String> {
    crate::qjs::qjs_current_bundle(runtime_name).await
}

#[frb]
pub async fn qjs_drop_runtime(runtime_name: String) -> Result<bool> {
    crate::qjs::qjs_drop_runtime(runtime_name).await
}

#[frb]
pub async fn qjs_cancel_tasks_by_group(
    runtime_name: String,
    task_group_key: String,
) -> Result<QjsCancelTasksByGroupResult> {
    crate::qjs::qjs_cancel_tasks_by_group(runtime_name, task_group_key).await
}

#[frb]
pub async fn qjs_debug_snapshot(runtime_name: String) -> Result<String> {
    crate::qjs::qjs_debug_snapshot(runtime_name).await
}

#[frb(sync)]
pub fn set_http_proxy(proxy: String) -> Result<()> {
    crate::qjs::set_http_proxy(proxy)
}

#[frb(sync)]
pub fn set_socks5_proxy(proxy: String) -> Result<()> {
    crate::qjs::set_socks5_proxy(proxy)
}

#[frb(sync)]
pub fn set_tls_verify_enabled(enabled: bool) -> Result<()> {
    crate::qjs::set_tls_verify_enabled(enabled)
}

#[frb(sync)]
/// 设置 QuickJS 运行时错误消息语言（BCP-47 locale），默认 zh-CN
/// Set the QuickJS runtime error-message language (BCP-47 locale), defaults to zh-CN.
pub fn set_qjs_error_message_language(lang: String) -> Result<()> {
    rquickjs_playground::i18n::set_locale(&lang)
        .map_err(|e| anyhow::anyhow!("failed to set QJS locale: {e}"))?;
    Ok(())
}

#[frb(sync)]
pub fn is_tls_verify_enabled() -> Result<bool> {
    Ok(crate::qjs::is_tls_verify_enabled())
}

#[frb(sync)]
pub fn set_qjs_error_stack_enabled(enabled: bool) -> Result<()> {
    crate::qjs::set_qjs_error_stack_enabled(enabled)
}

#[frb(sync)]
pub fn configure_bridge_runtime(
    allowed_route_prefixes: Vec<String>,
    max_args_json_bytes: u64,
    max_return_binary_bytes: u64,
) -> Result<()> {
    crate::qjs::configure_bridge_runtime(
        allowed_route_prefixes,
        max_args_json_bytes,
        max_return_binary_bytes,
    )
}

#[frb(sync)]
pub fn set_host_cache_gc_enabled(enabled: bool) -> Result<()> {
    crate::qjs::set_host_cache_gc_enabled(enabled);
    Ok(())
}

#[frb(sync)]
pub fn is_host_cache_gc_enabled() -> Result<bool> {
    Ok(crate::qjs::is_host_cache_gc_enabled())
}

#[frb(sync)]
pub fn set_log_http_forward(url: String) -> Result<()> {
    crate::qjs::set_log_http_forward(url)
}

#[frb(sync)]
pub fn get_js_bundle(name: String) -> Result<String> {
    crate::qjs::get_js_bundle(name)
}

#[frb]
pub async fn is_qjs_runtime_initialized(name: String) -> Result<bool> {
    crate::qjs::is_qjs_runtime_initialized(name).await
}

#[frb]
pub async fn build_qjs_runtime(request: QjsRuntimeBuildRequest) -> Result<()> {
    crate::qjs::build_qjs_runtime(request).await
}

#[frb(sync)]
// 使用这个办法注册的都应该返回string，而不是一个类型
pub fn register_function(
    function_name: String,
    dart_callback: impl Fn(String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    crate::qjs::register_function(function_name, dart_callback)
}

#[frb(sync)]
pub fn init_rust_functions() -> Result<()> {
    crate::qjs::init_rust_functions()
}

#[frb(sync)]
pub fn opencc_convert(text: String, config: String) -> Result<String> {
    crate::qjs::opencc_convert(text, config)
}
