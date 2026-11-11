# T4 v2 — stop, safe repair paths, recording

2026-11-11. GPT design only; Claude builds/runs. Companion: `trial_T3_spec_v2.md` owns hashes, lanes, full replay budget and stop rules. Common lean core, with unresolved resume/clean-walk choices in `answer_specs_gpt.md`. No game/code written or run by GPT.

## Scope

Referee-supplied D:-only trial checkout, tools/dev probes only during qualification. No gameplay/scene/assets/Plant edits, secret reading, extra checkout, merge or push. Reuse `LiveControl`, play/record wrappers and small independent point/gate reducer. **No section graph or watch-budget restore.** Builder may add the minimum test-side observation/cancellation and Markdown report needed; report changed files/interfaces and deviations. Keep all artifacts/temp on D:, mute live speakers, preserve encoded audio and background windows.

## Walk and identity

The baseline has one real ghat entry. Start discovery fresh; first FAIL stops it, all later steps BLOCKED. The seven reset-based scenarios provide independent diagnostic views, not passed walk coverage. Repair resumes may use only qualified same-input points; otherwise replay the real prefix. Never patch promised state or bypass a break. Before recording, a repaired walk must have reached its end through valid producer paths; charge the tail/prefix work to T3's 19-min provisional allocation.

Point IDs are immutable, last-fail references an ID, and parts keep their source IDs. Reuse T3 game-tree/binary hashes plus walk/schema/profile/tool identities. Same game hash is required for a join; incompatible producer/action/test changes invalidate gate evidence. Do not overwrite a point used by a take, retag an old point after a fix, or join old-game prefix to fixed-game suffix. Unsupported point -> refuse before inputs and identify earlier real producer/fresh path. Full input identity is retained for accepted receipts.

## Pieces and controls

Every mutation has a corrected paired control. Offline reducers validate evidence only; live claims need live evidence.

| Piece | Acceptance control |
|---|---|
| First-failure cancellation | Helper cancellation generation/flag checked after awaits and before input sends; release keyboard/mouse/pad before bounded failure capture. Live: deliberately fail while breath/helper holds input, then advance long enough to show no subsequent input reappears; clean helper completes and releases. Preserve first FAIL, scoped exit, BLOCKED suffix. |
| Immutable identity | Offline old-game, changed walk/schema/profile/binary, wrong point and missing part refuse; compatible immutable point admits only to gate evaluation, not automatic SAME. |
| Scoped field inventory | Enumerate script fields of Ghat, Problem and relevant children, Camper/VanAttack, both players and carryables, plus van physics and relevant reference/visual/audio state. Each field is saved/rebuilt/refused with evidence; independent live observation, not a copy of serializer output. Offline remove engine and child observation -> refused. No unsupported relevant state may be silently accepted. Broader hidden-state treatment remains D4; a boundary relying on that disputed omission stays UNQUALIFIED. |
| Refusal instead of engine adapter | Refuse engine-on or >0.1 m/s van boundaries up front; immediate comparison also refuses any lost residual/angular velocity or physics state. Live engine-on point -> refused/DIFFERENT, clean stopped eligible point -> evaluate normally. No new van save adapter unless separately agreed after a needed boundary proves unavailable. |
| Refusal instead of hearing rebase | Recent (<2 wall s) item/hearing activity, unconsumed queue events, inconsistent listener serials or unresolved knock debounce block boundary. Age alone is insufficient: queue pruning is on emit. Normalize old `_item_ms` to unset only when expiry/no-pending-event semantics are established; else refuse. Offline recent event, old-but-unconsumed event and stale-origin timestamp refuse; fully quiet/consistent control matches predicates. T1 owns actual fast/normal hearing and knock qualification. |
| No open work at boundary | Nonempty open-watch/needs list, running helper or held inputs -> refused, including after future walk edits. Offline one watch/active helper refuses; empty list alone does not imply all other layers passed. No watch-budget restoration implementation. |
| Owner-built director / observed children | Use real `_spawn_problem` owner path for director and verify resolved references. Independently observe child transform/pose, eye emission, hum state/pitch and relevant timers. Offline omitted/changed child/reference -> DIFFERENT; clean reconstruction matches. If it cannot, refuse; no generic Callable serializer. |
| Immediate comparison (layer 2) | Observe synchronously after restore, before any await/tick or h1's 1s settling wait. Exact lossless semantic equality, normalize only documented volatile process metadata. Offline engine/velocity/child/clock mutation names a difference. Live clean round trip proves comparison runs before settling; live engine case above detects loss. |
| Trajectory rejection (layer 3) | Fresh reference at +3 game s while actual actions execute, matched inputs/event order/discrete state and complete next-step expects. One live post-immediate +0.2m actor perturbation must produce DIFFERENT; offline wrong discrete/event/delayed-input and identical-wrong-resume traces reject against fresh. No grace from a matching pair of wrong restores. Positive resume count/tolerances await D3. |
| 25-fps recording profile | Short known-sound clean clip and just-late unchanged-deadline fixture at fixed 25; correct physics-time accounting, named late rejection, helper release and verified exit. Decode/check known captured sound. Repeat throughput test with isolated second game, checking step/capture quality and actual recording slowdown. |
| Small join verifier | Exact point/part hashes, profile, passed prefix/suffix, actual trimmed ffprobe durations, no missing/duplicated actions. Prove drawn-frame-to-movie-frame mapping before using old cut indices, else refuse. Offline wrong-game, absent part and invalid range refuse; compatible short join has inspected frames on both sides and accurate cumulative time. No large validator framework or silent-audio mutation suite. |
| Whole video watch | After game exit watch full result with sound; timestamp required moments, every join and both views. Missing sound/view/action stays INCOMPLETE. Adjacent frame pairs supplement full watch. |

