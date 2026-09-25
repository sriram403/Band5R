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
## No window and no GPU (`--headless`, e.g. CI or tools/run_test_headless.sh):
## screenshots are skipped and frame-rate checks are only logged.
var headless := DisplayServer.get_name() == "headless"

## Quick runs basic input/vehicle mechanics in the base gym, then checks the
## story, map, puzzle, save/load and rendering in the real world by teleport.
const QUICK_GYM := ["gym", "mouse", "taps", "enter", "cockpit", "layout", "drive", "brake", "exit", "swap"]
const QUICK_WORLD := ["roadworks", "house_world", "traffic_world", "driveway", "audio", "dev", "mirrors", "map", "story", "waterworks", "climb", "carry", "look", "pad", "perf", "save"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playtest="):
			only = a.get_slice("=", 1)
	# Stay out of the way of whatever the user is doing. tools/run_test.sh opens the
	# window off screen; here it moves on screen but BEHIND every other window,
	# without taking focus. The user can click it (or its taskbar button) to watch
	# and hear it; clicking elsewhere sends it back. Muted unless it has focus.
	# Pass --show (after the --) for a plain window in front.
	if not OS.get_cmdline_user_args().has("--show"):
		AudioServer.set_bus_mute(0, true)
		_send_window_behind()
	_run.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not OS.get_cmdline_user_args().has("--show"):
		AudioServer.set_bus_mute(0, true)


## Windows only, via a hidden PowerShell: give focus back to the window the user
## had before the launch (tools/run_test.sh passes it as --refocus=<hwnd>), then
## SetWindowPos(HWND_BOTTOM, NOACTIVATE), centred on the primary screen.
func _send_window_behind() -> void:
	if OS.get_name() != "Windows":
		return
	var hwnd := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
	var screen := DisplayServer.screen_get_usable_rect(0)
	var size := DisplayServer.window_get_size_with_decorations()
	var pos := screen.position + (screen.size - size) / 2
	var sig := "[DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);"
	sig += " [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr h);"
	var prev := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--refocus="):
			prev = a.get_slice("=", 1).to_int()
	var ps := "Add-Type -Name W -Namespace U -MemberDefinition '%s'; " % sig
	if prev != 0:
		ps += "[void][U.W]::SetForegroundWindow([IntPtr]%d); " % prev
	ps += "[void][U.W]::SetWindowPos([IntPtr]%d, [IntPtr]1, %d, %d, 0, 0, 0x11)" % [hwnd, maxi(pos.x, 0), maxi(pos.y, 0)]
	# -EncodedCommand (UTF-16LE base64) so the quotes survive the command line.
	OS.create_process("powershell.exe", ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden",
		"-EncodedCommand", Marshalls.raw_to_base64(ps.to_utf16_buffer())])


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


## Hold a key for whole physics ticks. The press is sent again only if a window
## focus change dropped it: a fresh press every tick would read as 60 taps a second.
func hold_physics(k: Key, seconds: float) -> void:
	key(k, true)
	for _i in int(ceil(seconds * 60.0)):
		await get_tree().physics_frame
		if not Input.is_physical_key_pressed(k):
			key(k, true)
	key(k, false)
	await physics_frames(3)  # let the release land (a pour lets go of the can)


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
	if headless:
		return      # nothing is drawn (and frame_post_draw never fires)
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
	p._plan_vel = Vector2.ZERO
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
	c.parking_brake = true      # a parked van
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
		"%s at %s" % [DisplayServer.window_get_size(), DisplayServer.window_get_position()],
		str(Input.get_connected_joypads())])
	log_line("route length %.0f m, %d samples" % [boot.builder.route.total_length, boot.builder.route.point_count()])

	# After a load test reloaded the scene, only finish that check.
	if PlayTest.resume != "":
		var r := PlayTest.resume
		PlayTest.resume = ""
		_failures = PlayTest.carried_failures.duplicate()
		log_line("---- %s (after scene reload) ----" % r)
		var resumed_at := Time.get_ticks_msec()
		await call("t_" + r)
		log_line("time %s %.1f s (after reload)" % [r, (Time.get_ticks_msec() - resumed_at) / 1000.0])
		_finish()
		return
	var all := ["audio", "fixes", "dev", "mirrors", "feedback", "map", "story", "waterworks", "overview", "tour", "climb", "carry", "journey", "mouse", "foot", "taps", "enter", "cockpit", "layout", "park", "solid", "crash", "look", "pad", "drive", "brake", "lap", "exit", "swap", "perf", "save"]
	if boot.gym != "":
		all = ["tyre"] if boot.gym == "tyre" else (["house"] if boot.gym == "house" else (["traffic"] if boot.gym == "traffic" else ["gym"]))
	var selection := only
	if selection == "quick" or selection == "gym_quick":
		if boot.gym == "tyre":
			all = ["tyre"]
		elif boot.gym == "house":
			all = ["house"]
		elif boot.gym == "traffic":
			all = ["traffic"]
		else:
			all = QUICK_GYM.duplicate() if boot.gym != "" else QUICK_WORLD.duplicate()
		selection = ""
	elif selection == "full":
		if boot.gym != "":
			all = ["tyre"] if boot.gym == "tyre" else (["house"] if boot.gym == "house" else (["traffic"] if boot.gym == "traffic" else QUICK_GYM.duplicate()))
		else:
			all.insert(all.find("save"), "routes")
		selection = ""
	# Scenarios outside a preset can still run by name.
	if selection != "":
		for extra in selection.split(","):
			if not extra in all and has_method("t_" + extra):
				all.append(extra)
	for s in all:
		if selection != "" and not s in selection.split(","):
			continue
		log_line("---- %s ----" % s)
		var started_at := Time.get_ticks_msec()
		release_all()
		await fresh_hands()
		await call("t_" + s)
		release_all()
		log_line("time %s %.1f s" % [s, (Time.get_ticks_msec() - started_at) / 1000.0])
		if PlayTest.resume != "":
			return      # the scene is reloading; the new test node finishes up
	_finish()


func _finish() -> void:
	log_line("window ended at %s" % DisplayServer.window_get_position())
	log_line("==== %d failure(s) ====" % _failures.size())
	for f in _failures:
		log_line("  - " + f)
	get_tree().quit(1 if not _failures.is_empty() else 0)


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
	var starting_layout: int = boot.layout
	var solo_default: bool = boot.layout == 2
	check(solo_default == (Input.get_connected_joypads().size() == 0), "solo view is the default only when no controller is connected")
	var pad_for_p2: bool = boot.devices[1].kind == InputDevice.Kind.PAD
	if pad_for_p2:
		boot._set_layout(Boot.Layout.SOLO)
	await tap(KEY_TAB)
	await wait(0.4)
	if pad_for_p2:
		check(boot.kbm_owner == 0 and boot.views[0].visible and not boot.views[1].visible, "with a pad for P2, TAB leaves the keyboard and solo view on P1")
		boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	else:
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
	if pad_for_p2:
		boot._set_layout(Boot.Layout.SOLO)
	await tap(KEY_F2)
	await wait(0.4)
	check(boot.views[0].visible and boot.views[1].visible, "F2 goes to side-by-side split")
	await shot("split_side")
	await tap(KEY_F2)
	await wait(0.4)
	check(boot.views[0].visible and boot.views[1].visible and boot.split.vertical, "F2 goes to stacked split")
	await shot("split_stacked")
	await tap(KEY_F2)
	await wait(0.2)
	p2().force_exit = true
	await physics_frames(3)
	boot._set_layout(starting_layout)


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
	if not c.parking_brake:
		await tap(KEY_SPACE)
	await wait(1.0)
	var p0 := c.global_position
	await wait(5.0)
	var off_drift := p0.distance_to(c.global_position)
	c.toggle_engine()
	await wait(1.0)
	p0 = c.global_position
	await wait(5.0)
	var idle_drift := p0.distance_to(c.global_position)
	log_line("parked on the handbrake 5 s: engine off drift %.2f m, idling drift %.2f m" % [off_drift, idle_drift])
	check(off_drift < 0.1, "on the handbrake, a van with the engine off stays put on a slope")
	check(idle_drift < 0.1, "on the handbrake, an idling van stays put on a slope")
	# and it can still pull away uphill from the handbrake
	key(KEY_W, true)
	await wait(2.0)
	key(KEY_W, false)
	log_line("pull away from the handbrake: %.0f km/h after 2 s" % kmh())
	check(kmh() > 10.0, "van pulls away normally from the handbrake")
	key(KEY_S, true)
	await wait(3.0)
	key(KEY_S, false)


## Walk at solid-looking things and see whether the player goes through them.
func t_solid() -> void:
	var p := p1()
	var targets := []
	# the nearest rock and a tree far from the road, found from the scatter
	var r: Route = boot.builder.route
	var best_rock := Vector3.ZERO
	var best_rock_s := 0.0
	var home: Route = boot.builder.network.road("home_lane")
	# (from the builder's lists: a headless run has no renderer to ask the
	# MultiMeshes where their instances are)
	for xf: Transform3D in boot.builder.scatter["Rocks"]:
		var sc := xf.basis.get_scale().x
		if sc > 1.6 and sc > best_rock_s and float(home.nearest(xf.origin.x, xf.origin.z)["dist"]) < 60.0:
			best_rock_s = sc
			best_rock = xf.origin
	targets.append({"name": "big rock", "pos": best_rock})
	for xf: Transform3D in boot.builder.scatter["Trunks"]:
		var o := xf.origin
		if Landscape.road_distance(o.x, o.z) > 90.0 and Vector2(o.x - r.point(0).x, o.z - r.point(0).z).length() < 900.0:
			targets.append({"name": "tree 90 m+ from road", "pos": o})
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
	boot.menu = "title"
	boot.menu_sel = 0
	boot._refresh_overlay()
	boot.overlay.visible = true
	await wait(0.3)
	check(boot._menu_items() == ["New game", "Load game", "Quit"], "the title menu offers New game / Load game / Quit")
	await shot("title")
	boot.menu = ""
	boot.overlay.visible = false
	await tap(KEY_ESCAPE)
	await wait(0.3)
	check(get_tree().paused, "ESC pauses")
	check(boot.menu == "pause" and boot._menu_items()[1] == "Load game", "the pause menu offers Resume / Load / Quit")
	boot.menu_sel = 1
	boot._menu_accept()
	check(boot.menu == "load" and boot._menu_items().size() == SaveGame.SLOTS + 1, "Load game lists the three journal slots")
	await tap(KEY_ESCAPE)
	check(boot.menu == "pause", "ESC goes back from the load list")
	boot.story.flags["test_progress"] = true
	boot.menu_sel = 2
	boot._menu_accept()
	check(boot.menu == "quit_confirm", "quitting with unsaved progress asks first")
	await tap(KEY_ESCAPE)
	boot.story.flags.erase("test_progress")
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
	# left on with the engine off, they run the battery flat - and go out
	var c := camper()
	if c.engine_on:
		c.toggle_engine()
	var batt := c.battery
	c.battery = 0.03
	await wait(4.0)
	log_line("battery %.3f, headlights switched on %s, lit %s" % [c.battery, c.headlights_on, c._headlight_nodes[0].visible])
	check(c.battery <= 0.02 and not c._headlight_nodes[0].visible, "headlights left on die when the battery goes flat")
	c.battery = batt
	await physics_frames(2)
	check(c._headlight_nodes[0].visible, "and shine again once there is charge")
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
	await pad_tap(JOY_BUTTON_DPAD_RIGHT)
	check(p.phone_open, "D-pad right raises Player 2's phone")
	await pad_tap(JOY_BUTTON_DPAD_RIGHT)
	check(not p.phone_open, "D-pad right puts Player 2's phone away")
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
	# the pad drops out (flat battery): the game pauses and P2 falls back to
	# the keyboard in the solo view - which also leaves the session as it was
	boot._on_joy_changed(0, false)
	await physics_frames(2)
	check(boot.devices[1].kind == InputDevice.Kind.KBM and p.dev == boot.devices[1], "a disconnected controller hands Player 2 back to the keyboard")
	check(boot.paused and boot.layout == 2 and boot.pause_note != "", "and the game pauses and says why, in the solo view")
	boot._toggle_pause()
	await physics_frames(2)
	check(not boot.paused and boot.pause_note == "", "resuming clears the note")


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
		["tour_14_town", b.network.road("home_lane").point(200), b.poi["town_fuel"]],
		["tour_15_p2_home", b.network.road("home_lane").point(480), b.poi["p2_home"]],
		["tour_16_ghat_hairpins", b.network.road("ghat_road").point(40), b.poi["ghat_pass"] + Vector3(0, 20, 0)],
		["tour_17_coast_tower_view", b.poi["coast_tower_deck"], b.poi["roses"] + Vector3(0, 10, 0)],
		["tour_18_beach", b.poi["beach"] + Vector3(-20, 0, -60), b.poi["beach"] + Vector3(40, 0, 60)],
		["tour_19_fishing_village", _road_before("coast_road", b.poi["fishing_village"], 50), b.poi["fishing_village"]],
		["tour_20_salt_pans", _road_before("coast_road", b.poi["salt_pans"], 60), b.poi["salt_pans"]],
		["tour_21_estuary_bridge", _road_before("coast_road", b.poi["estuary_bridge"], 45) + Vector3(0, 3, 0), b.poi["estuary_bridge"]],
		["tour_22_tunnel_portal", b.poi["tunnel_portal"], b.poi["tunnel"] + Vector3(0, 5, 0)],
		["tour_23_naresh_home", b.network.road("west_road").point(40), b.poi["naresh_home"]],
		["tour_24_end_tower_view", b.poi["end_tower_deck"], b.poi["j1"] + Vector3(0, 0, 0)],
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


## A point on a road `back` samples before its nearest point to `at`.
func _road_before(road_name: String, at: Vector3, back: int) -> Vector3:
	var r: Route = boot.builder.network.road(road_name)
	var i := 0
	var best := 1e9
	for k in r.point_count():
		var d := Vector2(r.point(k).x - at.x, r.point(k).z - at.z).length()
		if d < best:
			best = d
			i = k
	return r.point(maxi(0, i - back))


## Orthographic shots from straight above: whole map, then close-ups.
func t_overview() -> void:
	var b: LevelBuilder = boot.builder
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 2000.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	boot.viewports[0].add_child(cam)
	var views := [
		["overview_map", Vector3(0, 0, 0), 4000.0],
		["overview_j1", b.poi["j1"], 160.0],
		["overview_billboard", b.poi["billboard"], 160.0],
		["overview_bridge", b.poi["bridge"], 160.0],
		["overview_home_town", Vector3(-1250, 0, 1520), 700.0],
		["overview_ghat", Vector3(900, 0, -80), 700.0],
		["overview_bessi", Vector3(1720, 0, 560), 600.0],
		["overview_coast_north", Vector3(1650, 0, -1000), 900.0],
		["overview_tunnel", b.poi.get("tunnel", Vector3.ZERO), 500.0],
		["overview_naresh", Vector3(-1600, 0, -900), 400.0],
	]
	var env: Environment = (boot.world.get_node("Environment") as WorldEnvironment).environment
	env.fog_enabled = false         # straight down from 600 m the haze hides the map
	for v in views:
		var c: Vector3 = v[1]
		cam.size = v[2]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(c.x, 600, c.z))
		cam.current = true
		await wait(0.4)
		await shot(v[0])
	env.fog_enabled = true
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


