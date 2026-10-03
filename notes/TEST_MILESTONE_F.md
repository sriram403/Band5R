# Milestone F: your test checklist

Milestone F (the return) is tested one part at a time. This page grows as
each part is ready; each part says what to do, what should happen, and what
to tell me. Your answers to the design questions are in `design/RETURN.md`
("Decisions").

Two players (P1 on keyboard + mouse, P2 on the controller), split screen.
Note anything that feels wrong, slow, confusing or ugly, with the step number.

**Testing F3 to F8 in one go (your plan, 2026-10-01).** F1 and F2 you've
tested. F3-F8 were built back to back with my recommended answers; each part
below has its steps and its "Decisions to confirm". Either:

- **play straight through:** F1 → Story → "North on the coast road", then
  drive on: the village (F3), the salt pans (F4), the estuary bridge (F5),
  the rail tunnel (F6), the mast on the hill (F7), Naresh's home and the
  drive home to the end (F8). By my automated drive the roads alone are
  7.5 min; with the puzzles about 25-30 min; or
- **jump to each part** with the F1 → Story row named at the top of its
  section.

Report per part (F3, F4, ...), and say which decisions you'd change.

**How each step reads (2026-10-04, your ask):** a plain sentence of what to
do and why; under it *Exactly how* (optional, the buttons and where to
stand) and **You should see** (what tells you it worked). Later: a
screenshot for each "you should see" (noted in `notes/POLISH.md`).

**Every jump, the same way:** F1 opens the developer menu; arrow keys to the
tab and the row; Enter jumps there; **then F1 (or Esc) to close the menu**
(it stays open after Enter). A jump gives you both the binoculars.
**Binoculars: hold RMB (P1) / hold LT (P2).** (Pad B is crouch.) Through them
you can give Naresh jobs up to 150 m away; 60 m by eye.

---

## F1. The storm (the storm gym)

Start `Play.bat`, **New game**, then **F1** (developer menu) → **Gyms** tab →
**storm**, Enter. You both start **right beside the van, facing its driver
door**, on a flat plain at dusk, in the storm: rain, wind, grey fog,
lightning now and then. The road runs straight ahead of the van's nose;
orange-and-white **windsocks** line it on the far side; four white **distance boards** (30, 60, 90, 120 m) stand
beside the road a little way along. The wind blows across the road, from
the windsocks' side.

1. **Look around on foot.** **Expect:** rain falling round you, slanting
   with the wind; the fog closes in so the 30 m board is clear, the 60 m one
   faint, the 90 and 120 m ones gone. Lightning: the whole land flashes pale
   for a moment, thunder a second or two later. You hear rain and wind.
   *Tell me:* is it dark and wet enough? Too dark to play? (Your ears: the
   rain and wind sounds are made here, no recordings.)
2. **Watch a windsock** for half a minute. **Expect:** it hangs down in the
   lulls; about every 7-14 s it **lifts and streams out** as the wind roars
   up, about a second before the gust is at full strength. That's your
   warning.
3. **Get in and drive** (P2 in the passenger seat). **Expect:** the wipers
   sweep by themselves while the engine runs, and park when you switch it
   off. No rain inside the cab. **L** (pad D-pad left): the headlights now
   light the road ahead (*bug fix: since the first prototype they shone
   backwards into the cab; nobody could see it in daylight*).
4. **Drive slowly, ~25 km/h**, along the straight, steering normally.
   **Expect:** the gusts shove the van a little and you correct, but it
   **never tips**, however strong the gust.
5. **Drive fast, 50-60 km/h.** **Expect:** an ordinary gust shoves the van a
   metre or more sideways (on the wet road it slides); a strong one can lift
   it onto two wheels and **throw it on its side** (or its roof). Then
   **R** (pad Back) puts it back on its wheels.
   *Tell me:* does it feel fair? Do you see it coming? Is it fun, scary,
   annoying?
6. **Brake hard from 50 km/h.** **Expect:** it takes longer to stop than on
   a dry road (about 16 m instead of 11.5).
