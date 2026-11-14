#!/usr/bin/env bash
# T3 v2 lane sentinel + T4 v2 recording contention (qualification only; 2 games: lane b plain, lane a recording).
#   tools/method/lane_sentinel.sh [walk]     (default gateprobe) -> appdata/t34/sentinel.log
# 1 lane b: a live game (play), playing the walk (a real second workload) and then idling
# 2 lane a: tools/record_walk.sh <walk> --fresh (rec25) beside it: its "recorded in ... (speed)" vs the alone take
# 3 while both run: a command for lane b sent into lane a's folder and one for lane a into lane b's are
#   REFUSED (instance.json: lane / pid); the corrected commands are answered by their own lane's pid
# 4 lane a's take ends with its own targeted stop (stop_lane.sh a): lane b's game still alive and its
#   heartbeat (physics frames) still advancing; then lane b stopped, both verified gone
# Prints SENTINEL PASS only when every check holds.
cd "$(dirname "$0")/../.."
w=${1:-gateprobe}
L=appdata/t34/sentinel.log
: > "$L"
say() { echo "== $(date +%H:%M:%S) $*" | tee -a "$L"; }
fail=0
check() { if [ "$1" = "$(printf %s "$2" | tr -d '\r')" ]; then say "ok   $3 ($1)"; else say "BAD  $3 (want $1, got $2)"; fail=1; fi; }
LA="appdata/playtest/FindingNaresh/live"
LB="appdata/playtest_b/FindingNaresh/live"
say "1 start lane b"
tools/method/live_session.sh start b >> "$L" 2>&1 || { say "OFF PLAN: lane b did not start"; exit 1; }
pidb=$(python -c "import json;print(json.load(open('$LB/instance.json'))['pid'])")
LANE=b python tools/live.py --walk "tools/live/$w.json" --fresh --timeout 120 > appdata/t34/sentinel_b_walk.log 2>&1 &
wb=$!
say "2 lane a records $w (rec25) beside lane b (pid $pidb)"
rm -f appdata/live_run.log "$LA/instance.json"       # no stale "ready" from an earlier lane a game
tools/record_walk.sh "$w" --fresh > appdata/t34/sentinel_a_rec.log 2>&1 &
ra=$!
for i in $(seq 1 90); do [ -f "$LA/instance.json" ] && grep -q "\[live\] ready" appdata/live_run.log 2>/dev/null && break; sleep 1; done
sleep 2
pida=$(python -c "import json;print(json.load(open('$LA/instance.json'))['pid'])")
say "3 misroutes (lane a pid $pida, lane b pid $pidb)"
LANE=b LIVE_DIR="$LA" python tools/live.py '[{"do":"state"}]' --timeout 8 >> "$L" 2>&1; check 6 $? "lane b's command into lane a's folder refused"
LANE= LIVE_DIR="$LB" python tools/live.py '[{"do":"state"}]' --timeout 8 >> "$L" 2>&1; check 6 $? "lane a's command into lane b's folder refused"
LANE=b python tools/live.py '[{"do":"state"}]' --timeout 15 > appdata/t34/sentinel_b_state.log 2>&1; check 0 $? "lane b's own command answered"
[ "$pida" != "$pidb" ] && check yes yes "two distinct processes" || check yes no "two distinct processes"
say "4 waiting for lane a's take to end (its own targeted stop)"
while kill -0 $ra 2>/dev/null; do sleep 2; grep -E "^step |^DONE|^FAILED|lifetime" appdata/t34/sentinel_a_rec.log | tail -1 | sed 's/^/   a: /'; done
wait $ra; say "lane a record_walk exit $?"
sleep 1
left_a=$(python tools/method/godot_guard.py --pids "" | tr -d '\r' | tr '\n' ' ')
check "" "$left_a" "lane a gone after its targeted stop"
alive_b=$(python tools/method/godot_guard.py --pids b | tr -d '\r' | tr '\n' ' ')
check "$pidb " "$alive_b" "lane b still running (same pid)"
f1=$(python -c "import json;print(json.load(open('$LB/heartbeat.json'))['physics_frames'])")
sleep 3
f2=$(python -c "import json;print(json.load(open('$LB/heartbeat.json'))['physics_frames'])")
check yes "$([ "$f2" -gt "$f1" ] && echo yes || echo no)" "lane b heartbeat advancing after lane a stopped ($f1 -> $f2)"
wait $wb; say "lane b walk: $(grep -E '^RESULT' appdata/t34/sentinel_b_walk.log | head -1)"
say "5 stop lane b"
tools/method/stop_lane.sh b | tee -a "$L"
check "" "$(python tools/method/godot_guard.py --pids b | tr -d '\r' | tr '\n' ' ')" "lane b gone (verified)"
say "speed alone vs beside: $(grep -o 'recorded in [^)]*)' appdata/live_run.log | tail -1)"
[ $fail = 0 ] && say "SENTINEL PASS" || say "SENTINEL FAIL"
exit $fail