## Put a can back where the level placed it, full or as given, off any rack.
func reset_can(tag: String, litres: float) -> FuelCan:
	var can := find_can(tag)
	if can.stowed_in != null:
		can.unstow()
	for h in can.holders.duplicate():
		h.drop_held()
	can.litres = litres
	can._update_mass()
	can._refresh_prompt()
	can.pouring = false
	can.global_transform = Transform3D(Basis(), boot.builder.poi[tag])
	can.linear_velocity = Vector3.ZERO
	can.angular_velocity = Vector3.ZERO
	can.reset_physics_interpolation()
	await physics_frames(20)
	return can


## Every scenario starts with empty hands and nothing open, whatever the last
## one left behind.
func fresh_hands() -> void:
	for pl in boot.players:
		pl.drop_held()
		pl.set_map_open(false)
		pl.journal_open = false
	await physics_frames(2)


func find_can(tag: String) -> FuelCan:
	# it may have been stowed on the van's rack by an earlier scenario
	return boot.world.find_child("FuelCan_" + tag, true, false) as FuelCan


## Pick up, carry, drop, throw, pour into the van, stow on the rack, drive off
## with it, take it back.
func t_carry() -> void:
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	var can := await reset_can("home_can", FuelCan.CAPACITY)
	await reset_can("station_can_a", FuelCan.CAPACITY)
	await reset_can("station_can_empty", 0.0)
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
	# the cans are stashed behind the kiosk: come at them from behind it
	var behind: Vector3 = -(boot.world.get_node("LastFuel") as Node3D).global_transform.basis.z
	await face_point(p, empty.global_position + Vector3.UP * 0.25, 2.0, behind)
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
	var full := await reset_can("station_can_a", FuelCan.CAPACITY)
	full.global_position = c.global_transform * Vector3(-2.4, 0.2, 1.0)
	full.reset_physics_interpolation()
	# let it settle (it can slide a little on a sloping verge) before aiming at it
	await physics_frames(20)
	await wait(1.2)
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
	await tap(KEY_SPACE)        # handbrake on before getting out
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
	# zoomed in, the rubber only reaches what is near the pencil on the paper
	var pm := p.paper_map
	ms.add_stamp("fuel", pm.cursor_world() + Vector2(60, 0))
	pm.zoom = 6.0
	var rubbed_far := pm.remove_stamp()
	pm.zoom = 1.0
	var rubbed_near := pm.remove_stamp()
	check(not rubbed_far and rubbed_near, "zoomed in, rubbing out only reaches stamps near the pencil")
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


## Put the van on a road near a point of interest, facing along the road.
func van_to(poi_pos: Vector3) -> void:
	var c := camper()
	var near: Dictionary = boot.builder.network.nearest(poi_pos.x, poi_pos.z)
	var r: Route = near["road"]
	var i: int = near["index"]
	var p := r.point(i)
	var f := r.forward(i)
	c.freeze = false
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), p + Vector3.UP * 0.9)
	c.reset_physics_interpolation()
	c.parking_brake = true      # a parked van
	await physics_frames(20)


## The opening, in order: letter, spare can, windmill, the road choice,
## refuelling at Last Fuel, and the road north.
func t_story() -> void:
	var b: LevelBuilder = boot.builder
	var st: Story = boot.story
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	await wait(0.5)
	log_line("objective at start: '%s'" % st.objective_text())
	check(st.current()["id"] == "read_letter", "the first objective is to read the letter")
	await face_point(p, b.poi["letter"], 1.6, Vector3(0, 0, 1))
	await wait(0.3)
	log_line("at the crate: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("Read the letter"), "the letter can be read")
	await tap(KEY_E)
	await wait(0.6)
	check(boot.huds[0]._note.visible and boot.huds[0]._note_text.text.contains("friend"), "the letter appears and mentions the friend")
	await shot("story_letter")
	check(st.current()["id"] == "spare_can", "then: take the spare can")

	# hold H for the hint
	key(KEY_H, true)
	await wait(0.3)
	log_line("hint: '%s'" % boot.huds[0]._objective_hint.text)
	check(boot.huds[0]._objective_hint.text.contains("garage"), "holding H shows the hint")
	key(KEY_H, false)

	# stow the home can on the rack
	var can := find_can("home_can")
	await face_point(p, can.global_position + Vector3.UP * 0.25, 1.8)
	await tap(KEY_E)
	await physics_frames(10)
	var c := camper()
	var slot: Node3D = c.storage_slots[0]
	await face_point(p, slot.global_position + Vector3.UP * 0.3, 1.9, c.global_transform.basis.z)
	await wait(0.3)
	await tap(KEY_E)
	await wait(0.6)
	check(st.current()["id"] == "to_windmill", "stowing the can moves on to: drive to the windmill")

	# arrive at the windmill: the first old text from Naresh
	await seat_p1_driver()
	await van_to(b.poi["j1"])
	await wait(0.8)
	log_line("objective at the windmill: '%s'" % st.objective_text())
	check(st.current()["id"] == "choose_road", "at the windmill: choose a road")
	check(st.flags.has("text_j1") and boot.huds[0]._note_text.text.contains("I mean I am"), "an old text from Naresh arrives at the windmill")
	await shot("story_text_j1")

	# Last Fuel, low on fuel
	c.fuel = 18.0
	await van_to(b.poi["j2"])
	await wait(0.8)
	check(st.current()["id"] == "refuel", "at Last Fuel: refuel")
	c.fuel = 44.0
	await wait(0.6)
	check(st.current()["id"] == "pump_road", "a full tank moves on to: Pump House Road")
	await van_to(b.poi["facility"])
	await wait(0.6)
	log_line("objective at the water works: '%s'" % st.objective_text())
	check(st.current()["id"] == "coolant" and camper().coolant_leak, "near the water works the hose splits: get coolant")
	p.force_exit = true
	await physics_frames(3)


func station() -> CoolingStation:
	return get_tree().get_first_node_in_group("cooling_station") as CoolingStation


## Beat 3 end to end: the hose splits on the way in, the engine boils and
## cuts out, the valves and pump fill the blue tank, the coolant fixes the
## van, fragments and clues are found.
func t_waterworks() -> void:
	var b: LevelBuilder = boot.builder
	var st: Story = boot.story
	var c := camper()
	var p := p1()
	var fac: Node3D = boot.world.get_node("WaterFacility")
	var yard_side := fac.global_transform.basis * Vector3(0, 0, -1)
	# on Pump House Road, heading for the water works, story at "pump_road"
	var road := b.network.road("pump_house_road")
	var start_i: int = int(road.nearest(b.poi["facility"].x, b.poi["facility"].z)["index"]) - 110
	await van_to(road.point(start_i))
	st.index = 5
	c.coolant_leak = false
	c.heat_lockout = false
	c.temp = Camper.TEMP_NORMAL
	st.flags.erase("leak_started")
	st.flags.erase("leak_fixed")
	c.fuel = 50.0
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	var path := road
	var ad := AutoDriver.new(self, path, c)
	var t := 0.0
	while t < 60.0 and not c.coolant_leak:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		ad.step(35.0)
	check(c.coolant_leak and st.flags.has("leak_started"), "the coolant hose splits on the approach to the water works")
	log_line("hose split %.0f m from the water works" % Vector2(c.global_position.x - b.poi["facility"].x, c.global_position.z - b.poi["facility"].z).length())
	await wait(0.5)
	await shot("ww_steam")
	check(c._steam.emitting, "steam pours from the grille")
	# the puffs must live out their lifetime and rise (resetting the particle
	# count every tick used to kill them all at once, so none ever rose)
	# (the cloud's size comes from the renderer, so only a windowed run can check it)
	if not headless:
		var steam_box := c._steam.capture_aabb()
		log_line("steam cloud: %.2f m tall, %.2f m wide" % [steam_box.size.y, steam_box.size.x])
		check(steam_box.size.y > 1.0, "the steam rises in a cloud above the grille")
	# keep the engine running hard until it boils over
	var t0 := c.temp
	var cut := false
	t = 0.0
	while t < 90.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		ad.step(12.0)
		if not c.engine_on:
			cut = true
			break
	ad.release()
	log_line("temperature %.0f -> %.0f C in %.0f s; engine cut out: %s; power at cut-out %.0f%%" % [t0, c.temp, t, cut, c.heat_power() * 100.0])
	check(cut and c.heat_lockout, "left running, the boiling engine cuts out")
	await tap(KEY_X)
	await physics_frames(3)
	log_line("restart attempt: '%s'" % c.start_fail)
	check(not c.engine_on and c.start_fail.contains("Too hot"), "it will not restart while boiling, and says why")

	# into the yard: the objective asks for coolant
	await wait(0.5)
	check(st.current()["id"] == "coolant", "the objective becomes: get coolant from the water works")
	await tap(KEY_SPACE)        # stalled on the climb: handbrake on before getting out
	p.force_exit = true
	await physics_frames(3)
	var sta := station()
	# wrong route first (as built: valve A sends everything to the grey tank)
	await face_point(p, b.poi["pump_handle"], 1.5, yard_side)
	await wait(0.3)
	log_line("at the pump: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("pump"), "the pump handle can be worked")
	key(KEY_E, true)
	await wait(5.0)
	key(KEY_E, false)
	log_line("held the pump 5 s on the wrong route: pops %d, grey tank %.0f%%, blue tank %.0f%%" % [sta.pops, sta.fill["waste"] * 100.0, sta.fill["coolant"] * 100.0])
	check(sta.pops >= 1, "over-pumping pops the relief valve")
	check(sta.fill["coolant"] == 0.0 and sta.fill["waste"] > 0.0, "the wrong route fills the grey tank, not the blue one")
	await shot("ww_pump")
	# set the valves by walking to them (the valve player's job)
	for v in [["valve_a", "a"], ["valve_b", "b"]]:
		await face_point(p, b.poi[v[0]], 1.6, yard_side)
		await wait(0.3)
		log_line("at %s: '%s'" % [v[0], p.prompt_text])
		await tap(KEY_E)
	log_line("valves now: A -> %s, B -> %s, route %s" % [sta.valve_a, sta.valve_b, sta.route()])
	check(sta.route() == "coolant", "turning both valves routes the line to the blue tank")
	await shot("ww_valves")
	# pump in bursts, keeping the needle in the green. Played as two people:
	# valve B kicks back twice and the partner at the valves turns it back.
	await face_point(p, b.poi["pump_handle"], 1.5, yard_side)
	await wait(3.5)
	sta.co_op = 1
	t = 0.0
	var pops0 := sta.pops
	var slipped_t := -1.0
	var fill_at_slip := 0.0
	var held_while_slipped := true
	while t < 90.0 and not sta.solved:
		var want := sta.pressure < 0.74
		key(KEY_E, want)
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if sta.valve_b == "overflow":
			if slipped_t < 0.0:
				slipped_t = t
				fill_at_slip = sta.fill["coolant"]
			elif t - slipped_t > 1.5:
				held_while_slipped = held_while_slipped and sta.fill["coolant"] == fill_at_slip
				sta._turn("b", p2())     # the partner turns it back
				slipped_t = -1.0
	key(KEY_E, false)
	sta.co_op = -1
	log_line("blue tank filled in %.0f s of careful pumping (%d extra pops, valve B slipped %d times)" % [t, sta.pops - pops0, sta.slips])
	check(sta.solved, "careful pumping fills the blue tank")
	check(sta.slips == CoolingStation.SLIP_AT.size(), "with two players, valve B kicks back twice while the tank fills")
	check(held_while_slipped, "while B is kicked back the blue tank stops filling")
	await wait(0.5)
	await shot("ww_solved")

	# the jug: carry it to the van and pour
	var jug := boot.world.get_node_or_null("CoolantJug") as CoolantJug
	check(jug != null, "the tap gives a coolant jug")
	if jug == null:
		return
	await face_point(p, jug.global_position + Vector3.UP * 0.2, 1.5, yard_side)
	await wait(0.3)
	log_line("at the jug: '%s' (jug at %.2f m above ground)" % [p.prompt_text, jug.global_position.y - Landscape.ground(jug.global_position.x, jug.global_position.z)])
	await tap(KEY_E)
	await physics_frames(10)
	check(p.held == jug, "the jug can be carried")
	var grille := c.global_transform * (Vector3(0, 1.45, -3.9) + Vector3(0, Camper.BODY_Y, 0))
	var van_before := c.global_position
	await face_point(p, grille, 1.8, -c.global_transform.basis.z)
	log_line("  van moved %.2f m while the player walked up" % van_before.distance_to(c.global_position))
	check(van_before.distance_to(c.global_position) < 0.1, "an empty van stays put (handbrake on)")
	await wait(0.3)
	log_line("at the grille holding the jug: '%s'" % p.prompt_text)
	await shot("ww_grille")
	key(KEY_E, true)
	for _k in 5:
		await wait(0.5)
		log_line("  pouring: added %.2f L, jug %.2f L, leak %s, using %s, held %s, prompt '%s'" % [c.coolant_added, jug.litres, c.coolant_leak, p._using, p.held, p.prompt_text])
	key(KEY_E, false)
	await wait(0.6)
	check(not c.coolant_leak and st.flags.has("leak_fixed"), "pouring the coolant fixes the leak")
	log_line("objective after the fix: '%s'" % st.objective_text())
	check(st.current()["id"] == "to_bridge", "then: carry on to the bridge")
	await tap(KEY_G)   # toss the jug aside (E here would just pour again)

	# fragments: the station's, then the shed roof by stacking crates
	var f0 := st.fragments
	var frag := boot.world.get_node_or_null("Fragment_water_works") as Node3D
	if frag:
		await face_point(p, frag.global_position + Vector3.UP * 0.15, 1.4, yard_side)
		await wait(0.3)
		log_line("at the station fragment: '%s'" % p.prompt_text)
		await tap(KEY_E)
		await wait(0.3)
	check(st.fragments == f0 + 1, "the station's Memory Fragment can be picked up")
	# stack two crates against the shed (as players would carry them over)
	var roof: Vector3 = b.poi["shed_roof"]
	var out := fac.global_transform.basis * Vector3(0, 0, -1)     # the shed's yard-side face
	var base := roof + out * 1.6
	base.y = Landscape.ground(base.x, base.z)
	# stand well clear before the crates are put down
	await place_player(p, roof + out * 6.0 + Vector3.UP * 0.3, 0.0)
	var cr0: Crate = boot.world.get_node("Crate0")
	var cr1: Crate = boot.world.get_node("Crate1")
	cr0.global_transform = Transform3D(fac.global_transform.basis, base + Vector3.UP * 0.02)
	cr1.global_transform = Transform3D(fac.global_transform.basis, base + Vector3.UP * 0.48)
	cr0.linear_velocity = Vector3.ZERO
	cr1.linear_velocity = Vector3.ZERO
	# a third crate on the ground in front makes the first step of a staircase
	var cr2: Crate = boot.world.get_node("Crate2")
	cr2.global_transform = Transform3D(fac.global_transform.basis, base + out * 0.66 + Vector3.UP * 0.02)
	cr2.linear_velocity = Vector3.ZERO
	await wait(1.0)
	log_line("crate stack settled: bottom %.2f m, top %.2f m above ground" % [cr0.global_position.y - base.y, cr1.global_position.y - base.y])
	# from the ground it is visible but out of reach
	var sfr := boot.world.get_node_or_null("Fragment_shed") as Node3D
	if sfr:
		await face_point(p, sfr.global_position + Vector3.UP * 0.15, 2.0, out)
		await wait(0.3)
		log_line("roof fragment from the ground: '%s'" % p.prompt_text)
		check(p.prompt_text.contains("out of reach"), "the roof fragment cannot be plucked from the ground")
	# climb: from the ground, step up the stack toward the roof
	var stand := base + out * 2.4
	stand.y = Landscape.ground(stand.x, stand.z) + 0.1
	await place_player(p, stand, atan2(out.x, out.z))
	var top_y := -9.0
	key(KEY_W, true)

	for k in 12:
		await tap(KEY_SPACE, 0.12)
		await wait(0.35)
		top_y = maxf(top_y, p.global_position.y - base.y)
		if p.global_position.y - base.y > 1.2:
			key(KEY_W, false)
			break
		log_line("  hop %d: feet %.2f, dist to base %.2f, crates d/y: %.2f/%.2f %.2f/%.2f %.2f/%.2f" % [k, p.global_position.y - base.y, Vector2(p.global_position.x - base.x, p.global_position.z - base.z).length(), Vector2(cr0.global_position.x - base.x, cr0.global_position.z - base.z).length(), cr0.global_position.y - base.y, Vector2(cr1.global_position.x - base.x, cr1.global_position.z - base.z).length(), cr1.global_position.y - base.y, Vector2(cr2.global_position.x - base.x, cr2.global_position.z - base.z).length(), cr2.global_position.y - base.y])
	await shot("ww_climb")
	key(KEY_W, false)
	await wait(0.4)
	log_line("climb: highest feet %.2f m; on the roof: %s" % [top_y, p.global_position.y - base.y > 1.2])
	check(p.global_position.y - base.y > 1.2, "a crate staircase (one, then two stacked) gets you onto the shed roof")
	var sf := boot.world.get_node_or_null("Fragment_shed") as Node3D
	if sf:
		# look at it from where we are (up on the stack or roof)
		var eye := p.global_position + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16)
		var dd := sf.global_position + Vector3.UP * 0.15 - eye
		p.yaw = atan2(-dd.x, -dd.z)
		p.pitch = atan2(dd.y, Vector2(dd.x, dd.z).length())
		await wait(0.3)
		log_line("at the roof fragment: '%s'" % p.prompt_text)
		await tap(KEY_E)
		await wait(0.3)
	check(boot.world.get_node_or_null("Fragment_shed") == null, "the shed roof fragment can be collected")
	await shot("ww_roof")

	# the clues
	var camp: Node3D = fac.get_node("Campsite")
	await face_point(p, camp.global_position + Vector3(0.8, 0.6, 0.3), 2.2, yard_side)
	await wait(0.3)
	log_line("at the campsite: '%s'" % p.prompt_text)
	await tap(KEY_E)
	await wait(0.4)
	check(boot.huds[0]._note_text.text.contains("One sleeping bag"), "the campsite shows one sleeping bag and two mugs")
	await shot("ww_camp")


## Journal save, then a real load (scene reload) that must restore it all.
## Runs last: the reload replaces this test node, so the check continues in
## t_save_verify via the static `resume`.
func t_save() -> void:
	var b: LevelBuilder = boot.builder
	var st: Story = boot.story
	var c := camper()
	var ms: MapState = boot.map_state
	for i in SaveGame.SLOTS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path(i)))
	# a known state worth saving
	await van_to(b.poi["j2"])
	c.fuel = 33.3
	c.temp = 91.0
	c.coolant_leak = false
	var can := await reset_can("station_can_b", 12.0)
	can.stow(c.storage_slots[1])
	ms.add_stamp("puzzle", Vector2(100, -50))
	st.index = 6
	st.fragments = 3
	st.roses_spent = 0
	st.collected = ["dock", "lookout", "shed"]
	station().valve_a = "b"
	station().valve_b = "coolant"
	station()._update_pointers()
	await place_player(p2(), b.poi["j2"] + Vector3(6, 1, 6), 1.0)
	await seat_p1_driver()
	await wait(1.5)
	check(st.roses() == 1, "three fragments make one Memory Rose")
	var p := p1()
	await tap(KEY_J)
	await physics_frames(3)
	check(p.journal_open, "J opens the travel journal in the parked van")
	await wait(0.3)
	await shot("journal_open")
	await tap(KEY_ENTER)
	await physics_frames(3)
	check(p.journal_confirm and boot.huds[0].get_children().filter(func(n): return n is JournalPanel)[0]._text.text.contains("uses 1 of your 1"), "the journal asks before spending the rose, and says the cost")
	await tap(KEY_ENTER)
	await physics_frames(5)
	check(SaveGame.exists(0) and st.roses() == 0 and not p.journal_open, "confirming writes slot 1 and spends the rose")
	await tap(KEY_J)
	await physics_frames(3)
	await tap(KEY_ENTER)
	await physics_frames(3)
	check(not p.journal_confirm and boot.huds[0].get_children().filter(func(n): return n is JournalPanel)[0]._text.text.contains("no Memory Rose"), "with no rose left the journal refuses")
	await tap(KEY_J)
	var expect := {
		"van": c.global_position, "fuel": c.fuel, "stowed": String(can.name), "stamps": ms.stamps.size(),
		"index": st.index, "fragments": st.fragments, "spent": st.roses_spent, "p2": p2().global_position,
		"valve_a": station().valve_a,
	}
	# now wreck the state, then load
	p.force_exit = true
	await physics_frames(3)
	await van_to(b.poi["facility"])
	c.fuel = 2.0
	ms.stamps.clear()
	st.index = 1
	await place_player(p2(), b.poi["homestead"] + Vector3(0, 2, 12), 0.0)
	PlayTest.expect = expect
	PlayTest.carried_failures = _failures.duplicate()
	PlayTest.resume = "save_verify"
	boot.load_slot(0)


