class_name SnowMat
extends RefCounted

## The cartoon material for the ground, trees, bushes and rocks, with snow
## that settles on whatever faces up as the global `snow_cover` (0..1, set by
## Weather) grows: after the barn maze the world whitens bit by bit (the
## user, 2026-10-08). The terrain's vertex alpha says where snow may lie (0
## on the road, where the tyres run).

const CODE := """
shader_type spatial;
render_mode diffuse_toon, specular_disabled, CULL;

global uniform float snow_cover;
uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vcol = false;
uniform bool vcol_mask = false;
uniform float roughness = 0.92;
uniform float snow_bias = 0.0;

varying vec3 wpos;
varying vec3 wn;

// no sin(): on the GPU it loses precision for large inputs (blocky streaks)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = albedo.rgb;
	if (use_vcol) {
		c *= COLOR.rgb;
	}
	float s = 0.0;
	if (snow_cover > 0.001) {
		float allow = vcol_mask ? COLOR.a : 1.0;
		float up = smoothstep(0.2, 0.85, abs(wn.y) * step(0.0, wn.y));
		float n = noise(wpos.xz * 0.35) * 0.6 + noise(wpos.xz * 1.9) * 0.4;
		// a dusting in patches at ~0.4, white fields by ~0.8
		s = smoothstep(0.0, 0.3, snow_cover * 1.1 + snow_bias - (1.0 - up) * 0.9 - n * 0.9) * allow;
	}
	ALBEDO = mix(c, vec3(0.90, 0.92, 0.96), s);
	ROUGHNESS = roughness;
}
"""

static var _shaders := {}
static var _cache := {}


static func _shader(cull: String) -> Shader:
	if not _shaders.has(cull):
		var sh := Shader.new()
		sh.code = CODE.replace("CULL", cull)
		_shaders[cull] = sh
	return _shaders[cull]


## Like ToonMat.make: `outline` is the inverted-hull width (0 = none).
static func make(color: Color, outline := 0.014, rough := 0.92, snow_bias := 0.0, cull := "cull_back") -> ShaderMaterial:
	var key := "%s|%.4f|%.2f|%.2f|%s" % [color.to_html(), outline, rough, snow_bias, cull]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = _shader(cull)
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("snow_bias", snow_bias)
	if outline > 0.0:
		m.next_pass = ToonMat._outline(outline)
	_cache[key] = m
	return m


## The same material drawing per-instance / per-vertex colours.
static func with_vcol(m: ShaderMaterial) -> ShaderMaterial:
	var key := "vcol|%d" % m.get_instance_id()
	if not _cache.has(key):
		var v: ShaderMaterial = m.duplicate()
		v.set_shader_parameter("use_vcol", true)
		_cache[key] = v
	return _cache[key]
