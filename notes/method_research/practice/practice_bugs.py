# The PRACTICE set (public): real bugs from the ramp build, put back by their
# symptom (the fixes all landed in one commit, 98753bf, so they can't be
# reverted one by one). Written by the referee, 2026-11-05.
#
#   python -I notes/method_research/practice/practice_bugs.py P3      put P3 back
#   python -I notes/method_research/practice/practice_bugs.py list    list them
#   python -I notes/method_research/practice/practice_bugs.py restore git checkout the touched files
#
# Run from the repo root (MPG_dev). Apply ONE at a time, on a trial branch,
# never commit the result, and restore before anything else runs. Never while
# a game is running (it loads these files).
import os, subprocess, sys

S = os.path.join("FindingNaresh", "scripts")
RJ = os.path.join(S, "puzzles", "RampJump.gd")
CA = os.path.join(S, "vehicle", "Camper.gd")
HUD = os.path.join(S, "ui", "PlayerHUD.gd")

BUGS = {
	"P1": (RJ, "after a miss the van isn't on the handbrake: it rolls downhill and uses up its run-up",
		"\t\tvan.parking_brake = true\n", ""),
	"P2": (RJ, "no stone ramp at the hut door: the sill blocks walking in",
		"\tif rise > 0.05:\n\t\tvar ang := atan2(rise, run)", "\tif rise > 0.05 and false:\n\t\tvar ang := atan2(rise, run)"),
	"P3": (RJ, "a swimmer put beside the van after a miss stays in swim mode",
		"\t\t\t\tp.swimming = false\n", ""),
	"P4": (RJ, "the rubble heap lies under the window, where the crate goes",
		"_rubble = Vector3(wx + ws * 1.7, 0.15, 1.9)", "_rubble = Vector3(wx + ws * 1.3, 0.15, 0.0)"),
	"P5": (RJ, "the river wreck placed from global_position during the build: it ends up under water",
		"var y := water_y - transform.origin.y if water_y > -1e8 else -5.0",
		"var y := water_y - global_position.y if water_y > -1e8 else -5.0"),
	"P6": (CA, "the bare hub sits below the ground after the landing",
		"\t_bare_hub.visible = false\n\t_wheels[0].add_child(_bare_hub)",
		"\t_bare_hub.visible = false\n\t_bare_hub.position = Vector3(0, -0.3, 0)\n\t_wheels[0].add_child(_bare_hub)"),
	"P7": (HUD, "the HUD says PUNCTURE when the wheel is gone",
		"\t\telif camper.wheel_off:\n\t\t\tw = \"ON THE HUB - front-left wheel gone\"\n", ""),
}

if __name__ == "__main__":
	args = sys.argv[1:]
	if args == ["list"] or not args:
		for k, v in BUGS.items():
			print(k, "-", v[1])
		sys.exit(0)
	if args == ["restore"]:
		subprocess.check_call(["git", "checkout", "--", RJ, CA, HUD])
		print("restored")
		sys.exit(0)
	for b in args:
		f, what, old, new = BUGS[b]
		s = open(f, encoding="utf-8", newline="").read()
		n = s.count(old)
		if n != 1:
			sys.exit("%s: expected the target once in %s, found %d (already applied, or the code moved)" % (b, f, n))
		open(f, "w", encoding="utf-8", newline="").write(s.replace(old, new))
		print("applied", b, "-", what)
