# Final resume audit — GPT, 2026-11-17

**Verdict: DON'T SIGN the branch for merge yet. The bounded P13 qualification itself is supported.**

Read-only audit except this file: no game/Godot/walk, code edits, commits or pushes; MPG_referee not read.
I reviewed acb86a5..resume and rejudged the saved evidence with Python -B, in memory, without file writes.
I did not execute rv1_controls.py: it deletes/recreates its work directory (lines 213–216), contrary to this task's one-file limit.
Paths below are relative to MPG_dev. WG = tools/method/walkgate.py; RV = FindingNaresh/scripts/dev/ResumeV1.gd;
LC = FindingNaresh/scripts/dev/LiveControl.gd; GO = FindingNaresh/scripts/dev/GateObs.gd.
P = appdata/playtest/FindingNaresh/live/points/.
F = ghat_rp14_20261117_212548_20588; R1 = ghat_rp14_20261117_213038_19488;
R2 = ghat_rp14_20261117_213120_24296; X1 = ghat_rp14_20261117_213204_25240;
X2 = ghat_rp14_20261117_213241_25228; REP = ghat_20261117_213319_23712.

CHANGE FIRST items from audit_resume_results_gpt.md:

1. Flush lifecycle: DONE for ordinary returns, including early returns from _run_walk; LC:122–123 resets the flag after awaiting it. Stick-only flushing is PlayTest.gd:1330; keys/buttons retain their old path.
2. Exception identities: DONE; GO:114–120 sorts body references rather than counting exceptions, used at GO:41,53,72.
3. Release-time gap: DONE in the live path; LC:736–755 synchronously compares the approved final observation to release, with no intervening await before actions at LC:849. Unsupported/open-needs boundaries remain excluded.
4. Hearing expiry: DONE for the reported hole; WG:286–293 preserves <=2000 versus >2000. Independently tested 1995/2005 and 2000/2001 -> DIFFERENT; 1990/2000 and 2005/2015 -> SAME. Controls exist at tools/method/rv1_controls.py:171–181.
5. Malformed adapter coverage: PARTIAL, still a blocker. The exact earlier empty-container/body-pose cases now refuse (WG:119–170), but complete coverage, supported payload kinds and finite values are not enforced; reproductions below.
6. Client identity: DONE for the reported paths; WG:580 enforces tools/testcode in admission; WG:704–706 enforces them in receipts; boundary uses that judge at WG:733. Controls: tools/method/rv1_controls.py:275–294.
7. Duplicate qualification: DONE for run/process counting; WG:736–742; tools/method/rv1_controls.py:279–289 exercises duplicate runs with a stubbed SAME judge, not a live restore.
8. Fresh proof after freezing identity: DONE for this boundary; P/R1/13.gate.json:23–30 and P/R2/13.gate.json:23–30 have no failed layers. Gate/point hashes match current files on independent recomputation; game PIDs are 23712 and 10308 (line 5), not the client PIDs in folder names.
9. Timing bench: PARTIAL. LC:575–583 logs 12 initial ticks; P/F/13.t3.json:1 and both resume samples show stick 0 at tick 1, -1 at tick 2 and matching initial movement. They still differ in floor status at tick 3. No controlled flush-off/on, player-read-axis/callback trace, key/button/mouse-order bench or deliberately delayed-verdict negative is supplied. Final-chain holds are 307–754 ms (appdata/resume_R2b.out:12; resume_REP.out:13).

Qualification and paired controls:

- Independent boundary(F,13,[R1,R2]) = SAME. All immediate/final comparisons, identity, +3 s and next-step checks pass; independently comparing release observations to F also returns no differences.
- The trajectory configuration is structurally IDENTICAL to acb86a5's trajectory configuration: 0.05 m / 2 degrees, velocity 0.05 m/s, original event/input/outcome bounds. WG:440–510 applies it without a new tolerance escape.
- Both resumes sample at 3000 game ms; P2 is 0.016731 m from F, below 0.05 m (P/F, P/R1, P/R2/13.t3.json:1). Their next-step result is PASS full pot (appdata/resume_R1b.out:16; resume_R2b.out:16).
- X1 rejudges DIFFERENT specifically for van.@xf 0.200 m at layer 3 (P/X1/13.gate.json:27–29; appdata/resume_X1.out:12–16). Other immediate/final/release comparisons pass; next_step failure is the subsequent abort.
- X2 rejudges DIFFERENT specifically for hearing serial 214 -> 6 and queue contents at layer 2 (P/X2/13.gate.json:25–39; appdata/resume_X2.out:8–9), before step input. Missing later samples/final observation are consequences of that early stop, not independent evidence against it.
- REP rejudges REPAIR, not SAME (P/REP/13.gate.json:30). Its actual success is supported separately by appdata/resume_REP.out:16–27: full pot, refill, over pass and DONE in 117 s.
- No false SAME was observed in this final chain. This qualifies F/13 with this profile/protocol/identity and next step; it does not establish complete engine state, arbitrary points, engine-on/held-body support or sound acceptance. The refusals remain at WG:336–345.

Remaining blocker (offline reproductions on copies of the actual F/13 record; no evidence files changed):

- Set live_frames[0].kind = "unknown": validate_rv1, coverage_rv1 and refusal all return []. WG:155–158 checks only recognized branches; it never requires a supported kind for each owner/field. RV:120–130 then interprets this record using different assumptions.
- Delete live_problem_children.xf["0"]: all three functions again return []. F has 14 children/14 poses; WG:168 accepts any nonempty pose map with count >= its length. It does not establish expected child-path or script-field coverage.
- Set rng_seed = float('nan'): all three again return []; WG:64 only checks numeric type. Supported finite/integer seed validation was requested, not mere presence. Clock units likewise are not bound to owner/field contracts (WG:88,140–149).
- These are admission holes, not proof that the supplied clean runs restored incorrectly. Later L2 can catch observable consequences, but cannot substitute for the explicitly required fail-closed schema/coverage guard. Add these exact negatives and clean pairs; do not claim all requested validation is complete (resume_fix_result.md:38–40).
- Receipts do not independently judge release.obs.json (WG:709–724); live enforcement and the saved transcripts/observations close that question for this chain. I think recording release verdict/failure explicitly in receipts would make future offline audits safer.

Saving and claims:

- The ESTIMATE/one-sample/no-fresh-fixed-baseline labels are honest (resume_fix_result.md:18–27). 265 s prefix + 117 s suffix + ~3 s stop = ~385 s; REP launch-to-stop = 142 s (appdata/resume_REP.out:1,37): ~243 s saved, ~2.71x. This is a splice, not a measured fresh repaired walk or a guarantee per repair.
- The result correctly says a real failed-step repair was NOT demonstrated (resume_fix_result.md:25). Other checkpoints and ~20 s overhead remain extrapolations; REP's measured overhead is ~25 s.
- The categorical old-cause claim, "FRESH run was the odd one" due to drawn-frame input delay (resume_fix_result.md:35–36), remains stronger than the controlled evidence. The final proof shows the new protocol passes; it does not isolate the old 0.288 m discrepancy's sole cause.
- Budget overrun is disclosed (~23.5 vs ~20 minutes, resume_fix_result.md:43–45); appdata/meter_resume.log records aborted/compile launches too. I did not independently verify the user's approval from a conversation outside this task.

**DON'T SIGN — not fit to merge yet:** finish the mandatory fail-closed coverage/kind/finite guards and correct the "all fixed" claim, then obtain targeted offline proof. The diff is tools/test code plus notes only; no gameplay source changes were found. P13's bounded SAME and the named X1/X2 evidence stand. User decides the merge; this audit authorizes none.
