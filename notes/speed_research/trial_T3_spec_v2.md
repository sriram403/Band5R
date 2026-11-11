# T3 v2 — lean discovery, evidence and replay

2026-11-11. GPT written design for Claude builder. Replaces T3 v1's implementation proposal. Common core of the Claude audit and GPT response; no assertion of a new Claude signature. `answer_specs_gpt.md` records restricted simplifications and five unresolved choices. Markdown spec only; no code/game execution by GPT.

## Scope and prerequisites

Referee supplies a D:-only trial checkout and imports qualified tools. No checkout creation, merges, pushes or gameplay repairs during tool qualification. Do not open secret files or transplant gameplay fixes. Claude builds; referee watches and meters. Keep all generated/cache/temp data on D:, games muted and behind user windows. Reuse existing tools; file names/interfaces may be kept small and reported by builder rather than reproducing v1's framework.

**T1 handoff must pass first:** requested/missing/refused lane inventory with invocation-local IDs; closed and delayed step deadline judgement on both clocks; exact check/run/fixture proof identity including early-stop; hearing/knock mode controls. Each needs a planted bad case and clean pair on the delivered tool identity. Old printed check IDs/open-only deadline controls do not satisfy this handoff. GPT accepts referee's allocation of this work to T1; T3 consumes the evidence, not a duplicate implementation.

Fast qualification is path-specific. Spring and free_coolant proofs stay normal. Places needs a negative control; lean_close needs a robust isolated proof; unresolved no-round divergence and hearing paths stay normal unless T1 resolves/qualifies them. A newly added replay check has no automatic fast qualification. Preserve original reset/order semantics across split lanes or use original normal order. Recompute budget when routing changes.

## Pieces and acceptance controls

Each negative below has a corrected clean counterpart. Offline means no Godot launch.

| Piece to build/reuse | Acceptance control |
|---|---|
| Small input identity helper | Content-tree hash + Godot binary hash before/after run. Define exclusions explicitly (outputs only); include relevant ignored/untracked inputs explicitly, plus generated walk/manifest/plant/tool inputs. Offline: change dirty bytes at same HEAD -> changed hash; simulate pre/post mismatch -> refused; different plant/final tree -> refused. Temporary git index lives on D: and cannot alter real index. |
| Run metadata | Exact returned invocation/run ID, actual plan/profile/fixtures/mode, role (discovery/repair/final), namespace, start/end and exit evidence. Offline: wrong run/fixture/profile fails; compatible record passes. Reuse T1's identities; no glob/latest-folder inference. |
| Design-to-observation table | Before discovery, map each permitted sealed design behaviour to real producer/input and check or manual picture/video observation; uncovered rows stay gaps. Acceptance: reviewer can trace every row; a deliberately omitted behaviour is visibly uncovered, not green by default. No secrets used. |
| Existing discovery commands, explicit continuation | Start all seven; ordinary FAIL evidence accumulates, but STALL/TEST/health/unexplained motion stops affected lane. Picture/log inspection and one notes line precede `GHAT=<remaining>` relaunch. Acceptance uses repaired T1 stop controls; stopped discovery remains diagnostic and cannot pass final checker. No new launcher. |
| Broad repair suite | After each cause batch, run all seven complete scenarios with qualified routing. No map, lint, selector or omitted-check policy. Acceptance: requested inventory is exactly all seven; subsets remain diagnostic. Short benches supplement it. |
| Small final checker | Accept only explicitly final, complete all-seven k3 clean suite, no fixture/shortcut/restored point/continuation, unchanged input identity, full required checks/work/rules/pictures, clean process exits and compatible matrix. Offline: six scenarios, one_corner, restored/continued setup and mid-run mutation each refuse; complete compatible control passes. Existing reducer retains thresholds and missing-check semantics. |
| Manifest helper traversal fix | Follow locally defined callees beyond underscore/prefix restrictions; cycle-safe, preserve repeated invocations, fail on unparsed checks. Offline tiny source controls: non-underscore helper containing required check is included; cycle terminates; repeated helper checks retain multiplicity; unparsed/dynamic unaccounted check refuses. Do not silently change required IDs or drop baseline rows. |
| Proof compatibility gate | Exact active fixture set/scenario/check IDs and completed expected detection; same check PASS in clean final on same input tree. Single-plant pairs accepted. Unestablished batch causality remains NOT PROVED; isolate or get D2 decision. Offline wrong ID with same text, wrong run, missing member and incompatible tree refuse. Early stop retains FAIL / rest not run and verifies exit. No activation logger mandated. |
| Optional overlap namespaces | Separate MPG_DATA, progress/logs, points/live commands, shots and movie parts; targeted quit/stop, no shared result pointer. Inspect actual writable outputs; add other routing only where needed, no writes on C:. Live sentinel: two distinct processes, intentional misroute refused, quit A leaves B heartbeat advancing; corrected pair stays isolated and exits. |
| Referee finish gate | Process sentence: seven holes and blind exam judged by referee; no tool reads secrets. Incomplete inventory/exam cannot be called success. |

Final plant inventory: all 21 baseline rows under R4, plus one per independently found hole and referee exam rows. Remove a row only under referee's authorized, written removed-behaviour ruling, never to meet a count or time cap. Keep safety thresholds. lean_close plant strengthening is a separate decision/proof, not permission here to edit Plant.gd during qualification. Three fortunate catches do not establish a reliable margin.

