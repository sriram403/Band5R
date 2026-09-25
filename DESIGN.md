# Finding Naresh: design document (demo)

The single source of truth for what the demo is. Agreed with the user on 2026-09-24. `notes/TODO.md` tracks the build, `FUTURE.md`
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

- **Bigger map**: the 4 x 4 km greybox is built; later areas remain block-outs.
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
   play-through, then the milestone gate: your test and approval, then push. Three
   levels (agreed 2026-09-24), so a fix costs minutes, not a long drive:
   - **Quick** (default, after every change, ~3-4 min): every mechanic tested in
     its gym, plus a short smoke check of the real map using teleports.
   - **Road check** (seconds, no game window): `tools/gen/layout_check.py` measures
     grades, cuts and gaps whenever roads or hills change.
   - **Full** (~35 min): the quick run plus the long drives (the journey, every
     road timed), only when roads change and before each milestone hand-over.
5. **Debug tools.** A developer menu (teleport to any place, set weather and time of
   day, spawn items / creatures / Naresh, skip beats) so any moment can be tested in
   seconds.
6. **Performance budget:** keep ~144 fps with both views while driving.
7. **Art at the end** (polish stage in `FUTURE.md`); layout, scale and sightlines are
   what must be right during greybox.

### 6.1 Metrics fixed in gyms

| Mechanic | Metric | Value | Gym |
|---|---|---|---|
| Tagging | reach (naked eye) | 200 m | tagging |
| Tagging | life / fade | 20 s, last 3 s fading; one tag per player | tagging |
| Tagging | marker size | pin ~36 px, text ~17 px at 1080p, whatever the distance | tagging |
| Tagging | reach through binoculars | 400 m | binoculars |
| Binoculars | zoom | 4x (hold RMB / LT; look speed / 4); hands free, not the driver | binoculars |
| Binoculars | readable letters, full screen | height >= distance / 650 (0.15 m at 100 m, 0.3 m at 200 m, 0.6 m at 400 m) | binoculars |
| Naked eye | readable letters, full screen | height >= distance / 170 (0.6 m at 100 m) | binoculars |
| Split screen | text size | ~1.35x larger than full screen for the same read | binoculars |
| Creature | sight, day (stand / sprint / crouch) | 35 / 45 / 17.5 m, 110 deg, blocked by walls, rocks, crates, trunks, the van | stealth |
| Creature | hearing | crouch-walk 2, walk 8, sprint 18, landing 10, thrown item 15 m | stealth |
| Creature | from seen to taken | ~2.3 s standing in the open at 9 m; gives up 10 s after losing sight | stealth |
| Cardboard box | seen from | still 3 m, moving 6 m; a box moving in view within 35 m: it walks to 4.5 m and stares (curious only) | stealth |
| Peeking | head offset | up 0.72 m over low cover or 0.6 m out past its end; cover must be within 1.3 m; seen as if standing | stealth |
| Lure | thrown item | heard 15 m; makes it curious (one throw = one sound) and it walks to the spot | stealth |
| Puzzle rule | a code meant for binoculars only | letters between distance / 450 and distance / 250 (readable zoomed in split view, never by eye) | binoculars |

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

## 8. Decisions for the opening, Milestone C (2026-09-24)

- **Phone:** read-only. Raised with a key; shows the texts (Naresh's mother, the
  two players' messages). No typing or reply choices.
- **Puncture:** at a fixed spot on the lane, not random. Swapping the wheel is a
  new mechanic and gets its own gym first.
- **Traffic:** a few simple cars on the town road for now; the full traffic
  system comes in Milestone D.
- **P2's house:** a simple enterable house (two rooms) plus a shed: batteries in a
  drawer, the fuel drum in the shed, an upstairs window to watch for the van. The
  first enterable building (FUTURE #12).
- **Story start:** the message from Naresh's mother starts the story. The parents'
  letter at P1's home stays as a small optional extra.
- **Torch batteries:** start in the opening (P2 finds batteries for the torch); the
  torch runs down and needs them.
