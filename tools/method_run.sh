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
#        the other. One RESULT per part, then combine_parts.py's one combined RESULT (exit code):
#        PASS only when every requested part ran its exact scenarios and passed (fix round).
#   INV=<id> ...                             # this invocation's id (default: time + pid; must be new)
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
# ---- T1 fix round (GPT's blocker 1): every invocation has its own id (INV) and its own receipt
# folder appdata/method/inv/<INV>/: `expected` (each requested part: its scenarios and fixture),
# per part `<part>.dir` (its run folder), `<part>.rc` (the part's own exit), `<part>.xrc` (the exit
# seen from outside), `<part>.refused` (why it never launched). tools/method/combine_parts.py judges
# from those only: a requested part that is refused, missing, truncated, from another invocation or
# covering other scenarios is never a PASS. No shared .last_* pointers.
STATE="$ROOT/appdata/method"
mkdir -p "$STATE/runs" "$STATE/inv"
if [ -z "$PART" ]; then
	INV="${INV:-$(date +%Y%m%d_%H%M%S)_$$}"
	INVD="$STATE/inv/$INV"
	mkdir "$INVD" 2>/dev/null || { echo "invocation id '$INV' already used ($INVD): not launching"; exit 3; }
	export INV
	echo "invocation $INV -> $INVD"
fi
INVD="$STATE/inv/$INV"
# ---- T1: SPEED=fast splits a ghat plan into its fast part and its 1x part
# fix round (the hearing gap): ghat_jug and ghat_places drop items near the creature, and the game's
# hearing reads the wall clock (Hearing.gd, Creature.gd item bounce 1500 wall ms, Carryable.gd 150 ms
# knock debounce): fast changes what it hears. Both stay 1x.
# T3 v2 (2026-11-14): T1 qualification round 2's final table: ghat_looks' glass check stays 1x for an
# accepted PASS (a steady speed shift), so looks runs in the 1x part; FAST_OK_OVERRIDE for diagnostics only.
# F6 (fix round): ghat_marks runs in the 1x part with ghat_looks (its prelude, same process, after looks);
# the routing lives in tools/method/route.py (offline controls in t3_controls.py).
if [ "$SPEED" = "fast" ] && [ "$WHAT" = "ghat" ] && [ -z "$PART" ]; then
	ALL="${GHAT:-ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_spring,ghat_marks}"
	RT=$(python "$DIR/method/route.py" "$ALL" "$FIXTURE" | tr -d '\r') || { echo "SPEED=fast: routing failed"; exit 3; }
	FP=$(printf '%s\n' "$RT" | sed -n 's/^fast\t//p'); SP=$(printf '%s\n' "$RT" | sed -n 's/^1x\t//p')
	case ",$FIXTURE," in *,free_coolant,*)
		echo "SPEED=fast: FIXTURE has free_coolant (its plant reads the wall clock): all at 1x" ;; esac
	echo "SPEED=fast: fast + nodraw: ${FP:-none} | 1x: ${SP:-none}${SP:+ (game-code wall clocks: Camper cap window, hearing, free_coolant)}"
	[ -n "$FP" ] && printf '%s\t%s\t%s\n' fast "$FP" "$FIXTURE" >> "$INVD/expected"
	[ -n "$SP" ] && printf '%s\t%s\t%s\n' 1x "$SP" "$FIXTURE" >> "$INVD/expected"
	[ -z "$FP$SP" ] && { echo "SPEED=fast: nothing requested"; python -u "$DIR/method/combine_parts.py" "$(cd "$INVD" && pwd -W 2>/dev/null || echo "$INVD")"; exit $?; }
	runpart() {    # part scenarios lane: one part, its exit written from outside (.xrc)
		{ PART=$1 SPEED=_$1 GHAT="$2" LANE=$3 sh "$0" ghat $K0; echo $? > "$INVD/$1.xrc"; } 2>&1 | sed -u "s/^/[$1] /"
	}
	K0="$2"
	if [ -n "$FP" ] && [ -n "$SP" ] && [ "${PAR:-1}" = "1" ]; then
		runpart fast "$FP" "" &
		bg=$!
		sleep 20     # the second launch after the first has started (the guard counts it)
		runpart 1x "$SP" b
		wait $bg
	else
		[ -n "$FP" ] && runpart fast "$FP" ""
		[ -n "$SP" ] && runpart 1x "$SP" "${PAR_LANE:-}"
	fi
	python -u "$DIR/method/combine_parts.py" "$(cd "$INVD" && pwd -W 2>/dev/null || echo "$INVD")"
	exit $?
