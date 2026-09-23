class_name LevelBuilder
extends RefCounted

## Assembles the world: terrain, roads, water, scatter, landmarks, sky.
##
## The journey, south-west to north-east:
##   Homestead -> Homestead Lane -> Windmill Junction (J1)
##     J1 -> Valley Road (long, scenic: Mirror Lake, billboard, barn) -> J2
##     J1 -> Ridge Track (short, steep gravel: lookout, wreck)        -> J2
##   J2 (Last Fuel station) -> Pump House Road -> Water facility -> broken
##   bridge over the Bessi river -> Bessi valley loop around the Five Roses.
## A radio mast on the hill west of the facility is visible from most of the
## map, as are the roses once you are past the facility.
##
## Placements live in the const tables below, so the layout is handcrafted
## data rather than procedural generation. Only the small scatter (trees,
## rocks, bushes) uses a fixed-seed RNG, so the world is identical on every
## run - remembering the route has to be rewarding.

# --- layout (x east, z south; metres) -------------------------------------------
const J1 := Vector2(-330, 300)          ## Windmill Junction: the route choice
const J2 := Vector2(300, 60)            ## Last Fuel: the two routes rejoin

const HOME_LANE := [Vector2(-575, 545), Vector2(-525, 505), Vector2(-470, 450), Vector2(-405, 378), J1]
const VALLEY_ROAD := [J1, Vector2(-285, 378), Vector2(-200, 446), Vector2(-80, 455), Vector2(60, 446),
	Vector2(190, 382), Vector2(268, 268), Vector2(298, 150), J2]
const RIDGE_TRACK := [J1, Vector2(-286, 226), Vector2(-205, 166), Vector2(-112, 126), Vector2(20, 102),
	Vector2(160, 82), J2]
## J2 north past the facility, over the river, into Bessi. The end is snapped
## onto the Bessi loop when the world is built.
const PUMP_HOUSE_ROAD := [J2, Vector2(318, -30), Vector2(342, -110), Vector2(356, -168), Vector2(350, -236),
	Vector2(345, -296), Vector2(396, -307), Vector2(446, -314), Vector2(476, -372)]

const BESSI_CENTRE := Vector2(590, -530)
const BESSI_SCALE := 0.85
static var BESSI_LOOP_SHAPE := PackedVector2Array([
	Vector2(0, -150), Vector2(85, -128), Vector2(140, -55), Vector2(150, 30), Vector2(112, 105),
	Vector2(35, 152), Vector2(-48, 148), Vector2(-120, 95), Vector2(-152, 15), Vector2(-130, -70),
	Vector2(-62, -140),
])

## The river runs north to south between the home side and Bessi.
const RIVER := [Vector2(300, -840), Vector2(335, -620), Vector2(370, -450), Vector2(395, -304),
	Vector2(420, -170), Vector2(470, -40), Vector2(560, 120), Vector2(680, 320), Vector2(840, 480)]

const PONDS := [
	{"pos": Vector3(-140, 0, 528), "radius": 70.0, "depth": 6.0},    # Mirror Lake
	{"pos": Vector3(-612, 0, 610), "radius": 20.0, "depth": 2.4},    # homestead duck pond
]

const ROSE_CENTRE := Vector3(590, 0, -530)
const MOUNDS := [
	# Bessi: raised so the five roses break the treeline; flat top for the plaza
	{"pos": ROSE_CENTRE, "radius": 95.0, "height": 26.0, "plateau": 30.0},
	# Pine Ridge: the ridge track climbs straight over it
	{"pos": Vector3(-190, 0, 150), "radius": 170.0, "height": 30.0},
	# Radio Hill: the mast on top is a landmark from most of the map
	{"pos": Vector3(-460, 0, -330), "radius": 150.0, "height": 48.0},
	# hills that close the valley in and make the edges feel like more world
	{"pos": Vector3(-720, 0, 60), "radius": 220.0, "height": 38.0},
	{"pos": Vector3(20, 0, -660), "radius": 230.0, "height": 42.0},
	{"pos": Vector3(120, 0, 720), "radius": 200.0, "height": 30.0},
]

const FACILITY := Vector3(392, 0, -160)      ## pump house yard, on the west bank
const GAS_STATION := Vector3(262, 0, 34)     ## Last Fuel, at J2
const HOMESTEAD := Vector3(-612, 0, 548)
const WINDMILL := Vector3(-352, 0, 286)
const LOOKOUT := Vector3(-200, 0, 140)
const RADIO_MAST := Vector3(-460, 0, -330)
const BARN := Vector3(118, 0, 488)

## Flat pads under buildings (centre, flat radius, blend distance).
const PADS := [
	{"pos": FACILITY, "radius": 22.0, "blend": 14.0},
	{"pos": GAS_STATION, "radius": 14.0, "blend": 10.0},
	{"pos": HOMESTEAD, "radius": 20.0, "blend": 12.0},
	{"pos": BARN, "radius": 14.0, "blend": 10.0},
]

const SCATTER_SEED := 20260810

# Colours -----------------------------------------------------------------------
const C_TRUNK := Color(0.38, 0.26, 0.18)
const C_LEAF_A := Color(0.30, 0.56, 0.24)
const C_LEAF_B := Color(0.41, 0.66, 0.28)
const C_LEAF_C := Color(0.24, 0.45, 0.26)
const C_ROCK := Color(0.52, 0.51, 0.49)
const C_ROSE := Color(0.83, 0.14, 0.24)
const C_ROSE_DEEP := Color(0.60, 0.08, 0.18)
const C_STONE := Color(0.66, 0.63, 0.58)
const C_WOOD := Color(0.55, 0.38, 0.25)
const C_RUST := Color(0.58, 0.32, 0.20)
const C_STEEL := Color(0.62, 0.66, 0.68)

var network: RoadNetwork
var route: Route                 ## the Bessi loop (kept for the lap test)
var river: Route
var world: Node3D
var camper_spawn := Transform3D.IDENTITY
var player_spawns: Array[Transform3D] = []
var poi: Dictionary = {}         ## named points of interest, for tests and later systems


func build() -> Node3D:
	var t := Time.get_ticks_msec()
	_build_roads()
	t = _lap("roads", t)
	world = Node3D.new()
	world.name = "World"
	world.add_to_group("world_root")

	world.add_child(_environment())
	world.add_child(_sun())
	world.add_child(Landscape.build_terrain())
	t = _lap("terrain", t)
	var lift := 0.0
	for r in network.roads:
		world.add_child(Landscape.build_road(r, lift))
		lift += 0.004
	world.add_child(Landscape.build_river())
	for p in PONDS:
		world.add_child(_pond(p))
	t = _lap("road meshes", t)

	_scatter()
	t = _lap("scatter", t)
	_backdrop()
	_landmarks()
	_signage()
	_items()
	_spawns()
	_lap("landmarks", t)
	return world


func _lap(what: String, since: int) -> int:
	var now := Time.get_ticks_msec()
	print("[World] %s %d ms" % [what, now - since])
	return now


# --- roads and water -----------------------------------------------------------

func _build_roads() -> void:
	network = RoadNetwork.new()
	# Landscape needs ponds and mounds before any road can sample the ground.
	Landscape.setup(null, null, PONDS, MOUNDS)
	var base := Landscape.base_height

	var loop_pts := PackedVector2Array()
	for p in BESSI_LOOP_SHAPE:
		loop_pts.append(BESSI_CENTRE + p * BESSI_SCALE)
	route = network.add(Route.new(loop_pts, true, base), "bessi_loop")

	var j1h := base.call(J1.x, J1.y) as float
	var j2h := base.call(J2.x, J2.y) as float
	network.add(Route.new(PackedVector2Array(HOME_LANE), false, base, NAN, j1h), "home_lane")
	network.add(Route.new(PackedVector2Array(VALLEY_ROAD), false, base, j1h, j2h), "valley_road")
	network.add(Route.new(PackedVector2Array(RIDGE_TRACK), false, base, j1h, j2h, 12), "ridge_track", "gravel")

	# Pump House Road ends on the Bessi loop: snap its last point to the nearest
	# loop sample and pin the height there so the two meet flush.
	var pump := PackedVector2Array(PUMP_HOUSE_ROAD)
	var last := pump[pump.size() - 1]
	var join := route.nearest(last.x, last.y)
	var jp := route.point(int(join["index"]))
	pump.append(Vector2(jp.x, jp.z))
	network.add(Route.new(pump, false, base, j2h, jp.y), "pump_house_road")

	var rv := Route.new(PackedVector2Array(RIVER), false, base, NAN, NAN, 40)
	rv.make_monotonic_descending()
	river = rv
	Landscape.setup(network, river, PONDS, MOUNDS)
	Landscape.set_pads(PADS)

	poi["j1"] = Vector3(J1.x, j1h, J1.y)
	poi["j2"] = Vector3(J2.x, j2h, J2.y)
	poi["bessi_join"] = jp


# --- spawns --------------------------------------------------------------------

func _spawns() -> void:
	var lane := network.road("home_lane")
	var i := 14                      # just up the lane from the homestead gate
	var p := lane.point(i)
	var f := lane.forward(i)
	var r := lane.right(i)
	var basis := Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP)
	camper_spawn = Transform3D(basis, p + r * 1.7 + Vector3.UP * 0.80)
	poi["camper_spawn"] = camper_spawn.origin

	# Stand off the van's rear quarter, looking past it up the lane, so the
	# first view shows the camper, the road and the way ahead.
	var look_at := p + f * 7.0 + r * 1.7
	for k in 2:
		var pos := p + r * (7.5 + k * 2.2) - f * (7.0 + k * 1.2)
		pos.y = _h(pos.x, pos.z) + 0.25
		var to := look_at - pos
		to.y = 0.0
		player_spawns.append(Transform3D(Basis.looking_at(to, Vector3.UP), pos))


