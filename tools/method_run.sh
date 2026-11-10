#!/bin/sh
# The final method (test-method research, Stage 4): one command, one RESULT.
#   tools/method_run.sh ramp          # ramp,c2_more with the next profile k0..k4 (logged)
#   tools/method_run.sh ramp k3       # a chosen profile
#   tools/method_run.sh c2_more       # c2's short declared stretches only
# The builder's controls (test-only fixtures, off by default):
#   FIXTURE=n5 tools/method_run.sh ramp      # also: hub / early / se_test / se_game (c2_more)
# Output: appdata/method/runs/<id>/ (verdict.txt, trace.json, logs, shots).
# Exit: PASS 0, FAIL 1, INCOMPLETE 2, TEST 3, NOT HEALTHY 4.
# Muted, behind the user's windows (tools/run_test.sh); refuses a second game.
# Diagnostic recording (FN_RECORD=1) is not built in this build (cut 1).
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
WHAT="${1:-ramp}"
case "$WHAT" in
	ramp) PLAN="ramp,c2_more" ;;
	c2_more) PLAN="c2_more" ;;
	# #6, the ghat (2026-11-09): every scenario, or GHAT=ghat_heat,ghat_net ... for some
	ghat) PLAN="${GHAT:-ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_spring,ghat_marks}"; [ -z "$2" ] && set -- "$1" k3 ;;
	*) echo "usage: method_run.sh ramp [k0..k4] | c2_more | ghat (GHAT=scenarios, FIXTURE=plants)"; exit 3 ;;
esac
STATE="$ROOT/appdata/method"
mkdir -p "$STATE/runs"
K="$2"
if [ -z "$K" ]; then
	n=$(cat "$STATE/next_k.txt" 2>/dev/null || echo 0)
	K="k$((n % 5))"
	echo $(( (n + 1) % 5 )) > "$STATE/next_k.txt"
fi
case "$K" in k0|k1|k2|k3|k4) ;; *) echo "unknown profile $K (k0..k4)"; exit 3 ;; esac
if [ -n "$FN_RECORD" ]; then echo "FN_RECORD: diagnostic recording is unsupported in this build (cut 1)"; exit 3; fi
if tasklist //FI "IMAGENAME eq godot*" 2>/dev/null | grep -qi godot; then
	echo "a Godot process is running: not launching (one game at a time)"; tasklist //FI "IMAGENAME eq godot*"; exit 3
fi
ID="$(date +%Y%m%d_%H%M%S)_${WHAT}_${K}${FIXTURE:+_$FIXTURE}"
OUT="$STATE/runs/$ID"
mkdir -p "$OUT/shots"
touch "$OUT/launch_mark"
{ echo "run $ID plan $PLAN profile $K fixture '${FIXTURE}' at $(date '+%F %T')"; echo "head $(git -C "$ROOT" rev-parse HEAD)"; git -C "$ROOT" status --porcelain; } > "$OUT/run_info.txt"
echo "method: $PLAN, profile $K -> $OUT"
echo "expected ~3-4 min (ramp,c2_more; c2_more alone ~2 min incl. the ~40 s compile); maximum: the phase deadlines + kill, cap 600 s"
GARGS="--method-profile=$K"
[ -n "$FIXTURE" ] && GARGS="$GARGS --method-fixture=$FIXTURE"
WROOT="$(cd "$ROOT" && pwd -W 2>/dev/null || pwd)"
python -u "$DIR/method/method_watch.py" "$WROOT" "$PLAN" "$(cd "$OUT" && pwd -W 2>/dev/null || pwd)" "$GARGS" 2>&1 | tee "$OUT/console.txt"
rc=$(sed -n 's/^RESULT: [A-Z ]* (exit \([0-9]\)).*/\1/p' "$OUT/verdict.txt" 2>/dev/null | head -1)
RUNS="$ROOT/appdata/playtest/runs"
for f in seg_1.log rig.txt method_events.txt c2.txt summary.txt compile.log; do
	[ -f "$RUNS/$f" ] && cp "$RUNS/$f" "$OUT/"
done
find "$ROOT/FindingNaresh/_shots" -maxdepth 1 \( -name 'test_*.png' -o -name 'c2_*.png' \) -newer "$OUT/launch_mark" -exec cp {} "$OUT/shots/" \; 2>/dev/null
exit "${rc:-3}"
