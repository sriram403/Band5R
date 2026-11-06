# g2 experiment manifest (frozen before the first measured run, 13:23)

Head: this commit on `g13-trial-g2`. Game files: sha256 list `appdata/g2/game_hash_before.txt`
(462 tracked files outside `scripts/dev`; list hash 30d6b955...). Each run: `tools/g2_run.sh <scen> <id>`,
fresh process, outputs in `appdata/g2/runs/<id>/`. No reruns to obtain an outcome.

| Order | Run id | Scenario | Factor |
|---|---|---|---|
| 1-3 | B1, B2, B3 | `ramp` (today's t_ramp, unmodified, recorder only) | none |
| 4-5 | A0, A1 | `g2_a0`, `g2_a1` | pre-retry wait 0.3 s / 5.0 s |
| 6-7 | B0, B1x | `g2_b0`, `g2_b1` | steering release at z gate / held until first all-off sample |
| 8-9 | C0, C1 | `g2_c0`, `g2_c1` | retry decisions after awaited physics_frame / in late _physics_process (prio 50000) |
| 10-11 | S0, S1 | `g2_s0`, `g2_s1` | P2 at near-side reset point (dry) / c2's river spot |
| 12 | K1 | `g2_s0` + `--g2-control=stale` | REQUIRED lookup `rj._launched` pointed at `_launched_gone` |
| 13 | K2 | `g2_s0` + `--g2-control=stall` | setup_wait awaits a signal nobody emits (5 s deadline) |
| 14 | K3 | `g2_s0` + `--g2-control=early` | returns after slow_result, before hands_off_done / arm_end |

Recorder phases: pre (SceneTree.physics_frame, connected once at ready), late (_physics_process,
priority 100000), proc (_process). Camper / RampJump priorities: logged per run in the manifest.
Prefix copy diff: `python -I tools/g2/prefix_diff.py` (also `appdata/g2/prefix_diff.txt`).
No new numeric classification is used; drift, speeds and offsets are reported as measurements.