# --- environment ---------------------------------------------------------------

func _environment() -> WorldEnvironment:
	var env := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.16, 0.40, 0.82)
	psm.sky_horizon_color = Color(0.62, 0.80, 0.93)
	psm.sky_curve = 0.22
	psm.sky_energy_multiplier = 1.0
	psm.ground_bottom_color = Color(0.20, 0.28, 0.22)
	psm.ground_horizon_color = Color(0.46, 0.60, 0.62)
	psm.sun_angle_max = 9.0
	psm.sun_curve = 0.10
	sky.sky_material = psm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Pure sky ambient, boosted by the saturation grade, turned every large
	# shadow (the plaza under the roses) a deep blue that read as water.
	env.ambient_light_sky_contribution = 0.6
	env.ambient_light_color = Color(0.66, 0.64, 0.62)
	env.ambient_light_energy = 0.55          # keep shadows readable, not milky

	# Linear tonemap plus a small grade keeps the cartoon palette saturated
	# instead of the pastel wash filmic curves give at this light level.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.22
	env.adjustment_contrast = 1.07
	env.adjustment_brightness = 1.0

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.68, 0.80, 0.90)
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.15
	env.fog_density = 0.55
	env.fog_sky_affect = 0.0
	env.fog_depth_begin = 260.0
	env.fog_depth_end = 1500.0
	env.fog_depth_curve = 1.6

	env.glow_enabled = true
	env.glow_intensity = 0.18
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.6

	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 1.1
	env.ssao_power = 2.0

	var we := WorldEnvironment.new()
	we.name = "Environment"
	we.environment = env
	return we


func _sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.965, 0.88)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 220.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.045
	sun.shadow_normal_bias = 1.4
	sun.rotation_degrees = Vector3(-46, 128, 0)
	return sun


func _pond(p: Dictionary) -> MeshInstance3D:
	var c: Vector3 = p["pos"]
	var r: float = p["radius"]
	var level := 0.6
	var m := CylinderMesh.new()
	m.top_radius = Landscape.pond_water_radius(r, level)
	m.bottom_radius = m.top_radius
	m.height = 0.12
	m.radial_segments = 48
	# the bowl floor sits `depth` below the ground the lake was carved from
	var rim := Landscape.base_height(c.x, c.z) + float(p["depth"])
	var y := rim - float(p["depth"]) * level
	var mi := Build.node(m, ToonMat.water(), Transform3D(Basis(), Vector3(c.x, y, c.z)), "Pond")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- scatter -------------------------------------------------------------------

func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED

	var trunks: Array[Transform3D] = []
	var pines: Array[Transform3D] = []
	var pine_cols: Array[Color] = []
	var blobs: Array[Transform3D] = []
	var blob_cols: Array[Color] = []
	var rocks: Array[Transform3D] = []
	var rock_cols: Array[Color] = []
	var bushes: Array[Transform3D] = []
	var bush_cols: Array[Color] = []
	var reeds: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	var flower_cols: Array[Color] = []
	var petal_palette := [Color(0.95, 0.85, 0.30), Color(0.96, 0.96, 0.92), Color(0.78, 0.45, 0.85),
		Color(0.95, 0.55, 0.30), Color(0.55, 0.70, 0.98)]

	var collide_body := StaticBody3D.new()
	collide_body.name = "TreeColliders"

	var half := Landscape.EXTENT * 0.5 - 15.0
	var attempts := 24000
	for _i in attempts:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var kind := rng.randf()
		var keep := rng.randf()
		var d := Landscape.road_distance(x, z)
		if d < 9.5:
			continue
		var rd := Landscape.river_distance(x, z)
		if rd < Landscape.RIVER_HALF + 4.0:
			continue
		if _in_pond(x, z, 4.0):
			# reeds grow on the lake shore instead
			if kind < 0.5 and _near_pond_shore(x, z):
				var ys := rng.randf_range(0.7, 1.3)
				reeds.append(_xf(Vector3(x, _h(x, z) + 0.5 * ys, z), rng.randf_range(0, TAU), Vector3(1, ys, 1)))
			continue
		if _in_clearing(x, z):
			continue
		# thin the woods right beside the road so sightlines stay open, and
		# along the river so the water reads from a distance
		if d < 26.0 and keep < 0.62:
			continue
		if rd < 30.0 and keep < 0.5:
			continue
		var y := _h(x, z)
		# Woods and meadows: a slow noise field decides which is which, so the
		# land alternates between forest belts and open flowery clearings
		# instead of one uniform carpet of trees.
		var forest := _forest(x, z)
		if keep > forest:
			if kind < 0.35 and d > 8.0:
				# meadow: a little clump of wildflowers instead of a tree
				var col: Color = petal_palette[int(kind * 100.0) % petal_palette.size()]
				for f in 5:
					var fx := x + rng.randf_range(-2.5, 2.5)
					var fz := z + rng.randf_range(-2.5, 2.5)
					flowers.append(_xf(Vector3(fx, _h(fx, fz) + 0.18, fz), 0.0, Vector3.ONE * rng.randf_range(0.8, 1.3)))
					flower_cols.append(col)
			continue

		if kind < 0.46:
			var s := rng.randf_range(0.85, 1.5)
			var yaw := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.5 * s, z), yaw, Vector3(s, s, s)))
			pines.append(_xf(Vector3(x, y + 5.4 * s, z), yaw, Vector3(s, s, s)))
			pine_cols.append(C_LEAF_A.lerp(C_LEAF_C, rng.randf()))
			collide_body.add_child(_tree_shape(Vector3(x, y + 3.0, z), 0.55 * s, 6.0 * s))
		elif kind < 0.80:
			var s2 := rng.randf_range(0.9, 1.7)
			var yaw2 := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.6 * s2, z), yaw2, Vector3(s2, s2, s2)))
			blobs.append(_xf(Vector3(x, y + 4.2 * s2, z), yaw2, Vector3(s2, s2 * 0.85, s2)))
			blob_cols.append(C_LEAF_B.lerp(C_LEAF_A, rng.randf()))
			collide_body.add_child(_tree_shape(Vector3(x, y + 3.0, z), 0.6 * s2, 6.0 * s2))
		elif kind < 0.90:
			var s3 := rng.randf_range(0.5, 2.4)
			var ryaw := rng.randf_range(0, TAU)
			var rys := rng.randf_range(0.5, 0.9)
			var rzs := rng.randf_range(0.8, 1.2)
			rocks.append(_xf(Vector3(x, y + s3 * 0.25, z), ryaw, Vector3(s3, s3 * rys, s3 * rzs)))
			rock_cols.append(C_ROCK.lightened(rng.randf_range(-0.12, 0.12)))
			# A sphere rather than a box: the capsule can ride up over the low
			# ones instead of catching on a vertical edge.
			if s3 > 0.8:
				var rs := CollisionShape3D.new()
				var sph := SphereShape3D.new()
				sph.radius = s3 * 0.72
				rs.shape = sph
				# top of the sphere matches the top of the (squashed) rock
				rs.position = Vector3(x, y + s3 * 0.25 + s3 * rys - sph.radius, z)
				collide_body.add_child(rs)
		else:
			var s4 := rng.randf_range(0.7, 1.6)
			bushes.append(_xf(Vector3(x, y + 0.35 * s4, z), rng.randf_range(0, TAU),
				Vector3(s4, s4 * 0.8, s4)))
			bush_cols.append(C_LEAF_C.lerp(C_LEAF_B, rng.randf()))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.2
	trunk_mesh.radial_segments = 7
	trunk_mesh.rings = 1

	var pine_mesh := CylinderMesh.new()
	pine_mesh.top_radius = 0.0
	pine_mesh.bottom_radius = 2.6
	pine_mesh.height = 7.4
	pine_mesh.radial_segments = 8
	pine_mesh.rings = 1

	var blob_mesh := SphereMesh.new()
	blob_mesh.radius = 2.7
	blob_mesh.height = 5.0
	blob_mesh.radial_segments = 9
	blob_mesh.rings = 5

	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 2.0
	rock_mesh.radial_segments = 6
	rock_mesh.rings = 3

	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 1.1
	bush_mesh.height = 2.0
	bush_mesh.radial_segments = 7
	bush_mesh.rings = 4

	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.16
	flower_mesh.height = 0.2
	flower_mesh.radial_segments = 6
	flower_mesh.rings = 2

	var reed_mesh := CylinderMesh.new()
	reed_mesh.top_radius = 0.02
	reed_mesh.bottom_radius = 0.35
	reed_mesh.height = 1.0
	reed_mesh.radial_segments = 5
	reed_mesh.rings = 1

	world.add_child(_multi("Trunks", trunk_mesh, ToonMat.make(C_TRUNK, 0.02), trunks, []))
	world.add_child(_multi("Pines", pine_mesh, ToonMat.make(Color.WHITE, 0.035), pines, pine_cols))
	world.add_child(_multi("Canopies", blob_mesh, ToonMat.make(Color.WHITE, 0.035), blobs, blob_cols))
	world.add_child(_multi("Rocks", rock_mesh, ToonMat.make(Color.WHITE, 0.02), rocks, rock_cols))
	world.add_child(_multi("Bushes", bush_mesh, ToonMat.make(Color.WHITE, 0.02), bushes, bush_cols))
	world.add_child(_multi("Reeds", reed_mesh, ToonMat.make(Color(0.46, 0.58, 0.28), 0.0), reeds, []))
	var fl := _multi("Wildflowers", flower_mesh, ToonMat.make(Color.WHITE, 0.0), flowers, flower_cols)
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(fl)
	world.add_child(collide_body)


