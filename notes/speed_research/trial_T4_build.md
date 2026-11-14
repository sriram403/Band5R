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
| C1 | lane a, **rec25**: `WALK_FAIL_AT=1:3.6 record_walk.sh gateprobe --fresh` (a take broken 3.6 game s into step index 1, after its +3 s sample: part 1 + the producer point) | 0.6 | | | | |
