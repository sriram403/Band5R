---
name: game-dev
description: How the user wants games built with an AI, any engine (Godot, Three.js/web, others) - design first and propose before building, the door problem (sweep every game-dev role a part touches and ask the user one batched list of questions with a recommendation each before building it), realistic and readable worlds that look lived in, built for humans (check everything from where a player stands), puzzles that keep players on their toes, gyms per mechanic, a core loop and colour bible first, one job per fresh AI session ending in a test, tuning panels with sliders, an automated play-test bot with hooks, dev-menu jumps that set the world up, one milestone at a time with the user's test before each push, and engine gotchas. Use when the user asks to make a game, mini game, level, puzzle, mechanic or prototype, or to play-test or polish one.
---

# Game development with the user

**Version: v4 (2026-11-09).** Generalized from a two-player co-op road-trip game in
Godot 4 (~3 weeks) and a car-park puzzle in Three.js (one day). v2: proposals lead
with the hardest idea, then tone down (§1.2, the user's rule). v3: core loop and colour bible
first, one job per fresh session ending in a test, tuning panels, reusable techniques (§5). v4: the door problem, a role sweep with
questions and picks before building any part (§1.2, the user's rule).

**You may ask the user questions at any point**, and early: what kind of game, who plays it (solo?
two on one keyboard?), which engine, what it should feel like, what "done" is for this version. Ask in
one batch with a recommended answer each (A / B reads best). If you're sure, go ahead.

Also load when relevant: [`testing-and-verification`](../testing-and-verification/SKILL.md) (how to
prove it), [`project-memory`](../project-memory/SKILL.md) (notes for a multi-session game),
[`first-principles-solving`](../first-principles-solving/SKILL.md) (when a process is slow or loops).
Engine notes: [Godot 4](references/godot.md) · [Three.js / web](references/web-threejs.md). Unreal and VFX: [`unreal-vfx`](../unreal-vfx/SKILL.md).

## 1. How the work runs

0. **A game loop before anything pretty.** Pretty prototypes that never get finished all lack the
   same thing: a cycle the player repeats (go out, gather, survive, come back...). Write the loop in
   one line before the first scene; if you can't, it's a scene, not a game yet.
1. **Design first.** A short `DESIGN.md`: the idea, the one thing that's deliberately unrealistic
   and why (e.g. passengers wear their car's colour: it *is* the puzzle and reads at a glance),
   what behaves for real, how a level is built, the level list, ideas not built yet.
2. **Propose before building** anything loosely described ("a room", "water", "a key"): design it as
   the thing that belongs to that game and place (the water works' own pump house, not a generic box),
   write a short proposal with numbers, add your own ideas marked S1, S2, ... (yes / no each), wait
   for the answers, then build. "Let's discuss" means discuss, not build.
   **Lead with the hardest, craziest version** (the 10 / 10) and what it costs in play time; the user
   tones it down (easier than pushing a safe idea up). Plain words, no engineering names ("a barrier
   pole", not "a boom"), and the answer in the message itself, never only behind a question box.
   **The door problem: sweep the roles first** (the user, 2026-11-09). Even a plain door is ~20 design
   questions and ~35 roles (designer, level, art, animation, audio, lighting, UI, AI, network, QA...),
   and an AI building alone silently answers all of them. Before building a new part, go through
   every role it touches, turn each open choice into a numbered question **with your pick and a
   few-word reason**, grouped by role, and open with the count ("🚪 Doors: 9 roles → 12 questions").
   The user decides every category; "recs" takes all your picks. Skip marketing-type roles by
   default. Decided once = decided for every one like it: write answers into `DESIGN.md` /
   `DECISIONS.md` and never ask again. Role list, depth table and message format:
   [references/door-problem.md](references/door-problem.md).
3. **One part at a time, the user's test decides.** Build a part, test it yourself until clean, hand
   over with a plain test guide (do / expect / tell me), wait for their OK before pushing or moving on.
   Bug fixes with passing tests can go out at once if the user agrees to that rule.
4. **Gyms first:** a small test map per mechanic makes the numbers (sight ranges, text sizes, jump
   heights) measurable before they go into the world. A gym starts you beside what you came to test,
   facing it.
5. **Greybox, then art.** Placeholders (boxes for buildings, vehicles, trees, the player) go in
   first, so mechanics are played before any art exists; then swap them one by one. Agree the look of
   every new asset with the user before it's populated into the world.
   **A colour bible first:** take a reference image for its *feeling* (not to copy) and write its
   rules down as numbers: a fixed palette (~12 colours, every model and texture builds from these),
   how bright the main surface sits, and **where warm colours are allowed** (often exactly one warm
   patch per frame: the focal point). If the game's time or mood differs from the reference,
   translate each colour and keep the rules. Nothing enters the game without being mapped to it
   (bought or generated assets get recoloured). Free/CC0 assets, credited in `CREDITS.md`; source zips kept out of git.
6. **Plan once, then one job per fresh session.** Never ask for the whole game in one prompt. The
   strongest model writes `PLAN.md`: a hub listing every system as a job, **one system = one file**
   (walking → a player script, camera → a camera script, weather, each enemy, each its own), ticked
   off when done. Each job runs in a clean session that reads only the brief (the rules: colour
   bible, style, conventions) plus that job, never the history of the other jobs. In one measured
   case a long chat read ~3x the tokens of fresh chats for the same work, and more reading means
   more mistakes *(AI limit, Opus 5.5 / GPT Sol 6.1, 2026-11: re-test on newer models)*. **Every job ends in a test**; a failing job goes back, not the game. Build a system
   in layers, each its own job (flat ground → height → a surface on it → the surface changes
   movement → marks the player leaves). Different models can take different roles (planner for the
   hard calls, mechanics coder, art/Blender scripter with good taste); give each the role it's best at
   *(AI limit, Opus 5.5 / GPT Sol 6.1, 2026-11: re-test on newer models)*.
7. **Tuning panels for look and feel:** for anything tuned by eye (lighting, fog, weather, speeds),
   ask the AI for an in-game panel with sliders, so the user experiments live instead of asking for
   edits (most useful where the engine has no live editor for it). Group sliders by **job**, not by
   engine node: key light (strength, time of day), shadow colour (ambient), warm accent (the one lamp
   or window), air (fog density, glow), shading (toon bands ↔ realistic). Add **presets on hotkeys,
   each named for the game moment it serves** ("nightfall: go home", "storm: can't see", "dawn: a few
   safe minutes", "flat: correct but dead" as the baseline), so lighting carries game state, not
   just mood.
8. **Keep a polish list** (`POLISH.md`) for things agreed "for later"; remind the user at the end.
9. **Look at it as a player before showing it** (see 3). Then report: what you couldn't test, what's
   done, what's next. Plain language, no code talk.

## 2. Design principles the user cares about

- **Realistic, and simple to read.** Everything works as it would for real (weather, machines,
  tools: binoculars about 8x, not 12x; a wrong code makes the box itself reset). Nothing appears out
  of nowhere. Keep one unrealistic rule only where it *is* the game, on purpose, and say why.
- **Lived in, never programmatic.** Built things look placed by a person (a mug on the bench, posts
  not quite in line); natural things sit as nature would leave them (clumps, half-sunk rocks, never
  rows or grids). If a space is cramped, make the space bigger.
- **Built for humans, who get irritated by silly mistakes.** Every placed thing visible, reachable,
  its text readable, nothing floating or sunk, blockers that really block (try to get round them).
  Every action shows visibly that it worked.
- **Keep players on their toes.** Each needs what the other knows (co-op); every mistake has a quick,
  visible, often funny consequence; give both players a job all the time; never force both onto one
  task when one could do it.
- **Never repeat a puzzle** (how it plays or what it's for). When the user's ask repeats an earlier
  one, say so and suggest a way round. A challenge can stand in for a puzzle.
- **Fun mechanics are their own reward** (a head-butt usable on everything); connect the pieces (use
  what the players brought rather than a reward that pops out of nowhere).
- **Give time to react** (a threat appears ~100 m ahead and approaches, not 20 m). **Danger warns
  first, then strikes** (a threat the player can't outrun gives a warning sound or pose, then attacks).
- **Few enemies, each one deadly** beats many weak ones. Give them **different senses** (one hunts
  by sight, another by smell or sound carried on the wind) so the player reads and plays each one
  differently.
- **The world reacts to the player and pushes back:** small details that answer what you do (marks
  you leave, with depth that follows the ground) make it feel alive; ground that changes movement
  (deep = walk, shallow = run) turns scenery into a mechanic.
- **Readable at the real screen size** (split-screen halves the pixels; size text for 800 px views).
  **Shapes must be unmistakable** (a 3-sided cylinder read as a diamond). Read order matches what the
  player sees (left to right from the front).
- **Distances along the route, not as the crow flies** (hairpins fold back; triggers fire early).
- **Design for how the user actually plays** (one person testing two players on one keyboard is a
  real mode; hiding something from "the driver" hid it from the only view there was).
- **Sightlines need clearing** by design; hiding the player from view must not block their own view.
- **Instructions in the world's voice** (a character's notes, signs) where it fits; plain narration
  only for what you see and feel. Messages short; questions as A / B.

## 3. Testing a game

General method: [`testing-and-verification`](../testing-and-verification/SKILL.md). Game-specific:
- **An automated play-test** from day one: scenarios that drive the real game with real inputs, plus
  a debug hook in the page/game (`window.game.sim(level)`, `hint()`, a probe that runs any
  expression and saves a screenshot). Headless where possible, but look at real renders.
- **A level checker:** seeded levels (same every time); a built-in solver must finish every level, or
  the generator backs off. Every level is solvable.
- **A dev menu** with jumps that **put you there and set the world up** (players, NPCs, vehicle,
  story flags), plus a per-puzzle reset so the user can replay what they test.
- **Walk, don't teleport, where layout matters** (a teleport test passed while P2 couldn't leave the
  house). Stand where a person would stand; hold inputs as long as a human would (a press shorter
  than one physics tick never registers).
- **Reactions come a step later:** wait a few frames before checking what someone said or did, and
  don't stop watching the moment something starts.
- **Close-ups of every new thing** and shots from the player's own height; lights in a dark shot
  (headlights shone backwards for weeks unnoticed in daylight).
- **The end-to-end run finds what part tests can't** (an open bridge span, a story gap): keep one
  whole-journey run per milestone.
- **A state flag must also put the world in that state** (a bridge "locked" by a load never moved).
- **A new feature changes what old tests start from:** grep the old tests for what they assume about
  anything the feature changes (a new gate blocks every walk that passes it).
- **Log what characters say** and every state change; it makes failures readable at once.
- **Hidden windows get no frames:** browsers (and some engines) stop drawing a minimised or covered
  window. If the world must keep going, step it by the wall clock. Test that with a real minimised
  window (headless never hides).
- **Real hardware changes tests:** a plugged-in controller moves P2 onto it. Log the setup first.
- **Measure performance:** every extra camera (mirrors, scopes) is a whole extra render; budget it.

## 4. Habits from mistakes (general to any game)

- Game events run on the **game's clock**, never `setTimeout` / wall-clock timers (fast tests run
  game time without real time).
- **One owner per state:** only the game sets a character's state; an object setting its own wiped
  the game's.
- **"In front of me" is not "on my road":** look-ahead follows the route (turns included) and checks
  real outlines; cone checks deadlock.
- **Shared names collide silently:** prefix names per place; grep before taking one.
- **Story steps by id, never by index.**
- **A tuning hack for one feel breaks another** (a low centre of mass that stops flips also makes a
  storm-tipped van roll back up like a toy).
- **Measure what the player ends with, not a peak** (tipped = where it comes to rest).
- **Make the limiting factor the thing you tune** (lower tyre grip did nothing: the brakes limited).
- **Thrust/vehicle layouts must push through the centre of mass**, and re-checked after every mass
  change (removing a backpack battery moved the CoM and a "working" layout crashed). Give a controller's
  optimiser the actuator's *reachable* range this instant (slow engines), not its rated range.
- **Before blaming the physics for a failed manoeuvre, check your own controller against the formula**
  (a "thrust-limited" turn was a fixed circle direction + a lean cap equal to the needed lean + lag).
- **A tool that fails quietly costs hours:** wrappers throw on failure (a geometry merge returning
  null stopped the game from starting).

## 5. Techniques worth reusing

- **Changing terrain: only a window around the player.** Height that changes during play (things
  press it down, weather piles it up) is computed every frame, nothing saved to disk, but only for a
  patch (~120 m on a ~700 m map) that slides with the player, never the whole map.
- **Trails as a fixed-size image, not a list.** Paint each mark (footprint, tyre track) into a
  texture around the player (e.g. 1080 px for 90 m). "Was something here?" is one pixel read instead
  of a search through every stored step, and a thousand marks cost the same as one. Many systems
  share it: the ground reads it for depth, weather fades it, an enemy follows it.
- **AI-made props: a script, one named piece per line, simple shapes.** Each line builds one named
  part (`walls_east`, `chimney`; ~50 parts for a house) and the preview renders as each part
  appears, so a wrong part is found by name, fixed in its one line and re-run; never hand-edit the
  mesh. AI does simple low-poly shapes well and realistic meshes badly: boxes + a roof + the
  lighting do the work *(AI limit, Opus 5.5 / GPT Sol 6.1, 2026-11: re-test on newer models)*. Method: [`3d-modelling`](../3d-modelling/SKILL.md).
- **Characters: turnaround concept → image-to-3D → texture → recolour to the colour bible.** Ask an
  image model for front / side / back in a T-pose on a plain background, and design out what AI does
  badly (a hood or mask hiding the face) *(AI limit, Opus 5.5 / GPT Sol 6.1, 2026-11: re-test on newer models)*. Feed the views to an image-to-3D tool; ~8k triangles is
  fine for a main character, and its auto-rig and animations can save days.
- **Downloaded models: match the style, credit them.** A realistic CC-BY model (e.g. an animated
  animal) gets decimated in Blender to the game's low-poly look. Make three stages side by side
  (e.g. ~7.5k → ~3k → ~800 triangles) and pick by eye: the middle one usually keeps the silhouette.
  Attribution in `CREDITS.md`.
- **Interiors in the same place, not a new level:** crossing the door threshold fades out a fixed
  list of parts (roof, the wall facing the camera) over ~0.3 s, so the player still sees the danger
  outside. A fixed list, no ray, because the cut is always the same.
- **Nothing hides the player outdoors:** cast a ray from the camera to the player every frame and
  fade out whatever it hits (a tree, a wall) as a whole shape.
