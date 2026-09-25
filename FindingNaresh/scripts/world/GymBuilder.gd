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

const GYMS := ["base", "tyre", "house", "traffic", "tagging", "binoculars", "stealth"]
## Stealth gym: a creature at STEALTH_EYE facing the players' side (+Z), cover
## pieces between, the players' lane 30 m out.
const STEALTH_EYE := Vector3(60, 0, -30)
## Tagging gym: [distance m, bearing degrees right of straight ahead] for each
## board, fanned out so no board hides another. The last one is past
## TagMarker.RANGE and must not take a tag.
const TAG_BOARDS := [[10, -30.0], [25, -14.0], [50, 0.0], [100, 7.0], [150, 12.0], [220, 16.0]]
const TAG_LANE := Vector3(20, 0, 40)      ## where the players stand, looking -Z
## Binocular gym: [distance m, bearing degrees] for each reading sign. Every
## sign carries three codes with letters 0.6, 0.3 and 0.15 m tall, so the
## screenshots show the smallest text that can be read at each distance.
const BINO_SIGNS := [[50, -12.0], [100, -4.0], [200, 3.0], [300, 8.0], [400, 12.0]]
const BINO_TEXT := [0.6, 0.3, 0.15]
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
	if gym == "house":
		_house_gym()
	if gym == "traffic":
		_traffic_gym()
	if gym == "tagging":
		_tagging_gym()
	if gym == "binoculars":
		_binocular_gym()
	if gym == "stealth":
		_stealth_gym()
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
	var spill := Build.nail_spill(6.0)
	spill.basis = Basis.looking_at(Vector3(1, 0, 0), Vector3.UP)   # the van comes from -X
	spill.position = Vector3(0, 0.02, 250)
	world.add_child(spill)
	world.add_child(Build.label3d("ROADWORKS - NAILS", Vector3(-8, 2.1, 250), Vector3.ZERO, 0.7, Color(1, 0.8, 0.3)))
	poi["tyre_nails"] = trap.position


func _house_gym() -> void:
	var house := HouseInterior.new()
	house.name = "OpeningHouse"
	world.add_child(house)
	house.position = Vector3(0, _h(0, -55), -55)
	poi["house_kitchen"] = house.position + Vector3(-2.5, 0.2, -0.5)
	poi["house_upstairs"] = house.position + Vector3(-2.5, 3.5, 1.0)
	poi["house_shed"] = house.position + Vector3(8.5, 0.2, 0)


func _traffic_gym() -> void:
	var road := network.road("gym_straight")
	var car := TrafficCar.new()
	car.name = "GymTrafficCar"
	car.configure(road, 45, 210, 95, 1)
	world.add_child(car)
	poi["traffic_block"] = road.point(145) - road.right(145) * TrafficCar.LANE_OFFSET


func _tagging_gym() -> void:
	var mat := ToonMat.make(Color(0.92, 0.9, 0.82))
	var post := ToonMat.make(C_WOOD)
	for spec in TAG_BOARDS:
		var d := int(spec[0])
		var a := deg_to_rad(float(spec[1]))
		var at := TAG_LANE + Vector3(sin(a), 0, -cos(a)) * float(d)
		at.y = _h(at.x, at.z)
		var body := StaticBody3D.new()
		body.name = "TagBoard%d" % d
		body.set_meta("tag_name", "board %d m" % d)
		body.add_child(Build.box(Vector3(2.0, 2.0, 0.12), mat, Vector3(0, 2.0, 0), Vector3.ZERO, "Board"))
		body.add_child(_box_shape(Vector3(2.0, 2.0, 0.12), Transform3D(Basis(), Vector3(0, 2.0, 0))))
		for sx in [-0.8, 0.8]:
			body.add_child(Build.box(Vector3(0.12, 1.0, 0.12), post, Vector3(sx, 0.5, 0), Vector3.ZERO, "Post"))
		body.add_child(Build.label3d("%d m" % d, Vector3(0, 2.3, 0.07), Vector3.ZERO, 0.8, Color(0.15, 0.15, 0.15)))
		body.position = at
		body.rotation.y = -a      # face the lane
		world.add_child(body)
		poi["tag_board_%d" % d] = at + Vector3(0, 2.0, 0)
	# something that moves, to check a tag follows it
	var crate := Crate.new()
	crate.name = "TagCrate"
	world.add_child(crate)
	crate.position = TAG_LANE + Vector3(-9, 0.3, -4)
	poi["tag_crate"] = crate.position


