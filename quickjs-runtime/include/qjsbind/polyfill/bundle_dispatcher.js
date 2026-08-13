// bundle_dispatcher.js —— bundle 分发器（qjs::HostRuntime 的 JS 侧）
//
// 设计文档：docs/runtime_management_design.md
// 安装后提供两个全局函数（每实例一份，随 Runtime 重建而重放）：
//
//   globalThis.__bundle_set_exports(name, exports, mapJson)
//     登记本实例的 bundle 导出表（C++ 侧 load_bundle 完成 CJS 包装与求值后
//     回调此函数；bundle 文件名进入错误栈由 C++ 侧 JS_Eval 的 filename 保证）。
//     导出表规范化（Node 风格 CJS 互操作）：单层 default unwrap；非 object/
//     function 导出抛 TypeError。mapJson 为行内 source map
//     （//# sourceMappingURL=data:...;base64,...）解出的 JSON 文本；有则错误栈
//     自动 remap 回原始源码位置（依赖 source_map_lib.js 的 __sourcemap_lib）。
//
//   globalThis.__invoke(path, argsJson, settle, signal)
//     覆盖 TaskRunner 安装的默认 trampoline：按点路径（"a.b.c"）在 bundle
//     导出表上解析函数并以正确的 this 调用（signal 作为最后一个参数追加），
//     promise 链结算。
//
// 序列化协议（设计文档 §2/§3，调用方自行解释返回的 std::string）：
//   - 顶层纯二进制（ArrayBuffer / TypedArray / DataView）：走 native buffer 池
//     （BlobStore），settle 负载为 "\x00buf:" + id，C++ 侧按 id 取字节交付
//     （消费语义），无 base64 开销；
//   - 其他一切值：JSON.stringify；嵌套二进制字段编码为
//     { "$type": "bytes", "base64": "..." }。
// 入参方向（host→JS）：调用方 HostRuntime::put_buffer 得 id，在 args JSON 里
//   嵌 {"$buf": "<id>"} 占位（任意深度），materializeArgs 在调用前替换为
//   Uint8Array（消费语义；id 不存在/过期 → invalid_args）。
//
// 错误协议（Node 风格，结构化载荷）：
//   settle(false, "@@errj:" + JSON.stringify({ c, n, m, s, g }))
//     c = 程序码（function_not_found / invalid_args / js_exception）
//     n = 错误名（TypeError 等）  m = 消息   s = remap 后的栈   g = 调用上下文
//     （bundle:<名> fn:<路径> args:<参数> source:<文件>，Node 风格 [scope] 前缀
//     由 C++ 侧拼装）。C++ 侧按 c 映射 runtime_errc，按 n/m/s/g 拼装最终文本。
(function () {
  "use strict";

  // base64 编码走 native（BoringSSL EVP_EncodeBlock），由 install_bundle_dispatcher 注册
  const b64encode = globalThis.__native_b64encode;

  function toBytes(v) {
    if (v instanceof ArrayBuffer) return new Uint8Array(v);
    if (ArrayBuffer.isView(v)) return new Uint8Array(v.buffer, v.byteOffset, v.byteLength);
    return null;
  }

  function serialize(v) {
    const b = toBytes(v);
    // 顶层纯二进制走 native buffer 池（消费语义），settle 负载为 "\x00buf:" + id，
    // C++ 侧 wait() 按 id 取字节交付，无 base64 开销
    if (b) return "\x00buf:" + globalThis.__native_buf_put(b);
    const s = JSON.stringify(v, (k, val) => {
      const bb = toBytes(val);
      return bb ? { $type: "bytes", base64: b64encode(bb) } : val;
    });
    return s === undefined ? "null" : s;
  }

  // args 物化：递归把 {"$buf": "<id>"} 占位替换为 Uint8Array（消费 pool 条目）
  function materializeArgs(v) {
    if (Array.isArray(v)) {
      for (let i = 0; i < v.length; i++) v[i] = materializeArgs(v[i]);
      return v;
    }
    if (v && typeof v === "object") {
      if (typeof v.$buf === "string") {
        const bytes = globalThis.__native_buf_take(v.$buf);
        if (bytes === null)
          throw protoError("invalid_args",
            "unknown or expired native buffer id: " + v.$buf);
        return bytes;
      }
      for (const k of Object.keys(v)) v[k] = materializeArgs(v[k]);
      return v;
    }
    return v;
  }

  // ---- 诊断辅助（Node 风格的详细 TypeError 用）----
  const isSafeKey = (k) => k !== "__proto__" && k !== "prototype" && k !== "constructor";
  const safeTypeOf = (v) => (v === null ? "null" : Array.isArray(v) ? "array" : typeof v);
  const ownKeysPreview = (obj, max = 24) => {
    if (!obj || (typeof obj !== "object" && typeof obj !== "function")) return [];
    try {
      return Object.keys(obj).slice(0, max);
    } catch (_e) {
      return [];
    }
  };

  let bundleExports = {};
  let bundleName = "bundle";
  let bundleMapJson = null;   // 行内 source map 的 JSON 文本（无则 null）
  let bundleMap = undefined;  // 惰性构建的 TraceMap；null = 构建失败

  // 把错误栈里的 <name>.bundle.cjs:line:col 映射回原始源码位置。
  // 注意：栈行号是 CJS 包装后文件的行号（包装头占 1 行），查询映射前减 1。
  function remapStack(text) {
    if (!bundleMapJson || typeof __sourcemap_lib === "undefined") return text;
    if (bundleMap === undefined) {
      try {
        bundleMap = new __sourcemap_lib.TraceMap(JSON.parse(bundleMapJson));
      } catch (e) {
        bundleMap = null;
      }
    }
    if (!bundleMap) return text;
    const filePat = bundleName + ".bundle.cjs";
    return String(text).split("\n").map((line) => {
      const idx = line.indexOf(filePat + ":");
      if (idx < 0) return line;
      const m = /:(\d+):(\d+)/.exec(line.slice(idx + filePat.length));
      if (!m) return line;
      const pos = __sourcemap_lib.originalPositionFor(bundleMap, {
        line: Number(m[1]) - 1,
        column: Number(m[2]),
      });
      if (!pos || !pos.source) return line;
      return line.slice(0, idx) + pos.source + ":" + pos.line + ":" + pos.column +
             line.slice(idx + filePat.length + m[0].length);
    }).join("\n");
  }

  globalThis.__bundle_set_exports = (name, exports, mapJson) => {
    bundleName = String(name || "bundle");
    // Node 风格 CJS 互操作：单层 default unwrap；导出必须是 object/function
    let api = exports;
    if (api && typeof api === "object" && api.default !== undefined) api = api.default;
    if (!api || (typeof api !== "object" && typeof api !== "function"))
      throw new TypeError("bundle must export object or function");
    bundleExports = api;
    bundleMapJson = typeof mapJson === "string" ? mapJson : null;
    bundleMap = undefined;
    return true;
  };

  // 协议性错误：真实 TypeError + __code（stack 保留，指向诊断现场）
  function protoError(code, message) {
    const e = new TypeError(message);
    e.__code = code;
    return e;
  }

  // 点路径解析：逐段下钻，每步给出可定位的诊断信息
  function resolveCallable(path) {
    const parts = String(path).split(".").filter(Boolean);
    if (parts.length === 0)
      throw protoError("function_not_found", "function path is empty");
    let owner = bundleExports;
    for (let i = 0; i < parts.length - 1; i++) {
      const key = parts[i];
      if (!isSafeKey(key))
        throw protoError("invalid_args", "unsafe path segment: " + key);
      owner = owner == null ? undefined : owner[key];
      if (owner === undefined || owner === null)
        throw protoError(
          "function_not_found",
          "function path not found: " + path +
            "; missing segment=" + key +
            "; rootType=" + safeTypeOf(bundleExports) +
            "; rootKeys=" + JSON.stringify(ownKeysPreview(bundleExports)));
    }
    const leaf = parts[parts.length - 1];
    if (!isSafeKey(leaf))
      throw protoError("invalid_args", "unsafe path segment: " + leaf);
    const fn = owner == null ? undefined : owner[leaf];
    if (typeof fn !== "function")
      throw protoError(
        "function_not_found",
        "target is not function: " + path +
          "; targetType=" + safeTypeOf(fn) +
          "; ownerType=" + safeTypeOf(owner) +
          "; ownerKeys=" + JSON.stringify(ownKeysPreview(owner)) +
          "; rootKeys=" + JSON.stringify(ownKeysPreview(bundleExports)));
    return { owner, fn };
  }

  // 结构化错误载荷：消息/栈/上下文分离，Node 风格拼装由 C++ 侧完成
  function errorPayload(err, path, argsJson) {
    const scope = "bundle:" + bundleName +
                  " fn:" + String(path || "?") +
                  " args:" + (argsJson || "[]") +
                  " source:" + bundleName + ".bundle.cjs";
    let code = "js_exception";
    let name = "Error";
    let message;
    let stack = "";
    if (err && err.__code) {
      code = String(err.__code);
    }
    if (err instanceof Error ||
        (typeof Error.isError === "function" && Error.isError(err))) {
      name = String(err.name || "Error");
      message = String(err.message != null ? err.message : err);
      stack = err.stack ? String(err.stack) : "";
    } else {
      // 非 Error 抛出值：包出栈（captureStackTrace 存在则从本帧起算）
      message = String(err === undefined ? "undefined" : err === null ? "null" : err);
      const enriched = new Error(message);
      if (typeof Error.captureStackTrace === "function")
        Error.captureStackTrace(enriched, errorPayload);
      stack = enriched.stack ? String(enriched.stack) : "";
    }
    return "@@errj:" + JSON.stringify({
      c: code, n: name, m: message, s: remapStack(stack), g: scope,
    });
  }

  globalThis.__invoke = (path, argsJson, settle, signal) => {
    Promise.resolve()
      .then(() => {
        const { owner, fn } = resolveCallable(path);
        // 参数约定：JSON 文本整体 parse 后作为唯一参数传递（命名参数风格：
        // {"a":1,"b":2} → fn({a:1,b:2})），signal 作为第二参数追加
        let arg;
        try {
          arg = JSON.parse(argsJson);
        } catch (e) {
          throw protoError("invalid_args",
            "args is not valid JSON: " + String((e && e.message) || e));
        }
        return fn.apply(owner, [materializeArgs(arg), signal]);
      })
      .then(
        (v) => settle(true, serialize(v)),
        (e) => settle(false, errorPayload(e, path, argsJson)),
      );
  };
})();
