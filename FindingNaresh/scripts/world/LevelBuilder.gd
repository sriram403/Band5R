class_name LevelBuilder
extends RefCounted

## Assembles the prototype world: terrain, road, scatter, landmarks, sky.
##
## Placements live in the const tables at the top of this file, so the layout is
## handcrafted data rather than procedural generation. Only the small scatter
## (trees, rocks, bushes) uses a fixed-seed RNG, which keeps the world identical
## on every run - remembering the route has to be rewarding.

static var ROUTE_POINTS := PackedVector2Array([
	Vector2(0, -150),
	Vector2(85, -128),
	Vector2(140, -55),
	Vector2(150, 30),
	Vector2(112, 105),
	Vector2(35, 152),
	Vector2(-48, 148),
	Vector2(-120, 95),
	Vector2(-152, 15),
	Vector2(-130, -70),
	Vector2(-62, -140),
])

const PONDS := [
	{"pos": Vector3(92, 0, -18), "radius": 36.0, "depth": 5.0},
	{"pos": Vector3(-70, 0, 60), "radius": 22.0, "depth": 3.2},
]

## Bessi sits on a raised hill in the middle of the loop so its five rose
## monuments break the treeline and can be navigated by from anywhere on the road.
const MOUNDS := [
	{"pos": Vector3(20, 0, 8), "radius": 105.0, "height": 26.0, "plateau": 34.0},
]

const ROSE_CENTRE := Vector3(20, 0, 8)
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

var route: Route
var world: Node3D
var camper_spawn := Transform3D.IDENTITY
var player_spawns: Array[Transform3D] = []


func build() -> Node3D:
	route = Route.new(ROUTE_POINTS, true)
	world = Node3D.new()
	world.name = "World"

	world.add_child(_environment())
	world.add_child(_sun())
	world.add_child(Landscape.build_terrain(route, PONDS, MOUNDS))
	world.add_child(Landscape.build_road(route))
	for p in PONDS:
		world.add_child(_pond(p))

	_scatter()
	_backdrop()
	_landmarks()
	_signage()
	_spawns()
	return world


# --- spawns --------------------------------------------------------------------

func _spawns() -> void:
	var i := 6                       # a few metres along the road from the homestead
	var p := route.point(i)
	var f := route.forward(i)
	var r := route.right(i)
	var basis := Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP)
	# wheel radius + suspension rest length puts the chassis origin ~0.75 m up
	camper_spawn = Transform3D(basis, p + r * 1.7 + Vector3.UP * 0.80)

	# Stand off the van's rear quarter, looking past it up the road, so the
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
	env.fog_depth_begin = 190.0
	env.fog_depth_end = 900.0
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
	m.radial_segments = 36
	var y: float = Landscape.natural_height(c.x, c.z, [], MOUNDS) - float(p["depth"]) * level
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

	var collide_body := StaticBody3D.new()
	collide_body.name = "TreeColliders"

	var attempts := 9000
	for _i in attempts:
		var x := rng.randf_range(-385.0, 385.0)
		var z := rng.randf_range(-385.0, 385.0)
		var near := route.nearest(x, z)
		var d: float = near["dist"]
		if d < 9.5:
			continue
		if _in_pond(x, z, 4.0):
			continue
		if _in_clearing(x, z):
			continue
		# thin the woods right beside the road so sightlines stay open
		if d < 26.0 and rng.randf() < 0.62:
			continue

		var y := _h(x, z)
		var kind := rng.randf()

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
			# same RNG call order as before, so the world layout does not change
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

	world.add_child(_multi("Trunks", trunk_mesh, ToonMat.make(C_TRUNK, 0.02), trunks, []))
	world.add_child(_multi("Pines", pine_mesh, ToonMat.make(Color.WHITE, 0.035), pines, pine_cols))
	world.add_child(_multi("Canopies", blob_mesh, ToonMat.make(Color.WHITE, 0.035), blobs, blob_cols))
	world.add_child(_multi("Rocks", rock_mesh, ToonMat.make(Color.WHITE, 0.02), rocks, rock_cols))
	world.add_child(_multi("Bushes", bush_mesh, ToonMat.make(Color.WHITE, 0.02), bushes, bush_cols))
	world.add_child(collide_body)


