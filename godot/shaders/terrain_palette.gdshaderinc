// Shared Mediterranean ground palette for the native board (ground.gdshader) and the
// countryside around it (surroundings.gdshader), so the two meet without a seam.
// cover follows the native field: 0 plain land (fertile meadow included), 0.3 chopped forest/scrub, 0.75 forest.
// Needs `surface_noise`. Albedos are linear; the scene uses a linear tonemap.

// Large-scale noise from two rotated lookups: the seamless texture's blend skirt
// otherwise shows as straight bands every repeat across the countryside.
float macro_noise(vec2 p, float scale) {
	vec2 a = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p / scale;
	vec2 b = mat2(vec2(0.28, -0.96), vec2(0.96, 0.28)) * p / (scale * 1.37) + vec2(0.43, 0.19);
	float value = (texture(surface_noise, a).r + texture(surface_noise, b).r) * 0.5;
	return clamp((value - 0.5) * 1.5 + 0.5, 0.0, 1.0);
}

vec3 land_colour(vec2 p, float cover) {
	float region = macro_noise(p, 173.0);
	float broad = macro_noise(p, 48.0);
	float patches = texture(surface_noise, p / 11.0 + vec2(3.1, 7.7)).r;
	float clumps = texture(surface_noise, p / 3.3 + vec2(1.7, 9.2)).r;
	float tufts = texture(surface_noise, p / 0.83 + vec2(5.3, 2.1)).r;
	// Plain land: grazed grassland, yellower on dry rises, with bare earth showing through.
	vec3 green = mix(vec3(0.115, 0.185, 0.050), vec3(0.185, 0.245, 0.075), broad);
	green = mix(green, green * vec3(1.18, 1.0, 0.82), smoothstep(0.45, 0.8, region) * 0.8);
	vec3 earth = mix(vec3(0.255, 0.215, 0.125), vec3(0.335, 0.285, 0.170), patches);
	float bare = smoothstep(0.6, 0.76, patches * 0.65 + broad * 0.35);
	bare = max(bare, smoothstep(0.78, 0.9, tufts) * 0.35);
	vec3 plain = mix(green, earth, bare * 0.8);
	// Scrub: olive maquis ground, greyer and patchier.
	vec3 scrub = mix(vec3(0.140, 0.165, 0.075), vec3(0.205, 0.205, 0.105), patches);
	scrub = mix(scrub, earth, smoothstep(0.62, 0.8, clumps) * 0.5);
	// Forest floor: moss and leaf litter under the canopy.
	vec3 forest = mix(vec3(0.075, 0.120, 0.040), vec3(0.115, 0.150, 0.055), broad);
	forest = mix(forest, vec3(0.180, 0.135, 0.075), smoothstep(0.58, 0.78, clumps) * 0.55);
	vec3 colour;
	if (cover < 0.3) {
		colour = mix(plain, scrub, cover / 0.3);
	} else {
		colour = mix(scrub, forest, clamp((cover - 0.3) / 0.45, 0.0, 1.0));
	}
	// Clumped grass and fine tufts break up the flat colour at street scale.
	return colour * (0.88 + clumps * 0.16) * (0.93 + tufts * 0.12);
}

vec3 sand_colour(vec2 p) {
	float patches = texture(surface_noise, p / 11.0).r;
	float ripples = texture(surface_noise, p / 1.4 + vec2(4.2, 1.3)).r;
	return mix(vec3(0.46, 0.39, 0.26), vec3(0.56, 0.49, 0.34), patches) * (0.95 + ripples * 0.08);
}
