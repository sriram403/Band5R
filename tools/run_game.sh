#!/bin/sh
# Run the Godot console build with the same C:-avoiding data redirect as
# Play.bat. Extra arguments go straight to Godot, e.g.
#   tools/run_game.sh --resolution 1600x900 -- --playtest
MPG="$(cd "$(dirname "$0")/.." && pwd -W 2>/dev/null || pwd)"
MPG_DATA="${MPG_DATA:-$MPG/appdata}"
export APPDATA="$MPG_DATA"
export LOCALAPPDATA="$MPG_DATA/local"
exec "$MPG/tools/godot/Godot_v4.7.1-stable_win64_console.exe" --path "$MPG/FindingNaresh" "$@"
