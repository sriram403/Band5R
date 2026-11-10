"""#6, the ghat (design/PUZZLE_CHANGES.md #6, agreed 2026-11-09) as a planned
walk for the recorded walkthrough: python tools/live/make_ghat.py ->
tools/live/ghat.json; record: tools/record_walk.sh ghat.
P1 on the keyboard drives; P2 on the pad reads the pace notes.
Shows: the fog and the pace notes; Naresh's note on the milestone; Problem
watching from the trees on hairpin 1 (its head follows the van, its eyes
brighten); the needle climbing, the engine dying in the fog; both out, the old
shade net over the van, one corner each; inside, it comes, goes round the van,
leans in at the windows (each holds their breath), crouches and sniffs at the
back; it gives up, slumps, turns away; P1 opens the radiator cap too soon:
WHOOSH, and it comes back; hide again; P2 walks down to the spring with the
steel pot, twice; the hiss stops, the water goes in; on over the pass; the
marks it left on the van; the end credits' turn round the van.
Cuts (declared): the walk to the net's corners and the doors (place_player),
the end credits called directly."""
import json
import os


def wait(s):
    return {"do": "wait", "s": s}


def look(who, to, s=0.4):
    return [{"do": "look", "who": who, "at": to}, wait(s)]


def walk(who, to, arrive=0.6, mx=40):
    return {"do": "walk", "who": who, "to": to, "arrive": arrive, "max": mx}


def call(fn, *args):
    return {"do": "call", "fn": fn, "args": list(args)}


def until(expr, mx):
    return {"do": "until", "expr": expr, "max": mx}


def pad(btn, s=None):
    return {"do": "pad_hold", "btn": btn, "s": s} if s else {"do": "pad_tap", "btn": btn}


def both_out():
    return [{"do": "tap", "key": "E"}, wait(0.5), pad("X"), wait(0.8)]


def net_on():
    return [call("_to_tarp_corner", "p1", "expr:camper()", -1.0), {"do": "hold", "key": "E", "s": 2.2},
            call("_to_tarp_corner", "p2", "expr:camper()", 1.0), pad("X", 2.6), wait(0.2)]


def net_off():
    return [call("_to_tarp_corner", "p1", "expr:camper()", -1.0), {"do": "hold", "key": "E", "s": 2.6}, wait(0.4)]


def both_in():
    return [call("_to_door", "p1", "expr:camper()", "driver"), {"do": "tap", "key": "E"}, wait(0.2),
            call("_to_door", "p2", "expr:camper()", "passenger"), pad("X"), wait(0.5)]


def trip(n):
    return {"name": "%d P2 down the road to the spring: the pot, filled at the pipe, back to the van" % n, "max": 120,
            "do": [walk(2, "expr:pot_stand()", 0.7, 50)] + look(2, "expr:pot_at() + Vector3(0, 0.15, 0)", 0.4)
                  + [pad("X"), wait(0.6)] + [walk(2, "expr:pipe_stand()", 0.5, 10)] + look(2, "expr:pipe_at()", 0.3)
                  + [pad("X", 5.8), wait(0.3), walk(2, "expr:van_side(-1.2, -5.6)", 0.8, 50)],
            "expect": [{"name": "P2 holds a full pot", "expr": "p2().held != null and p2().held.litres > 2.3", "within": 110}]}


def refill(n):
    return {"name": "%d not full yet: P2 back down to the spring with the pot, fills it again" % n, "max": 120,
            "do": [walk(2, "expr:pipe_stand()", 0.5, 50)] + look(2, "expr:pipe_at()", 0.3)
                  + [pad("X", 5.8), wait(0.3), walk(2, "expr:van_side(-1.2, -5.6)", 0.8, 50)],
            "expect": [{"name": "P2 holds a full pot", "expr": "p2().held != null and p2().held.litres > 2.3", "within": 110}]}


def pour(n):
    return {"name": "%d P2 pours the water into the radiator" % n, "max": 30,
            "do": look(2, "expr:bonnet_at()", 0.4) + [pad("X", 1.8), wait(0.5)],     # 2.5 L pours in ~1.6 s; X held on an empty pot drops it
            "expect": [{"name": "the water went in", "expr": "camper().coolant > 0.3", "within": 25}]}


