shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// A dark opening with moving depths; the fire is confined to its stone threshold.
uniform float scene_time = 0.0;
uniform vec3 ember_color : source_color = vec3(1.0, 0.24, 0.028);
uniform vec3 soul_color : source_color = vec3(0.14, 0.48, 0.46);
// Optional source-image calibration; older procedural doorway meshes keep the arch.
uniform bool registered_aperture = false;
uniform sampler2D aperture_distance : filter_linear, repeat_disable;
uniform float distance_to_portal_units = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float fbm(vec2 p) {
 float v=0.0, a=0.5;
 for(int i=0;i<4;i++){v+=a*noise(p);p=mat2(vec2(.8,.6),vec2(-.6,.8))*p*2.03;a*=.49;}
 return v;
}
void fragment() {
 vec2 p=vec2((UV.x-.5)*9.2, (1.0-UV.y)*16.2);
 // Arch spring at 11.6, radius 4.6. Signed distance includes straight jambs.
 float edge=min(4.6-abs(p.x), p.y < 11.6 ? p.y : 4.6-length(p-vec2(0,11.6)));
 if(registered_aperture) {
  vec2 packed=texture(aperture_distance,UV).rg;
  float distance=dot(packed,vec2(256.0/257.0,1.0/257.0));
  edge=(distance-.5)*distance_to_portal_units;
 }
 if(edge<0.0) discard;
 float t=scene_time;
 vec2 q=vec2(fbm(p*.34+vec2(t*.09,-t*.17)),fbm(p*.29+vec2(3.4,-t*.12)));
 float cloud=fbm(p*.47+q*3.0+vec2(0,-t*.24));
 float fire=exp(-edge*(3.2+cloud*3.0));
 float tongues=pow(fbm(vec2(p.x*1.9,p.y*.65-t*.85)+q*2.0),3.0);
 fire+=exp(-edge*1.4)*tongues*1.8;
 fire*=.60+cloud*.75;
 float vault=pow(clamp(cloud,0.0,1.0),3.0);
 vec3 depth=mix(vec3(.004,.009,.012),soul_color*.10,vault);
 float veins=pow(max(0.0,1.0-abs(sin(p.y*.65+q.x*6.0+p.x*.45-t*.2))),18.0)*vault;
 depth+=soul_color*veins*.17;
 vec3 hot=mix(ember_color,vec3(1.0,.65,.19),clamp(fire-.4,0.0,1.0));
 ALBEDO=depth+hot*fire*(2.5+.4*sin(t*2.1));
 EMISSION=depth*.3+hot*fire*(2.5+.4*sin(t*2.1));
 ROUGHNESS=1.0;
}
