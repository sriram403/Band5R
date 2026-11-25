# Step-9 hang: the bench builder's report (2026-11-25, Claude Opus 5.5, high; branch `step9` in `dev`)

Task: `notes/speed_research/step9_build_task.md`. Skills loaded first: testing-and-verification, first-principles-solving,
game-dev (+ references/godot.md "Physics and 3D"), project-memory.

## The cause (plain words)

At step 9's start Problem still has **its own urge to circle the van** (`Creature.van_interest`, set by the engine
sounds while driving; how long it lasts is `_van_memory`, a global-RNG draw of 20-40 s made when Problem spawns in
step 6). While that urge lasts it is in VAN state and circles the van at 7 m, **ignoring the ghat's round**, but the
round's bookkeeping (`Ghat._walk_round` -> `_round_waypoint`) keeps running on its position:

1. on the driver's side (16.0 s into step 9) the round picks ring point 3 (driver-side back corner) as its waypoint
   towards its stop 5 (passenger-side back corner);
2. the circling carries Problem on round to the van's **nose**; at 24.4 s the urge runs out and the round takes over;
3. the waypoint is "kept until reached" (the 2026-11-10 fix against back-and-forth) and **never re-checked**: from the
   nose the straight line to point 3 runs through the van, so it walks into the van's nose and stays there. Its
   side-steps (`Creature._unstick`) alternate left / right, ~1.8 m each, and never clear either edge of the 2.8 m nose.
   stops_done stays 0, so it can never give up.

Why only 2 in ~10: the urge left at step 9's start decides where the circling ends. Saved points, all fresh walks:

| run | result | van urge left at step 9 (s) |
|---|---|---|
| ghat_20261124_190738_7904 | **HANG** | **24.3** |
| ghat_20261125_133628_7352 | **HANG** | **24.0** |
| the 8 others | gave up | 8.1 - 20.8 |
| this report's walk W1 (fixed) | gave up | 24.0 (a hang-prone draw) |

Senses ruled out by the bench log: `seen_now` 0 the whole step, no sound heard during it, `_noticed_t` only grows,
breath events 0. The sniff RNG only times sounds. Frame rate: the same point hung at 1.73x speed. So:
cause (b) (an unreachable waypoint, no re-plan), triggered by (c) (the RNG-drawn urge length).

