# Stage 1: the Claude auditor's 7 ideas

Written 2026-11-05 by the Claude auditor, alone, before seeing the GPT auditor's.
Brief: `notes/TEST_METHOD_RESEARCH.md`. Aimed at: `notes/method_research/scoreboard.md`.

Every claim has a source (file:line, a log, a measurement) or says **"I think"**.
Evidence rows are numbered so the audits can point at them:

| # | Evidence row (brief) | Type |
|---|---|---|
| E1 | 5 of 8 takes lost to typos / bad expressions in `make_ramp.py` | false alarm |
| E2 | Drive-off only pressed forward, van hit a tree, landed in a different place each run | false alarm |
| E3 | `_on_joy_changed(0, false)` at a test's end paused the game; later tests failed, then froze | false alarm |
| E4 | "Back on the road" failed 15.8 m off: the bot circled | false alarm |
| E5 | Walk passed, video ends with the van stuck at a tree | **false pass** |
| E6 | Leg-up check passed with P2's pad off | **false pass** |
| E7 | 6 asked, 4 ran (`save` reloads), summary said 0 failures | **false pass** |
| E8 | Frozen test: the user saw it first | watching failed |
| E9 | "A swimmer slowed the van": it was the van rolling | wrong blame |
| B0 | Baseline: flat out missed at 66.5 km/h, 1.05 m off the middle, roll 14.5 deg; cause not measured | open |
| P1-P7 | The practice set (scoreboard) | real bugs |

---

## 0. What I found in the code before writing (facts the ideas lean on)

These shaped the ideas; the referee may want them independently of which idea wins.

1. **The same jump lands 4 / 4 in another test.** `appdata/ramp.out` (`ramp_retry`, 2026-11-04,
   after the handbrake fix): flat out straight after a miss, **66.2 km/h, 1.00 m off the middle,
   landed, four times with the same numbers** (lines 38-100). The baseline `t_ramp`: 66.5 km/h,
   1.05 m off, **missed** (`seg_1.log:41-43`). The bench (`appdata/ramp_bench.out:77-81`, fresh
   `ramp_start` each try): 66.7 km/h, 0.86 m off, landed. So: (a) the physics repeats closely from the
   same start (same numbers 4 times); (b) the miss is not explained by speed or offset alone.
2. **What differs between `ramp_retry` (lands) and `t_ramp` (missed):** `t_ramp` seats P2 as passenger
   with a direct `q.enter_seat` (`PlayTest.gd:11715`), stows a can (`11712`), waits 0.3 s
   (`11723`); `ramp_retry` leaves P2 outside (`12092`) and releases the handbrake at once. A seated
   player's collider is disabled (`PlayerRig.gd:1916`) and a stowed can is frozen with no collision
   (`Carryable.gd:212-216`), so **I think** neither adds weight to the physics. Cause still open.
3. **"Rolled 14.5 deg" may be after the miss, not its cause.** `ramp_try` keeps the max pitch / roll
   over every frame with `l.z < 2.0` until the miss registers (`PlayTest.gd:11598-11600`), and the game
   registers a miss only once the van is 1.3 m below the deck (`RampJump.gd:362`). So the numbers
   include the fall.
4. **The game doesn't say where a miss happened.** `RampJump.gd:591` prints only the lip speed. The
   "shallows" test (`:362`) has no far limit on `l.z`; the landing test (`:357`) needs a wheel touching
   past `-gap - 0.8` and inside `deck_w/2 + 1`. Short in the gap and touched-down-then-dropped look the
   same in the log.
5. **The test driver steers bang-bang until 1 m before the lip.** `ramp_try` calls `ad.step` while
   `l.z > 1.0` (`PlayTest.gd:11594`); `AutoDriver` presses full A or D outside a 0.05 rad dead band
   (`:7500`) at a look-ahead of `4 + 0.55 * v` points (`:7495`). At 18.5 m/s that's ~14 points; at
   ~2.09 m a point (`ROUGH_NOTES`, 2026-10-19) the dead band is about +-1.4 m sideways (I think). A
   full key press on the ramp itself, at 66 km/h, is something a careful human might not do.
6. **The run-up bends.** In the gap's frame the road is 6.4 m off-axis 50 m back and 19.2 m off at
   78 m (`ramp_bench.out:36`). Only the last ~30 m are straight.
7. **Tests keep stepping through a paused game.** `PlayTest.wait` uses a timer that runs while paused
   (`PlayTest.gd:217-218`, `create_timer(s, true, ...)`) and `PlayTest` is `PROCESS_MODE_ALWAYS`
   (`:40`). That is E3's mechanism: checks ran against a frozen world.
