"""The final method's one supervisor (test-method research, Stage 4).

Launches tools/run_test.sh <plan> itself, owns the game's PID, and judges only
from what it reads OUTSIDE the game (never a fixture switch):
  rig.txt            c1's heartbeat and events (dev/RigBeat.gd)
  method_events.txt  OPEN / CLOSE, CHECK, WORK, ATTEMPT, PREFLIGHT, STALE,
                     ABSENT, FIRE, WINDOW, G3B, RULES (dev/MethodRec.gd, C2Watch)
  seg_1.log          SCRIPT ERROR blocks (with their raising frame), the launch
Limits from tools/method/frozen.json (M3). Host monotonic timers for every
deadline; wall time (same PC clock as the game) only to order conditions.
Stops the game at once on NOT HEALTHY, STALLED and TEST conditions (a script
error first gets the 2 s tie window, M15), verifies the process is gone (5 s,
one retry, then KILL FAILED), bounds the wrapper's shutdown, then hands the
trace to method_verdict.py. Usage:
  method_watch.py <root> <plan> <out dir> [extra game args]
"""
import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import method_verdict  # noqa: E402


def say(s):
    print("[method %s] %s" % (time.strftime("%H:%M:%S"), s), flush=True)


def alive(pid):
    if not pid:
        return False
    out = subprocess.run(["tasklist", "/FI", "PID eq %d" % int(pid), "/NH"], capture_output=True, text=True).stdout
    return str(pid) in out


def godot_pids():
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq godot*", "/NH", "/FO", "CSV"], capture_output=True, text=True).stdout
    pids = []
    for ln in out.splitlines():
        f = [x.strip('"') for x in ln.split('","')]
        if len(f) > 1 and f[1].isdigit():
            pids.append(int(f[1]))
    return pids


def kill(pid, log, lim):
    """taskkill the tree; verify gone within lim s; retry once; else KILL FAILED."""
    t0 = time.monotonic()
    for attempt in (1, 2):
        r = subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True, text=True)
        log.append("taskkill #%d rc %d: %s" % (attempt, r.returncode, (r.stdout + r.stderr).strip()[:160]))
        t1 = time.monotonic()
        while time.monotonic() - t1 < lim:
            if not alive(pid):
                log.append("process %d gone %.1f s after the first kill" % (pid, time.monotonic() - t0))
                return True
            time.sleep(0.25)
    log.append("KILL FAILED: process %d still alive %.1f s after the kill" % (pid, time.monotonic() - t0))
    return False


class Tail:
    """Reads only complete new lines of a growing file."""

    def __init__(self, path):
        self.path, self.off = path, 0

    def lines(self):
        if not os.path.exists(self.path):
            return []
        with open(self.path, "rb") as f:
            f.seek(self.off)
            chunk = f.read()
        nl = chunk.rfind(b"\n")
        if nl < 0:
            return []
        self.off += nl + 1
        return chunk[:nl + 1].decode("utf-8", "replace").splitlines()


