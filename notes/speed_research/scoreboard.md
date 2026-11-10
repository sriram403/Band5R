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

## Stages
| Stage | State |
|---|---|
| 1 ideas | done: `ideas_claude.md`, `ideas_gpt.md` (no game, no code) |
| 2 round 1 audits | GPT done (`audit_r1_gpt.md`, R1); Claude running |
