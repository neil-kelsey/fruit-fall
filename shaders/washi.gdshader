shader_type canvas_item;
// Cream washi paper with fibres and specks.
uniform vec4 base_col : source_color = vec4(0.957, 0.906, 0.796, 1.0);
uniform vec2 size = vec2(800.0, 1400.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 q = UV * size;
	float n = noise(q * 0.015) * 0.5 + noise(q * 0.06) * 0.3 + noise(q * 0.25) * 0.2;
	float fib = noise(vec2(q.x * 0.012 + noise(q * 0.02) * 3.0, q.y * 0.7));
	float fibers = smoothstep(0.78, 0.97, fib);
	float fib2 = smoothstep(0.85, 0.99, noise(vec2(q.y * 0.01, q.x * 0.5)));
	float speck = step(0.9975, hash(floor(q * 0.5)));
	vec3 c = base_col.rgb * (0.93 + 0.09 * n) - fibers * 0.035 + fib2 * 0.03 - speck * 0.3;
	COLOR = vec4(c, base_col.a);
}
