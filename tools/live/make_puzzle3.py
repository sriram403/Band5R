"""Puzzle 3, the barn maze (notes/TEST_PUZZLES.md #3, the G rework in
design/PUZZLE_CHANGES.md #3) as a planned walk for the watched run and the
recorded walkthrough: python tools/live/make_puzzle3.py ->
tools/live/puzzle3.json. P1 on the keyboard walks the maze with the flag;
P2 on the pad guides from the silo. Real walking, real keys and pad: a pit
fall, a wrong turn with a jump scare, the snow from the middle, the bell, the
chest, the spare on the van, and the push from the moving van."""
import json
import os

M = "mz()"


def barn(x, y, z):
    """A point in the barn's frame (+Z towards the road)."""
    return "expr:mz_at(%s, %s, %s)" % (x, y, z)


def van(x, y, z):
    return "expr:boot.camper.global_transform * Vector3(%s, %s, %s)" % (x, y, z)


GATE_FRONT = barn(17.4, 0.2, -9.4)
GATE_NOTE = "expr:mz().find_child('NareshNote_maze_gate', true, false).global_position"
RACK = "expr:mz().find_child('FlagRack', true, false).global_position + Vector3(0, 1.0, 0)"
RACK_STAND = barn(20.0, 0.2, -8.2)
SILO_STAND = barn(11.0, 0.2, -5.25)
SILO_RUNGS = barn(11.0, 1.6, -4.68)
SKETCH = "expr:mz().get_parent().find_child('MazeSketch', true, false).global_position"
SILO_NOTE = "expr:mz().get_parent().find_child('NareshNote_maze_silo', true, false).global_position"
MAZE_MID = "expr:mz().global_position + Vector3(0, 1.0, 0)"
BELL = "expr:mz().find_child('FarmBell', true, false).global_position + Vector3(0, 1.2, 0)"
CHEST = "expr:mz().find_child('FeedChest', true, false).global_position + Vector3(0, 0.5, 0)"
PUSH_NOTE = "expr:mz().find_child('NareshNote_maze_push', true, false).global_position"
BACK_GATE = "expr:mz().find_child('BackGate', true, false).global_transform * Vector3(0.3, 1.0, -1.5)"
SPARE = "expr:boot.world.find_child('MazeSpare', true, false).global_position"
OUT_BACK = "expr:mz().global_transform * mz().back_spot()"

