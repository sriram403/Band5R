class_name Ghat
extends Node

## D10, the ghat hairpins (design/WAY_OUT.md 18:00, W7): fog comes down on
## the hairpins; the nav swung to the passenger shows rally pace notes worked
## out from the road's own bends (the driver sees only fog). #6 (2026-11-09):
## on the second hairpin the first Problem sees the van, and the van heats
## and leaks until it boils before the pass; tarp it, hide, keep quiet until
## Problem gives up, then coolant (on board, or water from a spring) and on.

const FOG_EASE := 0.25           ## fog boost per second in and out
const NOTES_AHEAD := 260.0       ## m of road the pace notes read ahead
const TURN_MIN := 4.0            ## deg per 10 m that counts as a bend
const GLIMPSE_AT := 40.0         ## m along the road before its hairpin when it shows
## Which hairpin it watches from (0 = the first). The user asked for the
## second; from there only ~170 m of road is left to the pass, too short for
## the needle to climb by itself (measured 2026-11-09), so Q1 B: the first,
## pending the user's answer.
const SEEN_HAIRPIN := 0

var road: Route
var hairpins: Array[int] = []    ## sample index of each hairpin's apex, from J3 up
var fog_from := 0                ## samples between these are in the fog
var fog_to := 0
var fog := 0.0                   ## 0..1, what the mood is showing
var on_ghat := false
var glimpse: Creature = null     ## (old tests) always null now: Problem is the one
var attacker: Creature = null    ## (old tests) the same node as `problem`
var _builder
var _story
var _check_t := 0.0


func setup(b) -> void:
	add_to_group("ghat")
	_builder = b
	road = b.network.road("ghat_road")
	_find_hairpins()
	fog_from = maxi(0, (hairpins[0] if not hairpins.is_empty() else 0) - 75)
	fog_to = road.point_count() - 3      # #6: up to the pass, where the van may die
	b.poi["ghat_fog"] = road.point((fog_from + fog_to) / 2)
	for k in hairpins.size():
		b.poi["hairpin_%d" % (k + 1)] = road.point(hairpins[k])
	# #6 L4: three springs on the hill (none over ~80 m behind any breakdown),
	# Naresh's note on a milestone stone before the bend where it watches
	for k in SPRINGS.size():
		_build_spring(b, SPRINGS[k], k + 1)
	_build_milestone(b, MILESTONE_AT)


## Apexes of the bends that turn more than 140 degrees.
func _find_hairpins() -> void:
	for c in _corners(0, road.point_count() - 1, 1):
		if absf(c["turn"]) > 140.0:
			hairpins.append(c["apex"])


## The bends from sample `from` towards `to` (step +1 or -1): each with its
## start, apex, end, total turn (deg, + = left) and tightest radius at the
## start and end halves.
func _corners(from: int, to: int, step: int) -> Array:
	var out: Array = []
	var i := from
	var cur: Dictionary = {}
	while (step > 0 and i < to - 5) or (step < 0 and i > to + 5):
		var a := road.forward(i) * float(step)
		var b := road.forward(i + 5 * step) * float(step)
		var turn := rad_to_deg(a.signed_angle_to(b, Vector3.UP))      # over 10 m
		if absf(turn) >= TURN_MIN:
			if cur.is_empty() or signf(turn) != signf(cur["turn"]):
				if not cur.is_empty():
					out.append(cur)
				cur = {"start": i, "apex": i, "end": i, "turn": 0.0, "peak": 0.0, "first": absf(turn), "last": absf(turn)}
			cur["turn"] = float(cur["turn"]) + turn * 0.2         # samples overlap 5 steps
			cur["end"] = i
			cur["last"] = absf(turn)
			if absf(turn) > float(cur["peak"]):
				cur["peak"] = absf(turn)
				cur["apex"] = i
		elif not cur.is_empty():
			out.append(cur)
			cur = {}
		i += step
	if not cur.is_empty():
		out.append(cur)
	return out.filter(func(c): return absf(c["turn"]) > 12.0)


## Rally grade from the sharpest part of a bend (deg per 10 m): 6 is a kink, 1
## is nearly a hairpin.
static func grade(peak: float) -> int:
	# radius = 10 m / turn in radians
	var r := 10.0 / deg_to_rad(maxf(peak, 0.1))
	if r > 150.0:
		return 6
	if r > 100.0:
		return 5
	if r > 65.0:
		return 4
	if r > 40.0:
		return 3
	if r > 22.0:
		return 2
	return 1


