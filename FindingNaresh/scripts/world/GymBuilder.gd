class_name GymBuilder
extends LevelBuilder

## Gyms: small test maps for building and tuning one mechanic at a time, the
## way studios keep "gym" / "metrics playground" levels. Flat ground with a
## measuring grid, a test road loop, slopes of known grade and the props the
## mechanic needs. Launched with `-- --gym=<name>` (tools/run_test.sh: GYM=name).
##
## Gyms:
##   base   the playground: grid, a road loop, 5 / 10 / 20 % slopes, cans, crates,
##          a coolant jug and a wall to hide behind
## More gyms (tagging, hiding, creatures, Naresh, storm) are added as those
## mechanics are built; each one starts as a copy of `base`.

const GYMS := ["base", "tyre"]
const GRID_HALF := 120.0           ## measuring grid covers +-120 m around the centre
## Test slopes: [x centre, grade]. Each is a 20 m wide hump across the road loop's
## east side, rising for 50 m, so the van can be parked mid-slope.
const SLOPES := [[150.0, 0.05], [185.0, 0.10], [220.0, 0.20]]
const SLOPE_RUN := 50.0

var gym := "base"


func _init(gym_name: String = "base") -> void:
	gym = gym_name if gym_name in GYMS else "base"


static func slope_height(x: float, z: float) -> float:
	var h := 0.0
	for s in SLOPES:
		var dx := absf(x - float(s[0]))
		if dx < 14.0:
			var across := 1.0 - smoothstep(10.0, 14.0, dx)
			h = maxf(h, float(s[1]) * maxf(0.0, SLOPE_RUN - absf(z)) * across)
	return h


func build() -> Node3D:
	Landscape.height_fn = GymBuilder.slope_height
	Landscape.EXTENT = 1200.0
	network = RoadNetwork.new()
	Landscape.setup(null, null, [], [])
	var base := Landscape.base_height
	# the test loop: an oval around the grid, over the slopes on its east side
	var loop := PackedVector2Array()
	for k in 48:
		var a := TAU * float(k) / 48.0
		loop.append(Vector2(cos(a) * 185.0, sin(a) * 130.0))
	route = network.add(Route.new(loop, true, base), "gym_loop")
	# a straight for acceleration and braking runs, joining the loop at its south
	network.add(Route.new(PackedVector2Array([Vector2(-300, 250), Vector2(0, 250), Vector2(300, 250)]), false, base), "gym_straight")
	# a short stream in the north-west corner for water tests
	river = Route.new(PackedVector2Array([Vector2(-420, -520), Vector2(-300, -400), Vector2(-180, -330)]), false, base, NAN, NAN, 40)
	river.make_monotonic_descending()
	Landscape.setup(network, river, [], [])
	Landscape.set_pads([])

	world = Node3D.new()
	world.name = "World"
	world.add_to_group("world_root")
	world.add_child(_environment())
	world.add_child(_sun())
	world.add_child(Landscape.build_terrain())
	var lift := 0.0
	for r in network.roads:
		world.add_child(Landscape.build_road(r, lift))
		lift += 0.004
	world.add_child(Landscape.build_river())
	_grid()
	_slope_signs()
	_gym_props()
	if gym == "tyre":
		_tyre_trap()
	_world_edge()
	_gym_spawns()
	return world


## Dark lines every 10 m, brighter every 50 m, with distance labels.
func _grid() -> void:
	var line := BoxMesh.new()
	line.size = Vector3(1, 1, 1)
	var xforms: Array = []
	var colors: Array = []
	var n := int(GRID_HALF / 10.0)
	for k in range(-n, n + 1):
		var c := float(k) * 10.0
		var major := k % 5 == 0
		var w := 0.25 if major else 0.12
		for axis in 2:
			var sz := Vector3(GRID_HALF * 2.0, 0.03, w) if axis == 0 else Vector3(w, 0.03, GRID_HALF * 2.0)
			var pos := Vector3(0, 0.02, c) if axis == 0 else Vector3(c, 0.02, 0)
			xforms.append(Transform3D(Basis.from_scale(sz), pos))
			colors.append(Color(0.95, 0.95, 0.9) if major else Color(0.2, 0.25, 0.2))
		if major:
			var lab := Build.label3d("%d m" % int(c), Vector3(c + 1.0, 0.05, 2.0), Vector3(-90, 0, 0), 1.2, Color(1, 1, 0.85))
			world.add_child(lab)
	world.add_child(_multi("Grid", line, ToonMat.flat(Color.WHITE), xforms, colors))
	poi["grid_centre"] = Vector3.ZERO


