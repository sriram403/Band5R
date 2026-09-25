class_name Boot
extends Node

## Prototype session root: builds the world, the two players and the
## split-screen shell, and owns input-device assignment.

const P1_TINT := Color(0.98, 0.76, 0.30)
const P2_TINT := Color(0.45, 0.82, 0.98)

# Godot's Camera3D.fov is vertical. Each half of a side-by-side split is taller
# than it is wide, so it needs a large vertical FOV to give a sane horizontal
# one; stacked halves are the opposite.
const FOV_SIDE_BY_SIDE := 78.0
const FOV_STACKED := 46.0
const FOV_SOLO := 62.0

## SOLO shows only the player the keyboard currently drives, full screen. It is
## the default when no controller is connected, so testing alone does not
## leave half the screen showing a player nobody is controlling.
enum Layout { SIDE_BY_SIDE, STACKED, SOLO }

var world: Node3D
var builder: LevelBuilder
var camper: Camper
var players: Array[PlayerRig] = []
var devices: Array[InputDevice] = []
var huds: Array[PlayerHUD] = []
var viewports: Array[SubViewport] = []

var split: BoxContainer
var overlay: Control
var overlay_text: RichTextLabel
var started := false
var paused := false
var kbm_owner := 0                 ## which player the keyboard/mouse drives
var layout: int = Layout.SIDE_BY_SIDE
var views: Array[SubViewportContainer] = []

const SETTINGS_PATH := "user://settings.cfg"
const SENS_STEPS := [0.4, 0.55, 0.7, 0.85, 1.0, 1.2, 1.45, 1.75, 2.1, 2.5]
var mouse_sens := 1.0
var map_state: MapState
## Menu shown on the overlay: "title", "load", "pause", "quit_confirm" or "".
var menu := "title"
var menu_sel := 0
var menu_from := "title"          ## where "Back" in the load list returns to
var _saved_sig := ""              ## story signature at the last save/load/new game
var story: Story
var _explore_t := 0.0
## A line shown on the pause screen until it is resumed (a controller dropped out).
var pause_note := ""

# Dev capture mode: `--shot` runs a scripted sequence and writes PNGs next to
# the project, so the look can be reviewed without playing.
var shot_mode := false
## Automated play-test running: never grab the mouse (the window sits off screen).
var testing := false
## Name of the gym (test map) loaded instead of the world, or "" for the game.
## From `-- --gym=<name>`, or set before reloading the scene (the dev menu does;
## "" there means the game world). "?" = nothing requested yet.
static var gym_request := "?"
var gym := ""
var dev_menu: DevMenu
var _frame := 0
var _shot_n := 0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	if gym_request != "?":
		gym = gym_request
	else:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--gym"):
				gym = a.get_slice("=", 1) if a.contains("=") else "base"
	builder = GymBuilder.new(gym) if gym != "" else LevelBuilder.new()
	world = builder.build()
	# Main runs as PROCESS_MODE_ALWAYS so the pause menu keeps working; the
	# simulation itself must stay pausable or ESC would not actually stop it.
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	map_state = MapState.new()
	map_state.name = "MapState"
	map_state.add_to_group("map_state")
	add_child(map_state)
	map_state.setup(builder)

	_spawn_camper()
	_load_settings()
	_assign_devices()
	_build_ui()
	_spawn_players()
	if gym == "house":
		players[1].flashlight_seconds = 0.0
	story = Story.new()
	story.name = "Story"
	story.add_to_group("story")
	add_child(story)
	story.setup(self)
	_set_layout(Layout.SOLO if devices[1].kind == InputDevice.Kind.KBM else Layout.SIDE_BY_SIDE)
	dev_menu = DevMenu.new()
	dev_menu.name = "DevMenu"
	dev_menu.boot = self
	add_child(dev_menu)
	if gym != "":
		# straight in: no title menu in a gym
		started = true
		menu = ""
		overlay.visible = false
		if not testing:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	Input.joy_connection_changed.connect(_on_joy_changed)
	print("[Boot] world built in %d ms" % (Time.get_ticks_msec() - t0))
	print("[Boot] user data: %s" % OS.get_user_data_dir())
	if OS.get_user_data_dir().to_upper().begins_with("C:"):
		push_warning("User data is on C:. Launch with Play.bat so it stays in MPG/appdata.")
	_refresh_overlay()
	if SaveGame.pending_load >= 0:
		var slot := SaveGame.pending_load
		SaveGame.pending_load = -1
		_apply_load.call_deferred(SaveGame.read(slot))
	shot_mode = OS.get_cmdline_args().has("--shot") or OS.get_cmdline_user_args().has("--shot")
	if shot_mode:
		started = true
		menu = ""
		overlay.visible = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playtest"):
			testing = true
			started = true
			menu = ""
			overlay.visible = false
			var pt := PlayTest.new()
			pt.boot = self
			add_child(pt)


