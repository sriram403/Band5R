# Pilot P1c (Stage 3): draw only for the pictures. Claude auditor, 2026-11-10

Task: `MPG\notes\speed_research\trial_T1_pilot_c_task.md` (P1's read lists and rules). Copy `MPG_speed_t1`,
branch `speed-t1`. Game code untouched (only `dev/PlayTest.gd`, test code). One game at a time, every run
watched every 3 s (`tools/method/probe_watch.sh`, kills on a script error or 20 s without a heartbeat).
How each run started: `FAST=1 ARGS="--nodraw" NO_CHECK=1 TIMEOUT=<s> tools/method/probe_watch.sh <scen> <label> <out>`
(the 1x run: no `FAST`, no `ARGS`). Logs, heartbeats, shots: `appdata/pilot/` (`probe_*.out`, `rig_*.txt`,
`p1c_shots/`; not in git).

## Verdict: the pictures work; the speed only shows where drawing really stopped, and it stopped only part of the time

| Run | Drawing really off? (frames drawn vs ticks) | Speed | Pictures | Checks |
|---|---|---:|---|---|
| 1 ghat_heat, fast, flag off in `_ready` | not measured (it drew, see run 4) | **1.44x** (steady 1.49x) | 1 (flat out): correct | 14 / 0 fail, same as P1 fast |
| 2 ghat_net, fast, same | **on** until the first picture (214 drawn by tick 275); **off after it**: exactly +1 frame per picture (215 ... 221 over ticks 276 -> 891) | **1.4x** before the first picture, **5.54x** after it (ticks 310 -> 868 in 1.7 wall s; peaks 6.4-7.6x) | 4: same as 1x | **3 / 3 pixel checks same verdict and value as 1x** (below) |
| 3 ghat_net, **1x** (reference) | - | 1.00x | 4 | all pass |
| 4 ghat_heat, fast, flag held off every frame | **no: 2,720 frames drawn of 2,781 ticks** while the flag read `false` all along (the reassert never fired) | 1.53x (steady 1.55x) | 1 (flat out): correct | 14 / 0 fail |
| 5 ghat_heat, fast, a drawn frame then off at tick 1 | **no: +300 frames drawn every 300 ticks** | 1.54x (steady 1.60x) | (cut at 30 s) | 2 / 0 fail |

**What works in Godot 4.7.1:** `RenderingServer.render_loop_enabled = false` set **mid-scenario, right after
a drawn frame** (shot / `grab_p1`: on -> `await frame_post_draw` -> grab -> off) stops drawing for real, and
the next on -> drawn frame -> off gives a **current** picture (not black, not stale; frames counted). I
didn't try the viewport's `UPDATE_DISABLED` / `UPDATE_ONCE` (no budget left; and the root window is not a
SubViewport, so it can't stop the main viewport's own draw).

**What doesn't:** set early in the run (in `PlayTest._ready`, or at tick 1 even after a drawn frame) the
flag reads back `false` but the engine draws every frame anyway. Something between tick 1 and the scenario's
start turns drawing back on without changing the flag (I think the world build / the window being shown
behind; not proved). The ghat_heat runs never toggled mid-scenario before their first picture at ~45 game s,
so they drew all the way: **1.44-1.55x is the "still drawing" speed, not the "draw only for pictures" speed.**
After run 4's picture at tick 2,781 the run was cut 2 s later (TIMEOUT), so ghat_heat with drawing truly off
was **not measured**. From ghat_net (5.5x on foot) and P1b's headless (4.96x on the same driving), I'd
expect ~4.5-5x (I think).

**So: go for the method, one fix untested.** Pictures and pixel checks are unchanged; the remaining step is
to switch drawing off **after the scenario's setup** (e.g. a one-frame on -> off at the start of each
scenario, after `_ghat_start`'s jump), then confirm with the frames-drawn count (= pictures + a few) and the
speed. Also open: whether the next profile's F1 jump inside ghat_heat turns drawing back on (the toggle in
`shot()` would turn it off again at the next picture only).