static var resume := ""
static var carried_failures: Array[String] = []
static var expect := {}


func t_save_verify() -> void:
	await wait(1.5)
	var c := camper()
	var st: Story = boot.story
	var e := PlayTest.expect
	log_line("after load: van %.2f m from saved spot, fuel %.1f, story step %d, fragments %d (spent %d), stamps %d" % [
		c.global_position.distance_to(e["van"]), c.fuel, st.index, st.fragments, st.roses_spent, boot.map_state.stamps.size()])
	check(c.global_position.distance_to(e["van"]) < 0.5, "loading puts the van back where it was")
	check(absf(c.fuel - float(e["fuel"])) < 0.2, "loading restores the fuel")
	var slot_item: Carryable = c.stowed_item(c.storage_slots[1])
	check(slot_item != null and String(slot_item.name) == e["stowed"] and absf(slot_item.litres - 12.0) < 0.1, "loading restores the can on the rack, with its fuel")
	check(boot.map_state.stamps.size() == e["stamps"], "loading restores the map stamps")
	check(st.index == e["index"] and st.fragments == e["fragments"] and st.roses_spent == e["spent"], "loading restores story, fragments and spent roses")
	check(p1().seat_role == "driver", "the driver is back in the driver's seat")
	check(p2().global_position.distance_to(e["p2"]) < 0.8, "the other player is back where they stood")
	check(station().valve_a == e["valve_a"], "loading restores the water works valves")
	for id in ["dock", "lookout", "shed"]:
		check(boot.world.find_child("Fragment_" + id, true, false) == null, "collected fragment '%s' stays collected" % id)
	await shot("after_load")


## Every sound family resolves to real samples, and the world actually makes
## noise: footsteps while walking, the wind bed, the steam hiss.
func t_audio() -> void:
	var missing := []
	for k in Sfx.FAMILIES.keys():
		if Sfx.streams(k).is_empty():
			missing.append(k)
	log_line("sound families: %d, missing: %s" % [Sfx.FAMILIES.size(), missing])
	check(missing.is_empty(), "every sound effect name has CC0 samples behind it")
	var p := p1()
	if p.seat != null:
		p.force_exit = true
		await physics_frames(3)
	# walk the way the spawn faces: open ground up the lane
	var sp: Transform3D = boot.builder.player_spawns[0]
	await place_player(p, sp.origin, sp.basis.get_euler().y)
	var before: int = boot.world.find_children("*", "AudioStreamPlayer3D", true, false).size()
	var heard := 0
	key(KEY_W, true)
	# up to 4 s: the first seconds after loading can crawl while shaders compile
	for _i in 80:
		await wait(0.05)
		heard = maxi(heard, boot.world.find_children("*", "AudioStreamPlayer3D", true, false).size() - before)
		if heard > 0:
			break
	key(KEY_W, false)
	log_line("one-shot sounds playing while walking: up to %d (moved %.1f m, on floor %s, at %s)" % [heard, p.global_position.distance_to(sp.origin), str(p.is_on_floor()), p.global_position])
	check(heard > 0, "walking makes footstep sounds")
	var wind: NoiseLoop = boot.world.get_node("Wind")
	check(wind != null and wind._gain > 0.5, "the wind bed is playing")
	var amb: Ambience = boot.world.get_node("Ambience")
	check(amb != null and amb._bed.playing and amb._birds.playing and amb._bed.stream != null and amb._birds.stream != null, "the forest bed and birdsong are playing")
	var dock: Vector3 = boot.builder.poi["dock"]
	await place_player(p, Vector3(dock.x, Landscape.ground(dock.x, dock.z) + 0.3, dock.z), 0.0)
	await wait(1.0)
	var lapping := 0
	for w in amb._water:
		if w._gain > 0.3:
			lapping += 1
	log_line("water emitters: %d, audible at the dock: %d" % [amb._water.size(), lapping])
	check(lapping > 0, "water can be heard at the lake")
	await place_player(p, boot.builder.player_spawns[0].origin, 0.0)


## Fixes from the user's play-through notes (FUTURE.md items 10, 11, 14, 15, 16, 25).
func t_feedback() -> void:
	var b: LevelBuilder = boot.builder
	var c := camper()
	var p := p1()
	# 14: engine off, W held on the steepest slope: the van must not roll
	var r: Route = b.route
	var steep := 0
	var best := 0.0
	for i in r.point_count():
		if absf(r.forward(i).y) > best:
			best = absf(r.forward(i).y)
			steep = i
	await reset_camper(steep)
	await seat_p1_driver()
	if c.engine_on:
		c.toggle_engine()
	await wait(1.0)
	var p0 := c.global_position
	key(KEY_W, true)
	await wait(3.0)
	key(KEY_W, false)
	log_line("engine off, W held 3 s on a %.0f%% slope: moved %.2f m" % [best * 100.0, p0.distance_to(c.global_position)])
	check(p0.distance_to(c.global_position) < 0.1, "with the engine off the van stays put (no rolling back)")
	# 11: idling costs fuel and heat
	c.toggle_engine()
	c.temp = Camper.TEMP_NORMAL
	var f0 := c.fuel
	await wait(10.0)
	log_line("idling 10 s: %.2f L used, temp %.0f -> %.0f C" % [f0 - c.fuel, Camper.TEMP_NORMAL, c.temp])
	check(f0 - c.fuel > 0.12 and c.temp > Camper.TEMP_NORMAL + 4.0, "idling burns fuel and runs hotter than driving")
	# 16: the split hose drains a coolant gauge
	c.coolant = 1.0
	c.spring_leak()
	await wait(5.0)
	log_line("coolant after 5 s with a split hose: %.0f%%" % (c.coolant * 100.0))
	check(c.coolant < 0.9 and boot.huds[0]._bars.has("COOL"), "a coolant gauge drains through the split hose")
	c.coolant_leak = false
	c.coolant = 1.0
	c.temp = Camper.TEMP_NORMAL
	c.toggle_engine()
	# 10: the nav points at your stamp, never at Bessi
	boot.map_state.stamps.clear()
	await wait(0.4)
	var nav: Label3D = c._needles["nav_label"]
	log_line("nav with no stamps: '%s'" % nav.text.replace("\n", " / "))
	check(not nav.text.contains("BESSI") and nav.text.contains("stamp"), "without stamps the nav gives nothing away")
	boot.map_state.add_stamp("fuel", Vector2(b.poi["gas_station"].x, b.poi["gas_station"].z))
	await wait(0.4)
	log_line("nav with a fuel stamp: '%s'" % nav.text.replace("\n", " / "))
	check(nav.text.begins_with("FUEL"), "the nav points at the latest map stamp")
	# 10: map zoom
	p.force_exit = true
	await physics_frames(3)
	await tap(KEY_M)
	await tap(KEY_EQUAL)
	await tap(KEY_EQUAL)
	log_line("map zoom after two presses: %.2fx" % p.paper_map.zoom)
	check(p.paper_map.zoom > 2.0, "+ zooms the paper map in")
	await shot("map_zoomed")
	await tap(KEY_MINUS)
	await tap(KEY_M)
	# 15: pouring tips the can spout-down at the filler
	var can := await reset_can("station_can_a", FuelCan.CAPACITY)
	can.global_position = c.global_transform * Vector3(-2.4, 0.2, 1.0)
	can.reset_physics_interpolation()
	await physics_frames(20)
	await face_point(p, can.global_position + Vector3.UP * 0.25, 1.8, -c.global_transform.basis.x)
	await tap(KEY_E)
	await physics_frames(10)
	var inlet := c.global_transform * (Vector3(-1.2, 1.40, 1.9) + Vector3(0, Camper.BODY_Y, 0))
	await face_point(p, inlet, 1.9, -c.global_transform.basis.x)
	key(KEY_E, true)
	await wait(1.2)
	var tilt := rad_to_deg(acos(clampf(can.global_transform.basis.y.y, -1, 1)))
	var near_filler := can.global_position.distance_to(inlet)
	await shot("pouring")
	key(KEY_E, false)
	log_line("while pouring: can tipped %.0f deg, %.2f m from the filler" % [tilt, near_filler])
	check(tilt > 60.0 and near_filler < 0.9, "pouring tips the can over the filler")
	await tap(KEY_G)   # toss it: E at the filler would just pour again
	# 25: no mountain intrudes on the map, and the world has an edge
	var worst := 1e9
	for m in boot.world.get_node("Backdrop").get_children():
		var mi := m as MeshInstance3D
		var rad := (mi.get_aabb().size.x * mi.scale.x) * 0.5
		worst = minf(worst, Vector2(mi.position.x, mi.position.z).length() - rad)
	log_line("closest backdrop mountain edge: %.0f m from the centre (map corner %.0f m)" % [worst, Landscape.EXTENT * 0.5 * sqrt(2.0)])
	check(worst > Landscape.EXTENT * 0.5, "no backdrop mountain reaches into the playable map")
	var edge_x := Landscape.EXTENT * 0.5 - 30.0
	var at := Vector3(edge_x, 0, 0)
	at.y = Landscape.ground(at.x, at.z) + 0.3
	await place_player(p, at, -PI * 0.5)   # facing +X, off the edge
	key(KEY_W, true)
	key(KEY_SHIFT, true)
	await wait(6.0)
	key(KEY_W, false)
	key(KEY_SHIFT, false)
	log_line("walked at the world edge: stopped at x %.0f (edge %.0f)" % [p.global_position.x, Landscape.EXTENT * 0.5])
	check(p.global_position.x < Landscape.EXTENT * 0.5 - 4.0, "the world edge stops you walking off the map")


