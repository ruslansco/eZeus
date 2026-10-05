shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
// Rest UVs stay attached to the skin through morph and VAT poses. UV2.x * 8:
// skin, belly, horn, mouth, teeth, eyes. No wall-clock animation or gameplay.
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
    float kind=round(UV2.x*8.0);
    vec3 color=COLOR.rgb;
    float roughness=0.74;
    if(kind<0.5) {
        vec2 p=UV*56.0;
        vec2 cell=floor(p);
        float first=10.0, second=10.0;
        for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
            vec2 n=cell+vec2(float(x),float(y));
            vec2 center=n+vec2(0.5+0.24*(hash(n)-0.5),0.5+0.24*(hash(n+17.0)-0.5));
            float d=length(p-center);
            if(d<first){second=first;first=d;}else second=min(second,d);
        }
        float edge=1.0-smoothstep(0.025,0.09,second-first);
        color*=mix(1.04,0.76,edge);
        roughness=0.72+edge*0.12;
    } else if(kind<1.5) roughness=0.85;
    else if(kind<2.5) roughness=0.43;
    else if(kind<3.5) roughness=0.91;
    else if(kind<4.5) roughness=0.65;
    else {roughness=0.38;EMISSION=color*1.5;}
    ALBEDO=color;
    ROUGHNESS=roughness;
    SPECULAR=0.32;
}
