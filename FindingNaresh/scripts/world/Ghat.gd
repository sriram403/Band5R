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
const ATTACK_AT := 45.0          ## m from the pass when it steps out
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
	if not flags.has("first_attack") and _both_in(van):
		var pass_at: Vector3 = _builder.poi["ghat_pass"]
		if Vector2(van.global_position.x - pass_at.x, van.global_position.z - pass_at.z).length() < ATTACK_AT:
			flags["first_attack"] = true
			_spawn_attacker(van, pass_at)


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


## At the pass: it steps out at the roadside ahead and comes for the van.
func _spawn_attacker(van: Camper, pass_at: Vector3) -> void:
	var fwd := -van.global_transform.basis.z
	fwd.y = 0.0
	var side := fwd.normalized().cross(Vector3.UP)
	var at := van.global_position + fwd.normalized() * 22.0 + side * 6.0
	at.y = Landscape.ground(at.x, at.z)
	attacker = Creature.new()
	attacker.name = "FirstCreature"
	get_tree().get_first_node_in_group("world_root").add_child(attacker)
	attacker.global_position = at
	attacker.look_at(Vector3(van.global_position.x, at.y, van.global_position.z), Vector3.UP)
	attacker.van_interest = 30.0
	_gone_t = 0.0
	var away := pass_at + side * 60.0
	away.y = Landscape.ground(away.x, away.z)
	attacker.patrol = PackedVector3Array([away, away + fwd.normalized() * 20.0])
	for p in get_tree().get_nodes_in_group("player"):
		(p as PlayerRig).say("Something tall steps out at the side of the road ahead. Two eyes catch the light, then it starts towards the van.\n\nIt wants the van. Pull over, engine and lights off, get out, pull the tarp over it (hold E at the back) - and keep out of sight until it goes. Or drive away.", 12.0)


## Over when it has lost interest and wandered off, or the van left it behind.
func _watch_attack(van: Camper, delta: float) -> void:
	var d := Vector2(attacker.global_position.x - van.global_position.x, attacker.global_position.z - van.global_position.z).length()
	if attacker.van_interest <= 0.0 and attacker.state == Creature.State.WANDER and d > 25.0 or d > 90.0:
		_gone_t += delta
	else:
		_gone_t = 0.0
	if _gone_t > 2.0 and not _story.flags.has("first_attack_over"):
		_story.flags["first_attack_over"] = true
		for p in get_tree().get_nodes_in_group("player"):
			(p as PlayerRig).say("It's gone, off into the trees. The dripping has stopped.\n\nSo that's what they do: they want the van. Hide it and they lose interest.", 8.0)
	if _story.flags.has("first_attack_over") and d > 120.0:
		attacker.queue_free()
		attacker = null
