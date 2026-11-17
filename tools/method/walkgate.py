"""T4 v2 resume gate (speed research): judge a walk's save point and a resume of it.

Evidence (written by the game, dev/LiveControl.gd + dev/GateObs.gd), per walk run folder
<live>/points/<run>/: run.json (identity, profile), walk.json, walk.log, <i>.json (the point),
<i>.obs.json (independent observation in the point's tick), <i>.t3.json (+3 game s sample: observation,
walk lines, messages, inputs), and for a resume <k>.restored.obs.json (observed right after the restore,
before any await). Rules and tolerances: tools/method/gate_inventory.json (written before the trials).

  refusal(point obs)        boundary rules: engine on / van > 0.1 m/s, hearing activity, open work,
                            held input, running helper, tweens, unsupported state (D4 A)
  layer1(obs)               every observed field classified; every required field observed
  layer2(point, restored)   exact equality after the documented volatile normalisations only
  layer3(fresh t3, resume t3)  trajectory at +3 game s: discrete exact, continuous within tolerance,
                            same event / message order, same inputs (times within tolerance)
  next_step(fresh, resume)  the resumed step's expect lines (PASS / FAIL names, order, times)
  identity(point, now)      same game, test, bin, schema, profile; walk steps before the point unchanged
                            (producer) and the resumed step on unchanged (its fresh reference)
A boundary is SAME only with >= RESUMES (2, D3 A) resume receipts SAME on all layers, same profile.

CLI (offline, no game):
  python tools/method/walkgate.py refuse <run_dir> <i>
  python tools/method/walkgate.py l2 <point_run_dir> <i> <resume_run_dir>
  python tools/method/walkgate.py l3 <point_run_dir> <i> <resume_run_dir>
  python tools/method/walkgate.py boundary <point_run_dir> <i> [<resume_run_dir> ...]
"""
import hashlib
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
INV_PATH = os.path.join(HERE, "gate_inventory.json")
SCHEMA = "t4v2-gate-1"
RESUMES = int(os.environ.get("GATE_RESUMES", "2"))       # D3 A: two resumes per boundary (B would be 1)


def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def inv():
    return load(INV_PATH)


# ---- resume fix v1 (2026-11-17, notes/speed_research/resume_fix_design.md v2, GPT-audited) ------------
RV = "rv1"
SEED_PROTO = "seed-v1"
AGE_TOL_MS = 20.0          # wall ms between a re-applied clock and its observation (ages frozen while held)


def validate_rv1(point, problem_out=False):
    """[] when the point carries a complete, well-formed rv1 record; else what is wrong. Fails closed on
    anything missing or malformed (GPT audit #7)."""
    if not isinstance(point, dict) or point.get("resume_v") is None:
        return ["not an rv1 point"]
    why = []
    if point.get("resume_v") != RV:
        why.append("resume_v %r != %s" % (point.get("resume_v"), RV))
    if point.get("seed_proto") != SEED_PROTO:
        why.append("seed_proto %r != %s" % (point.get("seed_proto"), SEED_PROTO))
    sd = point.get("rng_seed")
    if not (_finite(sd) and float(sd).is_integer() and 0 <= sd < 2 ** 31):
        why.append("rng_seed missing / not a finite integer (seed-v1: hash & 0x7fffffff)")
    if not isinstance(point.get("wall_ms"), (int, float)):
        why.append("wall_ms missing")
    b = point.get("live_bodies")
    if not isinstance(b, list) or not any(isinstance(x, dict) and x.get("key") == "van" for x in b):
        why.append("live_bodies missing the van")
    elif not all(isinstance(x, dict) and all(k in x for k in ("key", "freeze", "freeze_mode", "sleeping", "lv", "av")) for x in b):
        why.append("live_bodies entry malformed")
    v = point.get("live_vars")
    if not isinstance(v, dict) or not v.get("van") or not all(isinstance(v.get(k), d) for k, d in (("van", dict), ("attack", dict), ("items", dict), ("players", list))):
        why.append("live_vars missing / malformed")
    elif len(v["players"]) != 2:
        why.append("live_vars players: %d (2 needed)" % len(v["players"]))
    if not isinstance(point.get("live_frames"), list) or not isinstance(point.get("phys_frame"), (int, float)):
        why.append("live_frames / phys_frame missing")
    if not isinstance(point.get("live_refs"), dict):
        why.append("live_refs missing")
    pl = point.get("live_players")
    if not isinstance(pl, list) or len(pl) != 2 or not all(isinstance(x, dict) and "xf" in x and "vel" in x for x in pl):
        why.append("live_players missing / malformed")
    c = point.get("live_clock")
    if not isinstance(c, list):
        why.append("live_clock missing")
    elif not all(isinstance(e, dict) and e.get("unit") in ("ms", "s") and all(k in e for k in ("own", "field", "unset"))
                 and (e.get("unset") or isinstance(e.get("age"), (int, float))) for e in c):
        why.append("live_clock entry malformed")
    h = point.get("live_hearing")
    if not isinstance(h, dict) or not isinstance(h.get("next_id"), (int, float)) or not isinstance(h.get("events"), list):
        why.append("live_hearing missing / malformed")
    elif not all(isinstance(e, dict) and all(k in e for k in ("id", "pos", "radius", "what", "age")) for e in h["events"]):
        why.append("live_hearing event malformed")
    if problem_out and not (isinstance(point.get("live_problem_children"), dict) and point["live_problem_children"].get("count", 0) > 0):
        why.append("Problem out but live_problem_children missing")
    return why


