class_name Route
extends RefCounted

## The handcrafted road centreline.
##
## Control points are authored by hand in XZ. Elevation is derived from the same
## rolling-hill field the terrain uses and then smoothed along the spline, so the
## road always sits naturally in the landscape with drivable grades.
##
## Also provides a cheap nearest-point query (spatial hash) used by the terrain
## flattening and by prop scattering.

const SAMPLE_SPACING := 2.0     ## metres between centreline samples
const CELL := 20.0              ## spatial hash cell size
const SMOOTH_PASSES := 26       ## elevation smoothing along the spline

var control: PackedVector2Array
var closed := true

var points: PackedVector3Array = PackedVector3Array()   ## sampled centreline
var forwards: PackedVector3Array = PackedVector3Array() ## unit tangent per sample
var total_length := 0.0

var _hash: Dictionary = {}


func _init(control_points: PackedVector2Array, is_closed := true) -> void:
	control = control_points
	closed = is_closed
	_sample()
	_derive_elevation()
	_build_hash()


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


func point(i: int) -> Vector3:
	return points[wrapi(i, 0, points.size())]


func forward(i: int) -> Vector3:
	return forwards[wrapi(i, 0, forwards.size())]


## Right-hand side vector of the road at sample i (flat, ignores grade).
func right(i: int) -> Vector3:
	var f := forward(i)
	return Vector3(-f.z, 0.0, f.x).normalized()


## Index of the sample closest to the given distance along the loop.
func index_at_distance(d: float) -> int:
	return wrapi(int(round(d / SAMPLE_SPACING)), 0, points.size())


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

func _sample() -> void:
	var n := control.size()
	for i in range(n if closed else n - 1):
		var p0 := control[wrapi(i - 1, 0, n)]
		var p1 := control[i]
		var p2 := control[wrapi(i + 1, 0, n)]
		var p3 := control[wrapi(i + 2, 0, n)]
		var seg_len := p1.distance_to(p2)
		var steps := maxi(2, int(round(seg_len / SAMPLE_SPACING)))
		for s in steps:
			var t := float(s) / float(steps)
			var c := _catmull(p0, p1, p2, p3, t)
			points.append(Vector3(c.x, 0.0, c.y))
	# tangents
	for i in points.size():
		var a := points[wrapi(i - 1, 0, points.size())]
		var b := points[wrapi(i + 1, 0, points.size())]
		var f := (b - a)
		f.y = 0.0
		forwards.append(f.normalized())
	total_length = points.size() * SAMPLE_SPACING


func _derive_elevation() -> void:
	var h := PackedFloat32Array()
	h.resize(points.size())
	for i in points.size():
		h[i] = ground_noise(points[i].x, points[i].z)
	# Circular box blur: turns the raw hill field into gentle, drivable grades.
	for _pass in SMOOTH_PASSES:
		var src := h.duplicate()
		for i in h.size():
			var a := src[wrapi(i - 1, 0, src.size())]
			var b := src[i]
			var c := src[wrapi(i + 1, 0, src.size())]
			h[i] = (a + b * 2.0 + c) * 0.25
	for i in points.size():
		points[i] = Vector3(points[i].x, h[i], points[i].z)
	# recompute tangents with grade included
	for i in points.size():
		var a := points[wrapi(i - 1, 0, points.size())]
		var b := points[wrapi(i + 1, 0, points.size())]
		forwards[i] = (b - a).normalized()


func _build_hash() -> void:
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
