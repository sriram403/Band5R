# Speed-research referee: independent compliance audit

Scope: supplied transcript cut, 2026-11-10 evening to 2026-11-11 10:47; main evidence frozen at `55a5fa1`. Read-only audit, with this report as its sole output. No game runs, code changes, secret-folder access, or game-fault details in this report.

Method: project-memory §6. FOLLOWED requires positive evidence; BROKEN requires a demonstrated contradiction; N.A. means the trigger did not occur within this interval; NOT SHOWN means the allowed evidence cannot settle it. A rule written into a child task establishes briefing, not execution. Related rules have separate rows for traceability, not separate additive costs.

**Counts: 120 rules — FOLLOWED 37; BROKEN 22; N.A. 28; NOT SHOWN 33.** These are compliance checks, not 120 independent incidents or additive losses.

Evidence keys:

- **T**: `notes/audits/evidence_speed_referee/transcript_cut.md`, physical line numbers (including blank lines).
- **B / S / Q**: `notes/SPEED_RESEARCH.md`, `notes/speed_research/scoreboard.md`, `notes/speed_research/top4.md`, all via `git show 55a5fa1:<path>`.
- **C / G / H**: `trial_T1_task.md`, `trial_T34_spec_task.md`, `trial_T34_build_task.md`, same frozen directory/revision.
- **P3 / P4**: `trial_T3_spec.md`, `trial_T4_spec.md`, same revision; **A2G / A2C**: the round-2 GPT/Claude audits there.
- **J**: permitted main commit log `40e1f16..55a5fa1`; **D**: permitted trial-copy `log --stat -3`.
- **Rules**: project `CLAUDE.md`, the explicitly allowed work-account rules, library `AGENTS.md`, and the five named skills. Skills are the supplied current texts; the transcript shows shorter files at the time. Historical wording not independently available is not reconstructed.

The first USER block is entirely `[REDACTED by the referee: secret benchmark material]` (T1–3). Therefore the original task list cannot be recovered or scored item by item. B and Q are useful evidence of recorded scope, but cannot substitute for the user's missing words. Several tool arguments/results are also truncated; conclusions below do not treat invisible suffixes as evidence.

The expressly requested D command returned an entry dated after the cut. That entry is excluded from all verdicts. The pre-cut `45dc00f` WIP receipt and transcript are sufficient for the interrupted work finding. No later working-tree file was read.

## Highest costs

1. **Unreviewed specs sent to implementation; disputed acceptance weakened (R01, R04, R05, R06).** P3/P4 comprise 251 lines and were committed and handed to a builder without a separate opposing audit. T759 estimates the builder at **3–4 hours**, which is time at risk, not proven waste: the first builder reported no completed work. R5 also risks losing the independent clean-walk safeguard, and therefore invalidating the research conclusion. The referee itself prices that disputed walk at **about 10 game minutes** (T548). These costs overlap; do not add them.
2. **Concurrency changed into an untested account-limit rule (R10, R11).** Both Claude jobs failed with account-limit messages (T597–615); about **290 lines** remained uncommitted until rescue (T739). Interruption around 22:30 to the 10:39 recovery is approximately **12 h 9 min elapsed**, not 12 h 9 min proven avoidable waste: the limit's reset was reported as 00:10, and user/session availability is unknown. The demonstrated avoidable risk is work without checkpoints and resumption overhead. Claiming serialization prevents recurrence is unsupported; the lost overlap is unmeasured.
3. **Process metering presented as live correctness supervision (R08, R09).** START/END notices and five-minute budget events cannot establish step progress, motion, errors or correct completion. **0.7 game minutes** were reported used at restart (T746); their correctness supervision is not established. Up to **45 qualification minutes** on T1 and **30** on the builder were exposed by the launch plan, not observed wasted. Do not sum these caps into actual loss.

Other definite process loss: delayed mistake recording, stale handoff state, and an alarm-only cap policy. Their exact extra minutes cannot be measured from this cut.

## Rule table

