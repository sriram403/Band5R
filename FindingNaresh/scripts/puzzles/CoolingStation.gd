class_name CoolingStation
extends Node3D

## The water works co-op puzzle (built in the facility's local frame, -Z
## toward the river). Reworked for Milestone G (the user, 2026-10-05,
## `design/PUZZLE_CHANGES.md` #1): the two players can't see each other's
## side, and every mistake has a quick, messy consequence.
##
## THE PUMP ROOM. The pumper works the hand pump inside the brick pump house:
## press E each time the lever comes back up (a stroke). Strokes raise the
## pressure; keep the needle in the green. Rushing a stroke (pressing before
## the lever is back up) jerks the pressure up; too much pops the relief
## valve and stalls the pump. The flow lamp lights while water moves, but
## never says which tank. There is no window onto the yard. The door is
## padlocked; the key hangs on the catwalk at the top of the water tower.
##
## THE TANK YARD. The valve player sets valves A and B by following the
## grey pipes, and reads both tanks' sight glasses. Only they know where the
## water is going; only the pumper knows the pressure. So they talk.
##
## THE GREY (SLUDGE) TANK fills fast: about 2 s of pumping on the wrong route
## (3 strokes). It gurgles at three quarters; full, it groans for 2 s, then
## its lid blows and sludge rains over the yard: everyone in the yard is
## covered (slow motion for ~25 s, `PlayerRig.slime`), and the tank is empty
## again. The pumper inside only hears it, and the line clogs: the lever goes
## slack for 4 s. A standpipe in the yard rinses you off (hold E, 3 s).
##
## THE GULP. Turning a valve while the line is under pressure sends a fifth
## of the blue tank back into the grey one. So it's "stop pumping!" before
## every turn. Valve B's worn seat (its plate says so) kicks it back to the
## overflow twice while the blue tank fills, and each slip gulps too.
##
## Filling the blue tank dispenses a coolant jug and a Memory Fragment.

signal solved_changed

const GREEN_LO := 0.40
const GREEN_HI := 0.85
const STROKE := 0.6           ## s: one stroke of the lever, down and back up
const STROKE_RISE := 0.14     ## pressure per stroke, in rhythm
const RUSHED_RISE := 0.24     ## pressure per stroke pressed before the lever is back up
const RUSH_WINDOW := 0.3      ## a press with more than this much of the stroke left is rushed
const LEAK_FALL := 0.10       ## pressure lost per second, always
const OVERFLOW_FALL := 0.30   ## the overflow route has a free outlet: pressure never builds
const FILL_RATE := 1.0 / 15.0 ## blue tank per second of water moving in the green (~15 s)
const GREY_RATE := 0.5        ## grey tank per second of water moving its way (~2 s)
const GREY_DRAIN := 0.02      ## the grey tank seeps back down when nothing flows
const GULP_BLUE := 0.2        ## a valve turned under pressure: this much of the blue tank...
const GULP_GREY := 0.35       ## ...surges back into the (smaller) grey one
const GROAN_S := 2.0          ## the full grey tank strains this long before it bursts
const CLOG_S := 4.0           ## after a burst the line is full of sludge: the lever goes slack
const SLIME_S := 25.0         ## how long the sludge slows you (the last 5 s easing back)
const RINSE_S := 3.0          ## at the standpipe
const STALL_TIME := 3.5
## Blue-tank levels at which valve B kicks back to the overflow.
const SLIP_AT: Array[float] = [0.34, 0.67]

## Which outlet each valve points at. Correct: A -> "b" (on to valve B), B -> "coolant".
var valve_a := "waste"        ## "waste" | "b"
var valve_b := "overflow"     ## "coolant" | "overflow"
var pressure := 0.0
var fill := {"waste": 0.0, "coolant": 0.0}
var stalled := 0.0
var solved := false
var pops := 0                 ## relief valve pops, for the play-test
var slips := 0                ## times valve B has kicked back so far
var bursts := 0               ## times the grey tank has burst, for the play-test
var gulps := 0                ## valve turns under pressure, for the play-test
var rushed := 0               ## rushed strokes, for the play-test
var clog := 0.0               ## s left with the line full of sludge
var groan := 0.0              ## s left before the full grey tank bursts (0 = not groaning)
var key_taken := false
var key_by := -1              ## which player has the key (their index)
var door_open := false
## Valve B slips (1, always in play) or holds (0: the play-test's older
## checks, which pump without anyone at the valves).
var co_op := 1

var _jug: Node3D = null       ## the reward still lying at the tap (a reset clears it)
var _frag: Node3D = null
var _lever := 0.0             ## s left in the current stroke (0 = the lever is up, ready)
var _gurgled := false         ## the three-quarters gurgle, once per filling
var _needle: Node3D
var _lamp_green: MeshInstance3D
var _level_bars := {}
var _wheel_a: Node3D
var _wheel_b: Node3D
var _handle: Node3D
var _puff: CPUParticles3D
var _sludge: CPUParticles3D
var _rinse_spray: CPUParticles3D
var _rinse_t := 0.0
var _hatch: Node3D
var _puddle: MeshInstance3D
var _door: Node3D
var _door_body: StaticBody3D
var _key: Node3D
var _mat_on: StandardMaterial3D
var _mat_off: StandardMaterial3D
var _hiss: NoiseLoop

