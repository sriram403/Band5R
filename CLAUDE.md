# Finding Naresh: instructions for Claude

Start with `notes/MASTER_PROMPT.md` (how to resume, the user's rules, the
architecture) and `notes/TODO.md` ("Right now"). Lessons: `notes/LESSONS.md`.

## How to work (the user's principles, `notes/PRINCIPLES.md`)

- **First principles, not analogy.** Break a problem down to what is actually
  true (measured, tested, in the code) and build the solution up from there.
- **Never assume a limit you haven't tested**, especially on speed and cost.
  Run the smallest experiment that answers it, then decide.
- **The algorithm, in order:** question every requirement (who asked for
  it?), delete what isn't needed, simplify, speed up the cycle, automate last.
- **Keep the machine busy and the loop short:** build in the second copy
  (`../MPG_dev`, a git worktree on its own branch) while long tests run here;
  run the quick check for a change first, the long runs last.
- **Measure, then decide.** Numbers before opinions; an unexplained result is
  a question, not a pass.
- **Own it:** test it, look at the screenshots, read the logs, write the
  lesson down at once.

## Two copies of the project

- `MPG` (branch `main`): the long test runs, pushes.
- `MPG_dev` (branch per milestone part, e.g. `e3`): building the next part.
  It has its own `appdata/` (tests there don't touch this copy's runs) and a
  copy of `tools/godot` (not in git). Merge into `main` when the part is done.
- Two game instances at once work on this PC (measured 2026-09-27: 112 fps
  in one while the other ran the full world test). A frame-rate check that
  fails while both run is rerun alone before it is believed.
- Always check which folder a file is written to: a new file for the dev
  branch written into `MPG` sat outside the branch (2026-09-27).

## The user's rules in short (details in MASTER_PROMPT section 3)

Nothing on C: · one part at a time, the user's test before each push · "let's
discuss" means discuss · notes current at every step · tests stay behind the
user's windows · lessons written at once · at the end of a milestone, ask:
this thread or a new one.
