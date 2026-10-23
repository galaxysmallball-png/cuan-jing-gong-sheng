shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
void fragment(){
	vec2 p=(UV-.5)*2.0;
	float r=length(p);
	float haze=exp(-r*r*4.5)*(1.0-smoothstep(.6,1.0,r));
	ALBEDO=COLOR.rgb;
	ALPHA=haze*COLOR.a;
}
