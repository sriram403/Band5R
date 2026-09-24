# Code review, 2026-09-24 (cloud session)

A full read of every gameplay script (Boot, InputDevice, SaveGame, PlayerRig,
Camper, the items, Story, MapState, PaperMap, the HUD and journal, the audio,
Route, RoadNetwork, Landscape, DevMenu, GymBuilder). Each fixed bug was first
reproduced with a play-test check (red), then fixed (green), unless the check
needs a GPU, as noted. The headless suite passes: 185 checks, 0 failures; base
gym 10/10.

## Fixed in this branch

| # | Where | The bug | How it showed | Test |
|---|---|---|---|---|
| 1 | `Camper._update_visuals` | The steam's particle `amount` was set **every physics tick**. In Godot that resets every particle even when the value doesn't change (checked in the 4.7 source), so the steam from a boiling engine never got to rise: at best a flicker at the grille. | Weak or missing steam at the water works. | `waterworks`: the steam cloud must be > 1 m tall. Needs a renderer, so it runs on the PC only. |
| 2 | `Boot._on_joy_changed` | A controller that **disconnected** (flat battery, cable) was ignored: P2 was stuck with a dead pad and couldn't be switched to the keyboard. | P2 frozen until a restart. | `pad`: disconnecting pauses the game with a note, P2 falls back to the keyboard (solo view, TAB), resuming clears the note. Reconnecting a pad makes it P2 again (already tested). |
| 3 | `Camper` | **Headlights left on stayed lit on a flat battery** (their visibility was only set when switched). | Lights on with a dead battery and a dark nav. | `look`: the lights go out when the battery is flat and come back with charge. |
| 4 | `JournalPanel._process` | While the journal was open it **read and parsed all three save files every frame** (~400 file reads a second at 144 fps). | Possible stutter in the journal, worse with antivirus. | Covered by `save`. The slot lines are now read when the journal opens. |
| 5 | `SaveGame.nearest_place` | Save slots were named only after Milestone A places, and "near X" at any distance: a save at P2's house or the fishing village read "near Homestead" / "near Bessi". | Misleading save names. | `dev`: saving at the dock, P2's house, and far from everything reads "Mirror Lake", "P2's house", "on the road". |
| 6 | `PaperMap.remove_stamp` | The rubber's reach was 120 m at every zoom, so zoomed in it removed stamps far from the pencil. | Wrong stamp rubbed out. | `map`: zoomed in, a stamp 60 m away is left alone. |
| 7 | `PaperMap._relief` | The printed relief is a static that survives scene reloads, so after switching gym → world in the dev menu the map showed the **gym's** ground. | Wrong relief (dev menu only). | Keyed by the ground it was printed from. |
| 8 | `MapState.from_dict` | A save from before a road was re-laid restored a chunk list of the wrong length for it. | Half-drawn or wrong roads on an old save's map. | Guarded: a mismatched road starts undiscovered. |
| 9 | `CoolantJug` | Its weight didn't follow its litres after a load (no `_update_mass`, which `SaveGame` calls). | A half-empty jug carried like a full one after loading. | Small; same code path as the fuel can. |

Fixed earlier in the headless-tests PR: mouse look speed depended on the window
size (`relative` vs `screen_relative`).

## Not changed: worth deciding

1. **Saves are written in place.** A crash or power cut during the write loses
   that slot. Safer: write `slot_N.json.tmp`, then rename over the old file. Not
   done here because rename-over-existing needs a test on Windows.
2. **Title screen says "milestone A".** Update it with Milestone C.
3. **Footsteps:** anything that isn't the terrain sounds like wood (rocks, the
   water works yard, the future P2 house floors). A `surface` meta on bodies
   would fix it when the house is built.
4. **Standing up from a crouch has no headroom check.** Under something low you
   pop up through it. It will matter for the cardboard box, the P2 house and
   hiding (Milestones C/D).
5. **One audio listener** (a Godot limit): in split-screen, positional sounds are
   heard from P1's position only. Worth remembering for the creatures' "rising
   whine" cue: make it louder or non-positional so P2 also gets it.
6. **Procedural audio in GDScript** (`NoiseLoop`, the road roar) makes 22,050
   samples a second per active sound in script. Fine today; watch it when rain,
   storm and creature sounds arrive (a few at once is OK; ten is not).
7. **The story chain still ends at Milestone A's "end_a"**, which is expected
   until Milestone C rewrites the opening.
8. The dev menu's teleport puts players on the terrain height, under decks and
   roofs (the lookout deck, the coast tower). Fine for a dev tool.
