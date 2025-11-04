use crate::memory::{MEMORY_TRACKER, TrackedAllocation};
use anyhow::{Context, Result};
use image::{GenericImageView, ImageBuffer, ImageFormat, Rgba};
use log::debug;
use md5;
use std::fs::{self, File};
use std::io::Cursor;
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
pub fn segmentation_picture_to_disk(image_info: ImageInfo) -> Result<()> {
    // 记录开始时的内存状态
    let start_memory = MEMORY_TRACKER.get_memory_info();
    debug!(
        "Segmentation started for {}. Current memory: {}",
        image_info.file_name, start_memory.total_allocated
    );

    // 跟踪输入图片数据的内存
    let _input_tracker = TrackedAllocation::new(image_info.img_data.len(), Some("decode_input"));

    let format =
        image::guess_format(&image_info.img_data).context("Failed to guess image format")?;

    let num = get_segmentation_num(
        image_info.chapter_id,
        image_info.scramble_id,
        &image_info
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
    let src_img =
        image::load_from_memory(&image_info.img_data).context("Failed to decode image")?;
    let (width, height) = src_img.dimensions();

    // 跟踪解码后的图片内存
    let image_memory_size = (width * height * 4) as usize; // RGBA
    let _decoded_tracker = TrackedAllocation::new(image_memory_size, Some("decoded_image"));

    let block_size = (height as f32 / num as f32).floor() as u32;
    let remainder = height % num as u32;
    let mut blocks = Vec::new();
    for i in 0..num {
        let start = (i as u32) * block_size;
        let end = if i == num - 1 {
            start + block_size + remainder
        } else {
            start + block_size
        };
        blocks.push((start, end));
    }
    let mut des_img = ImageBuffer::<Rgba<u8>, Vec<u8>>::new(width, height);

    // 跟踪目标图片缓冲区内存
    let _dest_tracker = TrackedAllocation::new(image_memory_size, Some("dest_image_buffer"));

    let mut y_pos = 0;
    for (start, end) in blocks.iter().rev() {
        let block_height = end - start;
        for y in *start..*end {
            for x in 0..width {
                let pixel = src_img.get_pixel(x, y);
                des_img.put_pixel(x, y_pos + (y - start), pixel);
            }
        }
        y_pos += block_height;
    }
    let mut bytes = Vec::new();
    let mut cursor = Cursor::new(&mut bytes);
    des_img.write_to(&mut cursor, image::ImageFormat::WebP)?;

    // 跟踪编码后的字节数据
    let _encoded_tracker = TrackedAllocation::new(bytes.len(), Some("encoded_webp"));

    save_image(&bytes, &image_info.file_name)?;

    // 记录结束时的内存状态
    let end_memory = MEMORY_TRACKER.get_memory_info();
    debug!(
        "Segmentation completed for {}. Final memory: {}",
        image_info.file_name, end_memory.total_allocated
    );
    debug!(
        "Memory diff: {} bytes",
        end_memory.total_allocated as i64 - start_memory.total_allocated as i64
    );

    Ok(())
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
