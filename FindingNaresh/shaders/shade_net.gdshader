shader_type spatial;
// Old shade netting (#6, agreed 2026-11-09, S1), the inside layer: from the
// dark inside you look out through the weave, a faint grid over a clear view,
// like a mosquito net. Drawn on the sheet's back faces only (what you see from
// inside); the outside is an opaque dark skin (shade_net_out.gdshader), so
// nothing inside the van (glass, the bonnet) shows through from outside.
render_mode cull_front, depth_draw_never, unshaded;

uniform vec4 thread_col : source_color = vec4(0.08, 0.10, 0.07, 1.0);
uniform float pitch = 0.03;       // m between threads
uniform float thread = 0.18;      // fraction of the pitch a thread covers
uniform float thread_alpha = 0.26;
uniform float gap_alpha = 0.03;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = VERTEX;            // the box's own axes: the weave follows the van
	wnorm = abs(NORMAL);
}

void fragment() {
	vec3 g = abs(fract(wpos / pitch) - 0.5);
	// the two threads lying along this face (the third axis is the face's normal)
	float gx = wnorm.x > 0.5 ? max(g.y, g.z) : (wnorm.y > 0.5 ? max(g.x, g.z) : max(g.x, g.y));
	float line = step(0.5 - thread * 0.5, gx);
	ALBEDO = thread_col.rgb;
	ALPHA = mix(gap_alpha, thread_alpha, line);
}
