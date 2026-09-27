class_name BessiTasks
extends Node

## E6, Naresh's two teaching puzzles (design/BESSI.md 29:00-30:00):
## N1, the store: the torch batteries for the dark road are in a box too
##   heavy for one, in a store whose heavy shutter only stays up while
##   someone holds its handle outside. You both have to go in: Naresh holds
##   it ("hold it"). The first time, with you both inside, he lets go (his
##   friend was telling him something) and you're shut in, then he opens it.
## N2, the boat: the fuel drum is under an upturned boat on the sand. It
##   takes three pushing at once: you two and Naresh ("work it"). The first
##   time he pushes from the wrong side until someone tells him again.
##
## State in the story's flags: "n1_slip", "batteries_got", "n2_wrong_done",
## "drum_free".

const STORE_Z := 700.0             ## on the stall row, between two stalls
const STORE := Vector3(4.0, 2.6, 3.0)   ## outside size: depth (x), height, width (z)
const SHUTTER_UP := 1.25           ## m it rises: crouch to get under
const SLIP_AFTER := 2.5            ## s with you both inside before he lets go
const SLIP_BACK := 4.0             ## s before he opens it again
const BOAT_Z := 585.0
const BOAT_SLIDE := 5.5            ## m it slides towards the sea when pushed off

var store: Node3D
var shutter: StaticBody3D
var handle: Workable
var box: Carryable
var boat: Workable
var boat_body: Node3D
var drum: FuelDrum
var inside_box: AABB               ## the store's floor space, in world coordinates
var naresh_wrong := false
var _wrong_at := -1
var _slip_t := 0.0
var _back_t := -1.0
var _boat_base := Vector3.ZERO
var _drum_at := Vector3.ZERO
var _box_at := Vector3.ZERO


func setup(b) -> void:
	add_to_group("bessi_tasks")
	_store(b)
	_boat(b)


# --- N1, the store --------------------------------------------------------------------

func _store(b) -> void:
	var shore := Bessi.shore_x(STORE_Z)
	var at := Vector3(shore - 58.0, 0, STORE_Z)
	at.y = b._h(at.x, at.z)
	store = Node3D.new()
	store.name = "BatteryStore"
	store.position = at
	b.world.add_child(store)
	var walls := StaticBody3D.new()
	walls.name = "StoreWalls"
	store.add_child(walls)
	var paint := ToonMat.make(Color(0.72, 0.30, 0.25), 0.02)
	var hx := STORE.x * 0.5
	var hz := STORE.z * 0.5
	# back, two sides, roof; the front (+x, towards the sea) is the shutter
	for spec in [[Vector3(0.2, STORE.y, STORE.z), Vector3(-hx, STORE.y * 0.5, 0)],
			[Vector3(STORE.x, STORE.y, 0.2), Vector3(0, STORE.y * 0.5, -hz)],
			[Vector3(STORE.x, STORE.y, 0.2), Vector3(0, STORE.y * 0.5, hz)],
			[Vector3(STORE.x + 0.3, 0.2, STORE.z + 0.3), Vector3(0, STORE.y + 0.1, 0)],
			[Vector3(0.2, STORE.y - 2.2, STORE.z), Vector3(hx, 2.2 + (STORE.y - 2.2) * 0.5, 0)]]:
		walls.add_child(Build.box(spec[0], paint, spec[1], Vector3.ZERO, "Wall"))
		walls.add_child(b._box_shape(spec[0], Transform3D(Basis(), spec[1])))
	store.add_child(Build.label3d("BESSI STORES\nbatteries · torches · rope", Vector3(hx + 0.15, 2.4, 0), Vector3(0, 90, 0), 0.11, Color(1, 0.95, 0.8)))
	# the shutter: corrugated steel, 2.9 wide, all the way down to the ground
	shutter = StaticBody3D.new()
	shutter.name = "Shutter"
	var steel := ToonMat.make(Color(0.55, 0.58, 0.60), 0.02)
	var sh_size := Vector3(0.1, 2.2, STORE.z - 0.2)
	var look := Node3D.new()
	look.name = "Look"
	shutter.add_child(look)
	look.add_child(Build.box(sh_size, steel, Vector3(0, 1.1, 0), Vector3.ZERO, "Panel"))
	for k in 6:
		look.add_child(Build.box(Vector3(0.12, 0.05, STORE.z - 0.2), ToonMat.make(Color(0.45, 0.47, 0.5)), Vector3(0.02, 0.25 + k * 0.35, 0), Vector3.ZERO, "Rib"))
	shutter.add_child(b._box_shape(sh_size, Transform3D(Basis(), Vector3(0, 1.1, 0))))
	shutter.position = Vector3(hx + 0.05, 0, 0)
	store.add_child(shutter)
	# its handle, outside to one side: whoever holds it can't be inside
	handle = Workable.new()
	handle.name = "ShutterHandle"
	handle.kind = "hold"
	handle.label = "shutter"
	handle.verb = "hold up"
	handle.work_s = 1.4
	handle.close_s = 0.45
	handle.stand = Vector3(1.0, 0, 0)
	handle.add_child(Build.box(Vector3(0.12, 0.5, 0.12), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3.ZERO, Vector3.ZERO, "Grip"))
	handle.add_child(b._box_shape(Vector3(0.4, 0.7, 0.4), Transform3D.IDENTITY))
	handle.position = Vector3(hx + 0.4, 1.1, hz + 0.6)
	# it rolls up into the doorway's top: the bottom edge rises, the rolled
	# part is out of sight (the collider just rises into the wall above)
	handle.on_amount = func(a: float):
		var lift := SHUTTER_UP * a
		shutter.position.y = lift
		look.scale.y = (2.2 - lift) / 2.2
	store.add_child(handle)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.6)
	light.light_energy = 1.0
	light.omni_range = 4.0
	light.position = Vector3(0, 2.2, 0)
	store.add_child(light)
	# the box of batteries, at the back: two to carry it
	box = Carryable.new()
	box.name = "BatteryBox"
	box.item_name = "box of torch batteries"
	box.kind = "batteries"
	box.two_handed = true
	box.mass = 26.0
	box.add_child(Build.box(Vector3(0.9, 0.45, 0.6), ToonMat.make(Color(0.95, 0.75, 0.2)), Vector3(0, 0.225, 0), Vector3.ZERO, "Box"))
	box.add_child(Build.label3d("BATTERIES", Vector3(0, 0.3, 0.31), Vector3.ZERO, 0.12, Color(0.15, 0.1, 0.05)))
	var bcs := CollisionShape3D.new()
	var bsh := BoxShape3D.new()
	bsh.size = Vector3(0.9, 0.45, 0.6)
	bcs.shape = bsh
	bcs.position = Vector3(0, 0.225, 0)
	box.add_child(bcs)
	b.world.add_child(box)
	_box_at = at + Vector3(-hx + 0.8, 0.05, 0)
	box.position = _box_at
	inside_box = AABB(at + Vector3(-hx + 0.1, -1.0, -hz + 0.1), Vector3(STORE.x - 0.2, 4.0, STORE.z - 0.2))
	b.poi["store"] = at
	b.poi["store_door"] = at + Vector3(hx + 1.5, 0, 0)
	b.poi["store_handle"] = handle.position + at
	b.poi["battery_box"] = _box_at


