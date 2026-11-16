#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
runtime="$(mktemp -d)"
trap 'rm -rf "$runtime"' EXIT
export XDG_DATA_HOME="$runtime/data" XDG_CONFIG_HOME="$runtime/config" XDG_CACHE_HOME="$runtime/cache"
"$GODOT_BIN" --headless --editor --import --quit > "$runtime/import.log" 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' "$runtime/import.log"; then exit 1; fi
# First import bootstraps native template resources. Validate a settled editor scan too.
"$GODOT_BIN" --headless --editor --import --quit > "$runtime/validation.log" 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' "$runtime/validation.log"; then exit 1; fi
"$GODOT_BIN" --headless --path . res://tests/foundation.tscn > "$runtime/test.log" 2>&1 || { cat "$runtime/test.log"; exit 1; }
if rg -n 'SCRIPT ERROR|^ERROR:' "$runtime/test.log"; then exit 1; fi
rg 'PASS:|FOUNDATION_RESULT' "$runtime/test.log"
