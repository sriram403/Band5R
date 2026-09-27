# Milestone E: your test checklist

Milestone E is tested one part at a time. This page grows as each part is
ready; each part says what to do, what should happen, and what to tell me.

Two players (P1 on keyboard + mouse, P2 on the controller), split screen.
Note anything that feels wrong, slow, confusing or ugly, with the step number.

---

## E1. Naresh in his test map (the Naresh gym)

Start `Play.bat`, **New game**, then **F1** (developer menu) → **Gyms** tab →
**naresh**, Enter. You start in a flat yard with the van, Naresh (green, red
cap) a few steps in front of you, some cans and crates, a long stone wall with
three doorways, a red disc, and a creature asleep in a pen far off.

**Giving him jobs (your key: V on the keyboard, D-pad Up on the controller).**
Look at something and **hold** V: a small wheel of jobs opens round the
crosshair. Move the mouse (or the right stick) towards one, let go. A quick
**tap** gives the first job on the wheel. The driver can't give jobs (eyes on
the road); the passenger can.

What you can look at, and the jobs:

| Look at | Jobs |
|---|---|
| Naresh | Follow me · Wait here (· Let go, while he holds something) |
| The ground | Go and wait there |
| A can, crate, jug, box | Refuel the van with it (a can with fuel) · Bring it to me · Store it on the van |
| The van's fuel filler (driver's side, behind the cab) | Refuel the van (a full can on the rack) · Get in the back |
| The van | Get in the back (or Get out, if he's in) |
| The shutter handle, the lever, the crank | Hold it / Work it |

1. Look at Naresh, **tap V**. **Expect:** "Naresh: On it!" (or similar) at the
   bottom of your screen; he follows you. Walk around, run, go round the
   stone blocks. **Expect:** he keeps up, stops 2-3 m behind you, walks round
   walls rather than into them.
2. Tap V on him again: **Wait here**. Walk away. **Expect:** he stays put.
3. Look at the ground 10-20 m away, tap V: **Go and wait there**. **Expect:**
   he walks there and says "Here?".
4. Look at a **fuel can**, **hold** V. **Expect:** a wheel with three jobs.
   Point at **Bring it to me**, let go. **Expect:** he fetches it and puts it
   in your hands.
5. Put it down (E). Hold V on it, **Store it on the van**. **Expect:** he
   carries it to the rack at the back of the van and puts it there. Try the
   cardboard box too (it goes in the right-hand, any-item slot).
6. With a full can on the rack: stand by the fuel filler (the flap on the
   driver's side, behind the cab), look at it, tap V: **Refuel the van**.
   **Expect:** he takes the can off the rack, pours it in (you hear it), puts
   the empty can back. Sit in the van: the fuel gauge went up.
7. **The shutter** (the left doorway in the long wall): look at its yellow
   handle, tap V (**Hold the shutter**). **Expect:** "Got it! Go on, I've got
   it." and the shutter goes up; walk through. Come back, tap V on him: **Let
   go**. **Expect:** it drops. (You can hold it up yourself with E too.)
8. **The lever gate** (middle doorway): the red lever is 4 m off, so one
   person can't hold it and walk through. Give him the lever, walk through.
9. **The crank gate** (right doorway): **Work the crank**. **Expect:** about 8
   s of cranking, "It's done!", and that gate stays up for good.
10. **The van:** look at the van, tap V: **Get in the back**. **Expect:** he
    walks to the passenger door and sits on the bench in the back (on the
    right, leaving room beside him; he talks about his friend). Drive off with
    him: he rides along. Then from the **passenger** seat look round at him
    (turn right round) and tap V: **Get out**.
11. Tell him to **follow**, then get in the driver's seat. **Expect:** he gets
    in the back by himself. Get out and walk off: he gets out and follows.
12. **The driver:** in the driver's seat press V. **Expect:** a note, "Only
    the passenger can give Naresh jobs from the van."
13. **P2 on the controller:** do a few of the above with D-pad Up.
14. **Random acts:** F1 → **Spawn** → **Naresh: a random act now** (in real
    play they come every 3 to 6 minutes). **Expect:** a line 3 s before
    ("Ooh, what's that over there?"), then something: he wanders off to show
    his friend something, honks the horn, finds the fuel can hidden behind
    the grey wall, pulls the tarp off the van, switches the headlights on at
    dusk, holds a door for you, fixes a flat, tags a creature, drops what he's
    carrying. Try it a few times, in different situations (near the van, with
    him carrying something, standing at the shutter...).
15. **The red disc** ("TIMED ZONE"): stand on it with him: no random act
    starts there (a timed puzzle step, later, is like this).
16. **Being taken:** wake the creature with the post by the start (E). Tell
    Naresh to wait near the creature's pen (the fence far off to the east),
    and walk well away (more than 12 m). **Expect:** the creature drifts over
    to him and takes him in a puff of smoke; a while later you read "Over
    here! By the tall platform! My friend's with me, don't worry." even from
    far away. He's on top of a tall grey block about 300 m off. Walk (or
    drive) over to it. **Expect:** he climbs down and follows you.
17. Try the same with you standing next to him: **Expect:** the creature
    circles him, but doesn't take him (it may come for you, of course).
18. Bump into him slowly with the van, then faster. **Expect:** at walking
    pace he's in the way; faster, he's knocked over, gets up: "Ow! I'm fine!"

*Tell me:*
- Is V / D-pad Up comfortable? Is the wheel quick enough, and clear?
- Does he feel like a helpful, slightly chaotic friend, or annoying?
- His walking: does he ever get stuck, or wander somewhere silly?
- The random acts: which are funny, which are annoying? (They're every 3-6
  minutes for now; we'll tune that together, as agreed.)
- Anything he should say differently.

### Decisions to confirm (provisional, my choices): approved by you for now, 2026-09-27
1. **A quick tap = the first job** on the wheel, so the everyday ones are
   one tap: "Follow me" / "Wait here" on him, "Go and wait there" on the
   ground, "Refuel" on a can with fuel.
2. **Jobs reach 60 m**: you can send him to a spot, or at something, up to 60
   m away, as long as you can see it.
3. **After a job he goes back to following** if he was following you, else
   he waits where he is.
4. **"Bring it to me"** puts it straight into your hands if they're empty,
   else at your feet.
5. **Following you into the van:** when the one he follows gets in, he gets
   in the back by himself; he gets out when they get out and walk off. If you
   drive off without him (more than 45 m), he shouts "Hey! Wait for me!" and
   waits there, alone (so the creatures can get him).
6. **When he's taken**, he shouts every 25 s, to both of you wherever you
   are, until one of you comes within 9 m; then he climbs down by himself.
7. **"Drop it"** (a bad random act) ends the job: he says "I dropped it." and
   you tell him again (nothing is ever lost: it lies where he dropped it).
8. **What he says** shows at the bottom of the screen of anyone within 40 m
   (or in the van with him), and over his head when you're further than 7 m.

---

## E2. Bessi beach, the arrival

Start `Play.bat`, **New game**, **F1** → **Travel** → **Coast watchtower** (or
drive there from wherever you are). Get in the van and drive down the Beach
Road into Bessi (or F1 → Travel → **Bessi beach**, then walk).

1. Drive into Bessi, P2 in the passenger seat watching the nav. **Expect:**
   about 400 m from the roses the nav screen starts flickering **"NO
   SIGNAL"** / "searching...", and stays like that everywhere in Bessi. Drive
   back up the road: it comes back.
2. Park and walk to the beach (east, towards the sea). **Expect:** the light
   slowly turns to **dusk** (it takes about half a minute); it stays dusk.
3. The **promenade**: a paved walk along the row of coloured stalls, lamp
   posts between them. **Expect:** the stalls and lamps are lit, warm, and
   there is nobody at all. Walk along it, and step on and off it from the
   sand (no jumping needed).
4. **The radio:** one stall, near the north end by the memorial, has a small
   red radio on its counter. **Expect:** soft music (a plucked tune over a
   drone, like an old transistor radio) as you get near; it fades away as
   you walk off. *I made this tune myself (no samples); I can't hear it, so
   please tell me how it sounds.*
5. **The memorial** has moved onto the sand: a pale stone column with a
   pointed spire, on steps.
6. **The lighthouse:** on the rocks just off the north end of the beach,
   white with red bands. At dusk its lamp glows and a soft beam turns (one
   turn every 8 s).
7. F1 → Travel → **The photo spot (E3)**, look north. **Expect:** the
   memorial's spire right in front of the lighthouse, its lamp just showing
   over the spire's tip. Step a few metres to the side: the two separate.
   (This is the spot Naresh's photo will be taken from in E3.)

*Tell me:*
- Does the empty, lit promenade feel right (eerie but still warm)?
- The radio tune: nice, annoying, too loud, too quiet?
- The lighthouse: size, place, the beam (too much? too faint?).
- Is the nav's "NO SIGNAL" noticeable enough?

### Decisions to confirm (provisional, my choices)
1. **The memorial moved** onto the sand, 130 m in front of the photo spot,
   so that the lighthouse stands exactly behind its spire (the E3 clue).
2. **The lighthouse** is on rocks just off the north end of the beach, out
   of reach (it's a landmark, not a place to go), about 28 m tall.
3. **The nav loses its signal within about 400 m of the roses**, and gets it
   back outside.
4. **Dusk comes at the beach** and stays (the mood never brightens on the
   way out).
5. **The radio tune** is my own, procedurally made (`tools/gen/radio.py`), so
   there's nothing to credit; a proper recording can replace it at the polish
   stage if you like.
