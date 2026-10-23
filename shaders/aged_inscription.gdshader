shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/stele_reward_palette.gdshaderinc"
uniform sampler2D albedo_texture : source_color, filter_linear;
uniform vec4 stone_color : source_color = vec4(0.39, 0.365, 0.31, 1.0);
uniform float collection_color_amount : hint_range(0.0,1.0) = 0.0;
uniform sampler2D collection_pigment_texture : source_color, filter_linear_mipmap;
float grain(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec3 reference = texture(albedo_texture, UV).rgb;
	float ink = smoothstep(0.34, 0.77, dot(reference, vec3(0.299, 0.587, 0.114)));
	float rough = grain(floor(UV * vec2(195.0, 310.0)));
	float stain = sin(UV.y * 13.0 + sin(UV.x * 25.0)) * 0.035;
	vec3 stone = stone_color.rgb * (0.90 + rough * 0.16 + stain);
	vec2 stele_uv=vec2((UV.x-.5)*.94/1.1+.5,(UV.y-.5)*1.95/2.4+.5-.03/2.4);
	vec3 pigment=texture(collection_pigment_texture,clamp(stele_uv,vec2(0),vec2(1))).rgb*(.96+rough*.04+stain*.25);
	stone=mix(stone,pigment,collection_color_amount);
	float eroded = smoothstep(0.1, 0.38, rough);
	ALBEDO = mix(stone, stone * 0.40, ink * eroded * 0.94);
	ALBEDO = mix(ALBEDO, vec3(0.20, 0.24, 0.14), smoothstep(0.77, 1.0, UV.y) * 0.22);
	ROUGHNESS = 0.98;
	EMISSION=pigment*collection_color_amount*.32*(1.0-ink*.85);
}
