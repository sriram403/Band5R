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
## tools/run_test.sh passes --progress=<file>: each finished scenario is written
## there with its failures, and a rerun of the same plan (`run_test.sh resume`)
## skips what is already in it, so a run that broke off picks up where it
## stopped. Keyed by "<gym>|<selection>" so the same scenario in two segments
## is two entries.
var progress_path := ""
var _done := {}                  ## scenario -> its failures, from an earlier run
## No window and no GPU (`--headless`, e.g. CI or tools/run_test_headless.sh):
## screenshots are skipped and frame-rate checks are only logged.
var headless := DisplayServer.get_name() == "headless"

## Quick runs basic input/vehicle mechanics in the base gym, then checks the
## story, map, puzzle, save/load and rendering in the real world by teleport.
## Gyms with their own scenarios (the base gym runs QUICK_GYM).
const GYM_SCENARIOS := {"tyre": ["tyre"], "house": ["house"], "traffic": ["traffic", "lorry"], "tagging": ["tagging"], "binoculars": ["binoculars"], "stealth": ["stealth", "taken", "hiding"], "creature": ["van"], "naresh": ["naresh"], "photo": ["photo_gym"], "storm": ["storm_gym"]}
## Smoke (tools/run_test.sh with no arguments, ~3 min): the controls in the
## base gym and one short world check per system. The long playthroughs are
## in the sets and in full (tools/test_plan.sh).
const SMOKE_GYM := ["mouse", "taps", "enter", "cockpit", "exit", "swap"]
const SMOKE_WORLD := ["roadworks", "house_world", "traffic_world", "mood", "audio", "dev", "mirrors", "map", "story", "power", "relay_kb", "climb", "look", "pad", "perf", "beach", "save"]
const QUICK_GYM := ["gym", "mouse", "taps", "enter", "cockpit", "layout", "drive", "brake", "exit", "swap"]
const QUICK_WORLD := ["roadworks", "house_world", "traffic_world", "mood", "driveway", "audio", "dev", "mirrors", "map", "story", "windmill", "waterworks", "power", "bridge", "ghat", "ghat_menu", "tower", "maze", "relay", "relay_kb", "climb", "carry", "look", "pad", "teleports", "perf", "save"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playtest="):
			only = a.get_slice("=", 1)
		elif a.begins_with("--progress="):
			progress_path = a.substr(11)
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


## The nearest creature to Naresh, m (the live line's `until`: Expression has no lambdas).
func creature_to_naresh() -> float:
	var d := INF
	for cr in get_tree().get_nodes_in_group("creature"):
		d = minf(d, (cr as Node3D).global_position.distance_to(boot.naresh.global_position))
	return d


## How many creatures are within r m of a point (the live line).
func creatures_near(at: Vector3, r: float) -> int:
	var k := 0
	for cr in get_tree().get_nodes_in_group("creature"):
		if (cr as Node3D).global_position.distance_to(at) < r:
			k += 1
	return k


## The fishing village (the live line's expressions).
func village() -> FishingVillage:
	return get_tree().get_first_node_in_group("fishing_village") as FishingVillage


## The rail tunnel, and points in its service gallery for the live line: the
## gallery's middle line at road sample gate_i + k; a point down fork 1 / 2's
## side passage, d m in; in front of door 0 / 1 in the tunnel.
func tunnel() -> RailTunnel:
	return get_tree().get_first_node_in_group("rail_tunnel") as RailTunnel


func gallery_at(k: int) -> Vector3:
	var rt := tunnel()
	var i := rt.gate_i + k
	return rt.road.point(i) + rt.road.right(i) * rt._off


func gallery_fork(n: int, d: float) -> Vector3:
	var rt := tunnel()
	var fi: int = rt.doors[0] + (rt.gate_i - rt.doors[0]) / 2 if n == 1 else rt.gate_i + (rt.doors[1] - rt.gate_i) / 2
	return rt.road.point(fi) + rt.road.right(fi) * (rt._off + RailTunnel.GAL_W * 0.5 + d)


func gallery_door(n: int, inside: bool) -> Vector3:
	var rt := tunnel()
	var i: int = rt.doors[n]
	return rt.road.point(i) + rt.road.right(i) * (rt._off if inside else RailTunnel.IN_W - 2.5)


## Where the gallery's creature is, as a road sample offset from the gate
## (negative: the door-0 side), and which way it walks (+1 towards door 1).
func gallery_creature_k() -> float:
	var rt := tunnel()
	return float(rt.road.nearest(rt.watcher.global_position.x, rt.watcher.global_position.z)["index"] - rt.gate_i)


func gallery_creature_dir() -> float:
	var rt := tunnel()
	return signf(rt.watcher.velocity.dot(rt.road.forward(rt.gate_i)))


## The first road sample from `from_i` on where the next `ahead` samples drop
## at least `drop` m: the top of a slope to roll the van down (a push start).
func downhill_index(path: Route, from_i: int, ahead: int, drop: float) -> int:
	for i in range(from_i, path.point_count() - ahead - 1):
		if path.point(i).y - path.point(i + ahead).y >= drop:
			return i
	return -1


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
	# the live control line: no scenarios, wait for commands (tools/live.py)
	if only == "live":
		await LiveControl.new(self).run()
		return

	# After a load test reloaded the scene, only finish that check.
	if PlayTest.resume != "":
		var r := PlayTest.resume
		PlayTest.resume = ""
		_failures = PlayTest.carried_failures.duplicate()
		log_line("---- %s (after scene reload) ----" % r)
		var resumed_at := Time.get_ticks_msec()
		await call("t_" + r)
		log_line("time %s %.1f s (after reload)" % [r, (Time.get_ticks_msec() - resumed_at) / 1000.0])
		_record_done(PlayTest.reloading_scenario, PlayTest.scenario_fail_start)
		_finish()
		return
	_read_progress()
	var all := ["audio", "fixes", "dev", "mirrors", "feedback", "map", "story", "windmill", "waterworks", "power", "bridge", "ghat", "ghat_menu", "tower", "maze", "relay", "relay_kb", "overview", "tour", "climb", "carry", "journey", "mouse", "foot", "taps", "enter", "cockpit", "layout", "park", "solid", "crash", "look", "pad", "drive", "brake", "lap", "exit", "swap", "perf", "beach", "photo", "roses", "evidence", "bessi_jumps", "shutter", "boat", "storm", "storm_road", "decoy", "saltpans", "swing", "tunnel", "mast", "home", "step_jumps", "save"]
	if boot.gym != "":
		all = GYM_SCENARIOS.get(boot.gym, ["gym"]).duplicate()
	var selection := only
	if selection == "smoke":
		all = SMOKE_GYM.duplicate() if boot.gym != "" else SMOKE_WORLD.duplicate()
		selection = ""
	elif selection == "quick" or selection == "gym_quick":
		if GYM_SCENARIOS.has(boot.gym):
			all = GYM_SCENARIOS[boot.gym].duplicate()
		else:
			all = QUICK_GYM.duplicate() if boot.gym != "" else QUICK_WORLD.duplicate()
		selection = ""
	elif selection == "full":
		if boot.gym != "":
			all = GYM_SCENARIOS.get(boot.gym, QUICK_GYM).duplicate()
		else:
			all.insert(all.find("save"), "routes")
			# the world checks that were only in the old Quick list
			for extra in ["roadworks", "house_world", "traffic_world", "mood", "driveway"]:
				if not extra in all:
					all.insert(all.find("save"), extra)
			all.insert(all.find("save"), "way_out")
			all.insert(all.find("save"), "teleports")
		selection = ""
	# Scenarios outside a preset can still run by name.
	if selection != "":
		for extra in selection.split(","):
			if not extra in all and has_method("t_" + extra):
				all.append(extra)
	for s in all:
		if selection != "" and not s in selection.split(","):
			continue
		if _done.has(s):
			log_line("---- %s: done in the earlier run, skipped (%d failure(s) then) ----" % [s, _done[s].size()])
			for f in _done[s]:
				_failures.append(f + "  (earlier run)")
			continue
		log_line("---- %s ----" % s)
		# a test after the return's tests starts on the way out: the storm,
		# the blown bridge, the cut power, creatures after Naresh, him at home
		# put away (the full run's old tests inherited all of it, 2026-10-01)
		if boot.gym == "" and not s in RETURN_SCENARIOS and boot.story != null and boot.story.flags.has("storm_on"):
			_undo_return()
		# memory as the run goes on: the long runs have crashed in the graphics
		# driver after 35+ minutes; a steady climb here would say why
		log_line("mem: video %d MB, textures %d MB, static %d MB, objects %d" % [
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0),
			int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
			int(Performance.get_monitor(Performance.OBJECT_COUNT))])
		var started_at := Time.get_ticks_msec()
		PlayTest.reloading_scenario = s
		PlayTest.scenario_fail_start = _failures.size()
		release_all()
		await fresh_hands()
		if s.begins_with("opening"):
			await _p2_on_keyboard()
		await call("t_" + s)
		release_all()
		await _unplug_test_pad()
		log_line("time %s %.1f s" % [s, (Time.get_ticks_msec() - started_at) / 1000.0])
		if PlayTest.resume != "":
			return      # the scene is reloading; the new test node finishes up
		_record_done(s, PlayTest.scenario_fail_start)
	_finish()


func _segment_key() -> String:
	return "%s|%s" % [boot.gym, only]


## What an earlier, broken-off run of this segment already finished.
func _read_progress() -> void:
	if progress_path == "" or not FileAccess.file_exists(progress_path):
		return
	var key := _segment_key()
	var fails := {}              # a scenario's failures count only once its "done" line follows
	for line in FileAccess.get_file_as_string(progress_path).split("\n", false):
		var f := line.split("\t")
		if f.size() < 3 or f[1] != key:
			continue
		if f[0] == "fail" and f.size() >= 4:
			if not fails.has(f[2]):
				fails[f[2]] = []
			fails[f[2]].append(f[3])
		elif f[0] == "done":
			_done[f[2]] = fails.get(f[2], [])
			fails.erase(f[2])
	if not _done.is_empty():
		log_line("resuming: %d scenario(s) of this segment already done" % _done.size())


## Write a finished scenario (and the failures it added) to the progress file.
## Failures first, then "done", in one write: a crash before it leaves the
## scenario unfinished, so the resumed run plays it again.
func _record_done(s: String, fail_from: int) -> void:
	if progress_path == "":
		return
	var fa := FileAccess.open(progress_path, FileAccess.READ_WRITE) if FileAccess.file_exists(progress_path) else FileAccess.open(progress_path, FileAccess.WRITE)
	if fa == null:
		log_line("could not write the progress file %s" % progress_path)
		return
	fa.seek_end()
	var key := _segment_key()
	var text := ""
	for i in range(fail_from, _failures.size()):
		text += "fail\t%s\t%s\t%s\n" % [key, s, _failures[i].replace("\t", " ").replace("\n", " ")]
	text += "done\t%s\t%s\n" % [key, s]
	fa.store_string(text)
	fa.close()


## The opening's scenarios play P2 with the keyboard (TAB); with a real pad
## plugged in, P2 would be on it and TAB leaves the keyboard with P1. Put P2
## on the keyboard, solo view, as with no pad.
func _p2_on_keyboard() -> void:
	if boot.devices.size() < 2 or boot.devices[1].kind == InputDevice.Kind.KBM:
		return
	boot._set_p2_device(InputDevice.keyboard())
	boot._set_layout(Boot.Layout.SOLO)
	await physics_frames(3)


## Scenarios that plug in a pretend pad for P2 leave it plugged in; unplug it
## (and clear the pause that causes) so the next one starts as a real session
## would. A real connected pad is left alone.
func _unplug_test_pad() -> void:
	if not Input.get_connected_joypads().is_empty() or boot.devices.size() < 2:
		return
	if boot.devices[1].kind == InputDevice.Kind.PAD:
		boot._on_joy_changed(boot.devices[1].pad, false)
		await physics_frames(2)
		if boot.paused:
			boot._toggle_pause()
		await physics_frames(2)


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
	# the roses stay sunk until the photo spot is found (E4): stand them up
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	if ro != null:
		ro.rise_now()
		await physics_frames(3)
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
	if ro != null:
		ro.reset()


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
	c.snap_visuals()
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
	camper().repair_all()         # a healthy van, whatever the scenarios before did to it
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
	if not c.engine_on:
		log_line("engine didn't start: battery %.2f fuel %.1f lockout %s tarp %s; note '%s'" % [c.battery, c.fuel, c.heat_lockout, c.attack.tarped, boot.huds[1]._note_text.text if boot.huds.size() > 1 else ""])
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
	c.snap_visuals()
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
	camper().fuel = 26.0          # as a new game: low, so the spare can matters (the dev menu's fix fills it)
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
	check(st.current()["id"] == "windmill", "at the windmill: free the jammed windmill")
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
	st.index = st.index_of("pump_road")
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
	var wm := get_tree().get_first_node_in_group("windmill_brake") as WindmillBrake
	wm.from_dict({"snagged": false, "brake_on": true, "angle": 1.0, "box_open": true, "map_taken": true})
	var lift := get_tree().get_first_node_in_group("lift_bridge") as LiftBridge
	lift.from_dict({"locked": true})
	var maze := get_tree().get_first_node_in_group("barn_maze") as BarnMaze
	var relay := get_tree().get_first_node_in_group("lookout_relay") as LookoutRelay
	maze.from_dict({"chest_open": true, "dust_done": true})
	relay.from_dict({"dials": relay.code.duplicate(), "opened": true})
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
		"valve_a": station().valve_a, "objective": st.current()["id"],
	}
	wm.from_dict({})     # jammed again: loading must free it
	lift.from_dict({})   # up again: loading must bring it down
	maze.from_dict({})
	relay.from_dict({"dials": [0, 0, 0, 0], "opened": false})
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
static var reloading_scenario := ""  ## the scenario running when a load test reloads the scene
static var scenario_fail_start := 0
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
	var wm := get_tree().get_first_node_in_group("windmill_brake") as WindmillBrake
	check(wm != null and not wm.snagged and wm.box_open and wm.map_taken and not wm._rope.visible, "loading restores the freed windmill and the taken map")
	check(st.current()["id"] == e["objective"], "loading restores the objective by its id")
	var lift := get_tree().get_first_node_in_group("lift_bridge") as LiftBridge
	var bars: Array = boot.builder.bridge_barriers.find_children("*", "CollisionShape3D", true, false)
	check(lift != null and lift.locked and lift.angle == 0.0 and bars.all(func(c): return c.disabled), "loading restores the lowered lift bridge, barriers gone")
	var maze := get_tree().get_first_node_in_group("barn_maze") as BarnMaze
	var relay := get_tree().get_first_node_in_group("lookout_relay") as LookoutRelay
	check(maze != null and maze.chest_open and relay != null and relay.opened and relay.dials == relay.code, "loading restores the opened feed chest and supply box")
	var line := get_tree().get_first_node_in_group("power_line") as PowerLine
	check(line != null and line.hut_powered == station().solved and line.powered == station().solved, "loading restores the power line to match the water works (powered: %s)" % station().solved)
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
	# 10: the nav points at your stamp, never at Bessi. The loop this test
	# parks on is in Bessi itself, where the nav has no signal (E2): check it
	# at the windmill junction instead (on the map from the start: driving
	# anywhere new would mark it on the paper map), then come back.
	# (being there would also deliver Naresh's old text at J1: put that back
	# after, for the story test)
	var had_text_j1: bool = boot.story.flags.has("text_j1")
	boot.dev_menu.van_to(boot.dev_menu.van_spot(b.poi["j1"] + Vector3(15, 0, 15)), 0.0)
	await physics_frames(20)
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	boot.map_state.stamps.clear()
	await wait(0.4)
	var nav: Label3D = c._needles["nav_label"]
	log_line("nav with no stamps: '%s'" % nav.text.replace("\n", " / "))
	check(not nav.text.contains("BESSI") and nav.text.contains("stamp"), "without stamps the nav gives nothing away")
	boot.map_state.add_stamp("fuel", Vector2(b.poi["gas_station"].x, b.poi["gas_station"].z))
	await wait(0.4)
	log_line("nav with a fuel stamp: '%s'" % nav.text.replace("\n", " / "))
	check(nav.text.begins_with("FUEL"), "the nav points at the latest map stamp")
	await reset_camper(steep)
	if not had_text_j1:
		boot.story.flags.erase("text_j1")
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


## The developer menu in the game world: F1 opens it (and pauses), the tabs
## and keys, teleport by name, bring the van, skip in the opening, close.
func t_dev() -> void:
	var dm: DevMenu = boot.dev_menu
	await tap(KEY_F1)
	await physics_frames(2)
	check(dm.open and get_tree().paused, "F1 opens the developer menu and pauses the game")
	await shot("dev_menu")
	await tap(KEY_RIGHT)
	check(dm.tab == DevMenu.TABS.find("Story"), "Right goes to the next tab")
	await tap(KEY_LEFT)
	check(dm.tab == DevMenu.TABS.find("Travel"), "Left goes back")
	await tap(KEY_B)
	var row: Dictionary = dm._rows[dm._sel[dm.tab]]
	log_line("B jumps to: '%s'" % row["text"])
	check(String(row["text"]).to_lower().begins_with("b"), "a letter jumps to the next place starting with it")
	dm.select_place("dock")
	await tap(KEY_ENTER)
	await physics_frames(5)
	var dock: Vector3 = boot.builder.poi["dock"]
	var d := Vector2(p1().global_position.x - dock.x, p1().global_position.z - dock.z).length()
	log_line("teleported to the dock: %.1f m away" % d)
	check(d < 12.0 and p1().is_on_floor(), "the menu teleports both players to a named place (next to it, on their feet)")
	# save slots are labelled by the nearest place, the new map's included
	var here := SaveGame.nearest_place(boot, p1().global_position)
	var p2h := SaveGame.nearest_place(boot, boot.builder.poi["p2_home"])
	var nowhere := SaveGame.nearest_place(boot, Vector3(-1900, 0, -1900))
	log_line("save labels: dock '%s', P2's home '%s', far corner '%s'" % [here, p2h, nowhere])
	check(here == "Mirror Lake" and p2h == "P2's house" and nowhere == "on the road", "save slots name the place you saved at")
	dm.set_tab(DevMenu.TABS.find("Van"))
	dm.select_action("van_here")
	await tap(KEY_ENTER)
	await physics_frames(10)
	var vd := camper().global_position.distance_to(p1().global_position)
	log_line("van brought: %.1f m from P1" % vd)
	check(vd < 26.0 and camper().parking_brake, "the menu brings the van, handbrake on (on the nearest clear ground)")
	# skip: during the opening it skips the rest of the opening (it used to
	# only move the chain on underneath, so the opening's step never changed)
	var st: Story = boot.story
	var story_was := st.to_dict()
	var map_was: Dictionary = boot.map_state.to_dict()
	st.begin_opening()
	dm.set_tab(DevMenu.TABS.find("Story"))
	await physics_frames(2)
	log_line("in the opening: '%s'" % st.objective_text(0))
	dm.select_action("skip")
	await tap(KEY_ENTER)
	await physics_frames(3)
	log_line("after skip: '%s' (opening %s)" % [st.objective_text(0), st.opening_mode])
	check(not st.opening_mode and st.current()["id"] == "to_windmill", "skip during the opening ends it: next, drive to the windmill")
	dm.select_action("skip")
	await tap(KEY_ENTER)
	await physics_frames(3)
	check(st.current()["id"] == "windmill" and st.objective_text(0).contains("jammed"), "skip again: the windmill is jammed")
	# jump straight to an objective from the list
	for i in dm._rows.size():
		if dm._rows[i]["action"] == "jump" and dm._rows[i]["arg"] == st.index_of("to_bridge"):
			dm._select(i, true)
	await tap(KEY_ENTER)
	await physics_frames(3)
	check(st.current()["id"] == "to_bridge", "pick any objective in the Story tab and jump to it")
	st.from_dict(story_was)
	boot.map_state.from_dict(map_was)
	await tap(KEY_F1)
	await physics_frames(2)
	check(not dm.open and not get_tree().paused, "F1 closes it again and the game carries on")
	await place_player(p1(), boot.builder.player_spawns[0].origin, 0.0)


## Every place in the developer menu's Travel list: both players land standing
## on something (a floor, a deck, the ground), not inside a building or under
## the map. (The barn used to drop you under the map.)
func t_teleports() -> void:
	var dm: DevMenu = boot.dev_menu
	var st: Story = boot.story
	var story_was := st.to_dict()
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var mood_was := mood.value
	var keys: Array = []
	for sec in DevMenu.PLACES:
		for e in sec[1]:
			if boot.builder.poi.has(e[0]):
				keys.append(e[0])
	var bad: Array = []
	for key in keys:
		dm.teleport_to(key)
		await wait(0.7)
		var at: Vector3 = boot.builder.poi[key]
		for p in boot.players:
			var pp: Vector3 = (p as Node3D).global_position
			var ok: bool = (p as PlayerRig).is_on_floor() and pp.y > Landscape.ground(pp.x, pp.z) - 0.5 and Vector2(pp.x - at.x, pp.z - at.z).length() < 35.0
			if not ok:
				log_line("  %s: search %s" % [key, str(dm.last_search)])
				bad.append("%s (P%d at %s, ground %.1f)" % [key, (p as PlayerRig).index + 1, pp, Landscape.ground(pp.x, pp.z)])
	log_line("teleported to %d places; bad: %s" % [keys.size(), str(bad)])
	check(bad.is_empty(), "every Travel place puts both players on their feet (%d places)" % keys.size())
	# leave the session as it was: the story, the mood, the watchtower's creature
	st.from_dict(story_was)
	mood.set_now(mood_was)
	var cw := get_tree().get_first_node_in_group("coast_watch") as CoastWatch
	if cw != null and cw.creature != null:
		cw.creature.queue_free()
		cw.creature = null
	for tk in get_tree().get_nodes_in_group("taken"):
		(tk as Taken).cancel()
	await place_player(p1(), boot.builder.player_spawns[0].origin, 0.0)
	await place_player(p2(), boot.builder.player_spawns[0].origin + Vector3(2, 0, 0), 0.0)


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
	c.snap_visuals()
	await physics_frames(8)
	check(not c.tyre_flat, "unarmed roadworks leave an older route run alone")
	# what the driver sees coming up to the spill
	c.global_transform = Transform3D(basis, lane.point(505) + Vector3.UP * 0.8)
	c.snap_visuals()
	await seat_p1_driver()
	await wait(0.6)
	await shot("roadworks_approach")
	p1().force_exit = true
	await physics_frames(3)
	c.global_transform = Transform3D(basis, lane.point(510) + Vector3.UP * 0.8)
	c.snap_visuals()
	await physics_frames(8)
	flags["opening_puncture_armed"] = true
	c.global_transform = Transform3D(basis, lane.point(520) + Vector3.UP * 0.8)
	c.snap_visuals()
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
	c.snap_visuals()
	await physics_frames(8)
	c.global_transform = Transform3D(basis, lane.point(520) + Vector3.UP * 0.8)
	c.snap_visuals()
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
	# after the long drives it may be on the van's rack: back to the ground first
	can = await reset_can("station_can_empty", 0.0)
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


func mouse_button(b: MouseButton, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)


## Tagging gym: every way to tag, what both players see, reach, fade, follow.
func t_tagging() -> void:
	var b := boot.builder as GymBuilder
	check(b != null and boot.gym == "tagging" and boot.world.get_node_or_null("TagBoard150") != null,
		"the tagging gym has boards out to 150 m and one past the reach")
	if b == null:
		return
	# P2 on a controller, split screen side by side: tags must show on both halves
	boot._on_joy_changed(0, true)
	await wait(0.3)
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	var lane := GymBuilder.TAG_LANE
	await place_player(p2(), lane + Vector3(3, 0.25, 0), 0.0)
	# P1 tags each board with T from the lane
	for spec in GymBuilder.TAG_BOARDS:
		var d := int(spec[0])
		var board: Vector3 = b.poi["tag_board_%d" % d]
		var a := deg_to_rad(float(spec[1]))
		await face_point(p1(), board, float(d), Vector3(-sin(a), 0, cos(a)))
		var before := TagMarker.of(0)
		await tap(KEY_T)
		await physics_frames(2)
		var m := TagMarker.of(0)
		if d > TagMarker.RANGE:
			check(m == before, "a board at %d m is out of reach: no tag" % d)
			continue
		var ok := m != null and m.global_position.distance_to(board) < 1.2 and m.thing == "board %d m" % d
		log_line("tag at %d m: %s" % [d, ("%s at %.2f m from the board centre" % [m.thing, m.global_position.distance_to(board)]) if m != null else "none"])
		check(ok, "T tags the board at %d m and names it" % d)
		if d == 25 or d == 150:
			await wait(0.4)
			await shot("tag_%dm" % d)
	check(boot.world.find_children("Tag1", "", true, false).size() == 1, "one tag per player: a new tag replaces the old")
	# middle mouse works too
	var board10: Vector3 = b.poi["tag_board_10"]
	await face_point(p1(), board10, 10.0, Vector3(sin(deg_to_rad(30.0)), 0, cos(deg_to_rad(30.0))))
	mouse_button(MOUSE_BUTTON_MIDDLE, true)
	await wait(0.07)
	mouse_button(MOUSE_BUTTON_MIDDLE, false)
	await physics_frames(3)
	var m1 := TagMarker.of(0)
	check(m1 != null and m1.thing == "board 10 m", "the middle mouse button tags")
	if m1 != null:
		# what each viewer reads: the same name, their own distance
		await wait(0.1)
		var l1 := m1.get_node("Label1") as Label3D
		var l2 := m1.get_node("Label2") as Label3D
		log_line("P1 reads '%s', P2 reads '%s'" % [l1.text, l2.text])
		check(l1.text.begins_with("P1: board 10 m") and l2.text.begins_with("P1: board 10 m") and l1.text != l2.text,
			"both players read the tag, each with their own distance")
		check(l1.layers & boot.viewports[0].get_camera_3d().cull_mask != 0 and l1.layers & boot.viewports[1].get_camera_3d().cull_mask == 0,
			"P1's distance label is drawn only in P1's view")
	# P2 tags the crate with the pad's right trigger; the tag follows it
	var crate := boot.world.get_node("TagCrate") as RigidBody3D
	await face_point(p2(), crate.global_position + Vector3.UP * 0.2, 5.0, Vector3(1, 0, 0.2))
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await physics_frames(3)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await physics_frames(2)
	var m2 := TagMarker.of(1)
	log_line("P2's tag: %s" % (m2.thing if m2 != null else "none"))
	check(m2 != null and m2.target == crate, "P2's right trigger tags the crate")
	if m2 != null:
		var off := m2.global_position - crate.global_position
		crate.global_position += Vector3(0, 0, -3)
		crate.reset_physics_interpolation()
		await physics_frames(3)
		check((m2.global_position - crate.global_position).distance_to(off) < 0.3, "a tag follows the thing it is on")
	await wait(0.2)
	await shot("tag_split")
	# P2 turns away from P1's tag: an arrow at the edge of P2's view points back
	var hud2: PlayerHUD = boot.huds[1]
	await place_player(p2(), lane + Vector3(3, 0.25, 0), PI)   # facing +Z, the boards behind
	await wait(0.2)
	check(hud2.tag_arrow_at.has(0), "a tag behind you gets an arrow at the edge of the view")
	await shot("tag_arrow")
	var seen := TagMarker.of(0).global_position - (lane + Vector3(3, 0, 0))
	await place_player(p2(), lane + Vector3(3, 0.25, 0), atan2(-seen.x, -seen.z))
	await wait(0.2)
	check(not hud2.tag_arrow_at.has(0), "no arrow while the tag is in view")
	# the driver cannot tag (the pad's RT is the throttle); the passenger can
	var c := camper()
	c.parking_brake = true
	c.global_transform = Transform3D(Basis(), lane + Vector3(-6, 0.8, -4))
	c.snap_visuals()
	await wait(1.0)
	p1().enter_seat(c, c.seat_nodes["driver"], "driver")
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await wait(0.3)
	var before_drv := TagMarker.of(0)
	await tap(KEY_T)
	check(TagMarker.of(0) == before_drv, "the driver's T does not tag")
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await physics_frames(3)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await physics_frames(2)
	var mp := TagMarker.of(1)
	log_line("passenger's tag: %s, %.1f m from the van" % [mp.thing, mp.global_position.distance_to(c.global_position)] if mp != null else "passenger's tag: none")
	check(mp != null and mp != m2 and mp.thing != "that" and mp.global_position.distance_to(c.global_position) > 4.0,
		"the passenger tags from the seat, past the van itself")
	p1().force_exit = true
	p2().force_exit = true
	await physics_frames(3)
	# fading: tags last TagMarker.LIFE seconds
	var mf := TagMarker.of(0)
	check(mf != null, "P1's tag is still there")
	if mf != null:
		mf.age = TagMarker.LIFE - TagMarker.FADE * 0.5
		await wait(0.1)
		check((mf.get_node("Icon") as Sprite3D).modulate.a < 0.7, "a tag fades out at the end of its life")
		await wait(TagMarker.FADE)
		check(TagMarker.of(0) == null, "and is gone after %d s" % int(TagMarker.LIFE))


## The tan-ratio between a zoomed and an unzoomed vertical field of view.
func fov_ratio(zoomed_deg: float, base_deg: float) -> float:
	return tan(deg_to_rad(base_deg) * 0.5) / tan(deg_to_rad(zoomed_deg) * 0.5)


## Binocular gym: take them, zoom 4x, read signs, tag through them.
func t_binoculars() -> void:
	var b := boot.builder as GymBuilder
	check(b != null and boot.gym == "binoculars" and boot.world.get_node_or_null("BinoSign400") != null,
		"the binocular gym has reading signs out to 400 m")
	if b == null:
		return
	var p := p1()
	check(not p.has_binoculars, "nobody starts with binoculars")
	# without binoculars the right mouse button does nothing
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.4)
	check(p.zoom == 1.0, "no binoculars, no zoom")
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	# take them off the table
	await face_point(p, b.poi["gym_binoculars"], 1.4, Vector3(0.3, 0, 1))
	# the first second after the gym loads can crawl (shaders compiling)
	var t_wait := Time.get_ticks_msec()
	while p.prompt_text == "" and Time.get_ticks_msec() - t_wait < 2000:
		await physics_frames(2)
	log_line("prompt at the table: '%s'" % p.prompt_text)
	await tap(KEY_E)
	await physics_frames(3)
	check(p.has_binoculars and boot.world.get_node_or_null("GymBinoculars") == null, "E takes the binoculars off the table")
	# read each sign, without and with the zoom
	var lane := GymBuilder.TAG_LANE
	for spec in GymBuilder.BINO_SIGNS:
		var d := int(spec[0])
		var sign_at: Vector3 = b.poi["bino_sign_%d" % d]
		var a := deg_to_rad(float(spec[1]))
		await face_point(p, sign_at, float(d), Vector3(-sin(a), 0, cos(a)))
		await wait(0.3)
		if d == 100 or d == 300:
			await shot("bino_%dm_eye" % d)
		mouse_button(MOUSE_BUTTON_RIGHT, true)
		await wait(0.6)
		if d == 50:
			log_line("zoomed: fov %.1f (base %.1f), zoom %.2f" % [p.cam.fov, p.base_fov, p.zoom])
			check(absf(fov_ratio(p.cam.fov, p.base_fov) - PlayerRig.BINOCULAR_ZOOM) < 0.05, "holding the right mouse button zooms 4x")
			check((boot.huds[0] as PlayerHUD).binoculars.visible, "the view goes round, like binoculars")
		await shot("bino_%dm_zoom" % d)
		# tag through them: 300 m and 400 m are past the naked-eye reach
		if d >= 300:
			await tap(KEY_T)
			await physics_frames(2)
			var m := TagMarker.of(0)
			check(m != null and m.thing == "sign %d m" % d, "tagging through the binoculars reaches %d m" % d)
		mouse_button(MOUSE_BUTTON_RIGHT, false)
		await wait(0.5)
	check(p.zoom == 1.0 and absf(p.cam.fov - p.base_fov) < 0.1, "letting go lowers them")
	# naked eye at 300 m: out of reach
	var s300: Vector3 = b.poi["bino_sign_300"]
	await face_point(p, s300, 300.0, Vector3(-sin(deg_to_rad(8.0)), 0, cos(deg_to_rad(8.0))))
	TagMarker.of(0).queue_free()
	await physics_frames(2)
	await tap(KEY_T)
	await physics_frames(2)
	check(TagMarker.of(0) == null, "without the zoom a 300 m sign is out of tag reach")
	# looking around zoomed is 4x finer, so the view moves the same on screen
	await place_player(p, lane + Vector3(-1, 0.25, 0), 0.0)
	var y0 := p.yaw
	mouse(Vector2(200, 0))
	await wait(0.2)
	var free_turn := absf(wrapf(p.yaw - y0, -PI, PI))
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.6)
	y0 = p.yaw
	mouse(Vector2(200, 0))
	await wait(0.2)
	var zoom_turn := absf(wrapf(p.yaw - y0, -PI, PI))
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	await wait(0.5)
	log_line("200 px of mouse: %.2f deg free, %.2f deg zoomed" % [rad_to_deg(free_turn), rad_to_deg(zoom_turn)])
	check(zoom_turn > 0.0 and absf(free_turn / zoom_turn - PlayerRig.BINOCULAR_ZOOM) < 0.3, "zoomed look is 4x finer")
	# hands full: no binoculars
	var crate := Crate.new()
	crate.name = "BinoCrate"
	boot.world.add_child(crate)
	crate.global_position = p.global_position + Vector3(0, 1.0, -1.2)
	await physics_frames(2)
	p.pick_up(crate)
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.4)
	check(p.zoom == 1.0, "not with your hands full")
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	p.drop_held()
	# P2 on the pad: LT zooms once they have a pair; the driver cannot
	boot._on_joy_changed(0, true)
	await wait(0.3)
	var q := p2()
	q.has_binoculars = true
	await place_player(q, lane + Vector3(1, 0.25, 0), 0.0)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await wait(0.6)
	check(absf(q.zoom - PlayerRig.BINOCULAR_ZOOM) < 0.05, "P2's left trigger zooms")
	check(p.zoom == 1.0, "and only P2's view")
	await shot("bino_split")
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await wait(0.5)
	var c := camper()
	c.parking_brake = true
	c.global_transform = Transform3D(Basis(), lane + Vector3(-6, 0.8, -4))
	c.snap_visuals()
	await wait(1.0)
	q.enter_seat(c, c.seat_nodes["driver"], "driver")
	await wait(0.2)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await wait(0.5)
	check(q.zoom == 1.0, "the driver's LT is the brake, not the binoculars")
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await wait(0.2)
	q.force_exit = true
	await physics_frames(3)


## Hold the creature still, facing +Z, calm, forgetting everything.
func calm_creature(cr: Creature, at: Vector3, facing := PI) -> void:
	cr.patrol = PackedVector3Array()
	cr.global_position = at
	cr.rotation.y = facing
	cr.velocity = Vector3.ZERO
	cr.suspicion = 0.0
	cr.state = Creature.State.WANDER
	cr.target = null
	cr.last_noticed = at
	cr.van_interest = 0.0
	cr._heard_id = Hearing.last_id()
	cr.reset_physics_interpolation()
	for tk in get_tree().get_nodes_in_group("taken"):
		(tk as Taken).cancel()
	for pl in boot.players:
		pl.taken_grace = 0.0
	await physics_frames(2)


## Put a player somewhere and keep them still for a while; the most the
## creature's suspicion reached.
func exposed(p: PlayerRig, at: Vector3, seconds: float, crouch := false, cr: Creature = null) -> float:
	if crouch:
		key(KEY_CTRL, true)
		await physics_frames(20)     # already down when you arrive
	await place_player(p, at, 0.0)
	if cr != null:
		# whatever it glimpsed while you were being moved does not count
		cr.suspicion = 0.0
		cr._noticed_t = 99.0
		cr._heard_id = Hearing.last_id()
	var top := 0.0
	for _i in int(seconds * 10.0):
		await wait(0.1)
		if cr != null:
			top = maxf(top, cr.suspicion)
	if crouch:
		key(KEY_CTRL, false)
		await physics_frames(3)
	return top


