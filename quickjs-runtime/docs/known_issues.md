# qjsbind 已知问题与坑（Known Issues）

> 集中收录 qjsbind 实现与使用中遇到的已知问题、编译器怪癖、引擎行为差异与设计限制。
> 设计文档 `qjs_cpp_binding_design.md` §10 是精简版；本文档是完整台账，**新增问题一律追加到这里**。

## 维护约定

- 每条问题一个编号 `KI-xxx`，按分类前缀分段：`01-09` 编译器/语言语义 / `10-19` quickjs-ng / `20-29` stdexec / `30-39` qjsbind 设计限制 / `40+` 工具链与环境。
- 风险标记：★ = 高（会静默出错/难排查），● = 中，○ = 低（文档性）。
- 状态：`已规避`（有明确规避法并已实现）/ `设计规避`（设计层面避免触碰）/ `待验证`（依赖特定版本/场景，未实测）。
- 修改任何实现时，若命中下表问题，先更新状态或复现条件。

---

## 01–09 编译器 / 语言语义（MSVC 环境实测）

### KI-001 ★ 协程 lambda 捕获悬垂（生命周期问题，非 MSVC bug）
- **现象**：带捕获的协程 lambda 在 `co_await` 恢复后读到垃圾值/崩溃（最早在 MSVC 下发现，曾误判为编译器参数损坏缺陷）。
- **原因**：标准语义，与编译器无关。**协程只把形参拷进协程帧**（值形参因此安全；引用形参只存引用本身）；lambda 的捕获存在闭包对象里、**不进帧**——`[data] { ... }` 的闭包是临时对象，协程首次挂起后随完整表达式结束而析构，恢复时再访问捕获即 use-after-free。成员协程的 `this` 同理（隐式对象形参不进帧）。
- **规避**：**一切协程写成独立的自由函数**；需要"方法"语义时用自由函数 + `qjs::This<T>` 糖。临时写 lambda 也行，但**禁止捕获**，值一律走（值）形参并立即调用：
  ```cpp
  // ✗ data 随闭包临时对象析构而悬垂，恢复后读到垃圾值
  auto bad = [data]() -> task<int> { co_await cb(data); };

  // ✓ 值形参拷进协程帧（自由函数写法同理安全）
  auto ok = [](int data) -> task<int> { co_await cb(data); }(data);
  ```
- **状态**：设计规避（绑定层把自由函数当一等公民，天然兼容）。

### KI-002 ● 显式特化的成员函数体非惰性
- **现象**：`template<> struct js_convert<const char*> { ... static_assert(...) }` 在**头文件被 include 时立即报错**，与是否调用无关。
- **原因**：显式特化（`template<>`）的成员函数是普通代码（非模板），函数体在定义处立即编译；非依赖条件的 `static_assert` 立刻求值。
- **规避**：禁止入参的 `from_js` 用 `= delete` 表达（只在真正调用时报错）；类模板主模板的成员（惰性）才可用 `static_assert`。
- **状态**：已规避（M1 实测）。

### KI-003 ● `std::is_invocable_v` 是无参调用检测
- **现象**：`std::is_invocable_v<double(*)(double,double)>` 返回 **false**（不是 true）。
- **原因**：`is_invocable_v<F>` 检查"能否以**零参数**调用 F"；带参函数指针无参不可调。
- **规避**：检测"可调用对象"用 `std::is_function_v<std::remove_pointer_t<D>> || requires { &D::operator(); }`，不要用 `is_invocable_v`。
- **状态**：已规避（M1 实测，`Object::set` 自动包装处）。

### KI-003b ★ MSVC 实例化 `if constexpr` 的 discarded 分支
- **现象**：`if constexpr` 未选中的分支里的模板代码仍被实例化——对某些类型组合编译失败（如成员分支对非成员函数注入 self）。
- **原因**：MSVC 对 discarded 分支的实例化行为（非标准）。
- **规避**：把"按类型分派"改成**重载决议**（tag dispatch），不依赖 if constexpr 剪枝（function.hpp 的 `call_dispatch` 四重载）。
- **状态**：已规避（M2 实测）。

