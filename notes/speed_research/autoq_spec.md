# Auto-qualify resume points: spec v1 (Claude Opus 5.5, 2026-11-17; for GPT's audit before the build)

**Goal (the user: A, 2026-11-17):** nobody sets or qualifies a resume point by hand. Builds on resume v1 (main
`d18a91d`, `resume_fix_result.md`): rv1 points, `walkgate` refusal / layers 1-3 / next_step / receipts, REPAIR.

## Facts this rests on (measured, offline, 2026-11-17)
- Ghat points that pass refusal + layer 1 today: **1, 3, 4, 9, 12, 13**. Every late point (14-19) is refused
  (held pot / physics contacts / engine on); 2, 5 engine on; 6-8, 10, 11 the global RNG while Problem hunts.
- So a failure at a late step can only be resumed from an EARLIER point. Today's REPAIR allows a change only in
  the resumed step itself, and the `test` hash (walks + scripts/dev) refuses everything else.
- Steps 14 / 15 take ~19 s / ~35 s; a resume costs ~25 s of launch + restore on top.

## Design (5 pieces)
**1. Pick the point (offline, seconds).** On a FAILED fresh walk (run.json `from == ""`) at step N: walk back
k = N, N-1, ..., 1 and take the first point of THAT run that passes `refusal` + `layer1` (rv1 record checked).
None -> "no resumable point before step N: next run fresh". A failure inside a RESUMED run: no new
qualification; its source point is reused if it already has >= 2 valid SAME receipts, else next run fresh.

