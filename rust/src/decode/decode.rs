use anyhow::{Context, Result, bail};
use image::GenericImageView;
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use webp::Encoder;

const SCRAMBLE_ID: i32 = 220980;

pub struct ImageInfo {
    pub img_data: Vec<u8>,
    pub chapter_id: i32,
    pub url: String,
    pub file_name: String,
}

/// 描述一块需要从原图中裁剪出来的区域。
#[derive(Debug, Deserialize)]
pub struct ImageCropRegion {
    pub number: i32,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

/// 一块裁剪后的图片，`img_data` 为 WebP 编码后的图片数据。
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CroppedImage {
    pub number: i32,
    pub img_data: Vec<u8>,
}

/// 按给定的矩形区域裁剪图片。
///
/// 返回结果的顺序与 `regions` 的顺序一致，`number` 会从输入区域原样带回。
/// 所有裁剪结果都使用质量为 75 的 WebP 编码，并保留原图的透明通道。
pub fn crop_image_by_regions(
    image_data: Vec<u8>,
    regions: Vec<ImageCropRegion>,
) -> Result<Vec<CroppedImage>> {
    let image = image::load_from_memory(&image_data).context("Failed to decode image")?;
    let (image_width, image_height) = image.dimensions();

    regions
        .into_iter()
        .map(|region| {
            if region.width == 0 || region.height == 0 {
                bail!(
                    "Crop region {} must have a non-zero width and height",
                    region.number
                );
            }

            let right = region.x.checked_add(region.width).with_context(|| {
                format!(
                    "Crop region {} has an overflowing x coordinate",
                    region.number
                )
            })?;
            let bottom = region.y.checked_add(region.height).with_context(|| {
                format!(
                    "Crop region {} has an overflowing y coordinate",
                    region.number
                )
            })?;

            if right > image_width || bottom > image_height {
                bail!(
                    "Crop region {} ({}, {}, {}, {}) is outside image bounds ({}x{})",
                    region.number,
                    region.x,
                    region.y,
                    region.width,
                    region.height,
                    image_width,
                    image_height
                );
            }

            let cropped = image.crop_imm(region.x, region.y, region.width, region.height);
            let cropped_rgba = cropped.to_rgba8();
            let encoder = Encoder::from_rgba(cropped_rgba.as_raw(), region.width, region.height);
            let webp_memory = encoder.encode(75.0);

            Ok(CroppedImage {
                number: region.number,
                img_data: webp_memory.to_vec(),
            })
        })
        .collect()
}

// 这个东西是给禁漫用的，用来反混淆图片
pub fn segmentation_picture_to_disk(image_info: ImageInfo) -> Result<()> {
    let ImageInfo {
        img_data,
        chapter_id,
        url,
        file_name,
    } = image_info;

    let bytes = super::segmentation::segmentation_picture(img_data, chapter_id, SCRAMBLE_ID, &url)?;
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

#[cfg(test)]
mod tests {
    use super::{CroppedImage, ImageCropRegion, crop_image_by_regions};
    use image::{DynamicImage, GenericImageView, ImageBuffer, ImageFormat, Rgba, RgbaImage};
    use std::io::Cursor;

    fn test_image_data() -> Vec<u8> {
        let image: RgbaImage = ImageBuffer::from_fn(4, 2, |x, y| {
            if y == 0 {
                match x {
                    0 => Rgba([255, 0, 0, 255]),
                    1 => Rgba([0, 255, 0, 255]),
                    2 => Rgba([0, 0, 255, 255]),
                    _ => Rgba([255, 255, 255, 255]),
                }
            } else {
                Rgba([x as u8, y as u8, 0, 255])
            }
        });

        let mut output = Cursor::new(Vec::new());
        DynamicImage::ImageRgba8(image)
            .write_to(&mut output, ImageFormat::Png)
            .expect("encode test image");
        output.into_inner()
    }

    #[test]
    fn crops_regions_in_input_order() {
        let regions = vec![
            ImageCropRegion {
                number: 2,
                x: 2,
                y: 0,
                width: 2,
                height: 2,
            },
            ImageCropRegion {
                number: 1,
                x: 0,
                y: 0,
                width: 2,
                height: 1,
            },
        ];

        let result = crop_image_by_regions(test_image_data(), regions).expect("crop image");

        assert_eq!(
            result.iter().map(|item| item.number).collect::<Vec<_>>(),
            [2, 1]
        );

        let first: CroppedImage = result.into_iter().next().expect("first crop");
        assert_eq!(&first.img_data[0..4], b"RIFF");
        assert_eq!(&first.img_data[8..12], b"WEBP");
        let first_image = image::load_from_memory(&first.img_data).expect("decode first crop");
        assert_eq!(first_image.dimensions(), (2, 2));
        let first_pixel = first_image.get_pixel(0, 0);
        assert!(first_pixel[2] > first_pixel[0]);
        assert!(first_pixel[2] > first_pixel[1]);
    }

    #[test]
    fn rejects_regions_outside_image_bounds() {
        let region = ImageCropRegion {
            number: 1,
            x: 3,
            y: 0,
            width: 2,
            height: 1,
        };

        let error =
            crop_image_by_regions(test_image_data(), vec![region]).expect_err("bounds error");
        assert!(error.to_string().contains("outside image bounds"));
    }
}