### KI-003c ● `std::make_tuple` 会把左值引用实参 decay 成值
- **现象**：bound class 引用参数（`Point&`）被 make_tuple 拷贝成值，`T&` 形参绑定失败（invoke 无匹配重载）。
- **原因**：`make_tuple` 对实参做 decay。
- **规避**：tuple 用 `tuple_storage_t<A>` 定制存储类型直接构造（引用参数保留引用、值参数存值、string_view 存 std::string），不要用 make_tuple。
- **状态**：已规避（M2 实测，function.hpp）。

### KI-004 ○ NTTP 函数指针是 const 对象
- **现象**：`c_closure_entry<F>` 里把 NTTP `F` 传给非 const `F&` 参数编译失败。
- **原因**：NTTP 是 constexpr 对象（const 限定），绑定不了非 const 左值引用。
- **规避**：本地拷贝 `auto fn = F;` 再传。
- **状态**：已规避（M1 实测，`func<&f>()` 入口）。

### KI-005 ○ 空参数包展开成零长 C 数组
- **现象**：`constexpr bool arr[] = { (expr)... };` 在参数包为空（如 `void()` 函数）时是零长数组，C++ 禁止。
- **原因**：数组大小必须是常量且 > 0。
- **规避**：用 `std::array<bool, sizeof...(A)>`（允许零长）。
- **状态**：已规避（M1 实测，`arity_info` 处）。

---

## 10–19 quickjs-ng

### KI-010 ● `JS_GetOwnPropertyNames` 签名与上游不同
- **现象**：ng 版返回 `JSPropertyEnum*` 数组（`{bool is_enumerable; JSAtom atom;}`），不是上游的 `JSValue` 数组；配套 `JS_FreePropertyEnum(ctx, tab, len)` 释放。
- **原因**：quickjs-ng 改了枚举 API 形态。
- **规避**：枚举对象属性（`js_convert<map>::from_js`）用新签名；`JS_AtomToCStringLen` 取 key（返回指针配 `JS_FreeCString`）。
- **状态**：已规避（M1 实现）。
- **注意**：`JS_FreePropertyEnum` 是否内部 free atoms 未在本地确认（无源码），若出现 atom 泄漏检查此点。

### KI-011 ○ `JS_ToInt32(Symbol)` 不抛异常
- **现象**：`JS_ToInt32(ctx, &r, symbol)` 静默成功（返回 0），不产生 JS 异常。
- **原因**：ng 对 Symbol→number 的转换语义（返回 NaN→ToInt32→0），不走异常路径。
- **规避**：测试/用户代码不要依赖 Symbol→int 抛 TypeError；要测转换失败用无 `toString/valueOf` 的对象（如 `Object.create(null)`）走字符串路径。
- **状态**：已规避（M1 测试改用 `Object.create(null)`）。

### KI-012 ● `JS_ToCStringLen2` 返回指针必须配 `JS_FreeCString`
- **现象**：返回指针指向 runtime 内部缓冲，不 free 则泄漏，跨调用持有则悬垂。
- **规避**：转换层一律立即拷贝成 `std::string` 再 `JS_FreeCString`。
- **状态**：设计规避（§2）。

### KI-013 ● finalizer 没有 ctx
- **现象**：`JSClassFinalizer(JSRuntime*, JSValueConst)`（quickjs.h:654）无 `JSContext*`——不能执行 JS、不能 `JS_FreeValue`（用 `JS_FreeValueRT`），且取不到调用方 ctx。
- **规避**：finalizer 内从 runtime opaque 反查 `class_registry` 拿 class id，再 `JS_GetOpaque` 取原生指针析构；持有 JS 值的对象用 `gc_mark` + JS 线程析构队列（M2 处理）。
- **状态**：已规避（M1 实现，registry 生命周期由 Runtime 成员顺序保证）。

