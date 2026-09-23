class_name Route
extends RefCounted

## One road (or river) centreline.
##
## Control points are authored by hand in XZ. Elevation is sampled from a height
## function (the landscape without roads) and then smoothed along the spline, so
## the road sits naturally in the land with drivable grades. Open routes can pin
## their end heights so they meet other roads cleanly at junctions.
##
## Also provides a cheap nearest-point query (spatial hash).

const SAMPLE_SPACING := 2.0     ## metres between centreline samples
const CELL := 20.0              ## spatial hash cell size
const SMOOTH_PASSES := 26       ## elevation smoothing along the spline

var name := ""
var control: PackedVector2Array
var closed := true
var surface := "asphalt"        ## "asphalt" | "gravel" | "water"

var points: PackedVector3Array = PackedVector3Array()   ## sampled centreline
var forwards: PackedVector3Array = PackedVector3Array() ## unit tangent per sample
var total_length := 0.0

var _hash: Dictionary = {}


## height_fn(x, z) -> float gives the ground to follow; defaults to ground_noise.
## pin_start / pin_end (open routes only): NAN leaves that end free.
func _init(control_points: PackedVector2Array, is_closed := true, height_fn: Callable = Callable(),
		pin_start := NAN, pin_end := NAN, smooth_passes := SMOOTH_PASSES) -> void:
	control = control_points
	closed = is_closed
	if control.size() >= 2:
		_sample()
		_derive_elevation(height_fn if height_fn.is_valid() else Route.ground_noise, pin_start, pin_end, smooth_passes)
		_build_hash()


## Build a route straight from already-sampled 3D points (used to chain several
## roads into one path, e.g. for the auto-driver).
static func from_points(pts: PackedVector3Array, is_closed := false) -> Route:
	var r := Route.new(PackedVector2Array(), is_closed)
	r.points = pts
	for i in pts.size():
		r.forwards.append(r._tangent(i))
	r.total_length = pts.size() * SAMPLE_SPACING
	r._build_hash()
	return r


## Rolling-hill height field. Deterministic, no noise texture needed.
static func ground_noise(x: float, z: float) -> float:
	var h := 0.0
	h += sin(x * 0.0125 + 1.7) * cos(z * 0.0104 - 0.4) * 9.0
	h += sin(x * 0.0281 - 2.1) * cos(z * 0.0233 + 1.1) * 3.4
	h += sin((x + z) * 0.0071 + 0.6) * 4.6
	h += sin(x * 0.0605 + 0.3) * cos(z * 0.0518 - 1.9) * 0.9
	return h


func point_count() -> int:
	return points.size()


## Wraps on closed routes, clamps on open ones.
func point(i: int) -> Vector3:
	return points[_idx(i)]


func forward(i: int) -> Vector3:
	return forwards[_idx(i)]


## Right-hand side vector of the road at sample i (flat, ignores grade).
func right(i: int) -> Vector3:
	var f := forward(i)
	return Vector3(-f.z, 0.0, f.x).normalized()


func start_point() -> Vector3:
	return points[0]


func end_point() -> Vector3:
	return points[points.size() - 1]


## Index of the sample closest to the given distance along the route.
func index_at_distance(d: float) -> int:
	return _idx(int(round(d / SAMPLE_SPACING)))


## Nearest centreline info for a world XZ position.
## Returns { dist: float, height: float, index: int }. dist is 1e9 if the query
## is further away than the hash search radius (~40 m).
func nearest(x: float, z: float) -> Dictionary:
	var best := 1e18
	var best_i := -1
	var cx := int(floor(x / CELL))
	var cz := int(floor(z / CELL))
	for ox in range(-2, 3):
		for oz in range(-2, 3):
			var bucket = _hash.get(Vector2i(cx + ox, cz + oz))
			if bucket == null:
				continue
			for i in bucket:
				var p: Vector3 = points[i]
				var dx := p.x - x
				var dz := p.z - z
				var d2 := dx * dx + dz * dz
				if d2 < best:
					best = d2
					best_i = i
	if best_i < 0:
		return {"dist": 1e9, "height": 0.0, "index": -1}
	return {"dist": sqrt(best), "height": points[best_i].y, "index": best_i}


# --- construction --------------------------------------------------------------

func _idx(i: int) -> int:
	if closed:
		return wrapi(i, 0, points.size())
	return clampi(i, 0, points.size() - 1)


func _tangent(i: int) -> Vector3:
	var a := point(i - 1)
	var b := point(i + 1)
	var f := b - a
	if f.length() < 0.001:
		return Vector3.FORWARD
	return f.normalized()


func _sample() -> void:
	var n := control.size()
	var segs := n if closed else n - 1
	for i in range(segs):
		# open routes mirror their end points so the spline reaches them
		var p0 := control[wrapi(i - 1, 0, n)] if (closed or i > 0) else control[0] * 2.0 - control[1]
		var p1 := control[i]
		var p2 := control[wrapi(i + 1, 0, n)]
		var p3 := control[wrapi(i + 2, 0, n)] if (closed or i + 2 < n) else control[n - 1] * 2.0 - control[n - 2]
		var seg_len := p1.distance_to(p2)
		var steps := maxi(2, int(round(seg_len / SAMPLE_SPACING)))
		for s in steps:
			var t := float(s) / float(steps)
			var c := _catmull(p0, p1, p2, p3, t)
			points.append(Vector3(c.x, 0.0, c.y))
	if not closed:
		points.append(Vector3(control[n - 1].x, 0.0, control[n - 1].y))
	for i in points.size():
		var f := _tangent(i)
		f.y = 0.0
		forwards.append(f.normalized())
	total_length = points.size() * SAMPLE_SPACING


func _derive_elevation(height_fn: Callable, pin_start: float, pin_end: float, passes: int) -> void:
	var n := points.size()
	var h := PackedFloat32Array()
	h.resize(n)
	for i in n:
		h[i] = height_fn.call(points[i].x, points[i].z)
	var pinned_start := not closed and not is_nan(pin_start)
	var pinned_end := not closed and not is_nan(pin_end)
	# Box blur along the line: turns the raw ground into gentle, drivable grades.
	for _pass in passes:
		if pinned_start:
			h[0] = pin_start
		if pinned_end:
			h[n - 1] = pin_end
		var src := h.duplicate()
		for i in n:
			var a := src[_idx(i - 1)]
			var b := src[i]
			var c := src[_idx(i + 1)]
			h[i] = (a + b * 2.0 + c) * 0.25
	if pinned_start:
		h[0] = pin_start
	if pinned_end:
		h[n - 1] = pin_end
	for i in n:
		points[i] = Vector3(points[i].x, h[i], points[i].z)
	# recompute tangents with grade included
	for i in n:
		forwards[i] = _tangent(i)


## Force the height profile to only ever go down along the route (rivers).
func make_monotonic_descending() -> void:
	for i in range(1, points.size()):
		if points[i].y > points[i - 1].y:
			points[i] = Vector3(points[i].x, points[i - 1].y, points[i].z)
	for i in points.size():
		forwards[i] = _tangent(i)


func _build_hash() -> void:
	_hash.clear()
	for i in points.size():
		var key := Vector2i(int(floor(points[i].x / CELL)), int(floor(points[i].z / CELL)))
		if not _hash.has(key):
			_hash[key] = PackedInt32Array()
		var bucket: PackedInt32Array = _hash[key]
		bucket.append(i)
		_hash[key] = bucket


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
