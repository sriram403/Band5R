# c1 audit — GPT auditor, Stage 3

2026-11-05. Read-only audit of head `a6a412f`, including `57b8afd`.
No game or tests run. Referee scoring on this head is pending; this is not its score.
References below use current working-tree line numbers. `P` =
`FindingNaresh/scripts/dev/PlayTest.gd`; `B` = its sibling `RigBeat.gd`;
`I` = its sibling `RigInject.gd`; `W` = `tools/rig/rig_watch.py`.

## Verdict

**Useful health observer; not yet qualified for unrestricted reuse.** The saved
controls support seven catches on the earlier implementation, not seven controls
plus a clean ramp on this head. Three clean ramps raised receipt false alarms;
the process-frame change remains unverified in the builder's report
(`trial_c1.md:90-105`; saved `appdata/playtest/runs/q1_watch.txt:23-29`,
`q2_watch.txt:21-31`, `q3_watch.txt:22-29`). The referee's new numbers must decide S1.

The outside heartbeat, explicit-plan accounting and separate health/game verdicts
are worth keeping (B:94-114; W:193-229). A healthy heartbeat is not proof that an
actor moved. c1 correctly claims no game proof (`trial_c1.md:83-85`).

## Separation from injections

| Check | Evidence | Finding |
|---|---|---|
| Injection switches | I:27-44 parses `--inject`; P:78-81 creates the injector; P:546-547 arms it; P:566-584 lets it alter plan/needs. `tools/rig_run.sh:16-18` passes normal launch arguments to the runner. W:72-181 reads effects/events, not injector IDs. | No verdict branch reads an injection ID. PlayTest necessarily calls injection code, but its checking branches do not choose verdicts from IDs. |
| T1 | I:87-88 calls the ordinary pad-disconnect handler. B:107-110 reports device kind; W:111-115,154-158 diagnoses the transition. | A real device transition can be seen. Its cause is not established by that transition. |
| T2 | I:62-68 appends a bad expression to the declared needs. P:583-596 executes that list before play. | A genuine invalid declared expression is caught the same way. This does not prove detection of a bad inline lookup or a valid expression reading the wrong thing. |
| T3 | I:48-52 changes execution order; P:573-575 rejects work after save. | Real plan validation, not an injection-label shortcut. It catches the hazardous plan before the reload, not completion accounting across the reload. |
| N1/N2/N3 | I:89-96 blocks the thread, pauses, or removes P2. B:100-114 and W:147-163 inspect clocks/presence. | Real effects, not a private planted marker. Removing P2 tests scene presence, not an inert or wrong P2 body still in the tree. |
| N4 | I:53-57 removes a scenario from the order; P:576-581 detects the mismatch. | Valid catch of an omitted plan entry. Does not by itself qualify a scenario which starts and returns early without doing its required work. |

Saved logs support the reported event types: q4:8-12 (T2), q5:13-16 (N2),
q6:14-17 (T1), q8:9-12 (T3), q10:8-16 (N4), q11:12-15 (N3),
q12:12-16 (N1), under `appdata/playtest/runs/`. Reported detection delays are
in `trial_c1.md:93-101`. These files are saved evidence, not fresh measurements
or proof of their commit provenance. q9's healthy control did not exercise the
problematic ramp receipt path (`trial_c1.md:15-17,99`).

## Input receipts: too strong a diagnosis, too weak a guarantee

1. **False alarm by design when the wrong layer owns blame.** B:178-191 calls
   a wrong device binding or `d.move()` returning zero an input loss. W:145-146
   always labels that TEST. A game regression in device assignment or `move()`
   produces the same evidence. Raw input arrived but the game's reader broke
   is not measured proof of a test problem. Separate transport rejection,
   binding mismatch and game-reader mismatch; unresolved ownership must remain
   unresolved. This follows the agreed distinction in `top4.md:8,41-43`.
2. **False passes for keys/buttons.** B:169-171 returns success when a requested
   key is absent. B:193-195 does the same for an absent pad button. A fully
   dropped press is indistinguishable here from a quick tap. Keyboard success
   only needs some active keyboard device (B:172-175), not the intended actor.
   B:164-165 also returns success when device prerequisites are missing.
3. **Supersession hides unobserved input.** B:126-129 excludes releases;
   B:140-145 skips requests after scenario end or a changed latest value.
   These exclusions prevent known false alarms, but do not prove delivery of
   short pulses. Nor does an axis length prove its correct direction:
   B:190-191 tests movement magnitude only. It also skips that check for an
   inactive device. A zero/blocked intended input is not universally caught.
