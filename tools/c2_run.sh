#!/bin/sh
# Trial c2 (test-method research): state checks on top of c1's rig.
#   tools/c2_run.sh                 # runs ramp,c2_more (default)
#   tools/c2_run.sh c2_more         # only c2's own short stretches (~60 s)
# The observer (FindingNaresh/scripts/dev/C2Watch.gd) reads the game's state
# and writes appdata/playtest/runs/c2.txt and c2_verdict.txt. Three verdicts
# are printed apart: RIG (c1's), INNER CHECKS (the scenario's own, i.e. the
# driver and t_ramp's checks: not c2's verdict), and C2 STATE CHECKS.
# Exit: 0 rig healthy and no c2 rule fired; 1 a c2 rule fired; 2 rig not
# healthy (c2's verdict not counted).
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
RUNS="$ROOT/appdata/playtest/runs"
PLAN="${1:-ramp,c2_more}"
"$DIR/rig_run.sh" "$PLAN"
rig=$?
echo
if [ -f "$RUNS/c2_verdict.txt" ]; then
	cat "$RUNS/c2_verdict.txt"
else
	echo "==== C2 STATE CHECKS: no verdict (no watched scenario ended) ===="
fi
grep -h "^FIRE" "$RUNS/c2.txt" 2>/dev/null | sed 's/^/  /'
if [ $rig -ne 0 ]; then
	echo "  [c2 not counted: the rig is not healthy]"
	exit 2
fi
if grep -q "^FIRE" "$RUNS/c2.txt" 2>/dev/null; then exit 1; fi
exit 0
