# Stage 3: the Claude builder's FIX ROUND for the T3 + T4 v2 build. Written by the referee, 2026-11-14.
AUDITED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T34_gpt.md
AUDITED-ALSO: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T34_claude.md

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md` (ruling **R7**), `audit_T34_gpt.md`,
  `audit_T34_claude.md` (the conditions you close), `trial_T3_spec_v2.md`, `trial_T4_spec_v2.md`, `top4.md`,
  `trial_T34_v2_build_task.md` (your earlier task: its rules still hold), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside your copy `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34`, head `f208e6e`)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t1` or any other `MPG_*` folder not named above; branches or commits other than `speed-t34`,
`speed-t1`; the skill testing-and-verification §3b. Opened one by mistake: stop and say so.

## Rules (as before)
Build what is listed, add no ideas, report every change. Work ONLY in `MPG_speed_t34`. **Commit after every finished item**
(the message names the item, e.g. `F2`). No push; nothing on C:. **Game code untouched** (`FindingNaresh/scripts/` except
`scripts/dev/`, scenes, assets, `core/Plant.gd`). A game bug you notice: **your reply only, never a file.** Every new guard:
its planted failure is refused AND its clean case passes (and the planted case must fail BECAUSE of that guard, not another).
**Games: 5 wall game min for this round (hard), at most 1 game at a time except inside F5's bench**; before each run write
its cost and the running total; watch it while it runs; CPU load beside every timing. Three failed fixes of one thing: stop,
write where you got. The referee's meter and watch are on this copy.

## Fix list (the union of both audits; R7 decides the resume questions: fresh takes only)
- **F1** REPLAY_USAGE step 0 runs only self-checks that work in this copy (`t1fix_controls.py`: ship its fixtures or drop it
  from step 0, say which). (Claude C1)
- **F2** The 7 identity controls in `t4_controls.py` fail if their identity check is removed (call `identity_check` directly or
  start from `quiet()`); show one of them failing with the check disabled. (Claude C2)
- **F3** REPLAY_USAGE for **fresh takes only** (R7): the clean walk and the video are ONE unbroken fresh take; a failed take
  is fixed and taken again `--fresh`; the gate stays on (a resume attempt will be refused: budget fresh prefixes); remove
  promises the real ghat walk can't keep (`framemap_rec25.json` for ghat, `GATE_ONLY` second receipt). (Claude C3, C5; GPT)
- **F4** Save the sound evidence: `join_check.py sound` on R1b's mp4, keep the `SOUND:` line in a file. (Claude C4)
- **F5** The dropped key presses: a bench (<= 1.5 game min) of 20 N taps with and without a second window coming up, logging
  focus-out; if confirmed, a test-side fix (re-send a dropped tap the way `hold_physics` does, never a second edge) with its
  control; and `lane_sentinel.sh` must not print PASS when its worker walks failed. (Claude C6; GPT "sentinel worker failures")
- **F6** Marks keeps its looks prelude: route marks so it runs in the same process right after a looks run that made its round
  (or unsplit / 1x, whichever is simpler), and `t3_gate.py final` refuses a marks PASS without that same-run prelude receipt;
  the marks plant proof fits the proof judge. Offline controls (planted: marks without prelude -> refused; clean -> accepted).
  No live suite run in this round: the gate is fail-closed and the replay's first suite is its live use. (GPT)
- **F7** Picture evidence: every run writes a capture inventory (scenario, check / step id, frame number, file hash, written
  after the launch); `final` refuses a missing, stale (older than the launch) or duplicated required picture, and requires the
  runner's inspection file (one line per required picture: what it shows). Offline controls. (GPT)
- **F8** Proof coverage: a solo group for every member of every multi-plant group (D2 A), the exact matrix command list in
  REPLAY_USAGE, and an offline reconciliation command that lists the 21 R4 rows + any new plant against proved results
  (missing = not done). New checks / plants go in before the freeze, or the tool forces a refreeze + a new final. (GPT)
- **F9** Acceptance runs (`ROLE=final`, proofs, the recorded walk) refuse when a test-only flag is set (`GATE_PROBE`,
  `GATE_L2_CONTINUE`, `GATE_NOABORT`, `JOIN_GATE_WAIVED`, `GATE_RESUMES`, speed overrides): a control each way. (GPT)
- **F10** The manifest traversal covers a scenario's self / local calls GPT names (see its section 1); dynamic calls stay refused.
- **F11** Reports: complete the T4 report (files / interfaces, a deviations section, the 83 pairs, R1 in-walk 57 vs 51 %,
  unique run ids, T3's R4 out of the T4 column, lane b's 2 / 4 walks, G4 + G5 named a failed live pair); a short "Fix round"
  section in each report. REPLAY_USAGE ends with: "The referee judges the holes and the exam; the runner reports PASS / FAIL
  per step only." Commands, safe defaults, **no results, no game symptoms**. (Claude C7; GPT section 4)

## Reply (10 lines)
Commits per item, each guard's control pair (planted refused / clean passed), F5's bench numbers, game minutes used, what
stayed UNQUALIFIED.
