# GPT audit of the T3/T4 v2 build — 2026-11-14

Scope: I read `audit_T34_gpt_task.md` first and stayed within its allowlist. I inspected the permitted specifications, audit/answer, scoreboard, build reports, usage file, tools, permitted diff `709028b..f208e6e`, and selected evidence under this build's `appdata/`. No game, control script, reducer, import, encoding or test was run. This is my only authored file. Read commands and the permitted git diff were the only execution. No excluded folder or skill was opened.

Below, **B** means `D:/mine/Agentics/T3_Code_Works/MPG_speed_t34/`. Code findings are static findings, not newly executed controls. The reported 49/49 and 83/83 control totals are builder claims; the concurrent Claude auditor owns their rerun. Synthetic receipts establish reducer behavior, not live suite qualification.

## 1. Were both v2 specifications built as written?

### T3

| Required piece | Verdict | Evidence and limit |
|---|---|---|
| Scope, tools/dev only; reuse T1 | BUILT AS WRITTEN for inspected diff | `709028b..f208e6e` changes tools, dev scripts and reports; no production gameplay, scene, asset or Plant changes. Builder task authorizes the T1 merge despite the specs' original no-merge scope. |
| Input content identity, binary, pre/post stamps | BUILT CHANGED, partly sound | `B/tools/method/tree_id.py:54` uses a private index under appdata, stages dirty/untracked nonignored inputs, hashes groups and binaries; `method_run.sh:125` stamps both ends. Controls include dirty bytes, untracked input and real-index preservation. However ignored inputs are not generally force-included, and all appdata is excluded although it contains runtime inputs. The report's current-input inventory is a claim, not a general enforcement mechanism. Walk/tool identity separation also has the limit below. |
| Invocation-local metadata | BUILT AS WRITTEN structurally | `method_run.sh:151` writes inv/part/run/plan/profile/fixture/speed/lane/role/namespace/times/exit and tree stamps; existing combine/proof readers bind receipts to inv/part. No glob-based proof selection. Actual clean suite integration on this final tool tree is NOT SHOWN. |
| Design-to-observation table | BUILT CHANGED; reviewer still required | `t3_gate.py:197` validates present rows, producer text and observations. The table itself is intentionally left to the sealed replay runner, correctly named in the report. It cannot detect a behavior omitted entirely: deleting a complete row leaves no GAP. The mandatory design-to-row completeness review is not replaced by this checker. |
| Discovery, seven starts, explicit continuation after inspection | BUILT AS WRITTEN as procedure | Usage sections 2/4 retain existing launcher/watcher and explicit GHAT continuation; discovery cannot satisfy role=final. Shared simultaneous-stop behavior is still a human obligation. |
| Broad repair suites, no selector/map | BUILT AS WRITTEN as requested inventory; accepted routing NOT QUALIFIED | Default inventory contains all seven. But `method_run.sh:48–73` splits heat/net/marks from looks/places/jug/spring. This removes marks' same-process looks producer. Serializing that split with PAR=0 does not restore the producer. |
| Small final checker: clean complete seven, correct identity, work/checks/rules/pictures | NOT BUILT in full | `t3_gate.py:74` checks inventory, role, profile, fixture, restored/early-stop flags, trees and process leftovers; reuses combine/reducer for checks/work/rules. It never enforces marks' prelude or picture presence/freshness. `t3_controls.py:146–185` constructs an “accepted clean” receipt with no actual checks/work/pictures, including empty passed_ids. This is useful structural testing, not evidence of the required complete acceptance gate. |
| Manifest traversal beyond helper prefixes; repeated calls; fail closed | BUILT CHANGED, incomplete | Direct bare local calls, cycles and repeated sites are handled. `make_ghat_manifest.py:29` excludes names preceded by a dot, so `self.helper()` is not followed. At line 102, strings are erased and literal call/callv can be exempted without traversing their target. Thus a local helper with a check can still disappear. The current 116 unchanged IDs reported by the builder do not qualify future replay checks against these cases. |
| Exact proof compatibility and D2 A causality | BUILT CHANGED, useful refusal; incomplete operational path | `prove_ghat.judge` enforces exact IDs, fixture/inv, early-stop and exit. `t3_gate.py:138` adds matching clean PASS and source tree plus solo proof requirement. However it uses `len(expect)==1` as the “alone” predicate, not an actual single behavioral-plant set. Existing multi-member groups lack solo groups for many members (stall_hud, fog_h2_keep, jug_b, spring_a, lean_close). They remain uncertified, correctly, but usage has no complete matrix command list. Marks proofs under SPEED=fast request two parts, whereas `prove_ghat.py:81` requires exactly one; those commands cannot certify them. |
| Complete 21 + found holes + exam inventory | NOT BUILT as a completeness gate | `t3_gate.proof` certifies only supplied rows. A successful one-group command does not mean the matrix is complete. GROUPS retains existing rows, but the replay needs an explicit required-row ledger and reconciliation. Referee finish remains a separate process condition. |
| Optional namespaces and sentinel | BUILT AS WRITTEN for basic routing; broader qualification UNQUALIFIED | R4.out shows two PIDs, both misroutes refused, targeted stop and surviving heartbeat 4773→4956. It does not test suite reset/order equivalence or fast nodraw capture interleaving. Moreover `lane_sentinel.sh` logs recording/worker outcomes without making them all pass conditions: R4 says **2 ok of 4** worker walks but ends SENTINEL PASS. `appdata/t34/sentinel_b_walk.log` contains failed nav/engine expects. This proves live separation, not a clean paired workload or every acceptance criterion. The loop continues after worker failures. |
| Referee finish, budgets and watched-run discipline | BUILT CHANGED as process only | No secret-reading/scoring tool. Usage requires ledger and >75 stop. No automatic budget checker was required. The failed sentinel work must remain visible and be investigated; “SENTINEL PASS” cannot erase it. Reconcile reported ~15.2 T4 + 2.0 T3 union with exact referee meter and the 15/20 caps; rounded self-count does not establish compliance with T4's cap. |

