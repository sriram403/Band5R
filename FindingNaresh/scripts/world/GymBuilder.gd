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

const GYMS := ["base", "tyre", "house", "traffic", "tagging", "binoculars", "stealth", "creature", "naresh"]
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
	# a second straight for the lorry, clear of the town car's patrol
	network.add(Route.new(PackedVector2Array([Vector2(-300, 340), Vector2(0, 340), Vector2(300, 340)]), false, base), "gym_lorry")
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
	if gym == "creature":
		_creature_gym()
	if gym == "naresh":
		_naresh_gym()
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
	var lr := network.road("gym_lorry")
	var lorry := Lorry.new()
	lorry.name = "GymLorry"
	lorry.configure(lr, 150, 270, 150, 1)
	world.add_child(lorry)


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
	# a cardboard box and two crates to throw, by the players' start
	var box := CardboardBox.new()
	box.name = "GymBox"
	world.add_child(box)
	box.position = STEALTH_EYE + Vector3(4, 0.1, 36)
	poi["stealth_box"] = box.position
	for k in 2:
		var cr := Crate.new()
		cr.name = "LureCrate%d" % (k + 1)
		world.add_child(cr)
		cr.position = STEALTH_EYE + Vector3(-4 - k * 1.2, 0.1, 36)
	var c := Creature.new()
	c.name = "GymCreature"
	world.add_child(c)
	c.position = STEALTH_EYE
	c.rotation.y = PI       # facing +Z, the players' side
	c.patrol = PackedVector3Array([STEALTH_EYE + Vector3(-15, 0, 0), STEALTH_EYE + Vector3(15, 0, 0)])
	poi["creature"] = STEALTH_EYE
	# drop points 150-400 m away, each by a marked post
	for spec in [[Vector3(60, 0, 190), "the south post"], [Vector3(-200, 0, -60), "the west post"], [Vector3(60, 0, -560), "the far north post"]]:
		var at: Vector3 = spec[0]
		at.y = _h(at.x, at.z)
		world.add_child(Build.box(Vector3(0.3, 4.0, 0.3), ToonMat.make(Color(0.9, 0.3, 0.25)), at + Vector3(2, 2, 0), Vector3.ZERO, "DropPost"))
		world.add_child(Build.label3d(spec[1], at + Vector3(2, 4.6, 0), Vector3.ZERO, 0.8, Color(1, 0.95, 0.8)))
		drop_points.append({"pos": at, "near": spec[1]})


## The van parked with a creature on a patrol 45 m in front of it, stakes every
## 10 m in between, and two drop posts. Tunes the attack and the tarp.
const CREATURE_EYE := Vector3(0, 0, -15)

func _creature_gym() -> void:
	for k in range(1, 5):
		var z := 30.0 - 3.0 - k * 10.0
		world.add_child(Build.label3d("%d m" % (k * 10), Vector3(-4.0, 0.05, z), Vector3(-90, 0, 0), 0.8, Color(1, 0.9, 0.6)))
	var c := Creature.new()
	c.name = "GymCreature"
	world.add_child(c)
	c.position = CREATURE_EYE
	c.rotation.y = PI
	c.patrol = PackedVector3Array([CREATURE_EYE + Vector3(-10, 0, 0), CREATURE_EYE + Vector3(10, 0, 0)])
	poi["creature"] = CREATURE_EYE
	for spec in [[Vector3(0, 0, 230), "the south post"], [Vector3(-220, 0, 30), "the west post"]]:
		var at: Vector3 = spec[0]
		at.y = _h(at.x, at.z)
		world.add_child(Build.box(Vector3(0.3, 4.0, 0.3), ToonMat.make(Color(0.9, 0.3, 0.25)), at + Vector3(2, 2, 0), Vector3.ZERO, "DropPost"))
		world.add_child(Build.label3d(spec[1], at + Vector3(2, 4.6, 0), Vector3.ZERO, 0.8, Color(1, 0.95, 0.8)))
		drop_points.append({"pos": at, "near": spec[1]})


