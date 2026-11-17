"""T3 v2 small offline gates (speed research, 2026-11-14). Reads receipts only; never launches a game.

  python tools/method/t3_gate.py final <inv dir> [<frozen tree.json>]
      The small final checker: ACCEPT only an explicitly final (ROLE=final), complete all-seven k3 clean
      suite in ONE invocation: combine_parts PASS; the requested parts together = exactly the seven
      scenarios, each once; profile k3; no fixture; no restored point (FROM_POINT) and no early stop;
      every part's input tree the same before and after its run and across parts (and = the frozen tree
      if given); every part's game checked gone; fast parts only on the qualified routing (FAST_ACCEPTED);
      ghat_marks only after its looks prelude in the same run, the prelude's round PASSED (F6);
      pictures (F7, tools/method/captures.py): every required picture of every part in its capture
      inventory, captured and written after the launch, its file's bytes = the captured ones, no file
      standing for two pictures, and a line for it in <inv dir>/inspection.md (`<scenario>/<tag>: what
      it shows`, written by the runner after looking at it).
      Missing required checks / work / rules are the verdict's job (its PASS already needs them).
  python tools/method/t3_gate.py proof <final inv dir> <prove inv dir> [...]
      Proof compatibility: a plant is CERTIFIED only if prove_ghat's own judge says PROVED on its exact
      ids, its invocation's input tree equals the final suite's (unchanged during both), its own
      manifest ids PASSED in the clean final run (its rule ids not FAILed there), and (D2 A) it was
      proved ALONE: a member of a multi-plant group needs a single-plant proof of its own.
  python tools/method/t3_gate.py matrix <final inv dir> <frozen tree.json> <prove inv dir> [...]
      F8 reconciliation: every plant row (Plant.on in the game: R4's 21 + any new one) against the proofs
      given: CERTIFIED / NOT CERTIFIED (why) / NOT DONE (no proof, or no matrix group). Refused while the
      inputs differ from the frozen tree (new checks / plants go in before the freeze, else refreeze + a
      new final + the proofs again) or the final is not accepted on it. Exit 0 only with every row CERTIFIED.
  python tools/method/t3_gate.py obstable <table.md> [manifest.json]
      The design-to-observation table: every row needs an observation (a manifest check id, or
      "picture:"/"video:" with what to look at); an empty one is a GAP, an unknown check id is UNKNOWN.
      Exit 1 while any GAP / UNKNOWN remains (a missing behaviour is never green by default).
Exit 0 = accepted / certified all / no gaps; 1 = refused (every reason printed).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import captures  # noqa: E402
import combine_parts  # noqa: E402
import prove_ghat  # noqa: E402

SEVEN = ["ghat_heat", "ghat_looks", "ghat_net", "ghat_places", "ghat_jug", "ghat_spring", "ghat_marks"]
# T1 qualification round 2's final table: fast PASS accepted for these only (looks' glass check, jug,
# places, spring: 1x). The split part names in method_run.sh: "fast" / "1x"; a plain run: "single" (1x).
FAST_ACCEPTED = {"ghat_heat", "ghat_net", "ghat_marks"}
TREE_KEYS = ("game", "test", "tools", "bin")


def rd(p):
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def rj(p):
    t = rd(p)
    try:
        return json.loads(t) if t else None
    except ValueError:
        return None


def parts_of(invd):
    out = []
    for ln in (rd(os.path.join(invd, "expected")) or "").splitlines():
        f = ln.split("\t")
        if len(f) >= 2 and f[0]:
            out.append((f[0], f[1], f[2] if len(f) > 2 else ""))
    return out


def tree_of(run_dir, why, label):
    pre, post = rj(os.path.join(run_dir, "tree_pre.json")), rj(os.path.join(run_dir, "tree_post.json"))
    if not pre or not post:
        why.append("%s: input tree identity not recorded (tree_pre / tree_post)" % label)
        return None
    bad = [k for k in TREE_KEYS if pre.get(k) != post.get(k) or not pre.get(k)]
    if bad:
        why.append("%s: inputs changed DURING the run (%s)" % (label, ", ".join("%s %s -> %s" % (k, pre.get(k), post.get(k)) for k in bad)))
    return {k: pre.get(k) for k in TREE_KEYS}


# F6 (fix round): marks' PASS counts only with its looks prelude in the SAME run (one process), before
# marks, and that prelude's round PASSED (T1 round 2: no round -> no marks on the van to clear).
PRELUDE_ID = prove_ghat.PREREQ["marks_pile"][0]


def marks_prelude(scens, vj, lab):
    sc = [s for s in scens.split(",") if s]
    if "ghat_marks" not in sc:
        return []
    asked = vj.get("asked") or []
    if "ghat_looks" not in sc or sc.index("ghat_looks") > sc.index("ghat_marks"):
        return ["%s: ghat_marks without its looks prelude before it in the same run (%s)" % (lab, ",".join(sc))]
    if asked != sc:
        return ["%s: the run asked %s, the part %s (the prelude order is not on record)" % (lab, asked, sc)]
    if PRELUDE_ID not in set(vj.get("passed_ids", [])):
        return ["%s: ghat_marks' looks prelude made no round in this run (%s not PASSED): marks' PASS not counted" % (lab, PRELUDE_ID)]
    return []


def sealed(invd, role):
    """F9: the invocation's seal receipt (tools/method/seal.py, written by method_run.sh before any launch)."""
    s = rj(os.path.join(invd, "seal.json"))
    if not s:
        return ["no seal receipt (seal.json): test-only flags not checked for this %s run" % role]
    if s.get("role") != role or not s.get("sealed"):
        return ["seal receipt: role %s, sealed %s, test-only flags %s (an acceptance %s run needs none)" % (s.get("role"), s.get("sealed"), s.get("found"), role)]
    return []


