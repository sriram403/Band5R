class_name HouseInterior
extends Node3D

## Opening house, built at local ground level. The front is +Z. The stairwell
## opens through the upper floor at the right; the upstairs window faces the
## lane so P2 can see the arriving van.

var front_open := false
var shed_open := false
var drawer_open := false
var battery_pack: BatteryPack
var fuel_can: FuelCan
var coolant_jug: CoolantJug
var drum: FuelSource


func _ready() -> void:
	_build()


func _part(size: Vector3, pos: Vector3, color: Color, nm: String) -> StaticBody3D:
	var part := Build.solid_box(size, ToonMat.make(color), pos, Vector3.ZERO, nm)
	add_child(part)
	return part


func _build() -> void:
	var wall := Color(0.80, 0.86, 0.90)
	var inside := Color(0.86, 0.82, 0.72)
	var wood := Color(0.43, 0.30, 0.21)
	_part(Vector3(10.4, 0.35, 8.4), Vector3(0, -0.18, 0), inside, "GroundFloor")
	# Front opening, front door and three remaining walls.
	# The upstairs left bay has an actual opening from y=3.9 to 5.4.
	_part(Vector3(4.1, 3.9, 0.3), Vector3(-3.15, 1.95, 4), wall, "FrontLeftLow")
	_part(Vector3(4.1, 0.8, 0.3), Vector3(-3.15, 5.8, 4), wall, "FrontLeftHigh")
	_part(Vector3(1.7, 1.5, 0.3), Vector3(-4.3, 4.65, 4), wall, "WindowLeftJamb")
	_part(Vector3(0.8, 1.5, 0.3), Vector3(-1.5, 4.65, 4), wall, "WindowRightJamb")
	_part(Vector3(4.1, 6.2, 0.3), Vector3(3.15, 3.1, 4), wall, "FrontRight")
	_part(Vector3(2.2, 3.8, 0.3), Vector3(0, 4.3, 4), wall, "FrontOverDoor")
	_part(Vector3(10.4, 6.2, 0.3), Vector3(0, 3.1, -4), wall, "BackWall")
	for x in [-5.1, 5.1]:
		_part(Vector3(0.3, 6.2, 8.3), Vector3(x, 3.1, 0), wall, "SideWall")
	# A gap on the right is the stairwell. The last step reaches the rear landing.
	_part(Vector3(6.7, 0.25, 8.0), Vector3(-1.75, 3.2, 0), inside, "UpperFloor")
	_part(Vector3(3.3, 0.25, 0.9), Vector3(3.35, 3.2, -3.55), inside, "StairLanding")
	# A sloped collision bed lets the player walk naturally; visible wooden
	# treads mark each rise without catching the capsule on their vertical faces.
	add_child(Build.solid_box(Vector3(2.2, 0.12, 7.5), ToonMat.make(wood),
		Vector3(3.4, 1.55, 0.2), Vector3(25.0, 0, 0), "StairRamp"))
	for k in 16:
		var rise := float(k + 1) * 0.2
		var z := 2.75 - float(k) * 0.34
		add_child(Build.box(Vector3(2.2, 0.06, 0.34), ToonMat.make(wood),
			Vector3(3.4, rise, z), Vector3.ZERO, "Stair%02d" % k))
	_part(Vector3(10.8, 0.3, 8.8), Vector3(0, 6.35, 0), Color(0.37, 0.39, 0.44), "Roof")
	# Four slim blue frame pieces leave a clear sightline to the road.
	var blue := ToonMat.make(Color(0.36, 0.60, 0.78))
	for x in [-3.35, -1.65]:
		add_child(Build.box(Vector3(0.09, 1.45, 0.08), blue, Vector3(x, 4.65, 4.19), Vector3.ZERO, "WindowFrame"))
	for y in [3.93, 5.38]:
		add_child(Build.box(Vector3(1.78, 0.08, 0.08), blue, Vector3(-2.5, y, 4.19), Vector3.ZERO, "WindowFrame"))
	_part(Vector3(2.4, 0.8, 1.1), Vector3(-3.4, 3.65, -1.8), wood, "UpstairsDesk")
	add_child(Build.box(Vector3(0.75, 0.02, 0.55), ToonMat.make(Color(0.94, 0.88, 0.66)),
		Vector3(-3.9, 4.08, -1.7), Vector3.ZERO, "PaperMapOnDesk"))
	add_child(Build.interact_area(Vector3(0.9, 0.55, 0.5), Vector3(-3.9, 4.15, -0.95),
		"Open the paper map", func(p): p.set_map_open(true), "MapDesk"))
	add_child(Build.box(Vector3(0.42, 0.12, 0.55), ToonMat.make(Color(0.36, 0.26, 0.18)),
		Vector3(-2.8, 4.1, -1.7), Vector3.ZERO, "HouseJournal"))
	add_child(Build.interact_area(Vector3(0.65, 0.55, 0.5), Vector3(-2.8, 4.15, -0.95),
		"Read the travel journal note", func(p):
			p.say("The travel journal is kept in the camper. Three Memory Fragments make one Rose; writing a save spends one Rose. There are no automatic checkpoints.", 10.0),
		"JournalNote"))
	_part(Vector3(1.6, 2.5, 0.16), Vector3(0, 1.25, 4.12), wood, "FrontDoor")
	var handle := Build.interact_area(Vector3(2.2, 2.6, 0.5), Vector3(0, 1.3, 4.48),
		"Open front door", func(_p):
			front_open = not front_open
			_show_doors(),
		"FrontDoorHandle")
	add_child(handle)
	# Kitchen drawer reveals a physical packet that can be carried and fitted.
	_part(Vector3(2.8, 1.0, 0.85), Vector3(-3.0, 0.5, -2.7), wood, "KitchenCounter")
	var drawer := Build.box(Vector3(0.85, 0.24, 0.08), ToonMat.make(Color(0.62, 0.44, 0.29)),
		Vector3(-3.0, 0.82, -2.20), Vector3.ZERO, "BatteryDrawer")
	add_child(drawer)
	var pull := Build.interact_area(Vector3(1.1, 0.55, 0.5), Vector3(-3.0, 0.85, -1.92),
		"Open kitchen drawer", func(_p):
			if drawer_open:
				return
			drawer_open = true
			drawer.position.z += 0.42
			get_node("DrawerHandle").set_meta("prompt", "Drawer is open")
			battery_pack = BatteryPack.new()
			battery_pack.name = "HouseBatteries"
			add_child(battery_pack)
			battery_pack.position = Vector3(-3.0, 0.25, -1.55),
		"DrawerHandle")
	add_child(pull)
	# Shed: an enclosed workspace with a door on its front face.
	var sx := 8.5
	_part(Vector3(5.2, 0.25, 6.2), Vector3(sx, -0.1, 0), wood, "ShedFloor")
	_part(Vector3(5.2, 0.25, 6.2), Vector3(sx, 3.25, 0), wood, "ShedRoof")
	for x in [sx - 2.5, sx + 2.5]:
		_part(Vector3(0.25, 3.2, 6.1), Vector3(x, 1.6, 0), wood, "ShedSide")
	_part(Vector3(5.2, 3.2, 0.25), Vector3(sx, 1.6, -3), wood, "ShedBack")
	for x in [sx - 1.8, sx + 1.8]:
		_part(Vector3(1.5, 3.2, 0.25), Vector3(x, 1.6, 3), wood, "ShedFront")
	_part(Vector3(1.5, 2.5, 0.14), Vector3(sx, 1.25, 3.1), wood, "ShedDoor")
	var shed_handle := Build.interact_area(Vector3(1.9, 2.6, 0.5), Vector3(sx, 1.3, 3.46),
		"Open shed door", func(_p):
			shed_open = not shed_open
			_show_doors(),
		"ShedDoorHandle")
	add_child(shed_handle)
	drum = FuelSource.new()
	drum.name = "FuelDrum"
	add_child(drum)
	drum.position = Vector3(sx, 0, -1.7)
	fuel_can = FuelCan.create(0.0)
	fuel_can.name = "HouseFuelCan"
	add_child(fuel_can)
	fuel_can.position = Vector3(sx - 1.1, 0.2, 0.1)
	coolant_jug = CoolantJug.new()
	coolant_jug.name = "HouseCoolantJug"
	coolant_jug.litres = CoolantJug.CAPACITY * 0.5
	add_child(coolant_jug)
	coolant_jug.position = Vector3(sx + 1.1, 0.2, 0.1)


func to_dict() -> Dictionary:
	return {"front_open": front_open, "shed_open": shed_open,
		"drawer_open": drawer_open, "drum_litres": drum.litres}


func from_dict(d: Dictionary) -> void:
	front_open = bool(d.get("front_open", false))
	shed_open = bool(d.get("shed_open", false))
	drawer_open = bool(d.get("drawer_open", false))
	drum.litres = float(d.get("drum_litres", drum.litres))
	_show_doors()
	if drawer_open:
		get_node("BatteryDrawer").position.z = -1.78
		get_node("DrawerHandle").set_meta("prompt", "Drawer is open")


## Doors and their prompts follow the open/closed state.
func _show_doors() -> void:
	for pair in [["FrontDoor", front_open, "front door"], ["ShedDoor", shed_open, "shed door"]]:
		var door := get_node(pair[0]) as StaticBody3D
		var open: bool = pair[1]
		door.visible = not open
		door.collision_layer = 0 if open else 1
		get_node(pair[0] + "Handle").set_meta("prompt", ("Close " if open else "Open ") + pair[2])
