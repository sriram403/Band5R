# Stage 3, trial T1 (qualified speed) + T2 (proof runs), Claude-run. Written by the referee, 2026-11-10.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md`
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `top4.md`, `audit_r2_claude.md`, `audit_r2_gpt.md`, this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside your copy `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1` (branch `speed-t1`), first its
  `notes\speed_research\pilot_P1.md`, `pilot_P1b.md`, `pilot_P1c.md` (your own pilots: the starting point)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; anything in `MPG_dev`, `MPG_referee`,
`MPG_base`, `MPG_speed_base` or any other `MPG_*` folder; other branches or commits (`git log --all`,
`git show main:...`, etc.: only `speed-t1`'s own history); the skill testing-and-verification §3b.
If you open one by mistake, stop and say so in your reply.

## Where and how
- Work ONLY in `MPG_speed_t1`; commit locally on `speed-t1`; no merge, no push; nothing on C: (temp
  files inside the copy's `appdata/`).
- **Game code untouched** (`FindingNaresh/scripts/` except `scripts/dev/`, scenes, assets). Test code and
  tools may change. A game bug you notice: **say it in your reply only, never in a file or commit**
  (the benchmark replay runs blind later), and don't fix it.
- The referee meters every Godot process of this copy (wall clock, ruling R2). These are **qualification
  minutes**, counted apart from the benchmark score (ruling R3). **Budget: <= 45 wall-clock game minutes,
  hard stop at 60.** Before each run, write its expected cost in your notes; keep a running total.
- **Watch every run while it runs** (`tools/method/probe_watch.sh` or your own loop: step, heartbeat,
  PASS / FAIL / SCRIPT ERROR every few seconds); off plan -> stop it at once, look, note it.
  A loop (run -> fix -> run, each finding something new) after 3 rounds: stop, write where you got, reply.
- Two games at once is allowed (R2), at most 2 on the PC; another trial may be running a game in another
  copy. First scope `tools/method_run.sh`'s one-game guard to games whose command line holds THIS copy's
  path (now it refuses any Godot on the PC). Speed measurements: note whether another game was running.

## Part A: T1, qualified speed (from your pilots' "next")
1. **Deadlines on game time (offline).** Every gameplay-deadline read (P1's 19 sites, class D) reads game
   time (physics frames / 60), including `method_watch.py`'s STALL judge (judge `pf`, keep a wall
   backstop as health) and LiveControl's watch / step limits. Reporting lines print game s (wall in
   brackets is fine). 1x behaviour must not change. List each site changed.
2. **`--nodraw` that really stops drawing:** switched off after each scenario's setup (and again after
   any F1 jump / profile reset inside a scenario), on only for the frames a picture needs. Prove it per
   scenario by a logged count: frames drawn ~= pictures + a few, and the speed per stretch.
3. **A deadline-negative control:** a test-only fixture (off by default) that makes one step overrun
   its game-time budget; it must be STALLED (by name) in fast mode, and the clean run must not be.
4. **One command:** e.g. `SPEED=fast tools/method_run.sh ghat` runs the qualified scenarios fast +
   nodraw and `ghat_spring` (and any proof of `free_coolant`) at 1x automatically; prints which ran how.
5. **The differential:** one 1x clean run of all 7 (`tools/method_run.sh ghat`) and one fast run of the
   6 fast scenarios. Per check: same verdict; outcome values within tolerances you state (P1: 1x is not
   tick-exact); pictures compared side by side (look at them). Then **one plant per fast scenario**
   (6, `FIXTURE=<plant>`), fast: each must FAIL on the same check as at 1x. 1x verdicts may come from
   `notes/g15_pending/prove_ghat_2026-11-09.txt` in your copy (say which); rerun 1x only if missing.
   Any difference = a question: find why before calling it qualified.

## Part B: T2, proof runs (small)
6. Time a warm import twice + once after touching a `.gd` (~0.5 min): settle whether an import skip
   matters (P1: cold 9.9 s).
7. **Early stop:** a proof run stops as soon as every expected FAIL of its plant is fully on record
   (verdict written), and the process is checked gone. Show it on 2 plants (fast): minutes saved vs a
   full scenario, same verdict. Proofs of several plants of one scenario in one batch if it's cheap.

## Write
`MPG_speed_t1\notes\speed_research\trial_T1.md`: what changed (files), every run (command, game minutes,
watched how, result), the differential table (check, 1x, fast, values), the plant table, the speed per
scenario (fast + nodraw), frames-drawn proof, the negative control, T2's numbers, what is qualified and
what stays 1x and why, "assumed -> reality -> fix" for every surprise, the final commands. Commit.
**Reply:** 8 lines (qualified or not, speed, minutes used, plants matched, what stays 1x, game bugs seen).

## RESUME (2026-11-11, referee): the first T1 child was cut by the API rate limit
It got through: game-time deadlines, `SPEED=fast` routing, `--nodraw`, an overrun control, the import
timing (row 0 of its run log). Its work is committed on `speed-t1` as `45dc00f` (WIP, not run or
qualified). **Read `trial_T1.md` and `git show 45dc00f --stat` first, review that work critically (it was
never run), then carry on from run 1 of its log.** Same rules and budget; **0.7 of the 45 qualification
min are used.** No other game runs on the PC now (the T3/T4 builder starts after you).
GPT's audit of this task (its T3 spec, two points to answer in your report):
1. Old 1x plant verdicts (`prove_ghat_2026-11-09.txt`) count only where the source, the check and the
   fixture match (exact check name, not a FAIL substring); else rerun that one at 1x.
2. Prove the deadline-negative control at **1x as well as fast**.
