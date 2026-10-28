shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always;

uniform vec4 water_color : source_color = vec4(0.07, 0.2, 0.24, 0.82);
uniform sampler2D wave_normal : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wpos.x * 0.35 + TIME * 1.2) * 0.025 + cos(wpos.z * 0.3 + TIME) * 0.025;
}

void fragment() {
	vec2 uv1 = wpos.xz * 0.05 + vec2(TIME * 0.01, TIME * 0.006);
	vec2 uv2 = wpos.xz * 0.09 - vec2(TIME * 0.008, -TIME * 0.011);
	vec3 n = normalize(texture(wave_normal, uv1).rgb + texture(wave_normal, uv2).rgb - 1.0);
	NORMAL_MAP = n;
	NORMAL_MAP_DEPTH = 0.6;
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	ROUGHNESS = 0.04;
	METALLIC = 0.1;
	SPECULAR = 0.8;
}
