# Speed research: scoreboard and rulings (the referee's; only the referee changes it)

Brief: `notes/SPEED_RESEARCH.md`. Score = summed game-running minutes (meter), target <= 75 of 225.

## Rulings
- **R1 (2026-11-10, Stage 2 round 1):** the GPT auditor disclosed it read `notes/TODO.md` and
  `notes/MASTER_PROMPT.md` by mistake before the exclusions (my stage-2 task said "same reading as
  stage 1" without repeating the DO-NOT-READ list; MASTER_PROMPT was never on it). TODO's #6 entry names the
  day-2 fixes, so the 7 holes may be known to GPT. Ruling: (a) the 7 holes stay in the benchmark as a
  **known set** (a method must still find all 7, but it no longer proves blindness); (b) the referee
  adds a **new secret set**: bugs planted by the referee in the benchmark copy, written only in
  `D:\mine\Agentics\T3_Code_Works\MPG_referee\` (never in a note or commit the models can read), each
  seen to break the game for real before it counts; the final exam scores those blind; (c) from now on
  every child works only from a **sealed copy** at `5f3e3e3` (`MPG_speed_*`) plus the files the
  referee copies into `notes/speed_research/sealed/`; reading `MPG\notes` outside `speed_research/` is
  out. GPT's round-1 audit is kept and read as possibly contaminated.

- **R1b (2026-11-10, after the user asked "can't a new thread reset it?"):** yes: every round is a
  new child thread with no memory, so the leak lives only in the dead r1 GPT thread. What carries a leak
  on is what that thread WROTE: the referee grepped all four written files (ideas x2, audit_r1 x2) for
  every hole's words: clean (only generic hits). Ruling: **the 7 holes count as blind again** for every
  later thread; GPT r1's choice of trials may have been nudged, so the referee still adds **2-3 extra
  secret plants** as insurance (scored blind at the end). Each later task file repeats the full
  read-only / do-not-read lists and is read first.

- **R2 (2026-11-10, after pilot P1):** the score was "summed game minutes of every Godot process", so two
  games at once could not help. But the brief's core problem is the user's real waiting time
  (TESTING_METHOD's core: wall-clock time to a proven sheet). Ruling: **primary score = wall-clock minutes
  during which any game process of the trial copy runs** (the meter's union); summed process minutes are
  still reported and may not exceed the baseline's share by more than 10%. Target unchanged: <= 75
  wall-clock game minutes. Two games at once is back in play (the referee's pick; the user may overrule).
- **Pilot P1 (Claude, 2.0 pilot min):** uncapped fixed-fps 60 = **1.24x** (open road ~1.4x, the encounter
  0.98x: render-bound, 12-17 ms a frame); < 1.7x -> no-go for the 2x column as built. 19 wall-clock
  deadlines in test code (all loosen when fast: false-PASS risk). Import 9.9 s, not ~40 s (T2's import
  gate likely moot). Next: P1b, headless / tiny window speed (~2 min).
- **Pilot P1b (Claude, ~2.4 pilot min):** **headless + fast = 4.96x** (334 game s in 67 s), 33 / 33 checks,
  same result lines as 1x; tiny window 1.23x (CPU-side draw prep per frame, not pixels). Headless-capable:
  heat, looks, places, jug, marks (73% of a suite); ghat_net reads pixels; ghat_spring + `free_coolant`
  use game-code wall clocks (stay 1x). Plan with headless ~4.5x: **~61-64 min**. Preconditions: test
  deadlines on game time (5x looser otherwise); screenshots kept. Referee's misread logged: the meter's
  1.3 min looked "slower", it covered far more game time. Next: P1c, drawing off except at shots (~1 min).
- **Pilot P1c (Claude, ~2.9 pilot min):** `--nodraw` (test-only switch): `RenderingServer.render_loop_enabled`
  off, on for the one frame a shot / `grab_p1` needs. Shots correct (ghat_net vs 1x: 0.65-2.5 / 255;
  its 3 pixel checks within 0.002). ghat_net at **5.5x** once off. Works only when switched mid-scenario
  after a drawn frame (set in `_ready` it reads false and keeps drawing: prove it by frames drawn, never by
  reading the setting). ghat_heat truly off: not yet measured (~4.5-5x guessed). **Pilots total ~7.4 game min.**

- **R3 (2026-11-10, Stage 3 start):** building and qualifying a trial's tools (T1's differential, the T3/T4
  builder's proofs of its own tools) is a one-time cost, like writing code: **qualification minutes**,
  metered and reported apart from the benchmark score (as the pilots were). The score is the replay from
  `speed-base` with the finished tools. The meter now logs both (`WALL` = R2's union, `proc` = summed).
  Caps: T1 <= 45 wall game min (stop at 60); each GPT spec's build + proof <= 15.

- **R4 (2026-11-10, GPT's T3 spec asked):** the plant inventory at `speed-base` is **21 rows** (GPT is right;
  the brief's 20 counted day 2's removal of `no_stall_drag`). The replay keeps all 21; a row leaves only if the
  replay removes the thing it plants, with the reason written. Final = 21 (or 20 with that reason) + one per
  hole found + the referee's exam rows. Shortcut flags (`one_flat`, `one_corner`) are not bugs.
- **R5 (2026-11-10, WITHDRAWN 2026-11-11: DISPUTED, with the user), a disagreement between GPT's T4 spec and `top4.md`):** GPT's spec wants a separate
  uninterrupted fresh walk even when every join of a take passed the 3-layer gate. `top4.md` (signed by both)
  says a step resumed from a point that FAILS the gate doesn't count, so one that passes it does. Ruling, by the
  signed text and the user's choice A (joined takes are fine): **a joined take where every join is SAME on all 3
  layers, under the recording profile, counts as both the clean walk and the video.**
  **Withdrawn (2026-11-11):** the compliance audit showed the user's A covered the *video* only; the referee
  stretched it to "no unbroken clean walk needed". The point is DISPUTED (GPT: an unbroken fresh walk too,
  ~+10 game min; Claude: not yet audited) and goes to the user as A / B.
  **The user decided (2026-11-11): A.** A joined take where every join passes the 3-layer gate (SAME), under the
  recording profile, counts as the clean walk and the video. A join without SAME doesn't: then a fresh take. A join without SAME
  doesn't; then a fresh take is needed. GPT's stricter rule is noted as its reservation for the signatures.

- **Referee watch notes, T1 resumed (2026-11-11), to check at scoring:** fast suite of 6 PASS in 3.4 min (run 7);
  overrun control STALLED on game time (fast); plants caught fast: heat_always (H1), lean_close (window glass),
  one_layer_net (picture check), no_breath_lock. **Open: run `marks_pile,marks_unsaved` fast: `ghat_looks` FAILED
  ("0 stops", no lean, no sniff) though no plant touches it; at 1x (proof 2026-11-09) looks passed in that group, so
  `marks_pile` was never reached fast. A 1x-vs-fast difference (or the second game alongside): T1 must explain it
  before "qualified".** Batched plants (lean_close+fast_turn; leave_sees+no_breath_lock+round_skip): each needs its
  own check on record (GPT's attribution point). Two lanes ran at once in one copy (separate progress / shot dirs).

- **T1 + T2 scored (2026-11-11, referee; GPT's audit of it pending, so not final):** QUALIFIED, `SPEED=fast` for
  heat, looks, net, places, jug, marks (fast + nodraw, 4.6-4.9x); spring, the `free_coolant` proof and the recorded walk
  stay 1x. Clean 119 / 119 checks same verdict fast vs 1x, pictures matched. **Whole 7-scenario suite: 4.4 wall min,
  PASS, vs 18.7 at 1x** (spring 1x beside the fast lane). Plants: 8 / 9 same exact check id fast and 1x, every 1x rerun
  on this source (GPT's point 1); **`lean_close` is marginal** (0.13 m fast caught, 0.18 m at 1x not caught, limit 0.15,
  1x spread 0.05 m): its proof is a coin toss at either speed (a finding for the replay: firm up the plant or the
  limit). Deadline control STALLED by name fast AND 1x (GPT's point 2). Early stop: ~30 s fast, 2-4 min 1x saved.
  Import 6-8 s: skipping it doesn't matter (T2's import idea dropped). Deadlines: `el_ms` = the larger of game and
  wall time (never looser on either clock). One fast ghat_looks run (1 of 4) FAILed with no round, not reproduced (0 of 3
  at 1x): unexplained, fails loudly (never a false PASS). Engine error `self_list.h:46` x7-8 per scenario switch, same
  count 1x and fast. **Meter: WALL 32.8 min, proc 55.0** (two lanes), inside 45. Rule slip: a game symptom written into
  the report file (the task said reply only): the replay copy will carry tools only, no trial reports.

- **R1b insurance plants (2026-11-11, referee):** 2 written and **seen to break the game for real** (planted vs clean,
  pictures and logs), kept only in `MPG_referee` (outside every child's reach); the current checks pass on both (blind).
  They go into the replay copy's start in one orphan commit. Scored at the end with the 7 holes.

- **GPT's audit of T1 (2026-11-11, `audit_T1_gpt.md`): ACCEPT WITH CONDITIONS.** Verified: 119 clean verdicts match, the
  suite ~4.4 vs 18.7 min, 8 / 9 plants. **Three blocking false-PASS paths (code-read, real):** (1) a refused / missing lane
  (e.g. spring refused by the guard) leaves the combined command PASS on the other lane alone; (2) a step that overruns
  and CLOSES between watcher polls is never judged against its budget (fast makes it likelier); (3) plant proofs match
  FAIL substrings and pick run folders by glob: identity printed, not enforced. Also: lean_close unresolved, ghat_places
  has no plant, lane isolation and split order unproven, nodraw re-arm interleaving untested. **`SPEED=fast` is not
  used in an accepted replay until (1)-(3) pass with their own planted controls.** Who fixes: decided after the Claude
  audit of the specs (blockers 1 and 3 overlap T3's receipts / attribution).

- **T1 fix round scored (2026-11-11, referee; GPT re-check pending):** blockers (1) missing lane, (2) late-closing step,
  (3) exact plant identity: **fixed and proved** (31 offline controls `t1fix_controls.py`, 4 cases where the old rule said a
  wrong PROVED; live: both lanes refused -> TEST, fast PASS + spring refused -> TEST (was 0); late close STALLED fast, 1x and
  with a delayed watcher; on time PASS both). **Hearing gap: ghat_jug + ghat_places run 1x under `SPEED=fast`** (game hearing
  on the wall clock; the suite ~7.2 wall min, an estimate, vs 18.7). lean_close alone: fast 3 / 3 caught at 0.13 m; 1x a coin
  toss (0.14 caught, 0.18 / 0.19 missed): fast reads closer every time: a steady speed difference, unexplained (fast is the
  stricter side here, but not proved equal). Final clean fast run vs 1x: 87 / 87 verdicts; **3 values outside T1's own
  tolerances, unexplained** (fuel 1.06 L, engine ticks +17.7 %, sniffs 1 vs 2). Open: lane isolation, split order, batch
  causality (D2). **Meter: T1 WALL 43.7 of 45 min, proc 70.0.**

- **GPT's re-check of the fix round (`audit_T1fix_gpt.md`):** condition 1 CLOSED; 2 and 3 partly (the late-close and
  exact-identity repairs CLOSED; the original open-overrun not rerun on the final source; batch causality not shown).
  Fast counts in an accepted replay for **net** now, **marks** conditionally (its looks prelude), **heat / looks only as
  exploratory** until the 3 values (fuel, engine ticks, sniffs) and lean_close's fast/1x gap are bounded; jug / places 1x.
- **R6 (2026-11-11, referee's pick, told to the user):** one more capped T1 qualification round (`trial_T1_qual2_task.md`,
  <= 15 wall game min, apart from the score) to close what's left, because without it heat / looks / marks' final PASS runs
  at 1x (~+12 game min on the replay's final suite: likely over 75). It runs beside the builder: two Claude children at
  once, also the test the compliance audit asked for (F04: is the rate limit about parallel children at all?).

- **T1 round 2 scored (2026-11-14, referee; GPT check pending):** Q1 open overrun STALLED fast + 1x on the final source;
  the 6 batched plants each FAIL their own check alone (marks_pile needs its looks prelude to make its round: `passed_ids`
  prerequisite); fuel inside 1x spread (tolerance +-1.4 L, 3 runs a side); engine ticks were a wrong comparison (counter never
  reset); sniffs 1 / 2 are the game's own unseeded random (~20 % at any speed); **lean_close / the glass check: a real speed
  shift (fast 0.01-0.07 m closer every time): stays 1x.** No-round in 2 / 14 fast looks runs, 0 / 5 at 1x, unexplained:
  such runs rerun at 1x. **Final table: fast PASS accepted for net, heat, marks (if its looks prelude made its round);
  looks exploratory fast, 1x for an accepted PASS; jug, places, spring, free_coolant, the recorded walk 1x.** Suite serial
  ~11.8 vs 18.7 min (estimate). Meter: T1 total 56.1 (round 2 ~12.1 of 15). Open: a firmer lean_close plant (`core/Plant.gd`).

- **GPT's check of T1 round 2 (`audit_T1q2_gpt.md`): ACCEPT WITH CONDITIONS.** Its conditions 2 and 3 CLOSED (open overrun on the
  final source; solo attribution); 38 / 38 offline. The fast table is accepted for the replay with looks 1x and marks only with its
  same-run looks prelude PASS. Still open, all v2 pieces the builder is building: input sealing (exact source identity), split
  order equivalence, picture freshness. **T1 counts as qualified for the replay once the builder's v2 closes those three.**

- **Measurement caveat (2026-11-14 ~13:30, referee):** the user is playing GTA 5 on this PC (CPU 96 %, GTA most of it) and runs
  another thread. Every TIMING the builder measured since ~13:00 (recording at 34 % of real-time speed, two-lane throughput) is
  "measured under load": not usable for the replay budget until re-measured with GTA closed. Correctness results (planted
  failure refused, clean passes) stand. **The scored replay runs with GTA closed** (the baseline day had no such load).

- **T3 + T4 v2 builder, RESUME 2 scored (2026-11-14 14:00-14:07, referee; PC idle, CPU 38-52 %):** R4 lane sentinel PASS (misroutes
  refused both ways, quit A leaves B alive); recording re-measured: **52 % of real time overall, 62-70 % in the walk, the same
  beside a second game** (the GTA figures 34-39 % were a third too slow); two lanes 1.5x on that pair. Meter this resume: WALL 2.9
  (builder total ~17 of 20). Offline T3 49 / 49, T4 83 / 83 (rerun by the Claude auditor).
- **Audits of the build (2026-11-14):** Claude (`audit_T34_claude.md`): **ACCEPT WITH 7 CONDITIONS** (~3 game min): 7 identity controls
  can't fail (they start from an already-refused point); step 0's `t1fix_controls.py` crashes in this copy; "sound PASS" unsaved;
  no frame marker on the real ghat walk, so a joined take can't be verified; the gate refuses partly for no-effect reasons (a frozen
  van's stale stored velocity, a 1 s cooling offset, float noise on far sleeping items); dropped key presses in lane b (2 / 4 walks)
  unguarded. GPT (`audit_T34_gpt.md`): **REJECT as a ready <= 75 replay**: marks loses its looks prelude in the default split;
  picture freshness not enforced; solo proof groups incomplete; test-only flags unsealed; **projection ~105-118 game min serial**
  (no demonstrated <= 75 plan). Both: fresh takes only; the useful guards (identity, refusal, cancel, recording) stand.
- **R7 (2026-11-14, referee):** (a) the replay is **fresh takes only**: the gate stays on and refuses; its strictness classes
  (Claude C5) are a finding for after the research, not fixed now (0 game min); so the clean walk + video = one unbroken fresh take
  (D1's joined take stays allowed but unusable on this walk). (b) Walks and recordings run with no second game beside them until
  the dropped-tap bench (F5) says otherwise. (c) One fix round (`trial_T34_fix_build_task.md`) closes the union of both audits'
  conditions; its game cap **5 min** (builder total cap 25), qualification minutes apart from the score. (d) D5: the projection is
  over 75, so the replay waits for the user's A / B (asked 2026-11-14).
  **The user decided (2026-11-14 ~14:25): A** (run the replay anyway and report the overrun against 75 and the baseline 225).

## Next (Stage 3 proper)
**2026-11-14 13:40: stopped at the user's request; the referee's next steps are in `MPG
otes\SPEED_REFEREE_HANDOFF.md`.**

1. T1 build (Claude, `MPG_speed_t1`): test deadlines on game time (P1's 19 reads) + `--nodraw` after each
   scenario's setup, proved per scenario by frames drawn ~= shots; the 1x-vs-fast differential on all 7
   + a plant each (the clean/plant verdicts must match 1x); ghat_spring / `free_coolant` stay 1x.
2. GPT writes the T3 + T4 specs (given top4.md + P1-P1c), a Claude builder builds them in their own copy.
3. The benchmark replay from `speed-base` with all four, metered (wall clock, R2), 7 holes + plants scored;
   then the extra 2-3 secret plants (R1b), the final run, signatures.

## Stages
| Stage | State |
|---|---|
| 1 ideas | done: `ideas_claude.md`, `ideas_gpt.md` (no game, no code) |
| 2 round 1 audits | done (`audit_r1_gpt.md` possibly contaminated, R1; `audit_r1_claude.md`). Claude: 4 trials (speed-up on the game clock, plants one compile + early stop, first+last full run, discovery walk + safe resume); ~99 min at 1x, ~68 at 2x: the speed probe decides |
| 2 round 2 | done: both sign the same top 4 (`top4.md`) |
| 3 pilots | done: P1 1.24x (no-go as built), P1b headless 4.96x, P1c draw-only-at-shots 5.5x (go, one fix) |
| 3 T1 + T2 build | done, QUALIFIED (6 fast, suite 4.4 vs 18.7 min); `speed-t1` `5f468c2`; GPT: ACCEPT WITH CONDITIONS (3 blockers) |
| 3 T3 + T4 specs | done (GPT): `trial_T3_spec.md` (discovery, selection map, receipts, **the replay playbook**: ~99 min 1x / ~62 fast, ~54 with two games), `trial_T4_spec.md` (sections, the 3-layer gate, the video); qualification 9/6 + 14 min. GPT on T1: old 1x plant verdicts need matching identities; the deadline control at 1x too |
| 3 T3 + T4 specs audit | waits for T1: the Claude auditor audits GPT's specs (`audit_specs_claude_task.md`), GPT answers, disputes to the user |
| 3 T3 + T4 build | v2 mostly built (`speed-t34` `ec8dbcf`, ~14 of 20 min): T4 core + 83 offline controls, T3 checker + 49 controls, REPLAY_USAGE draft; stopped 2026-11-14 (GTA load); resume per the hand-off |
