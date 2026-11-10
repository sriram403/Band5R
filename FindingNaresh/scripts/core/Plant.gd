class_name Plant
extends RefCounted

## Planted bugs, for proving #6's checks (the test method, notes/method_research/
## FINAL.md port step 8: every check is seen to FAIL on its bug and PASS on the
## clean game). Test only: every plant is off unless the game is started with
## --method-fixture=<name>[,<name>...] (tools/method_run.sh FIXTURE=...). The
## game reads them only at the line each plant breaks; nothing judges by them.
##   heat_always     the van heats even when nothing is interested
##   fog_short       the fog ends 40 m short of the pass (as before #6)
##   seen_h2         Problem watches from hairpin 2 (the user's first ask)
##   hud_heat        the TEMP / COOL bars and "ENGINE HOT" stay up with it watching
##   lean_close      it leans in at the windows from 2.0 m: its face goes through the glass
##   fast_turn       giving up, it sets off before it has turned away
##   round_skip      under the net it gives up without going round the van
##   one_layer_net   the net is one see-through layer (the glass shows through)
##   keeps_interest  once it gives up it stays interested (the heat and leak go on)
##   no_fix          pouring water / coolant never clears "boiled dry"
##   no_power        after the fix the engine has no pull (it never gets over the pass)
##   seat_compare    hold-your-breath looks for a seat equal to the van (never matches)
##   endless_window  every window visit that gives you away restarts its search
##   leave_sees      once it gives up it still sees and takes people
##   no_breath_lock  B (the pad's handbrake) toggles the handbrake while you hold your breath
##   cap_text        the radiator's status text hides "Open the radiator cap"
##   marks_unsaved   the van's marks aren't saved
##   marks_pile      a jump back to the ghat keeps the old marks
##   needle_stuck    the dash's temperature needle stays put (GhatWatch H2)
##   free_coolant    coolant creeps up by itself during the encounter (GhatWatch H3)
##   stow_live       a stowed item stays a live body (left behind by a van stowed while awake)
##   tail_flush      the tail lights sit flush with the back doors (they flicker in and out)
##   no_listen       after the hot cap's yelp it comes straight back, no listening first
##   hold_through    holding on after the net is on starts pulling it back off
##   round_through   on its round it walks straight at a stop across the van (and sticks)
##   no_min_warn     when the van stops it walks on and comes at once, however close
##   fog_sees_far    in the ghat's fog it still sees people from ~40 m
## Not bugs, the planted runs' time savers (test only): one_flat / one_corner
## run ghat_heat at one driving profile.

static var _names := {}
static var _read := false


static func on(name: String) -> bool:
	if not _read:
		_read = true
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--method-fixture="):
				for n in a.get_slice("=", 1).split(","):
					_names[n.strip_edges()] = true
	return _names.has(name)
