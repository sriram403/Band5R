# Stage 4, round 1: the final method (Claude auditor's proposal)

2026-11-06. Written on `g12` `c85d4a4` without seeing GPT's proposal. Read-only: no code, no
runs. Evidence is cited as trial + SHA + file, or the scoreboard / trial report section.
Anything not measured is marked "I think".

Working name: **the judged run** (v7 of `notes/TESTING_METHOD.md` if adopted).

---

## 1. The method in one paragraph

A script plays the puzzle the way a player would (today's `t_ramp` and c2's short declared
stretches, with the driver's speed and lane varied on purpose and a miss retried the way a
player retries). Three observers, none of them a model, watch at the same time. **(1) Health**
(c1's rig + g2's deadlines): is the game alive, unpaused, both players there, every asked
scenario started and finished, every test step closed before its deadline, every input
delivered? **(2) Progress**: did every check the scenario owns actually run (a fixed list of
check IDs from a clean run), and did each driver-owned step get there? **(3) State rules**
(c2's rules, repaired): is the game's own state where it belongs, read through validated
fields, so a broken read is a TEST error and never a silent NOT REACHED? A small script
combines the three into **one headline** (PASS / FAIL / INCOMPLETE / TEST / NOT HEALTHY) with
the named thing, its numbers and one picture. **A PASS needs all three, and every rule
looked at least once with no read error.** No model reads anything per run; a person or model
reads only a failure, once, after the run. g2's full recorder is off by default and turned on
only to diagnose a physics failure.

### The parts and where each comes from

| # | Part | Source | Why it's in (scoreboard evidence) |
|---|---|---|---|
| A | Heartbeat, world clock, pause, players present, asked vs ran, plan check (after `save`), declared needs, input receipts | c1, `a6a412f`: `dev/RigBeat.gd`, `dev/RigInject.gd`, `tools/rig/rig_watch.py`, `tools/rig_run.sh`, PlayTest hooks | S1 10 / 10 rig-healthy; S3 3 / 3; S4 4 / 4, all <= 27 s (`trial_c1.md`, referee's scoring). Fit for reuse: R8. |
| B | Step deadlines published by the game (OPEN / CLOSE), judged on the host's clock, then kill and **check the process is gone** | g2, `afb9e9b`: `dev/G2Rec.gd` `open()` / `close()` (lines 175-181), `PlayTest.gd` `shot()` (lines 277-289), `tools/g2/g2_watch.py` `kill()` + deadline loop (lines 51-56, 117-121) | N5 caught in **5.02 s** on a real minimized window where c1 said "healthy" for ~440 s (`trial_g2.md` scoring; `trial_c2.md` S4). Kill verified gone in 0.7 s (K1, K2). |
| C | Validated reads: every game field a rule reads is checked by name and type at a preflight and on every read; a failure is an event, the rule counts an error | g2, `afb9e9b`: `G2Rec.gd` `rd()`, `_stale()`, `preflight()` (lines 113-146) | T4 1 / 1 "TEST: observation invalid" before any drive, where c2 gave a false pass on the same break (`trial_g2.md` S3 vs `trial_c2.md` S3). |
| D | SCRIPT ERROR veto | g2, `afb9e9b`: `g2_watch.py` lines 133-142, 166 | c2's 733 hidden SCRIPT ERRORs (`trial_c2.md` S3). **Changed:** split by where the error is (see §2). |
| E | Seven state rules with measured clean-vs-bug margins, an observer camera picture per finding | c2, `04c3102`: `dev/C2Watch.gd`, `t_c2_more` in `PlayTest.gd` | S1 10 / 10 no rule fired, 7 / 7 reached every run; S2 6 / 7 caught and named (`trial_c2.md` scoring). **Changed:** reads go through C; G3 becomes two-sided (§4). |
| F | Short declared stretches so every rule is reached every run, whatever the driver does | c2, `04c3102`: `t_c2_more` | Without it, G3 / G4 depend on the landing (8 / 10 in c2's S1). R12. |
| G | **Check ledger** (new): every `check()` gets a stable ID; a clean run's list of IDs is frozen; a run that ends with IDs missing is INCOMPLETE "stopped after <last check>" | new (generalises g2's K3 "missing checkpoint", `g2_watch.py` line 179) | `t_ramp` returns early after a miss (`PlayTest.gd` `t_ramp`, `if go["what"] != "landed": return`) and c1 / c2 printed that only as "INNER FAIL". g2's K3 showed c1 alone said "healthy, PASS" on an early return. |
| H | **The driver, owned and varied** (new): `ramp_try(target, lane)` already takes both (`PlayTest.gd:11579`, `ad.lane = off`); a run picks them from `--fn-vary=k`, logged; the flat-out try is retried up to 3 times, each try reported | `t_ramp` (g12) + new | R14: the final method must meet the 61-68 km/h spread with its own driver. c2 / g2 reached only 65.9-67.0. |
| I | One headline, one command, exit codes | new (`tools/fn_run.sh`, `tools/fn/fn_verdict.py`), from `tools/c2_run.sh` (`04c3102`) | The user reads one line (S6). Today three verdicts are printed side by side and a reader must combine them (`trial_c2.md` "How to run"). |
| — | g2's recorder (`G2Rec.gd` rows), arm tables, causal pairs | g2 `afb9e9b` | **Not in the default run** (§2 last row). |
| — | g1's driver and freeze rule | g1 `a367de3` | **Dropped**: failed qualification (2 / 7 retries off the ramp's edge; freeze rule can't hold, `trial_g1.md`). Its surviving idea, signed progress along the road, is used for the drive-off check (H). |

---

## 2. What each measured hole becomes

| Hole (measured) | Evidence | What it becomes |
|---|---|---|
| **c2's stale field -> silent NOT REACHED** | `_swim_to` renamed: rig healthy, "no rule fired", exit 0, G2 NOT REACHED, 733 SCRIPT ERRORs not in the verdict (`trial_c2.md` S3) | Two barriers, either one enough. (1) Every private field a rule reads (`_swim_to`, `_wheel_meshes`, `_bare_hub`, `_warn`, `_window`, plus any new) goes through part C: preflight at the watched scenario's start, then every read; a miss -> `ERROR <rule> <field>` -> headline **TEST: observation invalid**. (2) Each rule keeps three counts: looked, errors, fired. **PASS needs looked >= 1 and errors = 0 for every rule declared for the plan.** A rule with looked = 0 makes the run **INCOMPLETE** (coverage), never PASS. NOT REACHED survives only as a per-rule line inside a non-PASS report. |
| **The stuck step c1 didn't see (N5)** | `shot()` waited on `frame_post_draw` for ~440 s while c1 said healthy (`trial_c2.md` S4); g2 caught it in 5.02 s | Part B on every await that can wait for something other than physics: `shot()` (5 s), `ramp_try` (46 s, as g2 measured it holds drive + reset), `until(..., t)` (t + 2 s), `place_player` (5 s), and an **episode deadline** per watched scenario (clean max x 1.5, measured by the builder; `ramp` ~113 s -> about 170 s). Past a deadline: kill, check gone, headline **STALLED at <step>**, within 60 s. A `physics_frame` await can't stall while physics runs (the heartbeat covers physics stopping), so the other ~2,900 awaits in PlayTest don't each need one (I think; the count is `grep -c "await "` = 2,907, most are `physics_frame`). |
| **P6: a one-direction rule** | the hub off its axle sank in 1 of 5 looks, floated +0.19 to +0.29 m in 4 (`trial_c2.md` S2) | A general rule for every shape or position rule: **"where it belongs", checked as a band, both sides.** G3 becomes two checks: (a) **mount**: each visible tyre and the bare hub sit at their wheel's centre (distance from `Camper._wheels[i]` position), any direction; (b) **ground band**: a parked van's tyre / hub bottom between -0.12 m and an upper limit measured clean. Every other rule gets its opposite direction written down: added where a clean number is in the records, otherwise listed NOT PROVEN (§4). |
| **c1's failed kill** | T2: caught at ~22 s, but the game played on ~115 s (`trial_c1.md` scoring). c1's `kill()` runs `taskkill /F /T` and ignores the result (`a6a412f:tools/rig/rig_watch.py:67-69`) | Use g2's `kill()` (logs the return code) plus a check with `tasklist` for up to 5 s, one retry, then **"KILL FAILED: pid n still running"** as its own line and exit code. The wrapper refuses to start a new run while that pid lives (g2's `g2_run.sh` already checks `tasklist`). |
| **c1's "never ran" mislabel** | a stuck `ramp` was reported "asked but never ran" though it had started (`trial_c2.md` S4, `trial_g2.md` S4) | Count three things per scenario from c1's own `start` / `end` events: asked, started, finished. Started and not finished -> "**stopped in <scenario> at <open step>**" (from part B's last OPEN), never "never ran". |
| **The driver's misses (R12 / R14): who owns reaching a state** | `t_ramp` reaches the end 7 / 11 (c1 side data); misses at 66.4-66.6 km/h with the same numbers as landings, cause INCONCLUSIVE (`trial_g2.md` (a)); drive-off failed 2 / 11 | **The method owns its driver.** Each step is marked driver-owned (the approach, the flat-out jump, the drive-off) or not. (1) **Jump:** up to 3 flat-out tries, the way a player would retry; every try is printed (lip km/h, lane, landed / missed); each miss also exercises the game's own reset, which G1 watches. 3 misses -> **INCOMPLETE: the jump did not land in 3 tries at <speeds>** (never PASS, never "game problem"). (2) **Drive-off:** the check becomes signed progress along the road at the end (g1's idea, `top4.md` g1), not "closest ever" (the false pass in `ROUGH_NOTES.md` 2026-11-05). (3) A run that ends INCOMPLETE **only** at a driver-owned step is rerun once automatically; the report prints both ("PASS on rerun; run 1 stopped at drive-off"). Never silent. (4) Every rule is reached through part F whatever the driver does, so no rule depends on the driver. |
| **g2 is not a detector** (P1, P3 passed as INSTRUMENT OK, `trial_g2.md` S2) | its only automatic verdict is about itself | Its **mechanisms** move into the default run (B, C, D, K3-style completeness = G). Its **recorder** does not: default off. It runs only when a run's headline is FAIL / INCOMPLETE at a physics step (the jump, the reset, the landing) and someone wants the cause: `FN_RECORD=1 tools/fn_run.sh <plan>`. **Who reads it:** the model, once, after the run, offline, with g2's sheet scripts; that is a diagnosis, never a verdict, and its cost is stated when it's asked for. Reason: on the scoreboard it caught 0 / 2 by verdict; 18 MB per arm (`trial_g2.md`); its value is causes, which the exam doesn't score. |

---

## 3. Verdict words and who decides

**The scripts decide, never a model.** `tools/fn/fn_verdict.py` reads c1's `rig.txt`, the
events file (B, C, G) and c2's `c2.txt`, and prints one headline by this precedence (the
first that holds wins; everything else is still listed under it):

| Headline | When | What it means for blame | Exit |
|---|---|---|---|
| **NOT HEALTHY: <what>** | c1: no heartbeat 20 s, physics stopped 10 s, paused 5 s (not a pad loss), a player missing, a scenario asked and not started | The run proved nothing; game results below it are "not counted" | 4 |
| **TEST: <what>** | input not delivered to its device; plan broken (after `save`, unknown name); declared expression fails; a validated read failed (ERROR); a SCRIPT ERROR whose stack is in `scripts/dev/`; pad lost (c1's T1 rule); KILL FAILED | The test is wrong; game results not counted | 3 |
| **STALLED at <step>** | a published step deadline passed (part B) | Owner **not measured** (a `shot()` stall is the window not drawing; another await may be a game signal never firing). Reported within the deadline + 1 s | 3 |
| **FAIL: <named thing>** | a state rule fired (**owner: game, measured**: the value, the limit, the picture), or a SCRIPT ERROR in game code (**owner: game**), or a scenario check failed (**owner: not measured**: "game, unless the setup before it is wrong") | The named thing is the first rule / check / error, with its numbers | 1 |
| **INCOMPLETE: <what's missing>** | checks missing from the frozen ID list ("stopped after <last>"), a rule never looked, a driver-owned step not reached after its retries / rerun | Owner not measured; **never a pass** | 2 |
| **PASS** | none of the above; every asked scenario finished; every check ID ran; every rule looked >= 1 with 0 errors; the driver's tries listed | | 0 |

Under the headline, always: asked / started / finished; per rule `looked n, errors e, value
range, FIRED / ok`; the driver line (speed, lane, tries); seconds; the picture paths. R15's
three words map exactly: ERROR -> TEST, INCOMPLETE -> INCOMPLETE, NOT REACHED -> a per-rule
line inside a non-PASS run.

**Model reading per run: none.** The old trap (`TESTING_METHOD.md` v3: the model's think time
between commands became the biggest cost) is avoided because no model chooses an input or
judges a step while the game runs. On a non-PASS, the user (or the model) reads one headline,
the named rule's numbers and one picture: about 1 minute, I think, once per failure, not per
step. The opt-in recorder adds a reading of ~5-10 minutes of model time, I think; it's asked
for, never automatic.

---

## 4. The rules for the exam stretch

Thresholds are frozen in one file (`tools/fn/thresholds.md`, each with its clean source run)
at a commit **before** the referee gets the method. Nothing is tuned after a secret bug.

### c2's seven

| Rule | Kind | Decision | Clean / bug margin it rests on (`trial_c2.md`) | Opposite direction |
|---|---|---|---|---|
| G1 nothing moves after the game's reset | generic | **Keep**, reads via C | clean 0.039-0.045 m, limit 0.30; P1 0.42 m in 1.9 s (in `t_ramp`), 2.71 m in 5 s | already a magnitude (both ways) |
| G2 nobody swims far past their bank | generic in form, reads a private field | **Keep, reads via C** (the field that failed silently) | clean max -0.67 m over 1,850 looks, limit 5 m; P3 "far" | "walks on deep water" (not swimming where it should): **NOT PROVEN**, no clean number in the records |
| G3 wheels and hub on the ground | generic | **Change**: (a) mount (any direction) + (b) ground band | (b) lower: clean worst tyre -0.072 m vs -0.12 (0.048 m margin, the tightest). (a) and (b)'s upper side: **not in the records**; the builder measures them on 2 clean runs before any patch (§6). Proposed limits, frozen before measuring so the measurement can only reject them: mount <= 0.10 m (P6 moved the hub 0.3 m); upper +0.15 m. **Rule of the freeze:** if the clean max is over half the proposed limit, the builder reports it and the part is dropped as NOT PROVEN, never re-tuned. | (b) gives both |
| G4 HUD matches the physical wheel | generic in form | **Keep**, reads `_warn` via C | 0 mismatches in 666 looks; P7 on/off | both mismatch directions already |
| D1 the crate's spot is clear | declared | **Keep** | 0 solids; rubble within 1 m of the box (thin margin, stays listed) | n/a (any solid fires) |
| D2 the wreck shows above the water | declared | **Keep** | top +1.905 m clean; P5 -0.39 m | "floats far above": NOT PROVEN (one clean number, no band) |
| D3 P1 walks in by the door on W | declared, proven by play | **Keep** | crossed in 4 s; P2 stuck 0.28 m short | n/a |

### Added (general, what should always hold)

| Rule | Kind | Clean measurement behind it |
|---|---|---|
| X1 **no SCRIPT ERROR in game code** during a watched scenario | generic | 0 in every c2 run and every g2 run (`trial_c2.md` "No SCRIPT ERROR in any run's segment log"; `trial_g2.md` verdict). The split by path (game vs `scripts/dev/`) rests on Godot printing the script path under each error: **I think**; the builder plants one of each and checks (§6). |
| X2 **every check ran** (part G) | generic mechanism, puzzle-specific list | the ID list comes from the builder's clean run; the count must match on every clean qualification run |
| X3 **every rule looked, no read error** | generic | c2: 7 / 7 reached in all 10 S1 runs |

### Counted apart (top4's rule)
- **Generic:** G1, G2, G3, G4, X1, X2, X3, and all of parts A-D (health). G3(a) was written
  after P6 was seen, so it is generic in form but **practice-informed**; reported that way.
- **Puzzle-specific:** D1, D2, D3, the check ID list, `t_ramp`'s own checks (39 `check(` lines,
  each a ramp fact), the driver-owned step list.

### What it claims (R5, R7) and reports NOT PROVEN
- **Claims:** on `ramp,c2_more` as played: the run was alive, in control and complete; every
  check ran and passed; where each rule looked, the state was right; P1 crosses the door on W;
  the van landed within 3 flat-out tries at the logged speed and lane; the drive-off made
  signed progress along the road. Claims through a declared setup count under R13 only where
  the bug's code is on that path.
- **Declared setup, not proven:** every set-state line in `t_ramp` (g12 `PlayTest.gd`: the
  sight-line placements 11683-11698 before the jump; the hut stretch 11755-11863, e.g. P1 placed
  under the window, by the crate, on the crate; P2 placed in the river and behind; the wheel set
  by the hub with `w.global_position = ...` at 11884), `look_at_point`, the F1 jump in
  `c2_more`, P2 put in the river. The builder prints this list in the report (S5).
- **NOT PROVEN:** that a player can get to those placed spots; what a player sees (pictures are
  observer evidence, R2); why a 66.5 km/h jump sometimes misses (g2 INCONCLUSIVE); the land rate
  as a guarantee; speeds under 62 km/h; anything a rule or check doesn't look at; fun.

---

## 5. How it goes to a new puzzle (S7)

**Reused as is:** parts A-D, G's mechanism, H's retry / rerun mechanism, I (the headline and the
command), G1-G4 and X1-X3 wherever their trigger exists (any puzzle with the van parked, a
swimmer, a HUD warning, a game reset).

**What the builder writes per puzzle:**
1. Add the puzzle's scenario(s) to the watched list and the plan (1 line each).
2. The rule list for that plan: which generic rules apply, which are **declared n/a** up front
   (so X3 doesn't call them INCOMPLETE). Frozen before the first run.
3. The validated-read list for the private fields the rules and the scenario's checks use.
4. Mark driver-owned steps and their retry (if the puzzle drives).
5. Deadlines: the episode deadline from one clean run x 1.5; `shot` / `until` deadlines come
   free from the helpers.
6. One clean run -> the check ID list (automatic) -> frozen.
7. 1-3 declared rules for that place (the puzzle's "where it belongs" facts), each two-sided,
   with clean numbers from 2 clean runs.

**Estimate, I think:** 45-70 minutes and 60-150 lines, most of it the declared rules and two
clean runs (a full puzzle scenario is ~1.5-3 min). Unknown: if the puzzle's existing scenario
has the same flakiness as `t_ramp`'s drive-off, the first clean runs will show it, and that
costs more than the hour; reported as found, not fixed by tuning.

---

## 6. The build list for the Opus builder (cap ~60 minutes, R4)

Branch **`g14-final`** from c2's head **`04c3102`** (it already holds c1's code, reused by
file as `7c4b661`, and c2's). From g2 **`afb9e9b`**, copy by function, not by file: `rd()`,
`_stale()`, `preflight()`, `open()`, `close()` (from `G2Rec.gd`), `kill()` and the deadline
loop (from `g2_watch.py`), the `shot()` OPEN / CLOSE (from `PlayTest.gd`). Record the SHAs in
the report (R1). Nothing on C:; one game at a time; `tasklist` first.

**Measure first, before editing any rule's threshold.** The game-side edits go in one batch
(GDScript files mustn't change while a run loads them); the Python is written while runs go.

| # | Step | Min | Running total |
|---|---|---|---|
| 1 | Branch, reuse, read `C2Watch.gd`, `t_ramp`, `ramp_try` | 4 | 4 |
| 2 | **Game-side batch** (one go): (a) `need()` validated reads in `C2Watch` for every private field, preflight at scenario start, per-rule looked / errors / fired; (b) G3 split into mount + band, **log-only** for now (LOOK lines with both numbers); (c) OPEN / CLOSE events via `RigBeat`'s event line in `shot`, `until`, `place_player`, `ramp_try`, episode; (d) check IDs: `check()` logs `CHECK <n>`; (e) `t_ramp`: `--fn-vary=k` picks (target, lane) from a frozen table (k0 62 / -0.5, k1 64 / +0.5, k2 66 / 0, k3 80 / -0.5, k4 80 / +0.5; logged), flat-out retried up to 3, drive-off check -> signed progress at the end; (f) `RigInject` gets `N5` (a step awaiting a signal that never fires, g2's `G2Ctl` "never") and `SE_GAME` / `SE_TEST` (one script error each side, injection only) | 22 | 26 |
| 3 | Compile (7 s); **q1 clean** `ramp,c2_more` k0 (the slowest, worst lane). While it runs: write `tools/fn/fn_watch.py` (from `g2_watch.py`: deadlines, ERROR, verified kill, SCRIPT ERROR split) and `fn_verdict.py` + `tools/fn_run.sh` | 4 | 30 |
| 4 | **q2 clean** k4 (80, +0.5). While it runs: finish the Python. Read q1 / q2: mount and upper-band clean values; check ID list | 4 | 34 |
| 5 | Freeze: G3 limits by §4's rule, check ID list, episode deadline -> `thresholds.md`; commit **before any control** | 3 | 37 |
| 6 | Controls on `c2_more` (~1 min each, all from outside the rules: a patch or an injection): **T4** rename `_swim_to` in `PlayerRig.gd` (expect TEST: observation invalid, before the drive; revert); **N5** (expect STALLED <= 6 s after the step opened, process gone); **P6** x2 (expect FAIL G3 mount both times); **SE_GAME** (FAIL: game script error); **SE_TEST** (TEST); **early return** (INCOMPLETE, checks n of m) | 9 | 46 |
| 7 | **q3 clean** full, final code, k2; must PASS with the one-line headline | 4 | 50 |
| 8 | Report (what was built, the frozen file, every run's headline, departures), commit | 6 | 56 |

**Qualification it must pass** (inside the hour): q1-q3 clean; T4, N5, P6 x2, SE_GAME, SE_TEST,
early return each give their expected headline once. If a clean run fails, **one** fix round
for a test-side cause (R10), then report; no third round (the loop rule). If the drive-off or
the k0 speed is the cause, it's reported with the numbers; the frozen fallback is the
rerun in H(3) and, for k0, raising the table's floor to 63 km/h (written in `thresholds.md`
before any control, never after).

**Cut to fit the hour (on purpose):** no new drive-off controller (only its check changes);
no recorder in the default run; no new "nothing sunk" sweep over the puzzle's props (a rule
with no clean data, and the user's half-sunk rocks would false-alarm, I think).

The referee's requalification (clean, T4, N5) then runs on the frozen head.

---

## 7. Cost per run, and what the user runs

```
tools/fn_run.sh                 # ramp,c2_more, k = next in the table (logged)
tools/fn_run.sh ramp,c2_more 2  # a chosen k
FN_RECORD=1 tools/fn_run.sh ... # only to diagnose a physics failure
```

| | Minutes | Source |
|---|---|---|
| Normal run | **~3 min** (161-199 s wall measured for `ramp,c2_more`) | `trial_c2.md` S6 |
| Each extra flat-out try | +~0.5 min, I think (a `ramp_try` arm with reset is 45-50 s whole, `trial_g2.md`) | |
| Rerun after a driver-owned INCOMPLETE | +3 min, on ~1 run in 5 at most, I think (drive-off 2 / 11 in c1's side data) | |
| Model time / tokens per run | **0** | no model in the loop |
| The user's reading | 1 line on PASS; ~1 min on a failure (headline, numbers, one picture), I think | |

---

## 8. What it can't do, and predicted exam scores

**Can't do (honestly):**
- Prove anything a player does between the declared placements in the hut; it proves the
  interaction from the placed spot only.
- Explain why the jump sometimes misses at 66.5 km/h (it retries and reports it).
- Catch a secret bug that changes nothing any check, rule or deadline looks at (e.g. a wrong
  colour, a sound, a note's wording that still contains the checked word).
- Judge looks or fun; the pictures are there for a person.
- Tell game from test for a failed scenario check or a stall: it says "owner not measured".
- Its S1 depends on `t_ramp`'s drive-off and crate stretch, which have flaked before
  (drive-off 2 / 11; one crate + leg-up FAIL in c1's q1; the crate landing 0.85-1.26 m from the
  wall in `ROUGH_NOTES.md` 2026-10-19). The rerun hides at most one of these per run, and says so.

**Predicted scores (all "I think"):**

| Check | Prediction | Why |
|---|---|---|
| S1 | 9-10 / 10 PASS across k0-k4 | rules have measured margins; risks are the k0 speed (62 km/h, lane -0.5) and the drive-off / crate flake |
| S2 secret (>= 5) | caught 4 / 5, named 3 / 5 | most bugs in a playable stretch either stop progress (X2 / driver INCOMPLETE, named at the step), make an error (X1), or break state a rule or check reads; the misses are bugs nothing reads, and "named" is weakest when the run only stops |
| S2 practice | 7 / 7 caught and named (P6 now by the mount rule) | c2's 6 / 7 + the P6 fix |
| S3 | 4 / 4 (T1-T3 via c1, T4 via C) | measured in c1 / g2 |
| S4 | 5 / 5 (N1 ~20 s, N2 ~5 s, N3 ~1 s, N4 named, N5 <= 6 s) | measured in c1 / g2 |
| S5 | pass with the declared list | no new set state in the proven parts |
| S6 | ~3 min per run, 0 model time | measured |
| S7 | applied in ~1 h with generic rules + 1-3 declared ones; I think 1 or 2 of the generic rules are n/a there | §5 |

---

## 9. Where I expect GPT to disagree, and my answer

1. **"Retrying the jump selects only successful landings"** (GPT's own words in
   `audit_c2_gpt.md`: g2 "reports every bad approach instead of selecting only successful
   landings"). **My top predicted disagreement.** Answer: every try is printed with its
   numbers; a miss is not hidden, it is reported and its reset is watched by G1; 3 misses is
   INCOMPLETE named at the jump. What the retry refuses is to call a run FAIL for a miss whose
   cause is measured as unknown (g2 (a): the same 66.5 km/h lands and misses). The user's own
   claim is "works on my playthrough", and a player retries. Measured clean miss rate on the
   flat-out try: 2 / 10 (c2 S1), 3 / 4 on one g2 arm and 0 / 13 on the others: so P(3 misses
   in a row) is small for most arms (I think under 2 %, not measured for the g2_a0-like case).
   I'd accept a stricter variant if GPT proposes one with numbers: e.g. a miss **inside the
   envelope** (>= 64 km/h, |lane| <= 0.5) prints as a **WARN** line counted across runs.
2. **The recorder on by default** (the skill's "save the failing observation before rejecting
   it"). Answer: g2 scored 0 / 2 as a detector, its value is causes, and it costs 18 MB per arm
   plus a reader. The default run already keeps the failing observation that names the thing
   (the rule's value and picture). I'd concede a **small ring buffer** (the van's and players'
   last 10 s) written only on a non-PASS, if it fits the hour; that is "the 10 % added back".
3. **Counting `t_ramp`'s checks after teleports.** GPT may say they prove nothing by play.
   Answer: they are claimed only as "state after a declared setup and one input", their owner
   is printed "not measured", and S5's gate is about the part claimed as proven; the declared
   list is printed. Dropping them would leave every hut bug to c2's three declared rules.
4. **The G3 mount limit was written after seeing P6.** Agreed it's practice-informed; it is
   reported apart, its limit is frozen before the clean measurement, and the clean data can
   only drop it, not move it.
5. **The automatic rerun** may look like rerunning until green. Answer: one rerun, only for a
   driver-owned INCOMPLETE, both runs printed; a FAIL, TEST, STALLED or NOT HEALTHY is never
   rerun.
