"""PreToolUse hook (.claude/settings.json): when a command runs a walk, a test
or a recording, put the matching rules from the testing skill's trigger table
in front of the model (the user, 2026-11-10: a model loaded the skill and
still restarted 10 trial plays from step 1). Silent for every other command.
Reads the hook's JSON on stdin; prints JSON with additionalContext."""
import json
import re
import sys

COMMON = ("Testing triggers (testing-and-verification §0, CLAUDE.md): say this run's cost in minutes; "
          "WATCH it every few seconds (step, movement, errors), off plan -> stop it, look, tell the user; "
          "never only read the end.")
RULES = [
    (r"record_walk\.sh|play_walk\.sh|live\.py\b.*--walk|live_all\.sh",
     "WALK: it RESUMES from the last failed step by default (save points at every step). Use --fresh only "
     "when the cause is before that step or for a final take; never restart from step 1 for a fix after it. "
     "A video shows only the puzzle (no end credits); watch it yourself before sending it with times."),
    (r"method_run\.sh|prove_\w+\.py",
     "METHOD RUN: while fixing, only the changed scenarios; one full run at the milestone. Verdicts: "
     "PASS / FAIL / INCOMPLETE / STALLED / TEST. A new issue gets its own check proved against its planted bug "
     "(core/Plant.gd) + the clean game; add it to the manifest and notes/CHANGE_LEDGER.md."),
    (r"run_test(_headless)?\.sh",
     "TEST: size it to the change (its own scenarios, not the full set); a full run only at a milestone. "
     "Two or three failed fixes on one issue -> a test bench."),
]


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    cmd = str((data.get("tool_input") or {}).get("command", ""))
    hits = [txt for pat, txt in RULES if re.search(pat, cmd)]
    if not hits:
        return 0
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                             "additionalContext": " ".join([COMMON] + hits)}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
