class_name RadioMast
extends Node

## F7, the finale: point the dishes home (design/RETURN.md, decision 2). The
## relay mast on Radio Hill above the coast road. No road goes up: you walk.
## 1. Power: its generator is pull-started; one pulls the cord, the other
##    holds the choke (a cord pulled without it splutters out). It runs loud:
##    two creatures come for the noise. Far off, three red relay beacons
##    blink on: the targets.
## 2. The plaque says where each dish must face: the tunnel mouth, the house
##    on the ridge (Naresh's home), the watchtower on the West Road (home).
##    From the platform up the ladder you can see all three (tag them).
## 3. Each dish turns with its crank at the foot (always the same way, round
##    and round). A screen at the foot shows what the last-turned dish sees.
##    Naresh can take a crank; the first time he turns it backwards until
##    he's told again. Let go with a dish on its beacon (within LOCK_DEG)
##    and it locks, its lamp green.
## All three locked: the mast hums, and the clouds break over the West Road.
##
## State in the story's flags: "gen_running", "dish_1".."dish_3", "mast_done".

const PLAT_Y := 20.0
const DISH_Y := [17.4, 18.2, 19.0]
const CRANK_DEG := 8.0                 ## deg/s a dish turns while its crank is held
const LOCK_DEG := 3.0
const LOCK_AFTER := 0.8                ## s let go on target before it locks
const GEN_NOISE := 70.0                ## m: who hears it running
const SCREEN_EVERY := 6                ## the screen redraws every this many frames (a whole extra render)
var screen_on := true                  ## tests measure the frame rate without it
const TARGETS := ["the tunnel mouth", "the house on the ridge", "the watchtower on the West Road"]

var foot := Vector3.ZERO
var dishes: Array[Node3D] = []         ## yaw pivots
var cranks: Array[Workable] = []
var locked := [false, false, false]
var yaw := [0.0, 0.0, 0.0]             ## each dish's world yaw (radians)
var targets: Array[Vector3] = []
var cord: Workable
var choke: Workable
var running := false
var creatures: Array[Creature] = []
var screen_dish := 0
var _lamps: Array[MeshInstance3D] = []
var _beacons: Array[Node3D] = []
var _view: SubViewport
var _cam: Camera3D
var _frame := 0
var _hum: NoiseLoop
var _noise_t := 0.0
var _off_t := [0.0, 0.0, 0.0]
var _wrong := -1                       ## the crank Naresh first turns backwards (-1 none)
var _wrong_cmds := 0
var _wrong_done := false
var _story: Story
var _green: StandardMaterial3D
var _red: StandardMaterial3D


func setup(b) -> void:
	add_to_group("radio_mast")
	foot = b.poi["radio_mast"]
	_green = ToonMat.flat(Color(0.3, 0.95, 0.4))
	_red = ToonMat.flat(Color(0.9, 0.2, 0.15))
	_platform(b)
	_targets(b)
	_dishes(b)
	_generator(b)
	_screen(b)
	_creatures(b)
	# the coast road below: the nearest stretch (scanned: Route.nearest only
	# searches the cells round a point)
	var road: Route = b.network.road("coast_road")
	var best := INF
	var at := Vector3.ZERO
	for i in road.point_count():
		var q := road.point(i)
		var d := Vector2(q.x - foot.x, q.z - foot.z).length()
		if d < best:
			best = d
			at = q
	b.poi["mast_road"] = at
	b.poi["mast_foot"] = foot + Vector3(-3.0, 0.2, 3.0)


func _platform(b) -> void:
	var steel := ToonMat.make(Color(0.45, 0.47, 0.50))
	var body := StaticBody3D.new()
	body.name = "MastPlatform"
	body.position = foot
	b.world.add_child(body)
	var deck := Vector3(4.4, 0.2, 4.4)
	body.add_child(Build.box(deck, steel, Vector3(0, PLAT_Y - 0.1, 0), Vector3.ZERO, "Deck"))
	body.add_child(b._box_shape(deck, Transform3D(Basis(), Vector3(0, PLAT_Y - 0.1, 0))))
	# rails round three sides and half the fourth (the ladder comes up there)
	for spec in [[Vector3(4.4, 1.0, 0.08), Vector3(0, PLAT_Y + 0.5, -2.2)], [Vector3(0.08, 1.0, 4.4), Vector3(-2.2, PLAT_Y + 0.5, 0)],
			[Vector3(0.08, 1.0, 4.4), Vector3(2.2, PLAT_Y + 0.5, 0)], [Vector3(1.6, 1.0, 0.08), Vector3(-1.4, PLAT_Y + 0.5, 2.2)],
			[Vector3(1.6, 1.0, 0.08), Vector3(1.4, PLAT_Y + 0.5, 2.2)]]:
		body.add_child(Build.box(spec[0], steel, spec[1], Vector3.ZERO, "Rail"))
		body.add_child(b._box_shape(spec[0], Transform3D(Basis(), spec[1])))
	var root := Node3D.new()
	root.name = "MastLadderRoot"
	root.position = foot
	b.world.add_child(root)
	Ladder.make(root, Vector3(0, 0, 2.62), PLAT_Y + 0.05, Vector3(0, 0, -1), Vector3(0, PLAT_Y + 0.1, 1.6), "MastLadder")
	b.poi["mast_platform"] = foot + Vector3(0, PLAT_Y + 0.1, 1.2)


