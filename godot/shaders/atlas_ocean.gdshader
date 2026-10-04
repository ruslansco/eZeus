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
	float shallow=smoothstep(.0,.5,data.g)*within;
	vec3 sea=mix(vec3(.006,.055,.10),vec3(.015,.20,.23),shallow);
	float shore=(1.0-smoothstep(.24,.55,abs(data.b-.5)))*within;
	float foam=shore*pow(.5+.5*sin(TIME*1.1+data.g*48.0),5.0)*.16;
	ALBEDO=sea+foam*vec3(.65,.83,.76);
	vec2 p=local_position.xz*3.1+vec2(TIME*.07,-TIME*.04);
	float chop=noise(p)*2.0-1.0;
	float cross_chop=noise(p.yx+vec2(43.0,27.0))*2.0-1.0;
	NORMAL=normalize(NORMAL+vec3(chop*.10,cross_chop*.08,0.0));
	ROUGHNESS=.24;
	SPECULAR=.65;
	METALLIC=.16;
}
