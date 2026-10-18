"""Puzzle 5, the lift bridge: the seesaw (design/PUZZLE_CHANGES.md #5,
round 1b, agreed 2026-10-17) as a planned walk for the watched run and the
recorded walkthrough: python tools/live/make_puzzle5.py ->
tools/live/puzzle5.json. P1 on the keyboard, P2 on the pad. The dead hut,
Naresh's notes, the leg-up through the machinery house's hatch, the door
unbarred, the lock refused while the leaf is up, a stone by the axle (does
nothing), one at the tip with a stone (nothing), P2 out halfway with a
second stone (it comes down, gently), both stones at the tip, P2 walks off
(it stays down) and throws the lock. Then the fun: P1 jumps off the side
into the river and swims out, soaked. Real walking and real keys / pad."""
import json
import os

L = "lb()"


def wait(s):
    return {"do": "wait", "s": s}


def look(who, at, s=0.4):
    return [{"do": "look", "who": who, "at": at}, wait(s)]


def walk(who, to, arrive=0.5, mx=30):
    return {"do": "walk", "who": who, "to": to, "arrive": arrive, "max": mx}


def p1_take_stone(near):
    return [walk(1, "expr:lb_stone(%s)" % near, 1.1, 15)] + look(1, "expr:lb_stone(%s)" % near) + [{"do": "tap", "key": "E"}, wait(0.8)]


def p2_take_stone(near):
    return [walk(2, "expr:lb_stone(%s)" % near, 1.1, 15)] + look(2, "expr:lb_stone(%s)" % near) + [{"do": "pad_tap", "btn": "X"}, wait(0.8)]


HEAP = "boot.builder.poi['stone_heap']"

