# Step-9 fix, round 2: the audit's and the tester's findings (2026-11-25)

AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/step9_code_audit_gpt.md
AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/held5_results_audit_gpt.md

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`.
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`, any other thread's files.

The user is away from this job (they're going back to game dev): never ask; take your recommended option and write
what you chose and why in one simple sentence.

FIRST: load these skills (Skill tool, by name) before any other work: testing-and-verification, project-memory.

## You: a fresh Claude Opus 5.5, high, builder. Referee: the main thread. Re-audit after you: GPT Astra 6.2.

Folder `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`, branch **`step9`** (checked out). Commit after each item.
No merge, no push. **Budget: ~6 game minutes** (item 3's check only). Read first: `notes/speed_research/step9_build_report.md`,
`step9_code_audit_gpt.md` (GPT, DON'T SIGN), `step9_test_report.md` (the tester, PASS WITH RESERVATIONS).

## Items
1. **Blocking (GPT finding 1):** register the prove row `nose` in `tools/method/prove_ghat.py` `MATRIX` (beside
   `round`), update the inventory control in `tools/method/t3_controls.py` (~line 510) from 27 to 28, and run the
   matrix / inventory controls (`python tools/method/t3_controls.py` or the subset GPT names) + any control suite that
   reads MATRIX (`rv1_controls.py`, `autoq_controls.py` if they do). Show the gate now owns 28 of 28 plants (the same
   read-only check GPT ran: the gate's plant discovery vs MATRIX owners). Each control result in the report.
2. **Report corrections (GPT findings 3-4):** in `step9_build_report.md` add a short "Corrections after audit" section:
   the waypoint was dropped at **23.25 s** (still VAN; B2 log line 23), WANDER took over at 24.37 s; the nose check is a
   **reduced fixture** (position / stop / waypoint only, not velocities or orbit) and the B1 restore is the real-state
   evidence; the **limited guarantee**: the 11-sample line test can miss a grazing corner (GPT's example) and there is no
   general progress guarantee: no code change unless a new jam is seen; then an exact segment / box test. Also note the
   planted side's 3 follow-on failures (tarp give-up, slump, eyes dim) seen in the tester's proof (a stuck creature
   carries into later checks). Same lines in `notes/CHANGE_LEDGER.md`'s step-9 entry where they change what it claims.
3. **Walk gap (tester's finding, older than the fix; the rule "fix what you see" + "every issue gets a check"):** ghat
   walk steps 17 / 18 reuse the pass names of steps 14 / 16, and the walk driver skips a pass name already passed, so 17
   / 18 are never really checked. Find where (`tools/live/make_ghat.py` / `tools/live/ghat.json` / `tools/live.py`).
   Recommended fix: unique pass names for 17 / 18 (e.g. "... again"), regenerate `ghat.json` the project's way; better
   still, make the walk tool REFUSE a walk whose pass names repeat (a quick offline check, no game) and show it refusing
   the old file and accepting the new one. Don't run a whole walk for this (budget); a dry / offline check is enough.
   Note in the report: this changes the walk file, so the held branch will need a fresh producer (already planned).
4. **Not to fix, note only:** the bench trips the H2 heat rule right after loading a save (bench only, not in the walk
   or `ghat_looks`); the window took focus 1.8 s during step 9.

## Rules
Patch files with Edit / Write; never `sed -i`, never Python through a Bash heredoc with escapes, never `>>` / `printf >`
into tracked files. Parse-check / run the controls before commits. Nothing on C:. Mistakes the moment they happen into
`notes/ROUGH_NOTES.md` "Assumed -> reality -> fix". Every run counted, expected outcome declared before it.

## Report: append "Round 2" to `notes/speed_research/step9_build_report.md`
What changed (files, lines), each control's result, the refuse / accept demo for item 3, game minutes. Last line: the
commit hash.
