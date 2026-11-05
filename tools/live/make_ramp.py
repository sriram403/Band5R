"""The ramp jump (design/PUZZLE_CHANGES.md #5, "The ramp jump: as built") as a
planned walk for the recorded walkthrough: python tools/live/make_ramp.py ->
tools/live/ramp.json. P1 on the keyboard, driving; P2 on the pad, stood at the
gap to watch each try (a cut, so the video shows the jump from outside: in a
real game P2 sits in the van, or watches and swims over after).
Shows: the note on the post; a try at 48 km/h into the river, the fade, back at
the run-up; flat out, the bang, the wheel through the shutter, the can off the
rack; the hub; the bolted door; a leg-up alone falls short, crate + leg-up in;
the bench, the tiffin, the bolt; the wheel out by the door; refused without
nuts; the toolbox; jack, wheel, jack down, and away."""
import json
import os

R = "rj()"
HUT = "%s.hut" % R
W = "ramp_ws()"


def wait(s):
    return {"do": "wait", "s": s}


def at(x, z, y=0.0):
    return "expr:%s.global_transform * Vector3(%s, %s, %s)" % (R, x, y, z)


def hut(x, z, y=0.1):
    return "expr:%s.global_transform * Vector3(%s, %s, %s)" % (HUT, x, y, z)


def hut_w(x, z, y=0.1):
    """x measured out from the shuttered wall's side of the hut."""
    return "expr:%s.global_transform * Vector3(%s * %s, %s, %s)" % (HUT, W, x, y, z)


def look(who, to, s=0.4):
    return [{"do": "look", "who": who, "at": to}, wait(s)]


def walk(who, to, arrive=0.4, mx=30):
    return {"do": "walk", "who": who, "to": to, "arrive": arrive, "max": mx}


def place(who, to):
    return {"do": "call", "fn": "place_player", "args": ["p%d" % who, to, 0.0]}


def pad_x():
    return {"do": "pad_tap", "btn": "X"}


LIP = at(0, 0, 0.8)
FAR_WATCH = at(-3.9, "-%s.gap_len - 7.0" % R, 0.6)
NEAR_WATCH = at(-3.7, 2.5, 0.6)
OVER_GAP = at(0, "-%s.gap_len * 0.5" % R, -1.5)
UNDER = hut_w(2.0, 0.0)
SHUTTER = hut_w(1.8, 0.0, 3.0)
BEHIND = hut_w(3.05, 0.0)
CRATE = "expr:%s.find_child('HutCrate', true, false).global_position" % HUT
HUB = "expr:camper().global_transform * Vector3(-1.55, -0.37, -1.95)"
HUB_STAND = "expr:camper().global_transform * Vector3(-2.9, 0.0, -1.95)"
WHEEL = "expr:%s.van_wheel.global_position" % R
SIDE = "expr:camper().global_transform.basis.x * -1.0"
BOX = "expr:%s.find_child('ToolboxArea', true, false).global_position" % HUT
TIFFIN = "expr:%s.find_child('TiffinArea', true, false).global_position" % HUT
DOOR = "expr:%s.find_child('HutDoorArea', true, false).global_position" % HUT

