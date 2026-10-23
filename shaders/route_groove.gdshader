shader_type spatial;
render_mode cull_disabled;
varying vec2 p;
varying float frontness;
float line_distance(vec2 x,vec2 a,vec2 b) {
	vec2 v=b-a;
	return length(x-a-v*clamp(dot(x-a,v)/dot(v,v),0.,1.));
}
void vertex(){p=VERTEX.xy;frontness=smoothstep(.35,.75,NORMAL.z);}
float hash(vec2 a){return fract(sin(dot(a,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 a){vec2 f=fract(a);f=f*f*(3.-2.*f);vec2 c=floor(a);return mix(mix(hash(c),hash(c+vec2(1,0)),f.x),mix(hash(c+vec2(0,1)),hash(c+vec2(1,1)),f.x),f.y);}
void fragment(){
	float d=line_distance(p,vec2(-1.03,.9),vec2(-.52,1.08));
	d=min(d,line_distance(p,vec2(-.52,1.08),vec2(-.12,1.42)));
	d=min(d,line_distance(p,vec2(-.12,1.42),vec2(.25,1.48)));
	d=min(d,line_distance(p,vec2(.25,1.48),vec2(.56,1.98)));
	d=min(d,line_distance(p,vec2(.56,1.98),vec2(1.05,2.28)));
	float grain=fract(sin(dot(floor(p*175.),vec2(127.1,311.7)))*43758.5453);
	float edge=(1.-smoothstep(.014,.025,d))*frontness;
	float channel=(1.-smoothstep(.004,.014,d))*frontness;
	float weather=noise(p*3.4)*.14+noise(p*21.)*.04;
	vec3 stone=vec3(.29,.35,.34)*(.88+weather);
	float cloud=noise(p*1.3+noise(p*3.1)*.35);
	stone*=.90+cloud*.25;
	// Interrupted strata and irregular joints follow the sculpted rock, with
	// wider, softly eroded lips instead of ruler-straight surface scratches.
	float bed=sin(p.y*11.7+p.x*.65+noise(p*2.4)*1.1);
	float seam=(1.-smoothstep(.015,.11,abs(bed)))*smoothstep(.42,.68,noise(p*vec2(2.3,1.2)));
	stone*=1.-seam*.19;
	float split=abs(p.x-(1.01-.10*sin(p.y*2.8)));
	stone*=1.-(1.-smoothstep(.009,.065,split))*.36;
	float fault=min(line_distance(p,vec2(-1.22,2.52),vec2(-.83,2.28)),line_distance(p,vec2(-.83,2.28),vec2(-.92,2.05)));
	fault=min(fault,line_distance(p,vec2(.67,.41),vec2(.94,.74)));
	stone*=1.-(1.-smoothstep(.002,.012,fault))*.20;
	stone*=.97+noise(p*67.)*.04;
	stone=mix(stone,vec3(.15,.24,.15),smoothstep(.52,.76,noise(p*4.))*max(0.,1.3-p.y)*.5);
	ALBEDO=mix(stone,vec3(.48,.46,.36),edge);
	ALBEDO=mix(ALBEDO,vec3(.13,.17,.14),channel)*(.96+grain*.04);
	ROUGHNESS=.95;
}
