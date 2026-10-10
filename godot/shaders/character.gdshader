shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// UV2 stores the surface type. UV and painted colour follow rest anatomy so
// freckles, cloth weave and hair grain never swim during a morph walk cycle.
uniform bool elder_portrait = false; // Only a private Character-panel material enables this.
uniform bool greek_robe = false;
uniform bool hades_flame = false;
uniform vec3 robe_accent : source_color = vec3(0.24, 0.43, 0.64);
uniform vec3 clavi_0 : source_color = vec3(.64,.055,.075);
uniform vec3 clavi_1 : source_color = vec3(.64,.055,.075);
uniform vec3 clavi_2 : source_color = vec3(.64,.055,.075);
// Per-walker variety for townspeople (scripts/citizen_variety.gd): 0 keeps the authored look; any other value picks a
// stable small shift of tunic shade and hue, hair colour and skin tone, so a job keeps its colour but neighbours differ.
instance uniform float citizen_variant = 0.0;

float variant_hash(float k) { return fract(sin(citizen_variant * 91.7 + k * 37.3) * 43758.5453); }

vec3 rotate_hue(vec3 c, float a) {
	const mat3 to_yiq = mat3(vec3(.299,.596,.211), vec3(.587,-.274,-.523), vec3(.114,-.322,.312));
	const mat3 to_rgb = mat3(vec3(1.0,1.0,1.0), vec3(.956,-.272,-1.106), vec3(.621,-.647,1.703));
	vec3 yiq = to_yiq * c;
	float ca = cos(a), sa = sin(a);
	yiq.yz = vec2(yiq.y*ca - yiq.z*sa, yiq.y*sa + yiq.z*ca);
	return max(to_rgb * yiq, vec3(0.0));
}

float meander(vec2 p) {
	p = fract(p);
	float a = step(p.y, .17);
	float b = step(.15,p.x)*step(p.x,.30)*step(p.y,.78);
	float c = step(.15,p.x)*step(p.x,.76)*step(.63,p.y)*step(p.y,.78);
	float d = step(.61,p.x)*step(p.x,.76)*step(.32,p.y)*step(p.y,.78);
	float e = step(.40,p.x)*step(p.x,.76)*step(.32,p.y)*step(p.y,.47);
	return clamp(a+b+c+d+e,0.0,1.0);
}

