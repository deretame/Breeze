// runtime_api.js —— Breeze 风格运行时 API polyfill（base64 / native / runtime / opencc / Buffer）
//
// 安装前置（由 install_runtime_api 的 C++ 侧与既有设施保证，缺失时自动降级）：
//   - __native_b64encode(bytes) → string        （bundle_dispatcher.hpp，已存在）
//   - __native_b64decode(str) → Uint8Array      （runtime_api.hpp 新增）
//   - __native_gc()                             （runtime_api.hpp 新增）
//   - uuidv4() → string                         （runtime_api.hpp 新增，boost::uuids）
//   - __opencc_convert(text, config) → string   （runtime_api.hpp 新增，C++ opencc）
//   - native_put / native_get / __native_buf_free（blob_store.hpp，已存在/新增）
//   - __native_task_cancelled(id) → bool        （task.hpp TaskRunner 新增）
//   - __buffer_lib                              （buffer_lib.js 资产，已先 eval）
//
// 设计原则：polyfill 优先使用已存在的 native 能力（base64 编码/解码），
// 缺失时回退到纯 JS 实现；全部全局以覆盖方式注册（幂等 install）。
(function () {
  "use strict";

  // ---- 二进制输入收窄：ArrayBuffer/TypedArray/DataView/number[] → Uint8Array ----
  function toBytes(input) {
    if (input instanceof Uint8Array) return input;
    if (input instanceof ArrayBuffer) return new Uint8Array(input);
    if (ArrayBuffer.isView(input)) {
      return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
    }
    if (Array.isArray(input)) return Uint8Array.from(input);
    throw new TypeError("需要二进制输入（ArrayBuffer/TypedArray/DataView/number[]）");
  }

  // ---- base64（JS fallback；native 优先）----
  const B64_ALPHABET =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function jsBytesToBase64(bytes) {
    let out = "";
    const n = bytes.length;
    for (let i = 0; i < n; i += 3) {
      const b0 = bytes[i];
      const b1 = i + 1 < n ? bytes[i + 1] : 0;
      const b2 = i + 2 < n ? bytes[i + 2] : 0;
      out +=
        B64_ALPHABET[b0 >> 2] +
        B64_ALPHABET[((b0 & 3) << 4) | (b1 >> 4)] +
        B64_ALPHABET[((b1 & 15) << 2) | (b2 >> 6)] +
        B64_ALPHABET[b2 & 63];
    }
    const rem = n % 3;
    if (rem === 1) return out.slice(0, -2) + "==";
    if (rem === 2) return out.slice(0, -1) + "=";
    return out;
  }

  function jsBytesFromBase64(text) {
    const s = String(text);
    let acc = 0;
    let bits = 0;
    const out = [];
    for (let i = 0; i < s.length; ++i) {
      const c = s.charCodeAt(i);
      const v =
        c >= 65 && c <= 90
          ? c - 65
          : c >= 97 && c <= 122
            ? c - 71
            : c >= 48 && c <= 57
              ? c + 4
              : c === 43
                ? 62
                : c === 47
                  ? 63
                  : -1;
      if (v < 0) continue; // 忽略空白/非法字符
      acc = (acc << 6) | v;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.push((acc >> bits) & 0xff);
      }
    }
    return Uint8Array.from(out);
  }

  function bytesToBase64(input) {
    const bytes = toBytes(input);
    if (typeof globalThis.__native_b64encode === "function")
      return globalThis.__native_b64encode(bytes);
    return jsBytesToBase64(bytes);
  }

  function bytesFromBase64(text) {
    if (typeof text !== "string")
      throw new TypeError("bytesFromBase64: 需要字符串");
    if (typeof globalThis.__native_b64decode === "function")
      return globalThis.__native_b64decode(text);
    return jsBytesFromBase64(text);
  }

  globalThis.bytesToBase64 = bytesToBase64;
  globalThis.bytesFromBase64 = bytesFromBase64;
  globalThis.base64 = {
    encode: bytesToBase64,
    decode: bytesFromBase64,
  };

  // ---- gzip：压缩/解压（native 只收二进制；多种输入格式由 toBytes 收窄）----
  function gzipCompress(input) {
    const bytes = toBytes(input);
    if (typeof globalThis.__native_gzip_compress !== "function")
      throw new TypeError("gzipCompress: 未安装 __native_gzip_compress");
    return globalThis.__native_gzip_compress(bytes);
  }

  function gzipDecompress(input) {
    const bytes = toBytes(input);
    if (typeof globalThis.__native_gzip_decompress !== "function")
      throw new TypeError("gzipDecompress: 未安装 __native_gzip_decompress");
    return globalThis.__native_gzip_decompress(bytes);
  }

  globalThis.gzipCompress = gzipCompress;
  globalThis.gzipDecompress = gzipDecompress;

  // ---- native：二进制内存池（put/take/free；exec 系列为 Breeze 多余声明，不实现）----
  // put/take 复用 blob_store 已有的 native_put/native_get（同步、string id、
  // TTL 15min 滑动过期）；take 为消费语义（get 命中后 free），free 走
  // __native_buf_free（BlobStore::remove）。gzip 挂载对齐 kit 的
  // native.gzipCompress / native.gzipDecompress 声明。
  globalThis.native = {
    put(input) {
      return globalThis.native_put(toBytes(input));
    },
    take(id) {
      const data = globalThis.native_get(id);
      if (data !== null && typeof globalThis.__native_buf_free === "function") {
        try {
          globalThis.__native_buf_free(id);
        } catch (_e) {
          /* TTL 已回收等竞态：忽略 */
        }
      }
      return data;
    },
    free(id) {
      if (typeof globalThis.__native_buf_free === "function")
        return globalThis.__native_buf_free(id);
      return false;
    },
    gzipCompress,
    gzipDecompress,
  };

  // ---- runtime：gc / isTaskGroupCancelled ----
  // isTaskGroupCancelled 直接对接现有任务 id（TaskHandle.id）：查询该任务是否
  // 被 cancel() 过（TaskRunner 维护已取消 id 集合）。
  globalThis.runtime = {
    gc() {
      if (typeof globalThis.__native_gc === "function")
        globalThis.__native_gc();
    },
    isTaskGroupCancelled(taskGroupKey) {
      if (typeof globalThis.__native_task_cancelled !== "function")
        throw new TypeError("runtime.isTaskGroupCancelled: 未安装 __native_task_cancelled");
      return globalThis.__native_task_cancelled(taskGroupKey);
    },
  };

  // ---- opencc：简繁转换（C++ 实现，六种配置）----
  globalThis.opencc = {
    convert(text, config) {
      if (typeof globalThis.__opencc_convert !== "function")
        throw new TypeError("opencc.convert: 未安装 __opencc_convert");
      return globalThis.__opencc_convert(text, config);
    },
  };

  // ---- Buffer：Node 兼容类（npm buffer 打包资产）----
  if (typeof globalThis.__buffer_lib !== "undefined" && globalThis.__buffer_lib.Buffer) {
    globalThis.Buffer = globalThis.__buffer_lib.Buffer;
    if (typeof globalThis.__buffer_lib.SlowBuffer !== "undefined")
      globalThis.SlowBuffer = globalThis.__buffer_lib.SlowBuffer;
  }
})();
