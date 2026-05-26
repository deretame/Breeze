use crate::web_runtime::{configure_http_client, current_http_client_config};

pub fn run_async_script(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let previous = current_http_client_config();
    if !previous.allow_private_network {
        let mut config = previous.clone();
        config.allow_private_network = true;
        configure_http_client(config).ok();
        let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime")?;
        configure_http_client(previous).ok();
        let task = runtime.spawn(script)?;
        return task.wait().map_err(|e| e.into());
    }
    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime")?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}

pub fn run_async_script_with_fs(script: &str) -> Result<String, Box<dyn std::error::Error>> {
    let previous = current_http_client_config();
    if !previous.allow_private_network {
        let mut config = previous.clone();
        config.allow_private_network = true;
        configure_http_client(config).ok();
        let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-fs")
            .filesystem(true)
            .build()?;
        configure_http_client(previous).ok();
        let task = runtime.spawn(script)?;
        return task.wait().map_err(|e| e.into());
    }
    let runtime = crate::host_runtime::AsyncHostRuntime::builder("test-web-runtime-fs")
        .filesystem(true)
        .build()?;
    let task = runtime.spawn(script)?;
    task.wait().map_err(|e| e.into())
}
