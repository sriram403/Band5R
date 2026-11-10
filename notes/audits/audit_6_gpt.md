# Independent compliance audit: #6, the ghat

Scope: day 2, 2026-11-10, transcript 09:33:39–15:04:28. No game launched. Only this report written. Read only the supplied evidence and permitted `g15` code/tool headers and git path history. No newer skills or other MPG notes read.

T = historical testing-and-verification skill; M = project-memory; G = game-dev; F = first-principles-solving; C = CLAUDE_md_then.md. Numbers refer to source sections. All historical documents are in `evidence_6`. Identical instructions across sources share a row; distinct duties get separate rows. Counts measure rows, not overall quality.

FOLLOWED requires positive evidence. BROKEN requires an observed conflict. NOT SHOWN means evidence is missing or incomplete; N.A. means the trigger was absent or superseded. Repairing a breach later does not erase it. Times below locate transcript text/tool calls; quoted log values and commands make those locators searchable. `L` numbers refer to raw LF-delimited transcript lines; CRCRLF-aware readers may display different line numbers.

Limits: commands/results are clipped and image contents are absent. Image-read calls prove an inspection action, not independent pixel verification. Day-1 rough notes are admissions/history, not a complete day-1 audit. Run-folder clocks are 5 h 30 min ahead of transcript clocks: `20261110_152703` corresponds to 09:57. Do not add those clocks. `g15` includes later changes: its headers prove available capabilities, not every earlier implementation detail. Resume is independently documented in TESTING_METHOD_then.md v4, “As built.”

Skipped instructions clearly about other work: browser toasts/wrappers/headless viewport sizing, audio processing/resampling/sensor-specific cases, and document extraction. Their generic principles are retained below. Untriggered game pipelines and project/thread setup are marked N.A. rather than silently omitted. The later “never wait for answers” rule is not applied retroactively: historical rules allowed design questions. TESTING_METHOD_then's obsolete v6 “full after push” conflicts with C's explicit newer prohibition; C wins.

**150 rules: FOLLOWED 44, BROKEN 32, N.A. 23, NOT SHOWN 51.**

