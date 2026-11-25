# Step-9 fix: GPT RE-AUDIT after round 2 (2026-11-25)

**Read this file first, before anything else.**

READ-ONLY: everything. You write ONE file: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev\notes\speed_research\step9_reaudit_gpt.md`.
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`, any other thread's files.
Don't run the game (the referee runs one walk now). Python / grep / git reads and the offline controls are fine.
The user is away from this job: never ask; take your recommended option and say what you chose and why.

## You: GPT Astra 6.2, high, strict auditor (the same role as `step9_code_audit_gpt.md`, which you wrote: DON'T SIGN)
Branch `step9` in `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`. Since your audit: the Claude tester's results
(`step9_test_report.md`, PASS WITH RESERVATIONS: bench 5 / 5 gave up incl. hang point 2; prove row `nose` planted FAIL;
clean `ghat_looks` 18 / 18; a fresh recorded walk 20 / 20) and round 2 (`step9_fix2_task.md`, the report's "Round 2" +
"Corrections after audit" sections in `step9_build_report.md`, `git log 5e70d40..step9`, ending `45d946e`).

## Questions
1. Are your four findings closed? (MATRIX owns 28 / 28 and the controls; the integrated clean `ghat_looks` + solo
   proof; the limited guarantee recorded; the timing / fixture corrections.) Re-run your read-only owner check.
2. Round 2's walk change: unique pass names for steps 17 / 18, `tools/live.py` refusing repeated pass / step names
   (exit 7), and step 18's test changed from `coolant > 0.3` to `coolant > 0.99`. Correct? Could `> 0.99` false-fail
   (float, a pour that fills to 0.98, a different pot size)? Does the refusal break any other walk or tool path?
3. Anything in the tester's results that contradicts the fix or that nobody followed up?

## Output: `notes/speed_research/step9_reaudit_gpt.md`
Findings ranked, each with file:line, the failing scenario, the exact change. Verdict line: `SIGN`, `SIGN WITH
RESERVATIONS` (list), or `DON'T SIGN` (what must change). Don't commit; the referee commits it.
