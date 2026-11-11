#!/usr/bin/env bash
# Record a planned walk (a test sheet part) as a video for the user to watch
# (the user, 2026-10-04: "do F3 and capture a video, I'll review that").
#   tools/record_walk.sh ghat            -> appdata/videos/ghat.mp4 (and its walk log, joins.txt)
#   tools/record_walk.sh ghat --fresh    a whole new take from step 1 (old parts go)
# RESUMES BY DEFAULT (the user, 2026-11-10) after a failed part of this take: the next part starts
# from the failed step's save point (the point ID kept in <w>.parts/resume_point).
# T4 v2 (speed research, 2026-11-11):
#  - the profile is fixed: Movie Maker 25 fps, 1600x900, normal drawing, sound (WALK_PROFILE=rec25);
#    the walk's deadlines run on the game clock while recording (PlayTest.el_ms);
#  - a resume goes through the gate (tools/live.py, tools/method/walkgate.py): refused before any input
#    when the point's identity changed or a boundary rule says so; layer 2 right after the restore,
#    layer 3 at +3 game s. A refused point means: record a fresh take (--fresh);
#  - parts are kept WHOLE (no cut here); tools/method/join_check.py verifies the take (same game /
#    test / binary / profile, the producer chain, every join's gate SAME with 2 resumes (D3 A), the
#    drawn-frame -> movie-frame mapping proved by a marker), then cuts frame-exact and joins, and lists
#    every join as MM:SS.mmm -> step, part, gate. A join it refuses leaves no joined video.
#  - GATE_ONLY=1: a second recorded resume of the same point (the D3 A second receipt): plays only the
#    resumed step, keeps no part; its receipt lands in the point's gate list.
# LANE=b: a second game of this copy (appdata/playtest_b, appdata/videos_b, _shots_b).
# Godot's Movie Maker writes every frame and the sound to an .avi (the game plays no sound through
# the speakers meanwhile); ffmpeg then makes a small .mp4 (every frame kept: frame n at n/25 s).
cd "$(dirname "$0")/.."
w=${1:?which walk, e.g. ghat}
shift
FPS=25
sfx=${LANE:+_$LANE}
export LANE WALK_PROFILE=rec25
out="$(pwd -W)/appdata/videos$sfx"
parts="$out/$w.parts"
mkdir -p "$out" "$parts"
# NO_MAKE=1: record tools/live/<w>.json as it is (a hand-edited or planted variant)
[ -n "$NO_MAKE" ] || python "tools/live/make_$w.py" >/dev/null || exit 1
python tools/method/godot_guard.py "$LANE" || exit 3
export MPG_DATA="$(pwd -W)/appdata/playtest$sfx"
live="appdata/playtest$sfx/FindingNaresh/live"
mkdir -p "$live"
runlog="appdata/live_run$sfx.log"
walkjson="tools/live/$w.json"
args=("$@")
case " $* " in
	*" --fresh "*) rm -rf "$parts"/* ;;
	*" --from "*) ;;                                    # explicit: FROM_POINT=<run>/<i> names the point
	*) if [ -f "$parts/resume_point" ] && [ -z "$GATE_ONLY" ]; then
		export FROM_POINT=$(cat "$parts/resume_point"); args+=(--from "$(cat "$parts/resume_step")")
	   elif [ -n "$GATE_ONLY" ]; then
		[ -f "$parts/gate_point" ] || { echo "GATE_ONLY: no resumed part to repeat ($parts/gate_point)"; exit 5; }
		export FROM_POINT=$(cat "$parts/gate_point"); args+=(--from "$(cat "$parts/gate_step")")
	   else
		rm -rf "$parts"/*; args+=(--fresh)
	   fi ;;
esac
if [ -n "$GATE_ONLY" ]; then
	# the walk up to and including the resumed step only (its end, then stop)
	python - "$walkjson" "$(cat "$parts/gate_step")" "$live/gateonly_$w.json" <<'EOF'
import json, sys
w = json.load(open(sys.argv[1], encoding="utf-8"))
names = [s["name"] for s in w["steps"]]
w["steps"] = w["steps"][:names.index(sys.argv[2]) + 1]
json.dump(w, open(sys.argv[3], "w", encoding="utf-8"), indent=1)
EOF
	walkjson="$live/gateonly_$w.json"
fi
# T4 v2: the gate's identity / refusal check BEFORE a game is started (a refused point costs no launch)
python tools/live.py --gate-check --walk "$walkjson" "${args[@]}" || { echo "TAKE PART REFUSED before launch: record a fresh take: tools/record_walk.sh $w --fresh"; exit 5; }
n=$(ls "$parts"/part*.json 2>/dev/null | wc -l)
k=$((n + 1))
tag="part$k"; [ -n "$GATE_ONLY" ] && tag="gate$(date +%H%M%S)"
rm -f "$live/log_seen" "$live/walk.log" "$live/instance.json" "$live/res.json" "$live/cmd.json" "$live/abort" "$parts/$tag.avi"
t0=$(date +%s)
nohup tools/run_game.sh --write-movie "$parts/$tag.avi" --fixed-fps $FPS --resolution 1600x900 --position 4000,0 \
	-- --playtest=live --refocus=0 --lane=$LANE --shots-dir=res://_shots$sfx > "$runlog" 2>&1 &
for i in $(seq 1 90); do
	grep -q "\[live\] ready" "$runlog" 2>/dev/null && break
	grep -m3 "Parse Error\|SCRIPT ERROR" "$runlog" 2>/dev/null && break
	sleep 2
done
grep -q "\[live\] ready" "$runlog" || { echo "the game didn't start"; tools/method/stop_lane.sh "$LANE"; exit 1; }
python tools/live.py --walk "$walkjson" "${args[@]}" > "$parts/$tag.client.log" 2>&1 &
cpid=$!
# the game plays the walk on its own; follow the client (it prints the walk's lines and the gate's)
shown=0
while kill -0 $cpid 2>/dev/null; do
	sleep 3
	nl=$(wc -l < "$parts/$tag.client.log")
	[ "$nl" -gt "$shown" ] && { sed -n "$((shown + 1)),${nl}p" "$parts/$tag.client.log"; shown=$nl; }
done
wait $cpid
crc=$?
sed -n "$((shown + 1)),\$p" "$parts/$tag.client.log"
sleep 2                          # a moment after the last step
tools/method/stop_lane.sh "$LANE"
echo "game lifetime ~$(( $(date +%s) - t0 )) s; $(grep -o 'recorded in [^)]*)' "$runlog" | tail -1)"
run=$(sed -n 's/^RUN \([^ ]*\) .*/\1/p' "$parts/$tag.client.log" | head -1)
if [ "$crc" -eq 5 ] || [ "$crc" -eq 6 ] || [ -z "$run" ]; then
	rm -f "$parts/$tag.avi"
	echo "TAKE PART REFUSED (client exit $crc): no part kept. A refused point means a fresh take: tools/record_walk.sh $w --fresh"
	exit 5
