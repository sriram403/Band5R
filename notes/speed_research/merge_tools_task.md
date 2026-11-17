# Bring the speed research's tools into main (the user: A, 2026-11-17). Written by the referee.
AUDITED: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\reaudit_T34_gpt.md
AUDITED-ALSO: D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\reaudit_T34_claude.md

## READ THIS FILE FIRST. Then read
- `D:\mine\Agentics\T3_Code_Works\MPG\CLAUDE.md` (the project's rules), `notes\TESTING_METHOD.md` (v7 at the end),
  `notes\speed_research\FINAL.md`, `notes\CHANGE_LEDGER.md`, the last 12 entries of `notes\ROUGH_NOTES.md` "Assumed -> reality -> fix"
- the branches `main` and `speed-t34` (`fd4ae18`) of the repo at `D:\mine\Agentics\T3_Code_Works\MPG`
Do NOT read `MPG_referee` (private).

## The job
Work in `D:\mine\Agentics\T3_Code_Works\MPG_dev` (a worktree of the same repo; it holds `h1`, already merged into main). There:
`git switch -c speedtools main`, then `git merge speed-t34`. A dry run shows 8 conflicts: `.claude/settings.json`,
`FindingNaresh/scripts/dev/LiveControl.gd`, `FindingNaresh/scripts/dev/PlayTest.gd`, `tools/hooks/test_triggers.py`, `tools/live.py`,
`tools/method/prove_ghat.py`, `tools/play_walk.sh`, `tools/record_walk.sh`.
- **main wins on the game and on every check / plant main has** (main has #6 day 2's fixes, its checks and plants: the 27-row
  matrix). **speed-t34 brings the tools:** `SPEED=fast` + nodraw routing (fast only for heat / net per v7), two lanes and the
  guard, game-time deadlines, receipts, `t3_gate.py` / `t1fix` judges, captures, the resume gate (`walkgate.py`, refusing: fresh
  takes for acceptance), `record_walk.sh` rec25 + identity, `lane_sentinel.sh`, `stop_lane.sh`, `cpu_sampler.ps1`.
- No check removed, no plant row removed, no game code changed (`FindingNaresh/scripts/` outside `scripts/dev/`, scenes, assets,
  `core/Plant.gd` stay main's). Both hooks in `.claude/settings.json` kept.
- The required-check list rebuilt from main's scenarios (`freeze_ghat.py`), and `prove_ghat.py`'s groups = main's 27 rows + solo groups.

## Prove it (the project's rules: the changed part's checks, not the full run)
1. Offline: `t3_controls.py`, `t4_controls.py`, `t4_join_controls.py` pass (fixtures they need: copy from `MPG_speed_t34/appdata` into
   this copy's `appdata`, never into git); `godot --check-only` / the import check clean. 0 game min.
2. Live, watched, CPU load noted: the ghat suite once, `ROLE=final SPEED=fast tools/method_run.sh ghat` (~13 game min) -> PASS;
   one planted row fast (e.g. `heat_always`) and one at 1x (e.g. `no_breath_lock`) -> each FAILS by its own id. Budget **20 game min**
   (hard 25); two failed fixes of one thing -> a bench, then stop and write where you got.
3. A `notes/CHANGE_LEDGER.md` entry (what came in, what it could break, which tests cover it); `CLAUDE.md` / `AGENTS.md`: one line
   each pointing to TESTING_METHOD v7 and the new commands. Commit on `speedtools` after each step. **Do not merge into main and
   do not push**: the referee merges after checking.

## Reply (8 lines)
Commits, each conflict and how it was resolved, the offline counts, the live verdicts with game minutes, anything left.
