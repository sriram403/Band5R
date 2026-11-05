# GPT audit: Stage 2, round 2

2026-11-05. Proposal v3; v1 and v2 remain in `ideas_gpt.md` and
`audit_r1_gpt.md`. No game or test run. No game/test code written.
Only this file is changed by this audit. Paths below are relative to MPG_dev.
I did not open `audit_r2_claude.md` or seek secret test material.

## Decision

Accept Claude's allocation: **c1 health; g1 sensed input actor with independent
checker; c2 C3 invariants; g2 controlled causal comparisons.**

Withdraw G6+C6 as a standalone trial. R3 removes its operator. Reusing g1 makes
it runnable only over g1's limited coverage, not the hut. Keep recording and
cited evidence as obligations in all trials, not an extra claimed method.
This is a change from my round 1, caused by R3 and R5, not a measured victory
for C3's accuracy. No trial scores exist (`scoreboard.md:99-104`).

I apply the two requested skills read-only: testing-and-verification v8
(separate command/effect, retain failures, prove real paths) and
first-principles-solving v6 (delete unavailable dependencies, measure the
smallest claim, preserve versions). The task's one-file limit overrides their
normal instructions to update other notes. Nothing is written to the libraries.

## Answers to Claude's attacks

Claude's numbered idea sections in `audit_r1_claude.md` identify the attacks.
These answers cover the common layer and every G1-G7 objection.

| Target / attack | Concede or rebut, and evidence |
|---|---|
| G0: S3/S4 credited to every idea | **Concede.** R1 explicitly charges and qualifies shared parts once. Later trials say “via c1”, with control IDs; none earns independent 3/3 or 4/4 predictions. |
| G0: supervisor inside every one-hour estimate | **Concede the estimate.** R1 removes the duplicate build, not the initial cost. Both earlier build estimates were guesses. c1 must qualify its own controls before reuse. |
| G0: pause event can precede reason | **Concede the race.** `Boot.gd:276-277` toggles pause before setting `pause_note`. Record the completed device-change event and next observer sample. Do not label a game defect on the intermediate pause notification. |
| G0: legitimate stationary work | **Agree with the condition, not a global ten-second movement rule.** The reset waits 1.8 + 0.6 seconds (`RampJump.gd:605,631`); refit holds E for seven (`PlayTest.gd:11916`). Health and action progress need separate deadlines. |
| G1: full route in 3-6 hours | **Withdraw that estimate as unsupported.** `ROUGH_NOTES.md:716` records 15+ failed bot rounds in about 1.5 hours; `:731` records crate-drop spread 0.85-1.26 m. These do not prove “days”, but disprove confidence in my budget. No hut actor in this trial. |
| G1: a weak actor creates false alarms | **Concede the risk.** The measured baseline misses at 66.5 km/h (`scoreboard.md:95`). A healthy input transport does not establish competent steering. Unexplained failure remains unsuccessful and unresolved, never automatic GAME. |
| G1: planner avoids P4; forced point predicts coordinates | **Concede the avoidance hole. Rebut the blanket ban on targets.** S5 bans mutations, not geometry-relative goals (`scoreboard.md`, S5). Actual intended placement plus actual leg-up is different from placing the crate by code. Neither is built here; P4 is not caught by g1. |
| G1: failure means game unless inputs/contact measured | **Agree.** `Camper.gd:1013-1017` separates device values from steering/brake consequences. Preserve both, plus physical motion. Even correct readback leaves policy and oracle errors possible. |
| G2: no demonstration; varied replay grows into controller | **Drop.** R3 makes the human source unavailable. Existing slow tries vary 0.17-0.22 m (`appdata/ramp.out:26,44,64,84`); correction robust enough for new landings is unbuilt. Not a theorem that all replay fails S1; sufficient reason not to allocate a trial now. |
| G3: search costs real walking, avoids intended defects, incomplete frontier | **Drop.** P2/P4 are specific blocked affordances, not mere inability to finish (`scoreboard.md:60,62`). A workaround cannot clear them. No measured build/runtime benefit offsets my original 4-8 hour estimate. An incomplete search never passes. |
| G4: two pairs can explain noise; unlisted causes; P3 confound | **Concede and retain.** Flat-out launches repeat at 66.2 / 1.00 four times, slow ones differ (`ramp.out:26-96`). Neither establishes repeatability for B0. Brake-on P3 drift is 0.57 m versus clean 0.04 m (`scoreboard.md:59,67-68`); drift alone cannot name P1. Repeat the original case first; preserve disagreements and unknown causes. |
| G4: P2/P4 static checks name them “for free” | **Rebut “free” and complete naming.** C3 itself estimated 2-3 build hours (`ideas_claude.md`, Idea 3, Cost). A capsule query is evidence about geometry, not actual player traversal. Naming requires validating that proxy. It can still be a cheaper candidate than an actor for those objects. |
| G5: pixels fix the wrong defect | **Drop the trial; qualify the reason.** One-way index and full-key steering are visible in `PlayTest.gd:7484-7508`; they deserve the first experiment. That does not prove obstacle sensing is irrelevant: the brief records a tree collision. My 6-12 hour estimate and no qualified visual controller are enough to drop it, without asserting pixels cannot help. |
| G6: operator unavailable; bypasses; visual judge cost/accuracy | **Concede dependency and bypass risk.** R3 rules out a person; P2/P4 remain defects even if bypassed. Judge accuracy and token estimates are unmeasured (`ideas_claude.md`, Idea 6, Cost). Withdraw the trial, not the need to inspect recorded evidence. |
| G7: fitted van model learns around P1 | **Concede the risk; drop.** P1 changes reset drift from 0.04 to 3.79 m (`scoreboard.md:59`). Adapting throttle to it could hide that defect. This is a possible failure mechanism, not evidence that an unbuilt planner actually did it. No measured advantage earns its estimated 6-10 hour build. |

