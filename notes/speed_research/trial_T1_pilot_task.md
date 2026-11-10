# Stage 3, pilot P1 (T1 speed + T2 compile timing), Claude-run. Written by the referee.

READ FIRST, ONLY these: notes/SPEED_RESEARCH.md, notes/speed_research/{scoreboard.md, top4.md,
audit_r2_claude.md, audit_r2_gpt.md}, notes/TESTING_METHOD.md, and anything inside your copy
D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 (branch speed-t1 = the benchmark start 5f3e3e3 + h1's resume tools).
DO NOT READ anything else under D:\mine\Agentics\T3_Code_Works\MPG\notes, D:\mine\Agentics\T3_Code_Works\MPG_dev,
D:\mine\Agentics\T3_Code_Works\MPG_referee, other branches/commits, or skill testing-and-verification §3b.

Work ONLY in D:\mine\Agentics\T3_Code_Works\MPG_speed_t1 (commit locally on speed-t1; no merge, no push;
nothing on C:, no temp files there). The referee meters every Godot process of this copy: these are PILOT
minutes, counted apart from the benchmark. Budget: <= 8 game minutes for this pilot. One game at a time.
Watch every run while it runs (log every few seconds; stop it at once when off plan).
Game code stays untouched in this pilot (test code / tools only).

DO, in order, and stop at the first step that decides "no":
1. Offline (0 game min): classify every wall-clock read in the test code on the ghat path
   (FindingNaresh/scripts/dev/PlayTest.gd ghat scenarios, dev/LiveControl.gd, dev/GhatWatch.gd if present,
   tools/method/*): gameplay deadline / health / reporting. Write the table.
2. The speed probe (<= 2 game min): how fast can this PC run the game uncapped at a fixed physics step,
   with the same inputs? E.g. one short ghat scenario (pick one, say why) at normal settings vs with
   `--fixed-fps 60` and no frame cap (Godot: `--fixed-fps` makes each frame advance a fixed delta;
   `--disable-vsync` / max fps 0), measuring GAME seconds per real second (physics frames / 60 vs wall).
   Also with the window minimized/hidden if the tests run that way. Report the ratio. If < 1.7x: say so
   plainly; the plan can't reach 75 min (top4.md).
3. Compile timing: time `tools/run_game.sh --headless --import` twice in a row (unchanged code), and once
   after touching one .gd file. Report seconds.
4. Only if 2 says >= 1.7x: a 1x-vs-fast differential on that one scenario (same checks pass/fail), and one
   of its plants (core/Plant.gd, --method-fixture=<name>) fails the same way fast as at 1x.
WRITE notes/speed_research/pilot_P1.md: the table, every measurement with how it was taken, the verdict
(go / no-go for the 2x column), what you'd change. Reply with a 6-line summary.
