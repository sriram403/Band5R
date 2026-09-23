class_name Landscape
extends RefCounted

## Terrain, roads and water for the whole world.
##
## Height is built up in layers, and each layer is available on its own:
##   base_height     rolling hills + authored mounds/plateaus - lake bowls
##   natural_height  base with the river channel carved in
##   ground          natural with road corridors flattened in (what you stand on)
## Roads and the river follow base_height, so they never chase their own cuts.
## Call setup() once before any height query.

const EXTENT := 1600.0       ## terrain is EXTENT x EXTENT metres, centred on origin
const STEP := 5.0            ## grid resolution
const ROAD_HALF := 4.0       ## asphalt half-width
const GRAVEL_HALF := 3.0     ## gravel track half-width
const SHOULDER := 1.5        ## dirt shoulder width beyond the road
const FLAT_RADIUS := 7.0     ## terrain is fully flat within this distance of a road
const BLEND_RADIUS := 30.0   ## ... and eases back to natural ground by here
const PLATEAU_BLEND := 18.0  ## metres over which a plateau eases back into the hill

const RIVER_HALF := 9.0      ## half-width of the river channel floor + banks
const RIVER_DEPTH := 3.6     ## channel depth below the river's line
const RIVER_BANK := 10.0     ## how far the banks ease back to natural ground
const RIVER_WATER := 0.55    ## water surface, as a fraction of depth above the bed

const GRASS := Color(0.365, 0.615, 0.275)
const GRASS_DARK := Color(0.255, 0.470, 0.225)
const DRY := Color(0.640, 0.590, 0.375)
const ROCK := Color(0.470, 0.455, 0.440)
const SAND := Color(0.760, 0.700, 0.500)
const MUD := Color(0.45, 0.40, 0.30)

static var network: RoadNetwork
static var river: Route
static var ponds: Array = []
static var mounds: Array = []
## Level building pads: {pos: Vector3, radius, blend}. Buildings sit on them
## so yards are flat and props neither float nor sink.
static var pads: Array = []


static func setup(net: RoadNetwork, river_route: Route, pond_list: Array, mound_list: Array) -> void:
	network = net
	river = river_route
	ponds = pond_list
	mounds = mound_list


# --- height layers -------------------------------------------------------------

static func base_height(x: float, z: float) -> float:
	var h := _raw_height(x, z)
	# A mound with a "plateau" radius gets a level top, so a plaza built there
	# sits flush with the ground instead of floating over a dome.
	for m in mounds:
		if not m.has("plateau"):
			continue
		var c: Vector3 = m["pos"]
		var pr: float = m["plateau"]
		var d := Vector2(x - c.x, z - c.z).length()
		if d < pr + PLATEAU_BLEND:
			h = lerpf(plateau_height(m), h, smoothstep(pr, pr + PLATEAU_BLEND, d))
	return h


static func natural_height(x: float, z: float, _ponds = null, _mounds = null) -> float:
	var h := base_height(x, z)
	if river == null:
		return h
	var near := river.nearest(x, z)
	var d: float = near["dist"]
	if d < RIVER_HALF + RIVER_BANK:
		var bed: float = float(near["height"]) - RIVER_DEPTH
		var t := smoothstep(RIVER_HALF * 0.5, RIVER_HALF + RIVER_BANK, d)
		# carve only: a river never raises the ground
		h = minf(h, lerpf(bed, h, t))
	return h


## The surface you actually stand and drive on. Once the terrain is built this
## is read off the terrain grid, so it matches the visible ground exactly.
static func ground(x: float, z: float) -> float:
	if grid_n > 0:
		var gh := _grid_sample(grid_h, x, z, NAN)
		if not is_nan(gh):
			return gh
	var n := natural_height(x, z)
	if network == null:
		return n
	var near := network.nearest(x, z)
	var d: float = near["dist"]
	if d >= BLEND_RADIUS:
		return n
	var g := lerpf(float(near["height"]), n, smoothstep(FLAT_RADIUS, BLEND_RADIUS, d))
	# Roads never fill the river channel: where they cross it there is a
	# bridge deck instead, and near it the banks stay carved.
	return lerpf(g, n, river_weight(x, z))


