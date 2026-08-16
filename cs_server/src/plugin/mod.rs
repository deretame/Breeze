use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use serde_json::Value;

#[derive(Clone, Debug)]
pub struct PluginRuntimeCapabilities {
    pub quickjs: bool,
    pub filesystem: bool,
    pub cancellation: bool,
}

impl Default for PluginRuntimeCapabilities {
    fn default() -> Self {
        let options = runtime_options();
        Self {
            quickjs: true,
            filesystem: options.fs,
            cancellation: true,
        }
    }
}

pub fn runtime_options() -> rquickjs_playground::WebRuntimeOptions {
    rquickjs_playground::WebRuntimeOptions { fs: false }
}

/// 按用户隔离 QuickJS runtime，插件默认只能使用 Web Runtime 能力，不能访问宿主文件系统。
pub struct PluginRuntimeService {
    options: rquickjs_playground::WebRuntimeOptions,
    runtimes: Mutex<HashMap<String, Arc<rquickjs_playground::AsyncHostRuntime>>>,
}

impl PluginRuntimeService {
    pub fn new() -> Self {
        Self {
            options: runtime_options(),
            runtimes: Mutex::new(HashMap::new()),
        }
    }

    pub async fn invoke_json(
        &self,
        user_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Value, String> {
        if bundle_source.len() > 8 * 1024 * 1024 {
            return Err("plugin bundle exceeds 8 MiB limit".to_owned());
        }
        if fn_path.trim().is_empty() || !args.is_array() {
            return Err("plugin function path and array arguments are required".to_owned());
        }
        let runtime = self.runtime_for_user(user_id)?;
        runtime.bundle_call_once(bundle_source, fn_path, args).await
    }

    pub async fn invoke_bytes(
        &self,
        user_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Vec<u8>, String> {
        if bundle_source.len() > 8 * 1024 * 1024 {
            return Err("plugin bundle exceeds 8 MiB limit".to_owned());
        }
        if fn_path.trim().is_empty() || !args.is_array() {
            return Err("plugin function path and array arguments are required".to_owned());
        }
        let runtime = self.runtime_for_user(user_id)?;
        runtime
            .bundle_call_once_bytes(bundle_source, fn_path, args)
            .await
    }

    fn runtime_for_user(
        &self,
        user_id: &str,
    ) -> Result<Arc<rquickjs_playground::AsyncHostRuntime>, String> {
        let mut runtimes = self
            .runtimes
            .lock()
            .map_err(|_| "plugin runtime lock poisoned".to_owned())?;
        if let Some(runtime) = runtimes.get(user_id) {
            return Ok(Arc::clone(runtime));
        }
        let runtime = rquickjs_playground::AsyncHostRuntime::new_with_options(
            format!("cs-server-user-{user_id}"),
            self.options,
        )
        .map_err(|error| format!("failed to initialize plugin runtime: {error}"))?;
        let runtime = Arc::new(runtime);
        runtimes.insert(user_id.to_owned(), Arc::clone(&runtime));
        Ok(runtime)
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::PluginRuntimeService;

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn invokes_a_bundle_in_a_user_scoped_runtime() {
        let service = PluginRuntimeService::new();
        let source = r#"
            module.exports = {
              echo: async (value) => ({ value }),
            };
        "#;
        let result = service
            .invoke_json("user-1", source, "echo", &json!(["hello"]))
            .await
            .expect("plugin invocation should succeed");
        assert_eq!(result, json!({"value": "hello"}));
    }
}
