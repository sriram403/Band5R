"""The F3 sheet (notes/TEST_MILESTONE_F.md, the fishing village) as a planned
walk for the watched run: python tools/live/make_f3.py -> tools/live/f3.json,
then  python tools/live.py --walk tools/live/f3.json  [--from "F3.4 recall"].
Every step says what must come true and by when; the positions the next
steps rely on are planned here (found on the 2026-10-02 live walk)."""
import json
import os

JETTY_END = [1833.96, -1.4, -584.0]
EDGE_P1 = [1690, 0, -550]          # the village's edge, 149 m from the jetty end
EDGE_P2 = [1693, 0, -552]
BY_SHED = [1716, 0, -603.5]        # round the shed's west side, to the crates
SHED = "boot.builder.poi['net_shed']"
FV = "village()"


def jump_step():
    # one crate per jump, up the stairs (+x), jump again once landed
    return [{"do": "look", "who": 1, "at": "expr:p1().global_position + Vector3(20,1,0)"},
            {"do": "down", "key": "W"}, {"do": "tap", "key": "SPACE"}, {"do": "wait", "s": 0.6},
            {"do": "up", "key": "W"}, {"do": "wait", "s": 0.15}]


climb = []
for _ in range(7):
    climb += jump_step()
climb += [{"do": "look", "who": 1, "at": "expr:p1().global_position + Vector3(0,1.5,-20)"},
          {"do": "hold", "key": "W", "s": 0.8}]

