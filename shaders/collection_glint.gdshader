shader_type spatial;
render_mode unshaded,shadows_disabled,cull_disabled,depth_draw_never;
void fragment() {
	vec2 p=abs(UV*2.0-1.0);
	float core=exp(-dot(p,p)*18.0);
	float rays=pow(max(0.0,1.0-p.x*5.0-p.y),5.0)+pow(max(0.0,1.0-p.y*5.0-p.x),5.0);
	ALBEDO=vec3(1.0,.79,.42);
	ALPHA=clamp(core*.50+rays*.38,0.0,.72);
}
