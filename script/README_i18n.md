# Rust 侧错误消息国际化工作流

本项目在 `rquickjs_playground` 与 `rust`（windcore）两个 crate 中使用 `i18n!` / `i18n_fmt!` 宏实现中英双语错误/日志消息切换。默认语言为中文；Dart 侧可调用 `setQjsErrorMessageLanguage(lang: "en")` 切换。

## 文件说明

| 文件 | 作用 |
|------|------|
| `rquickjs_playground/src/i18n.rs` | 中文/英文消息表、`set_error_message_language`、`i18n!` / `i18n_fmt!` 宏 |
| `script/i18n_extract.js` | 扫描两个 crate 中的中文字符串，输出统计列表 |
| `script/translate_messages.js` | 读取 `i18n_strings.txt`，调用 MyMemory 免费接口得到英文草稿，输出 `i18n_translated.json` |
| `script/apply_i18n.js` | 读取 `i18n_translations.tsv`，把源码中的中文字面量替换为宏调用，并重新生成 `i18n.rs` |
| `script/i18n_translations.tsv` | 翻译表，格式 `zh<TAB>en`（key 为中文模板本身） |

## 新增/修改文案时的标准流程

### 1. 在源码里正常写中文

```rust
return Err(anyhow!("下载 bundle 失败"));
```

带变量时先按原来的 Rust 风格写：

```rust
anyhow!("下载 bundle 失败: {bundle_url}")
```

### 2. 提取待翻译字符串

```bash
cd script
node i18n_extract.js > i18n_strings.txt
```

`i18n_strings.txt` 每行为 `出现次数<TAB>"中文模板"`。

### 3. 获取/更新英文翻译

可以手工维护 `i18n_translations.tsv`，也可以先跑机器翻译草稿：

```bash
node translate_messages.js
# 输出 i18n_translated.json，需要人工校对后整理成 i18n_translations.tsv
```

`i18n_translations.tsv` 要求一行一条，用制表符分隔：

```tsv
下载 bundle 失败	Download bundle failed
下载 bundle 失败: {0}	Download bundle failed: {0}
```

> 注意：模板中的 `{0}`、`{1}` 等占位符必须保留，且与中文模板的占位符顺序一致。

### 4. 自动替换源码

```bash
node apply_i18n.js
```

该脚本会：

- 在两个 crate 的 `.rs` 文件中寻找中文字符串字面量；
- 根据占位符数量生成 `crate::i18n!(key)` 或 `crate::i18n_fmt!(key, args...)`（windcore 用 `rquickjs_playground::` 前缀）；
- 重新生成 `rquickjs_playground/src/i18n.rs` 的中英文 map。

### 5. 人工 review（重要）

自动替换有已知边界情况，编译前必须检查：

1. **`rquickjs::Exception::throw_message(&ctx, ...)`**  
   脚本可能把 `&ctx` 参数丢掉，需要补回：
   ```rust
   rquickjs::Exception::throw_message(&ctx, crate::i18n!("..."))
   ```

2. **`assert!(cond, "...", args)`**  
   `assert!` 的 message 必须是字符串字面量。替换后如果是：
   ```rust
   assert!(cond, crate::i18n_fmt!("... {0}", arg));
   ```
   需要改成：
   ```rust
   assert!(cond, "{}", crate::i18n_fmt!("... {0}", arg));
   ```
   并且补回 `{err}`、`{:?}` 这类被脚本遗漏的参数。

3. **需要 `&str` / `Pattern` 的地方**  
   以下场景应使用 `i18n!`（返回 `&str`），而不是 `i18n_fmt!`（返回 `String`）：
   - `.unwrap_or(...)` 接 `Option<&str>`
   - `.expect_err(...)`
   - `.contains(...)`
   - 任何要求 `'static str` 的上下文

4. **`{:?}` / `{变量名}` 参数**  
   脚本会把 `{err}` 转成 `{0}`，但不会自动传入 `err` 变量。需要手动补上：
   ```rust
   crate::i18n_fmt!("失败: {0}", err)
   // 原来是 Debug 格式则：
   crate::i18n_fmt!("失败: {0}", format!("{:?}", result))
   ```

5. **`ThreadId` 等没有实现 `Display` 的类型**  
   需要在外层先 `format!("{:?}", ...)` 再传入。

### 6. 格式化与验证

```bash
# Rust 格式化
cd rquickjs_playground && cargo fmt
cd ../rust && cargo fmt

# 编译检查（需要 MinGW clang）
export LIBCLANG_PATH=/d/msys2/mingw64/bin
export PATH=/d/msys2/mingw64/bin:$PATH
cargo check -p rquickjs_playground
cargo check -p windcore

# 测试
cargo test -p rquickjs_playground
cargo test -p windcore
```

### 7. 若新增了 Rust → Dart 接口

```bash
flutter_rust_bridge_codegen generate
puro dart format lib/src/rust/
```

## 小改动（只改一两条文案）

如果改动很少，可以直接：

1. 在 `i18n_translations.tsv` 新增/修改对应行；
2. 手动在源码中把中文换成 `crate::i18n!("...")` 或 `crate::i18n_fmt!("...", arg)`；
3. 在 `rquickjs_playground/src/i18n.rs` 的 `insert_messages` 和 `insert_messages_en` 中各加一行 `m.insert(...)`；
4. 跑 `cargo fmt` + `cargo check`。

这样不需要跑 `apply_i18n.js`，也最安全。
