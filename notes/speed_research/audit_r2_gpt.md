# Stage 2, round 2: GPT audit

2026-11-10. **Sign the four trial groups conditionally, not a claim that the method meets 75 minutes.** GPT specifies/audits; Claude alone implements and runs.

## Reading and evidence boundary

Read stage2_r2_task.md first, then scoreboard.md and R1 before the remaining permitted notes. Read only the allowed notes and FINAL.md lines 1-150. Additional source reads, in MPG_dev, were only `git show h1:FindingNaresh/scripts/dev/LiveControl.gd`, `git show 5f3e3e3:tools/run_test.sh`, and `git show 5f3e3e3:tools/method/prove_ghat.py`. An initial lookup of `tools/prove_ghat.py` returned path-not-found; the corrected path above succeeded. No game, code changes, other commits, referee files, personal folders/skills, or C: writes. This is the sole output file.

R1 persists: my previous exposure cannot be undone. The seven original holes are a **known set**, not a blind score; the referee's new secret set supplies the blind exam. I did not seek or encounter that new set. All estimates below are **I think**, not measurements. Source observations are identified separately from referee-reported results.

The referee corrects Claude r1's snapshot claim: h1 collects the world RAW and stores ghat/Problem script variables. Source confirms `SaveGame.collect(pt.boot, true)`, `_snap_live`, and `_restore_live`. `_snap_vars` stores supported plain script values and PlayerRig references; it is not a general serializer of object references, running coroutines, or engine internals. These omissions are **questions to test**, not demonstrated failures. A clean resumed suffix does not establish state equivalence. Points still lack a revision stamp.

## 1. Answers to every objection against my seven ideas

### G1: guarded resume

- **Concede cost:** a comprehensive 21-step snapshot/dependency framework is excessive before one boundary is tested. Start with immutable content provenance and one state comparison. Unknown producer dependencies invalidate conservatively; no claim that a guessed map is complete.
- **Concede savings attribution:** the original 25-35 minutes largely belongs to supplied h1 resume. Validation is a guard, not an additional speed saving. Record whole-workflow improvement against day 2 separately from incremental improvement over h1.
- **Rebut blanket pre-encounter-only restriction:** its cited evidence was baseline rewind/position-only restoration, corrected by the referee and h1 source. Permit an in-encounter boundary only after its comparison passes; refuse it when unqualified or affected by a producer change. That is a narrower claim than declaring every h1 point equivalent.
- **Adopt simple stamps:** HEAD plus content hash of dirty/untracked relevant inputs, walk, setup, snapshot schema, fixtures and engine/profile. HEAD alone misses dirty changes. Initially reject changed content; optimize dependency reuse only with evidence. Include snapshot identity to prevent a later replay silently overwriting the compared point.

### G2: bounded discovery

- **Concede restarts and idle decisions cost score:** one process may visit independent dev-menu sections, provided continuation is already declared and inspected. Stop actions on failure, secure evidence, and close the game before extended model reasoning. No mandatory new process per branch.
- **Agree independence is uncertain:** list upstream state each branch consumes. Unknown dependence means BLOCKED, not independent.
- **Partly reject repair outside the encounter as automatically safe:** location and using a game-owned setter do not prove reachable state. A declared diagnostic repair can be useful, but every dependent result stays diagnostic without a time expiry. Health/TEST/unexplained movement stops for diagnosis. No promise that one pass finds every break.

### G3: selective fixes and final suite

- **Concede the first broad discovery suite for this trial:** ordinary FAIL collection can expose scenario-only checks the authored walk never exercises. Keeping it is a conservative way to reduce late discovery risk. This changes my preferred scheduling, based on Claude's concrete coverage argument, not proof that its 20-minute investment always pays.
- **Withdraw the default 39-minute gross A saving:** with first plus final suites, A is approximately 59 -> 40 at 1x; additional savings need speed. My old 75-minute allocation was optimistic.
- **Adopt discovering the unstarted scenarios after a stall, with a guard:** stop and inspect first, then explicitly relaunch independent remaining discovery work. Preserve the stopped scenario/order failure. A merged discovery report cannot become a clean uninterrupted suite receipt. A same-process ordering bug still needs its own proof.
- **Agree receipts:** unknown/shared dependencies select all relevant scenarios (all seven when closure is unknown). Final acceptance cannot be assembled from stale greens. An end suite protects existing coverage; it does not guarantee discovery of all unknown holes.

