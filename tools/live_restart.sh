#!/usr/bin/env bash
# Restart the live game (after a code change) and wait until it's ready.
#   tools/live_restart.sh            (GYM=<name> for a gym)
cd "$(dirname "$0")/.."
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
sleep 2
rm -f appdata/playtest/FindingNaresh/live/log_seen
TIMEOUT=${TIMEOUT:-7200} nohup tools/run_test.sh live > appdata/live_run.log 2>&1 &
for i in $(seq 1 90); do
  grep -q "\[live\] ready" appdata/live_run.log 2>/dev/null && { echo "ready"; exit 0; }
  grep -m3 "Parse Error\|SCRIPT ERROR" appdata/live_run.log 2>/dev/null && { echo "failed"; exit 1; }
  sleep 2
done
echo "not ready in 180 s"; exit 1
