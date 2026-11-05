# g1 builder contract — GPT auditor, Stage 3

Version 3, 2026-11-05. Build on `g13-trial-g1` from `g12`, in MPG_dev.
Opus builds; GPT writes no game or test code. This document is the implementation
contract. No new actor skills, recovery search, game fixes or builder-added rules.

## Purpose and changes from round 2

Core: prove actual driving outcomes with real input, without fixed-time steering
or model thinking between steps. Controller success is never checker evidence.

| Version | Kept / changed | Reason |
|---|---|---|
| v1, round 1 | Sensed steering plus separate outcome checker. | Replace forward-only driving and distance-from-start passes. |
| v2, `audit_r2_gpt.md:157-216` | Two driving stretches, keyboard pulses, source-based input path; excluded miss recovery. | Bound the build and ban direct steering/brake setters. |
| v3, this contract | Restore slow miss, reset and immediate retry to stretch A. Keep B separate. Reuse c1 conditionally; require independent receipt evidence. | Agreed `top4.md:9` includes miss/reset/retry. c1's three false alarms and unverified fix (`trial_c1.md:90-105`) forbid unconditional health inheritance. |

## Coverage (R5): exactly two stretches

**A:** Fresh declared run-up, both aboard → slow miss → the game's own reset →
five seconds untouched on its brake → input-only retry → supported far-bank
arrival → stop. No fresh setup between miss and retry. Game-owned reset movement
is the behavior being checked (`RampJump.gd:608-640`), not a test teleport.

**B:** At A's actual stopped far-bank pose, declared repair/setup of the skipped
hut outcome → real-input merge onto outgoing road → 30 m signed road progress →
stop. No relocation or re-aiming the van in this second setup. This keeps actual
landing/parking variation in the departure challenge.

NOT PROVEN: the hut route, crate, leg-up, door, wheel retrieval/refitting by
players; visual/HUD/hub/wreck correctness; the river journey and swimming reset;
P2-left-behind play; boiling-engine play; connection of A to B without setup;
any other puzzle. P2–P7 count not caught in S2. P1 is a target only if its broken
reset brake/drift is actually observed and named; no score promised in advance.
Both aboard means g1 cannot exercise P3. R7 read-only permission adds no claims.

## Dependency and hour budget

Referee must supply an accepted c1 commit and the passing controls for each reused
part, including a clean exact-head ramp using receipts. Use the requirements in
`audit_c1_gpt.md`, “Reuse ruling requested”. Copy only the qualified health parts
and their required hooks into the g12-based trial; record source SHA and file list.
Do not merge the whole c1 branch or count its build cost twice (R1).

If c1 is not fit, report **BLOCKED: unqualified shared health layer**. A driver
and recorder may be built, but do not run qualification without a qualified
external watchdog or call the trial passed. Do not invent a replacement health
layer. The referee decides whether to qualify c1 first or score g1 incomplete.

Total cap: 60 real minutes, build **and** own qualification (R4). Target 40 build,
20 qualification. All coding, compilation, fixes, watched qualification, evidence
review and report time count. Stop at the cap. Referee scoring is separate.

## Setup boundaries

Use a new explicit scenario ID `g1`; no presets, save or reload. Before A:

- Use `ramp_start()` only as setup (`PlayTest.gd:11641-11659` on c1 head;
  resolve corresponding g12 lines). It repairs, positions and seats by code.
  Seat P2 as passenger, enable its normal test pad, close journals/maps.
- Reset story/ramp only here; engine on, fuel/coolant healthy, van settled,
  both seats occupied, zero debug throttle/steer, brake on, inputs released.
  Position is `r.van_start`, with the chosen initial lane shift along ramp right.
- Recorder writes all actual setup values, player/device/seat IDs, road points,
  ramp transform/gap/deck dimensions, collider IDs and support allowlist.
  Emit A_BEGIN only after prerequisites are read back. Missing prerequisites
  are TEST SETUP FAILURE, never a game finding.

Between A and B release inputs and emit A_END / SETUP_B. Repair with the existing
repair helper and set needed story/engine/seat state only in this declared gap.
Preserve the actual stopped transform. Read back wheel repaired, both aboard,
engine on, debug controls zero, brake on. Log every mutation, then B_BEGIN.
If the helper cannot preserve pose, stop and report; do not relocate as a fallback.

After either BEGIN: no test writes to transforms, velocities, seats, wheel state,
story, cameras, engine state, brake state or dev controls. Do not call `ramp_try`,
`ramp_drive_off`, `ramp_start`, repair or reset helpers inside a proven stretch.
Only ordinary input events may act. Read-only sensing/probing is allowed.

## Driver: fixed small controller

P1 drives on keyboard. Send physical **and logical** W/S/A/D/Space key fields
through the ordinary input-event route, so both physical reads and
`InputDevice` logical reads can be audited. P2 remains passive aboard with its pad
connected. No pad steering implementation, no `debug_steer` / `debug_throttle`.
Keyboard steer is -1/0/+1 (`core/InputDevice.gd:338-346`). Space toggles the
ordinary handbrake (`InputDevice.gd:39`; `vehicle/Camper.gd:1016-1017`).

