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

## Stages
| Stage | State |
|---|---|
| 1 ideas | done: `ideas_claude.md`, `ideas_gpt.md` (no game, no code) |
| 2 round 1 audits | done (`audit_r1_gpt.md` possibly contaminated, R1; `audit_r1_claude.md`). Claude: 4 trials (speed-up on the game clock, plants one compile + early stop, first+last full run, discovery walk + safe resume); ~99 min at 1x, ~68 at 2x: the speed probe decides |
| 2 round 2 | running (both) |