fi
case "$WHAT" in
	ramp) PLAN="ramp,c2_more" ;;
	c2_more) PLAN="c2_more" ;;
	# #6, the ghat (2026-11-09): every scenario, or GHAT=ghat_heat,ghat_net ... for some
	ghat) PLAN="${GHAT:-ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_spring,ghat_marks}"; [ -z "$2" ] && set -- "$1" k3 ;;
	*) echo "usage: method_run.sh ramp [k0..k4] | c2_more | ghat (GHAT=scenarios, FIXTURE=plants, SPEED=fast)"; exit 3 ;;
esac
if [ -z "$PART" ]; then
	PART=single
	printf '%s\t%s\t%s\n' single "$PLAN" "$FIXTURE" >> "$INVD/expected"
fi
# the part's own exit, on every path from here on (refusals included)
finish() { echo "$1" > "$INVD/$PART.rc"; exit "$1"; }
refuse() { echo "$1" > "$INVD/$PART.refused"; echo "$1"; [ -n "$2" ] && printf '%s\n' "$2"; finish 3; }
K="$2"
if [ -z "$K" ]; then
	n=$(cat "$STATE/next_k.txt" 2>/dev/null || echo 0)
	K="k$((n % 5))"
	echo $(( (n + 1) % 5 )) > "$STATE/next_k.txt"
fi
case "$K" in k0|k1|k2|k3|k4) ;; *) refuse "unknown profile $K (k0..k4)" ;; esac
if [ -n "$FN_RECORD" ]; then refuse "FN_RECORD: diagnostic recording is unsupported in this build (cut 1)"; fi
# ---- the guard (T1): this copy's lane free, at most 2 Godot on the PC
PT="playtest${LANE:+_$LANE}"
WROOT="$(cd "$ROOT" && pwd -W 2>/dev/null || pwd)"
MARK="$WROOT/appdata/$PT/runs"
GL=$(powershell.exe -NoProfile -NonInteractive -Command "Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | ForEach-Object { \"\$(\$_.ProcessId)\`t\$(\$_.CommandLine)\" }" 2>/dev/null | tr -d '\r')
# fix-round control only (off by default): GUARD_INJECT adds fake process lines ("pid<TAB>command
# line"), so the real guard below refuses (a lane busy, or 2 games on the PC) with no game running
[ -n "$GUARD_INJECT" ] && GL="$GL
$(printf '%b' "$GUARD_INJECT")"
# a game is 2 processes (the _console.exe wrapper and the game it starts): count games, not processes
all_n=$(printf '%s\n' "$GL" | grep -vi '_console\.exe' | grep -c '[0-9]')
mine=$(printf '%s\n' "$GL" | tr '\\' '/' | grep -ci "$(echo "$MARK" | tr '\\' '/')")
if [ "$mine" -gt 0 ]; then
	refuse "a Godot of this copy is running in lane '${LANE:-a}': not launching" "$GL"
fi
if [ "$all_n" -ge 2 ]; then
	refuse "2 Godot processes already run on this PC: not launching (at most 2)" "$GL"
