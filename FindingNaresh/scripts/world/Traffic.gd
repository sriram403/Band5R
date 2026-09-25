class_name Traffic
extends Node

## All the ordinary traffic, from one table (`LevelLayout.TRAFFIC`): how many
## cars patrol which stretch of which road. Thinning out towards J2 and none
## after it is that table, not code (design/WAY_OUT.md, "Traffic and mood").
## `density` (0..1, the mood curve) takes cars off each stretch: with n cars,
## only the first round(n * density) drive, the rest are put away.

var entries: Array = []          ## {"car": TrafficCar, "n": int, "k": int}
var density := 1.0:
	set(v):
		density = clampf(v, 0.0, 1.0)
		_apply()


## Table rows: [road, first sample, last sample (negative = that many from
## the road's end), cars, optional node name pattern with one %d].
static func build(world: Node3D, network: RoadNetwork, table: Array) -> Traffic:
	var t := Traffic.new()
	t.name = "Traffic"
	world.add_child(t)
	for row in table:
		var r: Route = network.by_name.get(String(row[0]))
		if r == null:
			continue
		var a: int = row[1]
		var b: int = row[2] if int(row[2]) > 0 else r.point_count() - 2 + int(row[2])
		var n: int = row[3]
		for k in n:
			var car := TrafficCar.new()
			car.name = (String(row[4]) % k) if row.size() > 4 else "Car_%s_%d_%d" % [row[0], a, k]
			# spread along the stretch, alternate directions
			var start := a + int(float(b - a) * (float(k) + 0.5) / float(n))
			car.configure(r, a, b, start, 1 if k % 2 == 0 else -1)
			world.add_child(car)
			t.entries.append({"car": car, "n": n, "k": k})
	return t


## How many cars are out on `road_name` right now.
func count_on(road_name: String) -> int:
	var c := 0
	for e in entries:
		var car: TrafficCar = e["car"]
		if car.active and car.route != null and car.route.name == road_name:
			c += 1
	return c


func _apply() -> void:
	for e in entries:
		(e["car"] as TrafficCar).set_active(int(e["k"]) < roundi(float(e["n"]) * density))
