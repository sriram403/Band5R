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


def b3():
    print("== blocker 3: a plant is PROVED only by its own exact ids in its own run (prove_ghat.judge)")
    import prove_ghat
    import method_watch
    G = prove_ghat.GROUPS

    def case(name, group, src, mutate=None, inv_override=None, judge_as=None):
        scen, plants, expect = G[judge_as or group]
        base = fresh(name)
        inv = "ctl_" + name
        invd = os.path.join(base, inv)
        os.makedirs(invd)
        rd = os.path.join(base, "run")
        shutil.copytree(os.path.join(RUNS, src), rd, ignore=shutil.ignore_patterns("shots", "*.png", "seg_1.log"))
        info = open(os.path.join(rd, "run_info.txt"), encoding="utf-8").read()
        open(os.path.join(rd, "run_info.txt"), "w", encoding="utf-8").write("inv %s part fast\n%s" % (inv_override or inv, info))
        tr = json.load(open(os.path.join(rd, "trace.json"), encoding="utf-8"))
        for c in tr["conditions"]:
            if c.get("kind") == "rule" and "id" not in c:
                m = re.match(r"^(H\d+):", c["text"])
                if m:
                    c["id"] = m.group(1)
        tr["inv"], tr["part"] = inv_override or inv, "fast"
        tr["fixture"] = re.search(r"fixture '([^']*)'", info).group(1)
        if mutate:
            mutate(tr)
        json.dump(tr, open(os.path.join(rd, "trace.json"), "w", encoding="utf-8"), indent=1)
        import method_verdict
        import io
        import contextlib
        with contextlib.redirect_stdout(io.StringIO()):
            method_verdict.report(tr, FZ, rd)
        with open(os.path.join(invd, "expected"), "w") as f:
            f.write("fast\t%s\t%s\n" % (scen, plants))
        open(os.path.join(invd, "fast.dir"), "w").write(rd)
        prob, d, rows = prove_ghat.judge(invd, scen, plants, expect)
        # what the OLD rule (substring in a FAIL line of verdict.txt) would have said
        v = open(os.path.join(rd, "verdict.txt"), encoding="utf-8").read()
        fails = [ln for ln in v.splitlines() if ln.strip().startswith(("FAIL", "RESULT: FAIL"))]
        old = {p: all(any(t in ln for ln in fails) for t in OLD_TEXTS[p]) for p in rows if p in OLD_TEXTS}
        return rows, old, tr

    def flip(scen, idpart, ok):
        def f(tr):
            for c in tr["checks"]:
                if c.get("scen") == scen and idpart in re.sub(r"[^a-z0-9]+", "_", c["text"].lower()):
                    c["ok"] = ok
        return f

    def show(name, rows, old, want):
        for p, (ok, why) in rows.items():
            w = want.get(p)
            if w is None:
                continue
            rec("%s:%s" % (name, p), w, "PROVED" if ok else "NOT PROVED", "old rule: %s; %s" % (
                ("PROVED" if old.get(p) else "NOT PROVED") if p in old else "-", why[:90]))

    HEAT_F, JUG_F, NET_F, HEAT_E = ("20261111_105546_ghat_k3_heat_always,one_corner_fast", "20261111_105826_ghat_k3_leave_sees,no_breath_lock,round_skip_fast",
                                    "20261111_105802_ghat_k3_one_layer_net_fast", "20261111_111507_ghat_k3_heat_always,one_corner_fast")
    # positives (the archived T1 runs, judged by the new rule)
    r, o, _ = case("b3_heat_clean_proof", "heat_always", HEAT_F)
    show("b3_heat_clean_proof", r, o, {"heat_always": "PROVED"})
    r, o, _ = case("b3_jug_batch_clean_proof", "jug_a", JUG_F)
    show("b3_jug_batch_clean_proof", r, o, {p: "PROVED" for p in G["jug_a"][2]})
    r, o, _ = case("b3_heat_early_clean_proof", "heat_always", HEAT_E)
    show("b3_heat_early_clean_proof", r, o, {"heat_always": "PROVED"})
    # one expected FAIL missing (H1 never fired)
    r, o, _ = case("b3_one_expected_missing", "heat_always", HEAT_F,
                   lambda tr: tr.__setitem__("conditions", [c for c in tr["conditions"] if c.get("id") != "H1"]))
    show("b3_one_expected_missing", r, o, {"heat_always": "NOT PROVED"})
    # a similarly named wrong check: "over the pass" (jug_c's old text) is also in the objective check;
    # the objective check fails, the plant's own over-the-pass check passes
    def wrong(tr):
        # in this plant run both pass checks ran (the _fix_with helper) and both FAILed downstream: make
        # the objective one FAIL and the plant's own over-the-pass one PASS
        for c in tr["checks"]:
            sl = re.sub(r"[^a-z0-9]+", "_", c["text"].lower())
            if c.get("scen") == "ghat_jug" and sl.startswith("the_objective_moves_on_over_the_pass"):
                c["ok"] = False
            elif c.get("scen") == "ghat_jug" and sl.startswith("over_the_pass_"):
                c["ok"] = True
    def jug_c_fixture(tr):
        wrong(tr)
        tr["fixture"] = "no_power"
    r, o, tr = case("b3_similar_named_wrong_check", "jug_c", JUG_F, jug_c_fixture)
    # the copy's run_info still names the jug_a plants: rebind it for this case (fixture is not the point here)
    rdir = os.path.join(CTL, "b3_similar_named_wrong_check", "run")
    ri = open(os.path.join(rdir, "run_info.txt"), encoding="utf-8").read().replace("leave_sees,no_breath_lock,round_skip", "no_power")
    open(os.path.join(rdir, "run_info.txt"), "w", encoding="utf-8").write(ri)
    show("b3_similar_named_wrong_check", r, o, {"no_power": "NOT PROVED"})
    # the wrong run's evidence: (a) another invocation's run folder; (b) a run with other plants
    r, o, _ = case("b3_wrong_invocation", "heat_always", HEAT_F, inv_override="prove_heat_always_someone_else")
    show("b3_wrong_invocation", r, o, {"heat_always": "NOT PROVED"})
    r, o, _ = case("b3_other_plants_run", "net", HEAT_F, judge_as="net")
    show("b3_other_plants_run", r, o, {"one_layer_net": "NOT PROVED"})
    # a batch member whose own check is absent (round_skip's check passed): the others still prove
    r, o, _ = case("b3_batch_member_absent", "jug_a", JUG_F, flip("ghat_jug", "it_went_all_round_the_van", True))
    show("b3_batch_member_absent", r, o, {"leave_sees": "PROVED", "no_breath_lock": "PROVED", "round_skip": "NOT PROVED"})
    # an early stop before every expected id was on record (H1 removed from an early-stopped run)
    r, o, tr = case("b3_early_stop_short", "heat_always", HEAT_E,
                    lambda tr: (tr.__setitem__("conditions", [c for c in tr["conditions"] if c.get("id") != "H1"]), tr.__setitem__("early_stop", True)))
    show("b3_early_stop_short", r, o, {"heat_always": "NOT PROVED"})
    done, have = method_watch.expected_on_record(tr, FZ, G["heat_always"][2]["heat_always"])
    rec("b3_watch_early_stop_trigger_without_H1", "no stop", "stop" if done else "no stop", "ids on record: %s" % sorted(have)[:3])
    # the game not checked gone
    r, o, _ = case("b3_game_not_gone", "heat_always", HEAT_F, lambda tr: tr.__setitem__("godot_left_after", [4242]))
    show("b3_game_not_gone", r, o, {"heat_always": "NOT PROVED"})

    # qual round 2: marks_pile counts only if the looks prelude made its round (marks on the van at the
    # F1 jump). T1 run 9: the prelude made 0 stops -> "prerequisite not met", not NOT PROVED / PROVED
    M9, M11, M1X = ("20261111_105936_ghat_k3_marks_pile,marks_unsaved_fast", "20261111_111501_ghat_k3_marks_pile,marks_unsaved_fast_laneb",
                    "20261111_110244_ghat_k3_marks_pile,marks_unsaved")
    r, o, _ = case("q2_marks_prelude_no_round", "marks", M9)
    show("q2_marks_prelude_no_round", r, o, {"marks_pile": "NOT PROVED", "marks_unsaved": "PROVED"})
    rec("q2_marks_prelude_no_round:why", "prerequisite", "prerequisite" if r["marks_pile"][1].startswith("prerequisite not met") else "other", r["marks_pile"][1][:70])
    r, o, _ = case("q2_marks_prelude_round_fast", "marks", M11)
    show("q2_marks_prelude_round_fast", r, o, {"marks_pile": "PROVED", "marks_unsaved": "PROVED"})
    r, o, _ = case("q2_marks_prelude_round_1x", "marks", M1X)
    show("q2_marks_prelude_round_1x", r, o, {"marks_pile": "PROVED", "marks_unsaved": "PROVED"})


OLD_TEXTS = {"heat_always": ["no heat or leak from it before it sees the van", "H1:"], "one_layer_net": ["from outside nothing of the van shows through the net"],
             "leave_sees": ["out beside it after it gave up: nobody is taken"], "no_breath_lock": ["never touched the handbrake"],
             "round_skip": ["it went all round the van before it gave up"], "no_power": ["over the pass"]}


if __name__ == "__main__":
    want = sys.argv[1:] or ["b1", "b2", "b3"]
    for w in want:
        if w in globals():
            globals()[w]()
    print("controls: %d / %d as expected" % (sum(RESULTS), len(RESULTS)))
    sys.exit(0 if all(RESULTS) else 1)
