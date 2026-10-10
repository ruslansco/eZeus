shader_type spatial;
uniform vec4 tint : source_color = vec4(.7,.65,.5,1.);
uniform float masonry = 0.;
varying vec3 local_pos;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local_pos=VERTEX;}
void fragment(){
 float n=noise(local_pos*3.0)*.55+noise(local_pos*18.)*.30+noise(local_pos*60.)*.15;
 float course=1.-smoothstep(.01,.035,abs(fract(local_pos.y*1.4)-.5));
 ALBEDO=tint.rgb*(.78+n*.30)*(1.-course*.13*masonry)*COLOR.rgb;
 ROUGHNESS=.84;
}
