# Trial g2: causal comparisons (GPT's spec v1, built by the Opus builder)

Branch `g13-trial-g2` from `g12` `f15b340`. Built and qualified 2026-11-06, 13:12-13:41 by the
clock (`date`). Contract: `trial_g2_spec.md` v1. Frozen run plan: `trial_g2_plan.md` (committed
at 13:22, before B1).

## Verdict up front
- **Qualified (instrument and comparisons work).** All 14 planned launches ran in order, with
  distinct IDs and archived outputs: B1-B3, the three pairs (6 arms), the swimmer pair and the
  3 controls. All 11 gameplay episodes: **INSTRUMENT OK**. No SCRIPT ERROR anywhere. The game's
  462 tracked files had identical hashes before and after.
- **Baseline: 0 / 3 misses** (3 landed: 66.03, 66.54, 66.36 km/h). Across all 9 retries, **1 miss**:
  **A0 (the control arm of pair A), 66.53 km/h**.
- **(a) ~66.5 km/h land or miss: INCONCLUSIVE.** One chain was seen in the one miss (an on-ramp
  steering tap -> roll / yaw rate at launch -> the hull stopped mid-air with no wheel contact). But
  B1 had the same tap and landed, and the body contact that stopped the van isn't measured.
- **(b) the 57.1 km/h retry: not reproduced** (every retry was 66.0-66.8 km/h). No rolling before
  throttle was seen. The historical cause is **NOT PROVEN**.
- **Swimmer: no drift difference.** S0 and S1 drifted the same 0.045 m. The game cleared the
  swimmer at the reset (as its code says). No mechanism to name; P1 not called.
- **Controls: 3 / 3 flagged by the host.** Stale field: TEST before drive. Stuck step: flagged
  5.14 s after the step opened, process gone. Early return: INCOMPLETE (c1 alone said healthy
  and PASS).

## Source and reuse (R8)
- **c1, by file:** `git checkout a6a412f -- <7 files>`, committed as **`230007d` "Reuse c1 code
  from a6a412f (R8)"**. The files: `dev/PlayTest.gd`, `dev/RigBeat.gd` + `.uid`, `dev/RigInject.gd` + `.uid`,
  `tools/rig/rig_watch.py`, `tools/rig_run.sh` (`git diff f15b340 a6a412f --stat -- FindingNaresh tools`
  lists exactly these). These are c1's code commits `920110d`, `3b96807`, `a106f90`, `57b8afd`.
  c1's code is unchanged except one config line: `RIG_NEEDS` lists the 8 `g2_*` scenarios with
  ramp's needs (`RIG_G2`), so c1's needs check and pause guard cover them, as c2 did.
- **c2 (`04c3102`): no file or code copied.** I used only the stretch's recipe from
  `t_c2_more` G1 / G2:
  - `ramp_start`;
  - P2 at `r.global_transform * Vector3(5.0, -10.5, -r.gap_len * 0.5)`;
  - `ramp_try(48.0)`, then `wait(6.0)` hands off.

  I did not use `C2Watch.gd`: its G1 / G2 observations are replaced by the recorder's rows. I did
  not use c2's wrapper exit policy or its rule claims.
- **g1: nothing used.**

