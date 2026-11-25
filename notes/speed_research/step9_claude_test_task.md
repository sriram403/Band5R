# Step-9 fix: the Claude TESTER (2026-11-25)

AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/audit_held_results_gpt.md
AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/held5_results_audit_gpt.md

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`; inside dev, all GAME CODE and TEST CODE
(`FindingNaresh/**`, `tools/**`): you RUN them, you do not change them. You write only your report, its evidence folder,
and the notes lines named below.
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`, any other thread's files.

The user is away (their words: "just continue your work, don't ask me anything, just go with your recom as needed").
Never ask; take the recommended option and write in your report what you chose and why.

FIRST: load these skills (by name, from `D:\mine\Agentics\Skills\skills\<name>\SKILL.md`) before any other work:
testing-and-verification, game-dev (+ `references\godot.md` "Physics and 3D"), project-memory.

## Roles
- **You: a fresh Claude Opus 5.5, high, the TESTER.** You did not build the fix: test it as if it were wrong. You run
  the after-fix tests and judge them; you write no game code and no test code. Something broken? Report it with the
  evidence; don't fix it. (GPT was meant to test: on the work account its rules stopped it, and GPT Astra 6.2 isn't on
  the personal account, so you test and GPT Astra 6.2 audits your results after.)
- **Referee:** the main thread (Claude). It watches the same runs and writes its own verdict blind.
- A separate GPT child audits the fix's code. You don't need to.

## What was fixed (read these)
`notes/speed_research/step9_build_report.md` (the cause, the fix, the bench, what was NOT tested),
`notes/speed_research/step9_build_task.md`, `notes/CHANGE_LEDGER.md` (the step-9 entry), the commits on branch `step9`:
`git log main..step9` (bench `15d5cfe`, fix `db70d9c`, prove row `043d5cc`). Project rules: `CLAUDE.md`,
`notes/TESTING_METHOD.md` (v7). How runs are watched / stopped: the build task's step 4.

## Folder and branch
`D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`, branch **`step9`** (checked out; don't switch). Commit your report
and evidence when done (plain message, keep the AI attribution line). No merge, no push.

## The tests, in this order (declare each run's expected outcome in the report BEFORE you start it)
1. **Real start states on the bench** (the bench scenario the builder made in `15d5cfe`; find how B1 / B2 were run in
   that commit and the report). Run the FIXED game from the step-9 save point of: hang point 2
   `ghat_20261125_133628_7352` (never run on the bench), then 4 good producers from
   `appdata/playtest/FindingNaresh/live/points/ghat_*` with different "van urge left" values (the report's table).
   Expected: each gives up within ~57-72 s of game time. Log each give-up time.
2. **The prove row:** `python tools/method/prove_ghat.py nose` (planted side must FAIL on that check id, clean side must
   PASS the whole `ghat_looks`, incl. its tarp give-up check that now starts from stop 5 within its 70 s limit).
   ~6 game min per side.
3. **The video:** one fresh recorded walk, `tools/record_walk.sh ghat --fresh` (the whole walk; video lands in
   `appdata/videos/`). Expected: every step passes; step 9 gives up in ~61-72 s. Then WATCH the video's step-9 part
   (extract frames every ~3 s with ffmpeg from `tools/` or PATH; look at them): Problem comes out of the fog, goes round
   the van (not into it), leans in at the windows, sniffs at the back, leaves. Write the video's path and the times
   (mm:ss in the video) of: Problem appears, each stop, the lean-in, the sniff, it leaves.

## Watching runs (the user's rule: never fire and forget)
- Poll the run's log every few seconds while it runs (line count + the new lines); flag 60 s with no new line (step 9
  itself is normally 60-70 s quiet, deadline 200 s). Off plan -> stop it at once, look (a screenshot if you can), write it.
- Stopping a run: kill its child processes (Win32_Process by command line `play_walk|live.py|autoq|record_walk` and
  Godot*), then `tools/method/stop_lane.sh`, then `tasklist` to check no Godot is left. Restore `tools/live/ghat.json`
  with `git checkout` if a run changed it.
- GTA closed; CPU load noted beside every timing (`tools/method/cpu_sampler.ps1 -Out <tsv> -Stop <file>`).
- One game at a time.

## Rules
- **Budget: ~25 game minutes** for all three. At the budget, stop and write up what's left.
- Never rerun to get a pass: every run counts and goes in the report. A run that fails: stop, look, report it.
- Nothing on C:. Use Write / Edit-style file writes; never `sed -i`, never `>>` / `printf >` into tracked files.
- A surprise (assumed -> reality) goes in your report's "Surprises" section; the referee copies it into the mistake log.

## Report: `notes/speed_research/step9_test_report.md` (+ evidence in `notes/speed_research/step9/test/`)
For each run: the command, the expected outcome (declared before), the result, game seconds, wall seconds, CPU load, the
log path. Then the video section (path, times, what you saw, 3-4 key frames saved as PNG in the evidence folder).
Then a **VERDICT** line: `PASS` (the fix works and nothing else broke), `PASS WITH RESERVATIONS` (list them), or `FAIL`
(what failed, the evidence). Then "What I could NOT test". Last line: the commit hash.