### KI-013b ★ `JS_NewClass` 保存 class_def 指针（不拷贝）
- **现象**：传局部 `JSClassDef` 给 `JS_NewClass`，注册后局部变量析构，GC/FreeRuntime 时崩溃（`ref_count` 断言或随机崩）。
- **原因**：ng 的 `JS_NewClass` 保存 def 指针；M1 用 `static` 局部恰好安全，M2 改动态 name 后暴露。
- **规避**：`JSClassDef` 存入 registry 的稳定容器（`std::map` 节点地址稳定），生命周期 = registry 生命周期。
- **状态**：已规避（M2 实测，context.hpp）。

### KI-013c ★ `JS_SetClassProto` 是转移语义（set_value，不 dup）
- **现象**：`JS_SetClassProto(ctx, id, proto)` 后自己还持有 proto 并 free → 引擎的 class_proto[id] 悬垂 → GC 断言崩溃。
- **原因**：`JS_SetClassProto` 用 `set_value`（转移所有权，quickjs.c:2579），与 `JS_SetConstructor`（内部 `js_dup`，quickjs.c:1320）不同。
- **规避**：传给 `JS_SetClassProto` 前先 `JS_DupValue`；对照表：`JS_SetPropertyStr`/`JS_SetPropertyUint32`/`JS_DefinePropertyGetSet` 转移，`JS_DefineProperty`/`JS_SetConstructor` 借用（内部 dup）。
- **状态**：已规避（M2 实测，class.hpp）。

### KI-013d ● `JS_DefinePropertyGetSet` 强制 HAS_GET|HAS_SET
- **现象**：getter-only / setter-only 分开注册时互相覆盖（第二次调用把对方清成 NULL）。
- **原因**：`JS_DefinePropertyGetSet` 无条件 `flags | JS_PROP_HAS_GET | JS_PROP_HAS_SET`（quickjs.c:11127）。
- **规避**：需要单边 getter/setter 时用底层 `JS_DefineProperty`（借用语义 + 可控 flags）。
- **状态**：已规避（M2 实测，class.hpp）。

### KI-014 ● class id 是 per-runtime 的
- **现象**：`JS_NewClassID(rt, &id)` per-runtime 分配；进程级 static 存 `JSClassID` 在多 runtime 下会撞/失效。
- **规避**：每 runtime 一张注册表（`class_registry`），禁进程级 static。
- **状态**：设计规避（§6.1）。

### KI-015 ○ `JS_CHECK_JSVALUE` 不产生可运行代码
- **现象**：该宏把 `JSValue` 变成指针类型做编译期所有权检查，头文件注释明确 "does not produce working code"。
- **规避**：只在静态检查构建开；运行测试用正常构建。
- **状态**：设计规避（§2）。

### KI-016 ○ 版本差异：vcpkg 装 0.15.1 vs 设计文档锚定 0.16.1
- **现象**：文档附录行号整体偏移约 40 行（如 `JS_NewCClosure` 文档 :1337 vs 0.15.1 头文件 :1298）。
- **规避**：实现以 `third_party/vcpkg/packages/quickjs-ng_*/include/quickjs.h` 实际签名为准；升级 quickjs-ng 后重跑测试。
- **状态**：已规避（M1 按实际头文件实现）。

---

## 20–29 stdexec

### KI-020 ★ `async_scope` 没有 `empty()` 查询；`on_empty()` 是边沿一次性信号
- **现象**：想把 `on_empty()` 当"当前是否空闲"查询用会出错——标志置位后若又 spawn 新任务，scope 非空但标志仍为 true。
- **原因**：`when_empty` opstate 在 `active != 0` 时挂 waiters 队列，仅 `active` 从 1→0 **变空瞬间**通知一次；它不反映当前状态。
- **规避**：退出判据用 Runtime 自维护的 `pending_` 计数（spawn +1、三路收尾 -1，可查询的当前状态），不用 `on_empty` 标志（设计文档 §8.2）。
- **状态**：设计规避（源码已核实）。

### KI-021 ★ `when_empty` opstate 挂队列期间析构会悬垂
- **现象**：`__task` 无自摘除逻辑；opstate 仍挂 waiters 队列时被析构，变空通知时 UB。
- **规避**：若用探针方案（备选），只能"触发后重连"（`scope_empty_ == false` 时绝不碰探针对象）。
- **状态**：设计规避（备选方案注明）。

