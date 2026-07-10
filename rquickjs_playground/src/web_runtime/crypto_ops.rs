//! 纯算法层：crypto / hash / HMAC / AES / PBKDF2 / 随机数。
//!
//! 本模块不感知 JS 调用约定，只负责把输入字节变成输出字节。
//! 错误使用 `anyhow::Error`，由调用方（`bridge_crypto.rs` / `web_runtime.rs`）
//! 按各自协议转换成 JS 异常或 JSON 错误。

use aes::cipher::{BlockDecrypt, BlockEncrypt, KeyInit};
use aes::{Aes128, Aes192, Aes256};
use aes_gcm::{
    Aes128Gcm, Aes256Gcm, Nonce,
    aead::{Aead, Payload as AeadPayload},
};
use anyhow::{Context as _, Result, anyhow};
use cbc::cipher::{BlockDecryptMut, BlockEncryptMut, KeyIvInit, block_padding::Pkcs7};
use cbc::{Decryptor as CbcDecryptor, Encryptor as CbcEncryptor};
use getrandom::fill as random_fill;
use hmac::{Hmac, Mac};
use pbkdf2::pbkdf2_hmac;
use sha1::Sha1;
use sha2::{Digest, Sha256, Sha512};

/// 把字节数组转成小写 hex 字符串。
pub fn bytes_to_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

/// MD5 摘要。
pub fn md5(input: &[u8]) -> Vec<u8> {
    md5::compute(input).to_vec()
}

/// SHA-1 摘要。
pub fn sha1(input: &[u8]) -> Vec<u8> {
    digest::<Sha1>(input)
}

/// SHA-256 摘要。
pub fn sha256(input: &[u8]) -> Vec<u8> {
    digest::<Sha256>(input)
}

/// SHA-512 摘要。
pub fn sha512(input: &[u8]) -> Vec<u8> {
    digest::<Sha512>(input)
}

fn digest<D: Digest + Default>(input: &[u8]) -> Vec<u8> {
    let mut hasher = D::default();
    hasher.update(input);
    hasher.finalize().to_vec()
}

/// HMAC-SHA1。
pub fn hmac_sha1(key: &[u8], input: &[u8]) -> Result<Vec<u8>> {
    let mut mac = <Hmac<Sha1> as Mac>::new_from_slice(key)
        .context(crate::tr!("failed-to-initialize-hmac"))?;
    mac.update(input);
    Ok(mac.finalize().into_bytes().to_vec())
}

/// HMAC-SHA256。
pub fn hmac_sha256(key: &[u8], input: &[u8]) -> Result<Vec<u8>> {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(key)
        .context(crate::tr!("failed-to-initialize-hmac"))?;
    mac.update(input);
    Ok(mac.finalize().into_bytes().to_vec())
}

/// HMAC-SHA512。
pub fn hmac_sha512(key: &[u8], input: &[u8]) -> Result<Vec<u8>> {
    let mut mac = <Hmac<Sha512> as Mac>::new_from_slice(key)
        .context(crate::tr!("failed-to-initialize-hmac"))?;
    mac.update(input);
    Ok(mac.finalize().into_bytes().to_vec())
}

/// AES-ECB-PKCS7 解密。
pub fn aes_ecb_decrypt_pkcs7(payload: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if payload.len() % 16 != 0 {
        return Err(anyhow!(crate::tr!(
            "aes-ecb-ciphertext-length-must-be-a-multiple-of-16"
        )));
    }
    let mut out = vec![0u8; payload.len()];
    match key.len() {
        16 => {
            let cipher = Aes128::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-128-key-length-invalid")))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes128>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        24 => {
            let cipher = Aes192::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-192-key-length-invalid")))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes192>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        32 => {
            let cipher = Aes256::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-256-key-length-invalid")))?;
            for (src, dst) in payload.chunks_exact(16).zip(out.chunks_exact_mut(16)) {
                let mut block = aes::cipher::Block::<Aes256>::clone_from_slice(src);
                cipher.decrypt_block(&mut block);
                dst.copy_from_slice(&block);
            }
        }
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-ecb-key-length-must-be-16-24-32-bytes-current",
                arg0 = key.len()
            )));
        }
    }

    let pad_len = *out
        .last()
        .ok_or_else(|| anyhow!(crate::tr!("aes-ecb-decryption-result-is-empty")))?
        as usize;
    if pad_len == 0 || pad_len > 16 || pad_len > out.len() {
        return Err(anyhow!(crate::tr!("aes-ecb-pkcs7-padding-invalid")));
    }
    if !out[out.len() - pad_len..]
        .iter()
        .all(|b| *b as usize == pad_len)
    {
        return Err(anyhow!(crate::tr!("aes-ecb-pkcs7-padding-invalid")));
    }
    out.truncate(out.len() - pad_len);
    Ok(out)
}

