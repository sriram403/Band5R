# Step-9 hang: the Claude BENCH builder's task (2026-11-25)

AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/audit_held_results_gpt.md
AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/held5_results_audit_gpt.md

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev` (main, extras, the skills library).
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\` (the referee's private files; you only RUN
its `game_meter.py` if told to; the referee already runs one), `dev\nextprompt.txt`, any other thread's files.

The user is away (their words: "just continue your work, don't ask me anything, just go with your recom as needed").
Never ask; take the recommended option and write in your report what you chose and why.

FIRST: load these skills (Skill tool, by name) before any other work: testing-and-verification, first-principles-solving,
game-dev (+ its references/godot.md "Physics and 3D"), project-memory.

## Roles
- **You: a fresh BENCH builder, Claude Opus 5.5, high.** Bench FIRST, reproduce the hang on the bench before any fix.
- **A plain bug** (a nav dead end, a timer never reset, a sense that sees through what it shouldn't, a state machine
  hole; one obviously right fix that keeps how the creature is MEANT to play, as the code's comments and
  `design/` say): fix it in the game code, with a planted check (below). Say in the report why it is a plain bug.
- **A design choice** (the fix changes how Problem plays: new give-up rules, new timings, different senses, more than one
  reasonable answer): do NOT build it. Write the options (A / B, your pick, what each changes for the players) in the
  report and stop; the referee runs two blind specs.
- **Referee:** the main thread (Claude Opus 5.5, high). **Audit of your fix:** GPT Astra 6.2, high (fresh eyes find
  what the maker misses).

## Branch and folder
`D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`, branch **`step9`** (made from `main`, already checked out). Commit
after each sub-step (small commits, plain messages, keep the AI attribution line). No merge, no push.

## The bug (what is known)
Ghat walk step 9 ("it comes out of the fog, goes round the van, leans in at the windows (hold your breath), sniffs at
the back, and gives up"): the walk waits `until gh().phase == 'leave'` (190 s) while `walk_breath_bot` holds breath.
Normally it passes in ~61-72 s. In **2 of ~10 fresh producers** Problem never gave up: state WANDER, standing ~1.5 m in
front of the windscreen looking in, `to_goal` ~7.6-7.7, for the whole 190 s.
- Pictures: `notes/speed_research/step9/held_step9_hang_191300.png`, `held5b_step9_hang_134143.png` (it stands at the
  windscreen, the net over the van). Log of the first: `notes/speed_research/step9/held_proof_5_step9_hang.log`.
- Run folders (save points, observations, logs): `appdata/playtest/FindingNaresh/live/points/ghat_20261124_190738_7904`
  and `ghat_20261125_133628_7352` (both hangs). Good runs to compare: any other `ghat_*` producer folder there.
- Not the held / resume code: fresh runs never restore.
- Where to look: `FindingNaresh/scripts/world/Ghat.gd` (phase "circle": `quiet_t` resets when `problem._noticed_t < 0.3`;
  give up needs `quiet_t > SEARCH_S` (25 s) AND `stops_done >= POSED_STOPS`), `scripts/creatures/Creature.gd`
  (`_sniff_t` uses the global RNG `randf`; `_van_memory` too), `Hearing.gd`, `tools/live/make_ghat.py` (steps 8-9),
  `PlayTest.gd` (`walk_breath_bot`).

## The bench (in this order)
0. **Offline first, no game (minutes):** read what the two hung runs and 2-3 good runs logged at steps 8-9. What
   differs before the hang? (Problem's arrival side, its stops, the van's / net's pose, where the players sit.)
1. **A small bench scene / gym** (rule: a test bench after 2-3 failed fixes, and here from the start): the van parked as
   at step 8, the net on, both players inside, still, Problem arriving as in step 9. Run many seeds FAST (headless /
   faster than real time is fine for a bench if the bench's own result matches 1x on one seed: measure that first).
   Log every 2 s: phase, phase_t, quiet_t, stops_done / which stop it's going to, Problem's state, goal, waypoint,
   to_goal, its position, velocity, `_noticed_t`, suspicion, sight (can it see a player? through what?), hearing
   (what did it hear?), `_sniff_t`, the breath bot's state.
2. **Causes, most obvious first** (what the picture shows: it stands at the windscreen looking in):
   a. it sees / hears the players through the glass or the net, so `_noticed_t` keeps resetting `quiet_t`;
   b. its next stop / waypoint is unreachable (past the van, the net, a slope) and it never re-plans, so `stops_done`
      never reaches `POSED_STOPS`;
   c. the global-RNG sniff timer (`_sniff_t`) or `_van_memory` draws a value that never lets it finish;
   d. the breath-hold bot misses a window (a breath event, a noise);
   e. frame rate (CPU load) changes a timing.
   Reproduce the hang on the bench (a seed / condition that hangs every time) BEFORE any fix. Can't reproduce in
   ~20 bench runs? Stop and report what you measured; don't guess-fix.
3. **The fix** (plain bug only), then the **planted check**: a named plant in `scripts/core/Plant.gd` that puts the bug
   back, a check that FAILS with the plant on and PASSES clean (on the bench, and as a scenario / manifest check the
   project's way: see `notes/TESTING_METHOD.md`, the existing plants in Plant.gd, the manifest), entry in
   `notes/CHANGE_LEDGER.md`. Then on the bench: the old hanging seed now gives up, and ~20 seeds all give up within
   the normal time (log the give-up times: the normal range is ~61-72 s from step start in the walk).
4. **The real walk, once:** one fresh ghat run up to step 9 passing: `tools/play_walk.sh ghat --fresh` (it runs on past
   step 9; you may stop it after step 10 starts). Watch it every few seconds (poll the log file; flag 60 s of silence;
   step 9 itself is normally ~60-70 s of silence, deadline 200 s). After stopping: kill its child processes (Win32_Process
   by command line `play_walk|live.py|autoq` + Godot*), then `tools/method/stop_lane.sh`, then `tasklist` to check.
   Restore `tools/live/ghat.json` with `git checkout` if a run changed it.

## Rules
- GTA closed; CPU load noted beside every timing (`tools/method/cpu_sampler.ps1 -Out <tsv> -Stop <file>`).
- Budget: **~8 game minutes** (bench runs counted at their real time). At the budget, stop and write it up.
- Never rerun to get a pass; every run counts and goes in the report. Declare each run's expected outcome before it.
- Patch files with the Edit / Write tools; never Python through a Bash heredoc with escapes, never `sed -i`, never
  `>>` / `printf >` into tracked files. Parse-check (Godot `--check-only` / the project's compile check) before commits.
- Nothing on C:. Mistakes the moment they happen into `notes/ROUGH_NOTES.md` "Assumed -> reality -> fix" (replace the
  step-9 OPEN entry's status when solved).
- One game at a time unless you measured two fit (lane `b` exists).

## Report: `notes/speed_research/step9_build_report.md`
The cause (with the bench numbers and a picture of the hang moment from an angle that shows it), plain bug or design
choice (and why), the fix (files, lines), the plant + check seen failing and passing, bench seeds before / after, the
real walk's step-9 time, game minutes used, CPU load, what you could NOT test. Last line: the commit hash.
