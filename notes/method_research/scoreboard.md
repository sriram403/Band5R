# Scoreboard: the test-method research

Written by the referee on 2026-11-05, **before any idea or trial**. Only the
referee changes it, and every change is logged at the bottom with its reason.
Brief: `notes/TEST_METHOD_RESEARCH.md`.

## The checks

| # | Check | How it's measured | Pass |
|---|---|---|---|
| S1 | **No false alarms** | At least 10 runs on the working game (`g12`, unchanged). The runs must vary: speed at the lip spread over at least 61-68 km/h, and where the van lands / parks (different lanes or approaches). Each run's numbers are logged. | 10 / 10 pass. One failure = fail, unless it's measured to be a real game bug (then it counts under S2 and goes to the user). |
| S2 | **Finds real bugs** | Practice set (public, below), each put back as a patch, one at a time. Final exam: the referee's secret set. | Each bug: **caught** (the run fails) and **named** (the report points at the broken thing, not at a symptom three steps later). Scored caught / named out of the set. |
| S3 | **Blames the right thing** | The test itself is broken on purpose (list below). | The report says "test problem" (or the method's own words for it), not "game problem". Scored out of the set. |
| S4 | **Can't pass by doing nothing** | The game frozen or paused; a player missing; a scenario skipped (list below). | Fails or reports it within 60 s of it happening (no silent waits to a 10-minute timeout). Scored out of the set, with the seconds to notice. |
| S5 | **Real path** | The referee reads how the method reaches each state it proves. | No teleport, set state, handed item or aimed camera inside the part being proven. Setup before it is fine if it's declared and the declared part isn't claimed as proven. Pass / fail, with the lines. |
| S6 | **Cost** | Wall-clock minutes per run; tokens and model time per run; the user's time to read the result. | Reported for every trial. Any model thinking inside the play loop must be justified against the old trap (`notes/TESTING_METHOD.md` v3: think time became the biggest cost). |
| S7 | **Not only the ramp** | Final exam only: one other complex puzzle chosen by the referee, not named until then. | Works with reasonable effort; the effort (hours, lines) is reported. |

### How the referee decides between methods

1. **Gates first.** S5 (real path) and S4 (can't pass by doing nothing) must pass.
   A method that proves things by teleporting, or that passes a frozen game,
   proves nothing, however good its other numbers are.
2. **Then the error rates:** S1, S2, S3 together. A false pass (missed bug,
   frozen game passed) weighs more than a false alarm, because the evidence
   table shows false passes reached the user's video unseen.
3. **Then cost (S6).** Between two methods with equal error scores, the cheaper
   one in the user's real time wins.
4. **S7 decides between finalists** and says how far the method carries.

## The sets

### Practice set (public: real bugs from the notes and git)
Put back as patches, one at a time. The referee prepares the patches before
Stage 3 and checks each one really breaks the game before it counts.

| ID | The bug | Where it was |
|---|---|---|
| P1 | After a miss the van rolls downhill and uses up its run-up (57 km/h at the lip instead of 66) | ramp: the handbrake on reset |
| P2 | The hut door sill blocks walking | ramp: the hut |
| P3 | A swimmer stays in swim mode beside the van | ramp: the river / P2 left behind |
| P4 | Rubble where the crate goes | ramp: under the hut's window |
| P5 | The wreck under the water (`global_*` during world build) | ramp: the river |
| P6 | The bare hub sits below the ground | ramp: after the landing |
| P7 | The HUD says PUNCTURE with no wheel | ramp: after the landing |

(Piers stopping in mid air belonged to the cut bridge; it is left out because
`g12` has no piers.)

**The patches:** `notes/method_research/practice/practice_bugs.py` (one at a time,
on a trial branch, never committed, `restore` after). The fixes all landed in one
commit (`98753bf`), so each bug is put back by its symptom.

**Proved by the referee (2026-11-05)**, each against a clean control run (the
referee's own check, kept private so nobody writes to it):

| ID | Clean game | With the bug |
|---|---|---|
| P1 | the van moves 0.04 m in 5 s after a miss's reset, brake on | **3.79 m**, brake off |
| P2 | P1 walks in by the open door | stuck **2.2 m** short of the door |
| P3 | the swimmer is on foot after the reset | **still swimming** beside the van |
| P4 | nearest rubble 1.94 m from the crate's spot | **0.00 m**: the heap under the window (picture) |
| P5 | the wreck's middle 0.41 m above the water | **1.88 m under** the water |
| P6 | the hub's bottom -0.01 m from the ground | **-0.19 m**: in the ground |
| P7 | HUD: "ON THE HUB - front-left wheel gone" | HUD: **"PUNCTURE - steer pulls left"** |

Knock-on seen: with P3 on, the van also moved 0.57 m after the reset with its
brake on (clean: 0.04 m). I think the swimmer beside it nudged it; not measured.
A method that blames P1 there has blamed the wrong thing.

### Test-breakers (for S3)
| ID | Broken on purpose | Expected verdict |
|---|---|---|
| T1 | P2's pad unplugged mid-run (`boot._on_joy_changed(0, false)`) | test problem (the game correctly pauses) |
| T2 | A stale / wrong expression or node name in the test | test problem |
| T3 | A scenario queued after `save` | test problem (it never ran) |

### Doing-nothing cases (for S4)
| ID | Case | Pass |
|---|---|---|
| N1 | The game frozen (a script stops the tree) | reported within 60 s |
| N2 | The game paused | reported within 60 s |
| N3 | A player missing (P2 not in the scene / never spawned) | reported, not passed |
| N4 | A scenario asked for but skipped | the summary says asked n, ran m |

### Final exam (secret)
At least 5 new bugs written by the referee, each seen to break the game before
it counts. Kept outside the repo until the exam. Counts and reasons in reports
for the practice set only.

## Baseline: today's method (v5, `PlayTest.gd` `t_ramp`), 2026-11-05

| Run | Result | Notes |
|---|---|---|
| `tools/run_test.sh ramp` on `g12` head `878286d` | **1 scenario, 1 failure**, 45 s of game | The slow try (46.8 km/h) fell short, reset and "nothing lost" passed. The flat-out try: **66.5 km/h at the lip, 1.05 m off the middle, roll up to 14.5 deg, pitch 23.2 deg -> "shallows"** (a miss). The test then returned early (`if go["what"] != "landed": return`), so nothing after the jump ran. The user has played the jump and it works. **Game or test: not measured.** Open question for the auditors: what in the run made a 66.5 km/h jump miss? (The second try starts 0.3 s after the game's own reset, with no `ramp_start()`; the AutoDriver steers.) |

### Today's method on the working game (side data from c1's scoring)
11 full `t_ramp` runs under the rig: **7 pass, 4 fail** (2 drive-offs, 2 missed jumps: one at
57 km/h after the reset, one at 66.6 km/h / 0.82 m where another run at 66.6 / 0.81 landed).
On S1, today's method fails. Details: `trial_c1.md`.

## Trial scores

| Trial | Branch | S1 false alarms | S2 bugs caught / named | S3 blame | S4 doing nothing | S5 real path | S6 cost | S7 other puzzle | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| c1 | `g13-trial-c1` `a6a412f` | **10/10** rig healthy | 0/7 (not covered, R5) | **3/3** (defect: one STOP didn't kill) | **4/4**, all <= 27 s | pass | 23 min build; ~140 s per run; no model tokens | n/a | **Passes its claim** (`trial_c1.md`) |
| g1 | `g13-trial-g1` `a367de3` | **fails** (clean retries missed 2/2 in v4: driver 2 m left at the lip; v3 sweep false alarms) | not scored | via c1 (not re-scored) | partly: idle 10.03 s, blocker caught by ID | not audited yet | ~75 s per run; 30 min build in 2 rounds | n/a | **Failed qualification in its cap** (`trial_g1.md`) |
| c2 | `g13-trial-c2` `04c3102` | **10/10**, 7/7 rules reached each run; spread 65.9-67.0 km/h only (R14) | **6/7 caught + named; P6 1/3** (G3 checks only "below"; the hub floated) | 3/3 via c1; **c2's own stale-field case: false pass** (silent NOT REACHED, 733 errors hidden) | **2/2** + 4/4 via c1; defect: a stuck test step goes unseen (c1's rig) | pass (declared setups) | 33 min build; 161-199 s per run; `c2_more` ~55 s; no model tokens | n/a | **Passes S1 + gates; S2 6/7; S3 hole** (`trial_c2.md`) |
| g2 | `g13-trial-g2` | | | | | | | n/a | |
| Final | | | | | | | | | |

## Referee rulings (after Stage 2 round 1, 2026-11-05)

Asked for by the auditors; they apply to every trial alike.

- **R1 Shared parts.** A part one trial builds (e.g. c1's health layer) may be reused
  by a later trial only after it passed its own negative controls in its trial. The
  reusing trial's S3/S4 scores are marked "via c1"; build minutes are charged once,
  to the trial that built it. A later trial never inherits an untested green claim.
- **R2 Observer cameras.** A camera no player owns, which can't change play, inputs, or
  what any actor senses, is allowed for evidence. It is not an "aimed camera" under S5.
  It may add to, never replace, what a player must see from where they stand
  (a note readable, a door seen open): that needs a player's view reached by play.
- **R3 No human operator.** There is no person to play the trials: the user's time is
  not a per-run resource (the brief's core problem). "Real play" in a trial means an
  input-only actor whose path has been audited (S5). A model choosing inputs live is
  allowed only if its S6 cost is measured and answered against the old trap.
- **R4 The hour cap** covers the build and the builder's own qualification runs. The
  scoring runs (S1 ten clean runs, S2 practice patches, S3 test-breakers, S4
  doing-nothing cases) are run by the referee afterwards, watched and timed into S6,
  and don't count against the cap. A trial that can't reach a runnable state in the
  hour counts as failed and reports where it got.
- **R5 Coverage.** A trial is scored on the stretch it claims to prove. Anything outside
  it is reported NOT PROVEN, and practice bugs outside it count as **not caught** in S2.
  A jump-only method can't score the hut's bugs.
- **R7 Reading the built world (after round 2).** A read-only check (probing geometry,
  reading the game's own state) reaches nothing by play, so S5 has nothing to forbid in it.
  It may claim only what it reads ("the crate's spot is clear"), never what a player can do
  or see there; those stay NOT PROVEN unless an actor reaches them by input.
- **R8 c1 is fit for reuse (after its scoring).** The GPT auditor's conditions (exact-head
  controls, a clean `ramp` exercising the receipts) are met by the referee's scoring on
  `a6a412f`. Reuse its code commits (`920110d`, `3b96807`, `a106f90`, `57b8afd`), recording
  the SHAs. Known limits travel with it: one STOP failed to kill the game; the 5 s pause
  rule would stop scenarios that pause on purpose; "pad lost" is always TEST; the 20 s
  stale limit is unmeasured.
- **R9 Video (g1 handoff).** Stills of each phase plus the checker's trace suffice for
  qualification; a video is a bonus, not to be bought with the trial's hour.
- **R10 Fixing your own trial inside the cap.** A trial's owner may revise its own rules
  inside the trial's hour (c1's builder fixed its own false alarms; g1's owner, GPT,
  revised its spec once, and the builder applied it). The revision's time counts against
  the same cap.
- **R11 No scoring runs after a failed qualification.** When the clean run already fails
  in qualification, S1 can't reach 10 / 10; the trial is recorded as failed with its
  partial results, and no scoring runs are spent.
- **R12 State checks ride on a driver that doesn't always get there (before c2, 2026-11-06).**
  c2's rules look only where the run reaches; today's `t_ramp` reaches the end 7 / 11 times on the
  working game. **S1:** a run counts when no rule fires on the working game; a rule the run never
  reached is NOT REACHED (neither pass nor fail) and each rule's coverage is reported (looked in
  k / 10 runs; under 5 / 10 is marked "S1 thin" for that rule). A rule firing on the working game
  is a false alarm, whatever the driver did. A driver failure (miss, drive-off) is not c2's verdict
  and must not be reported as a game problem by c2. **S2:** a practice bug whose rule was NOT
  REACHED in its run gets one rerun, logged; still not reached = not caught.
- **R13 Catches through a declared setup (c2's question 1, 2026-11-06).** A bug caught in a
  stretch reached by a declared setup (e.g. the game's own F1 jump) counts as caught when the
  bug's code is on that setup's path, and is marked "via setup". Checked for c2: the F1 jump
  to "wheel" and the real landing both call `Camper.snap_wheel()` (`DevMenu.gd:839`,
  `RampJump.gd:394`) and the HUD line is shared, so P6 / P7 count. A bug living only in the
  landing's own code (`RampJump._land`) would not be on that path: there only a played landing
  counts. The referee runs the practice patches on `ramp,c2_more`, so the played landing is
  exercised too whenever `t_ramp` lands.
- **R14 S1 spread for a method that doesn't own the driver (c2's question 2).** c2 is scored
  on the spread `t_ramp` gives by itself (logged per run: lip speed, offset, where it parks);
  the 61-68 km/h spread S1 asks for is **not reached** and stays a recorded limit, to be met in
  the final exam by whichever driver the final method uses. Not a fail for c2, not a pass of
  the spread either.
- **R6 Brief correction.** Walk `expect`s run alongside the steps only when marked
  `watch` (`dev/LiveControl.gd:485-501`, found by both auditors); the brief said all do.

## Change log
- 2026-11-06, referee: c2 scored (24 runs). Found: P6's patch shows either way (the hub turns with the wheel); a stuck test step is unseen by c1's rig.
- 2026-11-06, referee: R13, R14 (c2's two questions), before scoring c2.
- 2026-11-06, referee (second referee thread): R12 before c2 (state checks behind a driver that
  reaches the end 7 / 11 times). The user chose: c2 next (A), report and keep going (A).
- 2026-11-05, referee: g1 failed qualification; R9-R11.
- 2026-11-05, referee: c1 scored; R8 (c1 fit for reuse).
- 2026-11-05, referee: R7 added after round 2 (asked by Claude); top 4 agreed, `top4.md`.
- 2026-11-05, referee: rulings R1-R6 added after Stage 2 round 1 (asked for by both auditors).
- 2026-11-05, referee: practice patches written and proved (P4's first version put the rubble 1.5 m off the crate's spot and broke nothing: moved onto it).
- 2026-11-05, referee: written before Stage 1. Piers (P-) dropped from the
  practice set: the bridge they belonged to is cut from `g12`.
