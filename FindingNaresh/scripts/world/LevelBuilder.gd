class_name LevelBuilder
extends RefCounted

## Assembles the world: terrain, roads, water, scatter, landmarks, sky.
##
## A 4 x 4 km map (design/map_plan_v1.png, checked by tools/gen/layout_check.py,
## which holds a copy of this layout: keep the two in step). x east, z south.
##   Opening: P1's homestead (SW) -> Homestead Lane east through the town ->
##     P2's home -> north to Windmill Junction (J1).
##   The way out: J1 -> Valley Road (long: Mirror Lake, billboard, barn) or
##     Ridge Track (short, steep gravel: lookout, wreck) -> J2 Last Fuel ->
##     Pump House Road -> water works -> the bridge (the gate) -> J3 ->
##     Ghat Road hairpins up to the pass -> Beach Road past the coast
##     watchtower down to Bessi beach and the Five Roses (on the Bessi loop).
##   The way back: Coast Road north (fishing village, salt pans, estuary
##     bridge), west across the north through the old rail tunnel, past the
##     radio mast to Naresh's home.
##   The drive home: West Road south to the homestead; Tower Road branches
##     past the ending watchtower to P2's home.
##
## Placements live in the const tables below, so the layout is handcrafted
## data rather than procedural generation. Only the small scatter (trees,
## rocks, bushes) uses a fixed-seed RNG, so the world is identical on every
## run - remembering the route has to be rewarding.

# --- layout (x east, z south; metres) -------------------------------------------
const J1 := Vector2(-600, 950)          ## Windmill Junction: the route choice
const J2 := Vector2(100, 420)           ## Last Fuel: the two routes rejoin
const J3 := Vector2(560, -250)          ## east bank, foot of the Ghat
const GHAT_PASS := Vector2(1050, -80)   ## top of the hairpins
const NARESH_JN := Vector2(-1650, -900) ## Coast Road meets West Road at Naresh's home

const HOME_LANE := [Vector2(-1565, 1452), Vector2(-1500, 1540), Vector2(-1400, 1590), Vector2(-1250, 1585),
	Vector2(-1100, 1560), Vector2(-950, 1620), Vector2(-800, 1690), Vector2(-650, 1695), Vector2(-555, 1640),
	Vector2(-525, 1500), Vector2(-550, 1300), Vector2(-585, 1100), J1]
const VALLEY_ROAD := [J1, Vector2(-700, 925), Vector2(-850, 875), Vector2(-960, 780), Vector2(-1005, 640),
	Vector2(-985, 500), Vector2(-900, 385), Vector2(-760, 305), Vector2(-600, 262), Vector2(-430, 250),
	Vector2(-250, 285), Vector2(-80, 330), Vector2(40, 385), J2]
const RIDGE_TRACK := [J1, Vector2(-520, 830), Vector2(-430, 720), Vector2(-340, 610), Vector2(-220, 520),
	Vector2(-60, 465), J2]
## J2 north past the water works, over the river (the bridge) to J3.
const PUMP_HOUSE_ROAD := [J2, Vector2(210, 300), Vector2(290, 160), Vector2(338, 20), Vector2(360, -90),
	Vector2(362, -170), Vector2(372, -215), Vector2(410, -240), Vector2(460, -250), Vector2(515, -252), J3]
## Two hairpins up the saddle between the Ghat peaks.
const GHAT_ROAD := [J3, Vector2(650, -230), Vector2(730, -160), Vector2(790, -95), Vector2(850, -45),
	Vector2(900, -5), Vector2(955, 20), Vector2(985, 0), Vector2(965, -40), Vector2(930, -70), Vector2(935, -100),
	Vector2(985, -105), Vector2(1020, -90), GHAT_PASS]
## Down from the pass to the Bessi loop (the end is snapped onto the loop).
const BEACH_ROAD := [GHAT_PASS, Vector2(1150, -70), Vector2(1260, -60), Vector2(1380, -40), Vector2(1470, 40),
	Vector2(1530, 200), Vector2(1570, 380), Vector2(1610, 520)]
## North from the Bessi loop (start snapped onto it) along the coast, over the
## estuary, west through the rail tunnel to Naresh's home.
const COAST_ROAD := [Vector2(1735, 520), Vector2(1730, 300), Vector2(1720, 60), Vector2(1700, -250),
	Vector2(1660, -600), Vector2(1640, -900), Vector2(1610, -1150), Vector2(1570, -1350), Vector2(1550, -1600),
	Vector2(1450, -1720), Vector2(1250, -1760), Vector2(950, -1740), Vector2(650, -1680), Vector2(400, -1640),
	Vector2(180, -1560), Vector2(-150, -1490), Vector2(-400, -1470), Vector2(-650, -1560), Vector2(-900, -1400),
	Vector2(-1200, -1180), Vector2(-1450, -1020), NARESH_JN]
## Naresh's home south to the homestead (the end snaps onto Homestead Lane).
const WEST_ROAD := [NARESH_JN, Vector2(-1720, -700), Vector2(-1745, -420), Vector2(-1700, -150),
	Vector2(-1640, 150), Vector2(-1590, 480), Vector2(-1560, 800), Vector2(-1575, 1050), Vector2(-1610, 1250),
	Vector2(-1640, 1380)]
## From West Road past the ending watchtower to P2's home (both ends snapped).
const TOWER_ROAD := [Vector2(-1560, 800), Vector2(-1420, 870), Vector2(-1270, 980), Vector2(-1100, 1100),
	Vector2(-900, 1270), Vector2(-720, 1450), Vector2(-560, 1580)]

## Road profiles: smoothed over this many metres, then held to a grade limit.
const ROAD_SMOOTH_M := 150.0
const ROAD_GRADE := 0.10
const GRAVEL_SMOOTH_M := 80.0
const GRAVEL_GRADE := 0.15
const GHAT_GRADE := 0.09
## Ground this far above a road means it runs in a tunnel there.
const TUNNEL_COVER := 9.0

const ROSE_CENTRE := Vector3(1720, 0, 640)
const BESSI_CENTRE := Vector2(1720, 640)
const BESSI_SCALE := 0.85
static var BESSI_LOOP_SHAPE := PackedVector2Array([
	Vector2(0, -150), Vector2(85, -128), Vector2(140, -55), Vector2(150, 30), Vector2(112, 105),
	Vector2(35, 152), Vector2(-48, 148), Vector2(-120, 95), Vector2(-152, 15), Vector2(-130, -70),
	Vector2(-62, -140),
])

## The river rises in the south hills, runs north through the middle and
## turns east to the sea (the estuary).
const RIVER := [Vector2(600, 1130), Vector2(560, 900), Vector2(520, 650), Vector2(482, 380), Vector2(466, 150),
	Vector2(456, -100), Vector2(462, -400), Vector2(480, -900), Vector2(455, -1250), Vector2(560, -1420),
	Vector2(900, -1470), Vector2(1300, -1520), Vector2(1760, -1480), Vector2(1950, -1470)]

