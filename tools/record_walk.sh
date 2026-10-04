#!/usr/bin/env bash
# Record a planned walk (a test sheet part) as a video for the user to watch
# (the user, 2026-10-04: "do F3 and capture a video, I'll review that").
#   tools/record_walk.sh f3        -> appdata/videos/f3.mp4 (and its walk log)
# Godot's Movie Maker writes every frame and the sound to an .avi (the game
# plays no sound through the speakers meanwhile); 25 fps keeps up with real
# time on this PC (30 fps ran at 88 %). ffmpeg then makes a small .mp4.
cd "$(dirname "$0")/.."
w=${1:?which walk, e.g. f3}
out="$(pwd -W)/appdata/videos"
mkdir -p "$out"
python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 2
export MPG_DATA="$(pwd -W)/appdata/playtest"
rm -f appdata/playtest/FindingNaresh/live/log_seen appdata/playtest/FindingNaresh/live/walk.log "$out/$w.avi"
nohup tools/run_game.sh --write-movie "$out/$w.avi" --fixed-fps 25 --resolution 1600x900 --position 4000,0 \
	-- --playtest=live --refocus=0 > appdata/live_run.log 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" appdata/live_run.log 2>/dev/null && break
	sleep 2
done
grep -q "\[live\] ready" appdata/live_run.log || { echo "the game didn't start"; exit 1; }
python tools/live.py --walk "tools/live/$w.json" >/dev/null 2>&1 &
# the game plays the walk on its own; follow its log
log=appdata/playtest/FindingNaresh/live/walk.log
for i in $(seq 1 1200); do
	grep -qE "^(DONE|FAILED)" "$log" 2>/dev/null && break
	sleep 3
done
sleep 4                          # a few seconds after the last step
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 5
cp "$log" "$out/$w.walk.log"
cat "$log"
ffmpeg -v error -y -i "$out/$w.avi" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
	-c:a aac -b:a 128k -movflags +faststart "$out/$w.mp4" && rm -f "$out/$w.avi"
ls -la "$out/$w.mp4"
