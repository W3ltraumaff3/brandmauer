#!/usr/bin/env bash
# Runs tools/balance_sim.gd for every player count x Umfrage x seed in parallel
# and writes one JSON line per run (docs/specs/balancing.md).
#   GODOT=/path/to/godot tools/balance_matrix.sh <out.jsonl> [seeds=4] [mode=mortal|immortal|random|builds] [umfragen="0 1 2 3 4 5"]
# Then: python tools/balance_report.py <out.jsonl>
set -u
GODOT="${GODOT:-godot}"
OUT="${1:?usage: balance_matrix.sh <out.jsonl> [seeds] [mode] [umfragen]}"
SEEDS="${2:-4}"
MODE="${3:-mortal}"
UMFRAGEN="${4:-0 1 2 3 4 5}"
JOBS="${JOBS:-16}"   # one per logical core; the CPU is at 100 % with 16
cd "$(dirname "$0")/.."
: > "$OUT"
EXTRA=""
[ "$MODE" = "immortal" ] && EXTRA="immortal"
[ "$MODE" = "random" ] && EXTRA="random"     # randomised bots: item/weapon/stat/character analysis
{
	if [ "$MODE" = "builds" ]; then
		# human-like builds (solo and 4 players)
		for b in melee ranged status summon tank crit; do
			for n in 4 1; do
				for u in $UMFRAGEN; do
					for s in $(seq 1 "$SEEDS"); do
						echo "players=$n umfrage=$u seed=$s build=$b"
					done
				done
			done
		done
	else
		# longest runs (4 players) first, so the tail at the end stays short
		for n in 4 3 2 1; do
			for u in $UMFRAGEN; do
				for s in $(seq 1 "$SEEDS"); do
					echo "players=$n umfrage=$u seed=$s $EXTRA"
				done
			done
		done
	fi
} | xargs -P "$JOBS" -I{} sh -c "\"$GODOT\" --headless --path . -s res://tools/balance_sim.gd -- {} 2>/dev/null | grep '^{' >> \"$OUT\""
echo "balance_matrix: $(wc -l < "$OUT") runs in $OUT"
