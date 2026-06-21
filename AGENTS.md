# Breeze — Agent 开发指南

> 本文档面向 AI 编程助手。若你第一次接触本项目，请先阅读本文件再修改代码。项目的主要注释、文档与发布日志均为中文，因此本文档也使用中文撰写。

---

## 1. 项目概述

**Breeze**（包名 `zephyr`）是一个使用 Flutter 开发的跨平台漫画阅读应用，支持第三方图源插件。当前主要支持：

- **Android**（APK 分发）
- **iOS / iPadOS**（未签名 IPA，需侧载）
- **Windows**（Tauri 安装器）
- **macOS**（DMG / Homebrew Cask）
- **Linux**（Flatpak）

### 1.1 核心定位

- 应用本身不包含具体漫画内容，漫画数据通过**插件**获取。
- 插件运行在技术栈 `Dart → Flutter Rust Bridge → Rust → QuickJS` 的 Rust 侧运行时中。
- 默认内置插件（Bika、禁漫等）在 `rust/build.rs` 编译时从 CDN 下载并打包进二进制。

### 1.2 主要仓库

- **Dart/Flutter 应用**：`lib/`
- **Rust FFI 库**：`rust/`（crate 名 `windcore`）
- **QuickJS 运行时封装**：`rquickjs_playground/`
- **Windows 安装器前端**：`windows-installer/`（SvelteKit + Tauri v2）
- **构建/发布脚本**：`script/`
- **CI/CD**：`.github/workflows/`

---

## 2. 技术栈

### 2.1 Flutter / Dart

- **Flutter 版本**：`3.44.2`（通过 `.fvmrc` 与 `.puro.json` 锁定，建议使用 FVM / Puro）
- **Dart SDK**：`^3.9.2`
- **应用包名**：`zephyr`

### 2.2 Rust

- **主库 crate**：`rust/` 下的 `windcore`
- **Rust edition**：2024
- **Flutter Rust Bridge**：`2.12.0`（Rust 侧通过 `=2.12.0` 精确锁定）
- **rquickjs**：`0.11.0`，用于执行 JS 插件

### 2.3 状态管理与路由

- **状态管理**：`flutter_bloc` + `bloc` + `bloc_concurrency`
  - 复杂业务使用 `Bloc`（事件驱动）
  - 轻量/局部状态使用 `Cubit`
- **路由**：`auto_route`，页面使用 `@RoutePage()` 注解

### 2.4 数据持久化与网络

- **本地数据库**：`objectbox` + `objectbox_flutter_libs`
- **HTTP 客户端**：`dio` + `dio_http2_adapter` + `dio_cookie_manager`
- **图片加载/缓存**：`extended_image`、`photo_view`
- **后台下载**：`background_downloader`
- **WebDAV / S3 同步**：Rust 侧 `reqwest_dav`、Dart 侧 `minio`

### 2.5 监控与异常上报

- **Sentry**：`sentry_flutter`，崩溃、性能剖析、会话回放
- 通过 `sentry_dsn` dart-define 在 Release 构建中启用

---

## 3. 仓库结构

```text
.
├── lib/                        # Dart/Flutter 主代码
│   ├── main.dart               # 应用入口
│   ├── config/                 # 全局与业务配置（GlobalSetting、Bika/JM 设置等）
│   ├── cubit/                  # 全局轻量 Cubit
│   ├── debug/                  # 调试页面
│   ├── model/                  # 通用业务模型
│   ├── network/                # 网络层、插件调用、WebDAV/S3 同步
│   ├── object_box/             # ObjectBox 实体与生成文件
│   ├── page/                   # 页面/Feature 集合（最大模块）
│   ├── plugin/                 # 插件注册与服务
│   ├── src/rust/               # FRB 生成的 FFI 绑定
│   ├── type/                   # 通用枚举与类型工具
│   ├── util/                   # 工具类、路由、桌面端适配、下载队列等
│   └── widgets/                # 通用 UI 组件
├── rust/                       # Rust FFI 主库（windcore）
│   ├── src/api/                # 暴露给 Dart 的 API
│   ├── src/compressed/         # 压缩/打包（tar/zip/brotli/zstd）
│   ├── src/decode/             # 禁漫图片反混淆
│   ├── src/memory/             # 内存统计
│   ├── src/qjs/                # QuickJS runtime 管理
│   ├── build.rs                # 编译时下载内置插件 bundle
│   └── Cargo.toml
├── rquickjs_playground/        # QuickJS 宿主运行时封装 crate
├── windows-installer/          # Windows 安装器（SvelteKit + Tauri v2）
├── script/                     # 构建与代码生成脚本
│   ├── android_build_utils.py
│   ├── build_apk.dart
│   ├── build_linux_flatpak.dart
│   ├── build_ncnn_android.py
│   ├── build_ncnn_static_android.py
│   ├── build_waifu2x_cli_android.py
│   ├── build_windows.dart
│   ├── code_generate.dart
│   ├── download_android_ncnn_deps.dart
│   └── prepare_android_waifu2x_deps.py
├── hook/build.dart             # Dart Native Asset 构建钩子
├── flatpak/                    # Linux Flatpak 配置
├── android/                    # Android 工程
├── ios/ / macos/ / linux/ / windows/  # 各平台原生工程
├── .github/workflows/          # CI/CD
├── asset/                      # 字体、图片、内置资源
│   └── coreml_models/          # iOS/macOS CoreML 超分模型（随包分发）
├── test/                       # 测试（当前仅有一个注释掉的 widget_test.dart）
├── integration_test/             # 集成测试（如 Android RealSR / CoreML 超分端到端验证）
└── plugin-dev-docs/            # 插件开发文档（VitePress 站点）
```

