# GPT audit: Stage 2, round 1

2026-11-05. Proposal v2 after reading both Stage 1 files. No game or test run. No game or test code written. Only this file changed by this audit. No scores earned here.

The core: a green result must prove actual play, and a red result must not invent a cause. Claude's best contributions are rig health and controlled comparisons. Neither supplies a player or proves the hut. Treating either as a complete solution would hide the hardest missing part.

All proposed performance, coverage and cost judgments below mean **I think**, not measured results. Existing measurements are attributed separately. C1-C7 mean Claude's numbered ideas; G1-G7 mean my Stage 1 ideas. Trial owners are proposals for the referee, not instructions to start runs.

## Evidence checked independently

Paths below are relative to MPG_dev. These keys provide the file:line evidence for later tables.

| Key | Evidence and what it establishes |
|---|---|
| E | `notes/TEST_METHOD_RESEARCH.md:29-54`: the false alarms, false passes, wrong blame and real visual bugs. |
| S | `notes/method_research/scoreboard.md:9-29`: S5/S4 first; then S1-S3; then S6; S7 for finalists. An inconclusive result cannot become a clean S1 pass. |
| P | `notes/method_research/scoreboard.md:53-69`: referee's clean/mutant measurements. P1 moves 3.79 m in 5 s with brake off; P3 also moves 0.57 m with brake on. Swimmer contact is only the referee's hypothesis. |
| J | `FindingNaresh/scripts/puzzles/RampJump.gd:342-370`: total airborne speed is logged at z < -0.5; landing needs wheel contact, position and lateral bounds. Miss can fire below the deck without a far-z bound. Speed and offset alone are not the landing detector. |
| R | Same file, `585-640`: normal game reset zeros van velocities, sets its transform and brake, clears swimming for unseated players, moves them beside the van. These are game actions, not permission for a test to perform them. |
| A | `FindingNaresh/scripts/dev/PlayTest.gd:11579-11618`: AutoDriver input until z <= 1; maximum pitch/roll collected throughout z < 2, including falling. `11715-11728`: passenger seated by code, slow miss, genuine reset, wait 0.3 s, fast retry, early return if it misses. |
| D | Same file, `7485-7508`: index advances only for positive progress; full A/D outside a 0.05 rad band. This supports a driver hypothesis, not a proven explanation of circling. |
| L | `appdata/playtest/runs/seg_1.log:41-44`: 66.5 km/h, 1.05 m offset, miss. `appdata/ramp.out:38-42,58-62,76-80,96-100`: four 66.2 km/h, 1.00 m offset landings. |
| X | `PlayTest.gd:12088-12122`: retry test moves P2 near the ramp before the slow try and to the far side before the fast try; checks brake; calls ramp_start between cycles. It is not four unchanged natural two-player retries. |
| H | `FindingNaresh/scripts/story/Story.gd:93-101`: bridge done = flag present; wheel done = wheel_off false; cross done = within 60 m of j3. Entering cross proves repair, not departure. Even completing cross proves proximity, not continued travel on the road. |
| Q | `PlayTest.gd:11924-11932`: departure checks displacement and closest-ever approach to road; expressly permits later circling. `tools/run_test.sh:108-117`: counts completed scenarios; final exit gates failure/problem strings, not exact requested/completed identities. |
| T | `PlayTest.gd:40,217-218`: always-process test and pause-independent timer. `FindingNaresh/scripts/core/Boot.gd:262-277`: disconnect changes P2 device/layout and correctly pauses. |
| U | `FindingNaresh/scripts/core/InputDevice.gd:257-260,274-280`: held buttons and pad movement axes are different channels. A held(action) check alone is not movement-axis readback. |
| V | `FindingNaresh/scripts/ui/PlayerHUD.gd:355-367`: start failure, coolant leak and heat can legitimately take priority over wheel-off warning. `FindingNaresh/scripts/player/PlayerRig.gd:1608-1620`: swimming ends near the target bank, with a final move onto it. |
| W | `notes/TEST_PUZZLES.md:322-354`: intended slow miss, jump, negative leg-up, crate leg-up, inside bolt, door traversal, repair and departure. `design/PUZZLE_CHANGES.md:1578-1602`: 56.6 missed and 60.9 landed in the bench; these are observations, not a universal offset/attitude guarantee. |
| C | `FindingNaresh/scripts/player/PlayerRig.gd:1916` disables seated collider; `FindingNaresh/scripts/items/Carryable.gd:212-217` freezes stowed cargo and removes collision. This weakens a simple added-collision/load explanation, without ruling out all passenger/cargo effects. |
| M | `notes/TESTING_METHOD.md`, v3: per-command model thinking became the main cost. `notes/TODO.md:10`: research format records the user's “no reference recording”. The binding brief does not require a reference demonstration. |

