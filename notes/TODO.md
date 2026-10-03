# Finding Naresh: build checklist

Pushed to GitHub with the work (since 2026-09-24, for safety).
`[x]` done and tested · `[~]` being worked on now · `[ ]` not started.
Updated live as each small step lands (sub-steps are added under an item while it is
being built and tested), so this always shows where the work is right now.

## Right now
- Milestones A-E: done, each part tested and approved by you, full run
  clean, **pushed** (Milestone E finished 2026-09-29, main `8c18ef3`).
- **Milestone F, the return.** Your answers to `design/RETURN.md`
  (2026-10-01): the storm road a brutal dead end; the dishes point at nearer
  return sites; the family silent; the tracker = maze, relay, flare gun,
  fragments. F split into F1-F9 below.
- F1 the storm gym: **approved by you (2026-10-01, with its 8 decisions)
  and pushed.**
- F2 (the storm on the old road, the dead end at the bridge): **approved by
  you (2026-10-01, its 5 decisions) and pushed**, with the fix from your
  test (the rain followed P2 left at J3).
- F3 the fishing village (the decoy): pushed (2026-10-01) on your "all good",
  but **not tested by you yet** (you said so after the push).
- **Working mode for the rest of F (you, 2026-10-01):** build F4-F9 with my
  recommended answers (listed as "Decisions to confirm" in
  `notes/TEST_MILESTONE_F.md`); **your test comes once F is finished, from
  F3 onwards**. New parts stay local in main (not pushed) until that test.
- F4 the salt pans, F5 the estuary bridge: built (local, `../MPG_dev` branch `f4`).
- F6 the rail tunnel: built (local).
- F7 the radio mast: built (local).
- F8 Naresh's home and the ending: built (local).
- **F9 done:** the whole return drives end to end (7.5 min of roads); the full run's 24 failures fixed and rerun clean (2026-10-02). 
- [~] **Before your test: I walk the test sheet F3-F8 blind** (you, 2026-10-02:
  you found the binoculars missing after the F3 jump; my test had given them
  in code). Real keys and pad only, nothing set in code. Then you test.
  - [x] Fixed: F1 jumps to Bessi / return steps give the binoculars; the
        flare gun's prompt says "Fire a flare"
  - [x] First blind walk of F3 (scripted, open loop): it got to "Go and
        wait there" on the jetty end; Naresh never reached it; everything
        after failed for that reason
  - [~] **New way of testing (agreed 2026-10-02):** a live control line into
        the running game (one action at a time, result + state + screenshot
        back at once), fail-fast scripted runs that keep the game open, a
        walked part saved as its regression (`notes/ROUGH_NOTES.md`)
  - [x] F3 walked live: ~10 bugs fixed (the jetty rails caught the aim,
        Naresh's way on / off the jetty, world drop points, the light-can
        trip retried, ...); the sheet's F3 steps rewritten
  - [~] **The watched run (v4, agreed 2026-10-02, `notes/TESTING_METHOD.md`)**:
        planned steps with expected outcomes, checked in parallel in the
        game, stop on the first failure, resume from that step's save point.
        F3 as `tools/live/f3.json` (made by `tools/live/make_f3.py`)
  - [x] F3-F8 each walked as a watched run, every step passing (2026-10-03).
        Game bugs they found and fixed: Naresh couldn't plan beyond ~60 m
        (walked into walls; now in stages); he wandered off / kept acting
        with creatures near as you got in the van; the tunnel gallery's
        creature went for the van through the wall; the hill filled the
        gallery's side passages (flare gun buried); the flare case wasn't
        solid; getting into the van with the flare gun dropped it on the
        road; jumps past the tunnel gave no flare gun; the F7 sheet's "tell
        him again" didn't say how. All in `notes/ROUGH_NOTES.md`.
  - [x] Before your test (2026-10-03): every walk F3-F8 back to back
        passes (24 min); the full suite's 72 world scenarios pass (the
        frame-rate checks rerun alone: 144 fps; the decoy test after the
        creature fixes; the lightning check made robust). Merged into main
        locally, **not pushed**.
  - [ ] Your test from F3 on (the sheet updated with what the walks found)
- Command key (Naresh): **V** / **D-pad Up**.

## Tooling
- [x] Cloud PR integration (2026-09-24): #1 headless/CI, #4 nine review fixes,
      #5 world build speed, #6 LevelBuilder split, #2 water works valve B,
      #3 design proposals; merged and pulled in dependency order
  - [x] Last complete windowed run on the #2 preview with a controller connected:
        191 passes, 0 failures; two valve B kick-backs. The automated test cannot
        judge whether they feel fun to a human player.
  - [x] #3 adds only five Markdown pages; its merge was checked. A redundant
        windowed run was stopped after 161 passes, 0 failures.
- [x] Three test levels (agreed 2026-09-24): Quick (~4.5 min, mechanics in gyms +
      a teleport check of the real map) after every change; Road check (layout
      script, seconds); Full (~35 min, long drives) only when roads change and
      before a hand-over. First step: time every scenario to see where it goes
  - [x] Log elapsed time for each scenario; baseline windowed suite: 951 s of
        scenarios, 0 failures. `journey` 488 s; `waterworks` 91 s; `lap` 69 s.
  - [x] Mechanic checks in base gym and teleport checks in the world. Quick
        passed: 265 s of scenarios (~4.5 min), 0 failures, no script errors;
        gym segment was 77 s. The world segment includes map, story, water
        works, carrying, controller, performance and save/load.
  - [x] `full` includes the gym pass, old world suite, `journey`, and `routes`;
        2010 s of scenarios (~33.5 min), 0 failures and no script errors.
  - [x] Road check: `python tools/gen/layout_check.py` completed in 2 s with
        "no problems" (2026-09-24).
  - [x] Verify Quick and Full, update README and handoff notes. Quick and Full
        each finished with 0 failures; `routes` drove all eight legs before save.
  - [x] Moved the fading control reminder to bottom right in split views;
        on-foot gym and both van seats checked in screenshots, 0 failures
- [x] Play-test runs stay off your screen (2026-09-24)
  - [x] `tools/run_test.sh`: window opens off screen (x = 4000), 1600x900
  - [x] Muted, never takes keyboard focus, never grabs the mouse
  - [x] Tested: short run while you had YouTube in front; focus stayed on your
        window, screenshots still render, 0 failures
  - [x] `SHOW=1 tools/run_test.sh ...` to watch a run on screen with sound
- [x] Test window you can click to watch (2026-09-24)
  - [x] Window moves behind your windows (centred) and focus goes back to what you
        were using; ~3 s at start-up where it is at the screen edge
  - [x] Sound on only while you have it focused
  - [x] Tested 3 runs while you were using Opera / T3 Code: 0 failures, your window
        stayed in front

## Stage 1: look-and-feel prototype
- [x] Split-screen, per-player input, first-person movement, flashlight
- [x] Drivable camper: seats, dashboard, fuel, temperature, battery
- [x] Feel pass (input, camera, cockpit, collisions, parking, recovery, sensitivity)
- [x] Automated play-test (`scripts/dev/PlayTest.gd`)
- [x] User data kept off C:
- [x] Pushed to GitHub (`main`)
- [x] `FUTURE.md` with the post-demo open-world ideas

## Milestone A: Beats 1–3 (homestead → road trip → water facility)
### A1. Journey map
- [x] Road network: several roads with junctions (replaces the single loop)
- [x] Route choice at the first junction: long scenic valley road vs steep ridge shortcut
- [x] Lake and river, with a bridge where the road crosses
- [x] Bessi valley at the far end (existing loop + Five Roses hill)
- [x] Landmarks along the way (lookout, windmill, wrecked car, signs, info boards)
- [x] Play-test: drive the whole journey by keyboard without leaving the road
  - Also: world build 5.8 s -> 1.0 s (grid-stamped terrain, height-map collision),
    meadows + wildflowers, climbable lookout tower, signs face drivers.
### A2. Hands
- [x] Pick up, carry, drop and throw objects (weighty, not floaty)
- [x] Fuel cans: carry to the van, pour into the fuel inlet
- [x] Camper storage slots for cans and supplies
  - Also: cans at the homestead garage + Last Fuel (one empty), van starts on
    26 L so the first refuel happens at Last Fuel; cargo weight raises fuel use.
### A3. Paper map
- [x] Raise and lower the map (M / D-Down on pad) on foot or in a stopped van
- [x] Hand-drawn map of terrain, roads, water and landmarks, no position marker
- [x] Shared stamps: fuel, danger, puzzle, shortcut, unexplored
- [x] Info boards reveal map sections
  - Also: map fills in as you travel (roads chunk by chunk, landmarks from
    ~130 m); printed contours show the hills; folds away if the van moves off.
