"""T4 v2 offline controls (no game): every gate / join guard refuses its planted failure AND passes its
clean case. Source evidence is real: a gateprobe run's points (default: A3, appdata/.../points/
gateprobe_20261111_122158_4980; point 1 = stopped, engine off; point 4 = engine on) and, for the
`join` group, the control take of t4_join_controls.py (two real rec25 takes). Mutations are made on
copies under appdata/t4ctl/ (the evidence itself is never changed).

  python tools/method/t4_controls.py [ident inv refuse hear work child l2 l3 join ...]
Each case prints want / got; exit 1 if any case disagrees.
"""
import copy
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import walkgate as wg  # noqa: E402
import t4_join_controls  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
LIVE = os.path.join(ROOT, "appdata", "playtest", "FindingNaresh", "live")
SRC = os.environ.get("T4_SRC_RUN", os.path.join(LIVE, "points", "gateprobe_20261111_122158_4980"))
CTL = os.path.join(ROOT, "appdata", "t4ctl")
RESULTS = []


def rec(case, want, got, note=""):
    ok = want == got
    RESULTS.append(ok)
    print("%-4s %-58s want %-10s got %-10s %s" % ("ok" if ok else "BAD", case, want, got, str(note)[:150]), flush=True)


def obs(k):
    return wg.load(os.path.join(SRC, "%d.obs.json" % k))


def quiet():
    """Point 1 with the van's stored velocities zeroed: the CLEAN base of the refusal cases. (The real
    point 1 is refused: the parked van is frozen on the handbrake with a stale 0.148 m/s stored velocity
    that the restore zeroes; found by these controls, 2026-11-14. No real eligible point exists here.)"""
    o = copy.deepcopy(obs(1))
    o["fields"]["van.@lv"] = "Vector3(0, 0, 0)"
    o["fields"]["van.@av"] = "Vector3(0, 0, 0)"
    return o


def t3(k):
    return wg.load(os.path.join(SRC, "%d.t3.json" % k))


def v(why):
    return "REFUSED" if why else "ADMIT"


def d(diffs):
    return "DIFFERENT" if diffs else "SAME"


def copyrun(case):
    dst = os.path.join(CTL, case, os.path.basename(SRC))
    if os.path.isdir(os.path.dirname(dst)):
        shutil.rmtree(os.path.dirname(dst))
    shutil.copytree(SRC, dst)
    return dst


# ---- identity -----------------------------------------------------------------------------------
def g_ident():
    rj = wg.load(os.path.join(SRC, "run.json"))
    walk = wg.load(os.path.join(SRC, "walk.json"))
    idn = dict(rj["identity"])
    pts = os.path.dirname(SRC)
    pid = "%s/1" % os.path.basename(SRC)
    step = walk["steps"][1]["name"]
    why, k, _, _ = wg.admit(pts, walk, step, pid, idn)
    rec("ident REAL point 1 (identity fine, frozen van's stored velocity)", "REFUSED", v(why), why)
    why = wg.identity_check(SRC, 1, idn, walk, idn["profile"])
    rec("ident clean: same game/test/bin/schema/profile/walk", "ADMIT", v(why), why)
    b = wg.boundary(SRC, 1, [])
    rec("ident clean admitted -> evaluation only, not SAME", "NOT SAME", "SAME" if b["verdict"] == "SAME" else "NOT SAME", b["verdict"])
    for key, val in (("game", "0000old0game0000"), ("test", "0000old0test0000"), ("bin", "0000other0bin00"),
                     ("schema", "t4v2-gate-0"), ("profile", "rec25")):
        i2 = dict(idn)
        i2[key] = val
        # F2: the identity check alone (the real point 1 is refused anyway for its stale van velocity, so
        # going through admit() could not show the identity check missing)
        why = wg.identity_check(SRC, 1, i2, walk, i2["profile"])
        rec("ident %s changed" % key, "REFUSED", v(why), why)
    w2 = copy.deepcopy(walk)
    w2["steps"][0]["do"][1]["s"] = 3.5
    why = wg.identity_check(SRC, 1, idn, w2, idn["profile"])
    rec("ident producer step (before the point) changed", "REFUSED", v(why), why)
    w3 = copy.deepcopy(walk)
    w3["steps"][1]["do"][1]["s"] = 4.5
    why = wg.identity_check(SRC, 1, idn, w3, idn["profile"])
    rec("ident resumed step changed (its fresh reference stale)", "REFUSED", v(why), why)
    # F2: the same changes through admit() on the quiet point (velocity zeroed): admit refuses them by identity alone
    qrun = copyrun("ident_quiet")
    json.dump(quiet(), open(os.path.join(qrun, "1.obs.json"), "w", encoding="utf-8"))
    qpts = os.path.dirname(qrun)
    why, *_ = wg.admit(qpts, walk, step, pid, idn)
    rec("ident admit clean: quiet point 1, nothing changed", "ADMIT", v(why), why)
    i2 = dict(idn)
    i2["game"] = "0000old0game0000"
    why, *_ = wg.admit(qpts, walk, step, pid, i2)
    rec("ident admit: quiet point 1, game changed", "REFUSED", v(why), why)
    w4 = copy.deepcopy(walk)
    w4["steps"][3]["do"][1]["s"] = 9.0
    why = wg.identity_check(SRC, 1, idn, w4, idn["profile"])
    rec("ident a LATER step changed (point still compatible)", "ADMIT", v(why), why)
    why, *_ = wg.admit(pts, walk, step, "%s/2" % os.path.basename(SRC), idn)
    rec("ident wrong point (index 2 for step index 1)", "REFUSED", v(why), why)
    why, *_ = wg.admit(pts, walk, step, "gateprobe_19990101_000000_1/1", idn)
    rec("ident point ID that does not exist", "REFUSED", v(why), why)
    why, *_ = wg.admit(pts, walk, step, "", idn)
    rec("ident no point ID", "REFUSED", v(why), why)
    c = copyrun("ident_noobs")
    os.remove(os.path.join(c, "1.obs.json"))
    why, *_ = wg.admit(os.path.dirname(c), walk, step, pid, idn)
    rec("ident the point's observation missing", "REFUSED", v(why), why)