walk = {
    "name": "f3",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],     # P2 on a pad, as the user plays
    "steps": [
        {"name": "F3.0 jump", "do": [{"do": "menu", "tab": "Story", "row": "Nearly out of fuel"}],
         "expect": [{"name": "at the village, fuel low", "expr": "boot.story.current()['id'] == 'village' and boot.camper.fuel < 3.0", "within": 3}]},
        {"name": "F3.2 send him out",
         "do": [{"do": "walk", "who": 1, "to": EDGE_P1, "arrive": 2, "max": 60},
                {"do": "job", "who": 1, "at": JETTY_END, "job": "go", "zoom": True},
                {"do": "walk", "who": 2, "to": EDGE_P2, "arrive": 2, "max": 60}],
         "expect": [{"name": "Naresh at the jetty end", "expr": "boot.naresh.global_position.distance_to(Vector3(1833.96, -1.4, -584.0)) < 3.0", "within": 45, "watch": True},
                    {"name": "the shed side clear", "expr": "creatures_near(%s, 25.0) == 0" % SHED, "within": 60, "watch": True}]},
        {"name": "F3.3 the key", "needs": ["the shed side clear"],
         "do": [{"do": "walk", "who": 1, "to": BY_SHED, "arrive": 1, "max": 40},
                {"do": "walk", "who": 1, "to": "poi:net_shed_crates", "arrive": 0.6, "max": 20}] + climb +
               [{"do": "look", "who": 1, "at": "poi:net_shed_key"}, {"do": "wait", "s": 0.2},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.4}],
         "expect": [{"name": "the key", "expr": "boot.story.flags.has('key_got')", "within": 2}]},
        {"name": "F3.3 the door",
         "do": [{"do": "walk", "who": 1, "to": "expr:boot.builder.poi['net_shed_door'] + Vector3(-4,0,6)", "arrive": 1, "max": 20},
                {"do": "wait", "s": 0.6},
                {"do": "walk", "who": 1, "to": "poi:net_shed_door", "arrive": 0.6, "max": 20},
                {"do": "look", "who": 1, "at": "expr:%s.door.global_position" % FV}, {"do": "wait", "s": 0.2},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "the shed open", "expr": "boot.story.flags.has('shed_open')", "within": 2}]},
        {"name": "F3.5 the heavy can",
         "do": [{"do": "walk", "who": 1, "to": "expr:%s.can_full.global_position + (%s.door.global_position - %s.can_full.global_position).normalized() * 1.2" % (FV, FV, FV), "arrive": 0.5, "max": 20},
                {"do": "look", "who": 1, "at": "expr:%s.can_full.global_position" % FV}, {"do": "wait", "s": 0.1},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.2}],
         "expect": [{"name": "P1 holds the heavy can", "expr": "p1().held == %s.can_full" % FV, "within": 1}]},
        {"name": "F3.4 recall",
         "do": [{"do": "walk", "who": 1, "to": "poi:net_shed_door", "arrive": 0.8, "max": 20},
                {"do": "until", "expr": "creature_to_naresh() < 14.0", "max": 150},
                {"do": "job", "who": 2, "at": "expr:boot.naresh.global_position + Vector3(0,1.1,0)", "zoom": True}],
         "expect": [{"name": "Naresh follows P2", "expr": "boot.naresh.leader == p2()", "within": 3},
                    {"name": "Naresh off the jetty", "expr": "boot.naresh.global_position.x < 1758.0", "within": 120, "watch": True}]},
        {"name": "F3.5 the can to the van",
         "do": [{"do": "walk", "who": 1, "to": "expr:boot.camper.global_transform * Vector3(-3.0, 0, 1.0)", "arrive": 1.0, "max": 90},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.3}],
         "expect": [{"name": "the heavy can by the van", "expr": "p1().held == null and %s.can_full.global_position.distance_to(boot.camper.global_position) < 8.0" % FV, "within": 2}]},
        {"name": "F3.5 by the shed", "needs": ["Naresh off the jetty"],
         "do": [{"do": "walk", "who": 2, "to": [1708, 0, -600], "arrive": 2, "max": 60}],
         "expect": [{"name": "'There's two!'", "expr": "%s._helped" % FV, "within": 20}]},
        {"name": "F3.5 back to the van",
         "do": [{"do": "walk", "who": 2, "to": "expr:boot.camper.global_transform * Vector3(3.0, 0, 1.0)", "arrive": 1.5, "max": 90}],
         "expect": [{"name": "his mistake: 'Done. I even checked it twice.'", "expr": "boot.story.flags.has('mistake_done') and %s.can_full.litres > 19.0" % FV, "within": 150}]},
        {"name": "F3.6 drive on north",
         "do": [{"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
                {"do": "call", "fn": "pad_in_passenger", "args": ["p2"]},
                {"do": "until", "expr": "boot.naresh.state == 5", "max": 25},
                {"do": "tap", "key": "X"}, {"do": "wait", "s": 0.5},
                {"do": "drive", "road": "coast_road", "to": [1640.0, 0, -900.0], "until": "boot.story.flags.has('stalled')", "kmh": 40, "max": 120},
                {"do": "wait", "s": 1.5}],
         "expect": [{"name": "the engine dies", "expr": "boot.story.flags.has('stalled')", "within": 2},
                    {"name": "a creature steps out", "expr": "boot.world.get_node_or_null('StallCreature') != null", "within": 3}]},
        {"name": "F3.7 pour it yourself",
         "do": [{"do": "tap", "key": "E"}, {"do": "wait", "s": 0.2},
                {"do": "walk", "who": 1, "to": "expr:boot.camper.rack_stand()", "arrive": 0.6, "max": 20},
                {"do": "look", "who": 1, "at": "expr:%s.can_full.global_position" % FV}, {"do": "wait", "s": 0.1},
                {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.2},
                {"do": "walk", "who": 1, "to": "expr:boot.camper.filler_stand()", "arrive": 0.5, "max": 20},
                {"do": "look", "who": 1, "at": "expr:boot.camper.filler_point()"},
                {"do": "hold", "key": "E", "s": 5.0}],
         "expect": [{"name": "the tank full; on to the salt pans", "expr": "boot.camper.fuel > 15.0 and boot.story.current()['id'] == 'end_f3'", "within": 4}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f3.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
