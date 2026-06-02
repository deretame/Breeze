# 运行时 API

Breeze 插件运行在 QuickJS-NG 引擎中，不是 Node.js 也不是浏览器环境。
下面列出标准 ECMAScript 之外，运行时额外提供的全局 API。

## 全局对象

插件启动后可直接使用的全局对象：

- `fetch` / `Request` / `Response` / `Headers`
- `AbortController` / `AbortSignal`
- `URL` / `URLSearchParams`
- `Blob` / `File` / `FormData`
- `structuredClone`
- `console`
- `crypto`
- `TextEncoder` / `TextDecoder`
- `Buffer`
- `native`
- `bridge`
- `path`
- `uuidv4`

## fetch

标准 `fetch` 实现。

```js
const res = await fetch("https://api.example.com/data");
const data = await res.json();          // JSON
const text = await res.text();          // 文本
const blob = await res.blob();          // Blob
const buf = await res.arrayBuffer();    // ArrayBuffer
```

配套对象 `Request`、`Response`、`Headers`、`AbortController`、`AbortSignal`、`FormData`、`Blob`、`File` 均可用。

```js
// 超时控制
const ac = new AbortController();
setTimeout(() => ac.abort(), 10000);
const res = await fetch(url, { signal: ac.signal });

// 或
const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
```

### 二进制响应优化

对于返回二进制的接口，在请求头中加入以下字段可让宿主直接以二进制方式解析响应，避免不必要的类型转换：

```
x-rquickjs-host-offload-binary-v1: 1
```

```js
const res = await fetch(url, {
  headers: { "x-rquickjs-host-offload-binary-v1": "1" }
});
const buf = await res.arrayBuffer();
```

## bridge

插件与 Rust 宿主通信的唯一桥梁。

### 方法

- `bridge.call(name, ...args)` — 异步调用宿主路由
- `bridge.callSync(name, ...args)` — 同步调用（会阻塞，谨慎使用）
- `bridge.gzipCompress(input)` — gzip 压缩
- `bridge.gzipDecompress(input)` — gzip 解压

### 内建路由

以下路由开箱即用，无需注册：

**摘要**
- `crypto.md5_hex`
- `crypto.sha1_hex`
- `crypto.sha512_hex`
- `crypto.hmac_sha1_hex`
- `crypto.hmac_sha512_hex`

**AES**
- `crypto.aes_ecb_pkcs7_decrypt_b64`
- `crypto.aes_cbc_pkcs7_encrypt_b64`
- `crypto.aes_cbc_pkcs7_decrypt_b64`
- `crypto.aes_gcm_encrypt_b64`
- `crypto.aes_gcm_decrypt_b64`

**压缩**
- `compression.gzip_compress`
- `compression.gzip_decompress`

**原生**
- `native.put`
- `native.take`
- `native.exec`

**数学**
- `math.add`

### 说明

- 参数中的二进制数据会自动转为宿主端 buffer
- 返回的二进制数据会自动还原为 `Uint8Array`

```js
const md5 = await bridge.call("crypto.md5_hex", "hello");
const compressed = await bridge.call(
  "compression.gzip_compress",
  new Uint8Array([1, 2, 3]),
);
```

## native

字节缓冲池，用于管理二进制数据。大部分场景用 `fetch` 和 `bridge` 即可，不推荐直接操作。

主要方法：

- `native.put(input)` — 将数据放入缓冲池，返回 id
- `native.take(id)` — 从缓冲池取出数据
- `native.free(id)` — 释放缓冲

## console

```js
console.log("...");
console.info("...");
console.warn("...");
console.error("...");
console.debug("...");
```

输出会转到宿主日志。其他 console 方法会 fallback 到 `console.log` 同级逻辑。

## crypto

Node.js 兼容的加密 API **子集**，非完整实现。

### 支持的方法

```js
// 哈希
crypto.createHash("sha256" | "sha-256")
crypto.createHash("sha1"   | "sha-1")
crypto.createHash("sha512" | "sha-512")

// HMAC
crypto.createHmac("sha256" | "sha-256", key)
crypto.createHmac("sha1"   | "sha-1", key)
crypto.createHmac("sha512" | "sha-512", key)

// 工具
crypto.randomBytes(size)
crypto.randomUUID()
crypto.timingSafeEqual(a, b)

// PBKDF2
crypto.pbkdf2Sync(password, salt, iterations, keyLen, digest?)
crypto.pbkdf2(password, salt, iterations, keyLen, digest?, callback)

// AES 便捷包装
crypto.aesCbcPkcs7EncryptB64(payloadB64, keyRaw, ivRaw)
crypto.aesCbcPkcs7DecryptB64(payloadB64, keyRaw, ivRaw)
crypto.aesGcmEncryptB64(payloadB64, keyRaw, nonceRaw, aadB64?)
crypto.aesGcmDecryptB64(payloadB64, keyRaw, nonceRaw, aadB64?)
```

### Hash / Hmac 链式方法

```
hash.update(data, inputEncoding?) → Hash
hash.digest(encoding?) → string | Buffer
```

### 支持的编码

`utf8` / `utf-8` / `hex` / `base64` / `latin1` / `binary` / `buffer`

### 说明

- `pbkdf2`/`pbkdf2Sync` 目前固定走 sha256
- ECB 模式只提供了解密路由（通过 bridge）
- CBC 和 GCM 同时提供了 `crypto.*` 包装和 bridge 路由

```js
// crypto 对象
const hash = crypto.createHash("sha256").update("text").digest("hex");
const mac = crypto.createHmac("sha1", "key").update("text").digest("hex");

// bridge 路由
const md5 = await bridge.call("crypto.md5_hex", "text");
const decrypted = await bridge.call(
  "crypto.aes_cbc_pkcs7_decrypt_b64", payload, key, iv,
);
```

## uuidv4

```js
const id = uuidv4();
```

## Buffer

Node.js 兼容的 Buffer 子集。

```js
Buffer.from(data, encoding?)
Buffer.alloc(size)
Buffer.isBuffer(obj)
Buffer.byteLength(string, encoding?)
```

## TextEncoder / TextDecoder

UTF-8 编解码。

```js
const bytes = new TextEncoder().encode("hello");
const text = new TextDecoder().decode(bytes);
```

## structuredClone

```js
const copy = structuredClone({ a: 1, b: [2, 3] });
```

## 类型定义

示例仓库 `types/` 目录包含完整的 TypeScript 类型定义：

- `types/type.d.ts` — 插件所有 fnPath 的请求/响应结构
- `types/runtime-api.ts` — 运行时 API 的便捷封装
- `types/runtime-globals.d.ts` — 全局对象的 TypeScript 声明
- `types/runtime-api.typecheck.ts` — 运行时类型校验

建议开发时直接引用这些类型。

## 便捷封装

示例仓库 `src/tools.ts` 提供了一些常用功能的便捷封装（`cache.*`、`pluginConfig.*`、`opencc.*`、`flutterTools.*`、`runtime.*`），详细用法见源码注释。

## 常见用法

```ts
// 1. fetch 拉数据
const res = await fetch("https://api.example.com/list");
const data = await res.json();

// 2. bridge 调路由
const md5 = await bridge.call("crypto.md5_hex", "data");

// 3. console 打日志
console.log("result:", data);
```
