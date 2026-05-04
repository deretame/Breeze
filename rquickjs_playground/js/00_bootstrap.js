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
        typeof globalThis.__timer_start_evented === "function" &&
        typeof globalThis.__timer_drop_evented === "function"
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
      } catch (_err) {}
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

    globalThis.__host_runtime_timer_complete =
      function __host_runtime_timer_complete(hostId, payloadRaw) {
        if (typeof prevTimerComplete === "function") {
          try {
            prevTimerComplete(hostId, payloadRaw);
          } catch (_err) {}
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
      if (
        !hasHostTimer() ||
        entry.hostId === null ||
        entry.hostId === undefined
      )
        return;

      const hostId = Number(entry.hostId);
      hostToLocal.delete(hostId);
      try {
        globalThis.__timer_drop_evented(hostId);
      } catch (_err) {}
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
    const allowed = [
      "GET",
      "POST",
      "PUT",
      "PATCH",
      "DELETE",
      "HEAD",
      "OPTIONS",
    ];
    if (!allowed.includes(m)) {
      throw new TypeError(`不支持的 HTTP 方法: ${m}`);
    }
    return m;
  };

  function byteViewToBinaryText(view) {
    let text = "";
    for (let i = 0; i < view.length; i += 1)
      text += String.fromCharCode(view[i]);
    return text;
  }

  function bytesToBase64(bytes) {
    if (typeof globalThis.btoa !== "function") {
      throw new TypeError("btoa 不可用");
    }
    return globalThis.btoa(byteViewToBinaryText(bytes));
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

  async function formDataToHostMultipartPlan(formData) {
    const entries = [];
    for (const [name, value] of formData.entries()) {
      if (value instanceof Blob) {
        const ab = await value.arrayBuffer();
        const bytes = new Uint8Array(ab);
        const filename =
          typeof value.name === "string" && value.name.length > 0
            ? value.name
            : "blob";
        entries.push({
          name: String(name),
          kind: "binary",
          dataB64: bytesToBase64(bytes),
          filename,
          contentType: value.type || null,
        });
      } else {
        entries.push({
          name: String(name),
          kind: "text",
          value: String(value),
        });
      }
    }
    return {
      kind: "rquickjs-formdata-v1",
      entries,
    };
  }

  __web.parseBodyInit = function parseBodyInit(body) {
    if (body === undefined || body === null) {
      return {
        bodyText: undefined,
        contentType: null,
      };
    }

    if (
      typeof URLSearchParams !== "undefined" &&
      body instanceof URLSearchParams
    ) {
      return {
        bodyText: body.toString(),
        contentType: "application/x-www-form-urlencoded;charset=UTF-8",
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
        bodyText: byteViewToBinaryText(
          new Uint8Array(body.buffer, body.byteOffset, body.byteLength),
        ),
        contentType: null,
      };
    }
    return {
      bodyText: JSON.stringify(body),
      contentType: "application/json",
    };
  };

  __web.parseBodyInitAsync = async function parseBodyInitAsync(body) {
    if (body instanceof FormData) {
      const plan = await formDataToHostMultipartPlan(body);
      return {
        bodyText: JSON.stringify(plan),
        contentType: null,
        hostBodyKind: "formData",
      };
    }

    if (body instanceof Blob) {
      const ab = await body.arrayBuffer();
      return {
        bodyText: byteViewToBinaryText(new Uint8Array(ab)),
        contentType: body.type || null,
      };
    }

    return __web.parseBodyInit(body);
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
        bytes = new Uint8Array(
          input.buffer,
          input.byteOffset,
          input.byteLength,
        );
      } else if (input instanceof ArrayBuffer) {
        bytes = new Uint8Array(input);
      } else {
        bytes = new Uint8Array(0);
      }
      return decodeUtf8(bytes);
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
    if (typeof globalThis.atob !== "function") {
      throw new TypeError("atob 不可用");
    }
    const raw = globalThis.atob(String(text));
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
      const view = new Uint8Array(
        input.buffer,
        input.byteOffset,
        input.byteLength,
      );
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
      throw new TypeError(
        parsed && parsed.error
          ? parsed.error
          : `crypto host ${actionName} 执行失败`,
      );
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
      const out = parseHostCryptoResult(
        globalThis.__crypto_sha256_b64(inputB64),
        "sha256",
      );
      if (
        outputEncoding === undefined ||
        outputEncoding === null ||
        normalizeEncoding(outputEncoding, "hex") === "buffer"
      ) {
        return Buffer.from(bytesFromBase64(out.base64));
      }
      const enc = normalizeEncoding(outputEncoding, "hex");
      if (enc === "hex") return out.hex;
      if (enc === "base64") return out.base64;
      if (enc === "latin1")
        return byteViewToBinaryText(bytesFromBase64(out.base64));
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
      const out = parseHostCryptoResult(
        globalThis.__crypto_hmac_sha256_b64(keyB64, msgB64),
        "hmac-sha256",
      );
      if (
        outputEncoding === undefined ||
        outputEncoding === null ||
        normalizeEncoding(outputEncoding, "hex") === "buffer"
      ) {
        return Buffer.from(bytesFromBase64(out.base64));
      }
      const enc = normalizeEncoding(outputEncoding, "hex");
      if (enc === "hex") return out.hex;
      if (enc === "base64") return out.base64;
      if (enc === "latin1")
        return byteViewToBinaryText(bytesFromBase64(out.base64));
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

  function normalizeDigestAlgorithm(digest) {
    const alg = String(digest || "").toLowerCase();
    if (alg === "sha256" || alg === "sha-256") return "sha256";
    throw new TypeError(`不支持的 digest 算法: ${digest}`);
  }

  function normalizePositiveInt(value, name) {
    const n = Number(value);
    if (!Number.isInteger(n) || n <= 0) {
      throw new TypeError(`${name} 必须是正整数`);
    }
    return n;
  }

  function normalizeToBuffer(value, inputEncoding = "utf8") {
    return Buffer.from(toBytes(value, inputEncoding));
  }

  function randomBytes(size) {
    const n = Number(size);
    if (!Number.isInteger(n) || n < 0) {
      throw new TypeError("size 必须是非负整数");
    }
    const out = parseHostCryptoResult(
      globalThis.__crypto_random_bytes_b64(n),
      "randomBytes",
    );
    return Buffer.from(bytesFromBase64(out.base64));
  }

  function randomUUID() {
    const out = parseHostCryptoResult(
      globalThis.__crypto_random_uuid_v4(),
      "randomUUID",
    );
    return String(out.uuid || "");
  }

  function timingSafeEqual(a, b) {
    const left = normalizeToBuffer(a);
    const right = normalizeToBuffer(b);
    const out = parseHostCryptoResult(
      globalThis.__crypto_timing_safe_equal_b64(
        bytesToBase64(left),
        bytesToBase64(right),
      ),
      "timingSafeEqual",
    );
    return out.equal === true;
  }

  function pbkdf2Sync(password, salt, iterations, keyLen, digest = "sha256") {
    normalizeDigestAlgorithm(digest);
    const rounds = normalizePositiveInt(iterations, "iterations");
    const outLen = normalizePositiveInt(keyLen, "keyLen");
    const passwordBytes = normalizeToBuffer(password);
    const saltBytes = normalizeToBuffer(salt);
    const out = parseHostCryptoResult(
      globalThis.__crypto_pbkdf2_sha256_b64(
        bytesToBase64(passwordBytes),
        bytesToBase64(saltBytes),
        rounds,
        outLen,
      ),
      "pbkdf2",
    );
    return Buffer.from(bytesFromBase64(out.base64));
  }

  function pbkdf2(password, salt, iterations, keyLen, digest, callback) {
    let cb = callback;
    let dg = digest;
    if (typeof dg === "function") {
      cb = dg;
      dg = "sha256";
    }
    if (typeof cb !== "function") {
      throw new TypeError("pbkdf2 callback 必须是函数");
    }
    __web.nextTick(() => {
      try {
        const derived = pbkdf2Sync(password, salt, iterations, keyLen, dg);
        cb(null, derived);
      } catch (err) {
        cb(err);
      }
    });
  }

  const cryptoModule = {
    createHash,
    createHmac,
    randomBytes,
    randomUUID,
    timingSafeEqual,
    pbkdf2Sync,
    pbkdf2,
  };

  const BASE64_TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function btoaImpl(input) {
    const text = String(input);
    let out = "";
    for (let i = 0; i < text.length; i += 3) {
      const a = text.charCodeAt(i) & 0xff;
      const b = i + 1 < text.length ? text.charCodeAt(i + 1) & 0xff : NaN;
      const c = i + 2 < text.length ? text.charCodeAt(i + 2) & 0xff : NaN;
      const n =
        (a << 16) |
        ((Number.isNaN(b) ? 0 : b) << 8) |
        (Number.isNaN(c) ? 0 : c);
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
      if (
        c1 < 0 ||
        c2 < 0 ||
        (c3 < 0 && clean[i + 2] !== "=") ||
        (c4 < 0 && clean[i + 3] !== "=")
      ) {
        throw new TypeError("无效的 base64 字符串");
      }
      const n =
        (c1 << 18) | (c2 << 12) | ((c3 < 0 ? 0 : c3) << 6) | (c4 < 0 ? 0 : c4);
      out += String.fromCharCode((n >> 16) & 0xff);
      if (clean[i + 2] !== "=") out += String.fromCharCode((n >> 8) & 0xff);
      if (clean[i + 3] !== "=") out += String.fromCharCode(n & 0xff);
    }
    return out;
  }

  function uuidv4() {
    const raw = globalThis.__crypto_random_uuid_v4();
    let payload = null;
    try {
      payload = JSON.parse(String(raw || ""));
    } catch (_error) {
      throw new TypeError("uuidv4 返回结果无效");
    }
    if (!payload || payload.ok !== true) {
      throw new TypeError("uuidv4 失败");
    }
    if (typeof payload.uuid !== "string" || !payload.uuid) {
      throw new TypeError("uuidv4 返回结果无效");
    }
    return payload.uuid;
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
      return String(input || "")
        .replace(/\\/g, "/")
        .startsWith("/");
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

  if (typeof globalThis.TextEncoder !== "function") {
    globalThis.TextEncoder = TextEncoder;
  }
  if (typeof globalThis.TextDecoder !== "function") {
    globalThis.TextDecoder = TextDecoder;
  }

  __web.TextEncoder = globalThis.TextEncoder;
  __web.TextDecoder = globalThis.TextDecoder;
  const RuntimeBuffer = globalThis.Buffer;
  if (typeof RuntimeBuffer !== "function") {
    throw new TypeError("Buffer polyfill 不可用");
  }

  __web.Blob = globalThis.Blob;
  __web.File = globalThis.File;
  __web.FormData = globalThis.FormData;
  __web.path = path;
  __web.Buffer = RuntimeBuffer;
  __web.bufferModule = { Buffer: RuntimeBuffer };
  __web.crypto = cryptoModule;
  __web.cryptoModule = cryptoModule;
  __web.uuidv4 = uuidv4;
  __web.uuidv4Module = { uuidv4 };

  if (!globalThis.Blob) throw new TypeError("Blob 不可用");
  if (!globalThis.File) throw new TypeError("File 不可用");
  if (!globalThis.FormData) throw new TypeError("FormData 不可用");
  if (!globalThis.path) globalThis.path = path;
  if (!globalThis.Buffer) globalThis.Buffer = RuntimeBuffer;
  if (!globalThis.crypto) globalThis.crypto = cryptoModule;
  if (!globalThis.uuidv4) globalThis.uuidv4 = uuidv4;
  if (!globalThis.btoa) globalThis.btoa = btoaImpl;
  if (!globalThis.atob) globalThis.atob = atobImpl;
  globalThis.__web = __web;
})();
