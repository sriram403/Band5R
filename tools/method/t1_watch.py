"""T1: watch a method run while it runs (speed research). Prints at once every condition, result,
script error, scenario start / end, [speed] and [nodraw] line (console + both lanes' game logs),
and the newest heartbeat status line every PERIOD s. Exits when <done file> appears.
Usage: python -u tools/method/t1_watch.py <console out> <done file> [period s]
"""
import os
import re
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
out, done = sys.argv[1], sys.argv[2]
period = float(sys.argv[3]) if len(sys.argv) > 3 else 20.0
KEY = re.compile(r"CONDITION|RESULT|SCRIPT ERROR|STOP|scenario (started|ended)|\[speed\]|SPEED=fast|refus|not launching|"
                 r"Traceback|KILL|ERROR|\[nodraw\] off|FAIL ")
files = {out: [0, None]}
for lane in ("playtest", "playtest_b"):
    f = os.path.join(ROOT, "appdata", lane, "runs", "seg_1.log")
    try:
        files[f] = [os.path.getsize(f), os.stat(f).st_ctime]     # an old log: from its end
    except OSError:
        files[f] = [0, None]
last_status, last_emit = "", time.time()
t0 = time.time()
while True:
    for f in list(files):
        try:
            sz, ct = os.path.getsize(f), os.stat(f).st_ctime
        except OSError:
            continue
        pos, ct0 = files[f]
        if (ct0 is not None and ct != ct0) or sz < pos:
            pos = 0                                                # a new run's log
        with open(f, encoding="utf-8", errors="replace") as h:
            h.seek(pos)
            data = h.read()
            files[f] = [h.tell(), ct]
        tag = "" if f == out else ("[game b] " if "playtest_b" in f else "[game a] ")
        for ln in data.splitlines():
            if re.search(r"t=\s*\d+s scen=", ln):
                last_status = ln.strip()
            elif KEY.search(ln) and "speed research" not in ln:
                print("%5.0fs %s%s" % (time.time() - t0, tag, ln.strip()[:260]), flush=True)
    if time.time() - last_emit >= period and last_status:
        print("%5.0fs status: %s" % (time.time() - t0, last_status[:200]), flush=True)
        last_emit = time.time()
    if os.path.exists(done):
        print("%5.0fs DONE (%s)" % (time.time() - t0, open(done).read().strip()), flush=True)
        break
    time.sleep(1.0)