## The small fixes from the user's second list (2026-09-24): ESC, wheels at
## rest, the handbrake, brakes, pour sounds, seated avatars, van hits a player,
## the engine's gears.
func t_fixes() -> void:
	var c := camper()
	var p := p1()
	var b: LevelBuilder = boot.builder
	# --- ESC puts things away before it pauses
	await place_player(p, b.player_spawns[0].origin, 0.0)
	await tap(KEY_M)
	await physics_frames(3)
	await tap(KEY_ESCAPE)
	await physics_frames(3)
	check(not p.map_open and not boot.paused, "ESC closes the paper map without pausing")
	p.say("A test note.", 30.0)
	await physics_frames(3)
	await tap(KEY_ESCAPE)
	await physics_frames(3)
	check(not boot.huds[0]._note.visible and not boot.paused, "ESC dismisses a note without pausing")
	await tap(KEY_ESCAPE)
	await physics_frames(3)
	check(boot.paused, "ESC with nothing open pauses")
	await tap(KEY_ESCAPE)
	await physics_frames(3)
	check(not boot.paused, "ESC again resumes")

	# --- the handbrake, on the steepest part of the route
	var r: Route = b.route
	var steep := 0
	var best := 0.0
	for i in r.point_count():
		if absf(r.forward(i).y) > best:
			best = absf(r.forward(i).y)
			steep = i
	c.parking_brake = true
	await reset_camper(steep)
	await seat_p1_driver()
	if c.engine_on:
		c.toggle_engine()
	await wait(1.5)
	var p0 := c.global_position
	var spin0 := c._wheel_spin
	await wait(2.0)
	log_line("handbrake on, %.0f%% slope, 2 s: moved %.2f m, wheels turned %.3f rad" % [best * 100.0, p0.distance_to(c.global_position), absf(c._wheel_spin - spin0)])
	check(p0.distance_to(c.global_position) < 0.05, "with the handbrake on the van holds on the steepest slope")
	check(absf(c._wheel_spin - spin0) < 0.001, "the wheels do not turn while the van stands still")
	await wait(0.3)
	log_line("seated prompt: '%s'" % p.prompt_text.replace("\n", " / "))
	check(p.prompt_text.contains("Release handbrake"), "the seated prompt offers the handbrake")
	await tap(KEY_SPACE)
	await physics_frames(3)
	check(not c.parking_brake, "Space lets the handbrake off")
	await wait(3.0)
	var rolled := p0.distance_to(c.global_position)
	log_line("handbrake off, engine off, 3 s: rolled %.1f m" % rolled)
	check(rolled > 1.0, "with the handbrake off the van rolls down the slope")
	key(KEY_S, true)
	await wait(2.0)
	log_line("engine off, rolling back, S held 2 s: %.1f km/h" % kmh())
	check(kmh() < 1.0, "with the engine off, S brakes a van rolling backwards")
	key(KEY_S, false)
	await wait(1.0)
	await tap(KEY_SPACE)
	await wait(3.0)
	log_line("handbrake pulled while rolling: %.1f km/h after 3 s" % kmh())
	check(c.parking_brake and kmh() < 1.0, "pulling the handbrake stops a rolling van")
	c.toggle_engine()
	key(KEY_W, true)
	await wait(1.0)
	key(KEY_W, false)
	log_line("engine on, W with the handbrake on: brake %s, %.1f km/h" % ["on" if c.parking_brake else "off", kmh()])
	check(not c.parking_brake and kmh() > 2.0, "pulling away with the engine running lets the handbrake off")

	# --- brakes and the engine's gears, on the flat start of the route
	await reset_camper(6)
	var ad := AutoDriver.new(self, r, c)
	var pitches: Array[float] = []
	for _i in 60 * 25:
		await get_tree().physics_frame
		ad.step(999.0)
		pitches.append(c._audio._engine.pitch_scale)
		if kmh() >= 60.0:
			break
	ad.release()
	var drops := 0
	var peak := pitches[0]
	for pv in pitches:
		if pv < peak - 0.12:
			drops += 1          # revs fell well below the last peak: a shift
			peak = pv
		peak = maxf(peak, pv)
	log_line("engine pitch %.2f at the start, %.2f at %.0f km/h, %d gear-change drops" % [pitches[0], c._audio._engine.pitch_scale, kmh(), drops])
	check(c._audio._engine.playing and drops >= 2, "the engine climbs through gears (revs drop at each shift)")
	var v0 := kmh()
	var bp := c.global_position
	key(KEY_S, true)
	var frames := 0
	while kmh() > 1.0 and frames < 60 * 10:
		await get_tree().physics_frame
		ad.steer_only()
		frames += 1
	key(KEY_S, false)
	ad.release()
	var dist := bp.distance_to(c.global_position)
	log_line("brake from %.0f km/h: %.1f m in %.1f s" % [v0, dist, frames / 60.0])
	check(dist < 30.0, "S brakes hard: ~60 km/h to a stop within 30 m")
	await tap(KEY_SPACE)       # handbrake on: this stretch slopes, and it would roll
	await wait(1.0)
	var spin1 := c._wheel_spin
	await wait(1.5)
	check(absf(c._wheel_spin - spin1) < 0.001, "the wheels stop turning once the van has stopped")

	# --- the seated partner fits the cab
	if c.engine_on:
		c.toggle_engine()
	var p2r := p2()
	p2r.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await physics_frames(3)
	p2r._seat_yaw = 1.15
	p2r.pitch = -0.05
	await wait(0.5)
	var head := p._mesh_root.get_node("Head") as Node3D
	var roof := (c.global_transform * Vector3(0, Camper.BODY_Y + 2.56, 0)).y
	var head_top := head.global_position.y + 0.2
	log_line("seated driver's head top %.2f m, roof inside %.2f m" % [head_top, roof])
	check(head_top < roof - 0.05, "a seated player's body fits under the cab roof")
	await tap(KEY_TAB)          # show P2's view: the driver seen from the passenger seat
	await wait(0.3)
	await shot("seated_partner")
	await tap(KEY_TAB)
	p2r.exit_vehicle()

	# --- pouring: no sound from an empty can, a glug from a full one
	p.force_exit = true
	await physics_frames(3)
	for litres in [0.0, FuelCan.CAPACITY]:
		c.fuel = 20.0
		var can := await reset_can("station_can_a", litres)
		can.global_position = c.global_transform * Vector3(-2.4, 0.2, 1.0)
		can.reset_physics_interpolation()
		await physics_frames(20)
		await face_point(p, can.global_position + Vector3.UP * 0.25, 1.8, -c.global_transform.basis.x)
		await tap(KEY_E)
		await physics_frames(10)
		var inlet := c.global_transform * (Vector3(-1.2, 1.40, 1.9) + Vector3(0, Camper.BODY_Y, 0))
		await face_point(p, inlet, 1.9, -c.global_transform.basis.x)
		key(KEY_E, true)
		await wait(0.8)
		var glugging: bool = c._glug.playing
		key(KEY_E, false)
		await wait(0.4)
		log_line("pouring a can with %.0f L: glug %s, after letting go %s" % [litres, "playing" if glugging else "silent", "playing" if c._glug.playing else "silent"])
		if litres <= 0.0:
			check(not glugging, "an empty can makes no pouring sound")
		else:
			check(glugging and not c._glug.playing, "a full can glugs while pouring, and stops after")
		await tap(KEY_G)
		await wait(0.5)

	# --- the van knocks a player flying, and they get back up
	await reset_camper(6)
	c.parking_brake = false
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	var ahead := 6
	while ahead < r.point_count() - 1 and r.point(ahead).distance_to(r.point(6)) < 45.0:
		ahead += 1
	var victim := p2()
	var spot := r.point(ahead)
	spot.y = Landscape.ground(spot.x, spot.z) + 0.1
	await place_player(victim, spot, 0.0)
	var ad2 := AutoDriver.new(self, r, c)
	var hit_kmh := 0.0
	var flew := 0.0
	var shot_taken := false
	for _i in 60 * 12:
		await get_tree().physics_frame
		ad2.step(35.0)
		if victim.knocked_t > 0.0 and hit_kmh == 0.0:
			hit_kmh = kmh()
		if hit_kmh > 0.0:
			flew = maxf(flew, spot.distance_to(victim.global_position))
			if flew > 3.0 and not shot_taken:
				shot_taken = true
				await tap(KEY_TAB, 0.02)   # watch the tumble through the victim's eyes
				await wait(0.25)
				await shot("knocked")
				await tap(KEY_TAB, 0.02)
		if hit_kmh > 0.0 and victim.knocked_t <= 0.0:
			break
	ad2.release()
	key(KEY_S, true)
	var after_hit := kmh()
	log_line("van hit the player at %.0f km/h: thrown %.1f m, van still at %.0f km/h, back up: %s" % [hit_kmh, flew, after_hit, str(victim.knocked_t <= 0.0)])
	check(hit_kmh > 15.0 and flew > 4.0, "the van knocks a player flying")
	check(victim.knocked_t <= 0.0, "the knocked player gets back up")
	await wait(2.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)
	await wait(1.5)
	check(victim.eye_height > 1.3, "back on their feet, eyes at standing height")


## The developer menu in the game world: F1, teleport by name, close.
func t_dev() -> void:
	var dm: DevMenu = boot.dev_menu
	await tap(KEY_F1)
	await physics_frames(2)
	check(dm.open, "F1 opens the developer menu")
	await shot("dev_menu")
	dm._sel = 0
	dm._place = dm.places().find("dock")
	await tap(KEY_ENTER)
	await physics_frames(5)
	var dock: Vector3 = boot.builder.poi["dock"]
	var d := Vector2(p1().global_position.x - dock.x, p1().global_position.z - dock.z).length()
	log_line("teleported to the dock: %.1f m away" % d)
	check(d < 6.0, "the menu teleports both players to a named place")
	# save slots are labelled by the nearest place, the new map's included
	var here := SaveGame.nearest_place(boot, p1().global_position)
	var p2h := SaveGame.nearest_place(boot, boot.builder.poi["p2_home"])
	var nowhere := SaveGame.nearest_place(boot, Vector3(-1900, 0, -1900))
	log_line("save labels: dock '%s', P2's home '%s', far corner '%s'" % [here, p2h, nowhere])
	check(here == "Mirror Lake" and p2h == "P2's house" and nowhere == "on the road", "save slots name the place you saved at")
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await physics_frames(10)
	var vd := camper().global_position.distance_to(p1().global_position)
	log_line("van brought: %.1f m from P1" % vd)
	check(vd < 12.0 and camper().parking_brake, "the menu brings the van, handbrake on")
	await tap(KEY_F1)
	await physics_frames(2)
	check(not dm.open, "F1 closes it again")
	await place_player(p1(), boot.builder.player_spawns[0].origin, 0.0)


## The base gym: flat measured ground, test slopes, props, the dev menu.
func t_gym() -> void:
	var b: GymBuilder = boot.builder as GymBuilder
	check(b != null and boot.gym == "base", "the base gym loads instead of the world")
	if b == null:
		return
	var flat := absf(Landscape.ground(0, 0)) + absf(Landscape.ground(-80, -80)) + absf(Landscape.ground(60, 40))
	log_line("ground at three grid points: %.2f m total off level" % flat)
	check(flat < 0.2, "the gym floor is level")
	for s in GymBuilder.SLOPES:
		var x := float(s[0])
		var g := (Landscape.ground(x, 10.0) - Landscape.ground(x, 20.0)) / 10.0
		log_line("slope sign %d%%: measured %.1f%%" % [int(float(s[1]) * 100.0), g * 100.0])
		check(absf(g - float(s[1])) < 0.015, "the %d%% test slope really is %d%%" % [int(float(s[1]) * 100.0), int(float(s[1]) * 100.0)])
	check(boot.world.get_node_or_null("Grid") != null, "the measuring grid is there")
	check(find_can("gym_can_full") != null and boot.world.get_node_or_null("CoolantJug") != null, "cans and the coolant jug are there")
	await wait(0.5)
	await shot("gym_base")
	# the van on the 20% slope: held by the handbrake, rolls without it
	var c := camper()
	var top: Vector3 = b.poi["slope_20"]
	boot.dev_menu.van_to(top, 0.0)
	await wait(2.5)            # let it land and settle on its springs
	var p0 := c.global_position
	await wait(2.0)
	log_line("20%% slope, handbrake on: moved %.2f m" % p0.distance_to(c.global_position))
	check(p0.distance_to(c.global_position) < 0.05, "the handbrake holds the van on the 20% gym slope")
	c.set_parking_brake(false)
	await wait(2.5)
	log_line("20%% slope, handbrake off: rolled %.1f m" % p0.distance_to(c.global_position))
	check(p0.distance_to(c.global_position) > 2.0, "and it rolls when the handbrake is off")
	c.set_parking_brake(true)
	# a lap of the test loop by keyboard
	await reset_camper(0)
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	var ad := AutoDriver.new(self, b.route, c)
	for _i in 60 * 20:
		await get_tree().physics_frame
		ad.step(50.0)
	ad.release()
	log_line("gym loop, 20 s at up to 50 km/h: %d samples along, off-road max %.1f m" % [ad.progress, ad.max_off])
	check(ad.progress > 10 and ad.max_off < 6.0, "the van drives the gym's test loop")
	key(KEY_S, true)
	await wait(3.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)


