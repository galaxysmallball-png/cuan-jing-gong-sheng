shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = smoothstep(0.0, 1.0, fract(p));
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
void fragment() {
	// All three panels sample the same world-space palette. Their overlap must
	// not produce a hard sunset/night colour seam at a chapter boundary.
	vec2 p=world_position.xy;
	float creek=smoothstep(16.0,24.0,p.x);
	float court=smoothstep(36.0,44.0,p.x);
	vec3 high=mix(vec3(.12,.22,.32),vec3(.025,.065,.14),creek);
	vec3 low=mix(vec3(.87,.57,.33),vec3(.22,.33,.42),creek);
	high=mix(high,vec3(.045,.085,.18),court);
	low=mix(low,vec3(.49,.32,.28),court);
	vec3 sky = mix(high, low, pow(clamp(UV.y,0.0,1.0), .85));
	float clouds = noise(p*vec2(.32,1.27)+vec2(TIME*.007,0))*.6 + noise(p*vec2(.82,2.5))*.4;
	float strand = smoothstep(.47,.70,clouds) * smoothstep(.08,.30,UV.y) * (1.0-smoothstep(.75,.95,UV.y));
	sky = mix(sky, mix(low,high,.42), strand*.28);
	float sun_distance=length(p-vec2(7.4,1.95));
	float moon_distance=length(p-vec2(32.86,2.17));
	float sun=1.0-smoothstep(.47,.50,sun_distance);
	float moon=1.0-smoothstep(.33,.35,moon_distance);
	sky+=vec3(1,.66,.34)*exp(-sun_distance*.8)*.095;
	sky+=vec3(.50,.66,.73)*exp(-moon_distance*1.3)*.065;
	float crater=noise(p*18.0)*noise(p*31.0);
	sky=mix(sky,mix(vec3(1,.77,.43),sky,strand*.16),sun);
	sky=mix(sky,mix(vec3(.82,.88,.80)*(1.0-crater*.13),sky,strand*.12),moon);
	vec2 star_cell=floor(p*vec2(9.2,8.2));
	float star=step(.997,hash(star_cell))*(1.0-smoothstep(.0,.14,length(fract(p*vec2(9.2,8.2))-.5)));
	sky+=vec3(.55,.66,.75)*star*creek*(1.0-court*.35)*(1.0-UV.y)*(1.0-moon);
	ALBEDO = sky;
}
