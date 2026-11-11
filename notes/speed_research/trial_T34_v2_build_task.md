# Stage 3: the Claude builder builds the agreed v2 specs (T4 then T3). Written by the referee, 2026-11-11.
AUDITED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\audit_specs_claude.md
ANSWERED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\answer_specs_gpt.md

## READ THIS FILE FIRST. Then read ONLY these
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md`; `D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\`:
  `scoreboard.md`, `top4.md`, **`trial_T4_spec_v2.md`, `trial_T3_spec_v2.md` (what you build)**, `audit_specs_claude.md`,
  `answer_specs_gpt.md` (why v2 is what it is), `audit_T1_gpt.md`, this file
- `D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md`
- anything inside your copy `D:\mine\Agentics\T3_Code_Works\MPG_speed_t34` (branch `speed-t34`) and, after you merge it,
  the T1 tools (branch `speed-t1`, its `notes\speed_research\trial_T1.md` incl. the "Fix round")

## DO NOT READ
Anything else under `D:\mine\Agentics\T3_Code_Works\MPG\notes`; `MPG_dev`, `MPG_referee`, `MPG_base`, `MPG_speed_base`,
`MPG_speed_ref` or any other `MPG_*` folder not named above; branches or commits other than `speed-t34`, `speed-base`,
`speed-t1`; the skill testing-and-verification §3b. Opened one by mistake: stop and say so.

## The decisions v2 left open (build these)
- **D1, clean walk: the user chose** that a joined take where every join is SAME on all 3 gate layers (recording profile)
  counts as the clean walk and the video. (In `answer_specs_gpt.md` this is option **B**.) No separate unbroken walk.
- **D2 batch causality, D3 two resumes, D4 hidden-state inventory: build GPT's option A for each** (the referee's pick, with
  the user now; if the user picks B for one, that piece gets simpler: build so each is a separate, removable part).
- **D5 budget:** no choice; the replay stops and reports if its projection passes 75 wall game min.

## Your role and rules
The builder for GPT's specs (now agreed with the Claude auditor): build exactly v2, add no ideas, report every change you
had to make. Work ONLY in `MPG_speed_t34`. **First `git merge speed-t1`** (T1 + its fix round, `4a74146`: `SPEED=fast`,
game-time deadlines, exact identities, lanes) and keep it intact; build on it, don't duplicate it. Commit locally after every
finished sub-step (WIP commits say what's left); no push; nothing on C: (temp / video / cache under the copy's `appdata/`).
**Game code untouched** (`FindingNaresh/scripts/` except `scripts/dev/`, scenes, assets, `core/Plant.gd`). A game bug you
notice: **your reply only, never in any file** (a symptom in a file is a hint to the blind replay). **Games: budget per v2:
T4 7 + 3 reserve (hard 15), T3 3 (hard 5); all in, stop at 20 wall game min.** At most 2 games on the PC; before each run
write its cost and the running total; watch every run while it runs; off plan -> stop, picture, note. Three failed fixes of
one thing -> stop, write where you got. Every new guard: its planted failure is refused AND the clean case passes.

## Write
`MPG_speed_t34\notes\speed_research\trial_T4_build.md` and `trial_T3_build.md` (the v2 "builder report": files, commits,
every deviation, each control pair expected / actual, commands, minutes per run, what stayed UNQUALIFIED), and a short
**`REPLAY_USAGE.md`** in the same folder: the exact commands a replay runner uses, start to finish, with no trial results in
it (the referee hands only that file to the blind replay). **Reply:** 10 lines.
