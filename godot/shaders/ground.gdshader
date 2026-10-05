shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/terrain_common.gdshaderinc"
#include "res://shaders/terrain_palette.gdshaderinc"
#include "res://shaders/terrain_rock.gdshaderinc"
#include "res://shaders/map_outside.gdshaderinc"

uniform sampler2D road_data : filter_linear, repeat_disable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D mineral_data : filter_linear, repeat_disable;
uniform sampler2D mineral_pattern : filter_linear, repeat_disable;
uniform float mineral_strength = 1.0;
uniform float hillside_finish = 1.0;
varying float world_height;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	world_height = (MODEL_MATRIX * vec4(VERTEX,1.0)).y;
	// Only native water cells form a seabed; land heights come from the mesh.
	float shore = max(coast_distance(world_xz), 0.0);
	VERTEX.y -= UV2.x * smoothstep(0.0, 3.0, shore) * 0.48;
	// An earthquake's chasm sinks below the ground around it (the pattern's G, see fragment()).
	VERTEX.y -= smoothstep(0.55, 0.95, texture(mineral_pattern, map_uv(world_xz)).g) * 0.7;
}

void fragment() {
	vec4 terrain = texture(terrain_data, map_uv(world_xz));
	float patches = texture(surface_noise, world_xz / 11.0).r;
	float grain = texture(surface_noise, world_xz / 1.8).r;
	float shore = coast_distance(world_xz);
	vec3 ground = land_colour(world_xz, terrain.g);
	vec3 sand = sand_colour(world_xz);
	// Banks of uneven width with a ragged grass edge, instead of one even sand band.
	float reach = 0.7 + 1.5 * texture(surface_noise, world_xz / 13.0 + vec2(4.1, 0.7)).r;
	float ragged = (texture(surface_noise, world_xz / 1.6 + vec2(1.9, 6.2)).r - 0.5) * 0.9;
	float bank = 1.0 - smoothstep(reach - 0.35, reach + 0.25, abs(shore) + ragged);
	ground = mix(ground, sand, max(terrain.a, bank));
	// Wet sand: a darker, glossier strip the lapping water keeps soaked.
	float wet = 1.0 - smoothstep(0.0, 0.45 + ragged * 0.2, max(-shore, 0.0));
	ground = mix(ground, ground * vec3(0.62, 0.66, 0.68), wet * 0.8);
	vec3 stone = mix(vec3(0.42, 0.40, 0.34), vec3(0.51, 0.48, 0.40), grain);
	float strata = sin(world_height*23.0 + patches*2.0) * 0.025;
	stone += vec3(strata);
	float steepness = 1.0-clamp(dot(normalize(NORMAL),normalize(mat3(VIEW_MATRIX)*vec3(0.0,1.0,0.0))),0.0,1.0);
	ground = mix(ground, stone, max(terrain.b,UV2.y*smoothstep(0.02,0.22,steepness)*0.95*(1.0-hillside_finish)));
	vec3 world_point = vec3(world_xz.x, world_height, world_xz.y);
	vec3 world_normal = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
	// Only native blocked slopes and side faces expose rock; walkable ramps,
	// ordinary ground and protected foundations retain their existing materials.
	float rock_cover = UV2.y * smoothstep(0.035 + (grain - 0.5) * 0.025, 0.25, steepness) * hillside_finish;
	vec4 limestone = vec4(stone, 0.0);
	if (UV2.y > 0.5 && hillside_finish > 0.0) {
		limestone = limestone_surface(world_point, world_normal);
		ground = mix(ground, limestone.rgb, rock_cover);
	}
	vec4 mineral = texture(mineral_data,map_uv(world_xz));
	float geological_noise = texture(surface_noise,world_xz/5.3).r;
	float vein = smoothstep(0.50,0.56,geological_noise)-smoothstep(0.56,0.63,geological_noise);
	vec3 mineral_colour = mineral.rgb / max(mineral.a,0.0001);
	float deposit = mineral.a*mineral_strength;
	vec4 pattern = texture(mineral_pattern,map_uv(world_xz))*mineral_strength;
	float fleck = texture(surface_noise,world_xz/0.19+vec2(7.3,2.9)).r;
	// Stone grit so quarry floors are not flat paint.
	vec3 deposit_ground = mineral_colour*(0.9+grain*0.16-vein*0.08+(smoothstep(0.62,0.7,fleck)-smoothstep(0.3,0.22,fleck))*0.07);
	// Quarry floors: sawn blocks in staggered courses, each a slightly different tone.
	vec2 course = world_xz*vec2(2.1,3.2);
	course.x += floor(course.y)*0.5;
	vec2 inside = fract(course);
	float seam = 1.0-smoothstep(0.0,0.045,min(min(inside.x,1.0-inside.x)*0.65,min(inside.y,1.0-inside.y)));
	float block_tone = fract(sin(dot(floor(course),vec2(12.9898,78.233)))*43758.5453);
	deposit_ground = mix(deposit_ground,deposit_ground*(0.95+block_tone*0.08)*(1.0-seam*0.28),pattern.r);
	ground = mix(ground,deposit_ground,deposit);
	// Disasters and wet ground, from the pattern's other channels (terrain_presentation.gd): G an earthquake's chasm, B lava, A marsh.
	vec4 hazard = texture(mineral_pattern, map_uv(world_xz));
	vec3 glow = vec3(0.0);
	if (hazard.g + hazard.b + hazard.a > 0.001) {
		// Broad and fine noise break up the tile grid's outline.
		float ragged_edge = (texture(surface_noise, world_xz / 2.6 + vec2(3.3, 8.1)).r - 0.5) * 0.7
			+ (texture(surface_noise, world_xz / 0.8 + vec2(1.7, 4.4)).r - 0.5) * 0.12;
		float chasm = smoothstep(0.42, 0.6, hazard.g + ragged_edge);
		float lava = smoothstep(0.42, 0.6, hazard.b + ragged_edge);
		float marsh = smoothstep(0.38, 0.6, hazard.a + ragged_edge);
		// Chasm: a near-black rift inside a rim of pale, broken earth split by fissures (the ground also sinks there, see vertex()).
		float crack_a = abs(texture(surface_noise, world_xz / 2.2 + vec2(5.0, 1.0)).r - 0.5);
		float crack_b = abs(texture(surface_noise, world_xz / 0.9 + vec2(2.0, 9.0)).r - 0.5);
		float fissure = 1.0 - smoothstep(0.0, 0.045, min(crack_a, crack_b * 1.4));
		float depth = smoothstep(0.62, 0.9, hazard.g + ragged_edge * 0.5);
		vec3 rim = mix(vec3(0.45, 0.37, 0.27), vec3(0.34, 0.27, 0.19), grain);
		rim = mix(rim, vec3(0.06, 0.045, 0.035), fissure);
		vec3 rift = mix(vec3(0.07, 0.055, 0.045), vec3(0.025, 0.015, 0.012), smoothstep(0.85, 1.0, hazard.g) + grain * 0.2);
		ground = mix(ground, mix(rim, rift, depth), chasm);
		// Lava: a dark cooling crust broken by thin glowing seams, with molten pools that slowly drift and pulse.
		vec2 drift = vec2(TIME * 0.02, TIME * 0.013);
		float plates = texture(surface_noise, world_xz / 3.2 + drift).r;
		float seams = 1.0 - smoothstep(0.0, 0.03, abs(plates - 0.5));
		float molten_pool = smoothstep(0.62, 0.78, texture(surface_noise, world_xz / 5.5 - drift).r);
		float pulse = 0.8 + 0.2 * sin(TIME * 1.3 + plates * 7.0);
		float heat = max(seams * 0.8, molten_pool) * pulse;
		vec3 crust = mix(vec3(0.06, 0.05, 0.045), vec3(0.13, 0.09, 0.07), grain * 0.7 + patches * 0.3);
		vec3 molten = mix(vec3(0.85, 0.22, 0.03), vec3(1.0, 0.6, 0.16), molten_pool);
		ground = mix(ground, mix(crust, molten, heat), lava);
		glow = (molten * heat * 1.3 + vec3(0.22, 0.05, 0.0) * 0.25) * lava;
		// Marsh: sodden ground of rank green tussocks, with a few broad pools of still dark water.
		float pool_noise = texture(surface_noise, world_xz / 6.0 + vec2(8.0, 4.0)).r * 0.75 + texture(surface_noise, world_xz / 1.9 + vec2(2.0, 6.0)).r * 0.25;
		float pools = smoothstep(0.6, 0.66, pool_noise);
		float tussock = texture(surface_noise, world_xz / 3.0 + vec2(1.0, 7.0)).r;
		vec3 sodden = mix(vec3(0.15, 0.19, 0.08), vec3(0.24, 0.27, 0.11), tussock * 0.6 + grain * 0.4);
		sodden = mix(sodden, vec3(0.13, 0.15, 0.08), smoothstep(0.5, 0.6, pool_noise) * (1.0 - pools));
		sodden = mix(sodden, vec3(0.06, 0.10, 0.11), pools);
		ground = mix(ground, sodden, marsh);
		wet = max(wet, marsh * (0.4 + pools * 0.6));
	}
	// The road mask's 0.5 level is the tile edge: a straight road paves its whole tile,
	// outer corners round off. inward = distance inside that edge, in tiles.
	vec4 street = texture(road_data, map_uv(world_xz));
	float road_mask = street.r;
	float edge_width = fwidth(road_mask) * 0.75 + 0.004;
	float road = smoothstep(0.5 - edge_width, 0.5 + edge_width, road_mask);
	float inward = road_mask - 0.5;
	// Worn limestone slabs in staggered courses, each a slightly different tone.
	vec2 slab = world_xz * vec2(2.6, 3.4);
	slab.x += floor(slab.y) * 0.5;
	vec2 slab_inside = fract(slab);
	float joint = 1.0 - smoothstep(0.0, 0.06, min(min(slab_inside.x, 1.0 - slab_inside.x) * 0.75, min(slab_inside.y, 1.0 - slab_inside.y)));
	float slab_tone = fract(sin(dot(floor(slab), vec2(41.3, 289.1))) * 15731.743);
	float wear = texture(surface_noise, world_xz / 2.2 + vec2(6.1, 3.7)).r;
	vec3 paving = mix(vec3(0.40, 0.355, 0.275), vec3(0.50, 0.445, 0.345), slab_tone * 0.35 + grain * 0.35 + wear * 0.3);
	paving *= 1.0 - joint * 0.13 * (0.6 + wear * 0.8);
	// Dust and wear: packed earth shows between the slabs in patches.
	paving = mix(paving, vec3(0.40, 0.34, 0.25), smoothstep(0.5, 0.78, patches * 0.6 + wear * 0.4) * 0.45);
	// Avenues and boulevards: large pale dressed slabs.
	float dressed = smoothstep(0.35, 0.65, street.g);
	vec2 dress = world_xz * vec2(1.7, 2.3);
	dress.x += floor(dress.y) * 0.5;
	vec2 dress_inside = fract(dress);
	float dress_joint = 1.0 - smoothstep(0.0, 0.035, min(min(dress_inside.x, 1.0 - dress_inside.x) * 0.75, min(dress_inside.y, 1.0 - dress_inside.y)));
	float dress_tone = fract(sin(dot(floor(dress), vec2(17.7, 113.3))) * 24634.63);
	vec3 dressed_paving = mix(vec3(0.57, 0.54, 0.47), vec3(0.66, 0.62, 0.54), dress_tone * 0.6 + grain * 0.4) * (1.0 - dress_joint * 0.12);
	paving = mix(paving, dressed_paving, dressed);
	// Edge: a light kerb stone on plain roads, a dark border band on avenues and boulevards,
	// then a shaded gutter just inside it.
	float kerb = 1.0 - smoothstep(0.035, 0.05, inward);
	float band = 1.0 - smoothstep(0.075, 0.09, inward);
	float gutter = smoothstep(0.045, 0.06, inward) * (1.0 - smoothstep(0.075, 0.1, inward));
	paving = mix(paving, vec3(0.62, 0.58, 0.50), kerb * (1.0 - dressed));
	paving *= 1.0 - gutter * 0.18 * (1.0 - dressed);
	paving = mix(paving, vec3(0.30, 0.28, 0.25), band * dressed);
	// Medians (avenue and boulevard tiles): a planted bed inside a pale stone edging;
	// a boulevard's bed is lusher and full of flowers.
	float bed = smoothstep(0.62, 0.7, street.b);
	float edging = smoothstep(0.52, 0.58, street.b) * (1.0 - bed);
	float boulevard = smoothstep(0.3, 0.7, street.a);
	float flowers = smoothstep(0.76, 0.8, texture(surface_noise, world_xz / 0.35 + vec2(2.7, 5.1)).r) * mix(0.25, 1.0, boulevard);
	vec3 planting = mix(mix(vec3(0.14, 0.18, 0.08), vec3(0.20, 0.23, 0.11), grain), mix(vec3(0.08, 0.18, 0.045), vec3(0.13, 0.24, 0.06), grain), boulevard);
	planting = mix(planting, mix(vec3(0.75, 0.62, 0.20), vec3(0.62, 0.16, 0.12), slab_tone), flowers * 0.8);
	paving = mix(paving, vec3(0.64, 0.61, 0.55), edging);
	paving = mix(paving, planting, bed);
	// Pavement: a strip of small setts just outside the carriageway, where buildings step back.
	float sidewalk = smoothstep(0.38 - edge_width, 0.38 + edge_width, road_mask) * (1.0 - road);
	vec2 sett = fract(world_xz * 7.0);
	float sett_joint = 1.0 - smoothstep(0.0, 0.1, min(min(sett.x, 1.0 - sett.x), min(sett.y, 1.0 - sett.y)));
	vec3 pavement = mix(vec3(0.50, 0.46, 0.38), vec3(0.57, 0.53, 0.45), grain) * (1.0 - sett_joint * 0.12);
	ground = mix(ground, pavement, sidewalk);
	ground = mix(ground, paving, road);
	rock_cover *= 1.0 - max(road, deposit);
	ALBEDO = tint_outside(ground * (0.96 + grain * 0.08), map_outside(world_xz));
	ROUGHNESS = mix(0.92, 0.42, wet);
	// Tangents follow the shared world projection; adjacent tiles have no UV resets.
	vec3 bump = texture(ground_normal, world_xz / 2.4).rgb * 2.0 - 1.0;
	vec3 base_normal = normalize(NORMAL);
	vec3 detail = mat3(VIEW_MATRIX)*vec3(-bump.x*0.12,0.0,-bump.y*0.12);
	NORMAL = normalize(base_normal+detail-dot(detail,base_normal)*base_normal);
	if (UV2.y > 0.5 && hillside_finish > 0.0) {
		vec3 rocky_normal = mat3(VIEW_MATRIX) * limestone_normal(world_point, world_normal, limestone.a);
		NORMAL = normalize(mix(NORMAL, rocky_normal, rock_cover));
	}
	SPECULAR = 0.22;
	EMISSION = tint_outside(glow, map_outside(world_xz));
}
