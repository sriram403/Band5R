"""autoq offline controls (no game; 2026-11-17, GPT audit #8): every new guard refuses its planted case with the
intended reason and passes its clean case; then each guard is switched OFF and its planted case must turn BAD
(a guard never seen failing is not a guard).

Evidence: the real fresh producer F3 (ghat_rp14_20261117_212548_20588: points 0-13 with their +3 s samples),
copied read-only into appdata/autoqctl/work; ids / receipts / end records around it are synthetic.

    python tools/method/autoq_controls.py      -> one line per case; exit 1 if any disagrees
"""
import copy
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import walkgate as wg  # noqa: E402

F3 = os.environ.get("AQ_SRC", os.path.join(ROOT, "appdata", "playtest", "FindingNaresh", "live", "points",
                                           "ghat_rp14_20261117_212548_20588"))
W = os.path.join(ROOT, "appdata", "autoqctl", "work")
PTS = os.path.join(W, "points")
RES = []


def rec(case, want, got, note=""):
    ok = want == got
    RES.append(ok)
    print("%-4s %-70s want %-9s got %-9s %s" % ("ok" if ok else "BAD", case, str(want), str(got), str(note)[:130]), flush=True)
    return ok


def setup():
    shutil.rmtree(W, ignore_errors=True)
    os.makedirs(PTS)
    prod = os.path.join(PTS, "ghat_P")
    shutil.copytree(F3, prod)
    ident = {"game": "g1", "bin": "b1", "tools": "t1", "testcode": "c1", "test": "w1", "schema": wg.SCHEMA, "profile": "play"}
    rj = wg.load(os.path.join(prod, "run.json"))
    rj.update(identity=ident, run="ghat_P", **{"from": "", "control": []})
    json.dump(rj, open(os.path.join(prod, "run.json"), "w"))
    walk = wg.load(os.path.join(prod, "walk.json"))
    walk["name"] = "ghat"
    json.dump(walk, open(os.path.join(prod, "walk.json"), "w"))
    end = {"status": "FAILED", "failed_index": 13, "failed_step": walk["steps"][13]["name"], "kind": "expect",
           "check": "P2 holds a full pot", "text": "x", "outcomes": [[12, "PASS", "net off"], [13, "FAIL", "expect:P2 holds a full pot"]]}
    json.dump(end, open(os.path.join(prod, "end.json"), "w"))
    return prod, ident, walk, end


def receipt(name, k, ident, pid, verdict="SAME", control=None, rpid=None):
    rd = os.path.join(PTS, name)
    os.makedirs(rd, exist_ok=True)
    sha = wg.point_sha(os.path.join(PTS, pid + ".json"))
    json.dump({"point": pid, "verdict": verdict, "resume_run": name, "resume_pid": rpid or (hash(name) % 9000 + 1000),
               "profile": "play", "resume_identity": dict(ident), "point_sha": sha, "gate_hash": wg.gate_hash(),
               "protocol": "rv1/seed-v1"}, open(os.path.join(rd, "%d.gate.json" % k), "w"))
    json.dump({"identity": dict(ident), "pid": rpid or 1, "control": control or [], "from": "x", "from_point": pid},
              open(os.path.join(rd, "run.json"), "w"))


