pub(crate) static NATIVE_BUF_ID: AtomicU64 = AtomicU64::new(1);
static NATIVE_BUF_POOL: OnceLock<Mutex<HashMap<u64, NativeBufferEntry>>> = OnceLock::new();

pub(crate) fn native_pool() -> &'static Mutex<HashMap<u64, NativeBufferEntry>> {
    let pool = NATIVE_BUF_POOL.get_or_init(|| Mutex::new(HashMap::new()));
    start_native_buffer_gc_loop();
    pool
}

fn native_buffer_ttl() -> Option<Duration> {
    let ttl_secs = NATIVE_BUF_GC_TTL_SECS.load(Ordering::Relaxed);
    if ttl_secs == 0 {
        None
    } else {
        Some(Duration::from_secs(ttl_secs))
    }
}

fn cleanup_stale_native_buffers(pool: &mut HashMap<u64, NativeBufferEntry>) -> usize {
    let Some(ttl) = native_buffer_ttl() else {
        return 0;
    };
    let now = Instant::now();
    let stale_ids: Vec<u64> = pool
        .iter()
        .filter_map(|(id, entry)| {
            if now.duration_since(entry.created_at) > ttl {
                Some(*id)
            } else {
                None
            }
        })
        .collect();

    for id in &stale_ids {
        pool.remove(id);
    }
    stale_ids.len()
}

pub(crate) fn start_native_buffer_gc_loop() {
    NATIVE_BUF_GC_LOOP_STARTED.get_or_init(|| {
        thread::Builder::new()
            .name("rquickjs-native-buf-gc".to_string())
            .spawn(|| {
                loop {
                    thread::sleep(NATIVE_BUFFER_GC_INTERVAL);
                    let removed = {
                        let mut pool = match native_pool().lock() {
                            Ok(pool) => pool,
                            Err(_) => continue,
                        };
                        cleanup_stale_native_buffers(&mut pool)
                    };
                    if removed > 0 {
                        NATIVE_BUF_GC_DROPS.fetch_add(removed as u64, Ordering::Relaxed);
                    }
                }
            })
            .expect("创建 native buffer gc 线程失败");
    });
}

fn parse_u8_json_array(data_json: &str) -> AnyResult<Vec<u8>> {
    let value: Value = serde_json::from_str(data_json).context("解析字节数组 JSON 失败")?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("数据必须是字节数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let n = item
            .as_u64()
            .ok_or_else(|| anyhow!("字节数组元素必须是整数"))?;
        if n > 255 {
            return Err(anyhow!("字节数组元素必须在 0-255 范围"));
        }
        out.push(n as u8);
    }
    Ok(out)
}