## Stealth gym: what a creature sees and hears, the chase and giving up.
func t_stealth() -> void:
	var b := boot.builder as GymBuilder
	var cr := boot.world.get_node_or_null("GymCreature") as Creature
	check(b != null and cr != null and boot.gym == "stealth", "the stealth gym has a creature and cover")
	if cr == null:
		return
	var eye := GymBuilder.STEALTH_EYE
	var took := []
	cr.took.connect(func(pl): took.append(pl))
	await wait(3.0)
	check(cr.global_position.distance_to(eye) > 2.0, "left alone it wanders its patrol")
	await shot("stealth_creature")
	var p := p1()
	await place_player(p2(), eye + Vector3(-20, 0.25, 60), 0.0)   # out of the way
	# sight by distance, standing and crouched, in the open, day
	var cases := [[30.0, false, true], [40.0, false, false], [25.0, true, false], [14.0, true, true]]
	for c in cases:
		await calm_creature(cr, eye)
		var top := await exposed(p, eye + Vector3(-4, 0.25, float(c[0])), 3.0, bool(c[1]), cr)
		log_line("%s at %d m in the open: suspicion reached %.2f" % ["crouched" if c[1] else "standing", int(c[0]), top])
		check((top > 0.3) == bool(c[2]), "%s at %d m in the open is %s" % ["crouched" if c[1] else "standing", int(c[0]), "seen" if c[2] else "not seen"])
	# behind cover
	await calm_creature(cr, eye)
	var top_w := await exposed(p, b.poi["cover_wall"] + Vector3(0, 0.25, 1.2), 3.0, false, cr)
	check(top_w < 0.05, "standing behind the wall at 13 m: not seen (%.2f)" % top_w)
	await calm_creature(cr, eye)
	var top_r := await exposed(p, b.poi["cover_rock"] + Vector3(0, 0.25, 1.4), 3.0, true, cr)
	check(top_r < 0.05, "crouched behind the rock at 13 m: not seen (%.2f)" % top_r)
	await calm_creature(cr, eye)
	var top_r2 := await exposed(p, b.poi["cover_rock"] + Vector3(0, 0.25, 1.4), 2.0, false, cr)
	check(top_r2 > 0.3, "standing up behind the rock: seen (%.2f)" % top_r2)
	# out of its field of view, and close behind it
	await calm_creature(cr, eye)
	var top_side := await exposed(p, eye + Vector3(12, 0.25, -2), 2.0, false, cr)
	check(top_side < 0.05, "standing 12 m off to its side: not seen (%.2f)" % top_side)
	await calm_creature(cr, eye)
	var top_close := await exposed(p, eye + Vector3(0.5, 0.25, -2.5), 1.5, false, cr)
	check(top_close > 0.1, "right behind it, it notices you (%.2f)" % top_close)
	# hearing, from behind (out of sight): sprint 18 m, walk 8 m, crouch 2 m
	var sounds := [["sprinting", 14.0, true], ["walking", 12.0, false], ["walking", 6.0, true], ["crouch-walking", 4.0, false]]
	for s in sounds:
		await calm_creature(cr, eye)
		var start := eye + Vector3(-6, 0.25, -float(s[1]))
		await place_player(p, start, -PI * 0.5)       # facing +X, walking across behind it
		if s[0] == "crouch-walking":
			key(KEY_CTRL, true)
		if s[0] == "sprinting":
			key(KEY_SHIFT, true)
		key(KEY_W, true)
		var heard := 0.0
		for _i in 20:
			await wait(0.1)
			heard = maxf(heard, cr.suspicion)
		release_all()
		await physics_frames(3)
		log_line("%s %d m behind it: suspicion %.2f" % [s[0], int(s[1]), heard])
		check((heard >= Creature.SOUND_STEP - 0.01) == bool(s[2]), "%s %d m behind it is %s" % [s[0], int(s[1]), "heard" if s[2] else "not heard"])
	# a heard sound turns it to look
	await calm_creature(cr, eye)
	Hearing.emit(eye + Vector3(10, 0, 0), 15.0, "test")
	await wait(1.5)
	var f := -cr.global_transform.basis.z
	log_line("a sound 10 m to its right: facing %s, moved %.1f m" % [f, cr.global_position.distance_to(eye)])
	check(f.dot(Vector3(1, 0, 0)) > 0.7, "it turns to look at a sound it heard")
	# the chase: seen in the open, it comes for you and takes you
	await calm_creature(cr, eye)
	took.clear()
	await place_player(p, eye + Vector3(-5, 0.25, 8), 0.0)
	var t0 := Time.get_ticks_msec()
	while took.is_empty() and Time.get_ticks_msec() - t0 < 8000:
		await wait(0.1)
	log_line("standing still in view at 9 m: taken after %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	check(took.size() == 1 and took[0] == p, "stand in the open and it takes you")
	await shot("stealth_taken")
	# break line of sight during the chase: it gives up after 10 s
	await calm_creature(cr, eye)
	took.clear()
	await place_player(p, eye + Vector3(-5, 0.25, 8), 0.0)
	t0 = Time.get_ticks_msec()
	while cr.state != Creature.State.TAKE and Time.get_ticks_msec() - t0 < 6000:
		await wait(0.1)
	check(cr.state == Creature.State.TAKE, "it comes for you once it is sure")
	# slip away out of its sight and stay crouched
	await place_player(p, eye + Vector3(-10, 0.25, 70), 0.0)
	key(KEY_CTRL, true)
	var gave_up := false
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 13000 and took.is_empty():
		await wait(0.2)
		if cr.state != Creature.State.TAKE:
			gave_up = true
			break
	key(KEY_CTRL, false)
	log_line("out of sight: gave up after %.1f s, taken %s" % [(Time.get_ticks_msec() - t0) / 1000.0, not took.is_empty()])
	check(gave_up and took.is_empty(), "out of sight and quiet, it gives up the chase")
	await calm_creature(cr, eye)


## Being taken: white, a drop point, the partner's trail, texts, grace; both
## taken = both at the van with a leak.
func t_taken() -> void:
	var b := boot.builder as GymBuilder
	var cr := boot.world.get_node_or_null("GymCreature") as Creature
	if cr == null:
		check(false, "the stealth gym has a creature")
		return
	var eye := GymBuilder.STEALTH_EYE
	var p := p1()
	var q := p2()
	var story := get_tree().get_first_node_in_group("story") as Story
	var texts0 := [story.phone_threads[0].size(), story.phone_threads[1].size()]
	await calm_creature(cr, eye)
	boot._on_joy_changed(0, true)
	await wait(0.3)
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	await place_player(q, eye + Vector3(-8, 0.25, 40), 0.0)     # P2 watches from 40 m
	var start := eye + Vector3(-5, 0.25, 8)
	await place_player(p, start, 0.0)
	var white := 0.0
	var frozen := false
	var t0 := Time.get_ticks_msec()
	var tk: Taken = null
	while Time.get_ticks_msec() - t0 < 9000:
		await physics_frames(1)
		if tk == null:
			tk = boot.world.get_node_or_null("Taken1") as Taken
			if tk != null:
				# P1 tries to run: the input is ignored while taken
				key(KEY_W, true)
		white = maxf(white, p.whiteout)
		if p.taken_hold > 0.0 and planar_speed(p) < 0.05:
			frozen = true
		if tk != null and p.whiteout == 0.0 and p.taken_hold <= 0.0 and white > 0.9:
			break
	key(KEY_W, false)
	check(tk != null, "the creature takes P1")
	if tk == null:
		return
	var moved := p.global_position.distance_to(start)
	log_line("taken: woke %.0f m away by %s; white reached %.2f" % [moved, tk.near, white])
	check(white > 0.95 and frozen, "P1's view goes white and P1 cannot move meanwhile")
	check(moved >= Taken.DROP_MIN - 5.0 and moved <= Taken.DROP_MAX + 5.0 and tk.near == "the south post",
		"P1 wakes at a drop point 150-400 m away, by a landmark")
	check(boot.world.find_child("Trail", true, false) != null, "P2 sees a smoke trail drift off P1's way")
	await shot("taken_trail")
	await wait(0.5)
	check(story.phone_threads[0].size() > texts0[0] and story.phone_threads[1].size() > texts0[1]
		and String(story.phone_threads[1].back()["body"]).contains("south post"), "both get a text; P2's says where P1 is")
	check(p.taken_grace > 100.0, "P1 cannot be taken again for 2 minutes")
	await shot("taken_wake")
	# in grace: stand right in front of it and it ignores you
	await calm_creature(cr, eye)
	p.taken_grace = 60.0
	await place_player(p, eye + Vector3(-3, 0.25, 6), 0.0)
	await wait(3.0)
	check(boot.world.get_node_or_null("Taken1") == null and cr.state != Creature.State.TAKE, "during the grace time it cannot take you")
	# both taken: P2 is out on their own when P1 goes too -> both at the van, leaking
	var c := camper()
	c.fuel_leak = 0.0
	c.parking_brake = true
	await calm_creature(cr, eye)
	q.taken_grace = 90.0          # P2 was taken a moment ago
	await place_player(q, eye + Vector3(40, 0.25, 90), 0.0)
	await place_player(p, start, 0.0)
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 9000 and boot.world.get_node_or_null("Taken1") == null:
		await wait(0.1)
	await wait(Taken.WHITE_IN + Taken.WHITE_HOLD + 0.3)
	var vd := p.global_position.distance_to(c.global_position)
	var qd := q.global_position.distance_to(c.global_position)
	log_line("both taken: P1 %.1f m and P2 %.1f m from the van, leak %.1f L/min" % [vd, qd, c.fuel_leak])
	check(vd < 4.0 and qd < 4.0 and c.fuel_leak > 0.0, "both taken: both wake at the van, and it is leaking fuel")
	var f0 := c.fuel
	await wait(3.0)
	check(c.fuel < f0, "the leak drains the tank")
	c.fuel_leak = 0.0
	for pl in boot.players:
		pl.taken_grace = 0.0


## W1, the windmill brake, with the real controls. P1 climbs the ladder and
## tags the snagged blade from the platform; P2 at the lever lets the brake
## off and puts it back on when the tagged blade comes down to the platform;
## P1 cuts the rope; P2 lets the brake off; the box opens; P2 takes the map.
func t_windmill() -> void:
	var b: LevelBuilder = boot.builder
	var wm := boot.world.find_child("WindmillBrake", true, false) as WindmillBrake
	var lad := boot.world.find_child("WindmillLadder", true, false) as Ladder
	check(wm != null and lad != null and wm.snagged and wm.brake_on, "the windmill is jammed: a rope round one blade, the brake on")
	if wm == null or lad == null:
		return
	var p := p1()
	var q := p2()
	var st: Story = boot.story
	boot._on_joy_changed(0, true)      # P2 on a pad
	await wait(0.3)
	# P1: walk to the ladder, climb it (hold W), step off at the top
	await place_player(p, lad.global_transform * Vector3(0, 0.3, 1.6), lad.climb_yaw())
	await look_at_point(p, lad.global_transform * Vector3(0, 1.6, 0))
	await wait(0.2)
	log_line("at the ladder's foot: '%s', looking at %s" % [p.prompt_text, p.current_target.name if p.current_target else "nothing"])
	await tap(KEY_E)
	check(p.ladder == lad, "E at the ladder: you are on it")
	key(KEY_W, true)
	var t0 := Time.get_ticks_msec()
	while p.ladder != null and Time.get_ticks_msec() - t0 < 12000:
		await physics_frames(1)
	key(KEY_W, false)
	var up := (Time.get_ticks_msec() - t0) / 1000.0
	await wait(0.4)
	var plat: Vector3 = b.poi["windmill_platform"]
	log_line("climbed in %.1f s; on the platform at %s (%.1f m up)" % [up, p.global_position, p.global_position.y - b.poi["windmill"].y])
	check(p.ladder == null and p.global_position.distance_to(plat) < 1.5 and p.is_on_floor(), "hold W: up the ladder and off onto the platform")
	# P1 tags the snagged blade (it is up at the side, out of reach)
	var snag_area := _snag_area(wm)
	await look_at_point(p, snag_area.global_position)
	await tap(KEY_T)
	var tag := TagMarker.of(0)
	check(tag != null and tag.thing == "the snagged blade", "from the platform P1 tags the snagged blade")
	await shot("windmill_tag")
	# P1 can't cut it up there
	await look_at_point(p, snag_area.global_position)
	await wait(0.2)
	log_line("looking at the snag, out of reach: '%s'" % p.prompt_text)
	# P2 at the lever: brake off, watch the tag come down, brake on
	await place_player(q, b.poi["windmill_lever"] + Vector3(0.9, 0.3, 0.9), 0.0)
	await look_at_point(q, b.poi["windmill_lever"] + Vector3(0, 1.0, 0))
	await key_pad_interact(q)
	check(not wm.brake_on and wm.speed >= 0.0, "P2 lets the brake off")
	var caught := false
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await physics_frames(1)
		# the lever player sees the tag on screen; they brake when it nears the bottom
		var ahead := wrapf(PI - (wm.angle + TAU * float(WindmillBrake.SNAG) / 12.0), -PI, PI)
		var stop_in := wm.speed * wm.speed / (2.0 * WindmillBrake.BRAKE)
		if wm.speed > 0.05 and ahead > 0.0 and ahead <= stop_in + 0.04:
			await key_pad_interact(q)
			caught = true
			break
	await wait(1.0)
	log_line("braked: the snagged blade stopped %.1f deg from the bottom, speed %.2f" % [wm.snag_from_bottom(), wm.speed])
	check(caught and wm.brake_on and wm.snag_in_reach(), "P2 puts the brake on as the tagged blade reaches the platform")
	# P1 cuts the rope (hold E)
	await look_at_point(p, snag_area.global_position)
	await wait(0.2)
	log_line("P1 looking at the rope: '%s'" % p.prompt_text)
	key(KEY_E, true)
	await wait(WindmillBrake.CUT_S + 0.4)
	key(KEY_E, false)
	check(not wm.snagged, "P1 holds E and cuts the rope")
	await shot("windmill_cut")
	# brake off: it spins up and the box opens
	await key_pad_interact(q)
	t0 = Time.get_ticks_msec()
	while not wm.box_open and Time.get_ticks_msec() - t0 < 12000:
		await wait(0.2)
	check(wm.box_open and wm.speed > WindmillBrake.SPIN * 0.8, "brake off: the blades spin and the miller's box springs open")
	await place_player(q, b.poi["windmill_box"] + Vector3(0, 0.3, -1.5), PI)   # at its front, by the label
	await look_at_point(q, b.poi["windmill_box"] + Vector3(0, 0.5, 0))
	await wait(0.6)
	log_line("lid at %.0f deg" % rad_to_deg(wm._lid.rotation.x))
	await shot("windmill_box_open")
	await key_pad_interact(q)
	var ms = boot.map_state
	var valley_known := false
	for r in ms.roads:
		if r["name"] == "valley_road":
			valley_known = not (r["chunks"] as Array).has(false)
	check(wm.map_taken and valley_known and st.flags.has("windmill_map"), "P2 takes the map: both roads to Last Fuel are on the paper map")
	await shot("windmill_done")
	# climb back down
	await place_player(p, plat, lad.climb_yaw() + PI)
	await look_at_point(p, lad.global_transform * Vector3(0, lad.height + 0.6, 0))   # the rails above the deck
	await wait(0.2)
	log_line("at the top: '%s', looking at %s, ray hits %s" % [p.prompt_text, p.current_target.name if p.current_target else "nothing",
		p.ray.get_collider().name if p.ray.is_colliding() else "nothing"])
	await tap(KEY_E)
	log_line("after E: on the ladder %s" % (p.ladder != null))
	key(KEY_S, true)
	t0 = Time.get_ticks_msec()
	while p.ladder != null and Time.get_ticks_msec() - t0 < 12000:
		await physics_frames(1)
	key(KEY_S, false)
	await wait(0.4)
	check(p.ladder == null and p.global_position.y < b.poi["windmill"].y + 1.0, "E at the top and hold S: back down to the ground")


func _snag_area(wm: WindmillBrake) -> Area3D:
	var h := wm.rotor.get_child(WindmillBrake.SNAG)
	for c in h.get_children():
		if c is Area3D:
			return c
	return null


## P2 presses their interact button (keyboard P1 is busy): the pad X button.
func key_pad_interact(pl: PlayerRig) -> void:
	if pl.dev.kind == InputDevice.Kind.PAD:
		pad_button(JOY_BUTTON_X, true)
		await wait(0.1)
		pad_button(JOY_BUTTON_X, false)
		await wait(0.1)
	else:
		await tap(KEY_E)


## D8: filling the blue tank starts the turbine, the lamps light one by one
## along the road and the bridge's control hut gets power. Then P1 walks up
## the ramp into the hut.
func t_power() -> void:
	var b: LevelBuilder = boot.builder
	var line := get_tree().get_first_node_in_group("power_line") as PowerLine
	var stn := station()
	check(line != null and line.lamps.size() >= 5, "a power line runs from the water works to the bridge hut (%d lamps)" % (line.lamps.size() if line else 0))
	if line == null:
		return
	var was_solved := stn.solved
	stn.solved = false
	line.sync()
	check(not line.powered and not line.hut_powered and line.lamps[0].material_override == null, "before the tank fills: the turbine is still and the lamps are dark")
	var p := p1()
	var q := p2()
	await go_to(p, b.poi["power_line_first"], 7.0)
	await look_at_point(p, b.poi["power_line_last"] + Vector3(0, 6.0, 0))
	await go_to(q, b.poi["turbine"], 9.0)
	await look_at_point(q, b.poi["turbine"] + Vector3(0, 1.2, 0))
	stn.solved = true
	stn.solved_changed.emit()
	await wait(1.2)
	var lit := line.lamps.filter(func(l): return l.material_override != null).size()
	log_line("1.2 s after the tank filled: %d of %d lamps lit, turbine at %.1f rad/s" % [lit, line.lamps.size(), line._spin])
	check(line.powered and lit > 0 and lit < line.lamps.size(), "the tank fills: the turbine starts and the lamps come on one after another")
	await shot("power_wave")
	var t0 := Time.get_ticks_msec()
	while not line.hut_powered and Time.get_ticks_msec() - t0 < 15000:
		await wait(0.2)
	log_line("the hut had power %.1f s after the tank filled" % ((Time.get_ticks_msec() - t0) / 1000.0 + 1.2))
	check(line.hut_powered and line.hut_light.visible and line._hum.target > 0.0, "the wave reaches the bridge hut: its lamp is on and it hums")
	check(line._spin > 2.0, "the turbine wheel is turning")
	await go_to(p, b.poi["turbine"], 8.0, b.poi["facility"] - b.poi["turbine"])
	await look_at_point(p, b.poi["turbine"] + Vector3(0, 1.2, 0))
	await shot("power_turbine")
	await go_to(p, b.poi["power_line_first"], 12.0)
	await look_at_point(p, b.poi["power_line_last"] + Vector3(0, 5.0, 0))
	await shot("power_lit")
	# walk up the ramp and in through the door
	var door: Vector3 = b.poi["bridge_hut_door"]
	var hut: Vector3 = b.poi["bridge_hut"]
	var out := door - hut
	out.y = 0.0
	await place_player(p, door + out.normalized() * 4.0 + Vector3(0, 0.6, 0), atan2(out.x, out.z))
	await wait(0.4)
	var inside := await walk_to(p, hut, "into the bridge hut", 0.6, 12.0)
	log_line("in the hut: %s, %.2f m above its floor" % [p.global_position, p.global_position.y - hut.y])
	check(inside and absf(p.global_position.y - hut.y) < 0.3, "P1 walks up the ramp and into the hut")
	await look_at_point(p, b.poi["bridge"] + Vector3(0, 1.0, 0))
	await shot("power_hut")
	if not was_solved:
		stn.solved = false
		line.sync()


## W6, the lift bridge, with the real controls: P1 (keyboard) works the levers
## in the hut, P2 (pad) is in the machinery house. Jammed; the wedge only
## comes out while RAISE is held; lowered alone it runs away and cuts out;
## stopped with the counterweight level, P2 steps on and it comes down and
## locks; the barriers go and the van drives across.
func t_bridge() -> void:
	var b: LevelBuilder = boot.builder
	var lift := get_tree().get_first_node_in_group("lift_bridge") as LiftBridge
	var line := get_tree().get_first_node_in_group("power_line") as PowerLine
	check(lift != null and line != null, "the bridge has a lift leaf")
	if lift == null:
		return
	var stn := station()
	var was_solved := stn.solved
	stn.solved = true
	line.sync()
	lift.from_dict({})
	boot.story.flags.erase("bridge_down")
	boot.story.index = boot.story.index_of("to_bridge")
	await van_to(b.poi["bridge_barrier_near"])      # you drive here: "carry on to the old bridge" is done
	check(lift.jammed and absf(lift.angle - LiftBridge.UP_DEG) < 0.1, "the leaf is up and jammed")
	boot._on_joy_changed(0, true)      # P2 on a pad
	await wait(0.3)
	var p := p1()
	var q := p2()
	var road := b.network.road("pump_house_road")
	var view_i := b.bridge_span.x - 16
	await place_player(p, road.point(view_i) + road.right(view_i) * 2.0 + Vector3(0, 0.5, 0), 0.0)
	await look_at_point(p, b.poi["lift_pivot"] + Vector3(0, 3.0, 0))
	await place_player(q, road.point(view_i + 5) - road.right(view_i) * 7.0 + Vector3(0, 0.5, 0), 0.0)
	await look_at_point(q, b.poi["lift_pivot"] + Vector3(0, 2.0, 0))
	await wait(0.5)
	check(boot.story.current()["id"] == "bridge", "at the bridge the objective is: lower the lift bridge")
	await shot("bridge_up")
	var raise_lever := lift.find_child("RAISELever", true, false) as Node3D
	var lower_lever := lift.find_child("LOWERLever", true, false) as Node3D
	var panel: Vector3 = b.poi["bridge_panel"]
	var hut: Vector3 = b.poi["bridge_hut"]
	var back := hut - panel
	back.y = 0.0
	# P1 at the levers: LOWER strains
	await place_player(p, panel + back.normalized() * 0.9 + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, lower_lever.global_position)
	await wait(0.2)
	log_line("at the panel: '%s'" % p.prompt_text)
	key(KEY_E, true)
	await wait(1.2)
	key(KEY_E, false)
	check(lift.jammed and lift.angle > 69.0, "LOWER with the wedge in: the motor strains, the leaf stays up")
	await look_at_point(p, b.poi["bridge_mirror"])
	await wait(0.4)
	await shot("bridge_mirror")
	# P2 walks into the machinery house from the deck and tries the wedge
	await place_player(q, b.poi["machinery_door"] + Vector3(0, 0.4, 0), 0.0)
	await look_at_point(q, b.poi["machinery_in"])
	await wait(0.3)
	pad_axis(JOY_AXIS_LEFT_Y, -1.0)
	await wait(0.6)
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	await wait(0.3)
	log_line("P2 in the machinery house at %s (%.1f m from inside point)" % [q.global_position, q.global_position.distance_to(b.poi["machinery_in"])])
	await look_at_point(q, lift.wedge.global_position)
	await wait(0.3)
	log_line("P2 at the wedge: '%s'" % q.prompt_text)
	check(q.prompt_text.contains("back it off"), "the wedge won't budge while the gear presses on it (it says why)")
	await shot("bridge_wedge")
	# together: P1 holds RAISE, P2 pulls
	await look_at_point(p, raise_lever.global_position)
	key(KEY_E, true)
	await wait(0.3)
	pad_button(JOY_BUTTON_X, true)
	await wait(LiftBridge.PULL_S + 0.5)
	pad_button(JOY_BUTTON_X, false)
	key(KEY_E, false)
	check(not lift.jammed, "P1 holds RAISE while P2 pulls: the wedge comes out")
	# lowering alone: it runs away and cuts out
	await look_at_point(p, lower_lever.global_position)
	key(KEY_E, true)
	var t0 := Time.get_ticks_msec()
	while lift.cut_outs == 0 and Time.get_ticks_msec() - t0 < 15000:
		await physics_frames(1)
	key(KEY_E, false)
	await wait(4.0)
	log_line("cut-outs %d, leaf back at %.1f deg" % [lift.cut_outs, lift.angle])
	check(lift.cut_outs == 1 and absf(lift.angle - LiftBridge.RESET_DEG) < 1.0, "lowered with nobody on the counterweight it runs away: the cut-out hauls it back to 45")
	# the operator watches the mirror and stops it with the counterweight level
	key(KEY_E, true)
	t0 = Time.get_ticks_msec()
	while not lift.can_step_on() and Time.get_ticks_msec() - t0 < 10000:
		await physics_frames(1)
	await physics_frames(6)
	key(KEY_E, false)
	await wait(0.3)
	log_line("stopped at %.1f deg, counterweight top %.2f m from the floor" % [lift.angle, lift.counterweight_top()])
	check(lift.can_step_on() and lift.cut_outs == 1, "P1 stops the leaf with the counterweight level with the floor")
	await shot("bridge_level")
	# P2 steps on
	var cw := lift.counterweight.global_position
	await place_player(q, b.poi["counterweight_edge"] + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(q, cw + Vector3(0, 0.5, 0))
	await wait(0.2)
	pad_axis(JOY_AXIS_LEFT_Y, -1.0)
	t0 = Time.get_ticks_msec()
	while not lift.rider_on() and Time.get_ticks_msec() - t0 < 3000:
		await physics_frames(1)
	await wait(0.4)
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	await wait(0.4)
	check(lift.rider_on(), "P2 steps onto the counterweight")
	# down it comes, with P2 riding the counterweight up
	await look_at_point(p, lower_lever.global_position)
	key(KEY_E, true)
	t0 = Time.get_ticks_msec()
	while not lift.locked and Time.get_ticks_msec() - t0 < 15000:
		await physics_frames(1)
	key(KEY_E, false)
	await wait(0.5)
	log_line("locked %s, cut-outs %d, P2 %.2f m above the floor" % [lift.locked, lift.cut_outs, q.global_position.y - b.poi["lift_pivot"].y])
	check(lift.locked and lift.cut_outs == 1 and boot.story.flags.has("bridge_down"), "with P2's weight on it the leaf comes down and locks")
	var bar_shapes := b.bridge_barriers.find_children("*", "CollisionShape3D", true, false)
	check(not b.bridge_barriers.visible and bar_shapes.all(func(c): return c.disabled), "the barriers are gone")
	await wait(0.6)
	check(boot.story.current()["id"] == "cross", "the objective moves on to: cross the river")
	await place_player(q, b.poi["machinery_in"] + Vector3(0, 0.4, 0), 0.0)
	await place_player(p, road.point(view_i) + road.right(view_i) * 2.0 + Vector3(0, 0.5, 0), 0.0)
	await look_at_point(p, b.poi["bridge_far"])
	await wait(0.5)
	await shot("bridge_down")
	# the van drives across
	await van_to(road.point(b.bridge_span.x - 22))
	var c := camper()
	c.fuel = 40.0
	await seat_p1_driver()
	if not c.engine_on:
		c.toggle_engine()
	var ad := AutoDriver.new(self, road, c)
	var far: Vector3 = b.poi["bridge_far"]
	var lowest := INF
	var tt := 0.0
	while tt < 30.0 and Vector2(c.global_position.x - far.x, c.global_position.z - far.z).length() > 4.0:
		await get_tree().physics_frame
		tt += 1.0 / 60.0
		ad.step(20.0)
		lowest = minf(lowest, c.global_position.y)
	ad.release()
	key(KEY_S, true)
	await wait(1.5)
	key(KEY_S, false)
	log_line("van reached the far bank in %.1f s (lowest %.2f, deck %.2f)" % [tt, lowest, b.poi["lift_pivot"].y])
	check(Vector2(c.global_position.x - far.x, c.global_position.z - far.z).length() < 6.0 and lowest > b.poi["lift_pivot"].y - 1.5, "the van drives across the lowered leaf")
	await tap(KEY_SPACE)
	p.force_exit = true
	await physics_frames(3)
	if not was_solved:
		stn.solved = false
		line.sync()


## D10, the ghat: pace notes on the swung nav, the fog on the hairpins, a
## glimpse on the second hairpin, then the first creature at the pass comes
## for the van; hidden under the tarp, it loses interest and goes.
func t_ghat() -> void:
	var b: LevelBuilder = boot.builder
	var g := get_tree().get_first_node_in_group("ghat") as Ghat
	check(g != null and g.hairpins.size() >= 2, "the ghat road has its hairpins (%d)" % (g.hairpins.size() if g else 0))
	if g == null or g.hairpins.size() < 2:
		return
	var st: Story = boot.story
	for f in ["ghat_glimpse", "first_attack", "first_attack_over"]:
		st.flags.erase(f)
	st.index = st.index_of("ghat")
	var c := camper()
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	mood.set_now(0.7)
	boot._on_joy_changed(0, true)      # P2 on a pad, in the passenger seat
	await wait(0.3)
	await van_to(g.road.point(g.fog_from + 10))
	c.fuel = 45.0
	c.attack.set_tarp(false)
	await seat_p1_driver()
	var q := p2()
	if q.seat == null:
		q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await physics_frames(3)
	if not c.engine_on:
		c.toggle_engine()
	# P2 swings the nav (pad A) and reads the pace notes
	pad_button(JOY_BUTTON_A, true)
	await wait(0.1)
	pad_button(JOY_BUTTON_A, false)
	await wait(1.0)
	var nav: Label3D = c._needles.get("nav_label")
	log_line("pace notes: %s" % nav.text.replace("\n", " | "))
	check(c.nav_aside and (nav.text.contains("LEFT") or nav.text.contains("RIGHT")), "the swung nav reads pace notes on the ghat")
	check(nav.layers == 1 << (1 + p1().index), "the driver can't see them")
	var t0 := Time.get_ticks_msec()
	while g.fog < 0.99 and Time.get_ticks_msec() - t0 < 8000:
		await wait(0.2)
	var env := (boot.world.get_node("Environment") as WorldEnvironment).environment
	log_line("fog %.2f: visible to %.0f m" % [g.fog, env.fog_depth_end])
	check(g.fog > 0.9 and env.fog_depth_end < 60.0, "fog comes down on the hairpins (%.0f m)" % env.fog_depth_end)
	await shot("ghat_notes")
	# drive up: the glimpse, then the pass
	var ad := AutoDriver.new(self, g.road, c)
	var tt := 0.0
	var glimpsed := false
	var notes_seen := {}
	while tt < 150.0 and not st.flags.has("first_attack"):
		await get_tree().physics_frame
		tt += 1.0 / 60.0
		ad.step(24.0)
		if int(tt * 60.0) % 30 == 0:
			notes_seen[nav.text.get_slice("\n", 1).strip_edges()] = true
		if not glimpsed and g.glimpse != null:
			glimpsed = true
			log_line("glimpse at %.0f s, %.0f m from the van" % [tt, g.glimpse.global_position.distance_to(c.global_position)])
			await shot("ghat_glimpse")
	log_line("notes read on the way up: %s" % str(notes_seen.keys()))
	check(glimpsed and st.flags.has("ghat_glimpse"), "on the second hairpin a creature is glimpsed between the trees")
	check(st.flags.has("first_attack") and g.attacker != null, "near the pass the first creature shows up (drove %.0f s)" % tt)
	var cr := g.attacker
	var spawn_d := cr.global_position.distance_to(c.global_position)
	log_line("it showed up %.0f m ahead" % spawn_d)
	check(spawn_d > 80.0, "it shows up far up the road, not on top of you (%.0f m)" % spawn_d)
	# stop well back: brake, handbrake, engine off
	ad.release()
	key(KEY_S, true)
	await wait(2.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)
	await tap(KEY_X)
	await wait(0.5)
	await shot("ghat_attack")
	check(c.attack.stage() == 0 and not c.engine_on, "stopped well back, engine off: it hasn't come for the van")
	check(st.current()["id"] == "hide_van", "the objective: hide the van, or get away")
	# both out; P1 starts the tarp at one back corner, P2 finishes it at the other
	await tap(KEY_E)
	pad_button(JOY_BUTTON_X, true)
	await wait(0.1)
	pad_button(JOY_BUTTON_X, false)
	await wait(0.6)
	check(p1().seat == null and q.seat == null, "both out of the van")
	await _to_tarp_corner(p1(), c, -1.0)
	log_line("P1 at the back corner: '%s'" % p1().prompt_text)
	key(KEY_E, true)
	await wait(VanAttack.TARP_ON_S * 0.5)
	key(KEY_E, false)
	await wait(1.0)
	var half := c.attack.tarp_progress()
	log_line("P1 let go at %.0f%%: '%s'" % [half * 100.0, p1().prompt_text])
	check(not c.attack.tarped and half > 0.35 and half < 0.65, "P1 pulls it half way; letting go keeps it (%.0f%%)" % (half * 100.0))
	await _to_tarp_corner(q, c, 1.0)
	pad_button(JOY_BUTTON_X, true)
	await wait(VanAttack.TARP_ON_S * 0.5 + 0.4)
	pad_button(JOY_BUTTON_X, false)
	await wait(0.3)
	check(c.attack.tarped and not c.headlights_on, "P2 finishes it at the other corner: the van is under the tarp")
	await shot("ghat_tarped")
	# in, to hide: the doors still work under the tarp, the engine doesn't
	await _to_door(p1(), c, "driver")
	await tap(KEY_E)
	await _to_door(q, c, "passenger")
	pad_button(JOY_BUTTON_X, true)
	await wait(0.1)
	pad_button(JOY_BUTTON_X, false)
	await wait(0.6)
	check(p1().seat_role == "driver" and q.seat_role == "passenger", "both hide inside the tarped van")
	await tap(KEY_X)
	await wait(0.3)
	check(not c.engine_on, "under the tarp the engine won't start (it says why)")
	var mirrors_on := false
	for _i in 10:
		await physics_frames(1)
		for sv in c._mirrors:
			if sv.render_target_update_mode != SubViewport.UPDATE_DISABLED:
				mirrors_on = true
	check(mirrors_on, "from inside, the door mirrors still show what's out there")
	# the driver turns to the side window: the door mirror, past the canvas
	mouse(Vector2(-520, 60))
	await wait(0.5)
	await shot("ghat_hidden_mirror")
	mouse(Vector2(520, -60))
	# it comes down the road on its round (sped up: from 35 m up the road)
	var up_road := c.global_position - (-c.global_transform.basis.z) * -35.0
	var ni := int(g.road.nearest(up_road.x, up_road.z)["index"])
	var near_pt := g.road.point(ni) + g.road.right(ni) * 3.5
	cr.global_position = Vector3(near_pt.x, Landscape.ground(near_pt.x, near_pt.z), near_pt.z)
	cr.reset_physics_interpolation()
	var closest := 999.0
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 45000:
		await wait(0.25)
		closest = minf(closest, cr.global_position.distance_to(c.global_position))
		if closest < 12.0 and cr.global_position.distance_to(c.global_position) > closest + 8.0:
			break
	log_line("it walked by: closest %.1f m, state %s, van stage %d, interest %.1f" % [closest, Creature.State.keys()[cr.state], c.attack.stage(), cr.van_interest])
	await shot("ghat_passing")
	check(closest < 15.0 and c.attack.stage() == 0 and c.attack.leak_rate() == 0.0, "it walks right by the tarped van and doesn't notice it (closest %.1f m)" % closest)
	# and back up its road (sped up), then it's gone
	var far_i := mini(g.road.point_count() - 1, int(g.road.nearest(c.global_position.x, c.global_position.z)["index"]) + 40)
	var far_pt := g.road.point(far_i) + g.road.right(far_i) * 3.5
	cr.global_position = Vector3(far_pt.x, Landscape.ground(far_pt.x, far_pt.z), far_pt.z)
	cr.reset_physics_interpolation()
	t0 = Time.get_ticks_msec()
	while not st.flags.has("first_attack_over") and Time.get_ticks_msec() - t0 < 20000:
		await wait(0.25)
	check(st.flags.has("first_attack_over") and cr.passive, "back up the road it's gone for good")
	await wait(0.6)
	check(st.current()["id"] == "to_tower", "the objective moves on: to the coast watchtower")
	# out, tarp off, on we go
	p1().force_exit = true
	q.force_exit = true
	await physics_frames(4)
	await _to_tarp_corner(p1(), c, -1.0)
	key(KEY_E, true)
	await wait(VanAttack.TARP_OFF_S + 0.5)
	key(KEY_E, false)
	check(not c.attack.tarped, "hold E at a corner: the tarp comes off")
	c.attack.set_tarp(false)
	mood.set_now(1.0)
	if c.nav_aside:
		c.swing_nav()


## Stand by a back corner of the van (side -1 left, +1 right) looking at it.
func _to_tarp_corner(pl: PlayerRig, c: Camper, side: float) -> void:
	var stand := c._body_root.global_transform * Vector3(side * 2.3, 0, 3.4)
	var look := c._body_root.global_transform * Vector3(side * 1.3, 1.3, 2.85)
	await place_player(pl, Vector3(stand.x, Landscape.ground(stand.x, stand.z) + 0.3, stand.z), 0.0)
	await wait(0.4)
	await look_at_point(pl, look)
	await physics_frames(3)


## Stand outside a door of the van looking at it.
func _to_door(pl: PlayerRig, c: Camper, role: String) -> void:
	var sx := -1.0 if role == "driver" else 1.0
	var stand := c._body_root.global_transform * Vector3(sx * 2.9, 0, -1.8)
	var look := c._body_root.global_transform * Vector3(sx * 1.46, 1.4, -1.8)
	await place_player(pl, Vector3(stand.x, Landscape.ground(stand.x, stand.z) + 0.3, stand.z), 0.0)
	await wait(0.4)
	await look_at_point(pl, look)
	await physics_frames(3)


## D11, the coast watchtower: park, get out, and the creature at its base
## wakes and paces; it sees a player standing in the open; crouched behind
## the cover it doesn't; up the ramp to the deck, then stamp the beach.
func t_tower() -> void:
	var b: LevelBuilder = boot.builder
	var cw := get_tree().get_first_node_in_group("coast_watch") as CoastWatch
	check(cw != null and cw.covers.size() >= 4 and cw.boxes.size() == 3, "the watchtower has cover and a stack of boxes")
	if cw == null:
		return
	var st: Story = boot.story
	st.flags.erase("tower_seen")
	st.index = st.index_of("to_tower")
	var ms: MapState = boot.map_state
	ms.stamps.clear()
	var c := camper()
	await van_to(b.poi["coast_road_stop"])
	if c.engine_on:
		c.toggle_engine()
	c.set_headlights(false)
	var p := p1()
	var q := p2()
	for pl in [p, q]:
		if pl.seat != null:
			pl.force_exit = true
	await physics_frames(4)
	await place_player(p, b.poi["coast_arrive"] + Vector3(0, 0.5, 0), 0.0)
	await place_player(q, b.poi["coast_arrive"] + Vector3(1.5, 0.5, 0), 0.0)
	await wait(1.2)
	log_line("arrive %.0f m from the tower, ramp foot %.0f m; P1 %.0f m" % [b.poi["coast_arrive"].distance_to(b.poi["coast_tower"]), b.poi["coast_tower_ramp_foot"].distance_to(b.poi["coast_tower"]), p.global_position.distance_to(b.poi["coast_tower"])])
	check(cw.creature != null and st.flags.has("tower_seen"), "on foot near the tower, the creature at its base shows itself")
	check(st.current()["id"] == "tower", "the objective: get up the tower unseen")
	var cr := cw.creature
	if cr == null:
		return
	var from := cr.global_position
	await wait(3.0)
	log_line("it paced %.1f m in 3 s" % cr.global_position.distance_to(from))
	check(cr.global_position.distance_to(from) > 2.0, "it paces round the tower's base")
	await look_at_point(p, cr.global_position + Vector3.UP * 1.5)
	await shot("tower_arrive")
	# standing in the open in front of it at 16 m: seen
	var tower: Vector3 = b.poi["coast_tower"]
	var spot := cw.patrol[0]
	await calm_creature(cr, spot, 0.0)
	var fwd := -cr.global_transform.basis.z
	fwd.y = 0.0
	await place_player(p, spot + fwd.normalized() * 16.0 + Vector3(0, 0.5, 0), 0.0)
	await wait(1.0)
	log_line("standing 16 m in front: seen %s, suspicion %.2f" % [cr.seen_now.has(p), cr.suspicion])
	check(cr.seen_now.has(p), "standing in the open in front of it, it sees you")
	# crouched behind the rock nearest the tower, with the rock between: not seen
	var rock := cw.covers[2]
	var away := rock.global_position - tower
	away.y = 0.0
	spot = rock.global_position - away.normalized() * 12.0
	spot.y = Landscape.ground(spot.x, spot.z)
	await calm_creature(cr, spot, atan2(-away.x, -away.z))
	await place_player(p, rock.global_position + away.normalized() * 1.4 + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, spot + Vector3.UP * 1.5)
	key(KEY_CTRL, true)
	await wait(1.5)
	var hidden := not cr.seen_now.has(p)
	log_line("crouched behind the rock %.0f m from it: seen %s" % [p.global_position.distance_to(spot), cr.seen_now.has(p)])
	check(hidden, "crouched behind the rock, it doesn't see you")
	# peek over it: seen (it's looking this way)
	await mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(1.0)
	log_line("peeking: %s, seen %s" % [p.peeking, cr.seen_now.has(p)])
	check(p.peeking and cr.seen_now.has(p), "peek over the rock (hold RMB): you see it, and it sees you")
	await shot("tower_peek")
	await mouse_button(MOUSE_BUTTON_RIGHT, false)
	key(KEY_CTRL, false)
	await wait(0.3)
	# up the ramp to the deck (it's sent round the far side, off duty for the test)
	cr.passive = true
	await calm_creature(cr, tower + (tower - b.poi["coast_tower_ramp_foot"]).normalized() * 12.0, 0.0)
	var foot: Vector3 = b.poi["coast_tower_ramp_foot"]
	await place_player(p, foot + (foot - tower).normalized() * 2.0 + Vector3(0, 0.5, 0), 0.0)
	var deck: Vector3 = b.poi["coast_tower_deck"]
	var up := await walk_to(p, deck, "up the watchtower ramp", 1.2, 25.0)
	await wait(0.6)
	log_line("on the deck: %s, %.1f m up" % [p.global_position, p.global_position.y - tower.y])
	check(up and st.current()["id"] == "stamp_beach", "walked up the ramp to the deck; now stamp the beach")
	await look_at_point(p, b.poi["beach"] + Vector3.UP * 2.0)
	await shot("tower_view")
	var beach: Vector3 = b.poi["beach"]
	ms.add_stamp("fuel", Vector2(tower.x, tower.z))                        # a stamp somewhere else doesn't count
	await wait(0.6)
	check(st.current()["id"] == "stamp_beach", "a stamp elsewhere doesn't count")
	ms.add_stamp("puzzle", Vector2(beach.x + 40.0, beach.z - 30.0))
	await wait(0.6)
	check(st.current()["id"] == "to_beach", "stamping the beach: done; the nav points there")
	cr.passive = false
	cr.queue_free()
	cw.creature = null
	ms.stamps.clear()


## W2, the hay maze by the barn: up the loft ladder; the walls stop you
## walking straight through; walk the way the loft would call it; the dust
## blows in over the middle; the feed chest at the end.
func t_maze() -> void:
	var b: LevelBuilder = boot.builder
	var maze := get_tree().get_first_node_in_group("barn_maze") as BarnMaze
	var lad := boot.world.find_child("LoftLadder", true, false) as Ladder
	check(maze != null and lad != null, "the barn has a maze and a ladder to its loft")
	if maze == null or lad == null:
		return
	maze.from_dict({})
	var way := maze.path(maze.entrance, maze.goal)
	log_line("maze: %d cells from the way in to the chest" % way.size())
	check(way.size() >= 8 and way[way.size() - 1] == maze.goal, "there is one way through, and it's long enough (%d cells)" % way.size())
	var p := p1()
	var q := p2()
	# P1 up the loft ladder with the real keys
	await place_player(p, b.poi["loft_ladder"] + Vector3(0, 0.4, 0), lad.climb_yaw())
	await look_at_point(p, lad.global_transform * Vector3(0, 1.6, 0))
	await wait(0.2)
	await tap(KEY_E)
	key(KEY_W, true)
	var t0 := Time.get_ticks_msec()
	while p.ladder != null and Time.get_ticks_msec() - t0 < 10000:
		await physics_frames(1)
	key(KEY_W, false)
	await wait(0.4)
	log_line("loft: at %s, %.2f m from the balcony" % [p.global_position, p.global_position.distance_to(b.poi["loft"])])
	check(p.ladder == null and p.global_position.distance_to(b.poi["loft"]) < 1.8 and p.is_on_floor(), "up the ladder onto the loft balcony")
	await look_at_point(p, b.poi["maze"])
	await shot("maze_loft")
	# the walker: P1 comes down (teleport), P2 takes the loft
	await place_player(q, b.poi["loft"] + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(q, b.poi["maze"])
	var at_in := maze.global_transform * (maze.cell_pos(maze.entrance) + Vector3(0, 0, BarnMaze.CELL))
	await place_player(p, at_in + Vector3(0, 0.4, 0), 0.0)
	await wait(0.3)
	# straight at the chest: the hedges stop you
	var chest_at := maze.global_transform * maze.cell_pos(maze.goal)
	var straight := await walk_to(p, chest_at, "straight through the maze", 0.8, 4.0)
	check(not straight, "you can't walk straight through the hedges")
	await place_player(p, at_in + Vector3(0, 0.4, 0), 0.0)
	var ok := true
	var dust_seen := false
	for c in way:
		var target := maze.global_transform * maze.cell_pos(c)
		# the chest stands in the middle of the last cell: stop in front of it
		if not await walk_to(p, target, "maze cell %s" % str(c), 1.3 if c == maze.goal else 0.7, 8.0):
			ok = false
			break
		if maze.dust_on and not dust_seen:
			dust_seen = true
			await shot("maze_dust")
	check(ok and maze.cell_at(p.global_position) == maze.goal, "walked the way through, turn by turn, to the far end")
	check(dust_seen, "hay dust blows over the middle as you pass")
	await look_at_point(p, chest_at + Vector3.UP * 0.4)
	await wait(0.2)
	await tap(KEY_E)
	await wait(0.8)
	check(maze.chest_open and boot.world.find_child("MazeCoolant", true, false) != null and boot.story.flags.has("maze_done"), "the feed chest: a jug of coolant and a crate")
	await shot("maze_chest")
	for nm in ["MazeCoolant", "MazeCrate"]:
		var it: Node = boot.world.find_child(nm, true, false)
		if it != null:
			it.queue_free()


## W4, the binocular relay at the Pine Ridge lookout: two boards out across
## the valley show the code in pictures (binoculars from the deck); P2 at the
## supply box turns the dials to match (pad X); it opens, a full can inside.
func t_relay() -> void:
	var b: LevelBuilder = boot.builder
	var relay := get_tree().get_first_node_in_group("lookout_relay") as LookoutRelay
	check(relay != null and relay.boards.size() == 2 and relay.code.size() == 4, "the lookout has a picture-lock supply box and two code boards")
	if relay == null:
		return
	relay.from_dict({"dials": [(relay.code[0] + 3) % 6, (relay.code[1] + 2) % 6, (relay.code[2] + 4) % 6, (relay.code[3] + 1) % 6], "opened": false})
	boot._on_joy_changed(0, true)      # P2 on a pad
	await wait(0.3)
	var p := p1()
	var q := p2()
	check(boot.world.find_child("KioskBinoculars", true, false) != null, "a backstop pair of binoculars waits on the Last Fuel kiosk counter")
	# up on the deck, take the binoculars off the bench (they're found here, not given)
	p.has_binoculars = false
	await place_player(p, b.poi["lookout_deck"] + Vector3(0, 0.3, 0), 0.0)
	await wait(0.4)
	await look_at_point(p, b.poi["lookout_binoculars"] + Vector3(0, 0.05, 0))
	var t_wait := Time.get_ticks_msec()
	while p.prompt_text == "" and Time.get_ticks_msec() - t_wait < 2000:
		await physics_frames(2)
	log_line("at the bench: '%s'" % p.prompt_text)
	await shot("relay_bench")
	await tap(KEY_E)
	await physics_frames(3)
	check(p.has_binoculars and boot.world.find_child("LookoutBinoculars", true, false) == null, "the binoculars are on the lookout deck's bench: E takes them")
	await place_player(p, b.poi["lookout_deck"] + Vector3(0, 0.3, 0), 0.0)
	var names := []
	for k in 2:
		var board: Vector3 = b.poi["relay_board_%d" % (k + 1)]
		log_line("board %d: %.0f m from the deck" % [k + 1, board.distance_to(b.poi["lookout_deck"])])
		await look_at_point(p, board)
		await wait(0.3)
		await shot("relay_board%d_eye" % (k + 1))
		await mouse_button(MOUSE_BUTTON_RIGHT, true)
		await wait(0.6)
		await shot("relay_board%d_zoom" % (k + 1))
		await mouse_button(MOUSE_BUTTON_RIGHT, false)
		await wait(0.3)
		# can the deck see the board? a ray from the eye to the board's middle
		var eye := p.global_position + Vector3.UP * 1.56
		var hit: Dictionary = p.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, board, 1 | 8))   # ground, and trees and buildings
		log_line("board %d in sight: %s" % [k + 1, str(hit.is_empty())])
		check(hit.is_empty(), "board %d can be seen from the deck (nothing in the way)" % (k + 1))
	for c in relay.code:
		names.append(LookoutRelay.SHAPES[c])
	log_line("the code: %s" % str(names))
	# P2 at the box turns each dial until it shows what was called down
	await place_player(q, b.poi["relay_box"] + Vector3(0, 0.4, 0), 0.0)
	var boxn := relay.find_child("SupplyBox", true, false) as Node3D
	var front := boxn.global_transform * Vector3(0, 0, -1.4)
	await place_player(q, front + Vector3(0, 0.4, 0), 0.0)
	await wait(0.5)          # land first, then aim
	var presses := 0
	for k in 4:
		var dial := relay.find_child("Dial%d" % k, true, false) as Node3D
		await look_at_point(q, dial.global_position)
		await wait(0.2)
		log_line("dial %d: '%s', ray hits %s" % [k, q.prompt_text, q.ray.get_collider().name if q.ray.is_colliding() else "nothing"])
		var guard := 0
		while relay.dials[k] != relay.code[k] and guard < 8:
			pad_button(JOY_BUTTON_X, true)
			await wait(0.08)
			pad_button(JOY_BUTTON_X, false)
			await wait(0.12)
			presses += 1
			guard += 1
	await wait(0.8)
	log_line("dials %s, code %s, %d presses" % [str(relay.dials), str(relay.code), presses])
	check(relay.opened and boot.world.find_child("RelayFuel", true, false) != null and boot.story.flags.has("relay_done"), "the dials match: the box opens, a full can inside")
	await shot("relay_open")
	var can: Node = boot.world.find_child("RelayFuel", true, false)
	if can != null:
		can.queue_free()


## W4 as a player does it alone on the keyboard: a fresh box, E on each dial.
func t_relay_kb() -> void:
	var b: LevelBuilder = boot.builder
	var relay := get_tree().get_first_node_in_group("lookout_relay") as LookoutRelay
	# as in a new game, whatever ran before
	relay.from_dict({"dials": [(relay.code[0] + 3) % 6, (relay.code[1] + 2) % 6, (relay.code[2] + 4) % 6, (relay.code[3] + 1) % 6], "opened": false})
	var old_can: Node = boot.world.find_child("RelayFuel", true, false)
	if old_can != null:
		old_can.queue_free()
	var p := p1()
	var boxn := relay.find_child("SupplyBox", true, false) as Node3D
	var front := boxn.global_transform * Vector3(0, 0, -1.4)
	await place_player(p2(), boxn.global_transform * Vector3(6, 0.6, 0), 0.0)     # out of the way
	await place_player(p, front + Vector3(0, 0.4, 0), 0.0)
	await wait(0.6)
	log_line("fresh dials %s, code %s" % [str(relay.dials), str(relay.code)])
	await look_at_point(p, boxn.global_transform * Vector3(0, 0.4, -0.4))
	await wait(0.3)
	await shot("relay_dials_fresh")
	for k in 4:
		var dial := relay.find_child("Dial%d" % k, true, false) as Node3D
		await look_at_point(p, dial.global_position)
		await wait(0.2)
		var guard := 0
		while relay.dials[k] != relay.code[k] and guard < 8:
			log_line("dial %d: '%s' target %s" % [k, p.prompt_text, p.current_target.name if p.current_target else "none"])
			await tap(KEY_E)
			await wait(0.15)
			guard += 1
	await wait(0.5)
	log_line("dials %s code %s opened %s equal %s" % [str(relay.dials), str(relay.code), relay.opened, relay.dials == relay.code])
	check(relay.opened, "turned on the keyboard from fresh, the box opens")


## The ghat as a person testing alone sets it up: F1, Story -> jump to "up
## the ghat", Travel -> the foot of the ghat, Van -> bring it here, both in;
## close. The van stands on its wheels; drive up, swing the nav (N) and the
## pace notes show; then break the van and "fix everything" fixes it.
func t_ghat_menu() -> void:
	var b: LevelBuilder = boot.builder
	var dm: DevMenu = boot.dev_menu
	var st: Story = boot.story
	var c := camper()
	var g := get_tree().get_first_node_in_group("ghat") as Ghat
	for f in ["ghat_glimpse", "first_attack", "first_attack_over"]:
		st.flags.erase(f)
	await tap(KEY_F1)
	await physics_frames(2)
	dm.set_tab(DevMenu.TABS.find("Story"))
	for i in dm._rows.size():
		if dm._rows[i]["action"] == "jump" and dm._rows[i]["arg"] == st.index_of("ghat"):
			dm._select(i, true)
	await tap(KEY_ENTER)
	dm.select_place("j3")
	await tap(KEY_ENTER)
	dm.set_tab(DevMenu.TABS.find("Van"))
	dm.select_action("van_here")
	await tap(KEY_ENTER)
	await wait(0.4)
	await shot("menu_van_paused")          # the menu still open: the game is paused
	await tap(KEY_F1)
	await wait(1.5)
	await look_at_point(p1(), c.global_position)
	await wait(0.3)
	await shot("menu_van_after")
	var side_at := c.global_transform * Vector3(7.0, 0.0, 0.0)
	await place_player(p1(), Vector3(side_at.x, Landscape.ground(side_at.x, side_at.z) + 0.3, side_at.z), 0.0)
	await wait(0.4)
	await look_at_point(p1(), c.global_position + Vector3.DOWN * 0.3)
	await wait(0.3)
	await shot("menu_van_side")
	for w in c._wheels:
		var wl := c.global_transform.affine_inverse() * (w as Node3D).global_position
		log_line("wheel %s: van-local %s, contact %s, visible %s; mesh local %s visible %s" % [w.name, wl, (w as VehicleWheel3D).is_in_contact(), (w as Node3D).is_visible_in_tree(), c._wheel_meshes[c._wheels.find(w)].position, c._wheel_meshes[c._wheels.find(w)].visible])
	log_line("van: freeze %s, y %.2f, ground %.2f, vel %s" % [c.freeze, c.global_position.y, Landscape.ground(c.global_position.x, c.global_position.z), c.linear_velocity])
	await tap(KEY_F1)
	dm.set_tab(DevMenu.TABS.find("Van"))
	dm.select_action("van_seat")
	await tap(KEY_ENTER)
	await tap(KEY_F1)
	await wait(2.0)
	check(st.current()["id"] == "ghat", "the Story jump: up the ghat road")
	var wheels_ok := true
	for m in c._wheel_meshes:
		var local := c.global_transform.affine_inverse() * (m as Node3D).global_position
		if local.length() > 4.0 or local.y > 0.2:
			wheels_ok = false
			log_line("wheel %s at van-local %s" % [m.name, local])
	check(wheels_ok and p1().seat_role == "driver" and q_seat(), "the brought van stands on its wheels, both of us in it")
	await shot("menu_van_brought")
	# drive up and swing the nav
	if not c.engine_on:
		await tap(KEY_X)
	var i0 := int(g.road.nearest(c.global_position.x, c.global_position.z)["index"])
	var path := Route.from_points(g.road.points.slice(i0), false)
	var ad := AutoDriver.new(self, path, c)
	var nav: Label3D = c._needles.get("nav_label")
	var tt := 0.0
	var swung := false
	var notes := ""
	while tt < 150.0 and g.fog < 0.95:
		await get_tree().physics_frame
		tt += 1.0 / 60.0
		ad.step(22.0)
		if tt > 2.0 and not swung:
			swung = true
			ad.release()
			await tap(KEY_N)
		if swung and nav.text.contains("LEFT") or nav.text.contains("RIGHT"):
			notes = nav.text
	ad.release()
	key(KEY_S, true)
	await wait(2.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)
	log_line("on the ghat %s, fog %.2f, nav: '%s'" % [g.on_ghat, g.fog, notes.replace("\n", " | ")])
	check(c.nav_aside and notes != "", "N swings the nav and it reads the pace notes")
	check(g.fog > 0.9, "the fog comes down")
	# break the van, then fix everything from the menu
	c.puncture()
	c.attack.attacked_t = VanAttack.ENGINE_AFTER + 1.0
	c.fuel = 3.0
	c.coolant_leak = true
	c.fuel_leak = 1.0 / 60.0
	await tap(KEY_F1)
	dm.set_tab(DevMenu.TABS.find("Van"))
	dm.select_action("van_fix")
	await tap(KEY_ENTER)
	await tap(KEY_F1)
	await physics_frames(3)
	check(not c.tyre_flat and c.attack.stage() == 0 and c.fuel > 60.0 and not c.coolant_leak and c.fuel_leak == 0.0,
		"'Fix the van: everything' fixes the tyre, the creature's damage, fuel and leaks")
	if c.nav_aside:
		c.swing_nav()
	p1().force_exit = true
	p2().force_exit = true
	await physics_frames(3)


func q_seat() -> bool:
	return p2().seat_role == "passenger"


## Stealth gym: the cardboard box ("that box moved"), peeking from cover, and
## a thrown crate luring a creature to where it lands.
func t_hiding() -> void:
	var b := boot.builder as GymBuilder
	var cr := boot.world.get_node_or_null("GymCreature") as Creature
	var bx := boot.world.get_node_or_null("GymBox") as CardboardBox
	check(cr != null and bx != null, "the stealth gym has a cardboard box")
	if cr == null or bx == null:
		return
	var eye := GymBuilder.STEALTH_EYE
	var p := p1()
	await place_player(p2(), eye + Vector3(-20, 0.25, 60), 0.0)   # out of the way
	await calm_creature(cr, eye)
	# pick the box up and get under it, with the real keys
	await place_player(p, bx.global_position + Vector3(0, 0.15, 1.6), 0.0)
	await look_at_point(p, bx.global_position + Vector3.UP * 0.5)
	await tap(KEY_E)
	check(p.held == bx, "E picks the box up")
	await tap(KEY_E)
	await wait(0.5)
	var hud = boot.huds[0]
	check(p.in_box and p.held == null and bx.wearer == p and p.crouching and hud.box_view.amount > 0.9,
		"E again: you are under it, crouched, looking out through a slit")
	await shot("box_inside")
	# still, in the open, 12 m in front of it: just a box
	await calm_creature(cr, eye)
	var top := await exposed(p, eye + Vector3(-5, 0.25, 9), 3.0, false, cr)
	check(top < 0.05, "still in the box 10 m in front of it, in the open: not noticed (%.2f)" % top)
	await shot("box_outside")
	# shuffle sideways while it watches: that box moved
	var watched := false
	key(KEY_D, true)
	for _i in 15:
		await wait(0.1)
		watched = watched or cr.box_moved
	key(KEY_D, false)
	var box_at := p.global_position
	log_line("box moved: suspicion %.2f, %s" % [cr.suspicion, Creature.State.keys()[cr.state]])
	check(watched and cr.state == Creature.State.CURIOUS, "move while it watches and it comes to look at the box")
	var nearest := 99.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 16000:
		await wait(0.2)
		nearest = minf(nearest, cr._flat_dist(box_at))
		if nearest < 7.0 and cr.state == Creature.State.WANDER:
			break
	log_line("it stared from %.1f m, then %s" % [nearest, Creature.State.keys()[cr.state]])
	await shot("box_stared")
	check(nearest < 7.0 and nearest > 3.2 and cr.state == Creature.State.WANDER and boot.world.get_node_or_null("Taken1") == null,
		"it stares at the box from a few metres; you keep still and it loses interest")
	# but move right under its eyes and it is you
	var seen := false
	key(KEY_A, true)
	for _i in 12:
		await wait(0.1)
		if cr.seen_now.has(p):
			seen = true
			break
	key(KEY_A, false)
	check(seen, "move in the box right in front of it and it sees you")
	await calm_creature(cr, eye)
	await tap(KEY_E)
	check(not p.in_box and p.held == bx and bx.wearer == null, "E lifts the box off; you hold it again")
	await tap(KEY_G)       # toss it aside (E would put it back on)
	await wait(0.3)
	# wherever it landed, put it back by the start: a box between you and it
	# blocks its view as well as any cover
	bx.global_position = GymBuilder.STEALTH_EYE + Vector3(4, 0.3, 36)
	bx.linear_velocity = Vector3.ZERO
	bx.reset_physics_interpolation()
	# peeking: crouched behind the rock, hold RMB and your head comes up over it
	await calm_creature(cr, eye)
	key(KEY_CTRL, true)
	await physics_frames(20)
	await place_player(p, b.poi["cover_rock"] + Vector3(0, 0.25, 1.4), 0.0)
	await wait(0.5)
	cr.suspicion = 0.0
	cr._noticed_t = 99.0
	cr._heard_id = Hearing.last_id()
	await wait(1.0)
	check(cr.suspicion < 0.05 and not p.peeking, "crouched behind the rock: hidden (%.2f)" % cr.suspicion)
	var cam_y := p.cam.global_position.y
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.4)
	check(p.peeking and p.peek_offset.y > 0.5 and p.cam.global_position.y > cam_y + 0.5 and p.zoom == 1.0,
		"RMB behind the rock: your head comes up over it (no binoculars)")
	await shot("peek_rock")
	var seen_peek := false
	for _i in 15:
		if cr.seen_now.has(p):
			seen_peek = true
			break
		await wait(0.1)
	check(seen_peek, "peeking, it can see your head")
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	await wait(0.6)
	check(not p.peeking and p.peek_offset.length() < 0.05, "let go and you are back down")
	# a wall too tall to see over: lean out past its end
	await calm_creature(cr, b.poi["cover_wall"] + Vector3(-3, 0, -12))
	await place_player(p, b.poi["cover_wall"] + Vector3(-1.7, 0.25, 1.2), 0.0)
	cr.suspicion = 0.0
	cr._noticed_t = 99.0
	await wait(1.0)
	check(cr.suspicion < 0.05, "crouched by the end of the wall: hidden")
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.5)
	log_line("wall peek offset %s" % p.peek_offset)
	check(p.peeking and p.peek_offset.x < -0.4 and absf(p.peek_offset.y) < 0.05, "at the tall wall you lean out past its end instead")
	await shot("peek_wall")
	seen_peek = false
	for _i in 15:
		if cr.seen_now.has(p):
			seen_peek = true
			break
		await wait(0.1)
	check(seen_peek, "and it sees your head there")
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	key(KEY_CTRL, false)
	await wait(0.4)
	# a lure: behind it, throw a crate off to the side and it goes to look
	await calm_creature(cr, eye)
	var crate := boot.world.get_node_or_null("LureCrate1") as Crate
	await place_player(p, eye + Vector3(4, 0.25, -8), 0.0)
	await look_at_point(p, eye + Vector3(-6, 3.0, -8))
	crate.global_position = p.hold_point(crate)
	crate.linear_velocity = Vector3.ZERO
	crate.reset_physics_interpolation()
	await physics_frames(2)
	p.pick_up(crate)
	await wait(0.4)
	cr._heard_id = Hearing.last_id()
	cr.suspicion = 0.0
	await tap(KEY_G)
	# the thrower slips away; this checks where the creature goes
	await wait(0.8)
	await place_player(p, eye + Vector3(30, 0.25, -30), 0.0)
	await wait(1.0)
	var land := crate.global_position
	log_line("lure: crate landed %.1f m from it; suspicion %.2f, %s" % [cr._flat_dist(land), cr.suspicion, Creature.State.keys()[cr.state]])
	check(cr.state == Creature.State.CURIOUS and cr.last_noticed.distance_to(land) < 3.0, "it hears the crate land and wants to look")
	var reached := 99.0
	t0 = Time.get_ticks_msec()
	# it goes to where it heard the landing (the crate may roll on a bit) and
	# stops 1.5 m short to look
	var heard_at := cr.last_noticed
	while Time.get_ticks_msec() - t0 < 12000 and reached > 2.0:
		await wait(0.2)
		reached = cr._flat_dist(heard_at)
	await shot("lure")
	check(reached <= 2.0 and heard_at.distance_to(crate.global_position) < 3.0 and cr.state != Creature.State.TAKE, "it walks over to where the crate landed (%.1f m from the spot)" % reached)


