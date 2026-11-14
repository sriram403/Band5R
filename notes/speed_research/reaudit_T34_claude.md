# Re-audit of the T34 fix round (Claude auditor, 2026-11-14)

Task: `reaudit_T34_task.md` (read first; only its list read; no DO-NOT-READ file opened). Copy `MPG_speed_t34`, branch
`speed-t34`, head `fd4ae18` (verified), diff `f208e6e..fd4ae18` (11 commits, one per item, F1..F11). No game run, no code
changed. I ran the three allowed offline scripts; they rebuilt their fixtures (`appdata/t3ctl`, `t4ctl`, `t34/joinctl`).

**My runs:** `t3_controls.py` **123 / 123**, rc 0 (16.7 s). `t4_controls.py` **85 / 85**, rc 0. `t4_join_controls.py`
rc 0, no output (a module; `t4_controls` runs it). 0 BAD lines in either output.
Side effect seen: step 0 runs `make_ghat.py`, which rewrites `tools/live/ghat.json` with CRLF endings (`git status`:
`M`; `git diff --ignore-cr-at-eol`: empty). The tree hash goes through `git add -A`, which turns CRLF into LF, so it
should be unchanged. Note only.

## The table: my 7 conditions

| Cond. | Answered by | Status | Evidence |
|---|---|---|---|
| C1 step 0 crashes (`t1fix_controls.py`) | F1 | **CLOSED** | REPLAY section 0 now lists `t3_controls`, `t4_controls`, `live_session.sh import`, and says why `t1fix` is out. Both scripts ran rc 0 in my run |
| C2 the 7 identity controls can't fail | F2 | **CLOSED** | `t4_controls.py:86-107`: the 7 now call `wg.identity_check` directly. A new admit pair runs on the `quiet()` point (velocity zeroed): `admit clean` -> ADMIT, `admit game changed` -> REFUSED. With the check disabled (`appdata/t34/fix/F2_disabled.txt`): new file **8 BAD of 17**, old file **0 BAD of 15**. The admit pair is the one that proves `admit()` itself routes through identity: its planted case is refused BY identity, because the quiet point has no velocity reason |
| C3 no frame marker on ghat, so no verifiable join | F3 (+ R7) | **CLOSED** | REPLAY section 7 makes it one unbroken fresh take ("one part, no join"). The `framemap_rec25.json`, `GATE_ONLY` and join promises for ghat are gone. Code check: a single fresh part needs no framemap (`join_check.py:205-207`: no cut, so no proof needed). A resumed ghat part can't become a video: `verify` needs a SAME boundary from >= 2 receipts (`:184-200`), `GATE_ONLY` is no longer in REPLAY, and `GATE_RESUMES` / `JOIN_GATE_WAIVED` are sealed (F9) |
| C4 "sound PASS" not saved | F4 | **CLOSED** | `evidence_R1b_sound.txt` (commit `6280008`): SOUND PASS, 21.0 dB over the quiet window. The windows come from step frames. The planted no-audio and muted copies both FAIL (`R1b_noaudio.mp4`, `R1b_silent.mp4` kept) |
| C5 gate strictness, alignment, "expect every parked boundary refused" | F3 + R7 (a) | **CLOSED by ruling** (the strictness itself is deferred, as R7 says) | REPLAY section 3: every try `--fresh`; budget a fresh prefix per repair; a resume is refused before any input (exit 5). The code agrees: `play_walk.sh` runs `--gate-check` before `run_game.sh`. T4 report D1 / D5 name the stale velocity and the unfreeze. The resume gate is unchanged, as R7 (a) asks |
| C6 dropped taps: bench, fix, sentinel judges its workload | F5 | **CLOSED** (what it asked) | Bench log `appdata/playtest/FindingNaresh/logs/godot2026-11-14T14.33.50.log`: "alone: 20 / 20 flipped", "beside: 20 / 20 flipped", focus changes 0. Lane b launched at 14:25:08, during step 3 (frames 2959-4651, `F5_driver.out`). Not confirmed, so no re-send was built (right). Sentinel: `lane_sentinel.sh:55-56` + `sentinel_workers.py`. R4's real log REFUSED, its ok-only lines ACCEPTED, no walks REFUSED (my run). **Still unproven:** "2 / 4 came from walks back to back in one game" is the builder's explanation, with no bench behind it. R8 avoids that case, so it's a question, not a hole |
| C7 complete the T4 report | F11 | **CLOSED** | `trial_T4_build.md` now has: Files and interfaces; Deviations D1-D7; the 85 pairs; R1 57 % / R1b 69 % recomputed (25.0 / 43.82 s, 24.96 / 36.13 s), with the 51 / 62 error explained; R3a / R3b; R4 charged to T3; lane b 2 / 4; G4 + G5 a failed live pair (line 66); a fix-round section. REPLAY ends with the referee sentence |

