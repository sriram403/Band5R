# g2 builder contract — causal comparisons, v1

GPT auditor, 2026-11-06. Builder: Opus. Work in MPG_dev only, starting from
g12 `9112ee7`, trial branch `g13-trial-g2` managed by the referee/builder as
authorised in the brief. No game edits, fixes, merges or pushes. This contract
is the entire experiment; report departures, do not add hypotheses or searches.

## Question, scope and versions

Explain (a) why today's flat-out retry lands or misses at about 66.5 km/h,
and (b) the 57.1 km/h retry in c1 S1_4. Then test whether a left-behind swimmer
has an observed connection to reset drift, without calling brake-on drift P1.

v0 (g1) tried to guarantee driving with an unqualified controller and an exact
freeze rule. v1 (this trial) removes both: instrument today's driver, repeat
the baseline, run three one-factor comparisons, preserve inconclusive results.
I think these comparisons can expose a mechanism inside the hour. No promise
that the intermittent 57 km/h case or original miss will reproduce.

R5 claims: diagnosis of the observed attempts only, including recorded test
input failures and game/test ownership only when demonstrated. NOT PROVEN:
unobserved historical runs, universal landing reliability, 61–68 speed spread,
hut/departure/playability/visual correctness, P2's real journey into the river,
all other puzzles. P2/P4/P5/P6/P7 are outside coverage. P1/P3 count only when
their actual failure is observed and named; no advance score promised. A
completed experiment may legitimately conclude INCONCLUSIVE on both questions.

## Reuse and minimum implementation

Use c1's seven code files from accepted `a6a412f` (code commits `920110d`,
`3b96807`, `a106f90`, `57b8afd`), by file, record the exact list/diff. R8/R1
scores remain “via c1,” with its known limits. Explicit nonempty scenario IDs,
no presets/save/reload/intentional pause. Do not import g1's driver/checker.

c2 `04c3102` is optional source material **only for** the swimmer setup in
`PlayTest.gd:t_c2_more` and G1/G2 read-only observations in `C2Watch.gd`.
Record adopted files/sections. Do not import its wrapper's green-exit policy,
its seven-rule coverage claims or whole `c2_more` route. Copied private reads
must be type/presence validated. A stale field must invalidate the observation.

Add a test-side recorder, comparison scenario(s), a host wrapper/report. Test
files under scripts/dev and tools only. Preserve game's tracked-file hashes
(vehicle/player/puzzle/core/world/etc.) before and after. A read-only game-field
lookup is allowed; no callback replacement or subclass of the game body.

## Run order and wall-clock cap

One game at a time; tasklist before each launch. Behind user windows, muted,
no focus theft. Freeze the experiment manifest before its first measured run.
Each arm gets a fresh process and the same declared setup/prefix. No input
playback, state snapshot restoration or search for a favourable launch.

| Order | Episodes | Reserved wall time |
|---|---:|---:|
| B1–B3: unmodified baseline `t_ramp`, recorder only | 3 | 10 min (3 x 200 s) |
| Pair A, pair B, pair C, two arms each | 6 | 20 min (6 x 200 s maximum) |
| Swimmer pair, narrow slow-miss/reset stretches | 2 | 2 min (2 x 60 s target) |
| Local negative controls (stale read, live-step stall, missing checkpoint) | 3 short launches | 3 min total |
| Compile/import | one, plus one only if needed | 1.5 min (40 s each measured) |
| Build/read/instrument | — | 18 min target |
| Inspect evidence, write report | — | 5 min |
| **Total reservation** | **11 gameplay episodes + 3 controls** | **59.5 min** |

Full ramp measured 140–200 s, short c2_more ~55 s. Truncated pair prefixes may
save time; do not budget those savings before measuring. Three baseline runs
are **three attempts to reproduce the historical miss**, not a requirement
to obtain three misses. Report 0/3, 1/3 etc.; never keep retrying until it fails.
One compile/build correction allowed inside cap; no repeated tune-run loop.
At minute 60 stop, preserve partial evidence, report incomplete qualification.
Referee scoring is outside this R4 cap; report its costs separately.

## Baseline and setup boundary

B1–B3 run today's complete `t_ramp` under c1 plus the passive recorder. Preserve
its shots, setup timing, cargo, pad, passenger, slow target 48, reset wait,
0.3 s wait and flat target 80. No promise that passive instrumentation has
zero cost: log frame pacing and observer callback/flush durations.

