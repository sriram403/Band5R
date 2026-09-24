# Master prompt: Finding Naresh — Bessi and the 5 Roses (continue to completion)

You are taking over an in-progress Godot 4.7 game project from a previous session.
Read this whole file (`notes/MASTER_PROMPT.md`) first, then `DESIGN.md` (the agreed story arc, world, creatures and
the professional build process with gyms; it supersedes the original spec's plan),
`notes/TODO.md` (live progress; its "Right now" line says exactly where work stopped),
`README.md`, `FUTURE.md`, `CREDITS.md`, `design/map_plan_v1.png`, and only then the
original spec `Finding_Naresh_Game_Demo_Build_Prompt.md`, all in
`D:\mine\Agentics\T3_Code_Works\MPG`. Then continue from section 6. Everything below
is established fact unless it says otherwise.

**This file is kept current** (rule 11): it is updated whenever a part is finished and
tested, so a new session (any model) can resume if the previous one ran out.
Last updated: 2026-09-24, second thread: Milestone B finished, tested and
approved by the user, pushed. Next: discuss (no implementation yet), then build
the three test levels, then Milestone C.

---

## 1. The project in one paragraph

A two-player, local split-screen, first-person co-op road-trip adventure. Two friends
drive a battered camper van to find Naresh, who vanished on his way to "Bessi and the
5 Roses" with a "friend" nobody ever met (the twist: the friend was imaginary, left
ambiguous). Half driving and van upkeep (fuel, heat, coolant, tyres, battery, cargo),
half on-foot exploration, co-op puzzles, paper-map navigation, physics comedy.
Creatures you hide from (no killing; a hidden flare gun scares them off). Target: a
polished demo (the 30-minute cap is relaxed: up to ~3 h is fine, pacing matters),
Windows PC, keyboard + mouse for P1 and a controller for P2. The full story arc is in
`DESIGN.md`. Engine: Godot 4.7.1, GDScript, everything built
in code (no hand-made scenes beyond `scenes/Main.tscn` running `Boot.gd`).

GitHub: <https://github.com/sriram403/Band5R> (branch `main`). The user is
**sriram**; refer to them as "the user"/"you", pronouns
they/them.

---

## 2. Status right now (2026-09-24)

- **Stage 1** (prototype + feel pass) and **Milestone A** (homestead -> road trip ->
  water works -> broken bridge): done, approved, pushed.
- **Design agreed and pushed** in `DESIGN.md`: two homes + split tutorial, the way out
  teaching every mechanic, Bessi = an empty dusk beach inspired by Besant Nagar
  (Elliot's) Beach with the Five Roses rising from supernatural smoke (Naresh in the
  fifth), the return by a different road with Naresh (creatures follow him; he can be
  taken), Naresh's home + hidden tracker, the sunny drive home and the LiveStander
  teaser. Colour/mood curve bright -> grey -> dark -> bright. No health system: being
  caught separates you. Art stays block-out until a polish stage at the very end.
- **Small fixes** (ESC, handbrake, brakes, wheels, seated pose, van hits player,
  engine/pour/nature sounds, horizon ridges): done, 171 play-test checks pass,
  **approved and pushed** (main at `603fe46`).
