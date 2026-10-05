# Lessons: building a game with AI models (and in general)

What this project has taught us, so every model (and person) working on it
knows **what to do and what not to do**. Written from Stage 1 to Milestone D
(2026-09-23 to 2026-09-27); kept up to date from now on.

**Rule for every model (user, 2026-09-27):** add a lesson here **the moment
you learn it**, not at the end of a milestone or a full test run: a thread
can be compacted or stop at any time and the detail is lost. Before moving to
a new milestone or a new thread, read through what you did and add anything
missing. Short entries: what happened, why, what to do instead.

**From the watched runs (2026-10-02/03), the sorted ones:**
- A test that turns a hazard off, places a player by code or hands over an
  item to get past a step hides every bug in how that step really plays
  (the gallery creature vs the van, the buried flare gun, the gun lost at
  the van door: all behind `dormant`, `place_player`, given items).
- When the same failure repeats after resumes, the cause is upstream: go
  back to the step that set the situation up.
- Look at the input before fixing what consumes it (Naresh's path "bug"
  was the aim landing over deep water).
- A shape cut into a grid needs a cell (better its diagonal) of margin.
- Every wait gets a deadline; the watcher must not be the only thing that
  can stop a run.
- Check the tool before blaming the game, and make tools fail loudly.
- **Short threads with good notes beat one long thread** (the user,
  2026-10-04): every message resends the whole conversation, so a long
  thread gets slow and costly, and its compaction drops detail by chance.
  Keep the notes current, and at a natural break hand over: the next thread
  starts by reading `notes/MASTER_PROMPT.md` (section 8).

**Also (user, 2026-10-02):** every time an assumption meets a different
reality, add *assumed -> reality -> fix -> habit* to the mistake log in
`notes/ROUGH_NOTES.md`, and read that log before starting something similar
(we simulate learning from mistakes, which models can't do on their own).
"Update the md files" means every file listed in `CLAUDE.md` / `AGENTS.md`
that the change touches.

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
- **Shape a loose ask to fit, propose, then build (2026-10-05).** "A room",
  "water", "a key": design it as the thing that belongs to that puzzle and
  place (the water works' own pump house, its water tower), write a short
  proposal with numbers and your own extra ideas (S1, S2, ... yes / no
  each), wait for the answers, then build (`design/PUZZLE_CHANGES.md`).
- **Give the user a way to replay what they test.** A Story jump didn't
  reset a puzzle already done; the F1 Puzzles tab does (reset + story + go).

## 2. Working as an AI model

- **A jump should put you there** (E7): "jump to the step, then Travel"
  left Naresh 200 m away by the rose and the user lost (no Naresh, no
  drum in sight). First principles: what does a tester want from a jump?
  To play that step at once. Now a Bessi jump places both players, Naresh
  and the van (`DevMenu.STEP_PLACES`), tested by `t_step_jumps`.
- **Toggles in tests:** a blind X (engine) switched off an engine an
  earlier test had left running; the van never moved. Set the state
  (`engine_on()`), don't flip it.
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

- **A recorded run is the best evidence, for the user and for me**
  (2026-10-04/05). The user reviews videos of the walks instead of
  playing first. Twice the video showed a failure's cause the log
  couldn't: the full can caught on the van's side and fell from P1's
  hands; P1 stood in P2's line to the generator's choke. Both were my
  walks' positions, not the game. And it showed what only a viewer
  judges: the tunnel gallery nearly black, the homecoming told in text
  while you sit facing the road. Read the tool's own numbers before
  naming a cause (I guessed the recording speed wrong twice; Godot
  prints it).

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

- **A new feature changes what old tests start from** (the E8 full run,
  2026-09-29): the sets for the new part were clean, but in the full order
  three old world tests failed: the roses were now sunk until the photo, so
  "the rose monument blocks the player" walked through the spot; the storm
  test left the storm on, which holds the light at 0.3, so the mood test's
  J2 check saw 0.3; a fix in the feedback test parked the van at J1, which
  delivered Naresh's old text before the story test looked for it. When a
  part changes the world's starting state or leaves state behind, search
  the old tests for what they assume about it, and have the test that
  changes it put it back. Only the full order finds these, so run it before
  the push, not after.

- **Size the test to the change (the user, 2026-10-01):** don't rerun a long
  scenario because it happens to cover a small fix (the storm gym's spawn
  point was checked with the whole 3-minute storm test, twice). Write a
  throwaway scenario of a few seconds for the question in hand; the long
  tests run once, before the hand-over. See `notes/PRINCIPLES.md` 4.
- **Put the player where the thing is:** in the storm gym the players
  started at the gym's centre, 300 m from the van, in 60 m fog; the user
  couldn't find it. A gym starts you beside what you came to test, facing it.

- **"Where is everyone" isn't one place (F2, the user's test):** the storm
  took its strength from wherever *anyone* was, so P2 left standing at J3
  (a player testing alone moves only P1) kept it raining, wet and gusty on
  P1 and the van far up the coast road. Weather follows each player and the
  van; shared things (fog, sound) follow the views on screen. Test with the
  players split up, the way one person tests a two-player game.

- **`global_transform` before the world is in the scene is wrong** (F3):
  the builder runs before the world joins the tree; points taken from a
  node's `global_transform` then were garbage (a player placed by one fell
  through the map). Use `transform` (the world root sits at the origin).
