(() => {
  function parseHost(raw) {
    const payload = JSON.parse(raw);
    if (!payload.ok) {
      throw new Error(payload.error || "native 调用失败");
    }
    return payload;
  }

  function toByteArray(input) {
    if (input instanceof Uint8Array) return input;
    if (ArrayBuffer.isView(input)) {
      return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
    }
    if (input instanceof ArrayBuffer) {
      return new Uint8Array(input);
    }
    throw new TypeError("input 必须是 Uint8Array/ArrayBuffer");
  }

  async function put(input) {
    const arr = toByteArray(input);
    if (typeof globalThis.__native_buffer_put_raw === "function") {
      try {
        const id = globalThis.__native_buffer_put_raw(arr);
        if (typeof id === "number" && Number.isFinite(id) && id > 0) {
          return id;
        }
      } catch (_) {
      }
    }
    const res = parseHost(globalThis.__native_buffer_put(JSON.stringify(Array.from(arr))));
    return res.id;
  }

  async function exec(op, inputId, args, extraInputId) {
    const argsJson = args === undefined ? null : JSON.stringify(args);
    const extraId = extraInputId === undefined || extraInputId === null ? null : Number(extraInputId);
    const res = parseHost(globalThis.__native_exec(String(op), Number(inputId), argsJson, extraId));
    return res.id;
  }

  function normalizeChainSteps(steps) {
    if (!Array.isArray(steps) || steps.length === 0) {
      throw new TypeError("steps 必须是非空数组");
    }
    return steps.map((step) => {
      if (typeof step === "string") {
        return { op: step };
      }
      if (!step || typeof step !== "object") {
        throw new TypeError("steps 元素必须是字符串或对象");
      }
      if (!step.op || typeof step.op !== "string") {
        throw new TypeError("steps 元素缺少 op 字段");
      }
      const normalized = { op: step.op };
      if (step.extraInputId !== undefined && step.extraInputId !== null) {
        normalized.extraInputId = Number(step.extraInputId);
      }
      return normalized;
    });
  }

  async function execChain(inputId, steps) {
    const normalized = normalizeChainSteps(steps);
    const res = parseHost(globalThis.__native_exec_chain(Number(inputId), JSON.stringify(normalized)));
    return res.id;
  }

  async function take(id) {
    if (typeof globalThis.__native_buffer_take_raw === "function") {
      try {
        const raw = globalThis.__native_buffer_take_raw(Number(id));
        if (raw !== null && raw !== undefined) {
          if (raw instanceof Uint8Array) return raw;
          if (ArrayBuffer.isView(raw)) return new Uint8Array(raw.buffer, raw.byteOffset, raw.byteLength);
          if (raw instanceof ArrayBuffer) return new Uint8Array(raw);
          if (Array.isArray(raw)) return Uint8Array.from(raw);
        }
      } catch (_) {
      }
    }
    const res = parseHost(globalThis.__native_buffer_take(Number(id)));
    return Uint8Array.from(res.data || []);
  }

  async function takeInto(id, existing, offset = 0) {
    const target = toByteArray(existing);
    const start = Math.max(0, Number(offset) || 0);
    const data = await take(id);
    const writable = Math.max(0, target.length - start);
    const bytesWritten = Math.min(writable, data.length);
    if (bytesWritten > 0) {
      target.set(data.subarray(0, bytesWritten), start);
    }
    return {
      buffer: target,
      bytesWritten,
      sourceLength: data.length,
      truncated: bytesWritten < data.length,
    };
  }

  async function free(id) {
    parseHost(globalThis.__native_buffer_free(Number(id)));
  }

  async function run(op, input, args, extraInput) {
    const id = await put(input);
    let extraId = null;
    if (extraInput !== undefined && extraInput !== null) {
      if (typeof extraInput === "number") {
        extraId = Number(extraInput);
      } else {
        extraId = await put(extraInput);
      }
    }
    const outId = await exec(op, id, args, extraId);
    return take(outId);
  }

  async function chain(steps, input) {
    const inputId = typeof input === "number" ? Number(input) : await put(input);
    const outId = await execChain(inputId, steps);
    return take(outId);
  }

  async function gzipDecompress(input) {
    return run("gzip_decompress", input);
  }

  async function gzipCompress(input) {
    return run("gzip_compress", input);
  }

  globalThis.__web.native = {
    supportsBinaryBridge:
      typeof globalThis.__native_buffer_put_raw === "function"
      && typeof globalThis.__native_buffer_take_raw === "function",
    put,
    exec,
    execChain,
    take,
    takeInto,
    free,
    run,
    chain,
    gzipDecompress,
    gzipCompress,
  };
})();
