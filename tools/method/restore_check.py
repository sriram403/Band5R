"""New-puzzle restore check, a one-off DIAGNOSTIC (2026-11-17, autoq spec v2 piece 5, GPT audit #7). Never a
receipt: it lists what a resume's restore misses, so the puzzle's node / creature can be added before points are
qualified. It decides nothing by itself.

    python tools/method/restore_check.py <walk> [--producer <run>] [--points 3,9,13] [--baseline <report.json>]

1. A fresh producer of the CURRENT identity with wide observations (WIDE_OBS=1, <i>.wide.json at each point);
   none -> it plays one (child mode: no last_fail, no autoq).
2. Up to 3 resumable points spread over the walk (or --points); each resumed once in a new game, stopped after its
   step (STOP_AFTER), past any gate DIFFERENT (GATE_L2_CONTINUE: a control run, its receipt never counts).
3. Report <producer>/restore_check_<time>.md + .json: per point, the GateObs layer 1 + 2 differences and the WIDE
   differences (every scripted node's vars / pose / groups, unscripted descendants' engine state), grouped by node,
   none hidden. With --baseline, a difference also in that earlier report is MARKED (not removed).
   Fixes are HYPOTHESES: a node in a group missing from LiveControl.LIVE_GROUPS -> "add the group?"; a node below a
   creature -> "add it to gate_inventory problem_children?" (the frozen list).
Test-only: RC_PLANT=groups (the restore skips LIVE_GROUPS: a puzzle the restore doesn't know).
Blind spots (in every report): autoloads, script statics, a resource's insides, physics contacts, anything outside
the boot scene.
"""
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools"))
import walkgate as wg  # noqa: E402

LANE = os.environ.get("LANE", "")
LIVE = os.path.join(ROOT, "appdata", "playtest" + ("_" + LANE if LANE else ""), "FindingNaresh", "live")
PTS = os.path.join(LIVE, "points")
BLIND = ["autoloads (outside the boot scene)", "script statics (GateObs reads only Hearing / Creature)",
         "a resource's insides (meshes, materials' parameters)", "the physics server's contacts", "the audio server's playback position"]


def say(m):
    print("[restore_check] " + m, flush=True)


def live_groups():
    src = open(os.path.join(ROOT, "FindingNaresh", "scripts", "dev", "LiveControl.gd"), encoding="utf-8").read()
    m = re.search(r"const LIVE_GROUPS := \[([^\]]*)\]", src)
    return re.findall(r'"([^"]+)"', m.group(1)) if m else []


