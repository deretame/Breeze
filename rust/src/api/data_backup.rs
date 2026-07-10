use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use zip::{CompressionMethod, ZipWriter, write::FileOptions};

/// 流式创建应用数据备份 zip。
///
/// - `data_dir` 下的所有文件/目录会放到 zip 根目录；Dart 侧应在这里准备好
///   `config.json` 与 `objectbox.json`。
/// - 若 `download_dir` 不为空，则其下所有内容会以 `downloads/` 为前缀打包。
/// - 全部使用 Stored（不压缩）方式写入，避免对图片等已压缩数据做无效压缩。
#[frb]
pub async fn create_data_backup_zip(
    zip_path: String,
    data_dir: String,
    download_dir: Option<String>,
) -> Result<()> {
    tokio::task::spawn_blocking(move || {
        let file = File::create(&zip_path).with_context(|| {
            rquickjs_playground::i18n_fmt!("创建备份 zip 文件失败: {0}", zip_path)
        })?;
        let writer = BufWriter::with_capacity(64 * 1024, file);
        let mut zip = ZipWriter::new(writer);

        let options = FileOptions::<()>::default()
            .compression_method(CompressionMethod::Stored)
            .unix_permissions(0o644);

        // 1. 写入数据文件（config.json / objectbox.json 等）
        add_directory_to_zip(&mut zip, &data_dir, "", &options).with_context(|| {
            rquickjs_playground::i18n_fmt!("向 zip 添加数据目录失败: {0}", data_dir)
        })?;

        // 2. 可选：写入下载的漫画文件
        if let Some(dir) = download_dir {
            if !dir.is_empty() && Path::new(&dir).exists() {
                add_directory_to_zip(&mut zip, &dir, "downloads", &options).with_context(|| {
                    rquickjs_playground::i18n_fmt!("向 zip 添加下载目录失败: {0}", dir)
                })?;
            }
        }

        zip.finish()
            .context(rquickjs_playground::i18n_fmt!("完成 zip 写入失败"))?;
        Ok::<(), anyhow::Error>(())
    })
    .await
    .context(rquickjs_playground::i18n_fmt!("zip 备份任务执行失败"))?
}

/// 从数据备份 zip 中直接读取 config.json 内容。
#[frb]
pub async fn read_data_backup_config(zip_path: String) -> Result<String> {
    tokio::task::spawn_blocking(move || {
        let file = File::open(&zip_path)
            .with_context(|| rquickjs_playground::i18n_fmt!("打开备份 zip 失败: {0}", zip_path))?;
        let mut archive = zip::ZipArchive::new(file)
            .with_context(|| rquickjs_playground::i18n_fmt!("读取 zip 失败: {0}", zip_path))?;

        let mut entry = archive
            .by_name("config.json")
            .with_context(|| rquickjs_playground::i18n_fmt!("备份包中缺少 config.json"))?;

        let mut content = String::new();
        entry
            .read_to_string(&mut content)
            .with_context(|| rquickjs_playground::i18n_fmt!("读取 config.json 失败"))?;

        Ok::<String, anyhow::Error>(content)
    })
    .await
    .context(rquickjs_playground::i18n_fmt!("读取备份配置任务执行失败"))?
}

