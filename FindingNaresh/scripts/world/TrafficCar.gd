class_name TrafficCar
extends AnimatableBody3D

## Simple town traffic. Cars follow one road's sampled centreline, keep left,
## brake for anything in their lane (the van, another car, a person on foot)
## and U-turn across the road at the ends of their patrol.

const CRUISE := 9.0             ## m/s, about 32 km/h
const TURN_SPEED := 3.5         ## m/s round the U-turn
## Lane centre from the road's centre line (the road is 8 m wide). Close to the
## verge, so a 2.24 m van driven down the middle still passes with room to spare.
const LANE_OFFSET := 2.4
const LOOK_AHEAD := 13.0

var route: Route
var first := 0
var last := 0
var progress := 0.0            ## route sample index, including fractions
var direction := 1             ## +1 along the route, -1 toward its start
var speed := 0.0
var waiting := false
var _turn := -1.0              ## 0..1 through a U-turn at a patrol end, else -1
var _heading := Vector3.FORWARD
var _probe: BoxShape3D


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
	_probe = BoxShape3D.new()
	_probe.size = Vector3(1.8, 1.1, LOOK_AHEAD)   # this lane only, not the one beside it
	_position_on_road()


func _physics_process(delta: float) -> void:
	if route == null:
		return
	waiting = _blocked()
	var cruise := TURN_SPEED if _turn >= 0.0 else CRUISE
	var target := 0.0 if waiting else cruise
	speed = move_toward(speed, target, (12.0 if waiting else 2.0) * delta)
	if _turn >= 0.0:
		_turn += speed * delta / (PI * LANE_OFFSET)
		if _turn >= 1.0:
			_turn = -1.0
			direction = -direction
	else:
		progress += float(direction) * speed * delta / Route.SAMPLE_SPACING
		if progress >= float(last) or progress <= float(first):
			progress = clampf(progress, float(first), float(last))
			_turn = 0.0
	_position_on_road()


## Anything solid in a car-wide box over the next LOOK_AHEAD metres of lane.
func _blocked() -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _probe
	q.collision_mask = 1 | 2 | 8
	q.exclude = [get_rid()]
	q.transform = Transform3D(Basis.looking_at(_heading, Vector3.UP),
		global_position + Vector3.UP * 0.95 + _heading * (2.0 + LOOK_AHEAD * 0.5))
	for hit in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var body: Object = hit["collider"]
		if body is Camper or body is TrafficCar or body is PlayerRig:
			return true
	return false


func _position_on_road() -> void:
	if route == null:
		return
	var i := clampi(int(progress), first, last - 1)
	var t := clampf(progress - float(i), 0.0, 1.0)
	var p := route.point(i).lerp(route.point(i + 1), t)
	var f := route.forward(i).lerp(route.forward(i + 1), t).normalized() * float(direction)
	var left := -route.right(i).lerp(route.right(i + 1), t).normalized() * float(direction)
	f.y = 0.0
	left.y = 0.0
	f = f.normalized()
	left = left.normalized()
	if _turn >= 0.0:
		# half a circle about the centreline, from this lane into the other
		var a := _turn * PI
		p += left * LANE_OFFSET * cos(a) + f * LANE_OFFSET * sin(a)
		_heading = (f * cos(a) - left * sin(a)).normalized()
	else:
		p += left * LANE_OFFSET
		_heading = f
	global_transform = Transform3D(Basis.looking_at(_heading, Vector3.UP), p + Vector3.UP * 0.13)
