"""定位 Visual Studio 并生成 MSVC 编译环境（vcvars64）。

提供：
- vcvars_path(): 返回 vcvars64.bat 的绝对路径
- run_in_vs_env(command, cwd): 在 vcvars64 环境中执行一条 shell 命令
"""
from __future__ import annotations

import os
import subprocess
from pathlib import Path


def vswhere() -> Path:
    """vswhere.exe 的位置。"""
    pf86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")
    return Path(pf86) / "Microsoft Visual Studio" / "Installer" / "vswhere.exe"


def vcvars_path() -> Path:
    """定位最新的 VS 安装并返回 vcvars64.bat 路径。"""
    vswhere_exe = vswhere()
    if not vswhere_exe.exists():
        raise RuntimeError(f"未找到 vswhere.exe: {vswhere_exe}")
    out = subprocess.check_output(
        [
            str(vswhere_exe),
            "-latest",
            "-products", "*",
            "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
            "-property", "installationPath",
        ],
        text=True,
    ).strip()
    if not out:
        raise RuntimeError("未找到安装了 MSVC C++ 工具链的 Visual Studio")
    vcvars = Path(out) / "VC" / "Auxiliary" / "Build" / "vcvars64.bat"
    if not vcvars.exists():
        raise RuntimeError(f"未找到 vcvars64.bat: {vcvars}")
    return vcvars


def run_in_vs_env(command: str, cwd: Path | None = None) -> int:
    """在 MSVC x64 环境中执行 command（经 cmd.exe 串联 vcvars64.bat）。"""
    vc = vcvars_path()
    full = f'call "{vc}" >nul && {command}'
    return subprocess.run(full, shell=True, cwd=cwd).returncode
