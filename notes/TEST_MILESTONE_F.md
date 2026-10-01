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

1. **Get in** (Naresh too: look at the van, V, *Get in the back*). Drive
   north a little way. **Expect:** dry, calm, no rain: the storm stays
   behind you.
2. **Turn round and drive towards the black clouds.** Back past the dune
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

### Decisions to confirm (F2)

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