| R# | rule | section | verdict | evidence | cost |
|---|---|---|---|---|---|
| R1 | “Watch every run”; stop immediately off-plan | T1; C How to work | BROKEN | 10:39:17 sees P1 taken, 10:39:18 both taken, explicitly waits until 10:40:26 step timeout. Event tails did not stop this. | 69 s exposed game time; overlaps R3/K3 |
| R2 | Every issue gets check, planted failure, clean pass, manifest and ledger | T1; C checklist | BROKEN | New ghat checks/plants added throughout. But 10:20:58 leaves can landing and leg-up faults OPEN; no completed new proof for these issues before “finished” handoff. | Unpriced future replay/rework; not zero |
| R3 | Watch movement of everything; missing actor must not disable remaining checks | T3.3 | BROKEN | 11:07:54: Problem circle 206.5 s, zero stops. g15 LiveControl watcher checks van/Naresh, not Problem; `if not has_n: continue` also skips player-taken events. | About 3.3 min stall exposure, plus R1 overlap; K3 |
| R4 | Releasing input is not stopping; brake and verify rest | T1 | BROKEN | 10:30:27 walk toggled parking brake off in three places. 12:21:02–32 test driver only `ad.release()`; van rolls ~190 m back; braking added later. | ~2.4 min failed fresh heat attempt, 12:19:09–12:21:35; overlaps K2 |
| R5 | Controller owns expiry; test stopping and expiry separately | T1 | NOT SHOWN | Step deadlines exist; no independent controller-lease/expiry and verified-stop negative-control pair shown. | — |
| R6 | Match pixels/telemetry by frame identity; separate clocks and latency claims | T1 | NOT SHOWN | Shots and evals are separate observations. No frame-ID linkage demonstrated. No precise physical-latency claim established. | — |
| R7 | Separate requested/accepted control from readback and physical effect | T1 | FOLLOWED | 09:43–09:49 jug bench measures parent/local offset/body mode and actual displacement; planted R0 fails, fixed R1/R2 pass. | — |
| R8 | Save offending observation before rejection; compare same update phase | T1 | NOT SHOWN | Failure shots/logs exist; same-phase target/readback retention for every rejected observation not established. | — |
| R9 | Fixed-timetable downsampling; preserve old rule as negative control | T1 | NOT SHOWN | 13:56:24 selects every 250th frame at 25 fps, correctly fixed 10 s spacing. Old broken sampling rule retained as a test is not shown. | — |
| R10 | Confirm edit landed before long run | T1 | FOLLOWED | 09:35 freeze/compile; 11:09:28 grep confirms edit before run. 15:01:47–51 inspects broken list edit and reruns generator. | — |
| R11 | Honest pass/fail/untested report, assume broken | T1; T6; F2.10 | BROKEN | 11:46 honestly reports P2 left behind. But 14:17 says “finished and waiting only” for video OK, omitting known OPEN ramp faults and remaining path shortcuts. | Unpriced user verification/rework |
| R12 | Final player-visible result outranks own metrics | T1; F1; C Own it | FOLLOWED | 11:45–11:46 video inspection finds P2 abandoned despite passed steps; 09:50 jug picture reveals tail-light issue. | — |
| R13 | Every check able to fail; see each fail once | T1; T6 | NOT SHOWN | 27 plant proofs and 124 required checks reported at 14:16. These counts do not demonstrate that all 124 checks were independently seen failing. Several new named checks are positively proved. | — |
| R14 | Count after event ends; test starting/lasting states | T1 | FOLLOWED | 09:34–09:35 changes endless-window scenario to revisit a window; original case never reached the broken state. Plant caught and clean follow-on confirmed 10:04:01. | — |
| R15 | Real inputs and real paths; no gifted items/teleports or disabled hazards | T1; T6; G3 | BROKEN | 10:32:41 admits teleported corners/doors and code-assisted scenarios hid timing. g15 make_ghat header declares `place_player` cuts; net helpers still place players. | 52 min walk/replay pool reported 15:04; attributable avoidable share unknown, not all 52 |
| R16 | Debug from pictures, revealing angle, second angle if needed | T1; T4; C | FOLLOWED | 09:49:17 rejects inside rack view, 09:49:23 switches behind van; 10:22:52 inspects failure video; 11:01:36 reads failed spring-walk shot. | — |
| R17 | Reproduce user report using their device/menu/mode | T1 | N.A. | No user-reported gameplay failure in interval; credits complaint is handled under scope/final report. | — |
| R18 | After 2–3 failed fixes, isolate bench, visible causes first | T1; F2.9; C | NOT SHOWN | Jug bench used well at 09:43. Three round-test failures include instrumentation and an overstrict threshold; evidence does not establish three failed game fixes requiring a new bench. No blanket compliance credit. | — |
| R19 | Check tester before system | T1; F1 | FOLLOWED | 09:35 investigates unreachable plant; 10:23 finds missing pad setup; 11:20:25 reads real capsule radius before changing guessed clearance. | — |
| R20 | Suspects list for each shortcut, difference and removal/check plan | T1 | NOT SHOWN | Header declares cuts; 10:32:41 discusses existing shortcuts. Complete maintained rows with a check/removal plan for each are not shown. | — |
| R21 | Small change checks, smoke, area set; whole game only milestone | T2; C ledger | NOT SHOWN | Repeated GHAT filters and three all-seven ghat sets. No `full` whole-game run shown; no smoke command shown either. Area tests are not forbidden whole-game tests. | — |
| R22 | Do not rerun long test merely to cover small change | T2; F5 | NOT SHOWN | Three area clean sets ~59 min. New game fixes between sets invalidate some proof. Exact unnecessary share cannot be established from dependencies and final gate. | — |
| R23 | Ledger each change, risk and covering tests as it lands | T2; M2; C | FOLLOWED | Notes/ledger writes accompany 09:56:58, 10:56:45, 11:27:10, 12:31:22, 13:37:49 commits; final counts updated 14:16. Clipping limits entry-level completeness review. | — |
| R24 | Know cost before run; detect loops and tell user | T2; F1/5; C time | BROKEN | Estimates given, e.g. 09:57 ~20 min. But 11:02:15 says steps 1–13 passed then repeats from start; dry trials continue to 10. Aggregate cost only measured after user asks at 15:04. | K1 ~17–20 min; overlaps R27 |
| R25 | Before user's look, own tests + smoke; long tests after agreement | T2; C | NOT SHOWN | Own checks shown, smoke not shown. User 09:33 explicitly ordered all-seven final gate before video, authorizing that long run. | — |
| R26 | Planned steps include expected results, deadlines and later prerequisites | T3.1 | BROKEN | Take 2 drive-away passes with P2 left on road (11:46:39). Both-aboard prerequisite only added 12:10:52; parking brake prerequisite also initially wrong. | ~9.8 min take-2 run exposed to incomplete plan; avoidable fraction unknown |
| R27 | Resume failed step from save, do not replay passed start | T3.5; F5; method v4.5 | BROKEN | Dry trials 2–10 launch whole dry_walk.sh without `--from`; 11:02:15 admits passed prefix. live.py/LiveControl headers and historical method offer resume. No ghat resume experiment or measured reason for avoiding it. | ~17–20 min repeated prefixes; K1 |
| R28 | Run steps back-to-back with parallel expectations | T3.2; F5 | FOLLOWED | Autonomous step events through 10:56–11:01 and 13:45–13:55; model does not manually gate every successful action. | — |
| R29 | Clean end-to-end walk becomes regression | T3.6 | FOLLOWED | make_ghat.py/ghat.json committed; dry trial 10 and take 3 DONE; credits edit regenerates 20-step plan 15:01:51. | — |
| R30 | Critically inspect every screenshot | T4; C | NOT SHOWN | Specific image/grid reads shown; not every saved screenshot has an inspection action, and pixels omitted from export. | — |
| R31 | Every placed thing visible/reachable/readable, no floating/sunk objects; blockers tested around, action feedback; player-view close-ups | T4; G1.9/G3; C humans | NOT SHOWN | Rear rack shot and seated/net perspectives shown; no complete placed-object/player-view sweep. | — |
| R32 | Record, watch first, send times and judging guide | T4; G1.3; C record | FOLLOWED | 11:44–11:46 grid inspection then take-2 time guide with flaw (L3530–3552); 13:56 grid then 13:57 take-3 guide. | — |
| R33 | Reference/before/after side-by-side for visual changes | T4 | NOT SHOWN | 09:49:23 requests bug/fix outside shots; reference/before/after coverage of every visual change not shown. | — |
| R34 | List every region/view; unviewed means not checked | T4; F4 | NOT SHOWN | No complete region-to-view inventory or list of unchecked regions shown. | — |
| R35 | Long run progress file and resume finished parts | T5 | NOT SHOWN | run_test.sh offers scenario resume; no interrupted-suite resume demonstrated. Walk failure replay is separately R27. | — |
| R36 | Every wait independently bounded; trust summary only | T5 | BROKEN | dry script loops 1200×3 s, then cats log without explicit timeout verdict/failed rc. 10:23:41 live query goes unanswered until killed 10:25:49. | 128 s observed query wait; unrealized wrapper risk up to ~60 min |
| R37 | Compile/parse first | T5 | FOLLOWED | 09:35:27 compile; run_test defaults compile; 09:45:52 bench typo caught in seconds. No NO_CHECK override shown. | — |
| R38 | Each test sets/restores its own state | T5 | NOT SHOWN | F1 resets and fresh games shown; complete cleanup/independence proof across all scenarios absent. | — |
| R39 | Flaky means diagnose measurement, not simply rerun | T5 | FOLLOWED | 10:18:51 picture; 10:19:03 changes fixed 0.4 s delay to wait for actual Leg-up offer, THEN reruns 10:19:07. Later fling bench compares broken/fixed physics output; remaining OPEN issues are separately R139. | ? |
| R40 | Never edit files running test will load; second copy | T5; C copies | BROKEN | 12:19 edits setup while old chain runs, acknowledges/restarts 12:19:09; 12:21:32 edits test then restarts again. 15:04 labels killed changed-code runs ~8 min. | K2: ~8 min self-reported; 146 s of one invalidated attempt directly timed |
| R41 | Measure parallel-instance capability, do not assume serial limit | T5; C copies | NOT SHOWN | C already records measured 112 fps with two instances. method_run refuses second Godot. New experiment or documented reason for serial restriction not shown. | — |
| R42 | Muted, behind user windows, no focus stealing | T5; C short rules | NOT SHOWN | run_test header promises behavior. Dry script uses offscreen/refocus=0 but bypasses wrapper, no explicit mute; actual speaker/focus state not recorded. | — |
| R43 | Use game clock; distinguish wall and recording time | T5; G4 | FOLLOWED | 11:44–11:45 distinguishes video/game time from wall time; 13:56 ffprobe 401.32 s. Method host intentionally uses monotonic deadline clock. | — |
| R44 | Done requires every own check pass and seen fail | T6 | NOT SHOWN | 124/124 final pass and named new plant failures shown; all-check negative-control mapping absent. | — |
| R45 | Done requires real path with real inputs | T6 | BROKEN | 14:17 done claim retains declared corner/door placement cuts. 10:32:41 already explained why those cuts conceal timing. | Unknown remaining human-path verification; overlaps R15 |
| R46 | Done report lists what was not tested | T6; M3; G1.9 | BROKEN | 14:17 omits OPEN ramp faults and teleport limits while saying only video OK remains. | Unpriced, overlaps R11 |
| R47 | Load memory skill for substantial work | M intro | FOLLOWED | 09:33:42 Skill(project-memory) invocation and loaded text, followed by notes and local commits. | — |
| R48 | Say project-memory when behavior comes from skill; concise message | M intro | NOT SHOWN | Skill loaded; attribution for specific handoff behavior not shown. Long later tables explicitly requested by user. | — |
| R49 | New project own folder, ask local caches, create handoff | M intro | N.A. | Existing multi-session game, not setup. | — |
| R50 | Backup/git before editing; pushes only authorized | M intro | FOLLOWED | 09:33:42 git log/status confirms repo before edits; no premature push shown. | — |
| R51 | General Q&A: no git/commit ritual | M intro | N.A. | Day builds game code; not standalone knowledge Q&A. | — |
| R52 | Files permit instant continuation; important state not chat-only | M1 | BROKEN | g15 path history 5f3e3e3..50d89f1 contains no MASTER_PROMPT/LESSONS change. TODO batch updates do not meet LIVE STATUS after every substep. | Unpriced handoff recovery |
| R53 | AGENTS/CLAUDE kept together on changed rules | M2; C notes | NOT SHOWN | No paired update shown. No-credits rule saved elsewhere later; exact instruction-file applicability uncertain. | — |
| R54 | LIVE STATUS after every substep, exact next command | M2 | BROKEN | No MASTER_PROMPT change in day-2 path history; many walk failures/fixes between batch TODO updates at 10:21, 11:46, 14:16. | Unknown; overlaps R52 |
| R55 | TODO ticks results and current action as pieces land | M2 | FOLLOWED | 10:21 commit 1481fb4; 11:46 d83bc6b; 14:16:52 current state/counts update. Does not prove every-substep handoff duty. | — |
| R56 | Sorted lessons updated when learned | M2; C notes | BROKEN | Many new rough lessons; no notes/LESSONS.md change in g15 history 5f3e3e3..50d89f1 and no write call shown. | Unpriced future repeated mistakes |
| R57 | Immediate assumed/reality/fix/habit mistake entries | M2/M3; F4; C | FOLLOWED | 09:37:06 window; 09:51:23 jug/lights; 10:47:06 walk; 11:20:45 round; 12:16:37 warning. Supplied entries correct earlier false explanations. | — |
| R58 | Scope record: keep/cut/who/when/why | M2; F1 | NOT SHOWN | Design answers/rough notes exist; complete scope-file record including all walk cuts not shown. | — |
| R59 | Version process changes; retain decision history | M2; F2.6 | BROKEN | New dry wrapper lives in C: scratchpad, drops documented v4 resume, no versioned tradeoff entry shown. Method is replaced operationally without its required record. | K1 overlap, no extra charge |
| R60 | Keep agreed polish list; remind at end | M2; G1.8 | NOT SHOWN | 09:33 user confirms UI deferred. No explicit polish reminder in final report or polish-list update shown. | — |
| R61 | Read mistake log before similar task, apply lesson | M3; F4; C | BROKEN | 09:33:51/53 reads log. 10:30:04 CRLF exact-match failure repeats read newline lesson; full-prefix replay also repeats documented method waste. | ~13 s newline retry, plus K1 overlap |
| R62 | Update all touched notes without user listing each | M3; F5; C | BROKEN | Ledger/TODO/rough/FINAL updated; required sorted lessons and MASTER_PROMPT not updated in day-2 history. | Unknown; overlaps R52/54/56 |
| R63 | Before editing read handoff, status; project read order | M3; C opening | NOT SHOWN | git/TODO/rough reads shown; MASTER_PROMPT/LESSONS reads not shown. Absence of a read receipt is not proof of remembered context. | — |
| R64 | Say copy/branch; ready only in user-running copy | M3 | FOLLOWED | 10:22:05 explicitly g15/MPG_dev; 14:17 says merge waits approval rather than claiming main updated. | — |
| R65 | Commit small/often, push per project rule | M3 | FOLLOWED | Supplied log: 3425043,1481fb4,7b864db,005ff87,746ef2a,fe6daf7,50d89f1. No unauthorized merge/push. | — |
| R66 | Save notes before compaction/context fills | M3 | NOT SHOWN | No explicit compaction event in supplied interval; batch notes do not prove pre-compaction coverage. | — |
| R67 | Handoff: untested, done, next | M3 | BROKEN | 14:17 done/next present; known open or unproved coverage omitted. | Same unpriced exposure as R46 |
| R68 | Milestone/compaction fresh thread, notes first | M4; C short rules | NOT SHOWN | Milestone pending approval; user then requests discussion. No new-thread suggestion shown, but exact trigger/need to continue new work ambiguous. | — |
| R69 | Thread launch/link/stop OR timer-first wait/moved warning/full-path skills prompt | M4 | N.A. | No launch/suggestion/wait claim occurred. Project C overrides T3 auto-move rule; no invented missing-timer breach. | — |
| R70 | General lessons marked; approval for skill promotion; library instructions | M5; C notes | NOT SHOWN | No promotion authorization or library write shown. User-created-rule exception differs from model-derived lessons. Auditor did not read library. | — |
| R71 | App skill/catalog first, private app notes at milestones | M5 | NOT SHOWN | No app-skill action shown; existing game may qualify, no new-project trigger today. | — |
| R72 | State core/need/scarce unit and current cost first | F1; F2.1 | NOT SHOWN | 09:33 follows user steps; no explicit day-start core/cost statement. | — |
| R73 | Break down real cost, cut biggest waste | F1; F2.2 | BROKEN | Aggregate cost breakdown first done 15:04 after user requests, after repeated full-prefix walks. | K1 overlap |
| R74 | Measure true limits, smallest experiment before decision | F1; C measure | FOLLOWED | Jug awake/parked bench; 10:35 arrival timing; 11:20 real collision radius; 12:34 phase/speed measurement rejects guessed stop-timer cause. | — |
| R75 | Question owner/requirement, delete, simplify, speed, automate last | F1; C algorithm | BROKEN | Measured stall deletion is good; dry wrapper nevertheless automates redundant full restarts rather than testing existing resume. | K1 overlap |
| R76 | AI plans revisable, preserve user constraints, no invented approval gate | F1 | FOLLOWED | Changes unreachable plant case, diagnoses wrong stop theory before changing game; honors explicit two-take gate. Historical design answers really were allowed. | — |
| R77 | No habitual numbers/plans; evidence for exact situation | F1 | NOT SHOWN | Credits cap 30 s fails under recording at 11:43:40; dry run took 18 s and known recorder slowdown existed. Failure alone does not prove an unreasoned habitual number. No explicit measured slack calculation shown. | ? |
| R78 | Fixed goal, adapt plan to each result | F1 | FOLLOWED | Changes window scenario, uses jug bench, tests real net hold; measured fog sight replaces stop-timer guess. Specific restart habit separately fails. | — |
| R79 | Core before show features; every cut user-agreed/recorded | F1 | BROKEN | Credits appended to puzzle recording; user asks why 14:39:03, accepts removal 15:00. No earlier approval for this show feature shown. | ~1.1–1.3 game min plus ~1.7 elapsed trim/repair; K4 |
| R80 | Write v1/v2 keeps/waste/why, preserve old path | F2.3; F5 | BROKEN | Historical v1–v5 explicitly explains restart waste. New dry wrapper reverses resume behavior without a versioned measured tradeoff. | K1 overlap |
| R81 | Pick/reason, proposed until agreement, other work meanwhile | F2.4/5 | FOLLOWED | 10:40 hot-cap question, 12:10 A repair authorization; 12:36 sight question, 13:26 A answer then implementation. Do not retroactively impose later no-wait rule. | — |
| R82 | Wrong core: ask; user wants think: do not build that idea | F2.5 | FOLLOWED | 15:00/15:03 discussion requests followed by accepted credits trim and requested timing breakdown, no next-puzzle build. | — |
| R83 | Version atop document, decision log below | F2.6 | NOT SHOWN | Method snapshot has history; FINAL addendum written. Consistent header/log on every changed process record not shown. | — |
| R84 | Feedback both ways, explain better option | F2.7 | FOLLOWED | Hot-cap choice recommends reaction time; fog question proposes player-consistent 15 m after observed ~40 m charge. | — |
| R85 | Loose asks fit world, numbered suggestions, proposal before build | F2.8; G1.2; C design | N.A. | Resumes agreed puzzle, new work is bounded bug repair/A/B choices, not new loose room/mechanic ask. | — |
| R86 | Change looping method after 2–3 no-gain attempts | F2.9; F5 | BROKEN | Ten dry trials still use reset-from-start; no attempt to measure resume completeness. Useful new diagnoses mean not all trials are waste. | K1 overlap |
| R87 | Honestly name regressions; remove harmful work | F2.10 | BROKEN | Ramp issues left OPEN then omitted at “only video OK” handoff; credits retained through retries. | Unpriced plus K4 overlap |
| R88 | Shared value: find all users before changing | F4 habits | FOLLOWED | 09:47:34/40 searches stowed consumers; 09:57:09 follows ramp fling consequences of disabling body. | — |
| R89 | Recursion: write stopping condition | F4 habits | N.A. | No new recursive function or recursion issue evidenced. | — |
| R90 | Tools fail loudly; input first; repeated failure means upstream | F4; G4 | BROKEN | Dry script suppresses client stdout/stderr/rc. 10:42:08 `;` runs proof after clean launcher refuses an existing game; stale/missing verdict creates spurious NOT PROVED. | ~18 s refusal recovery; 128 s blind query overlaps R36 |
| R91 | Sampled grid/mesh gets cell margin; probe output | F4 | N.A. | No sampled-shape margin change today. | — |
| R92 | Measure big/small impression; explain eyes/numbers mismatch | F4 | FOLLOWED | 11:20:25 actual capsule radius 0.3 m replaces arbitrary >0.5 m threshold after 0.42 m result. | — |
| R93 | Recheck old visual notes; structure before cosmetics; framing early | F4 | NOT SHOWN | Specific picture diagnoses exist; complete old-note recheck/structural ordering not demonstrated. | — |
| R94 | No long silent runs; independent work/notes in parallel | F5; C busy | FOLLOWED | 09:36–09:37 reading/notes during proof; 09:57 examines rack consumers during set; scenario progress updates through clean runs. This does not prove movement watcher compliance. | — |
| R95 | Load relevant testing/memory/first-principles, engine notes | G intro | NOT SHOWN | Three Skill calls at 09:33; no first-principles or engine-reference read shown despite loop. Supplied skill file is standard, not a receipt of runtime loading. | — |
| R96 | One-line core loop before first scene | G1.0 | N.A. | Existing game, first scene outside interval. | — |
| R97 | Design doc includes intentional exception/real behavior/levels/ideas | G1.1 | NOT SHOWN | Reads agreed PUZZLE_CHANGES #6; all required design categories not visible. | — |
| R98 | Hardest proposal first, play-time cost, plain words, answer in message | G1.2; C hardest | N.A. | No broad new-part proposal; corrective A/B decisions are not a whole puzzle pitch. | — |
| R99 | Door role sweep: role counts/questions/picks/reasons before new part | G1.2 | N.A. | Continues agreed part. Earlier sweep cannot be audited from day-2 transcript. | — |
| R100 | Decided once: save answers, never re-ask | G1.2 | FOLLOWED | Q1/Q2 settled 09:33, not re-asked. Hot-cap/fog concern newly discovered behavior, answers recorded with fixes. | — |
| R101 | One part, own test, do/expect/tell guide, OK before push/next | G1.3; C | FOLLOWED | Stays #6, video guide 11:46/13:57, waits feature OK 14:17. Specific user instruction overrides automatic bug-push for this branch. | — |
| R102 | Gym first, beside mechanic facing it | G1.4 | NOT SHOWN | Jug bench good; no gym-first location/view proof for each listening/warning/routing repair. | — |
| R103 | Greybox then art; agree asset appearance before population | G1.5 | N.A. | No new art pipeline/population today; tail-light depth fixes existing geometry. | — |
| R104 | Numeric colour bible, warm focal rules; recolour imports | G1.5 | N.A. | No palette/imported asset creation. | — |
| R105 | Free/CC0 assets, credit, source zips out of git | G1.5/G5 | N.A. | No asset download evidenced. | — |
| R106 | PLAN hub, system/file, one job/fresh session, every job tested | G1.6 | NOT SHOWN | Existing scripts repaired and tested; no full job/session/PLAN compliance evidence. Mature project context makes blanket breach uncertain. | — |
| R107 | Eye/feel tuning panels by job, hotkey presets | G1.7 | N.A. | Bounded repairs, no open-ended aesthetic tuning request. | — |
| R108 | Realistic/readable behavior; intended unrealism only | G2; C | FOLLOWED | 13:27 fog-limited sight aligned with players; radiator waiting/pouring uses carried pot. These examples do not certify every world object. | — |
| R109 | Lived-in placement, clumps not grids, enlarge cramped space | G2; C | N.A. | No new decoration placement/layout today. | — |
| R110 | Both on foot/jobs, co-op knowledge, visible mistake consequences | G2; C both out | FOLLOWED | Walk demonstrates net corners, separate breaths, P1 cap/hiss, P2 spring trips; cap error brings danger back. P2 drive-away problem repaired. | — |
| R111 | Never repeat puzzle; warn/suggest alternative | G2; C | N.A. | No new puzzle requested. | — |
| R112 | Three fun mechanics; connect brought items, no magical rewards | G2; C | NOT SHOWN | Cooperative actions shown; whole-game count/provenance not proven by this day. | — |
| R113 | Danger warns then strikes; human time to react | G2 | BROKEN | 10:39 immediate cap return takes both; 12:15 and 12:34 taken during net despite warning patch. Later listening/fog fixes repair actual attack path. | Failed-walk minutes inside 52 min pool; causal avoidable share unknown |
| R114 | Few deadly enemies with distinct senses | G2 | N.A. | No roster design today. | — |
| R115 | World reacts; terrain depth changes movement | G2 | NOT SHOWN | Marks tested/saved, but complete terrain/reaction/movement principle not established here. | — |
| R116 | Real split-screen readability, unmistakable shapes, front read order | G2 | NOT SHOWN | No measured 800 px readability/shape/order sweep shown. | — |
| R117 | Distances follow route, not straight-line | G2 | FOLLOWED | Heat uses road sample indices; 12:13:05 parks at point 199 vs milestone 205. No claim all other triggers proven. | — |
| R118 | Actual play mode/hardware; log input setup first | G2/G3 | BROKEN | Take 1 lacks P2 pad setup (10:22:39/10:23:09). Later forces pad; no one-keyboard path proof. | 45 s initial launch-to-fail, ~1.5 min to identify/fix; not all gameplay |
| R119 | Clear sightlines; hiding player must not block their view | G2 | NOT SHOWN | Seated/net view shown; full obstruction audit absent. | — |
| R120 | World-voice instructions, short/plain, A/B questions | G2; C | FOLLOWED | 10:40/12:36 A/B choices; quoted “It heard that. It's listening: hide, quick.” Long breakdown later explicitly requested. | — |
| R121 | Automated real-game tests/debug hook and real renders | G3 | FOLLOWED | live.py eval/shot, autonomous walks, real frame grids read. Teleport limits separately R15. | — |
| R122 | Seeded generator/solver, every generated level solvable | G3 | N.A. | Authored ghat, no generation work. | — |
| R123 | Dev menu sets whole state, per-puzzle replay reset | G3 | FOLLOWED | F1 Puzzles start/reset throughout; jug bench exposes and repairs physical reset interaction. | — |
| R124 | Hold input beyond tick; reactions checked a few frames later | G3 | FOLLOWED | pad_tap holds 5 frames, releases 3; long-hold net test explicitly checks after completion. Spring release lesson read at startup. | — |
| R125 | Whole-journey run per milestone | G3 | NOT SHOWN | Ghat sets/walk are not whole journey; final milestone gate/approval pending, so no categorical breach. | — |
| R126 | State flag must physically put world in state | G3 | FOLLOWED | Bench checks jug actual world/local position, not just correct parent/slot metadata, and fixes physics participation. | — |
| R127 | Grep older tests' changed assumptions | G3 | FOLLOWED | 09:57 ramp throw investigation; 10:16 ramp run; 10:20 fling bench compares with/without stow fix. | — |
| R128 | Log every dialogue/state change | G3 | NOT SHOWN | Many logs exist; exhaustive event logging not proved. | — |
| R129 | Keep stepping minimized; test real minimized window | G3 | NOT SHOWN | Offscreen/headless is not proof of a real minimized-window experiment. | — |
| R130 | Performance budget every added camera | G3 | N.A. | No persistent extra render feature; diagnostic views alone do not trigger this. | — |
| R131 | One owner per state | G4 | NOT SHOWN | No ownership inventory/proof; phase logs insufficient. | — |
| R132 | Route/outlines look-ahead, not cone check | G4 | NOT SHOWN | Round waypoint obstruction fix shown; complete driving look-ahead audit not shown. | — |
| R133 | Prefix names, grep before allocating shared name | G4 | NOT SHOWN | ghat-prefixed helpers exist; collision search for every name not shown. | — |
| R134 | Story steps by ID not index | G4 | NOT SHOWN | New story-ID implementation not established in reviewed day evidence. | — |
| R135 | Check cross-effects of tuning; final state, actual limiter | G4; F4 | FOLLOWED | Fling bench compares actual output velocities; jug checked after motion; tail lights measured against doors. Other maneuvers not claimed checked. | — |
| R136 | Thrust through centre of mass; reachable range; formula before physics blame | G4 | N.A. | No thrust/controller redesign. | — |
| R137 | Sliding terrain window/fixed-image trails/named scripted props/character pipeline | G5 | N.A. | No such construction today; skipped as other-task techniques. | — |
| R138 | Interiors same place with fades; outdoor occluder ray/fade | G5 | N.A. | No interior/visibility-system construction. | — |
| R139 | Fix every issue now, not record/carry on | C How to work | BROKEN | 10:20:58 ramp can/leg-up left OPEN; 14:17 reports finished without them. Investigation is not a fix. | Unpriced future user/test time |
| R140 | Every shown change gets video unless waived | C Always record | NOT SHOWN | Ghat take 3 recorded, benches have shots; complete video coverage of every shared/ramp change not shown. | — |
| R141 | Main long tests; dev building; verify target copy | C copies | BROKEN | Three long sets run in MPG_dev, 09:57/11:46/13:56, rather than main. Unmerged g15 cannot be tested by simply running old main; needed isolated snapshot/explicit exception, not silent departure. | No independent extra cost proved; interference overlaps K2 |
| R142 | “Nothing on C:” | C short rules | BROKEN | Model chooses C: scratchpad for dry script/grids; 15:00:56 writes Claude memory there. Exclude unavoidable tool-managed task output from this finding. | Unpriced portability/recovery cost |
| R143 | “Let's discuss” means discuss | C short rules | FOLLOWED | 15:00/15:03 requests discussion; accepted trim then requested time breakdown, no next feature. | — |
| R144 | Bug fixes auto-push; feature waits user look | C push rule | N.A. | Specific 09:33 user says no feature merge/push before video OK. Do not penalize obeying that instruction. | — |
| R145 | Update touched test sheet/design/principles/memory and paired rules | C notes list | NOT SHOWN | Ledger/TODO/rough/design/FINAL writes visible; no complete touched-file reconciliation. Proven MASTER/LESSONS omissions separately listed. | — |
| R146 | Never remove a check without user OK | C checklist; T1 | FOLLOWED | 14:16:45 drops no_stall_drag proof row. 09:33 explicit instruction applies l6_final.py removing measured-ineffective stall drag. Authorized deletion is not concealment; old failed proof retained in evidence. | — |
| R147 | General rules saved; library approval before edits | C notes; M5 | NOT SHOWN | No-credits rule saved 15:00:56; no skill-library edit shown. Later no-wait commit postdates audited build behavior. | — |
| R148 | Follow startup reading list/order; no re-ask Q1/Q2 | 09:33:39 user | NOT SHOWN | Patch/proof/bench/final/video order and no Q1/Q2 re-ask shown. Some mandatory reading is only grep/head/count, e.g. 09:33:57 design section counted/searched. Complete reading of every listed item cannot be certified. | ? |
| R149 | Two failed recordings: stop and tell user | 09:33:39 user | FOLLOWED | 11:43:40 stops takes, 11:46:39 reports both; 12:10:45 A authorizes repair/continuation; take 3 starts 13:44:46. | — |
| R150 | No merge/push before video OK; then sriram403 | 09:33:39 user | FOLLOWED | No merge/push shown through cutoff; 14:17 asks OK. User likes playing at 15:00 but requests discussion. | — |

