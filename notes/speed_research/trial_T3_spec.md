# T3: discovery, conservative selection, receipts, and replay playbook

GPT auditor specification, 2026-11-10. Status: proposed, unbuilt, unmeasured. Claude builds and runs; GPT writes this specification only. No forbidden file was opened in this task. No game was run. Estimates marked below are **I think**, not measured results.

## Scope and evidence

Build only in the referee-supplied `D:/mine/Agentics/T3_Code_Works/MPG_speed_t34`, branch `speed-t34`, based on `speed-base` (benchmark `5f3e3e3` plus h1 tools). Nothing on C:, no new checkout, merge or push. Do not seek the referee's holes. Qualification must leave gameplay, scenes and assets unchanged. Temporary data belongs under this copy's `appdata/`.

Reading used the task's permitted research files, TESTING_METHOD, P1/P1b/P1c, and source inside MPG_speed_base. Source facts:

- `tools/method_run.sh ghat` already accepts `GHAT=...`, defaults to k3, and asks for heat, looks, net, places, jug, spring, marks in that order. Its printed ramp runtime is unsuitable for ghat.
- `method_watch.py` watches `appdata/playtest/runs`, initially hardcoded, and `seg_1.log`. `run_test.sh` also shares progress and logs; merely allowing a second process would corrupt evidence.
- `method_verdict.py` matches every observed repeated helper check and reports missing required checks/work/rules. Keep its semantics, limits and observation intervals.
- `make_ghat_manifest.py` follows only `_ghat`, `_fix_with`, `_hide_well` helpers. It is a check inventory, not a production dependency graph. A new helper outside those prefixes can be missed.
- `prove_ghat.py` uses FAIL substrings and discovers output with a directory glob. Neither is sufficient identity for parallel lanes or precise plant proof.
- Inventory discrepancy: I count **21 plant keys** in the baseline GROUPS dictionaries, whereas the brief says 20. Preserve all named rows, excluding shortcut flags `one_flat`/`one_corner` from the bug count. Ask the referee to reconcile the count; never remove a row to reach 20 or assume 27 is the complete final inventory.

Authority: scoreboard R2 overrides the brief's old score definition: union of Godot lifetimes is primary; summed lifetimes also reported, capped at 247.5 minutes (225 x 1.10). R3 separates qualification from replay. Latest task/top4 allow a final suite at qualified fast settings; earlier audits requested a final 1x suite too. This spec uses the latest instruction, explicitly conditional on T1's per-path evidence. If that condition fails, final affected paths run 1x and the budget changes.

## Builder files and command contract

Add only:

- `tools/method/speed_receipts.py`: canonical identities, sealed run receipts and compatibility validation.
- `tools/method/speed_select.py`: change closure, required coverage, map lint and controls.
- `tools/method/speed_plan.json`: scenario/check/work/rule dependencies with source evidence.
- `tools/method/speed_qualification.py`: the offline and short live negative controls below.
- `tools/speed_run.sh`: discovery/targeted/final launcher and explicit discovery continuation.
- `notes/speed_research/trial_T3_build.md`: qualification report, costs and deviations.

Modify only `tools/method_run.sh`, `tools/run_test.sh`, `tools/run_game.sh`, `tools/method/method_watch.py`, `tools/method/prove_ghat.py`, and, if needed, `FindingNaresh/scripts/dev/PlayTest.gd` / `MethodRec.gd` for off-by-default qualification controls and run identifiers. Reuse T1/T2 changes instead of overwriting them. New runner controls must not change default gameplay/check behaviour. Treat T4's file allowance separately. No changes to `core/Plant.gd`, gameplay or frozen thresholds during tool qualification.

Commands below are the required NEW interface, from Git Bash in MPG_speed_t34; existing method commands remain supported. `--speed normal` is baseline; `--speed fast` means T1 routing, never global acceleration.

```sh
python tools/method/speed_select.py build --base speed-base
python tools/method/speed_qualification.py t3 --offline
python tools/method/speed_qualification.py t3 --live --speed normal --cap-wall-seconds 540
bash tools/speed_run.sh discovery --speed normal
bash tools/speed_run.sh discovery --speed fast
python tools/method/speed_select.py select --since <saved-content-receipt>
bash tools/speed_run.sh targeted --selection <selection.json> --speed fast
bash tools/speed_run.sh discovery-remaining --report <discovery.json> --review <inspection.json> --speed fast
bash tools/speed_run.sh final --speed fast
python tools/method/speed_receipts.py finish --replay <replay-directory>
```

Each command returns its exact run directory/ID directly, with machine-readable JSON. No glob/latest-directory selection. Refuse an absent T1 qualification for a requested fast path, or route that path to normal with a prominent mode/budget entry. Final/finish exit codes retain PASS 0, FAIL 1, INCOMPLETE 2, TEST 3, NOT HEALTHY 4. A discovery report is diagnostic; it cannot be promoted to final PASS.

