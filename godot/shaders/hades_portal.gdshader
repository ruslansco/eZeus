shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float scene_time = 0.0;
uniform sampler2D aperture_distance : filter_linear, repeat_disable;
uniform float distance_to_portal_units = 1.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float fbm(vec2 p) {
 float value=0.0, amplitude=.5;
 for(int i=0;i<4;i++) { value+=amplitude*noise(p);p=mat2(vec2(.8,.6),vec2(-.6,.8))*p*2.03;amplitude*=.49; }
 return value;
}
void fragment() {
 vec2 packed=texture(aperture_distance,UV).rg;
 float edge=(dot(packed,vec2(256.0/257.0,1.0/257.0))-.5)*distance_to_portal_units;
 if(edge<0.0) discard;
 float t=scene_time;
 vec2 p=vec2((UV.x-.5)*9.2,(1.0-UV.y)*16.2);
 // Rising domain-warped flame tongues, with a quieter hot line at the masonry.
 vec2 warp=vec2(fbm(p*.53+vec2(t*.12,-t*.62)),fbm(p*.43+vec2(4.7,-t*.46)));
 float flow=fbm(p*vec2(1.4,.62)+warp*2.5+vec2(t*.08,-t*1.15));
 float reach=.24+pow(flow,2.3)*2.5;
 float tongue=pow(clamp(1.0-edge/reach,0.0,1.0),1.25);
 float fire=tongue*(.45+flow*.95)+exp(-edge*4.8)*.14;
 vec3 green=mix(vec3(.025,.48,.008),vec3(.35,1.0,.018),clamp(fire*1.15,0.0,1.0));
 green=mix(green,vec3(.72,1.0,.26),pow(clamp(fire-.40,0.0,1.0),2.0));
 // Slow rotating, billowing depths behind the guardian, open rather than black.
 vec2 center=vec2((UV.x-.56)*1.2,(UV.y-.46)*1.65);
 float radius=length(center), angle=atan(center.y,center.x);
 vec2 swirl=vec2(cos(angle+radius*4.0-t*.11),sin(angle+radius*4.0-t*.11))*radius;
 float cloud=fbm(swirl*6.0+warp*.65+vec2(t*.07,-t*.16));
 float veil=fbm(p*.30+vec2(cloud*1.8-t*.13,t*.12));
 float core=exp(-dot(center,center)*5.0);
 vec3 depth=mix(vec3(.009,.055,.046),vec3(.10,.31,.28),cloud);
 depth+=vec3(.17,.36,.38)*core*(.48+veil*.72);
 float stream=pow(clamp(1.0-abs(sin(p.y*.47+cloud*4.0+p.x*.18-t*.44)),0.0,1.0),10.0);
 depth+=vec3(.08,.23,.18)*stream*veil*core;
 vec3 color=depth+green*fire*1.35;
 ALBEDO=color;
 EMISSION=color*.34;
 ROUGHNESS=1.0;
}
