class_name MapState
extends Node

## The shared paper map: what the players have discovered and the stamps
## they have placed. One instance for the session; both players' maps draw
## from it, and it is what the save system will serialise.
##
## The map starts almost blank. Features appear as the players travel near
## them (roads chunk by chunk, landmarks from further off since they are seen
## from a distance), and reading an info board sketches in a whole area.

signal changed

const STAMP_TYPES := ["fuel", "danger", "puzzle", "shortcut", "unexplored"]
const ROAD_CHUNK := 12            ## centreline samples per revealable road piece
const ROAD_REVEAL_M := 55.0       ## reveal a road piece when a player is this close
const LANDMARK_REVEAL_M := 160.0  ## landmarks are big; you notice them from further off
const BOARD_REVEAL_M := 600.0     ## an info board sketches in everything this close to it

## World rectangle the paper covers (x0, z0, x1, z1).
const BOUNDS := Rect2(-2000, -2000, 4000, 4000)

var roads: Array = []        ## [{name, surface, pts: PackedVector2Array, chunks: Array[bool]}]
var river_pts := PackedVector2Array()
var river_chunks: Array = []
var lakes: Array = []        ## [{pos: Vector2, r: float, revealed: bool}]
var landmarks: Array = []    ## [{id, label, icon, pos: Vector2, revealed: bool}]
var stamps: Array = []       ## [{type: String, pos: Vector2}]
var _tick := 0.0


func setup(b: LevelBuilder) -> void:
	for r in b.network.roads:
		var pts := PackedVector2Array()
		for p in r.points:
			pts.append(Vector2(p.x, p.z))
		if r.closed and pts.size() > 0:
			pts.append(pts[0])
		var chunks := []
		chunks.resize(int(ceil(pts.size() / float(ROAD_CHUNK))))
		chunks.fill(false)
		roads.append({"name": r.name, "surface": r.surface, "pts": pts, "chunks": chunks})
	for p in b.river.points:
		river_pts.append(Vector2(p.x, p.z))
	river_chunks.resize(int(ceil(river_pts.size() / float(ROAD_CHUNK))))
	river_chunks.fill(false)
	for pond in ([] if b is GymBuilder else LevelBuilder.PONDS):
		var c: Vector3 = pond["pos"]
		lakes.append({"pos": Vector2(c.x, c.z), "r": Landscape.pond_water_radius(float(pond["radius"])), "revealed": false})

	var marks := [
		["homestead", "Home", "house"], ["windmill", "Windmill", "windmill"], ["dock", "Mirror Lake", "dock"],
		["billboard", "Billboard", "sign"], ["barn", "Red barn", "barn"], ["lookout", "Lookout", "tower"],
		["wreck", "Wreck", "wreck"], ["gas_station", "Last Fuel", "fuel"], ["facility", "Water works", "tower"],
		["radio_mast", "Radio mast", "mast"], ["bridge", "Old bridge", "bridge"], ["roses", "Bessi", "roses"],
		["p2_home", "P2's home", "house"], ["town_fuel", "Town fuel", "fuel"], ["coast_tower", "Coast tower", "tower"],
		["beach", "Bessi beach", "dock"], ["fishing_village", "Fishing village", "house"],
		["salt_pans", "Salt pans", "sign"], ["estuary_bridge", "Estuary bridge", "span"],
		["tunnel", "Rail tunnel", "sign"], ["naresh_home", "Naresh's home", "house"],
		["end_tower", "Watchtower", "tower"],
	]
	for m in marks:
		if b.poi.has(m[0]):
			var p: Vector3 = b.poi[m[0]]
			landmarks.append({"id": m[0], "label": m[1], "icon": m[2], "pos": Vector2(p.x, p.z), "revealed": false})

	# What the players know leaving home: the homestead, the lane up to the
	# windmill, and that the windmill is where the roads split.
	if b is GymBuilder:
		return
	reveal_around(Vector2(b.poi["homestead"].x, b.poi["homestead"].z), 90.0)
	_reveal_road("home_lane")
	_reveal_landmark("windmill")


# --- discovery -----------------------------------------------------------------