### T4

| Required piece | Verdict | Evidence and limit |
|---|---|---|
| Real fresh entry, first break stops, tail before recording; no section graph/watch restore | BUILT AS WRITTEN as procedure | Usage section 3 requires real prefix on refusal and completed repair tail. Wrappers use --fresh fallback. Actual full repaired ghat tail is replay work, NOT SHOWN by the probe. |
| Cancel helpers and release inputs before failure shot | BUILT AS WRITTEN for observed case | Permitted PlayTest/LiveControl diff adds cancellation generation, input gate, helper guard after await, release and flush before capture. A2 report records the corrected held-input control; `runA2_probe.out` shows held=[] and blocked sends. That file also contains a subsequent probe failure; do not describe it as an entirely clean session. |
| Immutable points, identity, source part ownership | BUILT CHANGED, only partly sound | New per-run folders refuse reuse; last-fail names a point. `walkgate.identity_check:385` checks game/test/bin/schema/profile and producer/resumed steps. Tool hash is retained but excluded from compatibility. The rationale “tools do not change what the game does” is too broad: tools/live.py sends actions and wrappers select profiles. Producer-affecting tools need invalidation; judge-only changes need recorded requalification. |
| Scoped independent inventory, D4 A | BUILT CHANGED, conservative refusal works; positive coverage UNQUALIFIED | GateObs (permitted diff) independently reads script vars, physics, child transforms/material/audio/timers, references and selected statics. Inventory names global RNG, contacts, coroutines and refuses a Problem/listener. However regex-wide classes are not per-field saved/rebuilt/refused proof. Required patterns do not require every child/clock/open-work observation; omitted fields on both sides can escape. Camera RNG/contact relevance assertions are not independently verified production facts in this scope. No live SAME boundary relies on them here. |
| Engine/velocity refusal; quiet hearing without rebase | BUILT AS WRITTEN conservatively | `walkgate.refusal` rejects engine, >0.1 m/s, recent/unconsumed hearing, any live Problem listener, live debounce windows, helpers/held inputs/watches/needs/tweens. G log demonstrates refusal. Real quiet eligible roundtrip is NOT SHOWN: offline quiet() edits the copied point velocities. |
| Owner director and independent children | BUILT for observation; live reconstructed equality UNQUALIFIED | Existing owner reconstruction retained; GateObs observes director and child state. Layer-2 mutations are synthetic. No live positive child reconstruction pair was delivered; all Problem points are refused. |
| Exact immediate layer 2 before await/settling | BUILT AS WRITTEN for comparison timing | Permitted LiveControl diff writes restored.obs synchronously before wait(1.0). G log catches lost carryable velocity and _safe_t, and the engine-on boundary is refused. Exact comparison appropriately does not waive tiny numeric discrepancies. |
| Layer 3 fresh vs resume, actual inputs/events and next-step outcomes | BUILT CHANGED; live rejection shown, acceptance UNQUALIFIED | G clean continuation differs at nav_aside, players 0.055 m, velocity 0.064 m/s, temperature 1.6 C; perturbation adds van displacement 0.152 m. Thus rejection works on these cases. `walkgate.next_step:339–359` treats client-aborted fresh steps like external breaks and compares only pre-break outcomes, potentially zero outcomes; this is weaker than complete next-step evidence. |
| D3 A: two positive resumes, profile and declared tolerances | BUILT mechanically, NOT QUALIFIED | boundary() counts SAME entries without requiring distinct run directories; the same resume supplied twice can count twice. judge_resume() does not itself bind each resume's identity/from_point to the producer; boundary checks only mutual profile equality. Declared numeric bounds exist, but no live two-resume calibration or successful recording-profile boundary exists. GATE_RESUMES can remove D3 independently; it must remain 2 for A. |
| Fixed25 sound clip, unchanged late deadline, recording contention | BUILT partly; evidence limits | R1b.out proves rec25 DONE, one magenta mapping at offset 0 and verified exit. R3.out names the 10.5/10 late failure. Report claims decoded sound PASS; I did not find a sound-result receipt in the inspected R1/R2/R3 outputs, so decoded sound is report-only here. R4 basic heartbeat/throughput stands; clean worker/capture equivalence does not follow from its failed walks. |
| Join verifier and D1 | BUILT CHANGED; end-to-end accepted join UNQUALIFIED | join_check validates video hashes/durations, identity groups, point chain, kept step names, gate and cut mapping; emits ffprobe-derived join times and adjacent frames. Controls use two fresh takes with a gate waiver and TESTONLY output, not a valid resumed take. Missing walk.json silently removes step-coverage checking; mapping is profile-wide, not bound to every part. No successful two-resume SAME join delivered. D1 permits a fully qualified joined take as both walk/video; it does not require a separate unbroken take. |
| Whole final video sound watch, timestamps, both views | NOT SHOWN (replay obligation) | Usage asks for full watch. No complete ghat video/watch receipt delivered here; a short probe and extracted frames cannot supply it. |

