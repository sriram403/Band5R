class_name BoxView
extends ColorRect

## The look from inside the cardboard box: brown card above and below, a
## wide slit to see out of. Only over the wearer's own view; fades in and out
## as the box goes on and comes off.

const SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;      // 0 = no box, 1 = inside it
uniform vec2 size = vec2(800.0, 900.0);

void fragment() {
	vec2 p = UV * size;
	float half_slit = size.y * 0.17;
	float d = abs(p.y - size.y * 0.5) - half_slit;
	float card = smoothstep(-6.0, 6.0, d);
	// the slit's ends close in, a little rounded
	float ends = smoothstep(size.x * 0.44, size.x * 0.5, abs(p.x - size.x * 0.5));
	card = max(card, ends);
	// shading: darker towards the edges of the view, a seam line down the middle
	float shade = 0.75 + 0.25 * (1.0 - abs(UV.x - 0.5) * 2.0);
	float seam = 1.0 - (1.0 - smoothstep(0.0, 3.0, abs(p.x - size.x * 0.5))) * 0.35;
	vec3 brown = vec3(0.36, 0.26, 0.16) * shade * seam;
	COLOR = vec4(brown, card * 0.98 * amount);
}
"""

var amount := 0.0:
	set(v):
		amount = v
		visible = v > 0.01
		(material as ShaderMaterial).set_shader_parameter("amount", v)


func _init() -> void:
	name = "BoxView"
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
