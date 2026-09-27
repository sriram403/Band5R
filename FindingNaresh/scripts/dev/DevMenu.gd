class_name DevMenu
extends Control

## Developer menu (F1): set up any moment of the game in seconds. A window
## with tabs: Travel (teleport both players to a named place, along the
## journey), Story (skip, or jump to any objective), Van, Spawn, World (the
## mood) and Gyms. The game pauses while it is open.
##
## Keys: Left / Right change tab, Up / Down pick, Page Up / Down jump, a
## letter jumps to the next place starting with it, Enter does it, F1 or Esc
## closes. The mouse works too: click a tab, click an item, double-click (or
## the button) to do it.
##
## Teleports never drop you into a building: `safe_spot` looks outwards from
## the place for somewhere a player can stand (a floor, a deck or the ground,
## with room above it) and turns you to face the place.

const TABS := ["Travel", "Story", "Van", "Spawn", "World", "Gyms"]

## The journey, in order: [section, [[poi key, name, what's there], ...]].
## Places missing from the world (a gym) are left out; every other named
## point is listed at the end under "All named points".
const PLACES := [
	["The opening", [
		["homestead", "Homestead", "Home: the van, the garage can, the letter on the porch."],
		["letter", "The porch letter", "Mum and Dad's note."],
		["town_fuel", "Town Fuel", "The working pump in town."],
		["roadworks_nails", "Roadworks", "Where the opening's puncture happens."],
		["p2_home", "P2's house", "P2's home and drive, on the lane north of town."],
		["house_kitchen", "P2's kitchen", "The drawer with the torch batteries."],
		["p2_window", "P2's upstairs window", "Where P2 watches for the van."],
	]],
	["The way out", [
		["j1", "Windmill junction (J1)", "The road choice: Valley Road or Ridge Track."],
		["windmill", "The windmill", "W1: the brake puzzle. Ladder at the back, lever out front."],
		["windmill_platform", "Windmill platform", "Up top, under the blades."],
		["dock", "Mirror Lake dock", "Valley Road: a Memory Fragment, Naresh's bench."],
		["billboard", "The billboard", "Valley Road: 'Bessi and the 5 Roses'."],
		["barn", "The barn", "Valley Road: W2, the hay maze on its west side."],
		["loft", "Barn loft balcony", "Above the maze: where the guide stands."],
		["maze", "Hay maze (the middle)", "Inside the hedges."],
		["lookout", "Pine Ridge lookout", "Ridge Track: binoculars on the deck; W4, the code boards."],
		["lookout_deck", "Pine Ridge lookout deck", "Up top, with the binoculars."],
		["relay_box", "Lookout supply box", "The picture dials at the ramp's foot."],
		["wreck", "The wreck", "Ridge Track: the car on its roof."],
		["j2", "Last Fuel (J2)", "The dead pumps and the cans; the note on the kiosk door."],
		["facility", "Water works", "The valves, the pump and the blue tank."],
		["turbine", "The turbine", "It starts when the blue tank fills."],
		["bridge_hut", "Bridge control hut", "W6: the RAISE / LOWER levers and the safety mirror."],
		["machinery_in", "Bridge machinery house", "The gear, the wedge and the counterweight."],
		["bridge_far", "Far side of the bridge", "Over the river, towards J3."],
		["j3", "Foot of the ghat (J3)", "Where the hairpins start."],
		["hairpin_1", "First hairpin", "Fog; the pace notes."],
		["hairpin_2", "Second hairpin", "The glimpse between the trees."],
		["ghat_pass", "The pass", "The first creature comes for the van here."],
		["coast_tower", "Coast watchtower", "Hiding on foot; stamp the beach from the top."],
		["coast_tower_deck", "Coast watchtower deck", "The first sight of the sea."],
	]],
	["Bessi and the coast", [
		["beach", "Bessi beach", "Milestone E."],
		["roses", "The Five Roses", "The plaza on the dune."],
		["memorial", "The memorial", "On the sand, its spire in line with the lighthouse."],
		["promenade_north", "The promenade", "The stalls, lit and empty; a radio in one of them."],
		["radio_stall", "The radio stall", "The one playing softly."],
		["photo_spot", "The photo spot (E3)", "Where Naresh's photo was taken: the lamp just over the spire."],
		["fishing_village", "Fishing village", "The coast road north."],
		["net_shed", "The net shed", "In the fishing village."],
		["salt_pans", "Salt pans", "The coast road."],
		["estuary_bridge", "Estuary bridge", "The coast road."],
	]],
	["The way back", [
		["tunnel", "Rail tunnel", "Under Tunnel Hill."],
		["radio_mast", "Radio mast", "The return."],
		["naresh_home", "Naresh's home", "His mother and sister."],
		["end_tower", "The old watchtower", "Tower Road, near the end."],
		["end_tower_deck", "Old watchtower deck", "The view of every puzzle site."],
	]],
]