fi
rdir="$live/points/$run"
if [ -n "$GATE_ONLY" ]; then
	rm -f "$parts/$tag.avi"
	echo "$rdir" >> "$parts/gate_runs"
	echo "GATE_ONLY: receipt $(ls "$rdir"/*.gate.json 2>/dev/null) (kept in $parts/gate_runs)"
	exit 0
fi
ffmpeg -v error -y -i "$parts/$tag.avi" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -r $FPS \
	-c:a aac -b:a 128k -ar 48000 -movflags +faststart "$parts/$tag.mp4" || { echo "encode failed"; exit 1; }
# the drawn-frame -> movie-frame proof, from the marker (if this walk has one), on the raw avi
mk=$(grep -oE "^marker at frame [0-9]+" "$rdir/walk.log" | grep -oE "[0-9]+$" | head -1)
[ -n "$mk" ] && python tools/method/join_check.py framemap "$parts/$tag.avi" "$mk" $FPS "$out/framemap_rec25.json"
rm -f "$parts/$tag.avi"
python tools/method/join_check.py part "$parts" $k "$rdir" "$parts/$tag.mp4" "$(grep -o 'recorded in [^)]*)' "$runlog" | tail -1)"
if grep -q "^DONE" "$rdir/walk.log"; then
	rm -f "$parts/resume_point" "$parts/resume_step"
	python tools/method/join_check.py join "$parts" "$out/$w.mp4" "$out/framemap_rec25.json"
	exit $?
fi
lf="$live/points/${w}_last_fail.json"
python -c "import json;d=json.load(open('$lf'));print(d['point']);open('$parts/resume_step','w').write(d['step']);open('$parts/gate_step','w').write(d['step'])" > "$parts/resume_point"
cp "$parts/resume_point" "$parts/gate_point"
echo "TAKE FAILED at '$(cat "$parts/resume_step")' (point $(cat "$parts/resume_point")): fix it, then run tools/record_walk.sh $w again: it resumes there through the gate (a game fix changes the game hash: the gate then refuses and a fresh take is needed)"
exit 1
