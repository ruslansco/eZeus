shader_type spatial;
varying vec3 p;
float hash(vec2 v){return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 v){vec2 i=floor(v),f=fract(v);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){p=VERTEX;}
void fragment(){
 float grass=smoothstep(.36,.68,noise(p.xz*.10)+noise(p.xz*.42)*.2);
 vec3 earth=mix(vec3(.18,.16,.085),vec3(.065,.095,.032),grass);
 float shore=1.-smoothstep(.2,2.0,p.y);
 ALBEDO=mix(earth,vec3(.44,.36,.20),shore)*(.84+noise(p.xz*8.)*.23);
 ROUGHNESS=.96;
}