const MOODS := [
	[1.0, "1.0  bright (the start)"], [0.85, "0.85  Last Fuel"], [0.7, "0.7  the pass"],
	[0.6, "0.6  the coast"], [0.4, "0.4  dusk"], [0.2, "0.2  night"],
]

var boot: Node
var open := false
var tab := 0
var _sel := {}                   ## tab -> selected row
var _rows: Array = []            ## this tab's rows: {text, action, arg, detail, header}
var _note := ""
var _was_paused := false
var _mouse_was := Input.MOUSE_MODE_VISIBLE
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _context: Label
var _tabs: Array[Button] = []
var _list: ItemList
var _detail: RichTextLabel
var _go: Button
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


# --- building the window ---------------------------------------------------------

func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1000, 620)
	_panel.add_theme_stylebox_override("panel", _box(Color(0.07, 0.08, 0.10, 0.97), Color(0.95, 0.78, 0.30), 2, 18))
	centre.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	# title row
	var head := HBoxContainer.new()
	v.add_child(head)
	_title = _label("DEVELOPER MENU", 22, Color(0.98, 0.82, 0.35))
	head.add_child(_title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(_label("F1 / Esc to close  ·  the game is paused", 14, Color(0.6, 0.64, 0.7)))
	_context = _label("", 15, Color(0.78, 0.82, 0.88))
	_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_context)
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for i in TABS.size():
		var b := Button.new()
		b.text = "  %s  " % TABS[i]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_stylebox_override("normal", _box(Color(0.13, 0.15, 0.18), Color(0.25, 0.28, 0.32), 1, 8))
		b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.2, 0.24), Color(0.5, 0.5, 0.5), 1, 8))
		b.add_theme_stylebox_override("pressed", _box(Color(0.95, 0.78, 0.30), Color(0.95, 0.78, 0.30), 1, 8))
		b.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.1))
		b.add_theme_color_override("font_hover_pressed_color", Color(0.08, 0.08, 0.1))
		b.pressed.connect(func(): set_tab(i))
		tabs.add_child(b)
		_tabs.append(b)
	# the list and the details side by side
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	v.add_child(body)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(560, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_NONE
	_list.add_theme_font_size_override("font_size", 16)
	_list.add_theme_stylebox_override("panel", _box(Color(0.05, 0.06, 0.07), Color(0.2, 0.22, 0.25), 1, 8))
	_list.add_theme_stylebox_override("selected", _box(Color(0.30, 0.25, 0.10), Color(0.95, 0.78, 0.30), 1, 4))
	_list.add_theme_stylebox_override("selected_focus", _box(Color(0.30, 0.25, 0.10), Color(0.95, 0.78, 0.30), 1, 4))
	_list.item_selected.connect(func(i: int): _select(i, false))
	_list.item_activated.connect(func(i: int): _select(i, false); activate())
	body.add_child(_list)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)
	var dpanel := PanelContainer.new()
	dpanel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dpanel.add_theme_stylebox_override("panel", _box(Color(0.10, 0.11, 0.13), Color(0.2, 0.22, 0.25), 1, 12))
	side.add_child(dpanel)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.scroll_active = true
	_detail.add_theme_font_size_override("normal_font_size", 15)
	_detail.add_theme_font_size_override("bold_font_size", 17)
	dpanel.add_child(_detail)
	_go = Button.new()
	_go.text = "Do it  (Enter)"
	_go.focus_mode = Control.FOCUS_NONE
	_go.add_theme_font_size_override("font_size", 17)
	_go.custom_minimum_size = Vector2(0, 44)
	_go.add_theme_stylebox_override("normal", _box(Color(0.95, 0.78, 0.30), Color(0.95, 0.78, 0.30), 1, 8))
	_go.add_theme_stylebox_override("hover", _box(Color(1.0, 0.86, 0.45), Color(1.0, 0.86, 0.45), 1, 8))
	_go.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
	_go.add_theme_color_override("font_hover_color", Color(0.08, 0.08, 0.1))
	_go.pressed.connect(activate)
	side.add_child(_go)
	_status = _label("", 15, Color(0.56, 0.89, 0.6))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_status)
	v.add_child(_label("Left / Right: tab   ·   Up / Down: pick   ·   a letter: jump to it   ·   Enter or double-click: do it", 14, Color(0.6, 0.64, 0.7)))