## The waterline, south-going; the sea lies east of it.
const COAST := [Vector2(1850, -2100), Vector2(1800, -1500), Vector2(1740, -1000), Vector2(1770, -500),
	Vector2(1840, 0), Vector2(1900, 400), Vector2(1930, 700), Vector2(1890, 1200), Vector2(1900, 2100)]

const PONDS := [
	{"pos": Vector3(-850, 0, 660), "radius": 110.0, "depth": 7.0},    # Mirror Lake
	{"pos": Vector3(-1600, 0, 1545), "radius": 20.0, "depth": 2.4},   # homestead duck pond
]

const TUNNEL_HILL := 3        ## index in MOUNDS: the Coast Road runs under it
const MOUNDS := [
	# the roses' dune by the beach: flat top for the plaza
	{"pos": ROSE_CENTRE, "radius": 90.0, "height": 6.0, "plateau": 30.0},
	# Pine Ridge: the ridge track climbs straight over it
	{"pos": Vector3(-330, 0, 640), "radius": 210.0, "height": 30.0},
	# Radio Hill: the mast on top is a landmark from the north of the map
	{"pos": Vector3(-600, 0, -1300), "radius": 240.0, "height": 55.0},
	# Tunnel Hill: the old rail tunnel runs under it
	{"pos": Vector3(0, 0, -1520), "radius": 240.0, "height": 48.0},
	# the Ghat: two peaks with the hairpin pass between, and an east shoulder
	{"pos": Vector3(990, 0, -320), "radius": 320.0, "height": 110.0},
	{"pos": Vector3(1180, 0, 190), "radius": 320.0, "height": 95.0},
	{"pos": Vector3(1380, 0, -60), "radius": 380.0, "height": 30.0},
	# the south hills (the river's source)
	{"pos": Vector3(600, 0, 1320), "radius": 280.0, "height": 45.0},
	# the ending watchtower's hill
	{"pos": Vector3(-1300, 0, 900), "radius": 300.0, "height": 30.0},
	# hills that fill the land out
	{"pos": Vector3(-1900, 0, 250), "radius": 260.0, "height": 50.0},
	{"pos": Vector3(-1050, 0, -350), "radius": 300.0, "height": 35.0},
	{"pos": Vector3(-250, 0, -650), "radius": 260.0, "height": 30.0},
	{"pos": Vector3(1250, 0, 1150), "radius": 260.0, "height": 35.0},
	{"pos": Vector3(750, 0, -1000), "radius": 220.0, "height": 28.0},
]

const HOMESTEAD := Vector3(-1600, 0, 1480)   ## P1's home
const P2_HOME := Vector3(-490, 0, 1590)
const TOWN_FUEL := Vector3(-1250, 0, 1625)
const WINDMILL := Vector3(-640, 0, 990)
const LOOKOUT := Vector3(-340, 0, 665)
const BARN := Vector3(-500, 0, 205)
const GAS_STATION := Vector3(130, 0, 470)   ## Last Fuel, at J2
const FACILITY := Vector3(405, 0, -150)     ## pump house yard, on the west bank
const COAST_TOWER := Vector3(1395, 0, -85)
const FISHING_VILLAGE := Vector3(1715, 0, -620)
const SALT_PANS := Vector3(1690, 0, -1120)
const RADIO_MAST := Vector3(-600, 0, -1300)
const NARESH_HOME := Vector3(-1605, 0, -950)
const END_TOWER := Vector3(-1300, 0, 900)

## Flat pads under buildings (centre, flat radius, blend distance).
const PADS := [
	{"pos": FACILITY, "radius": 22.0, "blend": 14.0},
	{"pos": GAS_STATION, "radius": 14.0, "blend": 10.0},
	{"pos": HOMESTEAD, "radius": 20.0, "blend": 12.0},
	{"pos": BARN, "radius": 14.0, "blend": 10.0},
	{"pos": P2_HOME, "radius": 16.0, "blend": 10.0},
	{"pos": TOWN_FUEL, "radius": 14.0, "blend": 10.0},
	{"pos": NARESH_HOME, "radius": 18.0, "blend": 10.0},
	{"pos": FISHING_VILLAGE, "radius": 30.0, "blend": 12.0},
	{"pos": SALT_PANS, "radius": 42.0, "blend": 12.0},
]

## Places kept clear of scattered trees (centre, radius).
const CLEARINGS := [
	[Vector2(1720, 640), 70.0], [Vector2(405, -150), 34.0], [Vector2(130, 470), 26.0],
	[Vector2(-1590, 1475), 75.0], [Vector2(-640, 990), 30.0], [Vector2(-340, 665), 30.0],
	[Vector2(-600, -1300), 24.0], [Vector2(-500, 205), 32.0], [Vector2(-490, 1590), 30.0],
	[Vector2(-1250, 1600), 150.0], [Vector2(1395, -85), 40.0], [Vector2(1715, -620), 60.0],
	[Vector2(1690, -1120), 60.0], [Vector2(-1605, -950), 36.0], [Vector2(-1300, 900), 36.0],
]

const DOCK_DIR := Vector3(-1, 0, 0.1)   ## Mirror Lake's dock runs out from this shore

const SCATTER_SEED := 20260810
## World size in metres (square). `-- --extent=<m>` overrides it for load tests.
const WORLD_EXTENT := 4000.0

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
## Scatter transforms by kind ("Rocks", "Trunks", ...), kept for tests and
## later systems: a headless run cannot read them back from the MultiMeshes.
var scatter: Dictionary = {}


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
	world.add_child(Landscape.build_sea())
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
	var wind := NoiseLoop.new()
	wind.name = "Wind"
	wind.kind = NoiseLoop.Kind.WIND
	wind.positional = false
	wind.volume_db = -20.0
	wind.target = 1.0
	world.add_child(wind)
	# forest bed, birds, and water you can hear from the bank
	var amb := Ambience.new()
	amb.name = "Ambience"
	world.add_child(amb)
	for k in range(0, RIVER.size(), 2):
		var rp: Vector2 = RIVER[k]
		amb.add_water(Vector3(rp.x, Landscape.ground(rp.x, rp.y) + 1.0, rp.y), world)
	# lapping all round Mirror Lake's shore (it is too big for one emitter)
	var lake: Vector3 = PONDS[0]["pos"]
	var shore_r := Landscape.pond_water_radius(float(PONDS[0]["radius"]))
	for k in 6:
		var a := TAU * k / 6.0
		var sp := lake + Vector3(cos(a), 0, sin(a)) * shore_r * 0.85
		amb.add_water(Vector3(sp.x, Landscape.ground(sp.x, sp.z) + 1.0, sp.z), world)
	_lap("landmarks", t)
	return world


func _lap(what: String, since: int) -> int:
	var now := Time.get_ticks_msec()
	print("[World] %s %d ms" % [what, now - since])
	return now


# --- roads and water -----------------------------------------------------------

