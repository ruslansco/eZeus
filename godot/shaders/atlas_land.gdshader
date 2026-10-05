shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D fields : filter_linear, repeat_disable;
varying vec3 local_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_position=VERTEX; }
void fragment() {
	vec4 data=texture(fields,UV);
	// The relief grid contains submerged vertices for continuous coast normals.
	// They must never draw (or cast rectangular shadows) in the open ocean.
	if (data.b < .5) { discard; }
	float height=data.r*3.6;
	float detail=1.0-smoothstep(.015,.045,length(fwidth(local_position.xz)));
	vec2 p=local_position.xz;
	float weather=noise(p*2.7)*.55+noise(p*8.1)*.3+noise(p*24.3)*.15;
	float grain=(noise(p*75.0)-.5)*.025*detail;
	vec3 olive=mix(vec3(.09,.18,.065),vec3(.23,.29,.13),data.a*.65+weather*.35);
	vec3 earth=mix(olive,vec3(.32,.30,.22),smoothstep(.65,1.6,height));
	earth=mix(earth,vec3(.48,.46,.39),smoothstep(1.1,2.1,height));
	vec3 world_normal=normalize((INV_VIEW_MATRIX*vec4(NORMAL,0.0)).xyz);
	float rock=smoothstep(.18,.65,1.0-world_normal.y);
	vec3 limestone=mix(vec3(.29,.31,.29),vec3(.60,.58,.50),weather);
	float strata=sin(p.y*9.0+height*42.0+weather*4.0)*.018;
	earth=mix(earth,limestone+strata,rock*.8);
	earth=mix(earth,limestone,smoothstep(2.0,3.0,height)*.7);
	earth=mix(vec3(.55,.49,.35),earth,smoothstep(.5,.92,data.b));
	// Broad cloud shadows move over the relief independently of game time.
	float cloud=sin(UV.x*20.0-TIME*.035)*sin(UV.y*17.0+TIME*.025);
	ALBEDO=(earth+grain)*(1.0-smoothstep(.2,.75,cloud)*.12);
	ROUGHNESS=.92;
	SPECULAR=.19;
}
