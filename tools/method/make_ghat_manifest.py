"""#6's required-check manifest (the method ported to the ghat, 2026-11-09).

Like make_manifest.py (the ramp's), but a scenario's checks also live in the
helpers it calls: this follows every call from t_<scen> into functions of
PlayTest.gd that start with one of HELPERS (recursively, each once) and lists
every check() there with a stable id (scenario/slug), its regex and line.
A check in a helper used by several scenarios is required in each.
Usage: python tools/method/make_ghat_manifest.py ghat_heat [ghat_looks ...]
       (no names: every #6 scenario) > out.json
       MANIFEST_SRC=<file.gd> : another source (the offline controls' tiny sources)

T3 v2 traversal fix (2026-11-14): the old walk followed only calls of names starting "_" AND with one
of HELPERS' prefixes, each function once. Now: every call of a function DEFINED in the source (any
name; also a bare function name passed as a value, e.g. a callback), cycle-safe (a function already on
the current call path is not re-entered), and every call SITE counts (a helper called from 2 places
gives its checks twice: id, id_2, ...). A check() that can't be parsed, or a dynamic call
(call("..." + x), callv(var), Callable(self, var)) in a traversed function that isn't listed in
DYNAMIC_OK with a reason, stops the manifest (exit != 0): nothing is silently dropped.
"""
import json
import os
import re
import sys

ROOT = __file__.replace("\\", "/").rsplit("/tools/", 1)[0]
SRC = ROOT + "/FindingNaresh/scripts/dev/PlayTest.gd"
FMT = re.compile(r"%[-+ 0#]*[0-9]*(?:\.[0-9]+)?[sdifxXcov]")
CHECK = re.compile(r'\bcheck\((.*),\s*"((?:[^"\\]|\\.)*)"(\s*%.*)?\)\s*$')
CALL = re.compile(r"(?<![\w.])([A-Za-z_][A-Za-z0-9_]*)\s*\(")
VALUE_REF = re.compile(r"(?:[=,(]|\breturn)\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?=[,)]|$)")
DYNAMIC = re.compile(r"(?<![\w])(?:call|callv|call_deferred)\(\s*(?!\))|Callable\(\s*self\s*,\s*(?!\")")
DYNAMIC_OK = {}      # "function": "why its dynamic call can't reach a check" (none needed for the ghat: see the controls)
OLD = os.environ.get("MANIFEST_OLD") == "1"   # the pre-fix traversal (for the diff / controls only)
HELPERS = ("_ghat", "_fix_with", "_hide_well")
STRS = re.compile(r'"(?:[^"\\]|\\.)*"')
OLD_CALL = re.compile(r"\b(_[a-z0-9_]+)\(")
SCENARIOS = ["ghat_heat", "ghat_looks", "ghat_net", "ghat_places", "ghat_jug", "ghat_spring", "ghat_marks"]


PCT = "\x00"     # a literal "%%" in a GDScript format string prints "%"


def slug(text):
    t = FMT.sub("x", text.replace("%%", PCT))
    t = re.sub(r"[^A-Za-z0-9]+", "_", t).strip("_").lower()
    return t[:60]


def regex(text):
    parts = FMT.split(text.replace("%%", PCT))
    return "^" + "(.*?)".join(re.escape(p.replace('\\"', '"').replace("\\'", "'")).replace(PCT, "%") for p in parts) + "$"


def functions(src):
    """name -> (first line index, end index) of every top-level func."""
    out = {}
    starts = [(i, re.match(r"func ([A-Za-z0-9_]+)\(", ln).group(1)) for i, ln in enumerate(src) if re.match(r"func ([A-Za-z0-9_]+)\(", ln)]
    for k, (i, name) in enumerate(starts):
        end = starts[k + 1][0] if k + 1 < len(starts) else len(src)
        out[name] = (i, end)
    return out


def manifest(scen, src, funcs):
    out, seen, visited = [], {}, set()

    def walk(name, path):
        if name not in funcs or name in path:          # not local, or a cycle on this call path
            return
        if OLD and name in visited:
            return
        visited.add(name)
        a, b = funcs[name]
        i = a
        while i < b:
            line = src[i].strip()
            first = i
            # a check spread over lines: join until its brackets close
            if re.search(r"\bcheck\(", line) and not line.startswith("#"):
                while line.count("(") > line.count(")") and i + 1 < b:
                    i += 1
                    line += " " + src[i].strip()
            i += 1
            if line.startswith("#") and not OLD:
                continue
            code = STRS.sub('""', line.split(" #")[0])
            m = CHECK.search(line)
            if m:
                text = m.group(2)
                sid = slug(text)
                seen[sid] = seen.get(sid, 0) + 1
                if seen[sid] > 1:
                    sid = "%s_%d" % (sid, seen[sid])
                out.append({"id": "%s/%s" % (scen, sid), "regex": regex(text), "line": first + 1, "kind": "plain", "in": name})
            elif re.search(r"\bcheck\(", line) and not line.startswith("#"):
                raise SystemExit("unparsed check at line %d: %s" % (first + 1, line))
            if OLD:
                for c in OLD_CALL.findall(line):
                    if c.startswith(HELPERS) and c != name:
                        walk(c, path)
                continue
            if DYNAMIC.search(code) and name not in DYNAMIC_OK and not re.search(r'(?:call|callv)\(\s*""\s*[,)]', code.replace(" ", "")) :
                raise SystemExit("dynamic call at line %d in %s (not in DYNAMIC_OK): %s" % (first + 1, name, line))
            for c in CALL.findall(code) + VALUE_REF.findall(code):
                if c != "check" and c in funcs:
                    walk(c, path | {name})

    walk("t_" + scen, frozenset())
    return out


if __name__ == "__main__":
    src = open(SRC, encoding="utf-8").read().split("\n")
    funcs = functions(src)
    names = sys.argv[1:] or SCENARIOS
    print(json.dumps({n: manifest(n, src, funcs) for n in names}, indent=1))
