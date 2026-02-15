#!/bin/bash
set -e

# Ensure we are in the project root (one level up from this script)
cd "$(dirname "$0")/.."

echo "🚀 Building Flutter application (Release)..."
flutter build linux --release

echo "📦 Building Flatpak..."
# Define directories
BUILD_DIR="build-flatpak"
REPO_DIR="repo-flatpak"
MANIFEST="flatpak/io.github.windy.breeze.yml"

# Build the Flatpak
# --force-clean: Clean the build directory
# --repo: Export to a repository (needed for bundling)
flatpak-builder --force-clean --repo=$REPO_DIR $BUILD_DIR $MANIFEST

echo "🎁 Creating Flatpak bundle..."
flatpak build-bundle $REPO_DIR breeze.flatpak io.github.windy.breeze

echo "✅ Done! 'breeze.flatpak' has been created in the project root."
echo "To install (for testing): flatpak install --user breeze.flatpak"