## 1 inside the river channel, 0 away from it.
static func river_weight(x: float, z: float) -> float:
	if river == null:
		return 0.0
	return 1.0 - smoothstep(RIVER_HALF, RIVER_HALF + 6.0, river_distance(x, z))


static func river_distance(x: float, z: float) -> float:
	if river == null:
		return 1e9
	if grid_n > 0:
		return _grid_sample(grid_river_d, x, z, 1e9)
	return float(river.nearest(x, z)["dist"])


## Distance to the nearest road centreline (1e9 when far from every road).
static func road_distance(x: float, z: float) -> float:
	if grid_n > 0:
		return _grid_sample(grid_road_d, x, z, 1e9)
	return float(network.nearest(x, z)["dist"]) if network else 1e9


## Water surface height of the river at its nearest point.
static func river_water_level(i: int) -> float:
	return river.point(i).y - RIVER_DEPTH * (1.0 - RIVER_WATER)


## Kept for older callers: the route/pond/mound arguments are ignored now that
## the landscape knows its own layout.
static func sample_height(_route, x: float, z: float, _ponds = null, _mounds = null) -> float:
	return ground(x, z)


## Level of a mound's plateau: the natural ground at its centre.
static func plateau_height(m: Dictionary, _ponds = null, _mounds = null) -> float:
	var c: Vector3 = m["pos"]
	return _raw_height(c.x, c.z)


static func _raw_height(x: float, z: float) -> float:
	return Route.ground_noise(x, z) + mound_raise(x, z) - pond_carve(x, z)


## Smooth dome, used to lift landmark hills above the treeline so they can be
## navigated by.
static func mound_raise(x: float, z: float, _mounds = null) -> float:
	var lift := 0.0
	for m in mounds:
		var c: Vector3 = m["pos"]
		var r: float = m["radius"]
		var pd := Vector2(x - c.x, z - c.z).length()
		if pd < r:
			lift += float(m["height"]) * (1.0 - smoothstep(0.0, r, pd))
	return lift


## Bowl profile for lakes: flat floor out to 55% of the radius, then a shore
## that eases back to natural ground.
static func pond_carve(x: float, z: float, _ponds = null) -> float:
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
	var u := 0.5 - sin(asin(1.0 - 2.0 * level_fraction) / 3.0)
	return r - u * (r * 0.45)


# --- terrain grid ----------------------------------------------------------------
#
# The terrain is solved once on its STEP-metre grid. Roads and the river are
# stamped onto the grid segment by segment (distance + height of the nearest
# centreline point), which is far cheaper than asking every vertex for its
# nearest road. After build_terrain() the grid is also the fastest and most
# faithful answer to "how high is the ground here" for placing props.

static var grid_n := 0
static var grid_h := PackedFloat32Array()        ## final ground height
static var grid_road_d := PackedFloat32Array()   ## distance to the nearest road centreline
static var grid_road_h := PackedFloat32Array()   ## that road's height
static var grid_river_d := PackedFloat32Array()  ## distance to the river line
static var grid_river_h := PackedFloat32Array()  ## the river line's height there
static var grid_gravel := PackedByteArray()      ## 1 where the nearest road is gravel

const STAMP_RADIUS := 45.0   ## how far from a road/river the grid records distance
const STAMP_STRIDE := 3      ## stamp every Nth centreline sample as a segment


static func _grid_origin() -> float:
	return -EXTENT * 0.5


## Give each pad its level: the natural ground at its centre (before roads).
static func set_pads(list: Array) -> void:
	pads = []
	for p in list:
		var c: Vector3 = p["pos"]
		var d := (p as Dictionary).duplicate()
		d["height"] = natural_height(c.x, c.z)
		pads.append(d)