## Creature gym: the van. It hears the engine and comes; while it stays within
## 15 m the van leaks, then fails, then punctures; driving off stops it all.
## The tarp (engine and lights off, everyone out, hold E at the back) hides
## the van. The horn carries 150 m.
func t_van() -> void:
	var cr := boot.world.get_node_or_null("GymCreature") as Creature
	var c := camper()
	check(cr != null and c != null and c.attack != null and boot.gym == "creature", "the creature gym has a creature and the van")
	if cr == null or c == null:
		return
	var p := p1()
	await place_player(p2(), Vector3(-60, 0.25, 110), 0.0)     # out of the way
	c.parking_brake = true
	c.fuel = 60.0
	var behind := c.global_transform * Vector3(0, 0, 1)
	behind -= c.global_position
	behind.y = 0.0
	behind = behind.normalized()                                # the van's back is this way (flat)
	# parked, engine off, 45 m behind it: nothing to notice
	await calm_creature(cr, c.global_position + behind * 45.0, atan2(behind.x, behind.z))
	await place_player(p, c.global_position + Vector3(-3, 0, 0), 0.0)
	p.enter_seat(c, c.seat_nodes["driver"], "driver")
	await wait(0.3)
	var door := Hearing.since(0).filter(func(s): return s["what"] == "door").size() > 0
	check(door, "getting in makes a door sound (heard 20 m)")
	await tap(KEY_X)
	await wait(2.5)
	check(c.engine_on and cr.state == Creature.State.WANDER and cr.van_interest == 0.0,
		"the engine idling 45 m away: not heard (idle carries 40 m)")
	# 35 m: it hears the engine and comes to the van
	await calm_creature(cr, c.global_position + behind * 35.0, atan2(behind.x, behind.z))
	await wait(1.5)
	check(cr.state == Creature.State.VAN, "the engine idling 35 m away: it hears it and heads for the van")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 25000 and cr._flat_dist(c.global_position) > VanAttack.NEAR:
		await wait(0.2)
	log_line("it reached the van in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	await wait(VanAttack.LEAK_AFTER + 1.0)
	var f0 := c.fuel
	await wait(3.0)
	log_line("at the van: stage %d, leak %.1f L/min, fuel %.2f -> %.2f" % [c.attack.stage(), c.attack.leak_rate(), f0, c.fuel])
	check(c.attack.stage() == 1 and c.attack.leak_rate() > 0.0 and c.fuel < f0 - 0.03, "while it stays, the van leaks fuel")
	await shot("van_attack")
	c.attack.attacked_t = VanAttack.ENGINE_AFTER - 0.5       # skip ahead: 30 s at the van
	await wait(1.2)
	check(c.attack.stage() == 2 and c.attack.power() <= VanAttack.SICK_POWER, "after 30 s the engine fails (power down 40%)")
	c.attack.attacked_t = VanAttack.PUNCTURE_AFTER - 0.5     # 60 s
	await wait(1.2)
	check(c.tyre_flat, "after 60 s a tyre goes")
	# drive off: once it is left behind it all stops (the flat stays flat)
	key(KEY_W, true)
	await wait(8.0)
	key(KEY_W, false)
	await tap(KEY_SPACE)            # handbrake
	await wait(3.0)
	var gap := cr._flat_dist(c.global_position)
	log_line("drove off: %.0f m from it; stage %d, leak %.1f, power %.2f" % [gap, c.attack.stage(), c.attack.leak_rate(), c.attack.power()])
	check(gap > VanAttack.NEAR and c.attack.stage() == 0 and c.attack.leak_rate() == 0.0 and c.tyre_flat,
		"drive away and the leak and the failing engine stop; the flat stays")
	c.tyre_flat = false
	c.tyre_stage = 0
	c.refresh_tyre_visuals()
	# the tarp: everyone out, engine and lights off, hold E at the back for 4 s
	await calm_creature(cr, c.global_position + behind * 120.0, atan2(behind.x, behind.z))
	c.parking_brake = true
	await wait(1.0)
	await tap(KEY_E)                # out of the van
	await wait(0.4)
	var back := c._body_root.global_transform * Vector3(0, 0, 5.2)
	var handle := c._body_root.global_transform * Vector3(0, 2.75, 3.75)
	await place_player(p, Vector3(back.x, c.global_position.y - 0.3, back.z), 0.0)
	await look_at_point(p, handle)
	await wait(0.3)
	log_line("at the back, engine on: '%s'" % p.prompt_text)
	check(p.seat == null and p.prompt_text.contains("Engine off first"), "with the engine running the tarp won't go on (it says why)")
	c.toggle_engine()
	await wait(0.3)
	log_line("engine off: '%s'" % p.prompt_text)
	key(KEY_E, true)
	await wait(VanAttack.TARP_ON_S + 0.5)
	key(KEY_E, false)
	check(c.attack.tarped and c.attack._tarp.visible, "hold E for 4 s: the van is under the tarp")
	var seat_block: String = (c._body_root.get_node("SeatPrompt_driver").get_meta("blocked_fn") as Callable).call()
	check(seat_block == "", "under the tarp you can still get in and hide")
	c.toggle_engine()
	check(not c.engine_on, "the engine won't start under the tarp")
	await place_player(p, c.global_position + Vector3(-7, 0.25, 7), 0.0)
	await look_at_point(p, c.global_position)
	await shot("tarp")
	await place_player(p, c.global_position + Vector3(0, 0.25, -90), 0.0)
	# a creature at the tarped van: no harm, and its interest runs out
	await calm_creature(cr, c.global_position + behind * 8.0, atan2(-behind.x, -behind.z))
	cr.van_interest = 30.0
	await wait(3.0)
	log_line("tarped: stage %d, interest left %.1f s" % [c.attack.stage(), cr.van_interest])
	check(c.attack.attacked_t == 0.0 and c.attack.leak_rate() == 0.0 and cr.van_interest < 27.5,
		"at the tarped van it does nothing and loses interest (not refreshed)")
	# off again: 2 s
	await calm_creature(cr, c.global_position + behind * 120.0, atan2(behind.x, behind.z))
	await place_player(p, Vector3(back.x, c.global_position.y - 0.3, back.z), 0.0)
	await look_at_point(p, handle)
	key(KEY_E, true)
	await wait(VanAttack.TARP_OFF_S + 0.5)
	key(KEY_E, false)
	check(not c.attack.tarped and not c.attack._tarp.visible, "hold E for 2 s: the tarp comes off")
	# the horn: heard 150 m off
	await calm_creature(cr, c.global_position + behind * 120.0, atan2(behind.x, behind.z))
	p.enter_seat(c, c.seat_nodes["driver"], "driver")
	await wait(0.3)
	cr._heard_id = Hearing.last_id()
	key(KEY_Q, true)
	await wait(0.8)
	var honking: bool = c.attack._horn.target > 0.5
	key(KEY_Q, false)
	await wait(0.5)
	check(honking and cr.van_interest > 0.0 and cr.state != Creature.State.WANDER, "the horn: it hears it from 120 m and turns up")
	p.force_exit = true
	await physics_frames(3)
	await calm_creature(cr, GymBuilder.CREATURE_EYE)


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
	c.snap_visuals()
	await wait(14.0)
	log_line("traffic blocked: index %.1f speed %.1f m/s, separation %.1f m" % [car.progress, car.speed, car.global_position.distance_to(c.global_position)])
	check(car.waiting and car.speed < 1.0 and car.global_position.distance_to(c.global_position) > 3.0,
		"the car keeps left and stops behind a parked van")
	var stopped := car.progress
	c.global_position = Vector3(0, 0.8, 30)
	c.snap_visuals()
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
	# the mood only ever falls on the way out, and traffic thins with it: start
	# bright, as at the opening (the full run gets here after the coast)
	var md := get_tree().get_first_node_in_group("mood") as Mood
	md.set_now(1.0)
	await physics_frames(2)
	var lane: Route = boot.builder.network.road("home_lane")
	var cars: Array[TrafficCar] = []
	for k in 4:
		var car := boot.world.get_node_or_null("TownCar%d" % k) as TrafficCar
		if car != null:
			cars.append(car)
	check(cars.size() == 4, "four cars patrol the town part of Homestead Lane")
	if cars.size() < 4:
		return
	# someone near the town (cars stand still with nobody within 600 m), off
	# the road so they don't stop for you
	var near := int(lane.nearest(cars[0].global_position.x, cars[0].global_position.z)["index"])
	await place_player(p1(), lane.point(near) + lane.right(near) * 30.0 + Vector3.UP * 0.5, 0.0)
	await wait(0.5)
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
	# the table: fewer on each road after J1, none after J2; the lorry waits
	var tr: Traffic = boot.builder.traffic
	var counts := [tr.count_on("home_lane"), tr.count_on("valley_road"), tr.count_on("ridge_track"), tr.count_on("pump_house_road"), tr.count_on("ghat_road")]
	log_line("traffic per road (lane, valley, ridge, pump house, ghat): %s" % str(counts))
	check(counts == [6, 2, 1, 0, 0], "traffic thins out after J1 and there is none after J2")
	var lo := boot.world.get_node_or_null("Lorry") as Lorry
	if lo != null and lo.phase != Lorry.Phase.PARKED:
		log_line("the lorry was %s (an earlier drive set it off): back to its lay-by" % Lorry.Phase.keys()[lo.phase])
		lo.reset()
		await physics_frames(3)
	check(lo != null and lo.phase == Lorry.Phase.PARKED and lo.global_position.distance_to(boot.builder.poi["p2_home"]) < 400.0,
		"the lorry waits in its lay-by on the lane up from P2's home")
	tr.density = 0.5
	var half := tr.count_on("home_lane")
	tr.density = 1.0
	check(half == 3 and tr.count_on("home_lane") == 6, "the mood dial takes cars off the road and puts them back")


## The mood dial: one number greys the sky, fog, sun and colours, quietens
## the birds, thins the traffic and at dusk shortens the creatures' sight.
## On the way out it falls, slowly, as the players reach each place.
func t_mood() -> void:
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	# the Bessi tests run before this one and leave the storm on, which holds
	# the light down (E7): put it away
	boot.story.flags.erase("storm_on")
	get_tree().call_group("storm_front", "match_story")
	await place_player(p1(), boot.builder.player_spawns[0].origin, 0.0)
	await place_player(p2(), boot.builder.player_spawns[0].origin + Vector3(2, 0, 0), 0.0)
	mood.set_now(1.0)            # as at the start; earlier scenarios may have been out at the coast
	await physics_frames(2)
	check(mood != null and mood.value > 0.9, "the mood dial is there, bright on the way out's first stretch")
	if mood == null:
		return
	mood.set_now(1.0)        # earlier checks may have walked someone up to J1
	var sun: DirectionalLight3D = boot.world.get_node("Sun")
	var env := (boot.world.get_node("Environment") as WorldEnvironment).environment
	var amb := boot.world.get_node("Ambience") as Ambience
	var tr: Traffic = boot.builder.traffic
	var p := p1()
	var view: Vector3 = boot.builder.poi["j1"]
	await place_player(p, Vector3(view.x - 30, view.y + 0.5, view.z + 40), 0.6)
	await wait(0.5)
	var b := [sun.light_energy, env.adjustment_saturation, amb.liveliness, tr.count_on("home_lane")]
	await shot("mood_bright")
	mood.set_now(0.6)
	await wait(0.4)
	var g := [sun.light_energy, env.adjustment_saturation, amb.liveliness, tr.count_on("home_lane")]
	log_line("mood 1.0 -> 0.6: sun %.2f -> %.2f, saturation %.2f -> %.2f, liveliness %.2f -> %.2f, lane cars %d -> %d" % [b[0], g[0], b[1], g[1], b[2], g[2], b[3], g[3]])
	check(g[0] < b[0] and g[1] < b[1] and g[2] < b[2] and g[3] == 0 and b[3] == 6,
		"greyer: less sun, less colour, quieter, no traffic")
	await shot("mood_grey")
	mood.set_now(0.3)
	await wait(0.4)
	check(mood.light() == 1, "at 0.3 it is dusk for the creatures (their sight shortens)")
	await shot("mood_dusk")
	mood.set_now(1.0)
	await wait(0.3)
	# the way out: at J2 the target falls to 0.85 and the dial eases towards it
	# (visiting J2 draws it on the paper map: put the map back afterwards)
	var map_before: Dictionary = boot.map_state.to_dict()
	await place_player(p, boot.builder.poi["j2"] + Vector3(0, 0.5, 0), 0.0)
	await wait(1.5)
	log_line("at J2: target %.2f, value %.3f" % [mood.target, mood.value])
	check(is_equal_approx(mood.target, 0.85) and mood.value < 1.0 and mood.value > 0.95, "at J2 it starts greying, slowly")
	await place_player(p, boot.builder.poi["j1"] + Vector3(0, 0.5, 0), 0.0)
	await wait(1.0)
	check(is_equal_approx(mood.target, 0.85), "going back to J1 does not brighten it")
	mood.set_now(1.0)
	await place_player(p, boot.builder.poi["homestead"] + Vector3(0, 0.5, 0), 0.0)
	boot.map_state.from_dict(map_before)


## Traffic gym: the one lorry. It waits on the verge, pulls out just ahead of
## the van coming up behind, crawls along holding it up, then pulls in and
## stops for good, and the van gets past. Driven like a player would: on the
## throttle, easing off and braking when close behind it.
func t_lorry() -> void:
	var lo := boot.world.get_node_or_null("GymLorry") as Lorry
	check(lo != null and lo.phase == Lorry.Phase.PARKED and lo.lane_offset > Landscape.ROAD_HALF, "the lorry waits on the verge")
	if lo == null:
		return
	var road: Route = boot.builder.network.road("gym_lorry")
	var start := int(lo.progress) - 110          # the van 220 m behind it
	var f := road.forward(start)
	var c := camper()
	var p := p1()
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP),
		road.point(start) - road.right(start) * TrafficCar.LANE_OFFSET + Vector3.UP * 0.8)
	c.snap_visuals()
	c.parking_brake = true
	await wait(0.6)
	await place_player(p, c.global_position + Vector3(-3, 0, 0), 0.0)
	p.enter_seat(c, c.seat_nodes["driver"], "driver")
	await wait(0.3)
	if not c.engine_on:
		await tap(KEY_X)
	await wait(0.5)
	var out_gap := -1.0
	var min_gap := 999.0
	var passed := false
	var shot_taken := false
	var w_down := false
	var s_down := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 70000:
		await physics_frames(1)
		var gap := lo._van_gap()
		if out_gap < 0.0 and lo.phase != Lorry.Phase.PARKED:
			out_gap = gap
		var ahead := lo.phase != Lorry.Phase.PARKED and lo.phase != Lorry.Phase.DONE and gap > 0.0
		var vs := c.linear_velocity.length()
		# brake early enough to stop 10 m behind it (about 4 m/s² of braking)
		var closing := maxf(0.0, vs - lo.speed)
		var want_s := ahead and closing > 0.3 and gap - 10.0 < closing * closing / 8.0 + 2.0
		var want_w := (not ahead or gap > 22.0) and not want_s
		if want_w != w_down:
			key(KEY_W, want_w)
			w_down = want_w
		if want_s != s_down:
			key(KEY_S, want_s)
			s_down = want_s
		if ahead and lo.phase != Lorry.Phase.PULL_IN:
			min_gap = minf(min_gap, gap)     # while it is in the lane
			if not shot_taken and gap < 24.0:
				shot_taken = true
				await shot("lorry_ahead")
		var vi := int(road.nearest(c.global_position.x, c.global_position.z)["index"])
		if lo.phase == Lorry.Phase.DONE and vi > int(lo.progress) + 8:
			passed = true
			break
	key(KEY_W, false)
	key(KEY_S, false)
	var took := (Time.get_ticks_msec() - t0) / 1000.0
	log_line("lorry: pulled out with the van %.0f m behind; held up %.1f s; closest %.1f m; %s after %.1f s" % [out_gap, lo.held_up_s, min_gap, "passed" if passed else "NOT passed", took])
	check(out_gap >= Lorry.TRIGGER.x - 5.0 and out_gap <= Lorry.TRIGGER.y + 5.0, "it pulls out just ahead of the van coming up behind")
	check(lo.held_up_s > 5.0 and lo.held_up_s < 20.0, "it holds the van up briefly (%.0f s)" % lo.held_up_s)
	check(min_gap > 7.5, "the van never runs into it (closest %.1f m, middle to middle)" % min_gap)
	check(lo.phase == Lorry.Phase.DONE and lo.lane_offset > Landscape.ROAD_HALF and passed, "then it pulls in, stops on the verge, and the van gets past")
	await shot("lorry_passed")
	await tap(KEY_SPACE)
	await wait(1.5)
	p.force_exit = true
	await physics_frames(3)


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
	c.snap_visuals()
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
	c.snap_visuals()
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
	c.snap_visuals()
	await wait(0.2)
	c.global_transform = Transform3D(Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP), lane.point(520) + Vector3.UP * 0.8)
	c.sleeping = false
	c.snap_visuals()
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
	c.snap_visuals()
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
	# the nav, swung to the passenger with N. Hidden from the driver only with
	# two screens: in the one-screen view one person plays both seats (and with
	# no controller plugged in the game starts in it), so set two screens here
	var start_layout: int = boot.layout
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
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
	boot._set_layout(Boot.Layout.SOLO)
	await tap(KEY_N)
	await wait(0.6)
	check(c.nav_aside and label.layers == 1, "in the one-screen view, swung aside it still shows (one person plays both seats)")
	await tap(KEY_N)
	await wait(0.6)
	boot._set_layout(start_layout)
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
	var flat_d := Vector2(p.global_position.x - deck.x, p.global_position.z - deck.z).length()
	check(absf(p.global_position.y - (deck.y - 0.075)) < 0.15 and flat_d < 2.0, "the lookout ramp can be walked up and onto the deck")
	await shot("lookout_climbed")


