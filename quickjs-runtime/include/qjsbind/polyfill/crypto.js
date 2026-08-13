// crypto.js —— Breeze 风格 crypto API polyfill（对齐 kit types/crypto.d.ts 签名）
//
// 依赖（由 install_crypto 的 C++ 侧注册）：
//   同步版（createHash/createHmac 的 digest 用，Node 同步语义）：
//     __crypto_hash / __crypto_hmac / __crypto_aes_{ecb,cbc,gcm}_{en,de}crypt /
//     __crypto_random_bytes / __crypto_pbkdf2 / __crypto_timing_safe_equal /
//     __crypto_hex_encode（原生 hex 编码，Boost.Algorithm hex_lower）
//   异步版（Promise 方法用；后台线程池计算、不阻塞 JS 事件循环）：
//     __crypto_hash_async / __crypto_hmac_async / __crypto_aes_*_async /
//     __crypto_pbkdf2_async
//   原生 base64（B64 变体用，不设 JS 回退）：
//     bytesToBase64 / bytesFromBase64（runtime_api.js 注册，BoringSSL；
//     install_runtime_api 必须先于 install_crypto 安装）
//   原生 TextEncoder/TextDecoder（utf8 编解码，不设 JS 回退）：
//     install_crypto 无条件安装（web/encoding.hpp，registry.ensure 幂等）
//
// 本文件负责：输入收窄（BinaryInput | string → 字节，UTF-8）、hex 编解码
// （原生）、latin1 编解码、流式 createHash/createHmac、Promise 方法（真异步）、
// B64 变体（deprecated）、pbkdf2 callback。挂载 crypto / hostCrypto /
// nodeCryptoCompat 三个全局（requireCryptoLike 依次探测）。
(function () {
  "use strict";

  // ---- 字节工具（hex 编解码走原生 __crypto_hex_{encode,decode}；latin1 自实现；base64 与 utf8 走原生）----
  // TextEncoder/TextDecoder 由 install_crypto 无条件安装（BoringSSL 无关，
  // web/encoding.hpp 的 C++ 绑定）；单例复用（encode/decode 无状态）。
  const textEncoder = new TextEncoder();
  const textDecoder = new TextDecoder();
  function toBytes(input) {
    if (input instanceof Uint8Array) return input;
    if (input instanceof ArrayBuffer) return new Uint8Array(input);
    if (ArrayBuffer.isView(input)) {
      return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
    }
    if (Array.isArray(input)) return Uint8Array.from(input);
    throw new TypeError(
      "crypto: 需要二进制输入（ArrayBuffer/TypedArray/DataView/number[]）",
    );
  }

  // 字符串 → UTF-8 字节（TextInput 的 string 分支；原生 TextEncoder）
  function utf8Encode(str) {
    return textEncoder.encode(str);
  }

  function utf8Decode(bytes) {
    return textDecoder.decode(bytes);
  }

  // hex 编码：原生（__crypto_hex_encode，Boost.Algorithm hex_lower），不设 JS 回退
  function hexEncode(bytes) {
    return __crypto_hex_encode(bytes);
  }

  // hex 解码：原生（__crypto_hex_decode，Boost.Algorithm unhex），不设 JS 回退
  function hexDecode(str) {
    return __crypto_hex_decode(str);
  }

  // base64：只调原生（runtime_api 的 bytesToBase64/bytesFromBase64，
  // BoringSSL 实现；install_runtime_api 必须先于 install_crypto 安装）
  function b64Encode(bytes) {
    return globalThis.bytesToBase64(bytes);
  }

  function b64Decode(text) {
    return globalThis.bytesFromBase64(text);
  }

  // TextInput → 字节（string 按 UTF-8）
  function textToBytes(input) {
    if (typeof input === "string") return utf8Encode(input);
    return toBytes(input);
  }

  // update() 的输入编码
  function decodeInput(data, encoding) {
    if (typeof data !== "string") return toBytes(data); // 二进制入参忽略 encoding
    switch (encoding) {
      case undefined:
      case null:
      case "utf8":
      case "utf-8":
        return utf8Encode(data);
      case "hex":
        return hexDecode(data);
      case "base64":
        return b64Decode(data);
      case "latin1":
      case "binary": {
        const out = new Uint8Array(data.length);
        for (let i = 0; i < data.length; ++i)
          out[i] = data.charCodeAt(i) & 0xff;
        return out;
      }
      default:
        throw new TypeError("crypto: 未知输入编码 " + encoding);
    }
  }

  // digest() 的输出编码（默认 buffer → Buffer；无 Buffer 时 Uint8Array）
  function encodeOutput(bytes, encoding) {
    if (encoding === undefined || encoding === null || encoding === "buffer") {
      const Buf = globalThis.Buffer;
      return Buf ? Buf.from(bytes) : bytes;
    }
    switch (encoding) {
      case "hex":
        return hexEncode(bytes);
      case "base64":
        return b64Encode(bytes);
      case "latin1":
      case "binary": {
        let out = "";
        for (let i = 0; i < bytes.length; ++i)
          out += String.fromCharCode(bytes[i]);
        return out;
      }
      case "utf8":
      case "utf-8":
        return utf8Decode(bytes);
      default:
        throw new TypeError("crypto: 未知输出编码 " + encoding);
    }
  }

  // ---- 流式 createHash / createHmac（digest 走同步 native，Node 语义）----
  function makeDigestObject(alg, hmacKey) {
    let chunks = [];
    return {
      update(data, inputEncoding) {
        const bytes = decodeInput(data, inputEncoding);
        chunks.push(bytes);
        return this;
      },
      digest(encoding) {
        // 拼接累计字节（分块不拷贝多次：最后一并 concat）
        let total = 0;
        for (const b of chunks) total += b.length;
        const merged = new Uint8Array(total);
        let off = 0;
        for (const b of chunks) {
          merged.set(b, off);
          off += b.length;
        }
        chunks = [];
        const out =
          hmacKey === null
            ? globalThis.__crypto_hash(alg, merged)
            : globalThis.__crypto_hmac(alg, hmacKey, merged);
        return encodeOutput(out, encoding);
      },
    };
  }

  // Promise 包装：参数求值/提取放进 then 体内——同步异常变成 reject
  //（符合 Node/async 语义）；async native（__crypto_*_async）为 stdexec 协程
  //（后台线程池 fetch::file_pool 计算 + post 回 JS 线程结算），大计算不阻塞
  // JS 事件循环。
  function prom(fn) {
    return Promise.resolve().then(fn);
  }

  const crypto = {
    createHash(algorithm) {
      return makeDigestObject(String(algorithm), null);
    },
    createHmac(algorithm, key) {
      return makeDigestObject(String(algorithm), textToBytes(key));
    },

    // ---- 摘要（hex 字符串 Promise；真异步）----
    md5(input) {
      return prom(() =>
        globalThis.__crypto_hash_async("md5", textToBytes(input)),
      ).then(hexEncode);
    },
    sha1(input) {
      return prom(() =>
        globalThis.__crypto_hash_async("sha1", textToBytes(input)),
      ).then(hexEncode);
    },
    sha256(input) {
      return prom(() =>
        globalThis.__crypto_hash_async("sha256", textToBytes(input)),
      ).then(hexEncode);
    },
    sha512(input) {
      return prom(() =>
        globalThis.__crypto_hash_async("sha512", textToBytes(input)),
      ).then(hexEncode);
    },
    hmacSha1(key, input) {
      return prom(() =>
        globalThis.__crypto_hmac_async(
          "sha1",
          textToBytes(key),
          textToBytes(input),
        ),
      ).then(hexEncode);
    },
    hmacSha256(key, input) {
      return prom(() =>
        globalThis.__crypto_hmac_async(
          "sha256",
          textToBytes(key),
          textToBytes(input),
        ),
      ).then(hexEncode);
    },
    hmacSha512(key, input) {
      return prom(() =>
        globalThis.__crypto_hmac_async(
          "sha512",
          textToBytes(key),
          textToBytes(input),
        ),
      ).then(hexEncode);
    },

    // ---- AES（Promise<Uint8Array>；真异步；keyRaw/ivRaw/nonceRaw 字符串按 UTF-8）----
    aesEcbPkcs7Encrypt(input, keyRaw) {
      return prom(() =>
        globalThis.__crypto_aes_ecb_encrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
        ),
      );
    },
    aesEcbPkcs7Decrypt(input, keyRaw) {
      return prom(() =>
        globalThis.__crypto_aes_ecb_decrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
        ),
      );
    },
    aesCbcPkcs7Encrypt(input, keyRaw, ivRaw) {
      return prom(() =>
        globalThis.__crypto_aes_cbc_encrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
          textToBytes(ivRaw),
        ),
      );
    },
    aesCbcPkcs7Decrypt(input, keyRaw, ivRaw) {
      return prom(() =>
        globalThis.__crypto_aes_cbc_decrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
          textToBytes(ivRaw),
        ),
      );
    },
    // deprecated B64 变体：payload/aad 为 base64 字符串，结果 base64 字符串
    aesCbcPkcs7EncryptB64(payloadB64, keyRaw, ivRaw) {
      return prom(() =>
        globalThis.__crypto_aes_cbc_encrypt_async(
          b64Decode(payloadB64),
          textToBytes(keyRaw),
          textToBytes(ivRaw),
        ),
      ).then(b64Encode);
    },
    aesCbcPkcs7DecryptB64(payloadB64, keyRaw, ivRaw) {
      return prom(() =>
        globalThis.__crypto_aes_cbc_decrypt_async(
          b64Decode(payloadB64),
          textToBytes(keyRaw),
          textToBytes(ivRaw),
        ),
      ).then(b64Encode);
    },
    aesGcmEncrypt(input, keyRaw, nonceRaw, aad) {
      return prom(() =>
        globalThis.__crypto_aes_gcm_encrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
          textToBytes(nonceRaw),
          aad === null || aad === undefined ? null : textToBytes(aad),
        ),
      );
    },
    aesGcmDecrypt(input, keyRaw, nonceRaw, aad) {
      return prom(() =>
        globalThis.__crypto_aes_gcm_decrypt_async(
          textToBytes(input),
          textToBytes(keyRaw),
          textToBytes(nonceRaw),
          aad === null || aad === undefined ? null : textToBytes(aad),
        ),
      );
    },
    aesGcmEncryptB64(payloadB64, keyRaw, nonceRaw, aadB64) {
      return prom(() =>
        globalThis.__crypto_aes_gcm_encrypt_async(
          b64Decode(payloadB64),
          textToBytes(keyRaw),
          textToBytes(nonceRaw),
          aadB64 === null || aadB64 === undefined ? null : b64Decode(aadB64),
        ),
      ).then(b64Encode);
    },
    aesGcmDecryptB64(payloadB64, keyRaw, nonceRaw, aadB64) {
      return prom(() =>
        globalThis.__crypto_aes_gcm_decrypt_async(
          b64Decode(payloadB64),
          textToBytes(keyRaw),
          textToBytes(nonceRaw),
          aadB64 === null || aadB64 === undefined ? null : b64Decode(aadB64),
        ),
      ).then(b64Encode);
    },

    // ---- 随机 / UUID ----
    randomBytes(size) {
      const bytes = globalThis.__crypto_random_bytes(size);
      const Buf = globalThis.Buffer;
      return Buf ? Buf.from(bytes) : bytes;
    },
    randomUUID() {
      if (typeof globalThis.uuidv4 === "function") return globalThis.uuidv4();
      const b = globalThis.__crypto_random_bytes(16);
      b[6] = (b[6] & 0x0f) | 0x40; // version 4
      b[8] = (b[8] & 0x3f) | 0x80; // variant
      return (
        hexEncode(b.subarray(0, 4)) +
        "-" +
        hexEncode(b.subarray(4, 6)) +
        "-" +
        hexEncode(b.subarray(6, 8)) +
        "-" +
        hexEncode(b.subarray(8, 10)) +
        "-" +
        hexEncode(b.subarray(10, 16))
      );
    },

    // ---- 恒时比较（TextInput：字符串按 UTF-8）----
    timingSafeEqual(a, b) {
      return globalThis.__crypto_timing_safe_equal(
        textToBytes(a),
        textToBytes(b),
      );
    },

    // ---- PBKDF2（默认 HMAC-SHA256，对齐 kit 注释）----
    pbkdf2Sync(password, salt, iterations, keyLen, digest) {
      const alg = digest || "sha256";
      const bytes = globalThis.__crypto_pbkdf2(
        alg,
        textToBytes(password),
        textToBytes(salt),
        iterations,
        keyLen,
      );
      const Buf = globalThis.Buffer;
      return Buf ? Buf.from(bytes) : bytes;
    },
    pbkdf2(password, salt, iterations, keyLen, digest, callback) {
      // Node 风格：digest 可省略（默认 sha256）；真异步——后台线程计算，
      // 完成后异步调 callback(err, derivedKey)
      let cb = callback;
      let dg = digest;
      if (typeof digest === "function") {
        cb = digest;
        dg = "sha256";
      }
      prom(() =>
        globalThis.__crypto_pbkdf2_async(
          dg,
          textToBytes(password),
          textToBytes(salt),
          iterations,
          keyLen,
        ),
      ).then(
        (key) => {
          if (typeof cb === "function") {
            const Buf = globalThis.Buffer; // 与 pbkdf2Sync 一致：返回 Buffer
            cb(null, Buf ? Buf.from(key) : key);
          }
        },
        (e) => {
          if (typeof cb === "function") cb(e);
        },
      );
    },
  };

  // 挂载三个全局（runtime-api.ts 的 requireCryptoLike 依次探测 crypto →
  // hostCrypto → nodeCryptoCompat）
  globalThis.crypto = crypto;
  globalThis.hostCrypto = crypto;
  globalThis.nodeCryptoCompat = crypto;
})();