7. **F1 → World → The storm:** turn the storm off (dry, the fog lifts, no
   rain) and on again; **A full gust now**; **Lightning now**. Use these to
   try things on purpose.

What to report: anything above that didn't happen, plus how it felt.

### Decisions to confirm (F1): confirmed by you, 2026-10-01 (for now)

1. **Wipers are automatic** (they run in the rain while the engine is on).
   No wiper key: there was only one right answer ("on"), and the pad has no
   free button.
2. **When a gust can tip the van:** never below 25 km/h; the strongest
   gusts from about 45 km/h; ordinary ones only well above that.
3. **The wet road:** tyres grip 60% of dry, brakes 70% (50 km/h: 11.5 m to
   stop dry, 15.6 m wet).
4. **The warning:** the windsocks lifting and the wind's roar, about a
   second before the gust's full push. Enough?
5. **Gusts every 7-14 s**, mostly from one side, swinging a little.
6. **You can see ~60 m** (30 m clear, 60 m faint).
7. **A tipped van just lies there until R**: no damage, nothing falls out
   (for now).
8. **On foot the wind doesn't push you** (for now).

---

## F2. The storm on the old road (the dead end)

**What this part is:** at the end of Bessi the story sends you north on the
coast road. F2 is what happens if you *don't* listen and drive back the way
you came: you go into the storm, and the road home that way is blocked.

**The old way, in plain words** (you drove it on the way out, in Milestone D):

- **The ghat** is the mountain road with the two hairpin bends and the fog
  (where the creature first came for the van). **The pass** is the top of
  it, where the road comes over towards the sea.
- **J3** is the bottom of the ghat on the river side.
- From J3 the road goes on, the same road, to **the lift bridge** you
  lowered in Milestone D (with the hut and the levers). That road is called
  Pump House Road (it's named on the board at Last Fuel, on the far side of
  the bridge); you don't need the name: just keep going from the bottom of
  the hairpins.

**Getting there.** Start `Play.bat`, **New game**, **F1 → Story**, pick
**"North on the coast road"** (the last row), Enter. You're both standing
by the van at the start of the coast road, Naresh with you, and behind you
over the hills a **black bank of storm cloud**.

   **The van is already pointing north:** north is straight ahead out of
   the windscreen; the storm is behind the van.
1. **Get in** (Naresh too: look at the van, V, *Get in the back*). Drive
   straight ahead (north) a little way. **Expect:** dry, calm, no rain: the storm stays
   behind you.
2. **Turn round (so the van faces back the way its tail pointed) and drive
   towards the black clouds.** Back past the dune
   with the roses, the road climbs away from the sea, south-west, up to the pass.
   **Expect:** as you get under the clouds: rain, wind, fog, the wipers
   start, gusts shove the van (slow down: under 25 km/h it can't tip).
   Over the pass and down the two hairpins to the bottom (J3).
   *Nothing from the way out should happen again* (no burst hose, no
   creature attack on the hairpins).
3. **Keep going on the same road** to the lift bridge (about a minute).
   **Expect:** its leaf stands up again, swaying, the barriers are back,
   every lamp along the road is dark; a message says the storm has the
   power line down and there's no way across. In the hut the panel says
   NO POWER and the levers do nothing.
4. **Turn back.** After about 300 m, **Naresh:** "My friend said north."
5. **F1 → Story**, jump to an earlier Bessi row. **Expect:** the bridge is
   down again, the lamps lit.

**Short cut (to skip the long drive):** after step 1, **F1 → Travel →
"Foot of the ghat (J3)"**, then **F1 → Van → "Bring the van here"**, and drive on
from there (step 3). Or Travel → "The pass" to start at the top.

### Decisions to confirm (F2): confirmed by you, 2026-10-01 (for now)

1. **The storm hugs the old road:** full within 60 m of the Beach Road (from
   the storm bank on), the ghat road, and Pump House Road from J3 to the
   bridge; gone by 160 m. The coast road north (about 220 m from the Beach
   Road at its closest) stays clear.
2. **The wind blows in from the sea** (towards the west).
3. **Why it's a dead end:** the storm brings the power line down, so the
   bridge has no power and the gale has its leaf up again. It can't be
   fixed; it's a world gate, not a puzzle.
4. **His line comes once,** when you're ~300 m back from the bridge with him
   in or by the van.
5. **The coast watchtower's creature** is still there on the way back (as
   before).

