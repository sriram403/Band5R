# Puzzles: review, research and a catalogue to choose from (proposal)

For your approval, like `OPENING.md`. Three parts:

1. **The water works review**: what works, what didn't, and what this branch changes.
2. **Research**: what co-op puzzle games do, boiled down to rules for this game.
3. **A catalogue** of puzzle ideas, each placed at a landmark in `BEAT_CHART.md`, for
   you to pick from. Nothing in part 3 is built; each chosen puzzle still gets its own
   page and gym first (`DESIGN.md` section 6).

---

## 1. The water works, reviewed

**How it plays today.** One player works the hand pump and keeps the pressure needle
in the green (hold E; too much pops the relief valve and stalls the pump for 3.5 s).
The other turns valves A and B in the yard and has to trace the grey pipes by eye to
find the setting that feeds the blue COOLANT tank. Wrong settings fill the grey tank
or dump into the river (the needle won't rise). About 13 s of pumping in the green
fills the tank; it gives a coolant jug and a Memory Fragment.

**What works well**

- **Mistakes are loud and harmless.** The relief valve bangs and hisses and costs a
  few seconds. The waste tank drains back. Nothing is ever lost. This is the right
  tone for the way out.
- **Each player knows something the other doesn't.** The pumper sees the gauge and
  the flow lamp. The valve player sees the pipes and the tank sight-glasses. The
  instruction plate says what to do but never which way the valves go.
- **You read the world, not a menu.** The pipes are all one colour on purpose, so you
  follow them with your eyes.
- **It is part of the story chain**: the hose splits on the way in, so you need the
  coolant, so you need the puzzle.

**What was weak**

1. **One person could do it alone, one job after the other.** Set both valves, walk
   to the pump, pump. Nothing ever needed both players *at the same time*, so a pair
   could split up and the "co-op" became taking turns. Research below calls this
   *soft* dependence; the best co-op moments use *hard*, simultaneous dependence.
2. **The valve player had nothing to do once the valves were right.** For the last
   ~15-25 s one player pumps and the other watches: dead time, which co-op games
   avoid.
3. **Only 4 valve settings**, so trying all of them is quicker than thinking. That's
   fine for the first co-op puzzle (it teaches the idea), but later puzzles need more
   room.
4. The flow lamp lights on the wrong (grey tank) route too. That's deliberate (the
   pumper can't tell which tank is filling, so the two have to talk), and it's kept.

**What this branch changes (built and tested)**

- **Valve B has a worn seat and kicks back.** With two players, the line pressure
  knocks valve B back to the overflow twice while the blue tank fills (at a third
  and at two thirds). The pumper sees the needle collapse and the flow lamp go out.
  The valve player hears a CLANK and sees the pointer swing. They turn it back and
  pumping carries on. So the valve player stays at their post, both keep talking to
  the end, and you get a small "B slipped!" / "got it, pump!" moment twice. While B
  is kicked back the blue tank does not fill.
- **It is set up in advance, not sprung on you.** A hand-written red note on B's post
  says "WORN SEAT - watch it under pressure", so when it happens players think "of
  course", not "that's unfair".
- **Solo still works.** With one keyboard only (no pad, the solo view) B holds, so
  one person can still test the whole puzzle.
- Saves remember how many times B has slipped.
- **Test:** the `waterworks` play-test now plays it as two people. B slips exactly
  twice, the "partner" turns it back each time, the tank does not fill while B is
  slipped, and the tank still fills (36 s of pumping). All the old checks still
  pass.

**Further ideas for the water works** (not built; your call)

- **Tie it to the bridge** (already in the beat chart): once the pump runs, the old
  turbine hums and the bridge's control hut lights come on. This is the "which caused
  that" link to the next puzzle.
- **Hear the flow**: a trickle sound from whichever tank is filling, so the valve
  player gets feedback without walking to the sight glass.

---

## 2. Research: what makes co-op puzzles good

Studied: *Keep Talking and Nobody Explodes*, the *We Were Here* series, *Portal 2*
co-op, Hazelight's *A Way Out*, *It Takes Two* and *Split Fiction*, *Unravel Two*,
*Operation: Tango*, *Biped*, *The Witness*, Nintendo's four-step level design, and
work on "cooperation vs interdependence" in games. Sources are at the end. The
lessons, applied to this game:

1. **Split the knowledge.** The strongest pattern (*Keep Talking*, *We Were Here*,
   *Operation: Tango*): each player holds information the other needs but can't get
   themselves, so **talking is the only way through**. Here: one sees from a height,
   one walks the maze; one has the photo, one has the binoculars.
2. **Split-screen warning (important for us).** Those games work because the other
   player truly *can't* see. On a couch the partner's half of the screen is right
   there. Design the hidden knowledge so it depends on **where you stand or what you
   hold**, not only on what is shown: a view from the top of the tower, a closely
   zoomed binocular view, a shape that only lines up from one spot, a sound only
   heard nearby. Peeking should give a clue, not the answer.
3. **Hard vs soft dependence.** *Soft*: a second player helps, but one could do it
   alone (the old water works). *Hard*: two things must happen **at the same time
   in two places** (hold a lever while the other crosses; crank while the other
   steers). Use hard dependence for the key moment of each puzzle. Keep a solo
   fallback for testing, like the valve fix.
4. **Different hands, not just different places** (*It Takes Two*): Cody's nails
   become May's swing points, then she opens the way for him. Our version: the
   driver and the navigator. The van, the map, the binoculars and the tags are
   natural tools for this.
5. **Keep both busy.** Watching your partner do the fun part is the most common
   co-op complaint. Give the waiting player a job: watch the creature, call the
   timing, hold the light.
6. **Teach, develop, twist, finish** (Nintendo's *kishōtenketsu*): show a mechanic
   safely, use it a little harder, turn it on its head, then a final test using all
   of it. This fits the way out (teach), the return (twist) and the radio mast
   (finish) exactly.
7. **One idea per puzzle, and an "aha".** A good puzzle has a single insight that
   makes you feel clever (*The Witness*). If it is only effort, it is a chore.
8. **Fail loudly and cheaply.** Funny, noisy, recoverable mistakes (the relief
   valve) keep pairs laughing instead of blaming each other.
9. **Each puzzle causes the next** (your rule from `FUTURE.md`): its reward is the
   thing the next place needs (coolant, power, a map section, sand, a cog).
10. **Mechanics that don't repeat** (Hazelight): each landmark adds one new twist, so
    every stop feels new.

---

## 3. The catalogue

Size: **S** = mostly existing systems, a day or two · **M** = one new mechanic or
prop set · **L** = several new systems. "Needs" names systems that don't exist yet.

### The way out (bright, happy, clever: teach one thing each)

| # | Puzzle | Where | Teaches | How it plays | Why both players are needed | Size |
|---|---|---|---|---|---|---|
| W1 | **Windmill brake** | J1 Windmill | Tagging | The blades are jammed by a snagged rope. The climber on the tower sees which blade and **tags** it. Below, the other works the brake lever: release it only when the tagged blade swings down to the platform, and the climber cuts it free. | Only the climber sees the snag; only the lever player can move the blades. Timing is called out loud. | M (needs tagging) |
| W2 | **Guide from a height** (your idea) | Barn: a maize / hedge maze beside it (optional) | Tagging, guiding | A walled maze where wrong turns loop you back to the entrance. One climbs the barn loft and tags the next turn; the walker can't see over the walls. **Twist**: halfway, a hay dust cloud hides part of the maze, so the walker has to describe what they see ("a red gate on my left") until the top player finds them again. Reward: spare coolant + a crate. | Top player sees the layout, walker sees the details up close. | M |
| W3 | **Clock and code** (your "rabbit + potato = sand" idea) | Town (the clock over Town Fuel) or the barn | Reading and matching | A chalkboard in the shop pairs pictures: RABBIT + POTATO. The town clock's face has pictures instead of numbers. One reads the board, the other on the clock gallery turns the hour hand to the rabbit and the minute hand to the potato. A hatch opens and drops a **sack of sand**, which the reader needs: pour it on the slick oil patch on the ramp so the van can climb it. | The board and the clock are far apart; the board changes to a new pair each time you open the hatch (3 rounds). | M |
| W4 | **Binocular relay** | Ridge lookout (short route) | Binoculars | A padlocked supply box at the foot of the lookout. Its code is painted on the water tower and the bridge hut, both only readable through binoculars from the deck. **Twist**: the top player reads the numbers, but the box has pictures, not digits; the player at the box describes the pictures and the top player matches them. | Top sees the far code, bottom sees the lock. | S (needs binoculars) |
| W5 | **Siphon at Last Fuel** | J2 Last Fuel | Van battery, cause and effect | The pumps are dead because the generator's battery is flat. **Borrow the van's battery** (the driver pops the bonnet, the other carries it). The pump now works, but the van can't start until the battery goes back, and the generator has to run long enough to fill a can. One cranks the nozzle, the other holds the can and calls "stop" before it overflows (a spill is a small fire you stamp out). | Crank and can are on opposite sides of the pump. | M |
| W6 | **Lift bridge** (the gate) | The bridge | Power, tagging, mirrors | Power from the water works reaches the control hut. One works the levers in the hut and can't see the deck, except in a **convex safety mirror** (the van's mirror tech). The other clears the jammed gear on the deck, guided by tags. **Twist**: lowering the bridge needs the deck player standing on the counterweight at the right moment ("now!"). | Levers and the gear are 30 m apart; only one sees the other in the mirror. | M |
| W7 | **Rally co-driver** | Ghat hairpins, in fog | The nav swing (N) | Fog on the hairpins. With the nav swung to the passenger it shows **pace notes** ("left 3, tightens, don't cut"); the driver sees only fog. Take the hairpins without scraping the barrier. Optional reward: a hidden lay-by with a Memory Fragment the notes mention. | Only the passenger sees the notes. | S (mostly exists) |
| W8 | **Where was the photo taken** | Bessi beach | Binoculars, tags, alignment | Only one player holds Naresh's photo (it's in their hands, on their screen). In it, the lighthouse sits **exactly behind** the memorial's spire, and a boat's mast lines up with a stall roof. Two lines give one spot. The photo-holder describes the picture; the other scans with binoculars and tags candidates; walk until both pairs line up. | The photo and the binoculars are in different hands; the alignment only works from one spot. | M |
| W9 | **Too heavy for the old bridge** (optional) | Valley road: a timber bridge on the long route | Cargo, carrying | A sign: 2 t limit, and the loaded van is over it. Unload the cans and crates, carry them across on foot, drive over empty (it creaks), load up again. **Twist**: the far bank is steep, so carrying needs both players on the heavy fuel drum. | Heavy items need two carriers. | S |

