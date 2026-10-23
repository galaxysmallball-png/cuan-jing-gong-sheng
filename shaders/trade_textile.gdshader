shader_type spatial;
render_mode cull_disabled;
uniform int motif = 0;
uniform int partner_motif = -1;
uniform float print_progress : hint_range(0.0,1.0) = 1.0;

void vertex() {
	VERTEX.z += sin(VERTEX.x * 8.0 + TIME * .65) * .012 * (1.0 - UV.y);
}

void fragment() {
	vec2 tile = fract(UV * vec2(4.0, 5.0)) - .5;
	float radius = length(tile);
	float angle = atan(tile.y, tile.x);
	float ink = 0.0;
	vec3 ground = vec3(.055, .14, .25);
	vec3 dye = vec3(.84, .83, .66);
	int selected_motif=motif;
	if (partner_motif>=0 && mod(floor(UV.x*4.0)+floor(UV.y*5.0),2.0)>.5) selected_motif=partner_motif;
	if (selected_motif == 0) {
		float flower = .22 + .075 * cos(angle * 6.0);
		ink = 1.0 - smoothstep(.018, .045, abs(radius - flower));
		ink = max(ink, 1.0 - smoothstep(.038, .065, radius));
		ink = max(ink, 1.0 - smoothstep(.008, .025, abs(radius - .40)));
	} else if (selected_motif == 1) {
		float spiral = abs(sin(radius * 26.0 - angle * 2.0));
		ink = (1.0 - smoothstep(.15, .35, spiral)) * (1.0 - smoothstep(.28, .37, radius));
		ink = max(ink, step(.445, max(abs(tile.x), abs(tile.y))));
	} else if (selected_motif == 3) {
		ground = vec3(.095, .10, .09);
		dye = vec3(.52, .21, .10);
		ink = step(.44, max(abs(tile.x), abs(tile.y))) * step(UV.y, .13);
	} else {
		float diamond = abs(tile.x) + abs(tile.y);
		ink = 1.0 - smoothstep(.035, .065, abs(diamond - .33));
		ink = max(ink, 1.0 - smoothstep(.025, .055, abs(diamond - .13)));
		ground = vec3(.38, .075, .045);
		dye = vec3(.91, .61, .18);
		if (fract(UV.y * 10.0) > .76) { ground = vec3(.035, .20, .20); }
	}
	float border = step(UV.x, .05) + step(.95, UV.x) + step(UV.y, .035) + step(.965, UV.y);
	float revealed=smoothstep(UV.x*.75,UV.x*.75+.15,print_progress);
	vec3 cloth = mix(ground, dye, clamp(max(ink*revealed, border), 0.0, 1.0));
	float weave = .88 + .12 * sin(UV.x * 1200.0) * sin(UV.y * 1500.0);
	ALBEDO = cloth * weave;
	EMISSION = cloth * .12;
	ROUGHNESS = 1.0;
}
