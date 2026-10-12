"""Puzzle 3, the barn maze, round 2 (notes/TEST_PUZZLES.md #3,
design/PUZZLE_CHANGES.md #3 "Round 2") as a planned walk for the watched run
and the recorded walkthrough: python tools/live/make_puzzle3.py ->
tools/live/puzzle3.json. P1 on the keyboard walks the maze with the flag;
P2 on the pad guides from the silo, then (when the snow whites it out) takes
the van round the track to the back gate. Real walking, keys and pad: a pit
fall, a wrong turn and its scare, the snow, the bell, the doors (one-way, a
fake), a distraction, running (the music box, a corner fright, the stumble),
a spin, the chest, the spare on the van, and the push from the moving van."""
import json
import os

M = "mz()"


def barn(x, y, z):
    """A point in the barn's frame (+Z towards the road)."""
    return "expr:mz_at(%s, %s, %s)" % (x, y, z)


def van(x, y, z):
    return "expr:boot.camper.global_transform * Vector3(%s, %s, %s)" % (x, y, z)


def way(i):
    return "expr:%s" % i


GATE_FRONT = barn(17.4, 0.2, -9.4)
GATE_NOTE = "expr:mz().find_child('NareshNote_maze_gate', true, false).global_position"
RACK = "expr:mz().find_child('FlagRack', true, false).global_position + Vector3(0, 1.0, 0)"
RACK_STAND = barn(20.0, 0.2, -10.2)
SILO_STAND = barn(11.0, 0.2, -5.25)
SILO_RUNGS = barn(11.0, 1.6, -4.68)
SKETCH = "expr:mz().get_parent().find_child('MazeSketch', true, false).global_position"
SILO_NOTE = "expr:mz().get_parent().find_child('NareshNote_maze_silo', true, false).global_position"
MAZE_MID = "expr:mz().global_position + Vector3(0, 1.0, 0)"
LANTERN = "expr:mz().find_child('ChestLantern', true, false).global_position"
WINDSOCK = "expr:mz().find_child('ExitWindsock', true, false).global_position + Vector3(0, 4, 0)"
BELL = "expr:mz().find_child('FarmBell', true, false).global_position + Vector3(0, 1.2, 0)"
CHEST = "expr:mz().find_child('FeedChest', true, false).global_position + Vector3(0, 0.5, 0)"
PUSH_NOTE = "expr:mz().find_child('NareshNote_maze_push', true, false).global_position"
BACK_GATE = "expr:mz().find_child('BackGate', true, false).global_transform * Vector3(0.3, 1.0, -1.5)"
SPARE = "expr:boot.world.find_child('MazeSpare', true, false).global_position"
OUT_BACK = "expr:mz().global_transform * mz().back_spot()"
FIRST_DOOR = "expr:mz().way.find(mz().doors[0].cell_back) + 1"

