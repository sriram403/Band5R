# The way out (Milestone D): design v1 (proposal)

Merged for future reference in PR #3; this page remains a proposal for approval
before anything is built. Follows the story arc (`DESIGN.md`
section 2, beats 3-5), the beat chart (`design/BEAT_CHART.md`, 6:00-25:00) and the
creature rules (`design/CREATURES.md`). The puzzle ideas come from the catalogue in
`design/PUZZLES.md` (W1-W9), so the details here are the suggested picks.

## Goal

The way out **teaches every co-op mechanic, one landmark at a time**: tagging,
guiding from a height, binoculars, the paper map and stamps, hiding the van, hiding
on foot. Each puzzle's reward is what the next place needs. Mood: happy, busy roads,
clever puzzles, slowly greying towards the coast. Creatures appear only once both
players are in the van, first glimpsed, then close.

## Where

P2's home -> J1 Windmill -> Valley Road (long) **or** Ridge Track (short) -> J2 Last
Fuel -> Pump House Road -> water works (built) -> the lift bridge -> J3 -> Ghat
hairpins -> the pass -> Beach Road past the coast watchtower -> Bessi. About 19
minutes for a first pair, driving plus stops.

## Beat by beat (the chain)

| Time | Where | What happens | Which caused... |
|---|---|---|---|
| 6:30 | Lane north | Birds lift off the road ahead; oncoming cars (full traffic system). | |
| 7:30 | **J1 Windmill** | [story] An old text from Naresh arrives here ("stopped at the windmill, he says it's lucky"). [puzzle] **Windmill brake (W1)**: the blades are jammed by a snagged rope. One climbs the tower and **tags** the snagged blade (first use of tags; the tag appears on both screens). The other works the brake lever and releases it only when the tagged blade swings down to the platform, where the climber cuts the rope. | The blades turn and the miller's box opens: **the map of this side of the valley** (both sides of the route choice drawn in). Now the road choice is a real choice. |
| 8:30 | **Road choice** | **Valley (long, ~3 min)**: Mirror Lake dock (fragment, Naresh's bench with two carved initials, one scratched out), the barn (optional **maze W2**: guided from the loft; reward spare coolant + a crate). **Ridge (short, ~1.5 min)**: steeper, the engine runs hot; the lookout (**binocular relay W4**: first binoculars, found on the deck; the code for a supply box is only readable from up there); the wreck ("our" tent, one sleeping bag). | Both routes give one thing the other doesn't: valley = coolant, ridge = binoculars early. If you take the valley, the binoculars wait at Last Fuel instead. |
| 11:30 | **J2 Last Fuel** | [teach] Refuel from cans (the pumps are dead, as built). [mood] **The last other car turns back here** and flashes its lights at you. [story] Naresh's text: "we're almost there". Binoculars on the kiosk counter if you came by the valley. | The dead pumps set up the water works' power link: the kiosk has a note, "power's been off since the turbine stopped". |
| 12:30 | Pump House Road | [teach] The hose splits: overheating (as built). | You need coolant: the water works. |
| 13:30 | **Water works** | [puzzle] Valves + pump, with valve B's kick-back (implemented in PR #2). **Proposed new link**: when the blue tank fills, the old turbine by the intake starts turning, and lights come on along a power line that runs north to the bridge. | Power reaches the bridge's control hut. |
| 16:00 | **The lift bridge** (the gate) | [puzzle] **Lift bridge (W6)**: one works the levers in the control hut and sees the deck only in a **convex safety mirror** (the van-mirror tech). The other clears the jammed gear on the deck, guided by tags from the hut. Lowering needs the deck player to stand on the counterweight at the operator's "now!". It comes down. | The road east opens. |
| 18:00 | **Ghat hairpins** | [mood] Clouds, the first grey. [teach] **Rally co-driver (W7)**: fog on the hairpins; swing the nav to the passenger (N) and it shows **pace notes**; the driver sees only fog. Then **the first creature**, glimpsed between the trees on the second hairpin. On the pass it comes for the van: the fuel starts to leak. **Pull over, tarp, engine off, lights off, peek** until it goes. | You learn what creatures do to the van, and that hiding works. The leak stops when it leaves; the fuel lost is felt but small. |
| 21:00 | **Coast watchtower** | [place] First sight of the sea and Bessi far off. [teach] **Hiding on foot**: a creature patrols the tower's base. Behind cover, crouch, peek, the **cardboard box** from the stack by the door. Up top: **stamp the beach** on the paper map; the nav follows the stamp (as built). | You know where Bessi is and how to hide from what's around it. |
| 23:00 | Down to the coast | [life] Casuarina groves, wind, gulls. [mood] Greyer, dusk. | |
| 24:00 | **Bessi** | Continues in `design/BESSI.md` (Milestone E). | |

## Traffic and mood

- **Traffic** (full system; the opening only has a few town cars): cars and a
  lorry on the lane and to J1, fewer on each road after, none after J2. They keep
  left, slow behind the van, stop if it blocks the road, and bump (no damage yet,
  FUTURE #2). The count per road is data, so "thinning out" is a table, not code.
- **Mood curve**: one number from 1 (bright) to 0 (dark), set by the story beat,
  drives the sky tint, fog colour, sun energy, `Ambience.liveliness` (birds go
  quiet first) and traffic. Way out: 1.0 at P2's home -> 0.6 at the coast.

## What is new to build

1. **Tagging**: look + T / middle mouse (pad: RT on foot). A marker on both screens,
   in the world (not a map pin), fades after 20 s; one tag per player at a time.
   Tag an object and it gets a name ("lever", "rope").
2. **Binoculars**: an item you find (lookout or Last Fuel); hold right mouse / LT
   to zoom (4x). Tagging works while zoomed. Budget: no extra render (just the
   camera's FOV), so no fps cost.
3. **Windmill puzzle** (brake lever, snag, climbing, map reward).
4. **Lift bridge puzzle** (control hut, levers, safety mirror, gear, counterweight),
   and the power link from the water works (turbine, line lamps).
5. **Pace notes** on the swung nav (a list per road section; fog volume on the ghat).
6. **Creature v1** (`design/CREATURES.md`): the van attack (leak), sight and hearing
   on foot, the tarp, peeking, the cardboard box.
7. **Traffic system** (table-driven counts, keep-left driving, stop for the van).
8. **Mood curve** (one dial for sky, fog, sun, birds, traffic).
9. Optional puzzles: barn maze (W2), lookout binocular relay (W4).

## Gyms first (DESIGN.md section 6)

- **tagging gym**: targets at 10, 25, 50, 100 m; fix how far a tag can reach and
  how big it looks at each distance, in split screen.
- **binocular gym**: signs with text at known distances; fix the zoom and the
  smallest readable text size.
- **stealth gym** and **creature gym**: see `design/CREATURES.md`.
- **traffic gym**: a loop with junctions and the van parked in the way.
- The windmill and the bridge are built in the world directly (they are places),
  but their levers and gears are tested in the base gym first.

## Tests (the three levels)

- **Quick**: each gym's scenario (tag reaches, binocular zoom, a creature sees a
  standing player at its sight range but not a crouched one behind cover, the tarp
  stops the leak, cars stop for the van), plus world checks by teleport: the
  windmill gives the map section, the water works lights the bridge hut, the bridge
  lowers, the first creature appears on the ghat only once both are in the van.
- **Full, at hand-over**: J1 -> Bessi driven by the auto-driver on both routes,
  with scripted puzzle actions, timed against the beat chart.

## Questions for you

1. The binoculars: found on the ridge (short route) or at Last Fuel (both routes)?
   Proposal: both. The ridge gives them early, Last Fuel is the backstop.
2. Traffic: is a lorry that blocks the lane for a moment (you wait or overtake)
   fun or annoying?
3. The first creature attack on the ghat: scripted to always happen (a lesson), or
   only if you stop in its area? Proposal: always, once.
