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
           "check": "P2 holds a full pot", "text": "x", "outcomes": [[12, "PASS", "net off"], [13, "FAIL", "expect:P2 holds a full pot"]],
           "steps": len(walk["steps"]), "from": ""}
    json.dump(end, open(os.path.join(prod, "end.json"), "w"))
    # synthetic receipts below can't be rejudged (no observations): their rejudge is off in this section; the rejudge
    # is proved on the REAL saved ghat runs in real_cases()
    wg.TRUST_STORED_VERDICT = True
    return prod, ident, walk, end


def receipt(name, k, ident, pid, verdict="SAME", control=None, rpid=None):
    """A complete synthetic receipt folder (run.json bound to the point and pid, walk.json, a valid end.json)."""
    rd = os.path.join(PTS, name)
    os.makedirs(rd, exist_ok=True)
    sha = wg.point_sha(os.path.join(PTS, pid + ".json"))
    rp = rpid or (hash(name) % 9000 + 1000)
    json.dump({"point": pid, "verdict": verdict, "resume_run": name, "resume_pid": rp,
               "profile": "play", "resume_identity": dict(ident), "point_sha": sha, "gate_hash": wg.gate_hash(),
               "protocol": "rv1/seed-v1"}, open(os.path.join(rd, "%d.gate.json" % k), "w"))
    json.dump({"run": name, "identity": dict(ident), "pid": rp, "control": control or [], "from": "x", "from_point": pid},
              open(os.path.join(rd, "run.json"), "w"))
    shutil.copy(os.path.join(PTS, pid.rsplit("/", 1)[0], "walk.json"), os.path.join(rd, "walk.json"))
    shutil.copy(os.path.join(PTS, pid.rsplit("/", 1)[0], "end.json"), os.path.join(rd, "end.json"))


# ---- GPT results audit B1: the rejudge on REAL saved runs (the historical ghat proof) ---------------------------
REAL = os.environ.get("AQ_REAL", os.path.join(ROOT, "appdata", "playtest", "FindingNaresh", "live", "points"))
REAL_P, REAL_R = "ghat_20261117_224429_13940", ("ghat_20261117_230724_14148", "ghat_20261117_230844_13532")
P_FILES = ("run.json", "walk.json", "end.json", "walk.log", "13.json", "13.obs.json", "13.t3.json")
R_FILES = ("run.json", "walk.json", "end.json", "walk.log", "13.gate.json", "13.restored.obs.json", "13.final.obs.json",
           "13.release.obs.json", "13.t3.json")


def real_setup():
    """-> (points dir, producer identity) with copies of the producer and its 2 qualifying resumes; None if absent."""
    w2 = os.path.join(ROOT, "appdata", "autoqctl", "real", "points")
    shutil.rmtree(os.path.dirname(w2), ignore_errors=True)
    for run, files in [(REAL_P, P_FILES)] + [(r, R_FILES) for r in REAL_R]:
        if not os.path.isdir(os.path.join(REAL, run)):
            return None, None
        os.makedirs(os.path.join(w2, run))
        for f in files:
            shutil.copy(os.path.join(REAL, run, f), os.path.join(w2, run, f))
    wg.GATE_HASH_OVERRIDE = wg.load(os.path.join(w2, REAL_R[0], "13.gate.json"))["gate_hash"]   # the gate they were made by
    return w2, wg.load(os.path.join(w2, REAL_P, "run.json"))["identity"]


