shader_type spatial;
render_mode cull_disabled,diffuse_burley;
uniform vec4 tint:source_color=vec4(.18,.19,.15,1.);
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
	float turning=sin(p.y*480.+sin(p.x*19.)*.8);
	float fleck=fract(sin(dot(floor(p.xz*600.),vec2(127.1,311.7)))*43758.5453);
	ALBEDO=tint.rgb*(.94+turning*.035+fleck*.04);
	ROUGHNESS=.62+fleck*.10;
	SPECULAR=.35;
}
