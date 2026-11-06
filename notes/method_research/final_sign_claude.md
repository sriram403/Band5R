# Claude's signature on FINAL.md (2026-11-06, head `79f41da`, method `g14-final` `ceb63e3`)

**SIGN WITH RESERVATIONS.**

**Why sign:** the run now tells the truth about itself. A broken test says TEST (26 s), a stuck step says STALLED (5.5 s, process gone), missing work says INCOMPLETE, and nothing is proven by teleporting (60 setup lines declared). Today's v5 passed 7 / 11 on a working game and hung ~440 s on a minimized window; this one gave 0 false FAILs from the jump in 10 runs, never hung, and costs ~165 s with no model in the loop.

**Why the reservations:**
- **It misses more than it catches: 3 / 7 secret bugs.** All 4 misses are the same gap: nothing checks *where* a thing sits (X5), that a fix *works* (X1 wheel, X2 van pulls left), or that a promised mistake *happens* (X7 boil). A false pass is the worse error by the scoreboard's own rule, so "PASS" today means "the checked parts held", not "the ramp works".
- **S1 doesn't meet its written bar** (10 / 10, "one failure = fail"): 9 PASS + 1 INCOMPLETE, plus one clean-game FAIL from the hut walk. The method labels these honestly, but they're still flakes the user has to read.
- **Untested beyond the ramp** (S7 skipped), so the "~1 hour" port is a guess.

**Wrong or overstated in FINAL.md (exact fixes):**
1. S1 row: add "**below the 10 / 10 bar**; counting the exam's clean hut-walk run, 9 PASS of 11 clean runs, 1 INCOMPLETE, 1 FAIL".
2. "flake about 1 run in 5" -> "drive-off 3 / 20 clean landings (~1 in 7), plus one hut-walk FAIL": give counts, not a rounded rate.
3. `scoreboard.md` Final row says "**Signed method**" before anyone signed -> "Frozen and examined; signatures in `FINAL.md`".
4. Under "What it can't do", first bullet: add "so a PASS doesn't mean the ramp works; it means the checked parts held".

**The one thing to do next:** write the four missing checks from the starter checklist (rewards on the bench, wheel turns, van drives straight, a leak boils and stops the van), then plant X1, X2, X5, X7 again and confirm each now FAILs by name (~4 runs, ~12 min). The bugs are no longer secret, so this is practice, not a new exam.
