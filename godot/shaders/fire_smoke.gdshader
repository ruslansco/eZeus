shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// The smoke over a burning building (scripts/building_fires.gd): a column that turns to face the camera, billowing upward and
// thinning out as it rises. `seed` sets each column's own phase; `thickness` is lower over smouldering rubble. Cosmetic only.
instance uniform float seed = 0.0;
instance uniform float thickness = 1.0;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {return noise(p)*.55+noise(p*2.1+3.1)*.3+noise(p*4.3+7.7)*.15;}
void vertex() {
	// Face the camera about the column's own vertical axis.
	vec3 axis=MODEL_MATRIX[3].xyz;
	vec3 towards=normalize(vec3(CAMERA_POSITION_WORLD.x-axis.x,0.0,CAMERA_POSITION_WORLD.z-axis.z));
	vec3 side=normalize(cross(vec3(0.0,1.0,0.0),towards));
	vec3 world=axis+side*VERTEX.x*length(MODEL_MATRIX[0].xyz)+vec3(0.0,VERTEX.y*length(MODEL_MATRIX[1].xyz),0.0);
	// The wind leans the top of the column.
	float rise=clamp(VERTEX.y/3.0,0.0,1.0);
	world.x+=rise*rise*.9;
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}
void fragment() {
	float y=1.0-UV.y;
	vec2 p=vec2(UV.x*2.2+seed*5.0,y*2.6-TIME*.55);
	float puff=fbm(p*1.6);
	float width=.18+y*.32;
	float body=1.0-smoothstep(width*.4,width,abs(UV.x-.5+(puff-.5)*.25));
	float fade=smoothstep(0.0,.12,y)*(1.0-smoothstep(.55,1.0,y));
	float density=body*fade*smoothstep(.25,.75,puff+.2);
	ALBEDO=mix(vec3(.16,.15,.14),vec3(.42,.40,.38),y*.8+puff*.2);
	ALPHA=clamp(density*.72*thickness,0.0,1.0);
}
