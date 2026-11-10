# Stage 1 task (the same for both auditors; written by the referee)

You are one of two strict, independent auditors in a two-model research (the other model's ideas are
hidden from you until Stage 2). Read, in this order:
1. D:\mine\Agentics\T3_Code_Works\MPG\notes\SPEED_RESEARCH.md (the brief: problem, benchmark, scoreboard, roles, rules). Follow it.
2. D:\mine\Agentics\T3_Code_Works\MPG\notes\TESTING_METHOD.md (how walks and tests work, versions v1-v6).
3. D:\mine\Agentics\T3_Code_Works\MPG\notes\method_research\FINAL.md, lines 1-150 ONLY (stop at "## Addendum: the method ported to #6": what follows names the benchmark's secret holes).
4. The tools as they were at the benchmark start, read-only, via git: in D:\mine\Agentics\T3_Code_Works\MPG_dev run
   `git show 5f3e3e3:tools/method_run.sh`, `git show 5f3e3e3:tools/record_walk.sh`, `git show 5f3e3e3:FindingNaresh/scripts/dev/LiveControl.gd` (header), `git show 5f3e3e3:tools/live/make_ghat.py`, `git show 5f3e3e3:design/PUZZLE_CHANGES.md` (#6 section), `git ls-tree -r --name-only 5f3e3e3 tools`.
   You may also read the NEW resume tools on branch h1 (`git show h1:tools/play_walk.sh`, `git show h1:tools/live.py`).
DO NOT READ: D:\mine\Agentics\T3_Code_Works\MPG\notes\ROUGH_NOTES.md, CHANGE_LEDGER.md, TODO.md, notes\audits\, D:\mine\Agentics\T3_Code_Works\MPG_referee\, commits after 5f3e3e3 other than h1's tools, or the skill testing-and-verification §3b. They hold the secret list. If you see a hole named by accident, say so in your file.
Do not run the game, do not edit any code. (GPT: you never write game code in this research; your trials are specs a Claude builder runs.)

WRITE your 7 ideas to D:\mine\Agentics\T3_Code_Works\MPG\notes\speed_research\ideas_<you>.md (<you> = claude or gpt). For each:
- how it works, concretely, in this project (which tool, which flag, what changes);
- which row(s) of the brief's 225-minute table it removes, and your estimate in minutes, marked measured / I think;
- how it could miss a hole or let a check go weak (false pass), make false alarms, or blame the wrong thing;
- its build cost (minutes of code) and any risk to the game;
- the smallest experiment (< 5 min of game time) that would show whether it works.
Then a short ranking of your 7 and what you would trial first. Be specific and skeptical; evidence or "I think".
Reply with a 6-line summary.
