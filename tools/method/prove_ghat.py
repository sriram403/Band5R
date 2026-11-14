"""Prove #6's checks against their planted bugs (FINAL.md port step 8).

Each group runs tools/method_run.sh ghat with FIXTURE=<plants> and GHAT=<scenarios> under its own
invocation id, then judges ONLY that invocation's receipt (fix round, GPT's blocker 3):
  - the invocation's one requested part ran (its run folder named in the receipt, its run_info
    bound to this invocation and part), its verdict is sealed (verdict.txt whole, verdict.json
    present and bound to the same invocation / part), the run asked exactly the group's scenarios
    with exactly the group's plants, and the game is checked gone (kill verified or the wrapper
    exited; no Godot of the lane left);
  - each plant is PROVED only by ITS OWN exact ids (manifest check ids, rule ids) among the run's
    FAILed ids; a batched plant whose own id is absent is NOT PROVED, whatever else failed;
  - an early stop counts only if every expected id of the group was on record before it.
No substrings, no folder globbing. Groups only combine plants that can't mask each other.
Usage: python tools/method/prove_ghat.py [group ...]   (no names: all)
       EARLY=1 SPEED=fast python tools/method/prove_ghat.py looks   (T1 / T2, speed research)
Output: appdata/method/prove_ghat.txt (one line per plant), plus each run's folder.
"""
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "appdata", "method", "prove_ghat.txt")
INVS = os.path.join(ROOT, "appdata", "method", "inv")

# group: (scenarios, plants, {plant: [its own exact ids: manifest check id or rule id]})
GROUPS = {
    "heat_always": ("ghat_heat", "heat_always,one_corner", {"heat_always": ["ghat_heat/x_no_heat_or_leak_from_it_before_it_sees_the_van_x_c_x_l_min", "H1"]}),
    "stall_hud": ("ghat_heat", "no_stall_drag,hud_heat,one_flat", {"no_stall_drag": ["ghat_heat/x_it_comes_to_rest_before_the_pass_in_the_fog_sample_x_of_x_"],
                                                                     "hud_heat": ["ghat_heat/x_hot_with_it_watching_no_temp_cool_bars_no_engine_hot_banne"]}),
    "fog_h2_keep": ("ghat_heat", "fog_short,seen_h2,keeps_interest,one_corner", {"fog_short": ["ghat_heat/x_the_fog_lies_all_the_way_up_to_the_pass_to_sample_x_of_x"],
                                                                                   "seen_h2": ["ghat_heat/x_the_heat_alone_boils_it_the_pass_guard_not_needed"],
                                                                                   "keeps_interest": ["ghat_heat/x_once_it_gives_up_the_heat_and_the_leak_stop_x_x_c_fuel_x_x"]}),
    "looks": ("ghat_looks", "lean_close,fast_turn", {"lean_close": ["ghat_looks/leaning_in_at_a_window_its_face_stays_outside_the_glass_clos"],
                                                     "fast_turn": ["ghat_looks/it_turns_away_slowly_fastest_x_deg_s"]}),
    "net": ("ghat_net", "one_layer_net", {"one_layer_net": ["ghat_net/from_outside_nothing_of_the_van_shows_through_the_net_bright"]}),
    "jug_a": ("ghat_jug", "leave_sees,no_breath_lock,round_skip", {"leave_sees": ["ghat_jug/out_beside_it_after_it_gave_up_nobody_is_taken"],
                                                                     "no_breath_lock": ["ghat_jug/holding_your_breath_ctrl_b_never_touched_the_handbrake"],
                                                                     "round_skip": ["ghat_jug/it_went_all_round_the_van_before_it_gave_up_x_stops"]}),
    "jug_b": ("ghat_jug", "no_fix,free_coolant,needle_stuck", {"no_fix": ["ghat_jug/cool_now_it_pours_in_the_radiator_is_full_again_x"],
                                                                 "free_coolant": ["H3"], "needle_stuck": ["H2"]}),
    # the old text "over the pass" matched two checks (the objective one too): the plant's own is this one
    "jug_c": ("ghat_jug", "no_power", {"no_power": ["ghat_jug/over_the_pass_x_s_x_c"]}),
    "spring_a": ("ghat_spring", "seat_compare,cap_text", {"seat_compare": ["ghat_spring/both_windows_visited_p1_prompt_x_held_x_p2_fogged_x"],
                                                          "cap_text": ["ghat_spring/at_the_bonnet_still_hissing_open_the_radiator_cap"]}),
    "spring_b": ("ghat_spring", "endless_window", {"endless_window": ["ghat_spring/quiet_at_last_it_gives_up_restarts_x"]}),
    "marks": ("ghat_looks,ghat_marks", "marks_pile,marks_unsaved", {"marks_pile": ["ghat_marks/a_clean_van_to_start_with"],
                                                                     "marks_unsaved": ["ghat_marks/the_marks_are_saved_and_come_back_on_load_x"]}),
    # qual round 2 (D2, option A): each batched member alone, against its own exact ids
    "solo_fast_turn": ("ghat_looks", "fast_turn", {"fast_turn": ["ghat_looks/it_turns_away_slowly_fastest_x_deg_s"]}),
    "solo_leave_sees": ("ghat_jug", "leave_sees", {"leave_sees": ["ghat_jug/out_beside_it_after_it_gave_up_nobody_is_taken"]}),
    "solo_no_breath_lock": ("ghat_jug", "no_breath_lock", {"no_breath_lock": ["ghat_jug/holding_your_breath_ctrl_b_never_touched_the_handbrake"]}),
    "solo_round_skip": ("ghat_jug", "round_skip", {"round_skip": ["ghat_jug/it_went_all_round_the_van_before_it_gave_up_x_stops"]}),
    "solo_marks_pile": ("ghat_looks,ghat_marks", "marks_pile", {"marks_pile": ["ghat_marks/a_clean_van_to_start_with"]}),
    "solo_marks_unsaved": ("ghat_looks,ghat_marks", "marks_unsaved", {"marks_unsaved": ["ghat_marks/the_marks_are_saved_and_come_back_on_load_x"]}),
}

