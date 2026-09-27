# Lessons: building a game with AI models (and in general)

What this project has taught us, so every model (and person) working on it
knows **what to do and what not to do**. Written from Stage 1 to Milestone D
(2026-09-23 to 2026-09-27); kept up to date from now on.

**Rule for every model (user, 2026-09-27):** add a lesson here **the moment
you learn it**, not at the end of a milestone or a full test run: a thread
can be compacted or stop at any time and the detail is lost. Before moving to
a new milestone or a new thread, read through what you did and add anything
missing. Short entries: what happened, why, what to do instead.

The engine-level details (exact Godot calls, numbers) are also in
`MASTER_PROMPT.md` section 7; this file is the why and the habits.

---

## 1. Working with the user

- **One step at a time, their test decides.** Build a part, test it yourself
  until clean, hand over, wait. The user tests one puzzle at a time and says
  "next"; don't push or move on before that (MASTER_PROMPT rule 2).
- **"Let's discuss" means discuss.** Proposals and design pages list open
  questions; ask them before building. Give a suggested answer for each so the
  user can say "all fine".
- **Explain in plain language.** The user is not a professional developer:
  say what they will see and do, not the code. Step-by-step test guides
  ("do / expect / tell me") worked well.
- **Things agreed "for later" go in `notes/POLISH.md`**, not built now, and
  the user is reminded at the end.
- **At the end of each milestone, stop and ask:** continue in this thread, or
  prepare the hand-over notes for a new one (MASTER_PROMPT rule 17). In the
  polishing stage, before starting a task, say whether it fits this thread's
  remaining context or a new thread would be cheaper.
- **Report failures honestly.** If a test failed, say so; if something wasn't
  tested, say that. The user trusts the report only if it is exact.

## 2. Working as an AI model

- **Test the way the user will get there** (E5): the test sheet said "F1,
  jump to 'Someone is sitting in the fifth rose'"; a jump only moved the
  objective, so the plaza was empty (the roses had never risen). The tests
  set their own flags and never jumped. Now Bessi jumps set the world up
  (and back), and `t_bessi_jumps` does exactly what the sheet says.
- **Say where a part lives** (E4): E4 was built on its own branch in
  `MPG_dev`; the user tested `MPG` and found "the build ends for now". A
  hand-over says which folder and which branch has the part, and nothing
  is announced as ready until it is in the copy the user plays.

- **Notes are the memory.** `MASTER_PROMPT.md` (how to resume), `TODO.md`
  (live checklist, "Right now" line), this file (lessons). Update them after
  every step and commit small: a new thread must carry on seamlessly.
- **Before editing, look.** Read the code you change; check `git status` at
  the start of a thread (the last thread may have left work uncommitted: D7
  was half-built and never run).
- **Review other models' work critically.** A ChatGPT session's code passed
  its own tests and still had real bugs; the tests were written to pass.
- **Don't trust a green test. Make it able to fail.**
  - `climb` checked "higher than deck - 0.6 m" and passed while every lookout
    ramp stopped short of its deck. Check the exact thing (feet on the deck).
  - `t_relay` gave P1 the binoculars in code, so nobody noticed they were
    never placed in the world. **Tests must find things the way a player
    does** (walk there, pick it up with the real key).
  - A "can see the board" check cast a ray against colliders; tree canopies
    have none, so it passed with trees in the way. Look at the screenshot.
- **Look at every screenshot, critically.** Most bugs this milestone were
  found in the shots, not the checks: a lid that swung into the chest, a
  window that was a solid panel, pace notes running off the nav glass, a
  triangle that looked like a diamond, a menu drawn in the corner, a creature
  glimpse in fog too thick to see it. One wrong-angle shot (a van's tyres
  hidden behind its body from straight behind) nearly sent the hunt the
  wrong way: take a second angle before concluding.
- **Reproduce a user report their way.** They use the F1 menu and play alone
  on one keyboard; the tests used code shortcuts and two views. The bugs
  (pace notes "missing", a van with no tyres) only showed up by doing exactly
  what they did (`t_ghat_menu`).
- **Can't reproduce it? Instrument it.** The lookout box "didn't open":
  logging every dial turn showed dial 1 was never turned, because the
  triangle looked like the diamond. Logs beat guesses.
- **Numbers before assumptions.** Measure (scenario times, fps, distances in
  the log) before deciding what's slow or broken.

## 3. Testing a game

- **Don't assume a speed limit: test it** (user, 2026-09-27). We sat idle
  through hour-long full runs because "only one game at a time". Broken
  down and tried: two instances run fine on this PC (112 fps in one while
  the other ran the full world test; 144 alone). Now long runs go in `MPG`
  while the next part is built in `MPG_dev` (a git worktree). The way to
  work is in `notes/PRINCIPLES.md` (first principles, the algorithm).
