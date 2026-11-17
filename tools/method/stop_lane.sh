#!/usr/bin/env bash
# Stop ONE lane's live game of this copy and verify it is gone (T4 v2 / T3 v2 lanes).
#   tools/method/stop_lane.sh [lane]     (no lane: lane a)
# 1) a quit command into that lane's folder only (tools/live.py refuses another lane's game),
# 2) wait up to 15 s for the lane's game pids to go, 3) kill what is left, 4) print the check.
# Other lanes' games are never touched. Exit 0 = gone (verified), 4 = still there.
cd "$(dirname "$0")/../.."
lane="$1"
LANE="$lane" python tools/live.py --quit --timeout 8 >/dev/null 2>&1
for i in $(seq 1 15); do
	p=$(python tools/method/godot_guard.py --pids "$lane")
	[ -z "$p" ] && break
	sleep 1
done
p=$(python tools/method/godot_guard.py --pids "$lane")
if [ -n "$p" ]; then
	for x in $p; do taskkill //PID "$x" //F >/dev/null 2>&1; done
	sleep 2
	p=$(python tools/method/godot_guard.py --pids "$lane")
fi
if [ -z "$p" ]; then
	echo "stop: lane '${lane:-a}' game gone (verified)"
	exit 0
fi
echo "stop: lane '${lane:-a}' game STILL RUNNING: $p"
exit 4
