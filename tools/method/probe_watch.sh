#!/bin/sh
# Speed research pilot P1b (2026-11-10): one watched speed-probe run. Test tool only.
# Starts tools/run_test.sh <scen> in the background (env passes through: FAST, ENGINE_ARGS,
# TIMEOUT, NO_CHECK), then every 3 s prints the speed (tools/method/speed_probe.py's reading of
# the heartbeat) and every new PASS / FAIL / SCRIPT ERROR line; kills the game on a script error
# or 20 s without a heartbeat after boot.   Usage: tools/method/probe_watch.sh <scen> <label> <out>
cd "$(dirname "$0")/../.."
scen=$1; label=$2; out=$3
rig=appdata/playtest/runs/rig.txt
# only this copy's game (another copy's game may be running)
killme() { powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | Where-Object { \$_.CommandLine -like '*MPG_speed_t1*' } | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }"; }
: > "$rig"
tools/run_test.sh "$scen" > "$out" 2>&1 &
pid=$!
seen=0; t=0; last_n=0; still=0
while kill -0 $pid 2>/dev/null; do
	sleep 3; t=$((t + 3))
	n=$(grep -c '^beat' "$rig" 2>/dev/null); n=${n:-0}
	sp=$(python -c "
import sys; sys.path.insert(0, 'tools/method'); import speed_probe as s
b = s.beats('$rig')
w = [x for x in b if x[0] >= b[-1][0] - 3000] if b else []
print('pf %d speed(3s) %.2fx scen=%s step=%s' % (b[-1][1], s.rate(w[0], b[-1]), b[-1][2] or '-', b[-1][3][:50]) if len(w) > 1 else 'beats %d' % len(b))")
	echo "[watch $label t=${t}s] $sp"
	grep -n "PASS\|FAIL\|SCRIPT ERROR\|headless" "$out" | grep -v "^ERROR: BUG" | sed -n "$((seen + 1)),\$p" | sed 's/^/    /'
	seen=$(grep -c "PASS\|FAIL\|SCRIPT ERROR\|headless" "$out")
	if grep -q "SCRIPT ERROR" "$out"; then echo "[watch] SCRIPT ERROR: stopping"; killme; fi
	if [ "$n" = "$last_n" ] && [ "$n" -gt 0 ]; then still=$((still + 3)); else still=0; fi
	last_n=$n
	if [ $still -ge 20 ]; then echo "[watch] no heartbeat for 20 s: stopping"; killme; fi
done
cp "$rig" "appdata/pilot/rig_$label.txt"
python tools/method/speed_probe.py "$rig" 0 "$label" | tail -1
