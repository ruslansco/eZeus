shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never;
uniform float scene_time=0.0;
uniform sampler2D aperture_distance : filter_linear, repeat_disable;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void fragment() {
 vec2 packed=texture(aperture_distance,UV).rg;
 float edge=dot(packed,vec2(256.0/257.0,1.0/257.0))-.5;
 float t=scene_time;
 float fog=noise(UV*vec2(8,22)+vec2(t*.17,-t*.18));
 fog=mix(fog,noise(UV*vec2(19,45)+vec2(-t*.20,t*.14)),.30);
 float feet=smoothstep(.60,.96,UV.y);
 ALBEDO=vec3(.12,.40,.24);
 EMISSION=vec3(.07,.21,.11);
 ALPHA=smoothstep(0.0,.02,edge)*feet*pow(fog,1.7)*.58;
}
