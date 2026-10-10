shader_type spatial;
render_mode cull_disabled, diffuse_burley;
global uniform float building_work_clock;
uniform sampler2D work_poses : filter_nearest, repeat_disable;
uniform vec2 work_layout = vec2(0.0,1.0);
uniform int work_frames[8];
uniform int inactive_pose = -1;
uniform float surface_roughness = .85;
uniform float surface_metallic = 0.0;
uniform bool smooth_work = true;
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
		vec3 a=displacement(work_frames[first],cell);
		vec3 b=displacement(work_frames[second],cell);
		float t=fract(phase);
		vec3 motion=mix(a,b,t);
		if (smooth_work) {
			vec3 before=displacement(work_frames[(first+7)%8],cell);
			vec3 after=displacement(work_frames[(first+2)%8],cell);
			vec3 tangent_a=(b-before)*.5;
			vec3 tangent_b=(after-a)*.5;
			float t2=t*t; float t3=t2*t;
			motion=(2.0*t3-3.0*t2+1.0)*a+(t3-2.0*t2+t)*tangent_a+(-2.0*t3+3.0*t2)*b+(t3-t2)*tangent_b;
			// No overshoot beyond adjacent authored poses (including hidden FX).
			motion=clamp(motion,min(a,b),max(a,b));
		}
		VERTEX += motion;
	}
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = surface_roughness;
	METALLIC = surface_metallic;
}
