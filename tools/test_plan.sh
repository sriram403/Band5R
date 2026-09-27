# The play-test plans, shared by tools/run_test.sh (Windows, a window) and
# tools/run_test_headless.sh (Linux, no window: GitHub). One source, so the
# two can't drift apart. `test_plan <name>` prints one line per game process:
# "<gym>|<scenarios>" (an empty gym is the game world).
#
#   (none), smoke   ~3 min: the controls in the base gym, one short world check
#                   per system. After a fix, with the scenarios for the change.
#   set:opening     the two-player opening, all four runs
#   set:gyms        every mechanic's test map
#   set:puzzles     the way-out puzzles in the world
#   set:creatures   the stealth and creature gyms, the ghat, the watchtower
#   set:driving     the base gym's driving, the long drives and the way out
#   set:world       the world checks (the old Quick list)
#   set:bessi       Bessi beach and the roses (Milestone E)
#   set:world_full  the world part of full alone (the long drives and every
#                   world check), e.g. after a crash in it
#   full            everything: before a push or a hand-over, and on GitHub
#   a,b,c           these scenarios (in the world, or in $GYM)
#   quick           the old name: now the same as smoke
test_plan() {
	if [ -n "$GYM" ]; then
		echo "$GYM|${1:-quick}"
		return
	fi
	case "$1" in
	""|smoke|quick)
		echo "base|smoke"
		echo "|smoke" ;;
	set:opening)
		echo "|opening"
		echo "|opening_save"
		echo "|opening_p2"
		echo "|opening_full" ;;
	set:gyms)
		echo "tagging|tagging"
		echo "binoculars|binoculars"
		echo "stealth|stealth,taken,hiding"
		echo "creature|van"
		echo "naresh|naresh"
		echo "photo|photo_gym"
		echo "traffic|traffic,lorry"
		echo "house|house"
		echo "tyre|tyre"
		echo "base|gym_quick" ;;
	set:puzzles)
		echo "|windmill,waterworks,power,bridge,maze,relay,relay_kb" ;;
	set:creatures)
		echo "stealth|stealth,taken,hiding"
		echo "creature|van"
		echo "|ghat,ghat_menu,tower" ;;
	set:driving)
		echo "base|gym_quick"
		echo "|journey,routes,way_out" ;;
	set:world)
		echo "|quick" ;;
	set:bessi)
		echo "photo|photo_gym"
		echo "|beach,photo" ;;
	set:world_full)
		echo "|full" ;;
	full)
		test_plan set:opening
		test_plan set:gyms
		echo "|full" ;;
	*)
		echo "|$1" ;;
	esac
}
