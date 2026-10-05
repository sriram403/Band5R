"""Puzzle 1, the water works (notes/TEST_PUZZLES.md #1, the G rework in
design/PUZZLE_CHANGES.md) as a planned walk for the watched run and the
recorded walkthrough: python tools/live/make_puzzle1.py ->
tools/live/puzzle1.json. P1 on the keyboard: the key from the water tower,
the door, the pump. P2 on the pad: the yard, the valves, the standpipe.
Real walking and real keys / pad throughout."""
import json
import os

ST = "station()"


def at(x, y, z):
    """A point in the water works' own frame."""
    return "expr:ww_at(%s, %s, %s)" % (x, y, z)


# the water tower is at (-12, 0, -6); its catwalk at 14.5 m, the ladder on
# the +Z side, the key on the +X side (towards the yard)
CAT_Y = 14.6
LADDER_TOP = at(-12.0, CAT_Y, -6.0 + 5.2)
LADDER_RUNGS = at(-12.0, CAT_Y + 0.5, -6.0 + 6.25)
LADDER_FOOT_STAND = at(-12.0, 0.2, -6.0 + 7.0)
LADDER_FOOT_LOOK = at(-12.0, 1.4, -6.0 + 6.25)
ROUND = at(-12.0 + 3.71, CAT_Y, -6.0 + 3.71)       # 45 deg round the catwalk
KEY_STAND = at(-12.0 + 5.4, CAT_Y, -6.0)
KEY_LOOK = at(-12.0 + 4.62, 15.55, -6.0)
DOOR_STAND = at(1.0, 0.2, 2.1)                      # the doorway in the yard-side wall
DOOR_LOOK = at(-0.62, 1.3, 2.1)
IN_DOOR = at(-1.6, 0.2, 2.1)
PUMP_STAND = at(-3.5, 0.2, 3.7)
PUMP_LOOK = at(-3.5, 0.9, 4.9)
# round the back of the pump house (its front has the intake pipes)
BACK_E = at(1.0, 0.2, 8.6)
BACK_W = at(-10.6, 0.2, 8.6)
YARD_WAIT = at(3.5, 0.2, 0.5)                       # P2 by the tanks, in the yard
TAP_STAND = at(0.6, 0.2, 6.2)
TAP_LOOK = at(0.6, 1.0, 7.2)
A_STAND = at(2.5, 0.2, -1.6)
A_LOOK = at(2.5, 1.05, -3.0)
B_STAND = at(8.0, 0.2, -1.6)
B_LOOK = at(8.0, 1.05, -3.0)