D2/D3/D4 are visibly separated (proof gate, RESUMES, inventory unsupported rules), but removability is not permission to weaken them. D5 remains mandatory. The reports name the marks gap, unqualified resumes, synthetic receipts and limited throughput sample honestly. They do not name all the acceptance bypasses above.

## 2. Are the T1 round-2 shared conditions closed?

**No. T1's conditional fast table is not an unconditional replay qualification.**

| Condition | Decision | Evidence |
|---|---|---|
| Exact input sealing | PARTLY CLOSED | Content/binary pre/post stamps close same-HEAD dirty-byte ambiguity for covered files. General ignored/runtime-input coverage and producer-tool invalidation remain incomplete (`tree_id.py`, `walkgate.identity_check`). No live final suite on these delivered bytes. |
| Split/reset order and marks producer | NOT CLOSED | Default split moves looks to a separate process from marks. The report expressly admits this. No reset/order differential is supplied. `PAR=0` still launches split processes. Marks' clean PASS prelude is not checked by final(); marks plant proof splitting also conflicts with judge's one-part requirement. |
| Pictures: current state, required coverage, freshness | NOT CLOSED | `method_run.sh:150` copies files newer than a launch timestamp. `method_verdict.reduce` and `t3_gate.final` never demand a capture manifest, picture bytes, scenario/state/frame identity or inspection receipt. Namespaces reduce cross-talk but do not prove current rendered state. R1b's movie marker qualifies that one mapping, not every fast-suite capture. |

