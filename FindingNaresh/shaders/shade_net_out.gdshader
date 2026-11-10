shader_type spatial;
// Old shade netting (#6), the outside layer: from the bright outside a dull
// dark weave, opaque (the van inside can't be seen). Front faces only.
render_mode cull_back, diffuse_toon, specular_disabled;

uniform vec4 outside_col : source_color = vec4(0.17, 0.20, 0.15, 1.0);
uniform vec4 thread_col : source_color = vec4(0.11, 0.13, 0.10, 1.0);
uniform float pitch = 0.03;
uniform float thread = 0.18;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = VERTEX;            // the box's own axes: the weave follows the van
	wnorm = abs(NORMAL);
}

void fragment() {
	vec3 g = abs(fract(wpos / pitch) - 0.5);
	float gx = wnorm.x > 0.5 ? max(g.y, g.z) : (wnorm.y > 0.5 ? max(g.x, g.z) : max(g.x, g.y));
	float line = step(0.5 - thread * 0.5, gx);
	ALBEDO = mix(outside_col.rgb, thread_col.rgb, line * 0.6);
	ROUGHNESS = 1.0;
}
