"""Resume fix v1 offline controls (no game): every new admission rule refuses its planted case with the
intended reason AND admits / passes its clean case (GPT audit #7). Evidence: the replay's real ghat point 13
(start of step 14: Problem out and leaving, van frozen with a stale stored speed, tarp hearing events
unconsumed), copied read-only to appdata/rv1ctl/src; the rv1 record is synthetic (built here like ResumeV1.gd
writes it) until a live rv1 point exists (then: RV1_SRC=<run dir> RV1_K=<k>).

  python tools/method/rv1_controls.py           -> one line per case, exit 1 if any disagrees
"""
import copy
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import walkgate as wg  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
# the real rv1 point 13 of producer F2 (ghat_rp14_20261117_210651_22032), copied read-only (GPT results audit #4b:
# the synthetic record of v1 of these controls was itself incomplete)
SRC = os.environ.get("RV1_SRC", os.path.join(ROOT, "appdata", "rv1ctl", "src2"))
K = int(os.environ.get("RV1_K", "13"))
CTL = os.path.join(ROOT, "appdata", "rv1ctl", "work")
RESULTS = []


def rec(case, want, got, note=""):
    ok = want == got
    RESULTS.append(ok)
    print("%-4s %-66s want %-9s got %-9s %s" % ("ok" if ok else "BAD", case, want, got, str(note)[:140]), flush=True)


def obs():
    return wg.load(os.path.join(SRC, "%d.obs.json" % K))


def point():
    p = wg.load(os.path.join(SRC, "%d.json" % K))
    if p.get("resume_v") is None:
        # a synthetic rv1 record of the same shape ResumeV1.collect writes
        p.update({"resume_v": "rv1", "seed_proto": "seed-v1", "rng_seed": 12345, "wall_ms": 1000,
                  "live_bodies": [{"key": "van", "freeze": True, "freeze_mode": 0, "sleeping": False,
                                   "lv": "Vector3(0, 0, 0)", "av": "Vector3(0, 0, 0)"}],
                  "live_vars": {"van": {"engine_on": "false"}, "attack": {}, "items": {}, "players": [{}, {}]},
                  "live_players": [{"xf": "x", "vel": "v"}, {"xf": "x", "vel": "v"}],
                  "live_clock": [{"own": "problem", "field": "_item_ms", "unit": "ms", "unset": True}],
                  "live_hearing": {"next_id": 207, "events": [{"id": 206, "pos": "Vector3(0, 0, 0)", "radius": 20.0, "what": "tarp", "age": 100}]},
                  "live_problem_children": {"count": 12, "xf": {}, "vars": {}},
                  "live_frames": [], "phys_frame": 100, "live_refs": {"targets": ["", ""], "window_fog": {}}})
    return p


def verdict(r):
    return "REFUSED" if r else "ADMIT"


def has(r, text):
    return any(text in x for x in r)


def setf(o, **kw):
    o = copy.deepcopy(o)
    for k, v in kw.items():
        o["fields"][k.replace("__", ".").replace("_AT_", "@")] = v
    return o


