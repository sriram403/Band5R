# Stage 2, round 2: the Claude auditor's audit (2026-11-10)

Read (all on the allowed list): the scoreboard (ruling R1 first), `SPEED_RESEARCH.md`, `stage1_task.md`,
`stage2_r2_task.md`, both idea files, both round-1 audits. New code reads, `git show h1:` only:
`LiveControl.gd` (header, `_snap_live` / `_restore_live` / `_run_walk`, lines 30-50 and 373-620),
`SaveGame.gd` (`collect` / `apply`), `Creature.gd` (vars, `_item_ms`), `Hearing.gd` (`emit`), `Ghat.gd`
(grep), `play_walk.sh`. Nothing forbidden read; no hole named by accident that I can tell. No game
started; this file is the only one written.

Rows: **A** full runs 59 · **B** walk plays + live replays 52 · **C** single-scenario reruns 40 · **D**
plants 27 · **E** takes + encoding 23 · **F** benches, killed, ramp 22.

## 0. Referee's facts checked in the code, plus four new ones (measured = read on h1)

- **Confirmed:** `SaveGame.collect(boot, raw=true)` skips `Ghat.adjust_save` (SaveGame.gd:127), and
  `_snap_live` keeps the plain script variables of the ghat node and of Problem plus Problem's
  transform. My r1 fact 1 ("positions only, rewound") was 5f3e3e3's code; **withdrawn for h1**.
- **New 1. The restore is not exact by construction, in four places:**
  - `SaveGame.apply` sets the van's `linear_velocity` and `angular_velocity` to zero and
    `engine_on = false` (SaveGame.gd:163-173). A point taken while the van rolls or idles resumes with
    it stopped and the engine off.
  - `_snap_vars` keeps only plain values: Problem's `director: Callable`, any object reference other
    than a `PlayerRig`, and **child nodes' state** (its `Hearing`, nav, animation) are not saved.
    `director` is probably re-set by `_spawn_problem` (I think; only when Problem was absent).
  - **Absolute clock values cross processes:** `Creature._item_ms` is a `Time.get_ticks_msec()` stamp
    (via `Hearing.emit`, Hearing.gd:29 -> Creature.gd:450-452). Restored into a new process whose ticks
    restart near zero, `t - _item_ms` is wrong (a "bounce" can be read where none happened).
  - Watches are re-armed with a **fresh `within`** from the resume moment (LiveControl.gd ~585), and the
    other creatures get **positions only**.
- **New 2. Inputs in a walk are made inside the game:** the walk's `do` steps run in `LiveControl`
  (`await _do(c)`, `pt.wait`), not sent live by the client. So "host inputs arrive at different
  simulated times" (GPT on C1) does not apply to walks or scenarios; it would apply only to a live
  session driven by hand.
- **New 3.** The walk's `within`, `max` and watches use `Time.get_ticks_msec()` (wall clock).
- **New 4.** No code revision or walk hash is stored in a point (confirmed).

## 1. GPT's objections to my ideas: conceded or rebutted

