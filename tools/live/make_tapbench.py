"""F5 bench walk (speed research fix round, test only; not part of the game's walkthrough).
python tools/live/make_tapbench.py -> tools/live/tapbench.json

The ghat's real entry (as gateprobe), then 20 N taps alone and 20 N taps while a second game window
comes up (the shell starts lane b when step 3 begins). Each tap is judged by its effect (P1's nav swing
must flip once per tap) and logged with the focus changes of this window (PlayTest.tap_bench).
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
# the ghat's real entry, as tools/live/make_gateprobe.py (copied: importing it would rewrite its walks)
ENTRY = {"name": "1 F1 Puzzles: the ghat: both in the van at the foot of the hairpins", "max": 25,
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The ghat pace notes"}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "both in, no Problem yet", "expr": "p1().seat != null and p2().seat != null and gh().phase == ''", "within": 4}]}
steps = [
    ENTRY,
    {"name": "2 alone: 20 N taps", "max": 40,
     "do": [{"do": "call", "fn": "tap_bench", "args": [20, "alone", 0.8]}],
     "expect": [{"name": "alone bench logged", "expr": "bench_lines.size() >= 21", "within": 2}]},
    {"name": "3 beside: 20 N taps while a second game comes up", "max": 45,
     "do": [{"do": "wait", "s": 1.0}, {"do": "call", "fn": "tap_bench", "args": [20, "beside", 0.8]}],
     "expect": [{"name": "beside bench logged", "expr": "bench_lines.size() >= 42", "within": 2}]},
    {"name": "4 end", "max": 10, "do": [{"do": "wait", "s": 0.5}], "expect": []},
]
with open(os.path.join(HERE, "tapbench.json"), "w", encoding="utf-8") as f:
    json.dump({"name": "tapbench", "setup": [], "steps": steps}, f, indent=1)
print("tapbench", len(steps), "steps")