### G4: short paired cases

- **Concede ranking and numbers:** no timing supports 15-22 minutes saved. The average scenario length does not establish how much prerequisite work is removable, nor the number of suitable reruns. Drop a general `--case` implementation from the top four.
- **Keep only the existing bench fallback:** after repeated failed fixes or a measured expensive prerequisite, specify one short real-input reproduction, preserving its producer-path check and final full scenario. Cost overlaps resume, speed and diagnostics; award no separate budget saving yet. An injected-state pass is diagnosis, not final proof.

### G5: qualified acceleration

- **Agree fixed-fps is the first candidate**, with engine flags before `--`, vsync disabled and no frame cap; drop time_scale as the first candidate. Movie Maker's existing fixed-fps use supports feasibility, not general equivalence or the achievable speed.
- **Concede my differential needs deadline stress:** clean/plant agreement on an easy 25-second stretch can miss an effectively relaxed deadline. Include a negative control whose event arrives just beyond its unchanged simulation-time deadline; it must fail at both rates. Preserve sampling coverage and physics resolution.
- **Rebut literal zero-get_ticks as the pass bar:** host health/reporting clocks should remain wall time, and indirect timers can evade that grep. Classify every reachable deadline, timer, input source and plant activation clock; no unclassified gameplay/assertion wall-time use on an accelerated path. Grep is an inventory aid, not equivalence proof.
- **Conditional on Claude's test-only Clock proposal:** unchanged 1x return values address my broad production-rewrite objection. They do not prove the fast branch equivalent, especially when absolute clock values cross save/load or subsystems use different clock origins. Qualify each affected path; otherwise keep it at 1x and revise the budget. No gameplay change solely to make a test pass.
- **Agree speed is the viability gate:** inspect it first. My previous incremental estimate could not support a confident 75-minute claim.

### G6: final matrix and causal proof

- **Concede omitted opportunities:** source confirms 11 proof groups and an import before each run unless NO_CHECK. Reusing a successful import in an immutable batch and exiting after complete detection can save time. The '~40 s' comment is not measured import time.
- **Agree new checks are proved immediately**, then all required plants at compatible final inputs. Late matrix failures still cost real minutes.
- **Retain causal objection:** source uses substring matches on FAIL lines. An active plant-set timestamp does not identify which of several plants caused a generic H-rule failure. Require exact check/scenario identity, activation/reach and necessary observation-window completion; ambiguous groups need isolation. Keep baseline process separation initially. A/B/A+B is a gate for any proposed additional batching, not proof that flags reset the world.

### G7: recording

- **Concede my categorical ban on joined acceptance videos:** the referee says joins worked on the ramp and acceptance is the user's decision. Snapshot uncertainty is a reason to qualify joins, not a reason for us to decide that preference.
- **Keep two separately costed options** below. A joined review video alone is not evidence of an uninterrupted successful walk; the clean-walk criterion needs its own explicit receipt.
- **Concede a separate preflight may not pay:** day-2 take failures are not attributed. Fold qualification into a short existing pilot when possible. Deadline-clock work does not certify sound, capture or joins. Keep required output quality; encoding after confirmed Godot exit costs zero metered game minutes.

## 2. Agreement with Claude's top four

