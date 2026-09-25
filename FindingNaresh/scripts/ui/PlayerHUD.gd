class_name PlayerHUD
extends Control

## Minimal per-player HUD. One instance lives inside each player's SubViewport,
## so nothing is shared between the two halves of the screen.

var player: PlayerRig
var camper: Camper

var _crosshair: Control
var _prompt: Label
var _who: Label
var _role: Label
var _gauges: VBoxContainer
var _speed: Label
var _fuel: Label
var _temp: Label
var _bars: Dictionary = {}
var _hint: Label
var _warn: Label
var _note: PanelContainer
var _note_text: Label
var _note_time := 0.0
var map_view: PaperMap
var _objective: Label
var _objective_hint: Label
## Seconds spent in each context; control hints fade once you have had time
## to learn them, and come back if you have been away for a while.
var _hint_age := {"foot": 0.0, "driver": 0.0, "passenger": 0.0}
const HINT_SECONDS := 14.0
const TEMP_OK := Color(0.45, 0.78, 0.95)
const TEMP_HOT := Color(0.95, 0.35, 0.28)


func setup(p: PlayerRig, van: Camper, title: String, tint: Color) -> void:
	player = p
	camper = van
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_crosshair = Control.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.75)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -2)
	_crosshair.add_child(dot)

	_prompt = _label(22, Color(1, 1, 1, 0.95))
	# Just under the crosshair, where you are already looking. At the bottom
	# of the screen it sat on top of the driver's gauges.
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -360
	_prompt.offset_right = 360
	_prompt.offset_top = 40
	_prompt.offset_bottom = 72
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt)

	_who = _label(18, tint)
	_who.text = title
	_who.position = Vector2(18, 12)
	add_child(_who)

	_role = _label(15, Color(1, 1, 1, 0.72))
	_role.position = Vector2(18, 34)
	add_child(_role)

	_gauges = VBoxContainer.new()
	_gauges.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_gauges.offset_left = 18
	_gauges.offset_top = -126
	_gauges.offset_bottom = -18
	_gauges.add_theme_constant_override("separation", 3)
	_gauges.visible = false
	add_child(_gauges)

	_speed = _label(30, Color(1, 1, 1, 0.95))
	_gauges.add_child(_speed)
	_gauges.add_child(_bar("FUEL", Color(0.95, 0.78, 0.30)))
	_gauges.add_child(_bar("TEMP", TEMP_OK))
	_gauges.add_child(_bar("COOL", Color(0.35, 0.75, 0.90)))

	_hint = _label(15, Color(1, 1, 1, 0.80))
	# Bottom right leaves the objective at top left and the gauges at bottom
	# left readable in each 800 px split view.
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -570
	_hint.offset_right = -18
	_hint.offset_top = -108
	_hint.offset_bottom = -20
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_hint)

	_warn = _label(20, Color(1.0, 0.45, 0.35))
	_warn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_warn.offset_left = -300
	_warn.offset_right = 300
	_warn.offset_top = 96
	_warn.offset_bottom = 126
	_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_warn)

	# current objective, shared by both players; hold the hint key for more
	_objective = _label(16, Color(1.0, 0.93, 0.70))
	_objective.position = Vector2(18, 58)
	add_child(_objective)
	_objective_hint = _label(14, Color(1, 1, 1, 0.85))
	_objective_hint.position = Vector2(18, 80)
	_objective_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_hint.custom_minimum_size = Vector2(420, 0)
	add_child(_objective_hint)

	# notes: boards, letters, story lines
	_note = PanelContainer.new()
	_note.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_note.offset_left = -330
	_note.offset_right = 330
	_note.offset_top = 130
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.94, 0.89, 0.76, 0.96)
	sb.border_color = Color(0.55, 0.45, 0.32)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	_note.add_theme_stylebox_override("panel", sb)
	_note_text = Label.new()
	_note_text.add_theme_font_size_override("font_size", 17)
	_note_text.add_theme_color_override("font_color", Color(0.22, 0.18, 0.14))
	_note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_text.custom_minimum_size = Vector2(620, 0)
	_note.add_child(_note_text)
	_note.visible = false
	add_child(_note)

	# the paper map, raised with M
	map_view = PaperMap.new()
	var ms := get_tree().get_first_node_in_group("map_state") as MapState
	if ms != null:
		map_view.bind(ms)
	add_child(map_view)
	p.paper_map = map_view

	var journal := JournalPanel.new()
	journal.player = p
	add_child(journal)
	var phone := PhonePanel.new()
	phone.player = p
	add_child(phone)

	p.prompt_changed.connect(_on_prompt)
	p.message.connect(show_note)