---

## F3. The fishing village (the decoy)

**Getting there.** `Play.bat`, **New game**, **F1**, the **Story** tab, the row
**"Nearly out of fuel. The fishing village: the fuel's in the net shed"**,
Enter, then **F1** to close the menu. You're both by the van on the road, a
short walk from the village, Naresh with you, nearly out of fuel. It's dusk.

**The idea.** The fuel is locked in a shed in the village, and two creatures
hang around it. You can't just walk in: they'll come for Naresh. So you use
him as **bait**: send him to the far end of the long jetty, the creatures
follow him out there, and while they're away you grab the fuel. Then you call
him back before they catch him.

**What's there.** Huts, nets on poles, boats on the sand, a long wooden
**jetty** out into the sea, and the **net shed**: brown, flat roof, a sign
**"NETS - PRIVATE"** over its door, a padlock, fish crates stacked up one
side like steps, and a small blue boat on its roof.

1. **Walk towards the village with Naresh, but stop about halfway** between
   the van and the first huts. Don't go in.
   - *Exactly how (optional):* walk from the van towards the huts; stop about
     halfway. You'll see the long jetty out to sea on your right.
   - **You should see:** two creatures pacing near the shed in the village.
2. **Send Naresh to the far end of the jetty.**
   - *Exactly how:* hold **RMB** (P2: **LT**) for the binoculars, look at the
     very end of the jetty, press **V** (P2: **D-pad Up**) and pick **"Go and
     wait there"**.
   - **You should see:** he walks out along the jetty to its end, and the two
     creatures slowly follow him out there. Within about a minute nobody is
     left by the shed. They're slow: it takes them over a minute to reach
     him, and that's your time.
3. **P1: get the key and open the shed.** The key is in the blue boat on the
   shed's roof.
   - *Exactly how:* walk to the shed, round to the side with the crates.
     Jump up the crates one at a time (W + Space, wait to land, again). At
     the top, turn towards the roof and step on. Look into the boat:
     **E "Take the key"**. Walk back down off the roof, go to the shed door:
     **E "Unlock the shed"**.
   - **You should see:** "The padlock gives ... two jerrycans at the back: one
     heavy, one light." Pick up the **heavy** one (E) and carry it to the back
     of the van.
4. **P2: hide by the shed, keep an eye on Naresh, and call him back to you
   before the creatures reach him.** Calling him from a hiding spot next to
   the shed means he comes back past the shed (that matters in step 5).
   - *Exactly how:* go to the shed door and stand with your back to it. Walk
     straight ahead about 10 steps, then turn right and walk about 10 more.
     Turn round: past the corner of the shed you can see the jetty with
     Naresh at its end. Hold **LT** (binoculars). When a creature is getting
     close to him, look at him, **D-pad Up**, **"Follow me"**. Then **don't
     move**: he walks back to you.
   - **Why hide:** the creatures follow him back. Standing in the open, or
     right at the shed door, they'd see you and take you.
   - **If he's taken anyway:** you'll hear him shouting from somewhere high
     (an old water tank or a rock stack). Walk to it and he climbs down to
     you. The creatures will be back at the shed by then, so send him out on
     the jetty again before you go near it.
5. **Naresh and the fuel.** Coming back past the shed, he notices the cans.
   - **You should see / hear:** "There's two! I'll take this one to the van."
     He carries the **light** can to the van himself. Now P2 walks to the van
     too (go back past the shed door, not the crate side).
   - At the van he offers: "Leave the fuel to me! I know how." **Let him.**
   - **You should see:** "Done. I even checked it twice." But the fuel gauge
     **doesn't move**: he poured from the empty can.
6. **Get in and drive on along the road.**
   - **You should see:** a couple of hundred metres on, the engine coughs and
     dies. "The full can is still on the rack." Naresh: "Then imagine how much
     fuel I put in." Up the road, a creature steps out and turns towards you.