const PUMP_POS := Vector3(-3.5, 0, 5.0)      ## inside the pump house, the lever towards the front
const GAUGE_POS := Vector3(-3.5, 0, 5.4)     ## right above the pump: watch it while you pump
const A_POS := Vector3(2.5, 0, -3.0)
const B_POS := Vector3(8.0, 0, -3.0)
const WASTE_TANK := Vector3(5.0, 0, 5.0)
const COOLANT_TANK := Vector3(10.5, 0, 5.0)
const PIPE_Y := 0.45
const DOOR_HINGE := Vector3(-0.62, 0, 1.0)   ## the doorway's front edge, in the yard-side wall (LevelLandmarks)
const DOOR_SHUT := -PI * 0.5                 ## the door lies along +Z, shut
const DOOR_OPEN := 0.0                       ## swung out into the yard
const TOWER := Vector3(-12.0, 0, -6.0)       ## the water tower (LevelLandmarks)
const KEY_POS := Vector3(-12.0 + 4.62, 15.6, -6.0)   ## on the tank wall, facing the yard
const TAP_POS := Vector3(0.6, 0, 7.6)        ## the yard's standpipe
## The tank yard (local): covered by the sludge, the pump house left out.
const YARD_MIN := Vector3(-12.5, -1.0, -11.0)
const YARD_MAX := Vector3(13.0, 4.0, 10.5)
const HOUSE_MIN := Vector3(-9.5, -1.0, 0.5)
const HOUSE_MAX := Vector3(-0.5, 6.0, 7.5)


func _ready() -> void:
	add_to_group("cooling_station")
	_mat_on = ToonMat.flat(Color(0.35, 1.0, 0.45))
	_mat_off = ToonMat.flat(Color(0.12, 0.22, 0.14))
	_build_pipes()
	_build_pump()
	_build_gauge()
	_wheel_a = _build_valve("A", A_POS, func(p): _turn("a", p))
	_wheel_b = _build_valve("B", B_POS, func(p): _turn("b", p))
	_build_levels()
	_build_door()
	_build_key()
	_build_tap()
	_build_sludge()
	_update_pointers()


# --- the puzzle ----------------------------------------------------------------

func route() -> String:
	if valve_a == "waste":
		return "waste"
	return "coolant" if valve_b == "coolant" else "overflow"


## Water is moving while the lever is on a stroke.
func flowing() -> bool:
	return _lever > 0.0 and stalled <= 0.0 and clog <= 0.0


func _physics_process(delta: float) -> void:
	var moving := flowing()
	_lever = maxf(0.0, _lever - delta)
	if _hiss:
		_hiss.target = maxf(0.0, _hiss.target - delta * 0.5)
	if stalled > 0.0:
		stalled -= delta
	if clog > 0.0:
		clog -= delta
		pressure = 0.0
		if clog <= 0.0:
			_tell_inside("The lever bites again: the line's clear.", 3.0)
	var r := route()
	pressure -= LEAK_FALL * delta
	if r == "overflow":
		pressure -= OVERFLOW_FALL * delta
	pressure = clampf(pressure, 0.0, 1.1)
	if pressure >= 1.0:
		_pop()
	if moving and not solved:
		if r == "waste" and groan <= 0.0:
			fill["waste"] = minf(1.0, fill["waste"] + GREY_RATE * delta)
		elif r == "coolant" and pressure >= GREEN_LO and pressure <= GREEN_HI:
			fill["coolant"] = minf(1.0, fill["coolant"] + FILL_RATE * delta)
			if fill["coolant"] >= 1.0:
				_solve()
			elif slips < SLIP_AT.size() and fill["coolant"] >= SLIP_AT[slips] and co_op == 1:
				_slip()
	elif not moving and groan <= 0.0:
		fill["waste"] = maxf(0.0, fill["waste"] - GREY_DRAIN * delta)
	_grey_tank(delta)
	_rinse_t = maxf(0.0, _rinse_t - delta)
	if _rinse_spray:
		_rinse_spray.emitting = _rinse_t > 0.0
	_update_visuals(delta)


## The grey tank: the gurgle, the groan, the burst.
func _grey_tank(delta: float) -> void:
	if fill["waste"] >= 0.75 and not _gurgled:
		_gurgled = true
		Sfx.play3d("gurgle", global_transform * (WASTE_TANK + Vector3(0, 4.0, 0)), 2.0)
	if fill["waste"] < 0.5:
		_gurgled = false
	if groan > 0.0:
		groan -= delta
		if _hatch:
			_hatch.position = WASTE_TANK + Vector3(randf_range(-0.04, 0.04), 5.62 + randf_range(0.0, 0.06), randf_range(-0.04, 0.04))
		if groan <= 0.0:
			_burst()
	elif fill["waste"] >= 1.0:
		groan = GROAN_S
		Sfx.play3d("groan", global_transform * (WASTE_TANK + Vector3(0, 4.0, 0)), 4.0)


## One press of E on the pump: a stroke of the lever.
func stroke(p) -> void:
	if stalled > 0.0:
		return
	if clog > 0.0:
		Sfx.play3d("hit_soft", global_transform * (PUMP_POS + Vector3(0, 1.0, 0)), -6.0)
		if p != null:
			p.say("The lever's gone slack: sludge in the line. Give it a moment.", 2.5)
		return
	if _lever > STROKE - 0.1:
		return        # the same press read twice: a stroke has only just begun
	if _lever > STROKE * RUSH_WINDOW:
		pressure += RUSHED_RISE
		rushed += 1
		Sfx.play3d("hit_metal", global_transform * (PUMP_POS + Vector3(0, 1.0, 0)), -6.0, 0.15)
	else:
		pressure += STROKE_RISE
	_lever = STROKE
	Sfx.play3d("creak", global_transform * (PUMP_POS + Vector3(0, 1.0, 0)), -4.0, 0.15)