pub fn native_buffer_put(data_json: String) -> String {
    let bytes = match parse_u8_json_array(&data_json) {
        Ok(bytes) => bytes,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(id, NativeBufferEntry::new(bytes));
    json!({ "ok": true, "id": id }).to_string()
}

pub fn native_buffer_put_raw(bytes: Vec<u8>) -> u64 {
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(id, NativeBufferEntry::new(bytes));
    id
}

pub fn native_buffer_take(id: u64) -> String {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    match pool.remove(&id) {
        Some(entry) => json!({ "ok": true, "data": entry.bytes }).to_string(),
        None => json!({ "ok": false, "error": "buffer id 不存在" }).to_string(),
    }
}

pub fn native_buffer_take_raw(id: u64) -> Option<Vec<u8>> {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.remove(&id).map(|entry| entry.bytes)
}

pub fn native_buffer_free(id: u64) -> String {
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    let existed = pool.remove(&id).is_some();
    json!({ "ok": true, "freed": existed }).to_string()
}

fn native_apply_op(
    op: &str,
    mut bytes: Vec<u8>,
    extra: Option<Vec<u8>>,
) -> Result<Vec<u8>, String> {
    match op {
        "invert" => {
            for b in &mut bytes {
                *b = 255 - *b;
            }
            Ok(bytes)
        }
        "grayscale_rgba" => {
            for chunk in bytes.chunks_exact_mut(4) {
                let r = chunk[0] as f32;
                let g = chunk[1] as f32;
                let b = chunk[2] as f32;
                let y = (0.299 * r + 0.587 * g + 0.114 * b).round() as u8;
                chunk[0] = y;
                chunk[1] = y;
                chunk[2] = y;
            }
            Ok(bytes)
        }
        "xor" => {
            let rhs = extra.ok_or_else(|| "xor 需要第二个输入参数".to_string())?;
            if rhs.len() != bytes.len() {
                return Err("xor 两个输入长度必须一致".to_string());
            }
            for i in 0..bytes.len() {
                bytes[i] ^= rhs[i];
            }
            Ok(bytes)
        }
        "noop" => Ok(bytes),
        "gzip_decompress" => {
            let mut decoder = GzDecoder::new(bytes.as_slice());
            let mut out = Vec::new();
            decoder
                .read_to_end(&mut out)
                .map_err(|e| format!("gzip 解压失败: {e}"))?;
            Ok(out)
        }
        "gzip_compress" => {
            let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
            encoder
                .write_all(&bytes)
                .map_err(|e| format!("gzip 压缩失败: {e}"))?;
            encoder.finish().map_err(|e| format!("gzip 压缩失败: {e}"))
        }
        _ => Err(format!("不支持的 native op: {op}")),
    }
}

fn parse_chain_steps(steps_json: &str) -> AnyResult<Vec<(String, Option<u64>)>> {
    let value: Value = serde_json::from_str(steps_json).context("解析 steps JSON 失败")?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!("steps 必须是数组"))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let obj = item
            .as_object()
            .ok_or_else(|| anyhow!("steps 元素必须是对象"))?;
        let op = obj
            .get("op")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("steps 元素缺少 op 字段"))?
            .to_string();
        let extra_input_id = obj.get("extraInputId").and_then(Value::as_u64);
        out.push((op, extra_input_id));
    }
    Ok(out)
}

pub fn native_exec(
    op: String,
    input_id: u64,
    _args_json: Option<String>,
    extra_input_id: Option<u64>,
) -> String {
    let (input, extra) = {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        let input = match pool.remove(&input_id) {
            Some(entry) => entry,
            None => return json!({ "ok": false, "error": "input id 不存在" }).to_string(),
        };

        let extra = if let Some(extra_id) = extra_input_id {
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    pool.insert(input_id, input);
                    return json!({ "ok": false, "error": "extra input id 不存在" }).to_string();
                }
            }
        } else {
            None
        };

        (input.bytes, extra)
    };

    let output = match native_apply_op(&op, input, extra) {
        Ok(bytes) => bytes,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };

    let output_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(output_id, NativeBufferEntry::new(output));
    json!({ "ok": true, "id": output_id }).to_string()
}

pub fn native_exec_chain(input_id: u64, steps_json: String) -> String {
    let steps = match parse_chain_steps(&steps_json) {
        Ok(steps) => steps,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    if steps.is_empty() {
        return json!({ "ok": false, "error": "steps 不能为空" }).to_string();
    }

    let mut current = {
        let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
        match pool.remove(&input_id) {
            Some(entry) => entry.bytes,
            None => return json!({ "ok": false, "error": "input id 不存在" }).to_string(),
        }
    };

    for (op, extra_input_id) in steps {
        let extra = if let Some(extra_id) = extra_input_id {
            let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    return json!({ "ok": false, "error": "extra input id 不存在" }).to_string();
                }
            }
        } else {
            None
        };

        current = match native_apply_op(&op, current, extra) {
            Ok(bytes) => bytes,
            Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
        };
    }

    let output_id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool().lock().expect("native buffer 池加锁失败");
    pool.insert(output_id, NativeBufferEntry::new(current));
    json!({ "ok": true, "id": output_id }).to_string()
}
use super::*;