- **Milestone B (foundations)**: done, approved and pushed (2026-09-24):
  - map plan v1 (`design/map_plan_v1.png`, `tools/gen/map_plan.py`) approved;
  - gyms done: `world/GymBuilder.gd` (`base` gym), `-- --gym=<name>`,
    `GYM=base tools/run_test.sh`, scenario `t_gym`; `Landscape.height_fn` lets a gym
    define its own ground; `Boot.gym_request` ("?" = none, "" = world) survives a
    scene reload;
  - developer menu done: `dev/DevMenu.gd` (F1), scenario `t_dev`;
  - chunked terrain done: `Landscape.build_terrain()` makes 250 m tiles (near 5 m
    mesh, far 20 m mesh with skirts, `visibility_range` switch at 800 m); world size
    is `Landscape.EXTENT` (static var, set by the builder; `--extent=<m>` override,
    `ARGS="--extent=4000" tools/run_test.sh perf` for load tests). 4 km: 144 fps,
    4.8 s build;
  - beat chart v1 (`design/BEAT_CHART.md`) **approved** ("happy");
  - mirrors + nav swing (user request) done: `Camper._build_mirrors()` (two door
    mirrors + rear-view: SubViewport cameras looking back, texture flipped on a quad,
    rendered only while someone is seated, round-robin one mirror every 2nd rendered
    frame from `Camper._process`; costs ~14 fps: 144 -> ~130 with both views
    driving). `Camper.swing_nav()` / `nav_aside` (N key, pad A, either seat): the nav
    label moves to the driver's private visual layer so only the passenger's camera
    draws it. Scenario `t_mirrors`;
  - full play-test after mirrors: 180 checks, 0 failures, ~130 fps (all committed,
    head is the mirrors commit; nothing of B pushed yet);
  - **4 x 4 km greybox done** (second thread): layout data in `LevelBuilder.gd`
    consts, mirrored in `tools/gen/layout_check.py` (checks grades/cuts/gaps,
    `--draw` makes `design/greybox_layout.png`). Roads: home_lane (homestead ->
    town -> P2 -> J1), valley_road, ridge_track, pump_house_road (J2 -> bridge ->
    J3), ghat_road (2 hairpins to the pass), beach_road (-> bessi_loop around the
    roses by the beach), coast_road (Bessi -> fishing village, salt pans, estuary
    bridge, under Tunnel Hill -> Naresh's home), west_road (-> homestead),
    tower_road (west_road -> ending watchtower -> P2). Sea + beach east, trees
    tiled, world builds ~7 s. Fixed an old bug: terrain triangles faced down
    (ground lit from below); albedo 0.6 keeps the approved brightness.
  - full suite on the new map: 180 checks pass (after fixing a lake-sound and
    two test-placement issues).
  - every road driven and timed (`tools/run_test.sh routes`, not in the default
    list; 16 min of driving at ~60 km/h). Fuel use lowered (FUEL_PER_KM 2.5).
  - **Milestone B approved by the user ("tested all good") and pushed.**
- The plan for B-G, with sub-steps, is in `notes/TODO.md`.

---

## 3. Rules the user has set (follow exactly)

1. **Nothing on the C: drive.** All tools, downloads, caches, user data stay inside the
   MPG folder on D:. Godot's `user://` is rooted at `%APPDATA%`; `Play.bat`,
   `OpenEditor.bat` and `tools/run_game.sh` set `APPDATA`/`LOCALAPPDATA` to
   `MPG\appdata`. **Always launch Godot through `tools/run_game.sh` (from a shell) or
   the .bat files, never the exe directly.** `config/custom_user_dir_name` alone does
   NOT move user data off C: (it appends under %APPDATA%). Verify, don't assume.
2. **Milestone gate.** Finish a milestone (or a part the user asks to see), play-test
   it yourself until you are satisfied, then **stop and hand over for the user's own
   test.** Only after they approve: **push to GitHub**, then start the next part.
   Never push untested/unapproved work. Commit locally as you go (small, descriptive
   commits).
3. **"Let's discuss" means discuss.** Do not build anything the user marked "let's
   discuss" in `FUTURE.md` until you have talked it through with them and agreed a
   design. Small clear bug reports can be fixed directly (say so in your report).
4. **`notes/TODO.md` is the live checklist.** Since 2026-09-24 it is pushed to GitHub
   (the user asked, for safety); commit it with the work. Keep it up to date LIVE
   and in DETAIL: a "Right now" line at the top, `[~]` for the item in progress, and
   sub-steps added and ticked as each small piece lands, not only when a whole
   feature is done. The user opens it at any time to see exactly where the work is.
5. **`notes/MASTER_PROMPT.md` (this file) is pushed too** (since 2026-09-24).
6. **Autonomous play-test-and-fix loop.** Play the game yourself with the automated
   play-test (section 5), find problems, fix them, re-test, and only stop when
   everything you can find is fixed or you truly need the user's input. The user does
   not want to be the tester for things you can detect yourself.
7. **Report format at hand-over:** (a) what you could not test, (b) what is done,
   (c) the next step. Plain language; the user is not a professional developer.
   Screenshots from `_shots/` are welcome.
8. **Assets:** CC0 packs are approved (credit them in `CREDITS.md`; keep source zips in
   `assets_src/`, which is gitignored; copy only used files into `FindingNaresh/`). The
   user wants to **agree on the look of every new asset before it is populated** into
   the world (FUTURE item 19) — show them first. Blender use must be discussed first.
9. **Commit attribution:** end commit messages with
   `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
   (or whatever attribution line your environment's instructions specify).
10. Don't spawn sub-agents unless the user asks.
11. **Keep this file current.** Each time a part is finished and tested (not only at
    milestone ends), update sections 2, 4, 6 and 7 here so another model can resume
    from this file alone if the session runs out.
12. **Test runs must not disturb the user** (they watch videos / work meanwhile): use
    `tools/run_test.sh` (window behind all others, focus handed back, muted).
13. **Professional process** (`DESIGN.md` section 6): design first, a gym (test map)
    per mechanic, then greybox in the world, automated tests, dev menu, 144 fps budget.

---

## 4. How the project is built (architecture)

```
MPG/
  Play.bat / OpenEditor.bat     launchers (with the APPDATA redirect)
  tools/run_game.sh             shell launcher with the same redirect (use this)
  tools/godot/                  portable Godot 4.7.1 (+ ._sc_ marker); exes NOT in git
  appdata/                      user:// data (settings, logs, saves) - gitignored
  design/                       plans shown to the user (map_plan_v1.png)
  tools/run_test.sh             the play-test launcher (behind other windows)
  tools/gen/                    generators: glug.py (pour sound), map_plan.py (plan image)
  DESIGN.md                     the agreed design (pushed)
  notes/                        MASTER_PROMPT.md (this file) + TODO.md, both pushed
  assets_src/                   downloaded CC0 packs - gitignored
  FindingNaresh/                the Godot project
    scenes/Main.tscn            one node running Boot.gd
    audio/                      the CC0 sound files actually used
    _shots/                     screenshots from tests - gitignored
    scripts/
      core/Boot.gd              session root: world, players, split-screen, menus
                                (title/pause/load/quit-confirm), device assignment,
                                map explore ticks, save/load entry (load_slot, mark_saved)
      core/InputDevice.gd       per-player input; KEYS/MOUSE/BUTTONS tables; polled in
                                PHYSICS; taps latched from events; glyph() for prompts
      core/SaveGame.gd          journal save slots (JSON in user://saves); collect/apply
      core/ToonMat.gd, Build.gd materials; primitive builders; interact_area()
      player/PlayerRig.gd       first person, carrying, map, journal, seats, footsteps
      items/Carryable.gd        physics items (+ FuelCan, CoolantJug, Crate, MemoryFragment)
      vehicle/Camper.gd         VehicleBody3D van: driving, fuel/temp/coolant/battery,
                                dashboard, nav screen, filler, radiator, rear rack, seats
      vehicle/EngineAudio.gd    CC0 engine loop pitched by a virtual gearbox, starter chug,
                                procedural road roar
      world/Route.gd            spline centrelines (open/closed, pinned junction heights)
      world/RoadNetwork.gd      all roads, nearest queries, chain()
      world/Landscape.gd        height layers; grid-stamped terrain (ArrayMesh +
                                HeightMapShape3D); roads, river, pads; static state
      world/LevelBuilder.gd     the world's layout data + assembly, landmarks, items, poi{}
      world/Spinner.gd          windmill blades / blinking beacon
      map/MapState.gd, PaperMap.gd   shared discovery + stamps; drawn paper map (zoom)
      story/Story.gd            objectives, hints, beats, fragments/roses, flags
      puzzles/CoolingStation.gd water works co-op puzzle
      audio/Sfx.gd, NoiseLoop.gd     sample one-shots by name; procedural steam/wind/water
      audio/Ambience.gd         forest bed + birds (CC0 loops), water emitters, cab muffle,
                                `liveliness` dial for the mood curve
      ui/PlayerHUD.gd, JournalPanel.gd  per-player HUD, notes, objective, journal
      dev/PlayTest.gd           automated play-test (section 5)
      dev/DevMenu.gd            F1 developer menu (teleport, van, spawn, skip, gyms)
      world/GymBuilder.gd       gyms: small flat test maps (extends LevelBuilder)
```

World layout (see `LevelBuilder.gd` consts and its header comment): 4 × 4 km,
sea on the east. Homestead (SW) → Homestead Lane east through the town (Town Fuel) →
P2's home → north to Windmill Junction J1 → Valley Road (Mirror Lake + dock, billboard,
barn) or Ridge Track (gravel, lookout, wreck) → J2 Last Fuel → Pump House Road → water
works → broken bridge → J3 → Ghat hairpins → pass → Beach Road past the coast
watchtower → Bessi loop around the Five Roses (dune by the beach). Way back: Coast Road
→ fishing village → salt pans → estuary bridge → rail tunnel → radio mast → Naresh's
home → West Road home (Tower Road branch past the ending watchtower to P2).
`builder.poi` holds named positions (j1, j2, j3, ghat_pass, facility, bridge,
bridge_barrier_near, roses, beach, memorial, coast_tower(_deck), end_tower(_deck),
p2_home, town_fuel, fishing_village, net_shed, salt_pans, estuary_bridge, tunnel,
tunnel_portal, naresh_home, lookout_deck, dock, shed_roof, pump_handle, valve_a/b,
letter, …).

Story objective chain (`Story.gd`): read_letter → spare_can → to_windmill →
choose_road → refuel → pump_road → coolant → pour_coolant → to_bridge → end_a
("the bridge is out; milestone B"). Milestone B continues from `end_a`.

---

## 5. The automated play-test (your main tool)

- Run: `tools/run_test.sh` (all scenarios) or `tools/run_test.sh name1,name2`. The window
  starts at the screen edge, then PlayTest moves it BEHIND all windows and hands focus
  back (run_test.sh passes the user's window as --refocus); muted unless focused, no
  mouse grab. The user asked for this: runs must not cover what they are doing, but
  they can click the window to watch. `SHOW=1` shows it on screen. Output lines start with `[test]` (`PASS`/`FAIL`, logs,
  `shot test_x.png`). Screenshots land in `FindingNaresh/_shots/test_*.png`; view them.
- It drives the REAL input path (`Input.parse_input_event`): keys, mouse, a simulated
  gamepad on device 0. Add a scenario as `func t_<name>()` in `PlayTest.gd` and add the
  name to the `all` list in `_run()`. Helpers: `tap(KEY_X)`, `key(k, down)`, `mouse()`,
  `pad_axis()`, `pad_button()`, `wait()`, `physics_frames()`, `place_player()`,
  `face_point(p, target, dist, side)`, `van_to(poi)`, `reset_camper(i)`,
  `seat_p1_driver()`, `reset_can(tag, litres)`, `AutoDriver` (keyboard auto-driving
  along a Route; `boot.builder.network.chain([...])` makes a path), `check(ok, what)`,
  `shot(tag)`.
- Every scenario starts via `fresh_hands()` (empty hands, map/journal closed). Order
  matters: `map` runs early because others reveal the map. The `save` scenario reloads
  the scene; the test resumes in `t_save_verify` through static `PlayTest.resume`.
- **Three test levels (agreed with the user 2026-09-24, DESIGN.md section 6.4), to
  be built next:** Quick (default, ~3-4 min: mechanics in the base gym + a world
  smoke check by teleports, no long drives) after every change; Road check
  (`python tools/gen/layout_check.py`, seconds) when roads/hills change; Full
  (quick + `journey` + `routes`, ~35 min) only when roads change and before a
  milestone hand-over. Today `journey` drives ~8 km (~8 of ~18 min), `routes` 16 min.
- **The full suite takes 15–20 minutes** — longer than the 10-minute tool timeout. Run
  it with `run_in_background: true`, redirect `[test]` lines to
  `tools/_last_playtest.log`, and wait with a Monitor/`until grep -q` loop. Only one
  game instance at a time.
- **Real input leaks in** only with `SHOW=1` (quiet runs never get focus); if a check
  fails spuriously, re-run that scenario. Re-run single scenarios to
  confirm before chasing a failure. Tell the user when long runs are going.
- New `class_name` scripts need `tools/run_game.sh --headless --import` once before
  they can be referenced, otherwise "Identifier not declared".
- Also available: `-- --shot` (old capture mode); `t_overview` (top-down orthographic
  map shots) and `t_tour` (landmark screenshots) are great for checking world changes.

---

## 6. What to do next

Continue Milestone B in `notes/TODO.md` ("Foundations"), in this order, keeping it
live and this file current:
1. (done) Gym system. 2. (done) Developer menu. 3. (done) Chunked terrain.
   Still to do there: faster build, and tile the tree/prop scatter (today one
   MultiMesh per type across the whole map: no culling).
4. (done, see section 2) **Greybox the new map** from `design/map_plan_v1.png` (coordinates are in
   `tools/gen/map_plan.py`): three homes, the way out through the Milestone A landmarks
   (moved), the Ghat hairpin road and coast watchtower, the sea and beach, the return
   road (fishing village, salt pans, estuary bridge, rail tunnel, radio mast, Naresh's
   home), the drive home and the ending watchtower. Real-road feel; landmarks visible
   from afar; the paper map must cover the new extent.
5. The beat chart is approved (`design/BEAT_CHART.md`): place its landmarks and
   stops; time each route with AutoDriver runs against it.
6. Keep all existing play-test scenarios passing (update positions as the map moves).
   Tests reach places through `builder.poi[...]`, road names (`network.road(...)`)
   and `builder.route`; keep those names or update the tests with the move.
   Suggested order: set `LevelBuilder.WORLD_EXTENT` to 4000, lay out the new road
   network and landmark positions as data first (as today's consts), tile the
   scatter, move the Milestone A landmarks, then add new places as simple blocks;
   the story objectives for the new opening belong to Milestone C (keep today's
   Milestone A chain working meanwhile). Update `MapState.BOUNDS` and the paper map
   for the new extent. Show the user screenshots (`t_overview`, `t_tour`) at the end.
Then hand over Milestone B (rule 2).
**Next (agreed 2026-09-24, in this order):** (1) build the three test levels (section
5); (2) `design/OPENING.md` v1 is WRITTEN (2026-09-24): get the user's approval and
answers to its three questions, using the opening decisions in `DESIGN.md` section 8 (read-only phone,
fixed-spot puncture with its own gym, a few simple cars in town, enterable P2 house
of two rooms + shed, mother's message starts the story and the letter stays as an
extra, torch batteries from the opening); (3) gyms, then build C. Milestones C-G follow `notes/TODO.md` / `DESIGN.md`.
New mechanics (tagging, binoculars, hiding, creatures, Naresh, storm) each get a gym
first.

---

## 7. Hard-won technical lessons (don't relearn these)

- **Input** is polled in `Boot._physics_process` (before players/van read it); quick
  taps are latched from events in `InputDevice.feed_event`. Polling per render frame
  lost taps at 144 Hz. The dev machine: RTX 3060, 144 Hz 1080p.
- **Physics interpolation is on.** Cameras are placed in `PlayerRig._process` from
  `get_global_transform_interpolated()` and have interpolation OFF. Call
  `reset_physics_interpolation()` after every teleport.
- **Seated players are never reparented** into the van (it launched the van at
  19 000 km/h). They are snapped to seat markers each tick with collision off.
- **VehicleBody3D:** positive `engine_force` pushes this rig toward +Z, so drive forces
  are negated; `steering` is positive-left. **Handbrake model (user-approved):**
  `Camper.parking_brake` toggled by Space/pad B (driver or passenger), P lamp; it is the
  ONLY hold (no auto-hold): off = the van rolls on slopes, even with nobody in it.
  Throttle/reverse with the engine running releases it. With the engine off, S always
  brakes. A van stopped on the handbrake with wheels down is `freeze`d (raycast brakes
  creep). Tests must park with the handbrake (`reset_camper`/`van_to` set it) or the
  van rolls away mid-test (this once cascaded into 18 failures).
- **Terrain** is solved on a 5 m grid: roads and river are stamped segment-by-segment
  (distance + height), mesh is an ArrayMesh, collision is `HeightMapShape3D` (heights
  /STEP, shape scaled by STEP). World build ~1 s (it was 5.8 s with per-vertex nearest
  queries). `Landscape.ground(x,z)` = bilinear on the grid once built. Buildings need
  **pads** (`LevelBuilder.PADS`) or they sit on slopes.
- **Roads/river** follow `Landscape.base_height` (no roads/river) so they never chase
  their own cuts; junction heights are pinned; the road ribbon is omitted over the
  river (bridge decks carry it).
- **Label3D text faces +Z; `Basis.looking_at(t)` points -Z at t.** Signs had their text
  facing away from drivers until this was fixed — aim -Z *away* from the viewer.
- **Carryables**: held items are real bodies steered to a hold point low-right of the
  view; collision exception with the holder; a safety net returns anything that falls
  under the ground to its last resting spot (physics once shot a crate to y = -248).
  `pouring` tilts items at fillers — clear it on drop/throw.
- **CharacterBody**: keep the intended horizontal velocity (`_plan_vel`) rather than
  the post-collision velocity, or you can never jump onto a crate you are touching. A
  two-crate stack is a wall; climbing needs a staircase (1 crate, then 2).
- **Interactables**: metas on Area3D/bodies: `prompt`, `prompt_fn(player)`,
  `blocked_fn()` or `blocked_fn(player)`, `callback(player)`, `hold_fn(player, dt)`,
  and for held items `held_prompt_fn(player, item)` + `held_action(player, item, dt,
  first)` + `pour` flag. Hold-to-use continues while E is held and you stay within 3 m.
- **Editing files from the shell:** heredocs with backslashes and `\n` inside Python
  strings got mangled by the shell repeatedly. Write patch scripts with the file-write
  tool (Python with raw strings `r'''...'''` and `assert old in s` before replacing),
  run them, then delete them from `tools/`.
- **GDScript** can't infer types from Variant sources (`var x := dict["k"]`, `get_node`
  results, ternaries with untyped sides): give explicit types.
- **Godot editor** rewrites `project.godot` (drops comments/defaults) when the user
  opens it — that's fine.
- **Audio**: `Sfx.play3d(name, pos, db)` picks a random CC0 variant; `NoiseLoop` for
  procedural loops (silent ones push zero buffers, cheap). Looping imported WAVs: set
  `loop_mode`/`loop_end` on a duplicate at runtime. You cannot listen: verify sounds by
  state (playing, pitch, gain) in tests and ask for the user's ears. CC0 sources that
  worked: Kenney packs, OpenGameArt (check each page's licence; curl into
  `assets_src/`; `C:/Windows/System32/tar.exe` extracts .7z). Pillow and numpy exist in
  the system Python; do NOT pip install (C: drive rule).
- **Camera far plane** is 2600 m (backdrop ridges); fog ends at 1500 m.
- **Players knocked by the van**: `PlayerRig.knock(impulse, van)` (collision exception
  until clear); `Camper._check_pedestrians` detects just ahead of the hull, because a
  kinematic player would stop the van dead.
- **Split-screen shots**: `shot()` captures the window; with one keyboard only the
  keyboard owner's view shows. `tap(KEY_TAB)` switches whose view is shown.
- **Gyms**: GymBuilder must provide what other systems read from a builder: `network`,
  `route` (AutoDriver, reset_camper), `river` (MapState), `poi` ("homestead",
  "camper_spawn"), `camper_spawn`, `player_spawns`. Story and MapState skip their
  world-specific parts when `boot.gym != ""`. In gyms PlayTest runs only `["gym"]`.
- A van dropped onto a slope needs ~2 s to settle on its springs before it freezes;
  measure holds after that.
- **Mirrors are expensive**: every SubViewport camera re-renders the world incl.
  directional shadow cascades, with a fixed cost (far plane made no difference). All
  three every frame: 58 fps; one per frame: 109; one every 2nd frame: ~130. Any new
  render-to-texture (binoculars, CCTV, photo) must budget for this the same way.
- **Private visual layers**: layer `1 << (1 + i)` is masked out of player i's camera
  only. Use it to hide things from one player (own avatar, the nav when aside).
- Performance: ~130 fps with both views while driving (mirrors on); keep >= 120.
- **Terrain winding:** tile triangles are wound [a, a+1, c] so faces point up.
  The old [a, c, a+1] order made the double-sided material flip the normals: the
  ground was lit as if the sun were below it (flat sand looked dark khaki). The
  terrain albedo is 0.6 to keep the approved brightness under full sun.
- **Road profiles** (`Route` smooth_m/max_grade): the ground noise alone has ~20 %
  slopes, so roads blur the ground over 150 m and then clamp to 10 % (gravel 15,
  ghat 9); junction heights are the mean ground over a 50 m disk. Check a layout
  with `python tools/gen/layout_check.py` before building it.
- **Tunnels**: a road whose profile ignores a hill (height_fn minus that mound)
  gets `Route.tunnel` flags where the ground is > 9 m above it; the terrain is only
  cut as a narrow slot there (TUNNEL_FLAT/BLEND) and `_tunnel()` builds walls, a
  roof and earth fill over it. No heightmap holes needed.
- **Build time traps:** adding thousands of shapes to one body then reparenting
  them is O(n²) (scatter took 94 s); create per-tile bodies up front. The terrain
  grid solve pre-filters hills/lakes/pads per row (`_base_fast`).
- The coast blend must not leave a step at its inland edge (a line of "white
  dashes" in overhead shots was exactly that).

---

## 8. Resuming in a new thread

Read the files listed at the top, check `git status` / `git log -3`, read `notes/TODO.md`'s
"Right now", tell the user in two or three plain lines where things stand and what you
will do next, then continue section 6. Do not redo finished items.