Pairs reuse the exact `t_ramp` prefix through the flat-out result, including
pre-drive shots and cargo. Copy that prefix into a test-only scenario; stop
after the flat result rather than playing the hut. Record a source diff proving
that only the declared factor changes. Prefix duplication is permitted for
this bounded experiment; do not refactor today's baseline while measuring it.

Existing `ramp_start`, seating/placement, camera setup and `ramp_try`'s
`set_parking_brake(false)` are **declared setup**, not input-only proof.
The release before each drive marks that setup boundary; record pose/velocity,
brake/freeze, players/seats and all state writes there. Reset itself is the
game's action under test. Between the slow miss and retry: no repair, teleport,
reset helper, seating change or pose/velocity write. All arms retain the same
existing brake release; observe it, do not infer that reset rolling preceded it.
Driving after each setup release uses only the existing key-event route. No
debug steer/throttle, physical parameter writes, timerscale or FPS changes.

## The three pairs — fixed in advance

Within each pair A/control precedes B/intervention. Other pairs start afresh
from the original prefix, never accumulate interventions. Two outcomes alone
do not prove cause; initial differences and frame pacing are recorded confounds.

| Pair | Control | Intervention | The sole assigned factor |
|---|---|---|---|
| A: reset settling | today's 0.3 s wait after the same reset/whiteout checks | 5.0 s instead, hands off throughout | pre-retry waiting duration; same release/driver afterward |
| B: steering release | original `ramp_try`: release W/S/A/D at local z <= 1 m | W/S still release at that same gate; continue only `AutoDriver.steer_only()` until all four wheels report no contact, then release A/D too | steering release policy on retry only |
| C: input dispatch phase | original retry decisions/calls after awaited `SceneTree.physics_frame` | same per-tick decision algorithm in one test node's late `_physics_process`, after Camper and RampJump callbacks | phase of the retry's decision/input dispatch; same keys, targets and geometry |

B: retain a separate AutoDriver instance/state exactly as original; once
pedals release never let `step()` reassert W/S. End the steering extension at
the first all-off sample following its z gate (even if brief); log it. No g1
pulse controller, lane change or extra steering correction. The 1 m gate is
the existing test's policy, not a claimed physical threshold.

C: use test-node physics priority later than the observed game's priorities;
log the actual priorities and tree order, don't change any game node priority.
Disable the original retry step caller in the intervention so there is exactly
one owner. Slow try/prefix unchanged. Decisions and releases otherwise match
original `ramp_try`, including z gate. If no later callback ordering can be
established, report C UNIMPLEMENTED; no substitute FPS/stress experiment.
Input consumption is not assumed synchronous with dispatch.

A's 5 s is the already-measured reset observation interval (c1/c2 clean
~0.04–0.045 m, P1 2.71–3.79 m). It is an intervention, not a universal settle
threshold. B/C are hypotheses (I think); no speed/angle guarantee is attached.

## Final swimmer pair (no game patch)

