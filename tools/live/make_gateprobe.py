"""T4 v2 qualification walks (speed research, test only; not part of the game's walkthrough).
python tools/live/make_gateprobe.py -> tools/live/gateprobe.json, gateprobe_late.json,
gateprobe_cancel.json, gateprobe_clean.json.

gateprobe: the ghat's real entry (F1 Puzzles, as ghat.json step 1), then short steps that give the
gate one clean boundary (step index 1: van stopped, engine off, both seated), one engine-on boundary
(index 4), a known sound (the engine start, index 2), the frame marker and an on-time deadline fixture
(9.5 game s of a 10 s step limit, index 3).
gateprobe_late: the just-late fixture: 10.5 game s of a 10 s step limit (must FAIL by name).
gateprobe_cancel: two helpers hold CTRL (one checks the cancel generation, one never does: the old
walk_breath_bot pattern), then a deliberate FAIL: nothing may press again afterwards.
gateprobe_clean: the clean pair: a checking helper runs 1.5 s, ends, releases; the walk passes.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ENTRY = {"name": "1 F1 Puzzles: the ghat: both in the van at the foot of the hairpins", "max": 25,
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The ghat pace notes"}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "both in, no Problem yet", "expr": "p1().seat != null and p2().seat != null and gh().phase == ''", "within": 4}]}


def save(name, steps):
    with open(os.path.join(HERE, name + ".json"), "w", encoding="utf-8") as f:
        json.dump({"name": name, "setup": [], "steps": steps}, f, indent=1)
    print(name, len(steps), "steps")


save("gateprobe", [
    ENTRY,
    {"name": "2 P2 swings the nav; both sit still", "max": 15,
     "do": [{"do": "pad_tap", "btn": "A"}, {"do": "wait", "s": 4.0}],
     "expect": [{"name": "nav swung", "expr": "camper().nav_aside", "within": 6}]},
    {"name": "3 the engine on (its sound)", "max": 15,
     "do": [{"do": "hold", "key": "X", "s": 0.3}, {"do": "wait", "s": 2.0}],
     "expect": [{"name": "engine on", "expr": "camper().engine_on", "within": 6}]},
    {"name": "4 the frame marker; on time: 9.5 game s inside a 10 s step limit", "max": 10,
     "do": [{"do": "marker"}, {"do": "wait", "s": 9.5}],
     "expect": [{"name": "on-time fixture done", "expr": "true", "within": 1}]},
    {"name": "5 an engine-on boundary: idle 3.5 s", "max": 15,
     "do": [{"do": "wait", "s": 3.5}],
     "expect": [{"name": "engine still on", "expr": "camper().engine_on", "within": 2}]},
    {"name": "6 end", "max": 10, "do": [{"do": "wait", "s": 0.5}], "expect": []},
])

save("gateprobe_late", [
    ENTRY,
    {"name": "2 just late: 10.5 game s inside a 10 s step limit", "max": 10,
     "do": [{"do": "wait", "s": 10.5}],
     "expect": [{"name": "late fixture done", "expr": "true", "within": 1}]},
])

save("gateprobe_cancel", [
    ENTRY,
    {"name": "2 two helpers hold CTRL, then a deliberate FAIL", "max": 15,
     "do": [{"do": "spawn", "fn": "cancel_probe_bot", "args": [4.0, False]},
            {"do": "spawn", "fn": "cancel_probe_bot", "args": [30.0, True]},
            {"do": "wait", "s": 1.0}],
     "expect": [{"name": "deliberate FAIL while CTRL is held", "expr": "false", "within": 0.5}]},
])

save("gateprobe_clean", [
    ENTRY,
    {"name": "2 a checking helper holds CTRL 1.5 s, ends and lets go", "max": 15,
     "do": [{"do": "spawn", "fn": "cancel_probe_bot", "args": [1.5, True]}, {"do": "wait", "s": 2.5}],
     "expect": [{"name": "helper done, CTRL released", "expr": "helpers_running == 0 and not ctrl_held()", "within": 3}]},
])
