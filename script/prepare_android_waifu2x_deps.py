#!/usr/bin/env python3
"""Prepare Android native dependencies for the waifu2x CLI module.

Downloads and extracts:
- OpenCV Android SDK (static libraries used by the waifu2x CLI)
- libwebp source (for CMake add_subdirectory build)

All dependencies are placed under:
    third_party/android_ncnn_deps/

These paths are referenced by:
    android/app/src/main/cpp/waifu2x_cli/CMakeLists.txt
    script/build_ncnn_static_android.py
    script/build_waifu2x_cli_android.py
"""

import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from urllib.request import urlopen
from urllib.error import URLError

OPENCV_VERSION = "4.11.0"
OPENCV_URL = f"https://github.com/opencv/opencv/releases/download/{OPENCV_VERSION}/opencv-{OPENCV_VERSION}-android-sdk.zip"

LIBWEBP_REPO = "https://github.com/webmproject/libwebp.git"


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def deps_dir() -> Path:
    return project_root() / "third_party" / "android_ncnn_deps"


def download(url: str, dest: Path) -> None:
    print(f"Downloading {url} ...")
    print(f"  -> {dest}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urlopen(url) as response, open(dest, "wb") as out_file:
            total = int(response.headers.get("content-length", 0))
            downloaded = 0
            chunk_size = 1024 * 1024
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                out_file.write(chunk)
                downloaded += len(chunk)
                if total > 0:
                    percent = downloaded * 100 // total
                    sys.stdout.write(f"\r  progress: {percent}% ({downloaded}/{total} bytes)")
                    sys.stdout.flush()
        print()
    except URLError as e:
        print(f"ERROR: failed to download {url}: {e}", file=sys.stderr)
        if dest.exists():
            dest.unlink()
        raise


def extract_zip(zip_path: Path, dest_dir: Path) -> None:
    print(f"Extracting {zip_path.name} ...")
    dest_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(dest_dir)


def setup_opencv() -> None:
    target = deps_dir() / "OpenCV-android-sdk"
    if (target / "sdk" / "native" / "jni" / "OpenCVConfig.cmake").exists():
        print("OpenCV Android SDK already exists, skipping.")
        return

    zip_name = f"opencv-{OPENCV_VERSION}-android-sdk.zip"
    zip_path = deps_dir() / zip_name

    if not zip_path.exists():
        download(OPENCV_URL, zip_path)

    extract_zip(zip_path, deps_dir())

    extracted = deps_dir() / f"opencv-{OPENCV_VERSION}-android-sdk"
    if extracted.exists():
        if target.exists():
            shutil.rmtree(target)
        shutil.move(str(extracted), str(target))

    zip_path.unlink(missing_ok=True)
    print(f"OpenCV ready at: {target}")


def setup_libwebp() -> None:
    target = deps_dir() / "libwebp"
    if (target / "CMakeLists.txt").exists():
        print("libwebp source already exists, skipping.")
        return

    deps_dir().mkdir(parents=True, exist_ok=True)
    print(f"Cloning libwebp from {LIBWEBP_REPO} ...")
    subprocess.run(
        ["git", "clone", "--depth", "1", LIBWEBP_REPO, str(target)],
        check=True,
    )
    print(f"libwebp ready at: {target}")


def main() -> int:
    print(f"Project root: {project_root()}")
    print(f"Dependencies will be placed in: {deps_dir()}")
    print()

    try:
        setup_opencv()
        setup_libwebp()
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        return 1

    print("\nAll Android waifu2x CLI dependencies are ready.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
