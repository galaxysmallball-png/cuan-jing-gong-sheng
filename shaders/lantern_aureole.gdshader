shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 glow_color : source_color = vec4(1.0,.49,.15,1.0);
uniform float strength = .18;
uniform float phase = 0.0;

void fragment() {
	float d=length((UV-.5)*2.0);
	float falloff=exp(-d*d*5.0)*(1.0-smoothstep(.55,1.0,d));
	float breathing=.97+.03*sin(TIME*1.4+phase);
	ALBEDO=glow_color.rgb;
	ALPHA=falloff*strength*breathing;
}
