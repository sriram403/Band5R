"""c1, the rig layer: the outside watcher (research trial c1, 2026-11-05).

Started by tools/rig_run.sh next to tools/run_test.sh. Reads the game's
heartbeat file (appdata/playtest/runs/rig.txt, written by dev/RigBeat.gd)
every second, from OUTSIDE the game, so a frozen game is noticed by its
silence. It never reads the referee's injection switches: only effects.

Rules (stop the run at once when one fires):
  frozen       no new heartbeat for STALE_S (the main loop stopped)
  physics      heartbeats arrive but the engine's physics frames don't move
  paused       the world clock (a pausable node) stops while paused, PAUSE_S
               (the pad-lost case: P2's device went PAD -> KBM = TEST problem)
  player       P1 or P2 not in the scene while a scenario runs
  input_lost   an input never reached the intended player's device = TEST
  lint / need  plan or declared needs broken before step 1 = TEST
At the end: scenarios asked vs ran, by ID.

The verdict has two parts, reported apart:
  RIG: healthy | TEST problem (which) | NOT healthy (which)
  INNER CHECKS: pass / fail (the scenario's own checks; c1 claims nothing
  about the game, and they count only when the rig is healthy)
"""
import os
import subprocess
import sys
import time

STALE_S = 20.0       # a save reload rebuilds the world (~10 s, main thread busy)
PHYS_S = 10.0
PAUSE_S = 5.0
FIRST_BEAT_S = 300.0  # compile (~40 s) + world build before the first beat
POLL_S = 1.0


def say(s):
    print("[rig-watch] " + s, flush=True)


def parse_beat(line):
    d = {}
    for kv in line.split("\t")[1:]:
        if "=" in kv:
            k, v = kv.split("=", 1)
            d[k] = v
    return d


def asked_ids(plan, root):
    """The scenarios asked for, by ID, per segment (from tools/test_plan.sh).
    A preset name (smoke, full, set:...) whose scenarios live in PlayTest
    can't be listed from outside: None (the game's own plan line is used)."""
    try:
        out = subprocess.run(["sh", "-c", '. tools/test_plan.sh; test_plan "$1"', "x", plan],
                             cwd=root, capture_output=True, text=True, timeout=20).stdout
    except Exception:
        out = "|" + plan
    ids = []
    for seg in out.splitlines():
        scen = seg.split("|", 1)[1] if "|" in seg else seg
        for s in scen.split(","):
            if s in ("", "smoke", "quick", "gym_quick", "full"):
                return None
            ids.append(s)
    return ids


def kill(pid):
    if pid:
        subprocess.run(["taskkill", "/PID", str(pid), "/F", "/T"], capture_output=True)


