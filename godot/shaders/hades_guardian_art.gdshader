shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never;
uniform float scene_time=0.0;
uniform sampler2D guardian_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D aperture_distance : filter_linear, repeat_disable;
uniform vec4 aperture_mapping=vec4(0.0,0.0,1.0,1.0);
void fragment() {
 vec2 aperture_uv=aperture_mapping.xy+UV*aperture_mapping.zw;
 vec2 packed=texture(aperture_distance,aperture_uv).rg;
 float edge=dot(packed,vec2(256.0/257.0,1.0/257.0))-.5;
 if(edge<0.0 || any(lessThan(aperture_uv,vec2(0.0))) || any(greaterThan(aperture_uv,vec2(1.0)))) discard;
 vec4 art=texture(guardian_art,UV);
 // Painted depth matches the photographic scenery; live green light animates
 // the eyes and existing rim without distorting the stationary stone statue.
 float green=max(0.0,art.g-max(art.r,art.b)*1.12);
 float shimmer=.74+.12*sin(scene_time*1.8)+.06*sin(scene_time*3.2+UV.y*8.0);
 ALBEDO=art.rgb;
 EMISSION=vec3(.30,1.0,.018)*green*shimmer;
 ALPHA=art.a*(1.0-smoothstep(.83,1.0,UV.y)*.45)*smoothstep(0.0,.008,edge);
 ROUGHNESS=1.0;
}
