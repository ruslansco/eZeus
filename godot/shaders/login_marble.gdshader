shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Procedural veined marble with subsurface-like depth and polished reflections.
// Used for the login screen temple floor and architectural surfaces.

uniform vec4 marble_base : source_color = vec4(0.82, 0.82, 0.80, 1.0);
uniform vec4 marble_vein : source_color = vec4(0.22, 0.24, 0.30, 1.0);
uniform float vein_scale : hint_range(1.0, 20.0) = 6.0;
uniform float vein_sharpness : hint_range(1.0, 10.0) = 3.5;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.22;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.04;
uniform float sss_strength : hint_range(0.0, 1.0) = 0.12;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = rot * p * 2.1;
		a *= 0.47;
	}
	return v;
}

// Turbulent marble veining via warped domain FBM
float marble_vein_pattern(vec2 uv) {
	vec2 q = vec2(fbm(uv), fbm(uv + vec2(5.2, 1.3)));
	vec2 r = vec2(fbm(uv + 4.0 * q + vec2(1.7, 9.2)), fbm(uv + 4.0 * q + vec2(8.3, 2.8)));
	float f = fbm(uv + 3.0 * r);
	// Create vein-like streaks
	float vein = abs(sin((uv.x + f * 2.0) * 3.14159));
	vein = pow(vein, vein_sharpness);
	return vein;
}

void fragment() {
	vec2 uv = UV * vein_scale;

	// Primary veining
	float vein1 = marble_vein_pattern(uv);
	// Secondary finer veins at different angle
	float vein2 = marble_vein_pattern(uv * 1.7 + vec2(3.0, 7.0)) * 0.4;
	// Micro grain
	float grain = noise(uv * 12.0) * 0.08;

	float vein_mix = clamp(vein1 + vein2 + grain, 0.0, 1.0);
	vec3 color = mix(marble_base.rgb, marble_vein.rgb, vein_mix * 0.7);

	// Subsurface-like warm translucency in thin areas
	color += vec3(0.08, 0.04, 0.02) * (1.0 - vein_mix) * sss_strength;

	// Slight roughness variation following veins
	float rough = roughness_value + vein_mix * 0.12;

	ALBEDO = color;
	ROUGHNESS = rough;
	METALLIC = metallic_value;
	SPECULAR = 0.5;
	// Subtle normal perturbation for surface depth
	float nx = (marble_vein_pattern(uv + vec2(0.01, 0.0)) - marble_vein_pattern(uv - vec2(0.01, 0.0))) * 0.3;
	float ny = (marble_vein_pattern(uv + vec2(0.0, 0.01)) - marble_vein_pattern(uv - vec2(0.0, 0.01))) * 0.3;
	NORMAL_MAP = vec3(0.5 + nx, 0.5 + ny, 1.0);
}