func _turn(which: String, p) -> void:
	if which == "a":
		valve_a = "b" if valve_a == "waste" else "waste"
	else:
		valve_b = "overflow" if valve_b == "coolant" else "coolant"
	_update_pointers()
	var at := A_POS if which == "a" else B_POS
	Sfx.play3d("latch", global_transform * at, -2.0)
	Sfx.play3d("creak", global_transform * at, -8.0, 0.2)
	if not solved and (pressure > 0.2 or flowing()):
		_gulp(p, "Glug: turned under pressure, water surges back out of the blue tank into the grey one. (Shout \"stop pumping!\" before you turn a valve.)" if gulps == 0 else "Glug: blue water back into the grey tank.")


## A fifth of the blue tank back into the grey one.
func _gulp(p, text: String) -> void:
	gulps += 1
	var moved := minf(fill["coolant"], GULP_BLUE)
	if moved <= 0.0:
		return
	fill["coolant"] -= moved
	if groan <= 0.0:
		fill["waste"] = minf(1.0, fill["waste"] + GULP_GREY * moved / GULP_BLUE)
	Sfx.play3d("gurgle", global_transform * (WASTE_TANK + Vector3(0, 3.0, 0)), 0.0)
	if p != null:
		p.say(text, 4.0)


## Valve B's worn seat gives way: it spins back to the overflow, and the
## kick gulps blue water back into the grey tank. The pump side sees the
## needle fall and the flow lamp go out; the valve side sees and hears it.
func _slip() -> void:
	slips += 1
	valve_b = "overflow"
	_update_pointers()
	var at := global_transform * (B_POS + Vector3(0, 1.0, 0))
	Sfx.play3d("bang", at, -6.0, 0.1)
	Sfx.play3d("latch", at, 0.0)
	Sfx.play3d("creak", at, -2.0, 0.3)
	var text := "CLANK! Valve B kicks back under the pressure and spins to the overflow, gulping blue water back into the grey tank. Turn it back - and stay by it." if slips == 1 else "CLANK! Valve B slips again. Turn it back!"
	for p in get_tree().get_nodes_in_group("player"):
		if (p as Node3D).global_position.distance_to(at) < 30.0 and in_yard(p):
			p.say(text, 4.0)
	_gulp(null, "")


func _pop() -> void:
	pressure = 0.3
	stalled = STALL_TIME
	pops += 1
	Sfx.play3d("bang", global_transform * PUMP_POS, 0.0)
	if _hiss:
		_hiss.target = 1.0
	if _puff:
		_puff.restart()
		_puff.emitting = true
	_tell_inside("BANG! The relief valve blows with a shriek of steam. The pump stalls - give it a moment. (Keep the needle in the green: don't rush the strokes.)", 5.0)


