"""T4 v2 join verifier controls (offline, no game), used by t4_controls.py `join`.

No resume of the gateprobe walk can pass the gate (every parked-van point is refused), so no real
2-part take with a SAME join exists. The mechanics are tested on a CONTROL take built from two REAL
rec25 takes: R2's part as part 1 'failed at' step 4, R1's part as part 2 'resumed from' R2's point 3,
kept from its step 4 (real videos, frame numbers, identities; the failure and the resume are written
into the part files). It is judged with JOIN_GATE_WAIVED=1 (every rule but the gate verdict), and
without the waiver it must be refused for the gate. Never a video, never a clean walk.
"""
import json
import os
import shutil

import join_check as jc
import walkgate as wg

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
R1 = os.path.join(ROOT, "appdata", "t34", "R1_parts")      # gateprobe rec25, alone (DONE)
R2 = os.path.join(ROOT, "appdata", "t34", "R2_parts")      # gateprobe rec25, beside lane b (DONE)
JC = os.path.join(ROOT, "appdata", "t34", "joinctl")
CTL = os.path.join(ROOT, "appdata", "t4ctl")
CUT = 3                                                     # the 'resumed' step index: "4 the frame marker ..."


def make_joinctl():
    if not (os.path.exists(os.path.join(R1, "part1.json")) and os.path.exists(os.path.join(R2, "part1.json"))):
        return None
    pdir = os.path.join(JC, "gateprobe.parts")
    if os.path.isdir(JC):
        shutil.rmtree(JC)
    os.makedirs(pdir)
    p1 = wg.load(os.path.join(R2, "part1.json"))
    p2 = wg.load(os.path.join(R1, "part1.json"))
    step = p1["steps"][CUT][0]
    p1.update(end="FAILED", failed_step=step, mp4=os.path.join(R2, "part1.mp4"))
    p2.update({"k": 2, "mp4": os.path.join(R1, "part1.mp4"), "steps": p2["steps"][CUT:], "from": step,
               "from_point": "%s/%d" % (p1["run"], CUT)})
    for k, pj in ((1, p1), (2, p2)):
        with open(os.path.join(pdir, "part%d.json" % k), "w", encoding="utf-8") as f:
            json.dump(pj, f, indent=1)
    shutil.copy(os.path.join(R1, "..", "R1_framemap_rec25.json"), os.path.join(JC, "framemap_rec25.json"))
    return pdir


def _jcopy(case, src):
    dst = os.path.join(CTL, case, "gateprobe.parts")
    if os.path.isdir(os.path.dirname(dst)):
        shutil.rmtree(os.path.dirname(dst))
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns("trim", "joins_frames"))
    shutil.copy(os.path.join(JC, "framemap_rec25.json"), os.path.join(os.path.dirname(dst), "framemap_rec25.json"))
    return dst


def _verify(pdir, waived=True, fmap=True):
    jc.WAIVED = waived
    fm = os.path.join(os.path.dirname(pdir), "framemap_rec25.json") if fmap else None
    p1 = wg.load(os.path.join(pdir, "part1.json"))
    walk = wg.load(os.path.join(p1["run_dir"], "walk.json"))
    try:
        why, _ = jc.verify(pdir, fm, walk)
    finally:
        jc.WAIVED = False
    return why


def _edit(pdir, k, fn):
    p = os.path.join(pdir, "part%d.json" % k)
    j = wg.load(p)
    fn(j)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(j, f, indent=1)


def g_join(rec):
    v = lambda w: "REFUSED" if w else "ADMIT"
    src = make_joinctl()
    if not src:
        rec("join needs the R1 / R2 takes", "present", "absent")
        return
    w = _verify(_jcopy("join_clean", src))
    rec("join control take, gate waived: every other rule holds", "ADMIT", v(w), w)
    w = _verify(_jcopy("join_gate", src), waived=False)
    rec("join the same take, gate NOT waived (no SAME receipt)", "REFUSED", v(w), w)

    def case(name, label, edits, **kw):
        c = _jcopy(name, src)
        for k, fn in edits:
            _edit(c, k, fn)
        w = _verify(c, **kw)
        rec(label, "REFUSED", v(w), w)

    c = _jcopy("join_absent", src)
    os.remove(os.path.join(c, "part2.json"))
    w = _verify(c)
    rec("join part 2 absent (part 1 ends FAILED)", "REFUSED", v(w), w)
    case("join_video_absent", "join part 2's video absent", [(2, lambda j: j.update(mp4=j["mp4"] + ".missing"))])
    case("join_wrong_game", "join part 2 from another game hash", [(2, lambda j: j["identity"].update(game="0000old0game0000"))])
    case("join_wrong_profile", "join both parts at the 60-fps play profile",
         [(1, lambda j: j["identity"].update(profile="play")), (2, lambda j: j["identity"].update(profile="play"))])
    case("join_bad_from", "join resumed step != part 1's failed step", [(1, lambda j: j.update(failed_step="no such step"))])
    case("join_wrong_point", "join part 2 resumed from another run's point", [(2, lambda j: j.update(from_point="gateprobe_19990101_000000_1/3"))])
    case("join_range", "join cut range invalid (start past the part's end)", [(2, lambda j: j.update(steps=[[j["steps"][0][0], 10 ** 6]] + j["steps"][1:]))])
    case("join_dup", "join a step played twice in the kept ranges", [(2, lambda j: j.update(steps=[j["steps"][0]] + j["steps"]))])
    case("join_missing_step", "join a step missing from the kept ranges", [(2, lambda j: j.update(steps=[x for i, x in enumerate(j["steps"]) if i != 1]))])
    case("join_nomap", "join no drawn-frame -> movie-frame proof", [], fmap=False)
    case("join_bytes", "join part 2's video bytes changed since recorded", [(2, lambda j: j.update(sha="0" * 16))])
    case("join_not_done", "join the last part did not reach DONE", [(2, lambda j: j.update(end="FAILED"))])
    # the join itself on the control take: frame-exact cut, times, frames either side
    out = os.path.join(JC, "gateprobe_TESTONLY.mp4")
    jc.WAIVED = True
    try:
        rc = jc.join(src, out, os.path.join(JC, "framemap_rec25.json"))
    finally:
        jc.WAIVED = False
    rec("join control take joined (sum of trimmed parts = video length)", "0", str(rc))
    j = wg.load(os.path.join(src, "joins.json"))
    p1, p2 = wg.load(os.path.join(src, "part1.json")), wg.load(os.path.join(src, "part2.json"))
    want = p1["steps"][CUT][1] / 25.0
    rec("join time = part 1's cut frame / 25", "%.3f" % want, "%.3f" % j["joins"][0]["at_s"], j["joins"][0]["before_png"])
    exp = want + p2["duration"] - p2["steps"][0][1] / 25.0
    rec("join length = part 1 to its cut + part 2 from its step (within 1 frame)", "yes",
        "yes" if abs(exp - j["duration"]) <= 0.04 else "no", "expected %.3f s, video %.3f s" % (exp, j["duration"]))
    rc = jc.join(src, os.path.join(JC, "gateprobe.mp4"), os.path.join(JC, "framemap_rec25.json"))
    rec("join the real command on the same take (gate enforced)", "1", str(rc))
