#!/usr/bin/env bash
# record_walk.sh without the movie writer: a watched dry run of a walk
cd /d/mine/Agentics/T3_Code_Works/MPG_dev
w=${1:?walk}
python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 2
export MPG_DATA="$(pwd -W)/appdata/playtest"
rm -f appdata/playtest/FindingNaresh/live/log_seen appdata/playtest/FindingNaresh/live/walk.log
nohup tools/run_game.sh --resolution 1600x900 --position 4000,0 -- --playtest=live --refocus=0 > appdata/live_dry.log 2>&1 &
for i in $(seq 1 90); do grep -q "\[live\] ready" appdata/live_dry.log 2>/dev/null && break; sleep 2; done
grep -q "\[live\] ready" appdata/live_dry.log || { echo "the game didn't start"; exit 1; }
python tools/live.py --walk "tools/live/$w.json" >/dev/null 2>&1 &
log=appdata/playtest/FindingNaresh/live/walk.log
for i in $(seq 1 1200); do grep -qE "^(DONE|FAILED)" "$log" 2>/dev/null && break; sleep 3; done
cat "$log"