func _build_roads() -> void:
	network = RoadNetwork.new()
	Landscape.height_fn = Callable()     # a gym may have set its own ground
	Landscape.EXTENT = WORLD_EXTENT
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--extent="):
			Landscape.EXTENT = a.get_slice("=", 1).to_float()
	Landscape.coast = PackedVector2Array(COAST)
	# Landscape needs ponds and mounds before any road can sample the ground.
	Landscape.setup(null, null, PONDS, MOUNDS)
	var base := Landscape.base_height

	var loop_pts := PackedVector2Array()
	for p in BESSI_LOOP_SHAPE:
		loop_pts.append(BESSI_CENTRE + p * BESSI_SCALE)
	route = network.add(Route.new(loop_pts, true, base, NAN, NAN, 0, 120.0), "bessi_loop")

	var j1h := _pin_height(J1)
	var j2h := _pin_height(J2)
	var j3h := _pin_height(J3)
	var pass_h := _pin_height(GHAT_PASS, 30.0)
	var nar_h := _pin_height(NARESH_JN)
	_road("home_lane", HOME_LANE, NAN, j1h)
	_road("valley_road", VALLEY_ROAD, j1h, j2h)
	_road("ridge_track", RIDGE_TRACK, j1h, j2h, "gravel")
	_road("pump_house_road", PUMP_HOUSE_ROAD, j2h, j3h)
	_road("ghat_road", GHAT_ROAD, j3h, pass_h, "asphalt", GHAT_GRADE)
	# Beach Road ends on the Bessi loop: snap its last point to the nearest
	# loop sample and pin the height there so the two meet flush.
	var beach := PackedVector2Array(BEACH_ROAD)
	var jp := _snap(route, beach[beach.size() - 1])
	beach.append(Vector2(jp.x, jp.z))
	_road("beach_road", beach, pass_h, jp.y)
	poi["bessi_join"] = jp

	# The Coast Road leaves the loop's north side and runs under Tunnel Hill
	# rather than over it: its profile ignores that hill.
	var coast_r := PackedVector2Array(COAST_ROAD)
	var cp := _snap(route, coast_r[0])
	coast_r.insert(0, Vector2(cp.x, cp.z))
	var th: Dictionary = MOUNDS[TUNNEL_HILL]
	var no_hill := func(x: float, z: float) -> float:
		return base.call(x, z) - _one_mound(th, x, z)
	var cr := network.add(Route.new(coast_r, false, no_hill, cp.y, nar_h, 0, ROAD_SMOOTH_M, ROAD_GRADE), "coast_road")
	cr.tunnel.resize(cr.point_count())
	for i in cr.point_count():
		var q := cr.point(i)
		cr.tunnel[i] = 1 if base.call(q.x, q.z) - q.y > TUNNEL_COVER else 0

	var west := PackedVector2Array(WEST_ROAD)
	var wp := _snap(network.road("home_lane"), west[west.size() - 1])
	west.append(Vector2(wp.x, wp.z))
	_road("west_road", west, nar_h, wp.y)
	var tower := PackedVector2Array(TOWER_ROAD)
	var tp0 := _snap(network.road("west_road"), tower[0])
	var tp1 := _snap(network.road("home_lane"), tower[tower.size() - 1])
	tower.insert(0, Vector2(tp0.x, tp0.z))
	tower.append(Vector2(tp1.x, tp1.z))
	_road("tower_road", tower, tp0.y, tp1.y)

	var rv := Route.new(PackedVector2Array(RIVER), false, base, NAN, NAN, 40)
	rv.make_monotonic_descending()
	river = rv
	Landscape.setup(network, river, PONDS, MOUNDS)
	Landscape.set_pads(PADS)

	poi["j1"] = Vector3(J1.x, j1h, J1.y)
	poi["j2"] = Vector3(J2.x, j2h, J2.y)
	poi["j3"] = Vector3(J3.x, j3h, J3.y)
	poi["ghat_pass"] = Vector3(GHAT_PASS.x, pass_h, GHAT_PASS.y)


func _road(nm: String, pts, pin_a: float, pin_b: float, surface := "asphalt", grade := 0.0) -> Route:
	var gravel := surface == "gravel"
	var r := Route.new(PackedVector2Array(pts), false, Landscape.base_height, pin_a, pin_b, 0,
		GRAVEL_SMOOTH_M if gravel else ROAD_SMOOTH_M, grade if grade > 0.0 else (GRAVEL_GRADE if gravel else ROAD_GRADE))
	return network.add(r, nm, surface)


## The road sample nearest a point (where a joining road meets it).
func _snap(r: Route, p: Vector2) -> Vector3:
	var near := r.nearest(p.x, p.y)
	if float(near["dist"]) < 1e8:
		return r.point(int(near["index"]))
	var best := r.point(0)
	for i in r.point_count():
		var q := r.point(i)
		if Vector2(q.x - p.x, q.z - p.y).length() < Vector2(best.x - p.x, best.z - p.y).length():
			best = q
	return best


## A junction's level: the mean ground over a disk, so no road has to climb to
## meet a bump the others smooth away.
func _pin_height(p: Vector2, r := 50.0) -> float:
	var tot := 0.0
	var cnt := 0
	for dx in range(-int(r), int(r) + 1, 10):
		for dz in range(-int(r), int(r) + 1, 10):
			if dx * dx + dz * dz <= r * r:
				tot += Landscape.base_height(p.x + dx, p.y + dz)
				cnt += 1
	return tot / cnt


