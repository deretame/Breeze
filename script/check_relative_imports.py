#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent / "lib"
PAT = re.compile(r"""^(import|export)\s+(['"])([^'"]+)\2""")
SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart")


def main() -> None:
    found = []
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith("src/rust/"):
            continue
        if path.name.endswith(SKIP_SUFFIXES):
            continue
        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            m = PAT.match(line.strip())
            if not m:
                continue
            uri = m.group(3)
            if uri.startswith("dart:") or uri.startswith("package:"):
                continue
            found.append(f"{rel}:{i}: {line.strip()}")

    if not found:
        print("No relative import/export remaining in hand-written lib/ files.")
        return
    print(f"Found {len(found)} relative import/export lines:")
    for line in found:
        print(line)


if __name__ == "__main__":
    main()