## The full grey tank's lid blows: sludge over the whole yard, the tank empty.
func _burst() -> void:
	groan = 0.0
	bursts += 1
	fill["waste"] = 0.0
	pressure = 0.0
	clog = CLOG_S
	var top := global_transform * (WASTE_TANK + Vector3(0, 5.6, 0))
	Sfx.play3d("splat", top, 8.0, 0.05)
	Sfx.play3d("bang", top, 2.0)
	if _sludge:
		_sludge.restart()
		_sludge.emitting = true
	if _hatch:
		var tw := create_tween()
		tw.tween_property(_hatch, "position", WASTE_TANK + Vector3(1.5, 11.0, 0.8), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_hatch, "position", WASTE_TANK + Vector3(0, 5.62, 0), 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if _puddle:
		_puddle.visible = true
		_puddle.transparency = 0.0
		var pw := create_tween()
		pw.tween_interval(10.0)
		pw.tween_property(_puddle, "transparency", 1.0, 8.0)
		pw.tween_callback(func(): _puddle.visible = false)
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if in_yard(p):
			p.slime(SLIME_S)
			p.say("SPLAT! The grey tank's lid blows off and sludge rains down over the whole yard. You're covered: everything's s-l-o-w until it dries. (Or rinse it off at the standpipe.)", 6.0)
		elif in_house(p):
			p.say("BOOM! Something outside bursts, and the needle drops dead. The lever goes slack.", 5.0)


## Inside the tank yard (and not up the water tower or in the pump house).
func in_yard(p: Node3D) -> bool:
	var l := global_transform.affine_inverse() * p.global_position
	var inside_yard := l.x > YARD_MIN.x and l.x < YARD_MAX.x and l.z > YARD_MIN.z and l.z < YARD_MAX.z and l.y < YARD_MAX.y and l.y > YARD_MIN.y
	return inside_yard and not in_house(p)


func in_house(p: Node3D) -> bool:
	var l := global_transform.affine_inverse() * p.global_position
	return l.x > HOUSE_MIN.x and l.x < HOUSE_MAX.x and l.z > HOUSE_MIN.z and l.z < HOUSE_MAX.z


func _tell_inside(text: String, secs: float) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if in_house(p as Node3D) or (p as Node3D).global_position.distance_to(global_transform * GAUGE_POS) < 4.0:
			p.say(text, secs)


func _solve() -> void:
	solved = true
	solved_changed.emit()
	Sfx.play3d("bong", global_transform * COOLANT_TANK, 0.0, 0.0)
	var tap_local := COOLANT_TANK + Vector3(0, 0.1, -2.9)
	var jug := CoolantJug.new()
	jug.name = "CoolantJug"
	get_tree().get_first_node_in_group("world_root").add_child(jug)
	jug.global_position = global_transform * tap_local
	_jug = jug
	var st = get_tree().current_scene.get("story")
	if st == null or not "water_works" in st.collected:
		var frag := MemoryFragment.create("water_works")
		get_tree().get_first_node_in_group("world_root").add_child(frag)
		frag.global_position = global_transform * (COOLANT_TANK + Vector3(-1.4, 0.4, -2.9))
		_frag = frag
	for p in get_tree().get_nodes_in_group("player"):
		p.say("The blue tank fills with a gurgle and the tap coughs out a jug of coolant mix. Something small and pink glints beside it.", 7.0)


# --- the key, the door, the standpipe -------------------------------------------

func _take_key(p) -> void:
	if key_taken:
		return
	key_taken = true
	key_by = p.index
	_key.visible = false
	Sfx.play3d("latch", global_transform * KEY_POS, -4.0)
	p.say("A big iron key on a ring, tagged PUMP HOUSE. It goes in your pocket.", 5.0)


func unlock(p) -> void:
	if door_open:
		return
	door_open = true
	Sfx.play3d("latch", global_transform * (DOOR_HINGE + Vector3(0, 1.2, 1.1)), 0.0)
	Sfx.play3d("door_open", global_transform * (DOOR_HINGE + Vector3(0, 1.2, 1.1)), 0.0)
	_door_body.collision_layer = 0
	var tw := create_tween()
	tw.tween_property(_door, "rotation:y", DOOR_OPEN, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if p != null:
		p.say("The padlock drops open. Inside: the pump, its pressure gauge, a kettle on the bench. No window onto the yard - you won't see the tanks from in here.", 7.0)


func _show_door() -> void:
	_door.rotation.y = DOOR_OPEN if door_open else DOOR_SHUT
	_door_body.collision_layer = 0 if door_open else 1
	_key.visible = not key_taken


## Rinse a covered player off at the standpipe (held E).
func rinse(p, dt: float) -> void:
	if p.slime_t <= 0.0:
		return
	_rinse_t = 0.2
	p.rinse(dt, RINSE_S, SLIME_S)


# --- F1 and saving ----------------------------------------------------------------

## F1 (Puzzles, or a story jump to the water works or before): back to how
## you first find it: the door locked, the key up the tower, the tanks
## empty. A jug or fragment still lying at the tap goes; one somebody
## carried off stays theirs. The turbine and lamps follow (`sync`).
func reset() -> void:
	valve_a = "waste"
	valve_b = "overflow"
	fill = {"waste": 0.0, "coolant": 0.0}
	pressure = 0.0
	stalled = 0.0
	clog = 0.0
	groan = 0.0
	_lever = 0.0
	solved = false
	slips = 0
	key_taken = false
	key_by = -1
	door_open = false
	for n in [_jug, _frag]:
		Workable.free_reward(n, global_transform * COOLANT_TANK, 6.0)
	_jug = null
	_frag = null
	for p in get_tree().get_nodes_in_group("player"):
		(p as PlayerRig).slime(0.0)
	_update_pointers()
	_show_door()
	_sync_line()


## F1: as if it had been done (a jump past it): the blue tank full, the door
## open, the power on, no reward handed out.
func solve_quietly() -> void:
	if solved:
		return
	valve_a = "b"
	valve_b = "coolant"
	fill["coolant"] = 1.0
	solved = true
	key_taken = true
	door_open = true
	_update_pointers()
	_show_door()
	_sync_line()


func _sync_line() -> void:
	var line := get_tree().get_first_node_in_group("power_line")
	if line != null:
		line.sync()


func to_dict() -> Dictionary:
	return {"valve_a": valve_a, "valve_b": valve_b, "fill_waste": fill["waste"],
		"fill_coolant": fill["coolant"], "solved": solved, "slips": slips,
		"key_taken": key_taken, "key_by": key_by, "door_open": door_open}


## Restore after a load. A solved station keeps its jug (restored as a normal
## item) and re-offers its fragment unless that was already picked up.
## Saves from before the pump house had a door load with it open.
func from_dict(d: Dictionary, collected: Array) -> void:
	valve_a = d.get("valve_a", valve_a)
	valve_b = d.get("valve_b", valve_b)
	fill["waste"] = float(d.get("fill_waste", 0.0))
	fill["coolant"] = float(d.get("fill_coolant", 0.0))
	solved = bool(d.get("solved", false))
	slips = int(d.get("slips", 0))
	door_open = bool(d.get("door_open", not d.has("key_taken")))
	key_taken = bool(d.get("key_taken", door_open))
	key_by = int(d.get("key_by", -1))
	pressure = 0.0
	stalled = 0.0
	clog = 0.0
	groan = 0.0
	_update_pointers()
	_show_door()
	if solved and not "water_works" in collected:
		var root := get_tree().get_first_node_in_group("world_root")
		if root.find_child("Fragment_water_works", true, false) == null:
			var frag := MemoryFragment.create("water_works")
			root.add_child(frag)
			frag.global_position = global_transform * (COOLANT_TANK + Vector3(-1.4, 0.4, -2.9))


# --- construction ----------------------------------------------------------------

func _pipe(a: Vector3, b: Vector3, mat: Material, r := 0.14) -> void:
	var mid := (a + b) * 0.5
	var len := a.distance_to(b)
	var m := Build.cyl(r, len, mat, Vector3.ZERO, Vector3.ZERO, 8, "Pipe")
	m.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), mid)
	add_child(m)