### A4. Story opening
- [x] Parents' note / phone messages at the homestead (Naresh left "with a friend")
- [x] Objective line plus hold-to-show hints
- [x] Explanation of the no-checkpoint save rule before leaving home
### A5. Water facility
- [x] Overheat that makes sense on the climb to the facility
- [x] Cooling-station co-op puzzle (valves + noisy pump + pressure gauge) → coolant + fragment
- [x] Optional Memory Fragment puzzle nearby
- [x] First clues that contradict the "friend" story
  - Also: building pads (flat yards), item safety net (nothing lost under the
    ground), handbrake on an empty van, crate staircase climbing, fragments on
    both routes (dock, lookout) so a first rose is reachable.
### A6. Saving and menus
- [x] Memory Fragments → Memory Rose (3 fragments each)
- [x] Save at the parked camper's travel journal (costs 1 rose, cost shown first)
- [x] 3 save slots and a load menu; restores players, van, cargo, puzzles, map, story
- [x] Main menu (new game / load / quit) and input-assignment screen
- [x] Warn before quitting with unsaved progress
### A7. Sound and credits
- [x] CC0 sounds (footsteps, pickup, pump, pouring, doors, UI)
- [x] `CREDITS.md` for every third-party asset
### A8. Wrap-up
- [x] Play-test scenarios for everything above, all passing
- [x] README updated
- [x] Also fixed from FUTURE.md notes: #10 map zoom + nav follows your stamp,
      #11 idling fuel/heat, #14 engine-off van stays put, #15 can tips when pouring,
      #16 coolant gauge, #25 mountains off the map + world edge
- [x] Hand over for your feel verdict (approved and pushed, 2026-09-23)

## Plan (agreed 2026-09-24; details in `DESIGN.md`)
Each mechanic is built first in its own gym (test map), then greyboxed into the world.
Every milestone ends with my play-test, then your test; push only after you approve.

## Small fixes (before milestone B)
New play-test scenario `fixes` checks all of these.
- [x] ESC closes the paper map and the message box (and the journal); pauses only
      when nothing is open. Tested.
- [x] Green backdrop blobs replaced by long, hazy wooded ridges (same haze as the
      mountains, tree tops on top); view distance 1.8 -> 2.6 km so they draw fully.
      Checked in the landmark tour screenshots.
- [~] Better engine sound
  - [x] CC0 recorded engine loop (OpenGameArt, domasx2) instead of the synth
  - [x] Virtual gearbox: revs climb and drop at each shift (tested: drops counted)
  - [x] Starter chug on ignition; louder under load; tyre roar kept
  - [ ] Your ears: I can't listen, so this needs your verdict
- [x] Partner's avatar fits inside the van: seated pose, slimmer, under the roof.
      Tested with a screenshot from the passenger seat.
- [x] Pour sounds: nothing from an empty can; new glugging loop (made here, no
      samples) plays only while liquid flows. Tested both.
- [x] Wheels stop turning when the van stands still (and when the handbrake locks them).
      Tested.
- [x] Van knocks a player flying (farther the faster), tumble + dust + thud, back up
      after 1-4 s. Tested at 36 km/h: thrown 10 m, van keeps going.
- [x] Brakes: S much stronger (60 km/h to stop in ~17 m, was ~40 m). Tested.
- [x] Real handbrake (Space / pad B, driver or passenger): P lamp on the dash, holds on
      the steepest slope, van rolls when it is off (engine on or off, driver or not),
      driving off with the engine running releases it. Tested.