## 0..1 chance a scatter spot is woodland rather than meadow. Hills and the
## land around them are wooded; the valley floor opens into meadows.
func _forest(x: float, z: float) -> float:
	var n := sin(x * 0.0061 + 0.8) * cos(z * 0.0053 - 1.3) + 0.55 * sin((x - z) * 0.0097 + 2.1)
	return clampf(0.5 + n * 0.7, 0.05, 0.98)


func _tree_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = pos
	return cs


func _cyl_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	return _tree_shape(pos, radius, height)


func _box_shape(size: Vector3, xf: Transform3D) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf
	return cs


func _multi(nm: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if colors.size() > 0:
			mm.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.name = nm
	node.multimesh = mm
	var m := mat
	if colors.size() > 0 and m is StandardMaterial3D:
		var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
		sm.vertex_color_use_as_albedo = true
		m = sm
	node.material_override = m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node


# --- backdrop ------------------------------------------------------------------

func _backdrop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED + 7
	var root := Node3D.new()
	root.name = "Backdrop"
	var far := ToonMat.make(Color(0.46, 0.55, 0.60), 0.0, 1.0)
	var far2 := ToonMat.make(Color(0.55, 0.63, 0.68), 0.0, 1.0)
	var snow := ToonMat.make(Color(0.90, 0.92, 0.95), 0.0, 1.0)
	for i in 64:
		var a := TAU * float(i) / 64.0 + rng.randf_range(-0.04, 0.04)
		var dist := rng.randf_range(980.0, 1350.0)
		var hgt := rng.randf_range(140.0, 330.0)
		var rad := hgt * rng.randf_range(0.7, 1.1)
		var pos := Vector3(cos(a) * dist, hgt * 0.35 - 30.0, sin(a) * dist)
		var mi := Build.cone(rad, hgt, far2 if i % 3 == 0 else far, pos, Vector3.ZERO, 9, "Peak%d" % i)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		if hgt > 250.0:
			# snow cap: the top quarter of the same cone
			var cap := Build.cone(rad * 0.25, hgt * 0.25, snow, pos + Vector3(0, hgt * 0.375 + 0.5, 0), Vector3.ZERO, 9, "Snow%d" % i)
			cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(cap)
	world.add_child(root)


# --- landmarks -----------------------------------------------------------------

func _landmarks() -> void:
	_homestead()
	_windmill(WINDMILL)
	_junction_signpost()
	_mirror_lake_dock()
	_billboard()
	_barn(BARN)
	_lookout(LOOKOUT)
	_wreck()
	_gas_station(GAS_STATION)
	_water_facility(FACILITY)
	_radio_mast(RADIO_MAST)
	_broken_bridge()
	_five_roses(ROSE_CENTRE)
	_info_board("home_lane", 22, 9.0, "HOMESTEAD\nRoad to Bessi: take the lane north\nto the windmill, then choose\nVALLEY RD or RIDGE TRACK")
	_info_board("pump_house_road", 12, -9.0, "LAST FUEL - J2\nPump House Rd north to the\nwater works and the old bridge.\nBESSI is across the river.")
	_info_board("pump_house_road", 150, -10.0, "BESSI WATER CO.\nPump station & cooling works\nAuthorised visitors only")


func _homestead() -> void:
	var lane := network.road("home_lane")
	var origin := HOMESTEAD
	origin.y = _h(origin.x, origin.z)
	var to_lane := lane.point(6) - origin
	to_lane.y = 0.0

	var root := Node3D.new()
	root.name = "Homestead"
	root.position = origin
	root.basis = Basis.looking_at(-to_lane, Vector3.UP)   # front door faces the lane

	var wall := ToonMat.make(Color(0.93, 0.88, 0.74))
	var roof := ToonMat.make(Color(0.78, 0.34, 0.26))
	var trim := ToonMat.make(Color(0.36, 0.52, 0.68))

	root.add_child(Build.solid_box(Vector3(11, 5, 8), wall, Vector3(0, 2.5, 0), Vector3.ZERO, "House"))
	root.add_child(Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, -1.55), Vector3(-34, 0, 0), "Roof1"))
	root.add_child(Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, 1.55), Vector3(34, 0, 0), "Roof2"))
	root.add_child(Build.box(Vector3(1.2, 2.6, 0.2), trim, Vector3(-2.5, 1.3, 4.05), Vector3.ZERO, "Door"))
	root.add_child(Build.box(Vector3(1.8, 1.4, 0.2), trim, Vector3(2.0, 3.0, 4.05), Vector3.ZERO, "Window"))
	root.add_child(Build.solid_cyl(0.5, 3.0, ToonMat.make(Color(0.6, 0.35, 0.3)), Vector3(3.6, 6.4, -1.0), Vector3.ZERO, "Chimney"))
	# porch
	root.add_child(Build.solid_box(Vector3(5.0, 0.25, 2.2), ToonMat.make(C_WOOD), Vector3(-1.5, 0.12, 5.2), Vector3.ZERO, "Porch"))
	for px in [-3.8, 0.8]:
		root.add_child(Build.cyl(0.1, 2.6, ToonMat.make(C_WOOD), Vector3(px, 1.3, 6.1), Vector3.ZERO, 6, "PorchPost"))
	root.add_child(Build.box(Vector3(5.4, 0.2, 2.6), roof, Vector3(-1.5, 2.7, 5.2), Vector3(8, 0, 0), "PorchRoof"))

	root.add_child(Build.solid_box(Vector3(7, 3.4, 6), ToonMat.make(Color(0.72, 0.70, 0.66)), Vector3(-10, 1.7, 1.0), Vector3.ZERO, "Garage"))
	root.add_child(Build.box(Vector3(7.6, 0.4, 6.6), roof, Vector3(-10, 3.6, 1.0), Vector3(-6, 0, 0), "GarageRoof"))
	# washing line and a vegetable patch make it look lived in
	for lx in [6.5, 12.5]:
		root.add_child(Build.cyl(0.06, 2.2, ToonMat.make(C_WOOD), Vector3(lx, 1.1, -2.0), Vector3.ZERO, 6, "LinePost"))
	root.add_child(Build.box(Vector3(6.0, 0.02, 0.02), ToonMat.make(Color(0.9, 0.9, 0.9)), Vector3(9.5, 2.1, -2.0), Vector3.ZERO, "Line"))
	var cloth := [Color(0.85, 0.35, 0.35), Color(0.95, 0.85, 0.40), Color(0.45, 0.65, 0.90)]
	for ci in 3:
		root.add_child(Build.box(Vector3(0.9, 0.9, 0.03), ToonMat.make(cloth[ci], 0.008), Vector3(7.8 + ci * 1.6, 1.6, -2.0), Vector3.ZERO, "Laundry"))
	root.add_child(Build.box(Vector3(5.0, 0.18, 3.0), ToonMat.make(Color(0.40, 0.30, 0.22)), Vector3(9.0, 0.09, 4.0), Vector3.ZERO, "VegPatch"))

	# the parents' letter, weighed down on a crate by the porch steps
	var crate_pos := Vector3(1.6, 0, 6.8)
	root.add_child(Build.solid_box(Vector3(0.7, 0.6, 0.6), ToonMat.make(C_WOOD), crate_pos + Vector3(0, 0.3, 0), Vector3.ZERO, "LetterCrate"))
	root.add_child(Build.box(Vector3(0.30, 0.01, 0.40), ToonMat.make(Color(0.97, 0.96, 0.90), 0.004), crate_pos + Vector3(0, 0.61, 0), Vector3(0, 12, 0), "Letter"))
	root.add_child(Build.box(Vector3(0.10, 0.08, 0.10), ToonMat.make(C_STONE), crate_pos + Vector3(0.08, 0.66, 0.1), Vector3.ZERO, "Paperweight"))
	var letter_area := Build.interact_area(Vector3(1.0, 1.0, 1.0), crate_pos + Vector3(0, 0.7, 0), "Read the letter", func(p):
		var st := p.get_tree().get_first_node_in_group("story") as Story
		if st != null:
			st.read_letter(p), "LetterArea")
	root.add_child(letter_area)

	var mb := Node3D.new()
	mb.name = "Mailbox"
	mb.position = Vector3(1.0, 0, 14.0)
	mb.add_child(Build.cyl(0.09, 1.3, ToonMat.make(C_WOOD), Vector3(0, 0.65, 0), Vector3.ZERO, 8, "Post"))
	mb.add_child(Build.box(Vector3(0.4, 0.35, 0.6), ToonMat.make(Color(0.85, 0.75, 0.30)), Vector3(0, 1.45, 0), Vector3.ZERO, "Box"))
	root.add_child(mb)
	world.add_child(root)
	poi["homestead"] = origin
	poi["letter"] = root.transform * (crate_pos + Vector3(0, 0.62, 0))


