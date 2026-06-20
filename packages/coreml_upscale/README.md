# coreml_upscale

`coreml_upscale` 是 Breeze 为 iOS / macOS 提供的 CoreML 图片超分插件。

它把预先转换好的 CoreML 模型（`*.mlmodel` 或 `*.mlpackage`）接到 Flutter 侧，
在 Apple 设备上利用 CoreML / Neural Engine / GPU / CPU 完成 2x 超分。

---

## 致谢

iOS / macOS 超分实现参考了 **Aidoku** 项目的思路与模型处理方式，
在此对 Aidoku 表示感谢。

- Aidoku: <https://github.com/Aidoku/Aidoku>

---

## CoreML 与 ncnn 的区别

Breeze 在不同平台上使用两套超分后端：

| 维度 | CoreML（iOS / macOS） | ncnn（Windows / Linux / Android） |
|---|---|---|
| 运行时 | CoreML / ANE / GPU / CPU | ncnn + Vulkan |
| 是否需要额外可执行文件 | 不需要 | 需要 `realcugan-ncnn-vulkan` |
| 模型格式 | `*.mlmodel` / `*.mlpackage` | PyTorch / NCNN 权重目录 |
| 放大倍率 | 由模型决定（目前均为 2×） | `-s 2` 等参数 |
| 降噪级别 | 由模型文件决定（如 `noise0` / `no-denoise`） | `-n` 参数 |
| 分块/Tile | 由模型固定：`blockSize` / `shrinkSize` | 用户可调 `-t tileSize` |
| 重叠处理 | 反射填充 + 非重叠内容块拼接 | 由 `syncGapMode` 控制 |
| 输入/输出 | PNG / JPEG 文件路径 | PNG / JPEG 文件路径 |

简单理解：

- **ncnn** 更像一个通用命令行工具，通过参数控制降噪、分块、放大倍率。
- **CoreML** 把这些信息都打包进模型文件本身，调用时只需要告诉插件用哪个模型、
  输入/输出节点叫什么、内容块和边距分别是多少。

---

## 模型转换

### Real-CUGAN

Real-CUGAN 官方只提供 PyTorch / NCNN 权重，没有现成的 CoreML 模型。
项目里提供了转换脚本：

```bash
python script/convert_realcugan_coreml.py \
    --src /path/to/Real-CUGAN \
    --weight up2x-latest-no-denoise.pth \
    --output RealCUGAN_2x_no-denoise_block156.mlpackage
```

关键参数含义：

- `--block-size`：内容块边长，即真正参与拼接的区域。
- `--shrink-size`：每边反射填充的边距。
- `--scale`：放大倍率。

脚本内部会先 `torch.jit.trace`，再用 `coremltools` 导出为 `.mlpackage`。
Dart 侧调用时对应的 config 为：

```dart
{
  'inputName': 'input',
  'outputName': 'output',
  'blockSize': blockSize + 2 * shrinkSize,
  'shrinkSize': shrinkSize,
  'scale': scale,
}
```

例如默认 `--block-size 156 --shrink-size 18 --scale 2` 对应：

```dart
{
  'blockSize': 192,   // 156 + 2*18
  'shrinkSize': 18,
  'scale': 2,
}
```

### waifu2x

waifu2x 的 CoreML 模型目前直接放在 `deretame/breeze-binary` 仓库中
（`MacOS-iOS.7z` 里的 `waifu2x_photo_noise0_scale2x.mlmodel`）。
如需自行转换，通用流程为：

1. 将 PyTorch 模型 trace 为固定尺寸输入。
2. 使用 `coremltools.convert(...)` 导出为 `*.mlmodel` 或 `*.mlpackage`。
3. 确保模型输入尺寸 = 内容块 + 2×反射边距，输出尺寸 = 内容块 × 放大倍率。
4. 在 Dart 侧填入对应的 `blockSize`、`shrinkSize`、`scale`。

---

## Dart 接口

```dart
import 'package:coreml_upscale/coreml_upscale.dart';

await CoreMLUpscale.upscale(
  inputPath: '/path/to/input.png',
  outputPath: '/path/to/output.png',
  modelPath: '/path/to/model.mlmodel', // 或 .mlpackage 目录
  modelType: 'multiarray',
  config: const <String, dynamic>{
    'inputName': 'input',
    'outputName': 'output',
    'blockSize': 156,
    'shrinkSize': 7,
    'scale': 2,
  },
);
```

`modelType` 目前主要使用 `'multiarray'`，即模型输入/输出为 `MLMultiArray`。

### config 字段说明

| 字段 | 含义 |
|---|---|
| `inputName` | 模型输入节点名称 |
| `outputName` | 模型输出节点名称 |
| `blockSize` | 模型固定输入尺寸（含反射边距） |
| `shrinkSize` | 每边反射边距 |
| `scale` | 放大倍率 |

**注意**：`blockSize` 不是内容块大小。实际参与拼接的内容块大小为
`blockSize - 2 * shrinkSize`。插件内部会先把图片 Padding 到内容块的整数倍，
再用反射方式扩展出 `shrinkSize` 边距，从而保证输出块之间不重叠。

---

## CLI（ncnn）使用方式

Windows / Linux / Android 上仍使用 `realcugan-ncnn-vulkan`。
典型命令：

```bash
realcugan-ncnn-vulkan \
  -i input.png \
  -o output.png \
  -m /path/to/models-pro \
  -s 2 \
  -n -1 \
  -t 0 \
  -c 3
```

参数说明：

| 参数 | 含义 |
|---|---|
| `-i` | 输入图片路径 |
| `-o` | 输出图片路径 |
| `-m` | 模型目录 |
| `-s` | 放大倍率 |
| `-n` | 降噪级别（`-1` 保守，`0` 无降噪，`1/2/3` 降噪强度） |
| `-t` | 分块大小，`0` 表示不分块 |
| `-c` | `syncGapMode` |

macOS 在 Breeze 中已切换到 CoreML，不再使用上述 CLI。

---

## 测试

集成测试位于项目根目录：

```bash
# macOS
flutter test integration_test/coreml_upscale_test.dart -d macos

# iOS 模拟器
flutter test integration_test/coreml_upscale_test.dart -d "iPhone 16 Pro"
```

测试会：

1. 从 `deretame/breeze-binary` 下载 `MacOS-iOS.7z`。
2. 用 Rust 侧 `decompress7Z` 解压出 CoreML 模型。
3. 分别用 waifu2x 和 Real-CUGAN 对 `404.png`（505×505）做 2x 超分。
4. 验证输出尺寸为 `1010×1010`。

调试页面：`lib/debug/coreml_upscale_debug_page.dart`。

---

## 模型分发

iOS / macOS 的模型不打包在应用内，而是从
`https://github.com/deretame/breeze-binary/raw/main/MacOS-iOS.7z`
下载后解压到临时目录。Dart 侧通过 `CoreMLModelLoader` 管理下载、解压和本地路径。
