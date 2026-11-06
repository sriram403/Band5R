# FINAL: the test method for complex play (research result, 2026-11-06)

Brief: `notes/TEST_METHOD_RESEARCH.md`. Process and every score: `scoreboard.md`. The method's code:
branch **`g14-final`, frozen at `ceb63e3`** (local, not merged). This file: the referee's summary of the
agreed method and its exam numbers; both auditors' signatures are at the end, in their own words.

## The method in one paragraph
**Bounded contract testing, judged from outside.** One script plays the stretch with real inputs
(today's `t_ramp`, plus short declared stretches `c2_more`); declared setup is listed line by line
and never claimed as proven. Three watchers judge it, with no model in the loop: **health** (c1's
heartbeat, scenarios asked / started / ended, g2-style deadline on every awaited step, the game process
checked gone after a kill), **completeness** (every required check and work item has a receipt, or the
run is INCOMPLETE), and **state rules** (c2's rules on the game's own state, read through validated,
typed reads, so a renamed field is a TEST problem, never a silent "not reached"). One verdict per run.

## What the user runs
`bash tools/method_run.sh ramp` (on `g14-final`; ~2 min 45 s; optional profile `k0`..`k4` = speed x lane).
It prints one line first:
| RESULT | Means | Exit |
|---|---|---|
| PASS | every required check ran and held, every rule that looked was right | 0 |
| FAIL | a check or rule broke: names the thing, owner UNRESOLVED (who's at fault isn't guessed) | 1 |
| INCOMPLETE | required work never happened (e.g. the jump missed, a step STALLED): names what's missing | 2 |
| TEST | the test itself is broken (a stale field, an error in test code) | 3 |
| NOT HEALTHY | the run wasn't alive / in control (frozen, paused, a player missing) | 4 |
Below it: every condition in the order it began (the earliest is the headline), every jump attempt,
rule coverage, the scope, and a NOT PROVEN list.

## The numbers (scoreboard checks, frozen head `ceb63e3`, all runs watched by the referee)
| Check | Result |
|---|---|
| S1 no false alarms (10 clean runs, 5 speed x lane profiles x 2) | **9 PASS, 1 INCOMPLETE** (the drive-off flake), **0 FAIL**. Also seen in the exam: one clean-game FAIL from today's hut walk ("out of the door with the wheel"), a test-walker flake. |
| S2 secret bugs (ramp, 7) | **3 / 7 caught and named**: the invisible door wall, the short jump counted as landed, the swimmer on the wrong bank. **Missed 4**: a wheel that never turns (looks only), the van pulling left after the refit, the rewards under the floor (the check only asks "do they exist"), a boiling engine jumping (no run tries a leak). |
| S2 practice set (on c2, the same rules) | 6 / 7 reliably; P6 now has an axle rule (the builder's control catches a 0.25 m hub, FAIL G3b). |
| S3 blames the right thing | T4 (a game field renamed) -> **TEST before the drive, 26 s**; error in test code -> TEST; error in game code -> FAIL, owner unresolved. |
| S4 can't pass by doing nothing | **N5 for real** (window minimized mid-run) -> **STALLED in 5.5 s**, process gone; early return -> INCOMPLETE naming the missing work; frozen / paused / player missing via c1's rig. |
| S5 real path | pass: 60 declared setup lines listed in `frozen.json`; inputs only in between. |
| S6 cost | ~165 s per run, no model time per run; build 24 min. |
| S7 another puzzle | **NOT DONE** (the user chose to skip it to save cost, 2026-11-06). The port steps are below; the referee's two water-works bugs stay unused. |

**Compared with today's method (v5, `t_ramp` alone):** v5 passed 7 / 11 on the working game, hung
silently when the window was minimized (~440 s), and its "all fine" could hide a broken test. The
final method never hung, said TEST on a broken test, and turned the driver's misses into a plain
INCOMPLETE instead of a game failure.

## What it can't do (honestly)
- **It catches bugs only where a check looks** (3 / 7 on the exam). More checks, not more research,
  close that: see the starter checklist.
- **The driver and walker still flake** about 1 run in 5 (drive-off 3 / 20 clean landings across the
  research; one hut-walk flake). The method reports it as INCOMPLETE / FAIL-unresolved; it doesn't fix it.
- **Why the same ~66.5 km/h jump sometimes misses** is still unexplained (g2: INCONCLUSIVE; the short
  0.3 s wait after a reset missed 3 / 4, other arms 0 / 13: a count, not a cause).
- It doesn't judge fun, or what a player sees (observer pictures only), or anything outside its scope list.
- Not tested on a second puzzle (S7 skipped).

## Using it on a new puzzle (the agreed port steps, ~1 hour, untested)
1. Read the puzzle's code and test scenario; list its required work from the design.
2. Write the manifest: required checks and work IDs, setup vs input-only stretches, typed reads.
3. Bind the generic rules where they apply (G1-G4), thresholds unchanged.
4. Add 0-3 puzzle rules from how the puzzle is built ("X sits where it was built").
5. Deadline every new await; mark reach steps.
6. Two clean runs; set step budgets from them; commit.
7. Report hours and lines.

**Starter checklist** (the kinds of rule that caught bugs, or would have):
- an **indicator matches the real state** (HUD, gauge, prompt);
- a thing **sits where it belongs**, not just exists (rewards on the bench, the hub on its axle);
- **nothing appears from nowhere** (water, items);
- after a fix, the thing **behaves fixed** (the van drives straight, the wheel turns);
- every **mistake path** the design promises happens once (a miss resets, a boil stops the van);
- a player can **walk through** what's open, and **can't** through what's shut.

## A first draft for `notes/TESTING_METHOD.md` (v6, proposed; the user decides)
- v6 = v5's watched run + **an outside judge**: health, completeness and state rules decide one RESULT;
  no model in the loop. Simple scripts stay for simple things.
- A step never waits without a deadline; a stopped game is checked gone.
- Missing work is INCOMPLETE, a broken test is TEST, a broken game is FAIL with the thing named;
  "who's at fault" stays unresolved unless measured.
- Every new puzzle gets the starter checklist before it's called covered.
- The recorded walkthrough for the user (v5) stays.

## Lessons proposed for the skills library (the user decides; not edited)
- `testing-and-verification`: a heartbeat proves the engine is alive, not that the test moves (deadline
  every step); a renamed field must read as a test problem, never "not reached"; check placement, not
  existence; a planted bug's symptom can depend on something unmeasured (prove it several times); turn
  each failure seen in the wild (a minimized window) into a planted control.
- `first-principles-solving`: an exact-equality rule on physics state can't hold; measure before
  writing a threshold.

## How it was chosen (short)
14 ideas -> top 4 (2 rounds) -> trials c1 (rig: passed), g1 (driver: failed), c2 (state checks: 6/7
practice, a stale-field false pass), g2 (causal recorder: strong health checks, not a detector) ->
3 rounds of agreement (16 / 21 points agreed; the user settled 4: one jump try, today's drive-off
checks with NOT PROVEN, script errors split by where raised, the earliest condition heads the verdict)
-> built (24 min) -> frozen -> exam.

## Signatures
(below, in each auditor's own words)
