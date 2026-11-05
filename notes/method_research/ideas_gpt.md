# GPT auditor: seven independent proposals

Stage 1, version 1, 2026-11-05. Author: GPT auditor. No other auditor's ideas or audits read. No game or test run. No game or test code written. Only this document changed. These are proposals for the Opus builder, not measured results.

## The core and the evidence

Prove that two players can finish the stretch through real controls, despite different arrivals. Spend time on failures, rather than model thinking between successful button presses. That cost is explicit in `notes/TESTING_METHOD.md:13-20` and its v3 account at line 39. A controller succeeding is not sufficient: the checker must also notice broken controls, missing work and wrong pictures.

I read the brief, scoreboard, listed project facts and code, the named Theo transcript, and the two requested skills. I apply testing-and-verification v8's distinctions between requested input, readback and physical effect, and first-principles-solving v6's rule that an unexplained result remains a question. No skill library changes. The special Stage 1 write restriction takes precedence over the usual instruction to update other notes.

### Source keys used below

Paths are relative to this project unless an outside source is explicitly named. A range identifies the inspected block, not a measured experiment.

| Key | Evidence |
|---|---|
| B | `notes/TEST_METHOD_RESEARCH.md:29-45`: nine failures and the real bugs. `notes/method_research/scoreboard.md:39-64`: P1-P7, T1-T3, N1-N4. |
| J | `FindingNaresh/scripts/puzzles/RampJump.gd:331-370`: launch, landing and failure detection. |
| R | Same file, `585-640`: miss reset, velocity zeroing, handbrake and clearing swimming. |
| D | `FindingNaresh/scripts/dev/PlayTest.gd:7475-7529`: AutoDriver. Nearest road index only advances; steering is left/neutral/right. It has no obstacle sensor in this block. This makes circling plausible, not proven. |
| A | Same file, `11555-11619`: start resets, repairs, positions and seats; try uses AutoDriver and releases it near the lip. Roll/pitch are maxima once local z < 2. |
| T | Same file, `11668-11933`: ramp scenario. Teleports and direct camera aiming occur throughout; wheel repositioning at `11884-11886`. Early return after jump failure at `11727-11728`. |
| O | Same file, `11924-11932`, `12004-12035`: drive-off checks distance and closest approach. `ramp_closest_to_road` has one initializer and is reduced, with no reset in the drive helper. |
| L | `FindingNaresh/scripts/dev/LiveControl.gd:129-136`: expression errors returned as strings. `187-199`, `485-501`, `544-550`: results converted to bool. `521-584`: watcher waits on game time, checks stuck van and Naresh; no independent process watchdog here. |
| C | `tools/live.py:60`, `80`, `114-154`: client timeout 180 s, at least 3600 s for walks; error scanning and replies, no fresh-heartbeat deadline in that loop. |
| Q | `tools/run_test.sh:85-116`: timeout defaults to 3600 s; completed-scenario count reported, but final success checks failures/problems, not requested IDs against completed IDs. |
| W | `tools/live/make_ramp.py:69-145`: fixed placements and direct looks; negative leg-up check at `106-109`; final expect at `144` checks wheel/story, not driving away. |
| P | `FindingNaresh/scripts/core/Boot.gd:262-277`: pad disconnection correctly changes layout and pauses. |
| H | `notes/TEST_PUZZLES.md:322-354`: intended player route and mistakes. `design/PUZZLE_CHANGES.md:1563` onward: approved ramp, physical jump, deliberately scripted wheel flight. |
| F | `appdata/playtest/runs/seg_1.log`: 46.8 km/h slow miss; 66.5 km/h, 1.05 m offset, flat-out miss; no post-jump work. Also scoreboard baseline at `scoreboard.md:74`. |

Theo's transcript is the single explicitly allowed C: attachment named in the brief, line 1 (one long line). It suggests verifiable rewards, private cases, planted errors and a separate visual judge; it also reports chasing a skybox. These are inspiration, not evidence that any method below works in Godot. No external research or unseen secret-case material was used.

### Baseline: what is and is not known

- F is a failed attempt, not proof of a broken jump. The user's successful play does not prove every approach works either.
- J measures `last_lip_kmh` at the first detected airborne sample beyond local z = -0.5. It is total velocity magnitude. It is not forward speed at first ramp contact, vertical takeoff velocity, or heading.
- A's 14.5 degrees is maximum roll during part of the attempt, not measured launch roll. Its Euler angles are in the world frame. Do not silently treat them as ramp-relative angles.
- The second try follows the game's reset, not `ramp_start()` (T `11719-11724`). Whether this matters is unknown. A different result after forcibly resetting would not by itself establish blame.
- O can accept a van that once touched the road and then circled. It also appears able to retain an earlier call's closest approach. Both are code facts about the check; neither was exercised in this stage.
- L returns error strings to callers that expect booleans. Whether a particular string becomes a false pass must be tested. Error return and boolean conversion already show why typed validity is needed.

## Common minimum for all seven candidates

This is required bookkeeping, not seven copies of one controller. The seven differ in who plays, what they sense, or how they judge. Each includes this minimum in its cost estimate.

