class_name MazePlan
extends Control

## Puzzle #3 round 3: the guide's plan of the barn maze, full screen (from
## Naresh's half-finished sketch on the silo rail). Drawn cells in ink;
## cells the walker has been through that nobody has drawn yet as faint
## pencil (hold E to draw them in); landmarks as names; the guide's pencil
## crosses (S15: click / A to pencil one, right-click / X to rub one out). No
## "you are here": the walker's flag over the hedges is that.

var maze: BarnMaze
var player: PlayerRig
var draw_t := 0.0                ## s of E held towards drawing the new bit
var cursor := Vector2(0.5, 0.5)  ## 0..1 on the plan
var _seen := -1

const DRAW_S := 3.0
const INK := Color(0.28, 0.28, 0.38)
const PENCIL := Color(0.45, 0.45, 0.50, 0.55)
const PAPER := Color(0.95, 0.92, 0.80)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_delta: float) -> void:
	if visible and maze != null and (maze.plan_changed != _seen or draw_t > 0.0):
		_seen = maze.plan_changed
		queue_redraw()


func paper_rect() -> Rect2:
	var side := minf(size.x, size.y) * 0.86
	return Rect2((size - Vector2(side, side)) * 0.5 + Vector2(0, size.y * 0.02), Vector2(side, side))


func _to_screen(uv: Vector2) -> Vector2:
	var r := paper_rect()
	var m := r.size.x * 0.04
	return r.position + Vector2(m, m) + uv * (r.size.x - 2.0 * m)


func move_cursor(px: Vector2) -> void:
	var r := paper_rect()
	cursor = (cursor + px / r.size.x).clamp(Vector2.ZERO, Vector2.ONE)
	queue_redraw()


## The cell under the cursor.
func cursor_cell() -> Vector2i:
	var n := BarnMaze.N
	return Vector2i(clampi(int(cursor.x * n), 0, n - 1), clampi(int(cursor.y * n), 0, n - 1))


func _cell_rect(c: Vector2i) -> Rect2:
	var n := float(BarnMaze.N)
	var a := _to_screen(Vector2(c.x / n, c.y / n))
	var b := _to_screen(Vector2((c.x + 1) / n, (c.y + 1) / n))
	return Rect2(a, b - a)


func _draw() -> void:
	if maze == null:
		return
	var r := paper_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	draw_rect(r, PAPER)
	draw_rect(r, Color(0.45, 0.32, 0.22), false, 4.0)
	var font := ThemeDB.fallback_font
	var w := maxf(1.5, r.size.x / 260.0)
	# the walls of drawn cells in ink, of found-but-not-drawn ones in pencil
	for set_i in 2:
		var cells: Dictionary = maze.drawn if set_i == 0 else maze.pending
		var col := INK if set_i == 0 else PENCIL
		for c in cells:
			var cr := _cell_rect(c)
			var cc: Vector2i = c
			if set_i == 1:
				draw_rect(cr.grow(-cr.size.x * 0.3), Color(0.5, 0.5, 0.55, 0.12))
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if not maze.wall_side(cc, d) and not maze.is_gap(cc, cc + d):
					continue
				var a: Vector2
				var b: Vector2
				match d:
					Vector2i(0, -1): a = cr.position; b = cr.position + Vector2(cr.size.x, 0)
					Vector2i(0, 1): a = cr.position + Vector2(0, cr.size.y); b = cr.end
					Vector2i(-1, 0): a = cr.position; b = cr.position + Vector2(0, cr.size.y)
					_: a = cr.position + Vector2(cr.size.x, 0); b = cr.end
				draw_line(a, b, col, w if set_i == 0 else w * 0.7)
	# doors in drawn or found cells
	for d in maze.doors:
		var md := d as MazeDoor
		if maze.drawn.has(md.cell_front) or maze.pending.has(md.cell_front):
			var pos := _to_screen(maze.plan_uv(md.position))
			draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), Color(0.62, 0.30, 0.14))
	# the landmarks drawn so far
	var pm := maze.plan_marks()
	for k in pm:
		var pos := _to_screen(maze.plan_uv(maze.cell_pos(pm[k])))
		draw_circle(pos, w * 2.0, Color(0.60, 0.12, 0.10))
		draw_string(font, pos + Vector2(6, 4), String(BarnMaze.PLAN_NAMES[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(11.0, r.size.x / 48.0)), Color(0.55, 0.12, 0.10))
	# the way in, the chest
	var inp := _to_screen(maze.plan_uv(maze.gate_spot()))
	draw_string(font, inp + Vector2(-14, -2), "in", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	# S15: the guide's pencil crosses
	for c in maze.crosses:
		var cr := _cell_rect(c).grow(-4)
		draw_line(cr.position, cr.end, Color(0.10, 0.10, 0.12), w * 1.4)
		draw_line(cr.position + Vector2(cr.size.x, 0), cr.position + Vector2(0, cr.size.y), Color(0.10, 0.10, 0.12), w * 1.4)
	# the cursor
	var cur := _cell_rect(cursor_cell())
	draw_rect(cur, Color(0.2, 0.4, 0.9, 0.18))
	draw_rect(cur, Color(0.2, 0.4, 0.9, 0.7), false, 2.0)
	# what to do
	var n_new := maze.pending.size()
	var g := func(a: String) -> String: return player.dev.glyph(a) if player != null and player.dev != null else a
	var line := ("[hold %s] draw in what they found (%d new)" % [g.call("interact"), n_new]) if n_new > 0 else "nothing new to draw yet"
	line += "     [%s] pencil a cross     [%s] rub it out     [%s] put it away" % [g.call("map_place"), g.call("map_remove"), g.call("map")]
	draw_string(font, Vector2(r.position.x, r.end.y + 22), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 15, Color(1, 1, 1, 0.9))
	if draw_t > 0.0:
		var bar := Rect2(r.position + Vector2(0, -16), Vector2(r.size.x * clampf(draw_t / DRAW_S, 0.0, 1.0), 6))
		draw_rect(bar, Color(0.3, 0.3, 0.4, 0.9))