func _build_pipes() -> void:
	# All the same colour on purpose: you have to follow them, not read them.
	var mat := ToonMat.make(Color(0.46, 0.50, 0.52), 0.01)
	var y := Vector3.UP * PIPE_Y
	var pump_out := Vector3(-0.5, 0, 6.6)
	# from the pump inside, along the back of the room and out through the
	# yard-side wall, clear of the doorway
	_pipe(PUMP_POS + Vector3(0, 0, 0.3) + y, Vector3(PUMP_POS.x, 0, pump_out.z) + y, mat)
	_pipe(Vector3(PUMP_POS.x, 0, pump_out.z) + y, pump_out + y, mat)
	_pipe(pump_out + y, Vector3(A_POS.x, 0, pump_out.z) + y, mat)
	_pipe(Vector3(A_POS.x, 0, pump_out.z) + y, A_POS + y, mat)
	# valve A: one outlet doubles back to the grey tank, the other runs on to B
	_pipe(A_POS + y, Vector3(A_POS.x + 1.2, 0, A_POS.z) + y, mat)
	_pipe(Vector3(A_POS.x + 1.2, 0, A_POS.z) + y, Vector3(A_POS.x + 1.2, 0, WASTE_TANK.z - 2.3) + y, mat)
	_pipe(Vector3(A_POS.x + 1.2, 0, WASTE_TANK.z - 2.3) + y, WASTE_TANK + Vector3(0, 0, -2.3) + y, mat)
	_pipe(A_POS + y, Vector3(A_POS.x, 0, A_POS.z - 2.0) + y, mat)
	_pipe(Vector3(A_POS.x, 0, A_POS.z - 2.0) + y, Vector3(B_POS.x, 0, B_POS.z - 2.0) + y, mat)
	_pipe(Vector3(B_POS.x, 0, B_POS.z - 2.0) + y, B_POS + y, mat)
	# valve B: one outlet to the blue tank, the other off the yard to the river
	_pipe(B_POS + y, Vector3(COOLANT_TANK.x, 0, B_POS.z) + y, mat)
	_pipe(Vector3(COOLANT_TANK.x, 0, B_POS.z) + y, COOLANT_TANK + Vector3(0, 0, -2.3) + y, mat)
	_pipe(B_POS + y, Vector3(B_POS.x - 1.0, 0, -12.0) + y, mat)
	# paint the coolant tank blue so "the blue tank" means something
	var world_tank := get_parent().get_node_or_null("Tank1")
	if world_tank != null:
		for c in world_tank.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).material_override = ToonMat.make(Color(0.34, 0.56, 0.86))
	var stencil := Build.label3d("COOLANT MIX", COOLANT_TANK + Vector3(0, 3.6, -2.25), Vector3(0, 180, 0), 0.34, Color(0.95, 0.95, 0.95))
	add_child(stencil)


