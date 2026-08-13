"""构建 CMake 项目。

用法: python scripts/build.py [--clean] [-- -j N]
"""
from __future__ import annotations

import sys
from pathlib import Path

import vs_env

ROOT = Path(__file__).resolve().parents[2] / "quickjs-runtime"
BUILD_DIR = ROOT / "build"


def main() -> int:
    extra = " ".join(sys.argv[1:])
    cmd = f'cmake --build "{BUILD_DIR}" {extra}'.strip()
    print(f">> {cmd}", flush=True)
    return vs_env.run_in_vs_env(cmd, cwd=ROOT)


if __name__ == "__main__":
    sys.exit(main())
