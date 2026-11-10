# Stage 2, round 1: the Claude auditor's audit (2026-11-10)

Read again: `stage1_task.md` and the same allowed set; both idea files. New reads this round, all at
`5f3e3e3` or `h1` (allowed): `prove_ghat.py`, `method_watch.py` (grep), `run_test.sh`, `run_game.sh`,
`record_walk.sh` (both), `play_walk.sh` / `live.py` (h1), `LiveControl.gd` `_run_walk` (lines 366-475),
`SaveGame.gd` (grep), `project.godot` (grep), the wall-clock reads in `Camper` / `VanAttack` / `Hearing` /
`Carryable` / `PlayerRig`. Nothing forbidden read; **no hole named by accident** that I can tell. No
file written anywhere but this one (nothing on C:), no game started.

Rows: **A** full runs 59 · **B** walk plays + live replays 52 · **C** single-scenario reruns 40 ·
**D** plant runs 27 · **E** takes + encoding 23 · **F** benches, killed, ramp 22 (sum 223, GPT is right).

## New facts found this round (measured = read in the code)

1. **A save point is partial, and inside the encounter it is rewound.** `LiveControl._run_walk` restores
   `SaveGame.apply` + creature **positions only** + held items + Naresh's simple states. Creature
   state (Problem's phase, interest, timers) is not saved; watches are **re-armed fresh** with a new
   `within`. And `SaveGame.collect` calls `Ghat.adjust_save`: "a save in the middle of the ghat's
   encounter goes back before it", while `apply` calls `ghat.match_story`. So a point taken mid-encounter
   gives a **mixed state**: the story before the encounter, the creatures where they stood during it.
   The point files carry **no code revision**; they are rewritten by whatever code ran last.
2. **Takes already run the game off real time:** `record_walk.sh` uses `--write-movie ... --fixed-fps 25`.
   With 60 physics ticks a second that is 2-3 ticks per frame, every frame exactly 1/25 s of game time.
   So the game has run in a fixed-step, not-real-time mode on every take. `--fixed-fps 60` is the
   *same* mode at the play's own frame cadence (1 tick per frame).
3. **prove_ghat.py = 11 groups = 11 `method_run.sh` = 11 compiles** (`run_test.sh` compiles unless
   `NO_CHECK`, "~40 s" by its comment, not measured by me): ~7 of row D's 27 min could be compile.
   Attribution is a substring of any FAIL line (`any(t in ln for ln in fails)`).
4. `project.godot`: physics ticks, vsync, max fps all default (60 / on / 0); physics interpolation on.
   The watcher's own limits (`no_physics_s` 10, `pause_s` 5, `startup_first_beat_s` 45) are host
   seconds: health checks, which only get easier to meet when the game runs faster.

---

## 1. Audit of GPT's 7 ideas

### G1. Validated resume (provenance, invalidate on dependency change)
- **Holds, with evidence I found (fact 1)**: points are partial, mid-encounter points are rewound by
  the game's own save, and there is no revision stamp. So the referee's "resumed at step 9
  mid-encounter, ran clean" is one pass, not proof that the state matched: it may have passed *because*
  Problem restarted in a fresh phase. That is a **false pass** route GPT named before I saw it.
- **How it fails:** *cost* and *false alarms*. Validating "transforms, velocities, phases, timers, input
  holds" for 21 steps is a framework (GPT's own 30-60 min "more"). "Invalidate when a dependency of the
  producer changed" needs the same file -> step map as G3; with an unknown map every change
  invalidates every point and the saving is gone. Its minutes (25-35, row B) are mostly **the h1
  tool's**, which the referee now treats as given: G1 by itself saves nothing; it is a **guard**.
- **What I'd change:** the cheap version only: stamp each point with `HEAD` + a hash of the dirty
  game files + the walk's hash; on resume print which game files changed since the point; the rule
  "resume from inside the encounter is not allowed: the nearest point **before** it" (fact 1 makes
  those the only points whose state is really the game's). The state compare (GPT's experiment) once,
  on one boundary, using the trace of C7 for the fields.

### G2. One bounded discovery pass, blocked branches, restart at an independent branch
- **Holds in part.** Same aim as my C5 (one play lists many breaks). GPT's is stricter: no in-place
  repair; stop, mark BLOCKED, restart at an independent section.
- **How it fails:** *cost*: each restart is a new process (boot + world load, ~40 s+ each, the brief's
  meter counts it) and a model decision per break; if the game waits open while the model decides,
  it is metered idle time. *Wrong blame*: "independent branch" is a model's judgment (GPT warns of
  it itself). It does guard my idea's real weakness (below).