## What the swung nav shows on the ghat: the next two bends and how far.
func pace_notes(van: Camper) -> String:
	if not on_ghat or not van.nav_aside:
		return ""
	var near: Dictionary = road.nearest(van.global_position.x, van.global_position.z)
	var i: int = near["index"]
	var step := 1 if van.global_transform.basis.z.dot(-road.forward(i)) > 0.0 else -1
	var end := clampi(i + step * int(NOTES_AHEAD / Route.SAMPLE_SPACING), 0, road.point_count() - 1)
	var lines: Array[String] = []
	for c in _corners(i, end, step):
		var dist := absf(float(int(c["start"]) - i)) * Route.SAMPLE_SPACING
		var t := float(c["turn"])
		var side := "LEFT" if t > 0.0 else "RIGHT"
		var what := "%s HAIRPIN" % side if absf(t) > 140.0 else "%s %d" % [side, grade(float(c["peak"]))]
		if float(c["last"]) > float(c["first"]) * 1.5 and absf(t) <= 140.0:
			what += " TIGHTENS"
		if absf(t) > 140.0:
			what += "\n    DON'T CUT"
		var at := "NOW" if dist <= 6.0 else "%3d" % (roundi(dist / 10.0) * 10)
		lines.append("%s  %s" % [at, what])
		if lines.size() >= 2:
			break
	if lines.is_empty():
		lines.append("     STRAIGHT")
	return "\n".join(lines)



# --- Problem: #6's encounter (design/PUZZLE_CHANGES.md #6, agreed 2026-11-09) ---
# At the second hairpin a tall figure among the trees turns its head to
# follow the van: it has seen you. From then the van heats and leaks (the heat
# rule, VanAttack) wherever you drive, harder driving hotter, until it boils
# before the pass. Problem follows up through the fog, steps out onto the road
# behind and walks up; it circles the van. Under the tarp, kept quiet, it
# searches a while and gives up: then, only then, the needle and the drip stop.
# Every noise it hears restarts its search (more coolant boiled away).

const WATCH_S := 2.5             ## s it stares (eyes brightening) before it has "seen" the van
const FOLLOW_SPEED := 1.6
const COME_FROM := 45.0          ## m behind the stopped van it steps out of the trees, if further
const COME_SPEED := 1.8
const CIRCLE_R := 6.0            ## m from the van's middle while it circles
const CIRCLE_SPEED := 1.1
const SEARCH_S := 25.0           ## s of quiet at the tarped van before it gives up
const LEAVE_SPEED := 1.0
const PASS_GUARD := 25           ## samples (50 m) before the pass: interested, it boils there at the latest
const STOP_S := 2.0              ## s stopped (engine off) before it comes
const STATION_S := 3.5           ## s it stays at each stop round the van
const POSED_STOPS := 4           ## stops of its round with a pose (bonnet, two windows, back)
const SPRINGS := [268, 304, 342] ## road samples of the spring pipes: one within 80 m back of anywhere past 268 (breakdowns measured at 291-319)
const MILESTONE_AT := 205        ## road sample of the milestone with Naresh's note (before hairpin 1)
const FILL_RATE := 0.5           ## L a second from a spring pipe
const BREATH_S := 8.0            ## s you can hold your breath
const BREATH_GRACE := 1.2        ## s after it leans in before your breathing shows
const SLUMP_S := 3.0             ## s it stands slumped, turning away, before it walks off
## Its round of the van, in the van body's frame (nose -Z): [where it stands,
## what it looks at, pose]; pose "" = just walking past the corner.
const ROUND := [
	[Vector3(0, 0, -5.4), Vector3(0, 1.4, -3.9), "lean"],          # the bonnet
	[Vector3(-2.4, 0, -4.6), Vector3.ZERO, ""],
	[Vector3(-2.6, 0, -1.6), Vector3(-1.2, 1.9, -1.8), "lean"],    # the driver's window (its face stops short of the glass)
	[Vector3(-2.4, 0, 4.3), Vector3.ZERO, ""],
	[Vector3(0, 0, 4.9), Vector3(0, 0.9, 3.4), "crouch"],          # the back, low: sniffing
	[Vector3(2.4, 0, 4.3), Vector3.ZERO, ""],
	[Vector3(2.6, 0, -1.6), Vector3(1.2, 1.9, -1.8), "lean"],      # the passenger's window
	[Vector3(2.4, 0, -4.6), Vector3.ZERO, ""],
]

