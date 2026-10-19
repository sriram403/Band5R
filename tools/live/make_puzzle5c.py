"""Puzzle 5 round 2b, the rest of the walkthrough (after 5.0-5.6 in
puzzle5): the jump, then 5.7 a block alone tips it and 5.8 the van creeps
over the middle with nothing behind it, into the pit, back at the gate.
python tools/live/make_puzzle5c.py -> tools/live/puzzle5c.json"""
import json
import os
import runpy

here = os.path.dirname(os.path.abspath(__file__))
src = runpy.run_path(os.path.join(here, "make_puzzle5.py"))
steps = [s for s in src["steps"] if s["name"][:3] in ("5.0", "5.8")]
# from the jump P2 starts in the van: out, and to the road by the bridge
steps.insert(1, {"name": "5.1b both out, by the bridge", "max": 60,
                 "do": [{"do": "tap", "key": "E"}, src["wait"](1.0), {"do": "pad_tap", "btn": "X"}, src["wait"](1.5),
                        src["walk"](1, src["at"](-1.8, 13.0), 0.6, 40), src["walk"](2, src["at"](1.8, 13.0), 0.6, 40)]
                       + src["look"](1, src["MID"]) + src["look"](2, src["MID"]),
                 "expect": []})
with open(os.path.join(here, "puzzle5c.json"), "w", encoding="utf-8") as f:
    json.dump({"name": "puzzle5c", "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}], "steps": steps}, f, indent=1)
print("tools/live/puzzle5c.json: %d steps" % len(steps))