def main():
    o, p = obs(), point()
    f = o["fields"]
    # --- the baseline: the real point, no rv1 record: today's refusals
    r = wg.refusal(o, None, None)
    rec("base: real P13, no rv1 record -> refused (listener, RNG)", "REFUSED", verdict(r), "; ".join(r)[:140])
    rec("base: ... names the listener", True, has(r, "listener (Problem) is out"))
    # --- clean rv1
    r = wg.refusal(o, None, p)
    rec("rv1 clean: same point + a valid record -> admitted", "ADMIT", verdict(r), "; ".join(r))
    # --- malformed records (fail closed, the intended reason)
    for name, mut in [("no live_hearing", lambda q: q.pop("live_hearing")),
                      ("hearing event without age", lambda q: q["live_hearing"]["events"][0].pop("age")),
                      ("no Problem children record", lambda q: q.pop("live_problem_children")),
                      ("seed protocol seed-v0", lambda q: q.update(seed_proto="seed-v0")),
                      ("no rng_seed", lambda q: q.pop("rng_seed")),
                      ("one player only", lambda q: q["live_players"].pop()),
                      ("bodies without the van", lambda q: q.update(live_bodies=[])),
                      ("clock entry unit 'min'", lambda q: q["live_clock"].append({"own": "van", "field": "_cap_t", "unit": "min", "unset": False, "age": 1})),
                      ("resume_v rv0", lambda q: q.update(resume_v="rv0")),
                      ("no live_frames", lambda q: q.pop("live_frames")),
                      ("no live_refs", lambda q: q.pop("live_refs"))]:
        q = copy.deepcopy(p)
        mut(q)
        r = wg.refusal(o, None, q)
        rec("rv1 malformed: %s" % name, "REFUSED", verdict(r), "; ".join(r)[:140])
        rec("  ... reason 'rv1 record malformed'", True, has(r, "rv1 record malformed"))
    # --- refusals that stay (GPT audit #4 / #5)
    for name, kw, reason in [("Problem crouched (sniff draws randf)", {"problem.pose": '"crouch"'}, "global_rng_problem"),
                             ("ghat phase circle (not leaving)", {"ghat.phase": '"circle"'}, "global_rng_problem"),
                             ("Problem not passive", {"problem.passive": "false"}, "global_rng_problem"),
                             ("p1 shaking (per-frame randf)", {"p1._shake_t": "0.12"}, "global_rng_problem"),
                             ("p2 holds the pot", {"p2.held": "node:/root/Main/World/GhatPot2"}, "p2 holds a carryable"),
                             ("p1 crouching", {"p1.crouching": "true"}, "p1 crouching"),
                             ("p2 on a ladder", {"p2.ladder": "node:/root/Main/World/Ladder"}, "p2 on a ladder"),
                             ("engine on", {"van.engine_on": "true"}, "engine on"),
                             ("van unfrozen, 0.2 m/s", {"van.@freeze": "false", "van.@lv": "Vector3(0.2, 0, 0)"}, "van moving"),
                             ("a running tween", {"tree.@tweens": "1"}, "tweens running"),
                             ("a held input", {"input.@held": '["key:87"]'}, "inputs held")]:
        q = copy.deepcopy(o)
        q["fields"].update(kw)
        r = wg.refusal(q, None, p)
        rec("rv1 still refused: %s" % name, "REFUSED", verdict(r), "; ".join(r)[:140])
        rec("  ... reason '%s'" % reason, True, has(r, reason))
    q = copy.deepcopy(o)
    q["fields"].update({"van.@freeze": "true", "van.@lv": "Vector3(0.15, 0, 0)"})
    rec("rv1 admits a FROZEN van with a stale 0.15 m/s stored", "ADMIT", verdict(wg.refusal(q, None, p)))
    rec("no rv1: the same frozen 0.15 m/s still refused", "REFUSED", verdict(wg.refusal(q, None, None)))
    # --- layer 2: ages, ids, serial (the hearing restore)
    now = o["meta"]["wall_ms"]
    rq = json.loads(f["static.Hearing.recent"])
    rec("evidence: P13 has hearing events queued", True, len(rq) > 0, len(rq))
    rec("layer 2: the point against itself", "SAME", "SAME" if not wg.layer2(o, o) else "DIFFERENT")

    def shifted(ms):
        q = copy.deepcopy(o)
        q["meta"]["wall_ms"] = now + ms
        q["fields"]["static.Hearing.recent"] = json.dumps([dict(e, t=e["t"] + ms + (0 if ms_age is None else ms_age)) for e in rq])
        return q
    ms_age = None
    rec("layer 2: clocks rebased (+60 s, same ages)", "SAME", "SAME" if not wg.layer2(o, shifted(60000)) else "DIFFERENT",
        wg.layer2(o, shifted(60000))[:2])
    ms_age = -15
    rec("layer 2: hearing ages 15 ms older (tolerance 20)", "SAME", "SAME" if not wg.layer2(o, shifted(60000)) else "DIFFERENT")
    ms_age = -30
    d = wg.layer2(o, shifted(60000))
    rec("layer 2: hearing ages 30 ms older", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    ms_age = None
    q = copy.deepcopy(o)
    q["fields"]["static.Hearing.recent"] = json.dumps([dict(e, t=e["t"] - 600000) for e in rq])
    d = wg.layer2(o, q)
    rec("layer 2: hearing NOT restored (old-process stamps)", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    q = copy.deepcopy(o)
    q["fields"]["static.Hearing.recent"] = json.dumps([dict(e, id=e["id"] + 3) for e in rq])
    d = wg.layer2(o, q)
    rec("layer 2: hearing ids shifted (serial lost)", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    q = setf(o, **{"static.Hearing._next_id": "1"})
    d = wg.layer2(o, q)
    rec("layer 2: hearing serial reset to 1 (Problem out)", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    # wall-stamp windows: same side of the window and within 20 ms
    for name, field, pv, rv_, want in [("_item_ms 1490 vs 1495 ms old (window 1500)", "problem._item_ms", 1490, 1495, "SAME"),
                                       ("_item_ms 1495 vs 1505 ms old (crosses 1500)", "problem._item_ms", 1495, 1505, "DIFFERENT"),
                                       ("_item_ms 1000 vs 1040 ms old", "problem._item_ms", 1000, 1040, "DIFFERENT"),
                                       ("_cap_t 2.990 vs 2.995 s old (window 3 s)", "van._cap_t", 2.990, 2.995, "SAME"),
                                       ("_cap_t 2.995 vs 3.005 s old (crosses 3 s)", "van._cap_t", 2.995, 3.005, "DIFFERENT")]:
        a, b = copy.deepcopy(o), copy.deepcopy(o)
        if field == "van._cap_t":
            a["fields"][field] = repr(now / 1000.0 - pv)
            b["fields"][field] = repr(now / 1000.0 - rv_)
        else:
            a["fields"][field] = str(int(now - pv))
            b["fields"][field] = str(int(now - rv_))
        d = wg.layer2(a, b)
        rec("layer 2: %s" % name, want, "SAME" if not d else "DIFFERENT", d[:1])
    q = setf(o, **{"problem._item_ms": "-99999"})
    a = setf(o, **{"problem._item_ms": "-99999"})
    rec("layer 2: _item_ms unset (-99999) both sides", "SAME", "SAME" if not wg.layer2(a, q) else "DIFFERENT")
    # stored velocity: exact (restored, not zeroed)
    q = setf(o, **{"van.@lv": "Vector3(0, 0, 0)"})
    rec("layer 2: the van's stale stored speed zeroed by a restore", "DIFFERENT", "SAME" if not wg.layer2(o, q) else "DIFFERENT")
    q = setf(o, **{"p2.@capsule": "1.0:Vector3(0, 0.5, 0):false"})
    a = setf(o, **{"p2.@capsule": "1.8:Vector3(0, 0.9, 0):false"})
    rec("layer 2: a player's capsule height differs", "DIFFERENT", "SAME" if not wg.layer2(a, q) else "DIFFERENT")
    # GPT results audit #4a: an unconsumed hearing event either side of Hearing's 2000 ms prune boundary
    def hq(age, base=o):
        q = copy.deepcopy(base)
        ev = [{"id": 999, "t": q["meta"]["wall_ms"] - age, "what": "step", "pos": "Vector3(0, 0, 0)", "r": 8.0}]
        q["fields"]["static.Hearing.recent"] = json.dumps(ev)
        q["fields"]["static.Hearing._next_id"] = "1000"
        return q
    for a_, b_, want in ((1995, 2005, "DIFFERENT"), (2000, 2001, "DIFFERENT"), (1990, 2000, "SAME"), (2005, 2015, "SAME")):
        d = wg.layer2(hq(a_), hq(b_))
        rec("hearing: unconsumed event %d vs %d ms old (prune > 2000)" % (a_, b_), want, "SAME" if not d else "DIFFERENT", d[:1])
    # GPT results audit #4b: records with missing CONTENT (not just missing containers)
    for name, mut in [("live_frames empty", lambda q: q.update(live_frames=[])),
                      ("live_refs empty", lambda q: q.update(live_refs={})),
                      ("live_clock empty", lambda q: q.update(live_clock=[])),
                      ("Problem children count 99, no poses", lambda q: q.update(live_problem_children={"count": 99})),
                      ("every body without xf / lxf / parent", lambda q: [b.pop(k, None) for b in q["live_bodies"] for k in ("xf", "lxf", "parent")]),
                      ("one item's body record gone", lambda q: q.update(live_bodies=[b for b in q["live_bodies"] if b["key"] != "item:Crate0"])),
                      ("a clock age NaN", lambda q: q["live_clock"].__setitem__(0, dict(q["live_clock"][0], unset=False, age=float("nan"))))]:
        q = copy.deepcopy(p)
        mut(q)
        r = wg.refusal(o, None, q)
        rec("rv1 content: %s" % name, "REFUSED", verdict(r), [x for x in r if "rv1 record" in x][:1])
        rec("  ... reason 'rv1 record malformed'", True, has(r, "rv1 record malformed"))
    # physics-frame stamps: ages at the observation's frame
    def fr(base, hs, done):
        q = copy.deepcopy(o)
        q["meta"]["physics_frames"] = base
        q["fields"]["van.attack._hold_start"] = "{player:0: %d, player:1: %d}" % (base - hs[0], base - hs[1])
        q["fields"]["van.attack._done_f"] = str(done if done == -1 else base - done)
        for i_ in (1, 2):
            q["fields"]["p%d._climb_since" % i_] = "0"
        q["fields"]["van.attack._last_pull"] = "{player:0: %d, player:1: %d}" % (base - 158, base - 3250)
        return q
    rec("frames: tarp stamps rebased (other frame base, same ages)", "SAME", "SAME" if not wg.layer2(fr(16000, (380, 3471), 300), fr(900, (380, 3471), 300)) else "DIFFERENT")
    d = wg.layer2(fr(16000, (380, 3471), 300), fr(900, (381, 3471), 300))
    rec("frames: a tarp hold stamp 1 frame off", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    d = wg.layer2(fr(16000, (380, 3471), -1), fr(900, (380, 3471), 300))
    rec("frames: _done_f unset vs set", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    d = wg.layer2(fr(16000, (380, 3471), 300), dict(fr(900, (380, 3471), 300), meta=dict(o["meta"], physics_frames=900)) if False else setf(fr(900, (380, 3471), 300), **{"van.attack._hold_start": "{player:0: 15620, player:1: 12529}"}))
    rec("frames: raw stamps from the old process (not rebased)", "DIFFERENT", "SAME" if not d else "DIFFERENT", d[:1])
    # --- receipts, boundary, REPAIR (synthetic run folders under appdata/rv1ctl/work)
    shutil.rmtree(CTL, ignore_errors=True)
    pts = os.path.join(CTL, "points")
    prun = os.path.join(pts, "ghat_ctl_prod")
    os.makedirs(prun)
    ident = {"game": "g1", "bin": "b1", "tools": "t1", "testcode": "c1", "test": "w1", "schema": wg.SCHEMA, "profile": "play"}
    walk = wg.load(os.path.join(SRC, "walk.json"))
    for nm, d_ in (("walk.json", walk), ("run.json", {"identity": ident, "pid": 1})):
        json.dump(d_, open(os.path.join(prun, nm), "w"))
    json.dump(p, open(os.path.join(prun, "%d.json" % K), "w"))
    json.dump(o, open(os.path.join(prun, "%d.obs.json" % K), "w"))
    pid_ = "ghat_ctl_prod/%d" % K
    sha, gh = wg.point_sha(os.path.join(prun, "%d.json" % K)), wg.gate_hash()

    def receipt(name, pid, **over):
        rd = os.path.join(pts, name)
        os.makedirs(rd, exist_ok=True)
        r_ = {"point": pid_, "verdict": "SAME", "resume_run": name, "resume_pid": pid, "profile": "play",
              "resume_identity": dict(ident), "point_sha": sha, "gate_hash": gh, "protocol": "rv1/seed-v1"}
        r_.update(over)
        json.dump(r_, open(os.path.join(rd, "%d.gate.json" % K), "w"))

    fixed = copy.deepcopy(walk)
    fixed["steps"][K]["do"] = fixed["steps"][K]["do"][:-1] + [{"do": "wait", "s": 0.1}]
    nowid = dict(ident, test="w2")

    def repair(wk=None, idn=None):
        why, k_, _, note = wg.admit(pts, wk or fixed, walk["steps"][K]["name"], pid_, idn or nowid)
        return why, note
    receipt("r1", 11)
    why, note = repair()
    rec("REPAIR with 1 SAME receipt", "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:140])
    receipt("r2", 11)
    why, note = repair()
    rec("REPAIR with 2 receipts from ONE process", "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:140])
    receipt("r3", 13, point_sha="0000")
    why, note = repair()
    rec("REPAIR: 2nd receipt bound to other point bytes", "REFUSED", "REFUSED" if why else "ADMIT")
    receipt("r4", 14, gate_hash="0000")
    why, note = repair()
    rec("REPAIR: 2nd receipt made by another gate", "REFUSED", "REFUSED" if why else "ADMIT")
    receipt("r5", 15, verdict="DIFFERENT")
    receipt("r6", 16, protocol="rv0/seed-v1")
    receipt("r7", 17, resume_identity=dict(ident, testcode="c0"))
    why, note = repair()
    rec("REPAIR: DIFFERENT / other protocol / other test code receipts", "REFUSED", "REFUSED" if why else "ADMIT")
    receipt("r8", 18)
    why, note = repair()
    rec("REPAIR clean: 2 valid receipts, actions-only change", "ADMIT", "REFUSED" if why else "ADMIT", "; ".join(why)[:140] or note)
    rec("  ... noted as REPAIR", True, note.startswith("REPAIR"))
    w2 = copy.deepcopy(fixed)
    w2["steps"][K - 1]["do"] = w2["steps"][K - 1]["do"] + [{"do": "wait", "s": 0.1}]
    why, note = repair(w2)
    rec("REPAIR: an earlier step changed too", "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:140])
    w3 = copy.deepcopy(fixed)
    w3["steps"][K]["needs"] = ["x"]
    why, note = repair(w3)
    rec("REPAIR: the step's needs changed (not actions)", "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:140])
    for key in ("game", "testcode", "tools", "bin"):
        why, note = repair(None, dict(nowid, **{key: "changed"}))
        rec("REPAIR: %s changed since" % key, "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:120])
    why = wg.admit(pts, walk, walk["steps"][K]["name"], pid_, dict(ident))[0]
    rec("unchanged walk: gate evaluation (not REPAIR)", "ADMIT", "REFUSED" if why else "ADMIT", "; ".join(why)[:140])
    # GPT results audit #4c: the client (tools) or test code changed -> refused for a normal resume too
    for key in ("tools", "testcode"):
        why = wg.admit(pts, walk, walk["steps"][K]["name"], pid_, dict(ident, **{key: "changed"}))[0]
        rec("unchanged walk, %s changed: refused" % key, "REFUSED", "REFUSED" if why else "ADMIT", "; ".join(why)[:120])
    # boundary: one resume run listed twice counts once
    rr = os.path.join(pts, "res_dup")
    os.makedirs(rr)
    json.dump({"identity": ident, "pid": 77}, open(os.path.join(rr, "run.json"), "w"))
    json.dump(o, open(os.path.join(rr, "%d.restored.obs.json" % K), "w"))
    json.dump(o, open(os.path.join(rr, "%d.final.obs.json" % K), "w"))
    real_jr = wg.judge_resume
    wg.judge_resume = lambda pr, k, r, cfg=None: {"verdict": "SAME", "resume_run": os.path.basename(r), "resume_pid": 77, "profile": "play"}
    b_ = wg.boundary(prun, K, [rr, rr])
    rec("boundary: one SAME resume listed twice", "NOT QUALIFIED", b_["verdict"][:13], b_["verdict"])
    wg.judge_resume = real_jr
    r_ = wg.judge_resume(prun, K, rr)
    rec("receipt: the resume's identity = the producer's", [], r_["identity"])
    json.dump({"identity": dict(ident, tools="other"), "pid": 78}, open(os.path.join(rr, "run.json"), "w"))
    r_ = wg.judge_resume(prun, K, rr)
    rec("receipt: a resume run with another client -> REFUSED", "REFUSED", r_["verdict"], r_["identity"])
    # boundary: duplicate resume dirs don't count twice
    print("rv1 offline controls: %d / %d as expected" % (sum(RESULTS), len(RESULTS)))
    return 0 if all(RESULTS) else 1


if __name__ == "__main__":
    sys.exit(main())
