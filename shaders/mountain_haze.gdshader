shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(.13,.24,.25,1);
uniform vec4 daylight_tint : source_color = vec4(.49,.43,.38,1);
uniform bool continuous_palette = false;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=smoothstep(0.0,1.0,fract(p));
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
void fragment() {
	vec2 p=world_position.xy;
	float rock=noise(p*vec2(2.4,.8))*.55+noise(p*vec2(7.0,2.3))*.3+noise(p*22.0)*.15;
	float folds=sin(p.x*2.3+noise(p*1.8)*4.0+p.y*.8);
	float shade=.78+rock*.34+folds*.045;
	float haze=(1.0-smoothstep(-1.6,2.1,p.y))*.27;
	vec3 base=continuous_palette ? mix(daylight_tint.rgb,tint.rgb,smoothstep(17.0,23.0,p.x)) : tint.rgb;
	vec3 color=mix(base*shade,base*1.32+vec3(.025,.035,.04),haze);
	ALBEDO=mix(vec3(.025,.045,.057),color,smoothstep(-9.0,-1.0,p.y));
}