## Discovery and change selection

1. Before running, inspect baseline design #6, generated walk and scenario/check/work/rule inventories in the sealed copy. Produce a design-to-observation table: behaviour -> real producer/input -> observer/check or manual picture/video judgement. An uncovered behaviour is a coverage gap, not evidence the game meets it. Add checks during the later repair phase, not speculative fixes during tool qualification.
2. First discovery asks for all seven complete scenarios. Ordinary failures accumulate without deleting their evidence. STALL, TEST, script/health error or unexplained movement stops the affected lane immediately. Inspect its picture and logs, retain its stopped verdict, close the game before extended reasoning.
3. Only then explicitly command independent unstarted scenarios using `discovery-remaining`. Inspection records failed scenario, cause understood or still unknown, independence justification and exact remaining list. Unknown dependence stays BLOCKED. Preserve all runs under one discovery report, including stopped/missing checks. This is not an uninterrupted green suite. `run_test.sh resume` alone cannot satisfy this report.
4. Build the map offline: each required check ID, repeated invocation/profile, work receipt, H-rule and walk section has producer files/functions, state read/written, reset/setup and downstream consumers. Record evidence locations. Compare generated manifest with frozen required checks and manually review call sites outside its helper prefixes. Unparsed/dynamic dispatch or untraced dependency is UNKNOWN. Do not claim a complete static analysis.
5. Default **all seven** for production vehicle, input, save, creature/hearing, shared resources/scenes, clocks, reset, judge, fixtures, manifest, shared helper changes or any unknown path. Narrow only an evidenced local observation/scenario change after including all consumers and its matching plant. A changed shared material/asset must include its visual consumers. File renames/deletions/untracked files are changes, not an empty diff.
6. A selection states changed content, closure, checks chosen and checks omitted with reasons. It cannot remove required coverage. In repairs, run the selected full scenarios and new/affected plant controls. Diagnostic short reproductions are supplementary. If the closure is all seven, budget it honestly; the map is allowed to save nothing.

### Guard against a wrong map

Do not let a map validate itself. An independently maintained coarse policy marks shared/unknown paths broad, and a separate inventory comparison checks required IDs/consumers against source. Mutation controls below include an intentionally missing shared edge whose correct answer is fixed before invoking the selector. Structural consistency cannot prove semantic dependency completeness: the final unshortened suite is the backstop. A new failure outside the selected closure at final is a **map miss**, invalidates the selection claim and triggers review of sibling omissions; it is not merely a newly convenient targeted test. Keep first-failure evidence and report the extra cost.

## Receipts and final acceptance

Use content hashes, not HEAD alone. Record HEAD, dirty and relevant untracked/deleted input paths and bytes; engine binary/version; project/import settings, relevant resources/assets; tool/judge/check/manifest/plant definitions; generated walk and generator; profile, fixtures, actual engine/game arguments, speed qualification identity, data namespace, run ID, process IDs and start/end times. Exclude outputs and volatile timestamps from content identity, explicitly list the exclusion policy. Stamp source both before and after execution; a mutation during the run invalidates it.

Receipts contain exact requested/started/ended scenarios and order, every check invocation including repeats, work and rule evaluation receipts, windows closed, pictures with identities, errors/stops and verified Godot exit. Missing, duplicate/conflicting, wrong fixture/profile, stale or truncated evidence cannot be PASS. A hash proves identity, not check correctness or independence. Seal receipts atomically after reduction and process exit; keep raw evidence. This is accidental-staleness protection, not a cryptographic trust system.

Final suite runs **every scenario and its entire original path**, all profiles originally exercised, same thresholds/work/H-rules/pictures, with fixtures empty. No h1 snapshots, proof shortcuts, cut windows, omitted checks or previous greens. T1 may separate the normal spring process from qualified fast scenarios; preserve original logical order and clean-process/reset boundaries and report every split. This declared mode split is permitted; arbitrary stitched selective results are not. Keep default single-process all-seven mode at 1x. Any order-sensitive state not shown equivalent across the split forces the relevant chain to 1x in its original process/order. Review all required pictures; nodraw retains actual full-resolution pictures, never blank/stale substitutes.

Final proof inventory = every baseline plant row plus each independently discovered hole's plant and the referee's exam rows. Require exact scenario/check IDs, activation/reach, closed observation and matching clean control, not substring-only verdicts. Preserve existing groups only where causal attribution is demonstrated; ambiguous generic H-rule failures require isolation. T2 early stop means DETECTION COMPLETE / rest not run, never clean scenario PASS. Reuse immediate new-hole proofs at finish only if dependency content is identical; otherwise rerun. Final full matrix cannot silently reuse incompatible revisions. Finish refuses until referee supplies its independent seven-hole and secret-exam score; the public tools must never read secret files to calculate it.

