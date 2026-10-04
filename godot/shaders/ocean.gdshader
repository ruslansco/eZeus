shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/terrain_common.gdshaderinc"
#include "res://shaders/map_outside.gdshaderinc"
#include "res://shaders/water_surface.gdshaderinc"
uniform sampler2D native_mask : filter_nearest, repeat_disable;
uniform sampler2D scenery_data : filter_linear, repeat_disable;
uniform vec2 scenery_origin;
uniform float scenery_size=1024.0;
uniform float field_width=129.0;
void vertex(){world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 vec2 uv=map_uv(world_xz);
 bool inside=all(greaterThanEqual(uv,vec2(0.0)))&&all(lessThanEqual(uv,vec2(1.0)))&&texture(native_mask,uv).r>.5;
 float shore=inside?coast_distance(world_xz):8.0;
 if(!inside){
  vec2 field_uv=(vec2(world_xz.x,-world_xz.y)-scenery_origin)/scenery_size;
  vec4 outside=texture(scenery_data,(field_uv*(field_width-1.0)+.5)/field_width);
  // Level land continues across its cut edge without a thin ocean band over it.
  if(outside.r>.55&&outside.a<35.0){discard;}
 }
 if(shore<0.0){discard;}
 vec3 albedo;float roughness;float foam;
 vec3 normal=water_surface(world_xz,shore,TIME,albedo,roughness,foam);
 ALBEDO=tint_outside(albedo,map_outside(world_xz));
 NORMAL=normalize(mat3(VIEW_MATRIX)*normal);ROUGHNESS=roughness;METALLIC=0.0;SPECULAR=.5;
}
