"""sparse clone WPT（web-platform-tests）测试资产到 third_party/wpt。

只取 wpt_runner 需要的子集（fetch/api + testharness + common），
资产不入库（.gitignore 覆盖）。幂等：已存在则提示并退出。

用法: python scripts/bootstrap_wpt.py
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "quickjs-runtime"
WPT_DIR = ROOT / "third_party" / "wpt"
WPT_REPO = "https://github.com/web-platform-tests/wpt.git"
# 与 tests/wpt_runner.cpp / scripts/analyze_wpt.py 的消费范围一致
SPARSE_PATHS = [
    "/fetch/api",
    "/resources/testharness.js",
    "/resources/testharnessreport.js",
    "/resources/testharness.css",
    "/common",
]


def run(cmd: list[str], cwd: Path) -> None:
    print(f">> {' '.join(cmd)}", flush=True)
    subprocess.run(cmd, cwd=cwd, check=True)


def main() -> int:
    if (WPT_DIR / ".git").exists():
        print(f"已存在: {WPT_DIR}（如需更新请手动 git -C third_party/wpt pull）")
        return 0
    WPT_DIR.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "clone", "--depth", "1", "--filter=blob:none", "--sparse",
         WPT_REPO, str(WPT_DIR)], cwd=ROOT)
    run(["git", "sparse-checkout", "set", "--no-cone", *SPARSE_PATHS], cwd=WPT_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