1. **External supervisor, independent of game physics.** A small host process checks every 2 s. A test-only observer emits a flushed record every second with run ID, scene generation, physics tick, pause state, player IDs/device assignments, scenario ID and current action. Missing fresh records for 10 s means `RUN INVALID: engine/observer stopped`, not `game bug`. A frozen physics counter with a live observer also stops the run. A fresh heartbeat without progress cannot satisfy an action.
2. **Do not depend on the command coroutine for health.** The observer must run while paused; if the whole process stalls the host notices. Record pad-change events. T1 plus P means `test problem: disconnected P2; correct game pause`. N2 without that cause means `paused; cause unproven`, not invented blame. N3 is checked at setup and on every health record. Missing evidence is never a pass.
3. **Manifest of work.** Before launch, host stores immutable requested scenario IDs and sub-obligations, with run ID. Observer sends start/end records. Scene reload does not erase the host ledger. At reload/end compare exact requested/completed IDs, not just a count. T3 and N4 are reported at reload/end or within 10 s of loss of the old scene. No summary can turn unfinished work green.
4. **Only real inputs after the declared boundary.** Setup may use the F1 puzzle menu. Then record keyboard, mouse and pad input. No `place_player`, `look_at_point`, `face_point`, item handovers, direct repair, save restoration or `ramp_start` during the proven stretch. Normal game towing/reset is allowed and labelled as game behavior. Camera turns must use mouse/pad deltas. Test observation cameras, if used for diagnosis, never steer a player and cannot substitute for a required player view.
5. **A typed observation is either valid or invalid.** Missing nodes, bad fields, expression parse/execute errors and wrong types are `test problem`, before any pass check. No free-form live expressions in a scored run; if a candidate uses them for configuration, resolve and validate them before playing and on each scene generation. This is a build requirement, not a claim that existing L does it.
6. **Stop safely, preserve first.** Keep a rolling 10 s trace/video buffer. Save the offending sample before stopping. Release controls and brake a moving van through real input; verify rest when possible. If engine is unresponsive, terminate the run and retain evidence. Do not claim a safe stop when frozen.

The proposed 10 s health limit is a choice to test, not measured performance. Host polls during build/load too, with a separately declared 60 s startup deadline. Active actions have progress checks every 2 s; 10 s of no relevant progress is invalid/inconclusive unless a declared timed action explains it. A holding action must show the correct actor, input and expected response; moving in circles is no progress. A non-moving interaction may have its own shorter/longer deadline but never disables health checks.

Verdicts: **pass**, **game defect demonstrated**, **test defect demonstrated**, **inconclusive**. A timeout is not causal proof. Inconclusive is unsuccessful for S1/S2/S3 as applicable; it cannot be used to wash away failures. Report caught/named separately. Record the first failure even if a later attempt succeeds. Any diagnostic retry is a separate run, not a replacement score.

For every method, the referee must run the full public practice set and test-breakers. Private checks remain with the referee, outside builder access. The builder gets only a stable observation/input interface. It cannot alter the judge or weaken deadlines to improve a score. This implements Theo's warning without pretending privacy guarantees correctness.

## 1. Measured skills with a separate contract checker

**Mechanism.** An in-engine test actor chooses from small skills every physics frame. A separate host checker judges their observable consequences. High-level goals are H's sequence, not fixed coordinates or seconds. The actor can read physical transforms, collision queries and current prompts, but cannot call puzzle success functions. The checker does not accept the actor's `done` value.

Builder specification:

- Driving: derive a local corridor from actual road/ramp geometry. Use chassis-width swept queries ahead, forward and lateral velocity, heading error, wheel contact and angular velocity. Apply proportional steering through A/D or existing input actions; one owner per pedal. Brake/reverse on a blocked sweep. Reacquire the nearest usable forward road segment after reversing; do not inherit D's one-way index. Check progress along the outgoing road, not distance from origin.
- Walking: sample free standing surfaces around the actual target, ray/sweep for collisions, turn the player by mouse/pad input, walk to a reachable interaction range. Replan on obstruction. No geometry mutation or target-facing transform setter.
- Interactions: turn by input until the player's ray hits the intended object and its prompt offers the action. Pick up, drop, crouch, jump, hold E and board through controls. Crate placement ends when the crate is supported under the window and the real leg-up becomes offered. Climb onto it through walking/jumping. This is the hardest unbuilt skill; no teleported shortcut.
- Checker: timestamp grounded launch, airborne crossing, supported far-bank arrival, wheel flight/shutter, both players on foot, actual unsuccessful leg-up attempt, successful crate leg-up, door traversal, carried wheel, refusal before nuts, toolbox, refit, and sustained forward road travel with both aboard. Require input-and-motion evidence for the negative leg-up attempt. Drive-off needs 30 m forward road progress, road occupancy for the last 3 s and a controlled stop; these are proposed acceptance values for referee review, not inferred game requirements.
- Add explicit observation tasks: walk to a legal view of wreck, hub and HUD. Use ground/water depth rays and mesh bounds as numeric warnings; retain player-view frames. Host judges those three views, initially by the separate reviewer described under cost. No view means unchecked, never green.

**Baseline diagnosis.** Log at physics tick resolution from 2 s before ramp contact to landing/reset: input intent/readback, transform in ramp frame, forward/lateral/vertical velocity, angular velocity, all wheel contacts, collision bodies, pause/reset and detector transitions. Show synchronized player video. This can demonstrate steering oscillation or unexpected side contact; it cannot infer either from 66.5 alone. If an unobstructed, aligned, stable takeoff physically reaches solid far ground but J fails to register it, name detection. If commanded turn differs from applied turn, name test transport. If both are valid and it falls short, report trajectory failure, cause unresolved until a controlled comparison. No invented angle gate may excuse the baseline.

**Evidence coverage — predictions only, all “I think”.**