Skills read, without editing: the two requested testing-and-verification and first-principles-solving SKILL.md files. Applied here: requested input is not physical effect; retain failing evidence; check the tester first; don't promote an unexplained number to a cause. I did not open the other auditor's round-1 audit or inspect private referee checks.

## Claude's seven, attacked

### C1. Rig-checked verdict — keep, narrowed

**Strongest point:** E/T/Q demonstrate three independent holes: tests continue while paused, a disconnected pad changes the actual device, and completed counts can hide omitted scenarios. An outside watchdog and a durable work list address these mechanisms directly.

**Break it:** P3 creates a dry swimmer after the game's reset. C1's “nobody swimming” precondition would call this test/setup trouble and erase a real game bug. Preconditions produced by real play must be checked as game outcomes, not assumed setup facts. A player deliberately walking into the hut sill also fails the proposed 0.2 m movement threshold despite correct input delivery: false alarm and wrong blame. U requires axis readback for movement. A fresh heartbeat with no world movement is not progress. A wrapper counter cannot detect arbitrary setters that bypass it; audit the call path as well.

**Scores:** S1 is not neutral: new movement thresholds add false alarms. S2 remains low alone. S3 3/3 is plausible only for parse errors, exact work accounting and explicit disconnects; stale but valid expressions need typed semantic checks. S4 4/4 is plausible only with a host deadline, continuously checked player presence and scene-reload accounting; an end-only count cannot guarantee detection within 60 s. S5 is not earned by counting SET lines. S6 “~0” excludes the proposed slow-try and 20 m controls on every run. S7 is plausible for health plumbing, unproved for puzzle preconditions.

**Cost/verdict:** Claude estimates 2-4 h full build (`ideas_claude.md:134-138,567-568`), beyond the cap. Keep a one-hour health/manifest slice; delete mandatory physical controls from every run, run them during rig qualification instead. No complete-ramp claim.

### C2. Counterfactual blame — merge with G4, reject its verdict table

**Strongest point:** L exposes a real unexplained discrepancy. Capturing launch vectors and varying one cause is better evidence than arguing from 66.5 km/h.

**Break it:** two drivers can share the same bad throttle or route target. Both fail, so “all variants fail -> GAME” gives wrong blame. A second driver might land by avoiding a real edge bug; “different driver passes -> TEST” can also give wrong blame. P3 already gives another cause of van movement (P). Removing both P2 and cargo changes two factors. Fresh setup also changes multiple inherited states. X shows the four successful cycles moved P2 across the river in code: they do not isolate a load effect. V4 expressly uses MPG, forbidden for this task. Drop it.

**Scores:** S1 belongs to the original attempt; a successful diagnostic retry cannot wash out its failure. S2 can improve naming, but fresh-start success alone does not name the handbrake. S3 0/3 alone is fair; 3/3 with C1 is still a prediction. S4 0/4 alone is fair. S5 depends on separate declared boundaries: no fresh setup inside the retry being proved. S6 ten tries is an added diagnosis cost, not run cost alone. S7 needs newly justified interventions, not just a reusable helper.

**Cost/verdict:** Claude's ~2 min jump estimate omits instrumentation/second-driver work (its own estimates total ~2 h, `ideas_claude.md:207-212`). Merge the experimental mechanism with G4's matched starts, limited pairs and inconclusive verdict. Keep original failure. No automatic game/test causal label from an outcome flip.

