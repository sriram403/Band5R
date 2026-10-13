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
         "expect": [{"name": "his note: draw the rest in as they find it, or fetch the van",
                     "expr": "last_note_has('Draw the rest')", "within": 2}]},
        {"name": "3.4 P1 takes both flags: one up, one spare on the back", "max": 25,
         "do": [{"do": "walk", "who": 1, "to": RACK_STAND, "arrive": 0.4, "max": 10},
                {"do": "look", "who": 1, "at": RACK}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "look", "who": 1, "at": RACK}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "spawn", "fn": "mz_guide_watch"}],
         "expect": [{"name": "two flags, the rack empty", "expr": "mz().flag_count(p1()) == 2 and mz().rack_left == 0", "within": 2}]},
        {"name": "3.5 the mistake: P1 walks onto a pit and drops through", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": GATE_FRONT, "arrive": 0.6, "max": 10},
                {"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_pit_index() - 1"]},
                {"do": "call", "fn": "mz_step_on_pit", "args": ["p1"]}, {"do": "wait", "s": 4.0}],
         "expect": [{"name": "out of the drain by the front gate, straw on the view",
                     "expr": "%s.falls == 1 and p1().global_position.distance_to(boot.builder.poi['maze_gate']) < 4.0" % M, "within": 2}]},
        {"name": "3.6 again, and a wrong turn: walking back out of it, something pops out of the hedge", "max": 150,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", 0, "expr:mz_detour()[1]"]},
                {"do": "call", "fn": "mz_take_detour", "args": ["p1"]}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "the scare popped (back over the same ground)", "expr": "%s.scares_fired >= 1" % M, "within": 2}]},
        {"name": "3.7 a hidden gap in the brambles: crouch through - the flag snags, the spare goes up", "max": 120,
         "do": [{"do": "call", "fn": "mz_gap_detour", "args": ["p1"]}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "one flag left stuck in the gap, the spare up", "expr": "mz().snagged == 1 and mz().flag_count(p1()) == 1", "within": 2}]},
        {"name": "3.8 an old marker flag in the maze: two again", "max": 120,
         "do": [{"do": "call", "fn": "mz_marker_detour", "args": ["p1"]}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "two flags again", "expr": "mz().flag_count(p1()) == 2", "within": 2}]},
        {"name": "3.9 on to the courtyard: the snow comes; P1 rings the bell; the silo still sees", "max": 200,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz_centre_index()"]},
                {"do": "until", "expr": "%s.snowing" % M, "max": 5},
                {"do": "look", "who": 1, "at": BELL}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"},
                {"do": "wait", "s": 10.0}],
         "expect": [{"name": "a blizzard in the maze, the silo still sees it",
                     "expr": "%s.snowing and get_tree().get_first_node_in_group('mood').env_of(p1()).fog_depth_end < 25.0 and get_tree().get_first_node_in_group('mood').env_of(p2()).fog_depth_end > 60.0" % M, "within": 3}]},
        {"name": "3.10 P1 on in the snow, past a fake door; P2 at the plan: draws in what P1 found, pencils a cross", "max": 200,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz_centre_index()", "expr:mz().way.find(mz().doors[0].cell_front) - 1"]},
                {"do": "call", "fn": "mz_fake_detour", "args": ["p1"]},
                {"do": "eval", "expr": "set('mz_watching', false)"},
                {"do": "look", "who": 2, "at": SKETCH}, {"do": "wait", "s": 0.3}, {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 1.5},
                {"do": "pad_hold", "btn": "X", "s": 3.4}, {"do": "wait", "s": 2.0},
                {"do": "eval", "expr": "p2().maze_plan.set('cursor', mz().plan_uv(mz().cell_pos(mz().doors[0].cell_back)))"},
                {"do": "pad_tap", "btn": "A"}, {"do": "wait", "s": 3.0},
                {"do": "pad_tap", "btn": "DOWN"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "the plan drawn in, a cross on it", "expr": "mz().pending.size() == 0 and mz().crosses.size() == 1 and fake_opened()", "within": 2}]},
        {"name": "3.11 P2 decides to fetch the van: down the silo, into the driver's seat", "max": 120,
         "do": [{"do": "look", "who": 2, "at": SILO_RUNGS}, {"do": "walk", "who": 2, "to": barn(11.0, 13.4, -3.4), "arrive": 0.35, "max": 10},
                {"do": "look", "who": 2, "at": barn(11.0, 13.6, -4.7)}, {"do": "wait", "s": 0.4}, {"do": "pad_tap", "btn": "X"},
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
        {"name": "3.12 P2 drives round to the back gate; P1 through a one-way door, then goes round in circles: the music box, frights", "max": 200,
         "do": [{"do": "spawn", "fn": "mz_pad_drive", "args": [False, 15.0]},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", FIRST_DOOR]},
                {"do": "call", "fn": "mz_get_lost", "args": ["p1"]},
                {"do": "call", "fn": "mz_spin", "args": ["p1"]},
                {"do": "call", "fn": "mz_get_lost", "args": ["p1"]}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "the one-way shut behind; lost, a fright or two", "expr": "mz().doors[0].locked and mz().frights.fired >= 1", "within": 3}]},
        {"name": "3.13 on to the chest; P2 waits at the gate and honks", "max": 200,
         "do": [{"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz().way.find(mz().doors[1].cell_back) + 1"]},
                {"do": "call", "fn": "mz_fake_detour", "args": ["p1"]},
                {"do": "call", "fn": "mz_walk", "args": ["p1", "expr:mz().way.find(mz().cell_at(p1().global_position)) + 1", "expr:mz().way.size() - 1"]},
                {"do": "until", "expr": "mz_drive_done", "max": 60},
                {"do": "pad_tap", "btn": "L3"}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "at the chest, the snow stops; the van at the back gate",
                     "expr": "%s.cell_at(p1().global_position) == %s.goal and not %s.snowing and boot.camper.global_position.distance_to(%s) < 8.0 and fake_opened()" % (M, M, M, OUT_BACK[5:]), "within": 3}]},
        {"name": "3.14 the chest: a spare, fuel, coolant, and the note in the lid: the push", "max": 40,
         "do": [{"do": "look", "who": 1, "at": CHEST}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "look", "who": 1, "at": PUSH_NOTE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 5.0}],
         "expect": [{"name": "the chest open, the push learned", "expr": "%s.chest_open and boot.story.flags.has('push')" % M, "within": 2}]},
        {"name": "3.15 out of the back gate: the van's right there; the spare on its mount", "max": 90,
         "do": [{"do": "look", "who": 1, "at": BACK_GATE}, {"do": "wait", "s": 0.3}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 1.5},
                {"do": "call", "fn": "mz_take_spare", "args": ["p1"]},
                {"do": "walk", "who": 1, "to": OUT_BACK, "arrive": 0.8, "max": 20},
                {"do": "walk", "who": 1, "to": van(3.0, 0.2, 4.9), "arrive": 0.7, "max": 20},
                {"do": "walk", "who": 1, "to": van(0.0, 0.2, 4.4), "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": van(0.0, 2.05, 3.25)}, {"do": "wait", "s": 0.3}, {"do": "hold", "key": "E", "s": 2.6}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "the spare's on the back of the van", "expr": "boot.camper.spare_available and boot.world.find_child('MazeSpare', true, false) == null", "within": 3}]},
        {"name": "3.16 P1 jumps in; P2 drives off - and P1 shoves the driver out", "max": 60,
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
