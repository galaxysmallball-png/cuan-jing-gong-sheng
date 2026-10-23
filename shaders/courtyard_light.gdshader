shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.54, 0.70, 0.72, 1.0);
uniform float strength = 0.075;

void fragment() {
	float edge = pow(max(0.0, sin(UV.x * 3.1415926)), 1.3);
	float height = sin(UV.y * 3.1415926);
	float drift = 0.87 + 0.13 * sin(UV.y * 8.0 + TIME * 0.24);
	ALBEDO = tint.rgb;
	ALPHA = edge * height * strength * drift;
}
