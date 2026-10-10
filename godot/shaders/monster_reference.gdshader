shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
// Stable rest UVs follow morph and VAT motion. No wall-clock animation.
uniform float surface_family = 0.0;
float cell_hash(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
void fragment() {
    float kind=round(UV2.x*8.0);
    vec3 color=COLOR.rgb;
    float roughness=0.74;
    float metallic=0.0;
    if(kind<0.5 || kind>8.5) {
        float pores=sin(UV.x*510.0)*sin(UV.y*470.0);
        color*=0.97+pores*0.035;
        if(surface_family>2.5) {
            vec2 q=UV*95.0;
            float spots=smoothstep(0.30,0.12,length(fract(q)-vec2(0.5)))*cell_hash(floor(q));
            color*=0.91-spots*0.22;
            roughness=0.46;
            NORMAL_MAP=normalize(vec3(pores*0.045,cos(UV.y*290.0)*0.035,1.0))*0.5+0.5;
        } else if(surface_family>1.5) {
            vec2 q=UV*85.0;
            q.x+=mod(floor(q.y),2.0)*0.5;
            vec2 cell=fract(q)-vec2(0.5);
            float edge=smoothstep(0.31,0.47,length(cell));
            color*=1.0-edge*0.12;
            roughness=0.68;
            NORMAL_MAP=normalize(vec3(cell*0.12,1.0))*0.5+0.5;
        } else if(surface_family>0.5) {
            float fibres=sin(UV.x*630.0+sin(UV.y*160.0)*2.0);
            color*=0.93+fibres*0.045;
            roughness=0.88;
            NORMAL_MAP=normalize(vec3(fibres*0.055,pores*0.025,1.0))*0.5+0.5;
        } else {
            roughness=0.64;
            NORMAL_MAP=normalize(vec3(pores*0.025,pores*0.02,1.0))*0.5+0.5;
        }
    } else if(kind<1.5) roughness=0.83;
    else if(kind<2.5) roughness=0.48;
    else if(kind<3.5) roughness=0.87;
    else if(kind<4.5) roughness=0.63;
    else if(kind<5.5) {roughness=0.26;EMISSION=color*0.12;}
    else if(kind<6.5) {roughness=0.90;color*=0.95+0.05*sin(UV.x*360.0);}
    else if(kind<7.5) {metallic=0.75;roughness=0.43;}
    else roughness=0.91;
    ALBEDO=color;ROUGHNESS=roughness;METALLIC=metallic;SPECULAR=0.32;
}