## Drive from the homestead to the bridge barrier by each route, by keyboard.
func t_journey() -> void:
	var b: LevelBuilder = boot.builder
	# the roads, not the town cars (as t_routes): run first in a fresh world
	# the keyboard driver got stuck behind one; mood 0.6 has them all gone
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var mood_was := mood.value if mood != null else 1.0
	if mood != null:
		mood.set_now(0.6)
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
	if mood != null:
		mood.set_now(mood_was)


## Drive every road of the 4 km map with the keyboard auto-driver and time
## each leg against the beat chart (design/BEAT_CHART.md). Long (~20 min), so
## it is not in the default list: `tools/run_test.sh routes`.
func t_routes() -> void:
	var b: LevelBuilder = boot.builder
	# the roads, not the traffic: the auto-driver doesn't dodge cars, and what
	# ran before decides whether the town cars are out (mood 0.6: all gone)
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var mood_was := mood.value if mood != null else 1.0
	if mood != null:
		mood.set_now(0.6)
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
		var swing := get_tree().get_first_node_in_group("swing_bridge") as SwingBridge
		var rail := get_tree().get_first_node_in_group("rail_tunnel") as RailTunnel
		while t < 900.0:
			await get_tree().physics_frame
			t += 1.0 / 60.0
			ad.step(-1.0)
			# the return's gates (F5, F6), opened by script as the van gets there
			# (their own tests do them for real)
			if swing != null and not swing.locked and c.global_position.distance_to(swing.pivot) < 150.0:
				swing._lock(false)
			if rail != null and rail.gate != null and c.global_position.distance_to(rail.gate.global_position) < 70.0:
				rail.winch.work_by(p2(), 1.0 / 60.0)
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
	if mood != null:
		mood.set_now(mood_was)


## D13: the whole way out in one drive, J1 -> the coast watchtower, on both
## routes (valley, then ridge), the story running. The puzzles are done by
## script where the van gets to them (the water works fixed, the turbine
## lit, the bridge lowered); the ghat fog, the glimpse and the first attack
## happen for real (the van drives on, which is one way out of it). Timed
## leg by leg against the beat chart. `tools/run_test.sh way_out` (Full only).
func t_way_out() -> void:
	var b: LevelBuilder = boot.builder
	var st: Story = boot.story
	var c := camper()
	var lift := get_tree().get_first_node_in_group("lift_bridge") as LiftBridge
	var ghat := get_tree().get_first_node_in_group("ghat") as Ghat
	var stn := station()
	for route in ["valley_road", "ridge_track"]:
		# a fresh way out: the puzzles as they are in a new game
		stn.solved = false
		stn.fill["coolant"] = 0.0
		(get_tree().get_first_node_in_group("power_line") as PowerLine).sync()
		lift.from_dict({})
		for f in ["leak_started", "leak_fixed", "bridge_down", "ghat_glimpse", "first_attack", "first_attack_over", "tower_seen", "windmill_map"]:
			st.flags.erase(f)
		st.index = st.index_of("windmill")
		var mood := get_tree().get_first_node_in_group("mood") as Mood
		mood.set_now(0.95)
		var path := b.network.chain([[route], ["pump_house_road"], ["ghat_road"], ["beach_road"]])
		var stop: Vector3 = b.poi["coast_road_stop"]
		var stop_at := int(path.nearest(stop.x, stop.z)["index"])
		# the van at J1, both in
		c.freeze = false
		var f0 := path.forward(4)
		c.linear_velocity = Vector3.ZERO
		c.angular_velocity = Vector3.ZERO
		c.global_transform = Transform3D(Basis.looking_at(Vector3(f0.x, 0, f0.z), Vector3.UP), path.point(4) + Vector3.UP * 0.9)
		c.reset_physics_interpolation()
		c.fuel = 40.0
		c.temp = Camper.TEMP_NORMAL
		c.coolant = 1.0
		c.coolant_leak = false
		c.heat_lockout = false
		c.fuel_leak = 0.0
		c.attack.set_tarp(false)
		c.parking_brake = false
		await physics_frames(30)
		await seat_p1_driver()
		var q := p2()
		if q.seat == null:
			q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
		await physics_frames(3)
		if not c.engine_on:
			c.toggle_engine()
		var ad := AutoDriver.new(self, path, c)
		var t := 0.0
		var stuck := 0.0
		var marks := {}          # place -> seconds after J1
		var places := [["j2", 60.0], ["facility", 60.0], ["bridge", 40.0], ["j3", 60.0], ["ghat_pass", 50.0], ["coast_road_stop", 30.0]]
		var fog_max := 0.0
		while t < 1500.0 and ad.idx < stop_at:
			await get_tree().physics_frame
			t += 1.0 / 60.0
			ad.step(-1.0)
			stuck = stuck + 1.0 / 60.0 if kmh() < 2.0 else 0.0
			if stuck > 10.0:
				break
			if ghat != null:
				fog_max = maxf(fog_max, ghat.fog)
			for pl in places:
				var at: Vector3 = b.poi[pl[0]]
				if not marks.has(pl[0]) and Vector2(c.global_position.x - at.x, c.global_position.z - at.z).length() < float(pl[1]):
					marks[pl[0]] = t
			# the water works: the hose splits on the way in; fixed by script
			# (the valves and pump are tested in `waterworks`), which lights
			# the power line
			if c.coolant_leak:
				c.coolant_leak = false
				c.heat_lockout = false
				c.temp = Camper.TEMP_NORMAL
				c.coolant = 1.0
				stn.solved = true
				stn.solved_changed.emit()
			# the bridge: lowered by script before the van gets there (`bridge`
			# tests it for real)
			if not lift.locked and c.global_position.distance_to(b.poi["bridge"]) < 160.0:
				lift.jammed = false
				lift._lock()
			# Last Fuel: the players refuel from the cans there (tested in
			# `story`); by script, the moment the objective asks for it
			if st.current()["id"] == "refuel" or c.fuel < 8.0:
				c.fuel = 45.0
		ad.release()
		key(KEY_S, true)
		await wait(2.0)
		key(KEY_S, false)
		await tap(KEY_SPACE)
		var arrived := ad.idx >= stop_at
		var times := []
		for pl in places:
			times.append("%s %s" % [pl[0], ("%.1f min" % (float(marks[pl[0]]) / 60.0)) if marks.has(pl[0]) else "-"])
		log_line("WAY OUT by %s: arrived=%s in %.1f min driving; %s; fog max %.2f; glimpse %s, attack %s (over %s); objective now '%s'" % [
			route, arrived, t / 60.0, ", ".join(times), fog_max, st.flags.has("ghat_glimpse"), st.flags.has("first_attack"), st.flags.has("first_attack_over"), st.current()["id"]])
		if not arrived:
			await shot("way_out_stuck_" + route)
		check(arrived, "the way out by %s: J1 to the coast watchtower in one drive (%.1f min)" % [route, t / 60.0])
		check(stn.solved and lift.locked and st.flags.has("bridge_down"), "by %s: the water works lit the line and the bridge came down" % route)
		check(fog_max > 0.9 and st.flags.has("ghat_glimpse") and st.flags.has("first_attack"), "by %s: fog on the hairpins, the glimpse, the first creature at the pass" % route)
		var obj: String = st.current()["id"]
		check(obj in ["hide_van", "to_tower", "tower"], "by %s: the story kept up with the drive (now '%s')" % [route, obj])
		await shot("way_out_" + route)
		p1().force_exit = true
		q.force_exit = true
		await physics_frames(4)
		var cr := get_tree().get_root().find_child("FirstCreature", true, false)
		if cr != null:
			cr.queue_free()
		if ghat != null:
			ghat.attacker = null
			ghat.glimpse = null


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
	camper().repair_all()
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


# --- Naresh (the Naresh gym) ---------------------------------------------------------

func nz() -> Naresh:
	return boot.naresh


## Give Naresh a job the way a player does: look at `at`, hold V, point the
## mouse at the job's slice, let go. Returns false if that job wasn't offered.
func naresh_job(p: PlayerRig, at: Vector3, job: String, quick := false) -> bool:
	await look_at_point(p, at)
	key(KEY_V, true)
	await until(func() -> bool: return p.wheel_open, 0.5)
	if not p.wheel_open:
		key(KEY_V, false)
		await physics_frames(2)
		log_line("naresh_job %s: no wheel (looking at %s)" % [job, at])
		return false
	var ids: Array = []
	for j in p.wheel_jobs:
		ids.append(j["id"])
	var i := ids.find(job)
	if i < 0:
		key(KEY_V, false)
		await physics_frames(2)
		log_line("naresh_job %s: not offered, the wheel had %s" % [job, ids])
		return false
	if not quick and ids.size() > 1:
		var a := float(i) * TAU / float(ids.size())
		var dir := Vector2(sin(a), -cos(a))
		for _k in 4:
			mouse(dir * 22.0)
			await physics_frames(1)
		await physics_frames(2)
	elif not quick:
		await wait(0.35)
	var sel_ok := p.wheel_sel == i or (quick and i == 0)
	key(KEY_V, false)
	await physics_frames(3)
	if not sel_ok:
		log_line("naresh_job %s: pointed at slice %d, wheel_sel %d" % [job, i, p.wheel_sel])
	return sel_ok


## Wait (physics time) until `cond` holds, up to `max_s`. True if it did.
func until(cond: Callable, max_s: float) -> bool:
	var t := 0.0
	while t < max_s:
		if cond.call():
			return true
		await get_tree().physics_frame
		t += 1.0 / 60.0
	return cond.call()


func t_naresh() -> void:
	var n := nz()
	check(n != null, "the Naresh gym has Naresh in it")
	if n == null:
		return
	var p := p1()
	var c := camper()
	c.repair_all()
	n.acts_on = false
	n.act_t = 999.0
	n.said.connect(func(t: String): log_line("  Naresh: \"%s\"" % t))
	await place_player(p2(), Vector3(-160, 0.3, 160), 0.0)      # out of the way (and not "with" him)
	await place_player(p, Vector3(-6, 0.25, 40), 0.0)
	n.command(p, "wait")
	n.global_position = Vector3(-3, 0.2, 34)
	n.reset_physics_interpolation()
	await wait(0.5)
	await shot("naresh_start")

	# follow: a quick tap on him
	var since := Time.get_ticks_msec()
	check(await naresh_job(p, n.global_position + Vector3.UP * 1.2, "follow", true), "tapping V on Naresh offers 'Follow me' first")
	check(n.state == Naresh.State.FOLLOW and n.leader == p, "a tap on Naresh: he follows P1")
	check(boot.huds[0].speech_text.begins_with("Naresh:"), "what he says shows on P1's screen (\"%s\")" % boot.huds[0].speech_text)
	await walk_to(p, Vector3(-28, 0, 46), "follow walk", 0.6, 15.0)
	await until(func() -> bool: return n.global_position.distance_to(p.global_position) < 4.5 and n.velocity.length() < 0.5, 8.0)
	var fd := n.global_position.distance_to(p.global_position)
	log_line("after a 23 m walk Naresh is %.1f m from P1" % fd)
	check(fd < 4.5, "he follows P1 on a walk and stops close by (%.1f m)" % fd)
	await shot("naresh_follow")

	# round a wall: P1 behind the hide wall, Naresh in front of it
	await place_player(p, Vector3(-40, 0.25, -36), 0.0)
	n.global_position = Vector3(-40, 0.2, -24)
	n.reset_physics_interpolation()
	since = Time.get_ticks_msec()
	var round_ok := await until(func() -> bool: return n.global_position.distance_to(p.global_position) < 4.5, 20.0)
	check(round_ok and not n.said_since("Found a way round", since), "he walks round a 10 m wall to P1 (no warp; %.1f m)" % n.global_position.distance_to(p.global_position))

	# wait here
	await place_player(p, Vector3(-12, 0.25, 30), 0.0)
	n.global_position = Vector3(-12, 0.2, 27)
	n.reset_physics_interpolation()
	await wait(0.4)
	check(await naresh_job(p, n.global_position + Vector3.UP * 1.2, "wait", true), "following, the tap on him is 'Wait here'")
	var held_at := n.global_position
	await walk_to(p, Vector3(-12, 0, 45), "walk away", 0.6, 10.0)
	await wait(2.0)
	check(n.state == Naresh.State.WAIT and n.global_position.distance_to(held_at) < 1.0, "told to wait, he stays put while P1 walks off")

	# go and wait there: a spot on the ground 12 m away
	var spot := Vector3(-24, 0, 38)
	await place_player(p, Vector3(-12, 0.25, 38), 0.0)
	check(await naresh_job(p, spot, "go", true), "looking at the ground offers 'Go and wait there'")
	var went := await until(func() -> bool: return n.state == Naresh.State.WAIT and Vector2(n.global_position.x - spot.x, n.global_position.z - spot.z).length() < 1.5, 15.0)
	check(went, "he goes to the spot and waits there (%.1f m off)" % Vector2(n.global_position.x - spot.x, n.global_position.z - spot.z).length())

	# the wheel on a full can: refuel / bring / store; bring it to me
	var can := await reset_can("gym_can_full", FuelCan.CAPACITY)
	await place_player(p, can.global_position + Vector3(4, 0.25, 4), 0.0)
	await look_at_point(p, can.global_position + Vector3.UP * 0.25)
	key(KEY_V, true)
	await wait(0.4)
	var ids: Array = []
	for j in p.wheel_jobs:
		ids.append(j["id"])
	check(p.wheel_open and ids == ["refuel", "carry", "store"], "holding V on a full can opens the wheel: %s" % str(ids))
	for _k in 4:
		mouse(Vector2(0.866, 0.5) * 22.0)
		await physics_frames(1)
	await physics_frames(2)
	check(p.wheel_sel == 1, "pointing the mouse at 'Bring it to me' lights it (sel %d)" % p.wheel_sel)
	await shot("naresh_wheel")
	key(KEY_V, false)
	await physics_frames(3)
	check(not p.wheel_open and n.job == "carry", "letting go of V gives him the job")
	var brought := await until(func() -> bool: return p.held == can, 25.0)
	check(brought, "he fetches the can and puts it in P1's hands")
	p.drop_held()
	await physics_frames(10)

	# store the box (the any-item slot) and the empty can (a can slot)
	var box := boot.world.get_node("NareshBox") as CardboardBox
	await place_player(p, box.global_position + Vector3(3, 0.25, 3), 0.0)
	check(await naresh_job(p, box.global_position + Vector3.UP * 0.2, "store"), "a box offers 'Store it on the van'")
	var stored := await until(func() -> bool: return box.stowed_in != null, 30.0)
	check(stored and box.stowed_in == c.storage_slots[2], "he carries the box to the van and stows it in the any-item slot")
	var empty := await reset_can("gym_can_empty", 0.0)
	await place_player(p, empty.global_position + Vector3(3, 0.25, 3), 0.0)
	check(await naresh_job(p, empty.global_position + Vector3.UP * 0.25, "store"), "an empty can offers 'Store it on the van'")
	stored = await until(func() -> bool: return empty.stowed_in != null, 30.0)
	check(stored and empty.stowed_in in [c.storage_slots[0], c.storage_slots[1]], "the empty can goes in a can slot")
	check(empty.holders.is_empty() and box.holders.is_empty(), "on the rack they're out of his hands (anyone can take them)")

	# refuel from the rack, told at the filler
	var can_b := await reset_can("gym_can_full_b", FuelCan.CAPACITY)
	var free := c.free_slot_for(can_b)
	can_b.stow(free)
	c.fuel = 10.0
	await face_point(p, c.filler_point(), 3.0, c.global_transform.basis * Vector3(-1, 0, 0.4))
	check(await naresh_job(p, c.filler_point(), "refuel", true), "the filler offers 'Refuel the van' (a full can on the rack)")
	await until(func() -> bool: return n.state != Naresh.State.JOB, 45.0)
	log_line("refuel: tank %.1f L, can %.1f L, can on the rack %s" % [c.fuel, can_b.litres, can_b.stowed_in != null])
	check(c.fuel > 29.0 and can_b.litres < 0.1, "he pours the rack's full can into the tank (%.1f L)" % c.fuel)
	check(can_b.stowed_in != null, "and puts the empty can back on the rack")

	# the scripted mistake: refuel, and he uses the empty can
	can_b.litres = FuelCan.CAPACITY
	can_b._update_mass()
	can_b._refresh_prompt()
	c.fuel = 10.0
	boot.dev_menu.run("naresh_mistake")
	check(n.refuel_mistake, "the dev menu arms the refuel mistake")
	since = Time.get_ticks_msec()
	check(await naresh_job(p, c.filler_point(), "refuel", true), "refuel again (mistake armed)")
	await until(func() -> bool: return n.state != Naresh.State.JOB, 50.0)
	check(n.said_since("I even checked it twice", since), "he says 'Done. I even checked it twice.'")
	check(c.fuel < 10.5 and can_b.litres > FuelCan.CAPACITY - 0.1 and can_b.stowed_in != null,
		"but the tank didn't move (%.1f L) and the full can is still full, back on the rack" % c.fuel)
	check(not n.refuel_mistake, "the mistake happens once")

	# hold the shutter while P1 goes through; let go and it drops
	var handle := boot.world.get_node("ShutterHandle") as Workable
	var gap: Vector3 = boot.builder.poi["naresh_shutter_gap"]
	n.command(p, "follow")
	await place_player(p, gap + Vector3(-1.5, 0.25, 5.0), 0.0)
	n.global_position = gap + Vector3(-3, 0.2, 6)
	n.reset_physics_interpolation()
	await wait(0.5)
	check(await naresh_job(p, handle.global_position, "hold", true), "the shutter handle offers 'Hold the shutter'")
	var up := await until(func() -> bool: return handle.amount >= 0.99, 15.0)
	check(up, "he walks to the handle and holds the shutter up")
	await shot("naresh_shutter")
	var through := await walk_to(p, gap + Vector3(0, 0, -4), "through the shutter", 0.6, 10.0)
	check(through and p.global_position.z < gap.z - 3.0, "P1 walks under the shutter he holds")
	await walk_to(p, gap + Vector3(0, 0, 4.5), "back through the shutter", 0.6, 10.0)
	check(await naresh_job(p, n.global_position + Vector3.UP * 1.2, "let_go", true), "on him while he holds it: 'Let go' first")
	var down := await until(func() -> bool: return handle.amount <= 0.01, 3.0)
	check(down and n.state != Naresh.State.JOB, "he lets go and the shutter drops")
	# a player can hold it too
	await face_point(p, handle.global_position, 1.0, Vector3(0, 0, 1))
	key(KEY_E, true)
	await wait(1.6)
	check(handle.amount >= 0.99, "P1 can hold the shutter up with E too")
	key(KEY_E, false)
	await wait(1.2)

	# the lever gate: he holds the lever 4 m away, P1 walks through
	var lever := boot.world.get_node("GymLever") as Workable
	var lgap: Vector3 = boot.builder.poi["naresh_lever_gap"]
	await place_player(p, lever.global_position + Vector3(1.0, -0.75, 4.0), 0.0)
	check(await naresh_job(p, lever.global_position, "hold", true), "the lever offers 'Hold the lever'")
	up = await until(func() -> bool: return lever.amount >= 0.99, 15.0)
	check(up, "he holds the lever down and the gate goes up")
	through = await walk_to(p, lgap + Vector3(0, 0, -4), "through the lever gate", 0.6, 12.0)
	check(through, "P1 walks through the lever gate")
	await walk_to(p, lgap + Vector3(0, 0, 4), "back through the lever gate", 0.6, 12.0)
	n.command(p, "follow")      # any new job lets go (the key path is tested above)
	down = await until(func() -> bool: return lever.amount <= 0.01, 3.0)
	check(down, "a new job and he lets go of the lever: the gate drops")

	# work the crank: 8 s and the gate stays up
	var crank := boot.world.get_node("GymCrank") as Workable
	var cgap: Vector3 = boot.builder.poi["naresh_crank_gap"]
	await place_player(p, crank.global_position + Vector3(-1.0, -0.75, 4.0), 0.0)
	since = Time.get_ticks_msec()
	check(await naresh_job(p, crank.global_position, "work", true), "the crank offers 'Work the crank'")
	var cranked := await until(func() -> bool: return crank.is_done, 25.0)
	await physics_frames(3)      # he says so on his next step
	check(cranked and n.said_since("done", since), "he cranks it up and says it's done")
	await wait(1.0)
	through = await walk_to(p, cgap + Vector3(0, 0, -4), "through the crank gate", 0.6, 12.0)
	check(through, "the crank gate stays up: P1 walks through")
	await place_player(p, cgap + Vector3(0, 0.25, 6), 0.0)

	# impossible jobs: someone else picks it up; it vanishes
	can = await reset_can("gym_can_full", FuelCan.CAPACITY)
	await place_player(p, can.global_position + Vector3(5, 0.25, 5), 0.0)
	n.global_position = can.global_position + Vector3(-14, 0.2, 10)
	n.reset_physics_interpolation()
	await physics_frames(5)
	check(await naresh_job(p, can.global_position + Vector3.UP * 0.25, "carry"), "bring the can (again)")
	await wait(0.5)
	await face_point(p, can.global_position + Vector3.UP * 0.25, 1.2)
	p.pick_up(can)
	since = Time.get_ticks_msec()
	var gave_up := await until(func() -> bool: return n.state != Naresh.State.JOB, 5.0)
	check(gave_up and n.said_since("got it already", since), "someone else takes it: he says so and stops")
	p.drop_held()
	await physics_frames(10)
	var jug := boot.world.get_node("CoolantJug") as Carryable
	await place_player(p, jug.global_position + Vector3(4, 0.25, 4), 0.0)
	n.command(p, "wait")
	n.global_position = jug.global_position + Vector3(-10, 0.2, 12)
	n.reset_physics_interpolation()
	await physics_frames(5)
	check(await naresh_job(p, jug.global_position + Vector3.UP * 0.2, "carry"), "bring the coolant jug")
	jug.queue_free()
	since = Time.get_ticks_msec()
	gave_up = await until(func() -> bool: return n.state != Naresh.State.JOB, 3.0)
	check(gave_up and n.said_since("gone", since), "the jug vanishes: 'It's gone.' and he stops (never silent)")

	# get in the back, ride along, get out
	await reset_camper(0)
	await place_player(p, c.global_transform * Vector3(5, 0, 0) + Vector3.UP * 0.3, 0.0)
	n.global_position = c.global_transform * Vector3(8, 0, 4) + Vector3.UP * 0.3
	n.reset_physics_interpolation()
	await physics_frames(5)
	check(await naresh_job(p, c.global_position + Vector3.UP * 0.8, "get_in", true), "the van offers 'Get in the back'")
	var sat := await until(func() -> bool: return n.state == Naresh.State.SEATED, 20.0)
	check(sat and n.van == c and n.global_position.distance_to(c.bench.global_position) < 0.05, "he walks to the door and sits on the bench")
	await face_point(p, c.global_transform * Vector3(0, 0.6, 1.5), 4.0, c.global_transform.basis * Vector3(1, 0, 0.2))
	await shot("naresh_bench")
	await seat_p1_driver()
	await tap(KEY_V)
	await wait(0.3)
	check(not p.wheel_open and boot.huds[0]._note.visible and boot.huds[0]._note_text.text.contains("Only the passenger"), "the driver's V says only the passenger gives jobs")
	await tap(KEY_X)
	await wait(1.0)
	c.set_parking_brake(false)
	hold_physics(KEY_W, 3.0)
	await wait(3.2)
	key(KEY_S, true)
	await until(func() -> bool: return c.linear_velocity.length() < 0.3, 6.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)
	await tap(KEY_X)
	await wait(0.5)
	check(n.state == Naresh.State.SEATED and n.global_position.distance_to(c.bench.global_position) < 0.05, "he rides along on the bench")
	await tap(KEY_C)
	await wait(0.5)
	check(p.seat_role == "passenger", "P1 swaps to the passenger seat")
	p._seat_yaw = deg_to_rad(120.0)
	await physics_frames(3)
	var look := p.command_look(n)
	check(look.get("col") == n, "from the passenger seat, looking round at the bench, the wheel is for Naresh")
	key(KEY_V, true)
	await physics_frames(4)
	var ok_out: bool = p.wheel_open and p.wheel_jobs.size() > 0 and p.wheel_jobs[0]["id"] == "get_out"
	key(KEY_V, false)
	await physics_frames(4)
	var out := await until(func() -> bool: return n.state != Naresh.State.SEATED, 2.0)
	var gy := Landscape.ground(n.global_position.x, n.global_position.z)
	check(ok_out and out and absf(n.global_position.y - gy) < 0.6, "'Get out' from the passenger seat: he's out, on the ground")
	p._seat_yaw = 0.0

	# following into the van and out again, by himself
	await tap(KEY_E)
	await wait(0.5)
	n.command(p, "follow")
	await wait(1.0)
	await seat_p1_driver()
	sat = await until(func() -> bool: return n.state == Naresh.State.SEATED, 15.0)
	check(sat, "following P1, he gets in the back when P1 gets in")
	await tap(KEY_E)
	await wait(0.4)
	var away := p.global_position - c.global_position
	away.y = 0.0
	await walk_to(p, p.global_position + away.normalized() * 10.0, "away from the van", 0.6, 6.0)
	var followed := await until(func() -> bool: return n.state == Naresh.State.FOLLOW and n.global_position.distance_to(p.global_position) < 6.0, 12.0)
	check(followed, "and gets out and follows when P1 walks off")

	# a pad player: D-Up opens the wheel
	boot._on_joy_changed(0, true)
	await physics_frames(3)
	var q := p2()
	await place_player(q, n.global_position + Vector3(0, 0.2, 5), 0.0)
	await look_at_point(q, n.global_position + Vector3.UP * 1.2)
	pad_button(JOY_BUTTON_DPAD_UP, true)
	await until(func() -> bool: return q.wheel_open, 0.5)
	check(q.wheel_open, "P2 on a pad: D-Up opens the wheel")
	log_line("P2's wheel: %s, sel %d" % [str(q.wheel_jobs), q.wheel_sel])
	pad_button(JOY_BUTTON_DPAD_UP, false)
	await physics_frames(4)
	log_line("after D-Up: wheel %s, Naresh %s following P%d" % [q.wheel_open, Naresh.State.keys()[n.state], n.leader.index + 1 if n.leader else 0])
	check(n.leader == q and n.state == Naresh.State.FOLLOW, "and a tap on him makes him follow P2 (the last command wins)")
	await _unplug_test_pad()
	await place_player(q, Vector3(-160, 0.3, 160), 0.0)
	n.command(p, "follow")

	# random acts, sped up: each announced 3 s before; good and bad. By the
	# van, 20 m from the hidden can (the good act that fits here)
	boot.dev_menu.van_to(Vector3(-28, 0, -12), 0.0)
	await physics_frames(30)
	await place_player(p, c.global_transform * Vector3(6, 0, 3) + Vector3.UP * 0.3, 0.0)
	n.global_position = p.global_position + Vector3(2, 0, 0)
	n.reset_physics_interpolation()
	n.acts_log.clear()
	n.act_gap = Vector2(3.0, 4.0)
	n.act_t = 1.0
	n.acts_on = true
	var t0 := Time.get_ticks_msec()
	var honked := false
	var cut := {}
	while Time.get_ticks_msec() - t0 < 110000:
		await get_tree().physics_frame
		if c.attack.is_honking():
			honked = true
		# a wander takes half a minute; call him back after a few seconds
		if n.state == Naresh.State.ACT and n.act == "wander" and not cut.has(n.acts_log.size()):
			await wait(3.0)
			n.command(p, "follow")
			cut[n.acts_log.size()] = true
		var started := 0
		var good := 0
		var bad := 0
		for a in n.acts_log:
			if int(a["start"]) > 0:
				started += 1
				if a["good"]:
					good += 1
				else:
					bad += 1
		if started >= 4 and good >= 1 and bad >= 1 and n.state != Naresh.State.ACT:
			break
	await wait(0.5)      # an act that just started (the honk) acts on the van's next step
	var lead_ok := true
	var summary := []
	var good_n := 0
	var bad_n := 0
	for a in n.acts_log:
		summary.append("%s%s" % [a["id"], "" if int(a["start"]) > 0 else "(dropped)"])
		if int(a["start"]) > 0:
			var lead := (int(a["start"]) - int(a["tele"])) / 1000.0
			if lead < 2.7 or lead > 3.6:
				lead_ok = false
				log_line("act %s announced %.2f s before" % [a["id"], lead])
			if a["good"]:
				good_n += 1
			else:
				bad_n += 1
	log_line("random acts: %s" % ", ".join(summary))
	check(good_n >= 1 and bad_n >= 1, "random acts: both good and bad ones happen (%d good, %d bad)" % [good_n, bad_n])
	check(lead_ok and not n.acts_log.is_empty(), "every act is announced about 3 s before it starts")
	var hidden := find_can("gym_hidden_can")
	var found_it := false
	for a in n.acts_log:
		if a["id"] == "find_can" and int(a["start"]) > 0:
			found_it = true
	if found_it:
		await until(func() -> bool: return n.state != Naresh.State.ACT, 40.0)
		check(hidden.stowed_in != null or hidden.global_position.distance_to(c.global_position) < 8.0, "his 'I know where one is' act brings the hidden can to the van")
	var did_honk := false
	for a in n.acts_log:
		if a["id"] == "honk" and int(a["start"]) > 0:
			did_honk = true
	if did_honk:
		check(honked or c.attack.last_honk_ms > t0, "his honk act sounds the van's horn")
	# not in the timed zone
	var calm: Vector3 = boot.builder.poi["naresh_calm"]
	n.acts_on = false
	await place_player(p, calm + Vector3(1, 0.25, 0), 0.0)
	n.command(p, "wait")
	n.global_position = calm + Vector3(-1, 0.2, 0)
	n.reset_physics_interpolation()
	var before := n.acts_log.size()
	n.act_t = 0.5
	n.acts_on = true
	await wait(7.0)
	check(n.acts_log.size() == before, "no random act in the timed zone (%d new)" % (n.acts_log.size() - before))
	await place_player(p, calm + Vector3(0, 0.25, 22), 0.0)
	n.global_position = calm + Vector3(2, 0.2, 22)
	n.reset_physics_interpolation()
	n.act_t = 0.5
	var came := await until(func() -> bool: return n.acts_log.size() > before, 30.0)
	check(came, "out of the zone, the acts carry on")
	await until(func() -> bool: return n.state != Naresh.State.ACT and n._tele_t <= 0.0, 40.0)
	n.command(p, "wait")
	n.act_gap = Naresh.ACT_GAP
	var gap_ok := n.act_now()
	await until(func() -> bool: return n._tele_t <= 0.0, 5.0)
	check(n.act_t >= 180.0 and n.act_t <= 360.0 and gap_ok, "at the real setting the next act is 3-6 min away (%.0f s)" % n.act_t)
	n.acts_on = false
	n.command(p, "follow")
	await wait(0.5)

	# every other act once, each set up so it fits (act_now still announces it)
	n.acts_on = true
	n.act_t = 999.0
	var near_van := c.global_transform * Vector3(5, 0, 2) + Vector3.UP * 0.3
	await place_player(p, near_van + Vector3(3, 0, 0), 0.0)
	n.command(p, "wait")
	n.global_position = near_van
	n.reset_physics_interpolation()
	c.attack.set_tarp(true)
	since = Time.get_ticks_msec()
	check(n.act_now("tarp_off"), "act: 'pull the tarp off' fits with the van under it")
	var untarped := await until(func() -> bool: return not c.attack.tarped, 15.0)
	check(untarped and n.said_since("can't breathe", since), "he says the van can't breathe, and pulls the tarp off")
	await until(func() -> bool: return n.state != Naresh.State.ACT, 5.0)
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	mood.set_now(0.3)
	c.set_headlights(false)
	check(n.act_now("headlights"), "act: 'headlights on' fits at dusk by the van")
	var lit := await until(func() -> bool: return c.headlights_on, 5.0)
	check(lit, "he switches the headlights on")
	c.set_headlights(false)
	mood.set_now(1.0)
	check(not n.act_now("headlights"), "not in daylight")
	c.puncture()
	c.set_parking_brake(true)
	await wait(0.5)
	check(n.act_now("fix_tyre"), "act: 'fix the flat' fits with the van parked on a flat")
	var fixed := await until(func() -> bool: return not c.tyre_flat, 45.0)
	check(fixed and n.said_since("Sort of", since), "he fixes the flat by himself ('Sort of.')")
	c.repair_all()
	await until(func() -> bool: return n.state != Naresh.State.ACT, 5.0)
	# holding the shutter for P1, unasked
	handle.amount = 0.0
	await place_player(p, gap + Vector3(0, 0.25, 3), PI)
	n.command(p, "wait")
	n.global_position = gap + Vector3(-6, 0.2, 6)
	n.reset_physics_interpolation()
	await physics_frames(3)
	check(n.act_now("hold_door"), "act: 'hold the door' fits with P1 at the shutter")
	up = await until(func() -> bool: return handle.amount >= 0.99, 15.0)
	check(up, "he holds the shutter up for P1 without being asked")
	n.command(p, "follow")
	await until(func() -> bool: return handle.amount <= 0.01, 3.0)
	# spotting a creature, with a tag on it
	var crt := boot.world.get_node("GymCreature") as Creature
	crt.dormant = false
	n.command(p, "wait")
	n.global_position = GymBuilder.NARESH_CREATURE + Vector3(-40, 0.2, 10)
	n.reset_physics_interpolation()
	await place_player(p, n.global_position + Vector3(-4, 0.05, 0), 0.0)
	p.taken_grace = 30.0
	check(n.act_now("spot_creature"), "act: 'someone's watching us' fits with a creature 40 m off")
	await wait(3.4)
	var tagm := TagMarker.of(p.index)
	check(tagm != null and tagm.global_position.distance_to(crt.global_position + Vector3.UP * 2.0) < 3.0, "he tags the creature for P1")
	crt.dormant = true
	crt.global_position = GymBuilder.NARESH_CREATURE
	crt.reset_physics_interpolation()
	p.taken_grace = 0.0
	# dropping what he carries, halfway to the van
	var crate := boot.world.get_node("Crate0") as Carryable
	await place_player(p, crate.global_position + Vector3(3, 0.25, 3), 0.0)
	n.command(p, "wait")
	n.global_position = crate.global_position + Vector3(4, 0.2, -2)
	n.reset_physics_interpolation()
	await physics_frames(3)
	check(await naresh_job(p, crate.global_position + Vector3.UP * 0.3, "store"), "store a crate")
	var carrying := await until(func() -> bool: return n.held == crate, 15.0)
	await wait(1.0)
	check(carrying and n.act_now("drop_it"), "act: 'drop it' fits while he carries something")
	await wait(3.4)
	await until(func() -> bool: return n.state != Naresh.State.JOB, 2.0)
	check(n.held == null and crate.holders.is_empty() and n.state != Naresh.State.JOB, "he drops it ('Oops') and says so; it lies there for anyone to pick up")
	n.acts_on = false
	# knocked by the van: over he goes, and up again
	boot.dev_menu.van_to(Vector3(-28, 0, -12), 0.0)
	await physics_frames(30)
	n.command(p, "wait")
	n.global_position = c.global_transform * Vector3(0, 0, -20) + Vector3.UP * 0.2
	n.global_position.y = Landscape.ground(n.global_position.x, n.global_position.z) + 0.2
	n.reset_physics_interpolation()
	await seat_p1_driver()
	await tap(KEY_X)
	await wait(0.8)
	var knocked := false
	key(KEY_W, true)
	var kt := 0.0
	while kt < 8.0 and not knocked:
		await get_tree().physics_frame
		kt += 1.0 / 60.0
		knocked = n.state == Naresh.State.KNOCKED
	key(KEY_W, false)
	key(KEY_S, true)
	await until(func() -> bool: return c.linear_velocity.length() < 0.3, 6.0)
	key(KEY_S, false)
	await tap(KEY_SPACE)
	await tap(KEY_X)
	check(knocked, "driving into him knocks him over (%.0f km/h)" % kmh())
	since = Time.get_ticks_msec() - 8000
	var up_again := await until(func() -> bool: return n.state != Naresh.State.KNOCKED, 8.0)
	check(up_again and n.said_since("Ow!", since), "and he gets up: 'Ow! I'm fine!'")
	await tap(KEY_E)
	await wait(0.4)

	# left alone near a creature, he's taken and left high up far away
	var cr := boot.world.get_node("GymCreature") as Creature
	var sw: Vector3 = boot.builder.poi["creature_switch"]
	await face_point(p, sw, 1.6, Vector3(0, 0, 1))
	await tap(KEY_E)
	check(not cr.dormant, "the switch wakes the creature (with E)")
	var pen: Vector3 = GymBuilder.NARESH_CREATURE
	n.command(p, "wait")
	n.global_position = pen + Vector3(0, 0.2, 26)
	n.reset_physics_interpolation()
	await place_player(p, pen + Vector3(-60, 0.25, 70), 0.0)
	var drawn := false
	var tk := 0.0
	while tk < 45.0 and n.state != Naresh.State.TAKEN:
		await get_tree().physics_frame
		tk += 1.0 / 60.0
		drawn = drawn or cr.naresh_drawn
	check(drawn, "the creature drifts towards Naresh")
	check(n.state == Naresh.State.TAKEN, "alone (nobody within 12 m), he's taken (%.0f s)" % tk)
	var drop := Vector3(80, 5, -300)
	check(n.global_position.distance_to(drop) < 2.0, "and left on the tall platform, %.0f m away" % (pen + Vector3(0, 0, 26)).distance_to(drop))
	await wait(2.5)
	check(boot.huds[0].speech_text.contains("Over here"), "he shouts, and P1 reads it %.0f m away" % p.global_position.distance_to(n.global_position))
	await place_player(p, drop + Vector3(-2, -5, 30), 0.0)
	await look_at_point(p, n.global_position + Vector3.UP * 1.5)
	n.say("Over here! By the tall platform! My friend's with me, don't worry.", true)
	await wait(0.2)
	await shot("naresh_taken")
	await place_player(p, drop + Vector3(-3.5, -4.75, 0), 0.0)
	var fetched := await until(func() -> bool: return n.state == Naresh.State.FOLLOW, 3.0)
	check(fetched and n.global_position.y < 1.0, "walking up to the platform fetches him down")

	# with a player close by he's safe: it only circles
	n.command(p, "wait")
	n.global_position = pen + Vector3(0, 0.2, 26)
	n.reset_physics_interpolation()
	await place_player(p, pen + Vector3(5, 0.25, 26), 0.0)
	p.taken_grace = 60.0      # this is about him, not P1
	drawn = false
	tk = 0.0
	while tk < 25.0:
		await get_tree().physics_frame
		tk += 1.0 / 60.0
		drawn = drawn or cr.naresh_drawn
	check(drawn and n.state != Naresh.State.TAKEN, "with P1 beside him the creature circles but never takes him")
	cr.dormant = true
	p.taken_grace = 0.0

	# save and load his state; a bad spot puts him on the bench
	n.command(p, "follow")
	var d := n.save_state()
	n.global_position += Vector3(30, 0, 0)
	n.load_state(d, boot.players, c)
	check(n.state == Naresh.State.FOLLOW and n.global_position.distance_to(Vector3(d["pos"][0], d["pos"][1], d["pos"][2])) < 0.1, "his state saves and loads (place, following P1)")
	d["pos"] = [0.0, -60.0, 0.0]
	d["seated"] = false
	n.load_state(d, boot.players, c)
	check(n.state == Naresh.State.SEATED, "a save with him somewhere bad puts him on the van's bench")
	n.command(p, "get_out")
	await wait(0.5)
	var fps := Engine.get_frames_per_second()
	log_line("fps with Naresh about: %d" % fps)


