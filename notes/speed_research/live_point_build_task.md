# Live play from a saved moment, with a sealed plant: the Claude builder's task (2026-11-25)

AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/step9_reaudit_gpt.md
AUDITED: D:/mine/Agentics/T3_Code_Works/FindingNaresh/dev/notes/speed_research/step9_code_audit_gpt.md

**Read this file first, before anything else.**

READ-ONLY: everything outside `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev`.
DO-NOT-READ: `D:\mine\Agentics\T3_Code_Works\FindingNaresh\extras\referee\`, `dev\nextprompt.txt`, other threads' files.
Don't ask; take your recommended option and say what you chose and why in one simple sentence.
FIRST: load these skills (Skill tool, by name): testing-and-verification, game-dev (+ references/godot.md), project-memory.

## Why (the user, 2026-11-25)
Today a model tests the game through scripts (walks). The user wants a model to PLAY it live, the way a human does
(look at the screen, press keys, look again) and to catch a bug AS IT HAPPENS. Trial 2: GPT plays ghat step 9 live from
the moment of a run that once hung, twice: once with the bug planted back (`stale_via`), once clean; GPT isn't told which.

## You: a fresh Claude Opus 5.5, high, builder (test code only, no game behaviour change). Referee: the main thread.
Branch: make `livept` from `main` in `D:\mine\Agentics\T3_Code_Works\FindingNaresh\dev` (dev may be on `gpttest`; it
has only report commits; switch with `git checkout -b livept main` once no game runs there: check `tasklist` for Godot
and that `appdata/playtest/runs/finished.txt` is fresh; if a game runs, wait for it). Commit per sub-step; no merge, no push.

## Build
1. **Start live play from a save point:** one command, e.g. `tools/live_from_point.sh <run>/<i> [--sealed <file>]`,
   that starts the game in `--playtest=live` mode restored at that point the same way the step-9 bench does (SaveGame +
   LiveControl's live part + rv1, seeded with the point's seed; see `ghat_step9_bench` in PlayTest.gd, commit `15d5cfe`),
   then PAUSES (the game tree paused) until the first `tools/live.py` command, so the player starts in control. No gate.
2. **The sealed plant:** `--sealed <file>`: the game reads the plant name (or "none") from that file at start and
   arms it (`core/Plant.gd`), and nothing about it shows on screen, in the HUD, in the game's log, in `state`, or in
   the command line. The referee keeps the file outside `dev` (in `extras\referee\`).
3. **Optional helpers for the player** (only if missing): `breath` on / off for each player (the hold-breath input,
   Ctrl / pad B) is already a key: check `tap` / `hold` work in the van; a `shot` from each seat; a `state` line that
   says only what a player would know (no creature internals: no phase, no waypoint, no timers).
4. **Prove it (budget ~8 game min):** (a) from `ghat_20261124_190738_7904` step-9 point, sealed `stale_via`: drive it
   with `live.py` waits + shots for ~90 s: Problem ends pressed on the van's nose (shots at 30 / 60 / 90 s); (b) the
   same, sealed `none`: it gives up within ~70 s. (c) Show the plant name appears nowhere a player can see (grep the log,
   `state`, the command line, the shots). Watch every run every few seconds; kill children + `stop_lane.sh` after.
5. Short how-to for the player (the model): `notes/LIVE_PLAY.md`: start (referee), the commands a player uses, what
   `state` tells, how to take shots, how to stop. Plain words.

## Rules
Edit / Write for every text change (never a heredoc patch, never `sed -i`, never `>>` into tracked files); parse-check
before commits; nothing on C:; mistakes into `notes/ROUGH_NOTES.md` "Assumed -> reality -> fix" at once; every run
declared before, counted; CPU load beside timings (`tools/method/cpu_sampler.ps1`).

## Report: `notes/speed_research/live_point_build_report.md` (what you built, files, the 3 proofs with shots, game
minutes, what you couldn't test). Last line: the commit hash.
