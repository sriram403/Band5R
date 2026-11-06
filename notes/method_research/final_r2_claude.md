# Stage 4, round 2: the Claude auditor's answer

2026-11-06. Read-only on `g12` `860e0af`. Read in full: `final_r1_claude.md`, `final_r1_gpt.md`,
`scoreboard.md` (R1-R15), `trial_c2.md` and `trial_g2.md` with the referee's scoring; the parts
of `trial_c1.md` / `trial_g1.md` the proposals cite. Code read at the SHAs named. Claims carry
evidence or "I think". **Where I moved, I name the evidence that moved me.**

## Summary

| # | Point | My r2 position | One line |
|---|---|---|---|
| D1 | Flat-out jump retries | **Hold the retry, concede the whole-run rerun** | Up to 3 tries in the same run, first try printed first, every miss in the headline line; no automatic rerun of a whole run (GPT is right that a rerun is a PASS by substitution) |
| D2 | Who owns reaching the state | **Hold, merged with GPT's honesty rule** | The method owns a frozen speed x lane table (keys only, an existing argument); each row qualified clean **before** the freeze; a row that fails is deleted before the freeze, never after; a spread that's still short is reported unmet |
| D3 | P6, the hub rule | **Concede the upper ground band; merge the mount rule** | GPT's axle-relative check with GPT's calibration formula, applied to the hub **and the tyres**; no two-sided world-height band |
| D4 | g2's recorder | **Merge, mostly GPT's way** | On during `ramp` (g2's existing scope, no new code), off for `c2_more` (measured deterministic); its rows feed no verdict; read only after a non-pass |
| D5 | Verdict words | **Merge** | GPT's GAME PROBLEM / FINDING (owner unresolved) split replaces my FAIL; I keep NOT HEALTHY and STALLED as words without blame; headline by **first cause in time**, not "TEST first" |
| D6 | (new) Headline order | **Hold** | First cause in game time wins the headline; everything else listed. "ERROR / TEST first" mislabels a game bug that cascades into a test error |
| D7 | (new) SCRIPT ERROR blame | **Hold, with GPT's middle word** | Raised in `scripts/dev/` -> TEST; raised in game code with no test frame on the stack -> GAME PROBLEM; raised in game code called by the test -> FINDING, owner unresolved |
| D8 | (new) `t_ramp`'s own checks | **Hold; GPT's text is unclear** | Every `t_ramp` check carries the verdict (a fail is a FINDING, owner unresolved) and sits in the frozen check-ID ledger; GPT's "inner PASS is advisory" must not mean a failed hut check can pass |
| D9 | (new) Missing field vs missing object | **Merge (new line)** | A member name / type missing = TEST (the test's model is stale); the member exists but holds null / freed / empty where the puzzle needs the object = GAME PROBLEM |
| D10 | (new) Drive-off check | **Concede to GPT** | No new drive-off check this hour; departure claimed only as the current check measures it, the rest NOT PROVEN |
| D11 | (new) Pad loss blame | **Concede to GPT** | TEST only when the test's own unplug is logged (c1's injection receipt); an unexplained pad loss is owner unresolved |

**Agreement in round 3: I think yes on D3-D11; D1 and D2 are the real fight**, and both turn on
one measured number (the clean miss rate below). If GPT has a measurement that changes it, I move.

---

## 1. Each dispute

### D1: flat-out jump retries. Hold the retry; concede the rerun.

**The number that decides it (I counted it from the trial reports):** on the clean game, today's
flat-out try at the `t_ramp` setup (0.3 s after the game's reset) missed **9 of 33**:

| Source | Flat-out tries | Misses |
|---|---|---|
| Baseline (`scoreboard.md`) | 1 | 1 (66.5 km/h) |
| c1's side data, 11 `t_ramp` runs (`scoreboard.md`) | 11 | 2 (57, 66.6) |
| c2 qualification q2, q4-q6 (`trial_c2.md`) | 4 | 1 (66.5) |
| c2 scoring S1, 10 counted (`trial_c2.md`) | 10 | 2 (66.4, 66.5) |
| g2 baseline B1-B3 + `g2_a0` x4 (`trial_g2.md`, referee's table) | 7 | 3 |
| **Total** | **33** | **9 (about 1 in 4)** |

(I left out g2's a1 / b / c arms: they changed the actor.) The cause is INCONCLUSIVE (g2 (a)):
the same 66.5 km/h lands and misses; the one chain seen (an on-ramp D tap) has a counter-example.

**What that does to each rule (I think; assumes independent tries, not measured, and g2_a0's 3 / 4
says they may cluster, which makes both worse):**

| Rule | A clean run passes the jump when | P(clean run passes) | P(S1 10 / 10) |
|---|---|---|---|
| GPT r1: one flat-out try, a miss is INCOMPLETE | the first try lands | ~0.73 | **~4 %** |
| Mine: up to 3 tries in the same run | any of 3 lands | ~0.98 | ~82 % |

GPT's own r1 predicts "whole-command PASS likely only 6-9 / 10". The scoreboard: "10 / 10 pass. One
failure = fail". So GPT's rule fails S1 by construction, on a game the user says works.

**Where GPT is right, and I move (evidence: R15 and the scoreboard's "false pass weighs more"):**
1. **The automatic whole-run rerun goes.** My r1's "rerun once after a driver-only INCOMPLETE" is a
   PASS by substituting a second run; it hides one drive-off or crate flake per run. Deleted.
2. **The first try is preserved and printed first** (GPT's "preserve the first attempt").
3. **A retry can hide an intermittent jump bug.** A secret bug that lifts the miss rate from 1 in 4
   to 1 in 2 passes a run 7 / 8 of the time under my rule (1 / 2 under GPT's). I accept that as a
   stated limit, and make every miss visible in the headline line, so a series shows it.

**Why I hold the retry:** a miss is a designed game outcome (the fade, "a long, wet hour and a tow
rope later", back at the run-up: `design/PUZZLE_CHANGES.md` "As built"), not a broken contract. The
contract the user plays is "a player who goes flat out lands", and a player who misses retries; the
game's reset is built for it. Each extra try also exercises the reset under G1. A deterministic jump
bug (a speed cap, a lower ramp) misses 3 / 3 and is named at the jump with the speeds, same as GPT's.
A miss at 66.5 km/h is not shown to be the game's fault, so it must not cost S1.

**The text I'd sign (D1):**
> The flat-out jump gets up to **3 tries in the same run**; tries 2-3 follow the game's own reset,
> as a player's would. Every try prints lip km/h, lane offset at the lip, landed / missed, in order,
> first try first. The headline line carries the count: "PASS (jump landed on try 2; 1 miss at
> 66.5 km/h, owner unresolved)". 3 misses = **INCOMPLETE: the jump did not land in 3 tries at
> <speeds>**, never PASS, never GAME PROBLEM. No run is ever rerun automatically. Across a series,
> the report sums tries and misses; the first-try land rate is printed apart, and a clean-game miss
> rate goes to the user as an open question (game or driver: not measured). Stated limit: a bug that
> makes the jump miss **sometimes** can pass a run.

### D2: who owns reaching the state. Hold, merged with GPT's honesty rule.

**Evidence the knob already exists and is keys-only:** `ramp_try(target, off)` at `PlayTest.gd:11579`
sets `ad.lane = off` (`:11584`) and drives with `ad.step(target)` (`:11595`): no state writes.
`t_ramp_bench` already drives it at 50-80 km/h targets (`:11653-11656`). Bench results
(`appdata/ramp_bench.out` lines 61-81, ramp 0.8 m): target 58 -> lip 56.7 missed; **62 -> 60.9
landed; 66 -> 64.3 landed; 80 -> 66.7 landed**.

**R14 decides who owns it:** the 61-68 spread is "to be met in the final exam by whichever driver
the final method uses". GPT's "carried as unmet" therefore fails S1's spread by design, not by
measurement. The change is a table lookup, about 10 lines (I think), not a new driver.

**Where GPT moved me (evidence: the bench line above, and g1's failure):**
1. My r1 row k0 (target 62) gives **60.9 km/h at the lip, under 61**: wrong. The low row becomes
   target **63** (lip about 61.8, I think, between the bench's 60.9 at 62 and 64.3 at 66).
2. Lanes are untested: g1's driver missed 2 m left at the lip (`trial_g1.md`), and today's driver
   already reaches the lip 0.76-1.18 m off the middle (`trial_g2.md` arm table, "x at lip"). A
   ±0.5 m lane could push that to ~1.7 m (I think). So **every row is qualified clean before the
   freeze**, and a row that doesn't land in 3 tries in its clean run is deleted before the freeze,
   with the reason. GPT's rule stands for what's left: a spread that's still short is reported
   unmet, never hidden.
3. **68 km/h isn't reachable flat out** (bench 66.7; c2 max 67.0; g2 max 66.89). I ask the referee
   to record the top of the spread as "flat out", measured.

**The text I'd sign (D2):**
> The method owns its driver's spread through a frozen table, chosen by `--fn-vary=k`, logged per
> run, keys only (`ramp_try(target, lane)`, existing code): **k0 63 / 0, k1 66 / -0.5, k2 80 / +0.5,
> k3 80 / 0** (today's). The builder runs each of k0-k2 once clean in qualification (these are the
> qualification's clean runs, no extra cost); a row that fails there is deleted before the freeze,
> with its numbers. If the rows left don't span 61 km/h to flat out, the spread is reported **unmet**
> (R14). The referee's S1 runs cycle the frozen rows. No row is added, removed or changed after the
> freeze.

### D3: P6, the hub rule. Concede the band; merge the mount rule.

**Evidence that moved me:** the source. `Camper.gd:750-752`: the bare hub is a cylinder at
`Vector3.ZERO`, added as a child of `_wheels[0]` ("on the wheel's node, so it rides the
suspension"). `Camper.gd:221-226`: each tyre sits at `Vector3.ZERO` inside a "Spin" holder that is
a child of its wheel. So by construction **every visible tyre and the hub are centred on their
wheel**, and the residual |part - wheel centre| is zero on a clean game, in every orientation. That
catches P6's rotating offset (sunk 1 / 5, floating 4 / 5, `trial_c2.md` scoring) every time, and a
floating part too. My upper world-height band then adds only a false-alarm risk (slopes, suspension,
no clean upper number in any record), which is GPT's point. Conceded.

**Where I hold:** the check covers **the tyres too**, not only the hub. A secret bug that moves a
tyre's mesh is the same class as P6; the cost is the same loop over `_wheel_meshes` (I think 3 lines).

**The text I'd sign (D3):**
> G3 has two checks while the van is parked 0.5 s. **(a) Lower band, unchanged:** a visible tyre's or
> the bare hub's bottom more than 0.12 m below the ground under it fires. **(b) Mount:** for each
> visible tyre mesh and the visible bare hub, the residual between its centre and its own wheel's
> centre, in the wheel's frame (all three axes recorded, the norm judged). Design centre: zero, from
> `Camper.gd:221-226, 750-752`, never from a sampled position. Tolerance = clean max residual +
> 0.01 m, measured on the unchanged game in the F1 state and every played landing in qualification;
> the clean max must be <= 0.01 m, otherwise (b) is reported unqualified, never widened. No upper
> world-height band; "the physical wheel floating above the ground" is NOT PROVEN. A test-only
> displaced-hub control must fire (b) before the freeze.

### D4: g2's recorder. Merge, mostly GPT's way.

**Evidence that moved me:** (1) the misses are once-offs at about 1 in 4 that a rerun can't summon
on demand (D1's table), so "turn it on afterwards" (my r1) loses exactly the run that needed it;
(2) g2's code already records only its `WATCHED` scenarios, `ramp` among them (`afb9e9b`
`G2Rec.gd:14`), so on-for-`ramp` is no new build time; (3) measured cost is small: per row p99
0.62-0.92 ms, flush max 1.8 ms, about 18 MB per arm (`trial_g2.md`).

**Where I hold:** off for `c2_more`. Its numbers repeat exactly run to run (each patch twice,
identical: `trial_c2.md`), so a rerun reproduces anything there; recording it is disk and nothing
else. And the rows must feed no verdict: g2 scored 0 / 2 as a detector, and a recorder that can
veto is a new false-alarm source.

**Unmeasured, said plainly:** whether the recorder changes frame pacing, which g2 lists as a
confounder of the miss (B1 ~46 process frames per 60 ticks vs ~75-90 in other arms). The builder
prints process frames per 60 ticks in every run, so the S1 series shows it.

**The text I'd sign (D4):**
> g2's recorder rows run during `ramp` (the played, non-repeatable stretch), off during `c2_more`;
> `FN_RECORD=0` turns it off, `FN_RECORD=all` turns it on everywhere. The rows feed **no verdict**;
> the events channel (OPEN / CLOSE, checks, validated-read errors) is separate and a failure there
> is TEST. Every run prints the recorder's per-row p99 and max, flush max, file size and process
> frames per 60 ticks. A model reads the rows only after a non-pass, once, offline; that cost is
> reported per reading. Any proposal to delete the recorder is made before the freeze, from the
> qualification numbers.

### D5: verdict words. Merge.

**Evidence that moved me:** my r1 FAIL carried two meanings behind one word ("owner: game, measured"
for a rule, "owner: not measured" for a scenario check). GPT's two words put the blame in the word
itself, which is what S3 scores. Taken.

**Where I hold, with the failure each prevents:**
- **No word that leans on blame without a measurement.** GPT's "TEST STALL" names the test. A game
  signal that never fires (a secret bug) stalls the step the same way as a minimized window (N5).
  So: **STALLED at <step>, owner not measured**.
- **NOT HEALTHY stays a headline.** GPT's r1 has no headline for a frozen or paused game or a missing
  player (N1-N3); they fall between "infrastructure invalid" (ERROR / TEST = test problem) and
  INCOMPLETE. A secret bug that pauses or freezes the game must not read "test problem". NOT HEALTHY
  says "this run proved nothing", owner not measured, except T1's logged unplug (D11).
- **NOT REACHED and NOT PROVEN are per-rule / scope lines, not headlines.** Both proposals agree in
  substance.

**The text I'd sign (D5):**

| Headline | When | Blame | Exit |
|---|---|---|---|
| **PASS (scope)** | nothing below; every asked scenario finished; every check ID ran; every declared rule looked >= 1 with 0 read errors; the jump's tries listed | none | 0 |
| **GAME PROBLEM: <thing>** | a rule fired on valid reads; a script error raised in game code with no test frame on the stack (D7); a required game object null / freed / empty (D9) | game, measured | 1 |
| **FINDING: <thing>, owner unresolved** | a `t_ramp` / scenario check failed; a script error in game code called by the test (D7) | not measured | 1 |
| **INCOMPLETE: <what's missing>** | check IDs missing ("stopped after <last>"); a declared rule never looked; the jump not landed in 3 tries | not measured | 2 |
| **STALLED at <step>** | a published step deadline passed; process killed and checked gone | not measured | 2 |
| **NOT HEALTHY: <what>** | no heartbeat 20 s; physics stopped 10 s; paused 5 s; a player missing; asked and not started | not measured (TEST only for a logged unplug, D11) | 2 |
| **TEST: <what>** | a validated read's member missing or wrong type (D9); plan broken (after `save`, unknown name); input not delivered; script error raised in `scripts/dev/` (D7); logged unplug; KILL FAILED | test, measured | 3 |

Per rule under every headline: looked n, errors e, value range, FIRED / ok / NOT REACHED. Scope and
the NOT PROVEN list on every run. R15 maps exactly: ERROR -> TEST, INCOMPLETE -> INCOMPLETE,
NOT REACHED -> a per-rule line, never a pass.

### D6 (new): which event takes the headline. Hold: first cause in time.

GPT r1: "Main status priority: ERROR / TEST, then ... GAME PROBLEM ..., then INCOMPLETE". Failure
mode, **wrong blame on a secret bug**: a game bug usually breaks things the test leans on later. E.g.
a bug that leaves the wheel out of the hut: G-rules or the "wheel in the hut" check see it first;
then the test's next step touches `r.van_wheel` and raises a SCRIPT ERROR in `scripts/dev/`. Under
"TEST first" the headline says test problem; the referee scores the blame wrong. The reverse case is
covered too: a test error that misplaces the van, then G3 fires, puts TEST first by time.

> **The text I'd sign (D6):** the headline is the **earliest** non-pass event in game time (physics
> frame), with its class from D5; a preflight TEST precedes everything. Every later event is listed
> under it with its time. Nothing is discarded. KILL FAILED is printed beside whatever started it.

### D7 (new): SCRIPT ERROR blame. Hold, with GPT's middle word.

GPT r1: "any SCRIPT ERROR immediately vetoes success" -> ERROR / TEST, while "root-cause ownership
remains separate". Failure mode: a secret bug that throws in game code (`RampJump.gd`, `Camper.gd`)
headlines "ERROR / TEST", which S3 reads as "test problem": wrong blame. **Measured, no longer "I
think":** Godot 4.7 prints the raising frame and a full backtrace under each error
(`appdata/chk.log:15-21`: `at: PlayTest.t_photo_gym (res://scripts/dev/PlayTest.gd:6411)` then
`GDScript backtrace (most recent call first): [0] ... [3]`).

> **The text I'd sign (D7):** every SCRIPT ERROR vetoes PASS (agreed). Its class comes from its
> backtrace: raised in `res://scripts/dev/` -> **TEST**; raised in game code with no `scripts/dev/`
> frame -> **GAME PROBLEM** (the game's own loop threw); raised in game code with a `scripts/dev/`
> frame below it -> **FINDING, owner unresolved** (the test called it; maybe with bad input). No
> backtrace -> owner unresolved. Two injected errors (one each side) qualify the split before the
> freeze.

### D8 (new): `t_ramp`'s own checks carry the verdict. Hold; asking GPT.

GPT r1 §4: "Existing inner PASS is advisory, never a new independent proof of departure." If that
means `t_ramp`'s checks don't decide the run, then the only things watching the shutter, the wheel's
path, the crate + leg-up, the toolbox, the bolt, the refit and the drive-off are c2's seven rules,
which look at none of them. **Failure mode: false pass** on any secret bug in that stretch (the
secret bugs are "in the ramp stretch"). I think GPT meant only "an inner PASS doesn't prove the
departure"; I agree with that. Please confirm in r3.

> **The text I'd sign (D8):** every `check()` in a watched scenario logs a stable ID and carries the
> verdict: a failed check is a **FINDING, owner unresolved** (D5). A clean run's ID list is frozen;
> IDs missing at the end make the run INCOMPLETE ("stopped after <last ID>"). A passed check proves
> only what it measures, from the declared setup before it (R7, R13); the declared set-state lines
> are printed with the report.

### D9 (new): a missing field vs a missing object. Merge, new line.

Both r1s make a failed validated read TEST (T4). Failure mode, **wrong blame**: a secret bug that
removes the wreck, or empties its meshes, fails D2's read the same way a renamed field does. GPT r1
§4 D2 says a missing wreck "is not a clean zero-look result", which by its own table is ERROR / TEST.

> **The text I'd sign (D9):** a validated read fails as **TEST** when the member or method name is
> missing or has the wrong type (the test's model of the code is stale: T4). When the member exists
> and holds null, a freed object or an empty mesh set where the puzzle's manifest says the object
> must exist, it is **GAME PROBLEM: <object> missing**. Each manifest line marks which objects must
> exist; an object not marked is NOT REACHED when absent.

### D10 (new): the drive-off check. Concede to GPT.

My r1 changed the drive-off check to "signed progress along the road". No clean number for it exists
in any record, the drive-off already flakes 2 / 11 (c1's side data), and the hour is short. A
deterministic "can't drive off" bug is still caught by today's "> 30 m from where it stood"
(`PlayTest.gd:11930`). Evidence that moved me: no clean data, plus the build cap.

> **The text I'd sign (D10):** the drive-off keeps today's checks (`PlayTest.gd:11930-11932`).
> Claimed: the van moved > 30 m and came within 3 m of the road. NOT PROVEN: that it drove away
> along the road, or where it ended.

### D11 (new): pad loss. Concede to GPT.

R8 lists c1's '"pad lost" is always TEST' as a known limit. GPT's fix: TEST only when the test's own
unplug is logged (c1's `RigInject` receipt); otherwise owner unresolved. That stops a secret bug in
the game's pad handling from reading as "test problem". Conceded; T1 still scores TEST.

---

## 2. My attack on GPT's r1 (how it would fail)

| # | GPT r1 says | How it fails | Kind | Evidence |
|---|---|---|---|---|
| A1 | One played flat-out try; a miss = INCOMPLETE (§2, §3) | ~4 % chance of S1 10 / 10 on the clean game | false alarm | D1's 9 / 33 table; GPT §8 itself predicts 6-9 / 10 |
| A2 | Spread "carried as unmet", no driver change (§4) | S1's spread fails by design; R14 says the final method's driver must meet it | scoreboard fail | R14; `ramp_try(target, off)` already exists (`PlayTest.gd:11579`) |
| A3 | "ERROR / TEST" first in the priority (§3) | a game bug that cascades into a test-side error reads "test problem" | wrong blame | D6 |
| A4 | Any SCRIPT ERROR -> ERROR / TEST (§2) | a secret bug that throws in game code reads "test problem" | wrong blame | D7; `appdata/chk.log:15-21` shows the path is printed |
| A5 | "TEST STALL" (§3) | a game signal that never fires reads as a test stall | wrong blame | D5 |
| A6 | No headline for N1-N3 | a secret bug that freezes or pauses the game lands in ERROR / TEST or INCOMPLETE; which one is undefined | wrong blame / unclear | D5 |
| A7 | "Existing inner PASS is advisory" (§4) | if `t_ramp` checks don't decide the run, hut-stretch bugs pass | false pass | D8 (asking, not asserting) |
| A8 | A missing wreck isn't a clean zero look (§4 D2) | under GPT's table that's ERROR / TEST: a removed object reads "test problem" | wrong blame | D9 |
| A9 | Recorder archives every outcome (§2) | `c2_more` repeats exactly; recording it costs disk for nothing | cost (small) | `trial_c2.md`: identical numbers per patch |
| A10 | Qualification: "two clean full commands" with one try (§6) | at ~1 in 4 misses, about 47 % of the time at least one is INCOMPLETE (I think): the hour goes on a driver outcome, and GPT gives no rule for what qualification accepts | cost / qualification | D1's table |
| A11 | Mount check on the hub only (§4) | a secret bug moving a tyre mesh is the same class as P6 and goes unseen | false pass | `Camper.gd:221-226` |

**What I checked in GPT's proposal and could not break:** the 45 s startup ceiling has support (g2's
K1, a stale-field TEST, took 16 s wall from launch, `trial_g2.md`); the axle-relative formula is
sound by the source; the per-phase deadlines (each <= 46 s) are stricter than my single episode
deadline and I take them; "preserve the first attempt" and "no PASS by substitution from `c2_more`"
are right.

**My own proposal's weak spots, so the referee has them:** the retry passes an intermittent jump
bug (D1, stated limit); the lanes are untested until the builder's three clean runs (D2); the D7
split needs its two injected errors to work inside the hour.

---

## 3. The text I'd sign, point by point

Numbered so the referee can match it against GPT's r2. Where a point says "as D<n>", the text is
the quoted block above.

- **S-1 Method.** c2's state rules are the detector; c1's health and g2's deadlines, validated
  reads, verified kill and completeness checks surround them; no model in the loop; one command,
  one headline. (Both r1s.)
- **S-2 Health.** c1's heartbeat (20 s), physics (10 s), pause (5 s), player present (~1 s), asked /
  started / finished per scenario; started-but-not-finished says "stopped in <scenario> at <open
  step>", never "never ran".
- **S-3 Deadlines.** OPEN (duration, sequence) / CLOSE on every await that can wait on something
  other than physics: `shot` 5 s, `place_player` 5 s, `until(t)` t + 2 s, each `ramp_try` 46 s,
  reset 6 s, door 4 s; an outer phase per helper with nested waits; host `time.monotonic()`; beats
  never renew a deadline. Episode caps: `ramp` 240 s, `c2_more` 90 s, both checked >= 1.3 x the clean
  max in qualification. Startup: 45 s to the first beat (GPT's number).
- **S-4 Kill.** taskkill, check the PID gone within 5 s, one retry, then KILL FAILED (TEST) and no
  new launch while it lives.
- **S-5 Validated reads.** Preflight at each watched scenario's start, then every read; per rule
  looked / errors / fired. As D9 for missing member vs missing object.
- **S-6 Script errors.** As D7.
- **S-7 Rules.** c2's G1, G2, G4, D1, D2, D3 as built, read through S-5. G3 as D3. G1 in `c2_more`
  needs its full 5 s hands-off window (GPT). D3 names "P1 did not cross this open doorway", not the
  sill (GPT).
- **S-8 Check ledger.** As D8.
- **S-9 The jump.** As D1.
- **S-10 The driver's spread.** As D2.
- **S-11 Drive-off.** As D10.
- **S-12 Recorder.** As D4.
- **S-13 Verdict words.** As D5. **Headline order** as D6. **Pad loss** as D11.
- **S-14 Scope.** Printed every run: claims (where each rule looked, the state was right; P1 crossed
  the door on W; the jump landed within 3 tries at the logged speed and lane; the declared checks
  held); the declared set-state lines (`t_ramp`'s placements, `look_at_point`, the F1 jump, P2 in the
  river); NOT PROVEN (a player reaching the placed spots; what a player sees; why a 66.5 km/h jump
  sometimes misses; the drive-off past D10; anything no rule or check looks at; fun).
- **S-15 Freeze.** Every threshold, the table rows left, the check-ID list, the G3 mount tolerance,
  the deadlines and the verdict table in one file, committed before the referee's requalification.
  Nothing tuned after a secret bug; a later fix voids the freeze and is reported apart.
- **S-16 New puzzle (S7).** Reuse S-1 to S-15 unchanged. The builder writes a manifest: scenarios,
  which generic rules apply or are n/a (with a reason), validated-read list, objects that must exist
  (D9), driver-owned steps and their retry count, 1-3 declared two-sided rules from the puzzle's own
  geometry. New budgets by GPT's formula `min(45 s, max(5 s, 2 x largest observed + 1 s))` from 3
  clean runs of the short stretches; frozen before any scored broken run. No predicate written after
  seeing an exam failure.

---

## 4. What a 1-hour build can't hold, and what goes first

My estimate, all "I think": the merged list is about 60-65 minutes, so something has to go.

| Item | Min | Keep? |
|---|---|---|
| Branch from c2 `04c3102`; copy g2's `rd` / `_stale` / `preflight` / `open` / `close`, recorder, `kill` + deadline loop | 6 | must |
| Validated reads in `C2Watch`, D9 split, per-rule counts | 8 | must (T4) |
| OPEN / CLOSE on helpers + episode / startup caps | 6 | must (N5) |
| Check IDs + ledger | 4 | must (early return, D8) |
| G3 mount (hub + tyres) + its control | 5 | must (P6) |
| Jump retry x3 + the table | 5 | must (S1) |
| Verdict reducer: words, first cause, backtrace split, scope print | 8 | must |
| Clean runs k0, k1, k2 (~3 min each, Python written meanwhile) | 10 | must |
| Controls: T4, N5, displaced hub, early return (~1 min each on `c2_more`) | 5 | must |
| SE_GAME / SE_TEST controls for D7 | 3 | **cut 1st** |
| Recorder print-outs (p99, frames per 60 ticks) | 2 | **cut 2nd** |
| Tyre half of the mount rule | 2 | **cut 3rd** |
| Lanes (k1, k2 at lane 0 instead) | 0 build, risk only | **cut 4th**, only if a lane row fails |
| Report + freeze file | 5 | must |

**Fallbacks when a cut is taken (frozen in advance):** without the D7 controls, every game-code
script error is FINDING, owner unresolved (the safe side). Without the recorder print-outs, the
recorder stays on and its cost is "not measured". Without the tyres, a tyre-mesh bug is NOT PROVEN.

**Can't hold at all in the hour:** a better driver (why a 66.5 km/h jump misses 1 in 4); a
drive-off check with clean data; any new rule without clean numbers. All stay NOT PROVEN.

**For the S7 port (the builder's next hour):** the manifest and 3 clean runs of the short
stretches are the cost. If the new puzzle drives, its driver-owned step reuses S-9's retry; if its
existing scenario flakes like `t_ramp`'s, that shows in the clean runs and is reported, not tuned.
