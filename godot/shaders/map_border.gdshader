shader_type spatial;
// Dashed playable-area border (in the manner of Cities: Skylines). UV.x is -1/+1 across
// the ribbon, UV.y the distance along the edge in tiles, UV2 the across axis in world XZ.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 colour : source_color = vec4(1.0, 1.0, 1.0, 0.78);
uniform float period = 3.4;
uniform float duty = 0.62;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float distance = length(CAMERA_POSITION_WORLD - world);
	// Constant on-screen weight: about 0.3 tiles close up, widening when zoomed out.
	float half_width = clamp(distance * 0.0032, 0.13, 1.1);
	VERTEX.xz += UV2 * UV.x * half_width;
	VERTEX.y += distance * 0.0006;
}

void fragment() {
	float along = fract(UV.y / period);
	float edge = fwidth(UV.y / period) * 1.5 + 0.002;
	float dash = smoothstep(0.0, edge, along) * (1.0 - smoothstep(duty - edge, duty, along));
	float across = 1.0 - smoothstep(0.55, 1.0, abs(UV.x));
	ALBEDO = colour.rgb;
	ALPHA = colour.a * dash * across;
}
