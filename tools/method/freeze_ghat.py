"""Re-freeze #6's required checks into frozen.json (after any check changes).
Usage: python tools/method/freeze_ghat.py"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FZ = os.path.join(HERE, "frozen.json")
WORK = {"ghat_heat": ["seen", "boiled"], "ghat_jug": ["boiled", "gave_up", "fixed", "over_pass"],
        "ghat_spring": ["boiled", "gave_up", "fixed", "over_pass"], "ghat_marks": ["boiled", "gave_up"]}
EVALUATED = {"ghat_heat": ["H1", "H2"], "ghat_jug": ["H1", "H2", "H3"], "ghat_spring": ["H1", "H2", "H3"]}

man = json.loads(subprocess.run([sys.executable, os.path.join(HERE, "make_ghat_manifest.py")], capture_output=True, text=True, check=True).stdout)
fz = json.load(open(FZ, encoding="utf-8"))
for scen, checks in man.items():
    fz["required"][scen] = {"checks": checks, "work": WORK.get(scen, []), "evaluated": EVALUATED.get(scen, [])}
json.dump(fz, open(FZ, "w", encoding="utf-8", newline=""), indent=1)
print({k: len(v) for k, v in man.items()}, "total", sum(len(v) for v in man.values()))
