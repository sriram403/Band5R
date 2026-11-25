# Ghat step 9 independent tester trial
Started 2026-11-25 15:40 IST. Tested gpttest 2aa4e3d.
## Expected outcomes declared before launch
- B1 restores 190738 and gives up in about 69 game seconds. Its original walk never reached step 10 (step 9 at 122 s, failed at 322 s).
- B2 restores 224429 and gives up in about 44 game seconds (its own original 171 - 123 - 4).
- P1 proves stale_via by failing the exact nose check. C1 with identical 1x drawing and no plant passes all 18 checks.
- W1 fresh recording passes every step, including both coolant checks. Inspect step 9 on film.
I chose early stop for the planted proof because the exact failed check is sufficient and leaves time for the fresh recording.
## Results

Each raw command log and its three-second line-count watch are under `gpt_trial/` with the run label below. CPU is mean system load over samples with Godot alive, followed by its range. Command wall time includes startup and shutdown. Budget is measured as real time with a game process alive, including startup.

| Run | Command (from dev, Git Bash) | Observed result | Game time | Command wall | CPU |
|---|---|---|---:|---:|---:|
| B1 | `STEP9_POINT=<190738>/8.json NO_CHECK=1 FAST=1 tools/run_test.sh ghat_step9_bench` | 4 stops, gave up at 68.6 s (44.7 wall); the old walk timed out here. No original give-up time exists. | 69.2 s | 66 s | 57.5% (38-82) |
| B2 | Same command with the 224429 point | 4 stops, gave up at 44.0 s (28.3 wall), exactly the original walk estimate. | 44.7 s | 58 s | 57.1% (27-93) |
| P1 | `EARLY=1 SPEED=fast python tools/method/prove_ghat.py nose` | PROVED. The planted creature still held waypoint 3 after 30.0 s. Its clearance fell to 0.16 m. The exact required check failed. | 149.9 s at detection | 184 s | 53.6% (14-90) |
| C1 | `ROLE=final SPEED=fast GHAT=ghat_looks tools/method_run.sh ghat` | 18/18 passed, including 0.42 m nose clearance and reaching the back corner in 9.7 s. Both P1 and C1 routed to 1x, drawn, profile k3. | 148.0 s physics | 184 s | 56.9% (14-90) |
| W1 | `tools/record_walk.sh ghat --fresh` | 20/20 named checks passed, 26,992 inputs sent, zero dropped. Step 9 started at 122 s, step 10 at 183 s, so about 57 s to give up after subtracting the wait. | 367 s walk | 612 s game lifetime, encoding extra | 52.9% (14-91) |

The full point paths are under `appdata/playtest/FindingNaresh/live/points/` in dev. B1 used `ghat_20261124_190738_7904`, B2 used `ghat_20261117_224429_13940`, and W1 produced `ghat_20261125_155053_13768`. Read each original walk.log for its comparison. The method receipts are in `appdata/method/runs/20261125_154413_ghat_k3_stale_via_1x` and `appdata/method/runs/20261125_154726_ghat_k3_1x`. Their verdict JSONs and W1's walk log are copied into the evidence folder.

## Surprises

- Both bench restores fired the H2 temperature-needle rule at startup (needle 60 degrees with the engine at 126 C). Each bench ended with zero scenario failures but two H2 findings. The clean scenario reported zero H2 findings and zero H2 measurement windows. This trial did not establish correct needle behavior through a restore.
- Seven Godot self-list errors followed the clean scenario end. The benches and recording also logged resource leaks on exit. Neither interrupted gameplay; their causes remain open.
- Step 3 and step 9 both exceeded 60 wall seconds without a walk line. Step 12 also reached about a minute. The three-second watch records the gaps; each step advanced before its game-clock deadline. Encoding continued after the game exited.
- The required builder report and ledger contain secondary references to earlier tester outcomes. I used my own launches and receipts; I did not open the comparison reports or referee evidence.

The CPU sampler observed only one game at a time. Integrating the sampled Godot-alive intervals gives approximately 60.4 + 55.3 + 175.9 + 171.3 + 609.2 = 1,072.1 s (17.9 game-process minutes). Sampling introduces a few seconds of uncertainty per run.
## Video and what I could NOT test

Fresh single take, 369.792 s, no joins between plays. Video: [ghat.mp4](../../appdata/videos/ghat.mp4). Recording command including encoding and joining took 744 s. [Every third second of step 9](gpt_trial/step9_sheet.jpg), read left to right from 02:03 to 03:03.

- 02:03 both players are parked under the mesh, facing a foggy windscreen with white steam rising. At 02:33 P2's breath-hold bar is visible. At [02:37](gpt_trial/frame_157.png) a blue glow reaches the passenger-side edge and the breath-release message is up.
- At [02:40](gpt_trial/frame_160.png) both players see the dark head, glowing eyes and upper body close to the bonnet. The figure crosses left and clears both forward views by [02:46](gpt_trial/frame_166.png). At 02:48 P1's breath bar is visible. These frames establish the close approach and breath cues. The door pillars hide the side-window lean, and the rear sniff is behind the cameras.
- At [03:01](gpt_trial/frame_181.png) the departure message and radiator objective are up. The actual turn and retreat into fog are outside the forward view. The walk independently records the give-up and continues to step 10.
- Coverage is two specific saved states and one fresh take. This does not measure the remaining hang probability across random seeds.

**VERDICT: PASS WITH RESERVATIONS.** The original hang cleared, the known-good timing held, the plant detected the failure, all clean checks passed and the fresh walk finished. The departure and side lean are only partly observable on film. Restore-time H2 findings and engine cleanup messages remain unexplained.

Finished 2026-11-25 16:03 IST. The commit containing this report identifies the trial (`git log -1 --format=%H -- notes/speed_research/gpt_tester_trial_report.md`).
