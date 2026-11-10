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
- Full run after the push (`appdata/full_after_push2.log`): 4 failures.
  Two frame-rate checks (two games at once; alone 144 fps). Two in the
  fishing village (decoy): "P1 takes the full can off the rack" and the
  refuel after it. Not from #2: an empty rack slot's zone caught the aim
  of a can in the right-hand slot. Fixed in `g7` (2026-10-14, empty slots
  are see-through for empty hands); decoy, saltpans, carry, story,
  opening_p2, smoke: 0 failures (smoke's dusk frame rate with the full
  run alongside: to rerun alone).

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
- Full run after the push (`appdata/full_after_push3.log`, 2026-10-13/14,
  resumed twice): 6 failures. Two the rack bug (see #2, fixed in `g7`).
  `maze_views` S4 curtain from the ridge and `weather` (snow at "the
  opening" and "over the ghat"): a player left at the maze by earlier
  tests; the curtain hid for everyone if anyone was near. Fixed in `g7`:
  the curtain per player, the weather test places both players first.
  `crash`: the van flipped while still moving and landed on its wheels
  (test; fixed). maze_views + weather, crash, maze, maze_van, maze_r3,
  maze_frights: 0 failures (frame rate rerun alone still to do).

---

## Small: the spare is used up (branch `g7`, 2026-10-14, the user's yes)

**What changed** - `Camper`: "Take the spare wheel" only with a spare on
the mount; without one the mount says "No spare on the back: the flat
stays until you find another wheel" (the barn maze's chest has one).
**Could break** - anything that punctures twice without `reset_camper`
(Naresh's tyre fix, the creature puncture, roadworks after a jump).
**Tests** - tyre (new check), roadworks, maze, puzzle_resets,
opening_full, van: 0 failures.

---

## Full run after the g7 push (`appdata/full_after_push_g7.log`, 2026-10-14)

**Found** - 1 failure: decoy "they leave the shed for him (clear after
60 s)": one creature frozen ~45 s (open, logging added, see ROUGH_NOTES).
The last segment broke off again: over the 3600 s limit (fixed: `routes`
and `way_out` in their own segment, branch `g8`).

## Full run after the split (`appdata/full_g8.log`, 2026-10-14)

All 22 segments finished (the split works; nothing broke off). 1 failure:
save "loading restores the can on the rack" (a can left in slot 1 by an
earlier test; test fixed, branch `g9`). Rerunning the return's tests then
found a game bug: a random act made Naresh let go of the mast's dish 2
(no calm zones in the world). Fixed in `g9`: no act while he holds or
works something he was told to; `naresh` checks it.

---

## #4 The lookout boards (branch `g10`, 2026-10-14; not merged yet)

**What changed**
- `puzzles/LookoutRelay.gd` rewritten. Six pictures (boards or paint)
  on the landmarks, each turned to face the deck: the windmill's neck
  (strapped, 14 m up, child of `WindmillPower.tower`), the silo (a
  `Decal`), the barn wall, Last Fuel (on a pole extension above the sign),
  the water tower's tank (a `Decal`, 4.2 m), the switch house. Mounted by
  `mount_plates(builder)`, called at the end of `LevelBuilder._landmarks`.
  The code = windmill, silo, the shape on two places (barn = Last Fuel),
  water tower. The patrol's sheet (riddles) on the box; the handle
  ("Pull the handle") opens it only on the right code; a wrong try spins
  the dials to new wrong places (`try_open`, `_spinning`). The patrol sign
  up the slope (riddle 4) under 4 lumps of old snow (`snow_left`, saved),
  knocked off by snowballs (`snowball_hit`, group `snow_target`). Snow
  patches under the deck. The practice boards (the old two). A direction
  table on the deck (a piece broken out at the water works). Rail rests
  (group `binocular_rest`). Naresh's note on the box's back (`relay_box`).
  `start_dials`; `reset()` puts the snow back.
- `items/Snowball.gd` (new): fun mechanic no. 4. Thrown at what you look
  at (from the hand to the crosshair's spot, lobbed); bursts on hit: a
  partner (jolt, "SPLAT"), Naresh (complains), the van (a white splat that
  melts in a minute), snow targets; heard by creatures like any thrown
  thing; melts after 4 min held.
- **Binoculars** (`PlayerRig`): `zoom_level` 2x-8x (wheel; pad RB / LB with
  LT held), kept between raises, shown under the eyepieces
  (`BinocularView.show_level`); sway above 5x (`_update_sway`, camera only),
  less crouched or `resting()` at a rail (or seated). No head-butt with
  them up; the passenger's LB doesn't swap seats while zoomed (`Camper`).
  `InputDevice`: actions `zoom_in` / `zoom_out`.
- **World-wide:** view lanes from the deck (`LevelLayout.in_view_lane`,
  `view_targets`; 260 m long, 5 m half-width): no trees there, stumps
  instead (`LevelScatter`).
- **The barn's snow shower** (`BarnMaze` curtain): soft edges (no glass
  tube), grey, a low cloud on top (`ShowerCloud`), wider (88-105 m: over the
  barn and silo), thins ~4 s in every 20 (`curtain_thin()`).
- DevMenu row text; PlayTest: `relay`, `relay_kb` rewritten; new
  `relay_views`, `bino_zoom`, `snowball`; `puzzle_resets` checks the snow.

**What it could break (our guess)**
- Anything that reads the relay's old shape: `code` order, `dials` reset
  to 0, the box opening as soon as the dials match (now the handle):
  `save` (loads `snow_left` too), `home` / tower lights (`opened`).
- The binoculars test in its gym (default 4x kept), tagging through them
  (aim unchanged; sway is on the camera only), the pad's RB (throw /
  head-butt) and LB (swap seats) while zoomed.
- Tree placement near the ridge (fewer trees; stumps): `tour`,
  `overview`, the ridge track's undergrowth (van-only blockers are also
  cut in the lanes).
