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

## Trial scores

| Trial | Branch | S1 false alarms | S2 bugs caught / named | S3 blame | S4 doing nothing | S5 real path | S6 cost | S7 other puzzle | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| c1 | `g13-trial-c1` | | | | | | | n/a | |
| g1 | `g13-trial-g1` | | | | | | | n/a | |
| c2 | `g13-trial-c2` | | | | | | | n/a | |
| g2 | `g13-trial-g2` | | | | | | | n/a | |
| Final | | | | | | | | | |

## Change log
- 2026-11-05, referee: practice patches written and proved (P4's first version put the rubble 1.5 m off the crate's spot and broke nothing: moved onto it).
- 2026-11-05, referee: written before Stage 1. Piers (P-) dropped from the
  practice set: the bridge they belonged to is cut from `g12`.
