# Finding Naresh: build checklist

Pushed to GitHub with the work (since 2026-09-24, for safety).
`[x]` done and tested · `[~]` being worked on now · `[ ]` not started.
Updated live as each small step lands (sub-steps are added under an item while it is
being built and tested), so this always shows where the work is right now.

## Right now
- Milestone C approved by you and pushed (2026-09-25). Your test found P2's
  house problems (stairs, doors, drive lip, battery hint) and a nail trap
  that only worked after the refuel; all fixed and re-tested. Quick: 8
  segments incl. P2 walked for real; `opening_full` plays the whole opening.
- Next: Milestone D (the way out), gyms first. The D/E/F, creature and
  Naresh design pages are proposals; discuss their open questions before
  building.

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
- [ ] Gyms first: tagging, binoculars, hiding (crouch, peek, cardboard box), creatures
      (sight, hearing, catch = separated, damage to the van, camouflage tarp)
- [ ] Landmark puzzle chain (each puzzle causes the next), teaching every co-op mechanic
- [ ] Creatures introduced once both players are in the van
- [ ] NPC traffic that thins out and disappears halfway
- [ ] Colour and mood slowly greying towards the coast
- [ ] Coast watchtower: first sight of the beach; stamp it on the map
- [ ] Optional puzzles (they count towards the hidden tracker)

## Milestone E: Bessi beach and Naresh
- [ ] Beach greybox: sand, sea, promenade, empty lit stalls, boats, casuarinas, memorial
- [ ] Photo clue: find the spot the photo was taken from
- [ ] Supernatural smoke; the Five Roses rise from the sand; Naresh in the fifth
- [ ] Evidence there was never a friend
- [ ] Naresh gym: commands (carry, store, refuel, hold, wait, follow) and random acts
- [ ] 1-2 fun puzzles showing what Naresh can do; then the weather turns

## Milestone F: The return and the ending
- [ ] Storm gym: gusts that can throw the van; driving carefully gets through
- [ ] The different road home; the old road under the storm
- [ ] Return puzzles using everything learnt; Naresh can solve them faster but chaotically
- [ ] Creatures follow Naresh; Naresh taken if he goes alone (left within sight, far)
- [ ] Dark, rain, eerie; brightening near Naresh's home
- [ ] Naresh's home: mother and sister; hidden tracker for 100% optional puzzles
- [ ] The drive home in full sun; watchtower view of every puzzle site
- [ ] Phone notification: Naresh heading to LiveStander; end screen

## Milestone G: Finish
- [ ] Full audio pass, music and ambience
- [ ] Settings menu (sensitivity, volumes, text speed)
- [ ] Windows `.exe` export
- [ ] Full playthrough QA, controller testing, save/load testing

## Polish stage (after the whole game is built and tested)
- [ ] Agree the art direction with you (realistic "RDR2-like" vs stylised)
- [ ] Show each asset (van, trees, grass, flowers, clouds, landmarks, Five Roses,
      beach...) for approval, then replace the block-outs one by one
- [ ] Lighting, sky and weather looks