### Two-model research: every §0 trigger and the operative stage/role requirements

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| R01 | §0 stage start: fresh child with brief, findings and objections | BROKEN | Fresh launches exist, but H lists specs and rulings, not a completed opposing spec audit; T488–520 goes directly from referee reading to builder launch. Fix F01. | 3–4 builder hours at risk, not spent. |
| R02 | §0 method request: brief file before children | FOLLOWED | B exists at frozen revision; tasks committed in `b5abab7` before T292/T298. | — |
| R03 | §0 GPT role: specs only, Claude implements/runs | FOLLOWED | G explicitly forbids code/runs; T429–434 reports only two files; T440–454 checks footprint; H assigns Claude. | — |
| R04 | §1 stage 3: other auditor audits each result before it counts | BROKEN | T1 task is already being built at T292 while GPT's objections arrive at T434 and are relayed only in the next-morning RESUME; P3/P4 go straight to builder at T520. No separate opposing review task exists in the supplied launch sequence. This is a missing gate, not a claim that an unfinished trial was awarded PASS. Fix F01. | Same exposure as R01. |
| R05 | §1 stage 2: agreement must retain each auditor's conditions | BROKEN | A2G says its four-group plan does not assert Claude signed the amendments, and requires a separate clean-walk receipt. Q describes both as signing the same plan; R5 uses that summary to remove the condition. Fix F02. | Acceptance invalidation risk; ~10 game min omitted safeguard. |
| R06 | §2 strict audits: measured support for claims; reasoned disagreement | BROKEN | R5 infers that passing a finite equality gate establishes a clean whole walk; A2G/P4 explicitly distinguish those claims. User's recorded choice in Q authorizes joined video, not that inference. Fix F02. | Same acceptance risk as R05. |
| R07 | §0 result arrives: score then send result and why to other auditor | NOT SHOWN | No completed qualification result arrives in this cut. Prior pilot numbers are in S, but their opposing result audits are not supplied here. | Unknown; do not count prior trials as independently accepted. |
| R08 | §4/referee role: watch step, movement, errors during every run | BROKEN | T283/T514/T708 Monitor filters inspect START/END/WALL only. T574 says “Nothing is off plan” based on launch length; no step/error/health observation supports it. Children are told to watch, but that is not referee observation. Fix F03. | 0.7 min observed usage; 45/30 min planned exposure. |
| R09 | §4: cost known before each run, rather than aggregate cap only | NOT SHOWN | C/H require per-run cost; T417/T549 announce total budgets. Child launch-by-launch notes are not in the permitted evidence. | Unknown game minutes; an instruction is not execution proof. |
| R10 | §4: stop/report loops; diagnose cause before changing method | BROKEN | T723/T745 turns simultaneous account-limit failures into “one Claude child at a time” as remedy, without evidence distinguishing shared quota exhaustion from concurrency limits. Fix F04. | Unmeasured overlap lost; recovery overhead; overnight gap not wholly attributable. |
| R11 | §4: local checkpoints keep trial work recoverable | BROKEN | T678 rescues WIP after failure; T739 says ~290 lines had never been committed. H already says “Commit as you go”; C originally says commit at the end. Fix F05. | ~290 lines at risk; no demonstrated code loss. |
| R12 | §0 scoreboard change: referee only, logged reason | FOLLOWED | S records R3 qualification phase, R4 inventory correction and R5 interpretation with reasons; J `b5abab7`, `6ad7002`. This does not make R5's reasoning valid. | — |
| R13 | §0 cap hit: fail trial and report progress | N.A. | No trial reaches its measured cap in this interval. API quota failure is not a measured trial cap. | — |
| R14 | §3 caps should be unambiguous and enforced | BROKEN | C/S call T1 budget <=45 but hard stop 60; T283 only emits alarms, not cancellation. B says ~2 h wall cap; no corresponding enforcement is shown. Fix F06. | Up to 15 extra game min permitted beyond stated T1 budget; not observed spent. |
| R15 | §0 failed agreement after three rounds: stop/escalate | N.A. | Two round-2 audit files are cited; no third-round deadlock in the cut. | — |
| R16 | §1 blind ideas, seven each, costs/failure modes | NOT SHOWN | S records stage 1 done; no stage-1 launch/execution in cut, and authors' blindness cannot be established from status alone. | — |
| R17 | §1 stage-3 trials alternate rather than silently combine outcomes | NOT SHOWN | Q explicitly bundles four groups; B still says each full trial replays separately. Here only qualification builds start; no scored replay shows which policy is executed. | Attribution of savings remains unresolved. |
| R18 | §1 final exam and each auditor's own signature | N.A. | T762 explicitly places signatures in future work. | — |
| R19 | §1 final user report: numbers, limits, rejected alternatives, adoption A/B | N.A. | Research not finished; T754 is an ETA, not final adoption report. | — |
| R20 | §2 referee neutral: does not invent competing trial ideas | FOLLOWED | Visible work is briefs, measurement, rulings and delegation; P3/P4 authored by GPT. | — |
| R21 | §3 secret set outside child access; each item demonstrated before counting | NOT SHOWN | T422 says designed, not yet run; no score awarded. Physical isolation cannot be proved by “do not read” alone or a redacted command. | Blindness/proof pending. |
| R22 | §5 leak recovery: inspect outgoing files, fresh tasks, insurance items | FOLLOWED | T166–173 reports grep clean; S R1b records fresh-thread policy; task heads repeat exclusions; T422 keeps insurance pending rather than scored. This establishes process record, not secret contents. | — |
| R23 | §5 every task starts with full allow/deny lists, read task first | FOLLOWED | C/G/H contain explicit lists; T292/T298/T520/T714 instruct reading that file FIRST. | — |
| R24 | §2 every round a fresh task, no old-child follow-up | FOLLOWED | New delegate calls at T292, T298, T520, T714; no referee follow-up call to an old child appears. Provider-generated continuation failure at T611 is not evidence of such a call. | — |
| R25 | §4 separate copies/branches, local-only results | FOLLOWED | T254–262 creates separate D: copy/branch; C/H restrict commits; J contains local notes; T554/T748 explicitly no push. | — |
| R26 | §4 one game per copy | BROKEN | C permits two games and only scopes guard to the copy; G/P3 proposes two lanes in a copy. Skill §4 says one run per copy. User's two-game seed does not explicitly waive per-copy isolation. No actual double run proved. Fix F07. | Planned evidence-collision risk; no measured loss. |
| R27 | §4 never alter product to suit qualification | NOT SHOWN | C/H prohibit gameplay changes; T669–675 shows test/tool diff paths only, but permitted stat evidence cannot prove behavioural noninterference. | — |
| R28 | §4 stage-end user communication | FOLLOWED | T414–425, T541–554 and T735–748 give progress, budgets and next actions. | — |