def point_sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def gate_hash():
    """The judges a receipt was made with (this file + the inventory): a REPAIR needs the same."""
    h = hashlib.sha256()
    for p in (os.path.abspath(__file__), INV_PATH):
        with open(p, "rb") as f:
            h.update(f.read())
    return h.hexdigest()[:16]


def _finite(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)


def coverage_rv1(point, f):
    """GPT results audit #4b: the record must COVER what the observation shows, with typed, finite contents
    (empty or partial records were admitted by validate_rv1 alone)."""
    why = []
    items = sorted(set(k[5:k.index("]")] for k in f if k.startswith("item[")))
    bodies = {b.get("key"): b for b in point.get("live_bodies", []) if isinstance(b, dict)}
    for it in items:
        b = bodies.get("item:" + it)
        if b is None:
            why.append("no body record for item %s" % it)
        elif not all(isinstance(b.get(k), str) and b.get(k) for k in ("xf", "lxf", "parent", "lv", "av")):
            why.append("body record of %s incomplete (xf / lxf / parent / lv / av)" % it)
    vb = bodies.get("van")
    if vb is not None and not all(isinstance(vb.get(k), str) and vb.get(k) for k in ("xf", "lxf", "parent", "lv", "av")):
        why.append("the van's body record incomplete")
    v = point.get("live_vars") or {}
    missing_iv = [it for it in items if it not in (v.get("items") or {})]
    if missing_iv:
        why.append("no vars for items %s" % missing_iv[:4])
    if not all(isinstance(x, dict) and x for x in (v.get("players") or [])):
        why.append("a player's vars are empty")
    clock = point.get("live_clock") or []
    have = {(e.get("own"), e.get("field")) for e in clock if isinstance(e, dict)}
    need = [("van", "_cap_t")] + [("item:" + it, "_last_hit_t") for it in items]
    if _problem_present(f):
        need.append(("problem", "_item_ms"))
    lost = [n for n in need if n not in have]
    if lost:
        why.append("live_clock misses %s" % lost[:4])
    units = {"_cap_t": "s", "_item_ms": "ms", "_last_hit_t": "ms"}      # GPT final audit: units bound to the field
    bad_u = [(e.get("own"), e.get("field")) for e in clock if isinstance(e, dict) and units.get(e.get("field")) != e.get("unit")]
    if bad_u:
        why.append("live_clock unit / field not supported %s" % bad_u[:3])
    if any(not e.get("unset") and not _finite(e.get("age")) for e in clock if isinstance(e, dict)):
        why.append("live_clock has a non-finite age")
    fr = point.get("live_frames") or []
    have_f = {(e.get("own"), e.get("field")) for e in fr if isinstance(e, dict)}
    need_f = [("attack", "_last_pull"), ("attack", "_hold_start"), ("attack", "_done_f"), ("p0", "_climb_since"), ("p1", "_climb_since")]
    if [n for n in need_f if n not in have_f]:
        why.append("live_frames misses %s" % [n for n in need_f if n not in have_f])
    kinds = {"_last_pull": "dict", "_hold_start": "dict", "_done_f": "int", "_climb_since": "int"}   # ResumeV1.FRAMES
    for e in fr:
        if not isinstance(e, dict) or kinds.get(e.get("field")) is None or e.get("kind") != kinds[e["field"]]                 or (e["kind"] == "dict" and not (isinstance(e.get("ages"), dict) and all(_finite(x) for x in e["ages"].values())
                                                 and all(str(k) in ("0", "1") for k in e["ages"])))                 or (e["kind"] == "int" and not e.get("unset") and not _finite(e.get("age"))):
            why.append("live_frames entry malformed / unsupported kind: %r" % (e,))
            break
    r = point.get("live_refs") or {}
    if not (isinstance(r.get("targets"), list) and len(r["targets"]) == 2 and all(isinstance(t, str) for t in r["targets"])
            and isinstance(r.get("window_fog"), dict) and all(_finite(x) for x in r["window_fog"].values())):
        why.append("live_refs incomplete (2 targets, window_fog numbers)")
    h = point.get("live_hearing") or {}
    if any(not _finite(e.get("age")) for e in h.get("events", []) if isinstance(e, dict)):
        why.append("live_hearing has a non-finite age")
    if _problem_present(f):
        c = point.get("live_problem_children") or {}
        # one saved pose per child pose the observation shows (GPT final audit: a missing child passed)
        n_obs = sum(1 for k in f if k.startswith("problem/") and k.endswith(".@local"))
        n_scr = len({k[:k.rindex(".")] for k in f if k.startswith("problem/") and not k.split(".")[-1].startswith("@")})
        # every built child has a pose (count == poses; a non-3D child is unsupported: fails closed); the observation
        # collapses auto-named siblings ("@X@#"), so it can only bound the poses from below
        if not (isinstance(c.get("xf"), dict) and len(c["xf"]) >= n_obs and n_obs > 0 and isinstance(c.get("count"), (int, float))
                and c["count"] == len(c["xf"]) and isinstance(c.get("vars"), dict) and len(c["vars"]) >= n_scr
                and all(isinstance(v, str) and v for v in c["xf"].values()) and "eye_energy" in c and "glow_color" in c):
            why.append("Problem's children record incomplete (%d poses saved, %d observed; %d child scripts saved, %d observed)"
                       % (len(c.get("xf") or {}), n_obs, len(c.get("vars") or {}), n_scr))
    return why


