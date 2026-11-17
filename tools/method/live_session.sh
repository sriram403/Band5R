#!/usr/bin/env bash
# One live game in a lane, for a sequence of walks / commands in the same process (T4 / T3 controls).
#   tools/method/live_session.sh start [lane] [rec <movie.avi>]   start, wait for "[live] ready"
#   tools/method/live_session.sh stop [lane]                      quit + verified exit (stop_lane.sh)
#   tools/method/live_session.sh import                           the compile / import check (headless)
# Then: LANE=<lane> python tools/live.py ... (each command's answer is checked for the lane).
cd "$(dirname "$0")/../.."
what=$1; lane=$2
sfx=${lane:+_$lane}
case "$what" in
import)
	tools/run_game.sh --headless --import > appdata/import_check.log 2>&1
	rc=$?
	grep -m5 "Parse Error\|SCRIPT ERROR\|ERROR" appdata/import_check.log
	echo "import rc $rc"; exit $rc ;;
start)
	python tools/method/godot_guard.py "$lane" || exit 3
	export MPG_DATA="$(pwd -W)/appdata/playtest$sfx"
	live="appdata/playtest$sfx/FindingNaresh/live"
	mkdir -p "$live"
	rm -f "$live/log_seen" "$live/walk.log" "$live/instance.json" "$live/res.json" "$live/cmd.json" "$live/abort"
	runlog="appdata/live_run$sfx.log"
	movie=()
	[ "$3" = "rec" ] && movie=(--write-movie "$4" --fixed-fps 25)
	nohup tools/run_game.sh "${movie[@]}" --resolution 1600x900 --position 4000,0 \
		-- --playtest=live --refocus=0 --lane=$lane --shots-dir=res://_shots$sfx > "$runlog" 2>&1 &
	for i in $(seq 1 90); do
		grep -q "\[live\] ready" "$runlog" 2>/dev/null && break
		grep -m3 "Parse Error\|SCRIPT ERROR" "$runlog" 2>/dev/null && break
		sleep 1
	done
	grep -q "\[live\] ready" "$runlog" || { echo "the game didn't start"; tools/method/stop_lane.sh "$lane"; exit 1; }
	echo "ready: lane '${lane:-a}' $(cat "$live/instance.json")" ;;
stop)
	tools/method/stop_lane.sh "$lane" ;;
*) echo "usage: live_session.sh start|stop [lane] | import"; exit 2 ;;
esac