fi
[ "$all_n" -ge 1 ] && echo "note: another game runs on this PC (speed numbers of this run are shared-PC numbers): $(printf '%s' "$GL" | cut -c1-160)"
ID="$(date +%Y%m%d_%H%M%S)_${WHAT}_${K}${FIXTURE:+_$FIXTURE}${SPEED:+$SPEED}${LANE:+_lane$LANE}"
OUT="$STATE/runs/$ID"
mkdir -p "$OUT/shots"
touch "$OUT/launch_mark"
(cd "$OUT" && pwd -W 2>/dev/null || pwd) > "$INVD/$PART.dir"
{ echo "inv $INV part $PART"; echo "run $ID plan $PLAN profile $K fixture '${FIXTURE}' speed '${SPEED:-1x}' lane '${LANE:-a}' at $(date '+%F %T')"; echo "head $(git -C "$ROOT" rev-parse HEAD)"; git -C "$ROOT" status --porcelain; } > "$OUT/run_info.txt"
# ---- T3 v2 run metadata (2026-11-14): role (ROLE=discovery|repair|final|proof|diag, default diag), the
# input tree identity before and after (tools/method/tree_id.py: game + test + tools + bin, dirty bytes
# included), the namespace, start / end and the verified exit. tools/method/t3_gate.py reads run_meta.json.
python "$DIR/method/tree_id.py" stamp "$OUT/tree_pre.json" > /dev/null
T_START=$(date '+%F %T')
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
export LANE INV PART FIXTURE
rm -f "$ROOT/$SHOTS/captures.jsonl"     # F7: this run's capture log starts empty (PlayTest.shot() appends)
python -u "$DIR/method/method_watch.py" "$WROOT" "$PLAN" "$(cd "$OUT" && pwd -W 2>/dev/null || pwd)" "$GARGS" 2>&1 | tee "$OUT/console.txt"
rc=$(sed -n 's/^RESULT: [A-Z ]* (exit \([0-9]\)).*/\1/p' "$OUT/verdict.txt" 2>/dev/null | head -1)
RUNS="$ROOT/appdata/$PT/runs"
for f in seg_1.log rig.txt method_events.txt c2.txt summary.txt compile.log; do
	[ -f "$RUNS/$f" ] && cp "$RUNS/$f" "$OUT/"
done
find "$ROOT/$SHOTS" -maxdepth 1 \( -name 'test_*.png' -o -name 'c2_*.png' \) -newer "$OUT/launch_mark" -exec cp -p {} "$OUT/shots/" \; 2>/dev/null
# F7: the game's capture log + the run's capture inventory (t3_gate.py final reads it)
[ -f "$ROOT/$SHOTS/captures.jsonl" ] && cp -p "$ROOT/$SHOTS/captures.jsonl" "$OUT/captures.jsonl"
python "$DIR/method/captures.py" inventory "$OUT"
python "$DIR/method/tree_id.py" stamp "$OUT/tree_post.json" > /dev/null
left=$(LANE= python "$DIR/method/godot_guard.py" --pids "$LANE" | tr '\n' ' ')
python - "$OUT/run_meta.json" <<EOF
import json, sys
json.dump({"inv": "$INV", "part": "$PART", "run": "$ID", "plan": "$PLAN", "profile": "$K", "fixture": "$FIXTURE",
           "speed": "${SPEED:-1x}", "lane": "${LANE:-a}", "role": "${ROLE:-diag}", "namespace": {"data": "appdata/$PT",
           "shots": "$SHOTS", "runs": "appdata/method/runs/$ID", "receipt": "appdata/method/inv/$INV"},
           "start": "$T_START", "end": "$(date '+%F %T')", "rc": "${rc:-3}", "godot_left_in_lane": "$left".strip(),
           "from_point": "$FROM_POINT", "ghat_env": "$GHAT", "early_stop_ids": "$EXPECT_IDS"},
          open(sys.argv[1], "w", encoding="utf-8"), indent=1)
EOF
finish "${rc:-3}"
