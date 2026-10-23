shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
void fragment(){
	vec2 p=(UV-.5)*2.0;
	float d=length(p);
	float core=exp(-d*d*8.0);
	float rays=pow(max(0.0,1.0-abs(p.x)*6.0-abs(p.y)),4.0)+pow(max(0.0,1.0-abs(p.y)*6.0-abs(p.x)),4.0);
	ALBEDO=COLOR.rgb*1.65;
	ALPHA=(core*.54+rays*.34)*(1.0-smoothstep(.65,1.0,d))*COLOR.a;
}
