# fetch 设计文档（v1）

> 状态：实现完成（2026-08-07），wpt 精选子集 30/30 文件全过（510 pass / 0 fail / 9 expected）
> 进度台账：`docs/fetch_milestone_progress.md`；已知问题：`docs/known_issues.md` KI-050~055
> **v3 迁移（2026-08-08）**：fetch 核心已解耦为独立纯 C++ 库 `fetchcore`
> （`include/fetch/` + `src/fetch/`，namespace `fetch`；`fetch::Client` 从当前线程
> thread_local 取 io_context（`fetch::set_thread_io`），
> redirect/SRI/data:/中间件链全部下沉；绑定层 `install_web_apis(ctx, fetch::Client&)` 变薄，
> 中间件注册入口只有 `fetch::Client::use()`，不向 JS 暴露）。
> 本文件 v1 分层图为迁移前结构，作历史参照；v3 目标架构见 `docs/fetch_cpp_decoupling.md` §3。

## 1. 架构总览

```
JS (quickjs-ng) ── qjsbind 绑定层 ── qjsbind::web（header-only）
                                        │
                                        ▼
                              FetchBackend 抽象接口（net.hpp）
                                        │
                                        ▼
                        qjsbind_net 静态库（boost::beast + OpenSSL）
                        src/net/http_client.{hpp,cpp} + http_backend.hpp
```

- web 层（`include/qjsbind/web/`）不依赖具体网络实现——`install_web_apis(ctx, backend)` 注入 `FetchBackend`
- 异步：所有耗时路径（fetch、Request/Response 消费）走 `exec::task` 协程 + asio io_context（绑定在 Runtime 的 io 上），经 `promise_from_sender` 转 JS Promise
- 取消：`AbortSignal`（`std::stop_source`）→ `socket.cancel()` → asio 以 `operation_aborted` 完成 → `set_stopped` → Promise reject AbortError

## 2. 已实现 API（v1 边界）

| 类 | 成员 | 备注 |
|---|---|---|
| fetch | `fetch(input, init)` | redirect follow≤20/error/manual；响应 type="basic"；参照 Node(undici)：用户自定义头（referer/cookie/origin 等）正常发送，仅 host/content-length 由运行时管理；blocked port |
| Headers | 构造（record/序列/实例/undefined/null→TypeError）、append/set/delete/get/has/forEach/entries/keys/values/getSetCookie、Symbol.iterator | guard：none/request/request-no-cors/response/immutable；参照 Node：guard=request 不检查 forbidden（referer/cookie 等可存可取）；immutable 抛；同名多值存储（set-cookie 语义）；迭代 sort+combine；活迭代器（迭代中增删反映，读内部 list） |
| Request | method/url/headers/redirect/signal/body/bodyUsed、clone、text/json/arrayBuffer/formData | body：string/ArrayBuffer/TypedArray/DataView/URLSearchParams/Blob/File/FormData/Request/Response 实例、其他值 ToString；method 规范化；GET/HEAD 禁 body；integrity：sha256/384/512 校验；blob() 未实现 |
| Response | status/statusText/type/url/redirected/ok/headers/body/bodyUsed、text/json/arrayBuffer/formData、clone、error()、redirect() | 204/205/304 无 body（带 body 抛 TypeError）；status 非法 RangeError；statusText ByteString 检查；error() 的 headers guard=immutable；formData() 走 multipart 解析；blob() 未实现 |
| URL | 各属性、searchParams、toString/href、静态 parse 未实现 | boost::urls；相对解析带 base；宽松解析（非 ASCII/`|`/裸 `%` → WHATWG 编码重试）；UTF-16 转换（孤立代理→U+FFFD）；searchParams 双向联动（SameObject 缓存 + 回写） |
| URLSearchParams | 构造/增删查改/sort/entries/keys/values/Symbol.iterator | 双向联动：owner URL 回写（append/delete/set/sort） |
| Blob/File | 构造（parts/type/lastModified）、size/type/name、slice、text/arrayBuffer | Blob 惰性拼接；File 继承 Blob（name/lastModified） |
| FormData | 构造（form/record/无参）、append/delete/get/getAll/has/set、entries/keys/values/Symbol.iterator | 迭代返回数组（非规范迭代器对象）；boundary 随机生成；数据模型与 multipart 编解码在 fetchcore（include/fetch/formdata.hpp），绑定层仅 JS 绑定 |
| AbortController/Signal | abort()/signal/aborted/onabort | 协程取消链路 |
| TextEncoder/Decoder | encode/decode、构造 options（fatal/ignoreBOM） | decode 默认剥离 UTF-8 BOM |
| 其他 | setTimeout/setInterval/clearTimeout/clearInterval、DOMException、Event/EventTarget | |

