class_name BridgeGate
extends Node3D

## #5 round 2 (2026-10-19): the gate before the lift bridge. A barrier pole
## across the road, raised by a hand winch that stands inside a works fence
## (1.6 m chain-link: a plain jump doesn't clear it, a leg-up does, and this
## is where you learn the leg-up). Hold E on the winch's handle and the pole
## goes up; let go and the ratchet slips: it comes back down. So one of you
## holds it while the other drives the van through. The fence runs out to
## thickets either side, so the van can't go round.

const RAISE := 28.0              ## deg/s while the handle is wound
const SLIP := 55.0               ## deg/s back down when let go
const OPEN_DEG := 80.0
const PASS_DEG := 62.0           ## above this the van fits under
const FENCE_H := 1.6

var angle := 0.0                 ## the pole: 0 down across the road
var _wind_t := 0.0
var half := 4.6                  ## the pole's length across the road
var pole: Node3D
var pole_shape: CollisionShape3D
var _click_t := 0.0
var _said := false


## `xf`: on the road's centre line at the gate, -Z towards the bridge
## (x across the road). `out_len`: how far the fence runs out each side.
func setup(xf: Transform3D, out_len: float) -> void:
	add_to_group("bridge_gate")
	transform = xf
	var steel := ToonMat.make(Color(0.32, 0.33, 0.35), 0.01)
	var concrete := ToonMat.make(Color(0.62, 0.61, 0.58), 0.01)
	var white := ToonMat.make(Color(0.95, 0.95, 0.92), 0.01)
	var redm := ToonMat.make(Color(0.80, 0.14, 0.12), 0.01)
	var gl := func(x: float, z: float) -> float:
		var w := xf * Vector3(x, 0, z)
		return Landscape.ground(w.x, w.z) - xf.origin.y
	# the post the pole hinges on, on the right-hand side; its winch on the
	# bridge side of the fence (inside)
	var hx := -half - 0.4
	var hy: float = gl.call(hx, 0.0)
	add_child(Build.solid_box(Vector3(1.0, 0.25, 1.0), concrete, Vector3(hx, hy - 0.05, 0), Vector3.ZERO, "Pad"))
	add_child(Build.solid_box(Vector3(0.3, 1.3, 0.3), steel, Vector3(hx, hy + 0.65, 0), Vector3.ZERO, "HingePost"))
	var ry: float = gl.call(half, 0.0)
	add_child(Build.solid_box(Vector3(0.16, 1.0, 0.16), steel, Vector3(half + 0.1, ry + 0.4, 0), Vector3.ZERO, "RestPost"))
	pole = Node3D.new()
	pole.name = "Pole"
	pole.position = Vector3(hx, hy + 1.15, 0)
	add_child(pole)
	var n := 8
	var length := 2.0 * half + 0.5
	for i in n:
		pole.add_child(Build.box(Vector3(length / n, 0.16, 0.12), white if i % 2 == 0 else redm,
			Vector3((i + 0.5) * length / n, 0, 0), Vector3.ZERO, "PoleSeg"))
	var body := StaticBody3D.new()
	body.name = "PoleBody"
	add_child(body)
	pole_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0 * half, 1.3, 0.3)
	pole_shape.shape = bs
	pole_shape.position = Vector3(0, (hy + ry) * 0.5 + 0.65, 0)
	body.add_child(pole_shape)
	# the winch: a drum and a crank handle on a stand, inside the fence
	var wz := -1.2
	var wy: float = gl.call(hx - 0.2, wz)
	var winch := Node3D.new()
	winch.name = "Winch"
	winch.position = Vector3(hx - 0.2, wy, wz)
	add_child(winch)
	winch.add_child(Build.solid_box(Vector3(0.5, 0.9, 0.4), steel, Vector3(0, 0.45, 0), Vector3.ZERO, "Stand"))
	winch.add_child(Build.cyl(0.16, 0.42, ToonMat.make(Color(0.5, 0.4, 0.25), 0.01), Vector3(0, 1.0, 0), Vector3(0, 0, 90), 10, "Drum"))
	var handle := Build.box(Vector3(0.05, 0.35, 0.05), redm, Vector3(0.26, 1.0, -0.12), Vector3.ZERO, "Handle")
	winch.add_child(handle)
	winch.add_child(Build.cyl(0.02, 1.6, steel, Vector3(0.1, 1.5, 0.6), Vector3(-55, 0, 0), 4, "Cable"))
	var wa := Build.interact_area(Vector3(0.9, 1.0, 0.9), Vector3(0, 1.0, 0), "", func(_p): pass, "WinchArea")
	wa.set_meta("tag_name", "the gate's winch")
	wa.set_meta("prompt_fn", func(_p) -> String: return "Hold: wind the barrier up")
	wa.set_meta("hold_fn", func(_p, _dt: float): _wind_t = 0.15)
	winch.add_child(wa)
	# the works fence: across the road on the gate's line (the pole is the
	# gap), out to each side and into a thicket
	_fence(Vector3(hx - 0.3, 0, 0), Vector3(-half - out_len, 0, 0.6), steel, 8301)
	_fence(Vector3(half + 0.3, 0, 0), Vector3(half + out_len, 0, -0.5), steel, 8302)
	var p := get_parent() if get_parent() != null else self
	Thicket.grow(p, xf * Vector3(-half - out_len - 5.0, 0, 0.6), 7.0, 8311, "GateThicketA")
	Thicket.grow(p, xf * Vector3(half + out_len + 5.0, 0, -0.5), 7.0, 8312, "GateThicketB")
	# the sign
	var sy: float = gl.call(half + 1.4, 1.0)
	add_child(Build.box(Vector3(0.08, 2.2, 0.08), steel, Vector3(half + 1.4, sy + 1.1, 1.0), Vector3.ZERO, "SignPost"))
	add_child(Build.box(Vector3(1.5, 0.7, 0.05), white, Vector3(half + 1.4, sy + 2.0, 1.05), Vector3.ZERO, "SignBoard"))
	add_child(Build.label3d("BRIDGE WORKS\nNO ENTRY", Vector3(half + 1.4, sy + 2.0, 1.09), Vector3.ZERO, 0.18, Color(0.85, 0.1, 0.08)))
	# Naresh's note on the sign's post, outside, where you stop at the gate
	NareshNote.make(self, "lb_gate", Vector3(half + 1.4, sy + 1.3, 1.1), 0.0,
		"The bridge is one big seesaw. Whatever goes on the front, something has to go on the back. My friend kept saying that. Took me ages.")
	_apply()


