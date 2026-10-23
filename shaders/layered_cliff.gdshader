shader_type spatial;
render_mode diffuse_burley,cull_disabled;
uniform vec4 base_color:source_color=vec4(.29,.36,.37,1.);
uniform float seed_offset=0.;
varying vec3 p;
varying vec3 world_normal;
float hash(vec2 a){return fract(sin(dot(a,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 a){vec2 f=fract(a);f=f*f*(3.-2.*f);vec2 c=floor(a);return mix(mix(hash(c),hash(c+vec2(1,0)),f.x),mix(hash(c+vec2(0,1)),hash(c+vec2(1,1)),f.x),f.y);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	vec2 q=p.xy+vec2(seed_offset,0.);
	float beds=q.y*5.0+.30*sin(q.x*1.2)+noise(q*.8)*.6;
	float joint=(1.-smoothstep(.025,.075,abs(sin(beds*3.14159))))*smoothstep(.38,.72,noise(q*vec2(1.3,3.1)));
	float mineral=noise(q*3.)*.12+noise(q*14.)*.07;
	float strata=noise(vec2(q.x*.4,floor(beds)))*.13;
	vec3 stone=base_color.rgb*(.80+mineral+strata)*(1.-joint*.095);
	float damp=1.-smoothstep(-1.,1.4,p.y);
	stone*=1.-damp*.12;
	float moss=smoothstep(.58,.79,noise(q*2.1))*max(0.,world_normal.y)*.30;
	ALBEDO=mix(stone,vec3(.15,.22,.13),moss);
	ROUGHNESS=.94;
}