## Qualification plan

Run offline controls first. T3 planning allowance **3 wall game minutes (2 + 1 reserve)** for namespace sentinel and necessary short real integration. Reuse compatible repaired T1 controls/evidence instead of replaying them. Hard cap **15 T3 game minutes**, with estimate and remaining budget written before every launch; report unrun checks INCOMPLETE. T4 has its own cap and recording contention test. T1 remediation/hearing minutes remain T1 qualification, not replay or hidden free work. Build hours: Claude estimates ~4 for lean T3, unmeasured; no deadline promise.

## Replay playbook and honest budget

Meter qualification separately (R3). Replay score is **union of game-process lifetimes** (R2); also report summed lifetimes, <=247.5 min. Model thinking, edits, encoding and full video watch are reported separately. Shut games down before lengthy reasoning.

Before replay: frozen baseline gameplay/assets plus qualified tools only; no reports revealing holes. Prepare observation table, complete inventory, routing and T4 eligible boundaries. Start budget ledger with actual process costs, not command timeout labels.

| Order | Work | Serial wall game min, planning only |
|---|---|---:|
| 1 | Seven-scenario discovery; explicit independent remainder after inspected stop if needed | 5–6 |
| 2 | Discovery walk + repair producer/resume trials + tail played to end before recording; necessary gate work charged here | ~19 |
| 3 | Two repair batches, each all seven (~4.4 each), plus <=~4 optional short discriminating proofs/benches | ~13 |
| 4 | Frozen-tree full plant matrix, baseline + new holes, exact clean pairing | 14–17 |
| 5 | Final unshortened seven-scenario clean suite on same frozen tree | 4.4 |
| 6 | Fresh full clean recorded real-input walk, reviewed after exit | 12.6–16.2 |
| 7 | Reserve/exam plants and their clean checks | 4–8 |
| Total | Rounded estimate, no earned overlap savings yet | **~74–84** |

Basis: T1 measured 4.4 for one clean split suite versus 18.7 normal, not 4.4 per future arbitrary routing. Matrix and repair figures are Claude estimates, not measured full replay totals. Recording assumes ~11 game minutes from the audit; TESTING_METHOD measured 68–87% real-time recording, so 11/0.87 to 11/0.68 = 12.6–16.2 wall min. Time an actual clip and replace this estimate. The 19-min walk/repair/gate allocation is provisional; a refused point or long fresh prefix may exceed it.

### A schedule with only two game slots

1. Discover and fix with explicit watched launches. At most two games globally; do not edit acceptance inputs while a game uses them.
2. Freeze final inputs. Run final fast clean lane beside its normal spring lane, then stop both. This is the measured 4.4-min shape, conditional on qualified split/reset semantics.
3. Run fast plant groups in available proof time. Route every plant according to T1 evidence; do not use a planted run as clean suite evidence.
4. Run the **one sequential proof lane** of normal plant groups beside the fresh recording. Put any remaining fast groups in this same proof slot only if recording contention qualification covers them. Never run recording + fast proof + normal proof simultaneously. Interleave the matrix schedule around recording, preserving exact clean/plant identity.
5. Stop all games, encode, inspect required pictures and watch entire video with sound. Referee exam follows its own boundary/identity rules and is charged, not presumed free.

Accept an overlap saving only after T4's paired throughput/capture test and an actual job queue show it. Net saving = serial lifetimes minus overlapping union, **after** recording slowdown/startup/tail. Do not add an assumed suite/matrix saving on top of this schedule. If net saving is **9–10 min**, planning union becomes **~64–75 min**; otherwise recalculate from actual costs. This is the safe conditional budget to take back to Claude, not a jointly signed result. Claude's current 62–68 remains dispute D5.

Fallback costs are additions, not hidden inside 4.4: hearing normal routing audit estimate ~+3 per suite; three suites -> ~+9 if that estimate holds. Full normal suite 18.7 versus 4.4 adds ~14.3 each. Isolated unresolved batches, additional fixes, gate prefixes, or a fresh clean walk after joined-only footage also add actual minutes. Do not claim the target survives a fallback without measurement.

### Walk / video policy while decisions are pending

Use T4 v2's qualified real producer paths and first-break stop. A fresh clean recording satisfies both clean walk and video positions. A joined video is allowed with validated joins; whether it replaces the fresh clean-walk receipt remains D1, never infer permission from R5 (withdrawn). Resume optimizations under D3/D4 are not earned until agreed and qualified; unqualified points require real prefixes. Ambiguous grouped plants under D2 remain uncertified.

Before every launch write expected cost, remaining target budget and required jobs. Watch step/movement/physics/errors every few seconds in both lanes. Off plan: bounded current picture, scoped stop, verify exit, inspect and retain original failure. For shared uncertainty stop both. No rerun-until-green, no check weakening. After 2–3 failed fixes use a small bench; stop/refer repeated loops. At projected >75 or actual 75, stop benchmark as INCOMPLETE and report which required work remains. Referee's ~2h wall cap also applies.

Report actual union/summed score and qualification, all commands/identities, controls with clean/negative outcomes, changed routing, raw errors and retained failures, required pictures, full plant matrix, video/watch evidence, five dispute decisions and referee's independent score. No <=75 / all-holes claim before that evidence exists.
