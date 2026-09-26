#!/bin/sh
# Run the automated play-test on Linux with no window and no GPU (cloud sessions,
# CI). Same scenarios as tools/run_test.sh, but screenshots are skipped and
# frame rates are only logged, so this checks logic and physics, not looks.
# Simulated time is fixed at 60 fps, so a run is repeatable on any machine.
#   tools/run_test_headless.sh               smoke (base gym + short world checks)
#   tools/run_test_headless.sh full          everything (the plans: tools/test_plan.sh)
#   tools/run_test_headless.sh drive,brake   some scenarios
#   GYM=base tools/run_test_headless.sh      in a gym instead of the world
# Godot: $GODOT, else tools/godot/Godot_v4.7.1-stable_linux.x86_64, else
# `godot` on the PATH. user:// data goes to tools/_headless_data (gitignored).
# Exit code: 0 when every check passed, 1 on any failure or a crash.
MPG="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$MPG/tools/godot/Godot_v4.7.1-stable_linux.x86_64}"
[ -x "$GODOT" ] || GODOT="$(command -v godot || true)"
if [ -z "$GODOT" ]; then
	echo "No Linux Godot 4.7.1 found: set GODOT=/path/to/godot" >&2
	exit 2
fi
# A plan (smoke, set:..., full; tools/test_plan.sh) is one game process per
# line: run each as a segment of its own.
if [ -z "$SEGMENT" ]; then
	. "$MPG/tools/test_plan.sh"
	NL='
'
	OLD_IFS=$IFS
	IFS=$NL
	for line in $(test_plan "$1"); do
		IFS=$OLD_IFS
		SEGMENT=1 GYM="${line%%|*}" "$0" "${line#*|}" || exit $?
		IFS=$NL
	done
	exit 0
fi
DATA="$MPG/tools/_headless_data"
export XDG_DATA_HOME="$DATA/data" XDG_CONFIG_HOME="$DATA/config" XDG_CACHE_HOME="$DATA/cache"
mkdir -p "$DATA"
# A fresh checkout has no import cache; class_name scripts need it.
if [ ! -d "$MPG/FindingNaresh/.godot" ]; then
	"$GODOT" --headless --path "$MPG/FindingNaresh" --import >/dev/null 2>&1
fi
ARG="--playtest=${1:-quick}"
EXTRA=""
[ -n "$GYM" ] && EXTRA="--gym=$GYM"
LOG="${LOG:-$MPG/tools/_last_playtest.log}"
# --fixed-fps 60: every frame is exactly one 1/60 s physics step, however slow
# the machine. Without it a slow CPU runs physics behind the real-time waits
# (a 5 s "hold the pump" became ~2 s of pumping) and checks fail at random.
# timeout: a script that fails to parse leaves the game idling forever.
timeout "${TIMEOUT:-1200}" "$GODOT" --headless --fixed-fps 60 --path "$MPG/FindingNaresh" -- "$ARG" $EXTRA $ARGS 2>&1 \
	| grep --line-buffered -v -e "Interpolated Camera3D triggered from outside" -e "at: _notification (scene/3d/camera_3d.cpp" \
	| tee "$LOG"
# Pass only if the run reached the summary line, it reports 0 failures, and no
# script error happened on the way (one aborts the rest of its scenario
# without a FAIL line, so it would otherwise go unnoticed).
if grep -q "SCRIPT ERROR" "$LOG"; then
	echo "Script errors during the run (see above): failing." >&2
	exit 1
fi
grep -q "==== 0 failure(s) ====" "$LOG"
