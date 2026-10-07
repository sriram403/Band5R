class_name StarsRing
extends Control

## Little stars circling the middle of your view after a head-butt lands on
## you (or you butt a wall). `amount` 1 -> 0 as it wears off.

var amount := 0.0
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	visible = amount > 0.01
	if visible:
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5 + Vector2(0, -size.y * 0.12)
	var r := minf(size.x, size.y) * 0.09
	for i in 5:
		var a := _t * 3.0 + TAU * i / 5.0
		var p := c + Vector2(cos(a) * r * 1.6, sin(a) * r * 0.55)
		_star(p, r * 0.22 * (0.8 + 0.2 * sin(_t * 9.0 + i)), Color(1.0, 0.92, 0.3, amount))


func _star(p: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI * 0.5 + TAU * k / 10.0
		var rr := s if k % 2 == 0 else s * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.35, 0.2, 0.05, col.a), 1.5)