walk = {
    "name": "puzzle3",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}, {"do": "eval", "expr": "boot.map_state.set('holder', 1)"}],
    "steps": [
        {"name": "3.0 F1 Puzzles: the barn maze",
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The barn maze"}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "fresh: the chest shut, both on foot by the van in the yard",
                     "expr": "not %s.chest_open and p1().seat == null and p2().seat == null and boot.camper.global_position.distance_to(boot.builder.poi['barn_yard']) < 4.0" % M, "within": 3}]},
        {"name": "3.1 round the barn: P1 reads Naresh's note at the way in, P2 to the silo", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": barn(9.0, 0.2, 27.5), "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": barn(15.5, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 1, "to": GATE_FRONT, "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": GATE_NOTE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "walk", "who": 2, "to": barn(9.0, 0.2, 28.5), "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, -5.4), "arrive": 0.6, "max": 30},
                {"do": "walk", "who": 2, "to": SILO_STAND, "arrive": 0.35, "max": 20}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "his note read: the holes, the silo, the flag", "expr": "last_note_has('silo')", "within": 2}]},
        {"name": "3.2 P2 climbs the silo (13 m)", "max": 40,
         "do": [{"do": "look", "who": 2, "at": SILO_RUNGS}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": -1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 15},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "on the silo's deck", "expr": "p2().global_position.y > %s.global_position.y + 12.5 and p2().is_on_floor()" % M, "within": 2}]},
        {"name": "3.3 up top: the maze, the chest's lantern, the exit's windsock, the sketch, his note (the van run)", "max": 50,
         "do": [{"do": "look", "who": 2, "at": MAZE_MID}, {"do": "wait", "s": 2.5},
                {"do": "look", "who": 2, "at": LANTERN}, {"do": "wait", "s": 2.5},
                {"do": "look", "who": 2, "at": WINDSOCK}, {"do": "wait", "s": 2.0},
                {"do": "look", "who": 2, "at": SKETCH}, {"do": "wait", "s": 3.0},
                {"do": "look", "who": 2, "at": SILO_NOTE}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "his note: learn the back half; when it whites out, the van to the back gate",
                     "expr": "last_note_has('back gate')", "within": 2}]},
        {"name": "3.4 P1 takes a flag", "max": 20,
         "do": [{"do": "walk", "who": 1, "to": RACK_STAND, "arrive": 0.4, "max": 10},
                {"do": "look", "who": 1, "at": RACK}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.5},
                {"do": "spawn", "fn": "mz_guide_watch"}],
         "expect": [{"name": "P1 carries a flag", "expr": "%s.has_flag(p1())" % M, "within": 2}]},
        {"name": "3.5 the mistake: P1 walks onto a pit and drops through", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": GATE_FRONT, "arrive": 0.6, "max": 10},
                {"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_pit_index() - 1"]},
                {"do": "call", "fn": "mz_step_on_pit", "args": ["p1"]}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "out of the drain by the front gate, straw on the view",
                     "expr": "%s.falls == 1 and p1().global_position.distance_to(boot.builder.poi['maze_gate']) < 4.0" % M, "within": 2}]},
        {"name": "3.6 again, and a wrong turn: walking back out, something pops out of the hedge", "max": 150,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_detour()[1]"]},
                {"do": "call", "fn": "mz_take_detour", "args": ["p1"]}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "the scare popped", "expr": "%s.scares_fired >= 1" % M, "within": 2}]},
        {"name": "3.7 on to the courtyard: the snow comes; P1 rings the bell", "max": 150,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz_detour()[1]", "expr:mz_centre_index()"]},
                {"do": "until", "expr": "%s.snowing" % M, "max": 5},
                {"do": "look", "who": 1, "at": BELL}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "wait", "s": 10.0}],
         "expect": [{"name": "heavy snow: the guide sees nothing below",
                     "expr": "%s.snowing and get_tree().get_first_node_in_group('weather').heavy > 0.8" % M, "within": 3}]},
        {"name": "3.8 the silo is useless now: P2 climbs down and gets in the van", "max": 120,
         "do": [{"do": "eval", "expr": "set('mz_watching', false)"},
                {"do": "look", "who": 2, "at": SILO_RUNGS}, {"do": "walk", "who": 2, "to": barn(11.0, 13.4, -3.3), "arrive": 0.35, "max": 10},
                {"do": "look", "who": 2, "at": barn(11.0, 13.6, -4.7)}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().ladder != null", "max": 2},
                {"do": "pad_axis", "axis": "LY", "v": 1.0},
                {"do": "until", "expr": "p2().ladder == null", "max": 15},
                {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "wait", "s": 0.5},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, -5.6), "arrive": 0.7, "max": 15},
                {"do": "walk", "who": 2, "to": barn(15.0, 0.2, 9.0), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 2, "to": barn(9.0, 0.2, 28.5), "arrive": 0.8, "max": 30},
                {"do": "walk", "who": 2, "to": van(-2.3, 0.2, -1.2), "arrive": 0.5, "max": 20},
                {"do": "look", "who": 2, "at": van(-0.9, 1.4, -1.2)}, {"do": "pad_tap", "btn": "X"},
                {"do": "until", "expr": "p2().seat != null", "max": 3},
                {"do": "pad_tap", "btn": "UP"}, {"do": "wait", "s": 1.5}],
         "expect": [{"name": "P2 at the wheel, the engine on", "expr": "p2().seat_role == 'driver' and boot.camper.engine_on", "within": 2}]},
        {"name": "3.9 P2 drives the track round to the back gate; P1 on in the snow: the doors, a distraction", "max": 200,
         "do": [{"do": "spawn", "fn": "mz_pad_drive", "args": [False, 15.0]},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz_centre_index()", "expr:mz().way.find(mz().doors[0].cell_front) - 1"]},
                {"do": "call", "fn": "mz_fake_detour", "args": ["p1"]},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", FIRST_DOOR]},
                {"do": "call", "fn": "mz_distraction", "args": ["p1"]}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "through a one-way door (shut behind), a fake door opened, a fright",
                     "expr": "mz().doors[0].locked and mz().frights.fired >= 1", "within": 3}]},
        {"name": "3.10 P1 runs (the music box swells), a fright at a corner, the flag dropped; a spin", "max": 150,
         "do": [{"do": "eval", "expr": "set('mz_sprint', true)"},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 7"]},
                {"do": "eval", "expr": "set('mz_sprint', false)"},
                {"do": "call", "fn": "mz_spin", "args": ["p1"]}],
         "expect": [{"name": "a few frights so far", "expr": "mz().frights.fired >= 2", "within": 2}]},
        {"name": "3.11 on to the chest from memory; P2 waits at the gate and honks", "max": 200,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz().way.find(mz().doors[1].cell_back) + 1"]},
                {"do": "call", "fn": "mz_fake_detour", "args": ["p1"]},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz().way.size() - 1"]},
                {"do": "until", "expr": "mz_drive_done", "max": 60},
                {"do": "pad_tap", "btn": "L3"}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "at the chest, the snow stops; the van at the back gate",
                     "expr": "%s.cell_at(p1().global_position) == %s.goal and not %s.snowing and boot.camper.global_position.distance_to(%s) < 8.0 and fake_opened()" % (M, M, M, OUT_BACK[5:]), "within": 3}]},
        {"name": "3.12 the chest: a spare, fuel, coolant, and the note in the lid: the push", "max": 40,
         "do": [{"do": "look", "who": 1, "at": CHEST}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "look", "who": 1, "at": PUSH_NOTE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "the chest open, the push learned", "expr": "%s.chest_open and boot.story.flags.has('push')" % M, "within": 2}]},
        {"name": "3.13 out of the back gate: the van's right there; the spare on its mount", "max": 90,
         "do": [{"do": "look", "who": 1, "at": BACK_GATE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.5},
                {"do": "call", "fn": "mz_take_spare", "args": ["p1"]},
                {"do": "walk", "who": 1, "to": OUT_BACK, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": van(0.0, 0.2, 4.4), "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": van(0.0, 2.05, 3.25)}, {"do": "wait", "s": 0.3}, {"do": "hold", "key": "E", "s": 2.6}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "the spare's on the back of the van", "expr": "boot.camper.spare_available and boot.world.find_child('MazeSpare', true, false) == null", "within": 3}]},
        {"name": "3.14 P1 jumps in; P2 drives off - and P1 shoves the driver out", "max": 60,
         "do": [{"do": "walk", "who": 1, "to": van(2.9, 0.2, 4.6), "arrive": 0.7, "max": 15},
                {"do": "walk", "who": 1, "to": van(2.3, 0.2, -1.2), "arrive": 0.5, "max": 15},
                {"do": "look", "who": 1, "at": van(0.9, 1.4, -1.2)}, {"do": "tap", "key": "E"},
                {"do": "until", "expr": "p1().seat != null", "max": 3},
                {"do": "pad_axis", "axis": "RT", "v": 1.0},
                {"do": "until", "expr": "boot.camper.linear_velocity.length() > 6.5", "max": 10},
                {"do": "tap", "key": "G"}, {"do": "pad_axis", "axis": "RT", "v": 0.0}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "P2 tumbles out of the moving van", "expr": "p2().seat == null and p1().seat != null", "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "puzzle3.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
