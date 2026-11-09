"""Prove #6's checks against their planted bugs (FINAL.md port step 8).

Each group runs tools/method_run.sh ghat with FIXTURE=<plants> and GHAT=<scenarios>,
then reads its verdict: every expected check (or rule) must be named in a FAIL
condition, or the proof fails. Groups only combine plants that can't mask each
other. The clean run (no fixture) is separate: tools/method_run.sh ghat.
Usage: python tools/method/prove_ghat.py [group ...]   (no names: all)
Output: appdata/method/prove_ghat.txt (one line per plant), plus each run's folder.
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "appdata", "method", "prove_ghat.txt")

# group: (scenarios, plants, {plant: [text the FAIL must contain, ...]})
GROUPS = {
    "heat_always": ("ghat_heat", "heat_always,one_corner", {"heat_always": ["no heat or leak from it before it sees the van", "H1:"]}),
    "stall_hud": ("ghat_heat", "no_stall_drag,hud_heat,one_flat", {"no_stall_drag": ["it comes to rest before the pass, in the fog"],
                                                                     "hud_heat": ["hot with it watching: no TEMP / COOL bars"]}),
    "fog_h2_keep": ("ghat_heat", "fog_short,seen_h2,keeps_interest,one_corner", {"fog_short": ["the fog lies all the way up to the pass"],
                                                                                   "seen_h2": ["the heat alone boils it, the pass guard not needed"],
                                                                                   "keeps_interest": ["once it gives up the heat and the leak stop"]}),
    "looks": ("ghat_looks", "lean_close,fast_turn", {"lean_close": ["its face stays outside the glass"], "fast_turn": ["it turns away slowly"]}),
    "net": ("ghat_net", "one_layer_net", {"one_layer_net": ["from outside nothing of the van shows through the net"]}),
    "jug_a": ("ghat_jug", "leave_sees,no_breath_lock,round_skip", {"leave_sees": ["out beside it after it gave up: nobody is taken"],
                                                                     "no_breath_lock": ["never touched the handbrake"],
                                                                     "round_skip": ["it went all round the van before it gave up"]}),
    "jug_b": ("ghat_jug", "no_fix,free_coolant,needle_stuck", {"no_fix": ["cool now, it pours in: the radiator is full again"],
                                                                 "free_coolant": ["H3:"], "needle_stuck": ["H2:"]}),
    "jug_c": ("ghat_jug", "no_power", {"no_power": ["over the pass"]}),
    "spring_a": ("ghat_spring", "seat_compare,cap_text", {"seat_compare": ["both windows visited"], "cap_text": ["Open the radiator cap"]}),
    "spring_b": ("ghat_spring", "endless_window", {"endless_window": ["quiet at last, it gives up"]}),
    "marks": ("ghat_looks,ghat_marks", "marks_pile,marks_unsaved", {"marks_pile": ["a clean van to start with"],
                                                                     "marks_unsaved": ["the marks are saved and come back on load"]}),
}


def run(name):
    scen, plants, expect = GROUPS[name]
    env = dict(os.environ, GHAT=scen, FIXTURE=plants)
    before = set(glob.glob(os.path.join(ROOT, "appdata", "method", "runs", "*")))
    print("== %s: %s with %s" % (name, scen, plants), flush=True)
    subprocess.run(["bash", os.path.join(ROOT, "tools", "method_run.sh"), "ghat"], cwd=ROOT, env=env)
    new = sorted(set(glob.glob(os.path.join(ROOT, "appdata", "method", "runs", "*"))) - before)
    verdict = open(os.path.join(new[-1], "verdict.txt"), encoding="utf-8").read() if new else ""
    fails = [ln for ln in verdict.splitlines() if ln.strip().startswith(("FAIL", "RESULT: FAIL"))]
    rows = []
    for plant, texts in expect.items():
        ok = all(any(t in ln for ln in fails) for t in texts)
        rows.append("%-15s %-12s %s  (%s)  run %s" % (plant, "PROVED" if ok else "NOT PROVED", " + ".join(texts), verdict.splitlines()[0] if verdict else "no verdict", os.path.basename(new[-1]) if new else "-"))
    with open(OUT, "a", encoding="utf-8") as f:
        for r in rows:
            f.write(r + "\n")
            print(r, flush=True)


if __name__ == "__main__":
    for g in (sys.argv[1:] or list(GROUPS)):
        run(g)
