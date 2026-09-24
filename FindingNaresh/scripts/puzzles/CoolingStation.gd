class_name CoolingStation
extends Node3D

## The water works co-op puzzle (built in the facility's local frame, -Z
## toward the river).
##
## One player works the hand pump by the pump house door and watches the
## pressure gauge there: hold E to pump, keep the needle in the green band.
## Too much pressure pops the relief valve and stalls the pump for a few
## seconds (a noisy, recoverable mistake, never a fail state).
##
## The other player sets two valve wheels in the yard. Each wheel's pointer
## shows which outlet pipe is open; the only way to know the right setting is
## to follow the pipes by eye to see which one feeds the blue COOLANT tank.
## Nothing on the pump side says which way the valves should point, and the
## gauge cannot be seen from the valves - so the two have to talk.
##
## Valve B has a worn seat (its plate says so). With two players, the line
## pressure kicks it back to the overflow twice while the blue tank fills (at
## a third and two thirds): the needle collapses on the pump side, the
## pointer swings and clanks on the valve side, and the valve player has to
## turn it back. So the valve player stays at their post and both keep
## talking to the end. Alone on one keyboard (solo view) it holds, so one
## person can still test the whole puzzle.
##
## Filling the blue tank dispenses a coolant jug and a Memory Fragment.

signal solved_changed

const GREEN_LO := 0.40
const GREEN_HI := 0.85
const PUMP_RISE := 0.28       ## pressure per second while pumping
const LEAK_FALL := 0.18       ## pressure per second while not pumping
const OVERFLOW_FALL := 0.30   ## the overflow route has a free outlet: pressure never builds
const FILL_RATE := 0.075      ## tank fill per second of pumping in the green
const STALL_TIME := 3.5
## Blue-tank levels at which valve B kicks back to the overflow (two players only).
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
## -1: valve B slips only when two people play (a pad for P2); 0 / 1 force it
## off / on (the play-test uses this).
var co_op := -1

var _pump_hold := 0.0         ## > 0 while someone is holding the pump handle
var _needle: Node3D
var _lamp_green: MeshInstance3D
var _level_bars := {}
var _wheel_a: Node3D
var _wheel_b: Node3D
var _handle: Node3D
var _puff: CPUParticles3D
var _mat_on: StandardMaterial3D
var _mat_off: StandardMaterial3D
var _stroke_t := 0.0
var _hiss: NoiseLoop

const PUMP_POS := Vector3(-2.0, 0, -0.6)
const GAUGE_POS := Vector3(-2.0, 0, -0.2)   ## right above the pump: watch it while you pump
const A_POS := Vector3(2.5, 0, -3.0)
const B_POS := Vector3(8.0, 0, -3.0)
const WASTE_TANK := Vector3(5.0, 0, 5.0)
const COOLANT_TANK := Vector3(10.5, 0, 5.0)
const PIPE_Y := 0.45


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
	_update_pointers()


# --- the puzzle ----------------------------------------------------------------

func route() -> String:
	if valve_a == "waste":
		return "waste"
	return "coolant" if valve_b == "coolant" else "overflow"


func _physics_process(delta: float) -> void:
	var pumping := _pump_hold > 0.0 and stalled <= 0.0
	_pump_hold = maxf(0.0, _pump_hold - delta)
	if pumping:
		_stroke_t -= delta
		if _stroke_t <= 0.0:
			_stroke_t = 0.55
			Sfx.play3d("creak", global_transform * PUMP_POS, -4.0, 0.15)
	if _hiss:
		_hiss.target = maxf(0.0, _hiss.target - delta * 0.5)
	if stalled > 0.0:
		stalled -= delta
	var r := route()
	pressure += (PUMP_RISE if pumping else -LEAK_FALL) * delta
	if r == "overflow":
		pressure -= OVERFLOW_FALL * delta
	pressure = clampf(pressure, 0.0, 1.1)
	if pressure >= 1.0:
		_pop()
	if pumping and pressure >= GREEN_LO and pressure <= GREEN_HI and r != "overflow" and not solved:
		fill[r] = minf(1.0, fill[r] + FILL_RATE * delta)
		if r == "coolant" and fill["coolant"] >= 1.0:
			_solve()
		elif r == "coolant" and slips < SLIP_AT.size() and fill["coolant"] >= SLIP_AT[slips] and _two_players():
			_slip()
	# the waste tank drains back down, so a wrong route is never permanent
	if not pumping:
		fill["waste"] = maxf(0.0, fill["waste"] - 0.03 * delta)
	_update_visuals(delta)


## Called every physics tick while a player holds E on the pump handle.
func pump(_p, _dt: float) -> void:
	_pump_hold = 0.1


func _turn(which: String, _p) -> void:
	if which == "a":
		valve_a = "b" if valve_a == "waste" else "waste"
	else:
		valve_b = "overflow" if valve_b == "coolant" else "coolant"
	_update_pointers()
	var at := A_POS if which == "a" else B_POS
	Sfx.play3d("latch", global_transform * at, -2.0)
	Sfx.play3d("creak", global_transform * at, -8.0, 0.2)


