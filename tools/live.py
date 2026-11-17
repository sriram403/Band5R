"""The live control line's client (dev/LiveControl.gd).

Start the game waiting for commands (window behind yours, as the tests are):
    tools/run_test.sh live            (in the background; GYM=<name> for a gym)
Then, one step at a time:
    python tools/live.py '{"do": "state"}'
    python tools/live.py '[{"do": "menu", "tab": "Story", "row": "Nearly out of fuel"}, {"do": "shot", "name": "a"}]'
    python tools/live.py --quit
A planned walk (a watched run): python tools/live.py --walk tools/live/<w>.json
  resumes BY DEFAULT from the step its last run failed at (save points at
  every step); --fresh starts from step 1; --from "<step>" picks one.
It waits for the game's answer and prints it (results, messages, state,
the screenshot's path). Commands are listed at the top of LiveControl.gd.
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "method"))
# T4 v2 lanes: LANE=b -> appdata/playtest_b and appdata/live_run_b.log (lane a: the usual folders).
# LIVE_DIR overrides the folder (only the misroute control uses it: the lane check then refuses).
LANE = os.environ.get("LANE", "")
LIVE = os.environ.get("LIVE_DIR") or os.path.join(HERE, "..", "appdata", "playtest" + ("_" + LANE if LANE else ""), "FindingNaresh", "live")
# the game's output when started as: tools/run_test.sh live > appdata/live_run.log
LOG = os.path.join(HERE, "..", "appdata", "live_run%s.log" % ("_" + LANE if LANE else ""))
SEEN = os.path.join(LIVE, "log_seen")


def lane_ok():
    """T4 v2: the game in this folder must be this lane's (instance.json, written at ready)."""
    ip = os.path.join(LIVE, "instance.json")
    if not os.path.exists(ip):
        return True, "no game has answered here yet"
    try:
        with open(ip, encoding="utf-8") as f:
            inst = json.load(f)
    except (ValueError, OSError):
        return False, "instance.json unreadable"
    if inst.get("lane", "") != LANE:
        return False, "MISROUTED: lane '%s' asked, the game in %s is lane '%s' (pid %s)" % (LANE or "a", LIVE, inst.get("lane") or "a", inst.get("pid"))
    return True, "lane '%s' pid %s" % (LANE or "a", inst.get("pid"))


def new_errors() -> list:
    """Script errors printed since the last call (a frozen Naresh was a stack
    overflow only the log showed)."""
    if not os.path.exists(LOG):
        return []
    seen = 0
    if os.path.exists(SEEN):
        try:
            seen = int(open(SEEN).read() or 0)
        except ValueError:
            seen = 0
    with open(LOG, encoding="utf-8", errors="replace") as f:
        f.seek(seen if seen <= os.path.getsize(LOG) else 0)
        lines = f.read().splitlines()
        pos = f.tell()
    with open(SEEN, "w") as f:
        f.write(str(pos))
    # errors only, with the "at:" line that follows one (a WARNING's "at:"
    # line, "possibly benign", stopped a whole run once)
    out = []
    after_error = False
    for ln in lines:
        if "ERROR" in ln:
            after_error = True
            if not out or out[-1] != ln:
                out.append(ln)
        elif after_error and ln.strip().startswith("at: "):
            out.append(ln)
            after_error = False
        else:
            after_error = False
    return out[:12]


def resume_step(walk: dict):
    """The step the last run of this walk failed at, if it is still in the
    walk; else None (start from the beginning)."""
    name = walk.get("name", "walk")
    lf = os.path.join(LIVE, "points", "%s_last_fail.json" % name)
    if not os.path.exists(lf):
        return None
    try:
        with open(lf, encoding="utf-8") as f:
            last = json.load(f)
    except (ValueError, OSError):
        return None
    step = last.get("step", "")
    global RESUME_POINT
    RESUME_POINT = last.get("point", "")
    names = [s.get("name", "") for s in walk.get("steps", [])]
    if step not in names:
        print("RESUME: the last failed step '%s' is not in this walk any more: from the start" % step, flush=True)
        return None
    if names.index(step) == 0:
        return None
    print("RESUME from step '%s' (the last run failed there: %s). Start over: --fresh; "
          "cause earlier: --from '<earlier step>'" % (step, last.get("fail", "")[:160]), flush=True)
    return step


