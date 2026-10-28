shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// 100% Procedural Conifer Foliage Shader (0 KB Textures)
// Wind sway displacement and needle color gradations computed analytically.

uniform vec3 tint : source_color = vec3(0.18, 0.32, 0.16);

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float sway = sin(TIME * 1.4 + wp.x * 0.15 + wp.z * 0.11) * 0.22 * COLOR.a * COLOR.a;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.6;
}

void fragment() {
	float needle_pat = fract(sin(dot(UV * 40.0, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 c = mix(tint, tint * 1.35, needle_pat * 0.3);
	c *= mix(0.65, 1.0, UV.y);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.1;
	BACKLIGHT = vec3(0.08, 0.14, 0.05);
}
