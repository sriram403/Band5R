"""The F5 sheet (notes/TEST_MILESTONE_F.md, the estuary swing bridge) as a
planned walk for the watched run: python tools/live/make_f5.py ->
tools/live/f5.json. Real walking and real keys / pad throughout (the old
t_swing put the players and Naresh in place by code)."""
import json
import os

SB = "get_tree().get_first_node_in_group('swing_bridge')"
OPEN = "90.0"                      # SwingBridge.OPEN_DEG (Expression knows no class names)

walk = {
    "name": "f5",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "F5.0 jump", "do": [{"do": "menu", "tab": "Story", "row": "The estuary bridge is swung open"}],
         "expect": [{"name": "at the controls, the span open, the barriers up",
                     "expr": "boot.story.current()['id'] == 'swing' and absf(%s.angle - %s) < 0.1 and %s.barriers.visible" % (SB, OPEN, SB), "within": 3}]},
        {"name": "F5.1 a crank alone",
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.crank_a.stand_point()" % SB, "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": "expr:%s.crank_a.global_position" % SB},
                {"do": "hold", "key": "E", "s": 2.0}],
         "expect": [{"name": "the brake's on: nothing moves", "expr": "%s.angle >= %s - 0.1" % (SB, OPEN), "within": 1}]},
        {"name": "F5.2 Naresh on the brake",
         "do": [{"do": "job", "who": 1, "at": "expr:%s.brake.global_position" % SB, "job": "hold"}],
         "expect": [{"name": "he holds it off", "expr": "%s.brake_off()" % SB, "within": 15}]},
        {"name": "F5.2 both crank", "max": 150,
         "do": [{"do": "walk", "who": 2, "to": "expr:%s.crank_b.stand_point()" % SB, "arrive": 0.5, "max": 40},
                {"do": "look", "who": 2, "at": "expr:%s.crank_b.global_position" % SB},
                {"do": "look", "who": 1, "at": "expr:%s.crank_a.global_position" % SB},
                {"do": "down", "key": "E"}, {"do": "pad_down", "btn": "X"},
                {"do": "until", "expr": "%s.cranks_turning() == 2" % SB, "max": 3},
                # half way he lets go to wave at a boat (once)
                {"do": "until", "expr": "boot.story.flags.has('swing_waved')", "max": 60},
                {"do": "wait", "s": 1.5}],
         "expect": [{"name": "the span comes round", "expr": "%s.angle < %s - 20.0" % (SB, OPEN), "within": 1},
                    {"name": "he let go: the brake's on again", "expr": "not %s.brake_off()" % SB, "within": 1}]},
        {"name": "F5.3 tell him again", "max": 120,
         "do": [{"do": "up", "key": "E"},
                {"do": "job", "who": 1, "at": "expr:%s.brake.global_position" % SB, "job": "hold"},
                {"do": "until", "expr": "%s.brake_off()" % SB, "max": 15},
                {"do": "look", "who": 1, "at": "expr:%s.crank_a.global_position" % SB},
                {"do": "down", "key": "E"},
                {"do": "until", "expr": "%s.locked" % SB, "max": 60},
                {"do": "up", "key": "E"}, {"do": "pad_up", "btn": "X"}],
         "expect": [{"name": "it bolts home, the barriers go", "expr": "%s.locked and not %s.barriers.visible" % (SB, SB), "within": 2},
                    {"name": "on to the rail tunnel", "expr": "boot.story.current()['id'] == 'end_f5'", "within": 3}]},
        {"name": "F5.4 drive over", "max": 150,
         "do": [{"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
                {"do": "call", "fn": "pad_in_passenger", "args": ["p2"]},
                {"do": "until", "expr": "boot.naresh.state == 5", "max": 25},
                {"do": "call", "fn": "engine_on"},
                # back up first, as a driver would: the jump leaves the van
                # 6 m off the road's middle, 25 deg askew, 20 m from the span,
                # too close to line up (the drive clipped the parapet)
                {"do": "hold", "key": "S", "s": 3.5}, {"do": "wait", "s": 1.0},
                {"do": "drive", "road": "coast_road", "to": "expr:%s.pivot + %s._fwd * 40.0" % (SB, SB),
                 "until": "boot.camper.global_position.distance_to(%s.pivot + %s._fwd * 40.0) < 8.0" % (SB, SB), "kmh": 30, "max": 60}],
         "expect": [{"name": "the van over the span",
                     "expr": "boot.camper.global_position.distance_to(%s.pivot + %s._fwd * 40.0) < 12.0 and boot.camper.global_position.y > -1.0" % (SB, SB), "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f5.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
