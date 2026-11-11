"""The final method's one supervisor (test-method research, Stage 4).

Launches tools/run_test.sh <plan> itself, owns the game's PID, and judges only
from what it reads OUTSIDE the game (never a fixture switch):
  rig.txt            c1's heartbeat and events (dev/RigBeat.gd)
  method_events.txt  OPEN / CLOSE, CHECK, WORK, ATTEMPT, PREFLIGHT, STALE,
                     ABSENT, FIRE, WINDOW, G3B, RULES (dev/MethodRec.gd, C2Watch)
  seg_1.log          SCRIPT ERROR blocks (with their raising frame), the launch
Limits from tools/method/frozen.json (M3). Step deadlines (STALL) are judged
on GAME time (speed research T1, 2026-11-10): physics frames from the events'
and heartbeats' `pf`, / 60; a step also stalls when its host-monotonic time
passes the budget (the old judge, kept: at 1x it fires exactly as before; fast
it only fires if the game ran below 1x). Health limits stay host seconds.
Wall time (same PC clock as the game) orders conditions; game time breaks ties.
LANE (env): a second game of this copy reads appdata/playtest_<lane>.
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


def godot_pids(mark=None, games_only=False):
    """Godot processes; with `mark`, only those whose command line holds it (this copy's lane:
    another copy's game, or this copy's other lane, is never ours to count or kill)."""
    if mark is None:
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq godot*", "/NH", "/FO", "CSV"], capture_output=True, text=True).stdout
        pids = []
        for ln in out.splitlines():
            f = [x.strip('"') for x in ln.split('","')]
            if len(f) > 1 and f[1].isdigit():
                pids.append(int(f[1]))
        return pids
    ps = ("Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | ForEach-Object { "
          "\"$($_.ProcessId)`t$($_.CommandLine)\" }")
    out = subprocess.run(["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", ps], capture_output=True, text=True).stdout
    m = mark.replace("\\", "/").lower()
    pids = []
    for ln in out.splitlines():
        pid, _, cl = ln.partition("\t")
        if pid.strip().isdigit() and m in cl.replace("\\", "/").lower():
            # T1: a game is 2 processes, the _console.exe wrapper and the game it starts
            if games_only and "_console.exe" in cl.lower():
                continue
            pids.append(int(pid))
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


def closed_late(o, e):
    """Fix round (GPT's blocker 2): a step that CLOSED is judged against its budget on both clocks
    before it is dropped. o = the OPEN (step, deadline_mono, open_unix, secs, open_pf); e = the CLOSE
    event. -> (late?, game s, wall s). Wall s from the game's own stamps (same PC clock), so a reader
    that polls late judges exactly what one polling at once would have judged."""
    game = (int(e.get("pf", 0)) - o[4]) / 60.0
    wall = float(e.get("unix", o[2])) - o[2]
    return (game > o[3] or wall > o[3]), game, wall


def expected_on_record(tr, fz, expect_ids):
    """Fix round (GPT's blocker 3): the exact ids (manifest check ids, rule ids) that FAILed so far,
    and whether every expected id is among them. Checks are mapped to their manifest ids the same way
    the verdict does (method_verdict.match_checks, per scenario, in order); rules by the FIRE's id."""
    have = set()
    req = fz["required"]
    for scen in {c.get("scen") for c in tr["checks"]}:
        man = req.get(scen, {}).get("checks", [])
        if not man:
            continue
        pairs, _ = method_verdict.match_checks([c for c in tr["checks"] if c.get("scen") == scen], man)
        for m, c in pairs:
            if not c.get("ok") and m.get("kind", "plain") not in ("jump", "departure"):
                have.add(m["id"])
    for c in tr["conditions"]:
        if c["status"] == "FAIL" and c.get("id"):
            have.add(c["id"])
    return all(x in have for x in expect_ids), have


class Tail:
    """Reads only complete new lines of a growing file."""

    def __init__(self, path):
        self.path, self.off = path, 0

    def leftover(self):
        """bytes after the last complete line (a truncated last line)"""
        if not os.path.exists(self.path):
            return 0
        return max(0, os.path.getsize(self.path) - self.off)

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
    lane = os.environ.get("LANE", "")
    runs = os.path.join(root, "appdata", "playtest" + ("_" + lane if lane else ""), "runs")
    mark = runs.replace("\\", "/")          # the game's --progress=<runs>/progress.txt holds it
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
          "launch": None, "first_beat": None, "opens_max": {}, "step_secs": {}, "pid": None,
          "inv": os.environ.get("INV", ""), "part": os.environ.get("PART", ""),
          "fixture": (re.search(r"--method-fixture=(\S+)", extra).group(1) if "--method-fixture=" in extra else ""),
          "closed_late": [], "drained": False}
    opens = {}                  # id -> (step, deadline_mono, open_wall, secs, open_pf)
    pf_now = 0                  # the newest physics frame seen (beats and events)
    fast = bool(os.environ.get("FAST"))
    # T2 early stop: EXPECT_FAIL="text|text" (a plant proof's expected FAILs). Once every one is on
    # record as a failed check or a FAIL condition, the run stops: "detection complete, rest not run".
    # fix round (blocker 3): EXPECT_IDS="<manifest check id>|<rule id>" exact ids only (no substrings)
    expect = [x for x in os.environ.get("EXPECT_IDS", "").split("|") if x]
    if os.environ.get("EXPECT_FAIL"):
        print("EXPECT_FAIL (substrings) is retired: use EXPECT_IDS (exact ids)", flush=True)
        sys.exit(3)
    tr["expect_ids"] = expect
    # fix-round control only (off by default): T1_LAG="<step>:<s>" -- after reading that step's OPEN,
    # the watcher stops reading for <s> wall s once (a delayed reader: the step is never seen open
    # past its deadline; its CLOSE arrives in a later read)
    lag_step, _, lag_s = os.environ.get("T1_LAG", "").partition(":")
    lag_done = False
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
    drained = False

    def cond(status, text, begin, kind, owner="UNRESOLVED", stop_now=False, grace=0.0):
        nonlocal stop, stop_at_mono, grace_until
        c = {"status": status, "text": text, "begin": begin, "detected": time.time(), "kind": kind, "owner": owner, "pf": pf_now,
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
                pf_now = max(pf_now, p)
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
        relisten = False
        for ln in evs.lines():
            try:
                e = json.loads(ln)
            except ValueError:
                cond("TEST", "malformed event line: %s" % ln[:120], now_w, "event", stop_now=True)
                continue
            k = e.get("ev")
            if "pf" in e:
                pf_now = max(pf_now, int(e["pf"]))
            if k == "OPEN":
                lag = max(0.0, now_w - float(e["unix"]))
                opens[e["id"]] = (e["step"], now_m - lag + float(e["secs"]), float(e["unix"]), float(e["secs"]), int(e.get("pf", 0)))
                last_step = e["id"]
                if lag_step and e["step"] == lag_step and not lag_done:
                    lag_done = True
                    say("T1_LAG control: not reading for %s wall s after the OPEN of %s" % (lag_s, e["id"]))
                    time.sleep(float(lag_s))
                    relisten = True
            elif k == "CLOSE":
                o = opens.pop(e["id"], None)
                if o is not None:
                    late, dur, wdur = closed_late(o, e)
                    if late:
                        # judged before it is dropped; recorded even after a stop (never lost)
                        tr["closed_late"].append({"id": e["id"], "game_s": round(dur, 2), "wall_s": round(wdur, 2), "secs": o[3]})
                        cond("INCOMPLETE", "STALLED at %s: closed late, %.2f game s (%.2f wall s) against a deadline of %.1f s, %s (owner=UNRESOLVED)"
                             % (e["id"], dur, wdur, o[3], "game clock" if dur > o[3] else "wall clock"), o[2], "stall",
                             stop_now=True)["pf"] = o[4]
                        if "stall_game_open_s" not in tr:
                            tr["stall_detect_after_deadline_s"] = round(dur - o[3], 2)
                            tr["stall_detect_after_open_s"] = round(now_w - o[2], 2)
                            tr["stall_game_open_s"] = round(dur, 2)
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
                c = cond("FAIL", "%s: %s, owner=UNRESOLVED" % (e.get("rule"), e.get("text")), float(e["unix"]), "rule")
                c["pf"], c["id"] = int(e.get("pf", pf_now)), e.get("rule")
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
        if relisten:
            continue        # the delayed reader's next read comes before any judging (T1_LAG control)
        # ---- T2: every expected FAIL on record -> stop early (never a PASS: the ledger says what didn't run)
        if expect and stop is None and not drained:
            done, _have = expected_on_record(tr, fz, expect)
            if done:
                cond("INCOMPLETE", "EARLY STOP (T2): every expected FAIL is on record (%s); detection complete, the rest not run"
                     % " + ".join(expect), now_w, "early", stop_now=True, grace=1.0)
                tr["early_stop"] = True
        # ---- deadlines: game time (pf / 60), and the old host-monotonic judge (T1)
        for oid, o in list(opens.items()):
            game_open = (pf_now - o[4]) / 60.0
            by_game, by_wall = game_open > o[3], now_m > o[1]
            if (by_game or by_wall) and stop is None:
                clock = "game clock" if by_game else ("wall clock first: the game ran below 1x" if fast else "wall clock")
                cond("INCOMPLETE", "STALLED at %s: open %.2f game s (%.2f wall s), deadline %.1f game s, %s (owner=UNRESOLVED)"
                     % (oid, game_open, now_w - o[2], o[3], clock), o[2], "stall", stop_now=True)["pf"] = o[4]
                tr["stall_detect_after_deadline_s"] = round(game_open - o[3], 2) if by_game else round(now_m - o[1], 2)
                tr["stall_detect_after_open_s"] = round(now_w - o[2], 2)
                tr["stall_game_open_s"] = round(game_open, 2)
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
                ps = godot_pids(mark, games_only=True)
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
        # ---- the end: once the wrapper has exited, one more full pass reads (and judges) every
        # event the game wrote before it went (fix round: drain all events at the end)
        if wrapper.poll() is not None:
            if drained:
                break
            drained = True
            tr["drained"] = True
            continue
        if tr["kill"] and now_m - stop_at_mono > 15.0:
            say("wrapper still running 15 s after the stop: terminating it")
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(wrapper.pid)], capture_output=True)
            try:
                wrapper.wait(5)
            except subprocess.TimeoutExpired:
                tr["kill"].append("wrapper %d did not exit" % wrapper.pid)
            if not drained:
                drained = True
                tr["drained"] = True
                continue
            break
        cap_s = float(L.get("whole_run_cap_ghat_s", L["whole_run_cap_s"])) if plan.startswith("ghat") else float(L["whole_run_cap_s"])
        if time.monotonic() - t_start_mono > cap_s and stop is None:
            cond("INCOMPLETE", "STALLED: the whole command passed its cap %.0f s" % cap_s, now_w, "stall", stop_now=True)
            grace_until = now_m
        time.sleep(float(L["poll_s"]))
    # whatever ended the run: no game may survive it
    wrapper_out.close()
    tr["wrapper_rc"] = wrapper.returncode
    if tr["pid"] and alive(tr["pid"]):
        kill(tr["pid"], tr["kill"], float(L["kill_verify_s"]))
    # T1: counted after the last kill (was before it: listed processes the next line killed)
    left = [p for p in godot_pids(mark)]
    tr["godot_left_after"] = left
    if "don't compile" in open(os.path.join(out, "run_test.out"), encoding="utf-8", errors="replace").read():
        cond("TEST", "the scripts don't compile: nothing ran", t_start, "preflight", owner="TEST")
    # fix round: a last line the game never finished is evidence lost: never a PASS
    for t, nm in ((evs, "method_events.txt"), (rig, "rig.txt")):
        if t.leftover():
            cond("TEST", "%s ends in a truncated line (%d bytes not read)" % (nm, t.leftover()), time.time(), "event")
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
