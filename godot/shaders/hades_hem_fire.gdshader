shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	float tip=1.0-UV.y;
	VERTEX.x+=sin(TIME*3.7+COLOR.r*21.0+tip*6.0)*.025*tip;
	VERTEX.z+=cos(TIME*3.1+COLOR.r*17.0+tip*7.0)*.022*tip;
}
void fragment() {
	float seed=COLOR.r*17.0;
	float y=1.0-UV.y;
	float n=noise(vec2(UV.x*5.0+seed,y*5.0-TIME*3.2));
	float center=.5+sin(y*8.0-TIME*4.0+seed)*y*.08;
	float width=min(.43,(1.0-y)*.38+n*.11);
	float fire=(1.0-smoothstep(width*.35,width,abs(UV.x-center)))*(1.0-smoothstep(.45,1.0,y+n*.18));
	float edge=smoothstep(0.0,.08,UV.x)*(1.0-smoothstep(.92,1.0,UV.x));
	ALBEDO=mix(vec3(.8,.006,.001),vec3(1.0,.19,.008),fire*fire)*1.65;
	ALPHA=fire*edge*.72;
}