var problem: Creature = null
var phase := ""                  ## "", watch, follow, come, circle, leave
var phase_t := 0.0
var quiet_t := 0.0               ## s of quiet at the tarped van (tests read it)
var search_restarts := 0         ## noises that restarted its search (tests read it)
var seen_index := -1             ## road sample where it saw the van
var boil_index := -1             ## road sample where the van boiled
var guard_fired := false         ## the pass guard had to boil it (tests read it; should stay false)
var _stopped_t := 0.0
var _leave_to := Vector3.ZERO
var springs: Array[Node3D] = []  ## the spring pipes' roots (tests read them)
var pots: Array = []             ## the steel pots, one at each spring
var breath_state := ""           ## "", wait, holding, fogged, gasped, done (tests read it)
var breath := 1.0                ## 0..1 of a held breath left
var breath_p: PlayerRig = null   ## the player at the window it leans in at
var breath_events := 0           ## times breathing or a gasp gave you away (tests read it)
var _window_t := 0.0
var _windows_given := {}         ## windows that gave you away this encounter
var _cap_blows_seen := 0
var stops_done := 0              ## posed stops of its round since its search last (re)started
var encounter_no := 0            ## which encounter this is (marks are tagged with it)
var _marked := {}                ## stops of its round that left a mark this encounter
var _fuel_at_seen := 0.0         ## the van as it was before it saw you (a save mid-encounter)
var _coolant_at_seen := 1.0
var stop_k := 0                  ## which stop of its round it's at (tests read it)
var at_stop := false             ## standing at that stop now (tests read it)
var _stop_t := 0.0
var _fog_target := 0.0
var _van_i := 0


func _physics_process(delta: float) -> void:
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van == null:
		return
	# the story and the van come after the world is built
	if _story == null:
		_story = get_tree().current_scene.get("story")
	if not van.nav_override.is_valid():
		van.nav_override = func() -> String: return pace_notes(van)
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 0.25
		var near: Dictionary = _builder.network.nearest(van.global_position.x, van.global_position.z)
		var i: int = near["index"]
		on_ghat = near["road"] == road and float(near.get("dist", 0.0)) < 30.0
		if on_ghat:
			_van_i = i
		var in_fog := on_ghat and i >= fog_from and i <= fog_to
		_fog_target = 1.0 if in_fog else 0.0
		_events(van, i)
	var f := move_toward(fog, _fog_target, FOG_EASE * delta)
	if f != fog:
		fog = f
		var mood := get_tree().get_first_node_in_group("mood") as Mood
		if mood != null:
			mood.fog_boost = fog
			mood.apply()
	if problem != null and is_instance_valid(problem):
		_run_problem(van, delta)
	elif problem != null:
		problem = null
		attacker = null


func _events(van: Camper, i: int) -> void:
	if _story == null:
		return
	var flags: Dictionary = _story.flags
	# measured along the road: the hairpins fold back, a straight-line
	# distance fired on the first one
	if hairpins.size() >= 2 and not flags.has("ghat_glimpse") and on_ghat \
			and i >= hairpins[SEEN_HAIRPIN] - int(GLIMPSE_AT / Route.SAMPLE_SPACING) and i <= hairpins[SEEN_HAIRPIN] + 10:
		flags["ghat_glimpse"] = true
		_spawn_problem(road.point(hairpins[SEEN_HAIRPIN]), van)


## Among the trees on the outside of the second hairpin, facing the road.
func _spawn_problem(apex: Vector3, van: Camper) -> void:
	var h: int = hairpins[SEEN_HAIRPIN]
	var out := apex - road.point(maxi(0, h - 12))
	out = (out + (apex - road.point(mini(road.point_count() - 1, h + 12)))).normalized()
	out.y = 0.0
	var at := apex + out.normalized() * 15.0
	at.y = Landscape.ground(at.x, at.z)
	problem = Creature.new()
	problem.name = "Problem"
	get_tree().get_first_node_in_group("world_root").add_child(problem)
	problem.global_position = at
	problem.look_at(Vector3(van.global_position.x, at.y, van.global_position.z), Vector3.UP)
	problem.director = func() -> Dictionary: return _direct()
	attacker = problem
	_set_phase("watch")


func _set_phase(p: String) -> void:
	phase = p
	phase_t = 0.0
	_stopped_t = 0.0
	quiet_t = 0.0


## Where Problem goes this frame (Creature.director).
func _direct() -> Dictionary:
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van == null or problem == null:
		return {}
	var here := problem.global_position
	var c := van.global_position
	match phase:
		"watch":
			return {"goal": here}       # the body stays put; only its head follows the van
		"follow":
			return {"goal": c, "speed": FOLLOW_SPEED, "face": c}
		"come":
			var off := here - c
			off.y = 0.0
			return {"goal": c + off.normalized() * CIRCLE_R, "speed": COME_SPEED, "face": c}
		"circle":
			var spot := _round_point(van, stop_k)
			if at_stop:
				return {"goal": here, "face": _round_look(van, stop_k)}
			return {"goal": spot, "speed": CIRCLE_SPEED, "face": spot}
		"leave":
			# slumped, it turns away slowly; it sets off only once it faces the
			# way out (it set off half turned and snapped round, 2026-11-09)
			var to := _leave_to - here
			to.y = 0.0
			var fwd := -problem.global_transform.basis.z
			fwd.y = 0.0
			if phase_t < SLUMP_S or fwd.angle_to(to) > 0.3:
				return {"goal": here, "face": _leave_to}
			return {"goal": _leave_to, "speed": LEAVE_SPEED, "face": _leave_to}
	return {}


