#!/usr/bin/env bash
# Two-process network smoke test: a headless host plus two headless clients
# (one with a wrong protocol version that must be rejected, one that must
# receive snapshots and meta). Exit code: 0 if both clients passed.
#   GODOT=/path/to/godot tools/net_smoke.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

run() { "$GODOT" --headless --path . -s res://tools/net_smoke.gd -- "$1"; }

run host &
HOST_PID=$!
sleep 2

run join-badversion
BAD=$?
run join
GOOD=$?

# Give the host a moment to notice the client leaving, then make sure it is gone.
for _ in 1 2 3 4 5 6; do
	kill -0 "$HOST_PID" 2>/dev/null || break
	sleep 1
done
kill "$HOST_PID" 2>/dev/null
wait "$HOST_PID" 2>/dev/null

echo "net_smoke: join-badversion=$BAD join=$GOOD"
[ "$BAD" -eq 0 ] && [ "$GOOD" -eq 0 ] && exit 0
exit 1
