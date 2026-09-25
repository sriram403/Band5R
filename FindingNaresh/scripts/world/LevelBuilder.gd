class_name LevelBuilder
extends "res://scripts/world/LevelLandmarks.gd"

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
## Placements live in const tables (LevelLayout.gd), so the layout is handcrafted
## data rather than procedural generation. Only the small scatter (trees,
## rocks, bushes) uses a fixed-seed RNG, so the world is identical on every
## run - remembering the route has to be rewarding.
##
## The code is split by job over five files, each extending the one before:
## LevelLayout (the data, shared state, helpers) -> LevelScatter (trees, rocks,
## backdrop) -> LevelPlaces (the greybox places) -> LevelLandmarks (the
## Milestone A landmarks, signs) -> this file (the build order, roads,
## environment, spawns, items).

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
	var mood := Mood.new()
	mood.name = "Mood"
	world.add_child(mood)
	return world


func _lap(what: String, since: int) -> int:
	var now := Time.get_ticks_msec()
	print("[World] %s %d ms" % [what, now - since])
	return now


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
	_bridge_hut_and_power()
	_five_roses(ROSE_CENTRE)
	_p2_home()
	_town()
	_roadworks()
	_traffic()
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
	var town: Node3D = world.get_node("TownFuel")
	_place_can(town.transform * Vector3(-4.5, 0, 2.2), 0.0, "town_empty")
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
