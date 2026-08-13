# qjsbind 设计文档

> QuickJS-NG 的 C++ 自动绑定层：纯 C++ 签名的函数/类自动绑定到 JS，异步由 stdexec + asio 驱动。
>
> 参考代码锚点：
> - `rquickjs/` —— 绑定设计思路来源（trait 驱动的自动胶水）
> - `quickjs/` —— quickjs-ng v0.16.1，底层 C API（行号均指 `quickjs/quickjs.h`，除非另注）
> - `stdexec/` —— P2300 参考实现（commit f0e8ae6f ≈ v0.11.0），异步底座
> - `cpp26_executor_model_usage.md` —— stdexec 用法参考（本文引其小节号）

## 0. 目标与非目标

### 目标

1. **同步函数自动绑定**：普通 C++ 函数（自由函数/函数指针/lambda/成员函数）一行注册进 JS，**签名里不出现任何 QuickJS 类型**（无 `JSContext*`、无 `JSValue`）。
2. **异步函数自动绑定**：返回 `stdexec::task<T>`（即标准 `std::exec::task`，下同）/ 任意 sender 的函数，注册后在 JS 侧表现为返回 Promise 的函数。
3. **类自动绑定**：C++ 类型注册为 JS class（构造器、方法、静态方法、字段、getter/setter）。方法可以用成员函数指针，也可以用「第一个参数是 `This<T>` 的自由函数」这一语法糖。
4. **异步底座**：stdexec（sender/receiver），IO 运行时为 asio（`exec::asio` 适配器），事件循环与 QuickJS 同线程。
5. **多运行时并行**：进程内 N 个 `Runtime` 各自绑定一根 JS 线程并行运行（隔离/沙箱/并行宿主），跨 Runtime 只经 channel 交换原生数据，不共享 JS 状态（§1）。

对标 rquickjs 的两句用户代码：

```rust
globals.set("__base64_decode_to_native_buffer", Func::from(base64_decode_to_native_buffer))?;
let promise = Promise::wrap_future(&ctx, future)?;
```

本设计的 C++ 形态：

```cpp
globals.set("__base64_decode_to_native_buffer", qjs::func(base64_decode_to_native_buffer));
qjs::Value promise = qjs::promise_from_sender(ctx, std::move(fut));  // fut 是 sender
```

### 非目标（v1 不做）

- Worker（同 runtime 多线程共享 JS 堆，即 quickjs-libc 的 `os.Worker()`）：C API 无注册接口（`quickjs.h` 仅两个标注 "only exported for os.Worker()" 的辅助导出），且与「事件循环唯一主人是 io_context」的模型冲突，不做。多 JSRuntime **并行**是支持的，见 §1。
- JS 回调类型的全自动转换（`std::function` 参数自动包成 JS function，v2 再做；v1 用 `qjs::Function` 逃生舱）。
- 类的 JS 侧继承（`class X extends Point`），v2。
- BigInt、Symbol、TypedArray 的自动转换（v1 走 `qjs::Value` 逃生舱）。

## 1. 总体架构

```
┌─────────────────────────────────────────────────────────┐
│ 用户代码：纯 C++ 函数 / 类（签名无 qjs 类型）              │
├─────────────────────────────────────────────────────────┤
│ qjsbind（header-only，namespace qjs）                    │
│  ├─ convert.hpp   js_convert<T>：C++ 类型 ⇄ JSValue      │
│  ├─ function.hpp  function_traits + thunk 生成 + func()  │
│  ├─ class.hpp     class_<T> 注册 DSL                     │
│  ├─ promise.hpp   promise_from_sender + 结算 receiver    │
│  ├─ loop.hpp      事件循环（asio io_context + JS jobs）  │
│  └─ value.hpp     Value/Context/Runtime 的 RAII 封装     │
├──────────────────────┬──────────────────────────────────┤
│ quickjs-ng C API     │ stdexec (P2300) + exec::asio      │
│ （单线程，JS 世界）   │ （异步世界：sender/task/scope）    │
└──────────────────────┴──────────────────────────────────┘
```

**线程模型（核心不变量）**：

- **每个 `JSRuntime` 绑定且只被一根线程（下称 **JS 线程**）触碰**——进程内可有多个 `Runtime` 并行：每个 `Runtime` 拥有自己的 `JSRuntime` + JS 线程 + `asio::io_context` + `async_scope` + `pending_` 计数，互不共享任何 JS 状态。quickjs-ng 官方模型即多 runtime 多线程、零共享；一个 runtime 内不支持多线程（`docs/developer-guide/intro.md:14`），`JS_EnqueueJob` 无锁（`quickjs.c:2494-2514`）。跨 Runtime 通信与跨线程相同：只经 channel 递原生数据（见下）。
- JS 线程上跑一个 `asio::io_context` 作为事件循环。所有 IO/定时器挂在这个 io_context 上。
- 重计算可 offload 到 `exec::asio::asio_thread_pool`（或 `exec::static_thread_pool`），但**触碰 JS 之前必须 `continues_on` 回 JS 线程的 scheduler**。这一条由 `promise_from_sender` 在结算前强制追加 `continues_on(js_sched)` 保证（见 §5.3）。
- 跨线程交互通道：`co::oneshot`（一对一单次）/ `co::mpsc`（多对一多次）channel——类 tokio 语义，park 路径原生支持 stop token（见 `cpp26_executor_model_usage.md` §8.7）。工作线程只递原生数据进 channel，不碰 JSValue；JS 线程在协程里 `co_await` 接收端消费。

头文件布局：

```
include/qjsbind/
  qjsbind.hpp     // 总入口
  value.hpp       // Value / Object / Array / Function / Persistent（JSValue RAII）
  context.hpp     // Context / Runtime / 每 runtime 注册表
  error.hpp       // js_error 等异常类型
  convert.hpp     // js_convert<T> 及内置实现
  function.hpp    // function_traits / func() / thunk
  class.hpp       // class_<T>
  promise.hpp     // promise_from_sender / 结算 receiver
  loop.hpp        // Runtime::run() 事件循环
```

## 2. 基础 RAII 层

对 C API 只做薄薄一层所有权封装，不追求"全覆盖的 C++ 包装"——绑定层内部使用，用户一般碰不到。

```cpp
namespace qjs {

class Value {                      // 持有一个已 dup/新建的 JSValue
  JSContext* ctx_; JSValue v_;
public:
  ~Value() { JS_FreeValue(ctx_, v_); }
  Value(const Value& o) : ctx_(o.ctx_), v_(JS_DupValue(ctx_, o.v_)) {}
  // move / 判空 / is<T>() / as<T>() ...
};

class Context {                    // JSContext* 薄包装，不拥有
public:
  Value eval(std::string_view code, std::string_view filename = "<input>", int flags = 0);
  Value globals();                 // JS_GetGlobalObject
  Value promise_capability();      // 见 promise.hpp
  // ...
};

class Runtime {                    // 拥有 JSRuntime + 主 JSContext + 事件循环资产
  std::string id_;                 // 实例标识：可自定义，默认自动生成 UUID v4
  JSRuntime* rt_;
  JSContext* ctx_;
  asio::io_context io_;            // 见 §5/§8（成员声明顺序保证销毁次序）
  stdexec::counting_scope scope_;
  // ...
public:
  explicit Runtime(std::string id = {});     // 空 id → 自动 UUID v4
  const std::string& id() const noexcept { return id_; }
};

}
```