### C3. Always-on invariants — merge into independent checking, not a standalone finalist

**Strongest point:** local state-versus-world checks can name an object before a later objective times out. R and V give genuine independent facts to compare: supported dry player versus swimming; missing wheel versus warning text.

**Break it:** P3's 0.57 m drift can trip a reset-motion rule and be misnamed P1 (P). Missing brake readback and contact evidence make that wrong blame. A ray from the ramp to the wreck can hit an intervening rail while a player can see round it: false alarm. A doorway capsule query is not actual walking over the sill: false pass for P2 if step/support handling differs. P4's static heap proximity is not proof of failed crate placement. V permits higher-priority warnings; requiring ON THE HUB at every instant would falsely fail a hot van. A literal “nothing below terrain” rule also needs explicit scope for the deliberately partly submerged wreck (W/P).

**Scores:** S1 9/10 is a failure under S, not a near-pass. S2 7/7 caught AND named is unsupported; P1/P3 attribution alone defeats that claim. S3 0/3 is fair. S4 cannot be earned by an in-tree monitor that freezes with its subject. S5 observation itself is clean, but this proves no route. S6 5 Hz runtime cost is unmeasured and does not erase build/review cost. S7 local comparisons transfer; puzzle placement/visibility rules must be reauthored.

**Cost/verdict:** estimated 2-3 h (`ideas_claude.md:272-275`). Merge dry-swim, brake/motion, bounds/ground and HUD consistency checks into G1/G6 evidence. Keep them test-side. Drop the always-on-in-every-user-play build from Stage 3.

### C4. Envelope sampling and shrinking — drop as a separate trial

**Strongest point:** it varies the very arrival conditions S1 requires. Logged real launch state is useful; a single repeated bench start does not test robustness.

**Break it:** “>=61 and offset <=1.5 -> upright landing” adds a guarantee W never established. J also depends on direction, support and contacts. The baseline L satisfies those two numeric inputs and fails: that establishes a counterexample to the proposed rule, not a game defect. Shrinking can change arrival attitude as well as speed, so the smallest flipping input is not necessarily the cause. Failure type: false alarm, then wrong blame. Its upper target 80 km/h is not the required measured 61-68 spread; report achieved lip speeds, not targets.

**Scores:** S1 varied sampling fits the measurement but does not predict 10/10. S2 P1 can be caught; named requires brake/reset evidence and P3 exclusion. S3/S4 0 alone are fair. S5 is conditional: current ramp_try directly releases the brake (A); a literal helper reuse is not input-only play. S6 24 tries plus shrinking exceeds the advertised 24 tries. S7 the claim is reasonably limited to physics; no hut actor exists here.

**Cost/verdict:** estimated 1-2 h build, ~5 min plus startup and uncounted shrink (`ideas_claude.md:332-336`). Drop the separate trial. Keep varied conditions in every candidate's S1 evaluation and bounded comparisons in C2. This is an experiment schedule, not another way to play and judge the complete puzzle.

### C5. Goal-seeking players — merge with G1, replace sole game-goal judge

**Strongest point:** sensing obstacles and prompts closes the loop E2/E4 lacked; input-only crate and leg-up skills would actually address S5 in the hut.

**Break it:** a bot can jump the bad sill or find a crate position beside the heap and meet all final flags. P2/P4 then false-pass despite a required route being broken. “P2 in hut” cannot prove an attempted no-crate leg-up. H is particularly damaging: entering cross happens after wheel refit, even if the van never drives. Completing cross only establishes a 60 m proximity condition. Game-owned flags are useful evidence, insufficient independent verdicts. A bot timeout at a door does not name the sill; the bot may face the wrong way.

**Scores:** S1 weakest-early is an honest prediction. S2 P2-P4 caught/named-by-place is overstated without route/contact evidence; P5-P7 missed is fair. S3 0 alone is fair. S4 budgets may exceed 60 s, so fails the gate as written. S5 could pass after input/call-path audit, not because goals use node names. S6 days-to-build is incompatible with an hour. S7 “30 min goal list” assumes general skills already proven; the first new interaction can invalidate it.

