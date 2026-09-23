class_name RoadNetwork
extends RefCounted

## All roads in the world. Answers "which road is nearest, and how high is it
## there" for terrain shaping, prop placement and the auto-driver.

var roads: Array[Route] = []
var by_name: Dictionary = {}


func add(r: Route, road_name: String, surface := "asphalt") -> Route:
	r.name = road_name
	r.surface = surface
	roads.append(r)
	by_name[road_name] = r
	return r


func road(road_name: String) -> Route:
	return by_name[road_name]


## Nearest centreline over every road.
## Returns { dist, height, index, road } (road is null and dist 1e9 when no road
## is within the hash search radius).
func nearest(x: float, z: float) -> Dictionary:
	var best := {"dist": 1e9, "height": 0.0, "index": -1, "road": null}
	for r in roads:
		var n := r.nearest(x, z)
		if float(n["dist"]) < float(best["dist"]):
			best = n
			best["road"] = r
	return best


## Chain several roads into one drivable path, e.g. home -> ridge -> facility.
## Each entry is [road_name, reversed]. Consecutive roads must share an end.
func chain(parts: Array) -> Route:
	var pts := PackedVector3Array()
	for part in parts:
		var r := road(part[0])
		var seq := r.points.duplicate()
		if part.size() > 1 and part[1]:
			seq.reverse()
		for p in seq:
			if pts.size() > 0 and pts[pts.size() - 1].distance_to(p) < 1.0:
				continue
			pts.append(p)
	return Route.from_points(pts, false)