func _box(bg: Color, border: Color, width: int, margin: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(margin)
	return sb


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


# --- opening, closing, keys -------------------------------------------------------

func toggle() -> void:
	open = not open
	visible = open
	_note = ""
	var tree := get_tree()
	if open:
		_was_paused = tree.paused
		tree.paused = true
		_mouse_was = Input.mouse_mode
		if not boot.testing:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh()
	else:
		tree.paused = _was_paused or boot.paused
		if not boot.testing:
			Input.mouse_mode = _mouse_was


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F1:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	if event is InputEventMouse:
		return            # the window's controls take the mouse; nothing reaches the game (paused)
	get_viewport().set_input_as_handled()      # no key or pad press reaches the game while open
	if not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).keycode
	match k:
		KEY_LEFT:
			set_tab(wrapi(tab - 1, 0, TABS.size()))
		KEY_RIGHT:
			set_tab(wrapi(tab + 1, 0, TABS.size()))
		KEY_UP:
			_move(-1)
		KEY_DOWN:
			_move(1)
		KEY_PAGEUP:
			_move(-10)
		KEY_PAGEDOWN:
			_move(10)
		KEY_HOME:
			_select(_first_selectable(0, 1), true)
		KEY_ENTER, KEY_KP_ENTER:
			activate()
		KEY_ESCAPE:
			toggle()
		_:
			if k >= KEY_A and k <= KEY_Z and not event.echo:
				_jump_letter(char(k).to_lower())


var _ctx_t := 0.0


func _process(delta: float) -> void:
	if not open:
		return
	_ctx_t -= delta
	if _ctx_t <= 0.0:
		_ctx_t = 0.5
		_update_context()


func set_tab(i: int) -> void:
	tab = i
	_note = ""
	_refresh()


# --- rows for each tab -----------------------------------------------------------

func _row(text: String, action: String, arg = null, detail := "") -> Dictionary:
	return {"text": text, "action": action, "arg": arg, "detail": detail, "header": false}


func _header(text: String) -> Dictionary:
	return {"text": text, "action": "", "arg": null, "detail": "", "header": true}


## Every place the Travel tab offers, in order (tests teleport to each).
func travel_keys() -> Array:
	var out: Array = []
	for r in _travel_rows():
		if not r["header"]:
			out.append(r["arg"])
	return out


