class_name PhonePanel
extends Control

## Per-player read-only text thread, drawn as a handset held at the right of
## the view. Story sends messages; this player's phone button (P / D-pad right)
## only raises or lowers it. Sized from the player's own view, so it fits solo,
## side-by-side and stacked split screens alike.

const SENDER_COLORS := {"Naresh's mother": Color(1.0, 0.72, 0.55), "P1": Color(1.0, 0.80, 0.42), "P2": Color(0.55, 0.85, 1.0)}
const SHOWN := 6                      ## newest texts that fit; older ones scroll off the top

var player: PlayerRig
var _phone: PanelContainer
var _thread: VBoxContainer
var _footer: Label
var _badge: Label
var _shown := -1
var _built_w := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# top left under the objective and its hint line: the top right is where
	# the rear-view mirror sits in the driver's view
	_badge = Label.new()
	_badge.position = Vector2(18, 104)
	_badge.add_theme_font_size_override("font_size", 15)
	_badge.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58))
	_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_badge.add_theme_constant_override("outline_size", 4)
	add_child(_badge)

	_phone = PanelContainer.new()
	_phone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := StyleBoxFlat.new()
	body.bg_color = Color(0.05, 0.06, 0.08)
	body.border_color = Color(0.30, 0.32, 0.36)
	body.set_border_width_all(6)
	body.set_corner_radius_all(30)
	body.set_content_margin_all(12)
	body.shadow_color = Color(0, 0, 0, 0.45)
	body.shadow_size = 14
	_phone.add_theme_stylebox_override("panel", body)
	add_child(_phone)

	var screen := PanelContainer.new()
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.93, 0.94, 0.96)
	glass.set_corner_radius_all(20)
	glass.set_content_margin_all(0)
	screen.add_theme_stylebox_override("panel", glass)
	_phone.add_child(screen)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	screen.add_child(column)
	# title bar with the earpiece slot above it
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.20, 0.36, 0.52)
	bar_style.corner_radius_top_left = 20
	bar_style.corner_radius_top_right = 20
	bar_style.content_margin_top = 8
	bar_style.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", bar_style)
	column.add_child(bar)
	var bar_col := VBoxContainer.new()
	bar_col.add_theme_constant_override("separation", 4)
	bar.add_child(bar_col)
	var slot := ColorRect.new()
	slot.color = Color(0.05, 0.06, 0.08)
	slot.custom_minimum_size = Vector2(46, 5)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar_col.add_child(slot)
	var title := Label.new()
	title.text = "Messages"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	bar_col.add_child(title)

	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 10)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pad)
	var clip := Control.new()   # older texts slide up out of view
	clip.clip_contents = true
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(clip)
	_thread = VBoxContainer.new()
	_thread.add_theme_constant_override("separation", 8)
	_thread.alignment = BoxContainer.ALIGNMENT_END
	_thread.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thread.grow_vertical = Control.GROW_DIRECTION_BEGIN   # overflow goes off the top
	clip.add_child(_thread)

	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 13)
	_footer.add_theme_color_override("font_color", Color(0.40, 0.43, 0.48))
	var foot_pad := MarginContainer.new()
	foot_pad.add_theme_constant_override("margin_bottom", 8)
	foot_pad.add_child(_footer)
	column.add_child(foot_pad)
	_phone.visible = false


## One text: sender in its colour over a rounded bubble.
func _bubble(sender: String, text: String, width: float) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var who := Label.new()
	who.text = sender
	who.add_theme_font_size_override("font_size", 12)
	var tint: Color = SENDER_COLORS.get(sender, Color(0.75, 0.80, 0.85))
	who.add_theme_color_override("font_color", tint.darkened(0.45))
	box.add_child(who)
	var bubble := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = tint.lerp(Color.WHITE, 0.55)
	st.set_corner_radius_all(12)
	st.corner_radius_top_left = 3
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 6
	st.content_margin_bottom = 7
	bubble.add_theme_stylebox_override("panel", st)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = width
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.10, 0.11, 0.13))
	bubble.add_child(body)
	box.add_child(bubble)
	return box


func _process(_delta: float) -> void:
	if player == null:
		return
	var story := get_tree().get_first_node_in_group("story") as Story
	if story == null:
		return
	var who := player.index
	var unread := story.phone_unread(who)
	var glyph := player.dev.glyph("phone") if player.dev else "P"
	_badge.text = "[%s]  Phone%s" % [glyph, "  -  %d new" % unread if unread > 0 else ""]
	_badge.visible = not player.phone_open and not story.phone_threads[who].is_empty()
	_phone.visible = player.phone_open
	if not player.phone_open:
		return
	story.mark_phone_read(who)  # texts that arrive while reading count as read
	# a handset about three quarters of the view's height, at the right
	var h := clampf(size.y * 0.78, 300.0, 640.0)
	var w := h * 0.56
	_phone.size = Vector2(w, h)
	_phone.position = Vector2(size.x - w - maxf(24.0, size.x * 0.06), (size.y - h) * 0.55)
	_footer.text = "[%s] put away" % glyph
	var msgs: Array = story.phone_threads[who]
	if msgs.size() != _shown or absf(w - _built_w) > 1.0:
		_shown = msgs.size()
		_built_w = w
		for c in _thread.get_children():
			c.queue_free()
		for m in msgs.slice(maxi(0, msgs.size() - SHOWN)):
			_thread.add_child(_bubble(m["from"], m["body"], w - 64.0))
