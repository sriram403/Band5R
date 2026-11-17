"""At most 2 games on this PC, and none of this copy's lane already running (T4 v2 / T3 v2 lanes).

A game is 2 processes (the _console.exe wrapper starts the game): games are counted without the
wrapper (T1's lesson). Lane folder: appdata/playtest (lane a) or appdata/playtest_<lane>.
  python tools/method/godot_guard.py [lane]          exit 0 = may launch, 3 = refused (why printed)
  python tools/method/godot_guard.py --pids [lane]   the game pids of this copy's lane (one per line)
  GUARD_INJECT="pid\\tcommand line\\n..."            test-only fake process lines (the refusal control)
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


def processes():
    ps = ("Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | "
          "ForEach-Object { \"$($_.ProcessId)`t$($_.CommandLine)\" }")
    out = subprocess.run(["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", ps],
                         capture_output=True, text=True, errors="replace").stdout
    lines = [ln.strip("\r") for ln in out.splitlines() if ln.strip()]
    inj = os.environ.get("GUARD_INJECT", "")
    if inj:
        lines += [ln for ln in inj.replace("\\t", "\t").replace("\\n", "\n").splitlines() if ln.strip()]
    return lines


def games(lines):
    return [ln for ln in lines if "_console.exe" not in ln.lower()]


def lane_of(cmdline):
    """A game's lane from its command line: --lane=<x> (walks), else --shots-dir=..._shots_<x> (method_run lane b)."""
    import re
    m = re.search(r"--lane=(\w*)", cmdline) or re.search(r"--shots-dir=\S*_shots_(\w+)", cmdline)
    return m.group(1) if m else ""


def mine(lines, lane):
    """This copy's games in this lane."""
    root = ROOT.replace("\\", "/").lower()
    return [ln for ln in games(lines) if root in ln.replace("\\", "/").lower() and lane_of(ln) == lane]


def main(a):
    pids = False
    if a and a[0] == "--pids":
        pids = True
        a = a[1:]
    lane = a[0] if a else os.environ.get("LANE", "")
    lines = processes()
    g = games(lines)
    m = mine(lines, lane)
    if pids:
        for ln in m:
            print(ln.split("\t")[0])
        return 0
    if m:
        print("REFUSED: a game of this copy runs in lane '%s': %s" % (lane or "a", m[0][:160]))
        return 3
    if len(g) >= 2:
        print("REFUSED: %d games already run on this PC (at most 2): %s" % (len(g), " | ".join(x[:80] for x in g)))
        return 3
    print("ok: %d game(s) on the PC, lane '%s' free" % (len(g), lane or "a"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
