shader_type spatial;
render_mode cull_disabled;
uniform float scene_time = 0.0;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float t=scene_time;
 vec2 p=world_pos.xz;
 float w=sin(p.x*2.1+p.y*.7+t*.6)*.55+sin(p.y*3.4-p.x*.4-t*.8)*.3;
 vec3 n=vec3(cos(p.x*2.1+p.y*.7+t*.6)*.09,1.,cos(p.y*3.4-p.x*.4-t*.8)*.07);
 NORMAL=normalize((VIEW_MATRIX*vec4(n,0.)).xyz);
 float path=exp(-pow((p.x-5.5)/3.2,2.))*exp(-abs(p.y+3.)*.055);
 float ripple=.55+.45*sin(p.y*8.0+w*2.5+t);
 ALBEDO=vec3(.015,.028,.035);
 EMISSION=vec3(.50,.11,.025)*path*ripple*.14;
 METALLIC=.45; ROUGHNESS=.22;
}
