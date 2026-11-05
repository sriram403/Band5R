# Trial c1: the rig layer (Claude auditor builds and qualifies)

Branch `g13-trial-c1` from `g12` `629f8c1`. Built 2026-11-05, 22:26-22:49
(clock from `date`). Definition: `top4.md` row c1, with my round-2 concessions
(`audit_r2_claude.md`, "c1: the rig layer"): no SET counter, no per-run
physical controls, "body didn't move" is a game outcome, T2 claimed only for
missing names and parse / run errors.

## Verdict up front
- **All 7 injections caught (T1-T3, N1-N4), each once, all under 60 s.**
- **A clean `ramp` run with the rig healthy was NOT shown.** All 3 clean
  `ramp` runs were stopped by **my own rig's false alarms** in the input
  receipt check, a different cause each time. I fixed the first two. The
  third fix is committed **unverified**: by the 3-round loop rule I didn't
  rerun it. One clean run with the rig healthy and inner PASS was seen on
  `ramp_edges,ramp_wedge` (49 s), which doesn't use the pad-receipt path
  that failed.
- By the brief's "must pass one clean run", qualification is **incomplete**.
  The referee picks which head to score (see "Heads").

## What was built (test code only; the game is untouched)
| File | Lines | What |
|---|---|---|
| `FindingNaresh/scripts/dev/RigBeat.gd` | 195 (new) | The in-game half. One flushed heartbeat line every 0.5 s and one line per rig event, both to `appdata/playtest/runs/rig.txt`. The beat carries: engine physics frames, a **world clock** (a pausable node's own physics ticks, which stop when the game pauses), paused, pause note, scene generation, pid, the scenario now running, P1 / P2 in the scene, P2's device (PAD0 / KBM), and the last `[test]` line. Input receipts: requested -> reached the intended player's device. |
| `FindingNaresh/scripts/dev/RigInject.gd` | 96 (new) | The referee's injection hooks (below). Nothing in the rig reads them. |
| `FindingNaresh/scripts/dev/PlayTest.gd` | +86 | Hooks only: `key` / `pad_axis` / `pad_button` report requests; a pause guard in `wait` / `until`; `start` / `end` events per scenario; `_rig_plan` (before step 1: the real run order, anything after `save`, asked names that won't run, and each wrapped scenario's declared `RIG_NEEDS` run once as expressions). `t_ramp` itself is unchanged. |
| `tools/rig/rig_watch.py` | 233 (new) | The outside watcher. Reads `rig.txt` every 1 s, stops the run at once (`taskkill` by the beat's pid), and prints the two-part verdict and asked vs ran. |
| `tools/rig_run.sh` | 21 (new) | One command: starts `tools/run_test.sh` with the watcher next to it. |

**Rules in the watcher** (the brief allows a 45 s stall limit; these are faster):
| Rule | Limit | Says |
|---|---|---|
| No new heartbeat (main loop stopped) | 20 s (allows the `save` reload's world build; reload time not measured) | NOT healthy: frozen |
| Beats arrive, physics frames don't | 10 s | NOT healthy: physics stopped |
| Paused and the world clock stopped | 5 s | P2's device went PAD -> KBM within 3 s before = **TEST problem: P2's pad lost, the game correctly paused**; else NOT healthy: paused |
| P1 / P2 not in the scene during a scenario | 2 beats (~1 s) | NOT healthy: player missing |
| `input_lost` event | at once | **TEST problem**: the input never reached the intended device |
| `lint` / `need` event (before step 1) | at once | **TEST problem**: the plan / a stale name |
| End of run | | asked vs ran **by ID**; any asked and not ran: TEST (if the plan check named it) or NOT healthy (skipped) |

**The verdict** (stdout and `appdata/playtest/runs/rig_verdict.txt`), two parts:
```
==== RIG: healthy | TEST problem: <which> | NOT healthy: <which> ====
     asked n (ids), ran m (ids), not run k (ids); seconds
==== INNER CHECKS: PASS | FAIL (n) | not finished   [not counted: the rig isn't healthy] ====
```
Exit 0 only when the rig is healthy. The inner checks are `t_ramp`'s own, passed through untouched.

**Input receipts, exactly:** only "did it reach the device" may say TEST.
- A pad input checks four things: P2's device is a pad, it's device 0, P2's player reads that device, and for a stick the axis value and `InputDevice.move()` read it back (stick axes, not the button table). What the body then did is never judged.
- A key checks only that some player is on the keyboard.
- A release or a stick back to 0 isn't judged. Neither is an input sent outside a scenario, or one the test itself replaced with a different value before the check.

## Minutes
| Part | Minutes |
|---|---|
| Reading, then build to the first run | ~6 (22:26-22:32) |
| Qualification: 12 runs, 22:32-22:47 | ~15 (runs 15-89 s each) |
| Fixes between runs | inside the above |
| Report and commits | ~2 |
| **Total** | **23 of 60 (22:26-22:49)** |

## How to run (from `MPG_dev`)
```
tools/rig_run.sh ramp
```
The cost is the same as `run_test.sh ramp` (86-89 s game time measured here; compile ~8 s with nothing changed). It takes the same arguments (`NO_CHECK=1`, `ARGS=...`). Live progress: one `[rig-watch]` line every 5 s, plus every event as it happens.

## Injections (for the referee; `dev/RigInject.gd`)
`ARGS="--inject=<ID>[@<s>][:<text>]" tools/rig_run.sh <plan>`. `<s>` is seconds after the first scenario starts (default 20).
| ID | Effect | Command used in qualification |
|---|---|---|
| T1 | `boot._on_joy_changed(0, false)` at s | `ARGS="--inject=T1@20" tools/rig_run.sh ramp` |
| T2 | a stale expression added to the wrapped scenario's declared needs (`:<text>`, default `rj().ramp_lip`) | `ARGS="--inject=T2" tools/rig_run.sh ramp` |
| T3 | the test plan runs `save` first, so everything else is queued after it | `ARGS="--inject=T3" tools/rig_run.sh ramp_wedge,save` |
| N1 | the main thread blocks for good (`OS.delay_msec` loop) at s | `ARGS="--inject=N1@5" tools/rig_run.sh ramp_wedge` |
| N2 | `get_tree().paused = true` at s | `ARGS="--inject=N2@20" tools/rig_run.sh ramp` |
| N3 | P2 taken out of the scene at s | `ARGS="--inject=N3@20" tools/rig_run.sh ramp` |
| N4 | the plan silently drops the first asked scenario | `ARGS="--inject=N4" tools/rig_run.sh ramp_wedge,ramp_edges` |

Separation, for the referee's read: `--inject` is parsed only in `RigInject.from_args`. `RigBeat.gd` and `rig_watch.py` never mention it. PlayTest calls the injector only to let it misbehave (`inject.plan`, `inject.needs`, `inject.arm`).

## What c1 claims, and what it doesn't (R5)
- **Claims:** the run was alive (heartbeat, physics, world clock), in control (not paused, both players there, pad inputs reached P2's device), and complete (asked = ran by ID). TEST problem only for: an input that never reached its device, a broken plan (after `save`, unknown or dropped names), and a declared expression or name that fails to parse or run, or is null.
- **NOT PROVEN:** anything about the game (S2 = 0 by design); whether a body did what the input asked; a stale but valid expression that reads the wrong thing; names used inline in scenario code (not declared in `RIG_NEEDS`); keys beyond "someone is on the keyboard"; pause safety in scenarios other than `ramp` (the pause guard covers `RIG_NEEDS` scenarios only).

## Qualification results (logs: `appdata/playtest/runs/q*_watch.txt`, not in git)
| Run | Plan / injection | Rig verdict | Noticed | Notes |
|---|---|---|---|---|
| q1 | `ramp`, clean | TEST: input lost (**false alarm, mine**) | 88 s run | A stick release checked after the teardown unplugged the pretend pad. Fixed: releases and inputs outside the scenario aren't judged. Inner: FAIL (1) "crate + leg-up: P2 is in through the smashed shutter" (passed in q3: the inner checks vary run to run; c1 doesn't judge that). |
| q2 | `ramp`, clean | TEST: input lost (**false alarm, mine**) | 86 s | `pad_walk_to` puts the stick back to 0 on arrival; the arrival frame's -1 was checked after it. Fixed: skip when the test since sent a different value. |
| q3 | `ramp`, clean | TEST: input lost (**false alarm, mine**) | 89 s | Four "-1 sent, reads 0" in a row in the hut walk, right after a `shot()`. Hypothesis, not measured: injected input is applied at the next process frame, and at a low frame rate "+2 physics frames" comes before that. Fix in `57b8afd`, **unverified** (loop rule). Every inner check up to that point passed. |
| q4 | T2 | **TEST: stale expression** `rj().ramp_lip` | 15 s from launch | Found before step 1. The scenario's `start` fired, and the kill landed within ~1 s. |
| q5 | N2 @20 | **NOT healthy: game paused**, world clock stopped | **5.6 s** after the pause | |
| q6 | T1 @20 | **TEST: P2's pad lost (PAD0 -> KBM), the game correctly paused** | **5.5 s** | |
| q7 | N1 @5 | NOT healthy: "physics stopped" | 10 s | Right catch, wrong words (beats had stopped too). Fixed: the physics rule only counts while beats are fresh. |
| q12 | N1 @5 (rerun) | **NOT healthy: frozen, no heartbeat for 20 s** | **~20 s** | |
| q8 | T3 | **TEST: ramp_wedge queued after save** | 17 s from launch, at the plan | asked 2, ran 0 |
| q9 | N4 | injector bug: it dropped "audio" (first of the whole list) | | So this was a **clean run: RIG healthy, asked 2 ran 2, inner PASS, 49 s**. Injector fixed. |
| q10 | N4 (fixed) | **TEST: asked for ramp_edges, not in the run order** | 27 s from launch | **asked 2, ran 1, not run 1 (ramp_edges)** |
| q11 | N3 @20 | **NOT healthy: P2 missing from the scene** | **1.5 s** | |

## Heads
- `a106f90`: the behaviour qualified above (q4-q12). It has the q3 false alarm: I expect it to stop most clean `ramp` runs at the hut walk (3 of 3 here, two of them by causes since fixed).
- `57b8afd` (the branch head): adds only the input-flush wait in `RigBeat._check_receipts`. **Never run.** I think it removes the q3 false alarm; not measured.

## Known gaps
1. **No healthy clean `ramp` run shown** (above). The receipt check's timing was my weakest part: 3 false alarms in 3 runs.
2. The pause guard covers only scenarios in `RIG_NEEDS` (`ramp`). The outside 5 s pause rule covers every scenario, so scenarios that pause on purpose for more than 5 s (pause-menu tests) would be stopped: a false alarm outside the ramp.
3. The 20 s no-heartbeat limit was picked for the `save` reload's world build, which wasn't measured (T3 was stopped before the reload).
4. The TEST label for a pad lost relies on the pad being the test's pretend pad. A game bug that drops P2's device would also be labelled TEST (wrong-blame risk; I think rare, since device 0 isn't a real pad here).
5. A needs or plan failure doesn't stop the game from inside: the scenario starts and the watcher kills it about 1 s later.
6. `SCRIPT ERROR` lines in the segment log aren't part of the rig verdict (`run_test.sh` lists them under "Problems").
7. Presets (`smoke`, `full`, `set:*`) take "asked" from the game's own plan line, not from outside.
8. `resume` isn't supported: `rig_run.sh` starts a fresh `rig.txt` every time.
9. The heartbeat's own cost (open, append, close twice a second) wasn't measured.

## My predicted scores (all "I think")
| Check | Prediction |
|---|---|
| S1 | At `a106f90`: fail (the q3 false alarm). At `57b8afd`: 10 / 10 rig-healthy if the flush hypothesis is right. Unmeasured. |
| S2 | 0 by design. c1 claims nothing about the game. |
| S3 | 3 / 3: T1 5.5 s, T2 at the plan check, T3 at the plan check. Each seen once. |
| S4 | 4 / 4: N1 ~20 s, N2 5.6 s, N3 1.5 s, N4 asked 2 / ran 1. Each seen once. |
| S5 | Pass: the rig only reads. `t_ramp`'s own set state is unchanged and not claimed. |
| S6 | No model in the loop. Run time is the scenario's own (86-89 s for `ramp`); the overhead wasn't separated. Reading: 2-4 verdict lines. Build and qualification: 23 minutes. |
## Referee's scoring of c1 (2026-11-05, 22:55-23:35)

Scored head: `g13-trial-c1` `a6a412f` (includes `57b8afd`, the input-timing fix the builder
never ran). Every run watched by the referee (log growth every 5 s, a 60 s silence flag),
one game at a time. Injection times and plans differ from the builder's own.
Code read: `--inject` is parsed only in `RigInject.from_args`; `RigBeat.gd` and
`tools/rig/rig_watch.py` never read it (the watcher reads the heartbeat file and the plan).

| Check | Runs | Result |
|---|---|---|
| **S1** no false alarms (the rig's verdict) | 10 clean `tools/rig_run.sh ramp` | **10 / 10 RIG healthy**, asked 1 ran 1 each time. The builder's last fix held. (Speed / lane variation: n/a, c1 claims nothing about the game.) |
| **S2** finds real bugs | none | **0 / 7: not covered** (R5: c1 claims nothing about the game) |
| **S3** blames the right thing | T1 pad pulled at 45 s; T2 my own stale name `camper().ramp_gauge`; T3 `ramp_edges,save` | **3 / 3 "TEST problem", each named right.** T1 within ~4 s; T3 in 40 s. **Defect: T2 was caught before step 1 (~22 s) but the STOP didn't stop the game: the kill failed and the scenario played on for ~115 s** (to its end). The verdict stayed right. |
| **S4** can't pass by doing nothing | N1 frozen at 50 s; N2 paused at 60 s; N3 P2 removed at 35 s; N4 on `ramp_edges,ramp_wedge` | **4 / 4**: N1 in 20 s ("no heartbeat"), N2 in 5 s, N3 at once, N4 named (`ramp_edges` not run) in 27 s. All under the 60 s limit. |
| **S5** real path | code read | **Pass**: c1 adds no teleport, set state or aimed camera; it proves no game state. |
| **S6** cost | measured | Build 23 min (cap 60). A clean `ramp` under the rig: 137-146 s wall (the inner scenario ~113 s + compile); the rig's own overhead is small (I think; not measured against a bare run of the same length). No model tokens or model time per run. Scoring: 17 runs, ~35 min of machine time. |

**Verdict: c1 passes its claim** (the run was alive, in control and complete), with one
defect (a STOP that failed to kill). Under R1 it's now fit to be reused, once the GPT
auditor's audit is in.

### Side data, not c1's score: today's `t_ramp` on a game the user says works
11 full runs under the rig (S1 1-10 + the T2 run, which played to its end):
**7 PASS, 4 FAIL** -> today's method fails S1 on its own.
| Run | Flat-out lip | Off middle | Result |
|---|---|---|---|
| S1_1 | 66.0 | 1.07 | landed; **drive-off FAIL** (13 m, 17.0 m off the road) |
| S1_4 | **57.1** | 1.53 | **miss** (the run-up lost after the reset: P1's symptom, with no patch on) |
| S1_5 | 66.6 | 0.82 | **miss** |
| S1_6 | 66.4 | 0.90 | landed; **drive-off FAIL** (10 m, 13.6 m off) |
| S1_2,3,7,8,9,10, T2 | 66.5-66.8 | 0.81-1.07 | PASS |
| baseline (g12) | 66.5 | 1.05 | miss |
S1_3 (66.6 / 0.81) landed and S1_5 (66.6 / 0.82) missed: speed and offset at the lip
don't decide it. Cause not measured: g2's question. The 57 km/h try is the evidence table's
"used up its run-up" row coming back, or the test's restart; not measured either.

### The GPT auditor's audit
`audit_c1_gpt.md` (written before the referee's scoring). Its reuse conditions were exact-head
controls and a clean `ramp` that exercises the input receipts. The scoring above meets both
(7 / 7 injections and 10 / 10 clean `ramp` runs on `a6a412f`; the hut stretch drives P2 by pad,
which is where the false alarms had been). Accepted for reuse: ruling R8.
