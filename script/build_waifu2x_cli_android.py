#!/usr/bin/env python3
"""Build the waifu2x Android CLI binary and package it as a fake .so.

The resulting executable is renamed to `libwaifu2x_cli.so` so Gradle will
package it into the APK's lib/<abi>/ directory. At runtime the app copies it
to a writable directory, chmod +x, and executes it via Process.run.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from android_build_utils import (
    cmake_exe,
    llvm_strip,
    ndk_root,
    ninja_exe,
    toolchain_file,
)

ABIS = ["arm64-v8a"]
ANDROID_PLATFORM = "android-24"
BUILD_PARALLEL = os.cpu_count() or 4

UPSTREAM_REPO = "https://github.com/tumuyan/RealSR-NCNN-Android.git"
UPSTREAM_COMMIT = "0eb16763761e46f55c6223439ca1ad20216bc4ab"


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def deps_dir() -> Path:
    return project_root() / "third_party" / "android_ncnn_deps"


def jni_libs_dir() -> Path:
    return project_root() / "android" / "app" / "src" / "main" / "jniLibs"


def run(args: list[str], cwd: Path) -> None:
    print(f">>> {' '.join(args)}\n  cwd: {cwd}")
    subprocess.run(args, cwd=cwd, check=True)


def ensure_upstream_source() -> None:
    """Clone the upstream RealSR-NCNN-Android source if it is missing.

    The waifu2x CLI CMakeLists.txt references source files under
    third_party/RealSR-NCNN-Android. This directory is not tracked in the
    main repository, so we fetch it on demand to keep CI/local builds working.
    """
    target = project_root() / "third_party" / "RealSR-NCNN-Android"
    marker = (
        target
        / "RealSR-NCNN-Android-CLI"
        / "Waifu2x"
        / "src"
        / "main"
        / "jni"
        / "main.cpp"
    )
    if marker.exists():
        return

    print(f"Upstream source missing, cloning {UPSTREAM_REPO} ...")
    if target.exists():
        shutil.rmtree(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["git", "clone", UPSTREAM_REPO, str(target)],
        check=True,
    )
    subprocess.run(
        ["git", "-C", str(target), "checkout", UPSTREAM_COMMIT],
        check=True,
    )

    # Verify the expected source files are present.
    if not marker.exists():
        raise RuntimeError(
            f"waifu2x source not found after clone: {marker}"
        )
    print(f"Upstream source ready at: {target}")


def build_abi(abi: str) -> None:
    ensure_upstream_source()

    src_dir = project_root() / "android" / "app" / "src" / "main" / "cpp" / "waifu2x_cli"
    build_dir = project_root() / "build" / f"waifu2x-cli-android-{abi.replace('-', '_')}"
    fake_so_name = "libwaifu2x_cli.so"
    dep_abi_dir = deps_dir() / "waifu2x-cli-android" / abi
    jni_abi_dir = jni_libs_dir() / abi
    dep_so = dep_abi_dir / fake_so_name
    jni_so = jni_abi_dir / fake_so_name

    if (
        dep_so.exists()
        and jni_so.exists()
        and not os.environ.get("FORCE_REBUILD")
    ):
        print(f"{abi}: {fake_so_name} already exists, skipping.")
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
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DCMAKE_MAKE_PROGRAM={ninja}",
        "-G",
        "Ninja",
        str(src_dir),
    ]
    run(configure_args, build_dir)
    run(
        [
            str(cmake),
            "--build",
            ".",
            "--",
            f"-j{BUILD_PARALLEL}",
        ],
        build_dir,
    )

    exe = build_dir / "waifu2x-ncnn"
    if not exe.exists():
        raise RuntimeError(f"waifu2x-ncnn executable not found at {exe}")

    # Strip to reduce size.
    strip = llvm_strip()
    if strip.exists():
        run([str(strip), str(exe)], build_dir)

    # Package as a fake shared library so Gradle will include it in the APK.
    fake_so_name = "libwaifu2x_cli.so"

    dep_abi_dir = deps_dir() / "waifu2x-cli-android" / abi
    if dep_abi_dir.exists():
        shutil.rmtree(dep_abi_dir)
    dep_abi_dir.mkdir(parents=True)
    fake_so_dep = dep_abi_dir / fake_so_name
    shutil.copy2(exe, fake_so_dep)

    jni_abi_dir = jni_libs_dir() / abi
    jni_abi_dir.mkdir(parents=True, exist_ok=True)
    fake_so_jni = jni_abi_dir / fake_so_name
    shutil.copy2(exe, fake_so_jni)

    size_mb = fake_so_jni.stat().st_size / 1024 / 1024
    print(f"{abi}: built {fake_so_name} ({size_mb:.2f} MB)")


def main() -> int:
    print(f"Building waifu2x CLI for: {', '.join(ABIS)}")
    for abi in ABIS:
        build_abi(abi)
    print(f"\nwaifu2x CLI installed to: {deps_dir() / 'waifu2x-cli-android'}")
    print(f"jniLibs updated at:       {jni_libs_dir()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
