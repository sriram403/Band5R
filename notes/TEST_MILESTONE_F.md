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
**storm**, Enter. You start on the flat test plain at dusk, in the storm:
rain, wind, grey fog, lightning now and then. The van stands at the west end
of a long straight road (the road runs off in front of the van); orange-and-white **windsocks** line the road on the
windward side; four white **distance boards** (30, 60, 90, 120 m) stand
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

### Decisions to confirm (F1)

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