def final(invd, frozen=None):
    why = []
    inv = os.path.basename(os.path.normpath(invd))
    worst, lines = combine_parts.combine(invd)
    if worst != "PASS":
        why.append("combined result %s: %s" % (worst, " | ".join(x.strip() for x in lines[1:])[:400]))
    why += sealed(invd, "final")
    parts = parts_of(invd)
    # F7: the runner's inspection file, one line per required picture: `<scenario>/<tag>: what it shows`
    ip = os.path.join(invd, "inspection.md")
    insp = captures.inspection(ip)
    if not os.path.exists(ip):
        why.append("no inspection file %s (one line per required picture: `<scenario>/<tag>: what it shows`)" % ip)
    scen = [s for _, sc, _ in parts for s in sc.split(",") if s]
    if sorted(scen) != sorted(SEVEN) or len(scen) != len(set(scen)):
        why.append("requested %s: the final suite is exactly the seven scenarios, each once (a subset or a GHAT= continuation is diagnostic)" % scen)
    trees = {}
    for part, sc, fx in parts:
        lab = "part %s" % part
        if fx:
            why.append("%s: fixture '%s' (a clean suite has none)" % (lab, fx))
        if part == "fast":
            extra = [s for s in sc.split(",") if s and s not in FAST_ACCEPTED]
            if extra:
                why.append("%s: %s ran fast, not qualified fast (routing: %s fast, the rest 1x)" % (lab, extra, sorted(FAST_ACCEPTED)))
        d = (rd(os.path.join(invd, part + ".dir")) or "").strip()
        if not d:
            why.append("%s: no run folder" % lab)
            continue
        m = rj(os.path.join(d, "run_meta.json"))
        if not m:
            why.append("%s: no run_meta.json (role / exit unknown)" % lab)
            continue
        if m.get("inv") != inv or m.get("part") != part:
            why.append("%s: run_meta bound to %s/%s" % (lab, m.get("inv"), m.get("part")))
        if m.get("role") != "final":
            why.append("%s: role '%s' (only an explicitly final run, ROLE=final)" % (lab, m.get("role")))
        if m.get("profile") != "k3":
            why.append("%s: profile %s (k3)" % (lab, m.get("profile")))
        if m.get("from_point"):
            why.append("%s: started from a restored point %s" % (lab, m.get("from_point")))
        if m.get("early_stop_ids"):
            why.append("%s: an early-stop run (EXPECT_IDS) is not a complete suite" % lab)
        if m.get("godot_left_in_lane"):
            why.append("%s: a game was left running in its lane (%s)" % (lab, m.get("godot_left_in_lane")))
        vj = rj(os.path.join(d, "verdict.json")) or {}
        if vj.get("early_stop"):
            why.append("%s: the verdict records an early stop" % lab)
        if vj.get("godot_left_after"):
            why.append("%s: Godot left after the run: %s" % (lab, vj.get("godot_left_after")))
        why += marks_prelude(sc, vj, lab)
        why += captures.check(d, [s for s in sc.split(",") if s], insp, lab)
        t = tree_of(d, why, lab)
        if t:
            trees[part] = t
    if len(set(json.dumps(t, sort_keys=True) for t in trees.values())) > 1:
        why.append("the parts ran on different input trees: %s" % trees)
    if frozen and trees:
        fz = rj(frozen) or {}
        for part, t in trees.items():
            bad = [k for k in TREE_KEYS if t.get(k) != fz.get(k)]
            if bad:
                why.append("part %s: not the frozen tree (%s)" % (part, ", ".join(bad)))
    return why, trees


