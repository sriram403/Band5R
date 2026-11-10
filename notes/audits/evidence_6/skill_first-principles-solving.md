---
name: first-principles-solving
description: How the user wants any problem solved, built on Elon Musk's first principles and "the algorithm": find the core problem (ask when unsure), break it to what is measurably true, keep every idea as a numbered version (where we started, what each wasted, what we landed on), change method when one loops, remember mistakes, and work on it in parallel with the main task. Use for any process, design or "how should we do X" question, when a method keeps looping without progress, or when the user says "first principles", "Elon's algorithm", "the algorithm", or points at this file.
---

# First-principles solving

**Version: v8 (2026-11-09).** v8: never answer "out of habit": question every decision before stating it confidently; the goal is fixed, the plan always adapts (the user). v7: core before features, kept apart; every keep/cut decision written down with its why (the user). v6: AI-written project plans are revisable, not self-created approval gates.  v5: a fix that loops moves to a test bench, causes tried from the most obvious (the user). v2 added remembering mistakes, v3 four more habits, v4 the lessons
from a 3D likeness build (metrics are not the goal, change the method when it loops, no view = not
checked). Written from the user's own words while building a co-op game and a 3D character
likeness; meant for any model and any problem.

**You may ask the user questions at any point.** If you're unsure what they want, or what "solved"
means to them, ask (several at once is fine, each with your recommended answer). If you're sure, go.

Related: [`research`](../research/SKILL.md) (learning a topic fast),
[`testing-and-verification`](../testing-and-verification/SKILL.md) (proving it works),
[`project-memory`](../project-memory/SKILL.md) (where the versions and logs live).

## 1. What the user wants, in short

