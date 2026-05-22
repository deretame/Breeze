pub(crate) fn fs_task_dispatch(op: String, args_json: String) -> String {
    let args: Vec<Value> = match serde_json::from_str(&args_json) {
        Ok(v) => v,
        Err(e) => {
            return json!({ "ok": false, "code": "EINVAL", "error": e.to_string() }).to_string();
        }
    };

    let arg_str = |idx: usize, name: &str| -> Result<String, String> {
        args.get(idx)
            .and_then(Value::as_str)
            .map(ToString::to_string)
            .ok_or_else(|| format!("参数 {name} 必须是字符串"))
    };
    let arg_bool = |idx: usize, name: &str| -> Result<bool, String> {
        args.get(idx)
            .and_then(Value::as_bool)
            .ok_or_else(|| format!("参数 {name} 必须是布尔值"))
    };
    let arg_u64 = |idx: usize, name: &str| -> Result<u64, String> {
        args.get(idx)
            .and_then(Value::as_u64)
            .ok_or_else(|| format!("参数 {name} 必须是非负整数"))
    };
    let arg_u32 = |idx: usize, name: &str| -> Result<u32, String> {
        arg_u64(idx, name)
            .and_then(|v| u32::try_from(v).map_err(|_| format!("参数 {name} 超出 u32 范围")))
    };
    let arg_i64 = |idx: usize, name: &str| -> Result<i64, String> {
        args.get(idx)
            .and_then(Value::as_i64)
            .ok_or_else(|| format!("参数 {name} 必须是整数"))
    };
    let arg_opt_str = |idx: usize| -> Option<String> {
        args.get(idx).and_then(|v| {
            if v.is_null() {
                None
            } else {
                v.as_str().map(ToString::to_string)
            }
        })
    };

    match op.as_str() {
        "readFile" => match arg_str(0, "path") {
            Ok(path) => fs_read_file(path, arg_opt_str(1)),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "writeFile" => match (
            arg_str(0, "path"),
            arg_str(1, "dataJson"),
            arg_opt_str(2),
            arg_bool(3, "append"),
        ) {
            (Ok(path), Ok(data_json), encoding, Ok(append)) => {
                fs_write_file(path, data_json, encoding, append)
            }
            _ => {
                json!({ "ok": false, "code": "EINVAL", "error": "writeFile 参数无效" }).to_string()
            }
        },
        "mkdir" => match (arg_str(0, "path"), arg_bool(1, "recursive")) {
            (Ok(path), Ok(recursive)) => fs_mkdir(path, recursive),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "mkdir 参数无效" }).to_string(),
        },
        "readdir" => match (arg_str(0, "path"), arg_bool(1, "withFileTypes")) {
            (Ok(path), Ok(with_file_types)) => fs_readdir(path, with_file_types),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "readdir 参数无效" }).to_string(),
        },
        "stat" => match arg_str(0, "path") {
            Ok(path) => fs_stat(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "lstat" => match arg_str(0, "path") {
            Ok(path) => fs_lstat(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "access" => match arg_str(0, "path") {
            Ok(path) => fs_access(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "unlink" => match arg_str(0, "path") {
            Ok(path) => fs_unlink(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "rm" => match (
            arg_str(0, "path"),
            arg_bool(1, "recursive"),
            arg_bool(2, "force"),
        ) {
            (Ok(path), Ok(recursive), Ok(force)) => fs_rm(path, recursive, force),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "rm 参数无效" }).to_string(),
        },
        "rename" => match (arg_str(0, "oldPath"), arg_str(1, "newPath")) {
            (Ok(old_path), Ok(new_path)) => fs_rename(old_path, new_path),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "rename 参数无效" }).to_string(),
        },
        "copyFile" => match (arg_str(0, "src"), arg_str(1, "dst")) {
            (Ok(src), Ok(dst)) => fs_copy_file(src, dst),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "copyFile 参数无效" }).to_string(),
        },
        "cp" => match (
            arg_str(0, "src"),
            arg_str(1, "dst"),
            arg_bool(2, "recursive"),
            arg_bool(3, "force"),
            arg_bool(4, "errorOnExist"),
        ) {
            (Ok(src), Ok(dst), Ok(recursive), Ok(force), Ok(error_on_exist)) => {
                fs_cp(src, dst, recursive, force, error_on_exist)
            }
            _ => json!({ "ok": false, "code": "EINVAL", "error": "cp 参数无效" }).to_string(),
        },
        "realpath" => match arg_str(0, "path") {
            Ok(path) => fs_realpath(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "readlink" => match arg_str(0, "path") {
            Ok(path) => fs_readlink(path),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        "symlink" => match (
            arg_str(0, "target"),
            arg_str(1, "path"),
            arg_bool(2, "isDir"),
        ) {
            (Ok(target), Ok(path), Ok(is_dir)) => fs_symlink(target, path, is_dir),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "symlink 参数无效" }).to_string(),
        },
        "link" => match (arg_str(0, "existingPath"), arg_str(1, "newPath")) {
            (Ok(existing_path), Ok(new_path)) => fs_link(existing_path, new_path),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "link 参数无效" }).to_string(),
        },
        "truncate" => match (arg_str(0, "path"), arg_u64(1, "len")) {
            (Ok(path), Ok(len)) => fs_truncate(path, len),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "truncate 参数无效" }).to_string(),
        },
        "chmod" => match (arg_str(0, "path"), arg_u32(1, "mode")) {
            (Ok(path), Ok(mode)) => fs_chmod(path, mode),
            _ => json!({ "ok": false, "code": "EINVAL", "error": "chmod 参数无效" }).to_string(),
        },
        "utimes" => match (arg_str(0, "path"), arg_i64(1, "atime"), arg_i64(2, "mtime")) {
            (Ok(path), Ok(atime_millis), Ok(mtime_millis)) => {
                fs_utimes(path, atime_millis, mtime_millis)
            }
            _ => json!({ "ok": false, "code": "EINVAL", "error": "utimes 参数无效" }).to_string(),
        },
        "mkdtemp" => match arg_str(0, "prefix") {
            Ok(prefix) => fs_mkdtemp(prefix),
            Err(e) => json!({ "ok": false, "code": "EINVAL", "error": e }).to_string(),
        },
        _ => {
            json!({ "ok": false, "code": "EINVAL", "error": format!("不支持的 fs 异步操作: {op}") })
                .to_string()
        }
    }
}