## Further fact checks of Claude round 1

1. **Euler angles: partly concede, keep the frame warning.** The call is
   `global_transform.basis.get_euler()` (`PlayTest.gd:11599-11600`), with no
   ramp-relative basis. There is no engine implementation/API definition of the
   default order in the local material I found. **I think** YXZ is the default;
   I cannot promote that API detail to verified fact without outside material
   or executing the engine, both outside this audit's scope.
   Conditional on YXZ, the algebra is clear: for B = Ry(yaw) Rx(pitch) Rz(roll),
   an extra world yaw changes yaw alone on the ordinary nonsingular branch.
   My suggestion that changing heading necessarily corrupts x/z was too broad.
   These remain Euler components relative to world vertical, not general
   ramp/deck-relative tilt or chassis-axis angular rates. Keep the raw basis,
   ramp-relative basis and angular velocity. Never diagnose B0 from these
   maxima: `:11598-11601` accumulates them during the fall too.

2. **Four repeated successes are real but not baseline controls.**
   `ramp.out:38,58,76,96` all report 66.2 km/h and 1.00 m offset. However,
   `t_ramp_retry` places P2 before the miss and again after reset
   (`PlayTest.gd:12092,12096`); baseline seats P2 before its miss and does not
   restage after it (`:11715-11724`). The four successes cannot establish B0's
   cause, or qualify S5 for the intervening P2 route. Claude's statement that
   C3 can ride “today's t_ramp” because retry landed 4/4 is too strong.
   `scoreboard.md:95` says baseline returns before the hut.

3. **“0.84 m past” is detector position, not touchdown.** Agree after reading
   `RampJump.gd:353-358,392`: airborne first, then contact beyond the centre
   threshold. The log does not retain the first physical touchdown point.
   My checker must record first regained support independently.

4. **Expression-error outcome remains unmeasured.**
   `LiveControl.gd:129-136` returns strings on parse/execute failure. Neither
   Claude's crash hypothesis nor a truthy-string hypothesis is a finding.
   c1's T2 must preserve the actual result. R6 settles sequential unwatched
   expects; no further argument there.

5. **C3 does not get S5 merely because its observer moves nobody.** Its
   producer may still stage the state. The existing helper writes transform,
   velocities, seat and parking brake (`PlayTest.gd:11555-11573`), and even
   `ramp_try` writes parking brake (`:11585`). Declare these before a boundary,
   or remove them within the claim. An observer-only camera is allowed by R2;
   player visibility still requires a reached player view.

6. **A motion invariant does not name the handbrake.** The reset explicitly
   sets brake and swimming state (`RampJump.gd:617-628`). The scoreboard's
   brake-on P3 drift defeats “drift => P1”. Keep separate findings for brake
   state, swimmer state, contact and motion. “Swimmer nudged van” remains
   unmeasured (`scoreboard.md:67-68`).

## Disputed slot, judged in scoreboard order

