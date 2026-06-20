# Aidoku Upscale CLI

从 [Aidoku](https://github.com/Aidoku/Aidoku) 阅读器里拆出来的图片超分命令行工具，用于在 macOS 上快速测试 Aidoku 的超分效果。

> 仅能在 macOS 上运行，因为推理完全依赖 Apple `CoreML` / `Vision` / `Accelerate`。

## 测试图片

本项目不提供测试图片，请自行准备输入图片（PNG/JPEG 均可）。
运行后生成的 `output.png` 等输出文件已被 `.gitignore` 忽略，不会进入版本控制。

## 构建

```bash
cd aidoku-upscale-cli
swift build
```

## 用法

列出可用模型：

```bash
swift run aidoku-upscale-cli --list-models
```

使用 waifu2x 对图片做 2x 超分：

```bash
swift run aidoku-upscale-cli \
  --model waifu2x_photo_noise0_scale2x.mlmodel \
  --input /path/to/input.png \
  --output /path/to/output.png
```

使用 Real-ESRGAN：

```bash
swift run aidoku-upscale-cli \
  --model RealESRGAN_x2plus.mlpackage \
  --input /path/to/input.png \
  --output /path/to/output.png
```

模型会自动下载并缓存到 `~/Library/Caches/aidoku-upscale-cli/Models`。

## 参数

- `--list-models`：列出远端可用模型
- `--model <file>`：模型文件名（默认 `waifu2x_photo_noise0_scale2x.mlmodel`）
- `--input <path>` / `-i <path>`：输入图片
- `--output <path>` / `-o <path>`：输出图片（默认 `output.png`）
- `--max-height <int>`：当图片高度大于等于该值时跳过超分（默认 4000）

## 实现说明

- `ModelManager.swift`：改编自 Aidoku，负责从 `https://upscale.aidoku.app/models.json` 拉取模型列表、下载/缓存/加载模型。
- `MultiArrayModel.swift`：直接移植自 Aidoku，包含分块（tiling）、`shrinkSize` 边界填充、以及 `Accelerate` 前后处理。
- `ImageModel.swift`：针对图到图 CoreML 模型的封装，使用 `VNCoreMLRequest`。
