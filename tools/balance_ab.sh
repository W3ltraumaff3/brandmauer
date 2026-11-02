#!/usr/bin/env bash
# Interleaved A/B runner (docs/specs/balancing.md §2): every side runs the same seeds in ONE
# parallel pool, so a game-code change mid-batch (or CPU contention) hits all sides alike.
#   GODOT=/path/to/godot tools/balance_ab.sh <out_dir> <seeds> <umfragen> <players> <builds> <side>=<"args"> ...
#     builds: e.g. "ranged status summon"; "-" = no build (priority bots, e.g. with `immortal`)
#     side:   name=args, e.g.  base=  lead="place=lead"  imm="immortal"
# Writes <out_dir>/<side>.jsonl per side (one JSON line per run, all sides with the same keys).
# Environment:
#   JOBS=16          parallel Godot processes
#   CHARS="own"      cross every run with these characters (char=<id>); "own" = the build's
#                    own character (or the rotating ones without a build)
# Compare: python tools/balance_report.py --sides <out_dir> <base side> [build,umfrage]
#          python tools/balance_report.py --ab <out_dir>/a.jsonl <out_dir>/b.jsonl
set -u
GODOT="${GODOT:-godot}"
OUT="${1:?usage: balance_ab.sh <out_dir> <seeds> <umfragen> <players> <builds> <side>=<args> ...}"
SEEDS="$2"; UMF="$3"; PLAYERS="$4"; BUILDS="$5"; shift 5
[ $# -ge 1 ] || { echo "balance_ab: no sides given" >&2; exit 2; }
JOBS="${JOBS:-16}"
CHARS="${CHARS:-own}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
LIST="$OUT/runs.txt"
: > "$LIST"
# longest runs (most players) first, so the tail at the end stays short
for n in $PLAYERS; do for b in $BUILDS; do for c in $CHARS; do for u in $UMF; do for s in $(seq 1 "$SEEDS"); do
	for side in "$@"; do
		name="${side%%=*}"; args="${side#*=}"
		line="$name players=$n umfrage=$u seed=$s jobs=$JOBS tag=$name"
		[ "$b" != "-" ] && line="$line build=$b"
		[ "$c" != "own" ] && line="$line char=$c"
		echo "$line${args:+ $args}" >> "$LIST"
	done
done; done; done; done; done
started=$(date +%s)
mkdir -p "$OUT/parts"
rm -f "$OUT"/parts/*
# one file per run (JSON lines are tens of KB; parallel appends could interleave), joined below
xargs -P "$JOBS" -L 1 sh -c 'name="$1"; shift; f=$(mktemp -p "'"$OUT"'/parts" "$name.XXXXXX"); "'"$GODOT"'" --headless --path . -s res://tools/balance_sim.gd -- "$@" 2>/dev/null | grep "^{" > "$f"' _ < "$LIST"
fail=0
for side in "$@"; do
	name="${side%%=*}"
	cat "$OUT"/parts/"$name".* > "$OUT/$name.jsonl" 2>/dev/null
	want=$(grep -c "^$name " "$LIST")
	got=$(wc -l < "$OUT/$name.jsonl")
	echo "$name: $got of $want runs"
	[ "$got" -eq "$want" ] || fail=1
done
rm -rf "$OUT/parts"
echo "balance_ab: done in $(( $(date +%s) - started )) s, JOBS=$JOBS"
# Missing runs: a crash, or an unknown id in the sim args (the sim prints it to stderr).
[ "$fail" -eq 0 ] || { echo "balance_ab: some runs produced no line" >&2; exit 1; }
