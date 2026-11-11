#!/bin/sh
# The final method (test-method research, Stage 4): one command, one RESULT.
#   tools/method_run.sh ramp          # ramp,c2_more with the next profile k0..k4 (logged)
#   tools/method_run.sh ramp k3       # a chosen profile
#   tools/method_run.sh c2_more       # c2's short declared stretches only
# The builder's controls (test-only fixtures, off by default):
#   FIXTURE=n5 tools/method_run.sh ramp      # also: hub / early / se_test / se_game (c2_more)
# Speed research T1 (2026-11-10), the ghat only:
#   SPEED=fast tools/method_run.sh ghat      # the qualified scenarios fast + drawing off between
#        pictures (FAST=1, --nodraw), ghat_spring at 1x (game-code wall clocks), both at once
#        (two games, lanes a and b); a FIXTURE with free_coolant runs all at 1x. PAR=0: one after
#        the other. One RESULT per part, then the worst of the two (exit code).
#   LANE=b ...                               # a second game of this copy: appdata/playtest_b,
#                                            # FindingNaresh/_shots_b (lane a = the usual folders)
#   EXPECT_FAIL="text|text" ...              # T2: stop once every expected FAIL is on record
# Output: appdata/method/runs/<id>/ (verdict.txt, trace.json, logs, shots).
# Exit: PASS 0, FAIL 1, INCOMPLETE 2, TEST 3, NOT HEALTHY 4.
# Muted, behind the user's windows (tools/run_test.sh). Refuses a second game of this copy in the
# same lane, and any launch when 2 Godot processes already run on the PC (R2: at most 2).
# Diagnostic recording (FN_RECORD=1) is not built in this build (cut 1).
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
WHAT="${1:-ramp}"
# ---- T1: SPEED=fast splits a ghat plan into its fast part and its 1x part
FAST_OK="ghat_heat ghat_looks ghat_net ghat_places ghat_jug ghat_marks"
if [ "$SPEED" = "fast" ] && [ "$WHAT" = "ghat" ]; then
	ALL="${GHAT:-ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_spring,ghat_marks}"
	FP=""; SP=""
	for s in $(echo "$ALL" | tr ',' ' '); do
		case " $FAST_OK " in *" $s "*) FP="$FP${FP:+,}$s" ;; *) SP="$SP${SP:+,}$s" ;; esac
	done
	case ",$FIXTURE," in *,free_coolant,*)
		echo "SPEED=fast: FIXTURE has free_coolant (its plant reads the wall clock): all at 1x"; SP="$ALL"; FP="" ;; esac
	echo "SPEED=fast: fast + nodraw: ${FP:-none} | 1x: ${SP:-none}${SP:+ (game-code wall clocks: Camper cap window, free_coolant)}"
	echo - > "$ROOT/appdata/method/.last_fast"; echo - > "$ROOT/appdata/method/.last_1x"
	if [ -n "$FP" ] && [ -n "$SP" ] && [ "${PAR:-1}" = "1" ]; then
		( SPEED=_fast GHAT="$FP" LANE= sh "$0" ghat $2 2>&1 | sed -u 's/^/[fast] /' ) &
		bg=$!
		sleep 20     # the second launch after the first has started (the guard counts it)
		SPEED=_1x GHAT="$SP" LANE=b sh "$0" ghat $2 2>&1 | sed -u 's/^/[1x]   /'
		wait $bg
	else
		[ -n "$FP" ] && { SPEED=_fast GHAT="$FP" LANE= sh "$0" ghat $2 2>&1 | sed -u 's/^/[fast] /'; }
		[ -n "$SP" ] && { SPEED=_1x GHAT="$SP" LANE=${PAR_LANE:-} sh "$0" ghat $2 2>&1 | sed -u 's/^/[1x]   /'; }
	fi
	# the two parts' RESULT lines, and the worst status (NOT HEALTHY > TEST > FAIL > INCOMPLETE > PASS)
	rank() { case "$1" in 4) echo 0 ;; 3) echo 1 ;; 1) echo 2 ;; 2) echo 3 ;; 0) echo 8 ;; *) echo 1 ;; esac; }
	worst=0; wr=8
	for part in fast 1x; do
		d=$(cat "$ROOT/appdata/method/.last_$part" 2>/dev/null)
		[ -n "$d" ] && [ "$d" != "-" ] || continue
		l=$(head -1 "$d/verdict.txt" 2>/dev/null)
		echo "SPEED=fast $part part: ${l:-no verdict} ($d)"
		c=$(echo "$l" | sed -n 's/^RESULT: [A-Z ]* (exit \([0-9]\)).*/\1/p'); c=${c:-3}
		r=$(rank "$c"); [ "$r" -lt "$wr" ] && { wr=$r; worst=$c; }
	done
	echo "SPEED=fast: exit $worst"
	exit "$worst"
