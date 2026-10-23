shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 deep_color : source_color = vec4(0.025, 0.16, 0.21, 1.0);
uniform vec4 foam_color : source_color = vec4(0.57, 0.76, 0.78, 1.0);
uniform vec2 rock_centers[12];
varying vec3 world_position;

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
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(VERTEX.z * 2.0 - TIME * 2.4 + VERTEX.x * 1.3) * 0.035;
}

void fragment() {
	vec2 p = world_position.xz;
	float stream = sin(p.x * 22.0 + noise(vec2(p.x * 3.0, p.y * 0.8 - TIME * 1.3)) * 7.0);
	float broken = smoothstep(0.35, 0.78, noise(vec2(p.x * 5.0, p.y * 1.6 - TIME * 2.2)));
	float ribbons = smoothstep(0.82, 0.99, stream) * broken;
	float gleam = pow(max(0.0, sin(p.x * 12.0 + p.y * 4.0 - TIME * 4.0)), 28.0) * broken;
	float whitewater = 0.0;
	for (int i=0; i<12; i++) {
		vec2 offset = p-rock_centers[i];
		float d = length(offset*vec2(1.6,1.0));
		float fringe = (1.0-smoothstep(.58,.94,d)) * smoothstep(.36,.52,d);
		float wake = exp(-abs(offset.x)*5.0) * smoothstep(-.1,.30,offset.y) * (1.0-smoothstep(.4,2.0,offset.y));
		whitewater += (fringe + wake*.5) * (.48+broken*.52);
	}
	float current = noise(vec2(p.x*2.0,p.y*.7-TIME*.9));
	vec3 water = deep_color.rgb * (.7+current*.75);
	ALBEDO = mix(water, foam_color.rgb, clamp(ribbons*.37+gleam*.25+whitewater*.73,0.0,.91));
}
