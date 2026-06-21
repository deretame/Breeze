use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::frb;
use image::{DynamicImage, ImageFormat};
use webp::Encoder;

/// 将任意支持的图片格式转换为 WebP，并覆盖写入原路径。
///
/// [input_path] 待转换图片的本地绝对路径。
/// [image_type] 图片类型提示，例如 `png`、`jpg`、`jpeg`、`webp`、`gif`、`bmp`。
///             传入空字符串或不支持的值时会根据文件头自动识别。
///             固定使用 95.0 质量，兼顾画质与压缩率。
#[frb]
pub fn convert_image_to_webp(input_path: String, image_type: String) -> Result<()> {
    let input_bytes =
        std::fs::read(&input_path).with_context(|| format!("读取输入文件失败: {}", input_path))?;

    let img = load_image(&input_bytes, &image_type)?;
    let (width, height) = (img.width(), img.height());

    // 漫画/插画通常不需要透明通道，使用 rgb8 编码体积更小
    let rgb = img.to_rgb8();
    let encoder = Encoder::from_rgb(&rgb, width, height);
    let webp_memory = encoder.encode(95.0);

    std::fs::write(&input_path, webp_memory.to_vec())
        .with_context(|| format!("写入 WebP 文件失败: {}", input_path))?;

    Ok(())
}

/// 将图片转换为 PNG。
///
/// 格式校验（仅支持 jpg/png/非动图 webp）请在 Dart 侧完成，本函数只负责解码并输出 PNG。
/// 转换后的 PNG 写入 [output_path]。
#[frb]
pub fn convert_image_to_png(input_path: String, output_path: String) -> Result<()> {
    let input_bytes =
        std::fs::read(&input_path).with_context(|| format!("读取输入文件失败: {}", input_path))?;

    let img = image::load_from_memory(&input_bytes).map_err(|e| anyhow!("解析图片失败: {}", e))?;

    img.save_with_format(&output_path, ImageFormat::Png)
        .with_context(|| format!("写入 PNG 文件失败: {}", output_path))?;

    Ok(())
}

fn load_image(bytes: &[u8], image_type: &str) -> Result<DynamicImage> {
    let format = match image_type.to_lowercase().as_str() {
        "png" => Some(ImageFormat::Png),
        "jpg" | "jpeg" => Some(ImageFormat::Jpeg),
        "webp" => Some(ImageFormat::WebP),
        "gif" => Some(ImageFormat::Gif),
        "bmp" => Some(ImageFormat::Bmp),
        "tiff" | "tif" => Some(ImageFormat::Tiff),
        "ico" => Some(ImageFormat::Ico),
        _ => None,
    };

    let img = match format {
        Some(fmt) => image::load_from_memory_with_format(bytes, fmt),
        None => image::load_from_memory(bytes),
    }
    .map_err(|e| anyhow!("解析图片失败: {}", e))?;

    Ok(img)
}
