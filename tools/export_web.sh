#!/usr/bin/env bash
# Exports the game for the web into play/ (served by GitHub Pages) and keeps the redirect at the site root.
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --import >/dev/null 2>&1 || true
rm -rf play && mkdir -p play
godot --headless --export-release "Web" play/index.html
touch play/.gdignore
ls -la play
