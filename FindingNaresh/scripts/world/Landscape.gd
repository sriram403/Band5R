class_name Landscape
extends RefCounted

## Generates the terrain shell and the road ribbon from a Route.
##
## The terrain is a single vertex-coloured toon-shaded mesh with trimesh
## collision. Inside the road corridor it is flattened to the road height, so the
## camper always has a clean drivable surface while the surrounding land rolls.

const EXTENT := 800.0        ## terrain is EXTENT x EXTENT metres, centred on origin
const STEP := 5.0            ## grid resolution
const ROAD_HALF := 4.0       ## asphalt half-width
const SHOULDER := 1.5        ## dirt shoulder width beyond the asphalt
const FLAT_RADIUS := 7.0     ## terrain is fully flat within this distance of the centreline
const BLEND_RADIUS := 30.0   ## ... and eases back to natural ground by here

const GRASS := Color(0.365, 0.615, 0.275)
const GRASS_DARK := Color(0.255, 0.470, 0.225)
const DRY := Color(0.640, 0.590, 0.375)
const ROCK := Color(0.470, 0.455, 0.440)
const SAND := Color(0.760, 0.700, 0.500)


static func build_terrain(route: Route, ponds: Array, mounds: Array = []) -> StaticBody3D:
	var n := int(EXTENT / STEP) + 1
	var origin := -EXTENT * 0.5

	# --- height grid ---------------------------------------------------------
	var h := PackedFloat32Array()
	h.resize(n * n)
	var road_dist := PackedFloat32Array()
	road_dist.resize(n * n)

	for iz in n:
		var z := origin + iz * STEP
		for ix in n:
			var x := origin + ix * STEP
			var natural := natural_height(x, z, ponds, mounds)
			var near := route.nearest(x, z)
			var d: float = near["dist"]
			var y := natural
			if d < BLEND_RADIUS:
				var t: float = smoothstep(FLAT_RADIUS, BLEND_RADIUS, d)
				y = lerp(float(near["height"]), natural, t)
			h[iz * n + ix] = y
			road_dist[iz * n + ix] = d

	# --- mesh ----------------------------------------------------------------
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in n:
		var z := origin + iz * STEP
		for ix in n:
			var x := origin + ix * STEP
			var y := h[iz * n + ix]
			var hx := h[iz * n + clampi(ix + 1, 0, n - 1)] - h[iz * n + clampi(ix - 1, 0, n - 1)]
			var hz := h[clampi(iz + 1, 0, n - 1) * n + ix] - h[clampi(iz - 1, 0, n - 1) * n + ix]
			var slope := Vector2(hx, hz).length() / (2.0 * STEP)
			# Analytic normal from the height field. Deriving it from triangle
			# winding gave a flat, unlit terrain, and this is exact anyway.
			st.set_normal(Vector3(-hx, 2.0 * STEP, -hz).normalized())
			st.set_color(_ground_color(x, z, y, slope, road_dist[iz * n + ix]))
			st.set_uv(Vector2(x, z) * 0.06)
			st.add_vertex(Vector3(x, y, z))
	for iz in n - 1:
		for ix in n - 1:
			var a := iz * n + ix
			var b := a + 1
			var c := a + n
			var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.metallic_specular = 0.06
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # winding-proof

	var mesh := st.commit()

	var body := StaticBody3D.new()
	body.name = "Terrain"
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mi)

	var cs := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	# Terrain is a one-sided sheet; enabling backface collision makes it solid
	# regardless of triangle winding and stops anything tunnelling through it.
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	return body


static func build_road(route: Route) -> Node3D:
	var root := Node3D.new()
	root.name = "Road"

	root.add_child(_ribbon(route, ROAD_HALF, 0.05, _asphalt(), "Asphalt"))
	root.add_child(_ribbon(route, ROAD_HALF + SHOULDER, 0.025, _dirt(), "Shoulder"))
	root.add_child(_edge_lines(route))
	root.add_child(_centre_dashes(route))
	return root


const PLATEAU_BLEND := 18.0   ## metres over which a plateau eases back into the hill

## Ground before the road corridor is flattened into it.
static func natural_height(x: float, z: float, ponds: Array = [], mounds: Array = []) -> float:
	var h := _raw_height(x, z, ponds, mounds)
	# A mound with a "plateau" radius gets a level top, so a plaza built there
	# sits flush with the ground instead of floating over a dome.
	for m in mounds:
		if not m.has("plateau"):
			continue
		var c: Vector3 = m["pos"]
		var pr: float = m["plateau"]
		var d := Vector2(x - c.x, z - c.z).length()
		if d < pr + PLATEAU_BLEND:
			h = lerpf(plateau_height(m, ponds, mounds), h, smoothstep(pr, pr + PLATEAU_BLEND, d))
	return h


## Level of a mound's plateau: the natural ground at its centre.
static func plateau_height(m: Dictionary, ponds: Array, mounds: Array) -> float:
	var c: Vector3 = m["pos"]
	return _raw_height(c.x, c.z, ponds, mounds)


static func _raw_height(x: float, z: float, ponds: Array, mounds: Array) -> float:
	return Route.ground_noise(x, z) + mound_raise(x, z, mounds) - pond_carve(x, z, ponds)


## Height of the terrain surface at a world position, used to sit props on the
## ground without needing a physics query.
static func sample_height(route: Route, x: float, z: float, ponds: Array = [], mounds: Array = []) -> float:
	var natural := natural_height(x, z, ponds, mounds)
	var near := route.nearest(x, z)
	var d: float = near["dist"]
	if d < BLEND_RADIUS:
		var t: float = smoothstep(FLAT_RADIUS, BLEND_RADIUS, d)
		return lerp(float(near["height"]), natural, t)
	return natural


