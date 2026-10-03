"""The F4 sheet (notes/TEST_MILESTONE_F.md, the salt pans) as a planned walk
for the watched run: python tools/live/make_f4.py -> tools/live/f4.json, then
python tools/live.py --walk tools/live/f4.json [--from "<step>"]."""
import json
import os

SP = "get_tree().get_first_node_in_group('salt_pans')"
JUMP = {"do": "menu", "tab": "Story", "row": "Open salt flats"}
BOARD = [{"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
         {"do": "call", "fn": "pad_in_passenger", "args": ["p2"]},
         {"do": "until", "expr": "boot.naresh.state == 5", "max": 25},
         {"do": "call", "fn": "engine_on"}]

walk = {
    "name": "f4",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "F4.0 jump", "do": [JUMP],
         "expect": [{"name": "short of the pans, the watcher on its gantry",
                     "expr": "boot.story.current()['id'] == 'salt_pans' and %s.watcher.passive and not %s.seen" % (SP, SP), "within": 3}]},
        {"name": "F4.1 watch it first",
         # its gaze sweeps: four stares along the road, out to sea, back
         "do": [{"do": "wait", "s": 8}],
         "expect": [{"name": "it hasn't seen anyone watching from here", "expr": "not %s.seen" % SP, "within": 1}]},
        {"name": "F4.2 cross in dashes", "max": 240,
         "do": BOARD + [{"do": "call", "fn": "salt_careful_crossing"}],
         "expect": [{"name": "across unseen", "expr": "boot.story.flags.has('pans_crossed') and not %s.seen" % SP, "within": 2},
                    {"name": "on to the estuary bridge", "expr": "boot.story.current()['id'] == 'end_f4'", "within": 5}]},
        {"name": "F4.3 get it wrong on purpose", "max": 200,
         "do": [{"do": "tap", "key": "E"}, {"do": "wait", "s": 0.5}, JUMP, {"do": "wait", "s": 1.0}] + BOARD +
               [{"do": "drive", "road": "coast_road", "to": "expr:%s.road_end" % SP, "until": "%s.seen" % SP, "kmh": 45, "max": 90}],
         "expect": [{"name": "straight across: it sees the van", "expr": "%s.seen" % SP, "within": 2},
                    {"name": "it drops off the gantry and comes for the van",
                     "expr": "not %s.watcher.passive and %s.watcher.state == 4" % (SP, SP), "within": 5}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f4.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
