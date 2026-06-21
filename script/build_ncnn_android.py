#!/usr/bin/env python3
"""Build ncnn Android shared libraries from source.

This script compiles ncnn for the ABIs used by Breeze:
    arm64-v8a, armeabi-v7a, x86, x86_64

It produces libncnn.so without OpenMP (to avoid the runtime affinity abort on
some Android devices), with Vulkan enabled, and copies the result to both:
    - third_party/android_ncnn_deps/ncnn-android-vulkan-shared/<abi>/
    - android/app/src/main/jniLibs/<abi>/

Usage:
    python script/build_ncnn_android.py

Requirements:
    - Android NDK (>= 29 recommended)
    - Android SDK CMake (>= 3.22.1)
    - git
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen
from urllib.error import URLError

from android_build_utils import (
    cmake_exe,
    llvm_strip,
    ndk_root,
    ninja_exe,
    toolchain_file,
)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
NCNN_VERSION = "20250503"
NCNN_REPO = "https://github.com/Tencent/ncnn.git"
ABIS = ["arm64-v8a", "armeabi-v7a", "x86", "x86_64"]
ANDROID_PLATFORM = "android-24"
BUILD_PARALLEL = os.cpu_count() or 4


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def ncnn_src_dir() -> Path:
    return project_root() / "third_party" / "ncnn-src"


def deps_dir() -> Path:
    return project_root() / "third_party" / "android_ncnn_deps"


def prebuilt_base_dir() -> Path:
    return deps_dir() / "ncnn-android-vulkan-shared"


def jni_libs_dir() -> Path:
    return project_root() / "android" / "app" / "src" / "main" / "jniLibs"


def run(args: list[str], cwd: Path) -> None:
    print(f"\n>>> {' '.join(args)}\n  cwd: {cwd}")
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
    build_dir = src / f"build-android-{abi.replace('-', '_')}"
    install_dir = build_dir / "install"

    # Clean previous build to avoid stale CMake cache
    if build_dir.exists():
        shutil.rmtree(build_dir)
    build_dir.mkdir(parents=True)

    cmake = cmake_exe()
    ninja = ninja_exe()

    if not cmake.exists():
        raise RuntimeError(f"cmake not found: {cmake}")
    if not ninja.exists():
        raise RuntimeError(f"ninja not found: {ninja}")

    configure_args = [
        str(cmake),
        f"-DCMAKE_TOOLCHAIN_FILE={toolchain_file()}",
        f"-DANDROID_ABI={abi}",
        f"-DANDROID_PLATFORM={ANDROID_PLATFORM}",
        "-DNCNN_VULKAN=ON",
        "-DNCNN_OPENMP=OFF",
        "-DNCNN_SHARED_LIB=ON",
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

    # Strip to reduce size
    libncnn = install_dir / "lib" / "libncnn.so"
    strip = llvm_strip()
    if strip.exists():
        run([str(strip), str(libncnn)], build_dir)
    else:
        print(f"Warning: llvm-strip not found, skipping strip for {abi}")

    # Copy to third_party dependency tree
    target_dir = prebuilt_base_dir() / abi
    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True)

    shutil.copytree(install_dir / "lib", target_dir / "lib")
    shutil.copytree(install_dir / "include", target_dir / "include")

    # Copy to jniLibs so Gradle packages the correct version
    jni_abi_dir = jni_libs_dir() / abi
    jni_abi_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(target_dir / "lib" / "libncnn.so", jni_abi_dir / "libncnn.so")

    final_size = (target_dir / "lib" / "libncnn.so").stat().st_size
    print(f"{abi}: built and installed ({final_size / 1024 / 1024:.2f} MB)")


def main() -> int:
    print(f"Project root: {project_root()}")
    print(f"Android SDK:  {android_sdk_root()}")
    print(f"NDK:          {ndk_root()}")
    print(f"ABIs:         {', '.join(ABIS)}")
    print()

    try:
        ensure_ncnn_source()

        for abi in ABIS:
            build_abi(abi)

        print("\nAll ABIs built successfully.")
        print(f"Prebuilt ncnn installed to: {prebuilt_base_dir()}")
        print(f"jniLibs updated at:         {jni_libs_dir()}")
        return 0

    except subprocess.CalledProcessError as e:
        print(f"\nBuild failed: {e}", file=sys.stderr)
        return e.returncode
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