### KI-022 ● spawn 链尾必须消化 error/stopped 通道且 `noexcept`
- **现象**：`stdexec::spawn` 对会失败的 sender 编译期拒绝；`exec::async_scope::spawn` 不拦但出错直接 `std::terminate()`。
- **规避**：链尾 `then/upon_error/upon_stopped` 三路全覆盖，收尾 lambda 标 `noexcept`。
- **状态**：设计规避（§5.3）。

### KI-023 ● `exec::task` 需要 start scheduler
- **现象**：脱离 `scope.spawn(sndr, env)` / `sync_wait` 环境裸 connect 一个 task 会 static_assert 失败。
- **规避**：`spawn(sndr, env)` 的 env 注入 `get_start_scheduler`；绑定层内已处理。
- **状态**：设计规避（§5.3，M3 实现）。

### KI-026 ★ JS 线程亲和是硬约束：跨线程 JS 操作导致栈损坏崩溃
- **现象**：协程在**主线程** spawn（JS 操作主线程），异步驱动线程（t 线程）run() 后又在 t 线程 `ctx.eval(...)`——`run()` 正常返回（pending==0）后 t 线程崩（`abort`，EXIT=3），且完全随机/时序相关（等价的"纯 C++ 无 eval"流程不崩）。
- **原因**：违反设计文档 §1 不变量——一个 JSRuntime 只被一根线程触碰；quickjs 的栈/异常状态（stack top 等）绑定线程，跨线程顺序访问也是 UB。
- **规避**：**JS 操作全部在 JS 线程**。服务模式：`run()` 在 JS 线程跑，`stop()` 从任意其他线程（只碰 io_，线程安全）；测试与宿主代码不得在驱动线程做任何 JS 调用。
- **状态**：实测确认（M3 调试中发现；修正测试线程模型后稳定 5/5）。

### KI-027 ★ `exec::task` 的 stop 语义：挂起时 stop → 协程 set_stopped（体不再继续）
- **现象**：协程在 timer await 挂起时收到 stop（`scope_.request_stop()`），**协程体不再恢复**（循环退出代码不执行），task 以 `set_stopped` 完成；"轮询 `stop.stop_requested()` 提前 co_return"的协作式写法到不了 co_return。
- **原因**：task 的 `__default_awaiter_context` 把父 stop 转发到内部 `__stop_source_`（task.hpp:250/311），恢复时走 stopped 路径。
- **规避**：取消结算统一为 **AbortError reject**（upon_stopped → reject AbortError，设计文档 §5.5/§8.3 实测吻合）；要"提前完成并返回值"需在**不被 task 拦截**的位置检查 stop（如子 sender 内部）。
- **状态**：实测确认（M3）。

### KI-028 ○ `exec::asio::use_sender` 不桥接 stdexec stop token
- **现象**：`timer.async_wait(use_sender)` 不响应 stdexec 的 stop（没有 cancellation_slot ↔ stop token 的桥接代码）；`request_stop()` 不会取消 asio 操作。
- **规避**：取消是协作式的——任务自己感知 stop（或等待自然完成）；需要硬取消时自行桥接 asio cancellation_slot。
- **状态**：源码核实（use_sender.hpp 无 stop 桥接，M3）。

### KI-029 ★ `JS_SetModuleExport` 是转移语义；临时 RAII 的 `.raw()` 是悬垂引用
- **现象**：`Module::function()` 里 `add_export(name, func(ctx, f, name).raw())`——`func()` 返回的 `Function` 临时对象析构时把 JSValue free 掉，`exports_` 里存的是已释放值；`import { x }`（绑定/star）触发 init 回调里 `JS_DupValue(已释放)` → use-after-free 段错误。`import 'm'`（bare、不解析导出）不触发，所以表现为"bare 过、绑定崩"。
- **原因**：`JS_SetModuleExport` 把 val 转移给模块（`set_value(var_ref->pvalue, val)`，quickjs.c:29874）；`Value::raw()` 只是借用，临时对象析构即释放。
- **规避**：导出时用 `take()` 转移所有权进 `exports_`（init 里再 dup 一份给引擎，本侧保留到 Module 析构）。
- **状态**：已修复（M4）。

