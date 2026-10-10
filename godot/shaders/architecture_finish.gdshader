shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float surface_roughness = .85;
uniform vec4 base_colour : source_color = vec4(1.0);
varying vec3 rest_position;
void vertex() { rest_position=VERTEX; }
void fragment() {
	vec3 original=COLOR.rgb*base_colour.rgb;
	float high=max(original.r,max(original.g,original.b));
	float low=min(original.r,min(original.g,original.b));
	// Pale, low-chroma architectural stone/plaster only. Roofs, plants, timber
	// and saturated decoration retain their authored palette and roughness.
	float stone=smoothstep(.30,.55,low)*(1.0-smoothstep(.16,.29,high-low));
	vec3 p=rest_position;
	float detail=1.0-smoothstep(.018,.07,length(fwidth(p)));
	float veins=sin(p.x*3.1+p.y*1.8+p.z*2.3+sin(p.y*7.0+p.z*3.0)*.3);
	// Continuous grain stays below the visible pixel frequency; no hash-cell shimmer.
	float fleck=sin(p.x*47.0+p.y*31.0)*sin(p.z*53.0-p.y*13.0)*.5;
	float relief=stone*detail*(veins*.016+fleck*.022);
	ALBEDO=original*(1.0+relief);
	ROUGHNESS=mix(surface_roughness,.72+fleck*.04,stone*detail);
	METALLIC=0.0;
}
