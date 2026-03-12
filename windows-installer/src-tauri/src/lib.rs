use mslnk::ShellLink;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};
use xz2::read::XzDecoder;

/// Release.tar.xz embedded directly into the binary
const RELEASE_ARCHIVE: &[u8] = include_bytes!("../resources/Release.tar.xz");
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
