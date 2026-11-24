# Auto-qualify resume points: result (2026-11-17 / 11-24, branch `autoq` in `dev`, not merged)

**Nobody sets or qualifies a resume point by hand any more.** A failed walk qualifies its own point in new games;
the next default run resumes it (or REPAIRs it after a fix), or starts fresh and says why. Spec `autoq_spec.md` v2
(Claude Opus 5.5, high); spec audit `audit_autoq_gpt.md` (GPT-6.1 Sol, high: BUILD WITH CHANGES, all 8 taken).

## How it works (one table)
| When | What the tools do |
|---|---|
| A walk FAILS at step N (`tools/play_walk.sh`) | `autoq.py`: walks back N, N-1, ... to the nearest point that passes refusal + layer 1 with a clean +3 s sample; resumes it in up to 2 NEW games (child mode: no hook, no last_fail writes), each played to the end; SAME on every layer **plus the outcome layer** (same status, failed step, kind, check, ordered PASS / FAIL from k on) x2 -> QUALIFIED; else NOT QUALIFIED with the reason |
| The default rerun (no `--from` / `--fresh`) | `walkgate.default_start`: one decision for `--gate-check` and the walk: qualified + same walk -> resume; qualified + a later step or step k's actions changed -> REPAIR; anything else -> **fresh, reason printed** |
| A failure inside a resumed run | No games: its own qualified source point is the next start |
| Game / test code / tools / bin changed | The point is refused: the default goes fresh (an explicit `--from` still exits 5) |
| A new puzzle | `restore_check.py <walk>`: a diagnostic listing what a restore misses (GateObs + a generic "wide" observation of every scripted node), fixes as hypotheses |

## The proof on the ghat walk (build `a2e0d65`..`eda5c36`; GTA closed; CPU 26-38 %: Opera + T3 Code)
| # | Run | Game min | Result |
|---|---|---|---|
| 1 | Producer, fresh, planted test-side typo at step 15 (`cool enough`: `temp <= 10.4`, within 5 s), WIDE_OBS | 5.2 | FAILED at step 15 (297 s); autoq skipped point 14 (P2 holds the pot) -> **picked 13** |
| 2 | Must-fail: `AUTOQ_PLANT=hearing` (resume 1 restores without hearing) | 0.4 | **DIFFERENT** before any input (`Hearing._next_id 220 -> 6`); stopped after 1 game; **NOT QUALIFIED**; `--gate-check` default: START fresh + the reason |
| 3 | Clean qualification, resume 1 (`..._225112_24248`) | 1.3 | SAME, every layer + outcome (same FAIL at step 15, 59 s) |
| 3b | resume 2 (`..._225232_3852`) | **14.4** | the game's result never reached the client: **found a real bug** (see below); no receipt |
| 4 | Clean qualification again (`--again`): `..._230724_14148`, `..._230844_13532` | 2.6 | **SAME x2 -> QUALIFIED** point 13; default: RESUME from 13 |
| 5 | Restore check point 13, clean / `RC_PLANT=groups` (the puzzle's state not restored) | 1.0 | clean: GateObs SAME, wide 233 diffs on 137 nodes; plant: GateObs DIFFERENT (129), wide 344 (**115 new: Problem 57, Ghat 23**); the probes' DIFFERENT receipts did not disqualify 13 (control runs) |
| 6 | The fix: plain `tools/play_walk.sh ghat` (regenerates the walk) `..._231151_3420` | 2.4 | **RESUME (repair)** from 13, layer 3 ON (its window unchanged) and SAME, **DONE** in 118 s, receipt REPAIR |
| 7 | Offline: a game file edited | 0 | default: START fresh ("game hash ... != now ..."); explicit `--from`: REFUSED |
| 8 | Rename-race check, old code / fixed (11-24) | 1.0 | old: **3 of 3 answers lost**; fixed: 3 of 3 landed |
Offline controls: **autoq 51 / 51** (`autoq_controls.py`; each of the 7 new guards seen failing when switched off),
**rv1 149 / 149** (one case split: a valid DIFFERENT next to 2 SAMEs now disqualifies). Total **28.3 game min**
(meter `extras/referee/meter_autoq.log`; budget ~10: 14.4 went to the stuck game in 3b).

## The saving (one sample each)
| | Wall |
|---|---|
| Fix the step-15 typo with a fresh walk to DONE | ~6.4 min |
| With autoq: qualify (2 background games, automatic) + the REPAIR to DONE | ~2.6 + 2.4 = **~5.0 min the first time**, then **~2.4 min per further repair** from 13 |

## Found on the way (each fixed, each with its own check)
1. **My tool changed the identity it guards:** `import live` wrote `tools/__pycache__`, inside the `tools` hash; autoq's
   "files changed while qualifying" guard caught it before any game. Fix: `__pycache__/`, `*.pyc` ignored repo-wide.
2. **A walk's result lost to a failed rename (an old bug, h1 era):** on Windows the game's `rename(res.tmp -> res.json)`
   fails while the client is reading `res.json`; one try, no check -> the client waited (limit 3600 s). Fix: every
   rename in LiveControl retried until it lands (2 s cap, error if not); the client stops a walk whose end is printed
   but whose result doesn't come in 30 s (STALLED, exit 2: seen firing offline after 31 s). Check `race_bench.sh`.
3. My watch printed lines but never a missing line: 13 min of silence went unseen. Watches now say "SILENT 60 s".
4. The wide observation costs **~85-95 ms, ~7,000 fields, ~0.9 MB per point**; it is taken BEFORE the point (same
   tick), so the step's clocks never move; layer 3 stayed SAME in every resume of the WIDE producer.

## Limits (said plainly)
- On the ghat only points 1, 3, 4, 9, 12, 13 can be resumed; a failure at 15-20 walks back to 13 (held pot, engine on
  refused): the held-item and engine-on adapters are the next job.
- The clean wide check shows **233 real gaps GateObs doesn't watch** (sounds playing, per-node random generators,
  HUD timers, far-off creatures' parts). None changed this walk (layer 3 + outcome SAME twice); a new puzzle could
  trip on them: the report lists them all, nothing masked.
- `needs` now re-arms from the nearest EARLIER definition only: changed by code reading, no live case run for it.
- The restore check's "add group X to LIVE_GROUPS?" hypothesis is untested live (the ghat's group is listed already, so
  the planted run named the missed nodes without it).
- One producer, one point, one planted failure: not yet run on a second walk.
