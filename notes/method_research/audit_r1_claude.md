# Stage 2, round 1: the Claude auditor's audit of the GPT auditor's 7 ideas

Written 2026-11-05 by the Claude auditor. Read: the brief, the scoreboard (with P1-P7 proved and
the P3 knock-on), my `ideas_claude.md`, GPT's `ideas_gpt.md`, the two skills
(testing-and-verification v8, first-principles-solving v6), and the code below. I did not open
`audit_r1_gpt.md`. No game or test was run.

Every claim has a file:line or a log line, or says **"I think"**. Paths are from `MPG_dev`.
GPT's ideas are **G1-G7**, mine are **C1-C7**. GPT's "common minimum for all seven" is **G0**.

---

## 0. GPT's facts, checked against the code

Before attacking the ideas, I checked the facts they stand on. Most hold. Two are new to me and
one corrects the brief.

| GPT's claim | Checked | Verdict |
|---|---|---|
| AutoDriver's road index only moves forward; steering is left / none / right; no obstacle sensor (D) | `PlayTest.gd:7484-7487` (`if dlt > 0: ... idx = ni`), `:7497-7503` (full A/D outside 0.05 rad) | **True.** The only "blocked" response is in `ramp_drive_off`: under 3 m moved in 2.5 s, reverse 3 s (`:12022-12031`). After that reverse, the index stays where it was. That makes E4's circling plausible. Not proven. |
| `ramp_closest_to_road` is set to INF once and never reset; the drive-off check takes the closest ever, not the end (O) | `PlayTest.gd:12004` (`var ... := INF`), `:12019` (`minf`), `:11932` (`check(ramp_closest_to_road < 3.0 ...)`) | **True, and I missed it.** It is a false-pass route: a van that once passed within 3 m of the road, then drove 30 m in any direction (`:11931` checks distance from the start only), passes both checks. A van circling on the grass can pass. Same family as E5. |
| Walk expects run **after** the step's commands; only `watch: true` expects run alongside (fact 5) | `LiveControl.gd:485-501`: the `do` loop finishes, then each expect without `watch` blocks in its own `while` | **True. It corrects the brief**, whose project facts say "a walk's expects run in parallel with its steps". Only marked watches do. |
| Expression errors come back as strings and reach `bool(...)` (L) | `LiveControl.gd:129-136` returns `"parse error: ..."` / `"error: ..."`; `:195`, `:495`, `:545` call `bool(_eval(...))` | **True as code.** What `bool("error: ...")` does at runtime: **not measured.** I think GDScript has no `bool(String)` constructor, so it raises a script error and the walk coroutine dies, not "true". If so, `live.py` writes `abort` (`tools/live.py:126-128`), but the result file may never come, and the client waits out its 3600 s walk timeout (`live.py:80`). Unmeasured; a T2 plant settles it. |
| The summary checks failures, not asked vs ran IDs; timeout 3600 s (Q) | `tools/run_test.sh:87-89` (`timeout "${TIMEOUT:-3600}"`), `:110-117` (counts `done`, success = no fails and no problems) | **True** (my fact 8 too). A hang is caught only by the timeout: up to 60 min. |
| Lip speed = total speed at the first airborne frame past local z = -0.5 (J) | `RampJump.gd:351-354` | **True.** Not forward speed, not heading. |
| Roll / pitch are maxima over the fall, not launch attitude (A) | `PlayTest.gd:11598-11600` with the miss rule `RampJump.gd:362` | **True** (my fact 3 too). |
| The Euler angles are "world frame; don't treat as ramp-relative" | `PlayTest.gd:11599-11600`: `global_transform.basis.get_euler()` | **Partly wrong, I think.** Godot 4's `get_euler()` defaults to YXZ order, so x and z come out after the yaw: roughly the body's pitch and roll whatever its heading. Small point; worth a one-line check in any trial that uses them. |
| Second try follows the game's reset, no `ramp_start` (T) | `PlayTest.gd:11720-11724` | **True.** |

