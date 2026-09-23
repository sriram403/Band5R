p = 'README.md'
s = open(p, encoding='utf-8').read()

def rep(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b)

rep(r'''Godot 4.7 project. **Stage 1 of 2: look-and-feel prototype.** This build exists so you
can decide whether the controls, the driving and the art direction feel right before
the full 30-minute demo from `Finding_Naresh_Game_Demo_Build_Prompt.md` gets built on
top of it.''', r'''Godot 4.7 project: a two-player co-op road-trip demo, built from
`Finding_Naresh_Game_Demo_Build_Prompt.md`. **Current build: milestone A** - story beats
1-3, from the homestead through the road trip to the water works and the broken bridge
(about 10-15 minutes). Later milestones add the crossing, Bessi, Naresh and the ending.''')

rep(r'''Double-click **`Play.bat`**. First launch takes about a second while the world is
generated. Press **Enter** (or **Start** on a controller) at the title card.''', r'''Double-click **`Play.bat`**. The world takes about a second to generate. The title menu
offers **New game / Load game / Quit** (W/S or arrows + Enter; D-pad + A on a pad).''')

rep(r'''| Flashlight | F | Y |
| Right a tipped-over van | R | View |''', r'''| Flashlight | F | Y |
| Throw what you carry | Left mouse (or G) | RB |
| Paper map | M | D-pad Down |
| Hint for the objective (hold) | H | R3 |
| Right a tipped-over van | R | View |

Carrying: **E** picks up a loose item (fuel cans, crates, the coolant jug) and **E** drops
it. Looking at something that takes it (the van's fuel filler, the rear rack, the
radiator) turns **E** into that action - hold it to pour.

Paper map (while it is up): mouse / right stick moves the pencil, **Q / E** (LB / RB)
choose a stamp, **left click** (A) places it, **right click** (X) rubs it out.''')

rep(r'''| Swap seats (stopped) | C | LB |
| Get out (stopped) | E | X |''', r'''| Swap seats (stopped) | C | LB |
| Get out (stopped) | E | X |
| Travel journal (parked) | J | D-pad Right |

**Saving:** there are no automatic saves. Memory Fragments (glowing pink petals) combine
three at a time into a Memory Rose. In the parked van, open the travel journal and
write to one of three slots - it tells you the cost first and uses one rose. Load from
the title or pause menu. Saves live in `MPG/appdata/FindingNaresh/saves/`.''')

rep(r'''**ESC** pause (**Q** quits from pause).''', r'''**ESC** pause (resume / load / quit; quitting warns about unsaved progress).''')

a = s.index('## What to try')
b = s.index('## Feel pass')
walk = r'''## Milestone A walkthrough

1. **Homestead.** Read the letter on the crate by the porch. Take the red fuel can by
   the garage and stow it on the van's rear rack (the van starts low on fuel).
2. **The lane** runs up to the windmill. At the **windmill junction** choose: the
   scenic **Valley Road** (Mirror Lake with a dock, a faded billboard, a red barn) or
   the steep gravel **Ridge Track** (shorter, runs the engine hotter; a lookout tower
   you can climb, a wreck). Both reach **Last Fuel**.
3. **Last Fuel.** The pumps are dead; cans are stashed behind the kiosk - one is empty
   (it is light; the prompt says so). Refuel at the filler on the van's left side.
   Read the info board: it sketches the area onto your paper map.
4. **Pump House Road.** The coolant hose splits on the way: steam, climbing
   temperature, lost power. Push it too far and the engine cuts out until it cools.
5. **The water works** (co-op puzzle). One player works the red hand pump and keeps
   the pressure needle in the green; the other sets valves A and B in the yard so the
   line feeds the **blue** tank - follow the pipes to see which way each valve sends
   the water. Over-pumping pops the relief valve (just a short stall). The blue tank
   gives a coolant jug and a Memory Fragment; pour the jug into the radiator at the
   front of the van.
6. **Optional:** a fragment glints on the tool shed roof - build a crate staircase (one
   crate, then two stacked) to reach it. There are fragments on each route too (the
   dock end, the lookout deck), so a first Memory Rose is within reach.
7. **Clues:** the visitor log by the pump house door and the campsite toward the river.
8. **The old bridge** is out. That is the end of milestone A.

'''
s = s[:a] + walk + s[b:]
open(p, 'w', encoding='utf-8').write(s)
print("ok")
