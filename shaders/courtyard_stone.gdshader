shader_type spatial;
render_mode diffuse_burley;
#include "res://shaders/stele_reward_palette.gdshaderinc"

uniform vec4 base_color : source_color = vec4(0.24, 0.27, 0.25, 1.0);
uniform float moss_amount = 0.22;
uniform float collection_color_amount : hint_range(0.0,1.0) = 0.0;
uniform sampler2D collection_pigment_texture : source_color, filter_linear_mipmap;
varying vec2 stele_uv;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	stele_uv=vec2(VERTEX.x/1.1+.5,.5-VERTEX.y/2.4);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 p = n.y > 0.5 ? world_position.xz : (n.z > 0.5 ? world_position.xy : world_position.zy);
	float grain = hash(floor(p * 145.0));
	float weather = noise(p * 2.8) * 0.17 + noise(p * 13.0) * 0.08;
	float veins = 1.0 - smoothstep(0.016, 0.048, abs(noise(p * 1.8) - 0.47));
	vec3 stone = base_color.rgb * (0.82 + weather + grain * 0.045) * (1.0 - veins * 0.06);
	float moss = smoothstep(0.53, 0.85, noise(p * 2.2)) * moss_amount;
	moss *= 0.5 + 0.5 * max(world_normal.y, 0.0);
	ALBEDO = mix(stone, vec3(0.12, 0.19, 0.095), moss);
	ALBEDO*=mix(1.0,.20,1.0-smoothstep(-2.8,-.25,world_position.y));
	vec3 pigment=texture(collection_pigment_texture,clamp(stele_uv,vec2(0),vec2(1))).rgb*(.92+weather*.35+grain*.025);
	ALBEDO=mix(ALBEDO,pigment,collection_color_amount);
	EMISSION=pigment*collection_color_amount*.38;
	ROUGHNESS = 0.88;
}
