# Final-method proposal — GPT, Stage 4 round 1

2026-11-06. **Proposal, not agreement or qualification.** Written independently of the other auditor's Stage 4 proposal. Read-only investigation at `g12 c85d4a4`; no game runs, code writes, commits or branch changes. Measurements below belong to the recorded trials, not to a fresh experiment. This file is my only write. The user's latest order supersedes the brief's old Stage 4 heading: agree, build, qualify, freeze, then examine the same implementation.

## 1. One method

**Bounded contract testing:** run real-input actors through explicitly bounded stretches, with read-only state/geometry contracts evaluated alongside them and an independent host supervising observation health, step deadlines and completion receipts. Use c2's seven contract families, repair their measured observation and hub holes, and use c1 plus g2 for health and evidence. Required observations or work missing means INCOMPLETE; broken observation means ERROR / TEST; an observed contract violation names the broken observable, with ownership unresolved unless supported. Every result states its scope, setup boundary and coverage. A passive recorder runs automatically, but a model reads it only after a non-pass requiring diagnosis; no model decides the next input. This is a detector with evidence, not a recorder mistaken for a detector and not a promise that the existing actor completes the whole puzzle.

### Parts and evidence for keeping them

Paths beginning `dev/` below mean `FindingNaresh/scripts/dev/`.

| Part | Source: trial, SHA, file | Why it belongs |
|---|---|---|
| External heartbeat, physics/world clocks, player presence, input/device evidence and explicit scenario plan | c1 `a6a412f`: `dev/RigBeat.gd`, `dev/PlayTest.gd`, `tools/rig/rig_watch.py`, `tools/rig_run.sh`; underlying code commits `920110d`, `3b96807`, `a106f90`, `57b8afd` | Referee: 10/10 healthy; T1–T3 3/3; N1–N4 4/4, at most 27 s. R8 permits reuse, carrying its limits. These establish health, not game correctness. |
| State/geometry contracts and short real-input stretches | c2 `04c3102`: `dev/C2Watch.gd`, `dev/PlayTest.gd:t_c2_more`; wrapper is source material only | Referee: 10/10 without fires, seven families reached each time; six practice bugs reliably caught and named. Reject its green-exit policy: T4 was a false pass and P6 passed twice. |
| Field/type validation, required receipts, bounded screenshot/phase supervision, verified termination | g2 `afb9e9b`: `dev/G2Rec.gd`, selected `dev/PlayTest.gd` hooks, `tools/g2/g2_watch.py`, `tools/g2_run.sh` | Referee: game-side stale field caught before driving; actual minimized-window N5 caught in 5.02 s, process gone. Builder's early-return control caught missing work. Do not inherit g2's 150 s startup allowance, unbounded baseline steps, wall-clock deadline implementation or INSTRUMENT OK as game success. |
| Passive event/phase recorder and offline causal discipline | g2 `afb9e9b`: `dev/G2Rec.gd`, `tools/g2/g2_table.py`, `g2_flight.py`, `g2_runup.py`, `g2_latency.py`; `trial_g2_spec.md` mechanism criteria | Recorded requests/raw/device/forces/contact histories expose alternatives. Both causal questions remained INCONCLUSIVE, including the historical 57 km/h event. This is useful evidence, not demonstrated automatic diagnosis. |
| Attachment-relative hub contract, aggregate verdict, scenario lifecycle accounting, monotonic host deadlines | **New**, specified here; adapt existing files rather than add a second framework | Addresses measured P6, false green, failed kill and “never ran” holes. These changes require qualification; no trial score is inherited for them. |

I concede c2 should be the detector's core because it caught/named six bugs automatically where c1 claimed none and g2 caught 0/2 by verdict. I retain my rejection of g1's driver: its clean qualification failed, including two off-ramp retries and a freeze requirement invalidated by measured settling. No new driver, motion planner, visual model judge, collision sweep or automated search belongs in this hour. Their benefits in this combination are unmeasured; I think their integration cost would displace the demonstrated repairs.

## 2. Each measured hole gets an owner and a consequence