## Tall farm windmill at the route choice: the junction you describe to each
## other ("left at the windmill").
func _windmill(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "Windmill"
	root.position = pos
	var steel := ToonMat.make(C_STEEL, 0.012)
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var leg := Build.cyl(0.12, 14.0, steel, Vector3(cos(a) * 1.6, 6.9, sin(a) * 1.6), Vector3.ZERO, 6, "Leg")
		leg.rotation_degrees = Vector3(sin(a) * 6.5, 0, -cos(a) * 6.5)
		root.add_child(leg)
	for hy in [3.0, 7.0, 11.0]:
		var w: float = 3.2 - hy * 0.2
		root.add_child(Build.box(Vector3(w, 0.08, 0.08), steel, Vector3(0, hy, w * 0.5), Vector3.ZERO, "Brace"))
		root.add_child(Build.box(Vector3(w, 0.08, 0.08), steel, Vector3(0, hy, -w * 0.5), Vector3.ZERO, "Brace"))
	root.add_child(Build.box(Vector3(0.6, 0.6, 1.2), ToonMat.make(Color(0.72, 0.28, 0.24)), Vector3(0, 14.2, 0), Vector3.ZERO, "Head"))
	root.add_child(Build.box(Vector3(0.08, 1.4, 2.4), ToonMat.make(Color(0.72, 0.28, 0.24)), Vector3(0, 14.2, 2.0), Vector3.ZERO, "Vane"))
	var rotor := Spinner.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 14.2, -0.8)
	rotor.axis = Vector3.FORWARD
	rotor.speed = 1.4
	root.add_child(rotor)
	var blade := ToonMat.make(Color(0.92, 0.92, 0.88), 0.012)
	for b in 12:
		var holder := Node3D.new()
		holder.rotation = Vector3(0, 0, TAU * b / 12.0)
		holder.add_child(Build.box(Vector3(0.35, 2.2, 0.04), blade, Vector3(0, 1.5, 0), Vector3(0, 18, 0), "Blade"))
		rotor.add_child(holder)
	root.add_child(Build.solid_cyl(1.6, 1.2, ToonMat.make(C_STONE), Vector3(3.0, 0.6, 0.0), Vector3.ZERO, "Trough"))
	var body := StaticBody3D.new()
	body.add_child(_cyl_shape(Vector3(0, 7, 0), 1.8, 14.0))
	root.add_child(body)
	world.add_child(root)
	poi["windmill"] = pos


func _junction_signpost() -> void:
	var pos := Vector3(J1.x - 8.0, 0, J1.y + 9.0)
	pos.y = _h(pos.x, pos.z)
	var n := Node3D.new()
	n.name = "JunctionSign"
	n.position = pos
	n.add_child(Build.cyl(0.1, 3.4, ToonMat.make(C_WOOD), Vector3(0, 1.7, 0), Vector3.ZERO, 8, "Post"))
	var valley_dir := network.road("valley_road").forward(8)
	var ridge_dir := network.road("ridge_track").forward(8)
	_arrow_board(n, "VALLEY RD  >\nscenic, easy going", valley_dir, 2.9, Color(0.93, 0.90, 0.80))
	_arrow_board(n, "RIDGE TRACK  >\nshorter, steep gravel", ridge_dir, 2.3, Color(0.86, 0.72, 0.52))
	world.add_child(n)


func _arrow_board(parent: Node3D, text: String, dir: Vector3, y: float, col: Color) -> void:
	var holder := Node3D.new()
	var d := Vector3(dir.x, 0, dir.z).normalized()
	holder.basis = Basis.looking_at(Vector3(-d.z, 0, d.x), Vector3.UP)   # board runs along the road
	holder.position = Vector3(0, y, 0)
	holder.add_child(Build.box(Vector3(2.2, 0.55, 0.08), ToonMat.make(col, 0.01), Vector3(1.1, 0, 0), Vector3.ZERO, "Board"))
	holder.add_child(Build.label3d(text, Vector3(1.1, 0, 0.05), Vector3.ZERO, 0.16, Color(0.20, 0.22, 0.28)))
	var back := Build.label3d(text, Vector3(1.1, 0, -0.05), Vector3(0, 180, 0), 0.16, Color(0.20, 0.22, 0.28))
	holder.add_child(back)
	parent.add_child(holder)


