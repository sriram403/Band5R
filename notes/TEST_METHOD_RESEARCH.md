# Test method research: the brief

Started 2026-11-05 by the user. This file is complete: nothing from the old
thread is needed. Results go in `notes/method_research/` (see "Files").

## The problem

The game is Finding Naresh: two-player co-op, Godot 4.7.1, world built in code.
The user played the new ramp jump (`puzzles/RampJump.gd`, branch `g12`): **"the
whole thing works on my playthrough"**. Yet our tests kept failing on it, and
sometimes passed when they shouldn't have.

The user's diagnosis: our complex tests try to **predict the future**. A script
written ahead of time says "hold W for 7 s, stand here, press E". That's fine
for simple things, not for complex play. The user wants a right way to verify
complex play with the game engine, without hardcoding everything.

**The question:** how do we check that a complex, unpredictable stretch of play
really works, when:
- it can't depend on exact positions or timing;
- it gets there the way a player would, with no teleporting or aimed cameras in
  the part being proven;
- a pass has to mean something;
- a failure has to say whether the game or the test is wrong;
- it can't eat the user's real time.

## What went wrong (the evidence)

| What happened | Type | Cause |
|---|---|---|
| 8 recording takes for one video, 5 lost to the walk script | False alarm | Typos and bad expressions in `tools/live/make_ramp.py` |
| Van landed in a different place on each of 3 runs (gap frame x -8.75, -10.45, -12.31; z about -50 to -53) | False alarm | The drive-off script only pressed forward; the van hit a tree, "drives off: 7 m in 8 s" |
| After `ramp`, 5 failures, then a frozen game | False alarm | The test ended with `boot._on_joy_changed(0, false)`: the game correctly paused for the lost pad, and later tests ran paused |
| "Back on the road" failed: 15.8 m off | False alarm | The bot reached the road (1.1 m), then circled at 40 km/h. Cause not confirmed (maybe `AutoDriver`'s road index stuck after starting off road) |
| Walk passed, video ends with the van stuck at a tree | **False pass** | The last step only checked the wheel was on |
| Leg-up check passed for nothing | **False pass** | The pad wasn't enabled, so the check never tested P2 |
| Asked for 6 scenarios, 4 ran, summary said 0 failures | **False pass** | `save` reloads the scene; anything queued after it silently never runs |
| The frozen test: the user saw it first | Watching failed | The watcher only read failure lines, a paused game writes nothing; `cut` buffered the FAIL lines |
| I told the user a swimming player slowed the van; it was the van rolling | Wrong blame | An unmeasured cause stated as fact |

**Real bugs the same tests did find, so we can't throw them away:** the van rolled
downhill after a miss and used up its run-up (57 km/h instead of 66); the hut door
sill blocked walking; a swimmer stayed in swim mode beside the van; rubble where
the crate goes; piers stopping in mid air; the wreck under water; the bare hub
below ground; the HUD saying PUNCTURE with no wheel. Most were found by looking at
pictures or video, not by the checks.

**Three things that make this hard:**
1. It isn't only the Python. `dev/PlayTest.gd` runs inside the engine with the
   same problem, and it teleports players and aims cameras.
2. Reacting isn't enough on its own. `AutoDriver` reacts every frame and still hit
   a tree and circled, because it senses very little.
3. **An old trap:** we once tried the model looking and deciding at each step
   (one command at a time). The model's thinking time became the biggest cost, so
   it was dropped. `notes/TESTING_METHOD.md` has the whole history: judged at the
   end, fail-fast, one command at a time, watched run. Don't walk back into it
   without answering why it won't cost the same.

Theo's video (`C:\Users\srira\.t3\userdata\attachments\e22712e0-6613-4374-9a32-d7214f7a7b25-9c7e563d-53b9-44a9-8b80-30d2023c38f3-txt.txt`)
gave the shape: agents do well when something can tell them, without a human,
whether they succeeded. Add errors on purpose and check they're caught; keep some
checks private so nobody writes to the test; a separate judge looks at the result.
His warning: judges get chased (about $800 of tokens on a skybox).

## The people

| Role | Account and model | Does |
|---|---|---|
| **Referee** (the thread reading this) | `claudeWork`, `claude-opus-5-5`, effort high | Runs the process, plants bugs, keeps the scoreboard, reports. Writes no ideas and takes no side. |
| **Claude auditor** | `delegate_task`: providerInstanceId `claudeWork`, model `claude-opus-5-5`, options `{effort:"high"}` | Ideas, audits, its own trials, its own code |
| **GPT auditor** | `delegate_task`: providerInstanceId `codexWork`, model `gpt-6.1-sol`, options `{reasoningEffort:"high"}` | Ideas, audits, designs its trials, reviews the code. **Writes no game or test code** (the user: GPT is weak at game dev) |
| **Opus builder for GPT** | `delegate_task`: providerInstanceId `claudeWork`, model `claude-opus-5-5`, options `{effort:"high"}` | Builds exactly what the GPT auditor specifies. Adds no ideas of its own; reports anything it had to change. |

Every new round is a new `delegate_task` carrying the brief, findings and
objections (children have no history). Don't use `t3_thread_send` for this.

**Both auditors are professional, strict auditors (the user's order).** They fight
back. Neither accepts an answer because it sounds right or to be polite:
- every claim needs evidence, or is marked "I think";
- each audit must try to break the other's idea and name how it would fail: a false
  alarm, a false pass, wrong blame, or cost;
- "looks good" isn't an audit; agreeing needs a reason, stated in their own words;
- changing your mind is fine only when evidence did it, and you say which.

## The process (the user's design)

**Stage 1: 14 ideas.** Each auditor writes 7 solutions **without seeing the
other's**. Each: how it works, what it would have caught from the evidence table,
how it fails, what it costs in the user's real time.

**Stage 2: the fight, then the top 4.** Each gets the other's 7 and audits them.
Merge true duplicates, saying so. They must agree on **4: 2 for each model to run**.
At most 3 rounds; after that the referee lists what's still disputed and picks by
the scoreboard criteria, giving reasons.

**Stage 3: trials, taking turns: Claude, GPT, Claude, GPT.**
- Build the smallest working version on the ramp, then score it.
- After each trial, the report goes to the other model: passed or failed, the numbers,
  **why**. It then continues, changes its next trial, or drops it. A drop needs a
  stated reason, and the referee records it.
- The other auditor audits each result before it counts.
- **Cap: about 1 hour per trial.** Hitting the cap counts as failed and reports where it got.

**Stage 4: final exam, then agreement.** The best method(s) face the secret bugs and
the second puzzle. **The scoreboard decides; any disagreement has to be explained.**
Both auditors must sign one final method, with the reasons in their own words. Still
no agreement after 3 rounds: stop and take both positions to the user.

## The scoreboard

Fair across all trials, written before the trials, and only the referee changes it
(with a logged reason).

| Check | How | Pass |
|---|---|---|
| **No false alarms** | Run on the working game at least 10 times, varying speed and where the van lands | Passes every time |
| **Finds real bugs** | Practice set: known bugs put back. Final: secret ones | Catches them, and names the right thing |
| **Blames the right thing** | Break the test itself (pad unplug, stale expression, scenario queued after `save`) | Says "test problem", not "game problem" |
| **Can't pass by doing nothing** | Game frozen or paused, a player missing, a scenario skipped | Fails or reports it, and quickly: no silent waits |
| **Real path** | Read how it reaches the state it's proving | No teleports, set state or aimed cameras in the part being proven; setup before it is OK if declared |
| **Cost** | Minutes per run, and tokens/model time per run | Reported. Model thinking inside the loop must be justified against the old trap |
| **Not only the ramp** | Final: one other complex puzzle chosen by the referee, unseen | Works with reasonable effort; report the effort |

**Bugs.**
- **Practice set (public):** the real bugs above; they're in the notes and git, so
  they can't be secret. Put back as patches.
- **Final set (secret):** new bugs written by the referee, not found in any note or
  commit, each seen to break the game for real before it counts. Auditors and builders
  don't get them, and must not go looking for them. Reports during trials give counts
  and reasons for the practice set only.

**Keep in mind:** simple scripts stay for simple things (saves, menus, resets). No method
judges whether something is fun: that's the user's. The method proves it works, so
they can spend their time on the fun.

## Rules that must not be broken

The work accounts don't load the user's personal skills or rules. So here they are:

- **Git:** everything on the branch below; **no merge and no push** (`g12` isn't merged
  until the user OKs it, after this research). Only ever commit locally.
- **Nothing on C:.** T3's `isolation:"worktree"` creates checkouts under
  `C:\Users\srira\.t3\worktrees`, so **don't use it.** Everything happens in
  `D:\mine\Agentics\T3_Code_Works\MPG_dev`. Children use `isolation:"shared"`, one
  at a time. Stage 1 and audits need no game; run them side by side if you like.
- **Branches:** start from `g12`. Each trial on its own: `g13-trial-c1`, `g13-trial-g1`,
  `g13-trial-c2`, `g13-trial-g2`. **Don't touch `MPG` (branch main)** or the user's
  `nextprompt.txt`.
- **One game run at a time in a copy.** Check `tasklist` first. A second run resets the
  first's logs. Never edit files a running test loads.
- **Tests stay behind the user's windows,** muted, never taking focus.
- **Watch every run for real:** see that it's moving, not just that no failure shows.
  A watcher must also flag a log that stops growing (45 s is a fair limit), every pipe
  stage must flush per line (`cut` doesn't), and compare scenarios asked against
  scenarios run. Ask yourself: "if this froze right now, would I hear?"
- **Know a run's cost in minutes before you start.** Each run finding something and
  each fix starting another is a loop: stop and report instead.
- **Debug with pictures:** when stuck, take a shot from a useful angle or pull video
  frames, and reason from what you see. Numbers back it up.
- **A failure says the game OR the test is wrong.** Name which only once it's measured.
- **Don't change the game to suit a test.** If a real game bug turns up, write it in
  the findings and tell the user; don't fix it in a trial branch unnoticed.
- **Nothing important only in chat.** Mistakes and lessons go in `notes/ROUGH_NOTES.md`
  ("Assumed -> reality -> fix") as they happen. Keep `notes/TODO.md` "Right now" current.
- **Don't edit the skills library** (`D:\mine\Agentics\Skills`) from this work. Lessons
  for it are listed in the final report; the user decides.
- **Talking to the user:** short, plain, a bit fun, questions as A / B with your pick.
  Tell them at each stage's end and at anything unexpected. They watch real time, so
  never go quiet for long.

## Project facts

- Read first: `CLAUDE.md`, `notes/TESTING_METHOD.md`, `notes/ROUGH_NOTES.md` (the last 40
  lines), `design/PUZZLE_CHANGES.md` "The ramp jump", `notes/TEST_PUZZLES.md` section 5.
- **Tests:** `tools/run_test.sh <scenarios>`; logs in `appdata/playtest/runs/seg_1.log`,
  `summary.txt`, `finished.txt`; shots in `FindingNaresh/_shots/test_*.png`. Scenarios
  are `t_<name>` methods in `FindingNaresh/scripts/dev/PlayTest.gd`.
- **Walks:** `tools/live/make_<w>.py` writes a json; `tools/record_walk.sh <w>` records
  `appdata/videos/<w>.mp4`. ffmpeg: `D:\ffmpeg-2025-12-24-git-abb1524138-full_build\ffmpeg-2025-12-24-git-abb1524138-full_build\bin\ffmpeg.exe`.
- **Costs measured:** smoke 3 min 11 s; `ramp` about 100 s; `ramp_retry` 88 s;
  `ramp_edges` 22 s; `ramp_wedge` 11 s; walk `ramp` 169 s. Two game instances at once
  have worked on this PC (`MPG` and `MPG_dev`).
- **Traps:** `save` must be last, it reloads the scene. `boot._on_joy_changed(0, true)`
  enables P2's pad, and shots show only P1 without it; turning it off pauses the game.
  The world is built outside the scene tree, so no `global_*` during setup. A walk's
  `expr:` (Godot's Expression) can't see class names and has no ternary. A walk's expects
  run in parallel with its steps. `AutoDriver` is in `PlayTest.gd` (line ~7454).
- **The ramp:** gap 14 m, ramp 0.8 m high, run-up 100 m. Under about 57 km/h falls short,
  61 lands clean, flat out gives about 66-68. Then: nuts snap, wheel goes through the hut's
  shutter (scripted path), crate + leg-up, bolt, toolbox, refit, drive off.
- **State at start:** `g12` head has the `ramp` test's last edit ("gets back to the road":
  closest approach under 3 m) **never run**. `way_out` and the rest of `set:puzzles` are
  **not run** since the bridge came out. The user has not yet played: a miss, a boiling
  engine, P2 left behind. Start by getting a baseline of `ramp` (and tell the user the result).

## Files

All in `notes/method_research/`, committed as you go, so the user can read the fight:
- `ideas_claude.md`, `ideas_gpt.md`: the 7 each.
- `audit_rN_claude.md`, `audit_rN_gpt.md`: each round's audits.
- `top4.md`: the 4, how they were chosen, what was merged or rejected and why.
- `trial_c1.md`, `trial_g1.md`, `trial_c2.md`, `trial_g2.md`: what was built, scores, the audit.
- `scoreboard.md`: the criteria and every score.
- `FINAL.md`: the agreed method, both auditors' signed reasons, what it can't do, how to use it
  on a new puzzle, a first draft of a new `notes/TESTING_METHOD.md` version, and lessons
  proposed for the skills library.

## Done means

1. One method both auditors signed, with numbers from the scoreboard, including the final exam.
2. It works on the ramp, in a local branch, and the user can run it.
3. A plain report to the user: what won, the scores, what it can't do, what lost and why,
   then A / B on what's next (adopting it; merging `g12`).