- The maze's curtain (`maze_views`) now bigger and fading at its edges.
- Thrown items: only the snowball aims from the eye; others unchanged.

**Tests that cover it**
- `relay` (19 checks), `relay_kb`, `relay_views` (6 plates + the snow,
  screenshots), `bino_zoom` (zoom, rest, crouch, pad), `snowball`,
  `puzzle_resets`, `binoculars` (gym), `maze_views`, `save`, smoke.

- After the video (2026-10-17): riddle 3 "shape", riddle 4 "the water
  tower at the coolant works", Naresh's note's last lines; **place hints**:
  `Story.hint_text` asks every node in group `place_hint` first
  (`LookoutRelay.hint_for`, `near_t`, `HINTS`). Could break: any hint
  check elsewhere if a place hint leaked out (it's "" beyond 70 m of the
  box or once open). Tests: `relay` (4 new hint checks).

**Found later**
- (nothing yet)


## #5 The lift bridge: the seesaw (branch `g11`, 2026-10-17; not merged yet)

**What changed**
- `puzzles/LiftBridge.gd` rewritten: no power, no levers, no wedge, no
  safety mirror. The leaf sits on its axle like a seesaw (`TAIL` 1260 kg m
  heavier at the back, `FRICTION` 160, `INERTIA`, `DAMP`): weight x
  distance of players (80 kg) and stones (25 kg) on the leaf (`_pull`)
  moves it; resting up at `UP_DEG` 30; a fast landing slams (`_slam`:
  players on it knocked, stones jump). The lock lever in the machinery
  house (only flat and still). The house barred from inside (`door_open`),
  a hatch high in its road-side wall, the keeper's broken ladder; a rail
  round the counterweight pit. Chalk marks every 2 m on the deck, a repair
  notice. The hut's panel dead ("NO POWER"). Naresh's notes `lb_hut`,
  `lb_door`, `lb_lock`. Place hints (`hint_for`, `HINTS`, group
  `place_hint`). The river: players in it swim to `bank_at`
  (`PlayerRig.fall_in_water`), stones sink (`BridgeStone.sink`).
  `setup()` lost the mirror / power arguments, gained `stone_spots`, `bank`.
- `items/BridgeStone.gd` (new): 25 kg flat stone (box collider, rough).
- `PowerLine.gd`: the last pole before the hut is snapped (`_build_snapped`,
  `snapped_pole`); the wave stops there; `hut_powered` always false.