# --- world ---------------------------------------------------------------------

func _spawn_camper() -> void:
	camper = Camper.new()
	camper.name = "Camper"
	world.add_child(camper)
	camper.transform = builder.camper_spawn


func _spawn_players() -> void:
	var tints := [P1_TINT, P2_TINT]
	for i in 2:
		var p := PlayerRig.new()
		p.name = "Player%d" % (i + 1)
		world.add_child(p)
		p.set_player_index(i)
		p.recolor(tints[i])
		p.dev = devices[i]
		p.transform = builder.player_spawns[i]
		p.yaw = p.transform.basis.get_euler().y
		players.append(p)

		var cam := Camera3D.new()
		cam.name = "Cam%d" % (i + 1)
		cam.fov = FOV_SIDE_BY_SIDE
		cam.near = 0.06
		cam.far = 5000.0      # across the 4 km map to the backdrop ridges and the sea horizon
		cam.cull_mask = PlayerRig.cull_mask_for(i)
		# The rig places this camera itself every rendered frame from
		# interpolated transforms; engine interpolation on top would add lag.
		cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		viewports[i].add_child(cam)
		cam.current = true
		p.set_view_camera(cam)

		huds[i].setup(p, camper, _hud_title(i), tints[i])


func _hud_title(i: int) -> String:
	if devices[i].kind == InputDevice.Kind.KBM and devices[1 - i].kind == InputDevice.Kind.KBM:
		return "P%d  Keyboard + Mouse  (TAB switches player)" % (i + 1)
	return "P%d  %s" % [i + 1, devices[i].label()]


# --- devices -------------------------------------------------------------------

func _assign_devices() -> void:
	var pads := Input.get_connected_joypads()
	var d1 := InputDevice.keyboard()
	var d2: InputDevice
	if pads.size() > 0:
		d2 = InputDevice.gamepad(pads[0])
	else:
		d2 = InputDevice.keyboard()
	devices = [d1, d2]
	_apply_kbm_owner()


func _apply_kbm_owner() -> void:
	for i in devices.size():
		var d := devices[i]
		if d.kind == InputDevice.Kind.KBM:
			d.active = (i == kbm_owner)
			d.look_sensitivity = mouse_sens
		else:
			d.active = true


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		mouse_sens = float(cfg.get_value("input", "mouse_sensitivity", 1.0))


func _step_sensitivity(dir: int) -> void:
	var idx := 0
	for k in SENS_STEPS.size():
		if absf(SENS_STEPS[k] - mouse_sens) < absf(SENS_STEPS[idx] - mouse_sens):
			idx = k
	mouse_sens = SENS_STEPS[clampi(idx + dir, 0, SENS_STEPS.size() - 1)]
	_apply_kbm_owner()
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sens)
	cfg.save(SETTINGS_PATH)
	if paused:
		_show_pause()


