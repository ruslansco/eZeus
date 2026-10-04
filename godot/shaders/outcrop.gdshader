shader_type spatial;
// Mineral outcrops: baked vertex palette (RGB) with an ore mask (A) from
// tools/godot_mineral_outcrops.py. Each resource kind sets its own response.
uniform sampler2D surface_noise : filter_linear_mipmap, repeat_enable;
uniform float base_roughness = 0.92;
uniform float base_specular = 0.24;
uniform float grain_strength = 0.16;
uniform float ore_metallic = 0.0;
uniform float ore_roughness = 0.5;
uniform float ore_emission = 0.0;
uniform vec3 vein_colour = vec3(0.0);
uniform float vein_strength = 0.0;
uniform float vein_scale = 1.6;
varying float tint;
varying float seed;
varying vec3 local_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	tint = 0.92 + seed * 0.16;
	local_position = VERTEX;
	local_normal = NORMAL;
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}

// Triplanar noise in model space, so grain and veins stay fixed to each rock.
float triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	return texture(surface_noise, p.yz).r * w.x + texture(surface_noise, p.xz).r * w.y + texture(surface_noise, p.xy).r * w.z;
}

void fragment() {
	vec3 p = local_position + vec3(seed * 7.3, 0.0, seed * 3.1);
	float grain = triplanar(p / 0.35, local_normal);
	float ore = COLOR.a;
	vec3 albedo = COLOR.rgb * tint * (1.0 - grain_strength * 0.5 + grain * grain_strength);
	if (vein_strength > 0.0) {
		// Marble veining: thin bands along a warped noise isoline, plus faint secondary threads.
		float field = triplanar(p * vein_scale * 0.31 + grain * 0.08, local_normal);
		float vein = 1.0 - smoothstep(0.004, 0.022, abs(field - 0.5));
		float thread = 1.0 - smoothstep(0.002, 0.012, abs(triplanar(p * vein_scale * 0.73, local_normal) - 0.45));
		albedo = mix(albedo, vein_colour, clamp(vein + thread * 0.45, 0.0, 1.0) * vein_strength);
	}
	ALBEDO = albedo;
	METALLIC = ore * ore_metallic;
	ROUGHNESS = mix(base_roughness, ore_roughness, ore) * (0.9 + grain * 0.2);
	SPECULAR = mix(base_specular, 0.5, ore);
	if (ore_emission > 0.0) {
		// A slow, uneven glow so precious ore reads at city distance and in shade.
		float pulse = 0.78 + 0.22 * sin(TIME * 1.1 + world_position.x * 1.7 + world_position.z * 2.3);
		EMISSION = COLOR.rgb * ore * ore_emission * pulse;
	}
}
