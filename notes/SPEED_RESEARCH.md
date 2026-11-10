# Speed research: the brief (cut the game-running time)

Started 2026-11-10 by the user. Same shape as the test-method research (`notes/TEST_METHOD_RESEARCH.md`,
result `notes/method_research/FINAL.md`). Results go in `notes/speed_research/`.

## The problem

Building puzzle #6 (the ghat), day 2 took ~5 h; **~3 h 45 m of it was the game running** (the model
mostly waiting and watching), only ~1 h 15 m was code. Day 2, game running, biggest first:

| What the game was doing | Time |
|---|---|
| 3 full clean runs of all 7 scenarios (`tools/method_run.sh ghat`, ~20 min each) | 59 m |
| 10 trial plays of the walk, each from step 1, one fix per play; live replays to measure | 52 m |
| single-scenario reruns to check each fix on the clean game | 40 m |
| planted-bug runs (each check must FAIL on its bug) | 27 m |
| 3 recording takes + encoding | 23 m |
| test benches 10 m, runs killed mid-way 8 m, ramp reruns 4 m | 22 m |

**The question:** how do we get from "the puzzle is built" to "every scenario green, the walk clean,
the video recorded" with **at most 1/3 of that game time (<= 75 min)**, without finding fewer bugs
and without weakening a single check?

## The benchmark (the scoreboard decides)

- **Start:** branch `g15` at commit **`5f3e3e3`** (the state at the start of #6 day 2). The game then
  holds **7 real holes** that day 2 found (the referee's secret list, outside the repo; the auditors
  and builders don't get it and must not go looking: no reading `MPG/notes`, `MPG_dev` history after
  `5f3e3e3`, or later commits). **Finish:** the 7 scenarios PASS under the method, the walk runs clean
  with real inputs, and the video is recorded and watched.
- **Score = game-running minutes**, measured by the referee's meter (every Godot process of the
  benchmark copy, start to end, summed). Model thinking time is reported separately.
- **Pass, all of these:** (a) game time <= 75 min; (b) **all 7 holes found** (named, with a check that
  fails on each, proved against its plant and the clean game); (c) **all the checks and plants still
  caught at the end**: the 20 plants of `5f3e3e3` still PROVED plus one per new hole (27 on the real
  day); a faster method that misses a hole or drops a check fails, however fast.
- Baseline to beat: the real day, 3 h 45 m (225 min).

## The people (the user's rules)

| Role | Model (`delegate_task`) | Does |
|---|---|---|
| **Referee** (the thread reading this) | Claude Opus 5.5 | Runs the process, keeps the scoreboard and the secret list, runs the meter, watches every run, reports. No ideas, no side. |
| **Claude auditor** | `claudeWork`, `claude-opus-5-5`, effort high | Ideas, audits, its own trials, its own code |
| **GPT auditor** | `codexWork`, `gpt-6.1-sol`, reasoningEffort high | Ideas, audits, **designs its trials as a written spec. Writes no game or test code, never runs the game** (the user: GPT is weak at game dev; `game-dev` §1.6) |
| **Claude builder for GPT** | `claudeWork`, `claude-opus-5-5`, effort high | Builds and runs exactly GPT's spec; adds no ideas; reports every change it had to make |

Every round is a new `delegate_task` with the brief, the findings and the objections (children have no
history). Strict auditors: evidence or "I think"; each audit tries to break the other's idea (false
pass, missed hole, wrong blame, cost); agreeing needs a reason in their own words.

## The process

1. **Stage 1: 7 ideas each, blind.** How it works, which part of the 225 min it removes (row of the
   table above), how it could miss a hole or let a check go weak, its cost to build.
2. **Stage 2: audits, then a top 4** (2 each), at most 3 rounds; then the referee picks by the scoreboard.
3. **Stage 3: trials**, taking turns (Claude, GPT-via-builder, ...): each a full replay of the benchmark
   from `5f3e3e3` in its own copy, cap ~2 h wall clock. The result and its why go to the other model.
4. **Stage 4: the final method** both sign (or the user decides what stays disputed), written into
   `notes/TESTING_METHOD.md` (a new version) and the skills (the user asked: the new skill
   `two-model-research`, this research = its example 2).

**Seed ideas** (the user's; the auditors add their own and may reject these with reasons):
note-and-repair walks (log every break, put the promised state, carry on; fix all, play once); resume
from the failed step (now the tools' default, branch `h1`); faster than real time (`Engine.time_scale`,
`--fixed-fps` physics, headless); only the changed scenarios while fixing, one full run at the end;
jump to the moment under test (save points, dev-menu jumps); two games at once (measured: two
instances run fine on this PC).

## Rules that must not be broken

- **Nothing on C:.** No T3 `isolation:"worktree"` (it makes checkouts on C:). Each trial gets its own
  copy on D: made by the referee (`git worktree add D:\mine\Agentics\T3_Code_Works\MPG_speed_<trial>
  5f3e3e3`, plus a copy of `tools/godot`), children use `isolation:"shared"` there.
- **No merge, no push**, local commits only, on the trial's own branch. Never touch `MPG` (main).
- **Watch every run while it runs** (step, movement, errors); a run that goes off plan is stopped at once.
- **Know a run's cost before starting it**; a loop (each run finds something, each fix starts another
  run) is stopped and reported.
- **Never change the game to suit a test.** A hole is fixed the way the design says (`design/PUZZLE_CHANGES.md` #6);
  where the design doesn't say, pick, note the pick, tell the referee.
- Tests stay behind the user's windows, muted, never taking focus.
- Mistakes go into the trial's notes at once (assumed -> reality -> fix).

## Files (`notes/speed_research/`)
`ideas_claude.md`, `ideas_gpt.md`, `audit_rN_*.md`, `top4.md`, `trial_<x>.md` (spec, build notes, the
meter's minutes, holes found, plants proved), `scoreboard.md`, `FINAL.md`.

## Done means
One method both auditors signed, with the benchmark numbers (<= 75 min, 7 / 7 holes, every plant
caught); it runs on `main` after the user's OK; the skill `two-model-research` written; a plain report to
the user: what won, the minutes, what it can't do, A / B on adopting it.