def play(wname, args, extra):
    env = dict(os.environ, AUTOQ_CHILD="1", AUTOQ_MODE="probe", NO_MAKE="1", WIDE_OBS="1", LANE=LANE)
    for x in ("GATE_DROP", "GATE_PERTURB", "GATE_L2_CONTINUE", "WALK_FAIL_AT", "STOP_AFTER", "FROM_POINT", "AUTOQ_PLANT"):
        env.pop(x, None)
    env.update(extra)
    p = subprocess.Popen(["bash", os.path.join(ROOT, "tools", "play_walk.sh"), wname] + args, cwd=ROOT, env=env,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
    rid = ""
    for ln in p.stdout:
        ln = ln.rstrip("\n")
        print("[rc game] " + ln, flush=True)
        if ln.startswith("RUN ") and not rid:
            rid = ln.split()[1]
    p.wait()
    return rid


def node_of(key):
    """'w:Boot/World/Ghat.phase' -> ('Boot/World/Ghat', 'phase')."""
    k = key[2:]
    i = k.rfind(".")
    return (k[:i], k[i + 1:]) if i > 0 else (k, "")


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 2
    wname = argv[0]
    walk = wg.load(os.path.join(ROOT, "tools", "live", "%s.json" % wname))
    import live
    ident = live.gate_identity(walk)
    prod = argv[argv.index("--producer") + 1] if "--producer" in argv else None
    if prod is None:
        cands = []
        for rd in sorted(os.listdir(PTS)):
            rj = os.path.join(PTS, rd, "run.json")
            if not (rd.startswith(wname + "_") and os.path.exists(rj)):
                continue
            r = wg.load(rj)
            pid = r.get("identity") or {}
            if r.get("from", "") == "" and r.get("wide") and all(pid.get(x) == ident.get(x) for x in ("game", "test", "testcode", "tools", "bin")):
                cands.append(rd)
        prod = cands[-1] if cands else None
    if prod is None:
        say("no fresh producer with wide observations for this identity: playing one (fresh, child mode)")
        prod = play(wname, ["--fresh"], {})
    pdir = os.path.join(PTS, prod)
    say("producer %s" % prod)
    if "--points" in argv:
        ks = [int(x) for x in argv[argv.index("--points") + 1].split(",")]
    else:
        ok = []
        for k in range(1, len(walk["steps"])):
            if os.path.exists(os.path.join(pdir, "%d.wide.json" % k)) and wg.pick_point(pdir, k)[0] == k:
                ok.append(k)
        ks = ok if len(ok) <= 3 else [ok[0], ok[len(ok) // 2], ok[-1]]
    say("points: %s" % ks)
    base = wg.load(argv[argv.index("--baseline") + 1]) if "--baseline" in argv else {}
    lg = live_groups()
    rep = {"producer": prod, "walk": wname, "plant": os.environ.get("RC_PLANT", ""), "points": {}, "blind_spots": BLIND,
           "live_groups": lg, "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    for k in ks:
        step = walk["steps"][k]["name"]
        extra = {"FROM_POINT": "%s/%d" % (prod, k), "STOP_AFTER": step, "GATE_L2_CONTINUE": "1"}
        if os.environ.get("RC_PLANT"):
            extra["GATE_DROP"] = os.environ["RC_PLANT"]
        rid = play(wname, ["--from", step], extra)
        rdir = os.path.join(PTS, rid) if rid else ""
        a_p, b_p = os.path.join(pdir, "%d.wide.json" % k), os.path.join(rdir, "%d.restored.wide.json" % k)
        if not (rid and os.path.exists(a_p) and os.path.exists(b_p)):
            rep["points"][str(k)] = {"error": "missing wide observation (%s / %s)" % (os.path.exists(a_p), bool(rid) and os.path.exists(b_p)), "run": rid}
            say("point %d: MISSING wide observations: no verdict (fails closed)" % k)
            continue
        a, b = wg.load(a_p), wg.load(b_p)
        fa, fb = a["fields"], b["fields"]
        diffs = sorted(x for x in set(fa) | set(fb) if fa.get(x) != fb.get(x))
        l2 = wg.load(os.path.join(rdir, "%d.l2.json" % k)) if os.path.exists(os.path.join(rdir, "%d.l2.json" % k)) else {}
        nodes = {}
        for d in diffs:
            n, f = node_of(d)
            nodes.setdefault(n, []).append(f)
        hyp = []
        for n, fs in sorted(nodes.items()):
            gs = (fa.get("w:%s.@groups" % n) or fb.get("w:%s.@groups" % n) or "").split(",")
            missing = [g for g in gs if g and g not in lg and g not in ("creature", "carryable", "player")]
            under_creature = any(fa.get("w:%s.@groups" % anc, "").split(",").count("creature")
                                 for anc in ["/".join(n.split("/")[:j]) for j in range(1, n.count("/") + 1)])
            if under_creature:
                hyp.append("%s: below a creature -> add it to gate_inventory problem_children? (%d fields)" % (n, len(fs)))
            elif missing and len(fs) > 0:
                hyp.append("%s (groups %s): not restored -> add group %s to LiveControl.LIVE_GROUPS? (%d fields)" % (n, ",".join(gs), missing, len(fs)))
        bk = set((base.get("points", {}).get(str(k)) or {}).get("wide_diffs", []))
        rep["points"][str(k)] = {"run": rid, "step": step, "wide_diffs": diffs, "in_baseline": sorted(set(diffs) & bk),
                                 "new_vs_baseline": sorted(set(diffs) - bk) if base else None,
                                 "nodes": {n: fs for n, fs in nodes.items()}, "hypotheses": hyp,
                                 "gateobs_l2": l2.get("verdict"), "gateobs_layer1": l2.get("layer1", []),
                                 "gateobs_diffs": [x[0] for x in l2.get("diffs", [])],
                                 "capture_us": [a["meta"].get("capture_us"), b["meta"].get("capture_us")],
                                 "fields": [len(fa), len(fb)], "bytes": [os.path.getsize(a_p), os.path.getsize(b_p)]}
        say("point %d: %d wide differences on %d nodes; GateObs layer 2 %s (%d); %d hypotheses; capture %s us, %d fields"
            % (k, len(diffs), len(nodes), l2.get("verdict"), len(l2.get("diffs", [])), len(hyp), a["meta"].get("capture_us"), len(fa)))
    stamp = time.strftime("%Y%m%d_%H%M%S")
    jp = os.path.join(pdir, "restore_check_%s.json" % stamp)
    with open(jp, "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1)
    md = ["# Restore check: %s, producer %s (%s)%s" % (wname, prod, rep["at"], " PLANT " + rep["plant"] if rep["plant"] else ""),
          "", "A diagnostic: it lists, it doesn't decide. Fixes are hypotheses. Blind spots: " + "; ".join(BLIND), ""]
    for k, e in rep["points"].items():
        md.append("## Point %s (%s)" % (k, e.get("step", "")))
        if "error" in e:
            md.append("- " + e["error"])
            continue
        md.append("- resume run %s; wide: %d differences on %d nodes; capture %s us, %s fields, %s bytes; GateObs layer 2: %s"
                  % (e["run"], len(e["wide_diffs"]), len(e["nodes"]), e["capture_us"], e["fields"], e["bytes"], e["gateobs_l2"]))
        for h in e["hypotheses"]:
            md.append("- HYPOTHESIS: " + h)
        for n, fs in sorted(e["nodes"].items()):
            mark = [f for f in fs if "w:%s.%s" % (n, f) in set(e["in_baseline"])]
            md.append("  - `%s`: %s%s" % (n, ", ".join(fs[:12]) + (" (+%d)" % (len(fs) - 12) if len(fs) > 12 else ""),
                                          (" [in baseline: %d]" % len(mark)) if mark else ""))
    with open(jp[:-5] + ".md", "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    say("report %s (+ .md)" % jp)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