func inside(p: Node3D) -> bool:
	return inside_box.has_point(p.global_position + Vector3.UP * 0.5)


# --- N2, the boat ---------------------------------------------------------------------

func _boat(b) -> void:
	var shore := Bessi.shore_x(BOAT_Z)
	_boat_base = Vector3(shore - 12.0, 0, BOAT_Z)
	_boat_base.y = b._h(_boat_base.x, _boat_base.z)
	# the drum first, on the sand; the boat lies over it, one side propped on it
	drum = FuelDrum.create_drum()
	drum.name = "BoatDrum"
	b.world.add_child(drum)
	_drum_at = _boat_base + Vector3(0.3, 0.05, 0)
	drum.position = _drum_at
	drum.freeze = true
	boat = Workable.new()
	boat.name = "UpturnedBoat"
	boat.kind = "work"
	boat.label = "boat"
	boat.verb = "push"
	boat.need_hands = 3
	boat.work_s = 5.0
	boat.set_meta("tag_name", "the upturned boat")
	# players push from the landward side, towards the sea; Naresh at first
	# goes round the other side and pushes back
	boat.stand = Vector3(-2.4, 0, 0)
	boat.stand_fn = func(who) -> Vector3:
		return boat.global_transform * Vector3(2.9 if (who is Naresh and naresh_wrong) else -2.7, 0, 1.2 if who is Naresh else 0.0)
	boat.helps = func(who) -> bool:
		return not (who is Naresh and naresh_wrong)
	boat_body = Node3D.new()
	boat_body.name = "Hull"
	boat.add_child(boat_body)
	var hull := ToonMat.make(Color(0.25, 0.45, 0.70), 0.02)
	boat_body.add_child(Build.box(Vector3(2.0, 0.9, 6.0), hull, Vector3(0, 0.45, 0), Vector3.ZERO, "Hull"))
	boat_body.add_child(Build.box(Vector3(0.2, 0.2, 6.2), ToonMat.make(Color(0.85, 0.40, 0.25)), Vector3(0, 0.95, 0), Vector3.ZERO, "Keel"))
	boat_body.rotation.z = deg_to_rad(-14.0)     # one side up on the drum
	# upright, round the tilted hull: a tilted box reached down into where
	# Naresh stood on the far side and wedged him fast
	boat.add_child(b._box_shape(Vector3(2.3, 1.3, 6.0), Transform3D(Basis(), Vector3(0, 0.65, 0))))
	boat.position = _boat_base
	# while three push it rocks where it is (so nobody loses their grip on a
	# hull sliding away); when it gives, it slides off down the sand in one go
	boat.on_amount = func(a: float):
		if boat.is_done:
			return
		boat_body.rotation.x = sin(Time.get_ticks_msec() * 0.03) * 0.03 * a
	boat.finished.connect(_slide_off)
	boat.finished.connect(_drum_free)
	b.world.add_child(boat)
	b.poi["boat"] = _boat_base
	b.poi["boat_push"] = _boat_base + Vector3(-2.6, 0, 0)
	b.poi["drum"] = _drum_at