| Claude r1 group | Agreement and remaining condition |
|---|---|
| T1 fast mode/game clock | Agree on priority, fixed-step candidate and clean/plant differential. Conditional on path-specific clock classification, deadline-negative control, rendered-check qualification and measured useful speed. Reject automatic authorization for every unrecorded domain. |
| T2 plant matrix/import reuse | Agree on early complete detection and one immutable-batch import. Retain exact causal evidence, cache invalidation controls and separate processes until additional batching is proved. |
| T3 first/final suites, map, receipts | Agree to first plus final for this trial; drop universal short cases. Restart unstarted discovery only after inspection; preserve original failures and refuse stitched final suite greens. |
| T4 discovery/resume/video | Agree on bounded diagnostic branches and minimal provenance/equality guard. Remove the outdated blanket ban on encounter checkpoints. Fresh and joined videos are user options; neither permits pretending repaired discovery was clean. |

This is the four-group plan I would sign. It does not assert Claude has already signed these amendments.

## 3. Top four as I would sign them

Each full trial starts at 5f3e3e3 in a referee-supplied sealed D: copy with explicitly supplied common h1 infrastructure, approximately two-hour wall cap. Referee owns meter and secrets. Claude builds/runs; GPT supplies written specifications for T3/T4. No silent import of later gameplay fixes. Trial deviations and setup are recorded.

| Trial and owner | Implementation/trial | Minutes/brief rows, I think; not additive |
|---|---|---|
| **T1 Claude-run: qualified speed** | Uncapped fixed-fps 60; classify clocks, preserve 1x semantics, qualify test-clock adapter and each fast domain. Baseline renderer/settings for unqualified visual checks. Final complete suite at 1x as well as qualified fast evidence. | On Claude's combined schedule, 99 -> 68, **31 incremental** across A/B/C/D/F at effective 2x. Zero for any unqualified domain. |
| **T2 Claude-run: proof completion/import reuse** | Successful import once per immutable input/cache state; early stop only after all expected detections are complete/persisted. Verify process gone. Full final matrix, matching clean controls; baseline process isolation initially. | D **27 -> 12 at 1x (15)** is a hypothesis including import saving. Shared import savings in A/C/F counted once in actual row ledger. Early stop alone: my earlier **4-10** estimate remains unmeasured. |
| **T3 GPT-specified, Claude-built: discovery/selection/receipts** | First broad suite, conservative file/state/check map for repairs, one final unshortened suite; receipt identity and explicit post-inspection remaining discovery. Short case only as measured bench fallback. | A **59 -> 40 (19)** at 1x. C **40 -> 15 (25)** is the combined workflow target, not a proven map-only saving; includes overlap with T1/T2/T4. |
| **T4 GPT-specified, Claude-built: bounded walk/resume/video** | Keep first-failure picture/state; declared independent diagnostic sections; minimal stamped points and equality gate; default h1 resume for repairs. Final clean walk/video and exit discipline; narrow event trace as needed. | Whole-workflow B **52 -> 15 (37)** includes supplied h1, not 37 new minutes from this trial. Increment beyond h1: **5-15 B**, uncertain. E **23 -> 8 (15)** and F **22 -> 9 (13)** are combined stretch allocations, not demonstrated standalone gains. |

### First experiments, pass and failure bars

Every cap is **summed Godot process lifetime**, including imports, startup, failed launches and shutdown; never 'four minutes of gameplay plus boot'. Stop at cap and mark INCOMPLETE/INCONCLUSIVE. Each experiment below is strictly under five game-running minutes. Claude/referee watches every few seconds, stops off-plan work and inspects pictures/logs. Offline controls cost no game minutes.

