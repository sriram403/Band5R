# Pilot P1 (Stage 3): T1 speed probe + T2 compile timing. Claude auditor, 2026-11-10

Task: `MPG\notes\speed_research\trial_T1_pilot_task.md`. Copy `MPG_speed_t1`, branch `speed-t1`.
Read: the task's read-only list only (SPEED_RESEARCH, scoreboard, top4, audit_r2 x2, TESTING_METHOD)
plus files inside this copy. Game code untouched. One game at a time, every run watched every 3 s.

## Verdict: NO-GO for the 2x column

**Uncapped `--fixed-fps 60` runs the ghat at 1.24x on this PC (steady), not >= 1.7x.**
Both audits' budget models then give ~87-91 min, not 75:
Claude `31 + 74/1.24 = 90.7`, GPT `37 + 62/1.24 = 87.0`. The plan in `top4.md` can't reach 75 min
through speed-up as built. Per the task, I stopped at step 2: steps 3 and 4 not run.

Game minutes used (my own count; the referee's meter decides): cold import 9.9 s + 1x probe 56.4 s +
fast probe 56.1 s = **~122 s ≈ 2.0 game min** of the 8.

## Step 1: every wall-clock read on the ghat path (offline, 0 game min)

How: a script walked the call graph from every `t_ghat*` in `PlayTest.gd` (44 functions reachable)
and listed each `Time.get_ticks* / get_unix_time / OS.delay / datetime`; read `MethodRec`, `GhatWatch`,
`RigBeat`, `LiveControl` and `tools/method/*` by hand.
Classes: **D** = gameplay deadline / judgement (must be the game clock under fast mode),
**H** = health (host seconds, stays wall), **R** = reporting only.

### Test code

| Where | What | Class | Under fast mode |
|---|---|---|---|
| `PlayTest._ghat_heat_run` 4439-42 | wait for phase `circle`, 90 s cap; "reached the van in N s" | D + R | cap loosens by f (90 wall s = 112 game s at 1.24x) |
| `PlayTest._ghat_heat_run` 4448-70 | wait for `first_attack_over`, 120 s cap; log | D + R | loosens |
| `PlayTest._hide_well` 4694-97 | hide until `leave`, `max_s`; returns false on the deadline (a check) | **D** | loosens: a slow give-up can pass |
| `PlayTest._fix_with` 4857-60 | hissing stops, 120 s cap; log | D + R | loosens |
| `PlayTest.t_ghat_spring` 4941-42 | breath held + fogged, 120 s | D | loosens |
| `PlayTest.t_ghat_spring` 4963-64 | phase `leave`, 150 s | D | loosens |
| `PlayTest.t_ghat_spring` 4994-95 | **it comes back within 5 s** after the cap blows | **D (tight)** | 5 wall s = 6.2 game s: a 5-6 s return would pass fast, fail at 1x |
| `PlayTest.t_ghat_marks` 5052-53, 5080-81 | phase `circle` 60 s; posed stops 120 s | D | loosens |
| `PlayTest.t_ghat_looks` 5324-25, 5334-35, 5359-60 | `circle` 60 s; 4 stops 80 s; `leave` within `SEARCH_S + 45` | D | loosens |
| `PlayTest.t_ghat` 5426-27, 5520-21, 5534-35 (not in the method's 7; in the sets) | fog 8 s; **a fixed 45 s watch loop**; 20 s | D | the 45 s loop watches 56 game s |
| `PlayTest.walk_breath_bot` 4582-84 (walk helper, `tools/live/ghat.json`) | hold breath until `leave`, `max_s` | D | loosens |
| `PlayTest._run` 500-07, 566-87 | "time <scenario> N s" | R | prints wall s, not game s |
| `PlayTest._ready` 85, `_notification` 104 | focus-in within 3 s = Godot's own, later = the user's click | H | stays wall |
| `PlayTest._hand_focus_back` 187-93 | window-move loop, 3 s, `OS.delay_msec` | H | stays wall |
| `PlayTest.wait()` → `create_timer(s, true, false, true)` | process-frame delta; `ignore_time_scale = true` | game clock under `--fixed-fps` | OK. Note: `Engine.time_scale` would NOT speed these waits (another reason fixed-fps is the candidate) |
| `tap()` (70 ms hold), `physics_frames()`, `hold_physics()`, the `t += 1/60` loops (4375, 4403, 4681, 4918, 5074, 5286, 5317) | frame / tick counts | game clock | OK |
| `MethodRec.open(step, secs)` (wait, frames, hold, shot 5 s, `episode:` `EPISODE_S`) | secs written in **game** s, judged by `method_watch.py` on **host monotonic** | **D** (the STALL deadlines) | loosen by f: a step overrunning its budget by < f x is not caught. Fix: judge `(pf_now - pf_open)/60 > secs` (each event already carries `pf`), keep a wall backstop as H |
| `MethodRec.ev` `unix` stamp | condition order, headline tie window 2.0 s | R (ordering) | 2 s wall covers 2.5 game s; use `pf` to order |
| `GhatWatch` H1-H3 | per physics tick, no clock | game clock | OK |
| `RigBeat` beat `ms` (wall), `pf`, `wf` | heartbeat every 0.5 s of process delta | H (ms) / game (pf, wf) | OK; beats come f x as often in wall terms |
| `LiveControl` 593, 601, 614, 622, 675, 683 (walks) | watch `until` = now + within; step `max`; checked against `get_ticks` | **D** | loosen |
| `LiveControl` 488, 600, 621, 637, 644, 682 | step / PASS / DONE times, `at` datetime | R | wall s in the log |
| `LiveControl` `until` (`t += 0.1` per `wait(0.1)`), 82 poll `create_timer(0.05)` | iteration count / frame delta | game clock | OK under fixed-fps |
| `method_watch.py` limits: startup 45, no beat 20, no physics 10, pause 5, missing-actor beats, kill verify 5, script-error grace 2, progress 5, whole-run cap 600 / 3300 | host monotonic | H | stay wall |
| `method_watch.py` `step_secs`, `opens_max` | step durations from `unix` | R | would show wall s; switch to pf |
| `method_verdict.py` | `unix` for begin / order, wall total | R | as above |
| `run_test.sh` `TIMEOUT` 3600 | process kill | H | stays wall |
| `prove_ghat.py`, `host_fixture.py`, `make_ghat_manifest.py`, `freeze*.py`, `method_run.sh` | no clock | - | - |

**Count:** 19 gameplay-deadline sites (D) in test code: 12 in the 7 method scenarios and their
helpers, 3 in `t_ghat`, 1 walk helper, the `MethodRec` -> `method_watch` STALL deadlines (one
mechanism, every `wait` / `frames` / `hold` / `shot` / episode), and `LiveControl`'s watch and step
limits (2). None unlabelled. All loosen (never tighten) under speed-up, so fast mode can't cause a false
STALL, only a **false PASS** of a tight deadline (`t_ghat_spring` 4995: 5 s).

### Game code on the ghat path (untouched; it decides what can't be qualified)

| Where | What | Effect under speed-up |
|---|---|---|
| `Camper._blow_cap` 1650 | the cap can't blow again within 3 wall s | 3.7 game s at 1.24x: changes S2 (ghat_spring) |
| `Camper` 1171, **plant `free_coolant`** | fires when `fmod(wall s, 5) < delta` | activation tied to wall clock and frame pacing: the plant's rate changes (proof `jug_b`) |
| `Hearing.emit` `KEEP_MS 2000`, `Creature._item_ms` bounce 1500 ms | sounds stamped in wall ms | the "bounce" window covers 1.86 game s at 1.24x; also the h1 resume problem (absolute ms across processes) |
| `Carryable._on_hit` 150 ms | hit-sound debounce | slightly fewer knocks at speed |
| `Camper` 1302 nav flicker, `PlayerRig` 311 torch flicker, `EngineAudio` 109 | cosmetic | none for checks |
| `Naresh` 943 / acts, `VanAttack.last_honk_ms`, Storm, Windmill, BarnMaze, BessiTasks | other puzzles / not on the ghat checks (I think) | - |
| `Boot`, `LevelBuilder`, `LevelScatter` | build timing prints | R |

So even with every test clock moved to the game clock, `ghat_spring` (cap) and the `free_coolant`
proof would stay 1x-only unless the game code changed, which this research forbids.

## Step 2: the speed probe (2 runs, 112.5 s of game process)

**Scenario: `ghat_heat`**, the first ~38-40 s (foot of the ghat -> flat out up the road -> Problem sees
the van at hairpin 1 -> boils). Why: it is one of the two biggest shares of a suite (episode 660 s of 3,360 s; `ghat_spring` 780),
and the heaviest load (moving camera, terrain, the creature, the encounter). A static scenario such as
`ghat_places` would overstate the speed for the suite.

**How:** `NO_CHECK=1 TIMEOUT=55 tools/run_test.sh ghat_heat` (1x) and the same with `FAST=1`
(adds `--fixed-fps 60 --disable-vsync --max-fps 0` before the `--`; new switch, below). Window as the
tests run it: `--position 4000,0`, then behind the user's windows (seen at (160, 77), drawn, not
minimized; tests never run minimized, so no minimized run). Muted. `rig.txt` emptied before each run.
`tools/method/speed_probe.py` read the heartbeat every 3 s: game speed = (Δ physics frames / 60) /
Δ wall s, from the beat's `pf` and `ms`. One game at a time; `tasklist` empty before and after each.
PC: RTX 3060, 144 Hz screen, window 1600x900.

| Run | Scenario stretch (wall) | Game s | **Speed** | Steady (after 5 s) |
|---|---:|---:|---:|---:|
| 1x (normal) | 38.5 s | 38.5 | **1.00x** | 1.00x |
| fast (`--fixed-fps 60`, no vsync, no cap) | 39.6 s | 48.6 | **1.23x** | **1.24x** |

Fast run in 5 s slices: 1.15x (start, jump settling), 1.14x (accelerating), **1.41 / 1.37 / 1.38x**
(flat out, empty road), **0.98x** (the encounter: it sees the van, follows, boils it; 17 ms/frame),
1.19x (the shot), 1.16x (the reset for the next profile). Frame cost ≈ 12-17 ms (59-85 fps).

**Why it's the frame cost, not a cap:** 85 fps max is far below the 144 Hz vsync rate, so no cap was
binding; each frame now pays one full render per 1/60 game s (at 1x the game draws fewer frames and
steps physics in between). Boot (launch -> first beat) ~17 wall s in both, not sped up at all, and it
is paid per process.

**Side look, same inputs (not the step-4 differential):** the per-second telemetry lines of the two
runs agree closely but not exactly (t = 1: 17.1 vs 17.7 km/h, 89.5 vs 88.3 C; later within ~1-2 road
samples and 0.1 C); both see the van at road sample 268 (apex 259) with the same phase sequence. The
start differs because at 1x a `wait()` ends on a 144 Hz process frame, not a physics tick, so the
setup lasts a slightly different number of ticks. 1x itself is not tick-exact: a differential needs
outcome tolerances, not equality.

## Step 3 (compile timing) and step 4 (differential): not run

The task stops at the first "no". One free data point: the **cold** import of this copy (no `.godot`
folder at all, 140 audio files): `tools/run_game.sh --headless --import` **9.9 s**, rc 0, no errors.
A warm import is normally no slower than a cold one, so I think T2's gate ("second import >= 30 s,
else drop the import skip") already falls: skipping it saves < 10 s per launch. Untested; ~0.5 game
min to confirm (two warm imports + one after touching a `.gd`).

## What I'd change

1. **Don't build the T1 clock split now.** At 1.24x it buys ~10 % of A-D for ~1-2 h of build, and
   `ghat_spring` + the `free_coolant` proof stay 1x anyway (game-code wall clocks).
2. **Cheapest next question (≤ 2 game min, the referee's call): where does the 13 ms frame go?**
   One fast `--headless` probe (no drawing: the simulation's own ceiling) and one fast probe at
   `--resolution 800x450`. If headless is ≫ 2x, rendering is the cost, and non-visual stretches could
   run at a small window. If headless is also ~1.3x, physics / scripts are the cost and speed-up is
   dead on this PC.
3. **Try parallel instead of faster:** two games at once at 1x (the project measured 112 fps in one
   game while the other ran, 2026-09-27). Independent scenarios in two processes is ~2x on row A / D
   throughput with **no clock change at all**: no deadline loosens, no qualification. It needs
   separate progress dirs per process (`MPG_DATA`), the one-game-at-a-time rule changed for
   proofs, and the referee's meter to count both processes (summed game minutes do NOT fall;
   wall-clock does). **Important for the scoreboard:** the score is summed process minutes, so
   parallel helps the user's real time but not the score as defined. The referee should rule
   which one we're optimising.
4. **Fix regardless (cheap, any speed):** `method_watch` should judge STALL deadlines on `pf`
   (game s) with the wall clock only as the health backstop; the scenario deadlines in the table
   should read `Engine.get_physics_frames()`. Then 1x behaviour is identical and any later speed-up
   (or a slow, stuttering PC) can't loosen a deadline.

## Assumed -> reality -> fix

- **Assumed** (both audits, "I think"): uncapped fixed-fps gives ~1.8-2.5x on an RTX 3060.
  **Reality:** 1.24x on the ghat; 0.98x during the encounter. **Fix:** stop T1 as a budget lever;
  measure the frame split before more speed work. **Habit:** the GPU/fps headroom at 1x (144 Hz vsync)
  says nothing about fixed-fps throughput, where every game tick pays a full render.
- **Assumed:** the import is the "~40 s" of the comments. **Reality:** 9.9 s cold. **Habit:** time it
  before planning around it.

## Tool changes (committed on `speed-t1`)

- `tools/run_test.sh`: `FAST=1` (= `--fixed-fps 60 --disable-vsync --max-fps 0`) and `ENGINE_ARGS=...`,
  both inserted before the `--` in both launch lines; prints "engine args: ..." when set. Default
  runs unchanged. Passes through `method_run.sh` (env).
- `tools/method/speed_probe.py`: reads `rig.txt` every 3 s, prints the speed, ends with a `SPEED` line.
- Raw logs (not in git): `appdata/pilot/` (`import_cold.log`, `probe_1x.out`, `probe_fast.out`,
  `rig_fast.txt`).
