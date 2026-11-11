# Stage 3: GPT answers the Claude audit of its specs and writes v2. Written by the referee, 2026-11-11.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md`; `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`:
  `scoreboard.md` (R5 is WITHDRAWN and with the user), `top4.md`, `trial_T3_spec.md`, `trial_T4_spec.md` (yours),
  **`audit_specs_claude.md`** (the Claude audit you answer), `audit_T1_gpt.md` (your audit of T1), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1`: `notes\speed_research\trial_T1.md`; code in `MPG_speed_t1` and
  `MPG_speed_base` read-only, to check the audit's code claims (file:line)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_ref`,
`MPG_speed_t34` or any other `MPG_*` folder; other branches or commits; the skill testing-and-verification §3b.

## Your role
The GPT auditor, strict. **No code, no game.** Two outputs only.
The Claude audit keeps 8 of your 24 pieces, simplifies 11, cuts 4 (the change -> checks map, its lint, the section
graph, watch-deadline restore), estimates ~35 -> ~12 build hours, says your 62-min replay budget is ~74-82 serial
(~62-68 with the 1x plant runs beside the recorded take), and found a gap: game-code hearing reads the wall clock
(`Creature.gd:448`, `Carryable.gd:164`), untested fast.
**Referee's plan for your T1 blockers (1) missing lane, (2) closed-step deadline, (3) exact plant identity:** the Claude
auditor fixes them in T1's own tools now (with planted controls), together with the hearing gap. So v2 can rely on
them; say if you disagree.

## Do
1. **For every row of the Claude audit:** AGREE / AGREE WITH CHANGE / DISAGREE, with your evidence (check its
   file:line claims in the code). Changing your mind is fine when evidence did it; say which.
2. **Write the agreed lean spec** `trial_T3_spec_v2.md` + `trial_T4_spec_v2.md` (same folder): only what both of you
   now agree, each piece with its acceptance control; the replay playbook with a budget both of you can defend
   (serial and with overlap, from T1's measured 4.4-min suite).
3. **A "Still disputed" list:** each point both positions in one line each, for the user to decide as A / B.

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\answer_specs_gpt.md` (1 + 3) and the two v2 specs.
**Reply:** 6 lines: agreed / disputed counts, the v2 budget, the disputes.
