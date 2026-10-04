shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
void fragment() {
	float radius=length(UV-.5)*2.0;
	float ring=(1.0-smoothstep(.016,.055,abs(radius-.78)));
	float ripple=1.0-smoothstep(.02,.09,abs(radius-fract(TIME*.22)));
	ALBEDO=vec3(1.0,.71,.24)*1.8;
	ALPHA=ring*.7+ripple*.18;
}
