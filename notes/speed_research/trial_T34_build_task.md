# Stage 3: the Claude builder builds GPT's T4 + T3 specs. Written by the referee, 2026-11-10.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md` (the brief)
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md` (rulings R1-R5: **R4 and R5
  change two points of the specs**), `top4.md`, `trial_T4_spec.md`, `trial_T3_spec.md` (your two specs), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside your copy `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34` = `speed-base`)
- the branch `speed-t1` and its copy `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1` (the T1 + T2 tools, being
  built now by the Claude auditor; read its `notes\speed_research\pilot_P1*.md` and, once it exists, `trial_T1.md`)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`,
`MPG_speed_base` or any other `MPG_*` folder not named above; any branch or commit other than `speed-t34`,
`speed-base`, `speed-t1` (no `git log --all`, no `git show main:...`); the skill testing-and-verification §3b.
If you open one by mistake, stop and say so in your reply.

## Your role
You are the **builder for the GPT auditor**: build exactly its two specs, add no ideas of your own, and
report every change you had to make and why (a spec point that can't work as written: build the closest
thing, say so). GPT writes no code and runs no game; you do both.

## Where and how
- Work ONLY in `MPG_speed_t34`; commit locally on `speed-t34`; no merge into other branches, no push;
  nothing on C: (temp, video, cache under the copy's `appdata/`).
- **Game code untouched** (`FindingNaresh/scripts/` except `scripts/dev/`, scenes, assets, `core/Plant.gd`).
  A game bug you notice: **your reply only, never in a file or commit** (the replay runs blind later). Don't fix it.
- **Order: T4 first, then T3.** Before T3, or before you edit any file T1 also changes (`run_test.sh`,
  `method_run.sh`, `method_watch.py`, `method_verdict.py`, `PlayTest.gd`, `LiveControl.gd`): if
  `MPG_speed_t1\notes\speed_research\trial_T1.md` is committed on `speed-t1`, first `git merge speed-t1`
  into `speed-t34` and keep both sides' changes (T1's game-time deadlines and `--nodraw` must survive).
  If it isn't there yet, build on, route every fast path to normal (the T3 spec allows it) and merge later.
- **Games:** the referee meters this copy (R2 wall clock, R3 qualification minutes). **Budget: <= 15 wall
  game min for T4, <= 15 for T3 (the specs' own caps), hard stop 30 in all.** Before each run, write its
  expected cost and the running total in your build notes.
- **At most 2 games on the PC**, and T1's copy may be running one. Scope this copy's one-game guard in
  `tools/method_run.sh` (and any launcher you touch) to games whose command line holds THIS copy's path,
  and before each launch check the PC-wide count of Godot processes is < 2 (else wait or say so).
  Speed numbers you take while T1's game runs: note it.
- **Watch every run while it runs** (step, heartbeat, PASS / FAIL / SCRIPT ERROR every few seconds); off
  plan -> stop it at once, look (a picture of the moment), note it. Three failed fixes of one thing ->
  stop, write where you got, move on or reply.
- Each new guard is proved against its planted failure AND passes clean (the specs' tables). A control that
  passes when it should fail stops that tool's qualification.

## Checkpoints (audit fix F05)
Commit locally after every finished sub-step (a WIP commit with: state, next action, tests outstanding), so a cut
child loses nothing; a WIP commit is never "qualified".

## Write
`MPG_speed_t34\notes\speed_research\trial_T4_build.md` and `trial_T3_build.md` (the specs' "required
builder report": files, commits, every deviation, every control pair with expected/actual, commands,
minutes per run, what stayed INCOMPLETE). Commit as you go.
**Reply:** 10 lines: built / partly built per spec, controls passed/failed, minutes used, T1 merged or not,
the deviations that matter, game bugs seen.
