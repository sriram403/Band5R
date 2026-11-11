# Stage 3: the Claude auditor's audit of GPT's T3 + T4 specs (2026-11-11)

Task: `audit_specs_claude_task.md` (read first). Read only its list: SPEED_RESEARCH, scoreboard (R1-R5), top4,
audit_r2 x2, trial_T3_spec, trial_T4_spec, TESTING_METHOD, `MPG_speed_t1/notes/speed_research/` (P1, P1b, P1c,
trial_T1), and code in `MPG_speed_base` (read-only: `method_run.sh`, `record_walk.sh`, `play_walk.sh`,
`prove_ghat.py`, `make_ghat_manifest.py`, `make_ghat.py`, `LiveControl.gd` 180-200 / 367-640, `Plant.gd` header,
`SaveGame.gd` grep, `DevMenu.gd` grep, `Creature.gd` / `Hearing.gd` / `Carryable.gd` greps). Nothing on the
DO-NOT-READ list opened. No game run, no code changed. This is the only file written.

**Evidence marks:** *code* = read in `MPG_speed_base` (file:line); *T1* = measured in `trial_T1.md` / pilots;
*I think* = my estimate, unmeasured. Build hours are all *I think*.

## 0. Five facts from the code and T1 that GPT's specs did not have or did not use