## 3. 关键实现决策

1. **异常出口统一**（`errors.hpp`）：`throw_type_error` / `throw_range_error` 用全局 TypeError/RangeError 构造器创建实例（保证 `instanceof` 正确），`[[noreturn]]` 单语句（不可能被控制流拆散——历史教训 KI-050）
2. **`js_error` 可拷贝**（`JS_DupValue` 深拷贝）：MSVC 协程异常传播对 move-only 异常类型损坏（KI-051）
3. **Headers 存储 = list of (lowercase name, value)**：同名多值（set-cookie 语义），get 合并；迭代 stable sort by name + 同名合并（set-cookie 例外）
4. **headers getter 缓存**（RtValue SameObject）：`r.headers` 每次返回同一 JS 对象；fetch 组装前 `sync_headers` 从 JS 对象同步回数据
5. **消费方法返回 Promise**：`text()/json()/arrayBuffer()` 为 `exec::task<qjs::Value>`（绑定层 sender→Promise）
6. **URL 字符串转换走 UTF-16**：`JS_ToCStringLenUTF16` + `utf16_to_utf8`（孤立代理 → U+FFFD），与 WHATWG 一致
7. **默认头**：Accept/Accept-Language 仅在用户未设置时生效；不设 Connection（wpt inspect-headers 语义）
8. **Symbol.iterator 等 JS 侧补丁**：vcpkg quickjs.h 无公共 atom/类常量；补丁字符串禁止 `//` 注释（无换行拼接，KI-053）

## 4. wpt 精选子集基础设施

- `scripts/analyze_wpt.py`：扫描 `third_party/wpt/fetch/api`（191 个测试入口），静态检查依赖（未实现 JS API / 服务器端点 / `.sub` / `.https` / 目录语义）→ skip + 原因，生成 `build/wpt_manifest.json` + `build/wpt_tests.txt`
- `tests/wpt_runner.cpp`：每文件独立 Runtime；eval shim → 注入 location → meta scripts → 主体（anyjs 直接 eval / html 提取内嵌 script）→ `run_to_completion` → 读 `__wpt_summary()`
- `tests/wpt_shim.js`：testharness 兼容层（test/promise_test/async_test/assert_*/promise_rejects_js/add_cleanup/setup/done + expected-fail 登记表）
- `tests/wpt_server.hpp`：beast mini 服务器（status/redirect/inspect-headers/method/echo 端点 + `.asis` 原样响应 + 静态文件 + 5s 超时防挂）

运行：
```bash
python scripts/analyze_wpt.py
cd build && ./quickjs_runtime_tests.exe --gtest_filter="WptRunner.*"
```

## 5. 已知限制（v1，28 个 expected + 清单 skip）

- **裸 `%`**：query 中 WHATWG 保留裸 `%`，boost 严格语法无法表示（1 个 expected）
- **`blob()`**：Request/Response 的 blob() 未实现（4 个 expected；body 消费仅 text/json/arrayBuffer/formData）
- **forbidden 请求头**：参照 Node(undici) 而非浏览器——referer/cookie/origin 等用户自定义头正常发送（22 个 expected；wpt 按浏览器语义期望不发送）
- 清单级 skip：`.sub` 模板、`.https`、worker、credentials/cors/policies 目录、ReadableStream/MediaSource 等未实现 API、Request cache/keepalive/priority 等未实现字段、beast 严格解析拒绝的重复 content-length/控制字符头值（header-value-combining）
- **未实现**：Request/Response 的 body 流（ReadableStream）、blob()、CORS 与跨域、credentials/cookie、cache/keepalive、URL 静态 parse
