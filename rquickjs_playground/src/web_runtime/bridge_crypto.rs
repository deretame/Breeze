//! Bridge crypto 路由实现。
//!
//! 注意：crypto 相关路由只接受原始二进制数据。
//! 如果需要传入 base64 或字符串，请先在 JS 层转换为 Uint8Array：
//!   - base64: 使用全局的 bytesFromBase64(base64String)
//!   - 字符串: 使用 new TextEncoder().encode(string) 或 encodeUtf8(string)

use super::*;

/// 判断给定路由名是否为内置 crypto 路由（含已废弃的 _hex / _b64 兼容路由）。
pub fn is_crypto_route(name: &str) -> bool {
    matches!(
        name,
        "crypto.md5"
            | "crypto.sha1"
            | "crypto.sha256"
            | "crypto.sha512"
            | "crypto.hmac_sha1"
            | "crypto.hmac_sha256"
            | "crypto.hmac_sha512"
            | "crypto.aes_ecb_pkcs7_decrypt"
            | "crypto.aes_ecb_pkcs7_encrypt"
            | "crypto.aes_cbc_pkcs7_decrypt"
            | "crypto.aes_cbc_pkcs7_encrypt"
            | "crypto.aes_gcm_decrypt"
            | "crypto.aes_gcm_encrypt"
            | "crypto.md5_hex"
            | "crypto.sha1_hex"
            | "crypto.sha256_hex"
            | "crypto.sha512_hex"
            | "crypto.hmac_sha1_hex"
            | "crypto.hmac_sha256_hex"
            | "crypto.hmac_sha512_hex"
            | "crypto.aes_ecb_pkcs7_decrypt_b64"
            | "crypto.aes_cbc_pkcs7_encrypt_b64"
            | "crypto.aes_cbc_pkcs7_decrypt_b64"
            | "crypto.aes_gcm_encrypt_b64"
            | "crypto.aes_gcm_decrypt_b64"
    )
}

/// 分发内置 crypto 路由。
///
/// 调用者应先用 [`is_crypto_route`] 确认 `name` 是 crypto 路由；
/// 若传入非 crypto 路由，本函数会 panic。
pub fn dispatch_crypto_route(name: &str, args: &[Value]) -> AnyResult<Value> {
    match name {
        "crypto.md5" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            crypto_md5_bytes(input)
        }
        "crypto.sha1" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            crypto_sha1_bytes(input)
        }
        "crypto.sha256" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            crypto_sha256_bytes(input)
        }
        "crypto.sha512" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            crypto_sha512_bytes(input)
        }
        "crypto.hmac_sha1" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            crypto_hmac_sha1_bytes(key, input)
        }
        "crypto.hmac_sha256" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            crypto_hmac_sha256_bytes(key, input)
        }
        "crypto.hmac_sha512" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            crypto_hmac_sha512_bytes(key, input)
        }
        "crypto.aes_ecb_pkcs7_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            crypto_aes_ecb_pkcs7_decrypt_bytes(input, key)
        }
        "crypto.aes_ecb_pkcs7_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            crypto_aes_ecb_pkcs7_encrypt_bytes(input, key)
        }
        "crypto.aes_cbc_pkcs7_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let iv = parse_u8_json_value(require_arg(args, 2, "iv")?)?;
            crypto_aes_cbc_pkcs7_decrypt_bytes(input, key, iv)
        }
        "crypto.aes_cbc_pkcs7_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let iv = parse_u8_json_value(require_arg(args, 2, "iv")?)?;
            crypto_aes_cbc_pkcs7_encrypt_bytes(input, key, iv)
        }
        "crypto.aes_gcm_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let nonce = parse_u8_json_value(require_arg(args, 2, "nonce")?)?;
            let aad = args.get(3).map(|v| parse_u8_json_value(v)).transpose()?;
            crypto_aes_gcm_decrypt_bytes(input, key, nonce, aad)
        }
        "crypto.aes_gcm_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let nonce = parse_u8_json_value(require_arg(args, 2, "nonce")?)?;
            let aad = args.get(3).map(|v| parse_u8_json_value(v)).transpose()?;
            crypto_aes_gcm_encrypt_bytes(input, key, nonce, aad)
        }
        // 以下路由已废弃，仅保留兼容。
        "crypto.md5_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            crypto_md5_hex(input)
        }
        "crypto.sha1_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            crypto_sha1_hex(input)
        }
        "crypto.sha256_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            crypto_sha256_hex(input)
        }
        "crypto.sha512_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            crypto_sha512_hex(input)
        }
        "crypto.hmac_sha1_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            crypto_hmac_sha1_hex(key, input)
        }
        "crypto.hmac_sha256_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            crypto_hmac_sha256_hex(key, input)
        }
        "crypto.hmac_sha512_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            crypto_hmac_sha512_hex(key, input)
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64, key_raw)
        }
        "crypto.aes_cbc_pkcs7_encrypt_b64" => {
            let plain_b64 = require_str_arg(args, 0, "plain")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let iv_raw = require_str_arg(args, 2, "iv")?;
            crypto_aes_cbc_pkcs7_encrypt_b64(plain_b64, key_raw, iv_raw)
        }
        "crypto.aes_cbc_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let iv_raw = require_str_arg(args, 2, "iv")?;
            crypto_aes_cbc_pkcs7_decrypt_b64(payload_b64, key_raw, iv_raw)
        }
        "crypto.aes_gcm_encrypt_b64" => {
            let plain_b64 = require_str_arg(args, 0, "plain")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let nonce_raw = require_str_arg(args, 2, "nonce")?;
            let aad_b64 = args.get(3).and_then(Value::as_str).map(ToString::to_string);
            crypto_aes_gcm_encrypt_b64(plain_b64, key_raw, nonce_raw, aad_b64)
        }
        "crypto.aes_gcm_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let nonce_raw = require_str_arg(args, 2, "nonce")?;
            let aad_b64 = args.get(3).and_then(Value::as_str).map(ToString::to_string);
            crypto_aes_gcm_decrypt_b64(payload_b64, key_raw, nonce_raw, aad_b64)
        }
        _ => panic!("dispatch_crypto_route 被传入非 crypto 路由: {name}"),
    }
}

