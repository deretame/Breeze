# 运行时管理与初始化 API 设计

> 状态：骨架已实现。代码：`include/qjsbind/host_runtime.hpp`（`qjs::HostRuntime`）、
> `include/qjsbind/polyfill/bundle_dispatcher.js`（JS 侧分发器）+
> `bundle_dispatcher.hpp`（安装入口）；测试 `tests/host_runtime_test.cpp`
> （套件 `HostRuntimeTest`）。本文档是设计依据，实现以其为准。
>
> 背景：`docs/rquickjs_playground_gap_analysis.md` 指出本项目缺少
> rquickjs_playground 那样的"运行时管理 + bundle 插件"能力。
> 本文档记录该能力在**本项目中的设计决策**——不照搬参考实现，
> 只借鉴其功能边界，API 形态按本项目情况重新设计。

## 一、参考实现的问题：返回类型分裂

rquickjs_playground（`src/host_runtime.rs`）的任务/调用 API 存在
**两种请求、三种返回**的分裂设计：

- 句柄分裂：
  - `RuntimeTaskHandle::wait() -> Result<String, String>`（原始 JSON 字符串）
  - `RuntimeJsonTaskHandle<T>::wait() -> Result<T, String>`（模板反序列化）
  - `RuntimeTaskHandle::wait_bytes() -> Result<Vec<u8>, String>`
    （按 JSON payload 内容猜测解码：nativeBufferId / 字节数组 / base64 字符串，
    见 `bytes_from_value`）
- API 因返回类型不同而成倍膨胀：
  `spawn / spawn_json`、`bundle_call / bundle_call_bytes`、
  `bundle_call_once / bundle_call_once_bytes`（外加 `_start` 变体）。

问题本质：**"数据是什么"的决策被烧进了 API 签名**。
传输层其实永远只搬一种东西（序列化后的字符串），
text / JSON / 二进制只是调用方对同一份数据的不同解释。
分裂出的 `_bytes` 变体还要靠 `bytes_from_value` 对 payload
做三种格式的猜测解码，脆且隐晦。

## 二、本项目的设计决策：单一返回类型

**所有任务/调用类 API 统一返回 `std::string`，不带任何类型标签。**
内容的解释权完全在调用方（调用方自己清楚这次调用要的是什么数据）：

- 当文本/JSON 用：直接用、自己解析；
- 当二进制用：就是字节串，直接 `data()` / `size()`。

序列化协议（JS 返回值 → `std::string` 的规则）：

- **纯二进制**（返回值本身是 `ArrayBuffer` / `TypedArray` / `DataView`）：
  字节原样塞进 `std::string`，不过 JSON、不加 base64；
- **其他一切值**（含混合结构）：`JSON.stringify`，
  其中嵌套的二进制字段编码为 base64 字符串进入 JSON。

推论：

- **句柄只有一种**：`task_handle`，`wait()` 返回
  `stdexec::task<runtime_result>`（异步结算，`co_await` 获取结果；
  见第五节错误通道），不存在 `wait_json<T>` / `wait_bytes` 变体。
- **API 不分裂**：`bundle_call` 就是 `bundle_call`，没有 `_bytes` 后缀版本。
  "这次调用返回的是文本还是字节"是调用方与插件之间的协议，
  不占用运行时 API 的维度。
- 运行时层不做 `bytes_from_value` 式的格式猜测：
  顶层值按 JS 类型分流（类型是显式信息），嵌套值统一 base64，没有内容嗅探。

入参方向的二进制（host 往 JS 传字节）见 §三（native buffer 通道）。

## 三、native buffer 通道（已实现）

> 本节为差距清单第 6 项的落地。实现复用现有 `qjs::dyn::BlobStore`
> （进程级单例、按桶隔离、TTL + sweeper、线程安全），不新造池子。

- **桶命名**：`hbuf:<instance id>`，刻意不用 Runtime id——reload 先建后拆时
  旧 Runtime 的析构钩子按 rt.id 整桶回收，独立桶名使 buffer 跨 reload 存活；
  `stop(id)` 时由 HostRuntime 显式回收整桶。