## Puncture on the measuring straight, then the real E/hold-E wheel sequence.
func t_tyre() -> void:
	var c := camper()
	check(boot.gym == "tyre" and boot.world.get_node_or_null("TyreNails") != null,
		"the tyre gym has a fixed, visible nail trap")
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	c.set_parking_brake(false)
	c.freeze = false
	key(KEY_W, true)
	var elapsed := 0.0
	while elapsed < 20.0 and not c.tyre_flat:
		await get_tree().physics_frame
		elapsed += 1.0 / 60.0
		key(KEY_W, true)  # reassert after a window focus event clears Input's held keys
	key(KEY_W, false)
	log_line("tyre approach: %.1f s, van %s, speed %.0f km/h" % [elapsed, c.global_position, kmh()])
	check(c.tyre_flat, "crossing the nails punctures the front-left tyre")
	if not c.tyre_flat:
		return
	check(c._wheels[0].wheel_friction_slip < 2.0 and c._wheels[0].wheel_radius < Camper.WHEEL_RADIUS,
		"the flat has less grip and a visibly smaller radius")
	key(KEY_S, true)
	await wait(4.0)
	key(KEY_S, false)
	if not c.parking_brake:
		await tap(KEY_SPACE)
	await wait(1.0)
	check(c.parking_brake and kmh() < 3.0, "the van is parked on its handbrake before the repair")
	p1().force_exit = true
	await physics_frames(3)
	var rear := c.global_transform * Vector3(0, 2.05 + Camper.BODY_Y, 3.25)
	await face_point(p1(), rear, 2.0, c.global_transform.basis.z)
	check(p1().prompt_text.contains("spare"), "the rear mount offers the spare wheel")
	await tap(KEY_E)
	check(c.tyre_stage == 1 and p1().held is SpareWheel, "E takes a physical spare off the rear mount")
	if not p1().held is SpareWheel:
		return
	var wheel := p1().held as SpareWheel
	var front := c.global_transform * Vector3(-1.55, 0.48 + Camper.BODY_Y, -Camper.WHEELBASE)
	await face_point(p1(), front, 2.0, -c.global_transform.basis.x)
	await tap(KEY_E)  # put the spare on the ground while working the jack
	check(p1().held == null, "the spare can be put down beside the flat")
	wheel.global_position = c.global_transform * Vector3(-3.3, 0.7, -Camper.WHEELBASE - 1.0)
	wheel.linear_velocity = Vector3.ZERO
	wheel.reset_physics_interpolation()
	await face_point(p1(), front, 1.8, -c.global_transform.basis.x)
	check(p1().prompt_text.contains("jack"), "the sill offers a jack point")
	await tap(KEY_E)
	check(c.tyre_stage == 2, "E sets the jack")
	await hold_physics(KEY_E, 7.0)
	check(c.tyre_stage == 3, "holding E loosens the nuts")
	await wait(0.2)  # one released physics tick before the next press
	await tap(KEY_E)
	check(c.tyre_stage == 4 and not c._wheel_meshes[0].visible, "the flat wheel comes off")
	await face_point(p1(), wheel.global_position, 1.5)
	await tap(KEY_E)
	check(p1().held == wheel, "the player picks the spare back up")
	await face_point(p1(), front, 1.8, -c.global_transform.basis.x)
	check(p1().prompt_text.contains("fit the spare"), "the spare fits onto the exposed hub")
	await hold_physics(KEY_E, 7.0)
	check(c.tyre_stage == 5 and p1().held == null, "holding E fits the spare")
	await wait(0.2)
	await tap(KEY_E)
	check(not c.tyre_flat and not c.spare_available and c.tyre_stage == 0,
		"lowering the jack restores grip and consumes the spare")
	await shot("tyre_repaired")
	boot.dev_menu.van_to(boot.builder.poi["slope_20"], 0.0)
	await wait(2.5)
	var slope_start := c.global_position
	await wait(2.0)
	check(c.parking_brake and c.global_position.distance_to(slope_start) < 0.05,
		"the repaired van holds on the 20% slope with the handbrake set")
	c.set_parking_brake(false)
	await wait(2.5)
	check(c.global_position.distance_to(slope_start) > 2.0,
		"and rolls on the 20% slope when the handbrake is released")


