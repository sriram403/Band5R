# Polish list: agreed improvements, to do after all milestones

Things the user has tested, **agreed to change**, and asked to leave until
every milestone is built (right now the goal is to check that what's built
works as intended, then move on). Each item says what was agreed.

**For any model working on this project:** don't build these during the
milestones. **Remind the user of this list** when all the milestones are done
(Milestone G), or whenever they ask about it. Add to it whenever the user
agrees a change "for later". When one is built, tick it and say when.

`[ ]` agreed, not started · `[~]` being built · `[x]` done

## Test sheets

- [ ] **Screenshots in the test sheets** (the user, 2026-10-04): next to each
  step's "You should see", a picture of what it looks like when it worked,
  so the user can check at a glance instead of reading. The watched runs
  can take them (`shot` at each expected outcome) and the sheet links them.

## Puzzles

- [ ] **P1. Barn maze (W2): give the guide a job during the hay dust**
      (user, 2026-09-26). Now, when the dust blows over the middle, the guide
      on the loft balcony can only stand and wait while the walker talks.
      Agreed: option 3, both of these:
      1. The dust comes from an old **hay blower in the loft** that starts up;
         the guide goes inside and stops it (holds its crank a few seconds)
         while the walker carries on alone by the landmarks.
      2. A **plan of the maze** pinned up on the balcony: walls and the
         landmarks (red gate, scarecrow, blue drum, cart), no route, drawn
         faint so watching the maze is easier while you can see it. With the
         dust down, the walker describes where they are ("by the scarecrow,
         the gate behind me") and the guide finds it on the plan and guides
         from there until the dust settles.
      Files: `FindingNaresh/scripts/puzzles/BarnMaze.gd` (dust in
      `blow_dust`), the loft in `LevelLandmarks._barn`; test `t_maze`.
