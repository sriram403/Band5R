# How we test the game: the method, version by version

**Current: v5 (v4's watched run, recorded as a video for the user; 2026-10-05).**
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

## Decision log
- v1 -> v2: the user saw a dead run carry on for minutes (2026-10-02).
- v2 -> v3: the user: test as a human does, closed loop (2026-10-02).
- v3 -> v4: the user: a human doesn't stop to check every step that worked;
  watch in parallel, stop only on failure, resume from there (2026-10-02).
- v4 agreed, stop-at-first-failure agreed (2026-10-02).
- v4 -> v5: the user: "do F3 and capture a video, I'll review that"
  (2026-10-04); then: keep the test sheets, and once the steps are written
  do the walkthrough, record it and place it for me to verify (2026-10-05).
