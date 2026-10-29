shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always;

uniform vec4 water_color : source_color = vec4(0.07, 0.2, 0.24, 0.82);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wpos.x * 0.35 + TIME * 1.2) * 0.025 + cos(wpos.z * 0.3 + TIME) * 0.025;
}

void fragment() {
	// Same waves as the vertex shader. No normal texture is assigned in this project.
	float slope_x = cos(wpos.x * 0.35 + TIME * 1.2) * 0.35 * 0.025;
	float slope_z = -sin(wpos.z * 0.3 + TIME) * 0.3 * 0.025;
	NORMAL = normalize(vec3(-slope_x, 1.0, -slope_z));
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	ROUGHNESS = 0.04;
	METALLIC = 0.1;
	SPECULAR = 0.8;
}
