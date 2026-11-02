#!/usr/bin/env bash
# Runs tools/balance_sim.gd for every player count x Umfrage x seed in parallel
# and writes one JSON line per run (docs/specs/balancing.md §2).
#   GODOT=/path/to/godot tools/balance_matrix.sh <out.jsonl> [seeds=4] [mode=mortal|immortal|random|builds] [umfragen="0 1 2 3 4 5"] [sim args...]
# Environment:
#   JOBS=16             parallel Godot processes
#   PLAYERS="4 3 2 1"   player counts (builds mode: "4 1")
#   BUILDS="melee ranged status summon tank crit"   builds mode only
#   CHARS="own oma"     cross every run with these characters (char=<id>); "own" = the
#                       build's own character (builds) or the rotating characters (other modes)
# Extra arguments go to every run, e.g. for an A/B pair on the same seeds:
#   tools/balance_matrix.sh a.jsonl 6 builds "0 2"
#   BUILDS=status tools/balance_matrix.sh b.jsonl 6 builds "0 2" start=kleber,tofu prefer=tofu
# Then: python tools/balance_report.py <out.jsonl>   (A/B: --ab a.jsonl b.jsonl)
set -u
GODOT="${GODOT:-godot}"
OUT="${1:?usage: balance_matrix.sh <out.jsonl> [seeds] [mode] [umfragen] [sim args...]}"
SEEDS="${2:-4}"
MODE="${3:-mortal}"
UMFRAGEN="${4:-0 1 2 3 4 5}"
shift $(( $# < 4 ? $# : 4 ))
ARGS="$*"
JOBS="${JOBS:-16}"   # one per logical core; the CPU is at 100 % with 16
BUILDS="${BUILDS:-melee ranged status summon tank crit}"
CHARS="${CHARS:-own}"
case "$MODE" in
	mortal|immortal|random|builds) ;;
	*) echo "balance_matrix: unknown mode $MODE" >&2; exit 2 ;;
esac
if [ "$MODE" = "builds" ]; then PLAYERS="${PLAYERS:-4 1}"; else PLAYERS="${PLAYERS:-4 3 2 1}"; fi
cd "$(dirname "$0")/.."
: > "$OUT"
EXTRA=""
[ "$MODE" = "immortal" ] && EXTRA="immortal"
[ "$MODE" = "random" ] && EXTRA="random"     # randomised bots: item/weapon/stat/character analysis
started=$(date +%s)
LIST="$OUT.runs"
{
	# longest runs (most players) first, so the tail at the end stays short
	for n in $PLAYERS; do
		for b in $( [ "$MODE" = "builds" ] && echo "$BUILDS" || echo "-" ); do
			for c in $CHARS; do
				for u in $UMFRAGEN; do
					for s in $(seq 1 "$SEEDS"); do
						line="players=$n umfrage=$u seed=$s jobs=$JOBS"
						[ "$b" != "-" ] && line="$line build=$b"
						[ "$c" != "own" ] && line="$line char=$c"
						echo "$line $EXTRA $ARGS"
					done
				done
			done
		done
	done
} > "$LIST"
# One file per run: JSON lines are tens of KB, and parallel appends to one file could interleave.
PARTS="$OUT.parts"
rm -rf "$PARTS"
mkdir -p "$PARTS"
xargs -P "$JOBS" -I{} sh -c "f=\$(mktemp -p \"$PARTS\"); \"$GODOT\" --headless --path . -s res://tools/balance_sim.gd -- {} 2>/dev/null | grep '^{' > \"\$f\"" < "$LIST"
cat "$PARTS"/* > "$OUT" 2>/dev/null
rm -rf "$PARTS"
want=$(wc -l < "$LIST")
got=$(wc -l < "$OUT")
rm -f "$LIST"
echo "balance_matrix: $got of $want runs in $OUT ($(( $(date +%s) - started )) s, JOBS=$JOBS)"
# Missing runs: a crash, or an unknown id in the sim args (the sim prints it to stderr).
[ "$got" -eq "$want" ] || { echo "balance_matrix: $(( want - got )) runs produced no line" >&2; exit 1; }