func _mirror_lake_dock() -> void:
	var lake: Dictionary = PONDS[0]
	var c: Vector3 = lake["pos"]
	var shore_dir := Vector3(0.35, 0, -1).normalized()        # north shore, toward the road
	var water_r := Landscape.pond_water_radius(float(lake["radius"]))
	var start := c + shore_dir * (water_r + 3.0)
	start.y = _h(start.x, start.z)
	var water_y := Landscape.base_height(c.x, c.z) + float(lake["depth"]) * 0.4
	var root := Node3D.new()
	root.name = "Dock"
	root.position = Vector3(start.x, maxf(start.y, water_y) + 0.35, start.z)
	root.basis = Basis.looking_at(-shore_dir, Vector3.UP)
	var wood := ToonMat.make(C_WOOD, 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	var deck_len := 16.0
	root.add_child(Build.box(Vector3(2.4, 0.18, deck_len), wood, Vector3(0, 0, -deck_len * 0.5), Vector3.ZERO, "Deck"))
	body.add_child(_box_shape(Vector3(2.4, 0.18, deck_len), Transform3D(Basis(), Vector3(0, 0, -deck_len * 0.5))))
	for k in 5:
		for sx in [-1.1, 1.1]:
			root.add_child(Build.cyl(0.12, 3.0, wood, Vector3(sx, -1.4, -2.0 - k * 3.4), Vector3.ZERO, 6, "Pile"))
	# a rowboat tied at the end
	var boat := Node3D.new()
	boat.position = Vector3(2.4, water_y - root.position.y + 0.15, -deck_len + 2.0)
	boat.add_child(Build.box(Vector3(1.3, 0.45, 3.4), ToonMat.make(Color(0.30, 0.52, 0.66)), Vector3.ZERO, Vector3.ZERO, "Hull"))
	boat.add_child(Build.box(Vector3(1.1, 0.06, 0.3), wood, Vector3(0, 0.2, 0.3), Vector3.ZERO, "Seat"))
	root.add_child(boat)
	world.add_child(root)
	poi["dock"] = root.position


## Faded roadside billboard for the attraction: the first time the players
## see what Bessi was supposed to be.
func _billboard() -> void:
	var road := network.road("valley_road")
	var i := 250
	var p := road.point(i) - road.right(i) * 12.0
	p.y = _h(p.x, p.z)
	var root := Node3D.new()
	root.name = "Billboard"
	root.position = p
	# Basis.looking_at points -Z at the target; the lettering is on +Z, so aim
	# -Z away from the road to turn the face toward approaching drivers.
	root.basis = Basis.looking_at(-(road.right(i) - road.forward(i) * 0.6), Vector3.UP)
	var wood := ToonMat.make(C_WOOD)
	for sx in [-3.5, 3.5]:
		root.add_child(Build.cyl(0.18, 6.0, wood, Vector3(sx, 3.0, 0), Vector3.ZERO, 8, "Leg"))
	root.add_child(Build.box(Vector3(10.0, 4.4, 0.25), ToonMat.make(Color(0.96, 0.80, 0.82)), Vector3(0, 6.6, 0), Vector3.ZERO, "Panel"))
	root.add_child(Build.label3d("BESSI & THE 5 ROSES", Vector3(0, 7.7, 0.16), Vector3.ZERO, 0.85, Color(0.72, 0.12, 0.26)))
	root.add_child(Build.label3d("the wonder of the valley  -  1 km", Vector3(0, 6.6, 0.16), Vector3.ZERO, 0.45, Color(0.35, 0.22, 0.30)))
	root.add_child(Build.label3d("BRING A FRIEND!", Vector3(0, 5.5, 0.16), Vector3.ZERO, 0.55, Color(0.20, 0.45, 0.35)))
	for k in 5:
		root.add_child(Build.sphere(0.45, ToonMat.make(C_ROSE, 0.01), Vector3(-4.0 + k * 2.0, 8.55, 0.2), Vector3(1, 1, 0.4), "PaintedRose"))
	world.add_child(root)
	poi["billboard"] = p


func _barn(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "Barn"
	root.position = pos
	root.rotation_degrees = Vector3(0, 28, 0)

	var red := ToonMat.make(Color(0.70, 0.24, 0.20))
	var white := ToonMat.make(Color(0.92, 0.90, 0.84))
	root.add_child(Build.solid_box(Vector3(16, 7, 11), red, Vector3(0, 3.5, 0), Vector3.ZERO, "BarnBody"))
	root.add_child(Build.box(Vector3(17.6, 0.6, 7.4), ToonMat.make(Color(0.42, 0.30, 0.26)), Vector3(0, 8.6, -2.1), Vector3(-38, 0, 0), "RoofA"))
	root.add_child(Build.box(Vector3(17.6, 0.6, 7.4), ToonMat.make(Color(0.42, 0.30, 0.26)), Vector3(0, 8.6, 2.1), Vector3(38, 0, 0), "RoofB"))
	root.add_child(Build.box(Vector3(4.4, 5.0, 0.2), white, Vector3(0, 2.5, 5.55), Vector3.ZERO, "Doors"))
	root.add_child(Build.solid_cyl(2.6, 13.0, ToonMat.make(Color(0.80, 0.78, 0.72)), Vector3(11.0, 6.5, -2.0), Vector3.ZERO, "Silo"))
	root.add_child(Build.dome(2.7, ToonMat.make(Color(0.60, 0.62, 0.64)), Vector3(11.0, 13.0, -2.0), Vector3.ONE, "SiloCap"))
	# hay bales out front
	for hb in 4:
		root.add_child(Build.solid_cyl(0.8, 1.2, ToonMat.make(Color(0.86, 0.74, 0.40)), Vector3(-5.0 + hb * 1.9, 0.8, 9.0), Vector3(0, 0, 90), "Hay"))
	world.add_child(root)
	poi["barn"] = pos


## Timber lookout tower on the crest of Pine Ridge: a deck 6 m up, reached by
## a walkable ramp, high enough to see over the trees to the river and the
## roses. The deck faces Bessi (-Z).
func _lookout(at: Vector3) -> void:
	const DECK_H := 6.0
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "Lookout"
	root.position = pos
	var to_bessi := ROSE_CENTRE - pos
	to_bessi.y = 0.0
	root.basis = Basis.looking_at(to_bessi, Vector3.UP)
	var wood := ToonMat.make(C_WOOD, 0.012)
	var dark := ToonMat.make(Color(0.40, 0.28, 0.18), 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	# legs and cross braces
	for lx in [-2.8, 2.8]:
		for lz in [-2.3, 2.3]:
			root.add_child(Build.cyl(0.16, DECK_H + 0.4, dark, Vector3(lx, (DECK_H + 0.4) * 0.5 - 0.4, lz), Vector3.ZERO, 6, "Leg"))
			body.add_child(_cyl_shape(Vector3(lx, DECK_H * 0.5, lz), 0.16, DECK_H))
	for bz in [-2.3, 2.3]:
		root.add_child(Build.box(Vector3(5.6, 0.1, 0.1), dark, Vector3(0, DECK_H * 0.45, bz), Vector3(0, 0, 38), "Brace"))
	# deck
	root.add_child(Build.box(Vector3(6.4, 0.25, 5.2), wood, Vector3(0, DECK_H, 0), Vector3.ZERO, "Deck"))
	body.add_child(_box_shape(Vector3(6.4, 0.25, 5.2), Transform3D(Basis(), Vector3(0, DECK_H, 0))))
	# Ramp from the back of the deck down to the real ground at its foot, at a
	# walkable ~28 degrees. The crest falls away behind the tower, so the run is
	# solved against the actual ground height there, not the tower's base.
	var slope := tan(deg_to_rad(28.0))
	var run := DECK_H / slope
	var foot_rel := 0.0
	for _k in 4:
		var fw := root.transform * Vector3(0, 0, 2.6 + run)
		foot_rel = _h(fw.x, fw.z) - pos.y
		run = (DECK_H - foot_rel) / slope
	var rise := DECK_H - foot_rel
	var ramp_len := sqrt(run * run + rise * rise) + 1.0
	var ang := atan2(rise, run)
	var ramp_xf := Transform3D(Basis(Vector3.RIGHT, ang), Vector3(0, (DECK_H + foot_rel) * 0.5 - 0.12, 2.6 + run * 0.5))
	var ramp := Build.box(Vector3(1.8, 0.2, ramp_len), wood)
	ramp.transform = ramp_xf
	root.add_child(ramp)
	body.add_child(_box_shape(Vector3(1.8, 0.2, ramp_len), ramp_xf))
	for sx in [-0.95, 0.95]:
		var rail_xf := Transform3D(Basis(Vector3.RIGHT, ang), Vector3(sx, (DECK_H + foot_rel) * 0.5 + 0.85, 2.6 + run * 0.5))
		var rail := Build.box(Vector3(0.08, 0.08, ramp_len), wood)
		rail.transform = rail_xf
		root.add_child(rail)
		body.add_child(_box_shape(Vector3(0.1, 1.0, ramp_len), rail_xf.translated_local(Vector3(0, -0.4, 0))))
	# open railing on the three outward sides of the deck
	var rail_y := DECK_H + 1.0
	root.add_child(Build.box(Vector3(6.4, 0.08, 0.08), wood, Vector3(0, rail_y, -2.6), Vector3.ZERO, "RailFront"))
	body.add_child(_box_shape(Vector3(6.4, 1.0, 0.1), Transform3D(Basis(), Vector3(0, DECK_H + 0.6, -2.6))))
	for sx in [-3.2, 3.2]:
		root.add_child(Build.box(Vector3(0.08, 0.08, 5.2), wood, Vector3(sx, rail_y, 0), Vector3.ZERO, "RailSide"))
		body.add_child(_box_shape(Vector3(0.1, 1.0, 5.2), Transform3D(Basis(), Vector3(sx, DECK_H + 0.6, 0))))
	for px in [-3.2, -1.1, 1.1, 3.2]:
		root.add_child(Build.box(Vector3(0.08, 1.0, 0.08), wood, Vector3(px, DECK_H + 0.55, -2.6), Vector3.ZERO, "RailPost"))
	root.add_child(Build.box(Vector3(2.2, 0.12, 0.5), wood, Vector3(-1.6, DECK_H + 0.5, 1.6), Vector3.ZERO, "Bench"))
	root.add_child(Build.cyl(0.08, 1.2, ToonMat.make(C_STEEL), Vector3(1.8, DECK_H + 0.7, -1.9), Vector3.ZERO, 6, "ScopePost"))
	root.add_child(Build.cyl(0.14, 0.55, ToonMat.make(Color(0.30, 0.50, 0.40)), Vector3(1.8, DECK_H + 1.35, -2.05), Vector3(-80, 0, 0), 8, "Scope"))
	# pitched roof
	for rs in [-1.0, 1.0]:
		root.add_child(Build.box(Vector3(3.6, 0.15, 5.8), ToonMat.make(Color(0.36, 0.44, 0.30)), Vector3(rs * 1.6, DECK_H + 3.2, 0), Vector3(0, 0, -rs * 22), "Roof"))
	for lx in [-2.8, 2.8]:
		for lz in [-2.3, 2.3]:
			root.add_child(Build.cyl(0.08, 2.6, dark, Vector3(lx, DECK_H + 1.4, lz), Vector3.ZERO, 6, "RoofPost"))
	var sign_n := Node3D.new()
	sign_n.position = Vector3(2.2, foot_rel, 2.6 + run + 1.0)
	sign_n.add_child(Build.cyl(0.08, 2.0, wood, Vector3(0, 1.0, 0), Vector3.ZERO, 6, "Post"))
	sign_n.add_child(Build.box(Vector3(1.8, 0.6, 0.08), ToonMat.make(Color(0.34, 0.46, 0.30)), Vector3(0, 1.9, 0), Vector3.ZERO, "Board"))
	sign_n.add_child(Build.label3d("PINE RIDGE\nLOOKOUT", Vector3(0, 1.9, 0.05), Vector3.ZERO, 0.2, Color(0.95, 0.92, 0.80)))
	root.add_child(sign_n)
	world.add_child(root)
	poi["lookout"] = pos
	poi["lookout_deck"] = root.transform * Vector3(0, DECK_H + 0.2, -0.5)
	poi["lookout_ramp_foot"] = root.transform * Vector3(0, 0, 2.6 + run + 1.5)


## A rusted car on its roof beside the ridge track: the track is not kind.
func _wreck() -> void:
	var road := network.road("ridge_track")
	var i := 250
	var p := road.point(i) + road.right(i) * 9.0
	p.y = _h(p.x, p.z)
	var root := Node3D.new()
	root.name = "Wreck"
	root.position = p
	root.basis = Basis(Vector3.UP, 0.7) * Basis(Vector3.FORWARD, PI * 0.92)
	var rust := ToonMat.make(C_RUST)
	root.add_child(Build.box(Vector3(1.8, 0.8, 4.2), rust, Vector3(0, -0.5, 0), Vector3.ZERO, "Body"))
	root.add_child(Build.box(Vector3(1.6, 0.6, 2.2), ToonMat.make(Color(0.45, 0.28, 0.20)), Vector3(0, -1.15, -0.2), Vector3.ZERO, "Cab"))
	for wx in [-0.95, 0.95]:
		for wz in [-1.4, 1.4]:
			root.add_child(Build.cyl(0.36, 0.25, ToonMat.make(Color(0.14, 0.14, 0.15)), Vector3(wx, 0.05, wz), Vector3(0, 0, 90), 10, "Wheel"))
	var body := StaticBody3D.new()
	body.add_child(_box_shape(Vector3(1.8, 1.4, 4.2), Transform3D(Basis(), Vector3(0, -0.8, 0))))
	root.add_child(body)
	world.add_child(root)
	poi["wreck"] = p


## Abandoned fuel station where the two routes rejoin.
func _gas_station(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "LastFuel"
	root.position = pos
	var road := network.road("pump_house_road")
	var f := road.forward(6)
	root.basis = Basis.looking_at(Vector3(f.z, 0, -f.x), Vector3.UP)   # forecourt faces the road
	var white := ToonMat.make(Color(0.90, 0.88, 0.82))
	var red := ToonMat.make(Color(0.78, 0.22, 0.20))
	var body := StaticBody3D.new()
	root.add_child(body)
	root.add_child(Build.box(Vector3(14.0, 0.15, 10.0), ToonMat.make(Color(0.42, 0.42, 0.44)), Vector3(0, 0.08, 0), Vector3.ZERO, "Forecourt"))
	root.add_child(Build.box(Vector3(12.0, 0.5, 7.0), white, Vector3(0, 4.6, 0), Vector3.ZERO, "Canopy"))
	root.add_child(Build.box(Vector3(12.2, 0.3, 7.2), red, Vector3(0, 4.25, 0), Vector3.ZERO, "CanopyStripe"))
	for cx in [-5.0, 5.0]:
		root.add_child(Build.cyl(0.2, 4.4, white, Vector3(cx, 2.2, 0), Vector3.ZERO, 8, "Column"))
		body.add_child(_cyl_shape(Vector3(cx, 2.2, 0), 0.2, 4.4))
	for px in [-1.8, 1.8]:
		root.add_child(Build.box(Vector3(0.8, 1.6, 0.5), red, Vector3(px, 0.95, 0), Vector3.ZERO, "Pump"))
		root.add_child(Build.box(Vector3(0.6, 0.35, 0.02), ToonMat.flat(Color(0.12, 0.14, 0.14)), Vector3(px, 1.35, 0.26), Vector3.ZERO, "PumpDisplay"))
		body.add_child(_box_shape(Vector3(0.8, 1.6, 0.5), Transform3D(Basis(), Vector3(px, 0.95, 0))))
	root.add_child(Build.solid_box(Vector3(6.0, 3.2, 4.5), white, Vector3(0, 1.6, -8.0), Vector3.ZERO, "Kiosk"))
	root.add_child(Build.box(Vector3(2.4, 1.2, 0.05), ToonMat.make(Color(0.32, 0.46, 0.56)), Vector3(-1.2, 1.7, -5.73), Vector3.ZERO, "KioskWindow"))
	var sign_n := Node3D.new()
	sign_n.position = Vector3(7.5, 0, 5.0)
	sign_n.add_child(Build.cyl(0.14, 7.0, ToonMat.make(C_STEEL), Vector3(0, 3.5, 0), Vector3.ZERO, 8, "Pole"))
	sign_n.add_child(Build.box(Vector3(3.2, 1.6, 0.25), red, Vector3(0, 7.2, 0), Vector3.ZERO, "Sign"))
	sign_n.add_child(Build.label3d("LAST FUEL", Vector3(0, 7.35, 0.14), Vector3.ZERO, 0.5, Color(0.98, 0.95, 0.85)))
	sign_n.add_child(Build.label3d("CLOSED", Vector3(0, 6.75, 0.14), Vector3.ZERO, 0.3, Color(0.98, 0.95, 0.85)))
	root.add_child(sign_n)
	world.add_child(root)
	poi["gas_station"] = pos


## The Bessi water works: pump house, tanks and pipes down to the river. The
## cooling-station puzzle (A5) is built into this site.
func _water_facility(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "WaterFacility"
	root.position = pos
	var to_river := Vector3(430 - at.x, 0, 0)
	root.basis = Basis.looking_at(to_river, Vector3.UP)     # -Z points at the river
	var brick := ToonMat.make(Color(0.66, 0.40, 0.32))
	var concrete := ToonMat.make(Color(0.70, 0.70, 0.68))
	var pipe := ToonMat.make(Color(0.36, 0.52, 0.60), 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	root.add_child(Build.box(Vector3(24.0, 0.2, 20.0), concrete, Vector3(0, 0.1, 0), Vector3.ZERO, "Yard"))
	root.add_child(Build.solid_box(Vector3(9.0, 5.0, 7.0), brick, Vector3(-5.0, 2.5, 4.0), Vector3.ZERO, "PumpHouse"))
	root.add_child(Build.box(Vector3(9.8, 0.4, 7.8), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(-5.0, 5.2, 4.0), Vector3.ZERO, "PumpHouseRoof"))
	root.add_child(Build.box(Vector3(2.2, 3.0, 0.15), ToonMat.make(Color(0.30, 0.44, 0.40)), Vector3(-5.0, 1.5, 0.45), Vector3.ZERO, "PumpHouseDoor"))
	for t in 2:
		var tp := Vector3(5.0 + t * 5.5, 0, 5.0)
		root.add_child(Build.solid_cyl(2.2, 5.5, concrete, tp + Vector3(0, 2.75, 0), Vector3.ZERO, "Tank%d" % t))
		root.add_child(Build.dome(2.25, ToonMat.make(Color(0.56, 0.58, 0.60)), tp + Vector3(0, 5.5, 0), Vector3.ONE, "TankCap"))
	# intake pipes running from the pump house to the river
	for k in 2:
		var px := -6.0 + k * 2.0
		root.add_child(Build.cyl(0.35, 28.0, pipe, Vector3(px, 0.6, -14.0), Vector3(90, 0, 0), 10, "Intake"))
		body.add_child(_box_shape(Vector3(0.7, 0.7, 28.0), Transform3D(Basis(), Vector3(px, 0.6, -14.0))))
	root.add_child(Build.cyl(0.3, 11.0, pipe, Vector3(1.0, 3.0, 5.0), Vector3(0, 0, 90), 10, "TankFeed"))
	# the water tower from the prototype now belongs here
	var tower := Node3D.new()
	tower.position = Vector3(-12.0, 0, -6.0)
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var leg := Build.cyl(0.22, 15.0, ToonMat.make(C_STEEL), Vector3(cos(a) * 3.4, 7.0, sin(a) * 3.4), Vector3.ZERO, 8, "Leg%d" % k)
		leg.rotation_degrees = Vector3(sin(a) * 6.0, 0, -cos(a) * 6.0)
		tower.add_child(leg)
	tower.add_child(Build.cyl(4.6, 6.0, ToonMat.make(Color(0.86, 0.84, 0.78)), Vector3(0, 17.5, 0), Vector3.ZERO, 18, "Tank"))
	tower.add_child(Build.cone(4.9, 2.4, ToonMat.make(Color(0.72, 0.36, 0.30)), Vector3(0, 21.7, 0), Vector3.ZERO, 18, "TankRoof"))
	for side in [1.0, -1.0]:
		tower.add_child(Build.label3d("BESSI WATER CO.", Vector3(0, 17.8, 4.75 * side), Vector3(0, 0 if side > 0 else 180, 0), 0.9, Color(0.25, 0.30, 0.38)))
	body.add_child(_cyl_shape(Vector3(-12.0, 7.0, -6.0), 3.6, 14.0))
	root.add_child(tower)
	# the cooling-station puzzle lives in this yard
	var station := CoolingStation.new()
	station.name = "CoolingStation"
	root.add_child(station)

	# a low tool shed, clear of the intake pipes; something glints on its
	# roof (optional: stack crates)
	# roof top at 1.31 m: one crate (0.45) is not enough to jump up, two stacked (0.9) are
	root.add_child(Build.solid_box(Vector3(3.0, 1.25, 2.4), ToonMat.make(Color(0.52, 0.46, 0.38)), Vector3(-1.8, 0.625, -7.5), Vector3.ZERO, "ToolShed"))
	root.add_child(Build.box(Vector3(3.3, 0.12, 2.7), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(-1.8, 1.25, -7.5), Vector3.ZERO, "ShedRoof"))

	# visitor log by the pump house door
	root.add_child(Build.box(Vector3(0.45, 0.6, 0.12), ToonMat.make(Color(0.40, 0.30, 0.20)), Vector3(-7.8, 1.4, 0.4), Vector3.ZERO, "LogBox"))
	var log_area := Build.interact_area(Vector3(0.9, 1.0, 0.9), Vector3(-7.8, 1.4, 0.0), "Read the visitor log", func(p):
		p.say("VISITOR LOG - Bessi Water Co.\n\nThe last entry, nine days ago, in Naresh's handwriting:\n\"Naresh K.  -  passing through to Bessi  -  party of 2\"\n\nThe \"2\" has been scratched out and written over as a \"1\". Then scratched out again, and a \"2\" pressed so hard the pen went through the page.", 12.0), "LogArea")
	root.add_child(log_area)

	# a campsite down toward the river: one sleeping bag, two mugs
	var camp := Node3D.new()
	camp.name = "Campsite"
	camp.position = Vector3(3.0, 0, -18.0)
	root.add_child(camp)
	camp.add_child(Build.box(Vector3(0.8, 0.18, 2.0), ToonMat.make(Color(0.25, 0.45, 0.30)), Vector3(0, 0.09, 0), Vector3.ZERO, "SleepingBag"))
	for k in 5:
		var a := TAU * k / 5.0
		camp.add_child(Build.sphere(0.18, ToonMat.make(C_ROCK), Vector3(1.6 + cos(a) * 0.45, 0.08, sin(a) * 0.45), Vector3(1, 0.6, 1), "FireStone"))
	camp.add_child(Build.box(Vector3(0.5, 0.06, 0.5), ToonMat.make(Color(0.15, 0.13, 0.12)), Vector3(1.6, 0.03, 0), Vector3.ZERO, "Ashes"))
	for mx in [0.9, 1.1]:
		camp.add_child(Build.cyl(0.05, 0.1, ToonMat.make(Color(0.85, 0.3, 0.3) if mx < 1.0 else Color(0.3, 0.5, 0.85)), Vector3(mx, 0.05, 0.9), Vector3.ZERO, 8, "Mug"))
	var camp_area := Build.interact_area(Vector3(3.5, 1.2, 3.0), Vector3(0.8, 0.6, 0.3), "Look around the campsite", func(p):
		p.say("A cold fire ring. One sleeping bag, rolled out neatly - only one.\nTwo mugs, both used, set side by side as if for a conversation.\nScratched into a stone: N + ", 10.0), "CampArea")
	camp.add_child(camp_area)

	# chain-link fence on the road side, with a gate gap
	for fx in range(-11, 12, 2):
		if absf(fx) < 3:
			continue
		root.add_child(Build.cyl(0.05, 2.0, ToonMat.make(C_STEEL), Vector3(fx, 1.0, 10.0), Vector3.ZERO, 5, "FencePost"))
	world.add_child(root)
	poi["facility"] = pos
	poi["pump_handle"] = root.transform * (CoolingStation.PUMP_POS + Vector3(0, 0.9, 0))
	poi["valve_a"] = root.transform * (CoolingStation.A_POS + Vector3(0, 1.0, 0))
	poi["valve_b"] = root.transform * (CoolingStation.B_POS + Vector3(0, 1.0, 0))
	poi["shed_roof"] = root.transform * Vector3(-1.8, 1.31, -7.5)
	poi["radiator_yard"] = root.transform * Vector3(0, 0, -6.0)


func _radio_mast(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "RadioMast"
	root.position = pos
	var steel := ToonMat.make(Color(0.80, 0.30, 0.26), 0.012)
	var white := ToonMat.make(Color(0.92, 0.92, 0.90), 0.012)
	var h := 42.0
	for seg in 7:
		root.add_child(Build.cyl(0.6 - seg * 0.06, h / 7.0, steel if seg % 2 == 0 else white, Vector3(0, h / 7.0 * (seg + 0.5), 0), Vector3.ZERO, 6, "Seg"))
	root.add_child(Build.solid_box(Vector3(4.0, 2.8, 3.0), ToonMat.make(Color(0.70, 0.70, 0.66)), Vector3(4.0, 1.4, 0), Vector3.ZERO, "Hut"))
	var beacon := Spinner.new()
	beacon.name = "Beacon"
	beacon.blink_period = 1.6
	beacon.position = Vector3(0, h + 0.4, 0)
	beacon.add_child(Build.sphere(0.5, ToonMat.make(Color(1.0, 0.2, 0.15), 0.0, 0.5, Color(1.0, 0.15, 0.1)), Vector3.ZERO, Vector3.ONE, "Light"))
	root.add_child(beacon)
	var body := StaticBody3D.new()
	body.add_child(_cyl_shape(Vector3(0, h * 0.5, 0), 0.6, h))
	root.add_child(body)
	world.add_child(root)
	poi["radio_mast"] = pos


## Where Pump House Road crosses the river: an old timber bridge with its middle
## span gone. Decks either side are solid; the gap is not. Barriers and signs
## stop the van before it gets there (milestone B turns this into a puzzle).
func _broken_bridge() -> void:
	var road := network.road("pump_house_road")
	var root := Node3D.new()
	root.name = "BrokenBridge"
	world.add_child(root)
	var body := StaticBody3D.new()
	body.name = "BridgeDeck"
	root.add_child(body)
	var wood := ToonMat.make(Color(0.50, 0.36, 0.24), 0.012)
	var span_idx: Array[int] = []
	for i in road.point_count():
		var p := road.point(i)
		if Landscape.river_distance(p.x, p.z) < Landscape.RIVER_HALF + 7.0:
			span_idx.append(i)
	if span_idx.is_empty():
		push_warning("Pump House Road never crosses the river")
		return
	var first := span_idx[0]
	var last := span_idx[span_idx.size() - 1]
	var mid := (first + last) / 2
	for i in range(first - 1, last + 1):
		if absi(i - mid) <= 2:
			continue               # the missing middle span
		var a := road.point(i)
		var b := road.point(i + 1)
		var c := (a + b) * 0.5
		var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), c + Vector3.UP * 0.02)
		var plank := Build.box(Vector3(Landscape.ROAD_HALF * 2.0 + 0.6, 0.3, a.distance_to(b) + 0.05), wood)
		plank.transform = xf
		root.add_child(plank)
		body.add_child(_box_shape(Vector3(Landscape.ROAD_HALF * 2.0 + 0.6, 0.3, a.distance_to(b) + 0.05), xf))
		if i % 2 == 0:
			for s in [-1.0, 1.0]:
				var post := Build.cyl(0.12, 1.2, wood, c + road.right(i) * s * (Landscape.ROAD_HALF + 0.2) + Vector3.UP * 0.6, Vector3.ZERO, 6, "RailPost")
				root.add_child(post)
	# piers under the ends of the gap, snapped timbers hanging into the water
	for gi in [mid - 3, mid + 3]:
		var gp := road.point(gi)
		root.add_child(Build.cyl(0.5, 7.0, wood, gp + Vector3.DOWN * 3.5, Vector3.ZERO, 8, "Pier"))
		var hang := Build.box(Vector3(Landscape.ROAD_HALF * 1.6, 0.25, 3.0), wood, gp + Vector3.DOWN * 1.2, Vector3.ZERO, "Snapped")
		hang.basis = Basis.looking_at(road.forward(gi), Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(40 if gi < mid else -40))
		root.add_child(hang)
	# barrier and warning signs on both approaches
	for end in [[first - 14, 1.0], [last + 14, -1.0]]:
		var bi: int = end[0]
		var bp := road.point(bi)
		var fwd := road.forward(bi) * float(end[1])
		var bx := Transform3D(Basis.looking_at(fwd, Vector3.UP), bp + Vector3.UP * 0.5)
		var bar := Build.box(Vector3(Landscape.ROAD_HALF * 2.0, 0.25, 0.2), ToonMat.make(Color(0.95, 0.55, 0.15)), Vector3.ZERO, Vector3.ZERO, "Barrier")
		bar.transform = bx.translated_local(Vector3(0, 0.6, 0))
		root.add_child(bar)
		for s in [-1.0, 1.0]:
			root.add_child(Build.cyl(0.08, 1.2, ToonMat.make(C_STEEL), bp + road.right(bi) * s * 3.6 + Vector3.UP * 0.6, Vector3.ZERO, 6, "BarrierLeg"))
		body.add_child(_box_shape(Vector3(Landscape.ROAD_HALF * 2.0, 1.2, 0.3), bx.translated_local(Vector3(0, 0.1, 0))))
		var sign_n := Node3D.new()
		sign_n.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), bp + road.right(bi) * 5.5)
		sign_n.add_child(Build.cyl(0.07, 2.4, ToonMat.make(C_STEEL), Vector3(0, 1.2, 0), Vector3.ZERO, 6, "Post"))
		sign_n.add_child(Build.box(Vector3(1.8, 1.0, 0.06), ToonMat.make(Color(0.98, 0.82, 0.20)), Vector3(0, 2.3, 0), Vector3.ZERO, "Plate"))
		sign_n.add_child(Build.label3d("BRIDGE\nOUT", Vector3(0, 2.3, 0.05), Vector3.ZERO, 0.32, Color(0.15, 0.12, 0.10)))
		root.add_child(sign_n)
	poi["bridge"] = road.point(mid)
	poi["bridge_barrier_near"] = road.point(first - 14)


## The destination silhouette: five giant rose monuments on the central hill.
func _five_roses(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FiveRoses"
	world.add_child(root)

	var centre := at
	centre.y = Landscape.plateau_height(MOUNDS[0])

	# Stone plaza, flush with the plateau: its top is a low 8 cm lip the
	# player's capsule rolls straight over.
	const PLAZA_R := 30.0
	const PLAZA_TOP := 0.08
	var solid := StaticBody3D.new()
	solid.name = "RosesSolid"
	root.add_child(solid)
	root.add_child(Build.cyl(PLAZA_R, 0.6, ToonMat.make(C_STONE, 0.03), centre + Vector3(0, PLAZA_TOP - 0.3, 0), Vector3.ZERO, 40, "Plaza"))
	solid.add_child(_cyl_shape(centre + Vector3(0, PLAZA_TOP - 0.3, 0), PLAZA_R, 0.6))

	for k in 5:
		var a := TAU * float(k) / 5.0 - PI * 0.5
		var p := centre + Vector3(cos(a) * 22.0, PLAZA_TOP, sin(a) * 22.0)
		var sc := 2.4 + k * 0.10
		root.add_child(_rose_monument(p, sc, a))
		# plinth and stem are solid; the bloom overhead does not need to be
		solid.add_child(_cyl_shape(p + Vector3(0, 0.5 * sc, 0), 1.6 * sc, 1.0 * sc))
		solid.add_child(_cyl_shape(p + Vector3(0, 6.6 * sc, 0), 0.42 * sc, 12.0 * sc))

	# welcome sign on the side facing the road in from the bridge
	var join: Vector3 = poi["bessi_join"]
	var to_join := join - centre
	to_join.y = 0.0
	var sign_pos := centre + to_join.normalized() * 34.0
	sign_pos.y = _h(sign_pos.x, sign_pos.z)
	var s := Node3D.new()
	s.name = "WelcomeSign"
	s.position = sign_pos
	s.basis = Basis.looking_at(-to_join, Vector3.UP)
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(-2.4, 2.0, 0), Vector3.ZERO, 8, "PostL"))
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(2.4, 2.0, 0), Vector3.ZERO, 8, "PostR"))
	s.add_child(Build.box(Vector3(6.4, 2.2, 0.18), ToonMat.make(Color(0.93, 0.90, 0.80)), Vector3(0, 3.4, 0), Vector3.ZERO, "Board"))
	s.add_child(Build.label3d("BESSI\nand the 5 ROSES", Vector3(0, 3.5, 0.12), Vector3.ZERO, 0.52, Color(0.70, 0.16, 0.24)))
	root.add_child(s)
	poi["roses"] = centre