fn io_error_code(error: &io::Error) -> &'static str {
    match error.kind() {
        io::ErrorKind::NotFound => "ENOENT",
        io::ErrorKind::PermissionDenied => "EACCES",
        io::ErrorKind::AlreadyExists => "EEXIST",
        io::ErrorKind::InvalidInput => "EINVAL",
        io::ErrorKind::InvalidData => "EINVAL",
        io::ErrorKind::TimedOut => "ETIMEDOUT",
        io::ErrorKind::Interrupted => "EINTR",
        io::ErrorKind::WouldBlock => "EWOULDBLOCK",
        _ => "EIO",
    }
}

fn fs_error_payload(error: io::Error) -> String {
    json!({
        "ok": false,
        "code": io_error_code(&error),
        "error": error.to_string()
    })
    .to_string()
}

fn system_time_to_millis(time: Result<SystemTime, io::Error>) -> Option<i64> {
    let value = time.ok()?;
    let dur = value.duration_since(UNIX_EPOCH).ok()?;
    Some(dur.as_millis() as i64)
}

fn normalize_encoding(encoding: Option<String>) -> String {
    encoding
        .unwrap_or_default()
        .trim()
        .to_ascii_lowercase()
        .replace('_', "-")
}

pub fn fs_read_file(path: String, encoding: Option<String>) -> String {
    match fs::read(&path) {
        Ok(bytes) => {
            let encoding = normalize_encoding(encoding);
            if encoding.is_empty() {
                json!({ "ok": true, "kind": "bytes", "data": bytes }).to_string()
            } else if encoding == "utf8" || encoding == "utf-8" {
                match String::from_utf8(bytes) {
                    Ok(text) => json!({ "ok": true, "kind": "text", "data": text }).to_string(),
                    Err(err) => json!({ "ok": false, "code": "EINVAL", "error": err.to_string() })
                        .to_string(),
                }
            } else {
                json!({
                    "ok": false,
                    "code": "EINVAL",
                    "error": format!("不支持的编码: {encoding}")
                })
                .to_string()
            }
        }
        Err(error) => fs_error_payload(error),
    }
}

fn parse_fs_write_payload(data_json: String, encoding: Option<String>) -> Result<Vec<u8>, String> {
    let value: Value = serde_json::from_str(&data_json).map_err(|e| e.to_string())?;
    let kind = value
        .get("kind")
        .and_then(Value::as_str)
        .ok_or("缺少 kind 字段")?;

    if kind == "bytes" {
        let list = value
            .get("data")
            .and_then(Value::as_array)
            .ok_or("bytes 数据格式错误")?;
        let mut out = Vec::with_capacity(list.len());
        for item in list {
            let num = item.as_u64().ok_or("bytes 数据必须是 0-255 的整数")?;
            if num > 255 {
                return Err("bytes 数据必须在 0-255 范围内".to_string());
            }
            out.push(num as u8);
        }
        return Ok(out);
    }

    if kind == "text" {
        let text = value
            .get("data")
            .and_then(Value::as_str)
            .ok_or("text 数据格式错误")?;
        let encoding = normalize_encoding(encoding);
        if encoding.is_empty() || encoding == "utf8" || encoding == "utf-8" {
            return Ok(text.as_bytes().to_vec());
        }
        return Err(format!("不支持的编码: {encoding}"));
    }

    Err(format!("不支持的 kind: {kind}"))
}