- **Intermittent driver crashes: measure, don't guess** (2026-09-27). Three
  breakdowns in long world runs (two crashes in `nvoglv64.dll` at the same
  address, one freeze), with one and with two game instances, at the ghat,
  the journey and the way out. The way out run alone: no crash. So it's not
  one scenario and not the second instance; most likely the graphics driver
  under long heavy runs. What helps: `resume` (finished scenarios are kept),
  and memory per scenario in the log. (Kept `../MPG_base`, a copy at the last
  commit before E1, to compare if it gets worse.)
- **A resumed run starts from a fresh world:** skipped scenarios no longer
  set things up for the next one. The journey then met the town cars and
  got stuck (it clears the traffic itself now, like the road drive).
- **Fail fast, automatically** (E3): a typing slip in a test left the game
  hanging on its failed load for the whole 10-minute timeout. `run_test.sh`
  now compiles first and stops in ~5 s on a script error (`NO_CHECK=1` skips
  it). Proven by breaking a line on purpose.
- **Check which copy a file goes into:** two new E3 files were written into
  `MPG` (main) instead of `MPG_dev`, so the dev copy couldn't find them.
  With two copies, every path names its folder.
- **A test fix can break the next test:** checking the nav at Last Fuel
  drove the van there, which put Last Fuel on the paper map, and the map
  test (next) expects it unknown. Fix a test by the smallest move that keeps
  the world as the next test expects it (the nav is checked at J1 now).

- **Levels, like a team** (user, 2026-09-26):
  1. while fixing: only the scenarios for the change (seconds to 2 min);
  2. smoke, `tools/run_test.sh` (~2.5 min): the controls + one short world
     check per system;
  3. an area set (`set:puzzles`, `set:creatures`, ...) when an area changed;
  4. full, before a push or a hand-over; GitHub runs it on every push.
  Never make the user wait on a 15-minute run for a one-line fix.
- **One source for the test plans** (`tools/test_plan.sh`): the local and the
  GitHub runners had drifted apart (GitHub was missing four test maps).
- **Each test sets up its own state.** Reordering the suite exposed tests that
  leaned on what ran before them (a story test that needed a low fuel tank;
  a controller test that couldn't start an engine an earlier drive had
  overheated; a pretend controller left plugged in).
- **The real world changes tests:** a controller plugged in moves P2 onto it
  (TAB then leaves the keyboard with P1). Log the setup (`pads=`) first.
- **Flaky means the measurement is wrong**, not "rerun it": a lure test
  measured to a crate that rolls (measure to the spot it heard); a pickup
  test read the prompt before the map had settled (wait for it).
- **Long runs must be resumable** (user, 2026-09-27): a 40-minute full run
  that dies at minute 35 (a timeout, a crash, a restart) shouldn't be redone
  from the start. Each finished scenario goes to a progress file with its
  results; `tools/run_test.sh resume` skips those. A failing part shouldn't
  stop the run either: report everything in one summary at the end.
- **Give every wait a timeout that fits it, and check the run finished.** A
  quick recheck was wrapped in a 900 s timeout; the way-out drive alone
  outlasted it, the log just stopped, and "no failure lines" looked like a
  pass. Trust only the summary line (`==== N failure(s) ====`); no summary
  means it didn't finish.
- **The full order changes the state.** Scenarios that passed alone failed
  late in the full run: after the long drives the day had moved on (the mood
  was already dusky), and the van ended far from where a test assumed. Each
  test sets the time of day and positions it needs.
  It came back in E1's full run: after 16 minutes of driving, the one-time
  lorry had already pulled out, and a test can was on the van's rack, where
  moving it does nothing. One-time things need a `reset()`; items go back
  with `reset_can` (it unstows), never by setting a position.
- **Never edit game files while a test run is going:** later segments load
  the new files and the run is meaningless (one had to be thrown away).
- **A parse error hangs the game** on its failed load: run tests with a
  timeout and kill stray processes afterwards.
- **Gyms first:** a small test map per mechanic (tagging, binoculars,
  stealth, creature, traffic, tyre, house) made the numbers (sight ranges,
  readable text sizes) measurable before they went into the world.
