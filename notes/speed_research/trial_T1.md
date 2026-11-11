# Trial T1 (qualified speed) + T2 (proof runs). Claude auditor, 2026-11-10 / 11

Task: `MPG\notes\speed_research\trial_T1_task.md` (read first, with its RESUME). Copy `MPG_speed_t1`,
branch `speed-t1`. Read only the task's list + files in this copy (nothing on the DO-NOT-READ list
opened). Game code untouched (only `FindingNaresh/scripts/dev/` and `tools/`). The first child (cut by
the API rate limit) wrote 45dc00f and ran rows 0-1; I reviewed it, fixed 4 things, ran the rest.
Every run watched while it ran: `tools/method/t1_watch.py` in a Monitor (each condition, scenario
start / end, `[speed]`, `[nodraw]`, FAIL line at once; the heartbeat line every 10-60 s). One run was
stopped mid-way when it went off plan (row 6).

## Verdict

**Qualified: fast + nodraw (`SPEED=fast`) for ghat_heat, ghat_looks, ghat_net, ghat_places, ghat_jug,
ghat_marks.** Clean: 119 / 119 checks same verdict, values inside the tolerances below, pictures the
same. Plants: 9 plants in 5 groups, fast vs 1x on this source. **8 / 9 fail on the same check id**, and
the 9th (lean_close) is caught fast but not at 1x, because it sits at the check's limit (below). One fast
run of ghat_looks went wrong once (the creature made no round). It FAILed loudly, so a rerun clears it,
but it isn't explained (1 of 4 fast ghat_looks runs, 0 of 3 at 1x). **Stays 1x:** ghat_spring, the
`free_coolant` proof (`jug_b`) and the recorded walk. **Speed: 4.6-4.9x in the long scenarios, the 6
fast scenarios in 3.6 wall min (alone) vs ~16 at 1x.** **The whole 7-scenario suite, one command
(`SPEED=fast tools/method_run.sh ghat`, spring at 1x beside it): 4.4 wall min, PASS, vs 18.7 at 1x
(4.3x on the suite).** Qualification minutes used: **~33.5 of 45** (my count; the meter decides).

## What changed (files)

| File | Change |
|---|---|
| `FindingNaresh/scripts/dev/PlayTest.gd` | `clk()` / `el_ms()` / `game_s()` / `wall_s()` (game ms = physics frames / 60; `el_ms` = the larger of game and wall, so a deadline is never looser on either clock and 1x is the old wall deadline); the 16 PlayTest deadline sites below; `nodraw_off()` after each scenario's setup (`_ghat_start`: every F1 jump, every ghat_heat profile) **with a frame read-back before switching off (my fix, row 7)**; a detector in `_process` that re-arms when frames are drawn again; `[speed]` line per scenario (game s, wall s, x, frames drawn / physics frames, pictures, re-arms); the `overrun` fixture (test-only, off by default: one step with a 10 game s budget runs 15 game s); `--shots-dir` for lane b; `time <scen>` lines in game s |
| `FindingNaresh/scripts/dev/LiveControl.gd` | walk watches, `expect ... within` and step `max` on `pt.el_ms` (game time); step / PASS / DONE times in game s |
| `tools/method/method_watch.py` | STALL judged on game time `(pf_now - pf_open) / 60` plus the old host-monotonic judge (the reason names which clock fired); step lengths from `pf`; `LANE`; `EXPECT_FAIL` early stop (T2); **my fixes:** the game pid found without a heartbeat (a game is 2 processes: the `_console.exe` wrapper + the game), leftovers counted after the last kill |
| `tools/method/method_verdict.py` | headline tie window in game s when both conditions carry `pf`; times print `game N s` |
| `tools/method_run.sh` | `SPEED=fast`: fast + nodraw for the 6 qualified scenarios (lane a), spring at 1x in lane b at the same time, everything 1x when `FIXTURE` has `free_coolant`; one RESULT per part + the worst exit; `LANE=b`; the guard scoped to this copy's lane and at most 2 games on the PC (**my fix:** counts games, not processes) |
| `tools/run_test.sh` | `MPG_DATA` per lane |
| `tools/method/prove_ghat.py` | `EARLY=1`, `SPEED` passes through; **mine:** takes only its own run folder (two lanes make folders at once), names the exact check id each expected text matched |
| `tools/method/t1_diff.py` (new) | per-check 1x vs fast: verdict and the numbers in each check's text |
| `tools/method/t1_watch.py` (new) | the watcher above |

### The 19 gameplay-deadline sites (P1's class D), all now game time

PlayTest (16): `_ghat_heat_run` circle 90 s + first_attack_over 120 s; `_hide_well` max_s; `_fix_with`
120 s; `t_ghat_spring` 120 s, 150 s, the 5 s "it comes back"; `t_ghat_marks` 60 s, 120 s; `t_ghat_looks`
60 s, 80 s, SEARCH_S + 45; `t_ghat` 8 s, the 45 s watch, 20 s; `walk_breath_bot` max_s. MethodRec ->
`method_watch` STALL (1 mechanism: every `wait` / `frames` / `hold` / `shot` / episode). LiveControl (2):
watch / expect `within` (3 code points incl. re-armed watches), step `max`. Reporting lines: `time
<scen>`, `[speed]`, LiveControl step / PASS / DONE, `method_watch` step lengths, verdict times.
Health clocks stay wall (startup, no beat, no physics, kill verify, whole-run cap, focus / window).

## Every run (expected cost written before each; wall clock of game processes, my count)

