(() => {
  if (!globalThis.globalThis) globalThis.globalThis = globalThis;
  if (!globalThis.window) globalThis.window = globalThis;
  if (!globalThis.self) globalThis.self = globalThis;
  if (!globalThis.navigator) globalThis.navigator = { userAgent: "quickjs" };

  const __web = {};

  __web.nextTick = function nextTick(fn) {
    Promise.resolve().then(fn);
  };

  if (!globalThis.queueMicrotask) {
    globalThis.queueMicrotask = function queueMicrotask(cb) {
      __web.nextTick(cb);
    };
  }

  if (!globalThis.setTimeout) {
    let timerId = 1;
    const active = new Map();
    const hostToLocal = new Map();

    function hasHostTimer() {
      return (
        typeof globalThis.__timer_start_evented === "function"
        && typeof globalThis.__timer_drop_evented === "function"
      );
    }

    const prevTimerComplete = globalThis.__host_runtime_timer_complete;

    function normalizeDelay(ms) {
      const n = Number(ms);
      if (!Number.isFinite(n) || n <= 0) return 0;
      return Math.min(24 * 60 * 60 * 1000, Math.floor(n));
    }

    function runCallback(entry) {
      if (typeof entry.cb !== "function") return;
      try {
        entry.cb(...entry.args);
      } catch (_err) {
      }
    }

    function scheduleHostTimer(localId) {
      const entry = active.get(localId);
      if (!entry) return;

      const raw = globalThis.__timer_start_evented(entry.delayMs);
      const started = JSON.parse(raw);
      if (!started || started.ok !== true) {
        throw new TypeError((started && started.error) || "timer start 失败");
      }

      const hostId = Number(started.id);
      if (!Number.isFinite(hostId) || hostId <= 0) {
        throw new TypeError("timer id 非法");
      }

      entry.hostId = hostId;
      hostToLocal.set(hostId, localId);
    }

    globalThis.__host_runtime_timer_complete = function __host_runtime_timer_complete(hostId, payloadRaw) {
      if (typeof prevTimerComplete === "function") {
        try {
          prevTimerComplete(hostId, payloadRaw);
        } catch (_err) {
        }
      }

      const hId = Number(hostId);
      const localId = hostToLocal.get(hId);
      if (localId === undefined) return;

      hostToLocal.delete(hId);
      const entry = active.get(localId);
      if (!entry) return;

      entry.hostId = null;
      if (entry.kind === "timeout") {
        active.delete(localId);
        runCallback(entry);
        return;
      }

      runCallback(entry);
      if (!active.has(localId) || !hasHostTimer()) return;

      try {
        scheduleHostTimer(localId);
      } catch (_err) {
        active.delete(localId);
      }
    };

    globalThis.setTimeout = function setTimeout(cb, ms, ...args) {
      const id = timerId;
      timerId += 1;
      const entry = {
        kind: "timeout",
        cb,
        args,
        delayMs: normalizeDelay(ms),
        hostId: null,
      };
      active.set(id, entry);

      if (hasHostTimer()) {
        try {
          scheduleHostTimer(id);
        } catch (err) {
          active.delete(id);
          throw err;
        }
        return id;
      }

      __web.nextTick(() => {
        if (!active.get(id)) return;
        active.delete(id);
        runCallback(entry);
      });
      return id;
    };

    globalThis.clearTimeout = function clearTimeout(id) {
      const localId = Number(id);
      const entry = active.get(localId);
      if (!entry) return;

      active.delete(localId);
      if (!hasHostTimer() || entry.hostId === null || entry.hostId === undefined) return;

      const hostId = Number(entry.hostId);
      hostToLocal.delete(hostId);
      try {
        globalThis.__timer_drop_evented(hostId);
      } catch (_err) {
      }
    };

    globalThis.setInterval = function setInterval(cb, ms, ...args) {
      const id = timerId;
      timerId += 1;

      const entry = {
        kind: "interval",
        cb,
        args,
        delayMs: normalizeDelay(ms),
        hostId: null,
      };
      active.set(id, entry);

      if (hasHostTimer()) {
        try {
          scheduleHostTimer(id);
        } catch (err) {
          active.delete(id);
          throw err;
        }
        return id;
      }

      const tick = () => {
        const current = active.get(id);
        if (!current) return;
        runCallback(current);
        __web.nextTick(tick);
      };

      __web.nextTick(tick);
      return id;
    };

    globalThis.clearInterval = function clearInterval(id) {
      globalThis.clearTimeout(id);
    };

    globalThis.setImmediate = function setImmediate(cb, ...args) {
      return globalThis.setTimeout(cb, 0, ...args);
    };

    globalThis.clearImmediate = function clearImmediate(id) {
      globalThis.clearTimeout(id);
    };
  }

  if (!globalThis.process) {
    const env = {};
    const argv = ["quickjs"];

    globalThis.process = {
      env,
      argv,
      platform: "quickjs",
      versions: {
        node: "18.0.0-compat",
        quickjs: "embedded",
      },
      cwd() {
        return "/";
      },
      chdir(_path) {
        throw new Error("process.chdir 当前未实现");
      },
      nextTick(fn, ...args) {
        __web.nextTick(() => {
          if (typeof fn === "function") fn(...args);
        });
      },
      hrtime(previous) {
        const nowMs = Date.now();
        const sec = Math.floor(nowMs / 1000);
        const ns = Math.floor((nowMs % 1000) * 1e6);
        if (!previous) return [sec, ns];
        let dSec = sec - Number(previous[0] || 0);
        let dNs = ns - Number(previous[1] || 0);
        if (dNs < 0) {
          dSec -= 1;
          dNs += 1e9;
        }
        return [dSec, dNs];
      },
    };

    globalThis.process.hrtime.bigint = function hrtimeBigint() {
      return BigInt(Date.now()) * 1000000n;
    };
  }

  __web.normalizeHeaderName = function normalizeHeaderName(name) {
    return String(name).toLowerCase();
  };

  __web.normalizeMethod = function normalizeMethod(method) {
    const m = String(method || "GET").toUpperCase();
    const allowed = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"];
    if (!allowed.includes(m)) {
      throw new TypeError(`不支持的 HTTP 方法: ${m}`);
    }
    return m;
  };

  function byteViewToBinaryText(view) {
    let text = "";
    for (let i = 0; i < view.length; i += 1) text += String.fromCharCode(view[i]);
    return text;
  }

  function bytesToBase64(bytes) {
    return btoaImpl(byteViewToBinaryText(bytes));
  }

  function normalizeMimeType(input) {
    if (input === undefined || input === null) return "";
    return String(input).trim().toLowerCase();
  }

  function cloneBytes(view) {
    const out = new Uint8Array(view.length);
    out.set(view);
    return out;
  }

  function concatBytes(chunks, total) {
    const out = new Uint8Array(total);
    let offset = 0;
    for (const chunk of chunks) {
      out.set(chunk, offset);
      offset += chunk.length;
    }
    return out;
  }

  function blobPartToBytes(part) {
    if (part instanceof Blob) {
      return cloneBytes(part._bytes);
    }
    if (part instanceof ArrayBuffer) {
      return cloneBytes(new Uint8Array(part));
    }
    if (ArrayBuffer.isView(part)) {
      return cloneBytes(new Uint8Array(part.buffer, part.byteOffset, part.byteLength));
    }
    return encodeUtf8(String(part));
  }

  class Blob {
    constructor(parts = [], options = {}) {
      const list = Array.isArray(parts) ? parts : [parts];
      const chunks = [];
      let total = 0;
      for (const part of list) {
        const bytes = blobPartToBytes(part);
        chunks.push(bytes);
        total += bytes.length;
      }
      this._bytes = concatBytes(chunks, total);
      this.type = normalizeMimeType(options && options.type);
    }

    get size() {
      return this._bytes.length;
    }

    arrayBuffer() {
      const out = cloneBytes(this._bytes);
      return Promise.resolve(out.buffer);
    }

    text() {
      return Promise.resolve(decodeUtf8(this._bytes));
    }

    slice(start = 0, end = this.size, contentType = "") {
      const size = this.size;
      let from = Number(start);
      let to = Number(end);
      if (!Number.isFinite(from)) from = 0;
      if (!Number.isFinite(to)) to = size;
      if (from < 0) from = Math.max(size + from, 0);
      if (to < 0) to = Math.max(size + to, 0);
      from = Math.min(Math.max(from, 0), size);
      to = Math.min(Math.max(to, 0), size);
      if (to < from) to = from;
      const bytes = this._bytes.slice(from, to);
      return new Blob([bytes], { type: contentType });
    }

    get [Symbol.toStringTag]() {
      return "Blob";
    }
  }

  class File extends Blob {
    constructor(parts = [], name = "", options = {}) {
      super(parts, options);
      this.name = String(name);
      const lm = options && options.lastModified;
      const ts = Number(lm);
      this.lastModified = Number.isFinite(ts) ? ts : Date.now();
    }

    get [Symbol.toStringTag]() {
      return "File";
    }
  }

  function normalizeFormDataEntry(value, filename) {
    if (value instanceof Blob) {
      let resolvedFilename;
      if (filename !== undefined) {
        resolvedFilename = String(filename);
      } else if (value instanceof File) {
        resolvedFilename = value.name;
      } else {
        resolvedFilename = "blob";
      }
      return {
        value,
        filename: resolvedFilename,
      };
    }

    return {
      value: String(value),
      filename: null,
    };
  }

  class FormData {
    constructor(init) {
      this._entries = [];
      if (init instanceof FormData) {
        for (const entry of init._entries) {
          this._entries.push({ ...entry });
        }
      }
    }

    append(name, value, filename) {
      const normalized = normalizeFormDataEntry(value, filename);
      this._entries.push({
        name: String(name),
        value: normalized.value,
        filename: normalized.filename,
      });
    }

    set(name, value, filename) {
      const key = String(name);
      this.delete(key);
      this.append(key, value, filename);
    }

    get(name) {
      const key = String(name);
      for (const entry of this._entries) {
        if (entry.name === key) return entry.value;
      }
      return null;
    }

    getAll(name) {
      const key = String(name);
      const out = [];
      for (const entry of this._entries) {
        if (entry.name === key) out.push(entry.value);
      }
      return out;
    }

    has(name) {
      const key = String(name);
      return this._entries.some((entry) => entry.name === key);
    }

    delete(name) {
      const key = String(name);
      this._entries = this._entries.filter((entry) => entry.name !== key);
    }

    forEach(callback, thisArg) {
      for (const entry of this._entries) {
        callback.call(thisArg, entry.value, entry.name, this);
      }
    }

    *entries() {
      for (const entry of this._entries) {
        yield [entry.name, entry.value];
      }
    }

    *keys() {
      for (const entry of this._entries) {
        yield entry.name;
      }
    }

    *values() {
      for (const entry of this._entries) {
        yield entry.value;
      }
    }

    [Symbol.iterator]() {
      return this.entries();
    }

    _toHostMultipartPlan() {
      const entries = this._entries.map((entry) => {
        if (entry.value instanceof Blob) {
          return {
            name: entry.name,
            kind: "binary",
            dataB64: bytesToBase64(entry.value._bytes),
            filename: entry.filename,
            contentType: entry.value.type || null,
          };
        }
        return {
          name: entry.name,
          kind: "text",
          value: String(entry.value),
        };
      });

      return {
        kind: "rquickjs-formdata-v1",
        entries,
      };
    }
  }

  __web.FormData = FormData;

  __web.parseBodyInit = function parseBodyInit(body) {
    if (body === undefined || body === null) {
      return {
        bodyText: undefined,
        contentType: null,
      };
    }

    if (body instanceof FormData) {
      const plan = body._toHostMultipartPlan();
      return {
        bodyText: JSON.stringify(plan),
        contentType: null,
        hostBodyKind: "formData",
      };
    }

    if (typeof URLSearchParams !== "undefined" && body instanceof URLSearchParams) {
      return {
        bodyText: body.toString(),
        contentType: "application/x-www-form-urlencoded;charset=UTF-8",
      };
    }

    if (body instanceof Blob) {
      return {
        bodyText: byteViewToBinaryText(body._bytes),
        contentType: body.type || null,
      };
    }

    if (typeof body === "string") {
      return { bodyText: body, contentType: null };
    }
    if (typeof body === "number" || typeof body === "boolean") {
      return { bodyText: String(body), contentType: null };
    }
    if (body instanceof ArrayBuffer) {
      return {
        bodyText: byteViewToBinaryText(new Uint8Array(body)),
        contentType: null,
      };
    }
    if (ArrayBuffer.isView(body)) {
      return {
        bodyText: byteViewToBinaryText(new Uint8Array(body.buffer, body.byteOffset, body.byteLength)),
        contentType: null,
      };
    }

    return {
      bodyText: JSON.stringify(body),
      contentType: "application/json",
    };
  };

  __web.stringToArrayBuffer = function stringToArrayBuffer(text) {
    const arr = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i += 1) {
      arr[i] = text.charCodeAt(i) & 0xff;
    }
    return arr.buffer;
  };

  function encodeUtf8(text) {
    const s = unescape(encodeURIComponent(String(text)));
    const out = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i += 1) {
      out[i] = s.charCodeAt(i);
    }
    return out;
  }

  function decodeUtf8(bytes) {
    let s = "";
    for (let i = 0; i < bytes.length; i += 1) {
      s += String.fromCharCode(bytes[i]);
    }
    return decodeURIComponent(escape(s));
  }

  class TextEncoder {
    encode(input = "") {
      return encodeUtf8(input);
    }
  }

  class TextDecoder {
    constructor(label = "utf-8") {
      const normalized = String(label).toLowerCase();
      if (normalized !== "utf-8" && normalized !== "utf8") {
        throw new TypeError(`不支持的编码: ${label}`);
      }
      this.encoding = "utf-8";
    }

    decode(input = new Uint8Array(0)) {
      let bytes;
      if (input instanceof Uint8Array) {
        bytes = input;
      } else if (ArrayBuffer.isView(input)) {
        bytes = new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
      } else if (input instanceof ArrayBuffer) {
        bytes = new Uint8Array(input);
      } else {
        bytes = new Uint8Array(0);
      }
      return decodeUtf8(bytes);
    }
  }

  class Buffer extends Uint8Array {
    static from(input, encoding = "utf8") {
      if (typeof input === "string") {
        const enc = String(encoding).toLowerCase();
        if (enc !== "utf8" && enc !== "utf-8") {
          throw new TypeError(`不支持的编码: ${encoding}`);
        }
        const bytes = encodeUtf8(input);
        return new Buffer(bytes);
      }

      if (input instanceof ArrayBuffer) {
        return new Buffer(new Uint8Array(input));
      }

      if (ArrayBuffer.isView(input)) {
        return new Buffer(new Uint8Array(input.buffer, input.byteOffset, input.byteLength));
      }

      if (Array.isArray(input)) {
        return new Buffer(Uint8Array.from(input));
      }

      throw new TypeError("Buffer.from 不支持该输入类型");
    }

    static alloc(size, fill = 0) {
      const out = new Buffer(Number(size) || 0);
      if (typeof fill === "string") {
        const src = encodeUtf8(fill);
        for (let i = 0; i < out.length; i += 1) {
          out[i] = src[i % src.length] || 0;
        }
      } else {
        out.fill(Number(fill) & 0xff);
      }
      return out;
    }

    static isBuffer(value) {
      return value instanceof Buffer;
    }

    static concat(list, totalLength) {
      if (!Array.isArray(list)) {
        throw new TypeError("Buffer.concat 参数必须是数组");
      }

      const chunks = list.map((item) => (Buffer.isBuffer(item) ? item : Buffer.from(item)));
      const size = totalLength === undefined
        ? chunks.reduce((n, c) => n + c.length, 0)
        : Number(totalLength);

      const out = Buffer.alloc(size);
      let offset = 0;
      for (const chunk of chunks) {
        if (offset >= out.length) break;
        const writable = Math.min(chunk.length, out.length - offset);
        out.set(chunk.subarray(0, writable), offset);
        offset += writable;
      }
      return out;
    }

    static byteLength(input, encoding = "utf8") {
      if (typeof input === "string") {
        const enc = String(encoding).toLowerCase();
        if (enc !== "utf8" && enc !== "utf-8") {
          throw new TypeError(`不支持的编码: ${encoding}`);
        }
        return encodeUtf8(input).length;
      }
      return Buffer.from(input).length;
    }

    toString(encoding = "utf8") {
      const enc = String(encoding).toLowerCase();
      if (enc !== "utf8" && enc !== "utf-8") {
        throw new TypeError(`不支持的编码: ${encoding}`);
      }
      return decodeUtf8(this);
    }

    slice(start, end) {
      const view = super.slice(start, end);
      return new Buffer(view);
    }
  }

  function normalizeEncoding(encoding, defaultEncoding = "utf8") {
    const enc = String(encoding || defaultEncoding).toLowerCase();
    if (enc === "utf8" || enc === "utf-8") return "utf8";
    if (enc === "hex") return "hex";
    if (enc === "base64") return "base64";
    if (enc === "latin1" || enc === "binary") return "latin1";
    if (enc === "buffer") return "buffer";
    throw new TypeError(`不支持的编码: ${encoding}`);
  }

  function bytesFromHex(text) {
    const clean = String(text).replace(/\s+/g, "").toLowerCase();
    if (clean.length % 2 !== 0) {
      throw new TypeError("无效的 hex 字符串");
    }
    const out = new Uint8Array(clean.length / 2);
    for (let i = 0; i < out.length; i += 1) {
      const part = clean.slice(i * 2, i * 2 + 2);
      const v = Number.parseInt(part, 16);
      if (Number.isNaN(v)) {
        throw new TypeError("无效的 hex 字符串");
      }
      out[i] = v;
    }
    return out;
  }

  function bytesFromBase64(text) {
    const raw = atobImpl(String(text));
    const out = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i += 1) {
      out[i] = raw.charCodeAt(i) & 0xff;
    }
    return out;
  }

  function bytesFromLatin1(text) {
    const raw = String(text);
    const out = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i += 1) {
      out[i] = raw.charCodeAt(i) & 0xff;
    }
    return out;
  }

  function toBytes(input, encoding = "utf8") {
    if (typeof input === "string") {
      const enc = normalizeEncoding(encoding);
      if (enc === "utf8") return encodeUtf8(input);
      if (enc === "hex") return bytesFromHex(input);
      if (enc === "base64") return bytesFromBase64(input);
      if (enc === "latin1") return bytesFromLatin1(input);
      throw new TypeError(`不支持的编码: ${encoding}`);
    }

    if (input instanceof ArrayBuffer) {
      return new Uint8Array(input.slice(0));
    }
    if (ArrayBuffer.isView(input)) {
      const view = new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
      return cloneBytes(view);
    }
    if (Array.isArray(input)) {
      return Uint8Array.from(input);
    }
    throw new TypeError("不支持的数据类型");
  }

  function bytesToHex(bytes) {
    let out = "";
    for (let i = 0; i < bytes.length; i += 1) {
      const b = bytes[i];
      out += HEX[(b >> 4) & 0x0f] + HEX[b & 0x0f];
    }
    return out;
  }

  function bytesToDigest(bytes, outputEncoding) {
    if (outputEncoding === undefined || outputEncoding === null) {
      return Buffer.from(bytes);
    }
    const enc = normalizeEncoding(outputEncoding, "hex");
    if (enc === "buffer") return Buffer.from(bytes);
    if (enc === "hex") return bytesToHex(bytes);
    if (enc === "base64") return bytesToBase64(bytes);
    if (enc === "latin1") return byteViewToBinaryText(bytes);
    if (enc === "utf8") return decodeUtf8(bytes);
    throw new TypeError(`不支持的编码: ${outputEncoding}`);
  }

  function parseHostCryptoResult(raw, actionName) {
    let parsed;
    try {
      parsed = JSON.parse(String(raw || ""));
    } catch (_err) {
      throw new TypeError(`crypto host ${actionName} 返回格式无效`);
    }
    if (!parsed || parsed.ok !== true) {
      throw new TypeError(parsed && parsed.error ? parsed.error : `crypto host ${actionName} 执行失败`);
    }
    return parsed;
  }

  function concatChunks(chunks) {
    const total = chunks.reduce((n, c) => n + c.length, 0);
    return concatBytes(chunks, total);
  }

  function normalizeHashAlgorithm(algorithm) {
    const alg = String(algorithm || "").toLowerCase();
    if (alg === "sha256" || alg === "sha-256") return "sha256";
    throw new TypeError(`不支持的 hash 算法: ${algorithm}`);
  }

  class Hash {
    constructor(algorithm) {
      this.algorithm = normalizeHashAlgorithm(algorithm);
      this._chunks = [];
      this._digested = false;
    }

    update(data, inputEncoding) {
      if (this._digested) {
        throw new TypeError("digest 后不能再 update");
      }
      this._chunks.push(toBytes(data, inputEncoding));
      return this;
    }

    digest(outputEncoding) {
      if (this._digested) {
        throw new TypeError("digest 只能调用一次");
      }
      this._digested = true;
      const input = concatChunks(this._chunks);
      const inputB64 = bytesToBase64(input);
      const out = parseHostCryptoResult(globalThis.__crypto_sha256_b64(inputB64), "sha256");
      if (outputEncoding === undefined || outputEncoding === null || normalizeEncoding(outputEncoding, "hex") === "buffer") {
        return Buffer.from(bytesFromBase64(out.base64));
      }
      const enc = normalizeEncoding(outputEncoding, "hex");
      if (enc === "hex") return out.hex;
      if (enc === "base64") return out.base64;
      if (enc === "latin1") return byteViewToBinaryText(bytesFromBase64(out.base64));
      if (enc === "utf8") return decodeUtf8(bytesFromBase64(out.base64));
      throw new TypeError(`不支持的编码: ${outputEncoding}`);
    }
  }

  class Hmac {
    constructor(algorithm, key) {
      this.algorithm = normalizeHashAlgorithm(algorithm);
      this._chunks = [];
      this._digested = false;
      this._key = toBytes(key, "utf8");
    }

    update(data, inputEncoding) {
      if (this._digested) {
        throw new TypeError("digest 后不能再 update");
      }
      this._chunks.push(toBytes(data, inputEncoding));
      return this;
    }

    digest(outputEncoding) {
      if (this._digested) {
        throw new TypeError("digest 只能调用一次");
      }
      this._digested = true;
      const message = concatChunks(this._chunks);
      const keyB64 = bytesToBase64(this._key);
      const msgB64 = bytesToBase64(message);
      const out = parseHostCryptoResult(globalThis.__crypto_hmac_sha256_b64(keyB64, msgB64), "hmac-sha256");
      if (outputEncoding === undefined || outputEncoding === null || normalizeEncoding(outputEncoding, "hex") === "buffer") {
        return Buffer.from(bytesFromBase64(out.base64));
      }
      const enc = normalizeEncoding(outputEncoding, "hex");
      if (enc === "hex") return out.hex;
      if (enc === "base64") return out.base64;
      if (enc === "latin1") return byteViewToBinaryText(bytesFromBase64(out.base64));
      if (enc === "utf8") return decodeUtf8(bytesFromBase64(out.base64));
      throw new TypeError(`不支持的编码: ${outputEncoding}`);
    }
  }

  function createHash(algorithm) {
    return new Hash(algorithm);
  }

  function createHmac(algorithm, key) {
    return new Hmac(algorithm, key);
  }

  function randomBytes(size) {
    const n = Number(size);
    if (!Number.isInteger(n) || n < 0) {
      throw new TypeError("size 必须是非负整数");
    }
    const out = parseHostCryptoResult(globalThis.__crypto_random_bytes_b64(n), "randomBytes");
    return Buffer.from(bytesFromBase64(out.base64));
  }

  const cryptoModule = {
    createHash,
    createHmac,
    randomBytes,
  };

  const BASE64_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function btoaImpl(input) {
    const text = String(input);
    let out = "";
    for (let i = 0; i < text.length; i += 3) {
      const a = text.charCodeAt(i) & 0xff;
      const b = i + 1 < text.length ? text.charCodeAt(i + 1) & 0xff : NaN;
      const c = i + 2 < text.length ? text.charCodeAt(i + 2) & 0xff : NaN;
      const n = (a << 16) | ((Number.isNaN(b) ? 0 : b) << 8) | (Number.isNaN(c) ? 0 : c);
      out += BASE64_TABLE[(n >> 18) & 63];
      out += BASE64_TABLE[(n >> 12) & 63];
      out += Number.isNaN(b) ? "=" : BASE64_TABLE[(n >> 6) & 63];
      out += Number.isNaN(c) ? "=" : BASE64_TABLE[n & 63];
    }
    return out;
  }

  function atobImpl(input) {
    const clean = String(input).replace(/\s+/g, "");
    if (clean.length % 4 !== 0) {
      throw new TypeError("无效的 base64 字符串");
    }
    let out = "";
    for (let i = 0; i < clean.length; i += 4) {
      const c1 = BASE64_TABLE.indexOf(clean[i]);
      const c2 = BASE64_TABLE.indexOf(clean[i + 1]);
      const c3 = clean[i + 2] === "=" ? -1 : BASE64_TABLE.indexOf(clean[i + 2]);
      const c4 = clean[i + 3] === "=" ? -1 : BASE64_TABLE.indexOf(clean[i + 3]);
      if (c1 < 0 || c2 < 0 || (c3 < 0 && clean[i + 2] !== "=") || (c4 < 0 && clean[i + 3] !== "=")) {
        throw new TypeError("无效的 base64 字符串");
      }
      const n = (c1 << 18) | (c2 << 12) | ((c3 < 0 ? 0 : c3) << 6) | (c4 < 0 ? 0 : c4);
      out += String.fromCharCode((n >> 16) & 0xff);
      if (clean[i + 2] !== "=") out += String.fromCharCode((n >> 8) & 0xff);
      if (clean[i + 3] !== "=") out += String.fromCharCode(n & 0xff);
    }
    return out;
  }

  const HEX = "0123456789abcdef";

  function randomByte() {
    return Math.floor(Math.random() * 256) & 0xff;
  }

  function formatUuid(bytes) {
    let out = "";
    for (let i = 0; i < bytes.length; i += 1) {
      if (i === 4 || i === 6 || i === 8 || i === 10) out += "-";
      const b = bytes[i];
      out += HEX[(b >> 4) & 0x0f];
      out += HEX[b & 0x0f];
    }
    return out;
  }

  function uuidv4() {
    const bytes = new Uint8Array(16);
    for (let i = 0; i < bytes.length; i += 1) {
      bytes[i] = randomByte();
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return formatUuid(bytes);
  }

  class URLSearchParams {
    constructor(init = "") {
      this._pairs = [];
      this._onUpdate = null;

      if (typeof init === "string") {
        const text = init.startsWith("?") ? init.slice(1) : init;
        if (text.length > 0) {
          const segs = text.split("&");
          for (const seg of segs) {
            if (!seg) continue;
            const idx = seg.indexOf("=");
            const k = idx >= 0 ? seg.slice(0, idx) : seg;
            const v = idx >= 0 ? seg.slice(idx + 1) : "";
            this._pairs.push([decodeURIComponent(k), decodeURIComponent(v)]);
          }
        }
      } else if (Array.isArray(init)) {
        for (const item of init) {
          this.append(item[0], item[1]);
        }
      } else if (init && typeof init === "object") {
        for (const key of Object.keys(init)) {
          this.append(key, init[key]);
        }
      }
    }

    _notify() {
      if (typeof this._onUpdate === "function") this._onUpdate();
    }

    append(name, value) {
      this._pairs.push([String(name), String(value)]);
      this._notify();
    }

    set(name, value) {
      const key = String(name);
      const val = String(value);
      this._pairs = this._pairs.filter((p) => p[0] !== key);
      this._pairs.push([key, val]);
      this._notify();
    }

    get(name) {
      const key = String(name);
      for (const p of this._pairs) {
        if (p[0] === key) return p[1];
      }
      return null;
    }

    getAll(name) {
      const key = String(name);
      return this._pairs.filter((p) => p[0] === key).map((p) => p[1]);
    }

    has(name) {
      const key = String(name);
      return this._pairs.some((p) => p[0] === key);
    }

    delete(name) {
      const key = String(name);
      this._pairs = this._pairs.filter((p) => p[0] !== key);
      this._notify();
    }

    toString() {
      return this._pairs
        .map((p) => `${encodeURIComponent(p[0])}=${encodeURIComponent(p[1])}`)
        .join("&");
    }

    forEach(callback, thisArg) {
      for (const p of this._pairs) callback.call(thisArg, p[1], p[0], this);
    }

    *entries() {
      for (const p of this._pairs) yield [p[0], p[1]];
    }

    *keys() {
      for (const p of this._pairs) yield p[0];
    }

    *values() {
      for (const p of this._pairs) yield p[1];
    }

    [Symbol.iterator]() {
      return this.entries();
    }
  }

  function parseAbsoluteUrl(input) {
    const text = String(input);
    const m = text.match(/^(https?):\/\/([^/?#]*)([^?#]*)(\?[^#]*)?(#.*)?$/i);
    if (!m) throw new TypeError(`无效的 URL: ${text}`);
    const protocol = `${m[1].toLowerCase()}:`;
    const host = m[2] || "";
    const pathname = m[3] || "/";
    const search = m[4] || "";
    const hash = m[5] || "";
    const p = host.split(":");
    const hostname = p[0] || "";
    const port = p[1] || "";
    return {
      protocol,
      host,
      hostname,
      port,
      pathname: pathname.startsWith("/") ? pathname : `/${pathname}`,
      search,
      hash,
      origin: `${protocol}//${host}`,
    };
  }

  function resolveUrl(input, base) {
    const text = String(input);
    if (/^https?:\/\//i.test(text)) return text;
    if (!base) throw new TypeError(`无效的 URL: ${text}`);
    const b = parseAbsoluteUrl(base);
    if (text.startsWith("/")) return `${b.origin}${text}`;
    const baseDir = b.pathname.replace(/\/[^/]*$/, "/");
    return `${b.origin}${baseDir}${text}`;
  }

  class URL {
    constructor(input, base) {
      this._setHref(resolveUrl(input, base));
    }

    _syncFromSearchParams() {
      const s = this.searchParams.toString();
      this._search = s ? `?${s}` : "";
      this._refreshHref();
    }

    _refreshHref() {
      this._href = `${this._origin}${this._pathname}${this._search}${this._hash}`;
    }

    _setHref(href) {
      const p = parseAbsoluteUrl(href);
      this._protocol = p.protocol;
      this._host = p.host;
      this._hostname = p.hostname;
      this._port = p.port;
      this._pathname = p.pathname;
      this._search = p.search;
      this._hash = p.hash;
      this._origin = p.origin;
      this.searchParams = new URLSearchParams(this._search);
      this.searchParams._onUpdate = () => this._syncFromSearchParams();
      this._refreshHref();
    }

    get href() { return this._href; }
    set href(v) { this._setHref(String(v)); }

    get protocol() { return this._protocol; }
    set protocol(v) {
      const p = String(v).replace(/:$/, "").toLowerCase();
      this._protocol = `${p}:`;
      this._origin = `${this._protocol}//${this._host}`;
      this._refreshHref();
    }

    get host() { return this._host; }
    set host(v) {
      this._host = String(v);
      const p = this._host.split(":");
      this._hostname = p[0] || "";
      this._port = p[1] || "";
      this._origin = `${this._protocol}//${this._host}`;
      this._refreshHref();
    }

    get hostname() { return this._hostname; }
    set hostname(v) {
      this._hostname = String(v);
      this._host = this._port ? `${this._hostname}:${this._port}` : this._hostname;
      this._origin = `${this._protocol}//${this._host}`;
      this._refreshHref();
    }

    get port() { return this._port; }
    set port(v) {
      this._port = String(v || "");
      this._host = this._port ? `${this._hostname}:${this._port}` : this._hostname;
      this._origin = `${this._protocol}//${this._host}`;
      this._refreshHref();
    }

    get pathname() { return this._pathname; }
    set pathname(v) {
      const p = String(v);
      this._pathname = p.startsWith("/") ? p : `/${p}`;
      this._refreshHref();
    }

    get search() { return this._search; }
    set search(v) {
      const s = String(v || "");
      this._search = s ? (s.startsWith("?") ? s : `?${s}`) : "";
      this.searchParams = new URLSearchParams(this._search);
      this.searchParams._onUpdate = () => this._syncFromSearchParams();
      this._refreshHref();
    }

    get hash() { return this._hash; }
    set hash(v) {
      const h = String(v || "");
      this._hash = h ? (h.startsWith("#") ? h : `#${h}`) : "";
      this._refreshHref();
    }

    get origin() { return this._origin; }

    toString() { return this.href; }
  }

  function normalizePath(path) {
    const input = String(path || "").replace(/\\/g, "/");
    const absolute = input.startsWith("/");
    const parts = input.split("/");
    const stack = [];
    for (const part of parts) {
      if (!part || part === ".") continue;
      if (part === "..") {
        if (stack.length > 0 && stack[stack.length - 1] !== "..") {
          stack.pop();
        } else if (!absolute) {
          stack.push("..");
        }
      } else {
        stack.push(part);
      }
    }
    const joined = stack.join("/");
    if (absolute) return `/${joined}`.replace(/\/$/, "") || "/";
    return joined || ".";
  }

  const path = {
    sep: "/",
    delimiter: ":",
    normalize(input) {
      return normalizePath(input);
    },
    isAbsolute(input) {
      return String(input || "").replace(/\\/g, "/").startsWith("/");
    },
    join(...parts) {
      return normalizePath(parts.map((p) => String(p || "")).join("/"));
    },
    resolve(...parts) {
      let out = "";
      for (let i = parts.length - 1; i >= 0; i -= 1) {
        const p = String(parts[i] || "").replace(/\\/g, "/");
        if (!p) continue;
        out = `${p}/${out}`;
        if (p.startsWith("/")) break;
      }
      if (!out.startsWith("/")) out = `/${out}`;
      return normalizePath(out);
    },
    dirname(input) {
      const p = normalizePath(input);
      if (p === "/") return "/";
      const idx = p.lastIndexOf("/");
      if (idx < 0) return ".";
      if (idx === 0) return "/";
      return p.slice(0, idx);
    },
    basename(input, ext) {
      const p = normalizePath(input);
      const idx = p.lastIndexOf("/");
      let base = idx >= 0 ? p.slice(idx + 1) : p;
      if (ext && base.endsWith(String(ext))) {
        base = base.slice(0, base.length - String(ext).length);
      }
      return base;
    },
    extname(input) {
      const base = this.basename(input);
      const idx = base.lastIndexOf(".");
      if (idx <= 0) return "";
      return base.slice(idx);
    },
  };

  __web.TextEncoder = TextEncoder;
  __web.TextDecoder = TextDecoder;
  __web.Blob = Blob;
  __web.File = File;
  __web.URLSearchParams = URLSearchParams;
  __web.URL = URL;
  __web.path = path;
  __web.Buffer = Buffer;
  __web.bufferModule = { Buffer };
  __web.crypto = cryptoModule;
  __web.cryptoModule = cryptoModule;
  __web.uuidv4 = uuidv4;
  __web.uuidv4Module = { uuidv4 };

  if (!globalThis.TextEncoder) globalThis.TextEncoder = TextEncoder;
  if (!globalThis.TextDecoder) globalThis.TextDecoder = TextDecoder;
  if (!globalThis.Blob) globalThis.Blob = Blob;
  if (!globalThis.File) globalThis.File = File;
  if (!globalThis.FormData) globalThis.FormData = FormData;
  if (!globalThis.URLSearchParams) globalThis.URLSearchParams = URLSearchParams;
  if (!globalThis.URL) globalThis.URL = URL;
  if (!globalThis.path) globalThis.path = path;
  if (!globalThis.Buffer) globalThis.Buffer = Buffer;
  if (!globalThis.crypto) globalThis.crypto = cryptoModule;
  if (!globalThis.uuidv4) globalThis.uuidv4 = uuidv4;
  if (!globalThis.btoa) globalThis.btoa = btoaImpl;
  if (!globalThis.atob) globalThis.atob = atobImpl;

  globalThis.__web = __web;
})();
