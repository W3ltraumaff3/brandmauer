#!/usr/bin/env bash
# runlist.sh <out_dir> <list file>: every line "<side> <sim args...>", run in one pool of JOBS
# Godot processes, joined into <out_dir>/<side>.jsonl (same as tools/balance_ab.sh).
set -u
GODOT="${GODOT:-/c/Users/Weltr/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$1"; LIST="$2"
JOBS="${JOBS:-16}"
cd "${TREE:-/c/PythonProjekte/Rogue Like AnticapAntiFa}"
mkdir -p "$OUT/parts"
rm -f "$OUT"/parts/*
started=$(date +%s)
xargs -P "$JOBS" -L 1 sh -c 'name="$1"; shift; f=$(mktemp -p "'"$OUT"'/parts" "$name.XXXXXX"); "'"$GODOT"'" --headless --path . -s res://tools/balance_sim.gd -- "$@" 2>/dev/null | grep "^{" > "$f"' _ < "$LIST"
for name in $(cut -d" " -f1 "$LIST" | sort -u); do
	cat "$OUT"/parts/"$name".* > "$OUT/$name.jsonl" 2>/dev/null
	want=$(grep -c "^$name " "$LIST")
	got=$(grep -c "^{" "$OUT/$name.jsonl")
	echo "$name: $got of $want runs"
done
rm -rf "$OUT/parts"
echo "done in $(( $(date +%s) - started )) s"
