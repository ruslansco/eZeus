shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

// Enhanced ethereal energy ribbon shader with color shifting, temporal noise,
// hotter core emission and Fresnel-like edge glow for cinematic particle trails.

uniform vec4 ribbon_color : source_color = vec4(0.15, 0.88, 1.0, 0.85);
uniform vec4 ribbon_color_warm : source_color = vec4(0.55, 0.92, 0.72, 0.85);
uniform float core_brightness : hint_range(1.0, 8.0) = 3.6;
uniform float shimmer_speed : hint_range(0.5, 8.0) = 3.2;
uniform float color_shift_speed : hint_range(0.1, 3.0) = 0.8;

float hash1(float p) {
	return fract(sin(p * 127.1) * 43758.5453);
}

void fragment() {
	// Soft Gaussian falloff along width (UV.x) and tapered length (UV.y)
	float dx = abs(UV.x - 0.5) * 2.0;
	float dy = abs(UV.y - 0.5) * 2.0;

	// Lateral: sharper core, softer edges
	float lateral = pow(max(1.0 - dx * dx, 0.0), 1.2);
	// Longitudinal: tapered tail with faster falloff at ends
	float longitudinal = pow(max(1.0 - dy * dy * dy, 0.0), 1.4);
	float streak = pow(lateral * longitudinal, 1.5);

	// Temporal shimmer: traveling wave along the ribbon length
	float shimmer = 0.7 + 0.3 * sin(UV.y * 12.0 - TIME * shimmer_speed + hash1(UV.x * 100.0) * 6.28);
	streak *= shimmer;

	// Hot white-blue center core for Bloom
	float core = pow(max(1.0 - dx, 0.0), 4.0) * longitudinal;

	// Color cycling between cool and warm tones
	float shift = sin(TIME * color_shift_speed + UV.y * 2.0) * 0.5 + 0.5;
	vec3 base_color = mix(ribbon_color.rgb, ribbon_color_warm.rgb, shift);

	// Edge Fresnel-like glow (halo around the ribbon)
	float edge_glow = pow(max(1.0 - abs(dx - 0.6) * 3.0, 0.0), 2.0) * longitudinal * 0.4;

	vec3 col = base_color * streak * core_brightness;
	col += vec3(1.0, 1.0, 1.0) * core * 2.2;  // Hot white center
	col += base_color * edge_glow * 1.5;        // Soft edge halo

	ALBEDO = col;
	ALPHA = streak * ribbon_color.a + edge_glow * 0.3;
}
