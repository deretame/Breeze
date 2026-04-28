# rquickjs_playground 使用说明

这个项目提供一个 Rust 宿主 + QuickJS 运行时，核心能力有三块：

- Web API 兼容层（`fetch`）
- 异步文件 API（`fs` / `fs.promises`，无同步接口）
- Native 二进制计算管道 + WASI 模块执行

下面重点说明你现在最关心的 `wasi` 用法，以及高性能二进制处理方式。

---

## 1. 作为库使用

这个仓库现在是 **library-first**：默认提供可引入的 Rust 库。

在你的项目里引入：

```toml
[dependencies]
rquickjs_playground = { path = "../rquickjs_playground" }
```

最小示例：

```rust
use rquickjs_playground::AsyncHostRuntime;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let host = AsyncHostRuntime::new("demo-runtime")?;
    let output = host
        .spawn("(async () => JSON.stringify({ ok: true }))()")?
        .wait()?;
    println!("{output}");
    Ok(())
}
```

说明：`AsyncHostRuntime::new(runtime_name)` 默认不注入 `wasi`，而且默认构建也不会编译进 WASI 依赖。如果需要 `wasi`，请在 Cargo 里开启 `wasi` 特性，并改用 `AsyncHostRuntime::new_with_options(runtime_name, WebRuntimeOptions { wasi: true })`。

如果你想运行仓库里的演示：

```bash
cargo run --example demo
```

---

## 2. `native` 二进制管道（推荐用于图片处理）

设计目标：尽量减少 JS <-> Rust 间的大对象开销。

### 2.1 基础接口

- `native.put(Uint8Array) -> Promise<number>`
  - 把字节放进 Rust 缓冲池，返回 `id`。
- `native.exec(op, inputId, args?, extraInputId?) -> Promise<number>`
  - 对 `inputId` 执行一个操作，返回新 `id`。
- `native.execChain(inputId, steps) -> Promise<number>`
  - 一次提交多个步骤执行，减少 host 往返。
- `native.take(id) -> Promise<Uint8Array>`
  - 取回结果（会消费该 id）。
- `native.takeInto(id, existing, offset?) -> Promise<{...}>`
  - 把结果拷贝进已有 `Uint8Array`，减少 JS 侧重新分配。
- `native.free(id) -> Promise<void>`
  - 释放不再需要的缓冲。
- `native.run(op, input, args?, extraInput?) -> Promise<Uint8Array>`
  - 单步便捷接口。
- `native.chain(steps, inputOrId) -> Promise<Uint8Array>`
  - 多步便捷接口。

### 2.2 已实现的操作

- `invert`
- `grayscale_rgba`
- `xor`（需要第二输入）
- `noop`

### 2.3 示例

```js
const inputId = await native.put(new Uint8Array([1, 2, 3, 4]));
const outId = await native.execChain(inputId, [
  { op: "invert" },
  { op: "invert" },
  { op: "noop" }
]);

const target = new Uint8Array(1024);
const info = await native.takeInto(outId, target, 0);
// info.bytesWritten / info.sourceLength / info.truncated
```

---

## 3. `wasi` 模块执行（重点）

`wasi` 是“在宿主里执行 WASI 模块”，不是把宿主本身跑在 WASI 里。

### 3.1 提供的接口

- `wasi.run(moduleBytes, options?)`
- `wasi.runById(moduleId, options?)`
- `wasi.takeStdout(result)`
- `wasi.takeStderr(result)`

`run/runById` 返回：

```ts
{
  exitCode: number,
  stdoutId: number,
  stderrId: number
}
```

### 3.2 options 说明

要使用这一组 API，需要同时满足两件事：

1. Cargo 开启 `wasi` 特性
2. 创建运行时时显式开启 `wasi`

```toml
[dependencies]
rquickjs_playground = { path = "../rquickjs_playground", features = ["wasi"] }
```

然后：

```rust
use rquickjs_playground::{AsyncHostRuntime, WebRuntimeOptions};

let host = AsyncHostRuntime::new_with_options(
    "demo-runtime",
    WebRuntimeOptions { wasi: true },
)?;
```

- `args?: string[]`
  - 传给 WASI 模块 argv（宿主会自动补 `module.wasm` 为 argv[0]）。
- `stdinId?: number`
  - 从 `native.put(...)` 得到的输入缓冲 id。
- `reuseModule?: boolean`
  - `true`：不消费 `moduleId`，可重复运行。
  - `false/未传`：默认消费 `moduleId`（更省内存）。

### 3.3 最常见用法

```js
// wasmBytes: Uint8Array
const moduleId = await native.put(wasmBytes);

const result = await wasi.runById(moduleId, {
  reuseModule: true,
  args: ["--mode", "fast"]
});

const stdout = await wasi.takeStdout(result); // Uint8Array
const stderr = await wasi.takeStderr(result); // Uint8Array

// 不再复用时释放
await native.free(moduleId);
```

### 3.4 权限模型（当前实现）

当前 `wasi` 执行上下文默认是“计算优先、权限最小”：

- 没有给 guest 预打开目录（不提供宿主文件系统权限）
- 没有额外网络权限配置
- stdin/stdout/stderr 走内存管道