func _on_joy_changed(device: int, connected: bool) -> void:
	if connected and devices.size() == 2 and devices[1].kind == InputDevice.Kind.KBM:
		_set_p2_device(InputDevice.gamepad(device))
		_set_layout(Layout.SIDE_BY_SIDE)
	elif not connected and devices.size() == 2 and devices[1].kind == InputDevice.Kind.PAD and devices[1].pad == device:
		# P2's pad dropped out (flat battery, cable): pause, like a console
		# does, and hand P2 to another pad if there is one, else the keyboard
		# (solo view, TAB switches) until one is plugged in again.
		var others := Input.get_connected_joypads()
		others.erase(device)
		_set_p2_device(InputDevice.gamepad(others[0]) if others.size() > 0 else InputDevice.keyboard())
		if devices[1].kind == InputDevice.Kind.KBM:
			_set_layout(Layout.SOLO)
		if started and not paused:
			_toggle_pause()
		pause_note = "Player 2's controller disconnected. Reconnect it to carry on in split-screen, or play on alone (TAB switches player)."
	_refresh_overlay()


func _set_p2_device(d: InputDevice) -> void:
	devices[1] = d
	if players.size() > 1:
		players[1].dev = d
	kbm_owner = 0
	_apply_kbm_owner()
	if huds.size() > 1:
		huds[0]._who.text = _hud_title(0)
		huds[1]._who.text = _hud_title(1)


# --- ui ------------------------------------------------------------------------

func _build_ui() -> void:
	var back := ColorRect.new()
	back.name = "Letterbox"
	back.color = Color(0.05, 0.05, 0.07)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)

	split = BoxContainer.new()
	split.name = "Split"
	split.vertical = false
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 4)
	split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(split)

	for i in 2:
		var svc := SubViewportContainer.new()
		svc.name = "View%d" % (i + 1)
		svc.stretch = true
		svc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		split.add_child(svc)
		views.append(svc)

		var sv := SubViewport.new()
		sv.name = "Viewport%d" % (i + 1)
		sv.handle_input_locally = false
		sv.physics_object_picking = false
		sv.own_world_3d = false          # share the root World3D with the level
		sv.msaa_3d = Viewport.MSAA_4X
		sv.positional_shadow_atlas_size = 2048
		sv.audio_listener_enable_3d = (i == 0)
		svc.add_child(sv)
		viewports.append(sv)

		var hud := PlayerHUD.new()
		hud.name = "HUD%d" % (i + 1)
		sv.add_child(hud)
		huds.append(hud)

	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	overlay_text = RichTextLabel.new()
	overlay_text.bbcode_enabled = true
	overlay_text.fit_content = false
	overlay_text.scroll_active = false
	overlay_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_text.offset_left = 90
	overlay_text.offset_right = -90
	overlay_text.offset_top = 60
	overlay_text.offset_bottom = -50
	overlay_text.add_theme_font_size_override("normal_font_size", 17)
	overlay_text.add_theme_font_size_override("bold_font_size", 17)
	overlay_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(overlay_text)


