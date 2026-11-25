# GPT as the TESTER, trial 1: result (the referee, 2026-11-25 04:03 PM)

Job: re-test the merged step-9 fix (same job as the Claude tester, smaller: 2 bench points not 5), blind to Claude's
report. GPT Astra 6.2 high on the work account, branch `gpttest`. Report: `gpt_tester_trial_report.md` (`8f0ee03`).
Referee's live notes: `extras/referee/gpt_trial1_referee.md`.

| | GPT Astra 6.2 | Claude Opus 5.5 (tester, earlier today) |
|---|---|---|
| Ran the game itself | yes (first game 1.5 min after launch) | yes |
| Watched its runs | yes (`*.watch` files, 3 s line counts, flagged >60 s gaps) | yes |
| Bench hang point | 68.6 s (= the builder's, deterministic) | (hang point 2) 68.3 s |
| Bench good point | 44.0 s, matched its own walk | 44.0 s |
| Expected outcomes | built from each run's OWN earlier walk: all hit | a general 57-72 s range: missed twice (honest results) |
| Planted bug | caught, 0.16 m (early stop after the FAIL) | caught, 0.16 m (ran on: 3 follow-on fails) |
| Clean checks | 18 / 18 | 18 / 18 |
| Recorded walk | 20 / 20, step 9 61 s | 20 / 20, step 9 68 s |
| Video judged | yes: 4 frames, Problem at the windscreen 2:40, gone 2:46, the forward-only camera named | yes: the same limit named |
| Surprises caught | H2 at restore; Godot cleanup errors / leaks at exit (NEW, nobody else noted); >60 s quiet gaps | H2 at restore; waypoint flips; steps 17 / 18 unchecked (fixed since); 1.8 s focus |
| Verdict | PASS WITH RESERVATIONS | PASS WITH RESERVATIONS |
| Game min | 17.9 (smaller job) | ~19 (5 bench points) |
| Wall time | ~22 min (03:40 -> 04:02) | ~40 min |

**Referee's verdict on the trial: GPT passed as a script-driven tester.** Every number right, watched every run, honest
gaps, one new finding (exit-time cleanup errors). Its expectations were better built than Claude's. Not tested yet: GPT
PLAYING live (look, act, judge as it happens) and catching a bug it isn't told about: trial 2
(`live_point_build_task.md`: a Claude builder adds live play from a saved moment with a sealed plant first).

Open from trial 1: the exit-time Godot cleanup errors / leaks (GPT: "seven self-list errors after the clean scenario
end"): check whether they're new or old, and whether they hide anything.