| Measured hole | Frozen treatment proposed |
|---|---|
| c2 stale `_swim_to`: 733 script errors, silent G2 NOT REACHED, exit 0 | Every contract declares and validates required names, types, instance validity, finite values and output destinations before use and when instances change. Runtime access failures also invalidate it. Host tails current-run logs; any SCRIPT ERROR immediately vetoes success, even if the observer cannot emit its error. An unresolved lookup, malformed event, failed write or required no-hit measurement is ERROR / TEST, not an absent trigger. Invalid evidence cannot support a new game finding. |
| c1 missed a live-engine await stall for about 440 s; N5 | Each awaited phase has an OPEN with fixed duration before the await, a matching CLOSE, and required receipts. Host starts its own monotonic timer on receipt. Beats, log growth and repeated OPENs cannot renew it. An additional outer phase bounds a hang before an inner OPEN. Screenshot budget 5 s, noticed within one 0.5 s poll plus scheduling delay; preserve N5 evidence and check process gone. |
| P6 floated as well as sank; c2 caught 1/3 | Retain G3's below-ground check, add a hub-to-axle attachment residual in all three axes. Never invent an upper ground-clearance bound from a lower bound. See calibration below. |
| c1 STOP failed to kill; stuck scenario called “never ran” | Supervisor owns launched PID/process tree and records launch, start, end and required-work receipts separately. Print asked / started / ended / verified counts and IDs. Started without end is interrupted/stalled; no start is NOT STARTED; end without required receipts is INCOMPLETE. Preserve first cause. Check taskkill result and PID exit; retry once after a bounded check, then report KILL FAILED and prohibit another launch. Never wait indefinitely for the runner. |
| Driver misses under R12/R14 | Method owns scheduling and honest coverage, not an assumption that a driver succeeds. Keep the existing `t_ramp` as an attempted played route and `c2_more` as declared local coverage. A real-input retry that misses is a recorded outcome, not automatically a game defect or a test defect. Its mandatory landing-dependent work is INCOMPLETE. Local setup checks cannot turn that route green. No “try until pass”; preserve the first attempt. |
| g2 was not a detector | Contracts run automatically on every selected run and determine observed findings. Recorder begins at setup, continues through play/reset and conclusion, flushes as g2 does, and archives on every outcome. Host reads health/receipt events each run. A model reads slices only after ERROR, INCOMPLETE or a finding whose cause/ownership needs investigation; a clean scoped result needs no model reading. |

### Fixed operational limits

These are cost ceilings, not newly discovered physical laws. They are justified either by existing controls or by the explicitly stated qualification measurement below.

