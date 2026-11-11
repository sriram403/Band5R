# Compliance audit: the speed-research referee thread (2026-11-10 22:10 -> 2026-11-11 10:47). Written by the referee.

Method: `D:\mine\Agentics\Skills\skills\project-memory\SKILL.md` §6 (read it first). You are a fresh auditor:
you did not do this work. Mark every rule **FOLLOWED / BROKEN / N.A. / NOT SHOWN** (no evidence = NOT SHOWN,
never "followed"), with evidence (a quote from the transcript, a file, a commit, a count), and the cost of
each broken rule in the scarce units (the user's real time; game minutes; build hours wasted or at risk).

## Read ONLY these
- The rules: `D:\mine\Agentics\T3_Code_Works\MPG\CLAUDE.md`; `C:\Users\srira\.claude-work\CLAUDE.md` (read only).
- The skills the referee was told to load (each one's §0 trigger table + the sections it points to):
  `D:\mine\Agentics\Skills\skills\{two-model-research, testing-and-verification, project-memory,
  first-principles-solving, game-dev}\SKILL.md`, and `D:\mine\Agentics\Skills\AGENTS.md`.
- The evidence: `D:\mine\Agentics\T3_Code_Works\MPG\notes\audits\evidence_speed_referee\transcript_cut.md`
  (the thread's record, its first block is the user's task; cut just before the user raised a problem;
  some blocks are redacted: secret benchmark material, not yours to see). Files as they were at the cut:
  `git -C D:\mine\Agentics\T3_Code_Works\MPG show 55a5fa1:<path>` for `notes/speed_research/*` (scoreboard,
  task files, specs), `notes/SPEED_RESEARCH.md`, `notes/TODO.md` (the "Right now" top item only), and
  `git log --stat 40e1f16..55a5fa1`. The trial copies' commits: `git -C D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 log --stat -3`.

## DO NOT READ
`D:\mine\Agentics\T3_Code_Works\MPG_referee` (the secret list); anything about the game's bugs or holes;
`MPG_dev`, other copies' files; anything after commit `55a5fa1`. Don't write any game detail in your report.
No game runs, no code, no other files changed: write one file.

## Pay special attention to (check, don't assume)
- two-model-research §1.4 and §0: was every spec / result from one model audited by the other before it was
  built on or counted? Were children briefed as the skill says?
- the user's task list for this thread (the first block): which items were done, skipped, or changed without saying so.
- project-memory triggers (notes current, mistake log at once, time report at milestones), first-principles
  (limits tested before assumed, e.g. running children in parallel), testing (cost before each run, watching runs).
- what the tools already offered vs how they were used.

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\audits\audit_speed_referee_gpt.md`: the table (rule, verdict, evidence,
cost), the top 3 by cost, and for each BROKEN rule one fix that makes it hard to break again (prefer a tool
default, a check or a hook over a reminder). **Reply:** 6 lines: counts per verdict, the top 3, the fixes.
