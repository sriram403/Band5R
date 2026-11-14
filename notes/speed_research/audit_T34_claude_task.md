# Stage 3: the Claude auditor checks the T3 + T4 v2 BUILD (results vs claims). Written by the referee, 2026-11-14.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `top4.md`, `trial_T3_spec_v2.md`,
  `trial_T4_spec_v2.md`, `audit_specs_claude.md`, `answer_specs_gpt.md`, `trial_T34_v2_build_task.md`, this file
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34`, head `f208e6e`): everything, especially
  `notes\speed_research\trial_T4_build.md`, `trial_T3_build.md`, `REPLAY_USAGE.md`, `tools\`, the run folders under
  `appdata\` (`t34\`, `t3ctl\`, `t4ctl\`, `method\`, `playtest*\FindingNaresh\live\`, `videos*\`), and `git log` / diffs of
  `speed-t34` against `speed-t1` (`709028b`).
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- You may RUN offline only: `python tools/method/t3_controls.py`, `t4_controls.py`, `t4_join_controls.py`,
  `t1fix_controls.py` (no game).

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t1` or any other `MPG_*` folder not named above; the skill testing-and-verification §3b.
Opened one by mistake: stop and say so.

## Your role
A strict auditor (two-model-research). The builder's reports are CLAIMS; the run folders, logs, receipts and code are the
evidence. "Looks good" is not an audit; every verdict cites a file / line / log; no evidence = NOT SHOWN.
No game runs, no code changes; write only your one file.

## Check, row by row (CONFIRMED / WRONG / NOT SHOWN, with evidence)
1. Every row of the "Game runs" table in `trial_T4_build.md` and every result in `trial_T3_build.md`: does the evidence
   say what the report says? Rerun the offline controls and give your own counts.
2. **Every control fixture pair** (planted case and clean case), in `appdata/t3ctl` and `appdata/t4ctl`: the expected
   verdict vs the actual one, for both speeds. List any pair where the planted case does not fail, or where the 1x and
   fast cases disagree, and say whether that is designed (cite the control's code) or a slip.
3. **The resume gate.** The builder says no point of the probe walk can pass the gate (a parked, frozen van with a stored
   velocity of 0.148 m/s; the engine on from point 3), and even a clean resume differs at layer 3 (`nav_aside`, players
   5.5 cm, van temperature 1.6 C). From the code and the logs: is each difference real lost state that would change what
   happens after a resume (so refusing is right), or a gate that compares something with no effect (so the gate is too
   strict)? Godot 4 facts you rely on: say how you know them. If only a game run can settle a point, say which run and
   its cost; don't run it.
4. **The nav swing.** The builder reports that pad A / the N key sometimes does not swing the nav when a walk is replayed
   in the same game (lane b's workload passed 2 of 4 walks, A2 and G too). Test side or game side, from code and logs?
   What would it cost a replay that plays several walks in one game, and what does the tool do about it?
5. **`REPLAY_USAGE.md`:** every command exists and does what the line says (read the tool); nothing in it is a trial
   result or a game symptom; anything a runner needs that is missing.
6. Every place the build departs from the v2 specs or from `top4.md`, and whether the report names it.

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T34_claude.md`: the six sections, then a verdict for the
build: ACCEPT / ACCEPT WITH CONDITIONS (list each, with the miss it guards against and its cost in game minutes) / REJECT.
Commit nothing. **Reply:** 8 lines.
