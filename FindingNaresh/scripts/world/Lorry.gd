class_name Lorry
extends TrafficCar

## The one lorry (design/WAY_OUT.md, decision "once, briefly"). It waits in a
## lay-by on the lane from P2's home to J1. When the van comes up behind it,
## it pulls out just ahead, crawls along for a while holding you up, then
## pulls in to the verge and stops for good. You can wait or overtake.

enum Phase { PARKED, PULL_OUT, CRAWL, PULL_IN, DONE }

const VERGE := 5.6               ## m from the centre line: off the road
const CRAWL := 6.0               ## m/s, about 22 km/h
const CRAWL_M := 70.0            ## m it holds you up for (briefly: ~12 s)
const TRIGGER := Vector2(25.0, 60.0)    ## the van this far behind it (m along the road) sets it off
const SHIFT_S := 3.0             ## s to pull out, or in
const SIZE := Vector3(2.4, 3.1, 8.0)

var phase := Phase.PARKED
var held_up_s := 0.0             ## s the van spent close behind it (tests, tuning)
var _crawled := 0.0
var _shift := 0.0


func _ready() -> void:
	lane_offset = VERGE
	body_half = SIZE.z * 0.5
	super._ready()


func _build() -> void:
	var cab := ToonMat.make(Color(0.86, 0.56, 0.16))
	var wood := ToonMat.make(Color(0.56, 0.41, 0.26))
	var canvas := ToonMat.make(Color(0.36, 0.44, 0.32))
	var dark := ToonMat.make(Color(0.16, 0.18, 0.2))
	var glass := ToonMat.make(Color(0.25, 0.35, 0.42))
	# the nose is -Z, like every car
	add_child(Build.box(Vector3(2.3, 0.35, 7.8), dark, Vector3(0, 0.62, 0), Vector3.ZERO, "Chassis"))
	add_child(Build.box(Vector3(2.3, 1.9, 1.9), cab, Vector3(0, 1.75, -2.9), Vector3.ZERO, "Cab"))
	add_child(Build.box(Vector3(2.0, 0.7, 0.05), glass, Vector3(0, 2.15, -3.87), Vector3.ZERO, "Windscreen"))
	add_child(Build.box(Vector3(2.4, 1.2, 5.6), wood, Vector3(0, 1.4, 1.0), Vector3.ZERO, "Bed"))
	add_child(Build.box(Vector3(2.3, 1.1, 5.4), canvas, Vector3(0, 2.55, 1.0), Vector3.ZERO, "Load"))
	for z in [-2.8, 1.4, 2.9]:
		for x in [-1.05, 1.05]:
			add_child(Build.cyl(0.48, 0.3, dark, Vector3(x, 0.48, z), Vector3(0, 0, 90), 12, "Wheel"))
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE
	cs.shape = box
	cs.position = Vector3(0, SIZE.y * 0.5, 0)
	add_child(cs)


func _probe_width() -> float:
	return 2.5


func _physics_process(delta: float) -> void:
	if route == null or not active:
		return
	match phase:
		Phase.PARKED:
			speed = 0.0
			if _van_behind():
				phase = Phase.PULL_OUT
				_shift = 0.0
				Sfx.play3d("latch", global_position, 0.0)
		Phase.PULL_OUT:
			_shift = minf(1.0, _shift + delta / SHIFT_S)
			lane_offset = lerpf(VERGE, LANE_OFFSET, smoothstep(0.0, 1.0, _shift))
			speed = move_toward(speed, CRAWL * 0.7, 2.0 * delta)
			if _shift >= 1.0:
				phase = Phase.CRAWL
		Phase.CRAWL:
			waiting = _blocked(LOOK_AHEAD)
			speed = move_toward(speed, 0.0 if waiting else CRAWL, (10.0 if waiting else 1.5) * delta)
			_crawled += speed * delta
			if _crawled >= CRAWL_M:
				phase = Phase.PULL_IN
				_shift = 0.0
		Phase.PULL_IN:
			_shift = minf(1.0, _shift + delta / SHIFT_S)
			lane_offset = lerpf(LANE_OFFSET, VERGE, smoothstep(0.0, 1.0, _shift))
			speed = CRAWL * 0.7 * (1.0 - _shift)
			if _shift >= 1.0:
				phase = Phase.DONE
				speed = 0.0
		Phase.DONE:
			speed = 0.0
	if phase == Phase.PULL_OUT or phase == Phase.CRAWL:
		var gap := _van_gap()
		if gap > 0.0 and gap < 25.0:
			held_up_s += delta
	progress = clampf(progress + float(direction) * speed * delta / Route.SAMPLE_SPACING, float(first), float(last))
	_position_on_road()


## Metres along the road from the van (behind) to the lorry; -1 if the van is
## not on this road, or not behind it.
func _van_gap() -> float:
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van == null:
		return -1.0
	var n := route.nearest(van.global_position.x, van.global_position.z)
	if int(n["index"]) < 0 or float(n["dist"]) > 8.0:
		return -1.0
	var along := (progress - float(n["index"])) * Route.SAMPLE_SPACING * float(direction)
	return along if along > 0.0 else -1.0


## The van coming up behind, going this way, at more than a crawl.
func _van_behind() -> bool:
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van == null or van.linear_velocity.length() < 3.0:
		return false
	var gap := _van_gap()
	if gap < TRIGGER.x or gap > TRIGGER.y:
		return false
	var n := route.nearest(van.global_position.x, van.global_position.z)
	return van.linear_velocity.dot(route.forward(int(n["index"])) * float(direction)) > 0.0