func _bar(tag: String, col: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := _label(13, Color(1, 1, 1, 0.7))
	l.text = tag
	l.custom_minimum_size = Vector2(44, 0)
	row.add_child(l)
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.45)
	back.custom_minimum_size = Vector2(140, 12)
	row.add_child(back)
	var fill := ColorRect.new()
	fill.color = col
	fill.size = Vector2(140, 12)
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	back.add_child(fill)
	_bars[tag] = fill
	return row


func _label(sz: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _on_prompt(text: String) -> void:
	_prompt.text = text


func show_note(text: String, seconds: float) -> void:
	_note_text.text = text
	_note.visible = true
	_note_time = seconds


## Hides the note if one is showing; true if it did.
func dismiss_note() -> bool:
	if not _note.visible:
		return false
	_note.visible = false
	_note_time = 0.0
	return true


func _process(delta: float) -> void:
	if player == null:
		return
	if _note_time > 0.0:
		_note_time -= delta
		if _note_time <= 0.0:
			_note.visible = false
	if player.journal_open:
		_note.visible = false      # the journal has the reader's attention
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null:
		var d := player.dev
		_objective.text = "> " + st.objective_text(player.index)
		if d != null and d.held("hint"):
			_objective_hint.text = st.hint_text(player.index)
		else:
			_objective_hint.text = "(hold %s for a hint)" % (d.glyph("hint") if d else "H")
	var seated := player.seat != null
	_update_hint(delta, seated)
	_gauges.visible = seated
	if seated:
		_role.text = "%s  ·  %s" % [
			"DRIVER" if player.seat_role == "driver" else "NAVIGATOR",
			("engine on" if camper.engine_on else "engine off")]
		var kmh := camper.linear_velocity.length() * 3.6
		# a parked van settling on its springs should read 0, not 1-2
		_speed.text = "%3.0f km/h" % (kmh if kmh >= 1.5 else 0.0)
		_set_bar("FUEL", camper.fuel / Camper.FUEL_CAPACITY)
		_set_bar("TEMP", (camper.temp - Camper.TEMP_AMBIENT) / (Camper.TEMP_MAX - Camper.TEMP_AMBIENT))
		_set_bar("COOL", camper.coolant)
		(_bars["TEMP"] as ColorRect).color = TEMP_HOT if camper.temp > Camper.TEMP_WARN else TEMP_OK
		var w := ""
		if camper.start_fail_t > 0.0:
			w = camper.start_fail
		elif camper.coolant_leak:
			w = "STEAM! The coolant hose has split - %d C" % int(camper.temp)
		elif camper.temp > Camper.TEMP_WARN:
			w = "ENGINE HOT - ease off or stop"
		elif camper.tyre_flat:
			w = "PUNCTURE - steer pulls left; fit the spare"
		elif camper.fuel / Camper.FUEL_CAPACITY < 0.18:
			w = "FUEL LOW"
		_warn.text = w
	else:
		_warn.text = ""
		_role.text = "on foot" + ("  ·  sprinting" if player.dev and player.dev.held("sprint") else "")


func _update_hint(delta: float, seated: bool) -> void:
	var ctx := "foot"
	if seated:
		ctx = player.seat_role
	_hint_age[ctx] = _hint_age[ctx] + delta
	var d := player.dev
	var text := ""
	if _hint_age[ctx] < HINT_SECONDS and d != null:
		if d.kind == InputDevice.Kind.PAD:
			match ctx:
				"foot": text = "Stick move · Right stick look · L3 sprint · A jump · Y flashlight · X use · RB throw · D-Down map"
				"driver": text = "RT go · LT brake/reverse · Stick steer · B handbrake · D-Up engine · D-Left lights · A swing the nav"
				_: text = "Right stick look around · A swing the nav to you · D-Left lights · LB swap seats when stopped"
		else:
			match ctx:
				"foot": text = "WASD move · Mouse look · Shift sprint · Space jump · F flashlight · E use · LMB throw · M map"
				"driver": text = "W go · S brake/reverse · A/D steer · Space handbrake · X engine · L lights · N swing the nav"
				_: text = "Mouse look around · N swing the nav to you · L lights · C swap seats when stopped"
	_hint.text = text


func _set_bar(tag: String, v: float) -> void:
	var fill: ColorRect = _bars.get(tag)
	if fill:
		fill.anchor_right = clampf(v, 0.0, 1.0)
		fill.offset_right = 0
