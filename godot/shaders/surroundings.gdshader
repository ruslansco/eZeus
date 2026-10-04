shader_type spatial;
render_mode cull_disabled;
uniform sampler2D surface_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float sea_level = .025;
uniform float vegetation_override = -1.0;
uniform float hillside_finish = 1.0;
varying vec3 world;
#include "res://shaders/terrain_palette.gdshaderinc"
#include "res://shaders/terrain_rock.gdshaderinc"
#include "res://shaders/map_outside.gdshaderinc"
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float patches=texture(surface_noise,world.xz/11.0).r;
 float grain=texture(surface_noise,world.xz/1.8).r;
 float cover=vegetation_override<0.0?COLOR.r:vegetation_override;
 vec3 ground=land_colour(world.xz,cover);
 float elevation=world.y-sea_level;
 float beach=(1.0-smoothstep(.05,.7,abs(elevation)))*COLOR.a;
 ground=mix(ground,sand_colour(world.xz),beach);
 float wet=(1.0-smoothstep(-.1,.12,elevation))*COLOR.a;
 ground*=mix(vec3(1.0),vec3(.70,.74,.75),wet*.75);
 float slope=1.0-clamp(dot(normalize(NORMAL),normalize(mat3(VIEW_MATRIX)*vec3(0,1,0))),0.0,1.0);
 vec3 stone=mix(vec3(.42,.40,.34),vec3(.51,.48,.40),grain);
 stone+=vec3(sin(world.y*.8+patches*2.0)*.012);
 float rock_cover=smoothstep(.12,.46,slope);
 vec3 world_normal=normalize(mat3(INV_VIEW_MATRIX)*NORMAL);
 vec4 limestone=vec4(stone,0.0);
 if(slope>.1 && hillside_finish>0.0){limestone=mix(limestone,limestone_surface(world,world_normal),hillside_finish);}
 ALBEDO=tint_outside(mix(ground,limestone.rgb,rock_cover)*(.96+grain*.08),map_outside(world.xz));
 ROUGHNESS=mix(.92,.76,wet);SPECULAR=.22;
 vec3 bump=texture(ground_normal,world.xz/2.4).rgb*2.0-1.0;
 vec3 detail=mat3(VIEW_MATRIX)*vec3(-bump.x*.12,0,-bump.y*.12);
 vec3 base=normalize(NORMAL);NORMAL=normalize(base+detail-dot(detail,base)*base);
 if(slope>.1 && hillside_finish>0.0){NORMAL=normalize(mix(NORMAL,mat3(VIEW_MATRIX)*limestone_normal(world,world_normal,limestone.a),rock_cover));}
}