## Called with everyone's positions a few times a second.
func explore(positions: Array) -> void:
	var any := false
	for pos in positions:
		var p := Vector2(pos.x, pos.z)
		for r in roads:
			var pts: PackedVector2Array = r["pts"]
			var chunks: Array = r["chunks"]
			for c in chunks.size():
				if chunks[c]:
					continue
				var mid := pts[mini(c * ROAD_CHUNK + ROAD_CHUNK / 2, pts.size() - 1)]
				if mid.distance_to(p) < ROAD_REVEAL_M + ROAD_CHUNK:
					chunks[c] = true
					any = true
		for c in river_chunks.size():
			if not river_chunks[c] and river_pts[mini(c * ROAD_CHUNK, river_pts.size() - 1)].distance_to(p) < 90.0:
				river_chunks[c] = true
				any = true
		for l in lakes:
			if not l["revealed"] and (l["pos"] as Vector2).distance_to(p) < float(l["r"]) + 80.0:
				l["revealed"] = true
				any = true
		for m in landmarks:
			if not m["revealed"] and (m["pos"] as Vector2).distance_to(p) < LANDMARK_REVEAL_M:
				m["revealed"] = true
				any = true
	if any:
		changed.emit()


## Sketch in everything within `radius` of a point (info boards).
func reveal_around(p: Vector2, radius: float) -> void:
	for r in roads:
		var pts: PackedVector2Array = r["pts"]
		var chunks: Array = r["chunks"]
		for c in chunks.size():
			if pts[mini(c * ROAD_CHUNK + ROAD_CHUNK / 2, pts.size() - 1)].distance_to(p) < radius:
				chunks[c] = true
	for c in river_chunks.size():
		if river_pts[mini(c * ROAD_CHUNK, river_pts.size() - 1)].distance_to(p) < radius:
			river_chunks[c] = true
	for l in lakes:
		if (l["pos"] as Vector2).distance_to(p) < radius:
			l["revealed"] = true
	for m in landmarks:
		if (m["pos"] as Vector2).distance_to(p) < radius:
			m["revealed"] = true
	changed.emit()


## The miller's map from the windmill: both roads from J1 to Last Fuel and
## what is along them.
func reveal_valley() -> void:
	_reveal_road("valley_road")
	_reveal_road("ridge_track")
	for id in ["dock", "billboard", "barn", "lookout", "wreck", "gas_station"]:
		_reveal_landmark(id)
	for l in lakes:
		l["revealed"] = true
	changed.emit()


func _reveal_road(road_name: String) -> void:
	for r in roads:
		if r["name"] == road_name:
			(r["chunks"] as Array).fill(true)


func _reveal_landmark(id: String) -> void:
	for m in landmarks:
		if m["id"] == id:
			m["revealed"] = true


func is_revealed(id: String) -> bool:
	for m in landmarks:
		if m["id"] == id:
			return m["revealed"]
	return false


func revealed_fraction() -> float:
	var total := 0
	var seen := 0
	for r in roads:
		for c in r["chunks"]:
			total += 1
			seen += 1 if c else 0
	return float(seen) / maxf(1.0, total)


# --- stamps --------------------------------------------------------------------

func add_stamp(type: String, world_xz: Vector2) -> void:
	stamps.append({"type": type, "pos": world_xz})
	changed.emit()


## Remove the stamp nearest to a point, if one is within `radius` metres.
func remove_stamp_near(world_xz: Vector2, radius: float) -> bool:
	var best := -1
	var best_d := radius
	for i in stamps.size():
		var d := (stamps[i]["pos"] as Vector2).distance_to(world_xz)
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return false
	stamps.remove_at(best)
	changed.emit()
	return true


# --- save support ----------------------------------------------------------------

func to_dict() -> Dictionary:
	var rd := {}
	for r in roads:
		rd[r["name"]] = (r["chunks"] as Array).duplicate()
	var lm := {}
	for m in landmarks:
		lm[m["id"]] = m["revealed"]
	var lk := []
	for l in lakes:
		lk.append(l["revealed"])
	var st := []
	for s in stamps:
		st.append({"type": s["type"], "x": (s["pos"] as Vector2).x, "z": (s["pos"] as Vector2).y})
	return {"roads": rd, "river": river_chunks.duplicate(), "lakes": lk, "landmarks": lm, "stamps": st}


func from_dict(d: Dictionary) -> void:
	# A save from before a road was re-laid has a different number of pieces
	# for it; that road then starts undiscovered rather than half-drawn wrong.
	for r in roads:
		var saved: Array = d.get("roads", {}).get(r["name"], [])
		if saved.size() == (r["chunks"] as Array).size():
			r["chunks"] = saved.duplicate()
	var river: Array = d.get("river", [])
	if river.size() == river_chunks.size():
		river_chunks = river.duplicate()
	var lk: Array = d.get("lakes", [])
	for i in mini(lk.size(), lakes.size()):
		lakes[i]["revealed"] = lk[i]
	for m in landmarks:
		m["revealed"] = d.get("landmarks", {}).get(m["id"], m["revealed"])
	stamps.clear()
	for s in d.get("stamps", []):
		stamps.append({"type": s["type"], "pos": Vector2(float(s["x"]), float(s["z"]))})
	changed.emit()
