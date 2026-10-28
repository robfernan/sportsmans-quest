shader_type spatial;
render_mode diffuse_burley;

// 100% Procedural Terrain Shader (0 KB Textures)
// Uses analytical sine & hash noise for soil, moss, and grass variations.

varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = NORMAL;
}

void fragment() {
	vec2 p = wpos.xz;
	
	// Single-step procedural noise
	float n1 = noise(p * 0.15);
	float n2 = noise(p * 0.9);
	float detail = (n1 * 0.65 + n2 * 0.35);
	
	// Halloween Late Autumn / Early Winter Palette (Frosted ground, pale moss, and snow glades)
	vec3 col_snow = vec3(0.92, 0.94, 0.98); // Crisp white snow dusting
	vec3 col_frost_turf = mix(vec3(0.35, 0.40, 0.32), vec3(0.48, 0.52, 0.44), detail); // Frosted autumn turf
	vec3 col_frozen_needles = mix(vec3(0.26, 0.22, 0.18), vec3(0.32, 0.28, 0.22), detail);
	vec3 col_cold_rock = mix(vec3(0.30, 0.30, 0.34), vec3(0.42, 0.42, 0.45), detail);
	vec3 col_shore_ice = mix(vec3(0.45, 0.55, 0.60), vec3(0.85, 0.90, 0.95), detail);
	
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	vec3 base_col = mix(col_frost_turf, col_frozen_needles, smoothstep(0.35, 0.65, n1));
	base_col = mix(base_col, col_cold_rock, smoothstep(0.22, 0.52, slope));
	base_col = mix(col_shore_ice, base_col, smoothstep(-0.2, 0.8, wpos.y));
	
	// Snow cover on flatter surfaces and high elevations
	float snow_factor = smoothstep(0.45, 0.15, slope) * smoothstep(-5.0, 18.0, wpos.y + n2 * 4.0);
	vec3 final_col = mix(base_col, col_snow, clamp(snow_factor * 0.75, 0.0, 0.88));
	
	ALBEDO = final_col;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
