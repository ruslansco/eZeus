shader_type spatial;
render_mode cull_disabled;
varying vec3 stone_position;
void vertex() { stone_position=VERTEX; }
float grain(vec3 p) { return fract(sin(dot(floor(p),vec3(127.1,311.7,74.7)))*43758.5453); }
void fragment() {
 float pores=grain(stone_position*155.0);
 float strata=sin(stone_position.y*34.0+sin(stone_position.x*8.0)*1.7)*.018;
 float stains=sin(stone_position.x*3.7+stone_position.z*7.1)*sin(stone_position.y*2.9)*.045;
 ALBEDO=vec3(.30,.265,.19)*( .90+pores*.20)+strata+stains;
 ROUGHNESS=.88+pores*.10;
 SPECULAR=.28;
}
