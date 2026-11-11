"""PreToolUse hook on delegate_task (.claude/settings.json), the user, 2026-11-11.
Why: the referee loaded two-model-research ("the other auditor audits each result before it counts")
and still sent GPT's specs straight to a builder; the user caught it. A rule only in a skill is
forgotten at the moment it applies, so this hook (1) puts the hand-off rules in front of the model at
every delegate_task, and (2) BLOCKS a build hand-off whose task file has no `AUDITED:` line naming an
existing audit file written by the other model.
Build hand-off = the task names a `*build*_task.md` file. The task file must contain a line
`AUDITED: <path to the other model's audit>` (and, if the audit asked for changes, the answer:
`ANSWERED: <path>` is optional, shown when present). Reads the hook JSON on stdin; prints JSON."""
import json
import os
import re
import sys

RULES = ("Hand-off rules (two-model-research §0-2, CLAUDE.md): the child's task FILE starts with its "
         "READ-ONLY / DO-NOT-READ lists and is read first; every spec, plan or result from one model is "
         "AUDITED BY THE OTHER MODEL before anyone builds on it or it counts; GPT writes no game code and runs "
         "no game; one Claude child at a time on the critical path (rate limit, 2026-11-11); a budget in "
         "game minutes + a meter Monitor for every copy that runs games; nothing on C:.")


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    task = str((data.get("tool_input") or {}).get("task", ""))
    out = {"hookEventName": "PreToolUse", "additionalContext": RULES}
    for path in re.findall(r"[A-Za-z]:[\\/][^\s\"'`]*?build[^\s\"'`]*?_task\.md", task):
        p = path.replace("\\", "/")
        if not os.path.isfile(p):
            continue
        text = open(p, encoding="utf-8").read()
        m = re.search(r"^AUDITED:\s*(\S+)", text, re.M)
        audit = m.group(1).replace("\\", "/") if m else ""
        if not m or not os.path.isfile(audit):
            out["permissionDecision"] = "deny"
            out["permissionDecisionReason"] = (
                "BLOCKED by tools/hooks/handoff_gate.py: %s is a build hand-off with no `AUDITED: <file>` line "
                "naming an existing audit by the OTHER model (%s). Get the spec audited first (two-model-research "
                "§1.4), answer the audit, then add the line." % (p, "line missing" if not m else "file not found: " + audit))
            break
    print(json.dumps({"hookSpecificOutput": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
