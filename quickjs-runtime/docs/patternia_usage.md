# Patternia 使用指南

> 本文档解析 `third_party/patternia`（Patternia v0.9.4）的用法。
> Patternia 是一个 header-only 的现代 C++ 模式匹配（pattern matching）库，
> 上游仓库：<https://github.com/SentoMK/patternia>，许可证见 `third_party/patternia/LICENSE`。

---

## 1. 它是什么

Patternia 把「模式匹配」做成一个**表达式**，核心形态只有一条管道：

```cpp
match(subject) | on(
  pattern_1 >> handler_1,
  pattern_2 >> handler_2,
  _         >> fallback      // 必须有的兜底分支
);
```

特性一览：

- C++17 起即可使用（本项目是 C++23，完全兼容）。
- **header-only**，零外部依赖，不引入任何链接产物。
- 字面量匹配、结构体解构、`std::variant` 分发统一在一个 DSL 里。
- 绑定（binding）是显式的：`$` / `$(...)`，不存在隐式绑定。
- 零开销目标：无 RTTI、无虚函数分发、无堆分配；字面量/variant 场景可降级为
  跳转表（jump table）级别的静态分发。
- 匹配是**表达式**而不是语句：可以直接 `return match(...) | on(...)`。
- 穷尽性在编译期检查：缺兜底分支直接编译失败。

它的设计约束（有意为之的「窄」）：

1. 被匹配值（subject）必须是**左值**。
2. case 按源码顺序匹配，**first-match-wins**（先匹配到的分支胜出）。
3. `on(...)` 的**最后一个 case 必须是通配符 `_` 兜底**，否则编译报错。
4. 没有链式 builder 之类的延迟构造，`match | on` 立即求值。

---

## 2. 在本项目中如何集成

当前状态：仓库已把 patternia 整体 vendor 在 `third_party/patternia/`，
但**根 `CMakeLists.txt` 尚未接入**（没有 `add_subdirectory`，src/ 里也还没有使用）。

两种接入方式，任选其一：

### 方式 A：add_subdirectory（推荐）

patternia 自带 CMake 工程，导出 INTERFACE target `patternia::patternia`：

```cmake
# 根 CMakeLists.txt
add_subdirectory(third_party/patternia)

target_link_libraries(quickjs_runtime PRIVATE patternia::patternia)
# 或挂到某个库上，例如 fetchcore：
target_link_libraries(fetchcore PUBLIC patternia::patternia)
```

注意：patternia 的 CMakeLists 里有一些可选子工程（samples/tests/bench），
由 `PTN_BUILD_SAMPLES` / `PTN_BUILD_TESTS` 等选项控制，默认关闭，不会污染主工程构建。

### 方式 B：只加头文件路径（最轻量）

header-only 库，直接把 include 目录加进去就能用：

```cmake
target_include_directories(fetchcore PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/patternia/include
)
```

代码里只需要：

```cpp
#include <ptn/patternia.hpp>
```

---

## 3. 快速上手

### 3.1 最小例子：值分发

```cpp
#include <ptn/patternia.hpp>

int classify(int x) {
  using namespace ptn;

  return match(x) | on(
    lit(0) >> 0,      // 运行时字面量匹配
    lit(1) >> 1,
    _      >> -1      // 通配符兜底（必须有）
  );
}
```

读法：

1. `match(x)` 建立匹配上下文（x 必须是左值）；
2. `on(...)` 提供有序的 case 列表；
3. `pattern >> handler` 定义一条 case；
4. 从上到下匹配，第一个命中的分支执行并返回；
5. `_` 是兜底的通配模式。

### 3.2 handler 的两种形态

`>>` 右侧可以是**值**，也可以是**可调用对象**：

```cpp
match(x) | on(
  lit(1) >> 100,                              // 直接给值
  lit(2) >> [] { return compute(); },         // 零参 lambda（pattern 无绑定时）
  $      >> [](int v) { return v * 2; }       // 带参 lambda（参数来自绑定）
);
```

- 作为表达式使用时，**所有分支的返回类型必须一致**（或有公共类型），否则编译失败。
- 只做副作用时（handler 都返回 void），可以当语句用。

---

## 4. 模式（Pattern）详解

所有公共符号都在 `namespace ptn` 下。

### 4.1 字面量模式：`lit` / `val` / `lit_ci`

| 写法 | 语义 | 备注 |
|---|---|---|
| `lit(v)` | 运行时字面量相等匹配 | v 可以是运行期变量 |
| `val<V>` | **编译期**字面量匹配 | V 必须是常量表达式；利于生成跳转表 |
| `lit_ci(s)` | ASCII 大小写不敏感的字符串匹配 | 如 `lit_ci("hello")` |

