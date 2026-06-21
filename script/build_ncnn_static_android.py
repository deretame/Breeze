#!/usr/bin/env python3
"""Build static ncnn Android libraries from source for waifu2x CLI."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from android_build_utils import (
    cmake_exe,
    ndk_root,
    ninja_exe,
    toolchain_file,
)

NCNN_VERSION = "20250503"
NCNN_REPO = "https://github.com/Tencent/ncnn.git"
ABIS = ["arm64-v8a"]  # only need arm64 for the waifu2x CLI app
ANDROID_PLATFORM = "android-24"
BUILD_PARALLEL = os.cpu_count() or 4


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def ncnn_src_dir() -> Path:
    return project_root() / "third_party" / "ncnn-src"


def deps_dir() -> Path:
    return project_root() / "third_party" / "android_ncnn_deps"


def prebuilt_base_dir() -> Path:
    return deps_dir() / "ncnn-android-vulkan-static"


def run(args: list[str], cwd: Path) -> None:
    print(f">>> {' '.join(args)}\n  cwd: {cwd}")
    subprocess.run(args, cwd=cwd, check=True)


def ensure_ncnn_source() -> None:
    src = ncnn_src_dir()
    if (src / "CMakeLists.txt").exists():
        print(f"ncnn source already exists at {src}")
        return
    print(f"Cloning ncnn {NCNN_VERSION} ...")
    src.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "git",
            "clone",
            "--branch",
            NCNN_VERSION,
            "--depth",
            "1",
            "--recurse-submodules",
            "--shallow-submodules",
            NCNN_REPO,
            str(src),
        ],
        check=True,
    )


def build_abi(abi: str) -> None:
    src = ncnn_src_dir()
    build_dir = src / f"build-android-{abi.replace('-', '_')}-static"
    install_dir = build_dir / "install"
    target_dir = prebuilt_base_dir() / abi

    if (
        target_dir.exists()
        and (target_dir / "lib" / "libncnn.a").exists()
        and not os.environ.get("FORCE_REBUILD")
    ):
        print(f"{abi}: static ncnn already exists at {target_dir}, skipping.")
        return

    if build_dir.exists():
        shutil.rmtree(build_dir)
    build_dir.mkdir(parents=True)

    cmake = cmake_exe()
    ninja = ninja_exe()

    configure_args = [
        str(cmake),
        f"-DCMAKE_TOOLCHAIN_FILE={toolchain_file()}",
        f"-DANDROID_ABI={abi}",
        f"-DANDROID_PLATFORM={ANDROID_PLATFORM}",
        "-DNCNN_VULKAN=ON",
        "-DNCNN_OPENMP=OFF",
        "-DNCNN_SHARED_LIB=OFF",
        "-DNCNN_DISABLE_RTTI=OFF",
        "-DNCNN_DISABLE_EXCEPTION=OFF",
        "-DNCNN_BUILD_BENCHMARK=OFF",
        "-DNCNN_BUILD_EXAMPLES=OFF",
        "-DNCNN_BUILD_TOOLS=OFF",
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DCMAKE_INSTALL_PREFIX={install_dir}",
        f"-DCMAKE_MAKE_PROGRAM={ninja}",
        "-G",
        "Ninja",
        str(src),
    ]
    run(configure_args, build_dir)
    run(
        [
            str(cmake),
            "--build",
            ".",
            "--target",
            "install",
            "--",
            f"-j{BUILD_PARALLEL}",
        ],
        build_dir,
    )

    target_dir = prebuilt_base_dir() / abi
    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True)
    shutil.copytree(install_dir / "lib", target_dir / "lib")
    shutil.copytree(install_dir / "include", target_dir / "include")

    print(f"{abi}: static ncnn installed to {target_dir}")


def main() -> int:
    print(f"Building static ncnn for: {', '.join(ABIS)}")
    ensure_ncnn_source()
    for abi in ABIS:
        build_abi(abi)
    print(f"\nStatic ncnn installed to: {prebuilt_base_dir()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