One extra fact I found while checking J, so nobody leans on it wrongly: the game's "landed ... 0.84 m
past the far edge" (`appdata/ramp.out:39`) is where the van's **centre** was when the detector fired
(`RampJump.gd:357`, `:392`), i.e. the first frame past the 0.8 m line (about 0.26 m a frame at
56 km/h). It is **not** the touchdown point. So the game still records nowhere where a jump touched
down (my fact 4 stands).

And a correction to my own Stage 1 fact 1: the clean flat-out tries in `ramp_retry` matched to the
decimal 4 / 4 (66.2 km/h, 1.00 m, `ramp.out:38,58,76,96`), but the slow tries did not (offsets 0.22,
0.19, 0.19, 0.17 m; one at 47.3 km/h, `ramp.out:26,44,64,84`). The physics repeats **closely, not
exactly**. That matters for the paired-blame method below (two runs per variant may not be enough
near an edge).

---

## 1. GPT's common minimum (G0): audited first, because every G score leans on it

**What it is:** an outside supervisor polling every 2 s; a test-only observer writing a flushed record
each second (run ID, scene generation, physics tick, paused, devices, scenario, action); 10 s without a
fresh record = `RUN INVALID`; an immutable list of asked scenario IDs that survives `save`; typed
observations (bad node / expression = test problem); four verdicts (pass / game / test / inconclusive).

**Strongest point:** it is the right layer, stated more sharply than mine. Three things in it are
better than my C1: (a) the manifest compares **IDs**, not counts (a count can match while the wrong
scenario ran); (b) "a fresh heartbeat without progress cannot satisfy an action", so a live but idle
game can't pass; (c) "save the offending sample before stopping" (skill v8, §1).

**How it breaks:**
- **Wrong blame (T1 / N2):** "N2 without a pad event = paused, cause unproven". Good. But a pad drop
  and a pause menu both show the same `paused`; the observer must log `Boot._on_joy_changed`'s
  `pause_note` or it can't tell T1 from N2. G0 says "record pad-change events". Careful: `Boot.gd:276`
  pauses **before** `:277` sets the note, in the same call. A per-second record sees both; an observer
  hooked on the pause itself sees a pause with no reason yet and could call T1 an N2. Say so in the spec.
- **False alarm:** "10 s of no relevant progress is invalid" fires on every legitimate wait in this
  game: the ramp's fade and tow take 2.4 s (`RampJump.gd:605`, `:631`), `hold_physics(KEY_E, 7.0)` for the
  refit (`PlayTest.gd:11916`) shows no motion for 7 s. Each needs a declared "timed action". G0 says
  so; it's a list someone must keep right.
- **Cost:** not free. My estimate for the same layer was 2-4 h; GPT charges it inside every idea's
  45-60 min. **Both can't be true.** If each trial has to rebuild it inside a 1-hour cap, nothing else
  gets built.

**The audit point that matters most:** G1-G7 **all** self-score S3 "3/3" and S4 "4/4, 2-12 s" through
G0. Those scores belong to G0, not to the ideas. They don't separate the seven at all. Read GPT's
table with S3 and S4 struck out: the ideas differ only on S1, S2, S5, S6.

**Verdict on G0: merge with my C1** (same mechanism; see section 3). Build it **once**, first, and
score it on its own against T1-T3 and N1-N4. Every later trial reuses it.

---

## 2. GPT's seven ideas, one by one

### G1. Measured skills with a separate contract checker

**What it is:** an in-engine actor with small closed-loop skills (drive with swept obstacle queries
and proportional steering, walk with rays, interact by turning until the prompt shows), real input
only; a separate checker that never accepts the actor's own "done" and judges physical events.