```cpp
match(x) | on(
  val<1> >> "one",        // 编译期常量，可静态分发
  val<2> >> "two",
  _      >> "other"
);

int target = get_target();
match(x) | on(
  lit(target) >> true,    // 运行期值必须用 lit()，val<target> 编译不过
  _           >> false
);

match(s) | on(
  lit_ci("yes") >> 1,
  _             >> 0
);
```

### 4.2 绑定模式：`$` 与 `$(...)`

Patternia 的绑定是显式的：**没有任何模式会隐式绑定值**。

- `$` —— 绑定**整个** subject；
- `$(subpattern)` —— 在子模式匹配成功的前提下，绑定子模式提取出的值。

```cpp
match(x) | on(
  $ >> [](int v) { return v; },   // 绑定整个 x
  _ >> 0
);

using Value = std::variant<int, std::string>;
match(v) | on(
  $(is<std::string>) >> [](const std::string &s) { return s.size(); },
  _                  >> 0
);
```

规则：

- handler 的参数个数必须**恰好等于** pattern 产生的绑定个数，否则编译期报错。
- 不产生绑定的 pattern（如 `lit`、`is<T>` 裸用、组合子）对应**零参** handler。
- 绑定顺序即 handler 参数顺序。

> 常见坑：`$ >> [](int x){...}` 在 subject 是 `variant<int,string>` 时会把**整个
> variant** 绑给 `int x`，编译报错。要按类型绑定请用 `$(is<int>)`。

### 4.3 守卫（Guard）：`pattern[guard_expr]`

守卫挂在**绑定模式**后面，先匹配、再绑定、再评估守卫，守卫通过才执行 handler；
守卫失败只是拒绝当前 case，继续尝试下一条。

```cpp
const char *bucket(int x) {
  using namespace ptn;
  return match(x) | on(
    $[_ < 0]              >> "negative",
    $[_ > 0 && _ < 10]    >> "small",     // 守卫内的 `_` 是绑定值占位符
    _                     >> "large"
  );
}
```

守卫里可以写：

- 以 `_` 为占位符的关系/逻辑表达式（`_ > 0 && _ < 10`）；
- `rng(lo, hi)` 区间助手（默认闭区间，第三参 `pat::mod::open` 为开区间）；
- 任意一元谓词（lambda / 函数对象），返回值可转 bool；
- 以上混合：`$[_ > 0 && is_prime]`。

```cpp
auto is_prime = [](int v) { /* ... */ };

match(x) | on(
  $[rng(0, 10)]                  >> "0..10",
  $[rng(0, 10, pat::mod::open)]  >> "(0,10)",
  $[is_prime]                    >> "prime",
  _                              >> "other"
);
```

### 4.4 多绑定值的守卫：`PTN_BIND(Type, names...)`

当一条 pattern 绑定多个值时（典型场景：`has<>` 解构多个成员），
用 `PTN_BIND` 一次性声明有名字的占位符（1~10 个名字），守卫表达式直接用成员名：

```cpp
struct Point { int x; int y; };

PTN_BIND(Point, x, y);   // 声明后，x/y 成为 constexpr member_t<&Point::x> 等

bool on_circle_radius5(const Point &p) {
  using namespace ptn;
  return match(p) | on(
    $(has<&Point::x, &Point::y>)[x * x + y * y == 25] >> true,
    _                                                  >> false
  );
}
```

要点：

- 名字在**编译期**解析到 `has<>` 成员列表中的位置，所以 `has<>` 里成员指针的
  书写顺序不影响守卫语义（`x` 永远指 `.x`）。
- `PTN_BIND` 可写在命名空间作用域或块作用域；块作用域声明是静态存储期，
  因此也能在 `PTN_ON` 的无捕获缓存 lambda 里引用。
- 拼错的成员名会在 `PTN_BIND` 那一行直接报错；守卫里用到未列入 `has<>` 的
  成员会触发 static_assert。成员名只能用在 `has<...>` 的守卫里。

### 4.5 结构体匹配：`has<&T::member...>`

`has<>` 描述「对象具有这些成员」，配合 `$(...)` 把成员值绑进 handler：

```cpp
struct Point { int x; int y; };

int sum(const Point &p) {
  using namespace ptn;
  return match(p) | on(
    $(has<&Point::x, &Point::y>) >> [](int x, int y) { return x + y; },
    _                            >> 0
  );
}
```

- 未列出的成员直接忽略；
- 成员顺序显式且稳定（决定绑定顺序）；
- 全部校验在编译期完成。

也可以只绑一个成员再配合守卫做按字段分类：

```cpp
struct User { int age; bool active; };

auto label(const User &u) {
  using namespace ptn;
  return match(u) | on(
    $(has<&User::active>)[_ == false] >> "inactive",
    $(has<&User::age>)[_ < 18]        >> "minor",
    _                                 >> "adult"
  );
}
```

