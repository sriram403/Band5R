# Stage 3: RE-AUDIT of the T34 fix round (short). Written by the referee, 2026-11-14. Two auditors: Claude and GPT.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md` (R7, R8, the fix round's entry),
  `trial_T34_fix_build_task.md` (F1-F11), YOUR earlier audit (`audit_T34_claude.md` if you are Claude, `audit_T34_gpt.md` if
  you are GPT), this file
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34`, head `fd4ae18`): the fix-round sections of
  `notes\speed_research\trial_T4_build.md` and `trial_T3_build.md`, `REPLAY_USAGE.md`, `tools\`, the diff
  `git -C D:\mine\Agentics\T3_Code_Works\MPG_speed_t34 diff f208e6e fd4ae18`, run folders under `appdata\`.
- **Claude only** may RUN offline: `python tools/method/t3_controls.py`, `t4_controls.py`, `t4_join_controls.py` (no game).
  GPT runs nothing (the two runs would overwrite each other's fixtures).

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t1` or any other `MPG_*` folder not named above; the skill testing-and-verification §3b.

## Do (strict; no game, no code changes; write only your one file)
For each condition YOUR audit set, and each item F1-F11 that answers it: CLOSED / PARTLY / OPEN, with evidence (code line,
control output, log). A guard counts only if its planted case is refused BY that guard and its clean case passes. Then: is
the tool set fit to start the scored replay under R7 + R8 (fresh takes only; every walk in a new game; D5 = A: run it and
report the overrun)? Name any blocker that would make the replay's result untrustworthy (false PASS, a hole that can't be
seen); a mere cost increase is not a blocker. GPT: also give the replay's projection again from the fix round's numbers.

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\reaudit_T34_claude.md` or `reaudit_T34_gpt.md`: the table, then
GO / GO WITH CONDITIONS (each cheap and named) / NO GO. **Reply:** 5 lines.