Two games ran at once from row 8 on (R2); the running total counts the union (overlap once).

| # | Run (command) | Expected | Wall | Watched | Result | Total |
|---|---|---:|---:|---|---|---:|
| 0 | import x3, headless (first child) | 0.5 | 0.3 | - | 18.8 s for 3 | 0.3 |
| 1 | `SPEED=fast GHAT=ghat_net FIXTURE=overrun method_run.sh ghat` (first child) | 0.5 | 0.4 | its log | STALLED by game clock, 10.33 game s / 4.58 wall s | 0.7 (referee) |
| 2 | import: 2 warm + 1 after touching `RigBeat.gd` | 0.4 | 0.35 | inline | 7.9 / 6.2 / 6.2 s, rc 0, 0 errors | 1.05 |
| 3 | `SPEED=fast GHAT=ghat_net,ghat_spring FIXTURE=overrun method_run.sh ghat` | 1.2 | 0.6 | Monitor | fast STALLED (10.33 game / 4.56 wall s); **lane b refused** (guard counted 2 processes) | 1.65 |
| 4 | same, guard fixed | 1.0 | 1.1 | Monitor | fast STALLED (10.85 game / 6.98 wall s, lane b booting beside it); 1x lane b STALLED but **0.00 game s in 10.45 wall s** (cold cache, below) | 2.75 |
| 5 | `LANE=b GHAT=ghat_spring FIXTURE=overrun method_run.sh ghat` (1x control, warm) | 0.8 | 0.4 | Monitor | **STALLED, 9.97 game s / 10.21 wall s** | 3.15 |
| 6 | `SPEED=fast GHAT=<the 6> method_run.sh ghat` | 4 | 0.9 | Monitor | **stopped by me at 50 s**: frames drawn = ticks (drawing never off), 1.65x | 4.05 |
| 7 | same, nodraw fixed | 4 | 3.6 | Monitor | **PASS**, 6 / 6, 90 / 90 required checks; speeds below | 7.65 |
| 8 | `LANE=b method_run.sh ghat` (1x clean, all 7) | 20 | 18.7 | Monitor | **PASS**, 7 / 7 | |
| 9 | `SPEED=fast prove_ghat.py heat_always looks net jug_a marks` (lane a, beside 8) | 10 | 6.0 | Monitor | 8 PROVED, marks_pile NOT PROVED (looks made 0 stops) | |
| 10 | `prove_ghat.py marks` then `EARLY=1 prove_ghat.py looks heat_always jug_a net` (1x, lane a, beside 8) | 13 | 12.7 | Monitor | 8 PROVED, lean_close NOT PROVED (as on 11-09) | 7.65 + 21.4 (union 10:55:20-11:16:45) = 29.05 |
| 11 | `SPEED=_fast LANE=b GHAT=ghat_looks,ghat_marks FIXTURE=marks_pile,marks_unsaved` (the retry) | 1.5 | 1.7 | Monitor | normal round, both marks plants caught | (in the union) |
| 12 | `SPEED=fast EARLY=1 prove_ghat.py heat_always jug_a` (T2, lane a, beside 11) | 1.5 | 1.4 | Monitor | both early-stopped, PROVED | (in the union) |
| 13 | `SPEED=fast method_run.sh ghat` (the final command, all 7) | 5 | 4.4 | Monitor | **PASS 7 / 7**: fast part PASS (heat 3.91x, looks 3.55x, net 2.54x, places 2.13x, jug 3.97x, marks 3.64x beside spring), spring PASS at 1x (226 game s / 226 wall s) | **~33.5** |

## The differential (clean): 1x run 8 vs fast run 7

`python tools/method/t1_diff.py <run 8> <run 7>` -> `appdata/t1/diff_clean.txt`. **119 checks (90
required + the helper repeats), 119 same verdict.** Speed: run 7 ran alone on the PC; run 8 had a
second game beside it from 10:55:46 on (its speeds are all 0.94-1.00x).

