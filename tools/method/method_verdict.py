"""The final method's reducer: one RESULT with one of five statuses (M14).

PASS 0 / FAIL 1 / INCOMPLETE 2 / TEST 3 / NOT HEALTHY 4. STALLED and KILL
FAILED are reasons. Policies come from tools/method/frozen.json "policy" (the
user's answers, 2026-11-06): jump_tries 1, departure "checks", script_error
"split" (applied by the supervisor), headline "earliest", missing_object
"fail_unresolved". Every condition prints with its time; nothing is erased.
Usage (offline, on an archived trace): method_verdict.py <run dir>
"""
import json
import os
import re
import sys

EXIT = {"PASS": 0, "FAIL": 1, "INCOMPLETE": 2, "TEST": 3, "NOT HEALTHY": 4}
TIE_RANK = {"NOT HEALTHY": 0, "TEST": 1, "FAIL": 2, "INCOMPLETE": 3}


def match_checks(checks, manifest):
    """Each logged check -> its manifest ID (first unused match, in order)."""
    used, out, unmatched = set(), [], []
    for c in checks:
        hit = None
        for m in manifest:
            if m["id"] in used:
                continue
            if re.match(m["regex"], c["text"], re.S):
                hit = m
                break
        if hit is None:
            unmatched.append(c)
            continue
        used.add(hit["id"])
        out.append((hit, c))
    return out, unmatched


