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
F10 (fix round): also followed: self.<local>(...) and self.<local> as a value, and the literal target of
call("<local>") / callv("<local>", ...) / call_deferred("<local>") / Callable(self, "<local>") (bare or on
self; obj.call("x") is another object's and is not followed). A variable target stays refused.
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
SELF_REF = re.compile(r"\bself\.([A-Za-z_][A-Za-z0-9_]*)")
LIT_CALL = re.compile(r'(?<![\w.])(?:self\.)?(?:call|callv|call_deferred)\(\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*[,)]')
LIT_CALLABLE = re.compile(r'\bCallable\(\s*self\s*,\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*\)')
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
            # F10: a call with a literal local target is followed below, not "dynamic": judge what is left
            dyn = STRS.sub('""', LIT_CALLABLE.sub("", LIT_CALL.sub("", line.split(" #")[0])))
            if DYNAMIC.search(dyn) and name not in DYNAMIC_OK:
                raise SystemExit("dynamic call at line %d in %s (not in DYNAMIC_OK): %s" % (first + 1, name, line))
            # F10 (fix round): also self.<local>(...) / self.<local> as a value, and a literal target of
            # call("<local>") / callv("<local>", ...) / call_deferred("<local>") / Callable(self, "<local>")
            # (bare or on self only: obj.call("x") is another object's). Dynamic targets stay refused above.
            raw = line.split(" #")[0]
            for c in CALL.findall(code) + VALUE_REF.findall(code) + SELF_REF.findall(code) + LIT_CALL.findall(raw) + LIT_CALLABLE.findall(raw):
                if c != "check" and c in funcs:
                    walk(c, path | {name})

    walk("t_" + scen, frozenset())
    return out


if __name__ == "__main__":
    src = open(os.environ.get("MANIFEST_SRC", SRC), encoding="utf-8").read().split("\n")
    funcs = functions(src)
    names = sys.argv[1:] or SCENARIOS
    print(json.dumps({n: manifest(n, src, funcs) for n in names}, indent=1))
