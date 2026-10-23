// Seven mineral-pigment colours, revealed only by the completed collection.
vec3 collection_pigment(vec2 uv) {
	float t=clamp(uv.y*.78+uv.x*.22+.035*sin(uv.x*6.28318+uv.y*4.3),0.0,1.0)*6.0;
	vec3 red=vec3(.71,.16,.12);
	vec3 amber=vec3(.88,.41,.12);
	vec3 gold=vec3(.87,.70,.24);
	vec3 green=vec3(.19,.53,.30);
	vec3 cyan=vec3(.16,.60,.64);
	vec3 blue=vec3(.20,.32,.69);
	vec3 violet=vec3(.52,.25,.59);
	vec3 pigment;
	if(t<1.0) pigment=mix(red,amber,smoothstep(0.0,1.0,t));
	else if(t<2.0) pigment=mix(amber,gold,smoothstep(1.0,2.0,t));
	else if(t<3.0) pigment=mix(gold,green,smoothstep(2.0,3.0,t));
	else if(t<4.0) pigment=mix(green,cyan,smoothstep(3.0,4.0,t));
	else if(t<5.0) pigment=mix(cyan,blue,smoothstep(4.0,5.0,t));
	else pigment=mix(blue,violet,smoothstep(5.0,6.0,t));
	return pow(pigment,vec3(1.35))*.88+vec3(.025);
}
