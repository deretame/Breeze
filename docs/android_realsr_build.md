# Android RealSR 构建与 waifu2x CLI 使用说明

> 本文档面向开发者，说明 Breeze Android 端 RealSR 超分的原生部分如何构建、CLI 如何被调用。

---

## 1. 方案概述

Android 端已彻底从 **JNI + ncnn 共享库** 方案切换到 **waifu2x-ncnn CLI** 方案：

- 编译时把一个静态链接了 ncnn / Vulkan / OpenCV / libwebp 的可执行文件重命名为 `libwaifu2x_cli.so`，随 APK 打包到 `lib/<abi>/`。
- 运行时 Dart 层通过 `MethodChannel` 获取该 so 在 `nativeLibraryDir` 中的真实路径，然后直接用 `Process.run` 调用它。
- 超分模型（waifu2x / Real-CUGAN）不打包进 APK，首次使用时从网络下载 `realsr-android.7z` 并解压到应用的 `files/super_resolution/` 目录。

> 当前 ABI 只支持 `arm64-v8a`，其余 ABI 需要扩展 `script/build_waifu2x_cli_android.py` 的 `ABIS` 列表并解决对应依赖。

---

## 2. 前置要求

- Flutter `3.44.2`（建议用 FVM / Puro）
- Android SDK 与 NDK `29.0.14206865`
- Android SDK CMake `3.22.1`
- Python `3.x` 与 `git`
- Windows / Linux / macOS 均可，但脚本会优先查找本机已安装的 Android SDK

必要环境变量（如未使用默认路径）：

| 变量 | 说明 |
|------|------|
| `ANDROID_SDK_ROOT` 或 `ANDROID_HOME` | Android SDK 根目录 |
| `ANDROID_NDK_HOME` 或 `ANDROID_NDK_ROOT` | Android NDK 根目录 |

---

## 3. 依赖准备

waifu2x CLI 编译需要 OpenCV Android SDK 和 libwebp 源码，运行：

```bash
python script/prepare_android_waifu2x_deps.py
```

这个脚本会：

1. 下载并解压 `opencv-4.11.0-android-sdk.zip` 到 `third_party/android_ncnn_deps/OpenCV-android-sdk/`。
2. 克隆 `webmproject/libwebp` 到 `third_party/android_ncnn_deps/libwebp/`。

如果这两个目录已存在且文件完整，脚本会自动跳过。

---

## 4. 编译静态 ncnn

waifu2x CLI 需要静态链接 ncnn（关闭 OpenMP、开启 Vulkan），运行：

```bash
python script/build_ncnn_static_android.py
```

这个脚本会：

1. 克隆 ncnn 源码到 `third_party/ncnn-src/`（如果还没有）。
2. 为 `arm64-v8a` 编译静态库。
3. 输出到 `third_party/android_ncnn_deps/ncnn-android-vulkan-static/arm64-v8a/`。

产物包含 `lib/libncnn.a` 和 `include/`。

---

## 5. 编译 waifu2x CLI

```bash
python script/build_waifu2x_cli_android.py
```

这个脚本会：

1. 检查 `third_party/RealSR-NCNN-Android` 是否存在；若缺失，自动从上游仓库克隆对应 commit 的源码。
2. 使用 `android/app/src/main/cpp/waifu2x_cli/CMakeLists.txt` 构建 `waifu2x-ncnn` 可执行文件。
3. 用 NDK 的 `llvm-strip` 去除符号，减小体积。
4. 把可执行文件重命名为 `libwaifu2x_cli.so`（这样 Gradle 才会把它当作 native library 打进 APK）。
5. 复制到：
   - `third_party/android_ncnn_deps/waifu2x-cli-android/arm64-v8a/libwaifu2x_cli.so`
   - `android/app/src/main/jniLibs/arm64-v8a/libwaifu2x_cli.so`

如果产物已经存在，两个脚本都会直接跳过，避免重复编译。需要强制重建时：

```bash
# Windows (PowerShell)
$env:FORCE_REBUILD=1; python script/build_waifu2x_cli_android.py

# Linux / macOS
FORCE_REBUILD=1 python script/build_waifu2x_cli_android.py
```

---

## 6. 构建 Flutter APK

完成上述步骤后，像普通 Flutter 应用一样构建即可：

```bash
# Debug 快速验证
flutter build apk --debug --target-platform=android-arm64

# Release（正式构建）
dart ./script/build_apk.dart
```

构建完成后，APK 的 `lib/arm64-v8a/` 下应包含：

```text
libwaifu2x_cli.so
```

可以验证：

