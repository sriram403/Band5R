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
4. **P2: hide next to the shed, then call Naresh back to you** (out on the
   jetty he's the bait; now you bring him home). This is the last thing
   anyone tells him in this part.
   - *Exactly how:* go to the shed door and stand with your back to it. Walk
     straight ahead about 10 steps, then turn right and walk about 10 more.
     Turn round: past the corner of the shed you can see the jetty, with
     Naresh at its far end. Hold **LT** (binoculars) and watch. When a
     creature is getting close **to Naresh**, look at him, **D-pad Up**, and
     pick **"Follow me"**. Then stay where you are and wait for him.
   - **You should see:** he leaves the jetty end and walks back towards you.
   - **Why hide:** the creatures follow him back. If you waited out in the
     open, or right at the shed door, they'd see you and take you.
5. **On his way back to you, Naresh walks past the shed and spots the fuel.**
   You don't tell him anything; he does this by himself.
   - **You should see / hear:** "There's two! I'll take this one to the van."
     He carries the **light** can to the van on his own. P2: now walk to the
     van too (back past the shed door, not round the crate side).
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

**If something goes wrong in F3:** if a creature catches Naresh before you
call him back, you'll hear him shouting from somewhere high (an old water
tank or a rock stack). Walk to it and he climbs down to you. The creatures
will be back at the shed by then, so start again from step 2: send him out
to the jetty end, and so on.

**Also try:** pour the heavy can in yourself before he offers (then there's
no mistake and no breakdown); stand in his way at the van ("Excuse me!").

### Decisions to confirm (F3): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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
2. **Get in the van** (P1 driving, P2 in the passenger seat; Naresh climbs in
   the back by himself).
3. **Cross the flats in short dashes.**
   - *Exactly how:* drive while the beam points away from you. When it starts
     turning towards you, stop **behind one of the big white salt heaps**
     beside the road, so the heap is between you and the creature. Wait, and
     go again when it looks away.
   - **You should see:** behind a heap you're safe even when the beam passes
     over you. Naresh shouts "Stop! It's turning this way!", but about one
     time in three he gets it wrong ("Go, go! It's not looking!"). Once
     you're past the flats, the goal changes to the estuary bridge.

**Also try (a second go, optional):** jump back with F1 → Story → the same
row, and this time drive straight across without stopping, or stop out in
the open where the beam can see you.
   - **You should see:** a message; it jumps down and comes across the salt
     for the van (the usual van trouble). Drive on and it falls behind.
     Nothing is lost.

### Decisions to confirm (F4): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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
**red brake lever** off, and someone turning a **wheel**. With both of you on
the two wheels it goes twice as fast. Naresh holds the lever.

**What's there.** By the road: **two wheels** (each with a yellow knob), a
**red lever**, and a sign that says BRAKE ON or BRAKE OFF. In the river, a
white post with a yellow float (the tide).

1. **P1: try one wheel on your own.**
   - *Exactly how:* walk up to a wheel, look at it, **hold E**.
   - **You should see:** nothing moves; the sign says BRAKE ON.
2. **P1: ask Naresh to hold the red lever.**
   - *Exactly how:* look at the red lever, **V**, pick **"Hold the brake"**.
   - **You should see:** he walks over and holds it; the sign says BRAKE OFF.
3. **Both of you: turn a wheel each and keep holding.**
   - *Exactly how:* P1 **holds E** on one wheel, P2 walks to the other wheel
     and **holds X**.
   - **You should see:** the bridge swings slowly back towards the road.
4. **About half way, Naresh lets go of the lever to wave at a boat.**
   - **You should see / hear:** "Ooh, a boat! HELLO! ... Oh. Was I holding
     something?" The bridge starts swinging back open.
   - *What to do:* P1 lets go of the wheel, looks at the red lever, **V**,
     **"Hold the brake"** again, then goes back to holding E on the wheel.
     (He only does this once.)