- **host → JS（入参）**：`rt.put_buffer(id, bytes) -> expected<buffer_id>`；
  调用方在 args JSON 任意深度嵌 `{"$buf": "<id>"}` 占位；dispatcher 的
  `materializeArgs` 在调用前递归替换为 `Uint8Array`。**消费语义**
  （take = get + remove，BlobStore 新增 `remove` 单条 API）；
  id 不存在/过期 → `invalid_args`。
- **JS → host（返回）**：序列化协议升级——顶层纯二进制不再走 base64，
  JS 侧 `__native_buf_put` 入池，settle 负载为 `"\x00buf:" + id`；
  `wait()` 按 id 取件（消费）交付原始字节。嵌套二进制仍编码进 JSON
  （`{"$type":"bytes","base64":...}`，调用方协议）。
- **副本开销**：入池/出池各一次内存拷贝（JS 堆与 BlobStore 互不拥有），
  无 base64 的 +33% 体积与编解码 CPU；条目闲置由 BlobStore TTL 回收
  （默认 15min），句柄被丢弃不等待的场景不会泄漏。

## 四、统一后的 API 形态

初始化与生命周期：

```cpp
// 构建即初始化：builder 收集选项，build 失败返回错误，不存在半初始化态
auto rt = runtime_builder{}
    .cache_scope_id("...")
    // ...其他选项
    .build();   // -> expected<host_runtime, runtime_error>
```

任务与 bundle 调用（注意返回类型完全一致；以下为已实现的真实签名，
`qjs::HostRuntime`）：

```cpp
// bundle 生命周期
rt.init(id, source);                  // -> expected<void, runtime_error>
rt.call(id, fn_path, args_json);      // -> expected<task_handle, runtime_error>
rt.call(id, fn_path, args_json, src); // debug：先热重载再执行（hash 未变跳过）
rt.reload(id, source);                // -> expected<op_receipt, runtime_error>（原子替换）
rt.stop(id);                          // -> expected<void, runtime_error>
rt.list();                            // -> std::vector<std::string>

// 唯一的等待方式：异步结算（stdexec::task，co_await 获取结果，不阻塞线程）；
// 拿到的是序列化后的字符串（二进制已解码为原始字节）
runtime_result raw = co_await h->wait();
```

参数约定（args_json）：JSON 文本整体 `JSON.parse` 后作为**唯一参数**传给目标
函数——命名参数风格 `{"a":1,"b":2}` → `fn({a:1,b:2})`（bundle 函数用对象解构
接收）；不做数组展开。二进制参数先 `rt.put_buffer(id, bytes)` 得 buffer id，
在 JSON 任意深度嵌 `{"$buf":"<id>"}` 占位，调用前物化为 `Uint8Array`。
运行时另追加 `AbortSignal` 为第二参数（`rt.cancel` 时触发，函数可忽略）。

管理面：

```cpp
rt.cancel(id, task_id);               // -> bool（或 cancel(handle)）
rt.stats();                           // -> host_stats（每实例计数快照）
rt.run_gc(id);                        // -> expected<op_receipt, runtime_error>（任务间隙 JS_RunGC）
```

内建 fetch（可选）：`HostRuntime::Options{.enable_fetch = true, .fetch_opts = ...}`
让每个实例自动装配全套 Web API（fetch/URL/Headers/timers/blob/stream…）。
Client 的生命周期是三连约束——**实例线程构造**（io 取自构造线程
thread_local）、**实例线程析构**（连接池/DNS 缓存有 io 线程断言）、
**先于实例 Runtime 销毁**（池内 socket 绑定实例 io）——手工管理极易踩坑，
内建选项把它收编：init 时在实例线程建 Client，reload 随旧 Runtime 回收
重建，stop 时在实例线程、Runtime 销毁前拆除；`register_all` 在 Web API
之后执行，可覆盖/补充。

与参考实现的对照：

