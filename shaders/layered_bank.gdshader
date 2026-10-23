shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(.24,.29,.29,1);
varying vec3 point;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex() { point=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
void fragment() {
	float strata=abs(sin(point.y*12.0+sin(point.x*1.3)*.72+sin(point.z*2.1)*.35));
	float seam=smoothstep(.025,.15,strata);
	float grain=hash(floor(point*87.0));
	float broad=.5+.5*sin(point.x*2.7+sin(point.y*3.1+point.z*.9));
	vec3 stone=base_color.rgb*(.82+grain*.15+broad*.18)*mix(.66,1.0,seam);
	float fissure=abs(sin(point.x*2.8+point.y*.45+sin(point.y*2.3)*.13));
	float broken=(1.0-smoothstep(.015,.04,fissure))*smoothstep(.3,.7,sin(point.y*1.8+point.x*.4)*.5+.5);
	stone*=1.0-broken*.24;
	float moss=smoothstep(.68,.93,hash(floor(point*3.4)))*smoothstep(-2.8,-.25,point.y)*.24;
	// Keep the footing in shade; deeper beds recede below the lit walking surface.
	float depth=smoothstep(.12,2.8,-point.y);
	ALBEDO=mix(stone,vec3(.12,.19,.13),moss)*mix(.58,.10,depth);
	ROUGHNESS=.96;
}