func _travel_rows() -> Array:
	var poi: Dictionary = boot.builder.poi
	var rows: Array = []
	var listed := {}
	for sec in PLACES:
		var entries: Array = []
		for e in sec[1]:
			if poi.has(e[0]):
				entries.append(_row(e[1], "teleport", e[0], "[b]%s[/b]\n\n%s\n\n[color=#8a9099]point: %s[/color]" % [e[1], e[2], e[0]]))
				listed[e[0]] = true
		if not entries.is_empty():
			rows.append(_header(sec[0]))
			rows.append_array(entries)
	var rest: Array = []
	for key in poi.keys():
		if not listed.has(key) and poi[key] is Vector3:
			rest.append(key)
	rest.sort()
	if not rest.is_empty():
		rows.append(_header("All named points"))
		for key in rest:
			rows.append(_row(String(key).replace("_", " "), "teleport", key, "[b]%s[/b]\n\nA named point used by the game and its tests.\n\n[color=#8a9099]point: %s[/color]" % [key, key]))
	return rows


func _rows_for(t: int) -> Array:
	match TABS[t]:
		"Travel":
			return _travel_rows()
		"Story":
			var st: Story = boot.story
			var rows: Array = [_header("Quick")]
			rows.append(_row("Skip: %s" % ("end the opening" if st.opening_mode else "the next objective"), "skip", null,
				"[b]Skip[/b]\n\nDuring the two-player opening this skips the rest of it (as if you'd met at P2's house). After it, it moves on one objective."))
			rows.append(_header("Jump to an objective"))
			for i in st.objectives.size():
				var o: Dictionary = st.objectives[i]
				var now := i == st.index and not st.opening_mode
				rows.append(_row("%s%2d. %s" % ["> " if now else "   ", i + 1, o["text"]], "jump", i,
					"[b]%s[/b]\n\n%s\n\n[color=#8a9099]id: %s%s[/color]" % [o["text"], o.get("hint", ""), o["id"], "  (now)" if now else ""]))
			return rows
		"Van":
			var c: Camper = boot.camper
			return [
				_row("Bring the van here (fixed)", "van_here", null, "[b]Bring the van[/b]\n\nParks it on clear ground just in front of P1, handbrake on, and fixes everything (as below)."),
				_row("Fix the van: everything", "van_fix", null, "[b]Fix everything[/b]\n\nFull tank, normal temperature, coolant, no leaks, a charged battery, the flat tyre, whatever a creature did, the tarp off, and back on its wheels."),
				_row("Both in: P1 drives, P2 alongside", "van_seat", null, "[b]Both in[/b]\n\nPuts P1 in the driver's seat and P2 in the passenger seat."),
				_row("Both out", "van_out", null, "[b]Both out[/b]"),
				_row("Tarp: %s" % ("on (take it off)" if c.attack.tarped else "off (put it on)"), "van_tarp", null, "[b]The tarp[/b]\n\nWhat hides the van from creatures."),
				_row("Headlights: %s" % ("on" if c.headlights_on else "off"), "van_lights", null, "[b]Headlights[/b]"),
				_row("Handbrake: %s" % ("on" if c.parking_brake else "off"), "van_brake", null, "[b]Handbrake[/b]"),
			]
		"Spawn":
			return [
				_row("A full fuel can", "spawn_can", 1.0, "[b]Fuel can, full[/b]\n\nAt P1's feet."),
				_row("An empty fuel can", "spawn_can", 0.0, "[b]Fuel can, empty[/b]\n\nAt P1's feet."),
				_row("A coolant jug", "spawn_jug", null, "[b]Coolant jug[/b]\n\nAt P1's feet."),
				_row("A crate", "spawn_crate", null, "[b]Crate[/b]\n\nIn front of P1."),
				_row("A cardboard box", "spawn_box", null, "[b]Cardboard box[/b]\n\nPick it up (E), then E again to get under it."),
				_row("A creature, 25 m in front", "spawn_creature", null, "[b]Creature[/b]\n\n25 m in front of P1, facing them."),
				_row("Binoculars for both", "binoculars", null, "[b]Binoculars[/b]\n\nHold RMB / LT to look."),
				_row("Naresh, next to P1", "spawn_naresh", null, "[b]Naresh[/b]\n\nNext to P1 (moved there if he's already about), following P1. Hold V / D-Up looking at something to give him a job."),
				_row("Naresh: a random act now", "naresh_act", null, "[b]A random act[/b]\n\nOne of the acts that fits right now, announced 3 s before as usual."),
				_row("Naresh: arm the refuel mistake", "naresh_mistake", null, "[b]The scripted mistake[/b]\n\nThe next time he's told to refuel, he picks up the empty can instead, and says he checked it twice."),
			]
		"World":
			var rows: Array = [_header("Mood (sky, fog, birds, traffic, creatures' light)")]
			for m in MOODS:
				rows.append(_row(m[1], "mood", m[0], "[b]Mood %.2f[/b]\n\n1 is the bright start; the way out falls to 0.6 at the coast; dusk and night come later." % m[0]))
			return rows
		"Gyms":
			var rows: Array = [_row("The game world", "load", "", "[b]The game world[/b]\n\nReloads the world (the session starts over).")]
			rows.append(_header("Test maps"))
			for g in GymBuilder.GYMS:
				rows.append(_row(g, "load", g, "[b]Gym: %s[/b]\n\nA small test map for one mechanic. Reloads the scene." % g))
			return rows
	return []


