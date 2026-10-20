"""Puzzle 5, the shove (2026-10-20, fixed on the shove_bench test bench): a
cart left on the flap in the van's line; the van runs into it: the cart goes
over the side, the van is thrown back, the can on the rack flies off, and
you start again at the gate. python tools/live/make_puzzle5d.py"""
import json
import os

L = "lb()"
steps = [
    {"name": "5.0 F1 Puzzles: the lift bridge", "max": 20,
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The lift bridge"}, {"do": "wait", "s": 2.0},
            {"do": "eval", "expr": "%s.gate.set('_wind_t', 99999.0)" % L}],
     "expect": [{"name": "at rest", "expr": "absf(%s.angle - 12.0) < 0.1" % L, "within": 3}]},
    {"name": "5.9 (cut) a cart on the flap in the van's line, the van behind it", "max": 30,
     "do": [{"do": "call", "fn": "shove_setup"}, {"do": "wait", "s": 1.5}],
     "expect": []},
    {"name": "5.10 the van runs into the cart: over the side, the van thrown back, the can flies", "max": 40,
     "do": [{"do": "down", "key": "W"}, {"do": "until", "expr": "%s.carts[0]['lost']" % L, "max": 10},
            {"do": "up", "key": "W"}, {"do": "wait", "s": 3.0}],
     "expect": [{"name": "the cart went over", "expr": "%s.carts[0]['lost'] or %s.failing" % (L, L), "within": 2}]},
    {"name": "5.11 back at the gate", "max": 30,
     "do": [{"do": "until", "expr": "not %s.failing" % L, "max": 15}, {"do": "wait", "s": 3.0}],
     "expect": [{"name": "the van back at the gate", "expr": "camper().global_position.distance_to(%s.van_start.origin) < 3.0" % L, "within": 3}]},
]
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, "puzzle5d.json"), "w", encoding="utf-8") as f:
    json.dump({"name": "puzzle5d", "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}], "steps": steps}, f, indent=1)
print("tools/live/puzzle5d.json: %d steps" % len(steps))