func _round_point(van: Camper, k: int) -> Vector3:
	var p: Vector3 = van._body_root.global_transform * (ROUND[k][0] as Vector3)
	p.y = Landscape.ground(p.x, p.z)
	return p


func _round_look(van: Camper, k: int) -> Vector3:
	var l: Vector3 = ROUND[k][1]
	return van._body_root.global_transform * l if l != Vector3.ZERO else van.global_position + Vector3.UP


## The nearest stop of its round to where it is (it starts there).
func _nearest_stop(van: Camper) -> int:
	var best := 0
	var bd := INF
	for k in ROUND.size():
		var d := problem.global_position.distance_to(_round_point(van, k))
		if d < bd:
			bd = d
			best = k
	return best


## Its round: walk to the next stop; at one with a pose, stay STATION_S
## doing it (lean in at a window, crouch and sniff at the back), then on.
func _walk_round(van: Camper, delta: float) -> void:
	var spot := _round_point(van, stop_k)
	var flat := Vector2(spot.x - problem.global_position.x, spot.z - problem.global_position.z).length()
	if not at_stop:
		problem.pose = "stand"
		problem.look_point = spot + Vector3.UP * 1.5
		if flat < 0.7:
			if String(ROUND[stop_k][2]) == "":
				stop_k = (stop_k + 1) % ROUND.size()
			else:
				at_stop = true
				_stop_t = 0.0
		return
	_stop_t += delta
	problem.pose = String(ROUND[stop_k][2])
	problem.look_point = _round_look(van, stop_k)
	_breath_at_window(van, delta)
	if _stop_t > STATION_S:
		_leave_mark(van, stop_k)
		at_stop = false
		problem.pose = "stand"
		stop_k = (stop_k + 1) % ROUND.size()
		stops_done += 1
		_breath_end(van)


## L5: what it touched stays on the van (once per stop, per encounter).
func _leave_mark(van: Camper, k: int) -> void:
	if _marked.has(k):
		return
	_marked[k] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = encounter_no * 97 + k * 13 + 7
	var s := rng.randi()
	match k:
		0:      # the bonnet: a hand flat on it, a dent where it pressed
			van.add_mark("hand_bonnet", Vector3(rng.randf_range(-0.6, 0.6), 1.665, rng.randf_range(-3.55, -3.05)), s, encounter_no)
			van.add_mark("dent", Vector3(rng.randf_range(-0.7, 0.7), 1.664, rng.randf_range(-3.6, -3.1)), s + 1, encounter_no)
		2, 6:   # a window: a frosted handprint on the glass
			var sx := -1.0 if k == 2 else 1.0
			van.add_mark("hand_glass", Vector3(sx * 1.15, rng.randf_range(1.72, 1.95), rng.randf_range(-2.2, -1.4)), s, encounter_no)
		4:      # the back doors: long scrapes
			van.add_mark("scrape", Vector3(rng.randf_range(-0.5, 0.3), rng.randf_range(1.15, 1.5), 3.0), s, encounter_no)


## A save in the middle of an encounter goes back to just before the bend
## where it watches (the user's pick, #6 point 9): the van as it was, the
## encounter's flags and marks undone, both in the van.
func adjust_save(d: Dictionary) -> void:
	if not phase in ["watch", "follow", "come", "circle"]:
		return
	var i := maxi(0, hairpins[SEEN_HAIRPIN] - 45)
	var p := road.point(i)
	var f := road.forward(i)
	var cam: Dictionary = d["camper"]
	cam["xf"] = SaveGame._xf(Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), p + Vector3.UP * 0.9))
	cam["temp"] = Camper.TEMP_NORMAL
	cam["fuel"] = _fuel_at_seen
	cam["coolant"] = _coolant_at_seen
	cam["boiled_dry"] = false
	cam["lockout"] = false
	cam["tarp"] = false
	cam["marks"] = (cam.get("marks", []) as Array).filter(func(m): return int(m["enc"]) != encounter_no)
	var players: Array = d["players"]
	for k in players.size():
		players[k]["seat"] = "driver" if k == 0 else "passenger"
	var st: Dictionary = d["story"]
	st["objective"] = "ghat"
	st["index"] = _story.index_of("ghat")
	var fl: Dictionary = st["flags"]
	for fk in ["ghat_glimpse", "first_attack", "first_attack_over"]:
		fl.erase(fk)
	for it in d["items"]:
		if String(it["name"]).begins_with("GhatPot"):
			var k := int(String(it["name"]).trim_prefix("GhatPot")) - 1
			if k >= 0 and k < springs.size():
				it["xf"] = SaveGame._xf(Transform3D(Basis(Vector3.UP, springs[k].rotation.y), springs[k].global_transform * Vector3(0.62, 0.1, 0.12)))
				it["litres"] = 0.0
				it.erase("slot")
	d["meta"]["place"] = "Ghat hairpins"


