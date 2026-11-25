# Step-9 fix, round 3: GPT re-audit's reservations 1 + 3 (2026-11-25)

AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/step9_reaudit_gpt.md
AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/step9_code_audit_gpt.md

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`; inside it, don't touch `FindingNaresh/**`
(game code), `tools/live/**`, `tools/live.py`, `tools/play_walk.sh` (the referee is running a walk on them right now).
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`, other threads' files.
Never ask; take your recommended option and say what you chose and why in one simple sentence.
FIRST: load the skills testing-and-verification and project-memory (Skill tool, by name).

## You: a fresh Claude Opus 5.5, high, builder. Branch `step9` in `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`.
No game runs (0 game min). Commit after each item; no merge, no push. Don't start a game; one is running.

1. **GPT reservation 1:** the new offline control (`tools/method/t3_controls.py` ~line 589 and ~627-635) reads two
   files from run R7 under the git-ignored `appdata/` and needs the historical commit `5e70d40`, so it fails in a clean
   checkout. Copy what it needs into a small TRACKED fixture (e.g. `tools/method/fixtures/step9_walknames.json`: the
   old ghat definition's duplicate-name example + the two observed coolant values 0.6750000000000003 and 1.0, with the
   R7 run and point ids as provenance) and make the default control use it. Show it passing, and failing with the guard
   off (as round 2 did). Run the whole `t3_controls.py` suite + `rv1_controls.py` + `autoq_controls.py`; results in the report.
2. **GPT reservation 3:** `notes/speed_research/step9_test_report.md`: list R2 AND R3 as below the prediction (~line
   46); `step9_build_report.md` ~line 115: replace the general 57-72 s with the measured give-up range (~44-69 s game
   time on the bench, set by the van urge left) and say it is the give-up time, not the whole walk step (+ the 4 s wait).

## Report: append "Round 3" to `notes/speed_research/step9_build_report.md` (files, lines, control results). Last line:
the commit hash.
