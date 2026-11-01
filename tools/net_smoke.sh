#!/usr/bin/env bash
# Two-process network smoke test.
#  1. A headless host plus two headless clients (one with a wrong protocol
#     version that must be rejected, one that must receive snapshots and meta).
#  2. Reconnect: a headless host runs a real run, the client drops its connection
#     mid-run and must get back in with its session token (networking.md §7.4).
# Exit code: 0 if every process passed.
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

# Reconnect scenario: both sides must pass (the host checks it kept the player).
run host-run &
RUN_HOST_PID=$!
sleep 2
run join-reconnect
RECON_JOIN=$?
# The host exits on its own once the client left (or after its 60 s timeout).
wait "$RUN_HOST_PID"
RECON_HOST=$?

echo "net_smoke: join-badversion=$BAD join=$GOOD reconnect-join=$RECON_JOIN reconnect-host=$RECON_HOST"
[ "$BAD" -eq 0 ] && [ "$GOOD" -eq 0 ] && [ "$RECON_JOIN" -eq 0 ] && [ "$RECON_HOST" -eq 0 ] && exit 0
exit 1
