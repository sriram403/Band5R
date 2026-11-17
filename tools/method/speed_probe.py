"""Speed research T1, the speed probe (pilot P1, 2026-11-10). Test tool only.

Watches a running play-test's heartbeat (appdata/playtest/runs/rig.txt, one line
every 0.5 s of process delta, dev/RigBeat.gd: wall ms + engine physics frames pf)
and prints, every few seconds, the game speed: physics frames / 60 per wall
second (1.0 = real time). With --fixed-fps 60 every frame is exactly one 1/60 s
physics step, so pf / 60 IS the game clock.

Usage: python tools/method/speed_probe.py <rig.txt> [max wall s] [label]
Stops when the beats stop for 8 s (the game ended) or at max wall s.
Last line: SPEED <label> ... (the whole scenario stretch and the steady part).
"""
import os
import sys
import time


def beats(path):
    out = []
    if not os.path.exists(path):
        return out
    with open(path, encoding="utf-8", errors="replace") as f:
        for ln in f:
            if not ln.startswith("beat\t"):
                continue
            d = dict(kv.split("=", 1) for kv in ln.rstrip("\n").split("\t")[1:] if "=" in kv)
            try:
                out.append((int(d["ms"]), int(d["pf"]), d.get("scen", ""), d.get("step", ""), d.get("paused", "0")))
            except (KeyError, ValueError):
                pass
    return out


def rate(a, b):
    dt = (b[0] - a[0]) / 1000.0
    return ((b[1] - a[1]) / 60.0) / dt if dt > 0 else 0.0


def main():
    path = sys.argv[1]
    cap = float(sys.argv[2]) if len(sys.argv) > 2 else 120.0
    label = sys.argv[3] if len(sys.argv) > 3 else "run"
    t0 = time.monotonic()
    last_n, last_grow = 0, time.monotonic()
    while True:
        time.sleep(3.0)
        b = beats(path)
        if len(b) != last_n:
            last_n, last_grow = len(b), time.monotonic()
        if len(b) >= 2:
            w = [x for x in b if x[0] >= b[-1][0] - 3000] or b[-2:]
            print("[probe %s] t=%3.0fs beats %d pf %d scen=%s paused=%s speed(last 3 s)=%.2fx step=%s" % (
                label, time.monotonic() - t0, len(b), b[-1][1], b[-1][2] or "-", b[-1][4], rate(w[0], b[-1]), b[-1][3][:70]), flush=True)
        else:
            print("[probe %s] t=%3.0fs waiting for beats (%d)" % (label, time.monotonic() - t0, len(b)), flush=True)
        if time.monotonic() - t0 > cap or (last_n and time.monotonic() - last_grow > 8.0):
            break
    b = beats(path)
    sc = [x for x in b if x[2]]
    if len(sc) < 2:
        print("SPEED %s: not enough scenario beats (%d)" % (label, len(sc)))
        return
    # steady: drop the first 5 wall s of the scenario (its setup jump / loads)
    st = [x for x in sc if x[0] >= sc[0][0] + 5000]
    print("SPEED %s: scenario %.1f wall s, %.1f game s, %.2fx; steady (after 5 s) %.2fx over %.1f wall s; boot->first beat %s" % (
        label, (sc[-1][0] - sc[0][0]) / 1000.0, (sc[-1][1] - sc[0][1]) / 60.0, rate(sc[0], sc[-1]),
        rate(st[0], st[-1]) if len(st) > 1 else 0.0, ((st[-1][0] - st[0][0]) / 1000.0) if len(st) > 1 else 0.0,
        "%.1f game s" % (b[0][1] / 60.0)))


if __name__ == "__main__":
    main()