要点：

- 所有权规则照 quickjs.h:207-223 注释：`JSValue` 参数=移交、`JSValueConst`=借用、返回值=调用方负责 free。**调试构建打开 `JS_CHECK_JSVALUE`**（quickjs.h:203-227），编译期抓所有权错误。
- quickjs-ng 里 `JS_FreeValue` / `JS_DupValue` / `JS_FreeCString` 是真正的导出函数（:864-869, :921），直接调。
- `JS_ToCStringLen` 在 ng 是 `JS_ToCStringLen2(ctx, plen, val, /*cesu8=*/bool)` 的 inline 包装（:901-909）；返回指针**必须配对 `JS_FreeCString`**（quickjs.c:4983-4989），且指向 runtime 内部缓冲，不得跨调用持有 → 转换层一律立即拷成 `std::string`。
- **实例 id**：`Runtime(std::string id = {})`——传自定义 id（如 `"worker-1"`），留空则自动生成 UUID v4（`boost::uuids::random_generator`，vcpkg 依赖 `boost-uuid`）。`id()` 只读访问。用途：多 Runtime 日志区分、跨 Runtime channel 消息的来源标识（§8.2）、亲和断言错误信息。进程内唯一性：自定义时是调用方责任；自动生成时碰撞概率可忽略（v4 有 122 bit 随机空间）。
- **不可移动性**：`Runtime` 是不可移动/复制的集合体（`asio::io_context`、`stdexec::counting_scope`（内部含 mutex）均不可移动）——多 Runtime 场景下用 `std::unique_ptr<Runtime>` 或直接栈上分配持有，不需要 move 语义（§8.2）。

## 3. 类型转换系统 `js_convert<T>`

对应 rquickjs 的 `IntoJs` / `FromJs`（`rquickjs/core/src/value/convert.rs`）。C++ 里用一个可特化的 trait 模板：

```cpp
namespace qjs {

template <class T, class Enable = void>
struct js_convert;                 // 主模板未定义 = 该类型不可转换（编译期报错）

// 每个特化提供：
//   static JSValue to_js(JSContext*, const T& / T&&);
//   static T from_js(JSContext*, JSValueConst);   // 失败抛 qjs::type_error

}
```

### 3.1 内置转换表

| C++ 类型 | JS 侧 | 实现要点 |
|---|---|---|
| `bool` | boolean | `JS_ToBool` / `JS_NewBool` |
| `int32_t`/`uint32_t`/`int64_t`/`double`/`float` | number | `JS_ToInt32/ToInt64/ToFloat64`（:876-883）；超范围自动 float64 |
| `std::string` / `const char*` | string | `JS_NewStringLen` / `JS_ToCStringLen`+拷贝 |
| `std::string_view` | string（仅**入参**与**返回**，见下） | 入参视图仅在调用帧内有效 |
| `std::optional<T>` | `null`/`undefined` ⇄ `nullopt` | 对应 rquickjs 的 `Option<T>` |
| `std::vector<T>` | Array | 逐元素转换 |
| `std::map<std::string,T>` / `std::unordered_map` | Object | |
| `std::tuple<...>` | 定长 Array | |
| `std::variant<...>` | 按序尝试各备选 | from_js 逐个 try |
| `void`（返回） | `undefined` | |
| `qjs::Value` / `Object` / `Array` / `Function` | 原样 | 逃生舱：签名里**允许**出现这些 qjsbind 自有类型（不是裸 qjs 类型） |
| 已注册的 bound class `T` | 类实例 | 见 §6 |
| 返回 `stdexec::task<T>`（`std::exec::task`）/ sender | Promise | 见 §5 |

显式不做自动转换的：`char*` 出参、裸 `T*` 返回（所有权不明，编译期拒绝并提示用 `std::shared_ptr` 或按值返回）。

### 3.2 自定义类型扩展

用户对自己的类型特化 `js_convert` 即可（不注册成 class 时按值转换）。两种风格都支持：

```cpp
// 风格 A：手写特化
template <> struct qjs::js_convert<MyColor> {
  static JSValue to_js(JSContext* ctx, const MyColor& c);
  static MyColor from_js(JSContext* ctx, JSValueConst v);
};

// 风格 B：注册成 JS class（§6），自动获得 to_js/from_js（按 opaque 指针取引用）
```

### 3.3 特殊参数类型（不消耗 argv / 改变取参方式）

照抄 rquickjs `FromParam` 的特化清单（`rquickjs/core/src/value/function/params.rs:245-342`），C++ 用 concepts + `if constexpr` 实现，无重叠问题：

| 参数类型 | 语义 | 消耗 argv |
|---|---|---|
| `qjs::Ctx` | 注入当前 `JSContext*` 包装 | 否 |
| `qjs::This<T>` | 从 `this_val` 取 bound class 实例（`JS_GetOpaque2`，:1063） | 否（取 this） |
| `qjs::This<qjs::Value>` | 拿原始 this 值 | 否 |
| `qjs::Opt<T>` | 可选尾参：有剩参则取，否则 `nullopt` | 0 或 1 |
| `qjs::Rest<T>` | 排空剩余参数为 `std::vector<T>` | 全部剩余 |

注意与 rquickjs 一致地区分：`std::optional<T>` 是**值**层面的可空（JS null/undefined），`qjs::Opt<T>` 是**参数个数**层面的可选。两者可以叠加：`Opt<std::optional<T>>`。

## 4. 函数自动绑定（同步）

### 4.1 签名拆解：`function_traits`

rquickjs 受语言所限要用"参数元组作 trait 键"的技巧（`IntoJsFunc<'js, (A,B)>`，`into_func.rs:13-156`）；C++ 的可变参数模板天然表达任意签名，更直接：

```cpp
template <class T> struct function_traits : function_traits<decltype(&T::operator())> {};
template <class R, class... A> struct function_traits<R(*)(A...)>        { using result = R; using args = std::tuple<A...>; };
template <class C, class R, class... A> struct function_traits<R(C::*)(A...)>       { /* 隐含 this:C* 视作首个特殊参数 */ };
template <class C, class R, class... A> struct function_traits<R(C::*)(A...) const> { /* 同上，const */ };
// + noexcept 变体、R(A...) 直接签名变体
```

### 4.2 参数个数约束（编译期折叠）

对应 rquickjs 的 `ParamRequirement{min,max,exhaustive}`（params.rs:164-242）。对参数包做 constexpr 折叠：

- `min` = 首个 `Opt`/`Rest` 之前的普通参数个数（`This`/`Ctx` 不计）。
- `Rest` 出现则 `max = ∞`，否则 `max` = 普通参数+`Opt` 总数。
- `min` 作为 JS 函数的 `length` 属性传给 `JS_NewCClosure`（:1338-1341）。
- 运行时 `argc < min` → `JS_ThrowTypeError(ctx, "missing argument ...")`。
- quickjs-ng 的 C closure 调用路径会把缺失参数**补 `undefined` 到 `length`**（`quickjs.c:6764-6766`），解包逻辑因此简化；多出的参数非 `Rest` 时忽略（JS 惯例）。

### 4.3 thunk 生成：两个入口

```cpp
// 入口 A：编译期函数指针（NTTP），零间接调用，推荐
qjs::func<&add>()                    // template <auto F> Function func();
qjs::func<&Point::norm>()            // 成员函数指针也行（This 自动注入）

// 入口 B：运行期可调用对象（lambda、std::function、函数指针）
qjs::func([](double a, double b) { return a + b; });
qjs::func(some_fn_ptr);
```