func _refresh_overlay() -> void:
	if overlay_text == null:
		return
	var items := _menu_items()
	var menu_txt := ""
	for i in items.size():
		var sel := i == menu_sel
		var label: String = items[i]
		if menu == "load" and i < SaveGame.SLOTS and not SaveGame.exists(i):
			label = "[color=#777777]%s[/color]" % label
		menu_txt += ("[color=#ffcf6b]>  %s  <[/color]" if sel else "%s") % label + "\n"
	var nav := "[color=#9fd8ff]W/S or Up/Down[/color] choose  ·  [color=#9fd8ff]Enter[/color] select  ·  pad: D-pad + A"
	match menu:
		"pause":
			var note := "[color=#ffcf6b]%s[/color]\n\n" % pause_note if pause_note != "" else ""
			overlay_text.text = "[center]" + note + "[font_size=30]PAUSED[/font_size]\n\n%s\n%s\n\nMouse sensitivity  [color=#ffcf6b]%.2f[/color]   ([color=#9fd8ff][lb][/color] lower  ·  [color=#9fd8ff][rb][/color] higher)\n[color=#9fd8ff]TAB[/color] switch player  ·  [color=#9fd8ff]F2[/color] layout  ·  [color=#9fd8ff]F11[/color] fullscreen  ·  [color=#9fd8ff]ESC[/color] resume[/center]" % [menu_txt, nav, mouse_sens]
			return
		"load":
			overlay_text.text = "[center][font_size=30]LOAD A JOURNAL ENTRY[/font_size]\n\n%s\n%s  ·  ESC back[/center]" % [menu_txt, nav]
			return
		"quit_confirm":
			overlay_text.text = "[center][font_size=26]Quit without saving?[/font_size]\n\nEverything since your last journal entry will be lost.\n\n%s\n%s[/center]" % [menu_txt, nav]
			return
	var pad_note := ""
	if devices.size() > 1 and devices[1].kind != InputDevice.Kind.PAD:
		pad_note = "\n[color=#ffcf6b]No controller detected.[/color] Solo view: you play one player full screen. Press [b]TAB[/b] to jump to the other player, [b]F2[/b] for split-screen. Plug a controller in at any time and it becomes Player 2 with split-screen automatically."
	overlay_text.text = """[center][font_size=34][color=#ff6b7d]FINDING NARESH[/color] — Bessi and the 5 Roses[/font_size]
[font_size=18][color=#9fd8ff]DEMO BUILD  ·  milestone A[/color][/font_size]

[font_size=22]%s[/font_size]%s[/center]
[b]INPUT ASSIGNMENT[/b]
  Player 1 — %s
  Player 2 — %s%s

[b]ON FOOT[/b]   (keyboard)  WASD move · Mouse look · Shift sprint · Ctrl crouch · Space jump · [color=#9fd8ff]E[/color] interact · F flashlight · LMB throw · M map · H hint
[b]ON FOOT[/b]   (pad)       Left stick move · Right stick look · L3 sprint · B crouch · A jump · [color=#9fd8ff]X[/color] interact · Y flashlight · RB throw · D-Down map · R3 hint

[b]DRIVING[/b]   (keyboard)  W throttle · S brake / reverse · A/D steer · Space handbrake · [color=#9fd8ff]X[/color] ignition · L headlights · C swap seats · E get out · J journal
[b]DRIVING[/b]   (pad)       RT throttle · LT brake / reverse · Left stick steer · B handbrake · D-Up ignition · D-Left headlights · LB swap seats · X get out · D-Right journal

[b]OTHER[/b]  [lb] / [rb] mouse sensitivity · TAB switch player (solo) · F2 layout · F11 fullscreen · R right a tipped van · ESC pause""" % [
		menu_txt, nav,
		devices[0].label() if devices.size() > 0 else "-",
		devices[1].label() if devices.size() > 1 else "-",
		pad_note]


# --- loop ----------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	# Boot sits above the world in the tree, so this runs before any player or
	# vehicle reads input in the same physics tick.
	for d in devices:
		d.poll()
	# fill the paper map in as the players travel
	_explore_t -= _delta
	if _explore_t <= 0.0 and started and map_state != null:
		_explore_t = 0.4
		var where := []
		for p in players:
			where.append(p.global_position)
		map_state.explore(where)


func _process(_delta: float) -> void:
	if shot_mode:
		_shot_sequence()
		return

	if not started:
		return

	if not paused and Input.is_key_pressed(KEY_F3):
		_teleport_to_camper()


func _begin() -> void:
	started = true
	menu = ""
	overlay.visible = false
	if not testing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mark_saved()


# --- menus -----------------------------------------------------------------------

func _menu_items() -> Array:
	match menu:
		"title":
			return ["New game", "Load game", "Quit"]
		"pause":
			return ["Resume", "Load game", "Quit"]
		"load":
			var out := []
			for i in SaveGame.SLOTS:
				out.append(SaveGame.summary(i))
			out.append("Back")
			return out
		"quit_confirm":
			return ["Keep playing", "Quit without saving"]
	return []