### KI-030 ★ `JS_EXCEPTION` 只是返回 tag，真错误在 `current_exception`
- **现象**：`JS_Call`/`JS_NewObjectProtoClass` 失败返回 `JS_EXCEPTION`（原子值），真正的 Error 对象在 `rt->current_exception`。若 `throw js_error(ctx, JS_EXCEPTION)`，thunk 边界 `JS_Throw(ctx, JS_EXCEPTION)` 内部先 `JS_FreeValue(current_exception)` 把真错误释放（quickjs.c:7597），JS 侧 `catch (e)` 拿到的是 `JS_EXCEPTION` 原子值——`e.message` 再次抛异常，try/catch 失灵。
- **规避**：所有 `js_error` 构造必须 `JS_GetException(ctx)` 取走真异常值（`Function::call` 与 `class_` 失败路径三处已修）。
- **状态**：已修复（M4）。

### KI-031 ○ TLS 绑定时机：协程体在 spawn（eval）时即同步执行到第一个挂起点
- **现象**：`current_io()`（TLS 访问器）只在 `run()` 里绑定——但异步函数被 JS 调用（eval 内 spawn）时，协程体**立即同步执行到第一个 `co_await`**，此时若用 `current_io()` 会抛 "no runtime bound"（异步函数 reject）。
- **规避**：`Runtime` 构造时绑定 TLS（构造线程即 JS 线程，多运行时每线程各绑一个）；`run()` 里再绑定幂等并恢复。
- **状态**：已修复（M4）。

### KI-032 ○ `JS_NewCModule` 的 init 回调无 opaque 参数
- **现象**：init 回调签名只有 `(JSContext*, JSModuleDef*)`，拿不到 Module 实例；模块实例化（import 触发）与 Module 构造不在同一调用栈。
- **规避**：静态注册表（`JSModuleDef* → Module*`，互斥锁保护）反查；导出值在 init 里逐项 `JS_SetModuleExport`（dup 传入）。
- **状态**：设计规避（M4）。

### KI-024 ○ vcpkg 版 stdexec 无 `upon_done` 单点收尾原语
- **现象**：`exec/` 目录无 `upon_done.hpp`；`completion_behavior.hpp` 只是查询完成行为，不是转换原语。
- **规避**：三路分别收尾（`then`/`upon_error`/`upon_stopped`）是最简写法。
- **状态**：已规避（M1 核实）。

### KI-025 ○ `reschedule_coroutine_on` 类型擦除限制
- **现象**：把 scheduler 擦除进 `any_scheduler`，个别 scheduler 类型擦不进去编译失败（Clang 下 `static_thread_pool` 有案例）。
- **规避**：稳妥选择 io scheduler 或 `single_thread_context` 的 scheduler；MSVC 行为待验证。
- **状态**：待验证（M3 涉及）。

---

## 30–39 qjsbind 设计限制（有意为之）

### KI-030 ○ `Runtime` 不可移动/复制
- **原因**：`asio::io_context`、`exec::async_scope`（内部含 mutex）均不可移动。
- **规避**：多 Runtime 场景用 `std::unique_ptr<Runtime>` 或栈上持有。
- **状态**：设计规避（§2）。

### KI-031 ● `const char*` 禁止作为入参
- **原因**：`from_js` 返回指向引擎缓冲的指针，函数返回后悬垂。
- **规避**：入参用 `std::string`；`const char*` 只支持 `to_js`（返回侧），`from_js` 为 `= delete`（编译期拒绝）。
- **状态**：设计规避（§3.1）。

