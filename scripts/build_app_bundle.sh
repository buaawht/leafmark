#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/LeafMark.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c release --product LeafMark

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp ".build/release/LeafMark" "$MACOS_DIR/LeafMark"
cp "Resources/LeafMark.app/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/LeafMark"

echo "$APP_DIR"
