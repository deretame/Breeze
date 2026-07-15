#!/usr/bin/env python3
"""Convert relative import/export to package:zephyr/... in lib/."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
PACKAGE = "zephyr"
SKIP_DIR_PREFIXES = ("src/rust/",)
SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart")

PATTERN = re.compile(r"""^(import|export)\s+(['"])([^'"]+)\2(.*)$""")


def should_skip(path: Path) -> bool:
    rel = path.relative_to(ROOT).as_posix()
    if any(rel.startswith(p) for p in SKIP_DIR_PREFIXES):
        return True
    return path.name.endswith(SKIP_SUFFIXES)


def is_relative_uri(uri: str) -> bool:
    return not (uri.startswith("dart:") or uri.startswith("package:"))


def to_package_uri(file_path: Path, uri: str) -> str | None:
    if not is_relative_uri(uri):
        return None
    target = (file_path.parent / uri).resolve()
    try:
        rel = target.relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return None
    return f"package:{PACKAGE}/{rel}"


def process_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    newline = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    changes = 0
    out: list[str] = []

    for line in lines:
        m = PATTERN.match(line)
        if not m:
            out.append(line)
            continue

        kind, quote, uri, rest = m.group(1), m.group(2), m.group(3), m.group(4)
        if not is_relative_uri(uri):
            out.append(line)
            continue

        new_uri = to_package_uri(path, uri)
        if new_uri is None:
            out.append(line)
            continue

        new_line = f"{kind} {quote}{new_uri}{quote}{rest}"
        if new_line != line:
            changes += 1
            out.append(new_line)
        else:
            out.append(line)

    if changes:
        path.write_text(newline.join(out) + newline, encoding="utf-8")
    return changes


def main() -> None:
    changed_files: list[tuple[str, int]] = []
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if should_skip(path):
            continue
        n = process_file(path)
        if n:
            changed_files.append((path.relative_to(ROOT).as_posix(), n))
            total += n

    print(f"Changed {len(changed_files)} files, {total} import/export lines")
    for rel, n in changed_files:
        print(f"  {n:3d}  {rel}")


if __name__ == "__main__":
    main()
