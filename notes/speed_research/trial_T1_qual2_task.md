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

## RESUME (2026-11-14, referee): the round-2 child was cut by the API rate limit (2026-11-11 ~12:30)
Done and committed on `speed-t1` (last `c880e3d`): Q1 (open overrun STALLED fast + 1x), Q2 (the 6 batched plants alone; the
marks prelude prerequisite, `passed_ids`; 38 / 38 offline), Q3 (the round diagnostic). Not done: Q4 (the second diagnostic)
and the end of item 3 (1x-vs-1x spread vs the 3 values + lean_close) and **the final table** (scenario -> fast PASS accepted /
exploratory only / 1x). **About 2.6 game min are left of this round's 15 (meter: T1 at 56.1 of 58.7).** Read `trial_T1.md`'s
"Qualification round 2" section and `git log -6` first. Prefer finishing from the archived runs (0 game min); run Q4 only if
it fits and decides something. Then the table, commit, reply.
