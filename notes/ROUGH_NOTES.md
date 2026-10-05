# Rough notes: everything learned, as it happens

The user's ask (2026-10-02): note down everything learned or changed, small
or big, about the code, the problem solving or the game, the moment it
happens; one rough file just for this. Cleaned up at the end of the project
and made more general (beyond game dev). Newest at the bottom of each
section. `notes/LESSONS.md` keeps the sorted, checked lessons; this is the
raw stream. **The mistake log ("Assumed -> reality -> fix") is at the end:
read it before starting something similar.**

## How to work (process)

- **Open-loop tests waste time** (the user, 2026-10-02). A test written as
  one long script, run blind, then judged from the log at the end: one early
  failure turns every later step red (the F3 sheet walk: Naresh never
  reached the jetty end, then 20 checks failed for that one reason and the
  walker stood on a roof for minutes). A human tester looks, acts, looks
  again, and corrects on the spot.
- **The plan agreed for testing from now on (2026-10-02):**
  1. a live control line into the running game (a command file the game
     reads every frame: one action at a time, the result and state and a
     screenshot back at once), so the walk is closed-loop: look, act, check,
     fix, go on;
  2. scripted runs stop at the first failed check (fail fast), keep the
     game open and leave it on the control line to look into it;
  3. a part walked live and working is then saved as its regression test.
  The test window stays behind the user's windows (the user likes that).
- **Prove the user's test sheet before handing it over** (2026-10-02): walk
  every step exactly as written, real keys and pad only, nothing set in
  code, no teleports the sheet doesn't ask for. The user found the F3
  binoculars missing after an F1 jump that my test had given in code
  (`q.has_binoculars = true`). A test that gives itself what a player
  doesn't have proves nothing.
- **Notes before the context fills** (the user, 2026-10-02): write
  everything worthwhile into the md files before a compaction; always.
- **Size the test to the change** (2026-10-01): a few-second throwaway
  check for a small change, not a rerun of a long test that happens to
  cover it. Long runs once, before the hand-over.
- **Time is the scarcest thing** (the user): more than tokens or machine
  time.
- **Two game instances at once are fine for logic, not for frame-rate
  checks:** the beach measured 108 fps beside another run, 143 alone.
- **Shell traps:** bash heredocs and sed mangle quotes, apostrophes and
  backslashes (`\n` in GDScript strings became real line breaks; a `'` in
  a Python string broke a patch). Write patch scripts with the file tool;
  use the edit tool for lines with backslash escapes.

- **Don't check every step that worked** (the user, 2026-10-02): v3 (one
  command at a time) made my think time the biggest cost; a human plays on
  and stops only when something that should have happened didn't. Next:
  the watched run (v4, `notes/TESTING_METHOD.md`): steps with expected
  outcomes, checked in parallel inside the game, stop on failure, resume
  from that step's save point. The general method: the skill
  `first-principles-solving` (D:\mine\Agentics\Skills).

## The test sheet (things a blind tester would hit)

- The F1 menu stays open after Enter: the sheet must say "then F1 (or Esc)
  to close it".
- An F1 jump to Bessi / return steps didn't give the binoculars (you'd have
  them from Last Fuel or the ridge lookout): jumps give them now
  (`DevMenu.BINOCULAR_STEPS`).
- The binoculars are **hold RMB / hold LT**; pad B is crouch (the user tried
  B).
- The flare gun's held prompt said "Throw": it says "Fire a flare" now.
- F3 walk (2026-10-02): from the beach, "Go and wait there" on the jetty's
  far end through the binoculars was accepted (82 m), but Naresh never got
  to the end of the jetty. Found live: he planned round the jetty through
  the shallows, because his path checks didn't see the world edge (moved
  to layer 64 in F3 so eyes see through it): his masks include 64 now.
- Found live: the open world had no drop points for taken players (only
  the gyms), so since Milestone D a taken player woke where they stood
  ("by here"). Drop points at 20 named places now.
- Found live: the sheet's F3 "walk in with Naresh ... keep your distance"
  can't be done: the creatures drift to Naresh, who follows you, so they
  come to you. The sheet must say to send him from the village's edge.
- Found live (the real reason he never reached the jetty end): aimed at the
  jetty's end through the binoculars, the look hit the near railing first
  and the go point landed 6 cm outside it, over deep water; he went to the
  nearest place he could reach (the shallows beside the jetty). A real
  player aims the same way. The rails are on the world edge's layer now
  (stop bodies, not eyes): the aim lands on the deck and he walks to the end.
  General: thin barriers (rails, fences) shouldn't catch aims.
- Found live: "on the jetty" was "inside its box", but the box is wider than
  the deck and the sand beside its start is as high as the deck, so coming
  down the beach he counted as on it, walked straight on and ended in the
  water outside the rail. The funnel has a "deck" footprint now (walkway +
  end platform); off the jetty he goes back to its mouth first too (heading
  for P2 on the beach he was stuck till the "Found a way round!" teleport).
