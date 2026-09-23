class_name PlayTest
extends Node

## Automated play-test. Drives the real game through the real input path
## (Input.parse_input_event), measures how it behaves and writes screenshots to
## _shots/test_*.png. Launch with:
##   Godot --path FindingNaresh -- --playtest            (all scenarios)
##   Godot --path FindingNaresh -- --playtest=drive      (one scenario)
## Results are printed as "[test] ..." lines so a run can be diffed.

var boot: Node
var only := ""
var _frame_times: PackedFloat32Array = PackedFloat32Array()
var _failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playtest="):
			only = a.get_slice("=", 1)
	_run.call_deferred()


func _process(delta: float) -> void:
	_frame_times.append(delta)


# --- input injection -----------------------------------------------------------

func key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = down
	Input.parse_input_event(e)


## A quick human tap: held for ~70 ms of real time, however fast frames are.
func tap(k: Key, hold_s := 0.07) -> void:
	key(k, true)
	await wait(hold_s)
	key(k, false)
	await wait(0.08)


func mouse(rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.relative = rel
	e.screen_relative = rel
	Input.parse_input_event(e)


func release_all() -> void:
	for k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_SPACE, KEY_CTRL, KEY_E, KEY_X, KEY_F, KEY_L, KEY_R, KEY_C, KEY_ESCAPE]:
		key(k, false)


func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func physics_frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func log_line(s: String) -> void:
	print("[test] " + s)


func check(ok: bool, what: String) -> void:
	log_line(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failures.append(what)


func shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_shots"))
	img.save_png("res://_shots/test_%s.png" % tag)
	log_line("shot test_%s.png" % tag)


# --- helpers -------------------------------------------------------------------

func p1() -> PlayerRig:
	return boot.players[0]


func p2() -> PlayerRig:
	return boot.players[1]


func camper() -> Camper:
	return boot.camper


func kmh() -> float:
	return camper().linear_velocity.length() * 3.6


func planar_speed(p: PlayerRig) -> float:
	return Vector2(p.velocity.x, p.velocity.z).length()


func place_player(p: PlayerRig, pos: Vector3, yaw: float) -> void:
	if p.seat != null:
		p.force_exit = true
		await physics_frames(2)
	p.global_position = pos
	p.yaw = yaw
	p.rotation = Vector3(0, yaw, 0)
	p.pitch = 0.0
	p.velocity = Vector3.ZERO
	if p.has_method("reset_physics_interpolation"):
		p.reset_physics_interpolation()
	# a teleport must bring whatever is in your hands along
	if p.held != null:
		p.held.global_position = p.hold_point(p.held)
		p.held.linear_velocity = Vector3.ZERO
		p.held.reset_physics_interpolation()
	await physics_frames(3)


func reset_camper(route_index: int) -> void:
	var r: Route = boot.builder.route
	var p := r.point(route_index)
	var f := r.forward(route_index)
	var basis := Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP)
	var c := camper()
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(basis, p + Vector3.UP * 0.9)
	if c.has_method("reset_physics_interpolation"):
		c.reset_physics_interpolation()
	await physics_frames(30)


func seat_p1_driver() -> void:
	var c := camper()
	if p1().seat == null:
		p1().enter_seat(c, c.seat_nodes["driver"], "driver")
	await physics_frames(2)


# --- run -----------------------------------------------------------------------

func _run() -> void:
	await wait(1.0)
	log_line("adapter=%s  refresh=%.0fHz  window=%s  pads=%s" % [
		RenderingServer.get_video_adapter_name(),
		DisplayServer.screen_get_refresh_rate(),
		str(DisplayServer.window_get_size()),
		str(Input.get_connected_joypads())])
	log_line("route length %.0f m, %d samples" % [boot.builder.route.total_length, boot.builder.route.point_count()])

	var all := ["map", "overview", "tour", "climb", "carry", "journey", "mouse", "foot", "taps", "enter", "cockpit", "layout", "park", "solid", "crash", "look", "pad", "drive", "brake", "lap", "exit", "swap", "perf"]
	for s in all:
		if only != "" and only != s:
			continue
		log_line("---- %s ----" % s)
		release_all()
		await call("t_" + s)
		release_all()

	log_line("==== %d failure(s) ====" % _failures.size())
	for f in _failures:
		log_line("  - " + f)
	get_tree().quit()


# --- scenarios -----------------------------------------------------------------