- `PlayerRig.gd`: **the leg-up** (fun mechanic 5): jump next to a crouched
  partner (hands free) = `LEGUP_VELOCITY` (feet ~1.75 m up), prompt
  "[Space] Leg-up off P2's back", `boosted()`. **Swimming** (`swimming`,
  `_swim`, `_swim_to`) and **wet** (`wet_t`, drips, shivers). `_drip()` takes
  a colour.
- `LevelLandmarks._bridge_hut_and_power`: river stones on the near bank's
  dry strip, the swimmers' bank point; pois `bridge_bank`, `leaf_tip`,
  `stone_heap`, `machinery_hatch`, `lock_lever` (gone: `bridge_mirror`,
  `wedge`, `counterweight_edge`).
- Story "bridge" text / hint; DevMenu row 5 (starts in the van 25 m short
  of the barrier).
- PlayTest: `bridge` rewritten, new `bridge_mistakes`; `power` (the hut
  stays dead), `save`, `puzzle_resets`, `way_out` updated.

**What it could break (our guess)**
- Anything that used the hut's power (`hut_powered`): `power`, `save`,
  `storm` (F2: the panel says NO POWER anyway), `puzzle_resets`.
- The leg-up: any jump next to a crouched partner anywhere (fun, but a
  test that crouches P2 by P1 and jumps would jump higher).
- The F2 storm (`storm_blow`), `way_out` (locks by script), the van
  crossing (stones left on the leaf).
- Swimming only triggers within 40 m of the bridge.

**Tests that cover it**
- `bridge`, `bridge_mistakes`, `power`, `puzzle_resets`, `save`, `storm`
  (the storm-road scenario), smoke.

**Also changed while building (2026-10-17/18)**
- `PlayerRig.hold_point`: things of 24 kg or more (the stones; the Bessi
  battery box, 26 kg) are carried level at the belly, wherever you look.
  Could break: `bessi` box carrying (its hold point moved).
- `Carryable`: prints `[carry] ... snagged` with the hold point, the holder
  and what it touches when a held thing is let go.
- `LevelLandmarks._broken_bridge`: the old bridge's deck starts two planks
  further out at each end, with a ramp plate up from the road (a 0.4 m
  step stopped anyone on foot). Could break: drives over the bridge
  (`journey`, `routes`, `way_out`), the F2 storm road's dead end.
- `DevMenu.reset_way_out`: a jump past the water works marks the hose as
  split and fixed (a jump to the bridge split it again). Could break:
  `story`, `puzzle_resets`, the water works jump (still sets its own).

**Found later**
- (nothing yet)

## #5 round 2: the van's seesaw (branch `g11`, 2026-10-19; not merged)

**What changed**
- `puzzles/LiftBridge.gd` rewritten again: a 10 m leaf on a pivot in the
  middle of the river (`leaf` turns itself: a moving body follows its own
  transform, not its parent's). Near half heavier (`TAIL` 2800 kg m,
  `FRICTION` 600, rest `REST_DEG` 5 near end down, pit `PIT_DEG` -14).
  Weight x distance from the van's wheels (2150 kg / 4), players, three
  carts (450 / 350 / 250 kg) on rails along the edges and a siding on the
  near deck; grab a cart (hold E) and walk: it follows, heavier slower.
  A hinged flap (`apron`, 2 m) onto the leaf. The van: kept awake, carried
  with the turning leaf (`_carry_van`), lifted if a hub sinks
  (`_unbury_van`), held still when parked on it (`_hold_parked_van`),
  never frozen (`Camper.on_moving_deck`); with it on, the leaf turns at
  most `VAN_W` 1.4 deg/s. Mistakes: far-heavy past the middle -> the pit
  (`_fail`, fade, restart at the gate); the van touching a cart -> the
  cart over the side, the van thrown back, the rack's cargo flung
  (`_shove`, `_fling_cargo`), restart; front wheels off a raised far end
  -> `puncture()`. The far bank's hut (`_build_hut`): door bolted inside,
  window sill 2.1 m (crate + leg-up), flickering lamp, boot scuffs; the
  lock (only inside, only level and still) and a crate with fuel,
  coolant, a spare tyre. Naresh's notes lb_hut (near hut panel), lb_gate.
- `puzzles/BridgeGate.gd` (new): barrier pole, hand winch inside a 1.6 m
  chain-link fence (slips back when let go), thickets at the ends.
