#!/usr/bin/env python3
"""Scan pubspec.yaml dependencies for unused packages (no package: import)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"

SDK_DEPS = {
    "flutter",
    "flutter_localizations",
    "flutter_test",
    "integration_test",
}

# Known packages used without direct Dart import (native plugin / build / codegen tooling).
KEEP_WITHOUT_IMPORT = {
    # ObjectBox native libs loaded via objectbox package
    "objectbox_flutter_libs",
    # Material icons font package (often only via Icons.xxx, no import needed? actually cupertino_icons needs import for CupertinoIcons)
    # Build hooks / FRB toolchain used by hook/build.dart and tooling
    "code_assets",
    "hooks",
    "native_toolchain_rust",
    # Dev codegen / release tools (invoked via CLI, not import)
    "build_runner",
    "auto_route_generator",
    "objectbox_generator",
    "freezed",
    "json_serializable",
    "sentry_dart_plugin",
    "flutter_launcher_icons",
    "flutter_native_splash",
    "flutter_lints",
    # slang may be CLI only; slang_flutter is imported
    "slang",
}

IMPORT_RE = re.compile(r"""(?:import|export)\s+['"]package:([^/'"]+)""")


def parse_pubspec_deps(text: str) -> tuple[set[str], set[str]]:
    """Very small YAML-ish parser for top-level dependency maps."""
    deps: set[str] = set()
    dev_deps: set[str] = set()
    section: str | None = None
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        # top-level keys
        if re.match(r"^[A-Za-z0-9_]+:\s*$", line) or re.match(
            r"^[A-Za-z0-9_]+:\s+\S", line
        ):
            key = line.split(":", 1)[0].strip()
            if key == "dependencies":
                section = "deps"
                continue
            if key == "dev_dependencies":
                section = "dev"
                continue
            if key in {
                "dependency_overrides",
                "flutter",
                "environment",
                "sentry",
                "flutter_launcher_icons",
                "flutter_native_splash",
            }:
                section = None
                continue
            # other top-level
            if not line.startswith(" ") and not line.startswith("\t"):
                if key not in {"name", "description", "publish_to", "version"}:
                    # leaving unknown section
                    if section in {"deps", "dev"} and not line.startswith(" "):
                        section = None
                continue

        if section not in {"deps", "dev"}:
            continue
        # dependency entry: two-space indent name:
        m = re.match(r"^  ([A-Za-z0-9_]+):", line)
        if not m:
            continue
        name = m.group(1)
        if name in SDK_DEPS:
            continue
        if section == "deps":
            deps.add(name)
        else:
            dev_deps.add(name)
    return deps, dev_deps


def collect_used_packages() -> set[str]:
    used: set[str] = set()
    search_roots = [
        ROOT / "lib",
        ROOT / "test",
        ROOT / "integration_test",
        ROOT / "script",
        ROOT / "packages",
        ROOT / "hook",
    ]
    for base in search_roots:
        if not base.exists():
            continue
        for path in base.rglob("*.dart"):
            try:
                text = path.read_text(encoding="utf-8")
            except OSError:
                continue
            used.update(IMPORT_RE.findall(text))
    return used


def main() -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    deps, dev_deps = parse_pubspec_deps(text)
    used = collect_used_packages()

    unused_runtime = sorted(deps - used)
    unused_dev = sorted(dev_deps - used)

    print("=== Possibly unused runtime deps (no package: import) ===")
    for name in unused_runtime:
        tag = " [often keep: native/build]" if name in KEEP_WITHOUT_IMPORT else ""
        print(f"  - {name}{tag}")

    print()
    print("=== Possibly unused dev deps (no package: import) ===")
    for name in unused_dev:
        tag = " [often keep: CLI/codegen]" if name in KEEP_WITHOUT_IMPORT else ""
        print(f"  - {name}{tag}")

    print()
    print("=== Likely truly unused (no import AND not known keep) ===")
    true_unused = [n for n in unused_runtime if n not in KEEP_WITHOUT_IMPORT]
    true_unused_dev = [n for n in unused_dev if n not in KEEP_WITHOUT_IMPORT]
    if not true_unused and not true_unused_dev:
        print("  (none)")
    for name in true_unused:
        print(f"  - {name}  (runtime)")
    for name in true_unused_dev:
        print(f"  - {name}  (dev)")

    print()
    print(
        f"runtime: {len(deps)} total, {len(deps & used)} imported, "
        f"{len(unused_runtime)} no-import"
    )
    print(
        f"dev: {len(dev_deps)} total, {len(dev_deps & used)} imported, "
        f"{len(unused_dev)} no-import"
    )


if __name__ == "__main__":
    main()
