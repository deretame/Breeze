use anyhow::{Context, Result};
use crossbeam::channel;
use image::{GenericImageView, ImageBuffer};
use md5;
use rayon::prelude::*;
use std::fs::{self, File};
use std::io::Cursor;
use std::io::Write;
use std::path::Path;
use std::sync::Arc;

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
    let processed_data = if image_info.img_data.last() == Some(&0) {
        &image_info.img_data[..image_info.img_data.len() - 1]
    } else {
        &image_info.img_data[..]
    };
    // 1. 初始逻辑保持不变
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
    if num <= 1 {
        save_image(&processed_data, &image_info.file_name)?;
        return Ok(());
    }
    // 2. 解码图像
    let src_img = image::load_from_memory(processed_data).context("Failed to decode image")?;
    let (width, height) = src_img.dimensions();
    // 3. 计算分块
    let block_size = (height as f32 / num as f32).floor() as u32;
    let remainder = height % num as u32;
    let blocks: Vec<(u32, u32)> = (0..num)
        .map(|i| {
            let start = i as u32 * block_size;
            let end = if i == num - 1 {
                start + block_size + remainder
            } else {
                start + block_size
            };
            (start, end)
        })
        .collect();
    // 4. 创建通道用于收集处理结果
    let (sender, receiver) = channel::unbounded();
    let src_img = Arc::new(src_img);
    // 5. 并行处理每个块
    blocks
        .par_iter()
        .rev()
        .for_each_with(sender, |s, (start, end)| {
            let block_height = end - start;
            let y_offset = blocks
                .iter()
                .rev()
                .take_while(|&(s, _)| s > start)
                .map(|(s, e)| e - s)
                .sum::<u32>();
            // 为每个块创建临时缓冲区
            let mut block_buf = ImageBuffer::new(width, block_height);
            // 处理块内像素
            for y in *start..*end {
                let rel_y = y - start;
                for x in 0..width {
                    let pixel = src_img.get_pixel(x, y);
                    block_buf.put_pixel(x, rel_y, pixel);
                }
            }
            // 发送处理结果到主线程
            s.send((y_offset, block_buf)).unwrap();
        });
    // 6. 在主线程合并所有块
    let mut des_img = ImageBuffer::new(width, height);
    for (y_offset, block_buf) in receiver {
        for y in 0..block_buf.height() {
            for x in 0..width {
                des_img.put_pixel(x, y_offset + y, *block_buf.get_pixel(x, y));
            }
        }
    }
    // 7. 编码保存
    let mut bytes = Vec::new();
    des_img.write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::WebP)?;
    save_image(&bytes, &image_info.file_name)?;
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
