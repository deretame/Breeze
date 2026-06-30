//! Bridge crypto 路由实现。
//!
//! 注意：crypto 相关路由只接受原始二进制数据。
//! 如果需要传入 base64 或字符串，请先在 JS 层转换为 Uint8Array：
//!   - base64: 使用全局的 bytesFromBase64(base64String)
//!   - 字符串: 使用 new TextEncoder().encode(string) 或 encodeUtf8(string)
//!
//! 核心算法已抽到同目录的 [`crypto_ops`]，本文件只负责：
//!   1. 按 bridge 协议解析参数；
//!   2. 调用 [`crypto_ops`]；
//!   3. 把结果包成 `serde_json::Value` 返回。

use super::*;

use anyhow::anyhow;
use base64::engine::general_purpose::STANDARD as BASE64_STANDARD;

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
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::md5(&input))))
        }
        "crypto.sha1" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha1(&input))))
        }
        "crypto.sha256" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha256(&input))))
        }
        "crypto.sha512" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha512(&input))))
        }
        "crypto.hmac_sha1" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha1(
                &key, &input
            )?)))
        }
        "crypto.hmac_sha256" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha256(
                &key, &input
            )?)))
        }
        "crypto.hmac_sha512" => {
            let key = parse_u8_json_value(require_arg(args, 0, "key")?)?;
            let input = parse_u8_json_value(require_arg(args, 1, "input")?)?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha512(
                &key, &input
            )?)))
        }
        "crypto.aes_ecb_pkcs7_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            Ok(json!(crypto_ops::aes_ecb_decrypt_pkcs7(&input, &key)?))
        }
        "crypto.aes_ecb_pkcs7_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            Ok(json!(crypto_ops::aes_ecb_encrypt_pkcs7(&input, &key)?))
        }
        "crypto.aes_cbc_pkcs7_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let iv = parse_u8_json_value(require_arg(args, 2, "iv")?)?;
            Ok(json!(crypto_ops::aes_cbc_pkcs7_decrypt(&input, &key, &iv)?))
        }
        "crypto.aes_cbc_pkcs7_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let iv = parse_u8_json_value(require_arg(args, 2, "iv")?)?;
            Ok(json!(crypto_ops::aes_cbc_pkcs7_encrypt(&input, &key, &iv)?))
        }
        "crypto.aes_gcm_decrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let nonce = parse_u8_json_value(require_arg(args, 2, "nonce")?)?;
            let aad = args.get(3).map(|v| parse_u8_json_value(v)).transpose()?;
            Ok(json!(crypto_ops::aes_gcm_decrypt(
                &input,
                &key,
                &nonce,
                aad.as_deref()
            )?))
        }
        "crypto.aes_gcm_encrypt" => {
            let input = parse_u8_json_value(require_arg(args, 0, "input")?)?;
            let key = parse_u8_json_value(require_arg(args, 1, "key")?)?;
            let nonce = parse_u8_json_value(require_arg(args, 2, "nonce")?)?;
            let aad = args.get(3).map(|v| parse_u8_json_value(v)).transpose()?;
            Ok(json!(crypto_ops::aes_gcm_encrypt(
                &input,
                &key,
                &nonce,
                aad.as_deref()
            )?))
        }
        // 以下路由已废弃，仅保留兼容。
        "crypto.md5_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::md5(
                input.as_bytes()
            ))))
        }
        "crypto.sha1_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha1(
                input.as_bytes()
            ))))
        }
        "crypto.sha256_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha256(
                input.as_bytes()
            ))))
        }
        "crypto.sha512_hex" => {
            let input = require_str_arg(args, 0, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::sha512(
                input.as_bytes()
            ))))
        }
        "crypto.hmac_sha1_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha1(
                key.as_bytes(),
                input.as_bytes()
            )?)))
        }
        "crypto.hmac_sha256_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha256(
                key.as_bytes(),
                input.as_bytes()
            )?)))
        }
        "crypto.hmac_sha512_hex" => {
            let key = require_str_arg(args, 0, "key")?;
            let input = require_str_arg(args, 1, "input")?;
            Ok(json!(crypto_ops::bytes_to_hex(&crypto_ops::hmac_sha512(
                key.as_bytes(),
                input.as_bytes()
            )?)))
        }
        "crypto.aes_ecb_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let payload = BASE64_STANDARD
                .decode(payload_b64.as_bytes())
                .context("base64 解码失败")?;
            let key = key_raw.into_bytes();
            let plain = crypto_ops::aes_ecb_decrypt_pkcs7(&payload, &key)?;
            let text = String::from_utf8(plain).context("解密结果不是有效 UTF-8")?;
            Ok(json!(text))
        }
        "crypto.aes_cbc_pkcs7_encrypt_b64" => {
            let plain_b64 = require_str_arg(args, 0, "plain")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let iv_raw = require_str_arg(args, 2, "iv")?;
            let plain = BASE64_STANDARD
                .decode(plain_b64.as_bytes())
                .context("base64 解码失败")?;
            let key = key_raw.into_bytes();
            let iv = iv_raw.into_bytes();
            let out = crypto_ops::aes_cbc_pkcs7_encrypt(&plain, &key, &iv)?;
            Ok(json!(BASE64_STANDARD.encode(out)))
        }
        "crypto.aes_cbc_pkcs7_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let iv_raw = require_str_arg(args, 2, "iv")?;
            let payload = BASE64_STANDARD
                .decode(payload_b64.as_bytes())
                .context("base64 解码失败")?;
            let key = key_raw.into_bytes();
            let iv = iv_raw.into_bytes();
            let plain = crypto_ops::aes_cbc_pkcs7_decrypt(&payload, &key, &iv)?;
            Ok(json!(BASE64_STANDARD.encode(plain)))
        }
        "crypto.aes_gcm_encrypt_b64" => {
            let plain_b64 = require_str_arg(args, 0, "plain")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let nonce_raw = require_str_arg(args, 2, "nonce")?;
            let aad_b64 = args.get(3).and_then(Value::as_str).map(ToString::to_string);
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
                .transpose()?;
            let out = crypto_ops::aes_gcm_encrypt(&plain, &key, &nonce, aad.as_deref())?;
            Ok(json!(BASE64_STANDARD.encode(out)))
        }
        "crypto.aes_gcm_decrypt_b64" => {
            let payload_b64 = require_str_arg(args, 0, "payload")?;
            let key_raw = require_str_arg(args, 1, "key")?;
            let nonce_raw = require_str_arg(args, 2, "nonce")?;
            let aad_b64 = args.get(3).and_then(Value::as_str).map(ToString::to_string);
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
                .transpose()?;
            let out = crypto_ops::aes_gcm_decrypt(&payload, &key, &nonce, aad.as_deref())?;
            Ok(json!(BASE64_STANDARD.encode(out)))
        }
        _ => panic!("dispatch_crypto_route 被传入非 crypto 路由: {name}"),
    }
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
