class_name Story
extends Node

## Shared story progress: the current objective, its hint, and the one-off
## story beats (letters, old texts from Naresh) that fire as the players
## travel. One instance per session; both HUDs read from it, and `flags` is
## what the save system stores.

signal objective_changed

var boot: Node
var flags: Dictionary = {}          ## story facts: "letter_read", "text_j1", ...
var fragments := 0                  ## Memory Fragments held (3 make a Memory Rose)
var collected: Array = []           ## ids of fragments already picked up
var roses_spent := 0                ## Memory Roses used up by saving
var index := 0                      ## current objective
var _t := 0.0

## Objectives in order. `done` is checked a few times a second.
var objectives: Array = []


func setup(b: Node) -> void:
	boot = b
	if b.gym != "":
		objectives = [{"id": "gym", "text": "GYM: %s  -  F1 developer menu" % b.gym,
			"hint": "A test map. F1 opens the developer menu: teleport, spawn items, bring the van, back to the game.",
			"done": func(): return false}]
		return
	objectives = [
		{"id": "read_letter", "text": "Read the note on the porch",
			"hint": "The homestead porch, right by where you start. Look at the paper on the crate and press E.",
			"done": func(): return flags.has("letter_read")},
		{"id": "spare_can", "text": "Take the spare fuel can and stow it on the van's rack",
			"hint": "The red can is by the garage door. Pick it up (E), carry it to the back of the van and stow it on the rack (E). The van is low on fuel.",
			"done": func(): return _can_on_rack() or boot.camper.fuel >= 40.0},
		{"id": "to_windmill", "text": "Drive up the lane to the windmill",
			"hint": "Driver's door is on the left of the van. X starts the engine, W to go. The windmill is where the lane ends.",
			"done": func(): return _van_near("j1", 45.0)},
		{"id": "choose_road", "text": "Pick a road to Bessi: Valley Road or Ridge Track",
			"hint": "Both reach Last Fuel. The ridge track is shorter but steep - watch the temperature gauge. The signpost and your map (M) help.",
			"done": func(): return _van_near("j2", 70.0)},
		{"id": "refuel", "text": "Top up the tank - the pumps at Last Fuel are dead",
			"hint": "Cans are stashed behind the kiosk. Not all of them are full: an empty can is light, a full one is a lug. Pour at the filler on the van's left side.",
			"done": func(): return boot.camper.fuel >= 40.0},
		{"id": "pump_road", "text": "Follow Pump House Road north toward the river",
			"hint": "The board at Last Fuel shows the way: north past the water works to the old bridge. Bessi is across the river.",
			"done": func(): return boot.camper.coolant_leak or flags.has("leak_fixed")},
		{"id": "coolant", "text": "The engine is boiling! Get coolant from the water works",
			"hint": "Pull into the water works yard. The plate by the red pump says how: route the pipes to the BLUE tank with valves A and B, then pump and keep the needle in the green. Follow the pipes to see where each valve sends the water.",
			"done": func(): return _station_solved() or flags.has("leak_fixed")},
		{"id": "pour_coolant", "text": "Pour the coolant into the van's radiator",
			"hint": "Carry the blue jug to the front of the van and hold E at the grille.",
			"done": func(): return flags.has("leak_fixed")},
		{"id": "to_bridge", "text": "Carry on north to the old bridge",
			"hint": "Pump House Road continues past the water works to the river crossing.",
			"done": func(): return _van_near("bridge_barrier_near", 45.0)},
		{"id": "end_a", "text": "The bridge is out. (The crossing comes in milestone B.)",
			"hint": "This is the end of milestone A.",
			"done": func(): return false},
	]


func current() -> Dictionary:
	return objectives[mini(index, objectives.size() - 1)]


func objective_text() -> String:
	return current()["text"]


func hint_text() -> String:
	return current()["hint"]


func _physics_process(delta: float) -> void:
	if boot == null or not boot.started:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.25
	# several can complete at once (e.g. the tank was already full)
	var advanced := false
	while index < objectives.size() - 1 and (objectives[index]["done"] as Callable).call():
		index += 1
		advanced = true
	if advanced:
		objective_changed.emit()
	_beats()


