"""The F6 sheet (notes/TEST_MILESTONE_F.md, the old rail tunnel) as a planned
walk for the watched run: python tools/live/make_f6.py -> tools/live/f6.json.

The plan (real walking and keys / pad; the old t_tunnel placed players by
code and switched the gallery's creature off):
- P2 (pad) crosses the gallery: in by door 0 once the creature walks away
  (towards door 1), torch off and crouched (B held); at fork 1 a look with
  the torch (Y) at the arrow; into fork 1's side passage to let it pass
  back; on to fork 2's dead end for the flare gun; fire one (RB): it runs
  and keeps away 90 s; the winch (hold X) holds the gate up.
- P1 (keyboard, Naresh with him) drives the van under the gate.
- P2 out by the far door. Then the push start on a real slope past the
  tunnel: a flat battery (F1 -> Van row), click; roll it, X: it catches.
"""
import json
import os

RT = "tunnel()"
JUMP = {"do": "menu", "tab": "Story", "row": "A flood gate is down"}
CK = "gallery_creature_k()"
CD = "gallery_creature_dir()"


def p2(to, arrive=0.8, mx=60):
    return {"do": "walk", "who": 2, "to": to, "arrive": arrive, "max": mx}


walk = {
    "name": "f6",
    "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
    "steps": [
        {"name": "F6.0 jump", "do": [JUMP],
         "expect": [{"name": "in the tunnel, the gate down ahead",
                     "expr": "boot.story.current()['id'] == 'tunnel' and %s.gate.global_position.y < %s.road.point(%s.gate_i).y + 0.2" % (RT, RT, RT), "within": 3}]},
        {"name": "F6.1 dark: the torch",
         "do": [{"do": "tap", "key": "F"}, {"do": "wait", "s": 0.4}],
         "expect": [{"name": "P1's torch on", "expr": "p1().flashlight.visible", "within": 1}]},
        {"name": "F6.2 into the gallery (P2)", "max": 200,
         "do": [{"do": "tap", "key": "F"},                      # P1's torch off again
                p2("expr:gallery_door(0, false)", 1.0, 40),
                # in once it walks away from this end
                {"do": "until", "expr": "%s > 0 and %s > 2.0" % (CD, CK), "max": 120},
                {"do": "pad_down", "btn": "B"},                # crouch: it hears footsteps
                p2("expr:gallery_door(0, true)", 0.8, 20),
                p2("expr:gallery_at(-15)", 0.8, 60),
                {"do": "pad_tap", "btn": "Y"}, {"do": "wait", "s": 1.0}, {"do": "pad_tap", "btn": "Y"}],
         "expect": [{"name": "P2 at fork 1, torch off again", "expr": "p2().global_position.distance_to(gallery_at(-15)) < 2.0 and not p2().flashlight.visible", "within": 2}]},
        {"name": "F6.2 let it pass (fork 1's passage)", "max": 200,
         "do": [p2("expr:gallery_fork(1, 7.0)", 0.8, 30),
                # it comes back towards door 0 and passes the fork's mouth
                {"do": "until", "expr": "%s < 0 and %s < -18.0" % (CD, CK), "max": 150},
                p2("expr:gallery_at(-15)", 0.8, 30)],
         "expect": [{"name": "it walked by: not seen", "expr": "%s.watcher.state == 0" % RT, "within": 1}]},
        {"name": "F6.3 the flare gun", "max": 150,
         "do": [p2("expr:gallery_at(15)", 0.8, 80),
                # to the dead end; the torch on to find it (the sheet: seen only
                # by torchlight); 6.5 m in left it 2.2 m off, out of reach
                p2("expr:gallery_fork(2, 7.3)", 0.5, 30),
                {"do": "pad_tap", "btn": "Y"},
                {"do": "look", "who": 2, "at": "expr:%s.gun.global_position" % RT}, {"do": "wait", "s": 0.3},
                {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 0.3},
                {"do": "pad_tap", "btn": "Y"}],
         "expect": [{"name": "P2 has the flare gun", "expr": "p2().held == %s.gun" % RT, "within": 2}]},
        {"name": "F6.3 fire a flare",
         "do": [p2("expr:gallery_at(15)", 0.8, 30),
                {"do": "look", "who": 2, "at": "expr:gallery_at(0) + Vector3(0, 1, 0)"},
                {"do": "pad_tap", "btn": "RB"}, {"do": "wait", "s": 1.0}],
         "expect": [{"name": "it runs, 2 flares left", "expr": "%s.watcher.scared_t > 0.0 and %s.gun.flares_left() == 2" % (RT, RT), "within": 2}]},
        {"name": "F6.4 the winch (P2) and the van under the gate (P1)", "max": 150,
         "do": [p2("expr:%s.winch.stand_point()" % RT, 0.6, 40),
                {"do": "look", "who": 2, "at": "expr:%s.winch.global_position" % RT},
                {"do": "pad_down", "btn": "X"},
                {"do": "until", "expr": "%s.gate.global_position.y > %s.road.point(%s.gate_i).y + 3.0" % (RT, RT, RT), "max": 8},
                {"do": "call", "fn": "walk_in_driver", "args": ["p1"]},
                {"do": "until", "expr": "boot.naresh.state == 5", "max": 25},
                {"do": "call", "fn": "engine_on"},
                {"do": "drive", "road": "tunnel", "to": "expr:%s.road.point(%s.gate_i + 20)" % (RT, RT),
                 "until": "boot.story.flags.has('gate_through')", "kmh": 20, "max": 40},
                {"do": "pad_up", "btn": "X"}],
         "expect": [{"name": "the van under the gate and on", "expr": "boot.story.flags.has('gate_through')", "within": 2},
                    {"name": "on to the radio mast", "expr": "boot.story.current()['id'] == 'end_f6'", "within": 3}]},
        {"name": "F6.4 P2 out by the far door", "max": 120,
         "do": [p2("expr:gallery_at(28)", 0.8, 60), p2("expr:gallery_door(1, true)", 0.8, 20),
                p2("expr:gallery_door(1, false)", 1.0, 20), {"do": "pad_up", "btn": "B"},
                {"do": "call", "fn": "pad_in_passenger", "args": ["p2"]}],
         "expect": [{"name": "P2 in the van", "expr": "p2().seat != null", "within": 2}]},
        {"name": "F6.5 the push start", "max": 150,
         # to the top of a real slope past the tunnel (6 m down over 40 samples)
         "do": [{"do": "drive", "road": "tunnel", "to": "expr:%s.road.point(downhill_index(%s.road, %s.run.y + 12, 40, 6.0))" % (RT, RT, RT),
                 "until": "false", "kmh": 30, "max": 90},
                {"do": "tap", "key": "X"}, {"do": "wait", "s": 0.5},       # engine off
                {"do": "menu", "tab": "Van", "row": "Flatten the battery"},
                {"do": "tap", "key": "X"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "a flat battery: click, click", "expr": "not boot.camper.engine_on and boot.camper.battery < 0.05", "within": 1}]},
        {"name": "F6.5 roll it, X", "max": 60,
         "do": [{"do": "tap", "key": "SPACE"},                           # handbrake off: it rolls
                {"do": "until", "expr": "boot.camper.linear_velocity.length() * 3.6 > 11.0", "max": 30},
                {"do": "tap", "key": "X"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "rolling over 10 km/h: it bump-starts", "expr": "boot.camper.engine_on", "within": 1}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "f6.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