def real_cases(only=None):
    out = {}
    w2, ident = real_setup()
    if w2 is None:
        rec("real saved ghat runs present (AQ_REAL)", True, False, "missing: run the proof chain first")
        return out
    pid = REAL_P + "/13"

    def q(note=""):
        sk = []
        r = wg.receipts(w2, pid, 13, ident, sk)
        return ("QUALIFIED" if not wg.qualified(w2, pid, 13, ident) else "NOT", "%s same / %s diff; %s" % (len(r[0]), len(r[1]), "; ".join(sk)[:110]))

    def c(name, want, plant):
        if only and name != only:
            return
        real_setup()
        undo = plant() if plant else None
        got, note = q()
        out[name] = rec(name, want, got, note)

    def edit(run, f, fn):
        p_ = os.path.join(w2, run, f)
        d = wg.load(p_)
        fn(d)
        json.dump(d, open(p_, "w"))

    c("real: the historical pair rejudges -> QUALIFIED", "QUALIFIED", None)
    c("real: a resume's end.json lacks 'kind' -> NOT", "NOT", lambda: edit(REAL_R[1], "end.json", lambda d: d.pop("kind")))
    c("real: a resume's walk.json gained a step -> NOT", "NOT",
      lambda: edit(REAL_R[1], "walk.json", lambda d: d["steps"].append({"name": "21 extra", "do": [], "expect": []})))
    c("real: a resume's observation edited behind its stored SAME -> NOT", "NOT",
      lambda: edit(REAL_R[1], "13.restored.obs.json", lambda d: d["fields"].__setitem__("ghat.phase", '"hunt"')))
    c("real: a receipt's pid != its run's pid -> NOT", "NOT", lambda: edit(REAL_R[1], "13.gate.json", lambda d: d.__setitem__("resume_pid", 1)))
    c("real: a resume's from_point names another point -> NOT", "NOT",
      lambda: edit(REAL_R[1], "run.json", lambda d: d.__setitem__("from_point", REAL_P + "/12")))
    c("real: a resume's end.json missing -> NOT", "NOT", lambda: os.remove(os.path.join(w2, REAL_R[1], "end.json")))
    c("real: a resume's run.json names another run -> NOT", "NOT", lambda: edit(REAL_R[0], "run.json", lambda d: d.__setitem__("run", "other_run")))
    c("real: a resume's end.json claims -1 steps -> NOT", "NOT", lambda: edit(REAL_R[0], "end.json", lambda d: d.__setitem__("steps", -1)))
    c("real: a resume's end.json names another failed step -> NOT", "NOT", lambda: edit(REAL_R[0], "end.json", lambda d: d.__setitem__("failed_step", "x")))
    # the resumed-run lifecycle on the real runs: autoq (a separate process, real rejudge) names the qualified source
    if not only or only.startswith("real: autoq"):
        real_setup()
        rr = os.path.join(w2, "ghat_R")
        os.makedirs(rr)
        json.dump({"run": "ghat_R", "identity": ident, "pid": 9, "from": "x", "from_point": pid, "control": []}, open(os.path.join(rr, "run.json"), "w"))
        shutil.copy(os.path.join(w2, REAL_P, "walk.json"), os.path.join(rr, "walk.json"))
        e_ = wg.load(os.path.join(w2, REAL_P, "end.json"))
        json.dump(dict(e_, **{"from": "x"}), open(os.path.join(rr, "end.json"), "w"))
        lf = os.path.join(w2, "ghat_last_fail.json")
        json.dump({"run": "ghat_R", "point": "ghat_R/17", "step": "x", "index": 17}, open(lf, "w"))
        env = dict(os.environ, AUTOQ_LIVE=os.path.dirname(w2), AUTOQ_TEST_IDENT=json.dumps(ident),
                   AUTOQ_TEST_WALK=os.path.join(w2, REAL_P, "walk.json"), AUTOQ_TEST_GATE_HASH=wg.GATE_HASH_OVERRIDE)
        o = subprocess.run([sys.executable, os.path.join(HERE, "autoq.py"), "ghat", "--run", "ghat_R"], env=env, capture_output=True,
                           text=True, encoding="utf-8", errors="replace").stdout
        out["real: autoq SOURCE"] = rec("real: autoq: a resumed run's failure -> its qualified source, no games", "SOURCE/" + pid,
                                        "%s/%s" % (wg.load(lf).get("autoq"), wg.load(lf).get("point")), o.strip()[-100:])
    wg.GATE_HASH_OVERRIDE = None
    return out


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
    c("outcome: two malformed DONE records (no fields) -> differ", 1,
      lambda: (min(1, len(wg.outcome({"status": "DONE"}, {"status": "DONE"}, K))), wg.outcome({"status": "DONE"}, {"status": "DONE"}, K)[:1]))
    bad_o = copy.deepcopy(end)
    bad_o["outcomes"] = end["outcomes"] + ["junk"]
    c("outcome: a junk outcome entry is rejected, not filtered -> differ", 1, lambda: (min(1, len(wg.outcome(end, bad_o, K))), ""))
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
    json.dump({"run": "ghat_R", "identity": ident, "pid": 9, "from": walk["steps"][13]["name"], "from_point": pid, "control": []}, open(os.path.join(rr, "run.json"), "w"))
    shutil.copy(os.path.join(prod, "walk.json"), os.path.join(rr, "walk.json"))
    json.dump(dict(end, **{"from": "x"}), open(os.path.join(rr, "end.json"), "w"))   # the resumed run failed at the same step
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
    c("autoq: a resumed run's failure, source NOT qualified (synthetic receipts can't be rejudged) -> fresh_next", "NOT QUALIFIED",
      lambda: (aq("--run", "ghat_R") and wg.load(lf).get("autoq"), wg.load(lf).get("fresh_next")))
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
    json.dump(dict(end, failed_index=0, failed_step=walk["steps"][0]["name"], outcomes=[[0, "FAIL", "expect:x"]]), open(os.path.join(prod, "end.json"), "w"))
    json.dump({"run": "ghat_P", "point": "ghat_P/0", "step": "x"}, open(lf, "w"))
    c("autoq: no resumable point -> NOT QUALIFIED without a game", True,
      lambda: ("no resumable point" in aq("--run", "ghat_P") and "resume 1" not in open(os.path.join(PTS, "ghat_autoq.json")).read(), ""))
    json.dump(end, open(os.path.join(prod, "end.json"), "w"))
    return out


