"""克隆 vcpkg 到 third_party/vcpkg 并执行 bootstrap（跟随上游 master，不固定版本）。

版本策略：
- vcpkg 本体：克隆最新 master，不固定 release tag（上游漂移不影响依赖——见下）。
- 依赖版本：由 vcpkg.json 的 overrides 精确固定（全部直接+传递依赖），
  builtin-baseline 仅作版本数据库锚点（记录 vcpkg 的 build 版本 commit）。
- 为保证 builtin-baseline 指向的 commit（含各 port 的 git-tree）可解析，
  需要完整克隆；已存在的浅克隆会自动 unshallow 补全历史。

用法: python scripts/bootstrap_vcpkg.py
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "quickjs-runtime"
VCPKG_DIR = ROOT / "third_party" / "vcpkg"
VCPKG_URL = "https://github.com/microsoft/vcpkg.git"
VCPKG_EXE = VCPKG_DIR / "vcpkg.exe"


def run(cmd: list[str]) -> None:
    print(f">> {' '.join(cmd)}", flush=True)
    subprocess.run(cmd, check=True)


def ensure_full_history() -> None:
    """确保克隆包含完整历史（builtin-baseline 的 git-tree 可检出）。"""
    if not VCPKG_DIR.exists():
        return
    shallow = subprocess.run(
        ["git", "-C", str(VCPKG_DIR), "rev-parse", "--is-shallow-repository"],
        capture_output=True, text=True,
    ).stdout.strip()
    if shallow == "true":
        print("[unshallow] 现有克隆是浅克隆，补全历史（builtin-baseline 需要完整 git 对象）...")
        run(["git", "-C", str(VCPKG_DIR), "fetch", "--unshallow", "origin"])


def main() -> None:
    if VCPKG_EXE.exists():
        print(f"[skip] vcpkg 已就绪: {VCPKG_EXE}")
        ensure_full_history()
    else:
        if VCPKG_DIR.exists():
            print(f"[info] 目录已存在但缺少 vcpkg.exe，尝试复用: {VCPKG_DIR}")
        else:
            VCPKG_DIR.parent.mkdir(parents=True, exist_ok=True)
            print(f"[clone] 克隆 vcpkg (master) -> {VCPKG_DIR}")
            # 完整克隆（不固定版本）：baseline commit 的历史 git-tree 必须可解析
            run(["git", "clone", VCPKG_URL, str(VCPKG_DIR)])
        ensure_full_history()
        print("[bootstrap] 运行 bootstrap-vcpkg.bat ...")
        run([str(VCPKG_DIR / "bootstrap-vcpkg.bat")])

    print("[verify] vcpkg 版本:")
    run([str(VCPKG_EXE), "version"])


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(f"失败: {e}", file=sys.stderr)
        sys.exit(e.returncode)