底层都落到同一个机制——**`JS_NewCClosure`**（quickjs-ng 新增，:1337-1341）：

```c
JSValue JS_NewCClosure(JSContext *ctx, JSCClosure *func, const char *name,
                       JSCClosureFinalizerFunc *opaque_finalize,
                       int length, int magic, void *opaque);
// JSCClosure: JSValue (*)(JSContext*, JSValueConst this_val, int argc,
//                         JSValueConst* argv, int magic, void* opaque)
```

选它而不是 rquickjs 的「callable class + opaque」方案，因为 ng 原生提供了带 finalizer 的闭包对象（`js_c_closure_finalizer` 判空调用 `opaque_finalize`，`quickjs.c:6730-6740`），正好放 type-erased 的 C++ 可调用对象：

- 入口 A：opaque = nullptr，finalizer = nullptr，thunk 内直接调编译期已知的 `F`。
- 入口 B：opaque = `new holder{std::forward<F>(f)}`，finalizer = `delete holder`。thunk 是统一的一个泛型函数，从 opaque 取回闭包再调。

thunk 骨架（示意）：

```cpp
template <class F, class R, class... A, size_t... I>
JSValue invoke(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv,
               F& f, std::index_sequence<I...>) noexcept {
  try {
    if (argc < kMinArity) return JS_ThrowTypeError(ctx, "missing argument(s)");
    // 逐参：if constexpr 分派 Ctx/This/Opt/Rest/普通转换
    if constexpr (is_sender_v<R>) {
      return settle_promise_from_sender(ctx, invoke_and_decay_copy(...));   // §5
    } else if constexpr (std::is_void_v<R>) {
      std::invoke(f, convert_arg<A, I>(ctx, this_val, argc, argv)...);
      return JS_UNDEFINED;
    } else {
      return js_convert<R>::to_js(ctx, std::invoke(f, convert_arg<A, I>(...)...));
    }
  } catch (const js_error& e) {          // 用户/转换层主动抛的 JS 异常
    return JS_Throw(ctx, e.release_value());
  } catch (const type_error& e) {
    return JS_ThrowTypeError(ctx, "%s", e.what());
  } catch (const std::exception& e) {
    return JS_ThrowInternalError(ctx, "%s", e.what());
  } catch (...) {
    return JS_ThrowInternalError(ctx, "unknown C++ exception");
  }
}
```

**铁律：C++ 异常绝不允许穿过 QuickJS 的 C 帧**（QuickJS 不保证 unwind 安全），thunk 边界必须全捕获。这对应 rquickjs 在 FFI 边界的 `catch_unwind` + `Error::throw`（`rquickjs/core/src/class/ffi.rs:261-279`、`result.rs:286-358`）。

### 4.4 注册入口

```cpp
qjs::Value globals = ctx.globals();
globals.set("add", qjs::func<&add>());
// 或更自动：set 的可调用重载，直接吃函数指针
globals.set("add", add);
```

`Object::set(name, callable)` 检测到可调用类型时自动走 `func()` 包装——比 rquickjs 还省一步。挂 ES Module 走 §7。

## 5. 异步绑定（stdexec + asio）

### 5.1 设计原则

1. 异步 C++ 函数的签名形如 `task<T> f(A...)` 或 `sender f(A...)`——**JS 侧表现为 `Promise<T>`**。
2. 对应 rquickjs 的 `Async<F>` + `Promised(fut)`（`rquickjs/core/src/value/function/into_func.rs:36-55`）：参数**同步**提取完毕后再发起异步操作，函数本体立即返回 Promise。
3. 所有 promise 结算（resolve/reject）**必须发生在 JS 线程**。结算逻辑前强制 `continues_on(js_sched)`。

### 5.2 sender 识别

```cpp
template <class R>
inline constexpr bool is_async_result_v = stdexec::sender<R>;
// stdexec::task<T>（即 std::exec::task）与普通 sender 都满足 sender concept
// （stdexec/__detail/__task.hpp 的 enable_sender）
```

thunk 里 `if constexpr (is_async_result_v<R>)` 走 promise 包装分支（见 4.3 骨架）。

**注册路径对 task 和普通 sender 一视同仁**：`qjs::func` 只看返回类型是否满足 `stdexec::sender` 概念——`stdexec::task<T>`（`std::exec::task`）、`asio_op | then(...)` 这类运行期拼出来的管线 sender，全都自动包装成 Promise，不需要任何额外标注。`promise_from_sender` 是自动路径内部调用的原语，用户只在「手里已经握着一个 sender **对象**（而不是一个函数），想手动换成 Promise」时才直接用它，典型如绑定函数体内动态拼管线：

```cpp
// 自动路径：函数返回 task 或 sender，qjs::func 直接注册
globals.set("fetch", qjs::func(fetch));        // stdexec::task<string> fetch(string)
globals.set("query", qjs::func(query));        // auto query(string) { return db_get(q) | then(parse); }

// 手动路径：sender 对象 → Promise
qjs::Value search(qjs::Ctx ctx, std::string query) {
  auto sndr = build_pipeline(std::move(query));
  return qjs::promise_from_sender(ctx, std::move(sndr));
}
```

需要手动路径的具体场景（判据：promise 化无法从函数静态返回类型推断）：

- **返回类型写不出/不想暴露**：管线 sender 是匿名模板类型，跨 TU 分离声明时 `auto` 不可用；头文件声明 `qjs::Value f(...)`、实现里手动包，顺带获得编译防火墙。
- **一个返回值里装多个 Promise**：如 `{ done: p1, progress: p2 }`，自动路径只能包「整个返回值」这一个 sender。
- **运行期决定同步还是异步返回**：缓存命中直接 `qjs::to_js` 返回值，未命中 `promise_from_sender` 返回 Promise。
- **给已在运行的共享 sender 补发 Promise 句柄**：`exec::split` / `exec::ensure_started` 的多播 sender 早已 start，方法只是给 JS 一个观察它的 Promise。

### 5.3 `promise_from_sender` 实现

对照 rquickjs `Promise::wrap_future`（`rquickjs/core/src/value/promise.rs:48-79`）：

```cpp
template <stdexec::sender S>
JSValue promise_from_sender(JSContext* ctx, S&& sndr) {
  auto& env = runtime_env(ctx);              // 从 context opaque 取：async_scope + js_sched
  JSValue resolving[2];
  JSValue promise = JS_NewPromiseCapability(ctx, resolving);   // :1143

  auto hooks = std::make_shared<promise_hooks>(ctx, resolving[0], resolving[1]);
  // promise_hooks：RAII 持有 resolve/reject 两个 JSValue，析构时 JS_FreeValue

  auto chained =
      std::move(sndr)
    | stdexec::continues_on(env.js_sched)                       // ★ 结算点拉回 JS 线程
    | stdexec::then([hooks](auto&&... vs) noexcept {            // set_value → resolve
        hooks->resolve(convert_multi(vs...));                   // 0 值→undefined；1 值→值；多值→Array
      })
    | stdexec::upon_error([hooks](std::exception_ptr e) noexcept {
        hooks->reject(exception_to_js(ctx, e));                 // C++ 异常 → JS Error
      })
    | stdexec::upon_stopped([hooks]() noexcept {                // set_stopped → AbortError reject
        hooks->reject_abort();
      });

  env.runtime.spawn(std::move(chained), env.for_spawn());   // Runtime::spawn 统一入口（§8.1）；for_spawn 注入 get_start_scheduler
  JS_FreeValue(ctx, resolving[0]);
  JS_FreeValue(ctx, resolving[1]);
  return promise;                                               // 立即同步返回 pending promise
}
```