func _binocular_gym() -> void:
	var board := ToonMat.make(Color(0.95, 0.94, 0.88))
	var post := ToonMat.make(C_WOOD)
	for spec in BINO_SIGNS:
		var d := int(spec[0])
		var a := deg_to_rad(float(spec[1]))
		var at := TAG_LANE + Vector3(sin(a), 0, -cos(a)) * float(d)
		at.y = _h(at.x, at.z)
		var body := StaticBody3D.new()
		body.name = "BinoSign%d" % d
		body.set_meta("tag_name", "sign %d m" % d)
		body.add_child(Build.box(Vector3(5.0, 3.2, 0.15), board, Vector3(0, 3.0, 0), Vector3.ZERO, "Board"))
		body.add_child(_box_shape(Vector3(5.0, 3.2, 0.15), Transform3D(Basis(), Vector3(0, 3.0, 0))))
		for sx in [-2.2, 2.2]:
			body.add_child(Build.box(Vector3(0.15, 1.5, 0.15), post, Vector3(sx, 0.75, 0), Vector3.ZERO, "Post"))
		var y := 4.1
		for k in BINO_TEXT.size():
			var h := float(BINO_TEXT[k])
			# a 4-digit code per line, fixed per sign so screenshots can be read back
			var code := "%04d" % ((d * 37 + k * 1013) % 10000)
			var lab := Build.label3d(code, Vector3(0, y - h * 0.5, 0.09), Vector3.ZERO, h * 1.35, Color(0.08, 0.08, 0.1))
			lab.name = "Code%d" % k
			body.add_child(lab)
			y -= h * 1.35 + 0.25
		body.position = at
		body.rotation.y = -a
		world.add_child(body)
		poi["bino_sign_%d" % d] = at + Vector3(0, 3.0, 0)
	var pick := BinocularPickup.new()
	pick.name = "GymBinoculars"
	pick.tag = "gym_binoculars"
	world.add_child(pick)
	pick.position = TAG_LANE + Vector3(-2.5, 0.0, -1.5)
	pick.position.y = _h(pick.position.x, pick.position.z) + 0.9
	var table := StaticBody3D.new()
	table.name = "BinoTable"
	table.add_child(Build.box(Vector3(0.9, 0.9, 0.6), ToonMat.make(C_WOOD), Vector3(0, 0.45, 0), Vector3.ZERO, "Table"))
	table.add_child(_box_shape(Vector3(0.9, 0.9, 0.6), Transform3D(Basis(), Vector3(0, 0.45, 0))))
	table.position = pick.position - Vector3(0, 0.9, 0)
	world.add_child(table)
	poi["gym_binoculars"] = pick.position


func _stealth_gym() -> void:
	var stone := ToonMat.make(C_STONE)
	var bark := ToonMat.make(Color(0.36, 0.27, 0.2))
	var body := StaticBody3D.new()
	body.name = "Cover"
	# [name, size, centre]: a wall that hides a standing player, a rock and a
	# crate stack that hide a crouched one, a tree trunk
	var pieces := [["Wall", Vector3(4, 2.4, 0.4), Vector3(50, 1.2, -18)],
		["Rock", Vector3(1.8, 1.2, 1.4), Vector3(60, 0.6, -18)],
		["Crates", Vector3(1.2, 1.1, 1.2), Vector3(68, 0.55, -18)]]
	for spec in pieces:
		var mesh := Build.box(spec[1], stone if spec[0] != "Crates" else ToonMat.make(C_WOOD), spec[2], Vector3.ZERO, spec[0])
		body.add_child(mesh)
		body.add_child(_box_shape(spec[1], Transform3D(Basis(), spec[2])))
		poi["cover_" + String(spec[0]).to_lower()] = Vector3(spec[2].x, 0, spec[2].z)
	body.add_child(Build.cyl(0.45, 6.0, bark, Vector3(76, 3.0, -18), Vector3.ZERO, 10, "Trunk"))
	var trunk := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = 6.0
	trunk.shape = cyl
	trunk.position = Vector3(76, 3.0, -18)
	body.add_child(trunk)
	poi["cover_trunk"] = Vector3(76, 0, -18)
	world.add_child(body)
	# distance stakes out from the creature, every 5 m
	for k in range(1, 9):
		var z := STEALTH_EYE.z + k * 5.0
		world.add_child(Build.label3d("%d m" % (k * 5), Vector3(STEALTH_EYE.x - 4.0, 0.05, z), Vector3(-90, 0, 0), 0.8, Color(1, 0.9, 0.6)))
	var c := Creature.new()
	c.name = "GymCreature"
	world.add_child(c)
	c.position = STEALTH_EYE
	c.rotation.y = PI       # facing +Z, the players' side
	c.patrol = PackedVector3Array([STEALTH_EYE + Vector3(-15, 0, 0), STEALTH_EYE + Vector3(15, 0, 0)])
	poi["creature"] = STEALTH_EYE


func _gym_spawns() -> void:
	camper_spawn = Transform3D(Basis(), Vector3(0, 0.8, 30))
	if gym == "tyre":
		camper_spawn = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(-85, 0.8, 250))
	poi["camper_spawn"] = camper_spawn.origin
	poi["homestead"] = Vector3(0, 0, 40)
	for k in 2:
		var pos := Vector3(-6.0 - k * 2.0, 0.25, 40.0)
		if gym == "house" and k == 1:
			pos = poi["house_kitchen"]
		if gym == "stealth":
			pos = STEALTH_EYE + Vector3(-1.0 + k * 2.0, 0.25, 40.0)
		if gym == "tagging" or gym == "binoculars":
			pos = TAG_LANE + Vector3(-1.0 + k * 2.0, 0.25, 0)
		player_spawns.append(Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), pos))
