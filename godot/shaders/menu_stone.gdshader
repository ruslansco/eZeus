shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_rough : filter_linear_mipmap, repeat_enable;
uniform vec4 base_color : source_color = vec4(.30,.29,.27,1);
uniform float scale_value = .3;
uniform float normal_strength = .25;
uniform float palette_strength = 1.0;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 w=pow(abs(world_normal),vec3(4.));w/=w.x+w.y+w.z;
 vec3 p=world_pos*scale_value;
 vec3 tex=texture(stone_color,p.zy).rgb*w.x+texture(stone_color,p.xz).rgb*w.y+texture(stone_color,p.xy).rgb*w.z;
 float lum=dot(tex,vec3(.2126,.7152,.0722));
 // Limestone keeps a consistent finish; the scan contributes pores and wear.
 float pores=mix(.52,1.20,smoothstep(.025,.45,lum));
 float weather=.93+.07*sin(world_pos.y*2.8+lum*2.);
 ALBEDO=base_color.rgb*pores*weather*mix(vec3(1.),COLOR.rgb,palette_strength);
 float rough=texture(stone_rough,p.zy).r*w.x+texture(stone_rough,p.xz).r*w.y+texture(stone_rough,p.xy).r*w.z;
 float wet=(1.-smoothstep(.0,.6,world_pos.y))*smoothstep(.2,.7,lum);
 ROUGHNESS=mix(.80+rough*.16,.43,wet); METALLIC=0.; SPECULAR=.28;
 vec3 nx=texture(stone_normal,p.zy).rgb*2.-1.;
 vec3 ny=texture(stone_normal,p.xz).rgb*2.-1.;
 vec3 nz=texture(stone_normal,p.xy).rgb*2.-1.;
 vec3 perturb=vec3(nx.z*sign(world_normal.x),nx.y,nx.x)*w.x+vec3(ny.x,ny.z*sign(world_normal.y),ny.y)*w.y+vec3(nz.x,nz.y,nz.z*sign(world_normal.z))*w.z;
 vec3 n=normalize(mix(world_normal,normalize(perturb),normal_strength));
 NORMAL=normalize((VIEW_MATRIX*vec4(n,0.)).xyz);
}
