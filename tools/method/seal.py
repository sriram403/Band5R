"""F9 (fix round): acceptance runs refuse test-only flags.

  python tools/method/seal.py <role> [<receipt.json>]
      role: final | proof | record (the acceptance runs: ROLE=final / ROLE=proof method runs, the recorded walk).
      Exit 0 and (with a receipt path) write {"role", "sealed": true, "checked": [...]} when none of the
      test-only flags below is set; exit 3 and write "sealed": false with the flags found otherwise.
      Any other role (discovery, repair, diag, ...) is not sealed: exit 0, receipt "sealed": false, "role" kept.
t3_gate.py final / proof refuse a run whose invocation has no sealed receipt (seal.json).

Test-only flags (each read by a tool for a control or a diagnosis; never in an acceptance run):
  GATE_PROBE GATE_L2_CONTINUE GATE_NOABORT GATE_PERTURB GATE_RESUMES   resume gate controls / D3 override
  JOIN_GATE_WAIVED                                                     the join mechanics control
  WALK_FAIL_AT NO_MAKE                                                 a forced walk failure / a hand-edited walk
  GUARD_INJECT T1_LAG MANIFEST_OLD MANIFEST_SRC EXPECT_FAIL            guard / deadline / manifest controls
  FAST_OK_OVERRIDE FAST                                                speed routing overrides
  SPEED other than "" or "fast" (SPEED=_fast / _1x are one part's internal setting) for final / proof
"""
import json
import os
import sys

FLAGS = ("GATE_PROBE", "GATE_L2_CONTINUE", "GATE_NOABORT", "GATE_PERTURB", "GATE_RESUMES", "JOIN_GATE_WAIVED",
         "WALK_FAIL_AT", "NO_MAKE", "GUARD_INJECT", "T1_LAG", "MANIFEST_OLD", "MANIFEST_SRC", "EXPECT_FAIL",
         "FAST_OK_OVERRIDE", "FAST")
ACCEPTANCE = ("final", "proof", "record")


def found(role, env=None):
    env = os.environ if env is None else env
    bad = ["%s=%s" % (k, env[k]) for k in FLAGS if env.get(k, "") != ""]
    if role in ("final", "proof") and env.get("SPEED", "") not in ("", "fast"):
        bad.append("SPEED=%s (only '' or 'fast' for an acceptance run)" % env.get("SPEED"))
    return bad


def seal(role, receipt=None, env=None):
    bad = found(role, env) if role in ACCEPTANCE else []
    rec = {"role": role, "sealed": role in ACCEPTANCE and not bad, "checked": list(FLAGS) + ["SPEED"], "found": bad}
    if receipt:
        os.makedirs(os.path.dirname(os.path.abspath(receipt)), exist_ok=True)
        with open(receipt, "w", encoding="utf-8") as f:
            json.dump(rec, f, indent=1)
    return bad


def main(a):
    role = a[0] if a else ""
    bad = seal(role, a[1] if len(a) > 1 else None)
    if bad:
        print("REFUSED: an acceptance run (%s) with test-only flags set: %s (unset them; they are for controls only)" % (role, ", ".join(bad)))
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
