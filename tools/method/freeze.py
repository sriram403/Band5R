"""Writes tools/method/frozen.json: the final method's policy, limits,
thresholds, required work and scope (M19), from the agreed text
(notes/method_research/final_decisions.md, final_method_draft.md, C1-C4) and
the source at this head. Measured values are passed in with their source run:
  python tools/method/freeze.py [--g3b-tol <m> --g3b-source "<runs>"]
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_manifest  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SETUP = re.compile(r"\b(place_player|look_at_point|face_point|ramp_start|enter_seat|seat_p1_driver|dev_menu\.run|_open_door|\.stow\(|force_exit|_on_joy_changed|global_position = |linear_velocity = )")


def setup_lines(scen):
    src = open(make_manifest.SRC, encoding="utf-8").read().split("\n")
    a = src.index("func t_%s() -> void:" % scen)
    b = next(i for i in range(a + 1, len(src)) if src[i].startswith("func "))
    return ["PlayTest.gd:%d %s" % (i + 1, src[i].strip()) for i in range(a, b) if SETUP.search(src[i]) and "mrec" not in src[i]]


def main():
    args = sys.argv[1:]
    tol = float(args[args.index("--g3b-tol") + 1]) if "--g3b-tol" in args else None
    tol_src = args[args.index("--g3b-source") + 1] if "--g3b-source" in args else "not measured yet"
    fz = {
        "version": "final-2 (2026-11-06: + 4 checks for the exam misses: the leak boils and stops the van, the rewards by the bench, the refitted wheel turns, the van steers straight)",
        "sources": "notes/method_research/final_decisions.md (the user's answers 2026-11-06), final_method_draft.md M1-M21, final_r3_gpt.md C1-C4",
        "policy": {
            "jump_tries": 1,
            "departure": "checks",
            "script_error": "split",
            "headline": "earliest",
            "missing_object": "fail_unresolved",
            "owner_game": "never assigned automatically in this build (owner=UNRESOLVED unless demonstrated)",
        },
        "statuses": {"PASS": 0, "FAIL": 1, "INCOMPLETE": 2, "TEST": 3, "NOT HEALTHY": 4},
        "limits": {
            "poll_s": 0.5, "startup_first_beat_s": 45, "no_beat_s": 20, "no_physics_s": 10, "pause_s": 5,
            "missing_actor_beats": 2, "shot_s": 5, "simple_setup_s": 10, "drive_reset_s": 46, "until_extra_s": 2,
            "door_s": 6, "episode_ramp_s": 240, "episode_c2_more_s": 90, "progress_s": 5, "kill_verify_s": 5,
            "headline_tie_s": 2.0, "whole_run_cap_s": 600,
            "_source": "M3 (GPT r2 D8); door 4 s walk + 2 s; reset wait is until(6) + 2 = 8 s (see final_build.md)",
        },
        "thresholds": {
            "G1_drift_m": 0.30, "G1_window_s": 5.0, "G2_dry_m": 0.30, "G2_out_m": 5.0, "G2_secs": 1.0,
            "G3_sunk_m": -0.12, "G3_parked_s": 0.5, "G4_secs": 0.5, "G4_loose_m": 1.5, "D1_box_m": [1.0, 0.7, 1.2], "D3_secs": 4.0,
            "G3b_tolerance_m": tol, "G3b_tolerance_source": tol_src,
            "_source": "C2Watch.gd constants as built (M7); G3b = clean max norm + 0.01 m, clean max <= 0.01 m (M8)",
        },
        "profiles": {"k0": [62, -0.5], "k1": [64, 0.5], "k2": [66, 0.0], "k3": [80, -0.5], "k4": [80, 0.5], "_source": "M12 (GPT r2 D2)"},
        "required": {
            "ramp": {
                "checks": make_manifest.manifest("ramp"),
                "attempts": 2,
            },
            "c2_more": {
                "work": ["c2.door_walk", "c2.slow_miss_hands_off", "c2.f1_landed_state"],
                "windows": ["G1", "G3", "G3b"],
                "evaluated": ["G1", "G2", "G3", "G3b", "G4", "D1", "D2", "D3"],
            },
        },
        "scope": {
            "claims": "the run was alive, in control and complete; every required check ran and held; where each rule was evaluated, the state was right; P1 crosses the open doorway on W; the reset after a keys-only slow miss holds the van; the scheduled landing landed at the logged speed and lane (one try); the drive-off moved > 30 m and came within 3 m of the road; with a coolant leak the boiling engine is stopped before the gap; the rewards lie by the bench; after the fix the refitted wheel turns and the van adds no steering of its own",
            "declared_setup": [
                "the sight-line placements before the jump", "the hut stretch's placements (P1 under the window, by the crate, on the crate; P2 in the river and behind)",
                "the wheel set by the hub (w.global_position = ...)", "look_at_point cameras",
                "c2_more's F1 jump, door setup and P2 put in the river"],
            "declared_setup_lines": setup_lines("ramp") + setup_lines("c2_more"),
            "not_proven": [
                "that a player can reach the placed spots", "two-player hut completion between them", "what a player sees (observer pictures only, R2)",
                "a landing-only bug via F1 (R13)", "why a 66.5 km/h jump sometimes misses", "speeds under the slowest landed profile",
                "that the van drove away along the road, or where it stopped (M10)", "'floating above the ground' beyond G3b's attachment",
                "tyre attachment beyond the four visible tyres' centres", "secret bugs no rule, check or deadline looks at", "fun", "any whole-game result"],
        },
    }
    out = os.path.join(ROOT, "tools", "method", "frozen.json")
    json.dump(fz, open(out, "w", encoding="utf-8", newline="\n"), indent=1)
    print("wrote %s: %d ramp checks, %d setup lines, G3b tolerance %s" % (out, len(fz["required"]["ramp"]["checks"]), len(fz["scope"]["declared_setup_lines"]), tol))


if __name__ == "__main__":
    main()