| 参考（rquickjs_playground） | 本项目 |
|---|---|
| `spawn` / `spawn_json<T>` | 只有 `spawn`，返回 `task_handle` |
| `wait()` / `wait_bytes()` / `RuntimeJsonTaskHandle<T>` | 只有 `wait()`（异步 task，`co_await` 得 `std::string`） |
| `bundle_call` / `bundle_call_bytes` | 只有 `bundle_call` |
| `bytes_from_value` 三格式猜测解码 | 无；格式是调用方协议 |

## 五、生命周期协议与 debug 模式

运行时对调用方暴露的是一条五消息的生命周期：

1. **init**：调用方发送 `id + bundle`，运行时完成初始化，返回初始化结果；
2. **call**：调用方发送 `id + 调用参数`，运行时返回任务句柄。**入队即启动**
   （eager），无 start 步骤；期间可 `cancel`，结果经句柄 `co_await wait()`
   异步获取；
3. **reload**：调用方发送 `id + 新 bundle`，原子替换该 id 的代码（见下文）；
4. **结果结算**：任务完成后返回 `std::string`（见第二节，text / JSON / 二进制的
   解释权在调用方）；
5. **stop**：调用方发送停止，运行时回收对应实例。

### 升级替换：独立的 reload 消息

长期运行的运行时不会频繁切换 bundle，但**升级替换是一等需求**，不能用
"先 unload / stop 再 init"凑合——那会在窗口期内让 call 全部
`bundle_not_found`，且实例状态丢失。

`reload(id, bundle)` 的语义：

- **原子替换**：编译验证通过才切换；失败则旧 bundle 继续服役，返回
  `compile_failed`——升级失败不伤线上；
- **结算形态**：异步提交、一次性结算，直接返回可等待的
  `expected<void, runtime_error>`，**不返回任务句柄、不可取消**。
  reload 的全部工作是编译 + 切换：编译在运行时线程上同步完成、
  毫秒级、不可中断，为它配 start/cancel 是白送复杂度；
- **顺序保证**：reload 与 call 排在同一命令队列上，提交顺序即执行顺序——
  先 reload 后 call，该 call 一定跑在新代码上，无需额外同步原语；
- **无窗口期**：reload 是屏障命令——等在飞任务全部结算（跑完旧代码）后才
  切换，之后的新任务用新代码，不存在 `bundle_not_found` 中间态；
- **状态**：替换后模块级状态重置（新实例）。状态迁移（升级前
  `export_state`、升级后恢复）是插件层面的协议，运行时不管也不挡。

reload 与 debug 的"call 带 bundle"**共用同一个先建后拆机制**，
区别只在触发方式：reload 显式触发，debug 随调用触发。

### debug 模式：不新开 API，bundle 作为 call 的可选字段

debug 链路与正常链路的唯一区别是：**call 时连同整个 bundle 一起发送**。
设计上不为此单开调试接口，而是让 bundle 成为 call 消息的可选字段：

```
call(id, args)          → 普通调用
call(id, args, bundle)  → debug 调用 = 先热重载，再执行
```

语义：**携带 bundle 的 call = 先对该 id 做热重载，再执行调用**。

- 复用 TaskPool 已有的"编译验证后先建后拆"热重载：新 bundle 编译失败 →
  旧代码保留，返回编译错误；编译成功 → 原子切换后执行。
- 注册表语义单一：**id 永远指向最近一次编译成功的代码**，不存在
  "普通调用跑旧代码、debug 调用跑新代码"的双轨（对照参考实现的
  `bundle_call_once` 一次性脚本方案，那条路执行路径分叉、状态不连续，不采用）。
- 时序天然安全：debug call 是屏障命令——等在飞任务全部结算后才热重载，
  不会改到正在运行的代码，无需锁或版本栅栏。
- **debug 强制串行**：debug 任务执行期间，后续普通 call 在队列中等待，
  debug 任务结算后才恢复并发。debug 池的任务往往单个就要跑几秒、
  且需要随时取消，串行 + 轮询比几十路并发同时挂着好管理得多。
