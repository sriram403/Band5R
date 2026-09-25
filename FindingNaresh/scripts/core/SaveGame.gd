class_name SaveGame
extends RefCounted

## Manual saves, written from the van's travel journal (one Memory Rose each).
## A save is one JSON file per slot under user:// (MPG/appdata on this machine),
## holding everything needed to put the world back: players, the van and its
## cargo, loose items, the paper map, story progress, fragments and puzzles.
##
## Loading reloads the scene and applies the file on top of a fresh world, so
## nothing from the abandoned session can leak into the restored one.

const DIR := "user://saves"
const SLOTS := 3
const VERSION := 1

## Set before reloading the scene; Boot applies it once the world is built.
static var pending_load := -1


static func path(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot + 1]


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(path(slot), FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## One line for menus: "Slot 1 - Pump House Road - get coolant - 14:02".
static func summary(slot: int) -> String:
	var d := read(slot)
	if d.is_empty():
		return "Slot %d  -  empty" % (slot + 1)
	var m: Dictionary = d.get("meta", {})
	return "Slot %d  -  %s  -  %s  -  %s" % [slot + 1, m.get("place", "?"), m.get("objective", "?"), m.get("saved_at", "?")]


static func write(boot: Node, slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(collect(boot), "  "))
	return true


# --- gather ----------------------------------------------------------------------

static func collect(boot: Node) -> Dictionary:
	var c: Camper = boot.camper
	var players := []
	for p in boot.players:
		players.append({"pos": _v(p.global_position), "yaw": p.yaw, "pitch": p.pitch,
			"seat": p.seat_role if p.seat != null else ""})
	var stowed := {}
	for i in c.storage_slots.size():
		var it: Carryable = c.stowed_item(c.storage_slots[i])
		if it != null:
			stowed[it.name] = i
	var items := []
	for n in boot.get_tree().get_nodes_in_group("carryable"):
		var it := n as Carryable
		if it == null or it.is_queued_for_deletion():
			continue
		var e := {"name": String(it.name), "kind": it.kind, "xf": _xf(it.global_transform)}
		if "litres" in it:
			e["litres"] = it.litres
		if stowed.has(it.name):
			e["slot"] = stowed[it.name]
		items.append(e)
	var station := boot.get_tree().get_first_node_in_group("cooling_station") as CoolingStation
	return {
		"version": VERSION,
		"meta": {
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"objective": boot.story.objective_text(),
			"place": nearest_place(boot, c.global_position),
		},
		"players": players,
		"camper": {
			"xf": _xf(c.global_transform), "fuel": c.fuel, "temp": c.temp, "battery": c.battery,
			"odometer": c.odometer, "leak": c.coolant_leak, "lockout": c.heat_lockout,
			"headlights": c.headlights_on, "coolant_added": c.coolant_added, "coolant": c.coolant,
			"park_brake": c.parking_brake, "tyre_flat": c.tyre_flat,
			"tyre_stage": c.tyre_stage, "tyre_work": c.tyre_work,
			"spare_available": c.spare_available,
		},
		"items": items,
		"map": boot.map_state.to_dict(),
		"story": boot.story.to_dict(),
		"station": station.to_dict() if station else {},
	}


const PLACE_NAMES := {"homestead": "Homestead", "town_fuel": "Town", "p2_home": "P2's house",
	"windmill": "Windmill junction", "dock": "Mirror Lake", "barn": "Red barn", "lookout": "Pine Ridge",
	"wreck": "The wreck", "gas_station": "Last Fuel", "facility": "Water works", "bridge": "Old bridge",
	"ghat_pass": "Ghat pass", "coast_tower": "Coast watchtower", "beach": "Bessi beach", "roses": "Bessi",
	"fishing_village": "Fishing village", "salt_pans": "Salt pans", "estuary_bridge": "Estuary bridge",
	"tunnel": "Rail tunnel", "radio_mast": "Radio Hill", "naresh_home": "Naresh's home",
	"end_tower": "Old watchtower"}


## "Mirror Lake", "near Last Fuel" or "on the road", for save slot labels.
static func nearest_place(boot: Node, at: Vector3) -> String:
	var best := ""
	var best_d := 1e9
	for k in PLACE_NAMES.keys():
		if boot.builder.poi.has(k):
			var p: Vector3 = boot.builder.poi[k]
			var d := Vector2(p.x - at.x, p.z - at.z).length()
			if d < best_d:
				best_d = d
				best = PLACE_NAMES[k]
	if best_d < 250.0:
		return best
	return "near " + best if best_d < 700.0 else "on the road"


# --- restore ---------------------------------------------------------------------

static func apply(boot: Node, d: Dictionary) -> void:
	var world: Node3D = boot.world
	var c: Camper = boot.camper
	var cd: Dictionary = d.get("camper", {})
	c.freeze = false
	c.global_transform = _to_xf(cd.get("xf", []), c.global_transform)
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.fuel = float(cd.get("fuel", c.fuel))
	c.temp = float(cd.get("temp", c.temp))
	c.battery = float(cd.get("battery", c.battery))
	c.odometer = float(cd.get("odometer", 0.0))
	c.coolant_leak = bool(cd.get("leak", false))
	c.heat_lockout = bool(cd.get("lockout", false))
	c.coolant_added = float(cd.get("coolant_added", 0.0))
	c.coolant = float(cd.get("coolant", 1.0))
	c.engine_on = false
	c.parking_brake = bool(cd.get("park_brake", true))
	c.tyre_flat = bool(cd.get("tyre_flat", false))
	c.tyre_stage = int(cd.get("tyre_stage", 0))
	c.tyre_work = float(cd.get("tyre_work", 0.0))
	c.spare_available = bool(cd.get("spare_available", true))
	c.refresh_tyre_visuals()
	c.set_headlights(bool(cd.get("headlights", false)))
	c.reset_physics_interpolation()

	# story first: other systems read from it (collected fragments, flags)
	boot.story.from_dict(d.get("story", {}))
	boot.map_state.from_dict(d.get("map", {}))
	var station := boot.get_tree().get_first_node_in_group("cooling_station") as CoolingStation
	if station and d.has("station"):
		station.from_dict(d["station"], boot.story.collected)

	# items: match by name, recreate anything made at runtime, drop the rest
	var saved := {}
	for e in d.get("items", []):
		saved[e["name"]] = e
	for n in boot.get_tree().get_nodes_in_group("carryable"):
		if not saved.has(String(n.name)):
			n.queue_free()
	for e in d.get("items", []):
		var it := world.find_child(e["name"], true, false) as Carryable
		if it == null:
			it = _make_item(e)
			if it == null:
				continue
			it.name = e["name"]
			world.add_child(it)
		if it.stowed_in != null:
			it.unstow()
		if e.has("litres") and "litres" in it:
			it.litres = float(e["litres"])
			if it.has_method("_update_mass"):
				it._update_mass()
			it._refresh_prompt()
		it.global_transform = _to_xf(e.get("xf", []), it.global_transform)
		it.linear_velocity = Vector3.ZERO
		it.reset_physics_interpolation()
		if e.has("slot"):
			it.stow(c.storage_slots[int(e["slot"])])

	# fragments already picked up are gone
	for f in boot.get_tree().get_nodes_in_group("memory_fragment"):
		if f.fragment_id in boot.story.collected:
			f.queue_free()

	# players: stand where they were; anyone seated goes back to their seat
	var pd: Array = d.get("players", [])
	for i in mini(pd.size(), boot.players.size()):
		var p: PlayerRig = boot.players[i]
		var e: Dictionary = pd[i]
		if p.seat != null:
			p.exit_vehicle()
		p.global_position = _to_v(e.get("pos", []), p.global_position)
		p.yaw = float(e.get("yaw", 0.0))
		p.pitch = float(e.get("pitch", 0.0))
		p.velocity = Vector3.ZERO
		p.reset_physics_interpolation()
		var role: String = e.get("seat", "")
		if role != "":
			p.enter_seat(c, c.seat_nodes[role], role)


static func _make_item(e: Dictionary) -> Carryable:
	match e.get("kind", ""):
		"fuel_can":
			return FuelCan.create(float(e.get("litres", FuelCan.CAPACITY)))
		"coolant":
			var j := CoolantJug.new()
			j.litres = float(e.get("litres", CoolantJug.CAPACITY))
			return j
		"crate":
			return Crate.new()
		"spare_wheel":
			return SpareWheel.new()
	return null


# --- (de)serialising transforms --------------------------------------------------------

static func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _to_v(a: Array, fallback: Vector3) -> Vector3:
	return Vector3(a[0], a[1], a[2]) if a.size() == 3 else fallback


static func _xf(t: Transform3D) -> Array:
	var q := t.basis.get_rotation_quaternion()
	return [t.origin.x, t.origin.y, t.origin.z, q.x, q.y, q.z, q.w]


static func _to_xf(a: Array, fallback: Transform3D) -> Transform3D:
	if a.size() != 7:
		return fallback
	return Transform3D(Basis(Quaternion(a[3], a[4], a[5], a[6])), Vector3(a[0], a[1], a[2]))