func _one_mound(m: Dictionary, x: float, z: float) -> float:
	var c: Vector3 = m["pos"]
	var d := Vector2(x - c.x, z - c.z).length()
	return float(m["height"]) * (1.0 - smoothstep(0.0, float(m["radius"]), d)) if d < float(m["radius"]) else 0.0


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

	# colliders: one static body per scatter tile, so physics queries stay local
	var colliders := Node3D.new()
	colliders.name = "TreeColliders"
	var bodies := {}

	var half := Landscape.EXTENT * 0.5 - 15.0
	# the same density as the first 1.6 km valley, whatever the world size
	var attempts := int(24000.0 * pow(Landscape.EXTENT / 1600.0, 2.0))
	# Hot loop (150 000 tries at 4 km): the grid lookups are done by hand, once
	# per try for all three layers, and the coastline is only asked about near
	# the coast. Same tests, same order, same random numbers: the same forest.
	var gn := Landscape.grid_n
	var g0 := -Landscape.EXTENT * 0.5
	var g_road := Landscape.grid_road_d
	var g_river := Landscape.grid_river_d
	var g_h := Landscape.grid_h
	var coast_x0 := 1e9               # west of this, nowhere is near the beach
	for cp in Landscape.coast:
		coast_x0 = minf(coast_x0, cp.x)
	coast_x0 -= Landscape.BEACH_W + 10.0
	for _i in attempts:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var kind := rng.randf()
		var keep := rng.randf()
		# bilinear weights on the terrain grid (Landscape._grid_sample)
		var gfx := (x - g0) / Landscape.STEP
		var gfz := (z - g0) / Landscape.STEP
		var inside := gn > 0 and not (gfx < 0.0 or gfz < 0.0 or gfx > gn - 1 or gfz > gn - 1)
		var gk := 0
		var tx := 0.0
		var tz := 0.0
		var d: float
		if inside:
			var gix := mini(int(gfx), gn - 2)
			var giz := mini(int(gfz), gn - 2)
			tx = gfx - gix
			tz = gfz - giz
			gk = giz * gn + gix
			d = lerpf(lerpf(g_road[gk], g_road[gk + 1], tx), lerpf(g_road[gk + gn], g_road[gk + gn + 1], tx), tz)
		else:
			d = Landscape.road_distance(x, z)
		if d < 9.5:
			continue
		if x >= coast_x0 and Landscape.coast_inland(x, z) < Landscape.BEACH_W + 10.0:
			continue
		var rd: float
		if inside:
			rd = lerpf(lerpf(g_river[gk], g_river[gk + 1], tx), lerpf(g_river[gk + gn], g_river[gk + gn + 1], tx), tz)
		else:
			rd = Landscape.river_distance(x, z)
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

		var y := lerpf(lerpf(g_h[gk], g_h[gk + 1], tx), lerpf(g_h[gk + gn], g_h[gk + gn + 1], tx), tz) if inside else _h(x, z)
		if kind < 0.46:
			var s := rng.randf_range(0.85, 1.5)
			var yaw := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.5 * s, z), yaw, Vector3(s, s, s)))
			pines.append(_xf(Vector3(x, y + 5.4 * s, z), yaw, Vector3(s, s, s)))
			pine_cols.append(C_LEAF_A.lerp(C_LEAF_C, rng.randf()))
			_tile_shape(bodies, colliders, x, z, _cylinder(0.55 * s, 6.0 * s), Vector3(x, y + 3.0, z))
		elif kind < 0.80:
			var s2 := rng.randf_range(0.9, 1.7)
			var yaw2 := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.6 * s2, z), yaw2, Vector3(s2, s2, s2)))
			blobs.append(_xf(Vector3(x, y + 4.2 * s2, z), yaw2, Vector3(s2, s2 * 0.85, s2)))
			blob_cols.append(C_LEAF_B.lerp(C_LEAF_A, rng.randf()))
			_tile_shape(bodies, colliders, x, z, _cylinder(0.6 * s2, 6.0 * s2), Vector3(x, y + 3.0, z))
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
				var sph := SphereShape3D.new()
				sph.radius = s3 * 0.72
				# top of the sphere matches the top of the (squashed) rock
				_tile_shape(bodies, colliders, x, z, sph, Vector3(x, y + s3 * 0.25 + s3 * rys - sph.radius, z))
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

	# Each kind is split into SCATTER_TILE tiles that are culled on their own
	# and fade out with distance: a 4 km forest in one batch drew everything,
	# everywhere, every frame.
	world.add_child(_tiled("Trunks", trunk_mesh, ToonMat.make(C_TRUNK, 0.02), trunks, [], 1500.0))
	world.add_child(_tiled("Pines", pine_mesh, ToonMat.make(Color.WHITE, 0.035), pines, pine_cols, 1500.0))
	world.add_child(_tiled("Canopies", blob_mesh, ToonMat.make(Color.WHITE, 0.035), blobs, blob_cols, 1500.0))
	world.add_child(_tiled("Rocks", rock_mesh, ToonMat.make(Color.WHITE, 0.02), rocks, rock_cols, 900.0))
	world.add_child(_tiled("Bushes", bush_mesh, ToonMat.make(Color.WHITE, 0.02), bushes, bush_cols, 700.0))
	world.add_child(_tiled("Reeds", reed_mesh, ToonMat.make(Color(0.46, 0.58, 0.28), 0.0), reeds, [], 450.0))
	world.add_child(_tiled("Wildflowers", flower_mesh, ToonMat.make(Color.WHITE, 0.0), flowers, flower_cols, 350.0, false))
	world.add_child(colliders)


## A scatter collider: a shape straight on its tile's body, no node of its own
## (about 59 000 of them at 4 km; a CollisionShape3D each took ~0.7 s to make).
func _tile_shape(bodies: Dictionary, parent: Node3D, x: float, z: float, shape: Shape3D, at: Vector3) -> void:
	var sb := _tile_body(bodies, parent, x, z)
	var owner_id := sb.create_shape_owner(sb)
	sb.shape_owner_add_shape(owner_id, shape)
	sb.shape_owner_set_transform(owner_id, Transform3D(Basis(), at))


func _cylinder(radius: float, height: float) -> CylinderShape3D:
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	return sh


func _tile_body(bodies: Dictionary, parent: Node3D, x: float, z: float) -> StaticBody3D:
	var t := _tile(x, z)
	if not bodies.has(t):
		var sb := StaticBody3D.new()
		sb.name = "Tile%d" % t
		bodies[t] = sb
		parent.add_child(sb)
	return bodies[t]


const SCATTER_TILE := 500.0


func _tile(x: float, z: float) -> int:
	var n := int(ceil(Landscape.EXTENT / SCATTER_TILE))
	var h := Landscape.EXTENT * 0.5
	return clampi(int((z + h) / SCATTER_TILE), 0, n - 1) * n + clampi(int((x + h) / SCATTER_TILE), 0, n - 1)


