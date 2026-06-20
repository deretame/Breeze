use crate::compressed;
use crate::decode;
use crate::frb_generated::StreamSink;
use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use rquickjs_playground::{configure_http_client, current_http_client_config};
use std::sync::Once;
use std::sync::atomic::Ordering;
use xxhash_rust::xxh3::xxh3_128;

static ENABLE_STACKTRACE: Once = Once::new();
static ENABLE_LOG: Once = Once::new();
static INIT_ONCE: Once = Once::new();

#[frb(init)]
pub fn init_app() {
    INIT_ONCE.call_once(|| {
        crate::api::user_utils::setup_default_user_utils();
        let mut config = current_http_client_config();
        config.allow_private_network = true;
        configure_http_client(config).expect("更新 HTTP 配置失败");
    });
}

#[frb]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[frb]
pub fn sleep_test() -> String {
    std::thread::sleep(std::time::Duration::from_secs(5));
    "Done".to_string()
}

#[frb]
pub fn anti_obfuscation_picture(image_info: decode::ImageInfo) -> Result<()> {
    decode::segmentation_picture_to_disk(image_info)
}

#[frb]
pub async fn compress_image(image_bytes: Vec<u8>) -> Result<String> {
    compressed::compress_image(image_bytes).await
}

#[frb]
pub fn zstd_compress_bytes(raw: Vec<u8>, level: i32) -> Result<Vec<u8>> {
    let encoded = zstd::stream::encode_all(std::io::Cursor::new(raw), level)
        .map_err(|err| anyhow!(err.to_string()))?;
    Ok(encoded)
}

#[frb]
pub fn zstd_decompress_bytes(encoded: Vec<u8>) -> Result<Vec<u8>> {
    let decoded = zstd::stream::decode_all(std::io::Cursor::new(encoded))
        .map_err(|err| anyhow!(err.to_string()))?;
    Ok(decoded)
}

#[frb]
pub async fn pack_folder(dest_path: &str, pack_info: compressed::PackInfo) -> Result<()> {
    compressed::pack_folder_zip(dest_path, pack_info).await
}

#[frb]
pub async fn pack_folder_zip(dest_path: &str, pack_info: compressed::PackInfo) -> Result<()> {
    compressed::pack_folder_zip(dest_path, pack_info).await
}

#[frb]
pub fn stream_test(stream: StreamSink<String>) -> Result<()> {
    for i in 0..10 {
        if let Err(e) = stream.add(format!("Hello, World! {}", i)) {
            let _ = stream.add_error(anyhow!("Stream error: {}", e));
        }
    }
    Ok(())
}

#[frb(sync)]
pub fn enable_stacktrace(enabled: bool) {
    ENABLE_STACKTRACE.call_once(|| unsafe {
        std::env::set_var("RUST_LIB_BACKTRACE", if enabled { "1" } else { "0" });
    });
}

#[frb(sync)]
pub fn enable_rust_log(enabled: bool) {
    println!("enable_log : {enabled}");
    ENABLE_LOG.call_once(|| {
        crate::api::user_utils::setup_log_to_console(enabled);
        crate::api::logger::FLUTTER_KDEBUGMOD.store(enabled, Ordering::Relaxed);
    });
}

#[frb]
pub async fn compress_extreme(data: Vec<u8>) -> Result<Vec<u8>> {
    compressed::compress_extreme(data).await
}

#[frb]
pub async fn decompress_extreme(data: Vec<u8>) -> Result<Vec<u8>> {
    compressed::decompress_extreme(data).await
}

#[frb(sync)]
pub fn encode_path(path: &str) -> Result<String> {
    let hash = xxh3_128(path.as_bytes()).to_string();
    Ok(format!("f_{hash}"))
}

#[frb]
pub async fn decompress_7z(archive_path: &str, dest_path: &str) -> Result<()> {
    compressed::decompress_7z(archive_path, dest_path).await
}
