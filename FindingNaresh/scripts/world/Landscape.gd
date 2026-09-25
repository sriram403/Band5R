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

static var EXTENT := 1600.0  ## terrain is EXTENT x EXTENT metres, centred on origin (set by the builder)
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
static var driveways: Array = []
## Gyms replace the natural ground with their own shape (flat + test slopes).
static var height_fn: Callable = Callable()
## The coastline as (x, z) points, south-going; the sea lies east of it. Empty
## means no sea (gyms).
static var coast := PackedVector2Array()
const SEA_Y := -2.0          ## sea surface
const BEACH_W := 50.0        ## sand from the waterline inland
const COAST_BLEND := 320.0   ## land eases down to the beach over this distance


static func setup(net: RoadNetwork, river_route: Route, pond_list: Array, mound_list: Array) -> void:
	network = net
	river = river_route
	ponds = pond_list
	mounds = mound_list


# --- height layers -------------------------------------------------------------

static func base_height(x: float, z: float) -> float:
	if height_fn.is_valid():
		return height_fn.call(x, z)
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


## base_height for the grid solve, with the hill/lake lists already cut down to
## those near this row and the coastline's x for this row (cx).
static func _base_fast(x: float, z: float, row_m: Array, row_p: Array, cx: float) -> float:
	var h := Route.ground_noise(x, z)
	for m in row_m:
		var c: Vector3 = m["pos"]
		var r: float = m["radius"]
		var dx := x - c.x
		var dz := z - c.z
		var d2 := dx * dx + dz * dz
		if d2 < r * r:
			h += float(m["height"]) * (1.0 - smoothstep(0.0, r, sqrt(d2)))
	for pd in row_p:
		var c: Vector3 = pd["pos"]
		var r: float = pd["radius"]
		var d := Vector2(x - c.x, z - c.z).length()
		if d < r:
			h -= float(pd["depth"]) * smoothstep(r, r * 0.55, d)
	if cx < 1e8:
		var d := cx - x
		if d < COAST_BLEND:
			var prof := SEA_Y + 0.4 + d * 0.035 if d >= 0.0 else maxf(SEA_Y - 14.0, SEA_Y + 0.4 + d * 0.12)
			var v := lerpf(prof, h, smoothstep(BEACH_W, COAST_BLEND, d))
			h = lerpf(maxf(v, prof), v, smoothstep(200.0, COAST_BLEND, d))
	for m in row_m:
		if not m.has("plateau"):
			continue
		var c: Vector3 = m["pos"]
		var pr: float = m["plateau"]
		var d := Vector2(x - c.x, z - c.z).length()
		if d < pr + PLATEAU_BLEND:
			h = lerpf(plateau_height(m), h, smoothstep(pr, pr + PLATEAU_BLEND, d))
	return h


## Level of a mound's plateau: the natural ground at its centre.
static func plateau_height(m: Dictionary, _ponds = null, _mounds = null) -> float:
	var c: Vector3 = m["pos"]
	return _raw_height(c.x, c.z)


static func _raw_height(x: float, z: float) -> float:
	return coast_shape(x, z, Route.ground_noise(x, z) + mound_raise(x, z) - pond_carve(x, z))


## Metres inland of the waterline at this z (negative out at sea; 1e9 with no
## coast).
static func coast_inland(x: float, z: float) -> float:
	if coast.size() < 2:
		return 1e9
	if z <= coast[0].y:
		return coast[0].x - x
	for i in coast.size() - 1:
		var a := coast[i]
		var b := coast[i + 1]
		if z <= b.y:
			return lerpf(a.x, b.x, (z - a.y) / (b.y - a.y)) - x
	return coast[coast.size() - 1].x - x


## Near the sea the land eases down to a sandy beach and a shelving seabed;
## never below the beach line, so no dry hollows lie under sea level.
static func coast_shape(x: float, z: float, h: float) -> float:
	var d := coast_inland(x, z)
	if d > COAST_BLEND:
		return h
	var prof: float
	if d >= 0.0:
		prof = SEA_Y + 0.4 + d * 0.035
	else:
		prof = maxf(SEA_Y - 14.0, SEA_Y + 0.4 + d * 0.12)
	var v := lerpf(prof, h, smoothstep(BEACH_W, COAST_BLEND, d))
	# the floor fades out again inland, so the edge of the blend has no step
	return lerpf(maxf(v, prof), v, smoothstep(200.0, COAST_BLEND, d))


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
static var grid_tunnel := PackedByteArray()      ## 1 where the nearest road runs in a tunnel