# --- showing and picking ---------------------------------------------------------

func _refresh() -> void:
	if not open:
		return
	for i in _tabs.size():
		_tabs[i].button_pressed = i == tab
	_rows = _rows_for(tab)
	_list.clear()
	for r in _rows:
		var idx := _list.add_item(("   " + r["text"]) if not r["header"] else String(r["text"]).to_upper())
		if r["header"]:
			_list.set_item_selectable(idx, false)
			_list.set_item_disabled(idx, true)
			_list.set_item_custom_fg_color(idx, Color(0.95, 0.78, 0.30))
	var sel: int = _sel.get(tab, -1)
	if sel < 0 or sel >= _rows.size() or _rows[sel]["header"]:
		sel = _first_selectable(0, 1)
	_select(sel, true)
	_update_context()


func _update_context() -> void:
	var st: Story = boot.story
	var p1: PlayerRig = boot.players[0]
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	_context.text = "%s   ·   P1 near: %s   ·   objective: %s   ·   mood %.2f   ·   %d fps" % [
		"gym: " + boot.gym if boot.gym != "" else "game world", SaveGame.nearest_place(boot, p1.global_position),
		st.objective_text(0), mood.value if mood != null else 1.0, Engine.get_frames_per_second()]
	_status.text = _note


func _select(i: int, scroll: bool) -> void:
	if i < 0 or i >= _rows.size():
		return
	_sel[tab] = i
	_list.select(i)
	if scroll:
		_list.ensure_current_is_visible()
	_detail.text = _rows[i]["detail"]


func _first_selectable(from: int, step: int) -> int:
	var i := from
	while i >= 0 and i < _rows.size():
		if not _rows[i]["header"]:
			return i
		i += step
	return -1


func _move(d: int) -> void:
	var cur: int = _sel.get(tab, 0)
	var step := 1 if d > 0 else -1
	var target := clampi(cur + d, 0, _rows.size() - 1)
	var i := _first_selectable(target, step)
	if i < 0:
		i = _first_selectable(target, -step)
	if i >= 0:
		_select(i, true)


func _jump_letter(c: String) -> void:
	var cur: int = _sel.get(tab, 0)
	for n in range(1, _rows.size() + 1):
		var i := (cur + n) % _rows.size()
		var r: Dictionary = _rows[i]
		if not r["header"] and String(r["text"]).strip_edges().to_lower().begins_with(c):
			_select(i, true)
			return


## Pick the Travel row for a place (tests, and a handy call from elsewhere).
func select_place(key: String) -> bool:
	set_tab(TABS.find("Travel"))
	for i in _rows.size():
		if _rows[i]["action"] == "teleport" and _rows[i]["arg"] == key:
			_select(i, true)
			return true
	return false


## Pick a row in the current tab by its action (tests).
func select_action(action: String) -> bool:
	for i in _rows.size():
		if _rows[i]["action"] == action:
			_select(i, true)
			return true
	return false


