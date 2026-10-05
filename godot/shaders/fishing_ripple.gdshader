shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float life_clock = 0.0;
varying vec4 detail;
void vertex() { detail = INSTANCE_CUSTOM; }
void fragment() {
 float r = length(UV - vec2(.5)) * 2.0;
 float phase = fract(life_clock * .6 + detail.x);
 float ring = (1.0-smoothstep(.012,.045,abs(r-(.18+phase*.72))))*(1.0-phase);
 
 ALBEDO = vec3(.61,.86,.81);
 if (detail.y > .5) {
  // Broken surface glints when hands/net enter the water. No diagram rings.
  vec2 p = UV - vec2(.5);
  float cycle = detail.z;
  float pulse = exp(-pow((cycle-.22)*18.0,2.0)) + .55*exp(-pow((cycle-.56)*18.0,2.0));
  float flecks = smoothstep(.78,.98,sin(p.x*111.0+detail.x*19.0)*sin(p.y*97.0-life_clock*2.0));
  ALBEDO = vec3(.50,.73,.71);
  ALPHA = flecks * exp(-dot(p,p)*38.0) * (.025+.24*pulse);
 } else {
 float breakup = .55+.45*sin(UV.x*47.0+UV.y*39.0+detail.x*6.283185);
 ALPHA = ring * .12 * (.35+.65*breakup) * (1.0-smoothstep(.9,1.0,r));
 }
}
