shader_type canvas_item;
void fragment(){
 float left=(1.-smoothstep(.0,.52,UV.x))*.12;
 float edge=pow(length((UV-.5)*vec2(1.2,1.)),2.)*.18;
 float bottom=smoothstep(.70,1.0,UV.y)*.12;
 float top=(1.-smoothstep(0.,.16,UV.y))*.06;
 COLOR=vec4(vec3(.004,.009,.013),clamp(max(left,edge+bottom+top),0.,.90));
}