Tolerances (1x is not tick-exact, P1; two 1x runs differ by up to these too): times rounded to 1 s
±1 s; distances ±0.05 m (the face gap was 0.35 and 0.40 m in two clean 1x runs); road samples ±2;
temperatures ±0.5 C; litres ±0.5 L; pixel change / brightness ±0.01, shares ±2 %; counts ±10 % of
the stretch (they follow the scenario's length, which varies run to run at 1x).

Every check whose numbers differ (the other 110 have identical text):

| Check | 1x | fast | Inside? |
|---|---|---|---|
| ghat_jug over the pass | 12 s, 93 C | 13 s, 93 C | yes (1 s) |
| ghat_looks face outside the glass | 0.35 m | 0.33 m | yes |
| ghat_looks the hot engine ticks | 526 ticks | 551 ticks | yes (4.5 %) |
| ghat_net dark lump | change 0.529, brightness 0.22 | 0.532, 0.23 | yes |
| ghat_net faint grid | 0.108, 0.64 | 0.107, 0.65 | yes |
| ghat_net nothing bright | 3 %, 85 % bare | 3 %, 86 % | yes |
| ghat_heat cornering: heat and leak stop | fuel 62.17 L | 61.87 L | yes |
| ghat_heat flat out: sees the van | sample 269 | 268 | yes |
| ghat_heat flat out: comes to rest | 330, boiled at 315 | 329, 314 | yes |

**Pictures, side by side** (`appdata/t1/sbs/sheet_0..3.png`, left 1x, right fast; I looked at sheets 0,
1 and 3 = 16 of the 22 pairs): same moment, same HUD text, same creature pose and place in every pair.
Mean difference 3-14 / 255, from the steam puffs (random), a road sample of offset and the 1x/fast tick
offset. One stands out: `credits_turn` 28.9 / 255: same van and road, the slowly turning credits
camera a few degrees further round (its turn is timed; the check "turning slowly" passes in both).
1x-only pictures: the 3 spring shots (spring isn't in the fast run). None black, none stale.

## The plants: fast vs 1x, both on this source (GPT's point 1)

The 11-09 file (`notes/g15_pending/prove_ghat_2026-11-09.txt`) was **not used** as the 1x side. Its
source isn't this one (T1 changed the test code, and that night had pending patches), and it names only
each run's headline, so most plants have no exact check id there. Every 1x verdict below is a rerun on
this source (run 10). The 11-09 PROVED / NOT PROVED is listed only as a cross-check.

| Group (scenario) | Plant | 1x check id (run 10) | fast check id (run 9 / 11 / 12) | Same? | 11-09 |
|---|---|---|---|---|---|
| heat_always (heat) | heat_always | H1 + `ghat_heat/x_no_heat_or_leak_from_it_before_it_sees_the_van_x_c_x_l_min` | the same two | **yes** | PROVED |
| looks (looks) | fast_turn | `ghat_looks/it_turns_away_slowly_fastest_x_deg_s` (209 deg/s) | same (343 deg/s) | **yes** | PROVED |
| looks (looks) | lean_close | none (face 0.18 m, limit > 0.15: PASS) | `ghat_looks/leaning_in_at_a_window_its_face_stays_outside_the_glass_clos` (0.13 m) | **no** (below) | NOT PROVED |
| net (net) | one_layer_net | `ghat_net/from_outside_nothing_of_the_van_shows_through_the_net_bright` | same | **yes** | PROVED |
| jug_a (jug) | leave_sees | `ghat_jug/out_beside_it_after_it_gave_up_nobody_is_taken` | same | **yes** | PROVED |
| jug_a (jug) | no_breath_lock | `ghat_jug/holding_your_breath_ctrl_b_never_touched_the_handbrake` | same | **yes** | PROVED |
| jug_a (jug) | round_skip | `ghat_jug/it_went_all_round_the_van_before_it_gave_up_x_stops` (2 stops) | same (3 stops) | **yes** | PROVED |
| marks (looks + marks) | marks_pile | `ghat_marks/a_clean_van_to_start_with` | run 9: none (looks made 0 stops, so nothing piled up); retry run 11: same id | **yes on retry** | PROVED |
| marks (looks + marks) | marks_unsaved | `ghat_marks/the_marks_are_saved_and_come_back_on_load_x` | same (runs 9 and 11) | **yes** | PROVED |
| (places) | - | **no plant for ghat_places in the inventory**: qualified on the clean differential only (14 / 14) | | | |

**lean_close, why it differs:** the check is `face gap > 0.15 m`, the minimum over samples taken every
2 physics frames while it leans at a window stop. The plant moves the window stop from 2.6 to 2.3 m.
Values: clean 0.33 (fast), 0.35 and 0.40 (1x, two runs); planted 0.13 (fast), 0.18 (1x). So the plant
lands within ~0.03-0.05 m of the limit, inside 1x's own run-to-run spread (0.05 m). The pair is marginal
at either speed: 11-09's NOT PROVED at 1x is the same thing. Fast reads ~0.02-0.05 m closer in both clean
and planted runs (I think the lean pose, eased per process frame, is sampled once per tick fast against
~2.4 process frames per tick at 1x; not proven). It doesn't touch the clean verdict (0.33 vs 0.35, far
from 0.15). It does mean lean_close's proof is a coin toss at either speed: the plant or the limit needs
a firmer margin (a check change: the user's / the builder's call, not T1's).

**ghat_looks with 0 stops (run 9, marks group):** "it comes to the van" PASS, then `round: stops []`,
no lean, no slump, eyes stay bright: six looks checks FAIL. Neither marks plant touches the round
(`marks_pile` keeps old marks on an F1 jump, `marks_unsaved` empties the saved list). The round's stop
timer is game time (`_stop_t += delta`). The same group fast again (run 11): a normal round
`[6, 0, 2, 4]`. Count: 4 fast ghat_looks runs (runs 7, 9 x2 groups, 11), 1 bad; 3 at 1x, 0 bad. Too
few to call it speed-linked. Direction: it fails loudly (FAIL, never a false PASS). In a benchmark run
it would cost a rerun of that scenario, and that rerun should be at 1x if it repeats.

**Downstream FAILs in plant runs** (not the plant's own check, so not part of the match): jug_a at 1x
also failed `P1 holds the coolant jug` (82.2 game s, within the early stop's 1 s grace); fast jug_a didn't
reach that FAIL. It follows leave_sees (someone is taken after it gives up), so who is taken decides.

## Speed per scenario (fast + nodraw) and the frames-drawn proof

| Scenario | run 7 alone: game s / wall s = x | frames drawn / ticks (pictures, re-arms) | beside a 1x game (runs 9-12) |
|---|---|---|---|
| ghat_heat | 349.0 / 73.3 = **4.76x** | 263 / 20,938 (4, 27) | 4.73x |
| ghat_looks | 149.2 / 30.6 = **4.87x** | 75 / 8,951 (6, 13) | 3.43-3.92x |
| ghat_net | 13.9 / 4.4 = 3.16x | 52 / 835 (8 = 4 shots + 4 `grab_p1`, 4) | 2.14x |
| ghat_places | 9.4 / 3.8 = 2.52x | 42 / 566 (3, 4) | - |
| ghat_jug | 174.7 / 36.0 = **4.85x** | 119 / 10,484 (0, 19) | 3.97x |
| ghat_marks | 197.4 / 42.7 = **4.62x** | 121 / 11,843 (5, 22) | 3.49-4.23x |
| **6 scenarios** | **893.6 / 190.8 = 4.68x**; whole process 213 s incl. boot = **4.2x** | 672 / 53,617 = 1.25 % of ticks drawn | |
| 1x (run 8), same 6 | 869.6 game s in ~873 wall s, + spring 233 s; suite 1,121 s (18.7 min) | ~62,900 drawn (144 Hz) | |

Frames drawn = pictures + ~4 per re-arm + the scenario's setup frames before `nodraw_off` (the F1 jump
draws). The short scenarios (net 14 s, places 9 s) are mostly setup, hence 2.5-3.2x. Drawing really
stops: e.g. heat 189 drawn at tick 191, 193 at tick 2,052 (drawing on: 1 per tick). The re-arms show
the engine turns drawing back on now and then (at F1 jumps and a few other moments, not found); the
detector catches each within 30 ticks. Speed beside a second game drops to ~3.5-4.7x.

## The negative control (deadline overrun, test-only `FIXTURE=overrun`)

One step with a 10 game s budget runs 15 game s, before the scenario's own steps.

| Run | Speed | Verdict | Open at detection | Clock that fired |
|---|---|---|---|---|
| 1, 3 (fast, alone) | 2.25x (drawing still on before setup) | **STALLED at overrun_control#2** | 10.33 game s / 4.58 wall s | game |
| 4 (fast, lane b booting beside it) | 1.55x | STALLED | 10.85 game / 6.98 wall | game |
| 5 (1x, warm lane b) | 0.98x | **STALLED** | 9.97 game / 10.21 wall | wall (both within 0.3 s) |
| clean runs 7, 8 (no fixture) | | no STALL | | |

Fast: the step lasted 15 game s = ~6.7 wall s, under the 10 s wall budget, so the old wall-clock judge
would have let it through. The game clock caught it at 10.3 game s. At 1x both clocks agree (STALLED by
name either way). Run 4's 1x STALL doesn't count: lane b's first game had a cold shader cache (its
own user-data folder), the first frame took ~12 s, and the wall judge fired with 0 game s passed: right
verdict, wrong reason. Run 5 is the clean 1x control.

## T2: proof runs

**Import:** cold 9.9 s (P1); warm 7.9 / 6.2 s; after touching a `.gd` 6.2 s. **An import skip saves
<= 8 s a launch: it doesn't matter.** Lane b and NO_CHECK runs skip it anyway (only 1 import per batch).

**Early stop** (`EARLY=1 prove_ghat.py`: stops once every expected FAIL of the group is a FAIL condition
or failed check; the verdict says `EARLY STOP ... detection complete, the rest not run`; RESULT stays FAIL,
never PASS; process checked gone in each verdict's `stop:` line):

| Plant group | Mode | Full run (wall) | Early stop (wall) | Saved | Same verdict? |
|---|---|---:|---:|---:|---|
| heat_always | fast | 81 s (run 9) | 44 s (run 12) | 37 s | yes: the same 5 FAIL lines up to 90.2 game s; H1 headline |
| jug_a | fast | 69 s (run 9) | 40 s (run 12) | 29 s | yes: the same 4 FAIL lines up to 84 game s |
| heat_always | 1x | ~320 s (est.: 306 game s + boot) | 105 s (run 10) | ~3.6 min | same ids |
| jug_a | 1x | ~225 s (est.: 209 game s + boot) | 99 s (run 10) | ~2.1 min | same ids |
| net | 1x | 30 s | 30 s (the scenario ended by itself) | 0 | |
| looks (fast_turn at the end) | 1x | 142 s | (no early stop possible) | 0 | |

So early stop pays at 1x (minutes) and little fast (~30 s); groups whose expected FAIL comes at the end
gain nothing. Batching several plants of one scenario: the existing groups already do (3 in jug_a).

## What is qualified, what stays 1x, and why

- **Fast + nodraw, qualified:** ghat_heat, ghat_looks (with the 0-stop note), ghat_net, ghat_places
  (no plant exists), ghat_jug, ghat_marks: the clean run, and the plant proofs of those groups.
- **1x:** ghat_spring (game-code wall clocks: `Camper._blow_cap` 3 s window; the "it comes back
  within 5 s" check), the `jug_b` proof (`free_coolant` reads the wall clock), the recorded walk (the
  video draws every frame). lean_close's proof: marginal at both speeds (above).

## Assumed -> reality -> fix

- **Assumed (the WIP):** at most 2 Godot processes = at most 2 games. **Reality:** a game is 2
  processes (the `_console.exe` wrapper starts the game). Lane b refused. **Fix:** count non-wrapper
  processes. **Habit:** count what you mean (games), not what the OS lists.
- **Assumed:** lane b behaves like lane a. **Reality:** its own user-data folder = a cold shader cache;
  the first frame took ~12 s, and a deadline before the first frame was judged with the game frozen.
  **Fix:** none needed in the method (one-time per lane); controls rerun warm. **Habit:** a new lane's
  first run is a cold run: warm it before timing anything.
- **Assumed (the WIP):** `nodraw_off` (on -> one drawn frame -> off) stops drawing. **Reality:** the
  engine drew every tick with the flag false (run 6, 1.65x). Every switch-off that had stuck (P1c's
  pictures) read the frame back first. **Fix:** read the frame back, then off; proved by frames drawn
  (193 by tick 2,052). Why it works: not proved (I think a sync with the render thread). **Habit:** the
  frames-drawn count, not the flag, and stop the run the moment the count says no.
- **Assumed:** with no heartbeat yet, `method_watch` finds the game by its process. **Reality:** 2
  processes, so "no game pid known", 15 s wrapper wait. **Fix:** game processes only.
- **Assumed:** the 11-09 1x proof file can be the 1x side. **Reality:** another source, headline ids
  only. **Fix:** reran every 1x plant on this source (GPT's point 1). Doing so found lean_close's margin.
- **Assumed:** fast and 1x plants match. **Reality:** lean_close differs (a marginal plant), and one
  fast looks run made no round (not reproduced). Both explained or bounded above, neither a false PASS.
- **My slip:** writing this file's header with Write replaced the first child's 2 log rows. They are
  in 45dc00f and copied above (rows 0-1).

## The final commands

```sh
SPEED=fast tools/method_run.sh ghat                    # 6 fast + nodraw (lane a) and spring 1x (lane b) at once
SPEED=fast GHAT=ghat_heat,ghat_jug tools/method_run.sh ghat   # a subset; FIXTURE with free_coolant -> all 1x
SPEED=fast EARLY=1 python tools/method/prove_ghat.py heat_always looks net jug_a marks   # plant proofs, fast, early stop
EARLY=1 python tools/method/prove_ghat.py spring_a spring_b jug_b                      # the 1x proofs, early stop
python tools/method/t1_diff.py <1x run dir> <fast run dir>                             # the differential
```

## Fix round (2026-11-11, after GPT's audit `audit_T1_gpt.md`: 3 blockers + the hearing gap)

Task: `MPG\notes\speed_research\trial_T1_fix_task.md` (read first; only its list read). Budget 12 wall game min.

### Runs (expected cost written before each run; wall game min, my count; the meter decides)

| # | Run | Expected | Wall | Watched | Result |
|---|---|---:|---:|---|---|
| F0 | `SPEED=fast GHAT=ghat_net,ghat_places GUARD_INJECT=<2 fake games> method_run.sh ghat` (both parts refused) | 0 | 0 (no Godot started) | inline | COMBINED TEST exit 3 (old code: exit 0) |
| F1 | B2 pair: `late_close` + `T1_LAG=overrun_control:13`, ghat_net, fast lane a + 1x lane b at once | 0.8 | 0.8 | Monitor | **both STALLED by name, judged on CLOSE**: fast 10.50 game / 5.00 wall s (the game had already ended: caught in the end drain), 1x 10.50 / 10.41 |
| F2+F3 | lane a: `on_time` + lag fast, then `late_close` fast no lag (natural); lane b: `on_time` + lag 1x | 1.0 | 1.1 | Monitor | on_time fast **PASS**, on_time 1x **PASS** (9.50 s, budget 10, read 13 s late); late_close fast natural **STALLED** (closed late 10.50 game / 5.00 wall s; it closed between two polls, never seen open past its deadline) |
| F4 | `SPEED=fast GHAT=ghat_net,ghat_places GUARD_INJECT=<lane b busy>`: fast part runs, 1x part refused | 0.4 | 0.45 | Monitor | fast PASS, 1x REFUSED -> **COMBINED TEST, exit 3** (GPT's concrete path; the old block returned 0) |
| F5 | lane a: `SPEED=fast EARLY=1 prove_ghat.py heat_always net` (exact ids, live); lane b: `GHAT=ghat_looks FIXTURE=lean_close` 1x (isolated, item 5) | 2.6 | 2.8 | Monitor | heat_always **PROVED** (own id + H1, early stop at 90.2 game s as in T1), one_layer_net **PROVED** (early stop); lean_close alone 1x: **caught, 0.14 m** |
| F6 | lane a: `SPEED=fast GHAT=ghat_looks FIXTURE=lean_close` x3, then `SPEED=fast GHAT=ghat_heat,ghat_looks,ghat_net,ghat_marks method_run.sh ghat` (the final fast part); lane b: lean_close 1x #2 | 5.1 | 6.0 | Monitor | lean_close fast 0.13 / 0.13 / 0.13 m (caught x3), 1x 0.19 m (**missed**); clean fast **PASS 4 / 4** (heat 4.84x, looks 4.77x, net 3.06x, marks 4.89x; no late step, drained, none left) |

**Fix-round total: ~11.2 wall game min of 12** (my count: F1 0.8, F2+F3 1.1, F4 0.45, F5 2.8, F6 6.0; F0 and the reused-id refusal 0; lanes overlapped counted once). F6 ran 0.9 min over its estimate (3 lean runs ~1 min each with boot). Stopped there: no run after F6.

### Blocker 1: a requested part can vanish -> fixed, proved

**Change.** `tools/method_run.sh`: every invocation gets its own id (`INV`, default time + pid; a reused id is
refused) and receipt folder `appdata/method/inv/<INV>/`: `expected` (each requested part: scenarios + fixture),
per part `.dir` (its run folder), `.rc` (its own exit, on every path incl. refusals), `.xrc` (exit seen from
outside: no more `sed`-swallowed statuses), `.refused` (why). The shared `.last_fast` / `.last_1x` pointers are
gone. New `tools/method/combine_parts.py` judges from the receipts only: a part is TEST (never PASS) when refused,
missing, its folder from another invocation, its verdict not whole (RESULT first, Evidence naming that folder
last), its scenarios or fixture not exactly the requested ones, or its exits disagree with its verdict; nothing
requested or an unrequested part's receipt is TEST too. Combined PASS only when every requested part is PASS.
Test-only `GUARD_INJECT` adds fake process lines so the **real** guard refuses without a game.

**Controls.** Offline (`t1fix_controls.py b1`, copies of the archived final run 13's two parts bound to a made-up
invocation): clean both parts PASS; first part missing, second part missing, both missing, wrong invocation,
truncated verdict, coverage short, fixture differs, exit disagrees, nothing requested, unrequested part: all TEST
(11 / 11). Live: F0 both refused at once (0 min) -> TEST exit 3; F4 fast part PASS + spring lane refused -> TEST
exit 3; a reused `INV` refused. Concurrency: two invocations share nothing (own receipt folder, own run
folders); that two lanes' *games* don't touch each other is still not proved (GPT's lane-isolation point, open).

### Blocker 2: a late step that closes between polls -> fixed, proved

**Change.** `tools/method/method_watch.py`: on CLOSE, `closed_late()` judges the step's game s (pf) AND wall s
(the game's own stamps, so a late reader judges what a prompt one would) against its budget **before** dropping
it: over on either -> `STALLED at <id>: closed late ...` (recorded even after a stop). When the wrapper exits the
watcher makes **one more full pass** (every event judged), and a truncated last line in the event / heartbeat
files is TEST. Test-only `T1_LAG=<step>:<s>`: after that step's OPEN the watcher stops reading for <s> s and
skips judging until its next read (a delayed reader that can never see the step open past its deadline).
`PlayTest.gd` (dev): fixtures `late_close` (10.5 game s vs 10) and `on_time` (9.5 vs 10) beside `overrun`.

**Controls.** Offline (`b2`): OPEN + late CLOSE in one read -> STALLED (game-late fast, wall-late 1x); on-time
pairs pass; **every real closed step in the 22 archived T1 runs (fast and 1x, clean and planted) judged by the
new rule: none late** (closest 89 %: a 16 s wait of 18). Live (F1-F3, ghat_net host):

| Fixture | Speed | Reader | Verdict |
|---|---|---|---|
| late_close | fast | 13 s late | **STALLED**, closed late 10.50 game / 5.00 wall s (the game had already ended: caught in the end drain) |
| late_close | 1x | 13 s late | **STALLED**, closed late 10.50 game / 10.41 wall s |
| late_close | fast | normal | **STALLED**, closed late 10.50 / 5.00 (closed between polls: never seen open late) |
| on_time | fast | 13 s late | **PASS** |
| on_time | 1x | 13 s late | **PASS** |

The old watcher popped all three late cases without a judgement (code: CLOSE computed the length for reporting
only); the original open-overrun control is judged by unchanged code (the open path) and was not rerun.

### Blocker 3: exact plant identity -> fixed, proved

**Change.** `prove_ghat.py` now names each plant's **own exact ids** (manifest check ids, rule ids such as `H1`),
never text. Each group runs under its own invocation (`INV=prove_<group>_<time>_<pid>`) and is judged only from
that invocation's receipt: exactly one requested part; its run folder bound to the invocation (run_info first
line); a **sealed** verdict (`verdict.json`, new, written by `method_verdict.py` before `verdict.txt`, whose
Evidence line closes it; both bound to the same invocation and part); scenarios exactly the group's, fixture
exactly the group's plant set; not a PASS; the game checked gone (no Godot of the lane left, kill verified,
wrapper exited). Then a plant is PROVED only if all its own ids are in the run's FAILed ids
(`verdict.json failed_ids`, mapped check -> manifest id by the verdict's own matcher), so a batched plant whose
own check is absent is NOT PROVED whatever else failed. Early stop (`EXPECT_IDS`, exact; the old substring
`EXPECT_FAIL` is refused) triggers only when every expected id of the group has FAILed, and PROVED rechecks
that. No glob, no "last folder", no substrings. Found on the way: jug_c's old text "over the pass" matched two
checks (the objective's too); its own id is now `ghat_jug/over_the_pass_x_s_x_c`.

**Controls.** Offline (`b3`, archived T1 plant runs regenerated through the new verdict; "old rule" = the
substring rule on the same verdict): positives heat_always (full and early-stopped) and the jug_a batch PROVED
(old: PROVED); **one expected FAIL missing** (H1 removed) NOT PROVED; **similarly named wrong check** (the
objective "... over the pass" FAILs, the plant's own over-the-pass check passes) NOT PROVED (**old: PROVED**);
**wrong run's evidence** (another invocation's folder) NOT PROVED (**old: PROVED**); a run of other plants NOT
PROVED; **batch member's own check absent** (round_skip's check passes) round_skip NOT PROVED, its two
neighbours PROVED; early stop before H1 was on record NOT PROVED, and the watcher's trigger does not fire
without H1; game not checked gone NOT PROVED (**old: PROVED**). 15 / 15. Live (F5, fast, early stop):
heat_always PROVED on its own id + H1 (stopped at 90.2 game s, as T1), one_layer_net PROVED.

Not done: GPT's causal-attribution point for batches (does one plant change who is taken, etc.). Exact ids make
each member need its own check, but a batch member's FAIL could still be caused by a neighbour. Where that
can't be argued, prove members alone (lean_close below is the one that showed it).

### The hearing gap -> decision (b): ghat_jug and ghat_places run 1x under `SPEED=fast`

**Why (b), not (a).** The code decides it, no run needed: `Hearing.gd` stamps sounds in wall ms (kept 2000 wall
ms), `Creature.gd` treats an item sound within **1500 wall ms** and 4 m of the last as a bounce (no suspicion
added, though it still notices), `Carryable.gd` drops knocks within **150 wall ms** of the last. At ~4.7x the
bounce window covers ~7 game s and the debounce ~0.7 game s, so two item sounds 1.5-7 game s apart give a
different reaction fast than at 1x, by arithmetic. Option (a) could only measure that difference, not remove it
(and two sounds *within* 1.5 s agree at both speeds, so testing only that pair would prove the wrong thing).
ghat_jug and ghat_places both drop items (`p.drop_held()` in each), so both are exposed; heat, looks, net and
marks call no drop and throw nothing (searched); spring was already 1x. **Cost: 0 qualification min.** Replay
cost (estimate from run 8's per-scenario times, not measured as a suite): the 1x lane becomes spring 233 +
jug 175 + places 9 game s + boot ~ 7.2 min; the fast lane heat + looks + net + marks ~ 151 wall s + boot
~ 2.9 min; **the suite ~7.2 wall min instead of 4.4** (two games at once), still vs 18.7 at 1x.
Change: `FAST_OK` in `tools/method_run.sh`. Not bounded: whether driving makes loose items knock near the
creature in heat / looks / marks (no item sound counter was added; none is planned by a scenario there).

### Item 5: lean_close and ghat_places

**lean_close, isolated (no fast_turn beside it).** The glass check's closest face gap, limit > 0.15 m:

| Run | Speed | Gap | Caught? |
|---|---|---:|---|
| T1 run 9 (batch with fast_turn) | fast | 0.13 | yes |
| T1 run 10 (batch with fast_turn) | 1x | 0.18 | no |
| F6 x3 (alone) | fast | 0.13, 0.13, 0.13 | yes x3 |
| F5 (alone) | 1x | 0.14 | yes |
| F6 (alone) | 1x | 0.19 | no |

Bound: fast reads 0.13 every time (no spread in 4); 1x spreads 0.14-0.19 (0.05 m). Batched or alone makes no
visible difference (1x 0.18 batched sits inside the alone spread), so fast_turn is not what moves it. **Fast is
the stricter side every time:** every fast sample (4 planted at 0.13, 2 clean at 0.33 / 0.34) is closer than
every 1x sample of the same kind (3 planted at 0.14-0.19, 3 clean at 0.35 / 0.40 / 0.35): fast never PASSed
where 1x FAILed here. So this plant proves at fast and is a coin
toss at 1x. That does not prove equivalence: a fast run reads ~0.01-0.06 m closer, so a planted bug sitting a
hair *inside* the glass at 1x would also be caught fast (safe direction), but a real fault that moves the face
*out* at fast only is not excluded by these samples. Firming the plant (stop nearer than 2.3 m) is a
`core/Plant.gd` change, off-limits here: the builder's / the user's call.

**ghat_places' negative control: none.** No plant for ghat_places exists in `core/Plant.gd`'s inventory and
Plant.gd is off-limits, so none could be added. It no longer matters for speed: places now runs 1x under
`SPEED=fast` (the hearing decision), so its fast status is withdrawn rather than resting on the clean
differential alone.

### The final source, clean, fast (F6) vs 1x (T1 run 8)

`t1_diff.py` -> `appdata/t1fix/diff_clean_final.txt`: **87 / 87 checks same verdict** (heat 19, looks 16, net 10,
marks 17 required, all ran); no late step, events drained, no Godot left. Pictures not compared this round (no
budget; the drawing code is unchanged since T1's side-by-side). **Three values fall outside T1's stated
tolerances** (both runs PASS): heat fuel after it gives up 62.17 L (1x) vs 61.11 (fast), 1.06 L against +-0.5;
looks engine ticks 526 vs 619 (+17.7 % against +-10 %; per game second +6 %, as this fast looks ran 137.1 game s
vs 123.8); looks sniffs at the back 2 vs 1. **Unexplained** (no minutes left): either the tolerances were never
calibrated (GPT's point: no multi-run 1x spread exists) or fast shifts these values. Until a 1x-vs-1x spread is
measured, heat and looks stay fast on verdict agreement only, not on value equivalence.

### Status after the fix round

| Item | State |
|---|---|
| Blocker 1 (a part vanishes) | **fixed + proved**: 11 / 11 offline, 2 live refusals + reused id; combined PASS only with every requested part PASS |
| Blocker 2 (late close between polls) | **fixed + proved**: STALLED fast and 1x with a delayed reader, fast with a natural one; on-time passes both; 0 false STALLs over 22 archived runs and the live clean run |
| Blocker 3 (plant identity) | **fixed + proved**: 15 / 15 offline (4 where the old rule said PROVED wrongly), 2 live proofs on exact ids |
| Hearing gap | **(b)**: ghat_jug + ghat_places 1x under `SPEED=fast`; 0 min; suite ~7.2 wall min (estimate) |
| `SPEED=fast` set | heat, looks, net, marks (4) fast + nodraw; places, jug, spring, `free_coolant` proofs, the recorded walk 1x |
| Still open (GPT) | batch causal attribution in general; lane isolation and split order unproven (serial is the safe default); nodraw re-arm interleaving; value tolerances uncalibrated (3 broken above); the no-round looks run unexplained; the original open-overrun control not rerun on this source (its code path is unchanged) |

### Assumed -> reality -> fix (fix round)

- **Assumed:** a python heredoc in bash keeps `\t` / `\n` as typed. **Reality:** the edits to `method_run.sh`
  came out with real tabs / newlines inside `printf` strings. **Fix:** the Edit tool for shell files. **Habit:**
  patch shell scripts with exact-string edits, then `sh -n`.
- **Assumed:** the receipt path from the shell (`/d/...`) reads the same in Windows python. **Reality:** it would
  not have (`/d/mine` is not `D:/mine`). **Fix:** `pwd -W` before writing receipts. Caught before the first run.
- **Assumed:** a delayed reader is just a sleep. **Reality:** after a 13 s sleep the old open-path judge (wall
  deadline passed) fires before the CLOSE is read, so the control would pass for the wrong reason. **Fix:** the
  lag skips judging until the next read. **Habit:** ask which code path a control really exercises.
- **Assumed:** my "similarly named wrong check" control was strong. **Reality:** twice wrong: first my flips
  overrode each other (both checks passed, nothing to catch), then a plant run had *really* FAILed the plant's
  own check downstream, so PROVED was right. The 15 / 15 hid the first, the second showed as BAD. **Fix:** set
  each check by its exact start, and print what the old rule says beside the new one. **Habit:** a negative
  control must show the old rule being fooled, or it proves nothing.
- **Assumed:** F6 ~5.1 min. **Reality:** 6.0 (three separate launches each pay boot + import). **Habit:** price
  a repeat as N launches, not N x scenario.

### Final commands (fix round)

```sh
SPEED=fast tools/method_run.sh ghat          # heat, looks, net, marks fast (lane a); places, jug, spring 1x (lane b); one COMBINED RESULT
SPEED=fast EARLY=1 python tools/method/prove_ghat.py heat_always looks net marks   # exact-id proofs, early stop (jug / spring groups route to 1x)
python tools/method/t1fix_controls.py        # the offline controls of blockers 1-3 (31 cases, no game)
python tools/method/combine_parts.py appdata/method/inv/<INV>   # re-judge one invocation from its receipts
```

## Qualification round 2 (2026-11-11, after GPT's re-check `audit_T1fix_gpt.md`; ruling R6)

Task: `MPG\notes\speed_research\trial_T1_qual2_task.md` (read first; only its list read). Source `4a74146` + the
tool changes below (game code and `core/Plant.gd` untouched). Budget 15 wall game min (stop at 18).

### Tool changes (no game code)

| File | Change |
|---|---|
| `tools/method/prove_ghat.py` | 6 solo groups (`solo_fast_turn`, `solo_leave_sees`, `solo_no_breath_lock`, `solo_round_skip`, `solo_marks_pile`, `solo_marks_unsaved`): each batched member alone, judged on its own exact ids. `PREREQ`: marks_pile counts only if the looks prelude's round check PASSED in the same run (no round = no marks on the van = "prerequisite not met (rerun, not a verdict)") |
| `tools/method/method_verdict.py` | `verdict.json` also lists `passed_ids` (manifest ids with a PASS and no FAIL); nothing else changes |
| `tools/method/t1fix_controls.py` | 3 new offline cases (7 rows): T1 run 9 (prelude made no round) -> marks_pile "prerequisite not met", marks_unsaved PROVED; the fast retry and the 1x run -> both PROVED. **38 / 38** |

### Runs (cost written before each; wall game min, my count; the meter decides)

| # | Run | Expected | Wall | Watched | Result |
|---|---|---:|---:|---|---|
| Q1 | open overrun (`FIXTURE=overrun`, ghat_net host) on the final source: lane a `SPEED=_fast`, lane b 1x (20 s later) | 0.7 | 0.75 | Monitor | **both STALLED at `overrun_control#2`**: fast 10.33 game / 5.40 wall s (game clock fired); 1x 9.90 game / 10.04 wall s (wall clock fired). Drained, kill verified, no Godot left. `120734_ghat_k3_overrun_fast`, `120754_ghat_k3_overrun_laneb`. Total 0.75 |
| Q2 | lane a: `SPEED=_fast EARLY=1 prove_ghat.py solo_fast_turn solo_leave_sees solo_no_breath_lock solo_round_skip solo_marks_pile solo_marks_unsaved` (6 launches); lane b (25 s later): `LANE=b GHAT=ghat_heat FIXTURE=one_corner` 1x x2 | 5.6 | 7.75 | Monitor | lane a: **all 5 batched members alone PROVED on their own id** except marks_pile: **its looks prelude made no round again** (0 stops) -> "prerequisite not met (rerun, not a verdict)" (the gate built above, working live). Lane b: 1x cornering search 55 s, fuel 60.79 L (run 1) and see the heat table (run 2); both INCOMPLETE only for the 3-profile check `one_corner` skips. Total 8.5 |
| Q3 | diagnostic (test-only `ROUND DIAG` log + 2 pictures, only when the looks round fails): `SPEED=_fast GHAT=ghat_looks,ghat_marks FIXTURE=marks_pile EXPECT_IDS=<looks round id>`, lane a and lane b (20 s later), both fast | 1.6 | | Monitor | |