# ---- layer 1 inventory --------------------------------------------------------------------------
def g_inv():
    o = obs(1)
    rec("inv clean point 1: every field classified, required observed", "ADMIT", v(wg.layer1(o)), wg.layer1(o))
    o2 = copy.deepcopy(o)
    del o2["fields"]["van.engine_on"]
    rec("inv van.engine_on observation removed", "REFUSED", v(wg.layer1(o2)), wg.layer1(o2))
    o3 = copy.deepcopy(o)
    o3["fields"]["van.new_thing"] = "1"
    o3["fields"]["mystery.x"] = "1"
    l = wg.layer1(o3)
    rec("inv an unclassified field (mystery.x)", "REFUSED", v([x for x in l if "mystery" in x]), l)
    o4 = copy.deepcopy(o)
    o4["fields"]["problem.@xf"] = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)"
    o4["fields"]["problem.state"] = "\"stalk\""
    l = wg.layer1(o4)
    rec("inv Problem out, its children not observed", "REFUSED", v(l), l)
    o5 = copy.deepcopy(o4)
    o5["fields"]["problem/Eyes.@mat"] = "emission 1.0"
    o5["fields"]["problem/Hum.@audio"] = "playing pitch 1.0"
    l = wg.layer1(o5)
    rec("inv Problem out, children observed (layer 1 alone)", "ADMIT", v(l), l)


# ---- boundary refusal (engine / velocity) ------------------------------------------------------
def g_refuse():
    rec("refuse REAL point 1: frozen van, stale stored 0.148 m/s", "REFUSED", v(wg.refusal(obs(1))), wg.refusal(obs(1)))
    rec("refuse clean: point 1 with zero stored velocity", "ADMIT", v(wg.refusal(quiet())), wg.refusal(quiet()))
    rec("refuse engine-on point 4 (real)", "REFUSED", v(wg.refusal(obs(4))), wg.refusal(obs(4)))
    o = quiet()
    o["fields"]["van.@lv"] = "Vector3(0.12, 0, 0)"
    rec("refuse van at 0.12 m/s", "REFUSED", v(wg.refusal(o)), wg.refusal(o))
    o["fields"]["van.@lv"] = "Vector3(0.09, 0, 0)"
    r = wg.refusal(o)
    rec("refuse van at 0.09 m/s passes the prefilter", "ADMIT", v(r), r)
    p = quiet()
    l2 = wg.layer2(o, p)
    rec(" ... but layer 2 still names the lost velocity", "DIFFERENT", d(l2), l2[:2])
    o = quiet()
    o["fields"]["item[Crate0].@lv"] = "Vector3(0.3, 0, 0)"
    rec("refuse a carryable moving (contacts unsupported)", "REFUSED", v(wg.refusal(o)), wg.refusal(o))
    o = quiet()
    o["fields"]["problem.@xf"] = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)"
    rec("refuse Problem out (global RNG + listener serial: D4 A)", "REFUSED", v(wg.refusal(o)), wg.refusal(o))
    o = quiet()
    o["fields"]["tree.@tweens"] = "1"
    rec("refuse a running tween", "REFUSED", v(wg.refusal(o)), wg.refusal(o))