### 3.1 典型 Feature 目录结构

`lib/page/` 下每个模块通常按职责分层：

```text
page/comic_info/
├── comic_info.dart           # barrel 文件
├── bloc/                     # BLoC（event/state）
├── cubit/                    # 可选 Cubit
├── method/                   # 业务方法
├── models/                   # 页面内模型
├── json/normal/              # JSON 数据类与反序列化
├── view/                     # 页面主体 Widget
└── widgets/                  # 页面私有组件
```

### 3.2 生成文件位置

以下文件由工具生成，**请勿手动修改**：

- **ObjectBox**：`lib/object_box/model.g.dart`、`lib/object_box/objectbox.g.dart`
- **flutter_rust_bridge**：`lib/src/rust/frb_generated*.dart`、`rust/src/frb_generated.rs`
- **auto_route**：`lib/util/router/router.gr.dart`
- **freezed / json_serializable**：各目录下的 `*.freezed.dart`、`*.g.dart`

---

## 4. 环境准备

### 4.1 必需工具链

- **Flutter SDK**：`3.44.2`（推荐通过 FVM / Puro 安装）
- **Rust Toolchain**：通过 `rustup` 安装，并添加目标平台 target
- **LLVM / Clang**：`rustqjs` 等库需要解析 C 头，Windows 推荐 `choco install llvm`
- **Java 21**：Android / Windows / Linux 编译必需
- **Android SDK / NDK**：NDK 版本见 `android/app/build.gradle.kts` 中的 `ndkVersion`

### 4.2 推荐环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `JAVA_HOME` | 编译 Android / Windows / Linux 必需 | `C:\Program Files\Android\Android Studio\jbr` |
| `ANDROID_NDK_HOME` | Rust 交叉编译 Android 库必需 | `...\Android\Sdk\ndk\29.0.14206865` |
| `LIBCLANG_PATH` | 供 `bindgen` 生成 FFI 绑定使用 | `C:\Program Files\LLVM\bin` |

确保 `PATH` 中包含 `javac` 与 `clang`。

### 4.3 依赖初始化

```bash
# 根项目 Flutter 依赖
flutter pub get

# 桥接层依赖（如存在 rust_builder 目录）
cd rust_builder
flutter pub get
```

---

## 5. 构建与运行

### 5.1 代码生成

修改涉及 `auto_route`、`freezed`、`json_serializable`、`objectbox`、FRB 的代码后，必须重新生成：

```bash
# 方式 1：使用项目脚本（推荐）
dart ./script/code_generate.dart

# 方式 2：手动执行
flutter pub run build_runner build --delete-conflicting-outputs
flutter_rust_bridge_codegen generate
dart format ./lib/
cargo fmt
```

### 5.2 本地运行

```bash
# 调试运行
flutter run

# 带 Sentry DSN 运行
flutter run --dart-define=sentry_dsn=YOUR_DSN
```

### 5.3 平台构建

项目提供 Dart 脚本统一处理构建：

| 平台 | 构建命令/脚本 | 产物 |
|------|---------------|------|
| Android | `dart ./script/build_apk.dart` | `build/app/outputs/flutter-apk/*.apk` |
| Linux | `dart ./script/build_linux_flatpak.dart` | `breeze.flatpak` |
| Windows | `dart ./script/build_windows.dart` | `windows-installer.exe` |
| macOS | `flutter build macos --release` + `create-dmg` | `Breeze-macOS.dmg` |
| iOS | `flutter build ios --release --no-codesign` + 打包 | `Breeze-iOS.ipa` |

`build_apk.dart` 无参数时默认构建 Release 并分 ABI；带任意参数时进入快速 Debug 构建（`--debug --target-platform=android-arm64,android-x64`）。

