#!/usr/bin/env bash
# Imports assets and runs the headless Godot test suite.
#
#   tools/run_tests.sh            # all tests
#   tools/run_tests.sh audio      # only tests/godot/test_*audio*.gd
#
# Godot is taken from $GODOT, else from `godot` / `godot4` on PATH, else from
# a few default install locations.
set -euo pipefail

cd "$(dirname "$0")/.."

find_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		echo "$GODOT"
		return
	fi
	local c
	for c in godot godot4 Godot_v4.7.2-stable_linux.x86_64; do
		if command -v "$c" >/dev/null 2>&1; then
			command -v "$c"
			return
		fi
	done
	for c in \
		"$HOME/godot/godot" \
		"$HOME/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" \
		"$HOME/Downloads/Godot_v4.7.2-stable_win64_console.exe" \
		"/Applications/Godot.app/Contents/MacOS/Godot"; do
		if [[ -x "$c" ]]; then
			echo "$c"
			return
		fi
	done
	return 1
}

if ! GODOT_BIN="$(find_godot)"; then
	echo "Godot 4.7.2 not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi
echo "Using Godot: $GODOT_BIN"

"$GODOT_BIN" --headless --path . --import
if [[ $# -gt 0 ]]; then
	"$GODOT_BIN" --headless --path . -s res://tests/godot/run_tests.gd -- "$1"
else
	"$GODOT_BIN" --headless --path . -s res://tests/godot/run_tests.gd
fi
