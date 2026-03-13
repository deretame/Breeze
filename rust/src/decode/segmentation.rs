use anyhow::{Context, Result};
use image::{ImageBuffer, ImageFormat, Rgba, RgbaImage};
use std::io::Cursor;

pub(crate) fn segmentation_picture(
    img_data: Vec<u8>,
    chapter_id: i32,
    scramble_id: i32,
    url: &str,
) -> Result<Vec<u8>> {
    let format = image::guess_format(&img_data).context("Failed to guess image format")?;

    let picture_name = url
        .rsplit('/')
        .next()
        .and_then(|name| name.split('.').next())
        .unwrap_or("");
    let num = get_segmentation_num(chapter_id, scramble_id, picture_name);

    if format == ImageFormat::Gif || num <= 1 {
        return Ok(img_data);
    }

    // 直接解码成 rgba8，方便后续按整行内存拷贝
    let src_img: RgbaImage = image::load_from_memory(&img_data)
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
    Ok(bytes)
}

fn get_segmentation_num(eps_id: i32, scramble_id: i32, picture_name: &str) -> i32 {
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

        y_pos += end - start;
    }
}