def b2_cases(only=None):
    """GPT results audit B2: the lane lock and the durable attempt book, run IN-PROCESS on the synthetic folder (no
    game can start: the producer's failure is at step 0, so no point exists to resume)."""
    import contextlib
    import io
    out = {}
    os.environ["AUTOQ_LIVE"] = W
    prod, ident, walk, end = setup()
    json.dump(dict(end, failed_index=0, failed_step=walk["steps"][0]["name"], outcomes=[[0, "FAIL", "expect:x"]]), open(os.path.join(prod, "end.json"), "w"))
    wp = os.path.join(W, "walk_now.json")
    json.dump(walk, open(wp, "w"))
    os.environ.update(AUTOQ_TEST_IDENT=json.dumps(ident), AUTOQ_TEST_WALK=wp)
    import importlib
    import autoq
    importlib.reload(autoq)
    importlib.reload(autoq.lanelock)
    for nm, fn in PATCH_AQ:
        if nm.startswith("lanelock."):
            setattr(autoq.lanelock, nm.split(".", 1)[1], fn(autoq))
        else:
            setattr(autoq, nm, fn(autoq))
    lf = os.path.join(PTS, "ghat_last_fail.json")
    book_p = os.path.join(PTS, "ghat_autoq.json")
    key = "ghat_P|%s" % wg.walk_hash(ident)

    def call(*a):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            autoq.main(["ghat"] + list(a))
        return buf.getvalue()

    def reset_lf():
        json.dump({"run": "ghat_P", "point": "ghat_P/0", "step": "x", "index": 0}, open(lf, "w"))

    def c(name, want, fn):
        if only and name != only:
            return
        for x in (book_p, autoq.LOCK):
            if os.path.exists(x):
                os.remove(x)
        reset_lf()
        try:
            got, note = fn()
        except Exception as e:
            got, note = "CRASH", repr(e)
        out[name] = rec(name, want, got, note)

    def held():
        json.dump({"token": "held", "owner": "play_walk", "pid": os.getpid(), "walk": "ghat", "at": "now"}, open(autoq.LOCK, "w"))
        o = call("--run", "ghat_P")
        return ("lane is busy" in o and not os.path.exists(book_p), o.strip()[-80:])
    c("B2: the lane lock held by a live process -> nothing done", True, held)

    def stale():
        json.dump({"token": "stale", "owner": "autoq", "pid": 999999, "walk": "ghat", "at": "then"}, open(autoq.LOCK, "w"))
        o = call("--run", "ghat_P")
        return (os.path.exists(book_p) and not os.path.exists(autoq.LOCK), o.strip()[-80:])
    c("B2: a stale lock (process gone) is taken over, released after", True, stale)

    def interrupted():
        json.dump({key: {"attempts": [{"status": "running", "pid": 999999, "verdict": None}]}}, open(book_p, "w"))
        o = call("--run", "ghat_P")
        a = wg.load(book_p)[key]["attempts"]
        return ("%d/%s" % (len(a), a[0]["status"]), o.strip()[-90:])
    c("B2: an interrupted attempt is kept and named; a plain call launches nothing", "1/interrupted", interrupted)

    def again():
        call("--run", "ghat_P")
        reset_lf()
        call("--again")
        a = wg.load(book_p)[key]["attempts"]
        return (len(a), [x.get("verdict", "")[:30] for x in a])
    c("B2: --again appends an attempt (history kept)", 2, again)

    def play_refused():
        real_lock = os.path.join(ROOT, "appdata", "playtest", "FindingNaresh", "live", "lane.lock")
        if os.path.exists(real_lock):
            return ("SKIPPED", "a real lock exists")
        json.dump({"token": "held", "owner": "autoq", "pid": os.getpid(), "walk": "ghat", "at": "now"}, open(real_lock, "w"))
        try:
            r = subprocess.run(["bash", os.path.join(ROOT, "tools", "play_walk.sh"), "zz_no_such_walk"], cwd=ROOT,
                               capture_output=True, text=True, encoding="utf-8", errors="replace",
                               env=dict(os.environ, AUTOQ_LIVE="", AUTOQ_CHILD=""))
        finally:
            os.remove(real_lock)
        return (r.returncode, (r.stdout + r.stderr).strip()[-80:])
    c("B2: play_walk.sh refuses a game while the lane's qualification runs (exit 3)", 3, play_refused)

    def under_walk():
        # a walk owns the lane and calls autoq with its token: autoq acts under it and does NOT release it
        tok, _h = autoq.lanelock.acquire("play_walk", os.getpid(), "ghat", W)
        os.environ["LANE_TOKEN"] = tok
        try:
            o = call("--run", "ghat_P")
            return (os.path.exists(book_p) and autoq.lanelock.verify(tok, W), o.strip()[-60:])
        finally:
            os.environ["LANE_TOKEN"] = ""
            autoq.lanelock.release(tok, W)
    c("B2: autoq under a walk's lane token acts, and leaves the walk's ownership in place", True, under_walk)

    def walk_holds():
        # an ordinary walk owns the lane: a standalone autoq (no token) does nothing
        tok, _h = autoq.lanelock.acquire("play_walk", os.getpid(), "ghat", W)
        try:
            o = call("--again")
            return ("lane is busy" in o and not os.path.exists(book_p), o.strip()[-60:])
        finally:
            autoq.lanelock.release(tok, W)
    c("B2: an ordinary walk owns the lane -> a standalone autoq does nothing", True, walk_holds)

    def race():
        # GPT re-check: two callers on ONE stale lock at the same instant; exactly one may win (20 rounds, real files)
        import threading
        wins = []
        for _ in range(20):
            if os.path.exists(autoq.LOCK):
                os.remove(autoq.LOCK)
            json.dump({"token": "stale", "owner": "x", "pid": 999999, "walk": "ghat", "at": "then"}, open(autoq.LOCK, "w"))
            bar = threading.Barrier(2)
            got = {}

            def go(nm):
                bar.wait()
                got[nm] = autoq.lanelock.acquire(nm, os.getpid(), "ghat", W)[0] is not None
            ts = [threading.Thread(target=go, args=(n,)) for n in ("A", "B")]
            [t.start() for t in ts]
            [t.join() for t in ts]
            wins.append(sum(got.values()))
            os.remove(autoq.LOCK)
        return (max(wins), "winners per round: %s" % wins)
    c("B2: two callers on one stale lock (20 rounds): at most one winner", 1, race)

    def last_fail_array():
        json.dump(["not", "a", "record"], open(lf, "w"))
        o = call("--run", "ghat_P")
        d = wg.default_start(PTS, walk, ident)
        return ("%s/%s" % ("malformed" in o, d["mode"]), d["why"][:60])
    c("B1: a last_fail that is an array -> autoq does nothing, the start is fresh (no crash)", "True/fresh", last_fail_array)

    def cut_publication():
        # the verdict was written to the book, then the process was cut before last_fail: a plain call publishes it
        json.dump({key: {"attempts": [{"status": "done", "verdict": "QUALIFIED", "point": "ghat_P/13", "k": 13,
                                       "step_k": walk["steps"][13]["name"]}]}}, open(book_p, "w"))
        call("--run", "ghat_P")
        d = wg.load(lf)
        return ("%s/%s" % (d.get("autoq"), d.get("point")), "")
    c("B2: a verdict recorded but not published (cut) -> the next call publishes it", "QUALIFIED/ghat_P/13", cut_publication)

    def deleted_stays_deleted():
        os.remove(lf)                     # a newer walk passed and removed it
        autoq.finish("ghat", "ghat_P", {"run": "ghat_P"}, "QUALIFIED", point="ghat_P/13")
        return (os.path.exists(lf), "")
    c("B2: a last_fail deleted by a newer passing walk is not recreated", False, deleted_stays_deleted)
    os.environ["AUTOQ_LIVE"] = ""
    return out


