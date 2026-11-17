# Speed research (two-model research, example 2): FINAL (2026-11-17)

**Question:** can a smarter test method cut the game-running time of a puzzle's building day by 3x (225 -> <= 75 game min)
without finding less? **Answer: not yet.** The method cut the time ~1.9x but found 3 of the day's 7 holes and kept 18 of 21
starting checks proved. Both signers: **SIGN WITH RESERVATIONS** on the score and on the KEEP / CHANGE list
(`sign_claude.md`, `sign_gpt.md`). Score: `replay_score.md`. Method: `notes/TESTING_METHOD.md` v7.

## The numbers
| | Real day | Replay |
|---|---|---|
| Wall game minutes | 225 | **~119** (13.3 + 94.6 + ~1.0 + 10.1; summed ~170, approximate) |
| The day's 7 holes | 7 | **3** proved (S3, S4, S7); S1 and S5 seen and explained away; S2, S6 missed |
| Starting plant rows still proved | 20-21 | **18 / 21**, 16 firmly (no_fix / no_power confounded by S1) |
| Blind insurance plants (visual) | - | **2 / 2** (X1 via the observation table's GAP + code; X2 via pictures + code) |
| Extras found (real, not on the list) | - | 2 (a warning line off screen; the pot named "the jug") |
| Clean walk + video | yes | walk DONE, but the video leaves P2 on the road from 5:47 (no check looked) |

1.9x is time spent on an **unfinished, lower-coverage** result, not the speed-up to an equal finish (GPT's reservation).

## What each idea gave (measured)
| Idea | Owner | Result |
|---|---|---|
| T1 fast + nodraw on the game clock | Claude | KEEP, restricted: heat / net only (3.6x / 2.9x in the final) |
| T2 cheap proofs (early stop, solo groups) | Claude | KEEP: the 28-row matrix ran in ~20 min on two lanes |
| T3 discovery + selection + receipts | GPT spec, Claude built | KEEP the fail-closed judges; the stale-list TEST cost ~15 min (a usage-doc path error) |
| T4 walk + resume gate + video | GPT spec, Claude built | Resume never qualified on this game: fresh-only; ~45 min of walks. The take checks missed a player left behind |
| Two games at once | both | KEEP: hid the fast half and the recording behind the 13-min normal half |

## Costs of the research (wall game min, apart from the score)
Pilots 7.4 · T1 qualification 56.1 · T3/T4 builder ~19 (incl. fix round) · referee proofs ~4 · **the replay ~119**.
Thread time: 11-10, 11-11, 11-14 (to 15:11, then a rate-limit cut), 11-17 17:37-21:00.

## Lessons (for the skill, general)
- **Telling a blind runner how many holes exist makes it stop at the count** (it counted 2 extras + 2 insurance plants).
- **"The test did it" hid two real holes** (S1, S5): an unexpected failure is a discovery until a short bench says otherwise.
- **A guard that fails closed is right; a guard checked after a 13-min game is slow:** move preflights before launch.
- **Benches at the second failed fix, not after the referee steers** (~18 min lost).
- **The rate limit is a quota, not parallel children:** the runner was cut alone; checkpoints made it free.
- **Fast mode needs proof per scenario:** game code reading the PC clock or shifting slightly kept 5 of 7 at normal speed.

## Next (the user's choices)
- Fix resume (the user chose A, 2026-11-17): ignore the parked van's stale stored speed, save engine / nav / hearing, align the
  settle second; prove SAME + a perturbed DIFFERENT; then measure the saving on a real repair.
- The 7 CHANGE items in TESTING_METHOD v7, each with its planted control, then a NEW blind benchmark (a new secret set: the
  4 misses are now known).