### 4.6 `std::variant` 匹配：`is<T>` 与 `alt<I>`

```cpp
using Value = std::variant<int, std::string>;

std::string describe(const Value &v) {
  using namespace ptn;
  return match(v) | on(
    is<int>            >> "int",                       // 只分发不绑定 → 零参/值 handler
    $(is<std::string>) >> [](const std::string &s) {   // $(...) 绑定变体里的值
      return "str:" + s;
    },
    _ >> [] { return std::string("other"); }
  );
}
```

- `is<T>`：按类型匹配。要求 `T` 在 variant 的备选类型里**恰好出现一次**。
- `alt<I>`：按下标匹配。要求 `I` 在范围内。
- 想把备选值拿进 handler，就包一层 `$(...)`。

### 4.7 谓词模式：`pred(callable)`

`pred` 把一个任意一元谓词变成模式，在**匹配阶段**（而不是绑定后的守卫阶段）求值，
不产生绑定：

```cpp
match(x) | on(
  pred([](int v) { return v % 2 == 0; }) >> "even",
  _                                      >> "odd"
);
```

与守卫的区别：`$[g]` 是先绑定再检查（守卫拒绝时绑定值可以给后续分支重新匹配），
`pred(f)` 是纯粹的是/否判定，handler 拿不到值（要拿值请用 `$[...]`）。

### 4.8 组合子：`any` / `all` / `neg` 与运算符糖

```cpp
match(x) | on(
  any(val<1>, val<2>, val<3>) >> "1/2/3",   // 任一命中（短路）
  all(pred(is_pos), val<2>)   >> "2",       // 全部命中（短路）
  neg(val<0>)                 >> "non-zero",// 取反
  _                           >> "other"
);
```

- 三者都**不产生绑定**（handler 零参）。
- `any`/`all` 至少一个子模式，参数必须都是 pattern 对象。
- `neg(neg(p))` 双重否定抵消。
- 运算符糖：`!p` ≡ `neg(p)`；`(a || b)` ≡ `any(a, b)`；`(a && b)` ≡ `all(a, b)`。
  注意 `>>` 优先级高于 `||` / `&&`，组合子参与运算时**要加括号**：

```cpp
match(status) | on(
  !val<200>             >> "error",   // ! 不需要括号
  (lit(1) || lit(2))    >> "small",   // || 需要括号
  _                     >> "ok"
);
```

模式层的 `&&`/`||` 只接受 pattern 操作数，与守卫 `[...]` 内部的逻辑运算符不冲突。

---

## 5. 性能：缓存 case 包

`match(x) | on(...)` 每次调用都会重新构造 case 对象。对热路径上的重复匹配，
可以把 case 包缓存起来。

### `PTN_ON(...)`

```cpp
int fast_classify(int x) {
  using namespace ptn;
  return match(x) | PTN_ON(
    val<1> >> 1,
    val<2> >> 2,
    _      >> 0
  );
}
```

`PTN_ON` 把整个 matcher 存进函数内静态变量，只在首次执行时构造一次。
**限制：里面的 lambda 必须是无捕获的（stateless）**——静态上下文不能捕获局部变量。
需要捕获时退回普通 `on(...)`。

### `static_on(factory)`

更显式的版本：工厂 lambda 返回一个 `on(...)`，matcher 对象可与调用点分离，
在初始化期构造、多处复用：

```cpp
auto get_matcher() {
  using namespace ptn;
  return static_on([] {
    return on(
      lit("start") >> Action::Start,
      lit("stop")  >> Action::Stop,
      _            >> Action::Unknown
    );
  });
}

void process(const std::string &cmd) {
  auto result = match(cmd) | get_matcher();
}
```

### 什么时候值得缓存

- 同一 case 包在循环或高频函数里反复使用 → 用 `PTN_ON` / `static_on`；
- 非热路径、case 很少、或 handler 需要捕获局部变量 → 直接 `match | on` 即可。

### 分发层级（dispatch tiers）

库会按 pattern 构成自动选择分发策略：

- **Literal Dense / Runtime Dense**：连续整数字面量 → 跳转表 / 直接索引；
- **Variant Inline / Segmented / Compact**：小 variant 内联分发，大 variant 分段/紧凑表。

官方 benchmark（`docs/assets/bench/latest.md`）：纯字面量场景约 1.1ns/次，
variant 混合场景约 0.94ns/次；与手写 switch 差距在个位数百分比内。

---

## 6. 一个完整的实战例子（协议包分发）

来自库自带示例 `third_party/patternia/samples/handle_packet.cpp`，
演示结构体解构 + `PTN_BIND` 命名守卫 + 自定义谓词的组合：