Hang moment on the bench (B1, 100 s in, from above the van's front-left): the thin dark figure stands against the
van's nose under the net, as in the walk's pictures.
![B1 hang](step9/bench_B1_hang_front.png) · side view: `step9/bench_B1_hang_side.png`

## Plain bug, not a design choice: why

`Ghat._round_waypoint`'s own comment says how it is meant to walk: "straight there, unless the line crosses the van;
then the next point of its round the short way round". The waypoint it holds was never put through that same test, so
a creature moved elsewhere while holding one (its own circling, or an unstick hop) walks into the van for good. One
obviously right fix keeps the meant play: test the held waypoint's line with the same rule and choose again from where
it stands when it crosses the van. In a normal round that line never crosses (neighbouring ring points sit outside the
van's box), so nothing else changes: timings, stops, poses, the breath windows are the same.

## The fix

- `FindingNaresh/scripts/world/Ghat.gd` `_round_waypoint` (~line 380): before using `_via_k`, if the line from Problem
  to that ring point crosses the van, `_via_k = -1` (then the existing "nearest ring point" choice runs). The box test
  moved into `static func _crosses_van(a, b)` (same 11 samples, same box |x| < 1.6, |z| < 3.5), used for both lines.
- `FindingNaresh/scripts/core/Plant.gd`: plant `stale_via` (keeps the old behaviour).

## The plant + check

- Check `_ghat_round_nose` (PlayTest.gd): Problem put at the van's nose (van frame (0.6, -6.5)) with stop 5 and
  waypoint 3, the bench's B1 state at hand-over (declared setup); it must pass stop 5 within 30 s and never come
  nearer than its 0.3 m body: *"handed its round at the van's nose with a waypoint from the far side, it walks round
  the van, not into it"*. Called in `ghat_looks` right after the far-side round check (its sibling `round_through`),
  and alone by the bench scenario `ghat_round_nose_bench` (F1 ghat, engine off, Problem set circling by code).
- `tools/method/prove_ghat.py` row `nose` (stale_via -> `ghat_looks/handed_its_round_at_the_van_s_nose_with_a_waypoint_from_the_`);
  `tools/method/frozen.json` re-frozen: ghat_looks 17 -> 18 checks, total 125 (only that id added; the rest line shifts).
- Seen: **planted FAIL** (P1: still on its way to stop 5 after 30 s, pressed at van frame (-1.14, -3.18), 0.18 m from
  the body, waypoint still 3) / **clean PASS** (P2: round the passenger side in 9.8 s, closest 0.42 m).
- `notes/CHANGE_LEDGER.md` entry; mistake log `notes/ROUGH_NOTES.md` (SOLVED entry, three habits).

## Bench runs (every run counted; expected outcome declared before each)

The bench `ghat_step9_bench` restores a walk's own step-9 save point the way a resume does (SaveGame + LiveControl's
live part + rv1, no gate), seeds the RNG with that point's seed, runs `walk_breath_bot`, logs every 2 s and every change.

| run | point | speed | expected | result | game s | wall s |
|---|---|---|---|---|---|---|
| B0 | good run 130007 | 1x | gives up ~57 s | **GAVE UP 57.0 s** (the walk: 61 s incl. its 4 s wait): the bench matches 1x | 57 | ~80 incl. boot |
| B1 | hang 190738 | fast | hangs if the start state decides | **NO GIVE-UP in 190 s**, pressed on the nose, goal pt 3 at 7.68 m (walk: 7.6) | 190 | 110 + boot |
| P1 | round_nose bench, plant `stale_via` | fast | new check FAILS | **FAIL** 0.18 m, 30 s | 33.5 | 25.8 + boot |
| P2 | round_nose bench, clean | fast | new check PASSES | **PASS** 9.8 s, 0.42 m | 13.3 | 10.2 + boot |
| B2 | hang 190738, fixed | fast | gives up ~57-72 s | **GAVE UP 68.6 s** (dropped waypoint 3 at ~~24.4 s~~ **23.25 s**, still VAN; see Corrections; went round, 4 posed stops) | 69 | 41 + boot |

Bench seeds before / after: hang point 1 seed 78848943: before NO GIVE-UP, after 68.6 s. Good point seed 390248480:
57.0 s (before the fix only). The ~20-seed sweep was NOT run (budget, below).

## The real walk, once

W1 `AUTOQ=0 tools/play_walk.sh ghat --fresh` (run `ghat_20261125_140707_6788`, `step9/walk_W1.log`): steps 1-8 PASS;
**step 9 PASS "it gave up, nothing given away"**: step 9 at 122 s, step 10 at 194 s = **72 s** incl. the 4 s wait, so
the give-up ~68 s in (the task's "normal 61-72 s" is the whole step incl. the wait; give-ups measured ~44-69 s, by
urge left), on a hang-prone draw (urge 24.0 s). Step 10 also PASSED; stopped at step 11's
start: killed play_walk / live.py / Godot, `stop_lane.sh` (game gone, verified), `tasklist`: no Godot; the stale lane
lock released with its own token; `tools/live/ghat.json` restored with `git checkout`.

## Game minutes, CPU

About **9 game min** (CPU sampler: 209 samples with a game running x ~2.6 s; the referee's meter has the exact
figure), over the ~8 budget by ~1 min. My pick: run the real walk anyway (the task's only real-path proof) and skip the
20-seed sweep. CPU load 42-62 % while a game ran (mean 50 %), never two games at once; GTA closed
(`step9/cpu.tsv`). Note: the referee's TODO (14:04) makes GPT the tester for the after-fix runs; my task file still
listed step 4, so W1 ran (~4 game min) and GPT can run its own.

## What I could NOT test

- `ghat_looks` whole: the new call inside it and its later tarp give-up check (that now starts from stop 5, ~10 s
  more walking; the 70 s limit should still hold: estimated ~46 s for the round). Proved only through the bench scenario
  calling the same helper. The prove row `nose` itself (`prove_ghat.py nose`) was not run: ~6 min per side.
- ~20 bench seeds, and hang point 2 (`ghat_20261125_133628_7352`) on the bench (its numbers match hang 1's: urge 24.0).
- A recording / video of step 9 (the referee's next step).
- Wider: other creatures don't use the ghat's round, so the fix can't reach them.

## Found on the way: a design question for the referee (NOT built)

The Creature's comment on `director` says a directed creature "leaves the van to the puzzle (no van senses of its
own)", yet engine / horn sounds still set its van urge (`Creature._listen` -> `_want_van`), so at step 9's start
Problem circles the van at 7 m for 8-24 s before its round. With the fix this is harmless, but it is how step 9 plays.
- **A:** a directed creature ignores the van urge (gate `_want_van` on `not director.is_valid()`): it comes straight
  to its round; step 9 ~8-24 s shorter, the same every time, matches the comment.
- **B:** keep it: the circling first is a creepy "it sizes the van up" moment; Problem's give-up time varies with the
  van urge left: measured **~44-69 s** game time on the bench (R1-R5 44.0-68.3 s, B2 68.6 s; urge 8.1-24.0 s). That is
  the give-up time, not the whole walk step: the step adds its 4 s wait (W1: give-up ~68 s, step 72 s). *(Round 3
  correction: this line said "step 9 varies 57-72 s".)*
- My pick: **B** for now (it plays well and is no longer a trap); A if the user wants step 9 tighter and steadier.
  It changes what the players see, so it's the user's / two blind specs' call.

## Corrections after audit (round 2, 2026-11-25; GPT `step9_code_audit_gpt.md` findings 3-4, the tester's proof)

- **Timing (B2, `step9/bench_B2.log`):** the fix dropped waypoint 3 at **23.25 s** (line 23: `via_k 3 -> 0`, state
  still **VAN**, at (-1.16, -6.44)), not 24.4 s. WANDER took over at **24.37 s** (line 25) and inherited waypoint 0;
  short waypoint / straight-line switches (7 / -1) around 24.7-26.2 s settled, and corner 5 advanced to 6 at **34.03 s**
  (line 35). Two separate events: the fix acts while Problem is still circling, the hand-over comes ~1.1 s later.
- **What the nose check proves:** `_ghat_round_nose` is a **reduced fixture**: it seeds position, stop 5 and waypoint 3
  (B1's state at hand-over) only, not velocities, the detour state or the earlier orbit. The real-state evidence is the
  B1 / B2 restore of the hang's own step-9 save point (before: no give-up in 190 s; after: 68.6 s), and the tester's R1
  on hang point 2 (68.3 s).
- **Limited guarantee:** `_crosses_van` samples the line at 11 points, so a line can graze a corner of the padded box
  between two samples (GPT's example, flat van frame: (-2, -3.3) to ring point 7 (2.4, -4.6) is inside the box from
  0.091 to 0.154 of the way, between samples 1/12 and 2/12). That is a missed margin, not a seen collision. There is
  no general progress guarantee either: from a hop, a spot inside the margin or a tilted van it can pick the same
  blocked nearest point again. **No code change unless a new jam is seen;** then an exact segment / box test and a
  reachable leg (outward allowed when starting inside the margin), keeping a held target while its leg stays clear.
- **The planted side's follow-on failures:** in the tester's prove row (R6 planted, `stale_via`) the nose check FAILED
  on its id and 3 later checks failed after it: the tarp give-up ("1 stops"), the slump, the eyes dim. A stuck
  creature carries into every later check of the scenario; only the nose check's FAIL is the proof, the 3 others are
  knock-ons, expected while the plant is on (the clean side passed all 18).

## Commits (branch `step9`, no merge, no push)

`15d5cfe` bench · `db70d9c` fix + plant + check · `043d5cc` prove row, manifest, bench logs · `bc14d21` this report + notes.

Last code commit: `043d5cc`; report commit: `bc14d21` (this line added in the commit after it).

# Round 2 (2026-11-25, Claude Opus 5.5, high, builder; task `step9_fix2_task.md`)

Skills loaded first: testing-and-verification, project-memory. Inputs: `step9_code_audit_gpt.md` (DON'T SIGN),
`held5_results_audit_gpt.md`, `step9_test_report.md` (PASS WITH RESERVATIONS). **0 game minutes** (everything offline;
no Godot started, `tasklist` checked after each client call). No merge, no push.

## 1. The gate owns the new proof (GPT finding 1, blocking) · `67ee0b1`
- `tools/method/prove_ghat.py:88` `MATRIX`: `"nose"` beside `"round"` (28 rows); line 32's comment says 27 + `nose` = 28.
- `tools/method/t3_controls.py:512-513`: the inventory control 27 -> 28 ("main's 27 + stale_via").
- New `tools/method/matrix_owners.py` (read-only, GPT's check as a tool): the gate's plant discovery
  (`t3_gate.plant_rows`) vs MATRIX owners; exit 1 on a gap.

| check | before (HEAD `5e70d40`) | after |
|---|---|---|
| owners (`matrix_owners.py`; before = the same check on HEAD's `prove_ghat.py`) | 28 discovered, **27 owned**, no owner: `stale_via` | **28 / 28**, no gaps, none owned twice; `stale_via` -> `nose` |
| `t3_controls.py matrix` | **3 / 6** (clean 27/28 incomplete; the cap_text row also NOT DONE stale_via; inventory 28 vs 27) | **6 / 6** (clean 28/28 complete) |

Other suites (expected all-as-expected, declared before): `t3_controls.py` all **124 / 124**, `rv1_controls.py`
**149 / 149**, `autoq_controls.py` **81 / 81** (its 14 BAD lines are its guard-OFF negatives, the same 14 before and
after). `t1fix_controls.py` **can't run in this copy**: it stops at blocker 1 (`combine_parts.py`) because its archived
run `appdata/method/runs/20261111_111720_ghat_k3_fast` is in neither `dev` nor `main`; pre-existing, before any
MATRIX code, and it reads only `GROUPS` (unchanged for the old rows). Mistake log entry written.

## 2. Report corrections (GPT findings 3-4) · `5cc1ae0`
"Corrections after audit" above (and the B2 row marked in place): waypoint dropped at **23.25 s** (still VAN,
`bench_B2.log` line 23), WANDER at 24.37 s, corner 5 -> 6 at 34.03 s; the nose check is a **reduced fixture**, the
B1 / B2 restore the real-state evidence; the **limited guarantee** (11 samples can miss a grazing corner, GPT's example;
no general progress guarantee; no code change unless a new jam, then an exact segment / box test); the planted side's
3 knock-on FAILs (tarp give-up, slump, eyes dim). `notes/CHANGE_LEDGER.md`'s step-9 entry says the same.

## 3. The walk's steps 17 / 18 (the tester's Surprise 4) · `fa52f92`
- **Where:** `FindingNaresh/scripts/dev/LiveControl.gd:918` waits `while ... not ctx["passed"].has(name)`, one passed
  set per walk; `tools/live/make_ghat.py` `refill()` and `pour()` reused `trip()`'s "P2 holds a full pot" (step 14) and
  step 16's "the water went in", so 17 / 18 were never judged. Scan of all 20 walks in `tools/live`: only `ghat.json`.
- **Found on the way (fixed, "fix what you see"):** renamed alone, step 18 still couldn't fail: its test
  `camper().coolant > 0.3` is already true after the FIRST pot. The van's coolant at the step save points of 25 saved
  walks: **0.050** at step 16's start -> **0.675** at 17's -> **0.675** at 18's -> **1.000** at 19's (same in every
  run). So step 18 now expects **`camper().coolant > 0.99`** ("the water went in again, the radiator full"), which fails
  at 0.675 and passes at 1.000. Step 17's test was already able to fail (the pot is empty after the first pour: the
  radiator took all 2.5 L). Mistake log entry written.
- **Changed:** `make_ghat.py:71-85, 141` (step 17 "P2 holds a full pot again"; `pour(n, again)`), `ghat.json`
  regenerated with `python tools/live/make_ghat.py` (diff: exactly those 3 lines). `tools/method/walkgate.py:700`
  `repeated_names(walk)` (pass names as the driver makes them: an expect's name, else its step's; watches included;
  repeated step names too, since `--from` picks by name); `tools/live.py:144-150`: `--walk` refuses such a walk
  (exit 7) right after loading, before the gate or any launch, so `play_walk.sh` / `record_walk.sh` stop at their
  `--gate-check` line. My pick: refuse in the client, not the game driver: every walk goes through it, and it's offline.
- **Refuse / accept demo (no game):**
  ```
  $ python tools/live.py --gate-check --fresh --walk tools/live/ghat.json     # the old file
  REFUSED (walk): pass name 'P2 holds a full pot' in steps 14, 17; pass name 'the water went in' in steps 16, 18:
  the driver skips a name already passed, so the later step is never checked; give each its own name (...)
  exit 7
  $ python tools/live.py --gate-check --fresh --walk tools/live/ghat.json     # regenerated
  GATE CHECK: fresh walk
  exit 0
  ```
- **Its own control** (the rule "every issue gets a check"): `t3_controls.py walknames`, **13 / 13**: the old
  `ghat.json` (from `5e70d40`) refused naming steps 14,17 + 16,18; the new one accepted; every walk in `tools/live`
  accepted; a watch reusing a name, an unnamed expect taking its step's name, two steps with one name all refused; case
  differences allowed (the driver's keys are exact); `live.py --gate-check` REFUSED 7 old / ACCEPTED 0 new; step 18's
  new test False at 0.675 and True at 1.000 on the tester's real points (`ghat_20261125_143834_19960/17.json`,
  `18.json`), the old one True at 0.675. **Guard switched off in memory:** 5 BAD (every in-process refusal row).
- Suites after item 3: t3 **137 / 137**, rv1 **149 / 149**, autoq **81 / 81**, owners 28 / 28.
- **Note:** this changes the walk file and the tools, so the ghat's saved points no longer match identity: the held
  branch needs a fresh producer (already planned), and autoq qualifies afresh on the new walk. The walk itself was
  NOT run (budget; the task asked for offline only), so steps 17 / 18 judged live are unseen until the next ghat walk.

## 4. Noted, not fixed (task item 4)
- The bench (`t_ghat_step9_bench`) fires the H2 heat rule right after loading a save (needle 60 deg vs engine 126 C:
  the needle hasn't caught up with the restored hot engine). Bench only: not in the walk, not in `ghat_looks`.
- The game window took focus for 1.8 s during step 9 of the tester's recorded walk (`R7_game.log`, `[focus] app_in`
  131.6 s, `app_out` 133.4 s); cause unknown, the walk wasn't disturbed.

## What I could NOT test
- The ghat walk with the new steps 17 / 18 live (offline proof only: real saved coolant values, no game run).
- `t1fix_controls.py` (its archived evidence isn't in this copy).
- A real certifying matrix (a final suite + all 28 proofs on the frozen tree); the controls prove the gate's logic.

## Round 2 commits (branch `step9`, no merge, no push)
`67ee0b1` item 1 · `5cc1ae0` item 2 · `fa52f92` item 3 · `02ab97e` item 4 + this report (this line added in the commit after it).

Round 2 last commit: `02ab97e`

# Round 3 (2026-11-25, Claude Opus 5.5, high, builder; task `step9_fix3_task.md`)

Skills loaded first: testing-and-verification, project-memory. Input: `step9_reaudit_gpt.md` (SIGN WITH RESERVATIONS),
reservations 1 and 3. **0 game minutes**: no game started. The 2 Godot processes seen throughout (pids 6704, 19944)
are the referee's walk; their count was checked after each control run. No merge, no push.

## 1. The walknames control reads a tracked fixture (reservation 1) · `d01aa93`
- New `tools/method/fixtures/step9_walknames.json` (17 KB, tracked): the whole old ghat walk (`5e70d40:tools/live/ghat.json`,
  its sha256), needed whole because the end-to-end `live.py --gate-check` row hands it to the client, plus R7's coolant
  values **0.6750000000000003** (point 17 = step 18's start) and **1.0** (point 18 = step 19's start), each with run id
  `ghat_20261125_143834_19960`, point path and the point file's sha256. Built by the new
  `tools/method/fixtures/make_step9_walknames.py`; `--check` re-derives it from the sources and says whether they still
  match (run here: "fixture matches its sources"). My pick: the whole old walk rather than a cut-down example, so the
  client row tests the real file that was refused.
- `tools/method/t3_controls.py:587-598` (`g_walknames`): loads the fixture (old walk + both values) instead of
  `git show 5e70d40` and the appdata points; the step-18 rows (lines 631-636) use the fixture values. The rows are unchanged.

| run | where | result |
|---|---|---|
| `t3_controls.py walknames`, new | `dev` | **13 / 13** |
| `t3_controls.py walknames`, new | clean `git clone --depth 1 --branch step9` (1 commit, no `appdata/`, no `5e70d40`) | **13 / 13** |
| `t3_controls.py walknames`, old (`f6c0d84`'s file) | the same clean clone | **0 / 1** (`invalid object name '5e70d40'`) |
| guard off in memory (`walkgate.repeated_names` -> `[]`) | `dev` | **5 BAD of 13**, the same 5 in-process refusal rows as round 2 |

**Suites in `dev`:** `t3_controls.py` **137 / 137**, `rv1_controls.py` **149 / 149**, `autoq_controls.py` **80 / 81**
(its 14 guard-OFF BAD lines are expected). The 1 miss is `B2: play_walk.sh refuses a game while the lane's qualification
runs`, which returns SKIPPED when a real `lane.lock` exists, and the referee's ghat walk held it (`owner play_walk`,
pid 20044, since 15:08). This code is untouched in round 3. The same suite in the clean clone (with `AQ_SRC` / `AQ_REAL`
at dev's saved points, read-only, and an empty `appdata/playtest/FindingNaresh/live/` for the planted lock) read
**81 / 81**, that row `got 3`.
- **Seen, not fixed (older, outside this task):** in the clean clone t3's `sentinel R4's real lane b log present` row
  (reads `appdata/t34/`) is BAD (135 / 136), and `rv1_controls.py` crashes (needs `appdata/rv1ctl/src2`, or `RV1_SRC`).
  These are the same kind of gap as reservation 1, for the referee to decide on.

## 2. The timing words (reservation 3) · `1e8844e`
- `step9_test_report.md:46-50`: R2 **and** R3 are below the prediction (44.0, 54.9 against 57-72 s). The urge left sets
  the give-up time: 44.0-68.3 s over R1-R5. 57-72 s held only for urges of 18 s and more. Surprise 1 (`:102-105`) says the same.
- `step9_build_report.md:116-119` (option B): the measured give-up range **~44-69 s** game time on the bench (R1-R5
  44.0-68.3, B2 68.6; urge 8.1-24.0 s), said to be the give-up time, not the whole walk step (+ its 4 s wait). Also
  `:87` (W1), where "normal 61-72" read like a give-up range: now it says that is the whole step incl. the wait.

Notes: `notes/CHANGE_LEDGER.md` (round 3 lines under the walknames entry), `notes/ROUGH_NOTES.md` (3 mistake-log entries:
the control only passed on my machine; the heredoc rule broken again, no harm; the autoq row skipped beside a live walk).

## What I could NOT test
- Nothing needed a game. The fixture's values are copies; `--check` proves they still match R7's points only where
  `appdata/` and the history exist (here, yes).

## Round 3 commits (branch `step9`, no merge, no push)
`d01aa93` item 1 · `1e8844e` item 2 · `bb0c76d` this report + notes · the commit after it adds this line and a 4th
mistake-log entry (`git add notes` had staged the referee's files; un-done before anything left this copy).

Round 3 last commit: `bb0c76d` (report); see `git log -1` for the line-only commit after it.
