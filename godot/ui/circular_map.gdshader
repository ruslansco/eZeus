shader_type canvas_item;

varying vec2 canvas_pos;

uniform vec2 center = vec2(100.0, 100.0);
uniform float radius = 96.0;

void vertex() {
	canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float distance_to_center = length(canvas_pos - center);
	COLOR.a *= 1.0 - smoothstep(radius - 0.75, radius, distance_to_center);
}