walk = {
    "name": "puzzle1",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "1.0 F1 Puzzles: the water works",
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The water works"}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "fresh: door locked, key up the tower, tanks empty",
                     "expr": "not %s.door_open and not %s.key_taken and %s.fill['coolant'] == 0.0 and boot.story.current()['id'] == 'coolant'" % (ST, ST, ST), "within": 3}]},
        {"name": "1.1 the door is padlocked",
         "do": [{"do": "walk", "who": 1, "to": DOOR_STAND, "arrive": 0.6, "max": 30},
                {"do": "look", "who": 1, "at": DOOR_LOOK}, {"do": "wait", "s": 1.5}],
         "expect": [{"name": "the prompt says padlocked", "expr": "p1().prompt_text.contains('Padlocked')", "within": 2}]},
        {"name": "1.2 P1 climbs the water tower", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": BACK_E, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": BACK_W, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": LADDER_FOOT_STAND, "arrive": 0.5, "max": 20},
                {"do": "look", "who": 1, "at": LADDER_FOOT_LOOK}, {"do": "tap", "key": "E"},
                {"do": "until", "expr": "p1().ladder != null", "max": 2},
                {"do": "down", "key": "W"},
                {"do": "until", "expr": "p1().ladder == null", "max": 15},
                {"do": "up", "key": "W"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "on the catwalk", "expr": "p1().global_position.y > %s.global_position.y + 14.0 and p1().is_on_floor()" % ST, "within": 2}]},
        {"name": "1.3 round the catwalk to the key (the yard below)", "max": 60,
         "do": [{"do": "walk", "who": 1, "to": ROUND, "arrive": 0.5, "max": 15},
                {"do": "walk", "who": 1, "to": KEY_STAND, "arrive": 0.4, "max": 15},
                {"do": "look", "who": 1, "at": at(-2.0, 0.0, 2.0)}, {"do": "wait", "s": 2.5},
                {"do": "look", "who": 1, "at": KEY_LOOK}, {"do": "tap", "key": "E"}],
         "expect": [{"name": "P1 has the key", "expr": "%s.key_taken and %s.key_by == 0" % (ST, ST), "within": 2}]},
        {"name": "1.4 back down and unlock the pump house", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": ROUND, "arrive": 0.5, "max": 15},
                {"do": "walk", "who": 1, "to": LADDER_TOP, "arrive": 0.4, "max": 15},
                {"do": "look", "who": 1, "at": LADDER_RUNGS}, {"do": "tap", "key": "E"},
                {"do": "until", "expr": "p1().ladder != null", "max": 2},
                {"do": "down", "key": "S"},
                {"do": "until", "expr": "p1().ladder == null", "max": 15},
                {"do": "up", "key": "S"},
                {"do": "walk", "who": 1, "to": BACK_W, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": BACK_E, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": DOOR_STAND, "arrive": 0.6, "max": 20},
                {"do": "look", "who": 1, "at": DOOR_LOOK}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.5}],
         "expect": [{"name": "the door swings open", "expr": "%s.door_open" % ST, "within": 2}]},
        {"name": "1.5 P1 pumps before the valves are set: the grey tank bursts on P2", "max": 90,
         "do": [{"do": "walk", "who": 2, "to": YARD_WAIT, "arrive": 0.8, "max": 40},
                {"do": "walk", "who": 1, "to": IN_DOOR, "arrive": 0.5, "max": 15},
                {"do": "walk", "who": 1, "to": PUMP_STAND, "arrive": 0.4, "max": 15},
                {"do": "look", "who": 1, "at": PUMP_LOOK}, {"do": "wait", "s": 1.0},
                {"do": "call", "fn": "ww_pump_strokes", "args": [6]},
                {"do": "until", "expr": "%s.bursts > 0" % ST, "max": 6}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "it burst; P2 in the yard covered, P1 inside not",
                     "expr": "%s.bursts == 1 and p2().slime_t > 0.0 and p1().slime_t <= 0.0" % ST, "within": 2}]},
        {"name": "1.6 P2 rinses off at the standpipe (in slow motion)", "max": 90,
         "do": [{"do": "walk", "who": 2, "to": TAP_STAND, "arrive": 0.6, "max": 40},
                {"do": "look", "who": 2, "at": TAP_LOOK}, {"do": "pad_hold", "btn": "X", "s": 3.6}],
         "expect": [{"name": "clean again", "expr": "p2().slime_t <= 0.0", "within": 2}]},
        {"name": "1.7 P2 sets the valves (no pumping: no gulp)", "max": 90,
         "do": [{"do": "walk", "who": 2, "to": A_STAND, "arrive": 0.5, "max": 40},
                {"do": "look", "who": 2, "at": A_LOOK}, {"do": "pad_tap", "btn": "X"},
                {"do": "walk", "who": 2, "to": B_STAND, "arrive": 0.5, "max": 30},
                {"do": "look", "who": 2, "at": B_LOOK}, {"do": "pad_tap", "btn": "X"}],
         "expect": [{"name": "the line goes to the blue tank", "expr": "%s.route() == 'coolant' and %s.gulps == 0" % (ST, ST), "within": 2}]},
        {"name": "1.8 a valve turned while pumping: the gulp", "max": 90,
         "do": [{"do": "call", "fn": "ww_pump_until", "args": ["blue25", 40]},
                {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 2.5},
                {"do": "call", "fn": "ww_wait_pressure_off"}, {"do": "pad_tap", "btn": "X"}],
         "expect": [{"name": "blue gulped into grey, then turned back with the pressure off",
                     "expr": "%s.gulps == 1 and %s.route() == 'coolant'" % (ST, ST), "within": 2}]},
        {"name": "1.9 pump on; valve B slips twice, P2 turns it back each time", "max": 240,
         "do": [{"do": "call", "fn": "ww_pump_until", "args": ["slip_or_solved", 70]},
                {"do": "call", "fn": "ww_wait_pressure_off"}, {"do": "call", "fn": "ww_fix_b"},
                {"do": "call", "fn": "ww_pump_until", "args": ["slip_or_solved", 70]},
                {"do": "call", "fn": "ww_wait_pressure_off"}, {"do": "call", "fn": "ww_fix_b"},
                {"do": "call", "fn": "ww_pump_until", "args": ["slip_or_solved", 70]},
                {"do": "call", "fn": "ww_wait_pressure_off"}, {"do": "call", "fn": "ww_fix_b"},
                {"do": "call", "fn": "ww_pump_until", "args": ["slip_or_solved", 70]},
                {"do": "wait", "s": 2.0}],
         "expect": [{"name": "the blue tank full: the coolant jug at the tap",
                     "expr": "%s.solved and %s.slips == 2" % (ST, ST), "within": 3}]},
        {"name": "1.10 the reward", "max": 40,
         "do": [{"do": "walk", "who": 2, "to": at(10.5, 0.2, 0.6), "arrive": 0.6, "max": 30},
                {"do": "look", "who": 2, "at": at(10.5, 0.3, 2.1)}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "the jug is there", "expr": "boot.world.get_node_or_null('CoolantJug') != null", "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "puzzle1.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