- **What I'd change:** merge with C5 (see 3): repair in place where the promised state is a simple
  game-own setter **outside the encounter**; inside the encounter, BLOCKED + jump to the next section
  that starts from a dev-menu setup (GPT's rule). One process, both guards.

### G3. Defer full suites; a conservative change-to-check map; receipts
- **True duplicate of my C4**; agreed on the map (unknown or shared file -> all seven) and one final
  run. **Disagree on dropping the first full run.** Reason: a ghat run is one process whose FAILs don't
  stop it (`method_watch`: only STALL / TEST / NOT HEALTHY stop), so one run shows every failing check of
  113 at once for ~20 min; the walk and "design review" cannot see a scenario's checks. Without it, a
  scenario hole first shows in the final run -> fix -> another final run (+20) -> the loop the rules ban.
  GPT's 39 min gross assumes that never happens.
- **GPT is better on receipts** (revision + manifest hash; never stitch greens across revisions): adopt.
- **Missing in GPT's:** a STALL in scenario 2 today drops 3-7 unseen; my relaunch-the-rest fixes it.

### G4. Short paired reproductions (`--case`)
- **"I think", untimed** (GPT says so): a ghat scenario averages ~3 min (20 min / 7, load included), so a
  case cuts maybe 1-1.5 min per rerun; GPT's 15-22 min (row C) needs ~12-15 reruns all with long
  prerequisites, not shown. *False pass of the fix* (the case passes from injected state, the scenario
  still fails) is caught by the final run, so no false pass at the end, but a wasted loop.
- **Build cost** 30-60 min for one case family, and it overlaps fast mode + the compile skip + the
  existing gym rule (after 2-3 failed fixes, a bench).
- **What I'd change:** drop as a trial; keep as the bench rule's tool for a scenario rerun ≥ 3 times.

### G5. Acceleration only with differential evidence
- **True duplicate of my C1.** GPT's **pass bar is better**: 1x vs fast, clean and with a known plant,
  same events, order, outcomes; record the achieved speed, not the asked one. Adopt.
- **Where it's wrong or thin:** (a) "don't assume `--fixed-fps` alone yields faster physics": right that it
  alone doesn't (the frame is still capped by vsync); with `--disable-vsync --max-fps 0` it runs as fast as
  a frame can be made, and fact 2 shows the game already lives in this mode on every take. The
  2-minute speed probe settles it. (b) It **misses the main false-pass route**: the checks and the
  walk's deadlines are **wall clock today** (126 reads in `PlayTest`, 11 in `LiveControl`), so at 2x
  every "within N s" allows 2N game seconds: a check that must fail can pass. A 25-s differential
  segment only catches that if a deadline inside it is near its limit. Needed in the bar: **zero
  wall-clock reads on the path run fast**, shown by a grep, not only by agreement. (c) `Engine.time_scale`
  (GPT's candidate A) lengthens each physics step unless the tick rate is raised with it: a physics
  change; I'd not trial it.
- GPT's estimate (15-30 "additional") is low because it applies only to what's left after its other
  ideas; both budgets show 75 is **not** reached without it (mine: ~99 at 1x, below).

### G6. Prove plants once at the final revision, causal attribution
- **True duplicate of my C3** (different parts). GPT is right that grouping already exists (fact 3), so
  "grouping" earns nothing new, and right that a substring in *any* FAIL line is thin attribution.
- **How it fails:** proving only at the end risks a late NOT PROVED -> fix -> rerun loop. GPT's own
  answer (targeted proofs while fixing, one full matrix at the end) is correct; I agree because a new
  hole's check is cheapest to prove the moment it is written (its plant and scenario are fresh).
- **Missing in GPT's:** the 11 compiles (~7 min) and stopping a group once its expected FAILs are in.
  GPT's A, B, A+B experiment is the right **gate for batching**; adopt it.

### G7. Qualify the recording once, record the final fresh walk
- **True duplicate of my C6.** GPT is stricter and **right**: the acceptance take is one fresh,
  unstitched play. Reason (fact 1): a join restores a partial, possibly rewound state, so the video can
  show a state the game never reached. h1's stitching stays for diagnosis or a preview, labelled.
- **Doubt:** the preflight clip (2.5 min of game) pays only if takes failed for recording reasons; the
  real cause of day 2's 3 takes is not known to me. Cheaper guard: Movie Maker runs at `--fixed-fps
  25`, so with the walk's deadlines on the game clock (C1) a take behaves like a play, and the preflight
  isn't needed. Encoding is not a Godot process: both of us say it's not metered (referee: confirm).

## 2. Re-audit of my own 7

| Mine | Verdict after GPT's | Why |
|---|---|---|
| C1 fast mode + game clock | **keep, changed** | My step 1 changed game timing (cap window, hearing): that is changing the game, and could move a timing hole. Now: a `Clock.ms()` that **returns `Time.get_ticks_msec()` unchanged in normal play** and summed physics time only under the test flag `--fast`; game behaviour at 1x identical (a pure refactor; the referee still OKs it). Test code (`PlayTest`, `LiveControl`) on the game clock. GPT's differential bar added. |
| C2 one compile per change | **keep** | No counterpart; fact 3 makes it ~7 min in row D alone. Still unmeasured: the 90-s timing decides. |
| C3 plants stop at FAILs | **merge with G6** | Keep early stop + one compile; batching only after GPT's A / B / A+B gate; attribution by the FAIL's begin time inside the plant's own window. |
| C4 first + last full run | **merge with G3** | Take GPT's receipts; keep the first run and the stall relaunch; **drop my jumped fix-checks** (GPT's G4 critique of injected state applies to mine, and they'd need `--case`). |
| C5 note-and-repair walk | **weakened, merge with G2** | Fact 1: a repair inside the encounter would build the same mixed state; repair in place only outside it, BLOCKED + fresh section jump inside it. |
| C6 record once | **merge with G7** | No stitched acceptance take; drop my lower-resolution idea (the user judges the picture). |
| C7 trace, shots, no idle game | **keep as a rider** | Not a trial of its own: it supplies the state fields for G1's compare and cuts benches in every trial. "No idle game" is a rule for all trials. |

## 3. Duplicates merged

| Merged idea | From | Distinct? |
|---|---|---|
| M1 Fast mode on the game clock | C1 + G5 | true duplicate |
| M2 Plant matrix: one compile, early stop, gated batching, attribution | C2 + C3 + G6 | C3/G6 true duplicates; C2 added |
| M3 First + last full run, change map, receipts, stall doesn't drop the rest | C4 + G3 | true duplicate |
| M4 Discovery walk with guarded resume, one fresh unstitched take | C5 + G2 + G1 + C6 + G7 | C5/G2 and C6/G7 true duplicates; G1 is a guard |
| (rider) Trace + failure shots + no idle game | C7 | own |
| (fallback) Short cases for a scenario rerun ≥ 3 times | G4 | own |

14 ideas -> 4 trials + 1 rider + 1 fallback.

## 4. The TOP 4

Why this split: M1 and M2 are engine and tool code (Claude's ground: game flags, GDScript clock,
the watcher); M3 and M4 are mostly **rules, maps and receipts**, which GPT audits and specifies well, and
a builder can follow a spec for them without inventing.

### T1 (Claude runs): fast mode on the game clock (M1)
**Trial.** `Clock.ms()` (normal play: `Time.get_ticks_msec()`, byte-for-byte the same behaviour;
under `--fast`: summed physics time), used by `PlayTest`, `LiveControl` and the ghat-path game code
(`Camper`, `VanAttack`, `Hearing`, `Carryable`, `PlayerRig`) and the `free_coolant` plant. `run_test.sh`
/ `play_walk.sh` get `EARGS` before the `--`: `--fixed-fps 60 --disable-vsync --max-fps 0`, `--fast`.
Used for every **unrecorded** run (discovery, reruns, plants, trial plays); the take stays Movie Maker.
**Saves** (rows A, C, D, B; on what the other trials leave, ~70 min at 1x): **~30-40 min at 2x, ~20 at
1.5x, I think.** **First experiment (≤ 2 min):** `ghat_places` with the flags, no clock change yet:
physics frames per wall second from the heartbeat's `pf` -> the real factor. Then (≤ 4 min) GPT's
differential on a short nonvisual stretch of `ghat_heat`: 1x and fast, clean and `heat_always`.
**Pass bar:** factor ≥ 1.6x measured; `grep get_ticks_msec` on the fast path = 0 outside health code;
the differential gives the same named outcomes and event order, plant caught at both speeds;
at the end, the 27 plants PROVED and the clean run PASS at fast, and the final full run also
passes at 1x (one 1x run, so a speed-only pass can't slip through). Below 1.6x: drop it, report.

### T2 (Claude runs): the plant matrix and one compile per code state (M2)
**Trial.** `run_test.sh` skips the compile when a hash of every `*.gd`, `*.tscn`, `*.tres`,
`project.godot` and the asset folders equals the last clean compile's. `prove_ghat.py` passes each
group's expected texts to the watcher, which stops the game once all have begun in FAIL lines;
attribution also needs the FAIL's begin inside the run. A new hole's plant is proved when its check is
written (one group); the full matrix runs once at the final revision. Batching groups only if A, B,
A+B agree. **Saves** row D 27 -> ~12, plus ~40 s on most other launches (rows A, C, F): **~15-22 min at
1x, I think.** **First experiment (≤ 4 min):** time `run_game.sh --headless --import` twice with no
change (~1.5 min); then group `looks` with early stop (~2.5 min). **Pass bar:** second compile ≥ 30 s
(else drop the skip: Godot caches it already); `looks` stops early with both plants PROVED in ≤ 70 %
of the full group's time; **a control can still fail:** `looks` with only `lean_close` planted gives
`fast_turn` NOT PROVED; a touched `.gd` forces the compile.

### T3 (GPT specifies, builder builds): one discovery run, a change map, one final run (M3)
**Trial.** A full ghat run at the start; between, only the scenarios the change map selects (GPT's
table: changed file -> checks -> scenarios; shared input / clock / save / reset / judge or unknown ->
all seven); receipts with revision, manifest hash, profile, fixtures; a STALL / TEST in one scenario
relaunches the scenarios not yet started and merges one verdict; one final full run at the final
revision, any relevant change after it voids it. **Disputed:** the first run (GPT: drop it; me: keep,
reason in G3); the spec should let the referee see whether the first run found a hole nothing else
did. **Saves** row A one middle run ~20 + row C ~10: **~25-30 min at 1x, I think.** **First experiment
(≤ 4 min):** offline, GPT's map mutation test; then a 3-scenario plan with a stall planted in scenario 2
(a test-side hang): scenario 3 still runs. **Pass bar:** one verdict judges all three; an unknown file
selects all seven; a removed receipt -> INCOMPLETE; a receipt from another revision is refused.

### T4 (GPT specifies, builder builds): the discovery walk, guarded resume, one fresh take (M4)
**Trial.** `live.py --walk ghat.json --note`: on a failed expect, log `BROKE`, take the shots (rider),
then outside the encounter put the step's declared promised state with game-own functions and play
on ("after repair" on every later line); inside the encounter, BLOCKED and jump to the next section's
dev-menu setup. Fix all found breaks together; resume only from points stamped with the current
revision and lying **before** the encounter when the change touches it; the acceptance is **one fresh,
unstitched recorded play** (record the final play, no separate clean trial). **Saves** row B 52 -> ~15,
row E 23 -> ~8 (one take): **~45-50 min at 1x, I think** (overlaps T1 on B). **First experiment
(≤ 4 min):** from step 13's point with `no_fix` planted: BROKE at 16, repair, reach the end; and G1's
check: one spring boundary fresh vs resumed, compare held pot, litres, seats, Problem's phase (trace).
**Pass bar:** BROKE carries the original failure text and shots; the play's verdict is NOT CLEAN (it
can never count); a point from another revision is refused; the state compare matches or the point is
refused (never a silent pass); the final take is one part.

### Does it reach 75? (I think; overlaps removed)

| Row | Day 2 | All four at 1x | + T1 at 2x |
|---|---:|---:|---:|
| A full runs (first + final) | 59 | 40 | 30 (first 10 fast, final 20 at 1x) |
| B discovery walk + resumes | 52 | 15 | 9 |
| C targeted reruns | 40 | 15 | 8 |
| D plant matrix | 27 | 12 | 7 |
| E one take | 23 | 8 | 8 (Movie Maker) |
| F benches, killed | 22 | 9 | 6 |
| **Total** | **223** | **~99 (fails)** | **~68** |

So both files' budgets agree on one thing: **without fast mode the target is out of reach**; at 1.5x it
is ~76, at the edge (the 1x final run costs 10 min of the speed-up; it is the guard against a pass that
only holds fast, and I'd keep it). **Run T1's 2-minute speed probe and T2's compile timing first**: they decide
whether this plan can pass at all, for under 4 game minutes.
