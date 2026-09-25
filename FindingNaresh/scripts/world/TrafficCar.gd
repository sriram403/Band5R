class_name TrafficCar
extends AnimatableBody3D

## Ordinary traffic (placed from the table in `LevelLayout.TRAFFIC` by
## `Traffic`). Cars follow one road's sampled centreline, keep left, slow
## down behind anything in their lane, stop for it when it is close (the van,
## another car, a person on foot) and U-turn across the road at the ends of
## their patrol. Far from everyone they sleep.

const CRUISE := 9.0             ## m/s, about 32 km/h
const TURN_SPEED := 3.5         ## m/s round the U-turn
## Lane centre from the road's centre line (the road is 8 m wide). Close to the
## verge, so a 2.24 m van driven down the middle still passes with room to spare.
const LANE_OFFSET := 2.4
const LOOK_AHEAD := 13.0        ## m; anything this close ahead in the lane: stop
const SLOW_AHEAD := 32.0        ## m; anything this close ahead: half speed
const SLEEP_BEYOND := 600.0     ## m from every player and the van: stand still

var route: Route
var first := 0
var last := 0
var progress := 0.0            ## route sample index, including fractions
var direction := 1             ## +1 along the route, -1 toward its start
var speed := 0.0
var waiting := false
var slowing := false
var active := true             ## false: put away by the mood curve (Traffic.density)
var lane_offset := LANE_OFFSET
var _turn := -1.0              ## 0..1 through a U-turn at a patrol end, else -1
var _heading := Vector3.FORWARD
var _probes := {}              ## look-ahead length -> BoxShape3D
var _asleep := false
var body_half := 2.0           ## m from its middle to its nose, where the look-ahead starts
var _sleep_t := 0.0


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
	_build()
	_position_on_road()


## The body and its collision. A lorry builds its own.
func _build() -> void:
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


## How wide a strip ahead it watches: its own lane, not the one beside it.
func _probe_width() -> float:
	return 1.8


## Out on the road, or put away (mood curve): hidden, no collision, no driving.
func set_active(on: bool) -> void:
	active = on
	visible = on
	collision_layer = 1 if on else 0
	set_physics_process(on)


func _physics_process(delta: float) -> void:
	if route == null:
		return
	_sleep_t -= delta
	if _sleep_t <= 0.0:
		_sleep_t = 0.5
		_asleep = not _anyone_within(SLEEP_BEYOND)
	if _asleep:
		return
	waiting = _blocked(LOOK_AHEAD)
	slowing = not waiting and _blocked(SLOW_AHEAD)
	var cruise := TURN_SPEED if _turn >= 0.0 else CRUISE * (0.5 if slowing else 1.0)
	var target := 0.0 if waiting else cruise
	speed = move_toward(speed, target, (12.0 if waiting else 2.0 if target > speed else 5.0) * delta)
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


func _anyone_within(r: float) -> bool:
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_position) < r:
			return true
	var van := get_tree().get_first_node_in_group("camper") as Node3D
	return van != null and van.global_position.distance_to(global_position) < r


## Anything solid in a lane-wide box over the next `length` metres.
func _blocked(length: float) -> bool:
	if not _probes.has(length):
		var sh := BoxShape3D.new()
		sh.size = Vector3(_probe_width(), 1.1, length)
		_probes[length] = sh
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _probes[length]
	q.collision_mask = 1 | 2 | 8
	q.exclude = [get_rid()]
	q.transform = Transform3D(Basis.looking_at(_heading, Vector3.UP),
		global_position + Vector3.UP * 0.95 + _heading * (body_half + length * 0.5))
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
		p += left * lane_offset
		_heading = f
		# pulled off onto the verge: sit on the ground there, not the road
		if lane_offset > Landscape.ROAD_HALF:
			var g := Landscape.ground(p.x, p.z)
			p.y = lerpf(p.y, g, clampf((lane_offset - Landscape.ROAD_HALF) / 1.5, 0.0, 1.0))
	global_transform = Transform3D(Basis.looking_at(_heading, Vector3.UP), p + Vector3.UP * 0.13)
