class_name CloudSky
extends RefCounted

## The sky with clouds (puzzle #3's weather, design/PUZZLE_CHANGES.md #3):
## Godot's procedural sky has none. A gradient sky like the old one (the
## same colours, set by Mood), the sun's disc, and drifting clouds whose
## cover (0 clear .. 1 overcast) and darkness come from the weather.

const CODE := """
shader_type sky;

uniform vec3 sky_top : source_color = vec3(0.16, 0.40, 0.82);
uniform vec3 sky_horizon : source_color = vec3(0.62, 0.80, 0.93);
uniform vec3 ground_bottom : source_color = vec3(0.20, 0.28, 0.22);
uniform vec3 ground_horizon : source_color = vec3(0.46, 0.60, 0.62);
uniform float cover : hint_range(0.0, 1.0) = 0.45;
uniform float cloud_dark : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cloud_lit : source_color = vec3(0.97, 0.97, 0.98);
uniform vec3 cloud_shade : source_color = vec3(0.52, 0.55, 0.62);

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
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 5; k++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	vec3 col;
	if (d.y >= 0.0) {
		col = mix(sky_horizon, sky_top, pow(clamp(d.y, 0.0, 1.0), 0.45));
	} else {
		col = mix(ground_horizon, ground_bottom, clamp(-d.y * 3.0, 0.0, 1.0));
	}
	float cl = 0.0;
	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.15) * 1.2 + vec2(mod(TIME * 0.004, 200.0), mod(TIME * 0.0015, 200.0));
		float n = fbm(uv);
		float lo = mix(0.70, 0.08, cover);
		cl = smoothstep(lo, lo + 0.18, n) * smoothstep(0.0, 0.10, d.y);
		float thick = smoothstep(lo + 0.05, lo + 0.45, n);
		vec3 cc = mix(cloud_lit, cloud_shade, clamp(thick * 0.85 + cloud_dark, 0.0, 1.0));
		cc = mix(cc, cloud_shade * 0.45, cloud_dark * 0.6);
		col = mix(col, cc, cl * 0.96);
	}
	if (LIGHT0_ENABLED) {
		float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
		float disk = smoothstep(0.99970, 0.99985, sd);
		float glow = pow(sd, 48.0) * 0.18 + pow(sd, 500.0) * 0.5;
		col += LIGHT0_COLOR * min(LIGHT0_ENERGY, 1.6) * (disk * 2.5 + glow) * (1.0 - cl * 0.92);
	}
	COLOR = col;
}
"""

static var _shader: Shader


static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var m := ShaderMaterial.new()
	m.shader = _shader
	return m
