# Stage 3: T1 qualification round 2 (what GPT's re-check left open). Claude auditor. Referee, 2026-11-11.
AUDITED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T1fix_gpt.md

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md` (ruling R6), `trial_T1_task.md` (rules still in
  force), `audit_T1_gpt.md`, **`audit_T1fix_gpt.md`** (GPT's re-check: what is still open), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1` (branch `speed-t1`, `4a74146`)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t34` or any other `MPG_*` folder; other branches or commits; testing-and-verification §3b.

## Rules
As T1. Work only in `MPG_speed_t1`; commit after every finished sub-step; no merge, no push; nothing on C:; game code
untouched (incl. `core/Plant.gd`). **Budget (R6): 15 wall game min (stop at 18), counted apart from the score.** The
builder of another trial runs games in `MPG_speed_t34` now: **at most 2 games on the PC** (check before each launch;
wait if 2 run). Before each run write its cost and running total; watch every run while it runs. Game bugs: reply only.

## Do, cheapest first; stop where the budget ends and say what's left
1. **Final-source open-overrun control** (GPT condition 2): rerun the original 15-vs-10 open overrun, fast and 1x, on `4a74146`.
2. **Batch attribution** (D2, option A): run each batched plant member ALONE, fast (fast_turn, leave_sees, no_breath_lock,
   round_skip, marks_pile, marks_unsaved): each must FAIL on its own exact check id; one that doesn't is NOT PROVED alone.
3. **The 3 values outside tolerance** (fuel 1.06 L, engine ticks +17.7 %, sniffs 1 vs 2) and lean_close's steady fast/1x
   gap: measure 1x-vs-1x spread on the same inputs (reuse every archived 1x run; add the fewest new 1x runs of the affected
   scenario), then say for each: inside normal 1x variation (state the revised tolerance, every check threshold unchanged)
   or a speed-dependent shift (then that path stays 1x for an accepted PASS, and say so).
4. The looks prelude inside ghat_marks (GPT): show marks' result doesn't depend on the looks differences, or keep it 1x.

## Write
A "Qualification round 2" section in `MPG_speed_t1\notes\speed_research\trial_T1.md`, ending with a table: scenario ->
fast PASS accepted / exploratory only / 1x, with the reason. **Reply:** 8 lines.