### KI-032 ● `std::string_view` 入参仅调用帧内有效
- **原因**：视图指向 thunk 转换出的临时字符串。
- **规避**：thunk 的 `convert_arg` 特化把 `string_view` 参数转成 `std::string` 放进 tuple（生命周期由 tuple 保证）；不要直接调 `js_convert<string_view>::from_js`（已 delete）。
- **状态**：设计规避（§3.1，M1 实现）。

### KI-033 ○ 成员函数指针绑定 M1 拒绝
- **原因**：成员指针需要 this 注入，依赖 class 系统（M2）。
- **规避**：M1 用 `func()` 绑定成员指针会 static_assert 拒绝；M2 `class_<T>::method()` 启用。
- **状态**：设计规避（M1）。

### KI-034 ○ `Opt<T>` / `Rest<T>` 必须是尾参数
- **原因**：arity 折叠依赖"首个 Opt/Rest 之后无普通参数"。
- **规避**：编译期 `static_assert` 拦截（`arity_info::valid_order`）。
- **状态**：设计规避（§4.2，M1 实现）。

### KI-035 ★ JSValue/JSContext 只在 JS 线程触碰
- **原因**：quickjs-ng 单 runtime 单线程模型，`JS_EnqueueJob` 无锁。
- **规避**：跨线程只递原生数据（channel）；必要时先 `JS_UpdateStackTop(rt)`；debug 构建线程亲和断言。
- **状态**：设计规避（§1 不变量 2）。

---

## 40+ 工具链与构建

### KI-040 ● 构建环境：pixi cmake/ninja + 系统 MSVC
- **现象**：`cmake` 不在系统 PATH（在 `.pixi/envs/default/Library/bin/`）；编译器必须是系统 MSVC（`scripts/vs_env.py` 经 vcvars64.bat 注入）。
- **规避**：统一走 `python scripts/configure.py / build.py / test.py`（内部 `vs_env.run_in_vs_env`）。
- **状态**：已规避（M1 验证）。

### KI-041 ○ vcpkg 首次配置/重建耗时
- **现象**：CMakeLists 变更会触发 "Running vcpkg install"，首次或清缓存后需重建全部依赖（实测约 1.3 min + 编译）。
- **规避**：依赖已安装到 `third_party/vcpkg/packages` 并有二进制缓存；日常增量构建只编改动的 TU。
- **状态**：已规避（M1 实测）。

---

## 附录：M1 实现中解决的编译坑速查（对应上面条目）

| 编译错误 | 根因 | 条目 |
|---|---|---|
| C2338 static assertion failed（include 即报） | 显式特化成员函数体非惰性 | KI-002 |
| 函数指针走了值转换分支（deleted to_js 报错） | `is_invocable_v` 无参检测误判 | KI-003 |
| 无法将函数指针转换为 `F&` | NTTP const 对象 | KI-004 |
| 不能分配常量大小为 0 的数组 | 空参数包 → 零长数组 | KI-005 |
| lambda 被 static_assert "M1 暂不支持成员函数指针" | lambda operator() 提取误判 is_member | （function_traits 主模板显式置 false） |
| Opt/Rest 参数错位（Ctx 不消耗 argv） | argv 游标用了参数索引 | （arity_info::offsets 编译期计算） |

## 50+ fetch / wpt 里程碑（2026-08-07 记录）

### KI-050 ● 批量替换 JS_ThrowTypeError 时 throw 脱离 if 控制流
- **现象**：`HeadersInvalidName` 返回 `"undefined"`；多个测试 eval 无条件异常。
- **原因**：脚本把 `if (cond) JS_ThrowTypeError(...);` 单语句替换成两行组合时，`throw qjs::js_error(...)` 落到了 if 外（无条件执行，包装 `JS_UNINITIALIZED` 伪异常）。
- **规避**：web 层统一走 `errors.hpp::throw_type_error`（`[[noreturn]]` 单语句，不可能被控制流拆散）。
- **状态**：已规避（wpt 30/30 验证）。

