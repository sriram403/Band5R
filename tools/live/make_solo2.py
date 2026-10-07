"""Solo testing at the windmill (the user, 2026-10-07): one keyboard, no
controller. P1 holds the starter lever, TAB: P1 keeps holding (HOLDING E)
while the keyboard plays P2, who head-butts every sliding leg back (G).
python tools/live/make_solo2.py -> tools/live/solo2.json;
tools/record_walk.sh solo2"""
import json
import os

WM = "wm()"


def at(x, y, z):
    return "expr:wm_at(%s, %s, %s)" % (x, y, z)


walk = {
    "name": "solo2",
    "setup": [{"do": "eval", "expr": "boot.map_state.set('holder', 1)"}],
    "steps": [
        {"name": "S.0 F1 Puzzles: the windmill (no controller: TAB swaps)",
         "do": [{"do": "menu", "tab": "Puzzles", "row": "The windmill"}, {"do": "wait", "s": 1.5},
                {"do": "eval", "expr": "wm().rng.seed = 11"}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "P1 out of the van, the keyboard on P1",
                     "expr": "p1().seat == null and boot.kbm_owner == 0 and boot.keep_holding", "within": 3}]},
        {"name": "S.1 P1 to the lever; TAB, P2 out and under the windmill; TAB back", "max": 90,
         "do": [{"do": "walk", "who": 1, "to": at(0.0, 0.2, -19.0), "arrive": 0.5, "max": 30}, {"do": "wait", "s": 0.5},
                {"do": "tap", "key": "Tab"}, {"do": "wait", "s": 0.5}, {"do": "tap", "key": "E"}, {"do": "wait", "s": 0.8},
                {"do": "call", "fn": "wm_p2_kb_under"}, {"do": "wait", "s": 0.5},
                {"do": "tap", "key": "Tab"}, {"do": "wait", "s": 0.5}],
         "expect": [{"name": "keyboard on P1 again, P2 waiting by the legs",
                     "expr": "boot.kbm_owner == 0 and p2().global_position.distance_to(%s.global_position) < 12.0" % WM, "within": 2}]},
        {"name": "S.2 P1 holds the lever, TAB: P1 keeps holding (HOLDING E)", "max": 30,
         "do": [{"do": "look", "who": 1, "at": at(0.0, 1.5, -18.0)}, {"do": "wait", "s": 0.3},
                {"do": "down", "key": "E"}, {"do": "wait", "s": 2.0},
                {"do": "tap", "key": "Tab"}, {"do": "up", "key": "E"}, {"do": "wait", "s": 2.0}],
         "expect": [{"name": "keyboard on P2, the lever still held",
                     "expr": "boot.kbm_owner == 1 and %s.lever_held" % WM, "within": 2}]},
        {"name": "S.3 the keyboard plays P2: butting every leg back (G)", "max": 150,
         "do": [{"do": "call", "fn": "wm_guard_legs_kb", "args": [120]}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "it catches the wind with P1 held on the lever the whole time",
                     "expr": "%s.caught" % WM, "within": 3}]},
        {"name": "S.4 TAB back: P1 lets go", "max": 20,
         "do": [{"do": "tap", "key": "Tab"}, {"do": "wait", "s": 3.0}],
         "expect": [{"name": "keyboard on P1, nothing held", "expr": "boot.kbm_owner == 0 and not %s.lever_held" % WM, "within": 2}]},
    ],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "solo2.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(walk, f, indent=1)
print(out, len(walk["steps"]), "steps")