| Evidence row | Verdict and reason |
|---|---|
| E1: eight takes / expression errors | Caught: typed preflight rejects bad names/expressions before recording. New skill bugs remain possible. |
| E2: varied parking / forward into tree | Partly: swept obstacle control adapts; if it still sticks, marks controller failure rather than assuming game fault. |
| E3: unplug, five failures, freeze | Caught: host observes P event and pause, stops further work. |
| E4: road reached, then circles | Caught: signed road progress and final occupancy fail; steering trace alone cannot prove root cause. |
| E5: passed video stuck at tree | Caught: repair flag cannot replace actual departure. |
| E6: leg-up passed without pad | Caught: device/actor checks plus a real jump must precede the negative result. |
| E7: six asked, four ran | Caught: immutable host manifest survives reload. |
| E8: frozen game, buffered watcher | Caught: separate heartbeat deadline and flushed host output. |
| E9: swimming wrongly blamed | Partly: shows swim state, motion and controls; refuses causal claim without intervention. |
| P1: downhill reset roll | Caught/named: stationary reset obligation checks real handbrake plus displacement before releasing it. |
| P2: door sill | Caught; named if contact shows sill during valid forward walking. Otherwise inconclusive blocked traversal. |
| P3: stale swimming | Caught/named: dry supported player still swimming after reset. Include left-behind miss scenario through input. |
| P4: rubble at crate | Partly: contact identifies rubble; planner might route round it and hide obstruction. Required intended window placement must still be attempted. |
| P5: wreck underwater | Partly: depth warning plus required player view; reviewer may miss or misjudge. |
| P6: hub below ground | Partly: mesh/ground check plus frame; wheel contact alone does not prove visible hub. |
| P7: PUNCTURE without wheel | Caught/named if captured HUD text is checked at wheel-off event; not from story flag. |
| Old piers in mid air | Not caught on g12: absent, excluded by scoreboard. Future support probe could check them, no present credit. |
| Fresh 66.5 / 1.05 / 14.5 miss | Partly: catches attempt and records launch/contact evidence; does not yet know game versus test. |

**Harsh criticism.** This can become a second game AI project. Geometry access grants knowledge a human lacks; S5 forbids state mutation, but does not establish human-like perception. Goal contracts may repeat game bugs. Clearance checks may cause false alarms on legal tight paths. A clever controller might avoid a broken route. Required route obligations counter that but introduce authored requirements. Visual review remains a weak link. Do not claim ten successes in advance.

**Cost, I think:** 45-60 min for jump, supervisor and departure prototype; 3-6 hours for complete co-op crate/repair route. Thus a complete Stage 3 build may fail the one-hour cap. Stop and report that, never call a jump-only prototype a full ramp pass. Full run 3-5 min plus 0.5-2 min visual review; 10 runs 35-70 min. No model thinking during play, zero loop tokens. At most one post-run evidence review, estimated 2k-6k tokens; human/user result reading 0.5-1 min. Those review times are guesses; measure actuals.

**Self-score:** S1 unknown, I think strongest automation candidate but 10/10 unearned. S2 I think P1/P3/P7 most direct; P2/P4 require causal contact evidence; P5/P6 need pictures. S3 I think 3/3 with common minimum. S4 I think 4/4, target 2-12 s. S5 intended pass, inspect all helper calls. S6 reported estimates above. S7 I think 1-3 hours for another puzzle's goals/skills; could be much worse.

## 2. Event-anchored playback of genuine two-player input

**Mechanism.** Record a successful real-input route once, including both actors' keys, pad axes and mouse deltas. The recording must include the sheet's miss and repair branches, not merely the user's already successful jump. Replay short input phrases, chosen and ended by observed events, instead of one timed movie. Between phrases use a bounded proportional alignment correction through inputs, relative to the current target's measured pose. No snap to the recorded position or camera.

Builder specification:

- Store source build, action stream, actor/device IDs, event anchors, local distances/headings and elapsed ticks. Anchors are such things as genuine airborne transition, supported landing, carrying crate, door crossing and wheel fitted. Use a typed observer; never key off a prompt alone.
- A phrase starts only when its preconditions are observed. Re-time walking by distance travelled, stop near the actual target, and turn via mouse/pad deltas until the observed interaction ray matches. The jump remains continuous control; no freeze while aligning in flight.
- Deviation from demonstrated conditions stops the attempt as `replay cannot follow`, not `game broken`. One bounded recovery of at most 5 s may be part of a declared phrase; preserve its deviation. Anything more needs a new demonstration, not silent model rescue.
- Judge the H obligations with independent physical events and the required wreck/hub/HUD views, as in #1. Departure must remain on the road and make progress. Negative leg-up needs a recorded, actually applied P2 jump.
- S1 variation changes starting approaches using actual steering/reversing; select demonstrated speed phrases aimed at the required 61-68 range. Log achieved speed. Do not assume the range is achieved because the desired speed says so.

**Baseline diagnosis.** Compare the failed retry to a demonstrated good retry at matched physical events, not matched wall seconds. Highlight actual launch velocity, heading, contacts and roll at the matching tick. If the demonstration succeeds, this proves the old controller is not a universal witness; it does not prove why the old attempt failed. Replay drift without measured bad game response is a test problem. Matched valid inputs with different outcomes remain unresolved physics/state differences until measured.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught: typed anchors, no generated expression plan. Wrong anchor binding is still possible. |
| E2 tree / varied parking | Partly: relative anchoring adapts modest offsets; big offsets exhaust recovery and produce test failure. |
| E3 unplug freeze | Caught by common supervisor. |
| E4 circling | Caught: departure event requires sustained forward progress. |
| E5 stuck video passed | Caught: departure is an obligation, not optional footage. |
| E6 no-pad leg-up | Caught: input readback and actor motion required. |
| E7 skipped scenarios | Caught by host manifest. |
| E8 silent freeze | Caught by independent health checks. |
| E9 wrong swim blame | Partly: comparable phrases reveal differences, not causation. |
| P1 downhill reset | Caught/named by a stationary-reset anchor before retry. |
| P2 sill | Partly: phrase stalls at doorway; name sill only from contact/frame evidence. |
| P3 swimming | Caught/named if miss-with-player-out demonstration is present. No branch, no coverage. |
| P4 rubble | Partly: demonstrated placement is blocked; may mislabel it replay drift until obstruction is inspected. |
| P5 wreck | Partly: demonstrated legal viewpoint plus reviewer; camera drift may lose it. |
| P6 hub | Partly: same visual limitation. |
| P7 HUD | Caught if required screenshot/text observation stays valid. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly: compares real good/bad inputs and launch events; no automatic causal verdict. |