## After a load or a story jump: no Problem unless its encounter is under way.
func match_story() -> void:
	if _story == null:
		_story = get_tree().current_scene.get("story")
	if _story != null and not _story.flags.has("first_attack"):
		reset()


# --- S3: hold your breath -----------------------------------------------------

## At a window, leaning in: the player sitting there must hold their breath
## (hold crouch: Ctrl / pad B) until it moves on. Breathing shows (the glass
## fogs) and it hears you; letting go early, or running out, is a gasp. Either
## way it noticed: its head snaps to the window, it stays longer, and its
## search starts again.
func _breath_at_window(van: Camper, delta: float) -> void:
	var lx := (ROUND[stop_k][0] as Vector3).x
	if String(ROUND[stop_k][2]) != "lean" or absf(lx) < 1.0:
		return
	var role := "driver" if lx < 0.0 else "passenger"
	var p: PlayerRig = null
	for n in get_tree().get_nodes_in_group("player"):
		# (a seat is the seat's node, not the van: comparing it to the van never matched)
		if (n as PlayerRig).seat != null and (n as PlayerRig).seat_role == role:
			p = n
	if p == null:
		return
	if breath_p != p:
		breath_p = p
		breath_state = "wait"
		breath = 1.0
		_window_t = 0.0
		van.breath_lock = p
	_window_t += delta
	var held: bool = p.dev != null and p.dev.held("crouch")
	match breath_state:
		"wait":
			if held:
				breath_state = "holding"
			elif _window_t > BREATH_GRACE:
				breath_state = "fogged"
				_given_away(van, p, "Your breath fogs the glass, and it hears you breathing. Its head stops at the window.")
		"holding":
			breath -= delta / BREATH_S
			if not held or breath <= 0.0:
				breath_state = "gasped"
				Sfx.play3d("gasp", p.global_position + Vector3.UP * 1.5, 2.0)
				Hearing.emit(van.global_position, 12.0, "gasp")
				_given_away(van, p, "You gasp for air. Its head snaps round to the window.")
	van.fog_window(role, 1.0 if breath_state in ["wait", "fogged"] and _window_t > BREATH_GRACE * 0.6 else 0.0)
	_show_breath(p, van)


func _given_away(van: Camper, p: PlayerRig, text: String) -> void:
	breath_events += 1
	# each window gives you away once an encounter: it starts its search again
	# (one more round, more coolant boiled away); after that it only lingers
	if _windows_given.has(p.seat_role):
		_stop_t = maxf(0.0, _stop_t - 1.5)
		p.say("Your breath fogs the glass again. It lingers at the window... and moves on.", 4.0)
		return
	_windows_given[p.seat_role] = true
	search_restarts += 1
	quiet_t = 0.0
	stops_done = 0
	_stop_t = 0.0                # it stays at the window, staring
	problem.show_interest = 1.0
	# the head snaps round: no easing
	var lp := problem.global_transform.affine_inverse() * _round_look(van, stop_k)
	problem._head.rotation.y = clampf(atan2(-lp.x, -lp.z), deg_to_rad(-110.0), deg_to_rad(110.0))
	p.say(text, 4.0)


func _breath_end(van: Camper) -> void:
	if breath_p != null:
		if breath_state == "holding":
			breath_state = "done"
			breath_p.say("It moves on. You let the breath out, slowly.", 4.0)
		van.fog_window(breath_p.seat_role, 0.0)
		_hide_breath(breath_p)
	breath_p = null
	van.breath_lock = null


func _show_breath(p: PlayerRig, _van: Camper) -> void:
	var hud := _hud(p)
	if hud == null:
		return
	var key := p.dev.glyph("crouch") if p.dev != null else "Ctrl"
	var txt := "It's at your window.  HOLD %s: hold your breath" % key
	if breath_state == "holding":
		txt = "Holding your breath... (%s)" % key
	elif breath_state in ["fogged", "gasped"]:
		txt = "It noticed."
	hud.set_breath(true, breath, txt)


func _hide_breath(p: PlayerRig) -> void:
	var hud := _hud(p)
	if hud != null:
		hud.set_breath(false, 1.0, "")


