shader_type spatial;
render_mode unshaded, blend_mix, cull_back, shadows_disabled;
// Things that fly or fall for the disasters (scripts/disaster_effects.gd). mode 0 is a lava blob thrown in an arc, glowing; mode 1 a rock thrown in an arc (a landslide's tumbling stones); mode 2 a rock dropping straight down
// (an earthquake's falling stone). The instance sits where it lands; custom data is (dx, dz, birth, seed): it began that far back, so a
// blob flies from (-dx, -dz) to the instance. `life` and `arc` are the flight's time and height. Hidden outside its flight.
uniform float now = 0.0;
uniform int mode = 0;
uniform float life = 0.8;
uniform float arc = 1.8;
uniform vec3 light_dir = vec3(.4,.8,.5);
varying vec4 info;
varying float flight;

void vertex() {
	info=INSTANCE_CUSTOM;
	flight=(now-info.z)/life;
	vec3 offset;
	if(mode==2) {
		offset=vec3(0.0,arc*(1.0-flight*flight),0.0);
	} else {
		float rest=1.0-flight;
		offset=vec3(-info.x*rest,arc*4.0*flight*rest,-info.y*rest);
	}
	float shown=step(0.0,flight)*step(flight,1.0);
	vec3 world=(MODEL_MATRIX*vec4(VERTEX*shown,1.0)).xyz+offset*shown;
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}

void fragment() {
	if(flight<0.0||flight>1.0) {discard;}
	float shade=.55+.45*dot(normalize(NORMAL),normalize((VIEW_MATRIX*vec4(light_dir,0.0)).xyz));
	if(mode==0) {
		float core=clamp(dot(normalize(NORMAL),vec3(0.0,0.0,1.0)),0.0,1.0);
		ALBEDO=mix(vec3(.9,.25,.04),vec3(1.0,.85,.35),pow(core,2.0));
		EMISSION=ALBEDO*1.4;
	} else {
		float speck=fract(sin(dot(floor(UV*6.0)+info.w,vec2(12.9,78.2)))*43758.5);
		vec3 stone=mix(vec3(.38,.33,.28),vec3(.55,.5,.44),speck);
		ALBEDO=stone*shade;
	}
	ALPHA=1.0;
}
