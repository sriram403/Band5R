"""The final method: the required-check manifest for a watched scenario (M9).

Reads the scenario's source (t_<name> in FindingNaresh/scripts/dev/PlayTest.gd)
and lists every check() call with a stable semantic ID (a slug of its literal
words, format fields replaced by "x"), a regex the logged text must match, the
source line, and its kind:
  plain      a failed check is FAIL, owner UNRESOLVED
  jump       the scheduled landing (M11): a failure is INCOMPLETE, owner UNRESOLVED
  departure  the drive-off receipt (M10 "checks"): a failure is INCOMPLETE
Declared from the source before any run; clean runs verify it (they never
define it). Usage: python tools/method/make_manifest.py ramp > manifest.json
"""
import json
import re
import sys

ROOT = __file__.replace("\\", "/").rsplit("/tools/", 1)[0]
SRC = ROOT + "/FindingNaresh/scripts/dev/PlayTest.gd"
FMT = re.compile(r"%[-+ 0#]*[0-9]*(?:\.[0-9]+)?[sdifxXcov]")
CHECK = re.compile(r'\bcheck\((.*),\s*"((?:[^"\\]|\\.)*)"(\s*%.*)?\)\s*$')
JUMP = ["flat out the van makes it"]
DEPARTURE = ["and drives off", "and gets back to the road"]


def slug(text):
    t = FMT.sub("x", text)
    t = re.sub(r"[^A-Za-z0-9]+", "_", t).strip("_").lower()
    return t[:60]


def regex(text):
    parts = FMT.split(text)
    return "^" + "(.*?)".join(re.escape(p.replace('\\"', '"').replace("\\'", "'")) for p in parts) + "$"


def manifest(scen):
    src = open(SRC, encoding="utf-8").read().split("\n")
    a = src.index("func t_%s() -> void:" % scen)
    b = next(i for i in range(a + 1, len(src)) if src[i].startswith("func "))
    out, seen = [], {}
    for i in range(a, b):
        m = CHECK.search(src[i].strip())
        if not m:
            if re.search(r"\bcheck\(", src[i]):
                raise SystemExit("unparsed check at line %d: %s" % (i + 1, src[i].strip()))
            continue
        text = m.group(2)
        sid = slug(text)
        seen[sid] = seen.get(sid, 0) + 1
        if seen[sid] > 1:
            sid = "%s_%d" % (sid, seen[sid])
        kind = "jump" if any(text.startswith(j) for j in JUMP) else ("departure" if any(text.startswith(d) for d in DEPARTURE) else "plain")
        out.append({"id": "%s/%s" % (scen, sid), "regex": regex(text), "line": i + 1, "kind": kind})
    return out


if __name__ == "__main__":
    print(json.dumps(manifest(sys.argv[1] if len(sys.argv) > 1 else "ramp"), indent=1))
