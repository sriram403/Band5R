# Stage 3: T1 fix round (GPT's 3 blockers + the hearing gap). Claude auditor. Referee, 2026-11-11.
AUDITED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_T1_gpt.md

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`: `scoreboard.md`, `trial_T1_task.md` (the rules, still in
  force), **`audit_T1_gpt.md`** (GPT's audit of your T1: the conditions), `audit_specs_claude.md` §0 fact 5 (the hearing
  gap, found by a Claude auditor), this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside `D:\mine\Agentics\T3_Code_Works\MPG_speed_t1` (branch `speed-t1`, your T1 at `5f468c2`)

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref`, `MPG_speed_t34` or any other `MPG_*` folder; other branches or commits; testing-and-verification §3b.

## Rules (as T1, plus the audit fixes)
Work only in `MPG_speed_t1`; commit locally after every finished sub-step (WIP commits say what's left); no merge, no
push; nothing on C:; game code untouched (incl. `core/Plant.gd`). **Budget: 12 wall game min left of T1's 45 (the meter
decides; stop at 15).** Before each run write its cost; watch every run while it runs. **Game bugs: in your reply only,
never in any file** (your T1 report described one: don't repeat that; a symptom in a file is a hint to the blind replay).

## Do, in order (each fix proved: the planted case FAILS / is refused, the clean case passes)
1. **Blocker 1, a lane can vanish:** every requested part must return its own verdict for this invocation (no shared
   `.last_*` pointers); a refused / missing / truncated part = not PASS. Controls: first part missing, second part missing,
   both refused (offline or with a launch that is refused at once: ~0 game min).
2. **Blocker 2, a late step that closes between polls:** judge every CLOSED step against its budget (game and wall)
   before dropping it; drain all events at the end. Controls: a step just over budget that closes before the next poll
   -> STALLED, at fast AND 1x; an on-time one passes (short fixture runs: ~2-3 game min).
3. **Blocker 3, exact plant identity:** a plant is PROVED only by its own exact check id(s) in its own run (invocation id,
   exact fixture set), with all expected FAILs on record before an early stop; batched plants each need their own check.
   Controls (offline from the archived run folders where possible): one expected FAIL missing, a similarly named wrong
   check, the wrong run's evidence, a batch member whose own check is absent -> NOT PROVED.
4. **The hearing gap:** prove or bound it. Cheapest honest option of: (a) a test-side differential where the same item
   sounds near the creature give the same reaction fast and 1x (incl. two sounds within 1.5 s), or (b) declare
   ghat_jug and ghat_places 1x-only in `SPEED=fast`. Say which and why, with the minutes.
5. If minutes remain: lean_close (an isolated pair, repeated, to bound it) and ghat_places' missing negative control
   (if no plant exists and Plant.gd is off-limits: say so; keep places' fast status only on the clean differential).

## Write
Append a "Fix round" section to `MPG_speed_t1\notes\speed_research\trial_T1.md` (each blocker: change, controls, result,
minutes). **Reply:** 8 lines (each blocker fixed + proved or not, hearing decision, minutes used, game bugs seen).
