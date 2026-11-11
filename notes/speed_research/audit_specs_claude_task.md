# Stage 3: the Claude auditor audits GPT's T3 + T4 specs (before anything is built). Referee, 2026-11-11.

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md` (the brief)
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md` (rulings R1-R5), `top4.md` (what
  both of you signed), `audit_r2_claude.md`, `audit_r2_gpt.md`, `trial_T3_spec.md`, `trial_T4_spec.md`, this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1\notes\speed_research\` (the pilots and `trial_T1.md`: what T1 built and measured)
- code inside `D:\mine\Agentics\T3_Code_Works\MPG_speed_base` (read-only), to check the specs' claims

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`,
`MPG_speed_t34` or any other `MPG_*` folder not named above; other branches or commits (no `git log --all`,
no `git show main:...`); the skill testing-and-verification §3b. Opened one by mistake: stop and say so.

## Your role
The Claude auditor, strict (evidence or "I think"). **No game runs, no code changes**: write one file.
The user asked: "did Claude audit GPT's spec, and do BOTH of you think it should be this strict?"
The user's way of working: question every requirement (who needs it, what does it catch?), delete what
isn't needed, simplify, then speed up. A check that never catches anything real is cost; a cut that lets a
hole through is worse. Both are failures.

## Do
For every strict piece of the two specs (receipts / content hashes, the change -> checks map + its lint and
mutation controls, the discovery launcher, lane isolation for two games, plant attribution, the section
graph, the 3-layer gate's inventory + adapters, watch-budget restore, the movie join validator, each
qualification control), one row:
**piece | the real miss it guards against (a concrete way we'd get a false PASS / missed hole / wasted run,
with evidence from the code or the pilots, or "I think") | cost (build hours, game min in qualification and
in the replay) | KEEP / SIMPLIFY (to what) / CUT | why.**
Then: anything the specs MISS that could let a hole through or blow the 75-min budget; whether GPT's budget
numbers (T3 9/6, T4 14, replay 99 / 62 / ~54) hold up against the pilots and T1's measurements; where the
specs contradict `top4.md` or the rulings. Try to break the plan: how could the replay pass while a hole
stays in the game?

## Write
`D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_specs_claude.md`: the table, the misses, the
budget check, a short "the leanest spec that still catches everything" list, and your overall verdict
(SIGN / SIGN WITH CHANGES / DON'T SIGN). **Reply:** 6 lines (pieces kept / simplified / cut, build hours
saved, the biggest gap, verdict).
