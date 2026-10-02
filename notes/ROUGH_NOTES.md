# Rough notes: everything learned, as it happens

The user's ask (2026-10-02): note down everything learned or changed, small
or big, about the code, the problem solving or the game, the moment it
happens; one rough file just for this. Cleaned up at the end of the project
and made more general (beyond game dev). Newest at the bottom of each
section. `notes/LESSONS.md` keeps the sorted, checked lessons; this is the
raw stream.

## How to work (process)

- **Open-loop tests waste time** (the user, 2026-10-02). A test written as
  one long script, run blind, then judged from the log at the end: one early
  failure turns every later step red (the F3 sheet walk: Naresh never
  reached the jetty end, then 20 checks failed for that one reason and the
  walker stood on a roof for minutes). A human tester looks, acts, looks
  again, and corrects on the spot.
- **The plan agreed for testing from now on (2026-10-02):**
  1. a live control line into the running game (a command file the game
     reads every frame: one action at a time, the result and state and a
     screenshot back at once), so the walk is closed-loop: look, act, check,
     fix, go on;
  2. scripted runs stop at the first failed check (fail fast), keep the
     game open and leave it on the control line to look into it;
  3. a part walked live and working is then saved as its regression test.
  The test window stays behind the user's windows (the user likes that).
- **Prove the user's test sheet before handing it over** (2026-10-02): walk
  every step exactly as written, real keys and pad only, nothing set in
  code, no teleports the sheet doesn't ask for. The user found the F3
  binoculars missing after an F1 jump that my test had given in code
  (`q.has_binoculars = true`). A test that gives itself what a player
  doesn't have proves nothing.
- **Notes before the context fills** (the user, 2026-10-02): write
  everything worthwhile into the md files before a compaction; always.
- **Size the test to the change** (2026-10-01): a few-second throwaway
  check for a small change, not a rerun of a long test that happens to
  cover it. Long runs once, before the hand-over.
- **Time is the scarcest thing** (the user): more than tokens or machine
  time.
- **Two game instances at once are fine for logic, not for frame-rate
  checks:** the beach measured 108 fps beside another run, 143 alone.
- **Shell traps:** bash heredocs and sed mangle quotes, apostrophes and
  backslashes (`\n` in GDScript strings became real line breaks; a `'` in
  a Python string broke a patch). Write patch scripts with the file tool;
  use the edit tool for lines with backslash escapes.

## The test sheet (things a blind tester would hit)

- The F1 menu stays open after Enter: the sheet must say "then F1 (or Esc)
  to close it".
- An F1 jump to Bessi / return steps didn't give the binoculars (you'd have
  them from Last Fuel or the ridge lookout): jumps give them now
  (`DevMenu.BINOCULAR_STEPS`).
- The binoculars are **hold RMB / hold LT**; pad B is crouch (the user tried
  B).
- The flare gun's held prompt said "Throw": it says "Fire a flare" now.
- F3 walk (2026-10-02): from the beach, "Go and wait there" on the jetty's
  far end through the binoculars was accepted (82 m), but Naresh never got
  to the end of the jetty: to look into live (next).

## The game / code (found on the way)

- Shared poi names collide silently: the village's `shed_roof` overwrote the
  water works shed's (its Memory Fragment moved). Prefix new places' names.
- A state flag must also put the world in that state (the swing bridge
  "locked" from a load never moved its span).
- The van needs a safety net (it could be squeezed through the ground and
  fall for ever): back to where it last stood safely.
- Old greybox can hide traps (the estuary bridge's deck edge was a step).
- `global_transform` before the world is in the scene tree is wrong: use
  `transform` (the world sits at the origin).
- An invisible wall blocks eyes too: the world edge is on its own layer (64).
- Scripted drivers: S on a stopped van is reverse; hold with the handbrake.
- A new chapter's tests change what old tests start from: the runner puts
  the return away before older tests (`_undo_return`).
