shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float strength = 0.10;

void fragment() {
	float vertical = sin(UV.y * 3.1415926);
	float horizontal = sin(UV.x * 3.1415926);
	float waves = 0.5 + 0.5 * sin(UV.x * 15.0 + TIME * 0.18 + sin(UV.x * 35.0 - TIME * 0.09));
	ALBEDO = vec3(0.36, 0.48, 0.52);
	ALPHA = strength * vertical * horizontal * (0.45 + 0.55 * waves);
}