def main():
    root, plan, out = sys.argv[1], sys.argv[2], sys.argv[3]
    extra = sys.argv[4] if len(sys.argv) > 4 else ""
    fz = json.load(open(os.path.join(root, "tools", "method", "frozen.json"), encoding="utf-8"))
    L = fz["limits"]
    runs = os.path.join(root, "appdata", "playtest", "runs")
    os.makedirs(runs, exist_ok=True)
    for f in ("rig.txt", "method_events.txt", "c2.txt", "c2_verdict.txt", "finished.txt", "summary.txt"):
        p = os.path.join(runs, f)
        if os.path.exists(p):
            os.remove(p)
    for f in os.listdir(runs):
        if f.startswith("seg_") and f.endswith(".log"):
            os.remove(os.path.join(runs, f))
    env = dict(os.environ)
    env["ARGS"] = extra
    wrapper_out = open(os.path.join(out, "run_test.out"), "w", encoding="utf-8")
    t_start_mono, t_start = time.monotonic(), time.time()
    wrapper = subprocess.Popen(["sh", os.path.join(root, "tools", "run_test.sh"), plan], cwd=root, env=env,
                               stdout=wrapper_out, stderr=subprocess.STDOUT)
    say("launched run_test.sh %s (wrapper pid %d), args '%s'" % (plan, wrapper.pid, extra))
    rig, evs, seg = Tail(os.path.join(runs, "rig.txt")), Tail(os.path.join(runs, "method_events.txt")), Tail(os.path.join(runs, "seg_1.log"))
    tr = {"plan": plan, "args": extra, "t_start": t_start, "asked": [s for s in plan.split(",") if s],
          "started": [], "ended": [], "conditions": [], "checks": [], "work": [], "attempts": [], "windows": [],
          "g3b": [], "rules": {}, "preflight": [], "lips": [], "script_errors": [], "kill": [], "beats": 0,
          "launch": None, "first_beat": None, "opens_max": {}, "step_secs": {}, "pid": None}
    opens = {}                  # id -> (step, deadline_mono, open_wall, secs)
    last_beat = pf = wf = None
    pf_at = wf_at = None
    beat = {}
    missing_since, missing_n = None, 0
    p2dev_prev, p2dev_drop = None, None
    stop, stop_at_mono, grace_until = None, None, None
    se_pending = None
    last_say = 0.0
    last_step = ""
    seg_size, seg_grow = 0, time.monotonic()

    def cond(status, text, begin, kind, owner="UNRESOLVED", stop_now=False, grace=0.0):
        nonlocal stop, stop_at_mono, grace_until
        c = {"status": status, "text": text, "begin": begin, "detected": time.time(), "kind": kind, "owner": owner,
             "detected_after_start_s": round(time.monotonic() - t_start_mono, 2)}
        tr["conditions"].append(c)
        say("CONDITION %s: %s" % (status, text))
        if stop_now and stop is None:
            stop = c
            stop_at_mono = time.monotonic()
            grace_until = stop_at_mono + grace
        return c

    while True:
        now_m, now_w = time.monotonic(), time.time()
        # ---- the segment log: launch, script errors, lip lines
        for ln in seg.lines():
            if ln.startswith("==== launch") and tr["launch"] is None:
                tr["launch"] = now_w
                launch_m = now_m
                say("game launched")
            if se_pending is not None:
                m = re.search(r"at: (\S+) \((res://[^)]+)\)", ln)
                if m:
                    se_pending["at"] = m.group(2)
                    se_pending["func"] = m.group(1)
                if "GDScript backtrace" in ln or m:
                    se_pending["backtrace"] = se_pending.get("backtrace", False) or "GDScript backtrace" in ln
                if m or ln.strip() == "" or "SCRIPT ERROR" in ln:
                    if m:
                        tr["script_errors"].append(se_pending)
                        se_pending = None
            if "SCRIPT ERROR" in ln:
                se_pending = {"text": ln.strip()[:200], "unix": now_w}
            mm = re.search(r"\[ramp\] off the lip at ([0-9.]+) km/h, ([-0-9.]+) m off the middle", ln)
            if mm:
                tr["lips"].append({"kmh": float(mm.group(1)), "off": float(mm.group(2)), "unix": now_w})
        if se_pending is not None and now_w - se_pending["unix"] > 2.0:
            tr["script_errors"].append(se_pending)      # no raising frame seen
            se_pending = None
        while tr["script_errors"] and not tr["script_errors"][-1].get("_judged"):
            # judge every new one (M6 "split": where it was raised)
            for e in tr["script_errors"]:
                if e.get("_judged"):
                    continue
                e["_judged"] = True
                at = e.get("at")
                if at is None:
                    cond("TEST", "script error, no raising frame in the log (%s), owner=UNRESOLVED" % e["text"], e["unix"], "script_error",
                         stop_now=True, grace=2.0)
                elif at.startswith("res://scripts/dev/"):
                    cond("TEST", "script error raised in test code at %s (%s): %s, owner=UNRESOLVED" % (at, e.get("func"), e["text"]), e["unix"],
                         "script_error", stop_now=True, grace=2.0)
                else:
                    cond("FAIL", "script error at %s (%s): %s, owner=UNRESOLVED" % (at, e.get("func"), e["text"]), e["unix"], "script_error")
        # ---- the heartbeat
        for ln in rig.lines():
            if ln.startswith("beat\t"):
                d = dict(kv.split("=", 1) for kv in ln.split("\t")[1:] if "=" in kv)
                beat = d
                tr["beats"] += 1
                last_beat = now_m
                if tr["first_beat"] is None:
                    tr["first_beat"] = now_w
                    tr["pid"] = int(d.get("pid", "0"))
                    say("first beat, game pid %s, %.1f s after launch" % (d.get("pid"), now_w - (tr["launch"] or t_start)))
                p, w = int(d.get("pf", "0")), int(d.get("wf", "0"))
                if p != pf:
                    pf, pf_at = p, (now_m, now_w)
                if w != wf:
                    wf, wf_at = w, (now_m, now_w)
                dev = d.get("p2dev")
                if p2dev_prev and p2dev_prev.startswith("PAD") and dev == "KBM":
                    p2dev_drop = now_m
                p2dev_prev = dev
                if d.get("scen") and (d.get("p1") != "ok" or d.get("p2") != "ok"):
                    missing_n += 1
                    if missing_since is None:
                        missing_since = now_w
                    if missing_n >= int(L["missing_actor_beats"]) and stop is None:
                        who = "P1" if d.get("p1") != "ok" else "P2"
                        cond("NOT HEALTHY", "%s missing from the scene (in %s)" % (who, d.get("scen")), missing_since, "health", stop_now=True)
                else:
                    missing_n, missing_since = 0, None
            elif ln.startswith("ev\t"):
                parts = ln.split("\t", 2)
                kind, text = parts[1], (parts[2] if len(parts) > 2 else "")
                if kind == "start":
                    tr["started"].append({"scen": text, "unix": now_w})
                    say("scenario started: %s" % text)
                elif kind == "end":
                    tr["ended"].append({"scen": text, "unix": now_w})
                    say("scenario ended: %s" % text)
                elif kind in ("lint", "need"):
                    cond("TEST", "the plan / declared needs: %s" % text, now_w, "preflight", owner="TEST", stop_now=True)
                elif kind == "input_lost":
                    cond("TEST", "an input never reached the intended device: %s" % text, now_w, "input", stop_now=True)
                elif kind == "quit":
                    last_beat = None
        # ---- the method's events
        for ln in evs.lines():
            try:
                e = json.loads(ln)
            except ValueError:
                cond("TEST", "malformed event line: %s" % ln[:120], now_w, "event", stop_now=True)
                continue
            k = e.get("ev")
            if k == "OPEN":
                lag = max(0.0, now_w - float(e["unix"]))
                opens[e["id"]] = (e["step"], now_m - lag + float(e["secs"]), float(e["unix"]), float(e["secs"]))
                last_step = e["id"]
            elif k == "CLOSE":
                o = opens.pop(e["id"], None)
                if o is not None:
                    dur = float(e["unix"]) - o[2]
                    st = o[0].split(":")[0]
                    tr["step_secs"].setdefault(st, []).append(round(dur, 2))
                    m = tr["opens_max"].get(st)
                    if m is None or dur / o[3] > m[0] / m[1]:
                        tr["opens_max"][st] = [round(dur, 2), o[3]]     # the instance closest to its deadline
            elif k == "CHECK":
                tr["checks"].append(e)
            elif k == "WORK":
                tr["work"].append(e)
            elif k == "ATTEMPT":
                tr["attempts"].append(e)
                say("attempt: %s" % {x: e.get(x) for x in ("target", "lane", "lip_kmh", "lane_at_lip", "what")})
            elif k == "PREFLIGHT":
                tr["preflight"].append(e)
                if not e.get("ok"):
                    cond("TEST", "preflight: invalid required read(s) %s in %s" % (e.get("bad"), e.get("scen")), float(e["unix"]), "preflight", stop_now=True)
            elif k == "STALE":
                cond("TEST", "invalid required observation: %s (%s) in %s" % (e.get("field"), e.get("why"), e.get("scen")), float(e["unix"]), "stale", stop_now=True)
            elif k == "ABSENT":
                cond("FAIL", "%s missing (%s), owner=UNRESOLVED" % (e.get("object"), e.get("why")), float(e["unix"]), "absent")
            elif k == "FIRE":
                cond("FAIL", "%s: %s, owner=UNRESOLVED" % (e.get("rule"), e.get("text")), float(e["unix"]), "rule")
            elif k == "WINDOW":
                tr["windows"].append(e)
            elif k == "G3B":
                tr["g3b"].append(e)
                tol = fz["thresholds"].get("G3b_tolerance_m")
                if tol is not None and float(e["worst"]) > float(tol):
                    cond("FAIL", "G3b: the %s is %.3f m off where it was built on its wheel (tolerance %.3f m), van parked at %s, owner=UNRESOLVED"
                         % (e.get("worst_part"), float(e["worst"]), float(tol), e.get("van_at")), float(e["unix"]), "rule")
            elif k == "RULES":
                tr["rules"][e.get("scen_end")] = e
            elif k == "PLAN_BAD":
                cond("TEST", "malformed plan: %s" % e.get("what"), float(e["unix"]), "preflight", owner="TEST", stop_now=True)
        # ---- deadlines (host monotonic)
        for oid, o in list(opens.items()):
            if now_m > o[1] and stop is None:
                cond("INCOMPLETE", "STALLED at %s: open %.2f s, deadline %.1f s (owner=UNRESOLVED)" % (oid, now_w - o[2], o[3]), o[2], "stall", stop_now=True)
                tr["stall_detect_after_deadline_s"] = round(now_m - o[1], 2)
                tr["stall_detect_after_open_s"] = round(now_w - o[2], 2)
        # ---- health (M3)
        if stop is None:
            if tr["launch"] is not None and tr["first_beat"] is None and now_m - launch_m > float(L["startup_first_beat_s"]):
                cond("NOT HEALTHY", "no heartbeat %.0f s after the game launched" % (now_m - launch_m), tr["launch"], "health", stop_now=True)
            elif last_beat is not None and now_m - last_beat > float(L["no_beat_s"]):
                cond("NOT HEALTHY", "frozen: no heartbeat for %.0f s (in %s, step '%s')" % (now_m - last_beat, beat.get("scen"), beat.get("step")),
                     now_w - (now_m - last_beat), "health", stop_now=True)
            elif last_beat is not None and pf_at and now_m - pf_at[0] > float(L["no_physics_s"]) and now_m - last_beat < 2.0:
                cond("NOT HEALTHY", "physics stopped for %.0f s with fresh beats (in %s)" % (now_m - pf_at[0], beat.get("scen")), pf_at[1], "health", stop_now=True)
            elif last_beat is not None and beat.get("paused") == "1" and wf_at and now_m - wf_at[0] > float(L["pause_s"]):
                if p2dev_drop is not None and wf_at[0] - p2dev_drop < 3.0:
                    cond("NOT HEALTHY", "paused after P2's pad was lost (PAD -> KBM) in %s; no logged unplug seen by the method, owner=UNRESOLVED" % beat.get("scen"),
                         wf_at[1], "health", stop_now=True)
                else:
                    cond("NOT HEALTHY", "unallowed pause, world clock stopped %.0f s (in %s, note '%s')" % (now_m - wf_at[0], beat.get("scen"), beat.get("note")),
                         wf_at[1], "health", stop_now=True)
        # ---- the stop: kill once the grace window (script errors) is over
        if stop is not None and not tr["kill"] and now_m >= grace_until:
            pid = tr["pid"]
            if pid is None:
                ps = godot_pids()
                pid = ps[0] if len(ps) == 1 else None
            tr["detect_to_kill_start_s"] = round(now_m - stop_at_mono, 2)
            if pid:
                say("STOP (%s): killing game pid %d" % (stop["text"][:80], pid))
                ok = kill(pid, tr["kill"], float(L["kill_verify_s"]))
                tr["kill_ok"] = ok
                if not ok:
                    cond("TEST", "KILL FAILED: game process %d still alive" % pid, now_w, "kill", owner="UNRESOLVED")
            else:
                tr["kill"].append("no game pid known (nothing launched yet)")
                tr["kill_ok"] = True
            tr["shutdown_s"] = round(time.monotonic() - now_m, 2)
            for k2 in tr["kill"]:
                say(k2)
        # ---- progress every 5 s; a log that stops growing
        sz = os.path.getsize(os.path.join(runs, "seg_1.log")) if os.path.exists(os.path.join(runs, "seg_1.log")) else 0
        if sz != seg_size:
            seg_size, seg_grow = sz, now_m
        if now_m - last_say >= float(L["progress_s"]):
            last_say = now_m
            say("t=%3.0fs scen=%s pf=%s paused=%s beat_age=%s log %d B (grew %.0f s ago) open=%d last=%s" % (
                now_m - t_start_mono, beat.get("scen"), beat.get("pf"), beat.get("paused"),
                ("%.1fs" % (now_m - last_beat)) if last_beat else "-", sz, now_m - seg_grow, len(opens), last_step))
        # ---- the end
        if wrapper.poll() is not None:
            break
        if tr["kill"] and now_m - stop_at_mono > 15.0:
            say("wrapper still running 15 s after the stop: terminating it")
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(wrapper.pid)], capture_output=True)
            try:
                wrapper.wait(5)
            except subprocess.TimeoutExpired:
                tr["kill"].append("wrapper %d did not exit" % wrapper.pid)
            break
        cap_s = float(L.get("whole_run_cap_ghat_s", L["whole_run_cap_s"])) if plan.startswith("ghat") else float(L["whole_run_cap_s"])
        if time.monotonic() - t_start_mono > cap_s and stop is None:
            cond("INCOMPLETE", "STALLED: the whole command passed its cap %.0f s" % cap_s, now_w, "stall", stop_now=True)
            grace_until = now_m
        time.sleep(float(L["poll_s"]))
    # whatever ended the run: no game may survive it
    wrapper_out.close()
    tr["wrapper_rc"] = wrapper.returncode
    left = [p for p in godot_pids()]
    tr["godot_left_after"] = left
    if tr["pid"] and alive(tr["pid"]):
        kill(tr["pid"], tr["kill"], float(L["kill_verify_s"]))
    if "don't compile" in open(os.path.join(out, "run_test.out"), encoding="utf-8", errors="replace").read():
        cond("TEST", "the scripts don't compile: nothing ran", t_start, "preflight", owner="TEST")
    tr["open_at_end"] = {k: v[0] for k, v in opens.items()}
    tr["last_step"] = last_step
    tr["last_beat_step"] = beat.get("step", "")
    tr["wall_s"] = round(time.monotonic() - t_start_mono, 1)
    tr["t_end"] = time.time()
    json.dump(tr, open(os.path.join(out, "trace.json"), "w", encoding="utf-8"), indent=1, default=str)
    code = method_verdict.report(tr, fz, out)
    sys.exit(code)


if __name__ == "__main__":
    main()
