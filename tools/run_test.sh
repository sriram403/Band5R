#!/bin/sh
# Run the automated play-test without getting in the way of the desktop: the
# window opens off screen (right of a 1920 px monitor), muted, and never takes
# keyboard focus or the mouse. Screenshots still land in FindingNaresh/_shots.
#   tools/run_test.sh                  all scenarios
#   tools/run_test.sh map,drive        some scenarios
#   SHOW=1 tools/run_test.sh drive     on screen, with sound, to watch it
DIR="$(dirname "$0")"
ARG="--playtest"
[ -n "$1" ] && ARG="--playtest=$1"
if [ -n "$SHOW" ]; then
	exec "$DIR/run_game.sh" --resolution 1600x900 -- "$ARG" --show
fi
exec "$DIR/run_game.sh" --resolution 1600x900 --position 4000,0 -- "$ARG"
