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
var opening_mode := false
var opening_steps := [0, 0]
var phone_threads := [[], []]
var phone_seen := [0, 0]

const P1_OPENING := [
	["Read the message from Naresh's mother (P)", "The phone opens with P or D-pad right. Messages arrive by themselves."],
	["Start the van and drive to Town Fuel", "The fuel lamp is on. X starts the engine; release the handbrake before driving."],
	["Fill a can at Town Fuel, then pour it into the van", "Take the empty can from the stand. Hold E at the working pump, then hold E at the van's filler."],
	["Drive to P2; mind the roadworks", "A warning sign and loose nails are past town. P2 is waiting beyond them."],
	["Swap the punctured tyre", "Take the spare from the rear. Set the jack at the flat, hold E on the nuts, lift the flat off, fit the spare, lower the jack."],
	["Park on P2's steep drive with the handbrake", "The drive is steep enough to roll the van. Space or B sets the handbrake."],
	["Stow P2's fuel can and coolant jug on the rack", "Carry each to the rear rack and press E. Cans fit any slot; the jug only fits the right-hand one."],
	["Wait for P2, then set off together", "Both of you need to be in the van before the shared journey begins."],
]
const P2_OPENING := [
	["Read the message from Naresh's mother (P)", "P or D-pad right opens your read-only phone."],
	["Find batteries in the kitchen drawer and fit them", "The torch is dead. Open the kitchen drawer with E, carry the batteries and press F."],
	["Open the shed and fill the red fuel can", "Use the torch inside the shed. Carry the empty can to the drum and hold E to fill it."],
	["Stamp the windmill on the shared paper map", "Open the map with M or D-pad down. Move the pencil to the windmill and place a stamp."],
	["Watch for P1's van", "The upstairs window looks out over the lane. Or wait by the drive."],
	["Carry the can and coolant jug to the van rack", "Take both from the shed and stow them on P1's van. The jug only fits the rack's right-hand slot."],
	["Get into the van with P1", "Join P1 in the van when the gear is loaded."],
]

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
	# Boot decides: a new game in the world (never a gym, never an older
	# play-test scenario, which expects the Milestone A start).
	if b.opening_run:
		begin_opening()


func current() -> Dictionary:
	return objectives[mini(index, objectives.size() - 1)]


func objective_text(player_index := -1) -> String:
	if opening_mode:
		var who := maxi(player_index, 0)
		var s: Array = P1_OPENING if who == 0 else P2_OPENING
		return s[mini(opening_steps[who], s.size() - 1)][0]
	return current()["text"]


func hint_text(player_index := -1) -> String:
	if opening_mode:
		var who := maxi(player_index, 0)
		var s: Array = P1_OPENING if who == 0 else P2_OPENING
		return s[mini(opening_steps[who], s.size() - 1)][1]
	return current()["hint"]


func _physics_process(delta: float) -> void:
	if boot == null or not boot.started:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.25
	if opening_mode:
		_opening_update()
		return
	# several can complete at once (e.g. the tank was already full)
	var advanced := false
	while index < objectives.size() - 1 and (objectives[index]["done"] as Callable).call():
		index += 1
		advanced = true
	if advanced:
		objective_changed.emit()
	_beats()


func begin_opening() -> void:
	opening_mode = true
	opening_steps = [0, 0]
	phone_threads = [[], []]
	phone_seen = [0, 0]
	flags["opening_started"] = true
	var windmill: Vector3 = boot.builder.poi["j1"]
	boot.map_state.reveal_around(Vector2(windmill.x, windmill.z), 140.0)
	_send_phone(0, "Naresh's mother", "He's gone. He hasn't answered in four days. Please find him and bring him home.")
	_send_phone(1, "Naresh's mother", "He's gone. He hasn't answered in four days. Please help find him.")
	_send_phone(0, "P2", "I'm free. Come get me. I'll get the gear ready.")
	_send_phone(1, "P1", "I'll come get you. Torch batteries are in the kitchen drawer.")
	objective_changed.emit()


func _send_phone(who: int, sender: String, body: String) -> void:
	phone_threads[who].append({"from": sender, "body": body})


func phone_text(who: int) -> String:
	var lines := []
	for msg in phone_threads[who]:
		lines.append("%s\n%s" % [msg["from"], msg["body"]])
	return "\n\n".join(lines)


func phone_unread(who: int) -> int:
	return maxi(0, phone_threads[who].size() - int(phone_seen[who]))


func mark_phone_read(who: int) -> void:
	phone_seen[who] = phone_threads[who].size()