func _menu_move(dir: int) -> void:
	var n := _menu_items().size()
	if n > 0:
		menu_sel = wrapi(menu_sel + dir, 0, n)
		Sfx.play_ui("ui_move")
		_refresh_overlay()


func _menu_accept() -> void:
	var item_i := menu_sel
	Sfx.play_ui("ui_ok")
	match menu:
		"title":
			match item_i:
				0: _begin()
				1: _open_menu("load", "title")
				2: get_tree().quit()
		"pause":
			match item_i:
				0: _toggle_pause()
				1: _open_menu("load", "pause")
				2:
					if is_dirty():
						_open_menu("quit_confirm", "pause")
					else:
						get_tree().quit()
		"load":
			if item_i >= SaveGame.SLOTS:
				_menu_back()
			elif SaveGame.exists(item_i):
				load_slot(item_i)
		"quit_confirm":
			if item_i == 0:
				_menu_back()
			else:
				get_tree().quit()


func _menu_back() -> void:
	Sfx.play_ui("ui_back")
	match menu:
		"load", "quit_confirm":
			_open_menu(menu_from, "title")
		"pause":
			_toggle_pause()


func _open_menu(m: String, from: String) -> void:
	menu = m
	menu_from = from
	menu_sel = 0
	_refresh_overlay()


func load_slot(slot: int) -> void:
	SaveGame.pending_load = slot
	get_tree().paused = false
	get_tree().reload_current_scene()


func _apply_load(d: Dictionary) -> void:
	if d.is_empty():
		return
	SaveGame.apply(self, d)
	_begin()
	for p in players:
		p.say("You open the travel journal and read back the day. (Loaded: %s)" % d.get("meta", {}).get("place", "?"), 5.0)


func mark_saved() -> void:
	_saved_sig = story.progress_signature() if story else ""


func is_dirty() -> bool:
	return story != null and story.progress_signature() != _saved_sig


func _any_pad_start() -> bool:
	for p in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(p, JOY_BUTTON_START):
			return true
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and started and not paused:
		for d in devices:
			# screen_relative: real mouse pixels. `relative` is scaled by the
			# window stretch, so look speed changed with the window size
			# (full screen at 1080p turned ~17 % slower than the 1600x900 window).
			d.feed_mouse((event as InputEventMouseMotion).screen_relative)
		return
	if started and not paused:
		for d in devices:
			d.feed_event(event)

	# menus (title, pause, load) with keyboard or any controller
	if menu != "" and event.is_pressed() and not event.is_echo():
		if event is InputEventKey:
			match (event as InputEventKey).keycode:
				KEY_UP, KEY_W:
					_menu_move(-1)
					return
				KEY_DOWN, KEY_S:
					_menu_move(1)
					return
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
					_menu_accept()
					return
		elif event is InputEventJoypadButton:
			match (event as InputEventJoypadButton).button_index:
				JOY_BUTTON_DPAD_UP:
					_menu_move(-1)
				JOY_BUTTON_DPAD_DOWN:
					_menu_move(1)
				JOY_BUTTON_A, JOY_BUTTON_START:
					if menu == "pause" and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
						_toggle_pause()
					else:
						_menu_accept()
				JOY_BUTTON_B:
					_menu_back()
			return
	elif started and event is InputEventJoypadButton and event.is_pressed() and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		_toggle_pause()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_TAB:
				if devices.size() > 1 and devices[1].kind == InputDevice.Kind.KBM:
					kbm_owner = 1 - kbm_owner
					_apply_kbm_owner()
					_set_layout(layout)
			KEY_F2:
				_set_layout((layout + 1) % 3)
			KEY_F11:
				var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_ESCAPE:
				if menu in ["load", "quit_confirm"]:
					_menu_back()
				elif started and not paused and _esc_dismiss():
					pass
				elif started:
					_toggle_pause()
			KEY_BRACKETLEFT:
				_step_sensitivity(-1)
			KEY_BRACKETRIGHT:
				_step_sensitivity(1)


