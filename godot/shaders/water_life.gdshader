shader_type spatial;
render_mode cull_disabled;
uniform float life_clock = 0.0;
uniform bool swimming = false;
varying vec4 detail;
void vertex() {
 detail = INSTANCE_CUSTOM;
 if (swimming) {
  float t = life_clock * 0.85 + INSTANCE_CUSTOM.x * 6.283185;
  VERTEX.z += sin(life_clock * 9.0 + VERTEX.x * 22.0 + INSTANCE_CUSTOM.x * 6.283185) * .018 * smoothstep(0.0, .16, VERTEX.x);
  mat2 turn = mat2(vec2(-cos(t), sin(t)), vec2(-sin(t), -cos(t)));
  NORMAL.xz = turn * NORMAL.xz;
  VERTEX.xz = turn * VERTEX.xz + vec2(sin(t), cos(t)) * .09;
 }
}
void fragment() {
 ALBEDO = COLOR.rgb;
 ROUGHNESS = .48;
 SPECULAR = .35;
}
