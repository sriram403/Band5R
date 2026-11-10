#!/usr/bin/env bash
# A trial play of a planned walk, no recording (the dry runs before a take).
#   tools/play_walk.sh ghat               resume from the step the last run failed at (DEFAULT)
#   tools/play_walk.sh ghat --fresh       from step 1
#   tools/play_walk.sh ghat --from "<step name>"
# A fresh game every time (a game-code fix needs one); the walk's save point
# puts the world back as that step found it (dev/LiveControl.gd), so a fix is
# never paid for by replaying the steps that already passed (the user,
# 2026-11-10: 10 trial plays were restarted from step 1, ~40 min lost).
# Prints the walk's lines as they come; exit 0 = DONE, 1 = FAILED.
# Watch it while it runs (CLAUDE.md): run it in the background and read
# appdata/playtest/FindingNaresh/live/walk.log every few seconds.
cd "$(dirname "$0")/.."
w=${1:?which walk, e.g. ghat}
shift
# NO_MAKE=1: play tools/live/<w>.json as it is (a hand-edited or planted variant)
[ -n "$NO_MAKE" ] || python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 2
export MPG_DATA="$(pwd -W)/appdata/playtest"
rm -f appdata/playtest/FindingNaresh/live/log_seen appdata/playtest/FindingNaresh/live/walk.log
nohup tools/run_game.sh --resolution 1600x900 --position 4000,0 \
	-- --playtest=live --refocus=0 > appdata/live_run.log 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" appdata/live_run.log 2>/dev/null && break
	grep -m3 "Parse Error\|SCRIPT ERROR" appdata/live_run.log 2>/dev/null && { echo "the game failed to start"; exit 1; }
	sleep 2
done
grep -q "\[live\] ready" appdata/live_run.log || { echo "the game didn't start"; exit 1; }
python tools/live.py --walk "tools/live/$w.json" "$@"
rc=$?
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
exit $rc
