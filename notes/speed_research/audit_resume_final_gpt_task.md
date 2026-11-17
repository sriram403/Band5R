# Task: audit the resume-fix FINAL result (GPT, strict auditor)

**Read-only:** everything except your one output file. **Do not:** write or edit code, run the game / Godot / any walk,
commit, push. **Do not read:** `D:\mine\Agentics\T3_Code_Works\MPG_referee\`.
**Write exactly one file:** `D:\mine\Agentics\T3_Code_Works\MPG_dev\notes\speed_research\audit_resume_final_gpt.md`.

You audited the design (`audit_resume_fix_gpt.md`) and the interim results (`audit_resume_results_gpt.md`, CHANGE FIRST).
Claude says it took every change and ran the proof: read `notes/speed_research/resume_fix_result.md`, the commits
`git log --oneline acb86a5..resume` (diffs), the chain transcript `appdata/resume_chain.log` and `appdata/resume_*.out`
(F3, R1b, R2b, X1, X2, REP), the receipts `appdata/playtest/FindingNaresh/live/points/<run>/13.gate.json` and the
observations / t3 samples named in the result file, and `tools/method/rv1_controls.py` (run it if you like: offline, no game).

Write (strict; evidence = file + number, or "I think"; under ~80 lines):
1. Were your CHANGE FIRST items each done as asked (one line each, with the file:line)?
2. Do the receipts and transcripts support "point 13 qualified SAME" under the ORIGINAL bounds, and X1 / X2 DIFFERENT for
   their own named reason? Any false-SAME path left in what ran?
3. Is the saving stated honestly (an estimate, one sample)? Is anything over-claimed?
4. Verdict: SIGN / SIGN WITH RESERVATIONS (list) / DON'T SIGN (why), and whether the branch is fit to merge into main
   (tools + test code only; the user decides).