### KI-051 ★ MSVC 协程异常传播对 move-only 异常类型损坏
- **现象**：exec::task 协程体抛 `js_error`（move-only）→ SEH 0xc0000005（崩溃点在 throw 语句展开）。
- **原因**：MSVC 的异常对象存储/展开与协程帧的交互缺陷（`std::runtime_error` 可拷贝则正常，对照实验证实）。
- **规避**：`qjs::js_error` 加拷贝构造（`JS_DupValue` 深拷贝语义）。
- **状态**：已规避（ResponseConsume 全绿）。

### KI-052 ● `parse_uri_reference` 的 url_view 借用输入字符串
- **现象**：宽松解析（relax_url_chars）后 `result<url_view>` 悬垂 → boost 断言失败/崩溃（Debug 构建表现为弹窗挂起）。
- **原因**：url_view 不拥有字符串；relax 临时 `std::string` 在 if 块内析构。
- **规避**：relax 结果提升到函数作用域（`relaxed_storage`），url_view 使用完再销毁。
- **状态**：已规避。

### KI-053 ● JS 侧补丁字符串禁止 `//` 行注释
- **现象**：Headers 迭代器补丁"部分生效"（entries/keys/values 未覆盖，forEach 抛 ReferenceError）。
- **原因**：C++ 字符串拼接无换行，`//` 注释吞掉后续全部代码。
- **规避**：补丁字符串只用 `/* */` 或不用注释。
- **状态**：已规避。

### KI-054 ● Windows 环境隐形坑（fetch 里程碑实测）
- `std::ifstream` 打不开混合分隔符路径（`D:\...
untime/third_party/...`，errno=22）→ 用 `std::fopen`
- Windows 被拒端口（127.0.0.1:1 等）静默丢包，connect 挂起 → 必须实现 blocked-port 构造检查（fetch 规范）
- python `open("w")` 在 Windows 写 CRLF → `std::getline` 残留 `\r` 污染 meta 路径 → 写清单用 `newline="
"` + 解析端防御 strip
- **状态**：已规避（wpt_runner/analyze_wpt.py/http_client 均含规避代码）。

### KI-055 ○ wpt 精选子集 28 个 expected（v1 已知限制）
- 裸 `%` 在 query 的 WHATWG 保留语义（boost 无法表示）：1 个
- Request/Response 的 `blob()` 未实现（body 消费仅 text/json/arrayBuffer/formData）：4 个
- Headers 实例构造走内部拷贝（不走自定义迭代器）：1 个
- forbidden 请求头：参照 Node(undici) 而非浏览器，referer/cookie/origin 等用户自定义头正常发送（wpt 按浏览器语义期望不发送）：22 个
- **状态**：设计偏离（Node 行为）或设计规避（shim 内登记 expected，套件保持 0 fail）。
- **历史**：活迭代器、`data:` URL fetch、Blob/FormData、integrity、URLSearchParams 双向联动均已实现，从 expected 移除。

### KI-056 ★ parse_multipart 死循环：跳过畸形 part 时位置未推进
- **现象**：`Response.formData()` 遇到 delimiter 后非 `\r\n` 的输入（如孤立 `\n`、`\r`、垃圾字节）时卡死——wpt response-form-data.html 第 3 个 promise_test 必现；表象是"第 3 次 spawn 卡死"，实为该用例的输入触发。
- **原因**：旧解析器对无 `\r\n\r\n` 头体分隔的 part 走 `continue`，但找下一个 boundary 的位置变量未更新（`d = next` 在循环尾被 `continue` 跳过），原地死循环。
- **规避**：按 HTML 标准 multipart/form-data parsing algorithm 重写——pos 每轮严格递增保证终止；delimiter 后仅允许 transport padding（tab/space）+ `\r\n`，结束标记 `--` 之后必须到输入末尾；结构不合法返回 `std::nullopt`，调用方 reject TypeError。
- **状态**：已修复（wpt response-form-data.html 14/14 全过）。
- **教训**："第 N 次并发操作卡死"未必是并发/异步层问题——先把每个操作换成相同输入做对照，排除数据相关的确定性死循环，再往 stdexec/调度层挖。

