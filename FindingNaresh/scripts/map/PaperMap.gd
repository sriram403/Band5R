class_name PaperMap
extends Control

## A player's paper map, raised in front of their view. Drawn with vector
## calls on top of a printed relief (contours and hill shading), so it stays
## crisp in a split-screen half. Roads, water and landmarks only appear once
## discovered (see MapState). There is deliberately no "you are here".
##
## While it is up, look input moves a pencil cursor instead of the camera,
## and the stamp keys place or rub out shared stamps.

const PAPER := Color(0.94, 0.89, 0.76)
const PAPER_EDGE := Color(0.78, 0.70, 0.54)
const INK := Color(0.23, 0.19, 0.16)
const INK_SOFT := Color(0.40, 0.33, 0.26, 0.85)
const WATER := Color(0.36, 0.58, 0.74)
const GRAVEL := Color(0.52, 0.40, 0.26)

const STAMP_STYLE := {
	"fuel": {"col": Color(0.85, 0.30, 0.18), "glyph": "F", "name": "FUEL"},
	"danger": {"col": Color(0.80, 0.10, 0.12), "glyph": "!", "name": "DANGER"},
	"puzzle": {"col": Color(0.45, 0.30, 0.75), "glyph": "?", "name": "PUZZLE"},
	"shortcut": {"col": Color(0.15, 0.55, 0.35), "glyph": ">", "name": "SHORTCUT"},
	"unexplored": {"col": Color(0.30, 0.45, 0.70), "glyph": "o", "name": "UNEXPLORED"},
}

static var _relief: ImageTexture = null

var state: MapState
var cursor := Vector2(0.5, 0.5)       ## in map units, 0..1 across the paper
var stamp_index := 0
var zoom := 1.0                       ## 1 = whole valley on the sheet, up to 4x
var view_center := Vector2(0.5, 0.5)  ## paper point shown in the middle when zoomed
var _font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_font = ThemeDB.fallback_font
	if state:
		state.changed.connect(queue_redraw)
	if _relief == null:
		_relief = _make_relief()


func bind(s: MapState) -> void:
	state = s
	if is_inside_tree():
		state.changed.connect(queue_redraw)


# --- geometry ------------------------------------------------------------------

## The paper's rectangle inside this control (square-ish, centred).
func paper_rect() -> Rect2:
	var s := minf(size.x * 0.94, size.y * 0.90)
	var w := s * (MapState.BOUNDS.size.x / MapState.BOUNDS.size.y)
	w = minf(w, size.x * 0.94)
	return Rect2((size.x - w) * 0.5, (size.y - s) * 0.5, w, s)


## Paper point (0..1) to screen, through the current zoom.
func paper_to_screen(u: Vector2) -> Vector2:
	var r := paper_rect()
	return r.position + ((u - view_center) * zoom + Vector2(0.5, 0.5)) * r.size


func world_to_map(p: Vector2) -> Vector2:
	var b := MapState.BOUNDS
	return paper_to_screen(Vector2((p.x - b.position.x) / b.size.x, (p.y - b.position.y) / b.size.y))


## Zoom about the pencil, keeping the view on the sheet.
func zoom_by(f: float) -> void:
	zoom = clampf(zoom * f, 1.0, 4.0)
	view_center = cursor
	var half := 0.5 / zoom
	view_center = view_center.clamp(Vector2(half, half), Vector2(1.0 - half, 1.0 - half))
	queue_redraw()


func map_to_world(u: Vector2) -> Vector2:
	var b := MapState.BOUNDS
	return b.position + Vector2(u.x * b.size.x, u.y * b.size.y)


func cursor_world() -> Vector2:
	return map_to_world(cursor)


func current_stamp() -> String:
	return MapState.STAMP_TYPES[stamp_index]


## Move the pencil by a pixel delta (mouse) or a scaled stick delta.
func move_cursor(px: Vector2) -> void:
	var r := paper_rect()
	cursor += Vector2(px.x / r.size.x, px.y / r.size.y) / zoom
	cursor = cursor.clamp(Vector2(0.01, 0.01), Vector2(0.99, 0.99))
	queue_redraw()


func cycle_stamp(dir: int) -> void:
	stamp_index = wrapi(stamp_index + dir, 0, MapState.STAMP_TYPES.size())
	queue_redraw()


func place_stamp() -> void:
	state.add_stamp(current_stamp(), cursor_world())


