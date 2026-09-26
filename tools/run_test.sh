#!/bin/sh
# Run the automated play-test without getting in the way of the desktop: the
# window opens off screen, then moves behind all other windows without taking
# focus (muted, no mouse grab). Click it or its taskbar button to watch; click
# elsewhere and it goes back behind. Screenshots land in FindingNaresh/_shots.
#   tools/run_test.sh                  smoke, ~3 min: base gym controls + one short world check per system
#   tools/run_test.sh ghat,ghat_menu   just these scenarios (after a fix: the ones for the change)
#   tools/run_test.sh set:puzzles      one area: set:opening / gyms / puzzles / creatures / driving / world
#   tools/run_test.sh full             everything (before a push or a hand-over)
#   python tools/gen/layout_check.py  road check (no game window)
#   SHOW=1 tools/run_test.sh drive     on screen, with sound, to watch it
#   GYM=base tools/run_test.sh         in a gym (test map) instead of the world
#   ARGS="--extent=4000" tools/run_test.sh perf   extra game arguments
# The plans are in tools/test_plan.sh (shared with the headless runner).
DIR="$(dirname "$0")"
. "$DIR/test_plan.sh"
# Save/load scenarios must never overwrite a player's own slots. Godot still
# writes only inside MPG/appdata, in a separate play-test profile.
export MPG_DATA="$(cd "$DIR/.." && pwd -W 2>/dev/null || pwd)/appdata/playtest"
FG=""
if [ -z "$SHOW" ]; then
	# The window the user is in now; the game hands focus back to it once it starts.
	FG=$(powershell.exe -NoProfile -NonInteractive -Command "Add-Type -Name F -Namespace U -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; [U.F]::GetForegroundWindow().ToInt64()" | tr -dc '0-9')
fi
NL='
'
OLD_IFS=$IFS
IFS=$NL
for line in $(test_plan "$1"); do
	IFS=$OLD_IFS
	gym=${line%%|*}
	scen=${line#*|}
	g=""
	[ -n "$gym" ] && g="--gym=$gym"
	if [ -n "$SHOW" ]; then
		"$DIR/run_game.sh" --resolution 1600x900 -- "--playtest=$scen" $g $ARGS --show || exit $?
	else
		"$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- "--playtest=$scen" $g $ARGS "--refocus=${FG:-0}" || exit $?
	fi
	IFS=$NL
done
IFS=$OLD_IFS
