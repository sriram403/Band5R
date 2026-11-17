"""F7 (fix round): picture evidence for the method runs (no game launched here).

  python tools/method/captures.py inventory <run dir>
      After a run (tools/method_run.sh calls it): reads the game's own capture log <run>/captures.jsonl
      (PlayTest.shot() writes one row per picture: scenario, tag, file, drawn frame, physics frame,
      game ms, unix time, sha256 of the saved file, the last check before it) and writes
      <run>/capture_inventory.json: the launch time (launch_mark), every row with the copied file's
      sha256 / mtime, and per (scenario, tag) the LAST capture (an earlier capture of the same tag was
      overwritten by the game: "superseded", not evidence).
  python tools/method/captures.py required [<scenario> ...]
      The statically required pictures of each scenario: string-literal shot("...") / obs_shot("...")
      calls written at the top level (one tab) of its own t_<scenario>() in PlayTest.gd. A run's
      logged pictures are required too (t3_gate.py final adds them).

t3_gate.py final uses check(): every required picture present, fresh (captured and its file written
after the launch), the file's bytes = the captured ones, no one file standing for two pictures, and a
line in the runner's inspection file (`<scenario>/<tag>: what it shows`).
"""
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(ROOT, "FindingNaresh", "scripts", "dev", "PlayTest.gd")
LIT = re.compile(r'^\t(?:await\s+)?(?:obs_)?shot\(\s*"([^"]+)"')
INSPECT = re.compile(r"^\s*[-*]?\s*`?([a-z0-9_]+/[A-Za-z0-9_]+)`?\s*:\s*(.+?)\s*$")


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def required(scen, src_path=SRC):
    src = open(src_path, encoding="utf-8").read().split("\n")
    out, inside = [], False
    for ln in src:
        if ln.startswith("func "):
            inside = ln.startswith("func t_%s(" % scen)
            continue
        if inside:
            m = LIT.match(ln)
            if m and m.group(1) not in out:
                out.append(m.group(1))
    return out


def inventory(run):
    rows = []
    cap = os.path.join(run, "captures.jsonl")
    if os.path.exists(cap):
        for ln in open(cap, encoding="utf-8", errors="replace"):
            ln = ln.strip()
            if ln:
                try:
                    rows.append(json.loads(ln))
                except ValueError:
                    rows.append({"unparsed": ln})
    lm = os.path.join(run, "launch_mark")
    launch = os.path.getmtime(lm) if os.path.exists(lm) else None
    last = {}
    for i, r in enumerate(rows):
        f = os.path.join(run, "shots", r.get("file", ""))
        r["copied"] = os.path.isfile(f)
        if r["copied"]:
            r["copied_sha256"] = sha(f)
            r["copied_mtime"] = os.path.getmtime(f)
        last[(r.get("scenario", ""), r.get("tag", ""))] = i
    for i, r in enumerate(rows):
        r["superseded"] = last.get((r.get("scenario", ""), r.get("tag", ""))) != i
    inv = {"run": os.path.basename(os.path.normpath(run)), "launch_unix": launch, "rows": rows}
    with open(os.path.join(run, "capture_inventory.json"), "w", encoding="utf-8") as f:
        json.dump(inv, f, indent=1)
    return inv


def inspection(path):
    """-> {"scenario/tag": what it shows} from the runner's inspection file."""
    out = {}
    if path and os.path.exists(path):
        for ln in open(path, encoding="utf-8", errors="replace"):
            m = INSPECT.match(ln)
            if m:
                out[m.group(1)] = m.group(2)
    return out


def check(run, scens, seen_inspect, label, src_path=SRC):
    """-> reasons the run's picture evidence is not acceptable ([] = fine)."""
    why = []
    ip = os.path.join(run, "capture_inventory.json")
    if not os.path.exists(ip):
        return ["%s: no capture inventory (capture_inventory.json)" % label]
    inv = json.load(open(ip, encoding="utf-8"))
    launch = inv.get("launch_unix")
    if not launch:
        return ["%s: the inventory has no launch time" % label]
    if os.path.getmtime(ip) < launch:
        why.append("%s: the capture inventory was written before the launch" % label)
    rows = inv.get("rows", [])
    if any("unparsed" in r for r in rows):
        why.append("%s: unparsed capture rows" % label)
    cur = [r for r in rows if not r.get("superseded") and "unparsed" not in r]
    have = {"%s/%s" % (r.get("scenario"), r.get("tag")): r for r in cur}
    need = []
    for s in scens:
        need += ["%s/%s" % (s, t) for t in required(s, src_path)]
    need += [k for k in have if k.split("/", 1)[0] in scens]
    need = list(dict.fromkeys(need))
    for k in need:
        r = have.get(k)
        if r is None:
            why.append("%s: required picture %s missing (never captured in this run)" % (label, k))
            continue
        if not r.get("copied"):
            why.append("%s: picture %s captured but its file is not in the run's shots" % (label, k))
            continue
        if r.get("copied_sha256") != r.get("sha256"):
            why.append("%s: picture %s: the file's bytes are not the captured ones (stale or replaced)" % (label, k))
        if float(r.get("unix", 0)) < launch or float(r.get("copied_mtime", 0)) < launch:
            why.append("%s: picture %s is older than the launch (stale)" % (label, k))
        if not seen_inspect.get(k) or len(seen_inspect[k]) < 8:
            why.append("%s: picture %s has no inspection line (`%s: what it shows`)" % (label, k, k))
    by_sha = {}
    for k, r in have.items():
        if r.get("sha256"):
            by_sha.setdefault(r["sha256"], []).append(k)
    for h, ks in by_sha.items():
        if len(ks) > 1:
            why.append("%s: one picture file stands for %s (duplicated)" % (label, ks))
    return why


def main(a):
    if a and a[0] == "inventory":
        inv = inventory(a[1])
        cur = [r for r in inv["rows"] if not r.get("superseded")]
        print("capture inventory: %d row(s), %d current, %d copied -> %s" % (len(inv["rows"]), len(cur), sum(1 for r in cur if r.get("copied")), os.path.join(a[1], "capture_inventory.json")))
        return 0
    if a and a[0] == "required":
        for s in a[1:] or ["ghat_heat", "ghat_looks", "ghat_net", "ghat_places", "ghat_jug", "ghat_spring", "ghat_marks"]:
            print("%s: %s" % (s, ", ".join(required(s)) or "-"))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
