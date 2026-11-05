# The top 4 (Stage 2 result, 2026-11-05)

Agreed by both auditors in round 2 of 3 (`audit_r2_claude.md`, `audit_r2_gpt.md`),
with no referee pick needed. Trial order: c1, g1, c2, g2 (brief, Stage 3).

| Trial | Run by | What it is | Merged from | Claims to prove (R5) | Reports NOT PROVEN |
|---|---|---|---|---|---|
| **c1** | Claude (builds it) | **The rig layer.** A heartbeat watched from outside (physics frame count, scene generation, pause), scenarios asked vs ran by ID, a pause guard in `wait`/`until`, expressions checked before the run, and a check that each input reached the intended player's device. Pad movement read from the stick axes. Only "the input never reached the device" may say *test problem*; a body that doesn't move is a game outcome. | C1 + GPT's common minimum (G0) | That a run was alive, in control and complete | Anything about the game |
| **g1** | GPT (specifies), Opus builder | **A sensed-input driver with an independent checker.** The driver steers from the road and ramp geometry and the van's pose, through real inputs only (key taps or the pad; the van's dev steering setting is banned). A separate checker records inputs, wheel contacts and ramp-frame motion, and judges actual crossing, reset and departure (signed progress along the road, not distance from the start). | G1 + C5 | The jump, a miss and its reset, the retry, the drive-off | The hut stretch (set up by code) |
| **c2** | Claude (builds it) | **State checks.** Seven rules on the game's own state with clean-vs-bug margins measured, general rules and rules written for the practice set counted apart, one saved picture per finding. The van-moves-after-reset rule reads the handbrake (so P3's drift isn't blamed on P1); the door check is a short real walk on W, not a shape test. Lives in the test, not the game. | C3 (narrowed by GPT's attacks) | That the state is right where each rule looks | That any stretch completes; what a player can see |
| **g2** | GPT (specifies), Opus builder | **Causal comparisons.** First the baseline's flat-out miss repeated 3 times; then at most 3 pairs that change exactly one factor; then the P3 swimmer pair. A cause is named only when its mechanism is seen in the records; otherwise "inconclusive". No automatic all-fail = game / other-driver-passes = test table. | C2 + G4 | Game or test, for the failures it's pointed at | Anything it isn't pointed at |

## How it was chosen
- **Agreed from round 1:** c1 and g1 (both proposed them).
- **The disputed slot: C3 (the game checks itself) vs G6 + C6 (a judge over video of real play).**
  Ruling R3 removed G6's human player; in the hour the only real-input player is g1's, and
  it never reaches the hut. GPT conceded in round 2 and chose C3. Claude's case, in scoreboard
  terms: a tie on S5/S4, measured margins vs an unmeasured misread rate for S1, more of the
  practice set covered for S2, no model tokens per run for S6.
- **Who runs the causal comparisons:** GPT (g2), agreed by both: mostly a written plan, suits
  GPT's no-code role, and running last it reuses c1's health layer and g1's driver (R1).

## Merged (true duplicates, same mechanism)
- C1 = G0 (the health layer) -> c1.
- G1 = C5 (the goal-seeking player) -> g1.
- C2 = G4 (paired comparisons) -> g2.
- C6 = G6's judge half -> held as **first reserve** for the final exam, if the secret bugs
  turn out to need a visual judge.

## Dropped, and why
| Idea | Why (who argued, accepted by the other) |
|---|---|
| C4 the envelope | Its landing envelope invents a guarantee nobody proved (GPT). It survives as the S1 test plan: vary speed and lane. |
| C7 / G2 the user's play as a reference, input playback | Only the user can record one; the user's time isn't a per-run resource (R3). |
| G3 live action search | 4-8 h to build; routes round the P2/P4 bugs by design (Claude). |
| G5 screen-driven control | 6-12 h; the ramp's problem is the steering, not the sensing (Claude). |
| G6's person-plays half | No operator (R3); conceded by GPT. |
| G7 short motion planner | 6-10 h; a fitted van model can learn its way round regressions like P1 (Claude). |

## Concessions that changed the four (evidence-driven, both sides)
- Claude: setup checks only for state the test set; "body didn't move" is a game outcome;
  "another driver lands -> test wrong" removed (keyboard steering is all-or-nothing,
  `InputDevice.gd:346`, so full presses are what a keyboard player does); the old-commit
  comparison removed (it needs `MPG`); C3's claim cut to "7 caught, 6 named (I think)";
  the game's "cross" goal can't prove a drive-off (60 m proximity only).
- GPT: the full-route build estimate withdrawn; the human-operated G6 withdrawn; drift
  alone can't name P1; shared health is charged once.

## Still disputed (each has its settling measurement; the trials take it)
| Dispute | Settled by |
|---|---|
| Do c2's general rules (not the practice-set ones) catch the secret bugs? | The final exam |
| P3 vs P1 naming | One P3 run on c2: which lines fire |
| The hub rule's 0.07 m margin | The ten clean runs |
| The baseline miss's cause | g2 |
| The g1 driver's build time | g1's measured minutes |
| How the walk turns a broken expression into a boolean (false pass, or a hang?) | A planted T2 in c1 |
| The van's Euler order (body vs world pitch/roll) | A one-line check in g2 |

## Referee ruling R7 (asked by Claude in round 2)
A read-only check of the built world (probing geometry, reading the game's own state) reaches
nothing by play, so S5 has nothing to forbid in it. It may only claim what it reads ("the
crate's spot is clear"), never what a player can do or see there ("a player can stand the
crate there"). Those claims stay NOT PROVEN unless an actor reaches them by input.
