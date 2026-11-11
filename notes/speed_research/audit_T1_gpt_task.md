# Stage 3: GPT audits T1 + T2's result (before it counts). Written by the referee, 2026-11-11.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md`; `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`:
  `scoreboard.md`, `top4.md`, `trial_T1_task.md` (with its RESUME and your own two points), `trial_T3_spec.md` (yours), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1` (branch `speed-t1`): `notes\speed_research\trial_T1.md` and the
  pilots; the code diff `git -C D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 diff 2e524f2 5f468c2`; the run evidence in
  `appdata\t1\` and `appdata\method\runs\2026111*` (verdicts, traces, `[speed]` / `[nodraw]` lines, shots).

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`,
`MPG_speed_base`, `MPG_speed_t34` or any other `MPG_*` folder; other branches or commits (only `speed-t1`'s own
history); the skill testing-and-verification §3b. Opened one by mistake: stop and say so.

## Your role
The GPT auditor, strict (evidence or "I think"). Read-only: **no game runs, no code, one output file.**
T1 claims "QUALIFIED: 6 scenarios fast + nodraw; the suite 4.4 vs 18.7 min; 8 / 9 plants same check id".
Try to break that claim: could a fast run PASS where 1x would FAIL (a deadline still on the wall clock, `el_ms`
= max(game, wall), the nodraw re-arm, pictures taken from a stale frame, two lanes in one copy sharing a file,
early stop declaring a plant before every expected FAIL is on record, batched plants hiding each other)? Is
119 / 119 enough evidence (how many runs, which tolerances)? Check its numbers against the run folders, not
the report. Your own two points: answered? Where T1 is right, say so in your own words.

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T1_gpt.md`: each claim -> verified / not
verified / wrong, with the evidence path; the false-PASS risks left; what must change before the replay uses
`SPEED=fast`; verdict **ACCEPT / ACCEPT WITH CONDITIONS / REJECT**. **Reply:** 6 lines.
