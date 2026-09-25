class_name Taken
extends Node3D

## Caught = separated (design/CREATURES.md). No health, no damage: a wisp of
## the same white smoke the Five Roses rise from, your view goes white, and you
## wake somewhere else, a drop point 150-400 m away near a landmark. Your
## partner sees a faint smoke trail drift off roughly your way for a few
## seconds, and you both get a text. For two minutes nothing can take you
## again. If your partner is already out there on their own, you both wake at
## the van instead, and something has been at it (a fuel leak).

const GRACE := 120.0
const DROP_MIN := 150.0
const DROP_MAX := 400.0
const TRAIL_SECONDS := 5.0
const WHITE_IN := 0.7
const WHITE_HOLD := 1.2
const WHITE_OUT := 1.4

var player: PlayerRig
var by: Node3D
var from := Vector3.ZERO
var to := Vector3.ZERO
var near := ""                     ## the landmark you wake by
var both := false
var _cancelled := false


## Starts the sequence for `p`. Returns the node (tests read `to`/`both`).
static func take(p: PlayerRig, creature: Node3D = null) -> Taken:
	if p.taken_grace > 0.0 or p.seat != null or p.taken_hold > 0.0:
		return null
	var root := p.get_tree().get_first_node_in_group("world_root")
	if root == null:
		return null
	var t := Taken.new()
	t.name = "Taken%d" % (p.index + 1)
	t.player = p
	t.by = creature
	t.from = p.global_position
	root.add_child(t)
	t.global_position = t.from
	return t


func _ready() -> void:
	add_to_group("taken")
	player.taken_grace = GRACE
	player.taken_hold = WHITE_IN + WHITE_HOLD + 0.2
	player.drop_held()
	player.set_map_open(false)
	player.leave_box(false)     # the box stays behind where you were
	var partner := _partner()
	both = partner != null and partner.taken_grace > 0.0 and partner.global_position.distance_to(from) > 30.0
	_choose_drop()
	_wisp(from + Vector3.UP * 1.0)
	if not both and partner != null:
		_trail()
	Sfx.play3d("whoosh", from + Vector3.UP, 4.0)
	_run()


func _partner() -> PlayerRig:
	for n in get_tree().get_nodes_in_group("player"):
		if n != player:
			return n as PlayerRig
	return null


## A drop point from the builder's list, 150-400 m away: the nearest one past
## 150 m, so you land far enough to need the map but never across the world.
func _choose_drop() -> void:
	var boot := get_tree().current_scene
	var camper: Camper = boot.get("camper") if boot != null else null
	if both and camper != null:
		var side := camper.exit_transform_for("passenger" if player.index == 1 else "driver")
		to = side.origin + Vector3.UP * 0.3
		near = "the van"
		return
	var pts: Array = boot.builder.drop_points if boot != null and boot.get("builder") != null else []
	var best := {}
	var best_d := INF
	for d in pts:
		var dist := (d["pos"] as Vector3).distance_to(from)
		if dist >= DROP_MIN and dist <= DROP_MAX and dist < best_d:
			best = d
			best_d = dist
	if best.is_empty():
		# nothing in the ring: the farthest point short of it, else stay put
		for d in pts:
			var dist := (d["pos"] as Vector3).distance_to(from)
			if dist < DROP_MIN and (best.is_empty() or dist > (best["pos"] as Vector3).distance_to(from)):
				best = d
	if best.is_empty():
		to = from
		near = "here"
	else:
		to = best["pos"]
		near = best["near"]


## Stops a sequence part-way (dev menu, tests): the player keeps where they are.
func cancel() -> void:
	_cancelled = true
	player.whiteout = 0.0
	player.taken_hold = 0.0
	queue_free()


