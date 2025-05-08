use anyhow::{Context, Result};
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
    // Create the tar file
    let file = File::create(dest_path)
        .await
        .context("Failed to create tar file")?;
    let mut builder = Builder::new(file);

    // Add comic_info_string.json to the archive
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
        .context("Failed to add comic_info_string.json to archive")?;

    // Add processed_comic_info_string.json to the archive
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
        .context("Failed to add processed_comic_info_string.json to archive")?;

    // Process each pair of image paths
    for (i, original_path) in pack_info.original_image_paths.iter().enumerate() {
        if i >= pack_info.pack_image_paths.len() {
            break;
        }

        let pack_path = &pack_info.pack_image_paths[i];

        // Read the original image
        let image_data = tokio::fs::read(original_path)
            .await
            .with_context(|| format!("Failed to read image from {}", original_path))?;

        // Add the image to the archive with the pack path
        let mut header = Header::new_gnu();
        header.set_size(image_data.len() as u64);
        header.set_mode(0o644);
        header.set_mtime(
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        );

        let reader = tokio::io::BufReader::new(std::io::Cursor::new(image_data));
        builder
            .append_data(&mut header, pack_path, reader)
            .await
            .with_context(|| format!("Failed to add {} to archive", pack_path))?;
    }

    // Finish the archive
    builder
        .finish()
        .await
        .context("Failed to finish the archive")?;

    Ok(())
}
