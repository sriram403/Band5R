# Step-9 fix: GPT CODE AUDIT (2026-11-25)

**Read this file first, before anything else.**

READ-ONLY: everything. You write ONE file: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev\notes\speed_research\step9_code_audit_gpt.md`.
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`,
`dev\notes\speed_research\step9_gpt_test_*` (another child's work; stay blind to it), any other thread's files.
Don't run the game (another child is testing it; one game at a time). Python / grep / git reads are fine.

The user is away: never ask; take your recommended option and say what you chose and why.

FIRST: load these skills (by name, from `D:\mine\Agentics\Skills\skills\<name>\SKILL.md`): testing-and-verification,
game-dev (+ `references\godot.md` "Physics and 3D"), first-principles-solving.

## You: GPT Astra 6.2, high, a strict, fresh auditor
A Claude builder fixed a game hang (ghat walk step 9: the creature Problem sometimes never gives up; it presses on the
van's nose for good). Assume the fix is wrong until the code shows otherwise.

Read: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev` branch `step9`: `notes/speed_research/step9_build_report.md`,
`step9_build_task.md`, the diff `git diff main..step9 -- FindingNaresh tools` (commits `15d5cfe`, `db70d9c`, `043d5cc`),
`FindingNaresh/scripts/world/Ghat.gd` (`_round_waypoint`, `_crosses_van`, `_walk_round`), `scripts/creatures/Creature.gd`
(`_unstick`, `van_interest`, `_van_memory`), `scripts/core/Plant.gd`, the new check in `PlayTest.gd` and its bench scenario,
`tools/method/prove_ghat.py`, `tools/method/frozen.json`, `notes/CHANGE_LEDGER.md`. Project rules: `CLAUDE.md`.

## Questions
1. **Cause:** does the code really allow the stated cause (a held waypoint `_via_k` whose line crosses the van, never
   re-checked)? Is anything else in the report's evidence unexplained?
2. **Fix:** is it correct and complete? Other ways the round can still dead-end (an unstick hop, the net, a ring point
   inside / touching the van's box, the 11-sample line test missing a corner, back-and-forth flipping between two
   waypoints, the van moved / rotated)? Does it change how a normal round plays (timings, stops, poses, breath windows)?
3. **Plant + check:** does the plant `stale_via` put back exactly the old behaviour? Can the check `_ghat_round_nose`
   FAIL on the bug and PASS clean for the right reason (not a timeout, not a set-up that dodges the bug)? Is the
   declared setup the real hand-over state? Is the manifest change (`frozen.json`, prove row `nose`) right and only that?
4. **Plain bug or design choice?** The builder called it a plain bug. Agree?
5. **Risk:** what could this break elsewhere (`ghat_looks` order / timing: its tarp give-up check now starts from stop 5,
   other creatures, resume save points that hold `_via_k`)?

## Output: `notes/speed_research/step9_code_audit_gpt.md`
Findings ranked most severe first, each with file:line, the concrete failing scenario, and the exact change you'd make.
Then a verdict line: `SIGN`, `SIGN WITH RESERVATIONS` (list), or `DON'T SIGN` (what must change). Don't commit; the
referee commits it.
