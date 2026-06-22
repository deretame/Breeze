use mslnk::ShellLink;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};

/// Release.7z embedded directly into the binary
const RELEASE_ARCHIVE: &[u8] = include_bytes!("../resources/Release.7z");
const ROOT_PUBSPEC: &str = include_str!("../../../pubspec.yaml");

const LOG_FILE_NAME: &str = "breeze-install-log.json";
const UNINSTALL_REG_KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Uninstall\Breeze";
const START_MENU_SHORTCUT_NAME: &str = "Breeze.lnk";

fn get_display_version() -> String {
    let fallback = format!("v{}", env!("CARGO_PKG_VERSION"));

    for line in ROOT_PUBSPEC.lines() {
        let trimmed = line.trim();
        if let Some(version) = trimmed.strip_prefix("version:") {
            let version = version.trim();
            let core_version = version.split('+').next().unwrap_or(version).trim();
            if !core_version.is_empty() {
                return format!("v{}", core_version);
            }
        }
    }

    fallback
}

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

fn is_zephyr_running() -> bool {
    std::process::Command::new("tasklist")
        .args(["/FI", "IMAGENAME eq zephyr.exe", "/NH"])
        .output()
        .map(|output| String::from_utf8_lossy(&output.stdout).contains("zephyr.exe"))
        .unwrap_or(false)
}

#[tauri::command]
fn try_shutdown_app() -> Result<String, String> {
    use std::io::Write;
    use std::time::Duration;

    let pipe_path = r"\\.\pipe\zephyr_shutdown_signal";

    match fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(pipe_path)
    {
        Ok(mut pipe) => {
            let _ = pipe.write_all(b"shutdown");
            let _ = pipe.flush();
            drop(pipe);

            for _ in 0..15 {
                std::thread::sleep(Duration::from_secs(2));
                if !is_zephyr_running() {
                    return Ok("软件已关闭".to_string());
                }
            }
            Ok("已发送关闭信号，但软件可能仍在运行".to_string())
        }
        Err(_) => Ok("软件未在运行".to_string()),
    }
}

#[cfg(target_os = "windows")]
fn create_uninstall_script(install_root: &Path) -> Result<PathBuf, String> {
    let uninstall_script = install_root.join("uninstall.bat");
    let install_root_text = install_root.to_string_lossy();

    let script = [
        "@echo off\r\nsetlocal\r\n",
        "powershell -NoProfile -Command \"$pipe='\\\\.\\pipe\\zephyr_shutdown_signal'; try { $fs=[System.IO.File]::Open($pipe,[System.IO.FileMode]::Open,[System.IO.FileAccess]::ReadWrite); $bytes=[System.Text.Encoding]::UTF8.GetBytes('shutdown'); $fs.Write($bytes,0,$bytes.Length); $fs.Flush(); $fs.Close() } catch {}\" >nul 2>&1\r\n",
        "timeout /t 2 /nobreak >nul\r\n",
        "taskkill /IM zephyr.exe /F >nul 2>&1\r\n",
        "del /f /q \"%USERPROFILE%\\Desktop\\Breeze.lnk\" >nul 2>&1\r\n",
        "del /f /q \"%PUBLIC%\\Desktop\\Breeze.lnk\" >nul 2>&1\r\n",
        "del /f /q \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Breeze.lnk\" >nul 2>&1\r\n",
        "del /f /q \"%ProgramData%\\Microsoft\\Windows\\Start Menu\\Programs\\Breeze.lnk\" >nul 2>&1\r\n",
        "reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Breeze\" /f >nul 2>&1\r\n",
        &format!("set \"TARGET_DIR={}\"\r\n", install_root_text),
        "start \"\" powershell -NoProfile -WindowStyle Hidden -Command \"$target=$env:TARGET_DIR; Start-Sleep -Seconds 2; for($i=0;$i -lt 30;$i++){ try { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds 500 } }\"\r\n",
        "exit /b 0\r\n",
    ]
    .concat();

    fs::write(&uninstall_script, script).map_err(|e| format!("写入卸载脚本失败: {}", e))?;
    Ok(uninstall_script)
}

#[cfg(target_os = "windows")]
fn register_uninstall_entry_internal(
    exe_path: &Path,
    install_root: &Path,
) -> Result<String, String> {
    use winreg::enums::HKEY_CURRENT_USER;
    use winreg::RegKey;

    let uninstall_script = create_uninstall_script(install_root)?;
    let uninstall_cmd = format!("\"{}\"", uninstall_script.to_string_lossy());

    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let (key, _) = hkcu
        .create_subkey(UNINSTALL_REG_KEY)
        .map_err(|e| format!("创建卸载注册表项失败: {}", e))?;

    key.set_value("DisplayName", &"Breeze")
        .map_err(|e| format!("写入注册表 DisplayName 失败: {}", e))?;
    key.set_value("DisplayVersion", &get_display_version())
        .map_err(|e| format!("写入注册表 DisplayVersion 失败: {}", e))?;
    key.set_value("Publisher", &"Breeze")
        .map_err(|e| format!("写入注册表 Publisher 失败: {}", e))?;
    key.set_value(
        "InstallLocation",
        &install_root.to_string_lossy().to_string(),
    )
    .map_err(|e| format!("写入注册表 InstallLocation 失败: {}", e))?;
    key.set_value("DisplayIcon", &exe_path.to_string_lossy().to_string())
        .map_err(|e| format!("写入注册表 DisplayIcon 失败: {}", e))?;
    key.set_value("UninstallString", &uninstall_cmd)
        .map_err(|e| format!("写入注册表 UninstallString 失败: {}", e))?;
    key.set_value("QuietUninstallString", &uninstall_cmd)
        .map_err(|e| format!("写入注册表 QuietUninstallString 失败: {}", e))?;
    key.set_value("NoModify", &1u32)
        .map_err(|e| format!("写入注册表 NoModify 失败: {}", e))?;
    key.set_value("NoRepair", &1u32)
        .map_err(|e| format!("写入注册表 NoRepair 失败: {}", e))?;

    Ok("已注册到 Windows 卸载列表".to_string())
}