def group_of(inv):
    m = re.match(r"prove_(.+)_\d{8}_\d{6}_\d+$", inv)
    g = m.group(1) if m else ""
    return g if g in prove_ghat.GROUPS else None


def proof(final_invd, prove_invds):
    rows, fwhy = {}, []
    fw, ftrees = final(final_invd)
    if fw:
        fwhy.append("the clean final suite is not accepted: " + "; ".join(fw))
    ftree = next(iter(ftrees.values()), None)
    fpassed, ffailed = set(), set()
    for part, _, _ in parts_of(final_invd):
        d = (rd(os.path.join(final_invd, part + ".dir")) or "").strip()
        vj = rj(os.path.join(d, "verdict.json")) or {}
        fpassed |= set(vj.get("passed_ids", []))
        ffailed |= set(vj.get("failed_ids", []))
    proved_alone = set()
    judged = []
    for pd in prove_invds:
        inv = os.path.basename(os.path.normpath(pd))
        g = group_of(inv)
        if not g:
            judged.append((inv, None, {}, ["not a prove_ghat group invocation (prove_<group>_<time>_<pid>)"]))
            continue
        scen, plants, expect = prove_ghat.GROUPS[g]
        prob, d, res = prove_ghat.judge(pd, scen, plants, expect)
        w = sealed(pd, "proof")
        if d:
            t = tree_of(d, w, inv)
            if t and ftree and t != ftree:
                w.append("%s: another input tree than the clean final (%s)" % (inv, ", ".join(k for k in TREE_KEYS if t[k] != ftree[k])))
        judged.append((inv, g, res, w))
        # F8: "alone" = ONE behavioural plant in the run (time-saver flags one_flat / one_corner aren't bugs)
        if len(expect) == 1 and len(prove_ghat.behavioural(plants)) == 1:
            for pl, (ok, _) in res.items():
                if ok and not w:
                    proved_alone.add(pl)
    for inv, g, res, w in judged:
        if g is None:
            rows["?" + inv] = (False, w[0])
            continue
        scen, plants, expect = prove_ghat.GROUPS[g]
        for pl, (ok, why) in res.items():
            r = []
            if not ok:
                r.append("NOT PROVED: " + why)
            r += w + fwhy
            ids = expect[pl]
            notpass = [x for x in ids if "/" in x and x not in fpassed]
            rulefail = [x for x in ids if "/" not in x and x in ffailed]
            if notpass:
                r.append("its check(s) did not PASS in the clean final: %s" % notpass)
            if rulefail:
                r.append("its rule(s) FAILed in the clean final: %s" % rulefail)
            if (len(expect) > 1 or len(prove_ghat.behavioural(plants)) > 1) and pl not in proved_alone:
                r.append("proved only in a batch (%s): causality not established; prove it alone (D2 A)" % g)
            key = "%s (%s)" % (pl, inv)
            rows[key] = (not r, "; ".join(r) if r else "CERTIFIED: own ids %s FAILed alone, PASS in the clean final, same tree" % " + ".join(ids))
    return rows


ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PLANT_ON = re.compile(r'Plant\.on\("([a-z_0-9]+)"\)')


def plant_rows(root=ROOT):
    """F8: every plant the game can switch on (Plant.on("...") in FindingNaresh/scripts), time savers out, and the
    plants another puzzle's own test proves (prove_ghat.ELSEWHERE, e.g. the ramp's wheel_unlinked) out."""
    names = []
    for dp, _, fs in os.walk(os.path.join(root, "FindingNaresh", "scripts")):
        for f in sorted(fs):
            if f.endswith(".gd"):
                for n in PLANT_ON.findall(rd(os.path.join(dp, f)) or ""):
                    if n not in prove_ghat.SHORTCUTS and n not in prove_ghat.ELSEWHERE and n not in names:
                        names.append(n)
    return sorted(names)


