# c2 audit and g1 decision — GPT auditor

2026-11-06. Stage 3. Read-only audit on g12 `9112ee7`; no game run,
code edit, branch change or commit. Evidence: the referee's scoring appended
to `trial_c1.md`, `trial_g1.md`, `trial_c2.md`; scoreboard R1–R14;
`audit_g1_claude.md`; and read-only source inspection, including c2
`04c3102:FindingNaresh/scripts/dev/C2Watch.gd`. Reported measurements below
are the referee's/builder's, not fresh measurements by this auditor.

## Verdict on c2

**Accept the recorded score within its scope; reject any claim that c2 is
qualified as a general game verifier.** It found six practice bugs reliably,
missed P6 twice, and returned a false pass when its own rule broke. The last
two are observed failures, not hypothetical objections.

| Score | Evidence and audit judgment |
|---|---|
| S1 10/10, limited spread | Accept under R12/R14: all seven rules looked in each counted run, no fires; played landing coverage 8/10. Lip speeds 65.9–67.0 do not prove the required 61–68 spread. Fixed `c2_more` repeats are coverage, not ten independent environmental challenges. |
| S2 6/7 reliable, P6 1/3 | Accept the explicit counts. Do not round P6's one catch into reliable coverage. G3 checks the lowest part only, once per parked spell; it has no upper displacement test. The rotating off-axis hub floated +0.19 to +0.29 m without firing. |
| S3 via c1 3/3; own case 0/1 | Accept. Renaming `_swim_to` produced 733 errors, G2 NOT REACHED, exit 0. Source explains it: the typed bank lookup precedes `_look`, and the wrapper does not veto script errors. This is broken observation, not an absent gameplay trigger. |
| S4 listed cases pass | Accept 2/2 local and 4/4 via c1 as provenance, not six independent local controls. The 440 s live-engine await stall is a separate demonstrated hole. Passing listed cases does not establish the brief's broader no-silent-wait promise. |
| S5 pass | Accept the narrow claim: declared door/swimmer/F1 setups, input walk/miss/reset, read-only state checks. R13 verifies shared `snap_wheel`/HUD paths, not the landing-only code or reaching those states by play. |
| S6 | Reported 33 min build, 161–199 s full run, ~55 s short run, zero online model calls. The referee spent ~80 min on 24 runs. Per-tick observer overhead remains unmeasured. |

Excluding the ~440 s stalled S1 attempt is reasonable for counting c2's
state-rule false alarms, provided the excluded attempt stays visible as a
health failure and contributes to actual cost. S1_6's ~75 s interruption
also stays visible. Neither is evidence of a healthy unattended method.

## Try to break it

These secret-bug cases are hypothetical attacks (I think), not claims to know
the referee's secret set. No secret material was sought.

| Attack | Failure and evidence for the risk |
|---|---|
| Rename/remove any private dependency | False pass already demonstrated for G2. `_wheel_meshes`, `_bare_hub`, `_warn`, `_window` create similar dependencies. A missing ray hit can also leave G3 without a look. An observation error must be TEST/INVALID, never neutral NOT REACHED. |
| Break the state and its supposed witness together | G4 uses mesh visibility/loose-wheel proximity as physical truth. A collision wheel attached while the mesh is hidden can satisfy its picture of “gone.” G1 trusts the parking-brake flag: flag true with no effective brake leaves ownership unresolved. State agreement is not independent physical proof. |
| Keep an object above ground but off its axle | Observed P6 miss. Simply adding “too high” needs new clean measurements on slopes, suspension travel and all wheel orientations. An axle-relative rendered attachment check is a proposed replacement, not a qualified fix. |
| Make a blocked route outside the fixed crate box | D1 excludes rigid bodies and terrain and examines one box. Carryables/terrain can block play without firing; rubble near that box can fire without blocking a different valid placement. It proves its volume, not the leg-up route. |
| Change swimming destinations or river layout | G2 needed three revisions on this puzzle. A wrong bank target shared by movement and checker can make both agree. A valid longer bank climb can false-alarm on a different river. “Generic” is the form of the rule, not evidence of transfer. |
| Break the actual landing path only | F1-built G3/G4 states remain clean. R13 correctly refuses credit for bugs outside the shared path; eight played landings do not cover the two missed ones. |
| Stall screenshot/step while physics runs | Observed 440 s. More heartbeat/log lines do not prove step progress. Repeated errors can even make a broken run look busy. Every awaited operation needs an external wall deadline. |
| Move to another puzzle | Ramp group, hut window, wheel messages and river-bank fields do not exist there. Silent early returns could produce an empty green report; porting all seven rules would effectively write another puzzle-specific oracle. |