```bash
# 以实际 7z 路径为准
"C:\Program Files\7-Zip\7z.exe" l build/app/outputs/flutter-apk/app-debug.apk | findstr waifu2x
```

---

## 7. 运行时 CLI 调用方式

### 7.1 Dart 侧获取 CLI 路径

`MainActivity.kt` 里注册了一个 `MethodChannel` 处理器，方法名为 `getWaifu2xCliPath`：

```kotlin
"getWaifu2xCliPath" -> {
    val nativeLibDir = applicationInfo.nativeLibraryDir
    val cli = File(nativeLibDir, "libwaifu2x_cli.so")
    // ...
    result.success(cli.absolutePath)
}
```

Dart 侧在 `RealSrSuperResolution._prepareAndroidCli()` 中调用，得到 so 的真实路径。

### 7.2 CLI 参数

Dart 调用示例：

```dart
final result = await Process.run(
  exePath,
  [
    '-i', inputPath,          // 输入图片
    '-o', outputPath,         // 输出图片
    '-s', scale.toString(),   // 放大倍率，如 2
    '-n', noise.toString(),   // 降噪等级，如 0 / 1 / 2 / 3
    '-m', modelPath,          // 模型目录
    '-g', '0',                // GPU 设备 ID，0 表示第一个 Vulkan 设备
    '-t', tileSize.toString(),// tile 大小，如 0 表示自动
  ],
  runInShell: false,
  workingDirectory: modelRoot,
);
```

参数含义与上游 `waifu2x-ncnn-vulkan` 一致：

| 参数 | 说明 |
|------|------|
| `-i <path>` | 输入图片路径 |
| `-o <path>` | 输出图片路径 |
| `-s <int>` | 放大倍率（2 / 4 等） |
| `-n <int>` | 降噪等级（0-3） |
| `-m <dir>` | 模型目录 |
| `-g <int>` | GPU 索引，`-1` 为 CPU，默认 `0` |
| `-t <int>` | tile 大小，`0` 为自动 |

CLI 输出完成后，Dart 层再把图片转回 WebP 等目标格式覆盖原路径。

---

## 8. 模型下载

超分模型不随包分发。首次调用时，Dart 层会从：

```text
https://github.com/deretame/breeze-binary/raw/main/realsr-android.7z
```

下载并解压到：

```text
/data/user/0/com.zephyr.breeze/files/super_resolution/
```

目录结构示例：

```text
super_resolution/
├── models-cunet/
│   └── ...
├── models-upconv_7_anime_style_art_rgb/
│   └── ...
├── models-upconv_7_photo/
│   └── ...
└── ...
```

---

## 9. 常见问题

### 9.1 找不到 CMake / NDK

脚本优先从 `ANDROID_SDK_ROOT` / `ANDROID_HOME` 推断路径。如果 CMake 或 NDK 不在默认位置，设置环境变量即可。

### 9.2 需要强制重编

```bash
FORCE_REBUILD=1 python script/build_ncnn_static_android.py
FORCE_REBUILD=1 python script/build_waifu2x_cli_android.py
```

### 9.3 产物没有被打包进 APK

检查 `android/app/src/main/jniLibs/arm64-v8a/libwaifu2x_cli.so` 是否存在。Flutter 默认会把 `jniLibs/<abi>/` 下的 so 打包进 APK。

### 9.4 运行时提示 CLI 找不到

- 确认 APK 里包含 `lib/arm64-v8a/libwaifu2x_cli.so`。
- 确认设备 ABI 是 `arm64-v8a`（目前只支持这个 ABI）。
- 确认 `MainActivity.kt` 里的 `getWaifu2xCliPath` 方法没有被误删。

---

## 10. 相关文件速查

| 文件 | 作用 |
|------|------|
| `script/prepare_android_waifu2x_deps.py` | 下载 OpenCV / libwebp 依赖 |
| `script/build_ncnn_static_android.py` | 编译静态 ncnn |
| `script/build_waifu2x_cli_android.py` | 编译 waifu2x CLI 并伪装成 so |
| `script/android_build_utils.py` | 跨平台工具函数 |
| `android/app/src/main/cpp/waifu2x_cli/CMakeLists.txt` | CLI 的 CMake 配置 |
| `lib/util/real_sr/real_sr_super_resolution.dart` | Dart 侧超分入口与 CLI 调用 |
| `android/app/src/main/kotlin/com/zephyr/breeze/MainActivity.kt` | `getWaifu2xCliPath` MethodChannel |
| `integration_test/real_sr_android_test.dart` | 真机集成测试 |