- [x] Nature sounds (#21): forest bed + birdsong (CC0 recordings) under the wind,
      babbling water along the river and at Mirror Lake, all quieter inside the van.
      A `liveliness` dial is ready for the story's mood curve (birds go quiet first).
      Tested: playing, water audible at the dock. Your ears needed for the mix.
- [x] Full play-test run: 171 checks, 0 failures, 144 fps driving with both views.
      (First run found the old tests parked without the handbrake, so the van
      rolled away at the water works; tests now park properly. It also found a real
      bug: with the engine off, S did not brake a van rolling backwards. Fixed.)
- [x] Your test and approval (2026-09-24: "looks good"); pushed

## Milestone B: Foundations (dev tools + the bigger world)
- [x] Mirrors (your request, 2026-09-24): two door mirrors + a rear-view mirror
  - [x] Small cameras looking back, shown flipped on the glass; only while someone
        is in the van; take turns redrawing (each ~24 times a second)
  - [x] Cost: 144 fps -> ~130 fps with both views driving (all three every frame
        was 58 fps). A "mirror quality" option can go in the settings menu later.
  - [x] Tested: all three show a picture; screenshots from the driver's seat
- [x] Nav screen swing (your request): N / pad A from either seat swings it to the
      passenger; then the driver's view cannot show its text. Tested both views.
- [x] Gym system: `--gym=<name>` loads a flat test map with a measuring grid
  - [x] `base` gym: 10 m grid, road loop + straight, 5/10/20 % slopes, cans, jug,
        crates, a wall to hide behind (`world/GymBuilder.gd`)
  - [x] `GYM=base tools/run_test.sh` runs the gym's own play-test (`t_gym`): level
        floor, slopes measured, handbrake holds on 20 %, van laps the loop. Passes.
  - [x] Found and fixed on the way: a van dropped onto a steep slope could settle a
        few cm before locking; a parked van now stays locked once frozen.
- [x] Developer menu (F1): teleport to any named place, bring / fix the van, spawn
      cans and crates, skip an objective, switch world <-> gym. Tested (`t_dev`).
  - [ ] Weather, time of day, creatures, Naresh: added when those systems exist
  - [ ] Not auto-tested: switching world <-> gym from the menu (reloads the scene)
- [x] Terrain in chunks so a ~4 x 4 km map stays fast (144 fps budget)
  - [x] 250 m tiles, full 5 m detail near, 20 m version (with skirts) past 800 m
  - [x] World size is now a setting (`--extent=4000` for load tests)
  - [x] Tested: today's world looks the same (tour + overview shots), 144 fps;
        4 km stress test: 144 fps with both views driving, world builds in 4.8 s
  - [ ] Later: faster world build (4.8 s at 4 km), trees/props split into tiles too
        (they are one big batch each today; needed once the map is 4 km)
- [x] One-page layout plan: the three homes, the way out, Bessi beach on the coast,
      the return road, the storm road, landmarks visible from afar
  - [x] Draft v1 drawn: `design/map_plan_v1.png` (made by `tools/gen/map_plan.py`)
  - [x] Approved by you ("looks good for now", 2026-09-24)
- [x] Beat chart for each route (something interesting every 2-3 min)
  - [x] Draft v1: `design/BEAT_CHART.md` (~60 min first play)
  - [x] Approved by you ("happy", 2026-09-24)
- [x] Greybox the new map (roads with real-road splits and long loops, the existing
      Milestone A landmarks moved into it)
  - [x] Layout as data: roads, hills, lakes, river, coast (checked by
        `tools/gen/layout_check.py`: grades <= 10 % (gravel 15 %), cuts and fills
        <= 9 m, gaps between roads; draws `design/greybox_layout.png`)
  - [x] Roads engineered like real ones: smoothed over 150 m and held to a grade
        limit (cut and fill), junctions at the average ground level
  - [x] World size 4 km; sea, beach and coastline (knee-deep, then a wall)
  - [x] Trees and props split into 500 m tiles, faded out by distance
  - [x] World builds in ~7 s (first try took 103 s: tree colliders fixed,
        terrain solve 8 s -> 3 s)
  - [x] Milestone A landmarks moved (homestead, windmill, lake, barn, lookout,
        wreck, Last Fuel, water works, bridge)
  - [x] New places as blocks: P2's home, town + town fuel, ghat hairpins, coast
        watchtower, Bessi beach + Five Roses, fishing village, salt pans,
        estuary bridge, rail tunnel (road runs under Tunnel Hill), radio mast,
        Naresh's home, ending watchtower
  - [x] Paper map covers 4 km (sea printed blue, 500 m scale bar, zoom to 6x);
        signs and info boards
  - [x] Found and fixed: the ground was lit as if the sun were below it (its
        triangles faced down); hills now shade properly, colours kept close
  - [x] All play-test scenarios pass on the new map (180 checks, 0 failures,
        144 fps driving with both views); overview + tour shots of every place
  - [x] Found and fixed on the way: a player could spawn inside a tree at the
        homestead; the lake sound was out of earshot of the bigger lake; fuel
        use halved to suit the bigger map (~17 km on a tank)
- [x] Play-test: drive every route, time it against the beat chart
      (`tools/run_test.sh routes`: all 8 legs driven, 16 min of pure driving at
      ~60 km/h; opening 1.8, valley 1.8, ridge 0.9, pump road 0.8, ghat + beach
      2.1, coast road 5.1, west road 2.2, tower road 1.3 min. At players' ~45
      km/h this is close to the beat chart's driving times)
- [x] Your test and approval ("tested all good", 2026-09-24); pushed

Cloud follow-ups after Milestone B: world build improved from about 7.0 s to
4.7 s headless with identical generated world data; LevelBuilder was split into
five scripts without intended gameplay changes. The controller-aware layout
test was fixed and now restores its starting layout before the pad test.

## Milestone C: The opening (split tutorial, 5-10 min)
- [x] Decisions agreed (2026-09-24, `DESIGN.md` section 8): read-only phone;
      puncture at a fixed spot (own gym); a few simple cars in town; enterable P2
      house (two rooms + shed); mother's message starts it, the letter stays as
      an extra; torch batteries from the opening
- [x] One-page design `design/OPENING.md` v1, approved (2026-09-24): phone on P /
      D-pad right, split screen as now, town cars just bump
- [~] Tyre gym: fixed puncture, pull and speed loss, spare-wheel swap, handbrake
      on a 20% drive; automated input test and tuning
  - [x] Inspect the current tyre/van and gym hooks, then write the measured
        wheel-swap sequence in the gym
  - [x] Test puncture handling and wheel swap through real input: 17 checks,
        0 failures, 33.5 s. A null-held script error found during the run was
        fixed; the clean repeat reported no script errors.
  - [x] Repaired van holds on the gym's 20% slope with the handbrake, rolls
        without it; both checks pass
  - [x] Place the fixed puncture on the opening lane after Town Fuel: a warning
        sign and nails; three-check story-gated world test passed, 0 failures
- [x] House gym: downstairs kitchen, upstairs room/window, walkable stairs,
      drawer, enclosed shed, operable doors, dead torch and carryable cells,
      half coolant jug, drum filling an empty can. Fifteen checks pass with
      real input; the upstairs window was checked by ray and screenshot.
- [x] Traffic gym: a car loops, keeps left, stops behind a parked van and
      continues after it clears; three checks pass. Four town cars are placed
      and six world checks pass. Bumps have no damage system yet.
- [x] Phone and objectives: read-only texts (P / D-pad right), mother's message
      starts the story, per-player opening objectives (P1 8 steps, P2 7), one
      shared line again after the pick-up (resumes at "drive to the windmill")
  - [x] Review pass (2026-09-25, Claude): phone redrawn as a handset with
        bubbles, sized to each view; badge moved off the rear-view mirror;
        texts arriving while it is open count as read
- [x] Split start: P1 at the homestead with 6 L, P2 in the kitchen with a dead
      torch; the opening (steps, texts, house, pump) survives save/load
- [x] Torch batteries: drawer, 10-minute drain, flicker, fit with F, saved
- [x] Fuel drum and Town Fuel pump fill cans by holding E; saved with the game
- [x] Review fixes (2026-09-25) to the earlier Milestone C work
  - [x] Controller journal: D-pad right became the phone and left pads with no
        way to open the journal (no saving). Now RB in the parked van.
  - [x] Opening started in gyms reached from the dev menu (crash on the
        missing windmill); Story now follows Boot's opening flag
  - [x] P2 no longer has to go upstairs if already out at the drive; the jug
        only fits the rack's right-hand slot, and the hints say so
  - [x] Tyre: the fitted spare looked flat until the jack came down; the flat
        wheel now drops as a real object instead of vanishing
  - [x] Nail trap redrawn: broken nail boards, small loose nails, split box,
        cones on the left verge (was 24 cm white sticks); gym uses the same
  - [x] House doors say Close when open
  - [x] Town Fuel moved from 40 m off the lane to the roadside (13 m): you
        could not reach the pump without driving across the grass
  - [x] Town cars: stop for people on foot, look ahead with a car-wide box,
        U-turn smoothly at the patrol ends (they snapped 180 degrees), and
        keep 2.4 m from the centre so a van driven down the middle can pass
        (one stopped nose to nose with it and jammed the road)
  - [x] Test helper `hold_physics` sent a fresh key press every tick (read as
        60 taps a second); it now only re-sends a dropped press
- [x] P2's side fixed after your first test (2026-09-25): a new `opening_p2`
      walks P2's whole part with real movement (no teleports), in Quick
  - [x] Stairs rebuilt: their foot was 0.25 m from the front wall, so you
        could only scramble up the side. Now along the right wall with 1.6 m
        clear at the foot, a 1.2 m landing at the top, railings round the
        stairwell and the space under the stairs closed in
  - [x] Front and shed doors open from inside (their use zone was only on
        the outside face)
  - [x] A 0.2 m lip at the top of the drive stopped you walking out of the
        front door; the slab is flush now, and the drive's cutting is wide
        enough that the grass no longer humps through the concrete
  - [x] Nails puncture the van any time during the opening; they used to
        work only after the Town Fuel refuel, so driving straight there
        missed the puncture
  - [x] Batteries sit in the pulled-out drawer (they fell at your feet) and
        holding them says "[F] Fit the batteries in your torch"; the drawer's
        spent "Drawer is open" zone no longer covers them
- [x] Opening play-test (`opening_full`, in `full`): the whole opening with the
      real controls, P2's house jobs, the drive to Town Fuel, filling and
      pouring, the roadworks puncture and full wheel swap, the turn up P2's
      drive (van checked on the slab), loading, both aboard. 27 checks, 0
      failures. Scripted with no hesitation it takes about 3.3 min (P1 184 s
      to arrive, of which 124 s driving and 16 s on the wheel; P2's house
      jobs 52 s); people reading, looking and fumbling should land it in the
      5-10 minute target. Walks between jobs are teleports counted at walking
      pace.
  - [x] Quick after all fixes: 7 segments, 238 checks, 0 failures, no script
        errors, 388 s of scenarios
- [x] Milestone C hand-over after my play-test; push only after your approval
  - [x] My play-test (above)
  - [x] Your test; fixes above; approved and pushed (2026-09-25)
- [x] Phone: texts between players, the message from Naresh's mother
- [x] P1's home (the current homestead); P2's home
- [~] P1 drives alone to P2's home and learns the van: driving, fuel, tyre
      puncture, handbrake, parking are taught. Heat, coolant and battery are
      not part of the opening yet (heat and coolant come at the water works).
- [~] P2 prepares at home: fuel can and half coolant can, torch batteries,
      journal note, paper map and a stamp. Navigating and guiding P1 over the
      phone is not built (the phone is read-only, as agreed).
- [x] Pick-up: loading P2's cans into the van

## Milestone D: The way out
- [x] Discussed the proposals with you (2026-09-25): plan as proposed; binoculars
      at the ridge lookout and Last Fuel; one brief lorry; first ghat attack always,
      once; white smoke when taken; a faint trail for the partner; the box is in;
      controls tag T / MMB / pad RT, zoom and peek RMB / pad LT
- [x] D1. Tagging gym (`--gym=tagging`, `GYM=tagging tools/run_test.sh tagging`)
  - [x] `tag` action: T, middle mouse, pad RT (triggers read as buttons past
        halfway, `InputDevice.TRIGGERS`); on foot and from the passenger seat,
        never the driver (the pad's RT is the throttle)
  - [x] Tag marker (`player/TagMarker.gd`): a pin in the tagger's colour, seen
        through walls on both screens, "P1: board 25 m  24 m" with each
        viewer's own distance (one label per viewer on the private layers);
        fades after 20 s; one per player; follows moving things
  - [x] Names: a `tag_name` meta wins, items name themselves, "the van",
        "P2", "that" (a handle), "there" (ground); from a seat the van itself
        and its handles are skipped
  - [x] Edge arrow in the view when a tag is off screen or behind you
  - [x] Gym: boards fanned out at 10, 25, 50, 100, 150 m and one at 220 m;
        reach fixed at 200 m. First screenshots: marker and text far too small
        (text unreadable) and the diamond hid a 150 m board; now a pin above
        the spot with ~17 px text, checked at 10, 25 and 150 m in split view
  - [x] `t_tagging`: 21 checks pass (key, mouse, pad, reach, one per player,
        both views, follow, arrows, driver/passenger, fade), 8.6 s
  - [x] Quick suite with the tagging gym added: 9 segments, 0 failures, no
        script errors
- [x] D2. Binoculars gym (`--gym=binoculars`)
  - [x] `items/BinocularPickup.gd`: take them (E) and keep them; saved per player
  - [x] Hold RMB / pad LT: eases to 4x in ~0.25 s, look speed / 4, a round
        two-eyepiece view (`ui/BinocularView.gd`); hands free, not the driver
  - [x] Tag reach 400 m while zoomed (200 m by eye)
  - [x] Gym: signs at 50-400 m, each with 0.6 / 0.3 / 0.15 m codes. From the
        shots: zoomed, letters of distance / 650 read; by eye distance / 170;
        split screen needs ~1.35x. Written into DESIGN.md 6.1
  - [x] `t_binoculars`: 18 checks pass first time, 14.3 s
  - [x] Split view clipped the eyepieces at the sides; they now fit
  - [x] Quick suite with the binocular gym added: 10 segments, 0 failures
- [x] D3/D4. Stealth and creature gyms (`--gym=stealth`, `--gym=creature`), in four steps
  - [x] (a) Senses and the chase. `creatures/Hearing.gd`: every sound
        (footsteps by speed, landings, thrown items) reaches creatures within
        its radius, walls or not. `creatures/Creature.gd`: sight (110 deg, rays
        to head and chest past walls, rocks, crates, the van), suspicion 0-1
        (wander / curious / search / take), turns to stare at a sound, chases at
        7 m/s only towards where it last saw you, gives up 10 s after losing
        you. `PlayerRig.sight_range()` by stance and light. Eyes and a hum
        rise with suspicion (glow halo added: at 40 m in full sun the eyes were
        invisible; still faint in daylight, re-check at dusk)
  - [x] Stealth gym: a creature on a patrol, a wall, rock, crate stack and a
        tree trunk, stakes every 5 m. `t_stealth`: 17 checks pass (30 m seen,
        40 m not; crouched 25 m not, 14 m seen; behind wall / rock hidden,
        standing up behind the rock seen; out of its view; sprint 14 m heard,
        walk 12 m not, walk 6 m heard, crouch-walk 4 m not; turns to a sound;
        taken 2.3 s after standing in view at 9 m; gives up after 10.1 s)
  - [x] Bugs found on the way: class name `Noise` clashes with Godot's own
        (renamed `Hearing`); the chase homed in on your live position unseen;
        heard sounds didn't turn its head
  - [x] (b) Taken (`creatures/Taken.gd`): white smoke, the view goes white
        and you can't move, you wake at the nearest drop point 150-400 m away
        facing back the way you came, the partner sees a faint smoke trail for
        a few seconds, both get a text naming the landmark, 2 min grace. Both
        taken (partner already out there alone) = both wake at the van, which
        now leaks 1 L/min (`Camper.fuel_leak`). Stealth gym has three drop
        posts. `t_taken`: 10 checks pass (woke 207 m away by the south post;
        both taken: both 2.8 m from the van, leak 1.0 L/min, tank draining)
  - [x] Bugs found on the way: a running take teleported P1 in the middle of
        later checks (takes can now be cancelled; tests cancel them); the
        trail's stop timer outlived a cancelled take (now a tween on the trail)
  - [x] (c) Hiding. `items/CardboardBox.gd`: E while holding it puts it over
        you (crouched, no jumping, a slit view `ui/BoxView.gd`; your partner
        sees a box); E lifts it off again. Still in it you are seen only
        within 3 m, moving 6 m; a box that moves in its view within 35 m makes
        it curious: it walks up to 4.5 m, stares, and loses interest if you
        keep still. Peeking: crouched with cover within 1.3 m in front, hold
        RMB / LT and your head rises over it (low cover) or leans 0.6 m past
        its end (tall cover); a creature then sees you as if standing; no
        binoculars while peeking. Lures: a thrown thing landing within 15 m
        makes it curious and it walks to the spot (a bouncing crate counts
        once). Crouch and peek added to the on-foot hints. Stealth gym: a box
        and two crates by the start. `t_hiding`: 22 checks pass (box at 10 m
        not noticed; that box moved: stared from 4.4 m, then gave up; moving
        in the box right in front of it: seen; peek over the rock and past
        the wall's end both seen; lure landed 6.4 m away, it walked there)
  - [x] Bugs found on the way: a crate's bounces counted as three sounds and
        sent it searching (one throw = one sound now)
  - [x] (d) The van (`vehicle/VanAttack.gd`, a child of the Camper). Noises
        they hear: engine idle 40 m / driving 60 m / revving 90 m (every
        0.5 s), doors 20 m, the tarp being pulled 20 m, and a new **horn**
        (Q / L3, driver only, 150 m, a two-note synth `NoiseLoop.Kind.HORN`).
        A creature that notices the van (its engine, headlights 40 m by day /
        80 m at dusk, driving past within 45 m, or just being within 15 m)
        circles it at 7 m for 20-40 s after it last noticed it. While one is
        within 15 m: a fuel leak (1 L/min, dripping ticks on its side) after
        2 s, the engine failing after 30 s (60% power, coughs), a puncture
        after 60 s; 5 s with nothing near and it all stops (the flat stays).
        The tarp: hold E at the roll above the spare wheel, 4 s on / 2 s off,
        only with everyone out and the engine and lights off; under it the van
        is not noticed and nobody can get in. The leak left when both players
        are taken now lasts 90 s. Creature gym: the van, a creature on a
        patrol 45 m away, two drop posts. `t_van`: 15 checks pass (idle not
        heard at 45 m, heard at 35 m; reached the van in 11.5 s; leak; engine
        failing; puncture; drove 26 m off and it all stopped; tarp refused
        with the engine on, then on, blocks the seats, no harm under it,
        interest runs out; tarp off; horn heard at 120 m)
  - [x] Bugs found on the way: the van settling on its springs at the start
        counted as "moving" and drew the creature from 45 m (now only
        horizontal speed over 1.5 m/s); horn and door sounds would have sent
        it pushing into the van's middle (it goes to the van's side now)
- [x] D5. Traffic system. `LevelLayout.TRAFFIC` is the table (road, stretch,
      cars): town 4, P2's home to J1 2, valley 2, ridge 1, none after J2;
      `world/Traffic.gd` places them and has a `density` dial (mood).
      `TrafficCar`: half speed with something 32 m ahead in its lane, stops
      at 13 m, sleeps beyond 600 m from everyone. `world/Lorry.gd`, the one
      lorry: waits in a lay-by on the lane north of P2's home, pulls out when
      the van is 25-60 m behind, crawls 70 m at 22 km/h, pulls in to the verge
      and stays. Traffic gym: a second straight for it. `t_lorry`: 5 checks
      (pulled out 60 m ahead, held the van up 12.4 s, closest 11.4 m, pulled
      in, van passed after 32 s); `t_traffic_world` checks the table
      ([6, 2, 1, 0, 0] cars on lane / valley / ridge / pump house / ghat) and
      the density dial
  - [x] Bugs found on the way: the lorry held you up 24 s and pulled out
        100 m ahead (now ~12 s, 25-60 m); the test's driver braked too late
        and touched it (now brakes by speed, like a person)
- [x] D6. Mood curve. `world/Mood.gd`: one value 1 (bright) to 0 (dark),
      eased slowly (0.012 a second) towards a target that falls as the
      players reach each place on the way out (P2's home 1.0, J1 0.95, J2
      0.85, bridge 0.78, ghat pass 0.7, coast tower 0.62, the roses 0.6) and
      never rises on the way out. Drives sky and horizon colours, fog colour
      and distance, sun energy and colour, ambient light, colour saturation,
      `Ambience.liveliness` (birds first), `Traffic.density` (all gone by 0.6)
      and the creatures' light (dusk below 0.45, night below 0.2). Saved with
      the game (and the tarp). Developer menu: mood left/right, spawn a
      creature, spawn a box, give binoculars. `t_mood`: 6 checks (1.0 -> 0.6:
      sun 1.6 -> 1.12, saturation 1.22 -> 1.03, birds 1.0 -> 0.6, lane cars
      6 -> 0; at J2 the target is 0.85 and it eases; J1 again doesn't brighten)
  - [x] Found on the way: a thrown crate was sometimes heard as a 10 m drop,
        because the contact reports the speed after the bounce; a throw's
        first landing now always counts as a throw (15 m). A tossed box
        could land between the rock and the creature and block the peek
        check (the test puts it back)
- [x] D7. Windmill brake puzzle (J1) and the valley map section reward
  - [x] `world/Ladder.gd` (E on, W/S climb, off at the top or bottom, E/jump
        lets go; hands must be empty) and `PlayerRig` climbing
  - [x] Tower: solid legs instead of a solid core, a platform under the hub
        (11.3 m) with rails, a ladder up the back
  - [x] `puzzles/WindmillBrake.gd`: snagged blade (tag follows the blade),
        brake lever, rope cut (hold E, only with the blade at the bottom and
        stopped), miller's box opens after 3 s of free spin, map of the valley
        (`MapState.reveal_valley`), story objective `windmill`
  - [x] `t_windmill` (real controls, P2 on a pad): 11 checks pass, 27 s.
        P1 climbs in 5.2 s, tags the blade from the platform; "out of reach"
        until it comes down; P2 brakes it 2 deg from the bottom; cut, spin,
        box opens, map taken, climb back down. In Quick and Full
  - [x] Bugs found on the way: the ladder had no `prompt` meta, so nobody
        could use it; the box lid swung down into the chest and eased in so
        slowly it looked shut; the map lay inside the solid chest; the
        water-works hose trigger used a fixed story index (5) that the new
        objective shifted (now by id: `Story.index_of`)
  - [x] Saved: the windmill (rope, brake, blade angle, box, map) and the
        objective by its id, so objectives added later don't shift old saves.
        `save` checks both; story/windmill/waterworks/save: 0 failures
  - [x] Quick suite: 12 segments, 382 checks, 0 failures, no script errors
- [x] D8. Water works turbine lights the power line to the bridge hut
  - [x] `puzzles/PowerLine.gd`: a turbine house where the intake pipes meet
        the river (a flywheel on the yard side, so you see it turn), poles
        in the yard and every 30 m along Pump House Road (6 lamps), wires
        with a sag. When the blue tank fills the turbine spins up and the
        lamps light one by one, 0.6 s apart (a glow halo so it reads by day);
        then the control hut's lamp, light and hum come on (`hut_powered`)
  - [x] The bridge control hut on the near bank (`_bridge_hut_and_power`):
        on stilts with a ramp to the door (the terrain can't be padded after
        it is built), an open window onto the bridge, "BRIDGE CONTROL"
  - [x] Last Fuel kiosk note: power off since the turbine stopped; the lift
        bridge runs off the same line
  - [x] Saved via the water works (`PowerLine.sync()` after a load)
  - [x] `t_power`: 7 checks (dark before; 2 of 6 lit after 1.2 s; hut
        powered 4.9 s after; turbine turning; P1 walks the ramp into the hut)
  - [x] Found on the way: the window was an opaque panel (now open), 5 lamps
        lit in 1.1 s so the wave didn't read, the first wheel faced the river
  - [x] Quick suite: 12 segments, 389 checks, 0 failures
- [x] D9. Lift bridge puzzle (levers, convex safety mirror, gear, counterweight)
  - [x] Plan: a bascule leaf stuck up at 70 deg fills the gap. Hut: RAISE /
        LOWER levers (hold E) and a safety mirror outside the window showing
        the machinery house across the road (gear, wedge, counterweight pit),
        which the hut can't see into. (1) A wedge in the gear comes out only
        while RAISE is held and the deck player holds E. (2) The counterweight
        is short a block: below 30 deg with nobody on it the leaf runs away and
        the cut-out hauls it back to 45. The counterweight rises out of its
        pit as the leaf lowers; the operator stops it level with the floor,
        the partner steps on, and it comes down and locks; barriers go
  - [x] `puzzles/LiftBridge.gd`: leaf (AnimatableBody3D, the van drives
        over it), machinery house across the road with a door from the deck,
        the gear, pinion and wedge, the counterweight in its pit (rises from
        -2.3 to +1.6 m as the leaf lowers; steppable when its top is within
        0.3 m of the floor, ~32-43 deg), the fallen block down in the pit. Hut:
        RAISE / LOWER levers, a panel readout (LEAF 42 deg / JAMMED / CUT-OUT /
        NO POWER / LOCKED), the safety mirror outside the window (a camera in
        the machinery house, drawn only with someone within 12 m of the hut,
        every other frame). Barriers and signs are their own node, taken away
        when it locks. Saved (angle, wedge, locked)
  - [x] Story: `to_bridge` -> `bridge` (lower it) -> `cross` (to J3) -> `end_d`
  - [x] `t_bridge` (P1 keyboard at the levers, P2 pad in the machinery house):
        14 checks pass, 45 s. LOWER strains while jammed; wedge refuses alone
        ("back it off"); RAISE + pull frees it; lowering alone cuts out and
        returns to 45; stopped at 41.7 deg (top -0.22 m); P2 steps on and rides
        up 2.2 m; locked, barriers gone; the van crosses in 12.6 s
  - [x] From the shots: the first mirror camera looked straight down (the gear
        was unreadable), lowered to eye height in the back corner
  - [x] Save/load: the lowered bridge comes back down with its barriers gone
        (in `save`)
- [x] D10. Ghat fog and pace notes on the swung nav; the first creature attack
  - [x] `world/Ghat.gd`: finds the hairpins from the road's own bends (2);
        fog from 150 m before the first hairpin to the pass (`Mood.fog_boost`,
        eased in: visible to ~45 m, grey)
  - [x] Pace notes on the swung nav, worked out from the bends ahead (260 m):
        "70 LEFT HAIRPIN / DON'T CUT / 170 LEFT 3", grades 1-6 by radius,
        TIGHTENS, NOW when you're in it; the driver can't see them (the
        existing private layer). The nav text now shrinks to fit the glass
  - [x] The glimpse: a passive creature 15 m out on the second hairpin, seen
        from 40 m, walks off uphill, gone after 12 s
  - [x] The first attack, always, once: with both in the van, 45 m from the
        pass, one steps out 22 m ahead and comes for the van (leak after 2 s).
        Over when it has lost interest and walked off (or the van is 90 m
        away); a text says what they do. Story: `ghat` -> `hide_van` -> `end_d`
  - [x] `t_ghat`: 15 checks (notes, driver can't see them, fog 45 m, drove
        the hairpins in 49 s with the auto-driver, glimpse, attack, leak
        1 L/min, tarp, it gave up in 25 s, leak stopped, objective moves on).
        The creature's 20-40 s of patience is shortened to 3 s in the test
  - [x] Found on the way: the glimpse fired 91 m away, invisible in the fog
        (now 40 m); the notes overflowed the nav glass (header dropped, text
        fits); a parse error in the save test hid behind a discarded run
  - [x] Quick suite: 12 segments, 414 checks, 0 failures
- [x] D11. Coast watchtower: hide on foot, stamp the beach
  - [x] `world/CoastWatch.gd`: a creature paces an oval round the tower's
        legs and the ramp's foot; it only comes out once someone is on foot
        within 130 m or the van is parked there with the engine off (the
        lesson is hiding on foot); a text says what to do. Cover between the
        road and the ramp: two rocks (gym size: top 1.2 m, you can peek over),
        a tall broken wall (lean past its end), crates; three cardboard boxes
        by the road with a "FREE BOXES" card
  - [x] Story: `to_tower` -> `tower` (up it unseen; done on the deck) ->
        `stamp_beach` (a stamp within 300 m of the beach) -> `end_d`
  - [x] `t_tower`: 12 checks (it wakes when you get out, paces 3.9 m in 3 s,
        sees you standing at 16 m, not crouched behind the rock at 13 m, sees
        you peeking over it; walked the ramp to the deck; a stamp elsewhere
        doesn't count; the beach stamp does)
  - [x] Bugs found on the way: **every lookout ramp stopped 0.14 m below the
        deck and stuck out past its edge** (you couldn't walk onto the deck;
        `climb` only checked "within 0.6 m" so it passed). Now the ramp meets
        the deck exactly; `climb` checks you stand on it. The first rocks were
        too tall to peek over (1.8 m); the road lookup for the tower picked a
        point 338 m away (`Route.nearest` only searches nearby cells)
  - [x] Quick: 423 checks, 1 failure (the ghat test expected the old last
        objective; fixed, ghat + tower rerun 0 failures). Two flaky old checks
        made tight: the lure (measured to the crate, which rolls; now to the
        spot it heard) and the binocular pickup (read the prompt before the
        gym had settled; now waits for it)
- [x] D12. Optional puzzles: barn maze (W2), lookout binocular relay (W4)
  - [x] W2 `puzzles/BarnMaze.gd`: a 6 x 6 hedge maze (3 m cells, 2.6 m
        walls, the same maze every time, 33 cells from the way in to the
        chest) on the barn's west side; one flat pad now covers barn and maze.
        A ladder up the gable to a loft balcony (5 m) overlooking it. Things
        to describe inside (a red gate, a scarecrow, a blue drum, a cart).
        Hay dust blows over the middle cells the first time someone walks in
        there (25 s). The feed chest at the far end: coolant jug and a crate
  - [x] W4 `puzzles/LookoutRelay.gd`: a supply box at the foot of the Pine
        Ridge lookout with four picture dials (E / pad X turns one); two
        boards, 1 and 2, 150 and 140 m out across the valley, each with two
        white pictures on black (circle, square, triangle, cross, ring,
        diamond). By eye they're pale dots; through the binoculars you can
        read them. Tree-free sightlines to both boards
        (`LevelLayout.relay_boards`). Inside: a full can of fuel
  - [x] Both saved (`save` checks them)
  - [x] `t_maze` (8 checks: up the loft ladder, the hedges stop you walking
        straight through, walked 33 cells, the dust, the chest) and `t_relay`
        (6 checks: both boards in sight, P2 turns the dials with pad X, it
        opens)
  - [x] Found on the way, from the shots: trees hid the first boards from
        the deck (the check's ray passed between trunks: canopies have no
        collision); at 280 m the pictures were a few pixels even zoomed
        (now 150 m, 1.6 m pictures, all one colour so only the shape tells);
        the dials read right to left from the front (now 1-4, left to right)
  - [x] Quick: 12 segments, 436 checks, 0 failures
- [x] D13. Full run J1 -> Bessi on both routes; hand-over
  - [x] Last Full (after your test's fixes): 5 failures, all from the full
        order (the menu's van 20 m away, the day already dusky for
        traffic_world / lorry / mood). Tests now set their own time of day;
        the 10 scenarios rerun in the full order: 0 failures
  - [x] `tools/run_test.sh resume` (your idea): a run that broke off carries
        on from the scenario it was in; one summary at the end
  - [x] `t_way_out` (Full only): J1 -> the coast watchtower in one drive,
        story running, both routes. Puzzles by script where the van gets to
        them (refuel at Last Fuel, the water works fix and turbine, the
        bridge); the fog, the glimpse and the first attack for real (the van
        drives on). 8 checks pass. Driving time: valley 4.3 min (J2 at 1.8,
        water works 2.5, bridge 2.7, J3 2.8, pass 3.9, tower 4.3); ridge 3.2
        min (J2 at 0.8). With the stops (windmill ~2 min, water works ~3,
        bridge ~2-3, the attack ~1, the tower ~2) about 14-15 min from J1 to
        the tower, near the beat chart's 13.5 (7:30 -> 21:00). The roads
        themselves are shorter than the chart's guesses (valley 1.8 not ~3,
        ridge 0.8 not ~1.5)
  - [x] Found: the drive stopped the story at "refuel" (the van reached Last
        Fuel without a full tank); the script now refuels there like players
  - [x] Full suite: 13 segments, 525 checks, 1 failure: the new tests left a
        pretend P2 pad plugged in, so the old `layout` check later in the
        same session saw a controller. The run loop now unplugs a test pad
        after each scenario; that order rerun and a last Quick (436 checks,
        144 fps driving) both 0 failures. All eight roads 16.0 min; the way out
        valley 4.3 / ridge 3.2 min
  - [x] Your report: F1 "skip" did nothing in the opening (it moved the
        chain underneath; the opening's own steps never changed). Now it skips
        the whole opening to "drive to the windmill" (`Story.skip()`); `dev`
        checks it; dev/map/story/windmill rerun 0 failures
  - [x] Your report: teleporting to the barn dropped you under the map (the
        teleport landed you inside the barn's walls: it used the place's
        centre). The F1 menu is rebuilt: a centred window on its own layer,
        tabs (Travel / Story / Van / Spawn / World / Gyms), mouse and keys,
        a details panel, the places named and in journey order, jump to any
        objective, the game paused while it's open. Teleports look outwards
        for somewhere to stand (floor, deck or ground with room above; not
        the sea) and face you to the place. New `teleports` test: all 42
        places put both players on their feet. (First try found the barn,
        the homestead and the far bank: inland ground is below sea level
        there and the sea check threw every spot out; now it's the sea side
        of the coast only)
  - [x] Quick: 443 checks, 0 failures
  - [x] Your test and approval (2026-09-26: windmill, maze, lookout, water
        works, bridge, ghat, watchtower; fixes above)
  - [~] Full suite, then push

## Milestone E: Bessi beach and Naresh
Design: `design/BESSI.md`, `design/NARESH.md` (proposals; their open questions
get the provisional answers in MASTER_PROMPT section 6, listed for your review
in `notes/TEST_MILESTONE_E.md`).
- [x] E1. Naresh gym (`--gym=naresh`) (approved by you, 2026-09-27): Naresh as a character (follows,
      walks, climbs into the van's back seat), the command wheel (NOT Q:
      Q / L3 is the horn since D4; pick a free key and pad button), commands
      carry / store / refuel / hold / wait / follow / work it, the state
      machine, random acts (every 3-6 min), taken when alone (creatures
      follow him); `t_naresh`
  - [x] Key agreed with you: V / D-pad Up (D-Up is the ignition only for
        the driver, who can't give jobs)
  - [x] `naresh/Naresh.gd`: walking (gravity, a 1 m A* grid round things,
        jump then give up when stuck), follow / wait / go, jobs carry, store,
        refuel (from the rack, told at the filler or on a can), hold, work,
        get in / out (the van's bench, `Camper.bench`), the refuel mistake,
        random acts (9, announced 3 s before, never in a `naresh_calm` zone),
        taken when alone (`Creature` drifts to him), shouting until fetched,
        knocked by the van, save / load (`SaveGame`)
  - [x] `world/Workable.gd` (hold / work things: shutter, lever, crank)
  - [x] Command wheel: `PlayerRig` (hold V, point, let go; tap = first job),
        `ui/CommandWheel.gd`; his lines as subtitles (`PlayerHUD`)
  - [x] The gym (`GymBuilder._naresh_gym`), F1 rows (spawn, act now, arm the
        mistake), `t_naresh` written
  - [x] `t_naresh` (about 5 min): 0 failures after fixing: stowing on the
        rack never let go (he stayed "holding" it: nobody could pick it up;
        the scripted mistake hung), a deleted target read as null (no "It's
        gone"), an announced act could stall, test slips (P1 grabbing from
        7 m, checking a line the same step). Every job by the real V key and
        mouse, D-Up on a pad, all nine random acts, the timed zone, taken
        and fetched, never taken with a player beside him, knocked by the
        van, save / load, 144 fps
  - [x] Screenshots: the speech bubble was far too big from a distance:
        now ~17 px, wrapped, above his head, hidden within 7 m (the
        subtitle says it there)
  - [x] set:gyms 21 scenarios, smoke 22, set:creatures 7: all 0 failures
  - [x] Your test sheet: `notes/TEST_MILESTONE_E.md` section E1, with 8
        "Decisions to confirm"
  - [x] Your test and approval (the 8 decisions confirmed for now)
  - [x] Full run, then push: openings and every gym 0 failures (the honk
        check once caught the van a step early: fixed); the world part
        crashed once in the graphics driver (resumed as `set:world_full`),
        then 48 scenarios with 2 test-order failures (the lorry already set
        off, a can left on the rack after the long drives): `Lorry.reset()`,
        `reset_can`; the road drive run first then met the town cars (it now
        clears the traffic itself). Rechecked: routes + both, 0 failures.
        Pushed (2026-09-27)
- [x] E2. Bessi beach greybox (the existing `_beach` / roses plaza): sand,
      sea, promenade, empty lit stalls with a radio, boats, casuarinas, the
      memorial, the lighthouse; the nav loses signal; mood to dusk
  - [x] `world/Bessi.gd`: the promenade (slabs laid on the sand), 29 warm
        lights (stalls and lamps, fading with distance), the radio stall
        (`tools/gen/radio.py` makes `audio/radio_tune.wav`, my own tune), the
        memorial moved onto the photo line with a spire, the lighthouse on
        the rocks off the north end (its height worked out so its lamp shows
        just over the spire from the photo spot), the beam turning; the
        nav's "NO SIGNAL" within 420 m of the roses (`Camper.nav_signal_lost`);
        dusk at the beach (`Mood.WAY_OUT` "beach" 0.4); F1 places
  - [x] `t_beach` (in smoke and full, `set:bessi`): 0 failures; 144 fps on
        the lit promenade at dusk, both views; screenshots looked at (the
        beam was a solid grey cone: fainter, no fog)
  - [x] smoke (23, now with the beach) + tower after the memorial move: 0
        failures; your test sheet (E2 in `notes/TEST_MILESTONE_E.md`)
  - [x] Your test and approval (2026-09-27)
  - [x] Full world run, then push (2026-09-27)
- [x] E3. The photo (W8): the phone photo held by one player (P2), the
      alignment spot (lighthouse behind the memorial spire, a mast on a
      stall roof), binoculars + tags; `t_photo`
  - [x] Built in the second copy (`../MPG_dev`, branch `e3`) while the E2
        full run went on here
  - [x] `world/Alignment.gd` (pairs that line up, 2 m), the photo gym
        (`--gym=photo`, `t_photo_gym`: 0 failures)
  - [x] The kiosk and the boat with its mast on the sand NE of the spot;
        tag names; `core/PhotoCamera.gd` takes a real snapshot with Naresh
        at the edge; it goes to P2's phone only; story steps to_beach /
        photo / end_e3; found on the spot looking along it; a load retakes
        it without resending the texts. `t_photo`: 0 failures, the photo
        looked at (Naresh first hid the kiosk: moved to the edge)
  - [x] `run_test.sh` compiles first, stops in 5 s on a script error
  - [x] Merged into main after E2's push (not pushed); smoke 23, set:bessi,
        tower: 0 failures
  - [x] Your test: approved with its 4 decisions (2026-09-27); Naresh gym
        rechecked (0 failures); pushed
- [x] E4. The smoke and the Five Roses rising; the roses open in travel order
      (windmill, water drop, bridge, wave, star); wrong order resets;
      Naresh in the fifth; `t_roses`
  - [x] Built ahead in `../MPG_dev` (branch `e4`, on top of `e3`):
        `world/Roses.gd` (sunk until the photo spot, the smoke bank off the
        sea, the rise with a rumble `tools/gen/rumble.py`, carvings built
        from exact shapes, the order puzzle, the fifth bloom down to the
        plaza), each rose its own collider, `Naresh.sit_at` /
        `stand_from_seat`, story steps roses / naresh / end_e4, saved in
        story flags. `t_roses`: 0 failures first run
  - [x] The smoke bank didn't show (the test looked away; it also died
        before the dune): longer, softer sprites; still thin (your eye)
  - [x] Merged into main after E3's push; "He stood exactly here" was
        overwritten at once by the smoke line: the smoke now waits 6 s;
        `Roses.reset()` for tests; set:bessi 4 scenarios + smoke 23: 0 failures
  - [x] Your test: approved with its decisions (2026-09-27); pushed
- [x] E5. The evidence (one set of footprints, the unrolled second sleeping
      bag with its tag, the timer camera, the notebook "we"/"I")
  - [x] `world/Evidence.gd`: the camp at the fifth rose (lantern), each thing
        a "Look at" with only what you see, one set of footprints (a trail
        from the photo spot), he packs while you look (3 seen or 2 min);
        notes can show crossed-out words (rich text, `<bb>`); story steps
        look_around / end_e5; `t_evidence` (checks no text spells it out):
        0 failures. The notebook's strike first didn't show: pencil red now
  - [x] Built in `MPG_dev` (branch `e5`), merged into main; set:bessi 5 +
        smoke 23: 0 failures
  - [x] Your test: approved with its decisions (2026-09-27, after the F1
        jump fix); pushed
- [x] E6. N1 the stall shutter (hold; the scripted early let-go) and N2 push
      the boat (work it; he pushes the wrong way first); rewards: torch
      batteries, a fuel drum
  - [x] `world/BessiTasks.gd`: the store (the shutter rolls up while its
        handle is held; the box takes two; his slip once, with you both in),
        the upturned boat over the fuel drum (three at once; he goes round
        the wrong side until told again), `items/FuelDrum.gd` (40 L, two to
        carry); `Workable` need_hands / helps / stand_fn; story steps
        batteries / drum / end_e6 and their F1 jumps. `t_shutter`, `t_boat`
  - [x] Found and fixed: a tilted boat collider wedged Naresh fast; his
        straight-line check can't see a thing he's touching, so once stuck
        he plans round on the grid; players lost their grip on a sliding
        hull, so it rocks in place and slides off at the end; the raised
        shutter poked through the roof (rolls up into the doorway now)
  - [x] Merged into main; set:bessi 8 + smoke 23 + the Naresh gym: 0 failures
  - [x] Your test: approved with its decisions (2026-09-27); pushed
- [x] E7. The storm starts, the roses sink; "my friend says we should go
      north"; save/load of all of it; the full run pass-to-storm
  - [x] `world/StormFront.gd` (the bank over the Beach Road, rain curtains,
        lightning, thunder `tools/gen/thunder.py`, mood 0.3), the roses sink,
        his line; story storm / end_e (north on the coast road with him in
        the back); `t_storm`
  - [x] Save / load of Bessi: `t_bessi_save` (its own process). Found: the
        F1 jump to the storm step didn't start the storm (off by one step)
  - [x] `t_bessi_run` (Full only): from the ghat pass to north in the storm
  - [x] Merged into main: set:bessi 9 + bessi_save + smoke 23 + the Naresh
        gym: 0 failures (one stale check in t_boat fixed)
  - [x] F1 Story jumps to Bessi steps put everyone at the step (`t_step_jumps`)
  - [x] Your test: approved with its decisions (2026-09-29)
- [x] E8. Full suite, `notes/TEST_MILESTONE_E.md`, push (2026-09-29)

## Milestone F: The return and the ending
Design: `design/RETURN.md` (decisions 2026-10-01). One part at a time, your
test before each push.
- [x] F1. Storm gym (`--gym=storm`): a flat plain, a road, a gust schedule.
      Gusts push the van 1-2 m sideways at 50 km/h, can tip it above ~45 km/h
      in a crosswind, never under 25 km/h; rain and fog (~60 m); lightning
      lights the scene; wipers and headlights help. `t_storm_gym`
  - [x] `world/Storm.gd`: gusts (rise 1.8 s, hold 1, fall 1.5; every 7-14 s;
        only the part across the van counts; push grows with speed; roll
        torque only above 25 km/h), a wet road (`Camper.set_wet`: 60% grip,
        brakes 70%), rain round each player (GPU particles, the van's body
        keeps it out of the cab), fog to ~60 m and the sky into it
        (`Mood.storm`), lightning (`Mood.flash`) and thunder, wind and rain
        sounds (`NoiseLoop.Kind.RAIN`), windsocks that lift before a gust
  - [x] Measured (full gust, hands off): 25-30 km/h leans 0.5-2 deg; 40-42
        leans ~20 deg and stays up; 45+ tips. At 50 km/h a 55/70/85% gust
        pushes it 0.25/1/5 m. First found: the van always rolled back up
        (its centre of mass is below the floor for the driving feel): past
        70 deg in a gust it gets a real van's, so it stays down; R rights it
  - [x] Wipers (automatic in the rain with the engine on, park when off)
  - [x] Found: the headlights shone backwards into the cab since stage 1
        (fixed; they light the road now)
  - [x] The gym (`--gym=storm`: windward windsocks, distance boards), F1 World
        rows (storm on/off, a gust now, lightning now)
  - [x] `t_storm_gym`: 24 checks, 0 failures; 144 fps in the storm, both views
  - [x] smoke (1 failure, also on main: the mirrors test assumed two screens,
        which a plugged-in controller used to give it; fixed) + set:gyms 22
        scenarios: 0 failures. The storm gym is in set:gyms
  - [x] Merged into main; your test sheet `notes/TEST_MILESTONE_F.md` (F1)
  - [x] Your test: approved with its decisions (2026-10-01); pushed
- [x] F2. The storm over the ghat and the Beach Road (the old way); the dead
      end at J3 (the lift bridge swung open in the wind); "My friend said
      north"; the dark end of the mood curve; creatures drift to Naresh
  - [x] `StormFront` makes the world's `Storm` (wind off the sea) with a
        zone: full within 60 m of the Beach Road (from the bank), the ghat
        road and Pump House Road J3 -> bridge, gone by 160 m (first 150/300 m
        reached the coast road north, which runs ~220 m from the Beach Road)
  - [x] The dead end: `PowerLine.storm_cut`, `LiftBridge.storm_blow` (leaf up,
        swaying, barriers back, NO POWER); a message at the bridge; Naresh's
        line ~300 m back; a jump back before the storm puts it all back
  - [x] Found from the shots: after a Bessi jump the drive back burst the
        hose and started the first ghat attack again; the jump now marks the
        way out's one-offs done
  - [x] `t_storm_road` (in set:bessi and full): 17 checks, 0 failures
  - [x] set:bessi (1 failure: the new test leaned on the storm the test
        before left on; it sets its own start now) + bridge, power, save:
        0 failures; storm + storm_road rerun in order: 0 failures
  - [x] Merged into main; test sheet F2
  - [x] Your test: approved with its decisions (2026-10-01). Found: the
        "North on the coast road" jump left you where you were (now at the
        van, pointing north); the storm followed P2 left at J3, raining and
        gusting on P1 and the van up the coast road (now per player / van;
        `t_storm_road` checks it). One unexplained report: getting out near
        the fishing village you were thrown and spun round (likely a gust
        rolling the van into you, from the same bug; watch for it). Pushed
  - [ ] Creatures drift to Naresh: moved to F3, where the return's creatures start
- [x] F3. Fishing village, R1 the decoy (fuel in the net shed, Naresh waits
      on the jetty); the scripted refuel mistake; the van dies past the village
      (design agreed 2026-10-01: `design/RETURN.md` decision 5)
  - [x] Creatures on the return (`Creature.on_return`, set by the storm):
        drawn to Naresh from 120 m, kept to 300 m, drift 0.9 m/s, go to him in
        the van too; `Creature.funnels` (the jetty: they go round by its start)
  - [x] `world/FishingVillage.gd`: the jetty (railed to the seabed, the sea
        wall's gap), the net shed (door 2.2 m, flat roof), fish-crate stairs
        with a stop at the top, the roof boat and key, two cans inside, two
        creatures, two high drop places; the fuel lamp 420 m short
  - [x] Naresh as bait (measured: the shed clear 20 s after he reaches the
        end, the first creature 10 m from him after 78 s); recalled through
        the binoculars (jobs reach 150 m zoomed)
  - [x] The mistake: "There's two!" (he stores the light can), "Leave the
        fuel to me!"; the van dies ~200 m on, a creature steps out ahead;
        pour it yourself
  - [x] Story steps village / fuel / drive_on / stalled / end_f3, F1 jumps
        (village, fuel; the mood at dusk at once), save (`t_decoy_save`)
  - [x] Found on the way: positions taken from `global_transform` before
        the world is in the scene (P1 fell through the map); Naresh waded
        round the jetty (a 0.25 m step he can't take; the deck is flush
        now); the sea wall blocked looking at the jetty (the world edge is
        on its own layer, 64: it stops bodies, not eyes); a carried can
        snagged in a 1.4 m door; P1 standing at the rack made him give up
        ("Excuse me!" now, and he picks up a snagged thing again)
  - [x] `t_decoy` 21 checks + `t_decoy_save` 5: 0 failures
  - [x] Regression: set:creatures 7, the Naresh gym, set:bessi 12, teleports,
        smoke 23: 0 failures, no script errors. Merged into main (not pushed)
  - [x] Pushed on your "all good" (2026-10-01). Found on your launch: Play.bat
        showed a grey screen after the merge (a new class unknown until an
        import); Play.bat now imports when scripts are newer
  - [ ] Your test (at the end of F, from F3 on)
- [x] F4. Salt pans, R2 red light / green light (dashes between heaps, the
      spotter calls go / tarp) (built with my recommended answers; your test
      at the end of F)
  - [x] `world/SaltPans.gd`: a gantry with a watcher (a passive `Creature`)
        whose visible gaze stares 3 s, turns, and looks out to sea 4.5 s;
        9 salt heaps (each hides the van along 10-23 m of road, measured);
        seen when moving in its gaze or within 25 deg of it in the open, or
        stopped in the open 2.5 s (not under the tarp): it climbs down and
        goes for the van; Naresh calls, right 2 in 3
  - [x] Story `salt_pans` / `end_f4`, F1 jump, `match_story` (load, jumps)
  - [x] `t_saltpans`: 0 failures. A careful (scripted spotter) crossing got
        across unseen in 75 s with 2 stops; straight across at 45 km/h is
        seen. Tuning found on the way: with the gaze only on the road a
        careful driver could hardly ever move (the look out to sea fixed
        it); the heaps' cover was narrower than the van at first
  - [ ] Regression with F5 (the creature change: a watcher at its post
        ignores Naresh)
- [x] F5. Estuary bridge, R3 the three-hand swing bridge (two cranks and a
      held brake; the tide gauge is the clock; Naresh lets go to wave)
      (built with my recommended answers; your test at the end of F)
  - [x] `puzzles/SwingBridge.gd`: the middle span (an AnimatableBody3D on
        the pier; `_road_bridge(..., swing)` leaves its gap), barriers, two
        cranks and a brake (Workables, "hold"), the sign, the tide gauge;
        story `swing` / `end_f5`, F1 jump, `match_story` (load, jumps)
  - [x] `t_swing` (P1 on E, P2 on pad X, Naresh told by V): 0 failures. One
        crank 1.6 deg/s, both 3.2; he let go at 48 deg; the van drove over;
        the red-mark current 5 deg/s. From the shots: the sign was huge
        (fixed)
- [x] F6. The rail tunnel, R4 the torch relay; the hidden flare gun (3
      flares, empties an 80 m circle); R5 push start if the battery died
      (built with my recommended answers; your test at the end of F)
  - [x] `world/RailTunnel.gd`: dark inside (`Mood.dark`), the flood gate,
        the service gallery (doors left in the tunnel wall by `_tunnel`),
        two forks with painted arrows, the winch, a creature that keeps its
        post; `items/FlareGun.gd` (fired with the throw button,
        `Creature.scare`); `Camper` bump start (`BUMP_START`)
  - [x] `t_tunnel`: 16 checks, 0 failures. Found: the gallery was 330 m
        (doors now 60 m either side of the gate); in the dark the arrows
        were still legible (no outline now)
- [x] F7. The radio mast finale: the van's battery powers it, tag the three
      targets from the top (nearer return sites, chosen by a sightline test),
      three cranks with Naresh, the dish screens, the creatures come halfway;
      the clouds break over the West Road (built with my recommended answers;
      your test at the end of F)
  - [x] Measured first: no road reaches the mast (230 m up from the coast
        road), so the power is its own pull-start generator; the sightline
        test picked the tunnel mouth (430 m), Naresh's home (1.1 km), the
        ending watchtower (2.3 km)
  - [x] `puzzles/RadioMast.gd`: platform + ladder, three dishes, cranks,
        lamps, plaque, the screen (SubViewport, every 6th frame), the
        generator (cord + choke), relay beacons (group `far_tag`: taggable at
        any distance), two creatures for the noise; Naresh's backwards crank
  - [x] `t_mast`: 0 failures; 135 fps by the screen with both views (144
        without). Found: tags reach only 200/400 m (far lights now taggable);
        the crank's standing spot was 1 m up; the labels were huge
- [x] F8. Naresh's home (mother and sister, silent), the hidden tracker
      (maze, relay, flare gun, fragments), the West Road in full sun, the
      ending watchtower's site lights, the LiveStander text, end screen
      (built with my recommended answers; your test at the end of F)
  - [x] `world/Homecoming.gd`: the arrival scene, the tracker rule
        (`all_optional`), the mood back up, the site lights from the end
        tower, the phones, the end screen (back to the title on E / A);
        story `end_f7` / `drive_home` / `the_end`, F1 jumps
  - [x] `t_home`: 0 failures (the scene 24 s; no tracker, then the tracker
        with everything done; 3 lights dark). From the shots: his "wait"
        made him say "I'll wait here" after his goodbye (gone); the site
        lights were a pixel at 2-3 km (3x bigger)
- [~] F9. Full run (Bessi -> home, timed, about 29 min), `notes/TEST_MILESTONE_F.md`, push
  - [x] `t_return_run` (Full): Bessi to home in one drive, 7.5 min of
        driving (+ ~20 min of puzzles = near the beat chart's 29). Found and
        fixed: a locked span never moved (fell in the river); the van could
        fall through the ground for ever (`Camper._safety_net`); the
        estuary bridge's deck edge was a step (ramps)
  - [x] The test sheet: how to test F3-F8 in one go, per part
  - [x] The full run (in `MPG`, merged main, not pushed), 2026-10-01 night:
        finishing; **the fixes wait for the next session** (you, 2026-10-02).
        Failures so far, all in the world segment (each passes alone, so
        most likely test order: earlier tests leave state behind):
        roof fragment / crate staircase / shed roof fragment (carry or
        climb, old checks); "one sleeping bag and two mugs" (evidence);
        decoy: "both drift to Naresh (1 of 2)", "dies 55 m up the road",
        "takes the full can off the rack", "the tank's filled"; saltpans:
        "across unseen", "on to the estuary bridge"; home: "0 dark" (the
        maze / relay left done by an earlier test). Final: 24 failures, no
        script errors; the later ones are old way-out checks after the F
        tests: way_out (both routes: the bridge didn't come down, the story
        stuck at 'cross'), save (the lifted bridge / power line), routes
        (coast road, ghat + beach road). Likely the F tests leave the storm
        (`storm_on`: the bridge blown, the power cut, gusts) and the
        return's state behind for the old tests after them. The log:
        `appdata/playtest/runs/full_2026-10-01.log`.
  - [x] Causes found (2026-10-02): the village's `shed_roof` poi overwrote
        the water works shed's (its fragment had moved to the net shed: a
        real bug; renamed `net_shed_*`); the return's state left on for the
        old tests (`_undo_return` before each); the stall's distance
        depended on what was left in the tank (now ~250 m always); the
        salt pans pattern's phase (a jump restarts it); the watchtower test
        expected 3 dark when earlier tests had done the maze / relay
  - [x] Rerun in the full order: water works + every return test + every old
        world test after them: 2 left (the road drive met the swing bridge
        and the flood gate shut: it opens them by script now; the town cars
        stood still with nobody near: the test puts someone there), then
        those rerun: 0 failures; save after the return: 0; decoy_save: 0;
        the beach alone 143 fps (its 108 was with a second game running)
  - [ ] Your test (F3 on); push after it

## Milestone G: Finish
- [ ] The polish list (`notes/POLISH.md`): remind the user, agree the order, build it
- [ ] Full audio pass, music and ambience
- [ ] Settings menu (sensitivity, volumes, text speed)
- [ ] Windows `.exe` export
- [ ] Full playthrough QA, controller testing, save/load testing

## Polish stage (after the whole game is built and tested)
- [ ] Agree the art direction with you (realistic "RDR2-like" vs stylised)
- [ ] Show each asset (van, trees, grass, flowers, clouds, landmarks, Five Roses,
      beach...) for approval, then replace the block-outs one by one
- [ ] Lighting, sky and weather looks