**Harsh criticism.** This still encodes a route. Enough correction becomes #1, while too little becomes the failed timed script. A good human demonstration is a real prerequisite, not a file I have found. Asking the user to supply one consumes their time. The existing ramp video/walk is not a valid input demonstration because W contains cuts, aimed cameras and moved items. Do not use it as a success oracle. A phrase valid at 66 might not work at 61. This candidate may fail S1 from drift even on a working game.

**Cost, I think:** first capture 8-15 min of an available tester's time, including mistakes; builder 40-60 min for an initial event playback and supervisor, 90-180 min for full correction/anchors. Run 3-5 min; review 1-2 min; 10 runs 40-70 min excluding capture. Zero in-loop model tokens; one optional 2k-6k token post-run review. User reads a deviation report in about 1 min. No existing human input file is assumed.

**Self-score:** S1 unknown, I think drift is a major risk. S2 partial, especially P4 naming. S3 I think 3/3. S4 I think 4/4 in 2-12 s. S5 pass only with genuine source inputs and input-based correction. S6 estimates above, initial capture charged. S7 I think 30-90 min adaptation plus another human demonstration; not free transfer.

## 3. Search the live space of possible actions

**Mechanism.** An in-engine explorer builds a graph of what it has actually managed to do. Unlike #1's fixed goal order or #2's demonstrations, it chooses untried reachable actions and learns which transitions work in this run. The graph uses coarse physical facts: side of river, seats, held object, inside/outside hut, wheel present, available prompts, supported crate and device status. It does not use `solve_quietly`, hidden completion flags as rewards, or mutations of the scene.

Builder specification:

- Begin at declared F1 setup. Enumerate visible/interactable objects with ray tests and legal stand positions from collision queries. Walk/drive by a small local collision-avoiding controller using real input. Turn cameras with input. Candidate actions: approach, inspect, interact, carry/drop, crouch, jump, board, brake, drive corridor and reverse. Hold-action durations come from observed progress with a hard deadline.
- Assign each observed transition a before record, input sequence, after record and confidence. Prioritize sheet obligations not yet witnessed. Penalize repeating the same failed transition three times. Global budget 5 min; on exhausted frontier stop with `exploration incomplete`, never pass.
- Fail a known contract immediately, even if another route would bypass it. A recovered stumble is still recorded. Pass requires the complete H witness chain, departure and separate visual observations. The search cannot define its own completion score.
- Pair a failure with its attempted preconditions and collision body. A collision-free action that does nothing still needs controls checked before blame. A failed planner is not proof a player cannot do it.

**Baseline diagnosis.** A miss becomes a recorded edge with its physical launch trace. Try a different lawful approach only as separately scored exploration evidence. A successful alternative supports controller inadequacy, not a root cause. Ten misses do not prove a game fault; inability to search is reported as such. It must preserve the original 66.5/1.05/14.5 attempt rather than optimizing it out of the report.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught by typed interface/preflight; search-policy mistakes remain. |
| E2 tree / varying parking | Partly: frontier selects another approach; may waste its budget exploring. |
| E3 unplug | Caught by common minimum. |
| E4 circling | Caught: revisiting same coarse state without road progress stops repeat. |
| E5 stuck video passed | Caught: no witnessed outgoing-road edge, no completion. |
| E6 leg-up no pad | Caught: real P2 transition/input needed, not merely “not inside”. |
| E7 skipped work | Caught by manifest and obligation ledger. |
| E8 frozen watcher | Caught by independent health check. |
| E9 wrong swim blame | Partly: graph records correlation; no causal verdict without evidence. |
| P1 reset roll | Caught/named by stationary-reset contract, not search reward. |
| P2 sill | Partly: repeated failed door edge gives location; exact sill needs contact/frame. |
| P3 swimming | Partly: must actually discover/execute left-behind miss branch. |
| P4 rubble | Partly: may find a workaround and hide the bad placement unless required route checked. |
| P5 wreck | Partly: only required inspection makes it covered; exploration alone would miss it. |
| P6 hub | Partly: same visual requirement. |
| P7 HUD | Caught if required wheel-off observation executed. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly: finds varied lawful traces; still cannot infer cause from a successful alternative. |

**Harsh criticism.** Searching is expensive when every action needs real walking. Coarse states can merge important crate positions or velocities; fine states explode. It might spend five minutes discovering that the door is bolted. The proposed collision controller and action catalog are substantial implementation. I defend this as a way to discover unforeseen paths, not a likely first winner under the one-hour cap.

**Cost, I think:** 45-60 min for jump/departure-only explorer; 4-8 hours for full co-op graph and interactions. Full trial likely hits cap. 3-6 min per attempt, incomplete at budget counts unsuccessful; 10 attempts 40-80 min with reviews. Zero loop model tokens, estimated 1-3 min to read failed frontier; optional post-run 3k-8k token explanation. S7 reuse may be good only after that expensive catalog exists.

