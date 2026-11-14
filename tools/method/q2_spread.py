"""Qual round 2, item 3: the values GPT flagged, read from every archived run (no game).

Usage: python tools/method/q2_spread.py   (prints one row per run per value; 0 game min)
Values: heat fuel once it gives up (per profile), looks engine ticks + looks game length, sniffs at the
back, the looks round's stops, the closest face-to-glass gap.
"""
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RUNS = os.path.join(ROOT, "appdata", "method", "runs")
PAT = {
    "fuel": re.compile(r"^(\w[\w ]*): once it gives up the heat and the leak stop \(.*fuel ([\d.]+) -> ([\d.]+)\)"),
    "ticks": re.compile(r"the hot engine ticks.*\((?:.*), (\d+) ticks\)"),
    "sniffs": re.compile(r"at the back it crouches down and sniffs \((\d+) sniffs\)"),
    "round": re.compile(r"^it goes round the van, stopping at .*\((\d+) stops\)"),
    "glass": re.compile(r"its face stays outside the glass \(closest ([\d.]+) m\)"),
}


def info(d):
    p = os.path.join(d, "run_info.txt")
    txt = open(p, encoding="utf-8").read() if os.path.exists(p) else ""
    m = re.search(r"fixture '([^']*)' speed '([^']*)'", txt)
    fx, sp = (m.group(1), m.group(2)) if m else ("", "")
    return fx or "clean", ("fast" if "fast" in sp else "1x")


for name in sorted(os.listdir(RUNS)):
    d = os.path.join(RUNS, name)
    p = os.path.join(d, "method_events.txt")
    if not os.path.exists(p):
        continue
    ev = []
    for ln in open(p, encoding="utf-8"):
        try:
            ev.append(json.loads(ln))
        except ValueError:
            pass
    fx, sp = info(d)
    out = []
    for e in ev:
        if e.get("ev") != "CHECK":
            continue
        t = e.get("text", "")
        for k, rx in PAT.items():
            m = rx.search(t)
            if m:
                out.append("%s=%s%s" % (k, "/".join(m.groups()), "" if e.get("ok") else "(FAIL)"))
    if out:
        print("%-48s %-4s %-28s %s" % (name[:48], sp, fx[:28], " ".join(out)))
