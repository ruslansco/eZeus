shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;
// A badge that floats over a marked building (scripts/building_auras.gd) and keeps a readable size at any zoom: a sickly green ringed
// cross for the plague (mode 0), a golden four-pointed star for a blessing (mode 1), a purple disc with a dark slash for a curse
// (mode 2). It faces the camera, bobs and pulses. `seed` gives each building its own phase. Cosmetic only.
instance uniform float seed = 0.0;
instance uniform float mode = 0.0;
uniform float base_size = 1.1;       // world size when close
uniform float screen_fraction = 0.042; // lower bound as a share of the distance to the camera

void vertex() {
	vec3 origin=MODEL_MATRIX[3].xyz;
	float distance_to=length(CAMERA_POSITION_WORLD-origin);
	float size=max(base_size,distance_to*screen_fraction);
	vec3 right=normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up=normalize(INV_VIEW_MATRIX[1].xyz);
	float bob=sin(TIME*2.0+seed*6.28)*.08*size;
	vec3 world=origin+right*VERTEX.x*size+up*(VERTEX.y*size+bob);
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}

float sd_box(vec2 p, vec2 b) {vec2 d=abs(p)-b;return length(max(d,0.0))+min(max(d.x,d.y),0.0);}

void fragment() {
	vec2 p=(UV-.5)*2.0;
	float pulse=.88+.12*sin(TIME*3.0+seed*6.28);
	float r=length(p);
	// Every badge is a disc with a dark edge and a light outline outside it, so it reads on pale stone and dark grass alike.
	float disc=1.0-smoothstep(.76,.8,r);
	float edge=smoothstep(.66,.7,r)*disc;
	float outline=(1.0-smoothstep(.9,.94,r))*(1.0-disc);
	vec3 fill;
	vec3 mark;
	vec3 rim;
	float symbol=0.0;
	if(mode<.5) {
		// Sickly green disc with a dark ringed cross.
		fill=mix(vec3(.55,.74,.16),vec3(.80,.92,.32),.5-.5*p.y);
		mark=vec3(.08,.12,.02);
		rim=vec3(.16,.24,.03);
		float ring=smoothstep(.40,.44,r)*(1.0-smoothstep(.5,.54,r));
		float cross=1.0-smoothstep(.0,.03,min(sd_box(p,vec2(.3,.085)),sd_box(p,vec2(.085,.3))));
		symbol=max(ring,cross);
	} else if(mode<1.5) {
		// Golden disc with a fat white four-pointed star.
		fill=mix(vec3(1.0,.62,.08),vec3(1.0,.84,.3),.5-.5*p.y);
		mark=vec3(1.0,1.0,.92);
		rim=vec3(.62,.36,.02);
		vec2 q=abs(p)*1.15;
		float star=pow(q.x,.62)+pow(q.y,.62);
		symbol=1.0-smoothstep(.93,1.0,star);
	} else {
		// Purple disc with a pale slashed X.
		fill=mix(vec3(.30,.07,.40),vec3(.58,.17,.66),.5-.5*p.y);
		mark=vec3(1.0,.62,.7);
		rim=vec3(.12,.02,.18);
		float x1=1.0-smoothstep(.0,.03,sd_box(vec2((p.x+p.y)*.7071,(p.x-p.y)*.7071),vec2(.5,.09)));
		float x2=1.0-smoothstep(.0,.03,sd_box(vec2((p.x-p.y)*.7071,(p.x+p.y)*.7071),vec2(.5,.09)));
		symbol=max(x1,x2);
	}
	vec3 colour=mix(fill,rim,edge);
	colour=mix(colour,mark,symbol*(1.0-edge));
	colour=mix(colour,vec3(1.0,1.0,.96),outline);
	ALBEDO=colour*pulse;
	ALPHA=clamp(disc+outline,0.0,1.0)*.97;
}