## Teleport check of the fixed world puncture. The opening story arms it later;
## all the existing long-route checks keep their original route conditions.
func t_roadworks() -> void:
	var lane: Route = boot.builder.network.road("home_lane")
	var trap: Area3D = boot.world.get_node_or_null("RoadworksNails/PunctureArea")
	check(trap != null and boot.builder.poi.has("roadworks_nails"),
		"the roadworks nails and warning sign are placed past Town Fuel")
	if trap == null:
		return
	var c := camper()
	var flags: Dictionary = boot.story.flags
	flags.erase("opening_puncture_armed")
	flags.erase("opening_puncture_done")
	var f: Vector3 = lane.forward(520)
	var basis := Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP)
	c.parking_brake = true
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(basis, lane.point(520) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await physics_frames(8)
	check(not c.tyre_flat, "unarmed roadworks leave an older route run alone")
	# what the driver sees coming up to the spill
	c.global_transform = Transform3D(basis, lane.point(505) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await seat_p1_driver()
	await wait(0.6)
	await shot("roadworks_approach")
	p1().force_exit = true
	await physics_frames(3)
	c.global_transform = Transform3D(basis, lane.point(510) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await physics_frames(8)
	flags["opening_puncture_armed"] = true
	c.global_transform = Transform3D(basis, lane.point(520) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await physics_frames(8)
	check(c.tyre_flat and flags.has("opening_puncture_done"),
		"an armed opening punctures the van once at the fixed nails")
	# during the opening the nails work without any arming (no refuel first)
	flags.erase("opening_puncture_armed")
	flags.erase("opening_puncture_done")
	c.tyre_flat = false
	c.refresh_tyre_visuals()
	boot.story.opening_mode = true
	c.global_transform = Transform3D(basis, lane.point(505) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await physics_frames(8)
	c.global_transform = Transform3D(basis, lane.point(520) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await physics_frames(8)
	boot.story.opening_mode = false
	check(c.tyre_flat, "during the opening the nails puncture the van even before the refuel")
	flags.erase("opening_puncture_armed")
	flags.erase("opening_puncture_done")
	c.tyre_flat = false
	c.tyre_stage = 0
	c.refresh_tyre_visuals()


func t_house() -> void:
	var house := boot.world.get_node_or_null("OpeningHouse") as HouseInterior
	check(house != null and boot.gym == "house", "the enterable P2 house loads in its own gym")
	if house == null:
		return
	var p := p1()
	p.flashlight_seconds = 0.0
	await tap(KEY_F)
	check(not p.flashlight.visible, "the empty torch will not turn on")
	var drawer_pos := house.to_global(Vector3(-3.0, 0.85, -1.92))
	await face_point(p, drawer_pos, 1.5, Vector3(0, 0, 1))
	check(p.prompt_text.contains("drawer"), "the kitchen drawer can be searched")
	await tap(KEY_E)
	check(house.drawer_open and house.battery_pack != null, "opening the drawer reveals a physical battery pack")
	if house.battery_pack == null:
		return
	await face_point(p, house.battery_pack.global_position + Vector3.UP * 0.2, 1.3, Vector3(0, 0, 1))
	await tap(KEY_E)
	check(p.held is BatteryPack, "the batteries can be carried")
	await tap(KEY_F)
	check(p.held == null and p.flashlight.visible and p.flashlight_seconds > 590.0,
		"F fits the cells and lights the torch for ten minutes")
	var front := house.to_global(Vector3(0, 1.3, 4.48))
	await face_point(p, front, 1.5, Vector3(0, 0, 1))
	await tap(KEY_E)
	check(house.front_open, "E opens the house's front door")
	var shed := house.to_global(Vector3(8.5, 1.3, 3.46))
	await face_point(p, shed, 1.5, Vector3(0, 0, 1))
	await tap(KEY_E)
	check(house.shed_open, "E opens the enclosed shed")
	check(house.coolant_jug != null and absf(house.coolant_jug.litres - CoolantJug.CAPACITY * 0.5) < 0.01,
		"a half-full coolant jug waits in the shed")
	var can := house.fuel_can
	check(can != null and can.litres <= 0.01, "the shed can starts empty")
	if can != null:
		await face_point(p, can.global_position + Vector3.UP * 0.2, 1.4, Vector3(0, 0, 1))
		await tap(KEY_E)
		check(p.held == can, "the empty can can be carried to the drum")
		if p.held == can:
			var initial_mass := can.mass
			var spout := house.drum.to_global(Vector3(0, 0.85, 0.75))
			await face_point(p, spout, 1.25, Vector3(0, 0, 1))
			check(p.prompt_text.contains("fill can"), "the drum offers a hold-to-fill action")
			key(KEY_E, true)
			await wait(4.3)
			key(KEY_E, false)
			check(can.litres > 19.0 and can.mass > initial_mass + 14.0,
				"holding E fills the can and increases its weight")
			p.drop_held()
	await shot("house_shed")
	# Walk up the real colliding steps from the downstairs kitchen.
	await place_player(p, house.to_global(Vector3(3.9, 0.2, 3.1)), 0.0)
	log_line("stairs start: %s floor=%s" % [p.global_position, p.is_on_floor()])
	key(KEY_W, true)
	for step in 240:
		await get_tree().physics_frame
		key(KEY_W, true)
		if step % 60 == 59:
			log_line("stairs %d: %s floor=%s" % [step + 1, p.global_position, p.is_on_floor()])
	key(KEY_W, false)
	log_line("stairs end: %s" % p.global_position)
	check(p.global_position.y > house.global_position.y + 2.7,
		"P2 can climb the stairwell to the upstairs window")
	await place_player(p, house.to_global(Vector3(-2.5, 3.35, 2.4)), PI)
	p.pitch = 0.0
	await physics_frames(3)
	var eye := p.global_position + Vector3.UP * 1.5
	var q := PhysicsRayQueryParameters3D.create(eye, eye + Vector3(0, 0, 10), 1)
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	check(hit.is_empty(), "the upstairs window has a clear view toward the lane")
	await shot("house_upstairs")


func t_house_world() -> void:
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	var pump := boot.world.get_node_or_null("TownFuel/WorkingPump") as FuelSource
	check(house != null and pump != null, "P2's enterable house and working Town Fuel pump are on the world map")
	if house == null or pump == null:
		return
	var lane: Route = boot.builder.network.road("home_lane")
	var near: Dictionary = lane.nearest(house.global_position.x, house.global_position.z)
	var approach := lane.point(int(near["index"]))
	log_line("P2 drive: road %s, house %s, run %.1f m, rise %.1f m" % [approach, house.global_position,
		Vector2(approach.x - house.global_position.x, approach.z - house.global_position.z).length(),
		house.global_position.y - approach.y])
	check(house.fuel_can != null and house.coolant_jug != null and house.drum != null,
		"P2's shed has its empty can, half-full coolant and fuel drum")
	var out := house.global_basis * Vector3(0, 0, 1)
	await place_player(p1(), house.to_global(Vector3(-2.5, 3.35, 2.4)), atan2(-out.x, -out.z))
	await physics_frames(3)
	var eye := p1().global_position + Vector3.UP * 1.5
	var rayq := PhysicsRayQueryParameters3D.create(eye, eye + house.basis * Vector3(0, 0, 15), 1)
	check(p1().get_world_3d().direct_space_state.intersect_ray(rayq).is_empty(),
		"P2 can look out from the upstairs room toward the road")
	await shot("p2_home_window")
	var can := find_can("station_can_empty")
	check(can != null, "an empty test can is available for Town Fuel")
	if can == null:
		return
	can.global_position = pump.to_global(Vector3(0, 0.25, 2.1))
	can.linear_velocity = Vector3.ZERO
	can.reset_physics_interpolation()
	await face_point(p1(), can.global_position + Vector3.UP * 0.2, 1.35, pump.global_basis.z)
	await tap(KEY_E)
	check(p1().held == can, "the can can be carried to the working pump")
	if p1().held == can:
		var spout := pump.to_global(Vector3(0, 0.85, 0.75))
		await face_point(p1(), spout, 1.3, pump.global_basis.z)
		check(p1().prompt_text.contains("fill can"), "Town Fuel offers hold-to-fill")
		key(KEY_E, true)
		await wait(4.3)
		key(KEY_E, false)
		check(can.litres > 19.0, "Town Fuel fills an empty can")
		p1().drop_held()
	reset_can("station_can_empty", 0.0)


func t_traffic() -> void:
	var car := boot.world.get_node_or_null("GymTrafficCar") as TrafficCar
	check(car != null and boot.gym == "traffic", "a town car loops on the traffic gym straight")
	if car == null:
		return
	var road: Route = boot.builder.network.road("gym_straight")
	var i := 145
	var f := road.forward(i)
	var left := -road.right(i)
	var c := camper()
	c.parking_brake = true
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP),
		road.point(i) + left * TrafficCar.LANE_OFFSET + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await wait(14.0)
	log_line("traffic blocked: index %.1f speed %.1f m/s, separation %.1f m" % [car.progress, car.speed, car.global_position.distance_to(c.global_position)])
	check(car.waiting and car.speed < 1.0 and car.global_position.distance_to(c.global_position) > 3.0,
		"the car keeps left and stops behind a parked van")
	var stopped := car.progress
	c.global_position = Vector3(0, 0.8, 30)
	c.reset_physics_interpolation()
	await wait(4.0)
	check(car.progress > stopped + 3.0 and car.speed > 5.0,
		"the car continues when the van clears the lane")
	await shot("traffic_gym")
	# someone on foot in the lane
	var j := int(car.progress) + 12
	var walker := road.point(j) - road.right(j) * TrafficCar.LANE_OFFSET
	await place_player(p1(), walker + Vector3.UP * 0.2, 0.0)
	await wait(4.0)
	check(car.waiting and car.speed < 1.0 and car.global_position.distance_to(p1().global_position) > 2.5,
		"the car stops for a person standing in its lane")
	await place_player(p1(), Vector3(0, 0.3, 30), 0.0)
	# the U-turn at the end of the patrol: no jumps, into the other lane
	var last_pos := car.global_position
	var max_step := 0.0
	var turned := false
	var t := 0.0
	while t < 40.0 and not (car.direction < 0 and car._turn < 0.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		max_step = maxf(max_step, car.global_position.distance_to(last_pos))
		last_pos = car.global_position
		turned = turned or car._turn >= 0.0
	await wait(1.0)
	var k := int(car.progress)
	var side := (car.global_position - road.point(k)).dot(road.right(k))
	log_line("traffic U-turn: %.1f s, largest step %.2f m, now %.1f m right of the centreline" % [t, max_step, side])
	check(turned and car.direction < 0 and max_step < 0.4 and side > 1.0,
		"the car U-turns smoothly into the other lane at the end of its patrol")


func t_traffic_world() -> void:
	var lane: Route = boot.builder.network.road("home_lane")
	var cars: Array[TrafficCar] = []
	for k in 4:
		var car := boot.world.get_node_or_null("TownCar%d" % k) as TrafficCar
		if car != null:
			cars.append(car)
	check(cars.size() == 4, "four cars patrol the town part of Homestead Lane")
	if cars.size() < 4:
		return
	for car in cars:
		if car._turn >= 0.0:
			continue      # mid U-turn at a patrol end, crossing between lanes
		var i := int(car.progress)
		var offset := car.global_position - lane.point(i)
		check(offset.dot(lane.right(i)) * float(car.direction) < -1.0,
			"%s keeps to its left lane" % car.name)
	var start := cars[0].global_position
	await wait(3.0)
	log_line("town traffic: %s speed %.1f waiting=%s progress %.1f" % [cars[0].global_position, cars[0].speed, cars[0].waiting, cars[0].progress])
	check(cars[0].global_position.distance_to(start) > 5.0,
		"the town cars move along the lane")


func t_driveway() -> void:
	var slab := boot.world.get_node_or_null("P2Driveway") as StaticBody3D
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	check(slab != null and house != null, "P2's steep drive joins the lane to the house")
	if slab == null or house == null:
		return
	var lane: Route = boot.builder.network.road("home_lane")
	var nearest := lane.nearest(house.position.x, house.position.z)
	var road := lane.point(int(nearest["index"]))
	var front := house.position + house.basis * Vector3(0, 0, 4.8)
	var grade := (front.y - road.y) / Vector2(front.x - road.x, front.z - road.z).length()
	log_line("P2 driveway: grade %.1f%%, slab mid %.1f m, terrain mid %.1f m" % [grade * 100.0,
		slab.global_position.y, Landscape.ground(slab.global_position.x, slab.global_position.z)])
	check(grade > 0.18 and grade < 0.23, "P2's drive has about a 20% grade")
	var c := camper()
	c.parking_brake = true
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(slab.global_basis, slab.global_position + Vector3.UP * 1.4)
	c.reset_physics_interpolation()
	await wait(2.5)
	var parked := c.global_position
	await wait(2.0)
	check(c.global_position.distance_to(parked) < 0.15,
		"the handbrake holds the van on P2's drive")
	await face_point(p1(), slab.global_position + Vector3.UP * 1.0, 19.0, road - house.position)
	await shot("p2_driveway")
	c.set_parking_brake(false)
	await wait(2.5)
	check(c.global_position.distance_to(parked) > 1.5,
		"the van rolls down P2's drive without the handbrake")
	c.set_parking_brake(true)


## Opening story state in the actual world. Gym scenarios cover the long
## physical tasks; this checks their story handoffs and the two HUD threads.
func t_opening() -> void:
	var st: Story = boot.story
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	var c := camper()
	check(st.opening_mode and house != null, "a new game begins the two-player opening")
	if not st.opening_mode or house == null:
		return
	check(absf(c.fuel - 6.0) < 0.1 and p1().global_position.distance_to(p2().global_position) > 800.0,
		"P1 starts with a nearly dry van while P2 starts at the other house")
	check(p2().flashlight_seconds <= 0.0 and st.phone_unread(0) == 2 and st.phone_unread(1) == 2,
		"P2's torch is dead and both phones have the mother's news")
	check(boot.map_state.is_revealed("windmill"), "the windmill is printed on P2's opening map for stamping")
	await tap(KEY_P, 0.2)
	await wait(0.35)
	log_line("opening phone P1: open=%s seen=%d step=%d owner=%d" % [p1().phone_open, st.phone_seen[0], st.opening_steps[0], boot.kbm_owner])
	check(p1().phone_open and st.opening_steps[0] == 1,
		"P1 reads the phone and gets the Town Fuel objective")
	await shot("opening_phone")
	await tap(KEY_ESCAPE, 0.2)
	check(not p1().phone_open and not boot.paused, "ESC puts the phone away without pausing")
	await tap(KEY_TAB, 0.2)
	await tap(KEY_P, 0.2)
	await wait(0.35)
	log_line("opening phone P2: open=%s seen=%d step=%d owner=%d" % [p2().phone_open, st.phone_seen[1], st.opening_steps[1], boot.kbm_owner])
	check(p2().phone_open and st.opening_steps[1] == 1,
		"P2 reads the same news and gets the battery objective")
	await tap(KEY_P, 0.2)
	var side := house.global_basis * Vector3(0, 0, 1)
	await face_point(p2(), house.to_global(Vector3(-3.0, 0.85, -1.92)), 1.5, side)
	log_line("opening drawer prompt: '%s'" % p2().prompt_text)
	await tap(KEY_E)
	check(house.drawer_open and house.battery_pack != null, "P2 finds batteries in the kitchen drawer")
	if house.battery_pack == null:
		return
	await face_point(p2(), house.battery_pack.global_position + Vector3.UP * 0.2, 1.3, side)
	await tap(KEY_E)
	await tap(KEY_F)
	await wait(0.35)
	check(st.opening_steps[1] == 2 and st.phone_unread(0) > 0,
		"fitting batteries advances P2 and tells P1")
	var shed := house.to_global(Vector3(8.5, 1.3, 3.46))
	await face_point(p2(), shed, 1.5, side)
	await tap(KEY_E)
	await face_point(p2(), house.fuel_can.global_position + Vector3.UP * 0.2, 1.4, side)
	await tap(KEY_E)
	check(p2().held == house.fuel_can, "P2 can carry the shed's empty can")
	if p2().held == house.fuel_can:
		await face_point(p2(), house.drum.to_global(Vector3(0, 0.85, 0.75)), 1.25, side)
		log_line("opening drum prompt: '%s' can %.1f" % [p2().prompt_text, house.fuel_can.litres])
		await hold_physics(KEY_E, 5.5)
		p2().drop_held()
	await wait(0.35)
	log_line("opening shed: can %.1f step %d" % [house.fuel_can.litres, st.opening_steps[1]])
	check(st.opening_steps[1] == 3, "the full shed can advances P2 to the map")
	var j1: Vector3 = boot.builder.poi["j1"]
	boot.map_state.add_stamp("unexplored", Vector2(j1.x, j1.z))
	await wait(0.35)
	check(st.opening_steps[1] == 4, "stamping the windmill advances P2 to the window")
	await tap(KEY_TAB)
	var town := boot.world.get_node("TownFuel") as Node3D
	c.global_position = town.to_global(Vector3(5.0, 0.85, 5.0))
	c.linear_velocity = Vector3.ZERO
	c.reset_physics_interpolation()
	await wait(0.4)
	check(st.opening_steps[0] == 2, "reaching Town Fuel advances P1 to filling a can")
	var pump := town.get_node("WorkingPump") as FuelSource
	var can := find_can("town_empty")
	check(can != null and can.litres <= 0.01, "an empty can waits at Town Fuel")
	if can == null:
		return
	await face_point(p1(), can.global_position + Vector3.UP * 0.2, 1.3, pump.global_basis.z)
	log_line("town can: %s prompt '%s'" % [can.global_position, p1().prompt_text])
	await tap(KEY_E)
	log_line("town held: %s" % [p1().held])
	if p1().held == can:
		await face_point(p1(), pump.to_global(Vector3(0, 0.85, 0.75)), 1.3, pump.global_basis.z)
		log_line("town pump prompt: '%s'" % p1().prompt_text)
		log_line("town positions: p1 %s pump %s van %s collider %s" % [p1().global_position, pump.global_position, c.global_position, p1().ray.get_collider()])
		await hold_physics(KEY_E, 5.5)
		p1().drop_held()
	check(st.flags.has("town_fuel_filled") and can.litres > 19.0,
		"P1 fills the stand's can at the working pump")
	c.fuel = 14.0  # the real pouring path is checked in the carry scenario
	await wait(0.35)
	check(st.opening_steps[0] == 3 and st.flags.has("opening_puncture_armed"),
		"refueling arms the fixed roadworks beat")
	var lane: Route = boot.builder.network.road("home_lane")
	var f := lane.forward(520)
	c.set_parking_brake(false)
	c.freeze = false
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), lane.point(510) + Vector3.UP * 0.8)
	c.reset_physics_interpolation()
	await wait(0.2)
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), lane.point(520) + Vector3.UP * 0.8)
	c.sleeping = false
	c.reset_physics_interpolation()
	await wait(0.7)
	log_line("opening nails: flat=%s armed=%s done=%s step=%d pos=%s" % [c.tyre_flat,
		st.flags.has("opening_puncture_armed"), st.flags.has("opening_puncture_done"), st.opening_steps[0], c.global_position])
	var trap := boot.world.get_node("RoadworksNails/PunctureArea") as Area3D
	log_line("opening trap: %s overlapping=%s van layer=%d freeze=%s" % [trap.global_position, trap.get_overlapping_bodies(), c.collision_layer, c.freeze])
	check(c.tyre_flat and st.opening_steps[0] == 4,
		"crossing the nails advances P1 to the spare-wheel repair")
	c.tyre_flat = false
	c.tyre_stage = 0
	c.spare_available = false
	c.refresh_tyre_visuals()  # the gym checks the full physical repair
	await wait(0.35)
	check(st.opening_steps[0] == 5 and st.phone_unread(1) > 0,
		"repair advances P1 and sends P2 a puncture text")
	var slab := boot.world.get_node("P2Driveway") as StaticBody3D
	c.parking_brake = true
	c.global_transform = Transform3D(slab.global_basis, slab.global_position + Vector3.UP * 1.2)
	c.reset_physics_interpolation()
	var out := house.global_basis * Vector3(0, 0, 1)
	await place_player(p2(), house.to_global(Vector3(-2.5, 3.35, 2.4)), atan2(-out.x, -out.z))
	await wait(0.4)
	check(st.opening_steps[0] == 6 and st.opening_steps[1] == 5,
		"parking and watching from the window lead both players to loading")
	house.fuel_can.stow(c.storage_slots[0])
	house.coolant_jug.stow(c.storage_slots[2])
	await wait(0.35)
	check(st.opening_steps[0] == 7 and st.opening_steps[1] == 6,
		"stowing both supplies advances each player's objective")
	p1().enter_seat(c, c.seat_nodes["driver"], "driver")
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await wait(0.35)
	check(not st.opening_mode and st.flags.has("opening_complete") and st.index == 2,
		"both seated reunites the objectives at the windmill journey")


func t_opening_save() -> void:
	var st: Story = boot.story
	var house := boot.world.get_node("P2Home") as HouseInterior
	var pump := boot.world.get_node("TownFuel/WorkingPump") as FuelSource
	var c := camper()
	check(st.opening_mode, "the opening can be saved before pick-up")
	st.opening_steps = [2, 2]
	st.phone_seen = [2, 0]
	st.flags["opening_puncture_armed"] = true
	house.from_dict({"front_open": true, "shed_open": true, "drawer_open": true, "drum_litres": 87.0})
	house.fuel_can.litres = 8.0
	house.fuel_can._update_mass()
	pump.litres = 930.0
	c.fuel = 9.0
	c.tyre_flat = true
	c.refresh_tyre_visuals()
	p2().flashlight_seconds = 123.0
	p2().flashlight.visible = true
	p2().beam.visible = true
	await physics_frames(3)
	check(SaveGame.write(boot, 1), "the opening writes a save slot")
	PlayTest.expect = {"p2": p2().global_position}
	PlayTest.carried_failures = _failures.duplicate()
	PlayTest.resume = "opening_save_verify"
	boot.load_slot(1)


func t_opening_save_verify() -> void:
	await wait(1.2)
	var st: Story = boot.story
	var house := boot.world.get_node("P2Home") as HouseInterior
	var pump := boot.world.get_node("TownFuel/WorkingPump") as FuelSource
	log_line("opening restored: mode=%s steps=%s unread=%d flags=%s" % [st.opening_mode,
		st.opening_steps, st.phone_unread(1), st.flags])
	check(st.opening_mode and st.opening_steps == [2, 2] and st.phone_unread(1) == 2,
		"loading restores both opening objectives and unread phone texts")
	check(house.front_open and house.shed_open and house.drawer_open and absf(house.drum.litres - 87.0) < 0.1,
		"loading restores the house doors, drawer and drum")
	check(absf(house.fuel_can.litres - 8.0) < 0.1 and absf(pump.litres - 930.0) < 0.1,
		"loading restores both cans' fuel source state")
	check(absf(camper().fuel - 9.0) < 0.1 and camper().tyre_flat,
		"loading restores the opening van's fuel and puncture")
	check(p2().global_position.distance_to(PlayTest.expect["p2"]) < 0.5 and
		absf(p2().flashlight_seconds - 123.0) < 2.0 and p2().flashlight.visible,
		"loading returns P2 to the house with the torch battery state")


## Walk a player to `target` for real: turn to face it and hold W, one physics
## tick at a time. Returns false (and logs where) if they get stuck.
func walk_to(p: PlayerRig, target: Vector3, what: String, arrive := 0.5, max_s := 25.0) -> bool:
	var t := 0.0
	var mark := p.global_position
	var mark_t := 0.0
	key(KEY_W, true)
	while t < max_s:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var d := target - p.global_position
		d.y = 0.0
		if d.length() < arrive:
			key(KEY_W, false)
			return true
		p.yaw = atan2(-d.x, -d.z)
		p.rotation.y = p.yaw
		if not Input.is_physical_key_pressed(KEY_W):
			key(KEY_W, true)
		if t - mark_t > 1.5:
			if p.global_position.distance_to(mark) < 0.3:
				break
			mark = p.global_position
			mark_t = t
	key(KEY_W, false)
	var house := boot.world.get_node_or_null("P2Home") as Node3D
	var local := house.to_local(p.global_position) if house else p.global_position
	log_line("WALK STUCK going to %s: at %s (house local %s), %.1f m short" % [what, p.global_position, local,
		Vector2(target.x - p.global_position.x, target.z - p.global_position.z).length()])
	await shot("walk_stuck_" + what.replace(" ", "_"))
	return false


## Look at a point from where the player stands (no moving).
func look_at_point(p: PlayerRig, target: Vector3) -> void:
	var d := target - p.global_position
	p.yaw = atan2(-d.x, -d.z)
	p.rotation.y = p.yaw
	var eye := p.global_position + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16)
	p.pitch = atan2(target.y - eye.y, Vector2(target.x - eye.x, target.z - eye.z).length())
	await physics_frames(4)


## P2's whole part of the opening on foot, walking every step with the real
## controls: kitchen drawer and torch, out of the front door, the shed can and
## drum, back in and up to the window, then down and out to the drive.
## `tools/run_test.sh opening_p2`
func t_opening_p2() -> void:
	var st: Story = boot.story
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	check(st.opening_mode and house != null, "a new game begins the two-player opening")
	if house == null:
		return
	var p := p2()
	var H := func(v: Vector3) -> Vector3: return house.to_global(v)
	await tap(KEY_TAB, 0.2)
	check(boot.kbm_owner == 1, "TAB gives the keyboard to P2")
	await shot("p2_start")
	await tap(KEY_P, 0.2)
	await wait(1.0)
	await tap(KEY_P, 0.2)
	# the dead torch
	await tap(KEY_F)
	check(not p.flashlight.visible, "P2's torch starts dead")
	# kitchen drawer
	var ok: bool = await walk_to(p, H.call(Vector3(-3.0, 0, -1.1)), "kitchen drawer")
	check(ok, "P2 walks from the spawn to the kitchen drawer")
	await look_at_point(p, H.call(Vector3(-3.0, 0.85, -1.92)))
	log_line("at the drawer: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("drawer"), "the drawer offers to be opened")
	await tap(KEY_E)
	await wait(0.6)
	check(house.drawer_open and house.battery_pack != null, "E opens the drawer and shows the batteries")
	await shot("p2_drawer_open")
	if house.battery_pack == null:
		return
	log_line("batteries at %s (house local %s)" % [house.battery_pack.global_position, house.to_local(house.battery_pack.global_position)])
	await look_at_point(p, house.battery_pack.global_position + Vector3.UP * 0.1)
	log_line("looking at the batteries: '%s'" % p.prompt_text)
	await tap(KEY_E)
	check(p.held is BatteryPack, "P2 picks the batteries up")
	await wait(0.3)
	log_line("holding the batteries: '%s'" % p.prompt_text)
	check(p.prompt_text.contains(p.dev.glyph("flashlight")), "the prompt says which key fits the batteries")
	await tap(KEY_F)
	check(p.flashlight.visible and p.held == null, "F fits the batteries and the torch comes on")
	await shot("p2_torch_on")
	# out of the front door
	ok = await walk_to(p, H.call(Vector3(0, 0, 2.9)), "inside the front door")
	check(ok, "P2 walks from the kitchen to the front door")
	await look_at_point(p, H.call(Vector3(0, 1.3, 4.12)))
	log_line("inside the front door: '%s'" % p.prompt_text)
	await tap(KEY_E)
	check(house.front_open, "the front door opens from inside")
	ok = await walk_to(p, H.call(Vector3(0, 0, 6.5)), "outside the front door")
	check(ok, "P2 walks out of the house")
	await shot("p2_outside")
	# the shed
	ok = await walk_to(p, H.call(Vector3(8.5, 0, 5.0)), "shed door")
	check(ok, "P2 walks round to the shed door")
	await look_at_point(p, H.call(Vector3(8.5, 1.3, 3.1)))
	log_line("at the shed door: '%s'" % p.prompt_text)
	await tap(KEY_E)
	check(house.shed_open, "the shed door opens")
	ok = await walk_to(p, H.call(Vector3(7.5, 0, 1.4)), "in the shed")
	check(ok, "P2 walks into the shed")
	await look_at_point(p, house.fuel_can.global_position + Vector3.UP * 0.2)
	log_line("at the shed can: '%s'" % p.prompt_text)
	await tap(KEY_E)
	check(p.held == house.fuel_can, "P2 picks up the empty can")
	ok = await walk_to(p, H.call(Vector3(8.5, 0, -0.3)), "the drum")
	await look_at_point(p, H.call(Vector3(8.5, 0.85, -0.95)))
	log_line("at the drum: '%s'" % p.prompt_text)
	await hold_physics(KEY_E, 5.0)
	check(house.fuel_can.litres > 19.0, "holding E fills the can at the drum")
	await shot("p2_shed")
	# carry it out to where the van will park, then back in and upstairs
	ok = await walk_to(p, H.call(Vector3(7.5, 0, 5.0)), "out of the shed with the can")
	check(ok, "P2 carries the full can out of the shed")
	ok = await walk_to(p, H.call(Vector3(2.2, 0, 7.0)), "the top of the drive with the can")
	check(ok, "P2 carries the can to the top of the drive")
	await tap(KEY_E)  # set it down
	check(p.held == null, "P2 puts the can down by the drive")
	await tap(KEY_M, 0.2)
	await wait(0.3)
	var j1: Vector3 = boot.builder.poi["j1"]
	boot.map_state.add_stamp("unexplored", Vector2(j1.x, j1.z))
	await tap(KEY_M, 0.2)
	check(st.opening_steps[1] == 4, "P2's jobs are done: watch for the van")
	ok = await walk_to(p, H.call(Vector3(0, 0, 2.5)), "back in the door")
	ok = ok and await walk_to(p, H.call(Vector3(3.9, 0, 3.1)), "the foot of the stairs")
	ok = ok and await walk_to(p, H.call(Vector3(3.9, 0, -3.2)), "up the stairs", 0.6)
	check(ok and p.global_position.y > house.global_position.y + 3.0, "P2 climbs the stairs")
	ok = await walk_to(p, H.call(Vector3(1.5, 0, -3.2)), "off the landing")
	ok = ok and await walk_to(p, H.call(Vector3(-2.5, 0, 2.9)), "the upstairs window")
	check(ok and p.global_position.y > house.global_position.y + 3.0, "P2 walks from the landing to the window, upstairs")
	await look_at_point(p, H.call(Vector3(-2.5, 3.9, 10.0)))
	await shot("p2_window")
	# and back down and out to the drive
	ok = await walk_to(p, H.call(Vector3(1.5, 0, -3.2)), "back to the landing")
	ok = ok and await walk_to(p, H.call(Vector3(3.9, 0, -3.2)), "the top of the stairs")
	ok = ok and await walk_to(p, H.call(Vector3(3.9, 0, 3.1)), "down the stairs", 0.6)
	ok = ok and await walk_to(p, H.call(Vector3(0, 0, 2.5)), "the door again")
	ok = ok and await walk_to(p, H.call(Vector3(0, 0, 9.0)), "down to the drive")
	check(ok and p.global_position.y < house.global_position.y + 0.5, "P2 walks back down and out to the drive")


## Metres each player would have walked between the spots the full opening
## teleports them to (the test stands them at each job, a person walks there).
var _walk_m := [0.0, 0.0]


## face_point for places off the terrain (a driveway slab, house floors): the
## player stands on whatever solid is below the spot.
func go_to(p: PlayerRig, target: Vector3, dist: float, side := Vector3.ZERO) -> void:
	var dir := side if side != Vector3.ZERO else Vector3(1, 0, 0.3)
	dir.y = 0.0
	dir = dir.normalized()
	var stand := target + dir * dist
	# from just above the target's own height, so a ceiling is not taken for the floor
	var top := Vector3(stand.x, target.y + 0.6, stand.z)
	var q := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 10.0, 1)
	q.exclude = [p.get_rid(), camper().get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	stand.y = (hit["position"] as Vector3).y + 0.1 if not hit.is_empty() else Landscape.ground(stand.x, stand.z) + 0.1
	var from := p.global_position
	_walk_m[p.index] += Vector2(stand.x - from.x, stand.z - from.z).length()
	var d := target - stand
	var had := p.held
	await place_player(p, stand, atan2(-d.x, -d.z))
	if had != null and p.held == null:
		log_line("go_to: %s dropped on the move; stand %s, item %s, hold point %s" % [had.name, stand, had.global_position, p.hold_point(had)])
	var eye := stand + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16)
	p.pitch = atan2(target.y - eye.y, Vector2(target.x - eye.x, target.z - eye.z).length())
	await physics_frames(3)
	if had != null and p.held == null:
		log_line("go_to: %s dropped after aiming; item %s, hold point %s" % [had.name, had.global_position, p.hold_point(had)])


## Drive P1's van along `path` with the keyboard until `done` or the stop index,
## then brake to a halt and set the handbrake. Returns the seconds driven.
func drive_until(path: Route, stop_idx: int, done: Callable, limit_s: float, target_kmh := -1.0, lane := -1.8, look_min := 4) -> float:
	var c := camper()
	c.freeze = false
	var ad := AutoDriver.new(self, path, c)
	ad.lane = lane    # keep left, as the town cars do
	if look_min < 4:
		ad.look_min = look_min
		ad.look_gain = 0.25
	var t := 0.0
	var stuck := 0.0
	while t < limit_s:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		# ease off before the stop like a driver looking for the place
		var left := stop_idx - ad.idx
		var tk := target_kmh
		if left < 40:
			tk = 25.0 if tk < 0.0 else minf(tk, 25.0)
		if left < 14:
			tk = minf(tk, 10.0)
		ad.step(tk)
		stuck = stuck + 1.0 / 60.0 if kmh() < 2.0 else 0.0
		if ad.idx >= stop_idx or done.call() or (stuck > 8.0 and t > 10.0):
			break
	ad.release()
	key(KEY_S, true)
	var braking := 0.0
	while kmh() > 0.5 and braking < 8.0:
		await get_tree().physics_frame
		braking += 1.0 / 60.0
		key(KEY_S, true)
	# let go of S first: held at a standstill it reverses, which releases the handbrake
	key(KEY_S, false)
	if not c.parking_brake:
		await tap(KEY_SPACE)
	await wait(0.5)
	log_line("drive: %.0f s, %.0f m, off-road max %.1f m, now %s, fuel %.1f L" % [t, ad.progress * Route.SAMPLE_SPACING,
		ad.max_off, c.global_position, c.fuel])
	return t + braking


func enter_door(p: PlayerRig, role: String) -> void:
	var c := camper()
	var sx := -1.2 if role == "driver" else 1.2
	var door := c.global_transform * Vector3(sx, 1.2, -1.8)
	await go_to(p, door, 2.2, c.global_basis.x * signf(sx))
	await tap(KEY_E)
	await physics_frames(3)
	if role == "driver" and p.seat_role == "driver" and not c.engine_on:
		await tap(KEY_X)
		await wait(1.0)


## The whole opening played through in the real world with the real controls:
## P2's house jobs, P1's drive through town, filling and pouring a can, the
## roadworks puncture and full wheel swap, the drive up P2's steep drive,
## loading the gear and both getting in. Walks between jobs are teleports,
## counted as metres and added to the timing at walking pace.
## `tools/run_test.sh full` runs it; alone: `tools/run_test.sh opening_full`.
func t_opening_full() -> void:
	var st: Story = boot.story
	var house := boot.world.get_node_or_null("P2Home") as HouseInterior
	var c := camper()
	check(st.opening_mode and house != null, "a new game begins the two-player opening")
	if not st.opening_mode or house == null:
		return
	_walk_m = [0.0, 0.0]
	var t_start := Time.get_ticks_msec()
	var side := house.global_basis * Vector3(0, 0, 1)

	# --- P2 in the house, while P1 gets going (the two run side by side) ---
	var p2_start := Time.get_ticks_msec()
	await tap(KEY_TAB, 0.2)
	await tap(KEY_P, 0.2)
	await wait(4.0)  # reading the mother's text
	await tap(KEY_P, 0.2)
	check(st.opening_steps[1] == 1, "P2 reads the phone and is sent for the batteries")
	await go_to(p2(), house.to_global(Vector3(-3.0, 0.85, -1.92)), 1.5, side)
	await tap(KEY_E)
	if house.battery_pack != null:
		await go_to(p2(), house.battery_pack.global_position + Vector3.UP * 0.2, 1.3, side)
		await tap(KEY_E)
		await tap(KEY_F)
	await wait(0.4)
	check(st.opening_steps[1] == 2 and p2().flashlight.visible, "P2 fits the batteries and the torch works")
	await go_to(p2(), house.to_global(Vector3(0, 1.3, 4.48)), 1.5, side)
	if not house.front_open:
		await tap(KEY_E)
	await go_to(p2(), house.to_global(Vector3(8.5, 1.3, 3.46)), 1.5, side)
	await tap(KEY_E)
	await go_to(p2(), house.fuel_can.global_position + Vector3.UP * 0.2, 1.4, side)
	await tap(KEY_E)
	if p2().held == house.fuel_can:
		await go_to(p2(), house.drum.to_global(Vector3(0, 0.85, 0.75)), 1.25, side)
		await hold_physics(KEY_E, 5.5)
		await go_to(p2(), house.to_global(Vector3(7.4, 0.3, 0.6)), 1.2, side)
		await tap(KEY_E)  # put it down inside the shed door
	await wait(0.4)
	check(st.opening_steps[1] == 3 and house.fuel_can.litres > 19.0, "P2 fills the shed can from the drum")
	await tap(KEY_M, 0.2)
	await wait(0.3)
	var j1: Vector3 = boot.builder.poi["j1"]
	check(p2().map_open, "P2 raises the paper map")
	# Pencil placement is checked in the map scenario; here the stamp lands on the windmill.
	boot.map_state.add_stamp("unexplored", Vector2(j1.x, j1.z))
	await wait(0.4)
	await tap(KEY_M, 0.2)
	check(st.opening_steps[1] == 4, "stamping the windmill sends P2 to watch from the window")
	var p2_solo_s := (Time.get_ticks_msec() - p2_start) / 1000.0 + 20.0  # + ~20 s to find and stamp the windmill

	# --- P1: phone, van, Town Fuel ---
	var p1_start := Time.get_ticks_msec()
	await tap(KEY_TAB, 0.2)
	await tap(KEY_P, 0.2)
	await wait(4.0)
	await tap(KEY_P, 0.2)
	check(st.opening_steps[0] == 1, "P1 reads the phone and is sent to Town Fuel")
	await enter_door(p1(), "driver")
	check(p1().seat_role == "driver", "P1 gets into the driver's seat")
	check(c.engine_on, "X starts the nearly dry van")
	var lane: Route = boot.builder.network.road("home_lane")
	var town := boot.world.get_node("TownFuel") as Node3D
	var town_near := lane.nearest(town.global_position.x, town.global_position.z)
	var town_i := int(town_near["index"])
	log_line("Town Fuel stands %.0f m from the lane centre" % float(town_near["dist"]))
	var drive_s := await drive_until(lane, town_i + 3, func(): return false, 240.0)
	log_line("OPENING town fuel reached in %.0f s of driving, %.1f L left, van %.0f m from the station" % [drive_s, c.fuel,
		Vector2(c.global_position.x - town.global_position.x, c.global_position.z - town.global_position.z).length()])
	check(st.opening_steps[0] == 2 and c.engine_on, "P1 drives to Town Fuel without running dry")
	await tap(KEY_E)
	await physics_frames(3)
	check(p1().seat == null, "P1 gets out at the forecourt")
	var pump := town.get_node("WorkingPump") as FuelSource
	var can := find_can("town_empty")
	await go_to(p1(), can.global_position + Vector3.UP * 0.2, 1.3, pump.global_basis.z)
	await tap(KEY_E)
	check(p1().held == can, "P1 picks up the empty can at the stand")
	await go_to(p1(), pump.to_global(Vector3(0, 0.85, 0.75)), 1.3, pump.global_basis.z)
	await hold_physics(KEY_E, 5.5)
	check(can.litres > 19.0, "holding E at the pump fills the can")
	var inlet := c.global_transform * (Vector3(-1.2, 1.40, 1.9) + Vector3(0, Camper.BODY_Y, 0))
	await go_to(p1(), inlet, 1.5, -c.global_basis.x)
	var f0 := c.fuel
	await hold_physics(KEY_E, 4.0)
	log_line("OPENING poured %.1f L; tank %.1f L; holding %s" % [c.fuel - f0, c.fuel, p1().held])
	await go_to(p1(), c.storage_slots[0].global_position + Vector3.UP * 0.3, 1.9, c.global_basis.z)
	await wait(0.3)
	log_line("at the rack: '%s', holding %s" % [p1().prompt_text, p1().held])
	await tap(KEY_E)
	check(c.stowed_item(c.storage_slots[0]) == can, "the town can rides on the rack")
	await wait(0.4)
	check(st.opening_steps[0] == 3, "refuelling sends P1 on towards P2")

	# --- the roadworks and the wheel swap ---
	await enter_door(p1(), "driver")
	var nails_i := 520
	drive_s += await drive_until(lane, nails_i + 30, func(): return c.tyre_flat, 120.0)
	check(c.tyre_flat and st.opening_steps[0] == 4, "the roadworks nails puncture the van")
	if not c.tyre_flat:
		return
	await wait(1.0)
	check(c.parking_brake, "P1 stops on the handbrake for the repair")
	await tap(KEY_E)
	await physics_frames(3)
	var swap_start := Time.get_ticks_msec()
	var rear := c.global_transform * Vector3(0, 2.05 + Camper.BODY_Y, 3.25)
	await go_to(p1(), rear, 2.0, c.global_basis.z)
	await tap(KEY_E)
	check(p1().held is SpareWheel, "P1 takes the spare off the back")
	var wheel := p1().held as SpareWheel
	var front := c.global_transform * Vector3(-1.55, 0.48 + Camper.BODY_Y, -Camper.WHEELBASE)
	await go_to(p1(), front, 2.0, -c.global_basis.x)
	await tap(KEY_E)
	if wheel != null:
		wheel.global_position = c.global_transform * Vector3(-3.3, 0.7, -Camper.WHEELBASE - 1.0)
		wheel.linear_velocity = Vector3.ZERO
		wheel.reset_physics_interpolation()
	await go_to(p1(), front, 1.8, -c.global_basis.x)
	await tap(KEY_E)
	await hold_physics(KEY_E, 7.0)
	await wait(0.2)
	await tap(KEY_E)
	if wheel != null:
		await go_to(p1(), wheel.global_position, 1.5)
		await tap(KEY_E)
	await go_to(p1(), front, 1.8, -c.global_basis.x)
	await hold_physics(KEY_E, 7.0)
	await wait(0.2)
	await tap(KEY_E)
	await wait(0.4)
	var swap_s := (Time.get_ticks_msec() - swap_start) / 1000.0
	log_line("OPENING wheel swap took %.0f s (walks as teleports)" % swap_s)
	check(not c.tyre_flat and not c.spare_available and st.opening_steps[0] == 5,
		"P1 swaps the wheel and P2 hears about the puncture")
	await shot("opening_full_swap")

	# --- P2's steep drive ---
	await enter_door(p1(), "driver")
	# the same two ends LevelPlaces._p2_home builds the drive between
	var turn_i := int(lane.nearest(house.global_position.x, house.global_position.z)["index"])
	var bottom := lane.point(turn_i) + Vector3.UP * 0.1
	var top := house.to_global(Vector3(0, 0.1, 4.8))
	top = top.lerp(bottom, 0.25)  # stop short of the front door
	# down the lane, a turning arc (tangent 9 m each side of the corner, about
	# the van's full lock) into the drive, then straight up the middle of it
	var tangent := 9.0
	var up_drive := top - bottom
	up_drive.y = 0.0
	up_drive = up_drive.normalized()
	var arc_in_i := turn_i - int(tangent / Route.SAMPLE_SPACING)
	var arc_in := lane.point(arc_in_i)
	var arc_out := bottom.lerp(top, tangent / bottom.distance_to(top))
	var pts := PackedVector3Array()
	var cur_i := int(lane.nearest(c.global_position.x, c.global_position.z)["index"])
	for i in range(cur_i, arc_in_i, 2):
		pts.append(lane.point(i))
	for k in 12:
		var s := float(k + 1) / 12.0
		pts.append(arc_in.lerp(bottom, s).lerp(bottom.lerp(arc_out, s), s))
	for k in 12:
		pts.append(arc_out.lerp(top, float(k + 1) / 12.0))
	var drive_path := Route.from_points(pts, false)
	var to_p2 := await drive_until(drive_path, drive_path.point_count() - 4, func():
		return c.global_position.distance_to(top) < 4.5, 120.0, 12.0, 0.0, 2)
	drive_s += to_p2
	log_line("OPENING drive up: van %.1f m from the top of the drive, %.1f m from the house, grade under the van %.0f%%" % [
		c.global_position.distance_to(top), Vector2(c.global_position.x - house.global_position.x,
		c.global_position.z - house.global_position.z).length(), rad_to_deg(acos(clampf(c.global_basis.y.y, -1, 1)))])
	var slab := boot.world.get_node("P2Driveway") as Node3D
	var axis := top - bottom
	axis.y = 0.0
	var rel := c.global_position - bottom
	rel.y = 0.0
	var along_m := rel.dot(axis.normalized())
	var across_m := rel.dot(axis.normalized().cross(Vector3.UP))
	log_line("OPENING drive geometry: bottom %s top %s (%.0f m), slab centre %s; van %.1f m along, %.1f m across, heading off the drive by %.0f deg" % [
		bottom, top, axis.length(), slab.global_position, along_m, across_m,
		rad_to_deg((-c.global_basis.z * Vector3(1, 0, 1)).normalized().angle_to(axis.normalized()))])
	await wait(2.5)
	var parked := c.global_position
	await wait(2.0)
	check(absf(across_m) < 1.4 and along_m > 8.0, "P1 drives the van up onto P2's drive")
	check(c.parking_brake and c.global_position.distance_to(parked) < 0.15 and st.opening_steps[0] == 6,
		"P1 parks on P2's steep drive with the handbrake")
	await shot("opening_full_driveway")
	var p1_arrive_s := (Time.get_ticks_msec() - p1_start) / 1000.0

	# --- together: the window, the gear, into the van ---
	var after_start := Time.get_ticks_msec()
	await tap(KEY_TAB, 0.2)
	var out := house.global_basis * Vector3(0, 0, 1)
	_walk_m[1] += 12.0  # up the stairs
	await place_player(p2(), house.to_global(Vector3(-2.5, 3.35, 2.4)), atan2(-out.x, -out.z))
	await wait(1.5)
	check(st.opening_steps[1] == 5, "P2 sees the van from the upstairs window")
	await go_to(p2(), house.fuel_can.global_position + Vector3.UP * 0.2, 1.4, side)
	await wait(0.3)
	log_line("shed can: '%s' at %s" % [p2().prompt_text, house.fuel_can.global_position])
	await tap(KEY_E)
	check(p2().held == house.fuel_can, "P2 picks up the full shed can")
	await go_to(p2(), c.storage_slots[1].global_position + Vector3.UP * 0.3, 1.9, c.global_basis.z)
	await tap(KEY_E)
	await go_to(p2(), house.coolant_jug.global_position + Vector3.UP * 0.2, 1.4, side)
	await tap(KEY_E)
	await go_to(p2(), c.storage_slots[2].global_position + Vector3.UP * 0.3, 1.9, c.global_basis.z)
	await tap(KEY_E)
	await wait(0.4)
	check(st.opening_steps[0] == 7 and st.opening_steps[1] == 6, "P2 loads the can and coolant onto the rack")
	await enter_door(p2(), "passenger")
	await wait(0.6)
	check(p2().seat_role == "passenger", "P2 gets in beside P1")
	check(not st.opening_mode and st.flags.has("opening_complete") and st.index == 2,
		"together in the van, the shared journey begins")
	var after_s := (Time.get_ticks_msec() - after_start) / 1000.0

	var walk1: float = _walk_m[0] / PlayerRig.WALK
	var walk2: float = _walk_m[1] / PlayerRig.WALK
	var p1_total := p1_arrive_s + walk1
	var p2_ready := p2_solo_s + walk2 * 0.6
	var total := maxf(p1_total, p2_ready) + after_s + walk2 * 0.4
	log_line("OPENING timing: P1 %.0f s to arrive (%.0f s driving, %.0f s tyre, %.0f m walked = %.0f s)" % [
		p1_total, drive_s, swap_s, _walk_m[0], walk1])
	log_line("OPENING timing: P2 %.0f s of house jobs before the van comes (%.0f m walked)" % [p2_ready, _walk_m[1]])
	log_line("OPENING timing: loading and boarding %.0f s; whole opening about %.1f min (script, no hesitation; the test ran %.0f s)" % [
		after_s, total / 60.0, (Time.get_ticks_msec() - t_start) / 1000.0])
	check(total < 600.0, "the scripted opening stays inside the 10-minute ceiling")


## Door and rear-view mirrors; the nav screen swung over to the passenger.
func t_mirrors() -> void:
	var c := camper()
	await reset_camper(6)
	await seat_p1_driver()
	var p := p1()
	var q := p2()
	q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await wait(0.6)
	var busy := 0
	for sv in c._mirrors:
		if headless:
			busy += 1      # nothing is rendered without a GPU; the rest still runs
			continue
		var img := sv.get_texture().get_image()
		var lo := 9.0
		var hi := -9.0
		for k in 40:
			var px := img.get_pixel(int(img.get_width() * (0.1 + 0.02 * k)), int(img.get_height() * (0.2 + 0.015 * k)))
			lo = minf(lo, px.get_luminance())
			hi = maxf(hi, px.get_luminance())
		if hi - lo > 0.08:
			busy += 1
		log_line("%s: %dx%d, brightness range %.2f" % [sv.name, img.get_width(), img.get_height(), hi - lo])
	check(busy == c._mirrors.size(), "all three mirrors show a picture while someone is in the van")
	# the driver glances at the left door mirror, then up at the rear-view
	p._seat_yaw = 0.75
	p.pitch = -0.05
	await wait(0.3)
	await shot("mirror_left")
	p._seat_yaw = 0.18
	p.pitch = 0.32
	await wait(0.3)
	await shot("mirror_rear")
	p._seat_yaw = 0.0
	p.pitch = PlayerRig.SEATED_PITCH
	# the nav, swung to the passenger with N
	await tap(KEY_N)
	await wait(0.6)
	var label: Label3D = c._needles["nav_label"]
	var driver_cam: Camera3D = p.cam
	var pass_cam: Camera3D = q.cam
	log_line("nav aside: %s, label layers %d, driver mask sees it %s, passenger mask sees it %s" % [c.nav_aside, label.layers, str(driver_cam.cull_mask & label.layers != 0), str(pass_cam.cull_mask & label.layers != 0)])
	check(c.nav_aside and driver_cam.cull_mask & label.layers == 0, "swung aside, the driver's view does not show the nav")
	check(pass_cam.cull_mask & label.layers != 0, "the passenger still sees it")
	await shot("nav_aside_driver")
	q._seat_yaw = 0.35
	q.pitch = -0.25
	await tap(KEY_TAB)
	await wait(0.3)
	await shot("nav_aside_passenger")
	await tap(KEY_TAB)
	await tap(KEY_N)
	await wait(0.6)
	check(not c.nav_aside and driver_cam.cull_mask & label.layers != 0, "N swings it back to the middle for both")
	q.exit_vehicle()
	await physics_frames(3)
	p.force_exit = true
	await physics_frames(3)
	await wait(0.2)
	check(c._mirrors[0].render_target_update_mode == SubViewport.UPDATE_DISABLED, "an empty van's mirrors stop rendering")


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


## Drive every road of the 4 km map with the keyboard auto-driver and time
## each leg against the beat chart (design/BEAT_CHART.md). Long (~20 min), so
## it is not in the default list: `tools/run_test.sh routes`.
func t_routes() -> void:
	var b: LevelBuilder = boot.builder
	var legs := [
		["opening: homestead -> town -> P2 -> J1", [["home_lane"]], ""],
		["valley road J1 -> J2", [["valley_road"]], ""],
		["ridge track J1 -> J2", [["ridge_track"]], ""],
		["pump house road J2 -> bridge", [["pump_house_road"]], "bridge_barrier_near"],
		["ghat hairpins + beach road J3 -> Bessi", [["ghat_road"], ["beach_road"]], ""],
		["coast road Bessi -> Naresh's home", [["coast_road"]], ""],
		["west road Naresh's home -> homestead", [["west_road"]], ""],
		["tower road -> P2's home", [["tower_road"]], ""],
	]
	var total := 0.0
	for leg in legs:
		var path := b.network.chain(leg[1])
		var stop_at := path.point_count() - 12
		if leg[2] != "":
			var bp: Vector3 = b.poi[leg[2]]
			stop_at = int(path.nearest(bp.x, bp.z)["index"]) - 10
		var c := camper()
		c.freeze = false
		var p0 := path.point(4)
		var f := path.forward(4)
		c.linear_velocity = Vector3.ZERO
		c.angular_velocity = Vector3.ZERO
		c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), p0 + Vector3.UP * 0.9)
		c.reset_physics_interpolation()
		c.fuel = Camper.FUEL_CAPACITY
		c.temp = Camper.TEMP_NORMAL
		c.coolant = 1.0
		c.coolant_leak = false
		c.parking_brake = false
		await physics_frames(30)
		await seat_p1_driver()
		if not c.engine_on:
			c.toggle_engine()
		var ad := AutoDriver.new(self, path, c)
		var t := 0.0
		var stuck := 0.0
		var temp_max := c.temp
		var fuel0 := c.fuel
		var flipped := false
		while t < 900.0:
			await get_tree().physics_frame
			t += 1.0 / 60.0
			ad.step(-1.0)
			temp_max = maxf(temp_max, c.temp)
			flipped = flipped or c.global_transform.basis.y.y < 0.4
			stuck = stuck + 1.0 / 60.0 if kmh() < 2.0 else 0.0
			if stuck > 8.0 or ad.idx >= stop_at:
				break
		ad.release()
		key(KEY_S, true)
		await wait(2.0)
		key(KEY_S, false)
		var arrived := ad.idx >= stop_at
		var metres := ad.idx * Route.SAMPLE_SPACING
		total += t
		log_line("ROUTE %s: arrived=%s  %.0f m in %.0f s (%.1f min, avg %.0f km/h)  off-road max %.1f m  fuel %.1f L  temp max %.0f" % [
			leg[0], arrived, metres, t, t / 60.0, metres / maxf(t, 1.0) * 3.6, ad.max_off, fuel0 - c.fuel, temp_max])
		if not arrived:
			await shot("routes_stuck_%d" % legs.find(leg))
		check(arrived and not flipped, "the auto-driver gets through: " + leg[0])
		check(ad.max_off < 6.0, "stays on the road: " + leg[0])
	log_line("ROUTE all roads driven in %.1f min" % (total / 60.0))


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
	log_line("driving, both players seated: avg %.1f fps, p95 frame %.1f ms, p99 %.1f ms" % [1.0 / avg, p95 * 1000.0, p99 * 1000.0])
	if headless:
		log_line("headless: audio and frame-rate checks need a real audio device and GPU; skipped")
	else:
		check(skips == 0, "engine audio is fed without dropouts while driving")
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
	## metres right of the centre line to steer for; negative keeps left
	var lane := 0.0
	## look-ahead: (min samples, samples per m/s); shorter for tight turn-ins
	var look_min := 4
	var look_gain := 0.55
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
		var look := int(look_min + v * look_gain)
		var target := route.point(idx + look) + route.right(idx + look) * lane
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
			for k in range(4, 45, 3):
				bend = maxf(bend, acos(clampf(Vector2(f0.x, f0.z).normalized().dot(Vector2(route.forward(idx + k).x, route.forward(idx + k).z).normalized()), -1, 1)))
			target = lerp(70.0, 35.0, clampf(bend / 0.9, 0.0, 1.0))
			if bend > 1.3:
				# a hairpin: crawl round it like a driver would
				target = lerp(35.0, 18.0, clampf((bend - 1.3) / 1.2, 0.0, 1.0))
		var v := van.linear_velocity.length() * 3.6
		t.key(KEY_W, v < target)
		t.key(KEY_S, v > target + 8.0)

	func release() -> void:
		for k in [KEY_W, KEY_A, KEY_S, KEY_D]:
			t.key(k, false)
