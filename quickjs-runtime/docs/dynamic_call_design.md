# 动态调用设计文档（v1）

> 状态：已实现（2026-08；实现见 `include/qjsbind/dynamic_call.hpp`，测试见 `tests/dynamic_call_test.cpp`）。
> 目标：JS 侧通过「函数名 + 任意个可 JSON 序列化的参数」动态调用 C++ 侧注册的函数；host_id 不由 JS 传，由 C++ thunk 自动填入。
> 相关文档：`qjs_cpp_binding_design.md`（绑定层总设计）、`docs/cpp26_executor_model_usage.md`（异步模型）。
> 参考锚点：`include/qjsbind/context.hpp`（Runtime 与 id）、`include/qjsbind/function.hpp:319`（task → Promise）、`include/fetch/easy.hpp:267`（glaze 用法先例）。

## 0. 目标与非目标

目标：

- JS 侧两个全局函数：`call`（默认，异步，返回 Promise）和 `callSync`（同步）。
- JS 调用形式：`call(name, ...args)`，参数个数不限，但必须全部可 JSON 序列化。**不传 hostid**——thunk 自动使用安装时所在 Runtime 的 id。
- C++ 侧一个**全局注册中心**：内含全局注册表（同步、异步各一张）+ 每个 host 自己的注册表（同步、异步各一张）。
- C++ handler 统一签名：输入 `(host_id, name, json_args)` 三个参数（host_id 由 thunk 注入，handler 借此知道调用来源），JSON 字符串进出；解析用 glaze。
- 纯头文件实现，一个 `install_dynamic_call(ctx)` 完成接入，风格对齐现有 `install_*` 系列。

非目标：

- 不传 JS 对象引用（JSValue、函数、Promise 等）——只走 JSON 值语义。
- 不做二进制/零拷贝传输（有需求走 channel，见 `include/dart_cpp_bridge/channel.hpp`）。
- JS 侧**不能**寻址其他 host：调用只能命中自己 host 的表 + 全局表。这是硬性隔离边界，不提供任何跨 host 调用入口。

## 1. 总体架构

```
┌─ JS（某个 host 的 JS 线程）──────────────────────────────┐
│  call(name, ...args)     → Promise                       │
│  callSync(name, ...args) → 值                            │
└──────────────┬───────────────────────────────────────────┘
               │ thunk（include/qjsbind/dynamic_call.hpp）
               │  0. host_id = 安装时捕获的本 Runtime id    （JS 不传）
               │  1. JS_JSONStringify(args) → "[a,b,c]"    （不可序列化 → TypeError）
               │  2. 查注册中心（本 host 表 → 全局表），拷贝出 handler
               │  3. handler(host_id, name, json) → json_result
               │  4. JS_JSONParse(json_result) → JS 值     （异步版在 JS 线程做）
               ▼
┌─ dyn::Registry（进程级单例，shared_mutex 保护）──────────┐
│  global_sync : unordered_map<string, SyncHandler>        │
│  global_async: unordered_map<string, AsyncHandler>       │
│  hosts       : unordered_map<string /*host_id*/,         │
│                              HostTable>                  │
│    HostTable { sync_map; async_map; }                    │
└───────────────────────────────────────────────────────────┘
```

「host」= 一个 `qjs::Runtime`（一条 JS 线程 + 一个主 context + 一个事件循环），host_id 复用现成的 `Runtime::id()`（`context.hpp:185`，默认 UUID v4，构造时可指定）。注册中心是进程级单例：全局表被所有 host 共享；host 表按 id 隔离——`install_dynamic_call(ctx)` 把本 Runtime 的 id 捕获进 thunk 闭包，JS 每次调用自动带上，因此不同 host 的同名函数互不干扰，而 handler 仍能从第一个参数得知调用来自哪个 host。

## 2. JS API

```js
// 异步版（默认，推荐）：返回 Promise
const r1 = await call("add", 1, 2);

// 同步版：直接返回值，阻塞当前 JS 线程直到 handler 返回
const r2 = callSync("add", 1, 2);

// 查全局表无需任何特殊写法：本 host 表找不到会自动回落到全局表
const r3 = await call("version");
```

约定：