def _rv1_ok(point, f):
    if not isinstance(point, dict) or point.get("resume_v") is None:
        return False, []
    why = validate_rv1(point, _problem_present(f))
    if not why:
        why = coverage_rv1(point, f)
    return (not why), why


def _no_rng_draw(f):
    """seed-v1 lifts the global-RNG refusal only while no GAMEPLAY draw can run in the step (GPT audit #4):
    Problem passive and leaving, not crouched (it sniffs, drawing randf, only crouched: Creature.gd 668-671),
    no player shake (PlayerRig 420 draws per drawn frame while shaking)."""
    return (f.get("ghat.phase") == '"leave"' and f.get("problem.passive") == "true"
            and f.get("problem.pose") != '"crouch"'
            and all(f.get("p%d._shake_t" % i, "0.0") in ("0.0", "0") for i in (1, 2)))


def _fields(obs):
    return obs["fields"] if "fields" in obs else obs


# ---- value parsing (Godot var_to_str) ------------------------------------------------------------
NUM = r"[-+]?(?:\d+\.?\d*(?:[eE][-+]?\d+)?|inf|nan)"


def nums(s):
    """The numbers of a value. Only INSIDE the brackets of a typed value: the type name itself has a
    digit (Vector3, Transform3D), which the first version read as a number (found by t4_controls:
    every velocity / transform check was silently skipped or 'not a transform')."""
    s = str(s)
    if "(" in s and s.rstrip().endswith(")"):
        s = s[s.index("(") + 1:s.rstrip().rindex(")")]
    return [float(x) for x in re.findall(NUM, s.replace("inf_neg", "-inf"))]


def parse_xf(s):
    """Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz) -> (basis 9, origin 3)."""
    v = nums(s)
    if not s.startswith("Transform3D") or len(v) != 12:
        return None
    return v[:9], v[9:]


def rot_deg(b1, b2):
    # angle of R1^T R2 from its trace (basis columns as written: rows here, same for both)
    import itertools
    m1 = [b1[0:3], b1[3:6], b1[6:9]]
    m2 = [b2[0:3], b2[3:6], b2[6:9]]
    tr = sum(m1[i][k] * m2[i][k] for i, k in itertools.product(range(3), range(3)))
    c = max(-1.0, min(1.0, (tr - 1.0) / 2.0))
    return math.degrees(math.acos(c))


# ---- normalisation (layer 2's only allowed edits) ---------------------------------------------------
def normalise(obs, cfg):
    f = dict(_fields(obs))
    now = (obs.get("meta") or {}).get("wall_ms")
    notes = []
    for v in cfg["volatile"]:
        rx = re.compile(v["pattern"])
        for k in list(f):
            if rx.search(k):
                f[k] = "<volatile>"
    for pat, w in cfg["wallstamps"]["fields"].items():
        rx = re.compile(pat)
        for k in list(f):
            if not rx.search(k):
                continue
            try:
                t = float(nums(f[k])[0])
            except (IndexError, ValueError):
                continue
            if now is None:
                f[k] = "<no clock>"
                continue
            age = (now - t) if w["unit"] == "ms" else (now / 1000.0 - t)
            if w.get("unset") is not None and t == w["unset"]:
                f[k] = "<unset>"
            elif age >= w["window"]:
                f[k] = "<expired>"
            else:
                # rv1: the live age is compared separately within AGE_TOL_MS (layer2), same side of the window here
                f[k] = "<live>"
                notes.append((k, age * (1.0 if w["unit"] == "ms" else 1000.0)))
    # physics-frame stamps (resume fix v1): compared as AGES at the observation's frame (frames run on in a
    # new process and while paused); unset sentinels kept
    pf = (obs.get("meta") or {}).get("physics_frames")
    for pat, w in cfg.get("framestamps", {}).items():
        rx = re.compile(pat)
        for k in list(f):
            if not rx.search(k) or pf is None:
                continue
            if w["kind"] == "dict":
                f[k] = re.sub(r"(player:\d+): (-?\d+)", lambda m: "%s: age %d" % (m.group(1), pf - int(m.group(2))), f[k])
            else:
                try:
                    t = int(nums(f[k])[0])
                except (IndexError, ValueError):
                    continue
                f[k] = "<unset>" if t == w.get("unset") else "<age %d frames>" % (pf - t)
    # the Hearing queue: only its unconsumed / recent part matters (pruning happens on emit)
    if "static.Hearing.recent" in f:
        rec = json.loads(f["static.Hearing.recent"]) if f["static.Hearing.recent"].startswith("[") else []
        heard = _heard_ids(f)
        live = [e for e in rec if (now is not None and now - e["t"] < 2000) or any(e["id"] > h for h in heard)]
        # rv1: ids and radius too (the serial is restored); each live event's age compared within AGE_TOL_MS
        # + the side of Hearing's prune boundary (Hearing.gd 30: pruned on the next emit when now - t > 2000)
        f["static.Hearing.recent"] = "<consumed and old>" if not live else json.dumps(
            [[e["id"], e["what"], e["pos"], e.get("r"), "kept" if now is not None and now - e["t"] <= 2000 else "prunable"] for e in live])
        for e in live:
            if now is not None:
                notes.append(("static.Hearing.recent#%d" % e["id"], float(now - e["t"])))
    # the serial counter matters only relative to a listener
    if not _problem_present(f) and "static.Hearing._next_id" in f:
        f["static.Hearing._next_id"] = "<no listener>"
    return f, notes