- Found live: moving the jetty entry 0.8 m outwards froze both creatures at
  the mouth for minutes: a creature stops 0.3 m short of its goal, which was
  then outside the box, so the goal stayed the entry for ever. A target
  point and an arrive radius together decide where something ends up.
- Found live: P1 standing in the shed doorway as Naresh carried the light
  can out: he gave up ("I can't get there") and the decoy's mistake could
  never come (`_helped` stayed true). Now: a player within 2 m (was 1.4)
  is "in my way" (Excuse me!, he waits), and a failed trip is retried.
- Found live: once Naresh has been taken, the creatures come back to the
  shed side; the sheet's "nothing lost but time" needs: send him out on the
  jetty again before going back in (P1 was taken walking back in).
- The crate stairs work as the sheet says: one jump per step (6), then turn
  onto the roof. Jumping on a fixed 0.45 s beat missed steps (my driving,
  not the game): jump again once you've landed.
- P2's pad recall at 145 m through the binoculars works.
- Found live (open question): after the recall the creatures follow Naresh
  back to the shed (they drift to him), and P2 was taken by the shed while he
  did the light can. The decoy then only buys the time out and back. Ask
  the user: should they stay on the jetty a while (lose him), or is it right?
- The light-can retry works: "I can't get there", then "Hang on. The light
  one, to the van." and he carries it.

## The live control line (built 2026-10-02)

- `--playtest=live` (`tools/run_test.sh live` in the background) starts the
  world and waits; `python tools/live.py '<json command list>'` sends one
  step and prints the result, the messages and the state at once
  (`dev/LiveControl.gd` lists the commands: state, eval, wait, tap / hold,
  pad_tap / pad_hold / pad_axis, mouse, look, walk, job, menu, drive, shot).
  Positions: [x,y,z], "poi:<name>", or "expr:<expression on PlayTest>".
- In its first three steps it found three bugs a scripted run had buried.
- A frozen character can be a script error: Naresh stood still in GO
  because my jetty redirect called itself for ever (the entry is inside its
  own box: stack overflow, the frame aborted each time). Only the log showed
  it, so `live.py` now prints new `ERROR` lines from `appdata/live_run.log`
  after every step. Start the game with `tools/live_restart.sh` (quits the
  old one, starts it with its output in that log, waits for "ready").
- Windows: replacing cmd.json while the game reads it fails (access denied):
  the client retries.
- Look at the picture before theorising: one binocular screenshot showed
  Naresh beside the railing, which no position number had made obvious.
- An expression for `eval` runs on PlayTest: test-local variables (`fv`)
  don't exist there; use `get_tree().get_first_node_in_group(...)`.
- Out of earshot, a character's lines don't reach the players' speech
  signal: read his state changes in the log (`[naresh] GO -> WAIT`).
- Expression (the `eval` and `expr:` positions) has no `Vector3.UP` or
  lambdas: `Vector3(0, 1.1, 0)`. A bad position made `job` aim at nothing
  and it looked like the game's range bug ("Too far for Naresh..."); `job`
  now refuses a bad position. Check the tool before blaming the game.
- No pad plugged in: P2 is on the keyboard (solo, TAB). Plug one in the way
  the tests do: `eval boot._on_joy_changed(0, true)` (split screen, pad 0).
- The state shows the creatures within 150 m (where, doing what, how far
  from Naresh): the decoy is about distances, so watch them.
- `walk` steps aside (D / A) and goes on when stuck on a tree, as a person
  would.