## A chain-link fence from `a` to `b` (local), posts every ~2.5 m set into
## the ground where they stand, a mesh panel per span, solid to everyone.
func _fence(a: Vector3, b: Vector3, steel: Material, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var mesh := StandardMaterial3D.new()
	mesh.albedo_color = Color(0.55, 0.58, 0.6, 0.45)
	mesh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.cull_mode = BaseMaterial3D.CULL_DISABLED
	var root := Node3D.new()
	root.name = "WorksFence"
	add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var len := Vector2(b.x - a.x, b.z - a.z).length()
	var count := maxi(2, int(len / 2.5) + 1)
	var prev := Vector3.INF
	for i in count:
		var u := float(i) / float(count - 1)
		var q := a.lerp(b, u) + Vector3(0, 0, rng.randf_range(-0.05, 0.05))
		var w := transform * q
		q.y = Landscape.ground(w.x, w.z) - transform.origin.y
		root.add_child(Build.cyl(0.04, FENCE_H + 0.1, steel, q + Vector3(0, (FENCE_H + 0.1) * 0.5, 0), Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), 6, "FencePost"))
		if prev != Vector3.INF:
			var mid := (prev + q) * 0.5
			var d := q - prev
			var span := Vector2(d.x, d.z).length()
			var yaw := atan2(d.x, d.z)
			var panel := MeshInstance3D.new()
			var pm := QuadMesh.new()
			pm.size = Vector2(span, FENCE_H)
			panel.mesh = pm
			panel.material_override = mesh
			panel.position = mid + Vector3(0, FENCE_H * 0.5, 0)
			panel.rotation = Vector3(0, yaw + PI * 0.5, 0)
			root.add_child(panel)
			root.add_child(Build.box(Vector3(0.03, 0.03, span), steel, mid + Vector3(0, FENCE_H, 0), Vector3(0, rad_to_deg(yaw), 0), "TopWire"))
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(0.12, FENCE_H, span + 0.1)
			cs.shape = bs
			cs.position = mid + Vector3(0, FENCE_H * 0.5, 0)
			cs.rotation = Vector3(0, yaw, 0)
			body.add_child(cs)
		prev = q


func _physics_process(delta: float) -> void:
	_wind_t -= delta
	var was := angle
	if _wind_t > 0.0:
		angle = minf(angle + RAISE * delta, OPEN_DEG)
		_click_t -= delta
		if _click_t <= 0.0 and angle < OPEN_DEG:
			_click_t = 0.18
			Sfx.play3d("click", pole.global_position, -8.0)
	elif angle > 0.0:
		angle = maxf(angle - SLIP * delta, 0.0)
		if was >= OPEN_DEG - 0.1 or not _said:
			Sfx.play3d("creak", pole.global_position, -4.0, 0.1, 1.4)
		if angle <= 0.0:
			Sfx.play3d("hit_metal", pole.global_position, -2.0)
	if angle != was:
		_apply()


func _apply() -> void:
	pole.rotation = Vector3(0, 0, deg_to_rad(angle))
	pole_shape.disabled = angle > PASS_DEG


func is_open() -> bool:
	return angle > PASS_DEG


func reset() -> void:
	angle = 0.0
	_wind_t = 0.0
	_apply()