iOS 模拟器（`aarch64-apple-ios-sim`）构建时，`rquickjs-sys` 的 bindgen 会把 Rust target triple 直接传给 clang，但 clang 不识别 `-sim` 后缀。`hook/build.dart` 已针对该目标自动注入 `BINDGEN_EXTRA_CLANG_ARGS=--target=aarch64-apple-ios-simulator` 以绕过此问题。

RealSR 桌面端模型不再打包进安装包，首次使用需在设置页下载。模型下载后解压到 `getFilePath()/super_resolution/`，由 `RealSrSuperResolution` 自动调用。Linux / macOS 下载完成后会自动执行 `chmod +x` 授权。

Android 端已彻底从 JNI + ncnn 共享库方案切换到 **waifu2x CLI** 方案：APK 中以 native library 形式打包静态链接 ncnn / Vulkan / OpenCV / libwebp 的 `libwaifu2x_cli.so`；Dart 层通过 MethodChannel 获取它在 `nativeLibraryDir` 中的路径，直接通过 `Process.run` 调用。模型仍在首次使用时从 `https://github.com/deretame/breeze-binary/raw/main/realsr-android.7z` 下载并解压到 `getFilePath()/super_resolution/`。

相关脚本（默认仅 `arm64-v8a`）：

- 准备 OpenCV / libwebp 依赖：`python script/prepare_android_waifu2x_deps.py`
- 编译 ncnn 静态库：`python script/build_ncnn_static_android.py`（关闭 OpenMP，启用 Vulkan）
- 编译 waifu2x CLI：`python script/build_waifu2x_cli_android.py`（输出 `android/app/src/main/jniLibs/arm64-v8a/libwaifu2x_cli.so`；若 `third_party/RealSR-NCNN-Android` 不存在，脚本会自动从上游仓库克隆）

旧版 ncnn 共享库脚本 `script/build_ncnn_android.py` 与 `script/download_android_ncnn_deps.dart` 仍保留，但 CLI 方案已不再需要它们。

### 5.4 调试代理

开发模式下应用会读取 `.env.proxy` 资源文件中的 `proxy=` 配置，自动探测并设置 HTTP 代理，方便调试网络请求。

---

## 6. 代码风格与约定

### 6.1 换行与编码

- 使用 `.editorconfig`：UTF-8、LF 换行、文件末尾保留空行、去除行尾空格。
- `.gitattributes` 会将文本文件规范化为 LF；Windows 批处理文件（`*.bat`、`*.cmd`）保持 CRLF。
- Git `pre-commit` 钩子会自动对暂存文件执行 `git add --renormalize`，仅包含换行符噪音的提交会被阻止。

### 6.2 Dart 规范

- `analysis_options.yaml` 继承 `package:flutter_lints/flutter.yaml`。
- `invalid_annotation_target` 错误级别设为 `ignore`，避免代码生成注解的误报。
- `build.yaml` 配置 `json_serializable` 的 `explicit_to_json: true`。

### 6.3 命名与组织

- Dart 包名 `zephyr`，导入使用 `package:zephyr/...`。
- 页面模块使用 barrel 文件统一 `export` 下层子模块。
- 复杂业务优先使用 `Bloc`，轻量状态使用 `Cubit`。
- 状态类优先使用 `freezed` 生成不可变数据；旧模块仍有手写 `copyWith` + `equatable`。

### 6.4 Rust 规范

- Rust 使用 edition 2024，`cargo fmt` 格式化。
- `rust-toolchain.toml` 指定工具链，请按项目配置使用。
- FRB 导出函数使用 `#[frb]`、`#[frb(sync)]`、`#[frb(init)]` 等宏标记。

---

## 7. 测试策略

> ⚠️ 当前项目**几乎没有自动化测试**。`test/widget_test.dart` 是 Flutter 模板生成的示例，已被完全注释掉。

- 目前没有单元测试、集成测试或 Widget 测试。
- 修改核心逻辑后，主要依靠**手动在目标平台运行验证**。
- 如果你新增复杂业务，建议补充测试，但目前没有现成测试基础设施可直接复用。

---

## 8. 部署与发布

### 8.1 CI/CD 工作流

- **`.github/workflows/push-build.yml`**：每次 `push` 到 `main` 触发，并行构建 Android / Linux / Windows / macOS / iOS 产物为 artifact，**不发布 Release**。Android 构建前会安装 CMake 3.22.1，运行 `script/prepare_android_waifu2x_deps.py` 准备 OpenCV / libwebp 依赖，再依次运行 `script/build_ncnn_static_android.py` 与 `script/build_waifu2x_cli_android.py` 生成 `libwaifu2x_cli.so`；NCNN 模型不再随包打包，改为首次运行时下载。
- **`.github/workflows/release.yml`**：手动触发，输入版本号后构建全平台产物，上传符号表到 Sentry，创建 GitHub Release，更新 Homebrew Cask，并发送 Telegram 通知。Android 构建前同样会准备 waifu2x CLI 依赖并编译 CLI。
- **`.github/workflows/release_to_telegram.yml`**：Release `published` 时触发，向 Telegram 发送版本消息与附件。
- **`.github/workflows/signpath-smoke.yml`**：签名通道冒烟测试，与正式构建解耦。