func _rose_monument(pos: Vector3, scale: float, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Rose"
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale

	var green := ToonMat.make(Color(0.28, 0.48, 0.26), 0.03)
	n.add_child(Build.cyl(1.6, 1.0, ToonMat.make(C_STONE, 0.03), Vector3(0, 0.5, 0), Vector3.ZERO, 14, "Base"))
	n.add_child(Build.cyl(0.42, 12.0, green, Vector3(0, 6.6, 0), Vector3.ZERO, 10, "Stem"))
	for s in [-1.0, 1.0]:
		var leaf := Build.sphere(1.0, green, Vector3(s * 1.5, 5.4, 0), Vector3(1.6, 0.25, 0.8), "Leaf")
		leaf.rotation_degrees = Vector3(0, 0, s * 22.0)
		n.add_child(leaf)
	var rings := [
		{"count": 8, "radius": 3.4, "y": 12.4, "len": 5.4, "tilt": 62.0, "col": C_ROSE_DEEP},
		{"count": 7, "radius": 2.4, "y": 13.4, "len": 4.4, "tilt": 42.0, "col": C_ROSE},
		{"count": 5, "radius": 1.3, "y": 14.2, "len": 3.2, "tilt": 22.0, "col": C_ROSE.lightened(0.14)},
	]
	for ring in rings:
		var mat := ToonMat.make(ring["col"], 0.035)
		for k in int(ring["count"]):
			var a := TAU * float(k) / float(ring["count"]) + float(ring["y"])
			var petal := Build.sphere(1.0, mat, Vector3.ZERO, Vector3(1.15, 0.42, 1.55), "Petal")
			var holder := Node3D.new()
			holder.position = Vector3(cos(a) * ring["radius"], ring["y"], sin(a) * ring["radius"])
			holder.rotation_degrees = Vector3(0, -rad_to_deg(a), 0)
			petal.rotation_degrees = Vector3(float(ring["tilt"]), 0, 0)
			petal.position = Vector3(0, 0, -float(ring["len"]) * 0.28)
			petal.scale = Vector3(1.0, 1.0, float(ring["len"]) / 3.0)
			holder.add_child(petal)
			n.add_child(holder)
	n.add_child(Build.sphere(1.15, ToonMat.make(Color(0.95, 0.78, 0.32), 0.03, 0.6, Color(0.35, 0.22, 0.05)), Vector3(0, 14.4, 0), Vector3.ONE, "Core"))
	return n


func _info_board(road_name: String, i: int, offset: float, text: String) -> void:
	var road := network.road(road_name)
	var p := road.point(i)
	var r := road.right(i)
	var pos := p + r * offset
	pos.y = _h(pos.x, pos.z)
	var n := Node3D.new()
	n.name = "InfoBoard"
	n.position = pos
	n.basis = Basis.looking_at(r * signf(offset), Vector3.UP)   # faces the road
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(-1.1, 1.2, 0), Vector3.ZERO, 8, "PostL"))
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(1.1, 1.2, 0), Vector3.ZERO, 8, "PostR"))
	n.add_child(Build.box(Vector3(3.0, 1.9, 0.12), ToonMat.make(Color(0.90, 0.87, 0.78)), Vector3(0, 2.3, 0), Vector3(-14, 0, 0), "Board"))
	n.add_child(Build.label3d(text, Vector3(0, 2.36, 0.08), Vector3(-14, 0, 0), 0.16, Color(0.22, 0.26, 0.32)))
	# Reading a board sketches the surrounding area onto the shared paper map.
	var board_xz := Vector2(pos.x, pos.z)
	var area := Build.interact_area(Vector3(3.2, 2.4, 1.2), Vector3(0, 2.2, 0.3), "Read the board", func(p):
		var ms := p.get_tree().get_first_node_in_group("map_state") as MapState
		if ms != null:
			ms.reveal_around(board_xz, MapState.BOARD_REVEAL_M)
		var title := text.get_slice("\n", 0)
		var body := text.substr(title.length() + 1).replace("\n", " ")
		p.say(title + "\n" + body + "\n\n(The area around this board is now sketched on your map - M.)", 7.0), "ReadBoard")
	n.add_child(area)
	world.add_child(n)
	poi["info_" + road_name + str(i)] = pos