这适合你现在的目标：CPU 密集计算（如图片处理）而不是系统 IO。

---

## 4. 如何准备一个 WASI 模块

如果你要用 Rust 写一个 guest 程序，可以编译为 `wasm32-wasip1`：

```bash
rustup target add wasm32-wasip1
cargo build --target wasm32-wasip1 --release
```

生成的 `.wasm` 读成字节后传给 `wasi.run(...)` 或 `native.put(...) + wasi.runById(...)`。

---

## 5. 测试

```bash
cargo test
```

如果你要跑包含 WASI 的测试：

```bash
cargo test --features wasi
```

相关测试重点在：

- `src/tests/native.rs`
- `src/tests/fs.rs`
- `src/tests/fetch.rs`

---

## 5.1 Host FormData 协议（`rquickjs-formdata-v1`）

为了让 multipart 边界、编码细节完全由 `reqwest` 处理，当前实现采用“JS 结构化描述 -> Rust 组装 multipart”的协议。

### 目的

- 避免在 JS 端手写 multipart 文本与 boundary。
- 把 multipart 规范细节交给 `reqwest::multipart`。
- 后续可通过 `kind` 版本化扩展而不破坏已有行为。

### 传输流程

1. JS 端检测到 `body instanceof FormData`。
2. JS 将 `FormData` 编码为 JSON plan，作为 `body` 传给 host。
3. 同时追加请求头：`x-rquickjs-host-body-formdata-v1: 1`。
4. Rust 端识别该头后：
   - 解析 JSON plan；
   - 用 `reqwest::multipart::Form` / `Part` 构造请求；
   - 忽略 JS 侧 `content-type`，由 reqwest 自动生成 `multipart/form-data; boundary=...`。

### Plan 结构

顶层结构：

```json
{
  "kind": "rquickjs-formdata-v1",
  "entries": [
    {
      "name": "field1",
      "kind": "text",
      "value": "hello"
    },
    {
      "name": "file1",
      "kind": "binary",
      "dataB64": "aGVsbG8=",
      "filename": "a.txt",
      "contentType": "text/plain"
    }
  ]
}
```

字段说明：

- `kind`（顶层）
  - 当前固定 `rquickjs-formdata-v1`。
- `entries[]`
  - `name: string` 字段名。
  - `kind: "text" | "binary"`。
  - `value?: string`（`text` 必填）。
  - `dataB64?: string`（`binary` 必填，base64 字节）。
  - `filename?: string | null`（`binary` 可选）。
  - `contentType?: string | null`（`binary` 可选）。

### 兼容与约束

- Rust 端如果收到未知顶层 `kind`，会直接报错。
- 该协议只用于 `FormData`；其他 body（JSON、`URLSearchParams`、`Blob` 等）走原有分支。
- 建议后续新增字段时保持向后兼容；如有不兼容变更，升级 `kind`（例如 `rquickjs-formdata-v2`）。

---

## 6. 图片处理实战示例

下面给一个“可直接粘贴到 QuickJS 里执行”的最小示例。

场景：

- 输入一段 RGBA 原始像素（2x1）
- 先用 `native.chain` 做灰度化
- 再用 `takeInto` 复用预分配缓冲

```js
(async () => {
  // 2x1 RGBA: 红像素 + 绿像素
  const rgba = new Uint8Array([
    255, 0, 0, 255,
    0, 255, 0, 255,
  ]);

  // 多步链式（这里只有一步，也可继续加更多步骤）
  const out = await native.chain([
    "grayscale_rgba"
  ], rgba);

  // out 是新的 Uint8Array
  // 如果你想减少分配，建议用 takeInto
  const id = await native.put(rgba);
  const outId = await native.execChain(id, [
    { op: "grayscale_rgba" }
  ]);

  const reused = new Uint8Array(8);
  const info = await native.takeInto(outId, reused, 0);

  return JSON.stringify({
    out: Array.from(out),
    reused: Array.from(reused),
    bytesWritten: info.bytesWritten,
    truncated: info.truncated
  });
})()
```

如果你要把“下载图片 -> Rust/WASI 计算 -> 回 JS”串起来，推荐流程：

1. JS 先拿到图片字节（`Uint8Array`）
2. `native.put(bytes)` 拿到输入 id
3. `native.execChain(...)` 或 `wasi.runById(...)` 做计算
4. `native.take(...)` 或 `native.takeInto(...)` 取结果
5. 中间不再用的 id 及时 `native.free(...)`

---

## 7. WASI 模块版图片流水线示例

这个示例展示如何把输入字节通过 `stdinId` 传给 WASI 模块，再从 `stdout` 取回结果。

约定：

- WASI 模块从 stdin 读取输入字节
- WASI 模块把处理后的字节写到 stdout

