shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
// A burning building's flames (scripts/building_fires.gd): tongues of fire that sway, leap and flicker, after the altar's flame
// (ritual_flame.gdshader) but larger and wilder. COLOR.r is the tongue's own number (its phase); `seed` keeps neighbouring fires
// out of step. Cosmetic only.
instance uniform float seed = 0.0;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	float tip=1.0-UV.y;
	float phase=COLOR.r*21.0+seed*7.0;
	VERTEX.x+=sin(TIME*5.1+phase+tip*5.0)*.09*tip;
	VERTEX.z+=cos(TIME*4.4+phase*.8+tip*6.0)*.09*tip;
	VERTEX.y*=1.0+.25*sin(TIME*6.3+phase)*tip+.15*sin(TIME*11.0+phase*1.7)*tip;
}
void fragment() {
	float s=COLOR.r*17.0+seed*3.0;
	float y=1.0-UV.y;
	float n=noise(vec2(UV.x*4.0+s,y*4.0-TIME*4.2));
	float m=noise(vec2(UV.x*9.0-s,y*9.0-TIME*6.0));
	float center=.5+sin(y*7.0-TIME*5.0+s)*y*.1;
	float width=min(.46,(1.0-y)*.42+n*.14);
	float fire=(1.0-smoothstep(width*.3,width,abs(UV.x-center)))*(1.0-smoothstep(.35,1.0,y+n*.25+m*.1));
	float edge=smoothstep(0.0,.08,UV.x)*(1.0-smoothstep(.92,1.0,UV.x));
	vec3 core=vec3(1.0,.86,.42), hot=vec3(1.0,.52,.10), cool=vec3(.85,.16,.02);
	vec3 colour=mix(cool,hot,smoothstep(.1,.6,fire));
	colour=mix(colour,core,smoothstep(.65,1.0,fire)*(1.0-y));
	ALBEDO=colour*1.2;
	ALPHA=fire*edge*.6;
}
