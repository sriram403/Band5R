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
| S1 no false alarms (10 clean runs, 5 speed x lane profiles x 2) | **9 PASS, 1 INCOMPLETE** (the drive-off flake). **S1 did not meet its 10/10 PASS target.** Counting one exam run where the hut walk failed on steps the planted bug can't touch, the working game gave **9 PASS, 1 INCOMPLETE, 1 FAIL in 11 runs**. |
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
- **It catches bugs only where a check looks** (3 / 7 on the exam). Checks aimed at the four misses may
  close these gaps; prove each against its bug and the clean game (starter checklist below).
- **A PASS means "the checked parts held", not "the ramp works".**
- **The driver and walker still flake:** the drive-off failed 3 of 20 clean landings across the research
  (about 1 in 7), plus one hut-walk FAIL in the exam runs. The method reports it as INCOMPLETE / FAIL-unresolved; it doesn't fix it.
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
- Missing work is INCOMPLETE, a broken test is TEST, a failed check is FAIL with the thing named;
  whether the game or the test caused it stays unresolved unless measured.
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

## Addendum: final-2 (2026-11-06, after the signatures; the user asked for it)
Both auditors' next step, done: **4 checks added for the 4 misses**, on `g14-final` **`669071c`**
(method version final-2; 42 required checks). Written **after** seeing the bugs, so this is not a
blind score; it proves the checks work, not that the method finds unknown bugs.
| Check (in `t_ramp`) | Clean run (k2) | With the bug |
|---|---|---|
| with a coolant leak the boiling engine is stopped before the gap | stopped, no jump | X7: **FAIL** (jumped) |
| a can of fuel and a jug of coolant by the bench (now: placed, in the bench's frame) | on the floor by the bench (y 0.00 / -0.01) | X5: **FAIL** (under the floor) |
| the refitted wheel turns as the van drives | 1481 of 1481 frames | X1: **FAIL** (0 of 1551) |
| the van steers straight after the fix | pull 0.000 | X2: **FAIL** (pull 0.055) |
Clean run: **PASS** (179 s). Not re-run: the 10-run S1 on final-2 (one clean run only).

## Signatures (both: SIGN WITH RESERVATIONS; their fixes are applied above)

### Claude auditor (`final_sign_claude.md`)
# Claude's signature on FINAL.md (2026-11-06, head `79f41da`, method `g14-final` `ceb63e3`)

**SIGN WITH RESERVATIONS.**

**Why sign:** the run now tells the truth about itself. A broken test says TEST (26 s), a stuck step says STALLED (5.5 s, process gone), missing work says INCOMPLETE, and nothing is proven by teleporting (60 setup lines declared). Today's v5 passed 7 / 11 on a working game and hung ~440 s on a minimized window; this one gave 0 false FAILs from the jump in 10 runs, never hung, and costs ~165 s with no model in the loop.

**Why the reservations:**
- **It misses more than it catches: 3 / 7 secret bugs.** All 4 misses are the same gap: nothing checks *where* a thing sits (X5), that a fix *works* (X1 wheel, X2 van pulls left), or that a promised mistake *happens* (X7 boil). A false pass is the worse error by the scoreboard's own rule, so "PASS" today means "the checked parts held", not "the ramp works".
- **S1 doesn't meet its written bar** (10 / 10, "one failure = fail"): 9 PASS + 1 INCOMPLETE, plus one clean-game FAIL from the hut walk. The method labels these honestly, but they're still flakes the user has to read.
- **Untested beyond the ramp** (S7 skipped), so the "~1 hour" port is a guess.

**Wrong or overstated in FINAL.md (exact fixes):**
1. S1 row: add "**below the 10 / 10 bar**; counting the exam's clean hut-walk run, 9 PASS of 11 clean runs, 1 INCOMPLETE, 1 FAIL".
2. "flake about 1 run in 5" -> "drive-off 3 / 20 clean landings (~1 in 7), plus one hut-walk FAIL": give counts, not a rounded rate.
3. `scoreboard.md` Final row says "**Signed method**" before anyone signed -> "Frozen and examined; signatures in `FINAL.md`".
4. Under "What it can't do", first bullet: add "so a PASS doesn't mean the ramp works; it means the checked parts held".

**The one thing to do next:** write the four missing checks from the starter checklist (rewards on the bench, wheel turns, van drives straight, a leak boils and stops the van), then plant X1, X2, X5, X7 again and confirm each now FAILs by name (~4 runs, ~12 min). The bugs are no longer secret, so this is practice, not a new exam.

### GPT auditor (`final_sign_gpt.md`)
SIGN WITH RESERVATIONS
I sign for limited use on the ramp, not as proof that the game is ready.
The method caught and named 3/7 secret bugs (X3, X4, X6); it missed 4/7.
Those misses matter: wheel movement, steering after repair, reward placement, and a jump with a boiling engine.
S1 was 9 PASS + 1 INCOMPLETE, not the required 10/10 PASS; an exam run also had a clean-game hut-walk FAIL.
It usefully stops a stuck step in 5.5 seconds, checks the process is gone, and reports a stale field as TEST in 26 seconds.
At about 165 seconds per run with no model time, that is a useful improvement.
S7 was skipped at the user's request; use on another puzzle remains untested.
FINAL.md fix: add "S1 did not meet its 10/10 PASS target" to the S1 result.
FINAL.md fix: replace "a broken game is FAIL" in the v6 draft with "a failed check is FAIL; whether the game or test caused it remains unresolved".
FINAL.md fix: replace "More checks, not more research, close that" with "Checks aimed at the four misses may close these gaps; prove each against its bug and the clean game".
Next: close those four measured ramp gaps, including a player's view of the wheel, and prove each check catches its bug without rejecting the clean game.