- Host polling: 0.5 s (g2). Progress report: every 5 s. No heartbeat during established play: 20 s (c1 N1 measured). Fresh beats but no physics: 10 s (c1). Unallowed pause with stopped world: 5 s; missing required player: two beats, about 1 s (c1). No save/reload or intentional pause is supported by this ramp profile.
- Per screenshot: 5 s (g2 actual N5). Simple setup await: at most 10 s; drive including reset: 46 s; separate reset wait: 6 s (g2's published arm budgets). Short door action: 4 s (c2). Each outer phase, including each helper containing nested waits, must be bounded; an entire episode deadline alone does not satisfy N5.
- Before the first heartbeat, the host requires an identified process and startup progress within **45 s**; a pre-heartbeat freeze must be reported within 60 s. This is a new operational ceiling. Builder measures both clean qualification startups. If either legitimately exceeds it, this profile is unqualified: report that fact, do not silently inherit c1's 300 s or g2's 150 s window.
- Full `ramp` episode cap: **240 s**; `c2_more`: **90 s**, including its local setup. New ceilings above reported 161–199 s combined c2 runs and roughly 55 s short run; verify actual individual episode times before freezing. Within episodes every phase has its own <=46 s cap, so an N5 stall cannot hide behind 240 s.
- Termination: check exit for at most 5 s after taskkill; one retry and another at most 5 s. Then explicit KILL FAILED. These are operational caps; g2 measured successful exits about 0.7 s after kill in its controls. Detection time and shutdown time are reported separately.
- Use host `time.monotonic()` for elapsed deadlines. OPEN communicates a duration and sequence, not a cross-process Unix timestamp. Require valid nesting/order and unique step instances. No real-time clock adjustment may extend a running deadline.

No new numerical gameplay limit is authorised by these time budgets. For other puzzle actions, use the frozen calibration procedure in section 5, not arbitrary copies of ramp durations.

## 3. Verdict vocabulary and authority

The engine observer reports measurements and rule events; the host reducer decides the automatic verdict using the frozen manifest. Neither reads injection flags, practice patch IDs or secret labels. A later auditor may diagnose ownership from evidence but cannot revise the frozen run's automatic catch retrospectively. Referee scores catches and correct naming.

| Word | Exact meaning |
|---|---|
| PASS | All mandatory scoped contracts and required work have valid observations, required windows completed, no violated contract, no health error, and all mandatory scenarios/steps completed. Exit 0 only for this result. Always append the scope. Never print a bare whole-game PASS. |
| GAME PROBLEM | Valid observation directly establishes violation of a stated game contract with its prerequisites demonstrated. Name the observable and location, not an unmeasured root cause. E.g. hub displaced from its axle, wreck top below water. Exit 1. |
| FINDING / OWNERSHIP UNRESOLVED | A valid failure/outcome exists but game versus actor/setup ownership is not established. No GAME label from “another driver passed,” a missed jump or a timeout alone. Exit 1 for a mandatory contract failure. |
| ERROR / TEST | Required measurement/plan/infrastructure is invalid: stale field, expression error, script error, write failure, malformed required event, demonstrated test input loss or invalid setup. Exit 2. A game-origin script error is not proof that game code is innocent: this word means the automated proof is invalid; root-cause ownership remains separate. |
| NOT REACHED | A healthy observer evaluated the trigger and found it absent; report evaluations and zero activated windows. Neutral for that rule, never counted as a passed check. If that observation was mandatory for this profile, also emit INCOMPLETE. |
| INCOMPLETE | Required start/end/work/window/checkpoint absent, or required work missed its deadline. Print missing IDs and last completed step. A live-step stall says TEST STALL / INCOMPLETE, ownership unresolved, unless test causation was measured. Exit 2. |
| NOT PROVEN | Outside the declared proof scope, including setup and visual/playability claims unsupported by a player-reached view. Not a verdict about whether that feature works. |

If several conditions occur, print them all with timestamps: ERROR / TEST vetoes PASS; missing work vetoes PASS; valid earlier game findings remain visible even after a later infrastructure error. Main status priority: ERROR / TEST, then validated GAME PROBLEM or unresolved contract finding, then INCOMPLETE, then PASS. Never discard secondary findings to force one ownership label. KILL FAILED is an explicit infrastructure error alongside the initiating cause.

The pad test profile declares its synthetic device and expected binding. A measured harness disconnect earns TEST, including T1. An unexplained PAD-to-KBM transition is input/binding failure with ownership unresolved; c1's blanket claim that it proves test causation is not adopted. Short/unobserved pulses are labelled UNOBSERVED, not successful receipts. Raw/device records are evidence of delivery, not evidence the body should have succeeded.

Expected compact output:

> RESULT: INCOMPLETE — mandatory played retry landing absent; game/test ownership unresolved. STATE CONTRACTS: 7/7 covered, no violations (setup coverage identified). HEALTH: valid. Asked 2 / started 2 / ended 2 / verified 1. Played-route coverage and exact NOT PROVEN list follow. Evidence: run directory.

This is deliberately a non-pass even if local state checks were clean. R12 permits neutral per-rule NOT REACHED; it does not authorise completion by substitution.

## 4. Ramp contract manifest: keep, change, drop, add

The seven families remain separately visible: **four generic families G1–G4 and three puzzle-declared families D1–D3**. G3 has two subchecks, so also report **five generic predicates plus three declared predicates**, not eight independently demonstrated general laws. Health/coverage rules are counted separately from game detectors. “Generic” describes the relation, not demonstrated portability. All c2 families were written with P1–P7 descriptions known (`trial_c2.md`).

| Family / decision | Frozen trigger, check and measured basis |
|---|---|
| G1 KEEP, strengthen coverage | Observe reset placement under the game's own reset; horizontal drift >0.30 m before input/brake release, maximum 5 s. Report full brake history. Clean 0.039–0.045 m; P1 2.71 m/5 s (referee also caught 0.42 m in 1.9 s); P3 0.58 m with brake ON. Brake OFF after reset names reset brake state; brake ON drift names no pushing cause. Mandatory short profile requires the full five-second hands-off window; an early release makes that observation incomplete. |
| G2 KEEP, validate dependencies | Swim mode plus real ray surface >0.30 m over water, river-distance excess >5 m beyond that player's bank target, lasting >1 s. Clean maximum excess -0.666 m; P3 far from river. Keep actual `_swim_to` relation; the earlier absolute river distances false-alarmed on legitimate 16.4 m bank climbs. Missing target/ray evidence required to evaluate is invalid observation. This rule does not prove the destination itself correct. |
| G3 CHANGE and ADD subcheck | Keep parked/frozen >=0.5 s, bottom vs ground < -0.12 m: referee clean worst tyre -0.072 (0.048 m margin), hub about -0.013. Keep lower test, **drop any claim that it establishes correct attachment**. Add attachment residual below. No upper ground threshold. |
| G4 KEEP, make coverage explicit | Wheel warning vs mesh/loose-wheel state, mismatch >0.5 s; loose wheel >1.5 m as c2. Clean zero mismatches (builder 666 looks), P7 wrong warning. A missing required HUD or blank warning when a warning is required is incomplete/observable mismatch, not a clean look; observer validates dependencies. Do not silently broaden to collision-wheel correctness: it still compares these stated sources, which may share a bug. |
| D1 KEEP | Fixed-solid intersection in c2's 1.0 x 0.7 x 1.2 m crate volume; trigger after hut built. Clean zero solids, rubble within the enlarged box; P4 two pieces in required volume. Same terrain/carryable exclusions, fixed box and shared window coordinate. Proves this volume only. No claim that a crate can actually be placed or used. |
| D2 KEEP | Wreck rendered top above/equal water. Clean +1.905 m, P5 -0.39 m; zero is physical waterline boundary. Validate nonempty mesh set and water/transform reads; missing wreck is not a clean zero-look result. Does not prove visibility from a player. |
| D3 KEEP, qualify blame | c2's declared setup: open door, P1 2 m outside; W-only walk across door line within 4 s. Clean reached hut z -1.39; P2 symptom stuck 0.28 m short. Require validated open-door setup and intended actor input receipts. If blocked, name “P1 did not cross this open doorway,” not automatically the sill as root cause. A demonstrated collision/geometry witness or subsequent diagnosis is needed for stronger naming. |

### New G3 attachment subcheck: clean calibration before freeze

Source inspection: `04c3102:FindingNaresh/scripts/vehicle/Camper.gd:_build_wheel_kit` creates BareHub at zero local translation and parents it to `_wheels[0]`, the suspension wheel. The rotating mesh holders are distinct; the checker must use the actual wheel axle, not a body-relative height or a stored screenshot. Contract: a hub rendered as attached stays centred on its owning axle in axle coordinates regardless of wheel phase, body orientation or suspension displacement.

Builder measures `axle.global_transform.affine_inverse() * hub.global_position`, its expected design centre (zero here), and residual norm on the **unchanged clean game** in the existing F1 wheel setup and each clean played landing reached. Record component extrema and maximum norm; verify the expected centre against the construction, not against the first observed hub location (which could itself be broken). No exact world-transform equality.

Frozen calibration formula: tolerance = clean maximum residual + **0.01 m**; the added centimetre is a proposed numerical reserve, not a measured game invariant. No shifting/recentring of expected attachment from sampled data. Require clean maximum <=0.01 m; otherwise stop and report this proposed relation unqualified instead of widening it. Freeze the resulting value, samples and source relation before the exam. Fire on residual > frozen tolerance after the same parked 0.5 s trigger, and record all axes. This adds no upper ground-clearance assumption. I think it catches a rotating 0.3 m off-axis displacement in every orientation; that prediction requires qualification and the referee's P6 reruns, not my source reading alone.

Use one test-only displaced-hub negative control to show this predicate can fail; it is a detector control, not real-path gameplay evidence. Builder must not inspect secret bugs. If the formula cannot qualify within the hour, report failed qualification; do not drop the repair while still claiming P6 solved.

### Required coverage and R5/R7 scope

Default plan is **`ramp,c2_more`**, one attempted full route plus short declared coverage. c2_more requires D3 walk result, input-driven slow miss, game reset, full hands-off G1 window, a valid G2 swimming evaluation, and G3/G4 observations in the declared F1 state; D1/D2 observations also mandatory. Count each family’s evaluated triggers, completed observation windows, findings and errors, by scenario and setup/played provenance. Required clean coverage cannot be satisfied by script errors or a screenshot alone.

The attempted ramp route must record its actual slow result/reset and retry result, and must reach its mandatory later work to pass that route. If it returns early on a miss, whole-command result is INCOMPLETE, even though c2_more later proves its own contracts. Do not stop the whole batch merely for that unresolved miss; finish independent short coverage within its own budget. Stop on infrastructure invalidation or a validated contract finding, and list all unrun work. One referee rerun for a NOT REACHED S2 rule remains R12's scoring allowance; retain both outcomes, no best-of result.

**NOT PROVEN:** a complete human solution; scenery/readability/fun; leg-up, toolbox, bolt and wheel retrieval by two players where setup is used; a player-visible wreck/hub without a reached player view; departure based on “closest ever” or distance from start; actual landing-only code when only F1 state was checked; the original 57 km/h cause; universal swim correctness; secret bugs outside these contracts; any full-game result. Observer shots supplement but cannot replace player views (R2). Existing inner PASS is advisory, never a new independent proof of departure.

**R14 remains open:** c2 achieved 65.9–67.0 km/h; g2 66.36–66.89; g1 did not qualify. No evidence supports calling that 61–68. The final method owns this reported coverage deficit. I do not propose rebuilding a driver or manufacturing variation with in-stretch state writes. Builder logs actual speeds, offsets and park poses and a spread shortfall; referee must record the unmet requirement if it remains unmet. This proposal cannot honestly promise full S1 qualification. That is an explicit risk for agreement, not something hidden behind R12. Any changed actor or spread policy needs agreement and clean qualification **before** freeze.

## 5. Transfer to the unseen puzzle, S7

Reuse unchanged: host lifecycle, clocks and polling, error veto, dependency validator, event schema, required-receipt reducer, termination verification, archive format, recorder plumbing and verdict meanings. Reuse applicable generic relation implementations without tuning their thresholds; mark inapplicable rules N/A with a reason, not PASS. A new puzzle is not required to have water, a hub or wheel HUD.

Builder supplies a small puzzle manifest: typed node bindings; setup boundary per stretch; an existing input-only actor or short new input-only sequence; required outcomes and independent measurable witnesses; expected actors/items; optional triggers versus mandatory coverage; player-view obligations; and puzzle-specific spatial relations. Count adapter, actor, predicate and fixture lines separately, plus hours and qualification runs. New predicates count as puzzle-specific adaptation, not secret-bug catches by unchanged generic rules. No late invention of predicates to match an observed exam failure.

Freeze the **adaptation procedure now**: define semantic contracts from puzzle requirements/code before measured test results; run three clean bounded stretches; for new action budgets use `min(45 s, max(5 s, 2 * largest observed duration + 1 s))`, rounded up to a whole second, and publish it before scored runs. Longer legitimate actions must be divided at independently evidenced checkpoints; if impossible within this procedure, report unsupported rather than tune during the exam. These are new operational formulas, not measured timing guarantees. No automatic statistical or physical threshold is learned from three samples. Geometry checks derive from built dimensions/design relations; any new numerical physical limit without clean justification is omitted with NOT PROVEN. Preserve ramp/generic thresholds as frozen.

After the second puzzle is revealed, write/freeze its adapter and clean calibration record before any scored broken run; the referee must keep that phase separate from bug feedback. **I think 45–60 minutes** for one puzzle with reusable helpers and a few local contracts; no measured S7 transfer exists. I think a whole new complex two-player actor could exceed an hour. If so, return supported local scope and failed/incomplete S7, not a claim of full transfer. This is a measurable limitation of the proposal.

## 6. Opus build list and qualification, within about one hour

Proposed names below are implementation targets, not files this auditor created. Start from agreed referee checkout; no game fixes. Hash game files before/after. Fetch trial code by SHA/file and merge hooks deliberately: **do not overwrite PlayTest.gd repeatedly from three trial heads**.

| Order | Work/files | Minutes, all “I think” estimates |
|---|---|---:|
| 1 | Inspect existing target, hash game, enumerate c1 seven reused files and c2/g2 dependency lists. Confirm source axle/centre relation first. | 4 |
| 2 | Reuse c1 `RigBeat`, rig wrapper/watcher and PlayTest hooks from `a6a412f`; reuse c2 `C2Watch` and `t_c2_more` from `04c3102`. Preserve current unrelated test content. | 5 |
| 3 | Integrate selected `afb9e9b` G2Rec/PlayTest hooks and host logic. Validate every contract dependency/write; live script-error veto. No pair drivers or causal experiment queue in default command. | 8 |
| 4 | Extend host in `tools/method/method_watch.py`: explicit manifest, ordered lifecycle/work receipts, per-phase monotonic deadlines, immediate no-growth/error checks, verified kill and bounded runner shutdown. Remove c1 “end means ran” reduction from final authority. | 8 |
| 5 | Change `dev/C2Watch.gd` G3 and rule outcomes. Add all-direction axle check, invalid-observation states, full-window receipts; add scenario-local requirements in PlayTest. | 6 |
| 6 | `tools/method_run.sh ramp` and `tools/method/ramp.json`: one external nonempty plan, one supervisor authority, unique run archive, combined verdict/exit, printed scope and cost. No conflicting c1/g2 kill owners. | 3 |
| 7 | Qualification below: compile, two clean full commands, one short control/calibration run, short health negatives; inspect event slices/stills, clocks and process exit. | 17 |
| 8 | Record exact source reuse/diffs, clean calibration, limits, run costs and unchanged game hashes. Produce implementation manifest for referee's freeze. | 3 |
| 9 | Reserve for one compile/integration correction, rerun only affected controls. | 6 |
| | **Total cap** | **60** |

Qualification is not ten S1 runs or the secret exam (R4). Builder must demonstrate:

1. All required c2_more families validly reached and clean; typed binding inventory complete; G3 axle calibration saved; both clean full attempted routes and their actual outcomes archived. A driver miss stays INCOMPLETE. Two clean attempted routes are not a promise of 10/10 reliability.
2. A removed/renamed required observer field yields ERROR / TEST before drive, not NOT REACHED or exit 0. Exercise C2Watch's actual dependency path, not only an unrelated recorder lookup.
3. Actual minimized-window screenshot stall or equivalent awaiting post-draw while physics runs: notice about 5–6 s after OPEN, explicit started/stalled label, process checked gone. No unbounded await in the selected path; source audit covers remaining helpers.
4. Early return with a mandatory receipt missing yields INCOMPLETE; distinguish never-started, started/no-end and ended/no-work in a small host fixture, without game run cost.
5. Test-only attachment displacement fires the new all-direction predicate. Clean control and negative get distinct artifacts; restore only the fixture, no game edits. No claim of practice-set qualification from this synthetic control.
6. Startup/phase timing and actual trace flush gaps measured; inspect at least reset, door and hub evidence. A dark/underground image is marked unusable; repair the observer angle once without moving a player's camera. Drawing failure remains bounded and cannot conceal its own failure.

The referee then briefly requalifies the exact implementation as requested: clean runs, **T4, N5**, termination gone. R1 scores remain “via c1/g2” where genuinely unchanged, not newly earned by integration. I recommend referee P6 repetitions as the smallest confirmation of the changed detector, charged separately from build qualification. At the hour cap stop and report partial qualification; no tuning loop or fallback presented as the agreed method.

Freeze package: method/adapter text, source SHA and game hashes, actual threshold values and clean margins, event/receipt schemas, verdict table, operational limits, supported setup boundaries and uncovered spread. Final exam uses that implementation. A later fix invalidates its freeze and must not be silently included in its exam score.

## 7. Per-run cost and the user's command

Proposed single command, from MPG_dev:

`bash tools/method_run.sh ramp`

It launches the fixed `ramp,c2_more` profile; users do not join three verdicts by eye. Unique output is under `MPG_dev/appdata/method/runs/<id>/`, including report, manifest, contract coverage, traces, logs and stills. Refuse another game instance in this copy. Keep game muted and behind user windows; no focus-taking recovery. No file is written to C:.

- **Measured precursors:** c2 full 161–199 s; short about 55 s. g2 baseline about 128 s, arms 41–52 s. G2Rec p99 0.62–0.92 ms **per row**, max 13–29 ms; three sampling phases mean that number is not total frame overhead. Instrumentation can alter frame pacing.
- **I think normal combined run: 3–4 minutes**, including startup/archive and full passive recording. Measure actual wall time and recorder/flush distributions; do not add historical c2/g2 times as if independent costs. Operational episode/startup caps can make a non-pass take longer; print expected and maximum reservation before launch.
- **Automatic per-run model cost: zero tokens, zero thinking minutes.** Host reads measurements every run. I think a clean report takes the user 10–20 s to read; not measured.
- **On a non-pass:** I think 2–5 minutes of auditor/model analysis for one incident, tokens measured by the actual reader and reported separately. No mandatory full-trace model pass on clean runs. The g2 builder spent about four minutes after its last run analysing a batch, with other analysis overlapping; that is not evidence of a fixed per-failure cost.
- Diagnostics are not automatic reruns. If the referee requests a cause study, use frozen g2-style mechanism criteria and budget its separate paired episodes; INCONCLUSIVE is allowed. Repeated diagnoses/fixes/reruns require reporting the loop, not concealing it in normal S6.

This avoids v3's documented 20–60 s of model thinking between every step (`notes/TESTING_METHOD.md`). Evidence recording is machine work alongside play; diagnosis is incident work after the automatic verdict.

## 8. Limits and predictions

**Evidence-backed limits:** c2's predicates share private state with the game; matching wrong values can escape them. D1 excludes terrain and movable objects. D2 is a height test, not readability. G4 is not independent wheel collision truth. The existing driver is unreliable, full 61–68 spread unqualified, and g2 did not settle its causal questions. R13 setup catches prove shared code paths only. No method tested S7. These are not erased by a new wrapper.

**I think** the resulting method will still miss bugs involving unseen mechanics, timing outside observed windows, a wrong shared reference point, or visually wrong but contract-consistent objects. It cannot judge fun. A coherent-but-wrong private field will pass presence/type validation. No claim of general secret-bug detection follows from seven practice-informed rules.

| Score | Prediction — every entry is “I think,” not a qualification claim |
|---|---|
| S1 | State predicates likely 10/10 at the observed speed band after clean axle qualification. Whole-command PASS likely only 6–9/10 with today's actor because mandatory route completion cannot be assumed; strict 10/10 and 61–68 spread may fail. Report these separately, never label the whole method S1 passed from state-only numbers. |
| S2 practice | 7/7 caught if the attachment predicate qualifies and required local states execute. Naming 6–7/7: door failure names obstruction region, not necessarily sill causation. Requires referee runs. |
| S2 secret | For a first set of five, perhaps 2–4 caught and 1–3 named; entirely uncertain because the bugs are unknown. Outside-scope bugs count not caught under R5. More detector predicates do not guarantee broader secret coverage. |
| S3 | 4/4 if stale-path validation and all error/receipt vetoes survive integration; ambiguous device origin remains explicitly unresolved outside the measured T1 harness disconnect. |
| S4 | 5/5, with N1 about 20 s, N2 about 5–6 s, N3 about 1–2 s, N4 at plan/end, N5 about 5–6 s for screenshot or <=47 s for the longest drive phase; process gone verified. Integration and pre-beat failure still require controls. |
| S5 | Pass for each declared narrow scope: input-only door and miss/reset stretches; no play claim from F1 or state/geometry queries. No full-route S5 proof borrowed from inner assertions. |
| S6 | 3–4 min normal run, no model loop, 60 min build including qualification. |
| S7 | Local-contract adapter probably runnable inside 45–60 min; whole-puzzle autonomous proof may fail the hour. Report actual hours/lines and unchanged-vs-new predicates. |

These predictions do **not** satisfy “Done means.” I recommend this as the evidence-supported combination to build, but would not sign a statement that the original complex-play reliability problem is already solved. The exam and unresolved reach/spread evidence must remain in FINAL.md. The decision order is respected: repair S4 and retain scoped S5 first; favour automatic catches over green instrumentation; disclose completion misses; then count cost and transfer.

## 9. Expected disagreement and my response

**Top expected disagreement (I think):** the other auditor may allow PASS when c2's local contracts are clean even though the played route missed, because c2 does not own that driver. My answer: R12 allows neutral rule coverage; R15 requires missing expected work to be INCOMPLETE. The final method schedules both parts and must own the aggregate claim. Keep a green local-contract line if deserved, but a local F1-built hub cannot certify a failed played landing. Measured false passes weigh more than alarms in the decision order. A narrow state-only product is defensible only with that narrow scope explicit and the unmet play/spread requirement carried into the final judgment.

Other expected objections (I think):

- **“Add only an upper ground-height bound for P6.”** There is no measured clean upper bound. The actual failure rotates with the wheel; axle-relative displacement tests where the hub belongs, with pre-freeze clean calibration. A two-sided world-height patch risks false alarms on slopes/suspension.
- **“Use g2 comparisons to fix the driver now.”** Its two questions stayed INCONCLUSIVE, and the referee added a miss with no ramp tap plus a successful on-ramp-tap run. Choosing 5 s settling from 3/4 versus 0/2 is tuning to counts without a measured mechanism. I do not concede a guaranteed fix from those data.
- **“A recorder on every run costs too much.”** g2 measured callback and archive costs; a new minimal recorder's equivalence is untested. Reuse the evidence-producing recorder first, measure combined overhead, then propose deletion if cost dominates. Do not create a per-run model reader to compensate.
- **“This is too cautious to win S1.”** Agreed that it may not win whole-command S1; the stated reason is measured actor unreliability. Relabelling INCOMPLETE as PASS would improve a headline without improving proof. A reliable actor remains a requirement to solve, not one I can invent evidence for in a proposal.

## Handoff into the eventual FINAL.md

After agreement/exam, FINAL.md still needs both auditors' reasons in their own words, actual exam scores, exact limitations, new-puzzle effort, command, a draft next TESTING_METHOD version and proposed skill lessons. This file is neither signature for the other proposal nor permission to adopt/merge. Suggested next method version: keep v5's recorded user walkthrough for presentation, add a separately named scoped-contract gate with explicit incomplete/invalid states; never claim today's full route is proved by these inspections. Qualification stills satisfy research R9; they do not repeal the user's later walkthrough-video rule.

Lessons for the referee to copy into project notes (this role may write only this deliverable): a healthy instrument is not a detector; an absent trigger is not a broken observation; an ended scenario is not completed work; attachment should be measured relative to its owning part; a frozen contract cannot absorb exam feedback; and a reach failure must survive aggregate reporting. Skill-library updates remain proposals for the user, not authorised edits here.