func _run() -> void:
	var tree := get_tree()
	var t := 0.0
	while t < WHITE_IN:
		t += get_process_delta_time()
		player.whiteout = clampf(t / WHITE_IN, 0.0, 1.0)
		await tree.process_frame
		if _cancelled:
			return
	player.whiteout = 1.0
	_move_player()
	await tree.create_timer(WHITE_HOLD, false).timeout
	if _cancelled:
		return
	t = 0.0
	while t < WHITE_OUT:
		t += get_process_delta_time()
		player.whiteout = 1.0 - clampf(t / WHITE_OUT, 0.0, 1.0)
		await tree.process_frame
		if _cancelled:
			return
	player.whiteout = 0.0
	_texts()
	await tree.create_timer(TRAIL_SECONDS, false).timeout
	if not _cancelled:
		queue_free()


func _move_player() -> void:
	var at := to
	at.y = Landscape.ground(at.x, at.z) + 0.3 if near != "the van" else to.y
	player.global_position = at
	player.velocity = Vector3.ZERO
	player._plan_vel = Vector2.ZERO
	player.pitch = 0.0
	# you come round facing the way you were taken from: the trail, the
	# landmarks you know, your partner somewhere out there
	var back := from - at
	if Vector2(back.x, back.z).length() > 1.0:
		player.yaw = atan2(-back.x, -back.z)
		player.rotation.y = player.yaw
	player.reset_physics_interpolation()
	if both:
		var partner := _partner()
		var camper: Camper = get_tree().current_scene.get("camper")
		if partner != null and camper != null:
			var side := camper.exit_transform_for("driver" if player.index == 1 else "passenger")
			partner.global_position = side.origin + Vector3.UP * 0.3
			partner.velocity = Vector3.ZERO
			partner.reset_physics_interpolation()
			partner.say("Everything goes white... You are back at the van. Something has been at it: it smells of fuel.", 6.0)
			camper.fuel_leak = maxf(camper.fuel_leak, Camper.CREATURE_LEAK)


func _texts() -> void:
	var story := get_tree().get_first_node_in_group("story") as Story
	var me := "P%d" % (player.index + 1)
	var other := "P%d" % (2 - player.index)
	if both:
		player.say("You wake up by the van. The fuel is dripping out of it.", 6.0)
		return
	player.say("You wake up on the ground by %s. Where is everyone?" % near, 6.0)
	if story != null:
		story._send_phone(player.index, other, "where did you go??")
		story._send_phone(1 - player.index, me, "I'm by %s, I think. I don't know how I got here." % near)


## The same white smoke as the Five Roses: a quick, bright wisp where you were.
func _wisp(at: Vector3) -> void:
	var p := _smoke(28, 1.6, 0.9)
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.6
	p.one_shot = true
	add_child(p)
	p.global_position = at
	p.emitting = true


## For the partner: a faint trail drifting off towards where you went, for a
## few seconds. Rough on purpose: the map and the horn do the rest.
func _trail() -> void:
	var dir := to - from
	dir.y = 0.0
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var p := _smoke(60, TRAIL_SECONDS * 0.9, 0.45)
	p.name = "Trail"
	p.direction = (dir + Vector3.UP * 0.35).normalized()
	p.spread = 6.0
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 18.0
	p.damping_min = 0.5
	p.damping_max = 1.0
	p.gravity = Vector3(0, 0.6, 0)
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.2
	p.one_shot = false
	p.explosiveness = 0.0
	add_child(p)
	p.global_position = from + Vector3.UP * 1.5
	p.emitting = true
	# a tween owned by the trail dies with it (a cancelled take frees it early)
	var tw := p.create_tween()
	tw.tween_interval(TRAIL_SECONDS * 0.6)
	tw.tween_property(p, "emitting", false, 0.0)


func _smoke(amount: int, life: float, alpha: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.85
	p.gravity = Vector3(0, 0.3, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.8
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	sm.radial_segments = 8
	sm.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.97, 0.97, 1.0, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	p.mesh = sm
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	mat.vertex_color_use_as_albedo = true
	return p