- The watched run's first try: the watcher read Naresh once at the start,
  before the jump made him, crashed on it, and with it went every check;
  the steps carried on, waiting for watches nobody checked. A watcher must
  read what it watches fresh each tick and must not be the only thing that
  can stop the run (the step runner obeys the client's abort too). Who
  watches the watcher: the client, tailing the log for script errors.
- Resume from a save point works (F3.2 loaded and played on). But a game
  save holds no creatures, so after a resume they started elsewhere and
  "the shed side clear" passed at once: a check that passes too easily is
  as bad as one that fails. Save points now hold the creatures' positions,
  and the check also needs both creatures out on the jetty.
- A failure can be the plan's: "There's two!" came, but after 20+ s,
  because with a creature near Naresh stops to stare first ("Someone's
  watching us") and the trigger waits for that. Waiting at the shed also
  drew a creature onto P2. Plan fix: walk him past the shed and on, the line
  watched (60 s). Read the game's state before calling it a bug.

## The game / code (found on the way)

- Shared poi names collide silently: the village's `shed_roof` overwrote the
  water works shed's (its Memory Fragment moved). Prefix new places' names.
- A state flag must also put the world in that state (the swing bridge
  "locked" from a load never moved its span).
- The van needs a safety net (it could be squeezed through the ground and
  fall for ever): back to where it last stood safely.
- Old greybox can hide traps (the estuary bridge's deck edge was a step).
- `global_transform` before the world is in the scene tree is wrong: use
  `transform` (the world sits at the origin).
- An invisible wall blocks eyes too: the world edge is on its own layer (64).
- Scripted drivers: S on a stopped van is reverse; hold with the handbrake.
- A new chapter's tests change what old tests start from: the runner puts
  the return away before older tests (`_undo_return`).
- **Open, from the user's F3 play (2026-10-04), not fixed yet:**
  (1) P1 got out of the van to fill it, and moments later was flung across
  the map, spinning, no white flash (not a creature take), landing by the
  coast watchtower's creature near the beach. Suspects: a van knock
  (`Camper._check_pedestrians` -> `PlayerRig.knock`) with a huge impulse,
  or the exit spot inside the van's collider. The game log doesn't record
  player knocks: log them. (2) After an F1 → Story jump back to F3 the
  creatures were already after the van: the jump doesn't reset their
  interest in the van (`VanAttack`) or creatures away from their posts.
  - (2) **fixed** (2026-10-04): the cause was the stall's creature (it has
    no patrol, so the village's reset skipped it; left ~200 m up the road
    it was drawn to Naresh and came for the van). Now every jump puts each
    creature back at its post, calm (`Creature.back_to_post`, `home` =
    where it stood at its first tick), and one-off ones (`one_off`: the
    stall's, the F1 spawn) are removed. The van's damage was already reset
    by `repair_all`. Checked in `step_jumps`.
  - (1) **not reproduced yet.** Ruled out, measured: a take (a taken player
    wakes 150-400 m away; the coast watchtower is 706 m from the stall
    spot, and the fishing village's drop point is ~152 m from it, so a
    take there lands you in the village); getting out of a rolling van
    (doors stay shut above 2.5 m/s, the van only knocks at 2.5 m/s or
    more; tried 5.7, 9.7, 14.8 m/s: no exit, no knock); the van rolling
    away at the stall (flat there: 0.0001 m/s after 16 s, handbrake off);
    the pour with the handbrake off and P1 hugging the van (3 tries, no
    knock). Only the van can knock a player (`Camper._check_pedestrians`
    -> `PlayerRig.knock`); the knock's tumble is the "spinning". Now
    logged: `[knock] P1 thrown X m/s ... van Y m/s` and `[taken] P1 at
    ... by ...`, so the next time it happens the log says which. The
    user's log for the session ("TAKEN -> KNOCKED" for Naresh) is two
    state changes in one tick (fetched, then knocked by the driven van):
    the print only shows the first and last state of a tick.
- Recording a run (the user, 2026-10-04: "do F3 and capture a video, I'll
  review that"): Godot's Movie Maker, `--write-movie x.avi --fixed-fps 25`
  before the `--`. Measured: 30 fps recorded at 26.4 fps of wall time (88 %
  real speed); 25 keeps up. The watched run's deadlines and `Hearing`'s
  memory are in real time, so a recording must run at real speed.
  `Expression` can't reach `Engine` (eval "Engine..." errors).
  `tools/record_walk.sh <walk>` records a walk to `appdata/videos/<walk>.mp4`.
- **Assumed** the first recorded F3 failed ("the shed side clear" not in
  60 s) because recording slowed the game; then, from video length vs my
  guess of the wall time, that it ran *faster* than real time. **Reality:**
  Godot prints it when the movie ends: "recorded in 5:51 ... 84% of
  real-time speed" (encoding ~11 ms a frame); my wall-time guess left out
  the start-up. So the walk's real-time deadlines give ~16 % less game
  time, and the 60 s was tight anyway (0.9 m/s creatures, ~a minute by
  design). **Fix:** 90 s in `make_f3.py`. **Habit:** read the tool's own
  numbers (the movie summary in the log) before naming a cause; never
  tell the user a cause I haven't checked (I told them twice, wrong once
  each way).
- **Assumed** the recorded run's last step failed like the user's bug.
  **Reality:** P1 walked to the fuel cap hugging the van's side; the full
  can caught on the bodywork, fell out of the hands (`Carryable`
  SNAG_DISTANCE, by design) and the pour had nothing to pour. From the
  step's save point it passed (P1 started elsewhere). **Fix:** the walk
  goes 1.5 m out from the van first. Found by frames from the video at
  4 fps (`ffmpeg ... fps=4,tile=4x4`): the video is the best evidence.
- **Recorded F3-F8 (2026-10-04/05)**, all pass, videos in
  `appdata/videos/f3..f8.mp4` (game at 68-87 % of real time while
  recording). F7's first take failed at the generator: P1 at the cord
  stood in P2's line to the choke (the handles are ~1 m apart), so P2's X
  never reached it. Earlier passes were luck of where P1 stood. Fix: P2
  stands 0.6 m to the choke's side. **Habit:** two players at one machine:
  check each one's line to their handle isn't through the other. Things
  for the user to judge, seen only in the videos: the F6 gallery is
  nearly black with the torch off (too dark to follow?); in F8 the
  homecoming (his mother, his sister) is text only while both sit in the
  van facing the road.

## Assumed -> reality -> fix (my mistakes, so I don't make them twice)

The user (2026-10-02): a person remembers their mistakes on one problem and
is careful not to repeat them on the next. Models don't learn while they work
(no online learning: the weights don't change), so this log simulates it.
**Read it before starting something similar; add to it the moment reality
disagrees with what you assumed.** Each entry: what I assumed, what really
happened, the fix, and the habit to keep.

- **Assumed** (2026-10-06) the GitHub test run was worth keeping green.
  **Reality:** the user asked "why GitHub test again?": it had been red
  for 11 days unnoticed, duplicated the PC tests, and everything it found
  was in the tests (wall-clock timing on a faster machine, test order,
  headless has no textures). **Fix:** manual only. **Habit:** question a
  requirement before servicing it (who asked, what does it catch that we
  don't?), and stop as soon as the user says it doesn't matter now.
- **Assumed** (2026-10-06) I could edit a test while a long run went on
  (again). **Reality:** the same slip as the day before; it only compiled
  by luck. **Habit:** while a run goes, edit only in `../MPG_dev`.
- **Assumed** (2026-10-06) test timings in ms of the wall clock are fine.
  **Reality:** headless `--fixed-fps 60` runs faster than real time (3 s
  of game in 0.11 s): measure in physics frames.
- **Assumed** (2026-10-05) taking a jug off the van's rack worked anywhere
  (other tests took cans off it). **Reality:** with the van nose-up on the
  water works climb, the jug popped out 0.2 m up, inside the rack's bars,
  snagged (more than the snag distance from your hands) and dropped: the
  test saw "held: null". A frame-by-frame log on flat ground showed it
  working, which pointed at the van's pose. **Fix:** an item taken off the
  rack goes straight to your hands. **Habit:** when a step works in one
  place and not another, log it frame by frame in both before guessing.
- **Assumed** (2026-10-05) the test could reach the bench "from the yard
  side". **Reality:** that put the player inside the workbench. **Habit:**
  approach furniture from the room, not from a fixed world side.
- **Assumed** (2026-10-05) the pump house's old (painted-on) door was a
  doorway you could reach. **Reality:** the two intake pipes (solid, 0.95
  m high) run from the front wall to the river either side of it: the
  walk couldn't get there; the play-test teleported past it and passed.
  **Fix:** the doorway in the side wall facing the tanks. **Habit:** a
  decoration that becomes a way in gets walked to (the walk found it, the
  teleporting test didn't: the lesson "walk, don't teleport" again).
- **Assumed** (2026-10-05) appending helpers to PlayTest.gd during a
  background run was harmless. **Reality:** it was (only new functions,
  it still compiled), but the rule is there because later segments load
  the file fresh: a typo would have failed the rest of the run. **Fix:**
  checked the compile at once. **Habit:** check `tasklist | grep -i godot`
  before touching any game script; walk helpers can wait for the run.
- **Assumed** (2026-10-05) a variable name was free in a long test
  function (`stand`). **Reality:** a parse error ("already declared")
  that stopped every script depending on PlayTest. **Fix:** renamed;
  `--check-only` on each changed script after an edit. **Habit:** check
  the long functions' names before adding to them; compile right away.
- **Assumed** (2026-10-05) a script without `class_name`
  (`LevelLandmarks`) could be named in another script. **Reality:**
  "Identifier not declared". **Fix:** its constants through the class at
  the end of the chain (`LevelBuilder.TOWER_CATWALK_Y`). **Habit:** the
  LevelBuilder split's middle scripts have no class names.
- **Assumed** (2026-10-05) a Story jump was enough to replay a puzzle.
  **Reality:** the user did the water works once, jumped to it again, and
  found it still full: jumps reset only the Bessi / return state, never the
  way-out puzzles. **Fix:** every way-out puzzle has `reset()`; a jump to
  its step or before calls it; a new F1 **Puzzles** tab (all 16, reset + go).
  **Habit:** a test sheet that says "play it" needs a way to play it again.
- **Assumed** (2026-09-24, the cloud PR) valve B should hold for one player
  on the keyboard so a solo tester can finish. **Reality:** the user tests
  alone on the keyboard, so they never saw the slip: the feature looked
  broken. **Fix:** it slips for everyone (alone you walk over and turn it);
  only the play-test's older checks switch it off. **Habit:** the user's
  own way of playing (here: solo, keyboard) is the case to design for; a
  "solo exception" hides the feature from the person judging it.
- **Assumed** a test may give itself what the player gets (binoculars set
  in code). **Reality:** the user found none after an F1 jump. **Fix:** jumps
  give them. **Habit:** never set in code what a player must obtain in play.
- **Assumed** one long scripted run judged at the end was fine. **Reality:**
  one early failure turned 20 checks red; minutes lost. **Fix:** the live
  line, then the watched run. **Habit:** stop at the first failure.
- **Assumed** checking every step live was the careful way. **Reality:** my
  think time became the biggest cost (the user). **Fix:** the watched run:
  play on, checks in parallel, stop only on failure. **Habit:** spend my
  time on failures, not on steps that worked.
- **Assumed** Naresh's jetty problem was his path planner. **Reality:** the
  binocular aim hit the railing, so his goal was 6 cm outside it over deep
  water. **Fix:** rails on the world-edge layer. **Habit:** look at the
  input (the goal point) before fixing the thing that consumes it.
- **Assumed** "inside the jetty's box" meant "on the jetty". **Reality:** the
  box is wider than the deck and the sand beside it is as high. **Fix:** a
  deck footprint. **Habit:** a shortcut test (a box) must match the real
  shape where it matters.
- **Assumed** moving the jetty entry 0.8 m out was harmless. **Reality:** the
  creatures use the same entry, stop 0.3 m short of it, and that was outside
  the box: frozen for minutes. **Fix:** entry back. **Habit:** before
  changing a shared value, find every user of it; a target point and an
  arrive radius together decide where something ends up.
- **Assumed** my redirect couldn't loop. **Reality:** the entry is inside its
  own box, so it called itself for ever (stack overflow, Naresh frozen).
  **Fix:** a base case. **Habit:** when a function calls itself, write down
  what stops it.
- **Assumed** "Too far for Naresh to see what you mean" was a game range bug.
  **Reality:** my expression used `Vector3.UP`, unknown to Expression; the aim
  went nowhere. **Fix:** the tool refuses a bad position. **Habit:** check my
  own tool before blaming the game; make tools fail loudly.
- **Assumed** P2 was on the pad. **Reality:** no pad plugged in, P2 was on
  the keyboard and ignored pad input. **Fix:** plug one in as the tests do.
  **Habit:** check the setup (devices, layout) before the behaviour.
- **Assumed** the crate climb was broken. **Reality:** I jumped 5 times (it
  needs 6) and aimed diagonally into the wall. **Habit:** do it exactly as
  the sheet says before calling it a bug.
- **Assumed** `bc` exists in this shell. **Reality:** it doesn't; my watch
  loop never stopped and Naresh was taken. **Fix:** waits inside the game
  (`until`). **Habit:** keep logic out of shell glue; untested glue fails.
- **Assumed** a bash heredoc was safe for a patch with quotes. **Reality:**
  it broke, *for the second time*: the lesson was already written and I
  didn't read it. **Fix:** patches via the file tool. **Habit:** read this
  log before reaching for a tool that has failed before.
- **Assumed** the watcher could read Naresh once at the start. **Reality:** no
  Naresh before the jump; the watcher crashed, every check went with it, and
  the run hung. **Fix:** read fresh each tick; the step runner obeys the
  abort too. **Habit:** the watcher must not be the only thing that can stop
  a run.
- **Assumed** a check that passed meant the situation was right. **Reality:**
  "the shed side clear" passed in 0.1 s after a resume because saves hold no
  creatures. **Fix:** save points keep them; a stricter check. **Habit:** a
  check that passes too easily is as suspicious as one that fails.
- **Assumed** 20 s was enough for "There's two!". **Reality:** with a creature
  near, Naresh stops to stare first. **Habit:** deadlines come from the
  game's measured behaviour, not a guess.
- **Assumed** I could wait with `sleep`. **Reality:** the harness blocks long
  sleeps. **Fix:** run in the background and get notified. **Habit:** never
  poll; let the finished task call back.
- **Assumed** a point "by the shed" was close enough for Naresh's "There's
  two!". **Reality:** it was 23 m from the light can, the trigger is 25 m,
  and Naresh trailing P2 never got inside it (it only worked before because
  P2 stood still and he caught up). **Fix:** the shed door. **Habit:** plan
  points from the trigger's real radius, with a margin; read the trigger's
  code before placing the point.
- **Assumed** a step's plan could be fixed in that step alone (P2 "by the
  shed": first too far, then at the door, then behind the shed). **Reality:**
  three resumes, the same failure each time (taken within seconds): P2's
  route from the beach crossed the open sand in front of the creatures
  trailing Naresh back. The cause was the step *before* (where P2 stood when
  calling him). **Fix:** P2 goes into hiding first and calls from there; the
  resume starts from the step that set the position up. **Habit:** when the
  same failure repeats after resumes, the cause is upstream: go back to the
  step that set the situation up, don't keep patching the failing one.
  Also: an identical end state on every resume means it's deterministic;
  read it as a clue, not bad luck.
- **Assumed** every wait in my runner ended. **Reality:** after a resume a
  step `needs` a watch from a step before the resume point; nobody had armed
  it, so it waited 23 minutes, and Naresh, taken 1 s after the resume, went
  unflagged because the rules only covered players. I'd written down
  "a wait with no deadline" as a mistake an hour earlier, then built one.
  **Fix:** needs re-arm their watch from the plan; every step has a hard
  limit (300 s default); Naresh taken is a failure; a resume says what it
  put back. **Habit:** every wait gets a deadline at the moment it's
  written; every rule asks "who else could this happen to?".
- **Assumed** Naresh "dropping" the light can in the shed was a snag on the
  door frame (the old story: a can carried at the side snagged on a 1.4 m
  frame). **Reality:** a 10 s position trace showed his path was empty: the
  grid search only covers 45 m round the midpoint of him and the goal, and
  with the van 140 m off he wasn't even inside it, so he walked straight at
  the van, into the shed's inside wall, jumped, dropped the can, gave up.
  **Fix:** a far goal is planned in stages (45 m towards it, plan again at
  the end). **Habit:** trace the thing (positions, path size each second)
  before trusting the familiar explanation; a limit in a search (a radius,
  a node budget) is a silent failure for anything beyond it.
- **Assumed** the game's own save was a full snapshot for resuming a step.
  **Reality:** it's built for a player loading at the van: no creatures, no
  items in hand, Naresh put by the van. A resume with P1 holding the heavy
  can started empty-handed and failed in 2 s. **Fix:** the walk's save
  points add creatures, held items and Naresh's spot / state / leader.
  **Habit:** before reusing a mechanism for a new job, list what the new job
  needs from it and check each against what it really keeps.
- Found by the full F3 watched run (a game bug, not the plan): after his
  fuel mistake Naresh went into one of his little acts (wander off / stare
  at a creature) just as both players got into the van; he stayed in it,
  the creatures trailing him walked up, and he was taken. **Fix:** no
  wandering off with a creature within 60 m; any act on foot ends ("Wait for
  me!") the moment the player he's with sits in the van. **Habit:** random
  behaviour needs the same "is it safe now?" check as the planned kind; a
  feature that only ever ran in quiet places is untested where it's busy.
- **Assumed** "tap X" starts the engine. **Reality:** X toggles it; after a
  jump the engine was still running, so the tap switched it off and the
  "drive straight across" step never moved. **Fix:** the walks use
  `engine_on` (presses X only if it's off). **Habit:** never press a toggle
  blind: check its state, or use the helper that does. (Same family: the
  straight-line walkers walked P2 into the van's side; a person goes round.
  `round_van` now walks round the nose first.)
- F4 (salt pans) and F5 (swing bridge) pass as watched runs. Found on the
  way, both my tools': the straight-line walkers walked P2 into the van's
  side after a jump (`round_van`), and the auto-driver can't line up from
  where the F5 jump parks the van (6 m off the road's middle, 25 deg askew,
  20 m from the span): the walk backs up first, as a driver would. For the
  user's test that's fine; a jump could park the van straight on the road
  (a polish item, not a bug).
- **Assumed** class names work in a live expression (`SwingBridge.OPEN_DEG`).
  Checked first this time (the mistake log said Expression knows no
  `Vector3.UP`, `Input`, `Engine`): it doesn't; the plan uses the numbers.
  The log paid for itself here: caught before a run, not after.
- Found by the F6 watched run (a game bug): the gallery's creature went for
  the van through the gallery wall. From close by (VanAttack.NEAR) a
  creature senses the van with no sight line, so standing in the gallery
  9 m from the van in the tunnel it switched to VAN and stood against the
  wall for good: the gallery could never be crossed as designed. The old
  test switched it off (`dormant`) while the van was there, so it never
  showed. **Fix:** one that keeps its post never goes for the van.
  **Habit:** a test that turns a hazard off to get past a step hides every
  bug in how that hazard meets the rest of the world.
- Found by the F6 watched run (a game bug): the gallery's creature went for
  the van through the gallery wall. From close by (VanAttack.NEAR) a
  creature senses the van with no sight line, so standing in the gallery
  9 m from the van in the tunnel it switched to VAN and stood against the
  wall for good: the gallery could never be crossed as designed. The old
  test switched it off (`dormant`) while the van was there, so it never
  showed. **Fix:** one that keeps its post never goes for the van.
  **Habit:** a test that turns a hazard off to get past a step hides every
  bug in how that hazard meets the rest of the world.
- **Assumed** an edit had applied because the next command ran. **Reality:**
  the edit tool refused (file not read yet) and I chained the restart and
  the run straight after it in the same breath: a run on the old code, and
  a note that never got written when I stopped it. **Habit:** read each
  tool result before the next dependent step; don't chain a run onto an
  edit whose result I haven't seen.
- Found by the F6 watched run (a game bug): the gallery's two side
  passages reach 9 m out past the gallery, into the hill beyond the
  tunnel's slot in the terrain (flat only to 11 m from the road), so the
  hill filled their far ends: P2 walked up onto terrain inside fork 1, and
  fork 2's flare gun sat in it. The old test put the player beside the gun
  by code, so nobody ever walked down the passage. **Fix:** flat pads at
  road height where the passages run (`RailTunnel.fork_pads`, handed to the
  terrain with the other pads). (Polish: from the hill above, that's a pit.)
  **Habit:** when two systems build the same space (the terrain's slot, the
  gallery's walls), check where one ends and the other begins; a dark
  screenshot says nothing, so read the collider and the height you stand at.
- Found by the F6 watched run (a game bug): the flare gun's red case had
  no collider, so the gun fell through its lid and lay inside the case's
  box: a player would see a red box and no gun. **Fix:** the case is solid.
  And my plan's: P2 stopped 2.2 m off (out of reach) with the torch off,
  where the sheet says you find it by torchlight. **Habit:** a dark
  screenshot is no evidence either way; compare heights (the gun 1 cm under
  the floor top = it fell) before believing what you can't see.
- **Assumed** (again) a class name works in a live expression
  (`PhysicsRayQueryParameters3D.create`). The mistake log already said it
  doesn't; I didn't read it before typing. **Fix:** a probe helper on
  PlayTest (`ray_hit`). **Habit:** before any live expression, the rule is
  "instances and helpers only, no class names, no constants". Also: a bad
  eval writes ERROR lines to the log, and a running walk aborts on those:
  never eval during a walk.
- **Assumed** a flat pad just covering the side passage flattens it.
  **Reality:** the terrain is a 5 m grid; a cell corner outside the pad
  still raised a 2 m ridge across the passage (the triangle slopes between
  corners). The probe (`ray_hit` down through the passage) showed it.
  **Fix:** the pad reaches a cell and a half past the passage. **Habit:**
  any shape cut into a grid must allow one cell (better its diagonal) of
  margin; probe the result, don't trust the radius.
- F7 (mast) found: the jump gave no flare gun though the sheet says fire
  one (jumps past the tunnel hand it to P2 now); the sheet's "tell him
  again" on the dish crank doesn't say how: while he holds it the wheel
  offers only "Let go of it" (it counts as telling him), then Hold again
  (the old test told him in code). Sheet updated. And my plan: to climb
  down you must stand at the ladder's top (the gap in the rail), not look
  at it from across the platform.
- Found by the F8 watched run (a game bug): you couldn't get into the van
  holding the flare gun. Holding anything, E / X at a door means "drop", so
  the first press dropped the gun on the road and the second got you in:
  the gun stayed behind at every boarding (in the tunnel too), and by the
  mast you had none. **Fix:** holding the flare gun, the door says "Sit in
  the ... seat (the flare gun on the rack)" and getting in puts it on the
  rack's any-item slot. (Cans unchanged: they go on the rack by hand.)
  Also my helpers: a press that doesn't take is pressed again, as a person
  would. **Habit:** an item that must last across chapters needs a test
  that carries it across a chapter's ordinary actions (boarding, jumping),
  not one that hands it over at each step.
- **Assumed** (a third time) a Windows path with backslashes would survive a
  Python snippet in a bash heredoc. **Reality:** `\U` in "C:\Users" is a
  unicode escape: a syntax error. The log already had this one twice.
  **Fix:** the file tools (Write a .py file, or the edit tool). **Habit:**
  any text with backslashes goes through a file, never inline; this one is
  now in the memory note too, where it's read at every start.
- The user's skills folder moved (2026-10-03): the skill is at
  `D:\mine\Agentics\Skills\skills\first-principles-solving\SKILL.md`, and
  `D:\mine\Agentics\Skills\project-guides\finding-naresh\` keeps copies
  of CLAUDE.md, AGENTS.md and four notes (listed in "update the md files").
- **Assumed** a step that passed after a resume would pass in a run from
  the start. **Reality:** F6's flare gun failed in the back-to-back run: P2
  came from the gallery still crouched, and my `look_at_point` aims from
  standing eye height, so it looked over the gun (no prompt). The resume
  had started uncrouched, so it passed. **Fix:** the helper aims from the
  real eye height. **Habit:** a resume proves the step, not the way into
  it; the run from the start is the proof. State a resume doesn't carry
  (crouch, held buttons, a running engine) is exactly where it lies.
- The back-to-back run (`tools/live_all.sh`) passed F3 (clean from its
  start at last), F4 and F5 on the first try.
- The full suite after the walks' fixes: 381 checks passed through the
  whole-return drive; the world part failed in two older tests:
  - t_tunnel: the flare gun "not picked up". Not the game: the test aimed
    while P1 was still dropping from `place_player`, the view settled low,
    and the now-solid case caught the look (before, the low look found the
    gun lying inside the case). Wait to land, aim at the gun where it is.
  - t_decoy: a real game bug: a creature stood wedged against the shed's
    crate stack for good (it walks straight, no path planning), so the shed
    side never cleared. Logging every creature's spot / state / goal every
    10 s in the test showed it at once. **Fix:** creatures that want to
    move but haven't for 1.5 s step aside for 1.6 s, alternating sides.
  - t_decoy: after Naresh's mistake the van died 128 m up the road (wanted
    "a couple of hundred"): the fuel left allowed no idling while everyone
    gets in. **Fix:** + 20 s of idle fuel (it now dies ~185 m on).
  - Open question: once in three runs P2's D-pad recall through the
    binoculars didn't take (he stayed in WAIT, the look was on him). Twice
    since it passed; the test now logs the wheel, the jobs, the commands
    given and whether P2 had landed, so the next miss explains itself.
- **Habit (again):** when an old test fails after a change, ask first
  whether the test leaned on the old behaviour (placing, aiming while
  falling) or the game broke; both happened here, one of each kind.
- All six walks passed back to back in one go (F3-F8, 24 min) with every
  fix in (2026-10-03).
- The decoy test passed alone every time but failed inside the long world
  run: the village creatures were wherever earlier tests left them (one
  34 m off, nothing noticed for 1553 s) and an F1 jump didn't put them
  back, so one was never drawn to Naresh. The user hits this too if they
  jump to F3 after playing elsewhere. **Fix:** a jump or load to the
  village step puts its two back at their posts, calm (`Creature.calm`).
  Open: after the stall, the full can wasn't on the rack in the long run
  only; the test now logs the rack's contents when that happens.
- **Habit:** a test that passes alone and fails in a sequence is telling
  you about state that outlives a scene change; that state usually also
  outlives a player's own jump or load. Fix it in the game, not the order.
- The background tool stops a task after its time limit: the long world
  run gets stopped part way; `tools/run_test.sh resume` carries on from
  where it broke off. Plan long runs as resumable segments.
- After the earlier scenarios (jumps, boat, storm, storm road) a village
  creature stood frozen at the foot of the shed's crate stack (x 1722.6,
  the same spot twice) and even the sidestep didn't free it: no direction
  free, so it was caught inside the crate's collider. **Fix (a safety net,
  as Naresh's "Found a way round"):** three sidesteps that don't free it,
  it hops 1.2 m back out. The sequence passes now (clear after 24 s).
  **Open:** how it got inside the crates (a jump moving it? the stacked
  crates' shape?); the safety net covers the player either way.
- **The test sheet must read like a friend telling you** (the user,
  2026-10-04): "south-west corner", "away from the jetty", and "Follow me" +
  "stay there" in one step made no sense to them. Now each step is one
  plain sentence of what and why ("hide by the shed and call him back to
  you before the creatures reach him"), then *Exactly how* (optional:
  buttons, steps from a landmark: "back to the shed door, 10 steps ahead,
  10 to the right") and **You should see**. Landmarks they can see (the
  van, the huts, the shed door, the crates, the jetty), left / right from
  where they stand, never compass points. Two players, as the game is
  meant; no solo version needed. Later: a screenshot per "you should see"
  (POLISH).
- **Assumed** a sheet I'd proven step by step was followable. **Reality:**
  proven to work isn't the same as understandable: the walk proves the
  game, not the words. **Habit:** read each step as someone who has never
  seen the code: can they find every thing it names on the screen?
- The user read F3 step 4 as "send him back out to the jetty" because the
  "if he's taken, send him out again" fallback sat inside the step: the
  last command in a step reads as *the* command. Fallbacks now live in
  their own "If something goes wrong" note after the steps.
- Reviewing F4-F8 the same way found: F6 told you to flatten the battery
  *before* driving to the slope (a flat battery can't drive there); F6's
  "the second side passage (past the gate)" named something you can't see
  from inside the passage (now: past the FLOOD GATE WINCH sign); F5 didn't
  say to let go of the wheel before asking Naresh again; F7 didn't say
  what to do if you let go of a dish off its light (hold again: it comes
  round); F8's "Tower Road" isn't signposted (now: a side road on your
  left towards a tall wooden tower). Every "who does it" now says P1 / P2.
- **Habit, for any instructions:** one step = one goal; the order of the
  lines = the order you act; fallbacks after, never inside; name only
  what's on screen; check each step is possible in the state the previous
  step leaves you in (the battery!).
