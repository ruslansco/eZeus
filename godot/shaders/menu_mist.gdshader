shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float scene_time = 0.0;
uniform vec4 tint : source_color = vec4(.18,.25,.28,.13);
uniform float offset = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*vec2(7.,2.)+vec2(scene_time*.025+offset,0);
 float n=noise(p)*.65+noise(p*2.1)*.35;
 float mask=pow(sin(UV.x*3.14159)*sin(UV.y*3.14159),1.5);
 ALBEDO=tint.rgb; ALPHA=smoothstep(.20,.80,n)*mask*tint.a;
}
