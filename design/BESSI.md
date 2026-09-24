# Bessi beach and Naresh (Milestone E): design v1 (proposal)

One page, for approval. Follows the story arc (`DESIGN.md` section 2, beats 6-7),
the beat chart (24:00-31:00), `FUTURE.md` #13 (Besant Nagar / Elliot's Beach, the
Five Roses out of the smoke, "follow a clue") and `design/NARESH.md`.

## Goal

The **turning point** of the game. Arrive at an empty, beautiful beach at dusk; solve
the photo clue; the Five Roses rise out of supernatural smoke; find Naresh in the
fifth; find out (without being told) that there never was a friend; learn Naresh's
commands with two short, funny puzzles; then the storm arrives and you have to leave
**the other way**. Mood: grey dusk, calm and eerie, with warmth still in it (stall
lights, a radio playing somewhere).

## Where

Beach Road -> the Bessi loop -> the promenade (stalls, lamp posts, boats on the sand,
casuarinas, the memorial) -> the dune where the Five Roses rise (the existing plaza
at `ROSE_CENTRE`). The greybox already has the stalls, boats, casuarinas and the
memorial.

## Beat by beat

| Time | What happens | Which caused... |
|---|---|---|
| 24:00 | **Arrival.** Empty promenade, stall lights on, no people. A radio in one stall plays softly. The nav loses its signal (the dashboard flickers). | You're somewhere wrong. |
| 24:30 | [story] **The photo**: Naresh's last message to his mother, forwarded to both players: a photo of him on this beach, captioned "me and him at Bessi!". Only **one player** holds it (whoever reads the phone first). He is alone in the picture, standing to one side, as if leaving room for someone. | The photo clue. |
| 25:00 | [puzzle] **Where was it taken (W8)**: in the photo, the lighthouse sits exactly behind the memorial's spire, and a boat's mast lines up with a stall's roof. The photo-holder describes it; the other scans with binoculars and tags candidates; walk until both pairs line up. There's only one spot. | Standing on the spot... |
| 26:30 | [story] **The smoke.** Smoke rolls in off the sea, low and white (the same smoke as a creature taking someone). It pools on the dune. Five shapes rise out of it: **the Five Roses**, stone and red, in a ring (the existing plaza). | ...raises the roses. |
| 27:00 | [puzzle] **The five roses open in order**: each rose has a symbol from the journey carved at its base (a windmill, a water drop, a bridge, a wave, a star). Walk the roses in the order you travelled (windmill, water works, bridge, the coast, the star is "here"). A wrong order and the smoke rises and resets them (loud, harmless). Each right one opens like a flower. | The first four open; the fifth opens last... |
| 28:00 | **Naresh**, inside the fifth rose, sitting cross-legged, delighted to see them: "You came! He said you would." | |
| 28:30 | [story] **Evidence there was never a friend** (found, not told): one set of footprints in the sand leading to the rose; one sleeping bag inside, with a second rolled beside it, never unrolled, still with its shop tag; the camera on a tripod with a timer (that's how the photo was taken, alone); in his notebook, every "we" was first written as "I". | The players realise; Naresh never says it. |
| 29:00 | [teach] **The stall shutter (N1)**: the torch batteries you need for the dark road back are in a stall behind a heavy shutter. Command Naresh to **hold** it while you both crawl in. Random act, scripted this once: he lets go early and you're shut in (a knock, a laugh, he opens it). | Batteries for the tunnel later. |
| 30:00 | [teach] **Push the boat (N2)**: the fuel drum you need is on a boat grounded on the sand bar. Three have to push at once: two players and Naresh (**work it**). He pushes the wrong way at first until told. The boat floats, you wade out and roll the drum back. | Fuel for the coast road. |
| 31:00 | **The storm.** The sky over the way you came turns black: lightning, a wall of rain over the ghat. The Five Roses sink back into the sand. Naresh: "My friend says we should go north." North is the coast road. | The return (`design/RETURN.md`). |

## What is new to build

1. **The photo** as a held item on one player's screen (their phone, raised with
   P), and alignment checks: a spot where two pairs of landmarks line up
   (computed from their positions, with a 2 m tolerance).
2. **Smoke** (a particle volume that rolls and pools) and the **rising roses**
   (the existing monuments sink into the plaza at the start and rise with an
   animation and a rumble).
3. **The roses' order puzzle**: five symbols, an order check, a reset.
4. **Naresh** (`design/NARESH.md`), his gym first; and his seat on the van's bench.
5. The **stall shutter** (hold) and the **grounded boat** (three-person push).
6. **Storm start**: the weather over the ghat (the storm gym in
   `design/RETURN.md`), and the roses sinking.
7. Dusk lighting for the beach (the mood curve at ~0.4).

## Gyms first

- **Naresh gym** (see `design/NARESH.md`).
- **photo gym**: four tall markers; stand at the spot where two pairs line up, and
  fix the tolerance so it's findable but not accidental.
- The smoke and the roses are built in place (they're the place).

## Tests

- Quick: the photo spot triggers only within tolerance; the roses rise; the wrong
  order resets; the right order opens all five and Naresh appears; Naresh holds
  the shutter and pushes the boat on command; the storm starts and the roses sink.
- Full: from the Beach Road to the storm by auto-driver and scripted actions, timed
  against the beat chart (about 7 minutes).

## Questions for you

1. The roses' order puzzle (the journey's symbols in travel order): does that fit,
   or should the fifth rose open some other way?
2. The evidence scene: is the list above too much (it spells it out), or right?
3. Which player gets the photo: whoever looks at the phone first, or always P2
   (the navigator)?
