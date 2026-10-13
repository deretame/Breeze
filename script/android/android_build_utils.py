"""Common helpers for Android native build scripts.

Handles cross-platform discovery of Android SDK, NDK, CMake, Ninja and
llvm-strip. Works on Windows, Linux and macOS hosts.
"""

import os
import shutil
import sys
from pathlib import Path

NDK_VERSION = "29.0.14206865"
CMAKE_VERSION = "3.22.1"


def android_sdk_root() -> Path:
    """Return the Android SDK root path."""
    env = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    if env:
        return Path(env)

    if sys.platform == "win32":
        candidate = Path.home() / "AppData" / "Local" / "Android" / "Sdk"
    else:
        candidate = Path.home() / "Android" / "Sdk"

    if candidate.exists():
        return candidate

    raise RuntimeError(
        "Cannot find Android SDK. Please set ANDROID_SDK_ROOT or ANDROID_HOME."
    )


def ndk_root(version: str = NDK_VERSION) -> Path:
    """Return the Android NDK root path for the given version."""
    env = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_ROOT")
    if env:
        return Path(env)
    return android_sdk_root() / "ndk" / version


def toolchain_file(version: str = NDK_VERSION) -> Path:
    """Return the Android NDK CMake toolchain file path."""
    return ndk_root(version) / "build" / "cmake" / "android.toolchain.cmake"


def _host_prebuilt_dir() -> str:
    """Return the NDK prebuilt host directory name."""
    if sys.platform == "win32":
        return "windows-x86_64"
    if sys.platform == "darwin":
        return "darwin-x86_64"
    return "linux-x86_64"


def _exe_name(base: str) -> str:
    """Return the executable name with the correct suffix for the host OS."""
    return f"{base}.exe" if sys.platform == "win32" else base


def _find_tool(fallback: Path) -> Path:
    """Return the fallback path if it exists, otherwise search PATH."""
    if fallback.exists():
        return fallback
    from_path = shutil.which(fallback.name)
    if from_path:
        return Path(from_path)
    # Also try the base name without suffix in case PATH lookup needs it.
    from_path = shutil.which(fallback.stem)
    if from_path:
        return Path(from_path)
    return fallback


def cmake_exe(version: str = CMAKE_VERSION) -> Path:
    """Return the path to the Android SDK CMake executable."""
    fallback = android_sdk_root() / "cmake" / version / "bin" / _exe_name("cmake")
    return _find_tool(fallback)


def ninja_exe(version: str = CMAKE_VERSION) -> Path:
    """Return the path to the Android SDK Ninja executable."""
    fallback = android_sdk_root() / "cmake" / version / "bin" / _exe_name("ninja")
    return _find_tool(fallback)


def llvm_strip(version: str = NDK_VERSION) -> Path:
    """Return the path to the NDK llvm-strip executable."""
    return (
        ndk_root(version)
        / "toolchains"
        / "llvm"
        / "prebuilt"
        / _host_prebuilt_dir()
        / "bin"
        / _exe_name("llvm-strip")
    )