PATCH_AQ = []    # (name, fn(autoq) -> replacement): the B2 guard-off pass fills it


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
    ("validate_end", "outcome: two malformed DONE records (no fields) -> differ", lambda: setattr(wg, "validate_end", lambda e: [])),
]
B2_GUARDS = [     # the B2 guards, in-process
    ("the lane lock (owner alive)", "B2: the lane lock held by a live process -> nothing done",
     ("lanelock.pid_alive", lambda aq: (lambda pid: False))),
    ("the safe stale takeover", "B2: two callers on one stale lock (20 rounds): at most one winner",
     ("lanelock.SAFE_TAKEOVER", lambda aq: False)),
    ("attempts kept (no silent relaunch)", "B2: an interrupted attempt is kept and named; a plain call launches nothing",
     ("book_attempts", lambda aq: (lambda book, key: []))),
]
REAL_GUARDS = [   # the B1 guards, on the real saved runs
    ("rejudge (a stored verdict never trusted)", "real: a resume's observation edited behind its stored SAME -> NOT",
     lambda: setattr(wg, "TRUST_STORED_VERDICT", True)),
    ("run-folder binding (pid)", "real: a receipt's pid != its run's pid -> NOT", lambda: setattr(wg, "BIND_RUN_FOLDER", False)),
]


