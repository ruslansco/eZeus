shader_type spatial;
// Finish for baked-pose walkers and animals that have no custom character shader: the
// imported StandardMaterial3D's vertex-colour albedo, burley diffuse and per-part
// roughness/metal, with the pose lookup from walker_vat.gdshaderinc.
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
#include "res://shaders/walker_vat.gdshaderinc"

uniform float roughness_value = 0.85;
uniform float metallic_value = 0.0;
uniform float specular_value = 0.5;

void vertex() {
	VERTEX = vat_apply(VERTEX, CUSTOM0.xy);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	SPECULAR = specular_value;
}
