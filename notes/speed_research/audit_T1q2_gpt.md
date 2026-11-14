# GPT audit: T1 qualification round 2 — 2026-11-14

**Verdict: ACCEPT WITH CONDITIONS. The remaining open-overrun and solo-attribution clauses are closed for the inspected qualification inputs. The final mode table is usable as a conditional replay policy, not permission to count fast PASSes before the existing shared gates are met.**

Evidence root `R` below is `D:/mine/Agentics/T3_Code_Works/MPG_speed_t1/appdata/method/runs/`; all directly inspected runs match `20261111_12*`. I checked run identities, verdicts, traces and CHECK events, plus the permitted `4a74146..709028b` diff. The authorized offline command `python -B tools/method/t1fix_controls.py` exited 0: **38/38 as expected**, with 48 archived runs scanned by that script. Its archived inputs and generated control copies are covered by the explicit permission to execute it; I did not separately open older run folders. No game was run, no code changed, no C: output requested. This audit is my only authored file.

Scope disclosure: my first batch requested the whole permitted `trial_T1.md`, rather than extracting only “Qualification round 2”; that was broader than the requested section. Subsequent report reads extracted that section. I opened no excluded project folder or skill. The report's production-code explanations are claims, not independently inspected source: those production files are outside this audit's allowlist.

## Conditions 2 and 3

| Claim | Decision | Run evidence |
|---|---|---|
| Original open overrun rerun at both speeds | **CLOSED**, with the earlier late-close repair retained | `120734_ghat_k3_overrun_fast`: `overrun_control#2` open **10.33 game / 5.40 wall s**, deadline 10, game clock fires. `120754_ghat_k3_overrun_laneb`: **9.90 game / 10.04 wall s**, wall clock fires. Raw events OPEN the step with `secs:10.0` and never CLOSE it. Both verdicts are **INCOMPLETE, code 2**, with a named STALLED condition; neither is PASS. Both drained, kill verified, remaining processes empty. |
| Every formerly batched plant causes its own named failure alone | **CLOSED for D2 option A**, building on the previously qualified clean controls | The table below gives isolated fixtures and exact failed IDs. This closes the neighbour-attribution gap; it does not qualify jug PASSes for fast mode. |
| Final sealed replay bytes qualified | **NOT CLOSED** | Q1 records head `a9eaa88`; solo runs record `68fda8a`; marks retries record `9598cc1` and `c880e3d`. The permitted diff shows later changes including the prelude gate and test diagnostic. These records establish the tested inputs, not a single sealed final replay identity. Deadline logic is not changed by the inspected round-2 diff. |

Solo evidence, all under `R/20261111_`:

| Fixture | Run suffix | Required ID present in `failed_ids` |
|---|---|---|
| fast_turn | `120900_ghat_k3_fast_turn_fast` | `ghat_looks/it_turns_away_slowly_fastest_x_deg_s` (314 deg/s) |
| leave_sees | `121003_ghat_k3_leave_sees_fast` | `ghat_jug/out_beside_it_after_it_gave_up_nobody_is_taken` |
| no_breath_lock | `121101_ghat_k3_no_breath_lock_fast` | `ghat_jug/holding_your_breath_ctrl_b_never_touched_the_handbrake` |
| round_skip | `121155_ghat_k3_round_skip_fast` | `ghat_jug/it_went_all_round_the_van_before_it_gave_up_x_stops` (0 stops) |
| marks_unsaved | `121506_ghat_k3_marks_unsaved_fast` | `ghat_marks/the_marks_are_saved_and_come_back_on_load_x` (0 marks loaded) |
| marks_pile | `121856_ghat_k3_marks_pile_fast`, `122125_ghat_k3_marks_pile_fast` | `ghat_marks/a_clean_van_to_start_with`, with the looks round ID in `passed_ids` in both |

The corresponding trace CHECK failures agree. Every listed run drained and has an empty remaining-process list. Early-stopped cases have verified kills; the two diagnostic marks runs ended normally with wrapper exit 1, so their null `kill_ok` is not an unchecked forced stop. `leave_sees` also fails “the net comes off”; that collateral failure does not replace its required ID.

## Values and the marks prelude

