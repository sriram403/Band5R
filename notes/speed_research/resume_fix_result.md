# Resume fix: result (2026-11-17, branch `resume` in MPG_dev, not merged)

**Point 13 of the real ghat walk (the start of step 14, ~4.4 game min in) is QUALIFIED SAME** under the original gate
(no bound widened): two resumes in separate games, every layer SAME; the two planted controls DIFFERENT for their own
reason; a REPAIR resume of main's real walk from it played on to DONE. Design: `resume_fix_design.md` v2 (GPT audit
`audit_resume_fix_gpt.md`); results audit `audit_resume_results_gpt.md` (CHANGE FIRST: all taken before this proof).

## The proof chain (`appdata/resume_chain.log`; build `3053aa1`; CPU avg 61 % during it: Opera + T3 Code, GTA closed)
| Run | Points folder | Verdict | What it shows |
|---|---|---|---|
| F3 fresh producer (ghat_rp14) | `ghat_rp14_20261117_212548_20588` | DONE 270 s | point 13 written with its rv1 record |
| R1 resume | `..._213038_19488` | **SAME** (all layers) | layer 1+2, final check, release check, layer 3 (P2 1.7 cm from fresh), step outcome |
| R2 resume (another game) | `..._213120_24296` | **SAME** (all layers) | identical to R1 at +3 s |
| X1 van +0.2 m after the release check | `..._213204_25240` | DIFFERENT | layer 3 names `van.@xf` 0.200 m |
| X2 hearing restore off | `..._213241_25228` | DIFFERENT, before any input | layer 2 names `Hearing._next_id` 214 -> 6 and the queue |
| REPAIR: main's `ghat.json` from point 13 | `ghat_20261117_213319_23712` | REPAIR, DONE | steps 14-20 in 117 s |

## The saving (one sample each; an ESTIMATE as agreed with GPT: no separate fresh fixed walk was bought)
| | Wall time |
|---|---|
| Fresh walk to DONE (F3's launch -> step 14 start 265 s, + the repair's steps 14-20 117 s, + stop) | **~6.4 min** |
| Resume from point 13 to DONE (the REPAIR run, launch -> stop, 21:32:57 -> 21:35:19) | **~2.4 min** |
| Saved per repair at step 14 | **~4.0 min (~2.7x)** |
The replay's failures (steps 11, 17, 19) each cost a fresh walk; with qualified points near them each would cost the
suffix + ~20 s. **Not shown:** a real failed step repaired (the replay's failing route PASSED on main's game: that
failure belonged to the replay copy's game); other points qualified (each needs its own 2 receipts); engine-on points
(still refused: the engine restore is built, not proved).

## What it took (the findings, in order)
1. A restore lost: the van's freeze + stored speed, item / van / player vars, players' full pose, Problem's children,
   clocks (wall ms / s) and hearing (queue + serial), the global RNG; the 1-s running settle (+ the verdict wait).
2. R1 (first build): 34 layer-2 differences: text round-trips lost a float's last digit; refs a plain snapshot skips;
   physics-frame stamps (frames count on while paused); the observation's clock read at its end.
3. Bench: 3 "far sleeping items" 1e-7 off: a world pose set under a turned parent rounds: restored by LOCAL pose (exact).
4. F2/R1/R2: layer 3 0.288 m. The data FIT the fresh run starting late (32 fps drawn; test stick input applied at the
   next drawn frame; F at 48 fps matched the resumes), but that cause was not isolated by a controlled bench (GPT).
   Change: walk stick input flushed in the tick it is sent; with it the fresh -> resume comparison passed twice. (Flushing keys too ran the F1 menu inside the physics
   tick: engine error, caught at step 1 in 3 s.)
5. GPT's results audit: 3 false-SAME holes in the judges (hearing prune side, empty record contents, client identity),
   flush reset, exceptions by identity, a synchronous release check: fixed before the proof chain (controls 106 / 106).
6. GPT's final audit (DON'T SIGN for merge yet; the P13 SAME proof itself confirmed by its own rejudging): record
   validation still admitted an unknown frames kind, a deleted Problem child pose, a NaN seed. Fixed after the chain
   (seed a finite integer, frame kinds and clock units bound to their fields; after GPT's re-check, Problem's children
   must match a frozen list taken from F3 (14 index paths, child 2's 10 script fields: gate_inventory "problem_children"); receipts judge the
   release observation too); controls 128 / 128, each new guard seen failing when switched off; every saved run
   rejudged under the tightened gate: boundary F3/13 SAME, X1 / X2 DIFFERENT, REPAIR (`appdata/resume_rejudged_v3.json`).
   The judges changed, so new resumes need a new producer (identity binds the tools): by design.

## Cost
Game minutes (meter, `appdata/meter_resume.log`): **~23.5** (budget ~20, the user approved the overrun: A): F 5.0,
R1 0.6, benches 2.3, F2 + R1 5.5, R2 0.6, F3 aborted 0.4, the final chain 9.8 (F3 4.9, R1, R2, X1, X2 ~0.6 each,
REPAIR 2.4), compile checks ~0.1.
