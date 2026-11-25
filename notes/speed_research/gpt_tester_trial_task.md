# GPT as the TESTER: trial 1 (2026-11-25)

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`; inside dev, all GAME CODE and TEST CODE
(`FindingNaresh/**`, `tools/**`): you RUN them, you never change them. You write only your report, its evidence folder,
and nothing else.
DO-NOT-READ (stay blind: your results are compared with a Claude tester's on the SAME job):
`notes/speed_research/step9_test_report.md`, `notes/speed_research/step9/test/`, `notes/speed_research/step9/referee/`,
`notes/speed_research/step9_gpt_test_report.md`, `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\`,
`dev\nextprompt.txt`, any other thread's files.

FIRST: load these skills BY NAME (they are your own enabled skills; don't open the library folder):
testing-and-verification, game-dev, project-memory.

The user is here and chose this trial (their words: "can u do the testing here for gpt playtesting"). Don't ask
questions; take your recommended option and write what you chose and why in one simple sentence.

## Roles
- **You: GPT Astra 6.2, high, the TESTER.** The user's exception, written in this project's `AGENTS.md` / `CLAUDE.md`
  ("Exception, GPT as the TESTER", under "GPT plans, Claude builds"): you RUN the game's tests and walks and JUDGE them.
  You write no game code and no test code. Something broken? Report it with the evidence; don't fix it.
- **Referee:** the main thread (Claude). It watches the same runs live and compares your report with a Claude tester's
  report on the same job (already done, hidden from you). What's measured: did you run, watch and judge correctly
  (right verdicts, caught surprises, real numbers, honest gaps), and how long it took.

## The job (the game is fixed already; you re-test it independently)
Ghat walk step 9 used to hang: the creature "Problem" sometimes never gave up and pressed on the van's nose. A fix is
merged. Read: `notes/speed_research/step9_build_report.md` (cause, fix, bench, how bench runs were done),
`notes/speed_research/step9_build_task.md`, `notes/CHANGE_LEDGER.md` (step-9 entry), `notes/TESTING_METHOD.md` (v7),
`CLAUDE.md` (rules). Branch `gpttest` in dev (= main; don't switch).

Declare each run's expected outcome in the report BEFORE you start it.
1. **Bench, 2 saved start states** (the bench scenario from commit `15d5cfe`; find how B1 / B2 were run): the hang
   point `ghat_20261124_190738_7904` and the good point `ghat_20261117_224429_13940` (under
   `appdata/playtest/FindingNaresh/live/points/`, step-9 point). For each: did it give up, at what game time, and is
   that time consistent with that run's OWN earlier walk (its `walk.log` there: step 9 start -> step 10 start, minus the
   4 s wait)?
2. **The prove row:** `python tools/method/prove_ghat.py nose` (planted side: the nose check must FAIL); then the
   CLEAN `ghat_looks` with the same settings (it must PASS every check). Find how to run the clean side yourself.
3. **A fresh recorded walk:** `tools/record_walk.sh ghat --fresh` (video into `appdata/videos/`). Every step must
   pass. Then WATCH the step-9 part of the video: extract frames every ~3 s with ffmpeg (on PATH), look at them, and
   write what you see with video times (mm:ss): Problem appears, the lean-in, it leaves; and what the camera can't show.

## Watching runs (the user's rule: never fire and forget)
- Poll each run's log every few seconds (line count + new lines); flag 60 s with no new line (step 9 is normally ~45-70 s
  quiet, deadline 200 s). Off plan -> stop it at once, look (a screenshot if you can), write it down.
- Stopping a run: kill its child processes (Win32_Process by command line `play_walk|live.py|autoq|record_walk` and
  Godot*), then `tools/method/stop_lane.sh`, then `tasklist` to check no Godot is left. Restore `tools/live/ghat.json`
  with `git checkout` if a run changed it.
- CPU load beside every timing (`tools/method/cpu_sampler.ps1 -Out <tsv> -Stop <file>`). One game at a time.

## Rules
- **Budget: ~20 game minutes.** At the budget, stop and write up what's left.
- Never rerun to get a pass: every run counts and goes in the report.
- Nothing on C:. Never `sed -i`, never `>>` / `printf >` into tracked files.

## Report: `notes/speed_research/gpt_tester_trial_report.md` (+ evidence in `notes/speed_research/gpt_trial/`)
Per run: command, expected outcome (declared before), result, game s, wall s, CPU load, log path. The video section
(path, times, what you saw, 3-4 key frames as PNG). A **VERDICT** line on the fix: `PASS` / `PASS WITH RESERVATIONS`
(list) / `FAIL`. "Surprises" and "What I could NOT test". Your wall-clock start and end times. Commit report + evidence
on `gpttest` (git add each file by name; keep an AI attribution line). No merge, no push. Last line: the commit hash.