## E2, Bessi beach: the nav loses its signal coming in, the mood falls to
## dusk at the beach, the stalls and lamps are lit, the radio plays, the
## promenade walks on and off, and from the photo spot the lighthouse's lamp
## stands just over the memorial's spire (E3's photo). `tools/run_test.sh beach`
func t_beach() -> void:
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	c.repair_all()
	var bessi := get_tree().get_first_node_in_group("bessi") as Bessi
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	check(bessi != null, "Bessi beach is built")
	if bessi == null:
		return
	var p := p1()
	var nav: Label3D = c._needles["nav_label"]
	# the nav: fine at the coast watchtower, no signal in Bessi
	mood.set_now(0.62)
	boot.dev_menu.van_to(boot.dev_menu.van_spot(poi["coast_tower"] + Vector3(30, 0, 30)), 0.0)
	await physics_frames(30)
	await seat_p1_driver()
	await wait(1.0)
	check(not c.nav_signal_lost and not nav.text.contains("SIGNAL"), "at the coast watchtower the nav works (\"%s\")" % nav.text.replace("\n", " / "))
	boot.dev_menu.van_to(boot.dev_menu.van_spot(poi["beach"] + Vector3(-45, 0, 0)), PI * 0.5)
	await physics_frames(30)
	await seat_p1_driver()
	var seen := {}
	var tt := 0.0
	while tt < 3.0:
		await get_tree().physics_frame
		tt += 1.0 / 60.0
		seen[nav.text] = true
	log_line("nav in Bessi showed: %s" % str(seen.keys()).replace("\n", " / "))
	check(c.nav_signal_lost and seen.keys().any(func(t): return String(t).contains("NO SIGNAL")), "in Bessi the nav loses its signal (\"NO SIGNAL\", flickering)")
	await shot("beach_arrival")
	await tap(KEY_E)
	await wait(0.4)

	# dusk at the beach
	await place_player(p, poi["beach"] + Vector3(0, 0.3, 0), -PI * 0.5)
	var dusk := await until(func() -> bool: return mood.target <= 0.41, 8.0)
	check(dusk, "at the beach the mood falls to dusk (target %.2f)" % mood.target)
	mood.set_now(0.4)

	# the stalls and lamps lit, the radio playing by its stall
	check(bessi.lights.size() >= 20, "the stalls and lamps have their lights (%d)" % bessi.lights.size())
	check(bessi.radio != null and bessi.radio.playing and bessi.radio.stream != null, "a radio plays in one stall")
	await place_player(p, poi["radio_stall"] + Vector3(0, 0.3, 0), PI * 0.5)
	check(p.global_position.distance_to(bessi.radio.global_position) < bessi.radio.max_distance * 0.5, "you can hear it standing at its stall")
	await look_at_point(p, bessi.radio.global_position)
	await shot("beach_radio_stall")

	# the promenade: along it, and up onto it from the sand
	var north: Vector3 = poi["promenade_north"]
	await place_player(p, north + Vector3(0, 0.3, 0), PI)
	await shot("beach_promenade")
	var along := await walk_to(p, north + Vector3(Bessi.shore_x(north.z + 60.0) - Bessi.shore_x(north.z), 0, 60.0), "along the promenade", 0.8, 25.0)
	check(along, "you can walk 60 m along the promenade")
	var z := north.z + 60.0
	var sand := Vector3(Bessi.shore_x(z) - 30.0, 0, z)
	sand.y = Landscape.ground(sand.x, sand.z) + 0.3
	await place_player(p, sand, PI * 0.5)
	var onto := await walk_to(p, Vector3(Bessi.shore_x(z) - 50.0, 0, z), "onto the promenade", 0.8, 12.0)
	check(onto, "and step up onto it from the sand without jumping")

	# the photo spot: the lamp just over the spire
	var spot: Vector3 = poi["photo_spot"]
	var tip: Vector3 = poi["memorial_spire"]
	var lamp: Vector3 = poi["lighthouse_lamp"]
	var eye := spot + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16 - 0.1)
	var yaw_tip := atan2(tip.x - eye.x, tip.z - eye.z)
	var yaw_lamp := atan2(lamp.x - eye.x, lamp.z - eye.z)
	var el_tip := rad_to_deg(atan2(tip.y - eye.y, Vector2(tip.x - eye.x, tip.z - eye.z).length()))
	var el_lamp := rad_to_deg(atan2(lamp.y - eye.y, Vector2(lamp.x - eye.x, lamp.z - eye.z).length()))
	log_line("photo spot: spire at %.2f deg up, lamp %.2f deg up, %.2f deg apart sideways; memorial %.0f m, lighthouse %.0f m" % [
		el_tip, el_lamp, rad_to_deg(absf(angle_difference(yaw_tip, yaw_lamp))), eye.distance_to(tip), eye.distance_to(lamp)])
	check(rad_to_deg(absf(angle_difference(yaw_tip, yaw_lamp))) < 0.3 and el_lamp > el_tip and el_lamp - el_tip < 0.8,
		"from the photo spot the lighthouse's lamp stands just over the memorial's spire")
	var q := PhysicsRayQueryParameters3D.create(eye, lamp.lerp(eye, 4.0 / eye.distance_to(lamp)), 1 | 8)
	q.exclude = [p.get_rid()]
	var edge := boot.world.get_node_or_null("WorldEdge") as CollisionObject3D
	if edge != null:
		q.exclude = [p.get_rid(), edge.get_rid()]     # the invisible wall out at sea hides nothing
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		log_line("the line to the lamp hits %s at %s (%.0f m from the spot)" % [(hit["collider"] as Node).get_path(), hit["position"], eye.distance_to(hit["position"])])
	var mem := boot.world.find_child("Memorial", true, false) as Node3D
	log_line("memorial column at %s, spot %s, tip %s, lamp %s" % [(mem.get_node("Column") as Node3D).global_position if mem else Vector3.ZERO, spot, tip, lamp])
	check(hit.is_empty(), "nothing solid between the photo spot and the lamp")
	await place_player(p, spot + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, (tip + lamp) * 0.5)
	await shot("beach_photo_view")
	# a step to the side: the lighthouse comes out from behind the spire
	var side := Vector3(-(lamp - spot).z, 0, (lamp - spot).x).normalized() * 6.0
	await place_player(p, spot + side + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, (tip + lamp) * 0.5)
	await shot("beach_photo_off")

	# the frame rate at dusk, both views
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	await place_player(p2(), north + Vector3(1.5, 0.3, 2.0), PI)
	await place_player(p, north + Vector3(-1.5, 0.3, 0.0), PI)
	await wait(1.0)
	_frame_times.clear()
	await wait(3.0)
	var avg := 0.0
	for f in _frame_times:
		avg += f
	var fps := float(_frame_times.size()) / maxf(avg, 0.001)
	log_line("fps on the promenade at dusk, both views: %.0f" % fps)
	check(headless or fps >= 110.0, "the lit promenade at dusk keeps the frame rate (%.0f fps)" % fps)
	await shot("beach_dusk_split")
	mood.set_now(0.62)


## The storm gym (F1, design/RETURN.md). `GYM=storm tools/run_test.sh storm_gym`
func storm() -> Storm:
	return get_tree().get_first_node_in_group("storm") as Storm


## Put the van at the west end of the straight, P1 driving, the engine on.
func storm_start() -> void:
	var c := camper()
	c.repair_all()
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.global_transform = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(-290, Landscape.ground(-290, 250) + 0.9, 250))
	c.snap_visuals()
	c.parking_brake = true
	await wait(1.2)
	await seat_p1_driver()
	if not c.engine_on:
		await tap(KEY_X)
	await wait(0.3)


func storm_roll() -> float:
	return rad_to_deg(acos(clampf(camper().global_transform.basis.y.y, -1.0, 1.0)))


## Drive the straight at `kmh_want`, let go of the wheel, blow one gust across
## it. Returns [sideways m, most roll deg, tipped]. A tipped van is left lying.
func storm_run(kmh_want: float, strength := 1.0) -> Array:
	var c := camper()
	var s := storm()
	await storm_start()
	var ad := AutoDriver.new(self, boot.builder.network.road("gym_straight"), c)
	var t0 := Time.get_ticks_msec()
	# up to speed on the line, steadied for 2 s
	var steady := 0.0
	while Time.get_ticks_msec() - t0 < 30000 and steady < 2.0:
		await physics_frames(1)
		ad.step(kmh_want)
		if absf(kmh() - kmh_want) < 3.0 and absf(c.global_position.z - 250.0) < 0.4:
			steady += 1.0 / 60.0
	ad.release()
	var z0 := c.global_position.z
	var most := 0.0
	var tipped := false
	s.gust_now(strength, Vector3(0, 0, -1))
	var tt := 0.0
	while tt < 5.5:
		await physics_frames(1)
		tt += 1.0 / 60.0
		# hold the speed with the throttle only, hands off the wheel
		key(KEY_W, kmh() < kmh_want and not tipped)
		most = maxf(most, storm_roll())
		if storm_roll() > 60.0:
			tipped = true
	key(KEY_W, false)
	var side := absf(c.global_position.z - z0)
	var rest := -1.0
	if tipped:
		# where does it come to rest: on its side, or back on its wheels?
		await until(func() -> bool: return c.linear_velocity.length() < 0.5 and c.angular_velocity.length() < 0.3, 6.0)
		rest = storm_roll()
		tipped = rest > 60.0
	log_line("storm gust %.0f%% at %.0f km/h: pushed %.2f m sideways, most roll %.1f deg%s" % [strength * 100.0, kmh_want, side, most,
		(", came to rest at %.0f deg: %s" % [rest, "ON ITS SIDE" if tipped else "back on its wheels"]) if rest >= 0.0 else ""])
	if not tipped:
		key(KEY_S, true)
		await until(func() -> bool: return kmh() < 2.0, 8.0)
		key(KEY_S, false)
	return [side, most, tipped]


func storm_leave() -> void:
	var c := camper()
	if c.global_transform.basis.y.y < 0.9:
		c.recover()
	p1().force_exit = true
	p2().force_exit = true
	await physics_frames(3)


func t_storm_sweep() -> void:
	storm().auto_gusts = false
	storm().auto_flashes = false
	for spec in [[42.0, 1.0], [45.0, 1.0], [50.0, 1.0], [55.0, 1.0], [60.0, 1.0], [50.0, 0.85], [60.0, 0.85]]:
		await storm_run(spec[0], spec[1])
		await storm_leave()


## F2, the storm on the old road (Bessi -> ghat -> J3 -> the bridge): where
## it is, the dead end at the bridge, his line. `tools/run_test.sh storm_road`
func t_storm_road() -> void:
	var st: Story = boot.story
	var front := boot.world.get_node("StormFront") as StormFront
	var s := storm()
	var lift := get_tree().get_first_node_in_group("lift_bridge") as LiftBridge
	var line := get_tree().get_first_node_in_group("power_line") as PowerLine
	check(front != null and s != null and lift != null and line != null, "the world has the storm, the bridge and the power line")
	if s == null:
		return
	var poi: Dictionary = boot.builder.poi
	# its own start: the step before the storm (t_storm may have left it on)
	boot.dev_menu.run("jump", st.index_of("drum"))
	await wait(1.0)
	check(front.storm_at(poi["ghat_pass"]) == 0.0, "before the storm starts there is none")
	boot.dev_menu.run("jump", st.index_of("storm"))
	await wait(1.0)
	check(front.started and st.flags.has("storm_on"), "the jump to the storm step starts it")
	# where it is: the old way, not the way north
	var on_way := []
	for k in ["ghat_pass", "j3", "bridge"]:
		on_way.append("%s %.2f" % [k, front.storm_at(poi[k])])
	var coast: Route = boot.builder.network.road("coast_road")
	var worst := 0.0
	var roses: Vector3 = poi["roses"]
	for i in range(0, coast.point_count(), 5):
		var q := coast.point(i)
		if Vector2(q.x - roses.x, q.z - roses.z).length() > 350.0:
			if front.storm_at(q) > worst:
				var near := INF
				var at := Vector3.ZERO
				for z in front._zone:
					if Vector2(z.x - q.x, z.z - q.z).length() < near:
						near = Vector2(z.x - q.x, z.z - q.z).length()
						at = z
				log_line("  coast %s (%.0f m from the roses): %.2f, %.0f m from the old way at %s" % [q, Vector2(q.x - roses.x, q.z - roses.z).length(), front.storm_at(q), near, at])
			worst = maxf(worst, front.storm_at(q))
	log_line("storm at: %s; worst on the coast road north (past 350 m): %.2f" % [", ".join(on_way), worst])
	check(front.storm_at(poi["ghat_pass"]) > 0.99 and front.storm_at(poi["j3"]) > 0.99 and front.storm_at(poi["bridge"]) > 0.9, "the storm sits over the ghat, J3 and the bridge")
	check(worst < 0.01, "the coast road north is clear of it")
	check(s.intensity < 0.1, "at the start of the coast road it's not storming (%.2f)" % s.intensity)
	# the bridge: up, dead, barred
	await physics_frames(3)
	check(lift.storm_blown and lift.angle > 60.0 and lift.barriers.visible, "the bridge's leaf is up again, the barriers back (%.0f deg)" % lift.angle)
	check(line.cut and not line.hut_powered and lift.panel_label.text == "NO POWER", "the power line is down: the hut says NO POWER")
	# drive in: the van at the bridge, everyone aboard
	var c := camper()
	c.repair_all()
	await van_to(poi["bridge_barrier_near"])
	await seat_p1_driver()
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	var n := nz()
	n.global_position = c.global_transform * Vector3(0, -0.3, 6.5)     # on the road behind it
	await wait(0.5)
	n.command(p1(), "get_in", c)
	await until(func() -> bool: return n.state == Naresh.State.SEATED, 10.0)
	await until(func() -> bool: return s.intensity > 0.95, 8.0)
	check(s.intensity > 0.95 and c.wet > 0.9, "at the bridge it storms: the road is wet (%.2f)" % s.intensity)
	check(front.at_bridge, "they're told: the leaf is up, the lamps dark, no way across")
	await look_at_point(p1(), poi["lift_pivot"] + Vector3(0, 6, 0))
	await shot("storm_bridge")
	# back up the road: his line
	await van_to(poi["ghat_pass"])
	await wait(0.5)
	check(front.said_north and n.state == Naresh.State.SEATED, "back on the ghat, Naresh: 'My friend said north.'")
	check(not c.coolant_leak and st.flags.has("first_attack"), "the way out's one-offs don't happen again (no burst hose, no second first attack)")
	check(get_tree().get_nodes_in_group("creature").filter(func(x): return (x as Node3D).global_position.distance_to(c.global_position) < 80.0).is_empty(), "no creature comes for the van on the ghat")
	await shot("storm_ghat")
	# P2 left in the storm at the bridge, P1 and the van up the coast road:
	# only P2 gets the storm (it rained on P1, gusts and all)
	p1().force_exit = true
	await physics_frames(3)
	await place_player(p2(), poi["bridge_barrier_near"] + Vector3(0, 0.5, 0), 0.0)
	var north_at := coast.point(int(coast.nearest(1660.0, -600.0)["index"]))
	await van_to(north_at)
	await place_player(p1(), c.global_transform * Vector3(-3.2, 0, 0) + Vector3(0, 0.5, 0), 0.0)
	boot._set_layout(Boot.Layout.SOLO)
	await wait(6.0)
	var rain1 := s._rain.get(p1(), []) as Array
	var rain2 := s._rain.get(p2(), []) as Array
	log_line("split up: P1 %.2f, P2 %.2f, the van %.2f, on screen %.2f; the van wet %.2f" % [s.local(p1()), s.local(p2()), s.local(c), s.intensity, c.wet])
	check(s.local(p1()) < 0.05 and s.local(c) < 0.05 and c.wet < 0.05 and s.intensity < 0.05, "P2 left at the bridge: up the coast road P1 and the van are dry, no gusts")
	check(rain1.is_empty() or not (rain1[0] as GPUParticles3D).emitting, "no rain on P1")
	check(s.local(p2()) > 0.5 and not rain2.is_empty() and (rain2[0] as GPUParticles3D).emitting, "it still rains on P2 at the bridge")
	# a jump back before the storm puts it all away
	p1().force_exit = true
	p2().force_exit = true
	await physics_frames(3)
	boot.dev_menu.run("jump", st.index_of("drum"))
	await wait(1.0)
	await physics_frames(3)
	check(not front.started and not lift.storm_blown and not line.cut, "a jump back before the storm: the bridge and the power as they were")
	check(lift.locked == st.flags.has("bridge_down"), "the leaf as the story left it (locked %s)" % lift.locked)


## F3, the fishing village and R1 the decoy (design/RETURN.md decision 5).
## `tools/run_test.sh decoy`
func t_decoy() -> void:
	var st: Story = boot.story
	var fv := get_tree().get_first_node_in_group("fishing_village") as FishingVillage
	check(fv != null and fv.creatures.size() == 2 and fv.can_full != null and fv.can_empty != null, "the village: two creatures, the shed with two cans")
	if fv == null:
		return
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	var p := p1()
	var q := p2()
	boot.dev_menu.run("jump", st.index_of("village"))
	await wait(1.0)
	var n := nz()
	check(st.current()["id"] == "village" and c.fuel <= FishingVillage.LOW_FUEL + 0.01 and Creature.on_return, "F1 jump: short of the village on the last litre (%.1f L)" % c.fuel)
	await shot("decoy_arrive")
	# P1 and Naresh walk in towards the shed (teleported to the village edge)
	var edge: Vector3 = fv.centre + Vector3(-45, 0, 30)
	edge.y = Landscape.ground(edge.x, edge.z) + 0.3
	await place_player(p, edge, 0.0)
	await place_player(q, edge + Vector3(-2, 0, 2), 0.0)
	n.global_position = edge + Vector3(1.5, 0, 1.5)
	n.reset_physics_interpolation()
	n.command(p, "wait")
	var drawn := 0
	var t_draw := 0.0
	while t_draw < 10.0 and drawn < 2:
		await wait(0.5)
		t_draw += 0.5
		drawn = 0
		for cr in fv.creatures:
			if cr.naresh_drawn:
				drawn += 1
	check(drawn == 2, "both turn and drift towards Naresh (%d of 2)" % drawn)
	await look_at_point(p, fv.centre + Vector3(10, 2, 10))
	await shot("decoy_village")
	# the decoy: send him to the end of the jetty
	await place_player(p, fv.jetty_start + Vector3(-6, 0.3, -4), 0.0)
	await place_player(q, fv.jetty_start + Vector3(-8, 0.3, -6), 0.0)
	n.global_position = fv.jetty_start + Vector3(-2, 0.2, 0)
	n.reset_physics_interpolation()
	await wait(0.3)
	n.command(p, "go", null, fv.jetty_end)
	var j := boot.world.get_node("Jetty") as StaticBody3D
	log_line("jetty: centre %s, start %s, end %s, body at %s, waterline x %.0f; Naresh %s" % [fv.centre, fv.jetty_start, fv.jetty_end, j.global_position, fv.centre.x + Landscape.coast_inland(fv.centre.x, fv.jetty_start.z), n.global_position])
	var got_out := await until(func() -> bool: return n.global_position.distance_to(fv.jetty_end) < 3.0, 90.0)
	log_line("Naresh ended at %s" % n.global_position)
	check(got_out, "he walks out to the end of the jetty (%.1f m from it)" % n.global_position.distance_to(fv.jetty_end))
	await place_player(p, fv.centre + Vector3(-30, 0.3, 40), 0.0)
	await place_player(q, fv.centre + Vector3(-32, 0.3, 42), 0.0)
	await look_at_point(p, fv.jetty_end)
	await shot("decoy_jetty")
	# the decoy at work: P1 (keyboard) searches, P2 (pad) watches through the
	# binoculars from the beach and calls him back
	boot._on_joy_changed(0, true)
	await wait(0.3)
	var t0 := Time.get_ticks_msec()
	var shed: Vector3 = poi["net_shed"]
	var clear := await until(func() -> bool:
		for cr in fv.creatures:
			if cr.global_position.distance_to(shed) < 25.0:
				return false
		return true, 60.0)
	var clear_s := (Time.get_ticks_msec() - t0) / 1000.0
	check(clear, "they leave the shed for him (clear after %.0f s)" % clear_s)
	# up the fish crates with the real keys: W and jumps
	var foot: Vector3 = poi["net_shed_crates"]
	var roof_y: float = (poi["net_shed_roof"] as Vector3).y
	await place_player(p, foot + Vector3(0, 0.3, 0), -PI * 0.5)     # facing +X, along the steps
	await shot("decoy_crates")
	key(KEY_W, true)
	for _k in 7:
		await tap(KEY_SPACE)
		await wait(0.45)
	key(KEY_W, false)
	# at the top, turn left onto the roof
	p.yaw = 0.0
	p.rotation.y = 0.0
	key(KEY_W, true)
	await tap(KEY_SPACE)
	await wait(0.8)
	key(KEY_W, false)
	await wait(0.4)
	log_line("climb: P1 at y %.2f, the roof at %.2f" % [p.global_position.y, roof_y])
	check(p.global_position.y > roof_y - 0.4, "up the stacked fish crates onto the shed roof")
	await look_at_point(p, poi["net_shed_key"])
	await wait(0.2)
	await shot("decoy_roof")
	check(p.prompt_text.contains("Take the key"), "the boat on the roof: '%s'" % p.prompt_text)
	await tap(KEY_E)
	await physics_frames(3)
	check(st.flags.has("key_got"), "the key, tied to a cork float")
	await place_player(p, poi["net_shed_door"], 0.0)
	await look_at_point(p, fv.door.global_position)
	await wait(0.2)
	check(p.prompt_text.contains("Unlock"), "at the door: '%s'" % p.prompt_text)
	await tap(KEY_E)
	await physics_frames(3)
	await until(func() -> bool: return st.current()["id"] == "fuel", 3.0)
	check(st.flags.has("shed_open") and st.current()["id"] == "fuel", "the shed opens: next, fuel into the van")
	var search_s := (Time.get_ticks_msec() - t0) / 1000.0
	# P2 calls him back from the beach, 70 m off, through the binoculars
	q.has_binoculars = true      # from the way out (the jump doesn't hand them over)
	await place_player(q, fv.jetty_start + Vector3(-4, 0.3, 4), 0.0)
	var closest := 999.0
	for cr in fv.creatures:
		closest = minf(closest, cr.global_position.distance_to(n.global_position))
	log_line("decoy: shed clear %.0f s, shed open %.0f s after he reached the end; the nearest is %.0f m from him; P2 is %.0f m from him" % [clear_s, search_s, closest, q.global_position.distance_to(n.global_position)])
	check(closest > 8.0 and n.state != Naresh.State.TAKEN, "searched in time: none has reached him yet (%.0f m)" % closest)
	await look_at_point(q, n.global_position + Vector3.UP * 1.1)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await wait(0.5)
	await shot("decoy_binoculars")
	log_line("recall: P2 zoom %.1f, binoculars %s, looking at %s" % [q.zoom, q.has_binoculars, q.command_look(n)])
	pad_button(JOY_BUTTON_DPAD_UP, true)      # a press a few frames long, like a thumb
	await physics_frames(5)
	pad_button(JOY_BUTTON_DPAD_UP, false)
	await physics_frames(4)
	log_line("recall: Naresh %s, leader %s" % [Naresh.State.keys()[n.state], n.leader.name if n.leader != null else "-"])
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	check(n.state == Naresh.State.FOLLOW and n.leader == q, "D-pad Up through the binoculars, %.0f m: he follows P2" % q.global_position.distance_to(n.global_position))
	# the van parked at the village (as you would), P2 walks him back to it;
	# P1 brings the full can
	await van_to(fv.centre + Vector3(-40, 0, 10))
	await place_player(q, c.global_transform * Vector3(-4, 0, 4) + Vector3(0, 0.3, 0), 0.0)
	n.global_position = q.global_position + Vector3(1.5, 0, 1.5)
	n.reset_physics_interpolation()
	n.command(q, "follow")
	await place_player(p, fv.can_full.global_position + Vector3(-1.2, 0.3, 0), -PI * 0.5)
	await look_at_point(p, fv.can_full.global_position)
	await tap(KEY_E)
	await physics_frames(3)
	check(p.held == fv.can_full, "P1 picks up the heavy can")
	# P1 takes it out to the van and puts it down beside it
	await place_player(p, c.global_transform * Vector3(-3.0, 0, 1.5) + Vector3(0, 0.3, 0), 0.0)
	p.drop_held()
	await physics_frames(5)
	# Naresh at the shed: "there's two!" and he takes the light one to the van
	n.global_position = poi["net_shed_door"] + Vector3(-2, 0, 1)
	n.reset_physics_interpolation()
	var helped := await until(func() -> bool: return fv._helped, 5.0)
	check(helped and n.refuel_mistake, "Naresh: 'There's two! I'll take this one to the van.'")
	var stored := await until(func() -> bool: return fv.can_empty.stowed_in != null, 90.0)
	check(stored, "he puts the light can on the van's rack")
	var did := await until(func() -> bool: return st.flags.has("mistake_done"), 60.0)
	log_line("the mistake: fuel %.2f L, the full can %.1f L, the empty %.1f L" % [c.fuel, fv.can_full.litres, fv.can_empty.litres])
	check(did and c.fuel < 1.0 and fv.can_full.litres > 19.0, "'Leave the fuel to me!' He fills it from the empty can (the full one untouched)")
	await until(func() -> bool: return st.current()["id"] == "drive_on", 3.0)
	check(st.current()["id"] == "drive_on", "and the story says drive on ('%s')" % st.current()["id"])
	# drive on: it dies up the road, and one comes
	n.command(q, "get_in", c)
	await until(func() -> bool: return n.state == Naresh.State.SEATED, 15.0)
	await seat_p1_driver()
	q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await engine_on()
	var north: Route = boot.builder.network.road("coast_road")
	var stop := int(north.nearest(1640.0, -900.0)["index"])
	var t1 := Time.get_ticks_msec()
	var x0 := c.global_position
	await drive_until(north, stop, func() -> bool: return st.flags.has("stalled"), 90.0, 40.0)
	key(KEY_W, false)
	var went := c.global_position.distance_to(x0)
	log_line("stalled %.0f m on, after %.0f s" % [went, (Time.get_ticks_msec() - t1) / 1000.0])
	check(st.flags.has("stalled") and went > 150.0 and went < 600.0, "the van coughs and dies %.0f m up the road" % went)
	await wait(1.5)
	var sc := boot.world.get_node_or_null("StallCreature") as Creature
	check(sc != null and sc.global_position.distance_to(c.global_position) < 110.0, "up the road something steps out of the dark")
	await shot("decoy_stalled")
	# pour the full can in yourself
	p.force_exit = true
	await physics_frames(3)
	await place_player(p, c.rack_stand() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, fv.can_full.global_position)
	await tap(KEY_E)
	await physics_frames(3)
	check(p.held == fv.can_full, "P1 takes the full can off the rack")
	await place_player(p, c.filler_stand() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, c.filler_point())
	await hold_physics(KEY_E, 5.0)
	log_line("poured: the tank %.1f L, the can %.1f L" % [c.fuel, fv.can_full.litres])
	check(st.flags.has("stall_fixed") and st.current()["id"] == "end_f3", "the tank's filled: north on to the salt pans")
	p.drop_held()
	boot._set_layout(Boot.Layout.SOLO)


