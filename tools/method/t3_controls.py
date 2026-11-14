"""T3 v2 offline controls (no game): each guard refuses its planted failure AND accepts its clean case.

Groups:
  ident     tools/method/tree_id.py on a tiny scratch git repo under appdata/t3ctl/ (dirty bytes at the same
            HEAD, untracked input, output-only change, a plant change, pre/post mismatch, real index untouched)
  manifest  tools/method/make_ghat_manifest.py on tiny GDScript sources (non-underscore helper, cycle,
            repeated helper, unparsed check, dynamic call), old traversal beside the new
  final     t3_gate.py final on receipts in T1's exact format (method_run.sh / method_verdict.py), built
            under appdata/t3ctl/ (no archived T1 runs live in this copy)
  proof     t3_gate.py proof on the same kind of receipts
  obs       t3_gate.py obstable on a small table
  python tools/method/t3_controls.py [ident manifest final proof obs]
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import t3_gate  # noqa: E402
import tree_id  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
CTL = os.path.join(ROOT, "appdata", "t3ctl")
RESULTS = []
TREE = {"game": "g1", "test": "t1", "tools": "o1", "bin": "b1", "full": "f1"}


def rec(case, want, got, note=""):
    ok = want == got
    RESULTS.append(ok)
    print("%-4s %-60s want %-13s got %-13s %s" % ("ok" if ok else "BAD", case, want, got, str(note)[:160]), flush=True)


def fresh(*p):
    d = os.path.join(CTL, *p)
    if os.path.isdir(d):
        import stat
        shutil.rmtree(d, onerror=lambda f, p, e: (os.chmod(p, stat.S_IWRITE), f(p)))   # git objects are read-only
    os.makedirs(d)
    return d


def wr(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(s if isinstance(s, str) else json.dumps(s, indent=1))


# ---- ident ------------------------------------------------------------------------------------
def g_ident():
    r = fresh("repo")
    git = lambda *a: subprocess.run(["git", "-C", r] + list(a), capture_output=True, text=True, check=True)
    git("init", "-q")
    git("config", "user.email", "ctl@example.invalid")
    git("config", "user.name", "ctl")
    for p, s in (("FindingNaresh/scripts/a.gd", "var x = 1\n"), ("FindingNaresh/core/Plant.gd", "const P = []\n"),
                 ("FindingNaresh/scripts/dev/PlayTest.gd", "func t():\n\tpass\n"), ("tools/live/w.json", "{}\n"),
                 ("tools/method/j.py", "x = 1\n"), (".gitignore", "appdata/\n")):
        wr(os.path.join(r, p), s)
    git("add", "-A")
    git("commit", "-qm", "base")
    idx = os.path.join(r, ".git", "index")
    before = open(idx, "rb").read()
    a = tree_id.identity(r)
    rec("ident same tree twice -> same hashes", "SAME", "SAME" if tree_id.identity(r) == a else "DIFFERENT")
    rec("ident the real index is not written", "UNCHANGED", "UNCHANGED" if open(idx, "rb").read() == before else "CHANGED")
    wr(os.path.join(r, "FindingNaresh/scripts/a.gd"), "var x = 2\n")
    b = tree_id.identity(r)
    rec("ident dirty bytes at the same HEAD", "DIFFERENT", "DIFFERENT" if b["game"] != a["game"] and b["head"] == a["head"] else "SAME", (a["game"], b["game"]))
    wr(os.path.join(r, "FindingNaresh/scripts/a.gd"), "var x = 1\n")
    rec("ident bytes back -> back to the same hash", "SAME", "SAME" if tree_id.identity(r) == a else "DIFFERENT")
    wr(os.path.join(r, "FindingNaresh/scripts/new.gd"), "var y\n")
    c = tree_id.identity(r)
    rec("ident an untracked input file", "DIFFERENT", "DIFFERENT" if c["game"] != a["game"] else "SAME")
    os.remove(os.path.join(r, "FindingNaresh/scripts/new.gd"))
    wr(os.path.join(r, "appdata/out.txt"), "a run's output\n")
    wr(os.path.join(r, "notes/report.md"), "a report\n")
    c = tree_id.identity(r)
    rec("ident output-only changes (appdata/, notes/)", "SAME", "SAME" if c["full"] == a["full"] else "DIFFERENT")
    wr(os.path.join(r, "FindingNaresh/core/Plant.gd"), "const P = ['x']\n")
    c = tree_id.identity(r)
    rec("ident a different plant (core/Plant.gd)", "DIFFERENT", "DIFFERENT" if c["game"] != a["game"] else "SAME")
    wr(os.path.join(r, "FindingNaresh/core/Plant.gd"), "const P = []\n")
    wr(os.path.join(r, "tools/live/w.json"), "{\"steps\": []}\n")
    c = tree_id.identity(r)
    rec("ident a walk (test producer) changed", "DIFFERENT", "DIFFERENT" if c["test"] != a["test"] and c["game"] == a["game"] else "SAME")
    pa, pb = os.path.join(CTL, "pre.json"), os.path.join(CTL, "post.json")
    wr(pa, a)
    wr(pb, c)
    rc = subprocess.run([sys.executable, os.path.join(HERE, "tree_id.py"), "same", pa, pb, "game,test,tools,bin"], capture_output=True, text=True).returncode
    rec("ident pre/post mismatch -> tree_id.py same refuses", "REFUSED", "REFUSED" if rc == 1 else "ACCEPTED")
    rc = subprocess.run([sys.executable, os.path.join(HERE, "tree_id.py"), "same", pa, pa, "game,test,tools,bin"], capture_output=True, text=True).returncode
    rec("ident pre/post equal -> accepted", "ACCEPTED", "REFUSED" if rc else "ACCEPTED")


# ---- manifest ---------------------------------------------------------------------------------
def man(src, scen="ghat_x", old=False):
    p = os.path.join(CTL, "man_src.gd")
    wr(p, src)
    env = dict(os.environ, MANIFEST_SRC=p)
    if old:
        env["MANIFEST_OLD"] = "1"
    r = subprocess.run([sys.executable, os.path.join(HERE, "make_ghat_manifest.py"), scen], capture_output=True, text=True, env=env)
    if r.returncode:
        return None, (r.stderr.strip().splitlines() or ["?"])[-1]
    return [x["id"] for x in json.loads(r.stdout)[scen]], ""


def g_manifest():
    base = 'func t_ghat_x():\n\tcheck(true, "own check")\n\tstep_one()\n\nfunc step_one():\n\tcheck(true, "in a plain helper")\n'
    ids, _ = man(base)
    old, _ = man(base, old=True)
    rec("manifest non-underscore helper's check included", "2 rows", "%d rows" % len(ids or []), "new %s | old %s" % (ids, old))
    cyc = 'func t_ghat_x():\n\t_a()\n\nfunc _a():\n\tcheck(true, "in a")\n\t_b()\n\nfunc _b():\n\tcheck(true, "in b")\n\t_a()\n'
    ids, err = man(cyc)
    rec("manifest a cycle a -> b -> a terminates", "2 rows", "%d rows" % len(ids or []), ids or err)
    rep = 'func t_ghat_x():\n\tlook_round()\n\tlook_round()\n\nfunc look_round():\n\tcheck(true, "looked round")\n'
    ids, _ = man(rep)
    old, _ = man(rep, old=True)
    rec("manifest helper called twice -> its check twice", "2 rows", "%d rows" % len(ids or []), "new %s | old %s" % (ids, old))
    cb = 'func t_ghat_x():\n\tvar f := on_tick\n\tf.call()\n\nfunc on_tick():\n\tcheck(true, "from a callback")\n'
    ids, err = man(cb)
    rec("manifest helper passed as a value (callback)", "1 rows", "%d rows" % len(ids or []), ids or err)
    unp = 'func t_ghat_x():\n\tcheck(true, some_text_var)\n'
    ids, err = man(unp)
    rec("manifest unparsed check -> refused", "REFUSED", "REFUSED" if ids is None else "ACCEPTED", err)
    dyn = 'func t_ghat_x():\n\tcall("hel" + "per")\n\nfunc helper():\n\tcheck(true, "dynamic")\n'
    ids, err = man(dyn)
    rec("manifest dynamic call -> refused", "REFUSED", "REFUSED" if ids is None else "ACCEPTED", err)
    cmt = 'func t_ghat_x():\n\t# check(true, "commented out")\n\tcheck(true, "real")\n'
    ids, err = man(cmt)
    rec("manifest commented-out check not counted", "1 rows", "%d rows" % len(ids or []), ids or err)
    real_old = subprocess.run([sys.executable, os.path.join(HERE, "make_ghat_manifest.py")], capture_output=True, text=True, env=dict(os.environ, MANIFEST_OLD="1")).stdout
    real_new = subprocess.run([sys.executable, os.path.join(HERE, "make_ghat_manifest.py")], capture_output=True, text=True).stdout
    o, n = json.loads(real_old), json.loads(real_new)
    same = all([x["id"] for x in o[s]] == [x["id"] for x in n[s]] for s in o)
    rec("manifest real PlayTest.gd: required ids unchanged by the fix", "SAME", "SAME" if same else "DIFFERENT", "%d ids" % sum(len(v) for v in n.values()))


# ---- receipts in T1's format --------------------------------------------------------------------
def part(invd, inv, part, scens, fixture="", status="PASS", passed=(), failed=(), role="final", profile="k3",
         tree=None, tree_post=None, meta=None, vj_extra=None, early=False):
    runs = os.path.join(os.path.dirname(os.path.dirname(invd)), "runs")
    run = "%s_%s" % (inv, part)
    d = os.path.join(runs, run)
    os.makedirs(d, exist_ok=True)
    code = {"PASS": 0, "FAIL": 1, "INCOMPLETE": 2}[status]
    wr(os.path.join(d, "run_info.txt"), "inv %s part %s\nrun %s plan %s profile %s fixture '%s' speed '1x' lane 'a' at 2026-11-14 12:00:00\n" % (inv, part, run, scens, profile, fixture))
    wr(os.path.join(d, "trace.json"), {"asked": scens.split(",")})
    vj = {"status": status, "code": code, "inv": inv, "part": part, "fixture": fixture, "asked": scens.split(","),
          "failed_ids": list(failed), "passed_ids": list(passed), "early_stop": early, "kill": [], "kill_ok": True,
          "godot_left_after": "", "wrapper_rc": 0}
    vj.update(vj_extra or {})
    wr(os.path.join(d, "verdict.json"), vj)
    wr(os.path.join(d, "verdict.txt"), "RESULT: %s (exit %d)\n  ...\n  Evidence: %s\n" % (status, code, d))
    t = dict(tree or TREE)
    wr(os.path.join(d, "tree_pre.json"), t)
    wr(os.path.join(d, "tree_post.json"), tree_post or t)
    m = {"inv": inv, "part": part, "run": run, "plan": scens, "profile": profile, "fixture": fixture, "role": role,
         "rc": str(code), "godot_left_in_lane": "", "from_point": "", "ghat_env": scens, "early_stop_ids": ""}
    m.update(meta or {})
    wr(os.path.join(d, "run_meta.json"), m)
    with open(os.path.join(invd, "expected"), "a", encoding="utf-8", newline="\n") as f:
        f.write("%s\t%s\t%s\n" % (part, scens, fixture))
    wr(os.path.join(invd, part + ".dir"), d + "\n")
    wr(os.path.join(invd, part + ".rc"), "%d\n" % code)
    return d


FAST = "ghat_heat,ghat_net,ghat_marks"
SLOW = "ghat_looks,ghat_places,ghat_jug,ghat_spring"


def clean_final(name, fast=FAST, slow=SLOW, **kw):
    inv = "final_%s" % name
    invd = fresh("final", "inv", inv)
    fkw = {k: v for k, v in kw.items() if not k.startswith("s_")}
    skw = {k[2:]: v for k, v in kw.items() if k.startswith("s_")}
    if fast:
        part(invd, inv, "fast", fast, passed=kw.get("passed", ()), **{k: v for k, v in fkw.items() if k != "passed"})
    if slow:
        part(invd, inv, "1x", slow, passed=kw.get("passed", ()), **skw)
    return invd


def fin(invd, frozen=None):
    why, _ = t3_gate.final(invd, frozen)
    return ("REFUSED" if why else "ACCEPTED"), why


def g_final():
    v, w = fin(clean_final("clean"))
    rec("final clean: all seven, k3, no fixture, final role, same tree", "ACCEPTED", v, w)
    rec("final six scenarios (spring missing)", "REFUSED", *fin(clean_final("six", slow="ghat_looks,ghat_places,ghat_jug")))
    rec("final a GHAT= continuation (the remaining four only)", "REFUSED", *fin(clean_final("cont", fast="")))
    rec("final one_corner fixture", "REFUSED", *fin(clean_final("fx", fixture="one_corner", s_fixture="one_corner")))
    rec("final role repair (not explicitly final)", "REFUSED", *fin(clean_final("role", role="repair", s_role="repair")))
    rec("final started from a restored point", "REFUSED", *fin(clean_final("restored", meta={"from_point": "ghat_x/3"})))
    rec("final early-stop run", "REFUSED", *fin(clean_final("early", early=True)))
    rec("final inputs mutated mid-run (tree pre != post)", "REFUSED", *fin(clean_final("mut", s_tree_post=dict(TREE, game="g2"))))
    rec("final parts on different trees", "REFUSED", *fin(clean_final("trees", s_tree=dict(TREE, test="t2"))))
    rec("final looks run fast (not qualified fast)", "REFUSED", *fin(clean_final("route", fast=FAST + ",ghat_looks", slow="ghat_places,ghat_jug,ghat_spring")))
    rec("final profile k1", "REFUSED", *fin(clean_final("k1", profile="k1", s_profile="k1")))
    rec("final a game left in the lane", "REFUSED", *fin(clean_final("left", meta={"godot_left_in_lane": "1234"})))
    invd = clean_final("fail")
    d = (open(os.path.join(invd, "1x.dir")).read()).strip()
    wr(os.path.join(d, "verdict.txt"), "RESULT: FAIL (exit 1)\n  Evidence: %s\n" % d)
    wr(os.path.join(invd, "1x.rc"), "1\n")
    rec("final a part FAILED", "REFUSED", *fin(invd))
    invd = clean_final("nometa")
    os.remove(os.path.join(open(os.path.join(invd, "fast.dir")).read().strip(), "run_meta.json"))
    rec("final no run_meta (role / exit unknown)", "REFUSED", *fin(invd))
    wr(os.path.join(CTL, "frozen_ok.json"), TREE)
    wr(os.path.join(CTL, "frozen_other.json"), dict(TREE, game="g9"))
    rec("final = the frozen tree", "ACCEPTED", *fin(clean_final("fz1"), os.path.join(CTL, "frozen_ok.json")))
    rec("final != the frozen tree (another plant / game)", "REFUSED", *fin(clean_final("fz2"), os.path.join(CTL, "frozen_other.json")))


# ---- proof --------------------------------------------------------------------------------------
NET_ID = "ghat_net/from_outside_nothing_of_the_van_shows_through_the_net_bright"
JUG = {"leave_sees": "ghat_jug/out_beside_it_after_it_gave_up_nobody_is_taken",
       "no_breath_lock": "ghat_jug/holding_your_breath_ctrl_b_never_touched_the_handbrake",
       "round_skip": "ghat_jug/it_went_all_round_the_van_before_it_gave_up_x_stops"}


def prove_inv(group, scen, plants, failed, passed=(), tree=None, n=1, name=None):
    inv = name or "prove_%s_20261114_1200%02d_%d" % (group, n, 100 + n)
    invd = fresh("final", "inv", inv)
    part(invd, inv, "single", scen, fixture=plants, status="FAIL", failed=failed, passed=passed, role="proof", tree=tree)
    return invd


def g_proof():
    allpass = [NET_ID] + list(JUG.values())
    fz = clean_final("forproof", passed=allpass)
    net = prove_inv("net", "ghat_net", "one_layer_net", [NET_ID])
    rows = t3_gate.proof(fz, [net])
    rec("proof single plant, own id FAILed, PASS in clean, same tree", "CERTIFIED", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", rows)
    wrong = prove_inv("net", "ghat_net", "one_layer_net", ["ghat_net/from_outside_nothing_of_the_van_shows_through_the_net_brightx"], n=2)
    rows = t3_gate.proof(fz, [wrong])
    rec("proof a wrong id with the same text start", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    other = prove_inv("net", "ghat_net", "one_layer_net", [NET_ID], n=3)
    d = open(os.path.join(other, "single.dir")).read().strip()
    info = open(os.path.join(d, "run_info.txt")).read().splitlines()
    wr(os.path.join(d, "run_info.txt"), "inv prove_net_20261114_999999_1 part single\n" + "\n".join(info[1:]) + "\n")
    rows = t3_gate.proof(fz, [other])
    rec("proof the run folder of another invocation", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    tr = prove_inv("net", "ghat_net", "one_layer_net", [NET_ID], tree=dict(TREE, game="g_old"), n=4)
    rows = t3_gate.proof(fz, [tr])
    rec("proof on another input tree than the clean final", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    fz2 = clean_final("forproof_nopass", passed=[x for x in allpass if x != NET_ID])
    rows = t3_gate.proof(fz2, [net])
    rec("proof its check not PASSed in the clean final", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    batch = prove_inv("jug_a", "ghat_jug", "leave_sees,no_breath_lock,round_skip", list(JUG.values()), n=5)
    rows = t3_gate.proof(fz, [batch])
    rec("proof batch: all three ids FAILed together (D2 A)", "3 NOT", "%d NOT" % sum(not ok for ok, _ in rows.values()), [w for _, w in rows.values()][0])
    miss = prove_inv("jug_a", "ghat_jug", "leave_sees,no_breath_lock,round_skip", [JUG["leave_sees"], JUG["no_breath_lock"]], n=6)
    solo = [prove_inv("solo_%s" % p, "ghat_jug", p, [JUG[p]], n=7 + i) for i, p in enumerate(("leave_sees", "no_breath_lock"))]
    rows = t3_gate.proof(fz, [miss] + solo)
    st = {k.split(" ")[0] + ("/solo" if "solo" in k else ""): ok for k, (ok, _) in rows.items()}
    rec("proof batch member's own check absent -> that member NOT", "round_skip NOT", "round_skip NOT" if not st.get("round_skip") else "round_skip CERT", st)
    rec("proof batch members with their own solo proofs", "2 CERTIFIED", "%d CERTIFIED" % sum(1 for k, ok in st.items() if ok and "/solo" in k), st)
    early = prove_inv("net", "ghat_net", "one_layer_net", [], n=11)
    d = open(os.path.join(early, "single.dir")).read().strip()
    vj = json.load(open(os.path.join(d, "verdict.json")))
    vj["early_stop"] = True
    wr(os.path.join(d, "verdict.json"), vj)
    rows = t3_gate.proof(fz, [early])
    rec("proof early stop before its id was on record", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    left = prove_inv("net", "ghat_net", "one_layer_net", [NET_ID], n=12)
    d = open(os.path.join(left, "single.dir")).read().strip()
    vj = json.load(open(os.path.join(d, "verdict.json")))
    vj["godot_left_after"] = "4242"
    wr(os.path.join(d, "verdict.json"), vj)
    rows = t3_gate.proof(fz, [left])
    rec("proof game not checked gone", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    rows = t3_gate.proof(clean_final("forproof_six", slow="ghat_looks,ghat_places,ghat_jug", passed=allpass), [net])
    rec("proof against a clean suite that is not accepted (six)", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])


# ---- observation table --------------------------------------------------------------------------
def g_obs():
    man = os.path.join(CTL, "man.json")
    wr(man, {"ghat_net": [{"id": NET_ID}]})
    ok = "| # | behaviour | producer / input | observed by |\n|---|---|---|---|\n| 1 | the net hides the van | P2 hangs the net (walk step 9) | %s |\n| 2 | the lamp glows through fog | the fog step | picture: van lamp lit in fog at the hairpin |\n" % NET_ID
    p = os.path.join(CTL, "obs_ok.md")
    wr(p, ok)
    out, bad = t3_gate.obstable(p, man)
    rec("obs every row observed", "0 gaps", "%d gaps" % bad, out)
    wr(p, ok + "| 3 | it sniffs at the back door | the looks round |  |\n")
    out, bad = t3_gate.obstable(p, man)
    rec("obs a behaviour with no observation -> GAP", "1 gaps", "%d gaps" % bad, out[-1])
    wr(p, ok + "| 3 | it sniffs | the looks round | ghat_looks/no_such_check |\n")
    out, bad = t3_gate.obstable(p, man)
    rec("obs a check id that does not exist -> UNKNOWN", "1 gaps", "%d gaps" % bad, out[-1])
    wr(p, ok + "| 3 | it sniffs | - | picture: it crouches at the back door |\n")
    out, bad = t3_gate.obstable(p, man)
    rec("obs no real producer / input -> GAP", "1 gaps", "%d gaps" % bad, out[-1])


GROUPS = {"ident": g_ident, "manifest": g_manifest, "final": g_final, "proof": g_proof, "obs": g_obs}


def main(a):
    os.makedirs(CTL, exist_ok=True)
    for g in (a or list(GROUPS)):
        print("== %s" % g)
        GROUPS[g]()
    print("T3 offline controls: %d / %d as expected" % (RESULTS.count(True), len(RESULTS)))
    return 0 if all(RESULTS) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