func _opening_update() -> void:
	var changed := false
	for who in 2:
		var limit := P1_OPENING.size() if who == 0 else P2_OPENING.size()
		while opening_steps[who] < limit and _opening_done(who, opening_steps[who]):
			var finished: int = opening_steps[who]
			opening_steps[who] += 1
			changed = true
			if who == 0 and finished == 2:
				flags["opening_puncture_armed"] = true
			if who == 0 and finished == 3:
				_send_phone(1, "P1", "Got a puncture past town. Two minutes; I'm fitting the spare.")
			if who == 1 and finished == 1:
				_send_phone(0, "P2", "Found the torch batteries. I'll get the can ready.")
			if who == 0 and finished == 5:
				_send_phone(1, "P1", "I'm here. The van's on the drive.")
	if changed:
		objective_changed.emit()
	if opening_steps[0] >= P1_OPENING.size() and opening_steps[1] >= P2_OPENING.size():
		opening_mode = false
		flags["opening_complete"] = true
		flags.erase("opening_puncture_armed")
		index = 2  # the shared Milestone A journey resumes at the windmill
		_tell_all("You're together. Naresh is out there; take the road to the windmill.", 6.0)
		objective_changed.emit()


func _opening_done(who: int, step: int) -> bool:
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	if who == 0:
		match step:
			0: return phone_unread(0) == 0
			1: return _van_near("town_fuel", 35.0)
			2: return flags.has("town_fuel_filled") and boot.camper.fuel >= 12.0
			3: return flags.has("opening_puncture_done")   # even if it came before the refuel
			4: return flags.has("opening_puncture_done") and not boot.camper.tyre_flat and not boot.camper.spare_available
			5: return _van_near("p2_home", 30.0) and boot.camper.parking_brake
			6: return _opening_gear_stowed()
			7: return boot.players[0].seat != null and boot.players[1].seat != null
	else:
		match step:
			0: return phone_unread(1) == 0
			1: return house != null and house.drawer_open and boot.players[1].flashlight_seconds > 0.0
			2: return house != null and house.fuel_can.litres >= 19.0
			3: return _windmill_stamped()
			4:
				# from the window, or already out at the drive when the van pulls up
				var p2: PlayerRig = boot.players[1]
				return _van_near("p2_home", 40.0) and (p2.global_position.distance_to(boot.builder.poi["p2_window"]) < 6.0
					or p2.global_position.distance_to(boot.camper.global_position) < 20.0)
			5: return _opening_gear_stowed()
			6: return boot.players[1].seat != null
	return false


func _windmill_stamped() -> bool:
	var target: Vector3 = boot.builder.poi["j1"]
	for stamp in boot.map_state.stamps:
		if (stamp["pos"] as Vector2).distance_to(Vector2(target.x, target.z)) < 85.0:
			return true
	return false


func _opening_gear_stowed() -> bool:
	var can := false
	var jug := false
	for slot in boot.camper.storage_slots:
		var item: Carryable = boot.camper.stowed_item(slot)
		if item != null:
			can = can or item.name == "HouseFuelCan"
			jug = jug or item.name == "HouseCoolantJug"
	return can and jug


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
	if opening_mode:
		p.say("Dear both,\n\nNaresh said he was going to Bessi with a friend. He would not tell us the friend's name. He stopped answering four days ago. Please bring him home.\n\n- Mum & Dad", 14.0)
		return
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
	return "%d|%d|%d|%d|%s|%s" % [index, fragments, collected.size(), flags.size(), str(opening_steps), str(opening_mode)]


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
	return {"flags": flags.duplicate(), "index": index, "fragments": fragments,
		"collected": collected.duplicate(), "roses_spent": roses_spent,
		"opening_mode": opening_mode, "opening_steps": opening_steps.duplicate(),
		"phone_threads": phone_threads.duplicate(true), "phone_seen": phone_seen.duplicate()}


func from_dict(d: Dictionary) -> void:
	flags = (d.get("flags", {}) as Dictionary).duplicate()
	index = int(d.get("index", 0))
	fragments = int(d.get("fragments", 0))
	collected = (d.get("collected", []) as Array).duplicate()
	roses_spent = int(d.get("roses_spent", 0))
	opening_mode = bool(d.get("opening_mode", false))
	var steps: Array = d.get("opening_steps", [0, 0])
	opening_steps = [int(steps[0]), int(steps[1])]
	phone_threads = (d.get("phone_threads", [[], []]) as Array).duplicate(true)
	var seen: Array = d.get("phone_seen", [0, 0])
	phone_seen = [int(seen[0]), int(seen[1])]
	objective_changed.emit()