关键点：

- **错误通道必须先消化再 spawn**：链尾 `then/upon_error/upon_stopped` 三路全覆盖后 sender 不再 `set_error`/`set_stopped`。`stdexec::spawn` 对会失败的 sender 是编译期拒绝（`stdexec/__detail/__spawn.hpp`），`exec::async_scope::spawn` 不拦但出错直接 `std::terminate()`（`exec/async_scope.hpp:758-762`）——所以三个收尾 lambda 必须 `noexcept` 且内部不再泄漏异常。
- **opstate 生命周期**：由 `async_scope` 接管（spawn = nest + 堆上 opstate + 自删除），不用手写 connect/start 的存活性管理。scope 存在 `Runtime` 里，`Runtime::spawn` 同时维护在飞任务计数 `pending_`（§8.2）；关闭时 `request_stop()` 后**驱动 io_ 直至 `pending_ == 0`**（§8.3）——不能 `sync_wait(scope.on_empty())`，原因见 §8.3 开头。
- **stdexec::task 的 start scheduler 要求**：`stdexec::task` 被启动时要求父环境应答 `get_start_scheduler`，否则 static_assert（用法文档 §6.5、§14）。`stdexec::spawn(sndr, token, env)` 的 env 里注入 `get_start_scheduler = js_sched` 即可；协程每次 `co_await` 后自动"回家"到 JS 线程（stdexec::task 的调度亲和，`stdexec/__detail/__task.hpp`）。
- `continues_on(env.js_sched)` 中 `js_sched` 是 **io_context_scheduler**——用法文档 §12.6.2 已给出实现：`schedule()` 返回 `asio_impl::post(ioc, exec::asio::use_sender)`。裸 `asio::io_context` 没有现成 stdexec scheduler，这层薄包装是必须写的。
- promise 结算 = `JS_Call(ctx, resolve, JS_UNDEFINED, 1, &val)`（`quickjs-libc.c:2512-2558` 的 os.sleepAsync 就是此模式）；`JS_Call` 会把 then 回调排进 job 队列，由事件循环的 job 泵执行（§8）。
- 未处理 rejection 用 `JS_SetHostPromiseRejectionTracker`（:1177）挂监控，照抄 `js_std_promise_rejection_tracker` 的行为（`quickjs-libc.c:4783-4828`）。

### 5.4 异步函数怎么写（用户视角）

```cpp
// ★ 自由函数，不是 lambda —— 协程 lambda 捕获随闭包析构而悬垂（见 §10.1）
stdexec::task<std::string> fetch_text(std::string url) {
  asio_impl::steady_timer timer{current_io()};
  co_await timer.async_wait(exec::asio::use_sender);   // asio op → sender（用法文档 §12.6.1）
  // 需要重计算时：co_await exec::reschedule_coroutine_on(pool.get_scheduler());
  // 回来后继续 co_await，stdexec::task 会自动回到 home scheduler（JS 线程）
  co_return co_await do_http(std::move(url));
}

// 注册一行
globals.set("fetchText", qjs::func(fetch_text));
```

```js
const text = await fetchText("https://example.com");   // Promise<string>
```

异步参数规则：**异步函数的参数全部 decay-copy** 进发起闭包（string_view/引用禁止，static_assert 拦截）——同步提取后原 argv 即失效，这是 rquickjs `Async` 同样遵守的约束。

### 5.5 取消语义（v1 → v2）

- v1：JS 侧没有标准取消通道；C++ 侧 `Runtime` 析构/`scope.request_stop()` 时，未完成任务以 `set_stopped` 收尾 → promise 以 AbortError reject。
- v2：把 `qjs::Ctx` 换成可注入 stop token 的 `qjs::AsyncCtx`（从 env `get_stop_token` 读取），并接 JS `AbortSignal`：signal abort → `request_stop`。asio 操作为经 `use_sender` 发起的会自动经 cancellation_slot 收到取消（`use_sender.hpp:260-269`）。

## 6. 类绑定 `class_<T>`

rquickjs 的方案是 `#[class]`/`#[methods]` proc macro 生成注册代码（`rquickjs/macro/src/methods.rs`）。C++ 没有 proc macro，用链式 DSL（用户说"语法糖"是可接受的）：

```cpp
struct Point {
  double x, y;
  double norm() const { return std::sqrt(x*x + y*y); }
  void move_by(double dx, double dy) { x += dx; y += dy; }
  static Point origin() { return {0, 0}; }
};

// 自由函数形态的方法糖：第一个参数是 This<Point> 或 Point&
double distance(qjs::This<Point> self, const Point& other);

qjs::class_<Point>(ctx, "Point")
  .constructor<double, double>()        // new Point(1.0, 2.0)
  .field("x", &Point::x)                // 成员对象指针 → getter+setter
  .field_readonly("tag", &Point::tag)
  .method("norm", &Point::norm)         // 成员函数指针
  .method("moveBy", &Point::move_by)
  .method("distance", distance)         // 自由函数语法糖，this 注入
  .static_method("origin", &Point::origin);
```

JS 侧：

```js
const p = new Point(3, 4);
p.norm();            // 5
p.moveBy(1, 1);
Point.origin();
p.x = 10;
```

### 6.1 class 注册（quickjs-ng 的 per-runtime 语义）

ng 里 `JS_NewClassID(JSRuntime*, JSClassID*)`（:708）是 **per-runtime 分配、幂等写回**（`*pclass_id==0` 才分配），class id 上限 `1<<16`。因此**不能**用进程级 static 变量存 class id（多 runtime 会撞），正确做法是每 runtime 一张注册表：

```cpp
struct class_registry {                          // 挂在 Runtime 对象上，ctx opaque 可达
  std::unordered_map<std::type_index, JSClassID> ids;
  std::unordered_map<std::type_index, Value>     protos;   // 每 ctx 缓存
};

template <class T> JSClassID ensure_class_registered(JSRuntime* rt) {
  auto& reg = registry(rt);
  auto it = reg.ids.find(typeid(T));
  if (it != reg.ids.end()) return it->second;
  JSClassID id = 0;
  JS_NewClassID(rt, &id);                        // 幂等
  static const JSClassDef def{ class_name_of<T>, &finalizer<T>, nullptr, nullptr, nullptr };
  JS_NewClass(rt, id, &def);                     // 每 runtime 一次（:711，重复注册返回 -1）
  reg.ids.emplace(typeid(T), id);
  return id;
}
```

rquickjs 用「3 个共享 class id + Rust vtable + TypeId」的复用设计（`rquickjs/core/src/runtime/opaque.rs:102-141`），是因为原版 quickjs class id 是全局稀缺资源；ng 改为 per-runtime 后没有必要，**每 C++ 类型一个 class id** 更简单直白。

### 6.2 构造器 / 原型（canonical 模式）

照 `quickjs-libc.c:4493-4522`（Worker 类）的标准四步：

