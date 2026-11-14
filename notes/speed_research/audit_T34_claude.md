# Audit of the T3 + T4 v2 build (Claude auditor, 2026-11-14)

Task: `audit_T34_claude_task.md` (read first; only its list read; no DO-NOT-READ file opened). Copy `MPG_speed_t34`,
branch `speed-t34`, head `f208e6e` (verified), diff against `speed-t1` `709028b`. No game run, no code changed. I ran the
four offline controls; their runs **rewrote** `appdata/t3ctl`, `appdata/t4ctl` and `appdata/t34/joinctl` (the scripts
rmtree and rebuild their fixtures), so the fixtures I judge are fresh from my run, not the builder's. `git status` clean.

Verdict words: **CONFIRMED** (the evidence says it), **WRONG** (the evidence says otherwise), **NOT SHOWN** (no evidence kept).

## 1. Report vs evidence

**My rerun of the offline controls**

| Script | Builder says | My run | Verdict |
|---|---|---|---|
| `t3_controls.py` | 49 / 49 | **49 / 49**, rc 0 | CONFIRMED |
| `t4_controls.py` | 83 / 83 | **83 / 83**, rc 0 | CONFIRMED (but see section 2: 7 cases can't fail) |
| `t4_join_controls.py` | (used by t4 `join`) | prints nothing, rc 0. It's a module with no main; `t4_controls.py join` runs it | as designed (`t4_join_controls.py:1-9`) |
| `t1fix_controls.py` | REPLAY_USAGE section 0 lists it as a self-check | **crashes**, rc 1: `FileNotFoundError ... appdata\method\runs\20261111_111720_ghat_k3_fast` (`t1fix_controls.py:42`). T1's run folders aren't in this copy | **WRONG as a replay step** |

**`trial_T4_build.md`, the "Game runs" table**

| Row | Claim | Evidence | Verdict |
|---|---|---|---|
| 0 | import, rc 0 | `appdata/import_check.log` ends at `DONE loading_editor_layout`; no error lines seen in its tail | CONFIRMED (tail only) |
| A | CTRL held at the picture, fixed by a flush | only the commit `822e151` message; no run output kept for A | NOT SHOWN |
| A2 | "pad A did not swing the nav in this 4th walk of the process" | `runA2_probe.out:4-8` FAIL at "2 P2 swings the nav" | FAIL CONFIRMED. The "4th walk" cause is **WRONG**: see A3 |
| A3 | failed again in a new game; changed to N; DONE, 6 points | `runA3_probe.out:4-5` FAIL at frame 800 (a **fresh** game); `runA3b_probe.out:4-14` N PASS, DONE | CONFIRMED. So pad A failed **2 / 2, fresh game included**: a steady miss, not a same-game replay effect |
| R3 (resume) | refused before input (floats vs ints), then fixed | `runR3.out` present; fix in `055508b` | CONFIRMED (commit and log) |
| C1 | not run | the offline refusal of every point (section 3) | CONFIRMED |
| G | 5 rows | `appdata/t34/gate_session.log` and the three `*.gate.json` receipts: every row as written (row 2: BatteryBox / Crate0 velocities, `_safe_t` 0.4833 -> 0.4 on BatteryBox **and BoatDrum**; row 3: `ghat._check_t` ...34 -> ...36; row 4: nav_aside, 0.055 m, 0.0639 m/s, 1.6000 C; row 5: 0.152 m) | CONFIRMED |
| R1 | DONE, on time, framemap offset 0, **sound PASS**, "57 % in the walk, 39 % incl. boot" | `R1.out`: DONE, FRAMEMAP proved, 39 %. **No `SOUND:` line in any output** (`join_check.py:313` prints one; grep of `appdata/t34`: none). The walk % is 57 here but **51 %** in the report's own Re-measure table | sound **NOT SHOWN**; 57 vs 51 **WRONG** (inconsistent) |
| R2 | 2.67 union, 47 %, sound PASS | `R2.out` present; no `SOUND:` line | sound NOT SHOWN; minutes are the meter's |
| R3 (late) | FAIL by name at rec25, nothing held, refused resume | `R3.out`: "took longer than its limit", held [] | CONFIRMED |
| R1b | 52 %, life 59 s, CPU 38 % (13-91) | `R1b.out`: "recorded in 00:00:57 (52%)", life ~59 s; `R1b_cpu.tsv`, rows with a game alive: **37.8 % (13-91)** | CONFIRMED |
| R4 | SENTINEL PASS, 51 %, CPU 52 % (37-82), heartbeat 4773 -> 4956 | `R4.out` / `sentinel.log`: all `ok`, SENTINEL PASS; `R4_cpu.tsv`, both games alive: **52.3 % (37-82)** | CONFIRMED. **Left out:** `sentinel.log` says "lane b walks: **2 ok of 4**" (section 4) |
| totals | ~17.2 | the running sums add up. Slips: two rows are both called "R3"; the "T4 total" column also counts T3's R4 (2.0) | bookkeeping only |

**`trial_T3_build.md`:** 49 / 49 CONFIRMED; "real PlayTest.gd: the same 116 ids" CONFIRMED (control output); the R2 / R4
sentinel facts CONFIRMED (`sentinel.log`). "Lane b played 4 walks as its workload the whole time" is true but **leaves out
that 2 of the 4 failed**. The spec asks the throughput test to check step quality (T4 v2, "25-fps recording profile").

**What the T4 report is missing** (the build task asks for files, every deviation and each control pair): there is no
files / interfaces section, **no deviations section** (row A3 says "see the deviation", and none exists in any version of
the file: `git log` on it, 4 versions), and no list of the 83 control pairs.

## 2. The control fixture pairs (t3ctl, t4ctl)

- **Every planted case fails and every clean case passes** in my run: 49 + 83, no disagreement. List per piece: T3 ident
  10, manifest 8, final 16, proof 11, obs 4; T4 ident 15, inv 5, refuse 9, hear 9, work 5, child 5, l2 8, l3 10, join 16.
- **7 planted cases can't fail (a slip, not designed):** `ident game / test / bin / schema / profile changed`,
  `ident producer step changed`, `ident resumed step changed` (`t4_controls.py:76-89`). Each one runs `wg.admit` on the
  **real point 1**, which is already refused for its 0.148 m/s velocity. The control only compares REFUSED / ADMIT, so if
  the identity check were deleted it would still print `ok`. My output shows the van-velocity reason next to every
  identity reason. Today's output proves the identity checks fire, but these controls don't guard them. Fix: call
  `identity_check` directly, as the clean case on line 73 does, or start from `quiet()`.
- **Designed, not slips:** `work empty lists alone do not pass` uses point 4 (refused by the engine), as its name says;
  `refuse van at 0.09 passes the prefilter` -> ADMIT is paired with layer 2 naming the lost 0.09.
- **1x vs fast:** no t3ctl / t4ctl fixture has a speed pair. The only speed case is `final looks run fast` -> REFUSED,
  designed (`FAST_OK` in `method_run.sh:48`). The 1x / fast pairs live in `t1fix_controls.py`, which crashes in this copy
  -> **NOT SHOWN** here.
- **The live layer-3 pair doesn't separate.** The planted +0.2 m van (G5) is DIFFERENT, but so is the clean resume (G4).
  A pair where both sides say DIFFERENT proves nothing about layer 3 on a live walk. The report names G4 DIFFERENT but
  never calls this a failed control pair.
- **Join frame pair (looked at):** `join1_before.png` is the cab at the hairpins. `join1_after.png` is **a full magenta
  frame**: the cut lands on the frame marker. That holds for this control (CUT = the marker step), but it shows that the
  frame "after" a join can be the marker, and that frame would sit inside a real joined video.

## 3. The resume gate: real lost state, or a gate that's too strict?

The evidence is the six point observations of A3 (`points/gateprobe_20261111_122158_4980/{0..5}.obs.json`) and the game
code. Godot facts come from those files, not from memory, except where marked.

| Difference | What it really is | Does it change what happens after a resume? | Gate |
|---|---|---|---|
| **van `@lv` 0.148 m/s, frozen** | Points 1-5: `van.@xf` is **identical to every digit for 19.5 game s** while `@lv` reads 0.148 each time. The body doesn't move, so it's a stale **node-side value** with no physical motion. Game code still reads it: `Camper.gd:1042` speed -> `odometer += speed*delta` (`:1135`). Odometer 8.3207 -> 8.9359 over 4.167 s = **0.1476 m/s**: the ODO creeps while parked | Barely. The ODO (saved, `SaveGame.gd:105/170`; shown at 0.1 km, `Camper.gd:1327`; no check reads it) creeps at a different rate. With the engine on, the temp target moves by 0.25 x speed = 0.04 C. Nothing a walk check reads | **too strict as worded.** "Lost physics state" is wrong: no motion is lost |
| **van `@freeze`**, which the restore turns off | `SaveGame.gd` apply: `c.freeze = false` and the velocities zeroed. The van is then dynamic until `_update_parked` freezes it again after 0.6 s (`Camper.gd:1369-1373`), and it may creep meanwhile (the comment at `:1347`) | **Yes, a real change** (cm of creep; a new stale velocity: G4's 0.064 m/s) | this is the thing to refuse or compare, and the gate doesn't name it |
| **van temp 1.6 C at +3 s** | Engine-off cooling is 1.60 C/s (points 1 -> 2: 81.97 -> 75.31 C over 4.167 s). 1.6 C = **exactly 1.0 game s**. `LiveControl.gd:668` `await pt.wait(1.0)`, then polls for the client's verdict (`:671`) **before** the step and its +3 s sample start (`:756`). The fresh run's sample has no such second | **Yes**: the resumed world is ≥1 s further on (heat, fog, timers). It's the resume procedure that changes the state, not the saved state | **refusing is right**, but the cause is test-side: the fresh reference and the resume aren't lined up |
| players 5.5 cm | inside the same settle second (players re-seated by the restore). Below the 0.15 m check margin | small, real | follows from the settle |
| `nav_aside` fresh true / resume false | the resumed step's N tap didn't swing the nav. No layer-2 field explains it (the receipts list only items and `_check_t`), and the same miss happens in **fresh** lane-b walks (section 4) | it changes the step, but the cause is input delivery, not lost state | this layer-3 result is **confounded**. It doesn't show lost state |
| layer 2: items' velocities ~1e-5 m/s, transforms differing in the 9th digit, `_safe_t` / `_last_safe` | sleeping carryables 150-1300 m from the van (BatteryBox x 1870, Crate0 x 407); float32 text noise; safety-net timers | no effect on the walk | too strict, but **v2's "exact equality" requires it**: a decision for the referee, not a builder slip |
| `ghat._check_t` 17th digit | the float round trip loses one ulp | none | same |

**Conclusion:** the refusals are honest (nothing unsafe gets admitted), but on this game as built **no parked-van boundary
can ever pass**, and three of the reasons are artifacts:

1. The velocity rule reads a stale cache.
2. Layer 3 compares two worlds that are 1 s apart.
3. Layer 2 demands bit-equality on sleeping, far-away items.

The real lost state is the **freeze flag** and the **settle second**. In practice D3's resume path buys nothing in the
replay: every repair needs a fresh prefix, which T3's 19-minute allowance has to absorb.

- Godot fact taken from memory, not verified here: GodotPhysics3D zeroes a body's server-side velocity when it switches
  to static mode, and a static body's node is not re-synced. The obs data above shows the same thing without needing it.
- **The game run that settles it:** one gate session (~2 game min). Restore point 1, take the fresh reference at the
  same world offset as the resume (or move the settle before the point), and log `@freeze` and the raw server velocity
  (`PhysicsServer3D.body_get_state`).

## 4. The nav swing

- **Pad A (A2, A3): test side, and steady, not "sometimes".** It failed 2 / 2, including a fresh game at frame 800. The
  game picks SOLO when `devices[1]` is the keyboard (`Boot.gd:119`). The walk's pad press had no seated player's device
  behind it. The builder's switch to the N key was right; calling it "the 4th walk of the process" was wrong.
- **N key / X hold in lane b (R4): fails sometimes, fresh walks included.** `sentinel.log` says "lane b walks: 2 ok of 4".
  The raw `sentinel_b_walk.log` has 4 DONE and 5 FAILED lines: 3 failed at "2 ... (N)", 2 at "3 the engine on" (X hold).
  So it's not about a replay in the same game, and not about resume state.
  - Input is read on the physics tick after Boot polls it (`Boot.gd:413-416`, `InputDevice.gd:184`), which is fine.
  - `PlayTest.tap` (`PlayTest.gd:378`) holds for 70 ms of real time and **never re-sends** a press. `hold_physics`
    (`:385-393`) re-sends when "a window focus change dropped it", which is this code base's own note that a focus change
    drops presses.
  - A re-sent press is a **second** `just_pressed` edge, so `toggle_engine` runs twice and the engine ends up off. That
    fits the step-3 failures.
  - Likely cause, **unproved:** the second game window or the recording takes focus. A ~1 game-min bench settles it:
    one game, 20 N taps, with and without a second window coming up, logging focus-out.
- **Cost to a replay that plays several walks in one game, or two lanes:** each tap is a chance of a false FAIL at the
  first step that needs it. First-FAIL-stop plus "no rerun-until-green" turns that into a whole extra prefix, and into a
  false game failure if no one reads the picture.
- **What the tool does about it: nothing.** No guard in `tap`, no focus check, nothing in REPLAY_USAGE. The T3 sentinel
  prints PASS while lane b's walks fail, because the sentinel doesn't judge its workload.

## 5. `REPLAY_USAGE.md`

| Line | Check | Verdict |
|---|---|---|
| section 0 `t3_controls.py` | runs, 49 / 49 | OK |
| section 0 `t1fix_controls.py` | crashes (missing T1 run folders) | **WRONG**: remove it or ship its fixtures |
| section 0 `live_session.sh import` | `live_session.sh:10-11` has an `import)` case | OK. "~0.2 min" is a measured timing (minor) |
| section 1 manifest, `t3_gate.py obstable <table> <manifest>` | argument order matches `t3_gate.py:246` | OK |
| section 2 `ROLE / SPEED / GHAT method_run.sh ghat`, `combine_parts.py` | routing `FAST_OK` = heat, net, marks (`method_run.sh:48`); the file exists | OK |
| section 3 `play_walk.sh ghat [--fresh]`, exit 5 | `play_walk.sh:11,22` | OK |
| section 5 `tree_id.py stamp`, `t3_gate.py final <inv> <frozen>` | `tree_id.py:116`, `t3_gate.py:231` | OK |
| section 6 `prove_ghat.py`, `t3_gate.py proof <final> <prove_...>` | `prove_ghat.py:126` names `prove_<g>_<time>_<pid>` | OK |
| section 7 `record_walk.sh ghat --fresh` "-> ghat.mp4 (+ ghat.parts/, **framemap_rec25.json**)" | the framemap is written only if the walk has a `marker` step (`record_walk.sh:110-111`). **`tools/live/ghat.json` has none** (grep: 0). So a real take never gets a framemap, and `join_check verify / join` refuses any cut ("mapping not proved") | **WRONG**: a joined real take (D1) can't be built as shipped |
| section 7 `GATE_ONLY=1`, `join_check verify / join / sound` | `record_walk.sh:44-53`, `join_check.py:319-332` | OK |
| section 8 `lane_sentinel.sh`, `stop_lane.sh [b]`, `godot_guard.py [b]`, `cpu_sampler.ps1 -Out -Stop -HbB` | all exist; parameters match `cpu_sampler.ps1:2` | OK |
| trial results / game symptoms | none found (no hole, no symptom) | OK |

**What a runner needs that's missing:**

1. Every resume of a parked-van point is expected to be refused, so plan fresh prefixes (section 3).
2. Add a frame marker to the real walk, or the joined-video path doesn't exist.
3. marks' fast PASS counts only with its looks prelude's round in the same run (T1's table; the T3 report calls it a gap
   in the checker). The runner isn't told to check it.
4. A way to compute the 75-minute projection: a per-step cost table, or a ledger format.
5. What to do when an input misses with two lanes up (section 4).

## 6. Departures from the v2 specs and `top4.md`

| Departure | Named in the report? |
|---|---|
| Layer-3 tolerance: `top4.md` says "from two resumes of the same point"; built as fixed bounds in `gate_inventory.json` written before trials | v2 itself makes this change. Built as v2 says: OK |
| No live SAME resume, no D3 two-receipt resume on a real point | yes, UNQUALIFIED |
| The live layer-3 pair doesn't separate (clean G4 DIFFERENT, like the planted G5) | **no**: G4 is listed, but not as a failed pair |
| The fresh +3 s reference isn't lined up with the resume's 1 s settle (v2: "fresh reference at +3 game s while actual actions execute") | **no** |
| The refusal names a stale velocity as "lost physics state"; the real loss (the restore unfreezes the van) isn't named | **no** |
| "Decode / check known captured sound": no saved result | claimed PASS without evidence |
| Throughput test "checking step / capture quality": lane b's 2 / 4 failures not reported | **no** |
| Drawn-frame -> movie-frame proof exists only for walks with a marker; the real ghat walk has none | **no** |
| Probe walk: pad A -> N key | in the table, but the "deviation" it points to doesn't exist |
| Looks moved to 1x (T1 round 2); marks' prelude can't be checked | yes (T3 report) |
| Test-only gate bypasses `GATE_PROBE`, `GATE_L2_CONTINUE`, `GATE_PERTURB`, `JOIN_GATE_WAIVED` | yes. Fenced: the receipt stays REFUSED (`gate_session.log`), and a waived join must be written to a `*TESTONLY*` name (`join_check.py:234`) |
| Game code untouched | CONFIRMED: the diff touches only `scripts/dev/` (GateObs, LiveControl, PlayTest) |
| Budget (T4 hard 15, T3 hard 5, stop at 20) | ~17.2 in total; T4 ~12.7 + the void run, T3 ~2-4.5: inside the caps (the meter decides) |

## Verdict: ACCEPT WITH CONDITIONS

The core guards are sound and fail-closed:

- identity, receipts, the final / proof gates, refusal before input, cancellation, the late fixture, misroutes, lanes;
- all planted cases are refused in my rerun.

But the resume path can't produce a single SAME on this game, two report claims have no evidence, and two runner steps are
broken. Each condition below: the miss it guards against, and its cost.

1. **Fix REPLAY_USAGE section 0** (drop `t1fix_controls.py` or ship its fixtures). Guards against: a runner's first
   command crashing, then being skipped or "fixed" on the fly. **0 game min.**
2. **Make the 7 identity controls able to fail** (call `identity_check` directly). Guards against: a later edit
   silently disabling the old-game / changed-walk refusal while the controls stay green. **0 game min.**
3. **Real ghat walk: add a frame marker (report the walk edit), or write in REPLAY_USAGE that only an unbroken fresh
   take is possible.** Fix the "(+ framemap_rec25.json)" line. Guards against: the replay counting on D1's joined take,
   then finding at the end that no cut can be verified (~13-16 wall min of recording lost). **0 game min** (the marker
   is proved in the first take).
4. **Save the sound evidence:** run `join_check.py sound` on R1b's mp4 and keep the `SOUND:` line. Guards against:
   a silent movie track passing as "sound PASS". **0 game min** (ffmpeg only).
5. **The resume gate's alignment, and the referee's ruling on 3 strictness classes:**
   - the stale velocity of a frozen body (compare `@freeze` instead);
   - sleeping, far-away items' float noise at layer 2;
   - the settle second (line up the fresh reference, or settle before the point).

   Then rerun one gate session. Until then, REPLAY_USAGE must say "expect every parked boundary refused; budget fresh
   prefixes". Guards against: (a) a budget built on resumes that will all be refused; (b) a later loosening without
   evidence. **~2 game min** (one session like G), or 0 if the referee keeps "always fresh".
6. **Bench the dropped taps** before a replay plays walks in two lanes or several walks per game (20 N taps, with and
   without a second window coming up; log focus-out). If confirmed, re-send a dropped tap the way `hold_physics` does,
   without making a second edge. Guards against: false game FAILs and extra prefixes in the replay (lane b: 2 of 4 walks
   failed). **~1 game min.**
7. **Complete the T4 report:** files / interfaces, the missing deviations section, the 83 control pairs, the R1 walk %
   (57 vs 51), unique run IDs, T3's R4 out of the T4 column, lane b's 2 / 4, and G4 + G5 called a failed live pair.
   Guards against: the referee scoring on claims that aren't in the files. **0 game min.**

Total extra cost: **~3 game min** (conditions 5 and 6), plus offline edits.
