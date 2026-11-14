# Replay usage: the T3 / T4 v2 tools, start to finish

Commands only. Run from the copy's root in Git Bash. Every game is muted, behind your windows, writes only
under `appdata/`. Exit codes: 0 PASS / accepted, 1 FAIL / refused, 2 INCOMPLETE, 3 TEST / guard refused,
4 NOT HEALTHY, 5 gate refused (walks), 6 lane misrouted.

## Rules that every step follows

- **At most 2 games on the PC.** Every launcher runs the guard; check by hand with
  `python tools/method/godot_guard.py [b]`. A second game is lane b: put `LANE=b` before the command.
- **Before every launch** write its expected wall minutes and the running total in your budget ledger.
  Stop the replay as INCOMPLETE when the projection passes 75 wall game minutes.
- **CPU load beside every timing.** Close other heavy programs first. While a run lives, sample the load
  (stop it by creating the stop file):
  `powershell.exe -NoProfile -File tools/method/cpu_sampler.ps1 -Out appdata/<run>_cpu.tsv -Stop appdata/<run>_cpu.stop -HbB appdata/playtest_b/FindingNaresh/live/heartbeat.json &`
  then `touch appdata/<run>_cpu.stop`. Write the average and the range beside each timing.
- **Watch every run while it runs** (every few seconds): walks print their lines; suites write
  `appdata/method/runs/<run>/console.txt`; a walk's own log is
  `appdata/playtest[_b]/FindingNaresh/live/walk.log`. Off plan: stop that lane at once with
  `tools/method/stop_lane.sh [b]` (verified exit), look at the picture, write one notes line.
- **No rerun-until-green**, no check weakened, no plant row removed. 2-3 failed fixes of one thing: a bench.
- Shut games down before long reasoning or edits.

## 0. Self-checks (no game)

```sh
python tools/method/t3_controls.py          # input identity, manifest traversal, final / proof gates, obs table
tools/method/live_session.sh import         # compile check of the game + test scripts (headless, ~0.2 min)
```

`t1fix_controls.py` is not a step here: its fixtures are T1's archived run folders, which are not in this
copy (T1's judges were qualified in T1's own copy).

## 1. Before discovery

```sh
python tools/method/make_ghat_manifest.py > appdata/manifest.json      # required checks (exits != 0 on an unparsed check / dynamic call)
# write the design-to-observation table: | # | behaviour | producer / input | observed by |
#   observed by = a manifest check id, or "picture: <what it shows>", or "video: <the moment>"; empty = GAP
python tools/method/t3_gate.py obstable <your table.md> appdata/manifest.json   # lists GAP / UNKNOWN rows
```

## 2. Discovery: the seven scenarios

```sh
ROLE=discovery SPEED=fast tools/method_run.sh ghat
#   fast part (lane a): ghat_heat, ghat_net, ghat_marks; 1x part (lane b): looks, places, jug, spring
#   one COMBINED RESULT; receipts in appdata/method/inv/<INV>/ (the INV is printed first)
# after a STALL / TEST / health stop: look at the picture + log, write one notes line, then the rest:
ROLE=discovery SPEED=fast GHAT=<remaining scenarios, comma separated> tools/method_run.sh ghat
python tools/method/combine_parts.py appdata/method/inv/<INV>     # re-judge one invocation from its receipts
```

## 3. The walk (discovery, repair, tail)

```sh
tools/play_walk.sh ghat --fresh            # the real walk from its only real entry (step 1)
tools/play_walk.sh ghat                    # after a fix: tries to resume at the failed step THROUGH THE GATE
#   "REFUSED (gate, before any input)" (exit 5, no game started) -> play the real prefix: --fresh
#   a resume only counts if the gate says SAME (layers 1+2 right after the restore, layer 3 at +3 game s)
LANE=b tools/play_walk.sh ghat --fresh     # the same in lane b
```

A repaired walk must reach its end through real producer paths before the recording.

## 4. Repair rounds

After each batch of fixes, all seven again (subsets stay diagnostic):

```sh
ROLE=repair SPEED=fast tools/method_run.sh ghat
```

## 5. Freeze, then the final clean suite

```sh
python tools/method/tree_id.py stamp appdata/frozen_tree.json     # game + test + tools + Godot binary
ROLE=final SPEED=fast tools/method_run.sh ghat                    # no FIXTURE, no GHAT, no EXPECT_IDS
python tools/method/t3_gate.py final appdata/method/inv/<final INV> appdata/frozen_tree.json
```

`final` accepts only: one invocation, all seven each once, k3, no fixture, ROLE=final, no restored point,
no early stop, the input tree unchanged during every part and equal to the frozen one, games verified gone,
fast only for heat / net / marks.

## 6. The plant matrix (same frozen tree)

```sh
SPEED=fast EARLY=1 python tools/method/prove_ghat.py <group> [<group> ...]   # groups: see GROUPS in prove_ghat.py
#   a multi-plant group needs each member proved alone too (the solo_* groups) before it is certified
python tools/method/t3_gate.py proof appdata/method/inv/<final INV> appdata/method/inv/prove_<group>_<time>_<pid> [...]
```

New holes: add the plant to `core/Plant.gd` and a group to `prove_ghat.py` (its own exact check ids), then the same.
The final suite and the plant runs never share a run: a planted run is never clean-suite evidence.

## 7. The recorded walk (1600x900, Movie Maker 25 fps, sound)

```sh
tools/record_walk.sh ghat --fresh          # -> appdata/videos/ghat.mp4 (+ ghat.parts/, framemap_rec25.json)
# a take that FAILED: fix, then
tools/record_walk.sh ghat                  # resumes through the gate; refused -> tools/record_walk.sh ghat --fresh
GATE_ONLY=1 tools/record_walk.sh ghat      # the second recorded resume receipt of a resumed point (2 needed)
python tools/method/join_check.py verify appdata/videos/ghat.parts appdata/videos/framemap_rec25.json
python tools/method/join_check.py join   appdata/videos/ghat.parts appdata/videos/ghat.mp4 appdata/videos/framemap_rec25.json
#   joins.txt: MM:SS.mmm -> step, part, gate; joins_frames/: the frame either side of each join (look at them)
python tools/method/join_check.py sound appdata/videos/ghat.mp4 <a quiet second> <the second a known sound starts>
```

Then watch the whole video with sound after the games have exited; note the time of every required moment,
every join and both views. Anything missing stays INCOMPLETE.

## 8. Two games at once (optional)

```sh
tools/method/lane_sentinel.sh              # 2 games: misroutes refused, quit A leaves B running (prints SENTINEL PASS)
LANE=b <any launcher>                      # lane b's folders: appdata/playtest_b, FindingNaresh/_shots_b, appdata/videos_b
tools/method/stop_lane.sh [b]              # stop one lane's game, verified; other lanes untouched
```

Never a recording + a fast proof + a 1x proof at the same time. Count overlap savings only from measured
lifetimes (union vs sum).