walk = {
    "name": "puzzle3",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}, {"do": "eval", "expr": "boot.map_state.set('holder', 1)"}],
    "steps": [
        {"name": "3.0 F1 Puzzles: the barn maze",
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The barn maze"}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "fresh: the chest shut, both on foot by the van in the yard",
                     "expr": "not %s.chest_open and p1().seat == null and p2().seat == null and boot.camper.global_position.distance_to(boot.builder.poi['barn_yard']) < 4.0" % M, "within": 3}]},
        {"name": "3.1 round the barn: P1 reads Naresh's note at the way in, P2 to the silo", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": barn(15.5, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 1, "to": GATE_FRONT, "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": GATE_NOTE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, -5.4), "arrive": 0.6, "max": 30},
                {"do": "walk", "who": 2, "to": SILO_STAND, "arrive": 0.35, "max": 20}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "his note read: the holes, the silo, the flag",
                     "expr": "last_note_has('silo')", "within": 2}]},
        {"name": "3.2 P2 climbs the silo (13 m)", "max": 40,
         "do": [{"do": "look", "who": 2, "at": SILO_RUNGS}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": -1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 15},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "on the silo's deck", "expr": "p2().global_position.y > %s.global_position.y + 12.5 and p2().is_on_floor()" % M, "within": 2}]},
        {"name": "3.3 up top: the maze below, Naresh's sketch, his note", "max": 40,
         "do": [{"do": "look", "who": 2, "at": MAZE_MID}, {"do": "wait", "s": 3.0},
                {"do": "look", "who": 2, "at": SKETCH}, {"do": "wait", "s": 4.0},
                {"do": "look", "who": 2, "at": SILO_NOTE}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "his note: learn the back half before the snow",
                     "expr": "last_note_has('snows')", "within": 2}]},
        {"name": "3.4 P1 takes a flag", "max": 20,
         "do": [{"do": "walk", "who": 1, "to": RACK_STAND, "arrive": 0.4, "max": 10},
                {"do": "look", "who": 1, "at": RACK}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "spawn", "fn": "mz_guide_watch"}],
         "expect": [{"name": "P1 carries a flag", "expr": "%s.has_flag(p1())" % M, "within": 2}]},
        {"name": "3.5 the mistake: P1 walks onto a pit and drops through", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": GATE_FRONT, "arrive": 0.6, "max": 10},
                {"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_pit_index() - 1"]},
                {"do": "call", "fn": "mz_step_on_pit", "args": ["p1"]}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "out of the drain by the front gate, straw on the view",
                     "expr": "%s.falls == 1 and p1().global_position.distance_to(boot.builder.poi['maze_gate']) < 4.0" % M, "within": 2}]},
        {"name": "3.6 again, and a wrong turn: walking back out, something pops out of the hedge", "max": 120,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_detour()[1]"]},
                {"do": "call", "fn": "mz_take_detour", "args": ["p1"]}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "the scare popped", "expr": "%s.scares_fired >= 1" % M, "within": 2}]},
        {"name": "3.7 on to the courtyard: the snow comes; P1 rings the bell", "max": 120,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz_detour()[1]", "expr:mz_centre_index()"]},
                {"do": "until", "expr": "%s.snowing" % M, "max": 5},
                {"do": "look", "who": 1, "at": BELL}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "wait", "s": 10.0}],
         "expect": [{"name": "heavy snow: white close in, the guide sees nothing below",
                     "expr": "%s.snowing and get_tree().get_first_node_in_group('weather').heavy > 0.8" % M, "within": 3}]},
        {"name": "3.8 the back half in the snow, from the guide's memory", "max": 150,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz_centre_index()", "expr:mz().way.size() - 1"]}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "at the chest; the snow stops", "expr": "%s.cell_at(p1().global_position) == %s.goal and not %s.snowing" % (M, M, M), "within": 3}]},
        {"name": "3.9 the feed chest: a spare tyre, fuel, coolant - and Naresh's note: the push", "max": 40,
         "do": [{"do": "look", "who": 1, "at": CHEST}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.5},
                {"do": "look", "who": 1, "at": PUSH_NOTE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 6.0}],
         "expect": [{"name": "the chest open, the push learned",
                     "expr": "%s.chest_open and boot.story.flags.has('push')" % M, "within": 2}]},
        {"name": "3.10 it clears: the sun on the snowy hedges", "max": 30,
         "do": [{"do": "eval", "expr": "set('mz_watching', false)"}, {"do": "look", "who": 2, "at": MAZE_MID},
                {"do": "look", "who": 1, "at": "expr:p1().global_position + Vector3(0, 25, 0) - mz().global_transform.basis.z * 10.0"}, {"do": "wait", "s": 10.0}],
         "expect": [{"name": "a spell of sun", "expr": "get_tree().get_first_node_in_group('weather').clear_t > 100.0", "within": 2}]},
        {"name": "3.11 out of the back gate with the spare; on the van's empty mount", "max": 150,
         "do": [{"do": "look", "who": 1, "at": BACK_GATE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.5},
                {"do": "look", "who": 1, "at": SPARE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.5},
                {"do": "walk", "who": 1, "to": OUT_BACK, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": barn(-21.5, 0.2, -9.0), "arrive": 1.0, "max": 40},
                {"do": "walk", "who": 1, "to": barn(-12.0, 0.2, 9.0), "arrive": 1.0, "max": 30},
                {"do": "walk", "who": 1, "to": van(0.0, 0.2, 4.4), "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": van(0.0, 2.05, 3.25)}, {"do": "wait", "s": 0.3}, {"do": "hold", "key": "E", "s": 2.6}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "the spare's on the back of the van", "expr": "boot.camper.spare_available and boot.world.find_child('MazeSpare', true, false) == null", "within": 3}]},
        {"name": "3.12 P2 comes down; both in; P1 drives off and shoves P2 out", "max": 120,
         "do": [{"do": "look", "who": 2, "at": SILO_RUNGS}, {"do": "walk", "who": 2, "to": barn(11.0, 13.4, -3.3), "arrive": 0.35, "max": 10},
                {"do": "look", "who": 2, "at": barn(11.0, 13.6, -4.7)}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": 1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 15},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 2, "to": van(-3.0, 0.2, -5.2), "arrive": 0.7, "max": 30},
                {"do": "walk", "who": 2, "to": van(3.0, 0.2, -5.2), "arrive": 0.7, "max": 20},
                {"do": "walk", "who": 2, "to": van(2.3, 0.2, -1.2), "arrive": 0.5, "max": 30},
                {"do": "look", "who": 2, "at": van(0.9, 1.4, -1.2)}, {"do": "pad_tap", "btn": "X"},
                {"do": "walk", "who": 1, "to": van(-2.3, 0.2, -1.2), "arrive": 0.5, "max": 20},
                {"do": "look", "who": 1, "at": van(-0.9, 1.4, -1.2)}, {"do": "tap", "key": "E"},
                {"do": "until", "expr": "p1().seat != null and p2().seat != null", "max": 3},
                {"do": "tap", "key": "X"}, {"do": "wait", "s": 1.0}, {"do": "tap", "key": "Space"},
                {"do": "down", "key": "W"},
                {"do": "until", "expr": "boot.camper.linear_velocity.length() > 7.0", "max": 10},
                {"do": "tap", "key": "G"}, {"do": "up", "key": "W"}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "P2 tumbles out of the moving van", "expr": "p2().seat == null and p1().seat != null", "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "puzzle3.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
