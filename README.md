# Finding Naresh: Bessi and the 5 Roses

Godot 4.7 project: a two-player co-op road-trip demo, built from
`Finding_Naresh_Game_Demo_Build_Prompt.md`. **Current build: milestone A** - story beats
1-3, from the homestead through the road trip to the water works and the broken bridge
(about 10-15 minutes). Later milestones add the crossing, Bessi, Naresh and the ending.

Everything lives inside this folder. Nothing is installed to `C:`.

```
MPG/
  Play.bat            double-click to play
  OpenEditor.bat      open the project in the Godot editor
  FindingNaresh/      the Godot project
    scripts/          all gameplay code (GDScript)
    scenes/Main.tscn  entry point (a single node running Boot.gd)
    scripts/dev/      PlayTest.gd, the automated play-test
    _shots/           screenshots from the capture and play-test modes
  appdata/            user:// (settings, logs, shader cache, future saves) - created on demand
  tools/godot/        portable Godot 4.7.1, self-contained
  tools/run_game.sh   run from a shell with the same data redirect as Play.bat
```

Godot normally writes editor config and `user://` data into `%APPDATA%` on C:. Editor data
is redirected by the `._sc_` marker next to the executable (`tools/godot/editor_data/`).
`user://` is always rooted at `%APPDATA%`, so `Play.bat` and `OpenEditor.bat` set `APPDATA`
and `LOCALAPPDATA` to `MPG\appdata` for the game process. That also catches the graphics
driver's shader cache. **Launch through the .bat files**; starting the exe directly puts
user data back on C: (the game prints a warning in the console if it detects that).
Moving the MPG folder needs no changes.

## Setup after cloning

The Godot binaries are not in the repository (the editor is 171 MB, over GitHub's
file limit). Download **Godot 4.7.1 stable, Windows 64-bit, standard (not .NET)** from
<https://godotengine.org/download/archive/4.7.1-stable/>. Put both
`Godot_v4.7.1-stable_win64.exe` and `Godot_v4.7.1-stable_win64_console.exe` into
`tools/godot/`, next to the existing `._sc_` marker. Then use `Play.bat` as below.
The first launch rebuilds Godot's import cache, which takes a few extra seconds.

See `FUTURE.md` for ideas planned after the demo.

## Running it

Double-click **`Play.bat`**. The world takes about a second to generate. The title menu
offers **New game / Load game / Quit** (W/S or arrows + Enter; D-pad + A on a pad).

There is no export/`.exe` build yet; that comes with the finished demo.

## Controls

Player 1 is keyboard + mouse. Player 2 is the first connected controller.

**No controller?** You get a **solo view**: one player full screen. **TAB** jumps the
keyboard, mouse and screen to the other player, so one person can try both roles.
**F2** cycles solo / side-by-side / stacked. Plug a pad in at any time: it becomes
Player 2 and the game switches to split-screen on its own.

| | Keyboard + mouse | Controller |
|---|---|---|
| Move | WASD | Left stick |
| Look | Mouse | Right stick |
| Sprint | Shift | L3 |
| Crouch | Ctrl | B |
| Jump | Space | A |
| Interact / get out | **E** | **X** |
| Flashlight | F | Y |
| Throw what you carry | Left mouse (or G) | RB |
| Paper map | M | D-pad Down |
| Hint for the objective (hold) | H | R3 |
| Right a tipped-over van | R | View |

Carrying: **E** picks up a loose item (fuel cans, crates, the coolant jug) and **E** drops
it. Looking at something that takes it (the van's fuel filler, the rear rack, the
radiator) turns **E** into that action - hold it to pour.

Paper map (while it is up): mouse / right stick moves the pencil, **Q / E** (LB / RB)
choose a stamp, **left click** (A) places it, **right click** (X) rubs it out, **mouse
wheel or + / -** (Y / B) zooms. The van's dashboard nav points at your most recent
stamp - it never points at Bessi for you.