func _slope_signs() -> void:
	for s in SLOPES:
		var x := float(s[0])
		var sign_pos := Vector3(x, _h(x, SLOPE_RUN + 6.0), SLOPE_RUN + 6.0)
		var lab := Build.label3d("%d %% SLOPE" % int(float(s[1]) * 100.0), sign_pos + Vector3(0, 2.2, 0), Vector3.ZERO, 1.0, Color(1, 1, 1))
		world.add_child(lab)
		world.add_child(Build.box(Vector3(0.15, 2.0, 0.15), ToonMat.make(C_WOOD), sign_pos + Vector3(0, 1.0, 0), Vector3.ZERO, "SlopePost"))
		poi["slope_%d" % int(float(s[1]) * 100.0)] = Vector3(x, _h(x, SLOPE_RUN * 0.5), SLOPE_RUN * 0.5)


func _gym_props() -> void:
	_place_can(Vector3(-20, 0, 20), FuelCan.CAPACITY, "gym_can_full")
	_place_can(Vector3(-21, 0, 21.5), FuelCan.CAPACITY, "gym_can_full_b")
	_place_can(Vector3(-18, 0, 22), 0.0, "gym_can_empty")
	var jug := CoolantJug.new()
	jug.name = "CoolantJug"
	world.add_child(jug)
	jug.position = Vector3(-24, 0.3, 20)
	poi["gym_jug"] = jug.position
	for k in 4:
		var crate := Crate.new()
		crate.name = "Crate%d" % k
		world.add_child(crate)
		crate.position = Vector3(-30 + k * 1.4, 0.3, 30)
		poi["crate%d" % k] = crate.position
	# a wall and a shed-sized block to hide behind
	var body := StaticBody3D.new()
	body.name = "HideWall"
	var mat := ToonMat.make(C_STONE)
	for spec in [[Vector3(10, 3, 0.6), Vector3(-40, 1.5, -30)], [Vector3(6, 3.5, 6), Vector3(-60, 1.75, -30)]]:
		body.add_child(Build.box(spec[0], mat, spec[1], Vector3.ZERO, "Block"))
		body.add_child(_box_shape(spec[0], Transform3D(Basis(), spec[1])))
	world.add_child(body)
	poi["hide_wall"] = Vector3(-40, 0, -30)
	var title := Build.label3d("GYM: %s\nF1 developer menu" % gym, Vector3(0, 4.0, -8.0), Vector3.ZERO, 1.4, Color(1, 0.95, 0.6))
	world.add_child(title)


func _tyre_trap() -> void:
	var trap := Area3D.new()
	trap.name = "TyreNails"
	trap.position = Vector3(0, 0.35, 250)
	trap.collision_layer = 0
	trap.collision_mask = 8
	trap.monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 0.8, 9.0)
	cs.shape = box
	trap.add_child(cs)
	trap.body_entered.connect(func(body):
		if body is Camper:
			body.puncture())
	world.add_child(trap)
	var metal := ToonMat.make(Color(0.78, 0.78, 0.76))
	for k in 9:
		world.add_child(Build.box(Vector3(0.08, 0.06, 0.24), metal,
			Vector3(-1.8 + float(k) * 0.45, 0.08, 249.0 + float(k % 3) * 0.8),
			Vector3(0, float(k) * 19.0, 0), "Nail"))
	world.add_child(Build.label3d("ROADWORKS - NAILS", Vector3(-8, 2.1, 250), Vector3.ZERO, 0.7, Color(1, 0.8, 0.3)))
	poi["tyre_nails"] = trap.position


func _gym_spawns() -> void:
	camper_spawn = Transform3D(Basis(), Vector3(0, 0.8, 30))
	if gym == "tyre":
		camper_spawn = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(-85, 0.8, 250))
	poi["camper_spawn"] = camper_spawn.origin
	poi["homestead"] = Vector3(0, 0, 40)
	for k in 2:
		var pos := Vector3(-6.0 - k * 2.0, 0.25, 40.0)
		player_spawns.append(Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), pos))
