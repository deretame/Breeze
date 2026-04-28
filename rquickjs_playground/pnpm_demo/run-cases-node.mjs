import {
  appendFile,
  mkdtemp,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import {
  createHash,
  createHmac,
  randomBytes,
  randomUUID,
} from "node:crypto";
import { createServer } from "node:http";
import { resolve } from "node:path";
import { tmpdir } from "node:os";

const caseNames = ["fetch", "axios", "fs", "native", "runtime", "runtime_api", "wasi", "bridge"];

function toUint8Array(input) {
  if (input instanceof Uint8Array) return new Uint8Array(input);
  if (ArrayBuffer.isView(input)) {
    return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
  }
  if (input instanceof ArrayBuffer) return new Uint8Array(input);
  throw new TypeError("input must be Uint8Array/ArrayBuffer");
}

async function startTestServer() {
  const server = createServer(async (req, res) => {
    const method = String(req.method || "GET");
    const path = String(req.url || "/");
    if (path === "/axios-binary") {
      res.statusCode = 200;
      res.setHeader("content-type", "application/octet-stream");
      res.setHeader("connection", "close");
      res.end(Buffer.from([0, 1, 2, 3, 250, 251, 252, 253, 254, 255]));
      return;
    }
    const headers = Object.fromEntries(
      Object.entries(req.headers).map(([k, v]) => [k.toLowerCase(), Array.isArray(v) ? v.join(",") : String(v ?? "")]),
    );
    const bodyChunks = [];
    for await (const chunk of req) {
      bodyChunks.push(Buffer.from(chunk));
    }
    const body = Buffer.concat(bodyChunks).toString("utf8");
    const payload = JSON.stringify({ method, path, headers, body });
    res.statusCode = 200;
    res.setHeader("content-type", "application/json");
    res.setHeader("connection", "close");
    res.end(payload);
  });

  await new Promise((resolveReady, rejectReady) => {
    server.once("error", rejectReady);
    server.listen(0, "127.0.0.1", resolveReady);
  });

  const addr = server.address();
  if (!addr || typeof addr === "string") {
    throw new Error("无法获取测试服务地址");
  }

  return {
    baseUrl: `http://127.0.0.1:${addr.port}`,
    close: async () => {
      await new Promise((resolveClose, rejectClose) => {
        server.close((err) => {
          if (err) rejectClose(err);
          else resolveClose();
        });
      });
    },
  };
}

function createRuntimeAdapters() {
  let nextId = 1;
  const pool = new Map();

  const alloc = (bytes) => {
    const id = nextId;
    nextId += 1;
    pool.set(id, new Uint8Array(bytes));
    return id;
  };

  const takePool = (id) => {
    if (!pool.has(id)) throw new Error("buffer id 不存在");
    const bytes = pool.get(id);
    pool.delete(id);
    return bytes;
  };

  const applyOp = (op, input, extra) => {
    const out = new Uint8Array(input);
    if (op === "invert") {
      for (let i = 0; i < out.length; i += 1) out[i] = 255 - out[i];
      return out;
    }
    if (op === "grayscale_rgba") {
      for (let i = 0; i + 3 < out.length; i += 4) {
        const y = Math.round(0.299 * out[i] + 0.587 * out[i + 1] + 0.114 * out[i + 2]);
        out[i] = y;
        out[i + 1] = y;
        out[i + 2] = y;
      }
      return out;
    }
    if (op === "xor") {
      if (!extra) throw new Error("xor 需要第二个输入参数");
      if (extra.length !== out.length) throw new Error("xor 两个输入长度必须一致");
      for (let i = 0; i < out.length; i += 1) out[i] ^= extra[i];
      return out;
    }
    if (op === "noop") return out;
    throw new Error(`不支持的 native op: ${op}`);
  };

  const native = {
    supportsBinaryBridge: true,
    async put(input) {
      return alloc(toUint8Array(input));
    },
    async take(id) {
      return new Uint8Array(takePool(Number(id)));
    },
    async free(id) {
      pool.delete(Number(id));
    },
    async exec(op, inputId, _args, extraInputId) {
      const input = takePool(Number(inputId));
      const extra = extraInputId === undefined || extraInputId === null
        ? undefined
        : takePool(Number(extraInputId));
      return alloc(applyOp(String(op), input, extra));
    },
    async execChain(inputId, steps) {
      if (!Array.isArray(steps) || steps.length === 0) {
        throw new TypeError("steps 必须是非空数组");
      }
      let current = takePool(Number(inputId));
      for (const step of steps) {
        const normalized = typeof step === "string" ? { op: step } : step;
        if (!normalized || typeof normalized.op !== "string") {
          throw new TypeError("steps 元素缺少 op 字段");
        }
        const extra = normalized.extraInputId === undefined || normalized.extraInputId === null
          ? undefined
          : takePool(Number(normalized.extraInputId));
        current = applyOp(normalized.op, current, extra);
      }
      return alloc(current);
    },
    async run(op, input, args, extraInput) {
      const inputId = await this.put(input);
      const extraId = extraInput === undefined || extraInput === null
        ? null
        : (typeof extraInput === "number" ? Number(extraInput) : await this.put(extraInput));
      const outId = await this.exec(op, inputId, args, extraId);
      return this.take(outId);
    },
    async chain(steps, inputOrId) {
      const inputId = typeof inputOrId === "number" ? Number(inputOrId) : await this.put(inputOrId);
      const outId = await this.execChain(inputId, steps);
      return this.take(outId);
    },
  };

  const wasi = {
    async run(moduleBytes, options = {}) {
      const moduleId = await native.put(moduleBytes);
      return this.runById(moduleId, options);
    },
    async runById(moduleId, options = {}) {
      if (options.stdinId !== undefined && options.stdinId !== null) {
        takePool(Number(options.stdinId));
      }

      const consumeModule = options.reuseModule ? false : true;
      const source = consumeModule
        ? takePool(Number(moduleId))
        : pool.get(Number(moduleId));
      if (!source) throw new Error("module id 不存在");
      const wasmBytes = new Uint8Array(source);

      let instance;
      try {
        const compiled = await WebAssembly.compile(wasmBytes);
        instance = await WebAssembly.instantiate(compiled, {});
      } catch (err) {
        throw new Error(String(err && err.message ? err.message : err));
      }

      const start = instance && instance.exports ? instance.exports._start : undefined;
      if (typeof start === "function") {
        try {
          start();
        } catch (err) {
          throw new Error(String(err && err.message ? err.message : err));
        }
      }

      return {
        exitCode: 0,
        stdoutId: alloc(new Uint8Array(0)),
        stderrId: alloc(new Uint8Array(0)),
      };
    },
    async takeStdout(result) {
      return native.take(result.stdoutId);
    },
    async takeStderr(result) {
      return native.take(result.stderrId);
    },
  };

  const bridge = {
    async call(name, ...args) {
      const method = String(name || "");
      if (method === "math.add") {
        return Number(args[0] || 0) + Number(args[1] || 0);
      }
      if (method === "native.put") {
        return native.put(new Uint8Array(args[0] || []));
      }
      if (method === "native.take") {
        return Array.from(await native.take(Number(args[0])));
      }
      if (method === "native.exec") {
        return native.exec(String(args[0]), Number(args[1]), args[2] ?? null, args[3] ?? null);
      }
      throw new Error(`不支持的 bridge 方法: ${method}`);
    },
  };

  return {
    fs: {
      promises: {
        writeFile,
        appendFile,
        readFile,
        rm,
      },
    },
    bridge,
    nodeCryptoCompat: {
      createHash,
      createHmac,
      randomBytes,
    },
    uuidv4: () => randomUUID().replace(/-/g, ""),
    native,
    wasi,
  };
}

function loadCaseEntry(code) {
  const module = { exports: {} };
  const exports = module.exports;
  const requireFn = typeof require === "function" ? require : undefined;
  const runner = new Function("module", "exports", "require", code);
  runner(module, exports, requireFn);

  let entry = module.exports;
  if (entry && typeof entry === "object" && "default" in entry) {
    entry = entry.default;
  }
  if (typeof entry !== "function") {
    throw new Error("case bundle 必须导出默认函数");
  }
  return entry;
}

Object.assign(globalThis, createRuntimeAdapters());

const baseDir = await mkdtemp(resolve(tmpdir(), "rquickjs-node-case-"));
const server = await startTestServer();

try {
  for (const name of caseNames) {
    const file = resolve("dist/cases", `${name}.js`);
    const code = await readFile(file, "utf8");
    const entry = loadCaseEntry(code);
    const out = await Promise.race([
      entry({ baseDir, baseUrl: server.baseUrl }),
      new Promise((_, reject) => setTimeout(() => reject(new Error(`case ${name} 执行超时`)), 8000)),
    ]);
    if (!out || out.ok !== true) {
      throw new Error(`case ${name} 在 node 运行失败: ${JSON.stringify(out)}`);
    }
  }
} finally {
  await server.close();
  await rm(baseDir, { recursive: true, force: true });
}

console.log(JSON.stringify({ ok: true, cases: caseNames.length }));