```cpp
JSValue proto = JS_NewObject(ctx);
// ... 往 proto 上挂方法（JS_SetPropertyStr / JS_DefinePropertyGetSet）...
JSValue ctor = JS_NewCFunction2(ctx, &ctor_thunk<T, Args...>, "Point",
                                /*length=*/sizeof...(Args), JS_CFUNC_constructor, 0);  // :1323
JS_SetConstructor(ctx, ctor, proto);             // :1358，互链 prototype/constructor
JS_SetClassProto(ctx, class_id, proto);          // :541
```

构造器 thunk（`JS_CFUNC_constructor` 原型下 `this_val` 实为 `new_target`）：

```cpp
// 1. 从 new_target 取 "prototype"（支持 extends 的基础；失败回退 JS_GetClassProto）
// 2. args → C++ 参数包 → new T(args...)
// 3. JS_NewObjectProtoClass(ctx, proto, class_id)（:926）
// 4. JS_SetOpaque(obj, ptr)（:1061，ng 返回 int，仅自定义 class 可用）
```

### 6.3 实例存储与 finalizer

v1 支持两种所有权：

| 注册方式 | opaque 内容 | finalizer |
|---|---|---|
| `class_<T>`（默认，JS 拥有） | `new T(...)` 的裸指针 | `delete (T*)` |
| `class_<T, std::shared_ptr<T>>` | `new std::shared_ptr<T>(...)` | `delete (shared_ptr<T>*)` |

finalizer 签名 `void (*)(JSRuntime*, JSValueConst)`（:674）——**没有 ctx、不能执行 JS**，只做原生析构。

方法/自由函数取实例：`JS_GetOpaque2(ctx, this_val, class_id)`（:1063），类型不符自动抛 TypeError。这同时支撑 `This<T>` 参数和 `const Point&` 形态的普通参数转换（js_convert 对 bound class 的特化就是 `GetOpaque2` 取引用）——于是 `double distance(const Point&, const Point&)` 这种纯自由函数绑定成全局函数也能直接收类实例。

### 6.4 方法 / 字段 / getter-setter

- `.method(name, fn)`：`fn` 走与全局函数完全相同的 `func()` 机制（成员函数指针在 traits 里把 `this` 折算为首个特殊参数），产物 `JS_SetPropertyStr(proto, name, fn_obj)`。**异步方法天然支持**：成员函数返回 `stdexec::task<T>` 时走 §5 的 promise 分支（但注意 §10.1 的 MSVC 协程坑——协程方法建议写成自由函数 + `This<T>`）。
- `.static_method(name, fn)`：挂到**构造器函数对象**上（rquickjs 同样处理，`methods.rs:230-265`）。
- `.field(name, &T::member)`：生成 getter/setter 两个小 closure，`JS_DefinePropertyGetSet(ctx, proto, atom, get, set, JS_PROP_CONFIGURABLE)`（:1057-1059）。也可以显式 `.getter(name, fn)` / `.setter(name, fn)`。
- 持有 JS 值的类（成员里有 `qjs::Value`/`Persistent`）：提供 `.trace(fn)` 钩子填 `JSClassDef.gc_mark`，漏写会导致 GC 后悬垂——这是 rquickjs 用 derive 宏保证、C++ 只能靠约定的**正确性高风险点**，文档和静态断言都要强调。

### 6.5 与 rquickjs `#[methods]` 的属性对照

rquickjs 的 `#[qjs(get/set/static/constructor/rename/rename_all/configurable/enumerable/writable)]`（`macro/src/methods.rs:83-305`）在 DSL 里一一对应：`.getter/.setter/.static_method/.constructor/.method(name, ...)`（name 即 rename），属性 flags 用 `.method(name, fn, JS_PROP_CONFIGURABLE | ...)` 尾参。`rename_all`（camelCase 批量改名）可做 v2 的编译期字符串变换。

## 7. 模块系统

ES Module 导出走 ng 的 C 模块两阶段 API（:1434-1445）：

```cpp
qjs::Module m(ctx, "my:native");
m.function("base64_decode_to_native_buffer", base64_decode_to_native_buffer);
m.class_(std::move(point_class));       // 构造器挂为模块导出
// 实现：JS_NewCModule（:1436）→ JS_AddModuleExport（实例化前，:1439）
//       → init 回调里 JS_SetModuleExport（:1443）
```

JS：`import { base64_decode_to_native_buffer, Point } from "my:native";`

全局挂载与模块导出共用同一套 `func()`/`class_` 产物，只是落点不同（`JS_SetPropertyStr(global, ...)` vs `JS_SetModuleExport`）。

## 8. 事件循环

事件循环是整条异步链路的收口，本节把驱动协议、退出/关闭顺序和与 quickjs-libc 的关系定清楚。

### 8.1 骨架与不变量

三条不变量（其余设计都由此推导）：

1. **所有异步活动都被 `async_scope` 收养，且只经 `Runtime::spawn` 一个入口**（`scope_` 私有；§5.3 的 `promise_from_sender` 与用户自起 sender 都走它）——`Runtime` 据此维护在飞任务计数 `pending_`（spawn 时 +1，三路收尾时 -1，见 §8.2），「系统里还有没有未完成的异步」直接可查，关闭协议与脚本模式退出都靠它。
2. **JS 只在 JS 线程被触碰**；跨线程交互走 channel：`co::oneshot`（一对一单次）/ `co::mpsc`（多对一多次），类 tokio 语义、park 路径原生支持 stop token（用法文档 §8.7）——工作线程只把原生数据送进 channel，JS 线程在协程里 `co_await` 接收端消费。channel 接收端对事件循环的唤醒桥接属 channel 实现侧，此处不展开。唯一例外：`JS_SetInterruptHandler` 的原子标志（见 8.5）。
3. **结算必在 io handler 内**（§5.3 的 `continues_on(js_sched)` 保证）——promise 结算排入的 JS job 在下一轮循环开头必然被泵取，不需要额外唤醒机制。

骨架：

```cpp
void Runtime::loop_body() {
  pump_js_jobs();      // 一次排干 JS job（与浏览器微任务语义一致）
  io_.run_one();       // 跑一个 asio handler；无 ready 工作时阻塞在 IOCP/epoll 上
}

void Runtime::pump_js_jobs() {
  JSContext* c;
  int r;
  while ((r = JS_ExecutePendingJob(rt_, &c)) == 1) {}   // :1245
  if (r < 0) on_unhandled_exception_(c);               // 默认打印，类似 js_std_dump_error
}
```

- **一次排干**是刻意的：JS 微任务检查点语义要求清空队列，`js_std_loop` 的内层 for 也一样（quickjs-libc.c:4837-4841）。代价是 JS 侧自持的微任务无限循环会饿死 IO——这是 JS 本身的语义，明示即可。
- 不用 `stdexec::run_loop` / `exec::single_thread_context` 当循环主体：它们各自霸占或新起一根线程（`run_loop::run()` 是阻塞循环且无 `poll`），无法与 asio io_context 共享 JS 线程。**事件循环的唯一主人是 io_context**，stdexec 只提供 sender 语义层。

### 8.2 两种驱动模式 + 嵌入模式