def _heard_ids(f):
    out = []
    for k, v in f.items():
        if k.endswith("._heard_id"):
            try:
                out.append(int(nums(v)[0]))
            except IndexError:
                pass
    return out


def _problem_present(f):
    return any(k.startswith("problem.") for k in f)


def _item_moving(f):
    for k, v in f.items():
        if k.startswith("item[") and k.endswith(".@lv"):
            n = nums(v)
            if len(n) == 3 and math.sqrt(sum(x * x for x in n)) > 0.05:
                return True
    return False


ACTIVE = {"problem_present": _problem_present, "item_moving": _item_moving, "never": lambda f: False}


# ---- boundary refusal (before any input) -----------------------------------------------------------
def refusal(obs, cfg=None, point=None):
    """point: the save point's JSON; a valid rv1 record lifts the refusals for what it restores (frozen van's
    stored speed, hearing, listener serial, wall stamps, the global RNG while no gameplay draw can run).
    None / no record = the T4 v2 rules as before."""
    cfg = cfg or inv()
    f = _fields(obs)
    now = (obs.get("meta") or {}).get("wall_ms")
    why = []
    rv1, rv1_why = _rv1_ok(point, f)
    if isinstance(point, dict) and point.get("resume_v") is not None and not rv1:
        why.append("rv1 record malformed: %s" % "; ".join(rv1_why))
    # GPT audit #5 / #2: no held-body, crouch or climb adapter: refused, rv1 or not
    for i in (1, 2):
        if f.get("p%d.held" % i, "null") != "null":
            why.append("p%d holds a carryable (a held body's contacts are not restored)" % i)
        if f.get("p%d.crouching" % i) == "true":
            why.append("p%d crouching (capsule state not restored)" % i)
        if f.get("p%d.ladder" % i, "null") != "null":
            why.append("p%d on a ladder (climb frame stamps not rebased)" % i)
    if f.get("van.engine_on") == "true":
        why.append("engine on (no van engine adapter: refused)")
    lv = nums(f.get("van.@lv", ""))
    if len(lv) == 3 and math.sqrt(sum(x * x for x in lv)) > 0.1 and not (rv1 and f.get("van.@freeze") == "true"):
        why.append("van moving %.2f m/s (> 0.1)%s" % (math.sqrt(sum(x * x for x in lv)),
                   " (frozen on the handbrake: a stale STORED velocity, which the restore zeroes: lost physics state)" if f.get("van.@freeze") == "true" else ""))
    if "static.Hearing.recent" in f and not rv1:
        rec = json.loads(f["static.Hearing.recent"]) if f["static.Hearing.recent"].startswith("[") else []
        heard = _heard_ids(f)
        recent = [e for e in rec if now is not None and now - e["t"] < 2000]
        uncons = [e for e in rec if any(e["id"] > h for h in heard)]
        if now is None:
            why.append("no wall clock in the observation: hearing ages unknown")
        if recent:
            why.append("hearing activity < 2 wall s old (%s)" % ", ".join("%s %d ms" % (e["what"], now - e["t"]) for e in recent))
        if uncons:
            why.append("unconsumed hearing events (%s)" % ", ".join("%s #%d" % (e["what"], e["id"]) for e in uncons))
    if _problem_present(f) and not rv1:
        why.append("a listener (Problem) is out: its hearing serial (_heard_id vs Hearing._next_id) cannot be restored (no rebase by design)")
    for pat, w in ([] if rv1 else cfg["wallstamps"]["fields"].items()):
        rx = re.compile(pat)
        for k, v in f.items():
            if rx.search(k):
                try:
                    t = float(nums(v)[0])
                except IndexError:
                    continue
                if now is None:
                    why.append("%s: no wall clock to age it" % k)
                    continue
                age = (now - t) if w["unit"] == "ms" else (now / 1000.0 - t)
                if (w.get("unset") is None or t != w["unset"]) and age < w["window"]:
                    why.append("%s inside its %s%s window (%s)" % (k, w["window"], w["unit"], w["why"]))
    if f.get("tree.@tweens", "0") not in ("0",):
        why.append("tweens running (%s)" % f["tree.@tweens"])
    if f.get("input.@held", "[]") != "[]":
        why.append("inputs held %s" % f["input.@held"])
    if f.get("test.@helpers_running", "0") != "0":
        why.append("a spawned helper runs (%s)" % f["test.@helpers_running"])
    if f.get("test.@open_watches", "[]") != "[]":
        why.append("open watches %s" % f["test.@open_watches"])
    if f.get("test.@needs", "[]") != "[]":
        why.append("needs not met %s" % f["test.@needs"])
    for u in cfg["unsupported"]:
        if ACTIVE[u["active_if"]](f):
            if u["name"] == "global_rng_problem" and rv1 and _no_rng_draw(f):
                continue
            why.append("unsupported state %s (%s)" % (u["name"], u["why"]))
    return sorted(set(why))