| My idea | GPT's objection | Verdict | Evidence / why |
|---|---|---|---|
| C1 fast | "112 fps with two games does not measure accelerated physics throughput" | **Concede** | True; my 1.8-2.5x was "I think". The takes' 68-87 % is Movie Maker writing frames, not evidence either. Only the probe counts. |
| C1 | Changing gameplay clocks changes the game before discovery (could move a hole) | **Concede** | Already half-changed in r1 (`Clock.ms()` identical at 1x). Now: **game code untouched**. Only test code (PlayTest, LiveControl) moves to the game clock. Any scenario whose path runs wall-clock **game** code (`Camper` cap window, `VanAttack`, `Hearing`, `Carryable`, `PlayerRig`) is not run fast until qualified; at fast those windows would be 2x longer in game time. |
| C1 | "grep = 0 is neither necessary nor sufficient; health clocks stay wall" | **Concede, changed bar** | Right: the watcher's health limits are host seconds and should stay so. New bar: **every** `get_ticks` on the fast path is labelled *health/report* (stays wall) or *gameplay/deadline* (must be game clock), and none is left unlabelled. Done offline, 0 game minutes. |
| C1 | "time enters through timers/helpers too" | **Rebut in part, I think** | `SceneTreeTimer` / `Timer` / `pt.wait` advance by frame delta, and under `--fixed-fps 60` each delta is exactly 1/60, so they are game time. Not tested by me; the differential run is the test. |
| C1 | Bigger physics steps; samples see different states; input edges move | **Rebut** | `project.godot` keeps 60 ticks/s (r1 fact 4). `--fixed-fps 60` gives one tick per frame with **the same step size**, not bigger. Inputs are made in-game (new 2). The real risk is the wall-clock deadlines (new 3), which the clock split covers. |
| C2 compile skip | Cache key unsound (deletions, engine/import settings, cache absence); a stale asset can load without errors and give a false pass | **Concede** | My "the watcher catches it" covered only script errors. Taking GPT's narrow form: **one import per unchanged proof batch** (the 11 `prove_ghat` groups on one code state), no cache kept across edits. A general cache only if the timing shows it pays. |
| C2 | Magnitude unproved | **Concede** | "~40 s" is a comment. The 1.5-min timing test decides. |
| C3 early stop | Text may match before the observation window closes; a kill hides a later TEST/health failure and buffered evidence | **Concede** | Early exit only when every expected check has its exact id, scenario, activation evidence and closed window, the evidence is on disk, and nothing came before it. Labelled "detection complete, rest not run", never PASS. |
| C3 | Switching plants mid-process doesn't undo state | **Concede** | Batching across groups dropped from the trial. |
| C3 | "27 -> 12 not shown" | **Concede** | Revised to ~15 at 1x (I think), measured in the pilot. |
| C4 | Auto relaunch after a STALL breaks the stop-and-look rule | **Concede** | A stall stops; we look and diagnose; then the rest is relaunched **by command** (`run_test.sh resume` exists), the stalled scenario kept in the report. |
| C4 | Drop the first full run; walk + design review instead | **Rebut** | One ghat run is one process whose FAILs don't stop it (`method_watch`: only STALL / TEST / NOT HEALTHY stop), so it shows every failing check at once. The walk can't run a scenario's checks; a design review runs nothing. Without it, a scenario hole first appears in the final run -> fix -> another 20-min final run: the loop the rules ban. **Middle way:** the first run goes at fast speed (~10 min) if T1 qualifies its scenarios. GPT's design-to-check audit is free (0 game min): add it, but not instead. |
| C5 repair in place | A game-own setter doesn't make a state reachable; a repair can skip the very transition that holds a hole; one cause can show as many BROKEs | **Concede** | Dropping in-place repair. GPT's rule: stop, keep the first-failure state and shots, BLOCKED upstream, carry on only at a declared independent branch. Provenance on every later line, no 10-s expiry. |
| C6 record once | Lower resolution weakens visuals; a join is not an uninterrupted proof | **Concede on resolution** (dropped in r1). **Joins: the user's call** (referee fact), so section 3 gives both options with costs. |
| C7 trace | 2 Hz misses transitions; shots delay the stop; overhead | **Concede** | Events at event time; shots only after actions have stopped, time-capped; fields only for declared questions. Stays a rider, not a trial. |

## 2. GPT's top 4 against mine

Same four, same owners. Where we differ:

| Point | GPT | Me now | Why |
|---|---|---|---|
| T1 acceleration | Game timing untouched; 1.5x gate | **Agree** on untouched game code. Gate: **≥ 1.5x to keep building; the plan needs ≈ 1.7x** (table below) | My arithmetic: 31 fixed + 74/f ≤ 75 needs f ≥ 1.68. At 1.5x the plan is ~80: T1 alone is fine but the plan misses. |
| T1 scope | Rendered checks and the final walk stay at baseline | **Agree** | Also: any scenario on wall-clock game code stays at 1x until qualified. |
| T2 (GPT) short paired cases | In the trial's core | **Disagree, keep only as the bench tool** for a scenario on its 3rd rerun | A ghat scenario is ~3 min incl. load (20 min / 7), so a case saves ~1-1.5 min a rerun; build 30-60 min; untimed by both of us. |
| One final suite only | No first run | **Disagree** (above): first run kept, fast if qualified | Late-hole loop. |
| T3 plant + import | Keep groups, early exit, one import per batch | **Agree fully** (my r1 batching dropped) | |
| T4 discovery + take | BLOCKED branches; fresh take | **Agree on BLOCKED**; take = fresh **or** joined, user's choice | Referee fact. |
| Stall continuation | Diagnose first | **Agree** | |
| Recording preflight clip | Yes | **Agree, ≤ 1 min, only if test clocks changed** | The take runs `--fixed-fps 25` with the walk's deadlines; if those move to the game clock, check the take once. |
| Trials kept separate ("no silent bundling") | Each method trialled alone | **Disagree in part** | No single idea reaches 75 (both our budgets). Each trial must be a whole method to pass the scoreboard. I'd sign: **shared base** (h1 resume, one import per batch, no idle game, trace rider) + each trial's own feature on top, minutes reported per row so each feature's share shows. |