const TUNNEL_FLAT := 11.0    ## a tunnel's slot: flat this far from its centreline (a grid
                             ## cell clear of its walls, so no slope pokes through them)
const TUNNEL_BLEND := 16.0   ## ... and back to the hill by here (nearly sheer)

const STAMP_RADIUS := 45.0   ## how far from a road/river the grid records distance
const STAMP_STRIDE := 3      ## stamp every Nth centreline sample as a segment


static func _grid_origin() -> float:
	return -EXTENT * 0.5


## Give each pad its level: the natural ground at its centre (before roads).
## A pad close to a road takes the road's level instead, so the yard meets the
## road flush rather than fighting its cutting.
static func set_pads(list: Array) -> void:
	pads = []
	driveways = []
	for p in list:
		var c: Vector3 = p["pos"]
		var d := (p as Dictionary).duplicate()
		d["height"] = natural_height(c.x, c.z)
		if network != null:
			var near := network.nearest(c.x, c.z)
			if float(near["dist"]) < float(p["radius"]) + float(p["blend"]) + 8.0:
				d["height"] = float(near["height"])
		d["height"] += float(p.get("height_offset", 0.0))
		pads.append(d)
		if bool(p.get("driveway", false)) and network != null:
			var road := network.road("home_lane")
			var nearest := road.nearest(c.x, c.z)
			var a := road.point(int(nearest["index"]))
			var toward := Vector2(a.x - c.x, a.z - c.z).normalized()
			driveways.append({"a": Vector2(a.x, a.z),
				"b": Vector2(c.x, c.z) + toward * 4.8,
				"y0": a.y, "y1": float(d["height"])})


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
	grid_tunnel.resize(total)
	grid_road_d.fill(1e9)
	grid_river_d.fill(1e9)
	grid_gravel.fill(0)
	grid_tunnel.fill(0)
	for r in network.roads:
		_stamp(r, grid_road_d, grid_road_h, 1 if r.surface == "gravel" else 0)
	if river != null:
		_stamp(river, grid_river_d, grid_river_h, -1)

	var origin := _grid_origin()
	var gym := height_fn.is_valid()
	# The hill noise (Route.ground_noise) is mostly products of a sine in x and
	# a cosine in z: each factor is worked out once per column or row instead of
	# once per point. Same expressions in the same order (64-bit, like the
	# script's floats), so the heights are exactly what _base_fast gives.
	var s1 := PackedFloat64Array()
	var s2 := PackedFloat64Array()
	var s4 := PackedFloat64Array()
	s1.resize(n)
	s2.resize(n)
	s4.resize(n)
	for ix in n:
		var x := origin + ix * STEP
		s1[ix] = sin(x * 0.0125 + 1.7)
		s2[ix] = sin(x * 0.0281 - 2.1)
		s4[ix] = sin(x * 0.0605 + 0.3)
	# the diagonal term depends on x + z only, which on the grid is the same
	# exact number for every point with the same ix + iz
	var sd := PackedFloat64Array()
	sd.resize(2 * n - 1)
	for d in 2 * n - 1:
		var dix := mini(d, n - 1)
		sd[d] = sin(((origin + dix * STEP) + (origin + (d - dix) * STEP)) * 0.0071 + 0.6)
	# a plateau's level is the same for every point on it
	var plateau_h := {}
	for m in mounds:
		if m.has("plateau"):
			plateau_h[m] = plateau_height(m)
	for iz in n:
		var z := origin + iz * STEP
		# Only the hills, lakes and pads that reach this row are tested for
		# each of its points (the grid is 800 x 800 at 4 km).
		var row_m: Array = []
		for m in mounds:
			if absf(z - (m["pos"] as Vector3).z) < float(m["radius"]) + PLATEAU_BLEND:
				row_m.append(m)
		# the row's hills as plain numbers: no dictionary lookups per point
		var rm_x := PackedFloat64Array()
		var rm_z := PackedFloat64Array()
		var rm_r := PackedFloat64Array()
		var rm_h := PackedFloat64Array()
		var row_plateaus: Array = []
		for m in row_m:
			var mc: Vector3 = m["pos"]
			rm_x.append(mc.x)
			rm_z.append(mc.z)
			rm_r.append(float(m["radius"]))
			rm_h.append(float(m["height"]))
			if m.has("plateau"):
				row_plateaus.append(m)
		var nm := rm_x.size()
		var row_p: Array = []
		for pd in ponds:
			if absf(z - (pd["pos"] as Vector3).z) < float(pd["radius"]):
				row_p.append(pd)
		var row_pads: Array = []
		for pad in pads:
			if absf(z - (pad["pos"] as Vector3).z) < float(pad["radius"]) + float(pad["blend"]):
				row_pads.append(pad)
		var cx := coast_inland(0.0, z)
		var c1 := cos(z * 0.0104 - 0.4)
		var c2 := cos(z * 0.0233 + 1.1)
		var c4 := cos(z * 0.0518 - 1.9)
		for ix in n:
			var x := origin + ix * STEP
			var k := iz * n + ix
			var h: float
			if gym:
				h = base_height(x, z)
			else:
				# _base_fast, inlined
				h = s1[ix] * c1 * 9.0
				h += s2[ix] * c2 * 3.4
				h += sd[ix + iz] * 4.6
				h += s4[ix] * c4 * 0.9
				for j in nm:
					var dx := x - rm_x[j]
					var dz := z - rm_z[j]
					var d2 := dx * dx + dz * dz
					var r := rm_r[j]
					if d2 < r * r:
						h += rm_h[j] * (1.0 - smoothstep(0.0, r, sqrt(d2)))
				for pd in row_p:
					var c: Vector3 = pd["pos"]
					var r: float = pd["radius"]
					var d := Vector2(x - c.x, z - c.z).length()
					if d < r:
						h -= float(pd["depth"]) * smoothstep(r, r * 0.55, d)
				if cx < 1e8:
					var d := cx - x
					if d < COAST_BLEND:
						var prof := SEA_Y + 0.4 + d * 0.035 if d >= 0.0 else maxf(SEA_Y - 14.0, SEA_Y + 0.4 + d * 0.12)
						var v := lerpf(prof, h, smoothstep(BEACH_W, COAST_BLEND, d))
						h = lerpf(maxf(v, prof), v, smoothstep(200.0, COAST_BLEND, d))
				for m in row_plateaus:
					var c: Vector3 = m["pos"]
					var pr: float = m["plateau"]
					var d := Vector2(x - c.x, z - c.z).length()
					if d < pr + PLATEAU_BLEND:
						h = lerpf(plateau_h[m], h, smoothstep(pr, pr + PLATEAU_BLEND, d))
			var rd := grid_river_d[k]
			if rd < RIVER_HALF + RIVER_BANK:
				var bed := grid_river_h[k] - RIVER_DEPTH
				h = minf(h, lerpf(bed, h, smoothstep(RIVER_HALF * 0.5, RIVER_HALF + RIVER_BANK, rd)))
			var d := grid_road_d[k]
			var tun := grid_tunnel[k] == 1
			if d < (TUNNEL_BLEND if tun else BLEND_RADIUS):
				var g := lerpf(grid_road_h[k], h, smoothstep(TUNNEL_FLAT if tun else FLAT_RADIUS, TUNNEL_BLEND if tun else BLEND_RADIUS, d))
				h = lerpf(g, h, 1.0 - smoothstep(RIVER_HALF, RIVER_HALF + 6.0, rd))
			for pad in row_pads:
				var pc: Vector3 = pad["pos"]
				var pd := Vector2(x - pc.x, z - pc.z).length()
				var pr: float = pad["radius"]
				if pd < pr + float(pad["blend"]):
					h = lerpf(float(pad["height"]), h, smoothstep(pr, pr + float(pad["blend"]), pd))
			for drive in driveways:
				var a: Vector2 = drive["a"]
				var b: Vector2 = drive["b"]
				if x < minf(a.x, b.x) - 6.0 or x > maxf(a.x, b.x) + 6.0 or z < minf(a.y, b.y) - 6.0 or z > maxf(a.y, b.y) + 6.0:
					continue
				var ab := b - a
				var u := clampf((Vector2(x, z) - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				var across := (Vector2(x, z) - (a + ab * u)).length()
				if across < 5.5:
					var target_h := lerpf(float(drive["y0"]), float(drive["y1"]), u) - 0.05
					h = lerpf(target_h, h, smoothstep(2.2, 5.5, across))
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
		var tun := 1 if route.in_tunnel(i) else 0
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
						grid_tunnel[k] = tun
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


## Terrain tiles: CHUNK cells (CHUNK * STEP metres) a side. Each tile has a full
## detail mesh for near views and a coarse one (every COARSE-th vertex, with
## skirts down its edges so no gaps show against a finer neighbour) beyond
## FAR_LOD metres. Tiles are culled on their own, so a 4 km world only draws
## what is in view.
const CHUNK := 50
const COARSE := 4
const FAR_LOD := 800.0
const SKIRT := 6.0

static var _normals := PackedVector3Array()
static var _colors := PackedColorArray()


static func build_terrain() -> StaticBody3D:
	_solve_grid()
	var n := grid_n
	var origin := _grid_origin()
	var count := n * n
	_normals.resize(count)
	_colors.resize(count)
	# the colour patches' sine (per column) and cosine (per row), worked out once
	var px := PackedFloat64Array()
	px.resize(n)
	for ix in n:
		px[ix] = sin((origin + ix * STEP) * 0.031 + 2.0)
	for iz in n:
		var z := origin + iz * STEP
		var pz := cos(z * 0.027 - 1.0)
		var coast_x := coast_inland(0.0, z)     # inland distance is coast_x - x along the row
		for ix in n:
			var x := origin + ix * STEP
			var k := iz * n + ix
			var y := grid_h[k]
			var hx := grid_h[iz * n + mini(ix + 1, n - 1)] - grid_h[iz * n + maxi(ix - 1, 0)]
			var hz := grid_h[mini(iz + 1, n - 1) * n + ix] - grid_h[maxi(iz - 1, 0) * n + ix]
			var slope := Vector2(hx, hz).length() / (2.0 * STEP)
			# Analytic normal from the height field. Deriving it from triangle
			# winding gave a flat, unlit terrain, and this is exact anyway.
			_normals[k] = Vector3(-hx, 2.0 * STEP, -hz).normalized()
			var inland := coast_x - x if coast.size() >= 2 else 1e9
			_colors[k] = _ground_color(x, z, y, slope, grid_road_d[k], grid_river_d[k], grid_gravel[k] == 1, (px[ix] * pz + 1.0) * 0.5, inland)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	# The ground colours were chosen when the terrain was (wrongly) lit from
	# below; now it takes the full sun, this keeps it at the approved brightness.
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.metallic_specular = 0.06
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # winding-proof

	var body := StaticBody3D.new()
	body.name = "Terrain"
	var tiles := Node3D.new()
	tiles.name = "TerrainMesh"
	body.add_child(tiles)
	var cells := n - 1
	for cz in range(0, cells, CHUNK):
		for cx in range(0, cells, CHUNK):
			var w := mini(CHUNK, cells - cx)
			var d := mini(CHUNK, cells - cz)
			var near := MeshInstance3D.new()
			near.name = "Tile_%d_%d" % [cx / CHUNK, cz / CHUNK]
			near.mesh = _tile_mesh(cx, cz, w, d, 1, 0.0)
			near.material_override = mat
			near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			near.visibility_range_end = FAR_LOD
			tiles.add_child(near)
			var far := MeshInstance3D.new()
			far.name = near.name + "_far"
			far.mesh = _tile_mesh(cx, cz, w, d, COARSE, SKIRT)
			far.material_override = mat
			far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			far.visibility_range_begin = FAR_LOD
			tiles.add_child(far)
	_normals = PackedVector3Array()
	_colors = PackedColorArray()
	_index_cache.clear()

	# Height-map collision: one cell per grid square, far cheaper to build and
	# query than a trimesh. Its cells are 1 unit apart and centred on the
	# origin, so heights are stored /STEP and the shape scaled by STEP.
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


## Triangle lists depend only on a tile's size (and skirt), so the tiles share
## them: 256 full tiles at 4 km used to build the same list 512 times.
static var _index_cache := {}


static func _tile_indices(nx: int, nz: int, rim: PackedInt32Array) -> PackedInt32Array:
	var key := Vector3i(nx, nz, rim.size())
	if _index_cache.has(key):
		return _index_cache[key]
	var indices := PackedInt32Array()
	indices.resize((nx - 1) * (nz - 1) * 6 + maxi(rim.size() - 1, 0) * 6)
	var w := 0
	for jz in nz - 1:
		for jx in nx - 1:
			var a := jz * nx + jx
			var c := a + nx
			# wound so the faces point up (Godot's front faces are clockwise seen
			# from outside); the other way the double-sided material flipped the
			# normals and lit the ground as if the sun were underneath it
			indices[w] = a
			indices[w + 1] = a + 1
			indices[w + 2] = c
			indices[w + 3] = a + 1
			indices[w + 4] = c + 1
			indices[w + 5] = c
			w += 6
	var base := nx * nz
	for i in rim.size() - 1:
		var t0 := rim[i]
		var t1 := rim[i + 1]
		var b0 := base + i
		var b1 := base + i + 1
		indices[w] = t0
		indices[w + 1] = t1
		indices[w + 2] = b0
		indices[w + 3] = t1
		indices[w + 4] = b1
		indices[w + 5] = b0
		w += 6
	_index_cache[key] = indices
	return indices


## The tile's edge vertices in order round the rim (for the skirt).
static func _tile_rim(nx: int, nz: int) -> PackedInt32Array:
	var rim := PackedInt32Array()
	for jx in nx:
		rim.append(jx)
	for jz in range(1, nz):
		rim.append(jz * nx + nx - 1)
	for jx in range(nx - 2, -1, -1):
		rim.append((nz - 1) * nx + jx)
	for jz in range(nz - 2, -1, -1):
		rim.append(jz * nx)
	return rim


## One tile's mesh: cells [cx, cx+w) x [cz, cz+d) of the grid, every `stride`-th
## vertex, plus a skirt hanging `skirt` metres below its edges if non-zero.
static func _tile_mesh(cx: int, cz: int, w: int, d: int, stride: int, skirt: float) -> ArrayMesh:
	var n := grid_n
	var origin := _grid_origin()
	var xs: Array[int] = []
	var zs: Array[int] = []
	for i in range(0, w + 1, stride):
		xs.append(cx + i)
	if xs[xs.size() - 1] != cx + w:
		xs.append(cx + w)
	for i in range(0, d + 1, stride):
		zs.append(cz + i)
	if zs[zs.size() - 1] != cz + d:
		zs.append(cz + d)
	var nx := xs.size()
	var nz := zs.size()
	var rim := _tile_rim(nx, nz) if skirt > 0.0 else PackedInt32Array()
	var count := nx * nz
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(count + rim.size())
	normals.resize(count + rim.size())
	colors.resize(count + rim.size())
	var v := 0
	for jz in nz:
		var z := origin + zs[jz] * STEP
		var row := zs[jz] * n
		for jx in nx:
			var k := row + xs[jx]
			verts[v] = Vector3(origin + xs[jx] * STEP, grid_h[k], z)
			normals[v] = _normals[k]
			colors[v] = _colors[k]
			v += 1
	# skirt: a copy of the rim hanging `skirt` metres lower
	for r in rim:
		verts[v] = verts[r] - Vector3(0, skirt, 0)
		normals[v] = normals[r]
		colors[v] = colors[r]
		v += 1
	var indices := _tile_indices(nx, nz, rim)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


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


## The sea: one big water sheet from the coastline out past the horizon.
static func build_sea() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var far := 7000.0
	var line := PackedVector2Array([Vector2(coast[0].x, -far)])
	line.append_array(coast)
	line.append(Vector2(coast[coast.size() - 1].x, far))
	for p in line:
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(p.x - 40.0, SEA_Y, p.y))
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(far, SEA_Y, p.y))
	_strip_indices(st, line.size(), false)
	var mi := MeshInstance3D.new()
	mi.name = "Sea"
	mi.mesh = st.commit()
	var m := ToonMat.water(Color(0.24, 0.50, 0.66, 0.9))
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


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

## patch / inland: pass them in when already known (the terrain works them out
## per row and column); NAN works them out here.
static func _ground_color(x: float, z: float, y: float, slope: float, dist_to_road: float,
		dist_to_river: float, gravel: bool, patch := NAN, inland := NAN) -> Color:
	if is_nan(patch):
		patch = (sin(x * 0.031 + 2.0) * cos(z * 0.027 - 1.0) + 1.0) * 0.5
	var c := GRASS_DARK.lerp(GRASS, patch)
	# higher ground dries out
	c = c.lerp(DRY, clampf((y - 6.0) / 18.0, 0.0, 0.45))
	# steep faces show rock
	c = c.lerp(ROCK, clampf((slope - 0.55) / 0.5, 0.0, 0.85))
	# the beach: sand from the waterline up, wet and darker at the water
	if is_nan(inland):
		inland = coast_inland(x, z)
	if inland < BEACH_W + 30.0:
		c = c.lerp(SAND.lightened(0.12), 1.0 - smoothstep(BEACH_W - 10.0, BEACH_W + 30.0, inland))
		c = c.lerp(SAND.darkened(0.18), 1.0 - smoothstep(-2.0, 6.0, inland))
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
