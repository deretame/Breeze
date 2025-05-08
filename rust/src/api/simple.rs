use reqwest;
use tokio::runtime::Runtime;

use crate::image_decode::decode;

#[flutter_rust_bridge::frb] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn sleep_test() -> String {
    std::thread::sleep(std::time::Duration::from_secs(5));
    "Done".to_string()
}

#[flutter_rust_bridge::frb]
pub fn anti_obfuscation_picture(
    img_data: Vec<u8>,
    chapter_id: i32,
    url: String,
    scramble_id: i32,
    file_name: String,
) -> anyhow::Result<()> {
    let processed_data = if img_data.last() == Some(&0) {
        &img_data[..img_data.len() - 1]
    } else {
        &img_data[..]
    };
    let eps_id = chapter_id;
    let scramble_id = scramble_id;
    let picture_name = url.split('/').last().unwrap().split('.').next().unwrap();
    decode::segmentation_picture_to_disk(
        processed_data,
        eps_id,
        scramble_id,
        picture_name.to_string(),
        file_name,
    )
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb]
pub fn sync_http_get(url: &str) -> Result<String, anyhow::Error> {
    // 创建Tokio运行时
    let rt = Runtime::new()?;

    // 使用block_on执行异步代码
    rt.block_on(async {
        let client = reqwest::Client::new();
        let response = client.get(url).send().await?;
        response.text().await.map_err(Into::into)
    })
}