## Two people at the station: P2 has their own device (a pad). Solo testing on
## one keyboard shares a single pair of hands, so B holds there.
func _two_players() -> bool:
	if co_op >= 0:
		return co_op == 1
	var kbm := 0
	for p in get_tree().get_nodes_in_group("player"):
		var d: InputDevice = p.dev
		if d != null and d.kind == InputDevice.Kind.KBM:
			kbm += 1
	return kbm < 2


## Valve B's worn seat gives way: it spins back to the overflow. The overflow
## has a free outlet, so the pump side sees the needle fall and the flow lamp
## go out; the valve side sees and hears the wheel kick.
func _slip() -> void:
	slips += 1
	valve_b = "overflow"
	_update_pointers()
	var at := global_transform * (B_POS + Vector3(0, 1.0, 0))
	Sfx.play3d("bang", at, -6.0, 0.1)
	Sfx.play3d("latch", at, 0.0)
	Sfx.play3d("creak", at, -2.0, 0.3)
	var text := "CLANK! Valve B kicks back under the pressure and spins to the overflow. Turn it back - and stay by it." if slips == 1 else "CLANK! Valve B slips again. Turn it back!"
	for p in get_tree().get_nodes_in_group("player"):
		if (p as Node3D).global_position.distance_to(at) < 30.0:
			p.say(text, 4.0)


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
	for p in get_tree().get_nodes_in_group("player"):
		if (p as Node3D).global_position.distance_to(global_transform * GAUGE_POS) < 30.0:
			p.say("BANG! The relief valve blows with a shriek of steam. The pump stalls - give it a moment. (Keep the needle in the green.)", 5.0)


func _solve() -> void:
	solved = true
	solved_changed.emit()
	Sfx.play3d("bong", global_transform * COOLANT_TANK, 0.0, 0.0)
	var tap_local := COOLANT_TANK + Vector3(0, 0.1, -2.9)
	var jug := CoolantJug.new()
	jug.name = "CoolantJug"
	get_tree().get_first_node_in_group("world_root").add_child(jug)
	jug.global_position = global_transform * tap_local
	var frag := MemoryFragment.create("water_works")
	get_tree().get_first_node_in_group("world_root").add_child(frag)
	frag.global_position = global_transform * (COOLANT_TANK + Vector3(-1.4, 0.4, -2.9))
	for p in get_tree().get_nodes_in_group("player"):
		p.say("The blue tank fills with a gurgle and the tap coughs out a jug of coolant mix. Something small and pink glints beside it.", 7.0)


# --- save support ----------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"valve_a": valve_a, "valve_b": valve_b, "fill_waste": fill["waste"],
		"fill_coolant": fill["coolant"], "solved": solved, "slips": slips}


## Restore after a load. A solved station keeps its jug (restored as a normal
## item) and re-offers its fragment unless that was already picked up.
func from_dict(d: Dictionary, collected: Array) -> void:
	valve_a = d.get("valve_a", valve_a)
	valve_b = d.get("valve_b", valve_b)
	fill["waste"] = float(d.get("fill_waste", 0.0))
	fill["coolant"] = float(d.get("fill_coolant", 0.0))
	solved = bool(d.get("solved", false))
	slips = int(d.get("slips", 0))
	pressure = 0.0
	stalled = 0.0
	_update_pointers()
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
	var pump_out := Vector3(-0.5, 0, 1.5)
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
	var area := Build.interact_area(Vector3(1.4, 1.6, 1.6), PUMP_POS + Vector3(0, 0.9, -0.3), "Hold to work the pump", func(_p): pass, "PumpArea")
	area.set_meta("hold_fn", func(p, dt): pump(p, dt))
	area.set_meta("prompt_fn", func(_p) -> String:
		return "Pump stalled - wait" if stalled > 0.0 else "Hold to work the pump")
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
	plate.position = GAUGE_POS + Vector3(-1.2, 1.5, 0.0)
	plate.rotation_degrees = Vector3(0, 180, 0)
	add_child(plate)
	plate.add_child(Build.box(Vector3(1.1, 0.8, 0.04), ToonMat.make(Color(0.92, 0.90, 0.80), 0.008), Vector3.ZERO, Vector3.ZERO, "Plate"))
	plate.add_child(Build.label3d("COOLANT MIX\n1. Route the line to the BLUE tank\n   (valves A and B, in the yard)\n2. Pump. Hold the needle\n   in the GREEN.", Vector3(0, 0, 0.03), Vector3.ZERO, 0.07, Color(0.2, 0.2, 0.25)))


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
	var flowing := _pump_hold > 0.0 and stalled <= 0.0 and pressure >= GREEN_LO and pressure <= GREEN_HI
	if _lamp_green:
		_lamp_green.material_override = _mat_on if flowing else _mat_off
	if _handle and _pump_hold > 0.0 and stalled <= 0.0:
		_handle.rotation.x = sin(Time.get_ticks_msec() * 0.012) * 0.5
	for k in _level_bars.keys():
		var bar: MeshInstance3D = _level_bars[k]
		var f: float = maxf(0.02, fill[k])
		bar.scale = Vector3(1, f * 3.1, 1)
		bar.position.y = 0.6 + f * 3.1 * 0.5
