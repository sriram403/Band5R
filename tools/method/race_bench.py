"""The rename-race check (2026-11-17/24, autoq): the game answers a command by renaming res.tmp onto res.json; on
Windows that rename fails while another process has res.json open (the client polls it every 0.1 s). One failed
rename lost a walk's result and the client waited 13 min. This bench holds res.json open for HOLD s right after
each command, the way an unlucky client read would, then checks the answer still lands.

    tools/method/race_bench.sh          (launches lane a's game, runs this, stops the game)
    python tools/method/race_bench.py   (a live game must be ready in lane a)

PASS: every answer lands (the game retried until the lock went). FAIL: an answer lost (the old one-shot rename).
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
LANE = os.environ.get("LANE", "")
LIVE = os.path.join(HERE, "..", "..", "appdata", "playtest" + ("_" + LANE if LANE else ""), "FindingNaresh", "live")
HOLD = float(os.environ.get("RACE_HOLD", "1.0"))


def send(cid):
    tmp = os.path.join(LIVE, "cmd.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump({"id": cid, "cmds": [{"do": "state"}], "quit": False}, f)
    for _ in range(50):
        try:
            os.replace(tmp, os.path.join(LIVE, "cmd.json"))
            return
        except PermissionError:
            time.sleep(0.05)


def res_id():
    try:
        with open(os.path.join(LIVE, "res.json"), encoding="utf-8") as f:
            return int(json.load(f).get("id", -9))
    except (OSError, ValueError):
        return -9


def main():
    rp = os.path.join(LIVE, "res.json")
    if not os.path.exists(rp):
        print("race bench: no res.json (is the game ready?)")
        return 2
    base = int(time.time() * 10) % 1000000000
    lost = 0
    for i in range(3):
        cid = base + i
        h = open(rp, "rb")            # held like an unlucky client read (no delete sharing on Windows)
        send(cid)
        time.sleep(HOLD)
        h.close()
        t0 = time.time()
        while time.time() - t0 < 5 and res_id() != cid:
            time.sleep(0.05)
        ok = res_id() == cid
        lost += 0 if ok else 1
        print("race bench %d: res.json held %.1f s while the game answered -> answer %s" % (i + 1, HOLD, "LANDED" if ok else "LOST"), flush=True)
        if not ok:
            send(cid + 100)           # unstick: a fresh command (a lost answer leaves the old id)
            time.sleep(1.5)
    print("race bench: %s (%d of 3 lost)" % ("PASS" if lost == 0 else "FAIL", lost))
    return 0 if lost == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