### KI-057 ★ fetch::Client 生命周期三连约束（构造/析构线程 + 与 Runtime 的先后顺序）
- **现象**：把 `fetch::Client` 挂到 HostRuntime 实例时三种踩法三种死法——
  调用线程构造抛"当前线程未设置 io_context"（或绑到别的线程的 io，任务静默挂死）；
  调用线程析构触发 `DnsResolver` 的 `assert_io_thread` 断言 abort；
  实例 Runtime 销毁后再析构 Client → SEH 0xc0000005（池内 socket/beast stream
  访问已死的 io_context）。
- **原因**：`Client` 构造时从线程 thread_local 取 io_context（`fetch::thread_io()`）；
  `PooledTransport`/`DnsResolver` 的缓存无锁、仅 io 线程访问（首访问线程原子记录）；
  池内连接对象的生命周期依附实例 io。
- **规避**：用 `HostRuntime::Options{.enable_fetch = true}` 内建管理——Client 在
  实例线程构造（init/reload）、实例线程析构且先于实例 Runtime（`runner → client → rt`
  顺序），reload 随旧 Runtime 回收重建。手工挂接（TaskPool / 自定义宿主）仍须自己
  遵守同一顺序：实例线程建、实例线程拆、先于 Runtime 拆。
- **状态**：已规避（HostRuntime 内建；压测 ConcurrentFetchStress 实测三种错序的
  崩溃形态后收敛）。

## 60+ cheerio → BreezeHtml 只读子集（2026-08-08 重构）

> 重构后：`include/qjsbind/cheerio/` 只提供 **BreezeHtml 只读选择集 API**
> （cheerio 子集），全部在 lexbor C 树上实现，QuickJS 侧只有不可变选择集句柄。
> JS bundle 方案（`js/` 全量移植 + `cheerio_js_bundle.hpp`）与官方测试套件
> （`tests/cheerio/`、spec runner）已随重构删除。
> API：`BreezeHtml.load(html) -> $`（可调用）；`$(selector)` / `$(selection)`；
> 遍历 find/first/last/eq/closest/parent/children/siblings/next/prev/filter/
> has/slice/index/is，读取 attr/text/html/val，迭代 toArray/each/map
> （map 返回 `{ length, get() }`）。
> 无 DOM 修改能力（append/remove/attr 写等明确不做）——需要时请引入完整 cheerio。

### KI-060 ○ cheerio.load(options)（已关闭：设计如此）
- 只读子集只支持 `BreezeHtml.load(html)`，无 options 参数。

### KI-061 ○ map() 回调返回任意 JS 值（已修复）
- map 结果为普通 JS 对象 `{ length, get() }`（结果数组独立于选择集存储），
  回调可返回任意 JS 值（null/undefined 跳过，与 cheerio 一致）。

### KI-062 ○ find($) 语义差异（已关闭：只接受字符串）
- find 只接受字符串选择器，官方 `find($)` 的内部实现怪癖不再涉及。

### KI-063 ○ manipulation / attributes 方法面（已关闭：明确不做）
- append/remove/wrap/attr 写/addClass 等修改能力不属于本子集。

### KI-064 ● lexbor HTML5 嵌套修正与 htmlparser2 不一致
- **现象**：`<ul><ul>`、`<tr>` 等非法嵌套在 lexbor 按 HTML5 解析器修正（隐式闭合/移出），cheerio 官方基于 htmlparser2 宽容解析——少数场景结果不同。
- **原因**：两种解析器对畸形 HTML 的规范化策略不同。
- **规避**：尽量用合法 HTML。
- **状态**：已知差异。

### KI-065 ★ qjs.lib 含临时 DIAG 打印（构建产物残留，待重建）
- **现象**：为诊断泄漏，临时修改过 quickjs.c（`free_cycles` 泄漏路径加 dump）并重编 qjs.lib；**源码已还原，但 lib 未重编**。
- **影响**：仅在 Runtime 销毁且检测到残留对象时向 stdout 打印对象信息；功能与正确性无影响。
- **状态**：待重建（需 vcvars64 环境重编 vcpkg quickjs-ng，或下次 vcpkg 重建自动恢复）。
