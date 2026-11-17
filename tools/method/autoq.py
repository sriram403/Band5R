"""Auto-qualify a resume point after a failed walk (2026-11-17, notes/speed_research/autoq_spec.md v2, audited by
GPT-6.1 Sol: BUILD WITH CHANGES, all taken). Nobody sets or qualifies a resume point by hand.

    python tools/method/autoq.py <walk> --run <run id>     (tools/play_walk.sh calls it after a FAILED walk)
    python tools/method/autoq.py <walk> --again            (retry the last failed run's qualification by hand)

1. The run named in <walk>_last_fail.json (and --run) must have an end record FAILED by a game outcome (not a
   gate / client / test break).
2. A RESUMED run's failure: no games; its own source point is the next start if it is still qualified.
3. A FRESH run's failure: walk back from the failed step to the nearest point that passes refusal + layer 1 and
   has a usable +3 s reference (walkgate.pick_point); resume it up to twice, each in a NEW game (child mode:
   AUTOQ_CHILD=1, the walk file as the producer had it, NO_MAKE=1), each played to the end and judged by the gate
   (layers 1-3, next_step and the outcome layer: it must end as the producer did). Stops at the first non-SAME.
4. 2 valid SAME receipts and no valid DIFFERENT -> QUALIFIED: last_fail now names that point (the default rerun
   resumes it, or REPAIRs it after a fix). Otherwise last_fail says fresh_next with the reason.
One record per producer + identity (<walk>_autoq.json): run once; again only with --again.
Test-only: AUTOQ_PLANT=hearing|vars|bodies|groups drops that restore in resume 1 (a planted control: its receipt
never counts; the attempt must come out NOT QUALIFIED).
"""
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools"))
import walkgate as wg  # noqa: E402

LANE = os.environ.get("LANE", "")
LIVE = os.environ.get("AUTOQ_LIVE") or os.path.join(ROOT, "appdata", "playtest" + ("_" + LANE if LANE else ""), "FindingNaresh", "live")   # AUTOQ_LIVE: offline controls only
PTS = os.path.join(LIVE, "points")


def jwrite(path, d):
    tmp = path + ".tmp%d" % os.getpid()
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=1)
    os.replace(tmp, path)


def say(msg):
    print("[autoq] " + msg, flush=True)


def identity(walk):
    if os.environ.get("AUTOQ_TEST_IDENT"):       # offline controls only (autoq_controls.py): a synthetic identity
        return json.loads(os.environ["AUTOQ_TEST_IDENT"])
    import live      # tools/live.py: the same identity the walk calls stamp
    return live.gate_identity(walk)


