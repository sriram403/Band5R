# The opening (Milestone C): design v1 (proposal)

One page, for approval before anything is built. Follows the story arc (`DESIGN.md`
section 2, beats 0-2), the beat chart (`design/BEAT_CHART.md`, 0:00-6:00) and the
opening decisions (`DESIGN.md` section 8).

## Goal

Two friends, two homes, 1.3 km apart. In 5-10 minutes each player learns their half
of the game **alone and at the same time**, then they meet, load up and set off.
Nothing is explained in a menu: every lesson is a small need the world creates
("this happened, which caused that").

- **P1 (the driver)** learns the van: start, handbrake, fuel, a puncture, parking.
- **P2 (the navigator)** learns hands and tools: torch and batteries, carrying and
  pouring, the paper map and stamps, the journal and the save rule.
- Mood: bright, normal life. Birds, a few cars in town, sunshine.

## Where

P1's home (the homestead, SW) -> Homestead Lane east through the town (Town Fuel,
a few cars) -> the puncture spot on the lane past town -> P2's house (steep drive).
About 1.4 km, ~1.5 min of pure driving; the stops make it ~5 min.

## Beat by beat

| Time | P1 (homestead, then the van) | P2 (at home) |
|---|---|---|
| 0:00 | **Phone** buzzes: Naresh's mother, "he's gone... please find him". P1's phone then shows P2's reply: "I'm free. Come get me, I'll get the gear ready." (read-only: the texts arrive by themselves) | Same texts, from P2's side. |
| 0:30 | Out to the van. The **dash**: fuel lamp on (the van is nearly dry: ~6 L). **Key -> handbrake off -> drive.** The parents' letter on the porch is an optional extra. | The house is dim. **Torch** (F) is dead. A text from P1: "torch batteries are in the kitchen drawer". Search the drawers (E): find **batteries**, the torch works. |
| 1:30 | **Town**: 3-4 cars drive the town road. Keep left, don't hit anyone (a bump dents your pride, not the story). | **The shed** at the back is dark: the torch is needed to see inside (cause: the batteries). The **fuel drum**: fill the red can (hold E, the can gets heavier). The **coolant jug** is half full: take it too. |
| 2:30 | **Town Fuel**: the fuel lamp is on and the pump is open. Take a can from the stand, **fill it at the pump** (hold E), **pour it into the filler** (hold E). Same pouring P2 just learnt. | Back inside: the **paper map** (M) on the table. A text from P1: "meet me at the windmill after, right?". P2 **stamps the windmill** (the first stamp; P1's map shows it too). The **journal** on the desk explains saving (a Memory Rose per save). |
| 3:30 | **Puncture** at a fixed spot on the lane (a spill of nails from roadworks, a warning sign P1 can notice too late). A bang, the van pulls to one side. **Swap the wheel**: spare off the rear rack, jack under the van, hold E on the nuts, wheel off, spare on. | **Upstairs window**: watch the lane for the van (it comes into view from here). A text from P1: "got a puncture, 2 min". |
| 5:00 | **P2's steep drive**: park on it. Without the handbrake the van rolls back down (it is steep on purpose). | Sees the van arrive. |
| 5:30 | **Together**: carry P2's full can and the coolant jug out and **stow them on the rack**. Both in the van: the shared objective line returns and the trip begins (Milestone A's chain continues: to the windmill). | |

## Cause and effect (the chain)

Mother's text -> P2 is free -> P1 must fetch P2 -> the van is nearly dry -> Town
Fuel -> the fuller van reaches the roadworks -> the puncture -> the spare wheel ->
late, P2 watches from the window. Meanwhile: dead torch -> batteries -> the dark
shed -> the fuel drum and the jug -> the cans P1 will need later (Last Fuel's pumps
are dead). The map stamp at the windmill sets up the route choice there.

## What is new to build

1. **Phone** (read-only): raise with a key (P / D-pad right), a list of texts;
   texts are sent by the story (and a few automatic ones, like "found the
   batteries", so each player knows how the other is doing).
2. **Per-player objectives** during the opening; one shared line again after the
   pick-up. Today the story has one shared objective.
3. **Split start**: P1 at the homestead, P2 inside P2's house, each with its own view.
4. **Torch batteries**: the torch drains while on (about 10 minutes per set);
   batteries are a carryable item; a dim flicker warns before it dies.
5. **Enterable P2 house**: two rooms (kitchen with drawers; upstairs room with the
   window, stairs), a shed with a door; drawers you can open (E).
6. **Filling a can** from the fuel drum and from the Town Fuel pump (hold E).
7. **Puncture and wheel swap**: a flat wheel pulls the van and slows it; the spare
   lives on the rear rack; the swap is a few hold-E steps (~30 s).
8. **Town cars**: 3-4 simple cars looping the town stretch of the lane, keeping
   left, slowing behind anything in front, stopping if the van blocks them.
9. **P2's steep drive** (about 20 %), and the nails and warning sign at the
   puncture spot.
10. The Milestone A start changes: the mother's message starts the story; the
    letter stays as an extra; the van starts nearly dry at the homestead.

## Gyms first (DESIGN.md section 6)

- **tyre gym**: puncture pull and speed loss, the wheel swap, handbrake on 20 %.
- **house gym**: the P2 house alone: doors, stairs, drawers, torch in the dark.
- **traffic gym**: the town cars on a loop with the van in their way.
- The phone and objectives are tested in the world (they are story, not physics).

## Tests (the three levels)

- **Quick**: each gym's own scenario (swap a wheel, drain and replace batteries,
  fill a can, cars stop for the van), plus world checks by teleport: texts arrive,
  both objective lines advance, the pick-up merges them.
- **Full, at hand-over**: the whole opening played by the auto-driver and scripted
  P2 actions, timed against the 5-10 minute target.

## Questions for you

1. The phone key: **P** on the keyboard and **D-pad right** on the pad. OK?
2. Does P1 get to see P2's view at all during the opening (split screen as now),
   or should P1's half show only P1 until the pick-up? (Split screen as now is my
   suggestion: you see each other's progress.)
3. Town cars: can the van damage them or be damaged (FUTURE #2), or just bump for
   now? (Just bump for now is my suggestion.)
