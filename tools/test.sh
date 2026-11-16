#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/fieldlab-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/fieldlab-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/fieldlab-cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/domain.gd
godot --headless --path . --script tests/physics.gd
godot --headless --path . --script tests/settings.gd
python3 tests/multiplayer.py