## Top 3 costs

These are elapsed exposure estimates, not proven independent savings. They overlap; do not add them or subtract them mechanically from the nine-hour claim.

1. **R27 / K1 — repeated passed prefixes: approximately 17–20 game minutes.** Ten labeled dry trials, no dry `--from`. Approximate repeated prefixes for trials 2–10: 126 + 137 + 197 + 116 + 138 + 90 + 93 + 132 + 136 = 1165 s = 19.4 min. Derived from launches/step events around 10:30, 10:35, 10:56, 11:02, 11:27, 12:11, 12:13, 12:31 and 13:37. Allow startup/notification uncertainty: 17–20 min, not exact stopwatch time. Earlier unexpected failures sometimes shorten a prefix. Final complete recording/regression excluded. Ghat checkpoint completeness was never tested, so this is replay exposure/potential saving, not a demonstrated 19.4-minute speedup.
2. **R40 / K2 — changing the tested copy mid-run: about 8 minutes reported; 146 s of one invalidated attempt directly timed.** Model's 15:04 table labels killed changed-code runs 8 min. 12:19/12:21 edits and restarts corroborate behavior; 12:19:09–12:21:35 = 146 s. Clipped results do not independently reconstruct all eight minutes. Necessary corrected reruns are not automatically waste.
3. **R1/R3/R36 / K3 — weak failure supervision: roughly 4.4 game minutes plus 2.1 minutes of blind client waiting.** Problem has 206.5 s of circle time and zero stops; allowing initial approach, about 195 s could have been cut by a five-second movement check. P1 taken 10:39:17, waited to 10:40:26 = 69 s. About 264 s = 4.4 game min. Separately live query 10:23:41–10:25:49 = 128 s; not all proven game-running time. Combined observed blocked/exposed elapsed time ~6.5 min, with those categories kept distinct.