| Order | C3 versus revised G6+C6 |
|---|---|
| S5 gate | Neither gets a free pass. C3 must name its producer and boundaries; G6 must reuse an audited input actor. R2 permits inert evidence cameras for either, not staged player proof. |
| S4 gate | Neither alone notices every frozen run. Both need qualified c1 under R1. A missing observation/phase cannot mean no invariant failed or no visual defect. |
| S1-S3 | Neither has measured scores. C3 has precise public targets for P4-P7, but proxy/debounce risks. Revised G6 observes only what g1 reaches. It cannot now claim the hut coverage that motivated my round-1 pick. S3 is via c1 for both. |
| S6 | C3 has no per-run model decision loop. Its runtime is not literally free; measure it. Visual review token/accuracy numbers are estimates. With G6's former coverage advantage removed, I think C3 is the stronger one-hour experiment. |

Thus **c2 = C3**. This is not a merge of unlike methods. Evidence capture stays
common; a separate blind visual oracle remains a reserve. A visual judge might
win on S2 before cost matters. We have no measurements showing that yet.

## Why GPT runs the causal comparisons

**g2 = C2+G4, built by Opus to the specification below.** Claude already proposed
this allocation (`audit_r1_claude.md`, section 5). Both audits independently
identify the same mechanism and agree that all-fail is inconclusive. I accept
because it preserves c1 first, lets c2 build its distinct observer after g1,
and gives g2 already qualified health and launch measurements to reuse under
R1. This is an allocation reason, not a claim that GPT is a better implementer.
The builder writes all code; GPT audits it, as the binding brief requires.

## Final four and build contracts

All build times below mean **I think**, not measured forecasts. Each trial gets
about 60 minutes including its own qualification. R4 puts subsequent referee
scoring outside that hour; my round-1 insistence on fitting all ten runs and
mutants inside it is withdrawn. Record wall time, build minutes, qualification
time, scoring time, model tokens/seconds and reviewer attention separately.
No model chooses inputs between play steps.

Each report gives per-obligation PASS / GAME DEFECT / TEST PROBLEM / UNRESOLVED
and NOT PROVEN coverage. Unresolved is not successful S1 evidence. Retain first
failures; no retries erase them. Record video and frame-associated telemetry;
at failure retain the offending frame/state before stopping. No whole-game run.

### c1 — Claude: health and requested-work accounting (C1 + G0)

**Smallest build:** host manifest of exact IDs; one-second always-processing
records of run/scene identity, timestamp, pause/reason, players/devices and an
ordinary unpaused world-physics counter; outside poll every two seconds.
Ten seconds stale counter/record, missing player or unexpected pause must be
reported within twelve seconds. A scenario must start within ten seconds of
its scheduled dispatch or be marked missing. Scene reload never erases host
obligations. Resolve types/nodes before use; expression errors are test errors.
Reject scenarios after save, or explicitly report them skipped.

40 minutes build, 20 qualify stale/frozen progress, pad disconnect, missing P2,
bad lookup and skipped manifest ID. Untested controls remain unqualified.
Use an existing driving prefix; inventory its helper mutations and put the
boundary after setup. Do not spend the hour instrumenting every setter in the
game. Source audit supplements the mutation record; a SET counter alone cannot
detect uninstrumented writes.

**Claim:** execution health and exact requested/completed accounting during
that prefix. S3/S4 measured directly. **NOT PROVEN:** driving competence,
physical landing, hut, repair, departure, visual correctness. A healthy rig
cannot confer a gameplay PASS.

### g1 — GPT/Opus: sensed driving, independently checked (G1 + C5)

**Two separate stretches, not an end-to-end ramp route.** A: declared fresh
approach to supported far-bank arrival and safe stop. B: declared repaired,
parked far-bank setup to outgoing-road departure and stop. The setup gap
between A and B is not proven. If both do not become runnable within the hour,
report partial build and failure against this declared two-stretch scope.

Builder contract; do not add hut skills or recovery search:

1. Reuse c1 only after its controls pass. Keep the old actor as a selectable
   comparison, not as the judge. All transforms, seating, repair, story and
   initial engine state are setup before each boundary. Release all inputs.
   Beyond it use `PlayTest.key`/normal device events only. No debug throttle,
   debug steer, direct brake setters, velocity or camera writes. In particular
   do not reuse `ramp_try`'s direct brake setter inside the stretch.
2. Each physics tick reacquire the nearest road segment. Forward look-ahead
   is 8 m + 0.4 seconds of actual speed, measured along the road, with lane
   offset relative to that road. Desired normalized steering is heading error
   divided by 0.35 rad, clamped to [-1,1]. Implement with A/D pulse duty over
   six physics ticks; recalculate each period; never press both. These are
   fixed controller choices, not acceptance gates or proven optimal values.
3. One pedal owner. W below requested speed minus 1 km/h; S above it plus
   1 km/h; neither inside the band. Never both. Log actual achieved lip speed;
   an 80 km/h request means full throttle capability, not an achieved speed.
   Do not lock steering straight as part of this trial; that is g2's factor.
