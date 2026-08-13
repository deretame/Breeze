"""配置 CMake 项目（Ninja + vcpkg toolchain；默认 clang-cl 编译器）。

用法: python scripts/configure.py [--build-type Debug|Release] [--compiler clang-cl|msvc]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import vs_env

ROOT = Path(__file__).resolve().parents[2] / "quickjs-runtime"
BUILD_DIR = ROOT / "build"
TOOLCHAIN = ROOT.parent / "third_party" / "vcpkg" / "scripts" / "buildsystems" / "vcpkg.cmake"
CLANG_CL = r"C:\Program Files\LLVM\bin\clang-cl.exe"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-type", default="Debug", choices=["Debug", "Release", "RelWithDebInfo"])
    parser.add_argument(
        "--compiler", default="clang-cl", choices=["clang-cl", "msvc"],
        help="编译器：clang-cl（默认，LLVM 安装于 C:/Program Files/LLVM）或 msvc（cl.exe）",
    )
    args = parser.parse_args()

    if not TOOLCHAIN.exists():
        print(f"错误: 未找到 vcpkg toolchain: {TOOLCHAIN}\n请先运行: pixi run setup-vcpkg", file=sys.stderr)
        return 1

    compiler = ""
    if args.compiler == "clang-cl":
        if not Path(CLANG_CL).exists():
            print(f"错误: 未找到 clang-cl: {CLANG_CL}", file=sys.stderr)
            return 1
        # clang-cl 为 MS ABI，复用 vcpkg MSVC triplet 预编译库。
        # triplet 由 CMakeLists.txt 在 project() 前固定为 x64-windows-static-md，
        # 避免 vcpkg 按编译器自动切到 x64-clang-cl 全量重建依赖。
        compiler = (
            f' -DCMAKE_C_COMPILER="{CLANG_CL}"'
            f' -DCMAKE_CXX_COMPILER="{CLANG_CL}"'
        )

    cmd = (
        f'cmake -S "{ROOT}" -B "{BUILD_DIR}" -G Ninja '
        f'-DCMAKE_TOOLCHAIN_FILE="{TOOLCHAIN}" '
        f'-DCMAKE_BUILD_TYPE={args.build_type}{compiler}'
    )
    print(f">> {cmd}", flush=True)
    return vs_env.run_in_vs_env(cmd, cwd=ROOT)


if __name__ == "__main__":
    sys.exit(main())
