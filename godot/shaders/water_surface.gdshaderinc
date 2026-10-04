// Shared look of native water (water.gdshader) and the open sea (ocean.gdshader).
// Needs terrain_common (surface_noise). shore is the signed coast distance in tiles
// (> 0 on water); calm controls swell, for rivers versus the open sea.

vec2 ripple_slope(vec2 p, float scale, vec2 drift, float time) {
	vec2 uv = p / scale + drift * time;
	float e = 0.06;
	float h = texture(surface_noise, uv).r;
	return vec2(texture(surface_noise, uv + vec2(e, 0.0)).r - h, texture(surface_noise, uv + vec2(0.0, e)).r - h) / e;
}

// Returns the world-space normal; writes albedo, roughness and foam.
vec3 water_surface(vec2 p, float shore, float time, out vec3 albedo, out float roughness, out float foam) {
	float depth = smoothstep(0.0, 4.0, shore);
	float deep_sea = smoothstep(3.0, 12.0, shore);
	vec3 sandy = vec3(0.20, 0.31, 0.25);
	vec3 shallow = vec3(0.055, 0.235, 0.235);
	vec3 deep = vec3(0.018, 0.085, 0.115);
	vec3 abyss = vec3(0.010, 0.050, 0.085);
	albedo = mix(sandy, shallow, smoothstep(0.0, 0.9, shore));
	albedo = mix(albedo, deep, depth);
	albedo = mix(albedo, abyss, deep_sea);
	// Light dancing over the shallow bed.
	float caustic = texture(surface_noise, p / 1.7 + vec2(time * 0.03, -time * 0.021)).r
		* texture(surface_noise, p / 2.3 - vec2(time * 0.025, time * 0.017)).r;
	albedo += vec3(0.05, 0.07, 0.05) * smoothstep(0.3, 0.55, caustic) * (1.0 - depth);
	// Layered drifting ripples, faded where a pixel covers more than they can show.
	float detail = 1.0 - smoothstep(0.12, 1.1, length(fwidth(p)));
	vec2 slope = ripple_slope(p, 9.0, vec2(0.011, 0.007), time) * 0.4
		+ ripple_slope(mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p, 3.3, vec2(-0.018, 0.012), time) * 0.32 * detail
		+ ripple_slope(p, 1.1, vec2(0.03, -0.024), time) * 0.08 * detail;
	slope *= 0.03 * mix(0.6, 1.0, depth);
	slope.x += cos(dot(p, vec2(1.3, 0.6)) + time * 0.48) * 0.012 * detail;
	slope.y += cos(dot(p, vec2(0.5, 1.6)) - time * 0.41) * 0.010 * detail;
	// Lapping foam: a thin contact line plus bands that run up the beach and fade.
	float breakup = texture(surface_noise, p / 1.3 + vec2(time * 0.02, 0.0)).r;
	float contact = 1.0 - smoothstep(0.0, 0.16, shore);
	float bands = smoothstep(0.72, 0.95, sin(shore * 10.0 - time * 1.3 + breakup * 5.0) * 0.5 + 0.5)
		* (1.0 - smoothstep(0.05, 0.6, shore));
	foam = clamp(contact * 0.85 + bands * 0.45, 0.0, 1.0) * smoothstep(0.25, 0.6, breakup + contact * 0.4);
	albedo = mix(albedo, vec3(0.80, 0.83, 0.81), foam);
	roughness = mix(0.16, 0.6, foam);
	return normalize(vec3(-slope.x, 1.0, -slope.y));
}