## One MultiMesh per scatter tile under a group node, each culled by distance.
func _tiled(nm: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array, range_end: float, shadows := true) -> Node3D:
	scatter[nm] = xforms
	var group := Node3D.new()
	group.name = nm
	var by_tile := {}
	for i in xforms.size():
		var o: Vector3 = (xforms[i] as Transform3D).origin
		var t := _tile(o.x, o.z)
		if not by_tile.has(t):
			by_tile[t] = [[], []]
		by_tile[t][0].append(xforms[i])
		if colors.size() > 0:
			by_tile[t][1].append(colors[i])
	var keys := by_tile.keys()
	keys.sort()
	for t in keys:
		var mmi := _multi("%s%d" % [nm, t], mesh, mat, by_tile[t][0], by_tile[t][1])
		mmi.visibility_range_end = range_end
		mmi.visibility_range_end_margin = range_end * 0.1
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if not shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(mmi)
	return group


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
	# Hazy blue-green, between the valley's greens and the far blue peaks: a
	# saturated green read as odd blobs floating on the horizon.
	var ridge_mat := ToonMat.make(Color(0.39, 0.50, 0.49), 0.0, 1.0)
	var ridge_trees: Array[Transform3D] = []
	for i in 64:
		var a := TAU * float(i) / 64.0 + rng.randf_range(-0.04, 0.04)
		var hgt := rng.randf_range(140.0, 330.0)
		if cos(a) > 0.2 and Landscape.coast.size() > 0:
			continue               # the east is open sea to the horizon
		var rad := hgt * rng.randf_range(0.7, 1.1)
		var style := i % 4
		# forested ridges are long and low: stretched along the horizon
		var stretch := 1.9 if style == 3 else 1.0
		# Every mountain stands wholly outside the playable map (its base
		# starts beyond the terrain's corner), so none can sit on a road.
		var dist := Landscape.EXTENT * 0.72 + rad * stretch + rng.randf_range(20.0, 260.0)
		var pos := Vector3(cos(a) * dist, hgt * 0.35 - 30.0, sin(a) * dist)
		var mi: MeshInstance3D
		if style == 3:
			# a long, low wooded ridge with a ragged line of tree tops, so it reads
			# as distant forest rather than a smooth green blob
			var dm := SphereMesh.new()
			dm.radius = rad
			dm.height = rad * 2.0
			dm.is_hemisphere = true
			dm.radial_segments = 24
			dm.rings = 8
			var ys := hgt * 0.42 / rad
			var xf := Transform3D(Basis(Vector3.UP, -a - PI * 0.5) * Basis.from_scale(Vector3(stretch, ys, 1.0)), Vector3(pos.x, -30.0, pos.z))
			mi = Build.node(dm, ridge_mat, xf, "Hill%d" % i)
			for k in 34:
				var u := rng.randf_range(-0.92, 0.92)
				var v := rng.randf_range(-0.55, 0.55)
				var top := sqrt(maxf(0.0, 1.0 - u * u - v * v))
				if top < 0.15:
					continue
				var at := xf * Vector3(u * rad, top * rad, v * rad)
				var th := rng.randf_range(55.0, 90.0)
				var tr := th * rng.randf_range(0.24, 0.30)
				ridge_trees.append(Transform3D(Basis.from_scale(Vector3(tr, th, tr)), at + Vector3.UP * (th * 0.38)))
		else:
			mi = Build.cone(rad, hgt, far2 if style == 0 else far, pos, Vector3(0, rng.randf_range(0, 360), 0), 6 + style * 2, "Peak%d" % i)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		if style == 1 and hgt > 200.0:
			# a twin summit: a smaller cone leaning off the shoulder
			var twin := Build.cone(rad * 0.6, hgt * 0.7, far, pos + Vector3(rad * 0.45, -hgt * 0.1, rad * 0.2), Vector3.ZERO, 7, "Twin%d" % i)
			twin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(twin)
		if hgt > 250.0 and style != 3:
			# snow cap: the top quarter of the same cone
			var cap := Build.cone(rad * 0.25, hgt * 0.25, snow, pos + Vector3(0, hgt * 0.375 + 0.5, 0), Vector3.ZERO, 9, "Snow%d" % i)
			cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(cap)
	world.add_child(root)
	# the ridge tree tops: one multimesh, a single draw call
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	mm.instance_count = ridge_trees.size()
	for k in ridge_trees.size():
		mm.set_instance_transform(k, ridge_trees[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BackdropTrees"
	mmi.multimesh = mm
	mmi.material_override = ToonMat.make(Color(0.31, 0.43, 0.42), 0.0, 1.0)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)
	_world_edge()


## Invisible walls just inside the terrain's edge: the valley ends, you cannot
## walk or drive off the world into the backdrop.
func _world_edge() -> void:
	var body := StaticBody3D.new()
	body.name = "WorldEdge"
	var e := Landscape.EXTENT * 0.5 - 6.0
	for side in [[Vector3(e, 0, 0), Vector3(2, 400, e * 2)], [Vector3(-e, 0, 0), Vector3(2, 400, e * 2)],
			[Vector3(0, 0, e), Vector3(e * 2, 400, 2)], [Vector3(0, 0, -e), Vector3(e * 2, 400, 2)]]:
		body.add_child(_box_shape(side[1], Transform3D(Basis(), side[0])))
	# the sea: wade in knee-deep, no further
	for i in COAST.size() - 1:
		var a := Vector3(COAST[i].x + 18.0, 0, COAST[i].y)
		var b := Vector3(COAST[i + 1].x + 18.0, 0, COAST[i + 1].y)
		var mid := (a + b) * 0.5
		body.add_child(_box_shape(Vector3(2, 400, a.distance_to(b) + 4.0),
			Transform3D(Basis.looking_at(b - a, Vector3.UP), mid)))
	world.add_child(body)


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
	_p2_home()
	_town()
	_lookout(COAST_TOWER, 16.0, "CoastTower", "COAST\nWATCHTOWER", ROSE_CENTRE, "coast_tower")
	_lookout(END_TOWER, 22.0, "EndTower", "OLD\nWATCHTOWER", Vector3(400, 0, -300), "end_tower")
	_beach()
	_fishing_village()
	_salt_pans()
	_road_bridge("coast_road", "estuary_bridge")
	_tunnel("coast_road")
	_naresh_home()
	_info_board("home_lane", 22, 9.0, "HOMESTEAD\nRoad to Bessi: the lane runs east\nthrough town, then north to the\nwindmill: VALLEY RD or RIDGE TRACK")
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
	var shore_dir := DOCK_DIR.normalized()                    # west shore, toward the road
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
func _lookout(at: Vector3, DECK_H := 6.0, nm := "Lookout", label := "PINE RIDGE\nLOOKOUT", face := ROSE_CENTRE,
		key := "lookout") -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = nm
	root.position = pos
	var to_bessi := face - pos
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
	sign_n.add_child(Build.label3d(label, Vector3(0, 1.9, 0.05), Vector3.ZERO, 0.2, Color(0.95, 0.92, 0.80)))
	root.add_child(sign_n)
	# the legs of a tall tower need to reach the deck
	if DECK_H > 6.5:
		for lx in [-2.8, 2.8]:
			for lz in [-2.3, 2.3]:
				body.add_child(_cyl_shape(Vector3(lx, DECK_H * 0.5, lz), 0.2, DECK_H))
	world.add_child(root)
	poi[key] = pos
	poi[key + "_deck"] = root.transform * Vector3(0, DECK_H + 0.2, -0.5)
	poi[key + "_ramp_foot"] = root.transform * Vector3(0, 0, 2.6 + run + 1.5)


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
	var rp := _snap(river, Vector2(at.x, at.z))
	var to_river := Vector3(rp.x - at.x, 0, rp.z - at.z)
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
		{"road": "home_lane", "i": 40, "text": "BESSI\n6 km", "side": 1.0},
		{"road": "home_lane", "i": 330, "text": "TOWN\nFUEL", "side": 1.0},
		{"road": "ghat_road", "i": 40, "text": "HAIRPIN\nBENDS", "side": 1.0},
		{"road": "beach_road", "i": 60, "text": "BESSI\nBEACH", "side": 1.0},
		{"road": "coast_road", "i": 300, "text": "FISHING\nVILLAGE", "side": -1.0},
		{"road": "coast_road", "i": 1500, "text": "TUNNEL\nLIGHTS ON", "side": 1.0},
		{"road": "west_road", "i": 60, "text": "HOMESTEAD\n3 km", "side": 1.0},
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


# --- new places (greybox) --------------------------------------------------------

## A plain house block: walls, a pitched roof, a door facing `face`.
func _house(at: Vector3, face: Vector3, size: Vector3, wall_col: Color, roof_col: Color, nm: String) -> Node3D:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = nm
	root.position = pos
	var to := face - pos
	to.y = 0.0
	root.basis = Basis.looking_at(-to, Vector3.UP)      # front (+Z) faces `face`
	var roof := ToonMat.make(roof_col)
	root.add_child(Build.solid_box(size, ToonMat.make(wall_col), Vector3(0, size.y * 0.5, 0), Vector3.ZERO, "Walls"))
	var half := size.z * 0.5 + 0.4
	for sd in [-1.0, 1.0]:
		root.add_child(Build.box(Vector3(size.x + 1.2, 0.4, half / cos(deg_to_rad(32.0))), roof,
			Vector3(0, size.y + half * 0.31, sd * half * 0.5), Vector3(32.0 * sd, 0, 0), "Roof"))
	root.add_child(Build.box(Vector3(1.2, 2.4, 0.2), ToonMat.make(Color(0.36, 0.30, 0.26)), Vector3(0, 1.2, size.z * 0.5 + 0.05), Vector3.ZERO, "Door"))
	world.add_child(root)
	return root


func _p2_home() -> void:
	var lane := network.road("home_lane")
	var near := _snap(lane, Vector2(P2_HOME.x, P2_HOME.z))
	var h := _house(P2_HOME, near, Vector3(10, 6, 8), Color(0.80, 0.86, 0.92), Color(0.32, 0.36, 0.44), "P2Home")
	h.add_child(Build.solid_box(Vector3(5, 3, 6), ToonMat.make(Color(0.70, 0.66, 0.60)), Vector3(8.5, 1.5, 0), Vector3.ZERO, "Shed"))
	h.add_child(Build.box(Vector3(1.6, 1.2, 0.2), ToonMat.make(Color(0.36, 0.52, 0.68)), Vector3(-2.5, 4.2, 4.05), Vector3.ZERO, "UpstairsWindow"))
	poi["p2_home"] = h.position


## A few houses along the lane and the town fuel station.
func _town() -> void:
	var lane := network.road("home_lane")
	var cols := [Color(0.92, 0.86, 0.70), Color(0.86, 0.72, 0.62), Color(0.78, 0.84, 0.76), Color(0.90, 0.90, 0.86)]
	var k := 0
	for i in range(170, 470, 22):
		if absi(i - 330) < 20:
			continue           # the fuel station's frontage
		var side := 1.0 if k % 2 == 0 else -1.0
		var p := lane.point(i) + lane.right(i) * side * 20.0
		_house(p, lane.point(i), Vector3(8, 5, 7), cols[k % cols.size()], Color(0.62, 0.30, 0.24) if k % 3 else Color(0.34, 0.36, 0.40), "TownHouse%d" % k)
		k += 1
	var fuel := Node3D.new()
	fuel.name = "TownFuel"
	var pos := TOWN_FUEL
	pos.y = _h(pos.x, pos.z)
	fuel.position = pos
	var to_road := _snap(lane, Vector2(pos.x, pos.z)) - pos
	to_road.y = 0.0
	fuel.basis = Basis.looking_at(-to_road, Vector3.UP)
	var white := ToonMat.make(Color(0.94, 0.93, 0.88))
	var green := ToonMat.make(Color(0.20, 0.55, 0.35))
	var body := StaticBody3D.new()
	fuel.add_child(body)
	fuel.add_child(Build.box(Vector3(16, 0.15, 12), ToonMat.make(Color(0.40, 0.40, 0.42)), Vector3(0, 0.08, 0), Vector3.ZERO, "Forecourt"))
	fuel.add_child(Build.box(Vector3(12, 0.5, 7), white, Vector3(0, 4.6, 0), Vector3.ZERO, "Canopy"))
	fuel.add_child(Build.box(Vector3(12.2, 0.3, 7.2), green, Vector3(0, 4.25, 0), Vector3.ZERO, "Stripe"))
	for px in [-2.0, 2.0]:
		fuel.add_child(Build.box(Vector3(0.8, 1.6, 0.5), green, Vector3(px, 0.95, 0), Vector3.ZERO, "Pump"))
		body.add_child(_box_shape(Vector3(0.8, 1.6, 0.5), Transform3D(Basis(), Vector3(px, 0.95, 0))))
	for cx in [-5.0, 5.0]:
		fuel.add_child(Build.cyl(0.2, 4.4, white, Vector3(cx, 2.2, 0), Vector3.ZERO, 8, "Column"))
		body.add_child(_cyl_shape(Vector3(cx, 2.2, 0), 0.2, 4.4))
	fuel.add_child(Build.solid_box(Vector3(8, 3.4, 5), white, Vector3(0, 1.7, -9), Vector3.ZERO, "Shop"))
	fuel.add_child(Build.label3d("TOWN FUEL  -  OPEN", Vector3(0, 4.6, 3.55), Vector3.ZERO, 0.5, Color(0.15, 0.40, 0.25)))
	world.add_child(fuel)
	poi["town_fuel"] = pos


## Bessi beach (greybox): a promenade of stalls behind the sand, boats drawn
## up, a line of casuarinas and the memorial. Milestone E builds it properly.
func _beach() -> void:
	var root := Node3D.new()
	root.name = "BessiBeach"
	world.add_child(root)
	var stall_cols := [Color(0.90, 0.35, 0.30), Color(0.95, 0.80, 0.30), Color(0.35, 0.60, 0.85), Color(0.40, 0.75, 0.45)]
	var casu := ToonMat.make(Color(0.26, 0.40, 0.28), 0.03)
	var trunk := ToonMat.make(C_TRUNK)
	var k := 0
	for z in range(330, 960, 45):
		var shore := Landscape.coast_inland(0.0, float(z))       # the waterline's x here
		var inland := Vector3(-1, 0, 0)
		# stalls on the promenade edge, lamp posts between
		var sp := Vector3(shore - 58.0, 0, float(z))
		sp.y = _h(sp.x, sp.z)
		var stall := Build.solid_box(Vector3(3.0, 2.4, 2.4), ToonMat.make(stall_cols[k % stall_cols.size()]), sp + Vector3(0, 1.2, 0), Vector3.ZERO, "Stall%d" % k)
		root.add_child(stall)
		root.add_child(Build.box(Vector3(3.6, 0.15, 3.0), ToonMat.make(Color(0.95, 0.92, 0.84)), sp + Vector3(0.3, 2.55, 0), Vector3(0, 0, -8), "Awning"))
		var lp := sp + Vector3(0, 0, 22.0)
		root.add_child(Build.cyl(0.08, 4.5, ToonMat.make(C_STEEL), lp + Vector3(0, 2.25, 0), Vector3.ZERO, 6, "Lamp"))
		root.add_child(Build.sphere(0.3, ToonMat.make(Color(1.0, 0.92, 0.70), 0.0, 0.5, Color(1.0, 0.85, 0.5)), lp + Vector3(0, 4.6, 0), Vector3.ONE, "LampGlow"))
		# boats drawn up on the sand
		if k % 2 == 0:
			var bp := Vector3(shore - 14.0, 0, float(z) + 10.0)
			bp.y = _h(bp.x, bp.z)
			var boat := Build.box(Vector3(1.8, 0.8, 6.0), ToonMat.make(Color(0.25, 0.45, 0.70) if k % 4 == 0 else Color(0.85, 0.40, 0.25)), bp + Vector3(0, 0.4, 0), Vector3(0, 20.0 * (k % 3 - 1), 0), "Boat%d" % k)
			root.add_child(boat)
		# casuarinas behind the promenade
		for c in 2:
			var cp := Vector3(shore - 80.0 - c * 14.0, 0, float(z) + c * 20.0)
			cp.y = _h(cp.x, cp.z)
			root.add_child(Build.cyl(0.25, 5.0, trunk, cp + Vector3(0, 2.5, 0), Vector3.ZERO, 6, "CasuarinaTrunk"))
			root.add_child(Build.cone(1.6, 9.0, casu, cp + Vector3(0, 8.5, 0), Vector3.ZERO, 7, "Casuarina"))
		k += 1
	# the memorial: a plain stone column on a stepped base, facing the sea
	var shore0 := Landscape.coast_inland(0.0, 480.0)
	var mp := Vector3(shore0 - 45.0, 0, 480.0)
	mp.y = _h(mp.x, mp.z)
	root.add_child(Build.solid_box(Vector3(6, 0.6, 6), ToonMat.make(C_STONE), mp + Vector3(0, 0.3, 0), Vector3.ZERO, "MemorialBase"))
	root.add_child(Build.solid_box(Vector3(1.4, 8.0, 1.4), ToonMat.make(C_STONE.lightened(0.1)), mp + Vector3(0, 4.6, 0), Vector3.ZERO, "Memorial"))
	var bp0 := Vector3(Landscape.coast_inland(0.0, 600.0) - 30.0, 0, 600.0)
	bp0.y = _h(bp0.x, bp0.z)
	poi["beach"] = bp0
	poi["memorial"] = mp


func _fishing_village() -> void:
	var root := Node3D.new()
	root.name = "FishingVillage"
	world.add_child(root)
	var c := FISHING_VILLAGE
	var road := network.road("coast_road")
	var face := _snap(road, Vector2(c.x, c.z))
	var cols := [Color(0.62, 0.78, 0.86), Color(0.90, 0.84, 0.64), Color(0.86, 0.62, 0.56)]
	var offs := [Vector3(-14, 0, -20), Vector3(-14, 0, 2), Vector3(-12, 0, 24), Vector3(10, 0, -14)]
	for i in offs.size():
		_house(c + offs[i], face, Vector3(6, 3.4, 5), cols[i % cols.size()], Color(0.40, 0.36, 0.30), "Hut%d" % i)
	# the net shed (locked) and nets drying on poles
	var shed := _house(c + Vector3(12, 0, 12), c + Vector3(40, 0, 12), Vector3(8, 4, 6), Color(0.50, 0.42, 0.34), Color(0.30, 0.28, 0.26), "NetShed")
	shed.add_child(Build.label3d("NETS - PRIVATE", Vector3(0, 3.0, 3.1), Vector3.ZERO, 0.3, Color(0.95, 0.92, 0.85)))
	for k in 3:
		var np := c + Vector3(24, 0, -10 + k * 8)
		np.y = _h(np.x, np.z)
		root.add_child(Build.cyl(0.06, 2.4, ToonMat.make(C_WOOD), np + Vector3(0, 1.2, 0), Vector3.ZERO, 5, "NetPole"))
		root.add_child(Build.box(Vector3(0.04, 1.6, 6.0), ToonMat.make(Color(0.30, 0.45, 0.40)), np + Vector3(0, 1.4, 3.0), Vector3.ZERO, "Net"))
	var shore := Landscape.coast_inland(0.0, c.z)
	for k in 3:
		var bp := Vector3(shore - 10.0, 0, c.z - 20.0 + k * 16.0)
		bp.y = _h(bp.x, bp.z)
		root.add_child(Build.box(Vector3(1.8, 0.8, 6.5), ToonMat.make(Color(0.80, 0.30, 0.25) if k != 1 else Color(0.25, 0.45, 0.65)), bp + Vector3(0, 0.4, 0), Vector3(0, 10.0 * k, 0), "Boat"))
	poi["fishing_village"] = Vector3(c.x, _h(c.x, c.z), c.z)
	poi["net_shed"] = shed.position


## Salt pans: a grid of shallow white beds between low mud dikes.
func _salt_pans() -> void:
	var root := Node3D.new()
	root.name = "SaltPans"
	var c := SALT_PANS
	c.y = _h(c.x, c.z)
	root.position = c
	world.add_child(root)
	var salt := ToonMat.make(Color(0.93, 0.93, 0.90), 0.0)
	var brine := ToonMat.water(Color(0.62, 0.74, 0.80, 0.9))
	var dike := ToonMat.make(Landscape.MUD)
	for ix in 5:
		for iz in 5:
			var p := Vector3(-30 + ix * 15, 0.05, -30 + iz * 15)
			root.add_child(Build.box(Vector3(13, 0.06, 13), salt if (ix + iz) % 3 else brine, p, Vector3.ZERO, "Pan"))
	for k in 6:
		root.add_child(Build.box(Vector3(1.2, 0.7, 76), dike, Vector3(-37.5 + k * 15, 0.35, 0), Vector3.ZERO, "Dike"))
		root.add_child(Build.box(Vector3(76, 0.7, 1.2), dike, Vector3(0, 0.35, -37.5 + k * 15), Vector3.ZERO, "Dike"))
	# salt heaps and the watchman's hut
	for k in 3:
		root.add_child(Build.cone(2.5, 2.2, salt, Vector3(44, 1.1, -20 + k * 12), Vector3.ZERO, 8, "SaltHeap"))
	root.add_child(Build.solid_box(Vector3(3, 2.6, 3), ToonMat.make(Color(0.70, 0.64, 0.56)), Vector3(46, 1.3, 22), Vector3.ZERO, "Hut"))
	poi["salt_pans"] = c


## A whole road bridge where a road crosses the river (the estuary).
func _road_bridge(road_name: String, key: String) -> void:
	var road := network.road(road_name)
	var root := Node3D.new()
	root.name = "Bridge_" + key
	world.add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var deck_mat := ToonMat.make(Color(0.62, 0.62, 0.60), 0.012)
	var rail := ToonMat.make(C_STEEL)
	var span: Array[int] = []
	for i in road.point_count():
		if Landscape.over_river(road.point(i)):
			span.append(i)
	if span.is_empty():
		push_warning("%s never crosses the river" % road_name)
		return
	for i in range(span[0] - 1, span[span.size() - 1] + 1):
		var a := road.point(i)
		var b := road.point(i + 1)
		var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5 + Vector3.UP * 0.02)
		var sz := Vector3(Landscape.ROAD_HALF * 2.0 + 1.0, 0.4, a.distance_to(b) + 0.05)
		var slab := Build.box(sz, deck_mat)
		slab.transform = xf
		root.add_child(slab)
		body.add_child(_box_shape(sz, xf))
		for sd in [-1.0, 1.0]:
			var rx := xf.translated_local(Vector3(sd * (Landscape.ROAD_HALF + 0.35), 0.6, 0))
			var r := Build.box(Vector3(0.15, 0.9, sz.z), rail)
			r.transform = rx
			root.add_child(r)
			body.add_child(_box_shape(Vector3(0.2, 1.0, sz.z), rx))
	var mid := span[span.size() / 2]
	for gi in [span[0] + 2, mid, span[span.size() - 1] - 2]:
		root.add_child(Build.cyl(0.9, 9.0, deck_mat, road.point(gi) + Vector3.DOWN * 4.6, Vector3.ZERO, 10, "Pier"))
	poi[key] = road.point(mid)


