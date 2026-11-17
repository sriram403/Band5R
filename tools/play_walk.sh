#!/usr/bin/env bash
# A trial play of a planned walk, no recording (the dry runs before a take).
#   tools/play_walk.sh ghat               resume from the step the last run failed at (DEFAULT)
#   tools/play_walk.sh ghat --fresh       from step 1
#   tools/play_walk.sh ghat --from "<step name>"   (FROM_POINT=<run>/<i> names the point)
# A fresh game every time (a game-code fix needs one). T4 v2 (speed research, 2026-11-11): a resume
# goes through the gate (tools/live.py + tools/method/walkgate.py): the point is refused BEFORE any
# input if its identity changed or a boundary rule says so (then play --fresh: the real prefix);
# after the restore the game waits for the layer 1+2 verdict; layer 3 (+3 game s) DIFFERENT stops it.
# LANE=b: a second game of this copy (appdata/playtest_b, _shots_b, appdata/live_run_b.log).
# Prints the walk's lines as they come; exit 0 = DONE, 1 = FAILED, 3 = guard refused, 5 = gate refused.
# Watch it while it runs (CLAUDE.md): read appdata/playtest[_<lane>]/FindingNaresh/live/walk.log.
cd "$(dirname "$0")/.."
w=${1:?which walk, e.g. ghat}
shift
sfx=${LANE:+_$LANE}
export LANE WALK_PROFILE=${WALK_PROFILE:-play}
# NO_MAKE=1: play tools/live/<w>.json as it is (a hand-edited or planted variant)
[ -n "$NO_MAKE" ] || python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/method/godot_guard.py "$LANE" || exit 3
# T4 v2: the gate's identity / refusal check BEFORE a game is started (a refused point costs no launch)
python tools/live.py --gate-check --walk "tools/live/$w.json" "$@" || exit 5
export MPG_DATA="$(pwd -W)/appdata/playtest$sfx"
live="appdata/playtest$sfx/FindingNaresh/live"
mkdir -p "$live"
rm -f "$live/log_seen" "$live/walk.log" "$live/instance.json" "$live/res.json" "$live/cmd.json" "$live/abort"
runlog="appdata/live_run$sfx.log"
nohup tools/run_game.sh --resolution 1600x900 --position 4000,0 \
	-- --playtest=live --refocus=0 --lane=$LANE --shots-dir=res://_shots$sfx > "$runlog" 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" "$runlog" 2>/dev/null && break
	grep -m3 "Parse Error\|SCRIPT ERROR" "$runlog" 2>/dev/null && { echo "the game failed to start"; break; }
	sleep 2
done
grep -q "\[live\] ready" "$runlog" || { echo "the game didn't start"; tools/method/stop_lane.sh "$LANE"; exit 1; }
python tools/live.py --walk "tools/live/$w.json" "$@"
rc=$?
tools/method/stop_lane.sh "$LANE"
exit $rc