### Project-memory: every §0 trigger and the applicable handoff obligations

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| M01 | Thread starts: handoff/TODO, mistake log, git status | NOT SHOWN | T9 reads status/TODO; T70–86 reads mistake-log tail. MASTER_PROMPT/handoff read is not visible. | Unknown context gap. |
| M02 | Assumption disproved: mistake log now, before fix | BROKEN | Meter mismatch identified at T175, edited at T178–183, but logged only T400–406. Rate failure recovered/relaunched T653–717 before lesson T723. Fix F08. | Recording delay and repeat risk; minutes unmeasurable. |
| M03 | Similar job: read relevant mistake entries first | FOLLOWED | T70–86 reads last entries before trial-task writing T239; T166 explicitly references prior leak lesson. | — |
| M04 | Each sub-step: update TODO/LIVE STATUS | BROKEN | TODO updated in `b5abab7`, `fde3844`, `55a5fa1`, but S still says both builders “running” after `55a5fa1` says first builder deferred; J never updates MASTER_PROMPT in interval. Fix F09. | Next thread may act on contradictory state; exact minutes unknown. |
| M05 | User says update notes/note this: every touched note | NOT SHOWN | Initial user block redacted; no visible such instruction later. J proves some notes updated, not original checklist completion. | — |
| M06 | Milestone ends: fresh audit and per-part time report | N.A. | Qualification remains WIP. Not a completed milestone at cut. | — |
| M07 | Compaction/long thread: notes then new-thread step | NOT SHOWN | Overnight process restart exists; compaction/context-length trigger is not shown. | — |
| M08 | General lesson: mark general, ask before library promotion | N.A. | J records project notes only; no skill-library edits appear. | — |
| M09 | §1 nothing important only in chat | BROKEN | T745 changes builder order to depend on T1; TODO records it, but H still directs parallel development and a later merge, S still shows running. Operational handoff disagrees with chat. Fix F09. | Repeated setup/merge work at risk; unmeasured. |
| M10 | §3 say folder and branch holding each result | FOLLOWED | C/G/H name full folders and branches; T419/T549/T742 link active copies/tasks. | — |
| M11 | §3 commit small and often | FOLLOWED | J has six notes commits; WIP rescue at T678 is explicitly marked unqualified. Child checkpoint failure separately R11. | — |
| M12 | §3 handoff says done, untested, next | FOLLOWED | T735–748 names saved unrun work, deferred builder, next task and used budget. | — |
| M13 | §4 autonomous next-thread launch at milestone | N.A. | No completed milestone in cut. Do not penalize unfinished research for not switching threads. | — |
| M14 | §5 library edits generalized/versioned/logged only with authority | N.A. | No library change in allowed J; this audit does not inspect its history. | — |
| M15 | §6 fresh compliance audit at each milestone | N.A. | This cut precedes milestone completion; present audit is requested separately. | — |

