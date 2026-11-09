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

const WATCH_S := 1.5             ## s it stares before it has "seen" the van
const FOLLOW_SPEED := 1.6
const COME_FROM := 45.0          ## m behind the stopped van it steps out of the trees, if further
const COME_SPEED := 1.8
const CIRCLE_R := 6.0            ## m from the van's middle while it circles
const CIRCLE_SPEED := 1.1
const SEARCH_S := 25.0           ## s of quiet at the tarped van before it gives up
const LEAVE_SPEED := 1.0
const PASS_GUARD := 25           ## samples (50 m) before the pass: interested, it boils there at the latest
const STOP_S := 2.0              ## s stopped (engine off) before it comes

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
			return {"goal": here, "face": c}
		"follow":
			return {"goal": c, "speed": FOLLOW_SPEED, "face": c}
		"come":
			var off := here - c
			off.y = 0.0
			return {"goal": c + off.normalized() * CIRCLE_R, "speed": COME_SPEED, "face": c}
		"circle":
			var off := here - c
			off.y = 0.0
			var a := atan2(off.z, off.x) + 0.3
			return {"goal": c + Vector3(cos(a), 0, sin(a)) * CIRCLE_R, "speed": CIRCLE_SPEED, "face": c}
		"leave":
			return {"goal": _leave_to, "speed": LEAVE_SPEED}
	return {}


## Problem is interested in the van right now (it heats and leaks).
func interested() -> bool:
	return phase in ["follow", "come", "circle"]


func _run_problem(van: Camper, delta: float) -> void:
	phase_t += delta
	var flags: Dictionary = _story.flags if _story != null else {}
	var d := Vector2(problem.global_position.x - van.global_position.x, problem.global_position.z - van.global_position.z).length()
	var stopped := van.boiled_dry or (not van.engine_on and van.linear_velocity.length() < 0.5)
	match phase:
		"watch":
			if phase_t > WATCH_S:
				flags["first_attack"] = true
				seen_index = _van_i
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
				else:
					quiet_t += delta
				if quiet_t > SEARCH_S:
					_give_up(van)
			else:
				quiet_t = 0.0
		"leave":
			if d > 130.0 and flags.has("first_attack_over"):
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
	if d > COME_FROM + 10.0:
		var i := maxi(0, _van_i - int(COME_FROM / Route.SAMPLE_SPACING))
		var at := road.point(i) + road.right(i) * 9.0
		at.y = Landscape.ground(at.x, at.z)
		problem.global_position = at + Vector3.UP * 0.1
		problem.reset_physics_interpolation()
	_set_phase("come")


func _give_up(van: Camper) -> void:
	_set_phase("leave")
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
	search_restarts = 0
	seen_index = -1
	boil_index = -1
	guard_fired = false
	var st = get_tree().current_scene.get("story")
	if st != null:
		for f in ["ghat_glimpse", "first_attack", "first_attack_over"]:
			st.flags.erase(f)