| Question | Closed? | Finding |
|---|---|---|
| Fuel gap 1.06 L versus old 0.5 L tolerance | **Closed narrowly for the existing heat checks; limited calibration** | New 1x runs `120925_ghat_k3_one_corner_laneb` and `121207_ghat_k3_one_corner_laneb` record **60.79 -> 60.79 L** and **62.15 -> 62.15 L**, a **1.36 L** spread on the same one-corner fixture. Both record **2.0 L leaked, cap 17.5**, and no failed checks. The new measured spread already exceeds the old 1.06 L differential. The prior audit supplies the old 62.17/61.11 comparison; the other historical samples are report-only here. A provisional **1.4 L pairwise observation tolerance**, preserving the leak cap and exact stopped-leak invariant, is reasonable. It is not a proven statistical bound or proof that speed has zero fuel effect. Both new runs are correctly INCOMPLETE because the three-profile comparison was omitted; neither is a full clean heat PASS. |
| Engine ticks and sniffs explained | **Not independently closed as production-code causal claims** | New isolated looks runs with a round show 26 ticks and 2 sniffs. That supports consistency, but does not verify that the cumulative counter never resets or that the second-sniff probability is exactly 0.8. The permitted diff contains neither implementation. No need to waive this evidence limit: looks remains 1x for an accepted PASS. |
| Lean/glass speed gap | **NOT CLOSED; restriction accepted** | No new isolated lean_close comparison in these folders. Retain the prior audit's measured shift and unreliable 1x plant. Fast being stricter in those samples does not establish equivalence. Glass and the accepted looks run stay 1x; firming the plant remains open. |
| Marks prelude cannot silently lose the marks_pile proof | **CLOSED for the observed failure and proof gate** | `121248_ghat_k3_marks_pile_fast` has 0 stops, 0 sniffs, failed round ID, and marks' clean-start check PASSes despite the plant. This is genuinely ineffective setup, not a successful plant proof. The new PREREQ checks the same-run round PASS; offline controls reject a no-round proof. The two later solo retries each have 4 stops and fail the clean-start ID. |
| Marks independent of every looks difference | **Conditional, not a general causal proof** | The reset/counter arguments and historical 17/17 text comparisons are not independently reproducible within this reading scope. Direct evidence does establish the relevant prerequisite failure and its gate, then successful isolated detection. Keep the earlier qualification only for the existing marks checks with the same looks prelude and state checks; do not infer arbitrary new setups are equivalent. |

The no-round fault remains **open**. I directly verified this round's occurrence and two successful retries, not the report's historical 2/14 versus 0/5 census. In the failed run, the glass check even PASSes at the sentinel-looking **99.00 m**; that reinforces why individual PASSes cannot substitute for required coverage. The overall run FAILs loudly. Keep that failure on record, investigate, and use a 1x rerun for accepted evidence; never retry fast until green and erase the failure. The diagnostic's two successful rounds did not reproduce or explain the fault.

## May the replay use the final table?

**Yes, as this restricted policy, subject to the shared gates below.**

| Path | Allowed accepted mode |
|---|---|
| net, existing qualified checks | Fast, retaining prior exact plant and picture requirements |
| heat, existing qualified checks | Fast with the provisional fuel observation tolerance above; behavioral thresholds unchanged |
| marks, existing qualified looks -> marks setup | Fast only with the same-run looks round ID PASSed, required marks state/coverage checks satisfied, and no prerequisite failure hidden by selecting marks-only results |
| looks, including glass | 1x; fast exploratory only |
| jug, places, spring, free_coolant proof, recorded walk | 1x |

**Still open before fast PASSes count:** seal tool/game/test identities and qualify affected changes; inspect required captures and retain freshness/state evidence; establish split/reset order or preserve the qualified chain. Use serial isolated execution until lane isolation and nodraw capture interleaving are proved. Serial execution alone does not prove a changed order is safe. The PREREQ addition directly guards `prove_ghat.py` plant proofs; it is not by itself a new clean-run acceptance gate, so the replay must actually retain/enforce the stated prelude and coverage requirement.

The reported **11.8 versus 18.7 minutes is an estimate**, not a measured end-to-end replay result. Raw invocation refusals, the meter and historical full differentials are outside my direct read scope; their reported totals are not newly certified here. No unconditional “all shared gates closed” or unrestricted replay GO follows from this audit.
