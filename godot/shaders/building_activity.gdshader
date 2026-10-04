shader_type spatial;
render_mode cull_disabled, diffuse_burley;
global uniform float building_work_clock;
uniform sampler2D work_poses : filter_nearest, repeat_disable;
uniform vec2 work_layout = vec2(0.0,1.0);
uniform int work_frames[8];
uniform int inactive_pose = -1;
uniform float surface_roughness = .85;
uniform float surface_metallic = 0.0;
vec3 displacement(int pose_index, ivec2 cell) {
	if (pose_index < 0) return vec3(0.0);
	int row = int(work_layout.x+.5) + pose_index*int(work_layout.y+.5) + cell.y;
	return texelFetch(work_poses,ivec2(cell.x,row),0).xyz;
}
void vertex() {
	ivec2 cell = ivec2(round(CUSTOM0.xy));
	if (INSTANCE_CUSTOM.r < .5) {
		VERTEX += displacement(inactive_pose,cell);
	} else {
		float phase = mod(building_work_clock + INSTANCE_CUSTOM.g,8.0);
		int first = int(floor(phase));
		int second = (first+1)%8;
		VERTEX += mix(displacement(work_frames[first],cell),displacement(work_frames[second],cell),fract(phase));
	}
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = surface_roughness;
	METALLIC = surface_metallic;
}
