use anyhow::{Context, Result};
use base64::{engine::general_purpose, Engine as _};
use image::{codecs::jpeg::JpegEncoder, ExtendedColorType};
use log::debug;
use tokio::fs::File;
use tokio_tar::Builder;
use tokio_tar::Header;

#[derive(Debug)]
pub struct PackInfo {
    pub comic_info_string: String,
    pub processed_comic_info_string: String,
    pub original_image_paths: Vec<String>,
    pub pack_image_paths: Vec<String>,
}

// 流式的把一堆文件打包为一个tar文件
pub async fn pack_folder(dest_path: &str, pack_info: PackInfo) -> Result<()> {
    // 创建tar文件
    let file = File::create(dest_path).await.context("创建tar文件失败")?;
    let mut builder = Builder::new(file);

    // 将comic_info_string.json添加到压缩包
    let comic_info_bytes = pack_info.comic_info_string.as_bytes();
    let mut header = Header::new_gnu();
    header.set_size(comic_info_bytes.len() as u64);
    header.set_mode(0o644);
    header.set_mtime(
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
    );
    builder
        .append_data(&mut header, "comic_info.json", comic_info_bytes)
        .await
        .context("将comic_info_string.json添加到压缩包失败")?;

    // 将processed_comic_info_string.json添加到压缩包
    let processed_info_bytes = pack_info.processed_comic_info_string.as_bytes();
    let mut header = Header::new_gnu();
    header.set_size(processed_info_bytes.len() as u64);
    header.set_mode(0o644);
    header.set_mtime(
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
    );
    builder
        .append_data(
            &mut header,
            "processed_comic_info.json",
            processed_info_bytes,
        )
        .await
        .context("将processed_comic_info_string.json添加到压缩包失败")?;

    // 处理每对图片路径
    for (i, original_path) in pack_info.original_image_paths.iter().enumerate() {
        if i >= pack_info.pack_image_paths.len() {
            break;
        }

        let pack_path = &pack_info.pack_image_paths[i];

        // 首先获取文件元数据以保留权限和修改时间
        let metadata = tokio::fs::metadata(original_path)
            .await
            .with_context(|| format!("获取{}的元数据失败", original_path))?;

        // 读取原始图片
        let image_data = tokio::fs::read(original_path)
            .await
            .with_context(|| format!("从{}读取图片失败", original_path))?;

        // 使用打包路径将图片添加到压缩包
        let mut header = Header::new_gnu();
        header.set_size(image_data.len() as u64);

        // 保留文件权限
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = metadata.permissions().mode();
            header.set_mode(mode);
        }
        #[cfg(not(unix))]
        {
            // 在非Unix平台上使用标准权限
            header.set_mode(0o644);
        }

        // 保留修改时间
        let mtime = metadata
            .modified()
            .unwrap_or_else(|_| std::time::SystemTime::now())
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        header.set_mtime(mtime);

        let reader = tokio::io::BufReader::new(std::io::Cursor::new(image_data));
        builder
            .append_data(&mut header, pack_path, reader)
            .await
            .with_context(|| format!("将{}添加到压缩包失败", pack_path))?;
    }

    // 完成压缩包
    builder.finish().await.context("完成压缩包失败")?;

    Ok(())
}

/// 压缩图像并返回base64编码字符串
///
/// # 参数
/// * `file_path` - 原始图像文件路径
///
/// # 返回值
/// * `Result<String>` - 压缩后的base64编码字符串
pub async fn compress_image(file_path: &str) -> Result<String> {
    let image_bytes = tokio::fs::read(file_path).await?;
    let img = image::load_from_memory(&image_bytes)?;

    let mut low = 1u8;
    let mut high = 100u8;
    let mut best_quality = 100;
    let mut best_bytes = Vec::new();

    // 二分法查找最佳 quality
    while low <= high {
        let mid = (low + high) / 2;
        let mut compressed_bytes = Vec::new();

        {
            let rgb_img = img.to_rgb8();
            let mut encoder = JpegEncoder::new_with_quality(&mut compressed_bytes, mid);
            encoder.encode(
                rgb_img.as_raw(),
                rgb_img.width(),
                rgb_img.height(),
                ExtendedColorType::Rgb8,
            )?;
        }

        let current_size = general_purpose::STANDARD.encode(&compressed_bytes).len();

        if current_size <= 689493 {
            // 当前 quality 满足条件，尝试更高 quality
            best_quality = mid;
            best_bytes = compressed_bytes;
            low = mid + 1;
        } else {
            // 当前 quality 过大，尝试更低 quality
            high = mid - 1;
        }

        debug!("Quality: {}, Size: {}", mid, current_size);
    }

    let final_base64 = general_purpose::STANDARD.encode(&best_bytes);
    debug!(
        "Final Quality: {}, Size: {}",
        best_quality,
        final_base64.len()
    );
    Ok(final_base64)
}