Driving (once you are in the driver's seat):

| | Keyboard | Controller |
|---|---|---|
| Throttle | W | RT |
| Brake / reverse | S | LT |
| Steer | A / D | Left stick |
| Handbrake on / off (driver or passenger) | Space | B |
| Ignition | **X** | D-pad Up |
| Headlights | L | D-pad Left |
| Swap seats (stopped) | C | LB |
| Get out (stopped) | E | X |
| Travel journal (parked) | J | D-pad Right |

The handbrake is the only thing that holds the van: the red **P** lamp on the dash shows
it is on. Leave it off and the van rolls on any slope, with or without anyone in it.
Pulling away with the engine running lets it off. With the engine off, S is the brake
pedal (it stops a van rolling back after a stall).

**Saving:** there are no automatic saves. Memory Fragments (glowing pink petals) combine
three at a time into a Memory Rose. In the parked van, open the travel journal and
write to one of three slots - it tells you the cost first and uses one rose. Load from
the title or pause menu. Saves live in `MPG/appdata/FindingNaresh/saves/`.

You can only get out, or swap seats, once the van has (nearly) stopped. The prompt
under the crosshair always shows what you can do right now; while driving it stays
empty so the road is clear. The control reminder at the top fades after ~14 s.

Other keys: **[ / ]** mouse sensitivity (saved) · **TAB** switch player (solo) ·
**F2** layout · **F11** fullscreen · **F3** teleport both players to the camper ·
**ESC** pause (resume / load / quit; quitting warns about unsaved progress).

## Milestone A walkthrough

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

## Van condition

- **Fuel** gauge + HUD bar. Idling burns fuel too (~0.9 L a minute) - switch off when
  you stop. Cargo on the rack raises consumption.
- **Temperature** rises on long climbs and while idling (no airflow).
- **Coolant** (HUD bar): a split hose drains it and the engine heats faster the lower
  it gets; past 122 C the engine cuts out and will not restart until it cools.
- With the engine off, or nobody at the wheel, the parking brake holds the van.

## Feel pass (2026-09-23)

The first build felt bad to play. An automated play-test (`scripts/dev/PlayTest.gd`)
drove it through the real input path, measured each problem, and was re-run after
every fix. What it found and what changed:

| Problem | Fix |
|---|---|
| ~40% of quick key taps (E, X, F, C) were lost on the 144 Hz monitor; below 60 fps they would fire twice | Input is polled once per physics tick, and taps are latched from input events so none are dropped |
| View and movement updated only 60 times a second on a 144 Hz screen (judder) | Physics interpolation on; mouse look and camera run every rendered frame |
| Solo testing showed half a screen of an idle player | Solo full-screen view by default with no controller; TAB / F2 |
| Driver's view mostly dashboard: a dark plank across the windscreen, huge dials | Cab rebuilt: dash below the sightline, small readable cluster, slight downward default look |
| Nav screen text was buried inside its own box | Centre-console screen facing the passenger, readable, shows distance and direction to Bessi |
| E threw you out of a van doing 45 km/h | Doors only open below ~9 km/h |
| Engine hit 114 °C on one normal lap (warning at 104) | Temperature model retuned: ~88 °C cruising, only long climbs overheat; uphill/downhill were also swapped |
| Parked van crept downhill | Parking brake with engine off, auto-hold when idling, locked in place once stopped |
| Walked through rocks, far trees and the rose monuments; walking into the Five Roses plaza put you inside it | Colliders on all of those; the plaza now sits flush on a flat plateau |
| A flipped van could never be recovered | R / View rights it |
| "Sit in the driver's seat" shown for a taken seat, button did nothing | Says who is in it instead |
| No sensitivity setting | [ / ] in game, shown in the pause menu, saved |
| Big shadows read as blue water; glare spot on the windscreen; control hints overlapped gauges | Softer ambient tint, matte glass, prompts moved |
| Engine audio could run dry on a frame hitch | Larger audio buffer; 0 underruns in 12 s of driving |
| `user://` data (13 MB) was being written to C: despite the project setting | See the folder notes above |

Run the play-test yourself (takes 15-20 minutes for everything):

```
tools/run_test.sh                  (everything)
tools/run_test.sh drive,map        (some scenarios)
SHOW=1 tools/run_test.sh drive     (on screen, with sound, to watch it)
```

By default the window starts at the screen edge, then goes **behind** your other
windows and hands focus back to whatever you were using (about 3 seconds). It is
muted and never grabs the mouse. Click it or its taskbar button to watch (sound comes
on while it has focus); click anything else and it goes back behind. Keys you press
while it has focus reach the game and can fail a check; that scenario is just re-run. It prints `PASS`/`FAIL`
lines and writes `_shots/test_*.png`; the scenario list is `all` in
`scripts/dev/PlayTest.gd`.

## What is in this build

- **Split-screen co-op**: two independent views and HUDs, per-player input isolation
  (keyboard + mouse and a controller never cross over), solo view with TAB for testing.
- **First person**: walk, sprint, crouch, jump, flashlight, contextual prompts with the
  right glyph per device, surface-aware footsteps.
- **Carrying**: physical items with weight (cans, crates, jugs), drop, throw, nudge;
  use-with (pour, stow) and a safety net so physics can never lose an item.
- **The camper**: raycast-wheel driving, seats, dashboard dials and lamps, fuel,
  temperature, coolant, battery, parking brake, rear storage rack, fuel filler,
  radiator, a nav screen that follows your map stamps, right-it-up recovery.
- **The journey map**: 1.6 x 1.6 km valley with a road network (lane, route choice,
  valley road, gravel ridge track, pump house road, Bessi loop), river, lakes, bridge,
  meadows and woods, and the landmark set in the walkthrough. Built in about 1 s.
- **Paper map**: discovery by travel and info boards, shared stamps, zoom, no
  position marker.
- **Story**: parents' letter, objective line with hints, old texts from Naresh, clues.
- **Water works**: the hose breakdown and the cooling-station co-op puzzle.
- **Memory Fragments, Memory Roses and the travel journal** (three manual save slots),
  title and pause menus, unsaved-progress warning.
- **Sound**: CC0 effects plus procedural engine, pour, steam and wind.

## Not in this build yet

Milestones B-E: rain and wet traction, the tyre-pressure problem, the broken-crossing
puzzle and winch, health / downed / revive, the presence and hiding, the Five Roses
puzzle, Naresh and his fuel mistake, the ending, settings menu, a Windows `.exe`. Ideas
agreed for after the demo are in `FUTURE.md`.

## Architecture notes

`scenes/Main.tscn` is deliberately almost empty: one node running `Boot.gd`. The world
is assembled in code from data tables so it can be iterated on quickly and re-authored
into scene files later without changing the systems.

| File | Role |
|---|---|
| `scripts/core/Boot.gd` | Session root: builds the world, players and split-screen shell; device assignment, menus (title / pause / load), explore ticks for the map. |
| `scripts/core/InputDevice.gd` | One per player. Reads keyboard/mouse or a specific joypad; actions, latching of quick taps, prompt glyphs. |
| `scripts/core/SaveGame.gd` | Journal save slots: collect / apply the whole world state (JSON in `user://saves`). |
| `scripts/core/ToonMat.gd` | Every material in the game. Change the art direction here. |
| `scripts/core/Build.gd` | Primitive-mesh helpers and `interact_area()`. |
| `scripts/player/PlayerRig.gd` | First-person `CharacterBody3D`: movement, look, interaction, carrying, map, journal, seating. |
| `scripts/items/Carryable.gd` (+ `FuelCan`, `CoolantJug`, `Crate`, `MemoryFragment`) | Physical items and pickups. |
| `scripts/vehicle/Camper.gd` | Chassis, driving model, condition systems, dashboard, seats, filler, radiator, rack. Tuning constants at the top. |
| `scripts/vehicle/EngineAudio.gd` | Procedural engine / road noise. |
| `scripts/world/Route.gd`, `RoadNetwork.gd` | Road and river centrelines: splines, pinned junction heights, nearest queries, chaining. |
| `scripts/world/Landscape.gd` | Height layers, the grid-stamped terrain (mesh + height-map collision), roads, river, pads. |
| `scripts/world/LevelBuilder.gd` | The world's layout data and assembly: roads, water, scatter, landmarks, items. |
| `scripts/map/MapState.gd`, `PaperMap.gd` | Shared discovery + stamps; the drawn paper map. |
| `scripts/story/Story.gd` | Objectives, hints, story beats, fragments and roses. |
| `scripts/puzzles/CoolingStation.gd` | The water works co-op puzzle. |
| `scripts/audio/Sfx.gd`, `NoiseLoop.gd` | Sample one-shots by name; procedural pour / steam / wind. |
| `scripts/ui/PlayerHUD.gd`, `JournalPanel.gd` | Per-player HUD, notes, objective line; the travel journal. |
| `scripts/dev/PlayTest.gd` | Automated play-test: injects keys, mouse and a virtual gamepad, measures, screenshots. |

Extension points for the next stage: `Build.interact_area()` already gives any object a
prompt and a callback, so carryables, puzzle levers and the journal hook straight in;
`Camper`'s condition fields are plain state ready to be serialised by the save system;
`LevelBuilder`'s const tables are where new landmarks and puzzle sites go.

### Notable technical decisions

- **GodotPhysics3D is forced** in `project.godot` rather than the default, because
  `VehicleBody3D` is best supported there.
- **Terrain collision uses `backface_collision = true`.** `create_trimesh_shape()`
  produced a shape the ray and the wheels fell straight through otherwise.
- **Terrain normals are computed analytically** from the height field instead of from
  triangle winding, which produced flat, unlit ground.
- **Input is polled in `Boot._physics_process`**, not per rendered frame, because every
  consumer of `just_pressed()` runs in the physics step. `InputDevice.feed_event()` also
  latches presses from input events so a tap shorter than one tick still counts.
- **Physics interpolation is on.** The cameras are placed by `PlayerRig._process` from
  `get_global_transform_interpolated()`, so they set their own interpolation mode to off.
- **A stopped van is frozen** (`Camper._update_parked`), because raycast-wheel brakes
  still creep a few cm/s on a 14% grade. Any throttle or brake input unfreezes it.
- **Seated players are never reparented** into the camper. The body stays in the world
  with its collider disabled and is snapped onto the seat marker each physics tick.
  Reparenting a `CharacterBody3D` under a moving `VehicleBody3D` made GodotPhysics
  launch the van at ~19 000 km/h on exit.
- **Positive `engine_force` drives this rig toward +Z**, so drive forces are negated in
  `Camper._physics_process`; `steering` is likewise positive-left while the input is
  positive-right.

## Assets and licences

All art and geometry is generated at runtime from Godot primitives and code. Sound
effects are CC0 samples from Kenney; see `CREDITS.md` for every third-party asset.

## Dev capture mode

`Play.bat` with `-- --shot` appended runs a short scripted sequence and writes
screenshots to `FindingNaresh/_shots/`. Used to review the look without playing:

```
tools\godot\Godot_v4.7.1-stable_win64_console.exe --path FindingNaresh --resolution 1600x900 -- --shot
```