## F4, the salt pans and R2 red light / green light. `tools/run_test.sh saltpans`
func t_saltpans() -> void:
	var st: Story = boot.story
	var sp := get_tree().get_first_node_in_group("salt_pans") as SaltPans
	check(sp != null and sp.heaps.size() >= 5 and sp.watcher != null, "the salt pans: the gantry with its watcher, %d salt heaps" % (sp.heaps.size() if sp else 0))
	if sp == null:
		return
	var c := camper()
	boot.dev_menu.run("jump", st.index_of("salt_pans"))
	await wait(1.0)
	check(st.current()["id"] == "salt_pans" and sp.watcher.global_position.y > sp.centre.y + SaltPans.GANTRY_H - 0.5, "F1 jump: short of the pans, the watcher up on its gantry")
	await look_at_point(p1(), sp.eye)
	await shot("pans_gantry")
	# it looks one way, then another
	var lo := 9.0
	var hi := -9.0
	for _k in 60:
		await wait(0.25)
		lo = minf(lo, sp.gaze)
		hi = maxf(hi, sp.gaze)
	log_line("gaze swept %.0f deg in 15 s" % rad_to_deg(hi - lo))
	check(rad_to_deg(hi - lo) > 40.0, "its gaze turns from one stare to the next")
	# behind a heap: hidden; in the open: seen
	sp.auto_sweep = false
	var heap: Vector3 = sp.heaps[2]
	var away := Vector3(heap.x - sp.eye.x, 0, heap.z - sp.eye.z).normalized()
	await van_to(heap + away * 9.0)
	await physics_frames(10)
	var to := c.global_position - sp.eye
	sp.gaze = atan2(-to.x, -to.z)
	await physics_frames(3)
	check(not sp.van_in_view(c), "behind a salt heap, right in its gaze: hidden")
	var gap := (sp.heaps[2] + sp.heaps[3]) * 0.5
	await van_to(gap + Vector3(gap.x - sp.eye.x, 0, gap.z - sp.eye.z).normalized() * 9.0)
	await physics_frames(10)
	to = c.global_position - sp.eye
	sp.gaze = atan2(-to.x, -to.z)
	await physics_frames(3)
	check(sp.van_in_view(c), "between two heaps, in its gaze: in plain view")
	await shot("pans_in_view")
	# stopped in the open it takes a moment; moving, at once
	await wait(SaltPans.STILL_SEEN + 0.6)
	check(sp.seen and st.flags.has("pans_seen"), "stopped in the open, it sees the van after %.1f s" % SaltPans.STILL_SEEN)
	await physics_frames(20)
	check(not sp.watcher.passive and sp.watcher.state == Creature.State.VAN, "it drops off the gantry and comes for the van")
	# a careful crossing: a spotter's calls, dash and stop behind the heaps
	boot.dev_menu.run("jump", st.index_of("salt_pans"))
	await wait(1.0)
	check(not sp.seen and sp.watcher.passive, "a jump back: it's up on its gantry again")
	sp.auto_sweep = true
	await seat_p1_driver()
	await salt_careful_crossing()
	var road: Route = boot.builder.network.road("coast_road")
	check(st.flags.has("pans_crossed") and not sp.seen, "dashing between heaps, stopping behind them when it turns: across unseen")
	await until(func() -> bool: return st.current()["id"] == "end_f4", 3.0)
	check(st.current()["id"] == "end_f4", "on to the estuary bridge")
	# reckless: straight across at speed gets seen
	boot.dev_menu.run("jump", st.index_of("salt_pans"))
	await wait(1.0)
	await seat_p1_driver()
	await engine_on()
	var ad2 := AutoDriver.new(self, road, c)
	ad2.lane = -1.8
	var t1 := Time.get_ticks_msec()
	while not sp.seen and not st.flags.has("pans_crossed") and (Time.get_ticks_msec() - t1) < 60000:
		await physics_frames(1)
		ad2.step(45.0)
	ad2.release()
	log_line("reckless crossing: %s (it glanced round %d times)" % ["seen" if sp.seen else "not seen", sp.glances])
	check(sp.seen, "straight across without stopping: it sees the van")
	p1().force_exit = true
	await physics_frames(3)


## The careful crossing of the salt pans (P1 driving): go while it looks
## away; when it turns your way stop behind a heap, dash on if the next one
## hides you in a moment, else freeze. True: across unseen. (Its own function
## so the watched run can `call` it.)
func salt_careful_crossing() -> bool:
	var sp := get_tree().get_first_node_in_group("salt_pans") as SaltPans
	var st: Story = boot.story
	var c := camper()
	await engine_on()
	var road: Route = boot.builder.network.road("coast_road")
	var ad := AutoDriver.new(self, road, c)
	ad.lane = -1.8
	var t0 := Time.get_ticks_msec()
	var stops := 0
	var was_go := true
	while not st.flags.has("pans_crossed") and not sp.seen and (Time.get_ticks_msec() - t0) < 150000:
		await physics_frames(1)
		var v := c.global_position - sp.eye
		var vdir := Vector2(v.x, v.z).normalized()
		var now_a := absf(rad_to_deg(Vector2(-sin(sp.gaze), -cos(sp.gaze)).angle_to(vdir)))
		var next_a := absf(rad_to_deg(Vector2(-sin(sp._to), -cos(sp._to)).angle_to(vdir)))
		var after_a := absf(rad_to_deg(Vector2(-sin(sp.next_aim()), -cos(sp.next_aim())).angle_to(vdir)))
		var leaving := sp._t > sp._hold_now() * 0.5     # the next turn is coming
		var danger := now_a < SaltPans.CORNER + 8.0 or next_a < SaltPans.CORNER + 8.0 or (leaving and after_a < SaltPans.CORNER + 8.0)
		var hidden := sp._hidden(c)
		# a careful driver: go while it looks away; when it turns your way,
		# stop behind a heap, or dash on if the next one hides you in a moment,
		# else freeze where you are
		var fwd := -c.global_transform.basis.z
		var stop_at := sp.hidden_at(c.global_position + c.linear_velocity * 0.45)  # where braking now ends
		var soon := sp.hidden_at(c.global_position + c.linear_velocity * 1.4)
		var back := sp.hidden_at(c.global_position - fwd * 4.0)
		var go := not danger or (not stop_at and soon and kmh() > 8.0)
		if go:
			ad.step(28.0)
		elif (kmh() < 1.0 or c.linear_velocity.dot(fwd) < 0.0) and not hidden and back:
			# overshot the cover: back into it (S, stopped, reverses)
			ad.steer_only()
			key(KEY_W, false)
			key(KEY_S, true)
		else:
			ad.steer_only()
			key(KEY_W, false)
			key(KEY_S, kmh() > 0.5 and (c.linear_velocity.dot(fwd) > 0.0))
		if go != was_go:
			log_line("  %.0f s: %s (%s, %.0f km/h, gaze %.0f deg off, next %.0f)" % [(Time.get_ticks_msec() - t0) / 1000.0, "GO" if go else "STOP", "hidden" if hidden else "open", kmh(), now_a, next_a])
		if go != was_go and not go:
			stops += 1
		was_go = go
	ad.release()
	key(KEY_S, false)
	var took := (Time.get_ticks_msec() - t0) / 1000.0
	await shot("pans_careful_end")
	log_line("careful crossing: %s after %.0f s, %d stops behind heaps" % ["crossed unseen" if st.flags.has("pans_crossed") and not sp.seen else ("SEEN" if sp.seen else "not across"), took, stops])
	return st.flags.has("pans_crossed") and not sp.seen