RESUME_POINT = ""


def gate_identity(walk):
    import tree_id
    import walkgate
    d = tree_id.identity()
    d["schema"] = walkgate.SCHEMA
    d["profile"] = os.environ.get("WALK_PROFILE", "play")
    d["walk"] = walkgate.steps_hash(walk.get("steps", []))
    return d


def main() -> int:
    args = sys.argv[1:]
    ok, why = lane_ok()
    if not ok and "--gate-check" not in args:
        print("REFUSED (lane): " + why, flush=True)
        return 6
    timeout = 180.0
    quit_after = False
    if "--quit" in args:
        quit_after = True
        args.remove("--quit")
    if "--timeout" in args:
        i = args.index("--timeout")
        timeout = float(args[i + 1])
        del args[i:i + 2]
    walk_from = None
    if "--from" in args:
        i = args.index("--from")
        walk_from = args[i + 1]
        del args[i:i + 2]
    gate_check_only = False
    if "--gate-check" in args:        # T4 v2: the gate's refusal before any launch (no game needed)
        gate_check_only = True
        args.remove("--gate-check")
    fresh = False
    if "--fresh" in args:
        fresh = True
        args.remove("--fresh")
    walk = None
    if "--walk" in args:
        i = args.index("--walk")
        with open(args[i + 1], encoding="utf-8") as f:
            walk = json.load(f)
        del args[i:i + 2]
        timeout = max(timeout, 3600.0)
        # By default a walk resumes from the step its last run failed at (the
        # user, 2026-11-10: a model restarted 10 trial plays from step 1 though
        # the save points were there). --fresh starts over; --from picks a step.
        if walk_from is None and not fresh:
            walk_from = resume_step(walk)
        point_id = os.environ.get("FROM_POINT", "") if walk_from else ""
        if walk_from and not point_id:
            point_id = RESUME_POINT
        import walkgate
        ident = gate_identity(walk)
        run_id = "%s_%s_%d" % (walk.get("name", "walk"), time.strftime("%Y%m%d_%H%M%S"), os.getpid())
        k, prun, repair = -1, "", False
        if walk_from:
            # T4 v2: refuse an unusable point BEFORE any input is sent
            why, k, prun, probe_note = walkgate.admit(os.path.join(LIVE, "points"), walk, walk_from, point_id, ident,
                                                      probe=os.environ.get("GATE_PROBE") == "1")
            repair = probe_note.startswith("REPAIR")
            if repair:
                print("GATE: %s: layers 1 + 2 and the final pre-input check still decide; no layer 3 (new actions)" % probe_note, flush=True)
            elif probe_note:
                print("GATE PROBE (test only): the point would be refused (%s); restoring anyway to show layer 2" % probe_note, flush=True)
            if why:
                print("REFUSED (gate, before any input): %s" % "; ".join(why), flush=True)
                print("  -> play the real prefix: --fresh (the ghat's only real producer is step 1, F1 Puzzles)", flush=True)
                return 5
        if gate_check_only:
            print("GATE CHECK: %s" % ("resume from %s (%s) admitted to gate evaluation" % (point_id, walk_from) if walk_from else "fresh walk"), flush=True)
            return 0
    src = args[0] if args else "[]"
    if src.startswith("@"):          # a saved walk: tools/live/<name>.json
        with open(src[1:], encoding="utf-8") as f:
            src = f.read()
    cmds = json.loads(src)
    if isinstance(cmds, dict):
        cmds = [cmds]
    res_path = os.path.join(LIVE, "res.json")
    last = -1
    if os.path.exists(res_path):
        try:
            with open(res_path, encoding="utf-8") as f:
                last = int(json.load(f).get("id", -1))
        except (ValueError, OSError):
            pass
    cid = max(last + 1, int(time.time() * 10) % 1000000000)
    tmp = os.path.join(LIVE, "cmd.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        msg = {"id": cid, "cmds": cmds, "quit": quit_after}
        if walk is not None:
            msg = {"id": cid, "walk": walk, "from": walk_from or "", "from_point": point_id, "run": run_id, "identity": ident}
            if os.environ.get("WALK_FAIL_AT"):           # test-only control: "<step index>:<game s>"
                st_, s_ = os.environ["WALK_FAIL_AT"].split(":")
                msg["fail_at"] = {"step": int(st_), "s": float(s_)}
            if os.environ.get("GATE_L2_CONTINUE") == "1":    # test-only control: past a layer 1+2 DIFFERENT
                msg["l2_continue"] = True
            if os.environ.get("GATE_DROP"):              # test-only control (resume fix v1): "hearing", "vars", "bodies"
                msg["drop"] = os.environ["GATE_DROP"].split(",")
            if os.environ.get("GATE_PERTURB"):           # test-only control: "van:0.2"
                w_, dx_ = os.environ["GATE_PERTURB"].split(":")
                msg["perturb"] = {"what": w_, "dx": float(dx_)}
        json.dump(msg, f)
    for _ in range(50):
        try:
            os.replace(tmp, os.path.join(LIVE, "cmd.json"))
            break
        except PermissionError:      # the game is reading the old one (Windows)
            time.sleep(0.05)
    t0 = time.time()
    walk_log = os.path.join(LIVE, "walk.log")
    shown = 0
    gate_state = {}
    if walk is not None:
        print("RUN %s (points: %s)" % (run_id, os.path.join(LIVE, "points", run_id)), flush=True)
        if walk_from:
            gate_state = {"k": k, "prun": prun, "rrun": os.path.join(LIVE, "points", run_id), "l2": False, "l3": False,
                          "l2f": False, "repair": repair}
    if walk is not None:
        new_errors()                     # only errors from now on
    while time.time() - t0 < timeout:
        time.sleep(0.1)
        if walk is not None:
            # the walk's lines as they come, and a script error stops it
            if os.path.exists(walk_log):
                with open(walk_log, encoding="utf-8", errors="replace") as f:
                    lines = f.read().splitlines()
                for ln in lines[shown:]:
                    print(ln, flush=True)
                shown = len(lines)
            errs = new_errors()
            if errs:
                with open(os.path.join(LIVE, "abort"), "w", encoding="utf-8") as f:
                    f.write(errs[0])
            if gate_state:
                gate_step(gate_state)
        try:
            with open(res_path, encoding="utf-8") as f:
                res = json.load(f)
        except (ValueError, OSError):
            continue
        if int(res.get("id", -2)) == cid:
            if walk is not None:
                if gate_state:
                    gate_final(gate_state)
                print("RESULT:", "ok" if res.get("ok") else "FAILED at %s: %s" % (res.get("failed_step"), res.get("fail")))
                print("run %s; inputs sent %s, dropped by the gate %s, held at the failure picture %s" % (
                    res.get("run"), res.get("input_sends"), res.get("blocked_sends"), res.get("held_at_shot")))
                if res.get("shot"):
                    print("shot:", res["shot"])
                for k in ("naresh", "p1", "p2", "creatures", "story"):
                    if k in res.get("state", {}):
                        print("%s: %s" % (k, json.dumps(res["state"][k], separators=(",", ":"))))
                return 0 if res.get("ok") else 1
            for r in res.get("results", []):
                print("result:", json.dumps(r, separators=(",", ":")))
            for m in res.get("messages", []):
                print("msg:", m)
            for k, v in res.get("state", {}).items():
                print("%s: %s" % (k, json.dumps(v, separators=(",", ":"))))
            if res.get("shot"):
                print("shot:", res["shot"])
            for e in new_errors():
                print("ERROR in log:", e)
            return 0 if all(r.get("ok", True) for r in res.get("results", [])) else 1
    print("no answer in %.0f s (is the game running? tools/run_test.sh live)" % timeout)
    return 2


def gate_step(g):
    """During a resume: layer 1 + 2 as soon as the restored observation exists (the game waits for it
    before the step's first input); layer 3 as soon as the resume's +3 s sample exists (DIFFERENT
    stops the walk: a step resumed from a point that fails the gate doesn't count)."""
    import walkgate
    k = g["k"]
    ro = os.path.join(g["rrun"], "%d.restored.obs.json" % k)
    if not g["l2"] and os.path.exists(ro):
        try:
            robs = walkgate.load(ro)
        except ValueError:
            return
        pobs = walkgate.load(os.path.join(g["prun"], "%d.obs.json" % k))
        l1 = walkgate.layer1(robs)
        d = walkgate.layer2(pobs, robs)
        v = "SAME" if not (l1 or d) else ("REFUSED" if l1 else "DIFFERENT")
        why = "; ".join(l1 + ["%s: %s -> %s" % (x[0], str(x[1])[:60], str(x[2])[:60]) for x in d[:12]]) + (" (+%d more)" % (len(d) - 12) if len(d) > 12 else "")
        tmp = os.path.join(g["rrun"], "%d.l2.json.tmp" % k)
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"verdict": v, "why": why, "diffs": d, "layer1": l1}, f)
        os.replace(tmp, os.path.join(g["rrun"], "%d.l2.json" % k))
        print("GATE layer 1+2: %s %s" % (v, why[:400]), flush=True)
        g["l2"] = True
    fo = os.path.join(g["rrun"], "%d.final.obs.json" % k)
    if g["l2"] and not g.get("l2f") and os.path.exists(fo):
        # resume fix v1: the final pre-input check (the world as it will start the step, still paused)
        try:
            fobs = walkgate.load(fo)
        except ValueError:
            return
        pobs = walkgate.load(os.path.join(g["prun"], "%d.obs.json" % k))
        d = walkgate.layer2(pobs, fobs)
        v = "SAME" if not d else "DIFFERENT"
        why = "; ".join("%s: %s -> %s" % (x[0], str(x[1])[:60], str(x[2])[:60]) for x in d[:12])
        tmp = os.path.join(g["rrun"], "%d.l2f.json.tmp" % k)
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"verdict": v, "why": why, "diffs": d}, f)
        os.replace(tmp, os.path.join(g["rrun"], "%d.l2f.json" % k))
        print("GATE final pre-input check: %s %s" % (v, why[:400]), flush=True)
        g["l2f"] = True
    rt = os.path.join(g["rrun"], "%d.t3.json" % k)
    if g.get("repair"):
        return
    if g["l2"] and not g["l3"] and os.path.exists(rt):
        try:
            rt3 = walkgate.load(rt)
        except ValueError:
            return
        ft = os.path.join(g["prun"], "%d.t3.json" % k)
        d3 = walkgate.layer3(walkgate.load(ft) if os.path.exists(ft) else None, rt3)
        print("GATE layer 3 (+3 game s): %s %s" % ("SAME" if not d3 else "DIFFERENT", "; ".join(d3)[:600]), flush=True)
        if d3 and os.environ.get("GATE_NOABORT") != "1":
            with open(os.path.join(LIVE, "abort"), "w", encoding="utf-8") as f:
                f.write("gate layer 3 DIFFERENT: " + "; ".join(d3)[:300])
        g["l3"] = True


def gate_final(g):
    import walkgate
    rt = os.path.join(g["rrun"], "%d.t3.json" % g["k"])
    for _ in range(0 if g.get("repair") else 100):    # the +3 s sample may land just after the walk's end
        if os.path.exists(rt):
            break
        time.sleep(0.1)
    gate_step(g)
    rec = walkgate.judge_resume(g["prun"], g["k"], g["rrun"], repair=bool(g.get("repair")))
    with open(os.path.join(g["rrun"], "%d.gate.json" % g["k"]), "w", encoding="utf-8") as f:
        json.dump(rec, f, indent=1)
    print("GATE receipt %s: %s (failed layers %s)" % (os.path.join(g["rrun"], "%d.gate.json" % g["k"]), rec["verdict"], rec["failed_layers"]), flush=True)


if __name__ == "__main__":
    sys.exit(main())
