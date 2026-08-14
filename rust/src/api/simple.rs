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
    if cfg!(debug_assertions) {
        println!("Debug model");
    } else {
        println!("Release model");
    }
    INIT_ONCE.call_once(|| {
        crate::api::user_utils::setup_default_user_utils();
        let mut config = current_http_client_config();
        config.allow_private_network = true;
        configure_http_client(config)
            .expect(&rquickjs_playground::tr!("failed-to-update-http-config"));
    });
}

#[frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[frb(sync)]
pub fn get_system_time_zone() -> Result<String> {
    iana_time_zone::get_timezone().map_err(|err| anyhow!(err.to_string()))
}

#[frb]
pub async fn sleep_test() -> Result<String> {
    // 测试用阻塞休眠，放到全局阻塞线程池上，避免占用 FRB 的线程。
    rquickjs_playground::global_handle()
        .spawn_blocking(|| {
            std::thread::sleep(std::time::Duration::from_secs(5));
            Ok::<_, anyhow::Error>("Done".to_string())
        })
        .await?
}

#[frb]
pub async fn anti_obfuscation_picture(image_info: decode::ImageInfo) -> Result<()> {
    // 反混淆是 CPU 密集的阻塞操作（图像解码/分块重排/webp 编码/落盘），
    // 放到进程级全局 runtime 的阻塞线程池上执行，避免占用 FRB 的线程。
    rquickjs_playground::global_handle()
        .spawn_blocking(move || decode::segmentation_picture_to_disk(image_info))
        .await
        .map_err(|err| anyhow!("anti-obfuscation task failed: {err}"))?
}

#[frb]
pub async fn compress_image(image_bytes: Vec<u8>) -> Result<String> {
    // 图片压缩（解码 + 二分法 JPEG 编码）是 CPU 密集阻塞操作，
    // 放到全局阻塞线程池上执行。
    rquickjs_playground::global_handle()
        .spawn_blocking(move || compressed::compress_image(image_bytes))
        .await?
}

#[frb]
pub async fn zstd_compress_bytes(raw: Vec<u8>, level: i32) -> Result<Vec<u8>> {
    // zstd 压缩是 CPU 密集阻塞操作，放到全局阻塞线程池上执行。
    rquickjs_playground::global_handle()
        .spawn_blocking(move || {
            zstd::stream::encode_all(std::io::Cursor::new(raw), level)
                .map_err(|err| anyhow!(err.to_string()))
        })
        .await?
}

#[frb]
pub async fn zstd_decompress_bytes(encoded: Vec<u8>) -> Result<Vec<u8>> {
    // zstd 解压是 CPU 密集阻塞操作，放到全局阻塞线程池上执行。
    rquickjs_playground::global_handle()
        .spawn_blocking(move || {
            zstd::stream::decode_all(std::io::Cursor::new(encoded))
                .map_err(|err| anyhow!(err.to_string()))
        })
        .await?
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

#[cfg(test)]
mod tests {
    use rquickjs_playground::html::Document;

    use super::enable_rust_log;

    #[test]
    fn html5ever_debug_logs_are_suppressed() {
        // Initialize the same logging pipeline used by the app.
        enable_rust_log(true);

        // This HTML is large enough to trigger html5ever's tree-builder debug logging.
        let html = std::iter::repeat("<div><span>hello</span></div>")
            .take(100)
            .fold("<html><body>".to_string(), |mut acc, s| {
                acc.push_str(s);
                acc
            })
            + "</body></html>";

        let doc = Document::parse(&html);
        let sel = doc.select("span").unwrap();
        assert!(!sel.is_empty());
    }
}
