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
Last updated: 2026-09-25, Milestone D started (plan approved, tagging gym).
Milestones A, B and C are done. A ChatGPT session built the opening; a Claude
session reviewed it, fixed what it and the user's test found (see TODO.md,
"Review fixes" and "P2's side fixed") and added `opening_full` and
`opening_p2`. Next is Milestone D.
Start at section 6.

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

## 2. Status right now (2026-09-25)

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
  - full play-test after mirrors: 180 checks, 0 failures, ~130 fps;
  - **4 x 4 km greybox done** (second thread): layout data in `LevelLayout.gd`
    consts (was `LevelBuilder.gd`), mirrored in `tools/gen/layout_check.py` (checks grades/cuts/gaps,
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
- **Cloud PRs #1–#6 reviewed and merged into `main` (2026-09-24):** #1 added
  Linux headless tests and GitHub CI; #4 fixed nine bugs (including the steam
  cloud and controller disconnect) and added `notes/CODE_REVIEW.md`; #5 made
  world building about 1.5 times faster with identical generated world data;
  #6 split LevelBuilder into five files without intended behavior changes;
  #2 added valve B's two kick-backs and `design/PUZZLES.md`; #3 added five
  design proposal pages for D/E/F, creatures and Naresh. A follow-up to #6
  fixed the layout test for a connected P2 pad and restored its starting layout.
  All six GitHub PRs are closed as merged. Local `main` was pulled after #3.
  The last complete windowed run, on the #2 preview with the pad connected,
  recorded **191 passes, 0 failures**. The #3 docs-only preview was stopped
  after 161 passes, 0 failures because a full gameplay run was unnecessary.
  The valve B feel remains a human judgment; the user chose the automated
  result only for this review. Treat the new design pages as proposals, not
  approved implementation decisions.
- **Three test levels done locally (2026-09-25, not pushed):** scenario timing
  added to `PlayTest.gd`. Baseline old suite: 951 seconds of scenarios, zero
  failures (`journey` 488 s, `waterworks` 91 s, `lap` 69 s). Default
  `tools/run_test.sh` now runs basic mechanic checks in the base gym, then
  teleported world checks: Quick 265 s (~4.5 min), zero failures, no script
  errors. `tools/run_test.sh full` runs the gym plus the old broad world suite
  and all eight roads: 2010 s (~33.5 min), zero failures, no script errors.
  `python tools/gen/layout_check.py` takes ~2 s, "no problems". A screenshot
  review found the fading control reminder over the objective in split view;
  it was moved to bottom right and checked on foot and in both seats (0
  failures). Current local commits are beyond the merged cloud PRs; do not
  push before the user's milestone approval.
- **Milestone C started:** `notes/TODO.md` has the approved opening's detailed
  checklist. The tyre gym has a fixed trap, a physical spare-wheel swap, flat
  handling and a 20% handbrake slope. Its 17 checks pass in 33.5 s; the
  default Quick repeat including it finished with zero failures and script
  errors. The world puncture is after Town Fuel; its story-gated teleport
  check passes (three checks). The house gym then passed 15 checks: battery
  search and torch, doors, shed, full can, real stair walk and window sightline.
  The same house now replaces P2's world block, and Town Fuel has a working
  pump; seven world checks pass. Traffic gym passed three obstruction checks;
  four cars are placed on the town lane and six world checks pass. P2's drive
  measures 20.9%, holds the van with the handbrake and rolls it without one;
  the terrain joins the slab and its screenshot was inspected. The default
  Quick repeat across all three opening gyms, base gym and world passed with
  zero failures and no script errors. The phone, per-player objectives, split
  start, pick-up and save/load of the opening followed.
