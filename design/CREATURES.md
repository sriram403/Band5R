# The creatures: design v1 (proposal)

One page. **Approved by the user on 2026-09-25** (answers under "Decisions" at the end). Follows `DESIGN.md` sections 5 and 7 (hiding, caught =
separated, van damage, flare gun, they follow Naresh, no sight cones). Every number
below is a **starting value to fix in the creature gym**, then written back into
`DESIGN.md` (section 6: metrics are fixed in gyms).

## What they are

The same kind of being as Naresh, wearing the world instead of a person: tall,
thin, hard to see straight on, **two glowing eyes** that you learn to watch for. They
never hurt anyone. What they do is **take things away**: your fuel, your engine,
your partner (for a while), Naresh (if he is alone). On the way out you meet one or
two, slow and curious. On the return they are many, faster, and drawn to Naresh.

## What they notice

**Sight** (no cones drawn on screen; you read the eyes and the sound instead):

| You are... | Seen from up to (day / dusk / night) |
|---|---|
| Standing or walking | 35 / 25 / 15 m |
| Sprinting | 45 / 35 / 20 m |
| Crouched | half of the above |
| Crouched behind cover, or in the cardboard box standing still | not seen, unless it is within 3 m |
| In the box, moving slowly | not seen beyond 6 m |
| Torch on (night) | 40 m, whatever else you do |

Field of view about 110 degrees. Walls, the van, rocks and tree trunks block sight
(one ray to the head and one to the chest).

**Hearing** (a sound reaches it if it is within this distance, walls or not):

| Sound | Heard from |
|---|---|
| Crouch-walking | 2 m |
| Walking / sprinting | 8 / 18 m |
| Landing a jump, dropping a crate | 10 m |
| A thrown item landing | 15 m (so you can **throw things to lure them away**) |
| Car door, the tarp being pulled | 20 m |
| Engine idling / driving / revving | 40 / 60 / 90 m |
| The horn | 150 m |
| The relief-valve bang, a pump running | 30 m |

## Suspicion (how it decides)

Each creature has one suspicion value, 0 to 1. Seeing you raises it fast (to full in
about 1.5 s at 10 m, 4 s at the edge of sight); a sound raises it a step and turns
its head to the sound. It falls slowly when nothing is noticed.

| Suspicion | What it does | What you see and hear |
|---|---|---|
| 0 - 0.3 | **Wanders** its patch or patrol path | Eyes dim; a low hum nearby |
| 0.3 - 0.7 | **Curious**: stops, turns, walks to the last thing noticed | Eyes brighten; a rising whine (louder as it grows) |
| 0.7 - 1 | **Searching**: moves faster around that spot | Eyes bright; the whine sharpens |
| 1 | **Takes**: comes straight for you (7 m/s, a little slower than your sprint at 7.6) | A rush of air; the screen edge smokes |

It gives up a chase 10 s after losing sight of you and goes back to wandering. So you
can always escape by breaking line of sight and going quiet. That is the skill.

## Caught = separated

- If it reaches a player (within 1.5 m), that player is **taken**: a wisp of the
  same smoke the Five Roses rise from, the screen goes white, and they wake up
  somewhere else. **No health, no damage, no downed state.**
- Where you wake: a **drop point** 150-400 m away, chosen from a list placed by hand
  near landmarks. Never in water, never behind a gate you haven't opened, always
  within sight of a landmark you already know (so the map gets you back).
- Both players get a phone text ("where did you go??" / "I'm by the windmill, I
  think"). The partner can **honk the horn** (heard 150 m; but so do creatures) or
  flash the headlights.
- **Grace**: after being taken, you can't be taken again for 2 minutes.
- If **both** are taken, both wake up at the van, which has a new leak. Nobody is
  ever stuck.

## Near the van

- A creature that notices the van (engine sound, headlights, or seeing it move)
  comes to it and stays within 15 m. **While it stays** it does one thing at a
  time, telegraphed by a sound on the dash side it is on:
  1. a **fuel leak** (about 1 L a minute, a dripping sound);
  2. the **engine failing** (power down 40%, coughing), after 30 s;
  3. a **puncture** (the tyre system from the opening), after 60 s.
  Nothing is permanent: drive away and it all stops (the tyre stays flat).
- **The tarp** lives on the rear rack. Hold E at the rack (4 s) with the engine
  **off** and the lights **off**; the van becomes a lump under canvas. A tarped van
  is "not there" unless something bumps it. The creature loses interest in
  20-40 s.
- **Peeking**: crouched at the edge of cover (or at the tarp's edge, inside the
  van), hold right mouse / LT and your view slides out past the edge. You're
  more visible while peeking (as if standing).

## Hiding on foot

- **Cover**: anything that blocks sight (walls, the van, rocks, trunks, crates).
- **The cardboard box**: carryable items lying around the world near creature
  areas. Use (E) while holding it to put it over yourself; you move at crouch
  speed. Standing still in it you are a box. Comedy is allowed: a box that moves
  while watched raises suspicion faster ("that box moved").
- **Throwing** anything (a can, a crate lid) makes a noise where it lands and pulls
  a curious creature there.

## They follow Naresh (return trip)

- On the return, creatures within 120 m drift towards Naresh, slowly, even when he
  hides. That is a clue ("they're heading for him"), a danger and a tool (send him
  one way to pull them away, `design/NARESH.md`).
- They take Naresh **only** when he is alone (no player within 12 m), per
  `DESIGN.md` section 7.

## The flare gun

- Hidden off the main path in the old rail tunnel (`design/RETURN.md`), 3 flares.
  Fired (left mouse / RT while held), every creature within 80 m flees and stays
  away for 90 s. No killing, ever.

## Performance

- At most 4 active creatures; those beyond 300 m sleep. Sight rays at 10 Hz, not
  every frame. Hearing is a list of recent sounds checked by distance. The budget:
  under 0.5 ms per frame for all of them.

## Gyms first

- **stealth gym**: a grid with cover pieces (wall, rock, trunk, crate, the van, a
  box), a creature on a straight patrol, and markers at 5 m steps. Fix the
  sight and hearing numbers above until hiding feels fair.
- **creature gym**: the van parked, engine on and off, lights on and off; fix the
  leak and failure timings and the tarp's loss of interest.

## Tests

- A standing player at 30 m in daylight is seen; crouched behind a wall, not.
- A thrown can pulls a curious creature to where it lands.
- Caught = taken to a drop point that's on the list, in sight of a landmark, and
  not in water; the grace time works; both taken = both at the van.
- A creature near a running van starts a leak; the tarp with engine and lights off
  makes it lose interest; driving away stops the leak.
- The flare empties an 80 m circle.

## Questions for you

1. Being caught: is the white-smoke "taken" look right, or should it be darker?
2. Should the partner see where the taken player went (a faint smoke trail on the
   horizon for a few seconds), or is searching the point?
3. The comedy box ("that box moved"): in, or too silly for the mood?

## Decisions (user, 2026-09-25)

1. Taken look: **white smoke** (the Five Roses' smoke), screen to white.
2. The partner sees **a faint smoke trail for a few seconds**, roughly the way the
   taken player went; the map, texts and horn still do the regrouping.
3. The comedy cardboard box is **in**.