What would count as generalisation: freeze the generic rules and thresholds
before the unseen puzzle/secret bugs; declare dependencies and legitimate
triggers; record per-rule evaluated/error/not-reached counts; exercise varied
clean states and validated broken states the rules were not written from.
Score catches AND correct naming, false alarms, unresolveds, coverage and cost.
Report hours/lines of adaptation and all threshold changes. R7 inspections and
played-path claims stay separate. Require rule-error and live-step-stall
negative controls. Passing that exam would support the tested scope only;
seven practice descriptions known before writing seven rules cannot do so.

## g1: change — retire the driver, keep the evidence discipline

The independent outcome checker was the useful idea. Its fixed keyboard-pulse
driver and exact freeze invariant failed qualification. Do not repair/requalify
g1 inside g2 or inherit its green claims under R1.

- **Freeze: drop the retained-contact exact-transform rule.** Measured wheel
  settling was 1.5–3.1 mm at +1/+6 ticks, with chassis movement <1 cm; exact
  equality was my unsupported requirement. I retract it. I am not replacing it
  with a convenient 4 mm allowance: two freezes do not establish that bound.
  g2 observes moving launch/contact events and reset drift, and claims no
  two-second supported parked stop. Frozen wheel contacts were reported in
  1,464/1,464 wheel-ticks; that corrects the earlier “no contact” assumption,
  but does not by itself prove their continued physical validity.
- **Driver line: remove g1 from the reach path.** Two of seven retries were
  at x -1.98/-2.17 m, 59.0/58.5 km/h, left wheels off the 5.6 m ramp. That is
  evidence the test drove an unsafe line; it does not identify why the line
  differed. g2 uses today's AutoDriver as the experimental subject, not as a
  qualified replacement. It reports every bad approach instead of selecting
  only successful landings or adding a centreline repair.
- **What survives in g2:** requests/raw/device/force/contact records with tick
  identity, a checker independent of driver “done,” explicit physical outcomes,
  script-error veto, declared setup boundaries, non-pass on missing evidence.
  These are design requirements reimplemented and qualified for g2, not a
  wholesale import of unqualified G1Check/G1Drive code. Signed road progress
  remains useful for a future departure test, outside g2's claim.
- **Claude's strongest objection accepted:** unchanged controller does not
  exclude added sweep cost changing frame pacing. v3/v4 counts and 51–103 ticks
  without process frames are correlation, not mechanism. g2's dispatch-phase
  pair tests a narrow related hypothesis; it cannot retroactively prove that
  the sweep caused g1's misses. No extra sweep-on/off trial is smuggled in.
- The no-progress boundary is settled conceptually as the first sampled tick
  strictly after 10 s, with detection lag reported (v3: 10.03 s). It was never
  qualified in v4 B; g2 does not inherit a qualified departure deadline.

## Concessions, objections and lessons

1. **c1 reuse accepted under R8.** Its exact-head 10 clean runs and seven
   controls met my earlier conditions. That does not erase the failed kill,
   receipt blind spots, runtime-error hole or new live-step stall. Reuse
   requires these limits to travel, as R8 says.
2. **R12 accepted, with an operational distinction.** NOT REACHED is legitimate
   only after a healthy observer evaluated the trigger and found it absent.
   A failed lookup is ERROR; an expected checkpoint absent at a deadline is
   INCOMPLETE. The c2 refactor experiment proves why the distinction matters.
3. **R13/R14 accepted as scoped rulings.** Shared-path setup catches count;
   artificial reach and missing speed spread remain limitations. R14 cannot
   excuse a new driver method from measuring its own achieved spread.
4. **P3 naming dispute settled, causal dispute not settled.** G2 named stale
   swimming; G1 said brake ON/cause not named. Correct restraint. Neither the
   0.58 m drift nor simultaneous G2 establishes swimmer-to-van force transfer.
5. **Same rounded speed/offset does not establish identical launch state.**
   Today's 66.4/66.5 misses have larger recorded peak pitch/roll and later
   result times than most landings. Those maxima include the outcome and may
   be effects of a miss. Speed is a magnitude; heading, vertical velocity,
   wheel support history and angular motion remain unmeasured causes.
6. **My mistakes, recorded here under the two-file restriction:** assumed
   exact freeze transforms and a fixed controller would be stable -> mm
   settling and 2/7 off-ramp retries -> drop the rule/driver -> measure the
   consumed input and physical launch, never make exact equality a physics
   requirement without evidence. Referee may copy this lesson into project
   rough notes; this auditor is authorised to write only these deliverables.

Referee decision requested: apply the ERROR/NOT REACHED distinction explicitly
in final-method acceptance, and add the demonstrated live-engine step stall to
its required health controls. This requests no retrospective score rewrite.
