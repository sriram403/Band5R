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

## 1. The water works: round 1 and round 2 *built* (2026-10-05), awaiting your look

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
