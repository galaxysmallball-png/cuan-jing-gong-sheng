shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
uniform vec4 tint : source_color=vec4(1.0,.72,.29,1.0);
uniform float strength=.28;
void fragment(){
	vec2 p=(UV-.5)*2.0;
	float d=dot(p,p);
	float haze=exp(-d*4.6)*(1.0-smoothstep(.50,1.0,sqrt(d)));
	ALBEDO=tint.rgb;
	ALPHA=haze*strength*(.94+.06*sin(TIME*1.7));
}
