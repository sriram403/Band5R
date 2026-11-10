# Stage 2, round 1 task (both auditors; written by the referee)

Same reading and the same DO-NOT-READ list as notes/speed_research/stage1_task.md (read it again first).
Now read BOTH idea files: notes/speed_research/ideas_claude.md and notes/speed_research/ideas_gpt.md.

Referee's notes for this round (facts, measured today on branch h1 in MPG_dev):
- Resume from the failed step is now the tools' default (tools/live.py, play_walk.sh, record_walk.sh); proved on the ghat walk (failed at step 9 mid-encounter -> rerun resumed at 9, ran clean; 122 s of steps 1-8 not replayed) and on the ramp recording (3 parts joined). A resumed walk also found a real load bug (the ramp's wheel). Treat "resume" as available, not as an idea to build.
- The score counts summed game minutes of every Godot process, so two games at once saves wall time but not score (both of you said so; agreed).

WRITE notes/speed_research/audit_r1_<you>.md:
1. Audit EACH of the other model's 7 ideas: does it hold (evidence or "I think")? How exactly would it fail: a missed hole, a weakened check (false pass), a false alarm, wrong blame, or cost? What would you change?
2. Re-audit your own 7 in the light of the other's (drop or merge where theirs is better; say which and why).
3. Merge true duplicates across both files (say so).
4. Propose the TOP 4 to trial (2 run by Claude, 2 specified by GPT and built by a Claude builder), each with: the trial in one paragraph, its expected minutes saved (from which table row), the smallest first experiment (< 5 game minutes), and the pass bar.
Strict: agreeing needs a reason in your own words. Reply with a 6-line summary.
(GPT: plans and specs only, no game code, no game runs.)