def reduce(tr, fz):
    """Adds the end-of-run conditions (ledger, reach, coverage) to the trace's
    live ones; returns (status, headline, all conditions sorted, details)."""
    pol = fz["policy"]
    conds = [dict(c) for c in tr["conditions"]]
    t_end = tr.get("t_end", 0)
    det = {"lines": []}
    started = [s["scen"] for s in tr["started"]]
    ended = [s["scen"] for s in tr["ended"]]
    killed = bool(tr.get("kill")) and any("gone" in k or "KILL" in k for k in tr["kill"])
    stall_or_stop = [c for c in conds if c["status"] in ("NOT HEALTHY", "TEST") or c["kind"] == "stall"]
    # ---- scenario ledger (M2)
    for s in tr["asked"]:
        if s not in started:
            conds.append({"status": "INCOMPLETE", "text": "NOT STARTED: %s" % s, "begin": t_end, "kind": "ledger", "owner": "UNRESOLVED"})
        elif s not in ended:
            conds.append({"status": "INCOMPLETE", "text": "stopped in %s at %s (started, never ended)" % (s, tr.get("last_step") or tr.get("last_beat_step")),
                          "begin": t_end, "kind": "ledger", "owner": "UNRESOLVED"})
    # ---- checks (M9) with the reach policies (M10 departure "checks", M11 one try)
    req = fz["required"]
    ck = [c for c in tr["checks"] if c.get("scen") in req]
    jump_missed = False
    missed_in = set()
    for scen, spec in req.items():
        man = spec.get("checks", [])
        if not man or scen not in tr["asked"]:
            continue
        mine = [c for c in ck if c.get("scen") == scen]
        pairs, unmatched = match_checks(mine, man)
        for c in unmatched:
            conds.append({"status": "TEST", "text": "a check outside the declared manifest: '%s'" % c["text"], "begin": float(c["unix"]), "kind": "event", "owner": "UNRESOLVED"})
        seen = {m["id"]: c for m, c in pairs}
        for m, c in pairs:
            if c["ok"]:
                continue
            if m["kind"] == "jump":
                jump_missed = True
                missed_in.add(scen)
                a = [x for x in tr["attempts"] if x.get("scen") == scen]
                last = a[-1] if a else {}
                conds.append({"status": "INCOMPLETE", "text": "the scheduled landing missed (jump_tries=%d): lip %s km/h, lane at the lip %s m (target %s km/h, lane %s m), owner=UNRESOLVED"
                              % (pol["jump_tries"], last.get("lip_kmh"), last.get("lane_at_lip"), last.get("target"), last.get("lane")),
                              "begin": float(c["unix"]), "kind": "reach", "owner": "UNRESOLVED"})
            elif m["kind"] == "departure":
                conds.append({"status": "INCOMPLETE", "text": "drive-off not reached: '%s' failed, owner=UNRESOLVED" % c["text"],
                              "begin": float(c["unix"]), "kind": "reach", "owner": "UNRESOLVED"})
            else:
                conds.append({"status": "FAIL", "text": "check failed: '%s' (%s), owner=UNRESOLVED" % (c["text"], m["id"]),
                              "begin": float(c["unix"]), "kind": "check", "owner": "UNRESOLVED"})
        missing = [m["id"] for m in man if m["id"] not in seen]
        det["checks_%s" % scen] = (len(seen), len(man))
        if missing and scen in started:
            why = "not reached after the missed landing" if scen in missed_in else "required checks never ran"
            if not (scen in missed_in and scen in ended) and not stall_or_stop:
                conds.append({"status": "INCOMPLETE", "text": "%s in %s: %d of %d missing: %s" % (why, scen, len(missing), len(man), ", ".join(missing)),
                              "begin": next((s["unix"] for s in tr["ended"] if s["scen"] == scen), t_end), "kind": "ledger", "owner": "UNRESOLVED"})
            det["lines"].append("  %s: %d of %d required checks missing (%s): %s" % (scen, len(missing), len(man), why, ", ".join(missing)))
    # ---- required work and windows (M9, M3)
    for scen, spec in req.items():
        if scen not in started:
            continue
        miss = []
        for w in spec.get("work", []):
            if not any(x["id"] == w and x.get("ok") and x.get("scen") == scen for x in tr["work"]):
                miss.append("work:" + w)
        for r in spec.get("windows", []):
            if not any(x.get("rule") == r and x.get("complete") and x.get("scen") == scen for x in tr["windows"]):
                miss.append("window:" + r)
        rs = tr["rules"].get(scen, {}).get("stat", {})
        for r in spec.get("evaluated", []):
            if int(rs.get(r, {}).get("eval", 0)) < 1:
                miss.append("evaluated:" + r)
        if spec.get("attempts"):
            a = [x for x in tr["attempts"] if x.get("scen") == scen]
            if len(a) < spec["attempts"]:
                miss.append("attempts %d of %d" % (len(a), spec["attempts"]))
        if miss:
            det["lines"].append("  %s: missing required work/windows: %s" % (scen, ", ".join(miss)))
            if scen in ended and scen not in missed_in:
                conds.append({"status": "INCOMPLETE", "text": "%s ended with required work missing: %s" % (scen, ", ".join(miss)),
                              "begin": next(s["unix"] for s in tr["ended"] if s["scen"] == scen), "kind": "ledger", "owner": "UNRESOLVED"})
    # ---- headline (M15): earliest by when it began; within 2 s by rank; preflight TEST first
    order = sorted(conds, key=lambda c: float(c["begin"]))
    head = None
    pre = [c for c in order if c["status"] == "TEST" and c["kind"] == "preflight"]
    if pre:
        head = pre[0]
    elif order:
        if pol["headline"] == "earliest":
            t0 = float(order[0]["begin"])
            near = [c for c in order if float(c["begin"]) - t0 <= float(fz["limits"]["headline_tie_s"])]
            head = sorted(near, key=lambda c: (TIE_RANK[c["status"]], float(c["begin"])))[0]
        else:
            raise SystemExit("headline policy '%s' not built" % pol["headline"])
    status = head["status"] if head else "PASS"
    return status, head, order, det


def fmt_t(tr, u):
    return "%+.1fs" % (float(u) - float(tr["t_start"]))