# ---- hearing (no rebase) -----------------------------------------------------------------------
def _hear(recent, heard=None, item_ms=None, now=True):
    o = quiet()
    o["fields"]["static.Hearing.recent"] = json.dumps(recent)
    if heard is not None:
        o["fields"]["listener._heard_id"] = str(heard)
    if item_ms is not None:
        o["fields"]["problem._item_ms"] = str(item_ms)
    if not now:
        o["meta"].pop("wall_ms", None)
    return o


def g_hear():
    now = obs(1)["meta"]["wall_ms"]
    rec("hear quiet: empty queue, nothing unconsumed", "ADMIT", v(wg.refusal(_hear([]))), wg.refusal(_hear([])))
    r = wg.refusal(_hear([{"id": 1, "t": now - 600, "what": "item", "pos": [0, 0, 0]}]))
    rec("hear a sound 0.6 wall s old", "REFUSED", v(r), r)
    o = _hear([{"id": 7, "t": now - 60000, "what": "item", "pos": [0, 0, 0]}], heard=5)
    o["fields"].pop("listener._heard_id")
    o["fields"]["ghat.x._heard_id"] = "5"
    r = wg.refusal(o)
    rec("hear old (60 s) but unconsumed by a listener (id 7 > 5)", "REFUSED", v(r), r)
    o = _hear([{"id": 7, "t": now - 60000, "what": "item", "pos": [0, 0, 0]}], heard=None)
    r = wg.refusal(o)
    rec("hear old (60 s), no listener to consume it", "ADMIT", v(r), r)
    o = _hear([], item_ms=now + 40000)
    o["fields"].pop("problem._item_ms")
    o["fields"]["item[Crate0]._last_hit_t"] = str(now + 40000)
    r = wg.refusal(o)
    rec("hear stale-origin stamp (from another process' clock)", "REFUSED", v(r), r)
    o = _hear([])
    o["fields"]["item[Crate0]._last_hit_t"] = str(now - 100)
    r = wg.refusal(o)
    rec("hear knock debounce 100 ms old (window 150)", "REFUSED", v(r), r)
    o = _hear([])
    o["fields"]["item[Crate0]._last_hit_t"] = str(now - 5000)
    r = wg.refusal(o)
    rec("hear knock debounce expired (5 s)", "ADMIT", v(r), r)
    r = wg.refusal(_hear([], now=False))
    rec("hear no wall clock in the observation", "REFUSED", v(r), r)


# ---- open work ---------------------------------------------------------------------------------
def g_work():
    for f, val, nm in (("test.@open_watches", "[\"the van stays\"]", "one open watch"),
                       ("test.@needs", "[\"step 3\"]", "a need not met"),
                       ("test.@helpers_running", "1", "a helper running"),
                       ("input.@held", "[\"key:4194326\"]", "CTRL held")):
        o = quiet()
        o["fields"][f] = val
        r = wg.refusal(o)
        rec("work %s" % nm, "REFUSED", v(r), r)
    o = copy.deepcopy(obs(4))
    rec("work empty lists alone do not pass (point 4: engine on)", "REFUSED", v(wg.refusal(o)), wg.refusal(o))


# ---- owner-built director / children (layer 2 on the Problem's parts) --------------------------
def _with_problem(o):
    o = copy.deepcopy(o)
    f = o["fields"]
    f["problem.director"] = "callable:Ghat::_director"
    f["problem.@xf"] = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0, 5)"
    f["problem/Eyes.@mat"] = "emission 1.0"
    f["problem/Hum.@audio"] = "playing pitch 1.0"
    f["problem/Body.@xf"] = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0, 5)"
    return o


def g_child():
    a = _with_problem(obs(1))
    rec("child clean reconstruction (same children / reference)", "SAME", d(wg.layer2(a, copy.deepcopy(a))))
    b = copy.deepcopy(a)
    del b["fields"]["problem/Hum.@audio"]
    rec("child hum not rebuilt (omitted)", "DIFFERENT", d(wg.layer2(a, b)), wg.layer2(a, b))
    b = copy.deepcopy(a)
    b["fields"]["problem/Eyes.@mat"] = "emission 0.0"
    rec("child eye emission changed", "DIFFERENT", d(wg.layer2(a, b)), wg.layer2(a, b))
    b = copy.deepcopy(a)
    b["fields"]["problem.director"] = "null"
    rec("child director reference not resolved", "DIFFERENT", d(wg.layer2(a, b)), wg.layer2(a, b))
    b = copy.deepcopy(a)
    b["fields"]["problem/Body.@xf"] = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0.2, 5)"
    rec("child body pose moved", "DIFFERENT", d(wg.layer2(a, b)), wg.layer2(a, b))