func t_foot() -> void:
	var p := p1()
	await wait(0.5)
	await shot("foot_spawn")
	# open ground beside the road, facing away from it
	var rr: Route = boot.builder.route
	var gp := rr.point(100) + rr.right(100) * 12.0
	gp.y = Landscape.sample_height(rr, gp.x, gp.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.3
	var away := rr.right(100)
	await place_player(p, gp, atan2(-away.x, -away.z))
	var start := p.global_position
	key(KEY_W, true)
	await wait(1.5)
	var walk := planar_speed(p)
	key(KEY_SHIFT, true)
	await wait(1.5)
	var sprint := planar_speed(p)
	if walk < 3.5:
		await shot("foot_blocked")
	key(KEY_SHIFT, false)
	key(KEY_W, false)
	await wait(0.6)
	log_line("walk %.2f m/s  sprint %.2f m/s  moved %.1f m" % [walk, sprint, start.distance_to(p.global_position)])
	check(walk > 3.5, "walking reaches normal speed")
	check(sprint > walk + 1.5, "sprint is clearly faster")

	var y0 := p.global_position.y
	var peak := y0
	key(KEY_SPACE, true)
	for _i in 60:
		await get_tree().physics_frame
		peak = maxf(peak, p.global_position.y)
	key(KEY_SPACE, false)
	log_line("jump height %.2f m" % (peak - y0))
	check(peak - y0 > 0.35, "jump leaves the ground")

	# mouse look: 400 px right should be a sensible turn
	var yaw0 := p.yaw
	for _i in 20:
		mouse(Vector2(20, 0))
		await get_tree().process_frame
	await physics_frames(2)
	log_line("400 px mouse = %.1f deg turn" % rad_to_deg(absf(wrapf(p.yaw - yaw0, -PI, PI))))

	# walk off-road up the slope toward the roses hill
	var r: Route = boot.builder.route
	var i := 40
	var pos := r.point(i) - r.right(i) * 10.0
	var to_hill := LevelBuilder.ROSE_CENTRE - pos
	await place_player(p, pos + Vector3.UP * 1.0, atan2(-to_hill.x, -to_hill.z))
	var h0 := p.global_position
	key(KEY_W, true)
	await wait(6.0)
	key(KEY_W, false)
	var climbed := p.global_position.y - h0.y
	log_line("uphill 6 s: moved %.1f m, climbed %.1f m" % [Vector2(p.global_position.x - h0.x, p.global_position.z - h0.z).length(), climbed])
	await shot("foot_hill")


## Solo view, TAB to the other player, F2 through the split layouts.
func t_layout() -> void:
	await reset_camper(6)
	var c := camper()
	await seat_p1_driver()
	if p2().seat == null:
		p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await wait(0.4)
	var solo_default: bool = boot.layout == 2
	check(solo_default == (Input.get_connected_joypads().size() == 0), "solo view is the default only when no controller is connected")
	await tap(KEY_TAB)
	await wait(0.4)
	check(boot.kbm_owner == 1 and boot.views[1].visible and not boot.views[0].visible, "TAB switches to P2 and shows P2's view")
	# P2 looks left at the nav screen
	p2()._seat_yaw = deg_to_rad(38)
	p2().pitch = deg_to_rad(-18)
	await wait(0.3)
	await shot("passenger_nav")
	p2()._seat_yaw = 0.0
	p2().pitch = deg_to_rad(-5)
	await wait(0.2)
	await shot("passenger_forward")
	await tap(KEY_TAB)
	await tap(KEY_F2)
	await wait(0.4)
	check(boot.views[0].visible and boot.views[1].visible, "F2 goes to side-by-side split")
	await shot("split_side")
	await tap(KEY_F2)
	await wait(0.4)
	await shot("split_stacked")
	await tap(KEY_F2)
	await wait(0.2)
	p2().force_exit = true
	await physics_frames(3)


## A parked van must stay put on the steepest bit of road, engine off or idling.
func t_park() -> void:
	var r: Route = boot.builder.route
	var steep := 0
	var best := 0.0
	for i in r.point_count():
		var g := absf(r.forward(i).y)
		if g > best:
			best = g
			steep = i
	log_line("steepest road grade %.1f%% at sample %d" % [best * 100.0, steep])
	await reset_camper(steep)
	await seat_p1_driver()
	var c := camper()
	if c.engine_on:
		c.toggle_engine()
	await wait(1.0)
	var p0 := c.global_position
	await wait(5.0)
	var off_drift := p0.distance_to(c.global_position)
	c.toggle_engine()
	await wait(1.0)
	p0 = c.global_position
	await wait(5.0)
	var idle_drift := p0.distance_to(c.global_position)
	log_line("parked 5 s: engine off drift %.2f m, idling drift %.2f m" % [off_drift, idle_drift])
	check(off_drift < 0.1, "parked van with engine off stays put on a slope")
	check(idle_drift < 0.1, "idling van without throttle stays put on a slope")
	# and it can still pull away uphill from the hold
	key(KEY_W, true)
	await wait(2.0)
	key(KEY_W, false)
	log_line("pull away from hold: %.0f km/h after 2 s" % kmh())
	check(kmh() > 10.0, "van pulls away normally from the auto-hold")
	key(KEY_S, true)
	await wait(3.0)
	key(KEY_S, false)


## Walk at solid-looking things and see whether the player goes through them.
func t_solid() -> void:
	var p := p1()
	var targets := []
	# the nearest rock and a tree far from the road, found from the scatter
	var rocks: MultiMeshInstance3D = boot.world.get_node("Rocks")
	var trunks: MultiMeshInstance3D = boot.world.get_node("Trunks")
	var r: Route = boot.builder.route
	var best_rock := Vector3.ZERO
	var best_rock_s := 0.0
	for i in rocks.multimesh.instance_count:
		var xf := rocks.multimesh.get_instance_transform(i)
		var sc := xf.basis.get_scale().x
		if sc > 1.6 and sc > best_rock_s and float(r.nearest(xf.origin.x, xf.origin.z)["dist"]) < 60.0:
			best_rock_s = sc
			best_rock = xf.origin
	targets.append({"name": "big rock", "pos": best_rock})
	for i in trunks.multimesh.instance_count:
		var xf := trunks.multimesh.get_instance_transform(i)
		if float(r.nearest(xf.origin.x, xf.origin.z)["dist"]) > 90.0:
			targets.append({"name": "tree 90 m+ from road", "pos": xf.origin})
			break
	var roses: Node = boot.world.get_node("FiveRoses")
	for c in roses.get_children():
		if c.name.begins_with("Rose") and c is Node3D and c.get_child_count() > 3 and not (c is StaticBody3D):
			targets.append({"name": "rose monument", "pos": (c as Node3D).global_position})
			break
	targets.append({"name": "rose plaza", "pos": LevelBuilder.ROSE_CENTRE + Vector3(0, 0, 0)})
	for t in targets:
		var tp: Vector3 = t["pos"]
		var start := tp + Vector3(9.0, 0, 3.0)
		start.y = Landscape.sample_height(r, start.x, start.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.4
		var d := tp - start
		await place_player(p, start, atan2(-d.x, -d.z))
		var min_d := 999.0
		key(KEY_W, true)
		for _i in 60 * 4:
			await get_tree().physics_frame
			min_d = minf(min_d, Vector2(p.global_position.x - tp.x, p.global_position.z - tp.z).length())
		key(KEY_W, false)
		var ground := Landscape.sample_height(r, p.global_position.x, p.global_position.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS)
		log_line("%s: closest approach %.2f m, feet %.2f m above terrain" % [t["name"], min_d, p.global_position.y - ground])
		if t["name"] == "rose plaza":
			await shot("plaza_walk")
			var top := Landscape.plateau_height(LevelBuilder.MOUNDS[0], LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.08
			log_line("plaza: feet %.2f m relative to plaza top" % (p.global_position.y - top))
			check(p.global_position.y - top > -0.05, "player walks on top of the rose plaza, not inside it")
		else:
			check(min_d > 0.3, "%s blocks the player" % t["name"])


## Drive off the road into the woods at speed, then try to carry on.
func t_crash() -> void:
	await reset_camper(60)
	await seat_p1_driver()
	var c := camper()
	if not c.engine_on:
		c.toggle_engine()
	var flipped := false
	var max_tilt := 0.0
	var min_speed_after := 999.0
	key(KEY_W, true)
	key(KEY_D, true)
	for i in 60 * 3:
		await get_tree().physics_frame
		if i == 30:
			key(KEY_D, false)
	for _i in 60 * 10:
		await get_tree().physics_frame
		var up := c.global_transform.basis.y
		max_tilt = maxf(max_tilt, rad_to_deg(acos(clampf(up.y, -1, 1))))
		if up.y < 0.4:
			flipped = true
	key(KEY_W, false)
	await shot("crash")
	log_line("off-road run: max tilt %.0f deg, flipped=%s, speed now %.0f km/h" % [max_tilt, flipped, kmh()])
	# deliberately roll it: hard turns at speed down a slope
	c.freeze = false
	c.global_transform = Transform3D(Basis(Vector3.FORWARD, PI) * c.global_transform.basis, c.global_position + Vector3.UP * 2.5)
	c.reset_physics_interpolation()
	for k in 6:
		await wait(0.5)
		log_line("  t+%.1f s: up.y %.2f frozen=%s speed %.1f" % [0.5 * (k + 1), c.global_transform.basis.y.y, c.freeze, c.linear_velocity.length()])
	var on_side := c.global_transform.basis.y.y < 0.4
	log_line("van tipped on its side: on_side=%s, prompt '%s'" % [on_side, p1().prompt_text])
	check(p1().prompt_text.contains("Right the van") or p1().prompt_text.contains("right the van"), "a flipped van offers a way to right it")
	await tap(KEY_R)
	await wait(2.0)
	check(c.global_transform.basis.y.y > 0.9, "R puts the van back on its wheels")


## Screens and places that only need looking at.
func t_look() -> void:
	boot._refresh_overlay()
	boot.overlay.visible = true
	await wait(0.3)
	await shot("title")
	boot.overlay.visible = false
	await tap(KEY_ESCAPE)
	await wait(0.3)
	check(get_tree().paused, "ESC pauses")
	var s0: float = boot.mouse_sens
	await tap(KEY_BRACKETRIGHT)
	check(boot.mouse_sens > s0 and absf(p1().dev.look_sensitivity - boot.mouse_sens) < 0.001, "] raises mouse sensitivity")
	await shot("pause")
	await tap(KEY_BRACKETLEFT)
	check(absf(boot.mouse_sens - s0) < 0.001, "[ lowers it back")
	await tap(KEY_ESCAPE)
	await wait(0.2)
	check(not get_tree().paused, "ESC again resumes")
	var p := p1()
	var r: Route = boot.builder.route
	# the destination from the road, and from the plaza itself
	var i := 150
	var rp := r.point(i) + r.right(i) * 5.0
	rp.y = Landscape.sample_height(r, rp.x, rp.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.3
	var d := LevelBuilder.ROSE_CENTRE - rp
	await place_player(p, rp, atan2(-d.x, -d.z))
	p.pitch = 0.08
	await wait(0.6)
	await shot("roses_from_road")
	var top := Landscape.plateau_height(LevelBuilder.MOUNDS[0], LevelBuilder.PONDS, LevelBuilder.MOUNDS)
	var pp := LevelBuilder.ROSE_CENTRE + Vector3(-6, top + 0.4, 12)
	await place_player(p, pp, deg_to_rad(10))
	p.pitch = 0.18
	await wait(0.6)
	await shot("roses_plaza")
	var edge := LevelBuilder.ROSE_CENTRE + Vector3(0, 0, 44)
	edge.y = Landscape.sample_height(r, edge.x, edge.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.3
	await place_player(p, edge, 0.0)
	p.pitch = 0.05
	await wait(0.6)
	await shot("roses_approach")
	# headlights at dusk: darken the sun for a look at the beams
	var sun: DirectionalLight3D = boot.world.get_node("Sun")
	var env: Environment = (boot.world.get_node("Environment") as WorldEnvironment).environment
	var sun_e := sun.light_energy
	var amb := env.ambient_light_energy
	sun.light_energy = 0.05
	env.ambient_light_energy = 0.08
	await reset_camper(6)
	await seat_p1_driver()
	await tap(KEY_L)
	await wait(0.5)
	check(camper().headlights_on, "L switches the headlights on")
	await shot("headlights")
	await tap(KEY_F)
	await wait(0.3)
	await shot("flashlight_in_cab")
	await tap(KEY_F)
	await tap(KEY_L)
	sun.light_energy = sun_e
	env.ambient_light_energy = amb


## A simulated controller on device 0: P2 must pick it up, switch to split
## screen, walk, look, use the doors and drive with the triggers, and neither
## player's input may move the other.
func pad_axis(axis: JoyAxis, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = v
	Input.parse_input_event(e)


func pad_button(b: JoyButton, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)


func pad_tap(b: JoyButton) -> void:
	pad_button(b, true)
	await wait(0.07)
	pad_button(b, false)
	await wait(0.08)


func t_pad() -> void:
	for pl in boot.players:
		if pl.seat != null:
			pl.force_exit = true
	await physics_frames(3)
	boot._on_joy_changed(0, true)
	await wait(0.3)
	check(boot.devices[1].kind == InputDevice.Kind.PAD, "a connected controller becomes Player 2")
	check(boot.layout == 0 and boot.views[0].visible and boot.views[1].visible, "plugging a controller in switches to split-screen")
	var p := p2()
	var q := p1()
	var r: Route = boot.builder.route
	var gp := r.point(100) + r.right(100) * 12.0
	gp.y = Landscape.sample_height(r, gp.x, gp.z, LevelBuilder.PONDS, LevelBuilder.MOUNDS) + 0.3
	var away := r.right(100)
	await place_player(p, gp, atan2(-away.x, -away.z))
	var q0 := q.global_position
	var qyaw := q.yaw
	pad_axis(JOY_AXIS_LEFT_Y, -1.0)
	pad_axis(JOY_AXIS_RIGHT_X, 0.6)
	var yaw0 := p.yaw
	await wait(1.2)
	var v := planar_speed(p)
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	log_line("pad walk %.2f m/s, right stick turned %.0f deg in 1.2 s" % [v, rad_to_deg(absf(wrapf(p.yaw - yaw0, -PI, PI)))])
	check(v > 3.5, "left stick walks Player 2")
	check(absf(wrapf(p.yaw - yaw0, -PI, PI)) > 0.3, "right stick turns Player 2")
	check(q.global_position.distance_to(q0) < 0.05 and absf(q.yaw - qyaw) < 0.001, "the controller does not move Player 1")
	# keyboard must not move P2 (let it come to rest first)
	await wait(0.5)
	var p0 := p.global_position
	var pyaw := p.yaw
	key(KEY_W, true)
	mouse(Vector2(200, 0))
	await wait(0.6)
	key(KEY_W, false)
	log_line("P2 moved %.3f m, turned %.3f rad while the keyboard was used" % [p.global_position.distance_to(p0), absf(p.yaw - pyaw)])
	check(p.global_position.distance_to(p0) < 0.05 and absf(p.yaw - pyaw) < 0.001, "keyboard and mouse do not move Player 2")
	# enter the driver's seat with X and drive with RT
	await reset_camper(6)
	var c := camper()
	var door := c.global_transform * Vector3(-1.2, 0.0, -1.8)
	var stand := c.global_transform * Vector3(-3.6, 0.0, -1.8)
	stand.y = door.y
	var d := door - stand
	await place_player(p, stand + Vector3.UP * 0.2, atan2(-d.x, -d.z))
	await wait(0.3)
	log_line("P2 prompt at door: '%s'" % p.prompt_text)
	check(p.prompt_text.begins_with("[X]"), "Player 2's prompts show controller buttons")
	await pad_tap(JOY_BUTTON_X)
	await physics_frames(3)
	check(p.seat_role == "driver", "X on the controller gets into the van")
	if c.engine_on:
		c.toggle_engine()
	await pad_tap(JOY_BUTTON_DPAD_UP)
	check(c.engine_on, "D-pad up starts the engine")
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await wait(3.0)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	log_line("RT for 3 s: %.0f km/h" % kmh())
	check(kmh() > 25.0, "right trigger drives the van")
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	var guard := 0
	while kmh() > 1.0 and guard < 60 * 6:
		await get_tree().physics_frame
		guard += 1
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await wait(1.0)
	log_line("stopped with LT: %.1f km/h" % kmh())
	await pad_tap(JOY_BUTTON_X)
	await physics_frames(3)
	check(p.seat == null, "X gets Player 2 out once stopped")
	# leave the session as it was: keyboard for both, solo view
	boot.devices[1] = InputDevice.keyboard()
	p.dev = boot.devices[1]
	boot._apply_kbm_owner()
	boot._set_layout(2)


## Stand at each landmark and look at the next one: a picture of the journey.
func t_tour() -> void:
	var b: LevelBuilder = boot.builder
	var stops := [
		["tour_01_start", b.player_spawns[0].origin, b.poi["camper_spawn"] + Vector3(0, 0, -30)],
		["tour_02_windmill_junction", b.poi["j1"] + Vector3(-14, 0, 22), b.poi["windmill"]],
		["tour_03_mirror_lake", b.network.road("valley_road").point(110) + Vector3(0, 0, 0), b.poi["dock"]],
		["tour_04_billboard", b.network.road("valley_road").point(215), b.poi["billboard"]],
		["tour_05_barn", b.network.road("valley_road").point(330), b.poi["barn"]],
		["tour_06_ridge_climb", b.network.road("ridge_track").point(40), b.poi["lookout"]],
		["tour_07_lookout_view", b.poi["lookout_deck"], Vector3(LevelBuilder.ROSE_CENTRE.x, 30, LevelBuilder.ROSE_CENTRE.z)],
		["tour_08_wreck", b.network.road("ridge_track").point(240), b.poi["wreck"]],
		["tour_09_last_fuel", b.network.road("pump_house_road").point(18), b.poi["gas_station"]],
		["tour_10_water_works", b.network.road("pump_house_road").point(110), b.poi["facility"]],
		["tour_11_broken_bridge", b.poi["bridge_barrier_near"], b.poi["bridge"]],
		["tour_12_bessi", b.poi["bessi_join"], b.poi["roses"] + Vector3(0, 20, 0)],
		["tour_13_radio_mast", b.poi["j2"], b.poi["radio_mast"] + Vector3(0, 30, 0)],
	]
	var p := p1()
	for s in stops:
		var at: Vector3 = s[1]
		at.y = maxf(at.y, Landscape.ground(at.x, at.z) + 0.3)
		var look: Vector3 = s[2]
		var d: Vector3 = look - (at + Vector3.UP * 1.56)
		await place_player(p, at, atan2(-d.x, -d.z))
		p.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -0.5, 0.5)
		await wait(0.5)
		await shot(s[0])


## Orthographic shots from straight above: whole map, then close-ups.
func t_overview() -> void:
	var b: LevelBuilder = boot.builder
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 2000.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	boot.viewports[0].add_child(cam)
	var views := [
		["overview_map", Vector3(0, 0, 0), 1600.0],
		["overview_j1", b.poi["j1"], 160.0],
		["overview_billboard", b.poi["billboard"], 160.0],
		["overview_bridge", b.poi["bridge"], 160.0],
	]
	for v in views:
		var c: Vector3 = v[1]
		cam.size = v[2]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(c.x, 600, c.z))
		cam.current = true
		await wait(0.4)
		await shot(v[0])
	cam.queue_free()
	p1().cam.current = true


## Stand `dist` metres from a point and look straight at it.
func face_point(p: PlayerRig, target: Vector3, dist: float, side := Vector3.ZERO) -> void:
	var dir := side if side != Vector3.ZERO else Vector3(1, 0, 0.3)
	dir.y = 0.0
	dir = dir.normalized()
	var stand := target + dir * dist
	stand.y = Landscape.ground(stand.x, stand.z) + 0.1
	var d := target - stand
	await place_player(p, stand, atan2(-d.x, -d.z))
	var eye := stand + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16)
	p.pitch = atan2(target.y - eye.y, Vector2(target.x - eye.x, target.z - eye.z).length())
	await physics_frames(3)


func find_can(tag: String) -> FuelCan:
	return boot.world.get_node("FuelCan_" + tag) as FuelCan


## Pick up, carry, drop, throw, pour into the van, stow on the rack, drive off
## with it, take it back.
func t_carry() -> void:
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	var can := find_can("home_can")
	await face_point(p, can.global_position + Vector3.UP * 0.25, 2.0)
	log_line("looking at the home can: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("Pick up fuel can (full)"), "a fuel can offers 'Pick up fuel can (full)'")
	await tap(KEY_E)
	await physics_frames(10)
	check(p.held == can, "E picks the can up")
	await wait(0.6)
	p.pitch = -0.1
	await wait(0.3)
	await shot("carry_holding")
	log_line("while holding: '%s'" % p.prompt_text)
	# carry it across open ground, sprint held
	# turn away from the garage wall and carry it across the open yard
	p.yaw = wrapf(p.yaw + PI, -PI, PI)
	p.pitch = 0.0
	await wait(0.5)
	var start := p.global_position
	key(KEY_W, true)
	key(KEY_SHIFT, true)
	await wait(2.0)
	var loaded_speed := planar_speed(p)
	key(KEY_SHIFT, false)
	key(KEY_W, false)
	await wait(0.4)
	var lag := can.global_position.distance_to(p.hold_point(can))
	log_line("carrying a full can (%.0f kg): %.2f m/s with sprint held, can %.2f m from the hold point" % [can.mass, loaded_speed, lag])
	check(p.held == can, "the can is still held after walking")
	check(loaded_speed < PlayerRig.WALK and loaded_speed > 2.0, "a full can slows you below walking pace and blocks sprint")
	await tap(KEY_E)
	await wait(1.0)
	check(p.held == null and can.global_position.distance_to(p.global_position) < 3.0, "E drops the can at your feet")

	# the empty can at the station: light, and throwable
	var empty := find_can("station_can_empty")
	await face_point(p, empty.global_position + Vector3.UP * 0.25, 2.0)
	log_line("looking at the empty can: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("(empty)"), "an empty can says it is empty before you lift it")
	await tap(KEY_E)
	await physics_frames(10)
	p.pitch = 0.0
	await wait(0.4)
	var t0 := empty.global_position
	await tap(KEY_G)
	await wait(2.0)
	var thrown := Vector2(empty.global_position.x - t0.x, empty.global_position.z - t0.z).length()
	log_line("empty can thrown %.1f m" % thrown)
	check(p.held == null and thrown > 3.0, "throwing sends a light can a few metres")

	# pour a full can into the van
	var c := camper()
	c.freeze = false
	await reset_camper(6)
	c.fuel = 20.0
	var full := find_can("station_can_a")
	full.global_position = c.global_transform * Vector3(-2.4, 0.2, 1.0)
	full.reset_physics_interpolation()
	await physics_frames(20)
	await face_point(p, full.global_position + Vector3.UP * 0.25, 1.8, -c.global_transform.basis.x)
	await tap(KEY_E)
	await physics_frames(10)
	var inlet := c.global_transform * (Vector3(-1.2, 1.40, 1.9) + Vector3(0, Camper.BODY_Y, 0))
	await face_point(p, inlet, 1.9, -c.global_transform.basis.x)
	await wait(0.5)
	log_line("holding a full can at the filler: '%s'" % p.prompt_text)
	await shot("carry_filler")
	check(p.prompt_text.contains("pour"), "the filler offers to pour when you hold a can")
	var f0 := c.fuel
	key(KEY_E, true)
	await wait(3.0)
	key(KEY_E, false)
	await physics_frames(3)
	log_line("poured %.1f L in 3 s; can now %.1f L" % [c.fuel - f0, full.litres])
	check(c.fuel - f0 > 12.0 and full.litres < 6.0, "holding E pours the can into the tank")
	check(p.held == full, "pouring keeps the can in your hands")

	# stow it on the rear rack
	var slot: Node3D = c.storage_slots[0]
	var slot_look := slot.global_position + Vector3.UP * 0.3
	await face_point(p, slot_look, 1.9, c.global_transform.basis.z)
	await wait(0.4)
	log_line("at the rack: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("Stow"), "the rack offers to stow the can")
	await tap(KEY_E)
	await physics_frames(5)
	check(c.stowed_item(slot) == full and p.held == null, "E stows the can on the rack")
	log_line("cargo on the rack: %.1f kg" % c.cargo_mass())
	# drive 60 m with it
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	var ad := AutoDriver.new(self, boot.builder.route, c)
	var rel0 := c.global_transform.affine_inverse() * full.global_position
	for _i in 60 * 6:
		await get_tree().physics_frame
		ad.step(40.0)
	ad.release()
	key(KEY_S, true)
	await wait(3.0)
	key(KEY_S, false)
	var rel1 := c.global_transform.affine_inverse() * full.global_position
	log_line("stowed can moved %.3f m relative to the van while driving" % rel0.distance_to(rel1))
	check(rel0.distance_to(rel1) < 0.05, "a stowed can rides along with the van")
	await wait(1.0)
	p.force_exit = true
	await physics_frames(5)
	await face_point(p, slot.global_position + Vector3.UP * 0.3, 1.9, c.global_transform.basis.z)
	await wait(0.4)
	log_line("at the loaded rack: '%s'" % p.prompt_text)
	await tap(KEY_E)
	await physics_frames(10)
	check(p.held == full and c.stowed_item(slot) == null, "E takes the can back off the rack")
	await tap(KEY_E)
	await wait(0.5)
	await shot("carry_done")


## The paper map: starts nearly blank, fills in by travel and by reading
## boards, takes shared stamps, and folds away when the van drives off.
func t_map() -> void:
	var b: LevelBuilder = boot.builder
	var ms: MapState = boot.map_state
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	await place_player(p, b.player_spawns[0].origin, 0.0)
	await tap(KEY_M)
	await wait(0.3)
	check(p.map_open and p.paper_map.visible, "M raises the paper map")
	check(ms.is_revealed("homestead") and ms.is_revealed("windmill"), "home and the windmill junction are on the map from the start")
	check(not ms.is_revealed("facility") and not ms.is_revealed("gas_station"), "far places start off the map")
	log_line("map known at start: %.0f%% of roads" % (ms.revealed_fraction() * 100.0))
	await shot("map_start")
	await tap(KEY_M)
	check(not p.map_open, "M puts it away again")

	# travel reveals: stand near the water works
	var fac: Vector3 = b.poi["facility"]
	await place_player(p, fac + Vector3(-40, 1, 0), 0.0)
	await wait(1.0)
	check(ms.is_revealed("facility"), "going near a landmark puts it on the map")

	# reading the Last Fuel info board sketches in its area
	var board: Vector3 = b.poi["info_pump_house_road12"]
	await face_point(p, board + Vector3.UP * 2.2, 2.6, b.network.road("pump_house_road").right(12) * -1.0)
	await wait(0.4)
	log_line("at the board: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("Read the board"), "info boards can be read")
	var gas_known_before := ms.is_revealed("gas_station")
	await tap(KEY_E)
	await wait(0.4)
	check(ms.is_revealed("gas_station") and ms.is_revealed("bridge"), "reading a board sketches the area around it onto the map")
	log_line("gas station known before reading: %s; map now %.0f%% of roads" % [gas_known_before, ms.revealed_fraction() * 100.0])
	await shot("board_note")

	# stamps: cycle to DANGER, place one, rub it out
	await tap(KEY_M)
	await wait(0.2)
	var n0 := ms.stamps.size()
	for _i in 10:
		mouse(Vector2(12, 6))
		await get_tree().process_frame
	await tap(KEY_E)
	check(p.paper_map.current_stamp() == "danger", "E cycles the stamp type while the map is up")
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	Input.parse_input_event(e)
	await wait(0.07)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await wait(0.2)
	check(ms.stamps.size() == n0 + 1 and ms.stamps[ms.stamps.size() - 1]["type"] == "danger", "left click places a stamp")
	check(p2().paper_map.state == ms, "both players' maps show the same stamps")
	await shot("map_stamped")
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_RIGHT
	r.pressed = true
	Input.parse_input_event(r)
	await wait(0.07)
	r = r.duplicate()
	r.pressed = false
	Input.parse_input_event(r)
	await wait(0.2)
	check(ms.stamps.size() == n0, "right click rubs the stamp out")
	await tap(KEY_M)

	# in the van: only while stopped
	await reset_camper(6)
	var c := camper()
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	await tap(KEY_M)
	check(p.map_open, "the map can be read in a stopped van")
	key(KEY_W, true)
	await wait(2.0)
	key(KEY_W, false)
	check(not p.map_open, "the map folds away when the van moves off")
	key(KEY_S, true)
	await wait(2.0)
	key(KEY_S, false)


## Walk from the foot of the lookout ramp up onto the deck.
func t_climb() -> void:
	var b: LevelBuilder = boot.builder
	var foot: Vector3 = b.poi["lookout_ramp_foot"]
	var deck: Vector3 = b.poi["lookout_deck"]
	foot.y = Landscape.ground(foot.x, foot.z) + 0.3
	var d := deck - foot
	var p := p1()
	await place_player(p, foot, atan2(-d.x, -d.z))
	key(KEY_W, true)
	await wait(5.0)
	key(KEY_W, false)
	await wait(0.5)
	log_line("lookout climb: feet at %.1f m, deck at %.1f m, %.1f m from the deck centre" % [p.global_position.y, deck.y - 0.2, Vector2(p.global_position.x - deck.x, p.global_position.z - deck.z).length()])
	check(p.global_position.y > deck.y - 0.6, "the lookout ramp can be walked up to the deck")
	await shot("lookout_climbed")


## Drive from the homestead to the bridge barrier by each route, by keyboard.
func t_journey() -> void:
	var b: LevelBuilder = boot.builder
	for way in [["ridge_track", "ridge"], ["valley_road", "valley"]]:
		var path := b.network.chain([["home_lane"], [way[0]], ["pump_house_road"]])
		var stop_at: int = int(path.nearest(b.poi["bridge_barrier_near"].x, b.poi["bridge_barrier_near"].z)["index"]) - 10
		var c := camper()
		c.freeze = false
		var p0 := path.point(4)
		var f := path.forward(4)
		c.linear_velocity = Vector3.ZERO
		c.angular_velocity = Vector3.ZERO
		c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), p0 + Vector3.UP * 0.9)
		c.reset_physics_interpolation()
		c.fuel = 52.0
		c.temp = Camper.TEMP_NORMAL
		await physics_frames(30)
		await seat_p1_driver()
		if not c.engine_on:
			c.toggle_engine()
		var ad := AutoDriver.new(self, path, c)
		var t := 0.0
		var stuck := 0.0
		var max_tilt := 0.0
		var temp_max := c.temp
		var fuel0 := c.fuel
		var shot_done := false
		while t < 420.0:
			await get_tree().physics_frame
			t += 1.0 / 60.0
			ad.step(-1.0)
			temp_max = maxf(temp_max, c.temp)
			max_tilt = maxf(max_tilt, rad_to_deg(acos(clampf(c.global_transform.basis.y.y, -1, 1))))
			stuck = stuck + 1.0 / 60.0 if kmh() < 2.0 else 0.0
			if stuck > 8.0 or ad.idx >= stop_at:
				break
			if not shot_done and t > 45.0:
				shot_done = true
				await shot("journey_" + way[1])
		ad.release()
		key(KEY_S, true)
		await wait(3.0)
		key(KEY_S, false)
		var arrived := ad.idx >= stop_at
		log_line("%s route: arrived=%s in %.0f s (%.0f m), off-road max %.1f m, tilt max %.0f deg, fuel %.1f L, temp max %.0f" % [
			way[1], arrived, t, ad.idx * Route.SAMPLE_SPACING, ad.max_off, max_tilt, fuel0 - c.fuel, temp_max])
		check(arrived, "keyboard driver reaches the bridge by the %s route" % way[1])
		check(ad.max_off < 6.0, "stays on the road along the %s route" % way[1])


## Mouse travel must map to the same turn however it is split across frames.
func t_mouse() -> void:
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	for pattern in [[1, 400], [20, 20], [100, 4]]:
		var yaw0 := p.yaw
		for _i in int(pattern[0]):
			mouse(Vector2(float(pattern[1]), 0))
			await get_tree().process_frame
		await wait(0.2)
		var turned := rad_to_deg(absf(wrapf(p.yaw - yaw0, -PI, PI)))
		log_line("%d events x %d px = %.1f deg" % [pattern[0], pattern[1], turned])
		check(absf(turned - rad_to_deg(400 * 0.0022)) < 2.0, "400 px of mouse always turns the same amount (%d x %d px)" % [pattern[0], pattern[1]])


## Quick taps must register exactly once, whatever the render frame rate.
func t_taps() -> void:
	var p := p1()
	var hits := 0
	var tries := 10
	for _i in tries:
		var before := p.flashlight.visible
		await tap(KEY_F, 0.035)
		await physics_frames(2)
		if p.flashlight.visible != before:
			hits += 1
	log_line("flashlight: %d / %d quick taps registered" % [hits, tries])
	check(hits == tries, "every quick key tap registers once")
	if p.flashlight.visible:
		p.toggle_flashlight()


func t_enter() -> void:
	var c := camper()
	await reset_camper(6)
	var p := p1()
	# stand 3 m from the driver's door, facing it
	var door := c.global_transform * Vector3(-1.2, 0.0, -1.8)
	var stand := c.global_transform * Vector3(-3.6, 0.0, -1.8)
	stand.y = door.y
	var d := door - stand
	await place_player(p, stand + Vector3.UP * 0.2, atan2(-d.x, -d.z))
	await wait(0.4)
	log_line("prompt at door: '%s'" % p.prompt_text)
	await shot("door_prompt")
	check(p.prompt_text.contains("driver"), "driver door shows a prompt when looked at")
	await tap(KEY_E)
	await physics_frames(3)
	check(p.seat != null and p.seat_role == "driver", "E at the door seats the player")
	await place_player(p2(), stand + Vector3.UP * 0.2, atan2(-d.x, -d.z))
	await wait(0.3)
	log_line("P2 at the occupied driver's door: '%s'" % p2().prompt_text)
	check(p2().prompt_text.contains("taken"), "an occupied seat says so instead of offering a dead button")


func t_cockpit() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if p2().seat == null:
		p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await wait(0.5)
	await shot("cockpit_default")
	# How much of the driver's view is road? Sample the centre column.
	p1().pitch = -0.35
	await wait(0.3)
	await shot("cockpit_look_down")
	p1().pitch = 0.0
	p2().force_exit = true
	await physics_frames(3)


func t_drive() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if c.engine_on:
		c.toggle_engine()
	await tap(KEY_X)
	await physics_frames(2)
	check(c.engine_on, "X starts the engine with a quick tap")
	if not c.engine_on:
		c.toggle_engine()

	var t := 0.0
	var t50 := -1.0
	var t80 := -1.0
	var top := 0.0
	var autodrive := AutoDriver.new(self, boot.builder.route, c)
	for _i in 60 * 16:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		autodrive.step(999.0)
		var v := kmh()
		top = maxf(top, v)
		if t50 < 0 and v >= 50.0:
			t50 = t
		if t80 < 0 and v >= 80.0:
			t80 = t
		if absf(t - 3.0) < 0.009:
			await shot("drive_3s")
	autodrive.release()
	log_line("0-50 km/h %.1f s, 0-80 km/h %.1f s, top in 16 s %.0f km/h, off-road max %.1f m" % [t50, t80, top, autodrive.max_off])
	check(t50 > 0 and t50 < 12.0, "van reaches 50 km/h in reasonable time")


func t_brake() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if not c.engine_on:
		c.toggle_engine()
	var ad := AutoDriver.new(self, boot.builder.route, c)
	for _i in 60 * 20:
		await get_tree().physics_frame
		ad.step(999.0)
		if kmh() >= 60.0:
			break
	ad.release()
	var v0 := kmh()
	var p0 := c.global_position
	key(KEY_S, true)
	var frames := 0
	while kmh() > 1.0 and frames < 60 * 15:
		await get_tree().physics_frame
		ad.steer_only()
		frames += 1
	key(KEY_S, false)
	ad.release()
	var dist := p0.distance_to(c.global_position)
	log_line("brake from %.0f km/h: %.1f m in %.1f s" % [v0, dist, frames / 60.0])
	check(dist < 45.0, "braking from ~60 km/h stops within 45 m")
	# does holding S at rest then reverse?
	key(KEY_S, true)
	await wait(2.0)
	var rev := -c.global_transform.basis.z.dot(c.linear_velocity) * 3.6
	key(KEY_S, false)
	log_line("holding S at rest for 2 s: %.1f km/h (negative = reversing)" % rev)
	check(rev < -3.0, "holding brake at a stop reverses")


func t_lap() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if not c.engine_on:
		c.toggle_engine()
	var ad := AutoDriver.new(self, boot.builder.route, c)
	var t := 0.0
	var max_roll := 0.0
	var flipped := false
	var stuck_t := 0.0
	var fuel0 := c.fuel
	var temp_max := c.temp
	var shots := 0
	while t < 180.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		ad.step(-1.0)
		var up := c.global_transform.basis.y
		max_roll = maxf(max_roll, rad_to_deg(acos(clampf(up.y, -1, 1))))
		temp_max = maxf(temp_max, c.temp)
		if up.y < 0.3:
			flipped = true
			break
		if kmh() < 2.0:
			stuck_t += 1.0 / 60.0
			if stuck_t > 6.0:
				break
		else:
			stuck_t = 0.0
		if ad.progress >= boot.builder.route.point_count():
			break
		if shots < 3 and t > 20.0 + shots * 25.0:
			shots += 1
			await shot("lap_%d" % shots)
	ad.release()
	var done: bool = ad.progress >= boot.builder.route.point_count()
	log_line("lap: done=%s time %.1f s, avg %.0f km/h, max off-road %.1f m, max tilt %.1f deg, flipped=%s, fuel used %.1f L, max temp %.0f" % [
		done, t, boot.builder.route.total_length / t * 3.6 if done else 0.0, ad.max_off, max_roll, flipped, fuel0 - c.fuel, temp_max])
	log_line("lap: keyboard steer switches %d, time over road edge %.1f s" % [ad.steer_switches, ad.off_time])
	check(done, "keyboard driver can complete the loop")
	check(not flipped, "van does not flip on the loop")
	check(temp_max < Camper.TEMP_WARN, "a normal lap does not trip the overheat lamp")
	check(ad.max_off < 6.0, "keyboard driver can stay on the road")


func t_exit() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if not c.engine_on:
		c.toggle_engine()
	# exit at rest
	await wait(0.3)
	await tap(KEY_E)
	await physics_frames(10)
	var p := p1()
	var gap := p.global_position.distance_to(c.global_position)
	log_line("exit at rest: seat=%s, %.1f m from van, on floor=%s" % [str(p.seat), gap, p.is_on_floor()])
	check(p.seat == null, "E gets out of the van")
	await wait(1.0)
	log_line("1 s after exit: on floor=%s, speed %.2f" % [p.is_on_floor(), p.velocity.length()])
	# exit while rolling
	p.enter_seat(c, c.seat_nodes["driver"], "driver")
	var ad := AutoDriver.new(self, boot.builder.route, c)
	for _i in 60 * 10:
		await get_tree().physics_frame
		ad.step(999.0)
		if kmh() > 45.0:
			break
	ad.release()
	var v := kmh()
	await tap(KEY_E)
	await wait(1.5)
	log_line("exit at %.0f km/h: player seat=%s, player speed %.1f m/s" % [v, str(p.seat), p.velocity.length()])
	check(p.seat != null, "E does not throw you out of a van doing %.0f km/h" % v)
	# stop and leave
	key(KEY_S, true)
	await wait(4.0)
	key(KEY_S, false)
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)


func t_swap() -> void:
	await reset_camper(6)
	var c := camper()
	c.linear_velocity = Vector3.ZERO
	await seat_p1_driver()
	await wait(0.3)
	await tap(KEY_C)
	await physics_frames(3)
	check(p1().seat_role == "passenger", "C swaps seats when stopped")
	if p1().seat != null:
		p1().force_exit = true
		await physics_frames(3)


func t_perf() -> void:
	await reset_camper(6)
	await seat_p1_driver()
	var c := camper()
	if not c.engine_on:
		c.toggle_engine()
	if p2().seat == null:
		p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	var ad := AutoDriver.new(self, boot.builder.route, c)
	_frame_times.clear()
	var skips0: int = c._audio._playback.get_skips()
	# Camera smoothness: per rendered frame, how far the camera moved divided by
	# the frame time should be a steady speed. Without interpolation at 144 Hz
	# it alternates between standing still and jumping.
	var cam := p1().cam
	var last := cam.global_position
	var rates: PackedFloat32Array = PackedFloat32Array()
	var shake: PackedFloat32Array = PackedFloat32Array()
	var last_b := cam.global_transform.basis
	var t := 0.0
	while t < 12.0:
		var dt := get_process_delta_time()
		await get_tree().process_frame
		t += dt
		ad.step(45.0)
		var now := cam.global_position
		if t > 5.0 and dt > 0.0:
			rates.append(now.distance_to(last) / dt)
			# roll + pitch change per frame, ignoring the steering yaw
			var b := cam.global_transform.basis
			shake.append(rad_to_deg(absf(b.x.y - last_b.x.y)) + rad_to_deg(absf(b.z.y - last_b.z.y)))
		last = now
		last_b = cam.global_transform.basis
	ad.release()
	var mean := 0.0
	for r in rates:
		mean += r
	mean /= maxf(1.0, rates.size())
	var var_sum := 0.0
	for r in rates:
		var_sum += (r - mean) * (r - mean)
	var cv := sqrt(var_sum / maxf(1.0, rates.size())) / maxf(0.001, mean)
	var sh := 0.0
	for x in shake:
		sh = maxf(sh, x)
	log_line("driver view shake: worst frame-to-frame tilt %.2f deg" % sh)
	log_line("camera motion while driving: mean %.1f m/s, frame-to-frame variation %.0f%%" % [mean, cv * 100.0])
	check(cv < 0.25, "camera moves smoothly every rendered frame (no 60 Hz judder)")
	var arr := _frame_times.duplicate()
	arr.sort()
	var avg := 0.0
	for f in arr:
		avg += f
	avg /= maxf(1.0, arr.size())
	var p95 := arr[int(arr.size() * 0.95)] if arr.size() > 0 else 0.0
	var p99 := arr[int(arr.size() * 0.99)] if arr.size() > 0 else 0.0
	var skips: int = c._audio._playback.get_skips() - skips0
	log_line("engine audio buffer underruns during 12 s of driving: %d" % skips)
	check(skips == 0, "engine audio is fed without dropouts while driving")
	log_line("driving, both players seated: avg %.1f fps, p95 frame %.1f ms, p99 %.1f ms" % [1.0 / avg, p95 * 1000.0, p99 * 1000.0])
	check(1.0 / avg > 55.0, "holds 60 fps with both views while driving")
	p2().force_exit = true
	await physics_frames(3)


# --- keyboard auto-driver ------------------------------------------------------

## Drives like a keyboard player: W/S and A/D are on or off, nothing analogue.
class AutoDriver:
	var t: PlayTest
	var route: Route
	var van: Camper
	var idx := -1
	var progress := 0
	var max_off := 0.0
	var off_time := 0.0
	var steer_switches := 0
	var _last_steer := 0

	func _init(test: PlayTest, r: Route, c: Camper) -> void:
		t = test
		route = r
		van = c

	func _track() -> void:
		var near := route.nearest(van.global_position.x, van.global_position.z)
		var ni: int = near["index"]
		if ni < 0:
			max_off = maxf(max_off, 99.0)
			return
		if idx < 0:
			idx = ni
		var n := route.point_count()
		var dlt := wrapi(ni - idx, -n / 2, n / 2)
		if dlt > 0:
			progress += dlt
			idx = ni
		max_off = maxf(max_off, float(near["dist"]))
		if float(near["dist"]) > Landscape.ROAD_HALF:
			off_time += 1.0 / 60.0

	func steer_only() -> void:
		_track()
		var v := van.linear_velocity.length()
		var look := int(4 + v * 0.55)
		var target := route.point(idx + look)
		var local := van.global_transform.affine_inverse() * target
		var ang := atan2(local.x, -local.z)
		var want := 0
		if ang > 0.05:
			want = 1
		elif ang < -0.05:
			want = -1
		if want != _last_steer:
			steer_switches += 1
			_last_steer = want
		t.key(KEY_D, want == 1)
		t.key(KEY_A, want == -1)

	## target_kmh < 0 picks a cornering speed from the road ahead
	func step(target_kmh: float) -> void:
		steer_only()
		var target := target_kmh
		if target < 0.0:
			var f0 := route.forward(idx)
			var bend := 0.0
			for k in range(4, 30, 3):
				bend = maxf(bend, acos(clampf(Vector2(f0.x, f0.z).normalized().dot(Vector2(route.forward(idx + k).x, route.forward(idx + k).z).normalized()), -1, 1)))
			target = lerp(70.0, 35.0, clampf(bend / 0.9, 0.0, 1.0))
		var v := van.linear_velocity.length() * 3.6
		t.key(KEY_W, v < target)
		t.key(KEY_S, v > target + 8.0)

	func release() -> void:
		for k in [KEY_W, KEY_A, KEY_S, KEY_D]:
			t.key(k, false)
