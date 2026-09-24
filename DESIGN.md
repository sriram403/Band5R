# Finding Naresh: design document (demo)

The single source of truth for what the demo is. Agreed with the user on 2026-09-24. `TODO.md` (local) tracks the build, `FUTURE.md`
holds everything after the demo.

## 1. Theme

Life always holds beauty and danger together, at every point on a gradient. Naresh is
not evil: he is a being that, wherever he is, skews the gradient towards danger. It is
still beautiful and fun around him, just much less so. The players are never told
this; they should feel it through the colour, weather, traffic, sound and events, and
realise it on the drive home, the moment before the final notification.

## 2. Story arc

| # | Beat | Mood / colour | What the players learn or do |
|---|------|---------------|------------------------------|
| 0 | Two homes. P1 gets the news on their phone: Naresh is gone. P1 texts P2; P2 is free. | Bright, normal life | Phone / texts |
| 1 | **Split tutorial (5-10 min).** P1 drives the van alone to P2's home. P2 prepares at home. | Bright | P1: driving, fuel, coolant, heat, tyres/puncture, battery, handbrake, parking. P2: fuel can and half coolant can ready, torch batteries, journal, paper map, stamps, navigation and guiding |
| 2 | Pick-up. Load P2's cans into the van. The trip to Bessi beach begins. | Bright, traffic on the road | Carrying and storing together |
| 3 | **The way out.** Landmark puzzles teach every co-op mechanic (tagging, guiding, binoculars, the paper map, hiding). Enemies are introduced here, once both are in the van. Road choices (a long route with story and resources vs a short one). | Bright, slowly greying | Everything except Naresh |
| 4 | Halfway: other traffic thins out and disappears. Nobody drives this way. | Greying | (felt, not told) |
| 5 | A watchtower near the coast: the beach is visible far away. Players stamp their guess on the map and head there. | Grey | Using the map to plan |
| 6 | **Bessi beach** (inspired by Besant Nagar / Elliot's Beach): empty at dusk, stall lights on, boats, casuarinas, the memorial. The photo clue; supernatural smoke; the **Five Roses** rise from the sand; Naresh is inside the fifth. | Grey dusk | Finding a spot from a photo |
| 7 | With Naresh: 1-2 fun puzzles that show what he can do and his random acts (good and bad). Then the weather turns and they must leave. | Darkening | Naresh commands |
| 8 | **The return**, by a different road (the old road is a violent storm that can throw the van; careful players can still get through). No guidance. Fewer puzzles, each using everything learnt; Naresh can solve them faster but chaotically. The creatures and the world can take Naresh: players learn, unprompted, to keep him between them. | Eerie, dark, clouds, rain | Protecting Naresh |
| 9 | Nearing Naresh's home: it brightens. Drop him off; his mother and sister thank them. Hidden reward: if every optional puzzle was done, they get a **tracker** to place on Naresh. | Brightening | |
| 10 | The drive home: full sun, birds, wind in the grass, the most beautiful the game gets. The players realise the contrast. Near their homes, a phone notification: **Naresh has left his house, heading to LiveStander** (part two). End. | Full vibrance | |

Pacing target: **something interesting every 2-3 minutes** of play (a new place, a
landmark, an environment puzzle, wildlife, an event). Play time is not capped at 30
minutes (up to ~3 hours is fine); pacing and fun matter, not length.

## 3. World

- **Bigger map**: about 4 x 4 km (the demo world today is 1.6 x 1.6 km).
- Homes: P1's home, P2's home, Naresh's home (mother and sister), all on the map.
- Roads look and behave like real roads, but navigating them is itself a puzzle:
  splits where one branch is a long loop back to the same road (with story beats or
  resources on it) and the other is the quick way; players should notice and remember.
- **Landmarks you can see from far away** so players orient themselves without a
  marker; light guides the eye to places worth going (Level Design Book, "wayfinding").
- Heights and depths: mountain roads (Ooty / Kodaikanal style), underground, ground
  level (FUTURE #16).
- NPC traffic on the early roads; it thins out and stops halfway to the beach.
- Puzzles live inside landmarks; the game never counts puzzles on screen. At most it
  hints "have you explored everything around here?".
- Gates are part of the world (a bridge stuck open, and so on), never invisible walls.

## 4. Mechanics

- Van: driving, fuel, heat, coolant, battery, tyres/puncture, handbrake, cargo, parking.
- On foot: carry/throw, torch (batteries), paper map + stamps, journal, phone.
- Co-op: tagging for your teammate, binoculars, guiding from a height.
- Hiding (see section 5).
- Naresh: finite commands (carry, store, refuel, hold, wait, follow...) plus random acts.
- Weather: rain, wind gusts, storms strong enough to throw the van.
- Hidden items: the flare gun, the tracker.

## 5. The creatures

- The same kind of being as Naresh. First met on the way out; far more active on the
  return.
- **They see and hear.** On foot you hide physically: behind cover, peeking out,
  crouching, or inside a carried cardboard box you shuffle in slowly (MGS-style).
- **Caught = separated**, not hurt: the caught player is left somewhere else and the
  two must find each other. No health, downed or revive system.
- Near the van they cause damage for as long as they are close: fuel leaks, the engine
  failing or burning, punctures. Hide the van under a camouflage tarp, engine and
  lights off, and peek until they leave.
- **Flare gun** (hidden, off the main path): one flare drives every creature nearby
  away for a while. No killing.
- They **follow Naresh**; that is a clue, a danger (they can take him) and a puzzle
  tool (send Naresh one way to lead them away).

## 6. How we build (professional process)

1. **Design first.** Each area gets a one-page plan before building: its beats, the
   mechanic it teaches, its puzzle chain (each step causes the next) and a beat chart
   with the travel time between interesting moments (target 2-3 min).
2. **Gyms (test maps).** Every mechanic is built and tuned first in its own small test
   map: flat ground, measuring grid, only that mechanic (the tagging gym, the storm
   gym, the stealth gym, the Naresh gym...). Metrics (vision range, gust strength,
   reach distances) are fixed there and written into this document. Launched with
   `--gym=<name>`; the automated play-test runs there too. This is standard studio
   practice ("gym" or "metrics playground" maps; every major studio greyboxes).
3. **Greybox in the world.** Only then is the mechanic placed in the real map, in
   simple block-out shapes, and the route is timed against the beat chart.
4. **Automated play-test** for every feature (runs behind your windows), then my own
   play-through, then the milestone gate: your test and approval, then push.
5. **Debug tools.** A developer menu (teleport to any place, set weather and time of
   day, spawn items / creatures / Naresh, skip beats) so any moment can be tested in
   seconds.
6. **Performance budget:** keep ~144 fps with both views while driving.
7. **Art at the end** (polish stage in `FUTURE.md`); layout, scale and sightlines are
   what must be right during greybox.

## 7. Decisions (2026-09-24)

- **Map:** about 4 x 4 km, terrain split into chunks.
- **Watchtower** at the very end, near the players' homes: every puzzle site of the
  journey is visible from its top.
- **Opening:** Naresh's mother sends the message. The current homestead becomes P1's
  home; P2's home and Naresh's home (mother and sister) are added.
- **Naresh taken:** only when he is sent somewhere alone or wanders off by himself.
  The creature leaves him somewhere nearby, within sight, but far enough that you need
  the van or a long walk to reach him. The creatures follow him around, which is both
  a clue and a puzzle tool.
- **Hiding:** no visible sight cones (glowing eyes and a rising suspicion sound
  instead); crouch, lean to peek; cardboard boxes lie around the world as carryable
  items.