func _build_pump() -> void:
	var red := ToonMat.make(Color(0.70, 0.18, 0.14), 0.012)
	var body := StaticBody3D.new()
	add_child(body)
	add_child(Build.box(Vector3(0.8, 0.9, 0.6), red, PUMP_POS + Vector3(0, 0.45, 0), Vector3.ZERO, "PumpBody"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.8, 0.9, 0.6)
	cs.shape = sh
	cs.position = PUMP_POS + Vector3(0, 0.45, 0)
	body.add_child(cs)
	_handle = Node3D.new()
	_handle.position = PUMP_POS + Vector3(0, 0.95, 0)
	add_child(_handle)
	_handle.add_child(Build.box(Vector3(0.08, 0.08, 1.2), ToonMat.make(Color(0.25, 0.25, 0.27)), Vector3(0, 0, -0.4), Vector3.ZERO, "Handle"))
	var area := Build.interact_area(Vector3(1.4, 1.6, 1.6), PUMP_POS + Vector3(0, 0.9, -0.3), "Pump (press as the lever comes up)", func(p): stroke(p), "PumpArea")
	area.set_meta("tag_name", "the pump")
	area.set_meta("prompt_fn", func(_p) -> String:
		if stalled > 0.0:
			return "Pump stalled - wait"
		if clog > 0.0:
			return "The lever's slack - sludge in the line"
		return "Pump (press as the lever comes up)")
	add_child(area)
	# relief valve steam
	_puff = CPUParticles3D.new()
	_puff.position = PUMP_POS + Vector3(0.3, 1.2, 0)
	_puff.emitting = false
	_puff.one_shot = true
	_puff.amount = 40
	_puff.lifetime = 1.4
	_puff.explosiveness = 0.9
	_puff.direction = Vector3.UP
	_puff.spread = 30.0
	_puff.initial_velocity_min = 2.0
	_puff.initial_velocity_max = 4.0
	_puff.gravity = Vector3(0, 0.5, 0)
	_puff.scale_amount_min = 0.3
	_puff.scale_amount_max = 0.7
	var pm := SphereMesh.new()
	pm.radius = 0.3
	pm.height = 0.6
	_puff.mesh = pm
	_hiss = NoiseLoop.new()
	_hiss.kind = NoiseLoop.Kind.STEAM
	_hiss.volume_db = -4.0
	_hiss.position = PUMP_POS + Vector3(0.3, 1.2, 0)
	add_child(_hiss)
	var steam := StandardMaterial3D.new()
	steam.albedo_color = Color(1, 1, 1, 0.5)
	steam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.material = steam
	add_child(_puff)


func _build_gauge() -> void:
	var panel := Node3D.new()
	panel.position = GAUGE_POS + Vector3(0, 1.45, 0)
	panel.rotation_degrees = Vector3(0, 180, 0)     # face out into the yard
	add_child(panel)
	panel.add_child(Build.box(Vector3(1.3, 1.1, 0.08), ToonMat.make(Color(0.30, 0.34, 0.36), 0.01), Vector3.ZERO, Vector3.ZERO, "Panel"))
	panel.add_child(Build.cyl(0.36, 0.05, ToonMat.flat(Color(0.95, 0.93, 0.86)), Vector3(0, 0.12, 0.05), Vector3(90, 0, 0), 24, "Dial"))
	# coloured bands: low / green / red, as wedges of small boxes around the dial
	for k in 18:
		var t := float(k) / 17.0
		var col := Color(0.55, 0.55, 0.55)
		if t >= GREEN_LO and t <= GREEN_HI:
			col = Color(0.20, 0.75, 0.30)
		elif t > GREEN_HI:
			col = Color(0.85, 0.20, 0.15)
		var a := deg_to_rad(lerpf(135.0, -135.0, t)) + PI * 0.5
		panel.add_child(Build.box(Vector3(0.05, 0.10, 0.01), ToonMat.flat(col), Vector3(cos(a) * 0.3, 0.12 + sin(a) * 0.3, 0.085), Vector3(0, 0, rad_to_deg(a) - 90.0), "Band"))
	_needle = Node3D.new()
	_needle.position = Vector3(0, 0.12, 0.09)
	panel.add_child(_needle)
	_needle.add_child(Build.box(Vector3(0.025, 0.28, 0.01), ToonMat.flat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.13, 0), Vector3.ZERO, "Needle"))
	panel.add_child(Build.label3d("PRESSURE", Vector3(0, -0.34, 0.06), Vector3.ZERO, 0.09, Color(0.95, 0.95, 0.9)))
	_lamp_green = Build.cyl(0.05, 0.02, _mat_off, Vector3(0.48, 0.42, 0.06), Vector3(90, 0, 0), 10, "FlowLamp")
	panel.add_child(_lamp_green)
	panel.add_child(Build.label3d("FLOW", Vector3(0.48, 0.30, 0.06), Vector3.ZERO, 0.06, Color(0.95, 0.95, 0.9)))
	# the instruction plate: what to do, but not which way the valves go
	var plate := Node3D.new()
	plate.position = GAUGE_POS + Vector3(-1.45, 1.5, 0.0)
	plate.rotation_degrees = Vector3(0, 180, 0)
	add_child(plate)
	plate.add_child(Build.box(Vector3(1.5, 1.15, 0.04), ToonMat.make(Color(0.92, 0.90, 0.80), 0.008), Vector3.ZERO, Vector3.ZERO, "Plate"))
	plate.add_child(Build.label3d("COOLANT MIX\n1. Route the line to the BLUE tank\n   (valves A and B, in the yard)\n2. Pump: one stroke at a time,\n   needle in the GREEN.\n3. NEVER turn a valve\n   under pressure.", Vector3(0, 0, 0.03), Vector3.ZERO, 0.07, Color(0.2, 0.2, 0.25)))


func _build_valve(tag: String, at: Vector3, cb: Callable) -> Node3D:
	var post := ToonMat.make(Color(0.40, 0.42, 0.44), 0.01)
	add_child(Build.cyl(0.12, 1.0, post, at + Vector3(0, 0.5, 0), Vector3.ZERO, 8, "ValvePost"))
	var wheel := Node3D.new()
	wheel.name = "Valve" + tag
	wheel.position = at + Vector3(0, 1.05, 0)
	add_child(wheel)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.32
	wheel.add_child(Build.node(torus, ToonMat.make(Color(0.80, 0.20, 0.16), 0.01), Transform3D.IDENTITY, "Wheel"))
	# pointer: a yellow arrow lying along the currently open outlet
	var pointer := Node3D.new()
	pointer.name = "Pointer"
	wheel.add_child(pointer)
	pointer.add_child(Build.box(Vector3(0.07, 0.05, 0.55), ToonMat.make(Color(0.98, 0.80, 0.18), 0.008), Vector3(0, 0.05, -0.27), Vector3.ZERO, "Arrow"))
	pointer.add_child(Build.cone(0.1, 0.18, ToonMat.make(Color(0.98, 0.80, 0.18), 0.008), Vector3(0, 0.05, -0.6), Vector3(-90, 0, 0), 8, "Tip"))
	add_child(Build.label3d(tag, at + Vector3(0, 1.55, 0), Vector3(0, 180, 0), 0.4, Color(0.95, 0.95, 0.9)))
	if tag == "B":
		# a hand-written warning, so the kick-back is foreshadowed, not a trick
		add_child(Build.label3d("WORN SEAT -\nwatch it under pressure", at + Vector3(0, 0.62, -0.14), Vector3(0, 180, 0), 0.06, Color(0.85, 0.25, 0.2)))
	var area := Build.interact_area(Vector3(1.2, 1.2, 1.2), at + Vector3(0, 1.0, 0), "Turn valve " + tag, cb, "ValveArea" + tag)
	add_child(area)
	return wheel


