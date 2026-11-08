#!/usr/bin/env bash
# Exports the game for the web into play/ (served by GitHub Pages).
# Stamps the version (from VERSION), the build time and the commit it was built from into
# scripts/core/build_info.gd, so the title, Settings and every play log say exactly which build it is.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(tr -d '[:space:]' < VERSION)"
BUILT="$(date -u +'%Y-%m-%d %H:%M UTC')"
COMMIT="$(git describe --always --dirty 2>/dev/null || echo unknown)"
cat > scripts/core/build_info.gd <<GD
class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "$VERSION"
const BUILT := "$BUILT"
const COMMIT := "$COMMIT"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
GD
godot --headless --import >/dev/null 2>&1 || true
rm -rf play && mkdir -p play
godot --headless --export-release "Web" play/index.html
touch play/.gdignore
echo "Exported $VERSION ($BUILT, $COMMIT) to play/"
