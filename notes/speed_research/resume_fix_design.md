# Fix resume: design v1 (Claude, 2026-11-17; for GPT's audit before the build)

**Goal (the user chose A, 2026-11-17):** one save point on the REAL ghat walk (`tools/live/ghat.json`) resumes **SAME**
as the fresh run that made it (the existing gate: `tools/method/walkgate.py`, D3 = 2 SAME receipts), a perturbed
resume of it comes back **DIFFERENT**, and the saving is measured on a real failed-step repair vs a fresh walk.
Scarce thing: game minutes (budget ~20 for all live runs). Branch `resume` in `MPG_dev`, from main `d161ccd`.

## 1. What is true now (measured, not assumed)

Evidence: T4 build report (`trial_T4_build.md`, "Resume 2026-11-14", "Live gate session G"), and the gate's own refusal
run tonight on the replay's real ghat points (`MPG_speed_replay/.../points/ghat_probe_20261117_184311_8308`).

| Where the replay's walks failed | step 11 (w3), step 17 (w5, w6), step 19 (w4): 4-6 game min into a fresh walk each time |
|---|---|
| Ghat point 3 (step 4) | refused only for "engine sounds < 2 wall s old" |
| Ghat points 9-18 (steps 10-19) | refused for: a listener (Problem, phase `leave`, lingering ~40-90 m off) is out, so its hearing serial can't be restored; the **global RNG** (`Creature._sniff_t = randf_range`) isn't saved; unconsumed hearing events (P2's steps, the tarp); "a carryable moving" (P2 carrying the pot) |
| Van at every late point | `@freeze` true (parked), stored `@lv` 0.077 m/s (stale: a frozen body doesn't move); probe walk 0.148 m/s |

What the restore loses, in the code (`LiveControl._run_walk` resume branch + `SaveGame.apply`):
1. `SaveGame.apply` **unfreezes the van and zeroes its stored velocities** (and every item's `linear_velocity`);
   G4 then showed the van 0.064 m/s apart at +3 s and the seated players 5.5 cm off: the van, unfrozen, settles.
2. It forces **`engine_on = false`**; `nav_aside` is not saved (G4: fresh true / resume false). Other plain Camper /
   VanAttack / Carryable vars are not saved either (G2: a crate's `_safe_t` 0.483 -> 0.4).
3. `Hearing.recent` and `Hearing._next_id` (statics) are not saved; the creature's `_heard_id` is (live vars), so the
   listener serial is inconsistent after a restore. Wall-clock stamps (`problem._item_ms`, `item._last_hit_t`,
   `van._cap_t`, the hearing queue's `t`) come from the old process's clock.
4. The global RNG (randf) is per process: after a restore the creature's next sniff time differs.
5. **The settle:** after the restore the resume runs the world for `pt.wait(1.0)` **and then for however long the client
   takes to write its layer 1+2 verdict** (python, ~0.3-1 s) before the step's first input; the fresh run starts the step
   in the same tick as its point. G4's 1.6 C temp gap = ~1 s of engine-off cooling.

## 2. The design (each piece removable, each with a control that fails without it)

**A. Save what the restore loses (LiveControl, test-side only; no game code change).** At every point, beside
`SaveGame.collect` + `_snap_live`:
- `live_bodies`: for the van and every carryable: `freeze`, `sleeping`, stored `linear_velocity` / `angular_velocity`.
  After `SaveGame.apply`, put them back **as they were** (the frozen van stays frozen with its stale 0.077 m/s stored;
  set velocity, then freeze, then sleeping). *The user's idea was "ignore / zero it"; my pick is to restore it exactly:
  a stored velocity can come back when the van unfreezes (handbrake off), so zeroing it would be a real, if tiny,
  difference later. The gate still ignores it for the "moving" refusal (B1).*
- `live_vars`: plain script vars (the existing `_snap_vars`, objects skipped) of the Camper, its VanAttack, every
  Carryable and both PlayerRigs; restored after `SaveGame.apply` and the seat / held restore. Covers `engine_on`,
  `nav_aside`, `_cap_t`, `_safe_t`, breath / crouch state. Engine set straight (no `toggle_engine`: no click, no temp
  bump). A short skip list only where a raw set breaks something (found by layer 2, written in the inventory with why).
- `live_hearing`: `Hearing.recent` (ids, pos, radius, what, **age** = point wall ms - t) and `Hearing._next_id`;
  restored with `t = now - age`, so the listener serial and the queue line up with the creature's `_heard_id`.
- `wall_ms` of the point; every known wall stamp (the inventory's `wallstamps`) is rebased the same way
  (`t_new = t_old - wall_point + wall_now`).
- **The global RNG at a boundary:** the fresh run calls `seed(hash(point_id))` right after taking each point; a resume
  calls the same `seed(hash(point_id))` right before its step starts. From the boundary on, both draw the same
  numbers (the creature's sniff times, a knocked item's spin, sound pitch). Test runs only (LiveControl).

**B. Line up the settle (the user's "1-second settle").** Replace "restore, wait 1 s with the world running, wait for
the verdict with the world running" by: restore -> **pause the tree** (physics and game nodes stop; LiveControl's timers
run with `process_always`) -> 2 drawn frames for deferred work (queue_free, seat reparenting) -> the immediate
observation (layer 2) -> wait for the client's verdict, still paused -> rebase the wall stamps once more by the paused
wall time -> reseed -> **unpause and start the step in that tick**. Fresh and resume then both start the step from the
point's world, with no game time between. *If the 2-frame hold changes a layer-2 field, the observation moves before it
(the spec's "before any await") and the hold is reported.*

**B1. Gate rules (walkgate.py + gate_inventory.json; old points keep today's refusals):**
1. A van with `@freeze` true: its stored velocity is not motion: no "van moving" refusal (layer 2 still compares it
   exactly, since A restores it). Unfrozen and > 0.1 m/s stays refused.
2. A point that carries `live_hearing` + `wall_ms`: no refusal for a listener out, recent / unconsumed hearing events,
   or wall stamps inside their window (all restored and rebased). Layer 2 compares the hearing queue by
   (id, what, pos, radius) and ages **within 50 ms** (the wall time between the restore and its observation).
3. A point that carries `rng_seed`: `global_rng_problem` no longer refused.
4. "A carryable moving" excludes an item held by a player (it rides the hand; the pick-up restore puts it back).
5. A point that carries `live_vars`: "engine on" no longer refused.
6. **Far sleeping items (the user's "fair tolerance"):** only if layer 2 / 3 show them moving after the restore:
   an item asleep at the point AND > 10 m from both players, the van and Problem gets `@lv` / `@av` compared as
   "at rest" (< 0.01 m/s) and its pose within 0.01 m / 0.5 deg instead of exact. The number comes from the measured
   spread of the clean resumes, never bigger than the smallest margin a check reads (0.15 m). Not added if not needed.
7. A **repair resume** (new): the step at the point changed (a fix), the steps before it unchanged, and the point's
   boundary holds >= 2 SAME receipts on this profile: admitted; layers 1 + 2 still decide before any input; layer 3 and
   next_step are skipped (no fresh reference for new actions) and the receipt says REPAIR. Without the receipts: refused
   as today ("play it fresh").

## 3. The proof (live; watch every run; CPU load beside every timing; GTA closed, checked)

Points picked: **P16 = the start of step 17** ("not full yet: P2 back down to the spring"), the step where two replay
walks failed, ~5.7 game min into a fresh walk; Problem out (phase `leave`), engine off, nav aside, the van frozen with a
stale stored velocity, P2 holding the pot, hearing events queued. It exercises A1-A4 and B. **P2 = the start of step 3**
(engine on, nav just swung, parked): the engine piece; second priority, run only if the budget holds.

| # | Run | Expect | Game min |
|---|---|---|---|
| 0 | offline: `t4_controls.py`, `t4_join_controls.py` + new controls (each new rule: a planted case that must stay REFUSED / DIFFERENT, the clean case ADMIT / SAME); `--check-only` compile | all pass | 0 |
| 1 | **F**: fresh producer, main's ghat walk with step 17 = the replay's real failing route (`van_side(-1.2, -7.5)` first, max 10 s; translated to main's helpers, `pipe_side()` = +1) | fails at step 17 (or passes: then it's not this game's failure, said so) | ~6.5 |
| 2 | **R1, R2**: resume F/16, the same walk cut after step 17 | layer 1+2 SAME, layer 3 SAME, step 17's outcome = F's -> boundary **SAME** (D3: 2 receipts) | ~2 |
| 3 | **X1**: resume F/16 + `GATE_PERTURB=van:0.2` | DIFFERENT (layer 3) | ~0.7 |
| 4 | **X2**: resume F/16 with the hearing restore switched off (test-only `GATE_DROP=hearing`) | DIFFERENT at layer 2, refused before input | ~0.5 |
| 5 | **Repair**: main's real step 17 resumed from F/16 (REPAIR) and on to the end | DONE; wall + game time from launch to DONE | ~2 |
| 6 | (if budget) P2: 2 resumes + `GATE_DROP=vars` (engine / nav lost) | SAME, SAME, DIFFERENT | ~5 |

**The saving** = (a fresh fixed walk to DONE: F's measured time to step 17 + the repair's steps 17-20) vs (the repair's
launch-to-DONE), both wall game minutes, CPU noted. One sample each: marked as such.

**Fails the design if:** a clean resume is DIFFERENT after its cause is fixed twice (then a bench: restore twice in one
game from the same point and diff the two observations), or a control that should be DIFFERENT comes back SAME.

## 4. What it can't do (honest limits)
- Physics contact caches / solver warm-start live in the physics server and aren't restored: covered only by layer 3's
  tolerances (0.05 m, as frozen before the trials).
- Reseeding at every point makes a fresh test run's randomness differ from an unseeded one (still random per run ID);
  a player's game is untouched (LiveControl only).
- One point qualified is one point: each new boundary needs its own 2 receipts.
- Points made before this change (no `live_bodies` / `live_hearing` / `rng_seed`) keep today's refusals.

## v2 (2026-11-17, after GPT's audit `audit_resume_fix_gpt.md`: BUILD WITH THESE CHANGES; all 8 accepted)

| GPT # | What changes in the build |
|---|---|
| 1 | Atomic paused restore: restore -> pause -> 2 frames -> observation 1 (immediate) -> client verdict (paused) -> clocks re-applied -> reseed -> **observation 2 (final, pre-input) must also equal the point** -> unpause -> step. The run logs physics frames / wall ms across the hold (the clock bench, no extra launch). |
| 2 | Restore + observe: player full transform + velocity; capsule / crouch / climb (a boundary with crouch or climb **refused**); carryable parent, freeze_mode, layers / masks, holders (GateObs gains them); Problem's children (local transforms, child script vars, eye / glow material) put back; audio = gameplay-only SAME (sound cursors not promised; recording acceptance stays separate, said in the receipt). |
| 3 | Typed clocks: every wall stamp (ms / s, its unset sentinel kept) saved as an AGE at the point and set to `now - age` at release (one offset for the hearing queue, `_item_ms`, `_last_hit_t`, `_cap_t`); ages frozen through the hold; layer 2 compares ages within 20 ms **and** on the same side of every expiry window. Edge controls offline. |
| 4 | RNG: protocol `seed-v1` (stored integer seed, fresh and resume seed at the same place: right before the step's first action). The global-RNG refusal is lifted **only** while no gameplay draw can run in the step: Problem passive in `leave`, pose not `crouch` (its sniff draws only when crouched, Creature.gd 668-671), no player shake. Else refused. |
| 5 | **Held-carryable and engine-on refusals stay.** Far-item tolerance **cut**. So the qualified point moves from P16 (P2 holds the pot) to **P13 = the start of step 14** ("P2 down the road to the spring: the pot ... back to the van"), ~5 game min in: nobody holds anything, engine off, nav aside, van frozen with a stale stored speed, Problem out (`leave`), tarp hearing events unconsumed. Engine-on stays refused (row 6 deferred: its own proof later). |
| 6 | REPAIR only for an action-only change of the resumed step: game, bin, test code (`scripts/dev/`), tools, setup and every earlier step identical to the qualified receipts' runs; >= 2 SAME receipts from **distinct** runs (pids), bound to the point's bytes hash, `seed-v1`, restore version and the gate + inventory hash. Never counted as SAME. live.py skips layer 3 / final judging for it. |
| 7 | Every new admission fails closed on an absent / malformed record; one offline negative control per rule (want the intended reason). |
| 8 | Saving = **estimate** (F's measured prefix + the repair's measured suffix), labelled; no extra fresh run unless budget is left. Every launch and hold counted in the meter. |

Proof plan v2: 0 offline controls; F (fresh, step 14's return leg = the replay's real failing route from its step 17,
translated); R1, R2 (resume F/13, two launches); X1 (van +0.2 m after observation 1: DIFFERENT at layer 3);
X2 (hearing restore off: DIFFERENT at layer 2, named); repair (main's real step 14, REPAIR, to DONE). ~13 game min.