void fragment() {
	int kind = int(round(UV2.x*8.0));
	ALBEDO = COLOR.rgb;
	ROUGHNESS = .82;
	SPECULAR = .22;
	if (kind == 0) {
		float pore = sin(UV.x*1687.0+UV.y*523.0)*sin(UV.y*1843.0-UV.x*419.0);
		float detail = 1.0-smoothstep(.002,.012,length(fwidth(UV)));
		ALBEDO *= 1.0+pore*.008*detail;
		if (citizen_variant > 0.0) {
			float tone = variant_hash(1.0);
			ALBEDO *= mix(vec3(.88,.86,.84), vec3(1.10,1.08,1.05), tone);
		}
		ROUGHNESS = .66+pore*.025*detail;
		BACKLIGHT = ALBEDO*.055;
		if (elder_portrait) {
			// Restrained rest-space microrelief; derivative fade prevents sparkling when zoomed out.
			float grain = sin(UV.x*7213.0+sin(UV.y*4351.0))*sin(UV.y*6899.0+sin(UV.x*3911.0));
			float fine = 1.0-smoothstep(.0002,.0015,length(fwidth(UV)));
			ALBEDO *= 1.0+grain*.016*fine;
			ROUGHNESS = .62+grain*.045*fine;
			SPECULAR = .28;
			NORMAL = normalize(NORMAL + vec3(dFdx(grain),dFdy(grain),0.0)*.035*fine);
		}
		if (hades_flame) {
			// Cold, slightly waxy skin: a soft pale rim and a little sheen on the brow, nose and cheekbones.
			ROUGHNESS = .52+pore*.025*detail;
			SPECULAR = .3;
			RIM = .32;
			RIM_TINT = .55;
		}
	} else if (kind == 1 || kind == 8) {
		float weave = sin(UV.x*1900.0)*sin(UV.y*1700.0);
		float detail = 1.0-smoothstep(.001,.008,length(fwidth(UV)));
		ALBEDO *= 1.0+weave*.035*detail;
		if (citizen_variant > 0.0) {
			// Dyed in another batch: a touch lighter or darker, a little warmer or cooler.
			ALBEDO = rotate_hue(ALBEDO, (variant_hash(2.0)-.5)*.32) * mix(.80, 1.14, variant_hash(3.0));
		}
		ROUGHNESS = .91;
		if (kind == 8 && !greek_robe) {
			int person = int(floor(UV2.y*8.0));
			vec3 accent = person == 0 ? clavi_0 : person == 1 ? clavi_1 : clavi_2;
			float stripe = 1.0-smoothstep(.008,.009,abs(abs(UV.x)-.044));
			ALBEDO = mix(ALBEDO,accent,stripe);
		}
		if (greek_robe) {
			float z = 1.0-UV.y;
			float band = step(.25,z)*step(z,.277);
			float key = meander(vec2((UV.x+.2)*75.0,(z-.25)/.027));
			ALBEDO = mix(ALBEDO,robe_accent,band*key*.92);
		}
		if (hades_flame) {
			ROUGHNESS = .74;
			SPECULAR = .32;
			float z = 1.0-UV.y;
			float band = step(.030,z)*step(z,.057);
			float key = meander(vec2((UV.x+.3)*55.0,(z-.030)/.027));
			ALBEDO = mix(ALBEDO,vec3(.34,.19,.068),band*key*.85);
		}
	} else if (kind == 2) {
		float locks = sin(UV.x*1320.0+sin(UV.y*53.0)*2.0);
		float detail = 1.0-smoothstep(.001,.01,length(fwidth(UV)));
		ALBEDO *= 1.0+locks*.085*detail;
		float pick = variant_hash(4.0);
		if (citizen_variant > 0.0 && pick > .25) {
			// Black, dark brown, chestnut or grey; one walker in four keeps the authored colour.
			vec3 shade = pick < .45 ? vec3(.016,.012,.010) : pick < .68 ? vec3(.055,.032,.018) : pick < .86 ? vec3(.12,.062,.030) : vec3(.30,.29,.27);
			ALBEDO = mix(ALBEDO, shade*(1.0+locks*.12*detail), .85);
		}
		ROUGHNESS = .73;
		SPECULAR = .18;
		if (hades_flame && COLOR.r > COLOR.b*3.0 && COLOR.r > .15) {
			float flicker = .88+.12*sin(TIME*5.0+UV.x*87.0+UV.y*32.0);
			float tongues = .78+.22*sin(UV.x*119.0+UV.y*67.0-TIME*3.1);
			vec3 crimson = vec3(COLOR.r, COLOR.g*.18, COLOR.b*.3);
			// The tongues' painted colour climbs from deep red at the root (g near 0) to the tip (g .19): hot orange there.
			float heat = smoothstep(.02, .19, COLOR.g);
			vec3 hot = vec3(1.0, .40+.22*tongues, .05+.05*flicker);
			ALBEDO = crimson;
			EMISSION = mix(crimson*1.15, hot*1.55, heat*heat)*flicker*tongues;
			ROUGHNESS = .48;
		} else if (hades_flame && COLOR.r > .09 && COLOR.b > COLOR.r*.55) {
			// Neutral silver fill keeps the beard gray under the blue night sky.
			float silver = dot(COLOR.rgb,vec3(.2126,.7152,.0722));
			ALBEDO = mix(ALBEDO,vec3(silver),.85);
			EMISSION = vec3(.07);
		}
	} else if (kind == 3) {
		ROUGHNESS = elder_portrait ? .13 : .26;
		SPECULAR = .4;
		if (hades_flame) {
			// Wet, glossy eyes. The amber iris burns faintly under the brow; the sclera and the pupil stay as painted.
			ROUGHNESS = .08;
			SPECULAR = .7;
			float amber = smoothstep(.12, .5, COLOR.r) * (1.0 - smoothstep(.04, .2, COLOR.b)) * smoothstep(.015, .08, COLOR.g);
			EMISSION = COLOR.rgb * amber * (.8 + .12 * sin(TIME * 2.3));
		}
	} else if (kind == 4) {
		ALBEDO *= .97+sin(UV.x*640.0)*sin(UV.y*520.0)*.018;
		ROUGHNESS = .76;
	} else if (kind == 5) {
		METALLIC = .8;
		ROUGHNESS = .36;
		SPECULAR = .5;
	} else if (kind == 6) {
		ALBEDO *= .98+sin(UV.y*310.0+sin(UV.x*29.0))* .02;
		ROUGHNESS = .88;
	}
}
