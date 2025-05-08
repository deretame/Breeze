use crate::compressed;
use crate::decode;
use anyhow::Result;
use reqwest;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn sleep_test() -> String {
    std::thread::sleep(std::time::Duration::from_secs(5));
    "Done".to_string()
}

#[flutter_rust_bridge::frb]
pub fn anti_obfuscation_picture(image_info: decode::ImageInfo) -> Result<()> {
    decode::segmentation_picture_to_disk(image_info)
}

#[flutter_rust_bridge::frb]
pub async fn async_http_get(url: &str) -> Result<String> {
    let client = reqwest::Client::new();
    let response = client.get(url).send().await?;
    response.text().await.map_err(Into::into)
}

#[flutter_rust_bridge::frb]
pub async fn pack_folder(dest_path: &str, pack_info: compressed::PackInfo) -> Result<()> {
    compressed::pack_folder(dest_path, pack_info).await
}
