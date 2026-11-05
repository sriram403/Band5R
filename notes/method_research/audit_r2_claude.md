# Stage 2, round 2: the Claude auditor

Written 2026-11-05 by the Claude auditor. Read: the brief, the scoreboard with rulings R1-R6,
both ideas files, my round-1 audit, **GPT's round-1 audit** (`audit_r1_gpt.md`, answered here),
the two skills (testing-and-verification v8, first-principles-solving v6), and the code cited below.
I did not open `audit_r2_gpt.md` or the practice patches. No game or test was run.

Every claim has a file:line, a scoreboard number, or says **"I think"**. Paths are from `MPG_dev`.
GPT's attacks are quoted by the idea they hit (C1-C7). GPT's evidence keys (H, V, X, U, ...) are
GPT's own, from `audit_r1_gpt.md:13-31`.

---

## 0. New evidence I found this round (used below)

| # | Fact | Source |
|---|---|---|
| N1 | **Keyboard steering is on / off.** P1's steer input is -1, 0 or +1; the game itself ramps the wheels towards it at `STEER_SPEED` 3.4 x lock per second, lock shrinking with speed (0.55 rad stopped, ~0.24 rad at 66 km/h). | `InputDevice.gd:346`, `Camper.gd:16-19`, `:1042-1045` |
| N2 | So **AutoDriver's full A / D presses are what a keyboard player does.** Smooth "proportional" steering for P1 can only be tapping, or a pad driver (`InputDevice.gd:341-345`). The van's `debug_steer` (`Camper.gd:1009`, `:1015`) is a dev hook, not input: using it would be a set-state. | same |
| N3 | **The HUD can't show PUNCTURE while `wheel_off` is true** in the clean game: the warnings are one `elif` chain, `wheel_off` above `tyre_flat`. | `PlayerHUD.gd:355-367` |
| N4 | **The crate's spot is the game's own data,** not a test coordinate: `_window` (the shutter's middle) and the build comment "under the window is where the crate goes". | `RampJump.gd:56`, `:230`, `:249` |
| N5 | **`ramp_retry`'s fast try does follow the game's reset** (no `ramp_start` between slow and fast), **but P2 is put across the river by code** before it, and `ramp_start` runs between cycles. | `PlayTest.gd:12092-12100` (P2 moved at `:12096`), `:12122` |
| N6 | **`ramp_try` releases the handbrake by code** (`set_parking_brake(false)`). A player does it with the handbrake key (`just_pressed("handbrake")`). | `PlayTest.gd:11585`, `Camper.gd:1016` |
| N7 | The player has **no step-up logic**, only `floor_snap_length = 0.5`. A shape cast through a doorway is close to, but not the same as, `move_and_slide`. | `PlayerRig.gd:171` |
| N8 | The game's own reset **clears swimming and moves unseated players beside the van** (so after a reset, "not swimming" is a game outcome, not a test precondition). | `RampJump.gd:621-629` |
| N9 | The brief: "**Don't change the game to suit a test.**" | `TEST_METHOD_RESEARCH.md`, "Rules that must not be broken" |

---

## 1. GPT's attacks on my ideas, answered

### C1, the rig layer

| GPT's attack | Answer | Evidence that decided it |
|---|---|---|
| "Nobody swimming" as a precondition would call P3 a test problem and erase a real bug. | **Concede.** Preconditions apply only to state the test set up before the boundary. Anything produced by play after it (a reset, a swim) is a game observation. | N8: the game's own reset owns the swim state. Scoreboard P3: still swimming after the reset. |
| A player walking into the P2 sill fails "W moves the player 0.2 m in 1 s": false alarm, wrong blame. | **Concede.** My Stage 1 C1 labelled a failed body effect as TEST. With P2 on, that turns a real game bug into a test problem. **Fix:** only "the input reached the intended device" can say TEST. What the body did is a game outcome. | testing-and-verification v8, line 31: requested / accepted / applied are separate layers. Scoreboard P2: stuck 2.2 m short. |
| `held(action)` is not movement readback on a pad. | **Concede.** Pad movement is read from the axes, not the button table. Readback for a pad player must read the axis channel. | `InputDevice.gd:257-260` (buttons) vs `:275-279` (axes). |
| A fresh heartbeat with no world progress isn't progress. | **Agree, with a split.** Health = physics frames advancing (c1). Progress on a task = the checker's job (g1). Mixing them gives false alarms on legal still moments: the 2.4 s fade (`RampJump.gd:605`, `:631`), the 7 s hold-E refit (`PlayTest.gd:11916`). | as cited |
| A wrapper counter can't see raw setters; S5 isn't earned by counting SET lines. | **Agree.** I said so in Stage 1 (`ideas_claude.md:130-132`). I now **delete** the SET counter from c1: the referee reads the code for S5 anyway (scoreboard S5), so the counter is a second, weaker copy of that read. | the algorithm: delete what isn't needed |
| S3 3/3 holds only for parse errors, exact accounting and explicit pad loss; a stale but valid expression passes. | **Concede the scope.** c1 claims T2 only for a missing node or a parse / run error. A valid expression that reads the wrong thing is outside c1 and reported NOT PROVEN. | `LiveControl.gd:129-136` returns errors, not wrong values |
| S4 needs a host deadline, not an end-only count. | **Agree;** c1 below has one (host polls every 2 s). | brief: "if this froze right now, would I hear?" |
| The slow-try and 20 m controls on every run add cost. | **Concede, and one more reason:** a slow miss before every run goes through the game's reset, the very thing P1 breaks. A per-run control would mix with the bug it sits next to. **Fix:** run controls once, as rig qualification. | `RampJump.gd:619` (reset puts the brake on) |
| 2-4 h is beyond the cap. | **Agree.** One-hour slice in section 5. | `ideas_claude.md:136-137` |

### C2, causal comparisons

| GPT's attack | Answer | Evidence |
|---|---|---|
| Two drivers can share a bad policy; "all fail -> GAME" is wrong blame. | **Already conceded in round 1** (now "inconclusive"). | `audit_r1_claude.md:277` |
| "Other driver passes -> TEST" is wrong blame: driver B may land by avoiding a real edge. | **Concede, and I found why it is worse than GPT said.** AutoDriver's on/off steering is exactly a keyboard player's input (N1, N2). If on/off steering up to the lip makes a 66 km/h jump miss, that is a **finding for the user** (a keyboard driver can miss at full speed), not a test fault. **Fix:** a flip says "the outcome depends on factor X (n of n)". A cause is named only when the mechanism is seen (launch vector, brake readback, contact). | N1, N2 |
| P2 out of the van + no can = two factors at once. | **Concede.** One factor per pair. | `ideas_claude.md:162` |
| Fresh setup changes many inherited states at once. | **Concede.** "Fresh vs after the reset" is a bundle; a flip there says "state matters" and needs a second pair to say which state. | `ramp_start` sets ~10 things, `PlayTest.gd:11555-11573` |
| `ramp_retry`'s four landings moved P2 by code; they don't isolate a load effect. | **Concede in part.** True: P2 is teleported across the river (N5). But the fast try does start from the game's own reset (N5), so "lands 4 / 4 straight after a miss" still holds for that start. What it can't do is clear or blame P2's seat. | N5 |
| V4 uses `MPG`: forbidden. | **Concede. V4 deleted.** | brief: "Don't touch `MPG`" |
| A diagnostic retry can't wash out an S1 failure. | **Agree.** The first failure stands; diagnosis is reported beside it. | scoreboard S1 |
| Fresh-start success alone doesn't name the handbrake. | **Agree.** P1 is named only with brake readback **off** plus drift with no input. | scoreboard P1 (brake off, 3.79 m) |
| ~2 min omits instrumentation and the second driver. | **Agree.** Under R1 the second driver is g1's, reused only if it passed its own controls; that is one reason the comparisons should run last (section 4). | R1 |

### C3, the state checks

| GPT's attack | Answer | Evidence |
|---|---|---|
| P3's 0.57 m brake-on drift trips the reset rule and gets named P1. | **Concede.** As written (0.5 m in 2 s, `ideas_claude.md:241-242`) it fires on 0.57 m and points at the reset. **Fix:** the rule reads the brake and reports it. Brake off + drift = names the reset's handbrake (P1). Brake on + drift = "van moved 0.57 m with the brake on; cause not named". P3 is named by the swim rule. | scoreboard: P1 3.79 m brake off; P3 0.57 m brake on; clean 0.04 m |
| "7 / 7 caught and named" is unsupported. | **Concede.** New claim: **7 caught, I think; 6 named, I think**; P3 vs P1 named only once a P3 run shows which lines fire. | the P3 knock-on |
| A ray from the ramp to the wreck can hit a rail. | **Partly rebut, then delete.** The only side parts are 0.16 m `RampLip` strips (`RampJump.gd` ramp build, `Build.box(Vector3(0.12, 0.16, ...), "RampLip")`); an eye-height ray clears them, I think. But "the player can see it" is R2's player-view obligation, not mine to fake with a ray. I keep only **"the wreck's top is above the water"**, which is what P5 breaks (1.88 m under). "Seen from the ramp" is reported NOT PROVEN. | R2; scoreboard P5 |
| A doorway shape test isn't walking: false pass for P2. | **Concede.** The player has no step-up logic, only floor snap (N7), so a cast and `move_and_slide` can disagree. **Fix:** a short real walk. Declared setup: door open, P1 2 m outside. Proven: P1 crosses the door line on W alone within 4 s. That is how the referee proved P2. | N7; scoreboard P2 |
| Rubble near the spot doesn't prove the crate can't be placed. | **Rebut.** The bug *is* "rubble where the crate goes". The referee's own proof of P4 is a distance (1.94 m clean, 0.00 m bug), and the spot comes from the game's own `_window` (N4), not a test coordinate. A crate-sized box at that spot overlapping a solid names the rubble. It does **not** prove the leg-up fails, and I don't claim that. | scoreboard P4; N4 |
| A hot van legally shows other warnings; "ON THE HUB at every instant" false-fails. | **Rebut: that's not my rule.** Mine is "`wheel_off` -> the HUD is **not** PUNCTURE" (`ideas_claude.md:230-231`). And the HUD can't show PUNCTURE while `wheel_off` is true (N3). **My own fix:** compare the HUD text with the *physical* front-left wheel (mesh at the hub or not), not with the flag, so a bug in the flag can't hide. | N3 |
| "Nothing below the terrain" needs a scope for the half-sunk wreck. | **Agree on scope; no conflict.** The ground rule covers the hubs and carryables, not the wreck. The wreck has its own rule (top above the water; clean 0.41 m above). | scoreboard P5 |
| S1 9 / 10 is a fail. | **Agree.** That was my "before tuning" guess. The referee's clean / bug numbers now give real margins (table in section 3); S1 measures it. | scoreboard P1-P7 |
| S4 can't come from a monitor inside the frozen tree. | **Agree;** I never claimed it (`ideas_claude.md:280`: N1 / N2 "partly"). S4 is c1's, marked "via c1" (R1). | R1 |
| 5 Hz cost unmeasured. | **Agree.** c2 logs its own frame time. | — |
| Keep it test-side; drop "always on in every user play". | **Concede.** Two pieces of evidence: the brief forbids changing the game to suit a test (N9), and R3 says the user's play is not a per-run resource, so "runs in the user's play" earns no score. I delete it. The checks live in a test-side observer that reads state and moves nothing. | N9, R3 |

### C4, C5, C6, C7

| Idea | GPT's attack | Answer |
|---|---|---|
| C4 | "61 and <= 1.5 m -> lands" is a rule the design never made; the baseline (66.5, 1.05 m, missed) breaks it. | **Agree;** already dropped as a method in round 1. The baseline is a counterexample to my rule, not a game bug. Also concede: `ramp_try` releases the brake by code (N6), so reusing it isn't input-only play. |
| C5 | The game's `cross` is done within 60 m of `j3`: proximity, not departure. | **Concede.** Checked: `Story.gd:99-101`. My C5 "judged only by the game's own goals" would pass a van that reached 60 m and circled. Departure needs GPT's signed progress + road occupancy + a stop. |
| C5 | Bot budgets may exceed 60 s: fails S4. | **Agree;** S4 comes from c1. |
| C5 | Full co-op actor in an hour. | **Agree it doesn't fit**; I said so in round 1 (`audit_r1_claude.md:97-98`). |
| C6 | Two agreeing judges isn't ground truth; one "no" shouldn't page the user. | **Concede both.** Correlated calls measure agreement, not accuracy. |
| C7 | Drop the reference. | **Agree;** already dropped. Also `notes/TODO.md:10` records the user's "no reference recording". |

---

## 2. GPT's round-1 facts and arguments, checked

| GPT's claim | Checked | Verdict |
|---|---|---|
| H: `cross` is done within 60 m of `j3`; entering it proves the repair, not departure. | `Story.gd:96-101` | **True.** |
| V: start failure, steam and heat outrank the wheel warning. | `PlayerHUD.gd:355-367` | **True as code; the use made of it is wrong** (aimed at a rule I didn't write; see C3 above, N3). |
| X: `ramp_retry` moves P2 by code and calls `ramp_start` between cycles. | `PlayTest.gd:12092-12122` | **True, but incomplete:** inside each cycle the fast try starts from the game's reset (N5), so "lands straight after a miss" still stands. |
| U: buttons and pad axes are different channels. | `InputDevice.gd:257-279` | **True.** |
| A: `ramp_try` releases the brake directly. | `PlayTest.gd:11585` | **True** (N6). |
| R: the reset zeroes the van, puts the brake on, clears swimming, moves unseated players. | `RampJump.gd:606-630` | **True.** |
| C: a seated collider is off; stowed cargo is frozen with no collision. | `PlayerRig.gd:1916`, `Carryable.gd:212-217` | **True** (my Stage 1 fact 2 too). |
| M: the user said "no reference recording". | `notes/TODO.md:10` | **True.** |
| g1 spec: "proportional steering ... sent through the existing control transport". | N1, N2 | **Gap in GPT's spec.** P1's keyboard can't send a proportional value. The builder must either tap (pulse) the keys or drive with a pad; `debug_steer` is a set-state and must be banned. GPT did write "if the transport can't represent it, report it", so this is a gap, not an error. It should be settled before the build, not found during it. |
| g2 (G6) "needs a real-input operator or an audited actor; none established". | R3 | **True, and now decided by R3:** no human. G6's player half is gone; what's left is C6's judge on frames from whatever actor exists. That changes the disputed slot (section 3). |
| "C3 overlaps G1's checker." | GPT's g1 spec, `audit_r1_gpt.md:146` | **True for P1 and P3 only:** g1's checker already reads the brake, drift and swim state after a miss. The rest of C3 (P2, P4, P5, P6, P7) has no twin in g1. |

---

## 3. The disputed slot: C3 (state checks) vs G6 + C6 (evidence judge)

### What changed since round 1
R3 removed the human player. GPT's G6 said "delete the automated player initially. A tester plays"
(`ideas_gpt.md`, idea 6). Without a tester, G6 becomes C6: a model judge looking at frames from
whichever audited input-only actor exists. In the hour, the only such actor is g1: **jump, miss,
reset, landing, drive-off; no hut** (both of us agree the hut won't fit). R2 adds: a "the player can
see it" item needs a player's view reached by play.

So the real question is narrow: **who covers the bugs g1's checker doesn't, i.e. P2, P4, P5, P6,
P7: numeric state checks or a model judge?**

### In scoreboard order

| Check | C3, test-side (revised above) | G6 + C6 judge, actor = g1 | Edge |
|---|---|---|---|
| **S5 gate** | Moves nothing. Static checks read the world as built; the one walk (door) has a declared setup. Bugs on the jump / landing ride on g1's real path. | Watches only. But every hut view (crate placement, leg-up, door, bolt) needs an actor in the hut: none in the hour, so NOT PROVEN (R2, R5). | Tie on the gate; C3 reaches more of the stretch. |
| **S4 gate** | Neither alone (in-tree monitor freezes with the game). Via c1 (R1). | Neither alone (judges after the run). Via c1. | Tie. |
| **S1** | Thresholds with measured margins (table below). | One model call per run on frames; misread rate **unmeasured by anyone**. Under GPT's own rule an "unchecked" item is unsuccessful (`ideas_gpt.md`, common minimum), so one blurry frame on a clean run fails S1. | **C3**, I think; S1 measures both. |
| **S2** (practice, under R5) | P2 (walk), P4 (spot), P5 (height) need no actor; P6, P7 on g1's landing; P1, P3 on g1's miss (or via g1's checker). **7 caught I think, 6 named I think.** | P3, P6, P7 reachable on g1's run; P5 only if a player's view from the ramp shows the wreck; P1 isn't visible (GPT: "named from physical reset trace", i.e. a state check); P2, P4 in the hut: not reached, **not caught** (R5). **3-4 at most, I think.** | **C3.** |
| **S3** | 0 alone. | 0 alone (GPT: T1 needs device events, not pictures). | Tie. |
| **S6** | ~0 per run; no tokens. | One judge call per run: S1's 10 + S2's 7 + S3 / S4's 7 = **24 calls** for scoring alone. Tokens per call unmeasured (my C6 guess 50-150k; GPT's G6 guess 4-12k). | **C3.** |
| S7 / final exam | Generic rules carry; declared ones must be written per puzzle. Risk: secret bugs outside every rule. | A judge with a general sheet might see an odd thing nobody wrote a rule for. **This is the judge's one real advantage, and it is unmeasured.** | Judge, maybe. |

The margins C3 would run on (the referee's own numbers, `scoreboard.md`, "Proved by the referee"):

| Rule | Clean | Bug | Fires at | Margin |
|---|---|---|---|---|
| After the game's reset: drift with no input; brake read and reported | 0.04 m in 5 s | 3.79 m, brake off (P1) / 0.57 m, brake on (P3) | > 0.3 m in 5 s | 7x over clean |
| Swimming while standing on dry ground > 1 s | on foot | still swimming (P3) | 1 s | on / off |
| Crate-sized box at the spot under `_window` overlaps a solid | nearest rubble 1.94 m | 0.00 m (P4) | any overlap | 1.94 m |
| Wreck's top above the water | middle 0.41 m above | 1.88 m under (P5) | top below water | > 2 m |
| Hub bottom vs the ground under it, steady 0.5 s after settling | -0.01 m | -0.19 m (P6) | < -0.08 m | 0.07 m / 0.11 m: **the tightest; S1 will tell** |
| HUD warning vs the *physical* front-left wheel | "ON THE HUB" | "PUNCTURE" (P7) | PUNCTURE text with no wheel at the hub | on / off |
| Door: P1 walks in on W from 2 m out (declared setup) | walks in | stuck 2.2 m short (P2) | not across the line in 4 s | 2.2 m |

Honesty note: I wrote these after reading P1-P7. Each rule is tagged **generic** (drift after a
reset, swim on dry ground, below the ground, HUD vs physical state) or **declared** (crate spot,
wreck height, door walk), and the two are counted apart, so overfitting shows. The final exam's
secret bugs test the generic half.

### Is there a real merge?
I looked for one, and found one piece that's real and one that would be a compromise:
- **Real:** each C3 finding saves one observer-camera shot of its object at that moment (R2 allows it
  as evidence). That's "debug with pictures" for the user, at no model cost. It isn't G6: nobody
  judges the picture; the number decides.
- **Not real:** adding a model judge "for the rest". In the hour it has nothing the actor can reach
  that C3 doesn't already check, and it brings the S1 risk and the 24 calls. That's two methods
  stapled together to end an argument.

### Ruling (my position)
**C3, test-side and revised, takes the slot.** It wins S2 and S1 on measured margins (vs an
unmeasured judge) and S6, and ties on both gates. **G6 + C6 is the first reserve for Stage 4:**
if the secret bugs turn out visual and C3's generic rules miss them, the judge gets its chance
there, with a calibration first (measurement in section 6).

---

## 4. Who runs the causal comparisons: GPT (g2)

1. **It follows from the slot.** C3 is my idea and I build it as c2. Each model runs two; that leaves
   g2 = the comparisons. Nothing in GPT's round 1 says why *I* should run them, beyond the slot.
2. **Order makes them cheapest last.** Under R1 a trial reuses only parts that passed their own
   checks. The comparisons need three parts built earlier: c1's health (so a paused rig isn't read
   as a cause), **g1's second driver** (the other half of the steering pair), and the brake / swim
   readbacks (g1's checker, c2's rules). Run as c2, they'd be built before c2's rules exist and would
   rebuild them inside the hour.
3. **It fits GPT's role.** It's mostly a specification: a pair table, one factor per pair, verdict
   rules, a stop rule. Little game code; the Opus builder has little room to guess. G4 is also the
   idea GPT guarded best ("unmatched = inconclusive", which I adopted).
4. **Independence.** The auditor who didn't build c2 then uses c2's readbacks to name P1 vs P3, so
   c2's claims get checked by the other side, not by me.

---

## 5. My final top 4 (trial order)

| Trial | Runs | Method |
|---|---|---|
| c1 | Claude | The rig layer (C1 + GPT's common minimum) |
| g1 | GPT, Opus builds | Sensed driver + independent checker (G1 + C5), jump and drive-off |
| c2 | Claude | State checks, test-side (C3, revised) |
| g2 | GPT, Opus builds | Bounded causal comparisons (C2 + G4) |

### c1: the rig layer
- **Smallest 1-hour version:** an observer that keeps running while paused writes one flushed line a
  second (run ID, scene number, physics-frame counter from a normal pausable callback, paused, pause
  note, P1 / P2 present and device kind, scenario, step). A host watcher polls every 2 s: frames
  stopped 10 s, records stopped 10 s, an unexplained pause, or a missing player -> stop and say why;
  a pad-lost note -> **TEST: P2's pad lost, the game correctly paused**. Asked scenario IDs written
  before launch, compared by ID at each scene reload and at the end. A plan with work after `save`
  is refused. `wait` / `until` refuse an unexplained pause. Before a P2 action: P2's device is a pad
  and the input reaches it (axes for movement, buttons for actions). A missing node is a test problem.
  Qualification: T1-T3 and N1-N4 planted once each. **No per-run physical controls, no SET counter.**
  Budget: build 40 min, qualification 20 min.
- **Claims to prove:** the run was alive, complete and in control (S3: T1, T3, T2 for missing nodes
  and parse / run errors; S4: N1-N4 within 12 s, I think).
- **NOT PROVEN:** anything about the game (S2 = 0 by design; S1 neutral); a valid expression that
  reads the wrong thing; whether the body did what the input asked (that's a game outcome).

### g1: sensed driver + independent checker
- **Smallest 1-hour version:** GPT's spec (`audit_r1_gpt.md:144-146`) cut to driving, reusing c1.
  Two fixes I'd ask for before the build: (a) the steering channel: tapped keys or a pad driver,
  never `debug_steer` (N2); (b) the handbrake released by its key, not `set_parking_brake` (N6).
  Order inside the hour: the jump stretch first (from the declared F1 ramp setup), then the drive-off.
  Swept body-width check if time allows; without it the drive-off may hit E2's tree, and that is
  reported, not hidden.
- **Claims to prove:** the run-up, the jump (landed or missed, from the launch vector at the last
  wheel contact), the game's reset after a miss (brake readback, drift, swim state), the retry, and
  if reached, the drive-off (30 m signed road progress, last 3 s on the road, a stop by input).
- **NOT PROVEN:** the whole hut (crate, leg-up, bolt, door, toolbox, refit: a declared setup before
  the drive-off); anything a player must see; P2, P4, P5, P6, P7 unless c2 runs on top (R5).

### c2: state checks, test-side
- **Smallest 1-hour version:** a test-side observer, moving nothing, with the seven rules in the
  table in section 3, each tagged generic / declared, each finding saving one observer shot (R2).
  It rides on g1's actor if g1 passed its own controls (R1), else on a declared jump prefix with the
  two fixes above; the reach path is audited for S5 either way. P3's swimmer is put in the river as
  a declared setup before a real-input slow miss; the proven part is the game's reset. Budget: rules
  and door walk 40 min, clean qualification runs 20 min. Logs its own frame time.
- **Claims to prove:** no broken state on the stretches the actor really reached (miss, reset,
  landing), and the built world as placed (crate spot, wreck, door passable on foot).
- **NOT PROVEN:** that any stretch *completes* (it's not a player); the crate placed and the leg-up
  done by players; that a player *sees* the wreck or hub (R2); the drive-off; secret bugs outside
  every rule (the final exam measures that, generic and declared counted apart).

### g2: bounded causal comparisons
- **Smallest 1-hour version:** on the baseline miss (B0) first: **V0, the same again, 3 times**
  (`ramp.out:26-84`: slow tries differ by 0.17-0.22 m, so 2 isn't enough near an edge). Then, one
  factor per pair, at most three pairs: AutoDriver vs g1's driver from the same start; P2 seated vs
  not (nothing else changed); the game's reset vs a fresh F1 start (labelled a bundle). Then the P3
  knock-on: swimmer beside the van vs not, with brake readback. Every try logs the same launch
  vector at the last wheel contact. Reuses c1, g1, c2 (R1, "via").
- **Claims to prove:** which listed factor the failure depends on, n of n, with the mechanism named
  only when seen. P1 vs P3 told apart by brake readback.
- **NOT PROVEN:** anything about passing runs (S1 belongs to the method that played); any cause
  outside the listed factors ("inconclusive"); whether a driver-dependent miss is a test fault or a
  game finding: on-off steering is a keyboard player's real input (N1), so that goes to the user;
  P2, P4, P5, P6, P7 (nothing to compare: not caught under R5).

---

## 6. Still disputed, and what would settle it

| # | Dispute | My position | Settling measurement |
|---|---|---|---|
| D1 | The slot: C3 or G6 + C6 | C3 (section 3) | Referee's call by the scoreboard. If wanted before Stage 3 (cheap, I think 15 min, no new build): show a judge the referee's existing clean / bug shots for P4-P7 with labels hidden, plus 5 clean shots; count hits, misses and false "no"s. Against C3's margins above. |
| D2 | Who runs the comparisons | GPT (section 4) | Follows from D1. |
| D3 | Do C3's generic rules reach secret bugs? | Some, not all, I think half (`ideas_claude.md:263`) | Stage 4: secret bugs counted against the generic rules only. If they miss most, the judge comes in. |
| D4 | P3 vs P1 naming | Fixed by brake readback | One P3 run on c2: which lines fire, and what they say. Pass = swim rule names P3 and the drift line names no cause. |
| D5 | The hub rule's 0.07 m margin | Holds with a 0.5 s steady window, I think | S1's ten clean landings: log the hub's minimum each run. |
| D6 | Static checks under S5 | They prove a property of the built world, not a stretch of play; claimed as such | **A referee ruling is needed:** does a check of the world as built count as "reached by play"? I say it reaches nothing, so S5 has nothing to forbid, and R5 scopes the claim. |
| D7 | g1's steering channel | Tapped keys or a pad driver; `debug_steer` banned | GPT's spec update before the build; the referee's S5 read of g1's code. |

## Decision log
- v2 (this file), 2026-11-05. Changed my mind, with the evidence that did it:
  C1 preconditions and body-effect labels (N8, skill v8 line 31, scoreboard P2 / P3);
  C1 per-run controls dropped (they cross the reset P1 breaks); SET counter deleted (the referee's
  read already does it); C2 "other driver passes -> TEST" removed (N1, N2: keyboard steering is
  on / off); C2 V4 deleted (brief); C3 reset rule reads the brake (scoreboard P3 knock-on);
  C3 door shape test replaced by a real walk (N7); C3 wreck ray deleted (R2); C3 moved test-side
  (N9, R3); C3 S2 claim cut to 7 caught / 6 named; C5's game-goal judge wrong for departure
  (`Story.gd:99-101`).
  Held, with evidence: C3's P4 rule (scoreboard P4 is a distance; spot from `_window`, N4); C3's
  HUD rule (N3: GPT attacked a rule I didn't write); `ramp_retry`'s post-reset landings (N5).
