shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

void fragment() {
	vec3 low = vec3(0.16, 0.23, 0.25);
	vec3 high = vec3(0.035, 0.075, 0.115);
	ALBEDO = mix(high, low, smoothstep(0.12, 0.92, UV.y));
}
