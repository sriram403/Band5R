"""The F8 sheet (notes/TEST_MILESTONE_F.md, Naresh's home, the drive home, the
end) as a planned walk for the watched run: python tools/live/make_f8.py ->
tools/live/f8.json. Real driving all the way (the old t_home put the van at
each place by code): the coast road to his house; on to the West Road; the
Tower Road to the old watchtower (up its ramp); on to P2's house for the
phones and the end screen.
"""
import json
import os

HC = "get_tree().get_first_node_in_group('homecoming')"
TOWER = "boot.world.find_child('EndTower', true, false)"
NET = "boot.builder.network"
BOARD = [{"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
         {"do": "call", "fn": "pad_in_passenger", "args": ["p2"]},
         {"do": "until", "expr": "boot.naresh.state == 5", "max": 25},
         {"do": "call", "fn": "engine_on"}]

walk = {
    "name": "f8",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "F8.0 jump", "do": [{"do": "menu", "tab": "Story", "row": "Down to the van, and take Naresh home"}],
         "expect": [{"name": "on the road to his home, him with you", "expr": "boot.story.current()['id'] == 'end_f7' and not %s._mother.visible" % HC, "within": 3}]},
        {"name": "F8.1 take him home", "max": 200,
         "do": BOARD + [{"do": "drive", "road": "coast_road", "to": "poi:naresh_home_road", "until": "false", "kmh": 30, "max": 90}],
         "expect": [{"name": "P2 got in holding the flare gun: it went on the rack", "expr": "tunnel().gun.stowed_in != null", "within": 2},
                    {"name": "his mother at the door; his sister's look; he goes in", "expr": "boot.story.flags.has('naresh_home_done')", "within": 70},
                    {"name": "no tracker (the optional things not done; nobody says so)", "expr": "not boot.story.flags.has('tracker')", "within": 1},
                    {"name": "the objective: home along the West Road", "expr": "boot.story.current()['id'] == 'drive_home'", "within": 5}]},
        {"name": "F8.3 the West Road", "max": 300,
         # the coast road's end is the West Road's start
         "do": [{"do": "call", "fn": "engine_on"},
                {"do": "drive", "road": "coast_road", "until": "false", "kmh": 40, "max": 60},
                {"do": "call", "fn": "engine_on"},
                {"do": "drive", "road": "west_road", "to": "expr:%s.road('tower_road').point(0)" % NET, "until": "false", "kmh": 60, "max": 200}],
         "expect": [{"name": "full sun on the West Road", "expr": "get_tree().get_first_node_in_group('mood').target >= 0.99", "within": 5}]},
        {"name": "F8.4 to the old watchtower", "max": 240,
         "do": [{"do": "call", "fn": "engine_on"},
                {"do": "drive", "road": "tower_road", "to": "poi:end_tower", "until": "false", "kmh": 50, "max": 150},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.5},
                # round to the ramp's foot (it runs out from the tower's back), then up it
                # lined up on the ramp's middle at its foot (64 m out: the hill falls
                # away behind the tower, probed with ray_hit), then straight up
                # it (a rough arrival cut across beside the 1.8 m ramp and
                # ended under the deck)
                {"do": "walk", "who": 1, "to": "expr:%s.transform * Vector3(0, 0, 68.0)" % TOWER, "arrive": 1.5, "max": 90},
                {"do": "walk", "who": 1, "to": "expr:%s.transform * Vector3(0, 0, 65.0)" % TOWER, "arrive": 0.4, "max": 20},
                {"do": "walk", "who": 1, "to": "expr:%s.transform * Vector3(0, 0, 20.0)" % TOWER, "arrive": 0.6, "max": 40},
                {"do": "walk", "who": 1, "to": "expr:%s.transform * Vector3(0, 0, 0)" % TOWER, "arrive": 1.5, "max": 30}],
         "expect": [{"name": "from the watchtower: a light over every place", "expr": "boot.story.flags.has('tower_view')", "within": 3}]},
        {"name": "F8.5 near home: the phones, the end", "max": 300,
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.transform * Vector3(0, 0, 68.0)" % TOWER, "arrive": 2.0, "max": 90},
                {"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
                {"do": "call", "fn": "engine_on"},
                {"do": "drive", "road": "tower_road", "until": "boot.story.flags.has('end_reached')", "kmh": 60, "max": 200}],
         "expect": [{"name": "both phones: Naresh has left his house, heading to LiveStander", "expr": "boot.story.flags.has('end_reached')", "within": 5},
                    {"name": "the end screen", "expr": "%s._end != null" % HC, "within": 15}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f8.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
