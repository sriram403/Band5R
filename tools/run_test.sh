#!/bin/sh
# Run the automated play-test without getting in the way of the desktop: the
# window opens off screen, then moves behind all other windows without taking
# focus (muted, no mouse grab). Click it or its taskbar button to watch; click
# elsewhere and it goes back behind. Screenshots land in FindingNaresh/_shots.
#   tools/run_test.sh                  quick: base gym, then world smoke checks
#   tools/run_test.sh full             quick checks plus long journeys and every road
#   python tools/gen/layout_check.py  road check (no game window)
#   tools/run_test.sh map,drive        some scenarios
#   SHOW=1 tools/run_test.sh drive     on screen, with sound, to watch it
#   GYM=base tools/run_test.sh         in a gym (test map) instead of the world
#   ARGS="--extent=4000" tools/run_test.sh perf   extra game arguments
DIR="$(dirname "$0")"
ARG="--playtest"
[ -n "$1" ] && ARG="--playtest=$1"
if [ -z "$1" ]; then ARG="--playtest=quick"; fi
EXTRA=""
[ -n "$GYM" ] && EXTRA="--gym=$GYM"
EXTRA="$EXTRA $ARGS"
if [ -n "$SHOW" ]; then
	if [ -z "$GYM" ] && { [ -z "$1" ] || [ "$1" = quick ] || [ "$1" = full ]; }; then
		"$DIR/run_game.sh" --resolution 1600x900 -- --playtest=tyre --gym=tyre $ARGS --show || exit $?
		"$DIR/run_game.sh" --resolution 1600x900 -- --playtest=gym_quick --gym=base $ARGS --show || exit $?
	fi
	exec "$DIR/run_game.sh" --resolution 1600x900 -- "$ARG" $EXTRA --show
fi
# The window the user is in now; the game hands focus back to it once it starts.
FG=$(powershell.exe -NoProfile -NonInteractive -Command "Add-Type -Name F -Namespace U -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; [U.F]::GetForegroundWindow().ToInt64()" | tr -dc '0-9')
if [ -z "$GYM" ] && { [ -z "$1" ] || [ "$1" = quick ] || [ "$1" = full ]; }; then
	"$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- --playtest=tyre --gym=tyre $ARGS "--refocus=${FG:-0}" || exit $?
	"$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- --playtest=gym_quick --gym=base $ARGS "--refocus=${FG:-0}" || exit $?
fi
exec "$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- "$ARG" $EXTRA "--refocus=${FG:-0}"
