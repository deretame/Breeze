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
            .expect(&crate::tr!("failed-to-create-native-buffer-gc-thread"));
    });
}

fn parse_u8_json_array(data_json: &str) -> AnyResult<Vec<u8>> {
    let value: Value =
        serde_json::from_str(data_json).context(crate::tr!("failed-to-parse-byte-array-json"))?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!(crate::tr!("data-must-be-a-byte-array")))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let n = item
            .as_u64()
            .ok_or_else(|| anyhow!(crate::tr!("byte-array-elements-must-be-integers")))?;
        if n > 255 {
            return Err(anyhow!(crate::tr!(
                "byte-array-elements-must-be-in-the-0-255-range"
            )));
        }
        out.push(n as u8);
    }
    Ok(out)
}

pub fn native_buffer_put_binary(value: QjsValue) -> rquickjs::Result<u64> {
    let bytes: Vec<u8> = if let Ok(ta) = rquickjs::TypedArray::<u8>::from_value(value.clone()) {
        ta.as_bytes().map(|b| b.to_vec()).unwrap_or_default()
    } else if let Some(ab) = rquickjs::ArrayBuffer::from_value(value.clone()) {
        ab.as_bytes().map(|b| b.to_vec()).unwrap_or_default()
    } else if let Some(arr) = rquickjs::Object::from_value(value)?.into_array() {
        arr.iter::<u8>().collect::<rquickjs::Result<Vec<u8>>>()?
    } else {
        return Err(rquickjs::Error::new_from_js_message(
            "binary object",
            "Vec<u8>",
            "expected ArrayBuffer, TypedArray, or byte array",
        ));
    };

    Ok(native_buffer_put_raw(bytes))
}

pub fn native_buffer_put(data_json: String) -> String {
    let bytes = match parse_u8_json_array(&data_json) {
        Ok(bytes) => bytes,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    pool.insert(id, NativeBufferEntry::new(bytes));
    json!({ "ok": true, "id": id }).to_string()
}

pub fn native_buffer_put_raw(bytes: Vec<u8>) -> u64 {
    let id = NATIVE_BUF_ID.fetch_add(1, Ordering::Relaxed);
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    pool.insert(id, NativeBufferEntry::new(bytes));
    id
}

pub fn native_buffer_take(id: u64) -> String {
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    match pool.remove(&id) {
        Some(entry) => json!({ "ok": true, "data": entry.bytes }).to_string(),
        None => json!({ "ok": false, "error": crate::tr!("buffer-id-does-not-exist") }).to_string(),
    }
}

pub fn native_buffer_take_raw(id: u64) -> Option<Vec<u8>> {
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    pool.remove(&id).map(|entry| entry.bytes)
}

pub fn native_buffer_free(id: u64) -> String {
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
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
            let rhs = extra
                .ok_or_else(|| crate::tr!("xor-requires-a-second-input-argument").to_string())?;
            if rhs.len() != bytes.len() {
                return Err(crate::tr!("xor-inputs-must-have-the-same-length").to_string());
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
                .map_err(|e| crate::tr!("gzip-decompression-failed-2", e = e))?;
            Ok(out)
        }
        "gzip_compress" => {
            let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
            encoder
                .write_all(&bytes)
                .map_err(|e| crate::tr!("gzip-compression-failed-2", e = e))?;
            encoder
                .finish()
                .map_err(|e| crate::tr!("gzip-compression-failed-2", e = e))
        }
        _ => Err(crate::tr!("unsupported-native-op", op = op)),
    }
}

fn parse_chain_steps(steps_json: &str) -> AnyResult<Vec<(String, Option<u64>)>> {
    let value: Value =
        serde_json::from_str(steps_json).context(crate::tr!("failed-to-parse-steps-json"))?;
    let arr = value
        .as_array()
        .ok_or_else(|| anyhow!(crate::tr!("steps-must-be-an-array")))?;
    let mut out = Vec::with_capacity(arr.len());
    for item in arr {
        let obj = item
            .as_object()
            .ok_or_else(|| anyhow!(crate::tr!("steps-elements-must-be-objects")))?;
        let op = obj
            .get("op")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!(crate::tr!("steps-elements-missing-op-field")))?
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
        let mut pool = native_pool()
            .lock()
            .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
        let input = match pool.remove(&input_id) {
            Some(entry) => entry,
            None => {
                return json!({ "ok": false, "error": crate::tr!("input-id-does-not-exist") })
                    .to_string();
            }
        };

        let extra = if let Some(extra_id) = extra_input_id {
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    pool.insert(input_id, input);
                    return json!({ "ok": false, "error": crate::tr!("extra-input-id-does-not-exist") }).to_string();
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
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    pool.insert(output_id, NativeBufferEntry::new(output));
    json!({ "ok": true, "id": output_id }).to_string()
}

pub fn native_exec_chain(input_id: u64, steps_json: String) -> String {
    let steps = match parse_chain_steps(&steps_json) {
        Ok(steps) => steps,
        Err(error) => return json!({ "ok": false, "error": format!("{error}") }).to_string(),
    };
    if steps.is_empty() {
        return json!({ "ok": false, "error": crate::tr!("steps-cannot-be-empty") }).to_string();
    }

    let mut current = {
        let mut pool = native_pool()
            .lock()
            .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
        match pool.remove(&input_id) {
            Some(entry) => entry.bytes,
            None => {
                return json!({ "ok": false, "error": crate::tr!("input-id-does-not-exist") })
                    .to_string();
            }
        }
    };

    for (op, extra_input_id) in steps {
        let extra = if let Some(extra_id) = extra_input_id {
            let mut pool = native_pool()
                .lock()
                .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
            match pool.remove(&extra_id) {
                Some(entry) => Some(entry.bytes),
                None => {
                    return json!({ "ok": false, "error": crate::tr!("extra-input-id-does-not-exist") }).to_string();
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
    let mut pool = native_pool()
        .lock()
        .expect(&crate::tr!("failed-to-lock-native-buffer-pool"));
    pool.insert(output_id, NativeBufferEntry::new(current));
    json!({ "ok": true, "id": output_id }).to_string()
}
use super::*;