## Optional two-game lanes: a prerequisite, not a guard relaxation

At most two games on this PC, including other trials. Referee reserves slots; unavailable slot means serial execution. T1's copy-scoped guard is necessary but insufficient: the current copy shares data, shots, Movie Maker parts and `live.py` commands.

Before overlapping anything, route each lane's MPG_DATA, APPDATA, LOCALAPPDATA, TMP/TEMP, progress, rig/events/logs, points, live commands and shots into a unique D: directory. Fix watcher hardcoded paths and test-side shot destinations. Use exact PID plus copy/run identity for stop/quit; never kill a global Godot name. Prefer one walk/recording lane and one suite/proof lane, not two recording lanes. A single shared shader/import cache is read-only during overlap; finish import before both games. No editing game/check/tool inputs while either accepted run executes. Set any local temp/cache overrides before launching tools, too.

If namespace isolation is not proved within qualification budget, leave lanes serial and report zero overlap saving. A second game's performance failure is rerun alone before blaming the game; charge both runs. Concurrent observed throughput replaces pilot estimates.

## Qualification: every new tool must reject a planted failure

These are off-by-default test/tool controls, not claims of benchmark-hole discovery. Each control has a clean paired acceptance. Archive inputs, expected verdict written before execution, actual result and time. A control unexpectedly passing stops qualification.

| Tool/guard | Planted failure and required rejection | Clean counterpart |
|---|---|---|
| Map builder/selector | Delete a shared dependency edge; use a changed shared helper, unknown file, deleted resource and renamed file. Independent policy must select all seven or refuse map; a predeclared cross-consumer case must select both consumers. | Evidenced local observer edit selects its full declared consumers; no required ID lost. |
| Receipt/finish reducer | Mutate dirty bytes at same HEAD, fixture, manifest, speed profile; remove a check/work/window receipt, duplicate IDs with conflicting results, truncate run, insert during-run source mutation, mix revisions. | Immutable complete synthetic receipt accepted; real short complete scenario accepted only on its actual method result. |
| Discovery launcher/continuation | Three short diagnostic scenario entries through the real method recorder: control hangs entry 2 beyond its unchanged game deadline. Stop at 2, verify PID gone; no automatic entry 3. After explicit inspection, run 3; report retains stalled 2 and cannot become PASS. | Same entries without hang complete in order. These entries qualify orchestration, never replace real seven. |
| Final launcher | Ask for six scenarios, `one_corner`, dirty-on-exit receipt, h1 setup or interrupted continuation disguised as final: refuse acceptance. | Full synthetic final ledger admitted by wrapper only with compatible complete evidence; live completion is still independently reduced. |
| Lane isolation (optional) | Two short processes write distinct sentinel/run/fixture IDs and pictures. Misroute one path deliberately: preflight or reducer must refuse. Quit A must leave B's heartbeat advancing. | Corrected isolated lanes retain their own controls/results and both exit; no cross-selected directory. |
| Plant attribution adapter | Supply only `lean_close` but request proof of both looks plants; `fast_turn` must remain NOT PROVED. Give unrelated same-substring FAIL and absent activation: NOT PROVED. | Exact complete named evidence proves only active/reached plants; validate against T2's real looks evidence if compatible. |

Game budget including imports, failed launches and shutdown: **9 wall game min normal / 6 fast**, hard stop **15 per T3**. Allocation at 1x: import/preflight 0.5, watched clean/stall/explicit continuation <=3, one short real-method clean/plant validation <=3, optional lanes <=2, reserve 0.5. Offline controls cost zero game min. Do not run a whole ghat suite merely to qualify the launcher. If a chosen real scenario cannot reach its plant within the allocation, use compatible T2 evidence or mark that qualification INCOMPLETE; do not fake a result with a short replacement game path. Global three failed-fix rounds -> stop and report; do not exhaust 15 in a loop.

## The replay playbook

All numbers below are planning allocations, **I think**. Fast means measured T1 qualification on six paths plus nodraw pictures, with spring and every free_coolant path at 1x; use 4.5x for accelerated stretches, not the pilot's peak 5.5x. Walks/recording remain normal. Startup/import, 1x spring, failed attempts and exits are included. No claim that all seven holes or 75 minutes are achieved until referee scoring.

0. Referee prepares the clean speed-base gameplay state and supplies qualified T1/T2/T3/T4 tool changes with identities. Do not transplant gameplay fixes or qualification artifacts. Verify gameplay/assets match base before replay; import once. Start separate qualification/replay meter phases. Offline: reconcile inventory, map, independent walk sections, boundary eligibility, expected run costs and remaining budget. No games idle during design or fixing.