7. **Fill it up yourself, quickly.**
   - *Exactly how:* get out (E). At the back of the van, take the heavy can
     off the rack (E). The fuel cap is on the driver's side, near the back:
     look at it and **hold E** until it's full.
   - **You should see:** the tank fills; the goal changes to "on to the salt
     pans".

**Also try:** pour the heavy can in yourself before he offers (then there's
no mistake and no breakdown); stand in his way at the van ("Excuse me!").

### Decisions to confirm (F3) (not yet tested: you test from F3 on once F is finished)

1. **Why the fuel's low:** the storm road and the climb drank the Bessi drum;
   the lamp comes on 420 m short of the village, ~1 L left.
2. **The creatures on the return:** drawn to Naresh from 120 m, they keep
   after him to 300 m, drift slowly (0.9 m/s, so a decoy buys about a
   minute), and go to him even when he's in the van (they can't take him
   there).
3. **Binoculars stretch his jobs to 150 m** (60 m by eye).
4. **The mistake is his idea:** once both cans are at the van he offers to
   do the fuel and uses the light one. If you pour the heavy can yourself
   first, there's no mistake and no stall.
5. **The stall:** the van dies ~200 m on; one creature steps out ~70 m
   ahead.
6. **Naresh copes with clutter:** a thing that snags out of his hands he
   picks up again (up to 3 times); someone in his way gets "Excuse me!"
   and he waits.
7. **Where he's left if taken:** two new greybox high places near the
   village: "the old water tank" and "the rock stack".
8. **The shed's door is wide (2.2 m)** so carried cans don't catch on it.

---

## F4. The salt pans (red light, green light)

**Getting there.** **F1 → Story → "Open salt flats, and something on the
old gantry watching the road"**, Enter, **F1**. You're by the van about 100 m
before the salt flats, Naresh with you.

**The idea.** A creature stands on a tall wooden frame in the middle of the
white salt flats, watching the road like a lighthouse. Its gaze is a pale
beam you can see. Drive while it looks away; stop behind a salt heap when it
looks your way. (Red light, green light.)

1. **Watch it for a bit first**, from where you are.
   - **You should see:** it stares along the road, turns, stares again, a
     few times; then it turns right round and **looks out to sea** for a few
     seconds (that's your best moment to go), then back. Always the same
     pattern.
2. **Everyone in the van, then cross in short dashes.**
   - *Exactly how:* drive while the beam points away from you; when it starts
     turning towards you, stop **behind one of the big white salt heaps**
     next to the road (the heap between you and it).
   - **You should see:** behind a heap you're safe even when the beam passes
     over you. Naresh shouts "Stop! It's turning this way!", but about one
     time in three he gets it wrong ("Go, go! It's not looking!").
   - Once you're past the flats, the goal changes to the estuary bridge.
3. **Get it wrong on purpose** (jump back here with F1 → Story again): drive
   straight across without stopping, or stop in the open where the beam can
   see you.
   - **You should see:** a message; it jumps down and comes across the salt
     for the van (the usual van trouble). Drive on and it falls behind.
     Nothing is lost.

### Decisions to confirm (F4) (you test from F3 on once F is finished)

1. **Its gaze is visible** (a pale beam), so you can play it.
2. **The pattern:** four stares along the road (~3 s each), then out to sea
   (~4.5 s), then back the other way; the same every time (learnable).
   Added after my test: without the look out to sea a careful player could
   hardly ever move.
3. **What gives you away:** moving in its gaze, or moving in the open within
   25 deg of it (the corner of its eye: it turns and stares); stopped in
   the open in its gaze for 2.5 s. Half behind a heap counts as hidden.
4. **Cover:** 9 salt heaps, ~34 m apart, each hiding the van along 10-23 m
   of road.
5. **Seen = the usual van attack**, no fail; it gives up when you drive off.
6. **Naresh's calls:** right two times in three.

---

## F5. The estuary bridge (the three-hand swing bridge)

**Getting there.** **F1 → Story → "The estuary bridge is swung open. Turn
it back across"**, Enter, **F1**. You're next to the bridge's controls, the van
close by, Naresh with you.

**The idea.** The middle of the road bridge has been swung round, so there's
a gap. To swing it back you need three hands at once: someone holding the
**red brake lever** off, and someone turning a **wheel**. Two people on the
two wheels is twice as fast.

**What's there.** By the road: **two wheels** (with a yellow knob), a **red
lever**, a sign that says BRAKE ON or OFF. In the river, a white post with a
yellow float (the tide).

1. **Try one wheel on your own.**
   - *Exactly how:* look at a wheel, **hold E** (P2: **hold X**).
   - **You should see:** nothing moves; the sign says BRAKE ON.
2. **Ask Naresh to hold the brake, then both turn a wheel.**
   - *Exactly how:* look at the red lever, **V** (P2: D-pad Up), **"Hold the
     brake"**. Then P1 holds E on one wheel and P2 holds X on the other.
   - **You should see:** BRAKE OFF; the bridge swings slowly back towards
     the road (about 30 s with both of you).
3. **Half way, Naresh lets go to wave at a boat.**
   - **You should see / hear:** "Ooh, a boat! HELLO! ... Oh. Was I holding
     something?" The bridge swings back open. Ask him again (look at the red
     lever, V, "Hold the brake") and keep turning.