func _targets(b) -> void:
	var house: Vector3 = b.poi["naresh_home"]
	var tower: Vector3 = b.poi["end_tower"]
	var pts := [b.poi["tunnel_portal"] + Vector3.UP * 8.0, house + Vector3.UP * 8.0, tower + Vector3.UP * 14.0]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.18, 0.12)
	mat.disable_fog = true
	for k in pts.size():
		var at: Vector3 = pts[k]
		targets.append(at)
		# a holder we show and hide; the Spinner inside blinks itself
		var holder := Node3D.new()
		holder.name = "RelayBeacon%d" % (k + 1)
		holder.position = at
		holder.visible = false
		holder.set_meta("tag_name", TARGETS[k])
		holder.add_to_group("far_tag")
		b.world.add_child(holder)
		var bc := Spinner.new()
		bc.name = "Blink"
		bc.blink_period = 1.4 + k * 0.3
		holder.add_child(bc)
		# big enough to show as a point at 2 km
		bc.add_child(Build.sphere(0.9 + k * 0.6, mat, Vector3.ZERO, Vector3.ONE, "Light"))
		_beacons.append(holder)
		b.poi["dish_target_%d" % (k + 1)] = at


func _dishes(b) -> void:
	var white := ToonMat.make(Color(0.88, 0.88, 0.86))
	var grey := ToonMat.make(Color(0.4, 0.4, 0.42))
	for k in 3:
		var piv := Node3D.new()
		piv.name = "Dish%d" % (k + 1)
		piv.position = foot + Vector3(0, DISH_Y[k], 0)
		b.world.add_child(piv)
		piv.add_child(Build.box(Vector3(0.12, 0.12, 1.6), grey, Vector3(0, 0, -0.8), Vector3.ZERO, "Arm"))
		piv.add_child(Build.cyl(0.85, 0.18, white, Vector3(0, 0, -1.7), Vector3(90, 0, 0), 16, "Dish"))
		piv.add_child(Build.box(Vector3(0.08, 0.08, 0.7), grey, Vector3(0, 0, -2.1), Vector3.ZERO, "Feed"))
		piv.add_child(Build.label3d(str(k + 1), Vector3(0, 0, -1.58), Vector3.ZERO, 0.4, Color(0.15, 0.15, 0.15)))
		# start pointed well off its target, a different way each
		var want := _bearing(k)
		yaw[k] = want + deg_to_rad(110.0 + k * 70.0)
		piv.rotation.y = yaw[k]
		dishes.append(piv)


func _bearing(k: int) -> float:
	var t := targets[k] - (foot + Vector3(0, DISH_Y[k], 0))
	return atan2(-t.x, -t.z)


func _generator(b) -> void:
	var steel := ToonMat.make(Color(0.35, 0.45, 0.30))
	var at := foot + Vector3(4.0, 0, 2.2)          # by the hut
	at.y = b._h(at.x, at.z)
	var gen := StaticBody3D.new()
	gen.name = "Generator"
	gen.position = at
	b.world.add_child(gen)
	gen.add_child(Build.box(Vector3(1.4, 0.9, 0.8), steel, Vector3(0, 0.45, 0), Vector3.ZERO, "Engine"))
	gen.add_child(b._box_shape(Vector3(1.4, 0.9, 0.8), Transform3D(Basis(), Vector3(0, 0.45, 0))))
	gen.add_child(Build.label3d("GENERATOR\nCHOKE + PULL CORD", Vector3(0, 1.15, 0.42), Vector3.ZERO, 0.035, Color(1, 0.95, 0.8)))
	cord = _handle(b, "PullCord", "pull cord", "pull", at + Vector3(0.45, 0.7, 0.55), 1.2, 0.2)
	choke = _handle(b, "Choke", "choke", "hold", at + Vector3(-0.5, 0.7, 0.55), 0.5, 0.3)
	b.poi["generator"] = at + Vector3(0, 0.2, 1.4)