func _cyl_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	return _tree_shape(pos, radius, height)


func _tree_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = pos
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
	for i in 56:
		var a := TAU * float(i) / 56.0 + rng.randf_range(-0.05, 0.05)
		var dist := rng.randf_range(520.0, 780.0)
		var hgt := rng.randf_range(80.0, 210.0)
		var rad := hgt * rng.randf_range(0.7, 1.15)
		var pos := Vector3(cos(a) * dist, hgt * 0.35 - 20.0, sin(a) * dist)
		var mi := Build.cone(rad, hgt, far2 if i % 3 == 0 else far, pos, Vector3.ZERO, 9, "Peak%d" % i)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	world.add_child(root)


# --- landmarks -----------------------------------------------------------------

func _landmarks() -> void:
	_homestead()
	_water_tower(Vector3(-196, 0, 52))
	_barn(Vector3(-58, 0, -66))
	_five_roses(ROSE_CENTRE)
	_info_board(24, 8.0)
	_fence_run(30, 46, 9.5)


func _homestead() -> void:
	var i := 2
	var p := route.point(i)
	var r := route.right(i)
	var f := route.forward(i)
	var origin := p + r * 20.0
	origin.y = _h(origin.x, origin.z)

	var root := Node3D.new()
	root.name = "Homestead"
	root.position = origin
	root.basis = Basis.looking_at(-r, Vector3.UP)

	var wall := ToonMat.make(Color(0.93, 0.88, 0.74))
	var roof := ToonMat.make(Color(0.78, 0.34, 0.26))
	var trim := ToonMat.make(Color(0.36, 0.52, 0.68))

	# house
	root.add_child(Build.solid_box(Vector3(11, 5, 8), wall, Vector3(0, 2.5, 0), Vector3.ZERO, "House"))
	var r1 := Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, -1.55), Vector3(-34, 0, 0), "Roof1")
	var r2 := Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, 1.55), Vector3(34, 0, 0), "Roof2")
	root.add_child(r1)
	root.add_child(r2)
	root.add_child(Build.box(Vector3(1.2, 2.6, 0.2), trim, Vector3(-2.5, 1.3, 4.05), Vector3.ZERO, "Door"))
	root.add_child(Build.box(Vector3(1.8, 1.4, 0.2), trim, Vector3(2.0, 3.0, 4.05), Vector3.ZERO, "Window"))
	root.add_child(Build.solid_cyl(0.5, 3.0, ToonMat.make(Color(0.6, 0.35, 0.3)), Vector3(3.6, 6.4, -1.0), Vector3.ZERO, "Chimney"))

	# lean-to garage
	root.add_child(Build.solid_box(Vector3(7, 3.4, 6), ToonMat.make(Color(0.72, 0.70, 0.66)), Vector3(-10, 1.7, 1.0), Vector3.ZERO, "Garage"))
	root.add_child(Build.box(Vector3(7.6, 0.4, 6.6), roof, Vector3(-10, 3.6, 1.0), Vector3(-6, 0, 0), "GarageRoof"))

	# mailbox by the road, a readable "you start here" marker
	var mb := Node3D.new()
	mb.name = "Mailbox"
	mb.position = Vector3(0, 0, 17.5)
	mb.add_child(Build.cyl(0.09, 1.3, ToonMat.make(C_WOOD), Vector3(0, 0.65, 0), Vector3.ZERO, 8, "Post"))
	mb.add_child(Build.box(Vector3(0.4, 0.35, 0.6), ToonMat.make(Color(0.85, 0.75, 0.30)), Vector3(0, 1.45, 0), Vector3.ZERO, "Box"))
	root.add_child(mb)

	world.add_child(root)