static func _solve_grid() -> void:
	var n := int(EXTENT / STEP) + 1
	grid_n = n
	var total := n * n
	grid_h.resize(total)
	grid_road_d.resize(total)
	grid_road_h.resize(total)
	grid_river_d.resize(total)
	grid_river_h.resize(total)
	grid_gravel.resize(total)
	grid_road_d.fill(1e9)
	grid_river_d.fill(1e9)
	grid_gravel.fill(0)
	for r in network.roads:
		_stamp(r, grid_road_d, grid_road_h, 1 if r.surface == "gravel" else 0)
	if river != null:
		_stamp(river, grid_river_d, grid_river_h, -1)

	var origin := _grid_origin()
	for iz in n:
		var z := origin + iz * STEP
		for ix in n:
			var x := origin + ix * STEP
			var k := iz * n + ix
			var h := base_height(x, z)
			var rd := grid_river_d[k]
			if rd < RIVER_HALF + RIVER_BANK:
				var bed := grid_river_h[k] - RIVER_DEPTH
				h = minf(h, lerpf(bed, h, smoothstep(RIVER_HALF * 0.5, RIVER_HALF + RIVER_BANK, rd)))
			var d := grid_road_d[k]
			if d < BLEND_RADIUS:
				var g := lerpf(grid_road_h[k], h, smoothstep(FLAT_RADIUS, BLEND_RADIUS, d))
				h = lerpf(g, h, 1.0 - smoothstep(RIVER_HALF, RIVER_HALF + 6.0, rd))
			for pad in pads:
				var pc: Vector3 = pad["pos"]
				var pd := Vector2(x - pc.x, z - pc.z).length()
				var pr: float = pad["radius"]
				if pd < pr + float(pad["blend"]):
					h = lerpf(float(pad["height"]), h, smoothstep(pr, pr + float(pad["blend"]), pd))
			grid_h[k] = h


## Record, for every grid vertex near the route, the distance to and height of
## the closest point on the route. flag >= 0 also marks grid_gravel.
static func _stamp(route: Route, dist: PackedFloat32Array, hgt: PackedFloat32Array, flag: int) -> void:
	var n := grid_n
	var origin := _grid_origin()
	var cnt := route.point_count()
	var last := cnt if route.closed else cnt - 1
	var i := 0
	while i < last:
		var a := route.point(i)
		var b := route.point(mini(i + STAMP_STRIDE, cnt - 1) if not route.closed else i + STAMP_STRIDE)
		var abx := b.x - a.x
		var abz := b.z - a.z
		var len2 := maxf(abx * abx + abz * abz, 0.0001)
		var ix0 := maxi(0, int(floor((minf(a.x, b.x) - STAMP_RADIUS - origin) / STEP)))
		var ix1 := mini(n - 1, int(ceil((maxf(a.x, b.x) + STAMP_RADIUS - origin) / STEP)))
		var iz0 := maxi(0, int(floor((minf(a.z, b.z) - STAMP_RADIUS - origin) / STEP)))
		var iz1 := mini(n - 1, int(ceil((maxf(a.z, b.z) + STAMP_RADIUS - origin) / STEP)))
		for iz in range(iz0, iz1 + 1):
			var z := origin + iz * STEP
			for ix in range(ix0, ix1 + 1):
				var x := origin + ix * STEP
				var t := clampf(((x - a.x) * abx + (z - a.z) * abz) / len2, 0.0, 1.0)
				var dx := x - (a.x + abx * t)
				var dz := z - (a.z + abz * t)
				var d := sqrt(dx * dx + dz * dz)
				var k := iz * n + ix
				if d < dist[k]:
					dist[k] = d
					hgt[k] = lerpf(a.y, b.y, t)
					if flag >= 0:
						grid_gravel[k] = flag
		i += STAMP_STRIDE


## Bilinear sample of any grid layer; null once outside the terrain.
static func _grid_sample(layer: PackedFloat32Array, x: float, z: float, fallback: float) -> float:
	if grid_n == 0:
		return fallback
	var origin := _grid_origin()
	var fx := (x - origin) / STEP
	var fz := (z - origin) / STEP
	if fx < 0.0 or fz < 0.0 or fx > grid_n - 1 or fz > grid_n - 1:
		return fallback
	var ix := mini(int(fx), grid_n - 2)
	var iz := mini(int(fz), grid_n - 2)
	var tx := fx - ix
	var tz := fz - iz
	var k := iz * grid_n + ix
	var a := lerpf(layer[k], layer[k + 1], tx)
	var b := lerpf(layer[k + grid_n], layer[k + grid_n + 1], tx)
	return lerpf(a, b, tz)