# ---- layer 1: the field inventory -----------------------------------------------------------------
def layer1(obs, cfg=None):
    cfg = cfg or inv()
    f = _fields(obs)
    rxs = [(re.compile(c["pattern"]), c) for c in cfg["classes"]]
    why = []
    for k in f:
        if not any(rx.search(k) for rx, _ in rxs):
            why.append("unclassified field %s" % k)
    for r in cfg["required"]:
        if r["when"] == "always" or ACTIVE[r["when"]](f):
            rx = re.compile(r["pattern"])
            if not any(rx.search(k) for k in f):
                why.append("required observation missing: %s" % r["pattern"])
    return why


# ---- layer 2: immediate exact comparison ----------------------------------------------------------
def layer2(point_obs, restored_obs, cfg=None):
    cfg = cfg or inv()
    a, na = normalise(point_obs, cfg)
    b, nb = normalise(restored_obs, cfg)
    diffs = []
    for k in sorted(set(a) | set(b)):
        if k.startswith("test.@open_watches") or k.startswith("test.@needs"):
            continue            # judged by refusal() on the point (the restore starts with none open)
        if a.get(k) != b.get(k):
            diffs.append((k, a.get(k, "<absent>"), b.get(k, "<absent>")))
    # live wall-clock ages (rv1 re-applies them right before each observation; another process's stamp shows)
    na, nb = dict(na), dict(nb)
    for k in sorted(set(na) & set(nb)):
        if abs(na[k] - nb[k]) > AGE_TOL_MS:
            diffs.append((k + " (age ms)", "%.0f" % na[k], "%.0f" % nb[k]))
    return diffs


# ---- layer 3: the trajectory at +3 game s ---------------------------------------------------------
def _strip_times(line):
    line = re.sub(r"\(\d+ s, frame \d+\)", "(t)", line)
    line = re.sub(r"\(\d+\.\d s(, watched)?\)", "(t)", line)
    line = re.sub(r" in \d+ s$", " in t", line)
    return line


def _line_time(line):
    m = re.search(r"\((\d+\.\d) s", line)
    return float(m.group(1)) if m else None


def layer3(fresh_t3, resume_t3, cfg=None):
    cfg = cfg or inv()
    tr = cfg["trajectory"]
    why = []
    for nm, t in (("fresh", fresh_t3), ("resume", resume_t3)):
        if t is None:
            why.append("no +3 s sample from the %s run" % nm)
    if why:
        return why
    if fresh_t3.get("failed_before") or resume_t3.get("failed_before"):
        why.append("a FAIL before +3 s (fresh %r, resume %r)" % (fresh_t3.get("failed_before"), resume_t3.get("failed_before")))
    for nm, t in (("fresh", fresh_t3), ("resume", resume_t3)):
        if int(t.get("at_game_ms", 0)) < 3000:
            why.append("%s sample at %d game ms (< 3000)" % (nm, int(t.get("at_game_ms", 0))))
    a, _ = normalise(fresh_t3["obs"], cfg)
    b, _ = normalise(resume_t3["obs"], cfg)
    disc = [re.compile(p) for p in tr["discrete"]]
    for k in sorted(set(a) | set(b)):
        if any(rx.search(k) for rx in disc) and a.get(k) != b.get(k):
            why.append("discrete %s: fresh %s, resume %s" % (k, a.get(k, "<absent>"), b.get(k, "<absent>")))
    for c in tr["continuous"]:
        rx = re.compile(c["pattern"])
        for k in sorted(set(a) | set(b)):
            if not rx.search(k):
                continue
            va, vb = a.get(k), b.get(k)
            if va is None or vb is None:
                why.append("continuous %s missing on one side" % k)
                continue
            if c["kind"] == "xf":
                xa, xb = parse_xf(va), parse_xf(vb)
                if xa is None or xb is None:
                    why.append("%s not a transform" % k)
                    continue
                d = math.dist(xa[1], xb[1])
                r = rot_deg(xa[0], xb[0])
                if d > c["pos_m"] or r > c["rot_deg"]:
                    why.append("%s moved %.3f m / %.2f deg apart (bounds %.2f m / %.1f deg)" % (k, d, r, c["pos_m"], c["rot_deg"]))
            else:
                na, nb = nums(va), nums(vb)
                if len(na) != len(nb) or not na:
                    why.append("%s not comparable (%s / %s)" % (k, va, vb))
                    continue
                d = math.dist(na, nb) if len(na) > 1 else abs(na[0] - nb[0])
                if d > c["abs"]:
                    why.append("%s differs by %.4f %s (bound %s)" % (k, d, c.get("unit", ""), c["abs"]))
    la = [_strip_times(x) for x in fresh_t3.get("lines", [])]
    lb = [_strip_times(x) for x in resume_t3.get("lines", [])]
    if la != lb:
        why.append("walk lines differ: fresh %s / resume %s" % (la, lb))
    else:
        for x, y in zip(fresh_t3.get("lines", []), resume_t3.get("lines", [])):
            tx, ty = _line_time(x), _line_time(y)
            if tx is not None and ty is not None and abs(tx - ty) > tr["events_time_s"]:
                why.append("'%s' at %.1f s vs %.1f s" % (_strip_times(x), tx, ty))
    ma = [m[1:] for m in fresh_t3.get("messages", [])]
    mb = [m[1:] for m in resume_t3.get("messages", [])]
    if ma != mb:
        why.append("messages differ: fresh %s / resume %s" % (ma, mb))
    else:
        for x, y in zip(fresh_t3["messages"], resume_t3["messages"]):
            if abs(x[0] - y[0]) / 1000.0 > tr["events_time_s"]:
                why.append("message '%s' at %d vs %d game ms" % (x[3], x[0], y[0]))
    ia = [i[1:] for i in fresh_t3.get("inputs", [])]
    ib = [i[1:] for i in resume_t3.get("inputs", [])]
    if ia != ib:
        why.append("inputs differ (%d fresh, %d resume): first difference %s" % (len(ia), len(ib), next(((x, y) for x, y in zip(ia + [None] * 9, ib + [None] * 9) if x != y), None)))
    else:
        worst = max([abs(x[0] - y[0]) for x, y in zip(fresh_t3["inputs"], resume_t3["inputs"])] or [0])
        if worst / 1000.0 > tr["inputs_time_s"]:
            why.append("an input %d game ms off (bound %.0f)" % (worst, tr["inputs_time_s"] * 1000))
    return why