1. Read pose/velocity each physics tick. Reproject onto the road's polyline
   segments in XZ every tick, not a cached advancing sample index. Use actual
   segment lengths for signed arc position. Choose outgoing sign by its tangent's
   agreement with ramp forward (-ramp basis Z); freeze that sign in the manifest.
   Driver and checker implement their own projections, not a shared progress value.
2. Approach target: 8 m + 0.4 seconds of current horizontal speed ahead on road,
   plus lane offset. In ramp-local z <= RAMP_LEN + 8 m, use the straight ramp
   centreline with that lane offset instead, continuing onto the far bank.
   With normalized horizontal forward f and target direction t, heading error
   is atan2(-Vector3.UP.dot(f.cross(t)), f.dot(t)), positive right.
   Desired steer = clamp(error / 0.35 rad, -1, +1).
   Recompute every six physics ticks. Over those six ticks press
   D for round(6*abs(steer)) ticks if positive, A if negative; release otherwise.
   Never both. No smoothing, tuning search or alternate controller added.
3. One pedal owner: W below target minus 1 km/h, S above target plus 1 km/h,
   neither inside the band. Use horizontal speed. Slow attempt target 48 km/h;
   retry target from command line; B target 25 km/h. No reverse recovery.
4. At each approach/retry/B start, if brake is on, tap Space for 0.10 real
   seconds and release, then observe brake off within 1 s. Do not resend toggles.
   Pedal input follows only after that readback. Failed readback is unresolved
   input/game behavior unless transport rejection was measured.
5. Release throttle/steering as soon as all wheels leave support over the gap.
   On miss onset release every key and wait for the game's reset. During the
   five-second reset observation, send nothing. Then use the same controller
   for retry, without replacing the game's reset pose or brake.
6. On first supported far-bank contact, brake with S; below 0.5 m/s release S
   (avoids reversing), tap Space if brake is off, and observe the stop. B brakes
   after reaching 35 m signed progress, leaving margin for the checker’s 30 m.
7. Before ramp entry and during B, sweep the chassis collision volume horizontally
   along current velocity/heading for two seconds of travel (minimum 3 m).
   Exclude self and actual continuous road/deck support colliders only; enumerate
   their IDs from built geometry, never by excluding all static bodies. Disable
   this sweep from ramp entry through landing; absence of gap support is intended.
   A non-support hit releases W, commands stop, records collider/path and fails
   BLOCKED, cause unresolved. Do not steer round it or silently disable the sweep.
   If driveable support cannot be separated reliably, stop and report that gap.

## Independent checker and evidence

A separate observer owns verdicts. It reads raw engine/game state each physics
tick and appends a buffered row; flush at least every 0.5 real seconds and on
events/failure. Record run ID/SHA/options, monotonic real time, physics/process
frame IDs, phase, requested keys and releases, physical/logical key states,
P1 device kind/active/throttle/brake/steer, P2 binding/presence, player seats,
engine force/brake/steering/parking brake/debug controls, pose basis, world and
ramp-local velocity/angular velocity, each wheel's contact body/point/normal,
road projection and ramp flags (`jumped`, `failing`, `misses`). Capture last
supported launch row and first far support row separately. Do not use Euler
maxima, `last_lip_kmh`, actor done, or story goals as landing proof.

No checker code reads negative-control switches. The negative hook changes only
actor behavior; the checker sees resulting observations. Static shared geometry
is allowed; controller-computed success, target arrival and progress are not.
The host wrapper scans the current segment log for SCRIPT ERROR every second
and on exit. Include the matching line and following two lines in its result;
this is a g1 addition, not inherited c1 error detection. Do not consume the
ordinary c1 wrapper's zero exit status as the combined verdict.

