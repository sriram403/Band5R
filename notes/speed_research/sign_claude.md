# Stage 4: Claude's signature (2026-11-17)

Read-only, no game runs. Sources: the brief, `notes/speed_research/*` (scoreboard, replay_score, top4), `TESTING_METHOD.md`,
`MPG_speed_replay` @ `e2b197f` (REPLAY_REPORT, replay_ledger, replay_obstable, REPLAY_TASK, matrix_result.txt, inspect_final2,
run folders), `MPG_referee/meter_replay.log` and `speed_secret.md` (the exam is over), and frames from `ghat.mp4` (6:21 at 25 fps, 6:27-6:46 at 1 fps).
"I think" = not measured.

## 1. The score, row by row

| Row | Verdict | Evidence |
|---|---|---|
| (a) ~119 wall game min, FAIL | **AGREE** | The meter restarted twice: session maxima 13.3 (to 17:39), 94.6 (to 19:38:20), 10.1 (to 19:48:35). Plus ~1 min while it restarted = ~119. The runner says 120.2. Summed ~175 is inside R2's limit (225). FAIL against 75 either way. |
| (b) 3 / 7 holes, FAIL | **AGREE** on the verdict | - |
| S1 seen, not found | **AGREE**, and it's worse than the score says | The jug check FAILED as the first failure in the solo plant runs (`..._193344_..._no_power_1x_laneb/run_test.out`: `FAIL P1 holds the coolant jug`). It PASSED in the clean final (`..._190517_..._1x_laneb`). So the matrix itself showed S1 twice, and the gate certified both rows anyway. |
| S2 missed | **AGREE** | Nothing mentions it. I think the method had no way to see it: z-fighting flickers frame to frame. Every picture is one still, and the video was checked every 5 s. |
| S3, S4, S7 found + proved | **AGREE** | `matrix_result.txt`: tarp_overpull, round_through_van and fog_sees are CERTIFIED, each with its own solo run id. |
| S5 missed | **DISAGREE on the label: SEEN, NOT FOUND** (same as S1) | Ledger row 7, bench 11: "the yelp turned it back, **at the van in 3 s**". That is S5's symptom, measured, then put down to "walk timing, not a game hole". The verdict doesn't change: still no check. |
| S6 missed | **AGREE** | Observation-table row 9 ("stopped, it comes") has no time on it. No run stopped the van near it. |
| X1, X2 found + proved | **AGREE** | breath_key_ctrl and note_back are CERTIFIED. Obs-table row 32 flagged X1 before any run. |
| Extras warn_clip, pot_says_jug | **AGREE**: real | inspect_final2: the line wraps. Walk 4 picture. |
| (c) 25 / 28, FAIL | **AGREE** on FAIL. **DISAGREE on the denominator** | The brief needs 21 starting rows + one per real hole. The runner's 28 counts 2 extras where the 4 missing S rows (S1, S2, S5, S6) should be. Against the brief: starting rows 18 / 21 (and really 16: `no_fix` and `no_power` failed first on the S1 jug, so they never proved their plant); hole rows 3 / 7; X rows 2 / 2. On `no_stall_drag`: the real day removed it too (R4), but the replay neither removed it nor wrote down why, so R4 counts it as lost. `lean_close` was a known coin toss from T1 onwards. Firming it was listed for before the replay and wasn't done. |
| The video isn't clean | **AGREE** (seen) | The credits frames from 6:27 show P2 (yellow) standing on the road beside the van. The walk's last step checks the van, not the people. |
| The two referee steers, telling the count backfired | **AGREE** | Ledger rows 9-11 (3 walks failed on P2's route before the bench). Rows 12 and 17 (TEST from a stale required list). |

## 2. The method going forward

| Piece | Call | What the replay showed -> how |
|---|---|---|
| Fast + nodraw table | **KEEP, WIDEN** | heat + net ran fast in 2.5 min; the 1x lane took 12.8. jug, places and spring stay at 1x only because the game's hearing runs on the wall clock. Move those clocks to game time: it's a correctness fix that changes nothing at 1x. Prove it with T1's differential. Firm up the `lean_close` plant (not the limit) before any replay. T1's "no round" in fast looks runs was probably S4: re-qualify looks as fast now that S4 is fixed. |
| Two lanes | **KEEP** | The final took ~13 min instead of ~15.5, the take ran beside it, and the matrix ran on both lanes. Change: the tool should run a fast part on lane b itself (ledger row 17 had to be run by hand). |
| Receipts / fail-closed judges | **KEEP + preflight** | A stale list gave TEST, never a false PASS. But finding that out cost ~15.5 game min. Add an offline preflight (seconds) before every launch: the required list is current, and there is one source of truth (`frozen.json` vs `manifest.json` was a doc / tool defect). |
| Resume gate, fresh-only | **CHANGE** | Fresh-only cost ~41 min over 8 walks: walks 4-7 failed at steps 14-19 and replayed steps 1-13 each time. Keep fresh-only for the **acceptance take**. Allow gated resume for **discovery walks**, once the gate's no-effect refusals are fixed (Claude C5: a stale stored velocity, cooling offset, float noise). Prove it: two resumes of one point must come out SAME, and a planted real difference must be refused. |
| Observation table | **KEEP, CHANGE** | It flagged X1. It missed S5 and S6 because its rows say what happens but never **how long the player gets**. Add a **player-time row** for every threat: seconds from the first cue to contact, at least the time to do the counter-move as measured in the walk (re-net, re-hide). Add an **attachment row** for every carried or stowed thing. A row whose observer is "picture" or "video" needs a named shot. |
| Picture inspection | **KEEP, CHANGE** | It found X1, X2, warn_clip, pot_says_jug and tarp_overpull. Change: a check whose subject isn't in its picture FAILS. The milestone camera ended up inside the bank and was passed with a note. Add pairs of frames one frame apart on lights and coplanar surfaces (S2). Watch the video at 1 fps, plus the end state (both players aboard). |
| Plant matrix, solo groups | **KEEP, CHANGE** | Certify a row only if the plant's own check is the **first** FAIL, or every precondition PASSED before it. `no_fix` and `no_power` passed on the S1 jug. A NOT PROVED row gets a capped look in the budget, not "needs a look". |
| Early stop | **KEEP, CHANGE** | It saves 30 s fast and 2-4 min at 1x per proof. Under the first-FAIL rule above, stop once the plant's check is on record **and** the headline failure is that check. |
| Recorded take checks | **KEEP identity + sound, CHANGE the end** | The take was DONE with P2 left on the road. The walk's last step must check that both players are seated and that nothing carried was left behind (the pot). |
| (rule) Bench after 2-3 fails | **CHANGE to a tool default** | The runner didn't apply it alone. After 2 FAILs on the same leg, the walk tool refuses a 3rd full walk unless `--bench` is given. |
| (benchmark) Don't give the hole count | **KEEP** | The runner stopped at 7. |

### 3 changes most likely to have found S1, S2, S5, S6
1. **Watcher invariants the observation table produces** (in the game's watcher, every 0.1 s, in every run). "Every stowed item stays in its slot in the van's frame (< 0.5 m)" would catch **S1** in the first run that moves the van. "From the first cue (eyes, whine, the yelp) to contact >= X s", with X from the walk's measured counter-move, would catch **S5** (3 s measured in bench 11) and **S6**. Effect, I think: 3 of 4 holes, + ~2 min. Prove it: plant the real day's `stow_live`, `no_listen` and `no_min_warn` in the replay's start: each must FAIL on its invariant, and the clean game must PASS.
2. **A rule against blaming the test:** "the test did it" can't close a symptom until a short bench reproduces it with real input, or shows it can't happen that way. S1 (the jug 77 m behind) and S5 ("walk timing") were both seen and dismissed. Effect: it turns "seen" into "found" (+1-2 min a bench). Prove it by auditing the replay's ledger: both cases would have triggered the rule.
3. **Flicker / coplanar check:** an offline scan of the van's meshes for parallel faces closer than 1 mm that overlap (0 game min), plus one pair of frames at the tail lights. Effect: **S2**. Prove it: `tail_flush` FAILs, the clean game PASSes.
Also, for **S6**: add a heat-scenario case that stops the van at 3 distances from it (+~1.5 min fast).

### 3 changes most likely to cut the ~119 min (I think; each still needs proof)
1. **Gated resume for discovery walks + a route bench before the first full walk** (headless, each on-foot leg from the saved death pose; benches 14-14c took ~0.7 min each and fixed it). Walks ~45 -> ~15-20 min. Prove it: replay walks 4-8 on the same commits and compare minutes and verdicts.
2. **Game-time clocks, so jug, places, spring and looks run fast.** The discovery suite, the final suite and the 17 1x matrix groups go from ~13 + 13 + ~26 to ~5 + 5 + ~12. That saves ~25-30 min. Prove it: T1's differential (verdicts match fast vs 1x) and every plant on those scenarios.
3. **Offline preflight before every launch:** the required list is current, and a walk lint catches P2's missing pad setup, reused expect names, SPACE after a drive, and a last step that doesn't check the end state. Effect: −~17 (15.5 stale + walk 1). Prove it: each planted slip must be refused in < 5 s with 0 game min.
Together, ~119 -> ~55-65. Finding the 4 missed holes adds back ~+10-15, so **~70-80**. 75 is not shown. I think it is near.

## 3. Signature

- **"The score is right": SIGN WITH RESERVATIONS.** Every verdict is right: (a), (b) and (c) all FAIL, and the method does not
  pass. Two reservations. S5 should read *seen, not found* (bench 11: back in 3 s), not "missed". Rule (c) should be shown
  against the brief's own rows (starting 18 / 21, really 16; holes 3 / 7; X 2 / 2), not as the runner's 25 / 28, which counts
  two extras in place of four missing holes.
- **"The KEEP / CHANGE list should become the next TESTING_METHOD.md": SIGN WITH RESERVATIONS.** The KEEPs are measured. The
  CHANGEs are untested: v7 must list each one as "to prove", with its own check and planted case, until it passes. The time
  figures above are estimates. v7 must also replace v5's "a failed take resumes and joins (default)" with the R7 split:
  fresh for acceptance, gated resume for discovery only.
- **What I'd build** (Claude may): `tools/method/preflight.py` (list + walk lint); the two watcher invariants in
  `LiveControl.gd`'s watcher; the matrix's first-FAIL rule in `t3_gate.py`; the coplanar scan; the game-time hearing clocks.
  Proof: the real day's 4 plants planted on the replay's start, ~6-8 game min.