def step_block(walk_log_lines, step_name):
    """The lines of one step (its step line up to the next step line / the end line)."""
    out, on = [], False
    for ln in walk_log_lines:
        if ln.startswith("step "):
            if on:
                break
            on = ln.startswith("step %s (" % step_name)
        if on:
            out.append(ln)
    return out


EXTERNAL_BREAK = ("FAIL deliberate break", "FAIL the client saw in the log")


def next_step(fresh_lines, resume_lines, step_name, cfg=None):
    """The resumed step's outcomes (PASS / FAIL lines) must be the fresh run's. A fresh run broken
    from outside inside that step (a deliberate test break, the client's abort) is compared up to
    its break: its outcomes before the break must open the resume's; the break line itself is not
    an outcome. A fresh step with no outcome and no break is not evidence."""
    cfg = cfg or inv()
    a = [x for x in step_block(fresh_lines, step_name) if x.startswith(("PASS", "FAIL"))]
    b = [x for x in step_block(resume_lines, step_name) if x.startswith(("PASS", "FAIL"))]
    why = []
    broken = [x for x in a if x.startswith(EXTERNAL_BREAK)]
    if broken:
        a = a[:a.index(broken[0])]
        b = b[:len(a)]
    elif not a:
        why.append("the fresh run has no outcome for step '%s'" % step_name)
    if [_strip_times(x) for x in a] != [_strip_times(x) for x in b]:
        why.append("step outcomes differ: fresh %s / resume %s" % (a, b))
    else:
        for x, y in zip(a, b):
            tx, ty = _line_time(x), _line_time(y)
            if tx is not None and ty is not None and abs(tx - ty) > cfg["trajectory"]["next_step_time_s"]:
                why.append("'%s' took %.1f s vs %.1f s" % (_strip_times(x), tx, ty))
    return why


# ---- identity -----------------------------------------------------------------------------------
def _canon(v):
    """Godot's JSON reads every number as a float (25 -> 25.0): compare numbers by value."""
    if isinstance(v, bool) or v is None or isinstance(v, str):
        return v
    if isinstance(v, (int, float)):
        return int(v) if float(v).is_integer() else float(v)
    if isinstance(v, list):
        return [_canon(x) for x in v]
    if isinstance(v, dict):
        return {k: _canon(x) for k, x in v.items()}
    return v


def steps_hash(steps):
    return hashlib.sha256(json.dumps(_canon(steps), sort_keys=True).encode()).hexdigest()[:16]


def identity_check(point_run, k, now_identity, now_walk, profile):
    """-> reasons the point can't be used now ([] = compatible for gate evaluation, not SAME)."""
    why = []
    rj = load(os.path.join(point_run, "run.json"))
    pid = rj.get("identity") or {}
    if pid.get("schema") != SCHEMA or now_identity.get("schema") != SCHEMA:
        why.append("schema: point %s, now %s, gate %s" % (pid.get("schema"), now_identity.get("schema"), SCHEMA))
    for key in ("game", "test", "bin", "testcode", "tools"):
        # testcode + tools (GPT results audit #4c): the code that sends a walk's actions (scripts/dev, tools/live.py)
        if pid.get(key) != now_identity.get(key):
            why.append("%s hash %s != now %s" % (key, pid.get(key), now_identity.get(key)))
    if pid.get("profile") != profile:
        why.append("profile %s != %s" % (pid.get("profile"), profile))
    try:
        old_walk = load(os.path.join(point_run, "walk.json"))
    except OSError:
        return why + ["the point's walk.json is missing"]
    os_, ns_ = old_walk.get("steps", []), now_walk.get("steps", [])
    if steps_hash(os_[:k]) != steps_hash(ns_[:k]) or steps_hash(old_walk.get("setup", [])) != steps_hash(now_walk.get("setup", [])):
        why.append("the steps before the point changed (its producer): play the real prefix")
    if k >= len(ns_) or k >= len(os_) or steps_hash(os_[k:k + 1]) != steps_hash(ns_[k:k + 1]):
        why.append("the resumed step changed: its fresh +3 s reference is for other actions")
    return why


