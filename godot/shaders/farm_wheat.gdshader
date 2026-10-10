shader_type spatial;
render_mode cull_disabled;
global uniform float building_work_clock;
varying float ripeness;

void vertex() {
	ripeness = clamp(INSTANCE_CUSTOM.r, 0.0, 1.0);
	// Ears emerge late, from the stem tip; every point keeps its own authored anchor.
	if (UV.x > 0.5) {
		float ear = smoothstep(0.55, 0.82, ripeness);
		VERTEX.xz = mix(UV2, VERTEX.xz, ear);
		VERTEX.y = mix(UV.y, VERTEX.y, ear);
	}
	VERTEX.y *= mix(0.08, 1.0, pow(ripeness, 0.8));
	float tip = VERTEX.y * VERTEX.y;
	VERTEX.x += sin(building_work_clock * 0.785398 + INSTANCE_CUSTOM.g * 6.283185 + VERTEX.z * 4.0) * tip * 0.055;
	VERTEX.z += cos(building_work_clock * 0.785398 + VERTEX.x * 3.0) * tip * 0.025;
	if (ripeness < 0.001) VERTEX.y = -0.03;
}

void fragment() {
	vec3 green = vec3(0.16, 0.34, 0.055);
	vec3 gold = vec3(0.73, 0.52, 0.13);
	ALBEDO = mix(green, gold, smoothstep(0.58, 0.98, ripeness)) * COLOR.rgb;
	ROUGHNESS = 0.88;
}
