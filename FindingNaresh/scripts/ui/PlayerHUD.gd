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
	_gauges.offset_top = -104
	_gauges.offset_bottom = -18
	_gauges.add_theme_constant_override("separation", 3)
	_gauges.visible = false
	add_child(_gauges)

	_speed = _label(30, Color(1, 1, 1, 0.95))
	_gauges.add_child(_speed)
	_gauges.add_child(_bar("FUEL", Color(0.95, 0.78, 0.30)))
	_gauges.add_child(_bar("TEMP", TEMP_OK))

	_hint = _label(15, Color(1, 1, 1, 0.80))
	# Top centre: the bottom corners belong to the gauges, and in a split
	# view there is no room for a full-width line down there.
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.offset_left = -380
	_hint.offset_right = 380
	_hint.offset_top = 64
	_hint.offset_bottom = 88
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	_warn = _label(20, Color(1.0, 0.45, 0.35))
	_warn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_warn.offset_left = -300
	_warn.offset_right = 300
	_warn.offset_top = 96
	_warn.offset_bottom = 126
	_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_warn)

	p.prompt_changed.connect(_on_prompt)


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


func _process(delta: float) -> void:
	if player == null:
		return
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
		(_bars["TEMP"] as ColorRect).color = TEMP_HOT if camper.temp > Camper.TEMP_WARN else TEMP_OK
		var w := ""
		if camper.temp > Camper.TEMP_WARN:
			w = "ENGINE HOT - ease off or stop"
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
				"foot": text = "Stick move · Right stick look · L3 sprint · A jump · Y flashlight · X use · RB throw"
				"driver": text = "RT go · LT brake/reverse · Stick steer · B handbrake · D-Up engine · D-Left lights"
				_: text = "Right stick look around · D-Left lights · LB swap seats when stopped"
		else:
			match ctx:
				"foot": text = "WASD move · Mouse look · Shift sprint · Space jump · F flashlight · E use · LMB throw"
				"driver": text = "W go · S brake/reverse · A/D steer · Space handbrake · X engine · L lights"
				_: text = "Mouse look around · L lights · C swap seats when stopped"
	_hint.text = text


func _set_bar(tag: String, v: float) -> void:
	var fill: ColorRect = _bars.get(tag)
	if fill:
		fill.anchor_right = clampf(v, 0.0, 1.0)
		fill.offset_right = 0
