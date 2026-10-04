shader_type spatial;
// A soft gold ring on the ground under the walker the mouse rests on.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 colour : source_color = vec4(1.0, 0.86, 0.45, 0.9);

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float band = smoothstep(0.62, 0.72, r) * (1.0 - smoothstep(0.86, 0.98, r));
	float glow = (1.0 - smoothstep(0.0, 0.9, r)) * 0.14;
	ALBEDO = colour.rgb;
	ALPHA = colour.a * max(band, glow);
}