/// AES-ECB-PKCS7 加密。
pub fn aes_ecb_encrypt_pkcs7(payload: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    let pad_len = 16 - (payload.len() % 16);
    let mut out = vec![0u8; payload.len() + pad_len];
    out[..payload.len()].copy_from_slice(payload);
    for b in out[payload.len()..].iter_mut() {
        *b = pad_len as u8;
    }

    match key.len() {
        16 => {
            let cipher = Aes128::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-128-key-length-invalid")))?;
            for chunk in out.chunks_exact_mut(16) {
                let mut block = aes::cipher::Block::<Aes128>::clone_from_slice(chunk);
                cipher.encrypt_block(&mut block);
                chunk.copy_from_slice(&block);
            }
        }
        24 => {
            let cipher = Aes192::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-192-key-length-invalid")))?;
            for chunk in out.chunks_exact_mut(16) {
                let mut block = aes::cipher::Block::<Aes192>::clone_from_slice(chunk);
                cipher.encrypt_block(&mut block);
                chunk.copy_from_slice(&block);
            }
        }
        32 => {
            let cipher = Aes256::new_from_slice(key)
                .map_err(|_| anyhow!(crate::tr!("aes-256-key-length-invalid")))?;
            for chunk in out.chunks_exact_mut(16) {
                let mut block = aes::cipher::Block::<Aes256>::clone_from_slice(chunk);
                cipher.encrypt_block(&mut block);
                chunk.copy_from_slice(&block);
            }
        }
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-ecb-key-length-must-be-16-24-32-bytes-current",
                arg0 = key.len()
            )));
        }
    }

    Ok(out)
}

/// AES-CBC-PKCS7 加密。
pub fn aes_cbc_pkcs7_encrypt(plain: &[u8], key: &[u8], iv: &[u8]) -> Result<Vec<u8>> {
    let mut buf = plain.to_vec();
    let msg_len = buf.len();
    buf.resize(msg_len + 16, 0);

    let encrypted = match key.len() {
        16 => {
            let cipher = CbcEncryptor::<Aes128>::new_from_slices(key, iv)
                .map_err(|_| anyhow!(crate::tr!("aes-128-cbc-parameters-invalid")))?;
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!(crate::tr!("aes-128-cbc-encryption-failed")))?
                .to_vec()
        }
        24 => {
            let cipher = CbcEncryptor::<Aes192>::new_from_slices(key, iv)
                .map_err(|_| anyhow!(crate::tr!("aes-192-cbc-parameters-invalid")))?;
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!(crate::tr!("aes-192-cbc-encryption-failed")))?
                .to_vec()
        }
        32 => {
            let cipher = CbcEncryptor::<Aes256>::new_from_slices(key, iv)
                .map_err(|_| anyhow!(crate::tr!("aes-256-cbc-parameters-invalid")))?;
            cipher
                .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
                .map_err(|_| anyhow!(crate::tr!("aes-256-cbc-encryption-failed")))?
                .to_vec()
        }
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-cbc-key-length-must-be-16-24-32-bytes-current",
                arg0 = key.len()
            )));
        }
    };

    Ok(encrypted)
}

