class_name CommandWheel
extends Control

## The job wheel round the crosshair while a player holds the command key
## (PlayerRig.wheel_*): one slice per job, clockwise from the top, the one
## pointed at lit up. A single job sits on top, already picked.

var player: PlayerRig
const RADIUS := 92.0
const FONT := 17


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	visible = player != null and player.wheel_open
	if visible:
		queue_redraw()


func _draw() -> void:
	var jobs := player.wheel_jobs
	var n := jobs.size()
	if n == 0:
		return
	var c := size * 0.5
	var font := get_theme_default_font()
	draw_circle(c, RADIUS * 0.34, Color(0, 0, 0, 0.35))
	draw_arc(c, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.18), 2.0)
	for i in n:
		# slice i points at angle i * TAU / n, clockwise from straight up
		var a := float(i) * TAU / float(n)
		var dir := Vector2(sin(a), -cos(a))
		var at := c + dir * RADIUS
		var sel := i == player.wheel_sel
		var text: String = jobs[i]["label"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT).x
		var box := Rect2(at - Vector2(w * 0.5 + 12.0, 17.0), Vector2(w + 24.0, 32.0))
		draw_rect(box, Color(0.95, 0.80, 0.32, 0.92) if sel else Color(0.06, 0.07, 0.09, 0.78))
		draw_rect(box, Color(1, 1, 1, 0.5 if sel else 0.2), false, 1.5)
		draw_string(font, Vector2(box.position.x + 12.0, at.y + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT,
			Color(0.1, 0.08, 0.05) if sel else Color(1, 1, 1, 0.95))
	# where the pointer is
	var cur := player.wheel_cursor / PlayerRig.WHEEL_PICK * RADIUS * 0.8
	draw_circle(c + cur, 4.0, Color(1, 1, 1, 0.85))
	var title := "Naresh"
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, c + Vector2(-tw * 0.5, -RADIUS - 30.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.95, 0.6))