4. **It bolts home.**
   - **You should see:** "The span swings home ... the bolts drop", the red
     barriers go away. Drive across. The goal: the old rail tunnel.
5. **The tide (just watch):** the yellow float rises the longer you take;
   after about 4 minutes the current pulls twice as hard. It only makes it
   harder, never a fail.

### Decisions to confirm (F5) (you test from F3 on once F is finished)

1. **All three at once:** the span only moves while the brake is held off
   *and* a crank turns; the brake let go, the current swings it open
   (2.5 deg/s).
2. **Speeds:** one crank 1.6 deg/s, both 3.2 (about 30 s from open to shut).
3. **Naresh's slip:** once, with you both cranking and the span past half
   way, after 4 s.
4. **The tide is a soft clock:** 4 min to the red mark, then the current is
   twice as strong; no flooding, no fail.
5. **The controls stand on the near (south) bank;** the span turns on the
   middle pier.

---

## F6. The old rail tunnel (the dark gallery, the flare gun, the push start)

**Getting there.** **F1 → Story → "A flood gate is down across the road in
the old rail tunnel"**, Enter, **F1**. You're by the van inside a dark tunnel,
just before a closed steel gate, Naresh with you.

**The idea.** A steel **flood gate** blocks the road. Its winch is in a
narrow, pitch-dark **service passage** that runs alongside the tunnel, and a
creature walks up and down in there. One of you sneaks in, holds the gate
up, and the other drives the van through. In the passage there's also a
**flare gun** to find.

1. **Lights on.** Van headlights: **L**; your torch: **F** (P2: **Y**).
   - **You should see:** the steel gate ahead; in the tunnel wall on your
     right, just before the gate, a doorway marked **SERVICE GALLERY**.
2. **P2: sneak into the passage.** P1 stays at the van with Naresh.
   - **How it works:** in the dark, with your torch **off**, the creature only
     notices you if you're very close; it hears footsteps, so **crouch**
     (hold **B**). With the torch **on** it sees you from far away.
   - *Exactly how:* torch off, hold B, walk in. Every so often there's a short
     dead-end side passage on your right: duck into one to let the creature
     walk past. At the side passages a painted arrow on the opposite wall
     shows the way ("GATE >>"): flick the torch on for a second to read it.
3. **P2: find the flare gun.** It's in a red case at the end of the second
   side passage (the one past the gate).
   - *Exactly how:* torch on for a moment to see it, **X** to pick it up,
     torch off.
   - **RB fires a flare:** red light and a bang; every creature nearby runs
     off and stays away for about a minute and a half. Three flares.