8. **The run summary never compares asked with ran.** `tools/run_test.sh:108-113` counts `done` lines;
   nothing lists what was asked (E7's mechanism).
9. **The game already owns success predicates.** `Story.gd:93-101`: `bridge` is done on
   `flags["ramp_jumped"]`, `wheel` on `not camper.wheel_off`, `cross` on the van within 60 m of POI
   `j3`. These are the game's own "it worked", written before any test.
10. **Set state inside today's "proven" part:** `q.enter_seat` (`PlayTest.gd:11715`), `place_player` /
    `face_point` all through the hut part, the wheel moved by code (`:11884`), and the walk sets the
    wheel's position by `eval` (`make_ramp.py:132`). By S5 today's `t_ramp` proves the jump and little
    after it.
11. GodotPhysics3D (`project.godot:37`), 60 Hz physics. Two game copies can run at once (brief).

---

## Idea 1: The rig-checked verdict (test health first, then the game)

**One line:** before any check may say "game problem", the run proves the test rig itself was alive,
in control and honest; anything else is reported as "TEST problem" or "NOT PROVEN".

### How it works
A layer under every scenario and walk, inside the engine plus one outside watcher. Five parts:

1. **Heartbeat (outside + inside).** `PlayTest` writes one line a second to `progress.txt`: physics
   frame count (`Engine.get_physics_frames()`), `get_tree().paused`, scenario, step. The outside
   watcher (`run_test.sh` / `live.py`, line-buffered) fails the run if the frame count stops for
   10 s, if `paused` is true without a step that allows it, or if the file stops growing for 30 s.
   Inside, every `wait` / `until` refuses to run while the tree is paused unless allowed: it logs
   `RIG: game paused (since step X)` and fails at once (fixes fact 7).
2. **Command -> effect ledger.** Every injected input is checked one tick later on the **intended
   player's** `InputDevice` (`players[i].dev.held(action)`), and where cheap, on its body: a jump
   must give upward velocity within 0.3 s, W on foot must move the player 0.2 m within 1 s, the
   throttle must raise `engine_force`. If the device never saw it: `RIG: P2's input never reached P2
   (device is KBM)` = test problem. This is the skill's "requested / accepted / applied" rule.
3. **Declared preconditions per step.** Each step starts with `need:` lines (P2's device is a pad,
   the actor exists and is in the tree, the van at the run-up with the engine on, nobody swimming).
   A failed precondition = test/setup problem, reported before any action.
4. **Expression and plan lint, before the run.** Every walk `expr:` is parsed and executed once on the
   loaded world (`Expression.parse` + `has_execute_failed()`) before step 1; every scenario name is
   checked against `t_<name>` methods; a plan with anything after `save` is refused. The summary line
   becomes "asked 6, ran 6" and differs = failure.
5. **Set-state counter + controls.** Helpers that set state (`place_player`, `face_point`,
   `enter_seat`, `global_position =` via a wrapper, `eval` setters) log `SET` lines. A step marked
   `proven` that has any `SET` line cannot report PASS: it reports `NOT PROVEN (3 set-states)`. Each run
   also starts with a **negative control** (a too-slow try must miss) and a **positive control** (20 m on
   a flat road must move the van 20 m). A failed control makes the whole run `INVALID: rig`.

**Pass/fail:** three verdicts, not two: `GAME?` (inputs confirmed, preconditions met, controls good,
the outcome wrong), `TEST` (anything in 1-5 failed), `PASS` (proven steps passed with no `SET` lines).
The outcome checks themselves use the game's own predicates where they exist (fact 9) instead of
test-written expressions.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | **caught, as TEST, in seconds** | Lint runs every `expr:` before the take starts. Not every bad value is a crash, though (a wrong-but-valid expression still passes lint). |
| E2 | not caught | Lint and heartbeat can't see a bot driving into a tree. A stall rule would say "van not moving", not why. |
| E3 | **caught, as TEST** | `wait` / `until` refuse a paused tree: "RIG: game paused since step X". |
| E4 | not caught | The bot circling is "inputs reached the van, outcome wrong" = `GAME?`: **wrong blame risk.** |
| E5 | partly | Only if the last step's outcome is the game's `cross` predicate (fact 9), not "wheel on". The layer pushes that way; it doesn't force it. |
| E6 | **caught, as TEST** | Command -> effect: P2's jump never reached P2's device. |
| E7 | **caught, as TEST** | Plan lint refuses anything after `save`; asked vs ran in the summary. |
| E8 | **caught within 10-30 s** | Heartbeat on frame count and file growth, not on FAIL lines. |
| E9 | not caught | Blame between two game causes isn't its job. |
| B0 | **not decided; risk of wrong blame** | Inputs reached the van, preconditions held, so it would say `GAME?` with the numbers. That label is honest ("?") but it does not tell game from test here. |
| P1-P7 | mostly not by itself | It is a rig layer; it finds game bugs only through the outcome checks it hosts. P1 is caught if the flat-out-after-a-miss outcome is checked. |

### How it fails (my own harshest critique)
- **False pass:** a test can still check the wrong outcome with a healthy rig (E5). The layer makes
  passing-for-nothing hard; it doesn't make the outcome checks right.
- **Wrong blame:** `GAME?` for anything the rig can't see in the driver's behaviour (E4, B0). It only
  splits "rig broken" from "rig fine"; a working rig with a bad driver still blames the game.
- **False alarm:** command->effect thresholds (0.2 m in 1 s) fire when a player walks into a wall on
  purpose; each needs an `allow`.
- **Cost of discipline:** every helper must go through the wrappers or the `SET` counter lies by
  omission. A direct `x.global_position = ...` in a test bypasses it (the counter can't see raw
  assignments; I think a grep in the lint is the only guard).

### Cost in the user's real time
- Per run: ~0 extra (it runs alongside); lint ~2 s. Reading: one verdict line per scenario.
- Build: I think 1-2 h for heartbeat + paused guard + asked/ran + lint; another 1-2 h for
  command->effect and the `SET` counter across helpers.
- No model in the loop.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| neutral: adds no false alarms I think, removes none from the driver | low alone (host only) | **T1, T2, T3: 3/3 I think** | **N1-N4: 4/4, <30 s I think** | **makes S5 measurable** (the `SET` counter); doesn't create a real path | ~0 per run | carries to any puzzle unchanged (it's under the tests) |

