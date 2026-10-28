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
	
	// Single-step procedural noise (blazing fast WebGL fragment shader)
	float n1 = noise(p * 0.15);
	float n2 = noise(p * 0.9);
	float detail = (n1 * 0.65 + n2 * 0.35);
	
	// Rich earthy autumn palette
	vec3 col_grass = mix(vec3(0.18, 0.28, 0.12), vec3(0.26, 0.35, 0.14), detail);
	vec3 col_needles = mix(vec3(0.24, 0.18, 0.10), vec3(0.19, 0.22, 0.11), detail);
	vec3 col_rock = mix(vec3(0.26, 0.25, 0.24), vec3(0.33, 0.31, 0.28), detail);
	vec3 col_mud = mix(vec3(0.12, 0.09, 0.07), vec3(0.18, 0.14, 0.10), detail);
	
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	vec3 col = mix(col_grass, col_needles, smoothstep(0.38, 0.62, n1));
	col = mix(col, col_rock, smoothstep(0.25, 0.55, slope));
	col = mix(col_mud, col, smoothstep(-0.2, 1.2, wpos.y));
	
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}
	
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