**Cost/verdict:** Claude estimates 1-3 days (`ideas_claude.md:395-404`); my G1 estimates 3-6 h for full co-op (`ideas_gpt.md:99`). Merge the duplicate actor with G1's independent route obligations. Test a bounded slice and publish cap failure if the whole scored route cannot be done. No renamed old teleports.

### C6. Blind picture judge — merge with G6, keep independent evidence, remove majority-as-truth

**Strongest point:** E says pictures found bugs functional checks missed. P5/P6/P7 need visibility and presentation evidence, not just completed story flags. Post-run judgment avoids M's command-by-command think time.

**Break it:** a private checklist requiring a hub view is useless if the author never knew that view was needed. Publish view obligations; keep planted errors and judge decisions private. Two fresh calls can share a mistaken depth interpretation; agreement is no ground truth. “One no -> ask user” also spends user attention on routine ambiguity. A 1 fps grid cannot establish applied leg-up input or a doorway contact. P6's measured defect is -0.19 m (P), not merely the guessed 0.1 m example. Extra observer cameras must never replace proof that the player can see the wreck.

**Scores:** S1 unknown is fair. S2 P3/P4/P5/P7 are candidate detections, not four caught/named credits; require frame citations. S3 T1 cannot be inferred from absent P2 view alone: use device/pause events. S4 fails alone because it judges after play. S5 observation-only cameras can be compatible, but cannot legitimize a staged actor. S6 50-150k tokens and 1-3 min are estimates, not evidence. S7 adding camera locations is only part of new view/meaning authoring.

**Cost/verdict:** estimated 2-3 h full build (`ideas_claude.md:468-478`). Merge with G6: existing player-video capture, sparse mandatory views, independent host health, one cited judgment; ambiguity stays unsuccessful/unchecked without an automatic user query or fix loop. Real actor availability remains a dependency.

### C7. User trace as reference — drop reference, merge recorder only

**Strongest point:** a raw input/event trace can expose “negative leg-up passed without any P2 jump” and identify the first divergence. That is evidence rather than a guessed cause.

**Break it:** the user may never miss in the reference play. P1/P3 then remain unexercised. Two legal toolbox/door orders may differ and falsely fail a trace match. A continuous input stream can grow while the world is frozen: file growth alone false-passes N1. A player can exist without producing events, so no P2 events does not establish N3. Comparing lip speed with one user's speed cannot name P1. M records “no reference recording”; do not make a new reference play a prerequisite.

**Scores:** S1 order/timing risk is fair. S2 P1/P3/P7 only if branches and relevant physical/HUD observations exist. S3 needs explicit rig events for T1 and a host manifest for T3; matching a trace does not supply them. S4 N1/N2/N4/N3 all need independent health/identity accounting, not event absence alone. S5 neutral is fair; recorder cannot confer real-path status. S6 “~0” excludes hooks, capture and reference review. S7 needs another example and hand-checked contract.

**Cost/verdict:** estimated 2-3 h plus 5-10 min user play (`ideas_claude.md:535-543`). Drop the reference-derived oracle. Merge raw recorder into C1/G6 evidence. G2's event playback is related, but recording-and-diffing outcomes and choosing input phrases are different mechanisms.

## True duplicates and what survives

| Claude / GPT | Same mechanism? | Merged version |
|---|---|---|
| C1 / G1-G7 common minimum (`ideas_gpt.md:43-58`) | Yes: independent heartbeat, rig checks, input receipt and durable manifest. Not an extra eighth GPT idea. | C1's early plan lint and explicit preconditions; GPT's typed validity, scene identity, missing-player checks and preserved failures. No precondition may relabel a real-play defect. |
| C2 / G4 | Yes: intervention pairs to explain an observed failure. | Claude's variant measurements and repeatability probe; GPT's matched-state caveat, limited retries, original failure retention and permission to remain inconclusive. |
| C5 / G1 | Yes: sensed, goal-directed input skills. | Claude's prompt-led use and obstruction recovery; GPT's independent route/contact checker and sustained departure evidence. |
| C6 / G6 | Yes: separate post-run evidence judge, no model driving loop. | Claude's fresh blinded reviewer and canaries; GPT's machine gates, mandatory visible route evidence and explicit actor cost. |

