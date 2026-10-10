shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float surface_roughness=.85;
uniform float surface_metallic=0.0;
uniform vec4 base_colour : source_color=vec4(1.0);
varying vec3 rest_position;
varying float world_height;
varying flat float construction_active;
varying flat float construction_top;
void vertex() {
	rest_position=VERTEX;
	world_height=(MODEL_MATRIX*vec4(VERTEX,1.0)).y;
	construction_active=INSTANCE_CUSTOM.b;
	construction_top=INSTANCE_CUSTOM.a;
}
void fragment() {
	if(construction_active>.5 && world_height>construction_top) discard;
	vec3 original=COLOR.rgb*base_colour.rgb;
	float high=max(original.r,max(original.g,original.b));
	float low=min(original.r,min(original.g,original.b));
	float stone=smoothstep(.30,.55,low)*(1.0-smoothstep(.16,.29,high-low))*(1.0-step(.01,surface_metallic));
	vec3 p=rest_position;
	float detail=1.0-smoothstep(.018,.07,length(fwidth(p)));
	float veins=sin(p.x*3.1+p.y*1.8+p.z*2.3+sin(p.y*7.0+p.z*3.0)*.3);
	float fleck=sin(p.x*47.0+p.y*31.0)*sin(p.z*53.0-p.y*13.0)*.5;
	ALBEDO=original*(1.0+stone*detail*(veins*.016+fleck*.022));
	ROUGHNESS=mix(surface_roughness,.72+fleck*.04,stone*detail);
	METALLIC=surface_metallic;
}
