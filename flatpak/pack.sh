#!/bin/bash
set -euo pipefail

# Ensure we are in the project root (one level up from this script)
cd "$(dirname "$0")/.."

BUILD_DIR="${BUILD_DIR:-build-flatpak}"
REPO_DIR="${REPO_DIR:-repo-flatpak}"
MANIFEST="${MANIFEST:-flatpak/io.github.windy.breeze.yml}"
BUNDLE_NAME="${BUNDLE_NAME:-breeze.flatpak}"
SPLIT_DEBUG_INFO="${SPLIT_DEBUG_INFO:-build/symbols}"

echo "Building Flutter application (Release)..."
FLUTTER_BUILD_ARGS=(linux --release)

if [[ -n "${SPLIT_DEBUG_INFO}" ]]; then
  FLUTTER_BUILD_ARGS+=("--split-debug-info=${SPLIT_DEBUG_INFO}")
fi

if [[ -n "${SENTRY_DSN:-}" ]]; then
  FLUTTER_BUILD_ARGS+=("--dart-define=sentry_dsn=${SENTRY_DSN}")
fi

flutter build "${FLUTTER_BUILD_ARGS[@]}"

CRASHPAD_HANDLER="build/linux/x64/release/bundle/lib/crashpad_handler"
if [[ -f "${CRASHPAD_HANDLER}" ]]; then
  echo "Fixing executable permission: ${CRASHPAD_HANDLER}"
  chmod +x "${CRASHPAD_HANDLER}"
else
  echo "Missing file: ${CRASHPAD_HANDLER}"
  exit 1
fi

echo "Building Flatpak..."
mkdir -p "${BUILD_DIR}" "${REPO_DIR}"

FLATPAK_BUILDER_ARGS=(--force-clean "--repo=${REPO_DIR}")
if [[ "${FLATPAK_BUILDER_USER:-1}" == "1" ]]; then
  FLATPAK_BUILDER_ARGS+=(--user)
fi
FLATPAK_INSTALL_DEPS_FROM_VALUE="${FLATPAK_INSTALL_DEPS_FROM-}"
if [[ -z "${FLATPAK_INSTALL_DEPS_FROM_VALUE}" ]]; then
  FLATPAK_INSTALL_DEPS_FROM_VALUE="flathub"
fi
if [[ -n "${FLATPAK_INSTALL_DEPS_FROM_VALUE}" ]]; then
  FLATPAK_BUILDER_ARGS+=("--install-deps-from=${FLATPAK_INSTALL_DEPS_FROM_VALUE}")
fi

flatpak-builder "${FLATPAK_BUILDER_ARGS[@]}" "${BUILD_DIR}" "${MANIFEST}"

echo "Creating Flatpak bundle..."
flatpak build-bundle "${REPO_DIR}" "${BUNDLE_NAME}" io.github.windy.breeze

echo "Done: ${BUNDLE_NAME}"
echo "Install for testing: flatpak install --user ${BUNDLE_NAME}"
