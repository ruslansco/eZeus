shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D fields : filter_linear, repeat_disable;
varying vec3 local_position;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float waves(vec2 p) {
	return sin(p.x*.63+p.y*.47-TIME*.6)*.015+sin(p.x*.93-p.y*.51+TIME*.8)*.008;
}
float ripples(vec2 p) {
	return sin(p.x*5.4+p.y*2.6-TIME*.9)*.008
		+sin(p.x*2.9-p.y*6.1+TIME*.7)*.004
		+(noise(p*2.3+vec2(TIME*.035,-TIME*.02))-.5)*.008;
}
void vertex() {
	local_position=VERTEX;
	VERTEX.y+=waves(VERTEX.xz);
	float dx=(waves(VERTEX.xz+vec2(.03,0))-waves(VERTEX.xz-vec2(.03,0)))/.06;
	float dz=(waves(VERTEX.xz+vec2(0,.03))-waves(VERTEX.xz-vec2(0,.03)))/.06;
	NORMAL=normalize(NORMAL+vec3(-dx,0,-dz));
}
void fragment() {
	vec2 uv=local_position.xz/vec2(32.0,28.18)+.5;
	vec4 data=texture(fields,uv);
	float within=step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
	float shallow=smoothstep(.015,.6,data.g)*within;
	vec3 sea=mix(vec3(.012,.085,.13),vec3(.055,.31,.29),shallow);
	float shore=(1.0-smoothstep(.24,.55,abs(data.b-.5)))*within;
	float foam=shore*pow(.5+.5*sin(TIME*.7+data.g*32.0+noise(local_position.xz*3.0)*2.0),5.0)*.12;
	ALBEDO=sea+foam*vec3(.65,.83,.76);
	// Surface gradients belong to the world X/Z plane, regardless of orbit.
	vec2 p=local_position.xz;
	float dx=(ripples(p+vec2(.04,0))-ripples(p-vec2(.04,0)))/.08;
	float dz=(ripples(p+vec2(0,.04))-ripples(p-vec2(0,.04)))/.08;
	NORMAL=normalize(NORMAL+(VIEW_MATRIX*vec4(-dx,0,-dz,0)).xyz);
	ROUGHNESS=mix(.30,.38,shallow);
	SPECULAR=.5;
	METALLIC=0.0;
}
