"""The builder's host control (no game): the reducer on three synthetic traces,
one per missing-receipt case (M2 / M9), each must be named apart:
  never_started    c2_more asked, never started    -> INCOMPLETE "NOT STARTED: c2_more"
  started_no_end   c2_more started, no end         -> INCOMPLETE "stopped in c2_more at ..."
  ended_no_work    c2_more ended, its work missing -> INCOMPLETE "... required work missing: ..."
Usage: python tools/method/host_fixture.py <out dir>; exit 0 when all three hold.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import method_verdict  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def base():
    return {"plan": "c2_more", "args": "", "t_start": 1000.0, "t_end": 1100.0, "asked": ["c2_more"], "started": [], "ended": [],
            "conditions": [], "checks": [], "work": [], "attempts": [], "windows": [], "g3b": [], "rules": {}, "preflight": [],
            "kill": [], "beats": 100, "pid": 1, "last_step": "", "last_beat_step": "", "wall_s": 100}


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    fz = json.load(open(os.path.join(ROOT, "tools", "method", "frozen.json"), encoding="utf-8"))
    cases = {}
    t = base()
    cases["never_started"] = (t, "NOT STARTED: c2_more")
    t = base()
    t["started"] = [{"scen": "c2_more", "unix": 1010.0}]
    t["last_step"] = "until#41"
    cases["started_no_end"] = (t, "stopped in c2_more at until#41")
    t = base()
    t["started"] = [{"scen": "c2_more", "unix": 1010.0}]
    t["ended"] = [{"scen": "c2_more", "unix": 1060.0}]
    t["work"] = [{"id": "c2.door_walk", "ok": True, "scen": "c2_more"}]
    cases["ended_no_work"] = (t, "c2_more ended with required work missing: work:c2.slow_miss_hands_off, work:c2.f1_landed_state")
    ok_all = True
    lines = []
    for name, (tr, want) in cases.items():
        st, head, order, det = method_verdict.reduce(tr, fz)
        ok = st == "INCOMPLETE" and head is not None and head["text"].startswith(want)
        ok_all &= ok
        lines.append("%-15s %s  -> %s: %s" % (name, "OK  " if ok else "MISS", st, head["text"] if head else "-"))
    txt = "\n".join(lines)
    print(txt)
    open(os.path.join(out, "host_fixture.txt"), "w", encoding="utf-8").write(txt + "\n")
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