func _slide_off() -> void:
	boat_body.rotation.x = 0.0
	var tw := boat.create_tween()
	tw.set_parallel(true)
	tw.tween_property(boat, "position", _boat_base + Vector3(BOAT_SLIDE, 0, 0), 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(boat_body, "rotation:z", 0.0, 2.0)
	Sfx.play3d("hit_wood_heavy", boat.global_position + Vector3.UP, 4.0)


func _drum_free() -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null:
		st.flags["drum_free"] = true
	drum.freeze = false
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say("The boat grinds off down the sand. Under it: a blue fuel drum, full. It'll take two to carry.", 6.0)


# --- the frame --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	var boot := get_tree().current_scene
	if st == null or boot == null or st.index_of("batteries") < 0:
		return
	var nz: Naresh = boot.naresh
	_n1(delta, st, nz, boot)
	_n2(st, nz)
	# the drum stays put under the boat until it's off
	if not boat.is_done and drum.holders.is_empty():
		drum.freeze = true


func _n1(delta: float, st: Story, nz: Naresh, boot) -> void:
	# the box carried out: the batteries are yours
	if not st.flags.has("batteries_got") and not box.holders.is_empty() and not inside(box) \
			and box.global_position.distance_to(store.global_position) > 3.0:
		st.flags["batteries_got"] = true
		for n in get_tree().get_nodes_in_group("player"):
			var p := n as PlayerRig
			p.flashlight_seconds = 600.0
			p.say("A whole box of torch batteries. Fresh ones in both your torches now, and plenty for the dark road.", 6.0)
	if nz == null or not is_instance_valid(nz):
		return
	# the scripted slip, once: he holds it, you're both inside, he lets go
	if _back_t >= 0.0:
		_back_t -= delta
		if _back_t < 0.0:
			var p: PlayerRig = boot.players[0]
			nz.command(p, "hold", handle)
			nz.say("Sorry! Sorry. Got it. Come on out.")
		return
	if st.flags.has("n1_slip"):
		return
	var holding := nz.state == Naresh.State.JOB and nz.job == "hold" and nz.job_target == handle and handle.amount >= 0.99
	var both_in := true
	for n in get_tree().get_nodes_in_group("player"):
		both_in = both_in and inside(n as Node3D)
	if holding and both_in:
		_slip_t += delta
		if _slip_t >= SLIP_AFTER:
			st.flags["n1_slip"] = true
			nz.command(nz.job_for, "wait")
			nz.say("Oops! My friend was telling me something...")
			Sfx.play3d("bang", store.global_position + Vector3.UP, 4.0)
			_back_t = SLIP_BACK
	else:
		_slip_t = 0.0


func _n2(st: Story, nz: Naresh) -> void:
	if nz == null or not is_instance_valid(nz) or boat.is_done:
		naresh_wrong = false
		return
	var on_boat := nz.state == Naresh.State.JOB and nz.job == "work" and nz.job_target == boat
	if on_boat and not st.flags.has("n2_wrong_done") and _wrong_at < 0:
		# the first time: round the far side, pushing back
		naresh_wrong = true
		_wrong_at = nz.commands_given
		nz.say("Pushing! Is it moving? It's not moving.")
	elif naresh_wrong and nz.commands_given > _wrong_at:
		# told again: the right side now
		naresh_wrong = false
		st.flags["n2_wrong_done"] = true
		nz.say("Oh! THAT way. Right.")


# --- the story jumped (F1) ------------------------------------------------------------

func match_story() -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	var got := st != null and st.flags.has("batteries_got")
	var free := st != null and st.flags.has("drum_free")
	_slip_t = 0.0
	_back_t = -1.0
	_wrong_at = -1
	naresh_wrong = false
	for h in box.holders.duplicate():
		h.drop_held()
	box.global_position = _box_at if not got else store.global_position + Vector3(STORE.x * 0.5 + 3.0, 0.1, 0)
	box.linear_velocity = Vector3.ZERO
	box.reset_physics_interpolation()
	boat.amount = 1.0 if free else 0.0
	boat.is_done = free
	boat.position = _boat_base + (Vector3(BOAT_SLIDE, 0, 0) if free else Vector3.ZERO)
	boat_body.rotation = Vector3(0, 0, 0.0 if free else deg_to_rad(-14.0))
	for h in drum.holders.duplicate():
		h.drop_held()
	if drum.stowed_in != null:
		drum.unstow()
	drum.litres = FuelDrum.DRUM_L
	drum.global_position = _drum_at
	drum.linear_velocity = Vector3.ZERO
	drum.freeze = not free
	drum.reset_physics_interpolation()
