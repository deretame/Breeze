# 在 rquickjs_playground 中静态编译 PCRE2

> 本文档面向开发者，说明如何把 PCRE2 像 QuickJS 一样在 cargo build 时现场编译，并静态链接到 `rquickjs_playground` crate 中。

---

## 1. 目标

让 `rquickjs_playground` 在编译时自动完成以下事情：

1. 获取 PCRE2 源码（vendored 或下载）。
2. 用 Rust 的 `build.rs` 现场编译成静态库。
3. 静态链接到 `rquickjs_playground`。
4. 在 Rust 代码里通过 FFI 调用 PCRE2 API。

最终效果与项目里 `rquickjs-sys` 编译 QuickJS 的方式一致：不需要用户提前安装系统 PCRE2，也不依赖动态库。

---

## 2. 项目里 QuickJS 是怎么做的

`rquickjs_playground` 本身不直接编译 QuickJS，它依赖 crates.io 上的 `rquickjs`，真正的编译发生在 `rquickjs-sys` 的 `build.rs` 中：

- 源码放在 `rquickjs-sys/quickjs/`（vendored）。
- 直接用 Rust 的 `cc` crate 编译几个 `.c` 文件：
  - `quickjs.c`
  - `libregexp.c`
  - `libunicode.c`
  - `dtoa.c`
- 生成 `libquickjs.a` 并链接。
- 用 `bindgen` 生成 Rust FFI 绑定。

`rquickjs-sys` 不调用 QuickJS 的 `Makefile`，也不走 CMake，因为 QuickJS 源码结构简单，不需要生成 `config.h` 这类文件。

---

## 3. PCRE2 与 QuickJS 的差异

| 维度 | QuickJS | PCRE2 |
|------|---------|-------|
| 源文件数量 | 很少（4 个 `.c`） | 很多（约 30 个 `.c`） |
| 是否需要生成头文件 | 否 | 是（`config.h`、`pcre2.h`） |
| 官方构建系统 | 简单 Makefile | autotools + CMake |
| 是否可直接用 `cc` 编译 | 是 | 可以，但需要手动补齐 `config.h` 的等价 define |
| Windows 支持 | `cc` crate 直接支持 MSVC/MinGW | `cc` crate 直接支持，或走 CMake |

PCRE2 比 QuickJS 复杂的地方在于它依赖生成的配置头文件。不过 `pcre2-sys` 已经证明：**完全可以绕过 autotools/CMake，直接用 `cc` crate 编译 PCRE2**，只要设置好对应的宏定义。

---

## 4. 推荐方案：参考 `pcre2-sys` 用 `cc` 直接编译

`BurntSushi/rust-pcre2` 的 `pcre2-sys` crate 就是按这个思路实现的，它的 `build.rs` 核心逻辑：

1. 把 PCRE2 源码 vendored 在 `pcre2-sys/upstream/`。
2. 用 `cc::Build` 直接编译 `upstream/src/*.c`。
3. 手动 `define` 替代 `config.h`：
   - `PCRE2_CODE_UNIT_WIDTH=8`
   - `HAVE_CONFIG_H=1`
   - `PCRE2_STATIC=1`
   - `SUPPORT_UNICODE=1`
   - `HAVE_WINDOWS_H=1`（Windows）
4. 跳过几个被 `#include` 而不是单独编译的文件：
   - `pcre2_jit_match.c`
   - `pcre2_jit_misc.c`
   - `pcre2_ucptables.c`
5. 输出 `libpcre2.a` 并链接。

这是最接近 QuickJS 编译模式的方案，也是跨平台维护成本最低的自建方案。

---

## 5. 可选方案对比

### 方案 A：直接用 `pcre2` crate（最简单）

```toml
[dependencies]
pcre2 = "0.2"
```

然后强制静态编译：

```bash
PCRE2_SYS_STATIC=1 cargo build
```

优点：
- 零构建脚本。
- `pcre2-sys` 已经处理好了所有平台细节。

缺点：
- 增加外部依赖。
- 不能高度定制编译选项。

### 方案 B：拷贝 `pcre2-sys` 思路，自建 `build.rs`

在 `rquickjs_playground` 里新增 `build.rs`，vendored PCRE2 源码，用 `cc` 编译。

优点：
- 和项目里 QuickJS 的构建方式一致。
- 可控性强。
- 不需要用户系统安装 PCRE2。

缺点：
- 需要自己维护 PCRE2 源码版本。
- 需要处理跨平台细节（虽然比 autotools/CMake 少）。

### 方案 C：用 autotools（Linux/macOS）+ CMake（Windows）

在 `build.rs` 里根据平台选择构建系统。

优点：
- 完全按 PCRE2 官方方式构建，不容易出错。

缺点：
- Windows 需要 CMake。
- 交叉编译（Android/iOS）配置复杂。
- build.rs 代码量比方案 B 大很多。

**推荐顺序：A → B → C**。

---

## 6. 方案 B 实施步骤

### 6.1 添加 PCRE2 源码

作为 git submodule：

```bash
cd rquickjs_playground
git submodule add https://github.com/PCRE2Project/pcre2.git pcre2
git submodule update --init --recursive
```

或者直接把某个版本的 PCRE2 源码复制到 `rquickjs_playground/pcre2/`。

### 6.2 添加 build 依赖

```toml
# rquickjs_playground/Cargo.toml
[build-dependencies]
cc = "1.2"
bindgen = "0.71"   # 如果需要自动生成绑定
```

### 6.3 新建 `rquickjs_playground/build.rs`

