shader_type spatial;
render_mode cull_disabled;
uniform float scene_time = 0.;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world_pos.xz; float t=scene_time;
 float a=p.x*.8+p.y*.33+t*.5; float b=p.y*1.7-p.x*.25-t*.35;
 vec3 n=normalize(vec3(cos(a)*.075,1.,cos(b)*.055));
 NORMAL=normalize((VIEW_MATRIX*vec4(n,0.)).xyz);
 ALBEDO=mix(vec3(.008,.07,.13),vec3(.018,.16,.20),.5+.5*sin(p.y*.02));
 METALLIC=.12; ROUGHNESS=.31;
}
