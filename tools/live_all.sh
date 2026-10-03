#!/usr/bin/env bash
# Every planned walk (the user's test sheets, as watched runs), each from its
# start in a fresh game, back to back; stops at the first that fails.
#   tools/live_all.sh                 (f3 f4 f5 f6 f7 f8)
#   tools/live_all.sh f6 f7           (just those)
cd "$(dirname "$0")/.."
walks=${*:-f3 f4 f5 f6 f7 f8}
t0=$(date +%s)
for w in $walks; do
  python "tools/live/make_$w.py" >/dev/null || exit 1
  tools/live_restart.sh >/dev/null || { echo "$w: the game didn't start"; exit 1; }
  echo "=== $w ($(( $(date +%s) - t0 )) s)"
  python tools/live.py --walk "tools/live/$w.json" | grep -E "^(PASS|FAIL|step|DONE|FAILED|RESULT|ERROR)" || true
  if ! grep -q "^DONE" appdata/playtest/FindingNaresh/live/walk.log; then
    echo "stopped at $w"
    exit 1
  fi
done
python tools/live.py --quit --timeout 8 >/dev/null 2>&1
echo "all walks passed in $(( $(date +%s) - t0 )) s"
