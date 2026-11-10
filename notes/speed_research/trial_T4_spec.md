# T4: independent discovery sections, guarded h1 resume, recorded video

GPT auditor specification, 2026-11-10. Proposed, unbuilt and unmeasured. Claude alone implements/runs. GPT writes specs only. No forbidden file opened and no game run in this task. Companion: `trial_T3_spec.md`, including the complete replay playbook and shared identity/lane rules.

## Scope, evidence and builder files

Use only referee-supplied MPG_speed_t34 / speed-t34 from speed-base. Nothing on C:, no merge/push. Qualification changes tools/test code only, never gameplay/assets/scenes or `core/Plant.gd`. The later replay's actual game fixes are a separate Claude/referee responsibility, not permission for the T4 tool builder to repair baseline holes now.

Observed in speed-base: `LiveControl._snap_vars` omits non-plain Object fields except PlayerRig references. `_snap_live` records Ghat and its Problem creature variables/transform, not its children. `SaveGame.apply` zeros van velocities and turns the engine off. `_run_walk` waits one second after restore before actions, and re-arms earlier needed watches with a fresh limit; snapshotting after this wait would conceal an immediate restore difference. `_item_ms` is an absolute old-process stamp used against Hearing event stamps. These are concrete missing-state risks, not proof that every boundary fails. `record_walk.sh` already resumes/joins takes, but its part ownership uses a last-failure step, not a full content identity; log frame numbers use `Engine.get_frames_drawn()`. With 25-fps movies, do not confuse drawn frames, physics ticks and wall seconds.

Allowed additions:

- `tools/live/ghat_sections.json`: declared section graph and real producer/setup paths.
- `tools/live/walk_receipts.py`: immutable point/take identity, coverage and join validation; import T3 identity logic rather than duplicate it.
- `tools/live/resume_gate.py`: independent comparison/reduction of field inventories and three-layer evidence.
- `FindingNaresh/scripts/dev/ResumeProbe.gd`: test-only expanded observation/restore adapters, boundary probes and off-by-default negative controls.
- `tools/live/t4_qualification.py`: offline and capped live controls.
- `notes/speed_research/trial_T4_build.md`: qualification report and declared unknowns.

Allowed modifications: `FindingNaresh/scripts/dev/LiveControl.gd`, `PlayTest.gd`, `tools/live.py`, `tools/play_walk.sh`, `tools/record_walk.sh`, and `tools/live/make_ghat.py` / generated `ghat.json` for metadata, watched cancellation and guard integration. Do not remove/soften baseline actions/assertions/deadlines. Replacing a declared placement cut with a real walking path adds coverage; it must preserve its original interaction and be reported. Use tools under D: for temporary video/cache files. Do not regenerate a planted/hand-edited walk on launch (`NO_MAKE=1` remains supported and its bytes are stamped).

Required new command contract, Git Bash at trial root:

```sh
python tools/live/t4_qualification.py --offline
python tools/live/t4_qualification.py --live --cap-wall-seconds 840
python tools/live/resume_gate.py inventory --walk tools/live/ghat.json
bash tools/play_walk.sh ghat --discover --sections tools/live/ghat_sections.json --fresh
python tools/live/resume_gate.py compare --point <immutable-point-id>
bash tools/play_walk.sh ghat --from "<exact step name>" --require-same <point-id>
bash tools/record_walk.sh ghat --fresh
python tools/live/walk_receipts.py verify-video --walk ghat --take <take-id>
```

Default h1 repair resume remains convenient but must pass the same gate. On absent/stale/DIFFERENT point, print the reason and refuse **before inputs**, then recommend the exact earlier eligible producer boundary or `--fresh`. No silent restore, fallback to an arbitrary same-name point, or automatic replacement of immutable points. Offline commands launch no Godot. Qualification failures are TEST/INCOMPLETE, not gameplay PASS.

## Discovery is note-and-repair across independent sections

