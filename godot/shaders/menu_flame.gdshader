shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float scene_time = 0.0;
uniform float offset = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void fragment(){
 float t=scene_time+offset; float y=1.-UV.y;
 float n=noise(vec2(UV.x*5.,y*4.-t*2.7));
 float center=.5+sin(y*8.-t*3.)*y*.07;
 float width=(1.-y)*.36+n*.16;
 float fire=smoothstep(width,0.,abs(UV.x-center))*smoothstep(1.,.25,y+n*.18);
 ALBEDO=mix(vec3(1.,.08,.005),vec3(1.,.64,.16),pow(fire,2.))*2.3;
 ALPHA=fire;
}