steps = [
    {"name": "5.0 F1 Puzzles: the lift bridge",
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The lift bridge"}, wait(2.0)],
     "expect": [{"name": "fresh: the leaf up, the house barred", "expr": "%s.angle > 29.9 and not %s.door_open and not %s.locked" % (L, L, L), "within": 3}]},
    {"name": "5.1 both out of the van; P1 tries the hut's levers and reads Naresh's note", "max": 70,
     "do": [{"do": "tap", "key": "E"}, wait(1.0), {"do": "pad_tap", "btn": "X"}, wait(1.5),
            walk(1, "expr:boot.builder.poi['bridge_hut_door']", 0.6, 30),
            walk(1, "expr:lb_panel_stand()", 0.4, 10)]
            + look(1, "expr:%s.find_child('LOWERLever', true, false).global_position" % L, 2.5)
            + look(1, "expr:%s.find_child('NareshNote_lb_hut', true, false).global_position" % L)
            + [{"do": "tap", "key": "E"}, wait(8.0)],
     "expect": [{"name": "his note read: a seesaw", "expr": "lb_note_read('lb_hut')", "within": 2}]},
    {"name": "5.2 P2 at the machinery house: barred; Naresh's note by the door", "max": 60,
     "do": [walk(2, "expr:boot.builder.poi['bridge_hut_door']", 0.8, 40),     # round the barrier, past the hut
            walk(2, "expr:boot.builder.poi['machinery_door']", 0.5, 30)]
            + look(2, "expr:lb_door_look()", 2.5)
            + look(2, "expr:%s.find_child('NareshNote_lb_door', true, false).global_position" % L)
            + [{"do": "pad_tap", "btn": "X"}, wait(7.0)],
     "expect": [{"name": "his note read: a leg-up", "expr": "lb_note_read('lb_door')", "within": 2}]},
    {"name": "5.3 the leg-up: P2 crouches under the hatch, P1 jumps up off their back", "max": 70,
     "do": [walk(2, "expr:lb_hatch(0.0)", 0.3, 15)] + look(2, "expr:lb_hatch(2.0) + Vector3(0, 1.0, 0)")
            + [{"do": "pad_down", "btn": "B"}, wait(1.0),
               walk(1, "expr:lb_hatch(-1.6)", 0.5, 40), walk(1, "expr:lb_hatch(-0.85)", 0.25, 6)]
            + look(1, "expr:lb_hatch(2.0) + Vector3(0, 2.2, 0)", 1.5)
            + [{"do": "down", "key": "W"}, {"do": "tap", "key": "Space"}, wait(1.4), {"do": "up", "key": "W"},
               {"do": "pad_up", "btn": "B"}, wait(1.0)],
     "expect": [{"name": "P1 in through the hatch", "expr": "%s._inside_house(p1())" % L, "within": 3}]},
    {"name": "5.4 P1 lifts the bar and opens the door; the lock won't go with the leaf up", "max": 60,
     "do": [walk(1, "expr:boot.builder.poi['machinery_in']", 0.5, 10)] + look(1, "expr:lb_door_look()")
            + [{"do": "tap", "key": "E"}, wait(1.5),
               walk(1, "expr:boot.builder.poi['machinery_mid']", 0.5, 10), walk(1, "expr:boot.builder.poi['lock_lever']", 0.5, 10)]
            + look(1, "expr:%s.find_child('LockArea', true, false).global_position" % L, 3.0)
            + look(1, "expr:%s.find_child('NareshNote_lb_lock', true, false).global_position" % L)
            + [{"do": "tap", "key": "E"}, wait(8.0)],
     "expect": [{"name": "the door open; still up", "expr": "%s.door_open and %s.angle > 29.9" % (L, L), "within": 2}]},
    {"name": "5.5 a stone from the crew's heap, dropped by the axle: nothing", "max": 70,
     "do": [walk(1, "expr:boot.builder.poi['machinery_mid']", 0.5, 10), walk(1, "expr:boot.builder.poi['machinery_door']", 0.5, 15)]
            + p1_take_stone(HEAP)
            + [walk(1, "expr:leaf_at(lb(), 1.2, 0.0)", 0.4, 15), {"do": "tap", "key": "E"}, wait(1.5),
               walk(1, "expr:%s" % HEAP, 1.6, 15), wait(2.0)],
     "expect": [{"name": "still up", "expr": "%s.angle > 29.9" % L, "within": 2}]},
    {"name": "5.6 P1 carries a stone up to the tip: still nothing", "max": 70,
     "do": p1_take_stone(HEAP)
            + [walk(1, "expr:leaf_at(lb(), 8.6, -1.0)", 0.4, 25), {"do": "tap", "key": "E"}, wait(1.0)]
            + look(1, "expr:%s" % HEAP, 3.0),
     "expect": [{"name": "still up with P1 and a stone at the tip", "expr": "%s.angle > 29.9 and lb_stones_out() >= 1" % L, "within": 2}]},
    {"name": "5.7 P2 brings a second stone out, slowly: down it comes, gently", "max": 80,
     "do": p2_take_stone(HEAP)
            + [walk(2, "expr:leaf_at(lb(), 5.0, 1.0)", 0.4, 25),
               {"do": "until", "expr": "lb().angle < 0.1", "max": 25}, wait(1.5)],
     "expect": [{"name": "down on the far bank, no slam", "expr": "%s.angle < 0.1 and %s.slams == 0" % (L, L), "within": 2}]},
    {"name": "5.8 P2's stone to the tip; P2 walks off: P1 and two stones hold it", "max": 70,
     "do": [walk(2, "expr:leaf_at(lb(), 8.3, 1.0)", 0.4, 15), {"do": "pad_tap", "btn": "X"}, wait(1.0),
            walk(2, "expr:boot.builder.poi['machinery_door']", 0.6, 30), wait(2.0)],
     "expect": [{"name": "still down", "expr": "%s.angle < 0.1" % L, "within": 2}]},
    {"name": "5.9 P2 throws the lock: CLANK", "max": 50,
     "do": [walk(2, "expr:boot.builder.poi['machinery_in']", 0.5, 10), walk(2, "expr:boot.builder.poi['machinery_mid']", 0.5, 10),
            walk(2, "expr:boot.builder.poi['lock_lever']", 0.5, 10)]
            + look(2, "expr:%s.find_child('LockArea', true, false).global_position" % L)
            + [{"do": "pad_tap", "btn": "X"}, wait(4.0)],
     "expect": [{"name": "locked; the barriers gone", "expr": "%s.locked and not boot.builder.bridge_barriers.visible" % L, "within": 2}]},
    {"name": "5.10 the fun: P1 jumps over the kerb into the river and swims out", "max": 80,
     "do": [walk(1, "expr:leaf_at(lb(), 5.0, -lb().deck_w * 0.5 + 1.0)", 0.4, 15)]
            + look(1, "expr:lb().leaf.global_transform * Vector3(-8.0, 0.0, -5.0)")
            + [{"do": "down", "key": "W"}, wait(0.25), {"do": "tap", "key": "Space"}, wait(1.5), {"do": "up", "key": "W"},
               {"do": "until", "expr": "not p1().swimming and p1().wet_t > 0.0", "max": 50}, wait(3.0)],
     "expect": [{"name": "out on the bank, soaked", "expr": "p1().wet_t > 0.0 and not p1().swimming", "within": 3}]},
]

walk_plan = {"name": "puzzle5",
             "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
             "steps": steps}
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, "puzzle5.json"), "w", encoding="utf-8") as f:
    json.dump(walk_plan, f, indent=1)
print("tools/live/puzzle5.json: %d steps" % len(steps))