```cpp
#include <ptn/patternia.hpp>
#include <cstdint>
#include <vector>

using namespace ptn;

struct Packet {
  std::uint8_t              type;
  std::uint16_t             length;
  std::uint8_t              flags;
  std::vector<std::uint8_t> payload;
};

void parse_packet(const Packet &pkt) {
  PTN_BIND(Packet, type, length);   // 守卫里用成员名 type / length

  auto is_valid_payload = [&pkt](const std::vector<std::uint8_t> &payload) {
    return pkt.type == 0x02 && pkt.length == payload.size() && (pkt.flags & 0x01);
  };

  auto is_error_packet = [](std::uint8_t                     type,
                            const std::vector<std::uint8_t> &payload) {
    return type == 0xFF && !payload.empty();
  };

  match(pkt) | on(
    // ping：type==0x01 且 length==0（PTN_BIND 名字守卫）
    $(has<&Packet::type, &Packet::length>)[type == 0x01 && length == 0]
        >> [](auto &&...) { /* handle_ping() */ },

    // data：payload 通过外部谓词校验
    $(has<&Packet::payload>)[is_valid_payload]
        >> [](const std::vector<std::uint8_t> &payload) { /* handle_data */ },

    // error：两个绑定值一起进谓词
    $(has<&Packet::type, &Packet::payload>)[is_error_packet]
        >> [](std::uint8_t, const std::vector<std::uint8_t> &payload) { /* ... */ },

    _ >> [] { /* reject */ }
  );
}
```

---

## 7. 常见错误与编译诊断

| 错误写法 | 编译器表现 | 正确做法 |
|---|---|---|
| `val<target>`，`target` 是运行期变量 | "non-type template argument is not a constant expression" | 改用 `lit(target)` |
| `on(...)` 里没写 `_` 兜底 | static_assert / `unresolved_match` 相关长错误 | 末尾加 `_ >> ...` |
| `PTN_ON` 里的 lambda 捕获了局部变量 | "lambda in a static context cannot capture" | 改用普通 `on(...)`，或去掉捕获 |
| subject 是 variant 时 `$ >> [](int x){...}` | handler 类型不匹配（`$` 绑定的是整个 variant） | 用 `$(is<int>)` |
| handler 参数个数 ≠ pattern 绑定个数 | "handler arity does not match pattern bindings" | 参数与绑定一一对应 |
| 各分支返回类型不一致 | "all handlers must return the same type" | 统一返回类型（必要时显式构造，如 `std::string(...)`） |
| `(a \|\| b) >> h` 忘加括号 | 解析成 `a \|\| (b >> h)`，报类型错误 | 组合子参与运算时加括号 |
| `PTN_BIND` 成员名拼错 / 守卫用了 `has<>` 未列出的成员 | `PTN_BIND` 行报错 / static_assert | 检查成员名与 `has<>` 列表 |

另外注意：`match(subject)` 的 subject 必须是**左值**（不能传临时量/右值）。

---

## 8. API 速查表

| 类别 | 符号 | 说明 |
|---|---|---|
| 入口 | `match(subject)` | 建立匹配上下文（subject 为左值） |
| 终止 | `on(cases...)` | 有序 case 列表，末尾必须 `_` 兜底 |
| case | `pattern >> handler` | handler 为值或可调用对象 |
| 通配 | `_` | 兜底模式；在守卫里是绑定值占位符 |
| 字面量 | `lit(v)` / `val<V>` / `lit_ci(s)` | 运行时 / 编译期 / 大小写不敏感字符串 |
| 绑定 | `$` / `$(subpattern)` | 绑整体 / 按子模式绑定 |
| 守卫 | `pattern[expr]` | 先绑定再判定，失败继续下一条 |
| 守卫助手 | `_`、`rng(lo,hi[,mode])`、`PTN_BIND(T, names...)`、任意谓词 | |
| 结构体 | `has<&T::m...>` | 成员解构（配 `$(...)` 绑定） |
| variant | `is<T>` / `alt<I>` | 按类型 / 按下标 |
| 谓词 | `pred(fn)` | 匹配阶段求值的一元谓词，无绑定 |
| 组合子 | `any(ps...)` / `all(ps...)` / `neg(p)`，糖：`!`、`||`、`&&` | 均无绑定 |
| 缓存 | `PTN_ON(...)` / `static_on(factory)` | 热路径缓存 case 包（lambda 须无捕获） |

宏仅两个：`PTN_ON`、`PTN_BIND`，其余都在 `namespace ptn`。

---

## 9. 参考资源

- 库内文档：`third_party/patternia/docs/`（`api.md` 为权威 API 参考，
  `guide/` 与 `tutorials/` 有更多教程）
- 自带示例：`third_party/patternia/samples/`（fibo、handle_packet、variant_type_is、json_dispatch）
- 在线文档：<https://patternia.tech>
