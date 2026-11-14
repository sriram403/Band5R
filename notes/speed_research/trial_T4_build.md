# T4 v2 builder report (Claude builder for GPT's spec, 2026-11-11)

Task: `MPG\notes\speed_research\trial_T34_v2_build_task.md` (read first; only its list read). Copy `MPG_speed_t34`,
branch `speed-t34`, `speed-t1` merged first (fast-forward to `4a74146`, T1 + fix round kept intact).

## Game runs (cost written before each run; wall game min, my count; the referee's meter decides)

| # | Run | Expected | Wall | Watched | Result | T4 total |
|---|---|---:|---:|---|---|---:|
| 0 | import / compile check (headless, cold cache: this copy had no `.godot/`) | 0.5 | 0.18 | inline | rc 0, no errors | 0.18 |
| A | lane a, play: `gateprobe_cancel` (FAIL) + 5 s of probe_state reads | 1.5 | 0.85 | inline | FAIL as planned; after it no press (73 dropped by the gate, the one later send = the old helper's CTRL release), checking helper gone at once; **but CTRL read held at the failure picture** (release queued, not flushed): fixed (flush), stopped to rerun on the fixed code | 1.03 |
| A2 | lane a, play: `gateprobe_cancel` + reads, `gateprobe_clean`, fresh `gateprobe` (points) | 1.5 | 1.83 | inline + walk.log every 4 s | cancel control PASS (nothing held at the picture; old-style helper's presses all dropped (73); checking helper stopped at once; only later send = a release); clean pair DONE; **gateprobe FAILED at its own step 2** (pad A did not swing the nav in this 4th walk of the process; picture: solo view): stopped | 2.86 |
| A3 | lane a, play: fresh `gateprobe` alone in a new game (the producer) | 0.6 | 1.55 | walk.log every 4 s | FAILED again at step 2 (pad A: solo view, see the deviation); probe walk changed to P1's N key; rerun in the same game: **DONE**, 6 points; point 1 eligible, point 4 refused (engine on, engine sounds < 2 s) | 4.41 |
| R3 | lane a, play: resume point 1 of A3 with the van moved +0.2 m after the immediate observation | 0.5 | 0.42 | inline | **REFUSED before any input** (right outcome, wrong reason: Godot rewrote the walk's ints as floats, so the producer-steps hash differed); the game had been launched before the check: wasted boot. Fixed: numbers compared by value; the gate check now runs before any launch. Then the check refused A3's points for a real reason (I had edited tools/ since): identity split into test (producers) / tools (judges) | 4.83 |
| C1 | (planned by the first builder, **not run**: the offline controls of 2026-11-14 showed no point of this walk can pass the gate, see "Resume 2026-11-14") | | 0 | | | 4.83 |
| G | lane a, play, `tools/method/t4_live_gate.sh`: fresh gateprobe + 4 resumes (layer 2 live x2, layer 3 clean + perturbed) | 1.8 | 1.88 | Monitor (every line) | all on plan, see "Live gate session G" | 6.71 |
| R1 | lane a, **rec25**, alone: `tools/record_walk.sh gateprobe --fresh` (clean clip, engine sound, marker, on-time fixture) | 1.0 | 1.35 | Monitor (every line) | DONE; on-time 9.5/10 PASS at 25 fps; framemap proved (offset 0); sound PASS; **57 % of real time in the walk, 39 % incl. boot** | 8.06 |
| R2 | lane b plain game + lane a rec25 `record_walk.sh gateprobe --fresh` beside it: `tools/method/lane_sentinel.sh` (T3 sentinel + T4 contention) | 2.2 | 2.67 union (a 1.95 + b 2.67 = 4.62 summed) | Monitor (deduped) | all sentinel facts held; the tool printed FAIL on its own CR bug (fixed); beside lane b: **47 %** of real time in the walk (alone 57 %), DONE, framemap proved, sound PASS | 10.73 |
| R3 | lane a, **rec25**, alone: `NO_MAKE=1 record_walk.sh gateprobe_late --fresh` (just-late fixture) | 1.0 | 1.00 | Monitor | **FAIL by name** at 25 fps ("took longer than its limit"), nothing held at the picture, verified exit; then the resume of that take **refused before launch** (exit 5, 0 min) | 11.73 |
| R4-void | `lane_sentinel.sh` 13:32-13:34 (under GTA): cut by the referee's stop at the user's request (lane b killed at ~13:34:50, the script with it): **void**, rerun as R4 below | (2.8) | ~2.5 | Monitor | void (its 34 % recording figure was under GTA) | ~14.2 |
| R1b | 2026-11-14 14:01, PC idle (no GTA): rec25 alone, `tools/record_walk.sh gateprobe --fresh` (re-measure of R1) | 1.4 | 1.0 (life 59 s) | Monitor every 3 s + CPU sampler | DONE, framemap proved (offset 0), on-time PASS; see "Re-measure (PC idle)" | ~15.2 |
| R4 (T3) | 2026-11-14 14:03, PC idle: `tools/method/lane_sentinel.sh` again (CR fix; lane b walking the whole time) | 2.8 | 2.0 union (lane b 2.0 + lane a life 1.0 = 3.0 summed) | Monitor every 3 s + CPU sampler | **SENTINEL PASS**: every check held (T3 report, R4); recording beside lane b: see "Re-measure (PC idle)" | ~17.2 |

Totals are my count from the logs (union of game lifetimes per run); the referee's meter decides.

## Resume 2026-11-14: why no point of the probe walk passes the gate

The first builder planned C1 (a rec25 take broken mid-step, then resumed through the gate). The offline controls
(`tools/method/t4_controls.py`, 83 / 83) run the gate's boundary refusal (`walkgate.refusal`, before any input) on the
real points of the probe walk A3 (`gateprobe_20261111_122158_4980`, points 0-5). Every point is refused:

| Point | Refused because (the gate's own words) |
|---|---|
| 0, 1, 2 | van moving 0.14 / 0.15 / 0.15 m/s (> 0.1): the parked van is **frozen on the handbrake** and its **stored** linear velocity is a stale 0.148 m/s; the restore zeroes it, so a resume would lose physics state |
| 3, 4, 5 | engine on (no van engine adapter); hearing activity < 2 wall s old (engine sounds); and the same stale 0.15 m/s |

- So C1 cannot be built on this walk: a take broken at any of its steps can only be refused, never resumed SAME.
  The right outcome for this walk is "refused -> fresh take", which R3 (rec25) and the gate controls already show.
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

## Re-measure (PC idle), 2026-11-14 14:01-14:05

The R1 / R2 timings (13:22-13:34) were taken with GTA 5 at ~96 % CPU: **not usable**. Re-measured with no GTA, no other
Godot. CPU = `(Get-CimInstance Win32_Processor).LoadPercentage` every ~2.6 s while the run lived
(`tools/method/cpu_sampler.ps1` -> `appdata/t34/R1b_cpu.tsv`, `R4_cpu.tsv`). "Overall" = Godot's own "recorded in"
line (whole game life, boot included); "in the walk" = movie frames of the walk / 25 over the wall time between its
first and last point files.

| Take (gateprobe, rec25 1600x900, 6 steps, 25.0 game s) | Overall | In the walk | Game life | CPU while it ran (avg, min-max) |
|---|---:|---:|---:|---|
| R1 alone, **under GTA** (13:22) | 39 % | 51 % | 80 s | GTA ~96 % (not sampled) |
| R2 beside lane b, **under GTA** (13:25) | 34 % | 47 % | 90 s | GTA ~96 % (not sampled) |
| **R1b alone, idle** (14:01) | **52 %** | **62 %** | 59 s | 38 % (13-91; the 82-91 % at 14:01:44-50 was my offline control run, overlapping the walk's first step) |
| **R4 beside lane b, idle** (14:04) | **51 %** | **70 %** | 59 s | 52 % (37-82) with both games alive |

- Recording speed is the same alone and beside a plain game on an idle PC (overall 52 vs 51 %); the in-walk 62 vs 70 %
  is one take each and R1b's walk overlapped my own CPU load, so read it as "no measurable slowdown", not as faster.
- Lane b (plain game, 60 Hz physics) beside the recording: **59.7 physics frames/s** (heartbeat, both alive), 60.0
  after lane a stopped (CPU 59 % avg, ffmpeg's encode of lane a's take at 93-100 % included).
- Two-lane throughput (R4): lifetimes 3.0 min summed in 2.0 min union = 1.5x; lane a's take cost the same 59 s as alone.
- The GTA numbers overstated the recording cost by about a third (life 80-90 s -> 59 s; overall 34-39 % -> 51-52 %).
- **UNQUALIFIED:** one take per condition (no spread); a long recorded walk (the real ghat) was not timed.
