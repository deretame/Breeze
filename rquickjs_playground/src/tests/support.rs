use crate::web_runtime::{configure_http_client, current_http_client_config};

pub fn run_async_script(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    let _ = configure_http_client(config);
    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime")?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

pub fn run_async_script_without_wasi(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    let _ = configure_http_client(config);
    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime-no-wasi")?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

pub fn run_async_script_with_fs(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    let _ = configure_http_client(config);
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-fs")
        .filesystem(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

pub fn run_async_script_with_wasi(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    let _ = configure_http_client(config);
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-wasi")
        .wasi(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

pub fn run_async_script_with_wasi_and_fs(
    script: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    let _ = configure_http_client(config);
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-wasi-fs")
        .wasi(true)
        .filesystem(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}
