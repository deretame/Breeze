use anyhow::{Context, Result};
use flate2::read::GzDecoder;
use image::{ImageBuffer, ImageFormat, Rgba, RgbaImage};
use md5;
use std::fs::{self, File};
use std::io::Cursor;
use std::io::Read;
use std::io::Write;
use std::path::Path;

pub struct ImageInfo {
    pub img_data: Vec<u8>,
    pub chapter_id: i32,
    pub url: String,
    pub scramble_id: i32,
    pub file_name: String,
}

pub(crate) fn get_segmentation_num(eps_id: i32, scramble_id: i32, picture_name: &str) -> i32 {
    if eps_id < scramble_id {
        0
    } else if eps_id < 268850 {
        10
    } else if eps_id > 421926 {
        let s = format!("{}{}", eps_id, picture_name);
        let digest = md5::compute(s);
        let hash_str = format!("{:x}", digest);
        let last_char = hash_str.chars().last().unwrap() as u8;
        (last_char % 8) as i32 * 2 + 2
    } else {
        let s = format!("{}{}", eps_id, picture_name);
        let digest = md5::compute(s);
        let hash_str = format!("{:x}", digest);
        let last_char = hash_str.chars().last().unwrap() as u8;
        (last_char % 10) as i32 * 2 + 2
    }
}

// 这个东西是给禁漫用的，用来反混淆图片
pub fn segmentation_picture_to_disk(mut image_info: ImageInfo) -> Result<()> {
    // 检查是否是 Gzip 压缩数据 (Magic Bytes: 1F 8B)
    if image_info.img_data.len() > 2
        && image_info.img_data[0] == 0x1f
        && image_info.img_data[1] == 0x8b
    {
        log::info!(
            "检测到 Gzip 压缩数据，正在解压...: {}",
            image_info.file_name
        );

        let mut decoder = GzDecoder::new(&image_info.img_data[..]);
        let mut decompressed_data = Vec::new();
        match decoder.read_to_end(&mut decompressed_data) {
            Ok(_) => {
                image_info.img_data = decompressed_data;
                log::info!("解压成功，新数据大小: {}", image_info.img_data.len());
            }
            Err(e) => {
                log::warn!("尝试解压 Gzip 失败: {}, 保留原数据", e);
            }
        }
    }

    let format =
        image::guess_format(&image_info.img_data).context("Failed to guess image format")?;

    let num = get_segmentation_num(
        image_info.chapter_id,
        image_info.scramble_id,
        image_info
            .url
            .split('/')
            .last()
            .unwrap()
            .split('.')
            .next()
            .unwrap(),
    );

    if format == ImageFormat::Gif || num <= 1 {
        save_image(&image_info.img_data, &image_info.file_name)?;
        return Ok(());
    }

    // 直接解码成 rgba8，方便后续按整行内存拷贝
    let src_img: RgbaImage = image::load_from_memory(&image_info.img_data)
        .context("Failed to decode image")?
        .to_rgba8();

    let (width, height) = src_img.dimensions();
    let block_size = height / num as u32;
    let remainder = height % num as u32;

    let mut blocks = Vec::with_capacity(num as usize);
    for i in 0..num {
        let start = i as u32 * block_size;
        let end = if i == num - 1 {
            start + block_size + remainder
        } else {
            start + block_size
        };
        blocks.push((start, end));
    }

    let mut des_img: RgbaImage = ImageBuffer::<Rgba<u8>, Vec<u8>>::new(width, height);

    rearrange_blocks_by_block(&src_img, &mut des_img, &blocks);

    let mut bytes = Vec::new();
    let mut cursor = Cursor::new(&mut bytes);
    des_img.write_to(&mut cursor, image::ImageFormat::WebP)?;
    save_image(&bytes, &image_info.file_name)?;
    Ok(())
}

fn rearrange_blocks_by_block(src: &RgbaImage, dst: &mut RgbaImage, blocks: &[(u32, u32)]) {
    let width = src.width() as usize;
    let row_bytes = width * 4;

    let src_raw = src.as_raw();
    let dst_raw = dst.as_mut();

    let mut y_pos = 0u32;

    for &(start, end) in blocks.iter().rev() {
        let block_height = (end - start) as usize;

        let src_begin = start as usize * row_bytes;
        let src_end = src_begin + block_height * row_bytes;

        let dst_begin = y_pos as usize * row_bytes;
        let dst_end = dst_begin + block_height * row_bytes;

        dst_raw[dst_begin..dst_end].copy_from_slice(&src_raw[src_begin..src_end]);

        y_pos += (end - start);
    }
}

fn save_image(data: &[u8], file_path: &str) -> Result<()> {
    let path = Path::new(file_path);
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).context(format!("Failed to create directory: {:?}", parent))?;
    }
    File::create(path)
        .and_then(|mut file| file.write_all(data))
        .context(format!("Failed to write file: {}", file_path))?;
    Ok(())
}

// 繁体转简体
pub fn traditional_to_simplified(text: &str) -> String {
    zhconv::zhconv(text, zhconv::Variant::ZhCN)
}