steps = [
    {"name": "1 F1 Puzzles: the ramp jump: in the van at the run-up", "max": 25,
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The ramp jump"}, wait(2.0)],
     "expect": [{"name": "the van at the run-up, not jumped",
                 "expr": "camper().global_position.distance_to(%s.van_start.origin) < 6.0 and not %s.jumped" % (R, R), "within": 3}]},
    {"name": "2 out at the ramp (a cut): the ramp from the road, Naresh's note", "max": 45,
     "do": [{"do": "tap", "key": "E"}, wait(0.6), pad_x(), wait(0.6),
            place(1, at(3.8, 12.5, 0.5)), place(2, at(-1.0, 13.0, 0.5))]
            + look(2, LIP, 2.0) + look(1, at(3.8, 7.0, 1.2), 0.5)
            + [walk(1, at(3.8, 7.8, 0.3), 0.3, 8)] + look(1, at(3.8, 7.06, 1.2), 0.5)
            + [{"do": "tap", "key": "E"}, wait(4.0), {"do": "tap", "key": "E"}, wait(0.5)],
     "expect": []},
    {"name": "3 from the ramp's top: the gap, the rusted car in the river, the far hut", "max": 30,
     "do": [place(1, at(0, 1.0, 1.3))] + look(1, at(0, "-%s.gap_len" % R, -1.0), 2.0)
            + look(1, "expr:%s.get_node('RiverWreck/WreckCar').global_position" % R, 2.5)
            + look(1, "expr:%s.global_position + Vector3(0, 2.5, 0)" % HUT, 2.0),
     "expect": []},
    {"name": "4 too slow (P2 watching from the near deck): 48 km/h, into the river", "max": 70,
     "do": [{"do": "call", "fn": "ramp_start"}, place(2, NEAR_WATCH)] + look(2, OVER_GAP, 0.3)
            + [{"do": "spawn", "fn": "ramp_try", "args": [48.0]},
               {"do": "until", "expr": "%s.misses > 0" % R, "max": 30}, wait(6.0)],
     "expect": [{"name": "back at the run-up, nothing lost",
                 "expr": "camper().global_position.distance_to(%s.van_start.origin) < 5.0 and not camper().wheel_off and not %s.jumped and p1().seat != null" % (R, R), "within": 4}]},
    {"name": "5 flat out (P2 on the far bank): the jump, the bang, the wheel through the shutter", "max": 60,
     "do": [{"do": "call", "fn": "ramp_film_can"},
            place(2, FAR_WATCH)] + look(2, LIP, 0.3)
            + [{"do": "spawn", "fn": "ramp_try", "args": [80.0]},
               {"do": "until", "expr": "%s.jumped" % R, "max": 30}]
            + look(2, "expr:%s.global_position + Vector3(0, 2.5, 0)" % HUT, 3.5)
            + [{"do": "hold", "key": "S", "s": 2.5}, {"do": "tap", "key": "SPACE"}, wait(1.5)],
     "expect": [{"name": "the wheel off and in the hut", "expr": "camper().wheel_off and %s.shutter_broken and %s.van_wheel != null" % (R, R), "within": 3},
                {"name": "the story asks for it back", "expr": "boot.story.current()['id'] == 'wheel'", "within": 2}]},
    {"name": "6 out: the van on its hub; the shutter; the door's bolted", "max": 70,
     "do": [{"do": "tap", "key": "E"}, wait(1.0), place(1, HUB_STAND)] + look(1, "expr:camper()._wheels[0].global_position", 3.0)
            + [place(1, hut(0, -3.3, 0.5))] + look(1, DOOR, 0.5)
            + [{"do": "tap", "key": "E"}, wait(2.0), place(2, hut_w(6.0, 0.0, 0.5))] + look(2, SHUTTER, 3.0),
     "expect": [{"name": "still bolted", "expr": "not %s.door_open" % R, "within": 2}]},
    {"name": "7 a leg-up alone falls short of the shutter", "max": 30,
     "do": [place(1, UNDER)] + look(1, SHUTTER, 0.2) + [{"do": "down", "key": "CTRL"}, place(2, BEHIND)] + look(2, SHUTTER, 0.8)
            + [{"do": "pad_axis", "axis": "LY", "v": -1.0}, {"do": "pad_tap", "btn": "A"}, wait(1.5),
               {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "up", "key": "CTRL"}, wait(1.0)],
     "expect": [{"name": "still outside", "expr": "not %s.in_hut(p2())" % R, "within": 2}]},
    {"name": "8 the crate under the shutter, P1 crouched on it, P2 up and in", "max": 60,
     "do": [place(1, "expr:%s.find_child('HutCrate', true, false).global_position + (%s.find_child('HutCrate', true, false).global_position - (%s)).normalized() * 1.0 + Vector3(0, 0.4, 0)" % (HUT, HUT, UNDER[5:]))]
            + look(1, CRATE, 0.4) + [{"do": "tap", "key": "E"}, wait(0.6),
               walk(1, "expr:(%s) + (%s.global_transform.basis.x * %s).normalized() * 1.1" % (UNDER[5:], HUT, W), 0.3, 10)]
            + look(1, UNDER, 0.2) + [{"do": "tap", "key": "E"}, wait(1.0),
               place(1, "expr:%s.find_child('HutCrate', true, false).global_position + Vector3(0, 0.9, 0)" % HUT)]
            + look(1, SHUTTER, 0.5) + [{"do": "down", "key": "CTRL"}, place(2, BEHIND)] + look(2, SHUTTER, 0.8)
            + [{"do": "pad_axis", "axis": "LY", "v": -1.0}, {"do": "pad_tap", "btn": "A"},
               {"do": "until", "expr": "%s.in_hut(p2())" % R, "max": 4}, wait(0.8),
               {"do": "pad_axis", "axis": "LY", "v": 0.0}, {"do": "up", "key": "CTRL"}, wait(1.0)],
     "expect": [{"name": "P2 is in the hut", "expr": "%s.in_hut(p2())" % R, "within": 2}]},
    {"name": "9 inside: the wheel, the tiffin, the note; the bolt", "max": 60,
     "do": look(2, WHEEL, 2.0) + [walk(2, hut(0, 0.2), 0.3, 6)] + look(2, TIFFIN, 0.5) + [pad_x(), wait(4.0)]
            + [walk(2, hut(0, -0.7), 0.3, 6)] + look(2, DOOR, 0.4) + [pad_x(), wait(1.5)],
     "expect": [{"name": "the door's open", "expr": "%s.door_open" % R, "within": 2}]},
    {"name": "10 P1 in by the door, takes the wheel, carries it out (no nuts yet)", "max": 90,
     "do": [{"do": "call", "fn": "place_player", "args": ["p1", hut(0, -4.0, 0.5), 0.0]},
            walk(1, hut(0, 0.0), 0.5, 10)] + look(1, WHEEL, 0.5) + [{"do": "tap", "key": "E"}, wait(0.6),
            walk(1, hut(0, -3.2), 0.5, 12), place(1, "expr:camper().global_transform * Vector3(-3.3, 0.3, -1.95)")]
            + look(1, HUB, 0.6) + [{"do": "tap", "key": "E"}, wait(1.2)],
     "expect": [{"name": "the wheel's in the hub's way, put down", "expr": "p1().held == null", "within": 2}]},
    {"name": "11 the jack; the wheel to the hub: it says the nuts sheared", "max": 40,
     "do": [{"do": "eval", "expr": "%s.van_wheel.set('global_position', camper().global_transform * Vector3(-3.3, 0.7, -2.95))" % R},
            {"do": "eval", "expr": "%s.van_wheel.set('linear_velocity', Vector3.ZERO)" % R}, wait(0.5),
            {"do": "call", "fn": "face_point", "args": ["p1", HUB, 1.8, SIDE]}, wait(0.5), {"do": "tap", "key": "E"}, wait(1.0),
            {"do": "call", "fn": "face_point", "args": ["p1", WHEEL, 1.5]}, wait(0.4), {"do": "tap", "key": "E"}, wait(0.6),
            {"do": "call", "fn": "face_point", "args": ["p1", HUB, 1.8, SIDE]}, wait(3.0)],
     "expect": [{"name": "it says so", "expr": "p1().prompt_text.contains('sheared')", "within": 3}]},
    {"name": "12 P2 opens the toolbox: new nuts, a can, a jug", "max": 30,
     "do": [walk(2, hut(0, 0.2), 0.3, 6)] + look(2, BOX, 0.6) + [pad_x(), wait(4.0)],
     "expect": [{"name": "the nuts found", "expr": "camper().nuts_found", "within": 2}]},
    {"name": "13 the wheel on, the jack down, and away", "max": 70,
     "do": [{"do": "call", "fn": "face_point", "args": ["p1", HUB, 1.8, SIDE]}, wait(0.4), {"do": "hold", "key": "E", "s": 6.6}, wait(0.8), {"do": "tap", "key": "E"}, wait(1.5),
            {"do": "call", "fn": "seat_p1_driver"}, {"do": "call", "fn": "ramp_drive_off"}, wait(1.0)],
     "expect": [{"name": "the wheel is back on, the story moves on", "expr": "not camper().wheel_off and boot.story.current()['id'] != 'wheel'", "within": 3}]},
]
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, "ramp.json"), "w", encoding="utf-8") as f:
    json.dump({"name": "ramp", "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}], "steps": steps}, f, indent=1)
print("tools/live/ramp.json: %d steps" % len(steps))