## Gate limits and unresolved optimizations

Layer 1 is an independent saved/rebuilt/refused inventory. Layer 2 is exact immediate equality. Layer 3 is fresh-versus-resume trajectory plus unchanged next-step outcomes; discrete outcomes/event order match exactly and continuous tolerances cannot cross a check/reach/collision margin. Record field names, units and explicit bounds before trials. T1 scenario-summary spreads alone do not establish these walk/recording tolerances.

Both auditors accept these three layers and refusal on known differences. They do **not** yet agree on dropping hidden-state classes (D4) or replacing two resumes by one using T1 spread (D3). This spec does not authorize either contested acceptance shortcut. A cheap single resume may reject a point. Until the positive rule is agreed, do not call a new point SAME based on that shortcut; use an already jointly qualified boundary, or real fresh prefix. Recording-profile gates need recording-profile evidence; 60-fps rehearsal is insufficient.

Refusal is a valid tool result, not game PASS and not permission to fabricate a setup. A +3 snapshot can miss delayed consequences; record that finite evidence limit. No universal save-system or RNG/contact/coroutine adapter is requested. If a useful point needs one, report its refusal and cost instead of expanding scope silently.

## Fresh take and joined video

Keep 1600x900 fixed-25 Movie Maker with sound; normal drawing, no fast/nodraw. Preserve all baseline actions/assertions/deadlines and both players' jobs. List baseline placement helpers/credits calls honestly; they do not prove actual reachability. No added setter/teleport may replace a required failing real-input behaviour. Any added movement coverage is reported and timed.

Recommended common path: **one uninterrupted fresh clean recording** supplies both clean-walk and video evidence. On failure, cancel/stop immediately, inspect current picture, retain failed take and repair evidence; do not idle while reasoning. Game fixes invalidate old-game clean parts. Same-game joined video is allowed by the user's choice, only after gates and cuts pass; whether this also certifies the clean walk is still D1. Pending that decision, joined-only evidence does not settle completion.

For each join provide `MM:SS.mmm -> step, source part, gate ID` plus raw trimmed ranges/durations, identities, full video path/hash and inspected frame pair. Exclude failed step from retained prefix. No skipped/duplicated required actions or unexplained time reversal. Whole watch includes readable note/HUD, both views, net inside/outside, approach/lean/turn/sniff, cap event, spring carry/pour, restart/pass, marks/credits and captured sound, with times and judgement.

## Qualification and budget

Offline controls first, then short live cancellation, engine refusal/roundtrip/trajectory and movie clips. Share a real short point for offline mutations; do not replay a long prefix for every JSON mutation. Target **7 game min + 3 reserve**, **hard stop 15 T4**. This is a planning envelope, not measured feasibility. Encounter/recording boundary qualification may not fit; report it UNQUALIFIED and charge fresh prefixes during replay. No 21-boundary qualification sweep. T3 sentinel work is charged to T3; recording contention to T4, once only.

Whole replay budget is T3 v2: **~74–84 serial; ~64–75 only if two-slot measurements demonstrate 9–10 net minutes saved**. The 11-game-minute recording estimate implies 12.6–16.2 wall min at measured 68–87% throughput. More attempts, real movement additions, unqualified boundaries or an extra fresh walk after joined footage increase that figure. Report edits/encoding/watching time separately; full watch is not free user time merely because it costs zero game score.

Before each run state expected minutes and remaining cap; watch every few seconds, stop off-plan, retain picture/evidence and verify scoped process exit. Use a bench after repeated failed fixes, no rerun-until-green. Stop if required remaining replay work projects beyond 75, or qualification reaches its hard cap. No weaker threshold or dropped check to fit the budget.

Builder report: changed files/interfaces and deviations; all clean/negative controls and actual commands/evidence IDs; qualification meter union/sum; field refusal/inventory record; immediate/trajectory observations and outcomes; any qualified boundary's profile/tolerance proof; original blocked failures; actual prefixes/tails and recording throughput alone/overlap; final fresh receipt or unresolved D1 status; video path/hash, join times, full sound-watch timestamps; all incomplete work and referee decisions. No newly noticed benchmark-hole details in tool commits intended for the blind replay.
