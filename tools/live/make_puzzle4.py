"""Puzzle 4, the lookout boards (notes/TEST_PUZZLES.md #4, reworked
2026-10-14, design/PUZZLE_CHANGES.md #4) as a planned walk for the watched
run and the recorded walkthrough: python tools/live/make_puzzle4.py ->
tools/live/puzzle4.json. P1 on the keyboard: up on the deck with the
binoculars (wheel zoom, crouch to steady), reading the six pictures. P2 on
the pad: the patrol's sheet and Naresh's note, a wrong try, snowballs at the
snowy sign, the dials, the handle. Then the fun: snowballs at P1 and the van.
Real walking and real keys / pad throughout."""
import json
import os

R = "relay()"


def look1(expr, s):
    return [{"do": "look", "who": 1, "at": expr}, {"do": "wait", "s": s}]


def read_plate(pid, s=4.0, steady=True):
    """P1 at the deck's edge nearest the picture, binoculars up at 8x."""
    out = [{"do": "mouse", "btn": "right", "down": False},
           {"do": "walk", "who": 1, "to": "expr:relay_deck_edge('%s')" % pid, "arrive": 0.35, "max": 10},
           {"do": "look", "who": 1, "at": "expr:relay_plate('%s')" % pid},
           {"do": "mouse", "btn": "right", "down": True}, {"do": "wait", "s": 0.8},
           {"do": "call", "fn": "bino_zoom_to", "args": ["p1", 8]}]
    if steady:
        out += [{"do": "down", "key": "Ctrl"}, {"do": "wait", "s": 1.2},
                {"do": "look", "who": 1, "at": "expr:relay_plate('%s')" % pid}]
    out += [{"do": "wait", "s": s}]
    if steady:
        out += [{"do": "up", "key": "Ctrl"}, {"do": "wait", "s": 0.5}]
    return out


SNOW_SPOT = "expr:lk_at(-2.6, 0.2, 4.2)"


def snowball_then(target_stand, target_look):
    """P2 makes a snowball from the old snow under the ramp, walks to a
    spot and throws it (RB) at a point."""
    return [{"do": "walk", "who": 2, "to": SNOW_SPOT, "arrive": 0.5, "max": 30},
            {"do": "look", "who": 2, "at": "expr:relay_patch(2) + Vector3(0, 0.2, 0)"}, {"do": "wait", "s": 0.3},
            {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 0.6},
            {"do": "walk", "who": 2, "to": target_stand, "arrive": 0.5, "max": 30},
            {"do": "look", "who": 2, "at": target_look}, {"do": "wait", "s": 0.6},
            {"do": "pad_tap", "btn": "RB"}, {"do": "wait", "s": 1.6}]


