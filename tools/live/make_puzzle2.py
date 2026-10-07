"""Puzzle 2, the windmill (notes/TEST_PUZZLES.md #2, the G rework in
design/PUZZLE_CHANGES.md #2) as a planned walk for the watched run and the
recorded walkthrough: python tools/live/make_puzzle2.py ->
tools/live/puzzle2.json. P1 on the keyboard: the van, the starter lever.
P2 on the pad: the legs (head-butts), the ladder, the chest. Real walking
and real keys / pad throughout; the real 45 s spin-up."""
import json
import os

WM = "wm()"


def at(x, y, z):
    """A point in the windmill's own frame (-Z faces the lane)."""
    return "expr:wm_at(%s, %s, %s)" % (x, y, z)


LEVER_STAND = at(0.0, 0.2, -19.0)
LEVER_LOOK = at(0.0, 1.5, -18.0)
NOTE_LOOK = at(0.0, 0.45, -18.3)
UNDER = at(-6.5, 0.2, -2.0)            # P2 off to one side of the legs, watching
LADDER_STAND = at(0.0, 0.2, 3.85)
LADDER_LOOK = at(0.0, 1.6, 2.45)
TOP_LOOKOUT = at(-1.7, 22.8, -1.4)
VIEW_LOOK = "expr:boot.builder.poi['j1'] + (boot.builder.poi['j1'] - wm().global_position) * 4.0 + Vector3(0, 20, 0)"
CHEST_STAND = at(-0.2, 22.8, 1.4)
CHEST_LOOK = "expr:wm().tower.get_node('Chest').global_position + Vector3(0, 0.35, 0)"
TOP_LADDER = at(0.0, 22.8, 1.6)
TOP_LADDER_LOOK = at(0.0, 23.2, 2.45)
GATE_LOOK = "expr:boot.builder.poi['windmill_gate'] + Vector3(0, 2, 0)"
VAN_DOOR_L = "expr:boot.camper.global_transform * Vector3(-2.3, 0.2, -1.2)"
VAN_DOOR_R = "expr:boot.camper.global_transform * Vector3(2.3, 0.2, -1.2)"
VAN_SEAT_LOOK_L = "expr:boot.camper.global_transform * Vector3(-0.9, 1.4, -1.2)"
VAN_SEAT_LOOK_R = "expr:boot.camper.global_transform * Vector3(0.9, 1.4, -1.2)"

