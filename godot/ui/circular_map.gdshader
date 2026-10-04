shader_type canvas_item;
uniform vec2 canvas_size = vec2(1280.0, 720.0);
uniform vec2 center = vec2(100.0);
uniform float radius = 96.0;
void fragment() {
	float distance_to_center = length(SCREEN_UV * canvas_size - center);
	COLOR.a *= 1.0 - smoothstep(radius - 1.0, radius, distance_to_center);
}
