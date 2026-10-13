# Change ledger (Milestone G, the puzzle tuning)

The user, 2026-10-08: no full test run before every push. Instead, for
every puzzle we finish we note here **what changed**, **what it could break**
(our guess) and **which tests cover it**. The long runs (set:driving, full)
start in the background in `MPG` right after a push, while the next puzzle
is built in `../MPG_dev`; what they find is written under the entry it
points to, and fixed in the next round. At the end of the puzzle tuning, one
last full run is checked against the whole ledger.

**When a long run fails:** look here first. Find the entry whose "could
break" matches (a van stuck in the woods: the undergrowth; a test stopped
at J1: the junction gate), fix it, write what it was under "Found later".

Per entry: the puzzle, its branch and merge, then three lists.

---

## #2 The windmill (rounds 1-2, branches `g4`, `g5`; merged into main and pushed 2026-10-08, `e96c48b`)

**What changed**
- `puzzles/WindmillPower.gd` (new; `WindmillBrake.gd` deleted): the 24 m
  windmill at J1, the starter lever, sliding legs, the fall and restart,
  the rope ladder, the walkway and chest, the napin. Group `windmill`.
- `puzzles/WindmillWire.gd` (new): the switch house, poles and wire, the
  spark, the street lamps on the lane and both roads after J1, the storm
  wreckage past them.
- The junction gate across Home Lane just south of J1 (closed until the
  windmill turns), fences either side (`world/Fence.gd`, new), thickets
  (`world/Thicket.gd`, new).
- The windmill's meadow fenced along the lane's west verge for 230 m, with a
  stile 22 m south of the gate (`LevelLandmarks._windmill`, `_stile`).