**F6-F10 (GPT's conditions; checked for fitness only, not scored here).** Each new guard's planted case was refused BY
its own rule and its clean case accepted in my run:

- F6: old split, no round, marks before looks: "prelude only"; `solo_marks_pile` PROVED under the new routing.
- F7: 6 picture cases "pictures only", clean accepted.
- F8: missing row, batch-only, post-freeze, new plant: each refused; 21 / 21 clean.
- F9: 15 flags + `SPEED=_fast` refused; the seal is required by `final` / `proof`; the 3 launchers exit 3 before launch.
- F10: 6 forms followed, `obj.call` not followed, variable targets refused, still 116 ids.

`free_coolant` still sends everything to 1x (`route.py:23-24`).

## New findings (none is a blocker)

1. **The recorded take isn't bound to the frozen tree.** `part1.json` carries `identity` {game, test, bin, walk}, but
   neither `record_walk.sh` nor `join_check` compares it with `appdata/frozen_tree.json`. `--fresh` clears `ghat.parts/`
   but not an older `appdata/videos/ghat.mp4`.
   - Risk: a take made before a later fix could be shown as "the clean walk" (a false PASS).
   - Why not a blocker: the hole is visible, because the identity is kept in `part1.json`.
2. **REPLAY is out of step with R8.**
   - Its rule line still says "walks and the recording run alone". That is R7 (b), which R8 lifted. Following it only
     costs time.
   - `lane_sentinel.sh:27` has lane b play the walk again and again **in one game**, against R8. Since F5 it judges
     those walks, so it will likely print FAIL for that reason, not a lane fault. Section 8 is optional, but keep its
     result out of the replay's verdict.
3. **`record_walk.sh:126` still says** "run again: it resumes there through the gate". That contradicts REPLAY's
   fresh-only rule. It fails closed (refused before launch, or a join refused for want of 2 receipts), so it can only
   waste a take.
4. `appdata/videos/framemap_rec25.json` (gateprobe's, from R1b) is not bound to a take (no walk or sha in it). That
   doesn't matter while joins are impossible.

## Fit for the scored replay under R7 + R8 (fresh takes only; every walk a new game; D5 = A)

- Every walk and recording launches its own game and stops it (`play_walk.sh:27,39`, `record_walk.sh:75,96`). That is
  R8 by construction.
- Resumes fail closed. Acceptance runs are sealed.
- `final` checks the freeze, k3, the marks prelude, pictures and inspection; `matrix` checks the 21 solo proofs.
- All my controls are green, and every guard I set refuses its planted case by itself.
- Unqualified, and run first in the replay itself: the new final / proof / picture gates live, marks at 1x and the cost
  of the 21 solo proofs, and a long ghat recording's speed. These are cost unknowns, not holes: each gate fails closed.

## Verdict: GO WITH CONDITIONS (all 0 game min)

1. **Bind the take to the freeze.** Before the video counts, the runner (or the referee) checks that
   `ghat.parts/part1.json` `identity` game / test / bin equals `appdata/frozen_tree.json`. The take must also end
   DONE, `join_check verify` must find no refusal, and its start time must be after the freeze. Delete any old
   `appdata/videos/ghat.mp4` before the first take.
2. **REPLAY note for R8.** The referee tells the runner that R8 overrides the "run alone" line (or leaves it as a cost).
   The section 8 sentinel is not used as replay evidence: its lane b worker breaks R8.
3. **Ignore `record_walk.sh`'s "it resumes" hint.** Retakes are `--fresh` only (REPLAY section 7 already says so).

D5 = A: run the replay and report the overrun against 75 and the baseline 225; I see no tool reason to stop it.