### First-principles solving: every §0 trigger and operative procedure

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| F01 | New problem: state scarce resource and outcome | FOLLOWED | B defines 225 baseline game minutes, <=75 goal with coverage intact; R2 moves score to user's waiting time. | — |
| F02 | Accepting a limit: smallest experiment first | BROKEN | T745's serialization remedy follows account-limit messages, without a quota/concurrency measurement; earlier two-child launch itself was a concurrency experiment and is not a violation just because it failed. Fix F04. | Unmeasured loss of parallel progress; cap recurrence risk. |
| F03 | Every number/plan/pick needs situation-specific reason | BROKEN | T759 says “GPT's specs are big”; T766 says “a lot of strict checks.” No work-item estimate or minimum build experiment supports 3–4 h/9–13 h forecast. It is labelled a guess, so not fabricated measurement. Fix F10. | User planning exposed to 9–13 h forecast uncertainty. |
| F04 | Method loops: stop, count cost, change and tell user | NOT SHOWN | No three unsuccessful repair iterations are visible. C/H/P3/P4 specify stop rules; no execution proof. | — |
| F05 | Two/three failed fixes: test bench | N.A. | No such repeated fix sequence in permitted interval. | — |
| F06 | Assumption meets reality: immediate mistake entry | BROKEN | Same chronological contradictions as M02. Fix F08. | Same cost; not additive. |
| F07 | Rule only in memory: encode default/check | BROKEN | Budget monitoring only announces alarms (T283/T514); spec review exists as prose but is bypassed; rate-limit lesson is a note, not admission/checkpoint enforcement. Fix F01/F05/F06. | Same exposures as R01/R11/R14. |
| F08 | §1 algorithm: question/delete/simplify before optimization/automation | NOT SHOWN | P3/P4 specify a large tool set, but no explicit smallest sufficient implementation/deletion pass precedes H. T771 offers trimming only after user asks timing. Absence is not proof every tool is unnecessary. | Build-cost justification missing. |
| F09 | §1 measured facts before opinions, unexplained != pass | BROKEN | T574/T584 assert runs on plan from lifetime notices; T745 assigns quota failure to concurrency without discriminating evidence. Fix F03/F04. | Same risks as R08/R10. |
| F10 | §1 goal fixed, plan revisable | FOLLOWED | R2 changes metric; T745 revises order; T773 continues while user may steer. Whether each revision is justified is scored separately. | — |
| F11 | §2 version ideas, retain path and reasons | FOLLOWED | S retains P1/P1b/P1c, R1–R5; Q retains group ownership/budgets; P3/P4 labelled proposed. | — |
| F12 | §2 keep scope decisions in files with reasons/owner | FOLLOWED | S records R3–R5 dated referee decisions and reasons. No need to demand a filename when S serves that purpose. | — |
| F13 | §2 check with user while work continues | FOLLOWED | T421 and T745 “my pick”; T773 proceeds with A unless steered. | — |
| F14 | §1 only final result counts; no metric-only success | FOLLOWED | P3/P4 say proposed/unmeasured; T739 calls WIP never run; no final success claim in cut. | — |
| F15 | §4 read mistake log and preserve four-part lessons | FOLLOWED | T70–86 read; T403/T723 show assumed/reality/fix/habit lesson wording. Timing failure scored M02. | — |