4. **P2 holds the gate up, P1 drives through.**
   - *Exactly how:* the winch is a wheel on the passage wall, level with the
     gate. P2: look at it, **hold X** (the gate rises while you hold). P1:
     get in and drive under the gate. Then P2 lets go, walks on to the next
     doorway out of the passage, and back to the van.
   - **You should see:** the gate rising; the goal changes to the radio mast.
   - (You can also ask Naresh to hold the winch: V on it, "Hold the gate
     winch". Then you have to go back in and fetch him.)
   - **Getting in the van holding the flare gun** puts it on the van's rack
     at the back (the door tells you). Take it off at the back (E) later.
5. **The push start.** A flat battery: you start the van by rolling it.
   - *Exactly how:* **F1 → Van → "Flatten the battery"**, F1. Press X: it only
     clicks. Drive out of the tunnel (or roll) to where the road goes
     downhill, let the handbrake off (**Space**) and let the van roll; once
     it's rolling, press **X**.
   - **You should see:** it starts.

### Decisions to confirm (F6) (you test from F3 on once F is finished)

1. **The tunnel is a puzzle, not just a road:** the flood gate, its winch in
   a side gallery (~120 m door to door; the tunnel is ~360 m).
2. **Dark underground:** the sky's light gone (even by day); creatures see
   as at night (torch: 40 m; standing in the dark: 15 m).
3. **The arrows are painted** (no outline): readable by torchlight, barely
   at arm's length in the dark.
4. **The gallery creature keeps to its patrol** (it doesn't go for Naresh
   through the wall).
5. **The flare gun:** fired with the throw button while held; 3 flares; an
   80 m circle; 90 s. It stays an item you can carry, store on the rack or
   hand over.
6. **The push start:** rolling forwards over 10 km/h, the ignition works on
   a flat battery.

---

## F7. The radio mast (the finale: point the dishes home)

**Getting there.** **F1 → Story → "Point the mast's three dishes, as the
plaque says"**, Enter, **F1**. You're at the bottom of the tall red-and-white
radio mast on a hill (the van is down on the road below). After a jump, P2
holds the flare gun.

**The idea.** Start the mast's generator, then turn its three dishes to
point at three far-away red lights. That calls for help. The generator is
loud and brings creatures, so keep the flare gun handy.

**What's there.** The mast, with a platform at the top (a ladder up its
side) and three dishes numbered 1-3. At its foot: a desk with a **screen**,
three **crank handles** (each with a lamp) and a **plaque**. By the hut: a
green **generator** with a pull cord and a choke.

1. **Start the generator: P2 holds the choke, P1 pulls the cord.**
   - *Exactly how:* P1 first tries alone: look at the pull cord, **hold E**:
     it splutters and dies. Then P2 looks at the choke, **holds X**, and P1
     **holds E** on the cord again.
   - **You should see:** it roars into life; far away **three red lights**
     start blinking; the screen lights up. Two creatures start coming for
     the noise. P2: if one gets close, look at it and press **RB** (flare).
2. **Optional: climb up and look.** The plaque says which light is which.
   - *Exactly how:* at the ladder **E**, then **W** to climb; at the top
     **T** on a red light marks it for the other player. To get down: stand
     where the ladder comes up through the railing, **E**, then **S**.
3. **Turn dish 1 yourself.**
   - *Exactly how:* at the desk look at crank 1, **hold E**: the dish turns
     and the screen shows what it sees. **Let go** when its red light is in
     the middle of the screen.
   - **You should see:** it locks, its lamp turns green.
4. **Let Naresh turn dish 2** (he gets it wrong first).
   - *Exactly how:* look at crank 2, **V**, **"Hold"**. He turns it the
     **wrong way** ("Is it going the right way? It looks the right way.").
     Tell him: look at the crank, **V**, **"Let go of it"** ("Oh! The OTHER
     way."), then **V**, **"Hold"** again. When the screen shows its red light
     in the middle, look at him, **V**, **"Wait here"**.
   - **You should see:** dish 2 locks, lamp green.
5. **Turn dish 3 yourself** (as dish 1).
   - **You should see:** "The mast hums ... away to the west the clouds break
     over the West Road." The goal: take Naresh home.

### Decisions to confirm (F7) (you test from F3 on once F is finished)

1. **No van at the mast** (it's on a hill, no road up: measured 230 m from
   the coast road). So the power is the mast's own generator,
   pull-started by two (one on the choke), not the van's battery as
   RETURN.md first said.
2. **The three targets** (picked by a sightline test from the top): the
   tunnel mouth (430 m), Naresh's home (1.1 km), the ending watchtower on
   the West Road (2.3 km, "home"). Each gets a blinking red relay beacon
   that shows through the dusk.
3. **Tagging far lights:** a beacon looked at straight on can be tagged at
   any distance (tags otherwise reach 200 m, 400 through binoculars).
4. **The cranks turn one way only**, round and round (overshoot = go round
   again).
5. **The screen** shows the last-turned dish's view (it redraws every 6th
   frame: measured 135 fps by it with both views, 144 without).
