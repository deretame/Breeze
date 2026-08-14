# 时间向 Intl 实现说明

面向维护者。插件作者请先看 [README.md](../README.md) 的 `Intl` 一节。

## 目标

在 QuickJS 宿主中提供 **ECMA-402 时间相关子集**，满足：

1. 插件按 locale 习惯格式化日期时间
2. Temporal polyfill 的时区 / 字段刮取路径
3. 不引入 Collator / NumberFormat 等非时间能力

## 架构

```text
JS:  js/07_intl.js
       │  Intl.DateTimeFormat / Date.toLocale*
       ▼
Host:  __intl_canonicalize_time_zone
       __intl_dtf_format / __intl_dtf_format_to_parts
       __intl_dtf_resolved_options
       __intl_supported_values_of
       │
       ▼
Rust:  src/web_runtime/intl.rs
       ├── jiff          时区解析、offset、epoch → zoned
       ├── jiff-icu      jiff ↔ ICU 类型
       └── icu (ICU4X)   locale 日期时间格式化 + formatToParts
```

## 文件

| 路径 | 职责 |
|------|------|
| `js/07_intl.js` | JS 表面：选项规范化、style 冲突、`Date.toLocale*` |
| `src/web_runtime/intl.rs` | 宿主实现：时区、ICU 格式化、supportedValuesOf |
| `src/web_runtime.rs` | 注册 `__intl_*` 全局函数 |
| `tests/intl_datetime_smoke.rs` | 时间向 Intl 回归 |
| `tests/test262_temporal.rs` | Temporal / 可选 intl402 Temporal |

## 支持范围（承诺）

- 日历：`iso8601`、`gregory`（实用路径）
- 时区：IANA 名、固定 offset（`+HH:MM` 等）、常见 link 的 primary canonicalize
- 格式：`dateStyle` / `timeStyle`、字段选项、`hourCycle`（含 `h24`）、lone option
- locale：ICU4X compiled data 覆盖的常见语言（中/英/日/德等）

## 非目标（刻意不做）

- `Collator` / 排序
- `NumberFormat` / 货币 / 单位
- 完整非公历日历语义（农历闰月、伊斯兰 eraYear 等）
- 100% Test262 `intl402` 通过率

非公历失败主要来自 Temporal polyfill「用 Intl 刮字段」路径与 ICU 非公历语义之间的差距；插件场景收益低，维护成本高。若未来需要引擎级 Temporal 日历，应评估 `temporal_rs`，而不是继续堆 polyfill 特例。

## 关键行为备忘

### 选项冲突

`dateStyle` 或 `timeStyle` 与下列任一同时出现 → `TypeError`：

`weekday` / `era` / `year` / `month` / `day` / `hour` / `minute` / `second` / `dayPeriod` / `fractionalSecondDigits` / `timeZoneName`

### 默认 hourCycle

不在 JS 层强制 `h23`。未指定时交给 locale 默认（如 `en-US` 倾向 12 小时）。Temporal 刮时区路径会通过 `en-u-hc-h23` 显式指定。

### 时区 canonicalize

`primary_time_zone_id` 将常见 link 映射到 primary（如 `Asia/Calcutta` → `Asia/Kolkata`，`Etc/GMT` → `UTC`）。`resolvedOptions().timeZone` 与 `supportedValuesOf("timeZone")` 使用 primary。

### 极端时间戳

超出 jiff 毫秒范围时 **clamp** 到可表示区间，避免 Temporal 边界采样直接抛死。字段在极端下可能不精确，但宿主不崩溃。

### zone-only fieldset

仅 `timeZoneName` 时不向 ICU `FieldSetBuilder` 设置 `length`（否则 `SuperfluousOptions`）。

## 测试命令

```bash
# Intl smoke
cargo test --test intl_datetime_smoke

# Temporal built-ins（应 0 unexpected fail）
cargo test --test test262_temporal -- --nocapture

# intl402 Temporal（可选；非公历大量失败为已知）
# Windows PowerShell:
#   $env:TEST262_INCLUDE_INTL402='1'
#   cargo test --test test262_temporal -- --nocapture

# 单测超时（默认 15000ms）
#   $env:TEST262_CASE_TIMEOUT_MS='15000'
```

## 依赖

见 `Cargo.toml`：

- `jiff`
- `jiff-icu`
- `icu`
- `writeable`

## 变更原则

1. 优先保证 **ISO + 时区 + locale 显示** 稳定  
2. 不为冲 intl402 日历通过率引入大体积/高复杂度依赖路径  
3. 改 `intl.rs` / `07_intl.js` 后至少跑 `intl_datetime_smoke` + `temporal_smoke`  
4. 动 Temporal 相关路径时再跑 `test262_temporal`（built-ins）  