func _water_tower(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "WaterTower"
	root.position = pos

	var steel := ToonMat.make(Color(0.62, 0.66, 0.68))
	var tank := ToonMat.make(Color(0.86, 0.84, 0.78))
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var lp := Vector3(cos(a) * 3.4, 7.0, sin(a) * 3.4)
		var leg := Build.cyl(0.22, 15.0, steel, lp, Vector3.ZERO, 8, "Leg%d" % k)
		leg.rotation_degrees = Vector3(sin(a) * 6.0, 0, -cos(a) * 6.0)
		root.add_child(leg)
	root.add_child(Build.cyl(4.6, 6.0, tank, Vector3(0, 17.5, 0), Vector3.ZERO, 18, "Tank"))
	root.add_child(Build.cone(4.9, 2.4, ToonMat.make(Color(0.72, 0.36, 0.30)), Vector3(0, 21.7, 0), Vector3.ZERO, 18, "TankRoof"))
	root.add_child(Build.cyl(0.35, 14.0, steel, Vector3(3.2, 7.0, 0), Vector3.ZERO, 8, "Downpipe"))
	var lbl := Build.label3d("BESSI WATER CO.", Vector3(0, 17.8, 4.75), Vector3(0, 0, 0), 0.9, Color(0.25, 0.30, 0.38))
	root.add_child(lbl)
	world.add_child(root)


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
	world.add_child(root)


## The destination silhouette: five giant rose monuments on the central hill.
## Visible from most of the loop, which is what makes the route learnable.
func _five_roses(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FiveRoses"
	world.add_child(root)

	var centre := at
	centre.y = Landscape.plateau_height(MOUNDS[0], PONDS, MOUNDS)

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

	var sign_pos := centre + Vector3(0, 0, 31.0)
	sign_pos.y = _h(sign_pos.x, sign_pos.z)
	var s := Node3D.new()
	s.name = "WelcomeSign"
	s.position = sign_pos
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(-2.4, 2.0, 0), Vector3.ZERO, 8, "PostL"))
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(2.4, 2.0, 0), Vector3.ZERO, 8, "PostR"))
	s.add_child(Build.box(Vector3(6.4, 2.2, 0.18), ToonMat.make(Color(0.93, 0.90, 0.80)), Vector3(0, 3.4, 0), Vector3.ZERO, "Board"))
	s.add_child(Build.label3d("BESSI\nand the 5 ROSES", Vector3(0, 3.5, 0.12), Vector3.ZERO, 0.52, Color(0.70, 0.16, 0.24)))
	root.add_child(s)


func _rose_monument(pos: Vector3, scale: float, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Rose"
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale

	var green := ToonMat.make(Color(0.28, 0.48, 0.26), 0.03)
	n.add_child(Build.cyl(1.6, 1.0, ToonMat.make(C_STONE, 0.03), Vector3(0, 0.5, 0), Vector3.ZERO, 14, "Base"))
	n.add_child(Build.cyl(0.42, 12.0, green, Vector3(0, 6.6, 0), Vector3.ZERO, 10, "Stem"))
	# leaves
	for s in [-1.0, 1.0]:
		var leaf := Build.sphere(1.0, green, Vector3(s * 1.5, 5.4, 0), Vector3(1.6, 0.25, 0.8), "Leaf")
		leaf.rotation_degrees = Vector3(0, 0, s * 22.0)
		n.add_child(leaf)
	# bloom: three petal rings plus a core
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


func _info_board(route_index: int, offset: float) -> void:
	var p := route.point(route_index)
	var r := route.right(route_index)
	var pos := p + r * offset
	pos.y = _h(pos.x, pos.z)
	var n := Node3D.new()
	n.name = "InfoBoard"
	n.position = pos
	n.basis = Basis.looking_at(-r, Vector3.UP)
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(-1.1, 1.2, 0), Vector3.ZERO, 8, "PostL"))
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(1.1, 1.2, 0), Vector3.ZERO, 8, "PostR"))
	var board := Build.box(Vector3(3.0, 1.9, 0.12), ToonMat.make(Color(0.90, 0.87, 0.78)), Vector3(0, 2.3, 0), Vector3(-14, 0, 0), "Board")
	n.add_child(board)
	n.add_child(Build.label3d("ROSE VALLEY LOOP\n<- Water Tower   Bessi ->", Vector3(0, 2.36, 0.19), Vector3(-14, 0, 0), 0.24, Color(0.22, 0.26, 0.32)))
	world.add_child(n)