# ---- layer 2 -----------------------------------------------------------------------------------
def g_l2():
    a = obs(1)
    rec("l2 clean: the point vs its own copy", "SAME", d(wg.layer2(a, copy.deepcopy(a))))
    for f, val, nm in (("van.engine_on", "true", "engine lost (on -> off)"),
                       ("van.@lv", "Vector3(0.03, 0, 0)", "residual velocity lost"),
                       ("van.@av", "Vector3(0, 0.02, 0)", "angular velocity lost"),
                       ("van.@sleeping", "true", "sleep state lost"),
                       ("ghat.phase_t", "1.5", "a clock (ghat.phase_t)"),
                       ("static.Hearing.recent", json.dumps([{"id": 9, "t": a["meta"]["wall_ms"] - 10, "what": "item", "pos": [0, 0, 0]}]), "the hearing queue")):
        b = copy.deepcopy(a)
        b["fields"][f] = val
        l = wg.layer2(b, a)
        rec("l2 %s" % nm, "DIFFERENT", d(l), [x[0] for x in l])
    b = copy.deepcopy(a)
    b["fields"]["van.attack.last_honk_ms"] = "123456"
    l = wg.layer2(a, b)
    rec("l2 documented volatile only (last_honk_ms) -> normalised", "SAME", d(l), l)


# ---- layer 3 -----------------------------------------------------------------------------------
def _xf_shift(s, dx):
    n = wg.nums(s)
    n[9] += dx
    return "Transform3D(%s)" % ", ".join(repr(x) for x in n)


def g_l3():
    f = t3(1)
    rec("l3 clean: fresh vs its own copy", "SAME", d(wg.layer3(f, copy.deepcopy(f))))
    b = copy.deepcopy(f)
    b["obs"]["fields"]["ghat.phase"] = "\"stop\""
    rec("l3 wrong discrete (ghat.phase)", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    b = copy.deepcopy(f)
    b["obs"]["fields"]["van.@xf"] = _xf_shift(b["obs"]["fields"]["van.@xf"], 0.2)
    rec("l3 van 0.2 m off", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    b = copy.deepcopy(f)
    b["obs"]["fields"]["van.@xf"] = _xf_shift(b["obs"]["fields"]["van.@xf"], 0.03)
    rec("l3 van 0.03 m off (inside 0.05)", "SAME", d(wg.layer3(f, b)), wg.layer3(f, b))
    fm = copy.deepcopy(f)
    fm["messages"] = [[500, "p1", "sees", "a note"], [900, "p2", "hears", "a knock"]]
    b = copy.deepcopy(fm)
    b["messages"] = [b["messages"][1], b["messages"][0]]
    rec("l3 event order swapped", "DIFFERENT", d(wg.layer3(fm, b)), wg.layer3(fm, b))
    b = copy.deepcopy(f)
    b["inputs"] = [[x[0] + 150] + x[1:] for x in b["inputs"]]
    rec("l3 delayed input (+150 game ms)", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    b = copy.deepcopy(f)
    b["inputs"] = b["inputs"][:1]
    rec("l3 an input missing", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    b = copy.deepcopy(f)
    b["failed_before"] = "FAIL x"
    rec("l3 a FAIL before +3 s", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    b = copy.deepcopy(f)
    b["at_game_ms"] = 2500
    rec("l3 sample taken early (2.5 s)", "DIFFERENT", d(wg.layer3(f, b)), wg.layer3(f, b))
    rec("l3 no fresh reference", "DIFFERENT", d(wg.layer3(None, f)), wg.layer3(None, f))


GROUPS = {"ident": g_ident, "inv": g_inv, "refuse": g_refuse, "hear": g_hear, "work": g_work, "child": g_child,
          "l2": g_l2, "l3": g_l3, "join": lambda: t4_join_controls.g_join(rec)}


def main(a):
    os.makedirs(CTL, exist_ok=True)
    for g in (a or list(GROUPS)):
        print("== %s" % g)
        GROUPS[g]()
    bad = RESULTS.count(False)
    print("T4 offline controls: %d / %d as expected" % (RESULTS.count(True), len(RESULTS)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