func activate() -> void:
	var i: int = _sel.get(tab, -1)
	if i < 0 or i >= _rows.size() or _rows[i]["header"]:
		return
	run(_rows[i]["action"], _rows[i]["arg"])
	_refresh()


# --- doing it -------------------------------------------------------------------

func run(action: String, arg = null) -> void:
	var p1: PlayerRig = boot.players[0]
	var c: Camper = boot.camper
	match action:
		"teleport":
			teleport_to(String(arg))
			_note = "Teleported both players to %s." % _place_name(String(arg))
		"skip":
			boot.story.skip()
			_note = "Objective: " + boot.story.objective_text(0)
		"jump":
			boot.story.jump_to(int(arg))
			var where := go_to_step(String(boot.story.current()["id"]))
			_note = "Objective: " + boot.story.objective_text(0) + ("   (you're at %s)" % where if where != "" else "")
		"van_here":
			var fwd := -p1.global_transform.basis.z
			fwd.y = 0.0
			var at := van_spot(p1.global_position + fwd.normalized() * 8.0)
			van_to(at, p1.yaw)
			c.repair_all()
			_note = "The van is in front of P1, fixed, handbrake on."
		"van_fix":
			c.repair_all()
			_note = "The van is fixed: fuel, heat, coolant, leaks, battery, tyres, creature damage."
		"van_seat":
			var q: PlayerRig = boot.players[1]
			if p1.seat == null:
				p1.enter_seat(c, c.seat_nodes["driver"], "driver")
			if q.seat == null:
				q.enter_seat(c, c.seat_nodes["passenger"], "passenger")
			_note = "Both in the van."
		"van_out":
			for p in boot.players:
				if p.seat != null:
					p.exit_vehicle()
			_note = "Both out of the van."
		"van_tarp":
			c.attack.set_tarp(not c.attack.tarped)
			_note = "Tarp " + ("on." if c.attack.tarped else "off.")
		"van_lights":
			c.set_headlights(not c.headlights_on)
			_note = "Headlights " + ("on." if c.headlights_on else "off.")
		"van_brake":
			c.set_parking_brake(not c.parking_brake)
			_note = "Handbrake " + ("on." if c.parking_brake else "off.")
		"spawn_can":
			var can := FuelCan.create(FuelCan.CAPACITY * float(arg))
			boot.world.add_child(can)
			can.global_position = _in_front(p1, 2.0)
			_note = "A %s can at P1's feet." % ("full" if float(arg) > 0.5 else "empty")
		"spawn_jug":
			var jug := CoolantJug.new()
			boot.world.add_child(jug)
			jug.global_position = _in_front(p1, 2.0)
			_note = "A coolant jug at P1's feet."
		"spawn_crate":
			var cr := Crate.new()
			boot.world.add_child(cr)
			cr.global_position = _in_front(p1, 2.5)
			_note = "A crate in front of P1."
		"spawn_creature":
			var cr := Creature.new()
			boot.world.add_child(cr)
			cr.global_position = _in_front(p1, 25.0)
			cr.rotation.y = p1.yaw
			_note = "A creature 25 m in front of P1, facing them."
		"spawn_box":
			var bx := CardboardBox.new()
			boot.world.add_child(bx)
			bx.global_position = _in_front(p1, 2.0)
			_note = "A cardboard box at P1's feet (E to pick it up, E again to get under it)."
		"spawn_naresh":
			var at := _in_front(p1, 2.5)
			if boot.naresh == null or not is_instance_valid(boot.naresh):
				boot.naresh = Naresh.spawn(boot.world, at, p1.yaw + PI)
			else:
				boot.naresh.command(p1, "wait")
				boot.naresh.global_position = at
				boot.naresh.reset_physics_interpolation()
			boot.naresh.command(p1, "follow")
			_note = "Naresh is next to P1, following. V / D-Up (hold) gives him jobs."
		"naresh_act":
			if boot.naresh == null:
				_note = "No Naresh here: spawn him first."
			elif boot.naresh.act_now():
				_note = "Naresh: %s (in 3 s)." % boot.naresh.act
			else:
				_note = "No random act fits right now."
		"naresh_mistake":
			if boot.naresh != null:
				boot.naresh.refuel_mistake = true
			_note = "The next refuel will use the empty can." if boot.naresh != null else "No Naresh here: spawn him first."
		"binoculars":
			for p in boot.players:
				p.has_binoculars = true
			_note = "Both have binoculars (hold RMB / LT)."
		"mood":
			var mood := get_tree().get_first_node_in_group("mood") as Mood
			if mood != null:
				mood.set_now(float(arg))
			_note = "Mood %.2f." % float(arg)
		"load":
			Boot.gym_request = String(arg)
			get_tree().paused = false
			get_tree().reload_current_scene()