## Smooth dome, used to lift landmark hills above the treeline so they can be
## navigated by. Flat-topped and flat-edged, so it blends into the noise field.
static func mound_raise(x: float, z: float, mounds: Array) -> float:
	var lift := 0.0
	for m in mounds:
		var c: Vector3 = m["pos"]
		var r: float = m["radius"]
		var pd := Vector2(x - c.x, z - c.z).length()
		if pd < r:
			lift += float(m["height"]) * (1.0 - smoothstep(0.0, r, pd))
	return lift


## Bowl profile for ponds: flat floor out to 55% of the radius, then a shore
## that eases back to natural ground. Shared by the mesh, the collision and the
## prop placement so the water plane always meets a real shoreline.
static func pond_carve(x: float, z: float, ponds: Array) -> float:
	var drop := 0.0
	for pond in ponds:
		var c: Vector3 = pond["pos"]
		var r: float = pond["radius"]
		var pd := Vector2(x - c.x, z - c.z).length()
		if pd < r:
			drop += float(pond["depth"]) * smoothstep(r, r * 0.55, pd)
	return drop


## Radius at which the water plane meets the shore, for a given water level
## expressed as a fraction of the pond depth.
static func pond_water_radius(r: float, level_fraction := 0.6) -> float:
	# invert smoothstep(r, 0.55r, pd) = level_fraction
	var u := 0.5 - sin(asin(1.0 - 2.0 * level_fraction) / 3.0)
	return r - u * (r * 0.45)


# --- internals -----------------------------------------------------------------

static func _ground_color(x: float, z: float, y: float, slope: float, dist_to_road: float) -> Color:
	var patch := (sin(x * 0.031 + 2.0) * cos(z * 0.027 - 1.0) + 1.0) * 0.5
	var c := GRASS_DARK.lerp(GRASS, patch)
	# higher ground dries out
	c = c.lerp(DRY, clampf((y - 4.0) / 14.0, 0.0, 0.45))
	# steep faces show rock
	c = c.lerp(ROCK, clampf((slope - 0.55) / 0.5, 0.0, 0.85))
	# scuffed dirt beside the tarmac
	if dist_to_road < 12.0:
		c = c.lerp(SAND, 1.0 - smoothstep(5.0, 12.0, dist_to_road))
	return c


static func _unculled_flat(c: Color) -> StandardMaterial3D:
	var m := ToonMat.flat(c)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _asphalt() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.235, 0.235, 0.260)
	m.roughness = 0.98
	m.metallic_specular = 0.05
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func _dirt() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.560, 0.475, 0.330)
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func _ribbon(route: Route, half: float, lift: float, mat: Material, nm: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := route.point_count()
	for i in count:
		var p := route.point(i)
		var r := route.right(i)
		var nrm := r.cross(route.forward(i)).normalized()
		var up := Vector3.UP * lift
		st.set_normal(nrm)
		st.set_uv(Vector2(0.0, i * 0.12)); st.add_vertex(p - r * half + up)
		st.set_normal(nrm)
		st.set_uv(Vector2(1.0, i * 0.12)); st.add_vertex(p + r * half + up)
	for i in count:
		var a := i * 2
		var b := a + 1
		var c := (wrapi(i + 1, 0, count)) * 2
		var d := c + 1
		st.add_index(a); st.add_index(c); st.add_index(b)
		st.add_index(b); st.add_index(c); st.add_index(d)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _edge_lines(route: Route) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := route.point_count()
	var w := 0.16
	for side in [-1.0, 1.0]:
		var s := float(side)
		for i in count:
			var p := route.point(i)
			var r := route.right(i)
			var off := r * (s * (ROAD_HALF - 0.35))
			var up := Vector3.UP * 0.07
			st.set_normal(r.cross(route.forward(i)).normalized())
			st.add_vertex(p + off - r * w + up)
			st.add_vertex(p + off + r * w + up)
	# indices for both strips
	for s in 2:
		var base_i := s * count * 2
		for i in count:
			var a := base_i + i * 2
			var b := a + 1
			var c := base_i + wrapi(i + 1, 0, count) * 2
			var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	var mi := MeshInstance3D.new()
	mi.name = "EdgeLines"
	mi.mesh = st.commit()
	mi.material_override = _unculled_flat(Color(0.90, 0.87, 0.72))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _centre_dashes(route: Route) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := route.point_count()
	var dash_len := 3     # samples on
	var gap_len := 4      # samples off
	var w := 0.14
	var i := 0
	var quads := 0
	while i < count:
		var seg_end: int = mini(i + dash_len, count)
		for k in range(i, seg_end):
			var p := route.point(k)
			var r := route.right(k)
			var up := Vector3.UP * 0.07
			st.set_normal(r.cross(route.forward(k)).normalized())
			st.add_vertex(p - r * w + up)
			st.add_vertex(p + r * w + up)
		var strip: int = seg_end - i
		if strip >= 2:
			var base := quads
			for k in strip - 1:
				var a := base + k * 2
				var b := a + 1
				var c := a + 2
				var d := a + 3
				st.add_index(a); st.add_index(c); st.add_index(b)
				st.add_index(b); st.add_index(c); st.add_index(d)
		quads += strip * 2
		i += dash_len + gap_len
	var mi := MeshInstance3D.new()
	mi.name = "CentreDashes"
	mi.mesh = st.commit()
	mi.material_override = _unculled_flat(Color(0.93, 0.90, 0.62))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