**Self-score:** S1 I think unlikely 10/10 initially. S2 partial with branch-coverage risk. S3 I think 3/3 via supervisor. S4 I think 4/4, 2-12 s health; repeated-state stalls within 10 s. S5 intended pass. S6 costly estimates above. S7 I think 2-6 hours for unfamiliar actions, unmeasured.

## 4. Paired attempts that test a cause

**Mechanism.** Keep an ordinary real-input attempt, but diagnose it with a tightly controlled second attempt. This method's main contribution is experimental blame assignment, rather than smarter play. It cannot be sold as a complete autonomous player. For a full sheet it needs a human operator or a declared borrowed controller, charged in cost.

Builder specification:

- Instrument inputs, applied inputs, contacts, transforms, angular and linear velocity, water/swim, wheel/HUD, device state and scenario ledger. Retain matched video. Use an ordinary real-input player for the primary route, with no forbidden helpers after F1 setup.
- Predeclare a pair matrix: fresh menu start versus normal post-miss retry; neutral steering versus controller steering on the straight approach; driver ownership versus simultaneous input owners; target-relative departure versus old road-index departure. Change just one factor per pair. Log other starting differences; unmatched pairs are inconclusive.
- For public P1, hold brake release until the reset obligation is measured in both cases. For P2/P4 compare attempted motion with collision at the actual sill/rubble. For P3 compare dry support and swimming, not vehicle speed. All diagnostic runs have their own manifest and never overwrite primary failures.
- A successful second controller with the same scene can demonstrate a bad first policy if traces show its specific wrong action (e.g. turning into a known blocker). It does not absolve all game behavior. If player input is delivered and collision geometry blocks a required route, name the measured blocker. If evidence cannot distinguish causes, say inconclusive.
- No arbitrary “bad roll means invalid test” rule. The game may itself create that roll. Trace the first divergence from last grounded contact and its input/contact history.

**Baseline diagnosis.** First pair: fresh start and post-miss retry with the same input policy and logged state. Then, only if needed, vary steering ownership. Compare forward/upward speed and contacts at launch; compare early body tilt and collision history. Neither resetting angular velocity inside the proven retry nor modifying the ramp is allowed. Up to two diagnostic pairs, then stop and report. This could answer what 66.5 missed, but the answer is currently unknown.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught by common typed preflight; primary player may bypass expressions. |
| E2 tree parking | Partly: pair with obstacle-aware/human departure can identify a bad command; adaptation itself is borrowed. |
| E3 unplug | Caught and correctly named from event/pause sequence. |
| E4 circling | Caught: progress contract; index hypothesis tested through pair, not repeated as fact. |
| E5 passed stuck tree | Caught: independent final travel contract. |
| E6 no-pad leg-up | Caught: input/actor evidence absent. |
| E7 skipped scenarios | Caught by host manifest. |
| E8 silent freeze | Caught by common minimum. |
| E9 swim blame | Caught as unsupported blame; isolated input/reset measurements can test competing explanations. |
| P1 downhill reset | Caught/named directly from reset brake and roll trace. |
| P2 sill | Caught/named if collision and valid traversal input measured; otherwise partly. |
| P3 swimming | Caught/named from dry support plus swim flag after real reset. |
| P4 rubble | Caught/named if blocker identified during required placement; otherwise partly. |
| P5 wreck | Partly: required viewpoint and visual inspection, not a paired-motion result. |
| P6 hub | Partly: same. |
| P7 HUD | Caught/named by wheel-off versus visible HUD wording. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly now; this is the strongest proposed way to measure cause, but pairs can remain unmatched. |

**Harsh criticism.** Repeats multiply wall time and can manufacture a tidy explanation out of stochastic physics. One successful pair is weak evidence; failure to hold other variables constant ruins attribution. A broken test can be diagnosed without a method that can finish the sheet. This is a diagnostic finalist only if its borrowed player is honestly included in the trial. Do not count it as an independent full-route player.

**Cost, I think:** 35-55 min observer/pair report for jump scope; full instrumentation 90-180 min plus borrowed player build. Primary full run 3-5 min, plus up to four extra jump attempts at roughly 0.5-1 min each including reset/load. Budget 5-10 min total per failing case, then stop; no retry loop. Human operation adds 3-5 min attention per primary run if no automatic player. Zero model turns during play. One diagnosis after run, estimated 4k-10k tokens / 1-3 min; user reads about 1 min.

**Self-score:** S1 entirely depends on primary player, no independent 10/10 claim. S2 I think better naming for P1-P4 than an outcome check alone; P5/P6 still visual. S3 I think 3/3. S4 I think 4/4, 2-12 s. S5 intended pass if pair setup boundaries explicit. S6 expensive failures, quantified above. S7 I think 30-90 min instrumentation plus the new player's cost; causal experiments are puzzle-specific.

## 5. Screen-driven control with bounded local computation

**Mechanism.** A host visual controller plays from rendered player views, not object world positions. It uses cheap image operations at 5-10 Hz, then sends short-expiry input batches. A model helps write the detector/controller before play, not decide each command. This directly tackles the weak sensing of D while avoiding v3's model wait.

Builder specification:

