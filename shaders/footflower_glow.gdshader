shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
void fragment(){
	vec2 p=(UV-.5)*2.0;
	float r=length(p);
	float a=atan(p.y,p.x);
	// Rounded silk petals and an offset inner corolla.
	float edge=.48+.16*cos(a*6.0);
	float outer=(1.0-smoothstep(edge-.035,edge+.018,r))*smoothstep(.07,.22,r);
	float rim=exp(-pow((r-edge)/.017,2.0));
	float inner_edge=.29+.095*cos(a*6.0+3.14159);
	float inner_rim=exp(-pow((r-inner_edge)/.014,2.0));
	float inner=(1.0-smoothstep(inner_edge-.03,inner_edge+.02,r))*smoothstep(.06,.15,r);
	float veins=pow(max(0.0,cos(a*18.0)),22.0)*smoothstep(.16,.28,r)*(1.0-smoothstep(edge-.12,edge,r));
	float stamen_ring=exp(-pow((r-.112)/.016,2.0))*pow(max(0.0,cos(a*12.0)),6.0);
	float filaments=exp(-pow(sin(a*6.0)*r/.012,2.0))*smoothstep(.045,.065,r)*(1.0-smoothstep(.09,.12,r));
	float centre=exp(-r*r*650.0);
	float leaves=exp(-pow((r-(.63+.12*cos(a*4.0+1.2)))/.04,2.0))*pow(max(0.0,cos(a*4.0+1.2)),25.0);
	float spark_ring=exp(-pow((r-.82)/.023,2.0))*pow(max(0.0,cos(a*9.0+TIME*.7)),55.0);
	vec3 silk=mix(COLOR.rgb,vec3(1.0,.86,.57),inner*.35+rim*.19);
	vec3 golden=vec3(1.0,.76,.25);
	float gold=stamen_ring*.85+filaments*.4+centre*.8;
	ALBEDO=mix(silk,golden,clamp(gold,0.0,1.0));
	ALPHA=(outer*.19+rim*.48+inner*.16+inner_rim*.39+veins*.21+gold+leaves*.24+spark_ring*.62+exp(-r*r*6.0)*.06)*COLOR.a;
}