## The pictures, side by side

**ghat_net, 1x (run 3) vs fast + nodraw (run 2)**, all 1600x900. Side-by-side images:
`appdata/pilot/p1c_shots/side_{before,outside,inside,outside_bare}.png` (top 1x, bottom nodraw). I looked
at `outside` and `inside`:

| Picture | Mean pixel difference | What I see |
|---|---:|---|
| before | 0.65 / 255 | (numbers only) |
| outside (the dark lump) | 1.52 / 255 | same camera, same lump, same trees and road; tarp prompt **18 % (1x) vs 19 % (fast)** = the 1x/fast tick offset P1 found |
| inside (through the weave) | 0.87 / 255 | same view out, the weave grid visible in both, mirror and HUD identical |
| outside bare | 2.47 / 255 | (numbers only) |

None black (all means far above 5/255), none stale (each drawn frame counted, content matches the moment).

**ghat_heat flat out** (runs 1 and 4, fast + nodraw; files `nodraw_heat_run{1,4}_flat_out.png`): the right
moment (engine off, 0 km/h, "the radiator is boiled dry", "Something has seen the van", steam from the
bonnet, the mirror drawn), HUD readable at full size. The two runs differ by 4.7 / 255: the steam puffs are
placed differently (random, not seeded by the tick), the rest matches. **No 1x flat-out picture exists**
(P1's 1x run stopped at 38 s, before it), so for ghat_heat the 1x comparison is by content, not pixels.

## ghat_net's 3 pixel checks: 1x vs nodraw

| Check | 1x (run 3) | fast + nodraw (run 2) |
|---|---|---|
| from inside: a faint grid, the outside clear (change 0.004-0.12, brightness > 0.25) | PASS, change 0.106, brightness 0.645 | PASS, change 0.107, brightness 0.645 |
| from outside a dark lump (change > 0.08, brightness < 0.3) | PASS, change 0.532, brightness 0.227 | PASS, change 0.532, brightness 0.225 |
| nothing bright shows through (bright < 3 % and bare > bright + 5 %) | PASS, 3 % / 86 % | PASS, 3 % / 86 % |

Same verdicts, values within 0.002. (Seen, not judged: the inside change 0.106 sits near its 0.12 limit,
and the bright share rounds to 3 % against a < 3 % limit, in both modes.)

## Game minutes (my count; the referee's meter decides)

run 1 50 s (TIMEOUT) + run 2 ~21 s + run 3 ~27 s + run 4 45 s (TIMEOUT) + run 5 30 s (TIMEOUT) =
**~173 s ≈ 2.9 game min** of the 3. `tasklist` empty before and after each run.

## Assumed -> reality -> fix

- **Assumed:** `render_loop_enabled = false` in `_ready` stops drawing (the getter said `false`).
  **Reality:** 2,720 frames drawn of 2,781 ticks; the flag only takes effect when toggled mid-scenario.
  **Habit:** prove "nothing drawn" by counting `Engine.get_frames_drawn()` against ticks, never by
  reading the flag back; and check the speed per stretch, not only the whole-run number (ghat_net's 1.4x
  then 5.5x is what gave it away).
- **Assumed** (from P1b): run 1's 1.44x meant drawing-off barely helps. **Reality:** run 1 was still
  drawing. An unexplained number is a question, not a result.

## Test-code changes (committed on `speed-t1`, off by default)

`FindingNaresh/scripts/dev/PlayTest.gd`: game argument `--nodraw` (windowed only): `shot()` and `grab_p1()`
switch drawing on for their one frame and off after; `_process` holds it off between pictures and prints
frames drawn every 300 ticks; `_nodraw_start` does the early one-frame toggle (shown **not** to work at
tick 1: the next step moves it to after the scenario's setup). The builder's N5 stall control still works
(it turns drawing off after `shot()` turns it on).