def finish(walk_name, run, last, verdict, **kw):
    """Rewrite last_fail only if it still names this run (never over a newer run's record)."""
    lf = os.path.join(PTS, "%s_last_fail.json" % walk_name)
    try:
        cur = wg.load(lf)
    except (OSError, ValueError):
        cur = {}
    if cur.get("run") != run and cur.get("producer_run") != run:
        say("last_fail now names another run (%s): left as it is" % cur.get("run"))
        return
    rec = {"run": run, "producer_run": run, "fail": last.get("fail", ""), "failed_step": last.get("step", ""),
           "failed_index": last.get("index"), "at": time.strftime("%Y-%m-%d %H:%M:%S"), "autoq": verdict}
    rec.update(kw)
    jwrite(lf, rec)


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 2
    wname = argv[0]
    again = "--again" in argv
    want_run = argv[argv.index("--run") + 1] if "--run" in argv else None
    lf = os.path.join(PTS, "%s_last_fail.json" % wname)
    if not os.path.exists(lf):
        say("no last_fail for %s: nothing to qualify" % wname)
        return 0
    last = wg.load(lf)
    run = last.get("producer_run") or last.get("run", "")
    if want_run and run != want_run:
        say("last_fail names run %s, not the run just played (%s): nothing done" % (run, want_run))
        return 0
    if last.get("autoq") and not again:
        say("already done for %s: %s (retry: --again)" % (run, last.get("autoq")))
        return 0
    rdir = os.path.join(PTS, run)
    endp = os.path.join(rdir, "end.json")
    if not os.path.exists(endp):
        finish(wname, run, last, "NOT QUALIFIED", fresh_next="the failed run %s left no end record" % run)
        say("NOT QUALIFIED: no end record in %s: next run fresh" % run)
        return 0
    end = wg.load(endp)
    if end.get("status") != "FAILED":
        say("run %s ended %s: nothing to qualify" % (run, end.get("status")))
        return 0
    if end.get("kind") not in wg.QUALIFIABLE_KINDS:
        finish(wname, run, last, "NOT QUALIFIED", fresh_next="the run failed by %r (%s), not a game outcome" % (end.get("kind"), end.get("check")))
        say("NOT QUALIFIED: failed by %r, not a game outcome: next run fresh" % end.get("kind"))
        return 0
    rr = wg.load(os.path.join(rdir, "run.json"))
    walk_now_p = os.environ.get("AUTOQ_TEST_WALK") or os.path.join(ROOT, "tools", "live", "%s.json" % wname)
    walk_now = wg.load(walk_now_p)
    ident = identity(walk_now)
    if rr.get("from", "") != "":
        # a resumed run: its source point, if still qualified, is the next start (no games)
        src, why = wg.fresh_root(PTS, rr.get("from_point", "") or last.get("point", ""))
        q = ["no fresh source: " + why] if src is None else wg.qualified(PTS, src, int(src.rsplit("/", 1)[1]), ident)
        if q:
            finish(wname, run, last, "NOT QUALIFIED", fresh_next="resumed run %s: its source can't be reused (%s)" % (run, "; ".join(q)))
            say("NOT QUALIFIED (resumed run): %s: next run fresh" % "; ".join(q))
        else:
            k = int(src.rsplit("/", 1)[1])
            finish(wname, run, last, "SOURCE", point=src, step=wg.load(os.path.join(PTS, src + ".json")).get("live_step", ""), index=k)
            say("resumed run %s failed at step %s: next start = its qualified source %s (no games needed)" % (run, end.get("failed_index"), src))
        return 0
    # a fresh producer
    recp = os.path.join(PTS, "%s_autoq.json" % wname)
    book = wg.load(recp) if os.path.exists(recp) else {}
    key = "%s|%s" % (run, wg.walk_hash(ident))
    if key in book and not again:
        say("already tried for %s (%s): retry with --again" % (run, book[key].get("verdict")))
        return 0
    k, skips = wg.pick_point(rdir, int(end.get("failed_index", -1)))
    for s in skips:
        say("skip point " + s)
    entry = {"run": run, "failed_index": end.get("failed_index"), "kind": end.get("kind"), "check": end.get("check"),
             "skips": skips, "resumes": [], "at": time.strftime("%Y-%m-%d %H:%M:%S"), "plant": os.environ.get("AUTOQ_PLANT", "")}
    if k is None:
        entry["verdict"] = "NOT QUALIFIED: no resumable point before step %s" % end.get("failed_index")
        book[key] = entry
        jwrite(recp, book)
        finish(wname, run, last, "NOT QUALIFIED", fresh_next=entry["verdict"])
        say(entry["verdict"] + ": next run fresh")
        return 0
    pid = "%s/%d" % (run, k)
    step_k = wg.load(os.path.join(rdir, "walk.json"))["steps"][k]["name"]
    entry["point"] = pid
    say("producer %s FAILED at step %s (%s %s); qualifying point %s (step '%s') in up to %d new games"
        % (run, end.get("failed_index"), end.get("kind"), end.get("check"), pid, step_k, wg.RESUMES))
    prod_id = rr.get("identity") or {}
    stop_why = ""
    for i in range(1, wg.RESUMES + 1):
        # the tree must still be the producer's (a walk edited while qualifying would be refused anyway: say why now)
        cur_walk = wg.load(walk_now_p)
        ident = identity(cur_walk)
        changed = [x for x in ("game", "test", "testcode", "tools", "bin") if prod_id.get(x) != ident.get(x)]
        if wg.walk_hash(cur_walk) != wg.walk_hash(wg.load(os.path.join(rdir, "walk.json"))):
            changed.append("the walk file")
        if changed:
            stop_why = "files changed while qualifying (%s)" % changed
            break
        env = dict(os.environ, AUTOQ_CHILD="1", AUTOQ_MODE="qualify", NO_MAKE="1", FROM_POINT=pid, LANE=LANE)
        for x in ("GATE_DROP", "GATE_PERTURB", "GATE_L2_CONTINUE", "WALK_FAIL_AT", "STOP_AFTER", "WIDE_OBS", "GATE_PROBE"):
            env.pop(x, None)
        if i == 1 and os.environ.get("AUTOQ_PLANT"):
            env["GATE_DROP"] = os.environ["AUTOQ_PLANT"]
            say("TEST-ONLY plant: resume 1 restores without '%s' (its receipt never counts)" % env["GATE_DROP"])
        say("resume %d of %d: a new game from %s" % (i, wg.RESUMES, pid))
        t0 = time.time()
        p = subprocess.Popen(["bash", os.path.join(ROOT, "tools", "play_walk.sh"), wname, "--from", step_k], cwd=ROOT, env=env,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
        rid = ""
        for ln in p.stdout:
            ln = ln.rstrip("\n")
            print("[autoq r%d] %s" % (i, ln), flush=True)
            if ln.startswith("RUN ") and not rid:
                rid = ln.split()[1]
        rc = p.wait()
        gp = os.path.join(PTS, rid, "%d.gate.json" % k) if rid else ""
        r = wg.load(gp) if gp and os.path.exists(gp) else {}
        v = r.get("verdict", "NO RECEIPT")
        bad = [x for x in r.get("failed_layers", [])]
        entry["resumes"].append({"run": rid, "rc": rc, "verdict": v, "failed_layers": bad, "s": round(time.time() - t0, 1),
                                 "control": bool(i == 1 and os.environ.get("AUTOQ_PLANT"))})
        say("resume %d: receipt %s%s (%.0f s)" % (i, v, (" failed layers %s" % bad) if bad else "", time.time() - t0))
        if v != "SAME":
            why = (r.get("outcome") or r.get("layer3") or r.get("layer2") or r.get("refusal") or [])[:3]
            stop_why = "resume %d (%s) was %s: %s" % (i, rid or "no run", v, why)
            break
    q = ["stopped: " + stop_why] if stop_why else wg.qualified(PTS, pid, k, ident)
    entry["verdict"] = "QUALIFIED" if not q else "NOT QUALIFIED: " + "; ".join(q)
    book[key] = entry
    jwrite(recp, book)
    if not q:
        finish(wname, run, last, "QUALIFIED", point=pid, step=step_k, index=k)
        say("QUALIFIED %s (step '%s'): the default rerun resumes it (a REPAIR after a fix to the walk)" % (pid, step_k))
    else:
        finish(wname, run, last, "NOT QUALIFIED", fresh_next="point %s %s" % (pid, entry["verdict"]), point=pid)
        say("%s: next run fresh" % entry["verdict"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