### Testing-and-verification: every §0 trigger, then applicable run/proof requirements

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| V01 | Failed step fixed: resume there, default in tool | N.A. | No failed gameplay step and repair execution here; C RESUME is a work-task restart, not proof of gameplay resume. | — |
| V02 | New runner/wrapper: read existing header and method first | FOLLOWED | Referee T197/T227 checks tools/guard; G/H explicitly whitelist method and existing tools; P3/P4 cite observed runner limitations. This proves specification research only. | — |
| V03 | Any run: expected minutes and live watch every few seconds | NOT SHOWN | Children instructed C/H; per-launch watched logs unavailable. Referee's own insufficient watcher separately BROKEN R08. | Unknown child execution. |
| V04 | Issue found: own failing plant + clean pass, manifest/ledger | NOT SHOWN | C/P3/P4 require controls; no completed new proof result here. Meter correction's negative test is not shown either. | No new guard qualified. |
| V05 | Complex checks: frozen manifest, explicit verdict per run | NOT SHOWN | P3 mandates receipt preservation and verdicts; no completed qualification run evidence supplied. | — |
| V06 | Programmatic setup not enough: real end-to-end inputs | BROKEN | R5 replaces P4's separately required uninterrupted clean walk using SAME joins; no explicit user waiver of that criterion is visible. Fix F02. | ~10 game min safeguard; validity at risk. |
| V07 | Missed planted bug: confirm scenario reaches activation | N.A. | No missed plant result in cut. | — |
| V08 | Shared helper check: compare per-scenario frozen counts | N.A. | No demonstrated shared-helper check placement/change in this audit evidence. | — |
| V09 | Same issue survives 2–3 fixes: bench | N.A. | No visible qualifying sequence. | — |
| V10 | Random failure: find/log differing condition | N.A. | Account-limit errors are explicit resource errors, not random game failures. | — |
| V11 | Fixing: part checks, full run only milestone | NOT SHOWN | Tool qualification unfinished; C differential explicitly requires broad equivalence, which is a relevant qualification test, not gratuitous full-game regression. Execution unseen. | — |
| V12 | Stuck/wrong: picture of moment, supporting logs | NOT SHOWN | No run-state picture observed. Child tasks mandate pictures; process-start notices cannot establish whether a stuck moment occurred. | — |
| V13 | Before done/video: own checks, real path, watch footage, notes | N.A. | No completed method or delivered video in cut. | — |
| V14 | §1 save failing evidence before fail-fast exit | NOT SHOWN | P3/P4 require preserving picture/state first; no child-run evidence. | — |
| V15 | §1 check tester before blaming system | BROKEN | T574 calls short launches apparently import/setup and “Nothing is off plan” without their exit/result evidence. Fix F03. | 0.7 game min not independently classified. |
| V16 | §1 commands, replies and physical effects distinguished | NOT SHOWN | No actuator/control experiment observed in allowed run evidence. | — |
| V17 | §1 observations matched by identity, clocks separate | FOLLOWED | P3/P4 explicitly require source/run/frame/profile identity and distinguish movie/physics/wall clocks. This is spec compliance, not proof of implementation. | — |
| V18 | §1 stop motion/expire held controls before inspection | NOT SHOWN | P4 specifies full cancellation and held-input release; no execution result. | — |
| V19 | §1 confirm edit landed before long run | NOT SHOWN | No long qualification run completion shown; WIP explicitly unqualified. | — |
| V20 | §1 each check can fail: mutation and clean controls | FOLLOWED | P3/P4 provide explicit paired negative-control tables; H requires both. Only design of verification is established. | — |
| V21 | §1 close observation windows before counting | FOLLOWED | P3 requires closed windows/receipts and forbids incomplete early-stop proof counting. Again a spec-level result. | — |
| V22 | §1 user container, device, real path | NOT SHOWN | No actual completed play/recording evidence available. | — |
| V23 | §1 suspects list of shortcuts vs real use | FOLLOWED | P3 optional lanes/unknown dependencies and P4 setup cuts, unsupported state and profiles explicitly enumerate differences and guards. | — |
| V24 | §2 change ledger per change | NOT SHOWN | J has no ledger edit; trial WIP stat has no ledger path, but main ledger may intentionally wait until qualification lands. No completed landing established. | — |
| V25 | §3 steps/expected outcomes/deadlines, parallel watchers | NOT SHOWN | Specs mandate them, existing system referenced, no actual instrumented run evidence. | — |
| V26 | §3 first failure stops actions, retains failure, correct resumption | NOT SHOWN | P3/P4 require this; runtime reports unavailable. | — |
| V27 | §3b PASS iff all required work/checks ran; fault attribution measured | NOT SHOWN | No accepted PASS receipt in cut. Proposed receipt controls are not completed proofs. | — |
| V28 | §3b causal plant proofs exact IDs, activation, matching clean | FOLLOWED | GPT identifies loose historical proof reuse T434; C RESUME relays exact identity requirement; P3 requires exact attribution. Relay was delayed, covered R04. | — |
| V29 | §4 review screenshots/video critically with sound and joins | N.A. | No final video delivered; P4 prescribes full review and timestamps. | — |
| V30 | §5 long-run resume/progress/deadlines and setup fail-fast | NOT SHOWN | Cost/overrun controls proposed; no completed run establishing defaults and enforcement. | — |
| V31 | §5 never edit inputs a live accepted run will load | NOT SHOWN | Separate copies provided; no content identity trace of executed runs available. | — |
| V32 | §5 do not assume one-at-a-time: measure two instances | FOLLOWED | Project CLAUDE records previously measured two-game operation; T292/T298 actually tries concurrent children. Later unsupported account-limit remedy is separately F02/R10. | — |
| V33 | §5 user windows: muted/behind/no focus | NOT SHOWN | B/C require it; permitted evidence supplies no window observation. | — |
| V34 | §5 fast game time vs wall time measured correctly | NOT SHOWN | S records pilot evidence and C specifies clock split; complete differential remains unfinished. | — |

