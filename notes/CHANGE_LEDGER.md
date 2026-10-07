# Change ledger (Milestone G, the puzzle tuning)

The user, 2026-10-08: no full test run before every push. Instead, for
every puzzle we finish we note here **what changed**, **what it could break**
(our guess) and **which tests cover it**. The long runs (set:driving, full)
start in the background in `MPG` right after a push, while the next puzzle
is built in `../MPG_dev`; what they find is written under the entry it
points to, and fixed in the next round. At the end of the puzzle tuning, one
last full run is checked against the whole ledger.

**When a long run fails:** look here first. Find the entry whose "could
break" matches (a van stuck in the woods: the undergrowth; a test stopped
at J1: the junction gate), fix it, write what it was under "Found later".

Per entry: the puzzle, its branch and merge, then three lists.

---

## #2 The windmill (rounds 1-2, branches `g4`, `g5`; merged into main 2026-10-08, not pushed)

**What changed**
- `puzzles/WindmillPower.gd` (new; `WindmillBrake.gd` deleted): the 24 m
  windmill at J1, the starter lever, sliding legs, the fall and restart,
  the rope ladder, the walkway and chest, the napin. Group `windmill`.
- `puzzles/WindmillWire.gd` (new): the switch house, poles and wire, the
  spark, the street lamps on the lane and both roads after J1, the storm
  wreckage past them.
- The junction gate across Home Lane just south of J1 (closed until the
  windmill turns), fences either side (`world/Fence.gd`, new), thickets
  (`world/Thicket.gd`, new).
- The windmill's meadow fenced along the lane's west verge for 230 m, with a
  stile 22 m south of the gate (`LevelLandmarks._windmill`, `_stile`).
- **World-wide:** undergrowth between close trees that only the van hits
  (`LevelScatter._undergrowth`, layer `VAN_BLOCK` = 128, the Camper's mask);
  extra bushes and fallen logs in the woods; a pad and a wider tree clearing
  at the windmill (`LevelLayout.PADS`, `CLEARINGS`).
- **One map, one holder:** `MapState.holder` (saved), `who_has_it`; the map
  on the upstairs desk at P2's (HouseInterior); M only for the holder; E on
  your partner takes it (`PlayerRig._snatch_target`, `take_map_from`).
- **One pin:** `MapState.STAMP_TYPES = ["napin"]`, `napin` flag (saved),
  `find_napin` / `lose_napin`; PaperMap's help text and `place_stamp`; the
  van's nav text ("NAPIN", "no pin").
- **The head-butt:** G / pad RB with empty hands on foot
  (`PlayerRig.headbutt`, `_strike`, wind-up, shake, `dazed_t`,
  `ui/StarsRing.gd`, `fx/ButtFx.gd`); legs, partner, Naresh, the van
  (`Camper.thump`), loose things, walls.
- **Push out of the van:** seated G / pad hold RB (`PlayerRig._push_controls`,
  `Camper.push_out`).
- **Solo testing:** TAB keeps the left player holding
  (`InputDevice.kept`, `park_keeping`, `take_over`; `Boot.keep_holding`;
  F1 Puzzles toggle; HUD "HOLDING E").
- Story: P2's opening step "take the map from the desk"; `to_windmill`
  done at the gate; `windmill` (the gate has no power), `napin` (climb);
  `stamp_beach` worded for the napin. DevMenu: the Puzzles row, jumps set
  the map holder and the napin, reset_way_out. SaveGame: group `windmill`.
- Input glyphs: `fwd` / `back` (the ladder said "[?/?]").

**What it could break (our guess)**
- Anything that drives through J1 from the south: the gate is shut until
  the windmill turns (journey, routes, way_out, any walk or test that
  drives Home Lane north). Tests that pass J1 must call `wm_open_gate()`.
- Anything that drives off the road near woods: the van now stops at the
  undergrowth (the auto-driver cutting a bend, a test that parks the van
  off-road with `van_spot`, a creature test's van placement, a walk that
  drives across grass).
- Anything that walks from Home Lane to the windmill area: the meadow fence
  (only the stile lets you through).
- Anything that presses G or pad RB with empty hands: it now head-butts
  (and a G that throws no longer butts). Pad RB held in a parked van pushes
  the other out after 0.5 s.
- Anything that reads or places map stamps (old types are gone; only
  "napin"), or opens the map as P1 in a new game (P2 has it; P1 can't
  open it until they take it), or loads an old save (holder defaults to
  P2, the napin to "not found").
- Anything that relies on TAB letting go of keys (held keys are now kept).
- World build time (+1.3 s) and frame rate in the woods (more bushes and
  logs in the MultiMeshes).
- The opening's P2 steps (the map step changed).

**Tests that cover it**
- `windmill`, `windmill_fall`, `fun`, `solo`, `gate_bypass`, `save`,
  set:opening, smoke, set:creatures: 0 failures (2026-10-08).
- Walks `puzzle2` (285 s) and `solo2` (97 s) recorded, every step passing.
- Not yet run on this: **set:driving** (journey, routes: they now open the
  gate first), **full**.

**Found later** (by the long runs)
- (none yet)
