# rquickjs_playground fetch WPT 兼容性测试报告

> 测试时间：2026-07-13
> 运行方式：`cargo test --test wpt_fetch -- --nocapture`
> 测试范围：WPT `fetch/` 目录下无需远程服务器、可在纯 JS 运行环境中执行的 `.any.js` 用例

## 1. 总体结果

| 指标 | rquickjs_playground | Node.js v24.18.0（同条件对照） |
|------|---------------------|--------------------------------|
| 测试文件数 | 37 | 37 |
| 断言总数 | 629 | 605 |
| 通过 | 541 | 253 |
| 失败 | 88 | 352 |
| Harness 错误 | 0 | 1 |
| **通过率** | **86.0%** | **41.8%** |

> 注：Node.js 在现代版本（18+）中已经内置了 `fetch`、`Headers`、`Request`、`Response`、`FormData`、`Blob`、`ReadableStream`、`AbortController` 等 Web API，底层实现为 `undici`。同条件对照同样没有 WPT HTTP 服务器、没有真实 `location`、使用相同的 Shell 环境 mock，因此仍受浏览器专属用例拖累。

## 2. 运行环境说明

- 使用 `AsyncHostRuntime` 加载 WPT `testharness.js` 与目标 `.any.js`。
- 通过自定义 `testharnessreport.js` 收集 `add_result_callback` / `add_completion_callback` 结果。
- 由于 rquickjs 默认以严格模式执行脚本，对 WPT 中 `for (x of y)` 这类隐式全局循环变量做了 `var` 预声明注入。
- 未提供 `XMLHttpRequest`、`ReadableStream` 等浏览器全局对象；未启动 WPT HTTP 服务器，因此依赖真实 HTTP 响应或 XHR 的用例会失败。
- 为纯 client-side 用例注入了一个最小化的 `location` 对象，使构造 URL 的测试（如 bad-port）可以运行。

## 3. 完全通过的文件

| 文件 | 通过/失败 |
|------|-----------|
| `fetch/api/basic/header-value-null-byte.any.js` | 1/0 |
| `fetch/api/basic/historical.any.js` | 3/0 |
| `fetch/api/basic/request-head.any.js` | 1/0 |
| `fetch/api/body/formdata.any.js` | 3/0 |
| `fetch/api/body/mime-type.any.js` | 20/0 |
| `fetch/api/headers/headers-basic.any.js` | 23/0 |
| `fetch/api/headers/headers-casing.any.js` | 4/0 |
| `fetch/api/headers/headers-combine.any.js` | 6/0 |
| `fetch/api/headers/headers-errors.any.js` | 18/0 |
| `fetch/api/headers/headers-forbidden-override.any.js` | 90/0 |
| `fetch/api/headers/headers-normalize.any.js` | 3/0 |
| `fetch/api/headers/headers-record.any.js` | 13/0 |
| `fetch/api/headers/headers-structure.any.js` | 8/0 |
| `fetch/api/headers/header-setcookie.any.js` | 24/0 |
| `fetch/api/abort/request.any.js` | 18/0 |
| `fetch/api/request/forbidden-method.any.js` | 6/0 |
| `fetch/api/request/request-bad-port.any.js` | 83/0 |
| `fetch/api/request/request-constructor-init-body-override.any.js` | 2/0 |
| `fetch/api/request/request-consume-empty.any.js` | 14/0 |
| `fetch/api/request/request-headers.any.js` | 61/0 |
| `fetch/api/request/request-init-002.any.js` | 8/0 |
| `fetch/api/request/request-structure.any.js` | 24/0 |
| `fetch/api/response/response-consume-empty.any.js` | 14/0 |
| `fetch/api/response/response-error.any.js` | 10/0 |
| `fetch/api/response/response-init-001.any.js` | 9/0 |
| `fetch/api/response/response-static-error.any.js` | 2/0 |
| `fetch/api/response/response-static-json.any.js` | 16/0 |
| `fetch/api/response/response-static-redirect.any.js` | 11/0 |

## 4. 主要改进点

### 4.1 Body 消费与 Abort

- `fetch()` 现在会同步锁定 Request body，使 `bodyUsed` 在请求发起时立即变为 `true`。
- 被 `fetch` 消费过的 Request 再次调用 `text()`/`json()`/`arrayBuffer()`/`blob()`/`formData()` 会按规范 reject。
- `abort/request.any.js` 达到 18/0。
- 空 body（空字符串、空 `Blob`、空 `ArrayBuffer`、空 `FormData`）的消费已完善。

### 4.2 Headers guard 与 no-cors

- 补齐了 `x-http-method-override` / `x-http-method` / `x-method-override` 的禁用方法值校验（支持逗号分隔 token）。
- 修正了 `request-no-cors` guard：
  - `content-type` 现在按 MIME 类型（忽略参数）判断是否 safelisted。
  - `accept` / `accept-language` / `content-language` / `content-type` 在 no-cors 模式下遵守组合值长度不超过 128 的限制。
- `headers-forbidden-override.any.js` 达到 90/0。
- `headers-no-cors.any.js` 静态用例全部通过。
- `request-headers.any.js` 达到 61/0。

### 4.3 Request 构造器与 URL 校验

- `RequestInit.priority` 现在会校验取值范围，非法值抛出 `TypeError`；同时不在 Request 实例上暴露 `priority` 属性。
- 支持 `new Request(url, existingRequest)` 这种把 Request 作为 init 的用法。
- 实现了 bad port 快速拒绝，`request-bad-port.any.js` 达到 83/0。

### 4.4 MIME 类型与 Content-Type

- `Request`/`Response` 对 `Blob`、`FormData`、`URLSearchParams`、字符串等 body 类型的默认 Content-Type 处理已补齐。
- `mime-type.any.js` 达到 20/0。
- `formData()` 现在可以从 body 中推断 boundary，修复大小写不敏感的 multipart 解析。

## 5. 主要失败类别（按 `analyze_wpt_delta.py` 归类）

| 类别 | Rust 失败数 | Node 失败数 | 说明 |
|------|-------------|-------------|------|
| 浏览器全局对象缺失 / 需要服务器 | 81 | 154 | `XMLHttpRequest`、`ReadableStream`、相对 URL、真实 HTTP 响应 |
| Headers 校验/规范化/合并/guard | 0 | 151 | 已补齐 |
| body 消费方法 | 0 | 33 | 已补齐 |
| Request/Response body MIME 类型与 Content-Type | 4 | 8 | 仅剩 `ReadableStream` body 用例 |
| Request 属性/结构不符合规范 | 0 | 6 | 已补齐 |
| Response 静态方法与初始化校验 | 0 | 0 | 已补齐 |

## 6. 与 Node.js 对照说明

在同样的 37 个 client-side 用例、同样的无服务器环境下，rquickjs_playground 通过率为 **86.0%**，超过 Node.js v24.18.0 的 **41.8%**。差距主要来自：

- Headers 校验与 guard 实现更完整（Node 在此类失败 151 个，Rust 已清零）。
- 已补齐 `Response` 静态方法、`formData()`、默认 Content-Type、abort 后 body 行为等 Node/undici 在此子集中也失败的短板。
- 浏览器专属全局对象（XHR、ReadableStream）与需要真实 HTTP 服务器的用例仍是共同短板。

详细差距分析见 [`WPT_FETCH_DELTA.md`](./WPT_FETCH_DELTA.md)。
