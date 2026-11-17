"""Input identity (speed research T3 v2 "small input identity helper", reused by T4 v2's points).

One content hash of the working tree's inputs, taken through a TEMPORARY git index on D: (read from
HEAD with no stat data, so every input file is hashed; the real index is never written), plus the Godot
binary's hash. Dirty and untracked bytes count (git add -A into the temp index); HEAD alone does not.

Groups (sha256 over the sorted "mode blob path" lines of the temp index):
  game   FindingNaresh/ minus scripts/dev/ (the game: scripts, scenes, assets, core/Plant.gd)
  test   FindingNaresh/scripts/dev/ + tools/live/ (what PRODUCES a walk's actions: game-side test code, walks
         and their generators). A point / gate evidence needs the same game + test + bin.
  tools  tools/ minus tools/live/ (judges, wrappers, the client: recorded with every point and run, not
         required equal for a resume: they don't change what the game does)
  full   everything below (game + test + the rest of the repo's inputs)
  bin    sha256 of tools/godot/Godot_*.exe (ignored by git, so hashed directly)

EXCLUDED, outputs only (each written by a run, read by no tool as an input):
  appdata/                       every run's data, logs, points, videos, temp
  FindingNaresh/.godot/          the import cache (regenerated from the inputs)
  FindingNaresh/_shots*/         pictures a run takes
  tools/_last_playtest.log, tools/_gym_playtest.log, tools/_headless_data/, tools/godot/editor_data/
  notes/                         reports written during the work (no game or tool reads notes/: checked
                                 by grep 2026-11-11, see trial_T3_build.md)
INCLUDED although ignored by git: the Godot binaries (bin). Generated inputs that ARE tracked or
untracked-not-ignored (tools/live/<walk>.json, a manifest written into tools/) are in `test`.

Usage:
  python tools/method/tree_id.py                 -> JSON {game, test, full, bin, head, files}
  python tools/method/tree_id.py stamp <file>    -> write that JSON to <file>
  python tools/method/tree_id.py same <a> <b> [keys]   -> exit 0 if the keys (default full,bin) match, else 1
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
EXCLUDE = ("appdata/", "FindingNaresh/.godot/", "tools/_last_playtest.log", "tools/_gym_playtest.log",
           "tools/_headless_data/", "tools/godot/editor_data/", "notes/")
EXCLUDE_PREFIX_GLOB = ("FindingNaresh/_shots",)


def _git(args, env=None, root=ROOT, check=True):
    return subprocess.run(["git"] + args, cwd=root, env=env, capture_output=True, text=True, encoding="utf-8",
                          errors="replace", check=check).stdout


def excluded(path):
    return path.startswith(EXCLUDE) or path.startswith(EXCLUDE_PREFIX_GLOB)


def index_lines(root=ROOT):
    """The temp index's 'mode blob path' lines for every input file (dirty + untracked included)."""
    real = _git(["rev-parse", "--git-path", "index"], root=root).strip()
    if not os.path.isabs(real):
        real = os.path.join(root, real)
    tmpd = os.path.join(root, "appdata", "tmp")
    os.makedirs(tmpd, exist_ok=True)
    tmp = os.path.join(tmpd, "tree_id_index_%d" % os.getpid())
    # a FRESH temp index from HEAD (no stat data): `git add -A` then hashes every input file. A copy of the real
    # index let git's stat cache call a same-size edit made in the same second unchanged (1 in 10 control runs,
    # merge 2026-11-17; t3_controls "ident same-size edit, mtime restored"). Full hash of this repo: ~1.5 s.
    env = dict(os.environ, GIT_INDEX_FILE=tmp)
    if os.path.exists(tmp):
        os.remove(tmp)
    if real and _git(["rev-parse", "--verify", "-q", "HEAD"], root=root, check=False).strip():
        _git(["read-tree", "HEAD"], env=env, root=root)
    try:
        _git(["add", "-A", "--", ".", ":(exclude)notes"], env=env, root=root)
        out = _git(["ls-files", "-s"], env=env, root=root)
    finally:
        for p in (tmp, tmp + ".lock"):
            if os.path.exists(p):
                os.remove(p)
    lines = []
    for ln in out.splitlines():
        meta, path = ln.split("\t", 1)
        mode, blob, _stage = meta.split()
        if excluded(path):
            continue
        lines.append((path, mode, blob))
    lines.sort()
    return lines


def _h(lines):
    h = hashlib.sha256()
    for path, mode, blob in lines:
        h.update(("%s %s %s\n" % (mode, blob, path)).encode("utf-8"))
    return h.hexdigest()[:16]


def bin_hash(root=ROOT):
    h = hashlib.sha256()
    gd = os.path.join(root, "tools", "godot")
    names = sorted(n for n in os.listdir(gd) if n.lower().startswith("godot") and n.lower().endswith(".exe")) if os.path.isdir(gd) else []
    for n in names:
        h.update(n.encode())
        with open(os.path.join(gd, n), "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
    return h.hexdigest()[:16] if names else "none"


def identity(root=ROOT):
    lines = index_lines(root)
    game = [x for x in lines if x[0].startswith("FindingNaresh/") and not x[0].startswith("FindingNaresh/scripts/dev/")]
    test = [x for x in lines if x[0].startswith("FindingNaresh/scripts/dev/") or x[0].startswith("tools/live/")]
    tools = [x for x in lines if x[0].startswith("tools/") and not x[0].startswith("tools/live/")]
    # resume fix v1: the test CODE alone (no walk files): a REPAIR may change a walk's actions, never this
    testcode = [x for x in lines if x[0].startswith("FindingNaresh/scripts/dev/")]
    return {"game": _h(game), "test": _h(test), "testcode": _h(testcode), "tools": _h(tools), "full": _h(lines), "bin": bin_hash(root),
            "head": _git(["rev-parse", "HEAD"], root=root).strip(), "files": len(lines)}


def file_hash(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def main(argv):
    if argv and argv[0] == "stamp":
        d = identity()
        with open(argv[1], "w", encoding="utf-8") as f:
            json.dump(d, f)
        print(json.dumps(d))
        return 0
    if argv and argv[0] == "same":
        a, b = (json.load(open(p, encoding="utf-8")) for p in argv[1:3])
        keys = argv[3].split(",") if len(argv) > 3 else ["full", "bin"]
        bad = [k for k in keys if a.get(k) != b.get(k) or a.get(k) in (None, "")]
        print("SAME" if not bad else "DIFFERENT: " + ", ".join("%s %s != %s" % (k, a.get(k), b.get(k)) for k in bad))
        return 0 if not bad else 1
    print(json.dumps(identity()))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
