"""The live control line's client (dev/LiveControl.gd).

Start the game waiting for commands (window behind yours, as the tests are):
    tools/run_test.sh live            (in the background; GYM=<name> for a gym)
Then, one step at a time:
    python tools/live.py '{"do": "state"}'
    python tools/live.py '[{"do": "menu", "tab": "Story", "row": "Nearly out of fuel"}, {"do": "shot", "name": "a"}]'
    python tools/live.py --quit
It waits for the game's answer and prints it (results, messages, state,
the screenshot's path). Commands are listed at the top of LiveControl.gd.
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(HERE, "..", "appdata", "playtest", "FindingNaresh", "live")
# the game's output when started as: tools/run_test.sh live > appdata/live_run.log
LOG = os.path.join(HERE, "..", "appdata", "live_run.log")
SEEN = os.path.join(LIVE, "log_seen")


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
    out = []
    for ln in lines:
        if "ERROR" in ln or "at: " in ln:
            if not out or out[-1] != ln:
                out.append(ln)
    return out[:12]


def main() -> int:
    args = sys.argv[1:]
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
    walk = None
    if "--walk" in args:
        i = args.index("--walk")
        with open(args[i + 1], encoding="utf-8") as f:
            walk = json.load(f)
        del args[i:i + 2]
        timeout = max(timeout, 3600.0)
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
            msg = {"id": cid, "walk": walk, "from": walk_from or ""}
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
        try:
            with open(res_path, encoding="utf-8") as f:
                res = json.load(f)
        except (ValueError, OSError):
            continue
        if int(res.get("id", -2)) == cid:
            if walk is not None:
                print("RESULT:", "ok" if res.get("ok") else "FAILED at %s: %s" % (res.get("failed_step"), res.get("fail")))
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


if __name__ == "__main__":
    sys.exit(main())
