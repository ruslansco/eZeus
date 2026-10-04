shader_type spatial;
render_mode cull_disabled;
uniform sampler2D surface_noise : filter_linear_mipmap, repeat_enable;
varying vec3 world_point;
varying float tint;
varying float outside_amount;
#include "res://shaders/map_outside.gdshaderinc"

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	float weight = COLOR.a * smoothstep(0.25,1.7,VERTEX.y);
	float phase = world_point.x*0.73+world_point.z*0.49+INSTANCE_CUSTOM.r*6.28;
	VERTEX.x += sin(TIME*1.15+phase)*0.014*weight;
	VERTEX.z += cos(TIME*0.91+phase)*0.009*weight;
	tint = .91+INSTANCE_CUSTOM.r*.16;
	outside_amount = map_outside(world_point.xz);
}

void fragment() {
	float grain = texture(surface_noise,world_point.xz*1.4+world_point.yy).r;
	ALBEDO = tint_outside(COLOR.rgb * tint * (.92+grain*.15), outside_amount);
	ROUGHNESS = .86;
	SPECULAR = .18;
	BACKLIGHT = COLOR.rgb * COLOR.a * .12;
}