def cases(prod, ident, walk, end, only=None):
    """-> {case: ok}. only: run just that case (for the guard-off pass)."""
    out = {}

    def c(name, want, fn):
        if only and name != only:
            return
        try:
            got, note = fn()
        except Exception as e:      # a crash is a disagreement, shown
            got, note = "CRASH", repr(e)
        out[name] = rec(name, want, got, note)

    K = 13
    # --- classify_walk (GPT #1)
    later = copy.deepcopy(walk)
    later["steps"].append({"name": "21 extra", "do": [], "expect": []})
    kact = copy.deepcopy(walk)
    kact["steps"][K]["do"] = kact["steps"][K]["do"][:-1]
    pre = copy.deepcopy(walk)
    pre["steps"][K - 1]["do"] = pre["steps"][K - 1]["do"] + [{"do": "wait", "s": 0.1}]
    setup_ = copy.deepcopy(walk)
    setup_["setup"] = list(setup_.get("setup", [])) + [{"do": "wait", "s": 0.1}]
    top = copy.deepcopy(walk)
    top["extra_key"] = 1
    kneeds = copy.deepcopy(walk)
    kneeds["steps"][K]["needs"] = ["x"]
    c("classify: identical walk -> same", "same", lambda: (wg.classify_walk(walk, copy.deepcopy(walk), K)["mode"], ""))
    c("classify: a later step added -> repair, step k unchanged", "repair/False",
      lambda: ("%s/%s" % (wg.classify_walk(walk, later, K)["mode"], wg.classify_walk(walk, later, K)["k_changed"]), wg.classify_walk(walk, later, K)["why"]))
    c("classify: step k's actions -> repair, k changed", "repair/True",
      lambda: ("%s/%s" % (wg.classify_walk(walk, kact, K)["mode"], wg.classify_walk(walk, kact, K)["k_changed"]), ""))
    c("classify: an earlier step changed -> refuse", "refuse", lambda: (wg.classify_walk(walk, pre, K)["mode"], wg.classify_walk(walk, pre, K)["why"]))
    c("classify: setup changed -> refuse", "refuse", lambda: (wg.classify_walk(walk, setup_, K)["mode"], wg.classify_walk(walk, setup_, K)["why"]))
    c("classify: a top-level key changed -> refuse", "refuse", lambda: (wg.classify_walk(walk, top, K)["mode"], ""))
    c("classify: step k's needs (not an action) -> refuse", "refuse", lambda: (wg.classify_walk(walk, kneeds, K)["mode"], wg.classify_walk(walk, kneeds, K)["why"]))
    # --- identity_check: SAME needs the identical walk
    c("identity_check: later-step change -> not a plain resume", "REFUSED",
      lambda: ("REFUSED" if wg.identity_check(prod, K, ident, later, "play") else "ADMIT", "; ".join(wg.identity_check(prod, K, ident, later, "play"))))
    c("identity_check: identical walk -> admit", "ADMIT", lambda: ("REFUSED" if wg.identity_check(prod, K, ident, walk, "play") else "ADMIT", ""))
    # --- spill (GPT #2)
    t3 = wg.load(os.path.join(prod, "%d.t3.json" % K))
    # the producer's walk ends at step 13 (ghat_rp14): the spill case uses a producer walk WITH a step 14 ("later")
    spill = copy.deepcopy(t3)
    spill["lines"] = spill["lines"] + ["step %s (9 s, frame 99)" % later["steps"][K + 1]["name"]]
    k1 = copy.deepcopy(later)
    k1["steps"][K + 1]["do"] = [{"do": "wait", "s": 1}]
    c("spill: window = step k only, a later step changed -> layer 3 on", True, lambda: (wg.spill_ok(walk, later, K, t3)[0], wg.spill_ok(walk, later, K, t3)[1]))
    c("spill: window reaches step k+1, which changed -> n/a", False, lambda: (wg.spill_ok(later, k1, K, spill)[0], wg.spill_ok(later, k1, K, spill)[1]))
    c("spill: window reaches step k+1, unchanged -> layer 3 on", True, lambda: (wg.spill_ok(later, later, K, spill)[0], ""))
    c("spill: no step line in the sample -> n/a (fails closed)", False, lambda: (wg.spill_ok(walk, later, K, {"lines": []})[0], ""))
    # --- outcome (GPT #3)
    same = copy.deepcopy(end)
    diag = copy.deepcopy(end)
    diag["text"] = "other diagnostics (positions)"
    chk = copy.deepcopy(end)
    chk["check"] = "other check"
    gate = copy.deepcopy(end)
    gate["kind"] = "gate"
    mid = copy.deepcopy(end)
    mid["outcomes"] = [[12, "PASS", "net off"], [13, "PASS", "extra"], [13, "FAIL", "expect:P2 holds a full pot"]]
    early = copy.deepcopy(end)
    early["outcomes"] = [[3, "PASS", "x"]] + end["outcomes"]
    stop = copy.deepcopy(end)
    stop["status"] = "STOPPED"
    c("outcome: identical end -> pass", 0, lambda: (len(wg.outcome(end, same, K)), ""))
    c("outcome: diagnostic text differs only -> pass", 0, lambda: (len(wg.outcome(end, diag, K)), ""))
    c("outcome: another failed check -> differ", 1, lambda: (min(1, len(wg.outcome(end, chk, K))), wg.outcome(end, chk, K)))
    c("outcome: resume failed by the gate -> differ", 1, lambda: (min(1, len(wg.outcome(end, gate, K))), wg.outcome(end, gate, K)))
    c("outcome: an extra outcome on the way, same final FAIL -> differ", 1, lambda: (min(1, len(wg.outcome(end, mid, K))), wg.outcome(end, mid, K)))
    c("outcome: a difference BEFORE step k is not compared -> pass", 0, lambda: (len(wg.outcome(end, early, K)), ""))
    c("outcome: no end record from the resume -> differ", 1, lambda: (min(1, len(wg.outcome(end, None, K))), ""))
    c("outcome: a STOPPED (probe) run -> differ", 1, lambda: (min(1, len(wg.outcome(end, stop, K))), ""))
    # --- pick_point (GPT #6): F3's real refusals (6-8, 10, 11 refused; 9, 12, 13 resumable)
    c("pick_point: failed at 13 -> 13", 13, lambda: wg.pick_point(prod, 13))
    c("pick_point: failed at 11 -> walks back past 11, 10 to 9", 9, lambda: (wg.pick_point(prod, 11)[0], wg.pick_point(prod, 11)[1]))
    t3p = os.path.join(prod, "13.t3.json")
    keep = open(t3p, encoding="utf-8").read()
    bad_t3 = json.loads(keep)
    bad_t3["failed_before"] = "a FAIL"
    json.dump(bad_t3, open(t3p, "w"))
    c("pick_point: point 13's +3 s sample has a FAIL -> 12", 12, lambda: (wg.pick_point(prod, 13)[0], wg.pick_point(prod, 13)[1][:1]))
    open(t3p, "w", encoding="utf-8").write(keep)
    rj = wg.load(os.path.join(prod, "run.json"))
    json.dump(dict(rj, **{"from": "x"}), open(os.path.join(prod, "run.json"), "w"))
    c("pick_point: a resumed producer -> none", None, lambda: wg.pick_point(prod, 13))
    json.dump(dict(rj, control=["drop"]), open(os.path.join(prod, "run.json"), "w"))
    c("pick_point: a planted-control producer -> none", None, lambda: wg.pick_point(prod, 13))
    json.dump(rj, open(os.path.join(prod, "run.json"), "w"))
    # --- receipts + default_start (GPT #5)
    pid = "ghat_P/13"
    for d in os.listdir(PTS):
        if d.startswith("r_"):
            shutil.rmtree(os.path.join(PTS, d))
    lf = os.path.join(PTS, "ghat_last_fail.json")
    if os.path.exists(lf):
        os.remove(lf)
    ds = lambda wk=walk, idn=ident: wg.default_start(PTS, wk, idn)
    c("default: no last_fail -> fresh", "fresh", lambda: (ds()["mode"], ds()["why"]))
    json.dump({"run": "ghat_P", "point": pid, "step": walk["steps"][13]["name"]}, open(lf, "w"))
    c("default: a fresh failure not yet qualified -> fresh", "fresh", lambda: (ds()["mode"], ds()["why"]))
    receipt("r_c1", 13, ident, pid, control=["drop"], rpid=501)
    receipt("r_c2", 13, ident, pid, control=["l2_continue"], rpid=502)
    c("default: 2 SAME receipts from planted-control runs -> fresh", "fresh", lambda: (ds()["mode"], ds()["why"]))
    receipt("r_1", 13, ident, pid, rpid=601)
    receipt("r_2", 13, ident, pid, rpid=602)
    c("default: qualified, identical walk -> resume", "resume", lambda: (ds()["mode"], ds()["why"]))
    c("default: qualified, a later step fixed -> repair", "repair", lambda: (ds(later)["mode"], ds(later)["why"]))
    c("default: qualified, an earlier step changed -> fresh", "fresh", lambda: (ds(pre)["mode"], ds(pre)["why"]))
    c("default: game code changed -> fresh (reason printed)", "fresh", lambda: (ds(walk, dict(ident, game="g2"))["mode"], ds(walk, dict(ident, game="g2"))["why"]))
    receipt("r_cd", 13, ident, pid, verdict="DIFFERENT", control=["drop"], rpid=701)
    c("default: a planted-control DIFFERENT does not disqualify", "resume", lambda: (ds()["mode"], ds()["why"]))
    receipt("r_d", 13, ident, pid, verdict="DIFFERENT", rpid=702)
    c("default: a valid DIFFERENT next to 2 SAME -> fresh", "fresh", lambda: (ds()["mode"], ds()["why"]))
    shutil.rmtree(os.path.join(PTS, "r_d"))
    # a resumed run's failure maps to its source
    rr = os.path.join(PTS, "ghat_R")
    os.makedirs(rr, exist_ok=True)
    json.dump({"identity": ident, "pid": 9, "from": walk["steps"][13]["name"], "from_point": pid, "control": []}, open(os.path.join(rr, "run.json"), "w"))
    json.dump(dict(end, failed_index=15), open(os.path.join(rr, "end.json"), "w"))
    json.dump({"run": "ghat_R", "point": "ghat_R/15", "step": "x"}, open(lf, "w"))
    c("default: a resumed run failed later -> its qualified source", "resume/" + pid, lambda: ("%s/%s" % (ds()["mode"], ds()["point"]), ds()["why"]))
    json.dump({"run": "ghat_P", "fresh_next": "autoq said so"}, open(lf, "w"))
    c("default: fresh_next -> fresh", "fresh", lambda: (ds()["mode"], ds()["why"]))
    # --- autoq lifecycle (GPT #4): no game is ever launched by these
    wp = os.path.join(W, "walk_now.json")
    json.dump(walk, open(wp, "w"))
    env = dict(os.environ, AUTOQ_LIVE=W, AUTOQ_TEST_IDENT=json.dumps(ident), AUTOQ_TEST_WALK=wp)
    aq = lambda *a: subprocess.run([sys.executable, os.path.join(HERE, "autoq.py"), "ghat"] + list(a), env=env, capture_output=True,
                                   text=True, encoding="utf-8", errors="replace").stdout
    json.dump({"run": "ghat_P", "point": "ghat_P/13", "step": walk["steps"][13]["name"], "index": 13}, open(lf, "w"))
    c("autoq: --run names another run -> nothing done", True, lambda: ("nothing done" in aq("--run", "ghat_X"), aq("--run", "ghat_X").strip()[-90:]))
    json.dump({"run": "ghat_R", "point": "ghat_R/15", "step": "x"}, open(lf, "w"))
    c("autoq: a resumed run's failure -> SOURCE, no games", "SOURCE", lambda: (aq("--run", "ghat_R") and wg.load(lf).get("autoq"), wg.load(lf).get("point")))
    c("autoq: already done -> nothing (no --again)", True, lambda: ("already done" in aq("--run", "ghat_R"), ""))
    c("autoq: --again keeps the producer's failed step", "x", lambda: (aq("--again") and wg.load(lf).get("failed_step"), wg.load(lf).get("autoq")))
    json.dump({"run": "ghat_P", "point": "ghat_P/13", "step": "x"}, open(lf, "w"))
    e2 = dict(end, kind="gate")
    json.dump(e2, open(os.path.join(prod, "end.json"), "w"))
    c("autoq: producer failed by the gate -> NOT QUALIFIED, fresh_next", "fresh_next", lambda: (aq("--run", "ghat_P") and ("fresh_next" if wg.load(lf).get("fresh_next") else "?"), wg.load(lf).get("fresh_next")))
    os.remove(os.path.join(prod, "end.json"))
    json.dump({"run": "ghat_P", "point": "ghat_P/13", "step": "x"}, open(lf, "w"))
    c("autoq: no end record -> NOT QUALIFIED, fresh_next", "fresh_next", lambda: (aq("--run", "ghat_P") and ("fresh_next" if wg.load(lf).get("fresh_next") else "?"), wg.load(lf).get("fresh_next")))
    json.dump(end, open(os.path.join(prod, "end.json"), "w"))
    # pick_point none: failed at step 0
    json.dump(dict(end, failed_index=0), open(os.path.join(prod, "end.json"), "w"))
    json.dump({"run": "ghat_P", "point": "ghat_P/0", "step": "x"}, open(lf, "w"))
    c("autoq: no resumable point -> NOT QUALIFIED without a game", True,
      lambda: ("no resumable point" in aq("--run", "ghat_P") and "resume 1" not in open(os.path.join(PTS, "ghat_autoq.json")).read(), ""))
    json.dump(end, open(os.path.join(prod, "end.json"), "w"))
    return out


