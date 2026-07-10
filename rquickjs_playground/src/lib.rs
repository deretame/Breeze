pub mod host_runtime;
pub mod html;
pub mod i18n;
pub mod source_map;
pub mod web_runtime;

pub use i18n::{
    ErrorMessageLang, current_error_message_language, format_message, set_error_message_language, t,
};

pub use host_runtime::{
    AsyncHostRuntime, AsyncHostRuntimeBuilder, RuntimeJsonTaskHandle, RuntimeTaskHandle,
    RuntimeTaskStats, configure_js_error_stack, js_error_stack_enabled,
};
pub use web_runtime::{
    BridgeRuntimeConfig, HttpClientConfig, WebRuntimeOptions, configure_bridge_runtime,
    configure_http_client, configure_log_http_endpoint, configure_native_buffer_gc_ttl_seconds,
    current_bridge_runtime_config, current_http_client_config, current_log_http_endpoint,
    current_native_buffer_gc_ttl_seconds, forward_log_line, polyfill_script,
    register_bridge_route_async_handler, register_bridge_route_blocking_handler,
    register_bridge_route_sync_handler, unregister_bridge_route_handler,
};

#[cfg(test)]
mod tests;
