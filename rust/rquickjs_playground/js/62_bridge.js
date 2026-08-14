(() => {
  async function decodeHostData(data) {
    if (
      data
      && typeof data === "object"
      && (data.__hostProtocol === undefined || data.__hostProtocol === "bridge-binary-v1")
      && data.__hostReturnKind === "bytes"
      && data.nativeBufferId !== undefined
      && data.nativeBufferId !== null
    ) {
      if (!globalThis.native || typeof globalThis.native.take !== "function") {
        throw new Error("native.take 不可用，无法读取 bridge 二进制返回值");
      }
      const id = Number(data.nativeBufferId);
      return globalThis.native.take(id);
    }
    return data;
  }

  function buildHostError(payload) {
    const errInfo = payload.errorInfo;
    if (errInfo && typeof errInfo === "object") {
      const code = String(errInfo.code || "BRIDGE_CALL_FAILED");
      const message = String(errInfo.message || "bridge 调用失败");
      const details = errInfo.details;
      const out = new Error(`[${code}] ${message}`);
      out.code = code;
      out.details = details;
      return out;
    }
    const err = payload.error;
    if (err && typeof err === "object") {
      const code = String(err.code || "BRIDGE_CALL_FAILED");
      const message = String(err.message || "bridge 调用失败");
      const details = err.details;
      const out = new Error(`[${code}] ${message}`);
      out.code = code;
      out.details = details;
      return out;
    }
    return new Error(String(err || "bridge 调用失败"));
  }

  function decodeHostDataSync(data) {
    if (
      data
      && typeof data === "object"
      && (data.__hostProtocol === undefined || data.__hostProtocol === "bridge-binary-v1")
      && data.__hostReturnKind === "bytes"
      && data.nativeBufferId !== undefined
      && data.nativeBufferId !== null
    ) {
      throw new Error("bridge 返回了二进制数据，请使用异步版 bridge.call()");
    }
    return data;
  }

  function parseHostSync(raw) {
    const payload = JSON.parse(raw);
    if (!payload.ok) {
      throw buildHostError(payload);
    }
    return decodeHostDataSync(payload.data);
  }

  async function parseHost(raw) {
    const payload = JSON.parse(raw);
    if (!payload.ok) {
      throw buildHostError(payload);
    }
    return decodeHostData(payload.data);
  }

  function toByteArray(input) {
    if (input instanceof Uint8Array) return input;
    if (ArrayBuffer.isView(input)) {
      return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
    }
    if (input instanceof ArrayBuffer) {
      return new Uint8Array(input);
    }
    return null;
  }

  function normalizeArg(input) {
    const bytes = toByteArray(input);
    if (bytes) {
      if (
        typeof globalThis.__native_buffer_put_raw === "function"
        || typeof globalThis.__native_buffer_put === "function"
      ) {
        let id = null;
        if (typeof globalThis.__native_buffer_put_raw === "function") {
          try {
            id = globalThis.__native_buffer_put_raw(bytes);
          } catch (_) {
          }
        }
        if ((id === null || id === undefined) && typeof globalThis.__native_buffer_put === "function") {
          const raw = globalThis.__native_buffer_put(JSON.stringify(Array.from(bytes)));
          const payload = JSON.parse(raw);
          if (!payload || payload.ok !== true) {
            throw new Error(payload && payload.error ? String(payload.error) : "native put failed");
          }
          id = payload.id;
        }
        if (id !== null && id !== undefined) {
          return {
            __hostProtocol: "bridge-binary-v1",
            __hostArgKind: "bytes",
            nativeBufferId: Number(id),
            byteLength: Number(bytes.byteLength || 0),
          };
        }
      }
      return Array.from(bytes);
    }

    if (Array.isArray(input)) {
      return input.map((item) => normalizeArg(item));
    }

    if (input && typeof input === "object" && Object.getPrototypeOf(input) === Object.prototype) {
      const out = {};
      for (const [key, value] of Object.entries(input)) {
        out[key] = normalizeArg(value);
      }
      return out;
    }

    return input;
  }

  async function call(name, ...args) {
    const normalizedArgs = args.map((arg) => normalizeArg(arg));
    const routeName = String(name);

    if (typeof globalThis.__host_call_route_mode === "function") {
      try {
        const mode = globalThis.__host_call_route_mode(routeName);
        if (mode === "sync") {
          const raw = globalThis.__host_call(routeName, JSON.stringify(normalizedArgs));
          return parseHost(raw);
        }
      } catch (_) {
      }
    }

    if (
      typeof globalThis.__host_call_start === "function"
      && typeof globalThis.__host_call_try_take === "function"
    ) {
      const started = await parseHost(
        globalThis.__host_call_start(routeName, JSON.stringify(normalizedArgs)),
      );
      const id = Number(started && started.id);
      if (!Number.isFinite(id) || id <= 0) {
        throw new Error("bridge 任务启动失败: 无效 id");
      }

      try {
        while (true) {
          const tickRaw = globalThis.__host_call_try_take(id);
          const tick = JSON.parse(tickRaw);
          if (!tick.ok) {
            throw new Error(tick.error || "bridge 调用失败");
          }
          if (tick.done) {
            return parseHost(tick.result);
          }
          await new Promise((resolve) => setTimeout(resolve, 0));
        }
      } finally {
        if (typeof globalThis.__host_call_drop === "function") {
          try {
            globalThis.__host_call_drop(id);
          } catch (_) {
          }
        }
      }
    }

    const raw = globalThis.__host_call(routeName, JSON.stringify(normalizedArgs));
    return parseHost(raw);
  }

  function callSync(name, ...args) {
    const normalizedArgs = args.map((arg) => normalizeArg(arg));
    const raw = globalThis.__host_call(String(name), JSON.stringify(normalizedArgs));
    return parseHostSync(raw);
  }

  async function gzipDecompress(input) {
    const out = await call("compression.gzip_decompress", input);
    if (out instanceof Uint8Array) return out;
    if (ArrayBuffer.isView(out)) return new Uint8Array(out.buffer, out.byteOffset, out.byteLength);
    if (out instanceof ArrayBuffer) return new Uint8Array(out);
    return Uint8Array.from(Array.isArray(out) ? out : []);
  }

  async function gzipCompress(input) {
    const out = await call("compression.gzip_compress", input);
    if (out instanceof Uint8Array) return out;
    if (ArrayBuffer.isView(out)) return new Uint8Array(out.buffer, out.byteOffset, out.byteLength);
    if (out instanceof ArrayBuffer) return new Uint8Array(out);
    return Uint8Array.from(Array.isArray(out) ? out : []);
  }

  globalThis.__web.bridge = {
    call,
    callSync,
    gzipDecompress,
    gzipCompress,
  };
})();