func _hud(p: PlayerRig) -> PlayerHUD:
	var huds = get_tree().current_scene.get("huds")
	if huds == null or p.index >= (huds as Array).size():
		return null
	return huds[p.index]


# --- L4: the springs and the milestone ----------------------------------------

## A spring pipe in the bank on the uphill side of sample `i`: cold water
## running into a puddle, an old steel pot on a flat stone under it.
func _build_spring(b, i: int, k: int) -> void:
	var p := road.point(i)
	var r := road.right(i)
	r.y = 0.0
	r = r.normalized()
	var side := 1.0 if Landscape.ground(p.x + r.x * 7.0, p.z + r.z * 7.0) > Landscape.ground(p.x - r.x * 7.0, p.z - r.z * 7.0) else -1.0
	var base := p + r * side * 6.2
	base.y = Landscape.ground(base.x, base.z)
	var to_road := -r * side
	var root := Node3D.new()
	root.name = "GhatSpring%d" % k
	root.position = base
	root.rotation.y = atan2(to_road.x, to_road.z)          # local +Z faces the road
	b.world.add_child(root)
	springs.append(root)
	b.poi["ghat_spring_%d" % k] = base
	var stone := ToonMat.make(Color(0.46, 0.45, 0.42))
	var moss := ToonMat.make(Color(0.30, 0.38, 0.22))
	var rust := ToonMat.make(Color(0.45, 0.28, 0.18), 0.01)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.62, 0.78, 0.92, 0.55)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.1
	var pool := StandardMaterial3D.new()
	pool.albedo_color = Color(0.18, 0.26, 0.30, 0.85)
	pool.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool.roughness = 0.05
	# a dressed stone set into the bank, the pipe through it, rocks round it as
	# they fell (not in a row), a puddle where the water lands
	root.add_child(Build.box(Vector3(0.95, 1.25, 0.32), stone, Vector3(0, 0.45, -0.75), Vector3(-6, 3, 1), "SpringSlab"))
	root.add_child(Build.box(Vector3(0.7, 0.12, 0.25), moss, Vector3(0.05, 1.08, -0.68), Vector3(-6, 3, 4), "SpringMoss"))
	root.add_child(Build.cyl(0.04, 0.55, rust, Vector3(0, 0.85, -0.35), Vector3(90, 0, 0), 8, "SpringPipe"))
	root.add_child(Build.cyl(0.018, 0.82, water, Vector3(0, 0.44, -0.07), Vector3.ZERO, 6, "SpringStream"))
	root.add_child(Build.cyl(0.48, 0.02, pool, Vector3(0.05, 0.01, 0.02), Vector3.ZERO, 14, "SpringPool"))
	var rocks := [[Vector3(-0.62, 0.05, -0.35), 0.28, 20.0], [Vector3(0.7, 0.02, -0.42), 0.34, -35.0],
		[Vector3(-0.45, 0.0, 0.42), 0.2, 60.0], [Vector3(0.52, 0.0, 0.3), 0.24, 5.0]]
	for rk in rocks:
		root.add_child(Build.sphere(float(rk[1]), stone, rk[0], Vector3(1.3, 0.6, 1.0), "SpringRock"))
	# the flat stone the pot sits on
	root.add_child(Build.box(Vector3(0.42, 0.08, 0.36), stone, Vector3(0.62, 0.04, 0.12), Vector3(0, 18, 2), "PotStone"))
	var pot := WaterPot.new()
	pot.name = "GhatPot%d" % k
	b.world.add_child(pot)
	pot.position = base + Basis(Vector3.UP, root.rotation.y) * Vector3(0.62, 0.1, 0.12)
	pot.rotation.y = root.rotation.y
	pot.freeze = true                # set out in place until picked up
	pots.append(pot)
	# fill a pot at the pipe (hold use with the pot in your hands)
	var area := Build.interact_area(Vector3(0.7, 0.9, 0.7), Vector3(0, 0.7, -0.15), "", func(_p): pass, "SpringTap")
	area.set_meta("tag_name", "the spring")
	area.set_meta("prompt_fn", func(_p) -> String: return "")
	area.set_meta("blocked_fn", func() -> String:
		return "A spring pipe: cold water running off the hill. A pot would carry it.")
	area.set_meta("held_prompt_fn", func(_p, item) -> String:
		if not (item is WaterPot):
			return ""
		if item.litres >= WaterPot.POT_L - 0.05:
			return "The pot is full"
		return "Hold to fill the pot  -  %.1f of %.1f L" % [item.litres, WaterPot.POT_L])
	area.set_meta("pour", true)
	area.set_meta("held_action", func(pl, item, dt: float, _first: bool):
		if item is WaterPot:
			var got: float = item.fill(FILL_RATE * dt)
			if got > 0.0 and fmod(item.litres, 0.8) < FILL_RATE * dt:
				Sfx.play3d("gurgle", pl.global_position + Vector3.UP, -10.0))
	root.add_child(area)