def report(tr, fz, out):
    status, head, order, det = reduce(tr, fz)
    code = EXIT[status]
    L = []
    prof = re.search(r"--method-profile=(k\d)", tr.get("args", ""))
    prof = prof.group(1) if prof else "k3 (default)"
    if head is None:
        L.append("RESULT: PASS (exit 0): %s profile %s" % (tr["plan"], prof))
    else:
        L.append("RESULT: %s (exit %d): %s [began %s]" % (status, code, head["text"], fmt_t(tr, head["begin"])))
    L.append("  asked %d (%s) / started %d / ended %d (%s); wall %.0f s; beats %d; game pid %s" % (
        len(tr["asked"]), ",".join(tr["asked"]), len(tr["started"]), len(tr["ended"]), ",".join(s["scen"] for s in tr["ended"]), tr.get("wall_s", 0), tr["beats"], tr.get("pid")))
    if tr.get("launch") and tr.get("first_beat"):
        L.append("  startup: first beat %.1f s after the game launched (limit %s s)" % (tr["first_beat"] - tr["launch"], fz["limits"]["startup_first_beat_s"]))
    if len(order) > 0:
        L.append("  every condition, in the order it began (status, began, detected):")
        for c in order:
            mark = "  <== headline" if c is head else ""
            dt = (" detected %s" % fmt_t(tr, c["detected"])) if c.get("detected") else ""
            L.append("    %-11s %s%s  %s%s" % (c["status"], fmt_t(tr, c["begin"]), dt, c["text"], mark))
    for x in det["lines"]:
        L.append(x)
    for k, v in det.items():
        if k.startswith("checks_"):
            L.append("  %s: %d / %d required checks ran" % (k[7:], v[0], v[1]))
    for a in tr["attempts"]:
        L.append("  attempt [%s]: target %s km/h lane %s m -> %s, lip %s km/h, lane at lip %s m" % (a.get("scen"), a.get("target"), a.get("lane"), a.get("what"), a.get("lip_kmh"), a.get("lane_at_lip")))
    for scen, r in tr["rules"].items():
        st = r.get("stat", {})
        L.append("  rules in %s (evaluated / windows / errors / findings): %s" % (scen, "  ".join("%s %d/%d/%d/%d" % (k, v["eval"], v["win"], v["err"], v["find"]) for k, v in st.items())))
        nr = [k for k, v in st.items() if v["eval"] == 0 and v["find"] == 0]
        if nr:
            L.append("    NOT REACHED in %s: %s" % (scen, ", ".join(nr)))
    if tr["g3b"]:
        w = max(tr["g3b"], key=lambda e: float(e["worst"]))
        L.append("  G3b: %d parked evaluation(s); worst residual %.4f m (%s); tolerance %s" % (len(tr["g3b"]), float(w["worst"]), w.get("worst_part"), fz["thresholds"].get("G3b_tolerance_m")))
    if tr.get("kill"):
        L.append("  stop: kill started %.2f s after detection; shutdown %.2f s; %s" % (tr.get("detect_to_kill_start_s", -1), tr.get("shutdown_s", -1), "; ".join(tr["kill"])))
    if "stall_detect_after_deadline_s" in tr:
        L.append("  stall detected %.2f s after its deadline (%.2f s after the step opened)" % (tr["stall_detect_after_deadline_s"], tr["stall_detect_after_open_s"]))
    L.append("  godot processes left after the run: %s" % (tr.get("godot_left_after") or "none"))
    sc = fz["scope"]
    L.append("  Scope: %s, profile %s. Claims: %s" % (tr["plan"], prof, sc["claims"]))
    L.append("  Declared setup (not proven): %s; the %d exact source lines are in frozen.json scope.declared_setup_lines" % ("; ".join(sc["declared_setup"]), len(sc["declared_setup_lines"])))
    L.append("  NOT PROVEN: %s" % "; ".join(sc["not_proven"]))
    L.append("  Evidence: %s" % out)
    txt = "\n".join(L)
    print(txt, flush=True)
    with open(os.path.join(out, "verdict.txt"), "w", encoding="utf-8") as f:
        f.write(txt + "\n")
    return code


if __name__ == "__main__":
    d = sys.argv[1]
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    fz = json.load(open(os.path.join(root, "tools", "method", "frozen.json"), encoding="utf-8"))
    sys.exit(report(json.load(open(os.path.join(d, "trace.json"), encoding="utf-8")), fz, d))