## Where a road runs through a tunnel: walls and a roof over its slot in the
## hill, earth heaped over the roof up to the hillside, and portal faces.
func _tunnel(road_name: String) -> void:
	var road := network.road(road_name)
	if road.tunnel.is_empty():
		return
	var root := Node3D.new()
	root.name = "Tunnel_" + road_name
	world.add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var concrete := ToonMat.make(Color(0.50, 0.50, 0.48))
	var earth := ToonMat.make(Landscape.GRASS_DARK.lerp(Landscape.DRY, 0.3))
	var portal := ToonMat.make(Color(0.46, 0.40, 0.36))
	const IN_W := 5.4        # half-width inside
	const IN_H := 6.2        # clear height
	var runs: Array = []
	var start := -1
	for i in road.point_count() + 1:
		var t := i < road.point_count() and road.in_tunnel(i)
		if t and start < 0:
			start = i
		elif not t and start >= 0:
			runs.append([start, i - 1])
			start = -1
	for run in runs:
		var a0: int = run[0] - 3
		var a1: int = run[1] + 3
		var i := a0
		while i < a1:
			var j := mini(i + 4, a1)
			var a := road.point(i)
			var b := road.point(j)
			var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5)
			var seg_len := a.distance_to(b) + 0.3
			for sd in [-1.0, 1.0]:
				var wx := xf.translated_local(Vector3(sd * (IN_W + 0.3), IN_H * 0.5, 0))
				var w := Build.box(Vector3(0.6, IN_H, seg_len), concrete)
				w.transform = wx
				root.add_child(w)
				body.add_child(_box_shape(Vector3(0.6, IN_H, seg_len), wx))
			var rx := xf.translated_local(Vector3(0, IN_H + 0.3, 0))
			var roof := Build.box(Vector3(IN_W * 2.0 + 1.2, 0.6, seg_len), concrete)
			roof.transform = rx
			root.add_child(roof)
			body.add_child(_box_shape(Vector3(IN_W * 2.0 + 1.2, 0.6, seg_len), rx))
			# earth over the roof, up to the lower of the hillsides beside it
			var c := (a + b) * 0.5
			var r := road.right(i)
			var side_h := minf(Landscape.base_height(c.x + r.x * 17.0, c.z + r.z * 17.0), Landscape.base_height(c.x - r.x * 17.0, c.z - r.z * 17.0))
			var fill := side_h - (c.y + IN_H + 0.6)
			if fill > 0.5:
				var fx := xf.translated_local(Vector3(0, IN_H + 0.6 + fill * 0.5, 0))
				var e := Build.box(Vector3(34.0, fill, seg_len), earth)
				e.transform = fx
				root.add_child(e)
				body.add_child(_box_shape(Vector3(34.0, fill, seg_len), fx))
			i = j
		# portal faces at both ends
		for end in [[a0, 1.0], [a1, -1.0]]:
			var pi: int = end[0]
			var pp := road.point(pi)
			var f := road.forward(pi) * float(end[1])
			var face_h := maxf(Landscape.base_height(pp.x, pp.z) - pp.y, IN_H + 3.0) + 2.0
			var px := Transform3D(Basis.looking_at(f, Vector3.UP), pp)
			for sd in [-1.0, 1.0]:
				var side := px.translated_local(Vector3(sd * (IN_W + 5.5), face_h * 0.5, 0))
				var sb := Build.box(Vector3(10.0, face_h, 1.2), portal)
				sb.transform = side
				root.add_child(sb)
				body.add_child(_box_shape(Vector3(10.0, face_h, 1.2), side))
			var top_h := face_h - IN_H
			var top := px.translated_local(Vector3(0, IN_H + top_h * 0.5, 0))
			var tb := Build.box(Vector3(IN_W * 2.0 + 1.0, top_h, 1.2), portal)
			tb.transform = top
			root.add_child(tb)
			var lbl := Build.label3d("OLD RAIL TUNNEL  1911", Vector3.ZERO, Vector3.ZERO, 0.6, Color(0.92, 0.88, 0.78))
			lbl.transform = px.translated_local(Vector3(0, IN_H + 1.2, 0.65))
			root.add_child(lbl)
		poi["tunnel"] = road.point((run[0] + run[1]) / 2)
		poi["tunnel_portal"] = road.point(a1 + 12)