## 3. The TOP 4 as I'd sign it

| # | Owner | Trial | Saves (I think) | First experiment (< 5 game min) | Pass bar | Fails if |
|---|---|---|---|---|---|---|
| **T1** | Claude runs | Fast mode for unrecorded runs: `--fixed-fps 60 --disable-vsync --max-fps 0` as engine args (before `--`); test code on the game clock; game code untouched; each scenario / walk section labelled fast-qualified or 1x | A, C, D, B, F: **~32 at 2x, ~25 at 1.7x, ~20 at 1.5x** vs the 1x plan | **Probe (≤ 2 min):** `ghat_places` with the flags, no code change, behind the windows: physics frames per wall second from the heartbeat `pf`. Then (≤ 4 min, after the clock split) GPT's differential: a nonvisual stretch of `ghat_heat`, 1x and fast, clean and `heat_always` | measured ≥ 1.5x; every fast-path clock read labelled, no gameplay deadline on wall clock; differential: same named outcomes, event order, plant caught both speeds; final full run passes at 1x too | < 1.5x; any outcome differs between speeds; a hole seen only at 1x in the final run (then T1 cost us a loop) |
| **T2** | Claude runs | Plant matrix: one import per unchanged proof batch; early exit on receipt-complete detection (GPT's rule); a new hole's plant proved when its check is written; full matrix once at the end; no cross-group batching | D 27 -> ~15; import ~40 s on some launches in A, C, F (measured, counted once) | **Timing (≤ 1.5 min):** `run_game.sh --headless --import` twice, no change. **Pilot (≤ 3.5 min):** group `looks` full vs early exit | second import ≥ 30 s, else drop the skip; early exit gives identical detections in ≤ 70 % of the full time; a receipt missing activation -> NOT PROVED; `looks` with only `lean_close` -> `fast_turn` NOT PROVED; a touched `.gd` forces the import | early exit misses or mislabels a detection; a stale import accepted |
| **T3** | GPT specs, builder builds | First full run (fast if qualified), then only the scenarios the change map selects (unknown / shared input, clock, save, reset, judge -> all seven); receipts (revision, manifest hash, profile, fixtures; no greens across revisions); stall -> stop, diagnose, relaunch the rest by command; one final full run at the final revision; GPT's design-to-check audit up front (0 game min) | A 59 -> ~40 at 1x (~30 with T1); C 40 -> ~15 | **Offline (0 min):** map mutation (local / shared / unknown change) + receipt replay (missing -> INCOMPLETE, other revision -> refused). **Game (≤ 3 min):** a 3-scenario plan with a test-side hang in scenario 2: it stops, then `resume` runs scenario 3, one verdict lists both | the controls above; one verdict covers all; final suite on the original paths | the map misses a dependency the final run then finds (a late loop); a receipt from a stale revision accepted |
| **T4** | GPT specs, builder builds | Discovery walk: stop on a broken expect, first-failure state + shots, BLOCKED upstream, carry on only at a declared independent section; fix found breaks together; resume from points with a revision stamp and a passed **equality check** (section 4); then the take: **option A** one fresh unjoined take, **option B** a joined take with the joins listed (the user picks) | B 52 -> ~18; E 23 -> ~8 (A) or ~5-8 (B) | **(≤ 3 min):** a known baseline plant on a short interaction: BROKE with its original text, actions stopped, one declared independent branch played, upstream BLOCKED; offline, remove one action -> INCOMPLETE. Plus section 4's round trip at one point inside the encounter (≤ 2 min) | discovery play is never CLEAN; a point from another revision refused; a point that fails the equality check is refused, never a silent pass; the take has the original assertions, picture and sound, and is watched | a substituted branch hides or invents a fault; a resumed step passes where a fresh run fails |

**The take, two options (the user's call):**

| | A: one fresh take | B: a joined take |
|---|---|---|
| Cost if the first take is clean | one full walk (~7-8 game min: row E 23 = 3 takes; encoding isn't metered) | the same |
| Cost if it fails at step k | another full walk (~7-8) | only steps k..21 (~2-5, I think) |
| What it proves | one continuous play | each part played, joined at restored state; only as good as the equality check at each join |
| What the user sees | no cuts | cuts, listed with times |

**Budget with the concessions (I think; 2x is the hinge):**

| Row | 1x | 1.5x | 2x |
|---|---:|---:|---:|
| A first + final (final at 1x) | 40 | 33 | 30 |
| B discovery + resumes | 18 | 12 | 9 |
| C targeted (~3 min stay 1x) | 15 | 11 | 9 |
| D plant matrix | 15 | 10 | 8 |
| E one take (Movie Maker) | 8 | 8 | 8 |
| F benches, killed | 9 | 6 | 5 |
| **Total** | **~105** | **~80 (miss)** | **~69** |

Break-even ≈ **1.7x**. Pilots not included (next).

**Order of the first experiments** (each gate decides whether the next is worth its minutes):

1. **Offline, 0 game min, all trials:** label every clock read on the fast path; list the save point's
   fields (section 4 step 1); T3's map and receipt controls; T4's missing-action control.
2. **T1 speed probe, ≤ 2 min.** The whole plan hangs on it. < 1.5x: stop, report to the referee, and
   don't spend the remaining pilots as planned (the plan can't reach 75 as written). 1.5-1.7x: go
   on, flagged "likely miss".
3. **T2 import timing, ≤ 1.5 min.** Decides whether the import skip exists at all.
4. **Section 4 round trip, ≤ 2 min.** Resume is used by T4 and by every trial's fix loop; it must be
   trusted before the trials lean on it.
5. **T1 differential, ≤ 4 min** (after the test-code clock split is built).
6. **T2 early-exit pilot, ≤ 3.5 min.**
7. **T3 stall pilot, ≤ 3 min.** 8. **T4 discovery pilot, ≤ 3 min.** 9. Recording clip, ≤ 1 min, only if
   test clocks changed.

Total ≈ 20 game min. **For the referee:** if the pilots run in the trial copy they eat a quarter of the
75. I think they're a one-time qualification (the method is reused after it's adopted), so they
should be metered and reported **separately**; the referee rules.

## 4. Proposal: check "a resumed step's state equals the uninterrupted run's" cheaply

Three layers, cheapest first. The fresh run that wrote the point always played on past it, so the
uninterrupted side is already there; no extra fresh play is needed.

1. **Offline field coverage (0 game min).** A script lists every script variable of `Ghat`, Problem /
   `Creature`, `Camper`, the players, and their child nodes, marked saved / not saved / skipped as
   non-plain. Plus a grep for variables set from `Time.get_ticks_msec()` in those classes (found:
   `Creature._item_ms`). Each unsaved field gets a reason or a fix (absolute times stored as "ms ago").
   This already shows the four gaps in section 0.
2. **Round trip, exact, ≤ 1 min per point.** On resume, right after `_restore_live` and before any
   frame passes, collect the same snapshot again (`SaveGame.collect(raw)` + `_snap_live` + creature
   positions + van velocity + `engine_on` + held + Naresh) and diff it with the saved point. It should
   be **identical**. Every difference is a field the restore drops (it would show today's
   velocity = 0 and `engine_on = false` at once). No game time beyond the boot of a resume we run anyway.
3. **Probe at +K, ≤ 1 min extra.** Every run writes a second snapshot **K = 3 game s after each step's
   point** (game clock, before the step's later actions drift). The fresh run has it for every
   step it passed; a resume writes it at the same offset. Diff with tolerances: discrete values
   (phase, state, seats, held, flags) exact; positions ≤ 0.1 m; floats ≤ 2 %. The noise floor comes
   **once per boundary**: resume twice from the same point and diff the two (if two resumes differ
   more than the tolerance, the tolerance is wrong, not the restore).

**Verdict per boundary:** SAME, or DIFFERENT with the field list. A step that passed after a DIFFERENT
resume is marked "resumed, state differs: <fields>" and doesn't count until a run from a SAME point
(or fresh) passes it. Only the boundaries we actually resume from (or join a take at) are checked.

**Cost:** layer 1 ~30 min of code, layers 2-3 ~30-40 min; game time ~1 min per boundary qualified
(the noise-floor resume), the rest rides on runs we make anyway. **Weakness:** a field no snapshot
lists (an in-flight `await` in a puzzle script, a physics contact) is invisible to layers 2 and 3;
layer 3's outcome compare (the step's expects and the trace's event order matching the fresh run) is
the only net for those. I think that's acceptable for diagnosis and for option B joins, and it's
why a joined take still needs the user's yes.