steps = [
    {"name": "1 F1 Puzzles: the ghat: both in the van at the foot of the hairpins", "max": 25,
     "do": [{"do": "menu", "tab": "Puzzles", "row": "The ghat pace notes"}, wait(2.0)],
     "expect": [{"name": "both in, no Problem yet", "expr": "p1().seat != null and p2().seat != null and gh().phase == ''", "within": 4}]},
    {"name": "2 P2 swings the nav to read the pace notes; the engine on", "max": 15,
     "do": [pad("A"), wait(1.0), {"do": "hold", "key": "X", "s": 0.3}, wait(1.0)],
     "expect": [{"name": "nav swung, engine on", "expr": "camper().nav_aside and camper().engine_on", "within": 6}]},
    {"name": "3 up the hill into the fog, stop at the old milestone", "max": 100,
     "do": [{"do": "drive", "road": "ghat_road", "to": "poi:ghat_milestone", "kmh": 30, "max": 90},
            {"do": "hold", "key": "X", "s": 0.3}, wait(0.5)],     # (the drive ends parked: S or SPACE here released the handbrake)
     "expect": [{"name": "stopped by the milestone, parked", "expr": "camper().global_position.distance_to(boot.builder.poi['ghat_milestone']) < 18.0 and camper().parking_brake", "within": 95}]},
    {"name": "4 P1 out: Naresh's note on the milestone", "max": 40,
     "do": [{"do": "tap", "key": "E"}, wait(0.6), walk(1, "expr:note_stand()", 0.4, 20)] + look(1, "expr:note_at()", 0.5)
           + [{"do": "tap", "key": "E"}, wait(7.0)],
     "expect": [{"name": "the note read", "expr": "note_read('ghat_heat')", "within": 35}]},
    {"name": "5 back in, on up the hairpins", "max": 30,
     "do": [walk(1, "expr:van_side(-2.6, -1.8)", 0.6, 20)] + look(1, "expr:van_side(-1.2, -1.8, 1.4)", 0.3)
           + [{"do": "tap", "key": "E"}, wait(0.8), {"do": "hold", "key": "X", "s": 0.3}, wait(0.8)],
     "expect": [{"name": "P1 driving again", "expr": "p1().seat_role == 'driver' and camper().engine_on", "within": 25}]},
    {"name": "6 hairpin 1: something tall in the trees turns its head to follow the van; the needle climbs; the engine dies in the fog", "max": 120,
     "do": [{"do": "drive", "road": "ghat_road", "until": "gh().phase == 'watch'", "kmh": 28, "max": 60}]
           + [{"do": "look", "who": 2, "at": "expr:gh().problem.eye_point()"}]
           + [{"do": "drive", "road": "ghat_road", "until": "camper().boiled_dry", "kmh": 30, "max": 60},
              wait(1.0)],     # (Problem reaches a stopped van ~27 s after it stops: no dawdling) the drive ends parked; a SPACE here let the van roll back down the ghat (dry run 2026-11-10)
     "expect": [{"name": "seen, boiled dry, parked", "expr": "gh().seen_index > 0 and camper().boiled_dry and camper().linear_velocity.length() < 0.5 and camper().parking_brake", "within": 115}]},
    {"name": "7 both out: the old shade net over the van, one corner each", "max": 40,
     "do": both_out() + net_on(),
     "expect": [{"name": "the van under the net", "expr": "camper().attack.tarped", "within": 35}]},
    {"name": "8 both back in, keep still", "max": 30,
     "do": both_in(),
     "expect": [{"name": "both hidden inside", "expr": "p1().seat_role == 'driver' and p2().seat_role == 'passenger'", "within": 25}]},
    {"name": "9 it comes out of the fog, goes round the van, leans in at the windows (hold your breath), sniffs at the back, and gives up", "max": 200,
     "do": [{"do": "spawn", "fn": "walk_breath_bot", "args": [190.0]}, until("gh().phase == 'leave'", 190), wait(4.0)],
     "expect": [{"name": "it gave up, nothing given away", "expr": "gh().phase == 'leave' and gh().breath_events == 0", "within": 195}]},
    {"name": "10 out, net off; P1 opens the radiator cap while it still hisses: WHOOSH, and it hears", "max": 40,
     "do": both_out() + net_off() + [call("place_player", "p1", "expr:bonnet_stand()", 0.0)] + look(1, "expr:bonnet_at()", 0.4)
           + [{"do": "tap", "key": "E"}, wait(3.0)],
     "expect": [{"name": "the cap blew, it's coming back", "expr": "camper().cap_blows == 1 and camper().attack.interested()", "within": 35}]},
    {"name": "11 net on again, in, hide well", "max": 60,
     "do": net_on() + both_in(),
     "expect": [{"name": "hidden again", "expr": "camper().attack.tarped and p1().seat != null and p2().seat != null", "within": 55}]},
    {"name": "12 it searches again, and gives up again", "max": 200,
     "do": [{"do": "spawn", "fn": "walk_breath_bot", "args": [190.0]}, until("gh().phase == 'leave'", 190), wait(4.0)],
     "expect": [{"name": "it gave up again", "expr": "gh().phase == 'leave'", "within": 195}]},
    {"name": "13 out, net off; P1 waits by the bonnet for the hissing to stop", "max": 30,
     "do": both_out() + net_off() + [call("place_player", "p1", "expr:bonnet_stand()", 0.0)] + look(1, "expr:bonnet_at()", 0.4),
     "expect": [{"name": "net off", "expr": "not camper().attack.tarped", "within": 25}]},
    trip(14),
    {"name": "15 the hissing stops", "max": 130,
     "do": [until("camper().temp <= 104.0", 125)],
     "expect": [{"name": "cool enough", "expr": "camper().temp <= 104.0", "within": 128}]},
    pour(16),
    refill(17),
    pour(18),
    {"name": "19 the radiator full again: in, start up, on over the pass", "max": 90,
     "do": [{"do": "call", "fn": "place_player", "args": ["p2", "expr:van_side(2.9, -1.8)", 0.0]}, wait(0.3)]
           + both_in()[0:3] + [{"do": "call", "fn": "_to_door", "args": ["p2", "expr:camper()", "passenger"]}, pad("X"), wait(0.8),
                              {"do": "hold", "key": "X", "s": 0.3}, wait(0.8),
                              {"do": "drive", "road": "ghat_road", "kmh": 30, "max": 60}],
     "expect": [{"name": "over the pass, running", "expr": "boot.story.current()['id'] == 'to_tower' and camper().engine_on", "within": 85}]},
    {"name": "20 stopped past the pass: the marks it left on the van", "max": 40,
     "do": [{"do": "tap", "key": "E"}, wait(0.6),
            call("place_player", "p1", "expr:van_side(-2.7, -1.6)", 0.0)] + look(1, "expr:van_side(-1.15, -1.8, 1.85)", 3.0)
           + [call("place_player", "p1", "expr:van_side(-0.8, -5.8)", 0.0)] + look(1, "expr:van_side(0, -3.3, 1.66)", 3.0)
           + [call("place_player", "p1", "expr:van_side(0.6, 5.8)", 0.0)] + look(1, "expr:van_side(0, 3.0, 1.3)", 3.0),
     "expect": [{"name": "the marks are on the van", "expr": "camper().marks.size() >= 5", "within": 35}]},
    {"name": "21 the end credits: a slow turn round the battered van", "max": 30,
     "do": [call("show_credits"), wait(18.0)],
     "expect": []},
]

# P2 on the pad (split screen), as the ramp's walk: without it the walk played
# solo on one keyboard and P2's pad presses went nowhere (take 1, 2026-11-10)
walk_def = {"name": "ghat", "setup": [{"do": "eval", "expr": "boot._on_joy_changed(0, true)"}], "steps": steps}
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ghat.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk_def, f, indent=1)
print(out, len(steps), "steps")