- **Test like a person too:** walk, don't teleport, where the layout matters
  (P2 couldn't get out of their own house while teleport tests passed).
- **Stand where a person would stand** (E1): a test "picked up" a can from
  7 m away; carried things let go beyond 2.4 m, so the can fell straight
  back and the check failed for the wrong reason. Put the player next to
  what they grab.
- **Reactions come a step later** (E1): Naresh says "It's done!" on his next
  physics step after the crank finishes; a check on the same step saw
  nothing. Wait a few frames before checking what someone said or did.
- **Don't stop watching the moment something starts** (E1): the act test
  ended its loop as soon as the honk act began, one step before the van
  sounded the horn; it failed only when the honk happened to be last.
- **A crash inside the graphics driver** (`nvoglv64.dll`, E1 full run, in
  the world segment at the ghat) is not a game bug to chase first: resume
  the run (`tools/run_test.sh resume`) and see if it comes back.
- **A mouse test that passes alone but fails in a long run** read 40 and 48
  degrees instead of 50.4: real mouse movement reached the test window.
  Rerun it alone before looking at the code.
- **Resume first, recheck after** (E1): running one scenario to check a
  failure started a new run, which cleared the broken-off full run's
  progress, so `resume` had nothing left. Resume (or finish) the long run
  before starting any other test.
- **Log what characters say** (E1): hooking Naresh's lines into the test log
  made every failure readable at once ("I dropped it." showed the bug).

## 4. Game design lessons (from the user's play)

- **Give both players something to do, all the time.** The maze's hay dust
  left the guide standing idle (polish item P1).
- **Don't force both players onto one task.** The tarp needed "everyone out";
  now one can do it all, or start it and the other finish (progress kept).
- **Give time to react.** The first creature stepped out 22 m ahead: no time
  to hide. Now it appears ~100 m ahead and walks towards you.
- **Distances along the road, not as the crow flies.** Hairpins fold back on
  themselves: a straight-line trigger fired on the hairpins, before the scene
  it was meant to follow.
- **Readable at split-screen size.** Half the width means half the pixels:
  text and pictures must be sized for 800 px views (the relay boards at 280 m
  were a few pixels even through binoculars: moved to 150 m, bigger).
- **Shapes must be unmistakable.** A triangle made from a 3-sided cylinder
  looked like the diamond from the front: the player "solved" it wrongly.
- **Read order matches what the player sees.** Dials numbered left to right
  from the front (they were right to left).
- **Sightlines need clearing:** scattered trees hid things meant to be seen
  from a height; keep corridors clear by design.
- **Hiding from view, don't block the player's own view.** The tarp covered
  the door mirrors, the only way to watch from inside; it now leaves the side
  windows open.
- **Solo testing is a real mode:** one person plays both players on one
  screen. Hiding the nav from "the driver" hid it from the only view there
  was.

## 5. Godot / GDScript habits that bit us

- **A ray that starts inside a collider doesn't hit it** (E6): Naresh's
  "is the way clear?" rays began inside the tilted boat and said yes; he
  walked into it, got wedged, gave up. Once stuck, plan on the grid (shape
  queries do see overlaps); keep colliders upright round tilted visuals.
- **Don't make people chase what they're holding** (E6): a hull that slid
  away while pushed took itself out of reach; it rocks in place and slides
  off at the end.

(Details and more in `MASTER_PROMPT.md` section 7.)

- **Moving a physics object by hand:** reset the drawing smoothing on it *and
  every child*, and wake it: a parked, frozen, sleeping van kept its wheels
  where it had been (`Camper.snap_visuals`).
- **Teleporting a player:** look for a place to stand; a building's centre is
  inside its walls (players fell under the map at the barn). Check "in the
  sea" by the coastline, not a height: inland ground here is below sea level.
- **Interactables need a `prompt` meta** (`prompt_fn` alone is ignored).
- **Story steps by id, never by index:** adding one step shifted every
  hard-coded number after it; saves store the id too.
- **Untyped values need explicit types** (`var x: Array = boot.builder...`),
  or the whole script fails to parse.
- **Overlays on their own CanvasLayer** (the F1 menu was drawn under the
  HUDs); full-screen controls need `set_anchors_and_offsets_preset`, not just
  the anchors.
- **`Route.nearest` searches only nearby cells:** for a place well off the
  road, scan the road's points.
- **A guard meant for some steps of a job, applied to all of them** (E1):
  "is he still holding the can?" ran on the step where he had just put the
  empty can down to fetch the full one, so the scripted refuel mistake
  always ended in "I dropped it." Check per step.
- **Build meshes from exact points when shape matters** (a `PrismMesh` came
  out lopsided).
- **Patches through bash heredocs mangle backslashes:** use the edit tool for
  lines with `\n`.

## 6. Performance

- **Every extra camera is a whole extra render.** The van's three mirrors
  took 144 fps to 58 until they took turns; the bridge's safety mirror only
  draws with someone near the hut, every other frame.
- **Build-time traps:** thousands of shapes added to one body then moved is
  O(n²) (scatter once took 94 s); create per-tile bodies up front.

## 7. Environment and tools

- **Nothing on C:** all data inside the project folder (Godot's user data is
  redirected through `tools/run_game.sh` / the .bat files).
- **Test runs must not disturb the user:** the window opens off screen,
  muted, without focus (`tools/run_test.sh`).
- The GitHub command-line tool isn't installed on this PC: CI results are on
  the Actions page; say so rather than guessing.
- Game logs (the user's own sessions too) are in `appdata/FindingNaresh/logs`:
  read them when a report can't be reproduced.
