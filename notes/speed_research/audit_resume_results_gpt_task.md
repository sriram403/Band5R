# Task: audit the resume-fix RESULTS so far (GPT, strict auditor)

**Read-only:** everything except your one output file. **Do not:** write or edit code, run the game / Godot / any walk,
commit, push. **Do not read:** `D:\mine\Agentics\T3_Code_Works\MPG_referee\`.
**Write exactly one file:** `D:\mine\Agentics\T3_Code_Works\MPG_dev\notes\speed_research\audit_resume_results_gpt.md`.

## Context
You audited the design (`notes/speed_research/audit_resume_fix_gpt.md`, BUILD WITH THESE CHANGES); Claude accepted all
8 (design v2 in `resume_fix_design.md`) and built it on branch `resume` (MPG_dev, commits 602020b..6acecfd). Read
`git log --oneline main..resume` and the diffs. The live evidence (all in
`MPG_dev/appdata/playtest/FindingNaresh/live/points/`, transcripts `MPG_dev/appdata/resume_*.out`):
- F (old build) `ghat_rp14_20261117_205524_24252`; R1 of it (old build) `ghat_rp14_20261117_210039_23600`: layer 2
  DIFFERENT in 34 fields -> fixes in a239f25 (bit-exact bytes, refs, frame stamps as ages, obs clock at its start).
- Bench `ghat_bench2_*` (2-step producer + resume, GATE_PROBE): 3 far sleeping items 1e-7 off -> e8a7cd4 (local pose
  under the same parent); then layer 1+2 + final check SAME.
- F2 `ghat_rp14_20261117_210651_22032` (producer, point 13 = start of step 14); R1 `..._211154_21124` and
  R2 `..._211516_20984` (GATE_NOABORT=1): layer 1+2 SAME, final pre-input check SAME, layer 3 DIFFERENT
  (`p2.@xf` 0.288 m / 0.25 deg), R2 step-14 outcome = F2's; `walkgate.py l3` R1 vs R2 = no difference.
- Claude's reading: the fresh run F2 is the odd one (P2's 3-s travel F 12.494 m @48 fps drawn, F2 12.208 m @32 fps,
  R1 12.496 m @41 fps): test inputs are applied at the next drawn frame. Fix built, unproved (6acecfd: walk inputs
  flushed in the tick they are sent). Mistake log: `notes/ROUGH_NOTES.md` (last 2 entries).

## Write (strict; evidence = file + number, or "I think")
1. Is the reading right? Check the numbers yourself (t3 samples, obs meta frames_drawn / physics_frames, inputs). Name
   any other cause that fits the data equally (and what cheap evidence would separate them).
2. Is the flush fix correct and enough (Godot input buffering / agile flushing; order of the sender vs the player's
   `_physics_process`; anything else in a walk that waits on drawn frames)? Any risk to other walks?
3. Were the build fixes faithful to your 8 changes? Any new hole (false SAME) in a239f25 / e8a7cd4 / the controls
   (`tools/method/rv1_controls.py`)?
4. The next proof plan and its game minutes (the user's budget was ~20; 13.5 used): what is the minimum that would let
   point 13 count as qualified SAME, and is a layer-3 bound change justified by any measurement (or not)?
5. Verdict: PROCEED (with which runs) / CHANGE FIRST (numbered) / STOP. Under ~100 lines, plain words.
