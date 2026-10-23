shader_type spatial;
render_mode diffuse_burley;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
	float angle = atan(local_point.z, local_point.x);
	float fiber = sin(angle * 177.0 + sin(local_point.y * 7.0) * .3);
	float fine = sin(angle * 473.0 + local_point.y * 2.0);
	float stain = sin(angle * 7.0 + local_point.y * 6.0) * .035;
	float rim = exp(-pow((local_point.y - .31) * 60.0, 2.0)) + exp(-pow((local_point.y + .28) * 60.0, 2.0));
	ALBEDO = vec3(.43, .22, .075) + (fiber * .035 + fine * .012 + stain) * vec3(1.0, .7, .35) - rim * .045;
	ROUGHNESS = .53;
}
