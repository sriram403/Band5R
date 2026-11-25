# Step 9 re-audit

I sign the navigation fix with reservations because both saved hangs now finish and the remaining issues concern reproducibility and the scope of the evidence.

## Findings in priority order

1. **The new offline control fails in a clean checkout.** At `tools/method/t3_controls.py:627`, the default suite opens two files from one named R7 run. Both are under ignored `appdata/` (confirmed with `git check-ignore`). A new worktree or a cleaned point cache records a failure at line 635 before testing either predicate. Line 589 also requires historical commit `5e70d40`, unavailable in a shallow checkout. Keep the old duplicate-name example and the two observed coolant values in a small tracked fixture with the R7 run and point IDs. Use it in the default controls. The same test can then catch either regression from a clean checkout.

2. **The original recording leaves two steps unjudged.** At `notes/speed_research/step9/test/R7_walk.log:33`, steps 17 and 18 execute without a PASS. Step 19 records “over the pass, running, both aboard”, which proves restart and travel. The saved point independently shows full coolant. For live acceptance, attach the referee's new walk log showing the distinct PASS under each of steps 17 and 18 before step 19. Use that new producer for resume qualification. The earlier recording also cannot resolve a visible twitch at the out-of-view waypoint switches (`notes/speed_research/step9_test_report.md:115`). Reserve that visual claim for a view of those switches.

3. **A second timing prediction missed.** At `notes/speed_research/step9_test_report.md:19`, R3 was predicted at 57–72 s. Its result was 54.9 s with four stops and zero breath events (`notes/speed_research/step9/test/R3_bench.log:80`), consistent with its own earlier walk at about 55 s. List R2 **and R3** as below prediction at report line 46. Replace the general 57–72 s range at `notes/speed_research/step9_build_report.md:115` with the measured range and state whether it measures give-up or the whole step. This discrepancy does not undermine the repair. Round 2 records the bench-only H2 at restore and 1.8 s of window focus. The focus cause remains unknown.

## Prior findings

| Original finding | Re-audit |
|---|---|
| Matrix ownership | Closed. I reran `python -B tools/method/matrix_owners.py`. Gate discovery found 28 plants and 28 unique owners, with no missing, extra or duplicate owners. Only `nose` owns `stale_via` (`tools/method/prove_ghat.py:88`). The inventory control expects 28. Round 2 reports matrix 6/6, T3 137/137, RV1 149/149 and autoq 81/81. Ownership is verified here. Full frozen-tree certification is a separate milestone. |
| Integrated check and solo proof | Closed. The saved R6 planted verdict leads with the expected nose check at 0.16 m, followed by tarp, slump and eyes failures. The separate R6 clean verdict passes all 18 required checks. The tester measured 0.42 m clearance and four stops, with give-up 26.4 s after the nose check against a 70 s limit (`notes/speed_research/step9_test_report.md:57`). |
| Geometry guarantee | Closed. The limited guarantee and reachable-leg follow-up for a future jam are explicit at `notes/speed_research/step9_build_report.md:129`. Eleven samples can miss a grazing corner. Selecting the nearest waypoint does not guarantee progress from every displacement. |
| Event timing and fixture | Closed. Report line 121 separates the drop at 23.25 s in VAN, WANDER at 24.37 s and corner advance at 34.03 s. Line 125 identifies the reduced position/stop/waypoint fixture. Real saved hangs finished at 68.6 and 68.3 s. The four previously successful starts finished near their individual baselines. |

## Walk compatibility and coolant

- The validator at `tools/method/walkgate.py:700` matches the driver's step-name fallback and expectation keys, including watches (`FindingNaresh/scripts/dev/LiveControl.gd:826` and line 912). I scanned the 20 current step-based walks. All passed. The old ghat definition returned exactly the two conflicts at 14/17 and 16/18. The client returns 7 before gate evaluation on a duplicate (`tools/live.py:146`). Play and record stop before launch and return their existing wrapper status 5 (`tools/play_walk.sh:35`, `tools/record_walk.sh:69`). Non-walk command paths bypass this guard. Archived duplicate-name walks deliberately require correction to replay through the client.
- I read the R7 points before steps 16 through 19. Their coolant values were 0.05, 0.6750000000000003, 0.6750000000000003 and 1.0. A full pot holds 2.5 L, the radiator holds 4 L, and the transfer adds 1.6 L/s with a clamp at 1.0 (`FindingNaresh/scripts/items/WaterPot.gd:9`, `FindingNaresh/scripts/vehicle/Camper.gd:147` and line 586). From 0.675, full takes 1.30 L or about 0.81 s of effective pouring. Step 18 holds for 1.8 s and step 17 requires over 2.3 L in hand (`tools/live/make_ghat.py:76` and line 83). The 0.01 margin comfortably covers roundoff. A reading of 0.98 represents a genuine shortfall against the walk's full-radiator objective, even though the engine can restart at 0.75. A future capacity or rate change could make two trips insufficient. Recalculate the trips and hold time if those mechanics change. Keep the present threshold.

Scope was source, saved evidence and read-only checks on branch `step9`. The gameplay verdict covers the two reproduced hangs. The referee's post-change walk and wider seed coverage are outside this review.

SIGN WITH RESERVATIONS — make the new control reproducible, attach live PASS evidence for steps 17/18, and correct the R3 timing summary. The off-camera waypoint switches remain visually unverified.
