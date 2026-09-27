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

### Decisions to confirm (provisional, my choices)
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
