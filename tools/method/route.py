"""SPEED=fast routing of a ghat plan (tools/method_run.sh calls this; t3_controls tests it offline).
  python tools/method/route.py <scenarios, comma separated> [<fixture>]
-> two lines: "fast<TAB><scenarios>" and "1x<TAB><scenarios>" (either may be empty), in the plan's order.

Fast PASS is accepted for ghat_heat and ghat_net (T1 round 2's table). ghat_marks runs in the 1x part
with ghat_looks (F6, fix round): marks' fast PASS counted only with its looks prelude's round in the same
run, and looks stays 1x, so marks goes where looks is: the same process, after looks (the plan's order).
A fixture with free_coolant (its plant reads the wall clock): everything 1x.
FAST_OK_OVERRIDE="<scenarios, space separated>": diagnostics only (an acceptance run refuses it, F9).
"""
import os
import sys

FAST_OK = ("ghat_heat", "ghat_net")


def route(scens, fixture="", env=None):
    env = os.environ if env is None else env
    ok = env.get("FAST_OK_OVERRIDE", "").split() or list(FAST_OK)
    alls = [s for s in scens.split(",") if s]
    if "free_coolant" in fixture.split(","):
        return [], alls
    return [s for s in alls if s in ok], [s for s in alls if s not in ok]


if __name__ == "__main__":
    f, s = route(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
    print("fast\t%s\n1x\t%s" % (",".join(f), ",".join(s)))
