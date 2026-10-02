class_name FishingVillage
extends Node

## F3, the fishing village and R1 the decoy (design/RETURN.md, decision 5).
## The van comes up the coast road on its last litre. The fuel is in the net
## shed, locked; the key is in a small boat up on the shed's flat roof (climb
## the stacked fish crates). Two creatures pace between the huts and the shed,
## and on the return they drift towards Naresh: send him to wait at the end
## of the jetty and they follow him out, the shed side clears. The watcher
## calls him back from afar (V on him: Follow me) before one gets there; if
## he's taken he's left up high 200-400 m off. In the shed: a full can and an
## old empty one. Naresh takes the empty one to the van himself ("there's
## two!"), and once the full one is at the van too he does the fuel himself:
## with the empty can (the scripted mistake, design/NARESH.md). The van dies
## ~300 m on, and the creatures, following him, come while you pour it.
##
## State in the story's flags: "fuel_low", "key_got", "shed_open",
## "mistake_done", "stalled", "stall_fixed".

const SHED := Vector3(8.0, 2.8, 6.0)     ## outside size: depth (x, towards the sea), roof top, width (z)
const SHED_AT := Vector3(12, 0, 12)      ## from the village centre
const DOOR := Vector2(2.2, 2.2)            ## wide: a can carried at the side snagged on a 1.4 m frame
const STEP_H := 0.45                     ## one fish crate: a jump climbs one
const JETTY_Z := LevelBuilder.VILLAGE_JETTY_Z
const JETTY_LEN := 66.0                  ## m out past the waterline
const JETTY_W := LevelBuilder.VILLAGE_JETTY_W
const LOW_FUEL := 1.3                    ## litres when you reach the village (~500 m of driving)
const LOW_AT := 420.0                    ## m short of the village the lamp comes on
const DIES_AFTER := 250.0                ## m past the village (on top of what's left)

var centre := Vector3.ZERO
var shed: Node3D
var door: StaticBody3D
var key_node: StaticBody3D
var can_full: FuelCan
var can_empty: FuelCan
var jetty_end := Vector3.ZERO           ## where Naresh waits (tests)
var jetty_start := Vector3.ZERO
var creatures: Array[Creature] = []
var _story: Story
var _helped := false                    ## he's taken the empty can to the van
var _offered := false                   ## he's offered to do the fuel
var _mistake_at := Vector3.ZERO         ## where the van was when he "filled" it


func setup(b) -> void:
	add_to_group("fishing_village")
	Creature.funnels.clear()        # static: a reloaded scene starts again
	centre = LevelBuilder.FISHING_VILLAGE
	centre.y = b._h(centre.x, centre.z)
	_shed(b)
	_jetty(b)
	_creatures(b)
	_drops(b)


# --- the shed ------------------------------------------------------------------------