### With Naresh (dusk: fun, teaching his commands)

| # | Puzzle | Where | Teaches | How it plays | Size |
|---|---|---|---|---|---|
| N1 | **The stall shutter** | Bessi stalls | Naresh: *hold* | A heavy shutter only stays up while held. Command Naresh to *hold* it while you both crawl in for the torch batteries. Random act: he lets go early and you're shut in (funny, not harmful; he opens it again after a knock), or he spots the snacks and holds it proudly for ages. | M (needs Naresh) |
| N2 | **Push the boat** | Bessi beach | Naresh: *push / follow* | A fishing boat has to be pushed into the water to reach the fifth rose's shadow on the sand bar. It needs three at once: two players and Naresh (*push*). He sometimes pushes the wrong way. | M |

### The return (dark: fear, pressure, still clever; Naresh is the third hand)

| # | Puzzle | Where | Uses | How it plays | Size |
|---|---|---|---|---|---|
| R1 | **Decoy** (beat chart) | Fishing village | Naresh *follow / wait*, creatures, binoculars | Fuel is locked in the net shed and creatures patrol the jetty. Creatures follow Naresh, so send him down the jetty (*wait* there) to pull them away. One searches the shed; the other watches the creatures through binoculars and calls when to bring Naresh back, before one takes him. | L (creatures + Naresh) |
| R2 | **Red light, green light** (beat chart) | Salt pans | Tarp, hiding, driving | Open ground, one creature sweeping. The van moves in short dashes between salt heaps; the passenger on a heap with binoculars calls "go" and "stop, tarp!". If it sees the engine running, fuel starts to leak. | L |
| R3 | **Three-hand swing bridge** (beat chart) | Estuary bridge | Naresh *hold*, timing | Two cranks turn the bridge and a brake lever must be held at the same time. The tide rises (the clock). Naresh holds the brake, but sometimes lets go to wave at something, and the bridge swings back unless someone grabs it. | M |
| R4 | **Torch relay** | Old rail tunnel | Torch, batteries, hearing | Pitch dark; one set of fresh batteries. Creatures hear footsteps. One walks ahead with the torch *off* and taps the rails to mark the way; the other follows the sound and switches on only at forks. The flare gun is down a side passage only visible with the torch on. | M |
| R5 | **Push start** | Anywhere on the return (after the lights were left on in the rain) | Battery, handbrake, slopes | The battery is dead. Roll the van down a slope: one steers and "bumps" the engine on (X at the right speed), the other and Naresh push. Too steep and it runs away (handbrake!). | S |
| R6 | **Flooded causeway** | Estuary approach | Tagging, van in water | The road is under water. One wades ahead with a pole and tags the edges; the driver follows the tags at walking pace. Off the edge = water in the engine, which needs to dry out (FUTURE #9). | M |

### The final puzzle: the radio mast (uses everything)

**Point the dishes home.** The storm has knocked the mast's three dishes out of line.
From the top of the mast (climbing, like the lookout) you can see three landmarks
you passed: **the windmill, the water tower and the coast watchtower**. That's a
deliberate look back at the journey, before the ending watchtower does it fully.

1. **Power** (cause and effect, like the water works): the mast's generator needs
   the **van's battery**. Drive the van to the base in the storm; its engine noise
   draws creatures.
2. **Tags**: the climber tags which landmark each dish must face.
3. **Cranks**: dishes turn with cranks on the ground. Both players and **Naresh**
   each work one (his may spin the wrong way until you tell him to *wait*).
4. **Binoculars**: each dish has a sight. The ground player at each crank checks the
   dish's sight picture on a small screen at the base (the mirror tech), while the
   climber confirms from above.
5. **Hiding**: a creature comes for the van halfway through. Tarp it, go quiet, and
   keep Naresh between you, then finish.

When the third dish lines up, the storm eases over the road home (the reward is the
way out of the dark: "which caused that").

### Suggested picks (for a ~60 min first play)

- **Way out:** W1 windmill (tags), W7 rally co-driver (nav swing), the water works
  (done), W6 lift bridge, W8 photo. Optional: W2 maze or W9 bridge on the long route,
  W4 binocular relay on the short route, W3 clock at the town.
- **With Naresh:** N1 shutter, then N2 boat.
- **Return:** R1 decoy, R2 salt pans, R3 swing bridge, R4 tunnel (flare gun), then the
  **radio mast** finale. R5 push start as a scripted surprise between them.

### Questions for you

1. Which puzzles do you want (the suggested picks, or your own mix)?
2. The clock-and-code (W3): at the town, or somewhere else on the way out?
3. Is the valve B kick-back right, or should it happen only once?

---

Sources (research, 2026-09-24; most pages could only be read through search
summaries from this cloud session):
[GDC Vault: Designing Asymmetric Gameplay for Keep Talking and Nobody Explodes](https://gdcvault.com/play/1023471/Designing-Asymmetric-Gameplay-For-Keep) ·
[PC Gamer: We Were Here Too](https://www.pcgamer.com/two-players-co-operate-to-solve-linked-escape-rooms-in-we-were-here-too/) ·
[PreMortem: Total Mayhem Games and the asymmetric puzzler](https://premortem.games/2022/05/31/total-mayhem-games-are-masters-of-the-asymmetrical-puzzler/) ·
[Unreal Engine: It Takes Two, story and gameplay](https://www.unrealengine.com/developer-interviews/it-takes-two-lovingly-marries-story-and-gameplay-together) ·
[Xbox Wire: Josef Fares on Split Fiction](https://news.xbox.com/en-us/2025/03/05/split-fiction-josef-fares-interview/) ·
[It Takes Two (Wikipedia)](https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)) ·
[ACM CHI PLAY: Cooperation and Interdependence](https://dl.acm.org/doi/10.1145/3116595.3116639) ·
[Operation: Tango (Wikipedia)](https://en.wikipedia.org/wiki/Operation:_Tango) ·
[MCV: Nintendo's level design secrets in four steps](https://mcvuk.com/business-news/publishing/video-nintendos-level-design-secrets-in-four-steps/) ·
[Game Design Skills: puzzle game design](https://gamedesignskills.com/game-design/puzzle/) ·
[The Witness (Wikipedia)](https://en.wikipedia.org/wiki/The_Witness_(2016_video_game))