def admit(points_dir, walk, walk_from, point_id, ident, probe=False):
    """The check before any launch / input (tools/live.py): -> (why, k, point_run_dir, probe_note).
    why == [] admits the point to gate EVALUATION only (layers 2 + 3 still decide; SAME needs RESUMES)."""
    names = [s.get("name", "") for s in walk.get("steps", [])]
    k = names.index(walk_from) if walk_from in names else -1
    prun = os.path.join(points_dir, point_id.rsplit("/", 1)[0]) if "/" in point_id else ""
    why, note = [], ""
    if k < 0:
        why.append("no step '%s' in this walk" % walk_from)
    elif not point_id or not os.path.exists(os.path.join(points_dir, point_id + ".json")):
        why.append("no point ID for '%s' (%r)" % (walk_from, point_id))
    elif not point_id.rsplit("/", 1)[1].isdigit() or int(point_id.rsplit("/", 1)[1]) != k:
        why.append("point %s is not step %d" % (point_id, k))
    else:
        idw = identity_check(prun, k, ident, walk, ident.get("profile"))
        # a REPAIR (GPT audit #6): only the resumed step's actions changed (so the walk file, hence the `test`
        # hash, differs); everything else must hold, and the point must already be qualified SAME
        if any(x.startswith("the resumed step changed") for x in idw) and \
                all(x.startswith(("the resumed step changed", "test hash")) for x in idw):
            rw = repair_check(points_dir, point_id, k, prun, walk, ident)
            if rw:
                idw.append("REPAIR refused: " + "; ".join(rw))
            else:
                idw, note = [], "REPAIR (action-only change of step %d; point qualified SAME)" % k
        why += idw
        op = os.path.join(prun, "%d.obs.json" % k)
        if not os.path.exists(op):
            why.append("the point's observation %s is missing" % op)
        else:
            pobs = load(op)
            ref = refusal(pobs, None, load(os.path.join(points_dir, point_id + ".json"))) + layer1(pobs)
            if ref and probe:
                note = "; ".join(ref)
            else:
                why += ref
    return why, k, prun, note


REPAIR_KEYS = ("do", "expect", "max", "allow")     # what a repair may change in the resumed step


def repair_check(points_dir, point_id, k, prun, walk, ident):
    """-> [] when a REPAIR resume of point_id is allowed: the step's name and every key but its actions are
    unchanged; game, bin, tools and test code (scripts/dev) equal the producer's and the receipts' runs; >= RESUMES
    SAME receipts from distinct runs and processes, each bound to this point's bytes, this gate and rv1/seed-v1."""
    why = []
    try:
        old = load(os.path.join(prun, "walk.json"))
        prod = load(os.path.join(prun, "run.json")).get("identity") or {}
    except OSError:
        return ["the producer's walk.json / run.json is missing"]
    os_, ns_ = old.get("steps", []), walk.get("steps", [])
    if k >= len(os_) or k >= len(ns_):
        return ["step %d missing" % k]
    a = {x: y for x, y in os_[k].items() if x not in REPAIR_KEYS}
    b = {x: y for x, y in ns_[k].items() if x not in REPAIR_KEYS}
    if steps_hash([a]) != steps_hash([b]):
        why.append("more than the step's actions changed (%s)" % sorted(set(os_[k]) ^ set(ns_[k]) | {x for x in a if a.get(x) != b.get(x)}))
    for key in ("game", "bin", "tools", "testcode"):
        if not prod.get(key) or prod.get(key) != ident.get(key):
            why.append("%s: producer %s, now %s" % (key, prod.get(key), ident.get(key)))
    sha = point_sha(os.path.join(points_dir, point_id + ".json"))
    gh = gate_hash()
    good, runs, pids = [], set(), set()
    for rd in sorted(os.listdir(points_dir)):
        gp = os.path.join(points_dir, rd, "%d.gate.json" % k)
        if not os.path.isfile(gp):
            continue
        try:
            r = load(gp)
        except ValueError:
            continue
        if r.get("point") != point_id or r.get("verdict") != "SAME":
            continue
        rid = r.get("resume_identity") or {}
        bad = [x for x, ok in (("point bytes", r.get("point_sha") == sha), ("gate", r.get("gate_hash") == gh),
                               ("protocol", r.get("protocol") == "%s/%s" % (RV, SEED_PROTO)),
                               ("profile", r.get("profile") == ident.get("profile")))
               + tuple((key, rid.get(key) == ident.get(key) and bool(rid.get(key))) for key in ("game", "bin", "tools", "testcode")) if not ok]
        if bad or r.get("resume_run") in runs or r.get("resume_pid") in pids or r.get("resume_pid") is None:
            continue
        good.append(rd)
        runs.add(r.get("resume_run"))
        pids.add(r.get("resume_pid"))
    if len(good) < RESUMES:
        why.append("%d valid SAME receipt(s) for %s (distinct runs and processes, bound to its bytes, this gate, %s/%s): %d needed"
                   % (len(good), point_id, RV, SEED_PROTO, RESUMES))
    return why