- Obtain downsampled frames from each existing player viewport after rendering, with frame ID tied to retained telemetry. Never move the cameras except mouse/pad input. Frames contain normal visuals, no added world-position markers or object-ID colors. Health telemetry is allowed, but control uses pixels and device readback only.
- Derive road edges and van alignment from image gradients/line fits; optical flow estimates forward progress. Track shutter, crate and door by appearance templates from legal player views. Read prompt/HUD regions from deterministic text rendering data only for judging, or OCR for the pixel-only controller. A target not confidently located triggers a bounded camera scan, then `controller blind` within 10 s, not a speculative interaction.
- Use a state machine of sheet intentions. Approach until image target scale and prompt indicate interaction range; crouch/jump/hold through real input. P1/P2 views must both show activity for leg-up. Completion needs visual doorway crossing, wheel carried/fitted and sustained road flow, backed by independent physical checks. Never accept flow alone: circling also produces it.
- Judge wreck waterline, hub/ground relationship and HUD from actual images. Store detections and confidence, not just pass labels. If confidence is low, report unchecked and fail completion.

**Baseline diagnosis.** Video can reveal a side wheel clipping the ramp or visibly wrong alignment. Retained telemetry provides actual launch vectors and contacts for blame. If the detector lost the ramp before a bad steering command, name controller perception only when recorded confidence/command supports it. A good-looking image is insufficient to explain the 66.5 miss. Otherwise inconclusive.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught/bypassed: no walk-expression action plan, typed transport checks. |
| E2 tree variation | Partly: visible obstacle sensing helps; texture or lighting can blind it. |
| E3 unplug | Caught via supervisor and layout/device change. |
| E4 circling | Caught only with independent signed road progress; flow alone falsely passes. |
| E5 stuck video | Caught: no departure flow or physical progress. |
| E6 no-pad leg-up | Caught: P2 layout/activity and accepted jump required. |
| E7 skipped scenarios | Caught by common manifest. |
| E8 freeze | Caught by heartbeat; image motion alone would falsely flag intentional waits. |
| E9 swimming blame | Partly: pictures show posture, not drag forces; do not claim causation. |
| P1 reset roll | Caught/named with stationary-reset physical check; image drift alone insufficient. |
| P2 sill | Partly: visual blockage plus contact may name sill; controller may simply miss doorway. |
| P3 swimming | Caught/named with support/swim trace, since posture detector can fail. |
| P4 rubble | Partly: can see obstruction but may misclassify crate/rocks. |
| P5 wreck | Partly: waterline detector might miss dark/submerged car. Missing required view fails coverage. |
| P6 hub | Partly: projected ground/mesh appearance is lighting-sensitive. |
| P7 HUD | Caught/named if OCR/text-region check valid. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly: independent pixels and contacts help; no assured causal result. |

**Harsh criticism.** This might replace a brittle motion script with brittle vision. Lighting, snow, occlusion and split-screen resolution change templates. Pixel distance is not metric clearance. Full crate/leg-up control from pixels is a serious build, and an appeal to “AI vision” hides the difficult part. I defend its independent sensing; I do not think it is the best one-hour implementation.

**Cost, I think:** 45-60 min for road/obstacle prototype, 6-12 hours for a full pixel co-op player. Likely cap failure for full route. Run 4-7 min, 1-3 min result review; 10 runs 50-100 min. Zero model tokens in loop. Local inference/image computation must be timed: target <20 ms/update, not measured. Optional single post-run model review 3k-8k tokens. S6 fails any claim of cheapness until measured.

**Self-score:** S1 I think poor initially. S2 potentially strong visible coverage, unproven P5/P6. S3 I think 3/3 via supervisor. S4 I think 4/4, 2-12 s health. S5 intended pass with player cameras/input only. S6 highest build cost besides #7. S7 I think 3-8 hours to retarget visual recognition; not generic today.

## 6. Separate evidence judge over a real play session

**Mechanism.** Delete the automated player initially. A tester plays through controls while an independent host assembles proof and a separate reviewer judges it. This separates playing from deciding success, with no model controlling live play. The tester may later be replaced by #1 or #2, but that would be a combined method, not free ability of #6.

Builder specification:

- Launch declared menu setup; tester follows H without developer moves. Test-only observer records the common health data, input provenance, physical events and continuous two-view video. Tester is told desired actions, not private bug checks. Do not silently fix or patch anything during a run.
- Host checks health, scenario coverage, applied P2 action, reset stationarity, successful physical traversal and signed departure progress live. It halts on those failures. Model never needed to notice a freeze.
- At event boundaries save a contact sheet and short clips for legal views of wreck, bare hub/HUD, attempted leg-up, crate placement, door traversal and departure. A reviewer who did not play receives these, the immutable sheet and telemetry, without the player's own pass labels. Require evidence IDs per finding. `not visible` means unchecked, not pass.
- One bounded review at the end, or first failure. Reviewer gives each obligation pass/fail/unchecked and game/test/inconclusive with supporting evidence. Host accepts success only when machine gates and every reviewer obligation agree. Disagreement is unsuccessful and goes to referee; no endless panels or skybox polishing. Reviewer checks function/visibility, not fun or resemblance to another game's art.
- Score public mutants plus referee-private cases against this same review protocol. Record reviewer false positives and missed bugs separately. A human judge is allowed as fallback only when its attention cost is reported; it is not automatic verification.