```cpp
// 模式 A：服务模式（默认主模式）—— 常驻后台，唯一退出途径是 stop()
void Runtime::run() {
  guard_.emplace(asio::make_work_guard(io_));  // 保活：无 ready handler 时 run_one 阻塞等未来工作
  while (!done_)
    loop_body();
  shutdown();                                   // 8.3
}

// 模式 B：脚本模式 —— 所有被收养的异步完成即退出（类 node 跑脚本语义）
void Runtime::run_to_completion() {
  guard_.emplace(asio::make_work_guard(io_));
  for (;;) {
    pump_js_jobs();                             // 排干：结算 job 可能 spawn 新任务（+1）
    if (done_ || pending_.load(std::memory_order_acquire) == 0)
      break;                                    // 排干后无在飞异步 → 真空闲
    io_.run_one();
  }
  shutdown();
}

// 模式 C：嵌入外部主循环（GUI/游戏帧循环）—— 非阻塞单步
void Runtime::poll_once() {
  pump_js_jobs();
  io_.poll();                                   // 只跑当前 ready 的 handler，不阻塞
  check_unhandled_rejections();                 // 8.5
}
```

要点：

- **退出判据是「`pending_ == 0`」而不是「io 无工作」**：io_context 查询不了未触发的定时器，而 `pending_` 精确反映 JS 可见的异步活动（模式 B 用它退出；模式 A 的 shutdown 用它收尾）。纯 JS 微任务链在 `pump_js_jobs` 内排干；微任务里新起的异步会重新 +1，下一轮判定自然延续。**检查总在 `pump_js_jobs()` 之后**：pump 排干结算 job 才可能 spawn 新任务（先 +1 再被检查到），而 -1 是任务收尾的最后一动作（此后 sender 即完成、opstate 自删），所以 `pending_ == 0` 时不存在未观察到的在飞任务。`pending_` 用 atomic（未接 `continues_on` 的链收尾可能经线程池路径）。
- **不用 `scope_.on_empty()` 做退出判据**：它是「从非空变空」的边沿触发一次性信号（`when_empty` opstate 在 `active != 0` 时挂 waiters 队列，仅 active 1→0 瞬间被通知；挂起期间析构 opstate 会悬垂，`__task` 无自摘除）——标志置位后若 pump 排干的结算 job 又 spawn 新任务，scope 非空但标志仍为 true，会提前退出丢任务。计数是可直接查询的当前状态，无此问题。
- **停止协议（`stop()`）**：服务模式常驻期间，唯一退出途径是 `stop()`——可从任意线程调用，内部 `asio::post(io_, [this]{ done_ = true; })`，只碰 io_（线程安全）、不碰 JS。`stop()` 后 `run()` 在下一轮循环开头退出并进入 §8.3 `shutdown()`。注意 `shutdown()` 是单向的（`scope_.request_stop()` 不可逆）：停止后 Runtime 不可再 `run()`，需重新构造；宿主若希望「空闲即退」用模式 B。
- 模式 C 给已有主循环的宿主：每帧调一次。host 在循环外直接调 qjs API（eval、调 JS 函数）可能排入 job，随后补一次 `poll_once()` 或至少 `pump_js_jobs()` 即可。
- 线程池 offload 的完成会经 `continues_on(js_sched)` post 回 io_，所以「io 暂时无 ready handler」≠「系统空闲」——`run_one` 阻塞 + work_guard 保活的组合正确处理这种将来才到达的工作，不会误判退出。
- **多 Runtime 并行**：宿主为每个 `Runtime` 起一根 `std::thread` 跑 `run()`（Runtime 保持阻塞 API，不内建线程管理）；多 Runtime 之间零 JS 状态共享，通信走 §8.1 不变量 2 的 channel（原生数据，消息可带 `Runtime::id()` 标识来源，§2）。统一关闭：先逐个 `stop()`（任意线程可调），再 `join` 各线程——`shutdown()` 在各自线程内收尾到 `pending_ == 0` 后 `run()` 才返回。§8.5 的线程亲和断言 per-Runtime 成立（每个 Runtime 记录自己的 `js_thread_id_`）。

### 8.3 关闭协议

退出主循环后**不能**直接 `sync_wait(scope_.on_empty())`：被取消任务的结算回调（`upon_stopped` → reject AbortError）经 `continues_on(js_sched)` 排在 io_ 队列里，没人驱动 io_ 它们永远到不了，`sync_wait` 死等。正确顺序：

```cpp
void Runtime::shutdown() {
  scope_.request_stop();                       // 1. 通知所有在飞任务（协作式取消）
  while (pending_.load(std::memory_order_acquire) != 0) {  // 2. 驱动到全部结算
    pump_js_jobs();
    io_.run_one();                             // guard_ 仍在：取消结算必然 post 回 io_
  }
  pump_js_jobs();                              // 3. 收尾 job（AbortError 的 then/catch 链）
  check_unhandled_rejections();                // 4. 汇总上报未处理 rejection
  guard_.reset();                              // 5. 解除保活
}
// 此后 Runtime 析构：JS_FreeContext → JS_FreeRuntime（类 finalizer 在析构中运行）
```

第 2 步必然终止：每个在飞任务的三路收尾（`then`/`upon_error`/`upon_stopped`，§8.2 的 spawn 包装）必有一路触发，`pending_` 单调降为 0——被取消的任务里，asio 操作收到 cancel → `operation_aborted` → handler 必然投递回 io_（`use_sender` 把它映射为 `set_stopped`）；线程池上的工作完成后同样经 `continues_on` 回来。例外是用户代码忽略 stop token 且永不返回——取消是协作式，那是用户代码的责任（用法文档 §11）。

### 8.4 与 quickjs-libc std/os 模块的关系

- **不用 `js_std_loop`**（quickjs-libc.c:4831-4856）：它内嵌 `js_os_poll` 的 select/epoll 循环，与 io_context 冲突。
- `js_std_add_helpers`（console.log/print/scriptArgs）可挂，无循环依赖。
- **`os` 模块的异步函数（`os.sleepAsync` 等）依赖 js_std 自家的定时器队列 + `js_os_poll` 驱动**（quickjs-libc.c:2512-2558 的模式）——挂上但没人泵就永远不触发。v1：不挂 `js_init_module_os`，定时/IO 全部走 asio 绑定；v2 可选：js_std 的跨线程唤醒本身就是 waker 模式（Windows 是 event，POSIX 是 pipe/eventfd），可桥接成 asio 的可读事件挂进 io_context。
- 需要 `import` 文件模块时用 `JS_SetModuleLoaderFunc2`（:1194-1226）自实现同步读文件版即可，与循环无关。

### 8.5 杂项设施

- **Ctrl-C / 中断**：`JS_SetInterruptHandler(rt, cb, &flag)`（:1180-1181）——官方唯一认可的跨线程通道：信号线程只翻转原子标志，引擎在字节码断点自查并中断。需要停 loop 时用 `asio::post` 或 `stop()`，不要在中断回调里碰 io_。
- **未处理 rejection**：`JS_SetHostPromiseRejectionTracker`（:1177）维护未处理表，`is_handled` 翻转时摘除；在 `poll_once` 末尾与 `shutdown` 第 4 步检查上报（语义照抄 `js_std_promise_rejection_tracker`，quickjs-libc.c:4783-4828）。
- **GC 时机**：默依赖自动阈值即可；重内存场景在 `poll_once` 末尾或 `run_one` 返回后手动 `JS_RunGC`（:532）。
- **线程亲和断言**：debug 构建在所有触碰 JS 的入口断言 `std::this_thread::get_id() == js_thread_id_`，把不变量 2 变成早失败。
- **顶层 await**：eval 带 `JS_EVAL_FLAG_ASYNC`（:463）拿到顶层 promise 后，轮询 `JS_PromiseState`（:1147）并驱动循环直至 settled（等价 `js_std_await`，quickjs-libc.c:4894-4929），可作为 `run_to_completion` 的变体提供。