func _shed(b) -> void:
	var at := centre + SHED_AT
	at.y = b._h(at.x, at.z)
	shed = Node3D.new()
	shed.name = "NetShed"
	shed.position = at
	b.world.add_child(shed)
	var walls := StaticBody3D.new()
	walls.name = "ShedWalls"
	shed.add_child(walls)
	var plank := ToonMat.make(Color(0.50, 0.42, 0.34), 0.02)
	var hx := SHED.x * 0.5
	var hz := SHED.z * 0.5
	var low := -0.6                      # walls go into the sloping sand
	var hh := SHED.y - 0.2 - low
	var mid := low + hh * 0.5
	var side := (SHED.z - DOOR.x) * 0.5
	# back (+x), two sides, the front (-x, the land side) either side of the
	# door and over it, and the flat roof you can walk on
	for spec in [[Vector3(0.2, hh, SHED.z), Vector3(hx, mid, 0)],
			[Vector3(SHED.x, hh, 0.2), Vector3(0, mid, -hz)],
			[Vector3(SHED.x, hh, 0.2), Vector3(0, mid, hz)],
			[Vector3(0.2, hh, side), Vector3(-hx, mid, -hz + side * 0.5)],
			[Vector3(0.2, hh, side), Vector3(-hx, mid, hz - side * 0.5)],
			[Vector3(0.2, SHED.y - 0.2 - DOOR.y, DOOR.x), Vector3(-hx, DOOR.y + (SHED.y - 0.2 - DOOR.y) * 0.5, 0)],
			[Vector3(SHED.x + 0.3, 0.2, SHED.z + 0.3), Vector3(0, SHED.y - 0.1, 0)]]:
		walls.add_child(Build.box(spec[0], plank, spec[1], Vector3.ZERO, "Wall"))
		walls.add_child(b._box_shape(spec[0], Transform3D(Basis(), spec[1])))
	shed.add_child(Build.label3d("NETS - PRIVATE", Vector3(-hx - 0.12, 2.4, 0), Vector3(0, -90, 0), 0.22, Color(0.95, 0.92, 0.85)))
	# the door: locked until someone has the key
	door = StaticBody3D.new()
	door.name = "ShedDoor"
	door.position = Vector3(-hx, DOOR.y * 0.5, 0)
	door.add_child(Build.box(Vector3(0.12, DOOR.y, DOOR.x - 0.05), ToonMat.make(Color(0.36, 0.30, 0.24)), Vector3.ZERO, Vector3.ZERO, "Panel"))
	door.add_child(Build.box(Vector3(0.2, 0.18, 0.12), ToonMat.make(Color(0.25, 0.25, 0.27)), Vector3(-0.1, 0.0, DOOR.x * 0.3), Vector3.ZERO, "Padlock"))
	door.add_child(b._box_shape(Vector3(0.12, DOOR.y, DOOR.x - 0.05), Transform3D.IDENTITY))
	door.set_meta("prompt", "Locked")
	door.set_meta("prompt_fn", func(_p) -> String: return "Unlock the shed" if _flag("key_got") else "")
	door.set_meta("blocked_fn", func() -> String: return "" if _flag("key_got") else "Padlocked. The key must be somewhere about")
	door.set_meta("callback", func(p): _open(p, true))
	door.set_meta("tag_name", "the shed door")
	shed.add_child(door)
	# the fish crates stacked up the side: a staircase to the roof
	var crate := ToonMat.make(Color(0.62, 0.48, 0.30), 0.02)
	var slat := ToonMat.make(Color(0.42, 0.32, 0.22), 0.02)
	var stairs := StaticBody3D.new()
	stairs.name = "FishCrates"
	shed.add_child(stairs)
	var steps := int(ceil((SHED.y - 0.15) / STEP_H))
	for k in steps:
		var h := minf(STEP_H * (k + 1), SHED.y - 0.1)
		var cx := -hx + 0.45 + k * 0.66
		var size := Vector3(0.64, h - low, 0.66)
		var c := Vector3(cx, low + size.y * 0.5, hz + 0.45)
		stairs.add_child(Build.box(size, crate, c, Vector3.ZERO, "Crates"))
		stairs.add_child(Build.box(Vector3(0.66, 0.05, 0.68), slat, Vector3(cx, h - 0.03, hz + 0.45), Vector3.ZERO, "Top"))
		stairs.add_child(b._box_shape(size, Transform3D(Basis(), c)))
	# a taller stack past the top step: you turn onto the roof, not off the end
	var stop_x := -hx + 0.45 + steps * 0.66
	var stop := Vector3(0.64, SHED.y + 0.9 - low, 0.66)
	var sc := Vector3(stop_x, low + stop.y * 0.5, hz + 0.45)
	stairs.add_child(Build.box(stop, crate, sc, Vector3.ZERO, "Crates"))
	stairs.add_child(b._box_shape(stop, Transform3D(Basis(), sc)))
	b.poi["net_shed_crates"] = shed.transform * Vector3(-hx - 0.4, 0.2, hz + 0.45)
	# the boat on the roof, the key in it (tied to a cork float)
	var roof := SHED.y
	var boat := StaticBody3D.new()
	boat.name = "RoofBoat"
	boat.position = Vector3(0.6, roof, -0.8)
	shed.add_child(boat)
	var hull := ToonMat.make(Color(0.25, 0.45, 0.65), 0.02)
	for spec in [[Vector3(1.3, 0.12, 3.4), Vector3(0, 0.06, 0)], [Vector3(0.1, 0.5, 3.4), Vector3(-0.6, 0.25, 0)],
			[Vector3(0.1, 0.5, 3.4), Vector3(0.6, 0.25, 0)], [Vector3(1.3, 0.5, 0.1), Vector3(0, 0.25, -1.7)],
			[Vector3(1.3, 0.5, 0.1), Vector3(0, 0.25, 1.7)]]:
		boat.add_child(Build.box(spec[0], hull, spec[1], Vector3.ZERO, "Hull"))
		boat.add_child(b._box_shape(spec[0], Transform3D(Basis(), spec[1])))
	key_node = StaticBody3D.new()
	key_node.name = "ShedKey"
	key_node.position = Vector3(0.6, roof + 0.3, -0.8)
	key_node.add_child(Build.cyl(0.09, 0.14, ToonMat.make(Color(0.85, 0.75, 0.45)), Vector3.ZERO, Vector3(90, 0, 0), 8, "Float"))
	key_node.add_child(Build.box(Vector3(0.04, 0.02, 0.22), ToonMat.make(Color(0.35, 0.33, 0.30)), Vector3(0, 0.02, 0.17), Vector3.ZERO, "Key"))
	key_node.add_child(b._box_shape(Vector3(0.5, 0.4, 0.6), Transform3D.IDENTITY))
	key_node.set_meta("prompt", "Take the key")
	key_node.set_meta("callback", func(p): _take_key(p, true))
	key_node.set_meta("tag_name", "the boat on the roof")
	shed.add_child(key_node)
	b.poi["net_shed_key"] = shed.transform * key_node.position
	b.poi["net_shed_roof"] = shed.transform * Vector3(-1.6, roof + 0.2, 1.2)
	b.poi["net_shed_door"] = shed.transform * Vector3(-hx - 1.2, 0.2, 0)
	b.poi["net_shed"] = at
	# inside: a full can, and an old empty one
	can_full = b._place_can(shed.transform * Vector3(2.2, 0, 1.2), FuelCan.CAPACITY, "village_full")
	can_empty = b._place_can(shed.transform * Vector3(2.2, 0, -1.4), 0.0, "village_empty")