func _signage() -> void:
	var picks := [
		{"road": "home_lane", "i": 40, "text": "BESSI\n2 km", "side": 1.0},
		{"road": "valley_road", "i": 60, "text": "MIRROR\nLAKE", "side": 1.0},
		{"road": "valley_road", "i": 330, "text": "SLOW\nCATTLE", "side": 1.0},
		{"road": "ridge_track", "i": 30, "text": "STEEP\nGRADE", "side": 1.0},
		{"road": "ridge_track", "i": 180, "text": "LOOKOUT", "side": -1.0},
		{"road": "pump_house_road", "i": 60, "text": "WATER\nWORKS", "side": 1.0},
		{"road": "bessi_loop", "i": 20, "text": "BEND\nAHEAD", "side": 1.0},
	]
	for s in picks:
		var road := network.road(s["road"])
		var i: int = mini(int(s["i"]), road.point_count() - 1)
		var p := road.point(i)
		var r := road.right(i)
		var side: float = s["side"]
		var pos := p + r * (6.4 * side)
		pos.y = _h(pos.x, pos.z)
		var n := Node3D.new()
		n.name = "Sign"
		n.position = pos
		n.basis = Basis.looking_at(road.forward(i), Vector3.UP)   # lettering (+Z) faces approaching drivers
		n.add_child(Build.cyl(0.08, 2.6, ToonMat.make(Color(0.60, 0.62, 0.64)), Vector3(0, 1.3, 0), Vector3.ZERO, 8, "Post"))
		n.add_child(Build.box(Vector3(1.7, 1.1, 0.1), ToonMat.make(Color(0.94, 0.92, 0.86)), Vector3(0, 2.5, 0), Vector3.ZERO, "Plate"))
		n.add_child(Build.label3d(str(s["text"]), Vector3(0, 2.5, 0.08), Vector3.ZERO, 0.30, Color(0.20, 0.24, 0.30)))
		world.add_child(n)


