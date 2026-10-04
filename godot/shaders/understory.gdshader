shader_type spatial;
render_mode cull_disabled;
uniform float fade_start = 42.0;
uniform float fade_end = 62.0;
varying float tint;

void vertex() {
	tint = 0.91 + INSTANCE_CUSTOM.x * 0.18;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	float breeze = sin(TIME * 1.3 + world.x * 0.45 + world.z * 0.3 + INSTANCE_CUSTOM.x * 6.28);
	VERTEX.xz += vec2(0.013,0.008) * breeze * COLOR.a;
}

void fragment() {
	float coverage = 1.0 - smoothstep(fade_start,fade_end,length(VERTEX));
	// Opaque screen-door fade avoids transparent grass layers and their sorting.
	float threshold = fract(52.9829189 * fract(dot(FRAGCOORD.xy,vec2(0.06711056,0.00583715))));
	if (coverage < threshold) discard;
	ALBEDO = COLOR.rgb * tint;
	ROUGHNESS = 0.96;
	SPECULAR = 0.10;
}