### Game-dev: every §0 trigger

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| G01 | Room/puzzle/mechanic request: fit place, propose hardest first | N.A. | This interval builds research tools, no new player-facing feature request visible. | — |
| G02 | New game part: door-problem role sweep and batched choices | N.A. | No new gameplay part; already scoped research qualification. | — |
| G03 | Placed thing: inspect from player's position | N.A. | No world placement in supplied scope/stat receipts. | — |
| G04 | Repeated puzzle: disclose and suggest alternative | N.A. | No new puzzle proposed. | — |
| G05 | Walk/play-test/recording: testing §0 rules | NOT SHOWN | No completed walk; watcher shortcomings separately R08. | — |
| G06 | Handoff: GPT spec/audit, Claude code/runs | FOLLOWED | G/H and T429–454 footprint evidence. | — |
| G07 | Part done: record/watch/timestamps, user look before push | N.A. | WIP only, nothing pushed. | — |

### Project/account rules and original task accounting

| ID | Rule | Verdict | Evidence | Cost / exposure |
|---|---|---|---|---|
| P01 | Original user's first-block checklist completed as requested | NOT SHOWN | T1–3 contains only redaction. Cannot determine omitted/altered instructions. | Major audit limitation; obtain a safe task-only extract, not secrets. |
| P02 | B recorded tasks: qualification -> replay -> exam -> signatures -> write-up | FOLLOWED | T735–748 explicitly says qualification WIP; T758–762 keeps later stages pending, no false completion. This is accurate tracking, not fulfillment of all work. | — |
| P03 | Read relevant skills and triggered sections, not just load headers | BROKEN | T121 says “Skills loaded” after T115 reads only first 55 lines of four skills. Trigger-referenced run/role/memory sections lie beyond that; no later read is visible before delegation. Fix F11. | Misapplied review/watch/log rules; costs overlap top findings. |
| P04 | Short/plain reports, comparisons explained where needed | FOLLOWED | T417–425/T542–554 use bullets; T756–762 gives ETA comparison table and labels guesses. | — |
| P05 | Uncertain real choices: A/B with pick; otherwise continue | FOLLOWED | T769–773 offers A/B, states pick, continues; T421/T745 notify reversible choices. | — |
| P06 | No C: project/temp data | BROKEN | T51/T64 deliberately reads a persisted tool result on C:; T279/T510/T704 place shell outputs there. B says nothing on C:. Runtime-managed paths are a tool-default issue, not evidence of deliberate company-code publication. Fix F12. | Separation violation; storage/cleanup time unknown. |
| P07 | Use only account-enabled skills; avoid personal folders | NOT SHOWN | T106/T115 read D: skill library. Original user authorization to load it is redacted; audit task explicitly says referee was told to load these. No basis to call that authorized read a violation. Other personal access not proved. | — |
| P08 | Company material remains in project, no public repo | NOT SHOWN | No push in transcript; C: tool storage separately P06. Remote visibility not supplied and not inspected. | — |
| P09 | Offer git init before unbacked edits | N.A. | Existing git histories and branches precede edits. | — |
| P10 | No new remote/push without authorization | FOLLOWED | Visible operations local only; T554/T748 explicitly confirm no push. | — |
| P11 | Preserve default AI attribution | FOLLOWED | J commits include Claude Co-Authored-By; WIP rescue does too. | — |
| P12 | Main long tests, dev isolated building; verify destination | FOLLOWED | T254–262 sets D: copy and branch; C/H limit work destinations. Research main commits are notes, not game builds. | — |
| P13 | Every shown change gets video unless waived | N.A. | Only research notes/specs and unrun WIP shown; no demonstrated gameplay change delivered. | — |
| P14 | Fix issues seen rather than offer carry-on-as-is | FOLLOWED | Meter discrepancy corrected T178–183; WIP preserved T678. Validity of fixes not inferred from this. | — |
| P15 | Full run at milestone only; no full run after push | N.A. | No push or whole-game milestone run in interval. | — |
| P16 | Bug fixes push immediately after proven tests | N.A. | Qualification forbids baseline product fixes; no solved/tested product bug submitted. | — |
| P17 | Realistic, readable, lived-in world; both players, unique/fun puzzles | N.A. | No world-design/placement scope in this research interval. | — |
| P18 | Keep CLAUDE/AGENTS synchronized when rule changes | N.A. | No project instruction-file edit appears in J. | — |
| P19 | Know run costs, protect user's time, avoid unexplained pass | BROKEN | T745's untested serialization and T574's unsupported on-plan claim violate measurement-first process. Fix F03/F04. | Same as R08/R10, not additive. |
| P20 | Use capabilities available before inventing tool limits | FOLLOWED | T133 discovers delegation/monitor tools; T139 calls capabilities before child launches; T227 reads guard before changing instructions. No proof same-account jobs cannot overlap. | — |
| P21 | Don't wait for reversible design answers | FOLLOWED | T773 explicitly proceeds with recommended plan; no approval wait inserted. | — |

