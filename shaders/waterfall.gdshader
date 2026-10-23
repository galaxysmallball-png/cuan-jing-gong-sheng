shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(.35,.58,.66,1);
void fragment() {
	float edge = smoothstep(.0,.16,UV.x)*(1.0-smoothstep(.80,1.0,UV.x));
	float threads = sin(UV.x*112.0+sin(UV.y*18.0-TIME*5.0)*.9)*.5+.5;
	float rush = sin(UV.y*73.0-TIME*16.0+UV.x*15.0)*.5+.5;
	ALBEDO = tint.rgb * (.65+threads*.30+rush*.28);
	float spray = smoothstep(.72,1.0,UV.y)*pow(rush,3.0);
	ALPHA = edge*(.28+threads*.33+pow(rush,7.0)*.24+spray*.14);
}
