# Resume fix re-check — GPT, 2026-11-17

**DON'T SIGN — exact negatives closed, but required child coverage is still incomplete.**

Read task first; reviewed eb3dd5c and current files in MPG_dev; no MPG_referee access.
Only this report written; no game/Godot/walk, code edits, controls script execution, commits or pushes.
WG = tools/method/walkgate.py; RV = FindingNaresh/scripts/dev/ResumeV1.gd; paths relative to MPG_dev.
Independent reproductions used deep copies of F3/13 in memory, compiling WG directly from source
(avoids cached bytecode); no evidence or control work folders changed.
F3 = appdata/playtest/FindingNaresh/live/points/ghat_rp14_20261117_212548_20588.

Original blockers / corrections:

1. Unknown frame kind: CLOSED for the reported case. WG:160–165 binds fields to supported kinds;
   live_frames[0].kind="unknown" now produces coverage/refusal errors. Clean F3/13 admits.
2. NaN seed: CLOSED. WG:64–66 requires a finite integer in [0, 2**31); NaN and 1.5 both refuse.
3. Deleted child pose: EXACT CASE CLOSED, COVERAGE BLOCKER REMAINS. WG:180–182 rejects deleting xf["0"]
   alone because count remains 14 while poses become 13. It checks cardinality, not expected paths/content.
4. Clock unit binding: WG:149–154 rejects changing van._cap_t from s to ms in my reproduction.
5. Offline release evidence: CLOSED. WG:727–731 requires release.obs.json and includes layer2_release
   in the verdict; missing release data now fails, including REPAIR.
6. Claims: resume_fix_result.md:35–36 correctly makes the old timing explanation a hypothesis.
   Its line 43 claim "a pose for every child" is still too strong; see counterexamples below.

Remaining admission counterexamples (each independently mutated from the same clean F3/13):

- Rename live_problem_children.xf["0"] to "999", retaining its value: validate_rv1=[], coverage_rv1=[], refusal=[].
  RV:305–307 silently skips that nonexistent path, leaving the real child 0 unrestored.
- Delete xf["0"] AND decrement count to 13: all three return []. The observation has only 13 unique pose keys
  for 14 children (auto-name collapsing), so the count supplied by the record cannot establish completeness.
- Replace live_problem_children.vars["2"] with {}: all three return []; WG:181 counts script owners only,
  while RV:308–310 receives no fields to restore. Required script-field coverage remains unproved.
- These are the previous coverage blocker's remaining forms, not evidence that the saved clean restores failed.
  Require independently established expected child paths and restorable script fields, with paired negatives.

Evidence / regression check:

- My source-compiled boundary and all individual judges exactly equal appdata/resume_rejudged_v2.json:
  F3/13 + R1/R2 SAME; X1 DIFFERENT at van trajectory; X2 DIFFERENT at hearing; REP REPAIR, never SAME.
- No newly introduced false-SAME regression found in the changed predicates; they tighten admission/judging.
  The unclosed child holes above still prevent the promised fail-closed validation sign-off.
- Controls 118/118 and guard-off failures are reported by eb3dd5c's commit message; I did not independently
  execute rv1_controls.py because it rewrites its work folder. Added negatives are at that file:190–201.
- Current gate hash is 320b561f2a82b607, matching the rejudged evidence. This is historical rejudging;
  live admission still binds producer tools/testcode identities (WG:670–690), so new use needs fresh evidence.

**DON'T SIGN for merging resume into main yet.** Close child path/script-field coverage and narrow the
remaining claim, then re-check offline. Bounded historical P13 SAME stands. The user decides the merge.
