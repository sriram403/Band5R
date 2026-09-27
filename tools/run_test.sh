#!/bin/sh
# Run the automated play-test without getting in the way of the desktop: the
# window opens off screen, then moves behind all other windows without taking
# focus (muted, no mouse grab). Click it or its taskbar button to watch; click
# elsewhere and it goes back behind. Screenshots land in FindingNaresh/_shots.
#   tools/run_test.sh                  smoke, ~3 min: base gym controls + one short world check per system
#   tools/run_test.sh ghat,ghat_menu   just these scenarios (after a fix: the ones for the change)
#   tools/run_test.sh set:puzzles      one area: set:opening / gyms / puzzles / creatures / driving / world
#   tools/run_test.sh full             everything (before a push or a hand-over)
#   tools/run_test.sh resume           carry on with the last run that broke off (a crash,
#                                      a timeout, a closed window, a PC restart): the scenarios
#                                      it finished are skipped, their results kept
#   python tools/gen/layout_check.py  road check (no game window)
#   SHOW=1 tools/run_test.sh drive     on screen, with sound, to watch it
#   GYM=base tools/run_test.sh         in a gym (test map) instead of the world
#   ARGS="--extent=4000" tools/run_test.sh perf   extra game arguments
#   TIMEOUT=5400 tools/run_test.sh full           seconds before one game process is
#                                                 killed as hung (default 3600)
# The plans are in tools/test_plan.sh (shared with the headless runner).
# Every run ends with one summary of all its segments; the exit code is 0 only
# when everything passed. Logs: appdata/playtest/runs/<segment>.log.
DIR="$(dirname "$0")"
. "$DIR/test_plan.sh"
# Save/load scenarios must never overwrite a player's own slots. Godot still
# writes only inside MPG/appdata, in a separate play-test profile.
export MPG_DATA="$(cd "$DIR/.." && pwd -W 2>/dev/null || pwd)/appdata/playtest"
RUNS="$MPG_DATA/runs"
PROGRESS="$RUNS/progress.txt"
mkdir -p "$RUNS"
# The run's identity: the plan and $GYM. `resume` reuses the last one's.
if [ "$1" = "resume" ]; then
	if [ ! -f "$RUNS/plan.txt" ] || [ -f "$RUNS/finished.txt" ]; then
		echo "Nothing to resume: the last run finished (or there was none)."
		[ -f "$RUNS/summary.txt" ] && cat "$RUNS/summary.txt"
		exit 0
	fi
	PLAN=$(sed -n 1p "$RUNS/plan.txt")
	GYM=$(sed -n 2p "$RUNS/plan.txt")
	export GYM
	echo "Resuming '${PLAN:-smoke}'${GYM:+ in gym $GYM} (finished scenarios are skipped)"
else
	PLAN="$1"
	rm -f "$PROGRESS" "$RUNS/finished.txt" "$RUNS/summary.txt" "$RUNS"/seg_*.log
	printf '%s\n%s\n' "$PLAN" "$GYM" > "$RUNS/plan.txt"
fi
FG=""
if [ -z "$SHOW" ]; then
	# The window the user is in now; the game hands focus back to it once it starts.
	FG=$(powershell.exe -NoProfile -NonInteractive -Command "Add-Type -Name F -Namespace U -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; [U.F]::GetForegroundWindow().ToInt64()" | tr -dc '0-9')
fi
NL='
'
OLD_IFS=$IFS
IFS=$NL
n=0
problems=""
for line in $(test_plan "$PLAN"); do
	IFS=$OLD_IFS
	n=$((n + 1))
	gym=${line%%|*}
	scen=${line#*|}
	seg_log="$RUNS/seg_$n.log"
	if grep -qxF "segment	$line" "$PROGRESS" 2>/dev/null; then
		echo "==== segment $n ($line): finished in the earlier run, skipped ===="
		IFS=$NL
		continue
	fi
	echo "==== segment $n: ${gym:-world} | $scen ===="
	g=""
	[ -n "$gym" ] && g="--gym=$gym"
	echo "==== launch $(date)" >> "$seg_log"
	# stdout also into the segment's log (Godot's own log is replaced each launch);
	# a resumed segment adds to what it logged before
	if [ -n "$SHOW" ]; then
		timeout "${TIMEOUT:-3600}" "$DIR/run_game.sh" --resolution 1600x900 -- "--playtest=$scen" $g $ARGS "--progress=$PROGRESS" --show 2>&1 | tee -a "$seg_log"
	else
		timeout "${TIMEOUT:-3600}" "$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- "--playtest=$scen" $g $ARGS "--refocus=${FG:-0}" "--progress=$PROGRESS" 2>&1 | tee -a "$seg_log"
	fi
	# Finished only if it got to its summary line; otherwise it crashed or hung
	# (killed by the timeout): stop, so `resume` carries on from its last scenario.
	if ! awk '/^==== launch/ { f = 0 } /==== [0-9]+ failure\(s\) ====/ { f = 1 } END { exit !f }' "$seg_log"; then
		echo "Segment $n ($line) broke off before its end (crash or timeout)."
		echo "Run 'tools/run_test.sh resume' to carry on from the scenario it was in."
		exit 3
	fi
	# a script error aborts a scenario without a FAIL line: report it
	if grep -q "SCRIPT ERROR" "$seg_log"; then
		problems="$problems${NL}  segment $n ($line): script errors, see $seg_log"
	fi
	printf 'segment\t%s\n' "$line" >> "$PROGRESS"
	IFS=$NL
done
IFS=$OLD_IFS
# One summary for the whole run, from the progress file (earlier, broken-off
# runs of it included).
fails=$(grep -c "^fail	" "$PROGRESS" 2>/dev/null)
fails=${fails:-0}
done_n=$(grep -c "^done	" "$PROGRESS" 2>/dev/null)
{
	echo "==== RUN '${PLAN:-smoke}'${GYM:+ (gym $GYM)}: $n segment(s), ${done_n:-0} scenario(s), $fails failure(s) ===="
	grep "^fail	" "$PROGRESS" 2>/dev/null | awk -F'\t' '{ split($2, k, "|"); printf "  - [%s] %s: %s\n", (k[1] == "" ? "world" : k[1]), $3, $4 }'
	[ -n "$problems" ] && echo "Problems:$problems"
} | tee "$RUNS/summary.txt"
date > "$RUNS/finished.txt"
[ "$fails" = "0" ] && [ -z "$problems" ]
