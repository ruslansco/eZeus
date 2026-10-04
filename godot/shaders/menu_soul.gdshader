shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
void fragment(){
 float head=fract(scene_time*.045+phase);
 float d=head-UV.y;
 float tail=exp(-d*26.)*step(0.,d)*smoothstep(0.,.12,UV.y)*smoothstep(1.,.76,UV.y);
 float width=pow(max(0.,1.-abs(UV.x-.5)*2.),2.);
 ALBEDO=vec3(.23,.63,.55)*tail*width*1.7;
 ALPHA=tail*width*.65;
}
