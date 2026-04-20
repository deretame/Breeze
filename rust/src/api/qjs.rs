use anyhow::Result;
use flutter_rust_bridge::{DartFnFuture, frb};

pub use crate::qjs::{QjsCancelTaskResult, QjsCancelTasksByGroupResult};

#[frb]
pub async fn qjs_replace_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    crate::qjs::qjs_replace_bundle(runtime_name, bundle_name, bundle_js).await
}

#[frb]
pub async fn qjs_call(runtime_name: String, fn_path: String, args_json: String) -> Result<String> {
    crate::qjs::qjs_call(runtime_name, fn_path, args_json).await
}

#[frb]
pub async fn qjs_call_task_start(
    runtime_name: String,
    task_group_key: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    crate::qjs::qjs_call_task_start(runtime_name, task_group_key, fn_path, args_json).await
}

#[frb]
pub async fn qjs_call_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    crate::qjs::qjs_call_task_wait(runtime_name, task_id).await
}

#[frb]
pub async fn qjs_call_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<String> {
    crate::qjs::qjs_call_once(runtime_name, bundle_js, fn_path, args_json).await
}

#[frb]
pub async fn qjs_call_once_task_start(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
    task_group_key: String,
) -> Result<u64> {
    crate::qjs::qjs_call_once_task_start(
        runtime_name,
        bundle_js,
        fn_path,
        args_json,
        task_group_key,
    )
    .await
}

#[frb]
pub async fn qjs_call_once_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    crate::qjs::qjs_call_once_task_wait(runtime_name, task_id).await
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
pub async fn qjs_cancel_task(runtime_name: String, task_id: u64) -> Result<QjsCancelTaskResult> {
    crate::qjs::qjs_cancel_task(runtime_name, task_id).await
}

#[frb]
pub async fn qjs_cancel_tasks_by_group(
    runtime_name: String,
    task_group_key: String,
) -> Result<QjsCancelTasksByGroupResult> {
    crate::qjs::qjs_cancel_tasks_by_group(runtime_name, task_group_key).await
}

#[frb]
pub async fn qjs_fetch_image_bytes(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    crate::qjs::qjs_fetch_image_bytes(runtime_name, fn_path, args_json).await
}

#[frb]
pub async fn qjs_fetch_image_bytes_task_start(
    runtime_name: String,
    task_group_key: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    crate::qjs::qjs_fetch_image_bytes_task_start(runtime_name, task_group_key, fn_path, args_json)
        .await
}

#[frb]
pub async fn qjs_fetch_image_bytes_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    crate::qjs::qjs_fetch_image_bytes_task_wait(runtime_name, task_id).await
}

#[frb]
pub async fn qjs_fetch_image_bytes_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    crate::qjs::qjs_fetch_image_bytes_once(runtime_name, bundle_js, fn_path, args_json).await
}

#[frb]
pub async fn qjs_fetch_image_bytes_once_task_start(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
    task_group_key: String,
) -> Result<u64> {
    crate::qjs::qjs_fetch_image_bytes_once_task_start(
        runtime_name,
        bundle_js,
        fn_path,
        args_json,
        task_group_key,
    )
    .await
}

#[frb]
pub async fn qjs_fetch_image_bytes_once_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    crate::qjs::qjs_fetch_image_bytes_once_task_wait(runtime_name, task_id).await
}

#[frb]
pub fn set_http_proxy(proxy: String) -> Result<()> {
    crate::qjs::set_http_proxy(proxy)
}

#[frb]
pub fn set_socks5_proxy(proxy: String) -> Result<()> {
    crate::qjs::set_socks5_proxy(proxy)
}

#[frb(sync)]
pub fn set_qjs_error_stack_enabled(enabled: bool) -> Result<()> {
    crate::qjs::set_qjs_error_stack_enabled(enabled)
}

#[frb]
pub fn register_load_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    crate::qjs::register_load_plugin_config(dart_callback)
}

#[frb]
pub fn register_save_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    crate::qjs::register_save_plugin_config(dart_callback)
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
pub async fn init_qjs_runtime(name: String) -> Result<()> {
    crate::qjs::init_qjs_runtime(name).await
}

#[frb]
pub async fn is_qjs_runtime_initialized(name: String) -> Result<bool> {
    crate::qjs::is_qjs_runtime_initialized(name).await
}

#[frb]
pub async fn init_qjs_runtime_with_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    crate::qjs::init_qjs_runtime_with_bundle(runtime_name, bundle_name, bundle_js).await
}

#[frb(sync)]
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
