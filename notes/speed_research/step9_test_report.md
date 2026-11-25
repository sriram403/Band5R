# Step-9 fix: the Claude TESTER's report (2026-11-25, Claude Opus 5.5, high; branch `step9` in `dev`)

Task: `notes/speed_research/step9_claude_test_task.md`. Skills loaded first: testing-and-verification, game-dev
(+ `references/godot.md` "Physics and 3D"), project-memory. Tested at `b172217` (game + test code identical to the fix's
`043d5cc`: `git diff --stat 043d5cc HEAD -- FindingNaresh tools` is empty). Evidence: `notes/speed_research/step9/test/`.

## Choices (the user is away; my pick and why, one line each)
- Bench runs at FAST (`FAST=1`, `--fixed-fps 60`), as the builder's B1 / B2: the give-up is measured in game seconds
  either way and fast saves budget for the prove row and the video.
- The 4 good producers spread over the van-urge range (decoded from each point's `creature/vars/van_interest`), so the
  lowest, two middle and the highest good draw are all covered: 8.1 s, 13.9 s, 18.0 s, 20.8 s.

## Planned runs (expected outcome declared BEFORE each run)

| id | command | expected |
|---|---|---|
| R1 | `FAST=1 STEP9_POINT=<points>/ghat_20261125_133628_7352/8.json tools/run_test.sh ghat_step9_bench` (hang point 2, urge 24.0, never benched) | GAVE UP within ~57-72 game s; drops a waypoint that crosses the van after the urge ends (~24 s), never pressed on the nose |
| R2 | same, point `ghat_20261117_224429_13940` (urge 8.1) | GAVE UP ~57-72 s |
| R3 | same, point `ghat_20261124_235645_15888` (urge 13.9) | GAVE UP ~57-72 s |
| R4 | same, point `ghat_20261124_181730_2944` (urge 18.0) | GAVE UP ~57-72 s |
| R5 | same, point `ghat_20261124_201030_6632` (urge 20.8) | GAVE UP ~57-72 s |
| R6 | `python tools/method/prove_ghat.py nose` | planted side FAILs on `ghat_looks/handed_its_round_at_the_van_s_nose_with_a_waypoint_from_the_`; clean side PASSes all of `ghat_looks` incl. the tarp give-up check within its 70 s; row PROVED |
| R7 | `tools/record_walk.sh ghat --fresh` | every step PASS; step 9 gives up in ~61-72 s; video in `appdata/videos/ghat.mp4`; in it Problem comes out of the fog, goes round the van (not into it), leans in at the windows, sniffs at the back, leaves |

## Results (every run counted; none rerun)

One game at a time throughout (sampler max 1 Godot); GTA not running (`tasklist`). CPU = mean (min-max) % of samples with a
game running (`step9/test/cpu.tsv`). Bench logs: `step9/test/R<n>_bench.log`; wrapper summary `R<n>_wrapper.log`.

### 1. Real start states on the bench (`ghat_step9_bench`, FAST)

| run | point | urge left | its own walk's step 9 (give-up ≈ minus 4 s wait) | bench result | game s | wall s | CPU % |
|---|---|---|---|---|---|---|---|
| R1 | `ghat_20261125_133628_7352` (hang point 2) | 24.0 | **HUNG** (no step 10) | **GAVE UP 68.3 s** | 68.3 | 76 (48 in scenario) | 58 (36-83) |
| R2 | `ghat_20261117_224429_13940` | 8.1 | 123 -> 171 s = 48 s (~44) | **GAVE UP 44.0 s** | 44.0 | 60 (31) | 62 (26-91) |
| R3 | `ghat_20261124_235645_15888` | 13.9 | 122 -> 181 = 59 s (~55) | **GAVE UP 54.9 s** | 54.9 | 65 (37) | 56 (37-90) |
| R4 | `ghat_20261124_181730_2944` | 18.0 | 122 -> 189 = 67 s (~63) | **GAVE UP 62.3 s** | 62.3 | 74 (47) | 58 (22-82) |
| R5 | `ghat_20261124_201030_6632` | 20.8 | 122 -> 194 = 72 s (~68) | **GAVE UP 67.7 s** | 67.7 | 74 (46) | 57 (24-82) |

- **R1 (the one that matters):** same path as the builder's B1 up to the hang moment: VAN circling, waypoint 3 picked at
  15.55 s on the driver's side, carried to the nose (-1.15, -6.44) by 22.8 s. Then the fix acts: at 22.78 s (still VAN)
  the held waypoint is dropped and 0 chosen; the urge ends at 24.07 s; waypoint 7 / none flips four times in 1.4 s
  (24.5-25.9 s) and it walks off round the passenger side, posed stops at 37.9 (passenger window, breath held), 46.1
  (bonnet), 54.1 (driver window, breath held), 64.8 (back), gives up 68.3 s. Never pressed on the nose.
- **R2-R5:** each gave up within 0.3-1 s of its own walk's (pre-fix) give-up, so the fix changed nothing on good draws.
- **My expectation was wrong for R2** (declared 57-72 s, got 44.0): with only 8.1 s of urge it skips most of the circling
  and its round starts at ~8 s instead of ~24 s; its own walk took the same 44 s. The 57-72 range holds only for urges of
  ~14 s and more. Not a fix problem (Surprises).
- Every bench run logged, right after the restore, `[ghatwatch] FIRE H2: the temperature needle reads 60 deg, the engine
  is at 126.0 C` (the needle not yet caught up with a restored hot engine). The bench scenario has no gate on it and 0
  failures; a bench-only artifact, not in the walk (R7 game log has no FIRE line). Surprises.

### 2. The prove row `nose`

| run | command | result | game / wall s | CPU % |
|---|---|---|---|---|
| R6 planted | `python tools/method/prove_ghat.py nose` (ghat_looks, k3, 1x, FIXTURE `stale_via`) | **FAIL on the expected id** `ghat_looks/handed_its_round_at_the_van_s_nose_with_a_waypoint_from_the_` (closest 0.16 m, its body 0.3 m), headline condition; row **PROVED**. Knock-on FAILs after it (tarp give-up "1 stops", slump, eyes dim): the creature stays stuck, as the plant should cause. 18/18 checks ran; no Godot left | 205 game s / 245 wall | 53 (17-88) |
| R6 clean | `GHAT=ghat_looks ROLE=final bash tools/method_run.sh ghat` (same profile k3, 1x, no fixture) | **RESULT: PASS**, 18/18 required checks ran and held, H1-H3 0 findings. Nose check: closest 0.42 m. **Tarp give-up PASS (4 stops)**, 1585 physics frames = **26.4 s** after the nose check passed (limit 70 s). Slump -0.64 rad, turn 35 deg/s, eyes dim | ~155 game s / 189 wall | 55 (25-97) |

`prove_ghat.py` runs only the planted side (my pick: run the clean side myself with the same profile and speed, since the
task asks for both and the script's PROVED line doesn't include it). Evidence: `appdata/method/runs/20261125_142923_ghat_k3_stale_via`,
`appdata/method/runs/20261125_143428_ghat_k3`; verdicts copied to `step9/test/R6_planted_verdict.txt`, `R6_clean_verdict.txt`.

### 3. The video: one fresh recorded walk (R7)

`tools/record_walk.sh ghat --fresh`, run `ghat_20261125_143834_19960`, urge at step 9 = 18.2 s (a middle draw, not a
hang-prone one). **DONE, 20 steps, RESULT ok**, 372 game s (recorded in 10:10 wall, 61 % of real time), CPU 43 (5-99).
Step 9 **PASS "it gave up, nothing given away"**: step 9 at 121 s, step 10 at 189 s = **68 s** (give-up ~64 s).
After it: `stop: lane 'a' game gone (verified)`, `tasklist` no Godot, `tools/live/ghat.json` (CRLF-only change) restored
with `git checkout`. Logs: `step9/test/R7_record.log`, `R7_walk.log`, `R7_game.log`.

**Video:** `D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/appdata/videos/ghat.mp4` (377.6 s, one part, no joins).
Step 9 runs **2:04 -> 3:11** (frames 3106 -> 4787 at 25 fps). Frames every 3 s and every 1 s looked at (2:01-3:13).

What the video can show: the walk's two cameras are the players' own seats, looking out of the windscreen through the
net. So only the front of the van is in view; the back and the sides are not.

| mm:ss | what I saw |
|---|---|
| 2:04-2:36 | nothing of it in view (it comes out of the fog and circles behind / beside the van, out of the cab's view); steam from the bonnet |
| 2:37-2:41 | P2 "Holding your breath" bar: a stop at the passenger window (out of view); 2:41 "It moves on. You let the breath out, slowly." |
| **2:44** | **Problem appears**: walks round the passenger-side front corner, eyes lit, outside the glass (`step9/test/video_164s.png`) |
| **2:45-2:48** | **the lean-in at the bonnet**: head down at the windscreen, eyes glowing, its frame and arms on the bonnet, outside the glass (`video_166s.png`) |
| 2:49-2:50 | it straightens and walks off towards the driver's side (`video_169s.png`), out of view by 2:51 |
| 2:53-2:57 | P1 "Holding your breath": the driver-window stop (out of view); 2:57 "It moves on" |
| 2:58-3:06 | nothing in view: the back stop (the sniff) is behind the cab |
| **3:07** | **it leaves**: "It stops. Its eyes dim, it turns away slowly and walks off, and the fog takes it. The needle stops climbing; the dripping stops." (`video_187s.png`); the leaving figure itself is out of view |
| 3:11 | step 10: both get out |

Order seen (passenger window -> bonnet -> driver window -> back -> gives up) matches the bench rounds. Nothing walked into
the van or stood pressed on it in any visible frame. **Not seen in the video:** it coming out of the fog, the sniff at the
back, and the walk round the back and sides (no camera there); those rest on the bench logs (R1-R5) and the clean
ghat_looks checks (round 4 stops, crouch + 2 sniffs, nose check 0.42 m).

## Game minutes, CPU
About **19 game min** of the ~25 budget: bench 5.8 (349 s wall incl. boot), prove planted 4.1 + clean 3.2 (wall), the
walk 6.2 game min (10.3 wall at 61 %). CPU 43-62 % mean while a game ran; never two games.

## Surprises (for the referee's mistake log)
1. **Assumed** every good point gives up in 57-72 s -> **reality:** the low-urge point (8.1 s) gives up in 44 s, the same
   as its own walk -> the range only holds for urges of ~14 s and more -> **habit:** declare a bench run's expected time
   from that point's own walk, not from a range of other runs.
2. **Assumed** `prove_ghat.py <row>` proves both sides -> **reality:** it runs only the planted side and prints PROVED on
   that alone -> the clean side run separately (`GHAT=<scenario> tools/method_run.sh ghat`) -> **habit:** read what a
   proof script runs before counting its PROVED as "plant FAIL + clean PASS".
3. The bench (`t_ghat_step9_bench`) fires the H2 heat rule at every restore (needle 60 deg vs engine 126 C): a restore
   that skips the needle's catch-up. Harmless for the give-up measure, but a bench point reading H2 as a finding would be
   a false alarm.
4. In the walk, **steps 17 and 18 print no PASS**: their expect names ("P2 holds a full pot", "the water went in") are the
   same as steps 14 and 16, and the walk driver skips names already passed, so those two steps are unchecked (step 19's
   "radiator full again" did pass). A test gap that predates this fix (not caused by it).
5. The game window took focus for 1.8 s during step 9 (`[focus] app_in` at 131.6 s, `app_out` 133.4 s in
   `R7_game.log`); tests are meant to stay behind the user's windows. Cause not known (maybe a click on the desktop); the
   walk was not disturbed.
6. The fixed round's waypoint flips several times in under 1.5 s when it re-chooses (R1: 7/-1 four times; R4, R5: 3/-1
   three times). No twitch was visible where the video could show it, but the flips happened out of the cab's view.

## VERDICT
**PASS WITH RESERVATIONS.** The fix works: hang point 2 now gives up at 68.3 s (it drops the waypoint across the van and
walks round); 4 good points give up within ~1 s of their own walks (44-68 s); the prove row FAILs planted on its own id
and the whole `ghat_looks` PASSes clean (tarp give-up 26 s after the nose check, limit 70 s); a fresh recorded walk is
DONE at 20 steps with step 9 in 68 s. Reservations: (a) the video shows only the front of the van, so "goes round the
van, not into it", the sniff and the leaving figure are proved by logs and checks, not seen; (b) the waypoint flips in R1 /
R4 / R5 (Surprise 6) are unwatched on screen; (c) the walk's steps 17 / 18 are unchecked (Surprise 4, not this fix);
(d) one fresh walk and 5 bench points, no ~20-seed sweep.

## What I could NOT test
- A camera outside the van during step 9 (none in the walk): the round round the back and sides, the sniff, it leaving.
- The ~20-seed bench sweep (budget); hang point 1 again (the builder's B2 covers it).
- Whether the waypoint flips show as a visible twitch.
- Other creatures (they don't use the ghat's round).

Report + evidence commit: `1be5ca0` (this line added in the commit after it).
