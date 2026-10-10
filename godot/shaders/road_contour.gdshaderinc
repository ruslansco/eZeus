// Bilinear road data rounds an inside bend .207 tile into a square plot.
// Keep that curve inside the existing building setback, including the .075
// minimum clearance of a one-tile plot surrounded by roads. Evaluate the same
// plot distance on BOTH sides of each tile border so the kerb is one contour.
// Straight widths and convex outside corners retain their original contour.
uniform float road_inner_radius = 0.18;

float road_contour(vec2 uv, float blended) {
	if (road_inner_radius <= 0.0) {
		return blended;
	}
	vec2 grid = uv * map_extent;
	ivec2 base = ivec2(floor(grid - vec2(0.5)));
	float contour = blended;
	// The four texels supporting the bilinear field contain every plot close
	// enough to affect it. A discarded plot is at least .5 tile away, so its
	// distance cannot lower the [0,1] mask when the support changes.
	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			ivec2 cell = base + ivec2(x, y);
			ivec2 pixel = clamp(cell, ivec2(0), ivec2(map_extent) - ivec2(1));
			if (texelFetch(road_data, pixel, 0).r < 0.5) {
				vec2 q = abs(grid - vec2(cell) - vec2(0.5)) - vec2(0.5 - road_inner_radius);
				float plot_distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - road_inner_radius;
				contour = min(contour, 0.5 + plot_distance);
			}
		}
	}
	return contour;
}