## The Naresh gym (design/NARESH.md): the base yard's cans (one empty), jug,
## crates and wall, plus a wall with three ways through it: a heavy shutter
## (someone holds it up), a gate on a spring lever 4 m off (someone holds the
## lever) and a gate on a crank (worked once, it stays up). A fuel can hidden
## behind the hide wall for his "I know where one is" act; a red timed zone
## where no random act may happen; a creature asleep in its pen with a switch
## by the start; two high places far off where it leaves him.
const NARESH_WALL_Z := 0.0
const NARESH_GAPS := {"shutter": 16.0, "lever": 26.0, "crank": 36.0}
const NARESH_CREATURE := Vector3(70, 0, -40)

func _naresh_gym() -> void:
	var stone := ToonMat.make(C_STONE)
	var wood := ToonMat.make(C_WOOD)
	var steel := ToonMat.make(Color(0.55, 0.58, 0.62))
	var z := NARESH_WALL_Z
	var wall := StaticBody3D.new()
	wall.name = "NareshWall"
	var edges := [10.0]
	for k in ["shutter", "lever", "crank"]:
		edges.append(float(NARESH_GAPS[k]) - 1.5)
		edges.append(float(NARESH_GAPS[k]) + 1.5)
	edges.append(44.0)
	for i in range(0, edges.size(), 2):
		var x0: float = edges[i]
		var x1: float = edges[i + 1]
		var sz := Vector3(x1 - x0, 2.6, 0.4)
		var at := Vector3((x0 + x1) * 0.5, 1.3, z)
		wall.add_child(Build.box(sz, stone, at, Vector3.ZERO, "Wall"))
		wall.add_child(_box_shape(sz, Transform3D(Basis(), at)))
	# a lintel over each gap, so the way through reads as a doorway
	for k in NARESH_GAPS:
		var at := Vector3(float(NARESH_GAPS[k]), 2.45, z)
		wall.add_child(Build.box(Vector3(3.0, 0.3, 0.4), stone, at, Vector3.ZERO, "Lintel"))
		wall.add_child(_box_shape(Vector3(3.0, 0.3, 0.4), Transform3D(Basis(), at)))
	world.add_child(wall)

	# 1. the heavy shutter: hold its handle and it rolls up; let go and it drops
	var sx: float = NARESH_GAPS["shutter"]
	var shutter := _gym_gate("Shutter", Vector3(sx, 0, z), Vector3(2.9, 2.3, 0.12), steel)
	var handle := Workable.new()
	handle.name = "ShutterHandle"
	handle.kind = "hold"
	handle.label = "shutter"
	handle.verb = "hold up"
	handle.work_s = 1.2
	handle.close_s = 0.8
	handle.stand = Vector3(0, 0, 0.9)
	handle.add_child(Build.box(Vector3(0.5, 0.12, 0.12), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3.ZERO, Vector3.ZERO, "Grip"))
	handle.add_child(_box_shape(Vector3(0.6, 0.4, 0.4), Transform3D.IDENTITY))
	handle.position = Vector3(sx + 2.1, 1.1, z + 0.35)
	handle.on_amount = func(a: float): shutter.position.y = a * 2.2
	world.add_child(handle)
	poi["naresh_shutter"] = handle.position
	poi["naresh_shutter_gap"] = Vector3(sx, 0, z)

	# 2. the lever gate: hold the spring lever 4 m away, the gate is up
	var lx: float = NARESH_GAPS["lever"]
	var gate := _gym_gate("LeverGate", Vector3(lx, 0, z), Vector3(2.9, 2.3, 0.2), wood)
	var lever := Workable.new()
	lever.name = "GymLever"
	lever.kind = "hold"
	lever.label = "lever"
	lever.verb = "pull down"
	lever.work_s = 0.7
	lever.close_s = 0.5
	lever.stand = Vector3(0, 0, 0.9)
	var arm := Node3D.new()
	arm.name = "Arm"
	lever.add_child(arm)
	arm.add_child(Build.box(Vector3(0.08, 0.9, 0.08), ToonMat.make(Color(0.85, 0.2, 0.18)), Vector3(0, 0.45, 0), Vector3.ZERO, "Handle"))
	lever.add_child(Build.box(Vector3(0.4, 1.0, 0.3), steel, Vector3(0, -0.5, 0), Vector3.ZERO, "Post"))
	lever.add_child(_box_shape(Vector3(0.5, 1.9, 0.5), Transform3D(Basis(), Vector3(0, 0, 0))))
	lever.position = Vector3(lx - 4.0, 1.0, z + 2.5)
	lever.on_amount = func(a: float):
		arm.rotation.x = deg_to_rad(-70.0) * a
		gate.position.y = 2.2 * clampf(a * 1.5, 0.0, 1.0)
	world.add_child(lever)
	poi["naresh_lever"] = lever.position
	poi["naresh_lever_gap"] = Vector3(lx, 0, z)

	# 3. the crank gate: 8 s of cranking and it's up for good
	var cx: float = NARESH_GAPS["crank"]
	var cgate := _gym_gate("CrankGate", Vector3(cx, 0, z), Vector3(2.9, 2.3, 0.2), wood)
	var crank := Workable.new()
	crank.name = "GymCrank"
	crank.kind = "work"
	crank.label = "crank"
	crank.verb = "turn"
	crank.work_s = 8.0
	crank.stand = Vector3(0, 0, 0.9)
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	crank.add_child(wheel)
	wheel.add_child(Build.cyl(0.35, 0.06, steel, Vector3.ZERO, Vector3(90, 0, 0), 14, "Rim"))
	wheel.add_child(Build.box(Vector3(0.06, 0.06, 0.3), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3(0.3, 0, 0.15), Vector3.ZERO, "Knob"))
	crank.add_child(Build.box(Vector3(0.3, 1.0, 0.3), steel, Vector3(0, -0.5, -0.1), Vector3.ZERO, "Post"))
	crank.add_child(_box_shape(Vector3(0.8, 1.9, 0.5), Transform3D(Basis(), Vector3(0, -0.1, 0))))
	crank.position = Vector3(cx + 4.0, 1.0, z + 2.5)
	crank.on_amount = func(a: float):
		wheel.rotation.z = -a * TAU * 6.0
		cgate.position.y = 2.2 * a
	world.add_child(crank)
	poi["naresh_crank"] = crank.position
	poi["naresh_crank_gap"] = Vector3(cx, 0, z)
	for k in NARESH_GAPS:
		var names := {"shutter": "SHUTTER: hold it up", "lever": "LEVER GATE: hold the lever", "crank": "CRANK GATE: work it"}
		world.add_child(Build.label3d(names[k], Vector3(float(NARESH_GAPS[k]), 3.2, z + 0.3), Vector3.ZERO, 0.45, Color(1, 0.95, 0.7)))

	# a cardboard box to store, and a fuel can hidden behind the hide wall
	var box := CardboardBox.new()
	box.name = "NareshBox"
	world.add_child(box)
	box.position = Vector3(-14, 0.1, 22)
	poi["naresh_box"] = box.position
	_place_can(Vector3(-40, 0, -31.6), FuelCan.CAPACITY, "gym_hidden_can")
	(world.get_node("FuelCan_gym_hidden_can") as Node).add_to_group("naresh_find")

	# the timed zone: no random act while he or a player is on the red disc
	var calm := Node3D.new()
	calm.name = "TimedZone"
	calm.position = Vector3(0, 0, -45)
	calm.add_to_group("naresh_calm")
	calm.set_meta("radius", 7.0)
	calm.add_child(Build.cyl(7.0, 0.04, ToonMat.flat(Color(0.75, 0.22, 0.2)), Vector3(0, 0.03, 0), Vector3.ZERO, 32, "Disc"))
	calm.add_child(Build.label3d("TIMED ZONE\nno random acts", Vector3(0, 2.2, 0), Vector3.ZERO, 0.6, Color(1, 0.85, 0.8)))
	world.add_child(calm)
	poi["naresh_calm"] = calm.position

	# the creature, asleep in its pen until the switch by the start wakes it
	var pen := StaticBody3D.new()
	pen.name = "CreaturePen"
	for spec in [[Vector3(20, 1.0, 0.3), Vector3(0, 0.5, -10)], [Vector3(0.3, 1.0, 20), Vector3(-10, 0.5, 0)], [Vector3(0.3, 1.0, 20), Vector3(10, 0.5, 0)]]:
		pen.add_child(Build.box(spec[0], wood, spec[1], Vector3.ZERO, "Fence"))
	pen.position = NARESH_CREATURE
	world.add_child(pen)
	var cr := Creature.new()
	cr.name = "GymCreature"
	cr.dormant = true
	world.add_child(cr)
	cr.position = NARESH_CREATURE
	cr.rotation.y = PI
	cr.patrol = PackedVector3Array([NARESH_CREATURE + Vector3(-6, 0, 0), NARESH_CREATURE + Vector3(6, 0, 0)])
	poi["creature"] = NARESH_CREATURE
	var sw := StaticBody3D.new()
	sw.name = "CreatureSwitch"
	sw.add_child(Build.box(Vector3(0.15, 1.2, 0.15), wood, Vector3(0, 0.6, 0), Vector3.ZERO, "Post"))
	var lamp := Build.box(Vector3(0.4, 0.3, 0.2), ToonMat.flat(Color(0.3, 0.3, 0.32)), Vector3(0, 1.3, 0), Vector3.ZERO, "Lamp")
	sw.add_child(lamp)
	sw.add_child(_box_shape(Vector3(0.5, 1.5, 0.4), Transform3D(Basis(), Vector3(0, 0.75, 0))))
	var sw_label := Build.label3d("CREATURE: asleep", Vector3(0, 1.9, 0), Vector3.ZERO, 0.3, Color(1, 0.9, 0.8))
	sw.add_child(sw_label)
	sw.set_meta("prompt", "Wake the creature")
	sw.set_meta("prompt_fn", func(_p) -> String: return "Put the creature to sleep" if not cr.dormant else "Wake the creature")
	sw.set_meta("callback", func(_p):
		cr.dormant = not cr.dormant
		sw_label.text = "CREATURE: asleep" if cr.dormant else "CREATURE: AWAKE"
		lamp.material_override = ToonMat.flat(Color(0.3, 0.3, 0.32) if cr.dormant else Color(0.95, 0.2, 0.15)))
	sw.position = Vector3(-12, 0, 38)
	world.add_child(sw)
	poi["creature_switch"] = sw.position + Vector3(0, 1.3, 0)

	# where it leaves him: a tall platform and a hut roof, 250-300 m from the pen
	var drops := [[Vector3(80, 0, -300), 5.0, "the tall platform"], [Vector3(-230, 0, -40), 3.5, "the hut roof"]]
	for spec in drops:
		var at: Vector3 = spec[0]
		var h: float = spec[1]
		var body := StaticBody3D.new()
		body.name = "NareshDrop"
		body.add_child(Build.box(Vector3(5, h, 5), stone, Vector3(0, h * 0.5, 0), Vector3.ZERO, "Block"))
		body.add_child(_box_shape(Vector3(5, h, 5), Transform3D(Basis(), Vector3(0, h * 0.5, 0))))
		body.add_child(Build.label3d(spec[2], Vector3(0, h + 3.0, 0), Vector3.ZERO, 1.0, Color(1, 0.95, 0.8)))
		body.position = at
		world.add_child(body)
		naresh_drops.append({"pos": at + Vector3(0, h, 0), "near": spec[2]})
	# and for players the creature takes, two posts
	for spec in [[Vector3(-150, 0, 150), "the south-west post"], [Vector3(200, 0, 120), "the east post"]]:
		var at: Vector3 = spec[0]
		world.add_child(Build.box(Vector3(0.3, 4.0, 0.3), ToonMat.make(Color(0.9, 0.3, 0.25)), at + Vector3(2, 2, 0), Vector3.ZERO, "DropPost"))
		drop_points.append({"pos": at, "near": spec[1]})
	poi["naresh_spawn"] = Vector3(-3, 0.1, 35)


## A gate panel that slides up out of a doorway (its collider goes with it).
func _gym_gate(nm: String, at: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var g := StaticBody3D.new()
	g.name = nm
	var holder := Node3D.new()
	holder.name = nm + "Frame"
	holder.position = at
	world.add_child(holder)
	g.add_child(Build.box(size, mat, Vector3(0, size.y * 0.5, 0), Vector3.ZERO, "Panel"))
	g.add_child(_box_shape(size, Transform3D(Basis(), Vector3(0, size.y * 0.5, 0))))
	holder.add_child(g)
	return g


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