def matrix(final_invd, frozen, prove_invds, root=ROOT, now=None):
    """F8 reconciliation: every plant row (main's 27 + any new Plant.on) against the proofs given.
    -> (problems, [(plant, status, why)]); complete only when no problem and every row CERTIFIED."""
    import tree_id
    probs = []
    fz = rj(frozen) or {}
    if not fz:
        probs.append("no frozen tree %s" % frozen)
    now = now or tree_id.identity(root)
    changed = [k for k in TREE_KEYS if now.get(k) != fz.get(k)]
    if fz and changed:
        probs.append("the inputs changed since the freeze (%s): a new check / plant goes in BEFORE the freeze; now: refreeze, "
                     "a new final suite, then the proofs again" % ", ".join(changed))
    fw, _ = final(final_invd, frozen)
    if fw:
        probs.append("the final suite is not accepted on the frozen tree: " + "; ".join(fw))
    certs = proof(final_invd, prove_invds) if prove_invds else {}
    out = []
    owners = {}
    for g in prove_ghat.MATRIX:
        for pl in prove_ghat.GROUPS[g][2]:
            owners[pl] = g
    for pl in plant_rows(root):
        mine = [(k, ok, w) for k, (ok, w) in certs.items() if k.split(" ", 1)[0] == pl]
        if pl not in owners:
            out.append((pl, "NOT DONE", "no matrix group for this plant: add a solo group to prove_ghat.py GROUPS + MATRIX before the freeze"))
        elif any(ok for _, ok, _ in mine):
            out.append((pl, "CERTIFIED", next(k for k, ok, _ in mine if ok)))
        elif mine:
            out.append((pl, "NOT CERTIFIED", " | ".join(w for _, _, w in mine)[:300]))
        else:
            out.append((pl, "NOT DONE", "no proof given (run: prove_ghat.py %s)" % owners[pl]))
    return probs, out


ROW = re.compile(r"^\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*$")


def obstable(path, manifest=None):
    """Markdown rows: | # | behaviour (sealed design) | producer / input | observed by |"""
    ids = set()
    if manifest:
        man = rj(manifest) or {}
        ids = {r["id"] for v in man.values() for r in v}
    out, bad = [], 0
    for ln in (rd(path) or "").splitlines():
        m = ROW.match(ln)
        if not m or m.group(1) in ("#", "") or set(m.group(1)) <= set("-: "):
            continue
        n, beh, prod, obs = m.groups()
        st = "OK"
        if not obs or obs.lower() in ("-", "none", "gap", "?"):
            st = "GAP"
        else:
            for o in [x.strip() for x in obs.split(";") if x.strip()]:
                if o.startswith(("picture:", "video:")):
                    if len(o.split(":", 1)[1].strip()) < 5:
                        st = "GAP (say what the picture / video moment shows)"
                elif ids and o not in ids:
                    st = "UNKNOWN check id %s" % o
                elif not ids and "/" not in o:
                    st = "UNKNOWN observation %s (a check id, picture: or video:)" % o
        if not prod or prod.lower() in ("-", "none", "?"):
            st = st if st != "OK" else "GAP (no real producer / input)"
        bad += st != "OK"
        out.append("%-3s %-60s %s" % (n, beh[:60], st))
    return out, bad


def main(a):
    if not a:
        print(__doc__)
        return 2
    if a[0] == "final":
        why, trees = final(a[1], a[2] if len(a) > 2 else None)
        print("FINAL %s: %s" % ("ACCEPTED" if not why else "REFUSED", os.path.basename(os.path.normpath(a[1]))))
        for w in why:
            print("  - " + w)
        return 0 if not why else 1
    if a[0] == "proof":
        rows = proof(a[1], a[2:])
        for k, (ok, why) in rows.items():
            print("%-14s %s  %s" % ("CERTIFIED" if ok else "NOT CERTIFIED", k, why))
        return 0 if rows and all(ok for ok, _ in rows.values()) else 1
    if a[0] == "matrix":
        probs, out = matrix(a[1], a[2], a[3:])
        for p in probs:
            print("PROBLEM  " + p)
        for pl, st, w in out:
            print("%-14s %-16s %s" % (st, pl, w))
        done = sum(1 for _, st, _ in out if st == "CERTIFIED")
        print("plant matrix: %d / %d rows CERTIFIED%s" % (done, len(out), "" if not probs else ", %d problem(s)" % len(probs)))
        return 0 if not probs and out and done == len(out) else 1
    if a[0] == "obstable":
        out, bad = obstable(a[1], a[2] if len(a) > 2 else None)
        print("\n".join(out))
        print("observation table: %d row(s), %d not covered" % (len(out), bad))
        return 0 if not bad and out else 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
