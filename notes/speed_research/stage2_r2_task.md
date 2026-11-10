# Stage 2, round 2 task (both auditors; written by the referee)

READ ONLY these: notes/SPEED_RESEARCH.md, notes/speed_research/{scoreboard.md, stage1_task.md,
ideas_claude.md, ideas_gpt.md, audit_r1_claude.md, audit_r1_gpt.md}, notes/TESTING_METHOD.md,
notes/method_research/FINAL.md lines 1-150, and in D:\mine\Agentics\T3_Code_Works\MPG_dev only
`git show 5f3e3e3:<path>` and `git show h1:<path>` for tools/ and FindingNaresh/scripts/.
DO NOT READ anything else under D:\mine\Agentics\T3_Code_Works\MPG\notes (TODO.md, MASTER_PROMPT.md,
ROUGH_NOTES.md, CHANGE_LEDGER.md, LESSONS.md, audits/, design pages other than via git show 5f3e3e3),
D:\mine\Agentics\T3_Code_Works\MPG_referee\, other commits, or skill testing-and-verification §3b.
Read the scoreboard's ruling R1 first.

Referee's facts for this round:
- On h1 a walk save point is the world RAW (no `Ghat.adjust_save` rewind) plus the script variables of
  the ghat node and of Problem (phase, phase_t, timers, suspicion...; `LiveControl._snap_live`). The
  claude r1 point "positions only, rewound" is true of 5f3e3e3, not of h1. Still unproven: that a
  resumed step's state equals the uninterrupted run's (one clean pass only). No code revision is stored.
- A joined (stitched) take worked on the ramp; whether the user accepts joins in a final video is the
  user's call, not ours: treat "one fresh final take" and "a joined take" as two options with costs.

WRITE notes/speed_research/audit_r2_<you>.md:
1. Answer every objection the other model raised against your ideas: concede (say what evidence
   changed your mind) or rebut with evidence.
2. Say where you now agree with the other's top 4 and where not, and why.
3. The agreed TOP 4 as you'd sign it: owner (2 Claude-run, 2 GPT-specified + Claude-built), the
   trial, minutes saved (table row), first experiment (< 5 game min), pass bar, and what makes it
   fail. Also the ORDER of the first experiments, given that the plan only reaches 75 min if the speed
   probe works (claude r1: ~99 min at 1x, ~68 at 2x).
4. One proposal: how to check "a resumed step's state equals the uninterrupted run's" cheaply.
Strict, evidence or "I think". Reply with a 6-line summary. (GPT: plans/specs only, no game code or runs.)