func _take_key(p: PlayerRig, tell: bool) -> void:
	if _flag("key_got"):
		return
	_story.flags["key_got"] = true
	key_node.visible = false
	for c in key_node.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", true)
	if tell and p != null:
		Sfx.play3d("pickup", key_node.global_position, -4.0)
		p.say("Under the thwart, tied to a cork float: a big iron key.", 5.0)


func _open(p: PlayerRig, tell: bool) -> void:
	if not _flag("key_got") or _flag("shed_open"):
		return
	_story.flags["shed_open"] = true
	door.visible = false
	for c in door.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", true)
	if tell:
		Sfx.play3d("latch", door.global_position, 0.0)
		if p != null:
			p.say("The padlock gives. Nets, floats, a smell of fish, and two jerrycans at the back: one heavy, one light.", 6.0)


# --- the jetty --------------------------------------------------------------------------

func _jetty(b) -> void:
	var z := centre.z + JETTY_Z
	var shore := centre.x + Landscape.coast_inland(centre.x, z)    # the waterline's x here
	var x0 := shore - 5.0
	var x1 := shore + JETTY_LEN
	var top: float = b._h(x0, z) + 0.02       # flush with the sand where it starts: no step to stumble on
	var wood := ToonMat.make(Color(0.48, 0.38, 0.28), 0.02)
	var dark := ToonMat.make(Color(0.30, 0.25, 0.20), 0.02)
	var body := StaticBody3D.new()
	body.name = "Jetty"
	b.world.add_child(body)
	var len := x1 - x0
	var deck := Vector3(len, 0.3, JETTY_W)
	var dc := Vector3((x0 + x1) * 0.5, top - 0.15, z)
	body.add_child(Build.box(deck, wood, dc, Vector3.ZERO, "Deck"))
	body.add_child(b._box_shape(deck, Transform3D(Basis(), dc)))
	# the end: a square platform
	var pe := Vector3(x1 + 3.0, top - 0.15, z)
	body.add_child(Build.box(Vector3(6, 0.3, 6), wood, pe, Vector3.ZERO, "End"))
	body.add_child(b._box_shape(Vector3(6, 0.3, 6), Transform3D(Basis(), pe)))
	# rails: a fence down to the seabed so nobody (or nothing) steps off it,
	# or walks round it through the gap left in the sea wall
	var deep := Landscape.SEA_Y - 16.0
	var fence_h: float = top + 1.0 - deep
	var rail := func(a: Vector3, bb: Vector3) -> void:
		var mid := (a + bb) * 0.5
		var l := a.distance_to(bb)
		var xf := Transform3D(Basis.looking_at(bb - a, Vector3.UP), Vector3(mid.x, deep + fence_h * 0.5, mid.z))
		body.add_child(b._box_shape(Vector3(0.12, fence_h, l), xf))
		body.add_child(Build.node(_box_mesh(Vector3(0.08, 0.08, l)), dark, Transform3D(xf.basis, Vector3(mid.x, top + 0.95, mid.z)), "Rail"))
	var hw := JETTY_W * 0.5 + 0.05
	rail.call(Vector3(x0, 0, z - hw), Vector3(x1, 0, z - hw))
	rail.call(Vector3(x0, 0, z + hw), Vector3(x1, 0, z + hw))
	rail.call(Vector3(x1, 0, z - hw), Vector3(x1, 0, z - 3.0))
	rail.call(Vector3(x1, 0, z + hw), Vector3(x1, 0, z + 3.0))
	rail.call(Vector3(x1, 0, z - 3.0), Vector3(x1 + 6.0, 0, z - 3.0))
	rail.call(Vector3(x1, 0, z + 3.0), Vector3(x1 + 6.0, 0, z + 3.0))
	rail.call(Vector3(x1 + 6.0, 0, z - 3.0), Vector3(x1 + 6.0, 0, z + 3.0))
	# posts into the water every 6 m
	var x := x0 + 6.0
	while x < x1 + 6.0:
		for s in [-1.0, 1.0]:
			var py: float = b._h(x, z)
			var ph: float = top - py
			if ph > 0.3:
				body.add_child(Build.cyl(0.12, ph + 1.0, dark, Vector3(x, py + (ph + 1.0) * 0.5 - 0.3, z + s * hw), Vector3.ZERO, 6, "Post"))
		x += 6.0
	jetty_start = Vector3(x0 + 1.0, top, z)
	jetty_end = Vector3(x1 + 3.0, top, z)
	b.poi["jetty"] = jetty_start
	b.poi["jetty_end"] = jetty_end
	# a creature heading for someone out on it walks round by its start
	# (the entry is just inside the box: once there it heads straight along the deck)
	Creature.funnels.append({"box": AABB(Vector3(x0 - 1.0, top - 3.0, z - 3.5), Vector3(x1 + 10.0 - x0, 8.0, 7.0)), "entry": Vector3(x0, top, z)})


