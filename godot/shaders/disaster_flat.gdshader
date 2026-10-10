shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Flat effects lying on the ground or the water for the disasters (scripts/disaster_effects.gd). mode 0 is the tidal wave's surf: a
// crest of white foam that sweeps across a tile along the wave's direction (the instance's own turn) and thins out; mode 1 is the glow
// where a lava blob lands. Per instance: custom data (birth, life, seed, unused) and colour (tint, strength). `now` is the effects' clock.
uniform float now = 0.0;
uniform int mode = 0;
varying vec4 info;
varying vec4 tint;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	info=INSTANCE_CUSTOM;
	tint=COLOR;
}

void fragment() {
	float t=(now-info.x)/max(info.y,.01);
	if(t<0.0||t>1.0) {discard;}
	vec2 p=(UV-.5)*2.0;
	if(mode==0) {
		// The crest runs from -x to +x of the instance (its turn aims +x along the wave).
		float crest=mix(-1.5,1.5,t);
		float wobble=noise(vec2(p.y*3.0+info.z*9.0,t*2.0))*.5;
		float d=p.x-crest-wobble*.35;
		float band=exp(-d*d*3.2);
		float lace=smoothstep(.35,.7,noise(p*5.0+vec2(-t*3.0,info.z*7.0)));
		float trail=smoothstep(0.0,-1.2,d)*.35*smoothstep(.2,.7,noise(p*3.0+vec2(info.z*5.0,t)));
		float edge=1.0-smoothstep(.75,1.0,max(abs(p.x),abs(p.y)));
		float strength=(band*(.55+.45*lace)+trail)*edge*(1.0-t*t);
		ALBEDO=mix(vec3(.82,.93,.97),vec3(1.0),band);
		ALPHA=clamp(strength*tint.a,0.0,1.0);
	} else {
		float r=length(p);
		float glow=pow(1.0-smoothstep(0.0,1.0,r),2.0)*(1.0-t);
		ALBEDO=mix(tint.rgb,vec3(1.0,.9,.5),glow*.6);
		ALPHA=clamp(glow*tint.a,0.0,1.0);
	}
}