4. **The two-frame change is a plausible scheduling fix, not yet a measured
   fix.** B:128-140 now waits for two process frames as well as physics frames.
   That changes the clock domain; it is more specific than adding seconds to a
   timeout. But the flush ordering in B:136-138 is an assertion, not a trace.
   The report calls it a hypothesis (`trial_c1.md:92,105`). Waiting longer can
   also increase supersession and therefore skip more receipts.

What would prove it: a clean ramp on this exact head, with frame-stamped
request, raw read, device read and receipt disposition around `shot()`; then a
held-input negative control that omits delivery but preserves the request.
Require the latter to fail, not be skipped. Include a short tap/pulse with its
actual receipt status reported as observed or unobserved. Ten clean scoring
runs test false alarms; they alone do not test lost-input sensitivity. I think
these are the smallest discriminating experiments. The auditor has not run them.

## Other attempts to break it

| Risk | Evidence and consequence | Score relevance |
|---|---|---|
| Intentional pause | W:154-158 has no allowed-pause contract. P:242-248 only guards `RIG_NEEDS` scenarios. | False alarms for pause-menu scenarios. Not a failure of a ramp-only claim; blocks general reuse. |
| Wrong pad blame | W:155 tests `wf_at - drop_at < 3` without a lower bound and labels every matching transition TEST. No source of disconnect is recorded. | T1's controlled test disconnect can earn S3. A game-caused reassignment cannot be excluded. A later transition can also satisfy the one-sided comparison. |
| Unmeasured stale bound | W:28,150-151 uses 20 s; `trial_c1.md:110` admits reload time unmeasured. | N1 during an established run has saved support. Clean reload false-alarm risk remains. Measure before claiming save/reload support. |
| Startup/reload blind window | W:31,134-149 permits 300 s without a first/new-process beat. | A freeze before the first beat or between segments can exceed S4's 60 s. Report this scope; late N1 does not qualify it. |
| World clock stopped without pause | W:152-158 checks engine frames, or world frames only when paused. | If world callbacks stop but engine frames continue, no world-stall verdict follows. c1's “alive” claim is narrower than all gameplay progressing. |
| Runtime script errors | W:139-165 never reads script errors; P:548-550 emits end after the call returns. W:195 counts membership in end IDs. | A scenario aborting its work yet returning can appear complete. A declared T2 catch does not qualify runtime errors. Material to S3/T2 scope and to S4 false-pass risk. |
| Empty/preset manifests | W:53-64 ignores the planner subprocess return code; W:194 falls back to only the first game plan when asked is unknown. W:206-207 calls an empty want list healthy. | Preset omissions share their source with execution; planner failure can produce empty accounting. Use explicit nonempty IDs for scored g1. General completion claim is unsafe. |
| End is not work | W:195-196 does not require ordered start/end pairs or step obligations. | N4's plan removal earns only that control. g1 must independently prove each phase, even if a scenario reports end. |
| Exit status | W:218-229 can print INNER FAIL yet exit 0 when rig healthy; `tools/rig_run.sh:19-21` propagates it. | Deliberate c1 separation, documented in `trial_c1.md:47`. Consumers treating exit 0 as game PASS create a false pass. |
| Delayed final report / failed kill | W:67-69 ignores taskkill result; W:179 waits up to 40 s after STOP; `tools/rig_run.sh:20` waits for runner exit. | STOP is prompt, but final handback can lag; an unsuccessful kill can leave the wrapper waiting. Separate notice time from shutdown time in S6. |

Build plus qualification cost is **reported 23 minutes**, not independently
clocked here (`trial_c1.md:54-61`). No model is in W's loop. Heartbeat I/O and
watcher overhead are unmeasured (`trial_c1.md:116,126`). Five-second progress
lines show clocks and the last step, not body motion (W:170-176). A human watched
run still needs movement evidence.

## Reuse ruling requested, not a new score

R1 permits only parts that passed their negative controls
(`scoreboard.md:111-114`). My recommendation:

- Require the referee's exact-head S3/S4 evidence and a clean receipt-exercising
  ramp before adopting the full layer. Re-run the affected input negative
  control after the process-frame change. Do not inherit old green scores.
- Freeze the accepted commit and enumerate adopted parts. Restrict g1 to explicit
  IDs, no save/reload, no intentional pauses. Mark qualified S3/S4 **via c1**.
- Do not treat keyboard receipts as intended-actor proof. g1 needs its own
  input/device record and outcome checks. Raw/device disagreement is unresolved
  unless the broken transport is measured. No invisible upgrade of c1's claims.
- If current scoring does not qualify the needed parts, stop g1 at the dependency
  boundary and report partial/unqualified. Do not rebuild c1 inside g1's hour.

I think this preserves useful shared work without hiding the failure that c1's
own report already acknowledges. No files outside this audit and the requested
g1 spec were changed.
