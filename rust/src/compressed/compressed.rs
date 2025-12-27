use anyhow::{Context, Result};
use base64::{Engine as _, engine::general_purpose};
use image::{ExtendedColorType, codecs::jpeg::JpegEncoder};
use log::debug;
use tokio::fs::File;

use crate::memory::TrackedAllocation;
use tokio_tar::Builder;
use tokio_tar::Header;
use zip::{CompressionMethod, ZipWriter};

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

        // 流式读取原始图片文件，避免一次性加载到内存
        let file = File::open(original_path)
            .await
            .with_context(|| format!("打开文件{}失败", original_path))?;

        // 使用打包路径将图片添加到压缩包
        let mut header = Header::new_gnu();
        header.set_size(metadata.len());

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

        // 使用流式读取，减少内存占用
        builder
            .append_data(&mut header, pack_path, file)
            .await
            .with_context(|| format!("将{}添加到压缩包失败", pack_path))?;
    }

    // 完成压缩包
    builder.finish().await.context("完成压缩包失败")?;

    Ok(())
}

// 使用ZIP格式进行压缩，内存占用更低，压缩率更好
pub async fn pack_folder_zip(dest_path: &str, pack_info: PackInfo) -> Result<()> {
    let dest_path = dest_path.to_string();
    let pack_info_clone = pack_info;

    tokio::task::spawn_blocking(move || {
        use std::fs::File;
        use std::io::{BufWriter, Read, Write};
        use zip::write::FileOptions;

        // 创建ZIP文件
        let file = File::create(&dest_path).context("创建ZIP文件失败")?;
        // 优化点：BufWriter 依然保留，减少系统调用，但可以考虑调整 buffer 大小
        // 默认 8KB 是比较平衡的，如果要进一步降低系统调用频率，可以设为 64KB-128KB，但会增加少量堆内存
        let writer = BufWriter::with_capacity(64 * 1024, file);
        let mut zip = ZipWriter::new(writer);

        // 基础配置：使用 Stored (不压缩)
        let base_options = FileOptions::<()>::default()
            .compression_method(CompressionMethod::Stored)
            .unix_permissions(0o644);

        // --- 写入元数据 JSON (这些可以用 Deflated，因为文本压缩率高，但为了统一逻辑也可以 Stored) ---
        // 文本很小，这里用 Stored 也没关系，或者单独对 JSON 用 Deflated
        zip.start_file("comic_info.json", base_options)
            .context("创建comic_info.json条目失败")?;
        zip.write_all(pack_info_clone.comic_info_string.as_bytes())
            .context("写入comic_info.json失败")?;

        zip.start_file("processed_comic_info.json", base_options)
            .context("创建processed_comic_info.json条目失败")?;
        zip.write_all(pack_info_clone.processed_comic_info_string.as_bytes())
            .context("写入processed_comic_info.json失败")?;

        // --- 处理图片 ---
        // 复用缓冲区，避免在循环中反复分配
        let mut buffer = [0u8; 64 * 1024]; // 提升到 64KB，提升大文件拷贝速度
        let _buffer_tracker = TrackedAllocation::new(64 * 1024, Some("zip_buffer"));

        for (i, original_path) in pack_info_clone.original_image_paths.iter().enumerate() {
            if i >= pack_info_clone.pack_image_paths.len() {
                break;
            }
            let pack_path = &pack_info_clone.pack_image_paths[i];

            // 打开源文件
            let mut source_file = File::open(original_path)
                .with_context(|| format!("打开文件{}失败", original_path))?;

            let current_options = base_options;

            zip.start_file(pack_path, current_options)
                .with_context(|| format!("创建ZIP条目{}失败", pack_path))?;

            // 流式拷贝
            loop {
                let bytes_read = source_file
                    .read(&mut buffer)
                    .with_context(|| format!("读取文件{}失败", original_path))?;

                if bytes_read == 0 {
                    break;
                }
                zip.write_all(&buffer[..bytes_read])
                    .with_context(|| format!("写入ZIP条目{}失败", pack_path))?;
            }
        }

        zip.finish().context("完成ZIP文件失败")?;

        Ok::<(), anyhow::Error>(())
    })
    .await
    .context("ZIP任务执行失败")?
    .context("ZIP压缩失败")?;

    Ok(())
}

/// 压缩图像并返回base64编码字符串
pub async fn compress_image(image_bytes: Vec<u8>) -> Result<String> {
    // 跟踪输入图片的内存使用
    let _input_tracker = TrackedAllocation::new(image_bytes.len(), Some("image_input"));

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
            let _rgb_tracker =
                TrackedAllocation::new(rgb_img.as_raw().len(), Some("rgb_conversion"));

            let mut encoder = JpegEncoder::new_with_quality(&mut compressed_bytes, mid);
            encoder.encode(
                rgb_img.as_raw(),
                rgb_img.width(),
                rgb_img.height(),
                ExtendedColorType::Rgb8,
            )?;

            // 跟踪压缩后的字节
            let _compressed_tracker =
                TrackedAllocation::new(compressed_bytes.len(), Some("jpeg_compressed"));
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
