shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D fields : filter_linear, repeat_disable;
varying vec3 local_position;
void vertex() { local_position=VERTEX; }
void fragment() {
	vec4 data=texture(fields,UV);
	float height=data.r*3.6;
	float detail=1.0-smoothstep(.015,.045,length(fwidth(local_position.xz)));
	float grain=sin(local_position.x*57.0+sin(local_position.z*31.0))*sin(local_position.z*43.0)*.003*detail;
	vec3 olive=mix(vec3(.055,.12,.025),vec3(.17,.21,.07),data.a);
	vec3 earth=mix(olive,vec3(.29,.24,.14),smoothstep(.5,1.5,height));
	earth=mix(earth,vec3(.45,.40,.29),smoothstep(1.1,2.0,height));
	vec3 world_normal=normalize((INV_VIEW_MATRIX*vec4(NORMAL,0.0)).xyz);
	float rock=clamp((1.0-world_normal.y)*2.5,0.0,.6);
	earth=mix(earth,vec3(.36,.33,.25),rock);
	earth=mix(earth,vec3(.75,.73,.63),smoothstep(2.2,3.0,height));
	earth=mix(vec3(.48,.39,.22),earth,smoothstep(.48,.83,data.b));
	// Broad cloud shadows move over the relief independently of game time.
	float cloud=sin(UV.x*20.0-TIME*.035)*sin(UV.y*17.0+TIME*.025);
	ALBEDO=(earth+grain)*(1.0-smoothstep(.2,.75,cloud)*.12);
	ROUGHNESS=.92;
	SPECULAR=.19;
}