# ---- receipts -----------------------------------------------------------------------------------
def judge_resume(point_run, k, resume_run, cfg=None, repair=False):
    """repair=True: a REPAIR resume (changed actions): refusal + layers 1, 2 and the final pre-input check only;
    its verdict is REPAIR, never SAME (it can't qualify a point)."""
    cfg = cfg or inv()
    p_obs = load(os.path.join(point_run, "%d.obs.json" % k))
    ppath = os.path.join(point_run, "%d.json" % k)
    point = load(ppath)
    r_obs_p = os.path.join(resume_run, "%d.restored.obs.json" % k)
    rrun = load(os.path.join(resume_run, "run.json"))
    out = {"point": "%s/%d" % (os.path.basename(point_run), k), "resume_run": os.path.basename(resume_run),
           "profile": (rrun.get("identity") or {}).get("profile"), "resume_pid": rrun.get("pid"),
           "resume_identity": rrun.get("identity") or {}, "point_sha": point_sha(ppath), "gate_hash": gate_hash(),
           "protocol": "%s/%s" % (point.get("resume_v"), point.get("seed_proto"))}
    out["refusal"] = refusal(p_obs, cfg, point)
    prod = load(os.path.join(point_run, "run.json")).get("identity") or {}
    keys = ("schema", "game", "bin", "testcode", "tools", "profile") + (() if repair else ("test",))
    out["identity"] = ["%s: producer %s, resume %s" % (k_, prod.get(k_), out["resume_identity"].get(k_))
                       for k_ in keys if not prod.get(k_) or prod.get(k_) != out["resume_identity"].get(k_)]
    out["layer1"] = layer1(p_obs, cfg) + [x + " (restored)" for x in (layer1(load(r_obs_p), cfg) if os.path.exists(r_obs_p) else ["restored observation absent"])]
    out["layer2"] = [list(d) for d in layer2(p_obs, load(r_obs_p), cfg)] if os.path.exists(r_obs_p) else [["<restored observation absent>", "", ""]]
    if point.get("resume_v") is not None:
        f_obs_p = os.path.join(resume_run, "%d.final.obs.json" % k)
        out["layer2_final"] = [list(d) for d in layer2(p_obs, load(f_obs_p), cfg)] if os.path.exists(f_obs_p) else [["<final pre-input observation absent>", "", ""]]
        # the release observation (taken in the tick the step starts; GPT final audit: judge it offline too)
        r_rel = os.path.join(resume_run, "%d.release.obs.json" % k)
        out["layer2_release"] = [list(d) for d in layer2(p_obs, load(r_rel), cfg)] if os.path.exists(r_rel) else [["<release observation absent>", "", ""]]
    else:
        out["layer2_final"], out["layer2_release"] = [], []
    layers = ["refusal", "identity", "layer1", "layer2", "layer2_final", "layer2_release"]
    if repair:
        out["layer3"], out["next_step"], out["repair"] = [], [], True
    else:
        ft = os.path.join(point_run, "%d.t3.json" % k)
        rt = os.path.join(resume_run, "%d.t3.json" % k)
        out["layer3"] = layer3(load(ft) if os.path.exists(ft) else None, load(rt) if os.path.exists(rt) else None, cfg)
        fl = open(os.path.join(point_run, "walk.log"), encoding="utf-8").read().splitlines() if os.path.exists(os.path.join(point_run, "walk.log")) else []
        rl = open(os.path.join(resume_run, "walk.log"), encoding="utf-8").read().splitlines() if os.path.exists(os.path.join(resume_run, "walk.log")) else []
        out["next_step"] = next_step(fl, rl, point.get("live_step", ""), cfg)
        layers += ["layer3", "next_step"]
    bad = [x for x in layers if out[x]]
    ok = "REPAIR" if repair else "SAME"
    out["verdict"] = "REFUSED" if (out["refusal"] or out["identity"] or out["layer1"]) else (ok if not bad else "DIFFERENT")
    out["failed_layers"] = bad
    return out


def boundary(point_run, k, resume_runs, cfg=None):
    rec = [judge_resume(point_run, k, r, cfg) for r in resume_runs]
    profiles = set(r["profile"] for r in rec)
    same = [r for r in rec if r["verdict"] == "SAME"]
    distinct = len(set(r["resume_run"] for r in same)), len(set(r["resume_pid"] for r in same))
    if any(r["verdict"] != "SAME" for r in rec):
        v = "DIFFERENT" if any(r["verdict"] == "DIFFERENT" for r in rec) else "REFUSED"
    elif len(profiles) != 1:
        v = "NOT QUALIFIED (mixed profiles %s)" % sorted(map(str, profiles))
    elif min(distinct) < RESUMES:
        v = "NOT QUALIFIED (%d distinct SAME resume(s) / %d processes, %d needed: D3 A)" % (distinct[0], distinct[1], RESUMES)
    else:
        v = "SAME"
    return {"point": "%s/%d" % (os.path.basename(point_run), k), "resumes": rec, "verdict": v, "needs": RESUMES}


def main(a):
    if a[0] == "refuse":
        pp = os.path.join(a[1], "%s.json" % a[2])
        r = refusal(load(os.path.join(a[1], "%s.obs.json" % a[2])), None, load(pp) if os.path.exists(pp) else None)
        l1 = layer1(load(os.path.join(a[1], "%s.obs.json" % a[2])))
        print(json.dumps({"refusal": r, "layer1": l1}, indent=1))
        return 0 if not (r or l1) else 1
    if a[0] == "l2":
        d = layer2(load(os.path.join(a[1], "%s.obs.json" % a[2])), load(os.path.join(a[3], "%s.restored.obs.json" % a[2])))
        print(json.dumps(d, indent=1))
        return 0 if not d else 1
    if a[0] == "l3":
        d = layer3(load(os.path.join(a[1], "%s.t3.json" % a[2])), load(os.path.join(a[3], "%s.t3.json" % a[2])))
        print(json.dumps(d, indent=1))
        return 0 if not d else 1
    if a[0] == "boundary":
        b = boundary(a[1], int(a[2]), a[3:])
        print(json.dumps(b, indent=1))
        return 0 if b["verdict"] == "SAME" else 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["help"]))
