#!/usr/bin/env python3
"""Package Android NCNN super-resolution models into realsr-android.7z.

Usage:
    python script/build_android_ncnn_models.py <models_source_dir>

Example:
    python script/build_android_ncnn_models.py \
        third_party/RealSR-NCNN-Android/RealSR-NCNN-Android-CLI/assets/Linux-x64

The source directory is expected to contain model directories such as:
    models-pro/
    models-cunet/
    models-upconv_7_anime_style_art_rgb/
    models-upconv_7_photo/

For a release package matching the default Android config, prepare a source
directory that contains only the files actually referenced by
lib/util/real_sr/android_ncnn_model_config.dart.  As of the current config,
this means:

    models-pro/up2x-{conservative,no-denoise,denoise3x}.param/.bin
    models-se/up2x-{denoise1x,denoise2x}.param/.bin
    models-cunet/noise{0,1,2,3}_scale2.0x_model.param/.bin
    models-upconv_7_anime_style_art_rgb/scale2.0x_model.param/.bin
    models-upconv_7_photo/scale2.0x_model.param/.bin

The output archive is written to:
    realsr-android.7z

Upload this file to the breeze-binary release hosting.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path


def find_py7zr():
    try:
        import py7zr
        return py7zr
    except ImportError:
        return None


def find_7z_tool():
    """Find an available 7z command-line tool (Bandizip `bz` or 7-Zip `7z`)."""
    for name in ("bz", "7z", "7za"):
        path = shutil.which(name)
        if path:
            return path, name
    return None, None


def create_7z_py7zr(py7zr, output: Path, file_pairs):
    with py7zr.SevenZipFile(output, "w") as archive:
        for full_path, arcname in file_pairs:
            archive.write(full_path, arcname)


def create_7z_external(tool_path: str, tool_name: str, output: Path, source: Path, file_pairs):
    """Use an external 7z CLI to create the archive.

    The file pairs are relative to [source]; we run the tool with [source] as the
    working directory so that archive entries have the correct top-level paths.
    """
    # Build a list of relative paths.  Using individual files preserves directory
    # structure when the tool runs inside [source].
    rel_paths = [arcname.replace("\\", "/") for _, arcname in file_pairs]

    if tool_name == "bz":
        cmd = [tool_path, "c", "-r", "-l:5", str(output), *rel_paths]
    else:
        cmd = [tool_path, "a", "-t7z", "-mx=5", str(output), *rel_paths]

    subprocess.run(cmd, cwd=source, check=True)


def main() -> int:
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <models_source_dir>", file=sys.stderr)
        return 1

    source = Path(sys.argv[1]).resolve()
    if not source.is_dir():
        print(f"Source directory does not exist: {source}", file=sys.stderr)
        return 1

    project_root = Path(__file__).resolve().parent.parent
    output = project_root / "realsr-android.7z"

    model_dirs = [
        "models-pro",
        "models-cunet",
        "models-upconv_7_anime_style_art_rgb",
        "models-upconv_7_photo",
    ]

    files_to_archive = []
    for model_dir in model_dirs:
        src_dir = source / model_dir
        if not src_dir.exists():
            print(f"  skipping missing directory: {src_dir}")
            continue
        for root, _, files in os.walk(src_dir):
            for file in files:
                full_path = Path(root) / file
                arcname = str(full_path.relative_to(source))
                files_to_archive.append((str(full_path), arcname))
                print(f"  adding: {arcname}")

    if not files_to_archive:
        print("ERROR: no model files found", file=sys.stderr)
        return 1

    print(f"\nWriting {output} ...")

    py7zr = find_py7zr()
    if py7zr is not None:
        create_7z_py7zr(py7zr, output, files_to_archive)
    else:
        tool_path, tool_name = find_7z_tool()
        if tool_path is None:
            print(
                "ERROR: py7zr is not installed and no 7z CLI tool (bz/7z/7za) was found.\n"
                "Install py7zr with: pip install py7zr\n"
                "Or install Bandizip / 7-Zip and make sure its CLI is on PATH.",
                file=sys.stderr,
            )
            return 1
        print(f"Using external tool: {tool_path}")
        create_7z_external(tool_path, tool_name, output, source, files_to_archive)

    size_mb = output.stat().st_size / (1024 * 1024)
    print(f"Done. Archive size: {size_mb:.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
