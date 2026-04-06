use anyhow::{Context, Result};
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;

pub struct ImageInfo {
    pub img_data: Vec<u8>,
    pub chapter_id: i32,
    pub url: String,
    pub scramble_id: i32,
    pub file_name: String,
}

// 这个东西是给禁漫用的，用来反混淆图片
pub fn segmentation_picture_to_disk(image_info: ImageInfo) -> Result<()> {
    let ImageInfo {
        img_data,
        chapter_id,
        url,
        scramble_id,
        file_name,
    } = image_info;

    tracing::debug!("{} origin {}", img_data.len(), file_name);
    let bytes = super::segmentation::segmentation_picture(img_data, chapter_id, scramble_id, &url)?;
    tracing::debug!("{} after {}", bytes.len(), file_name);
    save_image(&bytes, &file_name)?;
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
