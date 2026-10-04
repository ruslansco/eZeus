shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
// A brazier's flame: tongues of fire that sway and flicker. `burn` (per instance) is 0 for the resting flame of an altar and 1 while a
// rite is on it: the tongues grow taller and brighter. COLOR.r is the tongue's own number (its phase). Cosmetic only.
instance uniform float burn = 0.0;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	float tip=1.0-UV.y;
	float lean=.025+.03*burn;
	VERTEX.x+=sin(TIME*4.3+COLOR.r*21.0+tip*6.0)*lean*tip;
	VERTEX.z+=cos(TIME*3.7+COLOR.r*17.0+tip*7.0)*lean*tip;
	VERTEX.y*=1.0+.55*burn+.12*sin(TIME*7.0+COLOR.r*13.0)*tip;
}
void fragment() {
	float seed=COLOR.r*17.0;
	float y=1.0-UV.y;
	float n=noise(vec2(UV.x*5.0+seed,y*5.0-TIME*3.6));
	float center=.5+sin(y*8.0-TIME*4.5+seed)*y*.08;
	float width=min(.43,(1.0-y)*.38+n*.12);
	float fire=(1.0-smoothstep(width*.35,width,abs(UV.x-center)))*(1.0-smoothstep(.45,1.0,y+n*.18));
	float edge=smoothstep(0.0,.08,UV.x)*(1.0-smoothstep(.92,1.0,UV.x));
	vec3 hot=vec3(1.0,.62,.12), cool=vec3(.95,.20,.02);
	ALBEDO=mix(cool,hot,fire*fire)*(1.5+.7*burn);
	ALPHA=fire*edge*(.62+.25*burn);
}