def main():
    need = [F3] + [os.path.join(REAL, r) for r in (REAL_P,) + REAL_R]
    miss = [x for x in need if not os.path.isdir(x)]
    if miss:
        # the evidence is run data (appdata/, not in git): copy the saved ghat runs from the copy that made them
        print("autoq controls: the saved ghat runs are missing here: %s" % ", ".join(os.path.basename(x) for x in miss))
        print("  copy them from ../dev/appdata/playtest/FindingNaresh/live/points/ (or set AQ_SRC / AQ_REAL); TEST, not a verdict")
        return 2
    prod, ident, walk, end = setup()
    cases(prod, ident, walk, end)
    print("--- the rejudge on the real saved ghat runs (GPT results audit B1)")
    wg.TRUST_STORED_VERDICT = False
    real_cases()
    print("--- the lane lock and the attempt book (GPT results audit B2)")
    b2_cases()
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
    for gname, case, patch in B2_GUARDS:
        importlib.reload(wg)
        PATCH_AQ[:] = [patch]
        print("guard OFF: %s" % gname, flush=True)
        n0 = len(RES)
        b2_cases(only=case)
        got_bad = len(RES) > n0 and not RES[-1]
        del RES[n0:]
        rec("  guard '%s' seen failing when off" % gname, True, got_bad)
    PATCH_AQ[:] = []
    for gname, case, off in REAL_GUARDS:
        importlib.reload(wg)
        off()
        print("guard OFF: %s" % gname, flush=True)
        n0 = len(RES)
        real_cases(only=case)
        got_bad = len(RES) > n0 and not RES[-1]
        del RES[n0:]
        rec("  guard '%s' seen failing when off" % gname, True, got_bad)
    importlib.reload(wg)
    print("autoq offline controls: %d / %d as expected" % (sum(RES), len(RES)))
    return 0 if all(RES) else 1


if __name__ == "__main__":
    sys.exit(main())
