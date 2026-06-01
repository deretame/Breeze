# rquickjs_playground API

这是给插件作者看的 JS API 列表。这里写的是**当前代码真正可直接使用的内容**，不包含未来设想。

## 全局对象

启动后通常可直接使用：

- `fetch`
- `Request`
- `Response`
- `Headers`
- `AbortController`
- `AbortSignal`
- `URL`
- `URLSearchParams`
- `Blob`
- `File`
- `FormData`
- `structuredClone`
- `fs`
- `native`
- `bridge`
- `console`
- `crypto`
- `uuidv4`
- `path`
- `Buffer`
- `TextEncoder`
- `TextDecoder`

## `fetch`

支持标准 `fetch` 请求。

```js
const res = await fetch("https://example.com");
const text = await res.text();
```

支持的常见配套对象：

- `Request`
- `Response`
- `Headers`
- `AbortController`
- `AbortSignal`

### 备注

- `FormData` 已支持
- `Blob` / `File` 已支持
- `AbortSignal.timeout()` 已支持
- `AbortSignal.any()` 已支持

## `fs`

文件系统对象，包含 `fs` 和 `fs.promises`。

### 可用方法

- `readFile(path, encoding?)`
- `writeFile(path, data, options?)`
- `appendFile(path, data, options?)`
- `mkdir(path, options?)`
- `readdir(path, options?)`
- `stat(path)`
- `lstat(path)`
- `access(path)`
- `unlink(path)`
- `rm(path, options?)`
- `rmdir(path, options?)`
- `rename(oldPath, newPath)`
- `copyFile(src, dst)`
- `cp(src, dst, options?)`
- `realpath(path)`
- `readlink(path)`
- `symlink(target, path, type?)`
- `link(existingPath, newPath)`
- `truncate(path, len?)`
- `chmod(path, mode)`
- `utimes(path, atime, mtime)`
- `mkdtemp(prefix)`
- `open(path, flags?)`
- `opendir(path)`
- `watch(path, options?, listener?)`
- `createReadStream(path, options?)`
- `createWriteStream(path, options?)`
- `readFileAsArrayBuffer(path)` 仅 `fs.promises` 下有

### 额外类型

- `FSError`
- `Dirent`
- `Stats`
- `Dir`
- `FileHandle`
- `ReadStream`
- `WriteStream`
- `FSWatcher`

### 示例

```js
const text = await fs.promises.readFile("/tmp/a.txt", "utf8");
await fs.promises.writeFile("/tmp/b.txt", text);
```

## `native`

字节缓冲池 + 二进制算子。

### 方法

- `native.put(input)`
- `native.exec(op, inputId, args?, extraInputId?)`
- `native.execChain(inputId, steps)`
- `native.take(id)`
- `native.takeInto(id, existing, offset?)`
- `native.free(id)`
- `native.run(op, input, args?, extraInput?)`
- `native.chain(steps, inputOrId)`
- `native.gzipCompress(input)`
- `native.gzipDecompress(input)`

### 已实现算子

- `invert`
- `grayscale_rgba`
- `xor`
- `noop`

### 示例

```js
const id = await native.put(new Uint8Array([1, 2, 3, 4]));
const outId = await native.execChain(id, ["invert", "noop"]);
const out = await native.take(outId);
```

## `bridge`

调用 Rust 侧注册的路由。

### 方法

- `bridge.call(name, ...args)`
- `bridge.callSync(name, ...args)`
- `bridge.gzipCompress(input)`
- `bridge.gzipDecompress(input)`

### 内建路由

下面这些路由代码里已经自带，不用注册：

- `crypto.md5_hex`
- `crypto.sha1_hex`
- `crypto.sha512_hex`
- `crypto.hmac_sha1_hex`
- `crypto.hmac_sha512_hex`
- `crypto.aes_ecb_pkcs7_decrypt_b64`
- `crypto.aes_cbc_pkcs7_encrypt_b64`
- `crypto.aes_cbc_pkcs7_decrypt_b64`
- `crypto.aes_gcm_encrypt_b64`
- `crypto.aes_gcm_decrypt_b64`
- `compression.gzip_compress`
- `compression.gzip_decompress`
- `native.put`
- `native.take`
- `native.exec`
- `math.add`

### 说明

- 参数里的二进制会自动转成 host buffer
- 返回二进制时会自动还原成 `Uint8Array`

### 示例

```js
const out = await bridge.call(
  "compression.gzip_compress",
  new Uint8Array([1, 2, 3]),
);
```

## `console`

支持的方法：

