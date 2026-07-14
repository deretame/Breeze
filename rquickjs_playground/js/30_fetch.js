(() => {
  const HOST_FORMDATA_BODY_HEADER = "x-rquickjs-host-body-formdata-v1";

  const BLOCKED_PORTS = new Set([
    0, 1, 7, 9, 11, 13, 15, 17, 19, 20, 21, 22, 23, 25, 37, 42, 43, 53, 69,
    77, 79, 87, 95, 101, 102, 103, 104, 109, 110, 111, 113, 115, 117, 119, 123,
    135, 137, 139, 143, 161, 179, 389, 427, 465, 512, 513, 514, 515, 526, 530,
    531, 532, 540, 548, 554, 556, 563, 587, 601, 636, 989, 990, 993, 995, 1719,
    1720, 1723, 2049, 3659, 4045, 4190, 5060, 5061, 6000, 6566, 6665, 6666,
    6667, 6668, 6669, 6679, 6697, 10080,
  ]);

  function isBlockedPort(port) {
    const n = Number(port);
    return Number.isInteger(n) && BLOCKED_PORTS.has(n);
  }

  function checkBlockedPort(url) {
    try {
      const parsed = new URL(String(url));
      const host = (parsed.hostname || "").toLowerCase();
      const isLocal = host === "localhost" || host === "127.0.0.1" || host === "::1";
      if (!isLocal && parsed.port && isBlockedPort(parsed.port)) {
        throw new TypeError("Bad port");
      }
    } catch (err) {
      if (err && err.message === "Bad port") throw err;
    }
  }

  const {
    parseBodyInit,
    parseBodyInitAsync,
    stringToArrayBuffer,
    byteViewToBinaryText,
    normalizeMethod,
    Headers,
  } = globalThis.__web;

  function generateBoundary() {
    const bytes = new Uint8Array(16);
    if (typeof crypto !== "undefined" && typeof crypto.getRandomValues === "function") {
      crypto.getRandomValues(bytes);
    } else {
      for (let i = 0; i < bytes.length; i += 1) bytes[i] = Math.floor(Math.random() * 256);
    }
    let hex = "";
    for (let i = 0; i < bytes.length; i += 1) {
      hex += (bytes[i] < 16 ? "0" : "") + bytes[i].toString(16);
    }
    return "----rquickjs-form-boundary-" + hex;
  }

  function formDataHasOnlyStringEntries(formData) {
    for (const [, value] of formData.entries()) {
      if (typeof value !== "string") return false;
    }
    return true;
  }

  async function serializeFormData(formData, boundary) {
    let body = "";
    let hasEntries = false;
    for (const [name, value] of formData.entries()) {
      hasEntries = true;
      body += "--" + boundary + "\r\n";
      if (value instanceof Blob) {
        const filename = value instanceof File ? value.name : "blob";
        body += 'Content-Disposition: form-data; name="' + name + '"; filename="' + filename + '"\r\n';
        body += "Content-Type: " + (value.type || "application/octet-stream") + "\r\n\r\n";
        const ab = await value.arrayBuffer();
        body += byteViewToBinaryText(new Uint8Array(ab));
        body += "\r\n";
      } else {
        body += 'Content-Disposition: form-data; name="' + name + '"\r\n\r\n';
        body += value;
        body += "\r\n";
      }
    }
    if (!hasEntries) return "";
    body += "--" + boundary + "--";
    return body;
  }

  function extractMimeType(contentType) {
    if (!contentType) return "";
    const match = String(contentType).match(/^([^;]+)/);
    if (!match) return "";
    const type = match[1].trim().toLowerCase();
    if (!/^[a-z0-9!#$%&'*+\-.^_`|~]+\/[a-z0-9!#$%&'*+\-.^_`|~]+$/i.test(type)) return "";
    return type;
  }

  function getBoundaryFromContentType(contentType) {
    if (!contentType) return null;
    const match = String(contentType).match(/boundary=([^;\s]+)/i);
    return match ? match[1] : null;
  }

  function parseUrlEncodedFormData(bodyText) {
    const params = new URLSearchParams(bodyText);
    const fd = new FormData();
    for (const [name, value] of params) {
      fd.append(name, value);
    }
    return fd;
  }

  function parseMultipartFormData(bodyText, contentType) {
    let boundary = getBoundaryFromContentType(contentType);
    if (!boundary) {
      const inferred = bodyText.match(/^--([^\r\n]+)\r\n/);
      if (inferred && inferred[1]) {
        boundary = inferred[1];
      } else {
        const alt = bodyText.match(/\r\n--([^\r\n]+)\r\n/);
        if (alt && alt[1]) boundary = alt[1];
      }
    }
    if (!boundary) {
      throw new TypeError("Missing boundary in multipart/form-data");
    }
    const fd = new FormData();
    const delimiter = "\r\n--" + boundary;
    let idx = bodyText.indexOf("--" + boundary);
    if (idx === -1) return fd;
    let start = idx + ("--" + boundary).length;
    while (true) {
      let next = bodyText.indexOf(delimiter, start);
      if (next === -1) break;
      let part = bodyText.slice(start, next);
      // Strip leading CRLF if present.
      if (part.startsWith("\r\n")) part = part.slice(2);
      const headerEnd = part.indexOf("\r\n\r\n");
      if (headerEnd !== -1) {
        const headers = part.slice(0, headerEnd);
        const value = part.slice(headerEnd + 4);
        const dispMatch = headers.match(/Content-Disposition:\s*form-data[^;]*;\s*name="([^"]*)"(?:;\s*filename="([^"]*)")?/i);
        if (dispMatch) {
          const name = dispMatch[1];
          const filename = dispMatch[2];
          if (filename !== undefined) {
            const ctMatch = headers.match(/Content-Type:\s*([^\r\n]+)/i);
            const blobType = extractMimeType(ctMatch ? ctMatch[1] : "") || "application/octet-stream";
            const bytes = stringToArrayBuffer(value);
            const blob = new Blob([bytes], { type: blobType });
            fd.append(name, blob, filename);
          } else {
            fd.append(name, value);
          }
        }
      }
      start = next + delimiter.length;
      if (bodyText.substr(start, 2) === "--") break;
    }
    return fd;
  }

  function defineReadOnlyRequestProperties(request) {
    const propNames = [
      "method",
      "url",
      "headers",
      "destination",
      "referrer",
      "referrerPolicy",
      "mode",
      "credentials",
      "cache",
      "redirect",
      "integrity",
      "isReloadNavigation",
      "isHistoryNavigation",
      "duplex",
    ];
    for (const name of propNames) {
      const internalName = "__" + name;
      if (!(internalName in request)) {
        request[internalName] = request[name];
      }
      Object.defineProperty(request, name, {
        get() {
          return request[internalName];
        },
        set(_value) {
          // Request 属性为只读，忽略外部赋值。
        },
        configurable: true,
        enumerable: true,
      });
    }
  }

  class BodyMixin {
    _initBody(bodyText, meta = {}) {
      const wasUsed = this.__bodyUsed === true;
      this._bodyText = bodyText || "";
      this._bodyBlob = null;
      this._bodyFormData = null;
      this._bodyInitPromise = null;
      this._bodyTextIsBinary = false;
      this.__bodyUsed = wasUsed;
      this.__fetchStateId = null;
      if (typeof globalThis.__fetch_state_register === "function") {
        try {
          this.__fetchStateId = Number(
            globalThis.__fetch_state_register(
              Boolean(meta.offloaded),
              Boolean(meta.nativeBody),
            ),
          );
        } catch (_err) {
          this.__fetchStateId = null;
        }
      }
      if (typeof globalThis.__body_state_register === "function") {
        try {
          this.__bodyStateId = Number(globalThis.__body_state_register());
        } catch (_err) {
          this.__bodyStateId = null;
        }
      } else {
        this.__bodyStateId = null;
      }
    }

    get bodyUsed() {
      return this.__bodyUsed === true;
    }

    set bodyUsed(_value) {
      // bodyUsed 为只读属性，外部赋值忽略。
    }

    _lockBody() {
      if (this.bodyUsed) {
        throw new TypeError("Body 已被读取");
      }
      if (!this._tryConsumeBodyState()) {
        this.__bodyUsed = true;
        throw new TypeError("Body 已被读取");
      }
      this.__bodyUsed = true;
    }

    _tryConsumeBodyState() {
      if (this.__fetchStateId !== null && this.__fetchStateId !== undefined) {
        if (typeof globalThis.__fetch_state_try_consume === "function") {
          try {
            if (globalThis.__fetch_state_try_consume(Number(this.__fetchStateId)) !== true) {
              return false;
            }
          } catch (_err) {
            return false;
          }
        }
      }
      if (this.__bodyStateId === null || this.__bodyStateId === undefined) return true;
      if (typeof globalThis.__body_state_try_consume !== "function") return true;
      try {
        return globalThis.__body_state_try_consume(Number(this.__bodyStateId)) === true;
      } catch (_err) {
        return false;
      }
    }

    _isBodyStateConsumed() {
      if (this.__fetchStateId !== null && this.__fetchStateId !== undefined) {
        if (typeof globalThis.__fetch_state_can_clone === "function") {
          try {
            return globalThis.__fetch_state_can_clone(Number(this.__fetchStateId)) !== true;
          } catch (_err) {
            return true;
          }
        }
      }
      if (this.__bodyStateId === null || this.__bodyStateId === undefined) return this.bodyUsed === true;
      if (typeof globalThis.__body_state_is_consumed !== "function") return this.bodyUsed === true;
      try {
        return globalThis.__body_state_is_consumed(Number(this.__bodyStateId)) === true;
      } catch (_err) {
        return true;
      }
    }

    _consumeBody() {
      if (this.bodyUsed) {
        return Promise.reject(new TypeError("Body 已被读取"));
      }
      if (this._hasBody) {
        if (!this._tryConsumeBodyState()) {
          this.__bodyUsed = true;
          return Promise.reject(new TypeError("Body 已被读取"));
        }
        this.__bodyUsed = true;
      }
      if (this.offloaded === true && this.nativeBufferId !== null && this.nativeBufferId !== undefined) {
        if (!globalThis.native || typeof globalThis.native.take !== "function") {
          return Promise.reject(new TypeError("native.take 不可用，无法读取 offload 二进制数据"));
        }
        const id = Number(this.nativeBufferId);
        this.nativeBufferId = null;
        return globalThis.native.take(id).then((bytes) => {
          if (typeof TextDecoder === "function") {
            return new TextDecoder("utf-8").decode(bytes);
          }
          let text = "";
          for (let i = 0; i < bytes.length; i += 1) text += String.fromCharCode(bytes[i]);
          return text;
        });
      }
      const produce = () => {
        if (this._bodyBlob) return this._bodyBlob.text();
        return Promise.resolve(this._bodyText);
      };
      if (this._bodyInitPromise) {
        return this._bodyInitPromise.then(produce);
      }
      return produce();
    }

    text() {
      return this._consumeBody();
    }

    json() {
      return this._consumeBody().then((text) => JSON.parse(text));
    }

    arrayBuffer() {
      if (this.bodyUsed) {
        return Promise.reject(new TypeError("Body 已被读取"));
      }
      if (this._hasBody) {
        if (!this._tryConsumeBodyState()) {
          this.__bodyUsed = true;
          return Promise.reject(new TypeError("Body 已被读取"));
        }
        this.__bodyUsed = true;
      }
      if (this.offloaded === true && this.nativeBufferId !== null && this.nativeBufferId !== undefined) {
        if (!globalThis.native || typeof globalThis.native.take !== "function") {
          return Promise.reject(new TypeError("native.take 不可用，无法读取 offload 二进制数据"));
        }
        const id = Number(this.nativeBufferId);
        this.nativeBufferId = null;
        return globalThis.native.take(id).then((bytes) => {
          const out = new Uint8Array(bytes.length);
          out.set(bytes);
          return out.buffer;
        });
      }
      const produce = () => {
        if (this._bodyBlob) return this._bodyBlob.arrayBuffer();
        if (this._bodyTextIsBinary) return Promise.resolve(stringToArrayBuffer(this._bodyText));
        if (typeof TextEncoder === "function") {
          return Promise.resolve(new TextEncoder().encode(this._bodyText).buffer);
        }
        return Promise.resolve(stringToArrayBuffer(this._bodyText));
      };
      if (this._bodyInitPromise) {
        return this._bodyInitPromise.then(produce);
      }
      return produce();
    }

    blob() {
      if (this.bodyUsed) {
        return Promise.reject(new TypeError("Body 已被读取"));
      }
      if (this._hasBody) {
        if (!this._tryConsumeBodyState()) {
          this.__bodyUsed = true;
          return Promise.reject(new TypeError("Body 已被读取"));
        }
        this.__bodyUsed = true;
      }
      const mime = extractMimeType(this.headers.get("content-type")) || "";
      const makeBlob = (ab) => new Blob([ab], { type: mime });
      const produce = () => {
        if (this._bodyBlob) return this._bodyBlob.arrayBuffer().then(makeBlob);
        if (this._bodyTextIsBinary) {
          return Promise.resolve(stringToArrayBuffer(this._bodyText)).then(makeBlob);
        }
        if (typeof TextEncoder === "function") {
          return Promise.resolve(new TextEncoder().encode(this._bodyText).buffer).then(makeBlob);
        }
        return Promise.resolve(stringToArrayBuffer(this._bodyText)).then(makeBlob);
      };
      if (this._bodyInitPromise) {
        return this._bodyInitPromise.then(produce);
      }
      return produce();
    }

    formData() {
      if (this.bodyUsed) {
        return Promise.reject(new TypeError("Body 已被读取"));
      }
      if (this._hasBody) {
        if (!this._tryConsumeBodyState()) {
          this.__bodyUsed = true;
          return Promise.reject(new TypeError("Body 已被读取"));
        }
        this.__bodyUsed = true;
      }
      const produce = () => {
        const contentType = this.headers.get("content-type") || "";
        const mime = extractMimeType(contentType);
        if (!this._hasBody) {
          if (mime === "application/x-www-form-urlencoded") {
            return Promise.resolve(parseUrlEncodedFormData(this._bodyText));
          }
          return Promise.reject(new TypeError("Invalid MIME type for formData()"));
        }
        if (this._bodyFormData && mime === "multipart/form-data") {
          return Promise.resolve(this._bodyFormData);
        }
        if (mime === "application/x-www-form-urlencoded") {
          return Promise.resolve(parseUrlEncodedFormData(this._bodyText));
        }
        if (mime === "multipart/form-data") {
          return Promise.resolve(parseMultipartFormData(this._bodyText, contentType));
        }
        return Promise.reject(new TypeError("Invalid MIME type for formData()"));
      };
      if (this._bodyInitPromise) {
        return this._bodyInitPromise.then(produce);
      }
      return produce();
    }
  }

  class Request extends BodyMixin {
    constructor(input, init = {}) {
      super();
      this._hasBody = false;
      this._bodyNativeBufferId = null;

      if (init instanceof Request) {
        const req = init;
        init = {
          method: req.method,
          headers: new Headers(req.headers),
          body: undefined,
          credentials: req.credentials,
          mode: req.mode,
          redirect: req.redirect,
          referrer: req.referrer,
          referrerPolicy: req.referrerPolicy,
          integrity: req.integrity,
          keepalive: req.keepalive,
          signal: req.signal,
          timeout: req.timeout,
        };
        if (req._hasBody) {
          if (req._bodyBlob) {
            init.body = req._bodyBlob;
          } else if (req._bodyFormData) {
            init.body = req._bodyFormData;
          } else if (req._bodyNativeBufferId !== null && req._bodyNativeBufferId !== undefined) {
            init.body = req._bodyText;
          } else {
            init.body = req._bodyText;
          }
        }
      }

      if (input instanceof Request) {
        this.url = input.url;
        this.method = input.method;
        this.headers = new Headers(input.headers);
        this._initBody(input._bodyText, {
          offloaded: false,
          nativeBody: Boolean(input._bodyNativeBufferId !== null && input._bodyNativeBufferId !== undefined),
        });
        this._bodyTextIsBinary = Boolean(input._bodyTextIsBinary);
        this._bodyBlob = input._bodyBlob || null;
        this._bodyFormData = input._bodyFormData || null;
        this._bodyInitPromise = null;
        if (this._bodyBlob) {
          this._bodyInitPromise = this._bodyBlob.arrayBuffer().then((ab) => {
            this._bodyText = byteViewToBinaryText(new Uint8Array(ab));
          });
        } else if (this._bodyFormData) {
          if (formDataHasOnlyStringEntries(this._bodyFormData)) {
            const boundary = getBoundaryFromContentType(this.headers.get("content-type"));
            this._bodyInitPromise = serializeFormData(this._bodyFormData, boundary).then((text) => {
              this._bodyText = text;
            });
          } else {
            this._bodyInitPromise = parseBodyInitAsync(this._bodyFormData).then((bodyInit) => {
              if (bodyInit.bodyText !== undefined) {
                this._bodyText = bodyInit.bodyText;
              }
              if (!this.headers.has("content-type") && bodyInit.contentType) {
                this.headers.set("content-type", bodyInit.contentType);
              }
              if (bodyInit.hostBodyKind === "formData") {
                this.headers.set(HOST_FORMDATA_BODY_HEADER, "1");
              }
            });
          }
        }
        this._hasBody = Boolean(input._hasBody);
        this._bodyNativeBufferId =
          input._bodyNativeBufferId === undefined || input._bodyNativeBufferId === null
            ? null
            : Number(input._bodyNativeBufferId);
        this.timeout = input.timeout;
        this.signal = input.signal || null;
      } else {
        this.url = String(input);
        this.method = "GET";
        this.headers = new Headers();
        this._initBody("", { offloaded: false, nativeBody: false });
        this.timeout = null;
        this.signal = null;
      }

      this.method = normalizeMethod(init.method || this.method);
      if (Object.prototype.hasOwnProperty.call(init, "priority")) {
        const validPriorities = new Set(["high", "low", "auto"]);
        if (!validPriorities.has(String(init.priority).toLowerCase())) {
          throw new TypeError("Invalid Request priority");
        }
        this.__priority = String(init.priority).toLowerCase();
      } else {
        this.__priority = "auto";
      }
      if (init.headers) this.headers = new Headers(init.headers);
      if (Object.prototype.hasOwnProperty.call(init, "signal")) {
        this.signal = init.signal || null;
      }
      this.credentials = init.credentials || "same-origin";
      this.mode = init.mode || "cors";
      this.redirect = init.redirect || "follow";
      this.destination = "";
      this.isReloadNavigation = false;
      this.isHistoryNavigation = false;
      this.duplex = "half";
      this.referrer = init.referrer || "about:client";
      this.referrerPolicy = init.referrerPolicy || "";
      this.integrity = init.integrity || "";
      this.keepalive = Boolean(init.keepalive);
      this.cache = init.cache || "default";
      const requestGuard = this.mode === "no-cors" ? "request-no-cors" : "request";
      this.headers._applyGuard(requestGuard);

      if (Object.prototype.hasOwnProperty.call(init, "timeout") || Object.prototype.hasOwnProperty.call(init, "timeoutMs")) {
        const timeoutRaw = Object.prototype.hasOwnProperty.call(init, "timeoutMs") ? init.timeoutMs : init.timeout;
        const timeout = Number(timeoutRaw);
        this.timeout = Number.isFinite(timeout) && timeout > 0 ? Math.floor(timeout) : null;
      }

      const body = init.body;

      if (body !== undefined) {
        let bodyText = "";
        let hasBody = false;
        let contentType = null;
        let bodySourceKind = "empty";

        if (body !== null) {
          if (this.method === "GET" || this.method === "HEAD") {
            throw new TypeError("GET/HEAD 请求不能带 body");
          }
          if (typeof body === "string") {
            bodyText = body;
            contentType = "text/plain;charset=UTF-8";
            bodySourceKind = "text";
            hasBody = true;
          } else if (typeof URLSearchParams !== "undefined" && body instanceof URLSearchParams) {
            bodyText = body.toString();
            contentType = "application/x-www-form-urlencoded;charset=UTF-8";
            bodySourceKind = "text";
            hasBody = true;
          } else if (body instanceof Blob) {
            contentType = body.type || null;
            if (body.size === 0) {
              bodyText = "";
              bodySourceKind = "text";
            } else {
              bodySourceKind = "blob";
            }
            hasBody = true;
          } else if (body instanceof FormData) {
            bodySourceKind = "formData";
            hasBody = true;
            if (formDataHasOnlyStringEntries(body)) {
              const boundary = generateBoundary();
              contentType = "multipart/form-data; boundary=" + boundary;
            }
          } else if (body instanceof ArrayBuffer || ArrayBuffer.isView(body)) {
            const view = body instanceof ArrayBuffer
              ? new Uint8Array(body)
              : new Uint8Array(body.buffer, body.byteOffset, body.byteLength);
            bodyText = byteViewToBinaryText(view);
            contentType = null;
            bodySourceKind = "binary";
            hasBody = true;
          } else {
            if (body.toString === Object.prototype.toString) {
              bodyText = JSON.stringify(body);
              contentType = "application/json";
            } else {
              bodyText = String(body);
              contentType = "text/plain;charset=UTF-8";
            }
            bodySourceKind = "text";
            hasBody = true;
          }
        }

        this._initBody(bodyText, { offloaded: false, nativeBody: false });
        this._bodyTextIsBinary = bodySourceKind === "binary";
        this._hasBody = hasBody;
        if (contentType !== null && !this.headers.has("content-type")) {
          this.headers.set("content-type", contentType);
        }
        this._bodyInitPromise = Promise.resolve();

        if (bodySourceKind === "blob") {
          this._bodyBlob = body;
          this._bodyInitPromise = this._bodyBlob.arrayBuffer().then((ab) => {
            this._bodyText = byteViewToBinaryText(new Uint8Array(ab));
          });
        } else if (bodySourceKind === "text" && contentType !== null && this._bodyText === "") {
          this._bodyInitPromise = Promise.resolve();
        } else if (bodySourceKind === "formData") {
          this._bodyFormData = body;
          if (formDataHasOnlyStringEntries(body)) {
            const boundary = getBoundaryFromContentType(this.headers.get("content-type"));
            this._bodyInitPromise = serializeFormData(this._bodyFormData, boundary).then((text) => {
              this._bodyText = text;
            });
          } else {
            this._bodyInitPromise = parseBodyInitAsync(body).then((bodyInit) => {
              if (bodyInit.bodyText !== undefined) {
                this._bodyText = bodyInit.bodyText;
              }
              if (!this.headers.has("content-type") && bodyInit.contentType) {
                this.headers.set("content-type", bodyInit.contentType);
              }
              if (bodyInit.hostBodyKind === "formData") {
                this.headers.set(HOST_FORMDATA_BODY_HEADER, "1");
              }
            });
          }
        }

        const canUseNativeBinaryBody =
          globalThis.native &&
          typeof globalThis.native.put === "function" &&
          !(body instanceof FormData) &&
          !(body instanceof Blob);
        if (
          canUseNativeBinaryBody &&
          (body instanceof ArrayBuffer || ArrayBuffer.isView(body))
        ) {
          this._bodyInitPromise = this._bodyInitPromise.then(async () => {
            this._bodyNativeBufferId = await globalThis.native.put(body);
            this._initBody("", { offloaded: false, nativeBody: true });
            this._hasBody = true;
          });
        }
      }

      defineReadOnlyRequestProperties(this);
    }

    clone() {
      if (this.bodyUsed) {
        throw new TypeError("Body 已被读取，无法 clone");
      }
      if (this._isBodyStateConsumed()) {
        this.__bodyUsed = true;
        throw new TypeError("Body 已被读取，无法 clone");
      }
      const clonedInit = {
        method: this.method,
        headers: new Headers(this.headers),
        signal: this.signal,
        timeout: this.timeout,
        credentials: this.credentials,
        mode: this.mode,
        redirect: this.redirect,
        referrer: this.referrer,
        referrerPolicy: this.referrerPolicy,
        integrity: this.integrity,
        keepalive: this.keepalive,
        cache: this.cache,
      };
      if (this._hasBody) {
        if (this._bodyNativeBufferId !== null && this._bodyNativeBufferId !== undefined) {
          throw new TypeError("native buffer body 暂不支持 clone");
        }
        if (this._bodyBlob) {
          clonedInit.body = this._bodyBlob;
        } else if (this._bodyFormData) {
          clonedInit.body = this._bodyFormData;
        } else {
          clonedInit.body = this._bodyText;
        }
      }
      return new Request(this, {
        ...clonedInit,
      });
    }
  }

  const NULL_BODY_STATUS = new Set([204, 205, 304]);
  const REDIRECT_STATUS = new Set([301, 302, 303, 307, 308]);

  function isValidStatus(status) {
    return Number.isInteger(status) && status >= 200 && status <= 599;
  }

  function isValidStatusText(statusText) {
    for (let i = 0; i < statusText.length; i += 1) {
      const code = statusText.charCodeAt(i);
      if (code === 0x0D || code === 0x0A || code > 0xFF) {
        return false;
      }
    }
    return true;
  }

  function isNullBody(body) {
    return body === null || body === undefined || body === "";
  }

  class Response extends BodyMixin {
    constructor(body = null, init = {}) {
      super();

      const status = init.status === undefined ? 200 : Number(init.status);
      if (!isValidStatus(status)) {
        throw new RangeError("Response status must be an integer in the range 200 to 599");
      }

      const statusText = init.statusText === undefined ? "" : String(init.statusText);
      if (!isValidStatusText(statusText)) {
        throw new TypeError("Response statusText contains invalid characters");
      }

      if (NULL_BODY_STATUS.has(status) && !isNullBody(body)) {
        throw new TypeError("Response with status " + status + " cannot have a body");
      }

      let bodyText = "";
      let contentType = null;
      let bodySourceKind = "empty";

      if (body !== null && body !== undefined) {
        if (typeof body === "string") {
          bodyText = body;
          contentType = "text/plain;charset=UTF-8";
          bodySourceKind = "text";
        } else if (typeof URLSearchParams !== "undefined" && body instanceof URLSearchParams) {
          bodyText = body.toString();
          contentType = "application/x-www-form-urlencoded;charset=UTF-8";
          bodySourceKind = "text";
        } else if (body instanceof Blob) {
          contentType = body.type || null;
          if (body.size === 0) {
            bodyText = "";
            bodySourceKind = "text";
          } else {
            bodySourceKind = "blob";
          }
        } else if (body instanceof FormData) {
          contentType = "multipart/form-data; boundary=" + generateBoundary();
          bodySourceKind = "formData";
        } else if (body instanceof ArrayBuffer || ArrayBuffer.isView(body)) {
          const view = body instanceof ArrayBuffer
            ? new Uint8Array(body)
            : new Uint8Array(body.buffer, body.byteOffset, body.byteLength);
          bodyText = byteViewToBinaryText(view);
          bodySourceKind = "binary";
        } else {
          bodyText = JSON.stringify(body);
          contentType = "application/json";
          bodySourceKind = "text";
        }
      }

      this._initBody(bodyText, {
        offloaded: Boolean(init.offloaded),
        nativeBody: false,
      });
      this._bodyTextIsBinary = bodySourceKind === "binary";
      this._hasBody = body !== null && body !== undefined;
      this.headers = new Headers(init.headers || {});
      if (contentType !== null && !this.headers.has("content-type")) {
        this.headers.set("content-type", contentType);
      }
      this.headers._applyGuard("response");

      this._bodyInitPromise = null;
      if (bodySourceKind === "blob") {
        this._bodyBlob = body;
        this._bodyInitPromise = this._bodyBlob.arrayBuffer().then((ab) => {
          this._bodyText = byteViewToBinaryText(new Uint8Array(ab));
        });
      } else if (bodySourceKind === "formData") {
        this._bodyFormData = body;
        const boundary = getBoundaryFromContentType(this.headers.get("content-type"));
        this._bodyInitPromise = serializeFormData(this._bodyFormData, boundary).then((text) => {
          this._bodyText = text;
        });
      }

      this.status = status;
      this.statusText = statusText;
      this.url = init.url || "";
      this.type = "default";
      this.redirected = false;
      this.ok = status >= 200 && status < 300;
      this.body = null;
      this.offloaded = Boolean(init.offloaded);
      this.nativeBufferId = init.nativeBufferId === undefined || init.nativeBufferId === null
        ? null
        : Number(init.nativeBufferId);
      this.offloadedBytes = Number(init.offloadedBytes || 0);
    }

    clone() {
      if (this.bodyUsed) {
        throw new TypeError("Body 已被读取，无法 clone");
      }
      if (this._isBodyStateConsumed()) {
        this.__bodyUsed = true;
        throw new TypeError("Body 已被读取，无法 clone");
      }
      if (this.offloaded && this.nativeBufferId !== null) {
        throw new TypeError("offload 响应暂不支持 clone");
      }
      const clonedBody = this._bodyBlob || this._bodyFormData || this._bodyText;
      return new Response(clonedBody, {
        status: this.status,
        statusText: this.statusText,
        headers: this.headers,
        url: this.url,
        offloaded: this.offloaded,
        nativeBufferId: this.nativeBufferId,
        offloadedBytes: this.offloadedBytes,
      });
    }

    async takeOffloadedBody() {
      if (this.bodyUsed) {
        throw new TypeError("Body 已被读取");
      }
      if (this.__fetchStateId !== null && this.__fetchStateId !== undefined) {
        if (typeof globalThis.__fetch_state_take_offloaded === "function") {
          let accepted = false;
          try {
            accepted = globalThis.__fetch_state_take_offloaded(Number(this.__fetchStateId)) === true;
          } catch (_err) {
            accepted = false;
          }
          if (!accepted) {
            this.__bodyUsed = true;
            throw new TypeError("Body 已被读取");
          }
        }
      }
      if (!this._tryConsumeBodyState()) {
        if (this.__fetchStateId === null || this.__fetchStateId === undefined) {
          this.__bodyUsed = true;
          throw new TypeError("Body 已被读取");
        }
      }
      this.__bodyUsed = true;

      if (!this.offloaded || this.nativeBufferId === null) {
        return new Uint8Array(0);
      }
      if (!globalThis.native || typeof globalThis.native.take !== "function") {
        throw new TypeError("native.take 不可用，无法读取 offload 二进制数据");
      }
      const id = this.nativeBufferId;
      this.nativeBufferId = null;
      return globalThis.native.take(id);
    }

    static error() {
      const headers = new Headers();
      headers._guard = "immutable";
      const response = new Response(null);
      response.status = 0;
      response.statusText = "";
      response.ok = false;
      response.headers = headers;
      response.type = "error";
      return response;
    }

    static redirect(url, status = 302) {
      let parsedUrl;
      try {
        parsedUrl = new URL(String(url)).toString();
      } catch (_err) {
        throw new TypeError("Invalid URL");
      }
      const statusNum = Number(status);
      if (!REDIRECT_STATUS.has(statusNum)) {
        throw new RangeError("Invalid redirect status code");
      }
      const headers = new Headers();
      headers.set("Location", parsedUrl);
      return new Response(null, { status: statusNum, statusText: "", headers });
    }

    static json(data, init = {}) {
      if (typeof data === "symbol") {
        throw new TypeError("Cannot convert a Symbol value to a string");
      }
      const headers = new Headers(init.headers || {});
      if (!headers.has("content-type")) {
        headers.set("content-type", "application/json");
      }
      return new Response(JSON.stringify(data), {
        ...init,
        headers,
      });
    }
  }

  function fetch(input, init = {}) {
    let request;
    try {
      if (input instanceof Request) {
        const hasInit = Object.keys(init).length > 0 ||
          Object.getOwnPropertySymbols(init).length > 0;
        request = hasInit ? new Request(input, init) : input;
      } else {
        request = new Request(input, init);
      }
    } catch (err) {
      return Promise.reject(err);
    }

    try {
      if (request._hasBody) {
        request._lockBody();
      }
    } catch (err) {
      return Promise.reject(err);
    }

    const waitBodyInit = request && request._bodyInitPromise
      ? request._bodyInitPromise
      : Promise.resolve();

    return waitBodyInit.then(async () => {
      let requestId = null;
      let timeoutId = null;
      let timeoutFired = false;
      let signal = request.signal;
      let cleanupRequestSignal = null;
      let cleanupSignal = null;

      const clearTimeoutIfNeeded = () => {
        if (timeoutId === null) return;
        clearTimeout(timeoutId);
        timeoutId = null;
      };

      const cleanupSignalListeners = () => {
        if (typeof cleanupRequestSignal === "function") {
          cleanupRequestSignal();
          cleanupRequestSignal = null;
        }
        if (typeof cleanupSignal === "function") {
          cleanupSignal();
          cleanupSignal = null;
        }
      };

      const isTimeoutAbortReason = (reason) => {
        if (timeoutFired) return true;
        if (reason === null || reason === undefined) return false;

        if (typeof reason === "string") {
          const text = reason.toLowerCase();
          return text.includes("timeout") || text.includes("超时");
        }

        if (typeof reason === "object") {
          const name = String(reason.name || "");
          const code = String(reason.code || "");
          const message = String(reason.message || "").toLowerCase();
          return (
            name === "TimeoutError" ||
            code === "ETIMEDOUT" ||
            code === "ECONNABORTED" ||
            message.includes("timeout") ||
            message.includes("超时")
          );
        }

        return false;
      };

      const buildAbortError = () => {
        const reason = signal ? signal.reason : null;
        const isTimeout = isTimeoutAbortReason(reason);

        let message = isTimeout ? "请求超时" : "请求已取消";
        if (typeof reason === "string" && reason.trim()) {
          message = reason;
        } else if (reason && typeof reason === "object") {
          const reasonMessage = String(reason.message || "").trim();
          if (reasonMessage) {
            message = reasonMessage;
          }
        }

        const err = new Error(message);
        err.name = isTimeout ? "TimeoutError" : "AbortError";
        return err;
      };

      if (request.timeout !== null) {
        if (typeof AbortController === "function") {
          const timeoutController = new AbortController();
          const prevSignal = signal;
          signal = timeoutController.signal;

          if (prevSignal) {
            const forwardAbort = () => {
              timeoutController.abort(prevSignal.reason);
            };
            prevSignal.addEventListener("abort", forwardAbort);
            cleanupRequestSignal = () => {
              prevSignal.removeEventListener("abort", forwardAbort);
            };

            if (prevSignal.aborted) {
              forwardAbort();
            }
          }

          timeoutId = setTimeout(() => {
            timeoutFired = true;
            timeoutController.abort("请求超时");
          }, request.timeout);
        } else {
          timeoutId = setTimeout(() => {
            timeoutFired = true;
            if (requestId !== null) {
              try {
                globalThis.__http_request_cancel(requestId);
              } catch (_err) {
              }
            }
          }, request.timeout);
        }
      }

      if (signal && signal.aborted) {
        cleanupSignalListeners();
        clearTimeoutIfNeeded();
        throw buildAbortError();
      }

      checkBlockedPort(request.url);

      try {
        const promise = globalThis.__http_request_promise(
          request.method,
          request.url,
          JSON.stringify(request.headers.toObject()),
          request._bodyText || null,
          request._bodyNativeBufferId === null || request._bodyNativeBufferId === undefined
            ? null
            : Number(request._bodyNativeBufferId),
        );
        requestId = Number(promise.__hostRequestId);

        const onAbort = () => {
          if (requestId !== null) {
            try {
              globalThis.__http_request_cancel(requestId);
            } catch (_err) {
            }
          }
        };
        if (signal) {
          signal.addEventListener("abort", onAbort);
          cleanupSignal = () => {
            signal.removeEventListener("abort", onAbort);
          };

          if (signal.aborted) {
            onAbort();
            cleanupSignalListeners();
            clearTimeoutIfNeeded();
            throw buildAbortError();
          }
        }

        const payloadRaw = await promise;
        cleanupSignalListeners();
        clearTimeoutIfNeeded();

        let payload;
        try {
          payload = JSON.parse(String(payloadRaw || "{}"));
        } catch (err) {
          throw err;
        }

        if (!payload.ok) {
          if (payload.canceled === true) {
            throw buildAbortError();
          }
          throw new TypeError(payload.error || "网络请求失败");
        }

        return new Response(payload.body || "", {
          status: payload.status,
          statusText: payload.statusText,
          headers: payload.headers || {},
          url: payload.url || request.url,
          offloaded: payload.offloaded === true,
          nativeBufferId: payload.nativeBufferId,
          offloadedBytes: payload.offloadedBytes,
        });
      } finally {
        cleanupSignalListeners();
        clearTimeoutIfNeeded();
      }
    });
  }

  globalThis.__web.Request = Request;
  globalThis.__web.Response = Response;
  globalThis.__web.fetch = fetch;
})();
