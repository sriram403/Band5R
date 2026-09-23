# Finding Naresh: Bessi and the 5 Roses

Godot 4.7 project. **Stage 1 of 2: look-and-feel prototype.** This build exists so you
can decide whether the controls, the driving and the art direction feel right before
the full 30-minute demo from `Finding_Naresh_Game_Demo_Build_Prompt.md` gets built on
top of it.

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

Double-click **`Play.bat`**. First launch takes about a second while the world is
generated. Press **Enter** (or **Start** on a controller) at the title card.

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
| Right a tipped-over van | R | View |

Driving (once you are in the driver's seat):

| | Keyboard | Controller |
|---|---|---|
| Throttle | W | RT |
| Brake / reverse | S | LT |
| Steer | A / D | Left stick |
| Handbrake | Space | B |
| Ignition | **X** | D-pad Up |
| Headlights | L | D-pad Left |
| Swap seats (stopped) | C | LB |
| Get out (stopped) | E | X |

You can only get out, or swap seats, once the van has (nearly) stopped. The prompt
under the crosshair always shows what you can do right now; while driving it stays
empty so the road is clear. The control reminder at the top fades after ~14 s.

Other keys: **[ / ]** mouse sensitivity (saved) · **TAB** switch player (solo) ·
**F2** layout · **F11** fullscreen · **F3** teleport both players to the camper ·
**ESC** pause (**Q** quits from pause).

## What to try

1. Walk around. Check mouse sensitivity, walk/sprint speed, head bob, jump weight.
2. Walk to a camper door and press **E** — the prompt appears when you look at a door.
3. Press **X** to start the engine, then drive. The loop road is about 900 m; there
   are crests, dips and long bends, so you can judge steering weight, body roll,
   braking and how the van handles a downhill corner.
4. Look at the dashboard: physical speed, fuel and temperature dials with needles,
   three warning lamps, and a nav screen angled toward the passenger.
5. Put the second player in the passenger seat and look around independently — the
   two views are fully separate.
6. Find the five giant rose monuments on the hill in the middle of the loop. They are
   deliberately visible over the treeline from most of the road: that is the
   navigation-by-landmark mechanic the full demo depends on.
7. Other landmarks to orient by: the homestead and garage at the start, the water
   tower, the red barn and silo, two ponds, road signs and an information board.

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

Run the play-test yourself (a window opens; takes about 5 minutes):

```
tools/run_game.sh --resolution 1600x900 -- --playtest          (everything)
tools/run_game.sh --resolution 1600x900 -- --playtest=drive    (one scenario)
```

Scenarios: mouse, foot, taps, enter, cockpit, layout, park, solid, crash, look, pad,
drive, brake, lap, exit, swap, perf. It prints `PASS`/`FAIL` lines and writes
`_shots/test_*.png`. Last run: 52 checks, 0 failures. Don't move the mouse over the
window while it runs; real mouse input is mixed in with the simulated input.

## What is in this prototype

- True local split-screen: two independent `SubViewport`s and cameras sharing one
  world, with per-player HUDs. Each player's own body is masked out of their own
  camera, so you see your partner but not the inside of your own head.
- Per-player input isolation. Devices are read from the hardware directly rather than
  through a shared `InputMap`, so one player's mouse can never move the other.
- First-person controller: walk, sprint, crouch, jump, look, flashlight with a visible
  beam, raycast interaction with contextual prompts that use the right glyph for each
  player's device.
- Drivable camper: `VehicleBody3D` with four raycast wheels, speed-sensitive steering
  lock, self-centring, reverse, handbrake, and a load-dependent engine curve.
- Vehicle condition: fuel burn scaled by distance, load and gradient; an equilibrium
  engine-temperature model; battery drain with the engine off. All shown on physical
  dials plus a minimal HUD.
- Seats and enter/exit, with independent look for driver and passenger and a seat swap.
- Procedural engine and tyre audio, so there are no third-party sound files to license.
- Handcrafted 800 x 800 m world: a closed loop road generated from hand-authored
  control points, terrain that flattens into a clean driving corridor and rolls
  everywhere else, a vertex-coloured toon terrain, ponds, ~2500 scattered trees, rocks
  and bushes on a fixed seed, distant mountains, and the landmark set above.
- Cartoon art direction: banded toon shading with inverted-hull outlines, a saturated
  colour grade, soft shadows and light depth fog.

## Not in this prototype yet

Everything else from the build prompt: the three co-op puzzles, carryable physics
objects, the paper map and map stamps, Memory Fragments and the manual-save system,
health/downed/revive, the threat and hide sequence, Naresh and his fuel mistake, the
story text and the imaginary-friend clues, weather, the settings menu, and the sampled
audio set. The architecture is laid out so those slot in rather than requiring rework.

## Architecture notes

`scenes/Main.tscn` is deliberately almost empty: one node running `Boot.gd`. The world
is assembled in code from data tables so it can be iterated on quickly and re-authored
into scene files later without changing the systems.

| File | Role |
|---|---|
| `scripts/core/Boot.gd` | Session root: builds the world, players and split-screen shell; owns device assignment, pause and the dev capture mode. |
| `scripts/core/InputDevice.gd` | One per player. Reads keyboard/mouse or a specific joypad, exposes `move/look/held/just_pressed/throttle/brake/steer` and prompt glyphs. |
| `scripts/core/ToonMat.gd` | Every material in the game. Change the art direction here. |
| `scripts/core/Build.gd` | Primitive-mesh helpers used to assemble props. |
| `scripts/player/PlayerRig.gd` | First-person `CharacterBody3D`: movement, look, flashlight, interaction ray, seating. |
| `scripts/vehicle/Camper.gd` | Chassis, driving model, condition systems, dashboard, seats. All tuning constants at the top. |
| `scripts/vehicle/EngineAudio.gd` | Procedural engine/road noise. Swap for sampled loops later; keep `set_state()`. |
| `scripts/world/Route.gd` | The road centreline: Catmull-Rom sampling, smoothed elevation, nearest-point queries. |
| `scripts/world/Landscape.gd` | Terrain mesh + collision, road ribbon, pond and mound height fields. |
| `scripts/world/LevelBuilder.gd` | World layout data (route points, ponds, mounds, landmarks, signage) and assembly. |
| `scripts/ui/PlayerHUD.gd` | Per-player HUD inside each viewport. |
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

All art, geometry and audio in this build is generated at runtime from Godot
primitives and code. No third-party assets are used, so there is nothing to credit yet.
A `CREDITS.md` will be added if that changes.

## Dev capture mode

`Play.bat` with `-- --shot` appended runs a short scripted sequence and writes
screenshots to `FindingNaresh/_shots/`. Used to review the look without playing:

```
tools\godot\Godot_v4.7.1-stable_win64_console.exe --path FindingNaresh --resolution 1600x900 -- --shot
```
