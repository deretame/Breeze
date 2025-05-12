use crate::compressed;
use crate::decode;
use anyhow::{anyhow, Result};
use reqwest;

use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
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
pub async fn async_http_get(url: &str) -> Result<String> {
    let client = reqwest::Client::new();
    let response = client.get(url).send().await?;
    response.text().await.map_err(Into::into)
}

#[frb]
pub async fn pack_folder(dest_path: &str, pack_info: compressed::PackInfo) -> Result<()> {
    compressed::pack_folder(dest_path, pack_info).await
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
