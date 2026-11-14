# Stage 3: GPT checks that its v2 specs were BUILT AS WRITTEN. Written by the referee, 2026-11-14.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `top4.md`, `trial_T3_spec_v2.md`,
  `trial_T4_spec_v2.md` (your specs), `audit_specs_claude.md`, `answer_specs_gpt.md`, `audit_T1q2_gpt.md`,
  `trial_T34_v2_build_task.md`, this file
- In `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34`, head `f208e6e`): `notes\speed_research\
  trial_T4_build.md`, `trial_T3_build.md`, `REPLAY_USAGE.md`, `tools\` (read the code), the run folders under `appdata\`,
  and `git -C D:\mine\Agentics\T3_Code_Works\MPG_speed_t34 diff 709028b f208e6e`.
- Read-only: run nothing (a Claude auditor reruns the offline controls in this copy at the same time; two runs would
  overwrite each other's fixtures under `appdata\t3ctl`, `t4ctl`).

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t1` or any other `MPG_*` folder not named above; the skill testing-and-verification §3b.
Opened one by mistake: stop and say so.

## Your role
The author of the specs, now a strict auditor of their build. You write no game code or test code and run no game.
Every verdict cites code / a log / a receipt; no evidence = NOT SHOWN.

## Check
1. Every piece of `trial_T4_spec_v2.md` and `trial_T3_spec_v2.md` (and the user's decisions D1 = joined take allowed when
   every join is SAME; D2-D4 = your option A, each removable; D5 = stop and report past 75): BUILT AS WRITTEN / BUILT
   CHANGED (is the change named in the report, and is it sound?) / NOT BUILT / UNQUALIFIED.
2. Your T1 round-2 conditions (input sealing, split order, picture freshness): closed by this build or not, with evidence.
3. The builder's finding that no point of its probe walk can pass the resume gate, and that a clean resume still differs
   at layer 3 (see "Resume 2026-11-14" and "Live gate session G"): does it change your replay playbook (fresh takes only,
   D3 / D4 unused)? Give the playbook's new cost from the MEASURED numbers in "Re-measure (PC idle)" (recording ~52 % of
   real time overall, ~62-70 % in the walk; two lanes 1.5x), not from your earlier estimates, and say what is still a guess.
4. `REPLAY_USAGE.md`: enough, and only commands (no results, no game symptoms)?

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T34_gpt.md`: the four sections, then ACCEPT / ACCEPT WITH
CONDITIONS (each with the miss it guards against and its cost) / REJECT. **Reply:** 6 lines.