5. **Keep turning until it locks.**
   - **You should see:** "The span swings home ... the bolts drop", and the
     red barriers disappear. Get in the van and drive across. The goal
     changes to the old rail tunnel.

**Just watch (no action):** the yellow float on the white post rises the
longer you take; after about 4 minutes the current pulls twice as hard. It
only makes it harder, never a fail.

### Decisions to confirm (F5): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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

**The idea.** A steel **flood gate** blocks the road. Its winch (the thing
that lifts it) is in a narrow, pitch-dark **service passage** that runs
alongside the tunnel, and a creature walks up and down in there. P2 sneaks
in, finds a flare gun on the way, and holds the gate up; P1 drives the van
through.

1. **Lights on.** Van headlights: **L**. Your torch: **F** (P2: **Y**).
   - **You should see:** the steel gate across the road ahead; in the tunnel
     wall on your right, just before the gate, a doorway marked **SERVICE
     GALLERY**.
2. **P2: sneak into the passage.** P1 waits by the van with Naresh.
   - **How the creature in there works:** in the dark, with your torch
     **off**, it only notices you when it's very close; it hears footsteps,
     so **crouch** (hold **B**). With the torch **on** it sees you from far
     away. You'll see its eyes glow.
   - *Exactly how:* torch off, hold B, go in through the doorway, and walk
     along the passage (towards the gate's end of the tunnel). Every so
     often there's a short dead-end side passage on your right. If the
     creature comes towards you, step into one of those and wait for it to
     walk past. At each side passage a painted arrow on the opposite wall
     points the way ("GATE >>"): switch the torch on for a second to read it,
     then off again.
3. **P2: pass the winch, and get the flare gun from the next side passage.**
   - *Exactly how:* you'll pass a wheel on the passage wall with the sign
     **FLOOD GATE WINCH**: that's the winch; leave it for now. Keep going to
     the next side passage on your right and walk to its end: there's a
     small red case. Torch on for a moment to see it, **X** to pick up the
     flare gun, torch off.
   - **Firing it (RB):** red light and a bang; every creature nearby runs
     away and stays away for about a minute and a half. You have three. If
     the creature is coming for you, fire one.
4. **P2 holds the gate up; P1 drives through.**
   - *Exactly how:* P2 goes back to the winch, looks at it and **holds X**:
     the gate rises while you hold. P1: get in the van (Naresh climbs in by
     himself), drive under the gate and stop a little past it. Then P2 lets
     go, walks on along the passage the way you were going to the **second
     doorway**, out into the tunnel beyond the gate, and gets in the van.
   - **You should see:** the gate rising; the goal changes to the radio mast.
   - Getting into the van with the flare gun in your hand puts it on the
     van's rack at the back (the door says so). Take it off at the back (E)
     when you need it.
5. **The push start: starting the van with a flat battery by rolling it.**
   - *Exactly how:* drive out of the tunnel's far end and stop on the road
     where it starts going **downhill**. Switch the engine off (**X**). Now
     **F1 → Van → "Flatten the battery"**, F1. Press **X**: it only clicks.
     Let the handbrake off (**Space**): the van starts rolling down the hill.
     Once it's rolling, press **X**.
   - **You should see:** the engine starts.

**Other way (optional):** instead of P2 holding the gate, ask Naresh to: in
the passage, look at the winch, **V**, "Hold the gate winch". Then you have
to go back into the dark and fetch him afterwards.

### Decisions to confirm (F6): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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
is holding the flare gun.

**The idea.** Start the mast's generator, then turn its three dishes to
point at three far-away blinking red lights. That calls for help. The
generator is loud and brings creatures, so P2 keeps the flare gun ready.

**What's there.** The mast, with a platform at the top (a ladder up its
side) and three dishes numbered 1-3. At its foot: a desk with a **screen**,
three **crank handles** (each with a small lamp) and a **plaque**. By the
hut: a green **generator** with a pull cord and a choke.

