# segmentation_wasi

用于将 `rust/src/decode/segmentation.rs` 独立编译为 WASI 模块。

## 代码来源

- 本 crate 通过路径模块直接复用主工程文件：`rust/src/decode/segmentation.rs`
- 不会复制两份逻辑，保持单一实现

## 编译命令

在仓库根目录执行：

```bash
cargo build --manifest-path rust/segmentation_wasi/Cargo.toml --target wasm32-wasip1 --bin jm_segmentation
```

或在 `rust` 目录执行：

```bash
cargo build --manifest-path segmentation_wasi/Cargo.toml --target wasm32-wasip1 --bin jm_segmentation
```

构建 release 版本（更小体积）：

```bash
cargo build --release --manifest-path rust/segmentation_wasi/Cargo.toml --target wasm32-wasip1 --bin jm_segmentation
```

## 产物位置

- `rust/segmentation_wasi/target/wasm32-wasip1/debug/jm_segmentation.wasm`
- `rust/segmentation_wasi/target/wasm32-wasip1/release/jm_segmentation.wasm`

## 调用方式（真实输入输出）

该 WASI 程序支持：

- 从 `stdin` 读取原始图片字节
- 参数传入 `chapter_id`、`scramble_id`、`url`
- 将处理后的图片字节写到 `stdout`

参数顺序：

```text
<chapter_id> <scramble_id> <url>
```

例如使用 `wasmtime`：

```bash
wasmtime run rust/segmentation_wasi/target/wasm32-wasip1/release/jm_segmentation.wasm 123456 220980 https://a/b/00001.jpg < input.jpg > output.webp
```

如果处理失败，错误信息会输出到 `stderr`，并返回非 0 退出码。
