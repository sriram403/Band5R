"""One invocation's combined RESULT (speed research T1 fix round, GPT's blocker 1).

tools/method_run.sh gives every invocation its own receipt folder appdata/method/inv/<INV>/:
  expected        one line per requested part: part<TAB>scenarios<TAB>fixture
  <part>.dir      the part's run folder (written once the folder exists)
  <part>.rc       the part's own exit (every path, refusals included)
  <part>.xrc      the exit seen from outside (split runs only)
  <part>.refused  why it never launched
A part counts only if all of these hold, else it is TEST (exit 3), never PASS:
  a run folder; its run_info names this invocation and part; a whole verdict (RESULT first line,
  the Evidence line naming that folder last); the trace asked exactly the requested scenarios with
  the requested fixture; the exits (.rc, .xrc) agree with the verdict.
Combined: PASS only when every requested part is PASS; else the worst (NOT HEALTHY > TEST > FAIL >
INCOMPLETE). No part requested, or a receipt for a part nobody requested: TEST.
Usage: combine_parts.py <inv dir>   (writes <inv dir>/combined.txt; exit = the combined code)
"""
import json
import os
import re
import sys

EXIT = {"PASS": 0, "FAIL": 1, "INCOMPLETE": 2, "TEST": 3, "NOT HEALTHY": 4}
RANK = {"NOT HEALTHY": 0, "TEST": 1, "FAIL": 2, "INCOMPLETE": 3, "PASS": 8}
NAME = {v: k for k, v in EXIT.items()}


def rd(p):
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def judge_part(invd, inv, part, scens, fixture):
    """-> (status, why, run dir or None)"""
    d = (rd(os.path.join(invd, part + ".dir")) or "").strip()
    if not d:
        ref = (rd(os.path.join(invd, part + ".refused")) or "").strip()
        if ref:
            return "TEST", "REFUSED, never launched: " + ref, None
        rc = (rd(os.path.join(invd, part + ".rc")) or rd(os.path.join(invd, part + ".xrc")) or "").strip()
        return "TEST", "MISSING: no run folder for this part (exit %s)" % (rc or "none recorded"), None
    if not os.path.isdir(d):
        return "TEST", "MISSING: its run folder %s does not exist" % d, d
    info = rd(os.path.join(d, "run_info.txt")) or ""
    if (info.splitlines() or [""])[0].strip() != "inv %s part %s" % (inv, part):
        return "TEST", "WRONG RUN: %s is not this invocation's %s part (its first line: '%s')" % (
            d, part, (info.splitlines() or ["(no run_info)"])[0][:80]), d
    v = rd(os.path.join(d, "verdict.txt"))
    if v is None:
        return "TEST", "NO VERDICT in %s" % d, d
    lines = [ln for ln in v.splitlines() if ln.strip()]
    m = re.match(r"^RESULT: (PASS|FAIL|INCOMPLETE|TEST|NOT HEALTHY) \(exit (\d)\)", lines[0] if lines else "")
    ev = lines[-1].strip() if lines else ""
    if not m or not ev.startswith("Evidence: ") or os.path.normcase(os.path.normpath(ev[10:].strip())) != os.path.normcase(os.path.normpath(d)):
        return "TEST", "TRUNCATED VERDICT in %s (first line '%s', last line '%s')" % (d, (lines[0] if lines else "")[:60], ev[:60]), d
    status, code = m.group(1), int(m.group(2))
    if EXIT[status] != code:
        return "TEST", "VERDICT says %s with exit %d" % (status, code), d
    try:
        tr = json.load(open(os.path.join(d, "trace.json"), encoding="utf-8"))
    except (OSError, ValueError):
        return "TEST", "NO / BAD TRACE in %s" % d, d
    want = [s for s in scens.split(",") if s]
    if tr.get("asked") != want:
        return "TEST", "COVERAGE: asked %s, this part was to run %s" % (tr.get("asked"), want), d
    m2 = re.search(r"fixture '([^']*)'", info)
    if not m2 or m2.group(1) != fixture:
        return "TEST", "FIXTURE: ran '%s', this part was to run '%s'" % (m2.group(1) if m2 else "?", fixture), d
    rc = (rd(os.path.join(invd, part + ".rc")) or "").strip()
    if rc != str(code):
        return "TEST", "EXIT: the part's own exit '%s' does not match its verdict (%d)" % (rc or "none", code), d
    xrc = rd(os.path.join(invd, part + ".xrc"))
    if xrc is not None and xrc.strip() != str(code):
        return "TEST", "EXIT: seen from outside '%s', verdict %d" % (xrc.strip(), code), d
    return status, lines[0], d


def combine(invd):
    inv = os.path.basename(os.path.normpath(invd))
    exp = []
    for ln in (rd(os.path.join(invd, "expected")) or "").splitlines():
        f = ln.split("\t")
        if len(f) >= 2 and f[0]:
            exp.append((f[0], f[1], f[2] if len(f) > 2 else ""))
    rows, worst = [], "PASS"
    if not exp:
        rows.append(("-", "TEST", "NOTHING REQUESTED: no expected part on record", None))
    names = [e[0] for e in exp]
    if len(set(names)) != len(names):
        rows.append(("-", "TEST", "the same part requested twice: %s" % names, None))
    for part, scens, fx in exp:
        st, why, d = judge_part(invd, inv, part, scens, fx)
        rows.append((part, st, why, d))
    for f in os.listdir(invd):
        if f.endswith(".dir") and f[:-4] not in names:
            rows.append((f[:-4], "TEST", "A PART NOBODY REQUESTED left a run folder: %s" % (rd(os.path.join(invd, f)) or "").strip(), None))
    for r in rows:
        if RANK[r[1]] < RANK[worst]:
            worst = r[1]
    out = ["COMBINED RESULT: %s (exit %d): invocation %s, %d part(s) requested (%s)" % (worst, EXIT[worst], inv, len(exp), ", ".join(names) or "none")]
    for part, st, why, d in rows:
        out.append("  %-6s %-11s %s%s" % (part, st, why, ("  [%s]" % d) if d and st != "PASS" else ""))
    return worst, out


def main():
    invd = sys.argv[1]
    worst, out = combine(invd)
    txt = "\n".join(out)
    print(txt, flush=True)
    with open(os.path.join(invd, "combined.txt"), "w", encoding="utf-8") as f:
        f.write(txt + "\n")
    print("SPEED=fast: exit %d" % EXIT[worst], flush=True)
    sys.exit(EXIT[worst])


if __name__ == "__main__":
    main()
