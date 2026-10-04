shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

// Low-lying ground fog/mist that slowly rolls across the temple courtyard.
// Creates depth and atmosphere in the login scene.

uniform vec4 fog_color : source_color = vec4(0.10, 0.18, 0.32, 0.35);
uniform float fog_speed : hint_range(0.01, 1.0) = 0.08;
uniform float fog_density : hint_range(0.1, 3.0) = 1.2;

float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash1(i);
	float b = hash1(i + vec2(1.0, 0.0));
	float c = hash1(i + vec2(0.0, 1.0));
	float d = hash1(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = rot * p * 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	// Slowly drifting fog
	vec2 drift = vec2(TIME * fog_speed, TIME * fog_speed * 0.3);
	float f1 = fbm3(uv * 3.0 + drift);
	float f2 = fbm3(uv * 5.0 - drift * 0.7 + vec2(5.0, 3.0));
	float fog = (f1 * 0.6 + f2 * 0.4);
	fog = pow(fog, 1.5) * fog_density;

	// Fade at edges
	float edge_x = smoothstep(0.0, 0.2, uv.x) * smoothstep(1.0, 0.8, uv.x);
	float edge_y = smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
	fog *= edge_x * edge_y;

	ALBEDO = fog_color.rgb * fog;
	ALPHA = fog * fog_color.a;
}