4. Sweep the current chassis collision shape two seconds of travel ahead
   horizontally, excluding self and driveable support. A non-support obstacle
   commands brake to rest and reports blocked with collider ID. No automatic
   reverse or retry in the smallest version. If a reliable sweep cannot be
   built within the cap, report the missing component, not a weaker green.
5. Independent per-physics-tick recorder: requested keys, device values,
   engine force/brake/steering, parking brake, full pose/basis, linear/angular
   velocity in world and ramp frames, wheel contact identities, player/seat
   IDs and detector/reset transitions. The actor's done flag is never proof.
6. A must show approach motion, loss of support over the gap, then actual
   support on far-bank solid ground beyond the far edge. Require positive
   forward displacement after support, then input braking to speed below
   0.2 m/s for two seconds. Compare `jumped` separately; detector/physics
   disagreement fails with cause unresolved. Both players remain aboard.
7. B requires a refitted wheel at its declared start, both aboard, 30 m
   signed outgoing-road progress, chassis centre inside the road corridor
   for the final three moving seconds, then input braking to below 0.2 m/s
   for two seconds. Closest-ever road distance and distance-from-origin are
   insufficient (`PlayTest.gd:11931-11932,12019`). Stop and retain failure on
   ten seconds without route progress while commanded to move. Each stretch
   has a 60-second deadline, including stopping. c1 handles freeze/pause.
8. Reuse existing ordinary handbrake input if needed at rest; confirm its
   device mapping from source. `Camper.gd:1016-1017` exposes the normal path.
   No direct setter fallback. If the input route is unavailable, report it.

40 minutes build, 20 qualify one A and one B, plus a negative checker control
where the actor says done without departure. Referee later varies speed and
lane/approach under S1. Use safe initial lanes -0.5, 0, +0.5 m; report achieved
speed spread over 61-68 and distinct actual landings, not just requested values.
If 68 cannot be achieved, report S1 coverage shortfall; do not alter physics.

**Claim:** those two driving stretches only. **NOT PROVEN:** their connection,
miss recovery/P1/P3, hut access, crate, leg-up, refit process, wreck visibility,
hub appearance or HUD correctness. Thus no P1-P7 caught/named credit is promised.
Qualification and later scores decide whether the new driver improves S1.

### c2 — Claude: bounded invariant observer (C3)

**Smallest build:** read-only observer after world build and at 5 Hz over g1's
A stretch. Static checks: declared crate placement volume against non-support
solids; wreck rendered bounds versus water level. After real landing/settle:
bare-hub rendered bounds versus actual support surface; actual HUD label versus
wheel-off state. Give object IDs, raw measurements and synchronized frames.
Use a one-second stable-state window before declaring a dynamic violation;
preserve all transient samples. Author generic and puzzle-specific rules in
separate lists. No game-object repair or state mutation by the observer.

40 minutes build, 20 qualify clean samples and deliberately broken observer
inputs/one applicable public defect. The referee supplies later patches. If g1
is unavailable, a declared landing setup may qualify the observer only; it
earns no driving or naturally reached landing claim. R1 still applies.

**Claim:** static crate-space/wreck geometry and reached post-landing hub/HUD
consistency; candidates P4-P7, not advance catches. R2 observer closeups are
allowed, with no actor access. **NOT PROVEN:** player-visible wreck, readable
views, actual crate placement/leg-up, door traversal/P2, miss reset/P1/P3,
repair or whole-route completion. A capsule door probe may be deferred; its
absence is explicit, not silently replaced by a claimed traversal. These cuts
replace Claude's seven-rule, 2-3 hour version with an honest hour experiment.

### g2 — GPT/Opus: repeated, bounded causal comparisons (C2 + G4)

**Smallest build:** diagnose the baseline miss and separate post-reset brake
and swim defects. Reuse qualified c1 and g1 measurement/checker components;
no new navigation. Keep the original AutoDriver policy selectable, with its
direct parking-brake setter removed from the proven interval. Ordinary W
releases the brake through game logic (`Camper.gd:1077-1078`).

Exact requested experiment IDs, fixed before running:

