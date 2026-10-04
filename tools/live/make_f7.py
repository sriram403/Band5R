"""The F7 sheet (notes/TEST_MILESTONE_F.md, the radio mast) as a planned walk
for the watched run: python tools/live/make_f7.py -> tools/live/f7.json.

Real walking and keys / pad; the old t_mast placed players by code and put
the two creatures the generator brings to sleep. Here P2 (with the flare
gun, as after the tunnel) stands guard from the moment it runs: a creature
within 25 m, a flare (`flare_guard`, alongside the other steps).
"""
import json
import os

M = "get_tree().get_first_node_in_group('radio_mast')"
LAD = "boot.world.find_child('MastLadder', true, false)"


def crank_turn(k):
    # hold E on dish k's crank until it's on its beacon (the screen shows it);
    # let go there: it locks
    return [{"do": "walk", "who": 1, "to": "expr:%s.cranks[%d].stand_point()" % (M, k), "arrive": 0.5, "max": 30},
            {"do": "look", "who": 1, "at": "expr:%s.cranks[%d].global_position" % (M, k)},
            {"do": "call", "fn": "mast_turn", "args": ["expr:%s" % M, k]}]


walk = {
    "name": "f7",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "F7.0 jump", "do": [{"do": "menu", "tab": "Story", "row": "Point the mast's three dishes"}],
         "expect": [{"name": "at the mast's foot, the generator off", "expr": "boot.story.current()['id'] == 'mast' and not %s.running" % M, "within": 3},
                    {"name": "P2 has the flare gun (as after the tunnel)", "expr": "p2().held == tunnel().gun", "within": 2}]},
        {"name": "F7.1 the cord alone",
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.cord.stand_point()" % M, "arrive": 0.5, "max": 30},
                {"do": "look", "who": 1, "at": "expr:%s.cord.global_position" % M},
                {"do": "hold", "key": "E", "s": 3.0}],
         "expect": [{"name": "it splutters out", "expr": "not %s.running and %s.cord.has_meta('spluttered')" % (M, M), "within": 2}]},
        {"name": "F7.1 the choke held, the cord pulled",
         # P2 a little to the choke's side, away from P1 at the cord: from the
         # plain stand point P1's body was in P2's line to the choke (the
         # recorded run, 2026-10-04)
         "do": [{"do": "walk", "who": 2, "to": "expr:%s.choke.stand_point() + (%s.choke.global_position - %s.cord.global_position).normalized() * 0.6" % (M, M, M), "arrive": 0.4, "max": 30},
                {"do": "look", "who": 2, "at": "expr:%s.choke.global_position" % M},
                {"do": "pad_down", "btn": "X"},
                {"do": "wait", "s": 0.5},
                {"do": "look", "who": 1, "at": "expr:%s.cord.global_position" % M},
                {"do": "hold", "key": "E", "s": 3.0},
                {"do": "pad_up", "btn": "X"}],
         "expect": [{"name": "it roars into life, the beacons on", "expr": "%s.running and %s._beacons[0].visible" % (M, M), "within": 2},
                    {"name": "its noise brings two of them", "expr": "not %s.creatures[0].dormant" % M, "within": 2}]},
        {"name": "F7.1 P2 on guard",
         "do": [{"do": "spawn", "fn": "flare_guard", "args": [25.0, "mast_done"]}],
         "expect": []},
        {"name": "F7.2 up the ladder, tag the tunnel mouth", "max": 120,
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.global_position + %s.global_transform.basis.z * 0.9" % (LAD, LAD), "arrive": 0.4, "max": 30},
                {"do": "look", "who": 1, "at": "expr:%s.global_position + Vector3(0, 1.2, 0)" % LAD},
                {"do": "tap", "key": "E"}, {"do": "down", "key": "W"},
                {"do": "until", "expr": "p1().global_position.y > %s.foot.y + 19.5 and p1().ladder == null" % M, "max": 30},
                {"do": "up", "key": "W"}, {"do": "wait", "s": 0.4},
                {"do": "look", "who": 1, "at": "expr:%s.targets[0]" % M}, {"do": "tap", "key": "T"}, {"do": "wait", "s": 0.3}],
         "expect": [{"name": "T on the far beacon: the tunnel mouth", "expr": "tag_thing(0) == 'the tunnel mouth'", "within": 2}]},
        {"name": "F7.2 down the ladder", "max": 90,
         # to the gap in the platform's rail where the ladder comes up, then
         # onto it (only looking at it from across the platform did nothing)
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.foot + Vector3(0, 20.1, 2.0)" % M, "arrive": 0.4, "max": 15},
                {"do": "look", "who": 1, "at": "expr:%s.foot + Vector3(0, 19.6, 2.62)" % M},
                {"do": "tap", "key": "E"},
                {"do": "until", "expr": "p1().ladder != null", "max": 2},
                {"do": "down", "key": "S"},
                {"do": "until", "expr": "p1().global_position.y < %s.foot.y + 1.0 and p1().ladder == null" % M, "max": 40},
                {"do": "up", "key": "S"}],
         "expect": [{"name": "back on the ground", "expr": "p1().global_position.y < %s.foot.y + 1.0" % M, "within": 2}]},
        {"name": "F7.3 dish 1", "max": 120, "do": crank_turn(0),
         "expect": [{"name": "dish 1 locks", "expr": "%s.locked[0]" % M, "within": 2}]},
        {"name": "F7.4 Naresh on dish 2", "max": 150,
         "do": [{"do": "job", "who": 1, "at": "expr:%s.cranks[1].global_position" % M, "job": "hold"},
                {"do": "until", "expr": "%s.cranks[1].holding_now()" % M, "max": 15},
                {"do": "until", "expr": "%s._wrong == 1" % M, "max": 6},
                # the wrong way: tell him again. While he holds it the wheel
                # offers only "Let go of it" (any command counts: "Oh! The
                # OTHER way."), then "Hold" again (the old test told him in code)
                {"do": "job", "who": 1, "at": "expr:%s.cranks[1].global_position" % M, "job": "let_go"},
                {"do": "until", "expr": "%s._wrong_done" % M, "max": 6},
                {"do": "wait", "s": 1.0},
                {"do": "job", "who": 1, "at": "expr:%s.cranks[1].global_position" % M, "job": "hold"},
                {"do": "until", "expr": "%s.cranks[1].holding_now()" % M, "max": 15},
                {"do": "until", "expr": "absf(rad_to_deg(angle_difference(%s.yaw[1], %s._bearing(1)))) < 1.2" % (M, M), "max": 60},
                # on its beacon: tell him to let go
                {"do": "job", "who": 1, "at": "expr:boot.naresh.global_position + Vector3(0, 1.1, 0)", "job": "wait"},
                {"do": "wait", "s": 1.4}],
         "expect": [{"name": "he turned it the wrong way first, then round: dish 2 locks", "expr": "%s.locked[1]" % M, "within": 3}]},
        {"name": "F7.3 dish 3", "max": 120, "do": crank_turn(2),
         "expect": [{"name": "the mast hums, the clouds break", "expr": "boot.story.flags.has('mast_done')", "within": 3},
                    {"name": "on to Naresh's home", "expr": "boot.story.current()['id'] == 'end_f7'", "within": 3}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f7.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