- `PlayerRig`: leg-up `LEGUP_VELOCITY` 9.2; off a partner on a crate
  (higher x 1.5). `items/BridgeStone.gd` deleted (round 1).
- `LevelLandmarks`: the gate where the old barrier was (poi
  `bridge_winch`; "gate_winch" clashed with the rail tunnel's), the far
  hut, `van_start`, `lift_mid`; the old deck's last plank before the gap
  removed (the flap lies there).
- `DevMenu.reset_way_out`: jumps past the water works set the hose
  split + fixed.
- PlayTest: `bridge`, `bridge_mistakes` rewritten; probe `seesaw_probe`
  (in `all`, base gym); the bot `bot_cross` and helpers at the end.

**What it could break (our guess)**
- Anything that drives over the old bridge (`journey`, `routes`,
  `way_out`: the gate now blocks the road until wound up), the F2 storm
  road (`storm_blow`), `save` (keys locked / crossed / door / chest).
- The leg-up height (any test with a crouched partner).
- Heavy carry hold point (24 kg+: the Bessi battery box).

**Tests that cover it**
- `bridge_mistakes` (passes), `bridge` (passes but the bot's crossing),
  `seesaw_probe`, `puzzle_resets`, `power`, `save`.

**Found later**
- (nothing yet)

## 2026-10-19: the test window (bug fix, pushed to main)

**What changed**
- `PlayTest.gd`: no Godot NO_FOCUS / MOUSE_PASSTHROUGH flags (NO_FOCUS hid
  the window). `send_window_behind()` (static, called by `Boot._ready`
  before the world build) sets no-activate + click-through styles, shows
  the window, centred, behind, and pumps window messages until it has
  moved. `_hand_focus_back()`: when the quiet window gets focus it gives it
  back to the window below (on top after the user's taskbar click, behind
  at the start).

**What it could break**
- Every quiet test run's window (position, focus, sound: it stays muted
  now since it never keeps focus). `--show` and recording runs untouched.

**Tests that cover it**
- smoke (23 scenarios, 0 failures, twice), `story`; the user's watched
  check with a real taskbar click.

**Found later**
- (nothing yet)

## 2026-10-19: #5 round 2b, a lively seesaw (feature, g11, waits for the user)

**What changed**
- `LiftBridge.gd`: REST 12 deg, TAIL 150, FRICTION 50, INERTIA 2,500,
  DAMP 0.5; four blocks 700 / 550 / 400 / 300 kg, two per rail; the flap
  8 m (APRON), its rails stretched with it; the siding behind it; the
  van's belly weight on the far end while its front wheels hang; hanging
  off the raised end = a burst tyre and back to the gate ("hung"); hints.
- `LevelLandmarks.gd`: four planks left out under the flap (was one).
- `DevMenu.gd`: the bridge jump's text (it still described round 1).
- `PlayTest.gd`: new `seesaw_live`; `bridge_mistakes` for four carts, the
  hang, and the level arrangement for the lock.
- `tools/live/make_puzzle5.py`: rewritten for round 2b.

**What it could break**
- `bridge` (the crossing bot was tuned to round 2's numbers), `save`
  (four carts), `puzzle_resets`, `storm_road` (the storm sets the leaf).

**Tests that cover it**
- `seesaw_live` (passes), `bridge_mistakes` (passes), `bridge` (see TODO).

**Found later**
- (nothing yet)

## 2026-10-20: #5 round 2b fixes (feature branch g11, waits for the user)

**What changed**
- `LiftBridge.gd`: the van no longer carried by re-setting its transform
  (it sank and stalled); turn cap with the van 7 deg/s (was 1.4); the leaf
  for the flap and carts computed from `angle` (`_leaf_xf`: after a snap the
  flap pointed up); the shove's reach 3.7 m (3.1 missed on the slope).
- `PlayTest.gd`: test benches `seesaw_dip`, `shove_bench`; `seesaw_live`
  drives on past the middle into the pit; `bridge_mistakes` crate step
  steady; `van_stuck_report` (pictures, what the van touches).
- `LiveControl.gd`: the watcher runs without Naresh; a van standing still
  5 s with the throttle down stops the walk.
- `tools/live/make_puzzle5b.py`, `5c`, `5d` (the rest, the van alone, the shove).

**What it could break**
- Anything riding the leaf (players carried still), `storm_road` (the storm
  sets the leaf), `save` (carts), `bridge` (the crossing bot).

**Tests that cover it**
- `seesaw_live`, `seesaw_dip` (with and without the snap), `shove_bench`,
  `bridge_mistakes` (0 failures x2); walks puzzle5b, 5c, 5d DONE.

**Found later**
- (nothing yet)

---

## #5 The ramp jump replaces the lift bridge (branch `g12` from `g11`; NOT merged, NOT pushed, waits for the user's look)

**What changed**
- Deleted: `puzzles/LiftBridge.gd`, `puzzles/BridgeGate.gd`, walks
  `puzzle5*`, the seesaw tests and their bot helpers.
- `puzzles/RampJump.gd` (new): ramp, wreck, far hut, launch and landing, the
  miss, hints, reset, save.
- `world/LevelLandmarks.gd`: gap 14 m (mid-2 to mid+5), BRIDGE OUT signs, piers
  to the river bed, pois `ramp_approach`, `ramp_foot`, `ramp_lip`, `bridge_far`,
  `van_start`, `far_hut`. `world/LevelLayout.gd`: `bridge_barriers` gone.
- `vehicle/Camper.gd`: `wheel_off`, `nuts_found`, `snap_wheel()`, a bare hub;
  `on_moving_deck` gone. `items/SpareWheel.gd`: `make_van_wheel()`.
- `core/SaveGame.gd`, `story/Story.gd` (`bridge` done on `ramp_jumped`, new
  step `wheel`), `world/StormFront.gd`, `dev/DevMenu.gd`, `ui/PlayerHUD.gd`,
  `tools/test_plan.sh`.

**What it could break**
- Anything crossing the bridge: `way_out`, the long drives, `return_run`, the
  storm road (the road continues past a real gap now; the bot must jump or be
  placed across).
- `storm_road`, `power`, `save`, `puzzle_resets`, `dev`: adapted, see below.
- The van's wheel code: the spare-wheel puzzle (`Camper` stage 1 and 4).

**Tests that cover it**
- `ramp`, `ramp_edges`, `ramp_wedge`, `ramp_retry`, `ramp_bench`; walk `ramp`
  DONE (13 steps, 169 s).
- Run 2026-11-05: smoke 23 scenarios, 0 failures (3 min). `dev`, `power`,
  `storm_road`, `save`, `puzzle_resets`, `ramp_retry` (4 of 4), `ramp_edges`,
  `ramp_wedge`: 0 failures.
- `ramp`: 1 failure, a check added that day (end of the drive on the road); the
  van reached the road (1.1 m), then the bot went round in circles. The check
  now asks for the closest it got: that edit has NOT been run.
- NOT run: `way_out` and the rest of `set:puzzles`.

**Found later**
- (nothing yet)

---

## #6 The ghat: Problem and the heat rule (branch `g15` from `main` 0705897; NOT merged, NOT pushed, waits for the user's look)

### L1 the heat rule (2026-11-09)
**What changed**
- `vehicle/VanAttack.gd`: the heat rule for every encounter. A Problem that
  wants the van calls `creature_interested()` each tick; while it does
  (`interested()`), the van leaks 4 L/min (capped 17.5 L an encounter, never
  below 4 L) and heats (`heat_rate`: 0.3 + 1.9 x throttle + 0.12 x m/s deg/s,
  0.6 deg/s with the engine off). The old near-the-van harms (cough at 30 s,
  puncture at 60 s) are kept for other creatures.
- `vehicle/Camper.gd`: `_problem_heat` (the needle never falls while it's
  interested; steaming boils coolant away), `boil_dry()` (half the coolant
  gone, no restart until it is back over 75 %), `boiled_dry`, `STALL_DRAG` (a
  dead engine in gear drags the van to a stop).
- `creatures/Creature.gd`: `director` (a puzzle steers it while it has
  nothing else on its mind; it still sees and hears players); generic
  creatures report interest (`van_interest > 0`).
- `world/Ghat.gd`: the old glimpse + attacker at the pass replaced by
  Problem: watch -> follow -> come -> circle -> leave. Seen at hairpin 1
  (`SEEN_HAIRPIN`, Q1 pick B pending the user: hairpin 2 leaves 170 m, too
  short). Fog now up to the pass. A pass guard 50 m short (should never fire).
- `story/Story.gd`: `hide_van` reworded; new step `ghat_fix`.
- `ui/PlayerHUD.gd`: TEMP / COOL bars and "ENGINE HOT" hidden while a Problem
  is interested (Q2 pick B pending the user).

**What it could break**
- Every creature that wants the van now heats + leaks it until it loses
  interest (driving away no longer stops the leak): `van` (adapted),
  `tower`, `decoy`, `saltpans`, `tunnel`, the return run.
- Old ghat tests: `ghat`, `ghat_menu`, `way_out`/long drives (they expect the
  creature at the pass), `puzzle_resets` (flags), `storm_road`.
- Taken.gd's leak after being taken (unchanged, but adds to the new leak).

**Tests that cover it**
- `ghat_heat` (new; 3 driving profiles): see the run results below.
- `van` (gym creature, adapted to the rule).
- Run 2026-11-09 20:36 (`ghat_heat`, 3 profiles, ~9 min): **0 failures**.
  Seen -> boiled: flat out 6 s (at rest sample 319), cornering 17 s (308),
  crawling 29 s (292); pass at 382, fog to 380, guard never fired. Hiding well
  leaves coolant at 21-25 % (one 2.5 L pot refills it to 75 %).
- `van` (gym creature): 0 failures after adapting 2 checks to the rule.

**Issues found while building L1, each with its own check (prove in L6 against a planted bug + clean run)**
| Issue found | Check (in `ghat_heat`) | Plant to prove it |
|---|---|---|
| the dead van coasted over the pass | "comes to rest before the pass, in the fog" | `STALL_DRAG = 0` |
| the breakdown came out of the fog (fog ended at 363) | same check (fog > 0.9) | `fog_to = point_count - 20` |
| seen at hairpin 2, the heat alone couldn't boil it before the pass | "the heat alone boils it, the pass guard not needed" | `SEEN_HAIRPIN = 1` |
| the HUD showed TEMP / COOL bars and "ENGINE HOT" | "hot with it watching: no bars, no banner; the grille steams" | remove the `problem_on` guard |
| my test counted heat on the tick it saw the van | (test fixed; the check "no heat before it sees the van") | — |

### L2 Problem's looks and sounds (2026-11-09)
**What changed**
- `creatures/Creature.gd`: everything you see hinged at the feet (`_rig`) and a
  head on its own neck (`_head`); `pose` (stand / lean / crouch / slump),
  `look_point`, `show_interest` (eyes + whine), `turn_cap` (deg/s), sniffs at
  a crouch; `eye_point()`, `head_forward()`.
- `world/Ghat.gd`: in the watch only its head follows the van (2.5 s, eyes dim
  -> bright); at the van a round of stops (`ROUND`: bonnet, driver's window,
  back, passenger's window); giving up it slumps, turns away at 35 deg/s and
  sets off only once facing away.
- `vehicle/Camper.gd`: hot metal ticks (`tick_every`, faster with heat), a
  kettle hiss when boiled dry. `audio/Sfx.gd` + `tools/gen/problem_sounds.py`:
  sniff, gasp.

**What it could break**: every creature now has its meshes under `Rig` /
`HeadPivot` (nothing found reading the old layout); the creature gym, the
tower, the decoy, salt pans (looks only).

**Tests**: `ghat_looks` 0 failures (2026-11-09 21:2x).
**Issues found, each with its check**
| Issue | Check | Plant to prove |
|---|---|---|
| leaning in at a window its head went through the glass | "its face stays outside the glass" | window stops back at x 2.3 |
| the give-up turn snapped round (204-228 deg/s): it set off before facing away | "it turns away slowly" | remove the facing test in `_direct` |
| (test) the round's last stop was counted on arrival, before the crouch | — | — |

### L3 the shade-net tarp (2026-11-09)
**What changed**
- `shaders/shade_net.gdshader` (inside: a faint weave, back faces only) and
  `shaders/shade_net_out.gdshader` (outside: an opaque dark weave); the tarp is
  one box over the whole van (bumper to spare wheel) plus the rack, each in
  both layers. The window gap and "only the door mirrors" are gone.

**What it could break**: `van` (tarp pulled in the creature gym), `ghat`,
the tower / salt pans hides, mirrors under the tarp (they're inside it now).

**Tests**: `ghat_net` 0 failures.
| Issue | Check | Plant to prove |
|---|---|---|
| one see-through layer: from outside the windows and bonnet showed through | "from outside nothing of the van shows through the net" | one layer again (`shade_net.gdshader` on both) |
| the net box stopped short of the van's nose | same check | box length back to 7.0 |

### L4 coolant, S2, S3, S5 (2026-11-09)
**What changed**
- `items/WaterPot.gd` (new): an old steel pot, 2.5 L of water, kind "coolant" (the radiator takes it).
- `world/Ghat.gd`: three springs (samples 268 / 304 / 342: one within 80 m back of anywhere past 268),
  each a pipe in a dressed stone, a puddle, rocks as they fell, its pot on a flat stone; hold use with
  the pot at the pipe to fill it. Naresh's note on a milestone (sample 205, before hairpin 1). S3: at a
  window it leans in at, the seated player there holds crouch (Ctrl / pad B) to hold their breath;
  breathing fogs the glass, letting go early or running out is a gasp; either way it noticed (its
  search restarts), but each window can give you away only once an encounter. It gives up only after
  25 s of quiet **and** a full round of its stops. Once given up it is passive (no sight); the hot
  cap's yelp brings it back (`cap_blows`).
- `vehicle/Camper.gd`: the net must come off before the bonnet; the cap opens with empty hands; open
  while it still hisses (> 104 C): a WHOOSH, a white screen, a yelp, 8 % coolant lost (`_blow_cap`);
  `fog_window`; `breath_lock` (B / Ctrl don't work the handbrake while you hold your breath).
- `ui/PlayerHUD.gd`: `steam_flash`, the breath bar (`set_breath`). `audio/Sfx.gd`: gasp.

**What it could break**: anything pouring coolant (the opening's split hose, the windmill): the cap's
prompt now shows when boiled or hissing; the handbrake while a breath is held; `save` (pots are loose items).

**Tests**: `ghat_places` 0 failures; `ghat_jug`, `ghat_spring` (see the run below).
| Issue found | Check | Plant to prove |
|---|---|---|
| the last spring was 90 m short of the pass | "wherever it dies past the first spring, a spring is at most x m back" | springs back at 262 / 298 / 334 |
| hold-breath never came up (a seat compared with the van) | "at P1's window: HOLD Ctrl" / "both windows visited" | `seat == van` again |
| under the net it gave up before reaching a window | "it gives up, only after a full round" (looks) | drop the `stops_done` condition |
| nobody held their breath: the search never ended | "quiet at last, it gives up" (spring) | every window restarts its search |
| out beside it as it gave up, it took P1 | "out beside it after it gave up: nobody is taken" | not passive when it gives up |
| the cap's status text hid "Open the radiator cap" | "at the bonnet, still hissing: 'Open the radiator cap'" | blocked text back when hot |
| (test) a deleted jug found again by name; a 70 ms key tap missed after the long F1 teleport (logged as SUSPECT) | — | — |

### L5 marks that stay, saves, the end-credits turn (2026-11-09)
**What changed**
- `vehicle/Camper.gd`: `marks` (handprints on the glass and the bonnet, a dent, scrapes on the back
  doors, each with a seed and an encounter number), `add_mark`, `set_marks`, `drop_marks`.
- `world/Ghat.gd`: each posed stop of its round leaves its mark once an encounter; `adjust_save`: a save
  mid-encounter goes back to 90 m before hairpin 1 (the van as it was, flags and this encounter's marks
  undone, pots back at their springs); `match_story`; a jump back to the ghat clears the van's marks.
- `core/SaveGame.gd`: saves `marks` and `boiled_dry`; calls `Ghat.adjust_save` and `match_story`.
- `world/Homecoming.gd`: `show_end` first turns slowly round the van for 16 s (its own viewport over
  both halves, "The van. Everything they left on it is still there."), then the old end card.

**What it could break**: `save`, `bessi_jumps`, `step_jumps` (jumps back clear marks), `home` (the end
screen's timing: E now works after 21 s, not 5).

**Tests**: `ghat_marks` 0 failures (run 2026-11-09 22:04).
| Issue found | Check | Plant to prove |
|---|---|---|
| marks piled up across replays of #6 | "a clean van to start with" | don't clear marks on reset |
| — (the user's ask) | "the marks are saved and come back on load" | don't save marks |

### L6 the test method ported to #6 (2026-11-09)
**What changed**
- From `g14-final` (the research's method, `notes/method_research/FINAL.md`): `dev/RigBeat.gd`,
  `dev/MethodRec.gd`, `dev/C2Watch.gd`, `dev/RigInject.gd`, `tools/method/*`, `tools/method_run.sh`,
  `tools/rig/*`; PlayTest's method hooks applied 3-way (no conflicts).
- New for #6: `tools/method_run.sh ghat` (`GHAT=` scenarios, `FIXTURE=` plants); `tools/method/
  make_ghat_manifest.py` (a scenario's checks *and* its helpers', `%%` handled) and `freeze_ghat.py`
  (113+ required checks, work receipts seen / boiled / gave_up / fixed / over_pass); `dev/GhatWatch.gd`
  (state rules H1 heat only while interested, H2 the needle shows the real heat, H3 coolant only rises
  when poured); `core/Plant.gd` (planted bugs, off by default, one per check, read only at the line
  each breaks); `tools/method/prove_ghat.py` (runs the planted groups, writes PROVED / NOT PROVED);
  per-scenario episode deadlines (`PlayTest.EPISODE_S`); the method's whole-run cap and scope for
  `ghat`; `whole_run_cap_ghat_s` 3300.
- `MethodRec.WATCHED` gains the 7 #6 scenarios.

**What it could break**: the ramp's method run (`tools/method_run.sh ramp`): the PlayTest hooks are the
same, `frozen.json` gained entries; not re-run.

**Found by the method's first runs**
- TEST, correctly: two checks print "50%" and the manifest builder read `%%` literally (fixed).
- STALLED, correctly: #6's scenarios need their own episode limits (`EPISODE_S`).
- The clean run: `ghat_heat`'s follow-on waited 55 s for the give-up, but with nobody holding their
  breath it takes ~3 rounds (by design now): the test hides well there; `ghat_looks` 66 deg/s: the walk
  away wasn't turn-capped (fixed in `Creature._move`).

### L6 finishing (2026-11-10)
- The stall drag deleted (measured useless: 32 m vs 36 m of coasting after a boil); plant `no_stall_drag` gone; window-lean plant moved to 2.0 m (at 2.3 m its face stayed 0.14 m outside the glass). Could break: where a boiled van rolls to a stop (`ghat_heat` "it comes to rest before the pass").
- `ghat_heat`'s follow-on: nobody holds their breath any more; new check "sitting there breathing, a window gives you away only once: its second visit lingers" (plant `endless_window`, moved from `ghat_spring`, which never visits a window twice). Could break: the give-up takes ~3 rounds (wait 180 s).
- **The jug left on the road (bug fix, all puzzles):** `Carryable.stow` takes a stowed item out of the physics world (`process_mode` DISABLED), back on `unstow`. Could break: anything stowed or taken off the rack anywhere (fuel cans, the drum, boxes, the ramp's fling). Covered: `ghat_jug` "the jug rode up the ghat in its place on the rack" (plant `stow_live`), `ghat_jug` / `ghat_spring` take items off the rack, `ramp` (the can thrown off: passed once, landed in the water once, as it did once before the fix; `fling_bench`: identical throw with and without the fix).
- **Tail lights** 2.5 cm proud of the back doors (were coplanar: flickered); named `TailLightL/R`. Check in `ghat_net` (plant `tail_flush`).
- **`t_ramp`:** P2 waits for the "Leg-up" offer before jumping. The ramp's two flaky steps (can in the water, leg-up miss) are OPEN (ROUGH_NOTES 2026-11-10).
- **Final clean run 2026-11-10:** `tools/method_run.sh ghat` PASS, 7 / 7 scenarios, 119 / 119 required checks, 0 FAILs, H1-H3 clean, 1163 s (`appdata/method/runs/20261110_152703_ghat_k3`). Proofs: 22 plants PROVED (`appdata/method/prove_ghat.txt`).