| IDs | Setup before boundary | Inputs and measured interval |
|---|---|---|
| B0a, B0b, B0c | Baseline-equivalent fresh game, both seated, same rack can as baseline | Original policy at target 48; real miss and game reset; neutral 0.3 s; original policy at target 80 until support/miss. No restaging between attempts. |
| Fa, Fb, Fc | Same declared players, can and fresh approach as B0 | Original policy at target 80 directly, until support/miss. |
| Sa, Sb, Sc | Same predecessor and initial setup as B0 | Same 48/miss/reset/0.3 s, then target 80; only change: release A/D at entry to the last 30 m before lip and hold them released through landing/miss. |
| D-dry, D-wet | Same van/P1/cargo setup; P2 left outside. Initial P2 position is respectively dry bank or river near bank. Wait before boundary until the game's own physics confirms dry/non-swimming or water/swimming. Never set swimming directly. | Original policy target 48, real miss/reset; then all inputs neutral for five seconds. Record P2 support/water/swim state, van brake, drift and contacts. |

Setup positions may be staged only before each declared boundary. The P2
journey into the water is NOT PROVEN. In D, P1 drives the real miss and the
game alone relocates players/resets the van. Do not copy `t_ramp_retry`'s
post-reset `place_player` (`PlayTest.gd:12096`). No teleport/camera/state write
within an experiment. A game-authored tow/reset is the behavior being tested,
not a forbidden test teleport.

Run B0 repeats first. If their outcome disagrees, label repeatability unresolved;
do not multiply retries. Complete the fixed table once if health permits.
Within each experiment, retain the first failure and allow only the explicitly
planned game reset; health failures stop the experiment immediately. Each try
has a 40-second action deadline, reset six seconds, total experiment at most
100 seconds. Manifest/deadline controls remain active during allowed fades.

Record each start, last supported launch sample, first airborne sample,
first regained support and reset completion. Use g1 telemetry plus can/seat
identity, temperature, coolant, fuel, damage and wheel state. Report all raw
differences between fresh and reset starts; fresh-versus-reset is a bundled
state intervention, not an isolated cause. B0 versus S isolates a commanded
steering policy only if its predecessor traces agree; even then a passing S
does not automatically make B0 a test bug. Different valid trajectories can
expose real defects. Save snapshots are not assumed to capture full physics.

Report rules, with no builder-added hypotheses:

- Missing/rejected command or bad probe: TEST PROBLEM with exact evidence.
- Reset brake off plus no-input drift: report broken reset brake, separately
  from any swim violation. The intended brake is explicit in
  `RampJump.gd:617-619` and measured P1 control in `scoreboard.md:59`.
- Player remains swimming on dry supported ground for over one second after
  reset: report stale swimming state. Brake-on drift does not become P1.
  D-dry/D-wet outcome differences do not prove physical nudging without contacts.
- Any missed attempt stays recorded. Differences across B0/F/S are associations
  with the stated interventions; name a narrower cause only when the retained
  input/contact trace demonstrates it. All fail, unmatched predecessors or
  contradictory repeats: UNRESOLVED, never automatic GAME or PASS.
- Healthy clean cases with expected reset and supported landing can pass their
  own obligations. A diagnosis table alone cannot green a failed route.

35 minutes build, 25 qualification: one B0 and both D conditions first. The
full fixed table is the runnable deliverable for referee scoring, not a demand
to fit all scoring into qualification. If any required mode is unbuildable in
the hour, report that failure, not an invented shortcut. No online model loop.

**Claim:** controlled attempt/reset observations and bounded evidence for B0,
P1 and P3 naming. **NOT PROVEN:** swimmer's real journey before setup, P2/P4-P7,
hut, repair, departure, a complete causal explanation of every miss or physics
repeatability in other puzzles. All outside practice defects count not caught.

## Remaining disagreement and deciding measurements

There is now **no disagreement in my proposed method allocation**. I still
reject unearned claims, including my own earlier estimates.

| Open issue | Measurement that settles it |
|---|---|
| C3 versus visual judge accuracy | Same reached states, clean and public-mutant evidence with labels hidden; separate false alarms, caught and named counts, unseen states, tokens and wall time. Do not commission an extra trial now. Final secret/S7 scores test generality. |
| C3 door/placement proxies count as player proof | Actual input-only walk/drop/climb with contact and reached views, compared with the proxy. Until then only geometry is proven. |
| Sensed driver fits hour and improves working-game reliability | Build/qualification minutes, both declared stretches runnable, then ten varied clean runs with achieved speed/landing records. No “days” or “one hour” claim is a measurement. |
| B0 cause and repeatability | Fixed g2 table, original failures retained; predecessor/launch/contact samples and outcome disagreements. Neither total lip speed nor Euler maxima decides it. |
| String conversion and YXZ default | c1's bad-expression control; a later allowed engine/API check for default order. Neither is run here. Basis-based measurements avoid dependence on the Euler default meanwhile. |

Final proposal: c1 health, g1 sensed driving, c2 bounded invariants, g2 causal
comparisons. Scores remain blank until the referee measures them.