C3 overlaps G1's checker, but always-on assertions in every play are not the same whole mechanism as actor-plus-independent-judge. C4 is not a duplicate of G4: sampling/shrinking hunts counterexamples; paired intervention tests an existing causal hypothesis. C7 shares recording with G2, but is not identical to corrected event-anchored playback. Merge components without pretending the entire ideas were duplicates.

## My own seven, revisited

Stage 1 remains v1 in ideas_gpt.md. These are v2 decisions; nothing is silently rewritten.

| My idea | Decision and evidence that moved or supports it | Expected attack and defense |
|---|---|---|
| G1 measured skills | Keep, merge C5 actor/C3 observations/C1 health. H strengthens the need for an independent checker; P3 knock-on forces separate brake and swim attribution. | “Days of bot work.” Valid; full-route build is unproved and may fail the cap. A jump slice gets slice credit only. Prompts do not substitute for input/physical effects. |
| G2 event playback | Drop from top four. C7's demonstration dependency and M's no-reference note add to my own admitted capture/drift cost (`ideas_gpt.md:140`). | Not all playback is a trace diff. Still, no valid input source is established. Do not spend a trial manufacturing a required reference. |
| G3 live search | Drop from top four; keep recorded v1. C5's actor-cost estimate reinforces my 4-8 h estimate (`ideas_gpt.md:180`); no evidence solves that dependency. | Search could find unforeseen routes. True, but cannot prove intended sill/placement behavior by avoiding it, and loses S6 before meaningful S1 is available. |
| G4 causal pairs | Keep through C2, revise P1 naming. P directly disproves “drift names handbrake.” | Outcomes alone don't establish cause. Agree: require delivered-input/contact evidence, single changes and unresolved verdicts. This improves naming; it isn't a complete player. |
| G5 screen control | Drop from top four. No new measured evidence changes v1's vision/co-op cost risk. | “More independent.” Yes, but unbuilt perception cannot earn S5 or ten successes; keep independence in judge instead. |
| G6 real-play evidence judge | Keep, merge C6. P5/P6 measurements reinforce visual obligations; remove C6's repeat-call vote and hidden capture requirements. | “Needs a person.” Correct; charge all attention and require the referee to establish an actor. No person/valid actor means blocked or failed trial, not a model-command loop substitute. |
| G7 short motion planner | Drop from top four. L/J show speed/offset fail to specify launch; fitting a small model cannot establish missing suspension/contact facts. My 6-10 h full-route estimate remains (`ideas_gpt.md`, G7 cost). | Replanning might improve driving. It can be a later controller experiment; shared incomplete prediction can also adapt around a regression. No evidence earns this extra build now. |

I also withdraw any implication in v1 that G1's stationary-reset check alone names P1. P3's brake-on drift is the specific new evidence. The presence of an explicit swim-state check does not automatically prevent a wrong earlier label: report both observations before attribution.

## Proposed top four: exactly two Claude, two GPT

These are four competing packages/contributions, not four independently complete players. Borrowed actors and common infrastructure must be named, audited and charged. A health-only or jump-only trial cannot receive whole-ramp S1/S2 credit. S7 is unearned for all four. Estimates below mean I think. The referee decides whether the smallest slice is a worthwhile trial; the hour cap is not permission to omit scored work silently.

### Claude trial c1 — rig-checked execution (C1 + GPT common minimum)