### 8.2 发布前准备

1. 更新 `pubspec.yaml` 中的 `version`。
2. 在 `CHANGELOG.md` 顶部按格式追加新版本日志（格式：`## [vX.Y.Z]`）。
3. 提交并推送后手动触发 `release.yml`。

### 8.3 敏感文件

- `android/key.properties` 与 `android/Breeze-key.keystore` 使用 **git-crypt** 加密。
- CI 中通过 `secrets.GIT_CRYPT_KEY` 解密。
- 未解密前请勿修改这些文件，避免破坏加密状态。

### 8.4 Sentry 配置

- Release 构建通过 `--dart-define=sentry_dsn=...` 注入 DSN。
- 上传符号表需要 `SENTRY_AUTH_TOKEN`、`SENTRY_ORG`、`SENTRY_PROJECT` 环境变量。
- `pubspec.yaml` 中已配置 `sentry:` 段落。

---

## 9. 安全与合规注意事项

- **TLS 校验**：应用在初始化时调用 `setTlsVerifyEnabled(enabled: false)`，默认关闭 TLS 证书校验。这是为兼容部分自签名证书图源，但会降低网络安全性；修改前请充分评估影响。
- **代理配置**：支持 HTTP / SOCKS5 代理，开发时通过 `.env.proxy` 配置，生产环境由用户在设置中配置。
- **插件系统**：插件运行在 QuickJS 沙箱中，但可执行网络请求与文件系统操作（取决于 feature）。新增宿主 API 时应注意权限边界。
- **第三方内容**：应用不直接托管漫画内容，内容由第三方插件提供。开发与发布时需遵守所在地区法律法规。
- **崩溃监控**：Release 构建启用 Sentry，会上报异常、性能样本与部分会话回放。注意保护用户隐私。
- **未签名桌面/macOS/iOS 包**：正式分发的包未进行 Apple / Windows 付费签名，首次安装可能需要用户手动放行。

---

## 10. 常见修改入口

| 你想做什么 | 从哪里开始 |
|-----------|-----------|
| 新增页面 / 路由 | `lib/page/`、`lib/util/router/router.dart`，然后运行代码生成 |
| 新增数据源/插件支持 | `lib/network/http/plugin/unified_comic_plugin.dart`、`rust/src/api/qjs.rs` |
| 修改数据库模型 | `lib/object_box/model.dart`，然后运行代码生成 |
| 修改全局设置 | `lib/config/global/global_setting.dart` |
| 修改图片/下载逻辑 | `lib/util/download/`、`lib/network/http/picture/` |
| 修改 Rust 侧能力 | `rust/src/api/`、`rust/src/qjs/`，然后运行 FRB 生成 |
| 修改 Windows 安装器 | `windows-installer/src/`、`windows-installer/src-tauri/` |
| 修改 RealSR 超分逻辑 | `lib/util/real_sr/real_sr_super_resolution.dart`、`lib/page/setting/real_sr/real_sr_setting_page.dart`、`rust/src/api/simple.dart` |
| 修改 Android RealSR 原生依赖 / waifu2x CLI | `script/prepare_android_waifu2x_deps.py`、`script/build_ncnn_static_android.py`、`script/build_waifu2x_cli_android.py`、`android/app/src/main/cpp/waifu2x_cli/`、`lib/util/real_sr/real_sr_super_resolution.dart` |
| 修改桌面端 RealSR 策略/模型选择 | `lib/util/real_sr/desktop_ncnn_model_config.dart`、`lib/util/real_sr/real_sr_super_resolution.dart`、`lib/page/setting/real_sr/real_sr_setting_page.dart` |
| 修改 CoreML 超分（iOS/macOS） | `packages/coreml_upscale/`、`lib/debug/coreml_upscale_debug_page.dart`、`asset/coreml_models/`、`script/convert_realcugan_coreml.py` |
| 修改 CI/CD | `.github/workflows/`、`script/` |

---

## 11. 延伸阅读

- **README.md**：用户安装指南与免责声明。
- **CHANGELOG.md**：版本发布日志。
- **plugin-dev-docs/**：插件开发文档（VitePress 站点），对外发布地址：<https://deretame.github.io/plugin-dev-docs/>
- **Android RealSR 构建文档**：`docs/android_realsr_build.md`
- **Flutter Rust Bridge 文档**：<https://cjycode.com/flutter_rust_bridge/>
