class_name Ghat
extends Node

## D10, the ghat hairpins (design/WAY_OUT.md 18:00, W7): fog comes down on
## the hairpins; the nav swung to the passenger shows rally pace notes worked
## out from the road's own bends (the driver sees only fog); a creature is
## glimpsed between the trees on the second hairpin; at the pass, the first
## creature comes for the van (always, once): pull over, engine and lights
## off, tarp, wait (or drive off) until it goes.

const FOG_EASE := 0.25           ## fog boost per second in and out
const NOTES_AHEAD := 260.0       ## m of road the pace notes read ahead
const TURN_MIN := 4.0            ## deg per 10 m that counts as a bend
const ATTACK_AT := 110.0         ## m from the pass when it shows up, far ahead
const GLIMPSE_AT := 40.0         ## m from the second hairpin when it shows

var road: Route
var hairpins: Array[int] = []    ## sample index of each hairpin's apex, from J3 up
var fog_from := 0                ## samples between these are in the fog
var fog_to := 0
var fog := 0.0                   ## 0..1, what the mood is showing
var on_ghat := false
var glimpse: Creature = null
var attacker: Creature = null
var _builder
var _story
var _check_t := 0.0
var _glimpse_t := 0.0
var _gone_t := 0.0
var _came_close := false
var _since_spawn := 0.0


func setup(b) -> void:
	add_to_group("ghat")
	_builder = b
	road = b.network.road("ghat_road")
	_find_hairpins()
	fog_from = maxi(0, (hairpins[0] if not hairpins.is_empty() else 0) - 75)
	fog_to = road.point_count() - 20
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
	if glimpse != null:
		_glimpse_t += delta
		if _glimpse_t > 12.0:
			glimpse.queue_free()
			glimpse = null
	if attacker != null:
		_watch_attack(van, delta)


var _fog_target := 0.0


func _events(van: Camper, _i: int) -> void:
	if _story == null:
		return
	var flags: Dictionary = _story.flags
	if hairpins.size() >= 2 and not flags.has("ghat_glimpse"):
		var hp := road.point(hairpins[1])
		if van.global_position.distance_to(hp) < GLIMPSE_AT and on_ghat:
			flags["ghat_glimpse"] = true
			_spawn_glimpse(hp)
	# measured along the road, and only past the second hairpin: the hairpins
	# fold back close to the pass, so a straight-line distance fired on them
	var after_hairpins := hairpins.size() < 2 or _i >= hairpins[1] + 8
	var to_pass := float(road.point_count() - 1 - _i) * Route.SAMPLE_SPACING
	if not flags.has("first_attack") and _both_in(van) and on_ghat and after_hairpins and to_pass < ATTACK_AT:
		flags["first_attack"] = true
		_spawn_attacker(van, _builder.poi["ghat_pass"], _i)


func _both_in(van: Camper) -> bool:
	return van.driver != null and van.passenger != null


## Between the trees on the outside of the second hairpin: it stands, looks,
## and walks off uphill. It does nothing else.
func _spawn_glimpse(apex: Vector3) -> void:
	var out := apex - road.point(maxi(0, hairpins[1] - 12))
	out = (out + (apex - road.point(mini(road.point_count() - 1, hairpins[1] + 12)))).normalized()
	out.y = 0.0
	var at := apex + out.normalized() * 15.0
	at.y = Landscape.ground(at.x, at.z)
	glimpse = Creature.new()
	glimpse.name = "GhatGlimpse"
	glimpse.passive = true
	get_tree().get_first_node_in_group("world_root").add_child(glimpse)
	glimpse.global_position = at
	var away := at + out.normalized() * 25.0
	away.y = Landscape.ground(away.x, away.z)
	glimpse.patrol = PackedVector3Array([away])
	glimpse.look_at(Vector3(apex.x, at.y, apex.z), Vector3.UP)
	_glimpse_t = 0.0


## By the pass, far up the road ahead: it walks down the road's edge towards
## you on its own round, slowly, and back up again. It notices the van only
## as creatures do (the engine, the lights, the van moving close, or just
## being within 15 m of it), so there's time to stop well back, engine off,
## and tarp the van; then it walks by and goes back up. Or drive past.
func _spawn_attacker(van: Camper, pass_at: Vector3, van_i: int) -> void:
	var last := road.point_count() - 1
	var up := road.forward(last)                   # towards the pass
	up.y = 0.0
	up = up.normalized()
	var side := up.cross(Vector3.UP)
	var top := pass_at + side * 3.5
	top.y = Landscape.ground(top.x, top.z)
	# down the road to a little past where the van is now (it stops there, or
	# drives on into it), then back up
	var down_i := maxi(0, van_i - 12)
	var low := road.point(down_i) + road.right(down_i) * 3.5
	low.y = Landscape.ground(low.x, low.z)
	attacker = Creature.new()
	attacker.name = "FirstCreature"
	get_tree().get_first_node_in_group("world_root").add_child(attacker)
	attacker.global_position = top
	attacker.patrol = PackedVector3Array([low, top])
	attacker.look_at(Vector3(low.x, top.y, low.z), Vector3.UP)
	_gone_t = 0.0
	_came_close = false
	_since_spawn = 0.0
	var d := Vector2(van.global_position.x - top.x, van.global_position.z - top.z).length()
	for p in get_tree().get_nodes_in_group("player"):
		(p as PlayerRig).say("Far up the road, by the pass, something tall is walking down the edge of the road. It hasn't seen you yet (%d m).

Stop well back: handbrake, engine off, get out and pull the tarp over the van (hold E at a back corner; one of you can start it and the other finish). Then hide - inside the van is fine - and watch it in the door mirrors. Or drive past it." % roundi(d), 14.0)


## Over when it has been near and gone back up (or given up on the van), or
## the van left it behind. After that it walks off over the pass for good.
## F1 (Puzzles, or a story jump to the ghat or before): the glimpse and the
## first attack happen again.
func reset() -> void:
	for cr in [glimpse, attacker]:
		if cr != null and is_instance_valid(cr):
			cr.queue_free()
	glimpse = null
	attacker = null
	_glimpse_t = 0.0
	_gone_t = 0.0
	_came_close = false
	_since_spawn = 0.0
	var st = get_tree().current_scene.get("story")
	if st != null:
		for f in ["ghat_glimpse", "first_attack", "first_attack_over"]:
			st.flags.erase(f)


func _watch_attack(van: Camper, delta: float) -> void:
	_since_spawn += delta
	var d := Vector2(attacker.global_position.x - van.global_position.x, attacker.global_position.z - van.global_position.z).length()
	if d < 40.0 or attacker.state == Creature.State.VAN:
		_came_close = true
	var calm := attacker.van_interest <= 0.0 and attacker.state == Creature.State.WANDER
	if (_came_close and calm and d > 45.0) or d > 110.0 and _since_spawn > 5.0:
		_gone_t += delta
	else:
		_gone_t = 0.0
	if _gone_t > 2.0 and not _story.flags.has("first_attack_over"):
		_story.flags["first_attack_over"] = true
		# away over the pass, and it doesn't look back
		var away := attacker.global_position + (attacker.global_position - van.global_position).normalized() * 150.0
		away.y = Landscape.ground(away.x, away.z)
		attacker.patrol = PackedVector3Array([away])
		attacker.passive = true
		for p in get_tree().get_nodes_in_group("player"):
			(p as PlayerRig).say("It's gone, back up over the pass. The dripping has stopped.

So that's what they do: they want the van. Hide it and they pass it by.", 8.0)
	if _story.flags.has("first_attack_over") and d > 130.0:
		attacker.queue_free()
		attacker = null