## 9. 与 rquickjs 的概念对照表

| rquickjs | qjsbind（C++） | 备注 |
|---|---|---|
| `Func::from(f)` | `qjs::func(f)` / `qjs::func<&f>()` | NTTP 版零间接 |
| `IntoJs` / `FromJs` | `js_convert<T>` 特化 | |
| `IntoJsFunc<'js, (A,B)>` 元组键 trait | `function_traits` 偏特化 + 参数包 | C++ 无需元组键技巧 |
| `Params` / `ParamsAccessor` | thunk 内 `if constexpr` 逐参分派 | |
| `ParamRequirement{min,max}` const 折叠 | constexpr 折叠表达式 | `length` 属性同源 |
| `Ctx<'js>` | `qjs::Ctx` | C++ 无生命周期标记，运行期断言代替 |
| `This<T>` | `qjs::This<T>` / 成员函数指针 | |
| `Opt<T>` / `Rest<T>` | `qjs::Opt<T>` / `qjs::Rest<T>` | |
| `Async(f)` + `Promised(fut)` | sender 返回类型自动识别 | 无需显式包装 |
| `Promise::wrap_future(ctx, fut)` | `qjs::promise_from_sender(ctx, sndr)` | |
| 自研 Schedular + DriveFuture（tokio 驱动） | asio::io_context + io_context_scheduler + async_scope | §5/§8 |
| callable class id + opaque 闭包 | `JS_NewCClosure`（ng 原生闭包） | 比 rquickjs 少走一层 |
| 3 共享 class id + vtable + TypeId | 每类型一个 per-runtime class id + `type_index` 注册表 | ng 改了 class id 语义 |
| `#[class]` / `#[methods]` proc macro | `class_<T>` 链式 DSL | C++ 无 proc macro |
| `Persistent<T>`（JS_DupValue 持有） | `qjs::Persistent<T>` | 同款设计 |
| `Result<T,E>` → throw（FFI 边界 catch_unwind） | C++ 异常 → throw（thunk 边界 try/catch） | |
| `'js` 不变生命周期 + HRTB 闭包（编译期安全） | 无对应物 → 降级为运行期检查 | **C++ 的真正缺口**：句柄 debug 断言同 runtime；跨作用域强制 `Persistent` |

## 10. 已知坑与注意事项

> 完整台账见 `docs/known_issues.md`（分类编号、状态跟踪）；本节为精简速查。

### 10.1 ★ 协程 lambda 捕获悬垂（生命周期问题，非 MSVC bug）

**协程只把（值）形参拷进协程帧；lambda 的捕获存在闭包对象里、不进帧**——闭包临时对象在协程首次挂起后随完整表达式结束析构，恢复后访问捕获即 use-after-free（曾误判为 MSVC 参数损坏 bug）。成员协程的 `this` 同理（隐式对象形参不进帧）。规避：**一切协程写成独立的自由函数**；临时用 lambda 必须"禁止捕获 + 值走形参 + 立即调用"。

```cpp
// ✗ 禁止：捕获随闭包临时对象析构而悬垂，恢复后读到垃圾值
auto bad = [data]() -> stdexec::task<int> { co_await cb(data); };

// ✓ 正确：自由函数（值形参拷进协程帧）
stdexec::task<std::string> fetch_text(std::string url) { ... }

// ✓ 必须 lambda 时：禁止捕获，值走形参并立即调用
auto ok = [](int data) -> stdexec::task<int> { co_await cb(data); }(data);

// ✓ 需要"方法"语义的协程：自由函数 + This<T> 糖
stdexec::task<void> point_upload(qjs::This<Point> self, std::string url) { ... }
```

这正好与绑定层兼容——自由函数是绑定的一等公民。测试阶段若发现协程参数值异常，先检查是否误用了带捕获的协程 lambda，不要怀疑绑定层。

### 10.2 其余坑（按风险排序）

1. **异常不得穿过 QuickJS C 帧**：所有 thunk 出口必须 try/catch 全捕获（§4.3）。FFI 边界外的 C++ 代码（如在 `stdexec::task` 协程里）抛异常是安全的——promise 的 `set_error(exception_ptr)` 通道会把它带回 JS 线程再转 JS 异常。
2. **JSValue/JSContext 只在 JS 线程触碰**：跨线程只能用 asio post 递原生数据。若确有线程切换，`JS_UpdateStackTop(rt)`（:522）必须先调。
3. **`stdexec::task` 需要 start scheduler**：脱离 `scope.spawn(sndr, env)` / `sync_wait` 环境裸 connect 一个 task 会 static_assert 失败（用法文档 §14）。绑定层内已注入，用户手写 receiver 时也要注意。
4. **`reschedule_coroutine_on` 的类型擦除限制**：它把 scheduler 擦除进 `any_scheduler`，个别 scheduler 类型擦不进去会编译失败（用法文档 §6.4 记录了 Clang 下 `static_thread_pool` 的案例；MSVC 待验证）。稳妥选择：io scheduler 或 `single_thread_context` 的 scheduler。
5. **spawn 链尾必须消化 error/stopped 通道**，收尾 lambda 标 `noexcept`（§5.3）。
6. **class id per-runtime**：禁止进程级 static 存 `JSClassID`（§6.1）。
7. **finalizer 里没有 ctx**：不能跑 JS、不能 `JS_FreeValue`（用 `JS_FreeValueRT`）；持有 JS 值的对象用 `gc_mark` + 在 JS 线程的析构队列处理。
8. **`JS_FreeCString` 必须配对**，返回指针指向 runtime 内部缓冲——转换层立即拷贝（§2）。
9. **异步函数参数 decay-copy**：`std::string_view`/引用参数在异步签名里 static_assert 拦截（§5.4）。
10. **工具链**：MSVC 用最新 VS2022，编译选项 `/Zc:__cplusplus /Zc:preprocessor /Zc:externConstexpr /bigobj`（走 stdexec 的 CMake target 会自动带上，`stdexec/CMakeLists.txt:296-298`）。`exec::asio` 依赖**生成的** `asio_config.hpp`，必须走 CMake：`STDEXEC_ENABLE_ASIO=ON` + `STDEXEC_ASIO_IMPLEMENTATION=standalone|boost`（用法文档 §12.6.6），链接 `STDEXEC::asioexec`。stdexec 本体 header-only，要求 C++20。

## 11. 端到端示例

