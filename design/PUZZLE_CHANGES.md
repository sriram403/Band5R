# Puzzle changes (Milestone G, the puzzle talk)

One puzzle at a time, in the order of `notes/TEST_PUZZLES.md`. For each:
what the user asked for, my proposal (shaped to fit the puzzle and the
world, `notes/PRINCIPLES.md` 10), my own extra ideas (marked as
suggestions), and the questions. **Nothing is built until the user has
reviewed the proposal.** Status per puzzle: *proposed* → *agreed* →
*built* → *approved*.

**The aim for every puzzle (the user, 2026-10-05):** keep both players on
their toes from the moment they enter. They can't see each other's side,
each needs what the other knows, and every mistake has a quick, funny,
visible consequence, so they keep talking.

---

**The voice of the game (the user, 2026-10-05): instructions come from
Naresh.** What to do, how a thing works, "it's locked": in his words, so
he's useful even while he's missing, and the world stays real. *Proposed
how* (round 2 of #1 below): on the way out, notes he left where he passed
(he came through every place days ahead of you) and his old texts arriving;
from Bessi on, him saying it. Plain narration stays only for what you see,
hear or feel ("SPLAT! You're covered").

**More rules for every place (the user, 2026-10-06, at the windmill):**
- **Get both players out of the van.** Every stop is designed so the van
  has to stop and both players are needed on foot, each with a job.
- **Never repeat a puzzle,** in how it plays or in what it's for. When
  the user asks for something that repeats an earlier puzzle or one of
  their own earlier ideas, **say so** and suggest a way round it.
- **Not everything has to be a puzzle:** a challenge is fine (the
  windmill). A place rewards with a view, the challenge itself, and/or a
  new ability.
- **Fun mechanics:** at least three abilities like the head-butt, just
  for fun, usable on your partner, Naresh and the van from then on, each
  learned at the place that needs it.
- **Mistakes have real consequences:** the windmill falls on you and you
  start the challenge again.

## 1. The water works: round 1 and round 2 *approved* (2026-10-05), pushed

### What the user asked for

1. **Split the two players** so they can't see each other: one in a room
   pumping, the other at the valves. Use the red (brick) building as the
   pump room. Its key is on top of the water tower: climb it to get the
   key. The tank area is open ground you can walk right through. It should
   look lived in, but no story details yet (that comes in the next phase).
2. **The grey tank has a consequence.** When it fills up, it dumps its load
   on the player near it. They're covered, and everything they do runs in
   slow motion until they dry off. Then the grey tank is empty again. The
   pumper learns that it's funny to do to the partner, but it wastes time.
3. **The grey tank fills much faster than the blue one:** two or three
   wrong pumps and it's full. So the two have to keep reporting how the
   tanks are doing.
4. **A valve change makes liquid run from the blue tank into the grey
   one,** so a careless turn costs you.

### My proposal

**The two places**

- **The pump room** is the brick pump house, made into a room you can go
  into. Inside are the hand pump lever, the pressure gauge and the flow
  lamp. The lamp lights whenever water flows anywhere, so it never says
  *which* tank. The room has no window onto the yard (at most a grimy one
  that only lets light in), so the pumper can't see the tanks at all.
  - It looks lived in, as block-outs: a chair, a workbench with a kettle
    and a mug, a coat on a hook, a calendar, a bare bulb.
  - The door is padlocked.
- **The key** hangs on a hook on a catwalk round the top of the water
  tower ("BESSI WATER CO."). A ladder runs up one leg. The climb takes
  about 10 s; you come down, unlock the door, and it stays open.
- **The tank yard** stays open ground: valves A and B, the pipes, the
  grey tank and the blue tank. Each tank has a sight glass showing its
  level, and only the valve player can see those.
- **What each one knows:**
  - the pumper knows the pressure and whether water is flowing;
  - the valve player knows the valve settings and both tank levels.

  Neither can see what the other knows, so they talk all the time.

**The grey tank** (the sludge tank: waste water from the filters)

- **It fills fast:** about 2 s of pumping on the wrong route fills it
  (2-3 strokes of the lever), at any pressure. The blue tank still takes
  about 15 s of steady pumping in the green.
- **The warning:** at about three quarters full it gurgles. When full, it
  groans and its lid rattles for 2 s, and the valve player hears it.
- **It bursts:** the lid blows and grey-brown sludge rains over the tank
  yard. Then the grey tank is empty.
  - **Whoever is in the yard is covered**, wherever they stand in it.
  - The pumper, inside, is safe. They hear the boom and the needle falls
    to zero.
- **Covered = slow motion,** for about 20 s at 40% speed, easing back to
  normal over the last 5 s:
  - walking and running;
  - turning your view;
  - jumping (you float up and drift down);
  - using things.

  You can see it on you: drips round the edges of your view, squelching
  footsteps, and a trail of drips. Your partner sees you brown and
  dripping.

**The valves leak blue into grey**

- Turning a valve while the line is under pressure (the pumper still
  pumping, or the needle up) sends a **gulp of 20% of the blue tank** back
  into the grey one. So the valve player has to shout "stop pumping!"
  before every turn, and the pumper has to stop.
- **Valve B's slips** (twice, as now) also gulp 20% back into the grey
  tank. A slip that isn't caught quickly can tip the grey tank over.

**What stays:** the instruction plate, the solution (A on to B, B to the
blue tank), the coolant jug and the Memory Fragment as the reward, and the
hose splitting on the way in. One player can still do it alone, just
slowly (pump, walk out, look, walk back).

### My extra ideas (suggestions: yes or no each)

- **S1. A rinse tap in the yard.** A covered player can stand under the
  yard's standpipe and hold E to wash the sludge off in about 3 s instead
  of waiting 20. That gives a choice: walk to the tap slowly, or wait.
- **S2. Pumping in rhythm instead of holding E.** Press E each time the
  lever reaches the top (the pumper hears the creak). Too fast and the
  pressure jumps (the relief valve bangs); too slow and it sags. The
  pumper then has a real job of their own.
- **S3. A view from the tower.** From the catwalk you can see the yard's
  pipes from above, so whoever fetches the key can study the route on the
  way down.
- **S4. The pumper learns the cost the funny way.** After the first burst,
  the gauge's needle sticks at zero for a few seconds ("the line's full of
  sludge") before pumping works again.

### Your answers (2026-10-05): **agreed**

Anyone in the tank yard; 40% for ~20 s + 5 s back; the grey tank in ~2 s
of wrong pumping; a 20% gulp; S1-S4 all in.

### As built (2026-10-05, `../MPG_dev` branch `g2`)

- **The pump house** (`LevelLandmarks._pump_house`): walls with a doorway,
  no window, a bulb, the bench, kettle, mug, toolbox, chair, coat,
  calendar. The door with its padlock is the puzzle's (`CoolingStation`):
  only the player who took the key can unlock it.
- **The water tower** (`_tower_catwalk`): a ladder on the road side, a
  railed catwalk at 14.5 m, the key on the tank wall on the yard side.
  From there the yard's pipes read from above (S3).
- **The pump** (S2): one press of E is one stroke (0.6 s, +0.14 pressure);
  pressing before the lever is back up is a rushed stroke (+0.24, a
  clank); the line loses 0.10 a second, the overflow route 0.30 more.
  Steady strokes creep up through the green, so the pumper pauses a beat
  to hold it. A second press within 0.1 s is ignored (a double read).
- **The grey (SLUDGE) tank:** 0.5 a second of flow its way (2.2 s of
  pumping measured), the gurgle at 75%, the groan 2 s, the burst: sludge
  particles, the hatch flies up, a puddle for 18 s; everyone in the yard
  (`in_yard`: the yard's rectangle, under 4 m up, not in the pump house)
  covered; the tank empty; the line clogged 4 s (S4).
- **Covered** (`PlayerRig.slime`): `slow()` = 0.4 for 20 s, easing back
  over 5 s: speed, acceleration, turning the view, the jump (velocity x f,
  gravity x f^2: as high, slower), climbing, held jobs (dt x f) and taps
  (a delay of 0.5/f - 0.5 s). Brown avatar, drips on the ground, squelch
  steps (pitched down), a drip overlay round the view (`PlayerHUD`).
  Measured: 1.5 s of walking 6.45 m clean, 2.58 m covered (40%).
- **The standpipe** (S1): hold E 3 s (2.4 s measured) to rinse off.
- **The gulp:** a valve turned with the pressure over 0.2 or the lever
  moving: 0.2 of the blue tank out, grey +0.35. B's slips gulp too.
- **Sounds** made here: `tools/gen/sludge.py` (squelch, gurgle, groan,
  splat). Sfx now plays `.wav` too and takes a pitch.
- **Tests:** `waterworks` rewritten (the key by the real ladder, the door,
  the burst on P2 by the valves, P1 inside untouched, slow walking
  measured, the rinse, the gulp, the slips): 0 failures. `puzzle_resets`
  checks the door and key go back. The walk: `tools/live/make_puzzle1.py`.

### Questions for you (answered above)

1. Who gets covered: **anyone in the tank yard** (my pick, so you can't
   dodge it) or only someone right by the grey tank?
2. Slow motion: **40% for ~20 s, then 5 s back to normal**. Right amount?
3. The grey tank fills in **about 2 s of wrong pumping**. Right?
4. The gulp when a valve turns under pressure: **20% of the blue tank**?
5. Which of S1-S4 do you want?

### Round 2: what the user asked for (2026-10-05, after the video)

1. **No jug and fragment popping out of the tap.** The van already carries
   a coolant jug (P2's, from the opening). Fill *that* at a tap on the blue
   tank, then pour it into the van: every piece connected.
2. **Test as if the jug is on the van.** In a real play, if it isn't, remind
   the players to fetch it.
3. **A checklist in the opening**, from P1 (the driver) to P2 by phone: the
   things to bring. Not blocking: it only tells you.
4. **Every instruction in the game written by Naresh**, so he's useful and
   it's real: how-to's, "the door is locked", and so on.

### Round 2: my proposal

**The tap and the jug**

- The blue tank gets a brass **tap** at its foot (where the jug used to
  appear). Full blue tank = coolant ready. Hold the jug, look at the tap,
  **hold E**: it fills at 1 L a second (the jug holds 5 L; you hear it, the
  tank's level drops a little). Then carry it to the van's grille and pour,
  as now (3 L seals the split hose).
- **The jug is P2's** from the opening (`HouseCoolantJug`, on the rack's
  right-hand slot, 2.5 L in it). Measured in the code: 2.5 L is not enough
  to seal the hose (it needs 3), so pouring it early doesn't skip the puzzle;
  it just leaves the jug empty for the tap.
- **F1 → Puzzles → 1** puts the jug on the van's rack (empty) if it isn't.
- **No jug anywhere near** (not on the van, not in anyone's hands) when the
  blue tank fills: Naresh's note on the tap says to bring something to
  carry it in, and the tap's prompt says "You need the coolant jug (P2's
  house)". Nothing is blocked: you can drive back for it.

**The checklist** (the opening)

- P1's first text to P2 becomes a list: *"Bring: the red fuel can (fill
  it from the drum in the shed), the blue coolant jug, torch batteries."*
- **Not blocking:** today the opening only ends when both the can and the
  jug are on the rack. Proposed: it ends when you're both in the van. The
  gear steps stay as goals, but skippable.

**Naresh's voice, here** (the pattern for every puzzle on the way out)

- **His note on the pump house door,** read with E (the padlock prompt stays
  short: "Padlocked"): *"Locked. Key's up the water tower, we found it
  after an hour. Put it back after. - N"*. The "we" fits the twist: he
  writes as if his friend were there.
- **His note pinned by the pump** (replaces the instruction plate's
  how-to): one stroke at a time, keep it in the green, and "NEVER turn a
  valve while someone's pumping, the grey one blew all over us".
- **His note on the tap:** "Bring your own can. We used our water bottles.
  Don't."
- **The hint (hold H) becomes his words** for this step too.
- Kept as narration: what you see and feel (the burst, being covered, the
  turbine starting).

**The Memory Fragment**

- Out of the tap's way. **Proposed:** on the pump house bench, beside
  Naresh's mug (he sat there), so the pumper finds it while working.

### Round 2: my extra ideas (yes or no each)

- **S5. The checklist ticks itself.** On the phone, each thing gets a tick
  when it's on the van's rack, so you can see what you're leaving behind.
- **S6. A leaky fallback.** An old oil can on the pump house bench: it
  holds coolant but leaks 1 L a minute, so it works if you rush, and it's
  funny. Then nobody has to drive back to P2's house if the jug was left
  behind.
- **S7. His notes collect in the journal** ("Naresh's notes"), so you can
  read them again later, and on the way home they read differently.

### Round 2: your answers (2026-10-05): **agreed**

My picks for 1 (hints and how-to's in his words, the objective line plain)
and 2 (puzzle by puzzle, then one pass at the end for the rest); the
fragment by his mug; the gear steps skippable; S5-S7 all in.

### Round 2: as built (2026-10-05, `../MPG_dev` branch `g3`)

- **The tap** (`CoolingStation._build_coolant_tap`): brass, at the blue
  tank's foot beside its sight glass; holding a jug (or the oil can) to it,
  hold E: 1 L a second (5 L in 5.0 s measured); the tank's level drops a
  little. Empty-handed it says what you need. No jug appears any more.
- **P2's jug** (`HouseCoolantJug`): F1 → Puzzles → 1 puts it on the
  rack's right-hand slot, empty (`DevMenu.van_jug`), and splits the hose.
  Found on the way: a jug taken off the rack with the van nose-up on the
  climb popped out inside the rack's bars, snagged and dropped from your
  hands; anything taken off the rack now goes straight into your hands.
- **Naresh's notes** (`world/NareshNote.gd`): on the door, by the pump (on
  the plate, which now only says BESSI WATER CO. / COOLANT MIX PUMP), on a
  stake by valve B (the old "WORN SEAT" label), by the tap, on a stake by
  the standpipe. E reads one; the story keeps them (`Story.notes`, saved)
  for the journal's second page (A / D, pad D-Left) (S7). The pop-up lines
  now only say what you see and feel. The hint (hold H) quotes his notes.
- **The bench:** the fragment by his mug (there from the start), and the
  leaky oil can (`items/LeakyCan.gd`, 4 L, 1 L a minute, S6).
- **The checklist** (S5): P1's first text to P2 is "I'll come get you.
  Bring:" with three lines that tick themselves (the filled fuel can on
  the rack, the coolant jug on the rack, the torch batteries fitted).
  Getting in the van together at P2's house ends the opening, gear or not
  (`t_opening_skip`).
- **Tests:** `waterworks` (the note, the rack, the tap, the pour, the bench,
  the leak, the journal page), `opening_skip` (new, in set:opening),
  `puzzle_resets`: 0 failures.

### Round 2: questions (answered above)

1. **How far does "written by Naresh" go?** (a) The hints (hold H) and the
   how-to messages only, with the objective line (top left) staying a short
   plain goal. Or (b) the objective line too. **My pick: (a)**, because the
   objective line is the game's menu-like reminder.
2. **Now or puzzle by puzzle?** **My pick:** do it for each puzzle as we
   rework it (here first), then one pass at the end for the rest (the
   opening, the drives).
3. **Is the fragment on the bench by his mug all right?**
4. **The opening's gear steps skippable:** yes?
5. **Which of S5-S7?**

---

## 2. The windmill: *agreed* (2026-10-07), being built

### Your answers (2026-10-07)

1. **Power here:** yes, a windmill making power is realistic. The lift
   bridge (#5) gets a different job when we reach it.
2. **One napin, shared.**
3. **When it falls:** restart the challenge right there.
4. **The map:** P1 has no map until the pick-up, and **only one player
   holds the map at a time**. To use it the other has to go up to them
   and take it.
5. **S1-S4 yes; S5 no**, your three fun mechanics instead:
   - **the head-butt** (above);
   - **the map snatch:** grab the map off your partner and sprint away
     while they chase you;
   - **the push out of the van:** either player can shove the other out
     of the van at any time, even at full speed.

**How I'll build the two new ones (my choices, judge them in the video):**
- *The map snatch:* the map is one thing in someone's pocket (it doesn't
  fill your hands). M opens it only for whoever has it; the other gets
  "P2 has the map". Look at your partner within 2 m and press **E**:
  "Take the map" (it works when they have it open too, and between the
  van's seats). Then run: sprinting is as fast as theirs, so it's a real
  chase. The map is saved with who has it.
- *The push out of the van:* seated, empty hands, press **G** (pad: hold
  **RB** for half a second, since RB opens the journal in a parked van).
  The other seat's player is thrown out of their door with the van's speed
  plus a shove sideways: the same tumble as being hit by the van. A pushed
  driver leaves the van rolling on with nobody at the wheel. Naresh on
  the bench is safe (not for now).

### As built (2026-10-07, `../MPG_dev` branch `g4`)

- **`puzzles/WindmillPower.gd`** replaces the brake puzzle. The windmill
  stands 44 m off Home Lane, its fan facing the lane: four legs on cracked
  stone footings (8 m apart), a collar at 7 m, a 2 m rusty neck to the
  walkway at 22.6 m, the head and tail vane, the 18-blade fan (12 m across)
  at 24 m. A flat pad under it, and no trees within 46 m.
- **The junction gate** across Home Lane just short of J1: a red-and-white
  boom, "JUNCTION CLOSED / NO POWER", a dead lamp, 40 m of fence and
  boulders either side. Measured: driving at it, the van stops 3 m short.
- **The starter lever** 18 m out in front of the legs, with Naresh's note.
  Held (E / X): 0 to full in 45 s; let go, it runs down twice as fast.
- **The legs:** at 20 / 40 / 60 / 80 % one leg (random) slides out 0.5 m
  over 8 s, the windmill leaning up to 5 deg that way. Three head-butts
  from the start of the slide put it back. S2: a butted leg slips again one
  time in four while it's still winding up. The speed can't reach full
  while a leg is out.
- **The fall:** a leg left 8 s: 2 s of groaning, then it topples over 2.6 s
  towards the nearest player on foot. Under it (its length, the neck's
  width, the fan's near the top): white, frozen. 3 s later it stands again,
  still, and everyone near is put back by the lever (S4: the partner's text
  "you ok? I think I'm flat").
- **Full speed:** a deeper hum, the gate's lamp on, the boom swings up, 9
  street lamps light one by one (S3: the lane to J1 and both roads after
  it). 5 s later the rope ladder unrolls down the back (1.6 s) and can be
  climbed (24 m, ~10 s).
- **The walkway:** stepping onto it puts both roads to Last Fuel, the lake,
  the barn and the lookout onto the map ("What a view"); the chest (E to
  open, E to take) holds the **napin**; Naresh's second note above it.
- **The napin:** `MapState.STAMP_TYPES = ["napin"]`, one pin, putting it
  again moves it; none before the chest ("No pin yet: you can only look");
  the nav reads "NAPIN 1.2 km / RIGHT >". The beach step is "put the napin
  on it".
- **One map, one holder** (`MapState.holder`, saved): on the desk upstairs
  at P2's in a new game ("Take the paper map": P2's opening step 4 now);
  M only for the holder, the other is told who has it; look at the holder
  within 2.3 m and press E / X: "Take the map off P1" (even open, even
  between the van's seats).
- **The head-butt** (G / RB, hands empty, on foot): a lunge of the view;
  your partner staggers back ~1.3 m with a jolt and "* BONK *"; Naresh is
  knocked and says something; the van rocks on its springs; loose things
  (even ones set out on shelves) pop up and away; a creature only hears it.
- **The push** (seated: G, pad hold RB 0.5 s): the other seat's player is
  thrown out of their door with the van's speed plus a sideways shove
  (tested at 33 km/h: tumbles, gets up). A pushed driver leaves the van
  rolling on.
- **F1:** Puzzles → 2 puts you both in the van 30 m short of the gate; a
  jump past the windmill sets it turning (and the napin found past the
  chest), at or before it resets it and takes the napin back; any jump
  gives P2 the map if it was still on the desk.
- **Tests:** `windmill` (the gate stops the van, P1 walks to the lever and
  holds, P2 walks to the first sliding leg and butts all four, the gate,
  the lamps, the ladder, the climb, the view, the chest, back down),
  `windmill_fall`, `fun` (head-butts, the map snatch on foot and in the
  van, the push at speed, the pad's held RB), and the old ones changed for
  one pin and one holder (map, feedback, tower, story, dev, puzzle_resets,
  save, the opening set).

---

### Round 2: what the user asked for (2026-10-07, after playing it)

1. **The head-butt needs visuals:** a wind-up and an impact, everywhere.
2. **The legs:** every butt should show it pushed the leg back into place.
3. **The chest up top** was awkward to reach and its note hidden: both
   easy to see and reach. (And from now on: nothing placed awkwardly, for
   any place: we build for humans.)
4. **A small room next to the windmill** (closed is fine) with a wire from
   it to the gate: show the power travelling to the gate and the lamps.
5. **A proper gate:** the fence floated at one end and went into the
   ground at the other, and the van could drive round it over the grass.

### Round 2: my proposal

1. **The head-butt, seen by both of you.**
   - *Wind-up* (0.15 s): your view pulls back and up a little, as you rear
     your head; your partner sees your avatar's head tip back.
   - *The lunge and the impact* (0.1 s): your view snaps forward with a
     short shake. Where it lands: a white burst of little stars, a "BONK!"
     that pops up and fades (1 s), and dust if it's the ground or a leg.
   - *Hitting nothing:* the lunge and a "whoosh", no burst.
   - *Butted yourself:* a ring of stars circles your view for 1 s.
2. **The legs: you see each butt land.**
   - A sliding leg's foot gets a red flashing light (it's going: easy to
     spot from the lever too).
   - Each butt: the foot jumps back on its footing with a little overshoot,
     sparks at the shoe, a dust puff, and a dent counter on the footing:
     1, 2, 3 white marks, one per butt that counted.
   - Back in place: a heavy bolt-down plate slams onto the shoe (a clank)
     and the light turns green and stays green. You can always see which
     legs are done.
3. **The chest and its note.** The chest moves to the open side of the
   walkway, facing you as you step off the ladder, 1.5 m from the top
   rung, in the light, painted bright (red with a yellow lid). Naresh's
   note is pinned on the chest's lid at eye height when open, and on a post
   by it before that, readable from the ladder top. The view spot is the
   other side. I'll check it from where you stand, in screenshots.
4. **The power hut and the wire.**
   - A small brick switch hut (2.5 x 2 x 2.5 m, locked door, a small
     window, "WINDMILL No. 3 / SWITCH HOUSE") between the windmill and the
     road. A thick cable runs from the windmill's collar down a leg into
     it.
   - From the hut, wooden poles every 12 m carry a wire to the gate and on
     along the lane past it, where the street lamps are.
   - When it catches the wind: the hut's window lights up and it hums, then
     a bright spark of light runs along the wire, pole to pole (about 3 s),
     into the gate (its lamp lights, the boom lifts), then on along the
     road, each lamp lighting as it passes.
5. **A proper gate.**
   - The fence follows the ground: a post every 2.5 m, sitting on the
     ground, each rail running post to post. Nothing floats or sinks.
   - It runs out 60 m each side and ends in a thicket (trees and boulders
     close together) so you can't drive round its ends either.
   - A test drives the van at both ends of the fence and round the gate:
     it must not get through. And screenshots of the fence from the road.

### Round 2: my extra ideas (yes or no each)

- **S6. A power meter on the hut** facing the lever: a big dial 0 to
  100 %, so the lever player sees how far it's wound up without guessing.
- **S7. The leg light visible from the lever** is part of 2 already; also
  make it a sound cue with direction (a screech from that leg's side), so
  the runner can find it by ear.
- **S8. Butting something solid** (a wall, a tree): a dull thunk and you
  stagger back a step. Silly, cheap, makes the butt feel physical.

### Round 2: your answers (2026-10-07): **agreed**

1. The chest: yes, **and make the walkway bigger** if it's cramped; the
   whole place should look lived in (placed by a person), nature as nature
   would leave it, nothing programmatic (a rule from now on).
2. The spark along the wire: yes.
3. S6, S7, S8: all yes.

### Round 2: as built (2026-10-07, `../MPG_dev` branch `g5`)

- **The walkway** is bigger (6.8 x 6.6 m, struts under it). Stepping off
  the ladder, the chest (red, yellow lid and bands) is 1.2 m straight
  ahead against the back of the gearbox housing; Naresh's note above it at
  eye height. The napin only shows once the lid's up. Left lying about: a
  toolbox with a flask, a coil of rope, a folded tarp, an oil can.
- **The head-butt:** 0.14 s rearing back (your view and your avatar's
  head), the lunge with a shake, stars and a "BONK!" where it lands (metal
  adds sparks: "CLANG!"), stars circling the view of whoever's butted. S8:
  a wall, a tree or a post: "THUNK", you stagger back a step, stars.
- **The legs:** a warning light on each footing (red flashing while it
  slides, green once back); each butt jumps the foot back with an
  overshoot, dust and a white mark on the footing (1-3); back in place, a
  bolt plate slams down. S7: the screech comes from that leg's foot.
- **The switch house** (`puzzles/WindmillWire.gd`) on the lane side of the
  windmill, facing the lever: brick, a locked door, a bench, a bucket, a
  rain barrel, "WINDMILL No. 3 / SWITCH HOUSE", S6 the POWER dial (its
  needle follows the fan). A cable runs down a leg into it; poles (each its
  own lean and height) carry the wire to a pole by the gate and on from
  street lamp to street lamp, both roads after J1. Caught the wind: the
  window lights, it hums, a spark runs along the wire; it reaches the gate
  in 1.7 s (the boom lifts) and lights the lamps one by one as it passes.
- **The gate:** a yellow motor housing on a concrete pad, the boom resting
  in a fork, the sign on its own post. Fences (`world/Fence.gd`) follow the
  ground post by post (spacing 2.4-3.2 m, each post its own lean and
  height, rails post to post), 150 m west up the hill and 80 m east into
  the trees, each ending in a thicket (`world/Thicket.gd`: old trees,
  young ones crowding them, bushes, half-sunk rocks).
- **Measured** (`gate_bypass`): driving at the fence's middle, its ends and
  into the thickets, the van is stopped every time (7 of 7). **Not solved:**
  further out a van can still get round: east by weaving between the
  forest's trees (6-10 m apart), west across the open hill beyond the
  thicket. Question for the user.

### Round 2: questions (answered above)

1. **The chest:** at the walkway's open side as above, fine?
2. **The wire's spark** travelling to the gate and lamps: yes?
3. **Which of S6-S8?**

### The proposal (2026-10-06)

### What the user asked for (2026-10-06)

- **A new windmill, bigger and menacing but realistic:** four legs that
  join into one huge neck, the fan on top as a windmill has it.
- **Why we stop:** the windmill is dead, so there's no power and the road
  on can't be crossed. Spinning it makes the power that opens the way.
  The stop has to get **both players out of the van and on their feet**
  (a rule for every place from now on).
- **Clear the area:** everything round the windmill goes (rope, brake,
  miller's box, trough, ladder, platform). Only the lever stays.
- **The lever is a capacitor:** one player holds the lever all the time
  (they can look around) and the fan spins up slowly, faster and faster.
  Once it's at full speed they can let go: the wind keeps it going.
- **The legs slide:** as it speeds up, the legs come loose one at a time,
  at random. The other player **head-butts** each sliding leg back into
  place ("holding it in the ground"). If they're too slow, the windmill
  **falls, always on top of them**, and they start again.
- **The ladder unrolls by itself:** it's rolled up by the head. Once the
  fan is at full speed the shaking makes it roll down, still fixed at the
  top. Now you can climb.
- **The reward:** the view from the top, and a chest up there with the
  **napin** ("navigation pin"). Only **one** pin; the different stamps go.
  The paper map itself is found at P2's home at the start.
- **A new ability, the head-butt:** from then on you can head-butt your
  partner, Naresh and the van, just for fun. The game should have **at
  least three fun mechanics like this**.
- It's a challenge more than a puzzle. That's fine.

### My proposal

**The blocker: a powered gate at Windmill Junction (J1).** The lane from
P2's home ends at a red-and-white boom gate just before the fork:
"JUNCTION CLOSED / NO POWER". A ditch on one side, a fence with boulders
on the other, so you can't drive round it. Its lamp is dead. The windmill
stands 25 m off the road beside the gate, its lever by the gate. The van
has to stop, so you both get out.

**The windmill, rebuilt (the old one's hub is at 14 m):**
- four steel legs on stone footings, splayed 8 m apart at the ground,
  rising 7 m to a collar, braced with cross-ties;
- from the collar, **one neck**: a rusty steel tube 2 m thick, up to the
  head at **24 m** (about an 8-storey building: real for a big farm
  windmill, menacing from the lane);
- the head: a 3 m gearbox housing with a long tail vane, and a narrow
  walkway with a rail round it. The rolled-up rope ladder is lashed there;
- **the fan:** the windmill fan you know, 12 m across, 18 blades, pale
  and weathered. It looms over the road and creaks.

**The lever (whoever takes it):** an old starter lever on a post 14 m out
from the legs, close enough to watch all four. **Hold E (pad X)** and the
fan winds up:
- held, its speed climbs from 0 to full in about **45 s**;
- let go too early and it **slows twice as fast** as it climbed;
- at full speed it **"catches the wind"**: a deeper hum, the gate's lamp
  comes on, and the lever player can let go;
- the lever's creak and the fan's whoosh rise with the speed.

**The legs (the other player):** at **20, 40, 60 and 80 %** speed one
leg comes loose, in a random order (one at a time, each leg once):
- a grinding screech, dust from its footing, and the foot **slides
  outwards about 0.5 m over 8 s**. The whole windmill leans that way and
  the fan wobbles;
- **head-butt it 3 times** (G / pad RB with empty hands, within 1.5 m,
  facing the leg) to knock it back onto its footing: each butt pushes it
  a third of the way back, with a clang and a small shake of your view;
- a leg that slides all the way (8 s without enough butts) **brings the
  windmill down**: 2 s of a loud groan and the lean speeding up (time to
  run), then it **falls towards whichever player is nearest**. Anyone
  under it: a crash, a cloud of dust, white screen, "The windmill came
  down." Then the challenge resets: the windmill standing, the fan
  stopped, both of you by the gate (question 3).

**The ladder:** 5 s after the fan catches the wind, the shaking works the
rolled ladder loose. It unrolls down the neck with a clatter and hangs to
just above the ground, fixed at the walkway. Climb it (E, then W), 24 m.

**At the top:** the walkway round the head, the fan thundering past a
few metres away, and **a chest** with the **napin**. The view: both roads
on to Last Fuel, the lake, the ridge, and below, the gate lifting.

**The napin (one pin):**
- the paper map's five stamps (fuel, danger, puzzle, shortcut,
  unexplored) go. There is **one napin** (question 2);
- open the map, put the napin anywhere; putting it again moves it; RMB /
  pad X takes it off;
- **the van's nav points at the napin** (it follows stamps today);
- what used stamps changes with it: the coast watchtower's "stamp the
  beach" becomes "pin the beach";
- before the windmill you have the map but no pin: you can look, not
  mark.

**The paper map at P2's home:** P2's opening step "stamp the windmill on
the map" becomes "**take the map from the kitchen table**". Naresh has
pencilled a ring round the windmill (he went this way). P1 has no map
until the pick-up; their M says "P2 has the map" (question 4).

**The head-butt (the first fun mechanic):** **G / pad RB with empty
hands** (that's throw, which does nothing with empty hands: no new
button). A quick lunge of your head and a "bonk":
- your partner staggers back 1.5 m, their view jolts, a few stars; both
  hear it;
- Naresh staggers and says something ("Oi!", "Really?");
- the van rocks on its springs with a hollow thump;
- loose things (cans, crates, boxes) are knocked over or away;
- **not creatures** (no fighting in this game): butting at one only makes
  a noise it hears;
- half a second between butts. Learned here (Naresh's note teaches it),
  usable everywhere after.

**Naresh's notes here (rule 24):** one pinned to the lever post:
*"Starter lever. Hold it till she catches the wind, don't let go. The
footings are cracked and the legs walk when she spins up. Head-butt them
back. Works every time. N."* One on the chest at the top: *"The napin.
Stick it where you're going, the van knows the way."*

**What goes from the old one:** the snagged rope, the brake, the cut, the
miller's box and its valley map (`MapState.reveal_valley`), the trough,
the platform, the old ladder. The tag (T) was first used here; it stays
in the game (S1 uses it here again).

### The repeat (you asked me to say it): power that opens the way

The water works (#1) already makes the power that runs the lift bridge
(#5). Here the windmill would also make power that opens the way: the
same idea twice, close together. My suggestion: **keep it here** (it's
the first and simplest) and **change #5 when we get to it**: the water
works' turbine only lights the lamps along the road, and the lift bridge
runs by hand (cranks and the counterweight; it's half that already).
Question 1.

### My extra ideas (suggestions: yes or no each)

- **S1. The lever player is the eyes.** From the lever they see all four
  legs; the butting player is under the neck and can't see the far side.
  A leg starting to slide is easy to miss from below: the lever player
  tags it (T / RT, still holding the lever) or shouts.
- **S2. A butted leg can slip again.** It wobbles for a few seconds and,
  while the fan is still speeding up, slips again one time in four. It
  keeps the runner busy to the end.
- **S3. The gate opens with a show.** At full speed the gate's lamp
  blinks, a buzzer, the boom swings up, and the dead street lamps along
  the next 200 m of road light one by one: the power you made, visible.
- **S4. The fall is funny, not cruel.** After the white screen you wake
  by the gate with dust on your view and a text from your partner ("you
  ok? I think I'm flat"). Back to trying within 5 s.
- **S5. Two more fun mechanics, for later** (only noted now): (a) **a
  leg-up:** one crouches, the other stands on their back to reach
  something high; (b) **push-starting the van:** with a flat battery,
  both push, the driver lets the clutch in. Each learned at a place that
  needs it.

### Questions for you

1. **The power repeat:** keep it here and change the lift bridge (#5)
   later (my pick), or give the windmill a different job?
2. **Napin:** one shared pin for both of you (my pick), or one each?
3. **When it falls:** restart the challenge right there (my pick), or
   load the last save?
4. **Before the pick-up:** P1 has no map (my pick), or both can look?
5. **Which of S1-S5?**