static func build_terrain() -> StaticBody3D:
	_solve_grid()
	var n := grid_n
	var origin := _grid_origin()
	var count := n * n

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(count)
	normals.resize(count)
	colors.resize(count)
	for iz in n:
		var z := origin + iz * STEP
		for ix in n:
			var x := origin + ix * STEP
			var k := iz * n + ix
			var y := grid_h[k]
			var hx := grid_h[iz * n + mini(ix + 1, n - 1)] - grid_h[iz * n + maxi(ix - 1, 0)]
			var hz := grid_h[mini(iz + 1, n - 1) * n + ix] - grid_h[maxi(iz - 1, 0) * n + ix]
			var slope := Vector2(hx, hz).length() / (2.0 * STEP)
			verts[k] = Vector3(x, y, z)
			# Analytic normal from the height field. Deriving it from triangle
			# winding gave a flat, unlit terrain, and this is exact anyway.
			normals[k] = Vector3(-hx, 2.0 * STEP, -hz).normalized()
			colors[k] = _ground_color(x, z, y, slope, grid_road_d[k], grid_river_d[k], grid_gravel[k] == 1)

	var indices := PackedInt32Array()
	indices.resize((n - 1) * (n - 1) * 6)
	var w := 0
	for iz in n - 1:
		for ix in n - 1:
			var a := iz * n + ix
			var c := a + n
			indices[w] = a; indices[w + 1] = c; indices[w + 2] = a + 1
			indices[w + 3] = a + 1; indices[w + 4] = c; indices[w + 5] = c + 1
			w += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.metallic_specular = 0.06
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # winding-proof

	var body := StaticBody3D.new()
	body.name = "Terrain"
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mi)

	# Height-map collision: one cell per grid square, far cheaper to build and
	# query than a 200k-triangle trimesh. Its cells are 1 unit apart and centred
	# on the origin, so heights are stored /STEP and the shape scaled by STEP.
	var hm := HeightMapShape3D.new()
	hm.map_width = n
	hm.map_depth = n
	var scaled := PackedFloat32Array()
	scaled.resize(count)
	for k in count:
		scaled[k] = grid_h[k] / STEP
	hm.map_data = scaled
	var cs := CollisionShape3D.new()
	cs.name = "TerrainCollision"
	cs.shape = hm
	cs.scale = Vector3.ONE * STEP
	body.add_child(cs)
	return body


# --- roads and water -------------------------------------------------------------

## lift: small per-road height offset so overlapping ribbons at junctions do
## not z-fight.
static func build_road(route: Route, lift := 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Road_" + route.name
	var gravel := route.surface == "gravel"
	var half := GRAVEL_HALF if gravel else ROAD_HALF
	root.add_child(_ribbon(route, half, 0.05 + lift, _dirt() if gravel else _asphalt(), "Surface"))
	root.add_child(_ribbon(route, half + SHOULDER, 0.025 + lift, _dirt_shoulder(), "Shoulder"))
	if not gravel:
		root.add_child(_edge_lines(route, lift))
		root.add_child(_centre_dashes(route, lift))
	return root


static func build_river() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := river.point_count()
	var half := RIVER_HALF + 3.0
	for i in count:
		var p := river.point(i)
		p.y = river_water_level(i)
		var r := river.right(i)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, i * 0.1)); st.add_vertex(p - r * half)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, i * 0.1)); st.add_vertex(p + r * half)
	_strip_indices(st, count, false)
	var mi := MeshInstance3D.new()
	mi.name = "River"
	mi.mesh = st.commit()
	var m := ToonMat.water(Color(0.26, 0.55, 0.70, 0.86))
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- internals -----------------------------------------------------------------