Put a host-owned requested-work ledger around an input-only ramp attempt. An always-processing observer reports once a second: run ID, scene generation, monotonic timestamp, pause, two player identities/devices, active obligation, plus a counter incremented by an ordinary unpaused world-physics callback. Host checks every 2 s; missing/stale world progress for 10 s, unexpected pause or missing player stops within 12 s. Explicit pad-loss -> test problem. A missing scene generation closes outstanding obligations as skipped within 10 s; exact IDs, not counts, decide completion. Preflight parses expressions, validates result types/nodes, resolves scenarios and rejects work after save. First ramp version: health plus the existing baseline's jump prefix, with all helper mutations declared before the boundary or removed. S5 still requires a source/call-path audit. This beats C7/C4 on the S4 gate and S3 T1-T3; it does not fix S1's driver or S2 coverage. Build budget 40 min, negative controls and one input-only prefix 20 min; stop at 60. Publish partial coverage if that is all it proves. No per-command model cost.

### GPT trial g1 — sensed driving with an independent verdict (G1 + C5, C3 observations)

The Opus builder builds the following bounded actor, without inventing hut shortcuts. Start at the declared F1 ramp setup, then real input only. Driving updates at 10 Hz from actual road/ramp geometry, van pose/velocity and a swept chassis shape; choose the nearest forward segment afresh after reversing. Set desired speed by throttle/brake input with one pedal owner; steer toward a look-ahead point 8 m plus 0.4 s of speed ahead, normalized heading error clamped to [-1,1] at 0.35 rad, sent through the existing control transport. If that transport cannot represent the requested input, report it; do not replace it with a transform setter. A blocking sweep causes brake to rest below 0.2 m/s, reverse at at most 5 km/h for at most 2 s, then reacquire; at most two recoveries, retaining the first failure. No automatic jump retry turns failure green. Stop for 10 s without signed route progress, measured by nearest-segment arclength with heading, not displacement from start. These controller constants are trial choices, not claims about valid game play.

The independent checker records inputs/readback, wheel contacts, ramp-frame position, full velocity and angular velocity each physics tick from approach until landing/reset. It requires actual airborne crossing followed by supported far-bank arrival, and records the game's jumped flag separately. After a miss, observe brake state, van drift for 5 s and each unseated player's dry-support/swim state before commanding departure. Drift alone never names P1. If the actor reaches the repair phase, the full version must execute W's actual leg-up, crate, bolt, door and refit obligations by input, with contact evidence for blockers. Prohibit reuse of old placement, direct seating, direct camera aiming, wheel moving or brake setters inside the proof. Full departure requires both aboard, repaired wheel, 30 m signed outgoing-road progress, final 3 s inside the road corridor, then an input-controlled stop below 0.2 m/s. These are explicit proposed witness criteria, not new game requirements. Use c1 health or count its equivalent build time. Allocate 40 min to implementation and 20 to watched qualification; unfinished hut means cap failure for full-ramp scoring, not an extra builder session. This beats C4/G7 by judging actual consequences without a predicted landing envelope; gates are explicit, S1-S3 remain to be measured. I think the full co-op version is unlikely within the hour. That risk must be visible before selection.

### Claude trial c2 — bounded causal comparisons (C2 + G4)

Instrument the existing unexplained jump, preserving the primary failure. First compare two separately declared starts under one input policy: fresh F1 approach versus a real slow miss followed by the game's own reset. Acquire both players/cargo through input before the boundary or declare them setup; do not hand-position P2 during the retry. Record at last supported contact, first airborne sample and landing/miss: ramp-frame pose, forward/lateral/upward velocity, angular velocity, inputs and wheel/contact identity. If the starts differ in an uncontrolled way, say unmatched. Then, only if needed, compare that same start with steering neutral through the last straight segment versus the original policy; change no other commanded factor. Maximum two pairs, no automatic all-fail/game or alternate-pass/test table. P1 attribution needs observed brake-off reset plus drift without input; P3 dry swimming is reported separately. Use c1 health for S4/S3 and audit each setup boundary for S5. Compared with C4, it buys S2 naming evidence without inventing an envelope; compared with a trace reference, it does not require user demonstration. Budget 40 min instrumentation and 20 min runs/report; actual run/reset/review costs recorded. Still no complete-route score without a complete real actor.

### GPT trial g2 — independent evidence over real input play (G6 + C6)

