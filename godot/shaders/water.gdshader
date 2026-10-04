shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/terrain_common.gdshaderinc"
#include "res://shaders/map_outside.gdshaderinc"
#include "res://shaders/water_surface.gdshaderinc"

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float shore = coast_distance(world_xz);
	if (shore < 0.0) {
		discard;
	}
	vec3 albedo;
	float roughness;
	float foam;
	vec3 normal = water_surface(world_xz, shore, TIME, albedo, roughness, foam);
	ALBEDO = tint_outside(albedo, map_outside(world_xz));
	NORMAL = normalize(mat3(VIEW_MATRIX) * normal);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
