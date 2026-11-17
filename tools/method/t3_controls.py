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
  sentinel  sentinel_workers.py (lane_sentinel.sh's workload judge) on R4's real lane b log and its pair
  python tools/method/t3_controls.py [ident manifest final proof obs sentinel ...]
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import captures  # noqa: E402
import seal  # noqa: E402
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
    # merge 2026-11-17: a same-size edit whose mtime matches the index entry (git's stat cache would call it clean)
    ap = os.path.join(r, "FindingNaresh/scripts/a.gd")
    st0 = os.stat(ap)
    wr(ap, "var x = 3\n")
    os.utime(ap, ns=(st0.st_atime_ns, st0.st_mtime_ns))
    b = tree_id.identity(r)
    rec("ident same-size edit, mtime restored (stat cache)", "DIFFERENT", "DIFFERENT" if b["game"] != a["game"] else "SAME", (a["game"], b["game"]))
    wr(ap, "var x = 1\n")
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
    # F10: self.<local>, literal call / callv / call_deferred / Callable(self, "<local>") targets are followed
    for nm, line in (("self.helper()", '\tself.helper()'), ("self.helper as a value", '\tvar f = self.helper\n\tf.call()'),
                     ('call("helper")', '\tcall("helper")'), ('callv("helper", [])', '\tcallv("helper", [])'),
                     ('self.call_deferred("helper")', '\tself.call_deferred("helper")'),
                     ('Callable(self, "helper").call()', '\tCallable(self, "helper").call()')):
        src = 'func t_ghat_x():\n%s\n\nfunc helper():\n\tcheck(true, "reached through %s")\n' % (line, nm.replace('"', "'"))
        ids, err = man(src)
        old, _ = man(src, old=True)
        rec("manifest F10 %s: helper's check included" % nm, "1 rows", "%d rows" % len(ids or []), "new %s | old %s %s" % (ids, old, err))
    src = 'func t_ghat_x():\n\tboot.call("helper")\n\nfunc helper():\n\tcheck(true, "another object")\n'
    ids, err = man(src)
    rec("manifest F10 boot.call(\"helper\") (another object's) not followed", "0 rows", "%d rows" % len(ids or []), ids or err)
    src = 'func t_ghat_x():\n\tvar nm = "hel" + "per"\n\tcallv(nm, [])\n\nfunc helper():\n\tcheck(true, "dynamic")\n'
    ids, err = man(src)
    rec("manifest F10 callv(<variable>) still refused", "REFUSED", "REFUSED" if ids is None else "ACCEPTED", err)
    src = 'func t_ghat_x():\n\tCallable(self, nm).call()\n\nfunc helper():\n\tcheck(true, "dynamic")\n'
    ids, err = man(src)
    rec("manifest F10 Callable(self, <variable>) still refused", "REFUSED", "REFUSED" if ids is None else "ACCEPTED", err)
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
    pictures(d, scens)
    with open(os.path.join(invd, "expected"), "a", encoding="utf-8", newline="\n") as f:
        f.write("%s\t%s\t%s\n" % (part, scens, fixture))
    wr(os.path.join(invd, part + ".dir"), d + "\n")
    wr(os.path.join(invd, part + ".rc"), "%d\n" % code)
    return d


def pictures(d, scens):
    """F7: a run's pictures the way method_run.sh leaves them: launch_mark, shots/test_<tag>.png (each its own
    bytes), the game's captures.jsonl (one row per picture, written after the launch), capture_inventory.json."""
    import time
    lm = os.path.join(d, "launch_mark")
    wr(lm, "")
    t0 = time.time() - 600
    os.utime(lm, (t0, t0))                      # the launch: 10 min ago
    os.makedirs(os.path.join(d, "shots"), exist_ok=True)
    rows = []
    for s in scens.split(","):
        for k, tag in enumerate(captures.required(s) + (["ghat_extra_%s" % s] if s == "ghat_heat" else [])):
            f = os.path.join(d, "shots", "test_%s.png" % tag)
            with open(f, "wb") as fh:
                fh.write(("PNG %s %s %s" % (d, s, tag)).encode())
            rows.append({"scenario": s, "tag": tag, "file": "test_%s.png" % tag, "frame": 100 + k, "physics_frame": 100 + k,
                         "game_ms": 1000 * k, "unix": t0 + 60 + k, "sha256": captures.sha(f), "last_check": "x"})
    with open(os.path.join(d, "captures.jsonl"), "w", encoding="utf-8", newline="\n") as fh:
        for r in rows:
            fh.write(json.dumps(r) + "\n")
    captures.inventory(d)


def inspect_all(invd, skip=()):
    lines = []
    for ln in open(os.path.join(invd, "expected"), encoding="utf-8"):
        f = ln.rstrip("\n").split("\t")
        for s in f[1].split(","):
            for t in captures.required(s) + (["ghat_extra_%s" % s] if s == "ghat_heat" else []):
                if "%s/%s" % (s, t) not in skip:
                    lines.append("- %s/%s: the view as the step describes it, looked at" % (s, t))
    wr(os.path.join(invd, "inspection.md"), "# inspection\n" + "\n".join(lines) + "\n")


# F6 (fix round): the default routing (tools/method/route.py): marks in the 1x part, after looks
FAST = "ghat_heat,ghat_net"
SLOW = "ghat_looks,ghat_places,ghat_jug,ghat_spring,ghat_marks"


def clean_final(name, fast=FAST, slow=SLOW, prelude=True, **kw):
    """prelude: the looks round id PASSED in the part that has marks (F6)."""
    inv = "final_%s" % name
    invd = fresh("final", "inv", inv)
    fkw = {k: v for k, v in kw.items() if not k.startswith("s_")}
    skw = {k[2:]: v for k, v in kw.items() if k.startswith("s_")}
    pre = lambda sc: tuple(kw.get("passed", ())) + ((t3_gate.PRELUDE_ID,) if prelude and "ghat_marks" in sc else ())
    if fast:
        part(invd, inv, "fast", fast, passed=pre(fast), **{k: v for k, v in fkw.items() if k != "passed"})
    if slow:
        part(invd, inv, "1x", slow, passed=pre(slow), **skw)
    inspect_all(invd)
    seal.seal(kw.get("role", "final"), os.path.join(invd, "seal.json"), env={})     # F9: clean env
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
    rec("final looks run fast (not qualified fast)", "REFUSED", *fin(clean_final("route", fast=FAST + ",ghat_looks", slow="ghat_places,ghat_jug,ghat_spring,ghat_marks")))
    # F6: marks' looks prelude (same run, before marks, its round PASSED)
    v, w = fin(clean_final("m_split", fast="ghat_heat,ghat_net,ghat_marks", slow="ghat_looks,ghat_places,ghat_jug,ghat_spring"))
    rec("final F6 marks split from looks (the old routing), marks PASS", "REFUSED", v, w)
    rec("final F6 ... refused BY the prelude rule alone", "prelude only", "prelude only" if w and all("prelude" in x for x in w) else "other", w)
    v, w = fin(clean_final("m_noround", prelude=False))
    rec("final F6 marks after looks, looks made no round (id not PASSED)", "REFUSED", v, w)
    rec("final F6 ... refused BY the prelude rule alone", "prelude only", "prelude only" if w and all("prelude" in x for x in w) else "other", w)
    v, w = fin(clean_final("m_order", slow="ghat_marks,ghat_looks,ghat_places,ghat_jug,ghat_spring"))
    rec("final F6 marks BEFORE looks in the same part", "REFUSED", v, w)
    rec("final F6 clean: marks after looks, round PASSED, same part", "ACCEPTED", *fin(clean_final("m_clean")))
    g_pictures()


def _pic_case(name, mutate, partname="1x"):
    """A clean final whose one part's picture evidence is changed by mutate(run dir, rows) -> rows."""
    invd = clean_final(name)
    d = open(os.path.join(invd, partname + ".dir")).read().strip()
    rows = [json.loads(x) for x in open(os.path.join(d, "captures.jsonl"), encoding="utf-8") if x.strip()]
    rows = mutate(d, rows)
    if rows is not None:
        with open(os.path.join(d, "captures.jsonl"), "w", encoding="utf-8", newline="\n") as fh:
            for r in rows:
                fh.write(json.dumps(r) + "\n")
        captures.inventory(d)
    v, w = fin(invd)
    return v, w


def _pic_only(w):
    return "pictures only" if w and all(("picture" in x or "inventory" in x or "inspection" in x) for x in w) else "other"


def g_pictures():
    """F7: picture evidence (capture inventory + the runner's inspection file)."""
    net_in = "ghat_net/ghat_net_inside"
    def drop_row(d, rows):
        return [r for r in rows if r["tag"] != "ghat_net_inside"]
    def drop_file(d, rows):
        os.remove(os.path.join(d, "shots", "test_ghat_net_inside.png"))
        return rows
    def stale(d, rows):
        lm = os.path.getmtime(os.path.join(d, "launch_mark"))
        f = os.path.join(d, "shots", "test_ghat_net_inside.png")
        os.utime(f, (lm - 3600, lm - 3600))
        for r in rows:
            if r["tag"] == "ghat_net_inside":
                r["unix"] = lm - 3600
        return rows
    def replaced(d, rows):
        with open(os.path.join(d, "shots", "test_ghat_net_inside.png"), "wb") as fh:
            fh.write(b"PNG another picture")
        return rows
    def dup(d, rows):
        src = os.path.join(d, "shots", "test_ghat_net_before.png")
        shutil.copy2(src, os.path.join(d, "shots", "test_ghat_net_inside.png"))
        for r in rows:
            if r["tag"] == "ghat_net_inside":
                r["sha256"] = captures.sha(src)
        return rows
    def noinv(d, rows):
        os.remove(os.path.join(d, "capture_inventory.json"))
        return None
    def oldinv(d, rows):
        lm = os.path.getmtime(os.path.join(d, "launch_mark"))
        os.utime(os.path.join(d, "capture_inventory.json"), (lm - 60, lm - 60))
        return None
    for nm, mut, pn in (("a required picture never captured (" + net_in + ")", drop_row, "fast"),
                        ("captured but its file not in the run's shots", drop_file, "fast"),
                        ("a picture older than the launch (stale)", stale, "fast"),
                        ("the file's bytes replaced after capture", replaced, "fast"),
                        ("one file standing for two pictures (duplicated)", dup, "fast"),
                        ("no capture inventory", noinv, "fast"),
                        ("inventory written before the launch", oldinv, "fast")):
        v, w = _pic_case("pic_" + mut.__name__, mut, pn)
        rec("final F7 %s" % nm, "REFUSED", v, w)
        rec("final F7 ... refused BY the picture rule alone", "pictures only", _pic_only(w), w)
    invd = clean_final("pic_noinspect_line")
    inspect_all(invd, skip=("ghat_heat/ghat_extra_ghat_heat",))
    v, w = fin(invd)
    rec("final F7 a logged picture with no inspection line", "REFUSED", v, w)
    rec("final F7 ... refused BY the picture rule alone", "pictures only", _pic_only(w), w)
    invd = clean_final("pic_noinspect")
    os.remove(os.path.join(invd, "inspection.md"))
    v, w = fin(invd)
    rec("final F7 no inspection file", "REFUSED", v, w)
    rec("final F7 clean: every picture present, fresh, unique, inspected", "ACCEPTED", *fin(clean_final("pic_clean")))
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
    seal.seal("proof", os.path.join(invd, "seal.json"), env={})        # F9: as method_run.sh writes it (clean env)
    return invd


def g_proof():
    allpass = [NET_ID] + list(JUG.values())
    fz = clean_final("forproof", passed=allpass)
    net = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID])
    rows = t3_gate.proof(fz, [net])
    rec("proof single plant, own id FAILed, PASS in clean, same tree", "CERTIFIED", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", rows)
    wrong = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", ["ghat_net/from_outside_nothing_of_the_van_shows_through_the_net_brightx"], n=2)
    rows = t3_gate.proof(fz, [wrong])
    rec("proof a wrong id with the same text start", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    other = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID], n=3)
    d = open(os.path.join(other, "single.dir")).read().strip()
    info = open(os.path.join(d, "run_info.txt")).read().splitlines()
    wr(os.path.join(d, "run_info.txt"), "inv prove_solo_one_layer_net_20261114_999999_1 part single\n" + "\n".join(info[1:]) + "\n")
    rows = t3_gate.proof(fz, [other])
    rec("proof the run folder of another invocation", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    tr = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID], tree=dict(TREE, game="g_old"), n=4)
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
    early = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [], n=11)
    d = open(os.path.join(early, "single.dir")).read().strip()
    vj = json.load(open(os.path.join(d, "verdict.json")))
    vj["early_stop"] = True
    wr(os.path.join(d, "verdict.json"), vj)
    rows = t3_gate.proof(fz, [early])
    rec("proof early stop before its id was on record", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    left = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID], n=12)
    d = open(os.path.join(left, "single.dir")).read().strip()
    vj = json.load(open(os.path.join(d, "verdict.json")))
    vj["godot_left_after"] = "4242"
    wr(os.path.join(d, "verdict.json"), vj)
    rows = t3_gate.proof(fz, [left])
    rec("proof game not checked gone", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    rows = t3_gate.proof(clean_final("forproof_six", slow="ghat_looks,ghat_places,ghat_jug", passed=allpass), [net])
    rec("proof against a clean suite that is not accepted (six)", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    # F6: the marks plant proof under SPEED=fast fits prove_ghat's one-part judge (route.py decides the parts)
    import route
    import prove_ghat
    scen, plants, expect = prove_ghat.GROUPS["solo_marks_pile"]
    for nm, env, want in (("old routing (marks fast, looks 1x)", {"FAST_OK_OVERRIDE": "ghat_heat ghat_net ghat_marks"}, "NOT PROVED"),
                          ("F6 routing (looks + marks one 1x part)", {}, "PROVED")):
        fp, sp = route.route(scen, plants, env)
        inv = "prove_solo_marks_pile_20261114_1300%02d_%d" % (len(nm), 300 + len(nm))
        invd = fresh("final", "inv", inv)
        for pn, sc in (("fast", fp), ("1x", sp)):
            if sc:
                part(invd, inv, pn, ",".join(sc), fixture=plants, status="FAIL", failed=expect["marks_pile"],
                     passed=[t3_gate.PRELUDE_ID], role="proof")
        prob, _, res = prove_ghat.judge(invd, scen, plants, expect)
        got = "PROVED" if res["marks_pile"][0] else "NOT PROVED"
        rec("proof F6 solo_marks_pile, SPEED=fast, %s" % nm, want, got, prob or res["marks_pile"][1])


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


# ---- proof matrix reconciliation (F8) -------------------------------------------------------------
def g_matrix():
    import prove_ghat
    ids = [x for g in prove_ghat.MATRIX for v in prove_ghat.GROUPS[g][2].values() for x in v]
    fz = clean_final("formatrix", passed=[x for x in ids if "/" in x])
    frozen = os.path.join(CTL, "frozen_matrix.json")
    wr(frozen, TREE)
    def proofs(skip=(), extra=()):
        out = []
        for n, g in enumerate([g for g in prove_ghat.MATRIX if g not in skip] + list(extra)):
            scen, plants, expect = prove_ghat.GROUPS[g]
            out.append(prove_inv(g, scen, plants, [x for v in expect.values() for x in v], passed=[t3_gate.PRELUDE_ID],
                                 name="prove_%s_20261114_14%04d_%d" % (g, n, 500 + n)))
        return out
    now = dict(TREE)
    full = proofs()
    probs, out = t3_gate.matrix(fz, frozen, full, now=now)
    done = sum(1 for _, st, _ in out if st == "CERTIFIED")
    nrow = len(prove_ghat.MATRIX)
    rec("matrix clean: %d rows, each proved alone on the frozen tree" % nrow, "%d/%d complete" % (nrow, nrow), "%d/%d %s" % (done, len(out), "complete" if not probs and done == len(out) else "incomplete"), probs)
    probs, out = t3_gate.matrix(fz, frozen, proofs(skip=("solo_cap_text",)), now=now)
    miss = [p for p, st, _ in out if st != "CERTIFIED"]
    rec("matrix one row's proof not given (cap_text)", "NOT DONE cap_text", "NOT DONE " + ",".join(miss) if miss else "complete", [w for p, _, w in out if p in miss])
    probs, out = t3_gate.matrix(fz, frozen, proofs(skip=("solo_leave_sees", "solo_no_breath_lock", "solo_round_skip"), extra=("jug_a",)), now=now)
    nc = sorted(p for p, st, _ in out if st == "NOT CERTIFIED")
    rec("matrix jug_a proved only as a batch", "3 NOT CERTIFIED", "%d NOT CERTIFIED" % len(nc), nc)
    probs, out = t3_gate.matrix(fz, frozen, full, now=dict(TREE, test="t_new_check"))
    rec("matrix a check added after the freeze (test tree changed)", "PROBLEM", "PROBLEM" if probs else "none", probs)
    root = fresh("matrix_root")
    names = t3_gate.plant_rows() + ["new_hole"]
    wr(os.path.join(root, "FindingNaresh", "scripts", "x.gd"), "\n".join('if Plant.on("%s"): pass' % n for n in names) + "\n")
    probs, out = t3_gate.matrix(fz, frozen, full, root=root, now=now)
    st = dict((p, s) for p, s, _ in out)
    rec("matrix a new plant (new_hole) with no matrix group", "NOT DONE", st.get("new_hole", "absent"), [w for p, _, w in out if p == "new_hole"])
    rec("matrix the game's plant rows (main's 27)", "27", str(len(t3_gate.plant_rows())), t3_gate.plant_rows())


# ---- test-only flags sealed out of acceptance runs (F9) ------------------------------------------
def g_seal():
    for role in ("final", "proof", "record"):
        rec("seal %s, clean environment" % role, "SEALED", "SEALED" if not seal.found(role, {"SPEED": "fast" if role != "record" else ""}) else "REFUSED")
    for k in seal.FLAGS:
        rec("seal final with %s set" % k, "REFUSED", "REFUSED" if seal.found("final", {k: "1"}) else "SEALED")
    rec("seal final with SPEED=_fast (a part's internal speed)", "REFUSED", "REFUSED" if seal.found("final", {"SPEED": "_fast"}) else "SEALED")
    rec("seal record with GATE_PROBE set", "REFUSED", "REFUSED" if seal.found("record", {"GATE_PROBE": "1"}) else "SEALED")
    rec("seal a discovery run with GATE_PROBE (not an acceptance run)", "not sealed, allowed",
        "not sealed, allowed" if not seal.seal("discovery", None, {"GATE_PROBE": "1"}) else "refused")
    # the gate side: an acceptance invocation needs a sealed receipt
    invd = clean_final("seal_flagged")
    seal.seal("final", os.path.join(invd, "seal.json"), env={"GATE_RESUMES": "1"})
    v, w = fin(invd)
    rec("seal final suite whose receipt found GATE_RESUMES", "REFUSED", v, w)
    rec("seal ... refused BY the seal rule alone", "seal only", "seal only" if w and all("seal" in x for x in w) else "other", w)
    invd = clean_final("seal_none")
    os.remove(os.path.join(invd, "seal.json"))
    rec("seal final suite with no seal receipt", "REFUSED", *fin(invd))
    rec("seal final suite, sealed receipt (clean)", "ACCEPTED", *fin(clean_final("seal_clean")))
    import prove_ghat
    fz = clean_final("seal_forproof", passed=[NET_ID])
    pr = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID], n=41)
    seal.seal("proof", os.path.join(pr, "seal.json"), env={"JOIN_GATE_WAIVED": "1"})
    rows = t3_gate.proof(fz, [pr])
    rec("seal a proof whose receipt found JOIN_GATE_WAIVED", "NOT", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    pr = prove_inv("solo_one_layer_net", "ghat_net", "one_layer_net", [NET_ID], n=42)
    rows = t3_gate.proof(fz, [pr])
    rec("seal a proof, sealed receipt (clean)", "CERTIFIED", "CERTIFIED" if all(ok for ok, _ in rows.values()) else "NOT", list(rows.values())[0][1])
    # the launchers refuse BEFORE any game (no Godot started: exit 3 and no run folder)
    inv = "ctl_seal_%d" % os.getpid()
    env = dict(os.environ, ROLE="final", SPEED="fast", INV=inv, GATE_PROBE="1")
    r = subprocess.run(["bash", os.path.join(ROOT, "tools", "method_run.sh"), "ghat"], cwd=ROOT, env=env, capture_output=True, text=True)
    ivd = os.path.join(ROOT, "appdata", "method", "inv", inv)
    nodir = not any(f.endswith(".dir") for f in os.listdir(ivd)) if os.path.isdir(ivd) else False
    rec("seal method_run.sh ROLE=final + GATE_PROBE=1 (refused before launch)", "exit 3, no run",
        "exit %d, %s" % (r.returncode, "no run" if nodir else "a run"), (r.stdout + r.stderr).strip().splitlines()[-1:] )
    shutil.rmtree(ivd, ignore_errors=True)
    env = dict(os.environ, T1_LAG="x:1")
    r = subprocess.run([sys.executable, os.path.join(HERE, "prove_ghat.py"), "net"], cwd=ROOT, env=env, capture_output=True, text=True)
    rec("seal prove_ghat.py with T1_LAG set (refused before launch)", "exit 3", "exit %d" % r.returncode, r.stdout.strip()[-120:])
    env = dict(os.environ, GATE_NOABORT="1")
    r = subprocess.run(["bash", os.path.join(ROOT, "tools", "record_walk.sh"), "ghat", "--fresh"], cwd=ROOT, env=env, capture_output=True, text=True)
    rec("seal record_walk.sh ghat with GATE_NOABORT set (refused before launch)", "exit 3", "exit %d" % r.returncode, r.stdout.strip().splitlines()[-1:])


# ---- sentinel workload (F5) ----------------------------------------------------------------------
def g_sentinel():
    sw = os.path.join(HERE, "sentinel_workers.py")
    real = os.path.join(ROOT, "appdata", "t34", "sentinel_b_walk.log")
    run = lambda p: subprocess.run([sys.executable, sw, p], capture_output=True, text=True)
    d = fresh("sentinel")
    if os.path.exists(real):
        r = run(real)
        rec("sentinel R4's real lane b log (2 of 4 walks failed)", "REFUSED", "ACCEPTED" if r.returncode == 0 else "REFUSED", r.stdout.strip())
        # the clean pair: the same log with only its ok walks (every RESULT line ok)
        txt = open(real, encoding="utf-8", errors="replace").read().replace(chr(13), "")
        keep = [ln for ln in txt.split(chr(10)) if not ln.startswith("RESULT") or ln.startswith("RESULT: ok")]
        wr(os.path.join(d, "clean.log"), chr(10).join(keep))
        r = run(os.path.join(d, "clean.log"))
        rec("sentinel the same log, failed walks' RESULT lines removed", "ACCEPTED", "ACCEPTED" if r.returncode == 0 else "REFUSED", r.stdout.strip())
    else:
        rec("sentinel R4's real lane b log present", "present", "missing", real)
    wr(os.path.join(d, "none.log"), "lane b never played a walk" + chr(10))
    r = run(os.path.join(d, "none.log"))
    rec("sentinel no worker walk at all", "REFUSED", "ACCEPTED" if r.returncode == 0 else "REFUSED", r.stdout.strip())


GROUPS = {"ident": g_ident, "manifest": g_manifest, "final": g_final, "proof": g_proof, "obs": g_obs,
          "sentinel": g_sentinel, "matrix": g_matrix, "seal": g_seal}


def main(a):
    os.makedirs(CTL, exist_ok=True)
    for g in (a or list(GROUPS)):
        print("== %s" % g)
        GROUPS[g]()
    print("T3 offline controls: %d / %d as expected" % (RESULTS.count(True), len(RESULTS)))
    return 0 if all(RESULTS) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