Use c2's narrow slow-miss/reset stretch; omit door/F1/hut. Both arms: same
fresh ramp setup, P1 driving, P2 unseated, connected pad neutral, slow target
48, game's reset, six seconds hands off. Factor: **P2's initial placement**.
Control: P2 at the game's near-side reset standing point (`van_start *
Vector3(-3.2, 0.3, -1.0)`), confirmed dry/on foot. Intervention: c2's river
position `ramp_transform * Vector3(5, -10.5, -gap/2)`, confirmed swimming by
ordinary game updates within c2's existing 4 s setup wait. Equalise setup wait
duration in both arms. Do not set `swimming`, seat a passenger in one arm, or
alter the reset code. Initial location is the assigned factor; changed mode
and subsequent path are consequences, not independently controlled variables.

No P3 patch is applied by the builder: that edits game code and violates this
contract. The referee may later use its public P3 patch as an S2 scoring run.
On clean game, a correctly cleared swimmer is an expected useful control.
This pair tests the swimmer hypothesis; it cannot promise to reproduce P3.
Record both players' swimming/position/velocity/seats across the game's reset,
brake state and van drift. If drift differs without a recorded physical
interaction chain, report swimmer-associated drift, mechanism INCONCLUSIVE.

## Recorder: fields and update phases

Attach test observers only; never add logging to game methods. Use numeric
physics frame ID, process frame ID, monotonic microseconds and engine delta,
not `t += 1/60` as a clock. Explicitly distinguish these sampling phases:

1. `physics_frame` signal/pre-node snapshot: immediately on the signal before
   normal node callbacks; log actual priority ordering in the manifest.
2. Late test `_physics_process`: after Camper/RampJump callbacks by priority.
   “Late” is post-callback, **not** post-solver. Wheel/velocity values may refer
   to the preceding integration; retain adjacent rows, never invent simultaneity.
3. `_process`: process-frame ID/time, raw/device input reads and count of
   physics ticks since the previous process frame. Log requests at dispatch
   with phase/frame IDs before forwarding them to the existing key helper.

Per physics phase, from setup through slow/reset/retry/result and the swimmer
observation, buffer a row with:

- episode/arm, phase, sequence, times, pause, node validity; actual keys
  requested and raw physical/logical state; P1 device identity and its
  throttle/brake/steer/handbrake reads; passenger device identity/neutral state;
- van full world transform basis/origin, ramp-local position, world velocity,
  ramp-local velocity, angular velocity in world and body axes; speed magnitude,
  horizontal and forward components separately; parking brake, freeze/sleep,
  engine force/brake/steering, debug inputs, engine/heat/coolant/wheel condition;
- all wheel transforms, in-contact bits, contact point/normal/body path and
  numeric instance ID; available suspension values; missing APIs marked unavailable;
- ramp transform, `jumped`, `failing`, misses, `_launched` (validated read),
  player position/velocity/swimming/seat, driver's AutoDriver index/target/desired
  keys as actor evidence only, not as checker success;
- current van contact bodies/count **only if already exposed** by existing
  contact monitoring. Do not enable monitoring or alter max contacts. Otherwise
  mark body impulses/contact ownership NOT MEASURED. Wheel contact/ray proximity
  alone cannot prove a swimmer pushed the chassis.

Manifest: game/test SHA and hashes, engine build/physics settings, RNG seed
information if available (do not seed/reseed the game), transforms/collider
dimensions, physics/process priorities, configured factors, field dependencies,
run plan/IDs, machine timings and observer duration distribution. Same recorder
and flush policy in every arm. Flush <=0.5 wall seconds and at events, not an
open/write/close per wheel. Record max gaps/row loss. No model inside play loop.

Events: setup boundaries, slow/retry begin, reset placement discontinuity and
failing-end, handbrake changes with last input request, first pedal/steer
consumption evidence, z=1 release gate, last supported wheel row, first all-off
row, game's lip log, first far-bank contact, jumped/miss transition, result.
Keep adjacent before/after rows. Engine lip magnitude is not necessarily the
last wheel-supported launch speed; report both.

Euler dispute: inspect and record actual `rotation_order` and the source call
used by today's test (`global_transform.basis.get_euler()` with its default).
State its resolved order from local engine metadata/docs if available; otherwise
ORDER NOT VERIFIED. No internet or material outside MPG_dev needed. Report raw
basis and yaw-independent forward elevation `atan2(f.y, length(f.xz))`,
f = normalised -basis.z, plus basis.up dot world.up and body-axis angular
velocity. At setup, verify these from the measured basis (including a pure-yaw
math check in test code). Today's Euler maxima are descriptive only; never use
world Euler x/z maxima as causal body pitch/roll thresholds.

## What is a mechanism seen, and who is blamed?

Use an event-aligned comparison sheet per pair: setup -> input receipt ->
consumed force/steering -> wheel support/launch velocity -> trajectory -> result.
Report raw differences and time order, with referenced rows. At ~66.5 km/h
compare components/attitude/contact history, not rounded scalar equality.

To name a causal mechanism require all of:

1. The sole assigned intervention and actual exposure are recorded. Other
   initial differences are listed, never hidden by a “matched” label.
2. A temporally prior mediator changes as predicted by the inspected code:
   e.g. delayed raw/device steering consumption followed by steering/side-wheel
   support change; or brake release followed by measurable rolling before
   throttle, shortened remaining run-up and lower acceleration history.
3. That mediator connects physically to the observed outcome in the trace:
   e.g. loss of one side's ramp support before roll/vertical-velocity divergence,
   then a geometrical shortfall; not simply larger roll after water contact.
4. The control/intervention records distinguish that chain from recorded
   alternative explanations. State what remains confounded. A two-arm result
   supports a local explanation, not a statistical reliability claim.

A full mechanism may explain one attempt even when no arm flips its outcome;
say exactly that. A flipped landing without the chain is INCONCLUSIVE. Both
fail, both pass, another driver passes, matching scalar lip speeds, a story
flag, or actor “done” never assign ownership. TEST is warranted by measured
transport/observer failure or recorded test action causing the invalid path;
GAME only by recorded game behavior violating its stated contract independently
of test setup/input error. Otherwise ownership UNRESOLVED.

For the historical 57.1 retry: distinguish reset-to-release rolling, initial
run-up length, brake/force overlap, steering/support loss and other contact.
Report actual achieved speeds in every arm. If no ~57 retry reproduces, the
historical cause is NOT PROVEN even if another low-speed mechanism is seen.

No new pass/fail thresholds on engine magnitudes. Report numeric differences
as measurements. Geometry tests use actual collider/ramp transforms; near-edge
cases with insufficient contact evidence are ambiguous, not invented margins.
If implementation needs a new numeric classification, first measure its clean
range in B1–B3, document the rule and its evidence before pairs, or omit that
classification. Never tune a threshold to make an intervention win.

## Health, qualification and failure modes

Host wrapper watches logs/recorder/c1 every second; builder watches progress,
motion and errors every 3–5 s. Any SCRIPT ERROR in current-run logs, invalid
required field, missing trace/manifest/event or failed output write vetoes
PASS and says TEST/OBSERVATION INVALID. Preflight dependencies by name AND type.
Separate trigger evaluated/absent from failed observation. Missing planned arm
or required checkpoint is INCOMPLETE, never neutral NOT REACHED.

Every await/phase gets a monotonic wall deadline published before entering it.
Use the existing 40 s drive and 6 s reset budgets as inherited trial budgets,
not engine invariants; report when they are inadequate. Screenshot deadline
5 s, short setup wait <=10 s, whole episode 200 s. These are **operational cost
ceilings**, not claims about physics. Host notices a missed deadline within
one polling interval; game callbacks cannot renew it. Recorder heartbeat alone
does not reset step deadlines. On expired work: TEST STALL/ownership unresolved,
retain evidence, stop safely, verify process exit; failed kill is explicit.
Stills at launch/result are nonblocking/bounded; failure to draw cannot strand
the driver or conceal a step stall. R9: stills plus traces suffice; no video cost.

Qualification means the instrument and comparisons work, not that every jump
lands or a cause is found. Required, inside the hour:

- Three baseline episodes and all selected arms have distinct run IDs, archived
  outputs, expected begin/end events or an explicit non-pass. Claimed complete
  qualification requires all three pairs and the swimmer pair. Honest causal
  INCONCLUSIVE is allowed; lost/missing records are not successful qualification.
- Review at least launch/result stills and event slices of every gameplay
  episode. If an angle is useless, say visual evidence unavailable; do not buy
  repeated full runs. Produce per-arm speed/offset/components/result/cost table.
- Short stale-read control removes a REQUIRED recorder lookup in test code:
  report TEST before drive, never NOT REACHED/green. Do not rename a game field.
- Short live-step control deliberately awaits an unfulfilled test signal while
  physics/recorder keep ticking. Give that step a 5 s operational deadline;
  host must flag it <=6 s and verify exit. This directly exercises c1's new hole.
- Short completion control returns before its declared checkpoint; host must
  flag missing work at completion, never PASS. Checker must not inspect the
  injection switch; it reads deadlines, logs and actual checkpoint receipts.
- Reused S3/S4 labelled via c1, additions labelled local; one negative's success
  cannot qualify another. Failed clean instrumentation follows R11: stop and
  report partial, no expensive scoring by builder.

Failure modes to include in report: rare miss not reproduced; uncontrolled
solver/RNG/frame-pacing variation; recorder overhead; paired initial states
different; sampling phase aliasing or stale wheel contacts; key dispatch not
consumed when assumed; landing mutates wheel/cargo before late sample; no body
impulses to explain swimmer drift; private-field coupling; bounded screenshot
loss; c1 failed termination. None licenses game fixes or invented causal labels.

Output `trial_g2.md`: exact source/file reuse, all departures, build and run
minutes, the complete arm table including excluded/failed arms, per-tick/event
artifact paths, qualification controls/detection seconds, R5 claim/NOT PROVEN,
each question's MECHANISM SEEN or INCONCLUSIVE with row references and alternatives.
Archive each run under a unique MPG_dev/appdata path before another overwrites
runner logs. Keep final reader summary short; raw traces carry the detail.