1. **P1: try to start the generator on your own.**
   - *Exactly how:* look at the pull cord, **hold E**.
   - **You should see:** it splutters and dies. It needs someone on the choke.
2. **P2 holds the choke while P1 pulls the cord.**
   - *Exactly how:* P2 looks at the choke and **holds X**; P1 **holds E** on
     the cord again. Once it's running, P2 can let go.
   - **You should see:** it roars into life; far away **three red lights**
     start blinking; the screen on the desk lights up.
3. **P2: stand guard.** The noise brings two creatures up the hill.
   - *Exactly how:* if one gets close to either of you, look at it and press
     **RB** to fire a flare.
4. **Optional: climb the mast and look.** The plaque says which light is
   which (the tunnel mouth, Naresh's house, the watchtower).
   - *Exactly how:* at the bottom of the ladder **E**, then **W** to climb. At
     the top, look at a red light and press **T** to mark it for the other
     player. To come down: stand where the ladder comes up through the
     railing, **E**, then **S**.
5. **P1: turn dish 1.**
   - *Exactly how:* at the desk, look at the crank whose prompt says "dish 1
     crank" and **hold E**: the dish turns and the screen shows what it
     sees. **Let go** when its red light is in the middle of the screen. If
     the lamp doesn't turn green, hold E again: the dish goes all the way
     round and comes back to the light.
   - **You should see:** its lamp turns green (it's locked on).
6. **Let Naresh turn dish 2** (he gets it wrong at first, on purpose).
   - *Exactly how:* P1 looks at the dish 2 crank, **V**, **"Hold"**. He turns
     it the **wrong way** ("Is it going the right way? It looks the right
     way."). Tell him: look at the crank, **V**, **"Let go of it"** ("Oh! The
     OTHER way."), then **V**, **"Hold"** again: now he turns it the right
     way. When the screen shows its red light in the middle, look at
     **Naresh**, **V**, **"Wait here"** (that makes him let go).
   - **You should see:** dish 2's lamp turns green.
7. **P1: turn dish 3** (as dish 1).
   - **You should see:** "The mast hums ... away to the west the clouds break
     over the West Road." The goal changes to taking Naresh home.

### Decisions to confirm (F7): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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

1. **Take him home.** Get in the van (Naresh climbs in the back by himself),
   drive along the road to the pale house, and stop on the road next to it.
   - **You should see:** he gets out by himself and walks to the door. "The
     door opens before he reaches it. His mother ..." His sister "looks past
     him, at the empty space beside him on the path ... She says nothing."
     Naresh: "Thanks for coming to get me. We'll be all right now." He goes
     in, and the light comes back.
2. **Drive on along the same road.** It carries on past his house and
   becomes the West Road home.
   - **You should see:** full sun and birds.
3. **Stop at the old watchtower.** After a long drive, a side road goes off
   on your **left**, towards a tall wooden tower on a hill. Take it, park by
   the tower, walk round it to find its long wooden ramp, and walk up.
   - **You should see:** from the top, a small warm light over every place
     your journey went, from the windmill to the mast. Anything optional you
     skipped (the barn maze, the lookout relay, the flare gun) stays dark,
     and a message says "Some lights out there are still dark".
4. **Drive on home.** Back in the van, carry on along the side road (it
   leads to P2's house).
   - **You should see:** near the house both phones buzz: "Location sharing:
     Naresh has left his house, heading to LiveStander." A few seconds later
     the end screen: "End of part one ... Part two: LiveStander". Press E (pad:
     A) to go back to the title.

**The secret tracker (nothing to do, just know):** only if you did the barn
maze, the lookout relay, picked up the flare gun in the tunnel and found
every Memory Fragment, his sister gives you "a tracker ... For next time" at
step 1. After an F1 jump you won't get it: that's expected.

(F1 → Story → "Home along the West Road" starts you at his home, him already
inside.)

### Decisions to confirm (F8): confirmed by you, 2026-10-05 (from the recorded walkthrough)

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