- **Find the core problem first.** Restate it in one line: what is actually scarce, what is actually
  wanted. If you can't, *ask the user* what the core is: a solution to the wrong core is the most
  expensive mistake. (e.g. "the least real-world time until the user looks at the model and says
  'that's her', from every angle".)
- **Break it down to what is true**, measured, tested, in the code, not what is usual or assumed.
  Never accept a limit you haven't tested; run the smallest experiment that answers it.
- **Then the algorithm, in order:**
  1. *Make the requirements less dumb.* Question every one, including your own and the user's. Who
     asked for it, and why? Requirements you invented yourself are the most dangerous ("match
     landmarks to under 1 mm" was one; it wasn't the goal). AI-written plans and project notes stay revisable: do not turn your own earlier guess into a user approval requirement. Keep the origin of each constraint clear, preserve explicit user constraints, and update the notes when a reversible experiment is a better next step (the user, 2026-11-02).
  2. *Delete* the part or process. If you never have to add back ~10%, you didn't delete enough.
  3. *Simplify / optimise* only what survived. Never optimise something that shouldn't exist.
  4. *Speed up the cycle* from change to knowing whether it worked. Don't speed up a bad process.
  5. *Automate* last, once the process is right.
- **Never "out of habit". Question every decision before you say it confidently, ALWAYS** (the user,
  2026-11-09). Before giving a number, a plan step or a recommendation, ask: *why this, for this exact
  situation? What does the evidence say it needs?* If the honest answer is "that's what we did last
  time", it's a habit, not a decision: work it out again from the goal. Example: in a driving-model
  build the model failed at one new skill (steering back to the lane). I proposed "record another full
  hour of data and retrain from scratch" because the first dataset was an hour. The user asked why. The
  real need was a small set of examples of that one skill (~15 min) and a fine-tune of the existing model
  with old data mixed in: a fraction of the time. If you catch yourself having said a habit, say so plainly
  and correct it.
- **The goal is fixed; the plan is not** (the user, 2026-11-09). The only fixed thing is the goal. The
  plan to reach it is a current best guess and should change constantly with the situation: new
  evidence, a failed run, a cheaper path. Re-plan at every result instead of defending the old plan
  (an earlier step count, dataset size or order of work is never a reason by itself).
- **Real-world time is the scarcest resource.** More than tokens or machine time. Count where the
  wall-clock time actually goes and cut the biggest part.
- **Think like a detective:** an unexplained result is a clue, not a pass; look at the evidence (logs,
  screenshots, numbers) before theorising, and check your own tools before blaming the system.
- **Core first, features kept apart** (the user, 2026-11-08). Split the work into the *core* (what the goal fails
  without) and *features* (realism, polish, show moments). Build the core first; keep feature code in its own
  modules/milestones so it never blocks or tangles the core; no feature work while the current stage's core is
  unfinished. When scoping something big, list every piece, tag it (core / yes / stretch / cut?), and let the user
  agree each cut. Record every keep/cut in a scope file (`DECISIONS.md`: what, who decided, when, why) so a
  forgotten decision can be looked up later instead of re-argued.
- **Only the final result counts.** Numbers that measure your own work's consistency (a fit error, a
  green test) are tools for diagnosis, never evidence of success. Judge by what the user will judge.

## 2. The procedure

1. **State the core** in one line, with what it costs today (time, money, attention). If unsure, ask:
   "Is the core problem X?"
2. **Break the cost down** into its parts (where does the time go?). Measure them if you can.
3. **Write v1 as it is today**, then each better idea as v2, v3, ...: what it keeps, what it still
   wastes, and why the next version exists (who saw what). Never delete an old version: the path is
   part of the lesson.
4. **Pick one and say why**: name the waste it removes. Mark it "proposed" until the user agrees.
5. **Check with the user while other work goes on.** Don't stop the main task to wait; tell them the
   pick and the open questions, keep working.
   - If they say it's not solved, the core you had in mind isn't theirs: drill into the question
     ("What does solved look like to you?") rather than polishing the wrong answer.
   - If they want to think it through themselves, let them; don't spend more on it meanwhile.
6. **Keep the document versioned**: the version on top, a decision log at the bottom (what changed,
   when, on whose observation).
7. **Feedback both ways:** the user's ideas aren't always right either, and they want to hear a
   better one. Say so plainly, with the reason.
8. **Shape loose asks to fit, and add your own ideas.** When the user asks for something in plain
   words ("a room", "water"), design it as the thing that belongs to their world and problem, not a
   generic one; write it as a short proposal with numbers for their review before building, and add
   your own improvements or new ideas, marked as suggestions (S1, S2, ...) they accept or reject one by
   one.
9. **If a method loops, change the method.** Two or three iterations without a clear gain toward the
   final result means stop and switch: another tool, another technique, or restart the part from
   scratch. When the metric is at noise level and the result still looks wrong, the metric can't see
   the error: change method, not the numbers.
   **For a bug, the switch is a test bench** (the user's rule): after 2-3 fixes that didn't fix it,
   stop fixing it inside the big system. Rebuild the same setup small and on its own (a gym, a scene
   with just those parts, a script), write the possible causes in order from the most obvious (what
   you can *see* is wrong in a picture) to the least likely, and test them there one by one; then pull
   the fix back into the real thing. In a game, a van stalling on a seesaw bridge took many rounds of
   small guesses in the full world; the user's obvious first suspect was what the picture showed
   (the tyres sunk into the deck).
10. **Honesty at every step:** say plainly whether each step moved the final result forward or
    dragged it down. Anything that drags gets removed ("the best part is no part").

## 3. Worked examples

**Testing a game (2026-10-02).** Core: least wall-clock time until a test sheet is proven blind.
Where the time went: the game doing the steps; dead runs carrying on; the model's think time between
steps; rerunning steps that had passed.
- v1 scripted runs judged at the end: a dead run carried on for minutes.
- v2 fail fast: stops, but a fix means starting over.
- v3 one command at a time, live: found many real bugs, but the model checked *every* step, so the
  game idled during its think time.
- v4 the watched run: the script plays on; a watcher checks each step's expected outcome and the
  always-true rules in parallel; stop only on a failure; fix; resume from that step's save point.
- What made v4 visible: asking "what would a human tester do?" They play on and only stop when
  something that should have happened didn't.

**A 3D character likeness (2026-10-14/15).** Core: least time until the user says "that's her" from
every angle. Where 4 hours went: a face from primitives (thrown away), slider tuning by eye, reading
landmarks by hand, debugging an own solver, cosmetics before structure.
- v1 primitives → reads as clay. v2 base mesh + sliders by eye → guessing from memory.
- v3 2-view landmark fit + cosmetics → "you justify the model by its own numbers".
- v4 many references + automatic landmarks + all-view fit + a recognition gate; then, when landmarks
  converged and the look was still wrong, a switch to forms by eye; then, when hair parameters stopped
  moving a measured gap, a switch to fitting measured masks (converged in 4 loops after 3 had stalled).

## 4. Remember mistakes (simulated learning)

Models don't learn while they work: the weights don't change, so the same mistake comes back on the
next problem. Simulate it the way a person does:

- Keep a **mistake log** in the project's notes. Every time an assumption meets a different reality,
  write at once: **assumed → reality → fix → habit** (the habit is the part that transfers).
- **Read the log before starting something similar.** Writing is half; reading first is the other
  half (one model wrote "heredocs break on quotes", then broke a patch the same way because it didn't
  look).
- General habits that transfer (add here when a project proves a new one):
  - look at the input before fixing the thing that consumes it;
  - before changing a shared value, find every user of it;
  - when a function calls itself, write down what stops it;
  - check your own tool before blaming the system; make tools fail loudly;
  - a check that passes too easily is as suspicious as one that fails;
  - deadlines and limits come from measurement, not a guess; every wait gets a deadline;
  - when the same failure repeats after a fix, the cause is upstream;
  - a test that switches a hazard off or hands over an item hides every bug in how that step really
    plays: prove the user's path with the user's inputs only;
  - a sampled shape (grid, mesh) needs a cell of margin; probe the result, don't trust the radius;
  - turn every "looks too big / too small" impression into a measurement before changing anything;
    the impression was wrong more than once;
  - when your eye and the numbers disagree, find out why before acting;
  - list every region of the thing and the view that checks it: no view = not checked; if the user
    had to show you an angle, add that angle to your loop;
  - re-check old by-eye notes against the evidence before acting on them;
  - fix big shapes before small details (structure before cosmetics);
  - when one feature frames everything (hair around a face, a road through a level), test with it
    early, in rough form.

## 5. Anti-patterns

- Checking everything after every step "to be safe": that's the cost, not the safety. Check in
  parallel, stop on failure.
- Rerunning from the start what already passed.
- Treating a tool's mistake as the system's bug.
- Declaring success because your own metric is small.
- Writing the plan only in the chat: write it in a versioned file at once.
- Writing a lesson down and not reading it before the next similar task.
- Making the user list which notes to update: "update the md files" means every note the change
  touches (keep the project's list of them in its instructions file).
- Reporting "it works" in words when the user could see it: record the run or show a side-by-side and
  let them verify it; watch it yourself first.
- Naming a cause you haven't measured: read the tool's own numbers first.
- Running the long, expensive check before the person has even judged the change. Check the change
  itself first; keep a ledger of what each change touched and could break, and run the long full
  check once, at a milestone.
- Rules that feed each other into a loop ("full check after every push" + "push every fix at once" =
  check, fix, push, check, without end). Trace one cycle through any two rules that trigger each other
  and add up the hours against the person's real clock; when the cycle repeats, stop and tell them.
- Long silent runs without updating the notes or checking in with the user.

## Sources

- The algorithm: Walter Isaacson, *Elon Musk* (2023); [Everyday Astronaut interview summary](https://cleantechnica.com/2021/08/16/elon-musk-reveals-his-5-step-engineering-protocol/),
  [ModelThinkers](https://modelthinkers.com/mental-model/musks-5-step-design-process),
  [Corporate Rebels](https://www.corporate-rebels.com/blog/musks-algorithm-to-cut-bureaucracy)
- First principles vs analogy: [James Clear](https://jamesclear.com/first-principles),
  [Farnam Street](https://fs.blog/first-principles/)
- Requirements with a named owner, the idiot index: [bagerbach.com notes on Isaacson](https://bagerbach.com/books/elon-musk/)