func _handle(b, nm: String, label: String, verb: String, at: Vector3, work: float, back: float) -> Workable:
	var w := Workable.new()
	w.name = nm
	w.kind = "hold"
	w.label = label
	w.verb = verb
	w.work_s = work
	w.close_s = back
	w.stand = Vector3(0, -0.7, 0.8)        # (the handles are 0.7 m up)
	w.add_child(Build.box(Vector3(0.18, 0.1, 0.1), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3.ZERO, Vector3.ZERO, "Grip"))
	w.add_child(b._box_shape(Vector3(0.35, 0.3, 0.3), Transform3D.IDENTITY))
	w.position = at
	w.set_meta("tag_name", "the " + label)
	b.world.add_child(w)
	return w


func _screen(b) -> void:
	var at := foot + Vector3(-2.6, 0, 1.6)
	at.y = b._h(at.x, at.z)
	var steel := ToonMat.make(Color(0.3, 0.32, 0.34))
	var stand := StaticBody3D.new()
	stand.name = "DishControls"
	stand.position = at
	b.world.add_child(stand)
	stand.add_child(Build.box(Vector3(3.6, 1.0, 0.5), steel, Vector3(0, 0.5, 0), Vector3.ZERO, "Desk"))
	stand.add_child(b._box_shape(Vector3(3.6, 1.0, 0.5), Transform3D(Basis(), Vector3(0, 0.5, 0))))
	_view = SubViewport.new()
	_view.size = Vector2i(256, 144)
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_view.world_3d = null
	stand.add_child(_view)
	_cam = Camera3D.new()
	_cam.fov = 14.0
	_cam.far = 2600.0
	_view.add_child(_cam)
	var tex_mat := StandardMaterial3D.new()
	tex_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tex_mat.albedo_texture = _view.get_texture()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 0.9)
	var scr := Build.node(q, tex_mat, Transform3D(Basis(), Vector3(0, 1.75, 0.0)), "Screen")
	stand.add_child(scr)
	stand.add_child(Build.box(Vector3(1.7, 1.0, 0.1), steel, Vector3(0, 1.75, -0.08), Vector3.ZERO, "Frame"))
	var plaque := "RADIO HILL RELAY\nDISH 1: THE TUNNEL MOUTH\nDISH 2: THE HOUSE ON THE RIDGE\nDISH 3: THE WATCHTOWER ON THE WEST ROAD"
	stand.add_child(Build.label3d(plaque, Vector3(0, 2.45, 0.05), Vector3.ZERO, 0.035, Color(1, 0.95, 0.8)))
	# the three cranks along the desk, each with its lamp
	for k in 3:
		var c := Workable.new()
		c.name = "DishCrank%d" % (k + 1)
		c.kind = "hold"
		c.label = "dish %d crank" % (k + 1)
		c.verb = "turn"
		c.work_s = 0.3
		c.close_s = 0.3
		c.stand = Vector3(0, -1.15, 0.9)       # on the ground in front of the desk
		var wheel := Node3D.new()
		wheel.name = "Wheel"
		c.add_child(wheel)
		wheel.add_child(Build.cyl(0.25, 0.05, ToonMat.make(Color(0.8, 0.8, 0.82)), Vector3.ZERO, Vector3(90, 0, 0), 12, "Rim"))
		wheel.add_child(Build.box(Vector3(0.05, 0.05, 0.22), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3(0.21, 0, 0.11), Vector3.ZERO, "Knob"))
		c.add_child(b._box_shape(Vector3(0.6, 0.6, 0.5), Transform3D.IDENTITY))
		c.position = at + Vector3(-1.2 + k * 1.2, 1.15, 0.3)
		c.set_meta("tag_name", "the dish %d crank" % (k + 1))
		b.world.add_child(c)
		cranks.append(c)
		var lamp := Build.sphere(0.07, _red, at + Vector3(-1.2 + k * 1.2, 1.5, 0.3), Vector3.ONE, "Lamp%d" % (k + 1))
		b.world.add_child(lamp)
		_lamps.append(lamp)
		b.poi["dish_crank_%d" % (k + 1)] = c.position
	b.poi["dish_screen"] = at + Vector3(0, 1.75, 0)


func _creatures(b) -> void:
	for spec in [Vector3(-150, 0, 40), Vector3(60, 0, -140)]:
		var cr := Creature.new()
		cr.name = "MastCreature"
		cr.dormant = true
		var at: Vector3 = foot + spec
		at.y = b._h(at.x, at.z) + 0.3
		b.world.add_child(cr)
		cr.position = at
		creatures.append(cr)


