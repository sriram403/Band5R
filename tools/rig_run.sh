#!/bin/sh
# c1, the rig layer (research trial c1): a play-test run with its health
# proven from outside. Same arguments as tools/run_test.sh:
#   tools/rig_run.sh ramp
#   ARGS="--inject=N2@30" tools/rig_run.sh ramp     (the referee's injections:
#                                                    see dev/RigInject.gd)
# The game writes a heartbeat to appdata/playtest/runs/rig.txt; the watcher
# (tools/rig/rig_watch.py) reads it every second, stops a frozen / paused /
# broken run at once, and ends with two verdicts: RIG and INNER CHECKS
# (also in appdata/playtest/runs/rig_verdict.txt). Exit 0 = rig healthy.
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
RUNS="$ROOT/appdata/playtest/runs"
mkdir -p "$RUNS"
rm -f "$RUNS/rig.txt" "$RUNS/rig_verdict.txt" "$RUNS/rig_run.out" "$RUNS/finished.txt" "$RUNS/summary.txt"
"$DIR/run_test.sh" "$@" > "$RUNS/rig_run.out" 2>&1 &
RT=$!
python -u "$DIR/rig/rig_watch.py" "$RUNS" "$1" "$ROOT"
rc=$?
wait $RT 2>/dev/null
exit $rc