- `args` 整体被序列化为一个 **JSON 数组**字符串（`[arg0, arg1, ...]`）传给 handler。
- 参数必须可 JSON 序列化；函数、Symbol、循环引用会在序列化时抛 `TypeError`——这是天然入参校验，不需要额外代码。
  - 实现偏差说明：QuickJS 的 `JS_JSONStringify` 按标准 JSON 语义，**数组/对象内**的函数与 Symbol 会转为 `null` 而非抛错；真正抛 `TypeError` 的是循环引用。实现不做额外拦截（thunk 直接透传 `JS_JSONStringify` 的异常），测试以循环引用覆盖「不可序列化」路径。
- 返回值是 handler 返回的 JSON 字符串解析后的 JS 值；handler 返回 `"null"` 即 JS 的 `null`。

## 3. C++ 注册 API

全部声明集中在新头文件 `include/qjsbind/dynamic_call.hpp`，namespace `qjs::dyn`。

### 3.1 Handler 签名

```cpp
// 同步 handler：JSON 进，JSON 出。在调用方 JS 线程上内联执行。
// 抛 C++ 异常 → JS 侧 throw。
using SyncHandler = std::function<std::string(
    std::string_view host_id, std::string_view name, std::string_view json_args)>;

// 异步 handler：惰性 task，由调用方 Runtime 的 scope spawn，
// Promise 经 promise_from_sender 的 continues_on 回到 JS 线程后 resolve。
// co_await 中抛异常 → Promise reject。
using AsyncHandler = std::function<std_exec::task<std::string>(
    std::string host_id, std::string name, std::string json_args)>;
```

- `host_id`：由 thunk 自动填入（调用方 Runtime 的 id），handler 可据此区分调用来源或做按 host 的统计/路由。
- `name`：原样透传是按需求的明确设计——允许一个 handler 服务多个名字（自己内部路由）。

### 3.2 注册 / 注销

```cpp
// 全局表（所有 host 可见）
void register_global(std::string name, SyncHandler fn);
void register_global_async(std::string name, AsyncHandler fn);
void unregister_global(std::string_view name);            // 两张全局表都尝试删

// host 表（只有该 host 自己的 JS 调用能命中；host 表优先于全局表）
void register_host(std::string_view host_id, std::string name, SyncHandler fn);
void register_host_async(std::string_view host_id, std::string name, AsyncHandler fn);
void unregister_host(std::string_view host_id, std::string_view name);

// host 表生命周期（§6）
void remove_host(std::string_view host_id);               // 整表删除
```

重复注册同名：直接覆盖（后注册生效），与 `unordered_map::insert_or_assign` 语义一致，简单可预期。

### 3.3 接入入口

```cpp
// 仿 install_timers/install_fetch：给该 Runtime 的主 context 装上
// call / callSync 两个全局函数，按 rt.id() 建好 host 表，
// 并把该 id 捕获进两个 thunk 的闭包（之后 JS 调用自动携带）。
void install_dynamic_call(qjs::Context& ctx);
```

## 4. 调用分发与查找顺序

```
sync 调用：  本 host 表.sync_map → 全局 global_sync → 找不到报错
async 调用： 本 host 表.async_map → 全局 global_async → 找不到报错
```

- **D1：host 表优先于全局表。** 允许某个 host 覆盖全局同名函数做定制。
- **D2（已移除）：async 不再回落到 sync handler。** `call` 只服务异步 handler（返回 Promise 即真异步），`callSync` 只服务同步 handler——互不回落：同步结果不走 Promise，异步入口不内联同步执行。`callSync` 命中异步函数仍直接报错（同步语义无法等待）。
- **D3：查表持读锁把 handler 拷贝出来，解锁后再调用。** handler 内部可能反过来注册/注销函数，持锁调用会死锁；拷贝 `std::function` 开销可忽略。
- 同名函数在 sync/async 两张表互不干扰（同名不同体是合法的）。

## 5. JSON 约定与分工

| 环节 | 机制 | 说明 |
|---|---|---|
| JS args → JSON 字符串 | `JS_JSONStringify`（QuickJS 原生） | thunk 里操作的是 JSValue，glaze 碰不到它 |
| JSON 字符串 → JS 返回值 | `JS_JSONParse`（QuickJS 原生） | 异步版必须在 JS 线程上 parse（`promise_from_sender` 已保证结算点在 JS 线程） |
| handler 内部解析 `json_args` | `glz::read_json<T>` | 项目已有先例（`include/fetch/easy.hpp:267`） |
| handler 内部生成返回值 | `glz::write_json(obj)` | 返回 `expected<string>`，错误时抛异常走统一错误模型 |

handler 侧典型写法（示意，非实现）：

