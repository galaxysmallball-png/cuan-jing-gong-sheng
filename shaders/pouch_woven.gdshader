shader_type spatial;
render_mode cull_disabled;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
	vec2 weave=p.xy*vec2(780.0,920.0);
	float aa=1.0-smoothstep(.35,1.8,max(fwidth(weave.x),fwidth(weave.y)));
	float threads=(sin(weave.x)*.035+sin(weave.y)*.035)*aa;
	float mottled=sin(p.x*43.0+sin(p.y*36.0))*.025+sin(p.y*87.0+p.z*31.0)*.012;
	ALBEDO=vec3(.24,.225,.14)*(1.0+threads+mottled);
	ROUGHNESS=.95;
}
