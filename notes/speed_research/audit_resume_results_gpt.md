# Resume results audit — GPT, 2026-11-17

**CHANGE FIRST — items 2–4 below; then the short timing bench and a new producer + two resumes. P13 is NOT qualified.**

Read-only audit: no Godot/game/walk, controls runner, code edits or commits. Only this report written.
I inspected main..resume and the listed on-disk evidence; calculations called pure judge functions in memory, with bytecode writes disabled.
Paths below are relative to MPG_dev. P = appdata/playtest/FindingNaresh/live/points/.
F = ghat_rp14_20261117_205524_24252; F2 = ghat_rp14_20261117_210651_22032;
R1 = ghat_rp14_20261117_211154_21124; R2 = ghat_rp14_20261117_211516_20984.

1. **The numbers fit delayed input; they do not prove that F2 alone is wrong.**
   Independently calculated from P/<run>/13.obs.json and 13.t3.json, using p2.@xf origins and meta counters:

   | Run | Physics ticks | Drawn frames | Draws / 3 game s | P2 displacement, m |
   |---|---:|---:|---:|---:|
   | F | 180 | 144 | 48.00 | 12.494056 |
   | F2 | 180 | 95 | 31.67 | 12.208169 |
   | R1 | 180 | 118 | 39.33 | 12.495947 |
   | R2 | 180 | 146 | 48.67 | 12.495947 |

   R1's interval is 39.33 draws/game-s, not 41 in the explanation. All four samples say at_game_ms=3000.
   F2 and both resumes each have 179 axis requests; F2 sends first at 16 ms, resumes at 17 ms; values/order match.
   F2 final velocity = Vector3(0.42942992, 0, 4.278484); R1/R2 = Vector3(0.42946556, 0, 4.2784796).
   F2→R1/R2 layer3 returns exactly the 0.288 m / 0.25 deg failure; R1→R2 returns [].
   F2→R1 travel difference 0.287777 m is about four ticks at 4.3 m/s. This is consistent with delayed activation.
   But traces record REQUEST time (PlayTest.gd:339–348), not delivery or the player's first moving tick.
   F also starts elsewhere (x=934.1967 versus F2 x=934.4397) and has different test/tools hashes (run.json): not a controlled fresh/fresh comparison.
   I think restored floor/contact state, initial input-device state, or different callback phase can also cause a start transient with the same final speed.
   Cheap separator: first 10 physics ticks, log sent axis, Input.get_joy_axis, player-read axis, position/velocity, floor status, callback phase and draw counter.
   Compare two fresh starts and a restore at matched and different draw rates; compare flush off/on. Average fps alone cannot establish causation.

