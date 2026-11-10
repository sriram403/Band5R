#!/usr/bin/env bash
# Record a planned walk (a test sheet part) as a video for the user to watch
# (the user, 2026-10-04: "do F3 and capture a video, I'll review that").
#   tools/record_walk.sh f3            -> appdata/videos/f3.mp4 (and its walk log)
#   tools/record_walk.sh f3 --fresh    a whole new take from step 1
#   tools/record_walk.sh f3 --from "<step name>"
# RESUMES BY DEFAULT (the user, 2026-11-10): after a failed take, the next
# run starts from the failed step's save point; each run is kept as a part
# (appdata/videos/<w>.parts/), cut at the step lines' frames, and once a run
# ends DONE the parts are joined into <w>.mp4 (the log says where the joins
# are: tell the user). A take that ran clean from step 1 is one part.
# Godot's Movie Maker writes every frame and the sound to an .avi (the game
# plays no sound through the speakers meanwhile); 25 fps keeps up with real
# time on this PC (30 fps ran at 88 %). ffmpeg then makes a small .mp4.
cd "$(dirname "$0")/.."
w=${1:?which walk, e.g. f3}
shift
FPS=25
out="$(pwd -W)/appdata/videos"
parts="$out/$w.parts"
mkdir -p "$out" "$parts"
# NO_MAKE=1: record tools/live/<w>.json as it is (a hand-edited or planted variant)
[ -n "$NO_MAKE" ] || python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 2
export MPG_DATA="$(pwd -W)/appdata/playtest"
live=appdata/playtest/FindingNaresh/live
# Resume only a failed TAKE: its parts are here and the walk's last failure is
# that take's (a trial play, tools/play_walk.sh, may have failed elsewhere since).
# Anything else is a fresh take: the old parts go.
lastfail="$live/points/${w}_last_fail.json"
args=("$@")
laststep=$( [ -f "$lastfail" ] && python -c "import json;print(json.load(open('$lastfail'))['step'])" )
case " $* " in
	*" --fresh "*|*" --from "*) rm -f "$parts"/* ;;
	*) if [ -z "$laststep" ] || [ ! -f "$parts/resume_step" ] || [ "$(cat "$parts/resume_step")" != "$laststep" ]; then
		rm -f "$parts"/*; args+=(--fresh)
	   fi ;;
esac
n=$(ls "$parts"/part*.mp4 2>/dev/null | wc -l)
k=$((n + 1))
rm -f $live/log_seen $live/walk.log "$parts/part$k.avi"
nohup tools/run_game.sh --write-movie "$parts/part$k.avi" --fixed-fps $FPS --resolution 1600x900 --position 4000,0 \
	-- --playtest=live --refocus=0 > appdata/live_run.log 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" appdata/live_run.log 2>/dev/null && break
	sleep 2
done
grep -q "\[live\] ready" appdata/live_run.log || { echo "the game didn't start"; exit 1; }
python tools/live.py --walk "tools/live/$w.json" "${args[@]}" > "$parts/part$k.client.log" 2>&1 &
# the game plays the walk on its own; follow its log
log=$live/walk.log
for i in $(seq 1 1200); do
	grep -qE "^(DONE|FAILED|FAIL )" "$log" 2>/dev/null && break
	sleep 3
done
sleep 4                          # a few seconds after the last step
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 5
cp "$log" "$parts/part$k.walk.log"
cat "$parts/part$k.client.log" | grep "^RESUME" ; cat "$log"
# this part's cut: from the first step it played (a resume: skip the load),
# to the start of the step it failed at (that step is played again next part)
first=$(grep -m1 -oE "^step .*frame [0-9]+\)" "$log" | grep -oE "frame [0-9]+" | grep -oE "[0-9]+")
resumed=$(grep -c "^resumed at" "$log")
ss=0
[ "$resumed" -gt 0 ] && [ -n "$first" ] && ss=$(python -c "print(max(0, $first / $FPS - 0.2))")
to=""
if grep -q "^FAILED" "$log"; then
	fstep=$(python -c "import json;print(json.load(open('$lastfail'))['step'])")
	fr=$(grep -F "step $fstep (" "$log" | tail -1 | grep -oE "frame [0-9]+" | grep -oE "[0-9]+")
	[ -n "$fr" ] && to="-to $(python -c "print($fr / $FPS)")"
fi
ffmpeg -v error -y -ss "$ss" $to -i "$parts/part$k.avi" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
	-c:a aac -b:a 128k -ar 48000 -movflags +faststart "$parts/part$k.mp4" && rm -f "$parts/part$k.avi"
echo "part $k: from ${ss}s ${to:-to the end}"
if grep -q "^DONE" "$log"; then
	if [ "$k" -eq 1 ]; then
		cp "$parts/part1.mp4" "$out/$w.mp4"
	else
		( for i in $(seq 1 $k); do echo "file 'part$i.mp4'"; done ) > "$parts/list.txt"
		( cd "$parts" && ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy -movflags +faststart "$out/$w.mp4" )
		echo "JOINED $k parts: the joins are at the start of each resumed step (tell the user)"
		for i in $(seq 1 $k); do ffprobe -v error -show_entries format=duration -of csv=p=0 "$parts/part$i.mp4" | sed "s/^/  part $i length s: /"; done
	fi
	cat "$parts"/part*.walk.log > "$out/$w.walk.log"
	ls -la "$out/$w.mp4"
else
	[ -n "$fstep" ] && echo "$fstep" > "$parts/resume_step"
	echo "TAKE FAILED: fix it, then run tools/record_walk.sh $w again: it resumes at the failed step and joins the parts"
	exit 1
fi