func remove_stamp() -> bool:
	# "near" in world metres, scaled so it feels the same size on the paper
	return state.remove_stamp_near(cursor_world(), MapState.BOUNDS.size.x * 0.03)


# --- drawing -------------------------------------------------------------------

func _draw() -> void:
	if state == null:
		return
	# dim the world behind the sheet a little
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))
	var r := paper_rect()
	draw_rect(r.grow(8), PAPER_EDGE)
	draw_rect(r, PAPER)
	if _relief:
		# only the visible part of the printed relief, stretched over the sheet
		var half := 0.5 / zoom
		var src := Rect2((view_center - Vector2(half, half)) * _relief.get_size(), _relief.get_size() / zoom)
		draw_texture_rect_region(_relief, r, src, Color(1, 1, 1, 0.9))
	draw_rect(r, INK_SOFT, false, 2.0)

	var scale := r.size.x / MapState.BOUNDS.size.x * zoom
	for l in state.lakes:
		if l["revealed"]:
			var c := world_to_map(l["pos"])
			var rad: float = float(l["r"]) * scale
			draw_circle(c, rad, WATER)
			draw_arc(c, rad, 0, TAU, 32, INK_SOFT, 1.5)
	_draw_chunks(state.river_pts, state.river_chunks, WATER, maxf(3.0, 14.0 * scale), false)
	for road in state.roads:
		var gravel: bool = road["surface"] == "gravel"
		if gravel:
			_draw_chunks(road["pts"], road["chunks"], GRAVEL, maxf(2.0, 5.0 * scale), true)
		else:
			_draw_chunks(road["pts"], road["chunks"], INK, maxf(3.0, 9.0 * scale), false)
			_draw_chunks(road["pts"], road["chunks"], PAPER.lightened(0.3), maxf(1.2, 4.0 * scale), false)
	for m in state.landmarks:
		if m["revealed"]:
			_draw_landmark(m)
	for s in state.stamps:
		_draw_stamp(world_to_map(s["pos"]), s["type"], 1.0)

	# zoomed ink runs past the sheet: cover everything outside it again
	var edge := PAPER_EDGE
	if zoom > 1.01:
		_mask_outside(r, edge)

	# compass, title and scale bar
	var n := r.position + Vector2(r.size.x - 36, 44)
	draw_line(n + Vector2(0, 20), n + Vector2(0, -20), INK, 2.0)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, -24), n + Vector2(-7, -8), n + Vector2(7, -8)]), INK)
	draw_string(_font, n + Vector2(-5, 38), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	draw_string(_font, r.position + Vector2(18, 30), "ROSE VALLEY  -  road map", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	var bar := 200.0 * scale
	var b0 := r.end + Vector2(-bar - 60, -22)
	draw_line(b0, b0 + Vector2(bar, 0), INK, 3.0)
	draw_string(_font, b0 + Vector2(0, -6), "200 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)

	# pencil cursor and the stamp it will place
	var cp := paper_to_screen(cursor)
	_draw_stamp(cp + Vector2(22, -22), current_stamp(), 0.8)
	draw_line(cp + Vector2(-10, 0), cp + Vector2(10, 0), INK, 1.5)
	draw_line(cp + Vector2(0, -10), cp + Vector2(0, 10), INK, 1.5)
	var help := "Stamp: %s   [Q/E] change   [LMB] place   [RMB] rub out   [wheel / + -] zoom %.1fx   [M] put away" % [STAMP_STYLE[current_stamp()]["name"], zoom]
	draw_string(_font, Vector2(r.position.x, r.end.y + 26), help, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 15, Color(1, 1, 1, 0.95))


## Draw the revealed pieces of a chunked polyline.
func _mask_outside(r: Rect2, edge: Color) -> void:
	var dark := Color(0.12, 0.1, 0.08)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, r.position.y - 8)), dark)
	draw_rect(Rect2(Vector2(0, r.end.y + 8), Vector2(size.x, size.y - r.end.y - 8)), dark)
	draw_rect(Rect2(Vector2(0, r.position.y - 8), Vector2(r.position.x - 8, r.size.y + 16)), dark)
	draw_rect(Rect2(Vector2(r.end.x + 8, r.position.y - 8), Vector2(size.x - r.end.x - 8, r.size.y + 16)), dark)
	draw_rect(r.grow(8), edge, false, 8.0)


