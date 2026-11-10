# Stage 3: GPT writes the T3 + T4 specs (and the replay playbook). Written by the referee, 2026-11-10.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md` (the brief)
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `top4.md`, `ideas_claude.md`,
  `ideas_gpt.md`, `audit_r1_claude.md`, `audit_r1_gpt.md`, `audit_r2_claude.md`, `audit_r2_gpt.md`,
  `trial_T1_task.md` (what the Claude auditor is building now), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- The pilots: `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1\notes\speed_research\pilot_P1.md`, `pilot_P1b.md`, `pilot_P1c.md`
- The code and notes **inside** `D:\mine\Agentics\T3_Code_Works\MPG_speed_base` (branch `speed-base` =
  the benchmark start `5f3e3e3` + the h1 resume tools): read-only, to make the spec exact.

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; anything in `MPG_dev`, `MPG_referee`,
`MPG_base`, `MPG_speed_t1` other than the 3 pilot files, any other `MPG_*` folder; other branches or
commits (`git log --all`, `git show main:...`, etc.: only `speed-base`'s own history); the skill
testing-and-verification §3b. If you open one by mistake, stop and say so at the top of your spec.

## Your role
You are the GPT auditor (strict: evidence or "I think"). **You write no game code or test code and you
run no game** (the user's rule: GPT plans, Claude builds). A Claude builder will build exactly your
spec in its own copy (`D:\mine\Agentics\T3_Code_Works\MPG_speed_t34`, branch `speed-t34` from
`speed-base`) and report every change it had to make. Write it so a builder with no history can do it.

## What the pilots changed (read them; the short of it)
- Uncapped `--fixed-fps 60` windowed = 1.24x (drawing is the brake, CPU side). Headless fast = 4.96x with
  identical checks; `--nodraw` (drawing on only for picture frames) = 5.5x with correct pictures, but
  only once switched off mid-scenario after a drawn frame (prove by frames drawn).
- `ghat_spring` and the `free_coolant` proof stay 1x (game-code wall clocks). Import is 9.9 s cold.
- Ruling R2: the score is **wall-clock minutes while any game of the copy runs**; two games at once is
  allowed (at most 2 on this PC). T1 (in progress) gives: deadlines on game time, `SPEED=fast` (6
  scenarios fast + nodraw, spring 1x), early-stop proofs. If T1 does not qualify, your plan must still
  work at 1x: give both budgets.

## Write two specs (and the playbook)
1. `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\trial_T3_spec.md`: **discovery + selection**:
   the first broad suite, the change -> checks map used while fixing (how it is built, how it can be
   wrong, and the guard that catches a wrong map), the one final unshortened suite, the receipts.
2. `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\trial_T4_spec.md`: **walk + resume + video**:
   note-and-repair as declared independent sections (no state patched mid-walk), h1 resume for
   repairs with the **3-layer state-equality gate** (top4.md; known gaps at speed-base from the
   referee's notes: a restore stops the van (speed 0, engine off), `Creature._item_ms` is a wall-ms stamp
   from the old process, non-plain fields and the creature's children aren't kept, watches restart with a
   fresh limit), the recorded video (the user chose: joined takes are fine, every join listed with its time).
3. In `trial_T3_spec.md`, a section **"The replay playbook"**: the exact order of work from `speed-base`
   to the finish (7 scenarios PASS under the method, the walk clean with real inputs, the video recorded
   and watched, every plant PROVED including one per new hole), using T1 + T2 + T3 + T4, with the
   expected wall-clock game minutes per step (1x and fast budgets), where two games run at once, and the
   stop rules (budget, loops).

Each spec gives, for the builder: files to add or change (tools / test code only, never game code),
commands, acceptance tests for every new tool **each proved against a planted failure** (the check must
fail on it and pass clean), the game-minute budget for building and proving it (keep it small: <= 15 wall
game min per spec), what could make it give a false pass or miss a hole, and what the builder must report.

**Reply:** 6 lines: the two budgets (1x / fast), the biggest risk, anything you disagree with in T1's task.