Other pools: three clean **ghat-area** sets cost ~59 min, not three whole-game runs. First verdict wall 1163 s; other two ~20 min each. New fixes between sets and explicit final gate mean the evidence cannot price all subsequent 39 min as waste. 15:04 estimates mix gameplay, encoding, coding overlap and response waiting; subtraction from total elapsed time does not produce exact coding time.

**K4, credits:** dry 6 step 21 11:33:29–47 = 18 s; take 2 11:43:05–40 = 35 s; take 3 13:54:45–13:55:11 = 26 s. Notification intervals total 79 s, roughly 1.1–1.3 game min. Accepted trim/rule repair 15:00:22–15:02:03 adds ~1.7 elapsed min. Do not charge the entire replacement recording to credits: P2 abandonment independently needed repair.

## What the tools already offered

- `LiveControl.gd` header documents step save points and `from`; `live.py` parses `--from`; historical method v4.5 requires it. Dry wrapper takes only walk name and resets. Smallest next experiment: prove ghat checkpoint completeness, rather than assume it works or assume it cannot.
- `run_test.sh` header offers smoke (~3 min), named scenarios, area sets, and scenario-level `resume`. Model used GHAT filters and benches; no smoke command shown. Three ghat sets do not establish forbidden whole-game retesting.
- `method_watch.py` owns PID/health/deadlines/shutdown. Its header stops on NOT HEALTHY/STALLED/TEST; ordinary FAIL may be collected. Waiting for deliberately planted failure verdicts is not automatically the same breach as letting a dead player walkthrough continue. Plant-tail time is not charged above.
- `live.py` already streams progress, catches errors from `live_run.log`, returns rc. Dry script redirects game to `live_dry.log`, suppresses client stdout/stderr/rc, and adds terminal polling. This disconnects the built-in error channel. `live_restart.sh` already checks parse/script errors during startup; replacement checks only ready.
- LiveControl movement checks cover van/Naresh, not Problem. Its no-Naresh `continue` precedes player-taken event handling. In a ghat without Naresh, deadlines survive but taken detection is skipped. Starting a Monitor tail did not repair this.
- `method_run.sh` refuses a second game. 10:42 still-open failed walk causes refusal; `;` runs proof anyway, creating missing-verdict NOT PROVED. Model deletes spurious last proof row and relaunches. Tester orchestration failure, not a game fault.