**Baseline diagnosis.** Give the reviewer the 66.5/1.05/14.5 miss clip and properly timed launch/contact trace, without telling them a cause. They must not turn “I see roll” into “roll caused miss”. Can identify a recorded controller turn into an obstacle or a detector/physical landing disagreement. Otherwise report failed jump, unmeasured cause. A fresh human success helps establish possibility, not explain the failure.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught/bypassed: human play needs no generated walk expressions; observer preflight still needed. |
| E2 varied parking / tree | Partly: human can adapt; reviewer detects blockage but may wrongly blame game without control/contact trace. |
| E3 unplug | Caught/named by live device/pause supervisor. |
| E4 circling | Caught: independent departure proof plus video. |
| E5 passed tree video | Caught: reviewer must inspect final travel; machine gate independently rejects. |
| E6 no-pad leg-up | Caught: live device check plus visible P2 movement and applied jump. |
| E7 skipped scenarios | Caught by host manifest. |
| E8 silent freeze | Caught before reviewer is asked, by health process. |
| E9 swim blame | Partly: independent reviewer must reject unsupported attribution; can still hallucinate. |
| P1 downhill reset | Caught/named from physical reset trace and departure clip. |
| P2 sill | Caught/named if actual failed door approach filmed with contact evidence; human could jump it and conceal bug. |
| P3 swimming | Caught/named if required miss-with-player-out branch played, otherwise unchecked. |
| P4 rubble | Partly: reviewer can see it, but human might work round it. Required intended placement remains mandatory. |
| P5 wreck | Partly: probably better than flags alone; unseen/submerged wreck may be misread as dark scenery. |
| P6 hub | Partly: direct visual judgment can find it, can also miss it. |
| P7 HUD | Caught/named if the required wheel-off HUD frame exists and reviewer reads it. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly: strong evidence review, still no automatic causal proof. |

**Harsh criticism.** This spends a person's time on every run; if that person is the user it may defeat the task's purpose. Human players can mask broken intended paths with clever workarounds. LLM visual judgment is fallible, and asking another model is not a ground truth. Mandatory views prevent invisible coverage gaps but add work. Its advantage is removing an unproven bot from the initial experiment and making real pictures count. It is a serious baseline alternative, not the promised final autonomous solution.

**Cost, I think:** 35-55 min for manifest/heartbeat/event evidence prototype, 90-150 min for full automatic clip/report assembly. Tester 3-6 min/run attention, plus review 1-3 min; ten runs 40-90 min of actual operator/reviewer time. Zero model thinking during play; one review 4k-12k tokens, estimated 1-3 min. User reads result in 0.5-1 min, but if they are tester charge all play time too. No available tester or model-review transport is assumed; referee must establish it before choosing this trial.

**Self-score:** S1 I think stronger than a new bot for reaching the end, still not 10/10 measured. S2 I think best near-term visual coverage, uncertain named counts. S3 I think 3/3 with machine gates, model not permitted to override them. S4 I think 4/4 in 2-12 s. S5 pass only if all actual play is recorded and no dev shortcuts. S6 expensive human time, explicit above. S7 I think 20-60 min to author obligations/views plus genuine tester play; observer reuse unmeasured.

## 7. Predict short motions; execute only the first input

**Mechanism.** An in-engine local planner evaluates several short input futures against measured collision geometry, executes the first small input, observes the real result, then plans again. It differs from #1's fixed steering rules and #3's action-graph discovery: it optimizes near-term physical motion. No language model in the play loop. The live game is never repositioned to test a candidate future.

Builder specification:

- Read current transform, velocity, wheel contacts, heading and nearby collision sweeps. Every 0.1 s simulate a small kinematic estimate for 9 candidates (three steering choices times throttle/coast/brake), horizon 0.5-1 s. Penalize body-width obstacle collision, loss of support, lateral corridor error, wrong heading and insufficient goal progress. Execute only 0.1 s of the winning input. On reversing, plan in reverse frame and reacquire the outgoing segment.
- Fit acceleration/braking/turn response from the real first few seconds of this run; retain prediction error, do not modify van properties. This is an approximate controller model, not a duplicate authoritative physics engine. If residual error grows, stop and report planner uncertainty before trusting a predicted safe jump.
- For walking/carrying, candidate controls are movement/turn/jump/crouch with support and head-clearance sweeps. Interaction intentions still follow H. Reach and leg-up trajectories need measured response envelopes; do not substitute direct impulses. Predictive planning cannot prove a climb unless the actual player does it.
- Independent checker evaluates actual events and visual obligations exactly as in #1; predicted landing never counts. State mutations are allowed only in an isolated mathematical estimate, not the live scene or puzzle. No shadow Godot game instance; one live game only.

**Baseline diagnosis.** Compare predicted and measured trajectory from last supported contact, including angular/vertical motion. Large error says the planner model is wrong, not the game. If predictions match the failing trajectory, it exposes why this controller chose an insufficient path; actual root cause still needs contacts/input evidence or #4. Model error and game error must not be conflated. 66.5 total speed is insufficient to initialize a trajectory prediction on its own.

| Evidence row | Prediction — I think |
|---|---|
| E1 expressions | Caught: typed preflight, no walk expression program. |
| E2 tree variation | Partly: short rollouts see obstacles, but a too-short horizon can trap it. |
| E3 unplug | Caught by common minimum. |
| E4 circling | Caught by actual signed-progress judge; local optimizer can still circle. |
| E5 stuck video | Caught: actual departure required. |
| E6 no-pad leg-up | Caught: real P2 input/motion prerequisite. |
| E7 skipped scenarios | Caught by host manifest. |
| E8 freeze | Caught by host health deadline. |
| E9 swim blame | Partly: prediction error exposes inadequate model, does not establish swimmer drag. |
| P1 reset roll | Caught/named by stationary-reset checker; planner must not silently compensate. |
| P2 sill | Partly: swept support/collision identifies obstacle; planner may jump round required walking path. |
| P3 swimming | Caught/named by dry/swim contract if branch exercised. |
| P4 rubble | Partly: measured collision can name it, but optimizer may avoid it. |
| P5 wreck | Partly: same required visual inspection as #1; planner alone misses it. |
| P6 hub | Partly: same. |
| P7 HUD | Caught only by independent wheel-off/HUD obligation. |
| Old piers | Not caught: absent, excluded. |
| Fresh baseline miss | Partly: prediction residual versus actual launch trace; wrong model can give wrong blame unless barred. |