## F5, the estuary bridge and R3 the three-hand swing bridge. `tools/run_test.sh swing`
func t_swing() -> void:
	var st: Story = boot.story
	var sb := get_tree().get_first_node_in_group("swing_bridge") as SwingBridge
	check(sb != null and sb.crank_a != null and sb.brake != null, "the estuary bridge: a swing span, two cranks, a brake lever, a tide gauge")
	if sb == null:
		return
	var c := camper()
	var p := p1()
	var q := p2()
	boot.dev_menu.run("jump", st.index_of("swing"))
	await wait(1.0)
	var n := nz()
	check(st.current()["id"] == "swing" and absf(sb.angle - SwingBridge.OPEN_DEG) < 0.1 and sb.barriers.visible, "F1 jump: at the controls, the span swung open, the barriers up")
	await look_at_point(p, sb.pivot + Vector3.UP * 2.0)
	await shot("swing_open")
	boot._on_joy_changed(0, true)
	await wait(0.3)
	# the cranks alone, brake on: nothing
	await place_player(p, sb.crank_a.stand_point() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, sb.crank_a.global_position)
	await wait(0.2)
	check(p.prompt_text.contains("turn the crank"), "at a crank: '%s'" % p.prompt_text)
	key(KEY_E, true)
	await wait(2.0)
	check(sb.angle >= SwingBridge.OPEN_DEG - 0.1, "turning a crank with the brake on does nothing (%.0f deg)" % sb.angle)
	# Naresh on the brake, P2 on the other crank (pad X)
	n.global_position = sb.brake.stand_point() + Vector3(1.0, 0.2, 0)
	n.reset_physics_interpolation()
	await place_player(q, sb.crank_b.stand_point() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(q, sb.crank_b.global_position)
	key(KEY_E, false)
	await physics_frames(3)
	var job_ok := await naresh_job(p, sb.brake.global_position, "hold")
	var on := await until(func() -> bool: return sb.brake_off(), 15.0)
	check(job_ok and on, "V on the lever, Hold the brake: Naresh holds it off")
	await look_at_point(p, sb.crank_a.global_position)
	key(KEY_E, true)
	await wait(0.4)
	var a0 := sb.angle
	await wait(3.0)
	var one_rate := (a0 - sb.angle) / 3.0
	pad_button(JOY_BUTTON_X, true)
	await wait(0.4)
	var a1 := sb.angle
	await wait(3.0)
	var two_rate := (a1 - sb.angle) / 3.0
	log_line("swing: one crank %.1f deg/s, two %.1f deg/s; now %.0f deg" % [one_rate, two_rate, sb.angle])
	check(one_rate > 1.0 and two_rate > one_rate * 1.7, "one crank turns it slowly, both twice as fast")
	await look_at_point(p, sb.pivot + Vector3.UP * 2.0)
	await shot("swing_turning")
	await look_at_point(p, sb.crank_a.global_position)
	# half way he waves at a boat and lets go: it swings back
	var waved := await until(func() -> bool: return st.flags.has("swing_waved"), 40.0)
	await physics_frames(10)
	var b0 := sb.angle
	await wait(1.5)
	log_line("he let go at %.0f deg; 1.5 s later %.0f deg" % [b0, sb.angle])
	check(waved and not sb.brake_off() and sb.angle > b0 + 2.0, "half way Naresh lets go to wave at a boat: the span swings back open")
	n.command(p, "hold", sb.brake)
	var done := await until(func() -> bool: return sb.locked, 60.0)
	key(KEY_E, false)
	pad_button(JOY_BUTTON_X, false)
	check(done and st.flags.has("swing_locked") and not sb.barriers.visible, "told again: round it comes, it bolts home, the barriers go")
	await until(func() -> bool: return st.current()["id"] == "end_f5", 3.0)
	check(st.current()["id"] == "end_f5", "on to the rail tunnel")
	await look_at_point(p, sb.pivot + Vector3.UP * 2.0)
	await shot("swing_closed")
	# the van drives over it
	await van_to(sb.pivot - (sb._fwd * 40.0))
	await seat_p1_driver()
	await engine_on()
	var road: Route = boot.builder.network.road("coast_road")
	var far := sb.pivot + sb._fwd * 40.0
	await drive_until(road, int(road.nearest(far.x, far.z)["index"]), func() -> bool: return c.global_position.distance_to(far) < 8.0, 30.0, 30.0)
	key(KEY_W, false)
	log_line("over the bridge: the van %.1f m from the far side, at height %.1f" % [c.global_position.distance_to(far), c.global_position.y])
	check(c.global_position.distance_to(far) < 12.0 and c.global_position.y > Landscape.SEA_Y + 1.0, "the van drives over the swung-back span")
	# the tide: at the red mark the current pulls twice as hard
	sb.match_story()
	st.flags.erase("swing_locked")
	sb.match_story()
	sb.tide = 1.0
	var c0 := sb.angle
	sb.angle = 45.0
	await wait(2.0)
	log_line("at the red mark it swings open at %.1f deg/s" % ((sb.angle - 45.0) / 2.0))
	check((sb.angle - 45.0) / 2.0 > SwingBridge.DRIFT * 1.6, "at the tide's red mark the current pulls it open twice as fast")
	p.force_exit = true
	await physics_frames(3)
	boot._set_layout(Boot.Layout.SOLO)


## F6, the old rail tunnel: the flood gate, the dark gallery, the flare gun,
## the push start. `tools/run_test.sh tunnel`
func t_tunnel() -> void:
	var st: Story = boot.story
	var rt := get_tree().get_first_node_in_group("rail_tunnel") as RailTunnel
	check(rt != null and rt.doors.size() == 2 and rt.gate != null and rt.winch != null and rt.gun != null, "the rail tunnel: a flood gate, a gallery with two doors, a winch, the flare gun")
	if rt == null or rt.doors.is_empty():
		return
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	var p := p1()
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	boot.dev_menu.run("jump", st.index_of("tunnel"))
	await wait(2.0)
	var n := nz()
	var gate_y: float = (poi["tunnel_gate"] as Vector3).y
	check(st.current()["id"] == "tunnel" and rt.gate.global_position.y < gate_y + 0.2, "F1 jump: in the tunnel, the flood gate down ahead")
	check(mood.dark > 0.8 and mood.light() == 2, "underground it's dark (%.2f): night for their eyes" % mood.dark)
	log_line("tunnel: samples %d-%d, doors %s, gate %d" % [rt.run.x, rt.run.y, rt.doors, rt.gate_i])
	await look_at_point(p, rt.gate.global_position + Vector3.UP * 2.0)
	await shot("tunnel_gate_dark")
	p.flashlight_seconds = 600.0
	p.toggle_flashlight()
	await wait(0.2)
	await shot("tunnel_gate_torch")
	p.toggle_flashlight()
	# the creature out of the way while we look round the gallery
	rt.watcher.dormant = true
	rt.watcher.global_position = poi["gallery_far_door"] + Vector3(0, 0.2, 0)
	# in through the first door, along to the first fork
	var door: Vector3 = poi["gallery_door"]
	await place_player(p, door - rt.road.right(rt.doors[0]) * 2.5 + Vector3(0, 0.3, 0), 0.0)
	var r0 := rt.road.right(rt.doors[0])
	var inside_door := rt.road.point(rt.doors[0]) + r0 * rt._off
	var in_ok := await walk_to(p, inside_door, "the gallery door", 0.8)
	check(in_ok, "through the door into the service gallery")
	var fork: Vector3 = poi["gallery_fork_1"]
	var to_fork := await walk_to(p, fork, "the first fork", 0.8, 40.0)
	check(to_fork, "along the gallery to the first fork")
	await look_at_point(p, fork - rt.road.right(rt.doors[0]) * 1.2 + Vector3.UP * 1.6)
	await shot("gallery_fork_dark")
	p.toggle_flashlight()
	await wait(0.2)
	await shot("gallery_fork_torch")
	# the creature sees a torch from far off, not you in the dark
	var cr := rt.watcher
	cr.dormant = false
	cr.patrol = PackedVector3Array()
	var fi: int = rt.doors[0] + (rt.gate_i - rt.doors[0]) / 2 + 12      # ~24 m on from the first fork
	var ahead := rt.road.point(fi) + rt.road.right(fi) * rt._off + Vector3.UP * 0.2
	cr.global_position = ahead
	cr.reset_physics_interpolation()
	cr.suspicion = 0.0
	var to_p := p.global_position - ahead
	cr.rotation.y = atan2(-to_p.x, -to_p.z)
	p.flashlight.visible = false
	await wait(2.0)
	var dark_s := cr.suspicion
	p.flashlight.visible = true
	await wait(1.5)
	var lit_s := cr.suspicion
	log_line("gallery creature %.0f m off: torch off suspicion %.2f, on %.2f" % [ahead.distance_to(p.global_position), dark_s, lit_s])
	check(dark_s < 0.2 and lit_s > 0.3, "in the dark it doesn't see you %.0f m off; with the torch on it does" % ahead.distance_to(p.global_position))
	p.flashlight.visible = false
	calm_creature(cr, ahead)
	cr.dormant = true
	# the flare gun at the second fork's dead end
	var gun_at: Vector3 = poi["flare_gun"]
	await place_player(p, gun_at - rt.road.right(rt.gate_i) * 1.3 + Vector3(0, 0.2, 0), 0.0)
	await look_at_point(p, gun_at)
	await wait(0.2)
	await shot("gallery_flare_gun")
	await tap(KEY_E)
	await physics_frames(3)
	check(p.held == rt.gun, "the flare gun, in a red case at the dead end: picked up")
	cr.dormant = false
	var gi: int = rt.gate_i + (rt.doors[1] - rt.gate_i) / 2 - 10           # 20 m back along the gallery
	cr.global_position = rt.road.point(gi) + rt.road.right(gi) * rt._off + Vector3.UP * 0.2
	cr.reset_physics_interpolation()
	await wait(0.3)
	var near_before := cr.global_position.distance_to(p.global_position)
	await tap(KEY_G)
	await wait(1.0)
	check(cr.scared_t > 0.0 and rt.gun.flares_left() == 2 and st.flags.get("flares_used", 0) == 1, "G / RB fires a flare: the creature runs (2 left)")
	await wait(3.0)
	await shot("gallery_flare")
	var ran := cr.global_position.distance_to(p.global_position)
	check(ran > near_before + 6.0, "it runs from the flare (%.0f m off, was %.0f)" % [ran, near_before])
	p.drop_held()
	cr.scared_t = 0.0
	calm_creature(cr, ahead)
	cr.dormant = true
	# Naresh holds the winch, P1 drives through
	var w: Vector3 = poi["gate_winch"]
	n.global_position = w + rt.road.right(rt.gate_i) * 1.0 + Vector3(0, 0.2, 0)
	n.reset_physics_interpolation()
	await place_player(p, w + rt.road.right(rt.gate_i) * 2.0 - rt.road.forward(rt.gate_i) * 2.0 + Vector3(0, 0.2, 0), 0.0)
	await physics_frames(5)
	var job_ok := await naresh_job(p, rt.winch.global_position, "hold")
	var up := await until(func() -> bool: return rt.gate.global_position.y > gate_y + 3.0, 12.0)
	check(job_ok and up, "V on the winch, Hold the gate winch: Naresh holds the flood gate up")
	await place_player(p, c.global_transform * Vector3(-3.0, 0, 0) + Vector3(0, 0.3, 0), 0.0)
	await seat_p1_driver()
	await engine_on()
	await drive_until(rt.road, rt.gate_i + 20, func() -> bool: return st.flags.has("gate_through"), 40.0, 20.0)
	key(KEY_W, false)
	check(st.flags.has("gate_through"), "the van drives under the gate and on")
	await until(func() -> bool: return st.current()["id"] == "end_f6", 3.0)
	check(st.current()["id"] == "end_f6", "on to the radio mast")
	# R5, the push start: a flat battery won't start; rolling, it does
	await tap(KEY_X)                       # engine off
	c.battery = 0.0
	await wait(0.3)
	await tap(KEY_X)
	await wait(0.3)
	check(not c.engine_on, "a flat battery: click, click")
	c.parking_brake = false
	c.linear_velocity = -c.global_transform.basis.z * 4.0
	await physics_frames(2)
	await tap(KEY_X)
	await wait(0.3)
	check(c.engine_on, "rolling at %.0f km/h: it bump-starts" % kmh())
	p.force_exit = true
	await physics_frames(3)
	rt.watcher.dormant = false


## Hold E on a dish crank until the dish is within `tol` degrees of its
## target, then let go (a player watching the screen).
func mast_turn(m: RadioMast, k: int, tol := 1.2, max_s := 60.0) -> bool:
	var t := 0.0
	key(KEY_E, true)
	while t < max_s:
		await physics_frames(1)
		t += 1.0 / 60.0
		if absf(rad_to_deg(angle_difference(m.yaw[k], m._bearing(k)))) < tol:
			break
	key(KEY_E, false)
	await wait(1.4)
	return m.locked[k]


## F7, the finale: point the dishes home. `tools/run_test.sh mast`
func t_mast() -> void:
	var st: Story = boot.story
	var m := get_tree().get_first_node_in_group("radio_mast") as RadioMast
	check(m != null and m.dishes.size() == 3 and m.cranks.size() == 3 and m.targets.size() == 3, "the mast: three dishes, three cranks, a generator, the screen")
	if m == null:
		return
	var poi: Dictionary = boot.builder.poi
	var p := p1()
	var q := p2()
	boot.dev_menu.run("jump", st.index_of("mast"))
	await wait(1.0)
	var n := nz()
	log_line("mast at %s; the road below %.0f m off; targets %.0f / %.0f / %.0f m" % [m.foot, Vector2((poi["mast_road"] as Vector3).x - m.foot.x, (poi["mast_road"] as Vector3).z - m.foot.z).length(),
		m.targets[0].distance_to(m.foot), m.targets[1].distance_to(m.foot), m.targets[2].distance_to(m.foot)])
	check(st.current()["id"] == "mast" and not m.running, "F1 jump: at the foot of the mast, the generator off")
	await look_at_point(p, m.foot + Vector3(0, 15, 0))
	await shot("mast_foot")
	boot._on_joy_changed(0, true)
	await wait(0.3)
	# the cord alone splutters out
	await place_player(p, m.cord.stand_point() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, m.cord.global_position)
	await wait(0.2)
	check(p.prompt_text.contains("pull the pull cord"), "at the generator: '%s'" % p.prompt_text)
	await hold_physics(KEY_E, 1.6)
	await wait(0.3)
	check(not m.running and m.cord.has_meta("spluttered"), "the cord alone: it coughs and dies (someone must hold the choke)")
	# P2 holds the choke (pad X), P1 pulls
	await place_player(q, m.choke.stand_point() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(q, m.choke.global_position)
	pad_button(JOY_BUTTON_X, true)
	await wait(0.8)
	await hold_physics(KEY_E, 1.6)
	pad_button(JOY_BUTTON_X, false)
	await wait(0.3)
	check(m.running and st.flags.has("gen_running"), "the choke held, the cord pulled: the generator roars into life")
	check(m._beacons[0].visible and m._beacons[2].visible, "far off, three red beacons blink on")
	check(not m.creatures[0].dormant, "and its noise brings two of them")
	for cr in m.creatures:
		cr.dormant = true            # (out of the way for the rest of this test)
	# up the ladder to the platform, tag the first target
	var lad := boot.world.find_child("MastLadder", true, false) as Ladder
	await place_player(p, lad.global_position + lad.global_transform.basis.z * 0.9 + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, lad.global_position + Vector3.UP * 1.2)
	await tap(KEY_E)
	key(KEY_W, true)
	await until(func() -> bool: return p.global_position.y > m.foot.y + RadioMast.PLAT_Y - 0.5 and p.ladder == null, 20.0)
	key(KEY_W, false)
	await wait(0.4)
	check(p.global_position.y > m.foot.y + RadioMast.PLAT_Y - 0.5, "up the ladder onto the platform, 20 m up")
	await look_at_point(p, m.targets[0])
	await shot("mast_view_tunnel")
	await look_at_point(p, m.targets[2])
	await shot("mast_view_tower")
	await look_at_point(p, m.targets[0])
	await tap(KEY_T)
	await physics_frames(3)
	var tg := TagMarker.of(0)
	check(tg != null and tg.thing == "the tunnel mouth", "T on the far beacon: '%s'" % (tg.thing if tg else "no tag"))
	# down again, the cranks
	await place_player(p, m.cranks[0].stand_point() + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, m.cranks[0].global_position)
	await wait(0.2)
	check(p.prompt_text.contains("dish 1 crank"), "at the desk: '%s'" % p.prompt_text)
	var y0: float = m.yaw[0]
	key(KEY_E, true)
	await wait(1.0)
	key(KEY_E, false)
	var rate := rad_to_deg(angle_difference(y0, m.yaw[0]))
	log_line("dish 1 turns %.1f deg/s" % rate)
	check(absf(rate) > 6.0, "holding its crank turns dish 1")
	var l1 := await mast_turn(m, 0)
	check(l1 and st.flags.has("dish_1"), "on its beacon, let go: dish 1 locks, its lamp green")
	await look_at_point(p, poi["dish_screen"])
	await shot("mast_screen")
	# Naresh on dish 2: backwards first, until he's told again
	n.global_position = m.cranks[1].stand_point() + Vector3(0.6, 0.2, 0.6)
	n.reset_physics_interpolation()
	await place_player(p, m.cranks[2].stand_point() + Vector3(0, 0.3, 0), 0.0)
	var job_ok := await naresh_job(p, m.cranks[1].global_position, "hold")
	var y1: float = m.yaw[1]
	await until(func() -> bool: return m.cranks[1].holding_now(), 10.0)
	await wait(2.0)
	var d1 := rad_to_deg(angle_difference(y1, m.yaw[1]))
	check(job_ok and d1 < -3.0 and m._wrong == 1, "Naresh on dish 2: he turns it the wrong way (%.0f deg)" % d1)
	n.command(p, "hold", m.cranks[1])
	await wait(0.5)
	var y2: float = m.yaw[1]
	await wait(2.0)
	var d2 := rad_to_deg(angle_difference(y2, m.yaw[1]))
	check(d2 > 3.0 and m._wrong_done, "told again: 'The OTHER way.' (%.0f deg)" % d2)
	var turned := await until(func() -> bool: return absf(rad_to_deg(angle_difference(m.yaw[1], m._bearing(1)))) < 1.2, 60.0)
	n.command(p, "wait")
	await wait(1.4)
	check(turned and m.locked[1], "he brings it round; let go on the beacon, dish 2 locks")
	# P1 on dish 3: done
	await look_at_point(p, m.cranks[2].global_position)
	var l3 := await mast_turn(m, 2)
	await until(func() -> bool: return st.flags.has("mast_done"), 3.0)
	check(l3 and st.flags.has("mast_done"), "the third locks: the mast hums, the clouds break over the West Road")
	await until(func() -> bool: return st.current()["id"] == "end_f7", 3.0)
	check(st.current()["id"] == "end_f7", "on to Naresh's home")
	# the frame rate by the screen, both views
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	await place_player(q, poi["dish_screen"] + Vector3(1, -1.5, 2), 0.0)
	await place_player(p, poi["dish_screen"] + Vector3(-1, -1.5, 2), 0.0)
	await wait(1.0)
	_frame_times.clear()
	await wait(3.0)
	var avg := 0.0
	for f in _frame_times:
		avg += f
	var fps := float(_frame_times.size()) / maxf(avg, 0.001)
	m.screen_on = false
	_frame_times.clear()
	await wait(3.0)
	var avg2 := 0.0
	for f in _frame_times:
		avg2 += f
	var fps_off := float(_frame_times.size()) / maxf(avg2, 0.001)
	m.screen_on = true
	log_line("fps by the dish screen, both views: %.0f (without the screen %.0f)" % [fps, fps_off])
	check(headless or fps >= 110.0, "the dish screen keeps the frame rate (%.0f fps)" % fps)
	boot._set_layout(Boot.Layout.SOLO)


## Drive up to Naresh's home with him in the back and let the scene play.
func home_arrive(hc: Homecoming) -> bool:
	var st: Story = boot.story
	var c := camper()
	var n := nz()
	await seat_p1_driver()
	n.command(p1(), "get_in", c)
	await until(func() -> bool: return n.state == Naresh.State.SEATED, 15.0)
	await van_to(boot.builder.poi["naresh_home_road"])
	await seat_p1_driver()
	return await until(func() -> bool: return st.flags.has("naresh_home_done"), 70.0)


## F8: Naresh's home, the tracker, the West Road, the watchtower's lights,
## the end. `tools/run_test.sh home`
func t_home() -> void:
	var st: Story = boot.story
	var hc := get_tree().get_first_node_in_group("homecoming") as Homecoming
	check(hc != null and hc.lights.size() >= 10, "the homecoming: his family at the door, %d site lights" % (hc.lights.size() if hc else 0))
	if hc == null:
		return
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	boot.dev_menu.run("jump", st.index_of("end_f7"))
	await wait(1.0)
	check(st.current()["id"] == "end_f7" and not hc._mother.visible, "F1 jump: on the road to his home, him with you")
	var t0 := Time.get_ticks_msec()
	var home := await home_arrive(hc)
	log_line("the scene took %.0f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	check(home, "he walks to the door; his mother; his sister's look; he goes in")
	check(not nz().visible and not Creature.on_return and mood.target >= Homecoming.HOME_MOOD - 0.01, "he's home: the creatures stop following, the light comes back")
	check(not st.flags.has("tracker"), "the optional things not done: no tracker (and nobody says so)")
	await until(func() -> bool: return st.current()["id"] == "drive_home", 3.0)
	check(st.current()["id"] == "drive_home", "the objective: home along the West Road")
	await look_at_point(p1(), hc.door + Vector3.UP * 1.5)
	await shot("home_door")
	# the West Road: full sun
	var west: Route = boot.builder.network.road("west_road")
	await van_to(west.point(west.point_count() / 2))
	await wait(1.0)
	check(mood.target >= Homecoming.SUN_MOOD - 0.01, "away down the West Road: full sun")
	# the ending watchtower: the lights (the optional ones dark)
	p1().force_exit = true
	await physics_frames(3)
	await place_player(p1(), poi["end_tower_deck"] + Vector3(0, 0.3, 0), 0.0)
	await wait(0.5)
	var dark := 0
	for l in hc.lights:
		if not l.visible:
			dark += 1
	# the optional ones dark unless an earlier test did them for real
	var maze0 := get_tree().get_first_node_in_group("barn_maze")
	var relay0 := get_tree().get_first_node_in_group("lookout_relay")
	var want_dark := int(not bool(maze0.get("chest_open"))) + int(not bool(relay0.get("opened"))) + int(not st.flags.has("flare_gun_found"))
	check(st.flags.has("tower_view") and dark == want_dark, "from the watchtower: a light over every place, the optional ones not done dark (%d dark, %d expected)" % [dark, want_dark])
	mood.set_now(1.0)
	await look_at_point(p1(), poi["radio_mast"] + Vector3.UP * 40.0)
	await shot("tower_lights")
	# near home: the phones, then the end
	var lane: Route = boot.builder.network.road("home_lane")
	var hs: Vector3 = poi["homestead"]
	var li := int(lane.nearest(hs.x, hs.z)["index"])
	await van_to(lane.point(li + 40))
	var ended := await until(func() -> bool: return st.flags.has("end_reached"), 5.0)
	var msg: Dictionary = st.phone_threads[0][-1]
	check(ended and String(msg["body"]).contains("LiveStander"), "near home, both phones: '%s'" % msg["body"])
	await until(func() -> bool: return hc._end != null, 12.0)
	await wait(5.5)
	check(hc._end != null, "the end screen")
	await shot("the_end")
	hc._end.queue_free()
	hc._end = null
	hc._end_t = -1.0
	# a second time with every optional thing done: the tracker
	var maze := get_tree().get_first_node_in_group("barn_maze")
	var relay := get_tree().get_first_node_in_group("lookout_relay")
	maze.set("chest_open", true)
	relay.set("opened", true)
	for id in hc._fragments:
		if not id in st.collected:
			st.collected.append(id)
	boot.dev_menu.run("jump", st.index_of("end_f7"))
	await wait(1.0)
	st.flags["flare_gun_found"] = true
	check(hc.all_optional(), "every optional thing done (maze, relay, flare gun, %d fragments)" % hc._fragments.size())
	var home2 := await home_arrive(hc)
	check(home2 and st.flags.has("tracker"), "his sister: a tracker, 'For next time.'")
	p1().force_exit = true
	await physics_frames(3)


## F9: the whole return in one drive, Bessi to home (Full only). The van
## drives every road; the puzzles are done by script where the van gets to
## them (each has its own test); the timings are logged against the beat
## chart's ~29 min. `tools/run_test.sh return_run`
func t_return_run() -> void:
	var st: Story = boot.story
	var b = boot.builder
	var c := camper()
	var fv := get_tree().get_first_node_in_group("fishing_village") as FishingVillage
	var sp := get_tree().get_first_node_in_group("salt_pans") as SaltPans
	var sb := get_tree().get_first_node_in_group("swing_bridge") as SwingBridge
	var rt := get_tree().get_first_node_in_group("rail_tunnel") as RailTunnel
	var hc := get_tree().get_first_node_in_group("homecoming") as Homecoming
	boot.dev_menu.run("jump", st.index_of("storm"))
	await wait(1.0)
	var n := nz()
	var path := (b.network as RoadNetwork).chain([["coast_road"], ["west_road"]])
	var hs: Vector3 = b.poi["homestead"]
	var stop_at := int(path.nearest(hs.x, hs.z)["index"])
	var start_i := int(path.nearest(c.global_position.x, c.global_position.z)["index"])
	log_line("return path: %d samples, %.1f km; from %d to %d" % [path.point_count(), path.total_length / 1000.0, start_i, stop_at])
	# the van's safety net: pushed down through the ground, it comes back
	await wait(2.5)
	var safe := c.global_position
	c.global_position = safe + Vector3(0, -12.0, 0)
	await physics_frames(3)
	check(c.global_position.distance_to(safe) < 1.5, "the van's safety net: under the ground, it's put back where it stood (%.1f m off)" % c.global_position.distance_to(safe))
	n.command(p1(), "get_in", c)
	await until(func() -> bool: return n.state == Naresh.State.SEATED, 15.0)
	await seat_p1_driver()
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await engine_on()
	c.parking_brake = false
	var ad := AutoDriver.new(self, path, c)
	ad.lane = -1.8
	var t := 0.0
	var stuck := 0.0
	var marks := {}
	var places := [["fishing_village", 90.0], ["salt_pans_start", 40.0], ["swing_near", 40.0], ["tunnel_in", 40.0], ["mast_road", 60.0], ["naresh_home_road", 40.0], ["end_tower", 300.0], ["homestead", 250.0]]
	var stopped_home := false
	while t < 2400.0 and not st.flags.has("end_reached"):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var hold := false
		# Naresh's home: stop at the door and let the scene play
		if not st.flags.has("naresh_home_done") and st.flags.has("mast_done") and c.global_position.distance_to(b.poi["naresh_home_road"]) < 18.0:
			hold = true
			if not stopped_home:
				stopped_home = true
				log_line("at Naresh's home after %.1f min" % (t / 60.0))
		if hold:
			# stopped at the door: brake, then the handbrake (S stopped is reverse)
			ad.steer_only()
			key(KEY_W, false)
			key(KEY_S, kmh() > 0.5 and -c.global_transform.basis.z.dot(c.linear_velocity) > 0.0)
			if kmh() < 0.5 and not c.parking_brake:
				c.set_parking_brake(true)
		else:
			key(KEY_S, false)
			ad.step(-1.0)
		stuck = stuck + 1.0 / 60.0 if kmh() < 2.0 and not hold else 0.0
		for pl in places:
			if not b.poi.has(pl[0]):
				continue
			var at: Vector3 = b.poi[pl[0]]
			if not marks.has(pl[0]) and Vector2(c.global_position.x - at.x, c.global_position.z - at.z).length() < float(pl[1]):
				marks[pl[0]] = t
		# the village (t_decoy): the fuel found and poured, no mistake
		if st.flags.has("fuel_low") and not st.flags.has("stall_fixed"):
			for f in ["key_got", "shed_open", "mistake_done", "stalled", "stall_fixed"]:
				st.flags[f] = true
			fv.match_story()
			c.fuel = 50.0
		# the salt pans (t_saltpans): it looks out to sea the whole time
		if sp.auto_sweep:
			sp.auto_sweep = false
			sp.gaze = sp._base + PI
		# the estuary (t_swing): swung back before the van gets there
		if not sb.locked and c.global_position.distance_to(sb.pivot) < 150.0:
			sb._lock(true)
		# the tunnel (t_tunnel): someone holds the winch while the van goes by
		if c.global_position.distance_to(rt.gate.global_position) < 70.0 and not st.flags.has("gate_through"):
			rt.winch.work_by(p2(), 1.0 / 60.0)
		# the mast (t_mast): done on the hill above while the van waits below
		if not st.flags.has("mast_done") and marks.has("mast_road"):
			for f in ["gen_running", "dish_1", "dish_2", "dish_3", "mast_done"]:
				st.flags[f] = true
			(get_tree().get_first_node_in_group("radio_mast") as RadioMast).match_story()
			# (players walk up to the mast for real: here the story moves on)
			if st.index < st.index_of("end_f7"):
				st.index = st.index_of("end_f7")
		if c.fuel < 8.0:
			c.fuel = 40.0
	ad.release()
	key(KEY_W, false)
	key(KEY_S, false)
	var times := []
	for pl in places:
		times.append("%s %s" % [pl[0], ("%.1f" % (float(marks[pl[0]]) / 60.0)) if marks.has(pl[0]) else "-"])
	log_line("RETURN: %s after %.1f min of driving; at (min): %s; objective '%s'" % ["home" if st.flags.has("end_reached") else "NOT home", t / 60.0, ", ".join(times), st.current()["id"]])
	if not st.flags.has("end_reached"):
		log_line("  stuck at %s, %.0f km/h, story '%s'" % [c.global_position, kmh(), st.current()["id"]])
		await shot("return_stuck")
	check(st.flags.has("naresh_home_done"), "the van drove Naresh home: the coast road, the pans, the swing bridge, the tunnel, past the mast")
	check(st.flags.has("end_reached"), "and on home along the West Road to the end (%.1f min of driving)" % (t / 60.0))
	await until(func() -> bool: return hc._end != null, 15.0)
	check(hc._end != null, "the end screen")
	if hc._end != null:
		hc._end.queue_free()
		hc._end = null


## The scenarios that start on the return themselves (they jump there).
const RETURN_SCENARIOS := ["storm", "storm_road", "decoy", "saltpans", "swing", "tunnel", "mast", "home", "step_jumps",
	"bessi_jumps", "return_run", "bessi_run", "decoy_save", "decoy_save_verify", "bessi_save", "bessi_save_verify"]


## Back to before the storm: every Bessi / return flag off, everything that
## follows the flags put back.
func _undo_return() -> void:
	var st: Story = boot.story
	for f in Story.BESSI_FLAGS:
		st.flags.erase(f)
	for f in ["flare_gun_found", "flares_used"]:
		st.flags.erase(f)
	for g in ["storm_front", "roses", "evidence", "bessi_tasks", "fishing_village", "salt_pans", "swing_bridge", "radio_mast", "homecoming"]:
		get_tree().call_group(g, "match_story")
	Creature.on_return = false
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.dark = 0.0
		mood.storm = 0.0
	log_line("(the return put away for this test)")


# --- the test sheet, walked as written (notes/TEST_MILESTONE_F.md) ---------------
# Only what a player can do: keys, mouse, pad; the F1 menu by its keys; no
# state set in code, no teleports the sheet doesn't ask for. A step that
# can't be done as written is a SHEET BLOCKER.

func sheet_step(ok: bool, what: String) -> bool:
	if not ok:
		log_line("SHEET BLOCKER: " + what)
	check(ok, "sheet " + what)
	return ok


## F1 → <tab> → the row whose text contains `part`, Enter, F1 to close.
func menu_pick(tab_name: String, part: String) -> bool:
	var dm: DevMenu = boot.dev_menu
	if not dm.open:
		await tap(KEY_F1)
		await physics_frames(3)
	var want := DevMenu.TABS.find(tab_name)
	var guard := 0
	while dm.tab != want and guard < 10:
		await tap(KEY_RIGHT)
		await physics_frames(2)
		guard += 1
	var row := -1
	for i in dm._rows.size():
		if not dm._rows[i]["header"] and String(dm._rows[i]["text"]).contains(part):
			row = i
			break
	if row < 0:
		log_line("menu: no row '%s' on %s" % [part, tab_name])
		await tap(KEY_F1)
		return false
	guard = 0
	while int(dm._sel.get(dm.tab, -1)) != row and guard < 200:
		await tap(KEY_DOWN if int(dm._sel.get(dm.tab, -1)) < row else KEY_UP)
		await physics_frames(1)
		guard += 1
	await tap(KEY_ENTER)
	await physics_frames(5)
	log_line("menu: %s → '%s' (%s)" % [tab_name, dm._rows[row]["text"], dm._note])
	await tap(KEY_F1)
	await wait(0.6)
	return true


## P2 walks with the left stick, facing where it goes.
func pad_walk_to(q: PlayerRig, target: Vector3, arrive := 0.8, max_s := 40.0) -> bool:
	var t := 0.0
	var mark := q.global_position
	var mark_t := 0.0
	while t < max_s:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var d := target - q.global_position
		d.y = 0.0
		if d.length() < arrive:
			pad_axis(JOY_AXIS_LEFT_Y, 0.0)
			return true
		q.yaw = atan2(-d.x, -d.z)
		q.rotation.y = q.yaw
		pad_axis(JOY_AXIS_LEFT_Y, -1.0)
		if t - mark_t > 2.0:
			if q.global_position.distance_to(mark) < 0.3:
				break
			mark = q.global_position
			mark_t = t
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	log_line("PAD WALK STUCK at %s, %.1f m short" % [q.global_position, Vector2(target.x - q.global_position.x, target.z - q.global_position.z).length()])
	return false


## Walk up to the van's driver door and E (P1).
## Round the van's nose first when you're on its other side (the straight-
## line walkers walked into its side: P2 after a jump, the F4 watched run).
func round_van(pl: PlayerRig, side: float, pad: bool) -> bool:
	var c := camper()
	var local := c.global_transform.affine_inverse() * pl.global_position
	if signf(local.x) == signf(side) or absf(local.x) < 0.5 and local.z < -3.0:
		return true
	for corner in [Vector3(signf(local.x) * 3.6, 0.0, -5.6), Vector3(signf(side) * 3.6, 0.0, -5.6)]:
		var at: Vector3 = c.global_transform * corner
		var ok: bool = await pad_walk_to(pl, at, 1.0, 20.0) if pad else await walk_to(pl, at, "round the van", 1.0, 20.0)
		if not ok:
			return false
	return true


func walk_in_driver(p: PlayerRig) -> bool:
	var c := camper()
	var stand := c.global_transform * Vector3(-3.4, 0.0, -1.8)
	if not await round_van(p, -1.0, false):
		return false
	if not await walk_to(p, stand, "the driver door", 0.8, 40.0):
		return false
	await look_at_point(p, c.global_transform * Vector3(-1.2, 1.4, -1.8))
	await physics_frames(3)
	await tap(KEY_E)
	await physics_frames(4)
	return p.seat != null


## P2 walks to the passenger door and presses X.
func pad_in_passenger(q: PlayerRig) -> bool:
	var c := camper()
	var stand := c.global_transform * Vector3(3.4, 0.0, -1.8)
	if not await round_van(q, 1.0, true):
		return false
	if not await pad_walk_to(q, stand):
		return false
	await look_at_point(q, c.global_transform * Vector3(1.2, 1.4, -1.8))
	await physics_frames(3)
	await pad_tap(JOY_BUTTON_X)
	await physics_frames(4)
	return q.seat != null


## F3, the fishing village, step by step as the sheet says.
func t_sheet_f3() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var fv := get_tree().get_first_node_in_group("fishing_village") as FishingVillage
	var c := camper()
	var p := p1()
	var q := p2()
	boot._on_joy_changed(0, true)
	await wait(0.3)
	# Getting there
	var picked := await menu_pick("Story", "Nearly out of fuel")
	var n := nz()
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	sheet_step(picked and st.current()["id"] == "village", "F3 getting there: F1 → Story → 'Nearly out of fuel...', Enter")
	sheet_step(p.global_position.distance_to(c.global_position) < 8.0 and n != null and n.global_position.distance_to(p.global_position) < 8.0,
		"F3: you both stand by the van, Naresh with you")
	sheet_step(c.fuel < 1.6 and mood.value < 0.4, "F3: the fuel lamp on (%.1f L), dusk (mood %.2f)" % [c.fuel, mood.value])
	# 1. walk in with Naresh (keep your distance)
	var edge := fv.centre + Vector3(-25, 0, 70)
	var walked := await walk_to(p, edge, "the village edge", 2.0, 60.0)
	var drawn := 0
	var tw := 0.0
	while tw < 12.0 and drawn < 2:
		await wait(0.5)
		tw += 0.5
		drawn = 0
		for cr in fv.creatures:
			drawn += int(cr.naresh_drawn)
	sheet_step(walked and drawn == 2, "F3.1 walk in with Naresh: the creatures turn towards him and drift his way (%d of 2)" % drawn)
	# 2. send him to the end of the jetty, with the binoculars from the beach
	var beach := fv.jetty_start + Vector3(-6, 0, 14)
	var to_beach := await walk_to(p, beach, "the beach by the jetty", 1.5, 60.0)
	sheet_step(to_beach, "F3.2 walk to the beach by the jetty")
	sheet_step(p.has_binoculars, "F3.2 the binoculars (hold RMB): P1 has them")
	mouse_button(MOUSE_BUTTON_RIGHT, true)
	await wait(0.6)
	var sent := await naresh_job(p, fv.jetty_end, "go")
	mouse_button(MOUSE_BUTTON_RIGHT, false)
	sheet_step(sent, "F3.2 look at the far end, hold V: 'Go and wait there' (%.0f m, through the binoculars)" % p.global_position.distance_to(fv.jetty_end))
	var out := await until(func() -> bool: return n.global_position.distance_to(fv.jetty_end) < 4.0, 90.0)
	sheet_step(out, "F3.2 he walks out to the end of the jetty")
	var clear := await until(func() -> bool:
		for cr in fv.creatures:
			if cr.global_position.distance_to(poi["net_shed"]) < 25.0:
				return false
		return true, 60.0)
	sheet_step(clear, "F3.2 the creatures follow him out; the shed side clears")
	# 3. one of you: the key (P1)
	var foot: Vector3 = poi["net_shed_crates"]
	var at_crates := await walk_to(p, foot, "the fish crates", 0.6, 40.0)
	var roof_y: float = (poi["net_shed_roof"] as Vector3).y
	p.yaw = -PI * 0.5
	p.rotation.y = p.yaw
	key(KEY_W, true)
	for _k in 7:
		await tap(KEY_SPACE)
		await wait(0.45)
	key(KEY_W, false)
	p.yaw = 0.0
	p.rotation.y = 0.0
	key(KEY_W, true)
	await tap(KEY_SPACE)
	await wait(0.8)
	key(KEY_W, false)
	await wait(0.3)
	sheet_step(at_crates and p.global_position.y > roof_y - 0.4, "F3.3 climb the fish crates (W and jump; at the top turn onto the roof)")
	await look_at_point(p, poi["net_shed_key"])
	await wait(0.2)
	var key_prompt := p.prompt_text
	await tap(KEY_E)
	await physics_frames(3)
	sheet_step(st.flags.has("key_got"), "F3.3 in the blue boat: E Take the key ('%s')" % key_prompt)
	# down again: walk off the roof's land side, round to the door
	var down := await walk_to(p, (poi["net_shed_door"] as Vector3) + Vector3(-4, 0, 6), "off the roof", 1.0, 20.0)
	await wait(0.6)
	var at_door := await walk_to(p, poi["net_shed_door"], "the shed door", 0.6, 20.0)
	await look_at_point(p, fv.door.global_position)
	await wait(0.2)
	var door_prompt := p.prompt_text
	await tap(KEY_E)
	await physics_frames(3)
	sheet_step(down and at_door and st.flags.has("shed_open"), "F3.3 down again, the shed door: E Unlock the shed ('%s')" % door_prompt)
	# 4. the other: watch him, call him back from the beach (P2, pad)
	var p2_spot := beach + Vector3(-3, 0, 3)
	var p2_there := await pad_walk_to(q, p2_spot, 1.5, 90.0)
	var closest := 999.0
	for cr in fv.creatures:
		closest = minf(closest, cr.global_position.distance_to(n.global_position))
	sheet_step(p2_there and n.state != Naresh.State.TAKEN, "F3.4 P2 on the beach in time (nearest creature %.0f m from him)" % closest)
	await look_at_point(q, n.global_position + Vector3.UP * 1.1)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await wait(0.6)
	pad_button(JOY_BUTTON_DPAD_UP, true)
	await physics_frames(5)
	pad_button(JOY_BUTTON_DPAD_UP, false)
	await physics_frames(4)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	sheet_step(n.state == Naresh.State.FOLLOW and n.leader == q, "F3.4 through the binoculars (LT), D-pad Up: 'Follow me' (%.0f m)" % q.global_position.distance_to(n.global_position))
	# 5. the fuel: P1 takes the heavy can to the van; P2 brings Naresh by the shed
	var heavy_at := fv.can_full.global_position
	var to_can := await walk_to(p, heavy_at + (fv.door.global_position - heavy_at).normalized() * 1.2, "the heavy can", 0.5, 20.0)
	await look_at_point(p, fv.can_full.global_position)
	await physics_frames(3)
	await tap(KEY_E)
	await physics_frames(3)
	sheet_step(to_can and p.held == fv.can_full, "F3.5 pick up the heavy can")
	var van_side := c.global_transform * Vector3(-3.0, 0, 1.0)
	var carried := await walk_to(p, van_side, "the van, with the can", 1.0, 90.0)
	await tap(KEY_E)               # E: drop
	await physics_frames(5)
	sheet_step(carried and p.held == null and fv.can_full.global_position.distance_to(c.global_position) < 8.0, "F3.5 carry it to the van and put it down (E)")
	var p2_shed := await pad_walk_to(q, (poi["net_shed_door"] as Vector3) + Vector3(-3, 0, 2), 1.5, 90.0)
	var helped := await until(func() -> bool: return fv._helped, 15.0)
	sheet_step(p2_shed and helped, "F3.5 Naresh by the shed: 'There's two! I'll take this one to the van.'")
	var mist := await until(func() -> bool: return st.flags.has("mistake_done"), 120.0)
	sheet_step(mist and fv.can_full.litres > 19.0, "F3.5 'Leave the fuel to me!' ... 'Done. I even checked it twice.' (the gauge doesn't move: %.1f L)" % c.fuel)
	# 6. drive on north
	var in1 := await walk_in_driver(p)
	var in2 := await pad_in_passenger(q)
	var aboard := await until(func() -> bool: return n.state == Naresh.State.SEATED, 25.0)
	sheet_step(in1 and in2 and aboard, "F3.6 get in (E / X); Naresh follows you into the back")
	await tap(KEY_X)
	await wait(0.5)
	var north: Route = boot.builder.network.road("coast_road")
	var x0 := c.global_position
	await drive_until(north, int(north.nearest(1640.0, -900.0)["index"]), func() -> bool: return st.flags.has("stalled"), 120.0, 40.0)
	key(KEY_W, false)
	var went := c.global_position.distance_to(x0)
	await wait(1.5)
	sheet_step(st.flags.has("stalled") and went > 120.0, "F3.6 drive on north: the engine dies %.0f m up the road" % went)
	sheet_step(boot.world.get_node_or_null("StallCreature") != null, "F3.6 up the road a creature steps out")
	# 7. pour it yourself
	await tap(KEY_E)                    # out of the van
	await physics_frames(5)
	var rack := c.rack_stand()
	var at_rack := await walk_to(p, rack, "the van's rack", 0.6, 20.0)
	await look_at_point(p, fv.can_full.global_position)
	await physics_frames(3)
	await tap(KEY_E)
	await physics_frames(3)
	sheet_step(at_rack and p.held == fv.can_full, "F3.7 the heavy can off the rack (E)")
	var at_filler := await walk_to(p, c.filler_stand(), "the filler", 0.5, 20.0)
	await look_at_point(p, c.filler_point())
	await hold_physics(KEY_E, 5.0)
	await until(func() -> bool: return st.current()["id"] == "end_f3", 3.0)
	sheet_step(at_filler and c.fuel > 15.0 and st.current()["id"] == "end_f3", "F3.7 hold E at the filler: the tank fills (%.0f L); on to the salt pans" % c.fuel)
	boot._set_layout(Boot.Layout.SOLO)


func t_storm_gym() -> void:
	var s := storm()
	var c := camper()
	check(s != null, "the storm gym has a storm")
	if s == null:
		return
	s.auto_gusts = false
	s.auto_flashes = false
	await wait(0.5)
	var near := maxf(p1().global_position.distance_to(c.global_position), p2().global_position.distance_to(c.global_position))
	check(near < 7.0, "both players start beside the van (%.1f m)" % near)
	await shot("storm_start")

	# the weather: the road wet, fog closing in, rain round each player
	check(is_equal_approx(c.wet, 1.0) and absf(c._wheels[0].wheel_friction_slip - 3.1 * Camper.WET_GRIP) < 0.01, "the road is wet: the tyres grip %.0f%% of dry" % (Camper.WET_GRIP * 100.0))
	var env := (boot.world.get_node("Environment") as WorldEnvironment).environment
	log_line("storm fog: begin %.0f m, end %.0f m, density %.2f" % [env.fog_depth_begin, env.fog_depth_end, env.fog_density])
	check(env.fog_depth_end <= 90.0 and env.fog_depth_begin <= 6.0, "the fog closes in (ends at %.0f m)" % env.fog_depth_end)
	var rains := s.find_children("*", "GPUParticles3D", false, false)
	check(rains.size() == 2 and (rains[0] as GPUParticles3D).emitting, "it rains round both players (%d emitters)" % rains.size())
	check(c.get_node_or_null("RainShield") != null, "the van's body keeps the rain out of the cab")
	check(s._hiss.target > 0.5 and s._wind.target > 0.1, "rain and wind are heard (rain %.2f, wind %.2f)" % [s._hiss.target, s._wind.target])

	# what you can see: from 200 m short of the boards, looking along the road
	await place_player(p1(), Vector3(-200, Landscape.ground(-200, 245) + 0.3, 245), -PI * 0.5)
	await wait(0.6)
	await shot("storm_boards")

	# lightning: the land lit for a moment, thunder after
	var amb0 := env.ambient_light_energy
	s.lightning()
	for _k in 6:
		await get_tree().process_frame
		log_line("  flash %.2f ambient %.2f" % [s.flash, env.ambient_light_energy])
	var lit := env.ambient_light_energy
	log_line("lightning: ambient %.2f -> %.2f, flash %.2f" % [amb0, lit, s.flash])
	check(s.flash > 0.4 and lit > amb0 + 0.5, "lightning lights the land for a moment")
	await shot("storm_flash")
	await wait(1.0)
	check(s.flash < 0.05, "the flash is over in a moment")

	# windsocks: hanging in the calm, streaming out in a gust
	var sock := boot.world.find_children("Windsock", "", true, false)[0] as Node3D
	var swing := sock.get_node("Turn/Swing") as Node3D
	var calm := rad_to_deg(swing.rotation.x)
	await face_point(p1(), sock.global_position + Vector3(0, 3.9, 0), 9.0, Vector3(1, 0, -0.4).normalized())
	await shot("storm_sock_calm")
	s.gust_now(1.0, Vector3(0, 0, -1))
	await wait(0.9)
	var early := rad_to_deg(swing.rotation.x)
	var early_gust := s.gust
	await wait(1.4)
	var full := rad_to_deg(swing.rotation.x)
	var tip := (swing.global_transform * Vector3(0, 0, -1.5)) - swing.global_position
	await shot("storm_sock_gust")
	log_line("windsock: calm %.0f deg, 0.9 s into a gust %.0f, at full %.0f; points %s" % [calm, early, full, tip.normalized()])
	check(calm < -55.0 and full > -15.0, "a windsock hangs in the calm and streams out in a gust")
	check(early > calm + 15.0 and early_gust < 0.7, "it lifts before the gust's full strength: a warning (gust %.2f then)" % early_gust)
	check(tip.z < -0.8, "it points where the wind blows")
	await wait(3.0)

	# the wipers: on in the rain with the engine running, parked when it stops
	await storm_start()
	await wait(0.4)
	var a0: float = c._wipers[0].rotation_degrees.z
	await wait(0.3)
	var a1: float = c._wipers[0].rotation_degrees.z
	check(c.wipers_on and absf(a1 - a0) > 5.0, "the wipers sweep in the rain with the engine on")
	await shot("storm_wipers")
	# the headlights in the rain: the road ahead lit to ~60 m
	await tap(KEY_L)
	await wait(0.4)
	check(c.headlights_on, "L puts the headlights on")
	await shot("storm_headlights")
	await tap(KEY_L)
	await tap(KEY_X)
	await wait(1.6)
	check(not c.wipers_on and absf(c._wipers[0].rotation_degrees.z - Camper.WIPE_REST) < 1.0, "engine off: they finish the sweep and park")

	# the gusts by speed: never under 25 km/h, over at 45+
	var r25 := await storm_run(25.0, 1.0)
	check(not r25[2] and r25[1] < 8.0, "a full gust at 25 km/h can't tip the van (leans %.1f deg)" % r25[1])
	await storm_leave()
	var r40 := await storm_run(40.0, 1.0)
	check(not r40[2], "at 40 km/h it leans hard but stays up (%.0f deg)" % r40[1])
	await storm_leave()
	var r70 := await storm_run(50.0, 0.7)
	check(not r70[2] and r70[0] > 0.6 and r70[0] < 3.0, "a 70%% gust at 50 km/h shoves it %.1f m sideways" % r70[0])
	await storm_leave()
	var r50 := await storm_run(50.0, 1.0)
	check(r50[2], "a full gust at 50 km/h tips it over")
	# put it back on its wheels the player's way: R
	await until(func() -> bool: return c.is_upset(), 6.0)
	await wait(0.3)
	await shot("storm_tipped")
	check(c.is_upset() and p1().prompt_text.contains("Right the van"), "lying on its side: '%s'" % p1().prompt_text)
	await tap(KEY_R)
	await wait(1.5)
	check(c.global_transform.basis.y.y > 0.95, "R puts it back on its wheels")
	await storm_leave()

	# careful driving gets through: 25 km/h, steering, a full gust every 5 s
	await storm_start()
	var ad := AutoDriver.new(self, boot.builder.network.road("gym_straight"), c)
	var most := 0.0
	var gt := 2.0
	var t := 0.0
	while c.global_position.x < 250.0 and t < 90.0:
		await physics_frames(1)
		t += 1.0 / 60.0
		ad.step(25.0)
		most = maxf(most, storm_roll())
		gt -= 1.0 / 60.0
		if gt <= 0.0:
			gt = 5.0
			s.gust_now(1.0, Vector3(0, 0, -1))
	ad.release()
	log_line("careful run: %d gusts, most roll %.1f deg, %.1f s off the road, most %.1f m off the line" % [s.gusts, most, ad.off_time, ad.max_off])
	check(c.global_position.x >= 250.0 and most < 8.0 and ad.off_time < 0.5, "at 25 km/h a careful driver gets through every gust")

	# stopping on the wet road from 50 km/h, against a dry one
	var stops := []
	for w in [0.0, 1.0]:
		s.intensity = w
		await physics_frames(2)
		await storm_start()
		var ad2 := AutoDriver.new(self, boot.builder.network.road("gym_straight"), c)
		var t2 := 0.0
		while kmh() < 50.0 and t2 < 20.0:
			await physics_frames(1)
			t2 += 1.0 / 60.0
			ad2.step(55.0)
		ad2.release()
		var x0 := c.global_position.x
		key(KEY_S, true)
		await until(func() -> bool: return kmh() < 1.0, 10.0)
		key(KEY_S, false)
		stops.append(c.global_position.x - x0)
	log_line("stopping from 50 km/h: dry %.1f m, wet %.1f m" % [stops[0], stops[1]])
	check(stops[1] > stops[0] * 1.15, "it takes longer to stop on the wet road (%.0f m, dry %.0f m)" % [stops[1], stops[0]])
	s.intensity = 1.0

	# the frame rate in the storm, both views, driving
	boot._on_joy_changed(0, true)
	await wait(0.3)
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	await storm_start()
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	s.auto_gusts = true
	s.auto_flashes = true
	var ad3 := AutoDriver.new(self, boot.builder.network.road("gym_straight"), c)
	var t3 := 0.0
	_frame_times.clear()
	while t3 < 6.0:
		await physics_frames(1)
		t3 += 1.0 / 60.0
		ad3.step(25.0)
	ad3.release()
	var avg := 0.0
	for f in _frame_times:
		avg += f
	var fps := float(_frame_times.size()) / maxf(avg, 0.001)
	log_line("fps in the storm, both views, driving: %.0f" % fps)
	check(headless or fps >= 120.0, "the storm keeps the frame rate (%.0f fps)" % fps)
	await shot("storm_split")
	key(KEY_S, true)
	await until(func() -> bool: return kmh() < 2.0, 6.0)
	key(KEY_S, false)

	# and off again: dry, clear, no rain
	s.intensity = 0.0
	await wait(0.5)
	check(is_equal_approx(c.wet, 0.0) and env.fog_depth_end > 300.0 and not (rains[0] as GPUParticles3D).emitting, "the storm off: dry road, the fog lifts, no rain")
	s.intensity = 1.0
	boot._set_layout(Boot.Layout.SOLO)
	await storm_leave()


## E3, the photo gym: two pairs of poles line up from one spot only; fixes
## how far off it still counts (Alignment.TOLERANCE, 2 m).
## `GYM=photo tools/run_test.sh photo_gym`
func t_photo_gym() -> void:
	var a: Alignment = boot.builder.photo_gym
	var spot: Vector3 = boot.builder.poi["photo_gym_spot"]
	check(a != null and a.spot().distance_to(Vector3(spot.x, a.spot().y, spot.z)) < 0.1, "the two lines cross at the marked spot")
	check(a.aligned(spot), "on the spot both pairs line up")
	var p := p1()
	for spec in [[Vector3(1.5, 0, 0), true, "1.5 m to the side"], [Vector3(0, 0, 1.8), true, "1.8 m back"],
			[Vector3(2.5, 0, 0), false, "2.5 m to the side"], [Vector3(0, 0, 10), false, "10 m back along the red line"],
			[Vector3(0, 0, -40), false, "between the red poles"]]:
		var at: Vector3 = spot + spec[0]
		var eye := at + Vector3.UP * 1.56
		var apart: Array = a.apart_deg(eye)
		log_line("%s: %.1f m off, the pairs look %.1f and %.1f degrees apart" % [spec[2], a.off(at), apart[0], apart[1]])
		check(a.aligned(at) == spec[1], "%s: %s" % [spec[2], "still on the spot" if spec[1] else "not the spot"])
	await place_player(p, spot + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, spot + Vector3(4, 5, -20))
	await shot("photo_gym_spot")
	await place_player(p, spot + Vector3(2.0, 0.3, 0), 0.0)
	await look_at_point(p, spot + Vector3(4, 5, -20))
	await shot("photo_gym_2m_off")


## E3, the photo in the world: reaching the beach, Naresh's photo comes to
## P2's phone (only P2's); standing on the spot and looking along it finds
## it; a step off, or looking away, doesn't. `tools/run_test.sh photo`
func t_photo() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var bessi := get_tree().get_first_node_in_group("bessi") as Bessi
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var p := p1()
	var q := p2()
	check(st.index_of("photo") > 0 and bessi != null and bessi.photo != null, "the story has the photo step")
	st.flags.erase("photo_sent")
	st.flags.erase("photo_spot")
	st.photo_texture = null
	st.jump_to(st.index_of("to_beach"))
	mood.set_now(0.4)
	await place_player(p, poi["beach"] + Vector3(0, 0.3, 0), 0.0)
	await place_player(q, poi["beach"] + Vector3(2, 0.3, 0), 0.0)
	var on := await until(func() -> bool: return st.current()["id"] == "photo", 3.0)
	check(on, "reaching the beach: 'Find where Naresh's photo was taken'")
	var sent := await until(func() -> bool: return st.flags.has("photo_sent"), Bessi.PHOTO_DELAY + 6.0)
	check(sent, "a few seconds later the photo arrives")
	var p2_msg: Dictionary = st.phone_threads[1][-1]
	var p1_msg: Dictionary = st.phone_threads[0][-1]
	check(p2_msg.get("photo", false) and String(p2_msg["body"]).contains("me and him at Bessi"), "on P2's phone: the photo, 'me and him at Bessi!'")
	check(not p1_msg.get("photo", false) and String(p1_msg["body"]).contains("P2"), "P1 gets words only: it went to P2")
	check(headless or st.photo_texture != null, "the photo is a real picture of the place")
	if st.photo_texture != null:
		st.photo_texture.get_image().save_png("res://_shots/test_photo_image.png")
		log_line("shot test_photo_image.png (the photo itself)")
	q.phone_open = true
	await wait(0.6)
	var pic := boot.huds[1].find_child("Photo", true, false) as TextureRect
	check(pic != null and pic.is_visible_in_tree() and pic.texture != null, "P2's phone shows it")
	boot._set_layout(Boot.Layout.SIDE_BY_SIDE)
	await wait(0.3)
	await shot("photo_phone")
	q.phone_open = false
	# off the spot, facing the right way: nothing
	var spot: Vector3 = poi["photo_spot"]
	var tip: Vector3 = poi["memorial_spire"]
	var side := Vector3(-(tip - spot).z, 0, (tip - spot).x).normalized()
	await place_player(p, spot + side * 3.0 + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, tip)
	await wait(2.0)
	check(not st.flags.has("photo_spot"), "3 m off the spot it doesn't count")
	# on the spot, looking away: nothing
	await place_player(p, spot + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, spot + (spot - tip).normalized() * 10.0)
	await wait(2.0)
	check(not st.flags.has("photo_spot"), "on the spot but looking away doesn't count")
	# tag the mast from the spot, the way the other player would point it out
	await look_at_point(p, poi["mast_top"] + Vector3(0, -1.5, 0))
	await tap(KEY_T)
	var tagm := TagMarker.of(p.index)
	check(tagm != null and tagm.thing.contains("mast"), "the mast can be tagged (\"%s\")" % (tagm.thing if tagm else "-"))
	# on the spot, looking at the memorial: found
	await look_at_point(p, tip)
	var found := await until(func() -> bool: return st.flags.has("photo_spot"), 3.0)
	check(found, "on the spot, looking along the photo: found")
	await wait(0.5)
	check(st.current()["id"] == "roses", "and the story moves on")
	check(boot.huds[0]._note.visible and boot.huds[0]._note_text.text.contains("He stood exactly here"), "'He stood exactly here.'")
	await look_at_point(p, (tip + poi["mast_top"]) * 0.5)
	await shot("photo_found_view")
	# a load: the story comes back as saved; the picture is taken again (it
	# isn't in the save file), without sending the texts a second time
	var texts: int = st.phone_threads[1].size()
	st.from_dict(st.to_dict())
	st.photo_texture = null
	var again := await until(func() -> bool: return st.photo_texture != null, 3.0)
	check((headless or again) and st.phone_threads[1].size() == texts and st.current()["id"] == "roses",
		"after a load the photo is back on P2's phone, the texts not sent twice")
	mood.set_now(0.62)


## E4, the Five Roses: sunk until the photo spot is found; the smoke rolls
## in and they rise; a wrong carving resets them; in travel order (windmill,
## water, bridge, wave, star) they open; the fifth comes down with Naresh in
## it, who gets up when you come close. `tools/run_test.sh roses`
func t_roses() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var p := p1()
	check(ro != null and st.index_of("roses") > 0, "the roses and their story step are there")
	if ro == null:
		return
	for f in ["photo_spot", "roses_up", "roses_open", "naresh_met"]:
		st.flags.erase(f)
	ro.reset()        # the photo test before this one sets them off
	if boot.naresh != null and is_instance_valid(boot.naresh) and boot.gym == "":
		boot.naresh.queue_free()
		boot.naresh = null
	st.jump_to(st.index_of("photo"))
	mood.set_now(0.4)
	var r0 := ro.roses[0] as Node3D
	check(ro.phase == "sunk" and not r0.visible, "before the photo spot the roses are sunk out of sight")
	# watch from the edge of the plaza, facing in
	var watch: Vector3 = ro.centre + (poi["photo_spot"] - ro.centre).normalized() * 40.0
	watch.y = Landscape.ground(watch.x, watch.z) + 0.3
	await place_player(p, watch, 0.0)
	await look_at_point(p, ro.centre + Vector3.UP * 12.0)
	st.flags["photo_spot"] = true
	await physics_frames(10)
	check(ro.phase == "sunk", "not straight away: the finding is read first")
	var smoke := await until(func() -> bool: return ro.phase == "smoke", Roses.AFTER_PHOTO + 2.0)
	check(smoke and st.current()["id"] == "roses" and boot.huds[0]._note_text.text.contains("smoke"), "a few seconds later the smoke comes (\"Out at sea...\"), the objective is the roses")
	# turn round to the sea: the bank rolling in
	await look_at_point(p, ro._sea_at + Vector3.UP * 4.0)
	await wait(5.0)
	await shot("roses_smoke")
	await wait(4.0)
	await shot("roses_smoke_near")
	await look_at_point(p, ro.centre + Vector3.UP * 12.0)
	var up := await until(func() -> bool: return ro.phase == "up", Roses.SMOKE_S + Roses.RISE_S + 3.0)
	check(up and r0.visible and absf(r0.position.y - float(ro._up_y[0])) < 0.05, "out of the smoke the five rise")
	await wait(1.0)
	await shot("roses_up")
	# the carvings: a wrong first one closes everything
	var star_k := Roses.SLOT_SYMBOL.find("star")
	var star_c := ro.carvings[star_k] as Node3D
	await face_point(p, star_c.global_position + Vector3.UP * 1.2, 1.8, (ro.centre - star_c.global_position).normalized())
	log_line("at the star carving: '%s'" % p.prompt_text)
	check(p.prompt_text.contains("Touch the carving"), "a carving offers 'Touch the carving'")
	await tap(KEY_E)
	await wait(0.3)
	check(int(st.flags.get("roses_open", 0)) == 0 and boot.huds[0]._note_text.text.contains("close again"), "the star first: the smoke surges and nothing opens")
	# the right order
	for i in 5:
		var sym: String = Roses.ORDER[i]
		var k := Roses.SLOT_SYMBOL.find(sym)
		var c := ro.carvings[k] as Node3D
		await face_point(p, c.global_position + Vector3.UP * 1.2, 1.8, (ro.centre - c.global_position).normalized())
		await tap(KEY_E)
		await wait(0.3)
		check(int(st.flags.get("roses_open", 0)) == i + 1, "the %s opens its rose (%d of 5)" % [sym, i + 1])
		if i == 1:
			await wait(Roses.OPEN_S)
			await look_at_point(p, (ro.roses[k] as Node3D).global_position + Vector3.UP * 30.0)
			await shot("roses_one_open")
	await wait(Roses.OPEN_S)
	check(ro.open_amount.all(func(a): return a > 0.99), "all five are open")
	# the fifth comes down with him in it
	await place_player(p, watch, 0.0)
	await look_at_point(p, ro.naresh_seat + Vector3.UP * 2.0)
	var down := await until(func() -> bool: return ro.phase == "done", Roses.BLOOM_DOWN_S + 2.0)
	var nz: Naresh = boot.naresh
	check(down and nz != null and nz.sitting and nz.global_position.distance_to(ro.naresh_seat) < 0.3, "the fifth bloom comes down: Naresh is sitting in it")
	check(st.current()["id"] == "naresh", "'Someone is sitting in the fifth rose'")
	await wait(1.0)
	await shot("roses_naresh_far")
	var to_seat := ro.naresh_seat - ro.centre
	to_seat.y = 0.0
	var near := ro.naresh_seat - to_seat.normalized() * 6.0
	near.y = Landscape.ground(near.x, near.z) + 0.3
	await place_player(p, near + Vector3(0, 0.5, 0), 0.0)
	await look_at_point(p, ro.naresh_seat + Vector3.UP * 0.8)
	await shot("roses_naresh_near")
	var met := await until(func() -> bool: return st.flags.has("naresh_met"), 3.0)
	await physics_frames(5)
	check(met and not nz.sitting and nz.said_since("You came!", 0) and nz.leader == p, "close up he gets down: 'You came! He said you would.' and follows")
	check(st.current()["id"] == "look_around", "and the story moves on")
	await wait(2.0)
	await look_at_point(p, nz.global_position + Vector3.UP * 1.2)
	await shot("roses_naresh_met")
	mood.set_now(0.62)


## E5, the evidence: his camp in the fifth rose (one bag slept in, one still
## in its plastic with the tag, the camera on its timer, the notebook's "we"
## over "I") and one set of footprints; each says only what you see; he
## packs while you look, then comes along. `tools/run_test.sh evidence`
func t_evidence() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var ev := get_tree().get_first_node_in_group("evidence") as Evidence
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var p := p1()
	check(ev != null and ev.print_points.size() > 100, "the camp and the footprints are built (%d prints)" % (ev.print_points.size() if ev else 0))
	if ev == null:
		return
	mood.set_now(0.4)
	# the prints: one set, left-right, from the promenade to the camp
	var first := ev.print_points[0]
	var last := ev.print_points[ev.print_points.size() - 1]
	var gaps_ok := true
	for i in range(1, ev.print_points.size()):
		var g := Vector2(ev.print_points[i].x - ev.print_points[i - 1].x, ev.print_points[i].z - ev.print_points[i - 1].z).length()
		if g < 0.4 or g > 1.3:
			gaps_ok = false
	check(Vector2(first.x - poi["photo_spot"].x, first.z - poi["photo_spot"].z).length() < 2.0 and Vector2(last.x - ev.camp.x, last.z - ev.camp.z).length() < 2.0 and gaps_ok,
		"one set of footprints, a step apart, from the photo spot to the camp")
	# the rose done, Naresh just met (as E4 leaves it)
	for f in ["photo_spot", "roses_up", "roses_open", "naresh_met", "packing", "packed"]:
		st.flags.erase(f)
	for it in Evidence.ITEMS:
		st.flags.erase("seen_" + String(it[0]))
	ro.reset()
	st.flags["photo_spot"] = true
	st.flags["roses_up"] = true
	st.flags["roses_open"] = 5
	st.flags["naresh_met"] = true
	st.jump_to(st.index_of("look_around"))
	var nz: Naresh = boot.naresh
	if nz == null or not is_instance_valid(nz):
		nz = Naresh.spawn(boot.world, ev.camp + Vector3(3, 0.3, 3), 0.0)
		boot.naresh = nz
	nz.sitting = false
	nz.command(p, "follow")
	await place_player(p, ev.camp + (ro.centre - ev.camp).normalized() * 5.0 + Vector3.UP * 0.3, 0.0)
	var shown := await until(func() -> bool: return ro.phase == "done" and ev.camp_root.visible, 3.0)
	check(shown, "with the fifth rose down, his camp is there")
	var packing := await until(func() -> bool: return st.flags.has("packing"), Evidence.GREET_S + 2.0)
	check(packing and nz.said_since("gone for a walk", 0), "he goes to pack: 'My friend's gone for a walk, he'll be back in a bit.'")
	await look_at_point(p, ev.camp + Vector3.UP * 0.4)
	await wait(2.0)
	await shot("evidence_camp")
	# look at each thing, as a player would (E)
	for spec in [["spare", "price tag"], ["camera", "self-timer"], ["notebook", "we got to Bessi"]]:
		var body := ev.camp_root.get_node("Evidence_" + spec[0]) as Node3D
		await face_point(p, body.global_position + Vector3.UP * 0.25, 1.6, (p.global_position - body.global_position).normalized())
		log_line("at %s: '%s'" % [spec[0], p.prompt_text])
		await tap(KEY_E)
		await wait(0.3)
		var txt: String = boot.huds[0]._note_text.text
		check(p.prompt_text.contains("Look at") or st.flags.has("seen_" + spec[0]), "%s: a 'Look at' prompt" % spec[0])
		check(st.flags.has("seen_" + spec[0]) and txt.contains(spec[1]), "%s: it says what you see (\"...%s...\")" % [spec[0], spec[1]])
		if spec[0] == "notebook":
			await shot("evidence_notebook")
	var nothing_told := true
	for it in Evidence.ITEMS:
		var t := String(it[2]).to_lower()
		for w in ["friend", "imagin", "alone", "nobody", "no one", "lie"]:
			if t.contains(w):
				nothing_told = false
				log_line("%s says '%s'" % [it[0], w])
	check(nothing_told, "none of it spells it out (no 'friend', 'alone', 'imagined'...)")
	var packed := await until(func() -> bool: return st.flags.has("packed"), 3.0)
	await physics_frames(3)
	check(packed and nz.said_since("All packed", 0) and nz.state == Naresh.State.FOLLOW, "three things seen: he's packed and comes along")
	check(st.current()["id"] == "batteries", "and the story moves on")
	# the prints, from the dune looking back down to the beach
	await place_player(p, ev.print_points[int(ev.print_points.size() * 0.7)] + Vector3.UP * 0.4, 0.0)
	await look_at_point(p, ev.print_points[int(ev.print_points.size() * 0.35)])
	await shot("evidence_prints")
	mood.set_now(0.62)


## F1 → Story jumps into Bessi set the world up to match (the user jumped to
## "Someone is sitting in the fifth rose" and found an empty plaza), and a
## jump back puts it away again. `tools/run_test.sh bessi_jumps`
func t_bessi_jumps() -> void:
	var st: Story = boot.story
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var ev := get_tree().get_first_node_in_group("evidence") as Evidence
	var dm: DevMenu = boot.dev_menu
	boot.dev_menu.teleport_to("roses")
	await physics_frames(10)
	dm.run("jump", st.index_of("naresh"))
	var sat := await until(func() -> bool: return ro.phase == "done" and boot.naresh != null and boot.naresh.sitting, Roses.BLOOM_DOWN_S + 3.0)
	check(sat and ro.open_amount.all(func(a): return a > 0.99), "jump to 'Someone is sitting in the fifth rose': the roses are up and open, he's in the fifth")
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	check(mood.value <= 0.41, "and it's dusk, as at the beach")
	await look_at_point(p1(), ro.naresh_seat + Vector3.UP)
	await shot("jump_naresh")
	dm.run("jump", st.index_of("look_around"))
	await wait(0.5)
	var nz: Naresh = boot.naresh
	log_line("after the jump: naresh %s sitting %s, camp %s, phase %s, objective %s" % [nz != null, nz.sitting if nz else false, ev.camp_root.visible, ro.phase, st.current()["id"]])
	check(nz != null and not nz.sitting and ev.camp_root.visible and st.current()["id"] == "look_around", "jump to 'packing up': he's out with you, his camp is there")
	var packing := await until(func() -> bool: return st.flags.has("packing"), Evidence.GREET_S + 2.0)
	check(packing, "and he goes to pack")
	dm.run("jump", st.index_of("photo"))
	await wait(0.5)
	check(ro.phase == "sunk" and not (ro.roses[0] as Node3D).visible and boot.naresh == null, "jump back to the photo: the roses are sunk again, no Naresh")
	dm.run("jump", st.index_of("roses"))
	var rising := await until(func() -> bool: return ro.phase in ["smoke", "rising", "up"], Roses.AFTER_PHOTO + 3.0)
	check(rising, "jump to 'The Five Roses': the smoke comes and they rise")


## P2 on a controller (the real one, or a pretend one on device 0).
func p2_pad() -> void:
	if boot.devices[1].kind != InputDevice.Kind.PAD:
		boot._on_joy_changed(0, true)
		await physics_frames(3)


## E6 N1, the store: Naresh holds the heavy shutter, you both crouch in; he
## lets go once (shut in), opens it again; the box takes two, carried out.
## `tools/run_test.sh shutter`
func t_shutter() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
	var p := p1()
	var q := p2()
	boot.dev_menu.run("jump", st.index_of("batteries"))
	await wait(0.5)
	var nz: Naresh = boot.naresh
	check(bt != null and nz != null and st.current()["id"] == "batteries", "the store step, Naresh along")
	await p2_pad()
	var door: Vector3 = poi["store_door"]
	await place_player(p, door + Vector3(2.0, 0.3, 1.0), 0.0)
	nz.global_position = door + Vector3(3.0, 0.3, -1.0)
	nz.reset_physics_interpolation()
	await physics_frames(3)
	check(bt.handle.amount < 0.01, "the shutter is down")
	check(await naresh_job(p, bt.handle.global_position, "hold", true), "V on the handle: 'Hold the shutter'")
	var up := await until(func() -> bool: return bt.handle.amount >= 0.99, 15.0)
	check(up, "he holds it up (%.2f m)" % bt.shutter.position.y)
	await shot("shutter_held")
	# crouch in under it, for real
	key(KEY_CTRL, true)
	var inn := await walk_to(p, bt.store.global_position + Vector3(-0.6, 0, 0.5), "under the shutter", 0.6, 10.0)
	key(KEY_CTRL, false)
	check(inn and bt.inside(p), "P1 crouches in under it")
	await place_player(q, bt.store.global_position + Vector3(-0.6, 0.3, -0.6), 0.0)
	var slip := await until(func() -> bool: return st.flags.has("n1_slip"), BessiTasks.SLIP_AFTER + 3.0)
	var down := await until(func() -> bool: return bt.handle.amount <= 0.01, 2.0)
	check(slip and down and nz.said_since("Oops", 0), "with you both in he lets go: 'Oops! My friend was telling me something...'")
	await look_at_point(p, bt.store.global_position + Vector3(2.0, 0.6, 0))
	await shot("shutter_shut_in")
	var reopened := await until(func() -> bool: return bt.handle.amount >= 0.99, BessiTasks.SLIP_BACK + 8.0)
	check(reopened and nz.said_since("Sorry", 0), "then he opens it again: 'Sorry! Sorry. Got it.'")
	# the box: two to carry it
	await face_point(p, bt.box.global_position + Vector3.UP * 0.25, 1.1, Vector3(1, 0, 0.6))
	await tap(KEY_E)
	await look_at_point(q, bt.box.global_position + Vector3.UP * 0.25)
	await physics_frames(3)
	pad_button(JOY_BUTTON_X, true)
	await physics_frames(4)
	pad_button(JOY_BUTTON_X, false)
	await physics_frames(4)
	check(bt.box.holders.size() == 2, "you both take hold of the box (%d holding)" % bt.box.holders.size())
	# out under the shutter together, a step at a time
	for i in 12:
		var step := Vector3(0.5, 0, 0)
		await place_player(p, p.global_position + step + Vector3.UP * 0.05, p.yaw)
		await place_player(q, q.global_position + step + Vector3.UP * 0.05, q.yaw)
	var got := await until(func() -> bool: return st.flags.has("batteries_got"), 3.0)
	check(got and p.flashlight_seconds >= 599.0 and q.flashlight_seconds >= 599.0, "carried out: fresh batteries in both torches")
	await physics_frames(5)
	check(st.current()["id"] == "drum", "and the story moves on to the drum")
	p.drop_held()
	q.drop_held()


## E6 N2, the boat: three push at once; Naresh goes round the wrong side
## until he's told again; off it comes, and the drum under it takes two.
## `tools/run_test.sh boat`
func t_boat() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
	var p := p1()
	var q := p2()
	boot.dev_menu.run("jump", st.index_of("drum"))
	await wait(0.5)
	var nz: Naresh = boot.naresh
	await p2_pad()
	var push: Vector3 = poi["boat_push"]
	await place_player(p, push + Vector3(0, 0.3, -1.0), 0.0)
	await place_player(q, push + Vector3(0, 0.3, 1.0), 0.0)
	nz.global_position = push + Vector3(-3, 0.3, 0)
	nz.reset_physics_interpolation()
	check(not bt.boat.is_done and bt.drum.freeze, "the boat lies over the drum")
	var hull_pt := bt.boat.global_position + Vector3(0, 0.7, 0)
	check(await naresh_job(p, hull_pt, "work", true), "V on the boat: 'Work the boat'")
	await look_at_point(p, hull_pt)
	await look_at_point(q, hull_pt)
	key(KEY_E, true)
	pad_button(JOY_BUTTON_X, true)
	await wait(6.0)
	var far_side := nz.global_position.x > bt.boat.global_position.x + 1.0
	log_line("pushing with him the wrong way: boat %.2f, hands %d, Naresh at %s (boat %s)" % [bt.boat.amount, bt.boat.hands_last, nz.global_position, bt.boat.global_position])
	check(bt.naresh_wrong and far_side and bt.boat.amount < 0.01 and nz.said_since("Is it moving", 0),
		"he goes round the far side and pushes back: 'Is it moving? It's not moving.' and it doesn't budge")
	await shot("boat_wrong_way")
	key(KEY_E, false)
	await physics_frames(3)
	check(await naresh_job(p, hull_pt, "work", true), "told again (V on the boat)")
	await look_at_point(p, hull_pt)
	await look_at_point(q, hull_pt)
	key(KEY_E, true)
	for i in 8:
		await wait(1.0)
		log_line("after telling him: wrong %s, told %d (wrong at %d), job '%s' step %d, state %s, at %s, hands %d, boat %.2f" % [bt.naresh_wrong, nz.commands_given, bt._wrong_at, nz.job, nz.job_step, Naresh.State.keys()[nz.state], nz.global_position, bt.boat.hands_last, bt.boat.amount])
		if bt.boat.is_done:
			break
	var off := await until(func() -> bool: return bt.boat.is_done, 12.0)
	key(KEY_E, false)
	pad_button(JOY_BUTTON_X, false)
	await physics_frames(3)
	check(off and nz.said_since("THAT way", 0), "the right side now ('Oh! THAT way.'), three pushing: off it slides")
	check(st.flags.has("drum_free") and not bt.drum.freeze, "the drum is free")
	await wait(1.0)
	check(st.current()["id"] == "storm", "and the story moves on (the storm next)")
	await look_at_point(p, bt.drum.global_position + Vector3.UP * 0.4)
	await shot("boat_off")
	# two to carry it
	await face_point(p, bt.drum.global_position + Vector3.UP * 0.45, 1.1, Vector3(-1, 0, 0.5))
	await tap(KEY_E)
	await face_point(q, bt.drum.global_position + Vector3.UP * 0.45, 1.1, Vector3(-1, 0, -0.5))
	pad_button(JOY_BUTTON_X, true)
	await physics_frames(4)
	pad_button(JOY_BUTTON_X, false)
	await physics_frames(4)
	check(bt.drum.holders.size() == 2 and bt.drum.litres > 39.0, "you both lift the full drum (40 L)")
	p.drop_held()
	q.drop_held()


## E7, the storm: both jobs done, and a few seconds later the sky over the way
## you came goes black (lightning, thunder, the light going), the roses sink,
## Naresh: "My friend says we should go north." Everyone in the van, north on
## the coast road. `tools/run_test.sh storm`
func t_storm() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var sf := get_tree().get_first_node_in_group("storm_front") as StormFront
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var c := camper()
	var p := p1()
	boot.dev_menu.run("jump", st.index_of("drum"))
	await wait(0.5)
	var nz: Naresh = boot.naresh
	check(sf != null and not sf.started and nz != null, "before the drum is free, no storm")
	await place_player(p, poi["beach"] + Vector3(-10, 0.3, 0), 0.0)
	await look_at_point(p, sf.root.global_position + Vector3.UP * 150.0)
	st.flags["drum_free"] = true
	await physics_frames(10)
	check(not sf.started, "not at once")
	var came := await until(func() -> bool: return sf.started, StormFront.AFTER + 2.0)
	check(came and sf.root.visible and st.current()["id"] == "storm", "a few seconds later the storm comes; the objective: north on the coast road")
	await physics_frames(5)
	check(nz.said_since("we should go north", 0), "Naresh: 'My friend says we should go north.'")
	check(ro.phase in ["sinking", "gone"], "the roses sink back into the sand")
	var flash := await until(func() -> bool: return sf.flashes > 0, StormFront.FLASH.y + 3.0)
	var thunder := await until(func() -> bool: return sf._thunder.playing, 4.0)
	check(flash and (headless or thunder), "lightning in the clouds, thunder a moment later")
	await wait(9.0)
	check(mood.value <= 0.32 and ro.phase == "gone", "the light goes (mood %.2f); the roses are gone" % mood.value)
	await shot("storm_front")
	# into the van, Naresh too, and north
	var road: Route = boot.builder.network.road("coast_road")
	var i0 := 0
	for i in road.point_count():
		if road.point(i).z < 470.0:
			i0 = i
			break
	boot.dev_menu.van_to(road.point(i0), atan2(-road.forward(i0).x, -road.forward(i0).z))
	await physics_frames(30)
	nz.command(p, "follow")
	await place_player(p, c.global_transform * Vector3(-3, 0, -1) + Vector3.UP * 0.3, 0.0)
	nz.global_position = c.global_transform * Vector3(4, 0, 0) + Vector3.UP * 0.3
	nz.reset_physics_interpolation()
	await seat_p1_driver()
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	var aboard := await until(func() -> bool: return nz.state == Naresh.State.SEATED, 15.0)
	check(aboard, "he follows you into the back of the van")
	await engine_on()
	var path: Route = boot.builder.network.chain([["coast_road"]])
	var t := await drive_until(path, int(path.nearest(1728.0, 250.0)["index"]), func() -> bool: return st.current()["id"] == "end_e", 60.0)
	log_line("north on the coast road: %.0f s, van at %s" % [t, c.global_position])
	check(st.current()["id"] == "end_e", "north on the coast road with him in the back: the end of Bessi")
	await shot("storm_north")


## Saving at Bessi, after the storm starts: the story, the roses gone, the
## storm, Naresh in the back, the drum on the rack, his camp, the photo on
## P2's phone all come back. `tools/run_test.sh bessi_save` (its own process:
## loading reloads the scene)
func t_bessi_save() -> void:
	var st: Story = boot.story
	var c := camper()
	var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
	for i in [2]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path(i)))
	boot.dev_menu.run("jump", st.index_of("storm"))
	await wait(1.0)
	var nz: Naresh = boot.naresh
	boot.dev_menu.van_to(boot.builder.poi["beach"] + Vector3(-60, 0, 0), 0.0)
	await physics_frames(30)
	# you in front, him following you into the back
	await seat_p1_driver()
	p2().enter_seat(c, c.seat_nodes["passenger"], "passenger")
	nz.command(p1(), "follow")
	nz.global_position = c.global_transform * Vector3(3.5, 0, 0) + Vector3.UP * 0.3
	nz.reset_physics_interpolation()
	var sat := await until(func() -> bool: return nz.state == Naresh.State.SEATED, 15.0)
	log_line("before saving: objective %s, storm %s, Naresh %s" % [st.current()["id"], st.flags.has("storm_on"), Naresh.State.keys()[nz.state]])
	bt.drum.freeze = false
	bt.drum.stow(c.free_slot_for(bt.drum))
	await physics_frames(5)
	check(sat and bt.drum.stowed_in != null and st.flags.has("storm_on"), "at Bessi, after the storm: Naresh in the back, the drum on the rack")
	check(SaveGame.write(boot, 2), "the journal writes the save")
	PlayTest.expect = {"objective": st.current()["id"], "drum_slot": c.storage_slots.find(bt.drum.stowed_in)}
	PlayTest.carried_failures = _failures.duplicate()
	PlayTest.resume = "bessi_save_verify"
	boot.load_slot(2)


## F3 saved and loaded: the key taken, the shed open, his mistake armed with
## the light can on the rack. `tools/run_test.sh decoy_save` (its own process)
func t_decoy_save() -> void:
	var st: Story = boot.story
	var fv := get_tree().get_first_node_in_group("fishing_village") as FishingVillage
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path(2)))
	boot.dev_menu.run("jump", st.index_of("fuel"))
	await wait(0.5)
	var c := camper()
	fv.can_empty.stow(c.free_slot_for(fv.can_empty))
	nz().refuel_mistake = true
	await physics_frames(5)
	check(st.flags.has("shed_open") and not fv.door.visible and not fv.key_node.visible, "the shed open, the key taken")
	check(SaveGame.write(boot, 2), "the journal writes the save")
	PlayTest.carried_failures = _failures.duplicate()
	PlayTest.resume = "decoy_save_verify"
	boot.load_slot(2)