## An old roadside milestone (white, a yellow cap) on the uphill side, Naresh's
## note pinned to the face you see from the road.
func _build_milestone(b, i: int) -> void:
	var p := road.point(i)
	var r := road.right(i)
	r.y = 0.0
	r = r.normalized()
	var side := 1.0 if Landscape.ground(p.x + r.x * 6.0, p.z + r.z * 6.0) > Landscape.ground(p.x - r.x * 6.0, p.z - r.z * 6.0) else -1.0
	var base := p + r * side * 4.4
	base.y = Landscape.ground(base.x, base.z) - 0.08
	var root := Node3D.new()
	root.name = "GhatMilestone"
	root.position = base
	var to_road := -r * side
	root.rotation.y = atan2(to_road.x, to_road.z) + deg_to_rad(-8.0)   # not quite square to the road
	b.world.add_child(root)
	b.poi["ghat_milestone"] = base
	var white := ToonMat.make(Color(0.88, 0.87, 0.82))
	var cap := ToonMat.make(Color(0.92, 0.70, 0.15))
	root.add_child(Build.box(Vector3(0.42, 0.62, 0.2), white, Vector3(0, 0.31, 0), Vector3(0, 0, 2), "MileStone"))
	root.add_child(Build.cyl(0.21, 0.2, cap, Vector3(0, 0.62, 0), Vector3(90, 0, 0), 12, "MileCap"))
	var lbl := Label3D.new()
	lbl.text = "PASS\n0.4"
	lbl.font_size = 40
	lbl.pixel_size = 0.004
	lbl.modulate = Color(0.12, 0.12, 0.12)
	lbl.position = Vector3(0, 0.52, 0.105)
	root.add_child(lbl)
	NareshNote.make(root, "ghat_heat", Vector3(0.0, 0.28, 0.1), 0.0,
		"On this hill we learnt it the hard way. If the needle climbs after you've seen one of them, it's them, not the engine. Don't try to outrun it.\n\nStop. Cover the van. Get in and don't breathe.\n\nAnd never open the radiator cap hot.")


## Problem is interested in the van right now (it heats and leaks).
func interested() -> bool:
	return phase in ["follow", "come", "circle"]


func _run_problem(van: Camper, delta: float) -> void:
	phase_t += delta
	# what it shows: eyes and whine with its interest, the head on the van
	match phase:
		"watch":
			problem.show_interest = clampf(phase_t / WATCH_S, 0.0, 1.0)
			problem.look_point = van.global_position + Vector3.UP * 1.5
			problem.pose = "stand"
		"follow", "come":
			problem.show_interest = 1.0
			problem.look_point = van.global_position + Vector3.UP * 1.5
			problem.pose = "stand"
		"circle":
			problem.show_interest = 1.0
			_walk_round(van, delta)
		"leave":
			problem.show_interest = clampf(1.0 - phase_t / 4.0, 0.0, 1.0)
			problem.pose = "slump" if phase_t < SLUMP_S + 2.0 else "stand"
			problem.look_point = Vector3.INF
			problem.turn_cap = 35.0
	var flags: Dictionary = _story.flags if _story != null else {}
	var d := Vector2(problem.global_position.x - van.global_position.x, problem.global_position.z - van.global_position.z).length()
	var stopped := van.boiled_dry or (not van.engine_on and van.linear_velocity.length() < 0.5)
	match phase:
		"watch":
			if phase_t > WATCH_S:
				flags["first_attack"] = true
				seen_index = _van_i
				# numbered on from the marks already on the van (a loaded game too)
				encounter_no = 1
				for m in van.marks:
					encounter_no = maxi(encounter_no, int(m["enc"]) + 1)
				_marked = {}
				_windows_given = {}
				_fuel_at_seen = van.fuel
				_coolant_at_seen = van.coolant
				_set_phase("follow")
				_tell("Among the trees on the bend, something tall turns its head to follow the van. Its eyes brighten.", 7.0)
		"follow":
			_stopped_t = _stopped_t + delta if stopped else 0.0
			if _stopped_t > STOP_S:
				_start_come(van, d)
		"come":
			if not stopped:
				_set_phase("follow")
			elif d < CIRCLE_R + 2.0:
				_set_phase("circle")
				stop_k = _nearest_stop(van)
				at_stop = false
				stops_done = 0
				# its hand on the bonnet: whatever the needle said, it boils now
				if not van.boiled_dry:
					van.temp = maxf(van.temp, Camper.TEMP_MAX)
		"circle":
			if van.engine_on and van.linear_velocity.length() > 2.0:
				_set_phase("follow")
			elif van.attack.tarped:
				if problem._noticed_t < 0.3 and phase_t > 1.0:
					if quiet_t > 1.0:
						search_restarts += 1
					quiet_t = 0.0
					stops_done = 0
				else:
					quiet_t += delta
				# it gives up only once it has been all round the van (the bonnet,
				# both windows, the back) and heard nothing for a while
				if quiet_t > SEARCH_S and stops_done >= POSED_STOPS:
					_give_up(van)
			else:
				quiet_t = 0.0
		"leave":
			# S2: a hot radiator cap opened too soon blows steam, and the yelp
			# brings it back (until the van is fixed it stays within earshot)
			if van.cap_blows > _cap_blows_seen:
				_cap_blows_seen = van.cap_blows
				problem.turn_cap = 0.0
				_start_come(van, d)
				_tell("Somewhere up in the fog a whine rises again. It heard that.", 6.0)
			elif d > 130.0 and flags.has("first_attack_over") and not van.boiled_dry:
				problem.queue_free()
				problem = null
				attacker = null
				return
	if interested():
		van.attack.creature_interested(problem, delta)
		# never past the pass: interested, it boils 50 m short at the latest
		if van.engine_on and on_ghat and _van_i >= road.point_count() - 1 - PASS_GUARD:
			van.temp = maxf(van.temp, Camper.TEMP_MAX)
			guard_fired = true
	if van.boiled_dry and boil_index < 0:
		boil_index = _van_i


