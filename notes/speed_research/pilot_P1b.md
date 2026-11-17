# Pilot P1b (Stage 3): is drawing the brake? Claude auditor, 2026-11-10

Task: `MPG\notes\speed_research\trial_T1_pilot_b_task.md` (P1's read lists and rules). Copy `MPG_speed_t1`,
branch `speed-t1`. Game code untouched. One game at a time, every run watched every 3 s
(`tools/method/probe_watch.sh`, new: heartbeat speed + every new PASS / FAIL / SCRIPT ERROR line; it kills
only this copy's Godot on a script error or 20 s with no heartbeat).

## Verdict: yes, drawing is the brake. Headless runs the ghat at ~5x; a tiny window doesn't help

| Run (ghat_heat, same inputs, `FAST=1` = `--fixed-fps 60 --disable-vsync --max-fps 0`) | Speed (whole stretch) | Steady (after 5 s) | Game s covered | Frame cost |
|---|---:|---:|---:|---:|
| 1x, 1600x900 (P1) | 1.00x | 1.00x | 38.5 | - |
| fast, 1600x900 (P1) | 1.23x | 1.24x | 48.6 | ~13.4 ms |
| **fast, 320x180** (P1b) | **1.23x** | **1.23x** | 55.8 | ~13.6 ms |
| **fast, `--headless`** (P1b) | **4.96x** | **4.98x** | **334.3** | **~3.4 ms** |

- **Pixels are not the cost.** 320x180 (1/25 of the pixels) is the same speed as 1600x900. GPU was at 53 %
  during the tiny run and the game used ~1.2 CPU cores: the ~10 ms is the CPU side of drawing (culling
  and sending a world of 53,367 undergrowth trees and the rest every frame), paid once per game tick under
  fixed-fps, whatever the window size. The encounter still dips (tiny: 0.79x for 3 s; headless: ~4.1-4.5x).
- **Headless:** physics + scripts ≈ 3.4 ms a tick, so the simulation's own ceiling on this PC is ~5x.
  Boot (launch -> first heartbeat) ~11 wall s headless vs ~15-16 windowed; world build 7.6 s vs 8.7 s.
- **The three fast runs are tick-identical.** fast 1600x900 and fast 320x180 print the same 64 test lines
  (every telemetry line, every value). Headless matches them line for line until the first screenshot,
  then is ~1 road sample earlier (a windowed `shot()` waits for one drawn frame, headless skips it); every
  outcome value in the flat-out profile is identical (seen at sample 268, boils 6 s after, rests at 329 /
  boiled at 314, 1.2 L leaked). 1x vs fast differ only in the first ticks (P1: a 1x `wait()` ends on a
  144 Hz frame) and agree on the outcome lines both reached.

Game minutes used (my count; the referee's meter decides): headless 80 s (killed at TIMEOUT=80) + tiny 62 s
(TIMEOUT=62) = **142 s ≈ 2.4 game min** of the 4. `tasklist` empty before and after each run.

## 1 and 2: the checks, fast headless and fast tiny vs 1x

How: `FAST=1 ENGINE_ARGS="--headless" NO_CHECK=1 TIMEOUT=80 tools/method/probe_watch.sh ghat_heat headless_fast <out>`
and the same with `ENGINE_ARGS="--resolution 320x180"`, TIMEOUT=62 (`--resolution` after run_test.sh's
own 1600x900 wins: the log says `window=(320, 180)`; window sent behind in 506 ms). Logs and heartbeats in
`appdata/pilot/` (`probe_headless_fast.out`, `probe_tiny_fast.out`, `rig_*.txt`; not in git).

| | 1x (P1, 38 s) | fast 1600x900 (P1) | fast 320x180 | fast headless |
|---|---|---|---|---|
| reached | flat out, t=38 | flat out done + cornering t=8 | flat out done + cornering t=9 | flat out + **cornering incl. its follow-on (circles, tarp, gives up, heat and leak stop, objective)** + crawling to t=159 (hot-with-watching) |
| PASS / FAIL / script errors | 3 / 0 / 0 | 14 / 0 / 0 | 14 / 0 / 0 | **33 / 0 / 0** |
| screenshots | (none reached) | 1, 1600x900 | 1, **320x180** (HUD unreadable: useless to judge) | **none: `shot()` returns at once headless (by design)** |
| checks that fail or skip vs 1x | - | none | none | **none** in ghat_heat: no ghat_heat check reads a picture |

So in ghat_heat **no check changes**; what headless loses is only the screenshots (4 in a full run: one per
profile + Problem at the van; 1 more only on a failed start). The tiny window keeps them but makes them unreadable, and buys nothing. Neither run
reached the end of ghat_heat (the crawl profile was cut by the TIMEOUT), so ~1/3 of ghat_heat's checks were
not seen in any fast mode; none of them reads a picture (step 3).

The wall clock already shows: headless logged "it reached the van in **4 s**" and "gave up after **8 s**
under the tarp": wall seconds, ~20 and ~40 game s. The "harder driving boils it sooner" check (needs all
three profiles) was not reached.

Seen, not judged (game code, untouched): the second and third profiles' "the engine starts" check passes
with a stale `start_fail` text from the previous profile's boiled van (`'The starter turns, the engine won't
catch...'`). The check reads `engine_on`, so it is right; the message is old.

## 3: which checks need real pictures (from the code, 0 game min)

How: a script walked `PlayTest.gd`'s call graph from each scenario (and the walk's helper) and listed every
`shot(`, `get_viewport().get_texture`, `get_image`, `get_pixel`, `get_luminance`, `frame_post_draw`,
`capture_aabb`, fps, `headless`, audio reads; then read each hit. Game code: no `VisibleOnScreen*` or
render read anywhere on the ghat (only `Boot`'s and `PhotoCamera`'s screenshots, not on these paths), so
the creature's senses don't depend on drawing. The walk: `tools/live/ghat.json` (21 steps, LiveControl).

| Scenario (episode cap, game s) | Screenshots (lost headless) | Checks that read pictures | Headless? |
|---|---|---|---|
| ghat_heat (660) | 4 + 1 on a failed start | none | **yes** (measured: 33/33 pass) |
| ghat_looks (360) | 3 `obs_shot` | none (eyes = `emission_energy_multiplier`, whine = `_hum.pitch`, angles: state) | **yes** |
| ghat_net (120) | 4 | **3**: through the windscreen (`grab_p1` + `img_stats`: faint grid, outside clear), from outside a dark lump (`_obs_image` + `img_stats`), nothing bright shows through (`bright_share`) | **no**: `grab_p1` has no headless guard and waits for `frame_post_draw`, which never fires headless (`shot()`'s own comment) -> it would hang at "the view out before" (I think; not run). The thresholds are tuned on 1600x900 pictures, so not tiny either |
| ghat_places (240) | 3 | none (spring height, pot litres, note text: state) | **yes** |
| ghat_jug (480) | 1 on a failed start | none | **yes** (its `jug_b` proof's plant `free_coolant` reads the wall clock: that proof stays 1x, P1) |
| ghat_spring (780) | 3 | none | checks yes, **but stays 1x**: game-code wall clock (`Camper._blow_cap` 3 s = 15 game s at 5x) and the 5 s "it comes back" test deadline (P1) |
| ghat_marks (720) | 5 (3 marks views, 2 credits) | none (marks are state) | **yes**, but the marks are a looks feature: its pictures are what the user judges |
| walk `ghat.json` | none (no `shot` step, no picture expect) | none | a rehearsal could; **the recorded walk can't**: `record_walk.sh` draws every frame at 1600x900 (`--write-movie`) |

Share of a ghat suite (by episode caps) that could run headless: heat + looks + places + jug + marks =
2,460 of 3,360 game s = **73 %**; 1x windowed: spring 780 + net 120 = 27 %.

## What it does to the plan's minutes (top4.md; R2's wall-clock score)

Headless process speed ≈ **4.5x** overall (4.96x in the scenario, the ~11 s boot not sped up).
Using P1's two budget models (fixed 1x part + speedable part), 73 % of the speedable part headless, the
rest at 1x (fast-windowed is 1.24x and unqualified: not worth it):

| Model | Fixed (1x) | Speedable | -> headless 73 % at 4.5x | -> rest 1x | **Total** |
|---|---:|---:|---:|---:|---:|
| Claude (audit r2) | 31 | 74 | 54 -> 12.0 | 20 | **~63 min** |
| GPT (audit r2) | 37 | 62 | 45 -> 10.1 | 17 | **~64 min** |
| top4 rows (D 12, A+C 55 at 0.43; B/E/F 32 at 1x) | | | | | **~61 min** |

**Under 75 (I think), without the 2x column**, and summed process minutes fall by the same amount (R2's
10 % cap is safe). Running the 1x windowed part (spring, net, the walk) beside a headless game would cut
wall-clock further (two games at once, R2): headless needs no window and ~1 core.

**What it costs and what must hold first (all from P1 + this pilot):**
1. **The T1 clock split is now mandatory, not optional.** At 5x every wall-clock deadline loosens 5x
   (the 5 s return = 25 game s; `method_watch`'s STALL budgets 5x): the 19 test-code sites and the STALL
   judge must read game time (physics frames) before any headless PASS counts.
2. **Game-code wall clocks stay** (forbidden to change): ghat_spring and the `free_coolant` proof stay 1x;
   `Carryable`'s 150 ms knock debounce becomes 750 game ms (fewer knock sounds the creature can hear:
   places / jug / walk could behave differently); `Hearing.KEEP_MS` only prunes old sounds (creatures read
   by id: I think harmless). The 1x-vs-headless differential per scenario (with tolerances) + one plant
   each decides it.
3. **Screenshots are lost headless.** The user's rule is to look at them. Either the last unshortened
   suite runs windowed 1x (adds back roughly a suite's 1x minutes x 0.57: likely pushes the total to ~75,
   untested), or the cheaper idea below.

## What I'd do next

1. **P1c, ~1 game min: draw only when a picture is taken.** Test code only: `RenderingServer.render_loop_enabled
   = false` in a windowed fast run, switched on just around `shot()` / `grab_p1()` (the method already does
   this for the builder's N5 control). If that runs at ~4-5x, the suite keeps every screenshot and ghat_net's
   picture checks at full size, and only ghat_spring + the `jug_b` proof stay 1x. If drawing can't be
   paused cleanly (the first frame after a pause stale, a shot blank), headless + a windowed final suite.
2. Then T1 as planned, on physics frames: the 19 deadlines + the STALL judge, the differential
   (headless or P1c vs 1x, outcomes within tolerance) on heat, looks, places, jug, marks, and one plant each.
3. Drop the tiny-window idea: no speed, unreadable pictures.

## Assumed -> reality -> fix

- **Assumed** (P1's "what I'd change", and the task's step 2): a small window would cut the frame cost.
  **Reality:** 320x180 = 1.23x, same as 1600x900; GPU half idle. The cost is drawing the world at all
  (CPU side, per frame), not pixels. **Habit:** split render cost into "per pixel" and "per frame / per
  object" before shrinking the window; headless is the clean way to get the simulation's own ceiling.
- **Assumed:** headless might break checks broadly. **Reality:** the game has a headless mode by design
  (CI): every ghat_heat check passed; only ghat_net's 3 pixel checks (and its unguarded `grab_p1`) can't.

## Tool changes (committed on `speed-t1`)

- `tools/method/probe_watch.sh`: one watched speed-probe run (above). Default runs unchanged.