```cpp
dyn::register_global("add", [](std::string_view, std::string_view, std::string_view args) -> std::string {
    auto v = glz::read_json<std::vector<double>>(args);        // 解析失败 → expected 带错
    if (!v) throw std::runtime_error(glz::format_error(v.error(), args));
    double s = std::accumulate(v->begin(), v->end(), 0.0);
    auto out = glz::write_json(s);
    return std::move(*out);
});
```

注意：glaze 只出现在 **handler 内部**和纯 C++ 层；绑定 thunk 层与 JSValue 打交道的地方一律用 QuickJS 原生 API，与 qjsbind 现有分层一致（绑定层不引 glaze）。

## 6. 线程模型与 host 表生命周期

线程不变量（必须写进文档头部注释）：

1. handler 是**纯 C++ 函数**：JSON 字符串进、JSON 字符串出，**不得触碰任何 JSValue / JSContext**。
2. **sync handler 跑在调用方的 JS 线程上**（内联调用）。重活不要注册 sync 版，会阻塞该 host 的事件循环——想跑重活就注册 async 版，在 task 里自己 `continues_on` 到线程池。
3. **async handler 的 task 由调用方 Runtime 的 `counting_scope` spawn**（复用 `Runtime::spawn`，`loop.hpp:26`），`run_to_completion()` 会等它结算；结算点经 `continues_on(rt.io_scheduler())` 回到调用方 JS 线程，parse JSON、resolve Promise 都在 JS 线程，安全。
4. 同一个全局 handler 可能被多个 host 的 JS 线程**并发**调用；handler 若访问共享状态，线程安全由注册方自理——注册中心只管查表时的锁。

生命周期：

- `install_dynamic_call(ctx)` 时按 `rt.id()` 建空 host 表（幂等，重复 install 不报错）。
- `Runtime` 析构时调用 `dyn::remove_host(id())` 整表移除，防止悬挂 host_id 残留。需要在 `context.hpp` 的析构（`:162-179`）里加一行——这是本设计对现有代码的唯一侵入点。
- 全局表不进 remove_host，进程级存活（静态注册的函数天然如此）。

## 7. 错误模型

| 场景 | sync | async |
|---|---|---|
| 函数名未注册 | throw `Error: dyn_call: '<name>' not found (host '<id>')` | Promise reject 同名 Error |
| JS 参数不可序列化 | `JS_JSONStringify` 返回异常 → TypeError | 同左（thunk 入口即失败，同步抛） |
| handler 抛 C++ 异常 | qjsbind thunk 出口统一捕获 → JS throw | `promise_from_sender` 的 `upon_error` → reject |
| handler 返回非法 JSON | `JS_JSONParse` 失败 → SyntaxError | 同左（reject） |
| `callSync` 命中异步函数 | throw（语义无法等待） | — |

thunk 出口全捕获是 qjsbind 已有行为（`function.hpp:363-404`），本设计不新增异常通道。

## 8. 文件落点

> 以下均已按此落地（2026-08）。

- 新增 `include/qjsbind/dynamic_call.hpp`：Registry 单例 + 注册/注销 API + 两个 thunk + `install_dynamic_call`。header-only，对齐 qjsbind 现有风格。
- 修改 `include/qjsbind/context.hpp`：析构加 `dyn::remove_host(id())` 一行（唯一侵入点）。
- 修改 `include/qjsbind/qjsbind.hpp`：include 新头文件（可选，想控制编译面也可以让使用者自己 include）。
- 新增 `tests/dynamic_call_test.cpp`：sync/async、host 表优先于全局表、两个 Runtime 的 host 表互相隔离且共享全局表、call 只认异步（未注册 async → reject not found）、未注册报错、不可序列化参数报错、host_id 自动注入正确。
- `src/main.cpp` 加 demo（可选）。

## 9. 已知限制

- 参数走 JSON 文本，大对象/高频调用有序列化开销；二进制数据请走 blob store（`docs/blob_store_design.md`，JSON 里传 id）或 channel。
- 只支持值语义：JS 侧的函数、类实例、Promise 传不过去（序列化即报错）。
- sync handler 阻塞调用方 JS 线程，滥用会卡事件循环。
- 无重载：同名后注册覆盖先注册。

## 10. 后续可选增强（本期不做）

- `register_typed<R(A...)>` 模板糖：注册普通 C++ 函数，自动 glaze 编解码，免手写 JSON。
- 调用统计 / tracing hook（Registry 里留一个 before/after 回调位）。
- `call` 支持 `AbortSignal`（异步版把 stop token 透进 task，机制现成，见 `promise.hpp`）。