T1's existing exact-ID and deadline guards are reused, not re-certified by this audit. Looks/jug/places/spring/free_coolant/recording stay 1x. For accepted work now, retain original unsplit normal chain; even then required picture inspection/freshness must be established. Do not call the tools' structural ACCEPTED result a certified full-game pass.

## 3. Replay playbook and measured cost revision

**My operational pick is fresh walks and fresh recordings only. D3/D4 remain built but unused for savings.** The six probe points are all refused: 0–2 retain ~0.148 m/s on a frozen van; later points also have engine/hearing activity. This does not prove every possible ghat boundary fails, but it proves no usable boundary in the delivered probe. G's unperturbed continuation also fails layer 3. Do not zero velocities, relax equality or use the mechanics-only join to turn that into SAME. D1's permission stands for a future qualified join.

Playbook: complete the sealed behavior/observation table and required plant ledger; discovery suite plus fresh real-input walk; after each repair batch all seven with qualified producer/order; replay fresh prefixes to a completed tail; freeze inputs including all new checks/plants before final proof work; exact clean final/matrix pairing; fresh rec25 full take; after exit inspect required pictures and watch the entire video with sound; referee judges holes/exam. Retain every failure and stop affected work on off-plan behavior. No acceptance inputs edited under running lanes. D5 stops scored replay if projection exceeds 75.

Measured replacement basis (`B/appdata/t34/R1b.out`, `R4.out`, CPU TSVs; build report “Re-measure”): **59 s game life** per short recording, **52% overall alone / 51% beside the other lane**, **62–70% in the walk**, CPU reported 38% average alone and 52% together. One sample per condition; R1b includes builder CPU work. R4's **3.0 summed / 2.0 union = 1.5x** applies to that job pair, with basic heartbeat 59.7 Hz. It is not measured speedup of the entire replay, a fast proof lane, or a long ghat recording. Its worker failures limit clean contention qualification.

For the still-assumed **11-game-minute** ghat take, 11/0.70 to 11/0.62 gives **15.7–17.7 wall minutes of walk**, plus startup/exit. Use **~16–18 min as an optimistic extrapolation**, and **~21.2 min** using 11/0.52 as a conservative whole-take allowance. Both are estimates based on measured short-clip rates, not measured long-take costs. A failed late take costs its actual lifetime again; every repair now pays a real prefix. Keep the old 19-min walk/repair allocation only as an explicit, potentially low placeholder.

Rebuilding the old schedule with its two assumed repair batches:

| Job | Conditional restricted-fast serial estimate (min) |
|---|---:|
| Discovery: one 11.8 suite + 1–2 continuation allowance | 12.8–13.8 |
| Fresh walk discovery/repairs/tail placeholder | 19 |
| Two 11.8 repair suites + 4 diagnostic allowance | 27.6 |
| Complete plant matrix placeholder, now needing extra solo work | 14–17 + unmeasured solo cost |
| Final suite | 11.8 |
| Fresh take | 16–21.2 |
| Reserve/exam placeholder | 4–8 |
| Total | **105.2–118.4 + extra prefixes/solos/retries** |

The 11.8 suite is T1's **estimate**, not a new end-to-end measurement, and is usable only after the split/producer issue is resolved. Original unsplit **18.7** normal routing instead gives **~132.8–146.0 min**, with the same uncertain walk/matrix assumptions and additions. The matrix's old 14–17 figure is not established serial work for the expanded D2-A queue; do not treat this table as an upper bound.