1. **The whole suite is 4.4 wall min fast** (T1 run 13: 6 scenarios fast + spring 1x beside them; 18.7 at 1x).
   GPT budgets 8 per suite. That changes what every T3 piece is worth: a change -> checks map can now save at
   most ~2-3 min a repair round (the suite minus the chosen scenarios; spring's 1x lane alone is 3.8 of the 4.4).
2. **The ghat has one entry point.** `DevMenu.gd:30` has one ghat row ("The ghat pace notes", the foot of the
   hairpins); every scenario (`_ghat_start`, `PlayTest.gd:4323`) and the walk's step 1 start there. So no walk
   section after step 1 has a real producer path except its whole prefix. GPT's own T4 text says the natural
   groups "are sequentially dependent". The 7 scenarios already are the independent views of the later stages.
3. **No ghat walk step leaves a watch open.** `make_ghat.py` uses no `"watch": true` and no `"needs"`; an expect
   without `watch` blocks the step until it passes or fails (`LiveControl.gd:609-624`). At every ghat boundary
   the open-watch list is empty.
4. **A spawned helper keeps sending input after a FAIL.** `spawn` is fire-and-forget (`LiveControl.gd:190-193`);
   `walk_breath_bot` (`PlayTest.gd:4580`) loops on `phase != "leave"` and wall time, pressing CTRL / pad B, and
   never reads `_fail`. The failure picture (`LiveControl.gd:635`) is taken while it may still be holding keys.
5. **Game code on fast scenarios reads the wall clock for hearing.** `Hearing.gd:29` stamps sounds in wall ms;
   `Creature.gd:448` treats an item sound within **1500 wall ms** of the last as a bounce; `Carryable.gd:164`
   debounces knocks on wall ms. At ~4.7x the bounce window covers ~7 game s and the debounce ~0.7 game s. Item
   sounds come from `Carryable.gd:177` (pot, coolant jug). None of T1's 9 plants touches hearing or knocks
   (`Plant.gd` header), so T1's qualification of ghat_jug / ghat_places fast never tested these paths.

## 1. Every strict piece, one row

Cost columns: **build** h (I think) / **qual** = game min in qualification (GPT's allocation) / **replay** = game
min it adds or saves in the replay.

### T3

| # | Piece | The real miss it guards against | Cost: build / qual / replay | Verdict | Why |
|---|---|---|---|---|---|
| 1 | **Receipts: content hashes** (HEAD, dirty + untracked bytes, engine, import settings, assets, tools, manifest, plants, profile, fixtures, PIDs, pre + post stamp, atomic seal) | A final PASS or a plant PROVED on a tree that isn't the final one. Real: `run_info.txt` today stores HEAD + `git status --porcelain` only (`method_run.sh`), so an edit after the run with the same file list is invisible; T1 found the 11-09 proof file was from another source (T1 "Assumed -> reality"). | 3 h / 0 / 0 | **SIMPLIFY** | Keep the core: one **tree hash** (a temp git index, `add -A` minus `appdata/`, `write-tree`) + the Godot binary's hash, stamped before and after each run; a mismatch = refused. Drop PIDs, per-asset lists, import-settings fields (inside the tree anyway), atomic sealing, the "not a crypto system" machinery. ~1 h. |
| 2 | **Change -> checks map** (`speed_plan.json`, producers / consumers per check, closure, omitted-with-reason) | Rerunning scenarios a fix can't touch (waste), and a narrow pick that skips one a fix breaks (a late loop, not a hole: the final suite runs all seven). | 5-6 h (a hand map of 90+ required checks) / 0 / saves ~2 min a round at best | **CUT** | Fact 1: all seven fast = 4.4 min. GPT's own rule sends vehicle, creature, hearing, shared helpers or anything unknown to all seven, which is nearly every ghat game fix (Ghat / Creature / Camper / VanAttack). So the map selects "all seven" almost always and its one-off cost (hours + a wrong-map risk) buys ~0-5 min a replay. Rule instead: **after a fix batch, run all seven fast.** Strictly stronger, so no hole can pass by the cut. Contradicts `top4.md` T3 ("a conservative change -> checks map"): I signed that before T1 measured 4.4 min. |
| 3 | **Map lint + mutation controls** (deleted shared edge, renamed / deleted / untracked files, cross-consumer case) | A map that validates itself. | 2 h / 0 / 0 | **CUT** (goes with 2) | Nothing to guard once there is no map. |
| 4 | **Design-to-observation table** before discovery (behaviour -> producer -> check or picture) | A design behaviour with no check: the suite can't find a hole nobody checks (the brief: "all 7 holes found, each with a check"). | 1 h model time / 0 / 0 | **KEEP** | Free in game minutes and the only piece aimed at holes no check covers. |
| 5 | **Discovery launcher** (`speed_run.sh discovery` / `discovery-remaining`, JSON report, inspection record, BLOCKED) | Auto-continuing after a STALL (the user's stop-and-look rule); a discovery run promoted to the final PASS. | 2 h / ~3 / 0 | **SIMPLIFY** | It exists already: `method_watch` stops on STALL / TEST / NOT HEALTHY and lets FAILs run on; T1's `GHAT=<rest> SPEED=fast method_run.sh ghat` runs the remaining scenarios by command. Keep only the rule (stop, look, one inspection line in the trial notes, then the rest by command) and let #6 refuse a discovery run as final. No new launcher, no live stall control (T1's `overrun` fixture already proved a STALL stops the run, fast and 1x). |
| 6 | **Final launcher / finish check** (refuses 6 scenarios, `one_corner`, dirty-on-exit, h1 setup, a continuation disguised as final) | A final "PASS" that ran a subset, a shortcut fixture or a changed tree. | 1.5 h / 0 / 0 | **KEEP, small** | A ~30-line check over `run_info.txt` + verdict: plan = all 7, profile k3, fixture empty, tree hash same before / after and = the plant matrix's. Offline controls only (feed it 4 bad run folders). Drop the "synthetic ledger admitted by wrapper" layer. |
| 7 | **Lane isolation for two games** (MPG_DATA, APPDATA, TMP, progress, live commands, shots, Movie parts per lane; PID-scoped stop; sentinel control) | Real, from the code: `method_run.sh` copies every `_shots/test_*.png` newer than its launch mark into its run, and the walk's failure picture is `_shots/test_walk_fail.png` (`LiveControl.gd:636`): a walk beside a lane-a suite puts the walk's picture into the suite's evidence. `record_walk.sh` / `play_walk.sh` use `MPG_DATA=appdata/playtest` and `live.py --quit`, which would hit any other `--playtest=live` game. T1 isolated lane b for suites only. | 2 h / ~1.5 / **saves ~8-10** | **KEEP, SIMPLIFY** | It is now the biggest replay lever left (section 3: the 1x plant lane beside the recorded walk). Scope it to what the game and tools actually write (MPG_DATA, shots dir, live dir, `live.py` target); drop APPDATA / LOCALAPPDATA / TMP routing unless the sentinel run shows a write there. Keep GPT's sentinel control (two short processes, one path misrouted -> refused; quit A, B's heartbeat goes on). Add: **measure Movie Maker's speed with a second game beside it** (T1 saw fast lanes drop 4.7x -> 3.5x beside another game). |
| 8 | **Plant attribution** (exact scenario / check id, activation / reach, closed window, clean control; ambiguous groups isolated) | A plant "PROVED" by a substring that some other FAIL matched, or by a check that also fails on the clean game (in the benchmark the clean game has 7 holes, so a check can FAIL with no plant at all). | 1 h / 0 / 0 | **SIMPLIFY** | T1 already made `prove_ghat.py` take its own run folder and name the exact check id. What's left that matters: **the same check id must PASS in the clean final suite on the same tree hash** (#1, #6). Drop "activation evidence": `Plant.gd` logs nothing at activation, adding it is a `core/` change, and the clean-PASS + plant-FAIL pair on one tree already proves causation for one-plant groups. Multi-plant groups (jug_a 3, jug_b 3, fog_h2_keep 3, ...) each name a different check id, so one plant can't be credited with another's FAIL. |
| 9 | **Finish refuses until the referee's score** | The tools scoring their own blind exam. | 0.2 h / 0 / 0 | **KEEP** | A sentence of process, no code. |
| 10 | **Manifest helper-prefix gap** (GPT: review call sites outside `_ghat`, `_fix_with`, `_hide_well`) | A new check in a helper the manifest doesn't follow is not "required", so if it never runs the verdict still says PASS. Real: `make_ghat_manifest.py` `CALL` matches only `_name(` with those prefixes; `walk_breath_bot`-style helpers are skipped. | 0.5 h / 0 / 0 | **KEEP, as a code fix** | Follow every call to any function defined in `PlayTest.gd` (drop the prefix filter), and fail on a check whose text the regex can't parse (it already does). Cheaper and stronger than a manual review. |

### T4

| # | Piece | The real miss it guards against | Cost: build / qual / replay | Verdict | Why |
|---|---|---|---|---|---|
| 11 | **Section graph + independent diagnostic sections** (`ghat_sections.json`, producers, consumers, admission rules) | Carrying on past a break into states the break made wrong (false FAILs, wrong blame). | 3 h / ~2.5 / ~0 | **CUT the graph; keep the rule** | Fact 2: the only real producer path for any later section is its whole prefix; GPT itself expects most sections BLOCKED. The graph would mostly print "BLOCKED". Rule instead: the walk stops at its first break (h1 does), everything after it is BLOCKED by definition, and the 7 scenarios (each from F1) are the independent discovery of the later stages. |
| 12 | **Cancel inputs and helpers on the first FAIL** (no awaited helper resumes; release every hold) | Fact 4: `walk_breath_bot` keeps pressing CTRL / pad B after a FAIL; the failure picture and saved state can show the helper's doing, not the break's. | 0.5 h / ~0.5 / 0 | **KEEP** | Cheap, real. Helpers check a cancel flag each tick; `_release()` before the failure shot. One control: fail a step while a spawned helper is holding a key -> no input after the FAIL line. |
| 13 | **Point identity** (immutable points, source / dirty / untracked / walk / schema / engine hashes; last-fail only points to an ID) | Resuming or joining across a game fix: `record_walk.sh` decides a part belongs to the take only by `resume_step` == last-fail step, not by source, so a prefix recorded on the old game can be joined to a suffix on the fixed game. Points are overwritten on every run (`LiveControl.gd:553`). | 1 h / 0 / 0 | **SIMPLIFY** | Reuse #1's tree hash, split in two: game code (everything but `scripts/dev`, `tools`) and walk / test. A point or a part is usable only with the same game-code hash; stop overwriting a point that a take depends on (copy it under its hash). Drop RNG ownership, per-field engine / profile stamps beyond the binary hash. |
| 14 | **Layer 1 inventory** (every script property, statics, Callables, RNG, physics contacts, coroutines, animation / audio, Hearing queue, children) | Fields the restore drops, so two snapshots agree while the world differs. Known from code: van velocity + engine (`SaveGame.gd:165-175`), `_item_ms`, `director`, Problem's children. | 6-8 h / ~1 / 0 | **SIMPLIFY** | Script vars of Ghat, Problem (+ its children's), Camper, VanAttack, both players, held carryables, plus van physics; each field saved / rebuilt / refused. Turn the known gaps into **refusal rules** instead of adapters (rows 17-20). Skip statics / RNG / contacts / coroutines as inventory items: layer 3 and the final fresh take catch their effects. ~2 h. |
| 15 | **Layer 2: immediate round trip before any frame, before h1's 1 s wait** | The 1 s wait (`LiveControl.gd:538`) lets the world settle before anything is compared, which hides a restore difference. | 1.5 h / 0 (rides on resumes) / 0 | **KEEP** | Free in game minutes, exact by construction, it would show today's engine / velocity loss at once. |
| 16 | **Layer 3: +3 game s, fresh vs two resumes, event order, next step's outcomes** | A hidden field that only shows once things move (contact, a coroutine). | 2.5 h / ~3-5 / ~1 per boundary | **SIMPLIFY** | Every run writes the +3 s snapshot at each step start (the fresh side is free). **One resume** per boundary, compared to the fresh run, tolerances from T1's measured 1x spread (0.05 m, ±1 s, 0.5 C / L, 2 %), not from a second resume. A second resume only when the first is within 1.5x of a tolerance. Contradicts `top4.md` ("tolerance from two resumes"): T1 has since measured the spread. Keep "compare to fresh, not to each other". |
| 17 | **Van engine / velocity adapter** + engine-on negative control | Real (`SaveGame.gd:165`, `:175`): a moving or idling van resumes stopped and off. | 1 h / ~1 / 0 | **SIMPLIFY** | Refuse any boundary with van speed > 0.1 m/s or engine on (the gate's layer 2 shows it anyway). The expensive boundaries (steps 7-18, the encounter and the spring) all have a boiled, stopped van. Keep the one live control (restore at step 3's point: engine on -> DIFFERENT). Adapter only if a needed boundary is refused. |
| 18 | **`_item_ms` + Hearing queue rebase** + the 1.5 s bounce control | Real: wall-ms stamps cross processes (`Creature.gd:73, 448-450`, `Hearing.gd:29`). | 2 h / ~1 / 0 | **SIMPLIFY** | Refuse a boundary with an item sound or Hearing event under 2 s old (`KEEP_MS`); otherwise set `_item_ms` to its unset value (-99999), which is what an old stamp means to the 1500 ms test. No rebasing code. Offline control only. |
| 19 | **Watch-budget restore** (remaining budget kept, no fresh `within`) + the 0.5 s / +0.8 s control | A resumed watch getting a fresh deadline. | 2 h / ~0.5 / 0 | **CUT for the ghat** | Fact 3: no ghat boundary has an open watch. Replace with one line: refuse a boundary whose open-watch list is not empty. |
| 20 | **Callables, children, pose / eye / hum reconstruction** | `director` Callable and Problem's children aren't saved (`_snap_vars`, `LiveControl.gd:402-412`). | 2 h / 0 / 0 | **SIMPLIFY** | `_restore_live` calls the real `_spawn_problem` when Problem is absent (`:449-451`), which is always the case in a new process, so `director` is set by its owner. Put Problem's child transforms, eye emission and hum pitch into the layer-2 / 3 snapshot (what checks and the video read); refuse on a difference. |
| 21 | **25-fps recording clip**: deadline-negative fixture + captured sound | T1 moved walk deadlines to game time (`el_ms` = max of game and wall); Movie Maker runs at 68-87 % of real time (TESTING_METHOD), so a game-time deadline under 25 fps is new and unproven; muted speakers say nothing about the encoded sound. | 1 h / ~2 / 0 | **KEEP** | Real and cheap. Also time it **beside a second game** (row 7). |
| 22 | **Movie join validator** (`joins.json`, ffprobe times, frame ranges, mutations: missing part, wrong identity, corrupt range, stale prefix, silent audio) | Joins at the wrong frame (cut by `Engine.get_frames_drawn()`, not movie frames: `record_walk.sh` "first" / "fr"), a part from an old game, no join times for the user. | 3 h / ~1 / 0 | **SIMPLIFY** | Keep: join times from ffprobe durations of the trimmed parts (`record_walk.sh` already prints them), the list `MM:SS -> step, part, gate`, the game-code hash per part (#13), and a frame pair either side of each join looked at. Cut the mutation set except "a part with another game-code hash -> refused". Silent audio: the full watch with sound (#24) catches it. |
| 23 | **A separate uninterrupted fresh clean walk even when every join is SAME** (R5, disputed) | Hidden state no gate lists making the joined suffix differ from a real continuous play. | 0 / 0 / **+0 if the take is clean, +~14 if a take fails** | **The user's call; my pick below (section 4)** | |
| 24 | **Watch the whole final video with sound**, both sides of every join | A video that looks done but has a missing view, sound, or a bad join. | 0 / 0 / 0 (after exit) | **KEEP** | The user's rule. Zero score minutes. |

### Qualification controls (each one)

| Control | Verdict | Why |
|---|---|---|
| T3 map builder / selector mutations | **CUT** | No map (row 2). |
| T3 receipt reducer mutations (dirty bytes same HEAD, fixture, manifest, removed receipt, duplicate ids, truncated run, mid-run mutation, mixed revisions) | **SIMPLIFY** to 3 offline cases: dirty byte same HEAD -> different hash; edit during a run -> refused; plant proof and final suite on different hashes -> refused. Duplicate / missing check receipts: `method_verdict.py` already reports missing required checks. |
| T3 discovery hang at entry 2, no auto entry 3 | **CUT** | T1's `overrun` fixture already proved STALL-stops, fast and 1x; continuation is by command, not code. |
| T3 final launcher refusals | **KEEP** offline (row 6). |
| T3 lane isolation sentinel | **KEEP** (row 7), + Movie Maker speed beside a second game. |
| T3 plant attribution (`lean_close` only -> `fast_turn` NOT PROVED; same-substring unrelated FAIL) | **SIMPLIFY**: one offline case on T1's real run folders (a FAIL with the right text on the wrong check id -> NOT PROVED). |
| T4 section graph / discovery control | **SIMPLIFY** to row 12's control (fail with a held helper -> no input after FAIL). |
| T4 identity / point ownership | **KEEP**, offline, game-code hash only. |
| T4 layer-1 omissions | **SIMPLIFY**: offline, remove `engine_on` and one child field from a real point -> refused. |
| T4 layer-2 restore mutations (engine off, `_item_ms`, child field, watch budget) | **SIMPLIFY**: offline against one real saved observation, minus the watch-budget case (row 19). |
| T4 layer-3 post-restore perturbation (+0.1 m, a discrete state, a delayed input; two identical wrong resumes) | **KEEP** one live case (move an actor 0.2 m after the immediate compare -> +3 s DIFFERENT); the rest offline. |
| T4 timestamp / watch behaviour | **SIMPLIFY**: hearing part becomes the refusal rule's offline test (row 18); watch part cut (row 19). |
| T4 movie wrapper / join validator mutations | **SIMPLIFY** (row 22). |
| T4 movie time / cancellation (25 fps just-late fixture) | **KEEP** (row 21). |
| **Missing: a hearing / knock differential plant** | **ADD** (section 2, miss 1). |

**Count (24 pieces):** KEEP 8 (4, 6, 9, 10, 12, 15, 21, 24), SIMPLIFY 11 (1, 5, 7, 8, 13, 14, 16, 17, 18, 20,
22), CUT 4 (2, 3, 11, 19), 1 to the user (23). Controls (14 in the specs): 5 kept, 7 simplified, 2 cut; 1 added.

**Build hours:** GPT's specs as written ~35 h (T3 ~14, T4 ~21); the lean version ~12 h (T3 ~4, T4 ~8). **~23 h
saved** (I think). Qualification game minutes: GPT 9 (or 6 fast) + 14 = 20-23; lean ~5-7 (T3 ~1.5-2, T4 ~4-5).

## 2. What the specs miss

1. **A hole can hide in the fast final suite (biggest gap).** Fact 5: hearing's bounce window and the knock
   debounce are game-code wall clocks on scenarios T1 qualified fast (jug, places; any item landing near the
   van). At ~4.7x a second item sound inside ~7 game s counts as a bounce, a knock inside ~0.7 game s is
   swallowed: the creature hears **less** fast than at 1x. A hole like "dropping the jug gives you away"
   would make a "nobody is taken" check FAIL at 1x and PASS fast. T1's 9 plants don't touch hearing, so
   nothing qualifies these paths, and GPT's final suite runs fast. **Fix (~2-3 qual min):** a test-only plant
   on the hearing path (e.g. a sound the creature must hear, made twice 1 game s apart) proved the same fast
   and 1x; if it differs, ghat_jug and ghat_places run **1x in the final suite** (in the 1x lane beside the
   fast lane: ~+3 min). The walk and the take are 1x, so they cover the chained path either way.
2. **The plant matrix and the take are under-budgeted** (section 3): GPT 7 + 10; my count ~14-17 + ~14.
3. **Immediate new-hole proofs are paid twice.** GPT proves each new plant at once (order 3) and then reruns
   them at the final tree unless "dependency content is identical", which after later fixes it won't be. With
   a tree-hash rule, the immediate proof is a full duplicate. Do it fast with early stop (~0.7 min) only for
   checks you doubt; the final matrix carries the proof.
4. **`lean_close` is a coin toss** (T1: planted 0.13 fast / 0.18 at 1x against a 0.15 limit; clean 0.33-0.40).
   The replay can "PROVE" it by luck. Neither spec says what happens. The check passes on the clean game with a
   wide margin, so the plant is what's weak: move its window stop to 2.0 m (a `Plant.gd` change: the user's OK,
   rule FINAL.md step 8), or prove it 3 times. Otherwise a weak check rides through as "PROVED".
5. **The unexplained fast ghat_looks "0 stops" run** (T1: 1 of 4). It fails loudly, but a FAIL in the replay's
   discovery suite will look like a hole. Rule: a ghat_looks round with 0 stops fast is rerun at 1x before
   anyone hunts it as a hole (~2.5 min when it happens).
6. **A walk that breaks early leaves its end unrun until the take.** With no independent sections (fact 2),
   steps after the last break are first played in the recorded take. A break there costs a take (~14 min).
   Cheap guard: once all known breaks are fixed, one unrecorded resume from the last repair point to the end
   before recording (it rides on h1 + the gate).

## 3. Do GPT's numbers hold up?

**Qualification** (R3 caps 15 each): T3 9 / 6 is fine but mostly buys controls I'd cut; **T4 14 of 15** has 1 min of
reserve for a 5-min encounter prefix and two resumes: one rerun blows the cap. Lean: ~2 + ~5.

**Replay** (wall union minutes; fast = T1's measured numbers):

| Order | GPT fast | Measured / my estimate | Basis |
|---|---:|---:|---|
| 1 discovery suite | 8 | **5-6** | T1: 4.4 clean; + a relaunch of the rest after a STALL |
| 2 + 4 discovery walk + repairs | 8 + 10 | **~19** | Walk length from `make_ghat.py` step bodies ~11 game min (I think); h1 resume ~40 s each + replayed failed steps, ~5 breaks |
| 3 fixes: suites + immediate proofs | 7 | **~13** | 2 all-seven fast rounds 9 + fast early-stop proofs ~4 (miss 3) |
| 5 plant matrix (21 + ~7 new) | 7 | **~14-17** | T1: 5 fast groups 6.0 min (no early stop); 3 fast groups not run (~3.2); 1x lane spring_a + spring_b + jug_b ~9-10; new plants ~5 fast + 1x spring ones ~4-8; union of two lanes |
| 6 final suite | 8 | **4.4** (+3 if miss 1 forces jug / places to 1x) | T1 run 13 |
| 7 recorded take | 10 | **~14** | ~11 game min at Movie Maker's 68-87 % (TESTING_METHOD); unmeasured |
| 8 reserve + exam plants | 4 | 4-8 | 2-3 exam plants, spring ones at 1x ~4 each |
| **Total** | **62** (54 with overlap) | **~74-82 serial** | |

So **GPT's 62 doesn't hold**: suites are cheaper than GPT thought (4.4 vs 8), but the matrix, the fixes and the
take are ~2x its allocations. Serial, the plan sits at or over 75. **With overlap it fits**: (a) the final suite
and the matrix run as one two-lane batch on the frozen tree (fast lane = suite + fast groups, 1x lane = spring +
1x groups), saving ~4; (b) the 1x plant lane runs **beside the recorded take** (needs row 7 + the Movie Maker
speed check), saving ~8-10. Lean plan: **~62-68**, I think. GPT's overlap (discovery suite beside discovery
walk) saves only ~4 now that the suite is 4.4. If the R5 dispute goes to "a separate fresh walk too" and the
first take is joined, add ~11-14: back to ~75-80.

## 4. Where the specs contradict `top4.md` or the rulings

| Point | top4 / ruling | GPT spec | My view |
|---|---|---|---|
| Final suite speed | top4: "one final unshortened suite" (speed not said); both r2 audits: final at 1x | fast, conditional on T1 | Fast is fine **except** the hearing paths (miss 1). |
| Joined take as the clean walk | R5 withdrawn, DISPUTED; top4: a step resumed from a point that fails the gate doesn't count | T4: a joined video "does not replace a separate uninterrupted fresh clean-walk receipt"; T3 order 7: "joins only for review" | **My pick (the user decides): a joined take counts as the clean walk only if every part has the same game-code hash and every join is SAME on all 3 layers.** Joins then only help after test-side or recording trouble (a flaky input, a capture glitch), never across a game fix, which is GPT's real worry (a prefix from the old game). Residual risk: hidden state the gate doesn't list; I think it's small because the deep boundaries (7-18) have a stopped, boiled van and no open watch. GPT's version costs ~+11-14 min whenever the first take fails. |
| Layer 3 noise floor | top4: "tolerance from two resumes" | two resumes | One resume + T1's measured 1x spread (row 16). A change to the signed text, on new evidence. |
| Change -> checks map | top4 T3 includes it | full map + lint | Cut (row 2), on T1's 4.4 min. A change to the signed text, on new evidence. |
| Qualification caps (R3) | <= 15 each | T4 14 | Within, but no room for a rerun. |
| R4 (21 rows) | 21 + new + exam | 21, counts asked of the referee | Consistent. |

## 5. Can the replay pass while a hole stays in the game? (tried to break it)

| Attack | Gets through GPT's spec? | Gets through the lean spec? |
|---|---|---|
| A hole on the hearing / knock path, final suite fast (miss 1) | **Yes**, unless the walk happens to exercise it | No, with the hearing plant (or jug / places at 1x in the final) |
| Stale green: final suite on tree A, a fix after it | No (receipts) | No (tree hash before / after, same hash as the matrix) |
| Plant "PROVED" by a check that also fails on the holed clean game | No (clean control) | No (same check id PASS in the clean final, same hash) |
| A weak check proved by luck (`lean_close`) | **Yes** (not addressed) | No, if the plant is firmed or proved 3x (miss 4) |
| A new check in a helper outside the manifest prefixes never runs, PASS | Partly (manual review) | No (manifest follows every call, row 10) |
| A joined take hides a break in the chain across a game fix | No (fresh walk required) | No (same game-code hash for every part) |
| A joined take, same game, hidden state differs in the suffix | No | Possible, small (the user's R5 call) |
| A helper keeps playing after a FAIL and the failure picture shows its doing | No (cancellation) | No (row 12) |
| A walk hole after the last discovered break, only in the take | No hole passes (the take fails), costs a take | Same, plus the pre-take run-through (miss 6) |
| Lane cross-talk: the walk's fail picture lands in a suite's evidence | No (isolation) | No (row 7) |

## 6. The leanest spec that still catches everything

1. One **tree hash** (+ the Godot binary's) stamped before / after every run; final suite and plant matrix must share it.
2. A **finish check**: all 7, k3, no fixture, hash unchanged, = the matrix's hash; refuses a discovery run.
3. **Discovery suite = the suite** fast; stop on STALL, look, write one line, run the rest by `GHAT=`.
4. **After every fix batch: all seven fast** (4.4 min). No change -> checks map.
5. **Design-to-observation table** before discovery (0 game min).
6. **Manifest follows every call** in `PlayTest.gd`.
7. **Plant proof** = exact check id FAIL with the plant + the same id PASS in the clean final, same hash.
   New plants proved fast with early stop only when in doubt; the final matrix proves all.
8. **Hearing / knock plant** proved fast = 1x, or ghat_jug + ghat_places run 1x in the final.
9. **`lean_close`**: firm the plant (the user's OK) or prove it 3 times.
10. **Lanes** isolated for MPG_DATA, shots, live dir and `live.py` target; sentinel control; Movie Maker timed beside a second game.
11. **Walk:** stop at the first break, the rest BLOCKED; helpers cancelled and inputs released before the failure picture.
12. **Resume gate:** points stamped with the game-code hash and kept; refuse boundaries with a moving / running
    van, an open watch, a live helper or a hearing event < 2 s old; layer 2 before the 1 s wait (incl. Problem's
    child state); layer 3 at +3 s vs the fresh run, one resume, T1's tolerances.
13. **Recording:** 25-fps clip for the game-time deadline and the encoded sound; join times from ffprobe;
    parts only with the same game-code hash; a frame pair at each join; the whole video watched with sound.
14. **Replay order:** discovery suite (fast) -> discovery walk (1x) -> fix batch -> all seven fast -> repeat ->
    walk resumes to the end -> freeze -> suite + matrix as one two-lane batch -> recorded take with the 1x
    plant lane beside it -> exam plants.

## 7. Verdict

**SIGN WITH CHANGES.** GPT's specs are honest about what they don't know and guard the right things (stale
greens, causal proofs, lane cross-talk, the resume's real gaps, cancelling after a FAIL), and I found the code
facts it cites (the 1 s wait, the zeroed van, `_item_ms`, the shared paths) all true. But about a third of
the strictness guards nothing on this puzzle (a map that would almost always pick all seven; a section graph
with one entry point; watch-budget restore with no open watches), the budget is ~2x short on the matrix, the
fixes and the take, and one real hole path (game-code hearing clocks under the fast final suite) is
unguarded. With the changes above: ~12 h to build instead of ~35, ~6 qualification min instead of ~22, and
~62-68 replay min (I think).

To the user's question: **I audited GPT's specs, and I don't think they should be this strict.** Strict where a
false PASS can get through (the hash, the clean-control pair, cancelling, the gate's layer 2, the hearing plant);
lean where the final suite or the fresh take already backs it up.