6. **Two creatures** come for the generator's noise.

---

## F8. Naresh's home, the drive home, the end

**Getting there.** **F1 → Story → "Down to the van, and take Naresh home"**,
Enter, **F1**. You're by the van on the road, a couple of hundred metres from
Naresh's home (the pale house up on the ridge), him with you.

1. **Take him home.** Everyone in the van (he climbs in the back by
   himself), drive along the road to the pale house and stop next to it.
   - **You should see:** he gets out and walks to the door. "The door opens
     before he reaches it. His mother ..." His sister "looks past him, at the
     empty space beside him on the path ... She says nothing." Naresh:
     "Thanks for coming to get me. We'll be all right now." He goes in, and
     the light comes back.
2. **The secret tracker** (nothing tells you about it): only if you did the
   barn maze, the lookout relay, picked up the flare gun in the tunnel and
   found every Memory Fragment, his sister gives you "a tracker ... For next
   time." (After a jump you won't get it: that's expected.)
3. **Drive home along the West Road** (the road carries on past his house).
   - **You should see:** full sun and birds.
4. **The old watchtower:** a tall wooden tower by a side road (Tower Road)
   off the West Road. Park near it and walk up its long ramp at the back.
   - **You should see:** a small warm light over every place your journey
     went, from the windmill to the mast. Any optional thing you skipped
     (maze, relay, flare gun) stays dark ("Some lights out there are still
     dark").
5. **Drive on to either home** (Tower Road goes on to P2's house; the West
   Road to the homestead).
   - **You should see:** both phones buzz: "Location sharing: Naresh has
     left his house, heading to LiveStander." A few seconds later the end
     screen: "End of part one ... Part two: LiveStander". E (A) goes back to
     the title.

(F1 → Story → "Home along the West Road" starts you at his home, him already
inside.)

### Decisions to confirm (F8) (you test from F3 on once F is finished)

1. **The scene is text only** (as agreed), with his mother and sister as
   simple block-out figures at the door; ~24 s from the door to him going
   in.
2. **Naresh's last line:** "Thanks for coming to get me. We'll be all right
   now." ("we": his friend, or his family; left open).
3. **After he's home the creatures stop following and scatter;** the mood
   goes to 0.7, then full sun 300 m down the road.
4. **The tracker** is only a flag and a line for now (no item, no use yet:
   part two).
5. **The site lights** hang 40 m over each place, warm, through any haze;
   13 of them, 3 optional (the barn maze, the lookout relay, the flare gun).
6. **The end** comes within 250 m of either home, after the phones; a black
   end screen ("End of part one / Part two: LiveStander").

---

## F9. The whole return in one go (what I checked)

- `return_run`: the van drove Bessi to home in one go, every new place on
  the way, the puzzles done by script where the van gets to them: 7.5 min
  of driving (village 0.9, salt pans 1.3, estuary 1.7, tunnel 3.2, below the
  mast 3.8, Naresh's door 5.0, the ending watchtower 7.1, home 7.5).
- It found three things no part's test had: (1) the swing bridge "locked"
  by a load never moved its span (the van fell in the river); (2) the van
  could be squeezed through the ground and fall for ever: it now has a
  safety net (back where it last stood safely, with a message); (3) the
  estuary bridge's deck edge (Milestone B's) stood up like a step and
  stopped the van dead: ramps now.

**What to look out for:** anything the van gets stuck on, anywhere.
