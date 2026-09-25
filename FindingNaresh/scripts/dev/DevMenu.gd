class_name DevMenu
extends Control

## Developer menu (F1): set up any moment of the game in seconds. Teleport to
## any named place, bring the van, top it up, spawn props, skip an objective,
## switch between the game world and the gyms. Up/Down pick, Left/Right change
## the value, Enter does it, F1 or ESC closes. The game keeps running under it.

var boot: Node
var open := false
var _sel := 0
var _place := 0
var _gym := 0
var _panel: PanelContainer
var _text: RichTextLabel
var _note := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.position = Vector2(24, 130)
	_panel.custom_minimum_size = Vector2(470, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.09, 0.9)
	sb.border_color = Color(0.95, 0.8, 0.3)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", sb)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(440, 0)
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 17)
	_panel.add_child(_text)
	_panel.visible = false
	add_child(_panel)


func places() -> Array:
	var keys: Array = boot.builder.poi.keys()
	keys.sort()
	return keys


func items() -> Array:
	var pl: Array = places()
	var pname: String = pl[_place % pl.size()] if pl.size() > 0 else "-"
	var gyms: Array = ["(game world)"] + GymBuilder.GYMS
	var out := [
		["Teleport both players to:  < %s >" % pname, "teleport"],
		["Bring the van here", "van_here"],
		["Van: full tank, cool engine, fix leak, battery", "van_fix"],
		["Spawn a full fuel can", "spawn_can"],
		["Spawn a crate", "spawn_crate"],
		["Skip to the next objective", "skip"],
		["Mood:  < %.1f >  (1 bright, 0 dark)" % _mood_value(), "mood"],
		["Spawn a creature 25 m in front", "spawn_creature"],
		["Spawn a cardboard box", "spawn_box"],
		["Give both players binoculars", "binoculars"],
		["Load:  < %s >" % gyms[_gym % gyms.size()], "load"],
		["Close (F1)", "close"],
	]
	return out


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_F1:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	var list := items()
	match k:
		KEY_UP:
			_sel = wrapi(_sel - 1, 0, list.size())
		KEY_DOWN:
			_sel = wrapi(_sel + 1, 0, list.size())
		KEY_LEFT, KEY_RIGHT:
			var d := 1 if k == KEY_RIGHT else -1
			if list[_sel][1] == "teleport":
				_place = wrapi(_place + d, 0, maxi(1, places().size()))
			elif list[_sel][1] == "load":
				_gym = wrapi(_gym + d, 0, GymBuilder.GYMS.size() + 1)
			elif list[_sel][1] == "mood":
				var mood := get_tree().get_first_node_in_group("mood") as Mood
				if mood != null:
					mood.set_now(snappedf(mood.value + 0.1 * d, 0.1))
		KEY_ENTER, KEY_KP_ENTER:
			run(list[_sel][1])
		KEY_ESCAPE:
			toggle()
		_:
			return
	get_viewport().set_input_as_handled()
	_refresh()


func toggle() -> void:
	open = not open
	_panel.visible = open
	_note = ""
	_refresh()


func _refresh() -> void:
	if not open:
		return
	var s := "[b][color=#f2cc4d]DEVELOPER MENU[/color][/b]   %s\n" % ("gym: " + boot.gym if boot.gym != "" else "game world")
	var list := items()
	for i in list.size():
		s += ("[color=#ffe680]> %s[/color]\n" if i == _sel else "  %s\n") % list[i][0]
	s += "[color=#99a0a8]Up/Down pick - Left/Right change - Enter do it[/color]"
	if _note != "":
		s += "\n[color=#8fe39a]%s[/color]" % _note
	_text.text = s


func run(action: String) -> void:
	var p1: PlayerRig = boot.players[0]
	var c: Camper = boot.camper
	match action:
		"teleport":
			var pl := places()
			if pl.is_empty():
				return
			var key: String = pl[_place % pl.size()]
			teleport(boot.builder.poi[key])
			_note = "Teleported to " + key
		"van_here":
			van_to(p1.global_position - p1.global_transform.basis.z * 8.0, p1.yaw)
			_note = "The van is in front of P1, handbrake on"
		"van_fix":
			c.fuel = Camper.FUEL_CAPACITY
			c.temp = Camper.TEMP_NORMAL
			c.coolant = 1.0
			c.coolant_leak = false
			c.heat_lockout = false
			c.battery = 1.0
			_note = "Van topped up and fixed"
		"spawn_can":
			var can := FuelCan.create(FuelCan.CAPACITY)
			boot.world.add_child(can)
			can.global_position = _in_front(p1, 2.0)
			_note = "A full can at P1's feet"
		"spawn_crate":
			var cr := Crate.new()
			boot.world.add_child(cr)
			cr.global_position = _in_front(p1, 2.5)
			_note = "A crate in front of P1"
		"skip":
			var st: Story = boot.story
			st.index = mini(st.index + 1, st.objectives.size() - 1)
			st.objective_changed.emit()
			_note = "Objective: " + st.objective_text()
		"mood":
			_note = "Left/Right changes the mood"
		"spawn_creature":
			var cr := Creature.new()
			boot.world.add_child(cr)
			cr.global_position = _in_front(p1, 25.0)
			cr.rotation.y = p1.yaw
			_note = "A creature 25 m in front of P1, facing them"
		"spawn_box":
			var bx := CardboardBox.new()
			boot.world.add_child(bx)
			bx.global_position = _in_front(p1, 2.0)
			_note = "A cardboard box at P1's feet (E with it in hand to get under it)"
		"binoculars":
			for p in boot.players:
				p.has_binoculars = true
			_note = "Both have binoculars (hold RMB / LT)"
		"load":
			var gyms: Array = ["(game world)"] + GymBuilder.GYMS
			var pick: String = gyms[_gym % gyms.size()]
			Boot.gym_request = "" if pick == "(game world)" else pick
			boot.get_tree().paused = false
			boot.get_tree().reload_current_scene()
		"close":
			toggle()


func _mood_value() -> float:
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	return mood.value if mood != null else 1.0


func _in_front(p: PlayerRig, dist: float) -> Vector3:
	var at := p.global_position - p.global_transform.basis.z * dist
	return Vector3(at.x, Landscape.ground(at.x, at.z) + 0.4, at.z)


## Both players to a spot (P2 beside P1), out of the van if seated.
func teleport(at: Vector3) -> void:
	for i in boot.players.size():
		var p: PlayerRig = boot.players[i]
		if p.seat != null:
			p.exit_vehicle()
		var spot := at + Vector3(2.0 * i, 0, 3.0)
		spot.y = Landscape.ground(spot.x, spot.z) + 0.3
		p.global_position = spot
		p.velocity = Vector3.ZERO
		p._plan_vel = Vector2.ZERO
		p.reset_physics_interpolation()


func van_to(at: Vector3, yaw: float) -> void:
	var c: Camper = boot.camper
	for p in boot.players:
		if p.seat != null:
			p.exit_vehicle()
	c.freeze = false
	c.linear_velocity = Vector3.ZERO
	c.angular_velocity = Vector3.ZERO
	c.parking_brake = true
	c.global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, Landscape.ground(at.x, at.z) + 0.9, at.z))
	c.reset_physics_interpolation()