## One-off story moments, each fires once.
func _beats() -> void:
	if boot.gym != "":
		return
	if _van_near("j1", 60.0) and not flags.has("text_j1"):
		flags["text_j1"] = true
		_tell_all("Your phone finds one bar. An old message from Naresh, sent eight days ago:\n\n\"found the road!! we're taking the ridge, he says it's quicker. I mean I am. whatever. bessi tomorrow\"")
	# the hose goes on the climb toward the water works, whichever way you came
	if not flags.has("leak_started") and _van_near("facility", 150.0) and index >= 5:
		flags["leak_started"] = true
		boot.camper.spring_leak()
		_tell_all("A bang from under the bonnet, then a long hiss. Steam pours out of the grille - the coolant hose has split! The needle is climbing. The water works is just ahead.")
	if flags.has("leak_started") and not boot.camper.coolant_leak and not flags.has("leak_fixed"):
		flags["leak_fixed"] = true
	if _van_near("j2", 70.0) and not flags.has("text_j2"):
		flags["text_j2"] = true
		_tell_all("Another old message from Naresh:\n\n\"last fuel is closed lol. we left a can behind the shop for the way back. i left it. one of us did\"")


# --- actions from the world ---------------------------------------------------

func read_letter(p) -> void:
	flags["letter_read"] = true
	var letter := """Dear both,

Thank you for doing this. Naresh set off for that place on the old billboards - "Bessi and the 5 Roses" - eight days ago. He said he was going with a friend. We have never met this friend. He would not tell us a name.

He stopped answering four days ago. Please bring him home.

The van is low on fuel; take the spare can from by the garage. Bessi is north-east, across the river.

- Mum & Dad

P.S. The van's travel journal only keeps your progress when you write in it, and writing takes a Memory Rose. Nothing is saved for you. Be careful out there."""
	p.say(letter, 16.0)
	objective_changed.emit()


func add_fragment(id: String, p) -> void:
	if id in collected:
		return
	collected.append(id)
	fragments += 1
	var msg := "A Memory Fragment. It is warm, and smells faintly of roses. (%d of 3 for a Memory Rose.)" % (fragments % 3 if fragments % 3 != 0 else 3)
	if fragments % 3 == 0:
		msg += "\nThe three petals fold together into a Memory Rose. The travel journal can use it to save."
	p.say(msg, 6.0)


## Memory Roses ready to spend: every three fragments make one.
func roses() -> int:
	return fragments / 3 - roses_spent


## Fragments towards the next rose (0..2).
func petals() -> int:
	return fragments % 3


## Changes whenever something worth saving changes; compared against the value
## at the last save/load to warn about quitting with unsaved progress.
func progress_signature() -> String:
	return "%d|%d|%d|%d" % [index, fragments, collected.size(), flags.size()]


func _station_solved() -> bool:
	var st := get_tree().get_first_node_in_group("cooling_station")
	return st != null and st.solved


func _tell_all(text: String, secs := 9.0) -> void:
	for pl in boot.players:
		pl.say(text, secs)


# --- helpers -------------------------------------------------------------------

func _van_near(poi_id: String, radius: float) -> bool:
	var p: Vector3 = boot.builder.poi[poi_id]
	var v: Vector3 = boot.camper.global_position
	return Vector2(p.x - v.x, p.z - v.z).length() < radius


func _can_on_rack() -> bool:
	for s in boot.camper.storage_slots:
		var it = boot.camper.stowed_item(s)
		if it != null and it.kind == "fuel_can":
			return true
	return false


func to_dict() -> Dictionary:
	return {"flags": flags.duplicate(), "index": index, "fragments": fragments, "collected": collected.duplicate(), "roses_spent": roses_spent}


func from_dict(d: Dictionary) -> void:
	flags = (d.get("flags", {}) as Dictionary).duplicate()
	index = int(d.get("index", 0))
	fragments = int(d.get("fragments", 0))
	collected = (d.get("collected", []) as Array).duplicate()
	roses_spent = int(d.get("roses_spent", 0))
	objective_changed.emit()
