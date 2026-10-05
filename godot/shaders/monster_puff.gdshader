shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// MultiMesh data: kind, normalized native-time age, deterministic seed, unused.
// No TIME: pause, native decisions and speed control every part of the effect.
varying vec4 effect_data;
varying vec4 effect_tint;
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    vec4 v=fract(sin(vec4(dot(i,vec2(127.1,311.7)),dot(i+vec2(1,0),vec2(127.1,311.7)),dot(i+vec2(0,1),vec2(127.1,311.7)),dot(i+vec2(1),vec2(127.1,311.7))))*43758.5453);
    return mix(mix(v.x,v.y,f.x),mix(v.z,v.w,f.x),f.y);
}
void vertex() {
    effect_data=INSTANCE_CUSTOM; effect_tint=COLOR;
    vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    if(INSTANCE_CUSTOM.x<1.5) {
        world=MODEL_MATRIX[3].xyz+INV_VIEW_MATRIX[0].xyz*VERTEX.x*length(MODEL_MATRIX[0].xyz)
            +INV_VIEW_MATRIX[1].xyz*VERTEX.y*length(MODEL_MATRIX[1].xyz);
    }
    POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}
void fragment() {
    vec2 p=UV*2.0-1.0; float r=length(p);
    float age=effect_data.y, seed=effect_data.z;
    float cloud=noise(p*4.0+vec2(seed*31.0,-age*3.0))*0.65+noise(p*9.0+seed*17.0)*0.35;
    float mask=(1.0-smoothstep(0.45,1.0,r))*(0.35+cloud*0.65);
    if(effect_data.x>1.5) mask=(1.0-smoothstep(0.04,0.14,abs(r-0.75)))*(1.0-smoothstep(0.8,1.0,r));
    vec3 color=effect_tint.rgb;
    if(effect_data.x<0.5) color=mix(color,color*0.45+vec3(0.55),pow(max(0.0,1.0-r),3.0));
    ALBEDO=color;
    EMISSION=effect_data.x<0.5 ? color*0.7 : vec3(0.0);
    ALPHA=mask*effect_tint.a;
}
