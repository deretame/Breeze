pub mod host_runtime;
pub mod web_runtime;

pub use host_runtime::{
    AsyncHostRuntime, AsyncHostRuntimeBuilder, RuntimeJsonTaskHandle, RuntimeTaskHandle,
    RuntimeTaskStats,
    configure_js_error_stack, js_error_stack_enabled,
};
pub use web_runtime::{
    HttpClientConfig, WebRuntimeOptions, configure_http_client, configure_log_http_endpoint,
    configure_native_buffer_gc_ttl_seconds, current_http_client_config, current_log_http_endpoint,
    current_native_buffer_gc_ttl_seconds, polyfill_script, register_bridge_route_async_handler,
    register_bridge_route_blocking_handler, register_bridge_route_sync_handler,
    unregister_bridge_route_handler,
};

#[cfg(test)]
mod tests;
