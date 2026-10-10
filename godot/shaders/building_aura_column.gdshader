shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// The state hanging over a marked building (scripts/building_auras.gd), a column that turns to face the camera. mode 0 is the plague:
// a sickly green miasma that billows and swirls over the roof, with flies circling in it; mode 1 a blessing: a thin golden beam of
// light with sparkles rising; mode 2 a curse: dark purple wisps with red sparks. `seed` gives each building its own phase. Cosmetic only.
instance uniform float seed = 0.0;
instance uniform float mode = 0.0;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {return noise(p)*.55+noise(p*2.1+3.1)*.3+noise(p*4.3+7.7)*.15;}

void vertex() {
	vec3 axis=MODEL_MATRIX[3].xyz;
	vec3 towards=normalize(vec3(CAMERA_POSITION_WORLD.x-axis.x,0.0,CAMERA_POSITION_WORLD.z-axis.z));
	vec3 side=normalize(cross(vec3(0.0,1.0,0.0),towards));
	vec3 world=axis+side*VERTEX.x*length(MODEL_MATRIX[0].xyz)+vec3(0.0,VERTEX.y*length(MODEL_MATRIX[1].xyz),0.0);
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}

// Specks that wander in loops through the column: x across, y up (both 0..1). Returns their coverage.
float specks(vec2 uv, float count, float speed, float radius) {
	float cover=0.0;
	for(int i=0;i<8;i++) {
		float fi=float(i);
		if(fi>=count) break;
		float h=hash(vec2(fi*3.7,seed*11.0));
		vec2 c=vec2(.5+.26*sin(TIME*speed*(.8+h)+fi*2.1+seed*9.0),.12+.62*fract(h*7.0+TIME*.05*speed)+.05*sin(TIME*speed*3.0+fi));
		float d=length((uv-c)*vec2(1.0,.55));
		cover+=1.0-smoothstep(radius*.5,radius,d);
	}
	return clamp(cover,0.0,1.0);
}

void fragment() {
	float y=1.0-UV.y;
	float t=TIME;
	if(mode<.5) {
		vec2 p=vec2(UV.x*3.0+seed*7.0,y*2.2-t*.35);
		p.x+=sin(y*4.0+t*.7+seed*6.0)*.35;
		float n=fbm(p*1.4);
		float width=.5+.1*sin(y*3.0+seed*5.0);
		float body=1.0-smoothstep(width*.3,width,abs(UV.x-.5)+(n-.5)*.34);
		float fade=smoothstep(0.0,.12,y)*(1.0-smoothstep(.55,1.0,y));
		float density=body*fade*smoothstep(.18,.7,n+.25);
		vec3 cloud=mix(vec3(.26,.34,.07),vec3(.70,.80,.24),n*.85+.1*y);
		float flies=specks(vec2(UV.x,y),6.0,1.6,.011);
		ALBEDO=mix(cloud,vec3(.05,.07,.02),flies);
		ALPHA=clamp(density*.7+flies*.85,0.0,1.0);
	} else if(mode<1.5) {
		float beam=1.0-smoothstep(0.0,.16+.08*y,abs(UV.x-.5));
		float shimmer=.65+.35*sin(y*16.0-t*2.6+seed*6.0);
		float fade=smoothstep(0.0,.06,y)*(1.0-smoothstep(.25,1.0,y));
		float sparks=specks(vec2(UV.x,y),8.0,.9,.04)*(.6+.4*sin(t*7.0+y*20.0));
		ALBEDO=mix(vec3(1.0,.84,.38),vec3(1.0,.96,.74),beam*.6+sparks);
		ALPHA=clamp(beam*fade*shimmer*.6+sparks*.9,0.0,1.0);
	} else {
		vec2 p=vec2(UV.x*3.2+seed*5.0,y*2.4-t*.5);
		p.x+=sin(y*5.0-t*.9+seed*4.0)*.4;
		float n=fbm(p*1.5);
		float width=.3+.08*sin(y*4.0+seed*3.0);
		float body=1.0-smoothstep(width*.35,width,abs(UV.x-.5)+(n-.5)*.34);
		float fade=smoothstep(0.0,.1,y)*(1.0-smoothstep(.5,1.0,y));
		float density=body*fade*smoothstep(.2,.7,n+.2);
		float sparks=specks(vec2(UV.x,y),6.0,1.8,.035)*(.5+.5*sin(t*9.0+y*15.0));
		ALBEDO=mix(mix(vec3(.10,.03,.15),vec3(.38,.10,.45),n),vec3(1.0,.25,.2),sparks);
		ALPHA=clamp(density*.8+sparks*.85,0.0,1.0);
	}
}
