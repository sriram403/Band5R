# The replay: the referee's score (2026-11-17, step 7)

Runner: `MPG_speed_replay` branch `replay`, last commit `e2b197f`; report `notes/speed_research/REPLAY_REPORT.md` there.
Secret list: `MPG_referee/speed_secret.md` (the exam is over; it may now be shown to the signers).

## The three pass rules of the brief (`SPEED_RESEARCH.md`)

| Rule | Needed | Got | Verdict |
|---|---|---|---|
| (a) game time | <= 75 wall game min | **~119** (meter: 13.3 + 94.6 + ~1.0 gap + 10.1; the runner's own count 120.2); summed ~175. Baseline 225 -> **~1.9x** | **FAIL** |
| (b) the 7 holes of the real day | all 7 named, each with a check that FAILS on it and passes fixed | **3 / 7** (S3, S4, S7); S1 and S5 seen but not named as holes; S2, S6 missed | **FAIL** |
| (c) every plant still caught at the end | the 21 starting rows + one per hole | **25 / 28 certified**, but against the brief's rule (21 starting rows + one per *real* hole): **18 / 21 starting rows**, really **16** (see `no_fix` / `no_power`); 3 starting rows lost (`lean_close`, `no_stall_drag`, `endless_window`); 2 more (`no_fix`, `no_power`) certified only through a broken state (the jug left 77 m behind, = S1) | **FAIL** |
| Insurance plants (R1b, blind) | found + proved | **X1 + X2: 2 / 2** | PASS |

**Overall: the method does NOT pass the benchmark.** It is ~1.9x faster and finds what can be SEEN (both blind insurance
plants, found only by looking at the screen), but it missed 4 of the day's 7 holes and lost 3 checks on the way.

## Each hole, against the secret list

| # | Hole | Runner | Evidence |
|---|---|---|---|
| S1 | Jug stowed on an awake van left behind | **SEEN, NOT FOUND**: "the jug left 77 m behind" listed as an open question, blamed on the test moving the van; no check, no plant | report lines 45-47, 74 |
| S2 | Tail lights z-fighting (flicker) | MISSED | no mention |
| S3 | Holding past the net's finish pulls it back off | **FOUND + PROVED** (`tarp_overpull`, planted FAIL 78 %, clean PASS) | run `20261117_193210_..._tarp_overpull_fast` |
| S4 | Round walks through the van and sticks | **FOUND + PROVED** (`round_through_van`) | runs 19:02 (planted FAIL, clean PASS), 19:30 matrix |
| S5 | After the whoosh it comes straight back (no listen) | **SEEN, NOT FOUND**: bench 11 measured it "back at the van in 3 s" and the runner blamed the walk (correction from `sign_claude.md`) | bench11 |
| S6 | Van stops near it: arrives in seconds (no stare / >= 24 s warning) | MISSED | no mention |
| S7 | Sees through the fog from ~40 m | **FOUND + PROVED** (`fog_sees`: seen at 35 m, fog sight 15 m) | run `..._fog_sees,one_corner_fast` |
| X1 | P2's breath prompt names P1's key (Ctrl) | **FOUND + PROVED** (`breath_key_ctrl`) | run `..._breath_key_ctrl_1x` |
| X2 | Naresh's note on the back of the milestone | **FOUND + PROVED** (`note_back`) | run `..._note_back_1x` |
| extra | the red "won't start" line runs off both halves | found + proved (`warn_clip`): real, not on the list | |
| extra | the spring's pot called "the jug" of "coolant" | found + proved (`pot_says_jug`): real, not on the list | |

## What the referee checked directly
- **The video is not clean:** frames 5:35-6:15 (`MPG_referee/scoring/replay/end_grid.jpg`): P1 drives off at 30 km/h, P2 stands
  on the road with the pot. The walk's checks passed it ("DONE"): its last step checks the van, not that both players are in.
  The runner reported it honestly; fixing it needs a new freeze + final + matrix + take (didn't fit).
- **Two referee steers** (procedure only): bench one move after 3 failed full walks (~18 game min lost first); rebuild the
  check list after 2 TEST runs (~15 game min lost). Root cause of the second, found by the runner: the judge reads
  `tools/method/frozen.json`, the usage doc said `appdata/manifest.json`: a usage-doc / tool defect from the build.
- **Telling the count backfired:** the brief said "7 holes"; the runner reached 7 with 2 extras and both insurance plants,
  then stopped looking. Next benchmark: don't give the count.

## Where the time went (approx., wall game min)
Discovery suite 13 · walks ~45 (8 fresh walks + benches; resume was not usable) · repair / diagnostic suites ~25 (15 of them
judged against a stale list) · final suite 13 · recorded take 12 (beside the final) · matrix ~20 (two lanes) · imports ~2.

## What worked (measured)
- Fast + nodraw for heat / net (~4.6x) and two games at once (the final suite 13 min instead of ~15.5; the take beside it).
- Fail-closed judges: stale check list -> TEST, never a false PASS; missing checks -> INCOMPLETE; a plant not caught -> PASS
  shown and the row left NOT CERTIFIED (no rerun-until-green).
- Picture inspection found both blind plants; the observation table flagged X1's area before any run.
- Commit after every sub-step: the rate-limit cut on 11-14 cost nothing.

## Corrections applied from the signatures
- `sign_claude.md` (SIGN WITH RESERVATIONS): S5 seen-not-found (was "missed"); plant rows read against the brief: 18 / 21, really 16.