- `console.log`
- `console.info`
- `console.debug`
- `console.warn`
- `console.error`
- `console.dir`
- `console.assert`

### 说明

- 只保证这些方法可用
- 输出会转到宿主日志
- `console.assert(false, ...)` 会按错误级别输出

## `crypto`

这是兼容层，不是完整 Node `crypto`。

### 支持的方法

- `crypto.createHash("sha256" | "sha-256")`
- `crypto.createHash("sha1" | "sha-1")`
- `crypto.createHash("sha512" | "sha-512")`
- `crypto.createHmac("sha256" | "sha-256", key)`
- `crypto.createHmac("sha1" | "sha-1", key)`
- `crypto.createHmac("sha512" | "sha-512", key)`
- `crypto.randomBytes(size)`
- `crypto.randomUUID()`
- `crypto.timingSafeEqual(a, b)`
- `crypto.pbkdf2Sync(password, salt, iterations, keyLen, digest?)`
- `crypto.pbkdf2(password, salt, iterations, keyLen, digest?, callback)`
- `crypto.aesCbcPkcs7EncryptB64(payloadB64, keyRaw, ivRaw)`
- `crypto.aesCbcPkcs7DecryptB64(payloadB64, keyRaw, ivRaw)`
- `crypto.aesGcmEncryptB64(payloadB64, keyRaw, nonceRaw, aadB64?)`
- `crypto.aesGcmDecryptB64(payloadB64, keyRaw, nonceRaw, aadB64?)`

### `Hash` / `Hmac` 支持的链式方法

- `update(data, inputEncoding?)`
- `digest(encoding?)`

### `digest` / `update` 支持的编码

- `utf8` / `utf-8`
- `hex`
- `base64`
- `latin1` / `binary`
- `buffer`

### 说明

- `pbkdf2` / `pbkdf2Sync` 目前仍然只走 `sha256`
- `AES-ECB-PKCS7` 只有解密是内建路由
- `AES-CBC-PKCS7` 和 `AES-GCM` 现在也已经提供了内建路由

### 可直接用的加密能力总结

- 直接 `crypto.*`：`sha1` / `sha256` / `sha512` 哈希，HMAC，随机数，UUID，常数时间比较，PBKDF2，以及 AES-CBC / AES-GCM 包装方法
- 通过 `bridge`：`md5`，`AES-ECB-PKCS7` 解密，gzip 压缩/解压，和其他自定义路由

### 示例

```js
const hash = crypto.createHash("sha256").update("text").digest("hex");
const mac = crypto.createHmac("sha1", "key").update("text").digest("hex");
const md5 = await bridge.call("crypto.md5_hex", "text");
const cbc = await bridge.call(
  "crypto.aes_cbc_pkcs7_decrypt_b64",
  payload,
  key,
  iv,
);
```

## `uuidv4`

直接可调用：

```js
const id = uuidv4();
```

## `path`

支持：

- `path.join`
- `path.resolve`
- `path.dirname`
- `path.basename`
- `path.extname`
- `path.isAbsolute`

### 示例

```js
const p = path.join("/a", "b", "..", "c");
```

## `Buffer`

可直接使用 `Buffer.from(...)`、`Buffer.isBuffer(...)`、`Buffer.alloc(...)` 等常见接口。

### 示例

```js
const buf = Buffer.from([1, 2, 3]);
```

## `TextEncoder` / `TextDecoder`

支持 UTF-8 编解码。

```js
const bytes = new TextEncoder().encode("hello");
const text = new TextDecoder().decode(bytes);
```

## `structuredClone`

可直接调用。

```js
const copy = structuredClone({ a: 1, b: [2, 3] });
```

## 常见用法

插件里常见的流程是：

1. 用 `fetch` 拉数据
2. 用 `fs` 读写本地文件
3. 用 `native` 处理字节
4. 用 `bridge` 调宿主路由
5. 用 `console` 打日志

## 推荐入口

如果你在写插件，优先用统一入口 `runtime`。

### 例子

```ts
import { runtime } from "../src/runtime-api";

const md5 = await runtime.md5Hex("text");
const sha1 = await runtime.sha1Hex("text");
const sha512 = await runtime.sha512Hex("text");
const key = runtime.uuidv4();
const data = await runtime.gzipCompress(new Uint8Array([1, 2, 3]));
```

### 这样做的好处

- 不用记 `bridge.call("crypto.md5_hex", ...)` 这种长路由名
- 常用能力有短方法
- 需要特殊路由时仍然可以直接用 `runtime.bridge.call(...)`
