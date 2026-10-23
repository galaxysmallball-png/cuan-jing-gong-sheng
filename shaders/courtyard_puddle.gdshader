shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform float warm = 1.0;
void fragment() {
	vec2 p = UV*2.0-1.0;
	float ragged = sin(p.x*19.0+p.y*7.0)*.03+sin(p.y*27.0)*.04;
	float edge = 1.0-smoothstep(.63,.99,length(p)+ragged);
	float glint = pow(max(0.0,sin(p.y*40.0+sin(p.x*15.0)*.6+TIME*.7)),16.0);
	ALBEDO = mix(vec3(.10,.22,.27),vec3(.49,.31,.13),warm)*(.7+glint*.6);
	EMISSION = mix(vec3(.07,.13,.17),vec3(.46,.24,.07),warm)*glint*.24;
	ALPHA = edge*.42;
	ROUGHNESS = .24;
	SPECULAR = .7;
}
