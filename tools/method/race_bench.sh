#!/usr/bin/env bash
# The rename-race check (tools/method/race_bench.py): launch lane a's live game, hold res.json while it answers, stop it.
cd "$(dirname "$0")/../.."
python tools/method/godot_guard.py "" || exit 3
export MPG_DATA="$(pwd -W)/appdata/playtest"
live="appdata/playtest/FindingNaresh/live"
mkdir -p "$live"
rm -f "$live/log_seen" "$live/walk.log" "$live/instance.json" "$live/res.json" "$live/res.tmp" "$live/cmd.json" "$live/abort"
runlog="appdata/live_run.log"
nohup tools/run_game.sh --resolution 1600x900 --position 4000,0 -- --playtest=live --refocus=0 --lane= > "$runlog" 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" "$runlog" 2>/dev/null && break
	sleep 2
done
grep -q "\[live\] ready" "$runlog" || { echo "the game didn't start"; tools/method/stop_lane.sh; exit 1; }
python tools/method/race_bench.py
rc=$?
tools/method/stop_lane.sh
exit $rc