## Aim each pointer down the pipe that is open.
func _update_pointers() -> void:
	var a_dir := Vector3(1, 0, 0) if valve_a == "waste" else Vector3(0, 0, -1)
	var b_dir := Vector3(1, 0, 0) if valve_b == "coolant" else Vector3(-0.15, 0, -1)
	if _wheel_a:
		(_wheel_a.get_node("Pointer") as Node3D).basis = Basis.looking_at(a_dir, Vector3.UP)
	if _wheel_b:
		(_wheel_b.get_node("Pointer") as Node3D).basis = Basis.looking_at(b_dir, Vector3.UP)


func _build_levels() -> void:
	# sight glass on the front of each tank, readable from the valves
	for t in [["waste", WASTE_TANK], ["coolant", COOLANT_TANK]]:
		var base: Vector3 = t[1] + Vector3(0, 0.6, -2.25)
		add_child(Build.box(Vector3(0.22, 3.2, 0.06), ToonMat.flat(Color(0.18, 0.2, 0.22)), base + Vector3(0, 1.6, 0), Vector3.ZERO, "Glass"))
		var bar := Build.box(Vector3(0.16, 1.0, 0.07), ToonMat.flat(Color(0.35, 0.6, 0.95) if t[0] == "coolant" else Color(0.45, 0.42, 0.35)), base, Vector3.ZERO, "Level")
		add_child(bar)
		_level_bars[t[0]] = bar


func _update_visuals(delta: float) -> void:
	if _needle:
		_needle.rotation.z = deg_to_rad(lerpf(135.0, -135.0, clampf(pressure, 0.0, 1.0)))
	if _lamp_green:
		_lamp_green.material_override = _mat_on if flowing() and route() != "overflow" else _mat_off
	if _handle:
		# up at rest; a stroke takes it down and back up
		var u := 1.0 - _lever / STROKE if _lever > 0.0 else 0.0
		_handle.rotation.x = -0.45 + 0.9 * sin(PI * u)
	for k in _level_bars.keys():
		var bar: MeshInstance3D = _level_bars[k]
		var f: float = maxf(0.02, fill[k])
		bar.scale = Vector3(1, f * 3.1, 1)
		bar.position.y = 0.6 + f * 3.1 * 0.5