- 协议形状不变：仍是 init / call / reload / cancel / stop 五种消息，
  debug 对调用方只是"每次 call 带上最新源码"，无新概念。

### 实例内并发模型：IO 并发 + 屏障命令

普通 call 在实例内是 **IO 并发**的：实例线程的事件循环常转
（work_guard 保活，阻塞在 `run_one`，命令入队随 noop post 唤醒），
任务 begin 后不等待结算、立即取下一条命令——几百个 fetch/定时器任务
在同一 Runtime 的 io 上交替推进，不需要几百个实例。这不是 CPU 并行
（QuickJS Runtime 单线程），纯 CPU 任务仍会互相挤占。

三类命令是**屏障命令**：debug call / reload / run_gc。屏障命令等在飞任务
全部结算后才执行（热重载/GC 必须无在飞）；其中 debug call 执行期间还会
拦住后续普通 call（串行语义，见上）。

调度状态机（实例内，host 锁保护）：

- `in_flight`：已开始未结算的 call 集合；结算经 TaskRunner 的
  `on_settle` 钩子回收（统计 completed/failed/cancelled + 清屏障标记）。
  任务登记走 `register_running`（登记即 Running，无 Queued 窗口），
  保证 cancel 恒走"post 闭包 + interrupt"，on_settle 恒在实例线程触发。
- `debug_active` / `debug_id`：debug 屏障标记。
- 永不结算的任务（never-resolving promise）会一直占在飞名额，挡住后续
  屏障命令；调用方应 `cancel` 它。`stop` 例外：io 排空后对剩余在飞任务
  以 `runtime_stopped` 强制结算，保证回收时间有界。

预留的后续项：

- ~~**带宽优化**：bundle 字段可带 content hash，hash 未变则跳过重载直接执行~~
  **已实现**：实例记录当前 bundle 的 FNV-1a；reload / debug call 携带的源码
  hash 未变（并全串确认）则跳过重载，模块状态保留，stats 计入
  `reloads_skipped`；
- **一次性调用**：若将来需要"不进注册表的临时执行"（REPL、探针式调试），
  再补 `call_once(source, fn, args)`，是纯加法，不影响本设计。

## 六、细部决策（已定）

### 5.1 架构定位：与 TaskPool 共用 bundle 语义（同一套约定）

实现形态：HostRuntime 与 TaskPool 都建在基础层 **TaskRunner** 之上，并共用
同一份 bundle 基础设施——`load_bundle_source`（CJS 包装 + 编译验证 +
`__bundle_set_exports` 登记）与 bundle dispatcher（trampoline 覆盖 /
fn_path 点路径解析 / 对象参数 / Node 风格错误 / source map / buffer 通道）。
**池脚本即 bundle**：同一份源码在 TaskPool（开发期文件监视热重载调试）和
HostRuntime（生产命名实例）里跑法完全一致，全项目只有一种参数约定
（argsJson 整体 parse 作为第一参数，signal 第二参数）。

拓扑差异（刻意保留）：TaskPool 是"一个 bundle 文件 × N worker"的多 Runtime
并行调试池，HostRuntime 是"N 个命名实例 × 每实例一 Runtime 的 IO 并发循环
（屏障命令串行）"；二者的先建后拆 reload 与 bundle 基础设施同源同构。

### 5.2 错误通道：`std::expected` + 枚举码结构体

成功值是 `std::string`（第二节），错误是带枚举码的结构体；
不用 `std::error_code` 的 category 机制（单一错误域，属于过度设计）：

```cpp
enum class runtime_errc {
    bundle_not_found,    // call/unload 了未 init 的 id
    bundle_exists,       // init 了重复的 id
    compile_failed,      // bundle 编译失败（debug 重载时旧代码保留）
    function_not_found,  // fn_path 解析不到导出函数
    invalid_args,        // 参数非法（不是合法 JSON / buffer id 失效等）
    task_cancelled,      // wait 时任务已被 cancel
    runtime_stopped,     // stop 之后的操作
    js_exception,        // 脚本执行抛异常
};

struct runtime_error {
    runtime_errc code;
    std::string message;  // 人类可读；js_exception/compile_failed 时带格式化 JS 栈
};

using runtime_result = std::expected<std::string, runtime_error>;
```

