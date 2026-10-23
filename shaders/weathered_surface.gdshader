shader_type spatial;
render_mode diffuse_burley;

uniform vec4 base_color : source_color = vec4(0.18, 0.23, 0.25, 1.0);
uniform float pattern = 0.0;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p), f = smoothstep(0.0,1.0,fract(p));
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 p = n.y > 0.5 ? world_position.xz : (n.z > 0.5 ? world_position.xy : world_position.zy);
	float grain = noise(p * 70.0);
	float variation = noise(p * vec2(3.0, 2.0));
	float value = 0.85 + 0.20 * variation + 0.045 * grain;
	if (pattern > 1.5) {
		float grain_flow=p.x*82.0+noise(p*vec2(5.0,1.6))*9.0;
		value *= .92+.045*sin(grain_flow)+.025*sin(grain_flow*2.1);
		vec2 knot=fract(p*vec2(.9,.55))-.5;
		float eye=length(knot*vec2(5.,1.6));
		value*=1.-exp(-eye*eye*12.)*.13;
	} else if (pattern > 0.5) {
		vec2 cells = vec2(p.x * 1.7 + mod(floor(p.y * 3.5),2.0)*.5, p.y * 3.5);
		vec2 border = min(fract(cells), 1.0 - fract(cells));
		float mortar = smoothstep(0.015, 0.045, min(border.x, border.y));
		value *= mix(0.48, 1.0, mortar);
	}
	vec3 color = base_color.rgb * value;
	float damp = (1.0-smoothstep(.05,1.2,world_position.y))*.20;
	color *= 1.0-damp;
	float moss = smoothstep(0.64, 0.88, noise(p * 3.0)) * 0.16;
	if (pattern < 1.5) color = mix(color, vec3(0.13, 0.19, 0.13), moss);
	color*=mix(1.0,.20,1.0-smoothstep(-2.8,-.25,world_position.y));
	ALBEDO = color;
	ROUGHNESS = 0.92;
}