Write the section graph before discovery: exact original step names/indices, actions, expects/needs, allowed captures, input state, consumed/produced state, setup provenance and downstream consumers. Baseline natural groups are steps 1-5 approach/note, 6-9 boiling/hiding/search, 10-12 cap/return search, 13-18 spring/cooling/refill, 19-21 departure/marks/credits. **These groups are sequentially dependent, not automatically independent.** A name or dev-menu location does not prove independence.

Admit a diagnostic section only if its full real producer prefix from a clean F1 puzzle reset is declared, or a separately qualified SAME point supplies exactly its prerequisites on identical producer content. Initial recommendation: use natural groups for reports but allow only reset-based independent paths proven from code; expect some BLOCKED sections. Do not invent cap/temperature/held-item/encounter values to jump over an earlier failure. A whole replayed prefix is charged; if it cannot fit the budget, mark the consumer BLOCKED and report the discovery limit.

On first failed action/expect/watch: immediately cancel pending input actions and spawned test helpers, release all keyboard/mouse/pad holds (audit complete input inventory, not just today's `_release` list), freeze the failure evidence, capture the current picture/state within the existing bounded shot budget, write BROKE with original text, producer/section/point ID and earliest event. Cancellation must prevent an awaited helper from later resuming and sending another input. Stop the process before lengthy diagnosis. Mark dependent watches/actions BLOCKED with the missing producer, never one independent bug per downstream red line.

After inspection, explicitly launch only a predeclared independent section and preserve the original failure report. No patching state mid-walk; no automatic repair-on-FAIL; no "after ten seconds this is clean". Every discovery line stays DIAGNOSTIC. If a reusable process is used, require a proved full reset that cancels helpers/watches and leaves no persistent state; otherwise a fresh process is the default. Script/health/unexplained movement failures stop rather than branching around them. Fix observed causes together during replay, prove each separately; discovery bookkeeping cannot certify that all unknown holes were found.

## Point identity and content changes

Each immutable boundary point has walk/generator/step/action/expect IDs, setup path, snapshot schema, source/dirty/untracked input hashes, engine/settings/profile/fixtures, RNG ownership where applicable and test/tool identity. Record actual process origin for wall stamps separately from semantic ages. Use T3's pre/post input identity and lane isolation. A last-failure file only points to an immutable ID; it cannot overwrite qualified state.

Default after a source change: reject old points. Reproduce the prefix under the new code or use an earlier SAME point qualified under the new identity. Do **not** edit stamps to make an old point compatible. Cross-revision reuse requires an explicit evidenced proof of unchanged producer dependencies and a new equality qualification; this first trial should avoid implementing that optimization. Fixture points never become clean points. A successful suffix is repair evidence only; it does not prove the skipped producer path or a fresh clean walk.

## The three-layer equality gate

Gate only boundaries actually used for repair/join. A failure means DIFFERENT or UNQUALIFIED with fields/reason; no resumed PASS credit. Do not attempt a general save-system rewrite. If an unsafe kind cannot be restored faithfully with a small test-side adapter, reject the boundary and use a fresh real producer path.

### Layer 1: offline inventory, before spending game minutes

Inventory SaveGame RAW fields versus every live script property and relevant engine state on Ghat, Camper/VanAttack, Problem/Creature, players, held/stowed/carryable items, Naresh if present and reachable child nodes. Include static/global state that affects the path (Hearing event queue/IDs, creature globals, story/map/mood), object relationships/Callables, timers, animation/audio/pose state, RNG, physics transforms/velocities/sleep/contact state, active watches and spawned helpers/coroutines. Classify each: saved/restored, deterministically reconstructed with evidence, irrelevant to this boundary with reason, or unsupported. Unknown/unsupported relevant field **blocks eligibility**. A variable absent from `_snap_vars` is not automatically irrelevant.

Use stable node/role IDs and reference edges, not transient instance IDs or creature array ordering. Live observation must independently read omitted fields; comparing two copies of the old partial serializer would pass the same omission twice. Add a runtime inventory check to catch new/missing properties/nodes and refine the static list. No blanket exclusion of all children/objects/visuals.

Specific required treatment:

- Van: snapshot/restore engine state, linear/angular velocity and relevant sleep/freeze state in test-side adapter, or reject any boundary where base restoration changes them. Never require the saved engine to be off merely to hide the gap. Engine-on/moving negative control is mandatory.
- `_item_ms`: store semantic age using the correct wall clock, preserve the unset sentinel distinctly, and rebase on new-process time. Also inventory Hearing queue/event timestamps and IDs that interact with it. Rebase consistently or reject boundaries with relevant hearing history; copying the integer is forbidden. The 1.5-second bounce predicate in Creature is the behavioural control.
- Non-plain fields: resolve known references to stable identities and reconstruct a director Callable only through its real declared owner/method. Unsupported bound closures/coroutines reject the boundary. Include actual Problem child transforms, pose/material/eye emission, hum state and timers that affect what the user sees/hears. Do not simply compare their owner vars.
- Watches: retain passed set, original watch expression/source step, elapsed time, remaining deadline and current step time already spent. A saved 0.5 seconds remaining stays 0.5, not a new `within`. Do not resurrect failed/expired watches or mark them passed. At step-start points current step budget is fresh, but prior open watches are not. Unrestorable helper progress/held inputs means boundary ineligible; do not silently restart a helper with a fresh duration.

### Layer 2: immediate round trip, before any elapsed frame

Original uninterrupted execution records a canonical live observation at the boundary before the first action. Restore into a new process under identical identity, apply the test-side adapters, and observe **synchronously before any await/tick**, including before h1's current one-second wait. Either remove that settling delay in guarded mode or reproduce it identically on the uninterrupted path and compare both immediate and post-delay observations; never let it conceal drift.

Compare all declared semantic state exactly after lossless canonical encoding: discrete state/flags/IDs, transforms/velocities, held quantities, engine, watches' remaining budgets, references and child state. Normalize only declared volatile metadata (save wall date/process ID) and re-express clock origins as semantic ages. Print every normalized field and reason. Exact means lossless round-trip numeric equality; a discrepancy from lossy serialization must be fixed or the point rejected, not hidden by the layer-3 tolerance. Clock age comparison may use a declared <= one-sample acquisition error measured in the same atomic observation; never seconds of extra grace.

### Layer 3: +3 game-second trajectory and outcome comparison

The uninterrupted run continues the **actual next actions** and records the same observation at +3 game seconds from the boundary, plus input edges and event ordering up to that point. Use a test-side physics callback to sample while actions/watches run, not a blocking wait before actions. Even if a short step finishes, sampling remains anchored to that original boundary. Do not change the action timing to make the probe convenient.

Resume twice independently from the immutable point, replaying identical scheduled inputs/profile; collect immediate and +3 observations, event trace and next step's unchanged expects through their full observation window. Discrete states, seats, held items, event ordering and check outcomes match exactly. Position error <=0.10 m; other relevant continuous values <=2% with predeclared per-field units/scales (use absolute bound near zero); rotations require an explicit angular bound. Tolerances must also be smaller than the nearest relevant check margin; a 0.1-m tolerance cannot excuse crossing a reach/collision boundary. Compare BOTH resumes to the uninterrupted reference, not just to each other.

Two resumes measure the noise floor, not a licence to widen tolerances: if their difference exceeds a declared bound, boundary remains unqualified. If RNG/contact/coroutine effects cause divergence, either capture/reconstruct them faithfully on the test side or reject that boundary. Do not seed/change the game solely to force a match. +3 sameness is finite evidence; require matching next-step outcomes and retain the final fresh full walk. Record per boundary SAME only when all three layers and outcomes pass. Recording-profile boundaries require their own evidence: a 60-fps rehearsal gate does not qualify 25-fps Movie Maker.

## Recording and clean-walk acceptance

Keep 1600x900, 25-fps Movie Maker and captured sound. Do not pass fast/nodraw flags to recording. Test gameplay/watch time comes from game time, health/exit backstops from host wall time. T1's physics clock must use `delta` or actual physics ticks/60; a movie frame is 1/25 second with 2-3 physics ticks, never one tick. Preflight short known behaviour with sound and a deadline-negative fixture in this profile. Muted live speakers do not imply captured audio is absent or present: inspect the encoded sound.

Record final fresh clean real-input walk once; if clean, it supplies both clean-walk receipt and video. Baseline make_ghat uses declared placement helpers for corners/doors/bonnet/marks and calls credits directly. List these cuts honestly. They do not prove movement/reachability. For any such real movement required by design or a new hole/check, use actual walk/input actions and keep its corresponding proof; no added teleport may bypass the failing behaviour. Preserve both players' interaction actions and every original assert. A direct setter, helper-spawned promised state or merely DONE cannot certify a required input path.

The user allows joined takes. Prefix parts must be clean up to their exact cut; resumed suffix must have SAME gate under its own recording profile and compatible final inputs. Changed relevant source makes old parts ineligible; do not join across repaired game versions merely because the step name matches. Keep old takes as diagnostic artifacts, without deleting them. A joined review video is allowed, but **does not replace a separate uninterrupted fresh clean-walk receipt**. If no clean fresh take exists, charge a normal fresh walk; budget overruns stay visible.

Each part has source take/run/point ID, original frame range/time base, passed steps and identity. Cut before the failed step, retain no assertion-failing segment as clean. Validate no skipped/duplicated required action/step and no unexplained time reversal. ffprobe/frame timestamps define actual cut timing; `Engine.get_frames_drawn` alone needs proven mapping to movie frame indices. Compute cumulative final join times from actual trimmed encoded part durations. Write `joins.json` and a plain list `MM:SS.mmm -> step, source part, gate ID, frame ranges`. No generic "joined parts" without times. Retain raw logs and a content hash of the final video.

Watch every take while running (step, movement, heartbeat, script errors); on failure cancel/stop immediately, record cause and verify scoped Godot exit. The existing record script's completion grep and fixed sleeps are not adequate health monitoring. Check process exit before encoding; encode/watch after exit to avoid idle score. Watch the **entire final video with sound**, inspect both sides of every join and every required visual moment; record timestamps and what was judged. A frame grid supplements that watch. Check both player views, readable note/HUD, net inside/outside, approach/lean/turn/sniff, cap event, spring carry/pour, restart/pass and marks/credits. Missing view/sound/action stays INCOMPLETE and requires a new segment or fresh take as appropriate.

## Tool qualification and deliberately broken controls

All controls off by default and labelled diagnostic. Controls may alter test snapshots/receipts/command fixtures; never production logic. Each must demonstrably fail its guard, then pass with the mutation removed. Offline malformed/stale controls run first (0 game minutes).

| New tool/guard | Planted failure that must be caught | Clean paired result |
|---|---|---|
| Section graph/discovery | Fail an existing short interaction expect; queue a later held input and spawned helper. Original BROKE retained, no later input executes, dependent section BLOCKED. Deliberately omit a producer/action edge: graph/coverage refuses INCOMPLETE. | Unbroken interaction completes; genuinely independent declared reset path can run with its own diagnostic identity. |
| Identity/point ownership | Change source bytes at same HEAD, walk expression, setup, fixture, snapshot schema or point ID. | Compatible immutable point admitted to equality test; it is not yet SAME. |
| Layer-1 inventory | Omit `engine_on`, a child property, a non-plain reference or an outstanding helper. Independent live inventory must mark unsupported/missing. | Complete narrowly scoped inventory has reasons for every relevant field, with unresolved fields making boundary ineligible. |
| Layer-2 restore | Turn off engine/zero nonzero velocity after restore; leave `_item_ms` at old process origin; omit a reference/child field; restore full watch budget instead of remaining. Apply each mutation separately to a valid saved observation. Each yields named DIFFERENT before inputs. | Correct round-trip matches on a qualifying boundary; known-unrestorable boundaries are refused, not forced green. |
| Layer-3 probe | Test-side post-restore perturbation after immediate comparison: move an actor >0.1 m, change one relevant discrete state, or delay a required input. Immediate gate alone would pass; +3/outcome gate must fail. Also give two identically wrong resumes: fresh-reference comparison must still fail. | Two independent resumes and fresh trajectory agree within predeclared tolerances and next-step outcomes. |
| Timestamp/watch behaviour | Supply saved hearing history around 1.5-s bounce boundary with controlled test-side event stamps; unre-based state must diverge or be refused. Watch with 0.5 s remaining, event at +0.8 s: must fail at original deadline. | Correctly rebased supported history preserves predicate; event at +0.3 s passes, no fresh-limit extension. Unsupported history explicitly refused. |
| Movie wrapper/join validator | Remove an encoded part or required action, use wrong point/profile identity, corrupt frame/time range, supply stale different-version prefix or silent/missing audio for a known sound clip. Must refuse review-complete. | Two short clean compatible pieces yield exact nonzero join time, full coverage and captured sound; watch both sides. |
| Movie time/cancellation | 25-fps short fixture goes just beyond unchanged game-time limit: named STALLED/FAIL; no continued input or dangling Godot. | On-time fixture passes with correct tick/game-time accounting and verified exit. |

Reuse one short naturally reached boundary to exercise several mutations offline against its real observation; do not replay a long prefix for every corrupt JSON variant. At least one live moving/engine-on point and one live in-encounter point must test independent restore observation. A diagnostic fixture can set up a snapshot to prove refusal, but cannot qualify that synthetic state as a real walk boundary. If no encounter boundary fits the cap, mark encounter resume UNQUALIFIED and use real prefixes; do not spend 21 full-step qualifications.

Qualification allocation, **I think**: imports/startup 0.5; watched short discovery/cancellation clean+broken 2.5; moving boundary fresh+two resumes and live inventory 3; encounter boundary fresh+two resumes 5; short 25-fps deadline/sound/join clips 2; reserve 1 = **14 wall game min at 1x / 14 with fast available**, hard stop **15 T4**. These runs are deliberately normal/recording profile; no assumed fast resume qualification. Costs include every launch and shutdown. If the encounter prefix exceeds five minutes, refuse that candidate and report unqualified; do not exceed the cap. Offline controls and post-exit video review add no game score. Report unexercised live controls as INCOMPLETE even if their offline reducers passed.

Replay allocation owned by T4: **28 / 28** (8 discovery, 10 repair/producers, 10 fresh clean recording); shared bench/stops reserve is in T3 playbook, not another T4 saving. An additional fresh walk after joined-only footage must fit the remaining replay budget or the method misses its target. At 1x fallback the whole method is estimated 99, not <=75. Actual achieved speed, boundary refusal and real prefix duration determine whether fast 62 remains plausible.

## False-pass risks, stop rules and report

Biggest risk: the observation and restorer omit the same hidden state, so two matching snapshots produce a falsely trusted suffix. Independent inventory, immediate observation including children, fresh-vs-two-resumes trajectory, unchanged next-step outcomes and the final fresh walk are complementary guards, not a completeness proof. An unsupported in-flight coroutine/contact/hearing history is a reason to reject the boundary. Never relax a tolerance or reset a deadline to get SAME.

Before every run state expected minutes and remaining qualification/replay budget. Watch every few seconds; off plan, stop immediately and inspect the failure picture/state. After three failed fixes of one tool/boundary, stop looping and report or reject that boundary. Hard qualification stop 15; replay target stop 75 union minutes or projected required work exceeding it; approximately two-hour wall cap per referee. No reading forbidden history for an easier point, no patched promised state, no stale footage, no claim of CLEAN from discovery.

Builder reports: files/local commits and every deviation; all controls with expected/actual clean and planted verdicts, evidence paths and exact commands; meter union/summed qualification minutes and watches/exits; section graph/blocked consumers and setup cuts; field inventory/unsupported list; per boundary identity, immediate diff, fresh/R1/R2 +3 diffs/tolerances, next outcomes and SAME/DIFFERENT/UNQUALIFIED; old-point rejection after edits; observed boot/prefix/suffix durations; final fresh walk receipt; final video path/hash, full watch timestamps, sound judgement and every join time with gate/part provenance; remaining risks and unrun checks. Baseline gameplay faults noticed during qualification go in the referee reply only, not a spoiler committed for the later replay.
