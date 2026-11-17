#!/usr/bin/env bash
# T4 v2 live gate controls (qualification only, test walks; one game, lane a, play profile).
#   tools/method/t4_live_gate.sh      -> appdata/t34/gate_session.log (+ the runs' points folders)
# 1 fresh gateprobe (the producer: points 0-5)
# 2 resume point 1 with GATE_PROBE=1 (restore although the pre-check refuses): layer 2 live, taken
#   before any await -> expected DIFFERENT naming the frozen van's lost stored velocity; walk stops before input
# 3 resume point 4 (engine on) with GATE_PROBE=1: layer 2 must name the lost engine
# 4 resume point 1 + GATE_L2_CONTINUE=1 (clean, unperturbed): layer 3 at +3 game s, what it names
# 5 the same + GATE_PERTURB=van:0.2 (moved after the immediate observation): layer 3 must name the 0.2 m
# Every resume plays a walk cut after the resumed step (the steps before it unchanged: same identity).
# Stops at the first off-plan result (the fresh walk not DONE); verified exit at the end.
cd "$(dirname "$0")/../.."
mkdir -p appdata/t34
L=appdata/t34/gate_session.log
: > "$L"
say() { echo "== $(date +%H:%M:%S) $*" | tee -a "$L"; }
python tools/live/make_gateprobe.py > /dev/null || exit 1
for n in 2 5; do
	python - "$n" <<'EOF'
import json, sys
n = int(sys.argv[1])
w = json.load(open("tools/live/gateprobe.json", encoding="utf-8"))
w["steps"] = w["steps"][:n]
json.dump(w, open("appdata/t34/gateprobe_upto%d.json" % n, "w", encoding="utf-8"), indent=1)
EOF
done
say "start lane a"
tools/method/live_session.sh start "" >> "$L" 2>&1 || { say "OFF PLAN: no game"; exit 1; }
say "1 fresh gateprobe"
python tools/live.py --walk tools/live/gateprobe.json --fresh --timeout 90 >> "$L" 2>&1
run=$(sed -n 's/^RUN \([^ ]*\) .*/\1/p' "$L" | tail -1)
if ! grep -q "^RESULT: ok" "$L"; then say "OFF PLAN: fresh walk not DONE ($run)"; tools/method/stop_lane.sh "" | tee -a "$L"; exit 1; fi
s1=$(python -c "import json;print(json.load(open('tools/live/gateprobe.json'))['steps'][1]['name'])")
s4=$(python -c "import json;print(json.load(open('tools/live/gateprobe.json'))['steps'][4]['name'])")
say "2 resume $run/1 GATE_PROBE (layer 2 live)"
GATE_PROBE=1 FROM_POINT="$run/1" python tools/live.py --walk appdata/t34/gateprobe_upto2.json --from "$s1" --timeout 40 >> "$L" 2>&1
say "3 resume $run/4 engine on, GATE_PROBE (layer 2 live)"
GATE_PROBE=1 FROM_POINT="$run/4" python tools/live.py --walk appdata/t34/gateprobe_upto5.json --from "$s4" --timeout 40 >> "$L" 2>&1
say "4 resume $run/1 GATE_L2_CONTINUE clean (layer 3)"
GATE_PROBE=1 GATE_L2_CONTINUE=1 FROM_POINT="$run/1" python tools/live.py --walk appdata/t34/gateprobe_upto2.json --from "$s1" --timeout 40 >> "$L" 2>&1
say "5 resume $run/1 GATE_L2_CONTINUE + GATE_PERTURB van:0.2 (layer 3)"
GATE_PROBE=1 GATE_L2_CONTINUE=1 GATE_PERTURB=van:0.2 FROM_POINT="$run/1" python tools/live.py --walk appdata/t34/gateprobe_upto2.json --from "$s1" --timeout 40 >> "$L" 2>&1
say "stop"
tools/method/stop_lane.sh "" | tee -a "$L"
say "end"
