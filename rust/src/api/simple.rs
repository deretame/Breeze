use crate::compressed;
use crate::decode;
use crate::frb_generated::StreamSink;
use anyhow::anyhow;
use flutter_rust_bridge::frb;

use crate::api::error::FrbError;

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
pub fn anti_obfuscation_picture(
    image_info: decode::ImageInfo,
) -> std::result::Result<(), FrbError> {
    decode::segmentation_picture_to_disk(image_info).map_err(Into::into)
}

#[frb]
pub async fn compress_image(image_bytes: Vec<u8>) -> std::result::Result<String, FrbError> {
    compressed::compress_image(image_bytes)
        .await
        .map_err(Into::into)
}

#[frb]
pub fn zstd_compress_bytes(raw: Vec<u8>, level: i32) -> std::result::Result<Vec<u8>, FrbError> {
    let encoded = zstd::stream::encode_all(std::io::Cursor::new(raw), level)
        .map_err(|err| anyhow!(err.to_string()))?;
    Ok(encoded)
}

#[frb]
pub fn zstd_decompress_bytes(encoded: Vec<u8>) -> std::result::Result<Vec<u8>, FrbError> {
    let decoded = zstd::stream::decode_all(std::io::Cursor::new(encoded))
        .map_err(|err| anyhow!(err.to_string()))?;
    Ok(decoded)
}

#[frb]
pub async fn pack_folder(
    dest_path: &str,
    pack_info: compressed::PackInfo,
) -> std::result::Result<(), FrbError> {
    compressed::pack_folder_zip(dest_path, pack_info)
        .await
        .map_err(Into::into)
}

#[frb]
pub async fn pack_folder_zip(
    dest_path: &str,
    pack_info: compressed::PackInfo,
) -> std::result::Result<(), FrbError> {
    compressed::pack_folder_zip(dest_path, pack_info)
        .await
        .map_err(Into::into)
}

#[frb]
pub fn stream_test(stream: StreamSink<String>) -> std::result::Result<(), FrbError> {
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
