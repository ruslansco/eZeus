uniform sampler2D terrain_data : filter_linear, repeat_disable;
uniform sampler2D surface_noise : filter_linear_mipmap, repeat_enable;
uniform vec2 map_extent = vec2(32.0);
varying vec2 world_xz;

vec2 map_uv(vec2 point) {
	return (vec2(point.x, -point.y) + map_extent * 0.5) / map_extent;
}

float coast_distance(vec2 point) {
	// A continuous field from the native water mask, never an extracted sprite.
	// The centre plus a small diagonal low-pass (five bilinear taps) smooths the zigzag
	// that staircase coasts leave in the field; too narrow to close one-tile channels.
	vec2 o = vec2(0.6, 0.6);
	float spread = texture(terrain_data, map_uv(point + o)).r + texture(terrain_data, map_uv(point - o)).r
		+ texture(terrain_data, map_uv(point + vec2(o.x, -o.y))).r + texture(terrain_data, map_uv(point - vec2(o.x, -o.y))).r;
	float distance = texture(terrain_data, map_uv(point)).r * 0.5 + spread * 0.125;
	// Two scales of irregularity: coves and spits, then a fine ragged edge.
	float irregularity = (texture(surface_noise, point / 9.0 + vec2(0.37, 0.61)).r - 0.5) * 0.22
		+ (texture(surface_noise, point / 2.7).r - 0.5) * 0.08;
	return distance + irregularity * (1.0 - smoothstep(0.0, 1.0, abs(distance)));
}