- **Milestone C review (2026-09-25, Claude):** eleven fixes to the earlier
  work, listed in `notes/TODO.md` under "Review fixes" (controller journal
  button, Town Fuel off the road, town cars jamming, gym crash, tyre and nail
  visuals, phone redesign, test helper bugs). `opening_full` plays the whole
  opening with the real controls: see TODO.md for its timing. The user's test
  then found P2's house unusable (stairs, doors, drive lip) and the nails
  gated behind the refuel; fixed, `opening_p2` added to Quick (P2 walked for
  real), and Milestone C was approved and pushed.

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
9. **Commit attribution:** use only attribution that truthfully reflects the
   contributor and follows your environment's instructions.
10. Don't spawn sub-agents unless the user asks.
11. **Keep the notes current at every step, not only at part ends** (user, 2026-09-24:
    a thread can stop at any moment and the next one must carry on seamlessly).
    - Before starting a task: write it in `notes/TODO.md` "Right now" and mark it `[~]`.
    - After every finished sub-step or test run: tick it, add the result (pass/fail,
      numbers, what was fixed) and what comes next.
    - Every time a part is finished and tested: also update sections 2, 4, 6 and 7
      here, and add any hard-won lesson to section 7.
    - Commit locally often (small commits), so an unfinished change is always either
      committed or visible in `git status` / `git diff` for the next thread.
    - Pushing still follows rule 2 (only approved work), except when the user asks
      to push the notes.
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
  design/                       map, beat chart, approved opening; D/E/F and
                                puzzle/creature/Naresh proposals
  tools/run_test.sh             the play-test launcher (behind other windows)
  tools/gen/                    generators: glug.py (pour sound), map_plan.py (plan image)
  DESIGN.md                     the agreed design (pushed)
  notes/                        MASTER_PROMPT.md, TODO.md, CODE_REVIEW.md
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
      world/LevelBuilder.gd     the world's assembly (build order, roads, spawns, items);
                                split by job, each file extending the one before:
                                LevelLayout (layout data, poi{}, helpers) -> LevelScatter
                                (trees, rocks, backdrop) -> LevelPlaces (greybox places)
                                -> LevelLandmarks (Milestone A landmarks, signs) -> LevelBuilder
      world/Spinner.gd          windmill blades / blinking beacon
      map/MapState.gd, PaperMap.gd   shared discovery + stamps; drawn paper map (zoom)
      story/Story.gd            objectives, hints, beats, fragments/roses, flags
      puzzles/CoolingStation.gd water works co-op puzzle
      audio/Sfx.gd, NoiseLoop.gd     sample one-shots by name; procedural steam/wind/water
      audio/Ambience.gd         forest bed + birds (CC0 loops), water emitters, cab muffle,
                                `liveliness` dial for the mood curve
      ui/PlayerHUD.gd, JournalPanel.gd  per-player HUD, notes, objective, journal
      dev/PlayTest.gd           automated play-test (section 5)
                               Quick/Full presets and per-scenario elapsed time
      dev/DevMenu.gd            F1 developer menu (teleport, van, spawn, skip, gyms)
      world/GymBuilder.gd       gyms: small flat test maps (extends LevelBuilder)