static func _ground_color(x: float, z: float, y: float, slope: float, dist_to_road: float,
		dist_to_river: float, gravel: bool) -> Color:
	var patch := (sin(x * 0.031 + 2.0) * cos(z * 0.027 - 1.0) + 1.0) * 0.5
	var c := GRASS_DARK.lerp(GRASS, patch)
	# higher ground dries out
	c = c.lerp(DRY, clampf((y - 6.0) / 18.0, 0.0, 0.45))
	# steep faces show rock
	c = c.lerp(ROCK, clampf((slope - 0.55) / 0.5, 0.0, 0.85))
	# river banks: mud down by the water, sand on the shelf above
	if dist_to_river < RIVER_HALF + RIVER_BANK + 4.0:
		c = c.lerp(SAND, 1.0 - smoothstep(RIVER_HALF, RIVER_HALF + RIVER_BANK + 4.0, dist_to_river))
		c = c.lerp(MUD, 1.0 - smoothstep(RIVER_HALF * 0.6, RIVER_HALF + 1.0, dist_to_river))
	# scuffed dirt beside the road, wider and browner on gravel tracks
	var edge := 7.0 if gravel else 12.0
	if dist_to_road < edge:
		c = c.lerp(MUD if gravel else SAND, (0.6 if gravel else 1.0) * (1.0 - smoothstep(3.5, edge, dist_to_road)))
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
	# pale grey-tan gravel, so the track reads against the brown shoulders
	m.albedo_color = Color(0.70, 0.66, 0.58)
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func _dirt_shoulder() -> StandardMaterial3D:
	var m := _dirt()
	m.albedo_color = Color(0.560, 0.475, 0.330)
	return m


## True where a road sample is over the river: a bridge deck carries the road
## there, so no asphalt ribbon is drawn (otherwise it floats across any gap).
static func over_river(p: Vector3) -> bool:
	return river_distance(p.x, p.z) < RIVER_HALF + 7.0


static func _strip_indices(st: SurfaceTool, count: int, closed: bool, base := 0, route: Route = null) -> void:
	var quads := count if closed else count - 1
	for i in quads:
		if route != null and (over_river(route.point(i)) or over_river(route.point(i + 1))):
			continue
		var a := base + i * 2
		var b := a + 1
		var c := base + wrapi(i + 1, 0, count) * 2
		var d := c + 1
		st.add_index(a); st.add_index(c); st.add_index(b)
		st.add_index(b); st.add_index(c); st.add_index(d)


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
	_strip_indices(st, count, route.closed, 0, route)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Samples at the open ends of a road are left unpainted, so markings stop
## short of junctions instead of crossing the other road.
static func _painted(route: Route, i: int) -> bool:
	if over_river(route.point(i)):
		return false
	if route.closed:
		return true
	return i > 7 and i < route.point_count() - 8


static func _edge_lines(route: Route, lift: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := route.point_count()
	var w := 0.16
	var verts := 0
	for side in [-1.0, 1.0]:
		var s := float(side)
		var run := 0
		for i in count + (1 if route.closed else 0):
			var k := wrapi(i, 0, count)
			if not _painted(route, k):
				run = 0
				continue
			var p := route.point(k)
			var r := route.right(k)
			var off := r * (s * (ROAD_HALF - 0.35))
			var up := Vector3.UP * (0.07 + lift)
			st.set_normal(r.cross(route.forward(k)).normalized())
			st.add_vertex(p + off - r * w + up)
			st.add_vertex(p + off + r * w + up)
			if run > 0:
				var a := verts - 2
				st.add_index(a); st.add_index(a + 2); st.add_index(a + 1)
				st.add_index(a + 1); st.add_index(a + 2); st.add_index(a + 3)
			verts += 2
			run += 1
	var mi := MeshInstance3D.new()
	mi.name = "EdgeLines"
	mi.mesh = st.commit()
	mi.material_override = _unculled_flat(Color(0.90, 0.87, 0.72))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _centre_dashes(route: Route, lift: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := route.point_count()
	var dash_len := 3     # samples on
	var gap_len := 4      # samples off
	var w := 0.14
	var i := 0
	var verts := 0
	while i < count:
		var seg_end: int = mini(i + dash_len, count)
		var strip := 0
		for k in range(i, seg_end):
			if not _painted(route, k):
				continue
			var p := route.point(k)
			var r := route.right(k)
			var up := Vector3.UP * (0.07 + lift)
			st.set_normal(r.cross(route.forward(k)).normalized())
			st.add_vertex(p - r * w + up)
			st.add_vertex(p + r * w + up)
			if strip > 0:
				var a := verts - 2
				st.add_index(a); st.add_index(a + 2); st.add_index(a + 1)
				st.add_index(a + 1); st.add_index(a + 2); st.add_index(a + 3)
			verts += 2
			strip += 1
		i += dash_len + gap_len
	var mi := MeshInstance3D.new()
	mi.name = "CentreDashes"
	mi.mesh = st.commit()
	mi.material_override = _unculled_flat(Color(0.93, 0.90, 0.62))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
