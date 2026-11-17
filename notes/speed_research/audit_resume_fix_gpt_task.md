# Task: audit the resume-fix design BEFORE it is built (GPT, strict auditor)

**Read-only:** everything except your one output file. **Do not:** write or edit game code or game test code, run the
game or Godot, run any walk, edit any other file, commit, push. **Do not read:** `D:\mine\Agentics\T3_Code_Works\MPG_referee\`.
**Write exactly one file:** `D:\mine\Agentics\T3_Code_Works\MPG_dev\notes\speed_research\audit_resume_fix_gpt.md`.

## Context (you have no history; this is all of it)
"Finding Naresh" is a Godot 4 co-op game. Walks are scripted plays with real inputs, step by step; at every step start
the test takes a save point. A resume from a point is only trusted when the resume gate (`tools/method/walkgate.py`,
rules + tolerances in `tools/method/gate_inventory.json`) says SAME (layer 1 inventory, layer 2 immediate exact
compare after restore, layer 3 +3 game s trajectory, next-step outcomes; 2 SAME receipts per boundary). In the speed
research (`notes/speed_research/FINAL.md`, `trial_T4_build.md` sections "Resume 2026-11-14" and "Live gate session G")
no point ever passed: every walk retry replayed the whole walk (~40 game min lost in the replay). The user chose to fix
resume. Claude designed it; Claude will build and run it. **You audit the design before anyone builds it.**

## Read (in MPG_dev, branch `resume`)
1. `notes/speed_research/resume_fix_design.md` (THE design under audit)
2. `notes/speed_research/trial_T4_build.md` (the gate's findings), `notes/speed_research/FINAL.md`
3. Code: `FindingNaresh/scripts/dev/LiveControl.gd` (points: `_run_walk`, `_snap_live`, `_restore_live`),
   `FindingNaresh/scripts/dev/GateObs.gd`, `FindingNaresh/scripts/core/SaveGame.gd` (`apply`),
   `FindingNaresh/scripts/creatures/Hearing.gd`, `Creature.gd` (hearing, `_sniff_t`), `FindingNaresh/scripts/world/Ghat.gd`
   (`leave` / `listen` phases), `FindingNaresh/scripts/vehicle/Camper.gd` (`toggle_engine`, `swing_nav`),
   `FindingNaresh/scripts/dev/PlayTest.gd` (`wait`, `gms`, `el_ms`), `tools/live.py`, `tools/method/walkgate.py`,
   `tools/method/gate_inventory.json`, `tools/live/make_ghat.py`.

## What to write (strict: every claim with evidence, a file:line or a number, or marked "I think")
1. **Per design piece (A1-A4, B, B1.1-B1.7, the proof table rows 0-6):** KEEP / SIMPLIFY / CUT, with the concrete miss it
   guards against (or the false SAME it could cause) and its cost. Try to break each: how could it make a resume look
   SAME while the world differs, or make a clean resume DIFFERENT for a reason that doesn't matter?
2. **Hidden state the design misses** (things a restore still loses that could change the resumed step): name each with
   where it lives in the code. Check especially: pausing the tree (does physics stop? do `Engine.get_physics_frames()` /
   `PlayTest.gms()` advance while paused, and what reads them?), the raw restore of PlayerRig / Carryable vars (any var
   that must match engine-side state), the global-RNG reseed (who else draws from it between point and step), the
   hearing rebase (ages while paused), Problem's own children / timers, audio players.
3. **The proof plan:** is it enough to call the point SAME and the fix proven? Is the perturbed control (X1, X2) a fair
   test that the gate can tell? Is the repair-resume rule (B1.7) safe? Is the saving measured honestly? Budget ~20 game min.
4. **Your verdict:** BUILD AS WRITTEN / BUILD WITH THESE CHANGES (a numbered list, each short) / DON'T BUILD (why).
   Keep it under ~150 lines. Plain words.
