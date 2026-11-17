"""T1 (speed research): the 1x-vs-fast differential of two method runs, per check.

Usage: python tools/method/t1_diff.py <run dir A (1x)> <run dir B (fast)> [scenario ...]
Each logged CHECK is paired with its manifest ID (method_verdict.match_checks, the same pairing
the verdict uses); repeats of a helper's check (three driving profiles) are numbered in order.
Prints one row per check: id, A verdict, B verdict, the numbers in each text, and SAME / DIFF
(verdict) plus the largest relative number gap. Then the H-rule FIREs and the RESULT lines.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from method_verdict import match_checks   # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NUM = re.compile(r"-?\d+(?:\.\d+)?")


def events(d):
    out = []
    p = os.path.join(d, "method_events.txt")
    for ln in open(p, encoding="utf-8") if os.path.exists(p) else []:
        try:
            out.append(json.loads(ln))
        except ValueError:
            pass
    return out


def checks(d, fz, scens):
    ev = events(d)
    rows = {}
    for scen in scens:
        man = fz["required"].get(scen, {}).get("checks", [])
        mine = [e for e in ev if e.get("ev") == "CHECK" and e.get("scen") == scen]
        pairs, unmatched = match_checks(mine, man)
        n = {}
        for m, c in pairs:
            k = m["id"]
            n[k] = n.get(k, 0) + 1
            rows["%s#%d" % (k, n[k]) if n[k] > 1 else k] = c
        for c in unmatched:
            rows["%s/UNMATCHED:%s" % (scen, c["text"][:40])] = c
    fires = [e for e in ev if e.get("ev") == "FIRE"]
    return rows, fires


def gap(a, b):
    na, nb = [float(x) for x in NUM.findall(a)], [float(x) for x in NUM.findall(b)]
    if len(na) != len(nb):
        return "n/a (%d vs %d numbers)" % (len(na), len(nb))
    worst = 0.0
    for x, y in zip(na, nb):
        if x != y:
            worst = max(worst, abs(x - y) / max(abs(x), abs(y), 1e-9))
    return "%.1f%%" % (worst * 100.0)


def main():
    a, b = sys.argv[1], sys.argv[2]
    fz = json.load(open(os.path.join(ROOT, "tools", "method", "frozen.json"), encoding="utf-8"))
    scens = sys.argv[3:] or sorted({e.get("scen") for e in events(b) if e.get("ev") == "CHECK"})
    ra, fa = checks(a, fz, scens)
    rb, fb = checks(b, fz, scens)
    same = diff = 0
    for k in sorted(set(ra) | set(rb), key=lambda k: (k.split("/")[0], min(
            [int(x["pf"]) for x in (ra.get(k), rb.get(k)) if x] or [0]))):
        x, y = ra.get(k), rb.get(k)
        va = ("PASS" if x["ok"] else "FAIL") if x else "-"
        vb = ("PASS" if y["ok"] else "FAIL") if y else "-"
        s = "SAME" if va == vb else "DIFF"
        same += s == "SAME"
        diff += s == "DIFF"
        g = gap(x["text"], y["text"]) if x and y else ""
        print("%-4s %-4s %-4s gap %-6s %s" % (s, va, vb, g, k))
        if x and y and x["text"] != y["text"]:
            print("            1x:   %s\n            fast: %s" % (x["text"][:150], y["text"][:150]))
        elif x or y:
            print("            %s" % (x or y)["text"][:150])
    print("checks: %d same, %d different" % (same, diff))
    for nm, f in (("1x", fa), ("fast", fb)):
        for e in f:
            print("FIRE %s: %s %s (pf %s)" % (nm, e.get("rule"), e.get("text"), e.get("pf")))
    for d in (a, b):
        v = os.path.join(d, "verdict.txt")
        print("%s: %s" % (os.path.basename(d), open(v, encoding="utf-8").readline().strip() if os.path.exists(v) else "no verdict"))


if __name__ == "__main__":
    main()
