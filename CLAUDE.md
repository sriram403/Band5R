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
- **Record the walkthrough (the user, 2026-10-05).** Keep writing the
  test sheet; once its steps are written, play them as a watched run,
  record it (`tools/record_walk.sh <walk>` -> `appdata/videos/`), watch it,
  and send it with times and what to judge. The user verifies the video
  first instead of playing straight away.

- **Fit the world, propose first, add your own ideas (the user,
  2026-10-05).** When the user asks for "a room", "water", "wind" and so
  on, design it to belong to that puzzle and place, write it as a short
  proposal for their review, then build. Add your own ideas or
  improvements to theirs, marked as suggestions. Puzzles keep both players
  on their toes (`notes/PRINCIPLES.md` 10, `design/PUZZLE_CHANGES.md`).
- **Both out of the van, no repeats, fun mechanics (the user,
  2026-10-06).** Every stop needs both players on foot, each with a job.
  Never repeat a puzzle (how it plays or what it's for); when the user's
  ask repeats an earlier puzzle or idea, say so and suggest a way round.
  A challenge can be the thing instead of a puzzle. At least three fun
  mechanics like the head-butt. Mistakes have real consequences.
- **Built for humans (the user, 2026-10-07).** Look at every placed thing
  from where a player stands before showing it: visible, reachable, notes
  readable, nothing floating or sunk, blockers that really block (drive
  round them). Every action shows visibly that it worked.
- **Lived in, never programmatic (the user, 2026-10-07).** Built things
  look placed by a person; natural things sit as nature would leave them
  (clumps, half-sunk rocks, no rows). A cramped space gets bigger.
- **The change ledger; long runs off the critical path (the user,
  2026-10-08).** Before the user's look: only the change's own tests,
  smoke and its area set. Each finished puzzle gets an entry in
  `notes/CHANGE_LEDGER.md` (what changed, what it could break, which tests
  cover it). On "push": push at once, then start set:driving / full in the
  background in `MPG` while the next part is built in `../MPG_dev`; write
  what they find under its ledger entry and fix it next round. One last
  full run at the end of the puzzle tuning, checked against the ledger.

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

## Remember mistakes; "update the md files" (the user, 2026-10-02)

- **The mistake log.** Models don't learn while they work, so we simulate
  it: whenever what you assumed meets a different reality, write it down at
  once in `notes/ROUGH_NOTES.md`, section "Assumed -> reality -> fix": what
  you assumed, what really happened, the fix, the habit to keep. **Read that
  section before starting something similar.**
- **Learnings go in the rough notes the moment they happen** (process, code,
  game; small or big). Sorted lessons go in `notes/LESSONS.md`.
- **"Update the md files"** means: update every file below that the change
  touches, without being told which:
  - `notes/ROUGH_NOTES.md` (learnings, the mistake log)
  - `notes/LESSONS.md` (sorted lessons), `notes/TODO.md` ("Right now")
  - `notes/MASTER_PROMPT.md` (status, rules), `notes/PRINCIPLES.md` (how we work)
  - `notes/TESTING_METHOD.md` (versioned method), the current
    `notes/TEST_MILESTONE_*.md` sheet, design pages when a decision changes
  - `CLAUDE.md` and `AGENTS.md` (instructions for Claude and for GPT / other
    models: keep the two in step)
  - the user's skills: `D:\mine\Agentics\Skills\skills\first-principles-solving\SKILL.md`
    and its copy `C:\Users\srira\.claude\skills\first-principles-solving\SKILL.md`
    (general, not game-specific, lessons only)
  - the project guide `D:\mine\Agentics\Skills\project-guides\finding-naresh\`
    (copies of CLAUDE.md, AGENTS.md, notes/PRINCIPLES.md, LESSONS.md,
    TESTING_METHOD.md, MASTER_PROMPT.md): copy them over after updating
  - Claude's memory (`memory/`), for rules about how to work
