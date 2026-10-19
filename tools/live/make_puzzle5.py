"""Puzzle 5, the lift bridge, round 2b: the lively seesaw (design/
PUZZLE_CHANGES.md #5 "Round 2b", agreed 2026-10-19 after the user's "it
didn't even seesaw") as a planned walk for the recorded walkthrough:
python tools/live/make_puzzle5.py -> tools/live/puzzle5.json.
P1 on the keyboard, P2 on the pad, real walking. For this video the barrier
is wound up and held by code (the gate isn't what's being judged). Shows:
the seesaw at rest from the road; P1 walks out past the middle and it tips
down, walks back and it tips up; P2 stays on the near half as weight while P1
walks to the far end (it holds); P2 walks out too and it goes down; both off,
it swings back; a 300 kg block pushed out on the far half tips it alone; the
van creeps on and over the middle with nothing behind it: down into the pit,
back at the gate."""
import json
import os

L = "lb()"


def wait(s):
    return {"do": "wait", "s": s}


def at(x, z, y=0.0):
    return "expr:%s.global_transform * Vector3(%s, %s, %s)" % (L, x, y, z)


def look(who, to, s=0.4):
    return [{"do": "look", "who": who, "at": to}, wait(s)]


def walk(who, to, arrive=0.4, mx=30):
    return {"do": "walk", "who": who, "to": to, "arrive": arrive, "max": mx}


MID = at(0, -5.0, 0.5)
# the 300 kg cart (carts[3]), the front one on its rail
# (as the bridge test does: stand 1.3 m behind it, hold X, push the stick)
CART3_IN = "expr:%s.global_transform * Vector3(%s.carts[3]['rail'] * 2.4, 0, %s.carts[3]['z'] + 1.3)" % (L, L, L)
CART3_PLACE = "expr:%s.carts[3]['node'].global_position + %s.global_transform.basis.z * 1.3 + Vector3(0, 0.4, 0)" % (L, L)          # the pivot (leaf 10 m, local -Z over the river)

steps = [
    {"name": "5.0 F1 Puzzles: the lift bridge", "max": 20,
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The lift bridge"}, wait(2.0),
            {"do": "eval", "expr": "%s.gate.set('_wind_t', 99999.0)" % L}, wait(1.0)],
     "expect": [{"name": "at rest: far end up 12 degrees, four blocks", "expr": "absf(%s.angle - 12.0) < 0.1 and %s.carts.size() == 4" % (L, L), "within": 3}]},
    {"name": "5.1 both out; from the road the far end is up", "max": 60,
     "do": [{"do": "tap", "key": "E"}, wait(1.0), {"do": "pad_tap", "btn": "X"}, wait(1.5),
            walk(1, at(-1.5, 13.0), 0.6, 40), walk(2, at(1.8, 13.0), 0.6, 40)]
            + look(1, MID) + look(2, MID, 3.0),
     "expect": [{"name": "both on the road by the bridge", "expr": "(%s.global_transform.affine_inverse() * p1().global_position).z > 9.0" % L, "within": 2}]},
    {"name": "5.2 P1 walks out past the middle: it tips down", "max": 40,
     "do": [walk(1, at(-1.5, -8.6)), {"do": "until", "expr": "%s.angle < -2.0" % L, "max": 12}] + look(1, at(0, -14.0)) + look(2, MID, 2.0),
     "expect": [{"name": "the far end went down", "expr": "%s.angle < 0.0" % L, "within": 2}]},
    {"name": "5.3 P1 walks back past the middle: it tips up", "max": 40,
     "do": [walk(1, at(-1.5, -1.5)), {"do": "until", "expr": "%s.angle > 10.0" % L, "max": 12}] + look(1, MID, 1.5),
     "expect": [{"name": "the far end is back up", "expr": "%s.angle > 8.0" % L, "within": 2}]},
    {"name": "5.4 P2 stays on the near half as weight; P1 walks to the far end: it holds", "max": 60,
     "do": [walk(2, at(1.5, -1.5)), walk(1, at(-1.5, -9.4)), wait(3.0)] + look(1, "expr:%s.hut.global_position" % L, 2.0),
     "expect": [{"name": "still up with one on each half", "expr": "%s.angle > 4.0" % L, "within": 2}]},
    {"name": "5.5 P2 walks out to the far half too: down it goes", "max": 40,
     "do": [walk(2, at(1.5, -8.0)), {"do": "until", "expr": "%s.angle < -2.0" % L, "max": 12}, wait(1.5)],
     "expect": [{"name": "both on the far half: down", "expr": "%s.angle < 0.0" % L, "within": 2}]},
    {"name": "5.6 both walk back off: it swings and settles up", "max": 60,
     "do": [walk(1, at(-1.8, 12.0), 0.6, 30), walk(2, at(1.8, 12.0), 0.6, 30)] + look(1, MID) + look(2, MID)
            + [{"do": "until", "expr": "%s.angle > 11.9" % L, "max": 20}],
     "expect": [{"name": "empty: back at rest", "expr": "%s.angle > 11.5" % L, "within": 3}]},
    {"name": "5.7 P2 pushes the 300 kg block out on the far half: it tips on its own", "max": 60,
     # P2 put straight behind it, as the bridge test does (walking there
     # ended up beside it, river side, 2026-10-19): a cut in the video
     "do": [walk(2, CART3_IN, 0.4, 30), {"do": "call", "fn": "place_player", "args": ["p2", CART3_PLACE, 0.0]}, wait(0.3)]
            + look(2, "expr:%s.carts[3]['node'].global_position + Vector3(0, 0.6, 0)" % L)
            + [{"do": "pad_down", "btn": "X"}, {"do": "pad_axis", "axis": "LY", "v": -0.6},
               {"do": "until", "expr": "float(%s.carts[3]['z']) < -6.8 or %s.angle < 0.0" % (L, L), "max": 45},
               {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "pad_up", "btn": "X"},
               walk(2, at(1.8, -4.0), 0.5, 20)] + look(2, MID)
            + [{"do": "until", "expr": "%s.angle < 0.0" % L, "max": 15}, wait(2.0)],
     "expect": [{"name": "the block out on the far half tips it down", "expr": "%s.angle < 0.0" % L, "within": 3}]},
    {"name": "5.8 the block back, the van creeps on with nothing behind it: past the middle into the pit", "max": 120,
     "do": [{"do": "eval", "expr": "%s.reset_bridge()" % L}, {"do": "eval", "expr": "%s.gate.set('_wind_t', 99999.0)" % L}, wait(1.0),
            walk(2, at(3.2, 16.0), 0.6, 30), {"do": "look", "who": 2, "at": MID}, wait(0.3),
            {"do": "call", "fn": "seat_p1_driver"}, wait(1.0),
            {"do": "tap", "key": "X"}, wait(1.5), {"do": "tap", "key": "SPACE"}, wait(0.5),
            # creeping at 6 km/h, as a careful driver would, nobody moving blocks
            {"do": "drive", "road": "pump_house_road", "to": at(0, -14.0), "until": "%s.failing" % L, "max": 90, "kmh": 6},
            {"do": "until", "expr": "%s.failing" % L, "max": 15}, wait(5.0)],
     "expect": [{"name": "into the pit, back at the gate", "expr": "camper().global_position.distance_to(%s.van_start.origin) < 3.0" % L, "within": 6}]},
]

out = os.path.join(os.path.dirname(__file__), "puzzle5.json")
with open(out, "w") as f:
    json.dump({"name": "puzzle5", "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}], "steps": steps}, f, indent=1)
print(out)