pub fn fs_write_file(
    path: String,
    data_json: String,
    encoding: Option<String>,
    append: bool,
) -> String {
    let bytes = match parse_fs_write_payload(data_json, encoding) {
        Ok(bytes) => bytes,
        Err(error) => {
            return json!({ "ok": false, "code": "EINVAL", "error": format!("{error}") })
                .to_string();
        }
    };

    let result = if append {
        fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)
            .and_then(|mut file| file.write_all(&bytes))
    } else {
        fs::write(&path, bytes)
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_mkdir(path: String, recursive: bool) -> String {
    let result = if recursive {
        fs::create_dir_all(&path)
    } else {
        fs::create_dir(&path)
    };
    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_readdir(path: String, with_file_types: bool) -> String {
    match fs::read_dir(&path) {
        Ok(read_dir) => {
            let mut entries = Vec::new();
            for entry in read_dir {
                match entry {
                    Ok(item) => {
                        let name = item.file_name().to_string_lossy().to_string();
                        if with_file_types {
                            match item.file_type() {
                                Ok(file_type) => entries.push(json!({
                                    "name": name,
                                    "isFile": file_type.is_file(),
                                    "isDirectory": file_type.is_dir(),
                                    "isSymbolicLink": file_type.is_symlink(),
                                })),
                                Err(error) => return fs_error_payload(error),
                            }
                        } else {
                            entries.push(Value::String(name));
                        }
                    }
                    Err(error) => return fs_error_payload(error),
                }
            }
            json!({ "ok": true, "entries": entries }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_stat(path: String) -> String {
    match fs::metadata(&path) {
        Ok(metadata) => json!({
            "ok": true,
            "isFile": metadata.is_file(),
            "isDirectory": metadata.is_dir(),
            "isSymbolicLink": metadata.file_type().is_symlink(),
            "size": metadata.len(),
            "readonly": metadata.permissions().readonly(),
            "atimeMs": system_time_to_millis(metadata.accessed()),
            "mtimeMs": system_time_to_millis(metadata.modified()),
            "ctimeMs": system_time_to_millis(metadata.created())
        })
        .to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_access(path: String) -> String {
    match fs::metadata(&path) {
        Ok(_) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_unlink(path: String) -> String {
    match fs::remove_file(&path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_rm(path: String, recursive: bool, force: bool) -> String {
    let target = Path::new(&path);
    if !target.exists() {
        if force {
            return json!({ "ok": true }).to_string();
        }
        return json!({ "ok": false, "code": "ENOENT", "error": "文件或目录不存在" }).to_string();
    }

    let result = if target.is_dir() {
        if recursive {
            fs::remove_dir_all(target)
        } else {
            fs::remove_dir(target)
        }
    } else {
        fs::remove_file(target)
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_rename(old_path: String, new_path: String) -> String {
    match fs::rename(&old_path, &new_path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_copy_file(src: String, dst: String) -> String {
    match fs::copy(&src, &dst) {
        Ok(bytes) => json!({ "ok": true, "bytesCopied": bytes }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_realpath(path: String) -> String {
    match fs::canonicalize(&path) {
        Ok(resolved) => {
            json!({ "ok": true, "path": resolved.to_string_lossy().to_string() }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_lstat(path: String) -> String {
    match fs::symlink_metadata(&path) {
        Ok(metadata) => json!({
            "ok": true,
            "isFile": metadata.is_file(),
            "isDirectory": metadata.is_dir(),
            "isSymbolicLink": metadata.file_type().is_symlink(),
            "size": metadata.len(),
            "readonly": metadata.permissions().readonly(),
            "atimeMs": system_time_to_millis(metadata.accessed()),
            "mtimeMs": system_time_to_millis(metadata.modified()),
            "ctimeMs": system_time_to_millis(metadata.created())
        })
        .to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_readlink(path: String) -> String {
    match fs::read_link(&path) {
        Ok(target) => {
            json!({ "ok": true, "path": target.to_string_lossy().to_string() }).to_string()
        }
        Err(error) => fs_error_payload(error),
    }
}

#[cfg(unix)]
fn create_symlink_impl(target: &str, path: &str, _is_dir: bool) -> io::Result<()> {
    std::os::unix::fs::symlink(target, path)
}

#[cfg(windows)]
fn create_symlink_impl(target: &str, path: &str, is_dir: bool) -> io::Result<()> {
    if is_dir {
        std::os::windows::fs::symlink_dir(target, path)
    } else {
        std::os::windows::fs::symlink_file(target, path)
    }
}

#[cfg(not(any(unix, windows)))]
fn create_symlink_impl(_target: &str, _path: &str, _is_dir: bool) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "当前平台不支持符号链接",
    ))
}

pub fn fs_symlink(target: String, path: String, is_dir: bool) -> String {
    match create_symlink_impl(&target, &path, is_dir) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_link(existing_path: String, new_path: String) -> String {
    match fs::hard_link(&existing_path, &new_path) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_truncate(path: String, len: u64) -> String {
    let result = fs::OpenOptions::new()
        .write(true)
        .open(&path)
        .and_then(|file| file.set_len(len));
    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

#[cfg(unix)]
fn chmod_impl(path: &str, mode: u32) -> io::Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let perms = fs::Permissions::from_mode(mode);
    fs::set_permissions(path, perms)
}

#[cfg(windows)]
fn chmod_impl(path: &str, mode: u32) -> io::Result<()> {
    let mut perms = fs::metadata(path)?.permissions();
    perms.set_readonly((mode & 0o200) == 0);
    fs::set_permissions(path, perms)
}

#[cfg(not(any(unix, windows)))]
fn chmod_impl(_path: &str, _mode: u32) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "当前平台不支持 chmod",
    ))
}

pub fn fs_chmod(path: String, mode: u32) -> String {
    match chmod_impl(&path, mode) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

pub fn fs_utimes(path: String, atime_millis: i64, mtime_millis: i64) -> String {
    let atime_secs = atime_millis.div_euclid(1000);
    let atime_nanos = (atime_millis.rem_euclid(1000) * 1_000_000) as u32;
    let mtime_secs = mtime_millis.div_euclid(1000);
    let mtime_nanos = (mtime_millis.rem_euclid(1000) * 1_000_000) as u32;
    let atime = FileTime::from_unix_time(atime_secs, atime_nanos);
    let mtime = FileTime::from_unix_time(mtime_secs, mtime_nanos);
    match set_file_times(&path, atime, mtime) {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> io::Result<()> {
    if !dst.exists() {
        fs::create_dir_all(dst)?;
    }
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        let file_type = entry.file_type()?;
        if file_type.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else if file_type.is_file() {
            fs::copy(&src_path, &dst_path)?;
        } else if file_type.is_symlink() {
            let target = fs::read_link(&src_path)?;
            create_symlink_impl(
                &target.to_string_lossy(),
                &dst_path.to_string_lossy(),
                target.is_dir(),
            )?;
        }
    }
    Ok(())
}

pub fn fs_cp(
    src: String,
    dst: String,
    recursive: bool,
    force: bool,
    error_on_exist: bool,
) -> String {
    let src_path = Path::new(&src);
    let dst_path = Path::new(&dst);

    if !src_path.exists() {
        return json!({ "ok": false, "code": "ENOENT", "error": "源路径不存在" }).to_string();
    }
    if dst_path.exists() {
        if error_on_exist {
            return json!({ "ok": false, "code": "EEXIST", "error": "目标路径已存在" }).to_string();
        }
        if !force {
            return json!({ "ok": false, "code": "EEXIST", "error": "目标路径已存在，且未启用 force" }).to_string();
        }
    }

    let result = if src_path.is_dir() {
        if !recursive {
            Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "复制目录时必须启用 recursive",
            ))
        } else {
            copy_dir_recursive(src_path, dst_path)
        }
    } else {
        fs::copy(src_path, dst_path).map(|_| ())
    };

    match result {
        Ok(()) => json!({ "ok": true }).to_string(),
        Err(error) => fs_error_payload(error),
    }
}

static MKDTEMP_COUNTER: AtomicU64 = AtomicU64::new(0);

pub fn fs_mkdtemp(prefix: String) -> String {
    for _ in 0..32 {
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_else(|_| Duration::from_secs(0))
            .as_nanos();
        let seq: u64 = MKDTEMP_COUNTER.fetch_add(1, Ordering::Relaxed);
        let candidate = format!("{prefix}{ts:016x}{seq:04x}");
        let path = PathBuf::from(candidate);
        match fs::create_dir(&path) {
            Ok(()) => {
                return json!({ "ok": true, "path": path.to_string_lossy().to_string() })
                    .to_string();
            }
            Err(error) if error.kind() == io::ErrorKind::AlreadyExists => continue,
            Err(error) => return fs_error_payload(error),
        }
    }
    json!({ "ok": false, "code": "EEXIST", "error": "无法创建唯一临时目录" }).to_string()
}
use super::*;