/// 将数据备份 zip 解压到目标目录。
#[frb]
pub async fn extract_data_backup_zip(zip_path: String, extract_dir: String) -> Result<()> {
    tokio::task::spawn_blocking(move || {
        std::fs::create_dir_all(&extract_dir).with_context(|| {
            rquickjs_playground::i18n_fmt!("创建解压目录失败: {0}", extract_dir)
        })?;

        let file = File::open(&zip_path)
            .with_context(|| rquickjs_playground::i18n_fmt!("打开备份 zip 失败: {0}", zip_path))?;
        let mut archive = zip::ZipArchive::new(file)
            .with_context(|| rquickjs_playground::i18n_fmt!("读取 zip 失败: {0}", zip_path))?;

        let extract_root = PathBuf::from(&extract_dir);
        let mut buffer = [0u8; 64 * 1024];

        for i in 0..archive.len() {
            let mut entry = archive
                .by_index(i)
                .with_context(|| rquickjs_playground::i18n_fmt!("读取 zip 第 {0} 个条目失败", i))?;

            let entry_path = entry.name().to_string();

            // 简单防御 zip slip：拒绝包含 .. 的路径
            if entry_path.split('/').any(|s| s == "..") {
                anyhow::bail!(rquickjs_playground::i18n_fmt!(
                    "发现非法 zip 条目路径: {0}",
                    entry_path
                ));
            }

            let target_path = extract_root.join(&entry_path);

            if entry.is_dir() {
                std::fs::create_dir_all(&target_path).with_context(|| {
                    rquickjs_playground::i18n_fmt!("创建目录失败: {0}", target_path.display())
                })?;
                continue;
            }

            if let Some(parent) = target_path.parent() {
                std::fs::create_dir_all(parent).with_context(|| {
                    rquickjs_playground::i18n_fmt!("创建父目录失败: {0}", parent.display())
                })?;
            }

            let mut out_file = File::create(&target_path).with_context(|| {
                rquickjs_playground::i18n_fmt!("创建文件失败: {0}", target_path.display())
            })?;

            loop {
                let n = entry.read(&mut buffer).with_context(|| {
                    rquickjs_playground::i18n_fmt!("读取 zip 条目失败: {0}", entry_path)
                })?;
                if n == 0 {
                    break;
                }
                out_file.write_all(&buffer[..n]).with_context(|| {
                    rquickjs_playground::i18n_fmt!("写入文件失败: {0}", target_path.display())
                })?;
            }
        }

        Ok::<(), anyhow::Error>(())
    })
    .await
    .context(rquickjs_playground::i18n_fmt!("zip 解压任务执行失败"))?
}

/// 递归把 `src_dir` 下的文件/目录写入 zip；`zip_prefix` 控制 zip 内的前缀路径。
fn add_directory_to_zip<W: Write + std::io::Seek>(
    zip: &mut ZipWriter<W>,
    src_dir: &str,
    zip_prefix: &str,
    options: &FileOptions<()>,
) -> Result<()> {
    let src_path = Path::new(src_dir);
    if !src_path.exists() {
        return Ok(());
    }

    let entries = std::fs::read_dir(src_path)
        .with_context(|| rquickjs_playground::i18n_fmt!("读取目录失败: {0}", src_dir))?;

    for entry in entries {
        let entry = entry
            .with_context(|| rquickjs_playground::i18n_fmt!("读取目录项失败: {0}", src_dir))?;
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();

        let zip_name = if zip_prefix.is_empty() {
            name
        } else {
            format!("{}/{}", zip_prefix, name)
        };

        if path.is_dir() {
            zip.add_directory(&zip_name, *options).with_context(|| {
                rquickjs_playground::i18n_fmt!("向 zip 添加目录失败: {0}", zip_name)
            })?;
            add_directory_to_zip(zip, path.to_str().unwrap_or(""), &zip_name, options)
                .with_context(|| {
                    rquickjs_playground::i18n_fmt!("递归添加目录失败: {0}", path.display())
                })?;
        } else {
            add_file_to_zip(zip, &path, &zip_name, options).with_context(|| {
                rquickjs_playground::i18n_fmt!("向 zip 添加文件失败: {0}", path.display())
            })?;
        }
    }

    Ok(())
}

fn add_file_to_zip<W: Write + std::io::Seek>(
    zip: &mut ZipWriter<W>,
    src_path: &Path,
    zip_name: &str,
    options: &FileOptions<()>,
) -> Result<()> {
    let mut src_file = File::open(src_path)
        .with_context(|| rquickjs_playground::i18n_fmt!("打开文件失败: {0}", src_path.display()))?;

    zip.start_file(zip_name, *options)
        .with_context(|| rquickjs_playground::i18n_fmt!("创建 zip 条目失败: {0}", zip_name))?;

    let mut buffer = [0u8; 64 * 1024];
    loop {
        let n = src_file.read(&mut buffer).with_context(|| {
            rquickjs_playground::i18n_fmt!("读取文件失败: {0}", src_path.display())
        })?;
        if n == 0 {
            break;
        }
        zip.write_all(&buffer[..n])
            .with_context(|| rquickjs_playground::i18n_fmt!("写入 zip 条目失败: {0}", zip_name))?;
    }

    Ok(())
}
