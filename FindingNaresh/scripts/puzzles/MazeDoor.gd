class_name MazeDoor
extends Node3D

## A door set into the barn maze's hedge (puzzle #3 round 2, the snow half).
## They all look alike: an old stable door in a plank frame.
## - "real": the only way on; E opens it, it stays open.
## - "oneway" (S12): real, but once you're through it swings shut behind you
##   and won't open from that side.
## - "fake": opens onto a brick wall set into the hedge. Nothing behind it.
## - "loop": a real opening, but the way behind it runs round and back to
##   this same door.
## Local frame: +Z is the front (the side you come from), the leaf in the
## plane z = 0, hinged on its -X edge, swinging away from you (to -Z).

const W := 1.4
const H := 2.3

var kind := "real"
var is_open := false
var locked := false              ## oneway: shut behind you, no way back
var cell_front := Vector2i.ZERO
var cell_back := Vector2i.ZERO

var _hinge: Node3D
## the leaf only blocks while shut (a static body swung on a tween kept its
## old place in the physics: the 2026-10-12 test walked into an open door)
var _leaf_shape: CollisionShape3D
var _back_area: Area3D


static func make(parent: Node3D, k: String, at: Vector3, yaw: float, front: Vector2i, back: Vector2i) -> MazeDoor:
	var d := MazeDoor.new()
	d.kind = k
	d.name = "MazeDoor_%s_%d_%d" % [k, front.x, front.y]
	d.position = at
	d.rotation.y = yaw
	d.cell_front = front
	d.cell_back = back
	parent.add_child(d)
	return d


func _ready() -> void:
	add_to_group("maze_door")
	var wood := ToonMat.make(Color(0.42, 0.30, 0.20), 0.012)
	var plank := ToonMat.make(Color(0.55, 0.40, 0.26), 0.012)
	var iron := ToonMat.make(Color(0.20, 0.20, 0.22), 0.008)
	# the frame: two posts and a lintel, a little proud of the hedge
	for s in [-1.0, 1.0]:
		add_child(Build.solid_box(Vector3(0.16, H + 0.25, 0.6), wood, Vector3(s * (W * 0.5 + 0.08), (H + 0.25) * 0.5, 0), Vector3.ZERO, "Post"))
	add_child(Build.box(Vector3(W + 0.5, 0.18, 0.6), wood, Vector3(0, H + 0.2, 0), Vector3.ZERO, "Lintel"))
	if kind == "fake":
		# what's behind it: old brick, flush with the back of the frame
		# just in front of the hedge's face (inside it they didn't show: 2026-10-12)
		add_child(Build.solid_box(Vector3(W, H, 0.03), ToonMat.make(Color(0.56, 0.24, 0.17)), Vector3(0, H * 0.5, -0.035), Vector3.ZERO, "Bricks"))
		var mortar := ToonMat.flat(Color(0.74, 0.70, 0.62))
		for r in 11:
			add_child(Build.box(Vector3(W - 0.02, 0.025, 0.01), mortar, Vector3(0, 0.2 * (r + 1), -0.015), Vector3.ZERO, "Mortar"))
			for c in 3:
				var x := -W * 0.5 + (c + 0.5 + (0.5 if r % 2 == 0 else 0.0)) * W / 3.0
				if x < W * 0.5:
					add_child(Build.box(Vector3(0.025, 0.2, 0.01), mortar, Vector3(x, 0.2 * (r + 0.5), -0.015), Vector3.ZERO, "Joint"))
	# the leaf on its hinge
	_hinge = Node3D.new()
	_hinge.name = "Hinge"
	_hinge.position = Vector3(-W * 0.5, 0, 0)
	add_child(_hinge)
	var leaf := StaticBody3D.new()
	leaf.name = "Leaf"
	_hinge.add_child(leaf)
	for k in 4:
		leaf.add_child(Build.box(Vector3(W / 4.0 - 0.02, H - 0.05, 0.07), plank, Vector3(W / 8.0 + k * W / 4.0, H * 0.5, 0), Vector3.ZERO, "Plank"))
	for y in [0.35, H - 0.35]:
		leaf.add_child(Build.box(Vector3(W - 0.1, 0.12, 0.09), plank, Vector3(W * 0.5, y, 0.01), Vector3.ZERO, "Brace"))
	leaf.add_child(Build.box(Vector3(0.08, 0.05, 0.12), iron, Vector3(W - 0.2, 1.05, 0.06), Vector3.ZERO, "Latch"))
	_leaf_shape = CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(W, H, 0.12)
	_leaf_shape.shape = sh
	_leaf_shape.position = Vector3(W * 0.5, H * 0.5, 0)
	leaf.add_child(_leaf_shape)
	# use from the front; a real door from behind too (the oneway says it's stuck)
	var a := Build.interact_area(Vector3(1.6, 2.2, 1.0), Vector3(0, 1.1, 0.7), "Open the door", func(p): open_from(p, true), "FrontArea")
	a.set_meta("tag_name", "a door")
	a.set_meta("prompt_fn", func(_p) -> String: return "" if is_open else "Open the door")
	add_child(a)
	if kind != "fake":
		_back_area = Build.interact_area(Vector3(1.6, 2.2, 1.0), Vector3(0, 1.1, -0.7), "Open the door", func(p): open_from(p, false), "BackArea")
		_back_area.set_meta("tag_name", "a door")
		_back_area.set_meta("prompt_fn", func(_p) -> String: return "" if is_open else "Open the door")
		_back_area.set_meta("blocked_fn", func() -> String: return "It won't budge from this side." if locked and not is_open else "")
		add_child(_back_area)


func open_from(p, front: bool) -> void:
	if is_open:
		return
	if not front and locked:
		return
	is_open = true
	_leaf_shape.set_deferred("disabled", true)
	Sfx.play3d("creak", global_position + Vector3.UP * 1.2, 2.0, 0.1, 0.85)
	Sfx.play3d("latch", global_position + Vector3.UP * 1.0, 0.0)
	# away from whoever opens it (+ rotates the leaf's far edge to -Z); a
	# fake one towards you (the bricks are right behind it)
	var to := 1.75 if front else -1.75
	if kind == "fake":
		to = -1.75
	create_tween().tween_property(_hinge, "rotation:y", to, 0.9).set_trans(Tween.TRANS_SINE)
	if kind == "fake" and p != null:
		get_tree().create_timer(0.8).timeout.connect(func():
			Sfx.play3d("hit_soft", global_position + Vector3.UP, 0.0)
			p.say("Behind the door: a brick wall.", 2.5))


## Swings shut (a oneway, behind you): bang, and it's latched.
func slam(lock: bool) -> void:
	if not is_open:
		return
	is_open = false
	locked = lock
	_leaf_shape.set_deferred("disabled", false)
	var tw := create_tween()
	tw.tween_property(_hinge, "rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): Sfx.play3d("bang", global_position + Vector3.UP * 1.2, 4.0))


## Which side of the door a point is on: > 0 the front, < 0 behind.
func side_of(pos: Vector3) -> float:
	return (global_transform.affine_inverse() * pos).z


func reset() -> void:
	is_open = false
	locked = false
	if _hinge != null:
		_hinge.rotation.y = 0.0
		_leaf_shape.set_deferred("disabled", false)
