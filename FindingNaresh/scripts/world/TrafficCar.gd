class_name TrafficCar
extends AnimatableBody3D

## Simple town traffic. Cars follow one road's sampled centreline, keep left,
## brake for a blocked lane, and turn around at the ends of their patrol.

const CRUISE := 9.0             ## m/s, about 32 km/h
const LANE_OFFSET := 2.1
const LOOK_AHEAD := 13.0

var route: Route
var first := 0
var last := 0
var progress := 0.0            ## route sample index, including fractions
var direction := 1             ## +1 along the route, -1 toward its start
var speed := 0.0
var waiting := false


func configure(r: Route, a: int, b: int, start: int, way: int) -> void:
	route = r
	first = a
	last = b
	progress = float(start)
	direction = 1 if way >= 0 else -1


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1 | 8
	sync_to_physics = true
	var body := ToonMat.make(Color(0.76, 0.72, 0.55) if direction > 0 else Color(0.42, 0.56, 0.70))
	var dark := ToonMat.make(Color(0.18, 0.25, 0.30))
	add_child(Build.box(Vector3(1.65, 0.65, 3.6), body, Vector3(0, 0.45, 0), Vector3.ZERO, "Body"))
	add_child(Build.box(Vector3(1.4, 0.65, 1.8), dark, Vector3(0, 1.05, -0.1), Vector3.ZERO, "Cabin"))
	for x in [-0.75, 0.75]:
		for z in [-1.1, 1.1]:
			add_child(Build.cyl(0.34, 0.18, dark, Vector3(x, 0.23, z), Vector3(0, 0, 90), 10, "Wheel"))
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.7, 1.5, 3.7)
	cs.shape = box
	cs.position = Vector3(0, 0.75, 0)
	add_child(cs)
	_position_on_road()


func _physics_process(delta: float) -> void:
	if route == null:
		return
	var forward := route.forward(int(progress)) * float(direction)
	var start := global_position + Vector3.UP * 0.65 + forward * 2.0
	var q := PhysicsRayQueryParameters3D.create(start, start + forward * LOOK_AHEAD, 1 | 8, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	waiting = not hit.is_empty() and (hit["collider"] is Camper or hit["collider"] is TrafficCar)
	var target := 0.0 if waiting else CRUISE
	speed = move_toward(speed, target, (12.0 if waiting else 2.0) * delta)
	progress += float(direction) * speed * delta / Route.SAMPLE_SPACING
	if progress >= float(last):
		progress = float(last)
		direction = -1
	elif progress <= float(first):
		progress = float(first)
		direction = 1
	_position_on_road()


func _position_on_road() -> void:
	if route == null:
		return
	var i := clampi(int(progress), first, last - 1)
	var t := clampf(progress - float(i), 0.0, 1.0)
	var p := route.point(i).lerp(route.point(i + 1), t)
	var f := route.forward(i).lerp(route.forward(i + 1), t).normalized() * float(direction)
	var left := -route.right(i).lerp(route.right(i + 1), t).normalized() * float(direction)
	p += left * LANE_OFFSET
	global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), p + Vector3.UP * 0.13)
