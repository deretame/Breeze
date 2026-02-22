use mslnk::ShellLink;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Cursor;
use std::path::PathBuf;
use xz2::read::XzDecoder;

/// Release.tar.xz embedded directly into the binary
const RELEASE_ARCHIVE: &[u8] = include_bytes!("../resources/Release.tar.xz");

const LOG_FILE_NAME: &str = "breeze-install-log.json";

#[derive(Serialize, Deserialize)]
struct InstallLog {
    install_path: String,
}

/// Returns the path to breeze-install-log.json in the local data dir.
fn get_log_file_path() -> Option<PathBuf> {
    dirs::data_local_dir().map(|p| p.join(LOG_FILE_NAME))
}

#[tauri::command]
fn get_default_install_path() -> String {
    // Try to read the previously saved install path first
    if let Some(log_path) = get_log_file_path() {
        if log_path.exists() {
            if let Ok(content) = fs::read_to_string(&log_path) {
                if let Ok(log) = serde_json::from_str::<InstallLog>(&content) {
                    if !log.install_path.is_empty() {
                        return log.install_path;
                    }
                }
            }
        }
    }

    // Fallback to default data_local_dir
    if let Some(path) = dirs::data_local_dir() {
        return path.to_string_lossy().to_string();
    }
    "".to_string()
}

#[tauri::command]
fn save_install_path(install_path: String) -> Result<String, String> {
    let log_path = get_log_file_path().ok_or_else(|| "无法获取本地数据目录".to_string())?;

    let log = InstallLog { install_path };
    let json = serde_json::to_string_pretty(&log).map_err(|e| format!("序列化失败: {}", e))?;
    fs::write(&log_path, json).map_err(|e| format!("写入文件失败: {}", e))?;

    Ok("安装路径已保存".to_string())
}

#[tauri::command]
fn try_shutdown_app() -> Result<String, String> {
    use std::time::Duration;

    let pipe_path = r"\\.\pipe\zephyr_shutdown_signal";

    match fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(pipe_path)
    {
        Ok(mut pipe) => {
            use std::io::Write;
            let _ = pipe.write_all(b"shutdown");
            let _ = pipe.flush();
            // Give the app a moment to close
            std::thread::sleep(Duration::from_secs(2));
            Ok("已发送关闭信号".to_string())
        }
        Err(_) => {
            // Pipe doesn't exist = app is not running, that's fine
            Ok("软件未在运行".to_string())
        }
    }
}

#[tauri::command]
fn perform_install(install_path: String) -> Result<String, String> {
    // 2. Create zephyr directory if it doesn't exist
    let zephyr_dir = PathBuf::from(&install_path).join("breeze");
    if !zephyr_dir.exists() {
        fs::create_dir_all(&zephyr_dir).map_err(|e| format!("无法创建安装目录: {}", e))?;
    }

    // 3. If Release folder already exists inside zephyr, remove it
    let release_dir = zephyr_dir.join("Release");
    if release_dir.exists() {
        fs::remove_dir_all(&release_dir).map_err(|e| format!("无法清理旧版本: {}", e))?;
    }

    // 4. Extract embedded Release.tar.xz into zephyr directory (streaming)
    let cursor = Cursor::new(RELEASE_ARCHIVE);
    let xz_decoder = XzDecoder::new(cursor);
    let mut archive = tar::Archive::new(xz_decoder);
    archive
        .unpack(&zephyr_dir)
        .map_err(|e| format!("解压安装文件失败: {}", e))?;

    // 5. Verify the expected executable exists
    let exe_path = zephyr_dir.join("Release").join("zephyr.exe");
    if !exe_path.exists() {
        return Err(format!(
            "安装完成但未找到主程序: {}",
            exe_path.to_string_lossy()
        ));
    }

    Ok(exe_path.to_string_lossy().to_string())
}

#[tauri::command]
fn create_shortcut(target_path: String, shortcut_name: String) -> Result<String, String> {
    // Get the desktop directory
    let desktop_dir = dirs::desktop_dir().ok_or_else(|| "无法获取桌面路径".to_string())?;

    let lnk_path = desktop_dir.join(format!("{}.lnk", shortcut_name));

    // Create a shell link pointing to the target executable
    let sl = ShellLink::new(&target_path).map_err(|e| format!("创建快捷方式失败: {}", e))?;

    sl.create_lnk(&lnk_path)
        .map_err(|e| format!("保存快捷方式失败: {}", e))?;

    Ok(format!("快捷方式已创建: {}", lnk_path.to_string_lossy()))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            get_default_install_path,
            save_install_path,
            try_shutdown_app,
            perform_install,
            create_shortcut
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