/// AES-CBC-PKCS7 解密。
pub fn aes_cbc_pkcs7_decrypt(payload: &[u8], key: &[u8], iv: &[u8]) -> Result<Vec<u8>> {
    let mut buf = payload.to_vec();
    let plain = match key.len() {
        16 => CbcDecryptor::<Aes128>::new_from_slices(key, iv)
            .map_err(|e| anyhow!(crate::tr!("aes-128-cbc-parameters-invalid-2", arg0 = e)))?
            .decrypt_padded_mut::<Pkcs7>(&mut buf)
            .map_err(|e| anyhow!(crate::tr!("aes-128-cbc-decryption-failed", arg0 = e)))?
            .to_vec(),
        24 => CbcDecryptor::<Aes192>::new_from_slices(key, iv)
            .map_err(|e| anyhow!(crate::tr!("aes-192-cbc-parameters-invalid-2", arg0 = e)))?
            .decrypt_padded_mut::<Pkcs7>(&mut buf)
            .map_err(|e| anyhow!(crate::tr!("aes-192-cbc-decryption-failed", arg0 = e)))?
            .to_vec(),
        32 => CbcDecryptor::<Aes256>::new_from_slices(key, iv)
            .map_err(|e| anyhow!(crate::tr!("aes-256-cbc-parameters-invalid-2", arg0 = e)))?
            .decrypt_padded_mut::<Pkcs7>(&mut buf)
            .map_err(|e| anyhow!(crate::tr!("aes-256-cbc-decryption-failed", arg0 = e)))?
            .to_vec(),
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-cbc-key-length-must-be-16-24-32-bytes-current",
                arg0 = key.len()
            )));
        }
    };
    Ok(plain)
}

/// AES-GCM 加密。
pub fn aes_gcm_encrypt(
    plain: &[u8],
    key: &[u8],
    nonce: &[u8],
    aad: Option<&[u8]>,
) -> Result<Vec<u8>> {
    let aad = aad.unwrap_or_default();
    let cipher_text = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(key)
                .context(crate::tr!("aes-128-gcm-parameters-invalid"))?;
            let nonce = Nonce::from_slice(nonce);
            cipher
                .encrypt(nonce, AeadPayload { msg: plain, aad })
                .map_err(|_| anyhow!(crate::tr!("aes-128-gcm-encryption-failed")))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(key)
                .context(crate::tr!("aes-256-gcm-parameters-invalid"))?;
            let nonce = Nonce::from_slice(nonce);
            cipher
                .encrypt(nonce, AeadPayload { msg: plain, aad })
                .map_err(|_| anyhow!(crate::tr!("aes-256-gcm-encryption-failed")))?
        }
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-gcm-key-length-must-be-16-32-bytes-current",
                arg0 = key.len()
            )));
        }
    };
    Ok(cipher_text)
}

/// AES-GCM 解密。
pub fn aes_gcm_decrypt(
    payload: &[u8],
    key: &[u8],
    nonce: &[u8],
    aad: Option<&[u8]>,
) -> Result<Vec<u8>> {
    let aad = aad.unwrap_or_default();
    let plain = match key.len() {
        16 => {
            let cipher = Aes128Gcm::new_from_slice(key)
                .context(crate::tr!("aes-128-gcm-parameters-invalid"))?;
            let nonce = Nonce::from_slice(nonce);
            cipher
                .decrypt(nonce, AeadPayload { msg: payload, aad })
                .map_err(|_| anyhow!(crate::tr!("aes-128-gcm-decryption-failed")))?
        }
        32 => {
            let cipher = Aes256Gcm::new_from_slice(key)
                .context(crate::tr!("aes-256-gcm-parameters-invalid"))?;
            let nonce = Nonce::from_slice(nonce);
            cipher
                .decrypt(nonce, AeadPayload { msg: payload, aad })
                .map_err(|_| anyhow!(crate::tr!("aes-256-gcm-decryption-failed")))?
        }
        _ => {
            return Err(anyhow!(crate::tr!(
                "aes-gcm-key-length-must-be-16-32-bytes-current",
                arg0 = key.len()
            )));
        }
    };
    Ok(plain)
}

/// PBKDF2-HMAC-SHA256 派生。
///
/// `iterations` 与 `key_len` 已由调用方校验为正数/非负数。
pub fn pbkdf2_sha256(password: &[u8], salt: &[u8], iterations: u32, key_len: usize) -> Vec<u8> {
    let mut out = vec![0u8; key_len];
    pbkdf2_hmac::<Sha256>(password, salt, iterations, &mut out);
    out
}

/// 生成密码学安全随机字节。
pub fn random_bytes(size: usize) -> Result<Vec<u8>> {
    let mut bytes = vec![0u8; size];
    random_fill(&mut bytes).context(crate::tr!("failed-to-generate-random-bytes"))?;
    Ok(bytes)
}