- **An invisible wall blocks eyes too** (F3): the sea wall stood between the
  beach and the jetty, so looking at Naresh out there hit the wall. Walls
  that only keep bodies in go on their own layer (64), which rays skip.
- **A step a character can't take sends its path round the long way:** a
  jetty 0.25 m above the sand made Naresh wade round it in the sea. Make
  the way in flush.
- **Real-world clutter breaks scripted helpers:** a can carried at his side
  snagged on a 1.4 m door; a player standing at the rack made him give up.
  He now picks a snagged thing up again and says "Excuse me!" and waits.
- **Test inputs must be as long as a human's:** a pad press shorter than one
  physics tick never opened the command wheel. Hold a few frames.
- **Check the story after it has had a tick to move on:** a check right
  after the action that completes a step passed or failed by luck; wait for
  it (`until`).
- **Heredocs with quotes and apostrophes break the shell:** write notes
  through a script file, not a bash heredoc.

- **A merge with a new `class_name` script greys out `Play.bat`** (F3, the
  user's launch): Godot only learns new class names on an import; the test
  runner imports first, `Play.bat` didn't, and nothing ran in `MPG` after
  the merge. `Play.bat` now imports when any script is newer than the class
  list. After a merge, start the game once in `MPG` before handing over.

- **A state flag without the thing it describes** (F9): the swing bridge's
  "locked" set from a load or a script never moved the span (only the cranks'
  path drew it), so the end-to-end drive fell into the estuary while the
  part's own test passed. Setting a state must also put the world in it.
- **The end-to-end drive finds what part tests can't** (F9): `return_run`
  drives Bessi to home in one go; in its first two runs it found the open
  span and a story gap a part's test would never meet. Keep a whole-journey
  run for every milestone.

- **Scripted drivers: S on a stopped van is reverse** (F9): the end-to-end
  drive "held" the van at a door by tapping S; once stopped, S reversed it
  at full power into a house. Hold with the handbrake, as a person does.
- **An old greybox can hide a trap for years:** the estuary bridge's deck
  edge was a 0.3-0.5 m step from Milestone B on; it only stopped the van
  on some lines and speeds (one run got over it, the next didn't). Drive
  every structure end to end, more than once.

- **Shared names collide silently** (F3, found by the full run): the
  village's `poi["shed_roof"]` overwrote the water works shed's, so the
  water works' Memory Fragment had moved onto the net shed and the old
  climb test climbed the wrong shed. New places prefix their poi names
  (`net_shed_...`); grep for a name before taking it.
- **A new chapter's tests change what the old ones start from** (F, the full
  run): the return left the storm on, so later way-out tests met a blown
  bridge, cut power and gusts (24 failures). The runner now puts the return
  away before any test that isn't one of its own (`_undo_return`).
- **A puzzle's test that passes "sometimes" depends on a phase:** the salt
  pans crossing passed alone and failed in order, because the watcher's
  pattern started somewhere else. A jump restarts the pattern.

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
  was. Again in G: valve B "held" for one keyboard player so a solo tester
  could finish, so the user never saw it slip. Design for how the user
  actually plays.
- **Keep both on their toes (the user, G).** Each player can't see the
  other's side, needs what the other knows, and every mistake has a quick,
  funny consequence, often for the partner (the sludge tank bursting over
  the yard, slow motion until you rinse).
- **Connect the pieces.** A reward that pops out of nowhere (a jug at the
  tap) is weaker than using what you brought (P2's jug from the opening,
  filled at the tap, poured into the van).
- **Instructions in Naresh's words.** He came through every place days
  ahead: his notes say how things work, his "we" carries the twist; plain
  narration only for what you see and feel.

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

- **A tuning hack for one feel breaks another** (F1): the van's centre of
  mass sits below its floor so normal driving never flips it; so a van
  thrown onto its side by a storm gust rolled back up like a toy, every
  time, from 100 deg. The storm gives it a real van's centre of mass only
  once a gust has it past 70 deg (`Storm._tip_check`), and R puts both back.
- **Measure what the player ends with, not a peak:** "rolled past 60 deg"
  counted as tipped while the van was back on its wheels a second later.
  The check is where it comes to rest.
- **Grip that never limits doesn't change anything:** lowering the tyres'
  friction for a wet road made no difference to braking (the brakes, not
  the tyres, were the limit). Wet braking is the brake force itself
  (`Camper.WET_BRAKE`).
- **The headlights shone backwards into the cab from stage 1 to F1**
  (a SpotLight shines along its -Z; the van's nose is -Z, and the lights
  were turned 180 deg). Nobody saw it in daylight; the first dark storm
  shot did. Look at every new light in a dark shot.

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
