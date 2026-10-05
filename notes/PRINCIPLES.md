# How we work: first principles (user, 2026-09-27)

The user's way of getting things done, for every model (and person) working
on this project. Adapted from Elon Musk's working principles (first-principles
thinking and "the algorithm", as told in Walter Isaacson's biography) to
building this game with AI. Each rule has an example from this project.

## 1. First principles, not analogy

Break a problem down to what is actually true (measured, tested, in the code),
then build the answer up from there. Don't do something "because that's how
it's done" or because it worked somewhere else.

- *Example:* "we can only run one game at a time, so we wait an hour for the
  full test" was an assumption. Broken down: is the limit the PC, Godot, or
  the tests? Tested: two game instances on this PC ran fine (a beach test at
  112 fps while the full world run went on, 144 alone). So: a second copy of
  the project (`MPG_dev`, a git worktree) for building while `MPG` tests.
  Nobody waits.

## 2. Never assume a limit you haven't tested

Especially speed, cost and "can't be done". Try the smallest experiment that
answers it, then decide. Say "I haven't measured this" rather than guess.

- *Example:* above. Also: a 50-minute run to check a one-line test fix is the
  wrong tool; run that one scenario (seconds), then the long run once.

## 3. The algorithm, in this order

1. **Question every requirement.** Each one should trace back to someone who
   asked for it (the user, a design page, a test). A requirement from "the way
   we did it before" is a suggestion. *Example:* "keep only one game running"
   was a rule written to stop tests fighting over one window and one progress
   file; with two separate copies, each with its own data, it no longer
   applies.
2. **Delete what isn't needed.** Steps, checks, files, features. If nothing
   ever has to be put back, not enough was deleted. *Example:* the full run's
   world part alone (`set:world_full`) instead of redoing the openings and
   gyms that already passed.
3. **Simplify, then optimise**, only what survived step 2. The most common
   mistake is to optimise something that shouldn't exist.
4. **Speed up the cycle.** Shorter loops between a change and knowing whether
   it works: the scenario for the change first, the long runs last, and work
   in parallel while they run.
5. **Automate last**, once the process is right (the play-test launcher,
   resume, the test plans).

## 4. Keep the loop short and the machine busy

- While a long run goes, build the next part (in the second copy).
- Run the quick check that can fail first; the long confirmation after.
- If waiting is the only option, say what is being waited for and roughly how
  long, and plan the next step meanwhile.
- **Time is the scarcest thing, more than tokens or machine time (the user,
  2026-10-01).** Test exactly the change in hand, with the smallest check
  that answers it: a throwaway scenario of a few seconds, not a rerun of an
  existing long test because it happens to cover it. Example of what not to
  do: a two-line change to where players start in the storm gym was checked
  by rerunning the whole 3-minute storm test, twice. A 5-second
  "where do they stand, what do they see" check was the right size. Rerun
  the long tests only once, before the hand-over or the push.

## 5. Measure, then decide

Numbers before opinions: fps, seconds per scenario, metres off the road.
"It feels slow" becomes "the world run is 50 minutes, 16 of them the road
drive". A result you can't explain is a question, not a pass.

## 6. Own the whole thing

Whoever builds a part tests it, looks at the screenshots, reads the logs and
writes down what was learnt (`notes/LESSONS.md`). No "that's the test's
problem"; no green test believed without looking.

## 7. Remember your mistakes (the user, 2026-10-02)

A person remembers a mistake made on one problem and is careful on the next.
Models don't learn while working (the weights don't change), so we simulate
it: every time an assumption meets a different reality, write *assumed ->
reality -> fix -> habit* in `notes/ROUGH_NOTES.md` ("Assumed -> reality ->
fix"), at once, and read that list before starting something similar.

- *Example:* a patch written through a bash heredoc broke on quotes; the
  lesson was written, then the same thing broke again because nobody read
  it before reaching for the same tool. Writing it down is half; reading it
  first is the other half.

## 8. Don't check every step that worked (the user, 2026-10-02)

A human tester plays on and stops only when something that should have
happened didn't. Plan the expected outcome of each step, check them in
parallel, stop on the first failure, fix, carry on from there
(`notes/TESTING_METHOD.md`).

## 9. Show it: record the walkthrough (the user, 2026-10-05)

Once a test sheet's steps are written, play them and record the run as
a video for the user to verify: easier to understand than a report, and
it shows what was done. Watch it yourself first (`notes/TESTING_METHOD.md`
v5).

## 10. Fit the world, propose first, add your own ideas (the user, 2026-10-05)

- **Whenever the user asks for a thing in plain words** ("a room", "water",
  "wind", "a key"), design it as something that belongs to that puzzle and
  place: the water works' own brick pump house as the closed room, its
  water tower for the key, sludge for the waste tank. Never a generic box.
- **Propose before building:** write the idea as a short proposal (what it
  is, how it plays, the numbers), the user reviews it, then build.
- **Add your own ideas** on top of the user's, marked as suggestions: an
  improvement to theirs, or something new. They say yes or no to each.
- *The aim for every puzzle:* keep both players on their toes the whole
  time. They can't see each other's side, each needs what the other knows,
  and every mistake has a quick, funny, visible consequence (often for the
  partner), so they keep talking.
- *Example:* the water works (`design/PUZZLE_CHANGES.md`, #1).

## Sources

- Walter Isaacson, *Elon Musk* (2023): "the algorithm"; summaries at
  [ModelThinkers](https://modelthinkers.com/mental-model/musks-5-step-design-process),
  [Corporate Rebels](https://www.corporate-rebels.com/blog/musks-algorithm-to-cut-bureaucracy),
  [The Book of Elon Musk](https://www.elonmuskbook.org/the-book-of-elon-musk-free-online-version/the-algorithm).
- First principles vs analogy: [James Clear](https://jamesclear.com/first-principles),
  [Farnam Street](https://fs.blog/first-principles/),
  [CNBC](https://www.cnbc.com/2020/02/28/billionaire-elon-musk-this-is-a-powerful-way-of-thinking-but-hard-to-do-how-it-works.html).
- Requirements traced to a named person, the "idiot index":
  [bagerbach.com notes on Isaacson](https://bagerbach.com/books/elon-musk/).
