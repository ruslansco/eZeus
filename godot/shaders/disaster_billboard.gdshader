shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Soft puffs that face the camera, for the disasters (scripts/disaster_effects.gd): dust over a cracking quake or a sliding hillside, the
// smoke of lava landing, the spray of a tidal wave. They grow, rise and fade over their life. Per instance: custom data (birth, life,
// rise, seed), the colour with its strength in alpha, and the size in the instance's scale. `now` is the effects' clock.
uniform float now = 0.0;
varying vec4 info;
varying vec4 tint;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	info=INSTANCE_CUSTOM;
	tint=COLOR;
	float t=clamp((now-info.x)/max(info.y,.01),0.0,1.0);
	vec3 origin=MODEL_MATRIX[3].xyz;
	float size=length(MODEL_MATRIX[0].xyz)*(1.0+t*.9);
	vec3 right=normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up=normalize(INV_VIEW_MATRIX[1].xyz);
	// The puff sits on its point rather than half buried in the ground (which would cut it in a hard line).
	vec3 world=origin+vec3(0.0,info.z*t+size*.5,0.0)+right*VERTEX.x*size+up*VERTEX.y*size;
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}

void fragment() {
	float t=(now-info.x)/max(info.y,.01);
	if(t<0.0||t>1.0) {discard;}
	vec2 p=(UV-.5)*2.0;
	float r=length(p);
	float billow=noise(p*2.4+vec2(info.w*13.0,t*1.3))*.7+noise(p*5.0+info.w*7.0)*.3;
	float body=1.0-smoothstep(.35+billow*.35,1.0,r);
	float fade=smoothstep(0.0,.12,t)*(1.0-smoothstep(.45,1.0,t));
	ALBEDO=tint.rgb*(.78+.3*billow);
	ALPHA=clamp(body*fade*tint.a,0.0,1.0);
}
