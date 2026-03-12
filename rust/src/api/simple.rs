use crate::compressed;
use crate::decode;
use crate::frb_generated::StreamSink;
use anyhow::{Result, anyhow};
use flutter_rust_bridge::{DartFnFuture, frb};

#[frb(init)]
pub fn init_app() {
    crate::api::user_utils::setup_default_user_utils();
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
    let encoded = zstd::stream::encode_all(std::io::Cursor::new(raw), level)?;
    Ok(encoded)
}

#[frb]
pub fn zstd_decompress_bytes(encoded: Vec<u8>) -> Result<Vec<u8>> {
    let decoded = zstd::stream::decode_all(std::io::Cursor::new(encoded))?;
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
pub fn traditional_to_simplified(text: &str) -> String {
    decode::traditional_to_simplified(text)
}

#[frb]
pub async fn rust_calls_dart(dart_callback: impl Fn(String) -> DartFnFuture<String>) -> String {
    let name = "Tom".to_owned();
    let dart_reply = dart_callback(name).await;
    format!("Rust 收到 Dart 回调: {dart_reply}")
}