func _draw_chunks(pts: PackedVector2Array, chunks: Array, col: Color, width: float, dashed: bool) -> void:
	var step := MapState.ROAD_CHUNK
	for c in chunks.size():
		if not chunks[c]:
			continue
		var line := PackedVector2Array()
		for i in range(c * step, mini((c + 1) * step + 1, pts.size())):
			line.append(world_to_map(pts[i]))
		if line.size() < 2:
			continue
		if dashed:
			for k in range(0, line.size() - 1, 2):
				draw_line(line[k], line[k + 1], col, width)
		else:
			draw_polyline(line, col, width, true)


func _draw_landmark(m: Dictionary) -> void:
	var p := world_to_map(m["pos"])
	var s := 9.0
	match m["icon"]:
		"house":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s), p + Vector2(s, 0)]), INK)
			draw_rect(Rect2(p + Vector2(-s * 0.7, 0), Vector2(s * 1.4, s * 0.8)), INK)
		"windmill", "tower", "mast":
			draw_line(p + Vector2(0, s), p + Vector2(0, -s), INK, 2.0)
			draw_line(p + Vector2(-s * 0.6, s), p + Vector2(0, -s * 0.2), INK, 1.5)
			draw_line(p + Vector2(s * 0.6, s), p + Vector2(0, -s * 0.2), INK, 1.5)
			if m["icon"] == "windmill":
				for k in 4:
					var a := TAU * k / 4.0 + 0.4
					draw_line(p + Vector2(0, -s), p + Vector2(0, -s) + Vector2(cos(a), sin(a)) * s * 0.8, INK, 1.5)
			if m["icon"] == "mast":
				draw_circle(p + Vector2(0, -s - 2), 2.5, Color(0.8, 0.1, 0.1))
		"roses":
			for k in 5:
				var a := TAU * k / 5.0 - PI * 0.5
				draw_circle(p + Vector2(cos(a), sin(a)) * s * 1.1, 4.0, Color(0.78, 0.12, 0.2))
		"fuel":
			draw_rect(Rect2(p - Vector2(s * 0.6, s * 0.8), Vector2(s * 1.2, s * 1.6)), Color(0.8, 0.2, 0.15))
		"bridge":
			draw_line(p + Vector2(-s, -3), p + Vector2(s, -3), INK, 2.0)
			draw_line(p + Vector2(-s, 3), p + Vector2(s, 3), INK, 2.0)
			draw_line(p + Vector2(-3, -6), p + Vector2(3, 6), Color(0.8, 0.1, 0.1), 2.5)
		_:
			draw_circle(p, s * 0.5, INK)
	draw_string(_font, p + Vector2(s + 3, 5), m["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)


func _draw_stamp(p: Vector2, type: String, alpha: float) -> void:
	var st: Dictionary = STAMP_STYLE[type]
	var col: Color = st["col"]
	col.a = alpha
	draw_circle(p, 11.0, col)
	draw_arc(p, 11.0, 0, TAU, 20, Color(0, 0, 0, 0.5 * alpha), 1.5)
	draw_string(_font, p + Vector2(-5, 6), st["glyph"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, alpha))


## Printed relief: paper tone darkened on steep ground and in hollows, with a
## contour line every 6 m. Built once from the terrain grid.
static func _make_relief() -> ImageTexture:
	var b := MapState.BOUNDS
	var w := 360
	var h := int(w * b.size.y / b.size.x)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var heights := PackedFloat32Array()
	heights.resize(w * h)
	for y in h:
		for x in w:
			var wx := b.position.x + (x + 0.5) / w * b.size.x
			var wz := b.position.y + (y + 0.5) / h * b.size.y
			heights[y * w + x] = Landscape.ground(wx, wz)
	for y in h:
		for x in w:
			var hh := heights[y * w + x]
			var hr := heights[y * w + mini(x + 1, w - 1)]
			var hd := heights[mini(y + 1, h - 1) * w + x]
			# light from the north-west
			var shade := clampf(0.5 + (hh - hr) * 0.08 + (hh - hd) * 0.08, 0.0, 1.0)
			var c := Color(0.94, 0.89, 0.76).darkened(0.18 * (1.0 - shade))
			c = c.lerp(Color(0.80, 0.84, 0.66), clampf((hh - 10.0) / 40.0, 0.0, 0.35))
			var band := floori(hh / 6.0)
			if band != floori(hr / 6.0) or band != floori(hd / 6.0):
				c = c.darkened(0.25)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