分工：**code 给程序分支**（是否重试、是否用户代码的锅），
**message 给人看**（日志、调试面板）；JS 栈配合 sourceURL 注入可定位到插件源码。

错误文本为 **Node 风格**（对齐 rquickjs_playground 的设计）：

- 内部线协议是结构化 JSON 载荷（`@@errj:` + `{c,n,m,s,g}`：程序码 / 错误名 /
  消息 / 栈 / 调用上下文），不再是裸字符串 sentinel；JS 侧由 dispatcher 的
  `errorPayload` 产出，C++ 侧 glaze 解析；
- 拼装规则：首行 `Name: message`，带 `[bundle:<名> fn:<路径> args:<参数>
  source:<文件>]` 上下文前缀；stack 首行已含消息则直接用 stack（Node 惯例）；
- `HostRuntime` 构造选项 `include_stack`（默认 true）：false 时错误文本只给
  带上下文的消息首行（面向终端用户的简洁错误）；
- fn_path 诊断为 Node 风格详细 TypeError：`missing segment` / `rootType` /
  `rootKeys` 预览 / `targetType` / `ownerKeys`，`__proto__` 等安全键段拒绝；
  导出表做 Node 风格 CJS 互操作（单层 `default` unwrap，非 object/function
  导出报 `TypeError: bundle must export object or function`）；调用经
  `fn.apply(owner, …)` 保持 this。

### 5.3 JS 返回值序列化协议

见第二节的规则：顶层纯二进制原样进 `std::string`，其余 `JSON.stringify`
（嵌套二进制 base64）。运行时保持哑管道，格式知识只属于调用双方。

### 5.4 bundle dispatcher（JS 侧）

JS 侧结构参考 rquickjs_playground 的 `BUNDLE_DISPATCHER_JS` 内嵌脚本：
模块注册表、`fn_path` 点路径解析、bundle 作用域隔离、错误栈增强
（`__bundle_scope`）、`sourceURL` 注入。具体移植与裁剪在实现阶段定，
落到 `include/qjsbind/polyfill/` 的既有"JS 源 + embed_js.py 生成头文件"模式。

### 5.5 遗留（实现阶段再定）

- dispatcher JS 的具体移植范围（参考实现约 200 行，哪些功能裁剪）；
- ~~content hash 跳过重载~~（已实现）、`call_once` 等预留项的启用时机。

## 七、source map 支持（已实现）

- **输入形式**：bundle 源码尾部的行内 source map
  `//# sourceMappingURL=data:application/json;base64,...`（仅 base64 行内形式），
  C++ 侧 `load_bundle` 提取（`fetch::base64_decode`）后随 `__bundle_set_exports`
  传入 dispatcher；无 map 时栈原样透传。
- **映射库**：`@jridgewell/trace-mapping`（纯 JS），由 `js/` node 工程
  （pnpm 管理）用 esbuild 打成 IIFE 单文件
  `include/qjsbind/polyfill/source_map_lib.js`（入库），走 embed_js.py 嵌入；
  重建：`pixi run build-js-assets`（需本机 node + pnpm）。
- **remap 位置**：dispatcher 结算用户异常时，把栈里的
  `<id>.bundle.cjs:line:col` 经 `originalPositionFor` 改写成原始
  `source:line:col`（TraceMap 惰性构建，构建失败静默透传）。
- **行号偏移**：栈行号是 CJS 包装后文件的行号，查询映射前减 1（包装头占 1 行）；
  map 的 generated 位置应对应**调用方给的 bundle 源码**（未包装）。
- **已知边界**：编译期错误（compile_failed / 包装求值失败）的栈在 C++ 侧格式化，
  不经过 remap；列号按 source map 的 GLB 语义就近命中。
