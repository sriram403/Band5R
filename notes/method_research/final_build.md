# The final method: build and builder qualification (Opus builder)

2026-11-06, branch `g14-final` in `MPG_dev`. Clock: started 15:12:14, finished 15:36
(24 min by `date`; cap ~60).

## Verdict: QUALIFIED (builder's qualification; the referee requalifies)

Every item of draft §6's qualification (with C4's additions) was run and held inside the hour:
q1 and q2 clean **PASS** (route PASS shown at k0 and k4); q3 (k2, the exact final head) a clean **INCOMPLETE**: its one scheduled landing missed at 64.4 km/h, recorded as the user's one-try policy says (no TEST, no NOT HEALTHY); T4 -> TEST
before the drive; N5 (the real draw-await, physics live) -> INCOMPLETE STALLED 5.25 s after the step
opened, process gone; displaced hub -> FAIL G3b; early return -> INCOMPLETE naming the missing IDs;
the host fixture's three cases named apart; G3b clean max 0.0000 m <= 0.01 m; both M6 split controls
(SE_TEST -> TEST, SE_GAME -> FAIL). Nothing was cut. No fix round was needed on a clean run (R10
unused). The user's five policies are built as chosen, none swapped (C4).

What this does **not** show: a route PASS on the exact final head (q2 ran the same GDScript, `d407ae1`;
later commits changed only the Python reducer's listing and `frozen.json`'s measured tolerance, and the
final reducer re-reduces q2's archive to PASS); S1 over ten runs (here 1 landing miss in 3 clean runs, 0
drive-off failures in 2 landings); nothing about the exam.

## Branch, reuse, SHAs

| Step | SHA | What |
|---|---|---|
| base | `e34af9c` (`g12`) | the notes, current |
| reuse c1 + c2 | `4d51129` | `git checkout 04c3102 -- ` the 10 files of `git diff --stat e34af9c 04c3102 -- FindingNaresh tools`: `dev/C2Watch.gd(.uid)`, `dev/PlayTest.gd`, `dev/RigBeat.gd(.uid)`, `dev/RigInject.gd(.uid)`, `tools/c2_run.sh`, `tools/rig/rig_watch.py`, `tools/rig_run.sh` (1,184 lines, R8 / R1) |
| build | `387b75f` | MethodRec, C2Watch reads / G3b, PlayTest hooks, supervisor, reducer, manifest, pre-measurement `frozen.json` |
| fixture fix | `d407ae1` | the hub control moved before the parked look (flag-only, found before it ever ran); host fixture; deadline bookkeeping |
| **freeze** | `90178e9` | `frozen.json` with the G3b tolerance from q1 + q2, committed **before any control** |
| cosmetic | `776744f` | reducer lists only asked scenarios' checks; re-run offline on all 8 archives, statuses unchanged |
| report | (this commit) | this file, rough notes |

