# T4 v2 builder report (Claude builder for GPT's spec, 2026-11-11)

Task: `MPG\notes\speed_research\trial_T34_v2_build_task.md` (read first; only its list read). Copy `MPG_speed_t34`,
branch `speed-t34`, `speed-t1` merged first (fast-forward to `4a74146`, T1 + fix round kept intact).

## Game runs (cost written before each run; wall game min, my count; the referee's meter decides)

| # | Run | Expected | Wall | Watched | Result | T4 total |
|---|---|---:|---:|---|---|---:|
| 0 | import / compile check (headless, cold cache: this copy had no `.godot/`) | 0.5 | 0.18 | inline | rc 0, no errors | 0.18 |
| A | lane a, play: `gateprobe_cancel` (FAIL) + 5 s of probe_state reads | 1.5 | 0.85 | inline | FAIL as planned; after it no press (73 dropped by the gate, the one later send = the old helper's CTRL release), checking helper gone at once; **but CTRL read held at the failure picture** (release queued, not flushed): fixed (flush), stopped to rerun on the fixed code | 1.03 |
| A2 | lane a, play: `gateprobe_cancel` + reads, `gateprobe_clean`, fresh `gateprobe` (points) | 1.5 | 1.83 | inline + walk.log every 4 s | cancel control PASS (nothing held at the picture; old-style helper's presses all dropped (73); checking helper stopped at once; only later send = a release); clean pair DONE; **gateprobe FAILED at its own step 2** (pad A did not swing the nav; picture: solo view). I first blamed "the 4th walk of the process": **wrong**, A3 failed the same way in a fresh game (see Deviations D2) | 2.86 |
| A3 | lane a, play: fresh `gateprobe` alone in a new game (the producer) | 0.6 | 1.55 | walk.log every 4 s | FAILED again at step 2 (pad A: solo view, see Deviations D2); probe walk changed to P1's N key; rerun in the same game: **DONE**, 6 points; point 1 eligible, point 4 refused (engine on, engine sounds < 2 s) | 4.41 |
| R3a | lane a, play: resume point 1 of A3 with the van moved +0.2 m after the immediate observation | 0.5 | 0.42 | inline | **REFUSED before any input** (right outcome, wrong reason: Godot rewrote the walk's ints as floats, so the producer-steps hash differed); the game had been launched before the check: wasted boot. Fixed: numbers compared by value; the gate check now runs before any launch. Then the check refused A3's points for a real reason (I had edited tools/ since): identity split into test (producers) / tools (judges) | 4.83 |
| C1 | (planned by the first builder, **not run**: the offline controls of 2026-11-14 showed no point of this walk can pass the gate, see "Resume 2026-11-14") | | 0 | | | 4.83 |
| G | lane a, play, `tools/method/t4_live_gate.sh`: fresh gateprobe + 4 resumes (layer 2 live x2, layer 3 clean + perturbed) | 1.8 | 1.88 | Monitor (every line) | all on plan, see "Live gate session G" | 6.71 |
| R1 | lane a, **rec25**, alone: `tools/record_walk.sh gateprobe --fresh` (clean clip, engine sound, marker, on-time fixture) | 1.0 | 1.35 | Monitor (every line) | DONE; on-time 9.5/10 PASS at 25 fps; framemap proved (offset 0); "sound PASS" claimed, but no `SOUND:` line was saved (the fix round saved one for R1b, F4); **57 % of real time in the walk, 39 % incl. boot** | 8.06 |
| R2 | lane b plain game + lane a rec25 `record_walk.sh gateprobe --fresh` beside it: `tools/method/lane_sentinel.sh` (T3 sentinel + T4 contention) | 2.2 | 2.67 union (a 1.95 + b 2.67 = 4.62 summed) | Monitor (deduped) | all sentinel facts held; the tool printed FAIL on its own CR bug (fixed); beside lane b: **47 %** of real time in the walk (alone 57 %), DONE, framemap proved, "sound PASS" (no `SOUND:` line saved) | 10.73 |
| R3b | lane a, **rec25**, alone: `NO_MAKE=1 record_walk.sh gateprobe_late --fresh` (just-late fixture) | 1.0 | 1.00 | Monitor | **FAIL by name** at 25 fps ("took longer than its limit"), nothing held at the picture, verified exit; then the resume of that take **refused before launch** (exit 5, 0 min) | 11.73 |
| R4-void | `lane_sentinel.sh` 13:32-13:34 (under GTA): cut by the referee's stop at the user's request (lane b killed at ~13:34:50, the script with it): **void**, rerun as R4 below | (2.8) | ~2.5 | Monitor | void (its 34 % recording figure was under GTA) | ~14.2 |
| R1b | 2026-11-14 14:01, PC idle (no GTA): rec25 alone, `tools/record_walk.sh gateprobe --fresh` (re-measure of R1) | 1.4 | 1.0 (life 59 s) | Monitor every 3 s + CPU sampler | DONE, framemap proved (offset 0), on-time PASS; see "Re-measure (PC idle)" | ~15.2 |
| R4 (T3's run) | 2026-11-14 14:03, PC idle: `tools/method/lane_sentinel.sh` again (CR fix; lane b walking the whole time) | 2.8 | 2.0 union (lane b 2.0 + lane a life 1.0 = 3.0 summed), **charged to T3** | Monitor every 3 s + CPU sampler | "SENTINEL PASS" printed, but **lane b's worker walks: 2 ok of 4** (left out of the first report; the sentinel did not judge its workload: fixed in F5, the same log is now refused); recording beside lane b: see "Re-measure (PC idle)" | ~15.2 (T3 +2.0) |

Totals are my count from the logs (union of game lifetimes per run); the referee's meter decides. The T4 column is T4
only: R4 is T3's sentinel run (its 2.0 is in the T3 report). Builder total before the fix round: ~17.2 (T4 ~15.2 + T3 2.0).

## Resume 2026-11-14: why no point of the probe walk passes the gate

The first builder planned C1 (a rec25 take broken mid-step, then resumed through the gate). The offline controls
(`tools/method/t4_controls.py`, 83 / 83) run the gate's boundary refusal (`walkgate.refusal`, before any input) on the
real points of the probe walk A3 (`gateprobe_20261111_122158_4980`, points 0-5). Every point is refused:

| Point | Refused because (the gate's own words) |
|---|---|
| 0, 1, 2 | van moving 0.14 / 0.15 / 0.15 m/s (> 0.1): the parked van is **frozen on the handbrake** and its **stored** linear velocity is a stale 0.148 m/s; the restore zeroes it, so a resume would lose physics state |
| 3, 4, 5 | engine on (no van engine adapter); hearing activity < 2 wall s old (engine sounds); and the same stale 0.15 m/s |

- So C1 cannot be built on this walk: a take broken at any of its steps can only be refused, never resumed SAME.
  The right outcome for this walk is "refused -> fresh take", which R3b (rec25) and the gate controls already show.
- The 0.148 m/s was invisible until 2026-11-14: `nums()` read the "3" of `Vector3(` / `Transform3D(` as the first number,
  so every velocity refusal and every layer-3 pose bound was silently skipped (fixed in `004d83c`, with controls that
  fail on the old reader).
- The clean case of every refusal control is point 1 with the stored velocities zeroed (`quiet()` in `t4_controls.py`):
  admitted. A real eligible point needs a boundary where the van is not frozen with a stored velocity and the engine
  is off; this probe walk has none. **UNQUALIFIED:** a live SAME resume (D3's two recorded resume receipts) on a real
  point; nothing in the T4 allowance buys a new walk for it.

## Live gate session G (2026-11-14 13:14-13:16, 1.88 min, lane a, play profile)

`tools/method/t4_live_gate.sh` -> `appdata/t34/gate_session.log`. One game; a fresh gateprobe (the producer), then four
resumes of its points, each a walk cut after the resumed step (same identity). GATE_PROBE / GATE_L2_CONTINUE /
GATE_PERTURB are test-only flags (they restore or continue past a refusal to show the next layer; a real resume never
does). Timed under GTA (CPU ~96 %): the verdicts below are not timings and stand; its minutes count.

| # | Resume | Expected | Actual |
|---|---|---|---|
| 1 | fresh gateprobe | DONE, points 0-5 | DONE in 26 s |
| 2 | point 1, GATE_PROBE (layer 2 live, before any await) | refusal named; layer 1+2 DIFFERENT; stop before input | refused: van 0.15 m/s frozen (stale stored); layer 1+2 DIFFERENT (crate / battery box stored velocities zeroed by the restore, `_safe_t` 0.483 -> 0.4); walk stopped before input; receipt REFUSED |
| 3 | point 4 (engine on), GATE_PROBE | the lost engine named | refused: engine on + engine sounds < 2 s + the stale velocity; layer 1+2 DIFFERENT (also `ghat._check_t` in the 17th digit); receipt REFUSED |
| 4 | point 1, GATE_L2_CONTINUE, clean (layer 3 at +3 game s) | what layer 3 names on an unperturbed resume | DIFFERENT: `van.nav_aside` fresh true / resume false; p1 / p2 0.055 m apart (bound 0.05); van velocity 0.064 m/s apart (0.05); van temp 1.6 C apart (0.5) |
| 5 | point 1, GATE_L2_CONTINUE + GATE_PERTURB van:0.2 | layer 3 names the 0.2 m move | DIFFERENT: van moved 0.152 m (bound 0.05), p1 / p2 0.149 m, velocity 0.075, temp 1.63 C; receipt REFUSED |

- Every layer refused where it should; layer 3 caught the perturbation that layers 1+2 (taken before it) could not.
- Even the clean resume (4) is DIFFERENT at layer 3: on this walk a resume is never SAME, consistent with the
  boundary refusals above. Ended with a verified exit (lane a gone).
- **G4 + G5 are a FAILED live control pair.** The planted +0.2 m (G5) is DIFFERENT, but so is the clean resume (G4),
  so this pair proves nothing about layer 3 telling a clean resume from a planted one on a live walk. Part of G4's
  difference is test-side: the resume waits 1 game s after the restore before its step, the fresh reference does not
  (1.6 C = 1.0 s of engine-off cooling), and its nav tap result is confounded. The strictness classes are a finding for
  after the research (R7 a); not fixed here.

## Re-measure (PC idle), 2026-11-14 14:01-14:05

The R1 / R2 timings (13:22-13:34) were taken with GTA 5 at ~96 % CPU: **not usable**. Re-measured with no GTA, no other
Godot. CPU = `(Get-CimInstance Win32_Processor).LoadPercentage` every ~2.6 s while the run lived
(`tools/method/cpu_sampler.ps1` -> `appdata/t34/R1b_cpu.tsv`, `R4_cpu.tsv`). "Overall" = Godot's own "recorded in"
line (whole game life, boot included); "in the walk" = movie frames of the walk / 25 over the wall time between its
first and last point files.

| Take (gateprobe, rec25 1600x900, 6 steps, 25.0 game s) | Overall | In the walk | Game life | CPU while it ran (avg, min-max) |
|---|---:|---:|---:|---|
| R1 alone, **under GTA** (13:22) | 39 % | 57 % | 80 s | GTA ~96 % (not sampled) |
| R2 beside lane b, **under GTA** (13:25) | 34 % | 47 % | 90 s | GTA ~96 % (not sampled) |
| **R1b alone, idle** (14:01) | **52 %** | **69 %** | 59 s | 38 % (13-91; the 82-91 % at 14:01:44-50 was my offline control run, overlapping the walk's first step) |
| **R4 beside lane b, idle** (14:04) | **51 %** | **70 %** | 59 s | 52 % (37-82) with both games alive |

- Recording speed is the same alone and beside a plain game on an idle PC (overall 52 vs 51 %, in the walk 69 vs 70 %);
  one take each, so read it as "no measurable slowdown".
- Fix round (F11): "in the walk" = 25.0 game s (point 0 at step 1 -> point 5 at step 6, drawn frames / 25) over the
  wall time between `0.json` and `5.json`. R1 = 25.0 / 43.82 s = **57 %**, R1b = 24.96 / 36.13 s = **69 %**, R2 = 47 %,
  R4 = 24.96 / 35.60 s = 70 %. The first version of this table had R1 51 % and R1b 62 %: 25 game s divided by a longer
  wall span (`walk.json` -> `5.t3.json`, which holds 28 game s). Those two cells are corrected above.
- Lane b (plain game, 60 Hz physics) beside the recording: **59.7 physics frames/s** (heartbeat, both alive), 60.0
  after lane a stopped (CPU 59 % avg, ffmpeg's encode of lane a's take at 93-100 % included).
- Two-lane throughput (R4): lifetimes 3.0 min summed in 2.0 min union = 1.5x; lane a's take cost the same 59 s as alone.
- The GTA numbers overstated the recording cost by about a third (life 80-90 s -> 59 s; overall 34-39 % -> 51-52 %).
- **UNQUALIFIED:** one take per condition (no spread); a long recorded walk (the real ghat) was not timed.

## Files and interfaces (T4 v2, `709028b..f208e6e`, plus the fix round)

| File | What it is / its interface |
|---|---|
| `FindingNaresh/scripts/dev/GateObs.gd` (new) | the independent observation of a point (layer 1 / 2 / 3 input): script fields of Ghat, the Problem and its children, Camper / VanAttack, both players, carryables, van physics (`@xf`, `@lv`, `@av`, `@sleeping`, `@freeze`), references, materials / audio / timers, selected statics (Hearing). Writes `<k>.obs.json` |
| `FindingNaresh/scripts/dev/LiveControl.gd` | per-step immutable points (`points/<run>/<k>.json` + `.obs.json`), `last_fail`, the resume path: observe synchronously after the restore (before any await), wait for the client's layer 1+2 verdict, the +3 game s layer-3 sample (`<k>.t3.json`), the `marker` command (one magenta drawn frame), `spawn` helpers counted |
| `FindingNaresh/scripts/dev/PlayTest.gd` | first-failure cancellation: `walk_gen`, the input gate (`_gate_send`), `release_everything`, `input_trace`; `cancel_probe_bot` (control helper). Fix round: `focus_log` + `tap_bench` (F5 bench), `_capture_row` (F7) |
| `tools/live.py` | the walk client: `--gate-check` (identity + boundary refusal before any launch), layer 1+2 / layer 3 judging through `walkgate.py`, gate receipts (`<k>.gate.json`), test-only `GATE_PROBE` / `GATE_L2_CONTINUE` / `GATE_PERTURB` / `GATE_NOABORT` / `WALK_FAIL_AT` (refused in acceptance runs since F9) |
| `tools/method/walkgate.py` (new) | `identity_check`, `admit`, `refusal`, `layer1`, `layer2`, `layer3`, `next_step`, `judge_resume`, `boundary` (D3 A: `RESUMES` = 2) |
| `tools/method/gate_inventory.json` (new) | layer 1's field classes (saved / rebuilt / refused / volatile) and layer 3's declared bounds, written before the trials |
| `tools/method/join_check.py` (new) | `framemap`, `part`, `verify`, `join`, `sound` (decoded known-sound check) |
| `tools/record_walk.sh`, `tools/play_walk.sh` | rec25 profile fixed; gate check before launch; parts kept whole; `GATE_ONLY` (D3 second receipt); F9: `record_walk.sh ghat` refuses test-only flags |
| `tools/method/godot_guard.py`, `stop_lane.sh`, `live_session.sh`, `lane_sentinel.sh`, `cpu_sampler.ps1` (new) | lanes: at most 2 games, targeted verified stop, one live game for several commands, the T3 sentinel + recording contention, the CPU load sampler |
| `tools/live/make_gateprobe.py` + 4 walks (new) | the qualification walks (gateprobe, late, cancel, clean). Fix round: `make_tapbench.py` / `tapbench.json` (F5) |
| `tools/method/t4_controls.py`, `t4_join_controls.py`, `t4_live_gate.sh` (new) | offline controls (85, list below), the join control take, live gate session G |

## Deviations (what I changed from the spec, and why)

- **D1 resume path unusable on this walk.** No point of the probe walk passes the boundary refusal (stale stored van
  velocity on a frozen van; engine on; recent sounds), and G4 (clean resume) is DIFFERENT at layer 3. So no SAME
  resume and no qualified joined take exist. R7 makes the replay fresh takes only; REPLAY_USAGE says so (F3).
- **D2 probe walk input: pad A -> the N key.** Step 2 used P1's pad A; it failed 2 / 2 (A2 and A3, A3 in a fresh
  game). With the keyboard as P1's device the game runs the solo view and the pad press has no seated player behind
  it. Changed the probe walk to the N key (`make_gateprobe.py`), the input the real ghat walk uses. My first
  explanation ("the 4th walk of the process") was wrong.
- **D3 identity split** into `test` (producers: game-side test code, walks) and `tools` (judges): a judge-only edit
  does not invalidate points. GPT notes that `tools/live.py` sends actions; it is in `tools`, so a change to it is
  recorded but not required equal: still open.
- **D4 layer-3 bounds** fixed in `gate_inventory.json` before the trials (v2's wording), not "from two resumes".
- **D5 gate refusal reads the stored velocity** (`@lv`) of a frozen body; the restore's real change (it unfreezes the
  van) is not named. A finding for after the research (R7 a).
- **D6 R3a** launched the game before the gate check (wasted boot); since then the check runs before any launch.
- **D7 `nums()` bug** (read the "3" of `Vector3(`), found by the controls, fixed in `004d83c` with controls that fail on
  the old reader.

## The offline control pairs (`python tools/method/t4_controls.py`: 85 / 85)

83 in the build, + 2 in the fix round (F2: the admit pair on the quiet point). Each planted case is refused (REFUSED /
DIFFERENT / NOT SAME) and each clean case passes (ADMIT / SAME); the script exits 1 on any disagreement.

| # | Group | Case | Want | Got |
|---|---|---|---|---|
| 1 | ident | ident REAL point 1 (identity fine, frozen van's stored velocity) | REFUSED | REFUSED |
| 2 | ident | ident clean: same game/test/bin/schema/profile/walk | ADMIT | ADMIT |
| 3 | ident | ident clean admitted -> evaluation only, not SAME | NOT SAME | NOT SAME |
| 4 | ident | ident game changed | REFUSED | REFUSED |
| 5 | ident | ident test changed | REFUSED | REFUSED |
| 6 | ident | ident bin changed | REFUSED | REFUSED |
| 7 | ident | ident schema changed | REFUSED | REFUSED |
| 8 | ident | ident profile changed | REFUSED | REFUSED |
| 9 | ident | ident producer step (before the point) changed | REFUSED | REFUSED |
| 10 | ident | ident resumed step changed (its fresh reference stale) | REFUSED | REFUSED |
| 11 | ident | ident admit clean: quiet point 1, nothing changed | ADMIT | ADMIT |
| 12 | ident | ident admit: quiet point 1, game changed | REFUSED | REFUSED |
| 13 | ident | ident a LATER step changed (point still compatible) | ADMIT | ADMIT |
| 14 | ident | ident wrong point (index 2 for step index 1) | REFUSED | REFUSED |
| 15 | ident | ident point ID that does not exist | REFUSED | REFUSED |
| 16 | ident | ident no point ID | REFUSED | REFUSED |
| 17 | ident | ident the point's observation missing | REFUSED | REFUSED |
| 18 | inv | inv clean point 1: every field classified, required observed | ADMIT | ADMIT |
| 19 | inv | inv van.engine_on observation removed | REFUSED | REFUSED |
| 20 | inv | inv an unclassified field (mystery.x) | REFUSED | REFUSED |
| 21 | inv | inv Problem out, its children not observed | REFUSED | REFUSED |
| 22 | inv | inv Problem out, children observed (layer 1 alone) | ADMIT | ADMIT |
| 23 | refuse | refuse REAL point 1: frozen van, stale stored 0.148 m/s | REFUSED | REFUSED |
| 24 | refuse | refuse clean: point 1 with zero stored velocity | ADMIT | ADMIT |
| 25 | refuse | refuse engine-on point 4 (real) | REFUSED | REFUSED |
| 26 | refuse | refuse van at 0.12 m/s | REFUSED | REFUSED |
| 27 | refuse | refuse van at 0.09 m/s passes the prefilter | ADMIT | ADMIT |
| 28 | refuse | ... but layer 2 still names the lost velocity | DIFFERENT | DIFFERENT |
| 29 | refuse | refuse a carryable moving (contacts unsupported) | REFUSED | REFUSED |
| 30 | refuse | refuse Problem out (global RNG + listener serial: D4 A) | REFUSED | REFUSED |
| 31 | refuse | refuse a running tween | REFUSED | REFUSED |
| 32 | hear | hear quiet: empty queue, nothing unconsumed | ADMIT | ADMIT |
| 33 | hear | hear a sound 0.6 wall s old | REFUSED | REFUSED |
| 34 | hear | hear old (60 s) but unconsumed by a listener (id 7 > 5) | REFUSED | REFUSED |
| 35 | hear | hear old (60 s), no listener to consume it | ADMIT | ADMIT |
| 36 | hear | hear stale-origin stamp (from another process' clock) | REFUSED | REFUSED |
| 37 | hear | hear knock debounce 100 ms old (window 150) | REFUSED | REFUSED |
| 38 | hear | hear knock debounce expired (5 s) | ADMIT | ADMIT |
| 39 | hear | hear no wall clock in the observation | REFUSED | REFUSED |
| 40 | work | work one open watch | REFUSED | REFUSED |
| 41 | work | work a need not met | REFUSED | REFUSED |
| 42 | work | work a helper running | REFUSED | REFUSED |
| 43 | work | work CTRL held | REFUSED | REFUSED |
| 44 | work | work empty lists alone do not pass (point 4: engine on) | REFUSED | REFUSED |
| 45 | child | child clean reconstruction (same children / reference) | SAME | SAME |
| 46 | child | child hum not rebuilt (omitted) | DIFFERENT | DIFFERENT |
| 47 | child | child eye emission changed | DIFFERENT | DIFFERENT |
| 48 | child | child director reference not resolved | DIFFERENT | DIFFERENT |
| 49 | child | child body pose moved | DIFFERENT | DIFFERENT |
| 50 | l2 | l2 clean: the point vs its own copy | SAME | SAME |
| 51 | l2 | l2 engine lost (on -> off) | DIFFERENT | DIFFERENT |
| 52 | l2 | l2 residual velocity lost | DIFFERENT | DIFFERENT |
| 53 | l2 | l2 angular velocity lost | DIFFERENT | DIFFERENT |
| 54 | l2 | l2 sleep state lost | DIFFERENT | DIFFERENT |
| 55 | l2 | l2 a clock (ghat.phase_t) | DIFFERENT | DIFFERENT |
| 56 | l2 | l2 the hearing queue | DIFFERENT | DIFFERENT |
| 57 | l2 | l2 documented volatile only (last_honk_ms) -> normalised | SAME | SAME |
| 58 | l3 | l3 clean: fresh vs its own copy | SAME | SAME |
| 59 | l3 | l3 wrong discrete (ghat.phase) | DIFFERENT | DIFFERENT |
| 60 | l3 | l3 van 0.2 m off | DIFFERENT | DIFFERENT |
| 61 | l3 | l3 van 0.03 m off (inside 0.05) | SAME | SAME |
| 62 | l3 | l3 event order swapped | DIFFERENT | DIFFERENT |
| 63 | l3 | l3 delayed input (+150 game ms) | DIFFERENT | DIFFERENT |
| 64 | l3 | l3 an input missing | DIFFERENT | DIFFERENT |
| 65 | l3 | l3 a FAIL before +3 s | DIFFERENT | DIFFERENT |
| 66 | l3 | l3 sample taken early (2.5 s) | DIFFERENT | DIFFERENT |
| 67 | l3 | l3 no fresh reference | DIFFERENT | DIFFERENT |
| 68 | join | join control take, gate waived: every other rule holds | ADMIT | ADMIT |
| 69 | join | join the same take, gate NOT waived (no SAME receipt) | REFUSED | REFUSED |
| 70 | join | join part 2 absent (part 1 ends FAILED) | REFUSED | REFUSED |
| 71 | join | join part 2's video absent | REFUSED | REFUSED |
| 72 | join | join part 2 from another game hash | REFUSED | REFUSED |
| 73 | join | join both parts at the 60-fps play profile | REFUSED | REFUSED |
| 74 | join | join resumed step != part 1's failed step | REFUSED | REFUSED |
| 75 | join | join part 2 resumed from another run's point | REFUSED | REFUSED |
| 76 | join | join cut range invalid (start past the part's end) | REFUSED | REFUSED |
| 77 | join | join a step played twice in the kept ranges | REFUSED | REFUSED |
| 78 | join | join a step missing from the kept ranges | REFUSED | REFUSED |
| 79 | join | join no drawn-frame -> movie-frame proof | REFUSED | REFUSED |
| 80 | join | join part 2's video bytes changed since recorded | REFUSED | REFUSED |
| 81 | join | join the last part did not reach DONE | REFUSED | REFUSED |
| 82 | join | join control take joined (sum of trimmed parts = video length) | 0 | 0 |
| 83 | join | join time = part 1's cut frame / 25 | 13.880 | 13.880 |
| 84 | join | join length = part 1 to its cut + part 2 from its step (within 1 frame) | yes | yes |
| 85 | join | join the real command on the same take (gate enforced) | 1 | 1 |

85 cases, 85 as expected.

## Fix round (2026-11-14, `trial_T34_fix_build_task.md`; commits `c449993`..)

Games this round (cost said before each, watched every ~5 s, CPU beside each timing; one game at a time except F5's bench):

| Run | Expected | Wall (union) | CPU avg (range) | Result |
|---|---:|---:|---|---|
| import check (headless) after the F5 dev edits | 0.2 | ~0.15 | not sampled (PC idle 23 % before) | rc 0 |
| F5 bench: lane a `tapbench` (20 N taps alone, 20 while lane b comes up) + lane b | 1.0 | 1.47 (1.82 summed; lane b lingered ~20 s after the walk: my driver's wait) | 48 % (27-70) one game, 67 % (54-82) two | 40 / 40 flipped, 0 focus changes |
| import check after the F7 dev edit | 0.2 | 0.13 | - | rc 0 |
| F7 live smoke: a live game, 2 `shot` commands, quit | 0.6 | 0.28 | - | 2 capture rows, sha256 = the files |
| **Total** | | **~2.0 of 5** | | |

| Item | Commit | What | Control pair (planted refused / clean passed) |
|---|---|---|---|
| F1 | `c449993` | REPLAY_USAGE step 0 drops `t1fix_controls.py` (its fixtures are T1's archived runs, not in this copy) | step 0 now runs: `t3_controls.py` rc 0 |
| F2 | `12b6c6b` | the 7 identity controls call `identity_check` directly; + an admit pair on the quiet point | with `identity_check` disabled: **8 BAD** (the 7 + the admit one); the old version: 0 BAD (`appdata/t34/fix/F2_disabled.txt`); clean 85 / 85 |
| F3 | `ade39a0` | REPLAY_USAGE: fresh takes only; walk + video = one unbroken fresh take; a failed take kept aside, taken again `--fresh`; no framemap / GATE_ONLY / join promise for ghat | (documentation) |
| F4 | `6280008` | `join_check.py sound` on R1b's mp4 (windows from its step frames: quiet 8.10 s, engine start 11.76 s) | **SOUND: PASS** (21.0 dB over quiet); planted no-audio / muted copies: FAIL / FAIL (`evidence_R1b_sound.txt`) |
| F5 | `db81a62` | the bench (above): dropped taps **not confirmed**, so no tap re-send was built; `lane_sentinel.sh` now judges its worker walks (`sentinel_workers.py`) | R4's real lane b log (2 of 4) REFUSED; the same log with only its ok walks ACCEPTED; no walks REFUSED |

- F5 note: the bench game never lost or gained focus during either phase (its only focus event is the launch's
  `app_out` at 0 ms), and lane b's window came up during the second phase (two games from 14:25:09 to 14:25:28). So a
  second game coming up does not drop N taps here. Lane b's 2 / 4 failed walks in R4 have another cause (they ran
  back to back in one game; the builder's reply names it); R7 b's "no second game beside walks" is for the referee
  to keep or lift.

F6-F10 (marks prelude, pictures, proof matrix, the seal, the manifest) are T3 pieces: see the T3 report's fix round.

**UNQUALIFIED after the fix round (T4):** a live SAME resume and a qualified joined take (none possible on this walk;
the replay is fresh only); the long real ghat take's recording speed (only 25 s clips timed); layer 3 on a live walk
(G4 / G5 failed pair); the picture inventory on a live suite (F7 smoked in one live game only).
