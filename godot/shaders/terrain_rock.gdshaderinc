// Original procedural limestone. World-space projections give vertical faces
// actual texture area instead of stretching their horizontal ground UVs.
float rock_noise(vec3 point, vec3 weights, float scale) {
	return dot(vec3(texture(surface_noise, point.yz / scale + vec2(0.31, 0.71)).r,
		texture(surface_noise, point.xz / scale + vec2(0.67, 0.19)).r,
		texture(surface_noise, point.xy / scale + vec2(0.13, 0.43)).r), weights);
}

// RGB is albedo, A is small surface relief; neither displaces the native surface.
vec4 limestone_surface(vec3 point, vec3 normal) {
	vec3 weights = pow(abs(normal), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);
	float weather = rock_noise(point, weights, 3.7);
	float chips = rock_noise(point, weights, 0.95);
	float pores = rock_noise(point, weights, 0.19);
	float bedding = point.y * 3.3 + weather * 0.65 + chips * 0.10;
	float edge = abs(fract(bedding) - 0.5);
	float aa = max(fwidth(bedding), 0.008);
	float seam = (1.0 - smoothstep(0.015, 0.045 + aa, edge)) * (1.0 - smoothstep(0.15, 0.30, aa));
	float fracture = smoothstep(0.30, 0.36, chips) - smoothstep(0.36, 0.41, chips);
	vec3 stone = mix(vec3(0.32, 0.30, 0.245), vec3(0.56, 0.53, 0.445), weather * 0.55 + chips * 0.45);
	stone *= 0.94 + pores * 0.12 - seam * 0.18 - fracture * 0.11;
	float lichen = smoothstep(0.64, 0.79, weather) * smoothstep(0.40, 0.62, chips);
	stone = mix(stone, vec3(0.27, 0.30, 0.17), lichen * 0.32);
	return vec4(stone, chips * 0.014 + pores * 0.0008 - seam * 0.003);
}

vec3 limestone_normal(vec3 point, vec3 normal, float relief) {
	vec3 dx = dFdx(point);
	vec3 dy = dFdy(point);
	vec3 across_y = cross(dy, normal);
	vec3 across_x = cross(normal, dx);
	float determinant = dot(dx, across_y);
	vec3 gradient = (across_y * dFdx(relief) + across_x * dFdy(relief))
		* sign(determinant) / max(abs(determinant), 0.00001);
	return normalize(normal - gradient);
}
