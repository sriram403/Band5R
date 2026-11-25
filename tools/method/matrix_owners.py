"""Read-only: the gate's plant discovery (t3_gate.plant_rows, from the game's Plant.on calls) vs the plants
prove_ghat.MATRIX owns. Prints both counts and every plant with no owner / every owner with no plant.
Exit 0 only when they match one to one. (GPT's step-9 audit check, kept as a tool, 2026-11-25.)
  python tools/method/matrix_owners.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prove_ghat  # noqa: E402
import t3_gate  # noqa: E402

found = t3_gate.plant_rows()
owners = {}
for g in prove_ghat.MATRIX:
    for pl in prove_ghat.GROUPS[g][2]:
        owners.setdefault(pl, []).append(g)
missing = [p for p in found if p not in owners]
orphans = sorted(p for p in owners if p not in found)
twice = sorted(p for p, gs in owners.items() if len(gs) > 1)
print("discovered %d plants, MATRIX owns %d (%d rows)" % (len(found), sum(1 for p in found if p in owners), len(prove_ghat.MATRIX)))
print("no owner: %s" % (", ".join(missing) or "none"))
print("owned but not in the game: %s" % (", ".join(orphans) or "none"))
print("owned twice: %s" % (", ".join(twice) or "none"))
print("nose -> %s" % owners.get("stale_via"))
sys.exit(0 if not missing and not orphans and not twice else 1)