2. **The flush is a sensible candidate, not a sufficient timing proof.**
   PlayTest.gd:379–391/1322–1348 flushes after key/axis/button injection. It should remove queued delivery delay.
   [Godot 4.5 input.cpp:1149–1178](https://github.com/godotengine/godot/blob/4.5/core/input/input.cpp#L1149) queues accumulated events; flush drains them.
   [main.cpp:4399–4405](https://github.com/godotengine/godot/blob/4.5/main/main.cpp#L4399) agile flushing happens BEFORE physics_frame callbacks: it cannot flush an event injected later in that callback until a later flush.
   _pad_walk_to_raw sends after physics_frame (PlayTest.gd:11157–11166); Boot polls devices in _physics_process (Boot.gd:412–417), then PlayerRig reads them (PlayerRig.gd:295).
   Thus this movement path can receive the axis before player processing. Check the actual binary/settings and measured order; do not generalise this to all commands.
   LiveControl starts steps from timer/process contexts too; wait uses an idle timer (PlayTest.gd:461–465).
   Draw waits remain: shot (PlayTest.gd:501–510), marker (LiveControl.gd:241–255), and paused hold (691–692). Flushing does not remove their scheduling effects.
   Mouse motion is still unflushed (PlayTest.gd:447–453). Walks with mouse then key can flush the pending mouse incidentally at the key.
   **Required:** save/restore flush_inputs around the walk, including early returns. It is set true at LiveControl.gd:600 and never reset in _end_walk:852 onwards.
   Otherwise a later non-walk test in the same process inherits changed timing. All walks also change input timing; cover short key/button taps, releases and mouse ordering on the bench.

3. **The eight changes are largely present, but the promised guards are incomplete.**
   #1 pause, two observations and frame-age rebasing exist; #2 body/player/child restoration and extra observations exist;
   #3 typed ages/sentinels exist; #4 seed-v1 and restricted RNG admission exist; #5 held/engine refusals remain, no far-item tolerance;
   #6 REPAIR has unique run/PID and point/gate/protocol hashes; #7 validation/controls exist; #8 design labels the saving an estimate, but no saving is proved yet.
   a239f25's bytes for scalar vars and rigid-body pose, explicit refs and frame ages address actual lost state without widening equality.
   e8a7cd4's local pose under the same parent avoids inverse-transform rounding; item parent/global pose observations remain. I found no new tolerance escape there.
   Exactness is not universal: player pose/velocity, body velocities and child transforms still use text (ResumeV1.gd:68,172,214). A later mismatch there remains a failure to investigate.
   Bench B1 only proves L1/L2/final: appdata/resume_B1.out explicitly reports DIFFERENT, missing fresh +3 s sample. It is not trajectory qualification.
   **Required:** observe collision-exception identities, not just counts (GateObs.gd:41/53/72). Swapping the excluded body preserves the count but changes collisions: false SAME remains possible.
   **Required:** close the final-observation gap. LiveControl.gd:718 observes, 719 awaits the client, 730 reapplies clocks, then unpauses.
   Always nodes/signals may change other state during that last await. Require a synchronous release-time comparison against the approved state, with no await before input.
   The observed 311/331 ms holds and +21/+22 physics ticks (resume_R2.out / resume_R1.out) prove paused counters advance, not that every hidden state is frozen.

4. **Three reproducible guard/control holes must be fixed before buying the long producer.**
   (a) **Hearing expiry false SAME:** copied F2 observation in memory; used one unconsumed event above every heard ID, age 1995 versus 2005 ms, identical other fields. layer2 returns [].
   walkgate.py:218 retains both via the unconsumed-ID branch; :359 allows their 10 ms age difference. Hearing.gd:30 prunes only the older case on the next emit.
   Required: preserve the side of the real >2000 ms pruning boundary, including 2000 exactly; add planted and clean expiry controls. Existing wall-stamp controls do not test this queue case.
   (b) **Malformed adapters admitted:** on real F2/13, separately set live_frames=[], live_refs={}, live_clock=[], or live_problem_children={count:99}; also removed every body's xf/lxf/parent.
   Every mutation returned validate_rv1=[] AND refusal=[] (walkgate.py:54–98). This is not fail-closed completeness; later equality catches only fields independently observed/exercised.
   Required: validate expected owner/field/body/child/ref coverage, types and finite values, supported versions and payloads; add controls for these exact missing-content cases.
   rv1_controls.py:45–48 itself admits synthetic empty frames/children content; :87–88 tests missing containers only. Its final duplicate-boundary comment has no actual boundary test.
   (c) **Client identity not enforced for normal SAME:** changing only F2's tools hash to CHANGED gives identity_check=[] (walkgate.py:510–531).
   tree_id.py:110–114 puts tools/live.py outside test/testcode; only repair_check enforces tools. judge_resume/boundary (:625–677) do not check producer/resume identity themselves.
   Required: enforce action-producing helper/client identity in normal admission and receipt/boundary judging too; plant changed-client and duplicate-run boundary controls.
   Keep pure judge/admission controls separate from live restore proof: editing two JSON objects does not exercise ResumeV1 restoration.

5. **Minimum next proof, with the minutes made explicit.**
   First fix 2–4 and rerun the targeted offline controls; no game minutes. Freeze helper/judge identity before production.
   Then a watched short timing bench as in #1, including a deliberately delayed final verdict and planted exception-ID mismatch; I think ~0.5–1 min including launch is a reasonable target, not measured.
   Only if it succeeds: new F3 on the final build, then two distinct process resumes of its immutable P13, unchanged step 14 and same profile, all layers and next_step SAME, no bypass flags.
   F2 cannot qualify the flush build: testcode changed. R2's completed pot outcome and R1↔R2 agreement do not replace F2 comparison.
   Measured F2 launch-to-stop = 303 s (resume_F2.out 21:06:35–21:11:38); R1 = 26 s (resume_R1.out 21:11:38–21:12:04).
   At those costs F3+two resumes is ~355 s = 5.92 min; allow ~6–6.5 because one short run is not a guaranteed launch cost.
   With the bench this is ~6.4–7.5 min versus ~6.5 left (task budget: 20−13.5). Do not promise the complete proof inside the remainder.
   For the agreed perturbation claim also need X1 van +0.2 m detected specifically at L3, and X2 dropped hearing detected at L2 before input, against clean counterparts.
   I think another ~0.7–1 min for both launches; repair-to-DONE and the saving estimate are additional, deferred work. Stop at the budget; report INCOMPLETE if qualification/controls remain.
   F2 step 14 PASSED (resume_F2.out): this has not reproduced a real failed-step repair, so do not claim that measured benefit yet.

6. **Do not widen layer 3.**
   The frozen bound is 0.05 m; observed clean-reference disagreements are 0.288 m and two mutually matching resumes, with no controlled post-flush fresh/fresh spread.
   Those numbers diagnose a timing/state question; they do not justify a new bound. Keep P13 unqualified until fresh→resume passes the original judge twice and the paired negatives fail for their named reasons.
