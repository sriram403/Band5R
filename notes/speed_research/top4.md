# The agreed top 4 (Stage 2, 2 rounds; referee's summary of audit_r2_claude.md + audit_r2_gpt.md)

Both auditors sign the same 4 trial groups and owners; no single idea reaches 75 min, so they are
trialled as one plan, with the speed probe first (it decides whether 75 is reachable at all).

| Trial | Owner | What | Rows it cuts | 1x / ~2x (I think, both) |
|---|---|---|---|---|
| **T1 qualified speed** | Claude runs | Test code reads a game clock (game code untouched); uncapped `--fixed-fps 60` (same physics step); classify every clock read; a deadline-negative control; visual checks stay at 1x until qualified | all | (enables the 2x column) |
| **T2 proof runs** | Claude runs | One import per unchanged batch; early stop only once every expected FAIL is fully on record; process checked gone | D proofs | 12 / 7 |
| **T3 discovery + selection** | GPT spec, Claude builds | One first broad suite (fast if T1 qualifies), a conservative change -> checks map for the fixes, one final unshortened suite; receipts | A suites, C fixes | 55 / 38 |
| **T4 walk + resume + video** | GPT spec, Claude builds | Note-and-repair as declared independent sections (no state patched mid-walk), h1 resume for repairs with a state-equality gate, the video | B walk, E video, F | 32 / 23 |
| **Total** | | | | **~99 / ~68** (needs >= ~1.7x) |

**Order of the first experiments:** (1) offline, 0 game min: clock-read classification, the change ->
checks map, the saved-field list; (2) **the speed probe, ~2 game min: does an uncapped fixed-fps run
reach >= 1.7x on this PC?** If not, stop and report: the plan can't reach 75; (3) compile timing (twice);
(4) the 1x-vs-fast differential on one scenario + its plants; (5) the resume equality gate.

**Pilots are counted separately** from the benchmark score (both asked).

**Resume equality check** (both, merged): layer 1 offline list of saved vs live fields; layer 2 a snapshot
right after restore must equal the saved point; layer 3 a snapshot 3 game s into the step vs the
uninterrupted run that wrote the point, tolerance from two resumes of the same point. A step resumed
from a point that fails it does not count as passed. ~1 game min per boundary.

**Video: the user chose A (2026-11-10): a joined take is fine for the final video**, every join's time listed
with it (GPT had recommended B, one fresh take; Claude left it open).
