class_name BinocularView
extends ColorRect

## The look through binoculars: two overlapping round eyepieces, dark outside,
## a soft edge. Drawn by a small shader over the player's own view only, and
## faded in with the zoom so raising them reads as a movement.

const SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;      // 0 = lowered, 1 = at the eyes
uniform vec2 size = vec2(800.0, 900.0);

void fragment() {
	vec2 p = UV * size;
	vec2 c = size * 0.5;
	float r = min(size.x * 0.30, size.y * 0.46);   // both eyepieces fit a half-screen
	vec2 off = vec2(r * 0.62, 0.0);
	float d = min(distance(p, c - off), distance(p, c + off));
	float dark = smoothstep(r - 14.0, r + 2.0, d);
	// a faint rim of light where the glass meets the housing
	float rim = (1.0 - smoothstep(0.0, 10.0, abs(d - r + 10.0))) * 0.10;
	COLOR = vec4(vec3(0.02), clamp(dark * 0.97 + rim, 0.0, 1.0) * amount);
}
"""

var amount := 0.0:
	set(v):
		amount = v
		visible = v > 0.01
		(material as ShaderMaterial).set_shader_parameter("amount", v)


func _init() -> void:
	name = "Binoculars"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	material = m
	color = Color.WHITE
	visible = false
	resized.connect(func(): m.set_shader_parameter("size", size))
	# the zoom, small at the bottom, like the scale on the ring
	_level = Label.new()
	_level.name = "Level"
	_level.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_level.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_level.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_level.position.y -= 18.0
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level.add_theme_font_size_override("font_size", 18)
	_level.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 0.85))
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level)


var _level: Label


## "6x   Wheel up / down: zoom" under the eyepieces.
func show_level(z: float, zoom_in: String, zoom_out: String) -> void:
	_level.text = "%dx      [%s / %s]  zoom" % [roundi(z), zoom_in, zoom_out]