---

## Idea 2: Counterfactual blame (on a failure, change one thing and run again)

**One line:** when a check fails, the harness reruns just that stretch in a few variants, each changing
one factor, and the pattern of which variants flip says "game" or "test".

### How it works
In `PlayTest.gd` a helper `diagnose(stretch, variants)`, used only after a failure:
- A **stretch** is a re-runnable unit with a declared start (for the ramp: "a try from the run-up",
  `ramp_start()` or the game's own post-miss reset) and an outcome predicate (`r.jumped`).
- **Variants**, each changing one thing, each run twice (fact 1 says the physics repeats closely, so
  two agreeing runs are meaningful; two disagreeing = flaky, reported as such):
  - V0 the same again (is it repeatable?);
  - V1 a fresh declared setup instead of the inherited state (`ramp_start` instead of after-the-miss);
  - V2 another actor: a second driver with a different steering style (steering held straight in the
    last 30 m, or proportional pad steering via `JoypadMotion` on a pad driver);
  - V3 a load factor removed (P2 out of the van; nothing on the rack);
  - V4 the same stretch on the last known-good commit, in the other copy (`MPG`), if one exists.
- **The rule table** (written before any trial):

| Pattern | Verdict |
|---|---|
| fails in V0-V3 | GAME (the outcome doesn't depend on the test's choices) |
| passes when only the driver changes (V2) | TEST: the driver |
| passes only with fresh setup (V1) | **STATE**: then ask "can a player reach the inherited state?" After a miss, yes (the game's own reset) -> GAME bug (like P1). After a test-only step -> TEST |
| passes when a load is removed (V3) | GAME if a player can have that load (P2 aboard, can on the rack): a real-play bug |
| V0 disagrees with the first run | FLAKY: the measurement is wrong (skill §5), no verdict |
| passes on V4 (old commit) | GAME: a regression, and `git diff` names the suspects |

- Every variant logs the same sensor line (lip speed, offset, yaw rate and roll **at the lip**, where
  the miss fired: facts 3 and 4), so the table carries numbers, not just pass/fail.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | not caught | A script typo fails every variant identically -> it would say GAME. **Wrong blame** unless Idea 1's lint runs first. |
| E2 | **blamed right** | V2 (another driver) gets away from the tree -> TEST: the driver. |
| E3 | partly | Paused game: every variant fails -> GAME. **Wrong** without Idea 1's pause guard. |
| E4 | **blamed right** | V2 with a different driver reaches the road -> TEST: the driver. |
| E5 | not caught | It only runs after a failure; a false pass never triggers it. |
| E6 | not caught | Same: no failure, no diagnosis. |
| E7 | not caught | Same. |
| E8 | not caught | Same. |
| E9 | **caught** | "A swimmer slows the van": V3 (P2 out of the water / not there) still crawls -> the swimmer isn't it; V1 (fresh setup, handbrake) fixes it -> STATE after a miss, reachable by a player -> GAME, pointing at the reset. That is what `ramp_retry` found by hand. |
| B0 | **this is what it's for** | V0: does 66.5 / 1.05 miss again? V1: `ramp_start` instead of after-the-miss. V2: straight-held steering. V3: P2 out, no can. Fact 1 already says `ramp_retry` (P2 out, no wait) lands 4/4: I think V3 or V1 flips it. If V3 flips it, a passenger making the jump miss is a **game** bug the user hasn't seen (they haven't played "P2 aboard"? unknown). If only V2 flips it, it's the test's steering. |
| P1 | **caught and named** | Flat out after a miss fails; V1 (fresh) lands -> STATE after the game's reset -> names the reset. |
| P2-P7 | not its job | It explains failures; it doesn't find them. |

### How it fails
- **Inconclusive when the cause is outside the variants.** The table only tests the factors someone
  thought of. A cause no variant touches gives "fails in all -> GAME", which may be wrong.
- **The alternative driver can have its own bug** (it's another test actor): V2 passing could mean the
  second driver cheats (e.g. holds speed differently). Both drivers must use real input only and log
  the same sensors.
- **State capture.** `SaveGame` doesn't keep velocities, wheel spin, steering (`_steer`), heat (LiveControl
  adds held items and Naresh only, `LiveControl.gd:439-447`). V0/V1 from a save point may not be the
  same start. On the ramp this is fine (each try starts from a declared spot); on longer stretches it
  is a real limit.
- **Cost on flaky physics:** if V0 disagrees often, each variant needs 5+ runs and the cost multiplies.
- **It runs after failures only:** it does nothing against false passes (E5-E8).

### Cost in the user's real time
- Only on a failure. A ramp try is ~9-10 s of game (`ramp_bench.out`, `t` 8.8-10.3 s) + ~2.4 s reset
  (`RampJump.gd` fade 1.8 + 0.6 s). 5 variants x 2 = 10 tries = **~2 min**. For a hut-part stretch I
  think 1 min per try, ~10 min per diagnosis.
- Build: I think ~1 h on the ramp (the tries exist: `ramp_start`, `ramp_try`); a second driver ~1 h.
- Reading: one table. No model in the loop (the table is decided by the rule above, not by a model).

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| **cuts false alarms** that are driver-made: I think B0 becomes a diagnosed verdict, not a red | P1 named; others only explained | T1-T3: **0/3 alone** (it blames the game for a broken rig); 3/3 with Idea 1 under it | 0/4 alone | neutral; V1 uses a declared setup, which is fine | +2 to +10 min **only on failure** | needs a stretch + variants per puzzle: I think 1-2 h each |

---

## Idea 3: The game checks itself (always-on invariants, in every play)

**One line:** the game objects carry their own "this must never be true" rules, checked at a few Hz in
every play (tests, walks, and the user's own play), so a bug is caught where it is, named by the
object, however the play got there.

### How it works
- A dev-only `Invariants` node (on unless a release flag is set), 5 Hz, plus build-time checks once
  after the world is built. Each rule is local, stated as the real thing, and names its object:
  - `Camper`: `wheel_off` => bare hub visible, wheel mesh hidden, and the HUD text is not PUNCTURE
    (**P7**); a ray down from each hub: hub bottom not below the ground (**P6**).
  - `PlayerRig`: `swimming` => in the river band and below `water_y + 0.3`; on dry land for > 1 s
    while swimming = fail (**P3**).
  - "Put down here" spots that a puzzle declares (the crate's place under the window) must be clear of
    solids: a shape query once after build (**P4**).
  - Every door a player must walk through: a capsule step test from 1 m outside to 1 m inside; any
    rise above the player's step height = fail (**P2**).
  - Things a puzzle declares as "seen from X" (the wreck from the ramp's top): its top above
    `water_y` and a ray from X reaches it (**P5**), plus a static lint: no `global_*` in `_build*` /
    `setup` functions (the class of bug behind P5, `ROUGH_NOTES` 2026-11-04).
  - After any game reset (`_fail`): nothing put down by the reset may move > 0.5 m in 2 s with no
    input (**P1**: the van rolling off its spot).
  - Generic: nothing that should move stands still (the watcher's rule, moved into the game), no
    carryable below the terrain, the tree not paused unless the pause menu is up.
- A failure prints `[invariant] <object>: <rule> (<numbers>)` and, in a test, fails it. The test then
  only has to get there; it no longer has to predict what to check at each moment.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1, E2, E4 | not caught | Test-side problems; invariants watch the game. E2/E4: "van still with throttle" would fire, i.e. **blame the game** (wrong). |
| E3 | partly | "paused with no pause menu" fires; but the pad-lost pause shows a pause note, so it is a correct game pause: the rule must allow it, then it's silent. |
| E5 | not caught | A van stopped at a tree with nobody pressing anything breaks no rule. |
| E6, E7, E8 | not caught | Rig problems. E8 partly: a frozen tree stops the 5 Hz check too; only an outside heartbeat sees it. |
| E9 | partly | It doesn't blame; the post-reset rule would have shown "van moved 30 m with no input after the reset", which points at the real cause. |
| B0 | not caught | No invariant broken: a miss is legal. |
| P1-P7 | **I think 7/7 caught and named**, each by its rule above | But see "how it fails": these rules were written knowing the bugs. |

### How it fails
- **Written to the practice set.** I wrote these rules after reading P1-P7. That is exactly Theo's
  "climbing the public bench". The final exam's secret bugs will test whether the *generic* rules
  (below ground, floating, state vs visual, stuck, swim on land) generalise. I think half of them will
  fall outside any rule written in advance.
- **False alarms on transient states:** mid-animation, mid-snap (`snap_wheel` changes the mesh and the
  HUD in different frames), a player half-climbed out of the river. Every rule needs a debounce, and a
  debounce long enough is long enough to hide a short-lived bug.
- **Can't prove completion.** It says "nothing broken where we looked", never "the stretch worked".
  It must ride on top of something that plays the stretch.
- **Cost in the game:** 5 Hz rays and shape queries are cheap (I think < 0.1 ms) but it is dev code in
  game scripts; it must stay out of a release.

### Cost in the user's real time
- Per run: ~0. It also runs while **the user plays**, so their playthrough reports bugs for free.
- Build: I think 2-3 h for the ramp's rules; 1-2 h per new puzzle.
- Reading: one named line per broken rule. No model.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| risk: debounce-tuned false alarms; I think 9/10 before tuning | **practice 7/7 caught + named (I think)**; secret: unknown, maybe half | 0/3 (not its job) | N1/N2 partly, N3 maybe (a rule "both players exist"), N4 no | **pass**: it doesn't move anyone | ~0 | generic rules carry; puzzle rules cost 1-2 h |

---

## Idea 4: The envelope (many varied plays, judged by properties, failures shrunk)

**One line:** instead of one predicted path, sample many plays across the space a player could do, and
judge the set against properties taken from the design's own numbers; a counterexample is shrunk to
the smallest change that flips it.

### How it works
- An in-engine sampler (the bench pattern: `t_ramp_bench`, `PlayTest.gd:11624`) runs N tries from
  declared starts, each with a sampled point from: target speed 50-80 km/h, lane -2..+2 m, steering
  style {bang-bang now, straight-held last 30 m, tap-pulsed}, P2 aboard / outside, rack empty / can,
  start fresh / after a miss.
- Each try logs the same sensors at fixed moments: lip speed, lateral offset, yaw rate, roll and pitch
  **at the lip** (not over the fall: fact 3), where the miss fired (fact 4), landing speed, rest point.
- **Properties from the design page** (`design/PUZZLE_CHANGES.md` "The ramp jump", measured bench
  numbers), with a grey zone left unjudged:
  - lip < 56 km/h => miss, back at the run-up on the handbrake, nothing lost;
  - lip >= 61 km/h and |offset| <= 1.5 m (the ramp is 5.6 m wide, the van 2.6 m) => lands upright;
  - the try right after a miss reaches >= 64 km/h at the lip (P1);
  - from every landing spot: wheel on, then the story reaches `cross` within T (the drive-off, E2/E4/E5).
- A counterexample is **shrunk**: bisect one factor at a time towards a passing neighbour (speed,
  offset, style, load) until the smallest flip is found: "flat out, 1.05 m off, P2 aboard: miss; P2
  out: lands". That line is the report.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | not caught | No hand-written expressions in the sampler; but a broken sampler fails all N (looks like a game break unless controls are run). |
| E2 | **caught as a property failure with its spread** | Different landing spots are sampled on purpose; "reaches `cross` from every spot" fails at the tree spot; shrinking says "the spot", and a second steering style says "the driver". |
| E3 | not caught | |
| E4 | partly | The drive-off property fails; the shrink can separate the driver only if two driving styles are in the sample. |
| E5 | **caught** | The property is the game's `cross` predicate, not "wheel on". |
| E6, E7, E8 | not caught | |
| E9 | **caught** | "after a miss, >= 64 km/h" fails; shrink: fresh start passes, after-a-miss fails: names the reset. |
| B0 | **found and shrunk** | It is exactly a counterexample to "lip >= 61, |off| <= 1.5 => lands". The shrink (load, style, start) gives the flipping factor. If it's the load or the start, it's a game finding for the user (a design edge a player can hit). If it's the style, the test. |
| P1 | **caught + named** (the after-a-miss property) | |
| P2-P7 | not caught | Static or visual bugs; no physics property touches them. P6/P7 only if a "hub above ground / HUD" sensor is added = Idea 3. |

### How it fails
- **The properties are predictions too.** "61 lands" is the design's number from one bench. A real
  envelope edge (1.5 m off at flat out misses) will look like a bug; it may be the design. The grey
  zone and "report to the user, don't fix" rule handle it, but it costs the user a look.
- **False alarms grow with N.** At N = 24 any rare physics outcome shows up. Good for finding things,
  bad for S1 if the properties are tight.
- **Not for the steps in the hut.** Crate distance, leg-up timing do have continuous parameters
  (`ROUGH_NOTES` 2026-10-20: crate 0.85-1.26 m from the wall, flaky at 1.26), so the method carries
  there, but it needs actors that do the steps for real (Idea 5).
- **Cost:** N tries is N x 12 s.

### Cost in the user's real time
- 24 tries x ~12 s = **~5 min** + ~50 s start-up. I think `--fixed-fps 60` headless could run faster
  than real time; **not measured**, so 5 min is the honest figure.
- Build: ~1-2 h (the bench exists; sensors at the lip, the sampler, the shrink).
- Reading: one table of properties, one shrunk line per counterexample. No model.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| **matches how S1 is measured** (speed and lane varied); risk at the edges | P1 named; physics bugs only | 0/3 | 0/4 alone | **pass for the jump** (real throttle and steering from a declared start) | ~5 min per run | physics stretches yes; puzzles of steps need Idea 5's actors |

---

## Idea 5: Goal-seeking players with eyes, judged by the game's own goals

**One line:** replace scripted paths with small in-engine player bots that are given goals ("get P2 into
the hut"), sense the world (rays, prompts, stuck), use only real input, recover when blocked, and are
judged only by the game's own success predicates within a budget.

### How it works
- `PlayBot` per player in `PlayTest.gd`, driving its player's real `InputDevice` (keys for P1, pad
  events for P2). Skills, each a small closed loop: `walk_to(node)` (rays at knee and chest height,
  sidestep and back off when blocked, gives up after a budget), `use(node, prompt_contains)` (turns the
  view with mouse / stick input until the game's own `prompt_text` shows the expected verb, then
  presses), `carry(item, to)`, `drive_to(goal_predicate)` (proportional tap steering, a 5-ray bumper
  fan, back up and re-aim when the speed is zero with throttle on).
- **Goals are the game's**, not the test author's: `Story` step predicates (fact 9), `RampJump` flags
  (`jumped`, `door_open`, `box_open`, `in_hut(p2)`), `camper.wheel_off`. Targets are nodes found by
  name (`HutDoorArea`, `HutCrate`, `ToolboxArea`), never coordinates.
- **The plan is a goal list**, not a path: `jump the gap`, `P2 in the hut`, `door open`, `wheel at the
  hub`, `nuts found`, `wheel on`, `story at cross`. Each with a budget from a measured human-ish time
  x 3. A goal not met in its budget = fail, with the bot's own log of what it tried.
- Attempts are counted and reported: "jumped on try 2 of 3" is a finding, not a pass to hide.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | mostly avoided | Targets are named nodes; far fewer hand expressions. A wrong node name still fails (test problem; it would say "node not found" before acting). |
| E2 | **avoided** | Bumper rays and back-up-and-re-aim; landing spot doesn't matter because the goal is `cross`. |
| E3 | not caught | |
| E4 | **avoided or failed honestly** | Goal is `cross`; a circling bot misses its budget and logs its own steering. Still `GAME?` by its own words unless Idea 1/2 sits under it. |
| E5 | **caught** | The last goal is the story reaching `cross`, not "wheel on". |
| E6 | **caught** | The goal is `in_hut(p2)` reached by P2's own pad input; with no pad, nothing moves and the budget fails. The "leg-up alone falls short" negative still needs a command->effect check (Idea 1), or it passes for nothing again. |
| E7, E8 | not caught | |
| E9 | no | |
| B0 | **would hide it unless counted** | A bot that retries would land on try 2 and pass. Counting attempts turns it into "missed once at 66.5" - a finding, but not a diagnosis. |
| P1 | partly | Retries after a miss show a slow lip if logged; caught only with a property (Idea 4). |
| P2 | **caught** | The bot can't walk in over the sill: `walk_to(door)` budget fails at the door, named by where it stuck. |
| P3 | **caught** | P2 in swim mode beside the van can't do the next goal (walk) at walking speed: fails at the next goal. Named weakly ("P2 stuck by the van"), not "swim mode". |
| P4 | **caught** | The crate can't be put down where the rubble is: `carry(crate, under window)` fails, named by place. |
| P5, P6, P7 | not caught | Visual; nothing blocks play. |

### How it fails
- **The bot is the risk.** A bot that can't do what a human can is a false alarm factory (E2, E4 were
  bots). The seesaw crossing bot took 15+ rounds and ~1.5 h without converging (`ROUGH_NOTES`
  2026-10-19, "the loop"). I think a general walker/driver is days, not hours.
- **A bot finds paths a designer didn't intend** (squeezes past a solid, climbs a rubble heap). That's
  a finding, but each one costs the user's look.
- **Wrong blame:** a budget miss says "goal not met", not whose fault. It needs Idea 1 under it and
  Idea 2 behind it.
- **Pass means less than it sounds:** goals met says the sequence works, not that it looks right
  (P5-P7).

### Cost in the user's real time
- Per run: the game's own time for the stretch; I think 3-5 min for the ramp end to end.
- Build: **I think 1-3 days** for walk / use / carry / drive good enough for the ramp; that is where
  this idea dies or lives. Per puzzle after that: a goal list, ~30 min.
- No model in the loop.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| I think the weakest of mine early: bot failures read as red | P2, P3, P4 caught (named by place); P5-P7 no | 0/3 alone | budgets fail a frozen game, but only after the budget (may exceed 60 s) | **the only idea of mine that makes the hut part a real path** | 3-5 min per run; days to build | goal lists carry well, if the bot skills are general |

---

## Idea 6: A separate, blind judge on pictures, with a private checklist

**One line:** after the run, frames taken at the game's own event moments go to a fresh judge model
that never sees the test code or the PASS lines, with a checklist the test's author has not seen; the
judge only reports, it never drives a loop.

### How it works
- **Frames:** an observer camera (a `SubViewport` + `Camera3D` that no player owns, so it changes
  nothing in play) placed per event from the event's own object (the hub, the hut window, the van),
  plus the players' own views. Captured at game events (landing, `snap_wheel`, shutter break, door
  open, toolbox, wheel on, 3 s after the story changes) and a 1 fps grid of the recorded video
  (`tools/record_walk.sh` + the ffmpeg grid already in `TESTING_METHOD.md` v5).
- **The checklist is private:** written by the referee / the user from the design page, kept outside
  the builder's view (as the brief's final exam set is). Items are visual facts: "the front-left shows
  a bare hub and it is above the road", "the HUD says ON THE HUB", "no one in a swimming pose on dry
  ground", "the wreck shows above the water from the ramp's top", "the crate's place under the window
  is clear", "at the end the van is on the road and moving away".
- **The judge:** a fresh model call per run (I'd use the other model family, so it doesn't share my
  blind spots), frames + checklist only. Answers each item yes / no / can't-see with a frame number.
  "can't-see" = the run didn't show it = **test problem** (coverage). Two "no"s from two judge calls =
  fail; one = ask the user with the frame.
- **Calibration, Theo's way:** a canary set of planted visual bugs (P4-P7 as patches) is run through
  the judge once per judge prompt change; the judge's hit rate on the canaries is reported with every
  verdict.
- **The old trap:** the model thinks once, **after** the run, on a finished set of frames. The game
  never waits for it. The skybox trap: the judge's output never feeds an automatic fix loop; it goes
  to a human.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | not caught | |
| E2 | **caught** | The last frames show the van at a tree; checklist "on the road, moving away" = no. |
| E3 | partly | Frozen frames look the same; the judge may say "can't see progress". |
| E4 | **caught** | Frames show the van off the road, circling. |
| E5 | **caught** | Same as E2: that's the video that fooled us. |
| E6 | **caught as test problem** | The leg-up frames show P1's view, not P2's: "can't see P2's leg-up". |
| E7 | partly | No frames for the missing scenarios: only if the judge counts scenarios against a list. |
| E8 | not in time | It's after the run. |
| E9 | partly | Frames can show the swimmer isn't touching the van; not the slope. |
| B0 | partly | Frames at the lip show the van's attitude; can't tell the cause. |
| P1 | no | A speed bug isn't visible in a still. |
| P2 | partly | A player stopped at the sill looks like a player standing. |
| P3 | **caught** (swimming pose on land) | |
| P4 | **caught** (rubble in the crate's place) | |
| P5 | **caught** (no wreck above the water) | |
| P6 | partly | A hub sunk 0.1 m: I think hard to see in a toon-shaded 1600x900 frame. |
| P7 | **caught** if the HUD is in frame | |

### How it fails
- **Hallucinated "no" (false alarm)** and **lazy "yes" (false pass).** Vision models misread small
  things; I have not measured this judge's rate on this game's frames. The canary hit rate is the
  only guard.
- **It depends on the camera.** No frame of the thing = "can't see": honest, but every new puzzle needs
  observer placements.
- **Tokens and time:** ~30-60 images per run. I think 50-150k tokens and 1-3 min per verdict.
- **Not in time:** after the run; it can't stop a dead run (E8).
- **Judges get chased** (Theo, ~$800 on a skybox) if anyone loops on its output. The rule "judge
  reports, a human decides" is a process rule; nothing in code enforces it.

### Cost in the user's real time
- Per run: the recording (walk `ramp` 169 s, brief) + judge ~1-3 min (I think). Reading: a per-item
  table with frame numbers.
- Build: I think ~2-3 h (observer camera per event, frame picker, judge prompt, canaries).
- Model thinking: once per run, after it; justified against the old trap because the game never idles
  for it.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| unknown: depends on the judge's misread rate (not measured) | **P3, P4, P5, P7 I think**; P6 partly; P1, P2 no | T1 maybe ("can't see P2"), T2/T3 no | N1/N2 partly, N3 yes (P2 missing in frames), N4 no | **pass**: observing isn't aiming a player's camera | 3-5 min + tokens per run | carries if observer spots are cheap to add (I think ~30 min a puzzle) |

---

## Idea 7: The user's own playthrough as the reference (a flight recorder and a trace diff)

**One line:** stop predicting the future; record the past. The game logs a stream of meaningful events
whenever anyone plays; the user's own play (which works) becomes the reference, and a test passes when
its stream matches the reference's milestones and breaks none of its rules.

### How it works
- A **flight recorder** in the game (dev builds): one JSON line per event with the physics frame:
  story step changes (`Story.objective_changed`, `Story.gd:9`), `RampJump` events (lip with speed /
  offset / attitude, landed, fail and where, shutter, wheel in hut, door, box), seat in / out, swim
  start / end, pick up / put down (item names), interact used (the `tag_name`), pause on / off, pad
  connected / lost. Also each player's raw `InputDevice` state per tick (small: a few bytes a tick).
- **The reference:** the user plays the ramp once with the recorder on (they already played it today;
  it would cost one more play, ~5-10 min I think). Out of the engine, a script turns their trace into a
  **contract**: the milestones in order (jumped -> P2 in hut -> door open -> box open -> wheel on ->
  `cross`), the numbers they reached (their lip speed), and the time between milestones.
- **A test passes** when its trace has every milestone in a compatible order, each within k x the
  user's time, no forbidden events (pause while playing, swim on dry land, a fail after `jumped`), and
  the trace never stops growing for > 30 s.
- **Replay probe (Theo's original plan):** feed the user's recorded inputs back from the same start.
  Fact 1 suggests the physics repeats closely, so the replay may hold for the jump. Where it diverges,
  the first diverging event is measured and reported; it is evidence of determinism, not a pass.

### What it would have caught
| # | Caught? | Why |
|---|---|---|
| E1 | not caught | Bad expressions in the actor still break the actor. |
| E2 | partly | Landing spot doesn't matter to a trace; but the driver still hits the tree, and the missing `cross` fails it. |
| E3 | **caught** | `pause on` while playing is forbidden; and the trace stops growing. |
| E4 | caught (as missing `cross`); blame not given | |
| E5 | **caught** | The user's trace has `cross`; the walk's doesn't. |
| E6 | **caught** | The user's trace has "P2 jump" events before "P2 in hut"; the test's leg-up with no pad has no P2 jump at all: the trace shows "passed with no P2 input". |
| E7 | **caught** | No trace file for a scenario asked = not run. |
| E8 | **caught** (trace stops growing) | |
| E9 | partly | The trace has the van's speed and P2's swim events side by side, so the cause is readable; still read by a person. |
| B0 | **partly, usefully** | Compare the lip events: the user's flat-out (their offset, attitude) vs the test's (1.05 m, attitude). If the user's lip attitude is calm and the test's isn't, the input differs: points at the driver. If the user also played with P2 aboard and landed, the load is cleared. |
| P1 | **caught** (lip speed after a miss below the user's) | |
| P3 | **caught** (swim on, no swim off, player beside the van) | |
| P7 | caught if the HUD text is an event | |
| P2, P4, P5, P6 | not caught | Static / visual. |

### How it fails
- **One play is an anecdote.** The user's order of events may be incidental (P2 opened the toolbox
  before the door, or not). A contract learned from one play is either too strict (false alarms) or
  hand-edited into a list of required milestones, which is a prediction again, just a smaller one.
- **It needs the user's time** per puzzle, and again whenever the design changes. That breaks the
  brief's "can't eat the user's real time" a little each time.
- **Not trial-able by us alone:** Stage 3 can't make the user play. A referee play could stand in, but
  then it's our play, not theirs.
- **It still needs actors** to play the test runs; the trace judges, it doesn't play.
- **Replay** will drift on anything with creatures or random scatter (`RampJump.gd:319` uses `randf`
  in the build). I think replay holds only for short physics stretches.

### Cost in the user's real time
- The user: one play per puzzle, ~5-10 min (I think). Per run: ~0 extra; the diff is a few seconds.
- Build: I think 2-3 h (recorder hooks, contract script, diff).
- No model in the loop.

### Self-score
| S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|
| risk: over-strict contracts from one play | P1, P3, P7 caught; others no | T1 yes (no P2 input in trace), T3 yes, T2 no | **N1, N2, N4 yes** (trace stops / missing); N3 yes (no P2 events) | neutral (judges, doesn't play) | ~0 per run; **user's time per puzzle** | needs a user play per puzzle |

---

## Ranking

How I ranked: the scoreboard's order. Gates (S4, S5) first, then S1-S3 with false passes weighing
more, then cost. Each idea alone, then what it needs beside it.

| Rank | Idea | One line |
|---|---|---|
| 1 | **Idea 1: the rig-checked verdict** | Proves the test was alive, in control and honest before any "game problem"; kills E3, E6, E7, E8, E1 as test problems; the cheapest way to pass S3 and S4. |
| 2 | **Idea 2: counterfactual blame** | On a failure, change one factor and rerun: the only one of mine that answers B0 and E9 with a measurement; costs only when something fails. |
| 3 | Idea 3: the game checks itself | Names P1-P7 at the object, in every play including the user's; risk: written to the known bugs. |
| 4 | Idea 4: the envelope | Many varied tries judged by design properties, failures shrunk; matches how S1 is measured; physics stretches only. |
| 5 | Idea 5: goal-seeking players | The only real path through the hut part; the bot is days of work and has looped before. |
| 6 | Idea 6: blind judge on pictures | Catches the visual bugs the evidence says pictures found; tokens and an unmeasured misread rate. |
| 7 | Idea 7: the user's play as reference | The cleanest answer to "stop predicting the future", but it needs the user's time and can't be trialled without them. |

## My 2 picks to run

**Pick 1: Idea 1 (the rig-checked verdict).** Why:
- It is aimed at the false passes and the watching failure (E5-E8), which the brief and scoreboard
  weigh highest, and at both gates: S4 directly, S5 by making set-state countable.
- It is cheap to build (I think 2-4 h; a ~1 h trial version: heartbeat, paused guard, asked/ran,
  expression lint, command->effect for the pad) and costs ~0 per run.
- Every other idea needs it underneath: without it, Ideas 2, 3, 4 and 5 blame the game for a paused
  or unplugged rig. Testable in a trial on all of T1-T3 and N1-N4.

**Pick 2: Idea 2 (counterfactual blame), run on B0 first.** Why:
- The baseline gives a live, unexplained failure (B0) with a short factor list already (fact 2: P2
  aboard, a can, the post-miss start, the steering). This idea answers it with a measured table rather
  than an opinion; the scoreboard's open question is literally this.
- Fact 1 (same numbers 4 times in `ramp_retry`) is evidence that two runs per variant can be enough on
  the ramp, which keeps it at ~2 min per diagnosis. (I think; the trial will measure V0 first.)
- Its outcome is useful either way: a game finding for the user (a passenger makes the jump miss), or
  a test fix with proof.
- Its weakness (blaming the game for a broken rig) is exactly what Pick 1 covers, so the two together
  cover "a pass means something" and "a failure says game or test".

What neither pick does: a real path through the hut (Idea 5) and the visual bugs (Ideas 3, 6). If the
top 4 has room for a third of mine, I'd argue for Idea 3 (cheap, names bugs, runs in the user's play),
and I'd want the GPT auditor to attack its overfitting to P1-P7 hardest.

## Facts for the referee (with file:line)

- `ramp_retry` landed flat out after a miss 4 / 4 at 66.2 km/h, 1.00 m off (`appdata/ramp.out:38-100`);
  `t_ramp` missed at 66.5 / 1.05 (`seg_1.log:41-43`). Differences: P2 seated by code
  (`PlayTest.gd:11715`), a stowed can (`11712`), a 0.3 s wait (`11723`). Seated collider off
  (`PlayerRig.gd:1916`), stowed can frozen with no collision (`Carryable.gd:212-216`).
- The baseline's pitch / roll include the fall after the miss (`PlayTest.gd:11598-11600` with
  `RampJump.gd:362`); they are not the attitude at the lip.
- The game's miss log has no position (`RampJump.gd:591`); "shallows" has no far bound on `l.z`
  (`RampJump.gd:362`).
- `ramp_try` steers with full key presses up to 1 m before the lip (`PlayTest.gd:11594`, dead band
  `:7500`).
- Tests run on through a pause: `wait` ignores pause (`PlayTest.gd:217-218`), `PlayTest` is
  `PROCESS_MODE_ALWAYS` (`:40`).
- The summary never compares asked with ran (`tools/run_test.sh:108-113`).
- Game-owned success predicates exist: `Story.gd:93-101` (`ramp_jumped`, `not wheel_off`, van near
  `j3`).
- Today's `t_ramp` sets state inside the steps it checks (`PlayTest.gd:11715`, `:11884`, `place_player`
  / `face_point` throughout the hut part); the walk too (`make_ramp.py:132`).
