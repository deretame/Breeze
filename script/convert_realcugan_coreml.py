#!/usr/bin/env python3
"""把 Real-CUGAN PyTorch 权重转换为 iOS/macOS CoreML .mlpackage。

依赖：
    pip install torch numpy opencv-python coremltools

用法：
    python script/convert_realcugan_coreml.py \
        --src /path/to/Real-CUGAN \
        --weight up2x-latest-no-denoise.pth \
        --output asset/coreml_models/RealCUGAN_2x_no-denoise_block156.mlpackage

说明：
- Real-CUGAN 官方只提供 PyTorch/NCNN 权重，没有现成 CoreML 模型。
- 本脚本把 UNet 推理包装成固定尺寸输入，输出 2x 超分结果。
- 输入尺寸 = block_size + 2 * shrink_size（默认 156 + 36 = 192）。
- 输出尺寸 = block_size * scale（默认 156 * 2 = 312）。
- 负 padding 在 CoreML 中不支持，所以先把 F.pad 的负值转成 tensor 切片。
"""

import argparse
import os
import sys


def _patch_negative_pad():
    """让 F.pad 的负 padding 走切片，以兼容 coremltools。"""
    import torch.nn.functional as F

    _original_pad = F.pad

    def _patched_pad(x, pad, mode="constant", value=0):
        if any(p < 0 for p in pad):
            left, right, top, bottom = pad
            left, right, top, bottom = -left, -right, -top, -bottom
            h, w = x.shape[-2], x.shape[-1]
            return x[..., top : h - bottom, left : w - right]
        return _original_pad(x, pad, mode=mode, value=value)

    F.pad = _patched_pad


def main():
    parser = argparse.ArgumentParser(description="Convert Real-CUGAN to CoreML")
    parser.add_argument("--src", required=True, help="Real-CUGAN 源码目录")
    parser.add_argument("--weight", required=True, help=".pth 权重文件名")
    parser.add_argument("--output", required=True, help="输出 .mlpackage 路径")
    parser.add_argument("--block-size", type=int, default=156, help="内容块边长")
    parser.add_argument("--shrink-size", type=int, default=18, help="每边重叠边距")
    parser.add_argument("--scale", type=int, default=2, help="放大倍率")
    parser.add_argument("--ios", type=int, default=15, help="最低 iOS 版本")
    args = parser.parse_args()

    sys.path.insert(0, args.src)
    _patch_negative_pad()

    import torch
    import torch.nn.functional as F
    import coremltools as ct
    from upcunet_v3 import UpCunet2x

    weight_path = os.path.join(args.src, args.weight)
    if not os.path.isfile(weight_path):
        raise FileNotFoundError(f"权重文件不存在: {weight_path}")

    input_size = args.block_size + 2 * args.shrink_size
    output_size = args.block_size * args.scale

    model = UpCunet2x()
    model.load_state_dict(torch.load(weight_path, map_location="cpu"))
    model.eval()

    class Cugan2xCoreML(torch.nn.Module):
        def __init__(self, m):
            super().__init__()
            self.m = m

        def forward(self, x):
            x = self.m.unet1.forward(x)
            x0 = self.m.unet2.forward(x, alpha=1)
            x = F.pad(x, (-20, -20, -20, -20))
            return x0 + x

    wrapped = Cugan2xCoreML(model)
    wrapped.eval()

    example_input = torch.randn(1, 3, input_size, input_size)
    with torch.no_grad():
        y = wrapped(example_input)
    print(f"输入 {example_input.shape} -> 输出 {y.shape}")
    assert y.shape[-2:] == (output_size, output_size), (
        f"输出尺寸 {y.shape[-2:]} 与预期 {output_size}x{output_size} 不符"
    )

    traced = torch.jit.trace(wrapped, example_input)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=(1, 3, input_size, input_size))],
        outputs=[ct.TensorType(name="output")],
        minimum_deployment_target=getattr(ct.target, f"iOS{args.ios}"),
        compute_units=ct.ComputeUnit.ALL,
    )

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    mlmodel.save(args.output)
    print(f"已保存: {args.output}")
    print(
        "Dart 侧 config 建议: "
        f"blockSize={input_size}, shrinkSize={args.shrink_size}, scale={args.scale}"
    )


if __name__ == "__main__":
    main()
