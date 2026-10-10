shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// A glow on the ground around a marked building (scripts/building_auras.gd): a mottled, pulsing sickly-green stain for the plague
// (readable from far away), a ring of golden light for a blessing, a bruised purple one for a curse. Cosmetic only.
instance uniform float seed = 0.0;
instance uniform float mode = 0.0;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {return noise(p)*.55+noise(p*2.1+3.1)*.3+noise(p*4.3+7.7)*.15;}

void fragment() {
	vec2 q=UV*2.0-1.0;
	float r=length(q);
	float edge=1.0-smoothstep(.82,1.0,r);
	float pulse=.5+.5*sin(TIME*1.8+seed*6.0);
	float ring=smoothstep(.5,.78,r)*(1.0-smoothstep(.84,1.0,r));
	float mottle=fbm(q*3.2+seed*5.0+vec2(TIME*.08,-TIME*.05));
	if(mode<.5) {
		float stain=edge*(.32+.4*smoothstep(.25,.75,mottle));
		float rim=ring*(.35+.35*pulse);
		ALBEDO=mix(vec3(.18,.26,.05),vec3(.62,.78,.20),mottle*.7+rim);
		ALPHA=clamp(stain+rim,0.0,1.0)*.8;
	} else if(mode<1.5) {
		float glow=edge*.3*(1.0-r*.5);
		ALBEDO=mix(vec3(1.0,.66,.12),vec3(1.0,.93,.6),ring);
		ALPHA=clamp(glow+ring*(.6+.3*pulse),0.0,1.0)*.9;
	} else {
		float stain=edge*(.16+.26*smoothstep(.25,.75,mottle));
		ALBEDO=mix(vec3(.12,.03,.18),vec3(.46,.14,.52),mottle*.6+ring*.5);
		ALPHA=clamp(stain*1.3+ring*(.45+.3*pulse),0.0,1.0)*.85;
	}
}
