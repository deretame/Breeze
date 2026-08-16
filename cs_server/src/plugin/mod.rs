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