**From g2 (`afb9e9b`), taken by function, rewritten, not copied** (`git show afb9e9b:<path>`, nothing
overwritten): `G2Rec.gd` `rd()` / `_stale()` / `preflight()` -> `C2Watch.rd()` / `_bad()` /
`preflight()` (validated by name, type, instance, finiteness; extended with M5's ABSENT witness);
`open()` / `close()` -> `MethodRec.open()` / `close()` (now unique instance ids, judged on the
host's monotonic clock); the `shot()` OPEN/CLOSE hook; `tools/g2/g2_watch.py` `kill()` -> the
supervisor's `kill()` (taskkill tree, verify gone, plus C's retry once). Not taken (M3 / M13): the
recorder (`G2Rec` rows, trace), the 150 s startup, wall-clock deadlines, repeated-OPEN renewal, the
pair / causal tooling, `G2Ctl`.

**Not used, still in the tree:** c1's `rig_watch.py` / `rig_run.sh` and c2's `c2_run.sh` stay as
reused files but the method never runs them (one supervisor, no competing kill watchers, M1).

## What was built (test code only)

| File | Lines | What |
|---|---|---|
| `FindingNaresh/scripts/dev/MethodRec.gd` | 99 new | events file (flushed JSON lines), OPEN / CLOSE with unique ids, WORK / CHECK / ATTEMPT receipts, profile (M12 table), fixture flag (read only by fixture code) |
| `FindingNaresh/scripts/dev/C2Watch.gd` | +222 | validated reads (19 required fields, preflight + every read, M4); M5 ABSENT witness for must-exist objects (hut, bare hub, HUD warning label, wreck node, wreck meshes, each wheel's Tyre); per-rule evaluated / windows / errors / findings; window receipts (G1 complete = 5 s hands-off, G3 parked 0.5 s with valid probes; a failed ground probe is TEST, M8); **G3b**: hub + every visible tyre's centre in its own wheel's frame, logged; predicates of G1-G4, D1-D3 unchanged (M7) |
| `FindingNaresh/scripts/dev/PlayTest.gd` | +88 | OPEN / CLOSE on every helper of the selected path (shot 5 s; place_player / face_point / look_at_point / seat / ramp_start 10 s; ramp_try 46 s; drive-off min(secs + 8, 46) = 34 s; wait s + 2; until / walk_to / pad_walk_to max + 2 (walk_to + 5 for its stuck shot); frames n/60 + 2; hold s + 2; door walk 6 s; episodes ramp 240 s, c2_more 90 s); `check()` receipts; profile on the scheduled landing; attempts (target, lane, lip, lane at lip); c2_more work receipts; fixtures behind `--method-fixture` |
| `tools/method/method_watch.py` | 355 | the one supervisor: launches `run_test.sh`, owns the PID, health (M3 limits), deadlines (host monotonic), live veto, M6 split, kill + verify + retry, bounded wrapper shutdown, progress every 5 s, trace |
| `tools/method/method_verdict.py` | 197 | reducer: five statuses / exits, ledger (asked / started / ended / work / windows / evaluated), check manifest with M10 / M11 reach kinds, M15 earliest with the 2 s tie, scope; runs offline on any archive |
| `tools/method/make_manifest.py` | 58 | the 39 `t_ramp` check IDs from the source (slug + regex + line + kind), before any run |
| `tools/method/freeze.py`, `frozen.json` | 87, 431 | writes the frozen policy / limits / thresholds / required work / scope (60 declared setup lines) |
| `tools/method/host_fixture.py` | 54 | the three missing-receipt cases on the reducer, no game |
| `tools/method_run.sh` | 50 | the user's command, archive, refuses a second Godot |

## `tools/method/frozen.json` as frozen (`90178e9`)

| Key | Value | Source |
|---|---|---|
| `policy.jump_tries` | 1 | the user, M11 (Option G) |
| `policy.departure` | `"checks"` | the user, M10 (Option C): the two drive-off checks are the receipt; a failure = INCOMPLETE drive-off, owner UNRESOLVED; "drove away / where it stopped" NOT PROVEN |
| `policy.script_error` | `"split"` | the user, M6 (Option C): raised in `res://scripts/dev/` -> TEST; game code -> FAIL; owner UNRESOLVED both |
| `policy.headline` | `"earliest"` | the user, M15 (Option C): earliest by begin time, 2 s tie NOT HEALTHY > TEST > FAIL > INCOMPLETE, preflight TEST first |
| `policy.missing_object` | `"fail_unresolved"` | M5, GPT's C2 wording |
| limits | poll 0.5; first beat 45; no beat 20; no physics 10; pause 5; actor 2 beats; shot 5; setup 10; drive / reset 46; until + 2; door 6; episodes 240 / 90; kill verify 5 (+ one retry); tie 2.0; whole-command cap 600 | M3 |
| thresholds | G1 0.30 m / 5 s; G2 0.30 m, 5 m, 1 s; G3 -0.12 m, parked 0.5 s; G4 0.5 s, 1.5 m; D1 1.0 x 0.7 x 1.2 m; D3 4 s | C2Watch as built (M7) |
| `G3b_tolerance_m` | **0.01** | q1 + q2: 6 parked evaluations (per run: ramp parked on the hub = hub + 3 tyres; c2_more after the reset = 4 tyres; c2_more F1 state = hub + 3 tyres), **clean max norm 0.0000 m**; tolerance = 0.0000 + 0.01; clean max <= 0.01 holds (M8) |
| profiles | k0 (62, -0.5), k1 (64, +0.5), k2 (66, 0), k3 (80, -0.5), k4 (80, +0.5) | M12 |
| required | ramp: 39 check IDs (1 `jump`, 2 `departure`, 36 `plain`), 2 attempts; c2_more: work `c2.door_walk`, `c2.slow_miss_hands_off`, `c2.f1_landed_state`; windows G1, G3, G3b complete; evaluated >= 1 for G1, G2, G3, G3b, G4, D1, D2, D3 | M9, C1 (mandatory local coverage from `c2_more`) |
| scope | claims, declared setup (5 sentences + 60 exact source lines), NOT PROVEN (12 items) | §4, M18 |

Measured on q1 / q2 against the caps (closest instance to its deadline, q2): drive-off 25.9 / 34 s
(76 %), hold 7.0 / 9 s, wait 6.0 / 8 s, swim `until` 18.9 / 62 s, ramp_try 12.5 / 46 s, ramp episode
112 / 240 s, c2_more episode 26 / 90 s, shot 0.23 / 5 s. Startup (first beat after launch) 13.6 /
12.6 / 12.1-12.6 s against 45 s. No clean work exceeded a cap; nothing re-tuned.

## Every run (archives `appdata/method/runs/<id>/`)

| Run | Command | Result | Numbers |
|---|---|---|---|
| q1 | `tools/method_run.sh ramp k0` | **PASS** (0) | 161 s; 39 / 39 checks; slow miss 46.8 km/h; landed lip **60.7** km/h, lane at lip +0.49 m; drive-off 68 m, closest 0.0 m; c2_more rules all evaluated, G1 window 5.02 s complete (drift 0.045 m); G3b 0.0000 m |
| q2 | `tools/method_run.sh ramp k4` | **PASS** (0) | 161 s; 39 / 39; landed lip **66.2** km/h, lane at lip +1.37 m; G3b 0.0000 m |
| q3 | `tools/method_run.sh ramp k2` (final code, fixtures off) | **INCOMPLETE** (2): the scheduled landing missed | 75 s; slow miss 46.8 km/h; **k2 landing missed at lip 64.4 km/h, lane at lip +1.09 m** (target 66 / 0), owner UNRESOLVED; 33 later ramp checks listed "not reached after the missed landing"; c2_more complete (all 8 rules evaluated, G1 / G3 / G3b windows complete, G3b 0.0000 m); no TEST / NOT HEALTHY; no Godot left. A clean reach outcome: recorded, not fixed, not rerun |
| T4 | `PlayerRig.gd` `_swim_to` -> `_swim_target` (5 places), `tools/method_run.sh c2_more k0`, then `git checkout -- PlayerRig.gd` at once | **TEST** (3) **before the drive** | preflight +19.9 s: `p1._swim_to`, `p2._swim_to` "no member"; detected +20.1 s; kill 0.5 s after detection; **process gone 0.6 s**; never committed |
| N5 | `FIXTURE=n5 tools/method_run.sh ramp k2` | **INCOMPLETE** (2) STALLED | at `shot:ramp_note#18`: **5.25 s after the OPEN, 0.26 s after its 5 s deadline**; physics frames 93 -> 394 during the stall (live); kill at once; **process gone 0.5 s**; c2_more NOT STARTED listed |
| hub | `FIXTURE=hub tools/method_run.sh c2_more k0` | **FAIL** (1) G3b | "the bare hub is 0.250 m off where it was built on its wheel (tolerance 0.010 m)", owner UNRESOLVED, detected 0.2 s after it began; run completed |
| early | `FIXTURE=early tools/method_run.sh c2_more k0` | **INCOMPLETE** (2) | "c2_more ended with required work missing: work:c2.f1_landed_state, evaluated:G4"; G4 NOT REACHED |
| SE_TEST | `FIXTURE=se_test tools/method_run.sh c2_more k0` | **TEST** (3) | "script error raised in test code at res://scripts/dev/PlayTest.gd:12226"; kill 2.03 s after detection (the 2 s tie window), process gone 0.5 s |
| SE_GAME | `FIXTURE=se_game tools/method_run.sh c2_more k0` | **FAIL** (1) | "script error at res://scripts/puzzles/RampJump.gd:540 (RampJump.in_hut)", owner UNRESOLVED (the test caused it on purpose: the label says where, not who, as decided) |
| host | `python tools/method/host_fixture.py <dir>` | 3 / 3 named apart | NOT STARTED: c2_more / stopped in c2_more at until#41 / ended with required work missing |

Every run: `tasklist` showed no Godot before and none after; one game at a time.

## Departures, interpretations and cuts (each for the referee)

**Cuts: none.** FN_RECORD (cut 1) was not built: `FN_RECORD=1 tools/method_run.sh` prints
"unsupported in this build" and exits 3, as the agreed fallback says.

**Departures and interpretations (mine, marked):**
1. **Branch** from `e34af9c` with c1 + c2 files checked out from `04c3102` (the referee's departure).
2. **The swim's `until(…, 60)` gets 62 s** with no <= 46 s enclosing phase (M3 says until(t) gets
   t + 2 "only within a <= 46-s enclosing phase"). The ramp's own step is 60 s long; clean 18.9 s.
   Every other selected-path await is under a phase <= 46 s. Referee: accept, or split the swim.
3. **The reset wait** is `until(not failing, 6)` -> 8 s by the generic until rule, not the draft's
   separate 6 s. Clean max of that step was under 6 s.
4. **Stops:** the supervisor stops the game at once on NOT HEALTHY, STALLED and TEST; a script error
   first waits the 2 s tie window (so a co-occurring health cause can headline, M15); FAIL findings
   don't stop the run (later conditions keep being recorded).
5. **M6 "no backtrace"**: a SCRIPT ERROR with no raising frame in the log reads **TEST, owner
   UNRESOLVED** (the decisions say "owner UNRESOLVED" without a status; I chose the invalid-proof
   reading). Not exercised by a control.
6. **owner=GAME is never assigned automatically** (no mechanism to establish prerequisites was
   specified); every FAIL says owner=UNRESOLVED. TEST rows say owner=UNRESOLVED too, except plan /
   needs lint (owner TEST, C3's "demonstrated test causation").
7. **Pad loss (M16):** the method reads no logged-unplug receipt, so a pause after PAD -> KBM reads
   NOT HEALTHY, owner UNRESOLVED. T1 (a logged synthetic unplug -> TEST) is **not built**; c1's
   `RigInject` still has the T1 hook. Not in the §6 control list; reported.
8. **Input receipts:** c1's `input_lost` event -> TEST (kept). Short unobserved pulses: c1's existing
   rule (a tap released within 2 frames is not judged) stands; no new UNOBSERVED line.
9. **Check IDs** are slugs of each check's literal words with format fields as "x" (e.g.
   `ramp/flat_out_the_van_makes_it_x_km_h_at_the_lip`), matched by regex from the source; a logged
   check outside the manifest is TEST (malformed event).
10. **G3/G3b on the played route** are evaluated (the van parks frozen once) but not mandatory;
    mandatory coverage is `c2_more`'s (C1).
11. **Lane at the lip** (my measure: the van's x in the ramp's frame when it crosses the lip) reads
    about +0.9 m right of the target lane on both profiles (k0 -0.5 -> +0.49; k4 +0.5 -> +1.37). The
    game's own lip line is also parsed. Reported as actuals (M12), not corrected.
12. **Picture on a finding:** c2's existing `_snap` (observer camera, fire-and-forget, not awaited,
    so a failed capture can't delay the stop). It was not given its own deadline.

## Game hashes (non-`scripts/dev` tracked files under `FindingNaresh/`, 462 files)

Before: `702d0f8738e855e21a842e2f62362b93bb29c752`. After: `702d0f8738e855e21a842e2f62362b93bb29c752` (**unchanged**); `git diff e34af9c HEAD -- FindingNaresh` touches only `scripts/dev/`. The T4 rename was reverted with
`git checkout --` right after its run and never committed.

## Commands

```
bash tools/method_run.sh ramp          # the user's command: ramp,c2_more, next profile k0..k4 (logged)
bash tools/method_run.sh ramp k3       # a chosen profile
bash tools/method_run.sh c2_more       # the short declared stretches only (~45 s + startup)
FIXTURE=n5 bash tools/method_run.sh ramp k2         # one control (also hub / early / se_test / se_game on c2_more)
python tools/method/method_verdict.py appdata/method/runs/<id>   # re-reduce an archive offline
python tools/method/host_fixture.py appdata/method/host_fixture  # the host control, no game
```
T4 by hand: `sed -i 's/_swim_to/_swim_target/g' FindingNaresh/scripts/player/PlayerRig.gd`, then
`bash tools/method_run.sh c2_more k0`, then `git checkout -- FindingNaresh/scripts/player/PlayerRig.gd`.
Cost: ramp,c2_more 161 s measured (plus ~6 s compile when already imported); c2_more alone ~45 s
plus startup; a stall ends <= the phase deadline + ~1 s.

## What the referee must decide
1. Departures 2-3 (the 62 s swim step; the 8 s reset wait), 5 (no-backtrace reading), 6 (no automatic
   GAME owner), 7 (T1 logged-unplug path not built).
2. The `next_k` counter in `appdata/method/next_k.txt` is at 0 (q1-q3 used explicit profiles): the
   referee's ten-run schedule should pass k0..k4 explicitly.
3. Whether the requalification's clean runs should include one at k1 / k3 (not run by me).