| Order | Work and required receipt | 1x min | Fast min |
|---|---|---:|---:|
| 1 | T3 first broad seven-scenario discovery; inspect pictures; explicitly recover unstarted independent scenarios only after stop/review | 20 | 8 |
| 2 | T4 discovery walk, stopping on failure; separately declared independent diagnostic sections; retain all BLOCKED consumers | 8 | 8 |
| 3 | Claude repairs discovered causes under separate replay authorization; map-selected full scenario tests and immediate clean/plant proof for each new check | 15 | 7 |
| 4 | T4 repair trials from qualified same-content points or real producer paths; requalify invalidated points, no injected repair | 10 | 10 |
| 5 | T2 full final-revision plant matrix, baseline plus new holes; exact attribution and clean controls; early exit only when complete | 12 | 7 |
| 6 | Freeze final inputs; T3 one final unshortened all-seven suite, review full-resolution pictures; seven PASS | 20 | 8 |
| 7 | T4 fresh real-input full walk recorded and watched. One clean uninterrupted take can satisfy both walk and video; joins allowed only for review, with separate fresh clean-walk proof if needed | 10 | 10 |
| 8 | Reserve: missed discovery, short benches/stops, exam plants/clean controls supplied by referee, final receipt checks | 4 | 4 |
| **Serial planning total** | **No double counting of immediate proofs reused at identical inputs** | **99** | **62** |

Budget ownership: T3 discovery/fixes/final = **55 / 23**; T4 discovery/resume/clean recording = **28 / 28**; T2 matrix = **12 / 7**; shared reserve = **4 / 4**. Qualification is separate: T3 **9 / 6**, T4 **14 / 14**, each hard-capped at 15. Thinking, editing, encoding and watching after Godot exits are separately reported and cost zero score minutes.

Where two games run: after isolated lanes qualify, overlap orders 1 and 2; both are read-only discovery of the same immutable gameplay inputs. Their planned union is max(20,8)=20 at 1x or max(8,8)=8 fast, saving **up to 8 minutes**; actual union/slowdown decides. Optional overlap final matrix with final suite only when inputs frozen and both lanes watched; do not budget an unmeasured saving. No overlap of editing with an acceptance run. Serial totals are the conservative budget; fully achieved first overlap would give approximately **91 / 54**, not a measurement. If a discovery lane fails, stop that lane; stop both for shared errors/health uncertainty, inspect, then decide explicitly.

At 1x, this plan still executes correctly but **does not meet 75**. Notify referee before starting its replay; do not spend 99 to pretend the target is reachable. Partial T1 qualification: recompute each planned cost with the actual normal/fast mix. Fast 62 leaves 13 minutes against 75, not permission to reduce checks. Unknown exam plant runtime and number of newly found holes make that provisional.

Stop rules: expected cost and remaining budget written before every launch. Every few seconds inspect step, movement/physics, errors and new verdicts in BOTH lanes. Off plan -> stop scoped process, capture current picture/state with bounded capture, preserve failure, verify exit. Meter union/summed totals and projected required work after every stop. At projected >75 or actual 75, stop benchmark as INCOMPLETE and report; never discard required work. Three unsuccessful fixes/replays of one issue -> stop speculative cycling and use a bounded bench under the remaining allocation. A final-suite map miss means repair, invalidate and rerun final coverage or report INCOMPLETE; no endless final loop and no reused stale greens. Referee's ~2-hour replay wall cap also applies; no silent extension.

## Required builder report / remaining risks

Report exact modified files and local commits; base/gameplay checksum; every deviation and why; commands and pre-run estimates; actual R2 union and summed minutes by qualification/replay and stage; watches/stop/exit evidence; every negative-control pair; map rows and unknowns; first source of each discovered issue (suite/walk/design), earliest divergence and new check/plant; final scenario and plant inventory with IDs, compatible clean controls, picture reviews; T4 walk/video/equality receipts; referee's independent hole/exam score. Distinguish FAIL, INCOMPLETE, TEST and health errors, never infer owner without evidence. A known baseline game failure during qualification is reported to the referee in the builder reply only, without a spoiler committed for the replay.

Biggest limitations: dependency completeness cannot be established from a hash; discovery cannot guarantee unknown-hole coverage; qualified fast clean/baseline-plant agreement is finite evidence; process splitting may hide cross-scenario state; two lanes can corrupt shared files unless fully isolated. Final broad suite and referee's blind exam remain mandatory. No weakened assertion or narrower evidence window earns a speed saving.

T1 task disagreement: no objection to test-only clocks, nodraw qualification or the 1x exceptions. Its allowance to reuse historical 1x plant verdicts needs compatible source/check/fixture identity and exact named causal evidence; an old substring FAIL is insufficient. Its copy-scoped process guard alone does not authorize same-copy concurrency. Also prove the deadline-negative fixture at **1x as well as fast**, and do not infer 25-fps recording clock correctness from the 60-fps differential (T4 qualifies that separately).
