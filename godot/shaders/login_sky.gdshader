shader_type sky;
uniform float scene_time = 0.0;
uniform sampler2D cloud_sky : filter_linear_mipmap;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
float fbm(vec2 p){float v=0.,a=.5;for(int i=0;i<4;i++){v+=a*noise(p);p=mat2(vec2(.8,.6),vec2(-.6,.8))*p*2.1;a*=.5;}return v;}
void sky(){
 vec3 d=normalize(EYEDIR);
 vec2 uv=vec2(atan(d.x,-d.z),asin(d.y));
 float horizon=exp(-abs(d.y)*5.0);
 vec2 panorama=vec2(atan(d.z,d.x)/6.283185+.5, acos(clamp(d.y,-1.,1.))/3.14159);
 vec3 photograph=texture(cloud_sky,panorama+vec2(.14+scene_time*.0003,0)).rgb;
 float luminosity=dot(photograph/(1.+photograph),vec3(.2126,.7152,.0722));
 vec3 col=mix(vec3(.006,.012,.023),vec3(.025,.042,.052),horizon);
 col+=vec3(.047,.062,.075)*pow(luminosity,2.0);
 float cloud=fbm(uv*4.0+vec2(scene_time*.008,0));
 float streak=fbm(uv*vec2(3.,11.)+vec2(scene_time*.014,1.7));
 float cover=smoothstep(.36,.74,cloud*.7+streak*.4);
 col=mix(col,vec3(.009,.016,.029),cover*.36);
 col+=vec3(.12,.09,.07)*pow(streak,5.0)*horizon;
 vec3 moon_dir=normalize(vec3(-.48,.50,-1.0));
 float r=length(d-moon_dir);
 float disk=1.-smoothstep(.041,.043,r);
 float eclipse=1.-smoothstep(.036,.037,length(d-normalize(moon_dir+vec3(.009,.004,0))));
 float crescent=disk*(1.-eclipse);
 float crater=.60+noise(uv*180.0)*.30+noise(uv*440.)*.10;
 col+=vec3(.38,.49,.55)*crescent*crater*(1.-cover*.5);
 col+=vec3(.10,.19,.24)*exp(-r*19.)*.35;
 vec2 cell=floor(uv*230.0); vec2 f=fract(uv*230.0)-.5;
 float star=pow(max(0.,1.-length(f)*10.),6.)*step(.994,hash(cell));
 col+=vec3(.42,.54,.66)*star*(1.-cover)*smoothstep(.1,.5,d.y);
 COLOR=col;
}
