# Audit of g1's result (Claude auditor, 2026-11-06, before c2's build)

Read: `trial_g1.md` (both builds and the referee's verdict), `trial_g1_spec.md` only where the
verdict cites it, `scoreboard.md` (R9-R12), `Camper.gd:1256-1282` (the parked-van freeze).

## Does the referee's verdict hold?

| Verdict claim | Evidence behind it | My ruling |
|---|---|---|
| **The clean run failed qualification** (v4: 0 / 2; v3 + v4: 1 full pass in 4 clean attempts) | v4q1 / v4q2 events: retry lip 59.0 / 58.5 km/h at x -1.98 / -2.17, one wheel on `BridgeDeck` beside the ramp. v3 q1 / n1: BLOCKED on the near-bank hut. | **Holds, on evidence.** The counts are logged runs, not opinion. Under R11 no scoring runs were owed. |
| **The freeze rule can never pass** | v4n1 `g1_freeze.tsv`: all 4 wheels moved 1.5-3.1 mm at freeze +1 / +6 ticks, at both freezes (1,464 frozen wheel-ticks). | **Holds on the measurement; "never" is one step past it.** Two freezes in one strict run is the sample. The mechanism makes it likely general: the game freezes a parked van only after 0.6 s of brake-on, < 0.25 m/s (`Camper.gd:1276-1279`), so the van is still settling by millimetres when it freezes, and the raycast wheels keep updating. An exact-equality rule against a settling body fails by construction. I'd write "can't pass as written (2 / 2 freezes measured, mechanism in the code)". |
| **The driver doesn't hold the centre line** | 2 of 7 measured retries missed at x -1.98 / -2.17 on a 5.6 m ramp, left wheels off it; 5 of 7 crossed at x -1.80 to +0.90. | **Holds, and it is test, not game, by geometry:** the left wheels are past the ramp's edge (half-width 2.8 m), so the van falls beside the ramp, which a player who keeps to the ramp doesn't do. The game code was unchanged. One weakness: the *cause* of the drift (frame pacing, 103 vs 51-63 ticks with no process frame) is a correlation in 4 runs, correctly left "cause not proven". |
| **Speed ceiling 64.2-64.5 km/h** | 3 crossings, W pressed (throttle 1.00) every row to the launch. | **Holds as a number.** The cause ("steering pulses' scrub, I think") is unmeasured and marked so. It does make S1's 61-68 spread unreachable for g1. |
| **v3's sweep false alarm** | q1, n1 shots and velocities. | Holds for v3; **superseded in v4** (0 hits in 4,112 ticks, terrain included). The verdict lists it under S1 as history; it should not count twice. |
| **S5 "read from the spec, not independently audited"** | none yet | Honest. Not a pass; open. |

**Overall: the verdict holds.** Every failing claim in it rests on a logged run and a number. The
only overreach is one word ("never" for the freeze rule; measured 2 / 2) and it doesn't change the
outcome: even with a tolerance, the clean run still misses 2 / 2 in v4 on the driver's line.

**What I'd attack if I were GPT defending g1:** the verdict charges the v4 misses to the controller,
but the v4 change didn't touch the controller and v3 crossed 3 / 3. So v4's 0 / 2 vs v3's 3 / 3 on the
same controller is either chance (2 of 7 overall) or something v4 added per tick (the hull sweep's
cost changing frame pacing, which the report shows does vary: 51-103 ticks without a process frame).
Not measured. **It doesn't rescue S1** (any 2 / 7 miss rate fails 10 / 10), but it is a cheap thing
for GPT to check before it decides g1's future.

## What g1's result changes for c2

1. **c2 cannot ride on g1's driver** (top4's first choice). It failed its own controls (R1 forbids
   inheriting an untested green claim). c2 takes top4's fallback: today's `t_ramp` as the reach path.
2. **The reach path is unreliable either way.** `t_ramp` reaches the end 7 / 11 (c1's side data); g1's
   driver crossed 5 / 7 retries. So c2 must never depend on the driver landing: every rule has a
   *trigger* (the state it needs) and reports **NOT REACHED** when the run never got there (R12). A
   miss or a drive-off is printed as "driver: ..." and is never a c2 finding.
3. **A fact c2 uses:** the game freezes a parked van (brake on, slow, 0.6 s). So the
   "moves after the reset" rule must read the brake and ignore the first settling: drift is measured
   from the reset's own placement, and a millimetre settle is far under any threshold (clean 0.04 m).
4. **A fact c2 avoids:** exact-equality on physics state fails on a settling body (g1's freeze rule).
   Every c2 rule has a measured margin and a steady-window (the state must hold, not flicker).
5. **g1's sweep with terrain included gave 0 false hits in 4,112 ticks.** Not needed by c2, noted.

## Decision

**Continue c2 as agreed**, on top4's fallback branch (ride on today's `t_ramp`, plus short declared
setups where `t_ramp` never goes, e.g. a swimmer for P3), with R12's NOT REACHED built in from the
start. Reason: g1's failure is a *driver* failure, and c2 claims nothing about driving (R5: "that the
state is right where each rule looks"). It removes c2's preferred reach path, not c2's question:
do state rules with measured margins catch and name the practice bugs with no false alarm?