**Harsh criticism.** Short-horizon planning can choose locally safe dead ends. A van's suspension, grip, load and wheel-loss physics are precisely what a tiny model will get wrong. Calibration might hide a real game regression by adapting to it. Independent contracts must keep a bad reset or sinking hub red even if the planner compensates. The attractive idea of duplicating Godot physics would exceed the cap and risk a shared-model false pass; I explicitly do not propose it.

**Cost, I think:** 45-60 min for drive-only model and rollout controller; 6-10 hours for full co-op route. Full Stage 3 likely fails cap. Runtime target 9 short rollouts within 5 ms per 0.1 s planning update, unmeasured; stop trusting budget if measurements exceed it. Full run 3-6 min, review 1-2 min; ten runs 40-80 min. Zero model loop tokens; optional 3k-8k token post-run review. User reads about 1 min.

**Self-score:** S1 I think poor until calibrated across loads and arrivals. S2 actual checker may catch P1-P4/P7, visual P5/P6 uncertain; optimizer can mask defects. S3 I think 3/3. S4 I think 4/4, 2-12 s common health. S5 intended pass, referee checks no live resets hidden in planner. S6 high build cost. S7 I think 3-8 hours for a puzzle with new dynamics, not demonstrated transfer.

## Ranking and my two trial picks

No proposal has earned a scoreboard pass. S4 and S5 are hard gates; shared infrastructure predictions are not measurements. All quoted build/run/review estimates above are “I think”. The measured anchors are the brief's old ramp ~100 s and recorded walk 169 s (`TEST_METHOD_RESEARCH.md:180-181`), not measurements of these proposals. Recording can slow play (`TESTING_METHOD.md`, v5); report actual wall time, not just game ticks.

| Rank | Idea | Why here |
|---|---|---|
| 1 | #1 Measured skills + independent contracts | Best route toward fast autonomous play with physical evidence; full co-op implementation is the main cap risk. |
| 2 | #6 Separate evidence judge over real play | Most direct independent test of whether bot failures are obscuring a working game; visual bugs get actual views. Human time is its large, explicit cost. |
| 3 | #4 Paired causal attempts | Best focused instrument for the fresh unexplained jump; not a full player, and retries are expensive. |
| 4 | #2 Event-anchored genuine playback | Reuses real successful control, but only after obtaining a valid demonstration; drift threatens S1. |
| 5 | #3 Live action-space search | Finds new routes and exposes missing assumptions; too much walking/search/build work for first trial. |
| 6 | #7 Short-horizon motion planner | Stronger local choice than simple steering, but approximate physics can mislead the auditor. |
| 7 | #5 Screen-driven local control | Most independent perception; the full vision/co-op controller is least plausible within an hour. |

**My two picks: #1 and #6.** They test different bottlenecks: can a small reactive actor finish without scripted placement, and can an independent judge detect what a successful actor might hide? #6 also provides a real-input trace for a possible later #2. I would not spend the second trial merely retuning #1's steering.

One-hour honesty: neither full #1 nor polished #6 evidence assembly is guaranteed to fit. Referee should record a cap failure if the complete scored route is not built and exercised in time. A smaller first experiment may prove jump/departure instrumentation useful, but it cannot receive a full ramp score. No unannounced extra builder session. If no tester is available for #6, report that dependency before selecting it; do not swap in a per-command model player and recreate v3.

For either trial, first show health, missing-player and manifest checks fail when broken. Then one ordinary complete route. Then the public mutants and the required ten varied working-game runs, one game at a time. Keep requested and achieved lip-speed spread, landing/parking variation, first-failure clips, false alarms, caught/named counts, diagnosis uncertainty, build minutes, play minutes, review minutes and tokens. The referee owns order and run permission. No tests were started here.

## Facts the referee should carry forward

1. `PlayTest.gd:11599-11600`: baseline roll/pitch are maxima, not launch pose. `RampJump.gd:353-356`: lip speed is airborne total speed. Missing velocity direction/contact timing prevents causal attribution today.
2. `PlayTest.gd:11719-11724`: baseline success try is a genuine game-reset retry, not a fresh `ramp_start`. Replacing it with a fresh setup would stop testing that retry path.
3. `PlayTest.gd:11931-11932`: closest-ever road approach deliberately allows later circling. `12004`, `12019`: closest approach appears persistent across calls. This is an additional possible false-pass route, not an executed finding.
4. `LiveControl.gd:129-136`, `195`, `495`, `545`: error strings can reach boolean checks. Typed error propagation deserves a planted stale-expression check; actual coercion outcome unmeasured here.
5. `LiveControl.gd:485-501`: normal expects start after step commands; only expects explicitly marked `watch` are added to concurrent watches. Do not assume all walk expectations run during their step's actions.
6. `tools/run_test.sh:109-116`: it reports completed count but does not gate success on exact requested/completed IDs. A green failure count is not proof of complete execution.
7. W is a staged video plan, not a real-path proof. Reusing its placement, aimed-camera or wheel-move helpers in a new controller would fail S5 despite using real keys for some actions.

Decision log: v1 keeps seven mechanisms separate. Common health/coverage rules address established false passes. No scores claimed, no causal diagnosis invented, no other auditor material consulted.
