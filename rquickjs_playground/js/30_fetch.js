(() => {
  const HOST_FORMDATA_BODY_HEADER = "x-rquickjs-host-body-formdata-v1";
  const EVENTED_HTTP_PENDING = new Map();
  const prevHttpComplete = globalThis.__host_runtime_http_complete;

  globalThis.__host_runtime_http_complete = function __host_runtime_http_complete(requestId, payloadRaw) {
    const pending = EVENTED_HTTP_PENDING.get(Number(requestId));
    if (!pending) {
      if (typeof prevHttpComplete === "function") prevHttpComplete(requestId, payloadRaw);
      return;
    }
    EVENTED_HTTP_PENDING.delete(Number(requestId));

    const { request, resolve, reject, finish, dropPending } = pending;

    let payload;
    try {
      payload = JSON.parse(String(payloadRaw || "{}"));
    } catch (err) {
      dropPending();
      finish(() => reject(err));
      return;
    }

    if (!payload.ok) {
      dropPending();
      finish(() => reject(new TypeError(payload.error || "网络请求失败")));
      return;
    }

    finish(() =>
      resolve(
        new Response(payload.body || "", {
          status: payload.status,
          statusText: payload.statusText,
          headers: payload.headers || {},
          url: payload.url || request.url,
          offloaded: payload.offloaded === true,
          nativeBufferId: payload.nativeBufferId,
          offloadedBytes: payload.offloadedBytes,
        }),
      ),
    );
  };

  const {
    parseBodyInit,
    parseBodyInitAsync,
    stringToArrayBuffer,
    normalizeMethod,
    Headers,
  } = globalThis.__web;

  class BodyMixin {
    _initBody(bodyText, meta = {}) {
      this._bodyText = bodyText || "";
      this.bodyUsed = false;
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
      if (!this._tryConsumeBodyState()) {
        this.bodyUsed = true;
        return Promise.reject(new TypeError("Body 已被读取"));
      }
      this.bodyUsed = true;
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
      return Promise.resolve(this._bodyText);
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
      if (this.offloaded === true && this.nativeBufferId !== null && this.nativeBufferId !== undefined) {
        if (!globalThis.native || typeof globalThis.native.take !== "function") {
          return Promise.reject(new TypeError("native.take 不可用，无法读取 offload 二进制数据"));
        }
        if (!this._tryConsumeBodyState()) {
          this.bodyUsed = true;
          return Promise.reject(new TypeError("Body 已被读取"));
        }
        this.bodyUsed = true;
        const id = Number(this.nativeBufferId);
        this.nativeBufferId = null;
        return globalThis.native.take(id).then((bytes) => {
          const out = new Uint8Array(bytes.length);
          out.set(bytes);
          return out.buffer;
        });
      }
      return this._consumeBody().then((text) => {
        if (typeof TextEncoder === "function") {
          const bytes = new TextEncoder().encode(text);
          const out = new Uint8Array(bytes.length);
          out.set(bytes);
          return out.buffer;
        }
        return stringToArrayBuffer(text);
      });
    }

    blob() {
      return this.arrayBuffer().then((ab) => new Blob([ab]));
    }
  }

  class Request extends BodyMixin {
    constructor(input, init = {}) {
      super();
      this._hasBody = false;
      this._bodyNativeBufferId = null;

      if (input instanceof Request) {
        this.url = input.url;
        this.method = input.method;
        this.headers = new Headers(input.headers);
        this._initBody(input._bodyText, {
          offloaded: false,
          nativeBody: Boolean(input._bodyNativeBufferId !== null && input._bodyNativeBufferId !== undefined),
        });
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
      if (init.headers) this.headers = new Headers(init.headers);
      if (Object.prototype.hasOwnProperty.call(init, "signal")) {
        this.signal = init.signal || null;
      }
      this.credentials = init.credentials || "same-origin";
      this.mode = init.mode || null;
      this.redirect = init.redirect || "follow";
      this.referrer = init.referrer || "about:client";
      this.referrerPolicy = init.referrerPolicy || "";
      this.integrity = init.integrity || "";
      this.keepalive = Boolean(init.keepalive);
      this.cache = init.cache || "default";

      if (Object.prototype.hasOwnProperty.call(init, "timeout") || Object.prototype.hasOwnProperty.call(init, "timeoutMs")) {
        const timeoutRaw = Object.prototype.hasOwnProperty.call(init, "timeoutMs") ? init.timeoutMs : init.timeout;
        const timeout = Number(timeoutRaw);
        this.timeout = Number.isFinite(timeout) && timeout > 0 ? Math.floor(timeout) : null;
      }

      const syncBodyInit = parseBodyInit(init.body);
      if (syncBodyInit.bodyText !== undefined) {
        if (this.method === "GET" || this.method === "HEAD") {
          throw new TypeError("GET/HEAD 请求不能带 body");
        }
        this._initBody(syncBodyInit.bodyText, { offloaded: false, nativeBody: false });
        this._hasBody = true;
        if (!this.headers.has("content-type") && syncBodyInit.contentType) {
          this.headers.set("content-type", syncBodyInit.contentType);
        }
        if (syncBodyInit.hostBodyKind === "formData") {
          this.headers.set(HOST_FORMDATA_BODY_HEADER, "1");
        }
      }

      this._bodyInitPromise = Promise.resolve();
      if (init.body instanceof FormData || init.body instanceof Blob) {
        this._bodyInitPromise = parseBodyInitAsync(init.body).then((bodyInit) => {
        if (bodyInit.bodyText === undefined) return;
        if (this.method === "GET" || this.method === "HEAD") {
          throw new TypeError("GET/HEAD 请求不能带 body");
        }
        this._initBody(bodyInit.bodyText, { offloaded: false, nativeBody: false });
        this._hasBody = true;
        if (!this.headers.has("content-type") && bodyInit.contentType) {
          this.headers.set("content-type", bodyInit.contentType);
        }
        if (bodyInit.hostBodyKind === "formData") {
          this.headers.set(HOST_FORMDATA_BODY_HEADER, "1");
        }
        });
      }

      const maybeBinaryBody = init.body;
      const canUseNativeBinaryBody =
        globalThis.native &&
        typeof globalThis.native.put === "function" &&
        !(maybeBinaryBody instanceof FormData);
      if (
        canUseNativeBinaryBody &&
        (maybeBinaryBody instanceof ArrayBuffer ||
          ArrayBuffer.isView(maybeBinaryBody) ||
          maybeBinaryBody instanceof Blob)
      ) {
        this._bodyInitPromise = this._bodyInitPromise.then(async () => {
          this._bodyNativeBufferId = await globalThis.native.put(maybeBinaryBody);
          this._initBody("", { offloaded: false, nativeBody: true });
          this._hasBody = true;
          if (maybeBinaryBody instanceof Blob) {
            const contentType = maybeBinaryBody.type || "";
            if (contentType && !this.headers.has("content-type")) {
              this.headers.set("content-type", contentType);
            }
          }
        });
      }
    }

    clone() {
      if (this.bodyUsed) {
        throw new TypeError("Body 已被读取，无法 clone");
      }
      if (this._isBodyStateConsumed()) {
        this.bodyUsed = true;
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
        clonedInit.body = this._bodyText;
      }
      return new Request(this, {
        ...clonedInit,
      });
    }
  }

  class Response extends BodyMixin {
    constructor(body = "", init = {}) {
      super();
      this._initBody(String(body), {
        offloaded: Boolean(init.offloaded),
        nativeBody: false,
      });
      this.status = init.status || 200;
      this.statusText = init.statusText || "OK";
      this.headers = new Headers(init.headers || {});
      this.url = init.url || "";
      this.ok = this.status >= 200 && this.status < 300;
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
        this.bodyUsed = true;
        throw new TypeError("Body 已被读取，无法 clone");
      }
      if (this.offloaded && this.nativeBufferId !== null) {
        throw new TypeError("offload 响应暂不支持 clone");
      }
      return new Response(this._bodyText, {
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
            this.bodyUsed = true;
            throw new TypeError("Body 已被读取");
          }
        }
      }
      if (!this._tryConsumeBodyState()) {
        if (this.__fetchStateId === null || this.__fetchStateId === undefined) {
          this.bodyUsed = true;
          throw new TypeError("Body 已被读取");
        }
      }
      this.bodyUsed = true;

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

    static json(data, init = {}) {
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
      const request = input instanceof Request ? new Request(input, init) : new Request(input, init);
      const waitBodyInit = request && request._bodyInitPromise
        ? request._bodyInitPromise
        : Promise.resolve();

    return waitBodyInit.then(() => new Promise((resolve, reject) => {
      let requestId = null;
      let settled = false;
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

      const finish = (cb) => {
        if (settled) return;
        settled = true;
        clearTimeoutIfNeeded();
        cleanupSignalListeners();
        cb();
      };

      const dropPending = () => {
        if (requestId === null) return;
        try {
          globalThis.__http_request_drop_evented(requestId);
        } catch (_err) {
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
            EVENTED_HTTP_PENDING.delete(requestId);
            dropPending();
            const timeoutErr = new Error("请求超时");
            timeoutErr.name = "TimeoutError";
            finish(() => reject(timeoutErr));
          }, request.timeout);
        }
      }

      try {
        if (signal && signal.aborted) {
          finish(() => reject(buildAbortError()));
          return;
        }

        const startedRaw = globalThis.__http_request_start_evented(
          request.method,
          request.url,
          JSON.stringify(request.headers.toObject()),
          request._bodyText || null,
          request._bodyNativeBufferId === null || request._bodyNativeBufferId === undefined
            ? null
            : Number(request._bodyNativeBufferId),
        );
        const started = JSON.parse(startedRaw);
        if (!started.ok) {
          finish(() => reject(new TypeError(started.error || "网络请求失败")));
          return;
        }
        requestId = Number(started.id);

        const onAbort = () => {
          EVENTED_HTTP_PENDING.delete(requestId);
          dropPending();
          finish(() => reject(buildAbortError()));
        };
        if (signal) {
          signal.addEventListener("abort", onAbort);
          cleanupSignal = () => {
            signal.removeEventListener("abort", onAbort);
          };

          if (signal.aborted) {
            onAbort();
            return;
          }
        }

        EVENTED_HTTP_PENDING.set(requestId, {
          request,
          resolve,
          reject,
          finish,
          dropPending,
        });
      } catch (err) {
        dropPending();
        finish(() => reject(err));
      }
    }));
  }

  globalThis.__web.Request = Request;
  globalThis.__web.Response = Response;
  globalThis.__web.fetch = fetch;
})();
