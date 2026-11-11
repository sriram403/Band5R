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
| F5 | lane a: `SPEED=fast EARLY=1 prove_ghat.py heat_always net` (exact ids, live); lane b: `GHAT=ghat_looks FIXTURE=lean_close` 1x (isolated, item 5) | 2.6 | | Monitor | |
