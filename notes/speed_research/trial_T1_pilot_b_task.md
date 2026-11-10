# Stage 3, pilot P1b (is drawing the brake?), Claude-run. Written by the referee.

Same READ FIRST / DO NOT READ lists and rules as notes/speed_research/trial_T1_pilot_task.md (read it
first, then notes/speed_research/pilot_P1.md and the scoreboard's rulings R2). Work only in
D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 (branch speed-t1, your P1 commit 1d0416e is there).
Budget: <= 4 game minutes. Watch every run while it runs. Game code untouched.

DO, with the same scenario (ghat_heat) and the same speed_probe measurement as P1:
1. fast + `--headless` (no drawing at all): game seconds per real second, and does the scenario still
   PASS the same checks (some checks may read pictures / need a viewport: list which fail or skip and why);
2. fast + a tiny window (e.g. `--resolution 320x180`): the ratio and the same pass / fail list;
3. (0 game min) per scenario of the 7 ghat scenarios and the walk: which checks need real pictures
   (screenshots, viewport reads, `get_viewport`, light / brightness checks), from the code.
WRITE notes/speed_research/pilot_P1b.md: the ratios, the check differences vs 1x, the per-scenario
"needs pictures" list, and the verdict: which parts could run headless/tiny-fast and what that does to the
plan's minutes (use the top4.md table). Commit locally on speed-t1. Reply with a 6-line summary.