steps = [
    {"name": "4.0 F1 Puzzles: the lookout boards",
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The lookout boards"}, {"do": "wait", "s": 2.0}],
     "expect": [{"name": "fresh: the box shut, the old snow on the sign, both on foot",
                 "expr": "not %s.opened and %s.snow_left == 4 and p1().seat == null and p2().seat == null" % (R, R), "within": 3}]},
    {"name": "4.1 P1 walks up the ramp and takes the binoculars off the bench", "max": 60,
     "do": [{"do": "walk", "who": 1, "to": "expr:boot.builder.poi['lookout_ramp_foot']", "arrive": 0.6, "max": 30},
            {"do": "walk", "who": 1, "to": "expr:lk_at(0, 6.3, 2.0)", "arrive": 0.5, "max": 20},
            {"do": "look", "who": 1, "at": "expr:boot.builder.poi['lookout_binoculars']"}, {"do": "wait", "s": 0.4},
            {"do": "tap", "key": "E"}, {"do": "wait", "s": 3.0}],
     "expect": [{"name": "P1 has the binoculars", "expr": "p1().has_binoculars", "within": 2}]},
    {"name": "4.2 P1 reads the windmill (8x, crouched: steady) and the switch house", "max": 60,
     "do": read_plate("windmill", 4.0) + look1("expr:relay_plate('switch_house')", 4.0),
     "expect": [{"name": "zoomed to 8x", "expr": "p1().zoom_level == 8.0 and p1().zoom > 7.5", "within": 2}]},
    {"name": "4.3 the barn and the silo in the snow shower: wait for it to thin", "max": 60,
     "do": read_plate("silo", 1.0, False) + [{"do": "call", "fn": "relay_wait_thin", "args": [25]}, {"do": "wait", "s": 3.0}]
            + look1("expr:relay_plate('barn')", 4.0),
     "expect": [{"name": "still at the deck, zoomed", "expr": "p1().zoom > 7.5", "within": 2}]},
    {"name": "4.4 Last Fuel, and the far water tower (1.1 km)", "max": 60,
     "do": read_plate("last_fuel", 3.0, False) + read_plate("water_tower", 6.0)
            + [{"do": "mouse", "btn": "right", "down": False}, {"do": "wait", "s": 0.5}],
     "expect": [{"name": "binoculars lowered", "expr": "p1().zoom < 1.1", "within": 2}]},
    {"name": "4.5 P2 reads the patrol's sheet and Naresh's note on the box", "max": 60,
     "do": [{"do": "walk", "who": 2, "to": "expr:box_at(1.7, 0.2, 0)", "arrive": 0.4, "max": 30},
            {"do": "look", "who": 2, "at": "expr:%s.find_child('SheetArea', true, false).global_position" % R}, {"do": "wait", "s": 0.4},
            {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 8.0},
            {"do": "walk", "who": 2, "to": "expr:box_at(0.2, 0.2, 1.5)", "arrive": 0.4, "max": 10},
            {"do": "look", "who": 2, "at": "expr:box_at(0.2, 0.45, 0.41)"}, {"do": "wait", "s": 0.4},
            {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 6.0}],
     "expect": [{"name": "his note read", "expr": "boot.story.notes.size() > 0 and String(boot.story.notes[boot.story.notes.size() - 1]['text']).contains('Easy with two')", "within": 2}]},
    {"name": "4.6 a wrong try: P2 pulls the handle, the dials spin round", "max": 40,
     "do": [{"do": "walk", "who": 2, "to": "expr:box_at(-1.7, 0.2, 0)", "arrive": 0.4, "max": 10},
            {"do": "look", "who": 2, "at": "expr:%s.find_child('HandleArea', true, false).global_position" % R}, {"do": "wait", "s": 0.4},
            {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 1.0},
            {"do": "look", "who": 2, "at": "expr:box_at(0, 0.4, -0.3)"}, {"do": "wait", "s": 3.0}],
     "expect": [{"name": "still shut, the dials stopped", "expr": "not %s.opened and not %s._spinning" % (R, R), "within": 3}]},
    {"name": "4.7 the patrol sign: old snow frozen on, out of reach", "max": 40,
     "do": [{"do": "walk", "who": 2, "to": "expr:relay_throw_spot().lerp(%s.sign_at, 0.8)" % R, "arrive": 0.5, "max": 30},
            {"do": "look", "who": 2, "at": "expr:%s.sign_at" % R}, {"do": "wait", "s": 3.0}],
     "expect": [{"name": "it says out of reach", "expr": "p2().prompt_text.contains('out of reach') or %s.snow_left == 4" % R, "within": 2}]},
]
knock = []
for k in range(4):
    knock += snowball_then("expr:relay_throw_spot()", "expr:relay_crust(%d)" % k)
steps.append({"name": "4.8 snowballs from the old snow under the ramp knock the snow off", "max": 150,
              "do": knock + [{"do": "look", "who": 2, "at": "expr:%s.sign_at" % R}, {"do": "wait", "s": 5.0}],
              "expect": [{"name": "the sign clear: the fourth riddle", "expr": "%s.snow_left == 0" % R, "within": 2}]})
steps += [
    {"name": "4.9 P2 turns the dials to the code and pulls the handle", "max": 80,
     "do": [{"do": "walk", "who": 2, "to": "expr:box_at(0, 0.2, -1.4)", "arrive": 0.4, "max": 30},
            {"do": "call", "fn": "relay_dials_to_code", "args": ["p2"]}, {"do": "wait", "s": 1.0},
            {"do": "walk", "who": 2, "to": "expr:box_at(-1.7, 0.2, 0)", "arrive": 0.4, "max": 10},
            {"do": "look", "who": 2, "at": "expr:%s.find_child('HandleArea', true, false).global_position" % R}, {"do": "wait", "s": 0.4},
            {"do": "pad_tap", "btn": "X"}, {"do": "wait", "s": 1.0},
            {"do": "look", "who": 2, "at": "expr:box_at(0, 1.0, 0)"}, {"do": "wait", "s": 4.0}],
     "expect": [{"name": "the box open, a full can inside", "expr": "%s.opened and boot.world.find_child('RelayFuel', true, false) != null" % R, "within": 2}]},
    {"name": "4.10 the fun: P1 comes down, P2 gets them with a snowball", "max": 80,
     "do": [{"do": "walk", "who": 1, "to": "expr:lk_at(0, 6.3, 2.0)", "arrive": 0.5, "max": 10},
            {"do": "walk", "who": 1, "to": "expr:boot.builder.poi['lookout_ramp_foot'] + Vector3(0, 0, 0)", "arrive": 0.6, "max": 30}]
            # from the open side of the ramp's foot (behind the ramp, it took the snowball)
            + snowball_then("expr:boot.builder.poi['lookout_ramp_foot'] + (lk_at(-6.0, 0.2, 0) - lk_at(0, 0.2, 0))",
                            "expr:p1().head.global_position + Vector3(0, -0.3, 0)")
            + [{"do": "wait", "s": 1.0}],
     "expect": [{"name": "P1: SPLAT", "expr": "boot.huds[0]._note_text.text.contains('SPLAT')", "within": 3}]}
]

walk = {"name": "puzzle4",
        "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}],
        "steps": steps}
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, "puzzle4.json"), "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print("tools/live/puzzle4.json: %d steps" % len(steps))