1. **T1 throughput first: cap 120 process-seconds.** Use the ghat_places candidate and heartbeat physics-frame delta versus wall time after readiness; retain all launch cost. No clock rewrite yet; this is throughput only, not accepted check evidence. Record cadence, achieved factor and background-window behavior. **Pass:** plausible effective speed supports the remaining budget; aim >=2x, not just a nominal flag. **Fail:** no acceleration, irregular physics cadence, throttle, or revised lower-bound budget >75. Stop/replan before broad clock work. A 1.6x result is not a budget pass.
2. **T2 import timing: cap 100 process-seconds for two unchanged imports.** **Pass:** successful equivalent import state and a material repeated cost (Claude's >=30 s criterion is a reasonable investment gate). **Fail/drop cache investment:** repeated import is already cheap, errors or cap. Then implement only immutable-batch reuse justified by timing, not a general cache. Offline changed/deleted/generated asset, .gd edit, engine/settings change or absent cache must invalidate; failed import must never mint a valid receipt.
3. **T1 equivalence gate: cap 240 process-seconds.** One short nonvisual domain at 1x/fast, clean/known baseline plant, plus deadline-negative evidence folded into those runs if possible. **Pass:** same named outcomes, event order, simulated timing within predeclared tolerances, plant activation, sample coverage and just-late deadline FAIL at both speeds; useful end-to-end speed. **Fail:** any weakened deadline/plant, unexplained divergence or unmet cap. Only this domain is qualified; later qualification costs count.
4. **T4 state/continuation pilot: cap 240 process-seconds**, specification in section 4. **Pass:** declared state comparison and negative control both work; diagnostic receipts cannot count as clean. **Fail:** silent omission, unaccounted timer/watch difference, mismatch or cap. Restrict reuse to a previously qualified boundary rather than masking a mismatch.
5. **T2 early-exit pilot: cap 240 process-seconds total.** Same short known group in full and early-stop modes. **Pass:** identical specific completed detection receipts, early exit materially faster, clean control holds, omitted activation evidence and an unplanted expected fault give NOT PROVED. Replay receipts offline for bookkeeping negatives. **Fail:** ambiguous attribution, missing required interval, early TEST/health fault ignored or no saving. Keep full execution if equivalence fails.
6. **T3 receipt/stop pilot: cap 240 process-seconds.** Offline local/shared/unknown file selection and stale/missing receipts; live short declared discovery sections with test-side stall in the middle. Stop/inspect, then explicitly run the remaining independent section within the cap. **Pass:** final section can be discovered, original stall persists, missing work is INCOMPLETE and no merged clean suite PASS is manufactured. **Fail:** automatic unexplained continuation, stale green accepted, unknown dependency selects narrowly, or cap. No full 20-minute run merely to test this bookkeeping.

Recording qualification can share the T4 pilot only if it fits its cap and uses final settings. Otherwise a separate <=150-process-second pilot is charged. These are ordered gates, not a requirement to consume every cap. Failed viability gates stop the expensive plan; trials still take turns under the referee's process.

### Joint budget and video choice

| Row | Brief | First/final plan at 1x | Hypothesis with qualified effective 2x |
|---|---:|---:|---:|
| A suites | 59 | 40 | 30: fast discovery, final 1x |
| B discovery/resumes | 52 | 15 | 9 |
| C fixes | 40 | 15 | 8 |
| D proofs | 27 | 12 | 7 |
| E video | 23 | 8 | 8 |
| F benches/killed | 22 | 9 | 6 |
| **Total** | **223 displayed; brief says 225** | **99** | **68** |

These are Claude's r1 allocations adopted as a **hypothesis**, with no independent timings. No row silently absorbs unlimited pilots. In the simplified model fitting these totals, cost is `37 + 62/s` minutes: 1.5x gives 78.3, 1.6x gives 75.75, and 2x gives 68. With zero extra cost the threshold is about 1.632x; extra probe/retry minutes raise it. This model is an approximation, not a measured decomposition. At 2x there are only seven minutes for costs not already included. Spending every pilot cap would exceed that allowance. Log actual meter usage, reuse valid pilot evidence, never subtract a pilot merely because it was diagnostic, and stop promising 75 if the revised ledger cannot reach it.

| Video option (user decides) | Evidence retained | Meter cost to compare |
|---|---|---|
| A: one fresh final take (my recommended default) | One continuous clean input walk also supplies the review video. | Measured full capture `V`; budget currently guesses V=8 min. Failed take costs remain charged. |
| B: joined take | Label every join, snapshot/revision and suffix scope. Compare boundary state; no diagnostic repair footage presented as clean. Separately retain a fresh clean real-input walk receipt unless the user explicitly changes that criterion. | Accepted capture segments `J` + discarded capture `W` + restart/restore `R` + any separate clean walk `U`; compare `J+W+R+U` with A's actual cost. Joining/encoding after exit costs zero game minutes. Do not set U=0 by assumption. |

The joined route can save re-recording prefixes after capture-only trouble, or cost more if it duplicates a clean walk. No fixed saving is evidenced yet. The user owns the preference; the referee cannot infer it from technical stitching success.

**Global trial PASS:** <=75 total metered minutes; all seven scenarios PASS at compatible final inputs; clean real-input walk; chosen video recorded and watched with sound/required visual quality; all seven known holes still found and individually checked; referee's new secret set judged blind; all 20 baseline plants plus every new hole's plant PROVED with matching clean controls. Referee reports both known and secret results separately; do not assume the secret set has seven members. No weakened/dropped check, deadline, observation window or required work. Missed required hole/plant, false PASS or excess time fails the method.

## 4. Cheap resumed-versus-uninterrupted comparison proposal

**One boundary, one short transition, one deliberately broken restore.** Claude builds this small probe, not a universal snapshot system. Use normal 1x settings first, same immutable code/walk/fixtures/engine, one naturally reached encounter boundary with Problem active and a nonzero timer. Prefer a boundary already reached during an allocated discovery pilot; do not obtain one from forbidden history or inject the expected encounter state.

1. Offline, list the fields the next 10-15 seconds consume, using game/check code as well as `_snap_vars`. Require ghat state, Problem phase/phase_t/relevant timers/suspicion/goal, actor transforms/velocities, player seats/held item identity, pot litres, van coolant/temperature and relevant input holds. List pending watches, their elapsed/remaining budgets, outstanding helpers/tweens/timers and relevant object links; explicitly report anything uninspectable. This independent list prevents the serializer comparing only the fields it already knows how to save.
2. At the normal step-start capture point, copy the original h1 snapshot to a unique immutable identity. Immediately collect a typed independent state read A0 at a defined physics boundary, before the next input; continue the unchanged next action for 10-15 simulated seconds, logging events/transitions and A1. Take a useful player/failure-angle picture. Quit; keep the original point safe from overwrite.
3. Fresh process, restore that exact point under the same inputs. Before replaying the action, at the same logical physics boundary collect B0; execute the identical input sequence and collect B1/event trace. Compare A0/B0 and continuation A1/B1 offline. Do not add a settling delay only to the resumed arm. Restore-time setup/spawn costs are measured separately.
4. Offline, deliberately alter a copied Problem timer or omit one required typed field from B's comparison evidence: comparison must FAIL/TEST, never skip the field. Also corrupt provenance and require rejection before resume. This checks the comparator cheaply; a later live corrupt-restore control is stronger evidence and must be costed before universal reliance.

**Compare rules declared before running:** exact categorical states, stable identities, inventory amounts and held controls; timer agreement within one 60 Hz tick (1/60 s) after aligning the capture instant; position/velocity tolerances fixed from existing check meanings, not widened after seeing a mismatch. If no defensible physical tolerance is available, report INCONCLUSIVE rather than invent one. Normalize process-local IDs to stable identity; compare remaining timeout duration, not raw absolute ticks. Check deadline outcomes as well as stored variables: h1 re-arming a prior watch with a fresh budget may disagree even when game state matches. Missing object/helper coverage remains explicitly NOT PROVEN.

**Cap:** 240 total process-seconds including natural prefix, imports, startup and exit across the two live arms. If that boundary cannot fit, reuse a legitimately captured ongoing-run prefix or report the pilot INCONCLUSIVE; do not teleport a producer into existence. Passing qualifies only the inspected boundary/profile/content and the listed observables. It is evidence of relevant state and short continuation equivalence, not proof that all engine state or every future suffix is identical. A mismatch disqualifies that point until explained; a final clean full-path walk remains required under the current contract.
