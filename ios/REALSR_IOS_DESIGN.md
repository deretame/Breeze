# iOS RealSR / 超分集成设计思路

> 说明：当前作者暂无 macOS 设备，本文只作为设计文档，供后续在 Mac/Xcode 上实现时参考。代码未实际编写，也未验证编译。

---

## 1. 现状

- Android / Windows / Linux / macOS 已经接入 `realcugan-ncnn-vulkan`。
- iOS 目前在 `RealSrSuperResolution.isAvailable` 中直接返回 `false`，即不支持超分。
- iOS 没有原生 Vulkan，ncnn 在 iOS 上跑 Vulkan 需要 MoltenVK，且只能用于 arm64 真机。

---

## 2. 目标

让 iOS 端也能使用超分功能，优先复用现有 Dart 侧 `RealSrSuperResolution` 的接口与设置体系，只对 iOS 平台做原生实现。

---

## 3. 选型：waifu2x-ios

iOS 上最成熟的本地超分开源方案是 **[imxieyi/waifu2x-ios](https://github.com/imxieyi/waifu2x-ios)**。

优点：

- 纯 iOS 原生实现，使用 `CoreML` + `Metal Performance Shaders`。
- 支持 iOS 11+，能利用 Apple Neural Engine（ANE）。
- 仓库本身带有一个 `waifu2x` framework target，可以当作库使用。
- 除了内置的 waifu2x 模型，还能通过 `waifu2x-ios-model-converter` 导入 ESRGAN / Real-ESRGAN / 其它兼容架构的 Core ML 模型。

缺点：

- 不是 CocoaPods / Swift Package，需要手动把源码/framework 集成进 Xcode 工程。
- 内置免费模型是 waifu2x；Real-CUGAN 需要自行准备兼容的 `.mlmodelc` 模型文件（或从 App Store 版本资产中提取，或用 converter 自己转）。

---

## 4. 集成方案

### 4.1 iOS 工程侧

1. 将 `waifu2x-ios` 仓库中的 `waifu2x/` 目录整体复制到 `ios/Runner/` 或 `ios/waifu2x/` 下。
2. 在 `Runner.xcodeproj` 中新增一个 **Framework target**（或直接把 `waifu2x/*.swift` 加入 Runner 编译）。
3. 链接系统 framework：
   - `CoreML`
   - `MetalKit`
   - `MetalPerformanceShaders`
   - `Accelerate`
   - `UIKit`
4. 将 Core ML 模型文件（`.mlmodelc`）打包进 app bundle，或首次运行时从网络下载后放到应用沙盒。

### 4.2 Flutter 与 iOS 通信

沿用现有的 `realsr_super_resolution` MethodChannel：

```text
通道名: realsr_super_resolution
方法:
  - extractAssets   (iOS 可空实现或用于下载模型)
  - upscale         (真正执行超分)
```

在 `AppDelegate.swift`（或新建一个 `RealSrPlugin.swift`）中注册 Handler：

```swift
let channel = FlutterMethodChannel(
    name: "realsr_super_resolution",
    binaryMessenger: controller.binaryMessenger
)
channel.setMethodCallHandler { call, result in
    switch call.method {
    case "upscale":
        // 读取 inputPath / outputPath / model / tileSize 等参数
        // 调用 Waifu2x.run(...)
        // 把结果写到 outputPath，result.success(...)
    case "extractAssets":
        // 检查/下载模型，result.success(true)
    default:
        result.notImplemented()
    }
}
```

### 4.3 Dart 侧改动

`RealSrSuperResolution` 已经做了平台区分：

- Windows / Linux / macOS：走 `_upscaleCli` + `realcugan-ncnn-vulkan`。
- Android：走 MethodChannel。
- iOS：只需要让 `isAvailable` 在 iOS 上也返回 `true`（模型存在时），`upscale` 会自动进入 MethodChannel 分支。

需要新增的判断：

```dart
if (Platform.isIOS) {
  // 检查 app bundle / 沙盒中是否存在 .mlmodelc 模型
  return File(p.join(await _modelDirectory, 'up_anime_scale2x_model.mlmodelc')).existsSync();
}
```

iOS 模型目录同样可以放在 `getFilePath()/super_resolution` 下，与桌面端保持语义一致。

### 4.4 参数映射

现有设置：

| Dart 设置 | iOS / waifu2x-ios 映射 |
|---|---|
| 自动超分开关 | 通用逻辑，不变 |
| 分辨率阈值 | 通用逻辑，不变 |
| 并发数量 | 使用 waifu2x-ios 的 `BackgroundPipeline` 串行/并发控制 |
| 分块大小 | 映射到 `Waifu2x.block_size` 或模型输入 shape |
| 降噪级别 | 映射到 waifu2x 的 `anime_noise0~3` / Real-CUGAN 的对应模型 |

waifu2x-ios 的调用入口大致为：

```swift
let image = UIImage(contentsOfFile: inputPath)
let output = Waifu2x.run(image, model: Model.anime_noise0_scale2x) { progress in
    // 可选回调进度
}
// 把 output 保存到 outputPath
```

如果后续使用 Real-CUGAN Core ML 模型，需要扩展 `Model` enum 或在自定义模型加载路径中处理。

### 4.5 设置项隐藏（Flutter 层控制）

设置项的显隐逻辑应放在 **Flutter/Dart 侧** 完成，而不是在 iOS 原生代码里控制。入口位于 `lib/page/setting/global/global_setting.dart`：该页面通过 `_realSrAvailable` 决定是否渲染“图片处理”整个区块；区块内部再由 `RealSrSettingPage` 根据后端能力决定是否渲染具体子项。

| 设置项 | 桌面端（ncnn-vulkan） | iOS（waifu2x-ios） |
|---|---|---|
| 分块大小 | 支持 | 由 waifu2x-ios 内部处理，通常无需暴露 |
| 降噪级别 | 映射到 Real-CUGAN noise 参数 | 若使用内置 waifu2x 模型则直接对应不同模型；若不暴露应隐藏 |
| 并发数量 | 支持 | 可用 `BackgroundPipeline` 控制 |

**原则**：

1. 若当前平台完全未接入超分（如 iOS 后端尚未实现），`global_setting.dart` 应整体隐藏“图片处理”区块，而不是只隐藏里面的列表项、留下空的区块标题。
2. 具体子项若在当前后端不可用，应在 `RealSrSettingPage` 中通过 `Platform.isIOS` 或能力查询接口隐藏，避免用户看到无效选项：

```dart
final _showTileSize = !Platform.isIOS;
final _showNoiseLevel = !Platform.isIOS || _iosSupportsNoiseSelection;
```

---

## 5. 模型资产

### 方案 A：使用 waifu2x 内置模型（最简单）

- 直接从 `waifu2x-ios` 仓库获取转换好的 `.mlmodelc` 文件。
- 优点：立即可用，无转换成本。
- 缺点：效果与 Real-CUGAN 不同，用户体验不一致。

### 方案 B：为 iOS 准备 Real-CUGAN Core ML 模型（推荐）

- 使用 `waifu2x-ios-model-converter` 将 Real-CUGAN PyTorch 权重转成 `.mlpackage`/`.mlmodelc`。
- 转换后的模型可以放到 `deretame/breeze-binary` 仓库，与桌面端 7z 包并列：
  - `realsr-ios-models.zip`
- App 首次进入超分设置时下载并解压到 `getFilePath()/super_resolution/`。
- Dart 侧复用已有的 `downloadModel()` 逻辑，只是 URL 和压缩包内容不同。

> 注：Core ML 模型转换不一定一次成功，可能需要针对 Real-CUGAN 的 upcunet 结构做 wrapper 或分块处理。

---

## 6. 文件与目录建议

```text
ios/
├── Runner/
│   └── RealSrPlugin.swift       # MethodChannel 实现
├── waifu2x/                     # 从 waifu2x-ios 复制过来的 framework 源码
│   ├── Waifu2x.swift
│   ├── ModelFactory.swift
│   └── ...
├── realsr-assets/               # 默认打包的 .mlmodelc（可选）
│   └── up_anime_scale2x_model.mlmodelc
└── REALSR_IOS_DESIGN.md         # 本文件
```

运行时模型目录：

```text
<App Documents>/files/super_resolution/
```

---

## 7. 实现步骤（待执行）

1. 在 Mac 上克隆 `waifu2x-ios`，确认 `waifu2x` framework target 能编译通过。
2. 把 `waifu2x/` 源码加入 Breeze 的 `ios/Runner.xcodeproj`。
3. 编写 `RealSrPlugin.swift` 实现 `extractAssets` / `upscale`。
4. 修改 Dart 侧 `RealSrSuperResolution.isAvailable`，使 iOS 在模型存在时返回 `true`。
5. 修改 `RealSrSettingPage`，让 iOS 也显示“模型管理”入口。
6. 准备并测试至少一个 `.mlmodelc` 模型（waifu2x 或 Real-CUGAN）。
7. 在 iPhone 真机上跑通单张图片超分。

---

## 8. 风险与注意事项

- **模拟器限制**：Core ML / Metal 在模拟器上可能无法完整验证，必须在真机测试。
- **内存**：大图超分容易 OOM，需要分块处理；waifu2x-ios 内部已有分块逻辑，但输入尺寸仍需要限制。
- **模型体积**：单个 `.mlmodelc` 可能几十到上百 MB，会显著增加 app 体积；建议按需下载。
- **精度**：Core ML 默认 FP16，可能和 ncnn-vulkan 输出有细微差异；如需完全一致可强制 FP32，但会牺牲 ANE 性能。
- **许可证**：从 App Store 版本提取模型存在法律和许可风险，建议用开源 converter 自己转换，或确认模型许可证允许再分发。

---

## 9. 替代思路（如果 waifu2x-ios 走不通）

- **ncnn + MoltenVK**：自己编译 `realcugan-ncnn-vulkan` 的 iOS 二进制。可行，但性能/稳定性不如 Core ML。
- **ONNX Runtime iOS**：将 Real-CUGAN 转 ONNX，用 ONNX Runtime 或 Core ML Execution Provider 跑。转换和分块工程量大。
- **服务器端超分**：iOS 把图片传到服务端超分再返回。最简单，但不符合“本地超分”的设计。

---

## 10. 结论

推荐以 **waifu2x-ios 的 Core ML/MPS 实现** 作为 iOS 超分后端：

- 技术成熟、资料多、能跑在 ANE 上。
- 与 Flutter 的集成只需要一个 MethodChannel。
- 模型层优先用 waifu2x 内置模型跑通流程，再尝试转换/引入 Real-CUGAN Core ML 模型以保持跨平台效果一致。
