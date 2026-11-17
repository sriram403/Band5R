# Speed research: the referee's hand-off (written 2026-11-14 13:40, stopped at the user's request)

**Why stopped:** the user is playing GTA 5 on this PC (CPU 96 %) and runs another thread: timings were skewed and the rate
limit at risk. **Before anything else in the new thread: check GTA is closed and the CPU is near idle**
(`Get-CimInstance Win32_Processor | % LoadPercentage`; `Get-Process GTA5*`). The scored replay must run with nothing heavy beside it.

## Start the new thread with this prompt (the user pastes it)

> You are the REFEREE of the speed research for "Finding Naresh" (Godot 4). Work in D:\mine\Agentics\T3_Code_Works\MPG (branch
> main). Read, in order: (1) MPG\CLAUDE.md; (2) **MPG\notes\SPEED_REFEREE_HANDOFF.md (this file: state + next steps)**;
> (3) MPG\notes\speed_research\scoreboard.md (rulings R1-R6, every trial's score); (4) MPG\notes\ROUGH_NOTES.md, the last 12
> entries of "Assumed -> reality -> fix"; (5) the referee's private files D:\mine\Agentics\T3_Code_Works\MPG_referee\speed_secret.md
> and game_meter.py (never give them to a child). Load the skills (full paths): D:\mine\Agentics\Skills\skills\two-model-research\SKILL.md
> (v2), testing-and-verification, project-memory, first-principles-solving, game-dev (same folder); library rules
> D:\mine\Agentics\Skills\AGENTS.md. Then follow "Next steps" in the hand-off, one at a time, and report to the user short and plain,
> A / B with your pick.

## LIVE (2026-11-14 14:55, new referee thread)
Steps 1-5 done. Builder resume 2 + fix round (F1-F11) done (builder total ~19 game min); audits + re-audits: both GO WITH
CONDITIONS (all in `REPLAY_TASK.md` rulings 1-8); D5: the user chose **A** (run, report the overrun; hard stop 150).
**Step 6:** part 1 2026-11-14 14:55-15:11 (cut by the rate limit; WALL 13.3); **RUNNING again since 2026-11-17 17:40
(child "Speed REPLAY runner (resume 1)"; meter session 2: ADD 13.3):** the replay runner (T3 child "Speed REPLAY runner") in `MPG_speed_replay` (`f9418c5`, sealed:
one commit, own repo); meter `MPG_referee/meter_replay.log` (background meter restarts every 2 h: ADD the sessions' WALL);
watch = scratchpad `watch_replay.sh` (starts/ends, verdicts, walk results, every 10 game min, load).
**ETA (the user wants it in every update):** replay done ~21:00 (11-17), scoring + final + signatures ~22:30.
Next: step 7 (score: S1-S7 + X1, X2 vs `MPG_referee/speed_secret.md`; plants PROVED; minutes vs 75 / 225).

## Where it stands (one paragraph)
Stages 1-2 done (top 4 signed). Stage 3: **T1 + T2 (fast tests) QUALIFIED** after 3 rounds and 3 GPT audits: the final table
(fast PASS counts for net, heat, marks-if-its-looks-prelude-made-its-round; looks fast = exploratory, 1x for an accepted PASS;
jug, places, spring, free_coolant, the recorded walk = 1x; suite ~11.8 min serial vs 18.7). GPT's last conditions (input sealing,
split order, picture freshness) are pieces of the v2 build. **T3 + T4 v2** (GPT's specs after a Claude audit: 20 / 24 agreed) are
**mostly built** by the Claude builder in `MPG_speed_t34` (stopped mid-way, see below). **Insurance plants X1, X2** written and
proved (private). The replay (the scored benchmark) has **not started**.

## The copies (all on D:, all local; nothing merged or pushed for the research)
| Copy | Branch / last commit | What |
|---|---|---|
| `MPG` | `main` (local commits ahead of origin: notes, the hand-off gate hook, ledger) | the referee's notes; never a trial |
| `MPG_speed_base` | `speed-base` `b7c6e8d` | the benchmark start (5f3e3e3 + h1 tools) |
| `MPG_speed_t1` | `speed-t1` `709028b` | T1 + T2 + fix round + qualification round 2 (report `notes/speed_research/trial_T1.md`) |
| `MPG_speed_t34` | `speed-t34` `ec8dbcf` | v2 builder (speed-t1 merged at `4a74146`; **needs `git merge speed-t1` again for round 2's tools**) |
| `MPG_speed_ref` | `speed-ref` (= speed-t1 `5f468c2`, working tree clean) | the referee's private copy (insurance plants proved there, nothing committed) |
| `MPG_referee` | (no git) | secret list, insurance plants (`Ghat_X1X2_planted.gd`, `xproof/`), meters and their logs |

## Minutes so far (meter, wall clock R2; all qualification minutes R3, NOT the score)
T1 all rounds **56.1** (pilots 7.4 before that) · builder **~14 of 20** (meter 13.1 + the run killed at the stop) · referee's
insurance-plant proofs ~4 · **the score (replay) 0**. Thread time ~4 h (11-10 22:10-23:00, 11-11 10:40-12:35, 11-14 12:58-13:40).

## Decisions on record
User: R5 = **A** (a joined take where every join passes the 3-layer gate counts as the clean walk); skill edit = A (done,
two-model-research v2); full plan = A. **Pending with the user: D2-D4** (batch causality, two resumes, hidden-state inventory):
built as the referee's pick **A/A/A**, each a removable piece. D5: stop and report if the replay's projection passes 75.

## The builder's findings that change the replay plan (from its commits; its report misses 2 sections)
1. **No save point on the probe walk can pass the resume gate:** the parked van is frozen but keeps a stale stored speed
   (0.148 m/s), so every parked boundary is refused; layer 3 also showed a lost nav swing and players 5.5-15 cm off after a resume.
   If that holds for the ghat walk, **joined takes (R5) and resume-from-failure can't be used: every walk attempt starts fresh**
   (costs game minutes). It is a game/save-system fact the replay may face, not a tool bug.
2. **Recording runs at 34 % of real-time speed** (a 26 s walk took 84 s) -> the ~6-7 min ghat walk may cost ~20 wall game min,
   not GPT's 11. **Measured with GTA running: re-measure with GTA closed** before planning.
3. Its own gate bug found and fixed (velocity / pose comparisons were silently skipped); offline controls 83 / 83 (T4), 49 / 49 (T3).
4. Lane sentinel: misroutes refused both ways, targeted stop works; the first "SENTINEL FAIL" was a comparison bug (CR), fixed;
   the rerun (R4) was running when stopped.

## Next steps (in order; one Claude child at a time; GPT may run beside it)
1. **Preconditions:** GTA closed, CPU idle; `tasklist` shows no Godot. Restart the meters only for copies about to run games.
2. **Resume the builder** (Claude, `trial_T34_v2_build_task.md`; add a RESUME 2 section: last `ec8dbcf`, ~6 game min left of 20;
   merge speed-t1 again; rerun R4 sentinel; **re-measure recording speed and two-lane throughput with GTA closed**; write the
   missing report sections ("Resume 2026-11-14": the gate refusal facts; "Live gate session G"); finish `REPLAY_USAGE.md`
   (commands only, **no results, no game symptoms**)).
3. **Audit the build** (the hook requires it before anything builds on it): the Claude auditor checks results vs. claims;
   GPT checks its v2 spec was built as written. Disputes -> the user.
4. **Re-plan the replay budget** from measured numbers (fresh takes if no point passes the gate; recording speed; 1x paths).
   If the projection is > 75: tell the user before starting (A: run it anyway and report the overrun / B: stop the research
   here and write up what was learned), per D5.
5. **Build the replay copy** (`MPG_speed_replay`, on D:): ONE orphan commit (no parent) = speed-base's game + the tools from
   speed-t34 (with speed-t1 merged) + the insurance plants (`MPG_referee/Ghat_X1X2_planted.gd` over `scripts/world/Ghat.gd`;
   check it equals speed-base's Ghat.gd + the two changes first) + **no trial reports, no scoreboard** (they carry game symptoms:
   T1's report and the scoreboard mention the fast "no round" runs) + `REPLAY_USAGE.md`. Copy `tools/godot`. Meter on it.
6. **The replay** (Claude runner, blind; its read list: SPEED_RESEARCH.md's benchmark part, REPLAY_USAGE.md, design #6 in the copy,
   TESTING_METHOD.md; NOT the scoreboard or any trial file). Watch it with a verdict Monitor; caps per D5 and ~2 h wall.
7. **Score** (referee): 7 holes (S1-S7) + X1, X2 found (named + a check that fails on it and passes fixed), every plant still
   PROVED (21 rows R4 + one per hole), wall game minutes vs 75 / the baseline 225. Then the final run, both auditors sign,
   `notes/speed_research/FINAL.md`, a new `notes/TESTING_METHOD.md` version, the skill two-model-research example 2 result
   (ask the user first: library edit), and the report to the user (A / B on adopting the method), with time spent.

## After the replay (the user chose A, 2026-11-17 ~19:05)
**Fix resume, then measure the saving** (the biggest win left: fresh-only walks cost ~40 game min in the replay vs ~15 with
resume). The user's idea: the parked van's stale stored speed (0.148 m/s, a frozen body, no motion) is ignored / zeroed;
save what the restore loses: the engine running, the nav swung aside, the creature's hearing memory; line up the 1 s settle
(the 1.6 C cooling offset); layer-2 tolerance for far, sleeping items. Claude designs + builds it (its idea), GPT audits; then
a gate session proves a SAME resume on the real ghat walk, and the saving is measured on a failed-step repair.

## Rules learned in this research (keep them)
- **A rule only in a note is forgotten:** the hand-off gate hook (`tools/hooks/handoff_gate.py`) blocks a build hand-off
  without the other model's audit (`AUDITED:` line). Every spec / result is audited by the other model before it counts.
- **Monitors report each run's VERDICT**, not only START / END; check a run's result, never just its length.
- **One Claude child at a time** (two rate-limit cuts, both with two Claude children; one alone ran fine); GPT beside it is fine.
- **Every child commits after each finished sub-step**; a cut then costs almost nothing. Each resumed child gets a RESUME section.
- **Game symptoms never go into files a later blind child can read** (T1 wrote one; the replay copy carries tools only).
- **No timing measurement while the PC is loaded** (GTA 5 at 96 % CPU): mark such numbers and re-measure.