## Bessi's steps (E): where each one happens, so a jump there puts you both
## on the spot, Naresh at your side (from the evidence on) and the van close
## by (for the storm, at the start of the coast road, ready to go).
## [poi, what the note calls it]
const STEP_PLACES := {
	"photo": ["beach", "the beach"],
	"roses": ["photo_spot", "the photo spot"],
	"naresh": ["roses", "the Five Roses"],
	"look_around": ["camp", "his camp"],
	"batteries": ["store_door", "the store"],
	"drum": ["boat_push", "the upturned boat"],
	"storm": ["", "the van, at the start of the coast road"],
}

func go_to_step(id: String) -> String:
	if boot.gym != "" or not STEP_PLACES.has(id):
		return ""
	var spec: Array = STEP_PLACES[id]
	var poi: Dictionary = boot.builder.poi
	var c: Camper = boot.camper
	var at: Vector3
	if id == "storm":
		# the van on the coast road where it leaves the loop, facing north
		var road: Route = boot.builder.network.road("coast_road")
		var i0 := 0
		for i in road.point_count():
			if road.point(i).z < 470.0:
				i0 = i
				break
		van_to(road.point(i0), atan2(-road.forward(i0).x, -road.forward(i0).z))
		c.repair_all()
		at = c.global_transform * Vector3(-3.2, 0, -1.0)
	else:
		at = poi[spec[0]]
		van_to(van_spot(at + Vector3(-18, 0, 6)), 0.0)
		c.repair_all()
	teleport(at)
	# Naresh with you from the evidence on (before that he's in the rose, or not yet found)
	var nz: Naresh = boot.naresh
	if nz != null and is_instance_valid(nz) and id in ["look_around", "batteries", "drum", "storm"]:
		var p1: PlayerRig = boot.players[0]
		if nz.sitting:
			nz.stand_from_seat(p1)
		nz.global_position = safe_spot(p1.global_position + p1.global_transform.basis * Vector3(1.5, 0, 1.5))
		nz.reset_physics_interpolation()
		nz.command(p1, "follow")
	return String(spec[1])


func _place_name(key: String) -> String:
	for sec in PLACES:
		for e in sec[1]:
			if e[0] == key:
				return e[1]
	return key.replace("_", " ")


func _in_front(p: PlayerRig, dist: float) -> Vector3:
	var at := p.global_position - p.global_transform.basis.z * dist
	return Vector3(at.x, Landscape.ground(at.x, at.z) + 0.4, at.z)


# --- safe places to stand ---------------------------------------------------------

## Both players to a named place: somewhere each can stand near it (P2 a
## little to the side), out of the van if seated, facing the place.
func teleport_to(key: String) -> void:
	teleport(boot.builder.poi[key])


func teleport(at: Vector3) -> void:
	var taken: Array[Vector3] = []
	for i in boot.players.size():
		var p: PlayerRig = boot.players[i]
		if p.seat != null:
			p.exit_vehicle()
		var spot := safe_spot(at, taken)
		taken.append(spot)
		p.global_position = spot
		var d := at - spot
		if Vector2(d.x, d.z).length() > 0.5:
			p.yaw = atan2(-d.x, -d.z)
			p.rotation.y = p.yaw
		p.pitch = 0.0
		p.velocity = Vector3.ZERO
		p._plan_vel = Vector2.ZERO
		p.reset_physics_interpolation()


