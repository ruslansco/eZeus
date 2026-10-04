shader_type canvas_item;
render_mode unshaded;
uniform float flight = 0.0;
uniform float amount = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1)), f.x), f.y);
}
void fragment() {
	// Soft cloud wisps rush outward as altitude increases. Both real 3D scenes
	// remain visible through this temporary veil; no frozen screenshot is used.
	vec2 uv = (UV - .5) * (4.8 - flight * 2.7);
	uv += vec2(flight * .7, flight * 1.5);
	float n = noise(uv * 3.0) * .57 + noise(uv * 6.1) * .28 + noise(uv * 12.3) * .15;
	float cloud = smoothstep(.32, .75, n);
	float edge = smoothstep(.12, .70, length(UV - .5));
	COLOR = vec4(mix(vec3(.20,.37,.48), vec3(.74,.85,.88), cloud), amount * (cloud * .48 + edge * .12));
}