## The van has stopped: it comes. Far behind, it steps out of the trees
## closer, off the road behind the van.
func _start_come(van: Camper, d: float) -> void:
	problem.passive = false
	if d > COME_FROM + 10.0:
		var i := maxi(0, _van_i - int(COME_FROM / Route.SAMPLE_SPACING))
		var at := road.point(i) + road.right(i) * 9.0
		at.y = Landscape.ground(at.x, at.z)
		problem.global_position = at + Vector3.UP * 0.1
		problem.reset_physics_interpolation()
	_set_phase("come")


func _give_up(van: Camper) -> void:
	_set_phase("leave")
	# capped from this very frame (set a frame later, its first turn was 200 deg/s)
	problem.turn_cap = 35.0
	# given up, it no longer looks for anyone (it took P1 getting out beside
	# it, 2026-11-09); only the hot cap's yelp brings it back
	problem.passive = true
	problem.calm()
	_cap_blows_seen = van.cap_blows
	_breath_end(van)
	_story.flags["first_attack_over"] = true
	var away := problem.global_position - van.global_position
	away.y = 0.0
	_leave_to = problem.global_position + away.normalized() * 150.0
	_leave_to.y = Landscape.ground(_leave_to.x, _leave_to.z)
	_tell("It stops. Its eyes dim, it turns away slowly and walks off, and the fog takes it. The needle stops climbing; the dripping stops.", 8.0)


## Players in the van or near it.
func _tell(text: String, s: float) -> void:
	var van := get_tree().get_first_node_in_group("camper") as Camper
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or van == null or p.global_position.distance_to(van.global_position) < 60.0:
			p.say(text, s)


## F1 (Puzzles, or a story jump to the ghat or before): Problem and its
## encounter happen again.
func reset() -> void:
	if problem != null and is_instance_valid(problem):
		problem.queue_free()
	problem = null
	attacker = null
	glimpse = null
	_set_phase("")
	# back before the ghat: the van has no marks yet (#6 is the first encounter)
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van != null:
		van.set_marks([])
	search_restarts = 0
	breath_events = 0
	breath_state = ""
	breath_p = null
	_cap_blows_seen = 0
	# the pots back at their springs, empty
	for k in pots.size():
		var pot: WaterPot = pots[k]
		if is_instance_valid(pot) and is_instance_valid(springs[k]):
			for h in pot.holders.duplicate():
				h.drop_held()
			if pot.stowed_in != null:
				pot.unstow()
			pot.litres = 0.0
			pot._update_mass()
			pot.global_transform = Transform3D(Basis(Vector3.UP, springs[k].rotation.y), springs[k].global_transform * Vector3(0.62, 0.1, 0.12))
			pot.linear_velocity = Vector3.ZERO
			pot.freeze = true          # set out in place until picked up
			pot._refresh_prompt()
	seen_index = -1
	boil_index = -1
	guard_fired = false
	var st = get_tree().current_scene.get("story")
	if st != null:
		for f in ["ghat_glimpse", "first_attack", "first_attack_over"]:
			st.flags.erase(f)
