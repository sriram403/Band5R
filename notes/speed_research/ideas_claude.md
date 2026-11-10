# Stage 1: the Claude auditor's 7 ideas (blind, 2026-11-10)

Read: the brief, `TESTING_METHOD.md`, `method_research/FINAL.md` lines 1-150, and at `5f3e3e3`:
`method_run.sh`, `method_watch.py`, `run_test.sh`, `run_game.sh`, `record_walk.sh`, `prove_ghat.py`,
`make_ghat_manifest.py`, `frozen.json` (limits), `Plant.gd` (header), `LiveControl.gd`, `make_ghat.py`,
`PUZZLE_CHANGES.md` #6, and parts of `PlayTest.gd` (the ghat scenarios and helpers). On `h1`:
`play_walk.sh`, `live.py` header, `record_walk.sh` header. Nothing forbidden read. **No hole named by
accident** as far as I can tell: the Plant list and the "built on the way" design holes I saw are
from before `5f3e3e3`.
**One slip to report:** I piped `PlayTest.gd` into a temp file on C: (`%TEMP%\pt.gd`) for one grep,
then deleted it at once (checked gone). Read-only otherwise; no game run.

Row names used below (the brief's table): **A** full runs 59 · **B** walk trial plays + live replays 52 ·
**C** single-scenario reruns 40 · **D** plant runs 27 · **E** takes + encoding 23 · **F** benches,
killed runs, ramp reruns 22.

## Facts from the code that shape every idea (measured = read in the code)

- **The meter sums every Godot process.** So anything that only overlaps games (two at once) saves
  wall clock, **not score**. Idle games (a live session open while the model thinks) **cost score**.
- **The compile check is a Godot process** (`run_test.sh`: `run_game.sh --headless --import`, "~40 s")
  and runs before **every** `method_run.sh`, including all 11 plant groups on unchanged code.
- **A ghat run is one game process** for all 7 scenarios (`test_plan "a,b,c"` -> one line; the
  watcher tails only `seg_1.log`). A FAIL does **not** stop it; STALLED / TEST / NOT HEALTHY do,
  and then the scenarios after it never run.
- **Many deadlines are wall clock, not game clock:** `PlayTest.gd` has 126 `Time.get_ticks_msec()`
  (e.g. `_hide_well`, the `ghat_looks` waits `SEARCH_S + 45`), `LiveControl.gd` 11 (every walk
  `within` and step `max`). **Game code too** on the ghat path: `Camper.gd` 4 (the cap's 3 s window
  line 1650, the `free_coolant` plant line 1171), `Hearing.gd`, `VanAttack.gd`, `Carryable.gd`,
  `PlayerRig.gd`. The watcher's deadlines are host real seconds (fine when faster).
- **Scenario clocks count physics frames** (`t += 1.0 / 60.0` per `physics_frame`), and `wait()` uses
  a timer: both are game time.
- **Image checks need a real renderer:** `ghat_net` (brightness of the net from outside / inside) and
  `ghat_looks` (`obs_shot`) read rendered pictures.
- **Movie Maker runs at 68-87 % of real time** (TESTING_METHOD v5), so a take's wall-clock deadlines
  are **tighter** in game time than in a trial play: a take can fail where the play passed.

---

## Idea 1. Game clock first, then faster than real time

**How:** two steps, in this order.
1. *Game clock.* A `gclock_ms()` in PlayTest / LiveControl (summed physics-frame time, or
   `Time.get_ticks_msec()` only while not paused, scaled 1:1 with game time) replaces every wall-clock
   read in test code; the ghat-path game code (`Camper`, `VanAttack`, `Hearing`, `Carryable`, `PlayerRig`
   flicker) moves to process / physics time. That is also a real fix (wall-clock game logic breaks
   under pause and slow frames), so it's **a game change: note it, tell the referee** (brief rule).
2. *Fast mode for unrecorded runs.* Engine args before the `--`: `--fixed-fps 60 --disable-vsync
   --max-fps 0` (fixed-fps turns off real-time sync: every frame is exactly 1/60 s of game time, one
   physics tick per frame, so physics is the **same** as the tests assume, even more repeatable). A new
   `EARGS` in `run_test.sh` / `play_walk.sh` (today `ARGS` lands after `--`, where engine flags don't
   work). A smaller window (960x540) for scenarios with no picture checks; 1600x900 kept for
   `ghat_net` / `ghat_looks`.
- Not `Engine.time_scale`: I think it keeps the ticks per second and makes each step longer (the van's
  physics changes; the `t += 1/60` counters go wrong). Not `--headless` in general: the dummy renderer
  breaks the picture checks (a false alarm, at least not a false pass); maybe for `ghat_heat` alone.

**Removes:** the game-time part of A, B, C, D, F (~200 min of rows). **I think 1.8-2.5x**
(112 fps was measured with a second game running; alone, uncapped, at 960x540 it should be higher;
the CPU side, physics + creature AI, may cap it). At 2x: **~70-80 min saved**; at 1.5x: ~50.
Fixed costs per launch (compile, world load) don't shrink.

**How it could go wrong:**
- *False pass / weak check:* any deadline left on wall clock becomes **looser** in game time (at 2x,
  `_hide_well`'s 150 s = 300 game s: "it gives up in time" can pass at speed and fail at 1x). That is
  why step 1 comes first, and a grep for `get_ticks` in `scripts/dev/` must come back zero.
- *Plants change strength:* `free_coolant` fires on a wall-clock window (`fmod(ticks/1000, 5) < delta`):
  at 2x it fires about half as often per game second: a NOT PROVED that is the speed-up's fault.
- *Wrong blame:* game code still on wall clock behaves differently fast vs slow (the cap's 3 s
  window, hearing): a bug shows only at one speed. The take (slow) then fails where the plays passed.
- *Hidden:* behind-the-windows rendering; Windows may throttle an occluded window (the minimized case
  already STALLs). Measure, don't assume.

**Build:** ~60-90 min (mechanical but each of ~140 reads needs a look; ~10 in game code). Game risk:
low-medium (timing logic on the ghat path changes from wall to game time).

**Smallest experiment (<5 min game):** (a) no game: the grep counts above. (b) `ghat_places` at
`--fixed-fps 60 --disable-vsync --max-fps 0 --resolution 960x540`: physics frames per wall second from
the heartbeat's `pf` -> the speed factor (~2 min). (c) `ghat_heat` with `one_flat` at 1x and fast:
same "seen at sample", same "boiled at sample" (within a few samples), same checks.

---

## Idea 2. One compile per code change, not per run

**How:** `run_test.sh` hashes the compile inputs (every tracked + untracked `*.gd`, `*.tscn`, `*.tres`,
`project.godot`, imported asset files under `FindingNaresh/`) and skips the `--headless --import`
when the hash equals the last **clean** compile's (`appdata/playtest/runs/compiled.hash`). Any
change, or a failed compile, forces it. `NO_CHECK=1` already exists; this makes it automatic and safe.
Also: `prove_ghat.py` runs on one code state, so its 11 groups need **one** compile, not 11.

**Removes:** ~40 s from most launches in A, C, D, F. **I think 8-15 min** (25-35 metered launches on
day 2 × ~40 s; the referee's meter log can count them exactly).

**How it could go wrong:** a missed change (a file type not hashed, e.g. a new sound from `tools/gen`)
-> the run uses a stale import. A script error is still caught (the watcher's 45 s first-beat limit
-> NOT HEALTHY, a SCRIPT ERROR -> TEST / FAIL), so it costs ≤45 s, not a false pass. A new asset not
imported could make a check miss a sound / mesh: hash the asset folders too.

**Build:** ~15 min. No game risk.

**Experiment (~2 min):** time `run_game.sh --headless --import` twice with no change. If the second
is ~40 s too, the saving is real; if it's 5 s (Godot's own cache), drop this idea.

---

## Idea 3. Plant runs stop at their expected FAILs, one compile, fewer processes

**How:** `prove_ghat.py` already knows, per group, the FAIL texts it needs. Pass them to
`method_watch.py` (an `EXPECT_FAILS` file); the moment **every** expected text has appeared in a FAIL
condition, the watcher stops the game (verdict as now; PROVED as now). With idea 2, one compile for
all groups. Then, cautiously, **batch groups into one process**: the plant set switches per scenario
(`--method-fixture-seq=ghat_heat:heat_always,one_corner;ghat_looks:lean_close,fast_turn`, `Plant`
re-read at each scenario start and logged "plants now: ..."), the puzzle reset by F1 as the tests
already do. Groups whose plant acts at world build (e.g. `fog_short` if the fog is built at load:
check) keep their own process.

**Removes:** D. **I think 27 -> ~12 min** at 1x (stop at the FAIL ~35 % off, one compile ~7 min off,
batching ~1 min of boot per group); ~7 with idea 1.

**How it could go wrong:**
- *False PROVED (the bad one):* a plant **leaking** into the next group's scenario can produce that
  group's expected FAIL for the wrong reason. Guard: a FAIL counts only if it began while its own
  plant set was active (the "plants now" line's time), and the clean run stays separate.
- Early stop hides later FAILs in the same run: harmless for a proof (each plant needs only its
  own); but if a plant also breaks something unexpected, we no longer see it. Acceptable.
- Build-time plants in a batched process don't apply -> NOT PROVED: a visible false alarm.

**Build:** early stop ~20 min; batching ~40 min. Game risk: none (test code; `Plant` is test-only).

**Experiment (~3 min):** group `looks` with early stop: time to the stop vs the whole `ghat_looks`
run; verdict still names both plants.

---

## Idea 4. Full runs only first and last; the scenarios a fix touches in between; a stall doesn't end the run

**How:**
- **One full run at the start** (finds every failing scenario at once; FAILs don't stop it) and **one
  at the end** (the benchmark's proof). None in the middle.
- **A STALL / TEST in one scenario no longer drops the rest:** after the kill, `method_watch` relaunches
  the scenarios not yet started (`run_test.sh resume` logic, which exists) and the verdict merges them.
  Today a stall in scenario 2 means scenarios 3-7 are unseen until another full run.
- **Between, only what a fix touches:** a map from game file -> scenarios (from
  `make_ghat_manifest.py`'s call graph plus the classes each scenario reads: `Ghat`, `Camper`,
  `VanAttack`, `WaterPot`, ...). Conservative: a file used by ≥3 scenarios -> all of them. For a
  quick fix-check only (never a proof), a scenario may start at its own declared jump (e.g. `ghat_jug`
  from a save point after the boil); the final run plays everything from F1.

**Removes:** A (one middle full run: **~20 min, I think**) and part of C (fewer, shorter reruns,
**~10-15 min, I think**). With idea 1, both halve.

**How it could go wrong:**
- *Missed hole:* none lost for good (the last full run plays everything), but a cross-scenario break
  surfaces only at the end -> one more full run (+10-20 min) and the loop the rules warn about.
- *Jumped fix-checks* can pass a fix that only works from the jumped state (e.g. coolant set, not
  boiled away). They are labelled "fix-check, not proof" and never counted.
- *Wrong blame* after a relaunch: a scenario's state from the killed game doesn't carry; each
  relaunched scenario starts from F1 as now.

**Build:** ~45 min (merge after relaunch, the file map). No game risk.

**Experiment (~4 min):** plant a stall in scenario 2 of a 3-scenario plan (`FIXTURE=n5`-style window
trick or a test-side hang): scenario 3 still runs, one verdict lists both.

---

## Idea 5. Note-and-repair discovery play of the walk, then resume, never from step 1

**How:** `LiveControl` gets a **note mode** (`live.py --walk ghat.json --note`). On a failed expect it
logs `BROKE <step>: ...`, takes the failure shots, then puts the **promised state** with the step's
declared `repair` list (written in `make_ghat.py` next to each `expect`: step 6 -> boiled dry and
stopped; step 7 -> `set_tarp(true)`; step 10 -> cap blown, interested; ...), and plays on. Steps after a
repair are marked "after repair". One play lists **every** break; all are fixed together; then the h1
default resumes from the **first** broken step's save point; the last clean play from step 1 is the
take (idea 6).

**Removes:** B. **I think 52 -> ~15 min** at 1x (one noted play ~12, 1-2 resumes ~3; the 10 plays
were one fix each, mostly from step 1); ~8 with idea 1.

**How it could go wrong:**
- *Wrong blame / false alarm:* a repaired state the real game never makes (Problem's phase machine,
  the coolant left after a real boil) makes later steps fail or pass for the wrong reason. Guards: a
  repair only uses the game's own functions (the dev menu / SaveGame), every later line says "after
  repair", and a fail within ~10 s of a repair is flagged "maybe the repair".
- *False pass:* none if the rule holds that **only a from-step-1 play with no repair counts as clean**.
- A break that kills the world (script error, stuck physics) can't be repaired: stop, as now.

**Build:** ~45-60 min (note mode ~20; repair lists for 21 steps ~30). No game risk.

**Experiment (~4 min):** from step 13's save point, with a plant that breaks step 16 (`no_fix`): the
noted play logs BROKE at 16, repairs, and reaches step 20-21.

---

## Idea 6. Record once: the take is the final clean play

**How:** no separate "trial until clean, then take". After idea 5's resumed plays pass, the **next
from-step-1 play is recorded** (`record_walk.sh`, h1's resume / stitch if it fails). With idea 1's game
clock the take can't fail on deadlines that Movie Maker's slower speed tightened (68-87 %). Try a
cheaper Movie Maker frame (1280x720, lower MJPEG quality) only if it measurably speeds the take.

**Removes:** E and the last play of B. **I think 23 + ~5 -> ~15 min.** Note: ffmpeg is not a
Godot process, so the encoding in row E is **not metered**: the meter's baseline for E is smaller
than the table says (referee: please confirm what the meter counted).

**How it could go wrong:**
- The take is the first play at slow speed: anything still on wall clock (game code) shows only here
  -> a failed take. Idea 1 step 1 is the guard.
- A stitched take (resumed parts) can hide a jump between parts (creatures repositioned from the save
  point): the user must be told where the joins are (h1 already logs them); the referee decides if a
  stitched video counts as "the walk runs clean".
- Recording the clean play means the user's video shows what was proven, nothing staged: good.

**Build:** ~10 min (order of tools, a resolution flag). No game risk.

**Experiment (~3 min):** record steps 1-5 at 1600x900 and at 1280x720: Godot's "% of real-time
speed" line for each.

---

## Idea 7. A flight recorder, failure shots, and no idle game

**How:**
- Every scenario and walk writes a **2 Hz state trace** into the run folder (van position / speed /
  temp / coolant / fuel / gear; Problem's position, phase, goal, stop, eye glow; each player's position,
  seat, held item, breath; the open step), plus **every event at its time** (seen, boil, cap, window
  give-away, taken). Most "live replays to measure" and many benches are questions this answers
  ("where was it when the window gave you away", "how hot at the pass").
- On any FAIL / STALL: **3 observer shots** (`obs_shot` exists) from angles that show the actors,
  before the kill: the user's "debug with pictures" without a rerun to get the angle.
- **No idle game:** a live session is closed the moment its answer is in; the model thinks with the
  game shut (the meter counts idle time). Runs that go off plan are stopped by the watcher's limits
  (exists) or the walk's step `max` (exists), not by the model noticing late.

**Removes:** the "live replays to measure" part of B, part of F (benches 10, killed 8), some C reruns
done only to add a log line. **I think 10-20 min.**

**How it could go wrong:** 2 Hz misses short events (keep events at event time); a trace can't show a
visual bug (a face through the glass needs a picture: the shots, or still a bench); a bigger log could
slow the game (I think negligible at 2 Hz: measure). Wrong blame: reading the trace replaces looking;
the rule stays "an unexplained result is a question".

**Build:** ~30-45 min. No game risk (test code).

**Experiment (~4 min):** `ghat_looks` with the trace: answer three questions from the trace alone
(when it reached each window, its lean gap, its turn speed), then check them against the scenario's
own log lines.

---

## Seeds I reject or fold in (with reasons)

- **Two games at once: rejected for the score.** The meter sums every Godot process, so overlap saves
  wall clock only; two uncapped games share the GPU and each runs slower (likely a worse score with
  idea 1). Also `method_run.sh` refuses a second game and both would write the same
  `appdata/playtest/runs` files. Keep it for wall clock (build in `MPG_dev` while a run goes).
- **Resume from the failed step:** already the default on h1; folded into idea 5.
- **Only the changed scenarios / jump to the moment:** idea 4 (jumps for fix-checks only, never proof).
- **Faster than real time:** idea 1, but via `--fixed-fps` uncapped, not `time_scale`, and only after
  the game clock.

## Ranking and what I'd trial first

| # | Idea | Saves (I think) | Build | Risk of a false pass |
|---|---|---|---|---|
| 1 | Game clock + fast mode | 50-80 | 60-90 min | medium until the clock is all game time |
| 5 | Note-and-repair walk | ~35-45 | 45-60 | low (clean = from step 1, no repair) |
| 3 | Plants stop at their FAILs (+ batching) | ~15-20 | 20-60 | low; batching medium (leaks) |
| 4 | Full runs first and last; stall doesn't end a run | ~25-35 | 45 | low (last run plays all) |
| 6 | The take is the clean play | ~8-13 | 10 | low |
| 7 | Flight recorder, shots, no idle game | 10-20 | 30-45 | low |
| 2 | One compile per change | 8-15 | 15 | very low |

Savings overlap (a 2x game halves what 3-7 leave), so they don't add up. **My projection with all
seven, at 2x: ~75-80 min. At 2.5x ~68; at 1.5x ~90 (fails).** So **the target hangs on idea 1's
speed factor**; everything else gets the rest of the way.

**Trial first:** the 2-minute speed measurement (idea 1, experiment b) and the compile timing
(idea 2), before any build: they decide whether the plan can reach 75 at all. Then trial C1 =
ideas 1 + 2 + 3 + 4 (mechanical, all in the test tools except the ~10 game-code clock reads), with
5 + 6 as the walk half. If fast mode measures under 1.6x, the plan changes: fewer full runs
(only the final one) and the walk discovered by note mode at 1x.