| Obligation | Exact rule |
|---|---|
| Health | Require accepted c1 health plus nonempty asked/start/end ID accounting. Any pause, missing player, stale stream or frozen physics is non-pass. No expected pauses. External watchdog must report silence within 60 s throughout BEGIN–END. |
| Inputs | Log requests and raw/device reads each frame. For a key held unchanged through two process and two physics frames, missing raw state = TEST transport failure. Raw present but wrong device/readback = INPUT MISMATCH, ownership unresolved. Short pulses not sampled are UNOBSERVED, not receipt PASS. Outcome obligations still apply; g1 claims no proof every tap was delivered. |
| Miss | Within 40 real seconds of A_BEGIN, see positive approach displacement >=10 m, loss of all wheel contact over the gap, and physical descent into water (ramp-local y < -1.3, -gap < z < 0), without far-bank support. `misses` must increase and `failing` must occur. Physical/detector disagreement fails unresolved. |
| Reset | Within 10 s of miss onset, see van back within 1 m of declared `van_start`, speed <0.2 m/s, and `failing` false. Observe five further real seconds with all inputs released. Brake must remain on and displacement from reset observation start <=0.30 m. Brake off names reset brake failure; drift with brake on names drift only. Log both separately. Tolerance is a trial rule, not a proved universal limit; scoreboard clean 0.04 m / P1 3.79 m supports trying it (`scoreboard.md:59`). |
| Retry / crossing | From actual reset, no test state writes. Within 60 real seconds of retry start: approach >=10 m; all wheels lose contact with centre z <0; then >=2 wheels contact fixed solid far-bank/deck bodies at contact points z < -gap for >=0.2 s, centre z < -gap -0.8, abs(x) < deck_w/2, upright basis Y dot world up >0.6. Require >=1 m further forward displacement after first far support. `jumped` must agree within 1 s of supported landing. No support on trees, wreck, actors or carryables. |
| A stop | Inside that same retry deadline, speed <0.2 m/s, parking brake on and far-bank support for 2 continuous real seconds. Both aboard throughout A. Any unexpected retry miss is retained failure, not a new attempt. |
| Departure | Within 60 real seconds of B_BEGIN, checker’s signed road arc position increases >=30 m from B_BEGIN. For the last three continuous moving seconds before braking, speed >0.5 m/s and road distance <=4 m (Landscape.ROAD_HALF); stop also inside that corridor. Then speed <0.2 m/s and brake on for 2 s, both aboard. No closest-ever distance or radial distance substitutes. |
| No progress | During commanded ground movement, fail after 10 real seconds without >=1 m increase beyond prior best forward progress. Exempt only airborne, declared reset wait/observation and final stop. World-alive/body-stuck must fail too. |
| Errors/completion | Any SCRIPT ERROR invalidates PASS; attribute TEST only if it identifies test code, otherwise unresolved. Scenario end or actor done without every applicable obligation fails INCOMPLETE. Missing summary/trace/evidence never passes. |

Any unexpected discontinuity (over 5 m translation in one physics tick) outside
the observed game miss/reset window invalidates crossing/departure. Log it and
report unresolved. Never count the reset jump as driven road progress.

Final verdict: PASS only if both A and B and health pass. Otherwise FAIL with
first broken obligation and raw measurements, or TEST/UNRESOLVED as specified.
Do not infer “game bug” just because legal input did not succeed. Preserve all
earlier failures; no automatic reruns. Healthy c1 plus failed game obligations
must exit nonzero. Report each phase PASS/FAIL/NOT REACHED independently.

Save trace, short summary, failure shot if engine responsive, launch/landing/stop
shots, and one recorded video under project `appdata/`. Observe from normal
player cameras; optional observer evidence cannot replace a player's reached
view (R2). No camera writes inside stretches. Watch video/frames before claiming
qualification. Give timestamps and what to judge. Recording failure means
evidence incomplete, not an excuse to rerun the whole route unnoticed.

## Referee variation switches

Expose `--g1-speed=61..68` (default 66) and `--g1-lane=-0.5..0.5` metres
(default 0). Reject invalid values before setup. Lane shifts the initial pose
and steering target only in setup/normal control; never shifts physics mid-run.
Slow attempt remains 48. B starts at the actual varied landing/parking pose.

Suggested ten `(speed, lane)` settings:
`(61,-.5), (61,.5), (62,0), (63,-.5), (64,.5), (65,0), (66,-.5),
(67,.5), (68,-.5), (68,.5)`.
Log requested versus achieved horizontal/total launch speed, local lateral
position, full launch vector, landing pose and B start. Referee judges actual
S1 speed/landing spread, not options. If 68 is unattainable, report the S1
shortfall; never change physics, accelerate time or weaken the coverage rule.

## Qualification and stop rules

Before a game run check no referee/game process is using this copy. Wait for
explicit referee handoff; never interrupt its scoring. Keep window behind the
user's windows and mute it. Expected full route upper bound: about 3 minutes
plus launch/setup/recording; actual time must be reported. Watch movement, phase,
errors and logs every few seconds. First off-plan result stops actions; capture
evidence and report. Do not run smoke, area sets or full game for this trial.

Within the hour:

1. Compile the changed test scripts. Source-audit every write after BEGIN.
2. One clean `g1` run at `(66,0)` must pass A and B with healthy c1 and complete
   evidence. Log minutes and achieved speed, not an estimated green.
3. One negative `--g1-negative=idle-departure`: after B_BEGIN the actor sends no
   movement input and immediately announces done. Keep the checker/watchdog
   running. It must fail INCOMPLETE/no-progress within 10 s, never PASS. The
   checker must not inspect that switch or require the announced done to fail.
   Qualify from the same setup path, not a new teleported B start.

Report qualification logs, code paths, timestamps, changed lines, build and run
minutes, zero online-model tokens, video timestamps, qualified c1 source and
remaining holes. Referee later runs the ten clean variations and public controls.

Stop and report rather than decide: missing/unqualified c1; unavailable normal
input or contact APIs; unreliable support filtering; ambiguous route direction;
missing video support; a required phase not runnable; any real game finding;
three failed fix/run rounds; cap reached. Do not add a pad driver, swimming
actor, obstacle routing, tuned parameters, a broader state oracle or game fixes.
Partial implementation is a failed/incomplete trial against this declared scope,
not a silently narrowed successful one. The referee alone may change scope or
scoring rules. No merge/push; follow the referee's local-save instructions.
