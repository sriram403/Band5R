# Trial g1: built by the Opus builder for GPT

Branch `g13-trial-g1` from `g12` `29579f7`. Contract: `trial_g1_spec.md` v3 (GPT's).
Built 2026-11-05, 23:24-23:41 (clock from `date`). I added no ideas to the method; every
place I had to depart or choose is listed under "Departures".

## Verdict up front
- **Qualification run 2 at (66, 0): PASS** (rig healthy, checker PASS on all 7
  obligations, no SCRIPT ERROR, exit 0). 67 s of game, ~75 s wall.
- **Negative `idle-departure`: caught**: FAIL no_progress, 10.03 s after B_BEGIN, never
  PASS (exit 1). The spec's two rules meet right at 10 s (see "For the referee").
- **The spec's obstacle sweep gives false BLOCKEDs: 2 of 4 runs that used it as written**
  (q1 and n1) stopped in stretch A at the bend before the ramp, on a roadside hut, with the
  van on the road. This comes from the rule itself, not a typo in the build. I didn't change
  the rule. I added one declared diagnostic switch to measure the rest (d1).
- **Lip speed falls short:** 66 requested, 64.2-64.5 km/h reached, with W held flat out
  through every launch.
- No video (the referee's ruling: stills + trace are enough). Stills are listed below.

## Source (R8)
`git checkout a6a412f -- <the 7 files>` and committed as `d6500b0` "Reuse c1 code from
a6a412f (R8)". `git diff g12 a6a412f --stat -- FindingNaresh tools` lists exactly those 7:
`dev/PlayTest.gd` (+86), `dev/RigBeat.gd` (195) + `.uid`, `dev/RigInject.gd` (96) + `.uid`,
`tools/rig/rig_watch.py` (233), `tools/rig_run.sh` (21). These are c1's code commits
`920110d`, `3b96807`, `a106f90`, `57b8afd`. c1 is unchanged except one config line (below).

## What was built (test code only; the game is untouched)
| File | Lines | What |
|---|---|---|
| `FindingNaresh/scripts/dev/G1Check.gd` | 552 (new) | **The independent checker.** A node, process_mode ALWAYS. Each physics tick: one trace row (35 columns, flushed every 0.5 s real and on every event) and the obligations' state machines: miss, reset, crossing, A stop, departure, aboard, no-progress, discontinuity, input receipts. It has its own road projection. It never reads the driver's target, progress or "done", and never reads the negative switch. Shots from the players' own split-screen view at events. Writes `g1_verdict.txt`. |
| `FindingNaresh/scripts/dev/G1Drive.gd` | 348 (new) | **The fixed small controller.** It acts only through `PlayTest.key()` (physical + logical keycode, `Input.parse_input_event`), and logs each request into `chk.requested`. Steer: target 8 m + 0.4 s ahead (on the ramp centreline when ramp-local z <= RAMP_LEN + 8, otherwise on the road polyline it projects itself), error / 0.35 rad, D or A for round(6·\|s\|) of every 6 ticks. Pedal: W below target-1, S above target+1. Space tap 0.10 s, then a 1 s readback. Hands off when airborne over the gap. Brake on far-bank contact. The hull sweep. |
| `FindingNaresh/scripts/dev/PlayTest.gd` | +154 / -1 | `t_g1` (`PlayTest.gd:12131`): option parsing and checks, declared setup A, manifest, prerequisite readback (a TEST SETUP FAILURE if anything is missing), A_BEGIN, A, A_END, SETUP_B (`solve_quietly`, `repair_all`, story past `wheel`, pose check), B_BEGIN, B, then a wait for the checker's departure result (up to 65 s; never for the driver's done), and the verdict. Also one line: `"g1"` added to c1's `RIG_NEEDS`, so c1's plan check and pause guard cover it. |
| `tools/g1_run.sh` | 76 (new) | The wrapper: rejects bad options before any setup, runs `tools/rig_run.sh g1`, scans `seg_1.log` for SCRIPT ERROR every 1 s and at exit (the matching line + 2), and prints `==== G1 COMBINED: ... ====`. Exit 0 only when the rig is healthy, there is no SCRIPT ERROR, and the checker says PASS (c1's own zero exit isn't used as the verdict). |

**Support allowlist** (by instance ID, from built geometry, written in the manifest):
`Terrain` (the world's one height-map body), `BridgeDeck`, `RampJump/TrailerRamp/RampBody`.
**Sweep excludes** (18 RIDs): the van, its own colliders, both players, the allowlist.

**Source audit after each BEGIN.** `G1Drive.gd`: the only call that acts on the game is
`pt.key()` (line 67). Otherwise it writes `chk.requested`, `chk.ev`, and `chk.fail("blocked")`
(the spec has the sweep fail BLOCKED itself). `G1Check.gd`: reads only, plus its own files and
shots. `t_g1` inside a stretch calls only `drv.run_a/run_b`, `drv.release_all`, `chk.mark`, and
waits. A grep for `global_transform =`, `linear_velocity =`, `debug_`, `set_parking_brake`,
`toggle_engine`, `repair`, `reset(`, `ramp_*`, cameras, seats and `parse_input_event` finds
none in either file.

## How to run (from `MPG_dev`)
```
tools/g1_run.sh                                    # (66, 0)
tools/g1_run.sh --g1-speed=61 --g1-lane=-0.5       # the referee's variations: 61..68, -0.5..0.5
tools/g1_run.sh --g1-negative=idle-departure       # the negative control
NO_CHECK=1 tools/g1_run.sh ...                     # skip the ~10 s compile check
tools/g1_run.sh --g1-diag-sweep=log                # builder's DIAGNOSTIC (not in the spec; never qualifies)
```
Cost: ~75 s wall per run, plus ~10 s of compile without `NO_CHECK` (67 s of game: 20 s
world load, A 33 s, B ~10 s). Live: one `[rig-watch]` line every 5 s. Evidence goes to
`appdata/playtest/runs/`: `g1_events.txt` (phases, PASS/FAIL, launch / landing rows),
`g1_trace.tsv` (every physics tick), `g1_verdict.txt`, `g1_combined.txt`, `g1_shots/*.png`,
`rig_verdict.txt`, `seg_1.log`. Each run overwrites them. My runs are copied to
`appdata/playtest/runs/g1_<run>/` (not in git).

## Qualification (all watched every 3-5 s: log growth, phase, events, errors)
| Run | Command | Combined | Rig | Checker | Notes |
|---|---|---|---|---|---|
| q1 | `g1_run.sh` (66, 0) | NOT PASS | healthy | **FAIL blocked** at 5.3 s of A: `BridgeHut/@StaticBody3D@2661` 25.6 m ahead | **False alarm, from the spec's rule.** Van on the road (0.9-1.2 m off centre, 47 km/h); the road bends right and the near-bank control hut stands off the road at the outside of the bend. The 2 s straight sweep (26 m) runs off the curve into it. Shot: `g1_q1/g1_shots/fail_blocked.png` (the hut ahead, the road curving right, the van in lane). |
| d1 | `--g1-diag-sweep=log` (66, 0) | DIAGNOSTIC: PASS | healthy | PASS on all 7 | The sweep logged no hit this time. Lip 64.4 km/h; landing z -15.99, x -2.04; B 38.1 m, stopped 1.2 m off the road centre. |
| **q2** | `g1_run.sh` (66, 0) | **PASS (exit 0)** | healthy, asked 1 ran 1, 67 s | **PASS on all 7** | Spec-literal; no sweep hit. Numbers below. |
| n1 | `--g1-negative=idle-departure` | NOT PASS | healthy | **FAIL blocked** in A (hut 26.0 m ahead) | The same false alarm. Never reached B, so it tells nothing about the negative. |
| **n2** | `--g1-negative=idle-departure` | **NOT PASS (exit 1)** | healthy, asked 1 ran 1 | A: PASS on all 5. **no_progress FAIL at 10.03 s after B_BEGIN** (best 0.0 m); departure NOT REACHED | Caught. The actor said "done" at +0.016 s; the checker ignored it and failed on what it measured. |

No SCRIPT ERROR in any of the 5 segment logs. I compiled before the first run and again after
each code change (`run_game.sh --headless --import`: clean).

**q2 in numbers** (`g1_q2/g1_events.txt`):
| Obligation | Measured |
|---|---|
| Miss | slow try: last support z 0.20, x -1.6, 47 km/h. All wheels off over the gap, descent y -1.45 at z -11.2 (10.6 s after A_BEGIN). `misses` 0 -> 1, `failing` seen |
| Reset | back 0.20 m from `van_start` 2.7 s after onset; 5 s untouched: handbrake on throughout, drift 0.121 m (limit 0.30) |
| Crossing | launch 64.5 km/h (total), x -1.30 at the lip; first supported far-bank contact z -19.92, x -1.12, upright; 1.8 m further on; `jumped` agreed |
| A stop | 2 s still on the handbrake, on far-bank support, z -22.95, x -0.96 |
| SETUP_B | pose kept (moved 0.000 m); wheel on, both aboard, engine on, brake on, debug zero |
| Departure | 30 m at +5.1 s, 0.5 m off the road; braked; stopped 0.3 m off the road, 38.3 m of progress |
| Inputs / discontinuity / no-progress | no failure seen |

**Achieved vs requested:** retry target 66 -> lip 64.4 (d1), 64.5 (q2), 64.2 (n2) km/h, with
W requested and raw-pressed (throttle 1.00) at every row up to the launch. Landing spread
across the 3 crossings: z -14.9 to -19.9, x -2.04 to +2.17; A's stop pose varied
(basis_z.x -0.94 to -1.00), so B started from different places, as the spec wants.

## How c1's T1-T3 / N1-N4 still apply (via c1, R1)
`g1` is in `RIG_NEEDS` and runs under `rig_run.sh`, so c1's watcher covers it unchanged:
heartbeat 20 s (N1), physics stopped 10 s, paused + world clock stopped 5 s (N2, T1 "pad lost
-> TEST"), P1/P2 missing ~1 s (N3), asked vs ran by ID (N4, T3), and the declared-needs check
before step 1 (T2: the same 8 needs as `ramp`). I didn't rerun those injections on `g1`. The
checker adds its own health lines (paused, a player missing, a raw key that never arrived ->
TEST). Inherited, as R8 says: one STOP failed to kill the game; the 5 s pause rule; "pad lost"
is always TEST; the 20 s stale limit is unmeasured. None of them bit in my 5 runs.

## Departures from the spec (all of them)
1. **Diagnostic switch `--g1-diag-sweep=log`** (driver + wrapper only). The sweep records
   hits as events and doesn't act on them; the combined line says DIAGNOSTIC and the exit is
   never 0. Why: the spec's sweep false-alarmed in q1, and I needed to know whether the rest
   works. Not used in q2 or n2.
2. **Reset wait 5.5 s, not 5.** After the game's reset (failing false, speed < 0.2) the driver
   waits 5.5 s before its Space tap, so the checker's 5 s window (which opens on its own
   detection) can't overlap the tap.
3. **Support while frozen.** The game freezes a van parked on its handbrake
   (`Camper._update_parked`), and a frozen van's wheels stop reporting contact. While
   `van.freeze` is true, the checker probes straight down from each wheel (a read-only ray,
   excluding the van) and applies the same allowlist and z < -gap rule. Each row is marked
   `probe` or `wheel`. Without this, the A stop's "support for 2 s" could never pass.
4. **When B "brakes".** The checker takes braking to start at the first tick after 30 m
   where P1's device reads brake > 0.5 (a raw device read, not the driver's state) or speed
   < 0.5 m/s. The 3 s window before it must be all > 0.5 m/s and <= 4 m off the road.
5. **The driver projects in A only when it steers**, every 6 ticks, and only outside the ramp
   zone. In B it projects every tick. The spec says every tick. Its steering decisions are
   every 6 ticks anyway.
6. **Lane in B.** The lane offset applies to the setup pose and to the steering target in both
   A and B (the spec doesn't say which for B; this is the literal "normal control" reading).
7. **The sweep excludes both players** (seated riders) as part of the van, and the whole
   `Terrain` body, because the world's ground is one height-map body. So a terrain bump never
   blocks; only placed objects do.
8. **Short pulses aren't labelled.** A steering tap shorter than 2 physics + 2 process frames
   isn't checked for receipt, as the spec allows, but the trace doesn't label it UNOBSERVED.
   The trace has requested / raw-physical / raw-logical bits per tick, so it can be derived.
9. **Contact bodies in the trace by name**, not by ID. The allowlist IDs are in the manifest
   and the checker compares by ID.
10. **Story in SETUP_B:** `st.index += 1` when the story sits at `wheel`. That is "set needed
    story state", declared and logged.
11. **No video** (the referee's ruling). Stills per run: `A_slow_launch`, `A_miss`,
    `A_launch`, `A_landing`, `A_stop`, `B_stop`, and `fail_<obligation>` on a failure.
12. **c1 config:** `"g1"` added to `RIG_NEEDS` (a data line; c1's code is unchanged).

## For the referee to decide
1. **The sweep rule.** As written, it false-alarms on this route about half the time (2 of 4
   runs that used it). The bend before the ramp plus the near-bank hut. Whether a run hits it
   depends on a few degrees of heading at t ≈ 5 s (q1 / n1 velocity (11.2, -7.2) / (11.1, -6.9)
   hit; d1 / q2 (11.9, -5.3) / (11.5, -6.4) didn't). Your ten S1 runs will see about the same.
   Options: (A) score it as specified: S1 fails on the test's own false alarm; (B) GPT changes
   the rule (e.g. sweep along the road ahead, or shorter), which needs a new spec version. I
   didn't pick.
2. **"Within 10 s" vs "after 10 s".** The negative failed at 10.03 s. The obligation table
   says fail "after 10 real seconds without >= 1 m"; the qualification line says "within 10 s".
   Both can't hold at once.
3. **The speed shortfall.** Flat out, this controller reaches 64.2-64.5 at the lip (the brief
   says the AutoDriver got 66-68). So every `--g1-speed` from 65 to 68 is the same run (W held
   to the lip). Cause not measured. It may be the steering pulses' scrub on the run-up or the
   line through the bend. The spec says report it; never change the physics.

## Open holes
- 10 variations and the public controls not run (the referee's job, R4).
- The sweep false alarm (above). Under the spec, a BLOCKED is "cause unresolved", which is
  honest, but it still stops the run.
- **NOT PROVEN** (from the spec, unchanged): the hut route, crate, leg-up, door, wheel by
  players; HUD / visuals / hub / wreck; the river and swimming; P2 left behind; the boiling
  engine; joining A to B without setup; any other puzzle.
- The speed band, 1 m progress, 0.30 m drift and 0.2 s support are trial rules, not proved
  limits. The 60 s deadlines were never near.
- Short steering taps aren't receipt-checked (spec-allowed).
- c1's own known limits, as above.

## Minutes
| Part | Clock | Minutes |
|---|---|---|
| Reading and branch | 23:24-23:26 | ~2 |
| Build to the first compile (checker, driver, scenario, wrapper) | 23:26-23:31 | ~5 |
| Qualification: 5 runs, each watched, plus the diagnostic switch | 23:31-23:38 | ~7 |
| Evidence review (shots, traces), audit, report, commits | 23:38-23:41 | ~3 |
| **Total** | **23:24-23:41** | **~17 of 60** |

Zero online-model tokens per run (no model in the loop). Builder model time is in the minutes
above.

---

## v4 (spec v4, applied 2026-11-05 23:46-23:59 by a second Opus builder for GPT)

Spec v4 committed as `b68f763` "g1 spec v4 (GPT)". The v3 false alarms (q1, n1) and results
above stay as they were; the v4 results below are new measurements.

### Verdict up front
- **Blocker negative: caught.** BLOCKED naming `G1Blocker` id 2926433088434 (the ID in the
  manifest), never PASS (exit 1). Run v4b1.
- **Clean `(66,0)`: NOT qualified.** 2 runs, both FAIL crossing: the retry missed (lip 59.0 /
  58.5 km/h, x -1.98 / -2.17, left wheels off the 5.6 m ramp). No v4 change touches the
  controller; see "The retry line" below.
- **Idle-departure negative: NOT qualified.** Run v4n1 never reached B: **A_stop fails by
  construction under v4's freeze provenance rule** (below). So the exact no-progress timestamps
  were never measured in B.
- **The spec question (referee / GPT decide):** v4 requires van, wheel and support transforms to
  stay exactly unchanged from the source tick while a contact is retained across the freeze.
  Measured: they don't. The van moves < 1 cm between the last unfrozen tick and the first frozen
  one; each wheel's transform then shifts 1.5-3.1 mm at freeze +1 and +6 ticks and holds. All 4
  wheels invalidate at every freeze -> no 2 s supported stop -> A can't pass -> B is never
  reached. The spec says "report incomplete; do not invent a tolerance", so I stopped there.
- **Terrain-included sweep: no false hit.** 0 hits in 4,112 swept ticks over 4 runs (Terrain,
  decks and every world solid included; only the van's own bodies and the 2 seated riders
  excluded). The one hit was the blocker.

### What changed (test code only; the game is untouched)
| Item | v4 rule | Built | Where |
|---|---|---|---|
| Sweep (driver 7) | actual chassis shape at its measured transform, motion `linear_velocity * delta`, plus current overlaps; exclude only the van and its riders | `_sweep()` uses the van's own `Hull` CollisionShape3D (its shape, `global_transform`, `margin`) and the van's `collision_mask`; motion = full 3D velocity x `get_physics_process_delta_time()`. First `intersect_shape` at the current pose (initial overlap), then `cast_motion` + `get_rest_info` (collider path, ID, point, normal, safe / unsafe fraction). Every swept tick writes a row to `g1_sweep.tsv` (step dt, shape size, margin, mask, transform origin / basis z, motion, exclusion count, result). The ramp-entry-to-landing exemption is unchanged (same call sites). | `G1Drive.gd` `_sweep`; exclusions in `PlayTest.gd` `t_g1` (the support allowlist is no longer excluded; the manifest lists the 15 RIDs) |
| Departure 7 rejected | Terrain / decks included | as above | |
| No progress | first tick strictly after 10.000 s; log threshold and detection | `Time.get_ticks_usec()`; exactly 1 m counts (`>=`). An event logs the initial sample; a failure logs sample / threshold / detection usec, the physics frame and the delay after the threshold. B_BEGIN logs its own usec. | `G1Check.gd` `_progress`, `mark` |
| Departure 3 rejected | retain the last real contact across the freeze only from the tick immediately before; transforms unchanged; log it | Per wheel, the last real contact `[frame, body id, point, normal, wheel xf, van xf, body xf]`. On the first frozen tick it is held only if its frame = this frame - 1; each frozen tick compares van / wheel / body transforms exactly (`!=`). Changed -> INVALIDATED (an event). While frozen the wheel API's own contact is not used as support (logged as `api_contact`). Every frozen tick x wheel -> `g1_freeze.tsv`. The ray probe is gone. | `G1Check.gd` `_wheels` |
| Departure 4 rejected | braking = device S brake > 0.5 or an observed parking-brake engagement | low speed removed; the anchor is logged with the brake value, the engagement and the speed. The 3 s window rule is unchanged. | `G1Check.gd` `_stretch_b` |
| Departure 8 rejected | per-pulse frames, counts, UNOBSERVED | each requested key pulse -> `g1_pulses.tsv`: key, start / end physics and process frame, physics / process counts, phase, `CHECKED (receipt window seen)` or `UNOBSERVED`. | `G1Check.gd` `_physics_process` |
| Departure 9 rejected | numeric body ID with each contact | the trace `wheels` column is now `in:name#id@point/nnormal/source` | `G1Check.gd` |
| Blocker negative | a fixed solid on B's forward path, placed in SETUP_B only | `--g1-negative=blocker`: in SETUP_B after the readback, a StaticBody3D `G1Blocker` (box 5 x 3 x 0.6 m, layer 1, with a visible mesh) 15 m along the road from the van's projection, across the road; its ID / RID / size / pose go in the events. The checker doesn't read the switch; the driver drives normally. The wrapper accepts the value. | `PlayTest.gd` `t_g1`, `tools/g1_run.sh` |

Diff v3 head -> v4 code: 4 files, about +210 / -55 lines (`G1Check.gd` most). Compiled clean
(`run_game.sh --headless --import`) after each edit. Source audit: inside a stretch the driver
still acts only through `pt.key()`; the sweep and the checker only query (`intersect_shape`,
`cast_motion`, `get_rest_info`, reads). The blocker is written in SETUP_B only.

### Qualification (each watched every ~4-5 s: rig line, phase, events, sweep-hit count)
| Run | Command | Combined | Result | Evidence |
|---|---|---|---|---|
| v4q1 | `g1_run.sh` (66,0) | NOT PASS, exit 1 | miss PASS, reset PASS; **the retry missed**: lip 59.0 km/h, x -1.98, one wheel on BridgeDeck beside the ramp at phys 1688. Sweep 992 ticks, 0 hits. | `g1_v4q1/` (shot `A_launch.png`: 57 km/h on the ramp) |
| v4q2 | same | NOT PASS, exit 1 | the same: retry missed, lip 58.5 km/h, x -2.17. Sweep 993 ticks, 0 hits. | `g1_v4q2/` |
| **v4b1** | `--g1-negative=blocker` | **NOT PASS, exit 1** (rig healthy) | A: miss, reset, crossing (lip 64.6 km/h, landed z -15.95), A_stop PASS (*). SETUP_B: blocker id 2926433088434 at (492.52, -1.89, -251.85). B: **BLOCKED** 2.4 s after B_BEGIN (phys 2196), "initial overlap with /root/Main/World/G1Blocker (id 2926433088434)", van centre 3.31 m from the blocker at 6.6 m/s (motion 0.11 m per tick); the ticks before were clear. Never PASS. | `g1_v4b1/` (`fail_blocked.png`, `g1_sweep.tsv` last rows) |
| v4n1 | `--g1-negative=idle-departure` (strict freeze rule) | NOT PASS, exit 1 | A: crossing PASS (landed z -16.03); **all 4 wheels INVALIDATED at both freezes** (phys 961, 1946); "INCOMPLETE: A did not reach its stop"; B not reached. | `g1_v4n1/g1_freeze.tsv`, `g1_events.txt` |

(*) v4b1 ran my first v4 freeze code, which still took the wheel API's own contact during the
freeze as support (the held-record path never ran, because the API kept reporting contact). I
then made it strict (v4n1). So **v4b1's A_stop PASS is not v4-qualified**; its B blocker result
doesn't depend on it (B was reached, the blocker was hit and named).

No SCRIPT ERROR in any of the 4 segment logs. Rig healthy in all 4 (asked 1, ran 1).
Evidence: `appdata/playtest/runs/g1_v4q1/`, `g1_v4q2/`, `g1_v4b1/`, `g1_v4n1/` (not in git):
trace, events, verdict, sweep, freeze, pulses, shots, seg_1.log, rig verdict.

### Freeze provenance, measured (v4n1, `g1_freeze.tsv` + trace)
- The wheel API reports `is_in_contact() == true` on **all 1464 frozen wheel-ticks**, in both
  freezes. (v3's departure 3 and the game's comment said frozen wheels stop reporting contact;
  not so in these runs.)
- Van transform: constant over the whole frozen hold (1 distinct value in 260 and 106 ticks),
  but **different from the tick before the freeze** (position equal to 1 cm; velocity
  ~0.1 m/s -> ~2 mm per tick).
- Wheel transforms: change 1.5-3.1 mm (largest element) at freeze +1 and freeze +6 ticks, then
  hold.
- Support bodies (Terrain / BridgeDeck): unchanged.
So the exact-unchanged rule invalidates every wheel at every freeze. Measured, not assumed.

### Pulses (`g1_pulses.tsv`)
v4b1: D 189 checked / 30 UNOBSERVED; W 49 checked; S 1 checked; Space 3 checked / 1 UNOBSERVED.
v4n1: D 186 / 10; W 45; S 1; Space 2 / 1. No UNOBSERVED pulse counts as a receipt pass. The
UNOBSERVED Space is a 0.10 s tap that got fewer than 2 process frames.

### The retry line (not a v4 change)
Lip x / speed on every retry so far (v3 + v4): -1.73 / 64.4, -1.30 / 64.5, +0.90 / 64.2,
-1.80 / 64.6, -1.79 / 64.6 crossed; -1.98 / 59.0, -2.17 / 58.5 missed (left wheels off the 5.6 m ramp). The
throttle duty on the run-up is the same (W requested on 120 vs 121 of 156 ticks, v4q1 vs q2).
Frame pacing differs (ticks with no process frame: 103 in q2, 63 / 51 in v4q1 / v4q2), and keys
reach the game on process frames. The spec fixes the controller; I didn't touch it. Cause not
proven.

### Departures from v4
1. **The blocker's geometry is my choice:** 5 x 3 x 0.6 m, 15 m along the road from B's start,
   layer 1, with a mesh. The spec only says "a fixed solid blocker in B's forward chassis path".
2. **v4b1 used the non-strict freeze reading** (above); disclosed, not counted for A.
3. **Clean and idle-departure not qualified**: I stopped at the spec question instead of a
   third round (a v4 rule that can't hold is a spec question).
Nothing else departs. The accepted departures 1, 2, 5, 6, 10, 11, 12 are unchanged.

### For the referee / GPT to decide
1. **Freeze provenance.** As written, A_stop can never pass on this game (mm-level settling at
   and after the freeze). (A) GPT states which transforms must be unchanged and from which tick
   (comparing from the first frozen tick still fails on the wheels' +1 / +6 tick shifts), or
   sets a measured tolerance; (B) score g1 incomplete for A_stop. I didn't pick.
2. **The retry line:** 2 of 7 measured retries missed with the fixed controller; the referee's ten S1 runs will likely see misses that come
   from the controller's line, not the game.
3. Unmeasured under v4, because B was never reached with v4-valid A: the idle negative's
   no-progress timestamps, the braking anchor, and the departure obligation.

### Open holes
- No clean PASS under v4; no v4 no-progress timestamp measurement.
- The blocker was caught as an initial overlap one tick after a clear cast (motion 0.11 m per
  tick, the gap within the shapes' margins): detection on the driven path, not a stop before
  contact (the spec says the same).
- Everything in the v3 "Open holes" above still stands.

### Minutes (v4)
| Part | Clock | Minutes |
|---|---|---|
| Reading, spec commit | 23:46-23:47 | ~2 |
| Build v4 (checker, driver sweep, blocker, wrapper) + compile | 23:47-23:49 | ~3 |
| Runs v4q1, v4q2, v4b1 (watched) + analysis | 23:49-23:55 | ~6 |
| Strict freeze edit, v4n1, freeze measurement | 23:55-23:57 | ~2 |
| Report, rough notes, commit | 23:57-23:59 | ~2 |
| **Total** | **23:46-23:59** | **~13** |

Zero online-model tokens per run.

## The referee's verdict on g1 (2026-11-05, 23:59)

**g1 failed qualification inside its cap** (23:24-00:24; two builds, 17 + 13 min, one spec
revision by GPT in between). No scoring runs were made: S1 needs 10 / 10 clean passes, and the
clean `(66,0)` run already failed in qualification (v4: 0 / 2; over v3 + v4, 1 clean full pass
in 4 clean attempts), so 30 minutes of scoring would only have confirmed it. The user chose to
stop the session after g1 (option B).

| Check | What g1 showed in qualification |
|---|---|
| S1 no false alarms | **Fails.** v3: the 26 m straight look-ahead hit a hut off the bend (2 of 4 runs). v4: both clean retries missed, the van at the lip **2.0 / 2.2 m left of centre at 59 / 58.5 km/h**, left wheels off the 5.6 m ramp. That is the test's own driver line (measured position), not shown to be the game. Also: the speed ceiling 64.2-64.5 km/h, short of S1's 61-68 spread. |
| S2 finds real bugs | Not scored (no scoring runs). Coverage would have been P1 at most (R5). |
| S3 blames the right thing | c1's layer reused (R8); not re-scored on g1. |
| S4 can't pass by doing nothing | **Partly shown:** v3's idle-departure negative failed "no progress" at 10.03 s, never PASS; v4's blocker negative failed BLOCKED and named the blocker by body ID 3.3 m before it. v4's idle negative never reached stretch B. |
| S5 real path | Read from the spec and report: setup declared before each stretch, input only inside them (not independently audited by the referee yet). |
| S6 cost | ~75 s per run; no model in the loop; build 30 min over two rounds plus GPT's revision. |

**Why it failed, as measured:** (1) a rule in its own spec could not hold in this game: v4's
freeze rule wants the wheel transforms unchanged across the parked van's freeze, and they move
1.5-3 mm (measured on all 4 wheels), so the stretch-A stop can never pass; (2) its keyboard-pulse
driver doesn't hold the ramp's centre line reliably.

**What g1 got right, for the next trials:** a per-tick sweep with the terrain included ran
4,112 ticks with no false alarm and caught a placed blocker by ID; an independent checker
judging signed road progress, not "closest ever"; a negative control that ignores the actor's
own "done". And a fact: a frozen van's wheels **do** report contact (1,464 / 1,464 frozen
wheel-ticks), contrary to the game's own comment and v3's departure 3.

**Open for GPT** (its turn after c2's report, per the brief): continue g1 (fix the freeze rule
with a measured tolerance, and the driver's line), change it, or drop it, with a reason.
