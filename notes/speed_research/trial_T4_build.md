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
| R4 (T3) | `tools/method/lane_sentinel.sh` again: CR fix, lane b walking the whole time | 2.8 | | | | |
