shader_type sky;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void sky(){
 float h=max(EYEDIR.y,0.);
 vec3 col=mix(vec3(.30,.42,.48),vec3(.055,.18,.36),smoothstep(0.,.75,h));
 vec2 p=EYEDIR.xz/(max(EYEDIR.y,.03)+.22)*2.;
 float cloud=noise(p*2.)*.55+noise(p*4.1)*.27+noise(p*8.3)*.13;
 float mask=smoothstep(.50,.72,cloud)*smoothstep(.02,.18,h);
 col=mix(col,vec3(.67,.60,.45),mask*.73);
 float sun=dot(EYEDIR,normalize(vec3(-.52,.30,-.8)));
 col+=vec3(1.,.73,.36)*pow(max(sun,0.),32.)*.32;
 col+=vec3(1.,.85,.58)*smoothstep(.9995,.99985,sun)*2.;
 COLOR=col;
}