```js
(async () => {
  // 这里只是示意：wasmBytes 通常来自文件读取或网络下载
  // 例如：const wasmBytes = await fs.promises.readFile("./image_worker.wasm");
  const wasmBytes = new Uint8Array([/* ... wasm 二进制 ... */]);

  // 输入图片字节（示意，真实场景可以是 PNG/JPEG/RGBA 等）
  const imageBytes = new Uint8Array([1, 2, 3, 4, 5]);

  const moduleId = await native.put(wasmBytes);
  const stdinId = await native.put(imageBytes);

  const result = await wasi.runById(moduleId, {
    // true 表示模块可复用，多次执行同一个模块时建议开启
    reuseModule: true,
    stdinId,
    args: ["--op", "grayscale"]
  });

  const processed = await wasi.takeStdout(result); // Uint8Array
  const logs = await wasi.takeStderr(result);      // Uint8Array

  // 用完后释放模块 id（如果后续还要复用就先不释放）
  await native.free(moduleId);

  return JSON.stringify({
    exitCode: result.exitCode,
    outputSize: processed.length,
    stderrSize: logs.length
  });
})()
```

建议：

- 多次调用同一个 WASI 模块时，用 `reuseModule: true`，减少模块重复加载成本。
- 如果输出大小可预估，拿到 `stdoutId` 后也可以结合 `native.takeInto(...)` 做复用缓冲。

---

## 9. Tokio + HTTP 并发请求示例

新增了一个“宿主收到多个 HTTP 请求 -> 分发到多个 QJS worker -> 按完成顺序逐条返回”的示例：

- `examples/http_plugin_pool.rs`

运行：

```bash
cargo run --example http_plugin_pool
```

这个示例演示了：

- 固定数量 QJS worker（常驻，不是每请求销毁）
- 本地 HTTP 接口（`POST /invoke`）
- JS 侧用 `fetch` 并发请求并按完成顺序收结果

---

## 8. Rust 调 JS（插件导出函数）

现在支持“插件 bundle 导出对象 + Rust 按函数名调用”的模式，不再要求插件把函数挂到 `globalThis`。

推荐插件产物（CJS bundle）导出一个对象：

```js
module.exports = {
  async getInfo() {
    return {
      name: "image-tools",
      version: "1.2.3",
      apiVersion: 1,
      description: "示例插件"
    };
  },
  async run(input) {
    return { ok: true, input };
  }
};
```

Rust 侧用法：

```rust
use rquickjs::{Context, Runtime};
use rquickjs_playground::web_runtime::{WebRuntimeOptions, polyfill_script};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let runtime = Runtime::new()?;
    let context = Context::full(&runtime)?;
    let script = polyfill_script(WebRuntimeOptions::default());

    context.with(|ctx| {
        ctx.eval::<(), _>(script.as_str())?;
        Ok::<(), anyhow::Error>(())
    })?;

    Ok(())
}
```

备注：当前推荐统一走 `bridge.call(...)` + 动态路由注册，避免额外插件模型。

---

## 9. TS 侧统一运行时 API（避免重复 `globalThis as ...`）

新增了 `pnpm_demo/src/runtime-api.ts`，提供统一类型化入口，插件代码可以直接 import 使用。

示例：

```ts
import { requireApi, requireCryptoLike, runtime } from "../src/runtime-api";

const crypto = requireCryptoLike();
const sign = crypto.createHmac("sha256", "key").update("text").digest("hex");

const native = requireApi("native");
const out = await native.chain(["invert"], new Uint8Array([1, 2, 3]));

const id = runtime.uuidv4();
```

可用能力包括（按需读取）：

- Web API：`fetch`、`Request`、`Response`、`Headers`、`FormData`、`Blob`、`URL` 等
- Host API：`fs`、`native`、`wasi`、`bridge`
- Runtime API：`crypto/nodeCryptoCompat`、`uuidv4`、`Buffer`、`TextEncoder/TextDecoder`

并且提供了 `getApi(name)`（可选）与 `requireApi(name)`（缺失直接抛错）两套调用方式。

补充：如需缓存与配置存取，建议在调用方通过动态 bridge 路由自行实现并包装（例如注册 `cache.get/cache.set`、`plugin_config.load/save` 等自定义方法）。

Rust 侧（宿主）动态注册示例：

```rust
use rquickjs_playground::register_bridge_route_async_handler;
use serde_json::{json, Value};

register_bridge_route_async_handler("cache.get", |_runtime, args| async move {
    let key = args
        .first()
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow::anyhow!("missing key"))?;
    let val = my_cache_get(key).await;
    Ok(json!(val))
})?;

register_bridge_route_async_handler("cache.set", |_runtime, args| async move {
    let key = args
        .first()
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow::anyhow!("missing key"))?;
    let value = args.get(1).cloned().unwrap_or(Value::Null);
    my_cache_set(key, value).await?;
    Ok(json!(true))
})?;
```

JS 侧包装成旧调用习惯示例：

```ts
export const cache = {
  get: (key: string, fallback: unknown = null) =>
    bridge.call("cache.get", key).then((v) => (v ?? fallback)),
  set: (key: string, value: unknown) => bridge.call("cache.set", key, value),
};

export const pluginConfig = {
  load: (key: string, def = "") =>
    bridge.call("plugin_config.load_plugin_config", key, def),
  save: (key: string, value: string) =>
    bridge.call("plugin_config.save_plugin_config", key, value),
};
```