- **World-wide:** undergrowth between close trees that only the van hits
  (`LevelScatter._undergrowth`, layer `VAN_BLOCK` = 128, the Camper's mask);
  extra bushes and fallen logs in the woods; a pad and a wider tree clearing
  at the windmill (`LevelLayout.PADS`, `CLEARINGS`).
- **One map, one holder:** `MapState.holder` (saved), `who_has_it`; the map
  on the upstairs desk at P2's (HouseInterior); M only for the holder; E on
  your partner takes it (`PlayerRig._snatch_target`, `take_map_from`).
- **One pin:** `MapState.STAMP_TYPES = ["napin"]`, `napin` flag (saved),
  `find_napin` / `lose_napin`; PaperMap's help text and `place_stamp`; the
  van's nav text ("NAPIN", "no pin").
- **The head-butt:** G / pad RB with empty hands on foot
  (`PlayerRig.headbutt`, `_strike`, wind-up, shake, `dazed_t`,
  `ui/StarsRing.gd`, `fx/ButtFx.gd`); legs, partner, Naresh, the van
  (`Camper.thump`), loose things, walls.
- **Push out of the van:** seated G / pad hold RB (`PlayerRig._push_controls`,
  `Camper.push_out`).
- **Solo testing:** TAB keeps the left player holding
  (`InputDevice.kept`, `park_keeping`, `take_over`; `Boot.keep_holding`;
  F1 Puzzles toggle; HUD "HOLDING E").
- Story: P2's opening step "take the map from the desk"; `to_windmill`
  done at the gate; `windmill` (the gate has no power), `napin` (climb);
  `stamp_beach` worded for the napin. DevMenu: the Puzzles row, jumps set
  the map holder and the napin, reset_way_out. SaveGame: group `windmill`.
- Input glyphs: `fwd` / `back` (the ladder said "[?/?]").

**What it could break (our guess)**
- Anything that drives through J1 from the south: the gate is shut until
  the windmill turns (journey, routes, way_out, any walk or test that
  drives Home Lane north). Tests that pass J1 must call `wm_open_gate()`.
- Anything that drives off the road near woods: the van now stops at the
  undergrowth (the auto-driver cutting a bend, a test that parks the van
  off-road with `van_spot`, a creature test's van placement, a walk that
  drives across grass).
- Anything that walks from Home Lane to the windmill area: the meadow fence
  (only the stile lets you through).
- Anything that presses G or pad RB with empty hands: it now head-butts
  (and a G that throws no longer butts). Pad RB held in a parked van pushes
  the other out after 0.5 s.
- Anything that reads or places map stamps (old types are gone; only
  "napin"), or opens the map as P1 in a new game (P2 has it; P1 can't
  open it until they take it), or loads an old save (holder defaults to
  P2, the napin to "not found").
- Anything that relies on TAB letting go of keys (held keys are now kept).
- World build time (+1.3 s) and frame rate in the woods (more bushes and
  logs in the MultiMeshes).
- The opening's P2 steps (the map step changed).

**Tests that cover it**
- `windmill`, `windmill_fall`, `fun`, `solo`, `gate_bypass`, `save`,
  set:opening, smoke, set:creatures: 0 failures (2026-10-08).
- Walks `puzzle2` (285 s) and `solo2` (97 s) recorded, every step passing.
- Not yet run on this: **set:driving** (journey, routes: they now open the
  gate first), **full**.

**Found later** (by the long runs)
- (none yet)

---

## #3 The barn maze + the weather (branch `g6`; merged and pushed 2026-10-13, `0f2f077`)

**What changed**
- `puzzles/BarnMaze.gd` rewritten: 14 x 14 cells of 3.5 m (50 m), 3 m
  hedges as one mesh (one StaticBody of box shapes), loops, the courtyard,
  12 landmarks (tall, low, twins), painted arrows, 5 pits (fall -> the
  drain by the front gate), 5 jump scares (pop only walking back out of a
  wrong turn), the flag on a pole (worn, own camera hides it), the bell,
  the chest (MazeSpare, MazeFuel 10 L, MazeCoolant, Naresh's push note),
  the back gate, snow from the courtyard to the chest, footprints. Moved:
  behind the barn (barn frame (6, 0, -36)); the old west-side maze gone.
- The barn: the silo's dome replaced by a deck, rail and cage ladder
  (`SiloLadder`), Naresh's sketch board and note (`LevelLandmarks`
  `_silo_top`, `_silo_sketch`). POIs `maze_gate`, `maze_back`,
  `silo_ladder`, `silo_top`, `barn_yard`; `maze` moved.
- `LevelLayout`: the barn pad is now `MAZE_YARD` (-508, 183), radius 50,
  blend 14 (was BARN_YARD r 30); a clearing r 54 there.
- **World-wide weather:** `world/Weather.gd` (new, group `weather`): clouds,
  light snow per player (GPU particles) from J1, far thunder, the maze's
  heavy snow, the clear spell, `snow_cover` (a global shader value,
  `project.godot [shader_globals]`). `world/CloudSky.gd` (new): the sky is
  a shader now (was ProceduralSkyMaterial), radiance redrawn every frame
  (REALTIME, 64). `Mood`: `clouds`, `cloud_dark`, `snow` (white fog to
  15 m), sun dimmed by clouds.
- **World-wide materials:** `core/SnowMat.gd` (new): the terrain, pines,
  canopies, rocks and bushes use it instead of ToonMat / StandardMaterial;
  the terrain's vertex alpha = where snow may lie (0 on the road).
- The push out of the van: only after the maze (`Story.flags["push"]`,
  `PlayerRig.can_push`). `PlayerRig.fade_color`, `straw()`, `jolt()`;
  `PlayerHUD` straw overlay. `Camper`: a spare can go back on the empty
  rear mount. Sounds made here: bell, caw, moo, sting, crack
  (`tools/gen/maze_sounds.py`). DevMenu: Puzzles 3 starts in the barn
  yard; places silo top, maze way in.

**What it could break (our guess)**
- **Frame rate everywhere:** the sky shader + realtime radiance, the snow
  particles, the snow shader on every tree and the ground (perf, the
  promenade's dusk fps check, mirrors, driving tests).
- **The look everywhere:** the sky (clouds, sun disc, colours at dusk and
  in the storm), the ground's brightness (same albedo 0.6, but a new
  shader), trees and rocks (outline kept), MultiMesh fade at range
  (visibility fade with a custom shader).
- Anything that reads the sky material as ProceduralSkyMaterial (Mood was
  the only one).
- The barn area: the bigger pad may change heights near the valley road
  (the road 66 m away); scatter, clearings; tests that used the loft or the
  old maze position (`maze`, `tour`, `overview`, `teleports`, `dev`).
- The push: `fun` (now needs the flag), any walk or test that pushes
  (puzzle2's walk step 2.10 pushes the driver out!).
- Saves: the maze's dict (`dust_done` -> `snow_done`, `back_open`).
- Story jumps / Puzzles reset: `reset()` also clears `push`.

**Tests that cover it**
- `maze` (21 checks), `maze_views` (pictures), `weather` (stages, pictures,
  fps), `fun`, `puzzle_resets`, `dev`, `mood`, `story`, `save`: 0 failures.
  smoke: 23 scenarios, 1 failure (the promenade's dusk fps, 91, while the
  full run went alongside: to rerun alone).
- Walk `puzzle3` (13 steps), recorded.
- set:puzzles: 2 failures (the water works' crate climb, 0.44 m) with three
  games running and PlayTest.gd edited mid-run; `waterworks` alone: 0
  failures (climbed to 1.25 m). Not a break.
- Not yet: the walk `puzzle2` again (its push needs the flag now), set:driving,
  full.

**Round 2 (2026-10-12, still `g6`)**
- What changed: 18 x 18 (63 m), `MAZE_AT` (6, 0, -43), the pad (-512, 172)
  r 64, the clearing r 70; `puzzles/MazeDoor.gd` (new: real, oneway, fake,
  loop); `puzzles/MazeFrights.gd` (new: the music box, spins, corners,
  distractions, sounds, the follower, small prints, the stumble);
  `tools/gen/maze_sounds.py` musicbox; the marks (chest lantern pole, exit
  windsock, EXIT board, the gate lamp); the dirt track round to the back
  gate (`BarnMaze.TRACK`); `barn_yard` moved out to (2, 0, 24) and Puzzles
  3 parks the van facing along the track; the push note in the chest lid.
- Could break: the bigger flat ground near the valley road (66 m), trees
  and clearings; the van's track (anything placed on it); frame rate (one
  more light, particles, a music player); the maze's save (doors aren't
  saved: a load resets them, shut).
- Tests: `maze` (the walk through the doors, both one-ways latched),
  `maze_frights`, `maze_van` (round the track in 27 s): 0 failures. Walk
  `puzzle3` (15 steps, 323 s) recorded.

**Round 3 (2026-10-13, still `g6`)**
- What changed: each player's camera has its own Environment
  (`Mood._player_envs`, `snow_by`, `env_of`): the snow fog only for whoever
  is in the maze; the world's environment no longer gets it. Flags: two
  (`rack_left`, `_spares`, `flag_count`), hidden gaps (`gaps`, `GAP_W/H`,
  `_snag`; built as two sides and a lintel), four marker flags; the stumble
  keeps the flag. The plan (`drawn`, `pending`, `crosses`, `attach_board`,
  `ui/MazePlan.gd`, `PlayerRig.plan_open`, `open_plan`, `_plan_controls`;
  the map ignores M / D-Down while the plan is open). Frights only when
  lost (`MazeFrights.visits/best/spell/lost`; the walk-back scares too).
  Pad / keyboard glyphs for map_place / map_remove.
- Could break: anything reading the camera's fog (the player's camera no
  longer uses the world's Environment: a new Mood field not in the copy
  list wouldn't reach the players); the mirrors / photo camera (still the
  world's env); the paper map's M while the plan is open; E at the silo top
  (the plan's zone by the ladder).
- Tests: maze, maze_frights, maze_r3: 0 failures. Walk `puzzle3` (17 steps,
  382 s) recorded.

**Found later** (by the long runs)
- (none yet)
