# The final method: what gets built (Stage 4, after round 3)

Written by the referee, 2026-11-06. The build text is **`final_method_draft.md`** (Claude 3a), with
**GPT's corrections C1-C4** (`final_r3_gpt.md`) applied, and the **user's answers** on the points
still held after three rounds. Neither auditor has signed the whole yet: both sign `FINAL.md` after
the exam (the brief).

## The user's answers on the held points (2026-11-06)
Each question was put with both auditors' cases in their own terms; the referee's suggestion followed
the scoreboard's decision rules (a false pass weighs more than a false alarm; S2 "named" means the
broken thing, not a symptom three steps later).
| Point | The user chose | Side | `tools/method/frozen.json` |
|---|---|---|---|
| M11 flat-out jump | **one try**: a missed flat-out jump makes the route INCOMPLETE (owner unresolved); every attempt printed | GPT (Option G) | `jump_tries: 1` |
| M10 drive-off | **today's two checks as the departure receipt; "drove away along the road / where it stopped: NOT PROVEN"**; a missing receipt = INCOMPLETE at the drive-off, owner unresolved | Claude (Option C) | `departure: "checks"` |
| M6 script error | **split by where it was raised**: `scripts/dev/` -> TEST; game code -> FAIL: script error at <file:line>, owner UNRESOLVED; no backtrace -> owner UNRESOLVED; always vetoes PASS | Claude (Option C) | `script_error: "split"` |
| M15 headline | **the earliest non-pass condition by when it began**; within 2 s: NOT HEALTHY > TEST > FAIL > INCOMPLETE; preflight TEST first; every later condition listed with its time | Claude (Option C) | `headline: "earliest"` |
| M5 missing field vs object | settled in 3b: **GPT's correction C2 wording** (a missing/invalid read = TEST; a validly observed absent required object = FAIL, owner UNRESOLVED) | agreed | `missing_object: "fail_unresolved"` |

## GPT's corrections, applied as written in `final_r3_gpt.md`
- **C1** (M1 overview wording: the route has declared setup; receipts, not scheduling, establish coverage).
- **C2** (M5, above).
- **C3** (M14: the TEST row's owner is `owner=TEST` only for demonstrated test causation, else `owner=UNRESOLVED`; TEST means the proof is invalid, not that the game is innocent).
- **C4** (M19: the selected policies are the user's answers above; **if M6 C or M15 C can't fit the hour, report it unimplemented / unqualified: do not substitute Option G**; N5 must be qualified on the real draw-await stall or an equivalent with physics live, process gone).
  This replaces the draft's cut items 2 and 4. The other cuts (1, 3, 5) stand.

## Build cost
Draft estimate 60 min on the defaults; the user's three C picks add M6 +3, M15 +3, M5 +1 (draft
estimates) -> ~67 min against the ~60 cap. The cut order: 1 `FN_RECORD` wiring, then 3 the tyre half of
G3b (tyres NOT PROVEN, the hub stays), then 5 q3 (only if every fixture is flag-only). M6 C / M15 C
are not cut into G (C4); if they don't fit they're reported unimplemented.

## A fact corrected by the referee (for FINAL.md)
The draft's "drive-off failed 2 of 9 clean landings" counts c1's runs only. Across every clean full
`t_ramp` run in the research: **3 of 20 landings failed the drive-off** (c1 2 / 9, c2's S1 0 / 8, g2's
baseline 1 / 3: B3, not mentioned in `trial_g2.md`). The draft's S1 percentages are illustrative.
