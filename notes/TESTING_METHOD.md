# How we test the game: the method, version by version

**Current: v7 (2026-11-17: the speed research's result, signed by Claude and GPT with reservations; see the end).**
v6's "long runs after every push" was replaced by the project's milestone-only full run (CLAUDE.md, 2026-10-14).
Each version keeps what worked in the one before and names what it wasted.
The general way of thinking behind it is in the skill
`first-principles-solving` (`D:\mine\Agentics\Skills\skills\first-principles-solving\SKILL.md`).

## The core problem (in the user's words, boiled down)

The scarce thing is **real-world time until a test sheet is proven**. Tokens and
machine time are cheap next to it. So the goal is: *the least wall-clock time
from "start" to "every step of the sheet works, blind, with real input"*.

Where that time goes, broken down:
1. the game doing the steps (driving, walking: fixed, we can't speed it up much);
2. waiting for something that already failed (an open-loop run carrying on dead);
3. my thinking time between steps (each turn of mine is ~20-60 s);
4. rerunning steps that already passed, after a fix.

v1 wasted (2), v3 wastes (3), and both waste (4). The aim: only (1), plus my
time on real failures.

## v1: scripted runs, judged at the end (until 2026-10-02)

A test is one long script (`t_sheet_f3`); it runs blind; I read the log and the
screenshots when it ends.
- Good: fast when nothing breaks; repeatable (a regression).
- Waste: one early failure turns every later step red. In the F3 sheet walk
  Naresh never reached the jetty end, then 20 checks failed for that one
  reason and the walker stood on a roof for minutes. Time lost = the rest of
  the run + reading all of it.

## v2: fail-fast scripts

Stop at the first failed check, keep the game open.
- Good: no time lost after a failure.
- Waste: after the fix, the run starts again from the very start (4).

## v3: the live control line, one command at a time (2026-10-02)

The game reads a command file (`--playtest=live`, `tools/live.py`); I send one
action, read the result, the state and a screenshot, then decide the next.
- Good: closed loop: in one morning it found ~10 real bugs the scripts had
  buried (the jetty railing caught the aim, Naresh's jetty path, the drop
  points, a stack overflow, creatures frozen at the jetty mouth, the light
  can trip lost for good, ...). The game stays open between fixes.
- Waste (the user, 2026-10-02): **I check every step, even the ones that
  worked.** The game idles while I read and think after every command: a
  human tester doesn't do that. They play on and only stop when something
  doesn't happen that should have. My think time (3) became the biggest cost.

## v4: the watched run (proposed)

Play on as scripted; check everything in parallel; stop only on a failure;
fix; carry on from the failed step.

1. **A walk is planned up front as steps, each with its expected outcome.**
   A step = the actions (real keys and pad) + `expect`: what must become true,
   by when (e.g. "Naresh within 3 m of the jetty end within 40 s"). The
   positions and outcomes the next steps rely on are written in the plan,
   not found on the way. Saved as `tools/live/<sheet>.json`.
2. **The game runs the steps itself, back to back.** No waiting for me
   between steps. An expectation is a *watch*: it doesn't block; the actions
   go on (P1 climbs the crates while the watch waits for Naresh to reach the
   jetty end). A step blocks only where it `needs` an earlier watch (the
   recall needs Naresh out there).
3. **A watcher inside the game, every 0.1 s, alongside the actions**, checks:
   - the open watches (PASS with its time, or FAIL at its deadline);
   - always-on invariants: no script error; nobody in a moving state stands
     still for more than 5 s (Naresh in GO, a creature with a goal, the
     scripted walker); nobody taken unless the step allows it; a giving-up
     line ("I can't get there") is a failure.
   Each PASS / FAIL is one log line. Screenshots only on a failure (and a few
   key frames to glance at afterwards), because logs say more per second;
   pictures when a log can't tell (someone tiny far away, a visual bug).
4. **On the first FAIL: the actions stop, the world stays live**, the report
   is written (the failed watch, the state, the actors' own log lines, a
   screenshot), and the client running in the background exits, so I'm told
   at once. No polling. While the run goes, I do other work (notes, the
   next part in MPG_dev) instead of watching it.
5. **Fix, then carry on from the failed step, not the start.** At the start
   of every step the game keeps a save point (`SaveGame.collect`, the real
   save system). A test-side fix: just carry on from that step in the open
   game. A game-code fix: restart, load that step's save point
   (`SaveGame.apply`), run from that step. (Creatures' positions aren't in a
   save: a step that depends on where they are restarts from the step that
   put them there.)
6. **A walk that runs clean end to end is its regression**, as it is.

My time then goes only on failures, and a fix never costs a rerun of what
already passed.

### Settled with the user (2026-10-02)
- The core is right: wall-clock time to a proven sheet.
- On a failure: stop at the first (simpler; the parallel watches catch most).

### As built
- `dev/LiveControl.gd`: `{"walk": ..., "from": step}`, the watcher, save
  points in `user://live/points/`, the walk's lines in `user://live/walk.log`.
- `tools/live.py --walk tools/live/f3.json [--from "<step>"]`: run it in the
  background; it prints the PASS / FAIL lines as they come, aborts the run
  on a script error in the log, and exits on the result.
- A walk is generated by a small script (`tools/live/make_f3.py` ... `make_f8.py`)
  so the plan reads as steps, not as a wall of JSON. `tools/live_all.sh`
  runs every walk back to back, each in a fresh game.
- Added on the way (2026-10-03): `spawn` (a helper running alongside the
  steps: P2 on guard with the flare gun, as a second player), `call` (an
  awaited PlayTest helper: boarding, crossing the salt pans), `until`,
  `pad_down` / `pad_up`; save points also keep the creatures, what's in
  hand and Naresh's spot and leader (a game save doesn't); watches from
  before a resume point are re-armed; every step has a hard time limit;
  probes (`ray_hit`, `tag_thing`, a creature's goal in the state).
- Resume costs ~40 s (a restart) against minutes for a rerun from the
  start; plan-only fixes resume in the open game without a restart.

## v5: the recorded walkthrough (the user, 2026-10-05)

v4 proves the sheet; the user still had to play it to see what was built.
Now the watched run is also recorded, and the video is what the user
reviews first.
- Write the sheet as before (plain words, `notes/TEST_MILESTONE_<X>.md`)
  and its walk (`tools/live/make_<part>.py`).
- `tools/record_walk.sh <walk>`: Godot's Movie Maker (`--write-movie x.avi
  --fixed-fps 25`, before the `--`), the walk played in it, then ffmpeg
  to `appdata/videos/<walk>.mp4` (with sound; the game plays none through
  the speakers while recording) and `<walk>.walk.log`.
- Recording runs the game at 68-87 % of real time (Godot prints it at the
  end: "recorded in ... (84% of real-time speed)"); the walk's deadlines
  are real seconds, so leave them slack.
- Before sending: a frame grid (`ffmpeg -i x.mp4 -vf "fps=1/10,scale=400:-1,
  tile=5x6" -frames:v 1 grid.jpg`), and on a failure the seconds round it
  at 4 fps: the video shows causes the log can't (a can caught on the van,
  one player blocking the other's handle).
- Send each video as it's ready, with times for each step and what only
  the video shows (too dark, a moment told in text only).
- **Writing a walk (G, puzzle 1: five re-recordings to learn these):**
  walkers go in straight lines, so give waypoints round anything solid (the
  pump house, the tanks, the van's sides); give every point its own name
  (a reused `TAP_STAND` sent P2 to the wrong tap); aim at the thing's own
  node (`find_child('RadiatorCap')`), not a guessed height; the video is
  wall-clock shorter than the walk log's seconds (Movie Maker), so read
  times off the frame grid, not the log; with a failure, look at
  `_shots/test_walk_fail.png` and `appdata/live_run.log` ("PAD WALK
  STUCK at ...") first.
- *(v7: until a resume point is qualified SAME, acceptance takes are FRESH: see v7.)* **A failed take resumes at the failed step and the parts are joined** (`tools/record_walk.sh`, default since
  2026-11-10); the user chose this for the final video too (A, 2026-11-10): send it with every join's time
  ("joins at 0:57, 1:18") and look at the frames either side of each join first.
- Puzzle walks start from **F1 → Puzzles → N** (`{"do": "menu", "tab":
  "Puzzles", "row": "..."}`): it resets the puzzle, so a walk can be rerun
  in one game.

## Decision log
- v1 -> v2: the user saw a dead run carry on for minutes (2026-10-02).
- v2 -> v3: the user: test as a human does, closed loop (2026-10-02).
- v3 -> v4: the user: a human doesn't stop to check every step that worked;
  watch in parallel, stop only on failure, resume from there (2026-10-02).
- v4 agreed, stop-at-first-failure agreed (2026-10-02).
- v4 -> v5: the user: "do F3 and capture a video, I'll review that"
  (2026-10-04); then: keep the test sheets, and once the steps are written
  do the walkthrough, record it and place it for me to verify (2026-10-05).

## v6 (the user, 2026-10-08): the change ledger, long runs after the push

- Before the user's look at a part: its own tests, smoke, its area set.
  Never the 25-minute driving set or full.
- Each finished part: an entry in `notes/CHANGE_LEDGER.md` (what changed,
  what it could break, which tests cover it).
- On "push": push, then set:driving / full in the background in `MPG`
  while the next part is built in `../MPG_dev`. Failures are matched to a
  ledger entry, written under it, and fixed in the next round.
- At the end of the puzzle tuning: one last full run against the ledger.

## v7 (2026-11-17): the speed research (two-model research, example 2)

Benchmark: replay #6 day 2 (225 game min on the real day) from its first commit, blind, with secret holes. Result
(`notes/speed_research/replay_score.md`, `FINAL.md`): **~119 wall game min (~1.9x), but only 3 of the day's 7 holes and 18 of 21
starting plant rows**: the method did NOT pass. Both blind insurance plants (visual) were found. So v7 keeps what was proved and
marks every change **TO PROVE** until its own planted control passes. The tools live in the research copies (`speed-t34`,
`MPG_speed_replay`), not yet in `main`.

**Keep (proved in the replay)**
- **Fast + nodraw only where it matched normal speed:** heat and net (final replay 3.6x / 2.9x); looks, places, jug, spring,
  marks and the recording at normal speed (they read the PC clock or shifted when fast). Looks before marks, same run.
- **Two games at once** (two lanes, each walk and recording in a NEW game, at most two): the final suite's normal half
  (~13 min) hid the fast half and the recording. Count union and summed minutes.
- **Fail-closed judges:** a stale check list -> TEST, missing checks -> INCOMPLETE, a plant not caught -> row NOT CERTIFIED;
  never rerun until green. Exact identities, input bytes sealed before / after.
- **Picture inspection** of current bytes (rebuild the inventory right before judging): found both blind visual holes.
- **The plant matrix** with solo groups and early stop; commit after every sub-step (a rate-limit cut cost nothing).

**Change (TO PROVE, each with its planted control first)**
1. **Check the required-check list BEFORE launch** (offline, seconds; one documented file: the judge reads
   `tools/method/frozen.json`). ~15 game min were lost on two runs judged against a stale list.
2. **Bench at the second failed fix**, from the real failing pose, then one full confirmation. ~18 game min went on three
   full walks for one move until the referee steered.
3. **Prerequisites first:** a proof whose setup already failed (the jug left behind) is BLOCKED, never certified; an
   unexpected earlier failure is a discovery to name, not "the test did it" (S1 and S5 were seen and explained away).
4. **Player-time checks:** seconds from the first cue to contact at each encounter transition (finds S5 / S6 kinds);
   stowed things stay with the van (S1 kind); both players aboard before the van leaves (the take left P2 on the road and
   the walk still said DONE).
5. **A moving-camera clip at normal rate** around new surfaces (z-fighting / flicker: S2 kind); nodraw or 5-s grids can't
   clear it.
6. **Resume:** fresh takes for acceptance now. Qualify one resume point (the parked van's stale stored speed ignored, the
   engine / nav / hearing saved, the settle second lined up: the user's choice, 2026-11-17), proved SAME and a perturbed
   DIFFERENT, before any saving is counted.
7. **Never tell a blind runner how many holes exist** (it stopped at the count).

