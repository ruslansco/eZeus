shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back, shadows_disabled;
// Soot over a burning building (scripts/building_fires.gd): a shell hugging the building's own meshes, patchy black that darkens the
// longer the fire burns (`amount`, 0..1), heaviest towards the roof where the flames are, with a dull ember glow in the thickest
// patches. Cosmetic only; the building's own materials are untouched.
uniform float amount = .3;
varying vec3 local_position;
varying vec3 world_position;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	local_position=VERTEX;
	VERTEX+=NORMAL*.012;
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}

void fragment() {
	float patch=noise(world_position.xz*2.3+world_position.y*1.7)*.6+noise(world_position.xz*6.0+world_position.y*5.0)*.4;
	float roof=smoothstep(.0,2.2,local_position.y);
	float soot=clamp(amount*(.55+.75*patch)*(.65+.5*roof),0.0,.92);
	float ember=smoothstep(.72,.95,patch)*smoothstep(.55,.9,amount)*(.5+.5*sin(TIME*3.0+world_position.x*4.0+world_position.z*3.0));
	ALBEDO=mix(vec3(.025,.02,.018),vec3(.55,.18,.04),ember*.5);
	ALPHA=soot;
}
