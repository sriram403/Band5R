"""T1 fix round: offline controls (no game) for GPT's blockers 1-3, from archived run folders.

Each control copies archived run folders into appdata/t1fix/ctl/<case>/ (the archive is never
changed), binds the copies to a made-up invocation the way method_run.sh now does (run_info's first
line `inv <id> part <part>`, the verdict's Evidence line naming the copy), breaks one thing, and runs
the real judge on it. Every case prints expected vs got; the script exits 1 if any case disagrees.
Usage: python tools/method/t1fix_controls.py [b1|b2|b3 ...]
"""
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import combine_parts  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
RUNS = os.path.join(ROOT, "appdata", "method", "runs")
CTL = os.path.join(ROOT, "appdata", "t1fix", "ctl")
FZ = json.load(open(os.path.join(HERE, "frozen.json"), encoding="utf-8"))
RESULTS = []


def rec(case, want, got, note=""):
    ok = want == got
    RESULTS.append(ok)
    print("%-4s %-46s want %-12s got %-12s %s" % ("ok" if ok else "BAD", case, want, got, note), flush=True)


def fresh(case):
    d = os.path.join(CTL, case)
    if os.path.isdir(d):
        shutil.rmtree(d)
    os.makedirs(d)
    return d


def bind(src_run, dst, inv, part, regen=False):
    """Copy an archived run folder to dst, bound to (inv, part)."""
    shutil.copytree(os.path.join(RUNS, src_run), dst, ignore=shutil.ignore_patterns("shots", "*.png", "seg_1.log"))
    info = open(os.path.join(dst, "run_info.txt"), encoding="utf-8").read()
    open(os.path.join(dst, "run_info.txt"), "w", encoding="utf-8").write("inv %s part %s\n%s" % (inv, part, info))
    tr = json.load(open(os.path.join(dst, "trace.json"), encoding="utf-8"))
    if regen:
        # the archived trace predates the fix round's ids: give FIRE conditions their rule id the way
        # method_watch now does (the text starts "<rule>: ")
        for c in tr["conditions"]:
            if c.get("kind") == "rule" and "id" not in c:
                m = re.match(r"^(H\d+|[A-Z][A-Za-z0-9_]*\d*):", c["text"])
                if m:
                    c["id"] = m.group(1)
        tr["inv"], tr["part"] = inv, part
        tr["fixture"] = re.search(r"fixture '([^']*)'", info).group(1)
        json.dump(tr, open(os.path.join(dst, "trace.json"), "w", encoding="utf-8"), indent=1)
        import method_verdict
        method_verdict.report(tr, FZ, dst)       # writes verdict.txt + verdict.json into the copy
    else:
        v = open(os.path.join(dst, "verdict.txt"), encoding="utf-8").read()
        v = re.sub(r"(?m)^  Evidence: .*$", "  Evidence: " + dst.replace("\\", "/"), v)
        open(os.path.join(dst, "verdict.txt"), "w", encoding="utf-8").write(v)
    code = re.match(r"^RESULT: [A-Z ]+ \(exit (\d)\)", open(os.path.join(dst, "verdict.txt"), encoding="utf-8").read()).group(1)
    return tr, code