## Fixes for every BROKEN row

These are recommendations only. This audit changes no tools, code, rules, notes or skills outside this file.

| Fix | Covers | Make the rule hard to bypass |
|---|---|---|
| F01 | R01, R04, F07 | Builder launch requires a separate opposing-auditor receipt tied to exact spec hashes, rulings, findings and unresolved objections. A builder's implementation brief cannot serve as that receipt. Changed specs invalidate approval. Same receipt requirement for results before scoreboard acceptance. |
| F02 | R05, R06, V06 | Keep each auditor's exact signed conditions in structured acceptance fields. Any changed condition remains DISPUTED until that auditor signs the revision or the user explicitly waives that exact criterion. Separate video-format preference from clean-walk evidence. R5 must be re-audited before implementation relies on it. |
| F03 | R08, F09, V15, P19 | Replace process-only reassurance with run-ID-bound progress/error/heartbeat/deadline events and scoped fail-stop. Referee sees explicit watched coverage and exit status. Missing telemetry yields UNKNOWN; “on plan” is unavailable from START/END alone. Supervision must survive referee quota loss or stop safely. |
| F04 | R10, F02, F09, P19 | Treat quota errors as account admission failures. Record remaining quota/reset and independent concurrency limits when the provider exposes them. Otherwise label cause unknown and run a bounded admission probe after reset. Serialization may be a temporary conservative pick, never a measured prevention claim. Schedule CPU/game and model slots separately. |
| F05 | R11, F07 | Every completed child sub-step creates a local WIP checkpoint with state, next action and tests outstanding. Supervisor can recover that checkpoint without treating it as qualified. Require a checkpoint before another long build starts. |
| F06 | R14, F07 | One declared qualification cap, with warning threshold below it, enforced by an independent scoped watchdog. On exhaustion, stop and emit INCOMPLETE/failed qualification with used minutes. Phase changes and meter restarts retain cumulative totals. No 45-budget/60-stop ambiguity. |
| F07 | R26 | One execution lane per copy by default. If comparing two games, allocate two isolated copies with immutable shared input identities and a global two-slot reservation. Change the explicit per-copy rule only through a logged approved exception. |
| F08 | M02, F06 | Before the first corrective mutation/relaunch after a surprise, require a short incident receipt: assumed, observed, evidence, intended fix, habit. Append its ID to task state and commit with the recovery. This eliminates end-of-session reconstruction. |
| F09 | M04, M09 | Use one structured live-state record for task status, dependencies, copy/branch, budget and next action; render TODO/scoreboard/child briefs from it. Prelaunch consistency check rejects “running” jobs known failed/deferred and obsolete merge/order instructions. |
| F10 | F03 | Derive ETA from a minimum viable build slice and measured throughput; list critical-path work and uncertainty. Offer scope deletion before a multi-hour build admission. A labelled guess remains allowed but must not masquerade as evidence that strictness necessarily costs hours. |
| F11 | P03 | Skill trigger checklist records the relevant section heading and concrete action before each launch/review/run. Reading headers does not satisfy it. Prelaunch gate includes review, watcher, cost, checkpoint and log requirements, with actual artifact references. |
| F12 | P06 | Configure tool-owned output/temp paths under D: before launch where supported; consume large outputs there rather than reopening a C: persisted file. If the runtime cannot honor relocation, report the concrete limitation and obtain an explicit narrow exception before handling project material that way. |

## Accounting limits and next audit inputs

- No audit of secret correctness, individual game faults or later fixes was attempted. No game detail is needed to establish the process failures above.
- The original user's task checklist remains NOT SHOWN. Supply a sanitized task-only extract to resolve P01; do not expose secret benchmark data.
- To turn child execution from NOT SHOWN into evidence, provide pre-cut per-run cost/watch/verdict receipts and the task completion records. Instructions to watch are not watch records.
- Do not attribute the whole overnight delay to parallelism. The account failed, reset time was stated, and recovery was next morning; the counterfactual completion time is unknown.
- No elapsed or risk figures in this report should be added across rows: the same failed gate appears under several applicable rules.
