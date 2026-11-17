# T3 v2 builder report (Claude builder for GPT's spec, 2026-11-14)

Task: `MPG\notes\speed_research\trial_T34_v2_build_task.md` (read first; only its list read). Copy `MPG_speed_t34`, branch
`speed-t34`. `speed-t1` merged again first (`2e31a0b`: T1 round 2's solo groups, `passed_ids`, the fast table), kept intact.
Decisions built: **D2 A** (batch members need their own solo proof), D3 / D4 A (T4's gate), D1 B (T4), D5 (the replay
stops on a projection past 75). Game code untouched (`scripts/` except `scripts/dev/`, scenes, assets, `core/Plant.gd`).

## Files and interfaces

| File | What |
|---|---|
| `tools/method/tree_id.py` (first builder, reused) | input identity: one temp git index on D: (copy of the real one, never written back), groups `game` / `test` / `tools` / `full` + `bin` (Godot binaries, ignored by git, hashed directly). Excluded, outputs only: `appdata/`, `FindingNaresh/.godot/`, `_shots*`, `notes/`, the editor / headless data. Checked: the only ignored inputs are the 2 Godot binaries (hashed) and caches |
| `tools/method_run.sh` | **run metadata**: `ROLE` (discovery / repair / final / proof / diag), `tree_pre.json` + `tree_post.json` per run, `run_meta.json` (inv, part, run, plan, profile, fixture, speed, lane, role, namespace, start, end, rc, Godot left in the lane, `FROM_POINT`, `GHAT`, `EXPECT_IDS`). **Routing**: `FAST_OK` = heat, net, marks (T1 round 2's final table: looks' glass check 1x); `FAST_OK_OVERRIDE` for diagnostics only |
| `tools/method/prove_ghat.py` | `ROLE=proof` passed to each group's run (one line) |
| `tools/method/make_ghat_manifest.py` | **traversal fix**: every call of a locally defined function (any name; also a function passed as a value), cycle-safe on the call path, every call site counts (`id`, `id_2`), comments skipped, a dynamic `call("..."+x)` / `callv(var)` / `Callable(self, var)` in a traversed function refuses (exit != 0) unless listed in `DYNAMIC_OK` (empty), unparsed check refuses as before. `MANIFEST_OLD=1` = the old traversal byte for byte; `MANIFEST_SRC` = another source (controls) |
| `tools/method/t3_gate.py` (new) | `final` (the small final checker), `proof` (proof compatibility, D2 A), `obstable` (design-to-observation table) |
| `tools/method/t3_controls.py` (new) | the offline controls below (49) |
| `tools/method/lane_sentinel.sh` (new) | the live lane sentinel (2 games), shared with T4's recording contention |
| `notes/speed_research/REPLAY_USAGE.md` (new) | the replay runner's commands, no results |

Reused, not rebuilt: discovery = `method_run.sh` + `GHAT=` continuation + T1's watcher; requested / missing / refused
lane inventory = T1's `combine_parts.py`; exact proof ids, sealed verdicts, early stop = T1's `prove_ghat.py`;
namespaces = T1's `LANE=b` folders + T4's `instance.json` / `godot_guard.py` / `stop_lane.sh`.

## Offline controls (`python tools/method/t3_controls.py`: 49 / 49)

| Piece | Planted failure -> refused | Clean -> accepted |
|---|---|---|
| Input identity (scratch git repo under `appdata/t3ctl/`) | dirty bytes at the same HEAD; an untracked input; a changed plant (`core/Plant.gd`); a changed walk (test group, game group unchanged); pre/post mismatch (`tree_id.py same` exit 1) | same tree twice; bytes put back; output-only changes (`appdata/`, `notes/`); **the real index byte-identical after** |
| Manifest traversal (tiny sources; old traversal printed beside) | unparsed check; dynamic call | non-underscore helper (old: missed it); cycle a -> b -> a (2 rows, ends); helper called twice -> 2 rows (old: 0); callback passed as a value; commented check not counted; **real PlayTest.gd: the same 116 ids in the same order as before the fix** |
| Final checker (receipts in T1's exact format) | six scenarios; a `GHAT=` continuation (four); `one_corner` fixture; role repair; restored point; early stop; inputs changed mid-run; parts on different trees; looks run fast; profile k1; a game left in the lane; a part FAILED; no `run_meta.json`; not the frozen tree | all seven, k3, no fixture, final, same tree (also = the frozen tree) |
| Proof compatibility | wrong id with the same text start; another invocation's run folder; another input tree; its check not PASSed in the clean final; batch-only proof (D2 A: 3 / 3 NOT); a batch member's own check absent; early stop before its id; game not checked gone; a clean suite that is itself refused | single plant, own id FAILed, PASS in the clean final, same tree; batch members with their own solo proofs (2 CERTIFIED) |
| Observation table | a row with no observation (GAP); an unknown check id (UNKNOWN); no real producer (GAP) | every row observed (check id / picture / video moment) |

The receipt-format controls use receipts built by the control script (no archived T1 run folders exist in this copy;
reading another copy's `appdata` is outside the allowed list). They exercise the reducers only; the receipts' format
is the one `method_run.sh` / `method_verdict.py` write (`run_info.txt` first line, sealed `verdict.txt` + `verdict.json`,
`trace.json` `asked`, `expected`, `.dir`, `.rc`).

## Live (T3 allowance 3 + 1, hard 5)

| # | Run | Expected | Wall | Watched | Result |
|---|---|---:|---:|---|---|
| R2 (shared, charged to T4) | `lane_sentinel.sh`: lane b plain game + lane a rec25 take | 2.2 | 2.67 union | Monitor | misroute b -> a folder **refused (6)**, a -> b folder **refused (6)**, lane b's own command answered (0), two distinct pids; after lane a's targeted stop: lane a gone, **lane b same pid alive, heartbeat 7369 -> 7555**; lane b stopped, verified gone. The tool printed SENTINEL FAIL on its own bug (a Windows `\r` in a pid comparison; the printed values were equal): fixed, then R4 |
| R4 | `lane_sentinel.sh` again (fixed; lane b walking the whole time), 2026-11-14 14:03, PC idle (CPU 52 % avg with both games) | 2.8 | 2.0 union (3.0 summed) | Monitor every 3 s + CPU sampler | **SENTINEL PASS** (`appdata/t34/R4.out`): lane b's own command answered (0); misroute b -> a folder **refused (6)**, a -> b folder **refused (6)**; two distinct pids (15912 / 8908); lane a's take DONE and its targeted stop left lane a gone; **lane b same pid alive, heartbeat 4773 -> 4956 in 3 s**; lane b played 4 walks as its workload the whole time; lane b stopped, verified gone. Lane b held 59.7 physics frames/s beside the recording (60.0 alone after) |

An earlier R4 attempt (13:32, under GTA) is void: its log stops mid-check at 13:34:53 (no "lane b walks" or stop lines), which matches the referee's stop at
the user's request at ~13:35 killing lane b and the script; its "lane b still running: BAD" is read as that kill. The
idle rerun above passed every check.

## Deviations and what I had to change

- **Routing changed** in `method_run.sh` (`FAST_OK`): looks moved to the 1x part, from T1 round 2's final table. Budget:
  T1's estimate for that table is ~11.8 wall min serial (1x lane ~9.3 + fast lane ~2.5), not the measured 4.4 shape.
- The final checker's "compatible matrix" is that routing (fast only heat / net / marks); marks' fast PASS also needs
  its looks prelude's round in the same run per T1's table: in the final suite looks runs in the 1x part, so the
  checker does not (cannot) check that prelude; recorded here as a gap of the matrix check, not hidden.
- The observation table is a Markdown file the replay writes; the tool only reads it (no design rows are written here:
  they would come from the sealed design, which a tool must not read).
- `tree_id.py` was built by the first builder under T4; reused here as T3's identity helper (same file).

## UNQUALIFIED / not done

- The final checker and proof gate were exercised on built receipts, not on a live final suite (the suite is replay work,
  ~11.8 min serial on the new routing; nothing in the T3 allowance pays for it).
- The referee finish gate is a process sentence (REPLAY_USAGE: the referee judges the seven holes and the exam); no tool.
- T1's open items are not touched (lane isolation of *suites* beyond this sentinel, nodraw interleaving, lean_close plant).

## Fix round (2026-11-14, `trial_T34_fix_build_task.md`)

Corrections to the sections above:
- **R4: lane b's worker walks were 2 ok of 4.** The line "lane b played 4 walks as its workload the whole time" left
  that out. The sentinel did not judge its workload; since F5 it does, and that same log is refused.
- **Routing (Deviations, first two bullets) is superseded by F6.** Marks now runs in the 1x part after looks. The
  "gap of the matrix check" is closed by F6's prelude rule.

| Item | Commit | What | Control pair (planted refused / clean passed) |
|---|---|---|---|
| F5 (sentinel) | `db81a62` | `tools/method/sentinel_workers.py`; `lane_sentinel.sh` checks "lane b's worker walks" (every walk `RESULT: ok`, at least one) before it can print SENTINEL PASS | R4's real `sentinel_b_walk.log` (2 of 4) REFUSED; that log with only its ok walks ACCEPTED; a log with no walk REFUSED |
| F6 | `4c6179e` | `tools/method/route.py`: SPEED=fast routing (fast = heat, net; **marks in the 1x part with looks**, plan order: looks before marks in one process); `method_run.sh` uses it. `t3_gate final` refuses a marks PASS unless its part ran looks before marks, the run asked that order, and the looks round id is in `passed_ids` | refused, each by the prelude rule alone: marks split from looks (the old routing); looks made no round; marks before looks. Clean (marks after looks, round PASSED) ACCEPTED. `solo_marks_pile` under SPEED=fast: old routing = 2 parts -> NOT PROVED by `prove_ghat.judge`; F6 routing = 1 part -> PROVED |
| F7 | `4caff50` | pictures: `PlayTest.shot()` -> `_capture_row` writes one row per picture into `<shots>/captures.jsonl` (scenario, tag, file, drawn / physics frame, game ms, unix time, sha256, last check); `method_run.sh` empties it at the launch, copies shots with their times (`cp -p`), runs `captures.py inventory` -> `capture_inventory.json` (the launch time, every row, the copied file's sha / mtime, earlier captures of a tag marked superseded). `t3_gate final` requires, per part: the inventory (written after the launch), every required picture (`captures.py required`: literal `shot` / `obs_shot` at the top level of the scenario's own function) and every logged one present, captured after the launch, its file's bytes = the captured ones, no one file standing for two pictures, and a line in `<inv>/inspection.md` (`<scenario>/<tag>: what it shows`) | refused, each by the picture rule alone: a required picture never captured; captured but its file missing; older than the launch; bytes replaced; one file for two pictures; no inventory; inventory older than the launch; a logged picture without an inspection line; no inspection file. Clean ACCEPTED. Live smoke (0.28 game min): 2 rows, sha256 = the files, `captures.check` passes them |
| F8 | `2d9b2ee` | 11 new solo groups in `prove_ghat.py` (every member of every multi-plant group now has one; parent's scenario and time-saver flag, own exact ids: checked equal to the parent's); "alone" = one behavioural plant (`one_flat` / `one_corner` don't count, R4); `prove_ghat.MATRIX` = the 21 rows, listed command by command in REPLAY_USAGE; `t3_gate.py matrix <final> <frozen> <proofs...>` lists every `Plant.on` row of the game as CERTIFIED / NOT CERTIFIED / NOT DONE and refuses when the inputs changed since the freeze | clean: 21 / 21 CERTIFIED, complete. Refused: one row's proof missing (cap_text NOT DONE); jug_a proved only as a batch (3 NOT CERTIFIED); a check added after the freeze (PROBLEM: refreeze + new final); a new plant with no group (NOT DONE). The game's rows = 21 |
| F9 | `24f5a31` | `tools/method/seal.py`: the test-only flags (GATE_PROBE, GATE_L2_CONTINUE, GATE_NOABORT, GATE_PERTURB, GATE_RESUMES, JOIN_GATE_WAIVED, WALK_FAIL_AT, NO_MAKE, GUARD_INJECT, T1_LAG, MANIFEST_OLD, MANIFEST_SRC, EXPECT_FAIL, FAST_OK_OVERRIDE, FAST; SPEED other than "" / fast). `method_run.sh` (ROLE=final / proof), `prove_ghat.py` and `record_walk.sh ghat` refuse before any launch and write `seal.json`; `t3_gate final` / `proof` require a sealed receipt | every flag REFUSED (16 cases), clean environment SEALED (3 roles), a discovery run not sealed (allowed). Gate: a receipt that found GATE_RESUMES REFUSED (by the seal rule alone), no receipt REFUSED, clean ACCEPTED; a proof whose receipt found JOIN_GATE_WAIVED NOT certified, clean CERTIFIED. Live, no game started: `method_run.sh` ROLE=final + GATE_PROBE exit 3 (no run folder); `prove_ghat.py` + T1_LAG exit 3; `record_walk.sh ghat` + GATE_NOABORT exit 3 |
| F10 | `33e06ba` | manifest traversal: also `self.<local>()`, `self.<local>` as a value, and the literal target of `call` / `callv` / `call_deferred` / `Callable(self, "<local>")` (bare or on self; `obj.call("x")` is another object's) | followed (old traversal: 0 rows each): self.helper(), self.helper as a value, call("helper"), callv("helper", []), self.call_deferred("helper"), Callable(self, "helper").call(). Not followed: boot.call("helper"). Still refused: callv(<variable>), Callable(self, <variable>). Real PlayTest.gd: the same 116 ids |

`python tools/method/t3_controls.py`: **123 / 123** (49 in the build; the F10 commit message says 125, a slip: 123 is the
count). `t4_controls.py`: 85 / 85.

Budget effect of F6 (estimate, not measured): marks leaves the fast lane for the 1x lane: with T1's fast marks
~4.6x, the 1x lane grows by about marks' 1x time (~3.3 game min) minus its fast share (~0.7). F8's matrix is 21
launches, each with its own boot, instead of 11 batch groups: more minutes. Neither was measured here (no live suite
this round, as the task says).

**UNQUALIFIED after the fix round (T3):** the final checker, proof gate, matrix, picture and seal rules on a live
final suite and live proofs (offline receipts + one live picture smoke + three live refusals only); the statically
required pictures were never seen in a live final run (a wrong one refuses the final, it can't pass a missing one);
F6's routing and F8's 21 solo launches have no measured cost; the observation table's completeness review stays human.