fn crypto_md5_bytes(input: Vec<u8>) -> AnyResult<Value> {
    let digest = md5::compute(&input);
    Ok(json!(format!("{:x}", digest)))
}

fn crypto_sha1_bytes(input: Vec<u8>) -> AnyResult<Value> {
    let mut hasher = Sha1::new();
    hasher.update(&input);
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_sha512_bytes(input: Vec<u8>) -> AnyResult<Value> {
    let mut hasher = Sha512::new();
    hasher.update(&input);
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_sha256_bytes(input: Vec<u8>) -> AnyResult<Value> {
    let mut hasher = Sha256::new();
    hasher.update(&input);
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_hmac_sha1_bytes(key: Vec<u8>, input: Vec<u8>) -> AnyResult<Value> {
    let mut mac =
        <Hmac<Sha1> as Mac>::new_from_slice(&key).map_err(|_| anyhow!("HMAC-SHA1 密钥无效"))?;
    mac.update(&input);
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_hmac_sha512_bytes(key: Vec<u8>, input: Vec<u8>) -> AnyResult<Value> {
    let mut mac =
        <Hmac<Sha512> as Mac>::new_from_slice(&key).map_err(|_| anyhow!("HMAC-SHA512 密钥无效"))?;
    mac.update(&input);
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_hmac_sha256_bytes(key: Vec<u8>, input: Vec<u8>) -> AnyResult<Value> {
    let mut mac =
        <Hmac<Sha256> as Mac>::new_from_slice(&key).map_err(|_| anyhow!("HMAC-SHA256 密钥无效"))?;
    mac.update(&input);
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_aes_ecb_pkcs7_decrypt_bytes(payload: Vec<u8>, key: Vec<u8>) -> AnyResult<Value> {
    let plain = super::aes_ecb_decrypt_pkcs7(&payload, &key)?;
    Ok(json!(plain))
}

fn crypto_aes_ecb_pkcs7_encrypt_bytes(input: Vec<u8>, key: Vec<u8>) -> AnyResult<Value> {
    let cipher = super::aes_ecb_encrypt_pkcs7(&input, &key)?;
    Ok(json!(cipher))
}

fn crypto_aes_cbc_pkcs7_encrypt_bytes(
    plain: Vec<u8>,
    key: Vec<u8>,
    iv: Vec<u8>,
) -> AnyResult<Value> {
    let out = match key.len() {
        16 => {
            let cipher = CbcEncryptor::<Aes128>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-128 CBC 加密失败"))?
                .to_vec()
        }
        24 => {
            let cipher = CbcEncryptor::<Aes192>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-192 CBC 加密失败"))?
                .to_vec()
        }
        32 => {
            let cipher = CbcEncryptor::<Aes256>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-256 CBC 加密失败"))?
                .to_vec()
        }
        _ => {
            return Err(anyhow!(
                "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(out))
}

fn crypto_aes_cbc_pkcs7_decrypt_bytes(
    mut payload: Vec<u8>,
    key: Vec<u8>,
    iv: Vec<u8>,
) -> AnyResult<Value> {
    let plain = match key.len() {
        16 => CbcDecryptor::<Aes128>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-128 CBC 解密失败"))?
            .to_vec(),
        24 => CbcDecryptor::<Aes192>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-192 CBC 解密失败"))?
            .to_vec(),
        32 => CbcDecryptor::<Aes256>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-256 CBC 解密失败"))?
            .to_vec(),
        _ => {
            return Err(anyhow!(
                "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(plain))
}

fn crypto_aes_gcm_encrypt_bytes(
    plain: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
    aad: Option<Vec<u8>>,
) -> AnyResult<Value> {
    let aad = aad.unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &plain,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 加密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &plain,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-256 GCM 加密失败"))?
        }
        _ => {
            return Err(anyhow!(
                "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(out))
}

fn crypto_aes_gcm_decrypt_bytes(
    payload: Vec<u8>,
    key: Vec<u8>,
    nonce: Vec<u8>,
    aad: Option<Vec<u8>>,
) -> AnyResult<Value> {
    let aad = aad.unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &payload,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 解密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &payload,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-256 GCM 解密失败"))?
        }
        _ => {
            return Err(anyhow!(
                "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(out))
}

fn require_arg<'a>(args: &'a [Value], index: usize, name: &str) -> AnyResult<&'a Value> {
    args.get(index).ok_or_else(|| anyhow!("缺少参数: {name}"))
}

fn require_str_arg(args: &[Value], index: usize, name: &str) -> AnyResult<String> {
    require_arg(args, index, name)?
        .as_str()
        .map(ToString::to_string)
        .ok_or_else(|| anyhow!("参数 {name} 必须是字符串"))
}

fn parse_u8_json_value(value: &Value) -> AnyResult<Vec<u8>> {
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

// 以下函数已废弃，仅保留对旧版 _hex / _b64 路由的兼容。

fn crypto_md5_hex(input: String) -> AnyResult<Value> {
    let digest = md5::compute(input.as_bytes());
    Ok(json!(format!("{:x}", digest)))
}

fn crypto_sha1_hex(input: String) -> AnyResult<Value> {
    let mut hasher = Sha1::new();
    hasher.update(input.as_bytes());
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_sha512_hex(input: String) -> AnyResult<Value> {
    let mut hasher = Sha512::new();
    hasher.update(input.as_bytes());
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_sha256_hex(input: String) -> AnyResult<Value> {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    Ok(json!(format!("{:x}", hasher.finalize())))
}

fn crypto_hmac_sha1_hex(key: String, input: String) -> AnyResult<Value> {
    let mut mac = <Hmac<Sha1> as Mac>::new_from_slice(key.as_bytes())
        .map_err(|_| anyhow!("HMAC-SHA1 密钥无效"))?;
    mac.update(input.as_bytes());
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_hmac_sha512_hex(key: String, input: String) -> AnyResult<Value> {
    let mut mac = <Hmac<Sha512> as Mac>::new_from_slice(key.as_bytes())
        .map_err(|_| anyhow!("HMAC-SHA512 密钥无效"))?;
    mac.update(input.as_bytes());
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_hmac_sha256_hex(key: String, input: String) -> AnyResult<Value> {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(key.as_bytes())
        .map_err(|_| anyhow!("HMAC-SHA256 密钥无效"))?;
    mac.update(input.as_bytes());
    Ok(json!(format!("{:x}", mac.finalize().into_bytes())))
}

fn crypto_aes_ecb_pkcs7_decrypt_b64(payload_b64: String, key_raw: String) -> AnyResult<Value> {
    let payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let plain = super::aes_ecb_decrypt_pkcs7(&payload, &key)?;

    let text = String::from_utf8(plain).context("解密结果不是有效 UTF-8")?;
    Ok(json!(text))
}

fn crypto_aes_cbc_pkcs7_encrypt_b64(
    plain_b64: String,
    key_raw: String,
    iv_raw: String,
) -> AnyResult<Value> {
    let plain = BASE64_STANDARD
        .decode(plain_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let iv = iv_raw.into_bytes();
    let out = match key.len() {
        16 => {
            let cipher = CbcEncryptor::<Aes128>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-128 CBC 加密失败"))?
                .to_vec()
        }
        24 => {
            let cipher = CbcEncryptor::<Aes192>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-192 CBC 加密失败"))?
                .to_vec()
        }
        32 => {
            let cipher = CbcEncryptor::<Aes256>::new_from_slices(&key, &iv)
                .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?;
            let mut buf = plain.clone();
            let msg_len = buf.len();
            buf.resize(msg_len + 16, 0);
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!("AES-256 CBC 加密失败"))?
                .to_vec()
        }
        _ => {
            return Err(anyhow!(
                "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(BASE64_STANDARD.encode(out)))
}

fn crypto_aes_cbc_pkcs7_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    iv_raw: String,
) -> AnyResult<Value> {
    let mut payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let iv = iv_raw.into_bytes();
    let plain = match key.len() {
        16 => CbcDecryptor::<Aes128>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-128 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-128 CBC 解密失败"))?
            .to_vec(),
        24 => CbcDecryptor::<Aes192>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-192 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-192 CBC 解密失败"))?
            .to_vec(),
        32 => CbcDecryptor::<Aes256>::new_from_slices(&key, &iv)
            .map_err(|_| anyhow!("AES-256 CBC 参数无效"))?
            .decrypt_padded_mut::<Pkcs7>(&mut payload)
            .map_err(|_| anyhow!("AES-256 CBC 解密失败"))?
            .to_vec(),
        _ => {
            return Err(anyhow!(
                "AES CBC 密钥长度必须是 16/24/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(BASE64_STANDARD.encode(plain)))
}

fn crypto_aes_gcm_encrypt_b64(
    plain_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> AnyResult<Value> {
    let plain = BASE64_STANDARD
        .decode(plain_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let nonce = nonce_raw.into_bytes();
    let aad = aad_b64
        .map(|raw| {
            BASE64_STANDARD
                .decode(raw.as_bytes())
                .context("base64 解码失败")
        })
        .transpose()?
        .unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &plain,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 加密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .encrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &plain,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-256 GCM 加密失败"))?
        }
        _ => {
            return Err(anyhow!(
                "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(BASE64_STANDARD.encode(out)))
}

fn crypto_aes_gcm_decrypt_b64(
    payload_b64: String,
    key_raw: String,
    nonce_raw: String,
    aad_b64: Option<String>,
) -> AnyResult<Value> {
    let payload = BASE64_STANDARD
        .decode(payload_b64.as_bytes())
        .context("base64 解码失败")?;
    let key = key_raw.into_bytes();
    let nonce = nonce_raw.into_bytes();
    let aad = aad_b64
        .map(|raw| {
            BASE64_STANDARD
                .decode(raw.as_bytes())
                .context("base64 解码失败")
        })
        .transpose()?
        .unwrap_or_default();
    let out = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(&key).context("AES-128 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &payload,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-128 GCM 解密失败"))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(&key).context("AES-256 GCM 参数无效")?;
            cipher
                .decrypt(
                    Nonce::from_slice(&nonce),
                    AeadPayload {
                        msg: &payload,
                        aad: &aad,
                    },
                )
                .map_err(|_| anyhow!("AES-256 GCM 解密失败"))?
        }
        _ => {
            return Err(anyhow!(
                "AES GCM 密钥长度必须是 16/32 字节，当前: {}",
                key.len()
            ));
        }
    };
    Ok(json!(BASE64_STANDARD.encode(out)))
}
