// Pose lookup for baked walker and animal animation (tools/bake_walker_vat.py).
// Each vertex carries the address of its texel in CUSTOM0.xy (column, row). A part's
// poses are stacked in one texture: pose p of a part starts at row layout.x + p * layout.y.
// A texel holds the vertex's displacement from the rest mesh, so blending two poses is the
// same as the normalized blend shape it replaces, and lighting keeps the rest normals.
// Use it from any spatial shader:
//   #include "res://shaders/walker_vat.gdshaderinc"
//   void vertex() { VERTEX = vat_apply(VERTEX, CUSTOM0.xy); }
uniform sampler2D vat_poses : filter_nearest, repeat_disable;
// x, y: pose indices (negative = rest pose), z: blend from x to y.
instance uniform vec3 vat_pose = vec3(-1.0, -1.0, 0.0);
// Optional second clip for smooth citizen start/stop. Existing animal/pose users keep 1.
instance uniform vec3 vat_idle_pose = vec3(-1.0, -1.0, 0.0);
instance uniform float vat_walk_blend = 1.0;
// x: first texture row of this part, y: texel rows per pose.
instance uniform vec2 vat_layout = vec2(0.0, 1.0);

vec3 vat_displacement(int pose_index, ivec2 cell) {
	if (pose_index < 0) {
		return vec3(0.0);
	}
	int row = int(vat_layout.x + 0.5) + pose_index * int(vat_layout.y + 0.5) + cell.y;
	return texelFetch(vat_poses, ivec2(cell.x, row), 0).xyz;
}

vec3 vat_apply(vec3 vertex, vec2 address) {
	ivec2 cell = ivec2(int(address.x + 0.5), int(address.y + 0.5));
	if (vat_walk_blend <= 0.0) {
		return vertex + mix(vat_displacement(int(round(vat_idle_pose.x)), cell), vat_displacement(int(round(vat_idle_pose.y)), cell), vat_idle_pose.z);
	}
	vec3 walk = mix(vat_displacement(int(round(vat_pose.x)), cell), vat_displacement(int(round(vat_pose.y)), cell), vat_pose.z);
	if (vat_walk_blend >= 1.0) { return vertex + walk; }
	vec3 idle = mix(vat_displacement(int(round(vat_idle_pose.x)), cell), vat_displacement(int(round(vat_idle_pose.y)), cell), vat_idle_pose.z);
	return vertex + mix(idle, walk, vat_walk_blend);
}