# qual round 2 (GPT: marks' looks prelude): ids that must have PASSED in the same run before a plant's
# FAIL counts. marks_pile is caught only if the looks prelude left marks on the van (its round); a
# prelude that made no round (T1 run 9) is "prerequisite not met", never a NOT PROVED or a PROVED.
PREREQ = {"marks_pile": ["ghat_looks/it_goes_round_the_van_stopping_at_the_bonnet_both_windows_an"]}


def rd(p):
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def judge(invd, scen, plants, expect):
    """-> (run-level problem or "", run dir or "", {plant: (PROVED?, why)}) from one invocation's receipt only."""
    inv = os.path.basename(os.path.normpath(invd))
    exp = [ln.split("\t") for ln in (rd(os.path.join(invd, "expected")) or "").splitlines() if ln.strip()]
    prob, d, vj = "", "", None
    if len(exp) != 1:
        prob = "the invocation requested %d parts (a proof needs exactly 1)" % len(exp)
    else:
        part = exp[0][0]
        d = (rd(os.path.join(invd, part + ".dir")) or "").strip()
        info = rd(os.path.join(d, "run_info.txt")) if d else None
        v = rd(os.path.join(d, "verdict.txt")) if d else None
        vj = json.loads(rd(os.path.join(d, "verdict.json")) or "null") if d else None
        lines = [ln for ln in (v or "").splitlines() if ln.strip()]
        if not d:
            prob = "no run (%s)" % ((rd(os.path.join(invd, part + ".refused")) or "no receipt").strip())
        elif (info or "").splitlines()[:1] != ["inv %s part %s" % (inv, part)]:
            prob = "wrong run: %s is not this invocation's" % d
        elif not lines or not lines[-1].strip().startswith("Evidence: ") or vj is None:
            prob = "verdict not sealed (verdict.txt not whole or verdict.json missing)"
        elif vj.get("inv") != inv or vj.get("part") != part:
            prob = "verdict.json bound to %s/%s, not %s/%s" % (vj.get("inv"), vj.get("part"), inv, part)
        elif vj.get("asked") != scen.split(","):
            prob = "ran %s, the group is %s" % (vj.get("asked"), scen)
        elif sorted(x for x in vj.get("fixture", "").split(",") if x) != sorted(plants.split(",")):
            prob = "fixture '%s', the group's plants are '%s'" % (vj.get("fixture"), plants)
        elif vj.get("status") == "PASS":
            prob = "the run PASSED"
        elif vj.get("godot_left_after") or (vj.get("kill") and not vj.get("kill_ok")) or vj.get("wrapper_rc") is None:
            prob = "the game is not checked gone (left %s, kill_ok %s, wrapper rc %s)" % (vj.get("godot_left_after"), vj.get("kill_ok"), vj.get("wrapper_rc"))
        elif vj.get("early_stop") and not all(x in vj.get("failed_ids", []) for ids in expect.values() for x in ids):
            prob = "early stop before every expected id was on record"
    rows = {}
    have = set(vj.get("failed_ids", [])) if vj and not prob else set()
    for plant, ids in expect.items():
        miss = [x for x in ids if x not in have]
        pre = [x for x in PREREQ.get(plant, []) if x not in set(vj.get("passed_ids", []) if vj else [])]
        if prob:
            rows[plant] = (False, prob)
        elif pre:
            rows[plant] = (False, "prerequisite not met (rerun, not a verdict): %s" % ", ".join(pre))
        elif miss:
            rows[plant] = (False, "its own id(s) not FAILed: %s" % ", ".join(miss))
        else:
            rows[plant] = (True, " + ".join(ids))
    return prob, d, rows


def run(name):
    scen, plants, expect = GROUPS[name]
    inv = "prove_%s_%s_%d" % (name, time.strftime("%Y%m%d_%H%M%S"), os.getpid())
    env = dict(os.environ, GHAT=scen, FIXTURE=plants, INV=inv, ROLE="proof")   # T3 v2: run_meta role
    env.pop("EXPECT_FAIL", None)
    # T2: EARLY=1 stops the run once every expected id of the group has FAILed (exact ids)
    if os.environ.get("EARLY"):
        env["EXPECT_IDS"] = "|".join(x for ids in expect.values() for x in ids)
    print("== %s: %s with %s (invocation %s)" % (name, scen, plants, inv), flush=True)
    subprocess.run(["bash", os.path.join(ROOT, "tools", "method_run.sh"), "ghat"], cwd=ROOT, env=env)
    prob, d, rows = judge(os.path.join(INVS, inv), scen, plants, expect)
    head = (rd(os.path.join(d, "verdict.txt")) or "no verdict").splitlines()[0] if d else "no verdict"
    with open(OUT, "a", encoding="utf-8") as f:
        for plant, (ok, why) in rows.items():
            r = "%-15s %-11s %s  (%s)  inv %s run %s" % (plant, "PROVED" if ok else "NOT PROVED", why, head, inv, os.path.basename(d) if d else "-")
            f.write(r + "\n")
            print(r, flush=True)


if __name__ == "__main__":
    for g in (sys.argv[1:] or list(GROUPS)):
        run(g)