## Where a player can stand near `at`: rings outwards from it; at each spot
## a ray down from just above the place's own height (so decks and floors
## count, and a roof overhead doesn't), then a capsule-sized check that
## nothing solid is there. `avoid`: spots already taken (the other player).
var last_search := {}           ## why candidate spots were turned down (tests read it)


func safe_spot(at: Vector3, avoid: Array[Vector3] = []) -> Vector3:
	last_search = {"no_hit": 0, "steep": 0, "under": 0, "sea": 0, "taken": 0, "blocked": 0}
	var space := (boot.players[0] as Node3D).get_world_3d().direct_space_state
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = PlayerRig.STAND_HEIGHT + 0.1
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 1 | 8
	var exclude: Array[RID] = []
	for p in boot.players:
		exclude.append((p as CollisionObject3D).get_rid())
	q.exclude = exclude
	for r in [0.0, 1.5, 3.0, 4.5, 6.5, 9.0, 12.0, 16.0, 22.0, 30.0]:
		var n := 1 if r == 0.0 else 12
		for k in n:
			var a := TAU * k / n
			var xz: Vector3 = at + Vector3(cos(a), 0, sin(a)) * float(r)
			var ground := Landscape.ground(xz.x, xz.z)
			var top := maxf(at.y, ground) + 2.2
			var ray := PhysicsRayQueryParameters3D.create(Vector3(xz.x, top, xz.z), Vector3(xz.x, ground - 2.0, xz.z), 1 | 8, exclude)
			var hit := space.intersect_ray(ray)
			if hit.is_empty():
				last_search["no_hit"] += 1
				continue
			var feet: Vector3 = hit["position"]
			if (hit["normal"] as Vector3).y < 0.7:
				last_search["steep"] += 1
				continue                              # too steep to stand on
			if feet.y < ground - 0.3:
				last_search["under"] += 1
				continue                              # under the ground
			if Landscape.coast_inland(feet.x, feet.z) < 2.0 and feet.y < Landscape.SEA_Y + 0.3:
				last_search["sea"] += 1
				continue                              # in the sea (inland ground can be lower)
			var near_taken := false
			for t in avoid:
				if t.distance_to(feet) < 1.2:
					near_taken = true
			if near_taken:
				last_search["taken"] += 1
				continue
			q.transform = Transform3D(Basis(), feet + Vector3.UP * (shape.height * 0.5 + 0.08))
			var hits := space.intersect_shape(q, 1)
			if hits.is_empty():
				return feet + Vector3.UP * 0.08
			last_search["blocked"] += 1
			last_search["by"] = String((hits[0]["collider"] as Node).name) if hits[0]["collider"] is Node else "?"
	return Vector3(at.x, Landscape.ground(at.x, at.z) + 0.3, at.z)


## Clear ground for the van near `at` (a box the van's size, on the ground).
func van_spot(at: Vector3) -> Vector3:
	var space := (boot.players[0] as Node3D).get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.8, 2.6, 6.6)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 1 | 8
	var exclude: Array[RID] = [(boot.camper as CollisionObject3D).get_rid()]
	for p in boot.players:
		exclude.append((p as CollisionObject3D).get_rid())
	q.exclude = exclude
	for r in [0.0, 3.0, 6.0, 10.0, 15.0, 22.0]:
		var n := 1 if r == 0.0 else 12
		for k in n:
			var a := TAU * k / n
			var xz: Vector3 = at + Vector3(cos(a), 0, sin(a)) * float(r)
			var g := Landscape.ground(xz.x, xz.z)
			q.transform = Transform3D(Basis(), Vector3(xz.x, g + 1.6, xz.z))
			if space.intersect_shape(q, 1).is_empty():
				return Vector3(xz.x, g, xz.z)
	return at


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
	c.snap_visuals()
	c.set_deferred("freeze", false)