The Opus builder instruments and captures; it does not author a new player. The referee must supply a real-input operator or an already audited actor. None is established in the files read. If unavailable, report the dependency and cap outcome; never call a staged walk a substitute. Publish this capture list to the builder: legal ramp-top wreck view; real slow miss and reset; left-behind swimmer/reset branch; supported landing and bare-hub close view; wheel-off HUD with other warning states logged; delivered P2 jump for the no-crate attempt; intended crate placement and leg-up; inside bolt; P1 walking through the open doorway without jumping; wheel/nuts/refit; sustained departure and stop as in g1. Film both players and retain synchronized telemetry. Observer-only closeups may supplement but never replace reachable player views. Missing required view or action means unchecked and no overall pass.

Use existing video capture and event timestamps, not a new observer-camera system. Build only an event/view manifest and contact/state report: each obligation links to its time span, player ID, input receipt and physical outcome; machine health/manifest gates cannot be overridden. A separate reviewer sees video plus telemetry and obligations, but no actor PASS strings or practice-patch identities. One judgment table: yes/no/unseen per obligation with cited times, broken object and evidence; unknown cause stays unknown. Report captured frames and actual tokens/model seconds. Do not force two agreeing model calls or send every ambiguity to the user. Record human play and review attention in S6. Budget 35 min instrumentation, 25 min one full capture/review and negative controls, counting reused c1 work explicitly. This beats pure C3 at visual S2 coverage and avoids the new bot's S1 confound; S5 real inputs and S4 external health remain gates. It loses on human cost, which S places after error scores. If assembling the route/controls or required ten runs and mutants exceeds the cap, record failure; one successful film earns no 10/10 claim. This is evidence collection for this run, not a reference recording to imitate.

Across all four: the referee owns run scheduling. Reserve time for requested tests; don't spend the whole hour building. No method receives ten-run S1 or seven-mutant S2 credit from a single prefix demonstration. Share infrastructure only with its provenance and build cost visible; don't let a later package inherit an untested green claim.

## Disputes expected, and evidence that settles them

| Dispute | My position | Settling evidence |
|---|---|---|
| “Rig passed, so it is a game failure.” | Healthy transport does not validate policy or oracle. | A trace showing the specific erroneous test command/check, or a physical game defect under correctly delivered required-route input. Otherwise unresolved. |
| “Four identical retries show two runs per variant suffice.” | They show repeatability for X's particular setup, not all loads/starts. | Matched starts and launches under the same policy, with raw P2/cargo/heat/contact state; report all repeats, including disagreements. |
| “All variants fail means GAME; other driver passes means TEST.” | Neither implication follows. | Isolate the changed cause and show the physical mechanism, not just a flipped result. Two shared-bad drivers are a control against this table. |
| “C3 names all seven.” | P3 drift can be misnamed P1; geometry proxies can miss actual traversal. | Blinded practice results with separate caught/named counts, including P3 brake-on drift, real sill walking, actual intended placement and rendered hub/HUD views. |
| “The game's cross goal fixes the drive-off.” | Entering it proves repair; its done predicate proves only proximity (H). | A run stationary after repair and one that touches the goal then circles; the independent departure judge must reject both. |
| “Two visual judges settle an ambiguous frame.” | Correlated agreement cannot measure accuracy. | Clean/mutant paired images with frame IDs and object measurements, withheld labels, false alarms and named hits counted separately. |
| “The four trials can be complete in an hour.” | No complete actor is demonstrated; my G1 shares this problem. | Build minutes, exact completed route obligations, control-test results, ten achieved varied clean runs and mutant results all within the cap. Otherwise cap failure or explicitly partial result. |
| “Reference play is the cheapest oracle.” | Reference dependence is unnecessary and conflicts with M's recorded format. | Referee resolves the rule before any reference-dependent build. Evidence-only recording of actual trials remains required. |

Round-1 position: keep health, controlled causality, sensed input play and independent evidence review. Do not vote for unmeasured scores. The open risks are the full co-op actor's build cost and the evidence trial's missing operator, not a lack of more possible methods.