```rust
use std::env;
use std::path::{Path, PathBuf};

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let pcre2_src = manifest_dir.join("pcre2");
    let pcre2_src_dir = pcre2_src.join("src");

    // 基础宏定义，替代 config.h
    let mut builder = cc::Build::new();
    builder
        .define("PCRE2_CODE_UNIT_WIDTH", "8")
        .define("HAVE_CONFIG_H", "1")
        .define("PCRE2_STATIC", "1")
        .define("STDC_HEADERS", "1")
        .define("HAVE_STDLIB_H", "1")
        .define("HAVE_MEMMOVE", "1")
        .define("SUPPORT_PCRE2_8", "1")
        .define("SUPPORT_UNICODE", "1");

    let target = env::var("TARGET").unwrap();
    if target.contains("windows") {
        builder.define("HAVE_WINDOWS_H", "1");
    }

    // 部分平台关闭 JIT，参考 pcre2-sys
    if should_disable_jit(&target) {
        // 不定义 SUPPORT_JIT
    } else {
        builder.define("SUPPORT_JIT", "1");
    }

    builder
        .include(&pcre2_src_dir)
        .include(pcre2_src.join("deps"))
        .include(pcre2_src.join("include"));

    // 编译 src 下所有 .c，跳过被 #include 的文件
    for entry in std::fs::read_dir(&pcre2_src_dir).unwrap() {
        let entry = entry.unwrap();
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("c") {
            continue;
        }
        let name = path.file_name().unwrap().to_string_lossy();
        if name == "pcre2_jit_match.c"
            || name == "pcre2_jit_misc.c"
            || name == "pcre2_ucptables.c"
        {
            continue;
        }
        builder.file(path);
    }

    builder.compile("libpcre2.a");

    // 生成绑定（可选）
    generate_bindings(&pcre2_src, &out_dir);
}

fn should_disable_jit(target: &str) -> bool {
    target.contains("apple-ios")
        || target.contains("apple-tvos")
        || target == "aarch64-linux-android"
        || target == "armv7-linux-androideabi"
        || target.contains("musleabi")
}

fn generate_bindings(pcre2_src: &Path, out_dir: &Path) {
    let bindings = bindgen::Builder::default()
        .header(pcre2_src.join("src/pcre2.h").to_string_lossy())
        .clang_arg("-DPCRE2_CODE_UNIT_WIDTH=8")
        .allowlist_function("pcre2_.*")
        .allowlist_type("pcre2_.*")
        .allowlist_var("PCRE2_.*")
        .generate()
        .expect("failed to generate pcre2 bindings");

    bindings
        .write_to_file(out_dir.join("pcre2_bindings.rs"))
        .expect("failed to write bindings");
}
```

### 6.4 在 Rust 代码中使用

```rust
// src/lib.rs 或需要用到的地方
mod pcre2_ffi {
    include!(concat!(env!("OUT_DIR"), "/pcre2_bindings.rs"));
}

pub fn compile_pattern(pattern: &str) {
    // 通过 pcre2_ffi::pcre2_compile_8(...) 调用
}
```

### 6.5 构建

```bash
cd rquickjs_playground
cargo build
```

第一次构建时，`build.rs` 会自动编译 PCRE2 源码并静态链接。

---

## 7. Windows 注意事项

### 7.1 工具链

- **MSVC**：需要安装 Visual Studio Build Tools，`cc` crate 会自动找到 `cl.exe`。
- **MinGW / MSYS2**：需要安装 `mingw-w64-x86_64-gcc`。

### 7.2 链接库名

上面的 `builder.compile("libpcre2.a")` 在 Windows MSVC 下会生成 `pcre2.lib`，`cc` crate 会自动处理链接名，通常不需要额外配置。

### 7.3 JIT 问题

PCRE2 的 JIT 在部分 Apple 平台（iOS/tvOS）和某些 Android ABI 上有兼容性问题，示例代码里已经按 `pcre2-sys` 的经验关闭了这些 target 的 JIT。

---

## 8. 如何验证 PCRE2 已成功链接

在 `rquickjs_playground` 里加一个测试或示例：

```rust
#[test]
fn pcre2_version_check() {
    unsafe {
        let version = pcre2_ffi::pcre2_config_8(
            pcre2_ffi::PCRE2_CONFIG_VERSION,
            std::ptr::null_mut(),
        );
        println!("PCRE2 version return: {}", version);
    }
}
```

能编译通过且运行不报错，说明 PCRE2 已经正确链接。

---

## 9. 决策速查

| 你的需求 | 推荐方案 |
|---------|---------|
| 只想快速用上 PCRE2，不 care 构建细节 | `pcre2` crate + `PCRE2_SYS_STATIC=1` |
| 想完全自己控制，像 QuickJS 一样内嵌 | 方案 B：vendored + `cc` crate + 自建 `build.rs` |
| 需要大量自定义 PCRE2 编译选项 | 方案 C：autotools/CMake |
| 只做 Windows，不想处理 `cc` 跨平台 | PCRE2 官方 CMake |

---

## 10. 参考链接

- `rquickjs-sys` build.rs（QuickJS 的 `cc` 编译方式）：<https://github.com/DelSkayn/rquickjs/blob/master/sys/build.rs>
- `pcre2-sys` build.rs（PCRE2 的 `cc` 编译方式）：<https://github.com/BurntSushi/rust-pcre2/blob/master/pcre2-sys/build.rs>
- PCRE2 官方仓库：<https://github.com/PCRE2Project/pcre2>
- `cc` crate 文档：<https://docs.rs/cc>
