#[path = "../../src/decode/segmentation.rs"]
mod segmentation_impl;

pub fn segmentation_picture(
    img_data: Vec<u8>,
    chapter_id: i32,
    scramble_id: i32,
    url: &str,
) -> anyhow::Result<Vec<u8>> {
    segmentation_impl::segmentation_picture(img_data, chapter_id, scramble_id, url)
}