walk = {
    "name": "puzzle2",
    # P2 has the map, as after the opening (a new game's opening hands it to P2)
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}, {"do": "eval", "expr": "boot.map_state.set('holder', 1)"}],
    "steps": [
        {"name": "2.0 F1 Puzzles: the windmill",
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The windmill"}, {"do": "wait", "s": 1.5},
                {"do": "eval", "expr": "wm().rng.seed = 11"}],
         "expect": [{"name": "fresh: still, the gate down, both in the van",
                     "expr": "not %s.caught and %s.power == 0.0 and p1().seat != null and p2().seat != null" % (WM, WM), "within": 3}]},
        {"name": "2.1 up the lane: the junction gate stops the van", "max": 60,
         "do": [{"do": "call", "fn": "engine_on"}, {"do": "eval", "expr": "boot.camper.set_parking_brake(false)"},
                {"do": "drive", "road": "home_lane", "to": "expr:wm_gate_approach(9.0)", "until": "false", "max": 30, "kmh": 25},
                {"do": "down", "key": "S"}, {"do": "wait", "s": 1.5}, {"do": "up", "key": "S"},
                {"do": "tap", "key": "Space"}, {"do": "look", "who": 1, "at": GATE_LOOK}, {"do": "wait", "s": 2.5}],
         "expect": [{"name": "the van stopped short of the closed gate",
                     "expr": "wm_van_short_of_gate() and boot.camper.linear_velocity.length() < 0.5", "within": 3}]},
        {"name": "2.2 both out; P1 reads Naresh's note at the starter lever", "max": 60,
         "do": [{"do": "tap", "key": "E"}, {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 0.8},
                {"do": "walk", "who": 1, "to": LEVER_STAND, "arrive": 0.5, "max": 30},
                {"do": "call", "fn": "round_van", "args": ["p2", -1.0, True]},
                {"do": "walk", "who": 2, "to": at(-8.5, 0.2, -9.0), "arrive": 0.8, "max": 40},
                {"do": "walk", "who": 2, "to": UNDER, "arrive": 0.8, "max": 20},
                {"do": "look", "who": 1, "at": NOTE_LOOK}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "wait", "s": 6.0}],
         "expect": [{"name": "his note read: hold the lever, head-butt the legs",
                     "expr": "boot.story.notes.size() > 0 and String(boot.story.notes[boot.story.notes.size() - 1]['text']).contains('Head-butt')", "within": 2}]},
        {"name": "2.3 P1 holds the lever: the fan winds up", "max": 40,
         "do": [{"do": "look", "who": 1, "at": LEVER_LOOK}, {"do": "wait", "s": 0.3}, {"do": "down", "key": "E"},
                {"do": "look", "who": 2, "at": at(0.0, 18.0, -3.4)}, {"do": "wait", "s": 6.0}],
         "expect": [{"name": "winding up", "expr": "%s.lever_held and %s.power > 0.1" % (WM, WM), "within": 3}]},
        {"name": "2.4 the mistake: a leg slides and nobody butts it - it falls on P2", "max": 60,
         "do": [{"do": "until", "expr": "%s.sliding_leg() >= 0" % WM, "max": 20},
                {"do": "call", "fn": "wm_face_sliding", "args": ["p2"]},
                {"do": "until", "expr": "%s.falling" % WM, "max": 12},
                {"do": "up", "key": "E"},
                {"do": "until", "expr": "p2().whiteout > 0.9", "max": 8},
                {"do": "until", "expr": "not %s.falling" % WM, "max": 8}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "it stands again, still; both back by the gate",
                     "expr": "not %s.falling and %s.power == 0.0 and p2().whiteout == 0.0" % (WM, WM), "within": 3}]},
        {"name": "2.5 again: P1 holds the lever, P2 butts every leg back", "max": 150,
         "do": [{"do": "walk", "who": 1, "to": LEVER_STAND, "arrive": 0.5, "max": 20},
                {"do": "walk", "who": 2, "to": UNDER, "arrive": 0.8, "max": 40},
                {"do": "look", "who": 1, "at": LEVER_LOOK}, {"do": "wait", "s": 0.3}, {"do": "down", "key": "E"},
                {"do": "until", "expr": "%s.lever_held" % WM, "max": 3},
                {"do": "call", "fn": "wm_guard_legs", "args": [120]},
                {"do": "up", "key": "E"}, {"do": "look", "who": 1, "at": GATE_LOOK}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "it catches the wind: the gate open, the lamps lit",
                     "expr": "%s.caught and boot.story.flags.has('windmill_power')" % WM, "within": 3}]},
        {"name": "2.6 the ladder unrolls; P2 climbs to the walkway", "max": 60,
         "do": [{"do": "until", "expr": "%s.ladder_down" % WM, "max": 10}, {"do": "wait", "s": 2.0},
                {"do": "walk", "who": 2, "to": LADDER_STAND, "arrive": 0.4, "max": 30},
                {"do": "look", "who": 2, "at": LADDER_LOOK}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": -1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 20},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "on the walkway", "expr": "p2().global_position.y > %s.global_position.y + 22.0 and p2().is_on_floor()" % WM, "within": 2}]},
        {"name": "2.7 the view, the chest, the napin", "max": 60,
         "do": [{"do": "walk", "who": 2, "to": TOP_LOOKOUT, "arrive": 0.4, "max": 10},
                {"do": "look", "who": 2, "at": VIEW_LOOK}, {"do": "wait", "s": 4.0},
                {"do": "walk", "who": 2, "to": CHEST_STAND, "arrive": 0.4, "max": 10},
                {"do": "look", "who": 2, "at": CHEST_LOOK}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "wait", "s": 1.2}, {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "the napin taken; the valley on the map",
                     "expr": "%s.napin_taken and boot.map_state.napin and wm_valley_known()" % WM, "within": 2}]},
        {"name": "2.8 P2 comes down and pins the napin on Last Fuel", "max": 60,
         "do": [{"do": "walk", "who": 2, "to": TOP_LADDER, "arrive": 0.35, "max": 10},
                {"do": "look", "who": 2, "at": TOP_LADDER_LOOK}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": 1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 20},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5},
                {"do": "walk", "who": 2, "to": at(4.0, 0.2, -10.0), "arrive": 0.6, "max": 20},
                {"do": "pad_tap", "btn": "DOWN"}, {"do": "wait", "s": 1.0},
                {"do": "call", "fn": "map_cursor_to", "args": ["p2", "gas_station"]}, {"do": "wait", "s": 1.0},
                {"do": "pad_tap", "btn": "A"}, {"do": "wait", "s": 2.0}, {"do": "pad_tap", "btn": "DOWN"}],
         "expect": [{"name": "the napin on Last Fuel", "expr": "boot.map_state.stamps.size() == 1", "within": 2}]},
        {"name": "2.9 the fun: P1 takes the map off P2, P2 head-butts P1", "max": 60,
         "do": [{"do": "walk", "who": 1, "to": at(2.5, 0.2, -17.0), "arrive": 0.6, "max": 10},
                {"do": "walk", "who": 1, "to": "expr:p2().global_position + (p1().global_position - p2().global_position).normalized() * 1.6", "arrive": 0.4, "max": 30},
                {"do": "look", "who": 1, "at": "expr:p2().head.global_position"}, {"do": "wait", "s": 0.4},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.0},
                {"do": "look", "who": 2, "at": "expr:p1().head.global_position"}, {"do": "wait", "s": 0.3},
                {"do": "pad_tap", "btn": "RB"}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "P1 has the map; P2 butted P1", "expr": "boot.map_state.holder == 0", "within": 2}]},
        {"name": "2.10 back in the van, through the gate - and P2 pushes the driver out", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": VAN_DOOR_L, "arrive": 0.5, "max": 40},
                {"do": "look", "who": 1, "at": VAN_SEAT_LOOK_L}, {"do": "tap", "key": "E"},
                {"do": "call", "fn": "round_van", "args": ["p2", 1.0, True]},
                {"do": "walk", "who": 2, "to": VAN_DOOR_R, "arrive": 0.5, "max": 40},
                {"do": "look", "who": 2, "at": VAN_SEAT_LOOK_R}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p1().seat != null and p2().seat != null", "max": 3},
                {"do": "tap", "key": "Space"},
                {"do": "down", "key": "W"},
                {"do": "until", "expr": "boot.camper.linear_velocity.length() > 8.0", "max": 8},
                {"do": "pad_hold", "btn": "RB", "s": 0.8}, {"do": "up", "key": "W"}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "P1 tumbles out on the road past the gate; the van rolls on", "expr": "p1().seat == null and wm_van_short_of_gate() == false", "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "puzzle2.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