**Strongest point:** the separation. The checker judges the world, not the actor's report. That's the
cure for E5 (the walk's last step trusted "wheel on") and for the `ramp_closest_to_road` hole GPT found.
It also fixes AutoDriver's two known defects by name (one-way index, no obstacle sense). And it is the
only idea (with my C5) that walks the hut part for real (S5).

**How it breaks (concrete):**
- **Cost, the big one.** GPT says 3-6 h for the full co-op route. The project's own record says
  otherwise: a real-input bot crossing the seesaw went "15+ times" round in ~1.5 h without converging
  (`notes/ROUGH_NOTES.md:716`), and that was one stretch. The crate + leg-up skill (GPT calls it "the
  hardest unbuilt skill") has a measured flaky window: crate 0.85-1.26 m from the wall (my Stage 1,
  `ROUGH_NOTES` 2026-10-20). **I think days, not hours, for the whole route.** In a 1-hour trial it
  reaches the jump and the drive-off, nothing more.
- **False alarm (S1):** any skill weaker than a human turns a working game red. E2 and E4 were exactly
  this. Swept queries help; they don't prove the skill is good enough at 10 / 10.
- **False pass (P4):** a capable walker puts the crate down **next to** the rubble and the leg-up still
  works. The bug hides. GPT names this itself ("planner might route round it"). Its fix ("required
  intended window placement") is a predicted coordinate again: the thing the user said not to do.
- **Wrong blame:** a skill that fails reads as `game?` unless the rig layer shows the input was
  applied and something measured blocked it (G0 / C1 must sit under it).

**Self-scores:** S1 "unknown": honest. S5 "intended pass": agreed, if the referee checks every helper.
S3 / S4: G0's, not G1's (section 1). **S6 understated:** "45-60 min for jump, supervisor and departure"
counts G0 in an hour; I think the supervisor alone is an hour.

**Verdict: keep, merged with my C5** (same mechanism: goal-seeking actor, real input, judged by
outcomes; GPT's version is sharper: swept queries, index reacquire, the checker never trusts the actor).
Trial it at the **smallest honest scope**: jump + drive-off, the hut part declared as setup and
reported NOT PROVEN.

### G2. Event-anchored playback of genuine two-player input

**What it is:** record a real person's inputs once; replay short phrases, each started by an observed
event; correct alignment between phrases through input.

**Strongest point:** the inputs were proven playable by a human, so a replay that works is a real path
with no bot skill to doubt.

**How it breaks:**
- **No demonstration exists**, and nobody in this process can make one. The referee and builder are
  models; a model playing live is the old v3 trap (`notes/TESTING_METHOD.md`, the brief's trap 3). So
  the tester is the user: 8-15 min per demonstration (GPT's figure), again at every design change.
  The brief says it "can't eat the user's real time". **It can't be trialled in Stage 3 without the
  user.** GPT says this itself ("No existing human input file is assumed").
- **S1 kills the replay itself.** S1 wants lip speeds spread over 61-68 km/h and different landing
  spots. One recorded phrase gives one speed and one landing. A different landing spot means a
  different walk to the hut, so the walking phrases don't fit, and "bounded correction" grows into a
  controller. GPT sees this: "Enough correction becomes #1". Then it **is** G1, plus a recording.
- **False alarm:** the slow tries in `ramp_retry` drifted 0.17-0.22 m between identical starts
  (`ramp.out:26-84`). A replay started from a slightly different state drifts more. GPT's own rule
  ("replay cannot follow" = test problem) is honest, but it means S1 fails on a working game.

**Self-scores:** S1 "drift is a major risk": agreed, I'd say "likely fail". S7 "30-90 min plus another
human demonstration": the demonstration is the user's time and should be scored as such.

**Verdict: drop.** Reason: untrialable without the user, and at the scale S1 needs it turns into G1.
My C7 (the user's trace as a reference) falls with it for the same reason (section 4).

### G3. Search the live space of possible actions

**What it is:** an explorer that tries untried actions and builds a graph of what worked, with a
global budget; never passes with an incomplete frontier.

**Strongest point:** it can find routes nobody predicted. That is literally "don't predict the future".

**How it breaks:**
- **Cost:** every edge is real walking. The ramp alone: fade + tow 2.4 s per miss, ~10 s per try
  (`ramp_bench.out`, my Stage 1). GPT budgets 5 min a run and 4-8 h to build. Its own rank: 5th.
- **False pass on the practice set:** the search is built to find **another** way. P4 (rubble) and P2
  (a sill a player might jump) are exactly where it would find a workaround and hide the bug. GPT's
  answer, "fail a known contract immediately", brings back the authored route.
- **False alarm:** "exploration incomplete = unsuccessful" on a working game whenever the budget is
  short. For S1 (10 / 10) that's a big risk.

**Verdict: drop.** Keep one rule from it in the merged checker: an unfinished search is never a pass.

### G4. Paired attempts that test a cause

**What it is:** after a failure, predeclared pairs that change one factor (fresh start vs post-miss
retry; neutral vs controller steering; driver ownership; target-relative vs index departure); stop
after two pairs; unmatched pairs are inconclusive.

**Strongest point:** it turns blame into a measurement. The scoreboard's open question ("what made a
66.5 km/h jump miss?") can only be answered this way. And it costs only when something fails.

**How it breaks:**
- **Inconclusive on noise.** GPT warns of "a tidy explanation out of stochastic physics". The evidence
  says the jump is close to repeatable but not exact (section 0: 4 / 4 identical flat-out tries,
  slow tries 0.17-0.22 m apart). Near the edge of the envelope two tries per side may disagree. So a
  repeat of the failing case (my V0) must come first, or the pair proves nothing.
- **Wrong blame on unlisted causes.** Only the factors someone thought of get varied. If the real
  cause is none of them, "fails everywhere" reads as `game`. GPT's "inconclusive" label is the right
  guard; my Stage 1 rule table said `GAME` there. **GPT is right and I change that row** (section 4).
- **The P3 knock-on** is a perfect test for it: with P3 on, the van moved 0.57 m after its reset,
  brake on (scoreboard). A pair "swimmer beside the van / no swimmer" separates P3 from P1. A method
  that skips that pair blames P1 wrongly. GPT's pair list doesn't include it; it must.
- **Cost:** up to 4 extra tries at 0.5-1 min (GPT). I measured ~12 s a try plus load
  (`ramp_bench.out`, `t` 8.8-10.3 s + 2.4 s reset). Cheap on the ramp, I think ~10 min a diagnosis in
  the hut.

**Self-scores:** "S1 entirely depends on primary player": correct and honest. S2 "better naming for
P1-P4": I agree for P1 and P3, not P2 / P4 (those are static: nothing to pair; an invariant names them
for free). S3 3/3: G0's again.

**Verdict: keep, merged with my C2** (same mechanism: rerun one stretch, one factor changed).

### G5. Screen-driven control with bounded local computation

**What it is:** a controller that plays from the rendered player views with cheap image operations at
5-10 Hz; a model writes the detectors before play, not during.

**Strongest point:** independent sensing, the honest answer to "AutoDriver senses very little".

**How it breaks:**
- **Wrong diagnosis of the problem.** On the ramp the driver's weakness I can point at is not sensing:
  it's full A / D presses up to 1 m before the lip (`PlayTest.gd:11594`, `:7500`) and the one-way index.
  Better control on the same data fixes those; pixels don't.
- **False alarm:** toon shading, snow, rain and split-screen at 1600x900 (`run_test.sh:89`) change
  every template. S1 needs 10 / 10.
- **Cost:** 6-12 h for a full pixel player (GPT). Hits the cap for anything beyond a road demo.

**Verdict: drop.** Reason: it fixes the wrong defect at the highest build cost.

### G6. Separate evidence judge over a real play session

**What it is:** a person plays through the controls; the host checks health, coverage and physical
events live; a reviewer who didn't play judges event clips and telemetry with a private sheet;
"not visible" = unchecked, never pass.

**Strongest point:** two halves, and the second is strong. The judge half (event clips, a blind
reviewer, evidence IDs per finding, "can't see" = unchecked, the machine gates can't be overruled) is
the best version of what the evidence says found most real bugs: "Most were found by looking at
pictures or video, not by the checks" (brief).

**How it breaks:**
- **The player half fails the brief's core.** S1 needs 10 runs; that's 10 plays at 3-6 min each (GPT),
  40-90 min of a person. If that person is the user, it breaks "can't eat the user's real time"; if
  it's a model, it's the v3 trap. In Stage 3 there is no other tester. GPT picked it as one of its two
  trials while noting "No available tester ... is assumed". **That pick can't run.**
- **False pass:** a person jumps the P2 sill or drops the crate beside the P4 rubble and moves on (GPT
  says so). The judge sees a successful clip.
- **Judge cost and accuracy, unmeasured:** my C6 estimated 50-150k tokens a run with 30-60 frames.
  Ten S1 runs = ten judge calls. The misread rate on this game's frames is unmeasured by anyone.

**Self-scores:** S1 "stronger than a new bot": only because a human plays; that's not the method's
credit. S6 "expensive human time, explicit": agreed; it should decide the verdict, not sit in a note.

**Verdict: split.** The player half: **drop.** The judge half: **merge with my C6** (same mechanism).
I then leave the merged judge **out of the top 4** for cost and unmeasured accuracy; it is the first
reserve if the final exam's secret bugs turn out visual and the invariants miss them (section 5).

### G7. Predict short motions; execute only the first input

**What it is:** a local planner rolls out 9 input choices over 0.5-1 s with a fitted van model, runs
0.1 s of the best, replans.

**Strongest point:** it reacts to what's ahead, not to a road index.

**How it breaks:**
- **Wrong blame built in.** A small fitted model of a `VehicleWheel3D` van on GodotPhysics3D
  (`project.godot:37`) gets suspension, landing and wheel-loss wrong; GPT says so. "Calibration might
  hide a real game regression": P1 (the van rolling after a reset) is a changed response the planner
  would learn and drive round.
- **Cost:** 6-10 h for the route (GPT). For the jump, proportional steering with a straight hold before
  the lip is a 20-line change to AutoDriver, not a planner.

**Verdict: drop.** Its one useful piece (react to what's ahead) is already in G1's swept queries.

---

## 3. True duplicates (same mechanism, not just the same goal)

| Merged | GPT | Mine | What the merged version keeps |
|---|---|---|---|
| **M1. The rig layer** | G0 (common minimum) | C1 (rig-checked verdict) | From GPT: the outside supervisor, IDs (not counts) in the manifest, typed observations, "fresh heartbeat without progress can't satisfy an action", save the bad sample first, the 4 verdicts. From mine: the **pause guard inside** `wait` / `until` (they run through a pause: `PlayTest.gd:217-218`, `:40`), command -> effect on the intended player's device, the plan lint (nothing after `save`), and the **SET counter** that makes S5 readable: a check after a set-state in its stretch says NOT PROVEN, never PASS. |
| **M2. Paired / counterfactual blame** | G4 | C2 | From GPT: pairs predeclared, two pairs then stop, "unmatched = inconclusive", no "bad roll = invalid test" shortcut. From mine: **V0 first** (repeat the failure; disagreement = flaky, no verdict), the written rule table, the reachability question for state ("can a player reach that inherited state? the game's own reset: yes -> game"). Added from the scoreboard: the swimmer-beside-the-van pair (P3 knock-on). |
| **M3. Goal-seeking actor + independent checker** | G1 | C5 | From GPT: swept body-width queries, index reacquire after reversing, the checker never accepts the actor's "done", signed road progress + occupancy for the drive-off. From mine: goals are the game's own predicates (`Story.gd:93-101`: `ramp_jumped`, `not wheel_off`, van near `j3`), targets are named nodes, **attempts counted** ("landed on try 2" is a finding, not a pass). |
| **M4. Blind judge on event pictures** | G6 (judge half) | C6 | From GPT: evidence IDs per finding, the machine gates can't be overruled, no endless panels. From mine: the canary set (P4-P7 patches) gives the judge's hit rate with every verdict; the other model family judges. |

Not duplicates, though they look close: G2 and my C7 both start from a human play, but G2 **plays**
it back and C7 **judges** against it. G1's "numeric warnings" (depth rays, mesh bounds) overlap my C3
(invariants) in two rules only; C3's mechanism (the game checks itself in every play, including the
user's) has no GPT twin.

---

## 4. My own seven, revisited

| Mine | Now | What moved me (evidence) |
|---|---|---|
| C1 rig-checked verdict | **Keep, merged (M1)**, with GPT's IDs, typed observations, progress rule | G0 is the same mechanism, sharper in three places (section 1). |
| C2 counterfactual blame | **Keep, merged (M2); one row changed** | GPT's "unmatched = inconclusive". My table said "fails in V0-V3 -> GAME". That's wrong blame when the cause is outside the variants; it now says **inconclusive: cause outside the listed factors**. Also: `ramp.out` shows slow tries vary 0.17-0.22 m, so near an edge V0 gets 3 runs, not 2. |
| C3 the game checks itself | **Keep, unchanged in mechanism; scoring changed** | GPT has no twin. Its G1 / G3 / G6 audits each admit P4 and P2 can be routed round by a capable player; an invariant on the declared crate spot or the door can't be routed round. Change: I split its rules into **generic** (written without the P-list: below ground, swimming on dry land, state vs what's shown, nothing moves after a reset, not paused without a menu) and **P-specific**, and score them separately, so overfitting to the practice set shows. |
| C4 the envelope | **Drop as a method; keep as the S1 protocol** | The scoreboard already requires S1 runs spread over 61-68 km/h and landing spots. The sampler is how M3 should be run 10 times, not a separate method. Its properties ("61 lands") are design predictions; the grey zone was the honest part. |
| C5 goal-seeking players | **Merged into M3** | G1 is the same mechanism with a better spec. I keep my cost estimate (days for the whole route) against GPT's 3-6 h: `ROUGH_NOTES.md:716`. |
| C6 blind judge | **Merged into M4, then left out of the top 4** | No new evidence on accuracy; cost per S1 run (10 judge calls) is the problem. First reserve. |
| C7 the user's trace as reference | **Drop** | Same blocker as G2, now confirmed by both of us separately: no valid demonstration file exists (GPT: "No existing human input file is assumed"; the walk is staged, `make_ramp.py:132`), and only the user can make one. Can't be trialled in Stage 3. Its event log lives on inside M1's heartbeat records. |

**Attacks I expect on the ones I keep, and my answers:**
- *"M1 is bookkeeping, not a method; it shouldn't take a top-4 slot."* It is what turns E3, E6, E7, E8
  (three of the four false passes / watching failures in the evidence table) into fast `TEST` reports.
  Those are scored (S3, S4), and S4 is a gate. And if it isn't a slot, each trial rebuilds it inside its
  1-hour cap, or skips it and claims G0's scores without having built them.
- *"C3 is written to the practice set (Theo's public-bench trap)."* Yes, half of it. That's why the
  generic rules are scored apart. The final exam's secret bugs are the honest test of the generic half;
  the trial reports both counts.
- *"C3 can't prove completion."* Agreed; it never claims to. It rides on whatever plays (M3, today's
  `t_ramp`, or the user's own play) and catches the bugs a player can walk past: P4, P5, P6, P7.
- *"M2 does nothing against false passes."* Agreed. It isn't meant to; M1 does that. M2 answers the
  question nothing else can: B0, and P1 vs P3.

---

## 5. My proposal for the top 4 (2 Claude, 2 GPT)

Order of trials, as the brief says: Claude, GPT, Claude, GPT. The order below is deliberate: M1 first,
because every other trial's S3 / S4 depends on it, and it should be built once.

| Trial | Runs it | Method | Gate S5 | Gate S4 | S1-S3 | S6 per run |
|---|---|---|---|---|---|---|
| c1 | Claude | **M1 the rig layer** | makes S5 readable (SET counter) | **N1-N4 direct** | **S3: T1-T3 direct** | ~0 extra |
| g1 | GPT (Opus builds) | **M3 goal actor + checker, jump + drive-off** | **pass by design** | via M1 | **S1** (the driver), E4 / E5 / O-hole | 3-5 min I think |
| c2 | Claude | **C3 invariants, generic vs specific** | **pass** (moves nothing) | N1 / N2 partly | **S2: P2-P7 named at the object** | ~0 extra |
| g2 | GPT (Opus builds) | **M2 paired blame** | declared setups only, never claimed | via M1 | **S2 named (P1 vs P3), S3 game vs test, B0** | only on failure, ~2-3 min |

### c1 (Claude): M1, the rig layer
A layer under every scenario: a heartbeat record each second (physics frame count, `paused`,
pause note, scenario, step, P2's device kind) read by a line-flushed outside watcher; the asked
scenario IDs written before launch and compared with the ran IDs at the end; `wait` / `until` that
refuse to step through an unexplained pause; each injected input checked on the intended player's
device; and a SET counter so any check after a set-state in its stretch reports NOT PROVEN.
**Why it beats the rest:** it is the only one that scores both T1-T3 (S3) and N1-N4 (S4, a gate)
directly, at ~0 cost per run, and every other trial's S3 / S4 claims are really claims about it.
**Smallest version on the ramp (1 h):** heartbeat + watcher (10 s), asked / ran IDs in `run_test.sh`,
the pause guard, P2's device check before a P2 action; run on today's `t_ramp` with T1-T3 and N1-N4
planted. The SET counter on `t_ramp`'s helpers if time allows; it will show how little of `t_ramp` is
proven (my fact 10: `:11715`, `:11884`, `place_player` / `face_point` through the hut). Not in the
first hour: the expression lint for walks (T2 then via a typed node lookup in PlayTest only).

### g1 (GPT): M3, the goal actor with an independent checker, jump + drive-off only
GPT's G1 spec, cut to the ramp's driving part: AutoDriver replaced (proportional steering by tapped
keys, steering held straight in the last ~30 m, swept body-width check ahead, index reacquired in both
directions after reversing), and a checker that ignores the actor: the game's `jumped` flag, attempts
counted, both players still aboard, drive-off = 30 m **signed** progress along the road from where it
parked, on the road for the last 3 s, stopped by the brake. The hut part is a **declared setup**
(wheel refitted by code) and reported NOT PROVEN. Run 10 times over 61-68 km/h and lanes -1.5..+1.5 m
(my C4's sampler as the S1 protocol).
**Why it beats the rest:** it is the only real path (S5) for the driving, and S1 is where today's method
fails (B0, E2, E4). It closes the `ramp_closest_to_road` false pass GPT found. Specifiable without GPT
coding: the spec above is a list of behaviours and numbers.
**Smallest version:** exactly that, nothing in the hut. 1 h is tight; I think the steering + checker fit,
the swept query may not.

### c2 (Claude): C3, the game checks itself
A dev-only node checking local rules at 5 Hz plus once after the world is built, each naming its object:
generic rules (anything below the ground, a swimmer on dry land > 1 s, what the HUD says vs the van's
state, whatever a game reset put down moves > 0.5 m in 2 s with no input, paused with no menu or pad
note) and declared ones (the door walk-through test, the crate's spot clear, the wreck's top above the
water). Scored generic and declared separately.
**Why it beats the rest:** it is the only idea that names P2, P4, P5, P6, P7 at the object without a
picture judge, and a capable player (human or M3) can't route round it. S5 is a free pass. ~0 per run;
it also runs in the user's own play. It beat M4 (the judge) for this slot on S6: no tokens, no
unmeasured misread rate.
**Smallest version:** the static rules (door, crate spot, wreck) and the after-landing rules (hub, HUD),
the swim rule and the reset rule, riding on today's `t_ramp` (whose jump lands 4 / 4 in `ramp_retry`
conditions) with each P-patch applied in turn.

### g2 (GPT): M2, paired blame
A predeclared pair table run after a failure: V0 the same again (3 times near an edge), fresh
`ramp_start` vs the game's post-miss reset, bang-bang vs straight-held steering, P2 seated vs outside,
can on the rack vs not, swimmer beside the van vs not; one factor per pair; a written rule table where
"fails in all" means **inconclusive**, not game.
**Why it beats the rest:** it is the only method that answers B0 and blames P3 (not P1) in the
knock-on: both are scored under S2 "named" and S3. It costs only on failure. It's a table and a rule
list: ideal for GPT to specify and Opus to build as one scenario.
**Smallest version:** B0 first (the baseline's 66.5 km/h miss), then P1 and P3 each with the swimmer
pair. ~12 tries at ~12 s plus loads: I think under 5 min a diagnosis.

### Left out, in scoreboard terms
| Idea | Why not in the 4 |
|---|---|
| G2 / C7 (human input as player or reference) | S6: the user's time per puzzle; untrialable in Stage 3. G2 also fails S1 by design. |
| G3 action search | S6 4-8 h; S2 false pass by design (routes round P2 / P4). |
| G5 pixel control | Fixes the wrong defect; S1 risk; S6 6-12 h. |
| G6 player half | Fails the brief's core (a person per run) or walks into the v3 trap. |
| M4 judge (G6 judge half + C6) | Lost the slot to C3 on S6 (tokens x10 runs) and on an unmeasured misread rate. **First reserve** if the final exam's secret bugs are visual and C3 misses them. |
| G7 planner | S6 6-10 h; learns its way round regressions (P1). |
| C4 envelope | Kept as the S1 protocol, not a method. |

---

## 6. Disputes I expect, and what would settle them

| # | Where GPT will likely disagree | My position | What settles it |
|---|---|---|---|
| D1 | M1 is "common bookkeeping", not a top-4 slot | It's scored (S3, S4 gate) and must be built once, or each trial rebuilds it inside 1 h | The referee's ruling on shared infrastructure across trials; c1's measured build time (if it's ~1 h, GPT's "45-60 min including the supervisor" for G1 can't hold) |
| D2 | G6 (human-played judge) as a trial | It can't run in Stage 3: no tester but the user | The referee names a tester who isn't the user and isn't a live model. If none exists, it's out |
| D3 | G1 the full co-op route in 3-6 h | Days; the 1-hour trial does jump + drive-off only | g1's measured minutes; `ROUGH_NOTES.md:716` (seesaw bot, 15+ rounds, ~1.5 h, no convergence) |
| D4 | Visual checks need a player's view (G0 point 4) vs an observer camera | S5 forbids aimed cameras **in reaching** a state; observing it from a camera no player owns moves nobody | The referee's reading of S5's "aimed camera inside the part being proven" |
| D5 | C3 overfits to P1-P7 | Half of it does; generic and specific are scored apart | The final exam's secret bugs, counted against the generic rules only |
| D6 | C3 over M4 (the judge) for the 4th slot | C3: ~0 tokens, names the object; the judge's misread rate is unmeasured | One cheap measurement before Stage 3: the judge on the P4-P7 canary shots (existing `_shots` + the referee's patches), hit rate vs C3's |
| D7 | M2's "fails everywhere" verdict | Now inconclusive (I changed it; GPT's point) | Agreed already, I think |
| D8 | Whether `bool("error: ...")` is a false pass or a crash | I think a script error and a 60-min hang | A T2 plant in c1: one bad expression in a walk, watch what happens |
| D9 | The Euler angles (world vs body) | YXZ order, so roughly body pitch / roll | One line: Godot's `get_euler()` default order; or log the basis directly in g2 |

---

## Decision log
- v1, 2026-11-05: written. Evidence that changed my own ideas: `PlayTest.gd:12004-12019` / `:11931-11932`
  (the closest-approach false pass, GPT's find), `LiveControl.gd:485-501` (expects are sequential unless
  watched, GPT's find; corrects the brief), `ramp.out:26-84` (slow tries not identical: physics repeats
  closely, not exactly), GPT's "unmatched = inconclusive" (changes one row of my C2 table).
