# Milestone F: your test checklist

Milestone F (the return) is tested one part at a time. This page grows as
each part is ready; each part says what to do, what should happen, and what
to tell me. Your answers to the design questions are in `design/RETURN.md`
("Decisions").

Two players (P1 on keyboard + mouse, P2 on the controller), split screen.
Note anything that feels wrong, slow, confusing or ugly, with the step number.

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

**Getting there.** `Play.bat`, **New game**, **F1 → Story**, pick **"Nearly
out of fuel. The fishing village: the fuel's in the net shed"**, Enter. You
both stand by the van on the coast road, a short walk south of the village,
Naresh with you, the fuel lamp on (about a litre left). It's dusk.
(Or drive there from "North on the coast road": about 420 m before the
village the lamp comes on and a message says you'll only just make it.)

**What's there.** A few huts, nets on poles, boats on the sand, a long
wooden **jetty** out into the sea (railed both sides), and the **net shed**
(brown, flat roof, "NETS - PRIVATE"), padlocked. Two creatures pace between
the huts and the shed. Fish crates are stacked up one side of the shed like
steps; up on its roof is a small blue boat.

1. **Walk in with Naresh.** **Expect:** the creatures stop and turn towards
   *him*, then drift his way, slowly. (Keep your distance: if they see you,
   they come for you.)
2. **Send him to the end of the jetty:** look at the far end of the jetty,
   hold V (pad: D-pad Up), *Go and wait there*. From the beach it's far:
   with the binoculars (hold RMB / LT) you can give him jobs up to 150 m
   away (60 m by eye). **Expect:** he walks out to the end; the creatures
   follow him out along the jetty (about 20 s later the shed side is clear);
   they need over a minute to reach him.
3. **One of you: the key.** Climb the fish crates (W and jump, step by step;
   at the top, turn onto the roof). In the blue boat: **E: Take the key**.
   Down again, the shed door: **E: Unlock the shed**. Inside: two cans, one
   heavy, one light.
4. **The other: watch him** through the binoculars. Before a creature reaches
   him, look at him and V / D-pad Up: *Follow me*, even from the beach.
   (If he's taken: he's left high up on the old water tank or the rock
   stack, shouting; go and fetch him. Nothing lost but time.)
5. **The fuel.** Take the heavy can to the van. **Expect:** when Naresh comes
   by the shed he says "There's two! I'll take this one to the van" and puts
   the *light* can on the rack. Once the heavy can is at the van too:
   "Leave the fuel to me! I know how." Let him. **Expect:** "Done. I even
   checked it twice." (Watch the fuel gauge: it doesn't move.)
6. **Drive on north.** **Expect:** after a couple of hundred metres the
   engine coughs and dies; "The full can is still on the rack"; Naresh:
   "Then imagine how much fuel I put in." Up the road a creature steps out
   and turns towards you.
7. **Pour it yourself:** the heavy can off the rack, hold E at the filler.
   **Expect:** the tank fills; the objective: on to the salt pans (the end
   of the build for now).

Try the other ways too: pour the heavy can yourself before he offers (then
no mistake, no stall); stand in his way at the van (he says "Excuse me!").

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
old gantry watching the road"**. You're by the van on the coast road, about
100 m short of the salt pans, Naresh with you. (Or drive on north from the
fishing village.)

**What's there.** The road crosses open white salt flats. In the middle of
the pans, on an old wooden gantry, a creature stands watch. Its gaze is a
**pale beam** you can see. White **salt heaps** line the seaward side of the
road.

1. **Watch it first** (from the van or on foot, out of its way). **Expect:**
   it stares along the road one way for ~3 s, turns to the next, sweeping
   across the road; after sweeping one way it **turns to look out to sea**
   for ~4.5 s (its back to the road: your green light), then sweeps back.
   The pattern repeats.
2. **Cross in dashes.** Drive while it looks away (best: while it looks out
   to sea); when it turns your way, **stop behind a salt heap** (the heap
   between you and it). **Expect:** behind a heap you're hidden even in its
   gaze. Naresh, in the back, calls out as it turns ("Stop! It's turning
   this way!"), but one time in three he gets it wrong ("Go, go! It's not
   looking!").
3. **Get it wrong on purpose** (another go: F1 → Story again):
   - driving through its gaze, or even near it (movement in the corner of
     its eye makes it turn and look), **it sees the van**;
   - stopped in the open, in its gaze for 2.5 s, **it sees the van** (not if
     the tarp's on);
   **Expect:** a message; it drops off the gantry and comes across the pans
   for the van (the usual van trouble: leak, engine, tyre). Drive on and
   it falls behind. Nothing is lost for good.
4. Across the open ground: the objective moves on to the estuary bridge.

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
it back across"**. You're at the bridge's controls on the near bank, the van
close by, Naresh with you. (Or drive on north from the salt pans.)

**What's there.** The road bridge over the river mouth; its middle span
stands **swung open along the river** on its pier, red barriers either side
of the gap. On the near bank by the road: **two cranks** (wheels with a
yellow knob) and a **brake lever** (red), and a sign. By the pier, a white
**tide gauge** with a red mark near the top and a yellow float.

1. **Turn a crank alone** (hold E / pad X). **Expect:** nothing: the brake's
   on (the sign says BRAKE ON).
2. **Give Naresh the brake:** look at the lever, V / D-pad Up, *Hold the
   brake*. **Expect:** he holds it off (BRAKE OFF). Now turn a crank:
   **expect** the span to come round slowly; with both of you on the cranks,
   twice as fast (~30 s from open to shut).
3. **Half way, Naresh lets go** to wave at a boat ("Ooh, a boat! HELLO! ...
   Oh. Was I holding something?"). **Expect:** the current swings the span
   back open. Tell him again (V on the lever) or one of you grabs the brake.
4. **Shut:** "The span swings home ... the bolts drop". The barriers go; drive
   the van over. The objective: on to the rail tunnel.
5. **The tide:** from when you arrive, the float rises; after ~4 min it's at
   the red mark and the current pulls the span open twice as fast (a
   message says so). Harder, never a fail.

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
the old rail tunnel"**. You're by the van inside the tunnel, ~25 m short of
the gate, Naresh with you. (Or drive on from the estuary bridge: the coast
road turns inland under Tunnel Hill; "OLD RAIL TUNNEL 1911" over the mouth.)

1. **Inside it's dark** (headlights: L; torch: F). **Expect:** a steel
   **FLOOD GATE** down across the road ahead; in the tunnel's right-hand wall
   a doorway marked **SERVICE GALLERY** (one before the gate, one after).
2. **The gallery:** narrow, pitch dark, and something walks it. **Expect:**
   with the torch **off** it doesn't see you unless it's very close (it hears
   your footsteps: crouch-walk); with the torch **on** it sees you from far
   off. At each of the two **forks**, the way is painted on the wall
   ("GATE >>"): you can only read it **with the torch on**. One fork is a
   dead end.
3. **The flare gun:** at the end of the second fork's dead end, a red case:
   **E** picks up the flare gun. **G / LMB** (pad RB: the throw button)
   fires a flare: red light, a bang, and every creature within 80 m runs and
   keeps away for 90 s. Three flares (the prompt counts them).
4. **The winch** is on the gallery wall by the gate: hold E to raise the gate
   (it drops when you let go). One holds it, the other drives the van
   through; or give it to Naresh (V on the winch, *Hold the gate winch*) and
   then fetch him (he's alone in the dark...). Out through the far door.
5. **The push start:** leave the headlights on with the engine off until the
   battery's flat (or F1 → Van → "Flatten the battery"). **Expect:** the ignition only clicks
   ("rolling over 10 km/h, it would bump-start"). Let the van roll down a
   slope, handbrake off, and press X while it rolls: it catches.

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
plaque says"**. You're at the foot of the red-and-white mast on Radio Hill;
the van is on the coast road below (about 230 m down: no road goes up).
(Or drive out of the tunnel: the mast is on the hill above the road; park
and walk up.)

**What's there.** The mast with a platform 20 m up (a ladder up its side)
and three dishes, numbered 1-3; at its foot a desk with a **screen**, three
**cranks** (each with a lamp) and a **plaque**; by the hut a green
**generator** with a pull cord and a choke.

1. **Power.** One holds the **choke** (hold E / X), the other pulls the
   **cord** (hold E). **Expect:** the cord alone splutters out; with the
   choke held it roars into life. Far off, **three red beacons** blink on,
   and the screen lights up. **It's loud: two creatures come for the noise**
   (hide, keep still, or fire a flare).
2. **The targets.** The plaque: DISH 1, the tunnel mouth; DISH 2, the house
   on the ridge (Naresh's home); DISH 3, the watchtower on the West Road.
   Climb the ladder: from the platform you can see all three beacons.
   **T** on a beacon tags it (any distance, looked at straight on; the
   binoculars help), so the one below sees where it is.
3. **The dishes.** Hold E on a dish's crank: it turns (always the same way,
   round and round, 8 deg/s); the screen shows what that dish sees. Let go
   with it on its beacon: it **locks**, its lamp goes green.
4. **Naresh** can take a crank (V on it: *Hold*): the first time he turns
   it **backwards** ("Is it going the right way? It looks the right way.")
   until you tell him again ("Oh! The OTHER way.").
5. **All three locked:** "The mast hums ... away to the west the clouds
   break over the West Road." The objective: on to Naresh's home.

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