## ESC first puts away whatever the keyboard player has open (journal, paper
## map, then a note on screen); only with nothing open does it pause.
func _esc_dismiss() -> bool:
	if kbm_owner >= players.size():
		return false
	var p: PlayerRig = players[kbm_owner]
	if p.journal_open:
		p.journal_open = false
		return true
	if p.map_open:
		p.set_map_open(false)
		return true
	return kbm_owner < huds.size() and huds[kbm_owner].dismiss_note()


func _toggle_pause() -> void:
	if not started:
		return
	paused = not paused
	overlay.visible = paused
	if not testing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	get_tree().paused = paused
	if not paused:
		pause_note = ""
	menu = "pause" if paused else ""
	menu_sel = 0
	_refresh_overlay()


func _show_pause() -> void:
	_refresh_overlay()


func _set_layout(l: int) -> void:
	layout = l
	split.vertical = (l == Layout.STACKED)
	# Solo shows whoever holds the keyboard; with a controller attached both
	# players are live, so solo just shows P1.
	var shown := kbm_owner if devices[1].kind == InputDevice.Kind.KBM else 0
	for i in views.size():
		views[i].visible = (l != Layout.SOLO) or i == shown
		viewports[i].audio_listener_enable_3d = (i == shown)
	var f := FOV_SIDE_BY_SIDE
	if l == Layout.STACKED:
		f = FOV_STACKED
	elif l == Layout.SOLO:
		f = FOV_SOLO
	for p in players:
		if p.cam:
			p.cam.fov = f


# --- dev capture ---------------------------------------------------------------

func _shot_sequence() -> void:
	_frame += 1
	match _frame:
		50:
			players[0].pitch = -0.05
			players[1].pitch = -0.02
			_shoot("01_on_foot")
		60:
			players[0].enter_seat(camper, camper.seat_nodes["driver"], "driver")
			players[1].enter_seat(camper, camper.seat_nodes["passenger"], "passenger")
			camper.toggle_engine()
		90:
			players[0].pitch = -0.34
			players[1].pitch = -0.20
		100:
			_shoot("02_dashboard")
		110:
			players[0].pitch = -0.05
			players[1].pitch = 0.0
			players[1]._seat_yaw = -0.9
			camper.debug_throttle = 0.85
		220:
			_shoot("03_driving")
		230:
			camper.debug_throttle = 0.0
			_move_to_roses()
		250:
			_shoot("04_five_roses")
		260:
			get_tree().quit()
	if _frame == 170:
		camper.debug_steer = 0.7


func _move_to_roses() -> void:
	# Physics-body surgery has to happen inside the physics step.
	players[0].force_exit = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	# stand on the far side of the loop and look back at the destination hill
	var idx := 220
	var rp: Vector3 = builder.route.point(idx) + builder.route.right(idx) * 7.0
	rp.y = Landscape.ground(rp.x, rp.z) + 0.3
	players[0].global_position = rp
	var dir := (LevelBuilder.ROSE_CENTRE - rp)
	players[0].yaw = atan2(-dir.x, -dir.z)
	players[0].rotation = Vector3(0, players[0].yaw, 0)
	players[0].pitch = 0.10


func _shoot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_shots"))
	var path := "res://_shots/%s.png" % tag
	img.save_png(path)
	_shot_n += 1
	print("[shot] %s" % path)


func _teleport_to_camper() -> void:
	for i in players.size():
		var p := players[i]
		if p.seat != null:
			continue
		var side := -1.0 if i == 0 else 1.0
		p.global_position = camper.global_transform * Vector3(side * 2.6, 0.4, -1.6)
		p.reset_physics_interpolation()