```

World layout (see the consts in `LevelLayout.gd` and `LevelBuilder.gd`'s header comment): 4 × 4 km,
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

- Run: `tools/run_test.sh` (Quick, ~4.5 min), `tools/run_test.sh full`
  (~33.5 min), or `tools/run_test.sh name1,name2` (selected world scenarios). The window
  starts at the screen edge, then PlayTest moves it BEHIND all windows and hands focus
  back (run_test.sh passes the user's window as --refocus); muted unless focused, no
  mouse grab. The user asked for this: runs must not cover what they are doing, but
  they can click the window to watch. `SHOW=1` shows it on screen. Output lines start with `[test]` (`PASS`/`FAIL`, logs,
  `shot test_x.png`). Screenshots land in `FindingNaresh/_shots/test_*.png`; view them.
- It drives the REAL input path (`Input.parse_input_event`): keys, mouse, a simulated
  gamepad on device 0; a physical P2 pad can also be connected. Add a scenario
  as `func t_<name>()` in `PlayTest.gd` and add the
  name to the `all` list in `_run()`. Helpers: `tap(KEY_X)`, `key(k, down)`, `mouse()`,
  `pad_axis()`, `pad_button()`, `wait()`, `physics_frames()`, `place_player()`,
  `face_point(p, target, dist, side)`, `van_to(poi)`, `reset_camper(i)`,
  `seat_p1_driver()`, `reset_can(tag, litres)`, `AutoDriver` (keyboard auto-driving
  along a Route; `boot.builder.network.chain([...])` makes a path), `check(ok, what)`,
  `shot(tag)`.
- Every scenario starts via `fresh_hands()` (empty hands, map/journal closed). Order
  matters: `map` runs early because others reveal the map. The `save` scenario reloads
  the scene; the test resumes in `t_save_verify` through static `PlayTest.resume`.
- **Three test levels (done 2026-09-25):** Quick (default, ~4.5 min): basic
  input/vehicle checks in the base gym, then world map, story, water works,
  carrying, controller, performance and save/load by teleport. Road check:
  `python tools/gen/layout_check.py`, ~2 s, when roads or hills change. Full:
  `tools/run_test.sh full`, ~33.5 min (gym, old broad suite, `journey`, all
  eight routes), when roads change and before a milestone hand-over.
- On this Windows PC, invoke
  `tools/run_test.sh` through Git Bash, capture the output to a log, and keep
  only one game instance running. Read the `[test]` PASS/FAIL lines and the
  final failure count; Godot warnings on stderr can make a PowerShell pipeline
  report exit code 1 even when the suite passes. The script now exits nonzero
  if any test check fails.
- **Real input leaks in** only with `SHOW=1` (quiet runs never get focus); if a check
  fails spuriously, re-run that scenario. Re-run single scenarios to
  confirm before chasing a failure. Tell the user when long runs are going.
- New `class_name` scripts need `tools/run_game.sh --headless --import` once before
  they can be referenced, otherwise "Identifier not declared".
- **Headless (Linux / GitHub, since 2026-09-24):** `tools/run_test_headless.sh
  [scenarios]` runs the same play-test with no window or GPU, `--fixed-fps 60`
  (deterministic: every frame is one 1/60 s physics step), Quick by default.
  Screenshots are skipped and frame-rate / audio checks only logged
  (`PlayTest.headless`). GitHub runs it plus the road check on every push
  (`.github/workflows/playtest.yml`). Use it for logic; keep `tools/run_test.sh`
  for looks, sound and fps. The headless script requires a Linux Godot binary;
  this Windows PC uses the windowed script locally and GitHub runs the Linux job.
- Also available: `-- --shot` (old capture mode); `t_overview` (top-down orthographic
  map shots) and `t_tour` (landmark screenshots) are great for checking world changes.
- **Connected-pad windowed runs:** the `layout` test now handles P2's physical
  controller and restores the initial view layout before `pad`. If the Godot
  window is minimized, physics stops and the suite can appear to hang; restore
  it behind other windows before diagnosing a test timeout. Automated pad events
  verify actions but cannot establish whether a mechanic feels fun.

---

## 6. What to do next

**Milestone C is approved and pushed. Next, in this order:**

1. Milestone D, the way out (`notes/TODO.md` D1-D13, `DESIGN.md`,
   `design/WAY_OUT.md`, `design/CREATURES.md`). **Both pages were approved on
   2026-09-25** with every recommended answer (their "Decisions" sections).
   Gyms first (tagging, binoculars, stealth, creatures), then traffic, mood
   and the places.
2. Then Milestones E-G follow `notes/TODO.md` / `DESIGN.md`.
   New mechanics (tagging, binoculars, hiding, creatures, Naresh, storm) each get a
   gym first. The merged `design/PUZZLES.md`, `design/WAY_OUT.md`,
   `design/CREATURES.md`, `design/NARESH.md`, `design/BESSI.md` and
   `design/RETURN.md` are proposals; discuss their open questions before building
   their suggested choices.

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
- **Split-screen shots**: `shot()` captures the window. With no connected pad,
  solo view shows the keyboard owner's view and TAB swaps the keyboard/view.
  With P2 on a pad, TAB leaves the keyboard with P1; use a split layout to
  inspect both views.
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
- **World build speed (2026-09-24, cloud):** ~7.0 s -> ~4.7 s headless with the
  world bit-for-bit the same (hashes of the height/road/river grids, normals,
  colours, every tile mesh array and every scatter transform/colour/collider
  compared before and after). Noise factors per row/column (64-bit, same
  expression order), tile index lists shared, the scatter's grid lookups by
  hand, scatter colliders as shape owners instead of 59 000 CollisionShape3D
  nodes. Tried and dropped: filling MultiMeshes from one buffer (slower to
  build in script than the per-instance calls, and not measurable headless).
- **Headless runs:** `frame_post_draw` never fires (so `shot()` returns early),
  viewport textures are null, and MultiMesh instance transforms read back as
  zero (use `builder.scatter[...]`). Without `--fixed-fps` a slow CPU runs
  physics behind real-time waits and timing checks fail at random.
- **Mouse look reads `screen_relative`**, not `relative`: `relative` is scaled by
  the canvas_items stretch, so look speed changed with the window size.
- The coast blend must not leave a step at its inland edge (a line of "white
  dashes" in overhead shots was exactly that).
- **Full preset order:** save/load reloads the scene and ends the test process,
  so `routes` must run before `save`. The launcher runs the gym as a separate
  process before the world; do not overlap game instances.
- **Test helpers vs input latching:** `InputDevice.feed_event` latches every
  pressed event as a tap, so re-sending a held key each tick reads as 60 taps
  a second. `hold_physics` only re-sends a press that a focus change dropped,
  and waits 3 ticks after release (a pour holds the can at the filler until
  the release lands). Never edit PlayTest.gd while a run is going: later
  segments load the file fresh.
- **Teleporting players (`go_to`)**: cast down from just above the target's
  own height, or inside the house you land on the upper floor.
- **Driving into P2's drive:** the auto-driver's 8-12 m look-ahead cuts the
  90-degree corner onto the bank. Feed it a turning arc (9 m tangents) and a
  short look-ahead; check the van is on the slab (across < 1.4 m), not just
  near the house.
- **Walk, don't teleport, to find layout bugs:** `walk_to` turns the player
  and holds W tick by tick, logging and screenshotting where they get stuck.
  Teleport-based checks (`go_to`, `face_point`) passed while P2 could not get
  out of the house or onto the stairs. Every walkable space gets a walk test.
- **Terrain under narrow features:** the terrain grid is 5 m, so anything
  narrower (the 4.6 m drive) needs the terrain lowered at least one grid step
  either side, or the triangles between vertices poke through it.
- **Town traffic clearance:** the van is 2.24 m wide; cars sit 2.4 m off the
  centre and look ahead with a 1.8 m box, so a van down the middle passes.
- **Split HUD:** the top-left objective and top-centre fading controls
  overlapped in 800 px views. The controls now wrap at bottom right, clear of
  the gauges. Checked on foot and from both seats.

---

## 8. Resuming in a new thread

Read the files listed at the top, check `git status` / `git log -3` (and `git diff` if
anything is uncommitted: that is the last thread's unfinished work), read
`notes/TODO.md`'s "Right now" and the `[~]` items, tell the user in two or three plain
lines where things stand and what you will do next, then continue from exactly there
(section 6 for the order). Do not redo finished items. From then on follow rule 11:
keep `notes/TODO.md` and this file current after every step, so the thread after you
can resume the same way.