def main():
    runs, plan, root = sys.argv[1], sys.argv[2], sys.argv[3]
    rig = os.path.join(runs, "rig.txt")
    out = os.path.join(runs, "rig_run.out")
    asked = asked_ids(plan, root)
    say("asked: %s" % (",".join(asked) if asked is not None else "(preset %s: listed by the game)" % plan))
    t0 = time.time()
    pos = 0
    last_beat = None          # wall time we last saw a new beat
    first_wait_from = t0
    pf, pf_at = None, None
    wf, wf_at = None, None
    beat = {}
    prev_p2dev = None
    p2dev_drop_at = None      # when P2's device went PAD -> KBM
    missing_n = 0
    quit_pids = set()
    started, ended, plans, lints, needs, lost, holds = [], [], [], [], [], [], []
    stop_reason = None        # ("TEST" | "NOT healthy", text)
    noticed_at = None
    last_say = 0.0
    while True:
        now = time.time()
        # -- new lines from the heartbeat file
        if os.path.exists(rig):
            with open(rig, "r", encoding="utf-8", errors="replace") as f:
                f.seek(pos)
                chunk = f.read()
                pos = f.tell()
            for line in chunk.splitlines():
                if line.startswith("beat\t"):
                    beat = parse_beat(line)
                    last_beat = now
                    p = int(beat.get("pf", "0"))
                    w = int(beat.get("wf", "0"))
                    if p != pf:
                        pf, pf_at = p, now
                    if w != wf:
                        wf, wf_at = w, now
                    dev = beat.get("p2dev")
                    if prev_p2dev and prev_p2dev.startswith("PAD") and dev == "KBM":
                        p2dev_drop_at = now
                        say("P2's device went %s -> KBM in %s" % (prev_p2dev, beat.get("scen")))
                    prev_p2dev = dev
                elif line.startswith("ev\t"):
                    parts = line.split("\t", 2)
                    kind, text = parts[1], parts[2] if len(parts) > 2 else ""
                    say("event %s: %s" % (kind, text))
                    if kind == "start":
                        started.append(text)
                    elif kind == "end":
                        ended.append(text)
                    elif kind == "plan":
                        plans.append(text)
                    elif kind == "lint":
                        lints.append(text)
                    elif kind == "need":
                        needs.append(text)
                    elif kind == "input_lost":
                        lost.append(text)
                    elif kind == "pause_hold":
                        holds.append(text)
                    elif kind == "quit":
                        quit_pids.add(beat.get("pid"))
                        last_beat = None          # this process ends; the next segment may start
                        first_wait_from = now
                        pf = wf = None
        # -- rules
        if stop_reason is None:
            if lints:
                stop_reason = ("TEST problem", "the plan: " + lints[0])
            elif needs:
                stop_reason = ("TEST problem", "a stale expression / node name: " + needs[0])
            elif lost:
                stop_reason = ("TEST problem", "an input never reached the intended device: " + lost[0])
            elif last_beat is None:
                if now - first_wait_from > FIRST_BEAT_S and not os.path.exists(os.path.join(runs, "finished.txt")) and not run_over(out):
                    stop_reason = ("NOT healthy", "no heartbeat %.0f s after launch" % (now - first_wait_from))
            elif now - last_beat > STALE_S:
                stop_reason = ("NOT healthy", "frozen: no heartbeat for %.0f s (in %s, step '%s')" % (now - last_beat, beat.get("scen"), beat.get("step")))
            elif pf_at and now - pf_at > PHYS_S and now - last_beat < 2.0:
                stop_reason = ("NOT healthy", "frozen: physics frames stopped for %.0f s (in %s)" % (now - pf_at, beat.get("scen")))
            elif beat.get("paused") == "1" and wf_at and now - wf_at > PAUSE_S:
                if p2dev_drop_at is not None and wf_at - p2dev_drop_at < 3.0:
                    stop_reason = ("TEST problem", "P2's pad was lost (device PAD -> KBM) in %s; the game correctly paused ('%s')" % (beat.get("scen"), beat.get("note")))
                else:
                    stop_reason = ("NOT healthy", "the game is paused, world clock stopped %.0f s (in %s, note '%s', step '%s')" % (now - wf_at, beat.get("scen"), beat.get("note"), beat.get("step")))
            elif beat.get("scen") and (beat.get("p1") != "ok" or beat.get("p2") != "ok"):
                missing_n += 1
                if missing_n >= 2:
                    who = "P1" if beat.get("p1") != "ok" else "P2"
                    stop_reason = ("NOT healthy", "%s missing from the scene (in %s)" % (who, beat.get("scen")))
            else:
                missing_n = 0
            if stop_reason is not None:
                noticed_at = now
                say("STOP: %s: %s" % stop_reason)
                kill(beat.get("pid"))
        # -- progress line every 5 s, so a person can see it move
        if now - last_say >= 5.0:
            last_say = now
            age = (now - last_beat) if last_beat else -1
            say("t=%3.0fs gen=%s scen=%s pf=%s wf=%s paused=%s p2=%s/%s beat_age=%.0fs step=%s" % (
                now - t0, beat.get("gen"), beat.get("scen"), beat.get("pf"), beat.get("wf"), beat.get("paused"),
                beat.get("p2"), beat.get("p2dev"), age, beat.get("step", "")[:60]))
        if os.path.exists(os.path.join(runs, "finished.txt")) or run_over(out):
            break
        if stop_reason is not None and now - noticed_at > 40:
            break
        time.sleep(POLL_S)
    verdict(runs, asked, plans, started, ended, lints, stop_reason, t0)


def run_over(out):
    if not os.path.exists(out):
        return False
    with open(out, "r", encoding="utf-8", errors="replace") as f:
        t = f.read()
    return "broke off before its end" in t or "don't compile" in t or "Nothing to resume" in t


def verdict(runs, asked, plans, started, ended, lints, stop_reason, t0):
    want = asked if asked is not None else [s for p in plans[:1] for s in p.split(",") if s]
    ran = [s for s in want if s in ended]
    not_run = [s for s in want if s not in ended]
    lines = []
    if stop_reason is not None:
        rig = "%s: %s" % stop_reason
    elif not_run:
        why = [l for l in lints if any(s in l for s in not_run)]
        if why:
            rig = "TEST problem: asked but never ran: %s (%s)" % (",".join(not_run), why[0])
        else:
            rig = "NOT healthy: asked but never ran (skipped): %s" % ",".join(not_run)
    else:
        rig = "healthy"
    lines.append("==== RIG: %s ====" % rig)
    lines.append("     asked %d (%s), ran %d (%s), not run %d (%s); %.0f s" % (
        len(want), ",".join(want), len(ran), ",".join(ran), len(not_run), ",".join(not_run), time.time() - t0))
    summ = os.path.join(runs, "summary.txt")
    inner = "not finished (the run was stopped)"
    detail = []
    if os.path.exists(summ):
        with open(summ, encoding="utf-8", errors="replace") as f:
            s = f.read().splitlines()
        if s:
            fails = [l for l in s[1:] if l.strip().startswith("- [")]
            inner = ("FAIL (%d)" % len(fails)) if fails else "PASS"
            detail = fails
    counts = "" if rig == "healthy" else "  [not counted: the rig isn't healthy]"
    lines.append("==== INNER CHECKS: %s%s ====" % (inner, counts))
    lines += ["     " + d.strip() for d in detail]
    lines.append("     c1 claims only the rig line. NOT PROVEN by c1: anything about the game.")
    text = "\n".join(lines)
    print(text, flush=True)
    with open(os.path.join(runs, "rig_verdict.txt"), "w", encoding="utf-8") as f:
        f.write(text + "\n")
    sys.exit(0 if rig == "healthy" else 2)


if __name__ == "__main__":
    main()