## What was built (test code only)
| File | What |
|---|---|
| `FindingNaresh/scripts/dev/G2Rec.gd` (new) | The passive recorder. **pre**: `SceneTree.physics_frame`, connected once at ready (before node callbacks and before the test coroutine's per-tick re-await). **late**: its own `_physics_process` at priority 100000 (Camper, RampJump, PlayTest: 0, logged per run). **proc**: `_process`, with process-frame id, raw keys, device reads and physics ticks since the previous frame. **keyreq**: rows logged at dispatch inside `PlayTest.key()`, before `parse_input_event`. Every row records the physics frame id, process frame id, `Time.get_ticks_usec`, engine delta and pause state. It also records the van (full basis, origin, ramp-local position, world and ramp-local velocity, angular velocity in world and body axes, speed / horizontal / forward, forward elevation `atan2(f.y, \|f.xz\|)`, `basis.y·up`, default Euler, brake, freeze, sleep, engine force, brake, steering, debug inputs, engine, temp, coolant, wheel / tyre state), 4 wheels (full transform, contact bit, point, normal, body path, instance id, rpm, skid; suspension "unavailable"), the ramp (`jumped`, `failing`, `misses`, `_launched`, lip), both players (position, velocity, swimming, seat, whiteout), both devices (identity, throttle, brake, steer, handbrake, move). REQUIRED reads are validated by name and type at preflight and on every tick; a stale field emits `STALE` and marks rows invalid. It buffers rows and flushes them every 0.4 s and at each event. It also writes the derived events, the manifest and the summary (observer and flush duration distribution). |
| `FindingNaresh/scripts/dev/G2Ctl.gd` (new) | The 3 local controls, parsed only from `--g2-control=`. The recorder and the host never read it. |
| `FindingNaresh/scripts/dev/PlayTest.gd` | Hooks: recorder and control setup in `_ready`; `g2.on_key` in `key()`; a 5 s OPEN / CLOSE in `shot()`; `begin` / `end_rec` around watched scenarios. **`t_ramp` and `ramp_try` are byte-identical to g12.** New: `t_g2_a0..c1`, `t_g2_s0/s1`, `g2_pair` (the t_ramp prefix copy), `g2_ramp_try_b`, `g2_ramp_try_c` + `G2Late`, `g2_swim`. |
| `tools/g2_run.sh` (new) | One arm per fresh process: checks `tasklist`, refuses an existing run id, runs c1's `rig_run.sh` with the g2 watcher beside it, then archives everything to `appdata/g2/runs/<id>/`. |
| `tools/g2/g2_watch.py` (new) | The host checker. It polls every 0.5 s. **Stops the game** (taskkill, then checks with tasklist that the process is gone) on: an OPEN step past its published deadline, `PREFLIGHT_FAIL` / `STALE`, or no recorder within 150 s. At the end, a missing required checkpoint, event or result count gives **INCOMPLETE**. SCRIPT ERROR, a missing manifest or a trace gap over 5 s gives **OBSERVATION INVALID**. Writes `g2_verdict.txt`; exit 0 only on INSTRUMENT OK. |
| `tools/g2/prefix_diff.py`, `g2_table.py`, `g2_arms.py`, `g2_flight.py`, `g2_runup.py`, `g2_latency.py` (new) | Read the archived runs only. Prefix diff proof, the event-aligned sheet, the arm table, the flight path, the last metres of the run-up, and key dispatch-to-raw latency. |

**Prefix proof:** `python -I tools/g2/prefix_diff.py` (output in `appdata/g2/prefix_diff.txt`).
- `t_ramp` prefix vs `g2_pair`: 2 lines removed (`await wait(0.3)`, `var go := await ramp_try(80.0)`);
  every added line is marked `G2 OBS` / `G2 FACTOR`, except `await wait(settle)`.
- `ramp_try` vs `_b` / `_c`: only factor lines, plus re-indented original lines.

## Departures from the spec (all of them)
1. **Baseline step deadlines:** `t_ramp` / `ramp_try` were left byte-identical ("do not
   refactor today's baseline"). So B1-B3 have only the 200 s episode deadline and a 5 s deadline
   on every `shot()` (instrumented in the helper). Their drives, waits and reset have no step
   deadline of their own. The pair and swimmer arms have one on every phase.
2. **Launch / result stills not built for the 8 pair and swimmer arms.** I missed it in the build
   and found it after the manifest was frozen and the queue was running, so I didn't add it. For
   those arms, visual evidence of launch / result is **unavailable**. They have the 6 pre-drive
   sight stills (pairs) or none (swimmer); traces carry the evidence. Baseline result stills
   (`ramp_landed`, hut) were reviewed: landed on the road, front-left wheel gone, on the hub
   (`appdata/g2/stills_review.jpg`).
3. **Drive deadline is 46 s** (40 s drive + 6 s reset): `ramp_try` holds both awaits inside one
   call. The pairs' own `reset_wait` has 6 s.
4. **Body contacts: NOT MEASURED.** `contact_monitor` is off on the van, and was not enabled.
   Suspension compression: no API, recorded as "unavailable".
5. **AutoDriver internals not recorded.** `ramp_try`'s driver is a local, kept unexposed so
   `ramp_try` stays identical. Requested keys, raw keys and device reads are recorded instead.
6. **Deadline clock:** the game publishes `Time.get_unix_time_from_system() + secs`; the host
   compares with `time.time()`. Same OS clock, but not a monotonic clock shared across the two
   processes. A clock step would shift it (not seen).
7. **Swimmer setup wait:** a fixed 4.0 s in both arms (c2 used `until(swimming, 4.0)`), to make
   the two arms equal as the spec asks.
8. **Run id:** pair B's intervention is `B1x` (`B1` is the first baseline).
9. **One compile correction used** (type inference in `G2Rec.gd:495`). No change after the first
   measured run.

## Minutes (clock)
| Part | Clock | Minutes |
|---|---|---|
| Read spec, brief, c1 / c2 / g1 reports, game code | 13:12-13:15 | 3 |
| Branch, R8 reuse, hashes; recorder, controls, arms, host, wrapper | 13:15-13:21 | 6 |
| Compile x2 (7 s each), prefix diff, plan frozen, commit `527706c` | 13:21-13:23 | 2 |
| 14 launches, watched (B1, B2 alone; the rest as a queue) | 13:22:45-13:37:25 | 15 |
| Analysis while running and after; stills; report | 13:25-13:41 | ~4 after the last run (the rest overlapped the runs) |
| **Total** | **13:12-13:41** | **~29 of 60** |

Run costs (wall, archived): B1-B3 128-129 s; pair arms 45-50 s; swimmer arms 39 s; K1 16 s,
K2 20 s, K3 33 s. Archive size: 254 MB under `appdata/g2/runs/` (not in git).
**Recorder overhead:** per-row observer p50 0.19-0.23 ms, p99 0.62-0.92 ms, max 13-29 ms. Flush
p50 0.35-0.6 ms, max 1.8 ms. Physics frames missing one phase: 1-2 per run (the begin / end
ticks). Host-seen trace no-growth gap: max 1.0 s.

## The arm table (every launch; retry = the flat-out try at 80)
| run | verdict | slow | retry | lip km/h | last-supported kmh (fwd) | v ramp-local x,y,z m/s | elev deg | w body x,y,z rad/s | x at lip m | last A/D held (dtick, z, on ramp) | reset->release moved 3d / horiz m | proc frames / ticks (2+) | wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 | INSTRUMENT OK | miss 47.2 | landed | 66.03 | 66.18 (66.18) | -0.088, 1.876, -18.288 | 4.38 | -0.298, -0.079, -0.154 | 1.177 | -19, 4.07, yes | 0.294 / 0.040 | 408 / 530 (101) | 128 s |
| B2 | INSTRUMENT OK | miss 46.9 | landed | 66.54 | 66.69 (66.67) | -0.816, 1.708, -18.429 | 2.50 | -0.408, 0.001, 0.001 | 0.900 | -45, 12.2, no | 0.294 / 0.039 | 722 / 527 (2) | 128 s |
| B3 | INSTRUMENT OK | miss 46.9 | landed | 66.36 | 66.51 (66.50) | -1.109, 1.750, -18.359 | 3.00 | -0.407, -0.007, 0.008 | 0.758 | -9, 0.74, yes | 0.294 / 0.039 | 530 / 528 (57) | 129 s |
| A0 | INSTRUMENT OK | miss 47.2 | **miss** | 66.53 | 66.69 (66.66) | -0.214, 1.689, -18.447 | 2.07 | -0.423, -0.032, **-0.178** | 1.019 | **-21, 4.67, yes** | 0.294 / 0.039 | 797 / 561 (9) | 45 s |
| A1 | INSTRUMENT OK | miss 47.2 | landed | 66.78 | 66.67 (66.65) | -0.658, 1.708, -18.430 | 2.32 | -0.441, -0.015, -0.071 | 0.854 | -29, 6.97, yes | 0.288 / 0.045 | 693 / 529 (9) | 50 s |
| B0 | INSTRUMENT OK | miss 47.0 | landed | 66.28 | 66.44 (66.42) | -0.915, 1.735, -18.350 | 2.70 | -0.411, -0.001, 0.032 | 0.863 | -46, 12.38, no | 0.294 / 0.040 | 714 / 529 (11) | 46 s |
| B1x | INSTRUMENT OK | miss 47.1 | landed | 66.33 | 66.49 (66.47) | -0.774, 1.744, -18.370 | 2.88 | -0.412, -0.003, 0.028 | 0.936 | -45, 12.01, no | 0.294 / 0.040 | 740 / 529 (13) | 45 s |
| C0 | INSTRUMENT OK | miss 47.1 | landed | 66.37 | 66.53 (66.51) | -0.851, 1.731, -18.379 | 2.80 | -0.392, -0.005, -0.014 | 0.977 | -45, 12.16, no | 0.294 / 0.040 | 743 / 530 (9) | 46 s |
| C1 | INSTRUMENT OK | miss 46.8 | landed | 66.55 | 66.71 (66.68) | -1.102, 1.643, -18.424 | 2.12 | -0.441, -0.005, -0.000 | 0.757 | -46, 12.46, no | 0.294 / 0.039 | 711 / 528 (12) | 46 s |
| S0 | INSTRUMENT OK | miss 46.9 | (none) | | | | | | | | | | 39 s |
| S1 | INSTRUMENT OK | miss 47.0 | (none) | | | | | | | | | | 39 s |
| K1 | **TEST: observation invalid** (stale `rj._launched`) | not driven | | | | | | | | | | | 16 s |
| K2 | **TEST STALL** (`setup_wait`) | not driven | | | | | | | | | | | 20 s |
| K3 | **INCOMPLETE** (hands_off_done, arm_end, failing_end missing) | miss 46.8 | | | | | | | | | | | 33 s |

Notes:
- "last-supported" is the late row before the first all-wheels-off row.
- The engine's lip value is read at the all-off row (the same tick in every run).
- "on ramp": the held row had a wheel on `RampBody`.
- "dtick" is the number of ticks before the all-off row.
- The run-up from the first consumed pedal to the z gate was 91.7-91.8 m in every retry.
- No arm was excluded or failed.

## Artifacts (per run `appdata/g2/runs/<id>/`)
- `g2_trace.jsonl`: rows by phase (`pre`, `late`, `proc`, `keyreq`).
- `g2_events.txt`: events, OPEN / CLOSE, CHECKPOINT, recorder summary.
- `g2_manifest.json`: engine 4.7.1, GodotPhysics3D, 60 Hz, max 8 steps per frame; priorities;
  ramp / van_start transforms; gap; hull 2.24 x 2.0 x 5.8 m; wheels; Euler check.
- `g2_verdict.txt`; c1's `rig.txt`, `rig_verdict.txt`, `rig_console.txt`; `seg_1.log`;
  `run_info.txt` (head, launch time); `shots/`.
- Also: `appdata/g2/arm_table.md`, `prefix_diff.txt`, `game_hash_before.txt` / `game_hash_after.txt`,
  `stills_review.jpg`, `compile1.log` / `compile2.log`.

Euler: the van's `rotation_order` is 2. `Basis.get_euler()` with its default argument
reproduces a YXZ-built basis (`default_matches_YXZ: true`, XYZ false). This is checked in the
engine, so the order is **YXZ, verified locally**. The pure-yaw math check gives elev 0.0 and
up·up 1.0 (ok). Today's Euler maxima are descriptive only; nothing here uses them as thresholds.

## The controls (host detection, measured)
| Control | What the test code did | Host verdict | Detection | Process |
|---|---|---|---|---|
| K1 stale read | `G2Ctl` pointed the REQUIRED lookup `rj._launched` at `_launched_gone` | **TEST: observation invalid**, before any drive (preflight at physics frame 10) | STALE event and host STOP in the same second (13:36:18), 14 s from launch | taskkill, **gone 0.7 s** later |
| K2 live-step stall | `setup_wait` (5 s deadline) awaited `G2Ctl.never`; physics and recorder kept ticking (trace grew) | **TEST STALL (ownership unresolved)** | **flagged 0.14 s after the deadline, 5.14 s after the step opened** (limit 6 s) | taskkill, **gone 0.7 s** later |
| K3 missing checkpoint | the swimmer arm returned right after `slow_result` | **INCOMPLETE**: hands_off_done, arm_end, failing_end missing | at completion (33 s) | exited by itself |

c1's own verdicts on the same runs show what the host adds:
- K1: c1 said "RIG healthy, INNER PASS".
- K2: c1 said "asked but never ran (skipped)", c1's known mislabel of a stuck step.
- K3: c1 said "RIG healthy, INNER PASS".

The host doesn't read the control switch: `grep g2-control tools/g2` finds nothing, and
`G2Rec.gd` never reads `G2Ctl`. Each control was seen once. One control passing does not
qualify another. S3 / S4 for c1's T1-T3, N1-N4: **via c1** (R1, R8), with its known limits.

## Question (a): why a flat-out retry lands or misses at about 66.5 km/h. INCONCLUSIVE
Seen in the one miss, A0 (rows in `A0/g2_trace.jsonl`; sheets from `g2_runup.py`, `g2_flight.py`):
1. **The setup and the pedal matched B2 (which landed).**
   - Reset to release: 1.87 s.
   - Moved 0.039 m sideways with the brake on.
   - W requested at pf 1004; raw W seen in the late row of pf 1005.
   - Run-up 91.75 m to the gate.
2. **A steering tap on the ramp.** Raw D was held for 9 ticks, dtick -29..-21 (z 7.17-4.67 m).
   The front wheels were on `RampBody` and the rear wheels were moving from the bridge deck onto
   it. The van's steering built up to -0.119. Then:
   - yaw rate (body y) went to -0.465 rad/s at dtick -18;
   - roll rate (body z) went -0.125 -> -0.163 -> -0.178 by the last supported row (pf 1483).

   B2's last tap was at dtick -45 (z 12.2, on the bridge deck). Its body rates were ~0.001 at
   launch.
3. **The flight.** For 29 ticks after leaving the ramp, A0's z, height and speed match B2's
   within ~0.02 (e.g. tick 29: z -10.64 / -10.64, y 0.90 / 0.92, 63.5 / 63.5 km/h). Differences:
   - A0 keeps rolling: up·up 0.9714 vs B2's 0.9827 at tick 29;
   - x 0.95 vs 0.51.
4. **The stop.** Between tick 29 and 35 (z -10.64 -> -11.28), A0's speed fell from 63.5 to
   4.2 km/h, with **no wheel in contact**, and yaw rate jumped to -1.556 rad/s. It then fell in
   ("shallows", 1.33 s after the lip). At the same z, B2's front wheels touched `BridgeDeck`
   (tick 35, 2 wheels, 54.9 km/h) and it landed.
   - The hull is 5.8 m long, so A0's nose was near the far edge (z ~ -14) when it stopped.
   - **What A0's hull hit: NOT MEASURED** (no contact monitoring). The far deck's collider
     transform wasn't recorded, so **no geometric shortfall is computed**: a near-edge case
     without contact evidence is ambiguous, as the spec says.

Why INCONCLUSIVE (the four conditions):
- **Pair A flipped** (A0 miss, A1 landed), but **not through its assigned factor.**
  - The wait (0.3 vs 5.0 s) changed nothing recorded between reset and drive: horizontal move
    0.039 vs 0.045 m, brake on in both, pedal consumed 1 tick after release in both, same run-up.
  - What differed was the tap: A1's last D was at z 6.97 (rear wheels still on the bridge deck),
    with launch roll rate -0.071.
  - A flipped landing without a chain from the factor is INCONCLUSIVE (spec).
- **Counter-example to the candidate chain:** B1 had a D tap on the ramp too (z 4.07) and a
  roll rate of -0.154 at launch, and landed. B1 also differed in launch elevation (4.38 deg vs
  2.07), x (1.18 vs 1.02), pitch rate (-0.30 vs -0.42) and frame pacing (101 multi-tick frames).
  The tap alone doesn't separate land from miss in this data.
- **Pair B** (steering held until the first all-off row): **the intervention was assigned but
  never exercised.**
  - B1x's extension ran z 0.75 -> -2.04 (9 ticks), and `steer_only()` requested no A or D in it.
  - The on-ramp tap (z 4-7) is before the z <= 1 gate, so B's factor can't touch it.
  - Both arms landed. No mechanism.
- **Pair C** (dispatch phase): established. `G2LateDriver` at priority 50000 ran after Camper
  and RampJump (0), and before the recorder's late row (100000).
  - Key requests showed in the raw state **the next tick** in both arms: C0 27 of 32 at +1 tick
    (+2 ×3, +4 ×1, 1 seen at +0); C1 30 of 32 at +1 (+2 ×2).
  - Input reached the van on the next process-frame flush either way, so moving the decision
    later in the tick changed nothing measurable.
  - Both landed. No mechanism.
- **Still confounded:** the AutoDriver's tap timing (it follows the van's path, which varies
  run to run), launch elevation and x, frame pacing (process frames per 60 physics ticks: B1 ~46, B3 ~60, the rest ~75-90),
  and solver variation (no RNG seed is exposed).
- **Ownership: UNRESOLVED.** The taps are a recorded test action, but they weren't shown to
  cause the miss (B1). No recorded game behaviour broke a stated contract.

## Question (b): the 57.1 km/h retry in c1 S1_4. INCONCLUSIVE, historical cause NOT PROVEN
- Every retry here reached 66.0-66.8 km/h; **none near 57**.
- Measured in all 9 retries:
  - reset -> release took 1.85-1.87 s, or 5.0 s + 1.87 s in A1;
  - the van moved 0.038-0.045 m sideways (0.29 m in 3D, mostly settling down onto its
    suspension), brake on throughout;
  - the first pedal was consumed 1-2 ticks after the release;
  - the run-up from the first pedal to the gate was 91.7-91.8 m.
- Rolling before throttle, a shortened run-up and brake / force overlap were **not observed**.
- Steering / support loss and other contacts were seen in the 66 km/h retries only.
- Every arm's achieved speed is in the table.

## Swimmer pair: no drift difference. INCONCLUSIVE (nothing to explain)
- **Setup:** both arms used the same fresh ramp setup, P1 driving and P2 unseated (the `seats`
  checkpoint: P2 ""), with the pad connected and neutral.
  - S0: P2 at `van_start * (-3.2, 0.3, -1.0)`; after 4.0 s, swimming false, on floor true.
  - S1: P2 at c2's river spot; after 4.0 s, swimming true, at y -15.66.
- **The slow try** missed in both (46.9 / 47.0 km/h).
- **At the game's reset:**
  - P2 in S1 was swimming at pf 974 (the row before) and not swimming in the reset row.
  - P2 was placed at the same spot as in S0, to 1 mm.
- **Over the next 6.6 s, hands off:**

  | | S0 | S1 |
  |---|---|---|
  | Van horizontal drift | 0.0451 m | 0.0449 m |
  | Vertical settle | -0.2849 m | -0.2849 m |
  | Peak 3D | 0.4734 m at +28 ticks | 0.4734 m at +28 ticks |
  | Brake | on throughout | on throughout |
  | Frozen from | +121 ticks | +121 ticks |
  | P2 swimming at the end | false | false |
  | P2 to van | 3.32 m | 3.32 m |

- On the clean game, a correctly cleared swimmer is the expected control result.
- No body impulses exist to look for (contacts NOT MEASURED), and there was no difference to
  explain. P1 (brake-on drift) is **not called**. The P3 patch was not applied (the referee may).

## R5: claims and NOT PROVEN
- **Claims** (observed attempts only):
  - the recorder and host saw every arm, alive and complete, with the three test-side failure
    modes flagged (stale field, stuck step, early return);
  - in these 9 retries, 1 miss at 66.53 km/h, with the chain above observed but not proven to
    cause it;
  - no rolling before throttle after the game's reset;
  - no swimmer-associated drift on the clean game;
  - retry dispatch phase didn't change when input was consumed.
- **NOT PROVEN:**
  - why the historical misses happened (g12's baseline, S1_5) and the 57.1 km/h retry;
  - whether the jump lands reliably;
  - the 61-68 km/h speed spread;
  - the hut, the departure, playability and visuals;
  - P2's real journey into the river;
  - what the hull hit in A0;
  - all other puzzles.
- P1 / P3 are not named (neither was observed failing). P2 and P4-P7 are outside coverage.

## Failure modes (as the spec lists them)
| Mode | Seen here? |
|---|---|
| Rare miss not reproduced | Baseline 0 / 3; overall 1 / 9 retries; 57 km/h 0 / 9 |
| Solver / RNG / frame-pacing variation | Pacing 408-797 process frames per ~530 ticks; RNG not exposed |
| Recorder overhead | p50 ~0.2 ms, p99 < 1 ms per row; max 29 ms (a one-off) |
| Paired initial states different | Reset states matched to mm; the tap timing differed (A0 vs A1) |
| Phase aliasing / stale wheel contacts | Wheel contact read in the late row can describe the previous integration; adjacent rows kept |
| Key dispatch not consumed when assumed | Requests take effect on the next process-frame flush: +1 tick typically, up to +4. B3 shows D still held at z 0.74, after the gate's release request |
| Landing mutates wheel / cargo before the late sample | Not examined (pairs stop at the result) |
| No body impulses to explain swimmer drift | True: contacts NOT MEASURED |
| Private-field coupling | `_launched`, `_wheels` (validated; K1 shows a rename turns into TEST) |
| Bounded screenshot loss | No `shot:` deadline expired in any run; launch / result stills missing by build (departure 2) |
| c1 failed termination | Not seen: both kills verified gone in 0.7 s |

## How the referee runs it (from `MPG_dev`, one game at a time)
```
NO_CHECK=1 tools/g2_run.sh ramp <id>          # baseline under the recorder (~129 s)
NO_CHECK=1 tools/g2_run.sh g2_a0 <id>         # any arm: g2_a0 a1 b0 b1 c0 c1 s0 s1 (~40-50 s)
G2_ARGS="--g2-control=stale" NO_CHECK=1 tools/g2_run.sh g2_s0 <id>   # also stall / early
python -I tools/g2/g2_arms.py appdata/g2/runs/<id> ...     # the arm table
python -I tools/g2/g2_runup.py appdata/g2/runs/<id> 60 6   # the last metres before the lip
python -I tools/g2/g2_flight.py appdata/g2/runs/<id>       # the flight
python -I tools/g2/g2_latency.py appdata/g2/runs/<id>      # dispatch -> raw key
python -I tools/g2/prefix_diff.py                           # the prefix copy proof
```
- Run ids must be new (the wrapper refuses an existing one).
- Drop `NO_CHECK=1` to compile first (7 s here).
- The verdict is the `==== G2: ... ====` line (also in `g2_verdict.txt`); exit 0 only on
  INSTRUMENT OK.
- Note: `queue.sh`'s printed `rc` is wrong (`$?` after `$(date)`); read `g2_verdict.txt`.

## For the referee / GPT to decide
1. **Is the A0 chain worth a follow-up?** The candidate is an on-ramp steering tap -> roll rate
   -> the hull stopped with no wheel contact. A follow-up would need what the spec forbade here:
   the van's contact monitoring (a game-body setting) or the far deck's collider recorded, plus a
   steering-timing factor. Pair B's factor (after the z gate) can't reach a tap at z 4-7 m.
2. **Departure 2** (no launch / result stills in the pair and swimmer arms): accept it with
   traces only, or require them.
3. **Baseline deadlines** (departure 1): accept `shot()` + episode deadlines for an unmodified
   `t_ramp`, or count it as a gap.
4. **S1 side data:** today's `t_ramp` landed 3 / 3 under the recorder, and the copied prefix
   missed once in 7 (A0).

## Referee's scoring of g2 (2026-11-06, 13:42-14:05)

Scored head: `g13-trial-g2` `afb9e9b`. Every run watched (log growth every 5 s, the 400 s kill, the
minimize watchdog except during N5), one game at a time, unique run ids `R_*` under
`appdata/g2/runs/`. Conditions differ from the builder's controls: a real minimized window (not a
test-code stall), c1's freeze, a **game-side** rename (not a test-side lookup), the public practice
patches, and 10 clean arms.
**Code read:** `G2Rec.gd` reads only `--g2-run=` from the command line; `g2_watch.py` never reads the
control switch or a patch. No file under `FindingNaresh/scripts` outside `dev/` changed
(`git diff --stat f15b340 afb9e9b`). What g2 is, read from its tools: a **recorder + host health
checker + analysis sheets ("measurements only, no thresholds")**. Its only automatic verdict is about
the instrument (INSTRUMENT OK / TEST / INCOMPLETE / OBSERVATION INVALID); any statement about the
game needs a reader comparing sheets.

| Check | Runs | Result |
|---|---|---|
| **S1** no false alarms | 10 clean arms (`g2_a0` x3, `a1`, `b0`, `b1`, `c0`, `c1`, `s0`, `s1`) | **10 / 10 INSTRUMENT OK**, no TEST / INVALID / INCOMPLETE on the working game, no cause named. Retries 66.36-66.89 km/h; the 61-68 spread not reached (R14). |
| **S2** finds real bugs | P1 on `g2_s0`, P3 on `g2_s1` (the only practice bugs in g2's coverage, R5) | **0 / 2 caught by the method's verdict** (both INSTRUMENT OK). **Mechanism visible on reading, 2 / 2:** `g2_table.py` shows P1 as drift 4.57 m, brake `[false]`, never froze (clean `s0`: 0.29 m, brake on, froze) and P3 as P2 still swimming at the end, drift 0.65 m with the brake on (clean `s1`: 0.29 m, nobody swimming). Seen only by comparing with a clean arm. P2, P4-P7: outside coverage (not caught, R5). |
| **S3** blames the right thing | T4 (R15): the game field `_launched` renamed in `RampJump.gd` (reverted after) | **1 / 1: "TEST: observation invalid"** before any drive, 20 s wall. (c2 gave a false pass on the same kind of break.) T1-T3 via c1. |
| **S4** can't pass by doing nothing | **N5 for real**: the test window minimized 35 s into a baseline `ramp` (watchdog off); N1 c1's freeze at 20 s in `g2_a0` | **N5: TEST STALL 5.02 s after the stuck step opened** (`shot:ramp_shutter`), process gone. The van drove and landed while minimized; only the drawing stopped. **N1: not passed:** c1 "no heartbeat 20 s", g2 OBSERVATION INVALID (trace still 21.6 s), flagged at the end, after c1's kill. N2-N4 via c1. c1's rig line again said `ramp` "never ran" on a stuck step (its known mislabel). |
| **S5** real path | code read + prefix diff | **Pass.** Declared setup: `ramp_start`, seating and placement, the brake release, P2 in the river (swimmer arm). Driving through key events only; the prefix diff shows only factor and observation lines changed. |
| **S6** cost | measured | Build + qualification 29 min (14 launches). Per arm 41-52 s, baseline ~128 s (+ ~76 s on a stall). Recorder p99 < 1 ms per row. Archive ~18 MB per arm (254 MB for 14). No model inside the play loop; **a diagnosis needs a reader** (the builder's analysis overlapped its runs, ~4 min after the last). Scoring: 14 runs, ~23 min wall. |

**New data for the land-or-miss question (measured, no cause stated):**
| Arm (0.3 s wait after the reset unless noted) | Retries | Misses |
|---|---|---|
| `g2_a0` (pair A control) | 4 (builder A0 + R_C1-3) | **3** (A0, R_C1, R_C2) |
| `g2_a1` (5 s wait) | 2 | 0 |
| `b0`, `b1`, `c0`, `c1` | 8 | 0 |
| `t_ramp` baseline under g2 | 3 | 0 |
R_C1 missed **with no on-ramp tap** (last A/D at z 12.3, off the ramp, roll rate +0.031): the candidate
chain in the builder's (a) does not cover it. R_C8 had an on-ramp tap (roll -0.173) and landed. Small
samples; the pair-A difference (3 / 4 vs 0 / 2) is a count, not a mechanism.

**Verdict: g2 qualified and scores well on the health side** (S3 1/1, S4 N5 caught in 5 s where c1
missed it for 440 s, S1 10/10), **but it is not a detector**: on the two practice bugs in its coverage
the runs passed, and the bugs were only visible to a reader comparing sheets. Its two questions
stay INCONCLUSIVE.
