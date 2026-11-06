# The final method: merged draft (Stage 4, round 3a, Claude auditor)

2026-11-06. Written on `g12` `0e8ef90`, read-only except this file. Read in full:
`final_r1_claude.md`, `final_r1_gpt.md`, `final_r2_claude.md`, `final_r2_gpt.md`, `scoreboard.md`
(R1-R15), and the scoring sections of `trial_c1.md`, `trial_c2.md`, `trial_g2.md` they cite.
Source checked at the SHAs named. No runs, no code. **Round 3b: GPT signs or holds each M-point.**

**How this text was made (the referee's rules).** Where both r2 files agree, or where I concede, the
text is **GPT's r2 wording**, quoted; every word I changed is marked **[changed: ...]** with the
reason. Where I still hold, the point is **DISPUTED: Option C (Claude) / Option G (GPT)**, each in its
owner's exact words, with evidence, cost in the user's real time, and a **default** the builder sets
with one key in `tools/method/frozen.json`.

**How every default was picked (one rule, applied the same way to all five disputes):**
1. a default must not block the builder's hour or qualification;
2. otherwise, the side the scoreboard's decision order favours: **a false pass weighs more than a
   false alarm** (`scoreboard.md` "How the referee decides", 2);
3. otherwise, the side with fewer build minutes.
Result: four of five defaults are GPT's option; one (M10) is mine, by rule 1. A default is not a
concession; the user decides each DISPUTED point as A / B.

**Note: GPT's r2 and mine were written at the same time.** GPT has not yet seen my r2's D6-D11. For
those, "Option G" is GPT's existing wording on the same question (quoted with its place), and 3b may
change it.

---

## 0. The M-points, and how they map to both r2 numberings

| M | Point | Claude r2 | GPT r2 | Status after 3a |
|---|---|---|---|---|
| M1 | The method, the detector, health vs truth | S-1, S-7 | A1, A3 | AGREED (GPT's words) |
| M2 | Health and scenario lifecycle | S-2 | A3, D6 (receipts) | AGREED (GPT's words) |
| M3 | Deadlines, windows, startup, kill | S-3, S-4 | D8 | AGREED (GPT's words) |
| M4 | Validated reads | S-5 | D7 (second half) | AGREED (GPT's words) |
| M5 | A missing member vs a missing object | D9 | D7 clause, D5 "TEST" | **DISPUTED** (GPT not yet answered D9) |
| M6 | SCRIPT ERROR blame | D7, S-6 | D7 | **DISPUTED** (I moved part way) |
| M7 | The state rules kept as built | S-7 | A2 | AGREED (GPT's words) |
| M8 | G3: lower ground + attachment | D3 | D3 | AGREED (GPT's words + tyres, GPT's own condition met) |
| M9 | Completion ledger; checks carry the verdict | D8 | D6 (first part), D5 | AGREED (GPT's words) |
| M10 | The drive-off (departure) | D10 | D6 (second part) | **DISPUTED** (GPT asked round 3 to settle it) |
| M11 | Flat-out jump: one try or up to three | D1, S-9 | D1 | **DISPUTED** |
| M12 | The driver's spread table | D2, S-10 | D2 | AGREED (**I concede**: GPT's table) |
| M13 | Recorder off by default; mandatory evidence | D4, S-12 | D4 | AGREED (**I concede**: GPT's text) |
| M14 | Five statuses, exit codes, reasons | D5, S-13 | D5 (minus priority) | AGREED (GPT's words) |
| M15 | Which event takes the headline | D6 | D5 (priority sentence) | **DISPUTED** (GPT not yet answered D6) |
| M16 | Pad loss and input receipts | D11 | A4 (last sentences) | AGREED (GPT's words) |
| M17 | Command and output | S-13 | A4 | AGREED (GPT's words) |
| M18 | Scope: claims, declared setup, NOT PROVEN | S-14 | A5 | AGREED (GPT's words + the list) |
| M19 | Controls, qualification, freeze | S-15 | A6, D9 (first part) | AGREED (GPT's words) |
| M20 | Port to the unseen puzzle | S-16 | D9 (second part) | AGREED (GPT's words) |
| M21 | Cost and humans | (r1 §7) | A7 | AGREED (GPT's words) |

**Summary: 16 AGREED, 5 DISPUTED (M5, M6, M10, M11, M15).**

---

## 1. The method in one paragraph, and its parts

**Bounded contract testing** (GPT's name; I drop mine, "the judged run"). A script plays the ramp
the way a player would: today's `t_ramp` route by keys only, through a fixed speed x lane schedule
(M12), plus c2's short declared stretches (`c2_more`) so every state rule is reached every run. Read-only
contracts (c2's seven families, with G3 repaired by an attachment check, M8) watch the game's own
state through validated reads (M4). A host supervisor, not a model, watches health (c1), published
step deadlines and verified kill (g2), and receipts that every required piece of work happened (M9).
One reducer prints one status out of five (M14) with its named thing, numbers and one picture, and
the scope. No model chooses an input or reads a step during the run; a person or model reads a
non-pass once, afterwards. The full recorder is off by default (M13). Everything is frozen before
the exam (M19).

| Part | Source (SHA, file) | Why (scoreboard evidence) |
|---|---|---|
| Heartbeat, physics / world clocks, pause, players present, input receipts, plan check | c1 `a6a412f`: `dev/RigBeat.gd`, `dev/RigInject.gd`, `tools/rig/rig_watch.py`, `tools/rig_run.sh`; code commits `920110d`, `3b96807`, `a106f90`, `57b8afd` (R8) | S1 10/10 healthy; S3 3/3; S4 4/4 in <= 27 s (`trial_c1.md`). Health only, never game truth. |
| State contracts G1-G4, D1-D3; short declared stretches | c2 `04c3102`: `dev/C2Watch.gd`, `t_c2_more` in `dev/PlayTest.gd` | S1 10/10, 7/7 reached every run; S2 6/7 caught and named (`trial_c2.md`). Its green-exit policy is **not** taken (T4 false pass, P6 1/3). |
| Validated reads, OPEN / CLOSE deadlines, verified kill, missing-checkpoint idea | g2 `afb9e9b`: `dev/G2Rec.gd` `rd()`, `_stale()`, `preflight()`, `open()`, `close()`; `tools/g2/g2_watch.py` `kill()`; `shot()` hooks in `PlayTest.gd` | T4 1/1 TEST before the drive; N5 caught in 5.02 s, process gone; K3 INCOMPLETE where c1 said PASS (`trial_g2.md`). g2's 150 s startup, wall-clock timers and repeated-OPEN renewal are **not** taken (M3). |
| Route and driver | g12 `0e8ef90`: `t_ramp`, `ramp_try(target, off)` (`PlayTest.gd` ~11579, `ad.lane = off`) | Keys only; the knob exists (M12). |
| New: attachment check, one supervisor, completion ledger, reducer, scope print | specified here | Fix P6, the false green, the failed kill, "never ran" (both r1s). No score is inherited for them (R1). |
| Dropped | g1 `a367de3` driver and freeze rule; g2's recorder in the default run; g2's pair / causal tooling | g1 failed qualification (`trial_g1.md`); recorder 0/2 as a detector (`trial_g2.md`). |

**Build base (checked):** `04c3102` holds g12's game plus c1 and c2; no file under `FindingNaresh/`
or `tools/` changed on g12 since their merge-base `d80e0cd`. g2's parts are copied by function from
`afb9e9b`, never by overwriting `PlayTest.gd` (GPT r1 §6).

---

## 2. The M-points

### M1. The method, the detector, health vs truth: AGREED

> **(GPT r2 A1)** Use c2's G1–G4 and D1–D3 as the automatic detector, with D3's hub repair above. Keep
> four generic families and three puzzle-declared families visible; G3's two subchecks are not two
> independently demonstrated universal laws. All seven were practice-informed (`trial_c2.md`, honesty
> note). No claimed secret generalisation before the exam.

> **(GPT r2 A3)** c1 supplies health, declared needs/input evidence and scenario lifecycle; g2 supplies
> validated-read patterns, bounded-step/termination mechanisms and receipts. Reuse source at a6a412f,
> 04c3102 and afb9e9b by function/file with diffs recorded; preserve current unrelated test content. A
> healthy rig is never itself a passed game test. R1/R8 scores remain 'via c1/g2'; new integrated paths
> need their own qualification. No simultaneous competing kill watchers.

[changed: "D3's hub repair above" means **M8** here.]

### M2. Health and scenario lifecycle: AGREED

> **(GPT r1 §2, restated by GPT r2 D6)** Supervisor owns launched PID/process tree and records launch,
> start, end and required-work receipts separately. Print asked / started / ended / verified counts and
> IDs. Started without end is interrupted/stalled; no start is NOT STARTED; end without required
> receipts is INCOMPLETE. Preserve first cause.

Health limits are in M3. A started-but-not-ended scenario prints "stopped in <scenario> at <last open
step>", never "never ran" (c1's mislabel, `trial_c2.md` S4, `trial_g2.md` S4: both r2s).

### M3. Deadlines, windows, startup, kill: AGREED

> **(GPT r2 D8)** Use one supervisor/kill owner, host monotonic timers and uniquely identified
> OPEN/CLOSE instances. Repeated OPENs cannot renew a deadline. All selected-path awaits are covered by
> an enclosing bounded phase, with additional short deadlines on drawing/signals. Fixed limits: poll
> 0.5 s; startup first valid beat within 45 s of game launch; no beat 20 s; fresh beats without physics
> 10 s; unallowed pause 5 s; missing actor two beats; shot 5 s; simple setup <=10 s; drive/reset call
> 46 s; separate reset wait 6 s; until(t) gets t+2 s only within a <=46-s enclosing phase. Outer ramp
> cap 240 s and c2_more cap 90 s do not replace these phase limits. Print progress every 5 s. Any
> required observation/error-write failure vetoes success when detected, not only at process end. After
> STOP, verify PID/process-tree exit for at most 5 s, retry termination once and check for at most
> 5 s, then TEST/KILL FAILED; bound wrapper shutdown too and prohibit another launch while the PID
> lives. Record detection and shutdown times separately. Required observation windows must complete, not
> merely be sampled: local G1 requires five hands-off seconds, G2/G4 preserve their existing duration
> tests, parked G3 requires 0.5 s. A truncated mandatory window is INCOMPLETE, not a passing LOOK.

[changed: one sentence added, for the builder: **"The played route's G1 window is evaluated but not
mandatory; the mandatory G1 window is `c2_more`'s."** Why: on the played route `t_ramp` starts driving
0.3 s after the reset, so its G1 window was 1.88 s (`trial_c2.md`); declared mandatory, every clean run
would be INCOMPLETE. GPT r1 §4 already lists the full G1 window under `c2_more`'s requirements.]

[not a change, a reminder from the same r2 D8: deadlines cover the **selected path** only ("auditing
just the selected paths/helpers, not instrumenting all ~2,900 awaits in the whole test suite").]

### M4. Validated reads: AGREED

> **(GPT r2 D7, the validation part)** T4 must exercise an actual required C2 observer dependency, not
> merely an unrelated recorder field. Validate every required field by existence/type/instance and
> finite value before use and after binding changes; runtime failures invalidate the observation.

Plus both r1s: a preflight at each watched scenario's start, then every read; per rule the counts
evaluated / windows completed / errors / findings (GPT D8's "full-window receipts" replaces my
"looked >= 1"). **What a failed read is called** is M5.

### M5. A missing member vs a missing object: DISPUTED

**The question.** A validated read fails. Is it always TEST, or is "the name exists but the object
the puzzle needs is gone" a game finding?

**Option C (Claude r2 D9, revised in 3a):**
> A validated read fails as **TEST** when the member or method name is missing or has the wrong type
> (the test's model of the code is stale: T4). When the member exists and holds null, a freed object or
> an empty mesh set where the puzzle's manifest says the object must exist, it is **FAIL: <object>
> missing, owner UNRESOLVED**. Each manifest line marks which objects must exist; an object not marked
> is NOT REACHED when absent.

[My revision: r2 said GAME PROBLEM for the second case. **Moved to owner UNRESOLVED** by GPT's D7
argument applied here: the test writes state before the proven stretch (`t_ramp` frees objects,
`can.queue_free()`, and sets `w.global_position` by the hub), so a null can be test-made.]

**Option G (GPT's existing wording; GPT has not answered D9 yet):**
> "Validate every required field by existence/type/instance and finite value before use and after
> binding changes; runtime failures invalidate the observation. Missing required ray hits/meshes/HUD
> evidence cannot be converted to clean zero-look or NOT REACHED results." (GPT r2 D7) and "TEST means
> invalid required observation" (GPT r2 D5); "missing wreck is not a clean zero-look result" (GPT r1 §4
> D2).

| | Evidence | Cost in the user's real time |
|---|---|---|
| C | A secret bug that removes or empties the wreck, the hub or a HUD label fails the read the same way a rename does; under G it reads "test problem": wrong blame on S2's "named" and S3. | +1 build minute (a must-exist flag per manifest line). None per run. |
| G | One rule, simplest; an invalid observation never produces a game claim. A null can be test-made (my own revision's evidence). | 0 build minutes. A removed-object bug costs the user a diagnosis (~2-5 min, GPT r1 §7) to see it isn't a test fault. |

**Neither is a false pass** (both veto PASS). **Default: G** (rule 3, fewer minutes). Key:
`"null_object": "test"` (G) or `"fail"` (C).

### M6. SCRIPT ERROR blame: DISPUTED

**Agreed by both:** every current-run SCRIPT ERROR vetoes PASS at once, with its stack and file kept;
valid earlier game findings stay visible (M15).

**Option C (Claude r2 D7, revised in 3a):**
> Every SCRIPT ERROR vetoes PASS. Its class comes from where it was raised: raised in
> `res://scripts/dev/` -> **TEST**; raised in game code (any stack) -> **FAIL: script error at
> <file:line>, owner UNRESOLVED**. No backtrace -> owner UNRESOLVED. Two injected errors (one each side)
> qualify the split before the freeze.

[My revision: r2 had "game code with no test frame -> GAME PROBLEM". **Conceded to GPT's D7
evidence**: file placement shows where an error surfaced, not who caused it; a declared setup write
(e.g. `t_ramp` setting the wheel's `global_position`) can make the game's own loop throw later with
no test frame on the stack. So no GAME label from the path. I hold only the split TEST vs FAIL.]

**Option G (GPT r2 D7, exact):**
> Any current-run SCRIPT ERROR vetoes PASS immediately as TEST/observation invalid, with stack and file
> preserved. File path is diagnostic evidence, never sufficient ownership proof. Independently valid
> game-contract findings already recorded remain visible under D5. A later diagnosis may assign cause
> with evidence; it cannot change the frozen automatic verdict or catch score.

| | Evidence | Cost |
|---|---|---|
| C | Godot 4.7 prints the raising frame and a full backtrace under each error (`appdata/chk.log:15-21`: `at: PlayTest.t_photo_gym (res://scripts/dev/PlayTest.gd:6411)` then `GDScript backtrace`). A secret bug that throws in `RampJump.gd` / `Camper.gd` reads "test problem" under G: S2 "named" and S3 both scored wrong. C never claims GAME. | +3 build min (path parse + 2 controls, SE_GAME / SE_TEST). |
| G | T4 was a game-side rename that broke an observer (`trial_g2.md` S3); a test callback can surface a real game failure and vice versa; path is not cause. Simpler; GPT cut the classifier and its controls for the hour. | 0 build min. A game-code throw costs a diagnosis (~2-5 min) before the user knows it's a game finding. |

**Neither is a false pass.** **Default: G** (rule 3). Key: `"script_error": "test"` (G) or `"path"`
(C). If C is chosen and its two controls don't fit the hour, it falls back to G (frozen in advance).

### M7. The state rules kept as built: AGREED

> **(GPT r2 A2)** G1 horizontal drift >0.30 m in its hands-off window; print brake history, brake-off
> reset versus brake-on cause unresolved. G2 actual ground >0.30 m above water AND distance beyond the
> player's own bank target >5 m for >1 s; validated target, no substitute absolute river-distance rule.
> G4 physical front-left absence versus PUNCTURE/ON THE HUB mismatch lasting >0.5 s, loose-wheel
> distance 1.5 m; require meaningful HUD observations. D1 c2's 1.0 x 0.7 x 1.2 m fixed-solid crate
> volume, same exclusions, any solid fires. D2 nonempty rendered wreck top below water fires; no upper
> floating rule. D3 c2's declared open-door setup and W-only crossing within 4 s, with input/open-state
> evidence. Failure names the un-crossed doorway, not an unmeasured sill cause. Preserve existing
> predicates unless the combined agreement explicitly changes them.

[changed: none. "Nonempty" in D2: what an empty wreck is called is M5.]

### M8. G3: lower ground + attachment: AGREED

> **(GPT r2 D3)** Keep c2's existing parked-for-0.5-s lower-ground predicate, bottom minus ray-hit
> height < -0.12 m. Add a hub-to-owning-axle residual in axle coordinates against the construction's
> expected centre, zero for BareHub. Measure clean component extrema and maximum norm on the two builder
> qualification commands, including declared F1 state and any played landings. Freeze tolerance = clean
> maximum norm + 0.01 m, requiring clean maximum <=0.01 m; otherwise this proposed repair is unqualified
> rather than widened. Never recenter the expected design position from observations. Fire when residual
> exceeds the frozen tolerance after the parked trigger. Validate required transforms and finite values.
> A required failed ground probe is invalid observation, not a skipped clean sample. Do not add an upper
> world-ground bound. Extending attachment checks to other wheel meshes requires verifying each
> construction centre; otherwise list those attachment relations NOT PROVEN. Show the new predicate can
> fail using a test-only displacement control before freeze.

**[changed: one sentence added, meeting GPT's own condition] "Verified for the four tyres, so they are
included: each `Tyre` sits at `Vector3.ZERO` in a `Spin` holder whose position is never set, child of
its own wheel (`Camper.gd` 221-232 at `0e8ef90`); the holder is only rotated (`rotation.x`, 1146-1147)
and scaled about its centre for a flat (674-675). Design centre zero for each visible tyre."** Why: a
secret bug moving a tyre mesh is the class P6 is in; the source check GPT asked for is done.
GPT confirms in 3b. If the builder's hour can't hold it, the tyres go NOT PROVEN (cut 3, §6).

### M9. Completion ledger; checks carry the verdict: AGREED

> **(GPT r2 D6, first part)** Before qualification, declare semantic required-work IDs for each scoped
> stretch, including route landing, post-landing work, end-of-route departure and each mandatory local
> observation window. Give branch alternatives explicit outcome IDs; do not learn obligations solely
> from whichever checks happened in one clean run. A check receipt contains its stable identity and
> boolean outcome, not just its ordinal count. Require asked/start/end/work receipts by scenario
> instance; started without end is interrupted, ended with missing work is INCOMPLETE. Coverage obtained
> through setup is labelled separately and cannot satisfy a played-route receipt. Clean traces verify the
> manifest rather than define away missing work.

My r2 D8 question ("does 'inner PASS is advisory' mean a failed hut check can pass?") is answered by
GPT r2 D5: "FAIL means a valid required contract/check failed". So: **every `check()` in a watched
scenario (39 in `t_ramp` at `0e8ef90`) is a required check with a stable semantic ID; a failed one is
FAIL, owner UNRESOLVED** unless M10 or M11 says the step is a reach outcome. [changed: "end-of-route
departure" in GPT's list is governed by M10.]

### M10. The drive-off (departure): DISPUTED

**The measured problem.** Today's two drive-off checks (`PlayTest.gd` ~11929-11932 at `0e8ef90`):
moved > 30 m from where it stood, and closest to the road < 3 m ("the closest it got, not where it
ends: the bot circles once on the road"). c1's side data: **2 of 9 clean landings failed the drive-off**
(moved 13 m and 10 m, `trial_c1.md` S1 table). No clean number exists for a better witness.

**Option C (Claude r2 D10, revised in 3a):**
> The drive-off keeps today's two checks, in the ledger as the route's departure receipt. If either is
> missing, the route is **INCOMPLETE: drive-off not reached, owner UNRESOLVED** (a driver reach
> outcome, like the jump). Claimed when both hold: the van moved > 30 m from where it stood and came
> within 3 m of the road. **NOT PROVEN:** that it drove away along the road, or where it stopped. No new
> departure check in this build.

[My revision: r2 kept them as plain checks (a fail = FAIL). The 2/9 record makes a failure a reach
outcome, not a contract break: so INCOMPLETE, the same word GPT uses for a missed reach.]

**Option G (GPT r2 D6, second part, exact):**
> For departure, 'closest ever to road' and distance from start are advisory only. Any claimed departure
> must measure signed progress on the road plus final road distance and verified stop under pre-frozen
> limits; without that witness departure is NOT PROVEN and a mandatory route departure remains
> INCOMPLETE. No new departure controller is required.
> ... I would rather carry an honest unproved departure than invent new numerical route-success limits
> in this audit. If departure is to qualify, builder/auditors must specify its source,
> progress/distance/rest limits before freeze; g1's checker is source material, not inherited
> qualification.

| | Evidence | Cost |
|---|---|---|
| C | A bug that stops the van leaving (wheel not really refitted, brake stuck) fails "moved > 30 m": caught. "Closest < 3 m" is a narrow claim, and it is all that is claimed. | 0 build min. ~2 in 9 clean landings read INCOMPLETE at the drive-off (c1 data): ~1 min of the user's reading each. |
| G | "Closest ever" was a measured false pass ("back on the road" while circling, the brief's evidence table); a real departure needs progress + final distance + stop. Honest NOT PROVEN beats invented limits. | As I read it (GPT to correct in 3b): with no witness built, either **every** route run is INCOMPLETE at the departure (if it stays mandatory), or the two checks are advisory and a can't-leave bug passes. |

**Default: C** (rule 1: G-as-mandatory makes every clean run INCOMPLETE, so the builder can never
show a clean route PASS; G-as-advisory is a false-pass path, rule 2). Key: `"departure": "checks"`
(C) or `"witness"` (G; with no witness built it reads departure NOT PROVEN + INCOMPLETE).
**3b, please say:** under G, is departure mandatory work in the ramp profile?

### M11. Flat-out jump: one try or up to three: DISPUTED

**Agreed by both:** the slow miss + reset is expected work; every attempt is printed in order, first
first; no automatic whole-run rerun (I conceded it in r2); a measured contract violation is FAIL even
if a later attempt lands; every miss stays visible.

**Option C (Claude r2 D1, exact):**
> The flat-out jump gets up to **3 tries in the same run**; tries 2-3 follow the game's own reset, as a
> player's would. Every try prints lip km/h, lane offset at the lip, landed / missed, in order, first try
> first. The headline line carries the count: "PASS (jump landed on try 2; 1 miss at 66.5 km/h, owner
> unresolved)". 3 misses = **INCOMPLETE: the jump did not land in 3 tries at <speeds>**, never PASS,
> never GAME PROBLEM. No run is ever rerun automatically. Across a series, the report sums tries and
> misses; the first-try land rate is printed apart, and a clean-game miss rate goes to the user as an
> open question (game or driver: not measured). Stated limit: a bug that makes the jump miss
> **sometimes** can pass a run.

**Option G (GPT r2 D1, exact):**
> The default command has one expected slow miss/reset and one flat-out landing attempt. The expected
> slow miss is successful scenario work when its reset contract completes. A missed mandatory flat-out
> landing makes the attempted route INCOMPLETE, ownership unresolved; later local coverage cannot change
> that verdict. Every attempt and its actual outcome remain in the report. No automatic whole-run rerun
> or successful-attempt substitution earns PASS. A separately requested diagnostic retry has its own run
> ID and verdict and cannot revise the original result. A measured contract violation remains FAIL even
> if a later attempt succeeds.

**Evidence, each side in its own terms:**
- **C:** the clean game's flat-out try missed **9 of 33** times on the unchanged actor (baseline 1/1,
  c1 side data 2/11, c2 qualification 1/4, c2 S1 2/10, g2 baseline + `g2_a0` 3/7; `final_r2_claude.md`
  D1 table; 9/41 if g2's factor arms count). The same 66.5 km/h lands and misses; cause INCONCLUSIVE
  (`trial_g2.md` (a)). A miss is a designed game outcome with its own reset (`design/PUZZLE_CHANGES.md`
  "As built"); a player retries.
- **G:** "c2's referee recorded two clean misses in ten attempts; g2 left the same-speed miss
  unresolved and found a miss without the proposed on-ramp tap, plus a landing with one ... Claude's
  sub-2% three-miss estimate is explicitly unmeasured; the g2_a0 group missed 3/4, and independence is
  unestablished. R12 permits neutral state-rule coverage; R15 forbids passing missing required work."
  And: "retry-to-success can hide a real intermittent gameplay defect" (GPT r2 attack table).

**Cost in the user's real time (I think; assumes independent tries, which g2_a0's 3/4 says may not
hold):**

| | Clean run reads PASS at the jump | With the drive-off flake (M10 C, 7/9) | S1 10/10 | Extra run time |
|---|---|---|---|---|
| C (3 tries) | ~0.98 | ~0.76 | ~6 % | +~45 s per extra try (a `ramp_try` arm with reset is 41-52 s, `trial_g2.md`) |
| G (1 try) | ~0.73 | ~0.57 | ~0.4 % | none |

**New in 3a, said plainly:** the drive-off record (M10) makes S1 10/10 unlikely under **either**
option with today's driver; my r2's "~82 %" ignored it. M11 still decides how often a clean run reads
INCOMPLETE (about 1 in 4 vs 2 in 5) and so how many reads the user does, and whether an intermittent
jump bug can pass a run (C: yes, stated limit; G: no, it reads INCOMPLETE).

**Default: G** (rule 2: C has a stated false-pass path). Key: `"jump_tries": 1` (G) or `3` (C). Both
use the same loop in `t_ramp`; only the count changes.

### M12. The driver's spread table: AGREED (I concede)

> **(GPT r2 D2)** The method owns scheduling, required reach receipts and honest reporting of actor
> failures. Reuse today's AutoDriver and ramp_try, with a fixed five-profile schedule: k0=(62 km/h
> target, -0.5 m lane), k1=(64,+0.5), k2=(66,0), k3=(80,-0.5), k4=(80,+0.5). The externally supplied
> profile ID is logged; ten qualification/scoring runs use k0–k4 twice in that order, retaining every
> run. Log actual lip speed, offset, landing and parked pose separately from targets. Change neither
> controller nor game physics, and perform no in-stretch state writes to manufacture variation. A miss
> stays D1 INCOMPLETE. If measured lip speeds do not span at least 61–68 km/h, report R14 unmet; do not
> certify the spread from requested targets or raise the floor to remove failing cases.

[changed: "A miss stays D1 INCOMPLETE" -> **"A miss is scored by M11."** Why: as written it settles
M11 for GPT's side.]

**Evidence that moved me:** my r2 moved k0 to target 63 because the bench gave lip **60.9** at target
62. But 60.9 km/h **landed** on the bench (`appdata/ramp_bench.out`), and a lip under 61 widens the
spread at its low end rather than missing it: the move was my error. GPT's point stands that raising a
floor or deleting a row before the freeze removes hard evidence. Note for the referee: flat out tops
at 66.7-67.0 km/h measured (bench, c2, g2), so "68" is likely unmet whatever the method; that's the
referee's R14 call, not ours.

### M13. Recorder off by default; mandatory evidence: AGREED (I concede)

> **(GPT r2 D4)** Full G2Rec telemetry is off by default; FN_RECORD=1 enables a separately declared
> diagnostic run. Health, input receipts, deadlines, contract evaluations, errors, scenario/work receipts
> and observed attempt outcomes are always recorded and archived with a unique run ID. Before stopping on
> a finding, flush the offending measurement, its threshold, prerequisites, object identity and
> physics/process frame IDs. Request one useful observer picture through the bounded capture helper;
> capture failure cannot delay termination or erase numeric evidence. These records, current-run logs
> and coverage summary are mandatory, not opt-in. No new ring-buffer subsystem is required in the hour.
> Full-recording mode is read only offline after a non-pass, never by a model choosing live inputs. Its
> overhead and diagnosis time are reported separately; it cannot retrospectively turn an automatic miss
> into a scored catch.

**Evidence that moved me** (my r2 had moved to "on during `ramp`"): g2 lists frame pacing as an
unmeasured confounder of the miss (B1 ~46 process frames per 60 ticks vs ~75-90 elsewhere,
`trial_g2.md`); recording by default during the exam adds a confounder to the very stretch being
judged, for diagnosis value the exam doesn't score. And it saves build minutes. My r2's once-off-miss
argument is a real loss; GPT names it as an accepted limit ("reduced diagnostic power on intermittent
physics").

### M14. Five statuses, exit codes, reasons: AGREED

> **(GPT r2 D5, without its priority sentences, which are M15)** One host reducer prints one RESULT
> with exactly one status: PASS, FAIL, INCOMPLETE, TEST, or NOT HEALTHY. TEST means invalid required
> observation, malformed plan/event, failed required output, or demonstrated test input failure; it does
> not declare all game code innocent. NOT HEALTHY means frozen/stopped physics, unallowed pause or
> missing required actor. FAIL means a valid required contract/check failed; attach owner=GAME only when
> valid prerequisites and the measured game-contract violation establish it, otherwise owner=UNRESOLVED.
> INCOMPLETE means mandatory work/window/reach receipts are absent, including an unresolved missed
> flat-out attempt. PASS requires valid health, every mandatory scenario and work item complete, every
> required observation window valid and complete, and no required failure. Exit codes: PASS=0, FAIL=1,
> INCOMPLETE=2, TEST=3, NOT HEALTHY=4. STALLED and KILL FAILED are reasons, not sixth/seventh statuses.
> A deadline expiry is INCOMPLETE/STALLED with owner=UNRESOLVED unless another measured condition gives
> the higher status. NOT REACHED is a per-rule healthy-absent-trigger line; mandatory absence also
> causes INCOMPLETE. NOT PROVEN identifies claims outside scope. Print all secondary conditions and
> earlier valid findings with times; evidence invalidated by the same cause is marked invalid. Never
> erase a valid earlier finding merely to select the headline. Append the named scope even on PASS.

[changed: "including an unresolved missed flat-out attempt" -> **"including a flat-out jump not landed
as M11 sets"**. Why: same as M12, it would settle M11.]

**Evidence that moved me:** my r1 FAIL carried two blames behind one word; GPT's owner tag puts the
blame in the line. My worries are met: STALLED is a reason with owner UNRESOLVED (not "TEST STALL"),
and NOT HEALTHY is a status of its own (N1-N3 have a home).

### M15. Which event takes the headline: DISPUTED

**Option C (Claude r2 D6, refined in 3a):**
> The headline is the **earliest** non-pass condition by the time it began (game events by physics
> frame / log order; host conditions by when they started, e.g. the last good beat), with its status
> from M14; a preflight TEST precedes everything. Conditions that begin within 2 s of each other (the
> health rule's two-beat lag, rounded up) are ranked NOT HEALTHY > TEST > FAIL > INCOMPLETE. Every
> later condition is listed under it with its time. Nothing is discarded. KILL FAILED is printed beside
> whatever started it.

[My refinement: the 2 s tie rule. Why: c2's N3 control removed P2 and the observer threw a SCRIPT ERROR
every tick at once (`trial_c2.md` S4); pure first-in-time would headline the observer's error, not the
missing player that caused it.]

**Option G (GPT r2 D5, exact; GPT has not answered D6 yet):**
> Priority is TEST > NOT HEALTHY > FAIL > INCOMPLETE > PASS. ... Print all secondary conditions and
> earlier valid findings with times; evidence invalidated by the same cause is marked invalid. Never
> erase a valid earlier finding merely to select the headline. ... Priority is a proposed fixed
> presentation convention, not a measured causal ordering.

| | Evidence | Cost |
|---|---|---|
| C | A game bug usually breaks what the test leans on later: e.g. the wheel never reaches the hut, the "wheel in the hut" check fails, then the next step touches `r.van_wheel` and throws in `scripts/dev/`. Under G the headline says TEST: the referee scores S2's "named" on the symptom three steps later (`scoreboard.md` S2: "not at a symptom three steps later"). | +3 build min (times on every condition; the reducer sorts). |
| G | A fixed order is simple and stable; it is a presentation rule, and the earlier FAIL is still printed with its time, so nothing is lost to a reader. An invalid observation makes later evidence untrustworthy. | 0 build min. The user reads past a TEST headline to the earlier FAIL (~1 min) on cascades. |

**Neither is a false pass.** **Default: G** (rule 3). Key: `"headline": "priority"` (G) or `"time"` (C).

### M16. Pad loss and input receipts: AGREED

> **(GPT r2 A4, last sentences)** A synthetic declared pad disconnect is TEST as T1 requires; an
> unexplained binding change alone does not prove who caused it. Short unobserved input pulses are
> UNOBSERVED, never successful receipts.

(My r2 D11 conceded this: TEST only when c1's `RigInject` logged the unplug; otherwise owner
UNRESOLVED. This replaces R8's known limit '"pad lost" is always TEST'.)

### M17. Command and output: AGREED

> **(GPT r2 A4)** One command runs the externally specified nonempty ramp,c2_more plan; no save, reload,
> intentional pause or preset discovery in this profile. One supervisor prints D5's headline plus
> asked/started/ended/verified IDs, per-rule evaluation/window/error/findings, actual attempts and
> variation, setup/played provenance, seconds and evidence directory. Archive uniquely before another run
> overwrites runner logs.

[changed: "D5's headline" means M14 + M15.] Command and paths in §7.

### M18. Scope: claims, declared setup, NOT PROVEN: AGREED

> **(GPT r2 A5)** Real-input stretches prove only what was reached by those inputs. Declare all t_ramp
> placements, handed items, state writes, door setup, F1 wheel setup and camera setup before their
> respective boundaries. Under R13 a setup catch counts only for code actually shared with the played
> path; F1 cannot catch a landing-only bug by implication. Observer pictures supplement evidence under
> R2; they do not certify a player-visible/readable/reachable object. Full human solution, unseen
> mechanics, general swim correctness, fun and visual quality remain NOT PROVEN. The default result must
> not imply those claims.

The printed lists are in §4.

### M19. Controls, qualification, freeze: AGREED

> **(GPT r2 A6)** Within the builder's hour: compile; two clean commands with k0/k4, recording outcomes
> rather than substituting successes; actual C2 stale-dependency control; live-step stall;
> missing-work/early-return control; hub displacement control; inspect reset/door/hub measurements and
> useful stills. Controls must not be read by detectors. Restore fixtures and demonstrate final clean
> behaviour if controls changed runtime code. A clean INCOMPLETE is not qualified route PASS. Referee then
> requalifies exact code with clean runs, T4 and N5, and retains all outcomes. Additional P6 repetitions
> are useful confirmation, separately charged. No fresh scores for unchanged inherited controls without
> reruns. Freeze only the reviewed implementation and concrete values; partial work is labelled partial.

> **(GPT r2 D9, first part)** Before ramp exam, freeze the combined source SHA, unchanged-game hashes,
> five statuses/exit codes, ownership policy, event/receipt schema, scope/setup boundaries, required
> work, actual numeric thresholds, timing limits, default/diagnostic modes, variation schedule and
> adapter procedure. No threshold or rule is repaired using secret-bug feedback.

[changed: "ownership policy" includes **the five DISPUTED keys** in `tools/method/frozen.json`,
set to the user's choices (or the defaults) before the referee's requalification. A later fix voids
the freeze and is reported apart (both r2s).]

### M20. Port to the unseen puzzle: AGREED

> **(GPT r2 D9, second part)** Freeze the adapter procedure now: bind existing generic relations
> unchanged where applicable; declare N/A with a reason otherwise; write puzzle-specific semantic
> obligations/geometry relations from requirements and construction before broken-run feedback; declare
> setup and input-only stretches; take two clean bounded runs; publish the adapter and its limits before
> scored broken runs. New timing budgets may use twice the larger observed clean action duration plus
> 1 s, rounded up, minimum 5 s and maximum 46 s; larger actions require independently witnessed phases or
> are unsupported. No gameplay threshold may be learned merely from two observations; use a justified
> design relation or report NOT PROVEN. The ramp's actual thresholds remain unchanged. Report port hours,
> lines by actor/binding/predicate/fixture, clean outcomes, reused versus new rules and unsupported work.
> A new whole-puzzle actor is not promised inside the hour. Failure to qualify or port within the cap is
> reported as failure/partial scope, not hidden by lowering obligations.

(This replaces my r2 S-16's "3 clean runs" and "1-3 two-sided rules from 2 clean runs": GPT's "no
threshold learned from two observations" is the stricter, safer rule. Procedure in §5.)

### M21. Cost and humans: AGREED

> **(GPT r2 A7)** No model chooses inputs or reads every step. Scripts decide the frozen verdict. A
> person/model reads a non-pass offline for diagnosis; time/tokens are charged separately. Precursor c2
> cost is 161–199 s full and about 55 s short; integrated cost has not been measured. I think reserve 3–4
> minutes per ordinary command, plus bounded startup/shutdown and qualification costs. Print expected and
> maximum cost before launch and measured cost after. Runs stay muted/behind user windows. Research
> qualification uses R9 stills/traces; it does not repeal the project's later recorded-walkthrough rule.
> No claim that this audit ran or verified the game.

---

## 3. Verdict words and headline order (exact)

**One line, one status** (M14):

| Status | Exit | Means | Owner tag |
|---|---|---|---|
| **PASS (scope)** | 0 | valid health; every mandatory scenario and work item complete; every required window valid and complete; no required failure | none |
| **FAIL: <named thing>** | 1 | a valid required contract or check failed | `owner=GAME` only when valid prerequisites and the measured contract violation establish it; else `owner=UNRESOLVED` |
| **INCOMPLETE: <what's missing>** | 2 | mandatory work / window / reach receipt absent (incl. reason **STALLED at <step>**, and the jump / drive-off reach per M11 / M10) | `owner=UNRESOLVED` |
| **TEST: <what>** | 3 | invalid required observation, malformed plan / event, failed required output, demonstrated test input failure (incl. reason **KILL FAILED**, a logged unplug) | test |
| **NOT HEALTHY: <what>** | 4 | frozen / stopped physics, unallowed pause, missing required actor | `owner=UNRESOLVED` (TEST only for a logged unplug, M16) |

**Per-rule and scope lines** under every status: evaluated / windows completed / errors / findings;
**NOT REACHED** (healthy, trigger absent: neutral; mandatory -> also INCOMPLETE); **NOT PROVEN**
(outside scope).

**Headline order:** M15's key. Default `"priority"`: TEST > NOT HEALTHY > FAIL > INCOMPLETE > PASS.
Option `"time"`: earliest condition by when it began; ties within 2 s ranked NOT HEALTHY > TEST >
FAIL > INCOMPLETE. Either way every condition prints with its time; nothing is erased.

**Where the DISPUTED keys land** (so the table is exact under either setting):

| Key | Default (G) | Option C |
|---|---|---|
| `null_object` (M5) | required object null / freed / empty -> TEST | -> FAIL owner=UNRESOLVED |
| `script_error` (M6) | any SCRIPT ERROR -> TEST | `scripts/dev/` -> TEST; game code -> FAIL owner=UNRESOLVED |
| `departure` (M10) | `"witness"`: departure NOT PROVEN, required departure INCOMPLETE | `"checks"` (**the default here**): today's two checks are the receipt; missing -> INCOMPLETE |
| `jump_tries` (M11) | 1: a flat-out miss -> INCOMPLETE | 3: landed within 3 -> PASS with the misses in the line; 3 misses -> INCOMPLETE |
| `headline` (M15) | `"priority"` | `"time"` |

Example (defaults): `RESULT: INCOMPLETE (exit 2): flat-out jump missed at 66.5 km/h, lane +0.5, owner
unresolved. Contracts 7/7 families evaluated, 0 findings, 0 errors. Health valid. Asked 2 / started 2 /
ended 2 / verified 1. Scope: ramp,c2_more profile k4. NOT PROVEN: ... Evidence: appdata/method/runs/<id>/`

---

## 4. The rules for the exam stretch

All numbers go in `tools/method/frozen.json` with their source run, committed before the referee's
requalification (M19). **Generic** and **puzzle-specific** are counted apart; all seven families were
written with P1-P7 known (practice-informed, M1).

### Generic (relation reusable; threshold frozen)

| Rule | Fires when | Clean margin, or the measurement the builder takes before the freeze |
|---|---|---|
| G1 nothing moves after the game's reset | horizontal drift > 0.30 m in the hands-off window | clean 0.039-0.045 m; P1 0.42 m in 1.9 s and 2.71 m in 5 s (`trial_c2.md`). Mandatory 5 s window in `c2_more`; played-route window evaluated, not mandatory (M3) |
| G2 nobody swims far past their bank | ground > 0.30 m above water AND > 5 m past own bank target for > 1 s | clean max -0.666 m over ~1,850 looks; P3 far (`trial_c2.md`) |
| G3a lower ground | parked 0.5 s, part bottom < ray-hit - 0.12 m | clean worst tyre -0.072 m: **0.048 m margin, the tightest**; hub about -0.013 |
| G3b attachment (hub + 4 tyres) | residual in wheel frame > frozen tolerance | **builder measures** on q1 / q2 (F1 state + played landings): tolerance = clean max norm + 0.01 m; clean max must be <= 0.01 m or G3b is unqualified (never widened); the displaced-hub control must fire |
| G4 HUD matches the wheel | mismatch > 0.5 s; loose wheel > 1.5 m | 0 mismatches in 666 looks; P7 |
| Health (M3) | 20 s no beat; 10 s no physics; 5 s pause; 2 beats actor missing; 45 s to first beat | c1 controls N1-N4 <= 27 s; startup: **builder measures** both clean startups, the profile is unqualified if one exceeds 45 s |
| Deadlines (M3) | shot 5 s; setup 10 s; drive/reset 46 s; reset wait 6 s; door 4 s; until(t) t+2 s; ramp 240 s; c2_more 90 s | g2 N5 5.02 s; arms 41-52 s; c2 full 161-199 s. **Builder measures** each episode on q1 / q2; the profile is rejected (not re-tuned) if clean work exceeds a cap |
| Ledger (M9) | a required ID absent at the end | mechanism generic; **the ID list is puzzle-specific**, declared from the source before q1, verified by q1 / q2 |
| Script errors (M6) | any, current run | 0 in every c2 and g2 run |

### Puzzle-specific (the ramp)

| Rule | Fires when | Clean margin |
|---|---|---|
| D1 crate's spot clear | any fixed solid in c2's 1.0 x 0.7 x 1.2 m volume | 0 solids clean (rubble within 1 m: thin, listed); P4 |
| D2 wreck above water | rendered top below water | +1.905 m clean; P5 -0.39 m |
| D3 P1 walks in by the door on W | not across the open doorway in 4 s | crossed in 4 s clean; P2 0.28 m short |
| `t_ramp`'s 39 checks | a required check false | each a ramp fact; all held in the 7 / 11 c1 runs that finished (`scoreboard.md`) |
| Jump reach (M11) | see key | 9 / 33 clean flat-out misses (C's count) |
| Drive-off reach (M10) | see key | 2 / 9 clean landings failed it (c1) |
| Spread (M12) | lip speeds don't span 61-68 | flat out tops at 66.7-67.0 measured: likely unmet at the top |

### R5 / R7: what it claims, and NOT PROVEN (printed every run)

- **Claims:** on `ramp,c2_more`, profile k: the run was alive, in control and complete; every
  required check ran and held; where each rule was evaluated, the state was right; P1 crosses the open
  doorway on W; the reset after a keys-only slow miss holds the van; the jump landed at the logged
  speed and lane (on the try M11 allows); the drive-off as M10 claims it.
- **Declared setup, not proven** (`t_ramp` at `0e8ef90`): the sight-line placements before the jump;
  the hut stretch's placements (P1 under the window, by the crate, on the crate; P2 in the river and
  behind); the wheel set by the hub (`w.global_position = ...`); `look_at_point` cameras; `c2_more`'s
  F1 jump, door setup and P2 put in the river. The builder prints the exact lines.
- **NOT PROVEN:** that a player can reach those placed spots; two-player hut completion between them;
  what a player sees (observer pictures only, R2); a landing-only bug via F1 (R13); why a 66.5 km/h
  jump sometimes misses; speeds under the slowest landed profile; the drive-off past M10's claim;
  "floating above the ground" beyond G3b's attachment; secret bugs no rule, check or deadline looks
  at; fun; any whole-game result.

---

## 5. The port procedure for the unseen puzzle (fixed now)

Rules: M20 (GPT's words). Steps the builder follows, in order, inside ~1 hour:

| # | The builder writes | Min (I think) | Reused as is |
|---|---|---|---|
| 1 | Read the puzzle's code and its existing scenario; list its required work from the puzzle's design, before any run | 8 | supervisor, health, deadlines, kill, reducer, statuses, `frozen.json` keys, the five DISPUTED settings as frozen |
| 2 | Manifest: scenarios; required-work IDs + branch outcome IDs (M9); setup vs input-only stretches (M18); typed bindings for every field read (M4); objects that must exist (M5, if C) | 12 | validated-read helpers, ledger, scope printer |
| 3 | Generic rules: bind G1-G4 where their trigger exists, unchanged thresholds; else N/A with a reason | 5 | G1-G4 code |
| 4 | 0-3 puzzle relations from construction / design (e.g. "the X sits where it was built"), no threshold learned from runs; else NOT PROVEN | 12 | G3b's attachment pattern |
| 5 | OPEN / CLOSE on any new await; reach steps marked (retry count from M11's key) | 5 | helpers' deadlines |
| 6 | Two clean bounded runs; budgets by `2 x larger + 1 s`, min 5, max 46; publish the adapter + limits, commit | 12 | |
| 7 | Report: hours, lines by actor / binding / predicate / fixture, reused vs new rules, unsupported work | 6 | |
| | **Total** | **60** | |

**Not promised:** a new whole-puzzle actor; if the puzzle's own scenario is flaky, the clean runs
show it and it is reported, not tuned (both r2s).

---

## 6. The build list for the Opus builder (~60 minutes)

**Before the clock:** the user's A / B answers on M5, M6, M10, M11, M15 are written into
`tools/method/frozen.json`; any unanswered key takes its default. Branch **`g14-final` from
`04c3102`** in `MPG_dev`; nothing on C:; one game at a time, `tasklist` first; game files hashed
before and after; no game edits. GDScript edits go in **one batch** (a running test must not load
changed files); Python is written while runs go.

| # | Step | Min | Total |
|---|---|---|---|
| 1 | Branch, hash game files, read `C2Watch.gd`, `t_ramp`, `ramp_try`, g2's `rd` / `_stale` / `preflight` / `open` / `close` / `kill` | 4 | 4 |
| 2a | **Game-side batch.** Validated reads in `C2Watch` (g2's functions), per-rule evaluated / windows / errors / findings, M5 key | 7 | 11 |
| 2b | G3b attachment for hub + 4 tyres, residuals logged | 4 | 15 |
| 2c | OPEN / CLOSE with unique instance IDs in `shot`, `until`, `place_player`, `ramp_try`, reset wait, door, outer phases, episodes | 5 | 20 |
| 2d | `check()` logs stable semantic ID + outcome; the required-work manifest (incl. M10 key) | 5 | 25 |
| 2e | `t_ramp`: profile k from the command (M12 table), targets and actuals logged; the jump loop with `jump_tries` (M11) | 4 | 29 |
| 2f | `RigInject` fixtures, test-only, behind flags: N5 (an await that never fires), displaced hub, early return | 3 | 32 |
| 3 | Compile; **q1 clean k0**. Meanwhile write `tools/method/method_watch.py` from `g2_watch.py`: monotonic timers, unique OPENs, live error veto + M6 key, verified kill, 45 s startup | 5 | 37 |
| 4 | **q2 clean k4**. Meanwhile write `method_verdict.py` (statuses, M15 key, scope print) and `tools/method_run.sh` | 5 | 42 |
| 5 | Read q1 / q2: G3b residuals, startup and episode times, window lengths, ledger IDs seen; freeze `frozen.json`; commit **before any control** | 4 | 46 |
| 6 | Controls on `c2_more` (~1 min each): **T4** (rename `_swim_to` in `PlayerRig.gd`, revert), **N5**, **displaced hub**, **early return**; host fixture for never-started / started-no-end / ended-no-work (no game) | 6 | 52 |
| 7 | **q3 clean k2** on the final code, fixtures off | 4 | 56 |
| 8 | Report: SHAs reused, diffs, every run's line, frozen values, game hashes unchanged, departures; commit | 4 | 60 |

**Adds, only if the user chose C (each inside the hour by the cuts below):** M6 C: +3 (path parse +
SE_GAME / SE_TEST controls); M15 C: +3 (times on every condition); M5 C: +1. M11 C and M10 C: +0.

**Cut order, with the fallback frozen in advance:**
1. **`FN_RECORD=1` wiring** (not in the 60; built only if time is left) -> "diagnostic recording
   unsupported in this build" (GPT r2 D4 allows it, agreed before the freeze).
2. **M6 C's two controls** -> M6 runs as G (TEST for all), reported.
3. **The tyre half of G3b** -> tyre attachment NOT PROVEN; the hub stays (P6 still covered).
4. **M15 C's time ordering** -> M15 runs as G, reported.
5. **q3** -> only if every fixture is flag-only and off by default; reported "final code not run
   clean by the builder"; the referee's requalification clean runs cover it.

**Never cut** (GPT r2's list, agreed): C2 dependency validation and T4; the hub attachment and its
negative control; N5 with process gone; required work / window receipts; the frozen M11 setting
(either side); fixed statuses and scope; the game unchanged; failure evidence kept. Not fitting
these = failed or partial qualification, reported.

**Qualification it must pass (inside the hour):** q1, q2, q3 clean: each ends with a status and no
TEST / NOT HEALTHY; the route-PASS path is shown by at least one clean command that reaches the end
(a clean INCOMPLETE at a reach step is recorded, not fixed, and is not a route PASS; if none reaches
the end, the route-PASS path is reported unqualified for the referee's clean runs). T4 -> TEST before
the drive; N5 -> INCOMPLETE (STALLED) within ~6 s of the OPEN, process gone; displaced hub -> FAIL G3b;
early return -> INCOMPLETE naming the missing IDs; the host fixture's three cases named apart; G3b clean
max <= 0.01 m. If a clean run fails for a test-side cause: one fix round (R10), then report; no third.

**Then the referee:** requalifies the frozen head (clean runs, T4, N5), freezes, runs the exam.

---

## 7. Cost per run, the user's command, what it can't do

```
bash tools/method_run.sh ramp          # ramp,c2_more, next profile k (logged)
bash tools/method_run.sh ramp k3       # a chosen profile
FN_RECORD=1 bash tools/method_run.sh ramp   # diagnosis only, if built (cut 1)
```
Output under `MPG_dev/appdata/method/runs/<id>/`; muted, behind the user's windows; refuses a second
game in the copy.

| | Cost | Source |
|---|---|---|
| Normal run | **3-4 min** (I think; integrated cost not measured) | c2 161-199 s full |
| Each extra jump try (M11 C only) | +~45 s, on ~1 run in 4 | g2 arms 41-52 s |
| Worst case (a stall) | the phase's deadline + kill, <= ~60 s after the stall | M3 |
| Model time / tokens per run | **0** | no model in the loop |
| The user's reading | one line on PASS; ~1 min on a non-pass (line, numbers, one picture) (I think) | |
| A diagnosis (asked for) | ~2-5 min of model time, reported apart (I think) | GPT r1 §7 |

**What it can't do:**
- Prove anything a player does between the declared placements in the hut.
- Explain why a 66.5 km/h jump sometimes misses; fix the drive-off flake (2 / 9 landings). **With
  today's driver, S1 10/10 is unlikely under either M11 option** (§2 M11 table, I think).
- Reach 68 km/h at the lip (flat out measured 66.7-67.0).
- Catch a secret bug no rule, check or deadline looks at (a colour, a sound, a note's wording).
- Tell game from test for most failures: owner UNRESOLVED is the honest default.
- Judge looks or fun; pictures are for a person.
- Under M11 C: pass-hide a jump bug that only sometimes makes it miss (stated limit).

---

## 8. Signatures

**Claude auditor:** signs M1, M2, M3, M4, M7, M8, M9, M12, M13, M14, M16, M17, M18, M19, M20, M21;
holds M5, M6, M10, M11, M15 (as Option C above, with the defaults as written).

**GPT auditor:**
