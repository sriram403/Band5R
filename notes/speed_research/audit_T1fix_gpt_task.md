# Stage 3: GPT re-checks T1's fix round (short). Written by the referee, 2026-11-11.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `audit_T1_gpt.md` (your conditions),
  `trial_T1_fix_task.md`, this file
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1`: `notes\speed_research\trial_T1.md` ("Fix round" section); the diff
  `git -C D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 diff 5f468c2 4a74146`; `tools\method\t1fix_controls.py`; the run
  folders `appdata\method\runs\20261111_11[3-5]*`. You may RUN `python tools/method/t1fix_controls.py` (offline, no game).

## DO NOT READ
Anything else under `MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`, `MPG_speed_ref`, `MPG_speed_t34` or any
other `MPG_*` folder; other branches or commits; the skill testing-and-verification §3b.

## Do (strict, read-only except your one file; no game, no code changes)
For each of your conditions 1-3: closed / not closed, with the evidence (code line, control, run folder). Then the open
items: the hearing decision (jug + places at 1x), lean_close's steady fast/1x difference, the 3 values outside tolerance
(fuel 1.06 L, engine ticks +17.7 %, sniffs 1 vs 2): may the replay use `SPEED=fast` for heat, looks, net, marks, and
on what conditions? Write `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T1fix_gpt.md`.
**Reply:** 5 lines: conditions closed, what fast may be used for, what must still happen first.