Even applying the measured **1.5x to every minute**, an unjustifiably generous assumption, the conditional 105.2–118.4 becomes **70.1–78.9**, before extra work. Dependencies and nonoverlapped work increase it. The old blanket 9–10 min saving is also unearned; subtracting it would leave ~95–109 conditional minutes. Only an actual eligible job queue with measured contention can produce an accepted union projection. **There is no demonstrated <=75 plan. With currently qualified normal ordering the projection exceeds 75: stop/report INCOMPLETE under D5, not launch the scored replay hoping it fits.** Qualification, encoding and full watch stay separately reported; summed process cap remains 247.5.

## 4. Is REPLAY_USAGE enough, and commands only?

**No: useful draft, not a safe complete runner handoff.** It contains operational prose/comments and expected statuses rather than literally only commands; those instructions are useful and do not reveal benchmark holes. I found no benchmark-hole symptom or measured trial results copied into it. Qualification-command comments such as “prints SENTINEL PASS” describe expected output, not a benchmark result.

Its substantive gaps matter more than literal formatting:

- Default SPEED=fast commands authorize the unqualified split and marks setup; the caveat is only in a report the blind runner will not receive. Give a safe default and exact qualified routing/prelude policy in the handoff.
- Supply exact complete matrix/solo commands and a required-row reconciliation, not `<group>` plus “see GROUPS.” Current marks commands cannot satisfy the one-part proof judge; many needed solo groups do not exist.
- Adding new plants/checks after the printed freeze/final stage changes the tree. Explicitly move that work before freeze, or refreeze and rerun the final/affected evidence; never certify earlier final bytes against later checks.
- Require current picture inventory/state/inspection evidence and complete design-row review. The current final command does not enforce either.
- Use fresh paths until resume is qualified. Include control-environment clearing (GATE_PROBE, GATE_L2_CONTINUE, GATE_NOABORT, JOIN_GATE_WAIVED, GATE_RESUMES overrides and diagnostic speed overrides) before acceptance runs; these inputs are not sealed by hashing source files.
- `GATE_ONLY` is described as the second receipt, but successful resume handling removes resume_step without updating gate_step/gate_point for every later join. Do not promise this unqualified workflow as ready.
- Include the referee finish check explicitly. The T3 report says usage has that sentence; the inspected usage file does not state that seven holes and the blind exam require the referee's verdict.

**Verdict: REJECT as a ready, qualified <=75 replay build/handoff.** This does not reject the useful refusal, identity, cancellation and recording work. The build contains acceptance gaps and its current budget fails D5. Reconsider only after:

| Required correction/evidence | Miss guarded against | Cost |
|---|---|---|
| Close marks producer/order, or preserve unsplit normal chain; actual compatible integration receipts | Fast PASS from an ineffective setup | Normal fallback ~+6.9 per suite over the 11.8 estimate; qualification cost unmeasured |
| Require fresh, complete picture/state evidence and inspected captures | Green logs with missing/stale pictures | Offline guards plus actual captures/inspection; game cost unmeasured |
| Cover manifest self/dynamic local calls; complete solo/inventory proof schedule | New checks silently omitted; incomplete or batch-only proof called complete | Offline controls; solo proof game minutes unmeasured and charged |
| Seal real acceptance inputs; keep resumes/joins disabled unless identity, distinct resumes, complete outcomes and inventory are proved | Stale input or wrong/duplicated gate evidence | Offline repair; zero positive-resume qualification cost if fresh-only is retained, but real prefix/take costs remain |
| Fix handoff and investigate sentinel worker failures; measure eligible overlap without continuing off plan | Unqualified routing/workload sold as verified throughput | Documentation/offline work; any new live probe separately metered |
| Reconcile exact caps and produce a measured, complete <=75 queue or report INCOMPLETE | Budget overrun hidden by old rates and guessed savings | Zero game minutes to stop now; any further qualification needs referee allocation |

No tests were rerun and no code was changed in this audit.