func _signage() -> void:
	var picks := [
		{"i": 60, "text": "BESSI\n12 km", "side": 1.0},
		{"i": 150, "text": "BEND\nAHEAD", "side": 1.0},
		{"i": 250, "text": "WATER\nTOWER", "side": -1.0},
		{"i": 360, "text": "SLOW\nCATTLE", "side": 1.0},
	]
	for s in picks:
		var i: int = int(s["i"]) % route.point_count()
		var p := route.point(i)
		var r := route.right(i)
		var side: float = s["side"]
		var pos := p + r * (6.4 * side)
		pos.y = _h(pos.x, pos.z)
		var n := Node3D.new()
		n.name = "Sign"
		n.position = pos
		n.basis = Basis.looking_at(r * -side, Vector3.UP)
		n.add_child(Build.cyl(0.08, 2.6, ToonMat.make(Color(0.60, 0.62, 0.64)), Vector3(0, 1.3, 0), Vector3.ZERO, 8, "Post"))
		n.add_child(Build.box(Vector3(1.7, 1.1, 0.1), ToonMat.make(Color(0.94, 0.92, 0.86)), Vector3(0, 2.5, 0), Vector3.ZERO, "Plate"))
		n.add_child(Build.label3d(str(s["text"]), Vector3(0, 2.5, 0.08), Vector3.ZERO, 0.30, Color(0.20, 0.24, 0.30)))
		world.add_child(n)


func _fence_run(from_i: int, to_i: int, offset: float) -> void:
	var root := Node3D.new()
	root.name = "Fence"
	var wood := ToonMat.make(C_WOOD, 0.015)
	var i := from_i
	while i < to_i:
		var p := route.point(i)
		var r := route.right(i)
		var pos := p + r * offset
		pos.y = _h(pos.x, pos.z)
		root.add_child(Build.cyl(0.09, 1.5, wood, pos + Vector3(0, 0.75, 0), Vector3.ZERO, 6, "Post"))
		if i + 2 < to_i:
			var p2 := route.point(i + 2)
			var r2 := route.right(i + 2)
			var pos2 := p2 + r2 * offset
			pos2.y = _h(pos2.x, pos2.z)
			for hgt in [0.6, 1.15]:
				var a := pos + Vector3(0, hgt, 0)
				var b := pos2 + Vector3(0, hgt, 0)
				var mid := (a + b) * 0.5
				var rail := Build.box(Vector3(0.06, 0.14, a.distance_to(b)), wood, mid, Vector3.ZERO, "Rail")
				rail.basis = Basis.looking_at(b - a, Vector3.UP)
				root.add_child(rail)
		i += 2
	world.add_child(root)


# --- helpers -------------------------------------------------------------------

## Ground height including ponds and landmark mounds.
func _h(x: float, z: float) -> float:
	return Landscape.sample_height(route, x, z, PONDS, MOUNDS)


func _in_pond(x: float, z: float, margin: float) -> bool:
	for p in PONDS:
		var c: Vector3 = p["pos"]
		if Vector2(x - c.x, z - c.z).length() < float(p["radius"]) + margin:
			return true
	return false


## Keep landmark footprints clear of scattered trees.
func _in_clearing(x: float, z: float) -> bool:
	var clearings := [
		{"c": Vector2(20, 8), "r": 60.0},       # five roses plaza
		{"c": Vector2(-196, 52), "r": 26.0},    # water tower
		{"c": Vector2(-58, -66), "r": 30.0},    # barn
	]
	for cl in clearings:
		if (Vector2(x, z) - Vector2(cl["c"])).length() < float(cl["r"]):
			return true
	return false


func _xf(pos: Vector3, yaw: float, scale: Vector3) -> Transform3D:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	return Transform3D(b, pos)