GUARDS = [   # (guard switched off, the planted case that must then turn BAD)
    ("outcome compares the check", "outcome: another failed check -> differ",
     lambda: setattr(wg, "outcome", lambda p, r, k: [] if isinstance(p, dict) and isinstance(r, dict) else ["x"])),
    ("spill_ok", "spill: window reaches step k+1, which changed -> n/a", lambda: setattr(wg, "spill_ok", lambda *a: (True, ""))),
    ("classify prefix check", "classify: an earlier step changed -> refuse",
     lambda: setattr(wg, "steps_hash", (lambda f: (lambda s: "same" if len(s) == 13 else f(s)))(wg.steps_hash))),
    ("walk binding in identity_check", "identity_check: later-step change -> not a plain resume",
     lambda: setattr(wg, "walk_hash", lambda w: "same")),
    ("receipts skip control runs", "default: 2 SAME receipts from planted-control runs -> fresh",
     lambda: setattr(wg, "COUNT_CONTROL_RUNS", True)),
    ("a valid DIFFERENT disqualifies", "default: a valid DIFFERENT next to 2 SAME -> fresh",
     lambda: setattr(wg, "qualified", (lambda f: (lambda pd, p, k, i: [x for x in f(pd, p, k, i) if "disqualified" not in x]))(wg.qualified))),
    ("pick_point refusal", "pick_point: failed at 11 -> walks back past 11, 10 to 9",
     lambda: setattr(wg, "refusal", lambda *a, **k: [])),
]


def main():
    prod, ident, walk, end = setup()
    cases(prod, ident, walk, end)
    print("--- guards switched off (each planted case must turn BAD)")
    import importlib
    for gname, case, off in GUARDS:
        importlib.reload(wg)
        prod, ident, walk, end = setup()
        off()
        print("guard OFF: %s" % gname, flush=True)
        n0 = len(RES)
        cases(prod, ident, walk, end, only=case)
        got_bad = len(RES) > n0 and not RES[-1]
        del RES[n0:]
        rec("  guard '%s' seen failing when off" % gname, True, got_bad)
    importlib.reload(wg)
    print("autoq offline controls: %d / %d as expected" % (sum(RES), len(RES)))
    return 0 if all(RES) else 1


if __name__ == "__main__":
    sys.exit(main())
