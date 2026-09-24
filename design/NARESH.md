# Naresh: commands and random acts, design v1 (proposal)

One page, for approval. Follows `DESIGN.md` sections 4, 5 and 7, and the original
spec's Naresh section (finite commands, one scripted mistake, never a soft-lock).

## Who he is, in play

Enthusiastic, confident, well-meaning, unreliable. He really tries to help. He is
the same kind of being as the creatures, in human form: wherever he is, the world
tips towards danger, but it is still fun around him. He talks (text only) about
his friend, who is not there. He is **the third pair of hands** the return trip
needs, and the reason it is stressful.

## Giving him a job

- **Look at something and hold Q** (pad: LB, on foot). A small wheel shows the 1-4
  jobs that make sense for what you look at; let go on one to give it. Tap Q while
  looking at him: "follow me" / "wait here".
- Either player can command him; the last command wins. He answers in text
  ("On it!", "My friend says that's a bad idea, but OK").

| Look at... | Jobs |
|---|---|
| Naresh himself | **Follow** (the player who asked) · **Wait here** |
| A spot on the ground | **Go and wait there** |
| A carryable (can, crate, jug, box) | **Carry it** (to you) · **Store it** (on the van's rack) |
| The van's filler with a can on the rack | **Refuel** |
| A lever, crank, door or shutter | **Hold it** (until told to let go) · **Work it** (cranks) |
| A spare wheel | **Carry it** |
| The van | **Get in** (the bench in the back) · **Get out** |

That is the whole list (the finite set in `DESIGN.md`). No free text.

## How he does it (the state machine)

`follow -> go_to -> do_job -> report -> idle` plus `wander` (random act) and
`taken`. He walks with the same controller as the players (so doors, slopes and
crates work the same), at walking pace, and paths round obstacles on a simple
grid near him. If a job becomes impossible (the item fell in the river) he says so
and goes idle. He never stands still silently.

## Random acts

About **one every 3-6 minutes** of play with him, from this table. Rules:

- **Always telegraphed**: a text line 3 s before ("Ooh, what's that?").
- **Never during a timed step** unless it is scripted for that puzzle.
- **Never a soft-lock**: whatever he moves stays reachable; whatever he breaks
  can be fixed nearby.
- Roughly half good, half bad, so players can't simply ignore him.

| Good | Bad |
|---|---|
| Finds a hidden fuel can ("my friend knew it was here") | Wanders off to "show his friend something" (the main way he gets taken) |
| Points at a hidden Memory Fragment (a tag appears) | Honks the horn (creatures hear it up to 150 m) |
| Spots a creature before you do ("someone's watching us") | Turns the headlights on at night (the battery drains; creatures see them) |
| Holds a door open for you without being asked | Pulls the tarp off to "let the van breathe" |
| Fixes the flat tyre by himself (slowly, badly, but it holds) | Drops what he's carrying halfway |
| Solves a puzzle step faster than you, by chance | Solves a puzzle step **chaotically**: right answer, wrong order (a noisy reset) |

## The scripted mistake (from the spec, kept)

On the return, near the fishing village:
1. Players hand Naresh the full can and tell him to **refuel**.
2. He says: "Done. I even checked it twice."
3. Later, the van coughs and stops, dry.
4. The full can is back on the rack; he filled the van from the **empty** one.
   "Then imagine how much fuel I put in."
5. The clue was there: he carried the light, empty can (the can sounds hollow and
   the prompt says "empty"), and the fuel gauge didn't move.
6. The fix: pour the full can yourself, with a creature approaching because the
   engine stalled on the open road.

## Taken, and keeping him safe

- He can be taken **only when alone**: no player within 12 m (`DESIGN.md` 7). A
  creature carries him off in smoke and leaves him **within sight, far away**: on a
  roof, a boat, a salt heap, a signal gantry, 200-400 m off, so you need the van or
  a long walk. He waves and shouts text ("Over here! My friend's with me, don't
  worry").
- Nobody tells the players to keep him between them. They learn it because the
  creatures drift towards him, and the one time they left him alone they had to
  fetch him off a roof.

## His friend (story, text only)

Short lines, never explained, more often as the return goes on:
- "My friend says this road is faster." / "Naresh, there is nobody there." / "He
  says you always do this."
- In the van, he leaves room on the bench beside him and talks to it.
- The last line before the drive home: "He says thank you. He likes you two."

## Save state

Position, current job and target, what he holds, whether he's taken (and where),
and the random-act timer. A load never loses him: if he'd be in a bad spot, he's put
on the van's bench.

## Gym first: the Naresh gym

A flat yard with a lever, a crank, a door, two cans (one empty), the van, a crate,
a box, and a creature switch. Tests: each job from the table completes; an
impossible job reports and goes idle; random acts happen at the set rate and never
during a marked "timed" zone; left alone with the creature switch on, he's taken
to a drop point; the scripted refuel mistake reproduces.

## Questions for you

1. The command key: Q / LB with a small wheel, OK?
2. How often should random acts happen: every 3-6 minutes, or more (more chaos,
   more laughs, more stress)?
3. Should the players ever be able to *see* the friend? (Proposal: never directly;
   once, in the van mirror, a shape on the empty bench for one frame.)