fi
case "$WHAT" in
	ramp) PLAN="ramp,c2_more" ;;
	c2_more) PLAN="c2_more" ;;
	# #6, the ghat (2026-11-09): every scenario, or GHAT=ghat_heat,ghat_net ... for some
	ghat) PLAN="${GHAT:-ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_spring,ghat_marks}"; [ -z "$2" ] && set -- "$1" k3 ;;
	*) echo "usage: method_run.sh ramp [k0..k4] | c2_more | ghat (GHAT=scenarios, FIXTURE=plants, SPEED=fast)"; exit 3 ;;
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
# ---- the guard (T1): this copy's lane free, at most 2 Godot on the PC
PT="playtest${LANE:+_$LANE}"
WROOT="$(cd "$ROOT" && pwd -W 2>/dev/null || pwd)"
MARK="$WROOT/appdata/$PT/runs"
GL=$(powershell.exe -NoProfile -NonInteractive -Command "Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | ForEach-Object { \"\$(\$_.ProcessId)\`t\$(\$_.CommandLine)\" }" 2>/dev/null | tr -d '\r')
all_n=$(printf '%s\n' "$GL" | grep -c '[0-9]')
mine=$(printf '%s\n' "$GL" | tr '\\' '/' | grep -ci "$(echo "$MARK" | tr '\\' '/')")
if [ "$mine" -gt 0 ]; then
	echo "a Godot of this copy is running in lane '${LANE:-a}': not launching"; printf '%s\n' "$GL"; exit 3
fi
if [ "$all_n" -ge 2 ]; then
	echo "2 Godot processes already run on this PC: not launching (at most 2)"; printf '%s\n' "$GL"; exit 3
fi
[ "$all_n" -ge 1 ] && echo "note: another game runs on this PC (speed numbers of this run are shared-PC numbers): $(printf '%s' "$GL" | cut -c1-160)"
ID="$(date +%Y%m%d_%H%M%S)_${WHAT}_${K}${FIXTURE:+_$FIXTURE}${SPEED:+$SPEED}${LANE:+_lane$LANE}"
OUT="$STATE/runs/$ID"
mkdir -p "$OUT/shots"
touch "$OUT/launch_mark"
case "$SPEED" in _fast) echo "$OUT" > "$STATE/.last_fast" ;; _1x) echo "$OUT" > "$STATE/.last_1x" ;; esac
{ echo "run $ID plan $PLAN profile $K fixture '${FIXTURE}' speed '${SPEED:-1x}' lane '${LANE:-a}' at $(date '+%F %T')"; echo "head $(git -C "$ROOT" rev-parse HEAD)"; git -C "$ROOT" status --porcelain; } > "$OUT/run_info.txt"
echo "method: $PLAN, profile $K, speed ${SPEED:-1x}, lane ${LANE:-a} -> $OUT"
echo "expected ~3-4 min (ramp,c2_more; c2_more alone ~2 min incl. the ~40 s compile); maximum: the phase deadlines + kill, cap 600 s"
GARGS="--method-profile=$K"
[ -n "$FIXTURE" ] && GARGS="$GARGS --method-fixture=$FIXTURE"
SHOTS="FindingNaresh/_shots"
if [ -n "$LANE" ]; then
	GARGS="$GARGS --shots-dir=res://_shots_$LANE"; SHOTS="FindingNaresh/_shots_$LANE"
	export NO_CHECK=1     # lane b never imports (lane a or the caller did; two imports at once would race)
fi
if [ "$SPEED" = "_fast" ]; then
	export FAST=1
	GARGS="$GARGS --nodraw"
fi
export LANE
python -u "$DIR/method/method_watch.py" "$WROOT" "$PLAN" "$(cd "$OUT" && pwd -W 2>/dev/null || pwd)" "$GARGS" 2>&1 | tee "$OUT/console.txt"
rc=$(sed -n 's/^RESULT: [A-Z ]* (exit \([0-9]\)).*/\1/p' "$OUT/verdict.txt" 2>/dev/null | head -1)
RUNS="$ROOT/appdata/$PT/runs"
for f in seg_1.log rig.txt method_events.txt c2.txt summary.txt compile.log; do
	[ -f "$RUNS/$f" ] && cp "$RUNS/$f" "$OUT/"
done
find "$ROOT/$SHOTS" -maxdepth 1 \( -name 'test_*.png' -o -name 'c2_*.png' \) -newer "$OUT/launch_mark" -exec cp {} "$OUT/shots/" \; 2>/dev/null
exit "${rc:-3}"
