class_name ButtFx
extends RefCounted

## What a head-butt looks like where it lands (puzzle #2 round 2, the user
## 2026-10-07: "show some kind of visual for the ramping and the impact"):
## a burst of little stars, a "BONK!" that pops up and fades, and sparks
## when it's metal. Seen by both players (it's in the world).


static func _root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("world_root") if tree else null


## Stars and a "BONK!" at `at`; `metal` adds orange sparks.
static func impact(at: Vector3, metal := false, word := "BONK!") -> void:
	var root := _root()
	if root == null:
		return
	_burst(root, at, Color(1.0, 0.95, 0.55), 18, 2.6, 0.55, 0.07)
	if metal:
		_burst(root, at, Color(1.0, 0.55, 0.15), 14, 4.5, 0.35, 0.035)
	var l := Label3D.new()
	l.text = word
	l.font_size = 96
	l.pixel_size = 0.0026     # ~0.25 m letters: readable to both, not a wall in your face
	l.modulate = Color(1.0, 0.92, 0.35)
	l.outline_size = 22
	l.outline_modulate = Color(0.25, 0.1, 0.05)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	root.add_child(l)
	l.global_position = at + Vector3.UP * 0.25
	l.scale = Vector3.ONE * 0.4
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "global_position", at + Vector3.UP * 0.8, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


static func _burst(root: Node, at: Vector3, col: Color, n: int, speed: float, life: float, size: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = n
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6.0, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	p.angle_min = 0.0
	p.angle_max = 360.0
	root.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
