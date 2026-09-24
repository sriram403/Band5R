class_name JournalPanel
extends PanelContainer

## The van's travel journal, as seen by one player. Writing in it saves the
## journey to one of three slots and costs a Memory Rose; the cost and the
## player's roses are shown before anything is spent.

var player: PlayerRig
var _text: RichTextLabel
## Slot lines, read from disk when the journal opens (reading all three save
## files every frame while it was open meant ~400 file reads a second).
var _summaries: Array[String] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -340
	offset_right = 340
	offset_top = -210
	offset_bottom = 210
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.88, 0.74, 0.98)
	sb.border_color = Color(0.45, 0.30, 0.22)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(22)
	add_theme_stylebox_override("panel", sb)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.add_theme_color_override("default_color", Color(0.22, 0.17, 0.13))
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 19)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	visible = false


func _process(_delta: float) -> void:
	if player == null:
		return
	var opening := player.journal_open and not visible
	visible = player.journal_open
	if not visible:
		return
	if opening or _summaries.size() != SaveGame.SLOTS:
		_summaries.clear()
		for i in SaveGame.SLOTS:
			_summaries.append(SaveGame.summary(i))
	var st := get_tree().get_first_node_in_group("story") as Story
	var roses := st.roses() if st else 0
	var petals := st.petals() if st else 0
	var d := player.dev
	var lines := "[center][b]TRAVEL JOURNAL[/b][/center]\n"
	lines += "Memory Roses: [b]%d[/b]      next rose: %d / 3 fragments\n" % [roses, petals]
	lines += "[i]Writing here saves the journey. Each entry uses one Memory Rose. Nothing is ever saved for you.[/i]\n\n"
	for i in SaveGame.SLOTS:
		var mark := "[color=#8a2a1a]>[/color] " if i == player.journal_sel else "   "
		lines += mark + _summaries[i] + "\n"
	lines += "\n"
	if player.journal_note != "":
		lines += "[color=#8a2a1a]%s[/color]\n" % player.journal_note
	elif roses < 1:
		lines += "[color=#8a2a1a]You have no Memory Rose. Three fragments make one.[/color]\n"
	elif player.journal_confirm:
		lines += "[b]Write in slot %d? This uses 1 of your %d Memory Roses.[/b]  [%s] yes\n" % [player.journal_sel + 1, roses, d.glyph("menu_ok") if d else "Enter"]
	lines += "[%s/%s] choose   [%s] write   [%s] close" % [
		"W" if d and d.kind == InputDevice.Kind.KBM else "D-Up", "S" if d and d.kind == InputDevice.Kind.KBM else "D-Down",
		d.glyph("menu_ok") if d else "Enter", d.glyph("journal") if d else "J"]
	_text.text = lines
