# Stage 1: seven blind speed ideas — GPT auditor

2026-11-10. Research only: no game launched, no game/test code written. This is the sole output file.

## Evidence and scope

Read in the requested order: `stage1_task.md`, `SPEED_RESEARCH.md`, `TESTING_METHOD.md`, and the first 150 lines of `method_research/FINAL.md` (stopped before the forbidden #6 addendum). Then read the specified files at `5f3e3e3`, the tools tree, and only the allowed `h1` tools. Additional baseline-only reads: `tools/method/prove_ghat.py` and `tools/method/method_watch.py`. No other auditor's ideas, forbidden notes, referee files, later history, or personal skill libraries read. No benchmark secret hole was encountered or identified as such. The baseline design and plant definitions name already-known faults; I do not treat them as the seven secret holes.

Observed in source, not measured in a run by me:

- `GHAT=scenario,... bash tools/method_run.sh ghat` already selects scenarios; ghat defaults to profile k3. The printed 3–4 minute estimate is ramp text, unsuitable for estimating ghat.
- `prove_ghat.py [group ...]` already groups multiple plants and checks named failures. Merely proposing grouped plants is not a new saving.
- `method_watch.py` uses host monotonic deadlines, completeness/health evidence and typed-observation failures. It can continue collecting ordinary FAIL conditions, but stops on stalled/unsafe test execution.
- LiveControl documents a save point per step; `h1` selects the failed step by default. A fresh launch is still needed after a game-code change. The method notes report approximately 40 seconds for a restart; I have not measured that on this benchmark.
- The 21-step walk has two searches bounded at 190 seconds each, spring trips bounded at 120 seconds, and an explicit cooling wait. These are bounds, not measured durations. They are not permission to shorten the game's search/cooling behaviour.
- `record_walk.sh` records a fresh walk, waits after DONE/FAILED, quits, then encodes. Its encoding time is not game-running time if Godot has actually exited.

Every saving and build estimate below is **I think**, unless explicitly attributed to the brief or notes. Build minutes mean Claude's implementation effort, excluding game-running experiments. No proposal is yet evidence that 7/7 holes will be found.

## 1. Resume repairs from a validated causal boundary

**Concrete mechanism.** Use `h1`'s `bash tools/play_walk.sh ghat` for repair trials, `--from "<exact step name>"` when the cause starts earlier, and `--fresh` for final acceptance. Add test-side metadata to saved points: source revision, walk hash, schema, dependencies and setup provenance. Validate the state needed by the next action: actor/vehicle transforms and velocities, seats and held objects, encounter phase/timers, input releases, water/temperature, marks and outstanding watches/helpers. These are requirements to inspect, not assertions about what today's save captures. Invalidate a point when a changed dependency affects its producer; a checkpoint created by broken code is not automatically trustworthy after the fix. Resume from an earlier verified producer or fresh setup in that case. Never label restored setup as input-path proof.

**Rows/minutes.** Row 2, 52 minutes of walk trials: save **25–35 minutes, I think**. The h1 comment attributes about 40 lost minutes to restarting trials; that is historical testimony, not a measured saving from this proposal. Row 3 may also benefit but is allocated to idea 4 to avoid double counting. Keep one complete fresh input walk.

**How it fails.** Restoring an already-invalid state can hide the cause; omitted clocks, tasks, physics contacts or input holds can produce false alarms and blame a game fix. Persistent last-failure files can select the wrong revision. Any validation failure means TEST/INCOMPLETE, never automatic PASS. A final fresh run is required even if every resumed suffix passes.

**Build/risk.** 10–20 minutes to wire the existing h1 commands and basic provenance; 30–60 more if meaningful state validation is missing. No production behaviour change; medium risk in test restore semantics.

**Smallest experiment.** Claude uses one naturally reached, short spring interaction boundary. Compare fresh-producer versus restored-point execution, including held pot, litres, seats, timers and released input. Deliberately corrupt one metadata dependency and require rejection. Cap the two live segments at 60 seconds each plus startup/shutdown: **<4 minutes summed game time**. Equality on this segment qualifies only this boundary, not every point.

## 2. One discovery pass, with explicit blocked branches and repairs

**Concrete mechanism.** Add a discovery-only mode to the live walk runner. On an unexpected outcome, stop actions immediately, capture state and a picture, and record the failure. Continue only through the existing real-input path if safe. Otherwise the builder declares the next branch BLOCKED, records exactly which setup is being substituted, checks the proposed state, and explicitly restarts discovery at an independent branch. For example, the authored walk has note, hide, cap, spring and final marks sections: a blocked earlier section need not prevent inspecting a later independent interaction. A substituted branch is diagnostic only; its missing upstream checks stay INCOMPLETE. Health errors, script errors and unexplained movement stop the run for diagnosis. This is not unattended continuation past a failure.

Record each distinct symptom, expected design behaviour, earliest divergence, dependent checks and shot. Fix the collected independent causes together, then use targeted proofs and one fresh walk. Do not infer independence merely because two failures have different names.

**Rows/minutes.** Row 2: **15–25 minutes saved, I think**, mostly overlapping idea 1. Row 6, benches/killed/ramp repeats: **3–6 minutes, I think**, by diagnosing several reachable faults in one controlled pass. No credit for reducing the number of distinct checks or bug plants.

**How it fails.** State substitution can erase the hidden fault, manufacture secondary faults or hide an ordering bug. Logging seven symptoms is not finding seven causes. Freeze the untouched first-failure evidence; never claim a patched-through walk is clean. Final acceptance and plants must use the genuine path in the declared scope.

**Build/risk.** 25–45 minutes of runner/report work; no shipped game changes. Medium/high risk of dishonest coverage if discovery and acceptance receipts share a verdict.

**Smallest experiment.** Use a *known baseline plant*, not an invented secret, at one short interaction. Require the original named failure, an immediate stopped action, an explicit blocked dependency and a separately identified diagnostic branch. A deliberately omitted action must remain INCOMPLETE. Cap at **3 minutes including startup**. Success proves bookkeeping, not unknown-hole detection.

## 3. Defer repeated full suites; use a conservative change-to-check map

**Concrete mechanism.** Create a test-side dependency table from changed code and each check/work/rule in the frozen manifest to scenarios. Use the existing `GHAT=...` selector for repairs; run the directly affected scenarios, their known consumers and relevant plants. Shared input, save/load, vehicle, clock, reset or judge changes conservatively select all affected scenarios; unknown mapping selects all seven. A receipt records revision/content hashes, manifest hash, scenario/profile and fixtures. Never combine green receipts across incompatible revisions to manufacture the final suite result.

Discover through the full authored walk and design review while tuning; run **one final all-seven suite** at the final code/check revision. Any subsequent relevant change invalidates that final result. Do not repeatedly rerun all seven simply because a local repair passed. The existing selector alone does not make dependency selection sound.

**Rows/minutes.** Row 1, 59 minutes: replace three full suites with one, removing **about 39 minutes gross** from the brief's ~20-minute runs. Allow 4–9 minutes of targeted work displaced into rows 3/4: **30–35 minutes net, I think**. Row 3: a further **5–10 minutes, I think**, only where previous reruns included unrelated scenarios. Idea 4 overlaps this part.

**How it fails.** An incomplete dependency graph misses a shared effect; hashes prove identity, not independence. Test/judge changes can invalidate every plant proof. Keep explicit unknown dependencies, the final complete suite and every old check. An early broad suite that reveals otherwise unseen faults was useful discovery: its removal must be compensated by deliberate walk/design exploration, not assumed harmless.

**Build/risk.** 20–35 minutes for a conservative static table and receipt validation. Low game risk; medium coverage risk. Start coarse, splitting only with evidence.

**Smallest experiment.** Offline, mutate the proposed dependency table inputs: a local observation change, a shared-input change and an unknown file must select the declared closures (last two broad). Claude then runs one short selected scenario, verifies its required receipts, and deliberately removes one receipt to require INCOMPLETE. **Game cap 2.5 minutes**; if it cannot complete, stop and report the experiment inconclusive rather than extend the cap.

## 4. Short, paired reproductions at real setup boundaries

**Concrete mechanism.** Introduce a *proposed* runner selector such as `--case <id>`; it does not exist today. For an issue, define its minimal real-input action, unchanged assertion/rule, preconditions, setup source and affected end-to-end checks. Use a genuine dev-menu reset and a validated boundary from idea 1 rather than replaying unrelated road travel for each repair. Where save restoration is incomplete, run the actual producer path. For physical reachability, visibility, timing and save/load checks, include that very behaviour in the reproduction: teleporting to a target cannot prove that a player reaches it. Keep any original setup/input distinctions explicit.

Run paired clean/plant cases using equivalent declared setup. Keep all original full-scenario checks in the final suite; the small reproduction supplements them while fixing. This is also a bounded gym after repeated failed fixes: change one suspected cause at a time, capture the wrong moment, stop speculative full replays.

**Rows/minutes.** Row 3, 40 minutes: **15–22 minutes saved, I think**; row 6, 22 minutes: **4–7 minutes, I think**. Overlaps ideas 1 and 3; not additive. Savings depend on how much of each scenario is prerequisite versus the actual tested behaviour, which has not been timed here.

**How it fails.** A convenient injected state may be unreachable or omit the fault. A local test can blame the assertion when the producer was broken. Require setup assertions and retain an unmodified producer-path check; reject incomplete restore rather than filling missing fields until it passes. No production state shortcut goes into the game to accommodate testing.

**Build/risk.** 30–60 minutes for the first useful case family; stop building a general snapshot framework if this becomes the cost centre. Medium risk confined to test setup.

**Smallest experiment.** Claude takes an existing short interaction check and its existing plant, executes clean then planted case through the same setup, and verifies the *specific assertion*, not merely a nonzero exit. Inspect one picture per case. Budget **two 70-second segments plus startup, <4 minutes summed**. Inability to establish preconditions within that budget is a negative result for that candidate boundary.

## 5. Accelerate simulation only where differential evidence permits it

**Concrete mechanism.** Test a runner-only acceleration option first on nonvisual, time-consuming logic stretches. Candidate A is test-controlled `Engine.time_scale`; candidate B is an uncapped headless/fixed-step execution mode. These are experiments, not claims that a flag makes this project faster. Do not assume `--fixed-fps` alone yields faster physics or equivalent input delivery. Keep physics step size, input edges, accumulated game-time waits and observer sample density explicit; scale tick frequency if needed to retain the original simulation resolution. Judge host health against real wall time and gameplay deadlines against their original game-time meaning. Never simply divide every deadline by the requested speed.

Stop acceleration before a rendered visibility check, aim/reach test, or the final 1x input walk/video. Inspect actual supported engine flags locally before implementing. Record achieved simulation-seconds per meter-second, not the requested multiplier.

**Rows/minutes.** After removing repeats, rows 1/3/4/6 still contain real waits. **15–30 additional minutes saved, I think**, if substantial portions achieve >2x without altered semantics; **zero** if equivalence fails. Excludes the 1x video. This could be necessary to reach 75 minutes; the low-risk ideas alone do not prove that target.

**How it fails.** Bigger effective physics steps change collisions/steering; real-time timers and input holds diverge; sparse observations miss a brief invariant break; headless removes the visual evidence. Accelerated clean+plant agreement is necessary but insufficient for unknown faults. Keep all checks, thresholds and required sample coverage; unsupported domains remain at 1x. No calibration may turn a real failure into PASS by relaxing a threshold.

**Build/risk.** 45–90 minutes, potentially more; high method risk, no intended production change. Do not commit to this investment before a tiny differential test.

**Smallest experiment.** A 25-second nonvisual segment, at 1x and candidate 2x, clean and with one known plant: **four capped runs, total meter cap 4 minutes**. Compare action/event order, named outcomes, state deltas, observer coverage and actual speed. Stop at the first mismatch. Passing authorizes a larger trial on that domain only; it does not certify all seven scenarios.

## 6. Prove plants once at the final revision, with causal attribution

**Concrete mechanism.** Preserve `prove_ghat.py`'s baseline groups, then audit their assertions and masking assumptions. Schedule one final complete proof matrix for all 20 existing plants plus each newly discovered hole; use targeted proofs during repairs instead of repeating unchanged groups. Reuse a prior proof only if game/check/plant/setup/judge dependencies match; otherwise rerun. Check each expected identifier in structured evidence, the plant's active window and a matching clean control. A substring in an unrelated FAIL is not sufficient attribution. Every required plant remains an explicit row, including plants grouped into the same process.

For new groups, batch only demonstrably noninterfering plants. Conflicting plants use separately reset cases with observations/helpers/fixtures cleared; if safe reset cannot be shown, separate processes. Do not layer multiple faults in one causal chain and count one downstream FAIL as proof of them all. Changes to proof tooling require revalidation of all affected groups.

**Rows/minutes.** Row 4, 27 minutes: **6–12 minutes saved, I think**, chiefly removing redundant proofs and setup. Existing grouping already earns the baseline saving, so I do not claim 27 minutes can collapse just by grouping. Idea 4 and acceleration overlap this estimate.

**How it fails.** One plant masks another, sticky fixtures contaminate clean control, stale evidence survives code changes, or matching failure text proves the wrong cause. A blanket FAIL never proves the matrix. Missing/ambiguous causal evidence means NOT PROVED; all final plants must still be caught, including the old 20.

**Build/risk.** 20–40 minutes for exact receipt matching/invalidation; 45–75 if safe per-case resets are required. No production change; medium/high false-proof risk.

**Smallest experiment.** Pick two known short-case plants claimed to be independent. Run A alone, B alone, then A+B; require the same individual check failures and completed activation windows, with no missing required work. Cap each segment at 45 seconds plus startup: **<4.5 minutes summed**. If the precondition path cannot fit, choose a shorter pair or reject this grouping experiment.

## 7. Qualify the recording route once, then record the final fresh walk

**Concrete mechanism.** Add a *proposed* `record_walk.sh` preflight/short-smoke mode that checks destination space, capture settings, readiness, sound and a small encoded clip. Wire the live walk's streamed PASS/FAIL and process-health monitoring into recording rather than suppressing the client output. Stop immediately on an off-plan take, capture failure evidence, then repair via ideas 1/4. The final acceptance video always starts fresh, uses 1x game-time behaviour and the required real inputs, and is watched. Do not stitch restored success snippets into an apparent clean walkthrough. Keep baseline declared setup cuts visible in the report; do not count them as proven movement.

The final recording can also be the final clean authored walk if its input/observer coverage is equivalent. Movie Maker can alter timing: qualify its deadlines without relaxing gameplay assertions. Quit and verify Godot gone before encoding and human review; a failed partial clip is diagnostic, never the completion video.

**Rows/minutes.** Row 5, 23 minutes including encoding: **6–12 game minutes saved, I think**, by avoiding repeated long takes and idle shutdown. Exact removable game time is unknown because the row mixes encoding with live capture. Encoding faster after Godot exits earns **zero** scoreboard saving. Any eliminated duplicate clean walk belongs to row 2, so avoid counting it twice.

**How it fails.** Normal-play success can fail under recording; muted playback can mask missing captured sound; edited cuts can conceal failures; low resolution can weaken visual checks. Keep the required output quality and visual checks; watch the finished file with timestamps, both players' views and sound. A take that merely reaches DONE is not sufficient.

**Build/risk.** 15–30 minutes; low game risk, medium runner/recording risk. Existing `FN_RECORD=1` is explicitly unsupported in `method_run.sh`; this proposal does not pretend otherwise.

**Smallest experiment.** Record a 35-second real-input interaction clip with the same final settings, watch it, then record a deliberately failed 10-second interaction and require prompt stop with a failure receipt and no accepted-video label. **Total game cap 2.5 minutes**, encoding only after verified exit.

## Ranking and first trial

1. **Idea 1, validated resume:** largest directly evidenced avoidable repetition; h1 already supplies the command path.
2. **Idea 3, selective repairs and one final suite:** about two full suites are avoidable, provided discovery remains deliberate.
3. **Idea 7, recording qualification:** cheap, prevents another long failure late in the process.
4. **Idea 4, short paired cases:** useful once actual repair bottlenecks are known; avoid a general framework first.
5. **Idea 2, bounded discovery:** potentially many faults per pass, but strict separation from acceptance is essential.
6. **Idea 6, final proof scheduling:** preserve all plants; baseline grouping means less new headroom than it first appears.
7. **Idea 5, acceleration:** highest uncertainty; a cheap experiment may promote it, but no equivalence assumed.

**Trial first:** idea 1's <4-minute state/provenance experiment, built and run only by Claude. Then combine 1+3+7 in the full benchmark replay, retain the complete final suite and plant matrix, and report actual discovery coverage and meter time. Run idea 5's tiny differential experiment early if the measured budget still cannot reach 75; do not spend an hour implementing it blind.

### A budget hypothesis, not a forecast

Savings above overlap; adding their maxima is invalid. The following is a stretch allocation for a combined method, with every row retained as work. These are **I think** targets, conditional on useful short boundaries and qualified acceleration; they are not measured outcomes or a claim of 7/7 discovery.

| Baseline row | Baseline, brief | Target game minutes | Main means |
|---|---:|---:|---|
| Full seven-scenario clean suites | 59 | 20 | One final unshortened suite, idea 3 |
| Walk trials/live measurement | 52 | 13 | Resume/discovery, ideas 1/2; final clean walk included in recording row |
| Single-scenario fix verification | 40 | 13 | Short cases and conservative selection, ideas 3/4 |
| Plant proofs | 27 | 15 | All plants retained, ideas 4/6; qualified acceleration where necessary |
| Recording takes/encoding | 23 | 8 | One qualified final fresh recorded walk, idea 7; encoding excluded after exit |
| Benches/killed/ramp reruns | 22 | 6 | Bounded diagnosis and stop rules, ideas 2/4 |
| **Total** | **223 displayed** | **75** | **Unproven; no allowance for expensive surprises** |

The brief calls the baseline 225 minutes; its displayed rows sum to 223 (likely rounded). I use the stated <=75-minute gate, not a redefined one-third. In particular, the eight-minute final recording target may be unrealistic for the full 21-step walk; measure it. If it needs 12, another row must save four, without weakening coverage. A full benchmark trial, not this budget, decides.

**Reject as a game-minute saving:** two concurrent games. The meter sums process lifetimes, so equal work in parallel saves wall time only and may add contention/false alarms. Existing wrappers also refuse a second Godot and the watcher has global PID assumptions; simply removing that guard is unsafe. Work offline while a watched run executes, and terminate live games before lengthy thinking/encoding, but never count that as omitted test work.

Final acceptance stays: all seven scenarios PASS, clean fresh real-input walk, finished video watched, all seven hidden holes independently found and checked, and every original/new plant PROVED at compatible final revisions. Missing any of those is a failed method even at 74 minutes.