# --- items ---------------------------------------------------------------------

## Loose things to pick up. Fuel: one can by the homestead garage for the
## tutorial, and a stash behind the Last Fuel kiosk (the pumps are dead) -
## including one empty can, so players learn to check before lugging.
func _items() -> void:
	# Memory Fragments: one on each route (dock on the valley road, lookout
	# deck on the ridge) plus the shed roof at the water works - with the one
	# the cooling station gives, careful players reach a first Memory Rose.
	_place_fragment("dock", poi["dock"] + Vector3(0, 0.3, 0) + Basis.looking_at(-Vector3(0.35, 0, -1).normalized(), Vector3.UP) * Vector3(0, 0, -14.0))
	_place_fragment("lookout", poi["lookout_deck"] + Vector3(0, 0.25, 0))
	_place_fragment("shed", poi["shed_roof"] + Vector3(0, 0.25, 0), poi["shed_roof"].y - 0.5)
	# crates to stack for the shed roof
	var fac: Node3D = world.get_node("WaterFacility")
	for k in 4:
		var crate := Crate.new()
		crate.name = "Crate%d" % k
		world.add_child(crate)
		var at := fac.transform * Vector3(-1.0 + k * 1.3, 0, -1.9)
		crate.position = Vector3(at.x, _h(at.x, at.z) + 0.3, at.z)
		poi["crate%d" % k] = crate.position

	var home: Node3D = world.get_node("Homestead")
	_place_can(home.transform * Vector3(-6.2, 0, 4.6), FuelCan.CAPACITY, "home_can")
	var station: Node3D = world.get_node("LastFuel")
	_place_can(station.transform * Vector3(2.2, 0, -10.8), FuelCan.CAPACITY, "station_can_a")
	_place_can(station.transform * Vector3(2.8, 0, -10.6), FuelCan.CAPACITY, "station_can_b")
	_place_can(station.transform * Vector3(-3.4, 0, -10.9), 0.0, "station_can_empty")


func _place_fragment(id: String, at: Vector3, min_feet_y := -INF) -> void:
	var f := MemoryFragment.create(id)
	f.min_feet_y = min_feet_y
	world.add_child(f)
	f.position = at
	poi["fragment_" + id] = at


func _place_can(at: Vector3, fill: float, tag: String) -> void:
	var can := FuelCan.create(fill)
	can.name = "FuelCan_" + tag
	world.add_child(can)
	can.position = Vector3(at.x, _h(at.x, at.z) + 0.05, at.z)
	can.rotation.y = float(tag.length()) * 0.37
	poi[tag] = can.position


# --- helpers -------------------------------------------------------------------

func _h(x: float, z: float) -> float:
	return Landscape.ground(x, z)


func _in_pond(x: float, z: float, margin: float) -> bool:
	for p in PONDS:
		var c: Vector3 = p["pos"]
		if Vector2(x - c.x, z - c.z).length() < float(p["radius"]) + margin:
			return true
	return false


func _near_pond_shore(x: float, z: float) -> bool:
	for p in PONDS:
		var c: Vector3 = p["pos"]
		var wr := Landscape.pond_water_radius(float(p["radius"]))
		var d := Vector2(x - c.x, z - c.z).length()
		if d > wr - 2.0 and d < wr + 4.0:
			return true
	return false


## Keep landmark footprints clear of scattered trees.
func _in_clearing(x: float, z: float) -> bool:
	var clearings := [
		{"c": Vector2(ROSE_CENTRE.x, ROSE_CENTRE.z), "r": 60.0},
		{"c": Vector2(FACILITY.x, FACILITY.z), "r": 34.0},
		{"c": Vector2(GAS_STATION.x, GAS_STATION.z), "r": 26.0},
		{"c": Vector2(HOMESTEAD.x, HOMESTEAD.z), "r": 40.0},
		{"c": Vector2(WINDMILL.x, WINDMILL.z), "r": 40.0},
		{"c": Vector2(LOOKOUT.x, LOOKOUT.z), "r": 38.0},
		{"c": Vector2(RADIO_MAST.x, RADIO_MAST.z), "r": 20.0},
		{"c": Vector2(BARN.x, BARN.z), "r": 32.0},
	]
	for cl in clearings:
		if (Vector2(x, z) - Vector2(cl["c"])).length() < float(cl["r"]):
			return true
	return false


func _xf(pos: Vector3, yaw: float, scale: Vector3) -> Transform3D:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	return Transform3D(b, pos)
