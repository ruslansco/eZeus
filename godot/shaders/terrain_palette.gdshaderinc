// Shared Mediterranean ground palette for the native board (ground.gdshader) and the
// countryside around it (surroundings.gdshader), so the two meet without a seam.
// cover follows the native field: 0 plain land, 0.3 chopped forest/scrub, 0.75 forest;
// fertile meadow is a separate weight drawn with meadow_colour().
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

// Fertile land: ripening hay and wild grain, warm gold against the grazed green, with
// greener swathes, darker seed heads and a scatter of poppies and daisies.
vec3 meadow_colour(vec2 p) {
	float broad = macro_noise(p, 31.0);
	float swathes = texture(surface_noise, p / 4.1 + vec2(2.6, 8.3)).r;
	float heads = texture(surface_noise, p / 0.47 + vec2(7.1, 3.4)).r;
	float blooms = texture(surface_noise, p / 0.29 + vec2(4.4, 1.9)).r;
	vec3 hay = mix(vec3(0.300, 0.255, 0.075), vec3(0.385, 0.320, 0.105), broad);
	hay = mix(hay, vec3(0.175, 0.230, 0.060), smoothstep(0.52, 0.78, swathes) * 0.55);
	hay *= 0.86 + heads * 0.2;
	hay = mix(hay, vec3(0.200, 0.150, 0.060), smoothstep(0.72, 0.84, heads) * 0.45);
	float poppy = smoothstep(0.80, 0.84, blooms);
	float daisy = smoothstep(0.80, 0.84, 1.0 - blooms) * 0.7;
	hay = mix(hay, vec3(0.55, 0.06, 0.03), poppy * 0.75);
	return mix(hay, vec3(0.70, 0.68, 0.58), daisy * 0.6);
}

vec3 sand_colour(vec2 p) {
	float patches = texture(surface_noise, p / 11.0).r;
	float ripples = texture(surface_noise, p / 1.4 + vec2(4.2, 1.3)).r;
	return mix(vec3(0.46, 0.39, 0.26), vec3(0.56, 0.49, 0.34), patches) * (0.95 + ripples * 0.08);
}