#[cfg(target_os = "windows")]
fn create_start_menu_shortcut_internal(exe_path: &Path) -> Result<(), String> {
    let appdata = std::env::var("APPDATA").map_err(|e| format!("获取 APPDATA 失败: {}", e))?;
    let programs_dir = PathBuf::from(appdata).join("Microsoft\\Windows\\Start Menu\\Programs");
    fs::create_dir_all(&programs_dir).map_err(|e| format!("创建开始菜单目录失败: {}", e))?;

    let shortcut_path = programs_dir.join(START_MENU_SHORTCUT_NAME);
    let sl = ShellLink::new(exe_path).map_err(|e| format!("创建开始菜单快捷方式失败: {}", e))?;
    sl.create_lnk(&shortcut_path)
        .map_err(|e| format!("保存开始菜单快捷方式失败: {}", e))?;

    Ok(())
}

#[cfg(not(target_os = "windows"))]
fn create_start_menu_shortcut_internal(_exe_path: &Path) -> Result<(), String> {
    Err("仅支持在 Windows 上创建开始菜单快捷方式".to_string())
}

#[cfg(not(target_os = "windows"))]
fn register_uninstall_entry_internal(
    _exe_path: &Path,
    _install_root: &Path,
) -> Result<String, String> {
    Err("仅支持在 Windows 上注册卸载信息".to_string())
}

/// Extract a 7z archive into `dest` using the same code path as the installer.
/// Kept as a separate function so it can be unit-tested.
fn extract_7z(archive_bytes: &[u8], dest: &Path) -> Result<(), String> {
    let cursor = Cursor::new(archive_bytes);
    sevenz_rust2::decompress(cursor, dest).map_err(|e| format!("解压安装文件失败: {}", e))
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

    // 4. Extract embedded Release.7z into zephyr directory
    extract_7z(RELEASE_ARCHIVE, &zephyr_dir)?;

    // 5. Verify the expected executable exists
    let exe_path = zephyr_dir.join("Release").join("zephyr.exe");
    if !exe_path.exists() {
        return Err(format!(
            "安装完成但未找到主程序: {}",
            exe_path.to_string_lossy()
        ));
    }

    register_uninstall_entry_internal(&exe_path, &zephyr_dir)?;
    create_start_menu_shortcut_internal(&exe_path)?;

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

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn make_temp_dir() -> PathBuf {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis();
        let dir = std::env::temp_dir().join(format!("breeze_7z_test_{}", now));
        fs::create_dir_all(&dir).expect("创建临时目录失败");
        dir
    }

    fn cleanup_dir(path: &Path) {
        let _ = fs::remove_dir_all(path);
    }

    /// Ensure 7z archives containing long paths can be unpacked by the
    /// installer's `sevenz_rust2` decompression path.
    #[test]
    fn sevenz_roundtrip_with_long_paths() {
        let base = make_temp_dir();

        // 1. Build a fake "Release" directory with a >100 char filename.
        //    Put it under a wrapper so that sevenz-rust2 archives the
        //    "Release" directory itself (matching the build script's
        //    `7zr a Release.7z Release` output).
        let wrapper_dir = base.join("wrapper");
        let release_dir = wrapper_dir.join("Release");
        fs::create_dir_all(&release_dir).unwrap();
        let long_name = "a".repeat(120) + ".txt";
        fs::write(release_dir.join(&long_name), "long file content").unwrap();
        fs::write(release_dir.join("normal.txt"), "normal content").unwrap();

        // 2. Create a 7z archive with sevenz-rust2.
        let archive_path = base.join("Release.7z");
        sevenz_rust2::compress_to_path(&wrapper_dir, &archive_path).expect("创建 7z 测试归档失败");

        // 3. Extract with the same function used by the installer.
        let archive_bytes = fs::read(&archive_path).unwrap();
        let extract_dir = base.join("extracted");
        fs::create_dir_all(&extract_dir).unwrap();
        extract_7z(&archive_bytes, &extract_dir).expect("sevenz-rust2 解压失败");

        // 4. Verify the long-path file was reconstructed correctly.
        let extracted_long = extract_dir.join("Release").join(&long_name);
        assert!(
            extracted_long.exists(),
            "长路径文件未正确解压: {}",
            extracted_long.display()
        );
        assert_eq!(
            fs::read_to_string(&extracted_long).unwrap(),
            "long file content"
        );

        cleanup_dir(&base);
    }
}