static func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


# --- the creatures and where they leave him -------------------------------------------

func _creatures(b) -> void:
	var c := centre
	var paths := [[Vector3(4, 0, 12), Vector3(-6, 0, 4), Vector3(-6, 0, 22), Vector3(2, 0, 26)],
		[Vector3(20, 0, 2), Vector3(24, 0, 20), Vector3(14, 0, 26), Vector3(6, 0, 4)]]
	for i in paths.size():
		var cr := Creature.new()
		cr.name = "VillageCreature%d" % (i + 1)
		var pts := PackedVector3Array()
		for o in paths[i]:
			var q: Vector3 = c + o
			q.y = b._h(q.x, q.z)
			pts.append(q)
		cr.patrol = pts
		b.world.add_child(cr)
		cr.position = pts[0] + Vector3(0, 0.2, 0)
		creatures.append(cr)
	b.poi["village_creatures"] = c + Vector3(12, 0, 14)


func _drops(b) -> void:
	var stone := ToonMat.make(LevelBuilder.C_STONE)
	for spec in [[Vector3(-230, 0, 130), 6.0, "the old water tank"], [Vector3(-150, 0, -250), 5.0, "the rock stack"]]:
		var at: Vector3 = centre + spec[0]
		at.y = b._h(at.x, at.z)
		var h: float = spec[1]
		var body := StaticBody3D.new()
		body.name = "NareshDrop"
		body.add_child(Build.box(Vector3(5, h + 1.0, 5), stone, Vector3(0, (h - 1.0) * 0.5, 0), Vector3.ZERO, "Block"))
		body.add_child(b._box_shape(Vector3(5, h + 1.0, 5), Transform3D(Basis(), Vector3(0, (h - 1.0) * 0.5, 0))))
		body.position = at
		b.world.add_child(body)
		b.naresh_drops.append({"pos": at + Vector3(0, h, 0), "near": spec[2]})


# --- the story -----------------------------------------------------------------------------

func _flag(f: String) -> bool:
	return _story != null and _story.flags.has(f)