## Fixes for every BROKEN rule

Proposals only: no code/tool/other note was changed.

- **R1:** One supervisor aborts actions on first unexpected taken/stall and saves live state/shot before alerting.
- **R2:** Issue registry requires check, named plant failure, clean pass, manifest and ledger links before closure.
- **R3:** Register progress targets for every moving actor; handle global events before missing-actor branches; plant stuck-Problem and missing-Naresh cases.
- **R4:** Controller stop releases throttle, brakes, verifies rest; add slope rollback and lease-expiry checks.
- **R11:** Generate completion text from open issues/cuts; block “only approval remains” with unresolved coverage.
- **R15:** Final path gate rejects layout-critical placement helpers; retain explicitly labeled fast diagnostic cases.
- **R24:** Run ledger displays repeated-prefix minutes and recommends checkpoint retry after two region failures.
- **R26:** Assert both players seated/held-item/parking prerequisites before drive-away, not at end of video.
- **R27:** Debug retry defaults to last failing checkpoint; prove ghat-specific save fields first. Full restart needs recorded reason.
- **R36:** Shared bounded launcher uses correct error log, propagates child rc and emits explicit timeout verdict; short default query timeout.
- **R40:** Source-revision lease: freeze tested checkout; invalidate and stop before edits; build in separate copy.
- **R45:** Completion gate requires real-path command/coverage certificate, including walking and boarding time.
- **R46:** Auto-list failed/untested/skipped checks and active shortcuts in handoff.
- **R52:** Checkpoint hook updates handoff/TODO after every result with exact next command.
- **R54:** Completion check compares LIVE STATUS revision with latest code/test event.
- **R56:** New rough-lesson IDs require sorted LESSONS classification before milestone close.
- **R59:** Keep launcher in repo; changed resume behavior requires version/tradeoff entry and orchestration test.
- **R61:** Patch helper detects newline mode, asserts match count, prints diff; avoid manual exact-match retry.
- **R62:** Project-local completion command derives required note updates from changed systems and rejects stale records.
- **R67:** Generate untested/done/next from issue/run registry, not memory.
- **R73:** Track game-active, encoding, idle, coding overlap and user wait separately while work happens.
- **R75:** Remove duplicate dry runner; share existing watched engine with movie flag and resume default.
- **R79:** Puzzle-walk scope whitelist excludes credits/show features without explicit decision ID.
- **R80:** Preserve old/new method behavior, measured waste and decision owner when runner changes.
- **R86:** Two retries trigger checkpoint diagnostic mode; require justification to repeat whole start.
- **R87:** OPEN regressions block milestone close; scope exception needs explicit user decision.
- **R90:** Preserve stdout/stderr/rc; proof depends on successful clean launch, log identity bound to run ID.
- **R113:** Bench worst-case sight/approach/attack together, and require minimum hide time via actual movement.
- **R118:** Preflight device mapping and verify P2 action readback before recording; cover real one-keyboard mode separately.
- **R139:** Complete minimal bench/repair for pre-existing faults too, or explicit scope exception; never silently drop them from final report.
- **R141:** Test frozen g15 in isolated worktree while building separately; document project-copy exception without premature merge.
- **R142:** Configure project-local scratch/media/memory; distinguish model-chosen paths from unavoidable tool-managed output.

## What went well

- Strong jug bench measured physical state and disproved earlier explanations; broken/fixed comparison was useful.
- Most new ghat faults got named plants, clean passes and ledger entries. Unreachable window proof was challenged instead of waved through.
- Picture review caught lights and abandoned P2; bad take was reported honestly.
- Two-take stop and feature approval boundary respected; genuine new design choices sent as A/B.
- Frequent local commits and rough-note updates. Weakness was incomplete handoff coverage, not no notes at all.
