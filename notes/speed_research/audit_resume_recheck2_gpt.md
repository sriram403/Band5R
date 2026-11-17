# Resume fix: second re-check (GPT, 2026-11-17)

**DON'T SIGN — child coverage closed; malformed child payloads still admitted.**

Read the task file first. Reviewed ce038c2 and its successor 161551a, current gate/inventory,
restore readers, result and v3 evidence. No MPG_referee access. Only this report written;
no game/Godot/walk, code edits, commits, pushes, or controls-script execution.
Reproductions compiled walkgate.py directly in memory (python -B); no bytecode/evidence writes.
F3 = appdata/playtest/FindingNaresh/live/points/ghat_rp14_20261117_212548_20588, point 13.

1. Previous three counterexamples: CLOSED, independently reproduced on deep copies of F3/13.
   - Rename xf["0"] to "999": coverage/refusal rejects extra 999 / missing 0, count 14.
   - Delete xf["0"] and set count=13: coverage/refusal rejects missing 0 / count 13.
   - Empty vars["2"]: coverage/refusal rejects script fields differing from the frozen list.
   Extra script owner 77 and deleting _gain also reject. Clean F3/13 has refusal=[].
   Gate WG=tools/method/walkgate.py:185-202 matches exact path/owner/field sets.
   Inventory matches F3: 14 poses, owner 2's ten fields. Creature.gd:143-208 and
   NoiseLoop.gd:10-49 support that tree and field list (object refs/audio RNG excluded).
   resume_fix_result.md now states the frozen-list guarantee, replacing the broader claim.

2. Remaining blocker: presence/nonempty-string checks do not validate child payload types.
   Independent mutations, each alone from clean F3/13:
   - live_problem_children.xf["0"] = "not-a-transform"
   - live_problem_children.vars["2"]["target"] = "not-a-variant"
   - live_problem_children.eye_energy = null
   Each gives validate_rv1=[], coverage_rv1=[], refusal=[]. WG:180-182,200 accepts
   these values; ResumeV1.gd:305-316 decodes/assigns poses/materials, and
   LiveControl.gd:509-518 decodes/assigns script values without an equivalent type guard.
   This violates resume_fix_design.md v2 row 7 (absent/malformed records fail closed).
   Require supported encodings, decoded types and finite numeric components, with paired negatives.
   This proves malformed admission to gate evaluation; no new false-SAME live run is claimed.

3. Independent boundary/judge outputs EXACTLY equal appdata/resume_rejudged_v3.json:
   gate hash 6292ecb6ab5a3879; F3/13 + R1/R2 SAME; X1 DIFFERENT (van 0.200 m);
   X2 DIFFERENT (hearing); REPAIR stays REPAIR. Saved clean proof remains supported.
   Controls 128/128 and guard-off failures are reported, not independently rerun here.
   One point, engine-on/held refused, saving estimate, and fresh producer after judge changes
   are correctly stated scope limits, not blockers. No new game proof requested for this audit.

**DON'T SIGN for merging resume into main until malformed child payload admission is closed.**