**2. Qualify it (new games, automatic).** `tools/method/autoq.py <walk>` runs at the end of `play_walk.sh`
whenever the walk FAILED (exit 1). It resumes point k up to twice, each in a NEW game (`play_walk.sh` with
`--from <step k> FROM_POINT=<run>/k`, the walk file as it was), stopping at the first non-SAME. Each resume plays
on to the end. A resume counts only if its gate receipt is SAME on every layer AND a new layer **outcome** holds:
- **outcome** (in `walkgate.judge_resume`, non-REPAIR only): the resume ends as the producer ended: the same
  failed step and the same last FAIL line (times stripped), or both DONE. (Today's receipts judge step k only.)
- 2 SAME receipts (distinct runs + pids, as `repair_check` already demands) -> QUALIFIED.
- Qualification resumes don't rewrite `<walk>_last_fail.json` (msg flag `no_last_fail`; the game skips it).
- Before each resume `autoq` checks the tree identity still equals the producer's; changed -> stop, NOT QUALIFIED
  ("files changed while qualifying"). The receipts would be refused anyway; this says why early.
- Result `points/<walk>_autoq.json` + `last_fail.json` rewritten: `{"step": <step k>, "point": "<run>/k",
  "qualified": true}` or `{"fresh_next": "<why>", ...}` (producer, N, FAIL text kept for a manual retry
  `autoq.py <walk> --again`).

**3. The default rerun (`live.py resume_step`).** Reads `last_fail.json`: `fresh_next` -> fresh, with the reason
printed; else it runs `walkgate.admit` itself: refused for identity (game / bin / testcode / tools changed) or
no qualification -> **fresh automatically**, reason printed (no more exit 5 + a manual `--fresh`). An explicit
`--from` keeps today's behaviour (refused = exit 5). `--gate-check` and the walk call decide the same way.

**4. REPAIR widened.** Allowed from a qualified point k when: setup and steps[:k] unchanged; step k's name and
non-action keys unchanged (actions = do / expect / max / allow, as now); **steps after k may change freely**
(they are played live from a state proven equal); game, bin, tools, testcode equal the producer's and the
receipts'. If step k itself is unchanged, layer 3 and next_step still run for step k (a stronger REPAIR); if its
actions changed, they are skipped (as now). A REPAIR never counts as SAME.

**5. New-puzzle restore check (one-off).** `tools/method/restore_check.py <walk>`: needs a fresh producer of
the current identity run with `WIDE_OBS=1` (else plays one), then resumes up to 3 admissible points spread over
the walk, one game each, `--stop-after <step k>` (the walk cut after step k: one step only) and
`GATE_L2_CONTINUE=1` (go on past a DIFFERENT to collect everything).
- `WIDE_OBS=1`: a GENERIC observation (new `GateObs.wide`): every scripted node under the world, its script vars
  (as GateObs values) and local pose; written at each point (`<i>.wide.json`) and right after the restore
  (`<k>.restored.wide.json`). GateObs itself is ghat-specific, so it can't see a new puzzle's node.
- Report (`<run>/restore_check.md`): layer-1 unclassified fields, layer-2 diffs, and the wide diffs grouped by
  node, each with a fix: a node in a group not in `LiveControl.LIVE_GROUPS` -> "add group 'x'"; a creature's
  child -> "add it to gate_inventory `problem_children`"; else "the restore misses <node>.<var>". Known noise
  (measured on a clean ghat point first) goes in `gate_inventory.json` `wide_volatile`.

## Proof on the ghat walk (~11 game min, metered; GTA closed, CPU noted)
| # | Run | Must show |
|---|---|---|
| 0 | offline: `rv1_controls.py` 148/148 + new cases (outcome layer, widened REPAIR, point walk-back, fresh fallback, last_fail rewrite) | each new guard seen failing when off |
| 1 | producer: fresh walk, planted test-side failure at step 15 (`cool enough` expects `temp <= 10.4`, a typo, within 5 s), `WIDE_OBS=1` (~5 min) | FAILED at step 15; walk-back skips refused 14, picks 13 |
| 2 | must-fail: `autoq --again` with `AUTOQ_PLANT=hearing` (resume 1 restores without hearing) | DIFFERENT -> stops after 1 game, NOT QUALIFIED, `--gate-check` says fresh |
| 3 | `autoq --again` clean (2 games, ~1.4 min each) | 2 SAME + outcome same (FAIL at 15) -> QUALIFIED |
| 4 | the fix: `make_ghat.py` regenerates the right expect; default `play_walk.sh ghat` (~2.4 min) | REPAIR from 13 (step 13 unchanged: layer 3 on), DONE |
| 5 | restore check on point 13: clean + `GATE_DROP=groups` (restore skips LIVE_GROUPS), 2 x ~0.6 min | clean: no misses beyond the noise list; plant: names `ghat.*` and "add group 'ghat'" |
| 6 | offline: a game-code change (touch a game file) -> `--gate-check` default says fresh, `--from` exits 5 | |

## Not in v1 (said so)
Held-item and engine-on adapters (next job). Qualifying several points per failure (only the nearest). Recorded
acceptance takes stay FRESH (v7): `record_walk.sh` gets no auto-qualify. A resumed run's own points are never
producers.

## v2: after GPT's audit (GPT-6.1 Sol, high: BUILD WITH CHANGES, `audit_autoq_gpt.md`; all 8 taken)
1. **Walk bound by content:** SAME needs the identical walk (all keys); a different walk can only be REPAIR:
   setup, every top-level key, steps[:k] and step k's name / non-action keys equal; later steps free. A re-armed
   watch (`needs`) binds to the nearest definition BEFORE the needing step (the game took the last one anywhere).
2. **Spill:** layer 3 runs only when every step inside the producer's +3 s window is unchanged; next_step only when
   step k is unchanged; otherwise "n/a: <why>", never SAME. Same rule live (`gate_step`) and offline (`judge_resume`).
3. **Structured end record** `<run>/end.json` (status DONE / FAILED / STOPPED, failed index + name, kind: expect /
   watch / do / limit / needs / gate / abort / break / van_stuck / naresh / taken, check name, text, outcomes:
   [index, PASS/FAIL, check] in order). Outcome layer: same status, index, kind, check, and the same ordered outcomes
   from step k on; diagnostics (text) not compared. gate / abort / break failures never qualify; no end.json = no.
4. **Lifecycle:** child mode (`AUTOQ_CHILD=1`): no post-run hook, no last_fail write or delete. autoq only for the
   run named in last_fail, with an end.json FAILED; one record per producer point + identity: run once, again
   only with `--again`; atomic writes; last_fail rewritten only if it still names that run.
5. **One decision:** `walkgate.default_start` used by `--gate-check` and the walk alike: a default resume needs >= 2
   valid bound SAME receipts and NO valid DIFFERENT one (a DIFFERENT disqualifies the point); else fresh, reason
   printed. Explicit `--from` keeps exit 5. last_fail keeps step name + index. A resumed run's failure maps to its
   own source point (never a producer). Planted-control receipts (drop / perturb / l2_continue) never count.
6. **Candidates checked offline:** skip k = 0, a missing / malformed point, obs or +3 s sample, a +3 s sample with a
   FAIL in it, a resumed producer; every skip reason recorded.
7. **Wide check is a diagnostic only:** its own report, never a receipt; the walk stays whole (a runtime
   `stop_after`); scripted nodes' vars + local pose + visible, and their unscripted descendants' engine state
   (timers, sounds, animations, particles, near poses); no auto-masking; capture ms / bytes measured; blind spots
   listed (autoloads, statics, resources' insides); fixes written as hypotheses.
8. **Controls:** an offline planted case for every new guard (`autoq_controls.py`), each seen failing with its
   guard off; game proof ~12 min (the user may cut the wide pair: B).

AUDITED: GPT-6.1 Sol, high, `notes/speed_research/audit_autoq_gpt.md` (BUILD WITH CHANGES 1-8, all taken in v2)