def inv_dir(case, parts):
    """parts: [(part, scens, fixture, src_run or None, extra)] -> the inv folder."""
    base = fresh(case)
    inv = "ctl_" + case
    invd = os.path.join(base, inv)
    os.makedirs(invd)
    with open(os.path.join(invd, "expected"), "w", encoding="utf-8") as f:
        for p in parts:
            f.write("%s\t%s\t%s\n" % (p[0], p[1], p[2]))
    for part, scens, fx, src, extra in parts:
        if src is None:
            continue
        rd = os.path.join(base, "run_" + part)
        _, code = bind(src, rd, extra.get("inv", inv), part)
        open(os.path.join(invd, part + ".dir"), "w").write(rd.replace("\\", "/"))
        open(os.path.join(invd, part + ".rc"), "w").write(str(extra.get("rc", code)) + "\n")
        open(os.path.join(invd, part + ".xrc"), "w").write(str(extra.get("rc", code)) + "\n")
        if extra.get("truncate"):
            v = open(os.path.join(rd, "verdict.txt"), encoding="utf-8").read()
            open(os.path.join(rd, "verdict.txt"), "w", encoding="utf-8").write(v[:len(v) // 2])
    return invd


# the final run 13's two parts (archived, both PASS)
F6 = "ghat_heat,ghat_looks,ghat_net,ghat_places,ghat_jug,ghat_marks"
FAST13, X13 = "20261111_111720_ghat_k3_fast", "20261111_111741_ghat_k3_1x_laneb"


def b1():
    print("== blocker 1: a requested part can't vanish (combine_parts.py)")
    cases = [
        ("b1_clean_both_parts", "PASS", [("fast", F6, "", FAST13, {}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_first_part_missing", "TEST", [("fast", F6, "", None, {}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_second_part_missing", "TEST", [("fast", F6, "", FAST13, {}), ("1x", "ghat_spring", "", None, {})]),
        ("b1_both_missing", "TEST", [("fast", F6, "", None, {}), ("1x", "ghat_spring", "", None, {})]),
        ("b1_wrong_invocation", "TEST", [("fast", F6, "", FAST13, {"inv": "someone_else"}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_truncated_verdict", "TEST", [("fast", F6, "", FAST13, {}), ("1x", "ghat_spring", "", X13, {"truncate": True})]),
        ("b1_coverage_short", "TEST", [("fast", F6 + ",ghat_spring", "", FAST13, {}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_fixture_differs", "TEST", [("fast", F6, "overrun", FAST13, {}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_exit_disagrees", "TEST", [("fast", F6, "", FAST13, {"rc": 1}), ("1x", "ghat_spring", "", X13, {})]),
        ("b1_nothing_requested", "TEST", []),
    ]
    for case, want, parts in cases:
        invd = inv_dir(case, parts)
        got, out = combine_parts.combine(invd)
        rec(case, want, got, (out[1].strip() if len(out) > 1 else "")[:110] if want != "PASS" else "")
        if want != "PASS":
            for ln in out[1:]:
                if "TEST" in ln:
                    print("       " + ln.strip()[:150])
    # a receipt for a part nobody requested
    invd = inv_dir("b1_unrequested_part", [("fast", F6, "", FAST13, {}), ("1x", "ghat_spring", "", X13, {})])
    with open(os.path.join(invd, "expected"), "w", encoding="utf-8") as f:
        f.write("fast\t%s\t\n" % F6)
    got, out = combine_parts.combine(invd)
    rec("b1_unrequested_part", "TEST", got, out[-1].strip()[:110])


def b2():
    print("== blocker 2: a step that closes late between polls (method_watch.closed_late)")
    import method_watch
    # synthetic: OPEN and a late CLOSE read in ONE batch (the step is never seen open past its deadline)
    o = ("overrun_control", 0.0, 1000.0, 10.0, 600)
    for case, close, want in (("b2_closed_late_game_fast", {"pf": 600 + 631, "unix": 1002.3}, True),     # 10.52 game s, 2.3 wall s
                              ("b2_closed_late_wall_1x", {"pf": 600 + 597, "unix": 1010.4}, True),       # 9.95 game s, 10.4 wall s
                              ("b2_closed_on_time_fast", {"pf": 600 + 570, "unix": 1002.1}, False),
                              ("b2_closed_on_time_1x", {"pf": 600 + 570, "unix": 1009.6}, False)):
        late, g, w = method_watch.closed_late(o, close)
        rec(case, "STALLED" if want else "pass", "STALLED" if late else "pass", "%.2f game s, %.2f wall s, budget 10" % (g, w))
    # the archived runs: every real step that closed, judged by the new rule (a false STALL here would
    # turn a clean run red). Clean fast x2, clean 1x x2, the plant runs x14.
    worst = []
    for run in sorted(os.listdir(RUNS)):
        p = os.path.join(RUNS, run, "method_events.txt")
        if not run.startswith("20261111") or not os.path.exists(p):
            continue
        opens, late, n, top = {}, [], 0, (0.0, "")
        for ln in open(p, encoding="utf-8", errors="replace"):
            try:
                e = json.loads(ln)
            except ValueError:
                continue
            if e.get("ev") == "OPEN":
                opens[e["id"]] = (e["step"], 0.0, float(e["unix"]), float(e["secs"]), int(e.get("pf", 0)))
            elif e.get("ev") == "CLOSE" and e["id"] in opens:
                o = opens.pop(e["id"])
                lt, g, w = method_watch.closed_late(o, e)
                n += 1
                r = max(g, w) / o[3]
                if r > top[0]:
                    top = (r, "%s %.1f/%.1f s (game %.1f, wall %.1f)" % (e["id"], max(g, w), o[3], g, w))
                if lt and not o[0].startswith("overrun_control"):
                    late.append(e["id"])
        clean = "_k3_fast" in run or run.endswith("_k3_laneb") or run.endswith("_1x_laneb")
        worst.append((run, n, late, top))
        print("     %-58s %3d closed steps, late: %-14s closest: %.0f%% %s" % (run, n, late or "none", 100 * top[0], top[1]))
    rec("b2_archived_steps_no_false_stall", "none late", "none late" if not any(w[2] for w in worst) else "LATE", "%d runs" % len(worst))


if __name__ == "__main__":
    want = sys.argv[1:] or ["b1", "b2", "b3"]
    for w in want:
        if w in globals():
            globals()[w]()
    print("controls: %d / %d as expected" % (sum(RESULTS), len(RESULTS)))
    sys.exit(0 if all(RESULTS) else 1)