## The pump house door: hinged on the doorway's left edge, padlocked until
## someone brings the key down from the water tower.
func _build_door() -> void:
	_door = Node3D.new()
	_door.name = "PumpHouseDoor"
	_door.position = DOOR_HINGE
	_door.rotation.y = DOOR_SHUT
	add_child(_door)
	_door_body = StaticBody3D.new()
	_door.add_child(_door_body)
	var green := ToonMat.make(Color(0.30, 0.44, 0.40))
	_door_body.add_child(Build.box(Vector3(2.2, 2.6, 0.1), green, Vector3(1.1, 1.3, 0), Vector3.ZERO, "Panel"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.2, 2.6, 0.1)
	cs.shape = sh
	cs.position = Vector3(1.1, 1.3, 0)
	_door_body.add_child(cs)
	_door.add_child(Build.box(Vector3(0.14, 0.18, 0.08), ToonMat.make(Color(0.25, 0.25, 0.26), 0.01), Vector3(1.95, 1.15, -0.1), Vector3.ZERO, "Padlock"))
	var open_it := func(p):
		if not door_open and key_taken and p.index == key_by:
			unlock(p)
	var area := Build.interact_area(Vector3(2.2, 2.4, 1.0), Vector3(1.1, 1.2, -0.3), "Locked", open_it, "DoorArea")
	area.set_meta("tag_name", "the pump house door")
	area.set_meta("prompt_fn", func(p) -> String:
		if door_open:
			return ""
		if key_taken and p.index == key_by:
			return "Unlock the pump house"
		if key_taken:
			return "Locked. P%d has the key" % (key_by + 1)
		return "Padlocked. The key must be about somewhere")
	_door.add_child(area)


## The key on a hook on the water tower's tank, up on the catwalk.
func _build_key() -> void:
	_key = Node3D.new()
	_key.name = "PumpHouseKey"
	_key.position = KEY_POS
	add_child(_key)
	var iron := ToonMat.make(Color(0.80, 0.66, 0.24), 0.01)
	_key.add_child(Build.box(Vector3(0.05, 0.22, 0.03), iron, Vector3(0.05, -0.1, 0), Vector3.ZERO, "Shank"))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.05
	ring.outer_radius = 0.07
	_key.add_child(Build.node(ring, iron, Transform3D(Basis(Vector3.RIGHT, PI * 0.5).rotated(Vector3.UP, PI * 0.5), Vector3(0.05, 0.05, 0)), "Ring"))
	_key.add_child(Build.box(Vector3(0.1, 0.06, 0.12), ToonMat.flat(Color(0.95, 0.85, 0.45)), Vector3(0.06, -0.2, 0.06), Vector3.ZERO, "Tag"))
	var area := Build.interact_area(Vector3(0.7, 0.7, 0.7), Vector3(0.1, -0.05, 0), "Take the key", func(p): _take_key(p), "KeyArea")
	area.set_meta("tag_name", "the pump house key")
	area.set_meta("prompt_fn", func(_p) -> String: return "" if key_taken else "Take the key")
	_key.add_child(area)


## The yard's standpipe: a covered player holds E under it to rinse off.
func _build_tap() -> void:
	var steel := ToonMat.make(Color(0.45, 0.48, 0.50), 0.01)
	add_child(Build.cyl(0.07, 1.6, steel, TAP_POS + Vector3(0, 0.8, 0), Vector3.ZERO, 8, "Standpipe"))
	add_child(Build.cyl(0.05, 0.4, steel, TAP_POS + Vector3(0, 1.55, -0.2), Vector3(90, 0, 0), 8, "Spout"))
	add_child(Build.cyl(0.12, 0.03, ToonMat.make(Color(0.80, 0.20, 0.16)), TAP_POS + Vector3(0, 1.62, 0), Vector3.ZERO, 10, "TapWheel"))
	add_child(Build.box(Vector3(1.2, 0.04, 1.2), ToonMat.make(Color(0.34, 0.36, 0.38)), TAP_POS + Vector3(0, 0.22, -0.5), Vector3.ZERO, "Drain"))
	var area := Build.interact_area(Vector3(0.9, 2.0, 0.9), TAP_POS + Vector3(0, 1.0, -0.2), "", func(_p): pass, "TapArea")   # small: standing inside it, your aim misses it
	area.set_meta("tag_name", "the standpipe")
	area.set_meta("prompt_fn", func(p) -> String: return "Hold to rinse the sludge off" if p.slime_t > 0.0 else "")
	area.set_meta("hold_fn", func(p, dt): rinse(p, dt))
	area.set_meta("no_slow", true)
	add_child(area)
	_rinse_spray = CPUParticles3D.new()
	_rinse_spray.position = TAP_POS + Vector3(0, 1.5, -0.4)
	_rinse_spray.emitting = false
	_rinse_spray.amount = 60
	_rinse_spray.lifetime = 0.6
	_rinse_spray.direction = Vector3.DOWN
	_rinse_spray.spread = 12.0
	_rinse_spray.initial_velocity_min = 1.5
	_rinse_spray.initial_velocity_max = 2.5
	_rinse_spray.gravity = Vector3(0, -9.8, 0)
	_rinse_spray.scale_amount_min = 0.5
	_rinse_spray.scale_amount_max = 1.0
	var drop := SphereMesh.new()
	drop.radius = 0.03
	drop.height = 0.06
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.70, 0.85, 1.0, 0.7)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = water
	_rinse_spray.mesh = drop
	add_child(_rinse_spray)


## The grey tank's hatch, the sludge that bursts out of it and the puddle it
## leaves over the yard.
func _build_sludge() -> void:
	var grey := ToonMat.make(Color(0.48, 0.47, 0.44), 0.01)
	_hatch = Node3D.new()
	_hatch.name = "GreyHatch"
	_hatch.position = WASTE_TANK + Vector3(0, 5.62, 0)
	add_child(_hatch)
	_hatch.add_child(Build.cyl(0.6, 0.12, grey, Vector3.ZERO, Vector3.ZERO, 14, "Hatch"))
	add_child(Build.label3d("SLUDGE", WASTE_TANK + Vector3(0, 3.6, -2.25), Vector3(0, 180, 0), 0.34, Color(0.95, 0.95, 0.95)))
	var mud := StandardMaterial3D.new()
	mud.albedo_color = Color(0.36, 0.30, 0.22)
	mud.roughness = 0.3
	_sludge = CPUParticles3D.new()
	_sludge.position = WASTE_TANK + Vector3(0, 5.8, 0)
	_sludge.emitting = false
	_sludge.one_shot = true
	_sludge.amount = 220
	_sludge.lifetime = 2.4
	_sludge.explosiveness = 0.85
	_sludge.direction = Vector3.UP
	_sludge.spread = 75.0
	_sludge.initial_velocity_min = 5.0
	_sludge.initial_velocity_max = 13.0
	_sludge.gravity = Vector3(0, -9.8, 0)
	_sludge.scale_amount_min = 0.6
	_sludge.scale_amount_max = 1.6
	var blob := SphereMesh.new()
	blob.radius = 0.12
	blob.height = 0.2
	blob.material = mud
	_sludge.mesh = blob
	add_child(_sludge)
	var disc := CylinderMesh.new()
	disc.top_radius = 9.0
	disc.bottom_radius = 9.0
	disc.height = 0.02
	disc.radial_segments = 24
	var puddle_mat := StandardMaterial3D.new()
	puddle_mat.albedo_color = Color(0.32, 0.27, 0.20, 0.85)
	puddle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle_mat.roughness = 0.2
	disc.material = puddle_mat
	_puddle = Build.node(disc, puddle_mat, Transform3D(Basis(), WASTE_TANK + Vector3(-1.0, 0.23, -2.0)), "SludgePuddle")
	_puddle.visible = false
	add_child(_puddle)