func _naresh_home() -> void:
	var face := Vector3(NARESH_JN.x, 0, NARESH_JN.y)
	var h := _house(NARESH_HOME, face, Vector3(12, 6, 9), Color(0.95, 0.88, 0.80), Color(0.55, 0.22, 0.22), "NareshHome")
	h.add_child(Build.solid_box(Vector3(1.2, 1.0, 12), ToonMat.make(Color(0.36, 0.55, 0.30)), Vector3(-8, 0.5, 4), Vector3.ZERO, "Hedge"))
	h.add_child(Build.box(Vector3(3.0, 0.12, 2.0), ToonMat.make(Color(0.40, 0.30, 0.22)), Vector3(5, 0.06, 8), Vector3.ZERO, "Garden"))
	poi["naresh_home"] = h.position


# --- items ---------------------------------------------------------------------

## Loose things to pick up. Fuel: one can by the homestead garage for the
## tutorial, and a stash behind the Last Fuel kiosk (the pumps are dead) -
## including one empty can, so players learn to check before lugging.
func _items() -> void:
	# Memory Fragments: one on each route (dock on the valley road, lookout
	# deck on the ridge) plus the shed roof at the water works - with the one
	# the cooling station gives, careful players reach a first Memory Rose.
	_place_fragment("dock", poi["dock"] + Vector3(0, 0.3, 0) + Basis.looking_at(-DOCK_DIR.normalized(), Vector3.UP) * Vector3(0, 0, -14.0))
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
	for cl in CLEARINGS:
		if (Vector2(x, z) - (cl[0] as Vector2)).length() < float(cl[1]):
			return true
	return false


func _xf(pos: Vector3, yaw: float, scale: Vector3) -> Transform3D:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	return Transform3D(b, pos)
