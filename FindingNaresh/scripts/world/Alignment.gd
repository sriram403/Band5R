class_name Alignment
extends RefCounted

## "Where was this photo taken?" (design/BESSI.md, W8): pairs of landmarks
## that line up, a near one in front of a far one, as seen from one spot.
## Each pair is a line on the ground (through the two, flattened); you stand
## where the lines cross. `off(pos)` is how far `pos` is from the worst line,
## in metres; within TOLERANCE of every line you are on the spot.

const TOLERANCE := 2.0            ## m; fixed in the photo gym (DESIGN.md 6.1)

var pairs: Array = []             ## [[near: Vector3, far: Vector3], ...]


func add_pair(near: Vector3, far: Vector3) -> Alignment:
	pairs.append([near, far])
	return self


## Metres from `pos` to the furthest line (0 on the spot itself). Only the
## side facing the landmarks counts: behind the far one the lines go on, but
## the near thing would be behind you.
func off(pos: Vector3) -> float:
	var worst := 0.0
	for pr in pairs:
		var a := Vector2((pr[0] as Vector3).x, (pr[0] as Vector3).z)
		var b := Vector2((pr[1] as Vector3).x, (pr[1] as Vector3).z)
		var p := Vector2(pos.x, pos.z)
		var d := (b - a).normalized()
		var along := (p - a).dot(d)
		if along > 0.0:
			worst = maxf(worst, INF)     # past the near landmark: not in front of it
			continue
		var perp := absf((p - a).cross(d))
		worst = maxf(worst, perp)
	return worst


func aligned(pos: Vector3, tol := TOLERANCE) -> bool:
	return off(pos) <= tol


## Where the first two lines cross (on the ground, y from the first pair).
func spot() -> Vector3:
	if pairs.size() < 2:
		return Vector3.ZERO
	var a1 := Vector2(pairs[0][0].x, pairs[0][0].z)
	var d1 := (Vector2(pairs[0][1].x, pairs[0][1].z) - a1).normalized()
	var a2 := Vector2(pairs[1][0].x, pairs[1][0].z)
	var d2 := (Vector2(pairs[1][1].x, pairs[1][1].z) - a2).normalized()
	var den := d1.cross(d2)
	if absf(den) < 0.0001:
		return Vector3(a1.x, pairs[0][0].y, a1.y)
	var t := (a2 - a1).cross(d2) / den
	var p := a1 + d1 * t
	return Vector3(p.x, pairs[0][0].y, p.y)


## How far apart the near and far landmark of each pair look from `eye`, in
## degrees sideways (tests and tuning: 0 on the spot).
func apart_deg(eye: Vector3) -> Array:
	var out: Array = []
	for pr in pairs:
		var n: Vector3 = pr[0]
		var f: Vector3 = pr[1]
		var yn := atan2(n.x - eye.x, n.z - eye.z)
		var yf := atan2(f.x - eye.x, f.z - eye.z)
		out.append(rad_to_deg(absf(angle_difference(yn, yf))))
	return out