func t_decoy_save_verify() -> void:
	await wait(2.0)
	var st: Story = boot.story
	var fv := get_tree().get_first_node_in_group("fishing_village") as FishingVillage
	await physics_frames(5)
	log_line("after loading: objective %s, door %s, key %s, the light can %s, mistake %s" % [st.current()["id"], fv.door.visible, fv.key_node.visible, fv.can_empty.stowed_in, nz().refuel_mistake if nz() else "-"])
	check(st.current()["id"] == "fuel" and not fv.door.visible and not fv.key_node.visible, "loaded: still 'fuel into the van', the shed open, the key gone")
	check(fv.can_empty.stowed_in != null and fv._helped and nz() != null and nz().refuel_mistake, "the light can on the rack, his mistake still to come")
	check(Creature.on_return, "and the creatures still follow him")


func t_bessi_save_verify() -> void:
	await wait(2.0)
	var st: Story = boot.story
	var c := camper()
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var sf := get_tree().get_first_node_in_group("storm_front") as StormFront
	var ev := get_tree().get_first_node_in_group("evidence") as Evidence
	var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
	var nz: Naresh = boot.naresh
	log_line("after loading: objective %s (saved %s), storm %s, roses %s, Naresh %s" % [st.current()["id"], PlayTest.expect["objective"], st.flags.has("storm_on"), ro.phase, Naresh.State.keys()[nz.state] if nz else "none"])
	check(st.current()["id"] == PlayTest.expect["objective"] and st.flags.has("storm_on"), "loading at Bessi: the storm objective, the storm on")
	check(ro.phase == "gone" and not (ro.roses[0] as Node3D).visible and sf.started and sf.root.visible, "the roses gone, the storm over the ghat")
	check(nz != null and nz.state == Naresh.State.SEATED and nz.van == c, "Naresh back in the back of the van")
	var slot: int = PlayTest.expect["drum_slot"]
	var it := c.stowed_item(c.storage_slots[slot])
	check(it != null and it.name == bt.drum.name and (it as FuelCan).litres > 39.0, "the fuel drum back on the rack, full")
	check(ev.camp_root.visible and bt.boat.is_done, "his camp still there, the boat still off the drum")
	var pic := await until(func() -> bool: return st.photo_texture != null, 3.0)
	check(headless or pic, "the photo back on P2's phone")


## E7: all of Bessi in one go, from the ghat pass to north in the storm, the
## beats timed against design/BESSI.md (24:00 arrival to 31:00 the storm,
## about 7 minutes). Driving by the auto-driver, the puzzles by their real
## calls (each is tested with the real keys in its own scenario).
## `tools/run_test.sh bessi_run` (Full only)
func t_bessi_run() -> void:
	var st: Story = boot.story
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	var p := p1()
	var q := p2()
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	var ev := get_tree().get_first_node_in_group("evidence") as Evidence
	var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
	var sf := get_tree().get_first_node_in_group("storm_front") as StormFront
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	boot.dev_menu.run("jump", st.index_of("to_beach"))
	mood.set_now(0.62)
	c.repair_all()
	var t0 := Time.get_ticks_msec()
	var beats := []
	var beat := func(what: String): beats.append("%s %.1f min" % [what, (Time.get_ticks_msec() - t0) / 60000.0])
	# down the Beach Road to the loop
	var road: Route = boot.builder.network.road("beach_road")
	boot.dev_menu.van_to(road.point(2), atan2(-road.forward(2).x, -road.forward(2).z))
	await physics_frames(30)
	await seat_p1_driver()
	q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await engine_on()
	var down: Route = boot.builder.network.chain([["beach_road"]])
	await drive_until(down, down.point_count() - 8, func() -> bool: return c.nav_signal_lost and c.global_position.distance_to(ro.centre) < 250.0, 240.0)
	check(c.nav_signal_lost, "coming into Bessi the nav loses its signal")
	beat.call("arrival")
	await tap(KEY_X)
	p.force_exit = true
	await physics_frames(3)
	q.force_exit = true
	await physics_frames(3)
	# the beach, the photo, the spot
	await place_player(p, poi["beach"] + Vector3(0, 0.3, 0), 0.0)
	await place_player(q, poi["beach"] + Vector3(2, 0.3, 0), 0.0)
	await until(func() -> bool: return st.flags.has("photo_sent"), 20.0)
	beat.call("the photo")
	await place_player(p, poi["photo_spot"] + Vector3(0, 0.3, 0), 0.0)
	await look_at_point(p, poi["memorial_spire"])
	await until(func() -> bool: return st.flags.has("photo_spot"), 5.0)
	beat.call("the spot found")
	await until(func() -> bool: return ro.phase == "up", Roses.AFTER_PHOTO + Roses.SMOKE_S + Roses.RISE_S + 5.0)
	beat.call("the roses up")
	for sym in Roses.ORDER:
		ro.touch(Roses.SLOT_SYMBOL.find(sym), p)
		await wait(1.0)
	await until(func() -> bool: return ro.phase == "done", Roses.BLOOM_DOWN_S + 3.0)
	await place_player(p, ro.naresh_seat + (ro.centre - ro.naresh_seat).normalized() * 6.0 + Vector3(0, -2.0, 0), 0.0)
	await until(func() -> bool: return st.flags.has("naresh_met"), 5.0)
	beat.call("Naresh")
	var nz: Naresh = boot.naresh
	check(nz != null and st.flags.has("naresh_met"), "found Naresh in the fifth rose")
	await until(func() -> bool: return st.flags.has("packing"), Evidence.GREET_S + 3.0)
	for id in ["spare", "camera", "notebook"]:
		ev.look(id, p)
		await wait(3.0)
	await until(func() -> bool: return st.flags.has("packed"), 5.0)
	beat.call("the evidence")
	# N1: he holds the shutter, you both go in, the slip, the box out
	nz.command(p, "hold", bt.handle)
	await until(func() -> bool: return bt.handle.amount >= 0.99, 30.0)
	await place_player(p, bt.store.global_position + Vector3(-0.6, 0.3, 0.5), 0.0)
	await place_player(q, bt.store.global_position + Vector3(-0.6, 0.3, -0.6), 0.0)
	await until(func() -> bool: return st.flags.has("n1_slip") and bt.handle.amount >= 0.99, BessiTasks.SLIP_AFTER + BessiTasks.SLIP_BACK + 10.0)
	p.pick_up(bt.box)
	q.pick_up(bt.box)
	for i in 12:
		await place_player(p, p.global_position + Vector3(0.5, 0.05, 0), p.yaw)
		await place_player(q, q.global_position + Vector3(0.5, 0.05, 0), q.yaw)
	await until(func() -> bool: return st.flags.has("batteries_got"), 3.0)
	p.drop_held()
	q.drop_held()
	check(st.flags.has("batteries_got"), "N1: the batteries")
	beat.call("the store")
	# N2: three push, told twice
	await p2_pad()
	var push: Vector3 = poi["boat_push"]
	await place_player(p, push + Vector3(0, 0.3, -1.0), 0.0)
	await place_player(q, push + Vector3(0, 0.3, 1.0), 0.0)
	var hull := bt.boat.global_position + Vector3(0, 0.7, 0)
	nz.global_position = push + Vector3(-3, 0.3, 0)      # he followed you down to the boat
	nz.reset_physics_interpolation()
	nz.command(p, "work", bt.boat)
	await wait(4.0)                                      # round the wrong side first
	await look_at_point(p, hull)
	await look_at_point(q, hull)
	key(KEY_E, true)
	pad_button(JOY_BUTTON_X, true)
	await wait(5.0)
	nz.command(p, "work", bt.boat)
	for i in 12:
		await wait(2.0)
		log_line("boat: %.2f, hands %d, wrong %s, Naresh %s '%s' at %s, P1 target %s, P2 target %s" % [bt.boat.amount, bt.boat.hands_last, bt.naresh_wrong,
			Naresh.State.keys()[nz.state], nz.job, nz.global_position, p.current_target.name if p.current_target else "-", q.current_target.name if q.current_target else "-"])
		if bt.boat.is_done:
			break
	key(KEY_E, false)
	pad_button(JOY_BUTTON_X, false)
	check(st.flags.has("drum_free"), "N2: the drum")
	beat.call("the boat")
	# the storm, into the van, north
	await until(func() -> bool: return sf.started, StormFront.AFTER + 3.0)
	beat.call("the storm")
	var cr: Route = boot.builder.network.road("coast_road")
	var i0 := 0
	for i in cr.point_count():
		if cr.point(i).z < 470.0:
			i0 = i
			break
	boot.dev_menu.van_to(cr.point(i0), atan2(-cr.forward(i0).x, -cr.forward(i0).z))
	await physics_frames(30)
	nz.command(p, "follow")
	nz.global_position = c.global_transform * Vector3(4, 0, 0) + Vector3.UP * 0.3
	nz.reset_physics_interpolation()
	await seat_p1_driver()
	q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
	await until(func() -> bool: return nz.state == Naresh.State.SEATED, 15.0)
	await engine_on()
	var north: Route = boot.builder.network.chain([["coast_road"]])
	await drive_until(north, int(north.nearest(1728.0, 250.0)["index"]), func() -> bool: return st.current()["id"] == "end_e", 60.0)
	beat.call("north")
	log_line("BESSI RUN: " + ", ".join(beats))
	var mins := (Time.get_ticks_msec() - t0) / 60000.0
	# (teleports between places: the minutes are not the pacing, the order is)
	check(st.current()["id"] == "end_e", "all of Bessi in order, from the pass to north in the storm (%.1f min of test)" % mins)


## F1 → Story → a Bessi step puts you both where it happens, Naresh at your
## side (from the evidence on) and the van close by; "The storm is coming"
## leaves you by the van on the coast road, ready to drive north. The user
## jumped to "Fuel for the coast road", travelled to the beach and found no
## Naresh (he'd been left by the rose). `tools/run_test.sh step_jumps`
func t_step_jumps() -> void:
	var st: Story = boot.story
	var dm: DevMenu = boot.dev_menu
	var poi: Dictionary = boot.builder.poi
	var c := camper()
	var p := p1()
	for id in ["photo", "naresh", "look_around", "batteries", "drum", "storm"]:
		dm.run("jump", st.index_of(id))
		await wait(0.6)
		var nz: Naresh = boot.naresh
		var place: String = DevMenu.STEP_PLACES[id][0]
		var here: bool = place == "" or p.global_position.distance_to(poi[place]) < 10.0
		var with_him: bool = id not in ["look_around", "batteries", "drum", "storm"] or (nz != null and nz.global_position.distance_to(p.global_position) < 6.0 and nz.leader == p)
		var van_near := c.global_position.distance_to(p.global_position) < 40.0
		log_line("jump to %s: P1 %.1f m from its place, Naresh %s, van %.0f m, note '%s'" % [id, p.global_position.distance_to(poi[place]) if place != "" else 0.0,
			"%.1f m" % nz.global_position.distance_to(p.global_position) if nz != null else "none", c.global_position.distance_to(p.global_position), dm._note])
		check(here and with_him and van_near and st.current()["id"] == id, "F1 jump to '%s': you're there%s, the van close by" % [id, ", Naresh with you" if id in ["look_around", "batteries", "drum", "storm"] else ""])
		if id == "drum":
			var bt := get_tree().get_first_node_in_group("bessi_tasks") as BessiTasks
			check(not bt.boat.is_done and bt.drum.freeze, "at the boat: the drum still under it, ready to push")
			await shot("jump_drum")
	# the storm step: get in and drive
	await seat_p1_driver()
	var nz2: Naresh = boot.naresh
	var aboard := await until(func() -> bool: return nz2.state == Naresh.State.SEATED, 15.0)
	check(aboard, "get in: Naresh climbs into the back")
	await engine_on()
	var north: Route = boot.builder.network.chain([["coast_road"]])
	await drive_until(north, int(north.nearest(1728.0, 250.0)["index"]), func() -> bool: return st.current()["id"] == "end_e", 60.0)
	check(st.current()["id"] == "end_e", "and drive north: the end of Bessi")
	# the Story tab shows every step, the storm among them
	dm.toggle()
	dm.set_tab(DevMenu.TABS.find("Story"))
	var row := -1
	for i in dm._rows.size():
		if dm._rows[i]["action"] == "jump" and int(dm._rows[i]["arg"]) == st.index_of("storm"):
			row = i
	check(row >= 0 and String(dm._rows[row]["text"]).contains("The storm is coming"), "F1 → Story lists 'The storm is coming'")
	if row >= 0:
		dm._select(row, true)
	await wait(0.3)
	await shot("f1_story_storm")
	dm.toggle()



## The engine running: X only if it isn't (a toggle; an earlier test may
## have left it on, and a blind X switched it off).
func engine_on() -> void:
	if not camper().engine_on:
		await tap(KEY_X)
	await wait(0.8)
