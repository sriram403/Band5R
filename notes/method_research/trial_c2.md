# Trial c2: state checks (Claude auditor builds and qualifies)

Branch `g13-trial-c2` from `g12` `d80e0cd`. Built 2026-11-06, 11:22-11:55 (clock from `date`).
Definition: `top4.md` row c2, with my round-2 concessions (`audit_r2_claude.md`, "C3, the
state checks") and ruling R12. My answer to g1's result: `audit_g1_claude.md` (continue c2 as
agreed, on top4's fallback path: ride on today's `t_ramp`).

## Verdict up front
- **Qualified.** Clean full runs on the working game with no rule firing: **q5 and q6**
  (`ramp,c2_more`; rig healthy; q5 reached 7 / 7 rules). Clean `c2_more` alone: q3, 7 / 7 reached, none fired.
- **Practice set on `c2_more`: 7 / 7 caught, 7 / 7 named at the object, each by its own rule**,
  seen twice each (P1-P7 at 11:33-11:39, and again on the final code at 11:46-11:51; P3 on the final code at 11:45).
  No stray finding, except the agreed one: under P3 the drift rule also fires and says
  "brake ON, cause not named" (top4 D4's pass condition).
- **One rule needed all three fix rounds:** G2 (the swimmer) false-alarmed on the clean game in
  q1, q2 and q4, a different way each time (the game's own climb-out, see "Qualification").
  Round 3 held in q5 and q6. It is the rule I trust least (it reads a private game field).
- **A question for the user, not a finding:** on the clean game, P2 leaving the river walks in
  swim mode up to 16.4 m over dry ground and the road to the bank point by the far hut
  (picture in q4). That is how `PlayerRig._swim` works; whether it looks right is the user's call.
- Built in 33 minutes of the 60.

## What was built (test code only; the game is untouched)
| File | Lines | What |
|---|---|---|
| `FindingNaresh/scripts/dev/C2Watch.gd` | 448 (new) | The observer. A node under PlayTest; reads the game's state every physics tick while a watched scenario (`ramp`, `c2_more`) runs, moves nothing. Seven rules, each with a trigger; a rule whose trigger never held is NOT REACHED (R12). A finding saves one picture from an observer camera (a SubViewport no player owns, R2) to `FindingNaresh/_shots/c2_<rule>.png`. Writes `appdata/playtest/runs/c2.txt` (every LOOK, FIRE, NOTREACHED line) and `c2_verdict.txt` (rewritten at each watched scenario's end). It finds the scenario from c1's `RigBeat.scen`. |
| `FindingNaresh/scripts/dev/PlayTest.gd` | +74 / -1 | `c2 = C2Watch.ensure(...)` in `_ready`; `c2.sync()` after each scenario's end (the run may quit before the next frame); `"c2_more"` added to c1's `RIG_NEEDS` (so c1's needs check and pause guard cover it); `t_c2_more` (below). `t_ramp` is unchanged. |
| `tools/c2_run.sh` | 29 (new) | `tools/rig_run.sh <plan>` (c1, unchanged), then prints the C2 verdict and its FIRE lines. Exit 0 = rig healthy and no c2 rule fired; 1 = a rule fired; 2 = rig not healthy (c2 not counted). |

c1's 7 files reused by file (R8): `git checkout a6a412f -- <the 7 files from git diff g12 a6a412f --stat -- FindingNaresh tools>`,
committed as **`7c4b661` "Reuse c1 code from a6a412f (R8)"** (c1's code commits `920110d`, `3b96807`,
`a106f90`, `57b8afd`). c1's code is unchanged except the one `RIG_NEEDS` data line.

**`t_c2_more`: c2's own short stretches** for what `t_ramp` never reaches, each with a declared setup:
| Stretch | Declared setup (code, not proven) | Proven part |
|---|---|---|
| D3 the door | `ramp_start`; P2 put inside the hut opens the door with the game's own `_open_door`; P1 put 2 m outside the door, looking in | **W alone** carries P1 across the door line within 4 s |
| G1 / G2 a miss with someone in the river | `ramp_start`; P2 put in the river 5 m off the gap's middle | a real-input slow try (AutoDriver, keys only) misses; **the game's own reset**; then 6 s hands off |
| G3 / G4 the landed van | the game's own F1 jump to "wheel" (`dev_menu.run("jump", ...)`: van over, wheel snapped, brake on); P1 seated (the HUD shows only when seated) | nothing by play: the rules read the state that jump builds (R7) |

## How to run (from `MPG_dev`)
```
tools/c2_run.sh                 # ramp,c2_more: ~2 min 45 s wall (161 s game in q5) 
tools/c2_run.sh c2_more         # c2's own stretches only: ~55 s wall (48 s game)
```
With a practice patch (one at a time, never while a game runs, never committed):
```
python -I notes/method_research/practice/practice_bugs.py P4
tools/c2_run.sh c2_more         # or tools/c2_run.sh for ramp,c2_more
python -I notes/method_research/practice/practice_bugs.py restore
```
Live progress: c1's `[rig-watch]` line every 5 s; c2's lines are `[c2] LOOK / FIRE` in
`appdata/playtest/runs/seg_1.log`. Output, three verdicts printed apart:
```
==== RIG: healthy ====                      (c1: alive, in control, complete)
==== INNER CHECKS: PASS | FAIL (n) ====     (t_ramp's own checks: the driver. NOT c2's verdict)
==== C2 STATE CHECKS: no rule fired | n rule(s) FIRED (after <scenario>) ====
  reached k / 7 rules; a rule not reached is neither a pass nor a fail (R12)
  generic rules:  G1..G4  looked n, values lo..hi: clean | FIRED: <finding> | NOT REACHED
  declared rules: D1..D3  ...
```
The rules never read which patch is on: `C2Watch.gd` reads only game nodes (`grep -n "practice\|patch\|getenv\|OS\." C2Watch.gd` finds nothing that reads one).

## The seven rules, with measured clean-vs-bug margins
Clean numbers: q3 (`c2_more`), q5 and q6 (`ramp,c2_more`). Bug numbers: my patch runs on
`c2_more` (each patch run twice, identical numbers: the stretch is deterministic).

| Rule | Kind | Fires when (trigger -> rule) | Clean | Bug | Limit | Margin |
|---|---|---|---|---|---|---|
| **G1** nothing moves after the game's reset | generic | trigger: the van jumps > 5 m while the ramp is `failing` (the reset). Window: until the first W/A/S/D, the brake's release, or 5 s. Fires: horizontal drift > limit. Then **reads the brake**: off -> "the reset left it off"; on -> "cause not named" | 0.039 m in 1.88 s (`t_ramp`: the window ends at the test's brake release); 0.045 m in 5.02 s (`c2_more`) | **P1 2.71 m in 5.0 s, brake OFF** -> named; P3 0.58 m, brake ON -> "cause not named" | 0.30 m | 0.255 m clean side (6.7x); P3 0.28 m over |
| **G2** nobody swims on dry ground past their bank | generic | trigger: a player in swim mode. Fires: ground (a ray) > 0.3 m above the water AND the player is > 5 m farther from the river than the bank point the game is taking them to (`_swim_to`), for 1 s | max -0.67 m (1,850 looks, both scenarios, incl. the far-bank climb-out) | **P3: "far"** (the swimmer beside the van at the run-up; no river near) | 5 m | 5.67 m clean side |
| **G3** wheels and hub sit on the ground | generic | trigger: the van frozen (parked) 0.5 s. Fires: a visible tyre's or the bare hub's bottom (centre minus radius) below the surface under it (a ray, van excluded) | worst tyre -0.069 m, bare hub -0.012 / -0.013 m | **P6 bare hub -0.252 m** | -0.12 m | 0.051 m clean (tyres; the tightest), 0.13 m bug |
| **G4** the HUD matches the physical wheel | generic | trigger: a HUD showing a warning. Fires (0.5 s): "PUNCTURE" while the front-left wheel is physically gone (its mesh hidden, or the loose wheel > 1.5 m from the hub), or "ON THE HUB" while it is physically on | 0 mismatches (666 looks in q5) | **P7 "PUNCTURE - steer pulls left" with the wheel gone** | 0.5 s | on / off |
| **D1** the crate's spot is clear | declared | read once per scenario: a 1.0 x 0.7 x 1.2 m box outside the window's wall, under the window (from the game's own `_window`); fixed solids (not terrain, not carried things) in it | 0 solids; 2 rubble pieces within 1 m more | **P4: 2 rubble pieces in the spot**, named with positions | any | under 1 m (rubble sits within 1 m of the box on the clean game) |
| **D2** the wreck shows above the water | declared | read once: the wreck's rendered top vs `water_y` | top +1.905 m (middle +0.41) | **P5 top -0.39 m** (middle -1.88) | top < water | 1.9 m clean, 0.39 m bug |
| **D3** P1 walks in by the door on W | declared | the door walk above. Fires: not across the line in 4 s | crossed (hut z -1.39 reached) | **P2 stuck 0.28 m short of the wall line** | 4 s | 0.69 m along the walk |

Counted apart (top4): **generic G1-G4** (written as "what should always hold"), **declared
D1-D3** (written for this puzzle's places). Honesty note, as in round 2: I wrote all seven after
reading P1-P7's descriptions in the scoreboard; I did not read `practice_bugs.py` or any patch.
Only the final exam's secret bugs can test the generic half.

## What c2 claims, and what it reports NOT PROVEN / NOT REACHED
- **Claims (R5, R7):** where a rule looked, the game's state was right (or wrong, named): the
  van after the game's reset, swimmers, a parked van's wheels and hub, the HUD's wheel line, the
  crate's spot, the wreck's height; and one proven-by-play fact: P1 walks in through the open door
  on W.
- **NOT REACHED:** any rule whose trigger never held in that run, printed per rule with its look
  count. With `c2_more` in the plan, every rule is reached in every run (7 / 7 in q5, q6, q3).
  In `t_ramp` alone, G3 / G4 need the driver to land (7 / 11 measured by the referee), and
  G2's swimmer only exists after a landing.
- **NOT PROVEN:** that any stretch completes (the driver's result is printed under INNER CHECKS,
  never as c2's verdict); a landing by play for G3 / G4 in `c2_more` (the F1 jump builds it);
  that a player can see the wreck or the hub (R2: the observer pictures are evidence, not a
  player's view); that the crate can be placed and the leg-up done; the rest of the hut route;
  secret bugs outside the seven rules.

## Qualification (every run watched: seg log and rig line every 5 s; tasklist before each)
| Run | Clock | Plan | Rig | Inner (driver) | C2 | Notes |
|---|---|---|---|---|---|---|
| q1 | 11:28 | `c2_more` | healthy, 1 / 1 | PASS | **G2 false alarm** | My rule: "swim mode with dry ground under you". `Landscape.ground` said +3.3 m mid-river (it doesn't carve the channel), and the picture showed P2 on the sand, still swimming: `PlayerRig._swim` keeps swim mode up the bank by design. Fix 1: a ray, and only outside the river's channel. |
| q2 | 11:30 | `ramp,c2_more` | healthy, 2 / 2 | FAIL: flat out missed at 66.5 km/h (driver) | **G2 false alarm** | the near-bank point is 5.3 m out of the channel. Fix 2: limit 15 m. `t_ramp` returned at the miss: G3 / G4 NOT REACHED in `ramp` (R12 as designed). |
| q3 | 11:32 | `c2_more` (+ the F1 landed stretch) | healthy | PASS | **none fired, 7 / 7 reached** | tyres after the F1 jump at -0.059 / -0.067 m: too near my -0.08 limit, so G3's limit -> -0.12 from these numbers (before any patch run). |
| P1-P7 | 11:33-11:39 | `c2_more`, one patch each | healthy x7 | PASS x7 | **7 / 7 caught, each by its own rule** | numbers in the margins table; P3 also fires G1 "brake ON, cause not named". Restored after each (git status clean of patches). |
| q4 | 11:39 | `ramp,c2_more` | healthy | landed | **G2 false alarm** | P2 swimming out on the far side to a bank point by the hut, 16.4 m out and 11 m above the water, in swim mode on the road (picture). Fix 3 (the last allowed): compare with the swimmer's own bank point. |
| q5 | 11:42 | `ramp,c2_more` | **healthy, 2 / 2, 161 s** | **PASS** (landed 66.3 km/h, hut, drive-off) | **none fired, 7 / 7 reached** | G2 clean max -0.67 m over 1,850 looks |
| P3 | 11:45 | `c2_more` + P3 | healthy | PASS | **G2 fires ("far"), G1 "brake ON, cause not named"** | on the final G2 |
| P1, P2, P4-P7 | 11:46-11:51 | `c2_more`, final code | healthy x6 | PASS x6 | **each fires exactly its own rule** (G1, D3, D1, D2, G3, G4) | identical numbers to the first pass |
| q6 | 11:51 | `ramp,c2_more` | **healthy, 2 / 2, 160 s** | **PASS** (landed 66.3 km/h, hut, drive-off) | **none fired, 7 / 7 reached** | G2 max -0.67 m (1,851 looks); G3 worst tyre -0.068, hub -0.013; G4 664 looks. Same landing as q5 (66.29 km/h): `t_ramp` repeated itself here; S1 variation is the referee's. |

No SCRIPT ERROR in any run's segment log. Patch runs' logs: `appdata/playtest/runs/p_P*.out`,
`p_P*.c2.txt`, `p_P*.seg.log`; clean: `q*_c2.out`, `q4/q5/q6.c2.txt` (not in git). Pictures:
`FindingNaresh/_shots/c2_<rule>.png` (the last finding of each rule).

## Departures from top4's c2, and why
1. **Rides on `t_ramp`, not g1's driver** (g1 failed its own controls; R1). top4's fallback.
2. **`c2_more`, declared short stretches**, so every rule is reached in every run without
   depending on the driver (R12). The G3 / G4 one uses the game's own F1 jump: set state, so it
   proves the state that jump builds, not a landing (R7). If P6 / P7 lived only in the real
   landing code, `c2_more` would miss them; `t_ramp`'s landing covers that path when it lands.
3. **G2 changed meaning twice** (q1, q2, q4). It now reads `PlayerRig._swim_to`, a private field.
4. **Every physics tick, not 5 Hz.** The frame time c2 adds was **not logged** (I said in round 2
   it would be). Gap.
5. **Pictures from an observer SubViewport** (R2), aimed at the object from a fixed offset: no
   player's camera moves.

## Known gaps
1. **G2 is fragile:** three rounds, and it depends on a private field (`_swim_to`) and on
   `river_distance` returning a huge value far from any river. A rename makes the observer
   error, and the private names it reads (`_swim_to`, `_wheel_meshes`, `_bare_hub`, `_warn`,
   `_window`) are not in c1's declared needs, so a rename shows as a SCRIPT ERROR, not as a TEST
   verdict.
2. **`c2_more` is deterministic** (identical numbers run to run). S1's variation (speed, lane,
   where the van lands) reaches only `t_ramp`'s part. G3's tyre margin (0.051 m) is the one most
   likely to meet a new landing spot.
3. **G1 in `t_ramp`:** its window there is only 1.88 s (the test releases the brake), so P1's
   drift there would be about 0.38 m, I think (from 2.71 m in 5 s, accelerating): just over the
   0.30 limit. Not run. `c2_more`'s 5 s window is where P1 is reliably caught.
4. **D1's clean margin is under 1 m:** rubble pieces sit within 1 m of the crate box.
5. Patches were run on `c2_more` only, not on `t_ramp`. A rule that fires in `c2_more` under a
   patch could also fire in `t_ramp`; both are the same bug, but the verdict lists it once per rule.
6. The observer's own cost per tick wasn't measured (departure 4).
7. c1's known limits travel with it (R8).
8. **G3's picture is useless** (dark: the observer camera, 3 m out from the hub and 0.6 m up,
   sat inside the ground or under the far bank). D1's, G1's and G2's pictures show their object.
   The finding's numbers carry it; the picture offset needs a fix (not done: found while the
   last clean run was loading this file).


## For the referee to decide
1. **Coverage of P6 / P7 through the F1 jump.** In `c2_more`, G3 / G4 read the state the game's
   own F1 jump to "wheel" builds (`snap_wheel`, brake on), not a landing by play. Under R7 c2
   claims only that state. If the referee wants P6 / P7 caught on a played landing only, they
   count only when `t_ramp` lands (7 / 11 measured), with R12's one rerun.
2. **S1's variation.** `c2_more` repeats itself exactly; `t_ramp` has no speed or lane knob
   (its flat-out try asks 80 km/h). Varying where the van lands means changing the driver,
   which c2 doesn't own.
3. **The swimmer on the road** (q4's picture): a clean-game behaviour, not a c2 finding.
   Whether it goes to the user is the referee's call.

## Predicted scores (all "I think")
| Check | Prediction |
|---|---|
| S1 | 10 / 10 with no rule firing, every rule reached in every run (`c2_more`), so no "S1 thin". Risk: G3's tyres (0.051 m) at a landing spot nobody measured, and G2 on a swim path nobody measured. |
| S2 | **7 / 7 caught, 7 / 7 named**, each by its own rule (seen twice each on `c2_more`). P3 named by G2; the G1 line under P3 names no cause. |
| S3 | 3 / 3 via c1 (R1). c2 adds no TEST verdicts. |
| S4 | 4 / 4 via c1. c2's own part: a rule not reached says NOT REACHED, never a pass. |
| S5 | Pass, with the declared setups above. Proven by play: the door walk (W only) and the reset after a keys-only miss; G3 / G4 in `c2_more` claim only the F1-built state. |
| S6 | ~2 min 45 s per full run (161 s game), ~55 s for `c2_more` alone; no model tokens or model time per run; reading: 3 verdict lines + one line per finding. Build 33 min. |

## Minutes (clock)
| Part | Clock | Minutes |
|---|---|---|
| g1 audit (before the clock, per the brief) | 11:20-11:22 | ~2 |
| Branch, R8 reuse, reading the game's state code | 11:22-11:25 | ~3 |
| Observer, scenario, wrapper, compile | 11:25-11:28 | ~3 |
| Qualification and the patch runs, fixes between | 11:28-11:53 | 25 |
| Report, notes, commit | 11:53-11:55 | 2 |
| **Total** | **11:22-11:55** | **33 of 60** |

## Referee's scoring of c2 (2026-11-06, 11:57-13:20)

Scored head: `g13-trial-c2` `04c3102`. Every run watched (log growth every 5 s, a 60 s silence
flag, a 500 s kill; an outside watcher for a minimized test window from 12:20), one game at a
time. Plans and times differ from the builder's: practice patches on the full `ramp,c2_more`
(the builder used `c2_more` only), so the played landing was exercised too.
**Code read:** `C2Watch.gd` reads no patch, env flag, command line or injection (grep: only its
own output files and game nodes). Rulings asked for by the builder: R13 (catches via a declared
setup count when the bug's code is on that path: checked, `snap_wheel` and the HUD are shared by
the F1 jump and the landing) and R14 (S1 spread when the method doesn't own the driver).

| Check | Runs | Result |
|---|---|---|
| **S1** no false alarms | 11 `ramp,c2_more`; 10 counted | **10 / 10: no rule fired, 7 / 7 rules reached every run.** S1_1 not counted: the test window was minimized, Godot stopped drawing, `t_ramp` waited in `shot()` for ~440 s until the referee's kill (an environment stall, not a c2 verdict). S1_6 counted with a note (minimized ~75 s during the setup shots; restored by the referee, no focus taken). **Driver spread (R14):** flat-out lip 65.9-67.0 km/h, 8 landed, 2 missed (66.4, 66.5 km/h); c2 said nothing about the misses (R12, right). G3 / G4 looked on the **played** landing in 8 / 10. Tightest: G3 worst tyre -0.072 m vs the -0.12 limit (0.048 m). G2's worst -0.666 m comes from `c2_more`'s fixed stretch every run: the played swims never came near the limit. The 61-68 km/h spread: **not reached** (R14 limit). |
| **S2** finds real bugs | 7 patches on `ramp,c2_more`, + 2 P6 reruns | **6 / 7 caught and named every time; P6 caught 1 / 3.** P1: G1 "moved 0.42 m in 1.9 s, handbrake OFF after the reset" **inside `t_ramp`'s 1.9 s window** (the builder had only predicted it). P2: D3 "stuck 0.28 m short of the door line". P3: G2 names the swimmer; G1 fires with "brake ON, cause not named" (no wrong blame on P1: top4's dispute settled). P4: D1 names the rubble in the crate's spot. P5: D2 "the wreck's top 0.39 m under the water". P7: G4 on the **played** landing. **P6: the hub was off its axle in every run, but it hangs on the spinning wheel, so the offset turns with it: sunk -0.28 m in 1 of 5 looks (G3 fired), floating +0.19 to +0.29 m in 4 of 5 (G3 silent: it checks only "below the ground").** A visible bug passed 2 runs of 3. |
| **S3** blames the right thing | c1's T1-T3 via c1 (R1); 1 c2-specific case | **c1's 3 / 3 carry over. c2's own case fails:** a private game field c2 reads, renamed (`_swim_to` -> `_swim_goal` in `PlayerRig.gd`: a game refactor making the test stale; reverted after). Verdict: rig healthy, **"no rule fired"**, exit 0, **G2 "NOT REACHED"** though a swimmer was there, **733 SCRIPT ERRORs not in the verdict**. A broken rule hides in R12's neutral NOT REACHED: a false pass, not "test problem". **0 / 1.** |
| **S4** can't pass by doing nothing | N1 frozen at 12 s, N3 P2 removed at 8 s (`c2_more`) | **2 / 2, plus c1's 4 / 4 via R1.** N1: "no heartbeat for 20 s", C2 "no verdict". N3: "P2 missing" at once, C2 "no verdict"; meanwhile c2's observer threw a SCRIPT ERROR every tick (62 KB of errors in 5 s). (A first N1 at 30 s fired after `c2_more` had ended: the referee's timing slip, not counted.) **New defect, c1's rig (reused):** a test step stuck on an await while the game runs (the minimized window: `shot()` waiting for a draw) is not noticed: the rig said "healthy" for ~440 s and ~75 s; only the referee's 500 s kill stopped S1_1, and the rig then said `ramp` was "asked but never ran" though it had started. Not one of N1-N4, so not scored against the gate, but it is the brief's "silent wait" and goes to the final method's must-fix list. |
| **S5** real path | code read | **Pass.** Declared setups: `place_player`, the game's `_open_door`, P1's camera aimed at the door before the walk, P2 put in the river, the F1 jump. Proven by play: the W walk through the door; the keys-only slow try and the game's own reset. G3 / G4 on the F1 state count under R13; P7 was also caught on the played landing. |
| **S6** cost | measured | Build 33 min. Full run `ramp,c2_more` 161-199 s wall (78-84 s when `t_ramp` misses and returns); `c2_more` alone ~55 s. No model tokens per run. Reading: 3 verdict lines + one per finding. Scoring: 24 runs, ~80 min wall. |

**Verdict: c2 passes S1 and the gates (S4, S5) on their listed cases; S2 6 / 7 (P6 a partial
false pass); S3 has one false pass in c2's own failure mode** (a stale field read turns into a
silent NOT REACHED). Three things the next trials and the final method must answer:
1. A rule that errors must say TEST, never NOT REACHED.
2. A stuck test step with the game alive must be reported within 60 s (c1's rig doesn't).
3. A shape rule written as "below the ground" misses the same bug pointing the other way:
   rules should check "where it belongs", not one direction.