func _physics_process(_delta: float) -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
		match_story()
	if not _flag("storm_on"):
		return
	var boot := get_tree().current_scene
	var van: Camper = boot.get("camper")
	var nz: Naresh = boot.get("naresh")
	if van == null:
		return
	var to_village := Vector2(van.global_position.x - centre.x, van.global_position.z - centre.z).length()
	# coming up the coast road on the last of the fuel
	if not _flag("fuel_low") and to_village < LOW_AT and van.global_position.z > centre.z:
		_story.flags["fuel_low"] = true
		van.fuel = minf(van.fuel, LOW_FUEL)
		for n in get_tree().get_nodes_in_group("player"):
			(n as PlayerRig).say("The fuel lamp is on and the needle's on E: the storm road and the climb have drunk the drum. You'll make the fishing village ahead, no further.", 8.0)
	if nz == null or not is_instance_valid(nz) or not is_instance_valid(can_empty) or not is_instance_valid(can_full):
		return
	# "there's two!": he takes the light one to the van
	if _flag("shed_open") and not _helped and nz.state in [Naresh.State.FOLLOW, Naresh.State.WAIT, Naresh.State.IDLE] \
			and nz.global_position.distance_to(can_empty.global_position) < 25.0 and can_empty.holders.is_empty():
		_helped = true
		nz.refuel_mistake = true
		nz.say("There's two! I'll take this one to the van.")
		nz.command(_leader(nz), "store", can_empty)
	# the full can at the van too: he does the fuel himself, with the empty one
	if _helped and not _offered and not _flag("mistake_done") and can_empty.stowed_in != null and is_instance_valid(can_full) and can_full.holders.is_empty() \
			and can_full.global_position.distance_to(van.global_position) < 8.0 and can_full.litres > 1.0 \
			and nz.state in [Naresh.State.FOLLOW, Naresh.State.WAIT, Naresh.State.IDLE] and nz.global_position.distance_to(van.global_position) < 25.0:
		_offered = true
		nz.say("Leave the fuel to me! I know how.")
		nz.command(_leader(nz), "refuel", can_full)
	if _offered and not _flag("mistake_done") and not nz.refuel_mistake:
		# his job is over: he "filled" it from the empty can
		_story.flags["mistake_done"] = true
		_mistake_at = van.global_position
		# what is left: enough for ~250 m (a long dawdle in the village had
		# it die within reach of the village creatures)
		van.fuel = DIES_AFTER / 1000.0 * Camper.FUEL_PER_KM * 1.2
	# the van dies on the open road, and they come (they follow him)
	if _flag("mistake_done") and not _flag("stalled") and van.fuel <= 0.0:
		_story.flags["stalled"] = true
		for n in get_tree().get_nodes_in_group("player"):
			(n as PlayerRig).say("The engine coughs, catches, coughs and dies. The gauge is on empty. The full can is still on the rack.", 7.0)
		nz.say("Then imagine how much fuel I put in.")
		_stall_creature(van)
	if _flag("stalled") and not _flag("stall_fixed") and van.fuel > 5.0:
		_story.flags["stall_fixed"] = true


## Up the road ahead something steps out of the dark and turns towards him.
func _stall_creature(van: Camper) -> void:
	var road: Route = get_tree().current_scene.get("builder").network.road("coast_road")
	var near: Dictionary = road.nearest(van.global_position.x, van.global_position.z)
	var i := int(near["index"])
	var ahead := road.point(i + 35) + road.right(i + 35) * 9.0       # ~70 m on, off the verge
	var cr := Creature.new()
	cr.name = "StallCreature"
	get_tree().current_scene.get("world").add_child(cr)
	cr.global_position = ahead + Vector3(0, 0.3, 0)
	creatures.append(cr)
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say("Up the road, something tall steps out of the dark and turns towards the van. Pour the full can in yourself, quickly.", 7.0)


func _leader(nz: Naresh) -> PlayerRig:
	if nz.leader != null:
		return nz.leader
	return get_tree().get_nodes_in_group("player")[0] as PlayerRig


## After a load or a story jump: the shed and the key as the flags say.
func match_story() -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
	if _story == null:
		return
	var got := _flag("key_got")
	key_node.visible = not got
	for c in key_node.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", got)
	var open := _flag("shed_open")
	door.visible = not open
	for c in door.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", open)
	_helped = can_empty.stowed_in != null      # he's taken the light can to the van already
	_offered = _flag("mistake_done")