```cpp
#include <qjsbind/qjsbind.hpp>
#include <stdexec/execution.hpp>
#include <exec/asio/use_sender.hpp>
#include <asio/steady_timer.hpp>

using qjs::This;

// ---- 同步自由函数：签名无 qjs 类型 ----
double add(double a, double b) { return a + b; }

// ---- 异步自由函数（★ 自由函数，不是 lambda —— §10.1）----
stdexec::task<std::string> greet_after(std::string name, double ms) {
  asio::steady_timer timer{qjs::current_io(), std::chrono::milliseconds{(long long)ms}};
  co_await timer.async_wait(exec::asio::use_sender);
  co_return "hello, " + name;
}

// ---- 类 ----
struct Counter {
  int value = 0;
  int add(int d) { return value += d; }
};

stdexec::task<int> counter_add_later(This<Counter> self, int d, double ms) {
  asio::steady_timer timer{qjs::current_io(), std::chrono::milliseconds{(long long)ms}};
  co_await timer.async_wait(exec::asio::use_sender);
  co_return self->add(d);
}

int main() {
  qjs::Runtime rt;
  qjs::Context ctx = rt.main_context();

  ctx.globals().set("add", qjs::func(add));
  ctx.globals().set("greetAfter", qjs::func(greet_after));

  qjs::class_<Counter>(ctx, "Counter")
    .constructor<>()
    .method("add", &Counter::add)
    .method("addLater", counter_add_later)     // 异步方法（自由函数糖）
    .field("value", &Counter::value);

  ctx.eval(R"(
    const c = new Counter();
    c.add(5);
    Promise.all([greetAfter("qjs", 100), c.addLater(2, 50)])
      .then(([g, total]) => print(g, "total=", c.value + total));
  )", "<demo>", JS_EVAL_TYPE_GLOBAL);

  rt.run();   // 事件循环：泵 JS jobs + 驱动 asio（§8）
}
```

JS 侧看到的就是：`add` 普通函数、`greetAfter`/`addLater` 返回 Promise、`Counter` 是个完整 class。

## 12. 里程碑

| 里程碑 | 内容 | 验收 |
|---|---|---|
| M1 基础层 | RAII 封装、`js_convert` 基础类型、同步函数绑定（NTTP + 闭包两入口）、异常边界、`Opt`/`Rest`/`Ctx`/`This` | JS 调用同步函数全类型往返正确；C++ 异常正确变 JS 异常；`JS_CHECK_JSVALUE` 下无所有权错误 |
| M2 类绑定 | `class_<T>`：constructor/method/static/field/getter/setter、per-runtime class 注册表、finalizer | JS `new`/方法/字段全通；GC 后无泄漏（`JS_ComputeMemoryUsage` 前后对比） |
| M3 异步 | io_context_scheduler、`promise_from_sender`、sender 返回自动识别、`Runtime::run()`、async_scope 收尾、rejection tracker | 协程函数 JS 侧 await 成功；asio timer/socket 联通；异常→reject；关闭无 terminate |
| M4 打磨 | 异步方法糖、`qjs::Function` 回调、`Module` 导出、取消（stop token 打通）、多 Runtime 并行（每 Runtime 一线程 + channel 互通 + 统一 stop/join + 实例 id） | 端到端示例（§11）跑通；两个 Runtime 各自线程并行跑通、channel 互通、stop 后 join 无泄漏、id 可自定义且默认唯一 |
| M5 增强 | 继承、`std::function` 自动转换、gc_mark/trace 工具、BigInt、多值返回→Array 之外的形态定制 | 视需求排期 |

## 13. 候选方向：句柄方案（handle + 对象表 + 自由函数）——设计笔记，暂不实现

> 结论（2026-08 评审）：不实现。本文记录讨论结论与**生命周期注意点**，供将来真需要"对象跨边界"时参考。

### 13.1 动机

多 Runtime + channel 互通（M4）之后，"把 C++ 对象传给另一个 Runtime/线程"成为自然需求：
现有 `class_` 的 opaque 是裸指针（`GetOpaque2` 取出 T*），**绑定 runtime、不能过 channel、不能序列化**。
句柄方案让对象获得**纯数据的身份标识**（数字 id），可跨线程/跨 Runtime/持久化。

### 13.2 分层设计（若实现）

不是"句柄 + 自由函数"替代 `class_`，而是**作为 `class_` 的底层实现**：

```
C++ 对象表（handle → unique_ptr<T>，每 Runtime 一张）
        ↑ 内部
class_<T>：JS 对象 opaque 里存 handle（而非裸指针），方法仍 p.norm() 自然语法
        ↑ 对外
handle 可暴露给跨边界场景（channel/序列化）
```

JS 侧语法不变（`p.norm()`、`p.x`），只是 opaque 从 `T*` 换成 handle；
另可生成一层自由函数包装（`point_norm(h)`）给"无 JS 类包装"的资源型对象（文件句柄/socket）用。

### 13.3 ★ 生命周期是生死线（特别注意）

opaque + finalizer 的自动回收是 QuickJS 白送的；换 handle 表后必须自己回答三个问题，
**任何一个答错都是泄漏或悬垂**：

1. **谁拥有对象**：C++ 侧持有（`unique_ptr` 表）还是 JS 侧持有（finalizer 注销）？
   两边都要的话必须显式区分所有权标记，不能默认。
2. **JS 对象被 GC 后 handle 还留在表里** → 泄漏。必须挂钩 GC：
   JS 侧持有的对象，其 JS 包装对象的 finalizer 里 `table.erase(handle)`；
   C++ 侧持有的对象不自动注销（显式 close）。
3. **close/注销后 JS 仍调用** → 悬垂 handle。查表失败时报错（不可静默）；
   **id 复用是最危险的**——释放的 handle 被新对象复用后，旧引用会静默操作到新对象。
   对策：单调递增 id + 世代计数（generation），或释放后 id 永不复用（表槽位 tombstone）。

建议组合：**JS 侧持有时 finalizer 自动注销 + C++ 侧持有显式 close + 单调 id 不复用**。

### 13.4 跨 Runtime 调用：句柄只是身份，操作要回原 Runtime

handle 跨 Runtime 传过去，**对象仍只活在创建它的 Runtime**（线程亲和，§1）。
"B 里操作 A 的对象"需要**代理（stub）**模式：B 建轻量代理对象，方法调用经 channel
转发回 A 执行、结果回传——这是完整子系统，与句柄表本身解耦，按需再做。

### 13.5 与 M5 的关系

句柄表 + 对象归属追踪（§13.3）与 M5 的 gc_mark/trace 工具共享同一套"对象图可见性"基础设施；
若将来做 gc_mark，先落句柄表更顺。

## 附：关键外部 API 速查（已核实）
| API | 位置 | 用途 |
|---|---|---|
| `JS_NewCClosure` | quickjs.h:1338 | 带 finalizer 的闭包函数对象（绑定层核心） |
| `JS_NewCFunction2` + `JS_CFUNC_constructor` | quickjs.h:1323 | 类构造器 |
| `JS_SetConstructor` / `JS_SetClassProto` / `JS_NewObjectProtoClass` / `JS_SetOpaque` | :1358/:541/:926/:1061 | 类注册四步 |
| `JS_NewClassID(rt,&id)` | :708 | ng 版：per-runtime、幂等 |
| `JS_GetOpaque2` | :1063 | 取 this 原生指针（自动 TypeError） |
| `JS_DefinePropertyGetSet` | :1057 | getter/setter |
| `JS_NewPromiseCapability` | :1143 | promise + resolve/reject |
| `JS_ExecutePendingJob` / `JS_EnqueueJob` | :1245/:1240 | job 泵（须 JS 线程） |
| `JS_SetHostPromiseRejectionTracker` | :1177 | 未处理 rejection 监控 |
| `exec::asio::use_sender` | stdexec `exec/asio/use_sender.hpp:220` | asio op → sender |
| `exec::asio::asio_thread_pool` | `exec/asio/asio_thread_pool.hpp` | asio 版线程池（offload 用） |
| `stdexec::task<T>`（`std::exec::task`）/ `stdexec::counting_scope` | `stdexec/__detail/__task.hpp` / `stdexec/__detail/__counting_scopes.hpp` | 协程类型 / 结构化并发 |
