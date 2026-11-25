"""Builds tools/method/fixtures/step9_walknames.json, the tracked evidence for t3_controls.py `walknames`
(step-9 round 3, GPT re-audit reservation 1, 2026-11-25): the control used to read the historical commit 5e70d40
and run R7's save points under the git-ignored appdata/, so it failed in a clean checkout.

  python tools/method/fixtures/make_step9_walknames.py          # (re)write the fixture from the sources
  python tools/method/fixtures/make_step9_walknames.py --check  # sources still match the fixture? exit 1 if not

Sources (needed only to build or --check, never by the control):
  git 5e70d40:tools/live/ghat.json   the ghat walk before the fix (steps 17 / 18 reused 14's and 16's pass names)
  appdata/playtest/FindingNaresh/live/points/ghat_20261125_143834_19960/{17,18}.json
                                     R7 (the tester's fresh recorded walk): point 17 = step 18's start (one pot
                                     poured), point 18 = step 19's start (two pots); camper.coolant at each."""
import hashlib, json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(HERE, "step9_walknames.json")
COMMIT, WALK = "5e70d40", "tools/live/ghat.json"
RUN = "ghat_20261125_143834_19960"
PTS = os.path.join(ROOT, "appdata", "playtest", "FindingNaresh", "live", "points", RUN)


def build():
    src = subprocess.run(["git", "-C", ROOT, "show", "%s:%s" % (COMMIT, WALK)], capture_output=True, text=True,
                         encoding="utf-8")
    if src.returncode != 0:
        sys.exit("old walk unreadable: " + src.stderr.strip())
    coolant = {}
    for i in (17, 18):
        p = os.path.join(PTS, "%d.json" % i)
        raw = open(p, "rb").read()
        coolant[str(i)] = {"value": json.loads(raw)["camper"]["coolant"],
                           "point": "appdata/playtest/FindingNaresh/live/points/%s/%d.json" % (RUN, i),
                           "sha256": hashlib.sha256(raw).hexdigest()}
    return {"what": "step-9 walknames control evidence (see make_step9_walknames.py)",
            "old_walk_source": {"commit": COMMIT, "path": WALK,
                                "sha256": hashlib.sha256(src.stdout.encode("utf-8")).hexdigest()},
            "old_walk": json.loads(src.stdout),
            "coolant_run": RUN,
            "coolant_note": "17 = step 18's start (after one pot), 18 = step 19's start (after two)",
            "coolant": coolant}


def main(a):
    new = build()
    if "--check" in a:
        old = json.load(open(OUT, encoding="utf-8"))
        same = old == new
        print("fixture matches its sources" if same else "fixture DIFFERS from its sources")
        return 0 if same else 1
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(new, f, indent=1, sort_keys=True)
        f.write("\n")
    print("wrote", OUT, {k: v["value"] for k, v in new["coolant"].items()})
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
