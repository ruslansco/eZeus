shader_type spatial;
render_mode cull_disabled;
instance uniform vec4 allegiance : source_color = vec4(.9,.7,.3,1);
void vertex() {
	if(UV.y>1.0) VERTEX.z+=sin(TIME*2.6+VERTEX.x*12.0)*.045*UV.x;
}
void fragment() {
	ALBEDO=COLOR.rgb;
	if(COLOR.a<.5) ALBEDO=allegiance.rgb;
	ROUGHNESS=COLOR.a<.5?.48:.84;
	METALLIC=COLOR.a<.5?.35:0.0;
}