# --- running it -------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
		match_story()
	if _story.flags.has("mast_done"):
		return
	if not running:
		_try_start()
		return
	# it runs loud
	_noise_t -= delta
	if _noise_t <= 0.0:
		_noise_t = 0.5
		Hearing.emit(cord.global_position, GEN_NOISE, "engine")
	var boot := get_tree().current_scene
	var nz: Naresh = boot.get("naresh")
	for k in 3:
		if locked[k]:
			continue
		var c := cranks[k]
		if c.holding_now():
			var dir := 1.0
			if nz != null and is_instance_valid(nz) and nz in c.holders_now() and not _wrong_done:
				if _wrong < 0:
					_wrong = k
					_wrong_cmds = nz.commands_given
					nz.say("Turning! Is it going the right way? It looks the right way.")
				if _wrong == k:
					dir = -1.0
			yaw[k] = wrapf(yaw[k] + deg_to_rad(CRANK_DEG) * dir * delta, -PI, PI)
			dishes[k].rotation.y = yaw[k]
			screen_dish = k
			_off_t[k] = 0.0
		else:
			if absf(rad_to_deg(angle_difference(yaw[k], _bearing(k)))) < LOCK_DEG:
				_off_t[k] += delta
				if _off_t[k] >= LOCK_AFTER:
					_lock(k, true)
	if nz != null and is_instance_valid(nz) and _wrong >= 0 and not _wrong_done and nz.commands_given > _wrong_cmds:
		_wrong_done = true
		nz.say("Oh! The OTHER way. Right.")
	if locked[0] and locked[1] and locked[2]:
		_done(true)


func _process(_delta: float) -> void:
	_update_screen()


func _try_start() -> void:
	if cord.amount < 0.99:
		return
	if choke.holding_now() and choke.amount > 0.6:
		_start(true)
	elif cord.amount >= 0.99 and not cord.has_meta("spluttered"):
		cord.set_meta("spluttered", true)
		cord.amount = 0.0
		Sfx.play3d("bang", cord.global_position, -8.0)
		_tell_near("It coughs, catches for a second, and dies. Someone needs to hold the choke while the cord's pulled.", 5.0)


func _start(tell: bool) -> void:
	running = true
	_story.flags["gen_running"] = true
	for bc in _beacons:
		bc.visible = true
	if _hum == null:
		_hum = NoiseLoop.new()
		_hum.kind = NoiseLoop.Kind.HUM
		_hum.volume_db = -6.0
		add_child(_hum)
		_hum.global_position = cord.global_position
	_hum.target = 0.8
	for cr in creatures:
		cr.dormant = false
		cr.patrol = PackedVector3Array([cord.global_position + Vector3(0, 0, 6.0)])
	if tell:
		Sfx.play3d("bang", cord.global_position, 2.0)
		_tell_near("The generator roars into life, loud on the quiet hill. Far off, three red relay beacons blink on. The screen at the foot lights up.", 7.0)


func _lock(k: int, tell: bool) -> void:
	locked[k] = true
	yaw[k] = _bearing(k)
	dishes[k].rotation.y = yaw[k]
	_lamps[k].material_override = _green
	_story.flags["dish_%d" % (k + 1)] = true
	if tell:
		Sfx.play3d("latch", dishes[k].global_position, 0.0)
		_tell_near("Dish %d locks on %s. Its lamp goes green." % [k + 1, TARGETS[k]], 4.0)


func _done(tell: bool) -> void:
	_story.flags["mast_done"] = true
	if _hum != null:
		_hum.pitch = 1.6
	for cr in creatures:
		cr.scare(foot, 120.0)
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.target = maxf(mood.target, 0.5)
	if tell:
		_tell_near("All three dishes lock. The mast hums, a deep note through the hill, and away to the west the clouds break over the West Road. The way home.", 8.0)


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(foot) < 90.0:
			q.say(text, secs)


## Like the van's mirrors: drawn only with someone near, every third frame.
func _update_screen() -> void:
	if _view == null or not running or not screen_on:
		if _view != null:
			_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var near := false
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(foot) < 14.0:
			near = true
	if not near:
		_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_frame += 1
	if _frame % SCREEN_EVERY != 0:
		return
	var k := screen_dish
	_cam.global_transform = Transform3D(Basis(Vector3.UP, yaw[k]), dishes[k].global_position + Basis(Vector3.UP, yaw[k]) * Vector3(0, 0.4, -2.4))
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE


## After a load or a story jump.
func match_story() -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
	if _story == null:
		return
	if _story.flags.has("gen_running") and not running:
		_start(false)
	elif not _story.flags.has("gen_running") and running:
		running = false
		for bc in _beacons:
			bc.visible = false
		if _hum != null:
			_hum.target = 0.0
		for cr in creatures:
			cr.dormant = true
	for k in 3:
		var on := _story.flags.has("dish_%d" % (k + 1))
		if on and not locked[k]:
			_lock(k, false)
		elif not on and locked[k]:
			locked[k] = false
			_lamps[k].material_override = null
			yaw[k] = _bearing(k) + deg_to_rad(110.0 + k * 70.0)
			dishes[k].rotation.y = yaw[k]
