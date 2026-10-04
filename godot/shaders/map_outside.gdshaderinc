// Darkens everything outside the playable board, like unowned land in Cities: Skylines.
// map_border.gd publishes the straightened, inset border loop (world XZ) as a 1-pixel-high
// RG float texture. With no loop (count 0, e.g. headless tools), nothing is tinted.
global uniform sampler2D map_border_points;
global uniform int map_border_count;
global uniform float map_outside_tint;

float map_outside(vec2 p) {
	if (map_border_count < 3) {
		return 0.0;
	}
	bool inside = false;
	float distance = 1e9;
	vec2 a = texelFetch(map_border_points, ivec2(map_border_count - 1, 0), 0).rg;
	for (int index = 0; index < min(map_border_count, 256); index++) {
		vec2 b = texelFetch(map_border_points, ivec2(index, 0), 0).rg;
		vec2 ab = b - a;
		float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
		distance = min(distance, length(p - a - ab * t));
		if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
			inside = !inside;
		}
		a = b;
	}
	return inside ? 0.0 : smoothstep(0.0, 1.2, distance) * map_outside_tint;
}

vec3 tint_outside(vec3 colour, float amount) {
	float grey = dot(colour, vec3(0.3, 0.59, 0.11));
	return mix(colour, mix(colour, vec3(grey), 0.3) * 0.6, amount);
}
