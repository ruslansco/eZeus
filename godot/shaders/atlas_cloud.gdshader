shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float seed=0.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV*vec2(5.0,3.5)+seed;
	float n=(noise(p)+noise(p*2.1)*.45+noise(p*4.2)*.16)/1.61;
	vec2 at=(UV-.5)*vec2(1.0,1.3);
	float rim=1.0-smoothstep(.12,.49,length(at));
	float density=smoothstep(.30,.68,n)*rim;
	ALBEDO=mix(vec3(.71,.79,.82),vec3(.97,.98,.97),n);
	ALPHA=density*.32;
}
