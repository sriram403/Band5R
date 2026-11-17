# Task: re-check the resume fix after your final audit (GPT, strict auditor)

**Read-only:** everything except your one output file. **Do not:** write or edit code, run the game / Godot / any walk,
commit, push, run scripts that write files (rv1_controls.py rewrites appdata/rv1ctl/work: read its output in
`git log` / the commit message, or run it only if you accept that one folder being rewritten). **Do not read:**
`D:\mine\Agentics\T3_Code_Works\MPG_referee\`.
**Write exactly one file:** `D:\mine\Agentics\T3_Code_Works\MPG_dev\notes\speed_research\audit_resume_recheck_gpt.md`.

Your final audit (`notes/speed_research/audit_resume_final_gpt.md`) said DON'T SIGN for merge: record validation still
admitted an unknown frames kind, a deleted Problem child pose, a NaN seed; claims too strong. Claude's answer is commit
`eb3dd5c` (diff `git show eb3dd5c`), the rejudged evidence `appdata/resume_rejudged_v2.json`, and the corrected
`notes/speed_research/resume_fix_result.md`. Check, under ~50 lines, with evidence: (1) each of your blockers closed
(file:line, and your own in-memory reproduction if you like); (2) any new hole the fix opened; (3) verdict for merging
branch `resume` into main (tools + test code + notes; the user decides): SIGN / SIGN WITH RESERVATIONS (list) / DON'T SIGN.
